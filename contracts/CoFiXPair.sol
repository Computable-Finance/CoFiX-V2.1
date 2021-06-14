// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./libs/TransferHelper.sol";

import "./interfaces/ICoFiXPair.sol";
import "./interfaces/ICoFiXController.sol";
import "./interfaces/ICoFiXDAO.sol";
import "./CoFiToken.sol";
import "./CoFiXERC20.sol";
import "hardhat/console.sol";

// Pair contract for each trading pair, storing assets and handling settlement
// No owner or governance
contract CoFiXPair is ICoFiXPair, CoFiXERC20 {

    struct Config {
        uint64 theta;
        uint64 k;
    }

    uint constant MINIMUM_LIQUIDITY = 10**9; // it's negligible because we calc liquidity in ETH

    string public name;
    string public symbol;

    address immutable public TOKEN_ADDRESS; // WETH token
    address _cofixDAO;

    uint immutable INIT_ETH_AMOUNT;
    uint immutable INIT_TOKEN_AMOUNT;

    Config _config;
    address _cofixController;
    uint private _unlocked = 1;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, address outToken, uint outAmount, address indexed to);
    event Swap(
        address indexed sender,
        uint amountIn,
        uint amountOut,
        address outToken,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    modifier lock() {
        require(_unlocked == 1, "CPair: LOCKED");
        _unlocked = 0;
        _;
        _unlocked = 1;
    }

    constructor (
        string memory name_, 
        string memory symbol_, 
        address tokenAddress, 
        uint initEthAmount, 
        uint initTokenAmount
    ) {
        name = name_;
        symbol = symbol_;
        TOKEN_ADDRESS = tokenAddress;
        INIT_ETH_AMOUNT = initEthAmount;
        INIT_TOKEN_AMOUNT = initTokenAmount;
    }

    function getInitialAssetRatio() public override view returns (uint initEthAmount, uint initTokenAmount) {
        initEthAmount = INIT_ETH_AMOUNT;
        initTokenAmount = INIT_TOKEN_AMOUNT;
    }

    function getCoFiXController() external view returns (address) {
        return _cofixController;
    }

    function setCoFiXController(address cofixController) external {
        _cofixController = cofixController;
    }

    function setCoFiXDAO(address cofixDAO) external {
        _cofixDAO = cofixDAO;
    }

    function getCoFiXDAO() external view returns (address) {
        return _cofixDAO;
    }

    // 做市出矿
    // this low-level function should be called from a contract which performs important safety checks
    function mint(
        // 份额接收地址
        address to, 
        // eth做市数量
        uint amountETH, 
        // token做市数量
        uint amountToken,
        address paybackAddress) external payable override lock returns (uint liquidity) {
        
        // 1. 验证资金的正确性
        // token0增量
        uint amount0 = amountETH;
        // token1数量
        uint amount1 = amountToken;

        // 确保比例正确
        require(amountETH * INIT_TOKEN_AMOUNT == amountToken * INIT_ETH_AMOUNT, "CPair: invalid asset ratio");

        // // 2. 调用预言机
        // 计算K值
        // 计算θ
        (
            uint256 ethAmount, 
            uint256 erc20Amount, 
            //uint256 blockNum, 
        ) = ICoFiXController(_cofixController).queryPrice { 
            value: msg.value - amountETH 
        } (
            TOKEN_ADDRESS,
            paybackAddress
        );

        //Config memory config = _config;

        uint total = totalSupply;

        // 计算净值
        uint navps = 1 ether;
        
        if (total > 0) {
            navps = calcNAVPerShare(
                address(this).balance - msg.value, 
                IERC20(TOKEN_ADDRESS).balanceOf(address(this)) - amountToken, 
                ethAmount, 
                erc20Amount
            );
        }

        // 没有冲击成本

        { // scope for ethAmount/erc20Amount/blockNum to avoid stack too deep error

            // 当发行量为0时，有一个基础份额
            // TODO: 确定基础份额的逻辑
            if (total == 0) {
                liquidity = calcLiquidity(amount0, navps) - (MINIMUM_LIQUIDITY);
                _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
            } 
            // 当发行量不为0时，正常发行份额
            else {
                liquidity = calcLiquidity(amount0, navps);
            }
        }

        // 增发份额必须大于0
        require(liquidity > 0, "CPair: SHORT_LIQUIDITY_MINTED");

        // 分发份额
        _mint(to, liquidity);

        emit Mint(msg.sender, amount0, amount1);

        console.log('liquidity', liquidity);
    }

    // 销毁流动性
    // this low-level function should be called from a contract which performs important safety checks
    function burn(uint liquidity, address to, address paybackAddress) external payable override lock returns (uint amountTokenOut, uint amountEthOut) { 
        
        // 2. 计算净值
        (
            uint256 ethAmount, 
            uint256 erc20Amount, 
            //uint256 blockNum, 
        ) = ICoFiXController(_cofixController).queryPrice { 
            value: msg.value 
        } (
            TOKEN_ADDRESS,
            paybackAddress
        );

        // 3. 根据净值计算等比资金
        uint total = totalSupply;

        // 计算净值
        uint navps = 1 ether;
        
        if (total > 0) {
            navps = calcNAVPerShare(
                address(this).balance - msg.value, 
                IERC20(TOKEN_ADDRESS).balanceOf(address(this)), 
                ethAmount, 
                erc20Amount
            );
        }

        amountEthOut = navps * liquidity;
        amountTokenOut = amountEthOut * INIT_TOKEN_AMOUNT / INIT_ETH_AMOUNT;

        // 6. 销毁份额
        _burn(address(this), liquidity);

        // 4. 根据资金池剩余情况进行调整
        // 5. 资金转入用户指定地址
        payable(to).transfer(amountEthOut);
        TransferHelper.safeTransfer(address(this), to, amountTokenOut);
    }

    function swapForToken(uint amountIn, address to, address paybackAddress) external payable override lock returns (uint amountTokenOut, uint Z) {
        
        // 2. 调用预言机获取价格
        (
            uint256 k, 
            uint256 ethAmount, 
            uint256 erc20Amount, 
            ,//uint256 blockNum, 
            uint256 theta
        ) = ICoFiXController(_cofixController).queryOracle { 
            value: msg.value  - amountIn
        } (
            TOKEN_ADDRESS,
            paybackAddress
        );

        // 3. 计算兑换结果
        // 3.1. K值计算
        // 3.2. 冲击成本计算
        uint C = impactCostForSellOutETH(amountIn);

        amountTokenOut = amountIn * erc20Amount * (1 ether - theta)/ ethAmount / (1 ether + k + C);
        uint fee = amountIn * theta / 1 ether;
        //payable(_cofixDAO).transfer(fee);
        // TODO: 改为批量存入
        _collect(fee);
        
        console.log('fee=', fee);

        // 4. 挖矿逻辑
        uint ethBalance1 = address(this).balance;
        console.log('amountTokenOut', amountTokenOut);
        uint tokenBalance1 = IERC20(TOKEN_ADDRESS).balanceOf(address(this)) - amountTokenOut;
        console.log('tokenBalance1', tokenBalance1);

        // 【注意】Pt此处没有引入K值，后续需要引入
        uint D1 = (ethBalance1 * INIT_TOKEN_AMOUNT - tokenBalance1 * INIT_ETH_AMOUNT)
                  / (INIT_TOKEN_AMOUNT + erc20Amount * INIT_ETH_AMOUNT / ethAmount);
        console.log('D1', D1);
        
        Z = _mint(D1);

        // 5. 转token给用户
        TransferHelper.safeTransfer(TOKEN_ADDRESS, to, amountTokenOut);
    }

    uint _totalFee;

    function _collect(uint fee) private {
        uint totalFee = _totalFee + fee;
        if (totalFee >= 1 ether) {
            _totalFee = 0;
            ICoFiXDAO(_cofixDAO).addETHReward { value: totalFee } (address(this));
        } 
        _totalFee = totalFee;
    }

    // BASE: 10000
    uint constant nt = 1000;

    function swapForETH(uint amountIn, address to, address paybackAddress) external payable override lock returns (uint amountEthOut, uint Z) {

        // 1. 记录初始资产数量，用于计算出矿量
        //uint ethBalance0 = address(this).balance - msg.value;
        //uint tokenBalance0 = IERC20(TOKEN_ADDRESS).balanceOf(address(this));

        // 2. 调用预言机获取价格
        (
            uint256 k, 
            uint256 ethAmount, 
            uint256 erc20Amount, 
            ,//uint256 blockNum, 
            uint256 theta
        ) = ICoFiXController(_cofixController).queryOracle { 
            value: msg.value
        } (
            TOKEN_ADDRESS,
            paybackAddress
        );

        // 3. 计算兑换结果
        // 3.1. K值计算
        // 3.2. 冲击成本计算
        uint C = impactCostForBuyInETH(amountIn);

        amountEthOut = amountIn * ethAmount * (1 ether - theta)/ erc20Amount / (1 ether + k + C); 
        uint fee = amountEthOut * theta / (1 ether - theta);
        //payable(_cofixDAO).transfer(fee);
        // TODO: 改为批量存入
        _collect(fee);

        // 4. 挖矿逻辑
        uint ethBalance1 = address(this).balance - amountEthOut;
        uint tokenBalance1 = IERC20(TOKEN_ADDRESS).balanceOf(address(this));

        // 【注意】Pt此处没有引入K值，后续需要引入
        uint D1 = (ethBalance1 * INIT_TOKEN_AMOUNT - tokenBalance1 * INIT_ETH_AMOUNT)
                  / (INIT_TOKEN_AMOUNT + erc20Amount * INIT_ETH_AMOUNT / ethAmount);
        
        Z = _mint(D1);

        // 5. 转token给用户
        payable(to).transfer(amountEthOut);
    }

    //uint a;
    //uint b;
    uint112 _Y;
    //uint a;
    uint112 _D;
    //uint b;
    uint32 _LASTBLOCK;

    function _mint(uint D1) private returns (uint Z) {
        // Y_t=Y_(t-1)+D_(t-1)*n_t*(S_t+1)-Z_t                   
        // Z_t=〖[Y〗_(t-1)+D_(t-1)*n_t*(S_t+1)]* v_t
        uint D0 = uint(_D);

        uint Y = uint(_Y) + D0 * nt * (block.number + 1 - uint(_LASTBLOCK)) / 10000;
        if (D0 > D1) {
            Z = 1 ether * Y * (D0 - D1) / D0;
            //_CNodeReward += Z * 10 / 100;
            Y = Y - Z;
        }

        _Y = uint112(Y);
        _D = uint112(D1);
        _LASTBLOCK = uint32(block.number);
    }

    uint256 constant internal C_BUYIN_ALPHA = 0; // α=0
    uint256 constant internal C_BUYIN_BETA = 2000000000000; // β=2e-06*1e18
    uint256 constant internal C_SELLOUT_ALPHA = 0; // α=0
    uint256 constant internal C_SELLOUT_BETA = 2000000000000; // β=2e-06*1e18

    // α=0，β=2e-06
    function impactCostForBuyInETH(uint vol) public pure override returns (uint impactCost) {
        uint gamma = 1; //CGammaMap[token];
        if (vol * gamma < 500 ether) {
            return 0;
        }
        // return C_BUYIN_ALPHA.add(C_BUYIN_BETA.mul(vol).div(1e18)).mul(1e8).div(1e18);
        return (C_BUYIN_ALPHA + C_BUYIN_BETA * vol / 1e18 / 1e10) * gamma; // combine mul div
    }

    // α=0，β=2e-06
    function impactCostForSellOutETH(uint vol) public pure override returns (uint impactCost) {
        uint gamma = 1; //CGammaMap[token];
        if (vol * gamma < 500 ether) {
            return 0;
        }
        // return C_BUYIN_ALPHA.add(C_BUYIN_BETA.mul(vol).div(1e18)).mul(1e8).div(1e18);
        return (C_BUYIN_ALPHA + C_BUYIN_BETA * vol / 1e18 / 1e10) * gamma; // combine mul div
    }

    // 计算净值
    // navps = calcNAVPerShare(reserve0, reserve1, _op.ethAmount, _op.erc20Amount);
    // calc Net Asset Value Per Share (no K)
    // use it in this contract, for optimized gas usage
    function calcNAVPerShare(uint balance0, uint balance1, uint ethAmount, uint erc20Amount) public view returns (uint navps) {

        // uint _totalSupply = totalSupply;
        // // 份额为0时，净值为1
        // if (_totalSupply == 0) {
        //     navps = NAVPS_BASE;
        // } 
        // // 计算净值
        // else {
        //     /*
        //     NV  = \frac{E_t + U_t/P_t}{(1 + \frac{k_0}{P_t})*F_t}\\\\
        //         = \frac{E_t + U_t * \frac{ethAmount}{erc20Amount}}{(1 + \frac{initToken1Amount}{initToken0Amount} * \frac{ethAmount}{erc20Amount})*F_t}\\\\
        //         = \frac{E_t * erc20Amount + U_t * ethAmount}{(erc20Amount + \frac{initToken1Amount * ethAmount}{initToken0Amount}) * F_t}\\\\
        //         = \frac{E_t * erc20Amount * initToken0Amount + U_t * ethAmount * initToken0Amount}{( erc20Amount * initToken0Amount + initToken1Amount * ethAmount) * F_t} \\\\
        //         = \frac{balance0 * erc20Amount * initToken0Amount + balance1 * ethAmount * initToken0Amount}{(erc20Amount * initToken0Amount + initToken1Amount * ethAmount) * totalSupply}
        //      */
        //     uint balance0MulErc20AmountMulInitToken0Amount = balance0.mul(erc20Amount).mul(initToken0Amount);
        //     uint balance1MulEthAmountMulInitToken0Amount = balance1.mul(ethAmount).mul(initToken0Amount);
        //     uint initToken1AmountMulEthAmount = initToken1Amount.mul(ethAmount);
        //     uint initToken0AmountMulErc20Amount = erc20Amount.mul(initToken0Amount);

        //     // 计算净值
            
        //     navps = (balance0MulErc20AmountMulInitToken0Amount.add(balance1MulEthAmountMulInitToken0Amount))
        //                 .div(_totalSupply).mul(NAVPS_BASE)
        //                 .div(initToken1AmountMulEthAmount.add(initToken0AmountMulErc20Amount));
        // }

        // k = Ut / Et
        // NV = (Et + Ut / Pt) / ( (1 + k0 / Pt) * Ft )
        // NV = (Et + Ut / Pt) / ( (1 + k0 / Pt) * Ft )
        // NV = (Et + Ut / Pt) / ( (1 + (U0 / Pt * E0)) * Ft )
        // NV = (Et * E0 + Ut * E0  / Pt) / ( (E0 + U0 / Pt) * Ft )

        navps = (balance0 * INIT_ETH_AMOUNT * erc20Amount + balance1 * INIT_ETH_AMOUNT * ethAmount)
                / totalSupply / (INIT_ETH_AMOUNT * erc20Amount + INIT_TOKEN_AMOUNT * ethAmount);
    }

    // use it in this contract, for optimized gas usage
    function calcLiquidity(uint amount0, uint navps) public pure returns (uint liquidity) {
        liquidity = amount0 * (1 ether) / (navps);
    }
}
