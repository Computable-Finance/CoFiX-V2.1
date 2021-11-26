// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./libs/TransferHelper.sol";

import "./interfaces/ICoFiXOpenPool.sol";
import "./interfaces/ICoFiXController.sol";
import "./interfaces/INestOpenPrice.sol";
import "./interfaces/ICoFiXDAO.sol";

import "./CoFiXBase.sol";
import "./CoFiToken.sol";
import "./CoFiXERC20.sol";

/// @dev 开放式资金池，使用NEST4.0价格
contract CoFiXOpenPool is CoFiXBase, CoFiXERC20, ICoFiXOpenPool {

    /* ******************************************************************************************
     * Note: In order to unify the authorization entry, all transferFrom operations are carried
     * out in the CoFiXRouter, and the CoFiXPool needs to be fixed, CoFiXRouter does trust and 
     * needs to be taken into account when calculating the pool balance before and after rollover
     * ******************************************************************************************/

    /*
    1. 如何共用做市接口：做市接口每次只能做一个币种，token0直接取得份额，token1需要根据价格转化为份额
    2. 份额如何计算：按照计价代币来算，一个单位的计价代币表示一个份额
    3. 兑换逻辑，价格如何转换和确定：
    4. CoFi需要跨上去吗?
    5. CoFiXDAO需要跨上去吗?
    */

    // 出块时间
    uint constant BLOCK_TIME = 3;

    // Address of NestPriceFacade contract
    address constant NEST_OPEN_PRICE = 0x09CE0e021195BA2c1CDE62A8B187abf810951540;

    // it's negligible because we calc liquidity in ETH
    uint constant MINIMUM_LIQUIDITY = 1e9; 

    // Target token address
    address _token0; 
    // Impact cost threshold, this parameter is obsolete
    // 将_impactCostVOL参数的意义做出调整，表示冲击成本倍数
    // 冲击成本计算公式：vol * uint(_impactCostVOL) * 0.00001
    uint96 _impactCostVOL;

    address _token1;
    // Trade fee rate, ten thousand points system. 20
    uint16 _theta;
    // Trade fee rate for dao, ten thousand points system. 20
    uint16 _theta0;
    // 报价通道编号
    uint32 _channelId;

    // ERC20 - name
    string public name;
    
    // ERC20 - symbol
    string public symbol;

    // Address of CoFiXDAO
    address _cofixDAO;
    // 常规波动率
    uint96 _sigmaSQ;

    // Address of CoFiXRouter
    address _cofixRouter;
    // Lock flag
    bool _locked;
    // Total trade fee
    uint72 _totalFee;

    // Address of CoFiXController
    //address _cofixController;

    // Constructor, in order to support openzeppelin's scalable scheme, 
    // it's need to move the constructor to the initialize method
    constructor() {
    }

    /// @dev init Initialize
    /// @param governance ICoFiXGovernance implementation contract address
    /// @param name_ Name of xtoken
    /// @param symbol_ Symbol of xtoken
    /// @param token0 代币地址1（不支持eth）
    /// @param token1 代币地址2（不支持eth）
    function init(
        address governance,
        string calldata name_, 
        string calldata symbol_, 
        address token0,
        address token1
    ) external {
        super.initialize(governance);
        name = name_;
        symbol = symbol_;
        _token0 = token0;
        _token1 = token1;
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
    /// @param sigmaSQ 常规波动率
    function setConfig(
        uint16 theta, 
        uint16 theta0, 
        uint96 impactCostVOL, 
        uint96 sigmaSQ
    ) external override onlyGovernance {
        // Trade fee rate, ten thousand points system. 20
        _theta = theta;
        // Trade fee rate for dao, ten thousand points system. 20
        _theta0 = theta0;
        // 将impactCostVOL参数的意义做出调整，表示冲击成本倍数
        _impactCostVOL = impactCostVOL;

        _sigmaSQ = sigmaSQ;
    }

    /// @dev Get configuration
    /// @return theta Trade fee rate, ten thousand points system. 20
    /// @return theta0 Trade fee rate for dao, ten thousand points system. 20
    /// @return impactCostVOL 将impactCostVOL参数的意义做出调整，表示冲击成本倍数
    /// @param sigmaSQ 常规波动率
    function getConfig() external view override returns (
        uint16 theta, 
        uint16 theta0, 
        uint96 impactCostVOL, 
        uint96 sigmaSQ
    ) {
        return (_theta, _theta0, _impactCostVOL, _sigmaSQ);
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
            ,//_cofixController,
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
        //require(token == _tokenAddress, "CoFiXPair: invalid token address");
        require(amountETH == 0, "COP:amountETH must be 0");
        
        // 3. Query oracle
        (
            uint k, 
            uint ethAmount, 
            uint tokenAmount, 
            //uint blockNumber, 
        ) = _queryOracle(
            uint(_channelId),
            msg.value,
            payback
        );
        tokenAmount = tokenAmount * (1 ether + k) / 1 ether;

        address token0 = _token0;
        address token1 = _token1;
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));

        // 代币0做市，份额直接换算
        if (token == token0) {
            liquidity = amountToken;
            balance0 -= amountToken;
        }
        // 代币1做市，需要调用预言机，进行价格转换计算
        else if(token == token1) {
            liquidity = amountToken * ethAmount / tokenAmount;
            balance1 -= amountToken;
        } 
        // 不支持的代币
        else {
            revert("COP:token not support");
        }
        
        // 2. Calculate net worth and share
        uint total = totalSupply;
        if (total > 0) {
            liquidity = liquidity * total / _calcTotalValue(
                // To calculate the net value, we need to use the asset balance before the market making fund 
                // is transferred. Since the ETH was transferred when CoFiXRouter called this method and the 
                // Token was transferred before CoFiXRouter called this method, we need to deduct the amountETH 
                // and amountToken respectively

                // The current eth balance minus the amount eth equals the ETH balance before the transaction
                balance0, 
                //The current token balance minus the amountToken equals to the token balance before the transaction
                balance1,
                // Oracle price - eth amount
                ethAmount, 
                // Oracle price - token amount
                tokenAmount
            );
        } else {
            // TODO: 对于精度小的币，小份额不能这样去除
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
        require(token == address(0), "COP:token must be 0");
        
        // 3. Calculate the net value and calculate the equal proportion fund according to the net value
        address token0 = _token0;
        address token1 = _token1;
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        uint total = totalSupply;

        amountETHOut = balance0 * liquidity / total;
        amountTokenOut = balance1 * liquidity / total;

        // 5. Destroy xtoken
        _burn(address(this), liquidity);
        //emit Burn(token, to, liquidity, amountETHOut, amountTokenOut);

        // 7. Transfer of funds to the user's designated address
        //payable(to).transfer(amountETHOut);
        TransferHelper.safeTransfer(token0, to, amountETHOut);
        TransferHelper.safeTransfer(token1, to, amountTokenOut);
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
        address token0 = _token0;
        address token1 = _token1;
        uint theta = uint(_theta);

        // 1. Query oracle
        (
            uint k, 
            uint ethAmount, 
            uint tokenAmount, 
            //uint blockNumber, 
        ) = _queryOracle(
            uint(_channelId),
            msg.value,
            payback
        );

        if (src == token0 && dest == token1) {
            //(amountOut, mined) =  _swapForToken(token1, amountIn, to, payback);

            // 2. Calculate the trade result
            uint fee = amountIn * theta / 10000;
            amountOut = (amountIn - fee) * tokenAmount * 1 ether / ethAmount / (
                1 ether + k + impactCostForSellOutETH(amountIn)
            );

            // 3. Transfer transaction fee
            // fee = _collect(fee * uint(_theta0) / theta);
            TransferHelper.safeTransfer(token0, _cofixDAO, fee * uint(_theta0) / theta);

            // 5. Transfer token
            TransferHelper.safeTransfer(token1, to, amountOut);

            emit SwapForToken1(amountIn, to, amountOut, mined);
        } else if (src == token1 && dest == token0) {
            //(amountOut, mined) = _swapForETH(token1, amountIn, to, payback);
           
            // 2. Calculate the trade result
            amountOut = amountIn * ethAmount / tokenAmount;
            amountOut = amountOut * 1 ether / (
                1 ether + k + impactCostForBuyInETH(amountOut)
            ); 

            uint fee = amountOut * theta / 10000;
            amountOut = amountOut - fee;

            // 3. Transfer transaction fee
            // fee = _collect(fee * uint(_theta0) / theta);
            TransferHelper.safeTransfer(token0, _cofixDAO, fee * uint(_theta0) / theta);

            // 5. Transfer token
            //payable(to).transfer(amountETHOut);
            TransferHelper.safeTransfer(token0, to, amountOut);

            emit SwapForToken0(amountIn, to, amountOut, mined);
        } else {
            revert("CoFiXPair: pair error");
        }
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
            IERC20(_token0).balanceOf(address(this)), 
            IERC20(_token1).balanceOf(address(this)), 
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
        //impactCost = vol * uint(_impactCostVOL) / 100000;
        impactCost = vol * uint(_impactCostVOL) / 500000000;
    }

    /// @dev Calculate the impact cost of sell out eth
    /// @param vol Trade amount in eth
    /// @return impactCost Impact cost
    function impactCostForSellOutETH(uint vol) public view override returns (uint impactCost) {
        //return _impactCostForSellOutETH(vol, uint(_impactCostVOL));
        //impactCost = vol * uint(_impactCostVOL) / 100000;
        impactCost = vol * uint(_impactCostVOL) / 500000000;
    }

    /// @dev Gets the token address of the share obtained by the specified token market making
    /// @param token Target token address
    /// @return If the fund pool supports the specified token, return the token address of the market share
    function getXToken(address token) external view override returns (address) {
        if (token == _token0 || token == _token1) {
            return address(this);
        }
        return address(0);
        //return address(this);
    }

    /// @dev Calc variance of price and K in CoFiX is very expensive
    /// We use expected value of K based on statistical calculations here to save gas
    /// In the near future, NEST could provide the variance of price directly. We will adopt it then.
    /// We can make use of `data` bytes in the future
    /// @param channelId 目标报价通道
    /// @param payback As the charging fee may change, it is suggested that the caller pay more fees, 
    /// and the excess fees will be returned through this address
    /// @return k The K value(18 decimal places).
    /// @return ethAmount Oracle price - eth amount
    /// @return tokenAmount Oracle price - token amount
    /// @return blockNumber Block number of price
    function _queryOracle(
        uint channelId,
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
            //uint triggeredSigmaSQ
        ) = INestOpenPrice(NEST_OPEN_PRICE).lastPriceListAndTriggeredPriceInfo {
            value: fee  
        } (channelId, 2, payback);

        
        //prices[1] = (prices[1]);
        //prices[3] = (prices[3]);
        //triggeredAvgPrice = (triggeredAvgPrice);
        tokenAmount = prices[1];
        _checkPrice(tokenAmount, triggeredAvgPrice);
        blockNumber = prices[0];
        ethAmount = 2000 ether;

        k = calcRevisedK(prices[3], prices[2], tokenAmount, blockNumber);
    }

     /// @dev K value is calculated by revised volatility
    /// @param p0 Last price (number of tokens equivalent to 1 ETH)
    /// @param bn0 Block number of the last price
    /// @param p Latest price (number of tokens equivalent to 1 ETH)
    /// @param bn The block number when (ETH, TOKEN) price takes into effective
    function calcRevisedK(uint p0, uint bn0, uint p, uint bn) public view returns (uint k) {
        uint sigmaSQ = uint(_sigmaSQ);
        uint sigmaISQ = p * 1 ether / p0;
        if (sigmaISQ > 1 ether) {
            sigmaISQ -= 1 ether;
        } else {
            sigmaISQ = 1 ether - sigmaISQ;
        }

        // James:
        // fort算法 把前面一项改成 max ((p2-p1)/p1,0.002) 后面不变
        // jackson:
        // 好
        // jackson:
        // 要取绝对值吧
        // James:
        // 对的
        if (sigmaISQ > 0.002 ether) {
            k = sigmaISQ;
        } else {
            k = 0.002 ether;
        }

        sigmaISQ = sigmaISQ * sigmaISQ / (bn - bn0) / BLOCK_TIME / 1 ether;

        if (sigmaISQ > sigmaSQ) {
            k += _sqrt(1 ether * BLOCK_TIME * (block.number - bn) * sigmaISQ);
        } else {
            k += _sqrt(1 ether * BLOCK_TIME * sigmaSQ * (block.number - bn));
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
            "COP:price deviation"
        );
    }
}
