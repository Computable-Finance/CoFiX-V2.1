# ICoFiXVaultForStaking

## 1. Interface Description
    This interface defines methods for CoFiXVaultForStaking

## 2. Method Description

### 2.1. 获取目标地址锁仓的数量

```javascript
    /// @dev 获取目标地址锁仓的数量
    /// @param pair 目标交易对
    /// @param addr 目标地址
    /// @return 目标地址锁仓的数量
    function balanceOf(address pair, address addr) external view returns (uint);
```

### 2.2. 获取目标地址在指定交易对锁仓上待领取的CoFi数量

```javascript
    /// @dev 获取目标地址在指定交易对锁仓上待领取的CoFi数量
    /// @param pair 目标交易对
    /// @param addr 目标地址
    /// @return 目标地址在指定交易对锁仓上待领取的CoFi数量
    function earned(address pair, address addr) external view returns (uint);
```

### 2.3. 存入做市份额

```javascript
    /// @dev 存入做市份额
    /// @param pair 目标交易对
    /// @param amount 存入数量
    function stake(address pair, uint amount) external;
```

### 2.4. 取回做市份额，并领取CoFi

```javascript
    /// @dev 取回做市份额，并领取CoFi
    /// @param pair 目标交易对
    /// @param amount 取回数量
    function withdraw(address pair, uint amount) external;
```

### 2.5. 领取CoFi

```javascript
    /// @dev 领取CoFi
    /// @param pair 目标交易对
    function getReward(address pair) external;
```