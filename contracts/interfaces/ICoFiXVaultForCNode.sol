// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

interface ICoFiXVaultForCNode {

    struct Config {
        // CoFi mining speed(100000based). 20000
        uint32 cofiRate;
    }

    function getConfig() external view returns (Config memory);

    function setConfig(Config memory config) external;

    function balanceOf(address addr) external view returns (uint);

    function earned(address addr) external view returns (uint);

    function stake(address to, uint amount) external;

    function unstake(uint amount) external;

    function getReward() external;
}