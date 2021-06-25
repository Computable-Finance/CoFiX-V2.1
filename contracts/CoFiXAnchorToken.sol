// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "./libs/IERC20.sol";
import "./libs/TransferHelper.sol";

import "./interfaces/ICoFiXPool.sol";
import "./interfaces/ICoFiXController.sol";
import "./interfaces/ICoFiXDAO.sol";

import "./CoFiXBase.sol";
import "./CoFiToken.sol";
import "./CoFiXERC20.sol";

import "hardhat/console.sol";

/// @dev 锚定份额币
contract CoFiXAnchorToken is CoFiXERC20 {

    // ERC20 - name
    string public name;
    
    // ERC20 - symbol
    string public symbol;

    address _pool;

    // 构造函数，为了支持openzeeplin的可升级方案，需要将构造函数移到initialize方法中实现
    constructor (
        string memory name_, 
        string memory symbol_,
        address pool
    ) {
        name = name_;
        symbol = symbol_;
        _pool = pool;
    }

    modifier check() {
        require(msg.sender == _pool, "CoFiXAnchorToken: Only for CoFiXAnchorToken");
        _;
    }

    function mint(
        address to, 
        uint amount
    ) external check {
        _mint(to, amount);
    }

    function burn(
        address to, 
        uint amount
    ) external check { 
        _burn(to, amount);
    }
}
