// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.7.6;

import "../uniswap/interfaces/IUniswapV3Pool.sol";
import '../uniswap/libraries/TickMath.sol';

import "../uniswap/UniswapV3Pool.sol";

import "hardhat/console.sol";

contract TestRouter {

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

	address _factory;

	constructor(address factory) {
		_factory = factory;
	}

	// /// @dev Deploys a pool with the given parameters by transiently setting the parameters storage slot and then
    // /// clearing it after deploying the pool.
    // /// @param factory The contract address of the Uniswap V3 factory
    // /// @param token0 The first token of the pool by address sort order
    // /// @param token1 The second token of the pool by address sort order
    // /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    // /// @param tickSpacing The spacing between usable ticks
    // function deploy(
    //     address factory,
    //     address token0,
    //     address token1,
    //     uint24 fee,
    //     int24 tickSpacing
    // ) internal returns (address pool) {
    //     parameters = Parameters({factory: factory, token0: token0, token1: token1, fee: fee, tickSpacing: tickSpacing});
    //     pool = address(new UniswapV3Pool{salt: keccak256(abi.encode(token0, token1, fee))}());
    //     delete parameters;
    // }

	// 获取资金池地址
	function getPool(address token0, address token1, uint24 fee) public view returns (address) {
        (token0, token1) = token0 < token1 ? (token0, token1) : (token1, token0);
		address predictedAddress = address(uint160(uint(keccak256(abi.encodePacked(
            bytes1(0xff),
            _factory,
            keccak256(abi.encode(token0, token1, fee)),
            bytes32(0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54)
        ))))); 
		return predictedAddress;
	}

    // rinkeby
    //bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;
    //address internal constant UNISWAP_V3_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;

    // mainnet
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;
    address internal constant UNISWAP_V3_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;

    function getUniswapPool(address token0, address token1, uint24 fee) external view returns (address) {
        (token0, token1) = token0 < token1 ? (token0, token1) : (token1, token0);
		address predictedAddress = address(uint160(uint(keccak256(abi.encodePacked(
            bytes1(0xff),
            UNISWAP_V3_FACTORY,
            keccak256(abi.encode(token0, token1, fee)),
            POOL_INIT_CODE_HASH
        ))))); 
		return predictedAddress;
    }

	function swap(address token0, address token1, uint24 fee, uint amount) external {
		address pool = getPool(token0, token1, fee);
        //console.log("router-v", TickMath.MIN_SQRT_RATIO);
		IUniswapV3Pool(pool).swap(
			msg.sender,
			false,
			1000000,
			TickMath.MAX_SQRT_RATIO - 1,
			abi.encode(msg.sender)
		);
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
    ) external {
		address payer = abi.decode(data, (address));
        if (amount0Delta > 0) {
            IERC20Minimal(IUniswapV3Pool(msg.sender).token0()).transferFrom(
                    payer,
                    msg.sender,
                    uint256(amount0Delta)
            );
        }

        if (amount1Delta > 0) {
            IERC20Minimal(IUniswapV3Pool(msg.sender).token1()).transferFrom(
                    payer,
                    msg.sender,
                    uint256(amount1Delta)
            );
        }
    }
    
	// /// @inheritdoc IUniswapV3PoolActions
    // /// @dev noDelegateCall is applied indirectly via _modifyPosition
    // function mint(
    //     address recipient,
    //     int24 tickLower,
    //     int24 tickUpper,
    //     uint128 amount,
    //     bytes calldata data
    // )

	function mint(address pool, uint amount) external {
		//address pool = getPool(token0, token1, fee);

		IUniswapV3Pool(pool).mint(
			msg.sender,
			-100000,
			100000,
			uint128(amount),
			abi.encode(msg.sender)
		);
	}

	/// @notice Called to `msg.sender` after minting liquidity to a position from IUniswapV3Pool#mint.
    /// @dev In the implementation you must pay the pool tokens owed for the minted liquidity.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// @param amount0Owed The amount of token0 due to the pool for the minted liquidity
    /// @param amount1Owed The amount of token1 due to the pool for the minted liquidity
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#mint call
    function uniswapV3MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata data
    ) external {

        //console.log('uniswapV3MintCallback-amount0Owed', amount0Owed);
        //console.log('uniswapV3MintCallback-amount1Owed', amount1Owed);

		address payer = abi.decode(data, (address));
		if (amount0Owed > 0) {
			IERC20Minimal(IUniswapV3Pool(msg.sender).token0()).transferFrom(
                    payer,
                    msg.sender,
                    uint256(amount0Owed)
            );
		}
		if (amount1Owed > 0) {
			IERC20Minimal(IUniswapV3Pool(msg.sender).token1()).transferFrom(
                    payer,
                    msg.sender,
                    uint256(amount1Owed)
            );
		}
	}
}