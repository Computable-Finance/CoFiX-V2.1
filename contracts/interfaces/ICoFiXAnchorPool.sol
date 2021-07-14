// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./ICoFiXPool.sol";

/// @dev Anchor pool (please refer to the product documentation for the logic of anchoring the fund pool)
interface ICoFiXAnchorPool is ICoFiXPool {

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
}