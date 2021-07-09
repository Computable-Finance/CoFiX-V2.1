// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./ICoFiXPool.sol";

/// @dev 锚定资金池（有关锚定资金池的逻辑请参考产品文档）。
interface ICoFiXAnchorPool is ICoFiXPool {

    /// @dev 将资金池内超过总份额的多余资金转走
    function skim() external;

    /// @dev 预估出矿量
    /// @param token 目标token地址
    /// @param newBalance 新的token余额
    /// @return mined 预计出矿量
    function estimate(
        address token,
        uint newBalance
    ) external view returns (uint mined);
}