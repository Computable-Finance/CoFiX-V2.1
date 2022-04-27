// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./libs/TransferHelper.sol";

import "./interfaces/ICoFiXOpenPool.sol";
import "./interfaces/INestBatchPrice2.sol";

import "./custom/ChainParameter.sol";
import "./custom/CoFiXFrequentlyUsed.sol";

import "./CoFiXBase.sol";
import "./CoFiXERC20.sol";

/// @dev CoFiXOpenPool, use NEST4.3 price
contract CoFiXOpenPool is ChainParameter, CoFiXFrequentlyUsed, CoFiXERC20, ICoFiXOpenPool {

    /* ******************************************************************************************
     * Note: In order to unify the authorization entry, all transferFrom operations are carried
     * out in the CoFiXRouter, and the CoFiXPool needs to be fixed, CoFiXRouter does trust and 
     * needs to be taken into account when calculating the pool balance before and after rollover
     * ******************************************************************************************/

    // it's negligible because we calc liquidity in ETH
    uint constant MINIMUM_LIQUIDITY = 1e9; 

    // Target token address
    address _token0; 
    // Unit of post token, make sure decimals convert
    uint96 _postUnit;

    address _token1;
    // Target price channelId
    uint32 _channelId;
    // Target price pairIndex
    uint32 _pairIndex;
    // Trade fee rate, ten thousand points system. 20
    uint16 _theta;
    // Trade fee rate for dao, ten thousand points system. 20
    uint16 _theta0;

    // ERC20 - name
    string public name;
    
    // ERC20 - symbol
    string public symbol;

    // Address of CoFiXDAO
    address _cofixDAO;
    // Standard sigmaSQ
    uint96 _sigmaSQ;

    // Address of CoFiXRouter
    address _cofixRouter;
    // Lock flag
    bool _locked;
    // The significance of the _impactCostVOL parameter is adjusted to represent the times of impact cost
    // impact cost formula: vol * uint(_impactCostVOL) * 0.000000001
    // for nest, _impactCostVOL is 2000
    uint32 _impactCostVOL;

    // Constructor, in order to support openzeppelin's scalable scheme, 
    // it's need to move the constructor to the initialize method
    constructor() {
    }

    /// @dev init Initialize
    /// @param governance ICoFiXGovernance implementation contract address
    /// @param name_ Name of xtoken
    /// @param symbol_ Symbol of xtoken
    /// @param token0 Address of token0(not support eth)
    /// @param token1 Address of token1(not support eth)
    function init(
        address governance,
        string calldata name_, 
        string calldata symbol_, 
        address token0,
        address token1
    ) external {
        super.initialize(governance);
        name = name_;
        symbol = symbol_;
        _token0 = token0;
        _token1 = token1;
    }

    modifier check() {
        require(_cofixRouter == msg.sender, "COP:Only for CoFiXRouter");
        require(!_locked, "COP:LOCKED");
        _locked = true;
        _;
        _locked = false;
    }

    /// @dev Set configuration
    /// @param channelId Target price channelId
    /// @param pairIndex Target price pairIndex
    /// @param postUnit Unit of post token, make sure decimals convert
    /// @param theta Trade fee rate, ten thousand points system. 20
    /// @param theta0 Trade fee rate for dao, ten thousand points system. 20
    /// @param impactCostVOL The significance of this parameter is adjusted to represent the times of impact cost
    /// impact cost formula: vol * uint(_impactCostVOL) * 0.000000001
    /// for nest, _impactCostVOL is 2000
    /// @param sigmaSQ Standard sigmaSQ
    function setConfig(
        uint32 channelId,
        uint32 pairIndex,
        uint96 postUnit,
        uint16 theta, 
        uint16 theta0, 
        uint32 impactCostVOL, 
        uint96 sigmaSQ
    ) external override onlyGovernance {
        _channelId = channelId;
        _pairIndex = pairIndex;
        _postUnit = postUnit;

        // Trade fee rate, ten thousand points system. 20
        _theta = theta;
        // Trade fee rate for dao, ten thousand points system. 20
        _theta0 = theta0;
        // The significance of the _impactCostVOL parameter is adjusted to represent the times of impact cost
        // impact cost formula: vol * uint(_impactCostVOL) * 0.000000001
        // for nest, _impactCostVOL is 2000
        _impactCostVOL = impactCostVOL;

        _sigmaSQ = sigmaSQ;
    }

    /// @dev Get configuration
    /// @return channelId Target price channelId
    /// @return pairIndex Target price pairIndex
    /// @return postUnit Unit of post token, make sure decimals convert
    /// @return theta Trade fee rate, ten thousand points system. 20
    /// @return theta0 Trade fee rate for dao, ten thousand points system. 20
    /// @return impactCostVOL The significance of this parameter is adjusted to represent the times of impact cost
    /// impact cost formula: vol * uint(_impactCostVOL) * 0.000000001
    /// for nest, _impactCostVOL is 2000
    /// @return sigmaSQ Standard sigmaSQ
    function getConfig() external view override returns (
        uint32 channelId,
        uint32 pairIndex,
        uint96 postUnit,
        uint16 theta, 
        uint16 theta0, 
        uint32 impactCostVOL, 
        uint96 sigmaSQ
    ) {
        return (_channelId, _pairIndex, _postUnit, _theta, _theta0, _impactCostVOL, _sigmaSQ);
    }

    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(newGovernance) when overriding, and override method without onlyGovernance
    /// @param newGovernance ICoFiXGovernance implementation contract address
    function update(address newGovernance) public override {
        super.update(newGovernance);
        (
            ,//cofiToken,
            ,//cofiNode,
            _cofixDAO,
            _cofixRouter,
            ,//_cofixController,
            //cofixVaultForStaking
        ) = ICoFiXGovernance(newGovernance).getBuiltinAddress();
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
    ) external payable override check returns (
        address xtoken,
        uint liquidity
    ) {
        // 1. Check token address
        //require(token == _tokenAddress, "CoFiXPair: invalid token address");
        require(amountETH == 0, "COP:amountETH must be 0");
        
        // 3. Query oracle
        (
            uint k, 
            uint ethAmount, 
            uint tokenAmount, 
            //uint blockNumber, 
        ) = _queryOracle(
            uint(_channelId),
            uint(_pairIndex),
            msg.value,
            payback
        );

        address token0 = _token0;
        address token1 = _token1;
        uint balance0 = ERC20(token0).balanceOf(address(this));
        uint balance1 = ERC20(token1).balanceOf(address(this));

        // token0, liquidity is amount of token0
        if (token == token0) {
            liquidity = amountToken;
            balance0 -= amountToken;
        }
        // token1, need use price
        else if(token == token1) {
            liquidity = amountToken * ethAmount / tokenAmount;
            balance1 -= amountToken;
        } 
        else {
            revert("COP:token not support");
        }
        
        // 2. Calculate net worth and share
        uint total = totalSupply;
        if (total > 0) {
            liquidity = liquidity * total / _calcTotalValue(
                // To calculate the net value, we need to use the asset balance before the market making fund 
                // is transferred. Since the ETH was transferred when CoFiXRouter called this method and the 
                // Token was transferred before CoFiXRouter called this method, we need to deduct the amountETH 
                // and amountToken respectively

                // The current eth balance minus the amount eth equals the ETH balance before the transaction
                balance0, 
                //The current token balance minus the amountToken equals to the token balance before the transaction
                balance1,
                // Oracle price - eth amount
                ethAmount, 
                // Oracle price - token amount
                tokenAmount
            );
        } else {
            _mint(address(0), MINIMUM_LIQUIDITY); 
            liquidity = liquidity * 1 ether / 10 ** uint(ERC20(token0).decimals()) - MINIMUM_LIQUIDITY;
        }

        // 5. Increase xtoken
        _mint(to, liquidity);
        //emit Mint(token, to, amountETH, amountToken, liquidity);

        xtoken = address(this);
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
    ) external payable override check returns (
        uint amountETHOut,
        uint amountTokenOut 
    ) { 
        if(msg.value > 0) {
            payable(payback).transfer(msg.value);
        }

        // 1. Check token address
        require(token == address(0), "COP:token must be 0");
        
        // 3. Calculate the net value and calculate the equal proportion fund according to the net value
        address token0 = _token0;
        address token1 = _token1;
        uint balance0 = ERC20(token0).balanceOf(address(this));
        uint balance1 = ERC20(token1).balanceOf(address(this));
        uint total = totalSupply;

        amountETHOut = balance0 * liquidity / total;
        amountTokenOut = balance1 * liquidity / total;

        // 5. Destroy xtoken
        _burn(address(this), liquidity);
        //emit Burn(token, to, liquidity, amountETHOut, amountTokenOut);

        // 7. Transfer of funds to the user's designated address
        //payable(to).transfer(amountETHOut);
        TransferHelper.safeTransfer(token0, to, amountETHOut);
        TransferHelper.safeTransfer(token1, to, amountTokenOut);
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
    ) external payable override check returns (
        uint amountOut, 
        uint mined
    ) {
        address token0 = _token0;
        address token1 = _token1;
        uint theta = uint(_theta);

        // 1. Query oracle
        (
            uint k, 
            uint ethAmount, 
            uint tokenAmount, 
            //uint blockNumber, 
        ) = _queryOracle(
            uint(_channelId),
            uint(_pairIndex),
            msg.value,
            payback
        );

        if (src == token0 && dest == token1) {
            //(amountOut, mined) =  _swapForToken(token1, amountIn, to, payback);

            // 2. Calculate the trade result
            uint fee = amountIn * theta / 10000;
            amountOut = (amountIn - fee) * tokenAmount * 1 ether / ethAmount / (
                1 ether + k + impactCostForSellOutETH(amountIn)
            );

            // 3. Transfer transaction fee
            // fee = _collect(fee * uint(_theta0) / theta);
            TransferHelper.safeTransfer(token0, _cofixDAO, fee * uint(_theta0) / theta);

            // 5. Transfer token
            TransferHelper.safeTransfer(token1, to, amountOut);

            emit SwapForToken1(amountIn, to, amountOut, mined);
        } else if (src == token1 && dest == token0) {
            //(amountOut, mined) = _swapForETH(token1, amountIn, to, payback);
           
            // 2. Calculate the trade result
            amountOut = amountIn * ethAmount / tokenAmount;
            amountOut = amountOut * 1 ether / (
                1 ether + k + impactCostForBuyInETH(amountOut)
            ); 

            uint fee = amountOut * theta / 10000;
            amountOut = amountOut - fee;

            // 3. Transfer transaction fee
            // fee = _collect(fee * uint(_theta0) / theta);
            TransferHelper.safeTransfer(token0, _cofixDAO, fee * uint(_theta0) / theta);

            // 5. Transfer token
            //payable(to).transfer(amountETHOut);
            TransferHelper.safeTransfer(token0, to, amountOut);

            emit SwapForToken0(amountIn, to, amountOut, mined);
        } else {
            revert("COP:pair error");
        }
    }

    /// @dev Get net worth
    /// @param ethAmount Oracle price - eth amount
    /// @param tokenAmount Oracle price - token amount
    /// @return navps Net worth
    function getNAVPerShare(
        uint ethAmount, 
        uint tokenAmount
    ) external view override returns (uint navps) {
        // Np = (Au * (1 + K) / P + Ae) / S
        uint total = totalSupply;
        navps = total > 0 ? _calcTotalValue(
            ERC20(_token0).balanceOf(address(this)), 
            ERC20(_token1).balanceOf(address(this)), 
            ethAmount, 
            tokenAmount
        ) * 1 ether / total : 1 ether;
    }

    // Calculate the total value of asset balance
    function _calcTotalValue(
        uint balance0, 
        uint balance1, 
        uint ethAmount, 
        uint tokenAmount
    ) private pure returns (uint totalValue) {
        totalValue = balance0 + balance1 * ethAmount / tokenAmount;
    }

    /// @dev Calculate the impact cost of buy in eth
    /// @param vol Trade amount in eth
    /// @return impactCost Impact cost
    function impactCostForBuyInETH(uint vol) public view override returns (uint impactCost) {
        //return _impactCostForBuyInETH(vol, uint(_impactCostVOL));
        //impactCost = vol * uint(_impactCostVOL) / 100000;
        // nest: 0.000002/U
        impactCost = vol * uint(_impactCostVOL) / 1e9;
    }

    /// @dev Calculate the impact cost of sell out eth
    /// @param vol Trade amount in eth
    /// @return impactCost Impact cost
    function impactCostForSellOutETH(uint vol) public view override returns (uint impactCost) {
        //return _impactCostForSellOutETH(vol, uint(_impactCostVOL));
        //impactCost = vol * uint(_impactCostVOL) / 100000;
        // nest: 0.000002/U
        impactCost = vol * uint(_impactCostVOL) / 1e9;
    }

    /// @dev Gets the token address of the share obtained by the specified token market making
    /// @return If the fund pool supports the specified token, return the token address of the market share
    function getXToken(address) external view override returns (address) {
        //if (token == _token0 || token == _token1) {
        //    return address(this);
        //}
        //return address(0);
        return address(this);
    }

    /// @dev Calc variance of price and K in CoFiX is very expensive
    /// We use expected value of K based on statistical calculations here to save gas
    /// In the near future, NEST could provide the variance of price directly. We will adopt it then.
    /// We can make use of `data` bytes in the future
    /// @param channelId Target price channelId
    /// @param pairIndex Target price pairIndex
    /// @param payback As the charging fee may change, it is suggested that the caller pay more fees, 
    /// and the excess fees will be returned through this address
    /// @return k The K value(18 decimal places).
    /// @return ethAmount Oracle price - eth amount
    /// @return tokenAmount Oracle price - token amount
    /// @return blockNumber Block number of price
    function _queryOracle(
        uint channelId,
        uint pairIndex,
        uint fee,
        address payback
    ) private returns (
        uint k, 
        uint ethAmount, 
        uint tokenAmount, 
        uint blockNumber
    ) {
        uint[] memory pairIndices = new uint[](1);
        pairIndices[0] = pairIndex;
        // (
        //     uint[] memory prices,
        //     ,//uint triggeredPriceBlockNumber,
        //     ,//uint triggeredPriceValue,
        //     uint triggeredAvgPrice,
        //     //uint triggeredSigmaSQ
        // ) 
        uint[] memory prices = INestBatchPrice2(NEST_BATCH_PRICE).lastPriceList {
            value: fee  
        } (channelId, pairIndices, 2, payback);

        //prices[1] = (prices[1]);
        //prices[3] = (prices[3]);
        //triggeredAvgPrice = (triggeredAvgPrice);
        tokenAmount = prices[1];
        blockNumber = prices[0];
        ethAmount = uint(_postUnit);

        k = calcRevisedK(prices[3], prices[2], tokenAmount, blockNumber);
    }

     /// @dev K value is calculated by revised volatility
    /// @param p0 Last price (number of tokens equivalent to 1 ETH)
    /// @param bn0 Block number of the last price
    /// @param p Latest price (number of tokens equivalent to 1 ETH)
    /// @param bn The block number when (ETH, TOKEN) price takes into effective
    function calcRevisedK(uint p0, uint bn0, uint p, uint bn) public view returns (uint k) {
        uint sigmaSQ = uint(_sigmaSQ);
        uint sigmaISQ = p * 1 ether / p0;
        if (sigmaISQ > 1 ether) {
            sigmaISQ -= 1 ether;
        } else {
            sigmaISQ = 1 ether - sigmaISQ;
        }

        // The left part change to: Max((p2 - p1) / p1, 0.002)
        if (sigmaISQ > 0.002 ether) {
            k = sigmaISQ;
        } else {
            k = 0.002 ether;
        }

        sigmaISQ = sigmaISQ * sigmaISQ / (bn - bn0) / BLOCK_TIME / 1 ether;

        if (sigmaISQ > sigmaSQ) {
            k += _sqrt(1 ether * BLOCK_TIME * (block.number - bn) * sigmaISQ);
        } else {
            k += _sqrt(1 ether * BLOCK_TIME * sigmaSQ * (block.number - bn));
        }
    }

    function _sqrt(uint256 x) private pure returns (uint256) {
        unchecked {
            if (x == 0) return 0;
            else {
                uint256 xx = x;
                uint256 r = 1;
                if (xx >= 0x100000000000000000000000000000000) { xx >>= 128; r <<= 64; }
                if (xx >= 0x10000000000000000) { xx >>= 64; r <<= 32; }
                if (xx >= 0x100000000) { xx >>= 32; r <<= 16; }
                if (xx >= 0x10000) { xx >>= 16; r <<= 8; }
                if (xx >= 0x100) { xx >>= 8; r <<= 4; }
                if (xx >= 0x10) { xx >>= 4; r <<= 2; }
                if (xx >= 0x8) { r <<= 1; }
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1; // Seven iterations should be enough
                uint256 r1 = x / r;
                return (r < r1 ? r : r1);
            }
        }
    }
}
