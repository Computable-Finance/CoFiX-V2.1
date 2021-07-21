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
            account = account.address;
            return {
                eth: toDecimal(await ethers.provider.getBalance(account)),
                //usdt: toDecimal(await usdt.balanceOf(account), 6),
                //hbtc: toDecimal(await hbtc.balanceOf(account)),
                //nest: toDecimal(await nest.balanceOf(account)),
                cofi: toDecimal(await cofi.balanceOf(account)),
                pusd: toDecimal(await pusd.balanceOf(account)),
                // dai: toDecimal(await dai.balanceOf(account)),
                // peth: toDecimal(await peth.balanceOf(account)),
                // usdtPair: await getXTokenInfo(account, usdtPair),
                // hbtcPair: await getXTokenInfo(account, hbtcPair),
                // nestPair: await getXTokenInfo(account, nestPair),
                // cofiPair: await getXTokenInfo(account, cofiPair),
                // xusdt: await getXTokenInfo(account, xusdt),
                // xpusd: await getXTokenInfo(account, xpusd),
                // xdai : await getXTokenInfo(account, xdai),
                // xpeth: await getXTokenInfo(account, peth),
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
                //hbtcPair: await getAccountInfo(hbtcPair),
                //nestPair: await getAccountInfo(nestPair),
                //cofiPair: await getAccountInfo(cofiPair),
                //ethAnchor: await getAccountInfo(ethAnchor),
                usdAnchor: await getAccountInfo(usdAnchor),
                owner: await getAccountInfo(owner),
                //addr1: await getAccountInfo(addr1),
                //dao: await getAccountInfo(cofixDAO),
                //addr2: await getAccountInfo(addr2)
            };
        }

        let status;
        let p;

        // let nestQuery = await ethers.getContractAt('INestQuery', nestPriceFacade.address);
        // let pi = await nestQuery.lastPriceListAndTriggeredPriceInfo(usdt.address, 2);
        // console.log({
        //     h0: pi.prices[0].toString(),
        //     p0: pi.prices[1].toString(),
        //     h1: pi.prices[2].toString(),
        //     p1: pi.prices[3].toString(),
        //     triggeredPriceBlockNumber: pi.triggeredPriceBlockNumber.toString(),
        //     triggeredPriceValue: pi.triggeredPriceValue.toString(),
        //     triggeredAvgPrice: pi.triggeredAvgPrice.toString(),
        //     triggeredSigmaSQ: pi.triggeredSigmaSQ.toString()
        // });

        if (true) {
            console.log('1. 初始化资金');
            // await cofi.addMinter(owner.address);
            // // await usdt.transfer(addr1.address, toBigInt(10000000, 6));
            // // await hbtc.transfer(addr1.address, toBigInt(10000000));
            // // await nest.transfer(addr1.address, toBigInt(10000000));
            // // //await cofi.transfer(addr1.address, toBigInt(10000000));
            // // await pusd.transfer(addr1.address, toBigInt(10000000));
            // // await dai .transfer(addr1.address, toBigInt(10000000));
            // // await peth.transfer(addr1.address, toBigInt(10000000));
            // // await cofi.mint(addr1.address, toBigInt(10000000));

            // //await usdt.transfer(owner.address, toBigInt(10000000, 6));
            // await hbtc.transfer(owner.address, toBigInt(10000000));
            // await nest.transfer(owner.address, toBigInt(10000000));
            // //await cofi.transfer(owner.address, toBigInt(10000000));
            // await pusd.transfer(owner.address, toBigInt(10000000));
            // await dai .transfer(owner.address, toBigInt(10000000));
            // await peth.transfer(owner.address, toBigInt(10000000));
            // await cofi.mint(owner.address, toBigInt(10000000));

            //status = await getStatus();
            //console.log(status);
        }

        if (false) {
            console.log('2. 做市1eth|usdt');
            // await usdt.approve(cofixRouter.address, toBigInt(2000, 6));
            // let receipt = await cofixRouter.addLiquidity(
            //     usdtPair.address,
            //     usdt.address,
            //     toBigInt(1),
            //     toBigInt(2000, 6),
            //     toBigInt('0.900000000000000000'),
            //     owner.address,
            //     BigInt('1800000000000'), {
            //         value: BigInt('1010000000000000000')
            //     }
            // );
            // showReceipt(receipt);
            status = await getStatus();
            console.log(status);
        }

        if (false) {
            console.log('3. 做市1eth|hbtc');
            (await hbtc.approve(cofixRouter.address, toBigInt(0.05))).wait();
            let receipt = await cofixRouter.addLiquidity(
                hbtcPair.address,
                hbtc.address,
                toBigInt(1),
                toBigInt(0.05),
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

        if (false) {
            // console.log('4. 做市1eth|nest');
            // await nest.approve(cofixRouter.address, toBigInt(100000));
            // let receipt = await cofixRouter.addLiquidity(
            //     nestPair.address,
            //     nest.address,
            //     toBigInt(1),
            //     toBigInt(100000),
            //     toBigInt('0.900000000000000000'),
            //     owner.address,
            //     BigInt('1800000000000'), {
            //         value: BigInt('1010000000000000000')
            //     }
            // );
            // showReceipt(receipt);
            status = await getStatus();
            console.log(status);
        }

        if (false) {
            console.log('5. 做市1eth|cofi');
            await cofi.approve(cofixRouter.address, toBigInt(2000));
            let receipt = await cofixRouter.addLiquidity(
                cofiPair.address,
                cofi.address,
                toBigInt(1),
                toBigInt(2000),
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

        if (false) {
            console.log('6. 做市1eth');
            let receipt = await cofixRouter.addLiquidity(
                ethAnchor.address,
                '0x0000000000000000000000000000000000000000',
                toBigInt(0),
                toBigInt(1),
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

        if (false) {
            console.log('7. 做市1peth');
            await peth.approve(cofixRouter.address, toBigInt(1));
            let receipt = await cofixRouter.addLiquidity(
                ethAnchor.address,
                peth.address,
                toBigInt(0),
                toBigInt(1),
                toBigInt('0.900000000000000000'),
                owner.address,
                BigInt('1800000000000'), {
                    value: BigInt('10000000000000000')
                }
            );
            showReceipt(receipt);
            status = await getStatus();
            console.log(status);
        }

        if (false) {
            console.log('8. 做市2000usdt');
            await usdt.approve(cofixRouter.address, toBigInt(2000, 6));
            let receipt = await cofixRouter.addLiquidity(
                usdAnchor.address,
                usdt.address,
                toBigInt(0),
                toBigInt(2000, 6),
                toBigInt('0.900000000000000000'),
                owner.address,
                BigInt('1800000000000'), {
                    value: BigInt('10000000000000000')
                }
            );
            showReceipt(receipt);
            status = await getStatus();
            console.log(status);
        }

        if (false) {
            console.log('9. 做市2000pusd');
            await pusd.approve(cofixRouter.address, toBigInt(2000));
            let receipt = await cofixRouter.addLiquidity(
                usdAnchor.address,
                pusd.address,
                toBigInt(0),
                toBigInt(2000),
                toBigInt('0.900000000000000000'),
                owner.address,
                BigInt('1800000000000'), {
                    value: BigInt('10000000000000000')
                }
            );
            showReceipt(receipt);
            status = await getStatus();
            console.log(status);
        }

        if (false) {
            console.log('10. 做市2000dai');
            //await dai.approve(cofixRouter.address, toBigInt(2000));
            let receipt = await cofixRouter.addLiquidity(
                usdAnchor.address,
                dai.address,
                toBigInt(0),
                toBigInt(2000),
                toBigInt('0.900000000000000000'),
                owner.address,
                BigInt('1800000000000'), {
                    value: BigInt('10000000000000000')
                }
            );
            showReceipt(receipt);
            status = await getStatus();
            console.log(status);
        }

        if (true) {
            console.log('11. 路由兑换1000usdt');
            let path = [
                usdt.address,
                '0x0000000000000000000000000000000000000000',
            ];
            await usdt.approve(cofixRouter.address, toBigInt(10, 6));
            let receipt = await cofixRouter.swapExactTokensForTokens(
                path,
                toBigInt(10, 6),
                0,
                owner.address,
                owner.address,
                BigInt('1800000000000'), {
                    value: BigInt('80000000000000000')
                }
            );
            showReceipt(receipt);
            status = await getStatus();
            console.log(status);
        }
        return;
        if (true) {
            console.log('11. 路由兑换1000usdt');
            let path = [
                usdt.address,
                '0x0000000000000000000000000000000000000000',
                peth.address,
                '0x0000000000000000000000000000000000000000',
                usdt.address,
                dai.address,
                pusd.address,
                usdt.address,
                '0x0000000000000000000000000000000000000000',
                cofi.address,
                '0x0000000000000000000000000000000000000000',
                nest.address,
                '0x0000000000000000000000000000000000000000',
                usdt.address
            ];
            await usdt.connect(addr1).approve(cofixRouter.address, toBigInt(1000, 6));
            let receipt = await cofixRouter.connect(addr1).swapExactTokensForTokens(
                path,
                toBigInt(1000, 6),
                0,
                addr1.address,
                addr1.address,
                BigInt('1800000000000'), {
                    value: BigInt('80000000000000000')
                }
            );
            showReceipt(receipt);
            status = await getStatus();
            console.log(status);
        }
        // ** rinkeby@20210720 **
        // usdt: 0x20125a7256EFafd0d4Eec24048E08C5045BC5900
        // hbtc: 0xaE73d363Cb4aC97734E07e48B01D0a1FF5D1190B
        // peth: 0xd5Dfe6355EeBE918a23d70f5399Bb08F8a1BD588
        // pusd: 0x01A8088947B1222a5dC5a13C45b845E0361EEFF7
        // dai: 0xFe027e6243Cd9b94772fA07c0b5fcD3D03D55c92
        // nest: 0xE313F3f49B647fBEDDC5F2389Edb5c93CBf4EE25
        // nestPriceFacade: 0x40C3EB032f27fDa7AdcF1B753c75B84e27f26838
        // cnode: 0xa818c471Ab162a1d7669Ab04b023Ebac38DDCA64
        // cofi: 0x6b3077dcEe0975017BDd1a7eA9E12d3D9F398695
        // cofixGovernance: 0x6843dA9a5DB73f68dDC97079fEeaaC6ca474EcbF
        // cofixDAO: 0x1F4B92d91D803c6f90A36A01168721d048E2b0d6
        // cofixRouter: 0xD2A6D4744027aBCE6781955674ffc04DcdEA7570
        // cofixVaultForStaking: 0xf952Cb518BD7F72F600c6aEA0A8CcFBeabe7c9C0
        // cofixController: 0xC18B1feb7F41521cDAaa4ad5E0e5a8c54D0FF4a5
        // usdtPair: 0x5930c58d71b83bc4586D13f5767aa921ca8B4143
        // hbtcPair: 0xF91809d869082DaEc8ed4fa36cB9423C2132726B
        // nestPair: 0x9eD5c27a4527927a4eF8cAa36547CAb502631A69
        // cofiPair: 0xF3Ef9e8Cbdd0424E0B152709358749155697C2d6
        // ethAnchor: 0x6Bba09C78b7CB6f559341BfFacCF19f5FD8AdAE6
        // usdAnchor: 0x4Ac7ea8AfF091D12C38b5A7Cf049482298656DE6
        // xeth: 0xF6992866092c2E85711aedBCDcEDa7ceE6eBbdb1
        // xpeth: 0x4034e0afC49f6ed8bE2E144A5240DaA993C87F88
        // xusdt: 0x927e7d1deaC7C2c9bCB74Df28e62eA8e7d3dDF18
        // xpusd: 0xB9a8cD49ba5BA661c490cFeADAC50A76b0c37367
        // xdai: 0x6683fBE911E71EEd849e2225E8FAe6CF9F8AAC9a

        // usdt->eth->nest->eth->cofi->eth->peth->eth->usdt->dai->pusd
        // 0x20125a7256EFafd0d4Eec24048E08C5045BC5900->0x0000000000000000000000000000000000000000->0xE313F3f49B647fBEDDC5F2389Edb5c93CBf4EE25->0x0000000000000000000000000000000000000000->0x6b3077dcEe0975017BDd1a7eA9E12d3D9F398695->0x0000000000000000000000000000000000000000->0xd5Dfe6355EeBE918a23d70f5399Bb08F8a1BD588->0x0000000000000000000000000000000000000000->0x20125a7256EFafd0d4Eec24048E08C5045BC5900->0xFe027e6243Cd9b94772fA07c0b5fcD3D03D55c92->0x01A8088947B1222a5dC5a13C45b845E0361EEFF7
        // ['0x20125a7256EFafd0d4Eec24048E08C5045BC5900', '0x0000000000000000000000000000000000000000', '0xE313F3f49B647fBEDDC5F2389Edb5c93CBf4EE25', '0x0000000000000000000000000000000000000000', '0x6b3077dcEe0975017BDd1a7eA9E12d3D9F398695', '0x0000000000000000000000000000000000000000', '0xd5Dfe6355EeBE918a23d70f5399Bb08F8a1BD588', '0x0000000000000000000000000000000000000000', '0x20125a7256EFafd0d4Eec24048E08C5045BC5900', '0xFe027e6243Cd9b94772fA07c0b5fcD3D03D55c92', '0x01A8088947B1222a5dC5a13C45b845E0361EEFF7']
    });
});
