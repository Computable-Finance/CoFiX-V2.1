// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "./ICoFiXPool.sol";

/// @dev 二元资金池: eth/token
interface ICoFiXAnchorPool is ICoFiXPool {

    // struct Config {
    //     // 手续费，万分制。20
    //     uint16 theta;
    //     // n_t为每一单位ETH标准出矿量为，当前n_t=0.1。万分制。 10000
    //     uint16 nt;
    //     // 冲击成本系数。
    //     uint16 gamma;
    //     // // 冲击成本基数。
    //     // uint16 VOL_BASE;
    //     // // 冲击成本α。
    //     // uint64 C_BUYIN_ALPHA;
    //     // uint64 C_BUYIN_ALPHA;
    // }

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