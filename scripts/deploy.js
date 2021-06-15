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
    const CoFiXVaultForLP = await ethers.getContractFactory("CoFiXVaultForStaking");
    const CoFiXPair = await ethers.getContractFactory("CoFiXPair");

    const cnode = await TestERC20.deploy('CNode', 'CNode', 18);
    const usdt = await TestERC20.deploy('USDT', 'USDT', 6);
    const cofi = await CoFiToken.deploy();
    const governance = await CoFiXGovernance.deploy();
    const cofixDAO = await CoFiXDAO.deploy(cofi.address);
    const router = await CoFiXRouter.deploy(cofi.address, cnode.address);
    const controller = await CoFiXController.deploy();
    const vaultForLP = await CoFiXVaultForLP.deploy(cofi.address, cnode.address);
        
    await governance.initialize('0x0000000000000000000000000000000000000000');
    await router.initialize(governance.address);
    await cofixDAO.initialize(governance.address);
    await vaultForLP.initialize(governance.address);
        
    await governance.setBuiltinAddress(
        cofi.address,
        cnode.address,
        cofixDAO.address,
        router.address,
        controller.address,
        vaultForLP.address
    );
    await router.update(governance.address);
    await cofixDAO.update(governance.address);
    await vaultForLP.update(governance.address);

    const pair = await CoFiXPair.deploy('XT-1', 'XToken-1', usdt.address, BigInt('1000000000000000000'), BigInt('3000000000'));
        
    await pair.initialize(governance.address);
    await pair.update(governance.address);
    await vaultForLP.setConfig({
        cofiRate: 20000
    });

    await router.setConfig({
        cnodeRewardRate: 1000
    });
    await router.addPair(usdt.address, pair.address);
    await cofi.addMinter(router.address);
    await cofi.addMinter(vaultForLP.address);
    console.log('usdt: ' + usdt.address);

    return {
        cofi: cofi,
        cnode: cnode,
        cofixDAO: cofixDAO,
        router: router,
        controller: controller,
        vaultForLP: vaultForLP,
        governance: governance,

        usdt: usdt,
        pair: pair
    };
}
