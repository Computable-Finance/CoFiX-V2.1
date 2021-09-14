// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./interfaces/ICoFiXController.sol";

/// @dev This interface defines the methods for price call entry
contract CoFiXController is ICoFiXController {

    uint constant BLOCK_TIME = 14;

    // Address of NestPriceFacade contract
    //address constant NEST_PRICE_FACADE = 0xB5D2890c061c321A5B6A4a4254bb1522425BAF0A;
    address NEST_PRICE_FACADE;

    /// @dev To support open-zeppelin/upgrades
    function initialize(address nestPriceFacade) external {
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
    external 
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
        
        _checkPrice(priceTokenAmount, avgPriceTokenAmount);
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

        // (
        //     uint latestPriceBlockNumber, 
        //     uint latestPriceValue,
        //     ,//uint triggeredPriceBlockNumber,
        //     ,//uint triggeredPriceValue,
        //     uint triggeredAvgPrice,
        //     //uint triggeredSigmaSQ
        // ) = INestPriceFacade(NEST_PRICE_FACADE).latestPriceAndTriggeredPriceInfo { 
        //     value: msg.value 
        // } (tokenAddress, payback);
        
        // _checkPrice(latestPriceValue, triggeredAvgPrice);

        // ethAmount = 1 ether;
        // tokenAmount = latestPriceValue;
        // blockNumber = latestPriceBlockNumber;
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
    ) external payable override returns (
        uint k, 
        uint ethAmount, 
        uint tokenAmount, 
        uint blockNumber
    ) {
        (
            uint[] memory prices,
            ,//uint triggeredPriceBlockNumber,
            ,//uint triggeredPriceValue,
            uint triggeredAvgPrice,
            uint triggeredSigmaSQ
        ) = INestPriceFacade(NEST_PRICE_FACADE).lastPriceListAndTriggeredPriceInfo {
            value: msg.value  
        } (tokenAddress, 2, payback);

        tokenAmount = prices[1];
        _checkPrice(tokenAmount, triggeredAvgPrice);
        blockNumber = prices[0];
        ethAmount = 1 ether;

        k = calcRevisedK(triggeredSigmaSQ, prices[3], prices[2], tokenAmount, blockNumber);
    }

    /// @dev K value is calculated by revised volatility
    /// @param sigmaSQ The square of the volatility (18 decimal places).
    /// @param p0 Last price (number of tokens equivalent to 1 ETH)
    /// @param bn0 Block number of the last price
    /// @param p Latest price (number of tokens equivalent to 1 ETH)
    /// @param bn The block number when (ETH, TOKEN) price takes into effective
    function calcRevisedK(uint sigmaSQ, uint p0, uint bn0, uint p, uint bn) public view override returns (uint k) {
        k = _calcK(_calcRevisedSigmaSQ(sigmaSQ, p0, bn0, p, bn), bn);
    }

    // Calculate the corrected volatility
    function _calcRevisedSigmaSQ(
        uint sigmaSQ,
        uint p0, 
        uint bn0, 
        uint p, 
        uint bn
    ) private pure returns (uint revisedSigmaSQ) {
        // sq2 = sq1 * 0.9 + rq2 * dt * 0.1
        // sq1 = (sq2 - rq2 * dt * 0.1) / 0.9
        // 1. 
        // rq2 <= 4 * dt * sq1
        // sqt = sq2
        // 2. rq2 > 4 * dt * sq1 && rq2 <= 9 * dt * sq1
        // sqt = (sq1 + rq2 * dt) / 2
        // 3. rq2 > 9 * dt * sq1
        // sqt = sq1 * 0.2 + rq2 * dt * 0.8

        uint rq2 = p * 1 ether / p0;
        if (rq2 > 1 ether) {
            rq2 -= 1 ether;
        } else {
            rq2 = 1 ether - rq2;
        }
        rq2 = rq2 * rq2 / 1 ether;

        uint dt = (bn - bn0) * BLOCK_TIME;
        uint sq1 = 0;
        uint rq2dt = rq2 / dt;
        if (sigmaSQ * 10 > rq2dt) {
            sq1 = (sigmaSQ * 10 - rq2dt) / 9;
        }

        uint dds = dt * dt * dt * sq1;
        if (rq2 <= (dds << 2)) {
            revisedSigmaSQ = sigmaSQ;
        } else if (rq2 <= 9 * dds) {
            revisedSigmaSQ = (sq1 + rq2dt) >> 1;
        } else {
            revisedSigmaSQ = (sq1 + (rq2dt << 2)) / 5;
        }
    }

    /// @dev Calc K value
    /// @param sigmaSQ The square of the volatility (18 decimal places).
    /// @param bn The block number when (ETH, TOKEN) price takes into effective
    /// @return k The K value
    function _calcK(uint sigmaSQ, uint bn) private view returns (uint k) {
        k = 0.002 ether + (_sqrt((block.number - bn) * BLOCK_TIME * sigmaSQ * 1 ether) >> 1);
    }

    // // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    // function _sqrt(uint y) private pure returns (uint z) {
    //     if (y > 3) {
    //         z = y;
    //         uint x = (y >> 1) + 1;
    //         while (x < z) {
    //             z = x;
    //             x = (y / x + x) >> 1;
    //         }
    //     } else if (y != 0) {
    //         z = 1;
    //     }
    // }

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

    // Check price
    function _checkPrice(uint price, uint avgPrice) private pure {
        require(
            price <= avgPrice * 11 / 10 &&
            price >= avgPrice * 9 / 10, 
            "CoFiXController: price deviation"
        );
    }
    
    /// @return adm The admin slot.
    function getAdmin() external view returns (address adm) {
        assembly {
            adm := sload(0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103)
        }
    }
}