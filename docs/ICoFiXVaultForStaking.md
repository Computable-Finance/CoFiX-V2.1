# ICoFiXVaultForStaking

## 1. Interface Description
    This interface defines methods for CoFiXVaultForStaking

## 2. Method Description

### 2.1. Modify configuration

```javascript
    /// @dev Modify configuration
    /// @param config Configuration object
    function setConfig(Config calldata config) external;

    /// @dev CoFiXRouter configuration structure
    struct Config {
        // CoFi mining unit
        uint96 cofiUnit;
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
    function batchSetPoolWeight(address[] calldata xtokens, uint[] calldata weights) external;
```

### 2.4. Get stake channel information

```javascript
    /// @dev Get stake channel information
    /// @param xtoken xtoken address (or CNode address)
    /// @return totalStaked Total lock volume of target xtoken
    /// @return cofiPerBlock Mining speed, cofi per block
    function getChannelInfo(address xtoken) external view returns (uint totalStaked, uint cofiPerBlock);
```

### 2.5. 获取目标地址锁仓的数量

```javascript
    /// @dev 获取目标地址锁仓的数量
    /// @param xtoken 目标份额代币地址（或CNode地址）
    /// @param addr 目标地址
    /// @return 目标地址锁仓的数量
    function balanceOf(address xtoken, address addr) external view returns (uint);
```

### 2.6. 获取目标地址在指定交易对锁仓上待领取的CoFi数量

```javascript
    /// @dev 获取目标地址在指定交易对锁仓上待领取的CoFi数量
    /// @param xtoken 目标份额代币地址（或CNode地址）
    /// @param addr 目标地址
    /// @return 目标地址在指定交易对锁仓上待领取的CoFi数量
    function earned(address xtoken, address addr) external view returns (uint);
```

### 2.7. 此接口仅共CoFiXRouter调用，来存入做市份额

```javascript
    /// @dev 此接口仅共CoFiXRouter调用，来存入做市份额
    /// @param xtoken 目标份额代币地址（或CNode地址）
    /// @param to 存入的目标地址
    /// @param amount 存入数量
    function routerStake(address xtoken, address to, uint amount) external;
```

### 2.8. 存入做市份额

```javascript
    /// @dev 存入做市份额
    /// @param xtoken 目标份额代币地址（或CNode地址）
    /// @param amount 存入数量
    function stake(address xtoken, uint amount) external;
```

### 2.9. 取回做市份额，并领取CoFi

```javascript
    /// @dev 取回做市份额，并领取CoFi
    /// @param xtoken 目标份额代币地址（或CNode地址）
    /// @param amount 取回数量
    function withdraw(address xtoken, uint amount) external;
```

### 2.10. 领取CoFi

```javascript
    /// @dev 领取CoFi
    /// @param xtoken 目标份额代币地址（或CNode地址）
    function getReward(address xtoken) external;
```