// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./libs/TransferHelper.sol";

import "./interfaces/ICoFiXVaultForLP.sol";
import "./CoFiToken.sol";
import "hardhat/console.sol";

// Router contract to interact with each CoFiXPair, no owner or governance
contract CoFiXVaultForLP is ICoFiXVaultForLP {

    constructor (address cofiToken) {
        COFI_TOKEN_ADDRESS = cofiToken;
    }

    address immutable COFI_TOKEN_ADDRESS;

    struct StakeChannel{
        uint total;
        // address=>balance
        mapping(address=>uint) balances;
    }

    // pair=>StakeChannel
    mapping(address=>StakeChannel) _channels;

    function balanceOf(address pair, address addr) external view override returns (uint) {
        return _channels[pair].balances[addr];
    }

    function earned(address pair, address addr) public view override returns (uint) {
        return 0;
    }

    function stake(address pair, address to, uint amount) external override {

        TransferHelper.safeTransferFrom(pair, msg.sender, address(this), amount);
        StakeChannel storage channel = _channels[pair];
        channel.total += amount;
        channel.balances[to] += amount;
    }

    function unstake(address pair, uint amount) external override {
        StakeChannel storage channel = _channels[pair];
        channel.total -= amount;
        channel.balances[msg.sender] -= amount;
        TransferHelper.safeTransfer(pair, msg.sender, amount);
    }

    function getReward(address pair) external override {
        uint reward = earned(pair, msg.sender);
        CoFiToken(COFI_TOKEN_ADDRESS).mint(msg.sender, reward);
    }
}
