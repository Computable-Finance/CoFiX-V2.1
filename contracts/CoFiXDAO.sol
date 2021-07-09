// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./libs/TransferHelper.sol";

import "./interfaces/ICoFiXDAO.sol";
import "./interfaces/ICoFiXController.sol";

import "./CoFiXBase.sol";
import "./CoFiToken.sol";

import "hardhat/console.sol";

/// @dev CoFiX公共资金的管理
contract CoFiXDAO is CoFiXBase, ICoFiXDAO {

    /// @dev 锚定币兑换的价格转换信息
    struct TokenPriceExchange {
        address target;
        uint96 exchange;
    }

    // Configuration
    Config _config;

    address _cofixController;

    // Redeem quota consumed
    // block.number * quotaPerBlock - quota
    uint _redeemed;

    // DAO applications
    mapping(address=>uint) _applications;

    // token和锚定币兑换的价格转换信息
    mapping(address=>TokenPriceExchange) _tokenExchanges;

    /// @dev Create CoFiXDAO
    constructor() {
    }

    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(newGovernance) when overriding, and override method without onlyGovernance
    /// @param newGovernance ICoFiXGovernance implementation contract address
    function update(address newGovernance) public override {
        super.update(newGovernance);
        _cofixController = ICoFiXGovernance(newGovernance).getCoFiXControllerAddress();
    }

    /// @dev Modify configuration
    /// @param config Configuration object
    function setConfig(Config memory config) external override onlyGovernance {
        _config = config;
    }

    /// @dev Get configuration
    /// @return Configuration object
    function getConfig() external view override returns (Config memory) {
        return _config;
    }

    /// @dev Set DAO application
    /// @param addr DAO application contract address
    /// @param flag Authorization flag, 1 means authorization, 0 means cancel authorization
    function setApplication(address addr, uint flag) external override onlyGovernance {
        _applications[addr] = flag;
        emit ApplicationChanged(addr, flag);
    }

    /// @dev Check DAO application flag
    /// @param addr DAO application contract address
    /// @return Authorization flag, 1 means authorization, 0 means cancel authorization
    function checkApplication(address addr) external view override returns (uint) {
        return _applications[addr];
    }

    /// @dev 设置token和锚定目标币价格的兑换关系。
    /// 例如，设置DAI锚定USDT，由于DAI是18位小数，USDT是6位小数，因此exchange = 1e6 * 1 ether / 1e18 = 1e6
    /// @param token 目标token
    /// @param target 目标锚定币
    /// @param exchange token和锚定目标币价格的兑换比例
    function setTokenExchange(address token, address target, uint exchange) external override {
        require(exchange <= 0xFFFFFFFFFFFFFFFFFFFFFFFF, "CoFiXDAO: exchange value overflow");
        _tokenExchanges[token] = TokenPriceExchange(target, uint96(exchange));
    }

    /// @dev 获取token和锚定目标币价格的兑换关系。
    /// 例如，设置DAI锚定USDT，由于DAI是18位小数，USDT是6位小数，因此exchange = 1e6 * 1 ether / 1e18 = 1e6
    /// @param token 目标token
    /// @return target 目标锚定币
    /// @return exchange token和锚定目标币价格的兑换比例
    function getTokenExchange(address token) external view override returns (address target, uint exchange) {
        TokenPriceExchange memory e = _tokenExchanges[token];
        return (e.target, uint(e.exchange));
    }

    /// @dev Add reward
    /// @param pool Destination pool
    function addETHReward(address pool) external payable override {
        //require(pool != address(0));
    }

    /// @dev The function returns eth rewards of specified ntoken
    /// @param pool Destination pool
    function totalETHRewards(address pool) external view override returns (uint) {
        //require(pool != address(0));
        return address(this).balance;
    }

    // /// @dev Pay
    // /// @param pool Destination pool. Indicates which ntoken to pay with
    // /// @param tokenAddress Token address of receiving funds (0 means ETH)
    // /// @param to Address to receive
    // /// @param value Amount to receive
    // function pay(address pool, address tokenAddress, address to, uint value) external override {
    //     //require(pool != address(0));
    //     require(_applications[msg.sender] == 1, "CoFiXDAO:!app");

    //     // Pay eth from ledger
    //     if (tokenAddress == address(0)) {
    //         // pay
    //         payable(to).transfer(value);
    //     }
    //     // Pay token
    //     else {
    //         // pay
    //         TransferHelper.safeTransfer(tokenAddress, to, value);
    //     }
    // }

    /// @dev Settlement
    /// @param pool Destination pool. Indicates which ntoken to pay with
    /// @param tokenAddress Token address of receiving funds (0 means ETH)
    /// @param to Address to receive
    /// @param value Amount to receive
    function settle(address pool, address tokenAddress, address to, uint value) external payable override {
        //require(pool != address(0));
        require(_applications[msg.sender] == 1, "CoFiXDAO:!app");

        // Pay eth from ledger
        if (tokenAddress == address(0)) {
            // pay
            payable(to).transfer(value);
        }
        // Pay token
        else {
            // pay
            TransferHelper.safeTransfer(tokenAddress, to, value);
        }
    }

    /// @dev Redeem CoFi for ethers
    /// @notice Ethfee will be charged
    /// @param amount The amount of ntoken
    /// @param payback As the charging fee may change, it is suggested that the caller pay more fees, and the excess fees will be returned through this address
    function redeem(uint amount, address payback) external payable override {
        
        // 1. Load configuration
        Config memory config = _config;

        // 2. Check redeeming stat
        require(uint(config.status) == 1, "CoFiXDAO: Repurchase status error");

        // 3. Query price
        // (
        //     ,//uint blockNumber, 
        //     uint priceEthAmount,
        //     uint priceTokenAmount,
        //     uint avgPriceEthAmount,
        //     uint avgPriceTokenAmount,
        //     //uint sigmaSQ
        // ) = ICoFiXController(_cofixController).latestPriceInfo {
        //     value: msg.value
        // } (COFI_TOKEN_ADDRESS, payback);
        // priceTokenAmount = priceTokenAmount * 1 ether / priceEthAmount;
        // avgPriceTokenAmount = avgPriceTokenAmount * 1 ether / avgPriceEthAmount;

        (
            uint priceTokenAmount, 
            uint avgPriceTokenAmount
        ) = _queryPrice(_cofixController, COFI_TOKEN_ADDRESS, msg.value, payback);

        // TODO: 检查价格偏差
        // 4. Check the redeeming amount and price deviation
        require(
            priceTokenAmount * 10000 <= avgPriceTokenAmount * (10000 + uint(config.priceDeviationLimit)) && 
            priceTokenAmount * 10000 >= avgPriceTokenAmount * (10000 - uint(config.priceDeviationLimit)), 
            "CoFiXDAO:!price"
        );

        // 5. Calculate the number of eth that can be exchanged for redeem
        uint value = amount * 1 ether / priceTokenAmount;

        // 6. Calculate redeem quota
        (uint quota, uint scale) = _quotaOf(config, _redeemed);
        _redeemed = scale - (quota - amount);

        // 7. 转入CoFi并转出eth
        TransferHelper.safeTransferFrom(COFI_TOKEN_ADDRESS, msg.sender, address(this), amount);
        payable(msg.sender).transfer(value);
    }

    /// @dev Redeem CoFi for Token
    /// @notice Ethfee will be charged
    /// @param token The target token
    /// @param amount The amount of ntoken
    /// @param payback As the charging fee may change, it is suggested that the caller pay more fees, and the excess fees will be returned through this address
    function redeemToken(address token, uint amount, address payback) external payable override {
        
        // 1. Load configuration
        Config memory config = _config;

        // 2. Check redeeming stat
        require(uint(config.status) == 1, "CoFiXDAO: Repurchase status error");

        TokenPriceExchange memory exchange = _tokenExchanges[token];
        require(exchange.exchange > 0, "CoFiXDAO: Token not allowed");

        // eth的价格是1:1
        uint fee = msg.value;
        uint tokenPriceTokenAmount = 1 ether;
        uint tokenAvgPriceTokenAmount = 1 ether;
        address cofixController = _cofixController;
        if (exchange.target != address(0)) {
            (
                tokenPriceTokenAmount, 
                tokenAvgPriceTokenAmount
            ) = _queryPrice(cofixController, exchange.target, fee >> 1, payback);
            fee = fee >> 1;
        }
        tokenPriceTokenAmount = tokenPriceTokenAmount * 1 ether / uint(exchange.exchange);
        tokenAvgPriceTokenAmount = tokenAvgPriceTokenAmount * 1 ether / uint(exchange.exchange);
        (
            uint cofiPriceTokenAmount, 
            uint cofiAvgPriceTokenAmount
        ) = _queryPrice(cofixController, COFI_TOKEN_ADDRESS, fee, payback);

        // TODO: 检查价格偏差
        // 4. Check the redeeming amount and price deviation
        require(
            cofiPriceTokenAmount * tokenAvgPriceTokenAmount * 10000 
                <= cofiAvgPriceTokenAmount * tokenPriceTokenAmount * (10000 + uint(config.priceDeviationLimit)) && 
            cofiPriceTokenAmount * tokenAvgPriceTokenAmount * 10000 
                >= cofiAvgPriceTokenAmount * tokenPriceTokenAmount * (10000 - uint(config.priceDeviationLimit)), 
            "CoFiXDAO:!price"
        );

        // 6. Calculate redeem quota
        {
            (uint quota, uint scale) = _quotaOf(config, _redeemed);
            _redeemed = scale - (quota - amount);
        }

        // 5. Calculate the number of eth that can be exchanged for redeem
        uint value = amount * tokenPriceTokenAmount / cofiPriceTokenAmount;

        // 7. 转入CoFi并转出etoken
        TransferHelper.safeTransferFrom(COFI_TOKEN_ADDRESS, msg.sender, address(this), amount);
        TransferHelper.safeTransfer(token, msg.sender, value);
    }

    // 查询价格并按照标准价格返回（相对于1 ether的价格）
    function _queryPrice(
        address cofixController, 
        address tokenAddress, 
        uint fee, 
        address payback
    ) private returns (
        uint price,
        uint avgPrice
    ) {
        (
            ,//uint blockNumber, 
            uint priceEthAmount,
            uint priceTokenAmount,
            uint avgPriceEthAmount,
            uint avgPriceTokenAmount,
            //uint sigmaSQ
        ) = ICoFiXController(cofixController).latestPriceInfo {
            value: fee
        } (tokenAddress, payback);

        price = priceTokenAmount * 1 ether / priceEthAmount;
        avgPrice = avgPriceTokenAmount * 1 ether / avgPriceEthAmount;
    }

    /// @dev Get the current amount available for repurchase
    function quotaOf() public view override returns (uint) {

        // 1. Load configuration
        Config memory config = _config;

        // 2. Check redeem state
        if (uint(config.status) != 1) {
            return 0;
        }

        // 3. Calculate redeem quota
        (uint quota, ) = _quotaOf(config, _redeemed);
        return quota;
    }

    // Calculate redeem quota
    function _quotaOf(Config memory config, uint redeemed) private view returns (uint quota, uint scale) {
        // Load cofiLimit
        uint quotaLimit = uint(config.cofiLimit) * 1 ether;
        // Calculate
        scale = block.number * uint(config.cofiPerBlock) * 1 ether;
        quota = scale - redeemed;
        if (quota > quotaLimit) {
            quota = quotaLimit;
        }
    }
}
