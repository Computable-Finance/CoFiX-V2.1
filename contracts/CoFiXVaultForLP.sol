// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./libs/TransferHelper.sol";

import "./interfaces/ICoFiXVaultForLP.sol";
import "./interfaces/ICoFiXRouter.sol";
import "./CoFiToken.sol";
import "hardhat/console.sol";

// Router contract to interact with each CoFiXPair, no owner or governance
contract CoFiXVaultForLP is ICoFiXVaultForLP {

    // 账户信息
    struct Account {
        uint128 balance;
        uint128 rewardCursor;
    }
    
    struct StakeChannel{
        uint totalStaked;
        // 标记
        uint totalReward;
        uint rewardPerToken;
        uint tradeReward;
        uint blockCursor;
        // address=>balance
        mapping(address=>Account) accounts;
    }

    constructor (address cofiToken, address cnodeToken) {
        COFI_TOKEN_ADDRESS = cofiToken;
        CNODE_TOKEN_ADDRESS = cnodeToken;
    }

    address immutable COFI_TOKEN_ADDRESS;
    address immutable CNODE_TOKEN_ADDRESS;

    uint constant COFI_GENESIS_BLOCK = 0;

    Config _config;
    address _cofixRouter;
    // pair=>StakeChannel
    mapping(address=>StakeChannel) _channels;
    
    function getConfig() external view override returns (Config memory) {
        return _config;
    }

    function setConfig(Config memory config) external override {
        _config = config;
    }

    function getCoFiXRouter() external view returns (address) {
        return _cofixRouter;
    }

    function setCoFiXRouter(address cofixRouter) external {
        _cofixRouter = cofixRouter;
    }

    function balanceOf(address pair, address addr) external view override returns (uint) {
        return uint(_channels[pair].accounts[addr].balance);
    }

    function earned(address pair, address addr) public view override returns (uint) {
        
        StakeChannel storage channel = _channels[pair];
        uint newTradeReward = 0;
        if (pair == CNODE_TOKEN_ADDRESS) {
            uint tradeReward = ICoFiXRouter(_cofixRouter).getTradeReward(pair);
            newTradeReward = tradeReward - channel.tradeReward;
        }
        Account memory account = channel.accounts[addr];
        (
            ,//uint newReward, 
            uint rewardPerToken
        ) = _calcReward(channel, channel.totalStaked, newTradeReward);
        return (rewardPerToken - uint(account.rewardCursor)) * uint(account.balance);
    }

    function stake(address pair, address to, uint amount) external override {

        StakeChannel storage channel = _channels[pair];
        _getReward(pair, channel, to);

        TransferHelper.safeTransferFrom(pair, msg.sender, address(this), amount);
        channel.totalStaked += amount;

        Account storage account = channel.accounts[to];
        account.balance = uint128(uint(account.balance) + amount);
    }

    function unstake(address pair, uint amount) external override {
        
        StakeChannel storage channel = _channels[pair];
        _getReward(pair, channel, msg.sender);

        channel.totalStaked -= amount;
        Account storage account = channel.accounts[msg.sender];
        account.balance = uint128(uint(account.balance) - amount);
        TransferHelper.safeTransfer(pair, msg.sender, amount);
    }

    function getReward(address pair) external override {
        uint reward = earned(pair, msg.sender);
        CoFiToken(COFI_TOKEN_ADDRESS).mint(msg.sender, reward);
    }

    function _getReward(address pair, StakeChannel storage channel, address addr) private {

        Account memory account = channel.accounts[addr];
        uint rewardPerToken = _updatReward(pair, channel);
        uint reward = (rewardPerToken - account.rewardCursor) * account.balance;
        account.rewardCursor = uint128(rewardPerToken);
        channel.accounts[addr] = account;
        if (reward > 0) {
            CoFiToken(COFI_TOKEN_ADDRESS).mint(addr, reward);
        }
    }

    // 更新分红信息
    function _updatReward(address pair, StakeChannel storage channel) private returns (uint){
        uint totalStaked = channel.totalStaked;
        if (totalStaked > 0) {

            uint newTradeReward = 0;
            if (pair == CNODE_TOKEN_ADDRESS) {
                uint tradeReward = ICoFiXRouter(_cofixRouter).getTradeReward(pair);
                newTradeReward = tradeReward - channel.tradeReward;
                // 更新交易分成
                channel.tradeReward = tradeReward;
            }
            (
                uint newReward, 
                uint rewardPerToken
            ) = _calcReward(channel, totalStaked, newTradeReward);
            
            // 更新已经计算的累计分红数量
            channel.totalReward += newReward;
            // 更新单位份额的分红值
            channel.rewardPerToken = rewardPerToken;
            // 更新已经结算的区块
            channel.blockCursor = block.number;

            return rewardPerToken;
        }
    }

    function _calcReward(StakeChannel storage channel, uint totalStaked, uint newTradeReward) internal view virtual returns (
        uint newReward, 
        uint rewardPerToken
    ) {
        // 重新计算总分红数量
        newReward =
            //_totalReward +
            // CNode区块出矿量
            // TODO: CNode出矿衰减
            (block.number - channel.blockCursor) * 1 ether * uint(_config.cofiRate) * _redution(block.number - COFI_GENESIS_BLOCK) / 40000000 +
            // 交易出矿量给CNode的分成
            newTradeReward;
            //tradeReward - channel.tradeReward;

        // 重新计算单位份额分红值
        rewardPerToken = newReward / totalStaked + channel.rewardPerToken;
    }

    // Nest ore drawing attenuation interval. 2400000 blocks, about one year
    uint constant NEST_REDUCTION_SPAN = 2400000;
    // The decay limit of nest ore drawing becomes stable after exceeding this interval. 24 million blocks, about 10 years
    uint constant NEST_REDUCTION_LIMIT = 24000000; // NEST_REDUCTION_SPAN * 10;
    // Attenuation gradient array, each attenuation step value occupies 16 bits. The attenuation value is an integer
    uint constant NEST_REDUCTION_STEPS = 0x280035004300530068008300A300CC010001400190;
        // 0
        // | (uint(400 / uint(1)) << (16 * 0))
        // | (uint(400 * 8 / uint(10)) << (16 * 1))
        // | (uint(400 * 8 * 8 / uint(10 * 10)) << (16 * 2))
        // | (uint(400 * 8 * 8 * 8 / uint(10 * 10 * 10)) << (16 * 3))
        // | (uint(400 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10)) << (16 * 4))
        // | (uint(400 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10)) << (16 * 5))
        // | (uint(400 * 8 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10 * 10)) << (16 * 6))
        // | (uint(400 * 8 * 8 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10 * 10 * 10)) << (16 * 7))
        // | (uint(400 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10 * 10 * 10 * 10)) << (16 * 8))
        // | (uint(400 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10 * 10 * 10 * 10 * 10)) << (16 * 9))
        // //| (uint(400 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10 * 10 * 10 * 10 * 10 * 10)) << (16 * 10));
        // | (uint(40) << (16 * 10));

    // Calculation of attenuation gradient
    function _redution(uint delta) internal pure returns (uint) {
        
        if (delta < NEST_REDUCTION_LIMIT) {
            return (NEST_REDUCTION_STEPS >> ((delta / NEST_REDUCTION_SPAN) << 4)) & 0xFFFF;
        }
        return (NEST_REDUCTION_STEPS >> 160) & 0xFFFF;
    }
}
