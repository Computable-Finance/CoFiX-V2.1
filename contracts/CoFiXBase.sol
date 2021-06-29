// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "./libs/IERC20.sol";
import "./libs/TransferHelper.sol";

import "./interfaces/ICoFiXDAO.sol";
import "./interfaces/ICoFiXGovernance.sol";
import "hardhat/console.sol";

// Router contract to interact with each CoFiXPair, no owner or governance
/// @dev Base contract of CoFiX
contract CoFiXBase {

    // // Address of CoFiToken contract
    // address constant COFI_TOKEN_ADDRESS = 0x1a23a6BfBAdB59fa563008c0fB7cf96dfCF34Ea1;
    address COFI_TOKEN_ADDRESS;

    // // Address of CoFiNode contract
    // address constant CNODE_TOKEN_ADDRESS = 0x558201DC4741efc11031Cdc3BC1bC728C23bF512
    address CNODE_TOKEN_ADDRESS;

    // Genesis block number of CoFi
    // CoFiToken contract is created at block height 11040156. However, because the mining algorithm of CoFiX1.0
    // is different from that at present, a new mining algorithm is adopted from CoFiX2.1. The new algorithm
    // includes the attenuation logic according to the block. Therefore, it is necessary to trace the block
    // where the CoFi begins to decay. According to the circulation when CoFi2.0 is online, the new mining
    // algorithm is used to deduce and convert the CoFi, and the new algorithm is used to mine the CoFiX2.1
    // on-line flow, the actual block is 5120000
    // TODO: 确定CoFi创世区块号
    uint constant COFI_GENESIS_BLOCK = 0;

    /// @dev To support open-zeppelin/upgrades
    /// @param governance INestGovernance implementation contract address
    function initialize(address governance) virtual public {
        require(_governance == address(0), 'NEST:!initialize');
        _governance = governance;
    }

    /// @dev INestGovernance implementation contract address
    address public _governance;

    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(nestGovernanceAddress) when overriding, and override method without onlyGovernance
    /// @param newGovernance INestGovernance implementation contract address
    function update(address newGovernance) public virtual {

        address governance = _governance;
        require(governance == msg.sender || ICoFiXGovernance(governance).checkGovernance(msg.sender, 0), "NEST:!gov");
        _governance = newGovernance;
        (
            COFI_TOKEN_ADDRESS,
            CNODE_TOKEN_ADDRESS,
            ,//address cofixDAO,
            ,//address cofixRouter,
            ,//address cofixController,
            //address cofixVaultForStaking
        ) = ICoFiXGovernance(newGovernance).getBuiltinAddress();
    }

    /// @dev Migrate funds from current contract to NestLedger
    /// @param tokenAddress Destination token address.(0 means eth)
    /// @param value Migrate amount
    function migrate(address tokenAddress, uint value) external onlyGovernance {

        address to = ICoFiXGovernance(_governance).getCoFiXDAOAddress();
        if (tokenAddress == address(0)) {
            ICoFiXDAO(to).addETHReward { value: value } (address(0));
        } else {
            TransferHelper.safeTransfer(tokenAddress, to, value);
        }
    }

    //---------modifier------------

    modifier onlyGovernance() {
        require(ICoFiXGovernance(_governance).checkGovernance(msg.sender, 0), "NEST:!gov");
        _;
    }

    modifier noContract() {
        require(msg.sender == tx.origin, "NEST:!contract");
        _;
    }
}
