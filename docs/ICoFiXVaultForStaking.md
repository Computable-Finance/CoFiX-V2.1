# ICoFiXVaultForStaking

## 1. Interface Description
    This interface defines methods for CoFiXVaultForStaking

## 2. Method Description

### 2.1. Modify configuration

```javascript
    /// @dev Modify configuration
    /// @param config Configuration object
    function setConfig(Config memory config) external;

    /// @dev CoFiXRouter configuration structure
    struct Config {
        // CoFi mining speed
        uint96 cofiRate;
    }
```

### 2.2. Get configuration

```javascript
    /// @dev Get configuration
    /// @return Configuration object
    function getConfig() external view returns (Config memory);
```

### 2.3. 初始化出矿权重

```javascript
    /// @dev 初始化出矿权重
    /// @param xtokens 份额代币地址数组
    /// @param weights 出矿权重数组
    function batchSetPoolWeight(address[] memory xtokens, uint[] memory weights) external;
```

### 2.4. 初始化锁仓参数

```javascript
    /// @dev 初始化锁仓参数
    /// @param pair 目标交易对
    /// @param cofiWeight CoFi出矿速度权重
    function initStakingChannel(address pair, uint cofiWeight) external;
```

### 2.5. 获取目标地址锁仓的数量

```javascript
    /// @dev 获取目标地址锁仓的数量
    /// @param pair 目标交易对
    /// @param addr 目标地址
    /// @return 目标地址锁仓的数量
    function balanceOf(address pair, address addr) external view returns (uint);
```

### 2.6. 获取目标地址在指定交易对锁仓上待领取的CoFi数量

```javascript
    /// @dev 获取目标地址在指定交易对锁仓上待领取的CoFi数量
    /// @param pair 目标交易对
    /// @param addr 目标地址
    /// @return 目标地址在指定交易对锁仓上待领取的CoFi数量
    function earned(address pair, address addr) external view returns (uint);
```

### 2.7. 此接口仅共CoFiXRouter调用，来存入做市份额

```javascript
    /// @dev 此接口仅共CoFiXRouter调用，来存入做市份额
    /// @param pair 目标交易对
    /// @param to 存入的目标地址
    /// @param amount 存入数量
    function routerStake(address pair, address to, uint amount) external;
```

### 2.8. 存入做市份额

```javascript
    /// @dev 存入做市份额
    /// @param pair 目标交易对
    /// @param amount 存入数量
    function stake(address pair, uint amount) external;
```

### 2.9. 取回做市份额，并领取CoFi

```javascript
    /// @dev 取回做市份额，并领取CoFi
    /// @param pair 目标交易对
    /// @param amount 取回数量
    function withdraw(address pair, uint amount) external;
```

### 2.10. 领取CoFi

```javascript
    /// @dev 领取CoFi
    /// @param pair 目标交易对
    function getReward(address pair) external;
```