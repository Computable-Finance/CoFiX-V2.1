// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "./INestPriceFacade.sol";

/// @dev This interface defines the methods for price call entry
interface ICoFiXController is INestPriceFacade{

    struct Config {
        uint32 alpha;
        uint32 beta;
        uint32 gamaR1;
        uint32 gamaR2;
    }
    
    // Calc variance of price and K in CoFiX is very expensive
    // We use expected value of K based on statistical calculations here to save gas
    // In the near future, NEST could provide the variance of price directly. We will adopt it then.
    // We can make use of `data` bytes in the future
    function queryPrice(
        address tokenAddress,
        address payback
    ) external payable returns (
        uint ethAmount, 
        uint tokenAmount, 
        uint blockNum
    );

    // Calc variance of price and K in CoFiX is very expensive
    // We use expected value of K based on statistical calculations here to save gas
    // In the near future, NEST could provide the variance of price directly. We will adopt it then.
    // We can make use of `data` bytes in the future
    function queryOracle(
        address tokenAddress,
        address payback
    ) external payable returns (
        uint k, 
        uint ethAmount, 
        uint tokenAmount, 
        uint blockNum//, 
        //uint theta
    );

    /**
     * @notice Calc K value
     * @param sigmaSQ The square of the volatility (18 decimal places).
     * @param bn The block number when (ETH, TOKEN) price takes into effective
     * @return k The K value
     */
    function calcK(uint sigmaSQ, uint bn) external view returns (uint k);
}