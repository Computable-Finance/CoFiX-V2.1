// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

/// @dev Router contract to interact with each CoFiXPair
interface ICoFiXPair {

    /// @dev 做市出矿事件
    /// @param to 份额接收地址
    /// @param amountETH 要添加的eth数量
    /// @param amountToken 要添加的token数量
    /// @param liquidity 获得的流动性份额
    event Mint(address to, uint amountETH, uint amountToken, uint liquidity);
    
    /// @dev 移除流动性并销毁
    /// @param to 资金接收地址
    /// @param liquidity 需要移除的流动性份额
    /// @param amountTokenOut 获得的token数量
    /// @param amountETHOut 获得的eth数量
    event Burn(address to, uint liquidity, uint amountTokenOut, uint amountETHOut);

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

    /// @dev CoFiXPair configuration structure
    struct Config {
        uint64 theta;
        uint64 k;
    }
    
    /// @dev 获取初始资产比例
    /// @param initETHAmount 初始资产比例 - ETH
    /// @param initTokenAmount 初始资产比例 - TOKEN
    function getInitialAssetRatio() external view returns (uint initETHAmount, uint initTokenAmount);

    /// @dev 添加流动性并增发份额
    /// @param to 份额接收地址
    /// @param amountETH 要添加的eth数量
    /// @param amountToken 要添加的token数量
    /// @param payback 退回的手续费接收地址
    /// @return liquidity 获得的流动性份额
    function mint(
        address to, 
        uint amountETH, 
        uint amountToken,
        address payback
    ) external payable returns (
        uint liquidity
    );

    /// @dev 移除流动性并销毁
    /// @param liquidity 需要移除的流动性份额
    /// @param to 资金接收地址
    /// @param payback 退回的手续费接收地址
    /// @return amountTokenOut 获得的token数量
    /// @return amountETHOut 获得的eth数量
    function burn(
        uint liquidity, 
        address to, 
        address payback
    ) external payable returns (
        uint amountTokenOut, 
        uint amountETHOut
    );
    
    /// @dev 用eth兑换token
    /// @param amountIn 兑换的eth数量
    /// @param to 兑换资金接收地址
    /// @param payback 退回的手续费接收地址
    /// @return amountTokenOut 兑换到的token数量
    /// @return mined 出矿量
    function swapForToken(
        uint amountIn, 
        address to, 
        address payback
    ) external payable returns (
        uint amountTokenOut, 
        uint mined
    );
    
    /// @dev 用token兑换eth
    /// @param amountIn 兑换的token数量
    /// @param to 兑换资金接收地址
    /// @param payback 退回的手续费接收地址
    /// @return amountETHOut 兑换到的token数量
    /// @return mined 出矿量
    function swapForETH(
        uint amountIn, 
        address to, 
        address payback
    ) external payable returns (
        uint amountETHOut, 
        uint mined
    );

    /// @dev 计算买入eth的冲击成本
    /// @param vol 以eth计算的交易规模
    /// @return impactCost 冲击成本
    function impactCostForBuyInETH(uint vol) external view returns (uint impactCost);

    /// @dev 计算卖出eth的冲击成本
    /// @param vol 以eth计算的交易规模
    /// @return impactCost 冲击成本
    function impactCostForSellOutETH(uint vol) external view returns (uint impactCost);

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
}