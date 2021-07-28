# ICoFiXPair

## 1. Interface Description
    Binary pool: eth/token

## 2. Method Description

### 2.1. Get initial asset ratio

```javascript
    /// @dev Get initial asset ratio
    /// @return initToken0Amount Initial asset ratio - eth
    /// @return initToken1Amount Initial asset ratio - token
    function getInitialAssetRatio() external view returns (uint initToken0Amount, uint initToken1Amount);
```

### 2.2. Estimate mining amount

```javascript
    /// @dev Estimate mining amount
    /// @param newBalance0 New balance of eth
    /// @param newBalance1 New balance of token
    /// @param ethAmount Oracle price - eth amount
    /// @param tokenAmount Oracle price - token amount
    /// @return mined The amount of CoFi which will be mind by this trade
    function estimate(
        uint newBalance0, 
        uint newBalance1, 
        uint ethAmount, 
        uint tokenAmount
    ) external view returns (uint mined);
```

### 2.3. Get eth balance of this pool

```javascript
    /// @dev Get eth balance of this pool
    /// @return eth balance of this pool
    function ethBalance() external view returns (uint);
```

### 2.4. Get net worth

```javascript
    /// @dev Get net worth
    /// @param ethAmount Oracle price - eth amount
    /// @param tokenAmount Oracle price - token amount
    /// @return navps Net worth
    function getNAVPerShare(
        uint ethAmount, 
        uint tokenAmount
    ) external view returns (uint navps);
```

### 2.5. Calculate the impact cost of buy in eth

```javascript
    /// @dev Calculate the impact cost of buy in eth
    /// @param vol Trade amount in eth
    /// @return impactCost Impact cost
    function impactCostForBuyInETH(uint vol) external view returns (uint impactCost);
```

### 2.6. Calculate the impact cost of sell out eth

```javascript
    /// @dev Calculate the impact cost of sell out eth
    /// @param vol Trade amount in eth
    /// @return impactCost Impact cost
    function impactCostForSellOutETH(uint vol) external view returns (uint impactCost);
```

### 2.7. Gets the token address of the share obtained by the specified token market making

```javascript
    /// @dev Gets the token address of the share obtained by the specified token market making
    /// @param token Target token address
    /// @return If the fund pool supports the specified token, return the token address of the market share
    function getXToken(address token) external view returns (address);
```

### 2.8. Settle trade fee to DAO

```javascript
    /// @dev Settle trade fee to DAO
    function settle() external;
```

### 2.9. Get total trade fee which not settled

```javascript
    /// @dev Get total trade fee which not settled
    function totalFee() external view returns (uint);
```