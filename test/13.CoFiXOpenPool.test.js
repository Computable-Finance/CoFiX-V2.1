const { expect } = require('chai');
const deployer = require('../scripts/deploy.js');
const { ethers, upgrades } = require('hardhat');

describe('CoFiXRouter', function() {
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

        await nest.transfer(owner.address, toBigInt(100000000));
        await usdt.transfer(owner.address, toBigInt(100000000));
        await nest.approve(cofixRouter.address, toBigInt(100000000));
        await usdt.approve(cofixRouter.address, toBigInt(100000000));

        console.log(await getStatus());
        if (true) {
            console.log('1. Add liquidity 1');
            let receipt = await cofixRouter.addLiquidity(
                nest_usdt_pool.address, //nest_usdt_pool.address, //address pool,
                usdt.address, //address token,
                0, //uint amountETH,
                toBigInt(10000), //uint amountToken,
                0, //uint liquidityMin,
                owner.address, //address to,
                99999999999, {
                    value: toBigInt(0.005)
                }
            );

            await showReceipt(receipt);
            status = await showStatus();
            expect(status.owner.xtoken).to.eq(toDecimal(9999999999999000000000n));
            expect(status.owner.usdt).to.eq(toDecimal(toBigInt(100000000 - 10000)));
            expect(status.owner.nest).to.eq(toDecimal(toBigInt(100000000)));
            expect(status.nest_usdt_pool.usdt).to.eq(toDecimal(toBigInt(10000)));
            expect(status.nest_usdt_pool.nest).to.eq(toDecimal(toBigInt(0)));
        }
        if (true) {
            console.log('2. Add liquidity 2');
            let receipt = await cofixRouter.addLiquidity(
                nest_usdt_pool.address, //nest_usdt_pool.address, //address pool,
                usdt.address, //address token,
                0, //uint amountETH,
                toBigInt(10000), //uint amountToken,
                0, //uint liquidityMin,
                owner.address, //address to,
                99999999999, {
                    value: toBigInt(0.005)
                }
            );

            await showReceipt(receipt);
            status = await showStatus();
            expect(status.owner.xtoken).to.eq(toDecimal(19999999999999000000000n));
            expect(status.owner.usdt).to.eq(toDecimal(toBigInt(100000000 - 20000)));
            expect(status.owner.nest).to.eq(toDecimal(toBigInt(100000000)));
            expect(status.nest_usdt_pool.usdt).to.eq(toDecimal(toBigInt(20000)));
            expect(status.nest_usdt_pool.nest).to.eq(toDecimal(toBigInt(0)));
        }

        if (true) {
            console.log('3. Add liquidity 3');
            let receipt = await cofixRouter.addLiquidity(
                nest_usdt_pool.address, //nest_usdt_pool.address, //address pool,
                nest.address, //address token,
                0, //uint amountETH,
                toBigInt(10000), //uint amountToken,
                0, //uint liquidityMin,
                owner.address, //address to,
                99999999999, {
                    value: toBigInt(0.005)
                }
            );

            await showReceipt(receipt);
            status = await showStatus();
            //expect(status.owner.xtoken).to.eq(toDecimal(19999999999999000000000n));
            expect(status.owner.usdt).to.eq(toDecimal(toBigInt(100000000 - 20000)));
            expect(status.owner.nest).to.eq(toDecimal(toBigInt(100000000 - 10000)));
            expect(status.nest_usdt_pool.usdt).to.eq(toDecimal(toBigInt(20000)));
            expect(status.nest_usdt_pool.nest).to.eq(toDecimal(toBigInt(10000)));
        }
        if (true) {
            console.log('4. Add liquidity 4');
            let receipt = await cofixRouter.addLiquidity(
                nest_usdt_pool.address, //nest_usdt_pool.address, //address pool,
                nest.address, //address token,
                0, //uint amountETH,
                toBigInt(10000), //uint amountToken,
                0, //uint liquidityMin,
                owner.address, //address to,
                99999999999, {
                    value: toBigInt(0.005)
                }
            );

            await showReceipt(receipt);
            status = await showStatus();
            //expect(status.owner.xtoken).to.eq(toDecimal(19999999999999000000000n));
            expect(status.owner.usdt).to.eq(toDecimal(toBigInt(100000000 - 20000)));
            expect(status.owner.nest).to.eq(toDecimal(toBigInt(100000000 - 20000)));
            expect(status.nest_usdt_pool.usdt).to.eq(toDecimal(toBigInt(20000)));
            expect(status.nest_usdt_pool.nest).to.eq(toDecimal(toBigInt(20000)));
        }

        if(true) {
            console.log('5. Swap1');
            let receipt = await cofixRouter.swapExactTokensForTokens(
                [usdt.address, nest.address], //address[] calldata path,
                toBigInt(100), //uint amountIn,
                0, //uint amountOutMin,
                addr1.address, //address to,
                addr1.address, //address rewardTo,
                99999999999, {
                    value: toBigInt(0.005)
                }
            )

            await showReceipt(receipt);
            status = await showStatus();
            // return;
            // //expect(status.owner.xtoken).to.eq(toDecimal(19999999999999000000000n));
            // expect(status.owner.usdt).to.eq(toDecimal(toBigInt(100000000 - 20000)));
            // expect(status.owner.nest).to.eq(toDecimal(toBigInt(100000000 - 20000)));
            // expect(status.nest_usdt_pool.usdt).to.eq(toDecimal(toBigInt(20000)));
            // expect(status.nest_usdt_pool.nest).to.eq(toDecimal(toBigInt(20000)));
        }
        if(true) {
            console.log('6. Swap2');
            let receipt = await cofixRouter.swapExactTokensForTokens(
                [nest.address, usdt.address], //address[] calldata path,
                toBigInt(100), //uint amountIn,
                0, //uint amountOutMin,
                addr1.address, //address to,
                addr1.address, //address rewardTo,
                99999999999, {
                    value: toBigInt(0.005)
                }
            )

            await showReceipt(receipt);
            status = await showStatus();
            return;
            //expect(status.owner.xtoken).to.eq(toDecimal(19999999999999000000000n));
            expect(status.owner.usdt).to.eq(toDecimal(toBigInt(100000000 - 20000)));
            expect(status.owner.nest).to.eq(toDecimal(toBigInt(100000000 - 20000)));
            expect(status.nest_usdt_pool.usdt).to.eq(toDecimal(toBigInt(20000)));
            expect(status.nest_usdt_pool.nest).to.eq(toDecimal(toBigInt(20000)));
        }
    });
});
