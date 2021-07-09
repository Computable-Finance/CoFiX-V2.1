// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev This interface defines the DAO methods
interface ICoFiXDAO {

    /// @dev Application Flag Changed event
    /// @param addr DAO application contract address
    /// @param flag Authorization flag, 1 means authorization, 0 means cancel authorization
    event ApplicationChanged(address addr, uint flag);
    
    /// @dev Configuration structure of CoFiXDAO contract
    struct Config {
        // Redeem activate threshold, when the circulation of token exceeds this threshold, 
        // 回购状态, 1表示启动
        uint8 status;

        // The number of CoFi redeem per block. 100
        uint16 cofiPerBlock;

        // The maximum number of CoFi in a single redeem. 30000
        uint32 cofiLimit;

        // Price deviation limit, beyond this upper limit stop redeem (10000 based). 1000
        uint16 priceDeviationLimit;
    }

    /// @dev Modify configuration
    /// @param config Configuration object
    function setConfig(Config memory config) external;

    /// @dev Get configuration
    /// @return Configuration object
    function getConfig() external view returns (Config memory);

    /// @dev Set DAO application
    /// @param addr DAO application contract address
    /// @param flag Authorization flag, 1 means authorization, 0 means cancel authorization
    function setApplication(address addr, uint flag) external;

    /// @dev Check DAO application flag
    /// @param addr DAO application contract address
    /// @return Authorization flag, 1 means authorization, 0 means cancel authorization
    function checkApplication(address addr) external view returns (uint);

    /// @dev 设置token和锚定目标币价格的兑换关系。
    /// 例如，设置DAI锚定USDT，由于DAI是18位小数，USDT是6位小数，因此exchange = 1e6 * 1 ether / 1e18 = 1e6
    /// @param token 目标token
    /// @param target 目标锚定币
    /// @param exchange token和锚定目标币价格的兑换比例
    function setTokenExchange(address token, address target, uint exchange) external;

    /// @dev 获取token和锚定目标币价格的兑换关系。
    /// 例如，设置DAI锚定USDT，由于DAI是18位小数，USDT是6位小数，因此exchange = 1e6 * 1 ether / 1e18 = 1e6
    /// @param token 目标token
    /// @return target 目标锚定币
    /// @return exchange token和锚定目标币价格的兑换比例
    function getTokenExchange(address token) external view returns (address target, uint exchange);

    /// @dev Add reward
    /// @param pool Destination pool
    function addETHReward(address pool) external payable;

    /// @dev The function returns eth rewards of specified ntoken
    /// @param pool Destination pool
    function totalETHRewards(address pool) external view returns (uint);

    // /// @dev Pay
    // /// @param pool Destination pool. Indicates which ntoken to pay with
    // /// @param tokenAddress Token address of receiving funds (0 means ETH)
    // /// @param to Address to receive
    // /// @param value Amount to receive
    // function pay(address pool, address tokenAddress, address to, uint value) external;

    /// @dev Settlement
    /// @param pool Destination pool. Indicates which ntoken to pay with
    /// @param tokenAddress Token address of receiving funds (0 means ETH)
    /// @param to Address to receive
    /// @param value Amount to receive
    function settle(address pool, address tokenAddress, address to, uint value) external payable;

    /// @dev Redeem CoFi for ethers
    /// @notice Ethfee will be charged
    /// @param amount The amount of ntoken
    /// @param payback As the charging fee may change, it is suggested that the caller pay more fees, and the excess fees will be returned through this address
    function redeem(uint amount, address payback) external payable;

    /// @dev Redeem CoFi for Token
    /// @notice Ethfee will be charged
    /// @param token The target token
    /// @param amount The amount of ntoken
    /// @param payback As the charging fee may change, it is suggested that the caller pay more fees, and the excess fees will be returned through this address
    function redeemToken(address token, uint amount, address payback) external payable;

    /// @dev Get the current amount available for repurchase
    function quotaOf() external view returns (uint);
}