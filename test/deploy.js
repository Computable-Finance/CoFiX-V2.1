const { expect } = require('chai');
const deployer = require('../scripts/deploy.js');

describe('CoFiXRouter', function() {
    it('test1', async function() {

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
            nestPriceFacade,

            nest,
            usdt,
            hbtc,
            usdtPair,
            hbtcPair,
            nestPair,
            cofiPair,
            usdAnchor,
            ethAnchor,

            xeth,
            xpeth,
            xusdt,
            xpusd,
            xusdc,

            pusd,
            usdc,
            weth
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

        // // 1. cofi转账
        // await cofi.mint(owner.address, toBigInt(10000000));

        // // 2. 开通cofi挖矿
        // const nTokenController = await ethers.getContractAt('INTokenController', '0xb75Fd1a678dAFE00cEafc8d9e9B1ecf75cd6afC5');
        // await cofi.approve(nTokenController.address, 1);
        // await nTokenController.open(cofi.address);

        // 3. cofi报价
        // const ntokenMining = await ethers.getContractAt('INestMining', '0xb984cCe9fdA423c5A18DFDE4a7bCdfC150DC1012');
        // //await cofi.approve(ntokenMining.address, toBigInt(10000000));
        // await ntokenMining.post(cofi.address, 10, toBigInt(2565), {
        //     value: toBigInt(10.1)
        // });

        const cfg = function (c) {
            return {
                theta: c.theta.toString(),
                impactCostVOL: c.impactCostVOL.toString(),
                nt: c.nt.toString()
            };
        }
        const eth = { address: '0x0000000000000000000000000000000000000000' };

        // await usdt.transfer(owner.address, 0, { nonce: 1973, gasPrice: 10e8 });
        // await usdt.transfer(owner.address, 1, { nonce: 1973, gasPrice: 11e8 })
        // return;
        // console.log('pairFor(eth/usdt)=' + await cofixRouter.pairFor(eth.address, usdt.address));
        // console.log('pairFor(usdt/eth)=' + await cofixRouter.pairFor(usdt.address, eth.address));

        // const chi = async function(xtoken) {
        //     let v = await cofixVaultForStaking.getChannelInfo(xtoken);
        //     return {
        //         totalStaked: v.totalStaked.toString(),
        //         cofiPerBlock: v.cofiPerBlock.toString()
        //     };
        // }
        // console.log('getChannelInfo(cnode)=', await chi(cnode.address));
        // console.log('getChannelInfo(usdtPair)=', await chi(usdtPair.address));
        // console.log('getChannelInfo(hbtcPair)=', await chi(hbtcPair.address));
        // console.log('getChannelInfo(nestPair)=', await chi(nestPair.address));
        // console.log('getChannelInfo(cofiPair)=', await chi(cofiPair.address));
        // console.log('getChannelInfo(xeth)=', await chi(xeth.address));
        // console.log('getChannelInfo(xpeth)=', await chi(xpeth.address));
        // console.log('getChannelInfo(xusdt)=', await chi(xusdt.address));
        // console.log('getChannelInfo(xpusd)=', await chi(xpusd.address));
        // console.log('getChannelInfo(xusdc)=', await chi(xusdc.address));

        await console.log('usdtPair: ', cfg(await usdtPair.getConfig()));
        await console.log('hbtcPair: ', cfg(await hbtcPair.getConfig()));
        await console.log('nestPair: ', cfg(await nestPair.getConfig()));
        await console.log('cofiPair: ', cfg(await cofiPair.getConfig()));

        await console.log('ethAnchor: ', cfg(await ethAnchor.getConfig()));
        await console.log('usdAnchor: ', cfg(await usdAnchor.getConfig()));

        return;
        console.log('16. ethAnchor.setConfig()');
        await ethAnchor.setConfig(20, 0, '0');
        console.log('17. usdAnchor.setConfig()');
        await usdAnchor.setConfig(20, 0, '0');

        return;
    //     cnode.address,
    //     usdtPair.address,
    //     hbtcPair.address,
    //     nestPair.address,
    //     cofiPair.address,
    //     xeth.address,
    //     xpeth.address,
    //     xusdt.address,
    //     xpusd.address,
    //     xusdc.address
        console.log('18. cofixVaultForStaking.batchSetPoolWeight()');
        await cofixVaultForStaking.batchSetPoolWeight([
            // LP-usdt speed ** 0CoFi/block **
            usdtPair.address,
            // LP-xeth speed 	** 0.2CoFi/block **
            xeth.address,
            // LP-xusdt speed 	** 0.2CoFi/block **
            xusdt.address,
            // LP-xpusd speed 	** 0.15CoFi/block **
            xpusd.address
        ], [0, 20, 20, 15]);

        console.log('24. registerPair(eth.address, usdt.address, usdtPair.address)');
        await cofixRouter.registerPair(eth.address, usdt.address, '0x0000000000000000000000000000000000000000');

        console.log('ok');
        
        return;
        // if (true) {
        //     console.log('0. 设置价格');
        //     await nestPriceFacade.setPrice(usdt.address, toBigInt('2051', 6), 1);
        //     await nestPriceFacade.setPrice(nest.address, toBigInt('192307'), 1);
        //     await nestPriceFacade.setPrice(cofi.address, toBigInt('3000'), 1);
        // }

        // let pi = await nestPriceFacade.latestPriceView(nest.address);
        // console.log({
        //     blockNumber: pi.blockNumber.toString(),
        //     price: pi.price.toString()
        // });

        // let navps = await nestPair.getNAVPerShare('1000000000000000000', pi.price);
        // console.log('navps: ' + navps); 

        return;

        console.log('xusdt: ' + await usdAnchor.getXToken(usdt.address));
        console.log('xpusd: ' + await usdAnchor.getXToken(pusd.address));
        console.log('xusdc: ' + await usdAnchor.getXToken(usdc.address));
        //console.log('xweth: ' + await usdAnchor.getXToken(weth.address));
        

        // await usdt.transfer(owner.address, BigInt('10000000000000'));
        // await usdt.approve(cofixRouter.address, BigInt('10000000000000'));
        
        // if (true) {
        //     // 1. 添加2eth的流动性，预期获得1999999999000000000份额
        //     let receipt = await cofixRouter.addLiquidity(
        //         usdt.address,
        //         BigInt('2000000000000000000'),
        //         BigInt('6000000000'),
        //         BigInt('900000000000000000'),
        //         owner.address,
        //         BigInt('1723207627371'), {
        //             value: BigInt('2010000000000000000')
        //         }
        //     );
        //     console.log((await receipt.wait()).gasUsed.toString());

        //     let liquidity = await pair.balanceOf(owner.address);
        //     //expect(liquidity).to.equal(BigInt('2000000000000000000'));
        //     expect(liquidity).to.equal(BigInt('1999999999000000000'));
        //     expect(await ethers.provider.getBalance(pair.address)).to.equal(BigInt('2000000000000000000'));
        //     expect(await usdt.balanceOf(pair.address)).to.equal('6000000000');
        //     expect(await cofixVaultForStaking.balanceOf(pair.address, owner.address)).to.equal('0');
        // }
        
        if (true) {

        }

        //     console.log((await receipt.wait()).gasUsed.toString());
        //     let liquidity = await pair.balanceOf(owner.address);
        //     expect(liquidity).to.equal(BigInt('1999999999000000000'));
        //     expect(await ethers.provider.getBalance(pair.address)).to.equal(BigInt('4000000000000000000'));
        //     expect(await usdt.balanceOf(pair.address)).to.equal('12000000000');

        //     await usdt.transfer(owner.address, 0);
        //     console.log('staked: ' + (await cofixVaultForStaking.balanceOf(pair.address, owner.address)).toString());
        //     console.log('[owner earned]: ' + (await cofixVaultForStaking.earned(pair.address, owner.address)).toString());

        //     expect(await cofixVaultForStaking.balanceOf(pair.address, owner.address)).to.equal('2000000000000000000');
        // }

        // await usdt.transfer(addr1.address, BigInt('5000000000000'));
        // await usdt.connect(addr1).approve(cofixRouter.address, BigInt('10000000000000')); 
        // if (true) {
        //     let receipt = await cofixRouter.connect(addr1).addLiquidityAndStake(
        //         usdt.address,
        //         BigInt('2000000000000000000'),
        //         BigInt('6000000000'),
        //         BigInt('900000000000000000'),
        //         addr1.address,
        //         BigInt('1723207627371'), {
        //             value: BigInt('2010000000000000000')
        //         }
        //     );

        //     let liquidity = await pair.balanceOf(addr1.address);
        //     expect(liquidity).to.equal('0');
        //     expect(await ethers.provider.getBalance(pair.address)).to.equal('6000000000000000000');
        //     expect(await usdt.balanceOf(pair.address)).to.equal('18000000000');

        //     expect(await cofixVaultForStaking.balanceOf(pair.address, addr1.address)).to.equal('2000000000000000000');
        // }

        // console.log('-----------------------');
        // if (true) {
        //     await usdt.transfer(owner.address, 0);
        //     console.log('[owner earned]: ' + (await cofixVaultForStaking.earned(pair.address, owner.address)).toString());
        //     console.log('[addr1 earned]: ' + (await cofixVaultForStaking.earned(pair.address, addr1.address)).toString());
        // }

        // if (true) {
        //     console.log('---- swap ----');
        //     console.log('addr2 balance: ' + (await ethers.provider.getBalance(addr2.address)).toString());
        //     console.log('addr2 usdt:' + (await usdt.balanceOf(addr2.address)).toString());
        //     console.log('addr2 cofi:' + (await cofi.balanceOf(addr2.address)).toString());

        //     let receipt = await cofixRouter.connect(addr2).swapExactETHForTokens(
        //         // 目标token地址
        //         usdt.address,
        //         // eth数量
        //         BigInt('1000000000000000000'),
        //         // 预期获得的token的最小数量
        //         BigInt('100'),
        //         // 接收地址
        //         addr2.address,
        //         // 出矿接收地址
        //         addr2.address,
        //         BigInt('1723207627371'), {
        //             value: BigInt('1010000000000000000')
        //         }
        //     )

        //     console.log('addr2 balance: ' + (await ethers.provider.getBalance(addr2.address)).toString());
        //     console.log('addr2 usdt:' + (await usdt.balanceOf(addr2.address)).toString());
        //     console.log('addr2 cofi:' + (await cofi.balanceOf(addr2.address)).toString());

        //     await usdt.connect(addr2).approve(cofixRouter.address, BigInt('1989514326'));
        //     receipt = await cofixRouter.connect(addr2).swapExactTokensForETH(
        //         usdt.address,
        //         BigInt('1989514326'),
        //         BigInt('100'),
        //         addr2.address,
        //         // 出矿接收地址
        //         addr2.address,
        //         BigInt('1723207627371'), {
        //             value: BigInt('10000000000000000')
        //         }
        //     );

        //     console.log('addr2 balance: ' + (await ethers.provider.getBalance(addr2.address)).toString());
        //     console.log('addr2 usdt:' + (await usdt.balanceOf(addr2.address)).toString());
        //     console.log('addr2 cofi:' + (await cofi.balanceOf(addr2.address)).toString());
        // }
    });
});
