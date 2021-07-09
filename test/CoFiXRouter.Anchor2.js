const { expect } = require("chai");
const deployer = require("../scripts/deploy.js");

describe("CoFiXRouter", function() {
    it("test1", async function() {

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
            nest,
            peth,
            weth,
            pusd,
            dai,
    
            xeth,
            xpeth,
            xweth,
            xusdt,
            xpusd,
            xdai,

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
            let BASE = BigInt('10');
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
            let BASE = BigInt('10');
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
            account = account.address;
            return {
                eth: toDecimal(await ethers.provider.getBalance(account)),
                usdt: toDecimal(await usdt.balanceOf(account), 6),
                nest: toDecimal(await nest.balanceOf(account)),
                cofi: toDecimal(await cofi.balanceOf(account)),
                pusd: toDecimal(await pusd.balanceOf(account)),
                dai: toDecimal(await dai.balanceOf(account)),
                xusdt: toDecimal(await xusdt.balanceOf(account)),
                xpusd: toDecimal(await xpusd.balanceOf(account)),
                xdai: toDecimal(await xdai.balanceOf(account)),
                //staked: toDecimal(await cofixVaultForStaking.balanceOf(usdtPair.address, account)),
                //earned: toDecimal(await cofixVaultForStaking.earned(usdtPair.address, account))
            };
        }
        const getStatus = async function() {
            let pairStatus = await getAccountInfo(usdtPair);
            //let p = await cofixController.latestPriceView(usdt.address);
            // let navps = toDecimal(await usdtPair.calcNAVPerShare(
            //     await ethers.provider.getBalance(usdtPair.address),
            //     //toBigInt(pairStatus.eth), 
            //     toBigInt(pairStatus.usdt, 6), 
            //     toBigInt(1), 
            //     p.price
            // ));
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
            console.log('0. 设置价格');
            await nestPriceFacade.setPrice(usdt.address, toBigInt('2051', 6), 1);
            await nestPriceFacade.setPrice(nest.address, toBigInt('192307'), 1);
        }

        let status;
        let p;

        if (true) {
            await dai.transfer(addr1.address, toBigInt(10000000));
            await dai.connect(addr1).approve(cofixRouter.address, toBigInt(10000000));

            await usdt.transfer(owner.address, toBigInt(10000000, 6));
            await usdt.approve(cofixRouter.address, toBigInt(10000000, 6));
            await nest.transfer(owner.address, toBigInt(10000000));
            await nest.approve(cofixRouter.address, toBigInt(10000000));
            await pusd.transfer(owner.address, toBigInt(10000000));
            await pusd.approve(cofixRouter.address, toBigInt(10000000));
            await dai.transfer(owner.address, toBigInt(10000000));
            await dai.approve(cofixRouter.address, toBigInt(10000000));
        }

        if (true) {
            console.log('1. 添加2eth的流动性，预期获得1.999999999000000000份额');
            // 1. 添加2eth的流动性，预期获得1.999999999000000000份额
            let receipt = await cofixRouter.addLiquidity(
                usdtPair.address,
                usdt.address,
                toBigInt(2),
                toBigInt(6000, 6),
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
            console.log('2. 添加2eth的流动性，预期获得1.999999999000000000份额');
            // 1. 添加2eth的流动性，预期获得1.999999999000000000份额
            let receipt = await cofixRouter.addLiquidity(
                nestPair.address,
                nest.address,
                toBigInt(2),
                toBigInt(40000),
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
            console.log('3. anchorPool做市10000usdt');
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
            console.log('4. anchorPool做市20000pusd');
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
            console.log('5. anchorPool做市30000dai');
            let receipt = await cofixRouter.addLiquidity(
                usdAnchor.address,
                dai.address,
                0,
                toBigInt(30000),
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

            console.log('6. 使用路由dai->usdt->eth兑换10usdt');
            let path = await cofixRouter.getRouterPath(dai.address, '0x0000000000000000000000000000000000000000');
            console.log(path);
            console.log('usdtPair: ' + usdtPair.address);
            console.log('nestPair: ' + nestPair.address);
            console.log('usdAnchor: ' + usdAnchor.address);
            console.log('cofixRouter: ' + cofixRouter.address);
            console.log('addr1: ' + addr1.address);
            let receipt = await cofixRouter.connect(addr1).swapExactTokensForTokens(
                path,
                toBigInt(10),
                toBigInt(0),
                //[usdt.address, '0x0000000000000000000000000000000000000000', nest.address],
                addr1.address,
                addr1.address,
                BigInt('1800000000000'), {
                    value: BigInt('10000000000000000')
                }
            );
            await showReceipt(receipt);
            status = await getStatus();
            console.log(status);
        }

        if (true) {
            console.log('7. 使用路由eth->usdt->dai兑换0.004850458833971061eth');
            let path = await cofixRouter.getRouterPath('0x0000000000000000000000000000000000000000', dai.address);
            console.log(path);
            let receipt = await cofixRouter.connect(addr1).swapExactTokensForTokens(
                path,
                BigInt('4850458833971061'),
                toBigInt(0),
                //[usdt.address, '0x0000000000000000000000000000000000000000', nest.address],
                addr1.address,
                addr1.address,
                BigInt('1800000000000'), {
                    value: BigInt('10000000000000000') + BigInt('4850458833971061')
                }
            );
            await showReceipt(receipt);
            status = await getStatus();
            console.log(status);
        }

        console.log('cofi.decimals() = ' + await cofi.decimals());
        console.log('nest.decimals() = ' + await nest.decimals());
        console.log('usdt.decimals() = ' + await usdt.decimals());
    });
});
