// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.6;

import "../interfaces/external/IWETH9.sol";

import "../libs/SimpleERC20.sol";

contract WETH is SimpleERC20, IWETH9 {

    constructor() {
    }

    function name() public pure override returns (string memory) {
        return "WETH";
    }

    function symbol() external pure override returns (string memory) {
        return "WETH";
    }

    function decimals() public pure override returns (uint8) {
        return 18;
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