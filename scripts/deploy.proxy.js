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
    const CoFiXDAO = await ethers.getContractFactory('CoFiXDAOSimple');
    const CoFiXRouter = await ethers.getContractFactory('CoFiXRouter');
    const CoFiXController = await ethers.getContractFactory('CoFiXController');
    const CoFiXPair = await ethers.getContractFactory('CoFiXPair');
    const CoFiXAnchorPool = await ethers.getContractFactory('CoFiXAnchorPool');
    const CoFiXAnchorToken = await ethers.getContractFactory('CoFiXAnchorToken');
    const CoFiXOpenPool = await ethers.getContractFactory('CoFiXOpenPool');

    console.log('** Deploy: deploy.proxy.js **');
    
    // 1. Deploy dependent contract
    const usdt = await TestERC20.deploy('USDT', 'USDT', 6);
    //const usdt = await TestERC20.attach('0x0000000000000000000000000000000000000000');
    console.log('usdt: ' + usdt.address);

    const hbtc = await TestERC20.deploy('HBTC', 'HBTC', 18);
    //const hbtc = await TestERC20.attach('0x0000000000000000000000000000000000000000');
    console.log('hbtc: ' + hbtc.address);

    let peth = await TestERC20.deploy('PETH', 'PETH', 18);
    //const peth = await TestERC20.attach('0x0000000000000000000000000000000000000000');
    console.log('peth: ' + peth.address);

    let pusd = await TestERC20.deploy('PUSD', 'PUSD', 18);
    //const pusd = await TestERC20.attach('0x0000000000000000000000000000000000000000');
    console.log('pusd: ' + pusd.address);

    let usdc = await TestERC20.deploy('USDC', 'USDC', 6);
    //const usdc = await TestERC20.attach('0x0000000000000000000000000000000000000000');
    console.log('usdc: ' + usdc.address);

    const nest = await TestERC20.deploy('NEST', 'NEST', 18);
    //const nest = await TestERC20.attach('0x0000000000000000000000000000000000000000');
    console.log('nest: ' + nest.address);
    
    const nestPriceFacade = await NestPriceFacade.deploy(nest.address);
    //const nestPriceFacade = await NestPriceFacade.attach('0x0000000000000000000000000000000000000000');
    console.log('nestPriceFacade: ' + nestPriceFacade.address);
    
    const cnode = await TestERC20.deploy('CNode', 'CNode', 0);
    //const cnode = await TestERC20.attach('0x0000000000000000000000000000000000000000');
    console.log('cnode: ' + cnode.address);

    const cofi = await CoFiToken.deploy();
    //const cofi = await CoFiToken.attach('0x0000000000000000000000000000000000000000');
    console.log('cofi: ' + cofi.address);

    // 2. Deploy structure contract
    const cofixGovernance = await upgrades.deployProxy(CoFiXGovernance, ['0x0000000000000000000000000000000000000000'], { initializer: 'initialize' });
    //const cofixGovernance = await CoFiXGovernance.attach('0x0000000000000000000000000000000000000000');
    console.log('cofixGovernance: ' + cofixGovernance.address);
    
    const cofixDAO = await upgrades.deployProxy(CoFiXDAO, [cofixGovernance.address], { initializer: 'initialize' });
    //const cofixDAO = await CoFiXDAO.attach('0x0000000000000000000000000000000000000000');
    console.log('cofixDAO: ' + cofixDAO.address);
    
    const cofixRouter = await upgrades.deployProxy(CoFiXRouter, [cofixGovernance.address], { initializer: 'initialize' });
    //const cofixRouter = await CoFiXRouter.attach('0x0000000000000000000000000000000000000000');
    console.log('cofixRouter: ' + cofixRouter.address);
        
    //const cofixController = await CoFiXController.deploy(nestPriceFacade.address);
    let cofixController = await upgrades.deployProxy(CoFiXController, [nestPriceFacade.address], { initializer: 'initialize' });
    //let cofixController = await CoFiXController.attach('0x0000000000000000000000000000000000000000');
    console.log('cofixController: ' + cofixController.address);
    const proxyAdmin = await ethers.getContractAt('IProxyAdmin', await cofixController.getAdmin());
    console.log('proxyAdmin: ' + proxyAdmin.address);
    const cofixControllerImpl = await proxyAdmin.getProxyImplementation(cofixController.address);
    console.log('cofixControllerImpl: ' + cofixControllerImpl);
    cofixController = await CoFiXController.attach(cofixControllerImpl);
    await cofixController.initialize(nestPriceFacade.address);

    // 3. Deploy pool contract
    const usdtPair = await upgrades.deployProxy(CoFiXPair, [cofixGovernance.address, 'XT-1', 'XToken-1', usdt.address, BigInt(1000000000), BigInt(2)], { initializer: 'init' });
    //const usdtPair = await CoFiXPair.attach('0x0000000000000000000000000000000000000000');
    console.log('usdtPair: ' + usdtPair.address);

    const hbtcPair = await upgrades.deployProxy(CoFiXPair, [cofixGovernance.address, 'XT-2', 'XToken-2', hbtc.address, BigInt(20), BigInt(1)], { initializer: 'init' });
    //const hbtcPair = await CoFiXPair.attach('0x0000000000000000000000000000000000000000');
    console.log('hbtcPair: ' + hbtcPair.address);

    const nestPair = await upgrades.deployProxy(CoFiXPair, [cofixGovernance.address, 'XT-3', 'XToken-3', nest.address, BigInt(1), BigInt(100000)], { initializer: 'init' });
    //const nestPair = await CoFiXPair.attach('0x0000000000000000000000000000000000000000');
    console.log('nestPair: ' + nestPair.address);

    const cofiPair = await upgrades.deployProxy(CoFiXPair, [cofixGovernance.address, 'XT-4', 'XToken-4', cofi.address, BigInt(1), BigInt(2000)], { initializer: 'init' });
    //const cofiPair = await CoFiXPair.attach('0x0000000000000000000000000000000000000000');
    console.log('cofiPair: ' + cofiPair.address);

    const nest_usdt_pool = await upgrades.deployProxy(CoFiXOpenPool, [cofixGovernance.address, 'XT-1', 'XToken-1', usdt.address, nest.address], { initializer: 'init' });
    //const nest_usdt_pool = await CoFiXOpenPool.attach('0x0000000000000000000000000000000000000000');
    console.log('nest_usdt_pool: ' + nest_usdt_pool.address);

    // Deploy eth anchor pool
    let ethAnchor = await upgrades.deployProxy(CoFiXAnchorPool, [
        cofixGovernance.address, 
        1, 
        [eth.address, peth.address],
        ['1000000000000000000', '1000000000000000000']
    ], { initializer: 'init' });
    //const ethAnchor = await CoFiXAnchorPool.attach('0x0000000000000000000000000000000000000000');
    console.log('ethAnchor: ' + ethAnchor.address);

    // Deploy usd anchor pool
    let usdAnchor = await upgrades.deployProxy(CoFiXAnchorPool, [
        cofixGovernance.address, 
        2,
        [usdt.address, pusd.address, usdc.address],
        [1000000, '1000000000000000000', 1000000]
    ], { initializer: 'init' });
    //const usdAnchor = await CoFiXAnchorPool.attach('0x0000000000000000000000000000000000000000');
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

    // 4. Update
    console.log('1. cofixGovernance.setBuiltinAddress');
    await cofixGovernance.setBuiltinAddress(
        cofi.address,
        cnode.address,
        cofixDAO.address,
        cofixRouter.address,
        cofixController.address,
        '0x0000000000000000000000000000000000000000'
    );
    console.log('2. cofixDAO.update');
    await cofixDAO.update(cofixGovernance.address);
    console.log('3. cofixRouter.update');
    await cofixRouter.update(cofixGovernance.address);
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
    console.log('10. nest_usdt_pool.update(cofixGovernance.address)');
    await nest_usdt_pool.update(cofixGovernance.address);

    // 6. Set pool config
    console.log('12. usdtPair.setConfig()');
    await usdtPair.setConfig(20, '1', '100000000000000000');
    console.log('13. hbtcPair.setConfig()');
    await hbtcPair.setConfig(20, '1', '100000000000000000');
    console.log('14. nestPair.setConfig()');
    await nestPair.setConfig(20, '200', '100000000000000000');
    console.log('15. cofiPair.setConfig()');
    await cofiPair.setConfig(20, '500', '100000000000000000');
    console.log('16. ethAnchor.setConfig()');
    await ethAnchor.setConfig(20, 0, '100000000000000000');
    console.log('17. usdAnchor.setConfig()');
    await usdAnchor.setConfig(20, 0, '50000000000000');
    console.log('12. nest_usdt_pool.setConfig()');
    await nest_usdt_pool.setConfig(0, 0, 2000000000000000000000n, 30, 10, 2000, 102739726027n);

    // 9. Register pairs
    console.log('24. registerPair(eth.address, usdt.address, usdtPair.address)');
    await cofixRouter.registerPair(eth.address, usdt.address, usdtPair.address);
    console.log('25. registerPair(eth.address, hbtc.address, hbtcPair.address)');
    await cofixRouter.registerPair(eth.address, hbtc.address, hbtcPair.address);
    console.log('26. registerPair(eth.address, nest.address, nestPair.address)');
    await cofixRouter.registerPair(eth.address, nest.address, nestPair.address);
    console.log('27. registerPair(eth.address, cofi.address, cofiPair.address)');
    await cofixRouter.registerPair(eth.address, cofi.address, cofiPair.address);

    // Register eth anchor pool
    console.log('28. registerPair(eth.address, peth.address, ethAnchor.address)');
    await cofixRouter.registerPair(eth.address, peth.address, ethAnchor.address);
    // Register usd anchor pool
    console.log('29. registerPair(usdt.address, pusd.address, usdAnchor.address)');
    await cofixRouter.registerPair(usdt.address, pusd.address, usdAnchor.address);
    console.log('30. registerPair(usdt.address, usdc.address, usdAnchor.address)');
    await cofixRouter.registerPair(usdt.address, usdc.address, usdAnchor.address);
    console.log('31. registerPair(pusd.address, usdc.address, usdAnchor.address)');
    await cofixRouter.registerPair(pusd.address, usdc.address, usdAnchor.address);

    // 9. Register pairs
    console.log('24. registerPair(nest.address, usdt.address, nest_usdt_pool.address)');
    await cofixRouter.registerPair(nest.address, usdt.address, nest_usdt_pool.address);

    // 10. Set minters
    console.log('33. cofi.addMinter(cofixRouter.address)');
    await cofi.addMinter(cofixRouter.address);
    
    await nest_usdt_pool.setNestOpenPrice(nestPriceFacade.address);
    
    const contracts = {
        cofi: cofi,
        cnode: cnode,
        cofixDAO: cofixDAO,
        cofixRouter: cofixRouter,
        cofixController: cofixController,
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
        usdAnchor: usdAnchor,
        nest_usdt_pool: nest_usdt_pool
    };
    
    //console.log(contracts);
    console.log('** Deployed **');
    return contracts;
}
