const { expect } = require('chai');
const deployer = require('../scripts/deploy.js');

describe('CoFiXRouter', function() {
    it('test1', async function() {

        const [owner, addr1, addr2] = await ethers.getSigners();
        
        // Deploy contract
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
            nest,
            usdtPair
        } = await deployer.deploy();

        const showReceipt = async function(receipt) {
            console.log({ gasUsed: (await receipt.wait()).gasUsed.toString() });
        }

        const toDecimal = function(bi, decimals) {
            decimals = decimals || 18;
            decimals = BigInt(decimals.toString());
            bi = BigInt(bi.toString());
            let BASE = BigInt(10);
            let r = '';
            while (decimals > 0) {
                let c = (bi % BASE).toString();
                r = c + r;
                bi /= BASE;

                --decimals;
            }
            r = bi.toString() + '.' + r;
            return r;
        }
        const toBigInt = function(val, decimals) {
            decimals = decimals || 18;
            val = parseFloat(val.toString());
            val = val * 1000000;
            decimals -= 6;
            let bi = BigInt(val.toString());
            let BASE = BigInt(10);
            while (decimals > 0) {
                bi *= BASE;
                --decimals;
            }

            return bi;
        }
        const getAccountInfo = async function(account) {
            let acc = account;
            account = account.address;
            return {
                eth: toDecimal(acc.ethBalance ? await acc.ethBalance() : await ethers.provider.getBalance(account)),
                usdt: toDecimal(await usdt.balanceOf(account), 6),
                cofi: toDecimal(await cofi.balanceOf(account)),
                xtoken: toDecimal(await usdtPair.balanceOf(account)),
                staked: toDecimal(await cofixVaultForStaking.balanceOf(usdtPair.address, account)),
                earned: toDecimal(await cofixVaultForStaking.earned(usdtPair.address, account))
            };
        }
        const getStatus = async function() {
            let pairStatus = await getAccountInfo(usdtPair);
            let p = await nestPriceFacade.latestPriceView(usdt.address);
            let navps = toDecimal(await usdtPair.getNAVPerShare(
                //await ethers.provider.getBalance(usdtPair.address),
                //toBigInt(pairStatus.eth), 
                //toBigInt(pairStatus.usdt, 6), 
                toBigInt(1), 
                p.price
            ));
            return {
                height: await ethers.provider.getBlockNumber(),
                navps: navps,
                usdtPair: pairStatus,
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
            console.log('1. Add 2eth liquidity, will get 1.999999999000000000 xt');
            // 1. Add 2eth liquidity, will get 1.999999999000000000 xt
            let receipt = await cofixRouter.addLiquidity(
                usdtPair.address,
                usdt.address,
                toBigInt(2),
                toBigInt(4000, 6),
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
            expect(status.usdtPair.eth).to.equal(('2.000000000000000000'));
            expect(status.usdtPair.usdt).to.equal('4000.000000');
            expect(status.owner.staked).to.equal('0.000000000000000000');
            expect(status.owner.usdt).to.equal('9996000.000000');
        }
        
        if (true) {
            console.log('2. Add 2eth liquidity, will get 2.000000000000000000 xt');
            // 2. Add 2eth liquidity, will get 2.000000000000000000 xt
            let receipt = await cofixRouter.addLiquidityAndStake(
                usdtPair.address,
                usdt.address,
                toBigInt('2.000000000000000000'),
                toBigInt('4000.000000', 6),
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
            expect(status.usdtPair.eth).to.equal(('4.000000000000000000'));
            expect(status.usdtPair.usdt).to.equal('8000.000000');
            expect(status.owner.staked).to.equal('2.000000000000000000');
            expect(status.owner.usdt).to.equal('9992000.000000');

            console.log('Wait 1 block');
            await usdt.transfer(owner.address, 0);
            status = await getStatus();
            console.log(status);
            
            expect(status.owner.xtoken).to.equal(('1.999999999000000000'));
            expect(status.usdtPair.eth).to.equal(('4.000000000000000000'));
            expect(status.usdtPair.usdt).to.equal('8000.000000');
            expect(status.owner.staked).to.equal('2.000000000000000000');
            expect(status.owner.usdt).to.equal('9992000.000000');
            expect(status.owner.earned).to.equal('0.200000000000000000');
        }

        await usdt.transfer(addr1.address, toBigInt(5000000, 6));
        await usdt.connect(addr1).approve(cofixRouter.address, toBigInt(10000000, 6)); 
        if (true) {
            console.log('3. addr1 add 2eth liquidity, will get 2000000000000000000 xt');
            let receipt = await cofixRouter.connect(addr1).addLiquidityAndStake(
                usdtPair.address,
                usdt.address,
                toBigInt('2.000000000000000000'),
                toBigInt(4000.000000, 6),
                toBigInt('0.900000000000000000'),
                addr1.address,
                BigInt('1800000000000'), {
                    value: BigInt('2010000000000000000')
                }
            );
            await showReceipt(receipt);
            status = await getStatus();
            console.log(status);

            expect(status.usdtPair.eth).to.equal(('6.000000000000000000'));
            expect(status.usdtPair.usdt).to.equal('12000.000000');
            expect(status.owner.xtoken).to.equal(('1.999999999000000000'));
            expect(status.owner.staked).to.equal('2.000000000000000000');
            expect(status.owner.usdt).to.equal('4992000.000000');
            expect(status.owner.earned).to.equal('0.800000000000000000');

            expect(status.addr1.xtoken).to.equal('0.000000000000000000');
            //expect(status.addr1.eth).to.equal('6000000000000000000');
            expect(status.addr1.usdt).to.equal('4996000.000000');
            expect(status.addr1.staked).to.equal('2.000000000000000000');
        }

        if (true) {
            console.log('4. Show reward');
            await usdt.transfer(owner.address, 0);
            status = await getStatus();
            console.log(status);
        }

        if (true) {
            console.log('5. addr2 swap 1eth for usdt');

            let receipt = await cofixRouter.connect(addr2).swapExactTokensForTokens(
                ['0x0000000000000000000000000000000000000000', usdt.address],
                BigInt('1000000000000000000'),
                BigInt(100),
                addr2.address,
                addr2.address,
                BigInt('1800000000000'), {
                    value: BigInt('1010000000000000000')
                }
            )
            await showReceipt(receipt);
            status = await getStatus();
            console.log(status);
            
            expect(toDecimal(toBigInt(status.usdtPair.usdt, 6) + toBigInt(status.addr2.usdt, 6), 6)).to.equal('12000.000000');

            await usdt.connect(addr2).approve(cofixRouter.address, BigInt(2687104054));
            console.log('6. addr2 swap 2687.104054 for eth');
            receipt = await cofixRouter.connect(addr2).swapExactTokensForTokens(
                [usdt.address, '0x0000000000000000000000000000000000000000'],
                BigInt(2687104054),
                BigInt(100),
                addr2.address,
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
            console.log('7. withdraw');
            let receipt = await cofixVaultForStaking.withdraw(usdtPair.address, toBigInt(2));
            status = await getStatus();
            console.log(status);

            console.log('8. withdraw');
            console.log({
                nvps: (await usdtPair.getNAVPerShare(toBigInt(1), toBigInt(2700, 6))).toString()
            });
            await usdtPair.approve(cofixRouter.address, toBigInt('10000000'));
            receipt = await cofixRouter.removeLiquidityGetTokenAndETH(
                usdtPair.address,
                //address token,
                usdt.address,
                BigInt('3999999999000000000'),//uint liquidity,
                BigInt(1),//uint amountETHMin,
                owner.address, //address to,
                BigInt('1800000000000'), {
                    value: BigInt('10000000000000000')
                }
            );
            status = await getStatus();
            console.log(status);

            console.log('8. addr1 withdraw');
            receipt = await cofixVaultForStaking.connect(addr1).withdraw(usdtPair.address, toBigInt('2'));
            status = await getStatus();
            console.log(status);

            console.log('9. addr1 withdraw');
            await usdtPair.connect(addr1).approve(cofixRouter.address, toBigInt('10000000'));
            receipt = await cofixRouter.connect(addr1).removeLiquidityGetTokenAndETH(
                usdtPair.address,
                //address token,
                usdt.address,
                BigInt('2000000000000000000'),//uint liquidity,
                BigInt(1),//uint amountETHMin,
                addr1.address, //address to,
                BigInt('1800000000000'), {
                    value: BigInt('10000000000000000')
                }
            );
            status = await getStatus();
            console.log(status);
        }

        if (true) {
            await usdt.approve(cofixRouter.address, toBigInt(1000000));
            let receipt = await cofixRouter.addLiquidity(
                usdtPair.address,
                usdt.address,
                toBigInt(2),
                toBigInt(4000, 6),
                toBigInt(0.9),
                owner.address,
                BigInt('1800000000000'), {
                    value: BigInt('2010000000000000000')
                }
            );
            await showReceipt(receipt);
            status = await getStatus();
            console.log(status);
        }

        //console.log(await cofixRouter.getRouterPath(usdt.address, cofi.address));
    });
});
