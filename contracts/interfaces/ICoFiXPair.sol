// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "./ICoFiXPool.sol";

/// @dev 二元资金池: eth/token
interface ICoFiXPair is ICoFiXPool {

    // struct Config {
    //     // 手续费，万分制。20
    //     uint16 theta;
    //     // n_t为每一单位ETH标准出矿量为，当前n_t=0.1。万分制。 10000
    //     uint16 nt;
    //     // 冲击成本系数。
    //     uint16 gama;
    //     // // 冲击成本基数。
    //     // uint16 VOL_BASE;
    //     // // 冲击成本α。
    //     // uint64 C_BUYIN_ALPHA;
    //     // uint64 C_BUYIN_ALPHA;
    // }

    /// @dev 用eth兑换token事件
    /// @param amountIn 兑换的eth数量
    /// @param to 兑换资金接收地址
    /// @param amountTokenOut 兑换到的token数量
    /// @param mined 出矿量
    event SwapForToken(uint amountIn, address to, uint amountTokenOut, uint mined);

    /// @dev 用token兑换eth
    /// @param amountIn 兑换的token数量
    /// @param to 兑换资金接收地址
    /// @param amountETHOut 兑换到的token数量
    /// @param mined 出矿量
    event SwapForETH(uint amountIn, address to, uint amountETHOut, uint mined);

    // /// @dev Modify configuration
    // /// @param config Configuration object
    // function setConfig(Config memory config) external;

    // /// @dev Get configuration
    // /// @return Configuration object
    // function getConfig() external view returns (Config memory);

    /// @dev 获取初始资产比例
    /// @param initToken0Amount 初始资产比例 - ETH
    /// @param initToken1Amount 初始资产比例 - TOKEN
    function getInitialAssetRatio() external view returns (uint initToken0Amount, uint initToken1Amount);

    // /// @dev 用eth兑换token
    // /// @param amountIn 兑换的eth数量
    // /// @param to 兑换资金接收地址
    // /// @param payback 退回的手续费接收地址
    // /// @return amountTokenOut 兑换到的token数量
    // /// @return mined 出矿量
    // function swapForToken(
    //     uint amountIn, 
    //     address to, 
    //     address payback
    // ) external payable returns (
    //     uint amountTokenOut, 
    //     uint mined
    // );
    
    // /// @dev 用token兑换eth
    // /// @param amountIn 兑换的token数量
    // /// @param to 兑换资金接收地址
    // /// @param payback 退回的手续费接收地址
    // /// @return amountETHOut 兑换到的token数量
    // /// @return mined 出矿量
    // function swapForETH(
    //     uint amountIn, 
    //     address to, 
    //     address payback
    // ) external payable returns (
    //     uint amountETHOut, 
    //     uint mined
    // );

    /// @dev 计算净值
    /// @param ethBalance 资金池eth余额
    /// @param tokenBalance 资金池token余额
    /// @param ethAmount 预言机价格-eth数量
    /// @param tokenAmount 预言机价格-token数量
    /// @return navps 净值
    function calcNAVPerShare(
        uint ethBalance, 
        uint tokenBalance, 
        uint ethAmount, 
        uint tokenAmount
    ) external view returns (uint navps);
    
    /// @dev 获取净值
    /// @param ethAmount 预言机价格-eth数量
    /// @param tokenAmount 预言机价格-token数量
    /// @return navps 净值
    function getNAVPerShare(
        uint ethAmount, 
        uint tokenAmount
    ) external view returns (uint navps);

    /// @dev 计算买入eth的冲击成本
    /// @param vol 以eth计算的交易规模
    /// @return impactCost 冲击成本
    function impactCostForBuyInETH(uint vol) external view returns (uint impactCost);

    /// @dev 计算卖出eth的冲击成本
    /// @param vol 以eth计算的交易规模
    /// @return impactCost 冲击成本
    function impactCostForSellOutETH(uint vol) external view returns (uint impactCost);
}