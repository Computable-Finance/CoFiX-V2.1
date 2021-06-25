// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "./libs/IERC20.sol";
import "./libs/TransferHelper.sol";

import "./interfaces/ICoFiXPool.sol";
import "./interfaces/ICoFiXController.sol";
import "./interfaces/ICoFiXDAO.sol";

import "./CoFiXBase.sol";
import "./CoFiToken.sol";
import "./CoFiXERC20.sol";

import "hardhat/console.sol";

/// @dev TOKEN/PTOKEN资产交易对
contract MultiCoFiXPool is CoFiXBase, ICoFiXPool, CoFiXERC20 {

    struct TokenInfo {
        address tokenAddress;
        uint base;
        uint initAmount;
        uint112 _Y;
        uint112 _D;
        uint32 _LASTBLOCK;
    }

    // it's negligible because we calc liquidity in ETH
    uint constant MINIMUM_LIQUIDITY = 10e9; 
    uint constant public THETA = 0.002 ether;

    // n_t为每一单位ETH标准出矿量为，当前n_t=0.1。BASE: 10000
    uint constant nt = 1000;

    // ERC20 - name
    string public name;
    
    // ERC20 - symbol
    string public symbol;

    // Configration
    //Config _config;

    // Address of CoFiXDAO
    address _cofixDAO;

    // Address of CoFiXRouter
    address _cofixRouter;

    // Lock flag
    uint8 _unlocked = 1;

    // TODO: 将CoFiXController合并到CoFiXRouter中
    // Address of CoFiXController
    address _cofixController;

    uint _totalFee;

    TokenInfo[] _tokens;
    mapping(address=>uint) _tokenMapping;

    // 构造函数，为了支持openzeeplin的可升级方案，需要将构造函数移到initialize方法中实现
    constructor (
        string memory name_, 
        string memory symbol_
    ) {
        name = name_;
        symbol = symbol_;
    }

    modifier check() {
        require(_cofixRouter == msg.sender, "CoFiXPair: Only for CoFiXRouter");
        require(_unlocked == 1, "CPair: LOCKED");
        _unlocked = 0;
        _;
        _unlocked = 1;
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
        require(amountETH == 0, "CPair: invalid asset ratio");

        // 2. 调用预言机
        // 计算K值
        // 计算θ
        // (
        //     uint ethAmount, 
        //     uint tokenAmount, 
        //     //uint blockNum, 
        // ) = ICoFiXController(_cofixController).queryPrice { 
        //     // 多余的部分，都作为预言机调用费用
        //     value: msg.value - amountETH
        // } (
        //     TOKEN1_ADDRESS,
        //     payback
        // );
        if (msg.value > 0) {
            payable(payback).transfer(msg.value);
        }

        // 3. 计算净值和份额
        uint navps = 1 ether;
        uint total = totalSupply;
        if (total > 0) {
            // // TODO: Pt此处没有引入K值，后续需要引入
            // navps = _calcTotalValue(
            //     // 当前eth余额，减去amountETH等于交易前eth余额
            //     address(this).balance - amountETH, 
            //     // 当前token余额，减去amountToken等于交易前token余额
            //     IERC20(TOKEN1_ADDRESS).balanceOf(address(this)) - amountToken,
            //     // 价格 - eth数量 
            //     ethAmount, 
            //     // 价格 - token数量
            //     tokenAmount
            // ) * 1 ether / total;

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
        // (
        //     uint ethAmount, 
        //     uint tokenAmount, 
        //     //uint blockNum, 
        // ) = ICoFiXController(_cofixController).queryPrice { 
        //     value: msg.value 
        // } (
        //     TOKEN1_ADDRESS,
        //     payback
        // );
        if (msg.value > 0) {
            payable(payback).transfer(msg.value);
        }

        // 2. 计算净值，根据净值计算等比资金
        // 计算净值
        uint navps = 1 ether;
        //uint total = totalSupply;
        // if (total > 0) {
        //     // Pt此处没有引入K值，后续需要引入
        //     navps = _calcTotalValue(
        //         ethBalance, 
        //         tokenBalance, 
        //         ethAmount, 
        //         tokenAmount
        //     ) * 1 ether / total;
        // }

        // TODO: 赎回时需要计算冲击成本
        // TODO: 确定赎回的时候是否有手续费逻辑
        amountTokenOut = navps * liquidity / 1 ether;

        // 3. 销毁份额
        _burn(address(this), liquidity);

        // 4. TODO: 根据资金池剩余情况进行调整

        // 5. 资金转入用户指定地址
        TransferHelper.safeTransfer(address(0), to, amountTokenOut);

        emit Burn(to, liquidity, amountTokenOut, amountETHOut);
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
    ) external payable override returns (
        uint amountOut, 
        uint mined
    ) {
        TokenInfo storage token0 = _tokens[_tokenMapping[src]];
        TokenInfo storage token1 = _tokens[_tokenMapping[dest]];

        uint amountOut = amountIn * token1.base / token0.base;
        IERC20(dest).transfer(to, amountOut);
        IERC20(dest).transfer(_cofixDAO, amountOut * THETA / 1 ether);

        mined = _cofiMint(token0) + _cofiMint(token1);

        amountOut = amountOut * (1 ether - THETA) / 1 ether;
    }

    // 计算CoFi交易挖矿相关的变量并更新对应状态
    function _cofiMint(TokenInfo storage ti) private returns (uint mined) {

        uint D1;
        {
            uint L = ti.initAmount;
            
            // TODO: 有人故意往资金池注入资金的攻击的可能
            uint x = IERC20(ti.tokenAddress).balanceOf(address(this));
            
            D1 = L > x ? L - x : x - L;
        }

        // Y_t=Y_(t-1)+D_(t-1)*n_t*(S_t+1)-Z_t                   
        // Z_t=〖[Y〗_(t-1)+D_(t-1)*n_t*(S_t+1)]* v_t
        uint D0 = uint(ti._D);

        // D0 < D1时，也需要更新Y值
        uint Y = uint(ti._Y) + D0 * nt * (block.number + 1 - uint(ti._LASTBLOCK)) / 10000;
        if (D0 > D1) {
            mined = Y * (D0 - D1) / D0;
            Y = Y - mined;
        }

        ti._Y = uint112(Y);
        ti._D = uint112(D1);
        ti._LASTBLOCK = uint32(block.number);
    }

    // use it in this contract, for optimized gas usage
    function _calcLiquidity(uint amount0, uint navps) private pure returns (uint liquidity) {
        liquidity = amount0 * 1 ether / navps;
    }
}
