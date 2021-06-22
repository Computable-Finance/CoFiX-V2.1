// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "./libs/IERC20.sol";
import "./libs/TransferHelper.sol";

import "./interfaces/ICoFiXDAO.sol";
import "./interfaces/ICoFiXController.sol";
import "./CoFiXBase.sol";
import "./CoFiToken.sol";
import "hardhat/console.sol";

/// @dev CoFiX公共资金的管理
contract CoFiXDAO is CoFiXBase, ICoFiXDAO {

    // Address of CoFiToken
    address immutable COFI_TOKEN_ADDRESS;

    // Configuration
    Config _config;

    address _cofixController;

    // Redeem quota consumed
    // block.number * quotaPerBlock - quota
    uint _redeemed;

    // DAO applications
    mapping(address=>uint) _applications;

    /// @dev Create CoFiXDAO
    /// @param cofiToken CoFi TOKEN
    constructor(address cofiToken) {
        COFI_TOKEN_ADDRESS = cofiToken;
    }

    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(nestGovernanceAddress) when overriding, and override method without onlyGovernance
    /// @param newGovernance INestGovernance implementation contract address
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

    /// @dev Carve reward
    /// @param pair Destination pair
    function carveETHReward(address pair) external payable override {

    }

    /// @dev Add reward
    /// @param pair Destination pair
    function addETHReward(address pair) external payable override {
        require(pair != address(0));
    }

    /// @dev The function returns eth rewards of specified ntoken
    /// @param pair Destination pair
    function totalETHRewards(address pair) external view override returns (uint) {
        require(pair != address(0));
        return address(this).balance;
    }

    /// @dev Pay
    /// @param pair Destination pair. Indicates which ntoken to pay with
    /// @param tokenAddress Token address of receiving funds (0 means ETH)
    /// @param to Address to receive
    /// @param value Amount to receive
    function pay(address pair, address tokenAddress, address to, uint value) external override {
        require(pair != address(0));
        require(_applications[msg.sender] == 1, "NestLedger:!app");

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

    /// @dev Settlement
    /// @param pair Destination pair. Indicates which ntoken to pay with
    /// @param tokenAddress Token address of receiving funds (0 means ETH)
    /// @param to Address to receive
    /// @param value Amount to receive
    function settle(address pair, address tokenAddress, address to, uint value) external payable override {
        require(pair != address(0));
        require(_applications[msg.sender] == 1, "NestLedger:!app");

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
        require(uint(config.RepurchaseStatus) == 1, "CoFiXDAO: Repurchase status error");

        // 3. Query price
        (
            /* uint latestPriceBlockNumber */, 
            uint latestPriceValue,
            /* uint triggeredPriceBlockNumber */,
            /* uint triggeredPriceValue */,
            uint triggeredAvgPrice,
            /* uint triggeredSigma */
        ) = ICoFiXController(_cofixController).latestPriceAndTriggeredPriceInfo {
            value: msg.value
        } (COFI_TOKEN_ADDRESS, payback);

        // 4. Calculate the number of eth that can be exchanged for redeem
        uint value = amount * 1 ether / latestPriceValue;

        // 5. Calculate redeem quota
        (uint quota, uint scale) = _quotaOf(config, _redeemed);
        _redeemed = scale - (quota - amount);

        // TODO: 检查价格偏差
        // 6. Check the redeeming amount and price deviation
        require(
            latestPriceValue * 10000 <= triggeredAvgPrice * (10000 + uint(config.priceDeviationLimit)) && 
            latestPriceValue * 10000 >= triggeredAvgPrice * (10000 - uint(config.priceDeviationLimit)), 
            "CoFiXDAO:!price"
        );

        payable(msg.sender).transfer(value);
    }

    /// @dev Get the current amount available for repurchase
    function quotaOf() public view override returns (uint) {

        // 1. Load configuration
        Config memory config = _config;

        // 2. Check redeem state
        if (uint(config.RepurchaseStatus) != 1) {
            return 0;
        }

        // 3. Calculate redeem quota
        (uint quota, ) = _quotaOf(config, _redeemed);
        return quota;
    }

    // Calculate redeem quota
    function _quotaOf(Config memory config, uint redeemed) private view returns (uint quota, uint scale) {
        // Load cofiLimit
        uint quotaLimit = uint(config.cofiLimit);
        // Calculate
        scale = block.number * uint(config.cofiPerBlock) * 1 ether;
        quota = scale - redeemed;
        if (quota > quotaLimit * 1 ether) {
            quota = quotaLimit * 1 ether;
        }
    }
}
