// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./libs/TransferHelper.sol";

import "./CoFiXBase.sol";

import "./interfaces/external/IWETH9.sol";
import "./interfaces/ICoFiXPool.sol";

import "./uniswap/interfaces/IUniswapV3Pool.sol";
import "./uniswap/interfaces/callback/IUniswapV3SwapCallback.sol";

import "hardhat/console.sol";

/// @dev UniswapV3PoolAdapter
contract UniswapV3PoolAdapter is CoFiXBase, ICoFiXPool, IUniswapV3SwapCallback {

    /* ******************************************************************************************
     * Note: In order to unify the authorization entry, all transferFrom operations are carried
     * out in the CoFiXRouter, and the CoFiXPool needs to be fixed, CoFiXRouter does trust and 
     * needs to be taken into account when calculating the pool balance before and after rollover
     * ******************************************************************************************/

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;

    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    // token0地址，0表示eth
    address immutable public TOKEN0;

    // token1地址，0表示eth
    address immutable public TOKEN1;
    
    // 目标uniswap资金池地址
    address immutable public TARGET_UNISWAP_V3_POOL;
    
    // IWETH9实现合约地址
    address immutable public WETH9;

    /// @dev 构造uniswap适配资金池
    /// @param targetUniswapV3Pool 目标UniswapV3Pool地址
    /// @param weth9 目标IWETH9实现地址
    constructor (address targetUniswapV3Pool, address weth9) {
        address token0 = IUniswapV3Pool(targetUniswapV3Pool).token0();
        address token1 = IUniswapV3Pool(targetUniswapV3Pool).token1();
        TOKEN0 = token0 == weth9 ? address(0) : token0;
        TOKEN1 = token1 == weth9 ? address(0) : token1;
        TARGET_UNISWAP_V3_POOL = targetUniswapV3Pool;
        WETH9 = weth9;
    }

    /// @dev Set configuration
    /// @param theta Trade fee rate, ten thousand points system. 20
    /// @param impactCostVOL Impact cost threshold, this parameter is obsolete
    /// @param nt Each unit token (in the case of binary pools, eth) is used for the standard ore output, 1e18 based
    function setConfig(uint16 theta, uint96 impactCostVOL, uint96 nt) external override {
        revert("UWP:not support");
    }

    /// @dev Get configuration
    /// @return theta Trade fee rate, ten thousand points system. 20
    /// @return impactCostVOL Impact cost threshold, this parameter is obsolete
    /// @return nt Each unit token (in the case of binary pools, eth) is used for the standard ore output, 1e18 based
    function getConfig() external view override returns (uint16 theta, uint96 impactCostVOL, uint96 nt) {
        revert("UWP:not support");
    }

    /// @dev Add liquidity and mint xtoken
    /// @param token Target token address
    /// @param to The address to receive xtoken
    /// @param amountETH The amount of ETH added to pool. (When pool is AnchorPool, amountETH is 0)
    /// @param amountToken The amount of Token added to pool
    /// @param payback As the charging fee may change, it is suggested that the caller pay more fees, 
    /// and the excess fees will be returned through this address
    /// @return xtoken The liquidity share token address obtained
    /// @return liquidity The real liquidity or XToken minted from pool
    function mint(
        address token,
        address to, 
        uint amountETH, 
        uint amountToken,
        address payback
    ) external payable override returns (
        address xtoken,
        uint liquidity
    ) {
        revert("UWP:not support");
    }

    /// @dev Maker remove liquidity from pool to get ERC20 Token and ETH back (maker burn XToken) 
    /// @param token The address of ERC20 Token
    /// @param to The target address receiving the Token
    /// @param liquidity The amount of liquidity (XToken) sent to pool, or the liquidity to remove
    /// @param payback As the charging fee may change, it is suggested that the caller pay more fees, 
    /// and the excess fees will be returned through this address
    /// @return amountETHOut The real amount of ETH transferred from the pool
    /// @return amountTokenOut The real amount of Token transferred from the pool
    function burn(
        address token,
        address to, 
        uint liquidity, 
        address payback
    ) external payable override returns (
        uint amountETHOut,
        uint amountTokenOut 
    ) {
        revert("UWP:not support");
    }

    /// @dev Gets the token address of the share obtained by the specified token market making
    /// @param token Target token address
    /// @return If the fund pool supports the specified token, return the token address of the market share
    function getXToken(address token) external view override returns (address) {
        revert("UWP:not support");
    }

    /// @dev Swap token
    /// @param src Src token address
    /// @param dest Dest token address
    /// @param amountIn The exact amount of Token a trader want to swap into pool
    /// @param to The target address receiving the ETH
    /// @param payback As the charging fee may change, it is suggested that the caller pay more fees, 
    /// and the excess fees will be returned through this address
    /// @return amountOut The real amount of ETH transferred out of pool
    /// @return mined The amount of CoFi which will be mind by this trade
    function swap(
        address src, 
        address dest, 
        uint amountIn, 
        address to, 
        address payback
    ) external payable override returns (
        uint amountOut, 
        uint mined
    ) {
        require(amountIn < 0x8000000000000000000000000000000000000000000000000000000000000000, "UWP:amountIn too large");

        // 1. Return unnecessary eth
        // The src is 0, which means that the ETH is transferred in and the part exceeding
        // the amountToken needs to be returned
        if (src == address(0)) {
            if (msg.value > amountIn) {
                payable(payback).transfer(msg.value - amountIn);
            }
        } 
        // If src is not 0, it means that the token is transferred in and all the transferred 
        // eth need to be returned
        else if (msg.value > 0) {
            payable(payback).transfer(msg.value);
        }

        // 2. 确定交易方向
        bool zeroForOne;
        if (src == TOKEN0 && dest == TOKEN1) {
            zeroForOne = true;
        } else if (src == TOKEN1 && dest == TOKEN0) {
            zeroForOne = false;
        } else {
            revert("UWP:token error");
        }

        // 3. 调用uniswap v3 pool执行交易
        // /// @notice Swap token0 for token1, or token1 for token0
        // /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
        // /// @param recipient The address to receive the output of the swap
        // /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
        // /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
        // /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
        // /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
        // /// @param data Any data to be passed through to the callback
        // /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
        // /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
        // function swap(
        //     address recipient,
        //     bool zeroForOne,
        //     int256 amountSpecified,
        //     uint160 sqrtPriceLimitX96,
        //     bytes calldata data
        // ) external returns (int256 amount0, int256 amount1);

        (int256 amount0, int256 amount1) = IUniswapV3Pool(TARGET_UNISWAP_V3_POOL).swap(
            address(this),
            zeroForOne,
            int(amountIn),
            zeroForOne ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1,
            abi.encode(amountIn)
        );

        // 4. 检查交易结果
        require(zeroForOne ? amount0 > 0 && amount1 < 0 : amount0 < 0 && amount1 > 0, "UWP:balance error");
        require(amountIn == (zeroForOne ? uint(amount0) : uint(amount1)), "UWP:amountIn error");
        mined = 0;

        // 5. 讲兑换到的代币转到目标地址
        amountOut = zeroForOne ? uint(-amount1) : uint(-amount0);
        // 目标代币是eth
        if (dest == address(0)) {
            IWETH9(WETH9).withdraw(amountOut);
            TransferHelper.safeTransferETH(to, amountOut);
        } 
        // 目标代币是token
        else {
            TransferHelper.safeTransfer(dest, to, amountOut);
        }
    }

    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external override {

        uint amountIn = abi.decode(data, (uint));
        if (amount0Delta > 0) {
            require(amountIn == uint(amount0Delta), "UWP:not completed");
            _pay(TOKEN0, msg.sender, uint(amount0Delta));
        }
        if (amount1Delta > 0) {
            require(amountIn == uint(amount1Delta), "UWP:not completed");
            _pay(TOKEN1, msg.sender, uint(amount1Delta));
        }
    }

    receive() external payable {
        //require(msg.sender == WETH9, 'Not WETH9');
    }
    
    /// @param token The token to pay
    /// @param recipient The entity that will receive payment
    /// @param value The amount to pay
    function _pay(
        address token,
        address recipient,
        uint256 value
    ) private {
        if (token == address(0)) {
            // pay with WETH9
            IWETH9(WETH9).deposit{value: value}(); // wrap only what is needed to pay
            IWETH9(WETH9).transfer(recipient, value);
        } else {
            // pay with tokens already in the contract (for the exact input multihop case)
            TransferHelper.safeTransfer(token, recipient, value);
        }
    }
}
