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
        // token地址
        address tokenAddress;
        // token单位（等于10^decimals）。
        uint96 base;
        // 对应的xtoken地址
        address xtokenAddress;

        uint112 _Y;
        uint112 _D;
        uint32 _LASTBLOCK;
    }

    // it's negligible because we calc liquidity in ETH
    //uint constant MINIMUM_LIQUIDITY = 1e9; 
    //uint constant public THETA = 0.002 ether;

    // n_t为每一单位ETH标准出矿量为，当前n_t=0.1。BASE: 10000
    //uint constant nt = 1000;

    // Configration
    //Config _config;

    // Address of CoFiXDAO
    address _cofixDAO;

    // Address of CoFiXRouter
    address _cofixRouter;

    // 手续费，万分制。20
    uint16 _theta;
    
    // 冲击成本系数。
    uint16 _gama;

    // 每一单位token（对于二元池，指单位eth）标准出矿量，万分制。1000
    uint32 _nt;

    // Lock flag
    uint8 _unlocked = 1;

    TokenInfo[] _tokens;
    mapping(address=>uint) _tokenMapping;

    // 构造函数，为了支持openzeeplin的可升级方案，需要将构造函数移到initialize方法中实现
    constructor () {
        
    }

    function init (
        address governance,
        uint index,
        address[] memory tokens,
        uint96[] memory bases
    ) external {
        super.initialize(governance);
        string memory si = getAddressStr(index);
        // 遍历token，初始化对应的数据
        for (uint i = 0; i < tokens.length; ++i) {
            // 创建TokenInfo
            address token = tokens[i];
            _tokenMapping[token] = _tokens.length;
            TokenInfo storage tokenInfo = _tokens.push();

            // 生成xtoken的name和symbol            
            string memory idx = getAddressStr(i);
            string memory name = strConcat(strConcat(strConcat('XToken-', si), '-'), idx);
            string memory symbol = strConcat(strConcat(strConcat('XT-', si), '-'), idx);

            tokenInfo.tokenAddress = token;
            // 创建xtoken代币
            tokenInfo.xtokenAddress = address(new CoFiXAnchorToken(name, symbol, address(this)));
            tokenInfo.base = bases[i];
        }
    }

    modifier check() {
        require(_cofixRouter == msg.sender, "CoFiXPair: Only for CoFiXRouter");
        require(_unlocked == 1, "CPair: LOCKED");
        _unlocked = 0;
        _;
        _unlocked = 1;
        //_update();
    }

    /// @dev 设置参数
    /// @param theta 手续费，万分制。20
    /// @param gama 冲击成本系数。
    /// @param nt 每一单位token（对于二元池，指单位eth）标准出矿量，万分制。1000
    function setConfig(uint16 theta, uint16 gama, uint32 nt) external override onlyGovernance {
        // 手续费，万分制。20
        _theta = theta;
        // 冲击成本系数。
        _gama = gama;
        // 每一单位token（对于二元池，指单位eth）标准出矿量，万分制。1000
        _nt = nt;
    }

    /// @dev 获取参数
    /// @return theta 手续费，万分制。20
    /// @return gama 冲击成本系数。
    /// @return nt 每一单位token（对于二元池，指单位eth）标准出矿量，万分制。1000
    function getConfig() external override view returns (uint16 theta, uint16 gama, uint32 nt) {
        return (_theta, _gama, _nt);
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

    // 给目标地址转账，token为0地址表示转eth
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

        // 2. 退回多余的eth
        // token为0，代表转入的是eth，需要将超过amountToken的部分退回
        if (token == address(0)) {
            _transfer(address(0), payback, msg.value - amountToken);
        } 
        // token不为0，代表转入的是token，需要将转入的eth全部退回
        else if (msg.value > 0) {
            payable(payback).transfer(msg.value);
        }

        // 3. 加载token对应的结构数据
        TokenInfo storage tokenInfo = _tokens[_tokenMapping[token]];
        xtoken = tokenInfo.xtokenAddress;

        // 4. 增发份额
        //liquidity = amountToken * 1 ether / uint(tokenInfo.base);
        liquidity = CoFiXAnchorToken(xtoken).mint(to, amountToken * 1 ether / uint(tokenInfo.base));
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
        // 1. 退回多余的eth
        if (msg.value > 0) {
            payable(payback).transfer(msg.value);
        }

        // TODO: 赎回时需要计算冲击成本
        // TODO: 确定赎回的时候是否有手续费逻辑

        // 2. 加载token对应的结构数据
        TokenInfo storage tokenInfo = _tokens[_tokenMapping[token]];
        uint base = uint(tokenInfo.base);

        // 计算净值，根据净值计算等比资金
        amountTokenOut = liquidity * 1 ether / base;
        amountETHOut = 0;

        // 3. 销毁份额
        CoFiXAnchorToken(tokenInfo.xtokenAddress).burn(address(this), liquidity);
        emit Burn(token, to, liquidity, amountTokenOut, amountETHOut);

        // 4. 根据资金池剩余情况进行调整
        uint balance = IERC20(token).balanceOf(address(this));
        while (liquidity > 0) {
            // 需要给用户支付的token数量
            uint need = liquidity * base / 1 ether;
            // 余额足够，直接将token转给用户，并结束
            if (need <= balance) {
                _transfer(token, to, need);
                break;
            }

            // 余额不够，将余额全部转给用户
            _transfer(token, to, balance);
            // 扣除已转token后，剩余份额
            liquidity -= balance * 1 ether / base;

            // 遍历token，找到余额最大的资金
            uint max = 0;
            uint length = _tokens.length;
            for (uint i = 0; i < length; ++i) {
                // 加载token
                tokenInfo = _tokens[i];
                address ta = tokenInfo.tokenAddress;
                // token和刚才处理的token不能相同
                if (ta != token) {
                    // 找到token的余额最大的，更新
                    uint b = IERC20(ta).balanceOf(address(this));
                    if (max < b) {
                        // 更新base
                        base = uint(tokenInfo.base);
                        // 更新balance
                        balance = b;
                        // 更新max
                        max = b * 1 ether / base;
                        // 更新token地址
                        token = ta;
                        // 更新token信息
                        //tokenInfo = ti;
                    }
                }
            }
        }
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
        // 1. 退回多余的eth
        // src为0，代表转入的是eth，需要将超过amountToken的部分退回
        if (src == address(0)) {
            _transfer(address(0), payback, msg.value - amountIn);
        } 
        // src不为0，代表转入的是token，需要将转入的eth全部退回
        else if (msg.value > 0) {
            payable(payback).transfer(msg.value);
        }
        
        // 2. 加载token对应的结构数据
        TokenInfo storage tokenInfo0 = _tokens[_tokenMapping[src]];
        TokenInfo storage tokenInfo1 = _tokens[_tokenMapping[dest]];
        uint base0 = uint(tokenInfo0.base);
        uint base1 = uint(tokenInfo1.base);

        // 3. 计算兑换的token数量和手续费
        amountOut = amountIn * base1 / base0;
        uint fee = amountOut * uint(_theta) / 10000;
        amountOut = amountOut - fee;

        // 4. 转换得的token和手续费
        _transfer(dest, to, amountOut);
        _transfer(dest, _cofixDAO, fee);

        // 5. 挖矿逻辑
        mined = _cofiMint(tokenInfo0, base0) + _cofiMint(tokenInfo1, base1);

        // console.log('------------------------------------------------------------');
        // console.log('CoFiXPair-swap src:', src);
        // console.log('CoFiXPair-swap dest:', dest);
        // console.log('CoFiXPair-swap src->dest:', _tokenName(src), '->', _tokenName(dest));
        // console.log('CoFiXAnchorPool-swap amountIn->amountOut:', amountIn, '->', amountOut);
        // console.log('CoFiXAnchorPool-swap to:', to);
        // console.log('CoFiXAnchorPool-swap mined:', mined);
    }

    function _tokenName(address token) private view returns (string memory) {
        if (token == address(0)) {
            return 'eth';
        }
        return ERC20(token).name();
    }
    mapping(address=>uint) _balances;
    function _update() private {
        for(uint i = 0; i < _tokens.length; ++i) {
            uint balance;
            TokenInfo memory ti = _tokens[i];
            if (ti.tokenAddress == address(0)) {
                balance = address(this).balance;
            } else {
                balance = IERC20(ti.tokenAddress).balanceOf(address(this));
            }
            if (balance > _balances[ti.tokenAddress]) {
                console.log('CoFiXAnchorPool-swap D', ti.tokenAddress, balance - _balances[ti.tokenAddress]);
            } else {
                console.log('CoFiXAnchorPool-swap D', ti.tokenAddress, '-', _balances[ti.tokenAddress] - balance);
            }
            _balances[ti.tokenAddress] = balance;
        }
    }

    // 计算CoFi交易挖矿相关的变量并更新对应状态
    function _cofiMint(TokenInfo storage tokenInfo, uint base) private returns (uint mined) {

        // 1. 获取份额数
        uint L = IERC20(tokenInfo.xtokenAddress).totalSupply();

        // 2. 获取当前token余额并转换成对应的份额数量
        // TODO: 分析有人故意往资金池注入资金的攻击的可能
        uint x = IERC20(tokenInfo.tokenAddress).balanceOf(address(this)) * 1 ether / base;
        
        // 3. 计算调整规模
        uint D1 = L > x ? L - x : x - L;

        // 4. 根据交易前后的调整规模计算出矿数据
        // Y_t=Y_(t-1)+D_(t-1)*n_t*(S_t+1)-Z_t                   
        // Z_t=〖[Y〗_(t-1)+D_(t-1)*n_t*(S_t+1)]* v_t
        uint D0 = uint(tokenInfo._D);
        // D0 < D1时，也需要更新Y值
        uint Y = uint(tokenInfo._Y) + D0 * uint(_nt) * (block.number + 1 - uint(tokenInfo._LASTBLOCK)) / 10000;
        if (D0 > D1) {
            mined = Y * (D0 - D1) / D0;
            Y = Y - mined;
        }

        // 5. 更新出矿参数
        tokenInfo._Y = uint112(Y);
        tokenInfo._D = uint112(D1);
        tokenInfo._LASTBLOCK = uint32(block.number);
    }

    // // use it in this contract, for optimized gas usage
    // function _calcLiquidity(uint amount0, uint navps) private pure returns (uint liquidity) {
    //     liquidity = amount0 * 1 ether / navps;
    // }

    /// @dev 获取指定token做市获得的份额代币地址
    /// @param token 目标token
    /// @return 如果资金池支持指定的token，返回做市份额代币地址
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
