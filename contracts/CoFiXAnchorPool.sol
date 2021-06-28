// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "./libs/IERC20.sol";
import "./libs/ERC20.sol";
import "./libs/TransferHelper.sol";

import "./interfaces/ICoFiXPool.sol";
import "./interfaces/ICoFiXController.sol";
import "./interfaces/ICoFiXDAO.sol";

import "./CoFiXBase.sol";
import "./CoFiToken.sol";
import "./CoFiXAnchorToken.sol";

import "hardhat/console.sol";

/// @dev 锚定池
contract CoFiXAnchorPool is CoFiXBase, ICoFiXPool {

    struct TokenInfo {
        address tokenAddress;
        uint96 base;
        address xtokenAddress;
        uint96 initAmount;
        uint112 _Y;
        uint112 _D;
        uint32 _LASTBLOCK;
    }

    // it's negligible because we calc liquidity in ETH
    uint constant MINIMUM_LIQUIDITY = 1e9; 
    uint constant public THETA = 0.002 ether;

    // n_t为每一单位ETH标准出矿量为，当前n_t=0.1。BASE: 10000
    uint constant nt = 1000;

    // Configration
    //Config _config;

    // Address of CoFiXDAO
    address _cofixDAO;

    // Address of CoFiXRouter
    address _cofixRouter;

    // Lock flag
    uint8 _unlocked = 1;

    uint _totalFee;

    TokenInfo[] _tokens;
    mapping(address=>uint) _tokenMapping;

    // 构造函数，为了支持openzeeplin的可升级方案，需要将构造函数移到initialize方法中实现
    constructor (
        uint index,
        address[] memory tokens,
        uint[] memory bases
    ) {
        string memory si = getAddressStr(index);
        for (uint i = 0; i < tokens.length; ++i) {
            address token = tokens[i];
            _tokenMapping[token] = _tokens.length;
            TokenInfo storage ti = _tokens.push();
            
            string memory idx = getAddressStr(i);
            string memory name = strConcat(strConcat(strConcat('XToken-', si), '-'), idx);
            string memory symbol = strConcat(strConcat(strConcat('XT-', si), '-'), idx);
            address xtokenAddress = address(new CoFiXAnchorToken(name, symbol, address(this)));
            ti.tokenAddress = token;
            ti.base = uint96(bases[i]);
            ti.xtokenAddress = xtokenAddress;
            ti.initAmount = uint96(0);
        }
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
            ,//_cofixController,
            //cofixVaultForStaking
        ) = ICoFiXGovernance(newGovernance).getBuiltinAddress();
    }

    function _transfer(address token, address to, uint value) private {
        if (value > 0) {
            if (token == address(0)) {
                payable(to).transfer(value);
            } else {
                TransferHelper.safeTransfer(token, to, value);
            }
        }
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
        require(amountETH == 0, "CPair: invalid asset ratio");

        // 2. 调用预言机
        // 计算K值
        // 计算θ
        if (token == address(0)) {
            _transfer(address(0), payback, msg.value - amountToken);
        } else if (msg.value > 0) {
            payable(payback).transfer(msg.value);
        }

        // 3. 计算净值和份额
        TokenInfo storage ti = _tokens[_tokenMapping[token]];
        uint base = ti.base;
        xtoken = ti.xtokenAddress;
        //uint navps = 1 ether;
        uint total = CoFiXAnchorToken(xtoken).totalSupply();
        liquidity = amountToken * 1 ether / base;
        if (total > 0) {
            // 当发行量不为0时，正常发行份额
            //liquidity = _calcLiquidity(amountETH, navps);
        } else {
            // TODO: 确定基础份额的逻辑
            liquidity -= MINIMUM_LIQUIDITY;
            // permanently lock the first MINIMUM_LIQUIDITY tokens
            // 当发行量为0时，有一个基础份额
            CoFiXAnchorToken(xtoken).mint(address(0), MINIMUM_LIQUIDITY); 
        }

        // // 份额必须大于0
        // require(liquidity > 0, "CPair: SHORT_LIQUIDITY_MINTED");

        // 5. 增发份额
        CoFiXAnchorToken(xtoken).mint(to, liquidity);
        emit Mint(token, to, amountETH, amountToken, liquidity);
    }

    // 销毁流动性
    // this low-level function should be called from a contract which performs important safety checks
    /// @dev 移除流动性并销毁
    /// @param token 目标token地址
    /// @param to 资金接收地址
    /// @param liquidity 需要移除的流动性份额
    /// @param payback 退回的手续费接收地址
    /// @return amountTokenOut 获得的token数量
    /// @return amountETHOut 获得的eth数量
    function burn(
        address token,
        address to, 
        uint liquidity, 
        address payback
    ) external payable override check returns (
        uint amountTokenOut, 
        uint amountETHOut
    ) { 
        // 1. 调用预言机
        if (msg.value > 0) {
            payable(payback).transfer(msg.value);
        }

        // 2. 计算净值，根据净值计算等比资金
        // 计算净值
        uint navps = 1 ether;
        // TODO: 赎回时需要计算冲击成本
        // TODO: 确定赎回的时候是否有手续费逻辑
        amountTokenOut = navps * liquidity / 1 ether;

        // 3. 销毁份额
        CoFiXAnchorToken(_tokens[_tokenMapping[token]].xtokenAddress).burn(address(this), liquidity);

        // 4. TODO: 根据资金池剩余情况进行调整

        // 5. 资金转入用户指定地址
        //TransferHelper.safeTransfer(token, to, amountTokenOut);
        _transfer(token, to, amountTokenOut);

        emit Burn(token, to, liquidity, amountTokenOut, amountETHOut);
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
        if (src == address(0)) {
            _transfer(address(0), payback, msg.value - amountIn);
        } else if (msg.value > 0) {
            payable(payback).transfer(msg.value);
        }
        
        TokenInfo storage token0 = _tokens[_tokenMapping[src]];
        TokenInfo storage token1 = _tokens[_tokenMapping[dest]];
        amountOut = amountIn * token1.base / token0.base;
        uint fee = amountOut * THETA / 1 ether;

        _transfer(dest, to, amountOut - fee);
        _transfer(dest, _cofixDAO, fee);

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

    // // use it in this contract, for optimized gas usage
    // function _calcLiquidity(uint amount0, uint navps) private pure returns (uint liquidity) {
    //     liquidity = amount0 * 1 ether / navps;
    // }

    function getXToken(address token) external view override returns (address) {
        return _tokens[_tokenMapping[token]].xtokenAddress;
    }

    /// @dev from NESTv3.0
    function strConcat(string memory _a, string memory _b) private pure returns (string memory)
    {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ret = new string(_ba.length + _bb.length);
        bytes memory bret = bytes(ret);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) {
            bret[k++] = _ba[i];
        } 
        for (uint i = 0; i < _bb.length; i++) {
            bret[k++] = _bb[i];
        } 
        return string(ret);
    } 
    
    /// @dev Convert number into a string, if less than 4 digits, make up 0 in front, from NestV3.0
    function getAddressStr(uint iv) private pure returns (string memory) 
    {
        bytes memory buf = new bytes(64);
        uint index = 0;
        do {
            buf[index++] = bytes1(uint8(iv % 10 + 48));
            iv /= 10;
        } while (iv > 0);
        bytes memory str = new bytes(index);
        for(uint i = 0; i < index; ++i) {
            str[i] = buf[index - i - 1];
        }
        return string(str);
    }
}
