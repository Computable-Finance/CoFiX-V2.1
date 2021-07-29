# CoFiX v2.1 Contract Specification

## 1. Background
CoFiX v2.1 adds an anchor pool on the basis of v2.0, supports multi currency repurchase of CoFi, and introduces 
a modified volatility. In addition to the above adjustments, v2.1 also reconstructs the contract code after 
coding test and code inspection in the previous period.

## 2. Contract Structure

![avatar](CoFiX2.1.svg)

The contract relationship is shown in the figure above. The green contract is the contract that needs to be 
actually deployed, and the others are interface definitions or abstract contracts. The main points are as follows:

1. The contracts of the CoFiX system all inherit the CoFiXBase contract. The CoFiXBase contract mainly implements 
the logic that the contracts belonging to the CoFiX governance system which need to cooperate with the governance.

2. CoFiXGovernance is a CoFiX governance contract, which includes governance-related functions and realizes the 
mapping management of the built-in contract address in the CoFiX system.

3. CoFiXController Used to process logic related to price.

4. CoFiXRouter is the entrance to market making and trading. The main functions of the system start from here.

5. CoFiXPair provides the implementation of dual fund pool, which is also a transaction pair.

6. CoFiXAnchorPool provides the implementation of anchored fund pool, which can have multiple assets and 
provide n * (n-1) / 2 transaction pairs.

7. CoFiXAnchorToken is the market making share of the anchored fund pool. Each fund in the rivet fund pool 
corresponds to one anchored fund pool share.

8. CoFiXVaultForStaking provides the logic of market making and CNode ore drawing. The market making share and 
CNode deposit and receive COFI through the interface provided by this contract.

## 3. Interface Description

### 3.1. ICoFiXRouter

## 4. Data Structure

### 4.1. Defines the structure of a token channel

```javascript
    /// @dev Defines the structure of a token channel
    struct TokenInfo {
        // Address of token
        address tokenAddress;
        // Base of token (value is 10^decimals)
        uint96 base;
        // Address of corresponding xtoken
        address xtokenAddress;

        // Total mined
        uint112 _Y;
        // Adjusting to a balanced trade size
        uint112 _D;
        // Last update block
        uint32 _lastblock;
    }
```

### 4.2. Stake channel information

```javascript
    /// @dev Stake channel information
    struct StakeChannel{

        // Mining amount weight
        uint cofiWeight;
        // Total staked amount
        uint totalStaked;

        // xtoken global sign
        // Total ore drawing mark of settled transaction
        uint128 tradeReward;
        // Total settled ore output mark
        //uint128 totalReward;
        // The dividend mark that the settled company token can receive
        uint96 rewardPerToken;
        // Settlement block mark
        uint32 blockCursor;

        // Accounts
        // address=>balance
        mapping(address=>Account) accounts;
    }
```

## 5. Application scenarios

It mainly includes add liquidity, trade, buy back and other scenarios.
