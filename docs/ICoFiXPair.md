# ICoFiXPair

## 1. Interface Description
    二元资金池: eth/token

## 2. Method Description

### 2.1. 获取初始资产比例

```javascript
    /// @dev 获取初始资产比例
    /// @return initToken0Amount 初始资产比例 - ETH
    /// @return initToken1Amount 初始资产比例 - TOKEN
    function getInitialAssetRatio() external view returns (uint initToken0Amount, uint initToken1Amount);
```

### 2.2. 预估出矿量

```javascript
    /// @dev 预估出矿量
    /// @param newBalance0 新的eth余额
    /// @param newBalance1 新的token余额
    /// @param ethAmount 预言机价格-eth数量
    /// @param tokenAmount 预言机价格-token数量
    /// @return mined 预计出矿量
    function estimate(
        uint newBalance0, 
        uint newBalance1, 
        uint ethAmount, 
        uint tokenAmount
    ) external view returns (uint mined);
```

### 2.3. 计算净值

```javascript
    /// @dev 计算净值
    /// @param balance0 资金池eth余额
    /// @param balance1 资金池token余额
    /// @param ethAmount 预言机价格-eth数量
    /// @param tokenAmount 预言机价格-token数量
    /// @return navps 净值
    function calcNAVPerShare(
        uint balance0, 
        uint balance1, 
        uint ethAmount, 
        uint tokenAmount
    ) external view returns (uint navps);
```

### 2.4. 获取净值

```javascript
    /// @dev 获取净值
    /// @param ethAmount 预言机价格-eth数量
    /// @param tokenAmount 预言机价格-token数量
    /// @return navps 净值
    function getNAVPerShare(
        uint ethAmount, 
        uint tokenAmount
    ) external view returns (uint navps);
```

### 2.5. 计算买入eth的冲击成本

```javascript
    /// @dev 计算买入eth的冲击成本
    /// @param vol 以eth计算的交易规模
    /// @return impactCost 冲击成本
    function impactCostForBuyInETH(uint vol) external view returns (uint impactCost);
```

### 2.6. 计算卖出eth的冲击成本

```javascript
    /// @dev 计算卖出eth的冲击成本
    /// @param vol 以eth计算的交易规模
    /// @return impactCost 冲击成本
    function impactCostForSellOutETH(uint vol) external view returns (uint impactCost);
```

### 2.7. 获取指定token做市获得的份额代币地址

```javascript
    /// @dev 获取指定token做市获得的份额代币地址
    /// @param token 目标token
    /// @return 如果资金池支持指定的token，返回做市份额代币地址
    function getXToken(address token) external view returns (address);
```