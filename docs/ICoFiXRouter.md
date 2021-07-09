# ICoFiXRouter

## 1. Interface Description
    This interface defines methods for CoFiXRouter

## 2. Method Description

### 2.1. 注册交易对

```javascript
    /// @dev 注册交易对
    /// @param token0 交易对token0。（0地址表示eth）
    /// @param token1 交易对token1。（0地址表示eth）
    /// @param pair 交易对资金池
    function registerPair(address token0, address token1, address pair) external;
```

### 2.2. 根据token地址获取交易对

```javascript
    /// @dev 根据token地址对获取交易资金池
    /// @param token0 交易对token0。（0地址表示eth）
    /// @param token1 交易对token1。（0地址表示eth）
    /// @return pool 交易资金池
    function pairFor(address token0, address token1) external view returns (address pool);
```

### 2.3. 注册路由路径

```javascript
    /// @dev 注册路由路径
    /// @param src 源token地址
    /// @param dest 目标token地址
    /// @param path 路由地址
    function registerRouterPath(address src, address dest, address[] calldata path) external;
```

### 2.4. 查找从源token地址到目标token地址的路由路径

```javascript
    /// @dev 查找从源token地址到目标token地址的路由路径
    /// @param src 源token地址
    /// @param dest 目标token地址
    /// @return path 如果找到，返回路由路径，数组中的每一个地址表示兑换过程中经历的token地址。
    function getRouterPath(address src, address dest) external view returns (address[] memory path);
```

### 2.5. Maker add liquidity to pool

```javascript
    /// @dev Maker add liquidity to pool, get pool token (mint XToken to maker) (notice: msg.value = amountETH + oracle fee)
    /// @param  pool The address of pool
    /// @param  token The address of ERC20 Token
    /// @param  amountETH The amount of ETH added to pool. (When pool is AnchorPool, amountETH is 0)
    /// @param  amountToken The amount of Token added to pool
    /// @param  liquidityMin The minimum liquidity maker wanted
    /// @param  to The target address receiving the liquidity pool (XToken)
    /// @param  deadline The dealine of this request
    /// @return xtoken 获得的流动性份额代币地址
    /// @return liquidity The real liquidity or XToken minted from pool
    function addLiquidity(
        address pool,
        address token,
        uint amountETH,
        uint amountToken,
        uint liquidityMin,
        address to,
        uint deadline
    ) external payable returns (address xtoken, uint liquidity);
```
    Note: 当前有两种资金池：二元池和锚定池，给二元池添加流动性需要按比例同时提供eth和token，给锚定池添加流动性则需要单个资产添加，因此在给锚定池添加流动性时，amountETH应当为0（对于ETH锚定池，添加流动性时，amountETH为0，amountToken为eth数量，token为0地址）。

### 2.6. Maker add liquidity to pool and stake

```javascript
    /// @dev Maker add liquidity to pool, get pool token (mint XToken) and stake automatically (notice: msg.value = amountETH + oracle fee)
    /// @param  pool The address of pool
    /// @param  token The address of ERC20 Token
    /// @param  amountETH The amount of ETH added to pool. (When pool is AnchorPool, amountETH is 0)
    /// @param  amountToken The amount of Token added to pool
    /// @param  liquidityMin The minimum liquidity maker wanted
    /// @param  to The target address receiving the liquidity pool (XToken)
    /// @param  deadline The dealine of this request
    /// @return xtoken 获得的流动性份额代币地址
    /// @return liquidity The real liquidity or XToken minted from pool
    function addLiquidityAndStake(
        address pool,
        address token,
        uint amountETH,
        uint amountToken,
        uint liquidityMin,
        address to,
        uint deadline
    ) external payable returns (address xtoken, uint liquidity);
```

### 2.7. Maker remove liquidity from pool

