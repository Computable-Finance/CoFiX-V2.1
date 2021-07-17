// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev This interface defines methods for CoFiXVaultForStaking
interface ICoFiXVaultForStaking {

    /// @dev CoFiXRouter configuration structure
    struct Config {
        // CoFi mining unit
        uint96 cofiUnit;
    }

    /// @dev Modify configuration
    /// @param config Configuration object
    function setConfig(Config calldata config) external;

    /// @dev Get configuration
    /// @return Configuration object
    function getConfig() external view returns (Config memory);

    /// @dev Initialize ore drawing weight
    /// @param xtokens xtoken array
    /// @param weights weight array
    function batchSetPoolWeight(address[] calldata xtokens, uint[] calldata weights) external;

    /// @dev Get total staked amount of xtoken
    /// @param xtoken xtoken address (or CNode address)
    /// @return Total lock volume of target xtoken
    function totalStakedOf(address xtoken) external view returns (uint);

    /// @dev Get staked amount of target address
    /// @param xtoken xtoken address (or CNode address)
    /// @param addr Target address
    /// @return Staked amount of target address
    function balanceOf(address xtoken, address addr) external view returns (uint);

    /// @dev Get the number of CoFi to be collected by the target address on the designated transaction pair lock
    /// @param xtoken xtoken address (or CNode address)
    /// @param addr Target address
    /// @return The number of CoFi to be collected by the target address on the designated transaction lock
    function earned(address xtoken, address addr) external view returns (uint);

    /// @dev Stake xtoken to earn CoFi, this method is only for CoFiXRouter
    /// @param xtoken xtoken address (or CNode address)
    /// @param to Target address
    /// @param amount Stake amount
    function routerStake(address xtoken, address to, uint amount) external;
    
    /// @dev Stake xtoken to earn CoFi
    /// @param xtoken xtoken address (or CNode address)
    /// @param amount Stake amount
    function stake(address xtoken, uint amount) external;

    /// @dev Withdraw xtoken, and claim earned CoFi
    /// @param xtoken xtoken address (or CNode address)
    /// @param amount Withdraw amount
    function withdraw(address xtoken, uint amount) external;

    /// @dev Claim CoFi
    /// @param xtoken xtoken address (or CNode address)
    function getReward(address xtoken) external;
}