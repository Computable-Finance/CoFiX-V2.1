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
    const CoFiXOpenPool = await ethers.getContractFactory('CoFiXOpenPool');

    console.log('** 开始部署合约 bsc_main@20211127.js **');

    //     ** 开始部署合约 bsc@20211120.js **
    // usdt: 0x55d398326f99059ff775485246999027b3197955
    // nest: 0x98f8669F6481EbB341B522fCD3663f79A3d1A6A7
    // pusd: 0x9b2689525e07406D8A6fB1C40a1b86D2cd34Cbb2
    // peth: 0x556d8bF8bF7EaAF2626da679Aa684Bac347d30bB
    // nestGovernance: 0x7b5ee1Dc65E2f3EDf41c798e7bd3C22283C3D4bb
    // nestLedger: 0x7DBe94A4D6530F411A1E7337c7eb84185c4396e6
    // nestOpenMining: 0x09CE0e021195BA2c1CDE62A8B187abf810951540

    // 1. 部署依赖合约
    //const usdt = await TestERC20.deploy('USDT', 'USDT', 18);
    const usdt = await TestERC20.attach('0x55d398326f99059ff775485246999027b3197955');
    console.log('usdt: ' + usdt.address);

    //let peth = await TestERC20.deploy('PETH', 'PETH', 18);
    const peth = await TestERC20.attach('0x556d8bF8bF7EaAF2626da679Aa684Bac347d30bB');
    console.log('peth: ' + peth.address);

    //let pusd = await TestERC20.deploy('PUSD', 'PUSD', 18);
    const pusd = await TestERC20.attach('0x9b2689525e07406D8A6fB1C40a1b86D2cd34Cbb2');
    console.log('pusd: ' + pusd.address);

    //const nest = await TestERC20.deploy('NEST', 'NEST', 18);
    const nest = await TestERC20.attach('0x98f8669F6481EbB341B522fCD3663f79A3d1A6A7');
    console.log('nest: ' + nest.address);
    
    //const nestPriceFacade = await NestPriceFacade.deploy(nest.address);
    const nestPriceFacade = await NestPriceFacade.attach('0x09CE0e021195BA2c1CDE62A8B187abf810951540');
    console.log('nestPriceFacade: ' + nestPriceFacade.address);

    // 2. 部署结构合约
    const cofixGovernance = await upgrades.deployProxy(CoFiXGovernance, ['0x0000000000000000000000000000000000000000'], { initializer: 'initialize' });
    //const cofixGovernance = await CoFiXGovernance.attach('0x0000000000000000000000000000000000000000');
    console.log('cofixGovernance: ' + cofixGovernance.address);
    
    const cofixDAO = await upgrades.deployProxy(CoFiXDAOSimple, [cofixGovernance.address], { initializer: 'initialize' });
    //const cofixDAO = await CoFiXDAOSimple.attach('0x0000000000000000000000000000000000000000');
    console.log('cofixDAO: ' + cofixDAO.address);
    
    const cofixRouter = await upgrades.deployProxy(CoFiXRouter, [cofixGovernance.address], { initializer: 'initialize' });
    //const cofixRouter = await CoFiXRouter.attach('0x0000000000000000000000000000000000000000');
    console.log('cofixRouter: ' + cofixRouter.address);
        
    // 3. 部署资金池合约
    const nest_usdt_pool = await upgrades.deployProxy(CoFiXOpenPool, [cofixGovernance.address, 'XT-1', 'XToken-1', usdt.address, nest.address], { initializer: 'init' });
    //const nest_usdt_pool = await CoFiXOpenPool.attach('0x0000000000000000000000000000000000000000');
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
    // console.log('2. cofixDAO.update');
    // await cofixDAO.update(cofixGovernance.address);
    // console.log('3. cofixRouter.update');
    // await cofixRouter.update(cofixGovernance.address);
    console.log('10. nest_usdt_pool.update(cofixGovernance.address)');
    await nest_usdt_pool.update(cofixGovernance.address);

    // 6. 初始化资金池参数
    console.log('12. nest_usdt_pool.setConfig()');
    await nest_usdt_pool.setConfig(30, 10, 200, 102739726027n);

    // 9. 注册交易对
    // 注册usdt和nest交易对
    console.log('24. registerPair(nest.address, usdt.address, nest_usdt_pool.address)');
    await cofixRouter.registerPair(nest.address, usdt.address, nest_usdt_pool.address);

    //await nest_usdt_pool.setNestOpenPrice(nestPriceFacade.address);
    //await nest_usdt_pool.setPriceChannelId(1);

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
