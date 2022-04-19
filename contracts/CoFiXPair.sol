// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./libs/TransferHelper.sol";

import "./interfaces/ICoFiXPair.sol";
import "./interfaces/ICoFiXController.sol";
import "./interfaces/ICoFiXDAO.sol";

import "./CoFiXBase.sol";
import "./CoFiToken.sol";
import "./CoFiXERC20.sol";

/// @dev Binary pool: eth/token
contract CoFiXPair is CoFiXBase, CoFiXERC20, ICoFiXPair {

    /* ******************************************************************************************
     * Note: In order to unify the authorization entry, all transferFrom operations are carried
     * out in the CoFiXRouter, and the CoFiXPool needs to be fixed, CoFiXRouter does trust and 
     * needs to be taken into account when calculating the pool balance before and after rollover
     * ******************************************************************************************/

    // it's negligible because we calc liquidity in ETH
    uint constant MINIMUM_LIQUIDITY = 1e9; 

    // Target token address
    address _tokenAddress; 
    // Initial asset ratio - eth
    uint48 _initToken0Amount;
    // Initial asset ratio - token
    uint48 _initToken1Amount;

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
    // Impact cost threshold
    uint96 _impactCostVOL;

    // Total mined
    uint112 _Y;
    // Adjusting to a balanced trade size
    uint112 _D;
    // Last update block
    uint32 _lastblock;

    // Constructor, in order to support openzeppelin's scalable scheme, 
    // it's need to move the constructor to the initialize method
    constructor() {
    }

    /// @dev init Initialize
    /// @param governance ICoFiXGovernance implementation contract address
    /// @param name_ Name of xtoken
    /// @param symbol_ Symbol of xtoken
    /// @param tokenAddress Target token address
    /// @param initToken0Amount Initial asset ratio - eth
    /// @param initToken1Amount Initial asset ratio - token
    function init(
        address governance,
        string calldata name_, 
        string calldata symbol_, 
        address tokenAddress, 
        uint48 initToken0Amount, 
        uint48 initToken1Amount
    ) external {
        super.initialize(governance);
        name = name_;
        symbol = symbol_;
        _tokenAddress = tokenAddress;
        _initToken0Amount = initToken0Amount;
        _initToken1Amount = initToken1Amount;
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
    /// @param impactCostVOL Impact cost threshold
    /// @param nt Each unit token (in the case of binary pools, eth) is used for the standard ore output, 1e18 based
    function setConfig(uint16 theta, uint96 impactCostVOL, uint96 nt) external override onlyGovernance {
        // Trade fee rate, ten thousand points system. 20
        _theta = theta;
        // Impact cost threshold
        _impactCostVOL = impactCostVOL;
        // Each unit token (in the case of binary pools, eth) is used for the standard ore output, 1e18 based
        _nt = nt;
    }

    /// @dev Get configuration
    /// @return theta Trade fee rate, ten thousand points system. 20
    /// @return impactCostVOL Impact cost threshold
    /// @return nt Each unit token (in the case of binary pools, eth) is used for the standard ore output, 1e18 based
    function getConfig() external view override returns (uint16 theta, uint96 impactCostVOL, uint96 nt) {
        return (_theta, _impactCostVOL, _nt);
    }

    /// @dev Get initial asset ratio
    /// @return initToken0Amount Initial asset ratio - eth
    /// @return initToken1Amount Initial asset ratio - token
    function getInitialAssetRatio() external view override returns (
        uint initToken0Amount, 
        uint initToken1Amount
    ) {
        return (uint(_initToken0Amount), uint(_initToken1Amount));
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
        // Make sure the proportions are correct
        uint initToken0Amount = uint(_initToken0Amount);
        uint initToken1Amount = uint(_initToken1Amount);
        require(amountETH * initToken1Amount == amountToken * initToken0Amount, "CoFiXPair: invalid asset ratio");

        // 2. Calculate net worth and share
        uint total = totalSupply;
        if (total > 0) {
            // 3. Query oracle
            (
                ,//uint blockNumber, 
                uint ethAmount,
                uint tokenAmount,
                ,//uint avgPriceEthAmount,
                ,//uint avgPriceTokenAmount,
                //uint sigmaSQ
            ) = ICoFiXController(_cofixController).latestPriceInfo { 
                value: msg.value - amountETH
            } (
                token,
                payback
            );

            uint balance0 = ethBalance();
            uint balance1 = IERC20(token).balanceOf(address(this));

            // There are no cost shocks to market making
            // When the circulation is not zero, the normal issue share
            liquidity = amountETH * total / _calcTotalValue(
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
                tokenAmount,
                initToken0Amount,
                initToken1Amount
            );

            // 6. Update mining state
            _updateMiningState(balance0, balance1, ethAmount, tokenAmount);
        } else {
            payable(payback).transfer(msg.value - amountETH);
            liquidity = amountETH - MINIMUM_LIQUIDITY;
            // permanently lock the first MINIMUM_LIQUIDITY tokens
            _mint(address(0), MINIMUM_LIQUIDITY); 
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
        // 1. Check token address
        require(token == _tokenAddress, "CoFiXPair: invalid token address");
        // 2. Query oracle
        (
            ,//uint blockNumber, 
            uint ethAmount,
            uint tokenAmount,
            ,//uint avgPriceEthAmount,
            ,//uint avgPriceTokenAmount,
            //uint sigmaSQ
        ) = ICoFiXController(_cofixController).latestPriceInfo { 
            value: msg.value 
        } (
            token,
            payback
        );

        // 3. Calculate the net value and calculate the equal proportion fund according to the net value
        uint balance0 = ethBalance();
        uint balance1 = IERC20(token).balanceOf(address(this));
        uint navps = 1 ether;
        uint total = totalSupply;
        uint initToken0Amount = uint(_initToken0Amount);
        uint initToken1Amount = uint(_initToken1Amount);
        if (total > 0) {
            navps = _calcTotalValue(
                balance0, 
                balance1, 
                ethAmount, 
                tokenAmount,
                initToken0Amount,
                initToken1Amount
            ) * 1 ether / total;
        }

        amountETHOut = navps * liquidity / 1 ether;
        amountTokenOut = amountETHOut * initToken1Amount / initToken0Amount;

        // 4. Adjust according to the surplus of the fund pool
        // If the number of eth to be retrieved exceeds the balance of the fund pool, 
        // it will be automatically converted into a token
        if (amountETHOut > balance0) {
            amountTokenOut += (amountETHOut - balance0) * tokenAmount / ethAmount;
            amountETHOut = balance0;
        } 
        // If the number of tokens to be retrieved exceeds the balance of the fund pool, 
        // it will be automatically converted to eth
        else if (amountTokenOut > balance1) {
            amountETHOut += (amountTokenOut - balance1) * ethAmount / tokenAmount;
            amountTokenOut = balance1;
        }
        
        // 5. Destroy xtoken
        _burn(address(this), liquidity);
        //emit Burn(token, to, liquidity, amountETHOut, amountTokenOut);

        // 6. Mining logic
        _updateMiningState(balance0 - amountETHOut, balance1 - amountTokenOut, ethAmount, tokenAmount);

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

        // 4. Mining logic
        mined = _cofiMint(_calcD(
            address(this).balance - fee, 
            IERC20(token).balanceOf(address(this)) - amountTokenOut, 
            ethAmount, 
            tokenAmount
        ), uint(_nt));
        
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

        // 4. Mining logic
        mined = _cofiMint(_calcD(
            address(this).balance - fee - amountETHOut, 
            IERC20(token).balanceOf(address(this)), 
            ethAmount, 
            tokenAmount
        ), uint(_nt));

        // 5. Transfer token
        payable(to).transfer(amountETHOut);

        emit SwapForETH(amountIn, to, amountETHOut, mined);
    }

    // Update mining state
    function _updateMiningState(uint balance0, uint balance1, uint ethAmount, uint tokenAmount) private {
        uint D1 = _calcD(
            balance0, //ethBalance(), 
            balance1, //IERC20(token).balanceOf(address(this)), 
            ethAmount, 
            tokenAmount
        );

        uint D0 = uint(_D);
        // When d0 < D1, the y value also needs to be updated
        uint Y = uint(_Y) + D0 * uint(_nt) * (block.number - uint(_lastblock)) / 1 ether;

        _Y = uint112(Y);
        _D = uint112(D1);
        _lastblock = uint32(block.number);
    }

    // Calculate the ETH transaction size required to adjust to k0
    function _calcD(
        uint balance0, 
        uint balance1, 
        uint ethAmount, 
        uint tokenAmount
    ) private view returns (uint) {
        uint initToken0Amount = uint(_initToken0Amount);
        uint initToken1Amount = uint(_initToken1Amount);

        // D_t=|(E_t *k_0 -U_t)/(k_0+P_t )|
        uint left = balance0 * initToken1Amount;
        uint right = balance1 * initToken0Amount;
        uint numerator;
        if (left > right) {
            numerator = left - right;
        } else {
            numerator = right - left;
        }
        
        return numerator * ethAmount / (
            ethAmount * initToken1Amount + tokenAmount * initToken0Amount
        );
    }

    // Calculate CoFi transaction mining related variables and update the corresponding status
    function _cofiMint(uint D1, uint nt) private returns (uint mined) {
        // Y_t=Y_(t-1)+D_(t-1)*n_t*(S_t+1)-Z_t                   
        // Z_t=[Y_(t-1)+D_(t-1)*n_t*(S_t+1)]* v_t
        uint D0 = uint(_D);
        // When d0 < D1, the y value also needs to be updated
        uint Y = uint(_Y) + D0 * nt * (block.number - uint(_lastblock)) / 1 ether;
        if (D0 > D1) {
            mined = Y * (D0 - D1) / D0;
            Y = Y - mined;
        }

        _Y = uint112(Y);
        _D = uint112(D1);
        _lastblock = uint32(block.number);
    }

    /// @dev Estimate mining amount
    /// @param newBalance0 New balance of eth
    /// @param newBalance1 New balance of token
    /// @param ethAmount Oracle price - eth amount
    /// @param tokenAmount Oracle price - token amount
    /// @return mined The amount of CoFi which will be mind by this trade
    function estimate(
        uint newBalance0, 
        uint newBalance1, 
        uint ethAmount, 
        uint tokenAmount
    ) external view override returns (uint mined) {
        uint D1 = _calcD(newBalance0, newBalance1, ethAmount, tokenAmount);
        // Y_t=Y_(t-1)+D_(t-1)*n_t*(S_t+1)-Z_t                   
        // Z_t=[Y_(t-1)+D_(t-1)*n_t*(S_t+1)]* v_t
        uint D0 = uint(_D);
        if (D0 > D1) {
            // When d0 < D1, the y value also needs to be updated
            uint Y = uint(_Y) + D0 * uint(_nt) * (block.number - uint(_lastblock)) / 1 ether;
            mined = Y * (D0 - D1) / D0;
        }
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
        uint total = totalSupply;
        navps = total > 0 ? _calcTotalValue(
            ethBalance(), 
            IERC20(_tokenAddress).balanceOf(address(this)), 
            ethAmount, 
            tokenAmount,
            _initToken0Amount,
            _initToken1Amount
        ) * 1 ether / total : 1 ether;
    }

    // Calculate the total value of asset balance
    function _calcTotalValue(
        uint balance0, 
        uint balance1, 
        uint ethAmount, 
        uint tokenAmount,
        uint initToken0Amount,
        uint initToken1Amount
    ) private pure returns (uint totalValue) {
        // NV=(E_t+U_t/P_t)/((1+k_0/P_t ))
        totalValue = (
            balance0 * tokenAmount 
            + balance1 * ethAmount
        ) * initToken0Amount / (
            initToken0Amount * tokenAmount 
            + initToken1Amount * ethAmount
        );
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
