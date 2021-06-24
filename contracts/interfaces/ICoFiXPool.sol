// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

/// @dev Router contract to interact with each CoFiXPair
interface ICoFiXPool {

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
    
    /// @dev 执行兑换交易
    /// @param src 源资产token地址
    /// @param dest 目标资产token地址
    /// @param amountIn 输入源资产数量
    /// @param to 兑换资金接收地址
    /// @param payback 退回的手续费接收地址
    /// @return amountOut 兑换到的目标资产数量
    /// @return mined 出矿量
    function swap(
        address src, 
        address dest, 
        uint amountIn, 
        address to, 
        address payback
    ) external payable returns (
        uint amountOut, 
        uint mined
    );
}