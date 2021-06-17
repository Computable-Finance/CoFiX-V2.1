const { expect } = require("chai");
const deployer = require("../scripts/deploy.js");

describe("CoFiXRouter", function() {
    it("test1", async function() {

        const [owner, addr1] = await ethers.getSigners();
        
        const {
            cofi,
            cnode,
            cofixDAO,
            cofixRouter,
            cofixController,
            cofixVaultForStaking,
            cofixGovernance,
            usdt,
            pair
        } = await deployer.deploy();

        await usdt.transfer(owner.address, BigInt('10000000000000'));
        await usdt.approve(cofixRouter.address, BigInt('10000000000000'));
        let receipt = await cofixRouter.addLiquidityAndStake(
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

        let staked = await cofixVaultForStaking.balanceOf(pair.address, owner.address);
            
        console.log(staked.toString());

        let liq = await cofixVaultForStaking.balanceOf(pair.address, owner.address);
        console.log('liq=' + liq.toString());
        await cofixVaultForStaking.unstake(pair.address, liq);
        await pair.approve(cofixRouter.address, liq);
        console.log('balance=' + (await pair.balanceOf(owner.address)).toString());

        await cofixRouter.removeLiquidityGetTokenAndETH(
            // 要移除的token对
            usdt.address,
            // 移除的额度
            1,
            // 预期最少可以获得的eth数量
            0,
            // 接收地址
            owner.address,
            // 截止时间
            BigInt('1723207627371'), {
                value: BigInt('10000000000000000')
            }
        );

        receipt = await cofixRouter.swapExactETHForTokens(
            // 目标token地址
            usdt.address.toString(),
            // eth数量
            BigInt('100000000000000000'),
            // 预期获得的token的最小数量
            BigInt('10'),
            // 接收地址
            owner.address,
            // 出矿接收地址
            owner.address,
            BigInt('1723207627371'), {
                value: BigInt('110000000000000000')
            }
        );
        console.log((await receipt.wait()).gasUsed.toString());

        receipt = await cofixRouter.swapExactETHForTokens(
            // 目标token地址
            usdt.address.toString(),
            // eth数量
            BigInt('100000000000000000'),
            // 预期获得的token的最小数量
            BigInt('10'),
            // 接收地址
            owner.address,
            // 出矿接收地址
            owner.address,
            BigInt('1723207627371'), {
                value: BigInt('110000000000000000')
            }
        );
        console.log((await receipt.wait()).gasUsed.toString());

        // // 用指定数量的eth兑换token
        // // msg.value = amountIn + oracle fee
        // function swapExactETHForTokens(
        //     // 目标token地址
        //     address token,
        //     // eth数量
        //     uint amountIn,
        //     // 预期获得的token的最小数量
        //     uint amountOutMin,
        //     // 接收地址
        //     address to,
        //     // 出矿接收地址
        //     address rewardTo,
        //     uint deadline
        // )
    });
});
