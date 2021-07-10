// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev This interface defines methods for CoFiXVaultForStaking
interface ICoFiXVaultForStaking {

    /// @dev CoFiXRouter configuration structure
    struct Config {
        // CoFi mining speed
        uint96 cofiRate;
    }

    /// @dev Modify configuration
    /// @param config Configuration object
    function setConfig(Config calldata config) external;

    /// @dev Get configuration
    /// @return Configuration object
    function getConfig() external view returns (Config memory);

    /// @dev 初始化出矿权重
    /// @param xtokens 份额代币地址数组
    /// @param weights 出矿权重数组
    function batchSetPoolWeight(address[] calldata xtokens, uint[] calldata weights) external;

    /// @dev 初始化锁仓参数
    /// @param xtoken 目标份额代币地址（或CNode地址）
    /// @param cofiWeight CoFi出矿速度权重
    function initStakingChannel(address xtoken, uint cofiWeight) external;
    
    /// @dev 获取目标地址锁仓的数量
    /// @param xtoken 目标份额代币地址（或CNode地址）
    /// @param addr 目标地址
    /// @return 目标地址锁仓的数量
    function balanceOf(address xtoken, address addr) external view returns (uint);

    /// @dev 获取目标地址在指定交易对锁仓上待领取的CoFi数量
    /// @param xtoken 目标份额代币地址（或CNode地址）
    /// @param addr 目标地址
    /// @return 目标地址在指定交易对锁仓上待领取的CoFi数量
    function earned(address xtoken, address addr) external view returns (uint);

    /// @dev 此接口仅共CoFiXRouter调用，来存入做市份额
    /// @param xtoken 目标份额代币地址（或CNode地址）
    /// @param to 存入的目标地址
    /// @param amount 存入数量
    function routerStake(address xtoken, address to, uint amount) external;
    
    /// @dev 存入做市份额
    /// @param xtoken 目标份额代币地址（或CNode地址）
    /// @param amount 存入数量
    function stake(address xtoken, uint amount) external;

    /// @dev 取回做市份额，并领取CoFi
    /// @param xtoken 目标份额代币地址（或CNode地址）
    /// @param amount 取回数量
    function withdraw(address xtoken, uint amount) external;

    /// @dev 领取CoFi
    /// @param xtoken 目标份额代币地址（或CNode地址）
    function getReward(address xtoken) external;
}