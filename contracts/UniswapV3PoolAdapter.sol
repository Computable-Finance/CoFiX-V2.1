// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./libs/TransferHelper.sol";

import "./CoFiXBase.sol";

import "./interfaces/external/IWETH9.sol";
import "./interfaces/ICoFiXPool.sol";

import "./uniswap/interfaces/IUniswapV3Pool.sol";
import "./uniswap/interfaces/callback/IUniswapV3SwapCallback.sol";

/// @dev UniswapV3PoolAdapter
contract UniswapV3PoolAdapter is CoFiXBase,/* ICoFiXPool, */ IUniswapV3SwapCallback {

    /* ******************************************************************************************
     * Note: In order to unify the authorization entry, all transferFrom operations are carried
     * out in the CoFiXRouter, and the CoFiXPool needs to be fixed, CoFiXRouter does trust and 
     * needs to be taken into account when calculating the pool balance before and after rollover
     * ******************************************************************************************/

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;

    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    // Address of token0, 0 means eth
    address immutable public TOKEN0;

    // Address of token1, 0 means eth
    address immutable public TOKEN1;
    
    // Target uniswap pool
    address immutable public TARGET_UNISWAP_V3_POOL;
    
    // IWETH9 contract address
    address immutable public WETH9;

    /// @dev Constructor of uniswap pool
    /// @param targetUniswapV3Pool Target UniswapV3Pool
    /// @param weth9 IWETH9 contract address
    constructor (address targetUniswapV3Pool, address weth9) {
        address token0 = IUniswapV3Pool(targetUniswapV3Pool).token0();
        address token1 = IUniswapV3Pool(targetUniswapV3Pool).token1();
        TOKEN0 = token0 == weth9 ? address(0) : token0;
        TOKEN1 = token1 == weth9 ? address(0) : token1;
        TARGET_UNISWAP_V3_POOL = targetUniswapV3Pool;
        WETH9 = weth9;
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
    ) external payable returns (
        uint amountOut, 
        uint mined
    ) {
        require(
            amountIn < 0x8000000000000000000000000000000000000000000000000000000000000000, 
            "UWP:amountIn too large"
        );

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

        // 2. Make sure swap direction
        bool zeroForOne;
        if (src == TOKEN0 && dest == TOKEN1) {
            zeroForOne = true;
        } else if (src == TOKEN1 && dest == TOKEN0) {
            zeroForOne = false;
        } else {
            revert("UWP:token error");
        }

        // 3. Swap with uniswap v3 pool
        (int256 amount0, int256 amount1) = IUniswapV3Pool(TARGET_UNISWAP_V3_POOL).swap(
            address(this),
            zeroForOne,
            int(amountIn),
            zeroForOne ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1,
            abi.encode(amountIn)
        );

        // 4. Check swap result
        require(zeroForOne ? amount0 > 0 && amount1 < 0 : amount0 < 0 && amount1 > 0, "UWP:balance error");
        require(amountIn == (zeroForOne ? uint(amount0) : uint(amount1)), "UWP:amountIn error");
        mined = 0;

        // 5. Transfer token to target address
        amountOut = zeroForOne ? uint(-amount1) : uint(-amount0);
        // Token is eth
        if (dest == address(0)) {
            IWETH9(WETH9).withdraw(amountOut);
            TransferHelper.safeTransferETH(to, amountOut);
        } 
        // Token is erc20
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
