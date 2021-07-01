// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "./INestPriceFacade.sol";

/// @dev This interface defines the methods for price call entry
interface ICoFiXController {

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

    /// @dev 查询价格
    /// @param tokenAddress 目标token地址
    /// @param payback 手续费退回接收地址
    /// @return ethAmount 价格-eth数量
    /// @return tokenAmount 价格-token数量
    /// @return blockNum 价格所在区块
    function queryPrice(
        address tokenAddress,
        address payback
    ) external payable returns (
        uint ethAmount, 
        uint tokenAmount, 
        uint blockNum
    );

    /// @dev Calc variance of price and K in CoFiX is very expensive
    /// We use expected value of K based on statistical calculations here to save gas
    /// In the near future, NEST could provide the variance of price directly. We will adopt it then.
    /// We can make use of `data` bytes in the future
    /// @param tokenAddress 目标token地址
    /// @param payback 手续费退回接收地址
    /// @return k The K value(18 decimal places).
    /// @return ethAmount 价格-eth数量
    /// @return tokenAmount 价格-token数量
    /// @return blockNum 价格所在区块
    function queryOracle(
        address tokenAddress,
        address payback
    ) external payable returns (
        uint k, 
        uint ethAmount, 
        uint tokenAmount, 
        uint blockNum
    );

    /// @notice Calc K value
    /// @param sigmaSQ The square of the volatility (18 decimal places).
    /// @param bn The block number when (ETH, TOKEN) price takes into effective
    /// @return k The K value(18 decimal places).
    function calcK(uint sigmaSQ, uint bn) external view returns (uint k);

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
    external 
    payable 
    returns (
        uint blockNumber, 
        uint priceEthAmount,
        uint priceTokenAmount,
        uint avgPriceEthAmount,
        uint avgPriceTokenAmount,
        uint sigmaSQ
    );
}