const { ethers } = require("hardhat");
const { expect } = require("chai");

const parseEther = ethers.utils.parseEther;
const formatEther = ethers.utils.formatEther;
const toBytes32 = ethers.utils.formatBytes32String;

function increaseTime(time) {
  ethers.provider.send("evm_increaseTime", [ time ]);
  ethers.provider.send("evm_mine");
}

const FEE = 10; //10% of transaction amount
const TOHOLDERS = 70; //70% of transaction fee
const TOTREASURY = 10; //10% of transaction fee
const TOBURN = 10; //10% of transaction fee
const TOREFERRALS = 10; //10% of transaction fee

describe("GOLDX Token", () => {
    beforeEach( async () => {
        [team, marketing, treasury, rewardVault, multiSigVault, ...users] = await ethers.getSigners();
        let GoldX = await ethers.getContractFactory("GOLDX");
        goldX = await GoldX.deploy(team.address, marketing.address, treasury.address, rewardVault.address, multiSigVault.address);
        await goldX.deployed();

        await goldX.excludeAccount(treasury.address);
        await goldX.excludeAccount(marketing.address);
        await goldX.excludeAccount(team.address);
        
        SUPERADMIN = await goldX.SUPERADMIN_ROLE();

        getBalances = async (silent) => {
            let balances = {};
            let addresses = [
                'Team wallet', 'Marketing wallet', 'Treasury',
                'Reward Vault', 'Multi-signature Vault', 'User1',
                'User2', 'User3', 'User4', 'User5'];

            balances.team = await goldX.balanceOf(team.address);
            balances.marketing = await goldX.balanceOf(marketing.address);
            balances.treasury = await goldX.balanceOf(treasury.address);
            balances.rewardVault = await goldX.balanceOf(rewardVault.address);
            balances.multiSigVault = await goldX.balanceOf(multiSigVault.address);
            balances.user1 = await goldX.balanceOf(users[0].address);
            balances.user2 = await goldX.balanceOf(users[1].address);
            balances.user3 = await goldX.balanceOf(users[2].address);
            balances.user4 = await goldX.balanceOf(users[3].address);
            balances.user5 = await goldX.balanceOf(users[4].address);
            if(!silent) {
                for(let i=0; i<addresses.length; i++) {
                    console.log(`${addresses[i]} balance: ${Object.values(balances)[i]/1e18} GOLDX`);
                }
            }
            return balances;
        }
    });

    describe("Base", () => {
        it("Should have correct name, symbol and decimals", async() => {
            expect(await goldX.name()).to.equal("GOLDX");
            expect(await goldX.symbol()).to.equal("GLDX");
            expect(await goldX.decimals()).to.equal(18);
        });
    });
    describe("Transactions & Fees distribution", () => {
        it("Should take fees for transaction and distribute it to holders, treasury, burn wallet and referrals", async() => {
            // transfer 10 GoldX with 10% fee
            // fee - 1 GoldX
            // to burn - 0.1 GoldX
            // to treasury - 0.1 GoldX
            // to referrals - 0.1 GoldX
            // to holders - 0.7 GoldX
            let amount = parseEther("10");
            let feeAmount = amount.mul(FEE).div(100);
            let amountWithFees = amount.sub(feeAmount);

            let balancesBefore = await getBalances();
            let totalSupplyBefore = await goldX.totalSupply();
            await goldX.transfer(users[0].address, amount);

            let refReward = await goldX.getReferralReward();

            console.log("\nTransferred 10 GoldX from team wallet to user1\n");
            let balancesAfter = await getBalances();
            let totalSupplyAfter = await goldX.totalSupply();
          
            // result = 10 - 1 + 0.7
            let expectedHolderAmount = amountWithFees.add(feeAmount.mul(TOHOLDERS).div(100));
            expect(balancesAfter.user1).to.be.equal(balancesBefore.user1.add(expectedHolderAmount));
            expect(balancesAfter.treasury).to.be.equal(feeAmount.mul(TOTREASURY).div(100));
            expect(refReward).to.be.equal(feeAmount.mul(TOREFERRALS).div(100));

            let burnedAmount = totalSupplyBefore.sub(totalSupplyAfter);
            let expectedBurnedAmount = feeAmount.mul(TOBURN).div(100);
            expect(burnedAmount).to.be.equal(expectedBurnedAmount);
          
            // all tokens in circulation should be 2.2B
            let sum = Object.values(balancesAfter).map(el => el*1, 0).reduce((a, b) => a + b, 0);
            sum = (sum + burnedAmount*1 + refReward*1) / 1e18;
            expect(sum).to.be.equal(2200000000);
        });
        it("Users that are in the whitelist don't pay fees", async() => {
            let amount = parseEther("10");
            let balancesBefore = await getBalances();

            await goldX.addToWhitelist(team.address);
            await goldX.transfer(users[0].address, amount);

            console.log("\nTeam wallet now in the whitelist !");
            console.log("Transferred 10 GoldX from team wallet to user1\n");
            let balancesAfter = await getBalances();
          
            // result = 10, no fees taken
            expect(balancesAfter.user1).to.be.equal(balancesBefore.user1.add(amount));
        });
        it("If user is in the blacklist, transaction is not executed", async() => {
            let amount = parseEther("10");

            await goldX.addToBlacklist(team.address);
            await expect(goldX.transfer(users[0].address, amount))
                .to.be.revertedWith("GOLDX: USER IS BLACKLISTED");
        });
        it("Owner can change fees amount", async() => {
            let amount = parseEther("10");
            let newFeeAmount = 5;
            let feeAmount = amount.mul(newFeeAmount).div(100);
            let amountWithFees = amount.sub(feeAmount);
            await goldX.setFees(newFeeAmount);

            let balancesBefore = await getBalances();
            let totalSupplyBefore = await goldX.totalSupply();
            await goldX.transfer(users[0].address, amount);

            let refReward = await goldX.getReferralReward();

            console.log("\nNew FEE AMOUNT is 5% !");
            console.log("Transferred 10 GoldX from team wallet to user1\n");
            let balancesAfter = await getBalances();
            let totalSupplyAfter = await goldX.totalSupply();
          
            // result = 10 - 0.5 + 0.35
            let expectedHolderAmount = amountWithFees.add(feeAmount.mul(TOHOLDERS).div(100));
            expect(balancesAfter.user1).to.be.equal(balancesBefore.user1.add(expectedHolderAmount));
            expect(balancesAfter.treasury).to.be.equal(feeAmount.mul(TOTREASURY).div(100));
            expect(refReward).to.be.equal(feeAmount.mul(TOREFERRALS).div(100));

            let burnedAmount = totalSupplyBefore.sub(totalSupplyAfter);
            let expectedBurnedAmount = feeAmount.mul(TOBURN).div(100);
            expect(burnedAmount).to.be.equal(expectedBurnedAmount);
          
            // all tokens in circulation should be 2.2B
            let sum = Object.values(balancesAfter).map(el => el*1, 0).reduce((a, b) => a + b, 0);
            sum = (sum + burnedAmount*1 + refReward*1) / 1e18;
            expect(sum).to.be.equal(2200000000);
        });
        it("New fee amount must be in 0-15% range", async() => {
            let newFeeAmount = 16;
            await expect(goldX.setFees(newFeeAmount))
                .to.be.revertedWith("GOLDX: 0% >= TRANSACTION FEE <= 15%");
        });
        it("Owner can change fee distributon", async() => {
            let amount = parseEther("10");
            let feeAmount = amount.mul(FEE).div(100);
            let amountWithFees = amount.sub(feeAmount);
            // setting new values for the fee distribution
            let toHolders = 20;
            let toTreasury = 50;
            let toBurn = 15;
            let toReferrals = 15;
            await goldX.setFeeDistribution(toHolders, toTreasury, toBurn, toReferrals);

            let balancesBefore = await getBalances();
            let totalSupplyBefore = await goldX.totalSupply();
            await goldX.transfer(users[0].address, amount);

            let refReward = await goldX.getReferralReward();

            console.log("\nNew FEE DISTRIBUTION 20% - to holders, 50% - to treasury, 15% - to burn, 15% - to referrals !");
            console.log("Transferred 10 GoldX from team wallet to user1\n");
            let balancesAfter = await getBalances();
            let totalSupplyAfter = await goldX.totalSupply();
          
            // result = 10 - 1 + 0.2
            let expectedHolderAmount = amountWithFees.add(feeAmount.mul(toHolders).div(100));
            expect(balancesAfter.user1).to.be.equal(balancesBefore.user1.add(expectedHolderAmount));
            expect(balancesAfter.treasury).to.be.equal(feeAmount.mul(toTreasury).div(100));
            expect(refReward).to.be.equal(feeAmount.mul(toReferrals).div(100));

            let burnedAmount = totalSupplyBefore.sub(totalSupplyAfter);
            let expectedBurnedAmount = feeAmount.mul(toBurn).div(100);
            expect(burnedAmount).to.be.equal(expectedBurnedAmount);
          
            // all tokens in circulation should be 2.2B
            let sum = Object.values(balancesAfter).map(el => el*1, 0).reduce((a, b) => a + b, 0);
            sum = (sum + burnedAmount*1 + refReward*1) / 1e18;
            expect(sum).to.be.equal(2200000000);
        });
        it("Only owner can set fees", async() => {
            let newFeeAmount = 16;
            await expect(goldX.connect(users[0]).setFees(newFeeAmount))
                .to.be.revertedWith("Ownable: caller is not the owner");
        });
        it("Only owner can set new fee distributions", async() => {
            // setting new values for the fee distribution
            let toHolders = 20;
            let toTreasury = 50;
            let toBurn = 15;
            let toReferrals = 15;
            await expect(goldX.connect(users[0]).setFeeDistribution(toHolders, toTreasury, toBurn, toReferrals))
                .to.be.revertedWith("Ownable: caller is not the owner");
        });
    });
    describe("Superadmins", () => {
        it("Owner can assign and revoke superadmin rights", async() => {
            await goldX.grantRole(SUPERADMIN, users[0].address);
            let hasRole = await goldX.hasRole(SUPERADMIN, users[0].address);
            expect(hasRole).to.be.equal(true);

            await goldX.revokeRole(SUPERADMIN, users[0].address);
            hasRole = await goldX.hasRole(SUPERADMIN, users[0].address);
            expect(hasRole).to.be.equal(false);
        });
        it("Owner and superadmins can add/remove users to the whitelist", async() => {
            await goldX.grantRole(SUPERADMIN, users[0].address);
            await goldX.addToWhitelist(users[1].address);
            await goldX.connect(users[0]).addToWhitelist(users[2].address);

            expect(await goldX.whitelist(users[1].address)).to.be.equal(true);
            expect(await goldX.whitelist(users[2].address)).to.be.equal(true);

            await goldX.removeFromWhitelist(users[1].address);
            await goldX.connect(users[0]).removeFromWhitelist(users[2].address);

            expect(await goldX.whitelist(users[1].address)).to.be.equal(false);
            expect(await goldX.whitelist(users[2].address)).to.be.equal(false);

            await expect(goldX.connect(users[1]).addToWhitelist(users[2].address))
                .to.be.revertedWith(`AccessControl: account ${users[1].address.toLowerCase()} is missing role ${SUPERADMIN}`);
            await expect(goldX.connect(users[1]).removeFromWhitelist(users[2].address))
                .to.be.revertedWith(`AccessControl: account ${users[1].address.toLowerCase()} is missing role ${SUPERADMIN}`);
        });
        it("Owner and superadmins can add/remove users to the blacklist", async() => {
            await goldX.grantRole(SUPERADMIN, users[0].address);
            await goldX.addToBlacklist(users[1].address);
            await goldX.connect(users[0]).addToBlacklist(users[2].address);

            expect(await goldX.blacklist(users[1].address)).to.be.equal(true);
            expect(await goldX.blacklist(users[2].address)).to.be.equal(true);

            await goldX.removeFromBlacklist(users[1].address);
            await goldX.connect(users[0]).removeFromBlacklist(users[2].address);

            expect(await goldX.blacklist(users[1].address)).to.be.equal(false);
            expect(await goldX.blacklist(users[2].address)).to.be.equal(false);

            await expect(goldX.connect(users[1]).addToBlacklist(users[2].address))
                .to.be.revertedWith(`AccessControl: account ${users[1].address.toLowerCase()} is missing role ${SUPERADMIN}`);
            await expect(goldX.connect(users[1]).removeFromBlacklist(users[2].address))
                .to.be.revertedWith(`AccessControl: account ${users[1].address.toLowerCase()} is missing role ${SUPERADMIN}`);
        });
        it("Owner and superadmins can put the token on pause", async() => {
            await goldX.grantRole(SUPERADMIN, users[0].address);
            await goldX.pause();
            expect(await goldX.paused()).to.be.equal(true);
            await goldX.unpause();
            expect(await goldX.paused()).to.be.equal(false);
            await goldX.connect(users[0]).pause();
            expect(await goldX.paused()).to.be.equal(true);

            await expect(goldX.connect(users[1]).unpause())
                .to.be.revertedWith(`AccessControl: account ${users[1].address.toLowerCase()} is missing role ${SUPERADMIN}`);
          
            await goldX.connect(users[0]).unpause();
            expect(await goldX.paused()).to.be.equal(false);

            await expect(goldX.connect(users[1]).pause())
                .to.be.revertedWith(`AccessControl: account ${users[1].address.toLowerCase()} is missing role ${SUPERADMIN}`);
        });
        it("Transfers and other functions during pause are prohibited", async() => {
            await goldX.pause();
            await expect(goldX.addToWhitelist(users[0].address))
                .to.be.revertedWith("Pausable: paused");
            await expect(goldX.transfer(users[0].address, 100000000))
                .to.be.revertedWith("Pausable: paused");
        });
    });
    describe("Referral program", () => {
        it("User can become a referrer", async() => {
            await goldX.addReferrer(users[0].address);
            let referrersList = await goldX.getReferrersList();
            expect(referrersList).to.include(users[0].address);
        });
        it("User can change it's referrer", async() => {
            await goldX.addReferrer(users[0].address);
            await goldX.connect(users[1]).setReferrer(users[0].address);
            let referralsList = await goldX.getReferralsList();
            let referrer = await goldX.connect(users[1]).getMyReferrer();
            expect(referralsList).to.include(users[1].address);
            expect(referrer).to.include(users[0].address);
        });
        it("User should wait for the cooldown to change his referrer again", async() => {
            await goldX.addReferrer(users[0].address);
            await goldX.addReferrer(users[2].address);
            await goldX.connect(users[1]).setReferrer(users[0].address);
            let referralsList = await goldX.getReferralsList();
            let referrer = await goldX.connect(users[1]).getMyReferrer();
            expect(referralsList).to.include(users[1].address);
            expect(referrer).to.be.equal(users[0].address);

            await expect(goldX.connect(users[1]).setReferrer(users[2].address))
                .to.be.revertedWith("GOLDX: COOLDOWN IN PROGRESS");
            increaseTime(90*24*60*60);
            await goldX.connect(users[1]).setReferrer(users[2].address);
            referrer = await goldX.connect(users[1]).getMyReferrer();
            expect(referrer).to.be.equal(users[2].address);
            
        });
        it("Should distribute fees to all referrals if transaction was not initiated by a referral", async() => {
            let amount = parseEther("10");
            let feeAmount = amount.mul(FEE).div(100);
            let amountWithFees = amount.sub(feeAmount);

            let balancesBefore = await getBalances();
            let totalSupplyBefore = await goldX.totalSupply();
            await goldX.addReferrer(users[1].address);
            await goldX.connect(users[2]).setReferrer(users[1].address);
            await goldX.transfer(users[0].address, amount);

            let refReward = await goldX.getReferralReward();
            expect(refReward).to.be.equal(feeAmount.mul(TOREFERRALS).div(100));

            console.log("\nTransferred 10 GoldX from team wallet to user1");
            console.log("User2 and User3 participate in a referral program\n");
            let balancesAfter = await getBalances();
            let totalSupplyAfter = await goldX.totalSupply();
            expect(balancesAfter.user2).to.be.equal(refReward.div(2));
            expect(balancesAfter.user3).to.be.equal(refReward.div(2));
        });
        it("If referral is initiating transaction, he splits part of the fee with his referrer", async() => {
            let amount = parseEther("10");
            let feeAmount = amount.mul(FEE).div(100);
            let refRewardJs = feeAmount.mul(TOREFERRALS).div(100);

            let amountWithFees = amount.sub(feeAmount);
            await goldX.addToWhitelist(team.address);
            await goldX.transfer(users[4].address, amount);

            let balancesBefore = await getBalances();
            let totalSupplyBefore = await goldX.totalSupply();

            await goldX.addReferrers([users[1].address, users[3].address]);
            await goldX.connect(users[2]).setReferrer(users[1].address);
            await goldX.connect(users[4]).setReferrer(users[3].address);

            await goldX.connect(users[4]).transfer(users[0].address, amount);

            let refReward = await goldX.getReferralReward();
            console.log("\nTransferred 10 GoldX from team wallet to user1");
            console.log("User4 is the User5's referrer\n");
            let balancesAfter = await getBalances();
            let totalSupplyAfter = await goldX.totalSupply();
            let burnedAmount = totalSupplyBefore.sub(totalSupplyAfter);
            // all tokens in circulation should be 2.2B
            let sum = Object.values(balancesAfter).map(el => el*1, 0).reduce((a, b) => a + b, 0);
            sum = (sum + burnedAmount*1 + refReward*1) / 1e18;
            expect(sum).to.be.within(2200000000 - 1, 2200000000 + 1);
        });
        it("New referrals don't get rewards for the past distributions", async() => {
            let amount = parseEther("10");
            let feeAmount = amount.mul(FEE).div(100);
            let amountWithFees = amount.sub(feeAmount);

            let balancesBefore = await getBalances();
            let totalSupplyBefore = await goldX.totalSupply();
            await goldX.addReferrer(users[1].address);
            await goldX.connect(users[2]).setReferrer(users[1].address);
            await goldX.transfer(users[0].address, amount);

            let refReward = await goldX.getReferralReward();
            expect(refReward).to.be.equal(feeAmount.mul(TOREFERRALS).div(100));

            console.log("\nTransferred 10 GoldX from team wallet to user1");
            console.log("User2 and User3 participate in a referral program\n");
            await getBalances();

            console.log("\nTransferred another 10 GoldX from team wallet to user1");
            console.log("User4 and User5 joined the referral program\n");
            await goldX.addReferrer(users[3].address);
            await goldX.connect(users[4]).setReferrer(users[3].address);
            await goldX.transfer(users[0].address, amount);
            let balancesAfter = await getBalances();
            expect(balancesAfter.user4).to.be.equal(refReward.div(4));
            expect(balancesAfter.user5).to.be.equal(refReward.div(4));
        });
        it("Total supply is consistent", async() => {
            let amount = parseEther("1000");
            await goldX.addToWhitelist(team.address);
            let totalSupplyBefore = await goldX.totalSupply();

            await goldX.addReferrers([users[0].address, users[1].address]);
            await goldX.connect(users[2]).setReferrer(users[0].address);
            await goldX.connect(users[3]).setReferrer(users[0].address);
            await goldX.connect(users[4]).setReferrer(users[1].address);

            for(let i=0; i<5; i++) {
                await goldX.transfer(users[i].address, amount);
            }
            await getBalances();

            for(let i=0; i<5; i++) {
                for(let j=0; j<5; j++) {
                    if(i != j)
                        await goldX.connect(users[i]).transfer(users[j].address, parseEther("100"));
                }
            }
            let balancesAfter = await getBalances();
            let totalSupplyAfter = await goldX.totalSupply();
            let burnedAmount = totalSupplyBefore.sub(totalSupplyAfter);
            let sum = Object.values(balancesAfter).map(el => el*1, 0).reduce((a, b) => a + b, 0);
            sum = (sum + burnedAmount*1) / 1e18;
            expect(sum).to.be.within(2200000000 - 1, 2200000000 + 1);
        });
    });
});

