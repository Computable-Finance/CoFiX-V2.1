// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./libs/TransferHelper.sol";

import "./interfaces/ICoFiXRouter.sol";
import "./interfaces/ICoFiXPair.sol";
import "./interfaces/ICoFiXVaultForStaking.sol";
import "./CoFiToken.sol";

import "hardhat/console.sol";

// Router contract to interact with each CoFiXPair, no owner or governance
contract CoFiXRouter is ICoFiXRouter {

    constructor (address cofiToken, address cnodeToken) {
        COFI_TOKEN_ADDRESS = cofiToken;
        CNODE_TOKEN_ADDRESS = cnodeToken;
    }

    address immutable COFI_TOKEN_ADDRESS;
    address immutable CNODE_TOKEN_ADDRESS;

    Config _config;
    address _coFiXVaultForStaking;
    mapping(address=>address) _pairs;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'CRouter: EXPIRED');
        _;
    }

    function getConfig() external view override returns (Config memory) {
        return _config;
    }

    function setConfig(Config memory config) external override {
        _config = config;
    }

    function getCoFiXVaultForLP() external view returns (address) {
        return _coFiXVaultForStaking;
    }

    function setCoFiXVaultForLP(address coFiXVaultForStaking) external {
        _coFiXVaultForStaking = coFiXVaultForStaking;
    }

    function addPair(address tokenAddress, address pairAddress) external {
        _pairs[tokenAddress] = pairAddress;
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address token) internal view returns (address pair) {
        // pair = address(uint(keccak256(abi.encodePacked(
        //         hex'ff',
        //         _factory,
        //         keccak256(abi.encodePacked(token)),
        //         hex'fb0c5470b7fbfce7f512b5035b5c35707fd5c7bd43c8d81959891b0296030118' // init code hash
        //     )))); // calc the real init code hash, not suitable for us now, could use this in the future
        //return ICoFiXV2Factory(_factory).getPair(token);
        return _pairs[token];
    }

    // 添加流动性
    // msg.value = amountETH + oracle fee
    function addLiquidity(
        // 目标token
        address token,
        // eth数量
        uint amountETH,
        // token数量
        uint amountToken,
        // 预期的最小份额数
        uint liquidityMin,
        // 流动性接收地址
        address to,
        // 截止时间
        uint deadline
    ) external override payable ensure(deadline) returns (uint liquidity)
    {
        // 0. 找到交易对合约
        address pair = pairFor(token);
        
        // 1. 转入资金
        // 收取token
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);

        // 2. 做市
        // 生成份额
        liquidity = ICoFiXPair(pair).mint{ value: msg.value }(to, amountETH, amountToken, msg.sender);

        // 份额数不能低于预期最小值
        require(liquidity >= liquidityMin, "CRouter: less liquidity than expected");
    }

    // 添加流动性并存入收益池
    // msg.value = amountETH + oracle fee
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
        address pair = pairFor(token);
        
        // 1. 转入资金
        // 收取token
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);

        // 2. 做市
        // 生成份额
        liquidity = ICoFiXPair(pair).mint{ value: msg.value }(address(this), amountETH, amountToken, msg.sender);

        // 份额数不能低于预期最小值
        require(liquidity >= liquidityMin, "CRouter: less liquidity than expected");

        address coFiXVaultForStaking = _coFiXVaultForStaking;
        IERC20(pair).approve(coFiXVaultForStaking, liquidity);
        ICoFiXVaultForStaking(coFiXVaultForStaking).stake(pair, to, liquidity);
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
        address pair = pairFor(token);

        // 1. 转入份额
        TransferHelper.safeTransferFrom(pair, msg.sender, pair, liquidity);

        ICoFiXPair(pair).burn{value: msg.value }(liquidity, to, msg.sender);
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
        address pair = pairFor(token);

        // 1. 转入eth
        (uint amountTokenOut, uint Z) = ICoFiXPair(pair).swapForToken{ value: msg.value }(amountIn, to, msg.sender);
        require(amountTokenOut >= amountOutMin);

        uint cnodeReward = Z * uint(_config.cnodeRewardRate) / 10000;
        CoFiToken(COFI_TOKEN_ADDRESS).mint(rewardTo, Z - cnodeReward);
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
        address pair = pairFor(token);

        // 1. 转入eth
        (uint amountEthOut, uint Z) = ICoFiXPair(pair).swapForETH{ value: msg.value }(amountIn, to, msg.sender);
        require(amountEthOut >= amountOutMin);
        uint cnodeReward = Z * uint(_config.cnodeRewardRate) / 10000;
        CoFiToken(COFI_TOKEN_ADDRESS).mint(rewardTo, Z - cnodeReward);
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
