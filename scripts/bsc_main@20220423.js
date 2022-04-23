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

    console.log('** Deploy: bsc_main@20220423.js **');

    // ** Deploy: bsc_main@20220423.js **
    // usdt: 0x55d398326f99059ff775485246999027b3197955
    // peth: 0x556d8bF8bF7EaAF2626da679Aa684Bac347d30bB
    // pusd: 0x9b2689525e07406D8A6fB1C40a1b86D2cd34Cbb2
    // nest: 0x98f8669F6481EbB341B522fCD3663f79A3d1A6A7
    // nestPriceFacade: 0x09CE0e021195BA2c1CDE62A8B187abf810951540
    // cofixGovernance: 0xF12F003ee11461dA376C70c03b2E8f1498C3AeA3
    // cofixDAO: 0x72A63055b9AA997A4311D0D068170e38F5455b82
    // cofixRouter: 0xb29A8d980E1408E487B9968f5E4f7fD7a9B0CaC5
    // nestOpenPool: 0x2BCeF6BDA147ca5E2C7ad0325CCCdcD01202f62a

    // proxyAdmin: 0x618B7b93b07Bf78D04B2e8FB2B1C3B48049F8ED5
    
    // 1. Deploy dependent contract
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

    // 2. Deploy structure contract
    //const cofixGovernance = await upgrades.deployProxy(CoFiXGovernance, ['0x0000000000000000000000000000000000000000'], { initializer: 'initialize' });
    const cofixGovernance = await CoFiXGovernance.attach('0xF12F003ee11461dA376C70c03b2E8f1498C3AeA3');
    console.log('cofixGovernance: ' + cofixGovernance.address);
    
    //const cofixDAO = await upgrades.deployProxy(CoFiXDAOSimple, [cofixGovernance.address], { initializer: 'initialize' });
    const cofixDAO = await CoFiXDAOSimple.attach('0x72A63055b9AA997A4311D0D068170e38F5455b82');
    console.log('cofixDAO: ' + cofixDAO.address);
    
    //const cofixRouter = await upgrades.deployProxy(CoFiXRouter, [cofixGovernance.address], { initializer: 'initialize' });
    const cofixRouter = await CoFiXRouter.attach('0xb29A8d980E1408E487B9968f5E4f7fD7a9B0CaC5');
    console.log('cofixRouter: ' + cofixRouter.address);
        
    // 3. Deploy pool contract
    //const nest_usdt_pool = await upgrades.deployProxy(CoFiXOpenPool, [cofixGovernance.address, 'XT-1', 'XToken-1', usdt.address, nest.address], { initializer: 'init' });
    const nest_usdt_pool = await CoFiXOpenPool.attach('0x278f5d08bEa1989BEfcC09A20ad60fB39702D556');
    console.log('nest_usdt_pool: ' + nest_usdt_pool.address);

    // 3. Deploy pool contract
    //const nestOpenPool = await upgrades.deployProxy(CoFiXOpenPool, [cofixGovernance.address, 'XT-2', 'XToken-2', usdt.address, nest.address], { initializer: 'init' });
    const nestOpenPool = await CoFiXOpenPool.attach('0x2BCeF6BDA147ca5E2C7ad0325CCCdcD01202f62a');
    console.log('nestOpenPool: ' + nestOpenPool.address);

    // console.log('10. nestOpenPool.update(cofixGovernance.address)');
    // await nestOpenPool.update(cofixGovernance.address);

    // // 6. Set pool config
    // console.log('12. nestOpenPool.setConfig()');
    // await nestOpenPool.setConfig(0, 1, 2000000000000000000000n, 30, 10, 2000, 102739726027n);

    // 9. Register pairs
    console.log('24. registerPair(nest.address, usdt.address, nestOpenPool.address)');
    await cofixRouter.registerPair(nest.address, usdt.address, nestOpenPool.address);

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

        nest_usdt_pool: nest_usdt_pool,
        nestOpenPool: nestOpenPool
    };
    
    //console.log(contracts);
    console.log('** Deployed **');
    return contracts;
}
