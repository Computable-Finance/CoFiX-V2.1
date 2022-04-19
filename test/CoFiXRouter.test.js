const { expect } = require('chai');
const deployer = require('../scripts/deploy.js');

describe('CoFiXRouter', function() {
    it('test1', async function() {

        const [owner, addr1] = await ethers.getSigners();
        
        const {
            cofi,
            cnode,
            cofixDAO,
            cofixRouter,
            cofixController,
            cofixVaultForStaking,
            cofixGovernance,
            nestPriceFacade,
            
            usdt,
            usdtPair
        } = await deployer.deploy();

        await usdt.transfer(owner.address, BigInt('10000000000000'));
        await usdt.approve(cofixRouter.address, BigInt('10000000000000'));
        let receipt = await cofixRouter.addLiquidityAndStake(
            usdtPair.address,
            usdt.address,
            BigInt('2000000000000000000'),
            BigInt('4000000000'),
            BigInt('900000000000000000'),
            owner.address,
            BigInt('1800000000000'), {
                value: BigInt('2010000000000000000')
            }
        );

        console.log((await receipt.wait()).gasUsed.toString());

        let staked = await cofixVaultForStaking.balanceOf(usdtPair.address, owner.address);
            
        console.log(staked.toString());

        let liq = await cofixVaultForStaking.balanceOf(usdtPair.address, owner.address);
        console.log('liq=' + liq.toString());
        await cofixVaultForStaking.withdraw(usdtPair.address, liq);
        await usdtPair.approve(cofixRouter.address, liq);
        console.log('balance=' + (await usdtPair.balanceOf(owner.address)).toString());

        await cofixRouter.removeLiquidityGetTokenAndETH(
            usdtPair.address,
            usdt.address,
            1,
            0,
            owner.address,
            BigInt('1800000000000'), {
                value: BigInt('10000000000000000')
            }
        );

        receipt = await cofixRouter.swapExactTokensForTokens(
            ['0x0000000000000000000000000000000000000000', usdt.address.toString()],
            BigInt('100000000000000000'),
            BigInt(10),
            owner.address,
            owner.address,
            BigInt('1800000000000'), {
                value: BigInt('110000000000000000')
            }
        );
        console.log((await receipt.wait()).gasUsed.toString());

        receipt = await cofixRouter.swapExactTokensForTokens(
            ['0x0000000000000000000000000000000000000000', usdt.address.toString()],
            BigInt('100000000000000000'),
            BigInt(10),
            owner.address,
            owner.address,
            BigInt('1800000000000'), {
                value: BigInt('110000000000000000')
            }
        );
        console.log((await receipt.wait()).gasUsed.toString());
    });
});
