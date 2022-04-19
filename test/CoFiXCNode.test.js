const { expect } = require('chai');
const deployer = require('../scripts/deploy.js');

describe('CoFiXRouter', function() {
    it('test1', async function() {
        const [owner, addr1, addr2] = await ethers.getSigners();
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

        const showReceipt = async function(receipt) {
            console.log({ gasUsed: (await receipt.wait()).gasUsed.toString() });
        }

        const toDecimal = function(bi, decimals) {
            decimals = typeof(decimals) == 'undefined' ? 18 : decimals;
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
            decimals = typeof(decimals) == 'undefined' ? 18 : decimals;
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
                cnode: toDecimal(await cnode.balanceOf(account), 0),
                staked: toDecimal(await cofixVaultForStaking.balanceOf(cnode.address, account), 0),
                earned: toDecimal(await cofixVaultForStaking.earned(cnode.address, account))
            };
        }
        const getStatus = async function() {
            let pairStatus = await getAccountInfo(usdtPair);
            let navps = 0;
            if (pairStatus.eth != '0.000000000000000000' || pairStatus.usdt != '0.000000') {
            let p = await nestPriceFacade.latestPriceView(usdt.address);
                navps = toDecimal(await usdtPair.getNAVPerShare(
                    //await ethers.provider.getBalance(usdtPair.address),
                    //toBigInt(pairStatus.eth), 
                    //toBigInt(pairStatus.usdt, 6), 
                    toBigInt(1), 
                    p.price
                ));
            }
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

        await cnode.transfer(owner.address, 100);
        await cnode.transfer(addr1.address, 20);

        if (true) {
            console.log('1. owner stake 80cnode');
            await cnode.approve(cofixVaultForStaking.address, 100);
            await cofixVaultForStaking.stake(cnode.address, 80);
            status = await getStatus();
            console.log(status);

            console.log('2. Wait 1 block');
            await usdt.transfer(owner.address, 0);
            status = await getStatus();
            console.log(status);

            console.log('3. addr1 stake 20cnode');
            await cnode.connect(addr1).approve(cofixVaultForStaking.address, 30);
            await cofixVaultForStaking.connect(addr1).stake(cnode.address,20);
            status = await getStatus();
            console.log(status);

            console.log('4. Wait 1 block');
            await usdt.transfer(owner.address, 0);
            status = await getStatus();
            console.log(status);
        }

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
            //expect(status.owner.staked).to.equal('0.000000000000000000');
            expect(status.owner.usdt).to.equal('9996000.000000');
        }
        
        if (true) {
            console.log('2. Add 2eth liquidity, will get 2.000000000000000000 xt');
            // 2. Add 2eth liquidity, will get 2.000000000000000000 xt
            let receipt = await cofixRouter.addLiquidityAndStake(
                usdtPair.address,
                usdt.address,
                toBigInt('2.000000000000000000'),
                toBigInt(4000.000000, 6),
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
            expect(status.owner.usdt).to.equal('9992000.000000');

            console.log('Wait 1 block');
            await usdt.transfer(owner.address, 0);
            status = await getStatus();
            console.log(status);
            
            expect(status.owner.xtoken).to.equal(('1.999999999000000000'));
            expect(status.usdtPair.eth).to.equal(('4.000000000000000000'));
            expect(status.usdtPair.usdt).to.equal('8000.000000');
            //expect(status.owner.staked).to.equal('2.000000000000000000');
            expect(status.owner.usdt).to.equal('9992000.000000');
            expect(status.owner.earned).to.equal('1.560000000000000000');
        }

        await usdt.transfer(addr1.address, toBigInt('5000000', 6));
        await usdt.connect(addr1).approve(cofixRouter.address, toBigInt('10000000', 6)); 
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
            expect(status.owner.staked).to.equal('80.');
            expect(status.owner.usdt).to.equal('4992000.000000');
            expect(status.owner.earned).to.equal('2.040000000000000000');

            expect(status.addr1.xtoken).to.equal('0.000000000000000000');
            expect(status.addr1.usdt).to.equal('4996000.000000');
            expect(status.addr1.staked).to.equal('20.');
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
                BigInt('100'),
                addr2.address,
                addr2.address,
                BigInt('1800000000000'), {
                    value: BigInt('1010000000000000000')
                }
            )
            await showReceipt(receipt);
            status = await getStatus();
            console.log(status);
            
            //expect(toDecimal(toBigInt(status.usdtPair.usdt, 6) + toBigInt(status.addr2.usdt, 6), 6)).to.equal('18000.000000');
            // 1. First swap
            // Et = 7
            // k0 = 3000
            // Ut = 15308.204313
            // Pt = 2700
            // 
            // D0 = (7* 3000 - 15308.204313) / (3000 + 2700) = 0.9985606468421052

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
            // 2. Second swap
            // Et = 6.006068035345306275
            // k0 = 3000
            // Ut = 18000.000000
            // Pt = 2700
            // 
            // D1 = (6.006068035345306275* 3000 - 18000.000000) / (3000 + 2700) = 0.003193702813319728
            // 
            // vt = (0.9985606468421052 - 0.003193702813319728)/ 0.9985606468421052 = 0.9968016936943993
            // 
            // X = 0 + 0.9985606468421052 * 0.1 * (2 + 1) = 0.2995681940526316
            // 
            // Zt = 0.2995681940526316 * 0.9968016936943993 = 0.2986100832086356
            // 
            // Yt = 0 + 0.9985606468421052 * 0.1 * (2 + 1) - 0.2986100832086356 = 0.0009581108439959962
            // 
            // mined = 0.2986100832086356 * 0.9 = 0.26874907488777205
            // 
            // cnodeReward = 0.02986100832086356
            // fw = 0.014930504160431781
        }

        if (true) {
            console.log('7. owner getReward');
            let receipt = await cofixVaultForStaking.getReward(usdtPair.address);
            await showReceipt(receipt);
            status = await getStatus();
            console.log(status);

            console.log('8. Wait 1 block')
            await usdt.transfer(owner.address, 0);
            status = await getStatus();
            console.log(status);
        }

        if (true) {
            console.log('9. addr2 swap 1eth for usdt');

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
            
            //expect(toDecimal(toBigInt(status.usdtPair.usdt, 6) + toBigInt(status.addr2.usdt, 6), 6)).to.equal('18000.000000');
            // 3. Third swap
            // Et = 7.006068035345306275
            // k0 = 3000
            // Ut = 15308.204313
            // Pt = 2700
            // 
            // D2 = (7.006068035345306275 * 3000 - 15308.204313) / (3000 + 2700) = 1.0017543496554249
            // 
            // vt = 0
            // 
            // X = 0.0009581108439959962 + 0.003193702813319728 * 0.1 * (3 + 1) = 0.0022355919693238875
            // 
            // Zt = 0.0022355919693238875 * 0 = 0
            // 
            // Yt = 0.0009581108439959962 + 0.003193702813319728 * 0.1 * (3 + 1) - 0 = 0.0022355919693238875
            // 
            // mined = 0 * 0.9 = 0
            // 
            // cnodeReward = 0
            // fw = 0

            await usdt.connect(addr2).approve(cofixRouter.address, BigInt(2687104054));
            console.log('10. addr2 swap 2687.104054 for eth');
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

            // 4. Forth swap
            // Et = 6.012136070690612550
            // k0 = 3000
            // Ut = 18000.000000
            // Pt = 2700
            // 
            // D3 = (6.012136070690612550 * 3000 - 18000.000000) / (3000 + 2700) = 0.006387405626638179
            // 
            // vt = (1.0017543496554249 - 0.006387405626638179) / 1.0017543496554249 = 0.9936237804918588
            // 
            // X = 0.0022355919693238875 + 1.0017543496554249 * 0.1 * (2 + 1) = 0.30276189686595134
            // 
            // Zt = 0.30276189686595134 * 0.9936237804918588 = 0.30083142055283285
            // 
            // Yt = 0.0022355919693238875 + 1.0017543496554249 * 0.1 * (2 + 1) - 0.30083142055283285 = 0.0019304763131184899
            // 
            // mined = 0.30083142055283285 * 0.9 = 0.27074827849754957
            // 
            // cnodeReward = 0.030083142055283285
            // fw = 0.015041571027641643
        }

        if (true) {
            console.log('11. owner withdraw cnode');
            await cofixVaultForStaking.withdraw(cnode.address, 40);
            status = await getStatus();
            console.log(status);

            console.log('12. Wait 1 block')
            await usdt.transfer(owner.address, 0);
            status = await getStatus();
            console.log(status);
        }
    });
});
 