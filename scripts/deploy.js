// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { ethers } = require("hardhat");

exports.deploy = async function () {
    const TestERC20 = await ethers.getContractFactory("TestERC20");
    const CoFiToken = await ethers.getContractFactory("CoFiToken");
    const CoFiXGovernance = await ethers.getContractFactory("CoFiXGovernance");
    const CoFiXDAO = await ethers.getContractFactory("CoFiXDAO");
    const CoFiXRouter = await ethers.getContractFactory("CoFiXRouter");
    const CoFiXController = await ethers.getContractFactory("CoFiXController");
    const CoFiXVaultForStaking = await ethers.getContractFactory("CoFiXVaultForStaking");
    const CoFiXPair = await ethers.getContractFactory("CoFiXPair");

    // cnode: 0x2dC52e1FcD06a43285c5D7f5E833131b1c411852
    // usdt: 0xd5798C4DbC5AC13DbE4809d2914b5fd5e5030948
    // cofi: 0x30C69c1511608aBCf5f7052CE330A47673BEF80a
    // governance: 0x615c7448ED870aD41a24FE7e96016b2d9406C169
    // cofixDAO: 0x7D3d375759Dce4D8609EcA61fCe5898e5Dd52E09
    // router: 0x537A8955B0E0466A487F8a417717551ac05bB580
    // controller: 0xA1e38e9DECB554b6AaC4b9B58f74Af1eb33CE291
    // vaultForStaking: 0x69E6CAae16Acf21134D839835C5f8bC9F2522680
    // pair: 0x9228A336bb91bFf6A1Ff54Ded0DE514D22dAED52

    //const cnode = await TestERC20.deploy('CNode', 'CNode', 18);
    const cnode = await TestERC20.attach('0x2dC52e1FcD06a43285c5D7f5E833131b1c411852');
    console.log('cnode: ' + cnode.address);
    // const usdt = await TestERC20.deploy('USDT', 'USDT', 6);
    const usdt = await TestERC20.attach('0xd5798C4DbC5AC13DbE4809d2914b5fd5e5030948');
    console.log('usdt: ' + usdt.address);
    //const cofi = await CoFiToken.deploy();
    const cofi = await CoFiToken.attach('0x30C69c1511608aBCf5f7052CE330A47673BEF80a');
    console.log('cofi: ' + cofi.address);
    //const governance = await CoFiXGovernance.deploy();
    const governance = await CoFiXGovernance.attach('0x615c7448ED870aD41a24FE7e96016b2d9406C169');
    console.log('governance: ' + governance.address);
    //const cofixDAO = await CoFiXDAO.deploy(cofi.address);
    const cofixDAO = await CoFiXDAO.attach('0x7D3d375759Dce4D8609EcA61fCe5898e5Dd52E09');
    console.log('cofixDAO: ' + cofixDAO.address);
    //const router = await CoFiXRouter.deploy(cofi.address, cnode.address);
    const router = await CoFiXRouter.attach('0x537A8955B0E0466A487F8a417717551ac05bB580');
    console.log('router: ' + router.address);
    //const controller = await CoFiXController.deploy();
    const controller = await CoFiXController.attach('0xA1e38e9DECB554b6AaC4b9B58f74Af1eb33CE291');
    console.log('controller: ' + controller.address);
    //const vaultForStaking = await CoFiXVaultForStaking.deploy(cofi.address, cnode.address);
    const vaultForStaking = await CoFiXVaultForStaking.attach('0x69E6CAae16Acf21134D839835C5f8bC9F2522680');
    console.log('vaultForStaking: ' + vaultForStaking.address);
    
    // console.log('governance.initialize');
    // await governance.initialize('0x0000000000000000000000000000000000000000');
    // console.log('router.initialize');
    // await router.initialize(governance.address);
    // console.log('cofixDAO.initialize');
    // await cofixDAO.initialize(governance.address);
    // console.log('vaultForStaking.initialize');
    // await vaultForStaking.initialize(governance.address);
        
    // console.log('governance.setBuiltinAddress');
    // await governance.setBuiltinAddress(
    //     cofi.address,
    //     cnode.address,
    //     cofixDAO.address,
    //     router.address,
    //     controller.address,
    //     vaultForStaking.address
    // );
    // console.log('router.update');
    // await router.update(governance.address);
    // console.log('cofixDAO.update');
    // await cofixDAO.update(governance.address);
    // console.log('vaultForStaking.update');
    // await vaultForStaking.update(governance.address);

    // const pair = await CoFiXPair.deploy('XT-1', 'XToken-1', usdt.address, BigInt('1000000000000000000'), BigInt('3000000000'));
    const pair = await CoFiXVaultForStaking.attach('0x9228A336bb91bFf6A1Ff54Ded0DE514D22dAED52');
    console.log('pair: ' + pair.address);
    
    // console.log('pair.initialize');
    // await pair.initialize(governance.address);
    // console.log('pair.update');
    // await pair.update(governance.address);
    // console.log('vaultForStaking.setConfig');
    // await vaultForStaking.setConfig({
    //     cofiRate: 20000
    // });
    // console.log('vaultForStaking.initStakingChannel');
    // await vaultForStaking.initStakingChannel(pair.address, 100000, 0);

    // console.log('router.setConfig');
    // await router.setConfig({
    //     cnodeRewardRate: 1000
    // });
    console.log('router.addPair');
    await router.addPair(usdt.address, pair.address);
    console.log('cofi.addMinter');
    await cofi.addMinter(router.address);
    console.log('cofi.addMinter');
    await cofi.addMinter(vaultForStaking.address);
    console.log('usdt: ' + usdt.address);

    return {
        cofi: cofi,
        cnode: cnode,
        cofixDAO: cofixDAO,
        router: router,
        controller: controller,
        vaultForStaking: vaultForStaking,
        governance: governance,

        usdt: usdt,
        pair: pair
    };
}
