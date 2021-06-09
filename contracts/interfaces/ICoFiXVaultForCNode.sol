// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

interface ICoFiXVaultForCNode {

    function balanceOf(address addr) external view returns (uint);

    function earned(address addr) external view returns (uint);

    function stake(address to, uint amount) external;

    function unstake(address pair, uint amount) external;

    function getReward() external;
}