// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "./CoFiXPair.sol";
import "hardhat/console.sol";

// Pair contract for each trading pair, storing assets and handling settlement
// No owner or governance
contract CoFiXPair_USDT is CoFiXPair {
    constructor (
        string memory name_, 
        string memory symbol_, 
        address tokenAddress, 
        uint initETHAmount, 
        uint initTokenAmount
    ) CoFiXPair('', '', address(0), 1, 1) {

    }
}
