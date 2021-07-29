// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { ethers, upgrades } = require('hardhat');

exports.deploy = async function () {
    
    const eth = { address: '0x0000000000000000000000000000000000000000' };
    const TestERC20 = await ethers.getContractFactory('TestERC20');
    const CoFiToken = await ethers.getContractFactory('CoFiToken');
    const CoFiXGovernance = await ethers.getContractFactory('CoFiXGovernance');
    const CoFiXDAO = await ethers.getContractFactory('CoFiXDAO');
    const CoFiXRouter = await ethers.getContractFactory('CoFiXRouter');
    const CoFiXController = await ethers.getContractFactory('CoFiXController');
    const CoFiXVaultForStaking = await ethers.getContractFactory('CoFiXVaultForStaking');
    const CoFiXPair = await ethers.getContractFactory('CoFiXPair');
    const CoFiXAnchorPool = await ethers.getContractFactory('CoFiXAnchorPool');
    const CoFiXAnchorToken = await ethers.getContractFactory('CoFiXAnchorToken');
    const NestPriceFacade = await ethers.getContractFactory('NestPriceFacade');

    //nestPriceFacade: 0xDda3801487a8Bb5ec19dD1E3510b6340BA435863
    //cnode: 0x6E9c1edACe6Fc03f9666769f09D557b1383f7F57
    //usdt: 0x0f4014fbA3D4fcb56d2653Bf3d51664dCcCF42f6
    //nest: 0x4c6DC3Fa867c3c96B1C8F51CE7Fa975b886d882f
    //cofi: 0x4c4F8Bfa7835089D176C1ec24e845f784F3045c1
    //cofixGovernance: 0x9964C60E19FA2F5426821643a5195920cE83f454
    //usdtPair: 0xb7719040D4357A2a58D1293a52511b57bCbd533D
    //nestPair: 0x91025AF7C4699473C9f9Cae7876c86e4ef715107
    //cofixDAO: 0xba7ba7e89ad593727e3eF694e5c9Db1C9f95B58d
    //cofixRouter: 0x2651171EeB0Ec9357c27A8CdB8B7dF4500534F34
    //cofixController: 0x45456aE6aCD697F9661a962716e105393d4CF8c4
    //cofixVaultForStaking: 0x6075560428330b0DeE19F6D5606d564E0B768cd6
    // peth: 0x885629c3784C4e7cEaa82b83F3aeD2F991d197C6
    // weth: 0x628b25c7658287c2829EE7a3E5D34b0158d2fdB5
    // pusd: 0x0f03cd5CeBe21D1E7307588b9844D10ad0F4A394
    // usdc: 0xe86dD41fEb8594D083f9dC364e530c0B8D208feA
    // ethAnchor: 0xbbd6b432B280dea51f137F8234a5D0Ac36D17fdf
    // usdAnchor: 0x08B79267ff01393925081396b328B6d6f82a4250
    // xeth: 0x1Be9CdBbf78389D2075F528730B87b82551A59D7
    // xpeth: 0x0FC0551C43915b652b646b277d883B8aC2Cd3C58
    // xweth: 0x0Ea19Bf07e6F09124CeefbDBa41C9c0e58430316
    // xusdt: 0xbff7C46F7825207A3e9cF8C459f2410C7e38aF43
    // xpusd: 0x08cD68990E084eD3FC4f7bF18b119F5581D2bAf6
    // xusdc: 0xC9F6c5a57451d39AC4F19F81B35A569714C87a93

    console.log('** 开始部署合约 rinkeby@20210702.js **');
    
    //const nestPriceFacade = await NestPriceFacade.deploy();
    const nestPriceFacade = await NestPriceFacade.attach('0xDda3801487a8Bb5ec19dD1E3510b6340BA435863');
    console.log('nestPriceFacade: ' + nestPriceFacade.address);
    
    //let cnode = await TestERC20.deploy('CNode', 'CNode', 0);
    const cnode = await TestERC20.attach('0x6E9c1edACe6Fc03f9666769f09D557b1383f7F57');
    console.log('cnode: ' + cnode.address);
    
    //const usdt = await TestERC20.deploy('USDT', 'USDT', 6);
    const usdt = await TestERC20.attach('0x0f4014fbA3D4fcb56d2653Bf3d51664dCcCF42f6');
    console.log('usdt: ' + usdt.address);

    //const nest = await TestERC20.deploy('NEST', 'NEST', 18);
    const nest = await TestERC20.attach('0x4c6DC3Fa867c3c96B1C8F51CE7Fa975b886d882f');
    console.log('nest: ' + nest.address);
    
    //const cofi = await CoFiToken.deploy();
    const cofi = await CoFiToken.attach('0x4c4F8Bfa7835089D176C1ec24e845f784F3045c1');
    console.log('cofi: ' + cofi.address);

    //const cofixGovernance = await upgrades.deployProxy(CoFiXGovernance, ['0x0000000000000000000000000000000000000000'], { initializer: 'initialize' });
    const cofixGovernance = await CoFiXGovernance.attach('0x9964C60E19FA2F5426821643a5195920cE83f454');
    console.log('cofixGovernance: ' + cofixGovernance.address);
    
    //const usdtPair = await upgrades.deployProxy(CoFiXPair, [cofixGovernance.address, 'XT-1', 'XToken-1', usdt.address, BigInt('1000000000'), BigInt('3')], { initializer: 'init' });
    const usdtPair = await CoFiXPair.attach('0xb7719040D4357A2a58D1293a52511b57bCbd533D');
    console.log('usdtPair: ' + usdtPair.address);
    //cnode = usdtPair;

    //const nestPair = await upgrades.deployProxy(CoFiXPair, [cofixGovernance.address, 'XT-2', 'XToken-2', nest.address, BigInt('1'), BigInt('20000')], { initializer: 'init' });
    const nestPair = await CoFiXPair.attach('0x91025AF7C4699473C9f9Cae7876c86e4ef715107');
    console.log('nestPair: ' + nestPair.address);

    //const cofixDAO = await upgrades.deployProxy(CoFiXDAO, [cofixGovernance.address], { initializer: 'initialize' });
    const cofixDAO = await CoFiXDAO.attach('0xba7ba7e89ad593727e3eF694e5c9Db1C9f95B58d');
    console.log('cofixDAO: ' + cofixDAO.address);
    
    //const cofixRouter = await upgrades.deployProxy(CoFiXRouter, [cofixGovernance.address], { initializer: 'initialize' });
    const cofixRouter = await CoFiXRouter.attach('0x2651171EeB0Ec9357c27A8CdB8B7dF4500534F34');
    console.log('cofixRouter: ' + cofixRouter.address);
    
    //const cofixController = await CoFiXController.deploy(nestPriceFacade.address);
    const cofixController = await CoFiXController.attach('0x45456aE6aCD697F9661a962716e105393d4CF8c4');
    console.log('cofixController: ' + cofixController.address);
    
    //const cofixVaultForStaking = await upgrades.deployProxy(CoFiXVaultForStaking, [cofixGovernance.address], { initializer: 'initialize' });
    const cofixVaultForStaking = await CoFiXVaultForStaking.attach('0x6075560428330b0DeE19F6D5606d564E0B768cd6');
    console.log('cofixVaultForStaking: ' + cofixVaultForStaking.address);
    
    // console.log('1. cofixGovernance.initialize');
    // await cofixGovernance.initialize(cofixGovernance.address);
    //console.log('2. cofixRouter.initialize');
    //await cofixRouter.initialize(cofixGovernance.address);
    //console.log('3. cofixDAO.initialize');
    //await cofixDAO.initialize(cofixGovernance.address);
    // console.log('4. cofixVaultForStaking.initialize');
    // await cofixVaultForStaking.initialize(cofixGovernance.address);
    //console.log('5. usdtPair.initialize');
    //await usdtPair.init(cofixGovernance.address, 'XT-1', 'XToken-1', usdt.address, BigInt('1000000000'), BigInt('3'));
    //console.log('6. nestPair.initialize');
    //await nestPair.init(cofixGovernance.address, 'XT-2', 'XToken-2', nest.address, BigInt('1'), BigInt('20000'));

    // console.log('7. cofixGovernance.setBuiltinAddress');
    // await cofixGovernance.setBuiltinAddress(
    //     cofi.address,
    //     cnode.address,
    //     cofixDAO.address,
    //     cofixRouter.address,
    //     cofixController.address,
    //     cofixVaultForStaking.address
    // );
    
    // console.log('8. cofixRouter.update');
    // await cofixRouter.update(cofixGovernance.address);
    // console.log('9. cofixDAO.update');
    // await cofixDAO.update(cofixGovernance.address);
    // console.log('10. cofixVaultForStaking.update');
    // await cofixVaultForStaking.update(cofixGovernance.address);
    // console.log('11. usdtPair.update');
    // await usdtPair.update(cofixGovernance.address);
    // console.log('12. usdtPair.update');
    // await nestPair.update(cofixGovernance.address);

    // console.log('13. cofixVaultForStaking.setConfig');
    // await cofixVaultForStaking.setConfig({
    //     cofiUnit: '10000000000000000'
    // });
    // console.log('14. cofixVaultForStaking.batchSetPoolWeight(cnode.address)');
    // await cofixVaultForStaking.batchSetPoolWeight([cnode.address], [100000]);
    // console.log('15. cofixVaultForStaking.batchSetPoolWeight(usdtPair.address)');
    // await cofixVaultForStaking.batchSetPoolWeight([usdtPair.address], [100000]);
    // console.log('16. cofixVaultForStaking.batchSetPoolWeight(nestPair.address)');
    // await cofixVaultForStaking.batchSetPoolWeight([nestPair.address], [20000]);

    // // console.log('17. cofixRouter.setConfig');
    // // await cofixRouter.setConfig({
    // //     cnodeRewardRate: 1000
    // // });
    // console.log('18. cofixRouter.addPair(usdt.address, usdtPair.address)');
    // await cofixRouter.registerPair(eth.address, usdt.address, usdtPair.address);
    // console.log('19. cofixRouter.addPair(nest.address, nestPair.address)');
    // await cofixRouter.registerPair(eth.address, nest.address, nestPair.address);
    // console.log('20. cofi.addMinter(cofixRouter.address)');
    // await cofi.addMinter(cofixRouter.address);
    // console.log('21. cofi.addMinter(cofixVaultForStaking.address)');
    // await cofi.addMinter(cofixVaultForStaking.address);

    // await cofixRouter.registerRouterPath(nest.address, usdt.address, [
    //     nest.address, 
    //     eth.address, 
    //     usdt.address
    // ]);

    // peth: 0x885629c3784C4e7cEaa82b83F3aeD2F991d197C6
    // weth: 0x628b25c7658287c2829EE7a3E5D34b0158d2fdB5
    // pusd: 0x0f03cd5CeBe21D1E7307588b9844D10ad0F4A394
    // usdc: 0xe86dD41fEb8594D083f9dC364e530c0B8D208feA
    // ethAnchor: 0xbbd6b432B280dea51f137F8234a5D0Ac36D17fdf
    // usdAnchor: 0x08B79267ff01393925081396b328B6d6f82a4250
    // 部署PETH, WETH
    //let peth = await TestERC20.deploy('PETH', 'PETH', 18);
    let peth = await TestERC20.attach('0x885629c3784C4e7cEaa82b83F3aeD2F991d197C6');
    console.log('peth: ' + peth.address);
    //let weth = await TestERC20.deploy('WETH', 'WETH', 18);
    let weth = await TestERC20.attach('0x628b25c7658287c2829EE7a3E5D34b0158d2fdB5');
    console.log('weth: ' + weth.address);
    // 部署PUSD, USDC
    //let pusd = await TestERC20.deploy('PUSD', 'PUSD', 18);
    let pusd = await TestERC20.attach('0x0f03cd5CeBe21D1E7307588b9844D10ad0F4A394');
    console.log('pusd: ' + pusd.address);
    //let usdc = await TestERC20.deploy('USDC', 'USDC', 6);
    let usdc = await TestERC20.attach('0xe86dD41fEb8594D083f9dC364e530c0B8D208feA');
    console.log('usdc: ' + usdc.address);
    // 部署ETH锚定池
    // let ethAnchor = await upgrades.deployProxy(CoFiXAnchorPool, [
    //     cofixGovernance.address, 
    //     0, 
    //     [eth.address, peth.address, weth.address],
    //     ['1000000000000000000', '1000000000000000000', '1000000000000000000']
    // ], { initializer: 'init' });
    let ethAnchor = await CoFiXAnchorPool.attach('0xbbd6b432B280dea51f137F8234a5D0Ac36D17fdf');
    console.log('ethAnchor: ' + ethAnchor.address);
    // 部署USD锚定池
    // let usdAnchor = await upgrades.deployProxy(CoFiXAnchorPool, [
    //     cofixGovernance.address, 
    //     1,
    //     [usdt.address, pusd.address, usdc.address],
    //     ['1000000', '1000000000000000000', '1000000000000000000']
    // ], { initializer: 'init' });
    let usdAnchor = await CoFiXAnchorPool.attach('0x08B79267ff01393925081396b328B6d6f82a4250');
    console.log('usdAnchor: ' + usdAnchor.address);

    // // 注册usdt和nest交易对
    // console.log('22. registerPair(eth.address, usdt.address, usdtPair.address)');
    // await cofixRouter.registerPair(eth.address, usdt.address, usdtPair.address);
    // console.log('23. registerPair(eth.address, nest.address, nestPair.address)');
    // await cofixRouter.registerPair(eth.address, nest.address, nestPair.address);
    // // 注册ETH锚定池
    // console.log('24. registerPair(eth.address, peth.address, ethAnchor.address)');
    // await cofixRouter.registerPair(eth.address, peth.address, ethAnchor.address);
    // console.log('25. registerPair(eth.address, weth.address, ethAnchor.address)');
    // await cofixRouter.registerPair(eth.address, weth.address, ethAnchor.address);
    // console.log('26. registerPair(peth.address, weth.address, ethAnchor.address)');
    // await cofixRouter.registerPair(peth.address, weth.address, ethAnchor.address);
    // // 注册USD锚定池
    // console.log('27. registerPair(usdt.address, pusd.address, usdAnchor.address)');
    // await cofixRouter.registerPair(usdt.address, pusd.address, usdAnchor.address);
    // console.log('28. registerPair(usdt.address, usdc.address, usdAnchor.address)');
    // await cofixRouter.registerPair(usdt.address, usdc.address, usdAnchor.address);
    // console.log('29. registerPair(pusd.address, usdc.address, usdAnchor.address)');
    // await cofixRouter.registerPair(pusd.address, usdc.address, usdAnchor.address);
    // // 注册路由路径
    // console.log('30. registerRouterPath(usdt.address, nest.address, [usdt.address, eth.address, nest.address])');
    // await cofixRouter.registerRouterPath(usdt.address, nest.address, [usdt.address, eth.address, nest.address]);
    // console.log('31. registerRouterPath(usdt.address, peth.address, [usdt.address, eth.address, peth.address])');
    // await cofixRouter.registerRouterPath(usdt.address, peth.address, [usdt.address, eth.address, peth.address]);
    // console.log('32. registerRouterPath(usdt.address, weth.address, [usdt.address, eth.address, weth.address])');
    // await cofixRouter.registerRouterPath(usdt.address, weth.address, [usdt.address, eth.address, weth.address]);
    
    // // eth, nest, usdt, pusd, usdc, peth, weth
    // console.log('33. registerRouterPath(pusd.address, eth.address, [pusd.address, usdt.address, eth.address])');
    // await cofixRouter.registerRouterPath(pusd.address, eth.address, [pusd.address, usdt.address, eth.address]);
    // console.log('34. registerRouterPath(pusd.address, peth.address, [pusd.address, usdt.address, eth.address, peth.address])');
    // await cofixRouter.registerRouterPath(pusd.address, peth.address, [pusd.address, usdt.address, eth.address, peth.address]);
    // console.log('35. registerRouterPath(pusd.address, weth.address, [pusd.address, usdt.address, eth.address, weth.address])');
    // await cofixRouter.registerRouterPath(pusd.address, weth.address, [pusd.address, usdt.address, eth.address, weth.address]);
    // console.log('36. registerRouterPath(pusd.address, nest.address, [pusd.address, usdt.address, eth.address, nest.address])');
    // await cofixRouter.registerRouterPath(pusd.address, nest.address, [pusd.address, usdt.address, eth.address, nest.address]);

    // console.log('37. registerRouterPath(usdc.address, eth.address, [usdc.address, usdt.address, eth.address])');
    // await cofixRouter.registerRouterPath(usdc.address, eth.address, [usdc.address, usdt.address, eth.address]);
    // console.log('38. registerRouterPath(usdc.address, peth.address, [usdc.address, usdt.address, eth.address, peth.address])');
    // await cofixRouter.registerRouterPath(usdc.address, peth.address, [usdc.address, usdt.address, eth.address, peth.address]);
    // console.log('39. registerRouterPath(usdc.address, weth.address, [usdc.address, usdt.address, eth.address, weth.address])');
    // await cofixRouter.registerRouterPath(usdc.address, weth.address, [usdc.address, usdt.address, eth.address, weth.address]);
    // console.log('40. registerRouterPath(usdc.address, nest.address, [usdc.address, usdt.address, eth.address, nest.address])');
    // await cofixRouter.registerRouterPath(usdc.address, nest.address, [usdc.address, usdt.address, eth.address, nest.address]);

    // console.log('41. registerRouterPath(peth.address, nest.address, [peth.address, eth.address, nest.address])');
    // await cofixRouter.registerRouterPath(peth.address, nest.address, [peth.address, eth.address, nest.address]);
    // console.log('42. registerRouterPath(weth.address, nest.address, [weth.address, eth.address, nest.address])');
    // await cofixRouter.registerRouterPath(weth.address, nest.address, [weth.address, eth.address, nest.address]);

    // console.log('43. ethAnchor.init(cofixGovernance.address)');
    // await ethAnchor.init(cofixGovernance.address, 0, 
    //     [eth.address, peth.address, weth.address],
    //     ['1000000000000000000', '1000000000000000000', '1000000000000000000']
    // );
    // console.log('44. usdAnchor.init(cofixGovernance.address)');
    // await usdAnchor.init(cofixGovernance.address, 1,
    //     [usdt.address, pusd.address, usdc.address],
    //     ['1000000', '1000000000000000000', '1000000000000000000']
    // );
    // console.log('45. ethAnchor.update(cofixGovernance.address)');
    // await ethAnchor.update(cofixGovernance.address);
    // console.log('46. usdAnchor.update(cofixGovernance.address)');
    // await usdAnchor.update(cofixGovernance.address);

    let xeth = await CoFiXAnchorToken.attach(await ethAnchor.getXToken(eth.address));
    console.log('xeth: ' + xeth.address);
    let xpeth = await CoFiXAnchorToken.attach(await ethAnchor.getXToken(peth.address));
    console.log('xpeth: ' + xpeth.address);
    let xweth = await CoFiXAnchorToken.attach(await ethAnchor.getXToken(weth.address));
    console.log('xweth: ' + xweth.address);

    let xusdt = await CoFiXAnchorToken.attach(await usdAnchor.getXToken(usdt.address));
    console.log('xusdt: ' + xusdt.address);
    let xpusd = await CoFiXAnchorToken.attach(await usdAnchor.getXToken(pusd.address));
    console.log('xpusd: ' + xpusd.address);
    let xusdc = await CoFiXAnchorToken.attach(await usdAnchor.getXToken(usdc.address));
    console.log('xusdc: ' + xusdc.address);

    // console.log('47. cofixVaultForStaking.batchSetPoolWeight(xeth.address, 20000)');
    // await cofixVaultForStaking.batchSetPoolWeight([xeth.address], [20000]);
    // console.log('48. cofixVaultForStaking.batchSetPoolWeight(xpeth.address, 20000)');
    // await cofixVaultForStaking.batchSetPoolWeight([xpeth.address], [20000]);
    // console.log('49. cofixVaultForStaking.batchSetPoolWeight(xweth.address, 20000)');
    // await cofixVaultForStaking.batchSetPoolWeight([xweth.address], [20000]);

    // console.log('50. cofixVaultForStaking.batchSetPoolWeight(xusdt.address, 20000)');
    // await cofixVaultForStaking.batchSetPoolWeight([xusdt.address], [20000]);
    // console.log('51. cofixVaultForStaking.batchSetPoolWeight(xpusd.address, 20000)');
    // await cofixVaultForStaking.batchSetPoolWeight([xpusd.address], [20000]);
    // console.log('52. cofixVaultForStaking.batchSetPoolWeight(xusdc.address, 20000)');
    // await cofixVaultForStaking.batchSetPoolWeight([xusdc.address], [20000]);

    // console.log('53. setConfig');
    // await usdtPair.setConfig(20, 1, 1000);
    // await nestPair.setConfig(20, 100, 1000);
    // await ethAnchor.setConfig(20, 0, 1000);
    // await usdAnchor.setConfig(20, 0, 1000);

    // console.log('56. setConfig');
    // await cofixDAO.setConfig({
    //     // Redeem activate threshold, when the circulation of token exceeds this threshold, 
    //     // 回购状态, 1表示启动
    //     status: 1,

    //     // The number of CoFi redeem per block. 100
    //     cofiPerBlock: 100,

    //     // The maximum number of CoFi in a single redeem. 30000
    //     cofiLimit: 30000,

    //     // Price deviation limit, beyond this upper limit stop redeem (10000 based). 1000
    //     priceDeviationLimit: 1000
    // });

    // await cofixDAO.setTokenExchange(usdt.address, usdt.address, BigInt('1000000000000000000'));
    // await cofixDAO.setTokenExchange(pusd.address, usdt.address, BigInt('1000000'));
    // await cofixDAO.setTokenExchange(usdc.address, usdt.address, BigInt('1000000'));

    // await cofixDAO.setTokenExchange(eth.address, eth.address, BigInt('1000000000000000000'));
    // await cofixDAO.setTokenExchange(peth.address, eth.address, BigInt('1000000000000000000'));
    // await cofixDAO.setTokenExchange(weth.address, eth.address, BigInt('1000000000000000000'));

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
        nest: nest,
        peth: peth,
        weth: weth,
        pusd: pusd,
        usdc: usdc,

        xeth: xeth,
        xpeth: xpeth,
        xweth: xweth,
        xusdt: xusdt,
        xpusd: xpusd,
        xusdc: xusdc,

        usdtPair: usdtPair,
        nestPair: nestPair,
        ethAnchor: ethAnchor,
        usdAnchor: usdAnchor
    };
    
    //console.log(contracts);
    console.log('** 合约部署完成 **');
    return contracts;
}
