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

/// @dev Pair contract for each trading pair, storing assets and handling settlement
contract CoFiXPair is CoFiXBase, ICoFiXPair, CoFiXERC20 {

    // it's negligible because we calc liquidity in ETH
    uint constant MINIMUM_LIQUIDITY = 10**9; 
    uint constant public THETA = 0.002 ether;
    address immutable public TOKEN_ADDRESS; 

    // n_t为每一单位ETH标准出矿量为，当前n_t=0.1。BASE: 10000
    uint constant nt = 1000;
    uint constant VOL_BASE = 500 ether;
    uint constant C_BUYIN_ALPHA = 0; // α=0
    uint constant C_BUYIN_BETA = 2000000000000; // β=2e-06*1e18
    //uint constant C_SELLOUT_ALPHA = 0; // α=0
    //uint constant C_SELLOUT_BETA = 2000000000000; // β=2e-06*1e18

    // ERC20 - name
    string public name;
    
    // ERC20 - symbol
    string public symbol;

    // Configration
    Config _config;

    // Address of CoFiXDAO
    address _cofixDAO;

    // Address of CoFiXRouter
    address _cofixRouter;

    // 初始资产比例 - ETH
    uint40 INIT_ETH_AMOUNT;
    
    // 初始资产比例 - TOKEN
    uint40 INIT_TOKEN_AMOUNT;

    // Lock flag
    uint8 _unlocked = 1;

    // TODO: 将CoFiXController合并到CoFiXRouter中
    // Address of CoFiXController
    address _cofixController;

    uint _totalFee;
    uint112 _Y;
    uint112 _D;
    uint32 _LASTBLOCK;

    // 构造函数，为了支持openzeeplin的可升级方案，需要将构造函数移到initialize方法中实现
    constructor (
        string memory name_, 
        string memory symbol_, 
        address tokenAddress, 
        uint40 initETHAmount, 
        uint40 initTokenAmount
    ) {
        name = name_;
        symbol = symbol_;
        TOKEN_ADDRESS = tokenAddress;
        INIT_ETH_AMOUNT = initETHAmount;
        INIT_TOKEN_AMOUNT = initTokenAmount;
    }

    modifier check() {
        require(_cofixRouter == msg.sender, "CoFiXPair: Only for CoFiXRouter");
        require(_unlocked == 1, "CPair: LOCKED");
        _unlocked = 0;
        _;
        _unlocked = 1;
    }

    /// @dev 获取初始资产比例
    /// @param initETHAmount 初始资产比例 - ETH
    /// @param initTokenAmount 初始资产比例 - TOKEN
    function getInitialAssetRatio() public override view returns (uint initETHAmount, uint initTokenAmount) {
        return (uint(INIT_ETH_AMOUNT), uint(INIT_TOKEN_AMOUNT));
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
    /// @param payback 退回的手续费接收地址
    /// @return liquidity 获得的流动性份额
    function mint(
        address to, 
        uint amountETH, 
        uint amountToken,
        address payback
    ) external payable override check returns (
        uint liquidity
    ) {
        // 1. 验证资金的正确性
        // 确保比例正确
        require(amountETH * uint(INIT_TOKEN_AMOUNT) == amountToken * uint(INIT_ETH_AMOUNT), "CPair: invalid asset ratio");

        // 2. 调用预言机
        // 计算K值
        // 计算θ
        (
            uint ethAmount, 
            uint tokenAmount, 
            //uint blockNum, 
        ) = ICoFiXController(_cofixController).queryPrice { 
            // 多余的部分，都作为预言机调用费用
            value: msg.value - amountETH
        } (
            TOKEN_ADDRESS,
            payback
        );

        // 3. 计算净值和份额
        uint navps = 1 ether;
        uint total = totalSupply;
        if (total > 0) {
            // TODO: Pt此处没有引入K值，后续需要引入
            navps = _calcTotalValue(
                // 当前eth余额，减去amountETH等于交易前eth余额
                address(this).balance - amountETH, 
                // 当前token余额，减去amountToken等于交易前token余额
                IERC20(TOKEN_ADDRESS).balanceOf(address(this)) - amountToken,
                // 价格 - eth数量 
                ethAmount, 
                // 价格 - token数量
                tokenAmount
            ) * 1 ether / total;

            // 做市没有冲击成本
            // 当发行量不为0时，正常发行份额
            liquidity = _calcLiquidity(amountETH, navps);
        } else {
            // TODO: 确定基础份额的逻辑
            liquidity = _calcLiquidity(amountETH, navps) - (MINIMUM_LIQUIDITY);
            // permanently lock the first MINIMUM_LIQUIDITY tokens
            // 当发行量为0时，有一个基础份额
            _mint(address(0), MINIMUM_LIQUIDITY); 
        }

        // // 份额必须大于0
        // require(liquidity > 0, "CPair: SHORT_LIQUIDITY_MINTED");

        // 5. 增发份额
        _mint(to, liquidity);
        emit Mint(to, amountETH, amountToken, liquidity);
    }

    // 销毁流动性
    // this low-level function should be called from a contract which performs important safety checks
    /// @dev 移除流动性并销毁
    /// @param liquidity 需要移除的流动性份额
    /// @param to 资金接收地址
    /// @param payback 退回的手续费接收地址
    /// @return amountTokenOut 获得的token数量
    /// @return amountETHOut 获得的eth数量
    function burn(
        uint liquidity, 
        address to, 
        address payback
    ) external payable override check returns (
        uint amountTokenOut, 
        uint amountETHOut
    ) { 
        // 1. 调用预言机
        (
            uint ethAmount, 
            uint tokenAmount, 
            //uint blockNum, 
        ) = ICoFiXController(_cofixController).queryPrice { 
            value: msg.value 
        } (
            TOKEN_ADDRESS,
            payback
        );

        // 2. 计算净值，根据净值计算等比资金
        // 计算净值
        uint ethBalance = address(this).balance;
        uint tokenBalance = IERC20(TOKEN_ADDRESS).balanceOf(address(this));
        uint navps = 1 ether;
        uint total = totalSupply;
        if (total > 0) {
            // Pt此处没有引入K值，后续需要引入
            navps = _calcTotalValue(
                ethBalance, 
                tokenBalance, 
                ethAmount, 
                tokenAmount
            ) * 1 ether / total;
        }

        // TODO: 赎回时需要计算冲击成本
        // TODO: 确定赎回的时候是否有手续费逻辑
        amountETHOut = navps * liquidity / 1 ether;
        amountTokenOut = amountETHOut * uint(INIT_TOKEN_AMOUNT) / uint(INIT_ETH_AMOUNT);

        // 3. 销毁份额
        _burn(address(this), liquidity);

        // 4. TODO: 根据资金池剩余情况进行调整
        // 待取回的eth数量超过资金池余额，自动转化为token取出
        if (amountETHOut > ethBalance) {
            amountTokenOut += (amountETHOut - ethBalance) * tokenAmount / ethAmount;
            amountETHOut = ethBalance;
        } 
        // 待取回的token数量超过资金池余额，自动转化为ETH取出
        else if (amountTokenOut > tokenBalance) {
            amountETHOut += (amountTokenOut - tokenBalance) * ethAmount / tokenAmount;
            amountTokenOut = tokenBalance;
        }

        // 5. 资金转入用户指定地址
        payable(to).transfer(amountETHOut);
        TransferHelper.safeTransfer(TOKEN_ADDRESS, to, amountTokenOut);

        emit Burn(to, liquidity, amountTokenOut, amountETHOut);
    }

    /// @dev 用eth兑换token
    /// @param amountIn 兑换的eth数量
    /// @param to 兑换资金接收地址
    /// @param payback 退回的手续费接收地址
    /// @return amountTokenOut 兑换到的token数量
    /// @return mined 出矿量
    function swapForToken(
        uint amountIn, 
        address to, 
        address payback
    ) external payable override check returns (
        uint amountTokenOut, 
        uint mined
    ) {
        // 1. 调用预言机获取价格
        (
            uint k, 
            uint ethAmount, 
            uint tokenAmount, 
            //uint blockNum, 
            //uint theta
        ) = ICoFiXController(_cofixController).queryOracle { 
            value: msg.value  - amountIn
        } (
            TOKEN_ADDRESS,
            payback
        );

        // 2. 计算兑换结果
        // 2.1. K值计算
        // 2.2. 冲击成本计算
        uint C = impactCostForSellOutETH(amountIn);
        amountTokenOut = amountIn * tokenAmount * (1 ether - THETA) / ethAmount / (1 ether + k + C);

        // 3. 扣除交易手续费
        uint fee = amountIn * THETA / 1 ether;
        _collect(fee);

        // 4. 挖矿逻辑
        //uint ethBalance1 = address(this).balance;
        //uint tokenBalance1 = IERC20(TOKEN_ADDRESS).balanceOf(address(this)) - amountTokenOut;
        // 【注意】Pt此处没有引入K值，后续需要引入
        mined = _cofiMint(_calcD(
            address(this).balance, 
            IERC20(TOKEN_ADDRESS).balanceOf(address(this)) - amountTokenOut, 
            ethAmount, 
            tokenAmount
        ));

        // 5. 转token给用户
        TransferHelper.safeTransfer(TOKEN_ADDRESS, to, amountTokenOut);
        emit SwapForToken(amountIn, to, amountTokenOut, mined);
    }

    /// @dev 用token兑换eth
    /// @param amountIn 兑换的token数量
    /// @param to 兑换资金接收地址
    /// @param payback 退回的手续费接收地址
    /// @return amountETHOut 兑换到的token数量
    /// @return mined 出矿量
    function swapForETH(
        uint amountIn, 
        address to, 
        address payback
    ) external payable override check returns (
        uint amountETHOut, 
        uint mined
    ) {
        // 1. 调用预言机获取价格
        (
            uint k, 
            uint ethAmount, 
            uint tokenAmount, 
            //uint blockNum, 
            //uint theta
        ) = ICoFiXController(_cofixController).queryOracle { 
            value: msg.value
        } (
            TOKEN_ADDRESS,
            payback
        );

        // 2. 计算兑换结果
        // 2.1. K值计算
        // 2.2. 冲击成本计算
        uint C = impactCostForBuyInETH(amountIn);
        amountETHOut = amountIn * ethAmount * (1 ether - THETA) / tokenAmount / (1 ether + k + C); 
        
        // 3. 扣除交易手续费
        uint fee = amountETHOut * THETA / (1 ether - THETA);
        _collect(fee);

        // 4. 挖矿逻辑
        //uint ethBalance1 = address(this).balance - amountETHOut;
        //uint tokenBalance1 = IERC20(TOKEN_ADDRESS).balanceOf(address(this));
        // 【注意】Pt此处没有引入K值，后续需要引入
        mined = _cofiMint(_calcD(
            address(this).balance - amountETHOut, 
            IERC20(TOKEN_ADDRESS).balanceOf(address(this)), 
            ethAmount, 
            tokenAmount
        ));

        // 5. 转token给用户
        payable(to).transfer(amountETHOut);
        emit SwapForETH(amountIn, to, amountETHOut, mined);
    }

    // 计算调整为𝑘0时所需要的ETH交易规模
    function _calcD(
        uint ethBalance1, 
        uint tokenBalance1, 
        uint ethAmount, 
        uint tokenAmount
    ) private view returns (uint) {
        // D_t=|(E_t 〖*k〗_0 〖-U〗_t)/(k_0+P_t )|
        uint left = ethBalance1 * uint(INIT_TOKEN_AMOUNT);
        uint right = tokenBalance1 * uint(INIT_ETH_AMOUNT);
        uint numerator;
        if (left > right) {
            numerator = left - right;
        } else {
            numerator = right - left;
        }
        
        return numerator * ethAmount / (uint(INIT_TOKEN_AMOUNT) * ethAmount + tokenAmount * uint(INIT_ETH_AMOUNT));
    }

    // 计算CoFi交易挖矿相关的变量并更新对应状态
    function _cofiMint(uint D1) private returns (uint mined) {
        // Y_t=Y_(t-1)+D_(t-1)*n_t*(S_t+1)-Z_t                   
        // Z_t=〖[Y〗_(t-1)+D_(t-1)*n_t*(S_t+1)]* v_t
        uint D0 = uint(_D);

        // D0 < D1时，也需要更新Y值
        uint Y = uint(_Y) + D0 * nt * (block.number + 1 - uint(_LASTBLOCK)) / 10000;
        if (D0 > D1) {
            mined = Y * (D0 - D1) / D0;
            Y = Y - mined;
        }

        _Y = uint112(Y);
        _D = uint112(D1);
        _LASTBLOCK = uint32(block.number);
    }

    // 批量存入手续费
    function _collect(uint fee) private {
        uint totalFee = _totalFee + fee;
        // 总手续费超过1ETH时才存入
        if (totalFee >= 1 ether) {
            _totalFee = 0;
            ICoFiXDAO(_cofixDAO).addETHReward { value: totalFee } (address(this));
        } 
        _totalFee = totalFee;
    }

    // // impact cost
    // // - C = 0, if VOL < 500 / γ
    // // - C = (α + β * VOL) * γ, if VOL >= 500 / γ

    // α=0，β=2e-06
    function impactCostForBuyInETH(uint vol) public pure override returns (uint impactCost) {
        uint gamma = 1; //CGammaMap[token];
        if (vol * gamma < VOL_BASE) {
            return 0;
        }
        // return C_BUYIN_ALPHA.add(C_BUYIN_BETA.mul(vol).div(1e18)).mul(1e8).div(1e18);
        return (C_BUYIN_ALPHA + C_BUYIN_BETA * vol / 1e18) * gamma; // combine mul div
    }

    // α=0，β=2e-06
    function impactCostForSellOutETH(uint vol) public pure override returns (uint impactCost) {
        uint gamma = 1; //CGammaMap[token];
        if (vol * gamma < VOL_BASE) {
            return 0;
        }
        // return C_BUYIN_ALPHA.add(C_BUYIN_BETA.mul(vol).div(1e18)).mul(1e8).div(1e18);
        return (C_BUYIN_ALPHA + C_BUYIN_BETA * vol / 1e18) * gamma; // combine mul div
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
        //navps = (ethBalance * INIT_ETH_AMOUNT * tokenAmount + tokenBalance * INIT_ETH_AMOUNT * ethAmount) * 1 ether
        //        / totalSupply / (INIT_ETH_AMOUNT * tokenAmount + INIT_TOKEN_AMOUNT * ethAmount);

        return _calcTotalValue(ethBalance, tokenBalance, ethAmount, tokenAmount) * 1 ether / totalSupply;
    }

    // 计算资产余额总价值
    function _calcTotalValue(
        uint ethBalance, 
        uint tokenBalance, 
        uint ethAmount, 
        uint tokenAmount
    ) private view returns (uint totalValue) {
        // NV=(E_t+U_t/P_t)/((1+k_0/P_t ))
        totalValue = (
            ethBalance * tokenAmount 
            + tokenBalance * ethAmount
        ) * uint(INIT_ETH_AMOUNT)
        / (
            uint(INIT_ETH_AMOUNT) * tokenAmount 
            + INIT_TOKEN_AMOUNT * ethAmount
        );
    }

    // use it in this contract, for optimized gas usage
    function _calcLiquidity(uint amount0, uint navps) private pure returns (uint liquidity) {
        liquidity = amount0 * 1 ether / navps;
    }
}
