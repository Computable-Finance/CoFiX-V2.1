const { expect } = require('chai');
const deployer = require('../scripts/deploy.js');

describe('CoFiXRouter', function() {
    it('test1', async function() {

        const [owner, addr1, addr2] = await ethers.getSigners();
        
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
            usdtPair,
            nest,
            nestPair
        } = await deployer.deploy();

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
        const getAccountInfo = async function(account) {
            let acc = account;
            account = account.address;
            return {
                eth: toDecimal(acc.ethBalance ? await acc.ethBalance() : await ethers.provider.getBalance(account)),
                usdt: toDecimal(await usdt.balanceOf(account), 6),
                nest: toDecimal(await nest.balanceOf(account), 6),
                cofi: toDecimal(await cofi.balanceOf(account)),
                xtoken: toDecimal(await usdtPair.balanceOf(account)),
                staked: toDecimal(await cofixVaultForStaking.balanceOf(usdtPair.address, account)),
                earned: toDecimal(await cofixVaultForStaking.earned(usdtPair.address, account))
            };
        }
        const getStatus = async function() {
            let pairStatus = await getAccountInfo(usdtPair);
            let p = await nestPriceFacade.latestPriceView(usdt.address);
            let navps = toDecimal(await usdtPair.getNAVPerShare(
                //await ethers.provider.getBalance(usdtPair.address),
                //toBigInt(pairStatus.eth), 
                //toBigInt(pairStatus.usdt, 6), 
                toBigInt(1), 
                p.price
            ));
            return {
                height: await ethers.provider.getBlockNumber(),
                navps: navps,
                usdtPair: pairStatus,
                owner: await getAccountInfo(owner),
                addr1: await getAccountInfo(addr1),
                addr2: await getAccountInfo(addr2)
            };
        }

        let status;
        let p;
        await usdt.transfer(addr1.address, toBigInt(10000000, 6));
        await usdt.transfer(owner.address, toBigInt(10000000, 6));
        await usdt.approve(cofixRouter.address, toBigInt(10000000, 6));
        await nest.transfer(owner.address, toBigInt(100000000));
        await nest.approve(cofixRouter.address, toBigInt(100000000));

        if (true) {
            console.log('1. Add 2eth liquidity, will get 1.999999999000000000 xt');
            // 1. Add 2eth liquidity, will get 1.999999999000000000 xt
            let receipt = await cofixRouter.addLiquidity(
                usdtPair.address,
                usdt.address,
                toBigInt(2),
                toBigInt(4000, 6),
                toBigInt(0.9),
                owner.address,
                BigInt('1800000000000'), {
                    value: BigInt('2010000000000000000')
                }
            );
            await showReceipt(receipt);
            status = await getStatus();
            console.log(status);
        }

        if (true) {
            console.log('2. Add 2eth liquidity, will get 1.999999999000000000 xt');
            // 1. Add 2eth liquidity, will get 1.999999999000000000 xt
            let receipt = await cofixRouter.addLiquidity(
                nestPair.address,
                nest.address,
                toBigInt(2),
                toBigInt(200000),
                toBigInt(0.9),
                owner.address,
                BigInt('1800000000000'), {
                    value: BigInt('2010000000000000000')
                }
            );
            await showReceipt(receipt);
            status = await getStatus();
            console.log(status);
        }

        if (true) {

            console.log('3. Swap path: usdt->eth->nest with 1000usdt');
            await usdt.connect(addr1).approve(cofixRouter.address, toBigInt(1000, 6));
            //let path = await cofixRouter.getRouterPath(usdt.address, nest.address);
            let path = [usdt.address, '0x0000000000000000000000000000000000000000', nest.address];
            console.log(path);
            let receipt = await cofixRouter.connect(addr1).swapExactTokensForTokens(
                path,
                toBigInt(1000, 6),
                toBigInt(1, 6),
                //[usdt.address, '0x0000000000000000000000000000000000000000', nest.address],
                addr1.address,
                addr1.address,
                BigInt('1800000000000'), {
                    value: BigInt('20000000000000000')
                }
            );
            await showReceipt(receipt);
            status = await getStatus();
            console.log(status);
        }
    });
});
