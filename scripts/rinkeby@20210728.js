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

    console.log('** rinkeby@20210728.js **');
    
    // | CoFiToken | 0x61EA050b28Ccca539F0faf79Fd26F6Df31b9f15B |
    // | CoFiXNode | 0x91566410cC6E9F6579e4132909F597676D5C1FB2 |
    // | CoFiXV2Factory | 0x5775F3870776bd995920D8A54caB11C60b4763eC |
    // | CoFiXV2Router | 0x1Ca87de99d604b151B6d7ac208Ea89A3751e98D6 |
    // | CoFiXV2Controller | 0xc9Be5846b12a1BBB185DE4E2Dfb9126566bb12CD |
    // | CoFiXV2VaultForLP | 0xc5fe31d30bD8d4C495f53A52f6EC1357F7062B7D |
    // | CoFiXV2VaultForTrader | 0x0f90F07FF5D5D7D83a50C3F8B0a08939408d4ccc |
    // | CoFiXV2VaultForCNode | 0x2ee5b4C01725ff6068691Fcc23b44D8BE5685A0D |
    // | V2CNodeStakingRewards CNode | 0x97a1f539F795D28acaaAf98583401deB0E125a01 |
    // | CoFiXDAO | 0x98f9D8DcfBadb0CFD74c1969F7BB5ac777cFFD82 |

    //     ** rinkeby@20210727.js **
    // usdt: 0x2d750210c0b5343a0b79beff8F054C9add7d2411
    // hbtc: 0xaE73d363Cb4aC97734E07e48B01D0a1FF5D1190B
    // peth: 0x4D4B378eFbeb7eE15Aa498F3383C9949391557e0
    // pusd: 0x740ed84037E5d2F650b585759623EBC4de849021
    // usdc: 0xB64825a6bA80d65886b5123f5170ddffc935D9DE
    // nest: 0xE313F3f49B647fBEDDC5F2389Edb5c93CBf4EE25
    // nestPriceFacade: 0x40C3EB032f27fDa7AdcF1B753c75B84e27f26838

    //     ** rinkeby@20210728.js **
    // usdt: 0x2d750210c0b5343a0b79beff8F054C9add7d2411
    // hbtc: 0xaE73d363Cb4aC97734E07e48B01D0a1FF5D1190B
    // peth: 0x4D4B378eFbeb7eE15Aa498F3383C9949391557e0
    // pusd: 0x740ed84037E5d2F650b585759623EBC4de849021
    // usdc: 0xB64825a6bA80d65886b5123f5170ddffc935D9DE
    // nest: 0xE313F3f49B647fBEDDC5F2389Edb5c93CBf4EE25
    // nestPriceFacade: 0x40C3EB032f27fDa7AdcF1B753c75B84e27f26838
    // cnode: 0x91566410cC6E9F6579e4132909F597676D5C1FB2
    // cofi: 0x61EA050b28Ccca539F0faf79Fd26F6Df31b9f15B
    // cofixGovernance: 0x4A01418AFAfD5d7870130F1cA2967BaD09863539

    //     ** rinkeby@20210728.js **
    // usdt: 0x2d750210c0b5343a0b79beff8F054C9add7d2411
    // hbtc: 0xaE73d363Cb4aC97734E07e48B01D0a1FF5D1190B
    // peth: 0x4D4B378eFbeb7eE15Aa498F3383C9949391557e0
    // pusd: 0x740ed84037E5d2F650b585759623EBC4de849021
    // usdc: 0xB64825a6bA80d65886b5123f5170ddffc935D9DE
    // nest: 0xE313F3f49B647fBEDDC5F2389Edb5c93CBf4EE25
    // nestPriceFacade: 0x40C3EB032f27fDa7AdcF1B753c75B84e27f26838
    // cnode: 0x91566410cC6E9F6579e4132909F597676D5C1FB2
    // cofi: 0x61EA050b28Ccca539F0faf79Fd26F6Df31b9f15B
    // cofixGovernance: 0x4A01418AFAfD5d7870130F1cA2967BaD09863539
    // cofixDAO: 0x2720dF961723568062A96F9f5310d8ab408bfFfc
    // cofixRouter: 0x9f7997EFb0aF6f5e370dea99b1941D73330825C9

    //     ** rinkeby@20210728.js **
    // usdt: 0x2d750210c0b5343a0b79beff8F054C9add7d2411
    // hbtc: 0xaE73d363Cb4aC97734E07e48B01D0a1FF5D1190B
    // peth: 0x4D4B378eFbeb7eE15Aa498F3383C9949391557e0
    // pusd: 0x740ed84037E5d2F650b585759623EBC4de849021
    // usdc: 0xB64825a6bA80d65886b5123f5170ddffc935D9DE
    // nest: 0xE313F3f49B647fBEDDC5F2389Edb5c93CBf4EE25
    // nestPriceFacade: 0x40C3EB032f27fDa7AdcF1B753c75B84e27f26838
    // cnode: 0x91566410cC6E9F6579e4132909F597676D5C1FB2
    // cofi: 0x61EA050b28Ccca539F0faf79Fd26F6Df31b9f15B
    // cofixGovernance: 0x4A01418AFAfD5d7870130F1cA2967BaD09863539
    // cofixDAO: 0x2720dF961723568062A96F9f5310d8ab408bfFfc
    // cofixRouter: 0x9f7997EFb0aF6f5e370dea99b1941D73330825C9
    // cofixVaultForStaking: 0x11839c81beBBC82686b0052Cb6F03E9Ae58A9704
    // cofixController: 0x59c2EAF8FC22C10C2EB79Be3c23c2916BD0ec81e
    // proxyAdmin: 0x533b91f72564422c7f9a735d838f4171cB30e033
    // cofixControllerImpl: 0xB6B199A0925a398E02fE0C46f7a86c6B27eB57Ff
    // usdtPair: 0xf749fA2B6E75F9EfBa8427eA86036f38A7173F9C
    // hbtcPair: 0xB042c57997a561FB93C510BA1811927B78452EAF
    // nestPair: 0x6FAc11eE801713460B2b9Fe089f473c48756D45d
    // cofiPair: 0x45579827334583680c33ae9110C6a65806DB6EC7
    // ethAnchor: 0xD93F55F65316de63497163e4d2FD0390A1805c35
    // usdAnchor: 0xdCa0d07422691f286f5CE641FF4F40D5979BC0D7
    // xeth: 0xe884Cc2774f90065f07E79B7673dD93cC7Cee30C
    // xpeth: 0x142d684B614D42c2a93EB07C0d067c2db195Bb34
    // xusdt: 0x1eDBAFb57D9Ae6808F9746E2bEf0C491351B456F
    // xpusd: 0x98F718Db4fA72F584C9dcA958c1fa7f7665Fb9a7
    // xusdc: 0x738029DD7dB8872eA9f4FF72eC5f06c31DED0948
    // uni: 0x1f9840a85d5af5bf1d1762f925bdaddc4201f984
    // uniswapV3PoolAdapter-uni: 0xCF483FF2D14EFd67f2c78cfe3430488313191569
    // cofixSinglePool-nest: 0x503B77BB77182b5f2a19Bacc5285af0edC5126FF
    // cofixSinglePool-cofi: 0x4115F0e23AbDd94AEF944e5Aba1362b43d3d6638

    // 1. 部署依赖合约
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
    const cnode = await TestERC20.attach('0x91566410cC6E9F6579e4132909F597676D5C1FB2');
    console.log('cnode: ' + cnode.address);

    //const cofi = await CoFiToken.deploy();
    const cofi = await CoFiToken.attach('0x61EA050b28Ccca539F0faf79Fd26F6Df31b9f15B');
    console.log('cofi: ' + cofi.address);

    // 2. 部署结构合约
    //const cofixGovernance = await upgrades.deployProxy(CoFiXGovernance, ['0x0000000000000000000000000000000000000000'], { initializer: 'initialize' });
    const cofixGovernance = await CoFiXGovernance.attach('0x4A01418AFAfD5d7870130F1cA2967BaD09863539');
    console.log('cofixGovernance: ' + cofixGovernance.address);
    
    //const cofixDAO = await upgrades.deployProxy(CoFiXDAO, [cofixGovernance.address], { initializer: 'initialize' });
    const cofixDAO = await CoFiXDAO.attach('0x2720dF961723568062A96F9f5310d8ab408bfFfc');
    console.log('cofixDAO: ' + cofixDAO.address);
    
    //     ** rinkeby@20210728.js **
    // usdt: 0x2d750210c0b5343a0b79beff8F054C9add7d2411
    // hbtc: 0xaE73d363Cb4aC97734E07e48B01D0a1FF5D1190B
    // peth: 0x4D4B378eFbeb7eE15Aa498F3383C9949391557e0
    // pusd: 0x740ed84037E5d2F650b585759623EBC4de849021
    // usdc: 0xB64825a6bA80d65886b5123f5170ddffc935D9DE
    // nest: 0xE313F3f49B647fBEDDC5F2389Edb5c93CBf4EE25
    // nestPriceFacade: 0x40C3EB032f27fDa7AdcF1B753c75B84e27f26838
    // cnode: 0x91566410cC6E9F6579e4132909F597676D5C1FB2
    // cofi: 0x61EA050b28Ccca539F0faf79Fd26F6Df31b9f15B
    // cofixGovernance: 0x4A01418AFAfD5d7870130F1cA2967BaD09863539
    // cofixDAO: 0x2720dF961723568062A96F9f5310d8ab408bfFfc
    // cofixRouter: 0x9f7997EFb0aF6f5e370dea99b1941D73330825C9
    // cofixVaultForStaking: 0x11839c81beBBC82686b0052Cb6F03E9Ae58A9704
    // cofixController: 0x59c2EAF8FC22C10C2EB79Be3c23c2916BD0ec81e
    // proxyAdmin: 0x533b91f72564422c7f9a735d838f4171cB30e033
    // cofixControllerImpl: 0xB6B199A0925a398E02fE0C46f7a86c6B27eB57Ff
    // usdtPair: 0xf749fA2B6E75F9EfBa8427eA86036f38A7173F9C
    // hbtcPair: 0xB042c57997a561FB93C510BA1811927B78452EAF
    // nestPair: 0x6FAc11eE801713460B2b9Fe089f473c48756D45d
    // cofiPair: 0x45579827334583680c33ae9110C6a65806DB6EC7
    // ethAnchor: 0xD93F55F65316de63497163e4d2FD0390A1805c35
    // usdAnchor: 0xdCa0d07422691f286f5CE641FF4F40D5979BC0D7
    // xeth: 0xe884Cc2774f90065f07E79B7673dD93cC7Cee30C
    // xpeth: 0x142d684B614D42c2a93EB07C0d067c2db195Bb34
    // xusdt: 0x1eDBAFb57D9Ae6808F9746E2bEf0C491351B456F
    // xpusd: 0x98F718Db4fA72F584C9dcA958c1fa7f7665Fb9a7
    // xusdc: 0x738029DD7dB8872eA9f4FF72eC5f06c31DED0948

    //const cofixRouter = await upgrades.deployProxy(CoFiXRouter, [cofixGovernance.address], { initializer: 'initialize' });
    const cofixRouter = await CoFiXRouter.attach('0x9f7997EFb0aF6f5e370dea99b1941D73330825C9');
    console.log('cofixRouter: ' + cofixRouter.address);
        
    //const cofixVaultForStaking = await upgrades.deployProxy(CoFiXVaultForStaking, [cofixGovernance.address], { initializer: 'initialize' });
    const cofixVaultForStaking = await CoFiXVaultForStaking.attach('0x11839c81beBBC82686b0052Cb6F03E9Ae58A9704');
    console.log('cofixVaultForStaking: ' + cofixVaultForStaking.address);
    
    //const cofixController = await CoFiXController.deploy(nestPriceFacade.address);
    //let cofixController = await upgrades.deployProxy(CoFiXController, [nestPriceFacade.address], { initializer: 'initialize' });
    let cofixController = await CoFiXController.attach('0x59c2EAF8FC22C10C2EB79Be3c23c2916BD0ec81e');
    console.log('cofixController: ' + cofixController.address);
    const proxyAdmin = await ethers.getContractAt('IProxyAdmin', await cofixController.getAdmin());
    console.log('proxyAdmin: ' + proxyAdmin.address);
    const cofixControllerImpl = await proxyAdmin.getProxyImplementation(cofixController.address);
    console.log('cofixControllerImpl: ' + cofixControllerImpl);
    cofixController = await CoFiXController.attach(cofixControllerImpl);
    //await cofixController.initialize(nestPriceFacade.address);

    // 3. 部署资金池合约
    //const usdtPair = await upgrades.deployProxy(CoFiXPair, [cofixGovernance.address, 'XT-1', 'XToken-1', usdt.address, BigInt(1000000000), BigInt(2)], { initializer: 'init' });
    const usdtPair = await CoFiXPair.attach('0xf749fA2B6E75F9EfBa8427eA86036f38A7173F9C');
    console.log('usdtPair: ' + usdtPair.address);

    //const hbtcPair = await upgrades.deployProxy(CoFiXPair, [cofixGovernance.address, 'XT-2', 'XToken-2', hbtc.address, BigInt(20), BigInt(1)], { initializer: 'init' });
    const hbtcPair = await CoFiXPair.attach('0xB042c57997a561FB93C510BA1811927B78452EAF');
    console.log('hbtcPair: ' + hbtcPair.address);

    //const nestPair = await upgrades.deployProxy(CoFiXPair, [cofixGovernance.address, 'XT-3', 'XToken-3', nest.address, BigInt(1), BigInt(100000)], { initializer: 'init' });
    const nestPair = await CoFiXPair.attach('0x6FAc11eE801713460B2b9Fe089f473c48756D45d');
    console.log('nestPair: ' + nestPair.address);

    //const cofiPair = await upgrades.deployProxy(CoFiXPair, [cofixGovernance.address, 'XT-4', 'XToken-4', cofi.address, BigInt(1), BigInt(2000)], { initializer: 'init' });
    const cofiPair = await CoFiXPair.attach('0x45579827334583680c33ae9110C6a65806DB6EC7');
    console.log('cofiPair: ' + cofiPair.address);

    // 部署ETH锚定池
    // let ethAnchor = await upgrades.deployProxy(CoFiXAnchorPool, [
    //     cofixGovernance.address, 
    //     1, 
    //     [eth.address, peth.address],
    //     ['1000000000000000000', '1000000000000000000']
    // ], { initializer: 'init' });
    const ethAnchor = await CoFiXAnchorPool.attach('0xD93F55F65316de63497163e4d2FD0390A1805c35');
    console.log('ethAnchor: ' + ethAnchor.address);

    // 部署USD锚定池
    // let usdAnchor = await upgrades.deployProxy(CoFiXAnchorPool, [
    //     cofixGovernance.address, 
    //     2,
    //     [usdt.address, pusd.address, usdc.address],
    //     [1000000, '1000000000000000000', '1000000000000000000']
    // ], { initializer: 'init' });
    const usdAnchor = await CoFiXAnchorPool.attach('0xdCa0d07422691f286f5CE641FF4F40D5979BC0D7');
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
    // await cofixDAO.setTokenExchange(usdc.address, usdt.address, BigInt(1000000));
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

    // // 10. 开通挖矿权限
    // console.log('33. cofi.addMinter(cofixRouter.address)');
    // await cofi.addMinter(cofixRouter.address);
    // console.log('34. cofi.addMinter(cofixVaultForStaking.address)');
    // await cofi.addMinter(cofixVaultForStaking.address);
    
    console.log(await cofixGovernance.getBuiltinAddress());
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
