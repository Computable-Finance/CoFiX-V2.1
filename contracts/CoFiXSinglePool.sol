// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./libs/TransferHelper.sol";

import "./interfaces/ICoFiXSinglePool.sol";
import "./interfaces/ICoFiXController.sol";
import "./interfaces/ICoFiXDAO.sol";

import "./CoFiXBase.sol";
import "./CoFiToken.sol";
import "./CoFiXERC20.sol";

/// @dev 单边池
contract CoFiXSinglePool is CoFiXBase, CoFiXERC20, ICoFiXSinglePool {

    /* ******************************************************************************************
     * Note: In order to unify the authorization entry, all transferFrom operations are carried
     * out in the CoFiXRouter, and the CoFiXPool needs to be fixed, CoFiXRouter does trust and 
     * needs to be taken into account when calculating the pool balance before and after rollover
     * ******************************************************************************************/

    // it's negligible because we calc liquidity in ETH
    uint constant MINIMUM_LIQUIDITY = 1e9; 

    // Target token address
    address _tokenAddress; 

    // ERC20 - name
    string public name;
    
    // ERC20 - symbol
    string public symbol;

    // Address of CoFiXDAO
    address _cofixDAO;
    // Each unit token (in the case of binary pools, eth) is used for the standard ore output, 1e18 based
    uint96 _nt;

    // Address of CoFiXRouter
    address _cofixRouter;
    // Lock flag
    bool _locked;
    // Trade fee rate, ten thousand points system. 20
    uint16 _theta;
    // Total trade fee
    uint72 _totalFee;

    // Address of CoFiXController
    address _cofixController;
    // Impact cost threshold, this parameter is obsolete
    // 将_impactCostVOL参数的意义做出调整，表示冲击成本倍数
    // 冲击成本计算公式：vol * uint(_impactCostVOL) * 0.00001
    uint96 _impactCostVOL;

    // Constructor, in order to support openzeppelin's scalable scheme, 
    // it's need to move the constructor to the initialize method
    constructor() {
    }

    /// @dev init Initialize
    /// @param governance ICoFiXGovernance implementation contract address
    /// @param name_ Name of xtoken
    /// @param symbol_ Symbol of xtoken
    /// @param tokenAddress Target token address
    function init(
        address governance,
        string calldata name_, 
        string calldata symbol_, 
        address tokenAddress
    ) external {
        super.initialize(governance);
        name = name_;
        symbol = symbol_;
        _tokenAddress = tokenAddress;
    }

    modifier check() {
        require(_cofixRouter == msg.sender, "CoFiXPair: Only for CoFiXRouter");
        require(!_locked, "CoFiXPair: LOCKED");
        _locked = true;
        _;
        _locked = false;
    }

    /// @dev Set configuration
    /// @param theta Trade fee rate, ten thousand points system. 20
    /// @param impactCostVOL 将impactCostVOL参数的意义做出调整，表示冲击成本倍数
    /// @param nt Each unit token (in the case of binary pools, eth) is used for the standard ore output, 1e18 based
    function setConfig(uint16 theta, uint96 impactCostVOL, uint96 nt) external override onlyGovernance {
        // Trade fee rate, ten thousand points system. 20
        _theta = theta;
        // 将impactCostVOL参数的意义做出调整，表示冲击成本倍数
        _impactCostVOL = impactCostVOL;
        // Each unit token (in the case of binary pools, eth) is used for the standard ore output, 1e18 based
        _nt = nt;
    }

    /// @dev Get configuration
    /// @return theta Trade fee rate, ten thousand points system. 20
    /// @return impactCostVOL 将impactCostVOL参数的意义做出调整，表示冲击成本倍数
    /// @return nt Each unit token (in the case of binary pools, eth) is used for the standard ore output, 1e18 based
    function getConfig() external view override returns (uint16 theta, uint96 impactCostVOL, uint96 nt) {
        return (_theta, _impactCostVOL, _nt);
    }

    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(newGovernance) when overriding, and override method without onlyGovernance
    /// @param newGovernance ICoFiXGovernance implementation contract address
    function update(address newGovernance) public override {
        super.update(newGovernance);
        (
            ,//cofiToken,
            ,//cofiNode,
            _cofixDAO,
            _cofixRouter,
            _cofixController,
            //cofixVaultForStaking
        ) = ICoFiXGovernance(newGovernance).getBuiltinAddress();
    }

    /// @dev Add liquidity and mint xtoken
    /// @param token Target token address
    /// @param to The address to receive xtoken
    /// @param amountETH The amount of ETH added to pool. (When pool is AnchorPool, amountETH is 0)
    /// @param amountToken The amount of Token added to pool
    /// @param payback As the charging fee may change, it is suggested that the caller pay more fees, 
    /// and the excess fees will be returned through this address
    /// @return xtoken The liquidity share token address obtained
    /// @return liquidity The real liquidity or XToken minted from pool
    function mint(
        address token,
        address to,
        uint amountETH, 
        uint amountToken,
        address payback
    ) external payable override check returns (
        address xtoken,
        uint liquidity
    ) {
        // 1. Check token address
        require(token == _tokenAddress, "CoFiXPair: invalid token address");

        // 2. Calculate net worth and share
        uint total = totalSupply;
        // 3. Query oracle
        (
            uint k, 
            uint ethAmount, 
            uint tokenAmount, 
            //uint blockNumber, 
        ) = ICoFiXController(_cofixController).queryOracle { 
            value: msg.value  - amountETH
        } (
            token,
            payback
        );
            
        uint balance0 = ethBalance();
        uint balance1 = IERC20(token).balanceOf(address(this));
            
        uint totalValue = _calcTotalValue(
            // To calculate the net value, we need to use the asset balance before the market making fund 
            // is transferred. Since the ETH was transferred when CoFiXRouter called this method and the 
            // Token was transferred before CoFiXRouter called this method, we need to deduct the amountETH 
            // and amountToken respectively

            // The current eth balance minus the amount eth equals the ETH balance before the transaction
            balance0 - amountETH, 
            //The current token balance minus the amountToken equals to the token balance before the transaction
            balance1 - amountToken,
            // Oracle price - eth amount
            ethAmount, 
            // Oracle price - token amount
            tokenAmount * 1 ether / (1 ether + k)
        );

        liquidity = (amountETH + amountToken * ethAmount * 1 ether / tokenAmount / (1 ether + k)) * 1 ether / totalValue;

        if (total == 0) {
            _mint(address(0), MINIMUM_LIQUIDITY); 
            liquidity -= MINIMUM_LIQUIDITY;
        }

        // 5. Increase xtoken
        _mint(to, liquidity);
        //emit Mint(token, to, amountETH, amountToken, liquidity);

        xtoken = address(this);
    }

    /// @dev Maker remove liquidity from pool to get ERC20 Token and ETH back (maker burn XToken) 
    /// @param token The address of ERC20 Token
    /// @param to The target address receiving the Token
    /// @param liquidity The amount of liquidity (XToken) sent to pool, or the liquidity to remove
    /// @param payback As the charging fee may change, it is suggested that the caller pay more fees, 
    /// and the excess fees will be returned through this address
    /// @return amountETHOut The real amount of ETH transferred from the pool
    /// @return amountTokenOut The real amount of Token transferred from the pool
    function burn(
        address token,
        address to, 
        uint liquidity, 
        address payback
    ) external payable override check returns (
        uint amountETHOut,
        uint amountTokenOut 
    ) { 
        if(msg.value > 0) {
            payable(payback).transfer(msg.value);
        }

        // 1. Check token address
        require(token == _tokenAddress, "CoFiXPair: invalid token address");
        
        // 3. Calculate the net value and calculate the equal proportion fund according to the net value
        uint balance0 = ethBalance();
        uint balance1 = IERC20(token).balanceOf(address(this));
        uint total = totalSupply;

        amountETHOut = balance0 * liquidity / total;
        amountTokenOut = balance1 * liquidity / total;

        // 5. Destroy xtoken
        _burn(address(this), liquidity);
        //emit Burn(token, to, liquidity, amountETHOut, amountTokenOut);

        // 7. Transfer of funds to the user's designated address
        payable(to).transfer(amountETHOut);
        TransferHelper.safeTransfer(token, to, amountTokenOut);
    }

    /// @dev Swap token
    /// @param src Src token address
    /// @param dest Dest token address
    /// @param amountIn The exact amount of Token a trader want to swap into pool
    /// @param to The target address receiving the ETH
    /// @param payback As the charging fee may change, it is suggested that the caller pay more fees, 
    /// and the excess fees will be returned through this address
    /// @return amountOut The real amount of ETH transferred out of pool
    /// @return mined The amount of CoFi which will be mind by this trade
    function swap(
        address src, 
        address dest, 
        uint amountIn, 
        address to, 
        address payback
    ) external payable override check returns (
        uint amountOut, 
        uint mined
    ) {
        address token = _tokenAddress;
        if (src == address(0) && dest == token) {
            (amountOut, mined) =  _swapForToken(token, amountIn, to, payback);
        } else if (src == token && dest == address(0)) {
            (amountOut, mined) = _swapForETH(token, amountIn, to, payback);
        } else {
            revert("CoFiXPair: pair error");
        }
    }

    /// @dev Swap for tokens
    /// @param amountIn The exact amount of Token a trader want to swap into pool
    /// @param to The target address receiving the ETH
    /// @param payback As the charging fee may change, it is suggested that the caller pay more fees, 
    /// and the excess fees will be returned through this address
    /// @return amountTokenOut The real amount of token transferred out of pool
    /// @return mined The amount of CoFi which will be mind by this trade
    function _swapForToken(
        address token,
        uint amountIn, 
        address to, 
        address payback
    ) private returns (
        uint amountTokenOut, 
        uint mined
    ) {
        // 1. Query oracle
        (
            uint k, 
            uint ethAmount, 
            uint tokenAmount, 
            //uint blockNumber, 
        ) = ICoFiXController(_cofixController).queryOracle { 
            value: msg.value  - amountIn
        } (
            token,
            payback
        );

        // 2. Calculate the trade result
        uint fee = amountIn * uint(_theta) / 10000;
        amountTokenOut = (amountIn - fee) * tokenAmount * 1 ether / ethAmount / (
            1 ether + k + impactCostForSellOutETH(amountIn)
        );

        // 3. Transfer transaction fee
        fee = _collect(fee);

        // 5. Transfer token
        TransferHelper.safeTransfer(token, to, amountTokenOut);

        emit SwapForToken(amountIn, to, amountTokenOut, mined);
    }

    /// @dev Swap for eth
    /// @param amountIn The exact amount of Token a trader want to swap into pool
    /// @param to The target address receiving the ETH
    /// @param payback As the charging fee may change, it is suggested that the caller pay more fees, 
    /// and the excess fees will be returned through this address
    /// @return amountETHOut The real amount of eth transferred out of pool
    /// @return mined The amount of CoFi which will be mind by this trade
    function _swapForETH(
        address token,
        uint amountIn, 
        address to, 
        address payback
    ) private returns (
        uint amountETHOut, 
        uint mined
    ) {
        // 1. Query oracle
        (
            uint k, 
            uint ethAmount, 
            uint tokenAmount, 
            //uint blockNumber, 
        ) = ICoFiXController(_cofixController).queryOracle { 
            value: msg.value
        } (
            token,
            payback
        );

        // 2. Calculate the trade result
        amountETHOut = amountIn * ethAmount / tokenAmount;
        amountETHOut = amountETHOut * 1 ether / (
            1 ether + k + impactCostForBuyInETH(amountETHOut)
        ); 

        uint fee = amountETHOut * uint(_theta) / 10000;
        amountETHOut = amountETHOut - fee;

        // 3. Transfer transaction fee
        fee = _collect(fee);

        // 5. Transfer token
        payable(to).transfer(amountETHOut);

        emit SwapForETH(amountIn, to, amountETHOut, mined);
    }

    // Deposit transaction fee
    function _collect(uint fee) private returns (uint total) {
        total = uint(_totalFee) + fee;
        if (total >= 1 ether) {
            ICoFiXDAO(_cofixDAO).addETHReward { value: total } (address(this));
            total = 0;
        } 
        _totalFee = uint72(total);
    }

    /// @dev Settle trade fee to DAO
    function settle() external override {
        ICoFiXDAO(_cofixDAO).addETHReward { value: uint(_totalFee) } (address(this));
        _totalFee = uint72(0);
    }

    /// @dev Get eth balance of this pool
    /// @return eth balance of this pool
    function ethBalance() public view override returns (uint) {
        return address(this).balance - uint(_totalFee);
    }

    /// @dev Get total trade fee which not settled
    function totalFee() external view override returns (uint) {
        return uint(_totalFee);
    }

    /// @dev Get net worth
    /// @param ethAmount Oracle price - eth amount
    /// @param tokenAmount Oracle price - token amount
    /// @return navps Net worth
    function getNAVPerShare(
        uint ethAmount, 
        uint tokenAmount
    ) external view override returns (uint navps) {
        // 做市: Np = (Au * (1 + K) / P + Ae) / S
        uint total = totalSupply;
        navps = total > 0 ? _calcTotalValue(
            ethBalance(), 
            IERC20(_tokenAddress).balanceOf(address(this)), 
            ethAmount, 
            tokenAmount
        ) * 1 ether / total : 1 ether;
    }

    // Calculate the total value of asset balance
    function _calcTotalValue(
        uint balance0, 
        uint balance1, 
        uint ethAmount, 
        uint tokenAmount
    ) private pure returns (uint totalValue) {
        totalValue = balance0 * tokenAmount + balance1 * ethAmount;
    }

    /// @dev Calculate the impact cost of buy in eth
    /// @param vol Trade amount in eth
    /// @return impactCost Impact cost
    function impactCostForBuyInETH(uint vol) public view override returns (uint impactCost) {
        //return _impactCostForBuyInETH(vol, uint(_impactCostVOL));
        impactCost = vol * uint(_impactCostVOL) / 100000;
    }

    /// @dev Calculate the impact cost of sell out eth
    /// @param vol Trade amount in eth
    /// @return impactCost Impact cost
    function impactCostForSellOutETH(uint vol) public view override returns (uint impactCost) {
        //return _impactCostForSellOutETH(vol, uint(_impactCostVOL));
        impactCost = vol * uint(_impactCostVOL) / 100000;
    }

    /// @dev Gets the token address of the share obtained by the specified token market making
    /// @param token Target token address
    /// @return If the fund pool supports the specified token, return the token address of the market share
    function getXToken(address token) external view override returns (address) {
        if (token == _tokenAddress) {
            return address(this);
        }
        return address(0);
    }
}
