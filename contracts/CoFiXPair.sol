// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "./libs/IERC20.sol";
import "./libs/TransferHelper.sol";

import "./interfaces/ICoFiXPair.sol";
import "./interfaces/ICoFiXController.sol";
import "./interfaces/ICoFiXDAO.sol";

import "./CoFiXBase.sol";
import "./CoFiToken.sol";
import "./CoFiXERC20.sol";

import "hardhat/console.sol";

// Pair contract for each trading pair, storing assets and handling settlement
// No owner or governance
contract CoFiXPair is CoFiXBase, ICoFiXPair, CoFiXERC20 {

    // it's negligible because we calc liquidity in ETH
    uint constant MINIMUM_LIQUIDITY = 10**9; 
    address immutable public TOKEN_ADDRESS; 

    uint immutable INIT_ETH_AMOUNT;
    uint immutable INIT_TOKEN_AMOUNT;

    string public name;
    string public symbol;

    Config _config;
    address _cofixDAO;
    address _cofixRouter;
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

    constructor (
        string memory name_, 
        string memory symbol_, 
        address tokenAddress, 
        uint initETHAmount, 
        uint initTokenAmount
    ) {
        name = name_;
        symbol = symbol_;
        TOKEN_ADDRESS = tokenAddress;
        INIT_ETH_AMOUNT = initETHAmount;
        INIT_TOKEN_AMOUNT = initTokenAmount;
    }

    modifier lock() {
        require(_unlocked == 1, "CPair: LOCKED");
        _unlocked = 0;
        _;
        _unlocked = 1;
    }

    modifier onlyRouter() {
        require(msg.sender == _cofixRouter, "CoFiXPair: Only for CoFiXRouter");
        _;
    }

    function getInitialAssetRatio() public override view returns (uint initETHAmount, uint initTokenAmount) {
        return (INIT_ETH_AMOUNT, INIT_TOKEN_AMOUNT);
    }

    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(nestGovernanceAddress) when overriding, and override method without onlyGovernance
    /// @param newGovernance INestGovernance implementation contract address
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

    /// @dev 添加流动性并增发份额
    /// @param to 份额接收地址
    /// @param amountETH 要添加的eth数量
    /// @param amountToken 要添加的token数量
    /// @param paybackAddress 退回的手续费接收地址
    /// @return liquidity 获得的流动性份额
    function mint(
        address to, 
        uint amountETH, 
        uint amountToken,
        address paybackAddress
    ) external payable override lock onlyRouter returns (
        uint liquidity
    ) {
        // 1. 验证资金的正确性
        // 确保比例正确
        require(amountETH * INIT_TOKEN_AMOUNT == amountToken * INIT_ETH_AMOUNT, "CPair: invalid asset ratio");

        // 2. 调用预言机
        // 计算K值
        // 计算θ
        (
            uint ethAmount, 
            uint tokenAmount, 
            //uint blockNum, 
        ) = ICoFiXController(_cofixController).queryPrice { 
            value: msg.value - amountETH
        } (
            TOKEN_ADDRESS,
            paybackAddress
        );

        //Config memory config = _config;

        // 3. 计算净值
        uint total = totalSupply;
        uint navps = 1 ether;
        if (total > 0) {
            navps = calcNAVPerShare(
                address(this).balance - amountETH, 
                IERC20(TOKEN_ADDRESS).balanceOf(address(this)) - amountToken, 
                ethAmount, 
                tokenAmount
            );
        }

        // 4. 计算份额
        // 做市没有冲击成本
        // 当发行量为0时，有一个基础份额
        // TODO: 确定基础份额的逻辑
        if (total == 0) {
            liquidity = _calcLiquidity(amountETH, navps) - (MINIMUM_LIQUIDITY);
            // permanently lock the first MINIMUM_LIQUIDITY tokens
            _mint(address(0), MINIMUM_LIQUIDITY); 
        } 
        // 当发行量不为0时，正常发行份额
        else {
            liquidity = _calcLiquidity(amountETH, navps);
        }
        // 份额必须大于0
        require(liquidity > 0, "CPair: SHORT_LIQUIDITY_MINTED");

        // 5. 增发份额
        _mint(to, liquidity);
        emit Mint(msg.sender, amountETH, amountToken);
    }

    // 销毁流动性
    // this low-level function should be called from a contract which performs important safety checks
    /// @dev 移除流动性并销毁
    /// @param liquidity 需要移除的流动性份额
    /// @param to 资金接收地址
    /// @param paybackAddress 退回的手续费接收地址
    /// @return amountTokenOut 获得的token数量
    /// @return amountETHOut 获得的eth数量
    function burn(
        uint liquidity, 
        address to, 
        address paybackAddress
    ) external payable override lock onlyRouter returns (
        uint amountTokenOut, 
        uint amountETHOut
    ) { 
        // 1. 计算净值
        (
            uint ethAmount, 
            uint tokenAmount, 
            //uint blockNum, 
        ) = ICoFiXController(_cofixController).queryPrice { 
            value: msg.value 
        } (
            TOKEN_ADDRESS,
            paybackAddress
        );

        // 2. 根据净值计算等比资金
        uint total = totalSupply;
        // 计算净值
        uint navps = 1 ether;
        if (total > 0) {
            navps = calcNAVPerShare(
                address(this).balance - msg.value, 
                IERC20(TOKEN_ADDRESS).balanceOf(address(this)), 
                ethAmount, 
                tokenAmount
            );
        }

        amountETHOut = navps * liquidity / 1 ether;
        amountTokenOut = amountETHOut * INIT_TOKEN_AMOUNT / INIT_ETH_AMOUNT;
        // 3. 销毁份额
        _burn(address(this), liquidity);

        // 4. TODO: 根据资金池剩余情况进行调整
        // 5. 资金转入用户指定地址
        payable(to).transfer(amountETHOut);
        TransferHelper.safeTransfer(TOKEN_ADDRESS, to, amountTokenOut);
    }

    /// @dev 用eth兑换token
    /// @param amountIn 兑换的eth数量
    /// @param to 兑换资金接收地址
    /// @param paybackAddress 退回的手续费接收地址
    /// @return amountTokenOut 兑换到的token数量
    /// @param mined 出矿量
    function swapForToken(
        uint amountIn, 
        address to, 
        address paybackAddress
    ) external payable override lock onlyRouter returns (
        uint amountTokenOut, 
        uint mined
    ) {
        // 1. 调用预言机获取价格
        (
            uint k, 
            uint ethAmount, 
            uint tokenAmount, 
            ,//uint blockNum, 
            uint theta
        ) = ICoFiXController(_cofixController).queryOracle { 
            value: msg.value  - amountIn
        } (
            TOKEN_ADDRESS,
            paybackAddress
        );
        // 2. 计算兑换结果
        // 2.1. K值计算
        // 2.2. 冲击成本计算
        uint C = impactCostForSellOutETH(amountIn);
        amountTokenOut = amountIn * tokenAmount * (1 ether - theta)/ ethAmount / (1 ether + k + C);

        // 3. 扣除交易手续费
        uint fee = amountIn * theta / 1 ether;
        _collect(fee);

        // 4. 挖矿逻辑
        uint ethBalance1 = address(this).balance;
        uint tokenBalance1 = IERC20(TOKEN_ADDRESS).balanceOf(address(this)) - amountTokenOut;
        // 【注意】Pt此处没有引入K值，后续需要引入
        uint D1 = //(ethBalance1 * INIT_TOKEN_AMOUNT - tokenBalance1 * INIT_ETH_AMOUNT)
                  _calcD(ethBalance1, tokenBalance1)
                  / (INIT_TOKEN_AMOUNT + tokenAmount * INIT_ETH_AMOUNT / ethAmount);
        mined = _mint(D1);

        // 5. 转token给用户
        TransferHelper.safeTransfer(TOKEN_ADDRESS, to, amountTokenOut);
    }

    /// @dev 用token兑换eth
    /// @param amountIn 兑换的token数量
    /// @param to 兑换资金接收地址
    /// @param paybackAddress 退回的手续费接收地址
    /// @return amountETHOut 兑换到的token数量
    /// @param mined 出矿量
    function swapForETH(
        uint amountIn, 
        address to, 
        address paybackAddress
    ) external payable override lock onlyRouter returns (
        uint amountETHOut, 
        uint mined
    ) {
        // 1. 调用预言机获取价格
        (
            uint k, 
            uint ethAmount, 
            uint tokenAmount, 
            ,//uint blockNum, 
            uint theta
        ) = ICoFiXController(_cofixController).queryOracle { 
            value: msg.value
        } (
            TOKEN_ADDRESS,
            paybackAddress
        );

        // 2. 计算兑换结果
        // 2.1. K值计算
        // 2.2. 冲击成本计算
        uint C = impactCostForBuyInETH(amountIn);

        amountETHOut = amountIn * ethAmount * (1 ether - theta)/ tokenAmount / (1 ether + k + C); 
        // 3. 扣除交易手续费
        uint fee = amountETHOut * theta / (1 ether - theta);
        _collect(fee);

        // 4. 挖矿逻辑
        uint ethBalance1 = address(this).balance - amountETHOut;
        uint tokenBalance1 = IERC20(TOKEN_ADDRESS).balanceOf(address(this));
        // 【注意】Pt此处没有引入K值，后续需要引入
        uint D1 = //(ethBalance1 * INIT_TOKEN_AMOUNT - tokenBalance1 * INIT_ETH_AMOUNT)
                  _calcD(ethBalance1, tokenBalance1)
                  / (INIT_TOKEN_AMOUNT + tokenAmount * INIT_ETH_AMOUNT / ethAmount);
        mined = _mint(D1);

        // 5. 转token给用户
        payable(to).transfer(amountETHOut);
    }

    function _calcD(uint ethBalance1, uint tokenBalance1) private view returns (uint) {
        uint left = ethBalance1 * INIT_TOKEN_AMOUNT;
        uint right = tokenBalance1 * INIT_ETH_AMOUNT;
        if (left > right) {
            return left - right;
        } 
        return right - left;
    }

    //uint a;
    //uint b;
    uint112 _Y;
    //uint a;
    uint112 _D;
    //uint b;
    uint32 _LASTBLOCK;
    // BASE: 10000
    uint constant nt = 1000;

    function _mint(uint D1) private returns (uint mined) {
        // Y_t=Y_(t-1)+D_(t-1)*n_t*(S_t+1)-Z_t                   
        // Z_t=〖[Y〗_(t-1)+D_(t-1)*n_t*(S_t+1)]* v_t
        uint D0 = uint(_D);

        // D0 < D1时，是否更新Y值
        uint Y = uint(_Y) + D0 * nt * (block.number + 1 - uint(_LASTBLOCK)) / 10000;
        if (D0 > D1) {
            mined = Y * (D0 - D1) / D0;
            //_CNodeReward += mined * 10 / 100;
            Y = Y - mined;
        }

        _Y = uint112(Y);
        _D = uint112(D1);
        _LASTBLOCK = uint32(block.number);
    }

    uint _totalFee;

    // 批量存入手续费
    function _collect(uint fee) private {
        uint totalFee = _totalFee + fee;
        if (totalFee >= 1 ether) {
            _totalFee = 0;
            ICoFiXDAO(_cofixDAO).addETHReward { value: totalFee } (address(this));
        } 
        _totalFee = totalFee;
    }

    uint constant internal C_BUYIN_ALPHA = 0; // α=0
    uint constant internal C_BUYIN_BETA = 2000000000000; // β=2e-06*1e18
    uint constant internal C_SELLOUT_ALPHA = 0; // α=0
    uint constant internal C_SELLOUT_BETA = 2000000000000; // β=2e-06*1e18

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
    // navps = calcNAVPerShare(reserve0, reserve1, _op.ethAmount, _op.tokenAmount);
    // calc Net Asset Value Per Share (no K)
    // use it in this contract, for optimized gas usage

    /// @dev 计算净值
    /// @param ethBalance 资金池eth余额
    /// @param tokenBalance 资金池token余额
    /// @param ethAmount 预言机价格-eth数量
    /// @param tokenAmount 预言机价格-token数量
    /// @return navps 净值
    function calcNAVPerShare(
        uint ethBalance, 
        uint tokenBalance, 
        uint ethAmount, 
        uint tokenAmount
    ) public view override returns (uint navps) {
        // k = Ut / Et
        // NV = (Et + Ut / Pt) / ( (1 + k0 / Pt) * Ft )
        // NV = (Et + Ut / Pt) / ( (1 + k0 / Pt) * Ft )
        // NV = (Et + Ut / Pt) / ( (1 + (U0 / Pt * E0)) * Ft )
        // NV = (Et * E0 + Ut * E0  / Pt) / ( (E0 + U0 / Pt) * Ft )
        navps = (ethBalance * INIT_ETH_AMOUNT * tokenAmount + tokenBalance * INIT_ETH_AMOUNT * ethAmount) * 1 ether
                / totalSupply / (INIT_ETH_AMOUNT * tokenAmount + INIT_TOKEN_AMOUNT * ethAmount);
    }

    // use it in this contract, for optimized gas usage
    function _calcLiquidity(uint amount0, uint navps) private pure returns (uint liquidity) {
        liquidity = amount0 * (1 ether) / (navps);
    }
}
