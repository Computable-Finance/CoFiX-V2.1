# CoFiX v2.1 Contract Specification

## 1. Background
CoFiX v2.1添加了锚定池逻辑和其他一些功能性修改，并对合约结构和代码进行了优化设计。

## 2. Contract Structure

![avatar](CoFiX2.1.svg)

The contract relationship is shown in the figure above. The green contract is the contract that needs to be actually deployed, and the others are interface definitions or abstract contracts. The main points are as follows:

1. The contracts of the CoFiX system all inherit the CoFiXBase contract. The CoFiXBase contract mainly implements the logic that the contracts belonging to the CoFiX governance system which need to cooperate with the governance.

2. CoFiXGovernance is a CoFiX governance contract, which includes governance-related functions and realizes the mapping management of the built-in contract address in the CoFiX system.

3. CoFiXController合约用于处理和价格相关的逻辑。

4. CoFiXRouter合约是做市和交易的入口，系统的主要功能从这里开始。

5. CoFiXPair合约提供了二元资金池的实现，二元资金池同时也是一个交易对。

6. CoFiXAnchorPool合约提供了锚定资金池的实现，锚定资金池可以有多个资产，并提供n*(n-1)/2个交易对。

7. CoFiXAnchorToken是锚定资金池的做市份额，铆钉资金池中的每中资金对应一个锚定资金池份额。

8. CoFiXVaultForStaking提供了做市和CNode出矿的逻辑，做市份额和CNode通过此合约提供的接口来存入和领取CoFi。

## 3. Interface Description

### 3.1. ICoFiXRouter

## 4. Data Structure

### 4.1. 锚定池代币信息

```javascript
    /// @dev 锚定池代币信息
    struct TokenInfo {
        // token地址
        address tokenAddress;
        // token单位（等于10^decimals）
        uint96 base;
        // 对应的xtoken地址
        address xtokenAddress;

        // 累计出矿量
        uint112 _Y;
        // 调整到平衡的交易规模
        uint112 _D;
        // 最后更新区块
        uint32 _lastblock;
    }
```

### 4.2. Stake通道信息

```javascript
    /// @dev Stake通道信息
    struct StakeChannel{

        // 配置
        // 出矿权重
        uint cofiWeight;
        // stake数量
        uint totalStaked;

        // pair全局挖矿标记
        // 已结算的交易出矿总量标记
        uint128 tradeReward;
        // 已结算的总出矿量标记
        //uint128 totalReward;
        // 已结算的单位token可以领取的分红标记
        uint96 rewardPerToken;
        // 结算区块标记
        uint32 blockCursor;

        // 账户标记
        // address=>balance
        mapping(address=>Account) accounts;
    }
```

## 5. Application scenarios

It mainly includes add liquidity, trade, buy back and other scenarios.
