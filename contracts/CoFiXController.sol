// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./interfaces/ICoFiXController.sol";

import "hardhat/console.sol";

/// @dev This interface defines the methods for price call entry
contract CoFiXController is ICoFiXController {

    uint constant K_ALPHA = 0.00001 ether;
    uint constant K_BETA = 10 ether;
    uint constant BLOCK_TIME = 14;

    // nest价格调用合约地址
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

    /// @dev 查询价格
    /// @param tokenAddress 目标token地址
    /// @param payback 手续费退回接收地址
    /// @return ethAmount 价格-eth数量
    /// @return tokenAmount 价格-token数量
    /// @return blockNumber 价格所在区块
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

        k = (K_ALPHA * (block.number - bn) * 14 ether + K_BETA * sigma) * gamma / 1e36;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) private pure returns (uint z) {
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