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

    // 账户信息
    struct Account {
        uint128 balance;
        uint128 rewardCursor;
    }

    constructor (address cofiToken, address cnodeToken) {
        COFI_TOKEN_ADDRESS = cofiToken;
        CNODE_TOKEN_ADDRESS = cnodeToken;
        _blockCursor = block.number;
    }

    address immutable COFI_TOKEN_ADDRESS;
    address immutable CNODE_TOKEN_ADDRESS;
    uint constant COFI_GENESIS_BLOCK = 0;

    Config _config;
    address _cofixRouter;
    uint _totalStaked;

    // 标记
    uint _totalReward;
    uint _rewardPerToken;
    uint _tradeReward;
    uint _blockCursor;

    // address=>balance
    mapping(address=>Account) _accounts;

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

    function balanceOf(address addr) external view override returns (uint) {
        return uint(_accounts[addr].balance);
    }

    function earned(address addr) public view override returns (uint) {

        Account memory account = _accounts[addr];
        (
            ,//uint tradeReward, 
            ,//uint newReward, 
            uint rewardPerToken
        ) = _calcReward(_totalStaked);
        return (rewardPerToken - uint(account.rewardCursor)) * uint(account.balance);
    }

    function stake(address to, uint amount) external override {

        _getReward(to);

        TransferHelper.safeTransferFrom(CNODE_TOKEN_ADDRESS, msg.sender, address(this), amount);
        _totalStaked += amount;

        Account storage account = _accounts[to];
        account.balance = uint128(uint(account.balance) + amount);
    }

    function unstake(uint amount) external override {
        
        _getReward(msg.sender);

        _totalStaked -= amount;
        Account storage account = _accounts[msg.sender];
        account.balance = uint128(uint(account.balance) - amount);
        TransferHelper.safeTransfer(CNODE_TOKEN_ADDRESS, msg.sender, amount);
    }

    function getReward() external override {
        _getReward(msg.sender);
    }

    function _getReward(address addr) private {

        Account memory account = _accounts[addr];
        uint rewardPerToken = _updatReward();
        uint reward = (rewardPerToken - account.rewardCursor) * account.balance;
        account.rewardCursor = uint128(rewardPerToken);
        _accounts[addr] = account;
        CoFiToken(COFI_TOKEN_ADDRESS).mint(addr, reward);
    }

    // 更新分红信息
    function _updatReward() private returns (uint){
        uint totalStaked = _totalStaked;
        if (totalStaked > 0) {
            (
                uint tradeReward, 
                uint newReward, 
                uint rewardPerToken
            ) = _calcReward(totalStaked);
            
            // 更新已经计算的累计分红数量
            _totalReward += newReward;
            // 更新单位份额的分红值
            _rewardPerToken = rewardPerToken;
            // 更新交易分成
            _tradeReward = tradeReward;
            // 更新已经结算的区块
            _blockCursor = block.number;

            return rewardPerToken;
        }
    }

    function _calcReward(uint totalStaked) public view returns (
        uint tradeReward, 
        uint newReward, 
        uint rewardPerToken
    ) {
        // 重新计算总分红数量
        tradeReward = ICoFiXRouter(_cofixRouter).getTradeReward(CNODE_TOKEN_ADDRESS);
        newReward =
            //_totalReward +
            // CNode区块出矿量
            // TODO: CNode出矿衰减
            (block.number - _blockCursor) * 1 ether * uint(_config.cofiRate) * _redution(block.number - COFI_GENESIS_BLOCK) / 40000000 +
            // 交易出矿量给CNode的分成
            tradeReward - _tradeReward;

        // 重新计算单位份额分红值
        rewardPerToken = newReward / totalStaked + _rewardPerToken;
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
    function _redution(uint delta) private pure returns (uint) {
        
        if (delta < NEST_REDUCTION_LIMIT) {
            return (NEST_REDUCTION_STEPS >> ((delta / NEST_REDUCTION_SPAN) << 4)) & 0xFFFF;
        }
        return (NEST_REDUCTION_STEPS >> 160) & 0xFFFF;
    }
}
