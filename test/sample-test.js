// const { expect } = require("chai");

// describe("Greeter", function() {
//     it("Should return the new greeting once it's changed", async function() {
//         const [owner, addr1] = await ethers.getSigners();
//         console.log('owner=' + owner.address);
//         const Greeter = await ethers.getContractFactory("Greeter");
//         const greeter = await Greeter.deploy("Hello, world!");
        
//         await greeter.deployed();
//         expect(await greeter.greet()).to.equal("Hello, world!");

//         await greeter.setGreeting("Hola, mundo!");
//         expect(await greeter.greet()).to.equal("Hola, mundo!");

//         const ERC20 = await hre.ethers.getContractFactory("_ERC20");
//         const erc20 = await ERC20.deploy();

//         await erc20.mint(9527);
//         console.log('balance=' + await erc20.balanceOf(owner.address));

//         const CoFiXPair = await ethers.getContractFactory("CoFiXPair");
//         const pair = await CoFiXPair.deploy(erc20.address);

//         console.log('balance0=', (await pair.balance0()).toString());
//         console.log('balance1=', (await pair.balance1()).toString());

        
//         let r1 = await pair.balance1T();
//         console.log('r1==');
//         console.log((await r1.wait()).gasUsed.toString());

//         let r0 = await pair.balance0T();
//         console.log('r0==');
//         console.log((await r0.wait()).gasUsed.toString());
//     });
// });
