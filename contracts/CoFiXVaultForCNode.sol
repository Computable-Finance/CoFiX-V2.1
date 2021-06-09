// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./libs/TransferHelper.sol";

import "./interfaces/ICoFiXVaultForCNode.sol";
import "./interfaces/ICoFiXRouter.sol";
import "./CoFiToken.sol";
import "hardhat/console.sol";

// Router contract to interact with each CoFiXPair, no owner or governance
contract CoFiXVaultForCNode is ICoFiXVaultForCNode {

    constructor (address cofiToken, address cnodeToken) {
        COFI_TOKEN_ADDRESS = cofiToken;
        CNODE_TOKEN_ADDRESS = cnodeToken;
    }

    address immutable COFI_TOKEN_ADDRESS;
    address immutable CNODE_TOKEN_ADDRESS;
    address _cofixRouter;

    uint _total;
    // address=>balance
    mapping(address=>uint) _balances;

    function balanceOf(address addr) external view override returns (uint) {
        return _balances[addr];
    }

    function getTotal() private view returns (uint) {
        return ICoFiXRouter(_cofixRouter).getCNodeReward() + block.number;
    }

    function earned(address addr) public view override returns (uint) {
        return 0;
    }

    function stake(address to, uint amount) external override {

        TransferHelper.safeTransferFrom(CNODE_TOKEN_ADDRESS, msg.sender, address(this), amount);
        _total += amount;
        _balances[to] += amount;
    }

    function unstake(address pair, uint amount) external override {
        _total -= amount;
        _balances[msg.sender] -= amount;
        TransferHelper.safeTransfer(CNODE_TOKEN_ADDRESS, msg.sender, amount);
    }

    function getReward() external override {
        uint reward = earned(msg.sender);
        CoFiToken(COFI_TOKEN_ADDRESS).mint(msg.sender, reward);
    }
}
