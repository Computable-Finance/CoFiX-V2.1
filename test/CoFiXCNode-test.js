const { expect } = require("chai");
const e = require("../scripts/deploy.js");

describe("CoFiXRouter", function() {
    it("test1", async function() {
        const [owner, addr1] = await ethers.getSigners();
        const {
            cofi,
            cnode,
            cofixDAO,
            router,
            controller,
            vaultForLP,
            governance,
            usdt,
            pair
        } = await e.deploy();

        let cnodeVault = vaultForLP;
        await cnodeVault.setConfig({
            cofiRate: 20000
        });
        
        await cnode.transfer(owner.address, 100);
        await cnode.transfer(addr1.address, 99);
        await cnode.approve(cnodeVault.address, 100);
        console.log(addr1.address);
        await cnode.connect(addr1).approve(cnodeVault.address, 100);
        await cnodeVault.stake(cnode.address, owner.address, 1);
        await cnodeVault.connect(addr1).stake(cnode.address, addr1.address, 99);

        for (var i = 0; i < 10; ++i) {
            let cr = await cnodeVault.calcReward(cnode.address, 100);
            let r = {
                //tradeReward: cr.tradeReward.toString(),
                newReward: cr.newReward.toString(),
                rewardPerToken: cr.rewardPerToken.toString()
            }
            console.log(r);
            let e = await cnodeVault.earned(cnode.address, owner.address);
            console.log('owner earned: ' + e);
            e = await cnodeVault.earned(cnode.address, addr1.address);
            console.log('addr1 earned: ' + e);
            console.log('balanceOf[owner]=' + await cnodeVault.balanceOf(cnode.address, owner.address));
            console.log('balanceOf[owner]=' + await cnodeVault.balanceOf(cnode.address, addr1.address));
            await cnodeVault.update(governance.address);
        }

        await cnodeVault.getReward(cnode.address);
    });
});
 