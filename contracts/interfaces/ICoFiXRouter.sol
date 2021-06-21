// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

/// @dev This interface defines methods for CoFiXRouter
interface ICoFiXRouter {

    /// @dev CoFiXRouter configuration structure
    struct Config {
        // CoFi交易挖矿给CNode的分成比例，万分制。1000
        uint16 cnodeRewardRate;
    }

    /// @dev Modify configuration
    /// @param config Configuration object
    function setConfig(Config memory config) external;

    /// @dev Get configuration
    /// @return Configuration object
    function getConfig() external view returns (Config memory);

    /// @dev 添加交易对映射。token=>pair
    /// @param token token地址
    /// @param pair pair地址
    function addPair(address token, address pair) external;
    
    /// @dev 根据token地址获取pair
    /// @param token 目标token地址
    /// @return pair pair地址
    function pairFor(address token) external view returns (address pair);

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
    ) external payable returns (uint liquidity);

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
    ) external payable returns (uint liquidity);

    /// @dev Maker remove liquidity from pool to get ERC20 Token and ETH back (maker burn XToken) (notice: msg.value = oracle fee)
    /// @param  token The address of ERC20 Token
    /// @param  liquidity The amount of liquidity (XToken) sent to pool, or the liquidity to remove
    /// @param  amountETHMin The minimum amount of ETH wanted to get from pool
    /// @param  to The target address receiving the Token
    /// @param  deadline The dealine of this request
    /// @return amountToken The real amount of Token transferred from the pool
    /// @return amountETH The real amount of ETH transferred from the pool
    function removeLiquidityGetTokenAndETH(
        address token,
        uint liquidity,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH);

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
    ) external payable returns (uint amountIn_, uint amountOut_);

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
    ) external payable returns (uint amountIn_, uint amountOut_);

    /// @dev 获取目标pair的交易挖矿分成
    /// @param pair 目标pair地址
    /// @return 目标pair的交易挖矿分成
    function getTradeReward(address pair) external view returns (uint);
}
