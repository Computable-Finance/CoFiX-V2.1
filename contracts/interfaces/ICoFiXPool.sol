// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev 此接口定义了资金池的方法和事件
interface ICoFiXPool {

    /*
    ETH交易对: ETU/USDT, ETH/HBTC, ETH/NEST, ETH/COFI
    稳定币交易池：USDT|DAI|TUSD|PUSD, ETH|PETH
     */

    /// @dev 做市出矿事件
    /// @param token 目标token地址
    /// @param to 份额接收地址
    /// @param amountETH 要添加的eth数量
    /// @param amountToken 要添加的token数量
    /// @param liquidity 获得的流动性份额
    event Mint(address token, address to, uint amountETH, uint amountToken, uint liquidity);
    
    /// @dev 移除流动性并销毁
    /// @param token 目标token地址
    /// @param to 资金接收地址
    /// @param liquidity 需要移除的流动性份额
    /// @param amountETHOut 获得的eth数量
    /// @param amountTokenOut 获得的token数量
    event Burn(address token, address to, uint liquidity, uint amountETHOut, uint amountTokenOut);

    /// @dev 设置参数
    /// @param theta 手续费，万分制。20
    /// @param gamma 冲击成本系数。
    /// @param nt 每一单位token（对于二元池，指单位eth）标准出矿量，万分制。1000
    function setConfig(uint16 theta, uint16 gamma, uint32 nt) external;

    /// @dev 获取参数
    /// @return theta 手续费，万分制。20
    /// @return gamma 冲击成本系数。
    /// @return nt 每一单位token（对于二元池，指单位eth）标准出矿量，万分制。1000
    function getConfig() external view returns (uint16 theta, uint16 gamma, uint32 nt);

    /// @dev 添加流动性并增发份额
    /// @param token 目标token地址
    /// @param to 份额接收地址
    /// @param amountETH 要添加的eth数量
    /// @param amountToken 要添加的token数量
    /// @param payback 退回的手续费接收地址
    /// @return xtoken 获得的流动性份额代币地址
    /// @return liquidity 获得的流动性份额
    function mint(
        address token,
        address to, 
        uint amountETH, 
        uint amountToken,
        address payback
    ) external payable returns (
        address xtoken,
        uint liquidity
    );

    /// @dev 移除流动性并销毁
    /// @param token 目标token地址
    /// @param to 资金接收地址
    /// @param liquidity 需要移除的流动性份额
    /// @param payback 退回的手续费接收地址
    /// @return amountETHOut 获得的eth数量
    /// @return amountTokenOut 获得的token数量
    function burn(
        address token,
        address to, 
        uint liquidity, 
        address payback
    ) external payable returns (
        uint amountETHOut,
        uint amountTokenOut 
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

    /// @dev 获取指定token做市获得的份额代币地址
    /// @param token 目标token
    /// @return 如果资金池支持指定的token，返回做市份额代币地址
    function getXToken(address token) external view returns (address);
}