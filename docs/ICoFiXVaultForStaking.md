# ICoFiXVaultForStaking

## 1. Interface Description
    This interface defines methods for CoFiXVaultForStaking.

## 2. Method Description

### 2.1. Modify configuration

```javascript
    /// @dev Modify configuration
    /// @param cofiUnit CoFi mining unit
    function setConfig(uint cofiUnit) external;
```

### 2.2. Get configuration

```javascript
    /// @dev Get configuration
    /// @return cofiUnit CoFi mining unit
    function getConfig() external view returns (uint cofiUnit);
```

### 2.3. Initialize ore drawing weight

```javascript
    /// @dev Initialize ore drawing weight
    /// @param xtokens xtoken array
    /// @param weights weight array
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

### 2.5. Get staked amount of target address

```javascript
    /// @dev Get staked amount of target address
    /// @param xtoken xtoken address (or CNode address)
    /// @param addr Target address
    /// @return Staked amount of target address
    function balanceOf(address xtoken, address addr) external view returns (uint);
```

### 2.6. Get the number of CoFi to be collected by the target address

```javascript
    /// @dev Get the number of CoFi to be collected by the target address on the designated transaction pair lock
    /// @param xtoken xtoken address (or CNode address)
    /// @param addr Target address
    /// @return The number of CoFi to be collected by the target address on the designated transaction lock
    function earned(address xtoken, address addr) external view returns (uint);
```

### 2.7. Stake xtoken to earn CoFi, this method is only for CoFiXRouter

```javascript
    /// @dev Stake xtoken to earn CoFi, this method is only for CoFiXRouter
    /// @param xtoken xtoken address (or CNode address)
    /// @param to Target address
    /// @param amount Stake amount
    function routerStake(address xtoken, address to, uint amount) external;
```

### 2.8. Stake xtoken to earn CoFi

```javascript
    /// @dev Stake xtoken to earn CoFi
    /// @param xtoken xtoken address (or CNode address)
    /// @param amount Stake amount
    function stake(address xtoken, uint amount) external;
```

### 2.9. Withdraw xtoken, and claim earned CoFi

```javascript
    /// @dev Withdraw xtoken, and claim earned CoFi
    /// @param xtoken xtoken address (or CNode address)
    /// @param amount Withdraw amount
    function withdraw(address xtoken, uint amount) external;
```

### 2.10. Claim CoFi

```javascript
    /// @dev Claim CoFi
    /// @param xtoken xtoken address (or CNode address)
    function getReward(address xtoken) external;
```