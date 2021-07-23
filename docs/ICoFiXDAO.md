# ICoFiXDAO

## 1. Interface Description
    This interface defines the DAO methods

## 2. Method Description

### 2.1. Modify configuration

```javascript
    /// @dev Modify configuration
    /// @param config Configuration object
    function setConfig(Config calldata config) external;
```

### 2.2. Get configuration

```javascript
    /// @dev Get configuration
    /// @return Configuration object
    function getConfig() external view returns (Config memory);
```

### 2.3. Set DAO application

```javascript
    /// @dev Set DAO application
    /// @param addr DAO application contract address
    /// @param flag Authorization flag, 1 means authorization, 0 means cancel authorization
    function setApplication(address addr, uint flag) external;
```

### 2.4. Check DAO application flag

```javascript
    /// @dev Check DAO application flag
    /// @param addr DAO application contract address
    /// @return Authorization flag, 1 means authorization, 0 means cancel authorization
    function checkApplication(address addr) external view returns (uint);
```

### 2.5. 设置token和锚定目标币价格的兑换关系

```javascript
    /// @dev 设置token和锚定目标币价格的兑换关系。
    /// 例如，设置USDC锚定USDT，由于USDC是18位小数，USDT是6位小数，因此exchange = 1e6 * 1 ether / 1e18 = 1e6
    /// @param token 目标token
    /// @param target 目标锚定币
    /// @param exchange token和锚定目标币价格的兑换比例
    function setTokenExchange(address token, address target, uint exchange) external;
```

### 2.6. 获取token和锚定目标币价格的兑换关系

```javascript
    /// @dev 获取token和锚定目标币价格的兑换关系。
    /// 例如，设置USDC锚定USDT，由于USDC是18位小数，USDT是6位小数，因此exchange = 1e6 * 1 ether / 1e18 = 1e6
    /// @param token 目标token
    /// @return target 目标锚定币
    /// @return exchange token和锚定目标币价格的兑换比例
    function getTokenExchange(address token) external view returns (address target, uint exchange);
```

### 2.7. Add reward

```javascript
    /// @dev Add reward
    /// @param pool Destination pool
    function addETHReward(address pool) external payable;
```

### 2.8. The function returns eth rewards of specified ntoken

```javascript
    /// @dev The function returns eth rewards of specified ntoken
    /// @param pool Destination pool
    function totalETHRewards(address pool) external view returns (uint);
```

### 2.9. Settlement

```javascript
    /// @dev Settlement
    /// @param pool Destination pool. Indicates which ntoken to pay with
    /// @param tokenAddress Token address of receiving funds (0 means ETH)
    /// @param to Address to receive
    /// @param value Amount to receive
    function settle(address pool, address tokenAddress, address to, uint value) external payable;
```

### 2.10. Redeem CoFi for ethers

```javascript
    /// @dev Redeem CoFi for ethers
    /// @notice Ethfee will be charged
    /// @param amount The amount of ntoken
    /// @param payback As the charging fee may change, it is suggested that the caller pay more fees, and the excess fees will be returned through this address
    function redeem(uint amount, address payback) external payable;
```

### 2.11. Redeem CoFi for Token

```javascript
    /// @dev Redeem CoFi for Token
    /// @notice Ethfee will be charged
    /// @param token The target token
    /// @param amount The amount of ntoken
    /// @param payback As the charging fee may change, it is suggested that the caller pay more fees, and the excess fees will be returned through this address
    function redeemToken(address token, uint amount, address payback) external payable;
```

### 2.12. Get the current amount available for repurchase

```javascript
    /// @dev Get the current amount available for repurchase
    function quotaOf() external view returns (uint);
```