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

    console.log('** mainnet@20210729.js **');

    // USDT	    0xdAC17F958D2ee523a2206206994597C13D831ec7
    // HBTC	    0x0316EB71485b0Ab14103307bf65a021042c6d380
    // PETH	    0x53f878Fb7Ec7B86e4F9a0CB1E9a6c89C0555FbbD
    // PUSD	    0xCCEcC702Ec67309Bc3DDAF6a42E9e5a6b8Da58f0
    // USDC	    0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
    // NEST	    0x04abEdA201850aC0124161F037Efd70c74ddC74C
    // NestPriceFacade 0xB5D2890c061c321A5B6A4a4254bb1522425BAF0A
    // CNODE	0x558201DC4741efc11031Cdc3BC1bC728C23bF512
    // COFI	    0x1a23a6BfBAdB59fa563008c0fB7cf96dfCF34Ea1

    //     ** mainnet@20210729.js **
    // usdt: 0xdAC17F958D2ee523a2206206994597C13D831ec7
    // hbtc: 0x0316EB71485b0Ab14103307bf65a021042c6d380
    // peth: 0x53f878Fb7Ec7B86e4F9a0CB1E9a6c89C0555FbbD
    // pusd: 0xCCEcC702Ec67309Bc3DDAF6a42E9e5a6b8Da58f0
    // usdc: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
    // nest: 0x04abEdA201850aC0124161F037Efd70c74ddC74C
    // nestPriceFacade: 0xB5D2890c061c321A5B6A4a4254bb1522425BAF0A
    // cnode: 0x558201DC4741efc11031Cdc3BC1bC728C23bF512
    // cofi: 0x1a23a6BfBAdB59fa563008c0fB7cf96dfCF34Ea1
    // cofixGovernance: 0xa0376c279940b26d1D8D03eaB5a3d8bD3F6b0DD4

    //     ** mainnet@20210729.js **
    // usdt: 0xdAC17F958D2ee523a2206206994597C13D831ec7
    // hbtc: 0x0316EB71485b0Ab14103307bf65a021042c6d380
    // peth: 0x53f878Fb7Ec7B86e4F9a0CB1E9a6c89C0555FbbD
    // pusd: 0xCCEcC702Ec67309Bc3DDAF6a42E9e5a6b8Da58f0
    // usdc: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
    // nest: 0x04abEdA201850aC0124161F037Efd70c74ddC74C
    // nestPriceFacade: 0xB5D2890c061c321A5B6A4a4254bb1522425BAF0A
    // cnode: 0x558201DC4741efc11031Cdc3BC1bC728C23bF512
    // cofi: 0x1a23a6BfBAdB59fa563008c0fB7cf96dfCF34Ea1
    // cofixGovernance: 0xa0376c279940b26d1D8D03eaB5a3d8bD3F6b0DD4
    // cofixDAO: 0x2Cf06Aa521DD979Bc1b50ce44590A09db21d6A74
    // cofixRouter: 0x57F0A4ef374B35eb32B61Dd8bc68C58e886CFC84
    // cofixVaultForStaking: 0x7Bd4546DEdB397a0f0D7593A7Fa7f2Ceb3ff32E6
    // cofixController: 0x8eFFbf9CA7dB20481cE9C25EA4B410b3B835D70E
    // proxyAdmin: 0xe14223f09B2d53Af50fbcf2b48c8139e4920BC31
    // cofixControllerImpl: 0x377491fF2eec6a7Fd6723D98C25403dfff1DF2eB
    // usdtPair: 0xFa8055B3e0C36605bB31e23bC565C31eb3Dca386
    // hbtcPair: 0xd312E8374fF2B0260A32aF5f91BA8d8EaFAE856B
    // nestPair: 0x2FA6F2d5e42630e872cD0F33C69D1c2708FF79Fd
    // cofiPair: 0x711EA25b70Bb580a7cb19DeBd0ab40A016c3fCbb
    // ethAnchor: 0xD7E54D936ca1e7F0ed097D4Ec6140653eC60f85D
    // usdAnchor: 0x31Aa5da47Cf6FBB203531D88e3FC47d46AE6D46b
    // xeth: 0xB6e9B1D8814DA83a663832822765fc4d4008Fd97
    // xpeth: 0xAB53A40e3153901c761CE55EfA5F0789dbD5F047
    // xusdt: 0x172b260F92d1A0661e9888918a19154E99E0B9f0
    // xpusd: 0x2b06Af945F1c18A6bf02ac6E401Fd251d9FfdBCf
    // xusdc: 0xF5beBE517eb95557CBcFd19a2BAfa8e9fC50C5EE

    // 1. 部署依赖合约
    //const usdt = await TestERC20.deploy('USDT', 'USDT', 6);
    const usdt = await TestERC20.attach('0xdAC17F958D2ee523a2206206994597C13D831ec7');
    console.log('usdt: ' + usdt.address);

    //const hbtc = await TestERC20.deploy('HBTC', 'HBTC', 18);
    const hbtc = await TestERC20.attach('0x0316EB71485b0Ab14103307bf65a021042c6d380');
    console.log('hbtc: ' + hbtc.address);

    //let peth = await TestERC20.deploy('PETH', 'PETH', 18);
    const peth = await TestERC20.attach('0x53f878Fb7Ec7B86e4F9a0CB1E9a6c89C0555FbbD');
    console.log('peth: ' + peth.address);

    //let pusd = await TestERC20.deploy('PUSD', 'PUSD', 18);
    const pusd = await TestERC20.attach('0xCCEcC702Ec67309Bc3DDAF6a42E9e5a6b8Da58f0');
    console.log('pusd: ' + pusd.address);

    //let usdc = await TestERC20.deploy('USDC', 'USDC', 6);
    const usdc = await TestERC20.attach('0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48');
    console.log('usdc: ' + usdc.address);

    //const nest = await TestERC20.deploy('NEST', 'NEST', 18);
    const nest = await TestERC20.attach('0x04abEdA201850aC0124161F037Efd70c74ddC74C');
    console.log('nest: ' + nest.address);
    
    //const nestPriceFacade = await NestPriceFacade.deploy();
    const nestPriceFacade = await NestPriceFacade.attach('0xB5D2890c061c321A5B6A4a4254bb1522425BAF0A');
    console.log('nestPriceFacade: ' + nestPriceFacade.address);
    
    //const cnode = await TestERC20.deploy('CNode', 'CNode', 0);
    const cnode = await TestERC20.attach('0x558201DC4741efc11031Cdc3BC1bC728C23bF512');
    console.log('cnode: ' + cnode.address);

    //const cofi = await CoFiToken.deploy();
    const cofi = await CoFiToken.attach('0x1a23a6BfBAdB59fa563008c0fB7cf96dfCF34Ea1');
    console.log('cofi: ' + cofi.address);

    // 2. 部署结构合约
    //const cofixGovernance = await upgrades.deployProxy(CoFiXGovernance, ['0x0000000000000000000000000000000000000000'], { initializer: 'initialize' });
    const cofixGovernance = await CoFiXGovernance.attach('0xa0376c279940b26d1D8D03eaB5a3d8bD3F6b0DD4');
    console.log('cofixGovernance: ' + cofixGovernance.address);
    
    //const cofixDAO = await upgrades.deployProxy(CoFiXDAO, [cofixGovernance.address], { initializer: 'initialize' });
    const cofixDAO = await CoFiXDAO.attach('0x2Cf06Aa521DD979Bc1b50ce44590A09db21d6A74');
    console.log('cofixDAO: ' + cofixDAO.address);
    
    //const cofixRouter = await upgrades.deployProxy(CoFiXRouter, [cofixGovernance.address], { initializer: 'initialize' });
    const cofixRouter = await CoFiXRouter.attach('0x57F0A4ef374B35eb32B61Dd8bc68C58e886CFC84');
    console.log('cofixRouter: ' + cofixRouter.address);
        
    //const cofixVaultForStaking = await upgrades.deployProxy(CoFiXVaultForStaking, [cofixGovernance.address], { initializer: 'initialize' });
    const cofixVaultForStaking = await CoFiXVaultForStaking.attach('0x7Bd4546DEdB397a0f0D7593A7Fa7f2Ceb3ff32E6');
    console.log('cofixVaultForStaking: ' + cofixVaultForStaking.address);
    
    //const cofixController = await CoFiXController.deploy(nestPriceFacade.address);
    //let cofixController = await upgrades.deployProxy(CoFiXController, [nestPriceFacade.address], { initializer: 'initialize' });
    let cofixController = await CoFiXController.attach('0x8eFFbf9CA7dB20481cE9C25EA4B410b3B835D70E');
    console.log('cofixController: ' + cofixController.address);
    const proxyAdmin = await ethers.getContractAt('IProxyAdmin', await cofixController.getAdmin());
    console.log('proxyAdmin: ' + proxyAdmin.address);
    const cofixControllerImpl = await proxyAdmin.getProxyImplementation(cofixController.address);
    console.log('cofixControllerImpl: ' + cofixControllerImpl);
    cofixController = await CoFiXController.attach(cofixControllerImpl);
    //await cofixController.initialize(nestPriceFacade.address);

    // 3. 部署资金池合约
    //const usdtPair = await upgrades.deployProxy(CoFiXPair, [cofixGovernance.address, 'XT-1', 'XToken-1', usdt.address, BigInt(1000000000), BigInt(2)], { initializer: 'init' });
    const usdtPair = await CoFiXPair.attach('0xFa8055B3e0C36605bB31e23bC565C31eb3Dca386');
    console.log('usdtPair: ' + usdtPair.address);

    //const hbtcPair = await upgrades.deployProxy(CoFiXPair, [cofixGovernance.address, 'XT-2', 'XToken-2', hbtc.address, BigInt(20), BigInt(1)], { initializer: 'init' });
    const hbtcPair = await CoFiXPair.attach('0xd312E8374fF2B0260A32aF5f91BA8d8EaFAE856B');
    console.log('hbtcPair: ' + hbtcPair.address);

    //const nestPair = await upgrades.deployProxy(CoFiXPair, [cofixGovernance.address, 'XT-3', 'XToken-3', nest.address, BigInt(1), BigInt(100000)], { initializer: 'init' });
    const nestPair = await CoFiXPair.attach('0x2FA6F2d5e42630e872cD0F33C69D1c2708FF79Fd');
    console.log('nestPair: ' + nestPair.address);

    //const cofiPair = await upgrades.deployProxy(CoFiXPair, [cofixGovernance.address, 'XT-4', 'XToken-4', cofi.address, BigInt(1), BigInt(2000)], { initializer: 'init' });
    const cofiPair = await CoFiXPair.attach('0x711EA25b70Bb580a7cb19DeBd0ab40A016c3fCbb');
    console.log('cofiPair: ' + cofiPair.address);

    // 部署ETH锚定池
    // let ethAnchor = await upgrades.deployProxy(CoFiXAnchorPool, [
    //     cofixGovernance.address, 
    //     1, 
    //     [eth.address, peth.address],
    //     ['1000000000000000000', '1000000000000000000']
    // ], { initializer: 'init' });
    const ethAnchor = await CoFiXAnchorPool.attach('0xD7E54D936ca1e7F0ed097D4Ec6140653eC60f85D');
    console.log('ethAnchor: ' + ethAnchor.address);

    // 部署USD锚定池
    // let usdAnchor = await upgrades.deployProxy(CoFiXAnchorPool, [
    //     cofixGovernance.address, 
    //     2,
    //     [usdt.address, pusd.address, usdc.address],
    //     [1000000, '1000000000000000000', 1000000]
    // ], { initializer: 'init' });
    const usdAnchor = await CoFiXAnchorPool.attach('0x31Aa5da47Cf6FBB203531D88e3FC47d46AE6D46b');
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

    // // 4. 更新合约
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

    // // 5. 设置配置
    // console.log('11. setConfig');
    // await cofixDAO.setConfig({
    //     // Redeem activate threshold, when the circulation of token exceeds this threshold, 
    //     // 回购状态, 1表示启动
    //     status: 1,

    //     // The number of CoFi redeem per block. 100
    //     cofiPerBlock: 500,

    //     // The maximum number of CoFi in a single redeem. 30000
    //     cofiLimit: 150000,

    //     // Price deviation limit, beyond this upper limit stop redeem (10000 based). 1000
    //     priceDeviationLimit: 1000
    // });

    // // 6. 初始化资金池参数
    // console.log('12. usdtPair.setConfig()');
    // await usdtPair.setConfig(20, '100000000000000000000', '100000000000000000');
    // console.log('13. hbtcPair.setConfig()');
    // await hbtcPair.setConfig(20, '100000000000000000000', '100000000000000000');
    // console.log('14. nestPair.setConfig()');
    // await nestPair.setConfig(20, '5000000000000000000', '100000000000000000');
    // console.log('15. cofiPair.setConfig()');
    // await cofiPair.setConfig(20, '5000000000000000000', '100000000000000000');
    // console.log('16. ethAnchor.setConfig()');
    // await ethAnchor.setConfig(20, 0, '100000000000000000');
    // console.log('17. usdAnchor.setConfig()');
    // await usdAnchor.setConfig(20, 0, '50000000000000');

    // // 7. 初始化锁仓挖矿参数
    // console.log('18. cofixVaultForStaking.batchSetPoolWeight()');
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

    // // 8. 设置资金兑换比例
    // console.log('19. cofixDAO.setTokenExchange(usdt.address, usdt.address)');
    // await cofixDAO.setTokenExchange(usdt.address, usdt.address, BigInt('1000000000000000000'));
    // console.log('20. cofixDAO.setTokenExchange(pusd.address, usdt.address)');
    // await cofixDAO.setTokenExchange(pusd.address, usdt.address, BigInt(1000000));
    // console.log('21. cofixDAO.setTokenExchange(usdc.address, usdt.address)');
    // await cofixDAO.setTokenExchange(usdc.address, usdt.address, BigInt('1000000000000000000'));
    // console.log('22. cofixDAO.setTokenExchange(eth.address, eth.address)');
    // await cofixDAO.setTokenExchange(eth.address, eth.address, BigInt('1000000000000000000'));
    // console.log('23. cofixDAO.setTokenExchange(peth.address, eth.address)');
    // await cofixDAO.setTokenExchange(peth.address, eth.address, BigInt('1000000000000000000'));

    // // 9. 注册交易对
    // // 注册usdt和nest交易对
    // console.log('24. registerPair(eth.address, usdt.address, usdtPair.address)');
    // await cofixRouter.registerPair(eth.address, usdt.address, usdtPair.address);
    // console.log('25. registerPair(eth.address, hbtc.address, hbtcPair.address)');
    // await cofixRouter.registerPair(eth.address, hbtc.address, hbtcPair.address);
    // console.log('26. registerPair(eth.address, nest.address, nestPair.address)');
    // await cofixRouter.registerPair(eth.address, nest.address, nestPair.address);
    // console.log('27. registerPair(eth.address, cofi.address, cofiPair.address)');
    // await cofixRouter.registerPair(eth.address, cofi.address, cofiPair.address);

    // // 注册ETH锚定池
    // console.log('28. registerPair(eth.address, peth.address, ethAnchor.address)');
    // await cofixRouter.registerPair(eth.address, peth.address, ethAnchor.address);
    // // 注册USD锚定池
    // console.log('29. registerPair(usdt.address, pusd.address, usdAnchor.address)');
    // await cofixRouter.registerPair(usdt.address, pusd.address, usdAnchor.address);
    // console.log('30. registerPair(usdt.address, usdc.address, usdAnchor.address)');
    // await cofixRouter.registerPair(usdt.address, usdc.address, usdAnchor.address);
    // console.log('31. registerPair(pusd.address, usdc.address, usdAnchor.address)');
    // await cofixRouter.registerPair(pusd.address, usdc.address, usdAnchor.address);

    // console.log('32. cofixVaultForStaking.setConfig');
    // await cofixVaultForStaking.setConfig('10000000000000000');

    // // // 10. 开通挖矿权限
    // // console.log('33. cofi.addMinter(cofixRouter.address)');
    // // await cofi.addMinter(cofixRouter.address);
    // // console.log('34. cofi.addMinter(cofixVaultForStaking.address)');
    // // await cofi.addMinter(cofixVaultForStaking.address);
    
    if (false) {
        // 11. 注册路由路径
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
    console.log('** 合约部署完成 **');
    return contracts;
}
