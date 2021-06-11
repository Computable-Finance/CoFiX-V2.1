// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./libs/TransferHelper.sol";

import "./interfaces/ICoFiXDAO.sol";
import "./CoFiToken.sol";
import "hardhat/console.sol";

// Router contract to interact with each CoFiXPair, no owner or governance
contract CoFiXDAO is ICoFiXDAO {

    function addETHReward(address pair) external payable override {

    }
}
