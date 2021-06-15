// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "./libs/IERC20.sol";
import "./libs/TransferHelper.sol";

import "./interfaces/ICoFiXRouter.sol";
import "./interfaces/ICoFiXPair.sol";
import "./interfaces/ICoFiXVaultForStaking.sol";
import "./CoFiXBase.sol";
import "./CoFiToken.sol";

import "hardhat/console.sol";

// Router contract to interact with each CoFiXPair, no owner or governance
contract CoFiXRouter is CoFiXBase, ICoFiXRouter {

    // TODO: 为了方便测试，此处使用immutable变量，部署时采用openzeppelin的可升级方案，需要将这两个变量改为常量
    address immutable COFI_TOKEN_ADDRESS;
    address immutable CNODE_TOKEN_ADDRESS;

    Config _config;
    address _cofixVaultForStaking;
    mapping(address=>address) _pairs;

    /// @dev Create CoFiXRouter
    /// @param cofiToken CoFi TOKEN
    /// @param cnodeToken CNode TOKEN
    constructor (address cofiToken, address cnodeToken) {
        COFI_TOKEN_ADDRESS = cofiToken;
        CNODE_TOKEN_ADDRESS = cnodeToken;
    }

    // 验证时间没有超过截止时间
    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, "CoFiXRouter: EXPIRED");
        _;
    }

    // 获取配置
    function getConfig() external view override returns (Config memory) {
        return _config;
    }

    function setConfig(Config memory config) external override onlyGovernance {
        _config = config;
    }

    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(nestGovernanceAddress) when overriding, and override method without onlyGovernance
    /// @param newGovernance INestGovernance implementation contract address
    function update(address newGovernance) public override {
        super.update(newGovernance);
        _cofixVaultForStaking = ICoFiXGovernance(newGovernance).getCoFiXVaultForStakingAddress();
    }

    function addPair(address tokenAddress, address pairAddress) external override onlyGovernance {
        _pairs[tokenAddress] = pairAddress;
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function _pairFor(address token) private view returns (address pair) {
        // pair = address(uint(keccak256(abi.encodePacked(
        //         hex'ff',
        //         _factory,
        //         keccak256(abi.encodePacked(token)),
        //         hex'fb0c5470b7fbfce7f512b5035b5c35707fd5c7bd43c8d81959891b0296030118' // init code hash
        //     )))); // calc the real init code hash, not suitable for us now, could use this in the future
        //return ICoFiXV2Factory(_factory).getPair(token);
        return _pairs[token];
    }

    /// @dev 添加流动性
    /// @param token 目标token
    /// @param amountETH 要添加的eth数量
    /// @param amountToken 要添加的token数量
    /// @param liquidityMin 预期获得的最小份额数量
    /// @param to 份额接收地址
    /// @param deadline 截止时间
    /// @return liquidity 获得的流动性份额
    function addLiquidity(
        address token,
        uint amountETH,
        uint amountToken,
        uint liquidityMin,
        address to,
        uint deadline
    ) external override payable ensure(deadline) returns (uint liquidity)
    {
        // msg.value = amountETH + oracle fee
        // 0. 找到交易对合约
        address pair = _pairFor(token);
        
        // 1. 转入资金
        // 收取token
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);

        // 2. 做市
        // 生成份额
        liquidity = ICoFiXPair(pair).mint{ value: msg.value }(to, amountETH, amountToken, msg.sender);

        // 份额数不能低于预期最小值
        require(liquidity >= liquidityMin, "CoFiXRouter: less liquidity than expected");
    }

    /// @dev 添加流动性并将份额转入收益池
    /// @param token 目标token
    /// @param amountETH 要添加的eth数量
    /// @param amountToken 要添加的token数量
    /// @param liquidityMin 预期获得的最小份额数量
    /// @param to 份额接收地址
    /// @param deadline 截止时间
    /// @return liquidity 获得的流动性份额
    function addLiquidityAndStake(
        // 目标token
        address token,
        // eth数量
        uint amountETH,
        // token数量
        uint amountToken,
        // 最低预期份额
        uint liquidityMin,
        // 接收地址
        address to,
        // 交易截止时间
        uint deadline
    ) external override payable ensure(deadline) returns (uint liquidity)
    {
        // 0. 找到交易对合约
        address pair = _pairFor(token);
        
        // 1. 转入资金
        // 收取token
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);

        // 2. 做市
        // 生成份额
        address cofixVaultForStaking = _cofixVaultForStaking;
        liquidity = ICoFiXPair(pair).mint{ 
            value: msg.value 
        }(cofixVaultForStaking, amountETH, amountToken, msg.sender);
        // 份额数不能低于预期最小值
        require(liquidity >= liquidityMin, "CoFiXRouter: less liquidity than expected");

        // 3. 存入份额
        ICoFiXVaultForStaking(cofixVaultForStaking).routerStake(pair, to, liquidity);
    }

    // 移除流动性
    // msg.value = oracle fee
    function removeLiquidityGetTokenAndETH(
        // 要移除的token对
        address token,
        // 移除的额度
        uint liquidity,
        // 预期最少可以获得的eth数量
        uint amountETHMin,
        // 接收地址
        address to,
        // 截止时间
        uint deadline
    ) external override payable ensure(deadline) returns (uint amountToken, uint amountETH) 
    {
        // 0. 找到交易对
        address pair = _pairFor(token);

        // 1. 转入份额
        TransferHelper.safeTransferFrom(pair, msg.sender, pair, liquidity);

        (amountToken, amountETH) = ICoFiXPair(pair).burn{value: msg.value }(liquidity, to, msg.sender);

        require(liquidity >= amountETHMin, "");
    }

    uint _CNodeReward;

    // 用指定数量的eth兑换token
    // msg.value = amountIn + oracle fee
    function swapExactETHForTokens(
        // 目标token地址
        address token,
        // eth数量
        uint amountIn,
        // 预期获得的token的最小数量
        uint amountOutMin,
        // 接收地址
        address to,
        // 出矿接收地址
        address rewardTo,
        uint deadline
    ) external override payable ensure(deadline) returns (uint _amountIn, uint _amountOut)
    {
        // 0. 找到交易对
        address pair = _pairFor(token);

        // 1. 转入eth
        uint mined;
        (_amountOut, mined) = ICoFiXPair(pair).swapForToken{ value: msg.value }(amountIn, to, msg.sender);
        require(_amountOut >= amountOutMin);
        _amountIn = amountIn;

        uint cnodeReward = mined * uint(_config.cnodeRewardRate) / 10000;
        CoFiToken(COFI_TOKEN_ADDRESS).mint(rewardTo, mined - cnodeReward);
        _CNodeReward += cnodeReward;
    }

    // msg.value = oracle fee
    function swapExactTokensForETH(
        address token,
        uint amountIn,
        uint amountOutMin,
        address to,
        address rewardTo,
        uint deadline
    ) external override payable ensure(deadline) returns (uint _amountIn, uint _amountOut)
    {
        // 0. 找到交易对
        address pair = _pairFor(token);

        // 1. 转入eth
        uint mined;
        (_amountOut, mined) = ICoFiXPair(pair).swapForETH{ value: msg.value }(amountIn, to, msg.sender);
        require(_amountOut >= amountOutMin);
        _amountIn = amountIn;
        uint cnodeReward = mined * uint(_config.cnodeRewardRate) / 10000;
        CoFiToken(COFI_TOKEN_ADDRESS).mint(rewardTo, mined - cnodeReward);
        _CNodeReward += cnodeReward;
    }

    function getTradeReward(address pair) external view override returns (uint) {
        // 只有CNode有交易出矿分成，做市份额没有        
        if (pair == CNODE_TOKEN_ADDRESS) {
            return _CNodeReward;
        }
        return 0;
    }
}
