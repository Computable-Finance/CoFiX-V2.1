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

    console.log('** 开始部署合约 bsc_test@20220419.js **');

    // ** 开始部署合约 bsc_test@20220419.js **
    // usdt: 0xDd4A68D8236247BDC159F7C5fF92717AA634cBCc
    // peth: 0xc39dC1385a44fBB895991580EA55FC10e7451cB3
    // pusd: 0x3DA5c9aafc6e6D6839E62e2fB65825869019F291
    // nest: 0x821edD79cc386E56FeC9DA5793b87a3A52373cdE
    // nestPriceFacade: 0xF2f9E62f52389EF223f5Fa8b9926e95386935277
    // cofixGovernance: 0xD69399d7B6a7E6481596065272F5E50329DA5914
    // cofixDAO: 0x76D8680e763c611f204c974cf2F6c203d44fd124
    // cofixRouter: 0x4A448cBb12e449D7031f36C8122eCE6dDdf9cc84
    // nest_usdt_pool: 0xBc95AB3Ce2F9e87C1453514a838234F9C0E6DB86

    // 1. 部署依赖合约
    //const usdt = await TestERC20.deploy('USDT', 'USDT', 18);
    const usdt = await TestERC20.attach('0xDd4A68D8236247BDC159F7C5fF92717AA634cBCc');
    console.log('usdt: ' + usdt.address);

    //let peth = await TestERC20.deploy('PETH', 'PETH', 18);
    const peth = await TestERC20.attach('0xc39dC1385a44fBB895991580EA55FC10e7451cB3');
    console.log('peth: ' + peth.address);

    //let pusd = await TestERC20.deploy('PUSD', 'PUSD', 18);
    const pusd = await TestERC20.attach('0x3DA5c9aafc6e6D6839E62e2fB65825869019F291');
    console.log('pusd: ' + pusd.address);

    //const nest = await TestERC20.deploy('NEST', 'NEST', 18);
    const nest = await TestERC20.attach('0x821edD79cc386E56FeC9DA5793b87a3A52373cdE');
    console.log('nest: ' + nest.address);
    
    //const nestPriceFacade = await NestPriceFacade.deploy(nest.address);
    const nestPriceFacade = await NestPriceFacade.attach('0xF2f9E62f52389EF223f5Fa8b9926e95386935277');
    console.log('nestPriceFacade: ' + nestPriceFacade.address);

    // 2. 部署结构合约
    //const cofixGovernance = await upgrades.deployProxy(CoFiXGovernance, ['0x0000000000000000000000000000000000000000'], { initializer: 'initialize' });
    const cofixGovernance = await CoFiXGovernance.attach('0xD69399d7B6a7E6481596065272F5E50329DA5914');
    console.log('cofixGovernance: ' + cofixGovernance.address);
    
    //const cofixDAO = await upgrades.deployProxy(CoFiXDAOSimple, [cofixGovernance.address], { initializer: 'initialize' });
    const cofixDAO = await CoFiXDAO.attach('0x76D8680e763c611f204c974cf2F6c203d44fd124');
    console.log('cofixDAO: ' + cofixDAO.address);
    
    //const cofixRouter = await upgrades.deployProxy(CoFiXRouter, [cofixGovernance.address], { initializer: 'initialize' });
    const cofixRouter = await CoFiXRouter.attach('0x4A448cBb12e449D7031f36C8122eCE6dDdf9cc84');
    console.log('cofixRouter: ' + cofixRouter.address);
        
    // 3. 部署资金池合约
    //const nest_usdt_pool = await upgrades.deployProxy(CoFiXOpenPool, [cofixGovernance.address, 'XT-2', 'XToken-2', usdt.address, nest.address], { initializer: 'init' });
    const nest_usdt_pool = await CoFiXOpenPool.attach('0xBc95AB3Ce2F9e87C1453514a838234F9C0E6DB86');
    console.log('nest_usdt_pool: ' + nest_usdt_pool.address);

    // console.log('10. nest_usdt_pool.update(cofixGovernance.address)');
    // await nest_usdt_pool.update(cofixGovernance.address);

    // // 6. 初始化资金池参数
    // console.log('12. nest_usdt_pool.setConfig()');
    // await nest_usdt_pool.setConfig(0, 1, 2000000000000000000000n, 30, 10, 2000, 102739726027n);

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
        //usdc: usdc,

        nest_usdt_pool: nest_usdt_pool
    };
    
    //console.log(contracts);
    console.log('** 合约部署完成 **');
    return contracts;
}
