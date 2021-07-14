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
    address immutable NEST_PRICE_FADADE;

    constructor(address nestPriceFacade) {
        NEST_PRICE_FADADE = nestPriceFacade;
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
        ) = INestPriceFacade(NEST_PRICE_FADADE).latestPriceAndTriggeredPriceInfo { 
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
        (blockNumber, tokenAmount) = INestPriceFacade(NEST_PRICE_FADADE).latestPrice { 
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
        uint sigmaSQ;
        (
            blockNumber, 
            ethAmount,
            tokenAmount,
            ,//uint avgPriceEthAmount,
            ,//uint avgPriceTokenAmount,
            sigmaSQ
        ) = latestPriceInfo(tokenAddress, payback);

        k = calcK(sigmaSQ, blockNumber);
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

        k = (K_ALPHA * (block.number - bn) * 14 ether + K_BETA * sigma) * gamma / 1e36;
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