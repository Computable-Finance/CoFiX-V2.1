// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "../interfaces/INestPriceFacade.sol";

/// @dev Router contract to interact with each CoFiXPair, no owner or governance
contract NestPriceFacadeMock is INestPriceFacade {

    /// @dev Returns the results of latestPrice() and triggeredPriceInfo()
    /// @param tokenAddress Destination token address
    /// @param paybackAddress As the charging fee may change, it is suggested that the caller pay more fees, and the excess fees will be returned through this address
    /// @return latestPriceBlockNumber The block number of latest price
    /// @return latestPriceValue The token latest price. (1eth equivalent to (price) token)
    /// @return triggeredPriceBlockNumber The block number of triggered price
    /// @return triggeredPriceValue The token triggered price. (1eth equivalent to (price) token)
    /// @return triggeredAvgPrice Average price
    /// @return triggeredSigmaSQ The square of the volatility (18 decimal places). The current implementation assumes that 
    ///         the volatility cannot exceed 1. Correspondingly, when the return value is equal to 999999999999996447,
    ///         it means that the volatility has exceeded the range that can be expressed
    function latestPriceAndTriggeredPriceInfo(address tokenAddress, address paybackAddress) 
    external 
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
        return (block.number - 1, 2700 * 1000000, block.number - 1, 2700 * 1000000, 2600 * 1000000, 314000000000000);
    }
}