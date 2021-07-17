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

import "hardhat/console.sol";

/// @dev Binary pool: eth/token
contract CoFiXPair is CoFiXBase, CoFiXERC20, ICoFiXPair {

    /* ******************************************************************************************
     * Note: In order to unify the authorization entry, all transferFrom operations are carried
     * out in the CofixRouter, and the CofixPool needs to be fixed, CofixRouter does trust and 
     * needs to be taken into account when calculating the pool balance before and after rollover
     * ******************************************************************************************/

    // it's negligible because we calc liquidity in ETH
    uint constant MINIMUM_LIQUIDITY = 1e9; 

    // Scale of impact cost base
    uint constant VOL_BASE = 50 ether;

    // α=0
    uint constant C_BUYIN_ALPHA = 0; 

    // β=2e-05*1e18
    uint constant C_BUYIN_BETA = 20000000000000; 

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

    // Address of CoFiXRouter
    address _cofixRouter;

    // Trade fee rate, ten thousand points system. 20
    uint16 _theta;
    
    // Impact cost coefficient
    uint16 _gamma;

    // Each unit token (in the case of binary pools, eth) is used for the standard ore output, 
    // in ten thousand points. 1000
    uint32 _nt;

    // Lock flag
    uint8 _locked;

    // Address of CoFiXController
    address _cofixController;

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
        //_locked = 0;
        _tokenAddress = tokenAddress;
        _initToken0Amount = initToken0Amount;
        _initToken1Amount = initToken1Amount;
    }

    modifier check() {
        require(_cofixRouter == msg.sender, "CoFiXPair: Only for CoFiXRouter");
        require(_locked == 0, "CoFiXPair: LOCKED");
        _locked = 1;
        _;
        _locked = 0;
        //_update();
    }

    /// @dev Set configuration
    /// @param theta Trade fee rate, ten thousand points system. 20
    /// @param gamma Impact cost coefficient
    /// @param nt Each unit token (in the case of binary pools, eth) is used for the standard ore output, 
    /// in ten thousand points. 1000
    function setConfig(uint16 theta, uint16 gamma, uint32 nt) external override onlyGovernance {
        // Trade fee rate, ten thousand points system. 20
        _theta = theta;
        // Impact cost coefficient
        _gamma = gamma;
        // Each unit token (in the case of binary pools, eth) is used for the standard ore output, 
        // in ten thousand points. 1000
        _nt = nt;
    }

    /// @dev Get configuration
    /// @return theta Trade fee rate, ten thousand points system. 20
    /// @return gamma Impact cost coefficient
    /// @return nt Each unit token (in the case of binary pools, eth) is used for the standard ore output, 
    /// in ten thousand points. 1000
    function getConfig() external override view returns (uint16 theta, uint16 gamma, uint32 nt) {
        return (_theta, _gamma, _nt);
    }

    /// @dev Get initial asset ratio
    /// @return initToken0Amount Initial asset ratio - eth
    /// @return initToken1Amount Initial asset ratio - token
    function getInitialAssetRatio() public override view returns (
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
        require(
            amountETH * uint(_initToken1Amount) == amountToken * uint(_initToken0Amount), 
            "CoFiXPair: invalid asset ratio"
        );

        // 2. Calculate net worth and share
        uint total = totalSupply;
        if (total > 0) {
            // 3. Query oracle
            (
                uint ethAmount, 
                uint tokenAmount, 
                //uint blockNumber, 
            ) = ICoFiXController(_cofixController).queryPrice { 
                // Any amount over the amountETH will be charged as the seer call fee
                value: msg.value - amountETH
            } (
                token,
                payback
            );

            // TODO: Pt此处没有引入K值，后续需要引入
            // There are no cost shocks to market making
            // When the circulation is not zero, the normal issue share
            liquidity = amountETH * total / _calcTotalValue(
                // To calculate the net value, we need to use the asset balance before the market making fund 
                // is transferred. Since the ETH was transferred when CofixRouter called this method and the 
                // Token was transferred before CofixRouter called this method, we need to deduct the amountETH 
                // and amountToken respectively

                // The current eth balance minus the amount eth equals the ETH balance before the transaction
                address(this).balance - amountETH, 
                //The current token balance minus the amounttoken equals to the token balance before the transaction
                IERC20(token).balanceOf(address(this)) - amountToken,
                // Oracle price - eth amount
                ethAmount, 
                // Oracle price - token amount
                tokenAmount,
                uint(_initToken0Amount),
                uint(_initToken1Amount)
            );

            // 6. Mining logic
            _updateMintState(token, ethAmount, tokenAmount);
        } else {
            payable(payback).transfer(msg.value - amountETH);
            //liquidity = _calcLiquidity(amountETH, navps) - MINIMUM_LIQUIDITY;
            liquidity = amountETH - MINIMUM_LIQUIDITY;
            // permanently lock the first MINIMUM_LIQUIDITY tokens
            _mint(address(0), MINIMUM_LIQUIDITY); 
        }

        // 5. Increase xtoken
        _mint(to, liquidity);
        xtoken = address(this);
        emit Mint(token, to, amountETH, amountToken, liquidity);
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
            uint ethAmount, 
            uint tokenAmount, 
            //uint blockNumber, 
        ) = ICoFiXController(_cofixController).queryPrice { 
            value: msg.value 
        } (
            token,
            payback
        );

        // 3. Calculate the net value and calculate the equal proportion fund according to the net value
        uint ethBalance = address(this).balance;
        uint tokenBalance = IERC20(token).balanceOf(address(this));
        uint navps = 1 ether;
        uint total = totalSupply;
        uint initToken0Amount = uint(_initToken0Amount);
        uint initToken1Amount = uint(_initToken1Amount);
        if (total > 0) {
            // TODO: Pt此处没有引入K值，后续需要引入
            navps = _calcTotalValue(
                ethBalance, 
                tokenBalance, 
                ethAmount, 
                tokenAmount,
                initToken0Amount,
                initToken1Amount
            ) * 1 ether / total;
        }

        // TODO: 赎回时需要计算冲击成本
        // TODO: 确定赎回的时候是否有手续费逻辑
        amountETHOut = navps * liquidity / 1 ether;
        amountTokenOut = amountETHOut * initToken1Amount / initToken0Amount;

        // 4. Destroy xtoken
        _burn(address(this), liquidity);

        // 5. Adjust according to the surplus of the fund pool
        // If the number of eth to be retrieved exceeds the balance of the fund pool, 
        // it will be automatically converted into a token
        if (amountETHOut > ethBalance) {
            amountTokenOut += (amountETHOut - ethBalance) * tokenAmount / ethAmount;
            amountETHOut = ethBalance;
        } 
        // If the number of tokens to be retrieved exceeds the balance of the fund pool, 
        // it will be automatically converted to eth
        else if (amountTokenOut > tokenBalance) {
            amountETHOut += (amountTokenOut - tokenBalance) * ethAmount / tokenAmount;
            amountTokenOut = tokenBalance;
        }

        // 6. Transfer of funds to the user's designated address
        payable(to).transfer(amountETHOut);
        TransferHelper.safeTransfer(token, to, amountTokenOut);

        emit Burn(token, to, liquidity, amountETHOut, amountTokenOut);

        // 7. Mining logic
        _updateMintState(token, ethAmount, tokenAmount);
    }

    function _updateMintState(address token, uint ethAmount, uint tokenAmount) private {
        // Mining logic
        _cofiMint(_calcD(
            address(this).balance, 
            IERC20(token).balanceOf(address(this)), 
            ethAmount, 
            tokenAmount
        ), uint(_nt));
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

        // TODO: 公式需要确认
        // 2. Calculate the trade result
        uint fee = amountIn * uint(_theta) / 10000;
        amountTokenOut = (amountIn - fee) * tokenAmount * 1 ether / ethAmount / (
            1 ether + k + _impactCostForSellOutETH(amountIn, uint(_gamma))
        );

        // 3. Transfer transaction fee
        _collect(fee);

        // TODO: 如果不检查重入，可能存在通过重入来挖矿的行为
        // 4. Mining logic
        mined = _cofiMint(_calcD(
            address(this).balance, 
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
            1 ether + k + _impactCostForBuyInETH(amountETHOut, uint(_gamma))
        ); 

        uint fee = amountETHOut * uint(_theta) / 10000;
        amountETHOut = amountETHOut - fee;

        // 3. Transfer transaction fee
        _collect(fee);

        // 4. Mining logic
        mined = _cofiMint(_calcD(
            address(this).balance - amountETHOut, 
            IERC20(token).balanceOf(address(this)), 
            ethAmount, 
            tokenAmount
        ), uint(_nt));

        // 5. Transfer token
        payable(to).transfer(amountETHOut);

        emit SwapForETH(amountIn, to, amountETHOut, mined);
    }

    // Calculate the ETH transaction size required to adjust to 𝑘0
    function _calcD(
        uint balance0, 
        uint balance1, 
        uint ethAmount, 
        uint tokenAmount
    ) private view returns (uint) {
        uint initToken0Amount = uint(_initToken0Amount);
        uint initToken1Amount = uint(_initToken1Amount);

        // D_t=|(E_t 〖*k〗_0 〖-U〗_t)/(k_0+P_t )|
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
        // Z_t=〖[Y〗_(t-1)+D_(t-1)*n_t*(S_t+1)]* v_t
        uint D0 = uint(_D);
        // When d0 < D1, the y value also needs to be updated
        uint Y = uint(_Y) + D0 * nt * (block.number - uint(_lastblock)) / 10000;
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
        // Z_t=〖[Y〗_(t-1)+D_(t-1)*n_t*(S_t+1)]* v_t
        uint D0 = uint(_D);
        if (D0 > D1) {
            // When d0 < D1, the y value also needs to be updated
            uint Y = uint(_Y) + D0 * uint(_nt) * (block.number - uint(_lastblock)) / 10000;
            mined = Y * (D0 - D1) / D0;
        }
    }

    // Deposit transaction fee
    function _collect(uint fee) private {
        ICoFiXDAO(_cofixDAO).addETHReward { value: fee } (address(this));
    }

    // Calculate net worth
    // navps = calcNAVPerShare(reserve0, reserve1, _op.ethAmount, _op.tokenAmount);
    // calc Net Asset Value Per Share (no K)
    // use it in this contract, for optimized gas usage

    /// @dev Calculate net worth
    /// @param balance0 Balance of eth
    /// @param balance1 Balance of token
    /// @param ethAmount Oracle price - eth amount
    /// @param tokenAmount Oracle price - token amount
    /// @return navps Net worth
    function calcNAVPerShare(
        uint balance0, 
        uint balance1, 
        uint ethAmount, 
        uint tokenAmount
    ) external view override returns (uint navps) {
        uint total = totalSupply;
        if (total > 0) {
            return _calcTotalValue(
                balance0, 
                balance1, 
                ethAmount, 
                tokenAmount,
                _initToken0Amount,
                _initToken1Amount
            ) * 1 ether / totalSupply;
        }
        return 1 ether;
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
        if (total > 0) {
            return _calcTotalValue(
                address(this).balance, 
                IERC20(_tokenAddress).balanceOf(address(this)), 
                ethAmount, 
                tokenAmount,
                _initToken0Amount,
                _initToken1Amount
            ) * 1 ether / totalSupply;
        }
        return 1 ether;
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
        // k = Ut / Et
        // NV = (Et + Ut / Pt) / ( (1 + k0 / Pt) * Ft )
        // NV = (Et + Ut / Pt) / ( (1 + k0 / Pt) * Ft )
        // NV = (Et + Ut / Pt) / ( (1 + (U0 / Pt * E0)) * Ft )
        // NV = (Et * E0 + Ut * E0  / Pt) / ( (E0 + U0 / Pt) * Ft )
        //navps = (ethBalance * _initToken0Amount * tokenAmount + tokenBalance * _initToken0Amount * ethAmount) * 1 ether
        //        / totalSupply / (_initToken0Amount * tokenAmount + _initToken1Amount * ethAmount);

        // NV=(E_t+U_t/P_t)/((1+k_0/P_t ))
        totalValue = (
            balance0 * tokenAmount 
            + balance1 * ethAmount
        ) * initToken0Amount / (
            initToken0Amount * tokenAmount 
            + initToken1Amount * ethAmount
        );
    }

    // // impact cost
    // // - C = 0, if VOL < 500 / γ
    // // - C = (α + β * VOL) * γ, if VOL >= 500 / γ

    // α=0，β=2e-06
    function _impactCostForBuyInETH(uint vol, uint gamma) private pure returns (uint impactCost) {
        //uint gamma = uint(_gamma); //CGammaMap[token];
        if (vol * gamma < VOL_BASE) {
            return 0;
        }
        // return C_BUYIN_ALPHA.add(C_BUYIN_BETA.mul(vol).div(1e18)).mul(1e8).div(1e18);
        return (C_BUYIN_ALPHA + C_BUYIN_BETA * vol / 1 ether) * gamma; // combine mul div
    }

    // α=0，β=2e-06
    function _impactCostForSellOutETH(uint vol, uint gamma) private pure returns (uint impactCost) {
        //uint gamma = uint(_gamma); //CGammaMap[token];
        if (vol * gamma < VOL_BASE) {
            return 0;
        }
        // return C_BUYIN_ALPHA.add(C_BUYIN_BETA.mul(vol).div(1e18)).mul(1e8).div(1e18);
        return (C_BUYIN_ALPHA + C_BUYIN_BETA * vol / 1 ether) * gamma; // combine mul div
    }

    /// @dev Calculate the impact cost of buy in eth
    /// @param vol Trade amount in eth
    /// @return impactCost Impact cost
    function impactCostForBuyInETH(uint vol) external view override returns (uint impactCost) {
        return _impactCostForBuyInETH(vol, uint(_gamma));
    }

    /// @dev Calculate the impact cost of sell out eth
    /// @param vol Trade amount in eth
    /// @return impactCost Impact cost
    function impactCostForSellOutETH(uint vol) external view override returns (uint impactCost) {
        return _impactCostForSellOutETH(vol, uint(_gamma));
    }

    /// @dev Gets the token address of the share obtained by the specified token market making
    /// @param token Traget token address
    /// @return If the fund pool supports the specified token, return the token address of the market share
    function getXToken(address token) external view override returns (address) {
        if (token == _tokenAddress) {
            return address(this);
        }
        return address(0);
    }
}
