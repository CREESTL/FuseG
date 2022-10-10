const { ethers } = require("hardhat");
const { expect } = require("chai");

describe('GOLDX Token', () => {
    beforeEach( async () => {
        [team, marketing, rewardVault, multiSigVault] = await ethers.getSigners();

        let Token = await ethers.getContractFactory("GOLDX");
        token = await Token.deploy(team.address, marketing.address, rewardVault.address, multiSigVault.address);
        await token.deployed();
    });

    it('Should have correct name, symbol and decimals', async() => {
        expect(await token.name()).to.equal("GOLDX");
        expect(await token.symbol()).to.equal("GOLDX");
        expect(await token.decimals()).to.equal(18);
    });
});

