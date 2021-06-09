const { expect } = require("chai");

describe("CoFiXRouter", function() {
    it("test1", async function() {
        const [owner, addr1] = await ethers.getSigners();
        const TestERC20 = await ethers.getContractFactory("TestERC20");
        const CoFiToken = await ethers.getContractFactory("CoFiToken");
        const CoFiXRouter = await ethers.getContractFactory("CoFiXRouter");
        const CoFiXPair = await ethers.getContractFactory("CoFiXPair");
        const CoFiXController = await ethers.getContractFactory("CoFiXController");
        const CoFiXVaultForLP = await ethers.getContractFactory("CoFiXVaultForLP");

        const usdt = await TestERC20.deploy('USDT', 'USDT', 6);
        const cofi = await CoFiToken.deploy();
        const router = await CoFiXRouter.deploy();
        const vaultForLP = await CoFiXVaultForLP.deploy(cofi.address);
        const pair = await CoFiXPair.deploy('XT-1', 'XToken-1', usdt.address, cofi.address, BigInt('1000000000000000000'), BigInt('3000000000'));
        // (
        //     string memory name_, 
        //     string memory symbol_, 
        //     address tokenAddress, 
        //     uint initEthAmount, 
        //     uint initTokenAmount
        // )
        const controller = await CoFiXController.deploy();
        pair.setCoFiXController(controller.address);

        await router.addPair(usdt.address, pair.address);
        await router.setCoFiXVaultForLP(vaultForLP.address);
        await router.setCoFiToken(cofi.address);
        console.log('usdt: ' + usdt.address);

        await usdt.transfer(owner.address, BigInt('10000000000000'));
        await usdt.approve(router.address, BigInt('10000000000000'));

        let receipt = await router.addLiquidityAndStake(
            usdt.address.toString(),
            BigInt('2000000000000000000'),
            BigInt('6000000000'),
            BigInt('900000000000000000'),
            owner.address,
            BigInt('1723207627371'), {
                value: BigInt('2010000000000000000')
            }
        );

        console.log((await receipt.wait()).gasUsed.toString());

        let staked = await vaultForLP.balanceOf(pair.address, owner.address);
            
        console.log(staked.toString());

        let liq = await vaultForLP.balanceOf(pair.address, owner.address);
        console.log('liq=' + liq.toString());
        await vaultForLP.unstake(pair.address, liq);
        await pair.approve(router.address, liq);
        console.log('balance=' + (await pair.balanceOf(owner.address)).toString());

        await router.removeLiquidityGetTokenAndETH(
            // 要移除的token对
            usdt.address,
            // 移除的额度
            liq,
            // 预期最少可以获得的eth数量
            1,
            // 接收地址
            owner.address,
            // 截止时间
            BigInt('1723207627371'), {
                value: BigInt('10000000000000000')
            }
        );
    });
});
