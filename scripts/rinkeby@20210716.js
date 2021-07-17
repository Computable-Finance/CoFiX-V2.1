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

    // ***** .deploy.rinkeby@20210716.js *****
    // nest: 0xE313F3f49B647fBEDDC5F2389Edb5c93CBf4EE25
    // usdt: 0x20125a7256EFafd0d4Eec24048E08C5045BC5900
    // hbtc: 0xaE73d363Cb4aC97734E07e48B01D0a1FF5D1190B
    // nestGovernance: 0xa52936bD3848567Fbe4bA24De3370ABF419fC1f7
    // nestLedger: 0x005103e352f86e4C32a3CE4B684fe211eB123210
    // nTokenController: 0xb75Fd1a678dAFE00cEafc8d9e9B1ecf75cd6afC5
    // nestVote: 0xF9539C7151fC9E26362170FADe13a4e4c250D720
    // nestMining: 0x50E911480a01B9cF4826a87BD7591db25Ac0727F
    // ntokenMining: 0xb984cCe9fdA423c5A18DFDE4a7bCdfC150DC1012
    // nestPriceFacade: 0x40C3EB032f27fDa7AdcF1B753c75B84e27f26838
    // nestRedeeming: 0xeD859B5f5A2e19bC36C14096DC05Fe9192CeFa31
    // nnIncome: 0x82307CbA43f05D632aB835AFfD30ED0073dC4bd9
    // nhbtc: 0xe6bf6Bd50b07D577a22FEA5b1A205Cf21642b198
    // nn: 0x52Ab1592d71E20167EB657646e86ae5FC04e9E01

    // ** 开始部署合约 rinkeby@20210716 **
    // nestPriceFacade: 0x40C3EB032f27fDa7AdcF1B753c75B84e27f26838
    // cnode: 0xa818c471Ab162a1d7669Ab04b023Ebac38DDCA64
    // usdt: 0x20125a7256EFafd0d4Eec24048E08C5045BC5900
    // nest: 0xE313F3f49B647fBEDDC5F2389Edb5c93CBf4EE25
    // cofi: 0xBd98Ec485d7f54979FC0Ef19365ABFFC63099755
    // cofixGovernance: 0xAc12D0CbA1E1a2ffb34326115c2A9926435Dd694
    // usdtPair: 0x7756f374E19E1528454B5291282D6C9e33eCBC69
    // nestPair: 0xEC38914c82969716C5E271a63087D365B0E259b2
    // cofiPair: 0x47380B7cd1a7c482Bc2416FB0171AD2A10c8258A
    // cofixDAO: 0xCD0E336D483511840D3002E4aE1518bd3681cdaC
    // cofixRouter: 0xFd759970c8B4A6EfE5525EA9A03732Ef04F1C5F4
    // cofixController: 0xEf1673bda89C0c1827680467BdfB6d22F18F8498
    // cofixVaultForStaking: 0x974E819Fa74683c3dAc7C4bc4041d6B2E042e1D7
    // peth: 0xd5Dfe6355EeBE918a23d70f5399Bb08F8a1BD588
    // pusd: 0x01A8088947B1222a5dC5a13C45b845E0361EEFF7
    // dai: 0xFe027e6243Cd9b94772fA07c0b5fcD3D03D55c92
    // ethAnchor: 0xA5fF74B6BcF816AA3e13857a68c231DE6EEAF4eA
    // usdAnchor: 0x5Ed0d53442415BE2Ac4d1bA5e289721c4e3A8ce1
    // xeth: 0xEb780f8711A0D99DA20B05A5C5c903D8E1091834
    // xpeth: 0x6f67bF655225D32a1a0d9fbE25147259cBAA917c
    // xusdt: 0x38967b00B27629E0a944D8004b18b97A203d6d49
    // xpusd: 0x670aa8399aF49620AB542Dc1d71a3Cd1662a92fd
    // xdai: 0xb6c01dF109bE84d29Ef570f8D2FBEa00413681F2

    console.log('** 开始部署合约 rinkeby@20210716 **');
    
    //const nestPriceFacade = await NestPriceFacade.deploy();
    const nestPriceFacade = await NestPriceFacade.attach('0x40C3EB032f27fDa7AdcF1B753c75B84e27f26838');
    console.log('nestPriceFacade: ' + nestPriceFacade.address);
    
    //let cnode = await TestERC20.deploy('CNode', 'CNode', 0);
    const cnode = await TestERC20.attach('0xa818c471Ab162a1d7669Ab04b023Ebac38DDCA64');
    console.log('cnode: ' + cnode.address);
    
    //const usdt = await TestERC20.deploy('USDT', 'USDT', 6);
    const usdt = await TestERC20.attach('0x20125a7256EFafd0d4Eec24048E08C5045BC5900');
    console.log('usdt: ' + usdt.address);

    //const nest = await TestERC20.deploy('NEST', 'NEST', 18);
    const nest = await TestERC20.attach('0xE313F3f49B647fBEDDC5F2389Edb5c93CBf4EE25');
    console.log('nest: ' + nest.address);
    
    //const cofi = await CoFiToken.deploy();
    const cofi = await CoFiToken.attach('0xBd98Ec485d7f54979FC0Ef19365ABFFC63099755');
    console.log('cofi: ' + cofi.address);

    //const cofixGovernance = await upgrades.deployProxy(CoFiXGovernance, ['0x0000000000000000000000000000000000000000'], { initializer: 'initialize' });
    const cofixGovernance = await CoFiXGovernance.attach('0xAc12D0CbA1E1a2ffb34326115c2A9926435Dd694');
    console.log('cofixGovernance: ' + cofixGovernance.address);
    
    //const usdtPair = await upgrades.deployProxy(CoFiXPair, [cofixGovernance.address, 'XT-1', 'XToken-1', usdt.address, BigInt('1000000000'), BigInt('3')], { initializer: 'init' });
    const usdtPair = await CoFiXPair.attach('0x7756f374E19E1528454B5291282D6C9e33eCBC69');
    console.log('usdtPair: ' + usdtPair.address);
    //cnode = usdtPair;

    //const nestPair = await upgrades.deployProxy(CoFiXPair, [cofixGovernance.address, 'XT-2', 'XToken-2', nest.address, BigInt('1'), BigInt('20000')], { initializer: 'init' });
    const nestPair = await CoFiXPair.attach('0xEC38914c82969716C5E271a63087D365B0E259b2');
    console.log('nestPair: ' + nestPair.address);

    //const cofiPair = await upgrades.deployProxy(CoFiXPair, [cofixGovernance.address, 'XT-3', 'XToken-3', nest.address, BigInt('1'), BigInt('1000')], { initializer: 'init' });
    const cofiPair = await CoFiXPair.attach('0x47380B7cd1a7c482Bc2416FB0171AD2A10c8258A');
    console.log('cofiPair: ' + cofiPair.address);

    //const cofixDAO = await upgrades.deployProxy(CoFiXDAO, [cofixGovernance.address], { initializer: 'initialize' });
    const cofixDAO = await CoFiXDAO.attach('0xCD0E336D483511840D3002E4aE1518bd3681cdaC');
    console.log('cofixDAO: ' + cofixDAO.address);
    
    //const cofixRouter = await upgrades.deployProxy(CoFiXRouter, [cofixGovernance.address], { initializer: 'initialize' });
    const cofixRouter = await CoFiXRouter.attach('0xFd759970c8B4A6EfE5525EA9A03732Ef04F1C5F4');
    console.log('cofixRouter: ' + cofixRouter.address);
    
    //const cofixController = await CoFiXController.deploy(nestPriceFacade.address);
    const cofixController = await CoFiXController.attach('0xEf1673bda89C0c1827680467BdfB6d22F18F8498');
    console.log('cofixController: ' + cofixController.address);
    
    //const cofixVaultForStaking = await upgrades.deployProxy(CoFiXVaultForStaking, [cofixGovernance.address], { initializer: 'initialize' });
    const cofixVaultForStaking = await CoFiXVaultForStaking.attach('0x974E819Fa74683c3dAc7C4bc4041d6B2E042e1D7');
    console.log('cofixVaultForStaking: ' + cofixVaultForStaking.address);
    
    // // console.log('1. cofixGovernance.initialize');
    // // await cofixGovernance.initialize(cofixGovernance.address);
    // //console.log('2. cofixRouter.initialize');
    // //await cofixRouter.initialize(cofixGovernance.address);
    // //console.log('3. cofixDAO.initialize');
    // //await cofixDAO.initialize(cofixGovernance.address);
    // // console.log('4. cofixVaultForStaking.initialize');
    // // await cofixVaultForStaking.initialize(cofixGovernance.address);
    // //console.log('5. usdtPair.initialize');
    // //await usdtPair.init(cofixGovernance.address, 'XT-1', 'XToken-1', usdt.address, BigInt('1000000000'), BigInt('3'));
    // //console.log('6. nestPair.initialize');
    // //await nestPair.init(cofixGovernance.address, 'XT-2', 'XToken-2', nest.address, BigInt('1'), BigInt('20000'));

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
    // console.log('12. nestPair.update');
    // await nestPair.update(cofixGovernance.address);
    // console.log('12.1. cofiPair.update');
    // await cofiPair.update(cofixGovernance.address);

    // console.log('13. cofixVaultForStaking.setConfig');
    // await cofixVaultForStaking.setConfig({
    //     cofiRate: '200000000000000000'
    // });
    // console.log('14. cofixVaultForStaking.batchSetPoolWeight(cnode.address)');
    // await cofixVaultForStaking.batchSetPoolWeight([cnode.address], [100000]);
    // console.log('15. cofixVaultForStaking.batchSetPoolWeight(usdtPair.address)');
    // await cofixVaultForStaking.batchSetPoolWeight([usdtPair.address], [100000]);
    // console.log('16. cofixVaultForStaking.batchSetPoolWeight(nestPair.address)');
    // await cofixVaultForStaking.batchSetPoolWeight([nestPair.address], [20000]);
    // console.log('17. cofixVaultForStaking.batchSetPoolWeight(cofiPair.address)');
    // await cofixVaultForStaking.batchSetPoolWeight([cofiPair.address], [20000]);

    // // console.log('17. cofixRouter.setConfig');
    // // await cofixRouter.setConfig({
    // //     cnodeRewardRate: 1000
    // // });
    // // console.log('18. cofixRouter.addPair(usdt.address, usdtPair.address)');
    // // await cofixRouter.registerPair(eth.address, usdt.address, usdtPair.address);
    // // console.log('19. cofixRouter.addPair(nest.address, nestPair.address)');
    // // await cofixRouter.registerPair(eth.address, nest.address, nestPair.address);
    // // console.log('19.1. cofixRouter.addPair(cofi.address, cofitPair.address)');
    // // await cofixRouter.registerPair(eth.address, cofi.address, cofiPair.address);
    // console.log('20. cofi.addMinter(cofixRouter.address)');
    // await cofi.addMinter(cofixRouter.address);
    // console.log('21. cofi.addMinter(cofixVaultForStaking.addres)');
    // await cofi.addMinter(cofixVaultForStaking.address);

    // await cofixRouter.registerRouterPath(nest.address, usdt.address, [
    //     nest.address, 
    //     eth.address, 
    //     usdt.address
    // ]);

    // peth: 0xd5Dfe6355EeBE918a23d70f5399Bb08F8a1BD588
    // pusd: 0x01A8088947B1222a5dC5a13C45b845E0361EEFF7
    // dai: 0xFe027e6243Cd9b94772fA07c0b5fcD3D03D55c92
    // ethAnchor: 0xA5fF74B6BcF816AA3e13857a68c231DE6EEAF4eA
    // usdAnchor: 0x5Ed0d53442415BE2Ac4d1bA5e289721c4e3A8ce1
    // xeth: 0xEb780f8711A0D99DA20B05A5C5c903D8E1091834
    // xpeth: 0x6f67bF655225D32a1a0d9fbE25147259cBAA917c
    // xusdt: 0x38967b00B27629E0a944D8004b18b97A203d6d49
    // xpusd: 0x670aa8399aF49620AB542Dc1d71a3Cd1662a92fd
    // xdai: 0xb6c01dF109bE84d29Ef570f8D2FBEa00413681F2

    // 部署PETH, WETH
    //let peth = await TestERC20.deploy('PETH', 'PETH', 18);
    let peth = await TestERC20.attach('0xd5Dfe6355EeBE918a23d70f5399Bb08F8a1BD588');
    console.log('peth: ' + peth.address);
    // let weth = await TestERC20.deploy('WETH', 'WETH', 18);
    // console.log('weth: ' + weth.address);
    // 部署PUSD, DAI
    //let pusd = await TestERC20.deploy('PUSD', 'PUSD', 18);
    let pusd = await TestERC20.attach('0x01A8088947B1222a5dC5a13C45b845E0361EEFF7');
    console.log('pusd: ' + pusd.address);
    //let dai = await TestERC20.deploy('DAI', 'DAI', 18);
    let dai = await TestERC20.attach('0xFe027e6243Cd9b94772fA07c0b5fcD3D03D55c92');
    console.log('dai: ' + dai.address);
    // 部署ETH锚定池
    // let ethAnchor = await upgrades.deployProxy(CoFiXAnchorPool, [
    //     cofixGovernance.address, 
    //     0, 
    //     [eth.address, peth.address],
    //     ['1000000000000000000', '1000000000000000000']
    // ], { initializer: 'init' });
    let ethAnchor = await CoFiXAnchorPool.attach('0xA5fF74B6BcF816AA3e13857a68c231DE6EEAF4eA');
    console.log('ethAnchor: ' + ethAnchor.address);
    // 部署USD锚定池
    // let usdAnchor = await upgrades.deployProxy(CoFiXAnchorPool, [
    //     cofixGovernance.address, 
    //     1,
    //     [usdt.address, pusd.address, dai.address],
    //     ['1000000', '1000000000000000000', '1000000000000000000']
    // ], { initializer: 'init' });
    let usdAnchor = await CoFiXAnchorPool.attach('0x5Ed0d53442415BE2Ac4d1bA5e289721c4e3A8ce1');
    console.log('usdAnchor: ' + usdAnchor.address);

    // // 注册usdt和nest交易对
    // console.log('22. registerPair(eth.address, usdt.address, usdtPair.address)');
    // await cofixRouter.registerPair(eth.address, usdt.address, usdtPair.address);
    // console.log('23. registerPair(eth.address, nest.address, nestPair.address)');
    // await cofixRouter.registerPair(eth.address, nest.address, nestPair.address);
    // console.log('23.1. registerPair(eth.address, cofi.address, cofiPair.address)');
    // await cofixRouter.registerPair(eth.address, cofi.address, cofiPair.address);

    // // 注册ETH锚定池
    // console.log('24. registerPair(eth.address, peth.address, ethAnchor.address)');
    // await cofixRouter.registerPair(eth.address, peth.address, ethAnchor.address);
    // // console.log('25. registerPair(eth.address, weth.address, ethAnchor.address)');
    // // await cofixRouter.registerPair(eth.address, weth.address, ethAnchor.address);
    // // console.log('26. registerPair(peth.address, weth.address, ethAnchor.address)');
    // // await cofixRouter.registerPair(peth.address, weth.address, ethAnchor.address);
    // // 注册USD锚定池
    // console.log('27. registerPair(usdt.address, pusd.address, usdAnchor.address)');
    // await cofixRouter.registerPair(usdt.address, pusd.address, usdAnchor.address);
    // console.log('28. registerPair(usdt.address, dai.address, usdAnchor.address)');
    // await cofixRouter.registerPair(usdt.address, dai.address, usdAnchor.address);
    // console.log('29. registerPair(pusd.address, dai.address, usdAnchor.address)');
    // await cofixRouter.registerPair(pusd.address, dai.address, usdAnchor.address);

    // // 注册路由路径
    // console.log('30. registerRouterPath(usdt.address, nest.address, [usdt.address, eth.address, nest.address])');
    // await cofixRouter.registerRouterPath(usdt.address, nest.address, [usdt.address, eth.address, nest.address]);
    // console.log('31. registerRouterPath(usdt.address, peth.address, [usdt.address, eth.address, peth.address])');
    // await cofixRouter.registerRouterPath(usdt.address, peth.address, [usdt.address, eth.address, peth.address]);
    // // console.log('32. registerRouterPath(usdt.address, weth.address, [usdt.address, eth.address, weth.address])');
    // // await cofixRouter.registerRouterPath(usdt.address, weth.address, [usdt.address, eth.address, weth.address]);
    
    // // eth, nest, usdt, pusd, dai, peth, cofi
    // console.log('33. registerRouterPath(pusd.address, eth.address, [pusd.address, usdt.address, eth.address])');
    // await cofixRouter.registerRouterPath(pusd.address, eth.address, [pusd.address, usdt.address, eth.address]);
    // console.log('34. registerRouterPath(pusd.address, peth.address, [pusd.address, usdt.address, eth.address, peth.address])');
    // await cofixRouter.registerRouterPath(pusd.address, peth.address, [pusd.address, usdt.address, eth.address, peth.address]);
    // // console.log('35. registerRouterPath(pusd.address, weth.address, [pusd.address, usdt.address, eth.address, weth.address])');
    // // await cofixRouter.registerRouterPath(pusd.address, weth.address, [pusd.address, usdt.address, eth.address, weth.address]);
    // console.log('36. registerRouterPath(pusd.address, nest.address, [pusd.address, usdt.address, eth.address, nest.address])');
    // await cofixRouter.registerRouterPath(pusd.address, nest.address, [pusd.address, usdt.address, eth.address, nest.address]);

    // console.log('37. registerRouterPath(dai.address, eth.address, [dai.address, usdt.address, eth.address])');
    // await cofixRouter.registerRouterPath(dai.address, eth.address, [dai.address, usdt.address, eth.address]);
    // console.log('38. registerRouterPath(dai.address, peth.address, [dai.address, usdt.address, eth.address, peth.address])');
    // await cofixRouter.registerRouterPath(dai.address, peth.address, [dai.address, usdt.address, eth.address, peth.address]);
    // // console.log('39. registerRouterPath(dai.address, weth.address, [dai.address, usdt.address, eth.address, weth.address])');
    // // await cofixRouter.registerRouterPath(dai.address, weth.address, [dai.address, usdt.address, eth.address, weth.address]);
    // console.log('40. registerRouterPath(dai.address, nest.address, [dai.address, usdt.address, eth.address, nest.address])');
    // await cofixRouter.registerRouterPath(dai.address, nest.address, [dai.address, usdt.address, eth.address, nest.address]);

    // console.log('41. registerRouterPath(peth.address, nest.address, [peth.address, eth.address, nest.address])');
    // await cofixRouter.registerRouterPath(peth.address, nest.address, [peth.address, eth.address, nest.address]);
    // // console.log('42. registerRouterPath(weth.address, nest.address, [weth.address, eth.address, nest.address])');
    // // await cofixRouter.registerRouterPath(weth.address, nest.address, [weth.address, eth.address, nest.address]);

    // console.log('42. registerRouterPath(cofi.address, nest.address, [cofi.address, eth.address, nest.address])');
    // await cofixRouter.registerRouterPath(cofi.address, nest.address, [cofi.address, eth.address, nest.address]);
    // console.log('43. registerRouterPath(cofi.address, usdt.address, [cofi.address, eth.address, usdt.address])');
    // await cofixRouter.registerRouterPath(cofi.address, usdt.address, [cofi.address, eth.address, usdt.address]);
    // console.log('44. registerRouterPath(cofi.address, pusd.address, [cofi.address, eth.address, usdt.address, pusd.address])');
    // await cofixRouter.registerRouterPath(cofi.address, pusd.address, [cofi.address, eth.address, usdt.address, pusd.address]);
    // console.log('45. registerRouterPath(cofi.address, dai.address, [cofi.address, eth.address, usdt.address, dai.address])');
    // await cofixRouter.registerRouterPath(cofi.address, dai.address, [cofi.address, eth.address, usdt.address, dai.address]);
    // console.log('46. registerRouterPath(cofi.address, peth.address, [cofi.address, eth.address, peth.address])');
    // await cofixRouter.registerRouterPath(cofi.address, peth.address, [cofi.address, eth.address, peth.address]);

    // // console.log('43. ethAnchor.init(cofixGovernance.address)');
    // // await ethAnchor.init(cofixGovernance.address, 0, 
    // //     [eth.address, peth.address, weth.address],
    // //     ['1000000000000000000', '1000000000000000000', '1000000000000000000']
    // // );
    // // console.log('44. usdAnchor.init(cofixGovernance.address)');
    // // await usdAnchor.init(cofixGovernance.address, 1,
    // //     [usdt.address, pusd.address, dai.address],
    // //     ['1000000', '1000000000000000000', '1000000000000000000']
    // // );
    // console.log('45. ethAnchor.update(cofixGovernance.address)');
    // await ethAnchor.update(cofixGovernance.address);
    // console.log('46. usdAnchor.update(cofixGovernance.address)');
    // await usdAnchor.update(cofixGovernance.address);

    let xeth = await CoFiXAnchorToken.attach(await ethAnchor.getXToken(eth.address));
    console.log('xeth: ' + xeth.address);
    let xpeth = await CoFiXAnchorToken.attach(await ethAnchor.getXToken(peth.address));
    console.log('xpeth: ' + xpeth.address);
    // let xweth = await CoFiXAnchorToken.attach(await ethAnchor.getXToken(weth.address));
    // console.log('xweth: ' + xweth.address);

    let xusdt = await CoFiXAnchorToken.attach(await usdAnchor.getXToken(usdt.address));
    console.log('xusdt: ' + xusdt.address);
    let xpusd = await CoFiXAnchorToken.attach(await usdAnchor.getXToken(pusd.address));
    console.log('xpusd: ' + xpusd.address);
    let xdai = await CoFiXAnchorToken.attach(await usdAnchor.getXToken(dai.address));
    console.log('xdai: ' + xdai.address);

    // console.log('47. cofixVaultForStaking.batchSetPoolWeight(xeth.address, 20000)');
    // await cofixVaultForStaking.batchSetPoolWeight([xeth.address], [20000]);
    // console.log('48. cofixVaultForStaking.batchSetPoolWeight(xpeth.address, 20000)');
    // await cofixVaultForStaking.batchSetPoolWeight([xpeth.address], [20000]);
    // // console.log('49. cofixVaultForStaking.batchSetPoolWeight(xweth.address, 20000)');
    // // await cofixVaultForStaking.batchSetPoolWeight([xweth.address], [20000]);

    // console.log('50. cofixVaultForStaking.batchSetPoolWeight(xusdt.address, 20000)');
    // await cofixVaultForStaking.batchSetPoolWeight([xusdt.address], [20000]);
    // console.log('51. cofixVaultForStaking.batchSetPoolWeight(xpusd.address, 20000)');
    // await cofixVaultForStaking.batchSetPoolWeight([xpusd.address], [20000]);
    // console.log('52. cofixVaultForStaking.batchSetPoolWeight(xdai.address, 20000)');
    // await cofixVaultForStaking.batchSetPoolWeight([xdai.address], [20000]);

    // console.log('53. setConfig');
    // await usdtPair.setConfig(20, 1, 1000);
    // await nestPair.setConfig(20, 100, 1000);
    // await cofiPair.setConfig(20, 100, 1000);
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
    // await cofixDAO.setTokenExchange(dai.address, usdt.address, BigInt('1000000'));

    // await cofixDAO.setTokenExchange(eth.address, eth.address, BigInt('1000000000000000000'));
    // await cofixDAO.setTokenExchange(peth.address, eth.address, BigInt('1000000000000000000'));
    // //await cofixDAO.setTokenExchange(weth.address, eth.address, BigInt('1000000000000000000'));

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
        //weth: weth,
        pusd: pusd,
        dai: dai,

        xeth: xeth,
        xpeth: xpeth,
        //xweth: xweth,
        xusdt: xusdt,
        xpusd: xpusd,
        xdai: xdai,

        usdtPair: usdtPair,
        nestPair: nestPair,
        cofiPair: cofiPair,
        ethAnchor: ethAnchor,
        usdAnchor: usdAnchor
    };
    
    //console.log(contracts);
    console.log('** 合约部署完成 **');
    return contracts;
}
