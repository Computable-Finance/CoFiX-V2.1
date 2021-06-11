// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

/// @dev Router contract to interact with each CoFiXPair, no owner or governance
interface ICoFiXPair {

    function getInitialAssetRatio() external view returns (uint initEthAmount, uint initTokenAmount);

    // this low-level function should be called from a contract which performs important safety checks
    function mint(
        address to, 
        uint amountETH, 
        uint amountToken,
        address paybackAddress
    ) external payable returns (
        uint liquidity
    );

    function burn(uint liquidity, address to, address paybackAddress) external payable returns (uint amountTokenOut, uint amountEthOut);
    
    function swapForToken(uint amountIn, address to, address paybackAddress) external payable returns (uint amountTokenOut, uint Z);
    
    function swapForETH(uint amountIn, address to, address paybackAddress) external payable returns (uint amountEthOut, uint Z);

    function impactCostForBuyInETH(uint vol) external view returns (uint impactCost);

    function impactCostForSellOutETH(uint vol) external view returns (uint impactCost);
}