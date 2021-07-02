// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { ethers, upgrades } = require("hardhat");

exports.deploy = async function () {
    
    const eth = { address: '0x0000000000000000000000000000000000000000' };
    const TestERC20 = await ethers.getContractFactory("TestERC20");
    const CoFiToken = await ethers.getContractFactory("CoFiToken");
    const CoFiXGovernance = await ethers.getContractFactory("CoFiXGovernance");
    const CoFiXDAO = await ethers.getContractFactory("CoFiXDAO");
    const CoFiXRouter = await ethers.getContractFactory("CoFiXRouter");
    const CoFiXController = await ethers.getContractFactory("CoFiXController");
    const CoFiXVaultForStaking = await ethers.getContractFactory("CoFiXVaultForStaking");
    const CoFiXPair = await ethers.getContractFactory("CoFiXPair");
    const CoFiXAnchorPool = await ethers.getContractFactory("CoFiXAnchorPool");
    const CoFiXAnchorToken = await ethers.getContractFactory("CoFiXAnchorToken");
    const NestPriceFacade = await ethers.getContractFactory("NestPriceFacade");

    // cnode: 0x2dC52e1FcD06a43285c5D7f5E833131b1c411852
    // usdt: 0xd5798C4DbC5AC13DbE4809d2914b5fd5e5030948
    // cofi: 0x30C69c1511608aBCf5f7052CE330A47673BEF80a
    // cofixGovernance: 0x615c7448ED870aD41a24FE7e96016b2d9406C169
    // cofixDAO: 0x7D3d375759Dce4D8609EcA61fCe5898e5Dd52E09
    // cofixRouter: 0x537A8955B0E0466A487F8a417717551ac05bB580
    // cofixController: 0xA1e38e9DECB554b6AaC4b9B58f74Af1eb33CE291
    // cofixVaultForStaking: 0x69E6CAae16Acf21134D839835C5f8bC9F2522680
    // usdtPair: 0x9228A336bb91bFf6A1Ff54Ded0DE514D22dAED52

    console.log('** 开始部署合约 deploy.proxy.js **');
    
    const nestPriceFacade = await NestPriceFacade.deploy();
    //const nestPriceFacade = await NestPriceFacade.attach('0x0000000000000000000000000000000000000000');
    console.log('nestPriceFacade: ' + nestPriceFacade.address);
    
    let cnode = await TestERC20.deploy('CNode', 'CNode', 0);
    //const cnode = await TestERC20.attach('0x2dC52e1FcD06a43285c5D7f5E833131b1c411852');
    console.log('cnode: ' + cnode.address);
    
    const usdt = await TestERC20.deploy('USDT', 'USDT', 6);
    //const usdt = await TestERC20.attach('0xd5798C4DbC5AC13DbE4809d2914b5fd5e5030948');
    console.log('usdt: ' + usdt.address);

    const nest = await TestERC20.deploy('NEST', 'NEST', 18);
    //const nest = await TestERC20.attach('0x0000000000000000000000000000000000000000');
    console.log('nest: ' + nest.address);
    
    const cofi = await CoFiToken.deploy();
    //const cofi = await CoFiToken.attach('0x30C69c1511608aBCf5f7052CE330A47673BEF80a');
    console.log('cofi: ' + cofi.address);

    const cofixGovernance = await upgrades.deployProxy(CoFiXGovernance, ['0x0000000000000000000000000000000000000000'], { initializer: 'initialize' });
    //const cofixGovernance = await CoFiXGovernance.attach('0x615c7448ED870aD41a24FE7e96016b2d9406C169');
    console.log('cofixGovernance: ' + cofixGovernance.address);
    
    const usdtPair = await upgrades.deployProxy(CoFiXPair, [cofixGovernance.address, 'XT-1', 'XToken-1', usdt.address, BigInt('1000000000'), BigInt('3')], { initializer: 'init' });
    //const usdtPair = await CoFiXPair.attach('0x9228A336bb91bFf6A1Ff54Ded0DE514D22dAED52');
    console.log('usdtPair: ' + usdtPair.address);
    //cnode = usdtPair;

    const nestPair = await upgrades.deployProxy(CoFiXPair, [cofixGovernance.address, 'XT-2', 'XToken-2', nest.address, BigInt('1'), BigInt('20000')], { initializer: 'init' });
    //const nestPair = await CoFiXPair.attach('0x0000000000000000000000000000000000000000');
    console.log('nestPair: ' + nestPair.address);

    const cofixDAO = await upgrades.deployProxy(CoFiXDAO, [cofixGovernance.address], { initializer: 'initialize' });
    //const cofixDAO = await CoFiXDAO.attach('0x7D3d375759Dce4D8609EcA61fCe5898e5Dd52E09');
    console.log('cofixDAO: ' + cofixDAO.address);
    
    const cofixRouter = await upgrades.deployProxy(CoFiXRouter, [cofixGovernance.address], { initializer: 'initialize' });
    //const cofixRouter = await CoFiXRouter.attach('0x537A8955B0E0466A487F8a417717551ac05bB580');
    console.log('cofixRouter: ' + cofixRouter.address);
    
    const cofixController = await CoFiXController.deploy(nestPriceFacade.address);
    //const cofixController = await CoFiXController.attach('0xA1e38e9DECB554b6AaC4b9B58f74Af1eb33CE291');
    console.log('cofixController: ' + cofixController.address);
    
    const cofixVaultForStaking = await upgrades.deployProxy(CoFiXVaultForStaking, [cofixGovernance.address], { initializer: 'initialize' });
    //const cofixVaultForStaking = await CoFiXVaultForStaking.attach('0x69E6CAae16Acf21134D839835C5f8bC9F2522680');
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

    console.log('7. cofixGovernance.setBuiltinAddress');
    await cofixGovernance.setBuiltinAddress(
        cofi.address,
        cnode.address,
        cofixDAO.address,
        cofixRouter.address,
        cofixController.address,
        cofixVaultForStaking.address
    );
    
    console.log('8. cofixRouter.update');
    await cofixRouter.update(cofixGovernance.address);
    console.log('9. cofixDAO.update');
    await cofixDAO.update(cofixGovernance.address);
    console.log('10. cofixVaultForStaking.update');
    await cofixVaultForStaking.update(cofixGovernance.address);
    console.log('11. usdtPair.update');
    await usdtPair.update(cofixGovernance.address);
    console.log('12. usdtPair.update');
    await nestPair.update(cofixGovernance.address);

    console.log('13. cofixVaultForStaking.setConfig');
    await cofixVaultForStaking.setConfig({
        cofiRate: '200000000000000000'
    });
    console.log('14. cofixVaultForStaking.initStakingChannel(cnode.address)');
    await cofixVaultForStaking.initStakingChannel(cnode.address, 100000);
    console.log('15. cofixVaultForStaking.initStakingChannel(usdtPair.address)');
    await cofixVaultForStaking.initStakingChannel(usdtPair.address, 100000);
    console.log('16. cofixVaultForStaking.initStakingChannel(nestPair.address)');
    await cofixVaultForStaking.initStakingChannel(nestPair.address, 20000);

    // console.log('17. cofixRouter.setConfig');
    // await cofixRouter.setConfig({
    //     cnodeRewardRate: 1000
    // });
    console.log('18. cofixRouter.addPair(usdt.address, usdtPair.address)');
    await cofixRouter.registerPair(eth.address, usdt.address, usdtPair.address);
    console.log('19. cofixRouter.addPair(nest.address, nestPair.address)');
    await cofixRouter.registerPair(eth.address, nest.address, nestPair.address);
    console.log('20. cofi.addMinter(cofixRouter.address)');
    await cofi.addMinter(cofixRouter.address);
    console.log('21. cofi.addMinter(cofixVaultForStaking.addres)');
    await cofi.addMinter(cofixVaultForStaking.address);

    // await cofixRouter.registerRouterPath(nest.address, usdt.address, [
    //     nest.address, 
    //     eth.address, 
    //     usdt.address
    // ]);

    // 部署PETH, WETH
    let peth = await TestERC20.deploy('PETH', 'PETH', 18);
    console.log('peth: ' + peth.address);
    let weth = await TestERC20.deploy('WETH', 'WETH', 18);
    console.log('weth: ' + weth.address);
    // 部署PUSD, DAI
    let pusd = await TestERC20.deploy('PUSD', 'PUSD', 18);
    console.log('pusd: ' + pusd.address);
    let dai = await TestERC20.deploy('DAI', 'DAI', 18);
    console.log('dai: ' + dai.address);
    // 部署ETH锚定池
    let ethAnchor = await upgrades.deployProxy(CoFiXAnchorPool, [
        cofixGovernance.address, 
        0, 
        [eth.address, peth.address, weth.address],
        ['1000000000000000000', '1000000000000000000', '1000000000000000000']
    ], { initializer: 'init' });
    console.log('ethAnchor: ' + ethAnchor.address);
    // 部署USD锚定池
    let usdAnchor = await upgrades.deployProxy(CoFiXAnchorPool, [
        cofixGovernance.address, 
        1,
        [usdt.address, pusd.address, dai.address],
        ['1000000', '1000000000000000000', '1000000000000000000']
    ], { initializer: 'init' });
    console.log('usdAnchor: ' + usdAnchor.address);

    // 注册usdt和nest交易对
    console.log('22. registerPair(eth.address, usdt.address, usdtPair.address)');
    await cofixRouter.registerPair(eth.address, usdt.address, usdtPair.address);
    console.log('23. registerPair(eth.address, nest.address, nestPair.address)');
    await cofixRouter.registerPair(eth.address, nest.address, nestPair.address);
    // 注册ETH锚定池
    console.log('24. registerPair(eth.address, peth.address, ethAnchor.address)');
    await cofixRouter.registerPair(eth.address, peth.address, ethAnchor.address);
    console.log('25. registerPair(eth.address, weth.address, ethAnchor.address)');
    await cofixRouter.registerPair(eth.address, weth.address, ethAnchor.address);
    console.log('26. registerPair(peth.address, weth.address, ethAnchor.address)');
    await cofixRouter.registerPair(peth.address, weth.address, ethAnchor.address);
    // 注册USD锚定池
    console.log('27. registerPair(usdt.address, pusd.address, usdAnchor.address)');
    await cofixRouter.registerPair(usdt.address, pusd.address, usdAnchor.address);
    console.log('28. registerPair(usdt.address, dai.address, usdAnchor.address)');
    await cofixRouter.registerPair(usdt.address, dai.address, usdAnchor.address);
    console.log('29. registerPair(pusd.address, dai.address, usdAnchor.address)');
    await cofixRouter.registerPair(pusd.address, dai.address, usdAnchor.address);
    // 注册路由路径
    console.log('30. registerRouterPath(usdt.address, nest.address, [usdt.address, eth.address, nest.address])');
    await cofixRouter.registerRouterPath(usdt.address, nest.address, [usdt.address, eth.address, nest.address]);
    console.log('31. registerRouterPath(usdt.address, peth.address, [usdt.address, eth.address, peth.address])');
    await cofixRouter.registerRouterPath(usdt.address, peth.address, [usdt.address, eth.address, peth.address]);
    console.log('32. registerRouterPath(usdt.address, weth.address, [usdt.address, eth.address, weth.address])');
    await cofixRouter.registerRouterPath(usdt.address, weth.address, [usdt.address, eth.address, weth.address]);
    
    // eth, nest, usdt, pusd, dai, peth, weth
    console.log('33. registerRouterPath(pusd.address, eth.address, [pusd.address, usdt.address, eth.address])');
    await cofixRouter.registerRouterPath(pusd.address, eth.address, [pusd.address, usdt.address, eth.address]);
    console.log('34. registerRouterPath(pusd.address, peth.address, [pusd.address, usdt.address, eth.address, peth.address])');
    await cofixRouter.registerRouterPath(pusd.address, peth.address, [pusd.address, usdt.address, eth.address, peth.address]);
    console.log('35. registerRouterPath(pusd.address, weth.address, [pusd.address, usdt.address, eth.address, weth.address])');
    await cofixRouter.registerRouterPath(pusd.address, weth.address, [pusd.address, usdt.address, eth.address, weth.address]);
    console.log('36. registerRouterPath(pusd.address, nest.address, [pusd.address, usdt.address, eth.address, nest.address])');
    await cofixRouter.registerRouterPath(pusd.address, nest.address, [pusd.address, usdt.address, eth.address, nest.address]);

    console.log('37. registerRouterPath(dai.address, eth.address, [dai.address, usdt.address, eth.address])');
    await cofixRouter.registerRouterPath(dai.address, eth.address, [dai.address, usdt.address, eth.address]);
    console.log('38. registerRouterPath(dai.address, peth.address, [dai.address, usdt.address, eth.address, peth.address])');
    await cofixRouter.registerRouterPath(dai.address, peth.address, [dai.address, usdt.address, eth.address, peth.address]);
    console.log('39. registerRouterPath(dai.address, weth.address, [dai.address, usdt.address, eth.address, weth.address])');
    await cofixRouter.registerRouterPath(dai.address, weth.address, [dai.address, usdt.address, eth.address, weth.address]);
    console.log('40. registerRouterPath(dai.address, nest.address, [dai.address, usdt.address, eth.address, nest.address])');
    await cofixRouter.registerRouterPath(dai.address, nest.address, [dai.address, usdt.address, eth.address, nest.address]);

    console.log('41. registerRouterPath(peth.address, nest.address, [peth.address, eth.address, nest.address])');
    await cofixRouter.registerRouterPath(peth.address, nest.address, [peth.address, eth.address, nest.address]);
    console.log('42. registerRouterPath(weth.address, nest.address, [weth.address, eth.address, nest.address])');
    await cofixRouter.registerRouterPath(weth.address, nest.address, [weth.address, eth.address, nest.address]);

    // console.log('43. ethAnchor.init(cofixGovernance.address)');
    // await ethAnchor.init(cofixGovernance.address, 0, 
    //     [eth.address, peth.address, weth.address],
    //     ['1000000000000000000', '1000000000000000000', '1000000000000000000']
    // );
    // console.log('44. usdAnchor.init(cofixGovernance.address)');
    // await usdAnchor.init(cofixGovernance.address, 1,
    //     [usdt.address, pusd.address, dai.address],
    //     ['1000000', '1000000000000000000', '1000000000000000000']
    // );
    console.log('45. ethAnchor.update(cofixGovernance.address)');
    await ethAnchor.update(cofixGovernance.address);
    console.log('46. usdAnchor.update(cofixGovernance.address)');
    await usdAnchor.update(cofixGovernance.address);

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
    let xdai = await CoFiXAnchorToken.attach(await usdAnchor.getXToken(dai.address));
    console.log('xdai: ' + xdai.address);

    console.log('47. cofixVaultForStaking.initStakingChannel(xeth.address, 20000)');
    await cofixVaultForStaking.initStakingChannel(xeth.address, 20000);
    console.log('48. cofixVaultForStaking.initStakingChannel(xpeth.address, 20000)');
    await cofixVaultForStaking.initStakingChannel(xpeth.address, 20000);
    console.log('49. cofixVaultForStaking.initStakingChannel(xweth.address, 20000)');
    await cofixVaultForStaking.initStakingChannel(xweth.address, 20000);

    console.log('50. cofixVaultForStaking.initStakingChannel(xusdt.address, 20000)');
    await cofixVaultForStaking.initStakingChannel(xusdt.address, 20000);
    console.log('51. cofixVaultForStaking.initStakingChannel(xpusd.address, 20000)');
    await cofixVaultForStaking.initStakingChannel(xpusd.address, 20000);
    console.log('52. cofixVaultForStaking.initStakingChannel(xdai.address, 20000)');
    await cofixVaultForStaking.initStakingChannel(xdai.address, 20000);

    console.log('53. setConfig');
    await usdtPair.setConfig(20, 1, 1000);
    await nestPair.setConfig(20, 100, 1000);
    await ethAnchor.setConfig(20, 0, 1000);
    await usdAnchor.setConfig(20, 0, 1000);

    console.log('56. setConfig');
    await cofixDAO.setConfig({
        // Redeem activate threshold, when the circulation of token exceeds this threshold, 
        // 回购状态, 1表示启动
        status: 1,

        // The number of CoFi redeem per block. 100
        cofiPerBlock: 100,

        // The maximum number of CoFi in a single redeem. 30000
        cofiLimit: 30000,

        // Price deviation limit, beyond this upper limit stop redeem (10000 based). 1000
        priceDeviationLimit: 1000
    });
    await cofixDAO.setTokenExchange(usdt.address, usdt.address, BigInt('1000000000000000000'));
    await cofixDAO.setTokenExchange(dai.address, usdt.address, BigInt('1000000'));

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
        dai: dai,

        xeth: xeth,
        xpeth: xpeth,
        xweth: xweth,
        xusdt: xusdt,
        xpusd: xpusd,
        xdai: xdai,

        usdtPair: usdtPair,
        nestPair: nestPair,
        ethAnchor: ethAnchor,
        usdAnchor: usdAnchor
    };
    
    //console.log(contracts);
    console.log('** 合约部署完成 **');
    return contracts;
}
