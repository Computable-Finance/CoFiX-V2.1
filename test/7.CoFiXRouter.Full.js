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
            hbtc,
            nest,
            peth,
            pusd,
            dai,
    
            xeth,
            xpeth,
            xusdt,
            xpusd,
            xdai,

            usdtPair,
            hbtcPair,
            nestPair,
            cofiPair,
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

        const getXTokenInfo = async function(account, xtoken) {
            return [
                toDecimal(await xtoken.balanceOf(account)), 
                toDecimal(await cofixVaultForStaking.balanceOf(xtoken.address, account)), 
                //toDecimal(await cofixVaultForStaking.earned(xtoken.address, account))
            ];
        }

        const getAccountInfo = async function(account) {
            account = account.address;
            return {
                eth: toDecimal(await ethers.provider.getBalance(account)),
                usdt: toDecimal(await usdt.balanceOf(account), 6),
                hbtc: toDecimal(await hbtc.balanceOf(account)),
                nest: toDecimal(await nest.balanceOf(account)),
                cofi: toDecimal(await cofi.balanceOf(account)),
                pusd: toDecimal(await pusd.balanceOf(account)),
                dai: toDecimal(await dai.balanceOf(account)),
                peth: toDecimal(await peth.balanceOf(account)),
                usdtPair: await getXTokenInfo(account, usdtPair),
                hbtcPair: await getXTokenInfo(account, hbtcPair),
                nestPair: await getXTokenInfo(account, nestPair),
                cofiPair: await getXTokenInfo(account, cofiPair),
                xusdt: await getXTokenInfo(account, xusdt),
                xpusd: await getXTokenInfo(account, xpusd),
                xdai : await getXTokenInfo(account, xdai),
                xpeth: await getXTokenInfo(account, peth),
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
                //usdtPair: pairStatus,
                cofiPair: await getAccountInfo(cofiPair),
                //nestPair: await getAccountInfo(nestPair),
                //usdAnchor: await getAccountInfo(usdAnchor),
                owner: await getAccountInfo(owner),
                addr1: await getAccountInfo(addr1),
                //dao: await getAccountInfo(cofixDAO),
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
            console.log('1. 初始化资金');
            await cofi.addMinter(owner.address);
            await usdt.transfer(addr1.address, toBigInt(10000000, 6));
            await hbtc.transfer(addr1.address, toBigInt(10000000));
            await nest.transfer(addr1.address, toBigInt(10000000));
            //await cofi.transfer(addr1.address, toBigInt(10000000));
            await pusd.transfer(addr1.address, toBigInt(10000000));
            await dai .transfer(addr1.address, toBigInt(10000000));
            await peth.transfer(addr1.address, toBigInt(10000000));
            await cofi.mint(addr1.address, toBigInt(10000000));

            await usdt.transfer(owner.address, toBigInt(10000000, 6));
            await hbtc.transfer(owner.address, toBigInt(10000000));
            await nest.transfer(owner.address, toBigInt(10000000));
            //await cofi.transfer(owner.address, toBigInt(10000000));
            await pusd.transfer(owner.address, toBigInt(10000000));
            await dai .transfer(owner.address, toBigInt(10000000));
            await peth.transfer(owner.address, toBigInt(10000000));
            await cofi.mint(owner.address, toBigInt(10000000));

            status = await getStatus();
            console.log(status);
        }

        if (true) {
            console.log('2. cofi做市1eth');
            await cofi.approve(cofixRouter.address, toBigInt(2000));
            let receipt = await cofixRouter.addLiquidity(
                cofiPair.address,
                cofi.address,
                toBigInt('1'),
                toBigInt('2000'),
                toBigInt('0.900000000000000000'),
                owner.address,
                BigInt('1800000000000'), {
                    value: BigInt('1010000000000000000')
                }
            );
            showReceipt(receipt);
            status = await getStatus();
            console.log(status);
        }
    });
});
