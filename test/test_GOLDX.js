const { ethers } = require("hardhat");
const { expect } = require("chai");

const parseEther = ethers.utils.parseEther;

describe('GOLDX Token', () => {
    beforeEach( async () => {
        [team, marketing, treasury, rewardVault, multiSigVault, user1, user2] = await ethers.getSigners();

        let GoldX = await ethers.getContractFactory("GOLDX");
        goldX = await GoldX.deploy(team.address, marketing.address, treasury.address, rewardVault.address, multiSigVault.address);
        await goldX.deployed();
        await goldX.setFees(10);
        await goldX.setFeeDistribution(70, 10, 10, 10);
    });

    it('Should have correct name, symbol and decimals', async() => {
        expect(await goldX.name()).to.equal("GOLDX");
        expect(await goldX.symbol()).to.equal("GLDX");
        expect(await goldX.decimals()).to.equal(18);
    });
    it('Should distribute fees to holders', async() => {
        let amount = parseEther("1000");
        let teamBalance = await goldX.balanceOf(team.address);
        let userBalance = await goldX.balanceOf(user1.address);
        console.log("Team: ", teamBalance/1e18)
        console.log("User 1: ", userBalance/1e18)
        console.log("TRANSFER")
        await goldX.transfer(user1.address, amount);
        teamBalance = await goldX.balanceOf(team.address);
        userBalance = await goldX.balanceOf(user1.address);
        rvBalance = await goldX.balanceOf(rewardVault.address);
        mvBalance = await goldX.balanceOf(multiSigVault.address);
        treasuryBalance = await goldX.balanceOf(treasury.address);
        marketingBalance = await goldX.balanceOf(marketing.address);
        treasury = await goldX.balanceOf(treasury.address);
        refReward = await goldX.totalReferralReward();
        refReward = await goldX.tokenFromReflection(refReward);
        sum = teamBalance.add(userBalance).add(treasuryBalance).add(rvBalance).add(mvBalance).add(refReward).add(marketingBalance);
        console.log("Team: ", teamBalance/1e18)
        console.log("User 1: ", userBalance/1e18)
        console.log("Reward Vault: ", (await goldX.balanceOf(rewardVault.address))/1e18)
        console.log("Multisig Vault: ", (await goldX.balanceOf(multiSigVault.address))/1e18)
        console.log("Marketing: ", (await goldX.balanceOf(marketing.address))/1e18)
        console.log("Treasury: ", treasury/1e18)
        console.log("TotalFees: ", (await goldX.totalFees())/1e18)
        console.log("Total: ", sum/1e18)
    });
});

