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
            usdt,
            pair
        } = await deployer.deploy();

        const showReceipt = async function(receipt) {
            console.log({ gasUsed: (await receipt.wait()).gasUsed.toString() });
        }

        const toDecimal = function(bi, decimals) {
            decimals = decimals || 18;
            decimals = BigInt(decimals.toString());
            bi = BigInt(bi.toString());
            let BASE = BigInt('10');
            // let base = BigInt('1');
            // while (decimals > BigInt('0')) {
            //     base *= BigInt('10');
            //     --decimals;            
            // }
            
            // let left = bi / base;
            // let right = bi % base;
            // return left + '.' + right;
            let r = '';
            while (decimals > 0) {
                let c = (bi % BASE).toString();
                //if (c != '0' || r != '') {
                //    r = c + r;
                //}
                r = c + r;
                bi /= BASE;

                --decimals;
            }

            // if (r == '') {
            //     r = bi.toString();
            // } else {
            //     r = bi.toString() + '.' + r;
            // }
            r = bi.toString() + '.' + r;
            return r;
        }
        const toBigInt = function(val, decimals) {
            decimals = decimals || 18;
            val = parseFloat(val.toString());
            val = val * 1000000;
            decimals -= 6;
            let bi = BigInt(val.toString());
            let BASE = BigInt('10');
            while (decimals > 0) {
                bi *= BASE;
                --decimals;
            }

            return bi;
        }
        const getAccountInfo = async function(account) {
            account = account.address;
            return {
                eth: toDecimal(await ethers.provider.getBalance(account)),
                usdt: toDecimal(await usdt.balanceOf(account), 6),
                cofi: toDecimal(await cofi.balanceOf(account)),
                xtoken: toDecimal(await pair.balanceOf(account)),
                staked: toDecimal(await cofixVaultForStaking.balanceOf(pair.address, account)),
                earned: toDecimal(await cofixVaultForStaking.earned(pair.address, account))
            };
        }
        const getStatus = async function() {
            let pairStatus = await getAccountInfo(pair);
            let p = await cofixController.latestPriceView(usdt.address);
            let navps = toDecimal(await pair.calcNAVPerShare(
                await ethers.provider.getBalance(pair.address),
                //toBigInt(pairStatus.eth), 
                toBigInt(pairStatus.usdt, 6), 
                toBigInt(1), 
                p.price
            ));
            return {
                height: await ethers.provider.getBlockNumber(),
                navps: navps,
                pair: pairStatus,
                owner: await getAccountInfo(owner),
                addr1: await getAccountInfo(addr1),
                addr2: await getAccountInfo(addr2)
            };
        }

        let status;
        let p;
        await usdt.transfer(owner.address, toBigInt(10000000, 6));
        await usdt.approve(cofixRouter.address, toBigInt(10000000, 6));
        if (true) {
            console.log('1. 添加2eth的流动性，预期获得1.999999999000000000份额');
            // 1. 添加2eth的流动性，预期获得1.999999999000000000份额
            let receipt = await cofixRouter.addLiquidity(
                usdt.address,
                toBigInt(2),
                toBigInt(6000, 6),
                toBigInt(0.9),
                owner.address,
                BigInt('1800000000000'), {
                    value: BigInt('2010000000000000000')
                }
            );
            await showReceipt(receipt);

            status = await getStatus();
            console.log(status);

            expect(status.owner.xtoken).to.equal(('1.999999999000000000'));
            expect(status.pair.eth).to.equal(('2.000000000000000000'));
            expect(status.pair.usdt).to.equal('6000.000000');
            expect(status.owner.staked).to.equal('0.000000000000000000');
            expect(status.owner.usdt).to.equal('9994000.000000');
        }
        
        if (true) {
            console.log('2. 添加2eth的流动性并存入收益池，预期获得2.000000000000000000份额');
            // 2. 添加2eth的流动性并存入收益池，预期获得2.000000000000000000份额
            let receipt = await cofixRouter.addLiquidityAndStake(
                usdt.address,
                toBigInt('2.000000000000000000'),
                toBigInt('6000.000000', 6),
                toBigInt('0.900000000000000000'),
                owner.address,
                BigInt('1800000000000'), {
                    value: BigInt('2010000000000000000')
                }
            );
            await showReceipt(receipt);

            status = await getStatus();
            console.log(status);

            expect(status.owner.xtoken).to.equal(('1.999999999000000000'));
            expect(status.pair.eth).to.equal(('4.000000000000000000'));
            expect(status.pair.usdt).to.equal('12000.000000');
            expect(status.owner.staked).to.equal('2.000000000000000000');
            expect(status.owner.usdt).to.equal('9988000.000000');

            console.log('等待一个区块后');
            await usdt.transfer(owner.address, 0);
            status = await getStatus();
            console.log(status);
            
            expect(status.owner.xtoken).to.equal(('1.999999999000000000'));
            expect(status.pair.eth).to.equal(('4.000000000000000000'));
            expect(status.pair.usdt).to.equal('12000.000000');
            expect(status.owner.staked).to.equal('2.000000000000000000');
            expect(status.owner.usdt).to.equal('9988000.000000');
            expect(status.owner.earned).to.equal('6.000000000000000000');
        }

        await usdt.transfer(addr1.address, toBigInt('5000000', 6));
        await usdt.connect(addr1).approve(cofixRouter.address, toBigInt('10000000', 6)); 
        if (true) {
            console.log('3. addr1添加2eth的流动性并存入收益池，预期获得2000000000000000000份额');
            let receipt = await cofixRouter.connect(addr1).addLiquidityAndStake(
                usdt.address,
                toBigInt('2.000000000000000000'),
                toBigInt('6000.000000', 6),
                toBigInt('0.900000000000000000'),
                addr1.address,
                BigInt('1800000000000'), {
                    value: BigInt('2010000000000000000')
                }
            );
            await showReceipt(receipt);
            status = await getStatus();
            console.log(status);

            expect(status.pair.eth).to.equal(('6.000000000000000000'));
            expect(status.pair.usdt).to.equal('18000.000000');
            expect(status.owner.xtoken).to.equal(('1.999999999000000000'));
            expect(status.owner.staked).to.equal('2.000000000000000000');
            expect(status.owner.usdt).to.equal('4988000.000000');
            expect(status.owner.earned).to.equal('6.600000000000000000');

            expect(status.addr1.xtoken).to.equal('0.000000000000000000');
            //expect(status.addr1.eth).to.equal('6000000000000000000');
            expect(status.addr1.usdt).to.equal('4994000.000000');
            expect(status.addr1.staked).to.equal('2.000000000000000000');
        }

        if (true) {
            console.log('4. 查看收益');
            await usdt.transfer(owner.address, 0);
            status = await getStatus();
            console.log(status);
        }

        if (true) {
            console.log('5. addr2使用1eth兑换usdt');

            let receipt = await cofixRouter.connect(addr2).swapExactETHForTokens(
                // 目标token地址
                usdt.address,
                // eth数量
                BigInt('1000000000000000000'),
                // 预期获得的token的最小数量
                BigInt('100'),
                // 接收地址
                addr2.address,
                // 出矿接收地址
                addr2.address,
                BigInt('1800000000000'), {
                    value: BigInt('1010000000000000000')
                }
            )
            await showReceipt(receipt);
            status = await getStatus();
            console.log(status);
            
            expect(toDecimal(toBigInt(status.pair.usdt, 6) + toBigInt(status.addr2.usdt, 6), 6)).to.equal('18000.000000');

            await usdt.connect(addr2).approve(cofixRouter.address, BigInt('2691795687'));
            console.log('6. addr2使用2691.795687兑换eth');
            receipt = await cofixRouter.connect(addr2).swapExactTokensForETH(
                usdt.address,
                BigInt('2691795687'),
                BigInt('100'),
                addr2.address,
                // 出矿接收地址
                addr2.address,
                BigInt('1800000000000'), {
                    value: BigInt('10000000000000000')
                }
            );
            await showReceipt(receipt);

            status = await getStatus();
            console.log(status);
        }

        if (true) {
            console.log('7. unstake');
            let receipt = await cofixVaultForStaking.unstake(pair.address, toBigInt('2'));
            status = await getStatus();
            console.log(status);

            console.log('8. 取回流动性');
            await pair.approve(cofixRouter.address, toBigInt('10000000'));
            receipt = await cofixRouter.removeLiquidityGetTokenAndETH(
                // 要移除的token对
                //address token,
                usdt.address,
                // 移除的额度
                BigInt('3999999999000000000'),//uint liquidity,
                // 预期最少可以获得的eth数量
                BigInt('1'),//uint amountETHMin,
                // 接收地址
                owner.address, //address to,
                // 截止时间
                BigInt('1800000000000'), {
                    value: BigInt('10000000000000000')
                }
            );
            status = await getStatus();
            console.log(status);

            console.log('8. addr1 unstake');
            receipt = await cofixVaultForStaking.connect(addr1).unstake(pair.address, toBigInt('2'));
            status = await getStatus();
            console.log(status);

            console.log('9. addr1 取回流动性');
            await pair.connect(addr1).approve(cofixRouter.address, toBigInt('10000000'));
            receipt = await cofixRouter.connect(addr1).removeLiquidityGetTokenAndETH(
                // 要移除的token对
                //address token,
                usdt.address,
                // 移除的额度
                BigInt('2000000000000000000'),//uint liquidity,
                // 预期最少可以获得的eth数量
                BigInt('1'),//uint amountETHMin,
                // 接收地址
                addr1.address, //address to,
                // 截止时间
                BigInt('1800000000000'), {
                    value: BigInt('10000000000000000')
                }
            );
            status = await getStatus();
            console.log(status);
        }
    });
});
