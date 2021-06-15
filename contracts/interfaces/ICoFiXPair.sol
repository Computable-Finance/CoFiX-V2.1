// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

/// @dev Router contract to interact with each CoFiXPair, no owner or governance
interface ICoFiXPair {

    struct Config {
        uint64 theta;
        uint64 k;
    }
    
    function getInitialAssetRatio() external view returns (uint initETHAmount, uint initTokenAmount);

    // this low-level function should be called from a contract which performs important safety checks
    function mint(
        address to, 
        uint amountETH, 
        uint amountToken,
        address paybackAddress
    ) external payable returns (
        uint liquidity
    );

    function burn(
        uint liquidity, 
        address to, 
        address paybackAddress
    ) external payable returns (
        uint amountTokenOut, 
        uint amountETHOut
    );
    
    function swapForToken(
        uint amountIn, 
        address to, 
        address paybackAddress
    ) external payable returns (
        uint amountTokenOut, 
        uint mined
    );
    
    function swapForETH(
        uint amountIn, 
        address to, 
        address paybackAddress
    ) external payable returns (
        uint amountETHOut, 
        uint mined
    );

    function impactCostForBuyInETH(uint vol) external view returns (uint impactCost);

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