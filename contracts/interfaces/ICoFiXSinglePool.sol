// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./ICoFiXPool.sol";

/// @dev Single pool
interface ICoFiXSinglePool is ICoFiXPool {

    /// @dev Swap for token event
    /// @param amountIn The exact amount of Token a trader want to swap into pool
    /// @param to The target address receiving the ETH
    /// @param amountTokenOut The real amount of token transferred out of pool
    /// @param mined The amount of CoFi which will be mind by this trade
    event SwapForToken(uint amountIn, address to, uint amountTokenOut, uint mined);

    /// @dev Swap for eth event
    /// @param amountIn The exact amount of Token a trader want to swap into pool
    /// @param to The target address receiving the ETH
    /// @param amountETHOut The real amount of eth transferred out of pool
    /// @param mined The amount of CoFi which will be mind by this trade
    event SwapForETH(uint amountIn, address to, uint amountETHOut, uint mined);

    /// @dev Set configuration
    /// @param theta Trade fee rate, ten thousand points system. 20
    /// @param theta0 Trade fee rate for dao, ten thousand points system. 20
    /// @param impactCostVOL Impact cost threshold
    function setConfig(uint16 theta, uint16 theta0, uint96 impactCostVOL) external;

    /// @dev Get configuration
    /// @return theta Trade fee rate, ten thousand points system. 20
    /// @return theta0 Trade fee rate for dao, ten thousand points system. 20
    /// @return impactCostVOL Impact cost threshold
    function getConfig() external view returns (uint16 theta, uint16 theta0, uint96 impactCostVOL);

    /// @dev Settle trade fee to DAO
    function settle() external;

    /// @dev Get eth balance of this pool
    /// @return eth balance of this pool
    function ethBalance() external view returns (uint);

    /// @dev Get total trade fee which not settled
    function totalFee() external view returns (uint);
    
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