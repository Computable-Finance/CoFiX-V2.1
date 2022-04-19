const { expect } = require('chai');
const deployer = require('../scripts/deploy.js');

describe('CoFiXRouter', function() {
    it('test1', async function() {

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
            nest,
            peth,
            weth,
            pusd,
            usdc,
    
            xeth,
            xpeth,
            xweth,
            xusdt,
            xpusd,
            xusdc,

            usdtPair,
            nestPair,
            ethAnchor,
            usdAnchor
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
                usdt: toDecimal(await usdt.balanceOf(account), 6),
                nest: toDecimal(await nest.balanceOf(account)),
                cofi: toDecimal(await cofi.balanceOf(account)),
                pusd: toDecimal(await pusd.balanceOf(account)),
                usdc: toDecimal(await usdc.balanceOf(account), 6),
                xusdt: toDecimal(await xusdt.balanceOf(account)),
                xpusd: toDecimal(await xpusd.balanceOf(account)),
                xusdc: toDecimal(await xusdc.balanceOf(account)),
                //staked: toDecimal(await cofixVaultForStaking.balanceOf(usdtPair.address, account)),
                //earned: toDecimal(await cofixVaultForStaking.earned(usdtPair.address, account))
            };
        }
        const getStatus = async function() {
            let pairStatus = await getAccountInfo(usdtPair);
            return {
                height: await ethers.provider.getBlockNumber(),
                //navps: navps,
                usdtPair: pairStatus,
                nestPair: await getAccountInfo(nestPair),
                usdAnchor: await getAccountInfo(usdAnchor),
                owner: await getAccountInfo(owner),
                addr1: await getAccountInfo(addr1),
                dao: await getAccountInfo(cofixDAO),
                //addr2: await getAccountInfo(addr2)
            };
        }

        if (true) {
            console.log('0. Set price');
            await nestPriceFacade.setPrice(usdt.address, toBigInt(2051, 6), 1);
            await nestPriceFacade.setPrice(nest.address, toBigInt(192307), 1);
        }

        let status;
        let p;

        if (true) {
            await usdc.transfer(addr1.address, toBigInt(10000000, 6));
            await usdc.connect(addr1).approve(cofixRouter.address, toBigInt(10000000, 6));

            await usdt.transfer(owner.address, toBigInt(10000000, 6));
            await usdt.approve(cofixRouter.address, toBigInt(10000000, 6));
            await nest.transfer(owner.address, toBigInt(10000000));
            await nest.approve(cofixRouter.address, toBigInt(10000000));
            await pusd.transfer(owner.address, toBigInt(10000000));
            await pusd.approve(cofixRouter.address, toBigInt(10000000));
            await usdc.transfer(owner.address, toBigInt(10000000, 6));
            await usdc.approve(cofixRouter.address, toBigInt(10000000, 6));
        }

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
            console.log('3. anchorPool add liquidity 10000usdt');
            let receipt = await cofixRouter.addLiquidity(
                usdAnchor.address,
                usdt.address,
                0,
                toBigInt(10000, 6),
                0,
                owner.address,
                BigInt('1800000000000'), {
                    value: BigInt('0')
                }
            );
            showReceipt(receipt);
            status = await getStatus();
            console.log(status);
        }

        if (true) {
            console.log('4. anchorPool add liquidity 20000pusd');
            let receipt = await cofixRouter.addLiquidity(
                usdAnchor.address,
                pusd.address,
                0,
                toBigInt(20000),
                0,
                owner.address,
                BigInt('1800000000000'), {
                    value: BigInt('0')
                }
            );
            showReceipt(receipt);
            status = await getStatus();
            console.log(status);
        }

        if (true) {
            console.log('5. anchorPool add liquidity 30000usdc');
            let receipt = await cofixRouter.addLiquidity(
                usdAnchor.address,
                usdc.address,
                0,
                toBigInt(30000, 6),
                0,
                owner.address,
                BigInt('1800000000000'), {
                    value: BigInt('0')
                }
            );
            showReceipt(receipt);
            status = await getStatus();
            console.log(status);
        }

        if (true) {

            console.log('6. Swap path: usdc->usdt->eth->nest with 10usdt');
            //let path = await cofixRouter.getRouterPath(usdc.address, nest.address);
            let path = [usdc.address, usdt.address, '0x0000000000000000000000000000000000000000', nest.address];
            console.log(path);
            console.log('usdtPair: ' + usdtPair.address);
            console.log('nestPair: ' + nestPair.address);
            console.log('usdAnchor: ' + usdAnchor.address);
            console.log('cofixRouter: ' + cofixRouter.address);
            console.log('addr1: ' + addr1.address);
            let receipt = await cofixRouter.connect(addr1).swapExactTokensForTokens(
                path,
                toBigInt(10, 6),
                toBigInt(0),
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

        if (true) {
            await nest.connect(addr1).approve(cofixRouter.address, toBigInt(900));
            console.log('7. Swap path: nest->eth->usdt->usdc with 900nest');
            let nestMined = await nestPair.estimate('2000166261648224847', '39970186477181116273778', '1000000000000000000', '192307000000000000000000');
            let usdtMined = await usdtPair.estimate('1999795637788636142', '6000442184', '1000000000000000000', '2051000000');
            let usdtAnchorMined = await usdAnchor.estimate(usdt.address, '9999537816');
            let usdcAnchorMined = await usdAnchor.estimate(usdc.address, '30000462184000000000000');

            console.log('mined estimate: ' + (BigInt(nestMined) + BigInt(usdtMined) + BigInt(usdtAnchorMined) + BigInt(usdcAnchorMined)));

            //let path = await cofixRouter.getRouterPath(nest.address, usdc.address);
            let path = [nest.address, '0x0000000000000000000000000000000000000000', usdt.address, usdc.address];
            console.log(path);
            let receipt = await cofixRouter.connect(addr1).swapExactTokensForTokens(
                path,
                toBigInt(900),
                toBigInt(0),
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

        console.log('cofi.decimals() = ' + await cofi.decimals());
        console.log('nest.decimals() = ' + await nest.decimals());
        console.log('usdt.decimals() = ' + await usdt.decimals());

        const CoFiXAnchorToken = await ethers.getContractFactory('CoFiXAnchorToken');
        console.log('xusdt.name=' + await (await CoFiXAnchorToken.attach(await usdAnchor.getXToken(usdt.address))).name());
        console.log('xpusd.name=' + await (await CoFiXAnchorToken.attach(await usdAnchor.getXToken(pusd.address))).name());
        console.log('xusdc.name=' + await (await CoFiXAnchorToken.attach(await usdAnchor.getXToken(usdc.address))).name());

        await cofixDAO.setApplication(owner.address, 1);
        console.log('checkApplication=' + await cofixDAO.checkApplication(owner.address));
        await cofixDAO.settle('0x0000000000000000000000000000000000000000', usdt.address, addr1.address, toBigInt(0.01, 6));

        {
            status = await getStatus();
            console.log(status);
        }
    });
});
