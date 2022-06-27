const { expect } = require('chai');
const deployer = require('../scripts/deploy.js');
const { ethers, upgrades } = require('hardhat');

describe('deploy', function() {
    it('test1', async function() {

        const [owner, addr1, addr2] = await ethers.getSigners();
        
        // Deploy contract
        const {
            dcu,
            cofixDAO,
            cofixRouter,
            cofixController,
            cofixGovernance,
            nestPriceFacade,

            nest,
            usdt,
            hbtc,
            nest_usdt_pool,
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
            peth,
            nhbtc
        } = await deployer.deploy();

        console.log('ok');
        
        return;
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
        const CoFiXSinglePool = await ethers.getContractFactory('CoFiXSinglePool');

        // cofixSinglePool_nest: 0xA1e3D346297DAa93235f2e39372d4FCDb2230475
        // cofixSinglePool_cofi: 0x8F6b4C4E48fe9B4b24A30037f07099778bAba0a9
        // cofixSinglePool_nhbtc: 0x400a0aA54074C924166e7864A588b1CA0baacaD2

        //const cofixSinglePool_nest = await upgrades.deployProxy(CoFiXSinglePool, [cofixGovernance.address, 'XT-5', 'XToken-5', nest.address], { initializer: 'init' });
        const cofixSinglePool_nest = await CoFiXSinglePool.attach('0xA1e3D346297DAa93235f2e39372d4FCDb2230475');
        console.log('cofixSinglePool_nest: ' + cofixSinglePool_nest.address);

        //const cofixSinglePool_cofi = await upgrades.deployProxy(CoFiXSinglePool, [cofixGovernance.address, 'XT-6', 'XToken-6', cofi.address], { initializer: 'init' });
        const cofixSinglePool_cofi = await CoFiXSinglePool.attach('0x8F6b4C4E48fe9B4b24A30037f07099778bAba0a9');
        console.log('cofixSinglePool_cofi: ' + cofixSinglePool_cofi.address);
        
        //const cofixSinglePool_nhbtc = await upgrades.deployProxy(CoFiXSinglePool, [cofixGovernance.address, 'XT-7', 'XToken-7', nhbtc.address], { initializer: 'init' });
        const cofixSinglePool_nhbtc = await CoFiXSinglePool.attach('0x400a0aA54074C924166e7864A588b1CA0baacaD2');
        console.log('cofixSinglePool_nhbtc: ' + cofixSinglePool_nhbtc.address);

        // console.log('1. cofixSinglePool_nest.update()');
        // await cofixSinglePool_nest.update(cofixGovernance.address);
        // console.log('2. cofixSinglePool_cofi.update()');
        // await cofixSinglePool_cofi.update(cofixGovernance.address);
        // console.log('3. cofixSinglePool_nhbtc.update()');
        // await cofixSinglePool_nhbtc.update(cofixGovernance.address);

        // console.log('4. cofixSinglePool_nest.setConfig()');
        // await cofixSinglePool_nest.setConfig(30, 10, '200');
        // console.log('5. cofixSinglePool_cofi.setConfig()');
        // await cofixSinglePool_cofi.setConfig(30, 10, '500');
        // console.log('6. cofixSinglePool_nhbtc.setConfig()');
        // await cofixSinglePool_nhbtc.setConfig(30, 10, '500');

        // console.log('7. cofixRouter.registerPair(nest)');
        // await cofixRouter.registerPair('0x0000000000000000000000000000000000000000', nest.address, cofixSinglePool_nest.address);
        // console.log('8. cofixRouter.registerPair(cofi)');
        // await cofixRouter.registerPair('0x0000000000000000000000000000000000000000', cofi.address, cofixSinglePool_cofi.address);
        // console.log('9. cofixRouter.registerPair(nhbtc)');
        // await cofixRouter.registerPair('0x0000000000000000000000000000000000000000', nhbtc.address, cofixSinglePool_nhbtc.address);

        // 7. Set staking parameters
        console.log('18. cofixVaultForStaking.batchSetPoolWeight()');
        await cofixVaultForStaking.batchSetPoolWeight([
            cnode.address,
            hbtcPair.address,
            nestPair.address,
            cofiPair.address,
            xeth.address,
            xpeth.address,
            xusdt.address,
            xpusd.address,
            xusdc.address
        ], [0, 0, 0, 0, 0, 0, 0, 0, 0]);
    });
});
