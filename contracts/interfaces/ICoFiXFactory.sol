// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

/// @dev Router contract to interact with each CoFiXPair, no owner or governance
interface ICoFiXFactory {
    // All pairs: {ETH <-> ERC20 Token}
    event PairCreated(address indexed token, address pair, uint);
    event NewGovernance(address _new);
    event NewController(address _new);
    event NewFeeReceiver(address _new);
    event NewFeeVaultForLP(address token, address feeVault);
    event NewVaultForLP(address _new);
    event NewVaultForTrader(address _new);
    event NewVaultForCNode(address _new);
    event NewDAO(address _new);

    /// @dev Create a new token pair for trading
    /// @param  token the address of token to trade
    /// @param  initToken0Amount the initial asset ratio (initToken0Amount:initToken1Amount)
    /// @param  initToken1Amount the initial asset ratio (initToken0Amount:initToken1Amount)
    /// @return pair the address of new token pair
    function createPair(
        address token,
	    uint initToken0Amount,
        uint initToken1Amount
        )
        external
        returns (address pair);

    function getPair(address token) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function getTradeMiningStatus(address token) external view returns (bool status);
    function setTradeMiningStatus(address token, bool status) external;
    function getFeeVaultForLP(address token) external view returns (address feeVault); // for LPs
    function setFeeVaultForLP(address token, address feeVault) external;

    function setGovernance(address _new) external;
    function setController(address _new) external;
    function setFeeReceiver(address _new) external;
    function setVaultForLP(address _new) external;
    function setVaultForTrader(address _new) external;
    function setVaultForCNode(address _new) external;
    function setDAO(address _new) external;
    function getController() external view returns (address controller);
    function getFeeReceiver() external view returns (address feeReceiver); // For CoFi Holders
    function getVaultForLP() external view returns (address vaultForStaking);
    function getVaultForTrader() external view returns (address vaultForTrader);
    function getVaultForCNode() external view returns (address vaultForCNode);
    function getDAO() external view returns (address dao);
}
