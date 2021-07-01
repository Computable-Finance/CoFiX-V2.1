// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "./CoFiXERC20.sol";

/// @dev 锚定份额代币
contract CoFiXAnchorToken is CoFiXERC20 {

    // it's negligible because we calc liquidity in ETH
    uint constant MINIMUM_LIQUIDITY = 1e9; 

    // 锚定池地址
    address immutable POOL;

    // ERC20 - name
    string public name;
    
    // ERC20 - symbol
    string public symbol;

    // 构造函数，为了支持openzeeplin的可升级方案，需要将构造函数移到initialize方法中实现
    constructor (
        string memory name_, 
        string memory symbol_,
        address pool
    ) {
        name = name_;
        symbol = symbol_;
        POOL = pool;
    }

    modifier check() {
        require(msg.sender == POOL, "CoFiXAnchorToken: Only for CoFiXAnchorToken");
        _;
    }

    /// @dev 发行份额代币
    /// @param to 份额接收地址
    /// @param amount 份额数量
    function mint(
        address to, 
        uint amount
    ) external check returns (uint) {
        if (totalSupply == 0) {
            // TODO: 确定基础份额的逻辑
            // permanently lock the first MINIMUM_LIQUIDITY tokens
            // 当发行量为0时，有一个基础份额
            amount -= MINIMUM_LIQUIDITY;
            _mint(address(0), MINIMUM_LIQUIDITY);
        }
        _mint(to, amount);
        return amount;
    }

    /// @dev 销毁份额代币
    /// @param amount 份额数量
    function burn(
        uint amount
    ) external { 
        _burn(msg.sender, amount);
    }
}
