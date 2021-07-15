// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./interfaces/ICoFiXController.sol";

import "hardhat/console.sol";

/// @dev This interface defines the methods for price call entry
contract CoFiXController is ICoFiXController {

    uint constant K_ALPHA = 0.00001 ether;
    uint constant K_BETA = 10 ether;
    uint constant BLOCK_TIME = 14;

    // Address of NestPriceFacade contract
    address immutable NEST_PRICE_FACADE;

    constructor(address nestPriceFacade) {
        NEST_PRICE_FACADE = nestPriceFacade;
    }

    /// @dev Query latest price info
    /// @param tokenAddress Target address of token
    /// @param payback As the charging fee may change, it is suggested that the caller pay more fees, 
    /// and the excess fees will be returned through this address
    /// @return blockNumber Block number of price
    /// @return priceEthAmount Oracle price - eth amount
    /// @return priceTokenAmount Oracle price - token amount
    /// @return avgPriceEthAmount Avg price - eth amount
    /// @return avgPriceTokenAmount Avg price - token amount
    /// @return sigmaSQ The square of the volatility (18 decimal places)
    function latestPriceInfo(address tokenAddress, address payback) 
    public 
    payable 
    override
    returns (
        uint blockNumber, 
        uint priceEthAmount,
        uint priceTokenAmount,
        uint avgPriceEthAmount,
        uint avgPriceTokenAmount,
        uint sigmaSQ
    ) {
        (
            blockNumber, 
            priceTokenAmount,
            ,//uint triggeredPriceBlockNumber,
            ,//uint triggeredPriceValue,
            avgPriceTokenAmount,
            sigmaSQ
        ) = INestPriceFacade(NEST_PRICE_FACADE).latestPriceAndTriggeredPriceInfo { 
            value: msg.value 
        } (tokenAddress, payback);
        priceEthAmount = 1 ether;
        avgPriceEthAmount = 1 ether;
    }

    // Calc variance of price and K in CoFiX is very expensive
    // We use expected value of K based on statistical calculations here to save gas
    // In the near future, NEST could provide the variance of price directly. We will adopt it then.
    // We can make use of `data` bytes in the future

    /// @dev Query price
    /// @param tokenAddress Target address of token
    /// @param payback As the charging fee may change, it is suggested that the caller pay more fees, 
    /// and the excess fees will be returned through this address
    /// @return ethAmount Oracle price - eth amount
    /// @return tokenAmount Oracle price - token amount
    /// @return blockNumber Block number of price
    function queryPrice(
        address tokenAddress,
        address payback
    ) external payable override returns (
        uint ethAmount, 
        uint tokenAmount, 
        uint blockNumber
    ) {
        (blockNumber, tokenAmount) = INestPriceFacade(NEST_PRICE_FACADE).latestPrice { 
            value: msg.value 
        } (tokenAddress, payback);
        ethAmount = 1 ether;
    }

    /// @dev Calc variance of price and K in CoFiX is very expensive
    /// We use expected value of K based on statistical calculations here to save gas
    /// In the near future, NEST could provide the variance of price directly. We will adopt it then.
    /// We can make use of `data` bytes in the future
    /// @param tokenAddress Target address of token
    /// @param payback As the charging fee may change, it is suggested that the caller pay more fees, 
    /// and the excess fees will be returned through this address
    /// @return k The K value(18 decimal places).
    /// @return ethAmount Oracle price - eth amount
    /// @return tokenAmount Oracle price - token amount
    /// @return blockNumber Block number of price
    function queryOracle(
        address tokenAddress,
        address payback
    ) external override payable returns (
        uint k, 
        uint ethAmount, 
        uint tokenAmount, 
        uint blockNumber
    ) {
        (
            uint[] memory prices,
            ,//uint triggeredPriceBlockNumber,
            ,//uint triggeredPriceValue,
            ,//uint triggeredAvgPrice,
            uint triggeredSigmaSQ
        ) = INestPriceFacade(NEST_PRICE_FACADE).lastPriceListAndTriggeredPriceInfo {
            value: msg.value  
        } (tokenAddress, 2, payback);

        ethAmount = 1 ether;
        tokenAmount = prices[1];
        blockNumber = prices[0];

        k = calcRevisedK(triggeredSigmaSQ, prices[3], prices[2], tokenAmount, blockNumber);
    }

    /// @dev K value is calculated by revised volatility
    /// @param sigmaSQ The square of the volatility (18 decimal places).
    /// @param p0 Last price (number of tokens equivalent to 1 ETH)
    /// @param bn0 Block number of the last price
    /// @param p Latest price (number of tokens equivalent to 1 ETH)
    /// @param bn The block number when (ETH, TOKEN) price takes into effective
    function calcRevisedK(uint sigmaSQ, uint p0, uint bn0, uint p, uint bn) public view override returns (uint k) {
        k = calcK(_calcRevisedSigmaSQ(sigmaSQ, p0, bn0, p, bn), bn);
    }

    // TODO: 为了测试方便写成public的，发布时需要改为private的
    // Calculate the corrected volatility
    function _calcRevisedSigmaSQ(uint sigmaSQ, uint p0, uint bn0, uint p, uint bn) public view returns (uint revisedSigmaSQ) {
        // console.log('_calcRevisedSigmaSQ-sigmaSQ', sigmaSQ);
        // console.log('_calcRevisedSigmaSQ-p0', p0);
        // console.log('_calcRevisedSigmaSQ-bn0', bn0);
        // console.log('_calcRevisedSigmaSQ-p', p);
        // console.log('_calcRevisedSigmaSQ-bn', bn);

        // sq2 = sq1 * 0.9 + rq2 * dt * 0.1
        // sq1 = (sq2 - rq2 * dt * 0.1) / 0.9
        // 1. 
        // rq2 <= 4 * dt * sq1
        // sqt = sq2
        // 2. rq2 > 4 * dt * sq1 && rq2 <= 9 * dt * sq1
        // sqt = (sq1 + rq2 * dt) / 2
        // 3. rq2 > 9 * dt * sq1
        // sqt = sq1 * 0.2 + rq2 * dt * 0.8

        uint rq = p * 1 ether / p0;
        if (rq > 1 ether) {
            rq -= 1 ether;
        } else {
            rq = 1 ether - rq;
        }
        //console.log('_calcRevisedSigmaSQ-rq', rq);

        uint rq2 = rq * rq / 1 ether;
        //console.log('_calcRevisedSigmaSQ-rq2', rq2);
        uint dt = (bn - bn0) * BLOCK_TIME;
        //console.log('_calcRevisedSigmaSQ-dt', dt);
        uint sq2 = sigmaSQ;
        //console.log('_calcRevisedSigmaSQ-sq2', sq2);
        uint sq1 = 0;
        if (sq2 * 10 > rq2 / dt) {
            sq1 = (sq2 * 10 - rq2 / dt) / 9;
        }
        //console.log('_calcRevisedSigmaSQ-sq1', sq1);

        uint sqt = sq2;
        uint dds = dt * dt * dt * sq1;
        //console.log('_calcRevisedSigmaSQ-dds', dds);
        if (rq2 <= 4 * dds) {
            console.log('case0');
            //sqt = sq2;
        } else if (rq2 <= 9 * dds) {
            console.log('case1');
            sqt = (sq1 + rq2 / dt) / 2;
        } else {
            console.log('case2');
            sqt = (sq1 + rq2 * 4 / dt) / 5;
        }
        revisedSigmaSQ = sqt;
        //console.log('_calcRevisedSigmaSQ-revisedSigmaSQ', revisedSigmaSQ);
    }

    // TODO: Note that the value of K is 18 decimal places
    /// @dev Calc K value
    /// @param sigmaSQ The square of the volatility (18 decimal places).
    /// @param bn The block number when (ETH, TOKEN) price takes into effective
    /// @return k The K value
    function calcK(uint sigmaSQ, uint bn) public view override returns (uint k) {
        uint sigma = _sqrt(sigmaSQ / 1e4) * 1e11;
        uint gamma = 1 ether;
        if (sigma > 0.0005 ether) {
            gamma = 2 ether;
        } else if (sigma > 0.0003 ether) {
            gamma = 1.5 ether;
        }

        k = (K_ALPHA * (block.number - bn) * BLOCK_TIME * 1 ether + K_BETA * sigma) * gamma / 1e36;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function _sqrt(uint y) private pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = (y >> 1) + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) >> 1;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}