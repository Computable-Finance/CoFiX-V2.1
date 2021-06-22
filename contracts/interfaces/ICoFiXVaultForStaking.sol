// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

/// @dev This interface defines methods for CoFiXVaultForStaking
interface ICoFiXVaultForStaking {

    /// @dev CoFiXRouter configuration structure
    struct Config {
        // CoFi mining speed
        uint96 cofiRate;
    }

    /// @dev Modify configuration
    /// @param config Configuration object
    function setConfig(Config memory config) external;

    /// @dev Get configuration
    /// @return Configuration object
    function getConfig() external view returns (Config memory);

    /// @dev 初始化锁仓参数
    /// @param pair 目标交易对
    /// @param cofiWeight CoFi出矿速度权重
    function initStakingChannel(address pair, uint cofiWeight) external;
    
    /// @dev 获取目标地址锁仓的数量
    /// @param pair 目标交易对
    /// @param addr 目标地址
    /// @return 目标地址锁仓的数量
    function balanceOf(address pair, address addr) external view returns (uint);

    /// @dev 获取目标地址在指定交易对锁仓上待领取的CoFi数量
    /// @param pair 目标交易对
    /// @param addr 目标地址
    /// @return 目标地址在指定交易对锁仓上待领取的CoFi数量
    function earned(address pair, address addr) external view returns (uint);

    /// @dev 此接口仅共CoFiXRouter调用，来存入做市份额
    /// @param pair 目标交易对
    /// @param to 存入的目标地址
    /// @param amount 存入数量
    function routerStake(address pair, address to, uint amount) external;
    
    /// @dev 存入做市份额
    /// @param pair 目标交易对
    /// @param amount 存入数量
    function stake(address pair, uint amount) external;

    /// @dev 取回做市份额，并领取CoFi
    /// @param pair 目标交易对
    /// @param amount 取回数量
    function withdraw(address pair, uint amount) external;

    /// @dev 领取CoFi
    /// @param pair 目标交易对
    function getReward(address pair) external;
}