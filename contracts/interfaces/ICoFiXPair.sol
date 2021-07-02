// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./ICoFiXPool.sol";

/// @dev 二元资金池: eth/token
interface ICoFiXPair is ICoFiXPool {

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

    /// @dev 获取初始资产比例
    /// @return initToken0Amount 初始资产比例 - ETH
    /// @return initToken1Amount 初始资产比例 - TOKEN
    function getInitialAssetRatio() external view returns (uint initToken0Amount, uint initToken1Amount);

    /// @dev 预估出矿量
    /// @param newBalance0 新的eth余额
    /// @param newBalance1 新的token余额
    /// @param ethAmount 预言机价格-eth数量
    /// @param tokenAmount 预言机价格-token数量
    /// @return mined 预计出矿量
    function estimate(
        uint newBalance0, 
        uint newBalance1, 
        uint ethAmount, 
        uint tokenAmount
    ) external view returns (uint mined);
    
    /// @dev 计算净值
    /// @param balance0 资金池eth余额
    /// @param balance1 资金池token余额
    /// @param ethAmount 预言机价格-eth数量
    /// @param tokenAmount 预言机价格-token数量
    /// @return navps 净值
    function calcNAVPerShare(
        uint balance0, 
        uint balance1, 
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