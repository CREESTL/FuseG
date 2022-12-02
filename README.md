## FUSE GOLD

### Installation

Clone repo and run

```
npm install
```

Create .env file

```
ACC_PRIVATE_KEY = <YOUR PRIVATE KEY>
BSCSCAN_API_KEY = <API_KEY_FOR_BSCSCAN>
POLYGONSCAN_API_KEY = <API_KEY_FOR_POLYGONSCAN>
```

### Run tests

```
npx hardhat test
```

Or

```
npx hardhat test test/<test name>
```

to run specific test (e.g. npx hardhat test test/test_RewardVault.js)
