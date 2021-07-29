// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { ethers } = require('hardhat');

exports.deploy = async function () {
    
    if (network.name != 'rinkeby') {
        console.log('当前不是rinkeby网络，退出');
        return;
    }
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

    // cnode: 0x5F22b973c29d739a12a0d20CEf99fa10b3A558df
    // usdt: 0x34deF4DF57ED33eDbE5d04bC49623659a553404e
    // nest: 0x8B4F5e0a3727877ff0850De5c9C1e54d0B7a85B4
    // cofi: 0x309291F40D714304A490F9A6E3A82F51Ae94962F
    // usdtPair: 0xf0ad5176dc1864962874Fd3817A835f8142BEa80
    // nestPair: 0xeDE17c63CA92608eD8864A7ef730994C80c27517
    // cofixGovernance: 0xb485aefBc9726d723EcDa8f3764Ab0a25144f3da
    // cofixDAO: 0x9338C665A487714143B079b36Bb4446bC06aeBd8
    // cofixRouter: 0xfCf2FF43915E655029517735846a22d245F707C7
    // cofixController: 0xE6C743CF3ffc2126cFdc3b3D802235981F3d9227
    // cofixVaultForStaking: 0x8d5c87F6ec179Ab29c8698001B5ec9e372281EA3
    // usdt: 0x34deF4DF57ED33eDbE5d04bC49623659a553404e
    // peth: 0x3FEf64736355F71981bcACB0Cc635474aDef3ad6
    // weth: 0x952Aba2A2F467AEE76fAE49A17C88e52FFa10C2a
    // pusd: 0xe6CdD2c0F48dCfaB1E4a8bcBb4e2001F671fe0e2
    // usdc: 0x46A7783AcA0b65073Ba51e52B73f252A261a909d
    // ethAnchor: 0xb57009B96FdD4863ef5D446Cd2E70FCF7747B606
    // usdAnchor: 0x71dd3d064b2d5975281A2992e3fC59467d936B92
    // xeth: 0x95C67FE9D28585e6ce468832149faf2392863Dc5
    // xpeth: 0x6620B963d98f7090E333608DfB1CC94979AC7586
    // xweth: 0x7A7F4122CF4d86eDA89d36d33EC9EB5c3fc43176
    // xusdt: 0x702F25CaC493F61584F00Db28b1095a6FFd5e023
    // xpusd: 0x4Eae4727BF3164cffdC2185F30A708CfdC6C20D2
    // xusdc: 0x802615556bE65f05C587C548eDF622726Bce7a63

    console.log('** 开始部署合约 rinkeby@20210628.js **');
    
    //let cnode = await TestERC20.deploy('CNode', 'CNode', 0);
    const cnode = await TestERC20.attach('0x5F22b973c29d739a12a0d20CEf99fa10b3A558df');
    console.log('cnode: ' + cnode.address);
    
    //const usdt = await TestERC20.deploy('USDT', 'USDT', 6);
    const usdt = await TestERC20.attach('0x34deF4DF57ED33eDbE5d04bC49623659a553404e');
    console.log('usdt: ' + usdt.address);

    //const nest = await TestERC20.deploy('NEST', 'NEST', 18);
    const nest = await TestERC20.attach('0x8B4F5e0a3727877ff0850De5c9C1e54d0B7a85B4');
    console.log('nest: ' + nest.address);
    
    //const cofi = await CoFiToken.deploy();
    const cofi = await CoFiToken.attach('0x309291F40D714304A490F9A6E3A82F51Ae94962F');
    console.log('cofi: ' + cofi.address);

    //const usdtPair = await CoFiXPair.deploy('XT-1', 'XToken-1', usdt.address, BigInt('1000000000'), BigInt('3'));
    const usdtPair = await CoFiXPair.attach('0xf0ad5176dc1864962874Fd3817A835f8142BEa80');
    console.log('usdtPair: ' + usdtPair.address);
    //cnode = usdtPair;

    //const nestPair = await CoFiXPair.deploy('XT-2', 'XToken-2', nest.address, BigInt('1'), BigInt('20000'));
    const nestPair = await CoFiXPair.attach('0xeDE17c63CA92608eD8864A7ef730994C80c27517');
    console.log('nestPair: ' + nestPair.address);
    
    //const cofixGovernance = await CoFiXGovernance.deploy();
    const cofixGovernance = await CoFiXGovernance.attach('0xb485aefBc9726d723EcDa8f3764Ab0a25144f3da');
    console.log('cofixGovernance: ' + cofixGovernance.address);
    
    //const cofixDAO = await CoFiXDAO.deploy();
    const cofixDAO = await CoFiXDAO.attach('0x9338C665A487714143B079b36Bb4446bC06aeBd8');
    console.log('cofixDAO: ' + cofixDAO.address);
    
    //const cofixRouter = await CoFiXRouter.deploy();
    const cofixRouter = await CoFiXRouter.attach('0xfCf2FF43915E655029517735846a22d245F707C7');
    console.log('cofixRouter: ' + cofixRouter.address);
    
    //const cofixController = await CoFiXController.deploy();
    const cofixController = await CoFiXController.attach('0xE6C743CF3ffc2126cFdc3b3D802235981F3d9227');
    console.log('cofixController: ' + cofixController.address);
    
    //const cofixVaultForStaking = await CoFiXVaultForStaking.deploy();
    const cofixVaultForStaking = await CoFiXVaultForStaking.attach('0x8d5c87F6ec179Ab29c8698001B5ec9e372281EA3');
    console.log('cofixVaultForStaking: ' + cofixVaultForStaking.address);
    
    // console.log('cofixGovernance.initialize');
    // await cofixGovernance.initialize(eth.address);
    // console.log('cofixRouter.initialize');
    // await cofixRouter.initialize(cofixGovernance.address);
    // console.log('cofixDAO.initialize');
    // await cofixDAO.initialize(cofixGovernance.address);
    // console.log('cofixVaultForStaking.initialize');
    // await cofixVaultForStaking.initialize(cofixGovernance.address);
    // console.log('usdtPair.initialize');
    // await usdtPair.initialize(cofixGovernance.address);
    // await nestPair.initialize(cofixGovernance.address);

    // console.log('cofixGovernance.setBuiltinAddress');
    // await cofixGovernance.setBuiltinAddress(
    //     cofi.address,
    //     cnode.address,
    //     cofixDAO.address,
    //     cofixRouter.address,
    //     cofixController.address,
    //     cofixVaultForStaking.address
    // );
    
    // console.log('cofixRouter.update');
    // await cofixRouter.update(cofixGovernance.address);
    // console.log('cofixDAO.update');
    // await cofixDAO.update(cofixGovernance.address);
    // console.log('cofixVaultForStaking.update');
    // await cofixVaultForStaking.update(cofixGovernance.address);
    // console.log('usdtPair.update');
    // await usdtPair.update(cofixGovernance.address);
    // await nestPair.update(cofixGovernance.address);

    // console.log('cofixVaultForStaking.setConfig');
    // await cofixVaultForStaking.setConfig({
    //     cofiUnit: '10000000000000000'
    // });
    // console.log('cofixVaultForStaking.batchSetPoolWeight');
    // await cofixVaultForStaking.batchSetPoolWeight([usdtPair.address], [100000]);
    // await cofixVaultForStaking.batchSetPoolWeight([nestPair.address], [20000]);
    // await cofixVaultForStaking.batchSetPoolWeight([cnode.address], [100000]);

    // console.log('cofixRouter.setConfig');
    // await cofixRouter.setConfig({
    //     cnodeRewardRate: 1000
    // });
    // console.log('cofixRouter.addPair');
    // await cofixRouter.addPair(usdt.address, usdtPair.address);
    // await cofixRouter.addPair(nest.address, nestPair.address);
    // console.log('cofi.addMinter');
    // await cofi.addMinter(cofixRouter.address);
    // console.log('cofi.addMinter');
    // await cofi.addMinter(cofixVaultForStaking.address);
    // console.log('usdt: ' + usdt.address);

    // await cofixRouter.registerRouterPath(nest.address, usdt.address, [
    //     nest.address, 
    //     eth.address, 
    //     usdt.address
    // ]);

    // peth: 0x3FEf64736355F71981bcACB0Cc635474aDef3ad6
    // weth: 0x952Aba2A2F467AEE76fAE49A17C88e52FFa10C2a
    // pusd: 0xe6CdD2c0F48dCfaB1E4a8bcBb4e2001F671fe0e2
    // usdc: 0x46A7783AcA0b65073Ba51e52B73f252A261a909d
    // ethAnchor: 0xb57009B96FdD4863ef5D446Cd2E70FCF7747B606
    // usdAnchor: 0x71dd3d064b2d5975281A2992e3fC59467d936B92

    // 部署PETH, WETH
    //let peth = await TestERC20.deploy('PETH', 'PETH', 18);
    let peth = await TestERC20.attach('0x3FEf64736355F71981bcACB0Cc635474aDef3ad6');
    console.log('peth: ' + peth.address);
    //let weth = await TestERC20.deploy('WETH', 'WETH', 18);
    let weth = await TestERC20.attach('0x952Aba2A2F467AEE76fAE49A17C88e52FFa10C2a');
    console.log('weth: ' + weth.address);
    // 部署PUSD, USDC
    //let pusd = await TestERC20.deploy('PUSD', 'PUSD', 18);
    let pusd = await TestERC20.attach('0xe6CdD2c0F48dCfaB1E4a8bcBb4e2001F671fe0e2');
    console.log('pusd: ' + pusd.address);
    //let usdc = await TestERC20.deploy('USDC', 'USDC', 6);
    let usdc = await TestERC20.attach('0x46A7783AcA0b65073Ba51e52B73f252A261a909d');
    console.log('usdc: ' + usdc.address);
    // 部署ETH锚定池
    // let ethAnchor = await CoFiXAnchorPool.deploy(0, 
    //     [eth.address, peth.address, weth.address],
    //     ['1000000000000000000', '1000000000000000000', '1000000000000000000']
    // );
    let ethAnchor = await CoFiXAnchorPool.attach('0xb57009B96FdD4863ef5D446Cd2E70FCF7747B606');
    console.log('ethAnchor: ' + ethAnchor.address);
    // 部署USD锚定池
    // let usdAnchor = await CoFiXAnchorPool.deploy(1,
    //     [usdt.address, pusd.address, usdc.address],
    //     ['1000000', '1000000000000000000', '1000000000000000000']
    // );
    let usdAnchor = await CoFiXAnchorPool.attach('0x71dd3d064b2d5975281A2992e3fC59467d936B92');
    console.log('usdAnchor: ' + usdAnchor.address);

    // // 注册usdt和nest交易对
    // console.log('1. registerPair(eth.address, usdt.address, usdtPair.address)');
    // await cofixRouter.registerPair(eth.address, usdt.address, usdtPair.address);
    // console.log('2. registerPair(eth.address, nest.address, nestPair.address)');
    // await cofixRouter.registerPair(eth.address, nest.address, nestPair.address);
    // // 注册ETH锚定池
    // console.log('3. registerPair(eth.address, peth.address, ethAnchor.address)');
    // await cofixRouter.registerPair(eth.address, peth.address, ethAnchor.address);
    // console.log('4. registerPair(eth.address, weth.address, ethAnchor.address)');
    // await cofixRouter.registerPair(eth.address, weth.address, ethAnchor.address);
    // console.log('5. registerPair(peth.address, weth.address, ethAnchor.address)');
    // await cofixRouter.registerPair(peth.address, weth.address, ethAnchor.address);
    // // 注册USD锚定池
    // console.log('6. registerPair(usdt.address, pusd.address, usdAnchor.address)');
    // await cofixRouter.registerPair(usdt.address, pusd.address, usdAnchor.address);
    // console.log('7. registerPair(usdt.address, usdc.address, usdAnchor.address)');
    // await cofixRouter.registerPair(usdt.address, usdc.address, usdAnchor.address);
    // console.log('8. registerPair(pusd.address, usdc.address, usdAnchor.address)');
    // await cofixRouter.registerPair(pusd.address, usdc.address, usdAnchor.address);
    // // 注册路由路径
    // console.log('9. registerRouterPath(usdt.address, nest.address, [usdt.address, eth.address, nest.address])');
    // await cofixRouter.registerRouterPath(usdt.address, nest.address, [usdt.address, eth.address, nest.address]);
    // console.log('10. registerRouterPath(usdt.address, peth.address, [usdt.address, eth.address, peth.address])');
    // await cofixRouter.registerRouterPath(usdt.address, peth.address, [usdt.address, eth.address, peth.address]);
    // console.log('11. registerRouterPath(usdt.address, weth.address, [usdt.address, eth.address, weth.address])');
    // await cofixRouter.registerRouterPath(usdt.address, weth.address, [usdt.address, eth.address, weth.address]);
    
    // // eth, nest, usdt, pusd, usdc, peth, weth
    // console.log('12. registerRouterPath(pusd.address, eth.address, [pusd.address, usdt.address, eth.address])');
    // await cofixRouter.registerRouterPath(pusd.address, eth.address, [pusd.address, usdt.address, eth.address]);
    // console.log('13. registerRouterPath(pusd.address, peth.address, [pusd.address, usdt.address, eth.address, peth.address])');
    // await cofixRouter.registerRouterPath(pusd.address, peth.address, [pusd.address, usdt.address, eth.address, peth.address]);
    // console.log('14. registerRouterPath(pusd.address, weth.address, [pusd.address, usdt.address, eth.address, weth.address])');
    // await cofixRouter.registerRouterPath(pusd.address, weth.address, [pusd.address, usdt.address, eth.address, weth.address]);
    // console.log('15. registerRouterPath(pusd.address, nest.address, [pusd.address, usdt.address, eth.address, nest.address])');
    // await cofixRouter.registerRouterPath(pusd.address, nest.address, [pusd.address, usdt.address, eth.address, nest.address]);

    // console.log('16. registerRouterPath(usdc.address, eth.address, [usdc.address, usdt.address, eth.address])');
    // await cofixRouter.registerRouterPath(usdc.address, eth.address, [usdc.address, usdt.address, eth.address]);
    // console.log('17. registerRouterPath(usdc.address, peth.address, [usdc.address, usdt.address, eth.address, peth.address])');
    // await cofixRouter.registerRouterPath(usdc.address, peth.address, [usdc.address, usdt.address, eth.address, peth.address]);
    // console.log('18. registerRouterPath(usdc.address, weth.address, [usdc.address, usdt.address, eth.address, weth.address])');
    // await cofixRouter.registerRouterPath(usdc.address, weth.address, [usdc.address, usdt.address, eth.address, weth.address]);
    // console.log('19. registerRouterPath(usdc.address, nest.address, [usdc.address, usdt.address, eth.address, nest.address])');
    // await cofixRouter.registerRouterPath(usdc.address, nest.address, [usdc.address, usdt.address, eth.address, nest.address]);

    // console.log('20. registerRouterPath(peth.address, nest.address, [peth.address, eth.address, nest.address])');
    // await cofixRouter.registerRouterPath(peth.address, nest.address, [peth.address, eth.address, nest.address]);
    // console.log('21. registerRouterPath(weth.address, nest.address, [weth.address, eth.address, nest.address])');
    // await cofixRouter.registerRouterPath(weth.address, nest.address, [weth.address, eth.address, nest.address]);

    // console.log('22. ethAnchor.initialize(cofixGovernance.address)');
    // await ethAnchor.initialize(cofixGovernance.address);
    // console.log('23. usdAnchor.initialize(cofixGovernance.address)');
    // await usdAnchor.initialize(cofixGovernance.address);
    // console.log('24. ethAnchor.update(cofixGovernance.address)');
    // await ethAnchor.update(cofixGovernance.address);
    // console.log('25. usdAnchor.update(cofixGovernance.address)');
    // await usdAnchor.update(cofixGovernance.address);

    let xeth = await CoFiXAnchorToken.attach(await ethAnchor.getXToken(eth.address));
    console.log('xeth: ' + xeth.address);
    let xpeth = await CoFiXAnchorToken.attach(await ethAnchor.getXToken(peth.address));
    console.log('xpeth: ' + xpeth.address);
    let xweth = await CoFiXAnchorToken.attach(await ethAnchor.getXToken(weth.address));
    console.log('xweth: ' + xweth.address);

    let xusdt = await CoFiXAnchorToken.attach(await usdAnchor.getXToken(usdt.address));
    console.log('xusdt: ' + xusdt.address);
    let xpusd = await CoFiXAnchorToken.attach(await usdAnchor.getXToken(pusd.address));
    console.log('xpusd: ' + xpusd.address);
    let xusdc = await CoFiXAnchorToken.attach(await usdAnchor.getXToken(usdc.address));
    console.log('xusdc: ' + xusdc.address);

    // console.log('26. cofixVaultForStaking.batchSetPoolWeight(xeth.address, 20000)');
    // await cofixVaultForStaking.batchSetPoolWeight([xeth.address], [20000]);
    // console.log('27. cofixVaultForStaking.batchSetPoolWeight(xpeth.address, 20000)');
    // await cofixVaultForStaking.batchSetPoolWeight([xpeth.address], [20000]);
    // console.log('28. cofixVaultForStaking.batchSetPoolWeight(xweth.address, 20000)');
    // await cofixVaultForStaking.batchSetPoolWeight([xweth.address], [20000]);

    // console.log('29. cofixVaultForStaking.batchSetPoolWeight(xusdt.address, 20000)');
    // await cofixVaultForStaking.batchSetPoolWeight([xusdt.address], [20000]);
    // console.log('30. cofixVaultForStaking.batchSetPoolWeight(xpusd.address, 20000)');
    // await cofixVaultForStaking.batchSetPoolWeight([xpusd.address], [20000]);
    // console.log('31. cofixVaultForStaking.batchSetPoolWeight(xusdc.address, 20000)');
    // await cofixVaultForStaking.batchSetPoolWeight([xusdc.address], [20000]);


    const contracts = {
        cofi: cofi,
        cnode: cnode,
        cofixDAO: cofixDAO,
        cofixRouter: cofixRouter,
        cofixController: cofixController,
        cofixVaultForStaking: cofixVaultForStaking,
        cofixGovernance: cofixGovernance,

        usdt: usdt,
        nest: nest,
        peth: peth,
        weth: weth,
        pusd: pusd,
        usdc: usdc,

        xeth: xeth,
        xpeth: xpeth,
        xweth: xweth,
        xusdt: xusdt,
        xpusd: xpusd,
        xusdc: xusdc,

        usdtPair: usdtPair,
        nestPair: nestPair,
        ethAnchor: ethAnchor,
        usdAnchor: usdAnchor
    };
    //console.log(contracts);
    console.log('** 合约部署完成 **');
    return contracts;
}
