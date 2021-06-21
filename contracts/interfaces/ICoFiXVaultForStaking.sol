// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

interface ICoFiXVaultForStaking {

    struct Config {
        // CoFi mining speed(100000based). 20000
        uint32 cofiRate;
    }

    function getConfig() external view returns (Config memory);

    function setConfig(Config memory config) external;

    function initStakingChannel(address pair, uint cofiWeight, uint initBlockNumber) external;
    
    function balanceOf(address pair, address addr) external view returns (uint);

    function earned(address pair, address addr) external view returns (uint);

    function routerStake(address pair, address to, uint amount) external;
    
    function stake(address pair, uint amount) external;

    function withdraw(address pair, uint amount) external;

    function getReward(address pair) external;
}