// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.6;

import "../interfaces/external/IWETH9.sol";

import "../libs/ERC20_LIB.sol";

import "hardhat/console.sol";

contract WETH is ERC20_LIB {

    constructor() ERC20_LIB("WETH", "WETH") {
        _setupDecimals(18);
    }

    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable {
        _mint(msg.sender, msg.value);
    }

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256 value) external {
        _burn(msg.sender, value);
        payable(msg.sender).transfer(value);
    }
}