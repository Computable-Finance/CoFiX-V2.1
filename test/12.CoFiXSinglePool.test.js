const { expect } = require('chai');
const deployer = require('../scripts/deploy.js');
const { ethers, upgrades } = require('hardhat');

describe('12.CoFiXSinglePool.test', function() {
    it('test1', async function() {

        const CoFiXSinglePool = await ethers.getContractFactory('CoFiXSinglePool');
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

        const cofixSinglePool = await upgrades.deployProxy(CoFiXSinglePool, [cofixGovernance.address, 'XT-5', 'XToken-5', usdt.address], { initializer: 'init' });
        await cofixSinglePool.update(cofixGovernance.address);
        await cofixRouter.registerPair('0x0000000000000000000000000000000000000000', usdt.address, cofixSinglePool.address);
        console.log('12. cofixSinglePool.setConfig()');
        await cofixSinglePool.setConfig(30, 10, '1');

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
                xtoken: toDecimal(await cofixSinglePool.balanceOf(account)),
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
                navps: toDecimal(await cofixSinglePool.getNAVPerShare(1000000000000000000n, (await nestPriceFacade.latestPriceView(usdt.address)).price)),
                ethBalance: toDecimal(await cofixSinglePool.ethBalance()),
                totalFee: toDecimal(await cofixSinglePool.totalFee()),
                //usdtPair: pairStatus,
                //hbtcPair: await getAccountInfo(hbtcPair),
                //nestPair: await getAccountInfo(nestPair),
                //cofiPair: await getAccountInfo(cofiPair),
                //ethAnchor: await getAccountInfo(ethAnchor),
                //usdAnchor: await getAccountInfo(usdAnchor),
                owner: await getAccountInfo(owner),
                cofixSinglePool: await getAccountInfo(cofixSinglePool),
                addr1: await getAccountInfo(addr1),
                dao: await getAccountInfo(cofixDAO),
                //addr2: await getAccountInfo(addr2)
            };
        }

        let status;
        let p;

        await usdt.transfer(owner.address, toBigInt(10000000, 6));
        //await weth.transfer(owner.address, toBigInt(10000000));
        if(true) {
            console.log('1. Create pool, and add liquidity');

            console.log(await getStatus());
            await usdt.approve(cofixRouter.address, toBigInt(10000000, 6));
            let receipt = await cofixRouter.addLiquidity(
                cofixSinglePool.address, 
                usdt.address,
                toBigInt(1n),
                toBigInt(0, 6),
                0n,
                owner.address,
                BigInt('1800000000000'), {
                    value: toBigInt(10.01)
                }
            );

            await showReceipt(receipt);
            console.log(await getStatus());
        }

        if(true) {
            console.log('2. Create pool, and add liquidity');

            await usdt.approve(cofixRouter.address, toBigInt(10000000, 6));
            let receipt = await cofixRouter.addLiquidity(
                cofixSinglePool.address, 
                usdt.address,
                toBigInt(1n),
                toBigInt(1000n, 6),
                0n,
                owner.address,
                BigInt('1800000000000'), {
                    value: toBigInt(10.01)
                }
            );

            await showReceipt(receipt);
            console.log(await getStatus());
        }

        if(true) {
            console.log('3. Create pool, and add liquidity');

            await usdt.approve(cofixRouter.address, toBigInt(10000000, 6));
            let receipt = await cofixRouter.addLiquidity(
                cofixSinglePool.address, 
                usdt.address,
                toBigInt(1n),
                toBigInt(1000n, 6),
                0n,
                owner.address,
                BigInt('1800000000000'), {
                    value: toBigInt(10.01)
                }
            );

            await showReceipt(receipt);
            console.log(await getStatus());
        }

        if(true) {
            console.log('4. Swap');

            const v = toBigInt(0.1, 6);
            await cofixRouter.registerPair('0x0000000000000000000000000000000000000000', usdt.address, cofixSinglePool.address);
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
                    value: v + toBigInt(0.01)
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
                BigInt('1800000000000'), {
                    value: toBigInt(0.01)
                }
            );

            await showReceipt(receipt);
            console.log(await getStatus());
        }

        if (true) {
            console.log('5. settle');

            await cofixSinglePool.settle();
            console.log(await getStatus());
        }

        if (true) {
            console.log('6. getConfig');

            let cfg = await cofixSinglePool.getConfig();
            console.log({
                theta: cfg.theta.toString(),
                theta0: cfg.theta0.toString(),
                vol: cfg.impactCostVOL.toString(),
            });
        }

        if (true) {
            console.log('7. getXToken');

            console.log('xusdt: ' + await cofixSinglePool.getXToken(usdt.address));
            console.log('xhbtc: ' + await cofixSinglePool.getXToken(hbtc.address));
        }

        if (true) {
            console.log('8. impactCostForBuyInETH');

            console.log('impactCostForBuyInETH(1ether): ' + toDecimal(await cofixSinglePool.impactCostForBuyInETH(1000000000000000000000000000n)));
            console.log('impactCostForBuyInETH(1ether): ' + toDecimal(await cofixSinglePool.impactCostForBuyInETH(1000000000000000000n)));
            console.log('impactCostForBuyInETH(1ether): ' + toDecimal(await cofixSinglePool.impactCostForBuyInETH(1000000000n)));
        }

        if (true) {
            console.log('8. impactCostForSellOutETH');

            console.log('impactCostForSellOutETH(1ether): ' + toDecimal(await cofixSinglePool.impactCostForSellOutETH(1000000000000000000000000000n)));
            console.log('impactCostForSellOutETH(1ether): ' + toDecimal(await cofixSinglePool.impactCostForSellOutETH(1000000000000000000n)));
            console.log('impactCostForSellOutETH(1ether): ' + toDecimal(await cofixSinglePool.impactCostForSellOutETH(1000000000n)));
        }
    });
});
