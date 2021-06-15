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

        await usdt.transfer(owner.address, BigInt('10000000000000'));
        await usdt.approve(router.address, BigInt('10000000000000'));
        let receipt = await router.addLiquidity(
            usdt.address,
            BigInt('2000000000000000000'),
            BigInt('6000000000'),
            BigInt('900000000000000000'),
            owner.address,
            BigInt('1723207627371'), {
                value: BigInt('2010000000000000000')
            }
        );
        console.log((await receipt.wait()).gasUsed.toString());

        let liquidity = await pair.balanceOf(owner.address);
        //expect(liquidity).to.equal(BigInt('2000000000000000000'));
        expect(liquidity).to.equal(BigInt('1999999999000000000'));
        expect(await ethers.provider.getBalance(pair.address)).to.equal(BigInt('2000000000000000000'));
        expect(await usdt.balanceOf(pair.address)).to.equal('6000000000');

        receipt = await router.addLiquidityAndStake(
            usdt.address,
            BigInt('2000000000000000000'),
            BigInt('6000000000'),
            BigInt('900000000000000000'),
            owner.address,
            BigInt('1723207627371'), {
                value: BigInt('2010000000000000000')
            }
        )

        console.log((await receipt.wait()).gasUsed.toString());
        expect(liquidity).to.equal(BigInt('1999999999000000000'));
        expect(await ethers.provider.getBalance(pair.address)).to.equal(BigInt('4000000000000000000'));
        expect(await usdt.balanceOf(pair.address)).to.equal('12000000000');

        await usdt.transfer(owner.address, 0);
        console.log('staked: ' + (await vaultForLP.balanceOf(pair.address, owner.address)).toString());
        console.log('earned: ' + (await vaultForLP.earned(pair.address, owner.address)).toString());
    });
});