```javascript
    /// @dev Maker remove liquidity from pool to get ERC20 Token and ETH back (maker burn XToken) (notice: msg.value = oracle fee)
    /// @param  pool The address of pool
    /// @param  token The address of ERC20 Token
    /// @param  liquidity The amount of liquidity (XToken) sent to pool, or the liquidity to remove
    /// @param  amountETHMin The minimum amount of ETH wanted to get from pool
    /// @param  to The target address receiving the Token
    /// @param  deadline The dealine of this request
    /// @return amountToken The real amount of Token transferred from the pool
    /// @return amountETH The real amount of ETH transferred from the pool
    function removeLiquidityGetTokenAndETH(
        address pool,
        address token,
        uint liquidity,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH);
```

### 2.8. Trader swap exact amount of ETH for ERC20 Tokens

```javascript
    /// @dev Trader swap exact amount of ETH for ERC20 Tokens (notice: msg.value = amountIn + oracle fee)
    /// @param  token The address of ERC20 Token
    /// @param  amountIn The exact amount of ETH a trader want to swap into pool
    /// @param  amountOutMin The minimum amount of Token a trader want to swap out of pool
    /// @param  to The target address receiving the Token
    /// @param  rewardTo The target address receiving the CoFi Token as rewards
    /// @param  deadline The dealine of this request
    /// @return amountOut The real amount of Token transferred out of pool
    function swapExactETHForTokens(
        address token,
        uint amountIn,
        uint amountOutMin,
        address to,
        address rewardTo,
        uint deadline
    ) external payable returns (uint amountOut);
```

### 2.9. Trader swap exact amount of ERC20 Tokens for ETH

```javascript
    /// @dev Trader swap exact amount of ERC20 Tokens for ETH (notice: msg.value = oracle fee)
    /// @param  token The address of ERC20 Token
    /// @param  amountIn The exact amount of Token a trader want to swap into pool
    /// @param  amountOutMin The mininum amount of ETH a trader want to swap out of pool
    /// @param  to The target address receiving the ETH
    /// @param  rewardTo The target address receiving the CoFi Token as rewards
    /// @param  deadline The dealine of this request
    /// @return amountOut The real amount of ETH transferred out of pool
    function swapExactTokensForETH(
        address token,
        uint amountIn,
        uint amountOutMin,
        address to,
        address rewardTo,
        uint deadline
    ) external payable returns (uint amountOut);
```

### 2.10. 执行兑换交易

```javascript
    /// @dev 执行兑换交易
    /// @param  src 源资产token地址
    /// @param  dest 目标资产token地址
    /// @param  amountIn The exact amount of Token a trader want to swap into pool
    /// @param  amountOutMin The mininum amount of ETH a trader want to swap out of pool
    /// @param  to The target address receiving the ETH
    /// @param  rewardTo The target address receiving the CoFi Token as rewards
    /// @param  deadline The dealine of this request
    /// @return amountOut The real amount of ETH transferred out of pool
    function swap(
        address src, 
        address dest, 
        uint amountIn,
        uint amountOutMin,
        address to,
        address rewardTo,
        uint deadline
    ) external payable returns (uint amountOut);
```

### 2.11. 多级路由兑换

```javascript
    /// @dev 多级路由兑换
    /// @param  path 路由路径
    /// @param  amountIn The exact amount of Token a trader want to swap into pool
    /// @param  amountOutMin The mininum amount of ETH a trader want to swap out of pool
    /// @param  to The target address receiving the ETH
    /// @param  rewardTo The target address receiving the CoFi Token as rewards
    /// @param  deadline The dealine of this request
    /// @return amounts 兑换路径中每次换得的资产数量
    function swapExactTokensForTokens(
        address[] calldata path,
        uint amountIn,
        uint amountOutMin,
        address to,
        address rewardTo,
        uint deadline
    ) external payable returns (uint[] memory amounts);
```
    Note: 多级路由兑换，path可以通过getRouterPath()查询，也可以前端缓存交易对数据，自行生成。

### 2.12. 获取目标pair的交易挖矿分成

```javascript
    /// @dev 获取目标pair的交易挖矿分成
    /// @param pair 目标pair地址
    /// @return 目标pair的交易挖矿分成
    function getTradeReward(address pair) external view returns (uint);
```