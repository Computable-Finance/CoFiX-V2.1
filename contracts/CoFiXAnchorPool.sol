// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./libs/TransferHelper.sol";

import "./interfaces/ICoFiXAnchorPool.sol";
import "./interfaces/ICoFiXDAO.sol";

import "./CoFiXBase.sol";
import "./CoFiToken.sol";
import "./CoFiXAnchorToken.sol";

/// @dev Anchor pool
contract CoFiXAnchorPool is CoFiXBase, ICoFiXAnchorPool {
    
    /* ******************************************************************************************
     * Note: In order to unify the authorization entry, all transferFrom operations are carried
     * out in the CoFiXRouter, and the CoFiXPool needs to be fixed, CoFiXRouter does trust and 
     * needs to be taken into account when calculating the pool balance before and after rollover
     * ******************************************************************************************/

    /// @dev Defines the structure of a token channel
    struct TokenInfo {
        // Address of token
        address tokenAddress;
        // Base of token (value is 10^decimals)
        uint96 base;
        // Address of corresponding xtoken
        address xtokenAddress;

        // Total mined
        uint112 _Y;
        // Adjusting to a balanced trade size
        uint112 _D;
        // Last update block
        uint32 _lastblock;
    }

    // Address of CoFiXDAO
    address _cofixDAO;
    // Each unit token (in the case of binary pools, eth) is used for the standard ore output, 1e18 based
    uint96 _nt;

    // Address of CoFiXRouter
    address _cofixRouter;
    // Lock flag
    bool _locked;
    // Trade fee rate, ten thousand points system. 20
    uint16 _theta;
    
    // Impact cost threshold
    //uint96 _impactCostVOL;

    // Array of TokenInfo
    TokenInfo[] _tokens;

    // Token mapping(token=>tokenInfoIndex)
    mapping(address=>uint) _tokenMapping;

    // Constructor, in order to support openzeppelin's scalable scheme, 
    // it's need to move the constructor to the initialize method
    constructor () {
    }

    /// @dev init Initialize
    /// @param governance ICoFiXGovernance implementation contract address
    /// @param index Index of pool
    /// @param tokens Array of token
    /// @param bases Array of token base
    function init (
        address governance,
        uint index,
        address[] calldata tokens,
        uint96[] calldata bases
    ) external {
        super.initialize(governance);
        // Traverse the token and initialize the corresponding data
        for (uint i = 0; i < tokens.length; ++i) {
            addToken(index, tokens[i], bases[i]);
        }
    }

    modifier check() {
        require(_cofixRouter == msg.sender, "CoFiXAnchorPool: Only for CoFiXRouter");
        require(!_locked, "CoFiXAnchorPool: LOCKED");
        _locked = true;
        _;
        _locked = false;
    }

    /// @dev Set configuration
    /// @param theta Trade fee rate, ten thousand points system. 20
    /// @param impactCostVOL Impact cost threshold
    /// @param nt Each unit token (in the case of binary pools, eth) is used for the standard ore output, 1e18 based
    function setConfig(uint16 theta, uint96 impactCostVOL, uint96 nt) external override onlyGovernance {
        // Trade fee rate, ten thousand points system. 20
        _theta = theta;
        // Impact cost threshold
        //_impactCostVOL = impactCostVOL;
        require(uint(impactCostVOL) == 0, "CoFiXAnchorPool: impactCostVOL must be 0");
        // Each unit token (in the case of binary pools, eth) is used for the standard ore output, 1e18 based
        _nt = nt;
    }

    /// @dev Get configuration
    /// @return theta Trade fee rate, ten thousand points system. 20
    /// @return impactCostVOL Impact cost threshold
    /// @return nt Each unit token (in the case of binary pools, eth) is used for the standard ore output, 1e18 based
    function getConfig() external view override returns (uint16 theta, uint96 impactCostVOL, uint96 nt) {
        return (_theta, uint96(0), _nt);
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

    /// @dev Add token information
    /// @param poolIndex Index of pool
    /// @param token Target token address
    /// @param base Base of token
    function addToken(
        uint poolIndex, 
        address token, 
        uint96 base
    ) public override onlyGovernance returns (address xtokenAddress) {
        TokenInfo storage tokenInfo = _tokens.push();
        uint tokenIndex = _tokens.length;
        _tokenMapping[token] = tokenIndex;

        // Generate name and symbol for token
        string memory si = _getAddressStr(poolIndex);
        string memory idx = _getAddressStr(tokenIndex);
        string memory name = _strConcat(_strConcat(_strConcat("XToken-", si), "-"), idx);
        string memory symbol = _strConcat(_strConcat(_strConcat("XT-", si), "-"), idx);

        xtokenAddress = address(new CoFiXAnchorToken(name, symbol, address(this)));
        tokenInfo.tokenAddress = token;
        tokenInfo.xtokenAddress = xtokenAddress;
        tokenInfo.base = base;
    }

    // Transfer token, 0 address means eth
    function _transfer(address token, address to, uint value) private {
        if (value > 0) {
            if (token == address(0)) {
                payable(to).transfer(value);
            } else {
                TransferHelper.safeTransfer(token, to, value);
            }
        }
    }

    // Query balance, 0 address means eth
    function _balanceOf(address token) private view returns (uint balance) {
        if (token == address(0)) {
            balance = address(this).balance;
        } else {
            balance = IERC20(token).balanceOf(address(this));
        }
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
        // 1. Check amount
        require(amountETH == 0, "CoFiXAnchorPool: invalid asset ratio");

        // 2. Return unnecessary eth
        // The token is 0, which means that the ETH is transferred in and the part exceeding 
        // the amountToken needs to be returned
        if (token == address(0)) {
            _transfer(address(0), payback, msg.value - amountToken);
        } 
        // If the token is not 0, it means that the token is transferred in and all the 
        // transferred eth needs to be returned
        else if (msg.value > 0) {
            payable(payback).transfer(msg.value);
        }

        // 3. Load tokenInfo
        TokenInfo storage tokenInfo = _tokens[_tokenMapping[token] - 1];
        xtoken = tokenInfo.xtokenAddress;
        uint base = uint(tokenInfo.base);

        // 4. Increase xtoken
        liquidity = CoFiXAnchorToken(xtoken).mint(to, amountToken * 1 ether / base);
        //emit Mint(token, to, amountETH, amountToken, liquidity);

        // 5. Update mining state
        _updateMiningState(tokenInfo, _balanceOf(token) * 1 ether / base, uint(_nt));
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
        // 1. Return unnecessary eth
        if (msg.value > 0) {
            payable(payback).transfer(msg.value);
        }

        // 2. Load tokenInfo
        TokenInfo storage tokenInfo = _tokens[_tokenMapping[token] - 1];
        uint base = uint(tokenInfo.base);

        amountTokenOut = liquidity * 1 ether / base;
        amountETHOut = 0;

        // 3. Destroy xtoken
        CoFiXAnchorToken(tokenInfo.xtokenAddress).burn(liquidity);
        //emit Burn(token, to, liquidity, amountETHOut, amountTokenOut);

        // 4. Adjust according to the surplus of the fund pool
        _cash(liquidity, token, base, _balanceOf(token), to, address(0));
    }

    // Transfer with taxes
    function _taxes(address token, address to, uint value, address dao) private {
        if (dao == address(0)) {
            _transfer(token, to, value);
        } else {
            uint taxes = value >> 1;
            if (token == address(0)) {
                payable(to).transfer(value - taxes);
                ICoFiXDAO(dao).addETHReward { value: taxes } (address(this));
            } else {
                _transfer(token, to, value - taxes);
                _transfer(token, dao, taxes);
            }
        }
    }

    // Retrieve the target token according to the share. If the token balance in the fund pool is not enough, 
    // the current token will be deducted from the maximum balance of the remaining assets
    function _cash(uint liquidity, address token, uint base, uint balance, address to, address dao) private {
        uint nt = uint(_nt);
        while (liquidity > 0) {
            // The number of tokens to be paid to the user
            uint need = liquidity * base / 1 ether;
            // If the balance is enough, the token will be transferred to the user directly and break

            TokenInfo storage tokenInfo = _tokens[_tokenMapping[token] - 1];
            if (need <= balance) {
                _taxes(token, to, need, dao);
                _updateMiningState(tokenInfo, (balance - need) * 1 ether / base, nt);
                break;
            }

            // If the balance is not enough, transfer all the balance to the user
            _taxes(token, to, balance, dao);
            _updateMiningState(tokenInfo, 0, nt);

            // After deducting the transferred token, the remaining share
            liquidity -= balance * 1 ether / base;

            // Traverse the token to find the fund with the largest balance
            uint max = 0;
            uint length = _tokens.length;
            for (uint i = 0; i < length; ++i) {
                // Load token
                TokenInfo storage ti = _tokens[i];
                address ta = ti.tokenAddress;
                // The token cannot be the same as the token just processed
                if (ta != token) {
                    // Find the token with the largest balance and update it
                    uint b = _balanceOf(ta);
                    uint bs = uint(ti.base);
                    if (max < b * 1 ether / bs) {
                        // Update base
                        base = bs;
                        // Update balance
                        balance = b;
                        // Update token address
                        token = ta;
                        // Update max
                        max = b * 1 ether / bs;
                    }
                }
            }
        }
    }

    /// @dev Transfer the excess funds that exceed the total share in the fund pool
    function skim() external override {
        // 1. Traverse the token, calculate the total number of assets and the total share, 
        // and find the fund with the largest balance
        uint totalBalance = 0;
        uint totalShare = 0;

        uint max = 0;
        uint base;
        uint balance;
        address token;
        uint length = _tokens.length;
        for (uint i = 0; i < length; ++i) {
            // Load token
            TokenInfo storage ti = _tokens[i];
            address ta = ti.tokenAddress;

            // Find the token with the largest balance and update it
            uint b = _balanceOf(ta);
            uint bs = uint(ti.base);
            uint stdBalance = b * 1 ether / bs;
            // Calculate total assets
            totalBalance += stdBalance;
            // Calculate total share
            totalShare += IERC20(ti.xtokenAddress).totalSupply();

            if (max < stdBalance) {
                // Update base
                base = bs;
                // Update balance
                balance = b;
                // Update token address
                token = ta;
                // Update max
                max = stdBalance;
            }
        }

        // 2. Take away the excess funds in the capital pool that exceed the total share
        if (totalBalance > totalShare) {
            _cash(totalBalance - totalShare, token, base, balance, msg.sender, _cofixDAO);
        }
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
        // 1. Return unnecessary eth
        // The src is 0, which means that the ETH is transferred in and the part exceeding
        // the amountToken needs to be returned
        if (src == address(0)) {
            _transfer(address(0), payback, msg.value - amountIn);
        } 
        // If src is not 0, it means that the token is transferred in and all the transferred 
        // eth need to be returned
        else if (msg.value > 0) {
            payable(payback).transfer(msg.value);
        }
        
        // 2. Load tokenInfo
        TokenInfo storage tokenInfo0 = _tokens[_tokenMapping[src] - 1];
        TokenInfo storage tokenInfo1 = _tokens[_tokenMapping[dest] - 1];
        uint base0 = uint(tokenInfo0.base);
        uint base1 = uint(tokenInfo1.base);

        {
            // 3. Calculate the number of tokens exchanged
            amountOut = amountIn * base1 / base0;
            uint fee = amountOut * uint(_theta) / 10000;
            amountOut = amountOut - fee;

            // 4. Transfer transaction fee
            if (dest == address(0)) {
                ICoFiXDAO(_cofixDAO).addETHReward { value: fee } (address(this));
            } else {
                _transfer(dest, _cofixDAO, fee);
            }
        }
        
        // 5. Mining logic
        uint nt = uint(_nt);
        mined = _cofiMint(tokenInfo0, _balanceOf(src) * 1 ether / base0, nt);
        mined += _cofiMint(tokenInfo1, (_balanceOf(dest) - amountOut) * 1 ether / base1, nt);

        // 6. Transfer token
        _transfer(dest, to, amountOut);
    }

    // Update mining state
    function _updateMiningState(TokenInfo storage tokenInfo, uint x, uint nt) private {
        // 1. Get total shares
        uint L = IERC20(tokenInfo.xtokenAddress).totalSupply();

        // 2. Get the current token balance and convert it into the corresponding number of shares
        //uint x = _balanceOf(tokenInfo.tokenAddress) * 1 ether / base;
        
        // 3. Calculate and adjust the scale
        uint D1 = L > x ? L - x : x - L;

        // 4. According to the adjusted scale before and after the transaction, the ore drawing data is calculated
        // Y_t=Y_(t-1)+D_(t-1)*n_t*(S_t+1)-Z_t                   
        // Z_t=[Y_(t-1)+D_(t-1)*n_t*(S_t+1)]* v_t
        uint D0 = uint(tokenInfo._D);
        // When d0 < D1, the y value also needs to be updated
        uint Y = uint(tokenInfo._Y) + D0 * nt * (block.number - uint(tokenInfo._lastblock)) / 1 ether;

        // 5. Update ore drawing parameters
        tokenInfo._Y = uint112(Y);
        tokenInfo._D = uint112(D1);
        tokenInfo._lastblock = uint32(block.number);
    }

    // Calculate CoFi transaction mining related variables and update the corresponding status
    function _cofiMint(TokenInfo storage tokenInfo, uint x, uint nt) private returns (uint mined) {

        // 1. Get total shares
        uint L = IERC20(tokenInfo.xtokenAddress).totalSupply();

        // 2. Get the current token balance and convert it into the corresponding number of shares
        //uint x = _balanceOf(tokenInfo.tokenAddress) * 1 ether / base;
        
        // 3. Calculate and adjust the scale
        uint D1 = L > x ? L - x : x - L;

        // 4. According to the adjusted scale before and after the transaction, the ore drawing data is calculated
        // Y_t=Y_(t-1)+D_(t-1)*n_t*(S_t+1)-Z_t                   
        // Z_t=[Y_(t-1)+D_(t-1)*n_t*(S_t+1)]* v_t
        uint D0 = uint(tokenInfo._D);
        // When d0 < D1, the y value also needs to be updated
        uint Y = uint(tokenInfo._Y) + D0 * nt * (block.number - uint(tokenInfo._lastblock)) / 1 ether;
        if (D0 > D1) {
            mined = Y * (D0 - D1) / D0;
            Y = Y - mined;
        }

        // 5. Update ore drawing parameters
        tokenInfo._Y = uint112(Y);
        tokenInfo._D = uint112(D1);
        tokenInfo._lastblock = uint32(block.number);
    }

    /// @dev Estimate mining amount
    /// @param token Target token address
    /// @param newBalance New balance of target token
    /// @return mined The amount of CoFi which will be mind by this trade
    function estimate(
        address token,
        uint newBalance
    ) external view override returns (uint mined) {
        TokenInfo storage tokenInfo = _tokens[_tokenMapping[token] - 1];
        // 1. Get total shares
        uint L = IERC20(tokenInfo.xtokenAddress).totalSupply();

        // 2. Get the current token balance and convert it into the corresponding number of shares
        uint x = newBalance * 1 ether / uint(tokenInfo.base);
        
        // 3. Calculate and adjust the scale
        uint D1 = L > x ? L - x : x - L;

        // 4. According to the adjusted scale before and after the transaction, the ore drawing data is calculated
        // Y_t=Y_(t-1)+D_(t-1)*n_t*(S_t+1)-Z_t                   
        // Z_t=[Y_(t-1)+D_(t-1)*n_t*(S_t+1)]* v_t
        uint D0 = uint(tokenInfo._D);

        if (D0 > D1) {
            // When d0 < D1, the y value also needs to be updated
            uint Y = uint(tokenInfo._Y) + D0 * uint(_nt) * (block.number - uint(tokenInfo._lastblock)) / 1 ether;
            mined = Y * (D0 - D1) / D0;
        }
    }

    /// @dev Gets the token address of the share obtained by the specified token market making
    /// @param token Target token address
    /// @return If the fund pool supports the specified token, return the token address of the market share
    function getXToken(address token) external view override returns (address) {
        uint index = _tokenMapping[token];
        if (index > 0) {
            return _tokens[index - 1].xtokenAddress;
        }
        return address(0);
    }

    // from NEST v3.0
    function _strConcat(string memory _a, string memory _b) private pure returns (string memory)
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
    
    // Convert number into a string, if less than 4 digits, make up 0 in front, from NEST v3.0
    function _getAddressStr(uint iv) private pure returns (string memory) 
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
