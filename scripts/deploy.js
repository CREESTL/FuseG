// SPDX-License-Identifier: MIT

const { ethers, upgrades, network } = require("hardhat");
const fs = require("fs");
const path = require("path");
const delay = require("delay");
const config = require("../config");

// JSON file to keep information about previous deployments
const OUTPUT_DEPLOY = require("./deployOutput.json");

let contractName;

async function main() {
  let [owner, addr1, addr2, addr3, ...addrs] = await ethers.getSigners();
  let accounts = config[network.name];
  console.log(`[NOTICE!] Chain of deployment: ${network.name}`);

  // ====================================================

  // Contract #1: Reward Vault

  // Deploy
  contractName = "RewardVault";
  console.log(`[${contractName}]: Start of Deployment...`);
  _contractProto = await ethers.getContractFactory(contractName);
  contractDeployTx = await _contractProto.deploy();
  reward = await contractDeployTx.deployed();
  console.log(`[${contractName}]: Deployment Finished!`);
  OUTPUT_DEPLOY[network.name][contractName].address = reward.address;

  // Verify
  console.log(`[${contractName}]: Start of Verification...`);

  // Sleep for 90 seconds, otherwise block explorer will fail
  await delay(90000);

  // Write deployment and verification info into the JSON file before actual verification
  // The reason is that verification may fail if you try to verify the same contract again
  // And the JSON file will not change
  OUTPUT_DEPLOY[network.name][contractName].address = reward.address;
  if (network.name === "polygon") {
    url = "https://polygonscan.com/address/" + reward.address + "#code";
  } else if (network.name === "mumbai") {
    url = "https://mumbai.polygonscan.com/address/" + reward.address + "#code";
  } else if (network.name === "ethereum") {
    url = "https://etherscan.io/address/" + reward.address + "#code";
  } else if (network.name === "goerli") {
    url = "https://goerli.etherscan.io/address/" + reward.address + "#code";
  } else if (network.name === "bsc") {
    url = "https://bscscan.com/address/" + reward.address + "#code";
  } else if (network.name === "bsc_testnet") {
    url = "https://testnet.bscscan.com/address/" + reward.address + "#code";
  }

  OUTPUT_DEPLOY[network.name][contractName].verification = url;

  // Provide all contract's dependencies as separate files
  // NOTE It may fail with "Already Verified" error. Do not pay attention to it. Verification will
  // be done correctly!
  try {
    await hre.run("verify:verify", {
      address: reward.address,
    });
  } catch (error) {
    console.error(error);
  }
  console.log(`[${contractName}]: Verification Finished!`);

  // ====================================================

  // Contract #2: Multi-signature Vault

  // Deploy
  contractName = "MultiSigVault";
  console.log(`[${contractName}]: Start of Deployment...`);
  _contractProto = await ethers.getContractFactory(contractName);
  contractDeployTx = await _contractProto.deploy([owner.address]);
  multisig = await contractDeployTx.deployed();
  console.log(`[${contractName}]: Deployment Finished!`);
  OUTPUT_DEPLOY[network.name][contractName].address = multisig.address;

  // Verify
  console.log(`[${contractName}]: Start of Verification...`);

  // Sleep for 90 seconds, otherwise block explorer will fail
  await delay(90000);

  // Write deployment and verification info into the JSON file before actual verification
  // The reason is that verification may fail if you try to verify the same contract again
  // And the JSON file will not change
  OUTPUT_DEPLOY[network.name][contractName].address = multisig.address;
  if (network.name === "polygon") {
    url = "https://polygonscan.com/address/" + multisig.address + "#code";
  } else if (network.name === "mumbai") {
    url =
      "https://mumbai.polygonscan.com/address/" + multisig.address + "#code";
  } else if (network.name === "ethereum") {
    url = "https://etherscan.io/address/" + multisig.address + "#code";
  } else if (network.name === "goerli") {
    url = "https://goerli.etherscan.io/address/" + multisig.address + "#code";
  } else if (network.name === "bsc") {
    url = "https://bscscan.com/address/" + multisig.address + "#code";
  } else if (network.name === "bsc_testnet") {
    url = "https://testnet.bscscan.com/address/" + multisig.address + "#code";
  }

  OUTPUT_DEPLOY[network.name][contractName].verification = url;

  // Provide all contract's dependencies as separate files
  // NOTE It may fail with "Already Verified" error. Do not pay attention to it. Verification will
  // be done correctly!
  try {
    await hre.run("verify:verify", {
      address: multisig.address,
      constructorArguments: [[owner.address]],
    });
  } catch (error) {
    console.error(error);
  }
  console.log(`[${contractName}]: Verification Finished!`);

  // ====================================================

  // Contract #3: GOLDX Token

  // Deploy
  contractName = "GOLDX";
  console.log(`[${contractName}]: Start of Deployment...`);
  _contractProto = await ethers.getContractFactory(contractName);
  contractDeployTx = await _contractProto.deploy(
    accounts.TEAM,
    accounts.MARKETING,
    accounts.TREASURY,
    reward.address,
    multisig.address
  );
  goldx = await contractDeployTx.deployed();
  console.log(`[${contractName}]: Deployment Finished!`);
  OUTPUT_DEPLOY[network.name][contractName].address = goldx.address;

  // Verify
  console.log(`[${contractName}]: Start of Verification...`);

  // Sleep for 90 seconds, otherwise block explorer will fail
  await delay(90000);

  // Write deployment and verification info into the JSON file before actual verification
  // The reason is that verification may fail if you try to verify the same contract again
  // And the JSON file will not change
  OUTPUT_DEPLOY[network.name][contractName].address = goldx.address;
  if (network.name === "polygon") {
    url = "https://polygonscan.com/address/" + goldx.address + "#code";
  } else if (network.name === "mumbai") {
    url = "https://mumbai.polygonscan.com/address/" + goldx.address + "#code";
  } else if (network.name === "ethereum") {
    url = "https://etherscan.io/address/" + goldx.address + "#code";
  } else if (network.name === "goerli") {
    url = "https://goerli.etherscan.io/address/" + goldx.address + "#code";
  } else if (network.name === "bsc") {
    url = "https://bscscan.com/address/" + goldx.address + "#code";
  } else if (network.name === "bsc_testnet") {
    url = "https://testnet.bscscan.com/address/" + goldx.address + "#code";
  }

  OUTPUT_DEPLOY[network.name][contractName].verification = url;

  // Provide all contract's dependencies as separate files
  // NOTE It may fail with "Already Verified" error. Do not pay attention to it. Verification will
  // be done correctly!
  try {
    await hre.run("verify:verify", {
      address: goldx.address,
      constructorArguments: [
        accounts.TEAM,
        accounts.MARKETING,
        accounts.TREASURY,
        reward.address,
        multisig.address,
      ],
    });
  } catch (error) {
    console.error(error);
  }
  console.log(`[${contractName}]: Verification Finished!`);

  // ====================================================

  // Initialize vaults

  await reward.initialize(accounts.FUSEG, goldx.address, multisig.address);
  await multisig.initialize(goldx.address, reward.address);

  // ====================================================

  console.log(`See Results in "${__dirname + "/deployOutput.json"}" File`);

  fs.writeFileSync(
    path.resolve(__dirname, "./deployOutput.json"),
    JSON.stringify(OUTPUT_DEPLOY, null, "  ")
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
