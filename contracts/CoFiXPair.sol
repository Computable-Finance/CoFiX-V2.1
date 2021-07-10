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

/// @dev 二元资金池: eth/token
contract CoFiXPair is CoFiXBase, CoFiXERC20, ICoFiXPair {

    // it's negligible because we calc liquidity in ETH
    uint constant MINIMUM_LIQUIDITY = 1e9; 
    // 冲击成本基础规模
    uint constant VOL_BASE = 50 ether;
    // α=0
    uint constant C_BUYIN_ALPHA = 0; 
    // β=2e-05*1e18
    uint constant C_BUYIN_BETA = 20000000000000; 

    // 目标代币地址
    address public TOKEN_ADDRESS; 

    // 初始资产比例 - ETH
    uint48 INIT_TOKEN0_AMOUNT;
    
    // 初始资产比例 - TOKEN
    uint48 INIT_TOKEN1_AMOUNT;

    // ERC20 - name
    string public name;
    
    // ERC20 - symbol
    string public symbol;

    // Address of CoFiXDAO
    address _cofixDAO;

    // Address of CoFiXRouter
    address _cofixRouter;

    // 手续费，万分制。20
    uint16 _theta;
    
    // 冲击成本系数。
    uint16 _gamma;

    // 每一单位token（对于二元池，指单位eth）标准出矿量，万分制。1000
    uint32 _nt;

    // Lock flag
    uint8 _unlocked;

    // Address of CoFiXController
    address _cofixController;

    // 累计出矿量
    uint112 _Y;

    // 调整到平衡的交易规模
    uint112 _D;

    // 最后更新区块
    uint32 _lastblock;

    // 构造函数，为了支持openzeeplin的可升级方案，需要将构造函数移到initialize方法中实现
    constructor() {
    }

    /// @dev init 初始化
    /// @param governance ICoFiXGovernance implementation contract address
    /// @param name_ 份额代币名称
    /// @param symbol_ 份额代币代号
    /// @param tokenAddress 资金池代币地址
    /// @param initToken0Amount 初始资产比例 - ETH
    /// @param initToken1Amount 初始资产比例 - TOKEN
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
        _unlocked = 1;
        TOKEN_ADDRESS = tokenAddress;
        INIT_TOKEN0_AMOUNT = initToken0Amount;
        INIT_TOKEN1_AMOUNT = initToken1Amount;
    }

    modifier check() {
        require(_cofixRouter == msg.sender, "CoFiXPair: Only for CoFiXRouter");
        require(_unlocked == 1, "CoFiXPair: LOCKED");
        _unlocked = 0;
        _;
        _unlocked = 1;
        //_update();
    }

    /// @dev 设置参数
    /// @param theta 手续费，万分制。20
    /// @param gamma 冲击成本系数。
    /// @param nt 每一单位token（对于二元池，指单位eth）标准出矿量，万分制。1000
    function setConfig(uint16 theta, uint16 gamma, uint32 nt) external override onlyGovernance {
        // 手续费，万分制。20
        _theta = theta;
        // 冲击成本系数。
        _gamma = gamma;
        // 每一单位token（对于二元池，指单位eth）标准出矿量，万分制。1000
        _nt = nt;
    }

    /// @dev 获取参数
    /// @return theta 手续费，万分制。20
    /// @return gamma 冲击成本系数。
    /// @return nt 每一单位token（对于二元池，指单位eth）标准出矿量，万分制。1000
    function getConfig() external override view returns (uint16 theta, uint16 gamma, uint32 nt) {
        return (_theta, _gamma, _nt);
    }

    /// @dev 获取初始资产比例
    /// @return initToken0Amount 初始资产比例 - ETH
    /// @return initToken1Amount 初始资产比例 - TOKEN
    function getInitialAssetRatio() public override view returns (
        uint initToken0Amount, 
        uint initToken1Amount
    ) {
        return (uint(INIT_TOKEN0_AMOUNT), uint(INIT_TOKEN1_AMOUNT));
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

    /// @dev 添加流动性并增发份额
    /// @param token 目标token地址
    /// @param to 份额接收地址
    /// @param amountETH 要添加的eth数量
    /// @param amountToken 要添加的token数量
    /// @param payback 退回的手续费接收地址
    /// @return xtoken 获得的流动性份额代币地址
    /// @return liquidity 获得的流动性份额
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
        // 1. 验证资金的正确性
        // 确保比例正确
        require(token == TOKEN_ADDRESS, "CoFiXPair: invalid token address");
        //uint initToken0Amount = uint(INIT_TOKEN0_AMOUNT);
        //uint initToken1Amount = uint(INIT_TOKEN1_AMOUNT);
        require(
            amountETH * uint(INIT_TOKEN1_AMOUNT) == amountToken * uint(INIT_TOKEN0_AMOUNT), 
            "CoFiXPair: invalid asset ratio"
        );

        // 2. 计算净值和份额
        uint total = totalSupply;
        if (total > 0) {
            // 3. 调用预言机
            // 计算K值
            // 计算θ
            (
                uint ethAmount, 
                uint tokenAmount, 
                //uint blockNumber, 
            ) = ICoFiXController(_cofixController).queryPrice { 
                // 多余的部分，都作为预言机调用费用
                value: msg.value - amountETH
            } (
                token,
                payback
            );

            // TODO: Pt此处没有引入K值，后续需要引入
            // 做市没有冲击成本
            // 当发行量不为0时，正常发行份额
            liquidity = amountETH * total / _calcTotalValue(
                // 当前eth余额，减去amountETH等于交易前eth余额
                address(this).balance - amountETH, 
                // 当前token余额，减去amountToken等于交易前token余额
                IERC20(token).balanceOf(address(this)) - amountToken,
                // 价格 - eth数量 
                ethAmount, 
                // 价格 - token数量
                tokenAmount,
                uint(INIT_TOKEN0_AMOUNT),
                uint(INIT_TOKEN1_AMOUNT)
            );
        } else {
            payable(payback).transfer(msg.value - amountETH);
            // TODO: 确定基础份额的逻辑
            //liquidity = _calcLiquidity(amountETH, navps) - MINIMUM_LIQUIDITY;
            liquidity = amountETH - MINIMUM_LIQUIDITY;
            // permanently lock the first MINIMUM_LIQUIDITY tokens
            // 当发行量为0时，有一个基础份额
            _mint(address(0), MINIMUM_LIQUIDITY); 
        }

        // 5. 增发份额
        _mint(to, liquidity);
        xtoken = address(this);
        emit Mint(token, to, amountETH, amountToken, liquidity);
    }

    /// @dev 移除流动性并销毁
    /// @param token 目标token地址
    /// @param to 资金接收地址
    /// @param liquidity 需要移除的流动性份额
    /// @param payback 退回的手续费接收地址
    /// @return amountETHOut 获得的eth数量
    /// @return amountTokenOut 获得的token数量
    function burn(
        address token,
        address to, 
        uint liquidity, 
        address payback
    ) external payable override check returns (
        uint amountETHOut,
        uint amountTokenOut 
    ) { 
        require(token == TOKEN_ADDRESS, "CoFiXPair: invalid token address");
        // 1. 调用预言机
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

        // 2. 计算净值，根据净值计算等比资金
        // 计算净值
        uint ethBalance = address(this).balance;
        uint tokenBalance = IERC20(token).balanceOf(address(this));
        uint navps = 1 ether;
        uint total = totalSupply;
        uint initToken0Amount = uint(INIT_TOKEN0_AMOUNT);
        uint initToken1Amount = uint(INIT_TOKEN1_AMOUNT);
        if (total > 0) {
            // Pt此处没有引入K值，后续需要引入
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
        TransferHelper.safeTransfer(token, to, amountTokenOut);

        emit Burn(token, to, liquidity, amountETHOut, amountTokenOut);
    }

    /// @dev 执行兑换交易
    /// @param src 源资产token地址
    /// @param dest 目标资产token地址
    /// @param amountIn 输入源资产数量
    /// @param to 兑换资金接收地址
    /// @param payback 退回的手续费接收地址
    /// @return amountOut 兑换到的目标资产数量
    /// @return mined 出矿量
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
        address token = TOKEN_ADDRESS;
        if (src == address(0) && dest == token) {
            (amountOut, mined) =  _swapForToken(token, amountIn, to, payback);
        } else if (src == token && dest == address(0)) {
            (amountOut, mined) = _swapForETH(token, amountIn, to, payback);
        } else {
            revert("CoFiXPair: pair error");
        }
    }

    /// @dev 用eth兑换token
    /// @param amountIn 兑换的eth数量
    /// @param to 兑换资金接收地址
    /// @param payback 退回的手续费接收地址
    /// @return amountTokenOut 兑换到的token数量
    /// @return mined 出矿量
    function _swapForToken(
        address token,
        uint amountIn, 
        address to, 
        address payback
    ) private returns (
        uint amountTokenOut, 
        uint mined
    ) {
        // 1. 调用预言机获取价格
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
        // 2. 计算兑换结果
        // 2.1. K值计算
        // 2.2. 冲击成本计算
        uint fee = amountIn * uint(_theta) / 10000;
        amountTokenOut = (amountIn - fee) * tokenAmount * 1 ether / ethAmount / (
            1 ether + k + _impactCostForSellOutETH(amountIn, uint(_gamma))
        );

        // 3. 扣除交易手续费
        _collect(fee);

        // 4. 转token给用户
        TransferHelper.safeTransfer(token, to, amountTokenOut);

        // TODO: 如果不检查重入，可能存在通过重入来挖矿的行为
        // 5. 挖矿逻辑
        // 【注意】Pt此处没有引入K值，后续需要引入
        mined = _cofiMint(_calcD(
            address(this).balance, 
            IERC20(token).balanceOf(address(this)), 
            ethAmount, 
            tokenAmount
        ), uint(_nt));

        emit SwapForToken(amountIn, to, amountTokenOut, mined);
    }

    /// @dev 用token兑换eth
    /// @param amountIn 兑换的token数量
    /// @param to 兑换资金接收地址
    /// @param payback 退回的手续费接收地址
    /// @return amountETHOut 兑换到的token数量
    /// @return mined 出矿量
    function _swapForETH(
        address token,
        uint amountIn, 
        address to, 
        address payback
    ) private returns (
        uint amountETHOut, 
        uint mined
    ) {
        // 1. 调用预言机获取价格
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

        // 2. 计算兑换结果
        // 2.1. K值计算
        // 2.2. 冲击成本计算
        amountETHOut = amountIn * ethAmount / tokenAmount;
        //uint C = impactCostForBuyInETH(amountETHOut);
        amountETHOut = amountETHOut * 1 ether / (
            1 ether + k + _impactCostForBuyInETH(amountETHOut, uint(_gamma))
        ); 
        uint fee = amountETHOut * uint(_theta) / 10000;
        amountETHOut = amountETHOut - fee;

        // 3. 扣除交易手续费
        //uint fee = amountETHOut * THETA / (1 ether - THETA);
        _collect(fee);

        // 4. 转token给用户
        payable(to).transfer(amountETHOut);

        // 5. 挖矿逻辑
        // 【注意】Pt此处没有引入K值，后续需要引入
        mined = _cofiMint(_calcD(
            address(this).balance, 
            IERC20(token).balanceOf(address(this)), 
            ethAmount, 
            tokenAmount
        ), uint(_nt));

        emit SwapForETH(amountIn, to, amountETHOut, mined);
    }

    // 计算调整为𝑘0时所需要的ETH交易规模
    function _calcD(
        uint balance0, 
        uint balance1, 
        uint ethAmount, 
        uint tokenAmount
    ) private view returns (uint) {
        uint initToken0Amount = uint(INIT_TOKEN0_AMOUNT);
        uint initToken1Amount = uint(INIT_TOKEN1_AMOUNT);

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

    // 计算CoFi交易挖矿相关的变量并更新对应状态
    function _cofiMint(uint D1, uint nt) private returns (uint mined) {
        // Y_t=Y_(t-1)+D_(t-1)*n_t*(S_t+1)-Z_t                   
        // Z_t=〖[Y〗_(t-1)+D_(t-1)*n_t*(S_t+1)]* v_t
        uint D0 = uint(_D);
        // D0 < D1时，也需要更新Y值
        uint Y = uint(_Y) + D0 * nt * (block.number + 1 - uint(_lastblock)) / 10000;
        if (D0 > D1) {
            mined = Y * (D0 - D1) / D0;
            Y = Y - mined;
        }

        _Y = uint112(Y);
        _D = uint112(D1);
        _lastblock = uint32(block.number);
    }

    /// @dev 预估出矿量
    /// @param newBalance0 新的eth余额
    /// @param newBalance1 新的token余额
    /// @param ethAmount 预言机价格-eth数量
    /// @param tokenAmount 预言机价格-token数量
    /// @return mined 预计出矿量
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
            // D0 < D1时，也需要更新Y值
            uint Y = uint(_Y) + D0 * uint(_nt) * (block.number + 1 - uint(_lastblock)) / 10000;
            mined = Y * (D0 - D1) / D0;
        }
    }

    // 批量存入手续费
    function _collect(uint fee) private {
        // uint totalFee = _totalFee + fee;
        // // 总手续费超过1ETH时才存入
        // if (totalFee >= 1 ether) {
        //     _totalFee = 0;
        //     ICoFiXDAO(_cofixDAO).addETHReward { value: totalFee } (address(this));
        // } 
        // _totalFee = totalFee;
        ICoFiXDAO(_cofixDAO).addETHReward { value: fee } (address(this));
    }

    // 计算净值
    // navps = calcNAVPerShare(reserve0, reserve1, _op.ethAmount, _op.tokenAmount);
    // calc Net Asset Value Per Share (no K)
    // use it in this contract, for optimized gas usage

    /// @dev 计算净值
    /// @param balance0 资金池eth余额
    /// @param balance1 资金池token余额
    /// @param ethAmount 预言机价格-eth数量
    /// @param tokenAmount 预言机价格-token数量
    /// @return navps 净值
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
                INIT_TOKEN0_AMOUNT,
                INIT_TOKEN1_AMOUNT
            ) * 1 ether / totalSupply;
        }
        return 1 ether;
    }

    /// @dev 获取净值
    /// @param ethAmount 预言机价格-eth数量
    /// @param tokenAmount 预言机价格-token数量
    /// @return navps 净值
    function getNAVPerShare(
        uint ethAmount, 
        uint tokenAmount
    ) external view override returns (uint navps) {
        uint total = totalSupply;
        if (total > 0) {
            return _calcTotalValue(
                address(this).balance, 
                IERC20(TOKEN_ADDRESS).balanceOf(address(this)), 
                ethAmount, 
                tokenAmount,
                INIT_TOKEN0_AMOUNT,
                INIT_TOKEN1_AMOUNT
            ) * 1 ether / totalSupply;
        }
        return 1 ether;
    }

    // 计算资产余额总价值
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
        //navps = (ethBalance * INIT_TOKEN0_AMOUNT * tokenAmount + tokenBalance * INIT_TOKEN0_AMOUNT * ethAmount) * 1 ether
        //        / totalSupply / (INIT_TOKEN0_AMOUNT * tokenAmount + INIT_TOKEN1_AMOUNT * ethAmount);

        // NV=(E_t+U_t/P_t)/((1+k_0/P_t ))
        totalValue = (
            balance0 * tokenAmount 
            + balance1 * ethAmount
        ) * uint(initToken0Amount)
        / (
            uint(initToken0Amount) * tokenAmount 
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

    // α=0，β=2e-06
    function impactCostForBuyInETH(uint vol) public view override returns (uint impactCost) {
        return _impactCostForBuyInETH(vol, uint(_gamma));
    }

    // α=0，β=2e-06
    function impactCostForSellOutETH(uint vol) public view override returns (uint impactCost) {
        return _impactCostForSellOutETH(vol, uint(_gamma));
    }

    /// @dev 获取指定token做市获得的份额代币地址
    /// @param token 目标token
    /// @return 如果资金池支持指定的token，返回做市份额代币地址
    function getXToken(address token) external view override returns (address) {
        if (token == TOKEN_ADDRESS) {
            return address(this);
        }
        return address(0);
    }
}
