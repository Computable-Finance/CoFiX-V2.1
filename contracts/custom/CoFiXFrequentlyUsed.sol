// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "../CoFiXBase.sol";

// /// @dev This contract include frequently used data
// contract CoFiXFrequentlyUsed is CoFiXBase {

//     // Address of INestBatchPrice2 implementation contract
//     address constant NEST_BATCH_PRICE = 0x09CE0e021195BA2c1CDE62A8B187abf810951540;
// }

// TODO: Use constant version
/// @dev Base contract of Hedge
contract CoFiXFrequentlyUsed is CoFiXBase {

    // Address of NestPriceFacade contract
    address NEST_BATCH_PRICE;

    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(newGovernance) when overriding, and override method without onlyGovernance
    /// @param newGovernance IHedgeGovernance implementation contract address
    function update(address newGovernance) public virtual override {

        super.update(newGovernance);
    }

    function setNestOpenPrice(address nestOpenPrice) external {
        NEST_BATCH_PRICE = nestOpenPrice;
    }
}