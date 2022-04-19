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

    console.log('** rinkeby@20210726.1.js **');

    // usdt: 0x2d750210c0b5343a0b79beff8F054C9add7d2411
    // hbtc: 0xaE73d363Cb4aC97734E07e48B01D0a1FF5D1190B
    // peth: 0x4D4B378eFbeb7eE15Aa498F3383C9949391557e0
    // pusd: 0x740ed84037E5d2F650b585759623EBC4de849021
    // usdc: 0xB64825a6bA80d65886b5123f5170ddffc935D9DE
    // nest: 0xE313F3f49B647fBEDDC5F2389Edb5c93CBf4EE25
    // nestPriceFacade: 0x40C3EB032f27fDa7AdcF1B753c75B84e27f26838

    // cofi: 0x6e2C8D93a67C4A6bf0Be14ee48f2b8cFE708bca7
    // cn: 0xa1F92f2F51E998ec54d81879f79018F5E7eA2271

    //     ** rinkeby@20210726.1.js **
    // usdt: 0x2d750210c0b5343a0b79beff8F054C9add7d2411
    // hbtc: 0xaE73d363Cb4aC97734E07e48B01D0a1FF5D1190B
    // peth: 0x4D4B378eFbeb7eE15Aa498F3383C9949391557e0
    // pusd: 0x740ed84037E5d2F650b585759623EBC4de849021
    // usdc: 0xB64825a6bA80d65886b5123f5170ddffc935D9DE
    // nest: 0xE313F3f49B647fBEDDC5F2389Edb5c93CBf4EE25
    // nestPriceFacade: 0x40C3EB032f27fDa7AdcF1B753c75B84e27f26838
    // cnode: 0xa1F92f2F51E998ec54d81879f79018F5E7eA2271
    // cofi: 0x6e2C8D93a67C4A6bf0Be14ee48f2b8cFE708bca7
    // cofixGovernance: 0x50e9787E7111f09d09B6E0A2Fd9d2Bf30b1edd99
    // cofixDAO: 0x2906c41Bfa96e54b407525f5E783989742659A4f
    // cofixRouter: 0xB70BF1e054E9a2DF667BfBf198aC7f0F69375728
    // cofixVaultForStaking: 0x3FD3375D5eDB05E1A117D9A61b9f1C6B436c7eCD
    // cofixController: 0x7A44d6dAAE4bafc8908f7913b275f88a63D833f8
    // usdtPair: 0x5A51c246232e4212948554b8161f44e4b735AcF7

    //     ** rinkeby@20210726.1.js **
    // usdt: 0x2d750210c0b5343a0b79beff8F054C9add7d2411
    // hbtc: 0xaE73d363Cb4aC97734E07e48B01D0a1FF5D1190B
    // peth: 0x4D4B378eFbeb7eE15Aa498F3383C9949391557e0
    // pusd: 0x740ed84037E5d2F650b585759623EBC4de849021
    // usdc: 0xB64825a6bA80d65886b5123f5170ddffc935D9DE
    // nest: 0xE313F3f49B647fBEDDC5F2389Edb5c93CBf4EE25
    // nestPriceFacade: 0x40C3EB032f27fDa7AdcF1B753c75B84e27f26838
    // cnode: 0xa1F92f2F51E998ec54d81879f79018F5E7eA2271
    // cofi: 0x6e2C8D93a67C4A6bf0Be14ee48f2b8cFE708bca7
    // cofixGovernance: 0x50e9787E7111f09d09B6E0A2Fd9d2Bf30b1edd99
    // cofixDAO: 0x2906c41Bfa96e54b407525f5E783989742659A4f
    // cofixRouter: 0xB70BF1e054E9a2DF667BfBf198aC7f0F69375728
    // cofixVaultForStaking: 0x3FD3375D5eDB05E1A117D9A61b9f1C6B436c7eCD
    // cofixController: 0x7A44d6dAAE4bafc8908f7913b275f88a63D833f8
    // usdtPair: 0x5A51c246232e4212948554b8161f44e4b735AcF7
    // hbtcPair: 0xf643511AcfdE4577A2e05aD7c44d14ca0F3E8d8c
    // nestPair: 0x48a3504d2173495843e6A71719b29c2Ba0342f00
    // cofiPair: 0x77d954ED22A55A870bB9C07963A0cC37C76C47F8
    // ethAnchor: 0x2d605e6365568304C21146783E4B59619EE406C4
    // usdAnchor: 0x8A86207F5bd49265C4F0421102bc26DC91157b0d
    // xeth: 0x84358F78Bed6a560F8F4edE23161039BE34cF9aC
    // xpeth: 0x73b196C7659Ab400b3A2bC9fAa3f56AcE0D9b672
    // xusdt: 0xBd7ee64e719e519B4607C581Bf181d2C34E32992
    // xpusd: 0xbcf93EEbcEc302926110E207974C37B9E878d701
    // xusdc: 0x818C8B17929a58F9e2093517eD4D594023EbA0c8

    // 1. Deploy dependent contract
    //const usdt = await TestERC20.deploy('USDT', 'USDT', 6);
    const usdt = await TestERC20.attach('0x2d750210c0b5343a0b79beff8F054C9add7d2411');
    console.log('usdt: ' + usdt.address);

    //const hbtc = await TestERC20.deploy('HBTC', 'HBTC', 18);
    const hbtc = await TestERC20.attach('0xaE73d363Cb4aC97734E07e48B01D0a1FF5D1190B');
    console.log('hbtc: ' + hbtc.address);

    //let peth = await TestERC20.deploy('PETH', 'PETH', 18);
    const peth = await TestERC20.attach('0x4D4B378eFbeb7eE15Aa498F3383C9949391557e0');
    console.log('peth: ' + peth.address);

    //let pusd = await TestERC20.deploy('PUSD', 'PUSD', 18);
    const pusd = await TestERC20.attach('0x740ed84037E5d2F650b585759623EBC4de849021');
    console.log('pusd: ' + pusd.address);

    //let usdc = await TestERC20.deploy('USDC', 'USDC', 6);
    const usdc = await TestERC20.attach('0xB64825a6bA80d65886b5123f5170ddffc935D9DE');
    console.log('usdc: ' + usdc.address);

    //const nest = await TestERC20.deploy('NEST', 'NEST', 18);
    const nest = await TestERC20.attach('0xE313F3f49B647fBEDDC5F2389Edb5c93CBf4EE25');
    console.log('nest: ' + nest.address);
    
    //const nestPriceFacade = await NestPriceFacade.deploy();
    const nestPriceFacade = await NestPriceFacade.attach('0x40C3EB032f27fDa7AdcF1B753c75B84e27f26838');
    console.log('nestPriceFacade: ' + nestPriceFacade.address);
    
    //const cnode = await TestERC20.deploy('CNode', 'CNode', 0);
    const cnode = await TestERC20.attach('0xa1F92f2F51E998ec54d81879f79018F5E7eA2271');
    console.log('cnode: ' + cnode.address);

    //const cofi = await CoFiToken.deploy();
    const cofi = await CoFiToken.attach('0x6e2C8D93a67C4A6bf0Be14ee48f2b8cFE708bca7');
    console.log('cofi: ' + cofi.address);

    // 2. Deploy structure contract
    //const cofixGovernance = await upgrades.deployProxy(CoFiXGovernance, ['0x0000000000000000000000000000000000000000'], { initializer: 'initialize' });
    const cofixGovernance = await CoFiXGovernance.attach('0x50e9787E7111f09d09B6E0A2Fd9d2Bf30b1edd99');
    console.log('cofixGovernance: ' + cofixGovernance.address);
    
    //const cofixDAO = await upgrades.deployProxy(CoFiXDAO, [cofixGovernance.address], { initializer: 'initialize' });
    const cofixDAO = await CoFiXDAO.attach('0x2906c41Bfa96e54b407525f5E783989742659A4f');
    console.log('cofixDAO: ' + cofixDAO.address);
    
    //const cofixRouter = await upgrades.deployProxy(CoFiXRouter, [cofixGovernance.address], { initializer: 'initialize' });
    const cofixRouter = await CoFiXRouter.attach('0xB70BF1e054E9a2DF667BfBf198aC7f0F69375728');
    console.log('cofixRouter: ' + cofixRouter.address);
        
    //const cofixVaultForStaking = await upgrades.deployProxy(CoFiXVaultForStaking, [cofixGovernance.address], { initializer: 'initialize' });
    const cofixVaultForStaking = await CoFiXVaultForStaking.attach('0x3FD3375D5eDB05E1A117D9A61b9f1C6B436c7eCD');
    console.log('cofixVaultForStaking: ' + cofixVaultForStaking.address);
    
    //const cofixController = await CoFiXController.deploy(nestPriceFacade.address);
    const cofixController = await CoFiXController.attach('0x7A44d6dAAE4bafc8908f7913b275f88a63D833f8');
    console.log('cofixController: ' + cofixController.address);

    // 3. Deploy pool contract
    //const usdtPair = await upgrades.deployProxy(CoFiXPair, [cofixGovernance.address, 'XT-1', 'XToken-1', usdt.address, BigInt(1000000000), BigInt(2)], { initializer: 'init' });
    const usdtPair = await CoFiXPair.attach('0x5A51c246232e4212948554b8161f44e4b735AcF7');
    console.log('usdtPair: ' + usdtPair.address);

    //const hbtcPair = await upgrades.deployProxy(CoFiXPair, [cofixGovernance.address, 'XT-2', 'XToken-2', hbtc.address, BigInt(20), BigInt(1)], { initializer: 'init' });
    const hbtcPair = await CoFiXPair.attach('0xf643511AcfdE4577A2e05aD7c44d14ca0F3E8d8c');
    console.log('hbtcPair: ' + hbtcPair.address);

    //const nestPair = await upgrades.deployProxy(CoFiXPair, [cofixGovernance.address, 'XT-3', 'XToken-3', nest.address, BigInt(1), BigInt(100000)], { initializer: 'init' });
    const nestPair = await CoFiXPair.attach('0x48a3504d2173495843e6A71719b29c2Ba0342f00');
    console.log('nestPair: ' + nestPair.address);

    //const cofiPair = await upgrades.deployProxy(CoFiXPair, [cofixGovernance.address, 'XT-4', 'XToken-4', cofi.address, BigInt(1), BigInt(2000)], { initializer: 'init' });
    const cofiPair = await CoFiXPair.attach('0x77d954ED22A55A870bB9C07963A0cC37C76C47F8');
    console.log('cofiPair: ' + cofiPair.address);

    // Deploy eth anchor pool
    // let ethAnchor = await upgrades.deployProxy(CoFiXAnchorPool, [
    //     cofixGovernance.address, 
    //     1, 
    //     [eth.address, peth.address],
    //     ['1000000000000000000', '1000000000000000000']
    // ], { initializer: 'init' });
    const ethAnchor = await CoFiXAnchorPool.attach('0x2d605e6365568304C21146783E4B59619EE406C4');
    console.log('ethAnchor: ' + ethAnchor.address);

    // Deploy usd anchor pool
    // let usdAnchor = await upgrades.deployProxy(CoFiXAnchorPool, [
    //     cofixGovernance.address, 
    //     2,
    //     [usdt.address, pusd.address, usdc.address],
    //     [1000000, '1000000000000000000', '1000000000000000000']
    // ], { initializer: 'init' });
    const usdAnchor = await CoFiXAnchorPool.attach('0x8A86207F5bd49265C4F0421102bc26DC91157b0d');
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

    // // 4. Update
    // console.log('1. cofixGovernance.setBuiltinAddress');
    // await cofixGovernance.setBuiltinAddress(
    //     cofi.address,
    //     cnode.address,
    //     cofixDAO.address,
    //     cofixRouter.address,
    //     cofixController.address,
    //     cofixVaultForStaking.address
    // );
    // console.log('2. cofixDAO.update');
    // await cofixDAO.update(cofixGovernance.address);
    // console.log('3. cofixRouter.update');
    // await cofixRouter.update(cofixGovernance.address);
    // console.log('4. cofixVaultForStaking.update');
    // await cofixVaultForStaking.update(cofixGovernance.address);
    // console.log('5. usdtPair.update');
    // await usdtPair.update(cofixGovernance.address);
    // console.log('6. hbtcPair.update');
    // await hbtcPair.update(cofixGovernance.address);
    // console.log('7. nestPair.update');
    // await nestPair.update(cofixGovernance.address);
    // console.log('8. cofiPair.update');
    // await cofiPair.update(cofixGovernance.address);
    // console.log('9. ethAnchor.update(cofixGovernance.address)');
    // await ethAnchor.update(cofixGovernance.address);
    // console.log('10. usdAnchor.update(cofixGovernance.address)');
    // await usdAnchor.update(cofixGovernance.address);

    // // 5. Set config
    // console.log('11. setConfig');
    // await cofixDAO.setConfig({
    //     // Redeem activate threshold, when the circulation of token exceeds this threshold, 
    //     // Redeem status, 1 means active
    //     status: 1,

    //     // The number of CoFi redeem per block. 100
    //     cofiPerBlock: 500,

    //     // The maximum number of CoFi in a single redeem. 30000
    //     cofiLimit: 150000,

    //     // Price deviation limit, beyond this upper limit stop redeem (10000 based). 1000
    //     priceDeviationLimit: 1000
    // });

    // // console.log('12. cofixVaultForStaking.setConfig');
    // // await cofixVaultForStaking.setConfig('10000000000000000');

    // // 6. Set pool config
    // console.log('13. usdtPair.setConfig()');
    // await usdtPair.setConfig(20, 1000, 1e8);
    // console.log('14. hbtcPair.setConfig()');
    // await hbtcPair.setConfig(20, 1000, 1e8);
    // console.log('15. nestPair.setConfig()');
    // await nestPair.setConfig(20, 50, 1e8);
    // console.log('16. cofiPair.setConfig()');
    // await cofiPair.setConfig(20, 50, 1e8);
    // console.log('17. ethAnchor.setConfig()');
    // await ethAnchor.setConfig(20, 0, 1e8);
    // console.log('18. usdAnchor.setConfig()');
    // await usdAnchor.setConfig(20, 0, 50000);

    // // 7. Set staking parameters
    // console.log('19. cofixVaultForStaking.batchSetPoolWeight()');
    // await cofixVaultForStaking.batchSetPoolWeight([
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
    // ], [20, 20, 20, 40, 40, 15, 15, 10, 10, 10]);

    // // 8. Set exchange parameters
    // console.log('20. cofixDAO.setTokenExchange(usdt.address, usdt.address)');
    // await cofixDAO.setTokenExchange(usdt.address, usdt.address, BigInt('1000000000000000000'));
    // console.log('21. cofixDAO.setTokenExchange(pusd.address, usdt.address)');
    // await cofixDAO.setTokenExchange(pusd.address, usdt.address, BigInt(1000000));
    // console.log('22. cofixDAO.setTokenExchange(usdc.address, usdt.address)');
    // await cofixDAO.setTokenExchange(usdc.address, usdt.address, BigInt(1000000));
    // console.log('23. cofixDAO.setTokenExchange(eth.address, eth.address)');
    // await cofixDAO.setTokenExchange(eth.address, eth.address, BigInt('1000000000000000000'));
    // console.log('24. cofixDAO.setTokenExchange(peth.address, eth.address)');
    // await cofixDAO.setTokenExchange(peth.address, eth.address, BigInt('1000000000000000000'));

    // // // 9. Set minters
    // // console.log('25. cofi.addMinter(cofixRouter.address)');
    // // await cofi.addMinter(cofixRouter.address);
    // // console.log('26. cofi.addMinter(cofixVaultForStaking.address)');
    // // await cofi.addMinter(cofixVaultForStaking.address);

    // // 10. Register pairs
    // console.log('27. registerPair(eth.address, usdt.address, usdtPair.address)');
    // await cofixRouter.registerPair(eth.address, usdt.address, usdtPair.address);
    // console.log('28. registerPair(eth.address, hbtc.address, hbtcPair.address)');
    // await cofixRouter.registerPair(eth.address, hbtc.address, hbtcPair.address);
    // console.log('29. registerPair(eth.address, nest.address, nestPair.address)');
    // await cofixRouter.registerPair(eth.address, nest.address, nestPair.address);
    // console.log('30. registerPair(eth.address, cofi.address, cofiPair.address)');
    // await cofixRouter.registerPair(eth.address, cofi.address, cofiPair.address);

    // // Register eth anchor pool
    // console.log('31. registerPair(eth.address, peth.address, ethAnchor.address)');
    // await cofixRouter.registerPair(eth.address, peth.address, ethAnchor.address);
    // // Register usd anchor pool
    // console.log('32. registerPair(usdt.address, pusd.address, usdAnchor.address)');
    // await cofixRouter.registerPair(usdt.address, pusd.address, usdAnchor.address);
    // console.log('33. registerPair(usdt.address, usdc.address, usdAnchor.address)');
    // await cofixRouter.registerPair(usdt.address, usdc.address, usdAnchor.address);
    // console.log('34. registerPair(pusd.address, usdc.address, usdAnchor.address)');
    // await cofixRouter.registerPair(pusd.address, usdc.address, usdAnchor.address);

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
