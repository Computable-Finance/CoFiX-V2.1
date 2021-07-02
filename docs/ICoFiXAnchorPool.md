# ICoFiXAnchorPool

## 1. Interface Description
    锚定资金池（有关锚定资金池的逻辑请参考产品文档）。

## 2. Method Description

### 2.1. 将资金池内超过总份额的多余资金转走

```javascript
        /// @dev 将资金池内超过总份额的多余资金转走
    function skim() external;
```

### 2.2. 预估出矿量

```javascript
    /// @dev 预估出矿量
    /// @param token 目标token地址
    /// @param newBalance 新的token余额
    /// @return mined 预计出矿量
    function estimate(
        address token,
        uint newBalance
    ) external view returns (uint mined);
```

### 2.3. 获取指定token做市获得的份额代币地址

```javascript
    /// @dev 获取指定token做市获得的份额代币地址
    /// @param token 目标token
    /// @return 如果资金池支持指定的token，返回做市份额代币地址
    function getXToken(address token) external view returns (address);
```