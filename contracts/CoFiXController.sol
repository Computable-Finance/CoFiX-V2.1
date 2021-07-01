// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "./interfaces/ICoFiXController.sol";
import "hardhat/console.sol";

/// @dev This interface defines the methods for price call entry
contract CoFiXController is ICoFiXController {

    address immutable NEST_PRICE_FADADE;

    constructor(address nestPriceFacade) {
        NEST_PRICE_FADADE = nestPriceFacade;
    }

    /// @dev 查询最新价格信息
    /// @param tokenAddress token地址
    /// @param payback 退回的手续费接收地址
    /// @return blockNumber 价格所在区块号
    /// @return priceEthAmount 预言机价格-eth数量
    /// @return priceTokenAmount 预言机价格-token数量
    /// @return avgPriceEthAmount 平均价格-eth数量
    /// @return avgPriceTokenAmount 平均价格-token数量
    /// @return sigmaSQ 波动率的平方（18位小数）
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
        // (uint bn, uint price) = INestPriceFacade(NEST_PRICE_FADADE).latestPrice { 
        //     value: msg.value 
        // } (tokenAddress, payback);
        // return (block.number - bn, 1 ether, price, 1 ether, price * 95 / 100, 10853469234);
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
    function queryPrice(
        address tokenAddress,
        address payback
    ) external payable override returns (
        uint ethAmount, 
        uint tokenAmount, 
        uint blockNum
    ) {
        (blockNum, tokenAmount) = INestPriceFacade(NEST_PRICE_FADADE).latestPrice { 
            value: msg.value 
        } (tokenAddress, payback);
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
        uint blockNumber//, 
        //uint theta
    ) {
        // (
        //     uint latestPriceBlockNumber, 
        //     uint latestPriceValue,
        //     ,//uint triggeredPriceBlockNumber,
        //     ,//uint triggeredPriceValue,
        //     ,//uint triggeredAvgPrice,
        //     uint triggeredSigmaSQ
        // ) = INestPriceFacade(NEST_PRICE_FADADE).latestPriceAndTriggeredPriceInfo { 
        //     value: msg.value 
        // } (tokenAddress, payback);

        uint sigmaSQ;
        (
            blockNumber, 
            ethAmount,
            tokenAmount,
            ,//uint avgPriceEthAmount,
            ,//uint avgPriceTokenAmount,
            sigmaSQ
        ) = latestPriceInfo(tokenAddress, payback);

        //ethAmount = 1 ether;
        //tokenAmount = latestPriceValue;
        //blockNum = latestPriceBlockNumber;

        k = calcK(sigmaSQ, blockNumber);
    }

    // TODO: 注意K值是18位小数
   /**
    * @notice Calc K value
    * @param sigmaSQ The square of the volatility (18 decimal places).
    * @param bn The block number when (ETH, TOKEN) price takes into effective
    * @return k The K value
    */
    function calcK(uint sigmaSQ, uint bn) public view override returns (uint k) {
        // TODO: 修改算法为配置
        uint sigma = sqrt(sigmaSQ / 1e4) * 1e11;
        uint gamma = 1 ether;
        if (sigma > 0.0005 ether) {
            gamma = 2 ether;
        } else if (sigma > 0.0003 ether) {
            gamma = 1.5 ether;
        }
        // k = (K_ALPHA.mul(_T   ).mul(1e18).add(K_BETA.mul(     vola)).mul(gamma).div(K_GAMMA_BASE).div(1e18));
        //k = (0.00002 ether * (block.number - bn) * 14 + 40 ether * sigma) * gamma / 1 ether / 1 ether;
        k = (0.00001 ether * (block.number - bn) * 14 + 10 ether * sigma) * gamma / 1 ether / 1 ether;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) public pure returns (uint z) {
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