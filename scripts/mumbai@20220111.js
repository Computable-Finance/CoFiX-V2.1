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
    //const CoFiXVaultForStaking = await ethers.getContractFactory('CoFiXVaultForStaking');
    //const CoFiXController = await ethers.getContractFactory('CoFiXController');
    //const CoFiXPair = await ethers.getContractFactory('CoFiXPair');
    //const CoFiXAnchorPool = await ethers.getContractFactory('CoFiXAnchorPool');
    //const CoFiXAnchorToken = await ethers.getContractFactory('CoFiXAnchorToken');
    const CoFiXOpenPool = await ethers.getContractFactory('CoFiXOpenPool');

    console.log('** 开始部署合约 mumbai@20220111.js **');
    
    // nest: 0x58694D405C8Cd917880FC1E23729fc0B90B7732c
    // usdt: 0xd32502b39da054dfF448AaBc1cb8210C756535f6
    // pusd: 0xEfF166764c1eF0e768D57FfEd7736f6C11eE6A4f
    // peth: 0xDdBF1D99A1f92Ee7c20E39B34001fA0784714043
    // nestGovernance: 0xF0737e3C98f1Ee41251681e2C6ad53Ab92AB0AEa
    // nestLedger: 0xbe388405c5f091f46DA440652f776c9832e0d1c3
    // nestBatchMining: 0xD3E0Effa6A9cEC78C95c1FD0BbcCCA5929068B83
    // proxyAdmin: 0xAc88d1fBF58E2646E0F4FF60aa436a70753885D9
    
    // dcu: 0x51EFE1E589354e1f24C7d4533D21F74f973c6eED
    // nestPriceFacade: 0xD3E0Effa6A9cEC78C95c1FD0BbcCCA5929068B83
    // hedgeGovernance: 0x906F3320286eCf8e7524e48Af2d62598F65bf1b2
    // hedgeOptions: 0x6636F38F59Db0d3dD2f53e6cA4831EB2B5A1047c
    // hedgeFutures: 0x8f89663562dDD4519566e590C18ec892134A0cdD
    // hedgeSwap: 0x82502A8f52BF186907BD0E12c8cEe612b4C203d1
    // proxyAdmin: 0x48f62fe14722455C5519303C2Eb89046107a3fD1

    // cofixGovernance: 0xB52E62003F106Ec763A95F4eBc89047A686a3f7c
    // cofixDAO: 0x31a8dF221E790AC7e20f021D2bEf94b1Bb7CE6D7
    // cofixRouter: 0xe51f5cfD748db482D599602742B8bEc4D679c6f1
    // nest_usdt_pool: 0x459Dac18933cdC80040382b25851660761E6EF40
    //                  -> 0x3c74E71cf4582B39d60d561Af38831c9C802B234
    // proxyAdmin: 0x7E015B01307A40D56e5720d68a4e7D29b4377702

    // 1. 部署依赖合约
    //const usdt = await TestERC20.deploy('USDT', 'USDT', 6);
    const usdt = await TestERC20.attach('0xd32502b39da054dfF448AaBc1cb8210C756535f6');
    console.log('usdt: ' + usdt.address);

    //let peth = await TestERC20.deploy('PETH', 'PETH', 18);
    const peth = await TestERC20.attach('0xDdBF1D99A1f92Ee7c20E39B34001fA0784714043');
    console.log('peth: ' + peth.address);

    //let pusd = await TestERC20.deploy('PUSD', 'PUSD', 18);
    const pusd = await TestERC20.attach('0xEfF166764c1eF0e768D57FfEd7736f6C11eE6A4f');
    console.log('pusd: ' + pusd.address);

    //const nest = await TestERC20.deploy('NEST', 'NEST', 18);
    const nest = await TestERC20.attach('0x58694D405C8Cd917880FC1E23729fc0B90B7732c');
    console.log('nest: ' + nest.address);
    
    //const nestPriceFacade = await NestPriceFacade.deploy(nest.address);
    const nestPriceFacade = await NestPriceFacade.attach('0xD3E0Effa6A9cEC78C95c1FD0BbcCCA5929068B83');
    console.log('nestPriceFacade: ' + nestPriceFacade.address);

    // 2. 部署结构合约
    //const cofixGovernance = await upgrades.deployProxy(CoFiXGovernance, ['0x0000000000000000000000000000000000000000'], { initializer: 'initialize' });
    const cofixGovernance = await CoFiXGovernance.attach('0xB52E62003F106Ec763A95F4eBc89047A686a3f7c');
    console.log('cofixGovernance: ' + cofixGovernance.address);

    //const cofixDAO = await upgrades.deployProxy(CoFiXDAOSimple, [cofixGovernance.address], { initializer: 'initialize' });
    const cofixDAO = await CoFiXDAO.attach('0x31a8dF221E790AC7e20f021D2bEf94b1Bb7CE6D7');
    console.log('cofixDAO: ' + cofixDAO.address);
    
    //const cofixRouter = await upgrades.deployProxy(CoFiXRouter, [cofixGovernance.address], { initializer: 'initialize' });
    const cofixRouter = await CoFiXRouter.attach('0xe51f5cfD748db482D599602742B8bEc4D679c6f1');
    console.log('cofixRouter: ' + cofixRouter.address);
    
    // 3. 部署资金池合约
    //const nest_usdt_pool = await upgrades.deployProxy(CoFiXOpenPool, [cofixGovernance.address, 'XT-1.1', 'XToken-1.1', usdt.address, nest.address], { initializer: 'init' });
    const nest_usdt_pool = await CoFiXOpenPool.attach('0x3c74E71cf4582B39d60d561Af38831c9C802B234');
    console.log('nest_usdt_pool: ' + nest_usdt_pool.address);

    // // 4. 更新合约
    // console.log('1. cofixGovernance.setBuiltinAddress');
    // await cofixGovernance.setBuiltinAddress(
    //     '0x0000000000000000000000000000000000000000', //cofi.address,
    //     '0x0000000000000000000000000000000000000000', //cnode.address,
    //     cofixDAO.address,
    //     cofixRouter.address,
    //     '0x0000000000000000000000000000000000000000', //cofixController.address,
    //     '0x0000000000000000000000000000000000000000' //cofixVaultForStaking.address
    // );
    // console.log('2. cofixDAO.update');
    // await cofixDAO.update(cofixGovernance.address);
    // console.log('3. cofixRouter.update');
    // await cofixRouter.update(cofixGovernance.address);
    // console.log('10. nest_usdt_pool.update(cofixGovernance.address)');
    // await nest_usdt_pool.update(cofixGovernance.address);

    // // 6. 初始化资金池参数
    // console.log('12. nest_usdt_pool.setConfig()');
    // await nest_usdt_pool.setConfig(0, 1, 2000000000n, 30, 10, 200, 102739726027n);

    // // 9. 注册交易对
    // // 注册usdt和nest交易对
    // console.log('24. registerPair(nest.address, usdt.address, nest_usdt_pool.address)');
    // await cofixRouter.registerPair(nest.address, usdt.address, nest_usdt_pool.address);

    // await nest_usdt_pool.setNestOpenPrice(nestPriceFacade.address);

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

        nest_usdt_pool: nest_usdt_pool
    };
    
    //console.log(contracts);
    console.log('** 合约部署完成 **');
    return contracts;
}
