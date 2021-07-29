# CoFiX-V2.1
CoFiX Dapp is the most efficient Token Swap on Ethereum. Traders always get market prices at the smallest spread. Reversing trade in CoFiX can mining COFI Tokens by hedging.

![](https://img.shields.io/github/issues/Computable-Finance/CoFiX-V2.1)
![](https://img.shields.io/github/forks/Computable-Finance/CoFiX-V2.1)
![](https://img.shields.io/github/stars/Computable-Finance/CoFiX-V2.1)
![](https://img.shields.io/github/license/Computable-Finance/CoFiX-V2.1)
![](https://img.shields.io/twitter/url?url=https%3A%2F%2Fgithub.com%2FComputable-Finance%2FCoFiX-V2.1)

## Whitepaper

**[https://cofix.io/doc/CoFiX_White_Paper.pdf](https://cofix.io/doc/CoFiX_White_Paper.pdf)**

## Documents

**[CoFiX v2.1 Contract Specification](docs/readme.md)**

**[CoFiX v2.1 Contract Structure Diagram](docs/CoFiX2.1.svg)**

**[CoFiX v2.1 Application Scenarios](docs/readme.md#5-application-scenarios)**

**[Learn More...](https://docs.cofix.io/)**

**[Goto](https://cofix.tech/)**

## Usage

### Run test

```shell
npm install

npx hardhat test
```

### Compile

Run `npx hardhat compile`, get build results in `artifacts/contracts` folder, including `ABI` json files.

### Deploy

Deploy with `hardhat` and you will get a contract deployment summary on contract addresses.

```shell
npx hardhat test ./test/deploy.js --network rinkeby
```

## Contract Addresses

### 2021-07-20@mainnet
| Name | Interfaces | mainnet |
| ---- | ---- | ---- |
| usdt | IERC20 | 0xdAC17F958D2ee523a2206206994597C13D831ec7 |
| hbtc | IERC20 | 0x0316EB71485b0Ab14103307bf65a021042c6d380 |
| peth | IERC20 | 0x53f878Fb7Ec7B86e4F9a0CB1E9a6c89C0555FbbD |
| pusd | IERC20 | 0xCCEcC702Ec67309Bc3DDAF6a42E9e5a6b8Da58f0 |
| usdc | IERC20 | 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48 |
| nest | IERC20 | 0x04abEdA201850aC0124161F037Efd70c74ddC74C |
| nestPriceFacade | INestPriceFacade, INestQuery | 0xB5D2890c061c321A5B6A4a4254bb1522425BAF0A |
| cnode | IERC20 | 0x558201DC4741efc11031Cdc3BC1bC728C23bF512 |
| cofi | IERC20 | 0x1a23a6BfBAdB59fa563008c0fB7cf96dfCF34Ea1 |
| cofixGovernance | ICoFiXGovernance | 0xa0376c279940b26d1D8D03eaB5a3d8bD3F6b0DD4 |
| cofixDAO | ICoFiXDAO | 0x2Cf06Aa521DD979Bc1b50ce44590A09db21d6A74 |
| cofixRouter | ICoFiXRouter | 0x57F0A4ef374B35eb32B61Dd8bc68C58e886CFC84 |
| cofixVaultForStaking | ICoFiXVaultForStaking | 0x7Bd4546DEdB397a0f0D7593A7Fa7f2Ceb3ff32E6 |
| cofixController | ICoFiXController | 0x8eFFbf9CA7dB20481cE9C25EA4B410b3B835D70E |
| CoFiXPair-usdt | ICoFiXPair, ICoFiXERC20 | 0xFa8055B3e0C36605bB31e23bC565C31eb3Dca386 |
| CoFiXPair-hbtc | ICoFiXPair, ICoFiXERC20 | 0xd312E8374fF2B0260A32aF5f91BA8d8EaFAE856B |
| CoFiXPair-nest | ICoFiXPair, ICoFiXERC20 | 0x2FA6F2d5e42630e872cD0F33C69D1c2708FF79Fd |
| CoFiXPair-cofi | ICoFiXPair, ICoFiXERC20 | 0x711EA25b70Bb580a7cb19DeBd0ab40A016c3fCbb |
| CoFiXAnchorPool-eth | ICoFiXAnchorPool | 0xD7E54D936ca1e7F0ed097D4Ec6140653eC60f85D |
| CoFiXAnchorPool-usd | ICoFiXAnchorPool | 0x31Aa5da47Cf6FBB203531D88e3FC47d46AE6D46b |
| xeth | ICoFiXERC20 | 0xB6e9B1D8814DA83a663832822765fc4d4008Fd97 |
| xpeth | ICoFiXERC20 | 0xAB53A40e3153901c761CE55EfA5F0789dbD5F047 |
| xusdt | ICoFiXERC20 | 0x172b260F92d1A0661e9888918a19154E99E0B9f0 |
| xpusd | ICoFiXERC20 | 0x2b06Af945F1c18A6bf02ac6E401Fd251d9FfdBCf |
| xusdc | ICoFiXERC20 | 0xF5beBE517eb95557CBcFd19a2BAfa8e9fC50C5EE |

### 2021-07-20@rinkeby
| Name | Interfaces | rinkeby |
| ---- | ---- | ---- |
| nestPriceFacade | INestPriceFacade, INestQuery | 0x40C3EB032f27fDa7AdcF1B753c75B84e27f26838 |
| usdt | IERC20 | 0x20125a7256EFafd0d4Eec24048E08C5045BC5900 |
| hbtc | IERC20 | 0xaE73d363Cb4aC97734E07e48B01D0a1FF5D1190B |
| peth | IERC20 | 0xd5Dfe6355EeBE918a23d70f5399Bb08F8a1BD588 |
| pusd | IERC20 | 0x01A8088947B1222a5dC5a13C45b845E0361EEFF7 |
| usdc | IERC20 | 0xFe027e6243Cd9b94772fA07c0b5fcD3D03D55c92 |
| nest | IERC20 | 0xE313F3f49B647fBEDDC5F2389Edb5c93CBf4EE25 |
| cnode | IERC20 | 0xa818c471Ab162a1d7669Ab04b023Ebac38DDCA64 |
| cofi | IERC20 | 0x6b3077dcEe0975017BDd1a7eA9E12d3D9F398695 |
| cofixGovernance | ICoFiXGovernance | 0x6843dA9a5DB73f68dDC97079fEeaaC6ca474EcbF |
| cofixDAO | ICoFiXDAO | 0x1F4B92d91D803c6f90A36A01168721d048E2b0d6 |
| cofixRouter | ICoFiXRouter | 0xD2A6D4744027aBCE6781955674ffc04DcdEA7570 |
| cofixVaultForStaking | ICoFiXVaultForStaking | 0xf952Cb518BD7F72F600c6aEA0A8CcFBeabe7c9C0 |
| cofixController | ICoFiXController | 0xC18B1feb7F41521cDAaa4ad5E0e5a8c54D0FF4a5 |
| CoFiXPair-usdt | ICoFiXPair, ICoFiXERC20 | 0x5930c58d71b83bc4586D13f5767aa921ca8B4143 |
| CoFiXPair-hbtc | ICoFiXPair, ICoFiXERC20 | 0xF91809d869082DaEc8ed4fa36cB9423C2132726B |
| CoFiXPair-nest | ICoFiXPair, ICoFiXERC20 | 0x9eD5c27a4527927a4eF8cAa36547CAb502631A69 |
| CoFiXPair-cofi | ICoFiXPair, ICoFiXERC20 | 0xF3Ef9e8Cbdd0424E0B152709358749155697C2d6 |
| CoFiXAnchorPool-eth | ICoFiXAnchorPool | 0x6Bba09C78b7CB6f559341BfFacCF19f5FD8AdAE6 |
| CoFiXAnchorPool-usd | ICoFiXAnchorPool | 0x4Ac7ea8AfF091D12C38b5A7Cf049482298656DE6 |
| xeth | ICoFiXERC20 | 0xF6992866092c2E85711aedBCDcEDa7ceE6eBbdb1 |
| xpeth | ICoFiXERC20 | 0x4034e0afC49f6ed8bE2E144A5240DaA993C87F88 |
| xusdt | ICoFiXERC20 | 0x927e7d1deaC7C2c9bCB74Df28e62eA8e7d3dDF18 |
| xpusd | ICoFiXERC20 | 0xB9a8cD49ba5BA661c490cFeADAC50A76b0c37367 |
| xusdc | ICoFiXERC20 | 0x6683fBE911E71EEd849e2225E8FAe6CF9F8AAC9a |

### 2021-07-16@rinkeby
| Name | Interfaces | rinkeby |
| ---- | ---- | ---- |
| nestPriceFacade | INestPriceFacade, INestQuery | 0x40C3EB032f27fDa7AdcF1B753c75B84e27f26838 |
| cnode | IERC20 | 0xa818c471Ab162a1d7669Ab04b023Ebac38DDCA64 |
| usdt | IERC20 | 0x20125a7256EFafd0d4Eec24048E08C5045BC5900 |
| nest | IERC20 | 0xE313F3f49B647fBEDDC5F2389Edb5c93CBf4EE25 |
| cofi | IERC20 | 0xBd98Ec485d7f54979FC0Ef19365ABFFC63099755 |
| peth | IERC20 | 0xd5Dfe6355EeBE918a23d70f5399Bb08F8a1BD588 |
| pusd | IERC20 | 0x01A8088947B1222a5dC5a13C45b845E0361EEFF7 |
| usdc | IERC20 | 0xFe027e6243Cd9b94772fA07c0b5fcD3D03D55c92 |
| cofixGovernance | ICoFiXGovernance | 0xAc12D0CbA1E1a2ffb34326115c2A9926435Dd694 |
| CoFiXPair-usdt | ICoFiXPair, ICoFiXERC20 | 0x7756f374E19E1528454B5291282D6C9e33eCBC69 |
| CoFiXPair-nest | ICoFiXPair, ICoFiXERC20 | 0xEC38914c82969716C5E271a63087D365B0E259b2 |
| CoFiXPair-cofi | ICoFiXPair, ICoFiXERC20 | 0x47380B7cd1a7c482Bc2416FB0171AD2A10c8258A |
| cofixDAO | ICoFiXDAO | 0xCD0E336D483511840D3002E4aE1518bd3681cdaC |
| cofixRouter | ICoFiXRouter | 0xFd759970c8B4A6EfE5525EA9A03732Ef04F1C5F4 |
| cofixController | ICoFiXController | 0xEf1673bda89C0c1827680467BdfB6d22F18F8498 |
| cofixVaultForStaking | ICoFiXVaultForStaking | 0x974E819Fa74683c3dAc7C4bc4041d6B2E042e1D7 |
| CoFiXAnchorPool-eth | ICoFiXAnchorPool | 0xA5fF74B6BcF816AA3e13857a68c231DE6EEAF4eA |
| CoFiXAnchorPool-usd | ICoFiXAnchorPool | 0x5Ed0d53442415BE2Ac4d1bA5e289721c4e3A8ce1 | 
| xeth | ICoFiXERC20 | 0xEb780f8711A0D99DA20B05A5C5c903D8E1091834 |
| xpeth | ICoFiXERC20 | 0x6f67bF655225D32a1a0d9fbE25147259cBAA917c |
| xusdt | ICoFiXERC20 | 0x38967b00B27629E0a944D8004b18b97A203d6d49 |
| xpusd | ICoFiXERC20 | 0x670aa8399aF49620AB542Dc1d71a3Cd1662a92fd |
| xusdc | ICoFiXERC20 | 0xb6c01dF109bE84d29Ef570f8D2FBEa00413681F2 |

### 2021-07-02@rinkeby
| Name | Interfaces | rinkeby |
| ---- | ---- | ---- |
| cnode | IERC20 | 0x6E9c1edACe6Fc03f9666769f09D557b1383f7F57 |
| usdt | IERC20 | 0x0f4014fbA3D4fcb56d2653Bf3d51664dCcCF42f6 |
| nest | IERC20 | 0x4c6DC3Fa867c3c96B1C8F51CE7Fa975b886d882f |
| cofi | IERC20 | 0x4c4F8Bfa7835089D176C1ec24e845f784F3045c1 |
| peth | IERC20 | 0x885629c3784C4e7cEaa82b83F3aeD2F991d197C6 |
| weth | IERC20 | 0x628b25c7658287c2829EE7a3E5D34b0158d2fdB5 |
| pusd | IERC20 | 0x0f03cd5CeBe21D1E7307588b9844D10ad0F4A394 |
| usdc | IERC20 | 0xe86dD41fEb8594D083f9dC364e530c0B8D208feA |
| cofixGovernance | ICoFiXGovernance | 0x9964C60E19FA2F5426821643a5195920cE83f454 |
| CoFiXPair-usdt | ICoFiXPair, ICoFiXERC20 | 0xb7719040D4357A2a58D1293a52511b57bCbd533D |
| CoFiXPair-nest | ICoFiXPair, ICoFiXERC20 | 0x91025AF7C4699473C9f9Cae7876c86e4ef715107 |
| cofixDAO | ICoFiXDAO | 0xba7ba7e89ad593727e3eF694e5c9Db1C9f95B58d |
| cofixRouter | ICoFiXRouter | 0x2651171EeB0Ec9357c27A8CdB8B7dF4500534F34 |
| cofixController | ICoFiXController | 0x45456aE6aCD697F9661a962716e105393d4CF8c4 |
| cofixVaultForStaking | ICoFiXVaultForStaking | 0x6075560428330b0DeE19F6D5606d564E0B768cd6 |
| CoFiXAnchorPool-eth | ICoFiXPool | 0xbbd6b432B280dea51f137F8234a5D0Ac36D17fdf |
| CoFiXAnchorPool-usd | ICoFiXPool | 0x08B79267ff01393925081396b328B6d6f82a4250 |
| xeth | ICoFiXERC20 | 0x1Be9CdBbf78389D2075F528730B87b82551A59D7 |
| xpeth | ICoFiXERC20 | 0x0FC0551C43915b652b646b277d883B8aC2Cd3C58 |
| xweth | ICoFiXERC20 | 0x0Ea19Bf07e6F09124CeefbDBa41C9c0e58430316 |
| xusdt | ICoFiXERC20 | 0xbff7C46F7825207A3e9cF8C459f2410C7e38aF43 |
| xpusd | ICoFiXERC20 | 0x08cD68990E084eD3FC4f7bF18b119F5581D2bAf6 |
| xusdc | ICoFiXERC20 | 0xC9F6c5a57451d39AC4F19F81B35A569714C87a93 |

### 2021-06-28@rinkeby
| Name | Interfaces | rinkeby |
| ---- | ---- | ---- |
| cnode | IERC20 | 0x5F22b973c29d739a12a0d20CEf99fa10b3A558df |
| usdt | IERC20 | 0x34deF4DF57ED33eDbE5d04bC49623659a553404e |
| nest | IERC20 | 0x8B4F5e0a3727877ff0850De5c9C1e54d0B7a85B4 |
| cofi | IERC20 | 0x309291F40D714304A490F9A6E3A82F51Ae94962F |
| peth | IERC20 | 0x3FEf64736355F71981bcACB0Cc635474aDef3ad6 |
| weth | IERC20 | 0x952Aba2A2F467AEE76fAE49A17C88e52FFa10C2a |
| pusd | IERC20 | 0xe6CdD2c0F48dCfaB1E4a8bcBb4e2001F671fe0e2 |
| usdc | IERC20 | 0x46A7783AcA0b65073Ba51e52B73f252A261a909d |
| CoFiXPair-usdt | ICoFiXPair, ICoFiXERC20 | 0xf0ad5176dc1864962874Fd3817A835f8142BEa80 |
| CoFiXPair-nest | ICoFiXPair, ICoFiXERC20 | 0xeDE17c63CA92608eD8864A7ef730994C80c27517 |
| cofixGovernance | ICoFiXGovernance | 0xb485aefBc9726d723EcDa8f3764Ab0a25144f3da |
| cofixDAO | ICoFiXDAO | 0x9338C665A487714143B079b36Bb4446bC06aeBd8 |
| cofixRouter | ICoFiXRouter | 0xfCf2FF43915E655029517735846a22d245F707C7 |
| cofixController | ICoFiXController | 0xE6C743CF3ffc2126cFdc3b3D802235981F3d9227 |
| cofixVaultForStaking | ICoFiXVaultForStaking | 0x8d5c87F6ec179Ab29c8698001B5ec9e372281EA3 |
| CoFiXAnchorPool-eth | ICoFiXPool | 0xb57009B96FdD4863ef5D446Cd2E70FCF7747B606 |
| CoFiXAnchorPool-usd | ICoFiXPool | 0x71dd3d064b2d5975281A2992e3fC59467d936B92 |
| xeth | ICoFiXERC20 | 0x95C67FE9D28585e6ce468832149faf2392863Dc5 |
| xpeth | ICoFiXERC20 | 0x6620B963d98f7090E333608DfB1CC94979AC7586 |
| xweth | ICoFiXERC20 | 0x7A7F4122CF4d86eDA89d36d33EC9EB5c3fc43176 |
| xusdt | ICoFiXERC20 | 0x702F25CaC493F61584F00Db28b1095a6FFd5e023 |
| xpusd | ICoFiXERC20 | 0x4Eae4727BF3164cffdC2185F30A708CfdC6C20D2 |
| xusdc | ICoFiXERC20 | 0x802615556bE65f05C587C548eDF622726Bce7a63 |