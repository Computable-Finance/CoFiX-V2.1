const { expect } = require('chai');
const deployer = require('../scripts/deploy.js');
const { ethers, upgrades } = require('hardhat');

describe('14.PolygonTest', function() {
    it('test1', async function() {

        const CoFiXSinglePool = await ethers.getContractFactory('CoFiXSinglePool');
        const CoFiXOpenPool = await ethers.getContractFactory('CoFiXOpenPool');
        var [owner, addr1, addr2] = await ethers.getSigners();
        //console.log('owner: ' + owner.address);
        //addr1 = owner;

        // nest: 0x58694D405C8Cd917880FC1E23729fc0B90B7732c
        // usdt: 0xd32502b39da054dfF448AaBc1cb8210C756535f6
        // pusd: 0xEfF166764c1eF0e768D57FfEd7736f6C11eE6A4f
        // peth: 0xDdBF1D99A1f92Ee7c20E39B34001fA0784714043
        // nestGovernance: 0xF0737e3C98f1Ee41251681e2C6ad53Ab92AB0AEa
        // nestLedger: 0xbe388405c5f091f46DA440652f776c9832e0d1c3
        // nestBatchMining: 0xD3E0Effa6A9cEC78C95c1FD0BbcCCA5929068B83
        // proxyAdmin: 0xAc88d1fBF58E2646E0F4FF60aa436a70753885D9
        
        // dcu: 0x51EFE1E589354e1f24C7d4533D21F74f973c6eED
        // nestPriceFacade: 0xD3E0Effa6A9cEC78C95c1FD0BbcCCA5929068B83
        // hedgeGovernance: 0x906F3320286eCf8e7524e48Af2d62598F65bf1b2
        // hedgeOptions: 0x6636F38F59Db0d3dD2f53e6cA4831EB2B5A1047c
        // hedgeFutures: 0x8f89663562dDD4519566e590C18ec892134A0cdD
        // hedgeSwap: 0x82502A8f52BF186907BD0E12c8cEe612b4C203d1
        // proxyAdmin: 0x48f62fe14722455C5519303C2Eb89046107a3fD1

        // cofixGovernance: 0xB52E62003F106Ec763A95F4eBc89047A686a3f7c
        // cofixDAO: 0x31a8dF221E790AC7e20f021D2bEf94b1Bb7CE6D7
        // cofixRouter: 0xe51f5cfD748db482D599602742B8bEc4D679c6f1
        // nest_usdt_pool: 0x459Dac18933cdC80040382b25851660761E6EF40
        // proxyAdmin: 0x7E015B01307A40D56e5720d68a4e7D29b4377702

        // const newCoFiXOpenPool = await CoFiXOpenPool.deploy();
        // console.log('newCoFiXOpenPool: ' + newCoFiXOpenPool.address);
        // return;

        const nestBatchMining = await ethers.getContractAt('INestBatchMining', '0xD3E0Effa6A9cEC78C95c1FD0BbcCCA5929068B83');
        console.log('nestBatchMining: ' + nestBatchMining.address);

        const nestBatchPriceView = await ethers.getContractAt('INestBatchPriceView', '0xD3E0Effa6A9cEC78C95c1FD0BbcCCA5929068B83');
        console.log('nestBatchPriceView: ' + nestBatchPriceView.address);

        // const cofixRouter = await ethers.getContractAt('ICoFiXRouter', '0xe51f5cfD748db482D599602742B8bEc4D679c6f1');
        // console.log('cofixRouter: ' + cofixRouter.address);

        // const nest_usdt_pool = await ethers.getContractAt('ICoFiXOpenPool', '0x459Dac18933cdC80040382b25851660761E6EF40');
        // console.log('nest_usdt_pool: ' + nest_usdt_pool.address);

        // 部署合约
        const {
            cofi,
            cnode,
            cofixDAO,
            cofixRouter,
            cofixGovernance,
            nestPriceFacade,
            
            usdt,
            nest,
            peth,
            pusd,
    
            nest_usdt_pool
        } = await deployer.deploy();

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

        const getAccountInfo = async function(account) {
            let acc = account;
            account = account.address;
            return {
                eth: toDecimal(acc.ethBalance ? await acc.ethBalance() : await ethers.provider.getBalance(account)),
                nest: toDecimal(await nest.balanceOf(account)),
                usdt: toDecimal(await usdt.balanceOf(account)),
                xtoken: toDecimal(await nest_usdt_pool.balanceOf(account)),
                //hbtc: toDecimal(await hbtc.balanceOf(account)),
                //weth: toDecimal(await weth.balanceOf(account)),
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
                navps: toDecimal(await nest_usdt_pool.getNAVPerShare(1000000000000000000n, (await nestPriceFacade.latestPriceView(nest.address)).price)),
                //ethBalance: toDecimal(await nest_usdt_pool.ethBalance()),
                //totalFee: toDecimal(await nest_usdt_pool.totalFee()),
                //usdtPair: pairStatus,
                //hbtcPair: await getAccountInfo(hbtcPair),
                //nestPair: await getAccountInfo(nestPair),
                //cofiPair: await getAccountInfo(cofiPair),
                //ethAnchor: await getAccountInfo(ethAnchor),
                //usdAnchor: await getAccountInfo(usdAnchor),
                owner: await getAccountInfo(owner),
                nest_usdt_pool: await getAccountInfo(nest_usdt_pool),
                addr1: await getAccountInfo(addr1),
                dao: await getAccountInfo(cofixDAO),
                //addr2: await getAccountInfo(addr2)
            };
        };

        const showStatus = async function() {
            let status = await getStatus();
            console.log(status);
            return status;
        }

        let status;
        let p;

        if (true) {
            console.log('1. 查询价格');

            let prices = await nestBatchPriceView.lastPriceList(0, 0, 4);
            
            for (var i = 0; i < prices.length / 2; ++i) {
                console.log('eth price: ' + i + ': ' + 2000 / parseFloat(toDecimal(prices[i * 2 + 1])) + ', block: ' + prices[i * 2]);
            }
            prices = await nestBatchPriceView.lastPriceList(0, 1, 4);
            for (var i = 0; i < prices.length / 2; ++i) {
                console.log('nest price: ' + i + ': ' + 2000 / parseFloat(toDecimal(prices[i * 2 + 1])) + ', block: ' + prices[i * 2]);
            }
        }

        // console.log('1.1. setConfig()');
        // await nest_usdt_pool.setConfig(0, 1, 2000000000n, 30, 10, 200, 102739726027n);

        if (false) {
            console.log('2. 做市');

            let receipt = await cofixRouter.addLiquidity(
                nest_usdt_pool.address,
                nest.address,
                0,
                1000000000000000000000000n,
                0,
                owner.address,
                9999999999, {
                    value: toBigInt(0.002)
                }
            );

            await showReceipt(receipt);
        }

        if (true) {
            console.log('2.1. 做市');

            let receipt = await cofixRouter.addLiquidity(
                nest_usdt_pool.address,
                usdt.address,
                0,
                999000000n,
                0,
                owner.address,
                9999999999, {
                    value: toBigInt(0.002)
                }
            );

            await showReceipt(receipt);
        }

        if (false) {
            console.log('3. 赎回');
            await nest_usdt_pool.approve(cofixRouter.address, await nest_usdt_pool.balanceOf(owner.address));
            let receipt = await cofixRouter.removeLiquidityGetTokenAndETH(
                nest_usdt_pool.address,
                '0x0000000000000000000000000000000000000000',
                await nest_usdt_pool.balanceOf(owner.address),
                0,
                owner.address,
                9999999999, {
                    value: toBigInt(0.002)
                }
            ) 
            await showReceipt(receipt);
        }

        if (false) {
            console.log('4. 兑换');
            let receipt = await cofixRouter.swapExactTokensForTokens(
                [usdt.address, nest.address],
                1000000n,
                0,
                owner.address,
                owner.address,
                9999999999, {
                    value: toBigInt(0.002)
                }
            )
            await showReceipt(receipt);
        }
        
        //await nest.transfer('0x82502A8f52BF186907BD0E12c8cEe612b4C203d1', 15000000000000000000000000n);
        //await dcu.mint('0x82502A8f52BF186907BD0E12c8cEe612b4C203d1', 15000000000000000000000000n);

        if (false) {
            console.log('4. 兑换2');
            let receipt = await cofixRouter.swapExactTokensForTokens(
                [usdt.address, nest.address, '0x51EFE1E589354e1f24C7d4533D21F74f973c6eED'],
                1000000n,
                0,
                owner.address,
                owner.address,
                9999999999, {
                    value: toBigInt(0.002)
                }
            )
            await showReceipt(receipt);
        }

        if (false) {
            console.log('5. 兑换3');
            let receipt = await cofixRouter.swapExactTokensForTokens(
                ['0x51EFE1E589354e1f24C7d4533D21F74f973c6eED', nest.address],
                7500017497459407961062702n,
                0,
                owner.address,
                owner.address,
                9999999999, {
                    value: toBigInt(0.002)
                }
            )
            await showReceipt(receipt);
        }
    });
});
