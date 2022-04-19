// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./ICoFiXPool.sol";

/// @dev Anchor pool (please refer to the product documentation for the logic of anchoring the fund pool)
interface ICoFiXAnchorPool is ICoFiXPool {

    /// @dev Set configuration
    /// @param theta Trade fee rate, ten thousand points system. 20
    /// @param impactCostVOL Impact cost threshold
    /// @param nt Each unit token (in the case of binary pools, eth) is used for the standard ore output, 1e18 based
    function setConfig(uint16 theta, uint96 impactCostVOL, uint96 nt) external;

    /// @dev Get configuration
    /// @return theta Trade fee rate, ten thousand points system. 20
    /// @return impactCostVOL Impact cost threshold
    /// @return nt Each unit token (in the case of binary pools, eth) is used for the standard ore output, 1e18 based
    function getConfig() external view returns (uint16 theta, uint96 impactCostVOL, uint96 nt);

    /// @dev Transfer the excess funds that exceed the total share in the fund pool
    function skim() external;

    /// @dev Estimate mining amount
    /// @param token Target token address
    /// @param newBalance New balance of target token
    /// @return mined The amount of CoFi which will be mind by this trade
    function estimate(
        address token,
        uint newBalance
    ) external view returns (uint mined);

    /// @dev Add token information
    /// @param poolIndex Index of pool
    /// @param token Target token address
    /// @param base Base of token
    function addToken(
        uint poolIndex, 
        address token, 
        uint96 base
    ) external returns (address xtokenAddress);
}