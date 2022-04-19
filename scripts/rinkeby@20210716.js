// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { ethers, upgrades } = require('hardhat');

exports.deploy = async function () {
    
    const eth = { address: '0x0000000000000000000000000000000000000000' };
    const TestERC20 = await ethers.getContractFactory('TestERC20');
    const CoFiToken = await ethers.getContractFactory('CoFiToken');
    const CoFiXGovernance = await ethers.getContractFactory('CoFiXGovernance');
    const CoFiXDAO = await ethers.getContractFactory('CoFiXDAO');
    const CoFiXRouter = await ethers.getContractFactory('CoFiXRouter');
    const CoFiXController = await ethers.getContractFactory('CoFiXController');
    const CoFiXVaultForStaking = await ethers.getContractFactory('CoFiXVaultForStaking');
    const CoFiXPair = await ethers.getContractFactory('CoFiXPair');
    const CoFiXAnchorPool = await ethers.getContractFactory('CoFiXAnchorPool');
    const CoFiXAnchorToken = await ethers.getContractFactory('CoFiXAnchorToken');
    const NestPriceFacade = await ethers.getContractFactory('NestPriceFacade');

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

    // ** Deploy: rinkeby@20210716 **
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
    // usdc: 0xFe027e6243Cd9b94772fA07c0b5fcD3D03D55c92
    // ethAnchor: 0xA5fF74B6BcF816AA3e13857a68c231DE6EEAF4eA
    // usdAnchor: 0x5Ed0d53442415BE2Ac4d1bA5e289721c4e3A8ce1
    // xeth: 0xEb780f8711A0D99DA20B05A5C5c903D8E1091834
    // xpeth: 0x6f67bF655225D32a1a0d9fbE25147259cBAA917c
    // xusdt: 0x38967b00B27629E0a944D8004b18b97A203d6d49
    // xpusd: 0x670aa8399aF49620AB542Dc1d71a3Cd1662a92fd
    // xusdc: 0xb6c01dF109bE84d29Ef570f8D2FBEa00413681F2

    console.log('** Deploy: rinkeby@20210716 **');
    
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
    
    // peth: 0xd5Dfe6355EeBE918a23d70f5399Bb08F8a1BD588
    // pusd: 0x01A8088947B1222a5dC5a13C45b845E0361EEFF7
    // usdc: 0xFe027e6243Cd9b94772fA07c0b5fcD3D03D55c92
    // ethAnchor: 0xA5fF74B6BcF816AA3e13857a68c231DE6EEAF4eA
    // usdAnchor: 0x5Ed0d53442415BE2Ac4d1bA5e289721c4e3A8ce1
    // xeth: 0xEb780f8711A0D99DA20B05A5C5c903D8E1091834
    // xpeth: 0x6f67bF655225D32a1a0d9fbE25147259cBAA917c
    // xusdt: 0x38967b00B27629E0a944D8004b18b97A203d6d49
    // xpusd: 0x670aa8399aF49620AB542Dc1d71a3Cd1662a92fd
    // xusdc: 0xb6c01dF109bE84d29Ef570f8D2FBEa00413681F2

    // Deploy PETH, WETH
    //let peth = await TestERC20.deploy('PETH', 'PETH', 18);
    let peth = await TestERC20.attach('0xd5Dfe6355EeBE918a23d70f5399Bb08F8a1BD588');
    console.log('peth: ' + peth.address);
    // let weth = await TestERC20.deploy('WETH', 'WETH', 18);
    // console.log('weth: ' + weth.address);
    // Deploy PUSD, USDC
    //let pusd = await TestERC20.deploy('PUSD', 'PUSD', 18);
    let pusd = await TestERC20.attach('0x01A8088947B1222a5dC5a13C45b845E0361EEFF7');
    console.log('pusd: ' + pusd.address);
    //let usdc = await TestERC20.deploy('USDC', 'USDC', 6);
    let usdc = await TestERC20.attach('0xFe027e6243Cd9b94772fA07c0b5fcD3D03D55c92');
    console.log('usdc: ' + usdc.address);
    // Deploy eth anchor pool
    // let ethAnchor = await upgrades.deployProxy(CoFiXAnchorPool, [
    //     cofixGovernance.address, 
    //     0, 
    //     [eth.address, peth.address],
    //     ['1000000000000000000', '1000000000000000000']
    // ], { initializer: 'init' });
    let ethAnchor = await CoFiXAnchorPool.attach('0xA5fF74B6BcF816AA3e13857a68c231DE6EEAF4eA');
    console.log('ethAnchor: ' + ethAnchor.address);
    // Deploy usd anchor pool
    // let usdAnchor = await upgrades.deployProxy(CoFiXAnchorPool, [
    //     cofixGovernance.address, 
    //     1,
    //     [usdt.address, pusd.address, usdc.address],
    //     ['1000000', '1000000000000000000', '1000000000000000000']
    // ], { initializer: 'init' });
    let usdAnchor = await CoFiXAnchorPool.attach('0x5Ed0d53442415BE2Ac4d1bA5e289721c4e3A8ce1');
    console.log('usdAnchor: ' + usdAnchor.address);

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
    let xusdc = await CoFiXAnchorToken.attach(await usdAnchor.getXToken(usdc.address));
    console.log('xusdc: ' + xusdc.address);

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
        usdc: usdc,

        xeth: xeth,
        xpeth: xpeth,
        //xweth: xweth,
        xusdt: xusdt,
        xpusd: xpusd,
        xusdc: xusdc,

        usdtPair: usdtPair,
        nestPair: nestPair,
        cofiPair: cofiPair,
        ethAnchor: ethAnchor,
        usdAnchor: usdAnchor
    };
    
    //console.log(contracts);
    console.log('** Deployed **');
    return contracts;
}
