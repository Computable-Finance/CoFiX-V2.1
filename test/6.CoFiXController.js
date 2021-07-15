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
            let pi = await nestPriceFacade.lastPriceListAndTriggeredPriceInfoView(usdt.address, 2);
            console.log({
                sigmaSQ: toDecimal(pi.triggeredSigmaSQ.toString()),
                p0: toDecimal(pi.prices[3].toString(), 6),
                bn0: pi.prices[2].toString(),
                p: toDecimal(pi.prices[1].toString(), 6),
                bn: pi.prices[0].toString()
            });

            let rs = await cofixController._calcRevisedSigmaSQ(
                pi.triggeredSigmaSQ, 
                pi.prices[3], 
                pi.prices[2], 
                pi.prices[1], 
                pi.prices[0]
            );
            console.log('rs=' + toDecimal(rs));
        }
    });
});
