// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./CoFiXERC20.sol";

/// @dev Anchor pool xtoken
contract CoFiXAnchorToken is CoFiXERC20 {

    // Address of anchor pool
    address immutable POOL;

    // ERC20 - name
    string public name;
    
    // ERC20 - symbol
    string public symbol;

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
        require(msg.sender == POOL, "CoFiXAnchorToken: Only for CoFiXAnchorPool");
        _;
    }

    /// @dev Distribute xtoken
    /// @param to The address which xtoken distribute to
    /// @param amount Amount of xtoken
    function mint(
        address to, 
        uint amount
    ) external check returns (uint) {
        _mint(to, amount);
        return amount;
    }

    /// @dev Burn xtoken
    /// @param amount Amount of xtoken
    function burn(
        uint amount
    ) external { 
        _burn(msg.sender, amount);
    }
}
