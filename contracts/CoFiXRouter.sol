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

/// @dev Router contract to interact with each CoFiXPair
contract CoFiXRouter is CoFiXBase, ICoFiXRouter {

    // TODO: 为了方便测试，此处使用immutable变量，部署时采用openzeppelin的可升级方案，需要将这两个变量改为常量

    // Address of CoFiToken
    address immutable COFI_TOKEN_ADDRESS;
    // Address of CoFiNode
    address immutable CNODE_TOKEN_ADDRESS;

    // Configuration
    Config _config;

    // 记录CNode的累计交易挖矿分成
    uint _cnodeReward;

    // Address of CoFiXVaultForStaing
    address _cofixVaultForStaking;

    // Mapping for token=>pair
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

    /// @dev Modify configuration
    /// @param config Configuration object
    function setConfig(Config memory config) external override onlyGovernance {
        _config = config;
    }

    /// @dev Get configuration
    /// @return Configuration object
    function getConfig() external view override returns (Config memory) {
        return _config;
    }

    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(nestGovernanceAddress) when overriding, and override method without onlyGovernance
    /// @param newGovernance INestGovernance implementation contract address
    function update(address newGovernance) public override {
        super.update(newGovernance);
        _cofixVaultForStaking = ICoFiXGovernance(newGovernance).getCoFiXVaultForStakingAddress();
    }

    /// @dev 添加交易对映射。token=>pair
    /// @param token token地址
    /// @param pair pair地址
    function addPair(address token, address pair) external override onlyGovernance {
        _pairs[token] = pair;
    }

    /// @dev 根据token地址获取pair
    /// @param token 目标token地址
    /// @return pair pair地址
    function pairFor(address token) external view override returns (address pair) {
        return _pairs[token];
    }

    /// @dev Maker add liquidity to pool, get pool token (mint XToken to maker) (notice: msg.value = amountETH + oracle fee)
    /// @param  token The address of ERC20 Token
    /// @param  amountETH The amount of ETH added to pool
    /// @param  amountToken The amount of Token added to pool
    /// @param  liquidityMin The minimum liquidity maker wanted
    /// @param  to The target address receiving the liquidity pool (XToken)
    /// @param  deadline The dealine of this request
    /// @return liquidity The real liquidity or XToken minted from pool
    function addLiquidity(
        address token,
        uint amountETH,
        uint amountToken,
        uint liquidityMin,
        address to,
        uint deadline
    ) external override payable ensure(deadline) returns (uint liquidity)
    {
        // 0. 找到交易对合约
        address pair = _pairs[token];
        
        // 1. 转入资金
        // 收取token
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);

        // 2. 做市
        // 生成份额
        liquidity = ICoFiXPair(pair).mint { 
            value: msg.value 
        } (to, amountETH, amountToken, msg.sender);

        // 份额数不能低于预期最小值
        require(liquidity >= liquidityMin, "CoFiXRouter: less liquidity than expected");
    }

    /// @dev Maker add liquidity to pool, get pool token (mint XToken) and stake automatically (notice: msg.value = amountETH + oracle fee)
    /// @param  token The address of ERC20 Token
    /// @param  amountETH The amount of ETH added to pool
    /// @param  amountToken The amount of Token added to pool
    /// @param  liquidityMin The minimum liquidity maker wanted
    /// @param  to The target address receiving the liquidity pool (XToken)
    /// @param  deadline The dealine of this request
    /// @return liquidity The real liquidity or XToken minted from pool
    function addLiquidityAndStake(
        address token,
        uint amountETH,
        uint amountToken,
        uint liquidityMin,
        address to,
        uint deadline
    ) external override payable ensure(deadline) returns (uint liquidity)
    {
        // 0. 找到交易对合约
        address pair = _pairs[token];
        
        // 1. 转入资金
        // 收取token
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);

        // 2. 做市
        // 生成份额
        address cofixVaultForStaking = _cofixVaultForStaking;
        liquidity = ICoFiXPair(pair).mint { 
            value: msg.value 
        } (cofixVaultForStaking, amountETH, amountToken, msg.sender);

        // 份额数不能低于预期最小值
        require(liquidity >= liquidityMin, "CoFiXRouter: less liquidity than expected");

        // 3. 存入份额
        ICoFiXVaultForStaking(cofixVaultForStaking).routerStake(pair, to, liquidity);
    }

    /// @dev Maker remove liquidity from pool to get ERC20 Token and ETH back (maker burn XToken) (notice: msg.value = oracle fee)
    /// @param  token The address of ERC20 Token
    /// @param  liquidity The amount of liquidity (XToken) sent to pool, or the liquidity to remove
    /// @param  amountETHMin The minimum amount of ETH wanted to get from pool
    /// @param  to The target address receiving the Token
    /// @param  deadline The dealine of this request
    /// @return amountToken The real amount of Token transferred from the pool
    /// @return amountETH The real amount of ETH transferred from the pool
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
        address pair = _pairs[token];

        // 1. 转入份额
        TransferHelper.safeTransferFrom(pair, msg.sender, pair, liquidity);

        // 2. 移除流动性并返还资金
        (amountToken, amountETH) = ICoFiXPair(pair).burn {
            value: msg.value
        } (liquidity, to, msg.sender);

        // 3. 得到的ETH不能少于期望值
        require(amountETH >= amountETHMin, "CoFiXRouter: less eth than expected");
    }

    /// @dev Trader swap exact amount of ETH for ERC20 Tokens (notice: msg.value = amountIn + oracle fee)
    /// @param  token The address of ERC20 Token
    /// @param  amountIn The exact amount of ETH a trader want to swap into pool
    /// @param  amountOutMin The minimum amount of Token a trader want to swap out of pool
    /// @param  to The target address receiving the Token
    /// @param  rewardTo The target address receiving the CoFi Token as rewards
    /// @param  deadline The dealine of this request
    /// @return amountIn_ The real amount of ETH transferred into pool
    /// @return amountOut_ The real amount of Token transferred out of pool
    function swapExactETHForTokens(
        address token,
        uint amountIn,
        uint amountOutMin,
        address to,
        address rewardTo,
        uint deadline
    ) external override payable ensure(deadline) returns (uint amountIn_, uint amountOut_)
    {
        // 0. 找到交易对
        address pair = _pairs[token];

        // 1. 执行交易
        uint mined;
        (amountOut_, mined) = ICoFiXPair(pair).swapForToken {
            value: msg.value
        } (amountIn, to, msg.sender);
        
        // 2. 得到的token数量不能少于期望值
        require(amountOut_ >= amountOutMin, "CoFiXRouter: got less eth than expected");
        amountIn_ = amountIn;

        // 3. 交易挖矿
        uint cnodeReward = mined * uint(_config.cnodeRewardRate) / 10000;
        // 交易者可以获得的数量
        CoFiToken(COFI_TOKEN_ADDRESS).mint(rewardTo, mined - cnodeReward);
        // CNode分成
        _cnodeReward += cnodeReward;
    }

    /// @dev Trader swap exact amount of ERC20 Tokens for ETH (notice: msg.value = oracle fee)
    /// @param  token The address of ERC20 Token
    /// @param  amountIn The exact amount of Token a trader want to swap into pool
    /// @param  amountOutMin The mininum amount of ETH a trader want to swap out of pool
    /// @param  to The target address receiving the ETH
    /// @param  rewardTo The target address receiving the CoFi Token as rewards
    /// @param  deadline The dealine of this request
    /// @return amountIn_ The real amount of Token transferred into pool
    /// @return amountOut_ The real amount of ETH transferred out of pool
    function swapExactTokensForETH(
        address token,
        uint amountIn,
        uint amountOutMin,
        address to,
        address rewardTo,
        uint deadline
    ) external override payable ensure(deadline) returns (uint amountIn_, uint amountOut_)
    {
        // 0. 找到交易对
        address pair = _pairs[token];

        // 1. 转入token并执行交易
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountIn);
        uint mined;
        (amountOut_, mined) = ICoFiXPair(pair).swapForETH {
            value: msg.value
        } (amountIn, to, msg.sender);

        // 2. 得到的eth数量不能少于期望值
        require(amountOut_ >= amountOutMin);
        amountIn_ = amountIn;

        // 3. 交易挖矿
        uint cnodeReward = mined * uint(_config.cnodeRewardRate) / 10000;
        // 交易者可以获得的数量
        CoFiToken(COFI_TOKEN_ADDRESS).mint(rewardTo, mined - cnodeReward);
        // CNode分成
        _cnodeReward += cnodeReward;
    }

    /// @dev 获取目标pair的交易挖矿分成
    /// @param pair 目标pair地址
    /// @return 目标pair的交易挖矿分成
    function getTradeReward(address pair) external view override returns (uint) {
        // 只有CNode有交易出矿分成，做市份额没有        
        if (pair == CNODE_TOKEN_ADDRESS) {
            return _cnodeReward;
        }
        return 0;
    }
}
