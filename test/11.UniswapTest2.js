const { expect } = require('chai');
const deployer = require('../scripts/deploy.js');

describe('11.UniswapTest2', function() {
    it('test1', async function() {

        const UniswapV3Factory = await ethers.getContractFactory('UniswapV3Factory');
        const UniswapV3PoolAdapter = await ethers.getContractFactory('UniswapV3PoolAdapter');
        const TestRouter = await ethers.getContractFactory('TestRouter');
        const WETH = await ethers.getContractFactory('WETH');
        
        var [owner, addr1, addr2] = await ethers.getSigners();
        //console.log('owner: ' + owner.address);
        //addr1 = owner;

        // Deploy contract
        const {
            cofi,
            cnode,
            cofixDAO,
            cofixRouter,
            cofixController,
            cofixVaultForStaking,
            cofixGovernance,
            nestPriceFacade,
            
            usdt,
            hbtc,
            nest,
            peth,
            pusd,
            usdc,
    
            xeth,
            xpeth,
            xusdt,
            xpusd,
            xusdc,

            usdtPair,
            hbtcPair,
            nestPair,
            cofiPair,
            ethAnchor,
            usdAnchor
        } = await deployer.deploy();

        const weth = await WETH.deploy();
        console.log('weth: ' + weth.address);
        const uniswapV3Factory = await UniswapV3Factory.deploy();
        await uniswapV3Factory.createPool(usdt.address, weth.address, 500);
        const testRouter = await TestRouter.deploy(uniswapV3Factory.address);
        const pool = await ethers.getContractAt('IUniswapV3Pool', await testRouter.getPool(usdt.address, weth.address, 500));
        await pool.initialize(1n << 96n);
        console.log('pool: ' + pool.address);
        const uniswapV3PoolAdapter = await UniswapV3PoolAdapter.deploy(pool.address, weth.address);

        const toBigInt = function(val, decimals) {
            decimals = decimals || 18;
            val = parseFloat(val.toString());
            val = val * 1000000;
            decimals -= 6;
            let bi = BigInt(val.toString());
            let BASE = BigInt(10);
            while (decimals > 0) {
                bi *= BASE;
                --decimals;
            }

            return bi;
        }

        const showReceipt = async function(receipt) {
            console.log({ gasUsed: (await receipt.wait()).gasUsed.toString() });
        }

        const toDecimal = function(bi, decimals) {
            decimals = decimals || 18;
            decimals = BigInt(decimals.toString());
            bi = BigInt(bi.toString());
            let BASE = BigInt(10);
            let r = '';
            while (decimals > 0) {
                let c = (bi % BASE).toString();
                r = c + r;
                bi /= BASE;

                --decimals;
            }
            r = bi.toString() + '.' + r;
            return r;
        }

        const getXTokenInfo = async function(account, xtoken) {
            return [
                toDecimal(await xtoken.balanceOf(account)), 
                toDecimal(await cofixVaultForStaking.balanceOf(xtoken.address, account)), 
                //toDecimal(await cofixVaultForStaking.earned(xtoken.address, account))
            ];
        }

        const getAccountInfo = async function(account) {
            let acc = account;
            account = account.address;
            return {
                eth: toDecimal(acc.ethBalance ? await acc.ethBalance() : await ethers.provider.getBalance(account)),
                usdt: toDecimal(await usdt.balanceOf(account), 6),
                //hbtc: toDecimal(await hbtc.balanceOf(account)),
                weth: toDecimal(await weth.balanceOf(account)),
                // nest: toDecimal(await nest.balanceOf(account)),
                // cofi: toDecimal(await cofi.balanceOf(account)),
                // pusd: toDecimal(await pusd.balanceOf(account)),
                // usdc: toDecimal(await usdc.balanceOf(account), 6),
                // peth: toDecimal(await peth.balanceOf(account)),
                // usdtPair: await getXTokenInfo(account, usdtPair),
                // hbtcPair: await getXTokenInfo(account, hbtcPair),
                // nestPair: await getXTokenInfo(account, nestPair),
                // cofiPair: await getXTokenInfo(account, cofiPair),
                // xusdt: await getXTokenInfo(account, xusdt),
                // xpusd: await getXTokenInfo(account, xpusd),
                // xusdc : await getXTokenInfo(account, xusdc),
                // xpeth: await getXTokenInfo(account, peth),
            };
        }
        const getStatus = async function() {
            //let pairStatus = await getAccountInfo(usdtPair);
            return {
                height: await ethers.provider.getBlockNumber(),
                //navps: navps,
                //usdtPair: pairStatus,
                //hbtcPair: await getAccountInfo(hbtcPair),
                //nestPair: await getAccountInfo(nestPair),
                //cofiPair: await getAccountInfo(cofiPair),
                //ethAnchor: await getAccountInfo(ethAnchor),
                //usdAnchor: await getAccountInfo(usdAnchor),
                owner: await getAccountInfo(owner),
                pool: await getAccountInfo(pool),
                uniswapV3PoolAdapter: await getAccountInfo(uniswapV3PoolAdapter),
                addr1: await getAccountInfo(addr1),
                //dao: await getAccountInfo(cofixDAO),
                //addr2: await getAccountInfo(addr2)
            };
        }

        let status;
        let p;

        // if (true) {
        //     const UNI = '0x1f9840a85d5af5bf1d1762f925bdaddc4201f984';
        //     const WET = '0xc778417e063141139fce010982780140aa0cd5ab';
        //     let up = await testRouter.getUniswapPool(UNI, WET, 3000);
        //     console.log('up: ' + up);
        // }
        // 0x7b2a5f8956ff62b26ac87f22165f75185e2ad639
        // return;

        console.log('wrap-token0 = ' + await uniswapV3PoolAdapter.TOKEN0());
        console.log('wrap-token1 = ' + await uniswapV3PoolAdapter.TOKEN1());

        console.log('pool-token0 = ' + await pool.token0());
        console.log('pool-token1 = ' + await pool.token1());

        await weth.deposit({ value: toBigInt(1000) });
        await usdt.transfer(owner.address, toBigInt(10000000, 6));
        //await weth.transfer(owner.address, toBigInt(10000000));
        if(true) {
            console.log('1. Create uniswap pool, and add liquidity');

            console.log(await getStatus());
            await usdt.approve(testRouter.address, toBigInt(10000000, 6));
            await weth.approve(testRouter.address, toBigInt(10000000));
            let receipt = await testRouter.mint(pool.address, toBigInt(10000, 6));
            await showReceipt(receipt);
            console.log(await getStatus());
        }

        if(true) {
            console.log('2. Swap');

            const v = 10000000000n;
            await cofixRouter.registerPair('0x0000000000000000000000000000000000000000', usdt.address, uniswapV3PoolAdapter.address);
            let receipt = await cofixRouter.swapExactTokensForTokens(
                [
                    '0x0000000000000000000000000000000000000000',
                    usdt.address
                ],
                v,
                0n,
                addr1.address,
                addr1.address,
                BigInt('1800000000000'), {
                    value: v
                }
            );

            await showReceipt(receipt);
            console.log(await getStatus());

            await usdt.approve(cofixRouter.address, 1000000000n);
            receipt = await cofixRouter.swapExactTokensForTokens(
                [
                    usdt.address,
                    '0x0000000000000000000000000000000000000000'
                ],
                1000000000n,
                0n,
                addr1.address,
                addr1.address,
                BigInt('1800000000000')
            );

            await showReceipt(receipt);
            console.log(await getStatus());
        }
    });
});
