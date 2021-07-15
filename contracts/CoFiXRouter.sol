// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./libs/TransferHelper.sol";

import "./interfaces/ICoFiXRouter.sol";
import "./interfaces/ICoFiXPool.sol";
import "./interfaces/ICoFiXVaultForStaking.sol";

import "./CoFiXBase.sol";
import "./CoFiToken.sol";

import "hardhat/console.sol";

/// @dev Router contract to interact with each CoFiXPair
contract CoFiXRouter is CoFiXBase, ICoFiXRouter {

    /* ******************************************************************************************
     * Note: In order to unify the authorization entry, all transferFrom operations are carried
     * out in the CofixRouter, and the CofixPool needs to be fixed, CofixRouter does trust and 
     * needs to be taken into account when calculating the pool balance before and after rollover
     * ******************************************************************************************/

    // Address of CoFiXVaultForStaing
    address _cofixVaultForStaking;

    // Mapping for trade pairs. keccak256(token0, token1)=>pool
    mapping(bytes32=>address) _pairs;

    // Mapping for trade paths. keccak256(token0, token1) = > path
    mapping(bytes32=>address[]) _paths;

    // Record the total CoFi share of CNode
    uint _cnodeReward;

    /// @dev Create CoFiXRouter
    constructor () {
    }

    // Verify that the cutoff time has exceeded
    modifier ensure(uint deadline) {
        require(block.timestamp <= deadline, "CoFiXRouter: EXPIRED");
        _;
    }

    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(newGovernance) when overriding, and override method without onlyGovernance
    /// @param newGovernance ICoFiXGovernance implementation contract address
    function update(address newGovernance) public override {
        super.update(newGovernance);
        _cofixVaultForStaking = ICoFiXGovernance(newGovernance).getCoFiXVaultForStakingAddress();
    }

    /// @dev Register trade pair
    /// @param token0 pair-token0. 0 address means eth
    /// @param token1 pair-token1. 0 address means eth
    /// @param pool Pool for the trade pair
    function registerPair(address token0, address token1, address pool) public override onlyGovernance {
        _pairs[_getKey(token0, token1)] = pool;
    }

    /// @dev Get pool address for trade pair
    /// @param token0 pair-token0. 0 address means eth
    /// @param token1 pair-token1. 0 address means eth
    /// @return pool Pool for the trade pair
    function pairFor(address token0, address token1) external view override returns (address pool) {
        return _pairFor(token0, token1);
    }

    /// @dev Register routing path
    /// @param src Src token address
    /// @param dest Dest token address
    /// @param path Routing path
    function registerRouterPath(address src, address dest, address[] calldata path) external override onlyGovernance {
        // Check that the source and destination addresses are correct
        require(src == path[0], "CoFiXRouter: first token error");
        require(dest == path[path.length - 1], "CoFiXRouter: last token error");
        // Register routing path
        _paths[_getKey(src, dest)] = path;
    }

    /// @dev Get routing path from src token address to dest token address
    /// @param src Src token address
    /// @param dest Dest token address
    /// @return path If success, return the routing path, 
    /// each address in the array represents the token address experienced during the trading
    function getRouterPath(address src, address dest) external view override returns (address[] memory path) {
        // Load the routing path
        path = _paths[_getKey(src, dest)];
        uint j = path.length;

        // If it is a reverse path, reverse the path
        require(j > 0, 'CoFiXRouter: path not exist');
        if (src == path[--j] && dest == path[0]) {
            for (uint i = 0; i < j;) {
                address tmp = path[i];
                path[i++] = path[j];
                path[j--] = tmp;
            }
        } else {
            require(src == path[0] && dest == path[j], 'CoFiXRouter: path error');
        }
    }
    
    /// @dev Get pool address for trade pair
    /// @param token0 pair-token0. 0 address means eth
    /// @param token1 pair-token1. 0 address means eth
    /// @return pool Pool for the trade pair
    function _pairFor(address token0, address token1) private view returns (address pool) {
        return _pairs[_getKey(token0, token1)];
    }

    // Generate the mapping key based on the token address
    function _getKey(address token0, address token1) private pure returns (bytes32) {
        (token0, token1) = _sort(token0, token1);
        return keccak256(abi.encodePacked(token0, token1));
    }

    // Sort the address pair
    function _sort(address token0, address token1) private pure returns (address min, address max) {
        if (token0 < token1) {
            min = token0;
            max = token1;
        } else {
            min = token1;
            max = token0;
        }
    }

    /// @dev Maker add liquidity to pool, get pool token (mint XToken to maker) 
    /// (notice: msg.value = amountETH + oracle fee)
    /// @param  pool The address of pool
    /// @param  token The address of ERC20 Token
    /// @param  amountETH The amount of ETH added to pool. (When pool is AnchorPool, amountETH is 0)
    /// @param  amountToken The amount of Token added to pool
    /// @param  liquidityMin The minimum liquidity maker wanted
    /// @param  to The target address receiving the liquidity pool (XToken)
    /// @param  deadline The dealine of this request
    /// @return xtoken The liquidity share token address obtained
    /// @return liquidity The real liquidity or XToken minted from pool
    function addLiquidity(
        address pool,
        address token,
        uint amountETH,
        uint amountToken,
        uint liquidityMin,
        address to,
        uint deadline
    ) external override payable ensure(deadline) returns (address xtoken, uint liquidity) {
        // 1. Transfer token to pool
        if (token != address(0)) {
            TransferHelper.safeTransferFrom(token, msg.sender, pool, amountToken);
        }

        // 2. Add liquidity, and increate xtoken
        (xtoken, liquidity) = ICoFiXPool(pool).mint { 
            value: msg.value 
        } (token, to, amountETH, amountToken, to);

        // The number of shares should not be lower than the expected minimum value
        require(liquidity >= liquidityMin, "CoFiXRouter: less liquidity than expected");
    }

    /// @dev Maker add liquidity to pool, get pool token (mint XToken) and stake automatically 
    /// (notice: msg.value = amountETH + oracle fee)
    /// @param  pool The address of pool
    /// @param  token The address of ERC20 Token
    /// @param  amountETH The amount of ETH added to pool. (When pool is AnchorPool, amountETH is 0)
    /// @param  amountToken The amount of Token added to pool
    /// @param  liquidityMin The minimum liquidity maker wanted
    /// @param  to The target address receiving the liquidity pool (XToken)
    /// @param  deadline The dealine of this request
    /// @return xtoken The liquidity share token address obtained
    /// @return liquidity The real liquidity or XToken minted from pool
    function addLiquidityAndStake(
        address pool,
        address token,
        uint amountETH,
        uint amountToken,
        uint liquidityMin,
        address to,
        uint deadline
    ) external override payable ensure(deadline) returns (address xtoken, uint liquidity) {
        // 1. Transfer token to pool
        if (token != address(0)) {
            TransferHelper.safeTransferFrom(token, msg.sender, pool, amountToken);
        }

        // 2. Add liquidity, and increate xtoken
        address cofixVaultForStaking = _cofixVaultForStaking;
        (xtoken, liquidity) = ICoFiXPool(pool).mint { 
            value: msg.value 
        } (token, cofixVaultForStaking, amountETH, amountToken, to);

        // The number of shares should not be lower than the expected minimum value
        require(liquidity >= liquidityMin, "CoFiXRouter: less liquidity than expected");

        // 3. Stake xtoken to CoFiXVaultForStaking
        ICoFiXVaultForStaking(cofixVaultForStaking).routerStake(xtoken, to, liquidity);
    }

    /// @dev Maker remove liquidity from pool to get ERC20 Token and ETH back (maker burn XToken) 
    /// (notice: msg.value = oracle fee)
    /// @param  pool The address of pool
    /// @param  token The address of ERC20 Token
    /// @param  liquidity The amount of liquidity (XToken) sent to pool, or the liquidity to remove
    /// @param  amountETHMin The minimum amount of ETH wanted to get from pool
    /// @param  to The target address receiving the Token
    /// @param  deadline The dealine of this request
    /// @return amountETH The real amount of ETH transferred from the pool
    /// @return amountToken The real amount of Token transferred from the pool
    function removeLiquidityGetTokenAndETH(
        address pool,
        address token,
        uint liquidity,
        uint amountETHMin,
        address to,
        uint deadline
    ) external override payable ensure(deadline) returns (uint amountETH, uint amountToken) {
        // 0. Get xtoken corresponding to the token
        address xtoken = ICoFiXPool(pool).getXToken(token);

        // 1. Transfer xtoken to pool
        TransferHelper.safeTransferFrom(xtoken, msg.sender, pool, liquidity);

        // 2. Remove liquidity and return tokens
        (amountETH, amountToken) = ICoFiXPool(pool).burn {
            value: msg.value
        } (token, to, liquidity, to);

        // 3. amountETH must not less than expected
        require(amountETH >= amountETHMin, "CoFiXRouter: less eth than expected");
    }

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
    ) external override payable ensure(deadline) returns (uint amountOut) {
        // 0. Get xtoken corresponding to the token
        address pair = _pairFor(address(0), token);

        // 1. Trade
        uint mined;
        (amountOut, mined) = ICoFiXPool(pair).swap {
            value: msg.value
        } (address(0), token, amountIn, to, to);
        
        // 2. amountOut must not less than expected
        require(amountOut >= amountOutMin, "CoFiXRouter: got less eth than expected");

        // 3. Mining cofi for trade
        _mint(mined, rewardTo);
    }

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
    ) external override payable ensure(deadline) returns (uint amountOut) {
        // 0. Get pool address for trade pair
        address pool = _pairFor(address(0), token);

        // 1. Transfer token to the pool and Trade
        TransferHelper.safeTransferFrom(token, msg.sender, pool, amountIn);
        uint mined;
        (amountOut, mined) = ICoFiXPool(pool).swap {
            value: msg.value
        } (token, address(0), amountIn, to, to);

        // 2. amountOut must not less than expected
        require(amountOut >= amountOutMin, "CoFiXRouter: got less eth than expected");

        // 3. Mining cofi for trade
        _mint(mined, rewardTo);
    }

    /// @dev Swap tokens for tokens
    /// @param  src Src token address
    /// @param  dest Dest token address
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
    ) external override payable ensure(deadline) returns (uint amountOut) {
        // 0. Get pool address for trade pair
        address pool = _pairFor(src, dest);

        // 1. Transfer token to the pool
        if (src != address(0)) {
            TransferHelper.safeTransferFrom(src, msg.sender, pool, amountIn);
        }

        // 2. Trade
        uint mined;
        (amountOut, mined) = ICoFiXPool(pool).swap {
            value: msg.value
        } (src, dest, amountIn, to, to);

        // 3. amountOut must not less than expected
        require(amountOut >= amountOutMin, "CoFiXRouter: got less eth than expected");

        // 4. Mining cofi for trade
        _mint(mined, rewardTo);
    }

    /// @dev Swap tokens for tokens with routing path
    /// @param  path Routing path
    /// @param  amountIn The exact amount of Token a trader want to swap into pool
    /// @param  amountOutMin The mininum amount of ETH a trader want to swap out of pool
    /// @param  to The target address receiving the ETH
    /// @param  rewardTo The target address receiving the CoFi Token as rewards
    /// @param  deadline The dealine of this request
    /// @return amounts The number of assets exchanged each time in the conversion path
    function swapExactTokensForTokens(
        address[] calldata path,
        uint amountIn,
        uint amountOutMin,
        address to,
        address rewardTo,
        uint deadline
    ) external payable override ensure(deadline) returns (uint[] memory amounts) {
        // Record the total mined
        uint totalMined = 0;
        // 1. Trade
        (amounts, totalMined) = _swap(path, amountIn, to);
        // 2. amountOut must not less than expected
        require(amounts[path.length - 1] >= amountOutMin, "CoFiXRouter: got less than expected");

        // 3. Any remaining ETH in the Router is considered to be the user's and is forwarded to 
        // the address specified by the Router
        uint balance = address(this).balance;
        if (balance > 0) {
            payable(to).transfer(balance);
        } 

        // 4. Mining cofi for trade
        _mint(totalMined, rewardTo);
    }

    // Trade
    function _swap(
        address[] calldata path,
        uint amountIn,
        address to
    ) private returns (
        uint[] memory amounts, 
        uint totalMined
    ) {
        // Initialize
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        totalMined = 0;
        
        // Get the first pair
        address token0 = path[0];
        address token1 = path[1];
        address pool = _pairFor(token0, token1);
        // Transfer token to first pool
        if (token0 != address(0)) {
            TransferHelper.safeTransferFrom(token0, to, pool, amountIn);
        }

        uint mined;
        // Execute the exchange transaction according to the routing path
        for (uint i = 1; ; ) {
            // Address to receive funds for this transaction
            address recv = to;

            // Next token address. 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF means empty
            address next = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;
            if (++i < path.length) {
                next = path[i];
                // While the next token address still exists, the fund receiving address is the next transaction pair
                recv = _pairFor(token1, next);
            }

            // Perform an exchange transaction. If token1 is ETH, the fund receiving address is address(this).
            // Q: The solution of openzeppelin-upgrades may cause transfer eth fail, 
            //    It needs to be validated and resolved
            // A: Since the execution entry is at CofixRouter, the proxy address of the CofixRouter has 
            //    already been read, which reduces the gas consumption for subsequent reads, So the gas 
            //    consumption of the later receive() transfer to CofixRouter is reduced without an error, 
            //    so OpenZeppelin is now available, The upgradable solution of does not cause the problem 
            //    of converting ETH from the capital pool to CoFixRouter to fail.
            (amountIn, mined) = ICoFiXPool(pool).swap {
                value: address(this).balance
            } (token0, token1, amountIn, token1 == address(0) ? address(this) : recv, address(this));

            // Increase total mining
            totalMined += mined;
            // Record the amount of money exchanged this time
            amounts[i - 1] = amountIn;

            // next equal to 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF means trade is over
            if (next == 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF) {
                break;
            }

            // Switch to the next trade pair in the routing path
            token0 = token1;
            token1 = next;
            pool = recv;
        }
    }

    // Mint CoFi to target address, and increase for CNode
    function _mint(uint mined, address rewardTo) private {
        if (mined > 0) {
            uint cnodeReward = mined / 10;
            // The amount available to the trader
            CoFiToken(COFI_TOKEN_ADDRESS).mint(rewardTo, mined - cnodeReward);
            // Increase for CNode
            _cnodeReward += cnodeReward;
        }
    }

    /// @dev Acquire the transaction mining share of the target XToken
    /// @param xtoken The destination XToken address
    /// @return Target XToken's transaction mining share
    function getTradeReward(address xtoken) external view override returns (uint) {
        // Only CNode has a share of trading out, not market making        
        if (xtoken == CNODE_TOKEN_ADDRESS) {
            return _cnodeReward;
        }
        return 0;
    }

    receive() external payable {
    }
}
