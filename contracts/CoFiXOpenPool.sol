// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./libs/TransferHelper.sol";

import "./interfaces/ICoFiXSinglePool.sol";
import "./interfaces/ICoFiXController.sol";
import "./interfaces/INestOpenPrice.sol";
import "./interfaces/ICoFiXDAO.sol";

import "./CoFiXBase.sol";
import "./CoFiToken.sol";
import "./CoFiXERC20.sol";

/// @dev 开放式资金池，使用NEST4.0价格
contract CoFiXOpenPool is CoFiXBase, CoFiXERC20, ICoFiXSinglePool {

    /* ******************************************************************************************
     * Note: In order to unify the authorization entry, all transferFrom operations are carried
     * out in the CoFiXRouter, and the CoFiXPool needs to be fixed, CoFiXRouter does trust and 
     * needs to be taken into account when calculating the pool balance before and after rollover
     * ******************************************************************************************/

    uint constant BLOCK_TIME = 14;

    // Address of NestPriceFacade contract
    //address constant NEST_PRICE_FACADE = 0xB5D2890c061c321A5B6A4a4254bb1522425BAF0A;
    address NEST_PRICE_FACADE;

    // it's negligible because we calc liquidity in ETH
    uint constant MINIMUM_LIQUIDITY = 1e9; 

    // Target token address
    address _tokenAddress; 
    // Trade fee rate, ten thousand points system. 20
    uint16 _theta;
    // Trade fee rate for dao, ten thousand points system. 20
    uint16 _theta0;

    // ERC20 - name
    string public name;
    
    // ERC20 - symbol
    string public symbol;

    // Address of CoFiXDAO
    address _cofixDAO;

    // Address of CoFiXRouter
    address _cofixRouter;
    // Lock flag
    bool _locked;
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

    // USDT代币的基数
    uint constant USDT_BASE = 1 ether;

    // ETH/USDT报价通道id
    uint constant ETH_USDT_CHANNEL_ID = 0;

    uint constant TRANSFER_RATE = 0;

    function _toUSDTPrice(uint rawPrice) private pure returns (uint) {
        return 2000 ether * 1 ether / rawPrice;
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
    /// @param theta0 Trade fee rate for dao, ten thousand points system. 20
    /// @param impactCostVOL 将impactCostVOL参数的意义做出调整，表示冲击成本倍数
    function setConfig(uint16 theta, uint16 theta0, uint96 impactCostVOL) external override onlyGovernance {
        // Trade fee rate, ten thousand points system. 20
        _theta = theta;
        // Trade fee rate for dao, ten thousand points system. 20
        _theta0 = theta0;
        // 将impactCostVOL参数的意义做出调整，表示冲击成本倍数
        _impactCostVOL = impactCostVOL;
    }

    /// @dev Get configuration
    /// @return theta Trade fee rate, ten thousand points system. 20
    /// @return theta0 Trade fee rate for dao, ten thousand points system. 20
    /// @return impactCostVOL 将impactCostVOL参数的意义做出调整，表示冲击成本倍数
    function getConfig() external view override returns (uint16 theta, uint16 theta0, uint96 impactCostVOL) {
        return (_theta, _theta0, _impactCostVOL);
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
        ) = _queryOracle(
            token,
            msg.value - amountETH,
            payback
        );
        tokenAmount = tokenAmount * (1 ether + k) / 1 ether;
        
        liquidity = amountETH + amountToken * ethAmount / tokenAmount;
        if (total > 0) {
            uint balance0 = ethBalance();
            uint balance1 = IERC20(token).balanceOf(address(this));
            
            liquidity = liquidity * total / _calcTotalValue(
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
                tokenAmount
            );
        } else {
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
        ) = _queryOracle(
            token,
            msg.value  - amountIn,
            payback
        );

        // 2. Calculate the trade result
        uint theta = uint(_theta);
        uint fee = amountIn * theta / 10000;
        amountTokenOut = (amountIn - fee) * tokenAmount * 1 ether / ethAmount / (
            1 ether + k + impactCostForSellOutETH(amountIn)
        );

        // 3. Transfer transaction fee
        fee = _collect(fee * uint(_theta0) / theta);

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
        ) = _queryOracle(
            token,
            msg.value,
            payback
        );

        // 2. Calculate the trade result
        amountETHOut = amountIn * ethAmount / tokenAmount;
        amountETHOut = amountETHOut * 1 ether / (
            1 ether + k + impactCostForBuyInETH(amountETHOut)
        ); 

        uint theta = uint(_theta);
        uint fee = amountETHOut * theta / 10000;
        amountETHOut = amountETHOut - fee;

        // 3. Transfer transaction fee
        fee = _collect(fee * uint(_theta0) / theta);

        // 5. Transfer token
        payable(to).transfer(amountETHOut);

        emit SwapForETH(amountIn, to, amountETHOut, mined);
    }

    // Deposit transaction fee
    function _collect(uint fee) private returns (uint total) {
        // 佣金的1/3进入DAO，2/3留在资金池
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
        totalValue = balance0 + balance1 * ethAmount / tokenAmount;
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

    /// @dev Calc variance of price and K in CoFiX is very expensive
    /// We use expected value of K based on statistical calculations here to save gas
    /// In the near future, NEST could provide the variance of price directly. We will adopt it then.
    /// We can make use of `data` bytes in the future
    /// @param tokenAddress Target address of token
    /// @param payback As the charging fee may change, it is suggested that the caller pay more fees, 
    /// and the excess fees will be returned through this address
    /// @return k The K value(18 decimal places).
    /// @return ethAmount Oracle price - eth amount
    /// @return tokenAmount Oracle price - token amount
    /// @return blockNumber Block number of price
    function _queryOracle(
        address tokenAddress,
        uint fee,
        address payback
    ) private returns (
        uint k, 
        uint ethAmount, 
        uint tokenAmount, 
        uint blockNumber
    ) {
        (
            uint[] memory prices,
            ,//uint triggeredPriceBlockNumber,
            ,//uint triggeredPriceValue,
            uint triggeredAvgPrice,
            uint triggeredSigmaSQ
        ) = INestOpenPrice(NEST_PRICE_FACADE).lastPriceListAndTriggeredPriceInfo {
            value: fee  
        } (ETH_USDT_CHANNEL_ID, 2, payback);

        prices[1] = _toUSDTPrice(prices[1]);
        prices[3] = _toUSDTPrice(prices[3]);
        tokenAmount = prices[1];
        _checkPrice(tokenAmount, triggeredAvgPrice);
        blockNumber = prices[0];
        ethAmount = 1 ether;

        k = calcRevisedK(triggeredSigmaSQ, prices[3], prices[2], tokenAmount, blockNumber);
    }

    /// @dev K value is calculated by revised volatility
    /// @param p0 Last price (number of tokens equivalent to 1 ETH)
    /// @param bn0 Block number of the last price
    /// @param p Latest price (number of tokens equivalent to 1 ETH)
    /// @param bn The block number when (ETH, TOKEN) price takes into effective
    function calcRevisedK(uint SIGMA_SQ, uint p0, uint bn0, uint p, uint bn) public view returns (uint k) {
        // TODO: SIGMA_SQ取值问题
        uint sigmaISQ = p * 1 ether / p0;
        if (sigmaISQ > 1 ether) {
            sigmaISQ -= 1 ether;
        } else {
            sigmaISQ = 1 ether - sigmaISQ;
        }
        sigmaISQ = sigmaISQ * sigmaISQ / (bn - bn0) / BLOCK_TIME / 1 ether;

        if (sigmaISQ > SIGMA_SQ) {
            k = _sqrt(0.002 ether * 0.002 ether * sigmaISQ / SIGMA_SQ) + 
                _sqrt(1 ether * BLOCK_TIME * (block.number - bn) * sigmaISQ);
        } else {
            k = 0.002 ether + _sqrt(1 ether * BLOCK_TIME * SIGMA_SQ * (block.number - bn));
        }
    }

    function _sqrt(uint256 x) private pure returns (uint256) {
        unchecked {
            if (x == 0) return 0;
            else {
                uint256 xx = x;
                uint256 r = 1;
                if (xx >= 0x100000000000000000000000000000000) { xx >>= 128; r <<= 64; }
                if (xx >= 0x10000000000000000) { xx >>= 64; r <<= 32; }
                if (xx >= 0x100000000) { xx >>= 32; r <<= 16; }
                if (xx >= 0x10000) { xx >>= 16; r <<= 8; }
                if (xx >= 0x100) { xx >>= 8; r <<= 4; }
                if (xx >= 0x10) { xx >>= 4; r <<= 2; }
                if (xx >= 0x8) { r <<= 1; }
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1; // Seven iterations should be enough
                uint256 r1 = x / r;
                return (r < r1 ? r : r1);
            }
        }
    }

    // Check price
    function _checkPrice(uint price, uint avgPrice) private pure {
        require(
            price <= avgPrice * 11 / 10 &&
            price >= avgPrice * 9 / 10, 
            "CoFiXController: price deviation"
        );
    }
}
