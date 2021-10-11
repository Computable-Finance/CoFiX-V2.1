const { expect } = require('chai');
const deployer = require('../scripts/deploy.js');
const { ethers, upgrades } = require('hardhat');

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
            peth
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

        const CoFiXSinglePool = await ethers.getContractFactory('CoFiXSinglePool');
        
        const cofixSinglePool_nest = await upgrades.deployProxy(CoFiXSinglePool, [cofixGovernance.address, 'XT-5', 'XToken-5', nest.address], { initializer: 'init' });
        console.log('cofixSinglePool_nest: ' + cofixSinglePool_nest.address);
        const cofixSinglePool_cofi = await upgrades.deployProxy(CoFiXSinglePool, [cofixGovernance.address, 'XT-6', 'XToken-6', cofi.address], { initializer: 'init' });
        console.log('cofixSinglePool_cofi: ' + cofixSinglePool_cofi.address);

        console.log('1. cofixSinglePool_nest.update()');
        await cofixSinglePool_nest.update(cofixGovernance.address);
        console.log('2. cofixSinglePool_cofi.update()');
        await cofixSinglePool_cofi.update(cofixGovernance.address);

        console.log('3. cofixSinglePool_nest.setConfig()');
        await cofixSinglePool_nest.setConfig(30, 10, '200');
        console.log('4. cofixSinglePool_cofi.setConfig()');
        await cofixSinglePool_cofi.setConfig(30, 10, '500');

        console.log('5. cofixRouter.registerPair(nest)');
        await cofixRouter.registerPair('0x0000000000000000000000000000000000000000', nest.address, cofixSinglePool_nest.address);
        console.log('6. cofixRouter.registerPair(cofi)');
        await cofixRouter.registerPair('0x0000000000000000000000000000000000000000', cofi.address, cofixSinglePool_cofi.address);
    });
});
