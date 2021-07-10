// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./libs/TransferHelper.sol";

import "./interfaces/ICoFiXVaultForStaking.sol";
import "./interfaces/ICoFiXRouter.sol";

import "./CoFiXBase.sol";
import "./CoFiToken.sol";

import "hardhat/console.sol";

/// @dev 存入做市份额或者CNode，领取CoFi出矿
contract CoFiXVaultForStaking is CoFiXBase, ICoFiXVaultForStaking {

    /// @dev 账户信息
    struct Account {
        // 账户锁仓余额
        uint128 balance;
        // 账户已经领取的单位token分红值标记
        uint128 rewardCursor;
    }
    
    /// @dev Stake通道信息
    struct StakeChannel{

        // 配置
        // 出矿权重
        uint cofiWeight;
        // stake数量
        uint totalStaked;

        // xtoken全局挖矿标记
        // 已结算的交易出矿总量标记
        uint128 tradeReward;
        // 已结算的总出矿量标记
        //uint128 totalReward;
        // 已结算的单位token可以领取的分红标记
        uint96 rewardPerToken;
        // 结算区块标记
        uint32 blockCursor;

        // 账户标记
        // address=>balance
        mapping(address=>Account) accounts;
    }
    
    // 总出矿速度权重
    uint constant TOTAL_COFI_WEIGHT = 100000;

    // Configuration
    Config _config;
    // Address of CoFiXRouter
    address _cofixRouter;
    // staking通道信息xtoken=>StakeChannel
    mapping(address=>StakeChannel) _channels;
    
    /// @dev Create CoFiXVaultForStaking
    constructor () {
    }

    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(newGovernance) when overriding, and override method without onlyGovernance
    /// @param newGovernance ICoFiXGovernance implementation contract address
    function update(address newGovernance) public override {
        super.update(newGovernance);
        _cofixRouter = ICoFiXGovernance(newGovernance).getCoFiXRouterAddress();
    }

    modifier onlyRouter() {
        require(msg.sender == _cofixRouter, "CoFiXPair: Only for CoFiXRouter");
        _;
    }

    /// @dev Modify configuration
    /// @param config Configuration object
    function setConfig(Config calldata config) external override onlyGovernance {
        _config = config;
    }

    /// @dev Get configuration
    /// @return Configuration object
    function getConfig() external view override returns (Config memory) {
        return _config;
    }

    /// @dev 初始化出矿权重
    /// @param xtokens 份额代币地址数组
    /// @param weights 出矿权重数组
    function batchSetPoolWeight(address[] calldata xtokens, uint[] calldata weights) external override onlyGovernance {
        uint cnt = xtokens.length;
        require(cnt == weights.length, "CoFiXVaultForStaking: mismatch len");
        for (uint i = 0; i < cnt; ++i) {
            require(xtokens[i] != address(0), "CoFiXVaultForStaking: invalid xtoken");
            _channels[xtokens[i]].cofiWeight = weights[i];
        }
    }

    /// @dev 初始化锁仓参数
    /// @param xtoken 目标份额代币地址（或CNode地址）
    /// @param cofiWeight CoFi出矿速度权重
    function initStakingChannel(address xtoken, uint cofiWeight) external override {
        StakeChannel storage channel = _channels[xtoken];
        channel.cofiWeight = cofiWeight;
    }

    /// @dev 获取目标地址锁仓的数量
    /// @param xtoken 目标份额代币地址（或CNode地址）
    /// @param addr 目标地址
    /// @return 目标地址锁仓的数量
    function balanceOf(address xtoken, address addr) external view override returns (uint) {
        return uint(_channels[xtoken].accounts[addr].balance);
    }

    /// @dev 获取目标地址在指定交易对锁仓上待领取的CoFi数量
    /// @param xtoken 目标份额代币地址（或CNode地址）
    /// @param addr 目标地址
    /// @return 目标地址在指定交易对锁仓上待领取的CoFi数量
    function earned(address xtoken, address addr) public view override returns (uint) {
        // 加载锁仓通道
        StakeChannel storage channel = _channels[xtoken];
        // 调用_calcReward()计算单位token分红
        uint newReward = _calcReward(channel);
        
        // 加载用户账号
        Account memory account = channel.accounts[addr];
        // 计算分红数据
        uint balance = uint(account.balance);
        // 加载锁仓总量
        uint totalStaked = channel.totalStaked;
        if (xtoken == CNODE_TOKEN_ADDRESS) {
            // 获取对应轨道的交易出矿量累计分成
            // 本次新增分成 = 累计分成 - 上次记录的分成
            newReward += ICoFiXRouter(_cofixRouter).getTradeReward(xtoken) - uint(channel.tradeReward);
            // 由于CNode没有小数位数，为了统一精度，在计算CNode单位token分红的时候，将数量乘以 1 ether
            balance *= 1 ether;
            totalStaked *= 1 ether;
        }

        // 计算单位token分红
        uint rewardPerToken = uint(channel.rewardPerToken);
        if (totalStaked > 0) {
            rewardPerToken += newReward * 1 ether / totalStaked;
        }
        
        // earned = (单位token分红 - 上次已经结算的单位token分红) * token数量
        return (rewardPerToken - uint(account.rewardCursor)) * balance / 1 ether;
    }

    /// @dev 此接口仅共CoFiXRouter调用，来存入做市份额
    /// @param xtoken 目标份额代币地址（或CNode地址）
    /// @param to 存入的目标地址
    /// @param amount 存入数量
    function routerStake(address xtoken, address to, uint amount) external override onlyRouter {
        // 加载锁仓通道
        StakeChannel storage channel = _channels[xtoken];
        // 结算用户分红
        Account memory account = _getReward(xtoken, channel, to);

        // 更新总锁仓量
        channel.totalStaked += amount;

        // 更新用户锁仓量
        account.balance = uint128(uint(account.balance) + amount);
        channel.accounts[to] = account;
    }

    /// @dev 存入做市份额
    /// @param xtoken 目标份额代币地址（或CNode地址）
    /// @param amount 存入数量
    function stake(address xtoken, uint amount) external override {
        // 加载锁仓通道
        StakeChannel storage channel = _channels[xtoken];
        // 结算用户分红
        Account memory account = _getReward(xtoken, channel, msg.sender);

        // 转入份额
        TransferHelper.safeTransferFrom(xtoken, msg.sender, address(this), amount);
        // 更新总锁仓量
        channel.totalStaked += amount;

        // 更新用户锁仓量
        account.balance = uint128(uint(account.balance) + amount);
        channel.accounts[msg.sender] = account;
    }

    /// @dev 取回做市份额，并领取CoFi
    /// @param xtoken 目标份额代币地址（或CNode地址）
    /// @param amount 取回数量
    function withdraw(address xtoken, uint amount) external override {
        // 加载锁仓通道
        StakeChannel storage channel = _channels[xtoken];
        // 结算用户分红
        Account memory account = _getReward(xtoken, channel, msg.sender);

        // 更新总锁仓量
        channel.totalStaked -= amount;
        // 更新用户锁仓量
        account.balance = uint128(uint(account.balance) - amount);
        channel.accounts[msg.sender] = account;

        // 将份额转给用户
        TransferHelper.safeTransfer(xtoken, msg.sender, amount);
    }

    /// @dev 领取CoFi
    /// @param xtoken 目标份额代币地址（或CNode地址）
    function getReward(address xtoken) external override {
        StakeChannel storage channel = _channels[xtoken];
        channel.accounts[msg.sender] = _getReward(xtoken, channel, msg.sender);
    }

    // 计算并领取分红
    function _getReward(
        address xtoken, 
        StakeChannel storage channel, 
        address to
    ) private returns (Account memory account) {
        // 加载账号
        account = channel.accounts[to];
        // 更新全局分红信息，并获得新的单位token分红量
        uint rewardPerToken = _updatReward(xtoken, channel);
        
        // 计算用户分红
        uint balance = uint(account.balance);
        if (xtoken == CNODE_TOKEN_ADDRESS) {
            balance *= 1 ether;
        }
        uint reward = (rewardPerToken - uint(account.rewardCursor)) * balance / 1 ether;
        
        // 更新用户分红标记
        account.rewardCursor = uint128(rewardPerToken);
        //channel.accounts[to] = account;

        // 将CoFi转给用户
        if (reward > 0) {
            CoFiToken(COFI_TOKEN_ADDRESS).mint(to, reward);
        }
    }

    // 更新全局分红信息，并返回新的单位token分红量
    function _updatReward(address xtoken, StakeChannel storage channel) private returns (uint rewardPerToken) {
        // 调用_calcReward()计算单位token分红
        uint newReward = _calcReward(channel);

        // 加载锁仓总量
        uint totalStaked = channel.totalStaked;
        if (xtoken == CNODE_TOKEN_ADDRESS) {
            // 获取对应轨道的交易出矿量累计分成
            uint tradeReward = ICoFiXRouter(_cofixRouter).getTradeReward(xtoken);
            // 本次新增分成 = 累计分成 - 上次记录的分成
            newReward += tradeReward - uint(channel.tradeReward);
            // 更新交易分成
            channel.tradeReward = uint128(tradeReward);
            // 由于CNode没有小数位数，为了统一精度，在计算CNode单位token分红的时候，将数量乘以 1 ether
            totalStaked *= 1 ether;
        }
        
        // 计算单位token分红
        rewardPerToken = uint(channel.rewardPerToken);
        if (totalStaked > 0) {
            rewardPerToken += newReward * 1 ether / totalStaked;
        }

        // 更新单位份额的分红值
        channel.rewardPerToken = uint96(rewardPerToken);
        // 更新已经结算的区块
        channel.blockCursor = uint32(block.number);
    }

    // 计算新增分红
    function _calcReward(StakeChannel storage channel
        //, uint totalStaked, uint newTradeReward
    ) internal view returns (
        uint newReward//, uint rewardPerToken
    ) {
        //rewardPerToken = uint(channel.rewardPerToken);
        // 重新计算总分红数量
        newReward =
            // 区块出矿量
            (block.number - uint(channel.blockCursor)) 
            * _redution(block.number - COFI_GENESIS_BLOCK) 
            * uint(_config.cofiRate) 
            * channel.cofiWeight
            / 400 / TOTAL_COFI_WEIGHT;
    }

    /// @dev 计算分红状态
    /// @param xtoken 目标份额代币地址（或CNode地址）
    /// @return newReward 自从上次结算依赖新增的量
    /// @return rewardPerToken 新的单位token可分红的数量
    function calcReward(address xtoken) public view returns (
        uint newReward, 
        uint rewardPerToken
    ) {
        // 加载锁仓通道
        StakeChannel storage channel = _channels[xtoken];
        // 调用_calcReward()计算单位token分红
        newReward = _calcReward(channel);

        // 加载锁仓总量
        uint totalStaked = channel.totalStaked;
        if (xtoken == CNODE_TOKEN_ADDRESS) {
            // 获取对应轨道的交易出矿量累计分成
            // 本次新增分成 = 累计分成 - 上次记录的分成
            newReward += ICoFiXRouter(_cofixRouter).getTradeReward(xtoken) - uint(channel.tradeReward);
            totalStaked *= 1 ether;
        }

        // 计算单位token分红
        rewardPerToken = uint(channel.rewardPerToken);
        if (totalStaked > 0) {
            rewardPerToken += newReward * 1 ether / totalStaked;
        }
    }

    // CoFi ore drawing attenuation interval. 2400000 blocks, about one year
    uint constant COFI_REDUCTION_SPAN = 2400000;
    // The decay limit of CoFi ore drawing becomes stable after exceeding this interval. 24 million blocks, about 4 years
    uint constant COFI_REDUCTION_LIMIT = 9600000; // COFI_REDUCTION_SPAN * 4;
    // Attenuation gradient array, each attenuation step value occupies 16 bits. The attenuation value is an integer
    uint constant COFI_REDUCTION_STEPS = 0x280035004300530068008300A300CC010001400190;
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
        
        if (delta < COFI_REDUCTION_LIMIT) {
            return (COFI_REDUCTION_STEPS >> ((delta / COFI_REDUCTION_SPAN) << 4)) & 0xFFFF;
        }
        return (COFI_REDUCTION_STEPS >> 64) & 0xFFFF;
    }
}
