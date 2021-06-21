// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "./interfaces/ICoFiXController.sol";
import "hardhat/console.sol";

/// @dev This interface defines the methods for price call entry
contract CoFiXController is ICoFiXController {

    /// @dev Get the latest effective price
    /// @param tokenAddress Destination token address
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    function latestPriceView(address tokenAddress) external view returns (uint blockNumber, uint price) {
        // TODO:
        require(tokenAddress != address(0));
        return (block.number - 1, 2700 * 1000000);
    }

    /// @dev Get the latest effective price
    /// @param tokenAddress Destination token address
    /// @param payback As the charging fee may change, it is suggested that the caller pay more fees, and the excess fees will be returned through this address
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    function latestPrice(address tokenAddress, address payback) public payable override returns (uint blockNumber, uint price) {
        // TODO:
        require(tokenAddress != address(0));
        require(payback != address(0));
        return (block.number - 1, 2700 * 1000000);
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
        // TODO:
        require(tokenAddress != address(0));
        require(payback != address(0));
        return (block.number - 1, 2700 * 1000000, block.number - 1, 2700 * 1000000, 2600 * 1000000, 10853469234);
    }

    // Calc variance of price and K in CoFiX is very expensive
    // We use expected value of K based on statistical calculations here to save gas
    // In the near future, NEST could provide the variance of price directly. We will adopt it then.
    // We can make use of `data` bytes in the future
    function queryPrice(
        address tokenAddress,
        address payback
    ) external payable override returns (
        uint ethAmount, 
        uint tokenAmount, 
        uint blockNum
    ) {
        (blockNum, tokenAmount) = latestPrice(tokenAddress, payback);
        ethAmount = 1 ether;
    }

    // Calc variance of price and K in CoFiX is very expensive
    // We use expected value of K based on statistical calculations here to save gas
    // In the near future, NEST could provide the variance of price directly. We will adopt it then.
    // We can make use of `data` bytes in the future
    function queryOracle(
        address tokenAddress,
        address payback
    ) external override payable returns (
        uint k, 
        uint ethAmount, 
        uint tokenAmount, 
        uint blockNum//, 
        //uint theta
    ) {
        (
            uint latestPriceBlockNumber, 
            uint latestPriceValue,
            ,//uint triggeredPriceBlockNumber,
            ,//uint triggeredPriceValue,
            ,//uint triggeredAvgPrice,
            uint triggeredSigmaSQ
        ) = latestPriceAndTriggeredPriceInfo(tokenAddress, payback);

        ethAmount = 1 ether;
        tokenAmount = latestPriceValue;
        blockNum = latestPriceBlockNumber;
        //theta = 0.002 ether;
        
        // uint sigma = sqrt(triggeredSigmaSQ * 1 ether);
        // //_k = K_ALPHA.mul(_op.T).mul(1e18).add(K_BETA.mul(_op.sigma)).mul(gamma).div(K_GAMMA_BASE).div(1e18);
        // // K=(0.00001*T+10*σ)*γ(σ)
        // uint gama = 1 ether;
        // if (sigma > 0.0005 ether) {
        //     gama = 2 ether;
        // } else if (sigma > 0.0003 ether) {
        //     gama = 1.5 ether;
        // }

        // k = (0.00001 ether * (block.number - blockNum) * 14 + 10 ether * sigma) * gama / 1 ether / 1 ether;

        k = calcK(triggeredSigmaSQ, blockNum);
    }

    // TODO: 注意K值是18位小数
   /**
    * @notice Calc K value
    * @param sigmaSQ The square of the volatility (18 decimal places).
    * @param bn The block number when (ETH, TOKEN) price takes into effective
    * @return k The K value
    */
    function calcK(uint sigmaSQ, uint bn) public view override returns (uint k) {

        // TODO: 考虑波动率开方精度问题，是否可以不需要那么高的精度
        //10853469234
        // 计算波动率

        // TODO: 修改算法为配置
        uint sigma = sqrt(sigmaSQ * 1e18);
        uint gama = 1 ether;
        if (sigma > 0.0005 ether) {
            gama = 2 ether;
        } else if (sigma > 0.0003 ether) {
            gama = 1.5 ether;
        }
        // _k = K_ALPHA.mul(_op.T).mul(1e18).add(K_BETA.mul(_op.sigma)).mul(gamma).div(K_GAMMA_BASE).div(1e18);
        // k = (K_ALPHA.mul(_T   ).mul(1e18).add(K_BETA.mul(     vola)).mul(gamma).div(K_GAMMA_BASE).div(1e18));
        k = (0.00001 ether * (block.number - bn) * 14 + 10 ether * sigma) * gama / 1 ether / 1 ether;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) public pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function sqrt2_(uint y) public pure returns (uint z) {
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