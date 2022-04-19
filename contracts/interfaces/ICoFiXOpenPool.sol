// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./ICoFiXPool.sol";

/// @dev CoFiXOpenPool, use NEST4.3 price
interface ICoFiXOpenPool is ICoFiXPool {

    /// @dev Swap for token event
    /// @param amountIn The exact amount of Token a trader want to swap into pool
    /// @param to The target address receiving the ETH
    /// @param amountTokenOut The real amount of token transferred out of pool
    /// @param mined The amount of CoFi which will be mind by this trade
    event SwapForToken1(uint amountIn, address to, uint amountTokenOut, uint mined);

    /// @dev Swap for eth event
    /// @param amountIn The exact amount of Token a trader want to swap into pool
    /// @param to The target address receiving the ETH
    /// @param amountETHOut The real amount of eth transferred out of pool
    /// @param mined The amount of CoFi which will be mind by this trade
    event SwapForToken0(uint amountIn, address to, uint amountETHOut, uint mined);

    /// @dev Set configuration
    /// @param channelId Target price channelId
    /// @param pairIndex Target price pairIndex
    /// @param postUnit Unit of post token, make sure decimals convert
    /// @param theta Trade fee rate, ten thousand points system. 20
    /// @param theta0 Trade fee rate for dao, ten thousand points system. 20
    /// @param impactCostVOL The significance of this parameter is adjusted to represent the times of impact cost
    /// impact cost formula: vol * uint(_impactCostVOL) * 0.000000001
    /// for nest, _impactCostVOL is 2000
    /// @param sigmaSQ Standard sigmaSQ
    function setConfig(
        uint32 channelId,
        uint32 pairIndex,
        uint96 postUnit,
        uint16 theta, 
        uint16 theta0, 
        uint32 impactCostVOL, 
        uint96 sigmaSQ
    ) external;

    /// @dev Get configuration
    /// @return channelId Target price channelId
    /// @return pairIndex Target price pairIndex
    /// @return postUnit Unit of post token, make sure decimals convert
    /// @return theta Trade fee rate, ten thousand points system. 20
    /// @return theta0 Trade fee rate for dao, ten thousand points system. 20
    /// @return impactCostVOL The significance of this parameter is adjusted to represent the times of impact cost
    /// impact cost formula: vol * uint(_impactCostVOL) * 0.000000001
    /// for nest, _impactCostVOL is 2000
    /// @return sigmaSQ Standard sigmaSQ
    function getConfig() external view returns (
        uint32 channelId,
        uint32 pairIndex,
        uint96 postUnit,
        uint16 theta, 
        uint16 theta0, 
        uint32 impactCostVOL, 
        uint96 sigmaSQ
    );

    /// @dev Get net worth
    /// @param ethAmount Oracle price - eth amount
    /// @param tokenAmount Oracle price - token amount
    /// @return navps Net worth
    function getNAVPerShare(
        uint ethAmount, 
        uint tokenAmount
    ) external view returns (uint navps);

    /// @dev Calculate the impact cost of buy in eth
    /// @param vol Trade amount in eth
    /// @return impactCost Impact cost
    function impactCostForBuyInETH(uint vol) external view returns (uint impactCost);

    /// @dev Calculate the impact cost of sell out eth
    /// @param vol Trade amount in eth
    /// @return impactCost Impact cost
    function impactCostForSellOutETH(uint vol) external view returns (uint impactCost);
}