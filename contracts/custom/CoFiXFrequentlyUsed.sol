// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "../CoFiXBase.sol";

/// @dev Base contract of Hedge
contract CoFiXFrequentlyUsed is CoFiXBase {

    // Address of NestPriceFacade contract
    address constant NEST_BATCH_PRICE = 0x09CE0e021195BA2c1CDE62A8B187abf810951540;
}
