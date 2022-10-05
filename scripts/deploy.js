const { ethers } = require("hardhat");

async function main() {
    const accounts = await ethers.getSigners();
    const Token = await ethers.getContractFactory("GOLDX");
    const token = await Token.deploy(accounts[0].address,accounts[1].address,accounts[2].address,accounts[3].address);
    console.log('GOLDX address: ', token.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });





