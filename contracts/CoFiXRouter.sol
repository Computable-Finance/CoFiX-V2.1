// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "./libs/IERC20.sol";
import "./libs/TransferHelper.sol";

import "./interfaces/ICoFiXRouter.sol";
import "./interfaces/ICoFiXPool.sol";
import "./interfaces/ICoFiXVaultForStaking.sol";

import "./CoFiXBase.sol";
import "./CoFiToken.sol";

import "hardhat/console.sol";

/// @dev Router contract to interact with each CoFiXPair
contract CoFiXRouter is CoFiXBase, ICoFiXRouter {

    // 记录CNode的累计交易挖矿分成
    uint _cnodeReward;

    // Address of CoFiXVaultForStaing
    address _cofixVaultForStaking;

    // Mapping for trade pairs. keccak256(token0, token1)=>pair
    mapping(bytes32=>address) _pairs;

    // Mapping for trade paths. keccak256(token0, token1) = > path
    mapping(bytes32=>address[]) _paths;

    /// @dev Create CoFiXRouter
    constructor () {

    }

    // 验证时间没有超过截止时间
    modifier ensure(uint deadline) {
        require(block.timestamp <= deadline, "CoFiXRouter: EXPIRED");
        _;
    }

    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(nestGovernanceAddress) when overriding, and override method without onlyGovernance
    /// @param newGovernance INestGovernance implementation contract address
    function update(address newGovernance) public override {
        super.update(newGovernance);
        _cofixVaultForStaking = ICoFiXGovernance(newGovernance).getCoFiXVaultForStakingAddress();
    }

    /// @dev 注册交易对
    /// @param token0 交易对token0。（0地址表示eth）
    /// @param token1 交易对token1。（0地址表示eth）
    /// @param pool 交易对资金池
    function registerPair(address token0, address token1, address pool) public override onlyGovernance {
        _pairs[_getKey(token0, token1)] = pool;
    }

    /// @dev 根据token地址对获取交易资金池
    /// @param token0 交易对token0。（0地址表示eth）
    /// @param token1 交易对token1。（0地址表示eth）
    /// @return pool 交易资金池
    function pairFor(address token0, address token1) external view override returns (address pool) {
        return _pairFor(token0, token1);
    }

    /// @dev 注册路由路径
    /// @param src 源token地址
    /// @param dest 目标token地址
    /// @param path 路由地址
    function registerRouterPath(address src, address dest, address[] calldata path) external override onlyGovernance {
        // 检查源地址和目标地址是否正确
        require(src == path[0], "CoFiXRouter: first token error");
        require(dest == path[path.length - 1], "CoFiXRouter: last token error");
        // 注册路由路径
        _paths[_getKey(src, dest)] = path;
    }

    /// @dev 查找从源token地址到目标token地址的路由路径
    /// @param src 源token地址
    /// @param dest 目标token地址
    /// @return path 如果找到，返回路由路径，数组中的每一个地址表示兑换过程中经历的token地址。
    function getRouterPath(address src, address dest) external view override returns (address[] memory path) {
        // 获取路由路径
        path = _paths[_getKey(src, dest)];
        uint j = path.length;
        // 如果是反向路径，则将路径反向
        if (src == path[--j] && dest == path[0]) {
            for (uint i = 0; i < j;) {
                address tmp = path[i];
                path[i++] = path[j];
                path[j--] = tmp;
            }
        } else {
            require(src == path[0] && dest == path[j], 'CoFiXRouter: path error');
        }
    }
    
    /// @dev 根据token地址对获取交易资金池
    /// @param token0 交易对token0。（0地址表示eth）
    /// @param token1 交易对token1。（0地址表示eth）
    /// @return pool 交易资金池
    function _pairFor(address token0, address token1) private view returns (address pool) {
        return _pairs[_getKey(token0, token1)];
    }

    // 根据token地址生成映射key
    function _getKey(address token0, address token1) private pure returns (bytes32) {
        (token0, token1) = _sort(token0, token1);
        return keccak256(abi.encodePacked(token0, token1));
    }

    // 对地址进行排序
    function _sort(address token0, address token1) private pure returns (address min, address max) {
        if (token0 < token1) {
            min = token0;
            max = token1;
        } else {
            min = token1;
            max = token0;
        }
    }

    /// @dev Maker add liquidity to pool, get pool token (mint XToken to maker) (notice: msg.value = amountETH + oracle fee)
    /// @param  pool The address of pool
    /// @param  token The address of ERC20 Token
    /// @param  amountETH The amount of ETH added to pool. (When pool is AnchorPool, amountETH is 0)
    /// @param  amountToken The amount of Token added to pool
    /// @param  liquidityMin The minimum liquidity maker wanted
    /// @param  to The target address receiving the liquidity pool (XToken)
    /// @param  deadline The dealine of this request
    /// @return xtoken 获得的流动性份额代币地址
    /// @return liquidity The real liquidity or XToken minted from pool
    function addLiquidity(
        address pool,
        address token,
        uint amountETH,
        uint amountToken,
        uint liquidityMin,
        address to,
        uint deadline
    ) external override payable ensure(deadline) returns (address xtoken, uint liquidity)
    {
        // 0. 找到交易对合约
        //address pair = pool; //_pairFor(address(0), token);
        
        // 1. 转入资金
        // 收取token
        TransferHelper.safeTransferFrom(token, msg.sender, pool, amountToken);

        // 2. 做市
        // 生成份额
        (xtoken, liquidity) = ICoFiXPool(pool).mint { 
            value: msg.value 
        } (token, to, amountETH, amountToken, msg.sender);

        // 份额数不能低于预期最小值
        require(liquidity >= liquidityMin, "CoFiXRouter: less liquidity than expected");
    }

    /// @dev Maker add liquidity to pool, get pool token (mint XToken) and stake automatically (notice: msg.value = amountETH + oracle fee)
    /// @param  pool The address of pool
    /// @param  token The address of ERC20 Token
    /// @param  amountETH The amount of ETH added to pool. (When pool is AnchorPool, amountETH is 0)
    /// @param  amountToken The amount of Token added to pool
    /// @param  liquidityMin The minimum liquidity maker wanted
    /// @param  to The target address receiving the liquidity pool (XToken)
    /// @param  deadline The dealine of this request
    /// @return xtoken 获得的流动性份额代币地址
    /// @return liquidity The real liquidity or XToken minted from pool
    function addLiquidityAndStake(
        address pool,
        address token,
        uint amountETH,
        uint amountToken,
        uint liquidityMin,
        address to,
        uint deadline
    ) external override payable ensure(deadline) returns (address xtoken, uint liquidity)
    {
        // 0. 找到交易对合约
        //address pair = pool; //_pairFor(address(0), token);
        
        // 1. 转入资金
        // 收取token
        TransferHelper.safeTransferFrom(token, msg.sender, pool, amountToken);

        // 2. 做市
        // 生成份额
        address cofixVaultForStaking = _cofixVaultForStaking;
        (xtoken, liquidity) = ICoFiXPool(pool).mint { 
            value: msg.value 
        } (token, cofixVaultForStaking, amountETH, amountToken, msg.sender);

        // 份额数不能低于预期最小值
        require(liquidity >= liquidityMin, "CoFiXRouter: less liquidity than expected");

        // 3. 存入份额
        ICoFiXVaultForStaking(cofixVaultForStaking).routerStake(xtoken, to, liquidity);
    }

    /// @dev Maker remove liquidity from pool to get ERC20 Token and ETH back (maker burn XToken) (notice: msg.value = oracle fee)
    /// @param  pool The address of pool
    /// @param  token The address of ERC20 Token
    /// @param  liquidity The amount of liquidity (XToken) sent to pool, or the liquidity to remove
    /// @param  amountETHMin The minimum amount of ETH wanted to get from pool
    /// @param  to The target address receiving the Token
    /// @param  deadline The dealine of this request
    /// @return amountToken The real amount of Token transferred from the pool
    /// @return amountETH The real amount of ETH transferred from the pool
    function removeLiquidityGetTokenAndETH(
        address pool,
        // 要移除的token对
        address token,
        // 移除的额度
        uint liquidity,
        // 预期最少可以获得的eth数量
        uint amountETHMin,
        // 接收地址
        address to,
        // 截止时间
        uint deadline
    ) external override payable ensure(deadline) returns (uint amountToken, uint amountETH) 
    {
        // 0. 找到交易对
        //address pair =  pool; //_pairFor(address(0), token);
        address xtoken = ICoFiXPool(pool).getXToken(token);

        // 1. 转入份额
        TransferHelper.safeTransferFrom(xtoken, msg.sender, pool, liquidity);

        // 2. 移除流动性并返还资金
        (amountToken, amountETH) = ICoFiXPool(pool).burn {
            value: msg.value
        } (token, to, liquidity, msg.sender);

        // 3. 得到的ETH不能少于期望值
        require(amountETH >= amountETHMin, "CoFiXRouter: less eth than expected");
    }

    /// @dev Trader swap exact amount of ETH for ERC20 Tokens (notice: msg.value = amountIn + oracle fee)
    /// @param  token The address of ERC20 Token
    /// @param  amountIn The exact amount of ETH a trader want to swap into pool
    /// @param  amountOutMin The minimum amount of Token a trader want to swap out of pool
    /// @param  to The target address receiving the Token
    /// @param  rewardTo The target address receiving the CoFi Token as rewards
    /// @param  deadline The dealine of this request
    /// @return amountOut The real amount of Token transferred out of pool
    function swapExactETHForTokens(
        address token,
        uint amountIn,
        uint amountOutMin,
        address to,
        address rewardTo,
        uint deadline
    ) external override payable ensure(deadline) returns (uint amountOut)
    {
        // 0. 找到交易对
        address pair = _pairFor(address(0), token);

        // 1. 执行交易
        uint mined;
        (amountOut, mined) = ICoFiXPool(pair).swap {
            value: msg.value
        } (address(0), token, amountIn, to, msg.sender);
        
        // 2. 得到的token数量不能少于期望值
        require(amountOut >= amountOutMin, "CoFiXRouter: got less eth than expected");

        // 3. 交易挖矿
        // uint cnodeReward = mined * uint(_config.cnodeRewardRate) / 10000;
        // // 交易者可以获得的数量
        // CoFiToken(COFI_TOKEN_ADDRESS).mint(rewardTo, mined - cnodeReward);
        // // CNode分成
        // _cnodeReward += cnodeReward;
        _mint(mined, rewardTo);
    }

    /// @dev Trader swap exact amount of ERC20 Tokens for ETH (notice: msg.value = oracle fee)
    /// @param  token The address of ERC20 Token
    /// @param  amountIn The exact amount of Token a trader want to swap into pool
    /// @param  amountOutMin The mininum amount of ETH a trader want to swap out of pool
    /// @param  to The target address receiving the ETH
    /// @param  rewardTo The target address receiving the CoFi Token as rewards
    /// @param  deadline The dealine of this request
    /// @return amountOut The real amount of ETH transferred out of pool
    function swapExactTokensForETH(
        address token,
        uint amountIn,
        uint amountOutMin,
        address to,
        address rewardTo,
        uint deadline
    ) external override payable ensure(deadline) returns (uint amountOut)
    {
        // 0. 找到交易对
        address pair = _pairFor(address(0), token);

        // 1. 转入token并执行交易
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountIn);
        uint mined;
        (amountOut, mined) = ICoFiXPool(pair).swap {
            value: msg.value
        } (token, address(0), amountIn, to, msg.sender);

        // 2. 得到的eth数量不能少于期望值
        require(amountOut >= amountOutMin);

        // 3. 交易挖矿
        // uint cnodeReward = mined * uint(_config.cnodeRewardRate) / 10000;
        // // 交易者可以获得的数量
        // CoFiToken(COFI_TOKEN_ADDRESS).mint(rewardTo, mined - cnodeReward);
        // // CNode分成
        // _cnodeReward += cnodeReward;
        _mint(mined, rewardTo);
    }

    /// @dev 多级路由兑换
    /// @param  path 路由路径
    /// @param  amountIn The exact amount of Token a trader want to swap into pool
    /// @param  amountOutMin The mininum amount of ETH a trader want to swap out of pool
    /// @param  to The target address receiving the ETH
    /// @param  rewardTo The target address receiving the CoFi Token as rewards
    /// @param  deadline The dealine of this request
    /// @return amounts 兑换路径中每次换得的资产数量
    function swapExactTokensForTokens(
        address[] calldata path,
        uint amountIn,
        uint amountOutMin,
        address to,
        address rewardTo,
        uint deadline
    ) external payable override ensure(deadline) returns (uint[] memory amounts) {
        // 1. 转入资金
        // 获取token0
        address token = path[0];
        // token0不为0表示token，需要转入
        // if (token != address(0)) {
        //     TransferHelper.safeTransferFrom(token, msg.sender, address(this), amountIn);
        // }

        // 2. 执行兑换交易
        // 记录总出矿量
        uint totalMined = 0;
        // 进行兑换交易
        (amounts, totalMined) = _swap(path, amountIn, to);

        // 3. 资金转给to地址
        // 获取最后的token
        token = path[path.length - 1];
        // 最后兑换的获取数量
        uint amountOut = amounts[amounts.length - 1];
        // 资金转到to地址
        if (token == address(0)) {
            payable(to).transfer(address(this).balance);
        } 
        // else {
        //     //TransferHelper.safeTransfer(token, to, amountOut);
        // }
        require(amountOut >= amountOutMin, "CoFiXRouter: got less than expected");

        // 4. 交易挖矿
        // uint cnodeReward = totalMined * uint(_config.cnodeRewardRate) / 10000;
        // // 交易者可以获得的数量
        // CoFiToken(COFI_TOKEN_ADDRESS).mint(rewardTo, totalMined - cnodeReward);
        // // CNode分成
        // _cnodeReward += cnodeReward;
        _mint(totalMined, rewardTo);
    }

    // 执行兑换交易
    function _swap(
        address[] calldata path,
        uint amountIn,
        address to
    ) private returns (
        uint[] memory amounts, 
        uint totalMined
    ) {
        // 出矿量
        uint mined;
        // 每次兑换获得的资金量数组
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        totalMined = 0;
        
        address token0 = path[0];
        address token1 = path[1];
        address pair = _pairFor(token0, token1);
        if (token0 != address(0)) {
            TransferHelper.safeTransferFrom(token0, to, pair, amountIn);
        }
        for (uint i = 1; ; ) {
            address next = to;
            address token;
            if (++i < path.length) {
                token = path[i];
                next = _pairFor(token1, token);
            }
            // 执行兑换交易
            (amountIn, mined) = ICoFiXPool(pair).swap {
                value: address(this).balance
            } (token0, token1, amountIn, token1 == address(0) ? address(this) : next, address(this));

            // 汇总交易结果
            totalMined += mined;
            amounts[i - 1] = amountIn;

            if (i == path.length) {
                break;
            }

            token0 = token1;
            token1 = token;
            pair = next;
        }
    }

    function _mint(uint mined, address rewardTo) private {
        if (mined > 0) {
            uint cnodeReward = mined / 10;
            // 交易者可以获得的数量
            CoFiToken(COFI_TOKEN_ADDRESS).mint(rewardTo, mined - cnodeReward);
            // CNode分成
            _cnodeReward += cnodeReward;
        }
    }
    /// @dev 获取目标pair的交易挖矿分成
    /// @param pair 目标pair地址
    /// @return 目标pair的交易挖矿分成
    function getTradeReward(address pair) external view override returns (uint) {
        // 只有CNode有交易出矿分成，做市份额没有        
        if (pair == CNODE_TOKEN_ADDRESS) {
            return _cnodeReward;
        }
        return 0;
    }

    receive() external payable {

    }
}
