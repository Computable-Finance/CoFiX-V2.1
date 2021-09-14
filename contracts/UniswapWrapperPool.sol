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

/// @dev UniswapWrapperPool
contract UniswapWrapperPool is CoFiXBase, ICoFiXPool, IUniswapV3SwapCallback {

    /* ******************************************************************************************
     * Note: In order to unify the authorization entry, all transferFrom operations are carried
     * out in the CoFiXRouter, and the CoFiXPool needs to be fixed, CoFiXRouter does trust and 
     * needs to be taken into account when calculating the pool balance before and after rollover
     * ******************************************************************************************/

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;

    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    address immutable public TARGET_UNISWAP_POOL;
    address immutable public TOKEN0;
    address immutable public TOKEN1;
    address immutable public WETH9;

    constructor (address targetUniswapPool, address weth9) {
        address token0 = IUniswapV3Pool(targetUniswapPool).token0();
        address token1 = IUniswapV3Pool(targetUniswapPool).token1();
        TARGET_UNISWAP_POOL = targetUniswapPool;
        TOKEN0 = token0 == weth9 ? address(0) : token0;
        TOKEN1 = token1 == weth9 ? address(0) : token1;
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
    
    // Transfer token, 0 address means eth
    function _transfer(address token, address to, uint value) private {
        if (value > 0) {
            if (token == address(0)) {
                payable(to).transfer(value);
            } else {
                TransferHelper.safeTransfer(token, to, value);
            }
        }
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
        // 1. Return unnecessary eth
        // The src is 0, which means that the ETH is transferred in and the part exceeding
        // the amountToken needs to be returned
        if (src == address(0)) {
            _transfer(address(0), payback, msg.value - amountIn);
        } 
        // If src is not 0, it means that the token is transferred in and all the transferred 
        // eth need to be returned
        else if (msg.value > 0) {
            payable(payback).transfer(msg.value);
        }

        bool zeroForOne;
        if (src == TOKEN0 && dest == TOKEN1) {
            console.log("true");
            zeroForOne = true;
        } else if (src == TOKEN1 && dest == TOKEN0) {
            console.log("false");
            zeroForOne = false;
        } else {
            revert("UWP:token error");
        }

        require(amountIn < 1 << 255, "UWP:amountIn too large");

        (int256 amount0, int256 amount1) = IUniswapV3Pool(TARGET_UNISWAP_POOL).swap(
            address(this),
            zeroForOne,
            int(amountIn),
            zeroForOne ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1,
            abi.encode(amountIn)
        );

        //console.log("swap-amount0", uint(-amount0));
        //console.log("swap-amount1", uint(amount1));

        // 目标代币是eth
        if (dest == address(0)) {
            amountOut = IWETH9(WETH9).balanceOf(address(this));
            if (amountOut > 0) {
                IWETH9(WETH9).withdraw(amountOut);
                TransferHelper.safeTransferETH(to, amountOut);
            }
        } 
        // 目标代币是token
        else {
            amountOut = IERC20(dest).balanceOf(address(this));
            TransferHelper.safeTransfer(dest, to, amountOut);
        }

        mined = 0;
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
            _pay(TOKEN0, address(this), msg.sender, uint(amount0Delta));
        }
        if (amount1Delta > 0) {
            require(amountIn == uint(amount1Delta), "UWP:not completed");
            _pay(TOKEN1, address(this), msg.sender, uint(amount1Delta));
        }
    }

    receive() external payable {
        //require(msg.sender == WETH9, 'Not WETH9');
    }

    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) external payable {
        uint256 balanceToken = IERC20(token).balanceOf(address(this));
        require(balanceToken >= amountMinimum, 'Insufficient token');

        if (balanceToken > 0) {
            TransferHelper.safeTransfer(token, recipient, balanceToken);
        }
    }

    /// @param token The token to pay
    /// @param payer The entity that must pay
    /// @param recipient The entity that will receive payment
    /// @param value The amount to pay
    function _pay(
        address token,
        address payer,
        address recipient,
        uint256 value
    ) private {
        if (token == address(0) && address(this).balance >= value) {
            // pay with WETH9
            IWETH9(WETH9).deposit{value: value}(); // wrap only what is needed to pay
            IWETH9(WETH9).transfer(recipient, value);
        } else if (payer == address(this)) {
            // pay with tokens already in the contract (for the exact input multihop case)
            TransferHelper.safeTransfer(token, recipient, value);
        } else {
            // pull payment
            TransferHelper.safeTransferFrom(token, payer, recipient, value);
        }
    }
}
