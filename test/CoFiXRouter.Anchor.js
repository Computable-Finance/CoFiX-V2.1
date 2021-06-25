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

        const CoFiXAnchorPool = await ethers.getContractFactory("CoFiXAnchorPool");
        const CoFiXAnchorToken = await ethers.getContractFactory("CoFiXAnchorToken");
        const TestERC20 = await ethers.getContractFactory("TestERC20");

        let pusdt = await TestERC20.deploy('PUSDT', 'PUSDT', 18);
        let dai = await TestERC20.deploy('DAI', 'DAI', 18);

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

        let anchorPool = await CoFiXAnchorPool.deploy(
            [usdt.address, pusdt.address, dai.address], 
            [toBigInt('1', 6), toBigInt('1'), toBigInt('1')]
        );
        await anchorPool.initialize(cofixGovernance.address);
        await anchorPool.update(cofixGovernance.address);

        await cofixRouter.registerPair(usdt.address, pusdt.address, anchorPool.address);
        await cofixRouter.registerPair(usdt.address, dai.address, anchorPool.address);
        await cofixRouter.registerPair(dai.address, pusdt.address, anchorPool.address);

        let xusdt = await CoFiXAnchorToken.attach(await anchorPool.getXToken(usdt.address));
        let xpusdt = await CoFiXAnchorToken.attach(await anchorPool.getXToken(pusdt.address));
        let xdai = await CoFiXAnchorToken.attach(await anchorPool.getXToken(dai.address));

        await cofixVaultForStaking.initStakingChannel(xusdt.address, 20000);
        await cofixVaultForStaking.initStakingChannel(xpusdt.address, 20000);
        await cofixVaultForStaking.initStakingChannel(xdai.address, 20000);

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
                nest: toDecimal(await nest.balanceOf(account), 6),
                cofi: toDecimal(await cofi.balanceOf(account)),
                xusdt: toDecimal(await xusdt.balanceOf(account)),
                xpusdt: toDecimal(await xpusdt.balanceOf(account)),
                xdai: toDecimal(await xdai.balanceOf(account)),
                staked: toDecimal(await cofixVaultForStaking.balanceOf(pair.address, account)),
                earned: toDecimal(await cofixVaultForStaking.earned(pair.address, account))
            };
        }
        const getStatus = async function() {
            let pairStatus = await getAccountInfo(pair);
            let p = await cofixController.latestPriceView(usdt.address);
            // let navps = toDecimal(await pair.calcNAVPerShare(
            //     await ethers.provider.getBalance(pair.address),
            //     //toBigInt(pairStatus.eth), 
            //     toBigInt(pairStatus.usdt, 6), 
            //     toBigInt(1), 
            //     p.price
            // ));
            return {
                height: await ethers.provider.getBlockNumber(),
                //navps: navps,
                pair: pairStatus,
                owner: await getAccountInfo(owner),
                addr1: await getAccountInfo(addr1),
                addr2: await getAccountInfo(addr2)
            };
        }

        let status;
        let p;

        await dai.transfer(addr1.address, toBigInt(10000000));
        await dai.connect(addr1).approve(cofixRouter.address, toBigInt(10000000));

        await usdt.transfer(owner.address, toBigInt(10000000, 6));
        await usdt.approve(cofixRouter.address, toBigInt(10000000, 6));
        await nest.transfer(owner.address, toBigInt(10000000));
        await nest.approve(cofixRouter.address, toBigInt(10000000));
        await pusdt.transfer(owner.address, toBigInt(10000000));
        await pusdt.approve(cofixRouter.address, toBigInt(10000000));
        await dai.transfer(owner.address, toBigInt(10000000));
        await dai.approve(cofixRouter.address, toBigInt(10000000));

        if (true) {
            console.log('1. 添加2eth的流动性，预期获得1.999999999000000000份额');
            // 1. 添加2eth的流动性，预期获得1.999999999000000000份额
            let receipt = await cofixRouter.addLiquidity(
                pair.address,
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
                anchorPool.address,
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
            console.log('4. anchorPool做市20000dai');
            let receipt = await cofixRouter.addLiquidity(
                anchorPool.address,
                dai.address,
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

            console.log('5. 使用路由 dai->usdt->eth->nest兑换1000usdt');
            let path = [dai.address, usdt.address, '0x0000000000000000000000000000000000000000', nest.address];//await cofixRouter.getRouterPath(usdt.address, nest.address);
            console.log(path);
            let receipt = await cofixRouter.connect(addr1).swapExactTokensForTokens(
                toBigInt(1000),
                toBigInt(1),
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
