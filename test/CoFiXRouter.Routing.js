const { expect } = require("chai");
const deployer = require("../scripts/deploy.js");

describe("CoFiXRouter", function() {
    it("test1", async function() {

        const [owner, addr1, addr2] = await ethers.getSigners();
        
        // 部署合约
        const {
            cofi,
            cnode,
            cofixDAO,
            cofixRouter,
            cofixController,
            cofixVaultForStaking,
            cofixGovernance,
            usdt,
            pair,
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
        const getAccountInfo = async function(account) {
            account = account.address;
            return {
                eth: toDecimal(await ethers.provider.getBalance(account)),
                usdt: toDecimal(await usdt.balanceOf(account), 6),
                nest: toDecimal(await nest.balanceOf(account), 6),
                cofi: toDecimal(await cofi.balanceOf(account)),
                xtoken: toDecimal(await pair.balanceOf(account)),
                staked: toDecimal(await cofixVaultForStaking.balanceOf(pair.address, account)),
                earned: toDecimal(await cofixVaultForStaking.earned(pair.address, account))
            };
        }
        const getStatus = async function() {
            let pairStatus = await getAccountInfo(pair);
            let p = await cofixController.latestPriceView(usdt.address);
            let navps = toDecimal(await pair.calcNAVPerShare(
                await ethers.provider.getBalance(pair.address),
                //toBigInt(pairStatus.eth), 
                toBigInt(pairStatus.usdt, 6), 
                toBigInt(1), 
                p.price
            ));
            return {
                height: await ethers.provider.getBlockNumber(),
                navps: navps,
                pair: pairStatus,
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
        await nest.transfer(owner.address, toBigInt(1000000000));
        await nest.approve(cofixRouter.address, toBigInt(1000000000));

        if (true) {
            console.log('1. 添加2eth的流动性，预期获得1.999999999000000000份额');
            // 1. 添加2eth的流动性，预期获得1.999999999000000000份额
            let receipt = await cofixRouter.addLiquidity(
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

            console.log('3. 使用路由 usdt->eth->nest兑换1000usdt');
            await usdt.connect(addr1).approve(cofixRouter.address, toBigInt(1000, 6));
            let path = await cofixRouter.getRouterPath(usdt.address, nest.address);
            console.log(path);
            let receipt = await cofixRouter.connect(addr1).swapExactTokensForTokens(
                toBigInt(1000, 6),
                toBigInt(1, 6),
                path,
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
    });
});
