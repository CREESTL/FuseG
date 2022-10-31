require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");
require("dotenv").config();

const {
        BSCSCAN_API_KEY,
        POLYGONSCAN_API_KEY,
        ACC_PRIVATE_KEY,
    } = process.env;

module.exports = {
  solidity: {
    version: "0.8.9",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    hardhat: {
      allowUnlimitedContractSize: true,
    },
    localhost: {
      url: "http://127.0.0.1:8545",
    },
    bsc_testnet: {
      url: 'https://data-seed-prebsc-1-s1.binance.org:8545/',
      accounts: [ACC_PRIVATE_KEY]
    },
    bsc: {
      url: "https://rpc.ankr.com/bsc",
      accounts: [ACC_PRIVATE_KEY]
    },
    mumbai: {
      url:  "https://matic-mumbai.chainstacklabs.com",
      accounts: [ACC_PRIVATE_KEY]
    },
    polygon: {
      url: "https://rpc-mainnet.maticvigil.com",
      accounts: [ACC_PRIVATE_KEY]
    },
  },
  mocha: {
    timeout: 20000000000
  },
  etherscan: {
    apiKey: {
      bsc: BSCSCAN_API_KEY,
      bscTestnet: BSCSCAN_API_KEY,
      polygon: POLYGONSCAN_API_KEY,
      mumbai: POLYGONSCAN_API_KEY
    }
  }
};
