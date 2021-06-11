const { expect } = require("chai");

describe("CoFiXRouter", function() {
    it("test1", async function() {
        const [owner, addr1] = await ethers.getSigners();
        const TestERC20 = await ethers.getContractFactory("TestERC20");
        const CoFiToken = await ethers.getContractFactory("CoFiToken");
        const CoFiXDAO = await ethers.getContractFactory("CoFiXDAO");
        const CoFiXRouter = await ethers.getContractFactory("CoFiXRouter");
        const CoFiXPair = await ethers.getContractFactory("CoFiXPair");
        const CoFiXController = await ethers.getContractFactory("CoFiXController");
        const CoFiXVaultForLP = await ethers.getContractFactory("CoFiXVaultForLP");
        const CoFiXVaultForCNode = await ethers.getContractFactory("CoFiXVaultForCNode");

        const cnode = await TestERC20.deploy('CNode', 'CNode', 18);
        const usdt = await TestERC20.deploy('USDT', 'USDT', 6);
        const cofi = await CoFiToken.deploy();
        const router = await CoFiXRouter.deploy(cofi.address, cnode.address);
        const vaultForLP = await CoFiXVaultForLP.deploy(cofi.address, cnode.address);
        const cofixDAO = await CoFiXDAO.deploy();
        const pair = await CoFiXPair.deploy('XT-1', 'XToken-1', usdt.address, BigInt('1000000000000000000'), BigInt('3000000000'));
        const controller = await CoFiXController.deploy();
        pair.setCoFiXController(controller.address);
        pair.setCoFiXDAO(cofixDAO.address);

        await router.setConfig({
            cnodeRewardRate: 1000
        });
        await router.addPair(usdt.address, pair.address);
        await router.setCoFiXVaultForLP(vaultForLP.address);
        await cofi.addMinter(router.address);
        await cofi.addMinter(vaultForLP.address);
        console.log('usdt: ' + usdt.address);

        const cnodeVault = await CoFiXVaultForCNode.deploy(cofi.address, cnode.address);
        await cofi.addMinter(cnodeVault.address);
        await cnodeVault.setConfig({
            cofiRate: 20000
        });
        
        await cnodeVault.setCoFiXRouter(router.address);
        await cnode.transfer(owner.address, 100);
        await cnode.transfer(addr1.address, 99);
        await cnode.approve(cnodeVault.address, 100);
        console.log(addr1.address);
        await cnode.connect(addr1).approve(cnodeVault.address, 100);
        await cnodeVault.stake(owner.address, 1);
        await cnodeVault.connect(addr1).stake(addr1.address, 99);
        // for(var i = 0; i < 100; ++i) {
        //     await cnode.approve(cnodeVault.address, 100);
        // }
        // let earned = await cnodeVault.earned(owner.address);
        // console.log('earned=' + earned);
        // earned = await cnodeVault.earned(addr1.address);
        // console.log('earned=' + earned);

        for (var i = 0; i < 10; ++i) {
            let cr = await cnodeVault._calcReward(100);
            let r = {
                tradeReward: cr.tradeReward.toString(),
                newReward: cr.newReward.toString(),
                rewardPerToken: cr.rewardPerToken.toString()
            }
            console.log(r);
            let e = await cnodeVault.earned(owner.address);
            console.log('owner earned: ' + e);
            e = await cnodeVault.earned(addr1.address);
            console.log('addr1 earned: ' + e);
            console.log('balanceOf[owner]=' + await cnodeVault.balanceOf(owner.address));
            console.log('balanceOf[owner]=' + await cnodeVault.balanceOf(addr1.address));
            await cnodeVault.setCoFiXRouter(router.address);
        }

        await cnodeVault.getReward();
    });
});
 