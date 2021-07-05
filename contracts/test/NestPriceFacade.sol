// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "../interfaces/INestPriceFacade.sol";

import "hardhat/console.sol";

/// @dev This interface defines the methods for price call entry
contract NestPriceFacade is INestPriceFacade {

    struct Price {
        uint price;
        uint dbn;
    }

    mapping(address=>Price) _prices;

    function setPrice(address token, uint price, uint dbn) external {
        _prices[token] = Price(price, dbn);
    }

    /// @dev Get the latest effective price
    /// @param tokenAddress Destination token address
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    function latestPriceView(address tokenAddress) public view returns (uint blockNumber, uint price) {
        // TODO:
        //require(tokenAddress != address(0));
        //return (block.number - 1, 2700 * 1000000);

        Price memory p = _prices[tokenAddress];
        if (p.price == 0) {
            p = Price(2700 * 1000000, 1);
        }

        return (block.number - p.dbn, p.price);
    }

    /// @dev Get the latest effective price
    /// @param tokenAddress Destination token address
    /// @param payback As the charging fee may change, it is suggested that the caller pay more fees, and the excess fees will be returned through this address
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    function latestPrice(address tokenAddress, address payback) public payable override returns (uint blockNumber, uint price) {
        if (msg.value > 0.01 ether) {
            payable(payback).transfer(msg.value - 0.01 ether);
        } else {
            require(msg.value == 0.01 ether, "CoFiXController: Error fee");
        }
        
        return latestPriceView(tokenAddress);
    }

    /// @dev Returns the results of latestPrice() and triggeredPriceInfo()
    /// @param tokenAddress Destination token address
    /// @param payback As the charging fee may change, it is suggested that the caller pay more fees, and the excess fees will be returned through this address
    /// @return latestPriceBlockNumber The block number of latest price
    /// @return latestPriceValue The token latest price. (1eth equivalent to (price) token)
    /// @return triggeredPriceBlockNumber The block number of triggered price
    /// @return triggeredPriceValue The token triggered price. (1eth equivalent to (price) token)
    /// @return triggeredAvgPrice Average price
    /// @return triggeredSigmaSQ The square of the volatility (18 decimal places). The current implementation assumes that 
    ///         the volatility cannot exceed 1. Correspondingly, when the return value is equal to 999999999999996447,
    ///         it means that the volatility has exceeded the range that can be expressed
    function latestPriceAndTriggeredPriceInfo(address tokenAddress, address payback) 
    public 
    payable 
    override
    returns (
        uint latestPriceBlockNumber, 
        uint latestPriceValue,
        uint triggeredPriceBlockNumber,
        uint triggeredPriceValue,
        uint triggeredAvgPrice,
        uint triggeredSigmaSQ
    ) {
        if (msg.value > 0.01 ether) {
            payable(payback).transfer(msg.value - 0.01 ether);
        } else {
            require(msg.value == 0.01 ether, "CoFiXController: Error fee");
        }

        (uint bn, uint price) = latestPriceView(tokenAddress);
        return (block.number - bn, price, block.number - bn, price, price * 95 / 100, 10853469234);
    }
}