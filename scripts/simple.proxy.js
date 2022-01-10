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
    const CoFiXDAOSimple = await ethers.getContractFactory('CoFiXDAOSimple');
    const CoFiXRouter = await ethers.getContractFactory('CoFiXRouter');
    //const CoFiXVaultForStaking = await ethers.getContractFactory('CoFiXVaultForStaking');
    //const CoFiXController = await ethers.getContractFactory('CoFiXController');
    //const CoFiXPair = await ethers.getContractFactory('CoFiXPair');
    //const CoFiXAnchorPool = await ethers.getContractFactory('CoFiXAnchorPool');
    //const CoFiXAnchorToken = await ethers.getContractFactory('CoFiXAnchorToken');
    const CoFiXOpenPool = await ethers.getContractFactory('CoFiXOpenPool');

    console.log('** 开始部署合约 simple.proxy.js **');
    
    // 1. 部署依赖合约
    const usdt = await TestERC20.deploy('USDT', 'USDT', 18);
    //const usdt = await TestERC20.attach('0x0000000000000000000000000000000000000000');
    console.log('usdt: ' + usdt.address);

    let peth = await TestERC20.deploy('PETH', 'PETH', 18);
    //const peth = await TestERC20.attach('0x0000000000000000000000000000000000000000');
    console.log('peth: ' + peth.address);

    let pusd = await TestERC20.deploy('PUSD', 'PUSD', 18);
    //const pusd = await TestERC20.attach('0x0000000000000000000000000000000000000000');
    console.log('pusd: ' + pusd.address);

    const nest = await TestERC20.deploy('NEST', 'NEST', 18);
    //const nest = await TestERC20.attach('0x0000000000000000000000000000000000000000');
    console.log('nest: ' + nest.address);
    
    const nestPriceFacade = await NestPriceFacade.deploy(nest.address);
    //const nestPriceFacade = await NestPriceFacade.attach('0x0000000000000000000000000000000000000000');
    console.log('nestPriceFacade: ' + nestPriceFacade.address);

    // 2. 部署结构合约
    const cofixGovernance = await upgrades.deployProxy(CoFiXGovernance, ['0x0000000000000000000000000000000000000000'], { initializer: 'initialize' });
    //const cofixGovernance = await CoFiXGovernance.attach('0x0000000000000000000000000000000000000000');
    console.log('cofixGovernance: ' + cofixGovernance.address);
    
    const cofixDAO = await upgrades.deployProxy(CoFiXDAOSimple, [cofixGovernance.address], { initializer: 'initialize' });
    //const cofixDAO = await CoFiXDAO.attach('0x0000000000000000000000000000000000000000');
    console.log('cofixDAO: ' + cofixDAO.address);
    
    const cofixRouter = await upgrades.deployProxy(CoFiXRouter, [cofixGovernance.address], { initializer: 'initialize' });
    //const cofixRouter = await CoFiXRouter.attach('0x0000000000000000000000000000000000000000');
    console.log('cofixRouter: ' + cofixRouter.address);
        
    
    // 3. 部署资金池合约
    const nest_usdt_pool = await upgrades.deployProxy(CoFiXOpenPool, [cofixGovernance.address, 'XT-1', 'XToken-1', usdt.address, nest.address], { initializer: 'init' });
    //const usdtPair = await CoFiXPair.attach('0x0000000000000000000000000000000000000000');
    console.log('nest_usdt_pool: ' + nest_usdt_pool.address);

    // 4. 更新合约
    console.log('1. cofixGovernance.setBuiltinAddress');
    await cofixGovernance.setBuiltinAddress(
        '0x0000000000000000000000000000000000000000', //cofi.address,
        '0x0000000000000000000000000000000000000000', //cnode.address,
        cofixDAO.address,
        cofixRouter.address,
        '0x0000000000000000000000000000000000000000', //cofixController.address,
        '0x0000000000000000000000000000000000000000' //cofixVaultForStaking.address
    );
    console.log('2. cofixDAO.update');
    await cofixDAO.update(cofixGovernance.address);
    console.log('3. cofixRouter.update');
    await cofixRouter.update(cofixGovernance.address);
    console.log('10. nest_usdt_pool.update(cofixGovernance.address)');
    await nest_usdt_pool.update(cofixGovernance.address);

    // 6. 初始化资金池参数
    console.log('12. nest_usdt_pool.setConfig()');
    await nest_usdt_pool.setConfig(0, 0, 30, 10, 200, 102739726027n);

    // 9. 注册交易对
    // 注册usdt和nest交易对
    console.log('24. registerPair(nest.address, usdt.address, nest_usdt_pool.address)');
    await cofixRouter.registerPair(nest.address, usdt.address, nest_usdt_pool.address);

    await nest_usdt_pool.setNestOpenPrice(nestPriceFacade.address);

    const contracts = {
        //cofi: cofi,
        //cnode: cnode,
        cofixDAO: cofixDAO,
        cofixRouter: cofixRouter,
        //cofixController: cofixController,
        //cofixVaultForStaking: cofixVaultForStaking,
        cofixGovernance: cofixGovernance,
        nestPriceFacade: nestPriceFacade,

        usdt: usdt,
        //hbtc: hbtc,
        nest: nest,
        peth: peth,
        pusd: pusd,
        //usdc: usdc,

        nest_usdt_pool: nest_usdt_pool
    };
    
    //console.log(contracts);
    console.log('** 合约部署完成 **');
    return contracts;
}
