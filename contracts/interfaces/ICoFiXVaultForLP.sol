// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

interface ICoFiXVaultForLP {

    function balanceOf(address pair, address addr) external view returns (uint);

    function earned(address pair, address addr) external view returns (uint);

    function stake(address pair, address to, uint amount) external;

    function unstake(address pair, uint amount) external;

    function getReward(address pair) external;
}