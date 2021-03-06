// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { ethers, upgrades } = require('hardhat');

exports.deploy = async function () {
    
    const eth = { address: '0x0000000000000000000000000000000000000000' };
    const TestERC20 = await ethers.getContractFactory('TestERC20');
    const NestPriceFacade = await ethers.getContractFactory('NestPriceFacade');
    const CoFiToken = await ethers.getContractFactory('CoFiToken');
    const CoFiXGovernance = await ethers.getContractFactory('CoFiXGovernance');
    const CoFiXDAO = await ethers.getContractFactory('CoFiXDAO');
    const CoFiXRouter = await ethers.getContractFactory('CoFiXRouter');
    const CoFiXVaultForStaking = await ethers.getContractFactory('CoFiXVaultForStaking');
    const CoFiXController = await ethers.getContractFactory('CoFiXController');
    const CoFiXPair = await ethers.getContractFactory('CoFiXPair');
    const CoFiXAnchorPool = await ethers.getContractFactory('CoFiXAnchorPool');
    const CoFiXAnchorToken = await ethers.getContractFactory('CoFiXAnchorToken');

    console.log('** rinkeby@20210720 **');
    
    // ** rinkeby@20210720 **
    // usdt: 0x20125a7256EFafd0d4Eec24048E08C5045BC5900
    // hbtc: 0xaE73d363Cb4aC97734E07e48B01D0a1FF5D1190B
    // peth: 0xd5Dfe6355EeBE918a23d70f5399Bb08F8a1BD588
    // pusd: 0x01A8088947B1222a5dC5a13C45b845E0361EEFF7
    // usdc: 0xFe027e6243Cd9b94772fA07c0b5fcD3D03D55c92
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
    // xusdc: 0x6683fBE911E71EEd849e2225E8FAe6CF9F8AAC9a

    // 1. Deploy dependent contract
    //const usdt = await TestERC20.deploy('USDT', 'USDT', 6);
    const usdt = await TestERC20.attach('0x20125a7256EFafd0d4Eec24048E08C5045BC5900');
    console.log('usdt: ' + usdt.address);

    //const hbtc = await TestERC20.deploy('HBTC', 'HBTC', 18);
    const hbtc = await TestERC20.attach('0xaE73d363Cb4aC97734E07e48B01D0a1FF5D1190B');
    console.log('hbtc: ' + hbtc.address);

    //let peth = await TestERC20.deploy('PETH', 'PETH', 18);
    const peth = await TestERC20.attach('0xd5Dfe6355EeBE918a23d70f5399Bb08F8a1BD588');
    console.log('peth: ' + peth.address);

    //let pusd = await TestERC20.deploy('PUSD', 'PUSD', 18);
    const pusd = await TestERC20.attach('0x01A8088947B1222a5dC5a13C45b845E0361EEFF7');
    console.log('pusd: ' + pusd.address);

    //let usdc = await TestERC20.deploy('USDC', 'USDC', 6);
    const usdc = await TestERC20.attach('0xFe027e6243Cd9b94772fA07c0b5fcD3D03D55c92');
    console.log('usdc: ' + usdc.address);

    //const nest = await TestERC20.deploy('NEST', 'NEST', 18);
    const nest = await TestERC20.attach('0xE313F3f49B647fBEDDC5F2389Edb5c93CBf4EE25');
    console.log('nest: ' + nest.address);
    
    //const nestPriceFacade = await NestPriceFacade.deploy();
    const nestPriceFacade = await NestPriceFacade.attach('0x40C3EB032f27fDa7AdcF1B753c75B84e27f26838');
    console.log('nestPriceFacade: ' + nestPriceFacade.address);
    
    //const cnode = await TestERC20.deploy('CNode', 'CNode', 0);
    const cnode = await TestERC20.attach('0xa818c471Ab162a1d7669Ab04b023Ebac38DDCA64');
    console.log('cnode: ' + cnode.address);

    //const cofi = await CoFiToken.deploy();
    const cofi = await CoFiToken.attach('0x6b3077dcEe0975017BDd1a7eA9E12d3D9F398695');
    console.log('cofi: ' + cofi.address);

    // 2. Deploy structure contract
    //const cofixGovernance = await upgrades.deployProxy(CoFiXGovernance, ['0x0000000000000000000000000000000000000000'], { initializer: 'initialize' });
    const cofixGovernance = await CoFiXGovernance.attach('0x6843dA9a5DB73f68dDC97079fEeaaC6ca474EcbF');
    console.log('cofixGovernance: ' + cofixGovernance.address);
    
    //const cofixDAO = await upgrades.deployProxy(CoFiXDAO, [cofixGovernance.address], { initializer: 'initialize' });
    const cofixDAO = await CoFiXDAO.attach('0x1F4B92d91D803c6f90A36A01168721d048E2b0d6');
    console.log('cofixDAO: ' + cofixDAO.address);
    
    //const cofixRouter = await upgrades.deployProxy(CoFiXRouter, [cofixGovernance.address], { initializer: 'initialize' });
    const cofixRouter = await CoFiXRouter.attach('0xD2A6D4744027aBCE6781955674ffc04DcdEA7570');
    console.log('cofixRouter: ' + cofixRouter.address);
        
    //const cofixVaultForStaking = await upgrades.deployProxy(CoFiXVaultForStaking, [cofixGovernance.address], { initializer: 'initialize' });
    const cofixVaultForStaking = await CoFiXVaultForStaking.attach('0xf952Cb518BD7F72F600c6aEA0A8CcFBeabe7c9C0');
    console.log('cofixVaultForStaking: ' + cofixVaultForStaking.address);
    
    //const cofixController = await CoFiXController.deploy(nestPriceFacade.address);
    const cofixController = await CoFiXController.attach('0xC18B1feb7F41521cDAaa4ad5E0e5a8c54D0FF4a5');
    console.log('cofixController: ' + cofixController.address);

    // 3. Deploy pool contract
    //const usdtPair = await upgrades.deployProxy(CoFiXPair, [cofixGovernance.address, 'XT-1', 'XToken-1', usdt.address, BigInt(1000000000), BigInt(2)], { initializer: 'init' });
    const usdtPair = await CoFiXPair.attach('0x5930c58d71b83bc4586D13f5767aa921ca8B4143');
    console.log('usdtPair: ' + usdtPair.address);

    //const hbtcPair = await upgrades.deployProxy(CoFiXPair, [cofixGovernance.address, 'XT-2', 'XToken-2', hbtc.address, BigInt(20), BigInt(1)], { initializer: 'init' });
    const hbtcPair = await CoFiXPair.attach('0xF91809d869082DaEc8ed4fa36cB9423C2132726B');
    console.log('hbtcPair: ' + hbtcPair.address);

    //const nestPair = await upgrades.deployProxy(CoFiXPair, [cofixGovernance.address, 'XT-3', 'XToken-3', nest.address, BigInt(1), BigInt(100000)], { initializer: 'init' });
    const nestPair = await CoFiXPair.attach('0x9eD5c27a4527927a4eF8cAa36547CAb502631A69');
    console.log('nestPair: ' + nestPair.address);

    //const cofiPair = await upgrades.deployProxy(CoFiXPair, [cofixGovernance.address, 'XT-4', 'XToken-4', cofi.address, BigInt(1), BigInt(2000)], { initializer: 'init' });
    const cofiPair = await CoFiXPair.attach('0xF3Ef9e8Cbdd0424E0B152709358749155697C2d6');
    console.log('cofiPair: ' + cofiPair.address);

    // Deploy eth anchor pool
    // let ethAnchor = await upgrades.deployProxy(CoFiXAnchorPool, [
    //     cofixGovernance.address, 
    //     0, 
    //     [eth.address, peth.address],
    //     ['1000000000000000000', '1000000000000000000']
    // ], { initializer: 'init' });
    const ethAnchor = await CoFiXAnchorPool.attach('0x6Bba09C78b7CB6f559341BfFacCF19f5FD8AdAE6');
    console.log('ethAnchor: ' + ethAnchor.address);

    // Deploy usd anchor pool
    // let usdAnchor = await upgrades.deployProxy(CoFiXAnchorPool, [
    //     cofixGovernance.address, 
    //     1,
    //     [usdt.address, pusd.address, usdc.address],
    //     [1000000, '1000000000000000000', '1000000000000000000']
    // ], { initializer: 'init' });
    const usdAnchor = await CoFiXAnchorPool.attach('0x4Ac7ea8AfF091D12C38b5A7Cf049482298656DE6');
    console.log('usdAnchor: ' + usdAnchor.address);

    let xeth = await CoFiXAnchorToken.attach(await ethAnchor.getXToken(eth.address));
    console.log('xeth: ' + xeth.address);
    let xpeth = await CoFiXAnchorToken.attach(await ethAnchor.getXToken(peth.address));
    console.log('xpeth: ' + xpeth.address);
    let xusdt = await CoFiXAnchorToken.attach(await usdAnchor.getXToken(usdt.address));
    console.log('xusdt: ' + xusdt.address);
    let xpusd = await CoFiXAnchorToken.attach(await usdAnchor.getXToken(pusd.address));
    console.log('xpusd: ' + xpusd.address);
    let xusdc = await CoFiXAnchorToken.attach(await usdAnchor.getXToken(usdc.address));
    console.log('xusdc: ' + xusdc.address);

    if (false) {
        // 4. Update
        console.log('1. cofixGovernance.setBuiltinAddress');
        await cofixGovernance.setBuiltinAddress(
            cofi.address,
            cnode.address,
            cofixDAO.address,
            cofixRouter.address,
            cofixController.address,
            cofixVaultForStaking.address
        );
        console.log('2. cofixDAO.update');
        await cofixDAO.update(cofixGovernance.address);
        console.log('3. cofixRouter.update');
        await cofixRouter.update(cofixGovernance.address);
        console.log('4. cofixVaultForStaking.update');
        await cofixVaultForStaking.update(cofixGovernance.address);
        console.log('5. usdtPair.update');
        await usdtPair.update(cofixGovernance.address);
        console.log('6. hbtcPair.update');
        await hbtcPair.update(cofixGovernance.address);
        console.log('7. nestPair.update');
        await nestPair.update(cofixGovernance.address);
        console.log('8. cofiPair.update');
        await cofiPair.update(cofixGovernance.address);
        console.log('9. ethAnchor.update(cofixGovernance.address)');
        await ethAnchor.update(cofixGovernance.address);
        console.log('10. usdAnchor.update(cofixGovernance.address)');
        await usdAnchor.update(cofixGovernance.address);

        // 5. Set config
        console.log('11. setConfig');
        await cofixDAO.setConfig({
            // Redeem activate threshold, when the circulation of token exceeds this threshold, 
            // Redeem status, 1 means active
            status: 1,

            // The number of CoFi redeem per block. 100
            cofiPerBlock: 500,

            // The maximum number of CoFi in a single redeem. 30000
            cofiLimit: 150000,

            // Price deviation limit, beyond this upper limit stop redeem (10000 based). 1000
            priceDeviationLimit: 1000
        });

        console.log('12. cofixVaultForStaking.setConfig');
        await cofixVaultForStaking.setConfig({
            cofiUnit: '10000000000000000'
        });

        // 6. Set pool config
        console.log('13. usdtPair.setConfig()');
        await usdtPair.setConfig(20, 1000, 1e8);
        console.log('14. hbtcPair.setConfig()');
        await hbtcPair.setConfig(20, 1000, 1e8);
        console.log('15. nestPair.setConfig()');
        await nestPair.setConfig(20, 50, 1e8);
        console.log('16. cofiPair.setConfig()');
        await cofiPair.setConfig(20, 50, 1e8);
        console.log('17. ethAnchor.setConfig()');
        await ethAnchor.setConfig(20, 0, 1e8);
        console.log('18. usdAnchor.setConfig()');
        await usdAnchor.setConfig(20, 0, 50000);

        // 7. Set staking parameters
        console.log('19. cofixVaultForStaking.batchSetPoolWeight()');
        await cofixVaultForStaking.batchSetPoolWeight([
            cnode.address,
            usdtPair.address,
            hbtcPair.address,
            nestPair.address,
            cofiPair.address,
            xeth.address,
            xpeth.address,
            xusdt.address,
            xpusd.address,
            xusdc.address
        ], [20, 20, 20, 40, 40, 15, 15, 10, 10, 10]);

        // 8. Set exchange parameters
        console.log('20. cofixDAO.setTokenExchange(usdt.address, usdt.address)');
        await cofixDAO.setTokenExchange(usdt.address, usdt.address, BigInt('1000000000000000000'));
        console.log('21. cofixDAO.setTokenExchange(pusd.address, usdt.address)');
        await cofixDAO.setTokenExchange(pusd.address, usdt.address, BigInt(1000000));
        console.log('22. cofixDAO.setTokenExchange(usdc.address, usdt.address)');
        await cofixDAO.setTokenExchange(usdc.address, usdt.address, BigInt(1000000));
        console.log('23. cofixDAO.setTokenExchange(eth.address, eth.address)');
        await cofixDAO.setTokenExchange(eth.address, eth.address, BigInt('1000000000000000000'));
        console.log('24. cofixDAO.setTokenExchange(peth.address, eth.address)');
        await cofixDAO.setTokenExchange(peth.address, eth.address, BigInt('1000000000000000000'));

        // 9. Set minters
        console.log('25. cofi.addMinter(cofixRouter.address)');
        await cofi.addMinter(cofixRouter.address);
        console.log('26. cofi.addMinter(cofixVaultForStaking.address)');
        await cofi.addMinter(cofixVaultForStaking.address);

        // 10. Register pairs
        console.log('27. registerPair(eth.address, usdt.address, usdtPair.address)');
        await cofixRouter.registerPair(eth.address, usdt.address, usdtPair.address);
        console.log('28. registerPair(eth.address, hbtc.address, hbtcPair.address)');
        await cofixRouter.registerPair(eth.address, hbtc.address, hbtcPair.address);
        console.log('29. registerPair(eth.address, nest.address, nestPair.address)');
        await cofixRouter.registerPair(eth.address, nest.address, nestPair.address);
        console.log('30. registerPair(eth.address, cofi.address, cofiPair.address)');
        await cofixRouter.registerPair(eth.address, cofi.address, cofiPair.address);

        // Register eth anchor pool
        console.log('31. registerPair(eth.address, peth.address, ethAnchor.address)');
        await cofixRouter.registerPair(eth.address, peth.address, ethAnchor.address);
        // Register usd anchor pool
        console.log('32. registerPair(usdt.address, pusd.address, usdAnchor.address)');
        await cofixRouter.registerPair(usdt.address, pusd.address, usdAnchor.address);
        console.log('33. registerPair(usdt.address, usdc.address, usdAnchor.address)');
        await cofixRouter.registerPair(usdt.address, usdc.address, usdAnchor.address);
        console.log('34. registerPair(pusd.address, usdc.address, usdAnchor.address)');
        await cofixRouter.registerPair(pusd.address, usdc.address, usdAnchor.address);
    } else {
    }
    if (false) {
        // 11. Register router path
        console.log('35. registerRouterPath(usdt.address, nest.address, [usdt.address, eth.address, nest.address])');
        await cofixRouter.registerRouterPath(usdt.address, nest.address, [usdt.address, eth.address, nest.address]);
        console.log('36. registerRouterPath(usdt.address, peth.address, [usdt.address, eth.address, peth.address])');
        await cofixRouter.registerRouterPath(usdt.address, peth.address, [usdt.address, eth.address, peth.address]);
        
        // eth, nest, usdt, pusd, usdc, peth, cofi, hbtc
        console.log('37. registerRouterPath(pusd.address, eth.address, [pusd.address, usdt.address, eth.address])');
        await cofixRouter.registerRouterPath(pusd.address, eth.address, [pusd.address, usdt.address, eth.address]);
        console.log('38. registerRouterPath(pusd.address, peth.address, [pusd.address, usdt.address, eth.address, peth.address])');
        await cofixRouter.registerRouterPath(pusd.address, peth.address, [pusd.address, usdt.address, eth.address, peth.address]);
        console.log('39. registerRouterPath(pusd.address, nest.address, [pusd.address, usdt.address, eth.address, nest.address])');
        await cofixRouter.registerRouterPath(pusd.address, nest.address, [pusd.address, usdt.address, eth.address, nest.address]);

        console.log('40. registerRouterPath(usdc.address, eth.address, [usdc.address, usdt.address, eth.address])');
        await cofixRouter.registerRouterPath(usdc.address, eth.address, [usdc.address, usdt.address, eth.address]);
        console.log('41. registerRouterPath(usdc.address, peth.address, [usdc.address, usdt.address, eth.address, peth.address])');
        await cofixRouter.registerRouterPath(usdc.address, peth.address, [usdc.address, usdt.address, eth.address, peth.address]);
        console.log('42. registerRouterPath(usdc.address, nest.address, [usdc.address, usdt.address, eth.address, nest.address])');
        await cofixRouter.registerRouterPath(usdc.address, nest.address, [usdc.address, usdt.address, eth.address, nest.address]);

        console.log('43. registerRouterPath(peth.address, nest.address, [peth.address, eth.address, nest.address])');
        await cofixRouter.registerRouterPath(peth.address, nest.address, [peth.address, eth.address, nest.address]);

        console.log('44. registerRouterPath(cofi.address, nest.address, [cofi.address, eth.address, nest.address])');
        await cofixRouter.registerRouterPath(cofi.address, nest.address, [cofi.address, eth.address, nest.address]);
        console.log('45. registerRouterPath(cofi.address, usdt.address, [cofi.address, eth.address, usdt.address])');
        await cofixRouter.registerRouterPath(cofi.address, usdt.address, [cofi.address, eth.address, usdt.address]);
        console.log('46. registerRouterPath(cofi.address, pusd.address, [cofi.address, eth.address, usdt.address, pusd.address])');
        await cofixRouter.registerRouterPath(cofi.address, pusd.address, [cofi.address, eth.address, usdt.address, pusd.address]);
        console.log('47. registerRouterPath(cofi.address, usdc.address, [cofi.address, eth.address, usdt.address, usdc.address])');
        await cofixRouter.registerRouterPath(cofi.address, usdc.address, [cofi.address, eth.address, usdt.address, usdc.address]);
        console.log('48. registerRouterPath(cofi.address, peth.address, [cofi.address, eth.address, peth.address])');
        await cofixRouter.registerRouterPath(cofi.address, peth.address, [cofi.address, eth.address, peth.address]);

        console.log('49. registerRouterPath(hbtc.address, nest.address, [hbtc.address, eth.address, nest.address])');
        await cofixRouter.registerRouterPath(hbtc.address, nest.address, [hbtc.address, eth.address, nest.address]);
        console.log('50. registerRouterPath(hbtc.address, usdt.address, [hbtc.address, eth.address, usdt.address])');
        await cofixRouter.registerRouterPath(hbtc.address, usdt.address, [hbtc.address, eth.address, usdt.address]);
        console.log('51. registerRouterPath(hbtc.address, pusd.address, [hbtc.address, eth.address, usdt.address, pusd.address])');
        await cofixRouter.registerRouterPath(hbtc.address, pusd.address, [hbtc.address, eth.address, usdt.address, pusd.address]);
        console.log('52. registerRouterPath(hbtc.address, usdc.address, [hbtc.address, eth.address, usdt.address, usdc.address])');
        await cofixRouter.registerRouterPath(hbtc.address, usdc.address, [hbtc.address, eth.address, usdt.address, usdc.address]);
        console.log('53. registerRouterPath(hbtc.address, peth.address, [hbtc.address, eth.address, peth.address])');
        await cofixRouter.registerRouterPath(hbtc.address, peth.address, [hbtc.address, eth.address, peth.address]);
        console.log('54. registerRouterPath(hbtc.address, cofi.address, [hbtc.address, eth.address, cofi.address])');
        await cofixRouter.registerRouterPath(hbtc.address, cofi.address, [hbtc.address, eth.address, cofi.address]);
    }

    const contracts = {
        cofi: cofi,
        cnode: cnode,
        cofixDAO: cofixDAO,
        cofixRouter: cofixRouter,
        cofixController: cofixController,
        cofixVaultForStaking: cofixVaultForStaking,
        cofixGovernance: cofixGovernance,
        nestPriceFacade: nestPriceFacade,

        usdt: usdt,
        hbtc: hbtc,
        nest: nest,
        peth: peth,
        pusd: pusd,
        usdc: usdc,

        xeth: xeth,
        xpeth: xpeth,
        xusdt: xusdt,
        xpusd: xpusd,
        xusdc: xusdc,

        usdtPair: usdtPair,
        hbtcPair: hbtcPair,
        nestPair: nestPair,
        cofiPair: cofiPair,
        ethAnchor: ethAnchor,
        usdAnchor: usdAnchor
    };
    
    //console.log(contracts);
    console.log('** Deployed **');
    return contracts;
}
