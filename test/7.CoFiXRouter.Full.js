const { expect } = require('chai');
const deployer = require('../scripts/deploy.js');

describe('CoFiXRouter', function() {
    it('test1', async function() {

        var [owner, addr1, addr2] = await ethers.getSigners();
        //console.log('owner: ' + owner.address);
        //addr1 = owner;

        // 部署合约
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
            hbtc,
            nest,
            peth,
            pusd,
            usdc,
    
            xeth,
            xpeth,
            xusdt,
            xpusd,
            xusdc,

            usdtPair,
            hbtcPair,
            nestPair,
            cofiPair,
            ethAnchor,
            usdAnchor
        } = await deployer.deploy();

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

        const getXTokenInfo = async function(account, xtoken) {
            return [
                toDecimal(await xtoken.balanceOf(account)), 
                toDecimal(await cofixVaultForStaking.balanceOf(xtoken.address, account)), 
                //toDecimal(await cofixVaultForStaking.earned(xtoken.address, account))
            ];
        }

        const getAccountInfo = async function(account) {
            let acc = account;
            account = account.address;
            return {
                eth: toDecimal(acc.ethBalance ? await acc.ethBalance() : await ethers.provider.getBalance(account)),
                usdt: toDecimal(await usdt.balanceOf(account), 6),
                hbtc: toDecimal(await hbtc.balanceOf(account)),
                nest: toDecimal(await nest.balanceOf(account)),
                cofi: toDecimal(await cofi.balanceOf(account)),
                pusd: toDecimal(await pusd.balanceOf(account)),
                usdc: toDecimal(await usdc.balanceOf(account), 6),
                peth: toDecimal(await peth.balanceOf(account)),
                usdtPair: await getXTokenInfo(account, usdtPair),
                hbtcPair: await getXTokenInfo(account, hbtcPair),
                nestPair: await getXTokenInfo(account, nestPair),
                cofiPair: await getXTokenInfo(account, cofiPair),
                xusdt: await getXTokenInfo(account, xusdt),
                xpusd: await getXTokenInfo(account, xpusd),
                xusdc : await getXTokenInfo(account, xusdc),
                xpeth: await getXTokenInfo(account, peth),
            };
        }
        const getStatus = async function() {
            let pairStatus = await getAccountInfo(usdtPair);
            return {
                height: await ethers.provider.getBlockNumber(),
                //navps: navps,
                usdtPair: pairStatus,
                hbtcPair: await getAccountInfo(hbtcPair),
                nestPair: await getAccountInfo(nestPair),
                cofiPair: await getAccountInfo(cofiPair),
                ethAnchor: await getAccountInfo(ethAnchor),
                usdAnchor: await getAccountInfo(usdAnchor),
                owner: await getAccountInfo(owner),
                addr1: await getAccountInfo(addr1),
                //dao: await getAccountInfo(cofixDAO),
                //addr2: await getAccountInfo(addr2)
            };
        }

        if (true) {
            console.log('0. 设置价格');
            await nestPriceFacade.setPrice(usdt.address, toBigInt(2051, 6), 1);
            await nestPriceFacade.setPrice(nest.address, toBigInt(192307), 1);
        }

        let status;
        let p;

        if (true) {
            console.log('1. 初始化资金');
            await cofi.addMinter(owner.address);
            await usdt.transfer(addr1.address, toBigInt(10000000, 6));
            await hbtc.transfer(addr1.address, toBigInt(10000000));
            await nest.transfer(addr1.address, toBigInt(10000000));
            //await cofi.transfer(addr1.address, toBigInt(10000000));
            await pusd.transfer(addr1.address, toBigInt(10000000));
            await usdc .transfer(addr1.address, toBigInt(10000000));
            await peth.transfer(addr1.address, toBigInt(10000000));
            await cofi.mint(addr1.address, toBigInt(10000000));

            await usdt.transfer(owner.address, toBigInt(10000000, 6));
            await hbtc.transfer(owner.address, toBigInt(10000000));
            await nest.transfer(owner.address, toBigInt(10000000));
            //await cofi.transfer(owner.address, toBigInt(10000000));
            await pusd.transfer(owner.address, toBigInt(10000000));
            await usdc .transfer(owner.address, toBigInt(10000000));
            await peth.transfer(owner.address, toBigInt(10000000));
            await cofi.mint(owner.address, toBigInt(10000000));

            status = await getStatus();
            console.log(status);
        }

        if (true) {
            console.log('2. 做市1eth|usdt');
            await usdt.approve(cofixRouter.address, toBigInt(2000, 6));
            let receipt = await cofixRouter.addLiquidity(
                usdtPair.address,
                usdt.address,
                toBigInt(1),
                toBigInt(2000, 6),
                toBigInt('0.900000000000000000'),
                owner.address,
                BigInt('1800000000000'), {
                    value: BigInt('1010000000000000000')
                }
            );
            showReceipt(receipt);
            status = await getStatus();
            console.log(status);
        }

        if (true) {
            console.log('3. 做市1eth|hbtc');
            await hbtc.approve(cofixRouter.address, toBigInt(0.05));
            let receipt = await cofixRouter.addLiquidity(
                hbtcPair.address,
                hbtc.address,
                toBigInt(1),
                toBigInt(0.05),
                toBigInt('0.900000000000000000'),
                owner.address,
                BigInt('1800000000000'), {
                    value: BigInt('1010000000000000000')
                }
            );
            showReceipt(receipt);
            status = await getStatus();
            console.log(status);
        }

        if (true) {
            console.log('4. 做市1eth|nest');
            await nest.approve(cofixRouter.address, toBigInt(100000));
            let receipt = await cofixRouter.addLiquidity(
                nestPair.address,
                nest.address,
                toBigInt(1),
                toBigInt(100000),
                toBigInt('0.900000000000000000'),
                owner.address,
                BigInt('1800000000000'), {
                    value: BigInt('1010000000000000000')
                }
            );
            showReceipt(receipt);
            status = await getStatus();
            console.log(status);
        }

        if (true) {
            console.log('5. 做市1eth|cofi');
            await cofi.approve(cofixRouter.address, toBigInt(2000));
            let receipt = await cofixRouter.addLiquidity(
                cofiPair.address,
                cofi.address,
                toBigInt(1),
                toBigInt(2000),
                toBigInt('0.900000000000000000'),
                owner.address,
                BigInt('1800000000000'), {
                    value: BigInt('1010000000000000000')
                }
            );
            showReceipt(receipt);
            status = await getStatus();
            console.log(status);
        }

        if (true) {
            console.log('6. 做市1eth');
            let receipt = await cofixRouter.addLiquidity(
                ethAnchor.address,
                '0x0000000000000000000000000000000000000000',
                toBigInt(0),
                toBigInt(1),
                toBigInt('0.900000000000000000'),
                owner.address,
                BigInt('1800000000000'), {
                    value: BigInt('1010000000000000000')
                }
            );
            showReceipt(receipt);
            status = await getStatus();
            console.log(status);
        }

        if (true) {
            console.log('7. 做市1peth');
            await peth.approve(cofixRouter.address, toBigInt(1));
            let receipt = await cofixRouter.addLiquidity(
                ethAnchor.address,
                peth.address,
                toBigInt(0),
                toBigInt(1),
                toBigInt('0.900000000000000000'),
                owner.address,
                BigInt('1800000000000'), {
                    value: BigInt('10000000000000000')
                }
            );
            showReceipt(receipt);
            status = await getStatus();
            console.log(status);
        }

        if (true) {
            console.log('8. 做市2000usdt');
            await usdt.approve(cofixRouter.address, toBigInt(2000, 6));
            let receipt = await cofixRouter.addLiquidity(
                usdAnchor.address,
                usdt.address,
                toBigInt(0),
                toBigInt(2000, 6),
                toBigInt('0.900000000000000000'),
                owner.address,
                BigInt('1800000000000'), {
                    value: BigInt('10000000000000000')
                }
            );
            showReceipt(receipt);
            status = await getStatus();
            console.log(status);
        }

        if (true) {
            console.log('9. 做市2000pusd');
            await pusd.approve(cofixRouter.address, toBigInt(2000));
            let receipt = await cofixRouter.addLiquidity(
                usdAnchor.address,
                pusd.address,
                toBigInt(0),
                toBigInt(2000),
                toBigInt('0.900000000000000000'),
                owner.address,
                BigInt('1800000000000'), {
                    value: BigInt('10000000000000000')
                }
            );
            showReceipt(receipt);
            status = await getStatus();
            console.log(status);
        }

        if (true) {
            console.log('10. 做市2000usdc');
            await usdc.approve(cofixRouter.address, toBigInt(2000));
            let receipt = await cofixRouter.addLiquidity(
                usdAnchor.address,
                usdc.address,
                toBigInt(0),
                toBigInt(2000),
                toBigInt('0.900000000000000000'),
                owner.address,
                BigInt('1800000000000'), {
                    value: BigInt('10000000000000000')
                }
            );
            showReceipt(receipt);
            status = await getStatus();
            console.log(status);
        }

        if (true) {
            console.log('11. 路由兑换1000usdt');
            let path = [
                usdt.address,
                '0x0000000000000000000000000000000000000000',
                peth.address,
                '0x0000000000000000000000000000000000000000',
                usdt.address,
                usdc.address,
                pusd.address,
                usdt.address,
                '0x0000000000000000000000000000000000000000',
                cofi.address,
                '0x0000000000000000000000000000000000000000',
                nest.address,
                '0x0000000000000000000000000000000000000000',
                usdt.address
            ];
            await usdt.connect(addr1).approve(cofixRouter.address, toBigInt(1000, 6));
            let receipt = await cofixRouter.connect(addr1).swapExactTokensForTokens(
                path,
                toBigInt(1000, 6),
                0,
                addr1.address,
                addr1.address,
                BigInt('1800000000000'), {
                    value: BigInt('80000000000000000')
                }
            );
            showReceipt(receipt);
            status = await getStatus();
            console.log(status);
        }

        if (true) {
            console.log('12. 交易0pusd');
            await pusd.connect(addr1).transfer(usdAnchor.address, toBigInt(2));
            await pusd.connect(addr1).approve(cofixRouter.address, toBigInt(0));
            let receipt = await cofixRouter.connect(addr1).swapExactTokensForTokens(
                [pusd.address, usdt.address],
                toBigInt(0),
                0,
                addr1.address,
                addr1.address,
                BigInt('1800000000000'), {
                    value: BigInt('0000000000000000')
                }
            );
            showReceipt(receipt);
            status = await getStatus();
            console.log(status);
            await usdAnchor.connect(addr1).skim();
            status = await getStatus();
            console.log(status);
        }

        let ci = await cofixVaultForStaking.getChannelInfo(cnode.address);
        console.log({
            totalStaked: ci.totalStaked.toString(),
            cofiPerBlock: ci.cofiPerBlock.toString()
        });
    });
});
