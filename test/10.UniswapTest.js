const { expect } = require('chai');
const deployer = require('../scripts/deploy.js');

describe('CoFiXRouter', function() {
    it('test1', async function() {

        const UniswapV3Factory = await ethers.getContractFactory('UniswapV3Factory');
        const UniswapWrapperPool = await ethers.getContractFactory('UniswapWrapperPool');
        const TestRouter = await ethers.getContractFactory('TestRouter');
        const WETH = await ethers.getContractFactory('WETH');
        
        var [owner, addr1, addr2] = await ethers.getSigners();
        //console.log('owner: ' + owner.address);
        //addr1 = owner;

        // 部署合约
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

        const uniswapV3Factory = await UniswapV3Factory.deploy();
        await uniswapV3Factory.createPool(usdt.address, hbtc.address, 500);
        const testRouter = await TestRouter.deploy(uniswapV3Factory.address);
        const pool = await ethers.getContractAt('IUniswapV3Pool', await testRouter.getPool(usdt.address, hbtc.address, 500));
        await pool.initialize(1n << 96n);
        console.log('pool: ' + pool.address);
        const weth = await WETH.deploy();
        const uniswapWrapperPool = await UniswapWrapperPool.deploy(pool.address, weth.address);

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
                hbtc: toDecimal(await hbtc.balanceOf(account)),
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
                uniswapWrapperPool: await getAccountInfo(uniswapWrapperPool),
                addr1: await getAccountInfo(addr1),
                //dao: await getAccountInfo(cofixDAO),
                //addr2: await getAccountInfo(addr2)
            };
        }

        let status;
        let p;

        console.log('wrap-token0 = ' + await uniswapWrapperPool.TOKEN0());
        console.log('wrap-token1 = ' + await uniswapWrapperPool.TOKEN1());

        console.log('pool-token0 = ' + await pool.token0());
        console.log('pool-token1 = ' + await pool.token1());

        await usdt.transfer(owner.address, toBigInt(10000000, 6));
        await hbtc.transfer(owner.address, toBigInt(10000000));
        if(true) {
            console.log('1. 创建uniswap交易对，并做市');

            console.log(await getStatus());
            await usdt.approve(testRouter.address, toBigInt(10000000, 6));
            await hbtc.approve(testRouter.address, toBigInt(10000000));
            let receipt = await testRouter.mint(pool.address, toBigInt(10000, 6));
            await showReceipt(receipt);
            console.log(await getStatus());
        }

        if(true) {
            console.log('2. 交易');

            // await usdt.approve(uniswapWrapperPool.address, toBigInt(10000000, 6));
            // await hbtc.approve(uniswapWrapperPool.address, toBigInt(10000000));

            const v = 100000000000n;
            await hbtc.transfer(uniswapWrapperPool.address, v);
            let receipt = await uniswapWrapperPool.swap(hbtc.address, usdt.address, v, addr1.address, owner.address);
            await showReceipt(receipt);
            console.log(await getStatus());
        }
    });
});
