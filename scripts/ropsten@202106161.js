// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { ethers } = require('hardhat');

exports.deploy = async function () {
    const TestERC20 = await ethers.getContractFactory('TestERC20');
    const CoFiToken = await ethers.getContractFactory('CoFiToken');
    const CoFiXGovernance = await ethers.getContractFactory('CoFiXGovernance');
    const CoFiXDAO = await ethers.getContractFactory('CoFiXDAO');
    const CoFiXRouter = await ethers.getContractFactory('CoFiXRouter');
    const CoFiXController = await ethers.getContractFactory('CoFiXController');
    const CoFiXVaultForStaking = await ethers.getContractFactory('CoFiXVaultForStaking');
    const CoFiXPair = await ethers.getContractFactory('CoFiXPair');

    // cnode: 0x2dC52e1FcD06a43285c5D7f5E833131b1c411852
    // usdt: 0xd5798C4DbC5AC13DbE4809d2914b5fd5e5030948
    // cofi: 0x30C69c1511608aBCf5f7052CE330A47673BEF80a
    // cofixGovernance: 0x615c7448ED870aD41a24FE7e96016b2d9406C169
    // cofixDAO: 0x7D3d375759Dce4D8609EcA61fCe5898e5Dd52E09
    // cofixRouter: 0x537A8955B0E0466A487F8a417717551ac05bB580
    // cofixController: 0xA1e38e9DECB554b6AaC4b9B58f74Af1eb33CE291
    // cofixVaultForStaking: 0x69E6CAae16Acf21134D839835C5f8bC9F2522680
    // pair: 0x9228A336bb91bFf6A1Ff54Ded0DE514D22dAED52

    console.log('** Deploy: ropsten@202106161.js **');

    //const cnode = await TestERC20.deploy('CNode', 'CNode', 18);
    const cnode = await TestERC20.attach('0x2dC52e1FcD06a43285c5D7f5E833131b1c411852');
    console.log('cnode: ' + cnode.address);
    // const usdt = await TestERC20.deploy('USDT', 'USDT', 6);
    const usdt = await TestERC20.attach('0xd5798C4DbC5AC13DbE4809d2914b5fd5e5030948');
    console.log('usdt: ' + usdt.address);
    //const cofi = await CoFiToken.deploy();
    const cofi = await CoFiToken.attach('0x30C69c1511608aBCf5f7052CE330A47673BEF80a');
    console.log('cofi: ' + cofi.address);
    //const cofixGovernance = await CoFiXGovernance.deploy();
    const cofixGovernance = await CoFiXGovernance.attach('0x615c7448ED870aD41a24FE7e96016b2d9406C169');
    console.log('cofixGovernance: ' + cofixGovernance.address);
    //const cofixDAO = await CoFiXDAO.deploy(cofi.address);
    const cofixDAO = await CoFiXDAO.attach('0x7D3d375759Dce4D8609EcA61fCe5898e5Dd52E09');
    console.log('cofixDAO: ' + cofixDAO.address);
    //const cofixRouter = await CoFiXRouter.deploy(cofi.address, cnode.address);
    const cofixRouter = await CoFiXRouter.attach('0x537A8955B0E0466A487F8a417717551ac05bB580');
    console.log('cofixRouter: ' + cofixRouter.address);
    //const cofixController = await CoFiXController.deploy();
    const cofixController = await CoFiXController.attach('0xA1e38e9DECB554b6AaC4b9B58f74Af1eb33CE291');
    console.log('cofixController: ' + cofixController.address);
    //const cofixVaultForStaking = await CoFiXVaultForStaking.deploy(cofi.address, cnode.address);
    const cofixVaultForStaking = await CoFiXVaultForStaking.attach('0x69E6CAae16Acf21134D839835C5f8bC9F2522680');
    console.log('cofixVaultForStaking: ' + cofixVaultForStaking.address);
    
    // console.log('cofixGovernance.initialize');
    // await cofixGovernance.initialize('0x0000000000000000000000000000000000000000');
    // console.log('cofixRouter.initialize');
    // await cofixRouter.initialize(cofixGovernance.address);
    // console.log('cofixDAO.initialize');
    // await cofixDAO.initialize(cofixGovernance.address);
    // console.log('cofixVaultForStaking.initialize');
    // await cofixVaultForStaking.initialize(cofixGovernance.address);
        
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

    // const pair = await CoFiXPair.deploy('XT-1', 'XToken-1', usdt.address, BigInt('1000000000000000000'), BigInt('3000000000'));
    const pair = await CoFiXPair.attach('0x9228A336bb91bFf6A1Ff54Ded0DE514D22dAED52');
    console.log('pair: ' + pair.address);
    
    // console.log('pair.initialize');
    // await pair.initialize(cofixGovernance.address);
    // console.log('pair.update');
    // await pair.update(cofixGovernance.address);
    // console.log('cofixVaultForStaking.setConfig');
    // await cofixVaultForStaking.setConfig({
    //     cofiUnit: 10000000000000000
    // });
    // console.log('cofixVaultForStaking.batchSetPoolWeight');
    // await cofixVaultForStaking.batchSetPoolWeight([pair.address], [100000]);

    // console.log('cofixRouter.setConfig');
    // await cofixRouter.setConfig({
    //     cnodeRewardRate: 1000
    // });
    console.log('cofixRouter.addPair');
    await cofixRouter.addPair(usdt.address, pair.address);
    console.log('cofi.addMinter');
    await cofi.addMinter(cofixRouter.address);
    console.log('cofi.addMinter');
    await cofi.addMinter(cofixVaultForStaking.address);
    console.log('usdt: ' + usdt.address);

    return {
        cofi: cofi,
        cnode: cnode,
        cofixDAO: cofixDAO,
        cofixRouter: cofixRouter,
        cofixController: cofixController,
        cofixVaultForStaking: cofixVaultForStaking,
        cofixGovernance: cofixGovernance,

        usdt: usdt,
        pair: pair
    };
}
