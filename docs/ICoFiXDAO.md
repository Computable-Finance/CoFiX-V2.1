# ICoFiXDAO

## 1. Interface Description
    This interface defines the DAO methods

## 2. Method Description

### 2.1. Redeem CoFi for ethers

```javascript
    /// @dev Redeem CoFi for ethers
    /// @notice Ethfee will be charged
    /// @param amount The amount of ntoken
    /// @param payback As the charging fee may change, it is suggested that the caller pay more fees, and the excess fees will be returned through this address
    function redeem(uint amount, address payback) external payable;
```

### 2.2. Redeem CoFi for Token

```javascript
    /// @dev Redeem CoFi for Token
    /// @notice Ethfee will be charged
    /// @param token The target token
    /// @param amount The amount of ntoken
    /// @param payback As the charging fee may change, it is suggested that the caller pay more fees, and the excess fees will be returned through this address
    function redeemToken(address token, uint amount, address payback) external payable;
```

### 2.3. Get the current amount available for repurchase

```javascript
    /// @dev Get the current amount available for repurchase
    function quotaOf() external view returns (uint);
```