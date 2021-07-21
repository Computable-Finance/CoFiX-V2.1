const { expect } = require('chai');
const deployer = require('../scripts/deploy.js');

describe('CoFiXRouter', function() {
    it('test1', async function() {

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
            await nestPriceFacade.setPrice(usdt.address, toBigInt(2051, 6), 1);
            await nestPriceFacade.setPrice(cofi.address, toBigInt(2051, 18), 1);
            await nestPriceFacade.setPrice(nest.address, toBigInt(192307), 1);
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
            console.log('2. 添加2eth的流动性，预期获得1.999999999000000000份额');
            // 1. 添加2eth的流动性，预期获得1.999999999000000000份额
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
            console.log('5. anchorPool做市50000dai');
            let receipt = await cofixRouter.addLiquidity(
                usdAnchor.address,
                dai.address,
                0,
                toBigInt(50000),
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

            console.log('6. 使用路由dai->usdt->eth->nest兑换1000usdt');
            //let path = await cofixRouter.getRouterPath(dai.address, nest.address);
            let path = [dai.address, usdt.address, '0x0000000000000000000000000000000000000000', nest.address];
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
                    value: BigInt('20000000000000000')
                }
            );
            await showReceipt(receipt);
            status = await getStatus();
            console.log(status);
        }

        if (true) {
            await nest.connect(addr1).approve(cofixRouter.address, toBigInt(900));
            console.log('7. 使用路由nest->eth->usdt->dai兑换900nest');
            //let path = await cofixRouter.getRouterPath(nest.address, dai.address);
            let path = [nest.address, '0x0000000000000000000000000000000000000000', usdt.address, dai.address];
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

        if (true) {
            console.log('8. owner使用22000usdt兑换xdai');
            await usdt.approve(cofixRouter.address, toBigInt(22000, 6));
            let receipt = await cofixRouter.swapExactTokensForTokens(
                [usdt.address, 
                dai.address], 
                toBigInt(22000, 6),
                toBigInt(0),
                owner.address,
                owner.address,
                // 截止时间
                BigInt('1800000000000'), {
                    value: BigInt('0')
                }
            );
            await showReceipt(receipt);
            status = await getStatus();
            console.log(status);
        }

        if (true) {
            console.log('9. owner使用18000pusd兑换xdai');
            await pusd.approve(cofixRouter.address, toBigInt(18000));
            let receipt = await cofixRouter.swapExactTokensForTokens(
                [pusd.address, 
                dai.address], 
                toBigInt(18000),
                toBigInt(0),
                owner.address,
                owner.address,
                // 截止时间
                BigInt('1800000000000'), {
                    value: BigInt('0')
                }
            );
            await showReceipt(receipt);
            status = await getStatus();
            console.log(status);
        }

        if (true) {
            console.log('10. owner赎回29999 xdai份额');
            await xdai.approve(cofixRouter.address, toBigInt(29999));
            let receipt = await cofixRouter.removeLiquidityGetTokenAndETH(
                usdAnchor.address,
                // 要移除的token对
                dai.address,
                // 移除的额度
                toBigInt(29999),
                // 预期最少可以获得的eth数量
                toBigInt(0),
                // 接收地址
                owner.address,
                // 截止时间
                BigInt('1800000000000'), {
                    value: BigInt('20000000000000000')
                }
            );
            await showReceipt(receipt);
            status = await getStatus();
            console.log(status);
            console.log('quotaOf: ' + await cofixDAO.quotaOf());
        }

        if (true) {
            console.log('11. addr1回购0.0002个CoFi');
            await cofi.connect(addr1).approve(cofixDAO.address, toBigInt(0.0002));
            let receipt = await cofixDAO.connect(addr1).redeemToken(usdt.address, toBigInt(0.0002), addr1.address, {
                value: BigInt('20000000000000000')
            });
            await showReceipt(receipt);
            status = await getStatus();
            console.log(status);
        }

        if (true) {
            console.log('12. addr1回购0.003个CoFi');
            await cofi.connect(addr1).approve(cofixDAO.address, toBigInt(0.003));
            let receipt = await cofixDAO.connect(addr1).redeemToken(dai.address, toBigInt(0.003), addr1.address, {
                value: BigInt('20000000000000000')
            });
            await showReceipt(receipt);
            status = await getStatus();
            console.log(status);
        }

        if (true) {
            await dai.transfer(usdAnchor.address, toBigInt(30000));
            await pusd.transfer(usdAnchor.address, toBigInt(10000));
            console.log('13. addr1.skim()');
            let receipt = await usdAnchor.connect(addr1).skim();
            await showReceipt(receipt);
            status = await getStatus();
            console.log(status);
        }

        if (true) {
            console.log('14. addr1.redeem()');
            await cofi.connect(addr1).approve(cofixDAO.address, toBigInt('0.0001'));
            await cofixDAO.connect(addr1).redeem(toBigInt('0.0001'), addr1.address, { value: toBigInt('0.1')});
            status = await getStatus();
            console.log(status);
            console.log('quotaOf: ' + await cofixDAO.quotaOf());
        }

        // for(var i = 0; i < 200; ++i) {
        //     await dai.transfer(usdAnchor.address, toBigInt(0));
        //     console.log('quotaOf: ' + await cofixDAO.quotaOf());
        // }
        console.log('totalETHRewards: ' + await cofixDAO.totalETHRewards('0x0000000000000000000000000000000000000000'));

        if (true) {
            console.log('15. migrate')
            console.log('addr1 gov: ' + await cofixGovernance.getGovernance(addr1.address));
            console.log('addr1 gov check: ' + await cofixGovernance.checkGovernance(addr1.address, 0));
            await cofixGovernance.setGovernance(addr1.address, 1);
            await usdtPair.connect(addr1).migrate('0x0000000000000000000000000000000000000000', toBigInt(1));
            await nestPair.connect(addr1).migrate(nest.address, toBigInt(20000));
            status = await getStatus();
            console.log(status);
            console.log('addr1 gov: ' + await cofixGovernance.getGovernance(addr1.address));
            console.log('addr1 gov check: ' + await cofixGovernance.checkGovernance(addr1.address, 0));
        }

        if (true) {
            console.log('16. getBuiltinAddress');
            console.log(await cofixGovernance.getBuiltinAddress());

            expect(await cofixGovernance.getCoFiTokenAddress()).to.equal((await cofixGovernance.getBuiltinAddress()).cofiToken);
            expect(await cofixGovernance.getCoFiNodeAddress()).to.equal((await cofixGovernance.getBuiltinAddress()).cofiNode);
            expect(await cofixGovernance.getCoFiXDAOAddress()).to.equal((await cofixGovernance.getBuiltinAddress()).cofixDAO);
            expect(await cofixGovernance.getCoFiXRouterAddress()).to.equal((await cofixGovernance.getBuiltinAddress()).cofixRouter);
            expect(await cofixGovernance.getCoFiXControllerAddress()).to.equal((await cofixGovernance.getBuiltinAddress()).cofixController);
            expect(await cofixGovernance.getCoFiXVaultForStakingAddress()).to.equal((await cofixGovernance.getBuiltinAddress()).cofixVaultForStaking);

            await cofixGovernance.setBuiltinAddress(
                cofi.address,
                cnode.address,
                cofixDAO.address,
                '0x1234567812345678123456781234567812345678',
                cofixController.address,
                cofixVaultForStaking.address
            );
            console.log(await cofixGovernance.getBuiltinAddress());

            expect(await cofixGovernance.getCoFiTokenAddress()).to.equal((await cofixGovernance.getBuiltinAddress()).cofiToken);
            expect(await cofixGovernance.getCoFiNodeAddress()).to.equal((await cofixGovernance.getBuiltinAddress()).cofiNode);
            expect(await cofixGovernance.getCoFiXDAOAddress()).to.equal((await cofixGovernance.getBuiltinAddress()).cofixDAO);
            expect(await cofixGovernance.getCoFiXRouterAddress()).to.equal('0x1234567812345678123456781234567812345678');
            expect(await cofixGovernance.getCoFiXControllerAddress()).to.equal((await cofixGovernance.getBuiltinAddress()).cofixController);
            expect(await cofixGovernance.getCoFiXVaultForStakingAddress()).to.equal((await cofixGovernance.getBuiltinAddress()).cofixVaultForStaking);

            console.log('cofix.empty: ' + await cofixGovernance.checkAddress('cofix.empty'));
            await cofixGovernance.registerAddress('cofix.empty', '0x1234567812345678123456781234567812345678');
            console.log('cofix.empty: ' + await cofixGovernance.checkAddress('cofix.empty'));

            console.log('usdt.exchange: ' + await cofixDAO.getTokenExchange(usdt.address));
            console.log('pusd.exchange: ' + await cofixDAO.getTokenExchange(pusd.address));
            console.log('dai.exchange: ' + await cofixDAO.getTokenExchange(dai.address));

            console.log('eth.exchange: ' + await cofixDAO.getTokenExchange('0x0000000000000000000000000000000000000000'));
            console.log('peth.exchange: ' + await cofixDAO.getTokenExchange(peth.address));
            //console.log('weth.exchange: ' + await cofixDAO.getTokenExchange(weth.address));
        }
    });
});
