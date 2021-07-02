const { expect } = require("chai");
const deployer = require("../scripts/deploy.js");

describe("CoFiXRouter", function() {
    it("test1", async function() {

        const [owner, addr1, addr2] = await ethers.getSigners();
        
        // 部署合约
        const {
            cofi,
            cnode,
            cofixDAO,
            cofixRouter,
            cofixController,
            cofixVaultForStaking,
            cofixGovernance,

            nest,
            usdt,
            usdtPair,
            nestPair,
            usdAnchor,
            ethAnchor,
        } = await deployer.deploy();
        return;

        // await usdt.transfer(owner.address, BigInt('10000000000000'));
        // await usdt.approve(cofixRouter.address, BigInt('10000000000000'));
        
        // if (true) {
        //     // 1. 添加2eth的流动性，预期获得1999999999000000000份额
        //     let receipt = await cofixRouter.addLiquidity(
        //         usdt.address,
        //         BigInt('2000000000000000000'),
        //         BigInt('6000000000'),
        //         BigInt('900000000000000000'),
        //         owner.address,
        //         BigInt('1723207627371'), {
        //             value: BigInt('2010000000000000000')
        //         }
        //     );
        //     console.log((await receipt.wait()).gasUsed.toString());

        //     let liquidity = await pair.balanceOf(owner.address);
        //     //expect(liquidity).to.equal(BigInt('2000000000000000000'));
        //     expect(liquidity).to.equal(BigInt('1999999999000000000'));
        //     expect(await ethers.provider.getBalance(pair.address)).to.equal(BigInt('2000000000000000000'));
        //     expect(await usdt.balanceOf(pair.address)).to.equal('6000000000');
        //     expect(await cofixVaultForStaking.balanceOf(pair.address, owner.address)).to.equal('0');
        // }
        
        if (true) {

        }

        //     console.log((await receipt.wait()).gasUsed.toString());
        //     let liquidity = await pair.balanceOf(owner.address);
        //     expect(liquidity).to.equal(BigInt('1999999999000000000'));
        //     expect(await ethers.provider.getBalance(pair.address)).to.equal(BigInt('4000000000000000000'));
        //     expect(await usdt.balanceOf(pair.address)).to.equal('12000000000');

        //     await usdt.transfer(owner.address, 0);
        //     console.log('staked: ' + (await cofixVaultForStaking.balanceOf(pair.address, owner.address)).toString());
        //     console.log('[owner earned]: ' + (await cofixVaultForStaking.earned(pair.address, owner.address)).toString());

        //     expect(await cofixVaultForStaking.balanceOf(pair.address, owner.address)).to.equal('2000000000000000000');
        // }

        // await usdt.transfer(addr1.address, BigInt('5000000000000'));
        // await usdt.connect(addr1).approve(cofixRouter.address, BigInt('10000000000000')); 
        // if (true) {
        //     let receipt = await cofixRouter.connect(addr1).addLiquidityAndStake(
        //         usdt.address,
        //         BigInt('2000000000000000000'),
        //         BigInt('6000000000'),
        //         BigInt('900000000000000000'),
        //         addr1.address,
        //         BigInt('1723207627371'), {
        //             value: BigInt('2010000000000000000')
        //         }
        //     );

        //     let liquidity = await pair.balanceOf(addr1.address);
        //     expect(liquidity).to.equal('0');
        //     expect(await ethers.provider.getBalance(pair.address)).to.equal('6000000000000000000');
        //     expect(await usdt.balanceOf(pair.address)).to.equal('18000000000');

        //     expect(await cofixVaultForStaking.balanceOf(pair.address, addr1.address)).to.equal('2000000000000000000');
        // }

        // console.log('-----------------------');
        // if (true) {
        //     await usdt.transfer(owner.address, 0);
        //     console.log('[owner earned]: ' + (await cofixVaultForStaking.earned(pair.address, owner.address)).toString());
        //     console.log('[addr1 earned]: ' + (await cofixVaultForStaking.earned(pair.address, addr1.address)).toString());
        // }

        // if (true) {
        //     console.log('---- swap ----');
        //     console.log('addr2 balance: ' + (await ethers.provider.getBalance(addr2.address)).toString());
        //     console.log('addr2 usdt:' + (await usdt.balanceOf(addr2.address)).toString());
        //     console.log('addr2 cofi:' + (await cofi.balanceOf(addr2.address)).toString());

        //     let receipt = await cofixRouter.connect(addr2).swapExactETHForTokens(
        //         // 目标token地址
        //         usdt.address,
        //         // eth数量
        //         BigInt('1000000000000000000'),
        //         // 预期获得的token的最小数量
        //         BigInt('100'),
        //         // 接收地址
        //         addr2.address,
        //         // 出矿接收地址
        //         addr2.address,
        //         BigInt('1723207627371'), {
        //             value: BigInt('1010000000000000000')
        //         }
        //     )

        //     console.log('addr2 balance: ' + (await ethers.provider.getBalance(addr2.address)).toString());
        //     console.log('addr2 usdt:' + (await usdt.balanceOf(addr2.address)).toString());
        //     console.log('addr2 cofi:' + (await cofi.balanceOf(addr2.address)).toString());

        //     await usdt.connect(addr2).approve(cofixRouter.address, BigInt('1989514326'));
        //     receipt = await cofixRouter.connect(addr2).swapExactTokensForETH(
        //         usdt.address,
        //         BigInt('1989514326'),
        //         BigInt('100'),
        //         addr2.address,
        //         // 出矿接收地址
        //         addr2.address,
        //         BigInt('1723207627371'), {
        //             value: BigInt('10000000000000000')
        //         }
        //     );

        //     console.log('addr2 balance: ' + (await ethers.provider.getBalance(addr2.address)).toString());
        //     console.log('addr2 usdt:' + (await usdt.balanceOf(addr2.address)).toString());
        //     console.log('addr2 cofi:' + (await cofi.balanceOf(addr2.address)).toString());
        // }
    });
});
