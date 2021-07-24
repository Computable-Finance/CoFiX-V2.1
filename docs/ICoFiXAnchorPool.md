# ICoFiXAnchorPool

## 1. Interface Description
    Anchor pool (please refer to the product documentation for the logic of anchoring the fund pool).

## 2. Method Description

### 2.1. Transfer the excess funds that exceed the total share in the fund pool

```javascript
    /// @dev Transfer the excess funds that exceed the total share in the fund pool
    function skim() external;
```

### 2.2. Estimate mining amount

```javascript
    /// @dev Estimate mining amount
    /// @param token Target token address
    /// @param newBalance New balance of target token
    /// @return mined The amount of CoFi which will be mind by this trade
    function estimate(
        address token,
        uint newBalance
    ) external view returns (uint mined);
```

### 2.3. Gets the token address of the share obtained by the specified token market making

```javascript
    /// @dev Gets the token address of the share obtained by the specified token market making
    /// @param token Target token address
    /// @return If the fund pool supports the specified token, return the token address of the market share
    function getXToken(address token) external view returns (address);
```

### 2.4. Add token information

```javascript
    /// @dev Add token information
    /// @param poolIndex Index of pool
    /// @param token Target token address
    /// @param base Base of token
    function addToken(
        uint poolIndex, 
        address token, 
        uint96 base
    ) external returns (address xtokenAddress);
```