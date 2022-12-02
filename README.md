# GOLDX 

The GOLDX token is the native currency of the GoldX blockchain and platform, just like ETH on Ethereum.

#### Table on contents

[Build & Deploy](#build_and_deploy)  
[Wallets](#wallets)  

<a name="build_and_deploy"/>

### Build & Deploy

The following information will guide you through the process of building and deploying the contracts yourself.

<a name="prerequisites"/>

### Prerequisites

- Install [Git](https://git-scm.com/)
- Install [Node.js](https://nodejs.org/en/download/)
- Clone this repository with `git clone https://git.sfxdx.ru/fuseg/fuse-gold-sc.git`
- Navigate to the directory with the cloned code
- Install [Hardhat](https://hardhat.org/) with `npm install --save-dev hardhat`
- Install all required dependencies with `npm install`
- Create a file called `.env` in the root of the project with the same contents as `.env.example`
- Create an account on [BscScan](https://bscscan.com/). Go to `Account -> API Keys`. Create a new API key. Copy it to `.env` file
  ```
  BSCSCAN_API_KEY = ***your BscScan API key***
  ```
- Create an account on [Polygonscan](https://polygonscan.com/). Go to `Account -> API Keys`. Create a new API key. Copy it to `.env` file
  ```
  POLYGONSCAN_API_KEY = ***your PolygonScan API key***
  ```
- Copy your wallet's private key (see [Wallets](#wallets)) to `.env` file
  ```
  ACC_PRIVATE_KEY = ***your private key***
  ```

  :warning:**DO NOT SHARE YOUR .env FILE IN ANY WAY OR YOU RISK TO LOSE ALL YOUR FUNDS**:warning:

### 1. Build

```
npx hardhat compile
```

### 2. Deploy

Start deployment _only_ if build was successful!

#### Testnets

а) **Polygon test** network  
Make sure you have _enough MATIC tokens_ for testnet. You can get it for free from [faucet](https://faucet.polygon.technology/).

```
npx hardhat run scripts/deploy.js --network mumbai
```
b) **BSC test** network
Make sure you have _enough BNB tokens_ for testnet. You can get it for free from [faucet](https://testnet.bnbchain.org/faucet-smart).
```
npx hardhat run scripts/deploy.js --network bsc_testnet
```
#### Mainnets
a) **Polygon** main network  
Make sure you have _enough real MATIC_ in your wallet. Deployment to the mainnet costs money!

```
npx hardhat run scripts/deploy.js --network polygon
```
a) **BSC** main network  
Make sure you have _enough real BNB_ in your wallet. Deployment to the mainnet costs money!

```
npx hardhat run scripts/deploy.js --network bsc
```
Deployment script takes more than 4 minutes to complete. Please, be patient!.

After the contracts get deployed you can find their _addresses_ and code verification _URLs_ in the `deployOutput.json` file.
Note that this file only refreshes the addresses of contracts that have been successfully deployed (or _redeployed_). If you deploy only a single contract then its address will get updated and all other addresses will remain untouched and will link to "old" contracts.
You have to provide these wallets with real/test tokens in order to _call contracts' methods_ from them.  
Please, **do not** write anything to `deployOutput.json` file yourself! It is a read-only file.

Please note that all deployed contracts **are verified** on [BscScan](https://bscscan.com/) or [Polygonscan](https://mumbai.polygonscan.com/)

<a name="wallets"/>

### Wallets

For deployment you will need to use either _your existing wallet_ or _a generated one_.

#### Using existing wallet

If you choose to use your existing wallet, then you will need to be able to export (copy/paste) its private key. For example, you can export private key from your MetaMask wallet.  
Wallet's address and private key should be pasted into the `.env` file (see [Prerequisites](#prerequisites)).

#### Creating a new wallet

If you choose to create a fresh wallet for this project, you should use `createWallet` script from `scripts/` directory.

```
node scripts/createWallet.js
```

This will generate a single new wallet and show its address and private key. **Save** them somewhere else!  
A new wallet _does not_ hold any tokens. You have to provide it with tokens of your choice.  
Wallet's address and private key should be pasted into the `.env` file (see [Prerequisites](#prerequisites)).