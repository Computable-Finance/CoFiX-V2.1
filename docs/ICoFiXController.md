# ICoFiXController

## 1. Interface Description
    This interface defines the methods for price call entry

## 2. Method Description

### 2.1. 查询价格

```javascript
    /// @dev 查询价格
    /// @param tokenAddress 目标token地址
    /// @param payback 手续费退回接收地址
    /// @return ethAmount 价格-eth数量
    /// @return tokenAmount 价格-token数量
    /// @return blockNum 价格所在区块
    function queryPrice(
        address tokenAddress,
        address payback
    ) external payable returns (
        uint ethAmount, 
        uint tokenAmount, 
        uint blockNum
    );
```

### 2.2. Calc variance of price and K

```javascript
    /// @dev Calc variance of price and K in CoFiX is very expensive
    /// We use expected value of K based on statistical calculations here to save gas
    /// In the near future, NEST could provide the variance of price directly. We will adopt it then.
    /// We can make use of `data` bytes in the future
    /// @param tokenAddress 目标token地址
    /// @param payback 手续费退回接收地址
    /// @return k The K value(18 decimal places).
    /// @return ethAmount 价格-eth数量
    /// @return tokenAmount 价格-token数量
    /// @return blockNum 价格所在区块
    function queryOracle(
        address tokenAddress,
        address payback
    ) external payable returns (
        uint k, 
        uint ethAmount, 
        uint tokenAmount, 
        uint blockNum
    );
```

### 2.3. Calc K value

```javascript
    /// @notice Calc K value
    /// @param sigmaSQ The square of the volatility (18 decimal places).
    /// @param bn The block number when (ETH, TOKEN) price takes into effective
    /// @return k The K value(18 decimal places).
    function calcK(uint sigmaSQ, uint bn) external view returns (uint k);
```