const { ethers } = require("hardhat");
const { expect } = require("chai");

const parseEther = ethers.utils.parseEther;
const FEE = 10; //10% of transaction amount
const TOHOLDERS = 70; //70% of transaction fee
const TOTREASURY = 10; //10% of transaction fee
const TOBURN = 10; //10% of transaction fee
const TOREFERRALS = 10; //10% of transaction fee

describe('GOLDX Token', () => {
    beforeEach( async () => {
        [team, marketing, treasury, rewardVault, multiSigVault, ...users] = await ethers.getSigners();
        let GoldX = await ethers.getContractFactory("GOLDX");
        goldX = await GoldX.deploy(team.address, marketing.address, treasury.address, rewardVault.address, multiSigVault.address);
        await goldX.deployed();
        await goldX.setFees(FEE);
        await goldX.setFeeDistribution(TOHOLDERS, TOTREASURY, TOBURN, TOREFERRALS);

        await goldX.excludeAccount(treasury.address);
        await goldX.excludeAccount(marketing.address);
        await goldX.excludeAccount(team.address);
        
        getBalances = async (silent) => {
            let balances = {};
            let addresses = ['Team wallet', 'Marketing wallet', 'Treasury', 'Reward Vault', 'Multi-signature Vault', 'User1', 'User2', 'User3'];
            balances.team = await goldX.balanceOf(team.address);
            balances.marketing = await goldX.balanceOf(marketing.address);
            balances.treasury = await goldX.balanceOf(treasury.address);
            balances.rewardVault = await goldX.balanceOf(rewardVault.address);
            balances.multiSigVault = await goldX.balanceOf(multiSigVault.address);
            balances.user1 = await goldX.balanceOf(users[0].address);
            balances.user2 = await goldX.balanceOf(users[1].address);
            balances.user3 = await goldX.balanceOf(users[2].address);
            if(!silent) {
                for(let i=0; i<addresses.length; i++) {
                    console.log(`${addresses[i]} balance: ${Object.values(balances)[i]/1e18} GOLDX`);
                }
            }
            return balances;
        }
    });

    describe('Base', () => {
        it('Should have correct name, symbol and decimals', async() => {
            expect(await goldX.name()).to.equal("GOLDX");
            expect(await goldX.symbol()).to.equal("GLDX");
            expect(await goldX.decimals()).to.equal(18);
        });
    });
    describe('Fees distribution', () => {
        it('Should take fees for transaction and distribute it to holders, treasury, burn wallet and referrals', async() => {
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

            let refReward = await goldX._tReferralReward();

            console.log("\nTransferred 10 GoldX from team wallet to user1\n");
            let balancesAfter = await getBalances();
            let totalSupplyAfter = await goldX.totalSupply();
            // result = 10 - 1 + 0.7
            expect(balancesAfter.user1).to.be.equal(balancesBefore.user1.add(amountWithFees).add(feeAmount.mul(TOHOLDERS).div(100)));
            expect(balancesAfter.treasury).to.be.equal(feeAmount.mul(TOTREASURY).div(100));
            expect(refReward).to.be.equal(feeAmount.mul(TOREFERRALS).div(100));
            let burnedAmount = totalSupplyBefore.sub(totalSupplyAfter);
            let expectedBurnedAmount = feeAmount.mul(TOBURN).div(100);
            expect(burnedAmount).to.be.equal(expectedBurnedAmount);
            let sum = Object.values(balancesAfter).map(el => el/1e18, 0).reduce((a, b) => a + b, 0);
            sum = sum + burnedAmount/1e18 + refReward/1e18;
            // all tokens in circulation should be 2.2B
            expect(sum).to.be.equal(2200000000)
        });
    });
    describe('Referral programm', () => {
        it('Should distribute fees to all referrals if transaction was not initiated by a referral', async() => {
            let amount = parseEther("10");
            let feeAmount = amount.mul(FEE).div(100);
            let amountWithFees = amount.sub(feeAmount);

            let balancesBefore = await getBalances();
            let totalSupplyBefore = await goldX.totalSupply();
            await goldX.addReferrer(users[1].address);
            await goldX.connect(users[2]).bindReferrerToReferral(users[1].address);
            await goldX.transfer(users[0].address, amount);

            let refReward = await goldX._tReferralReward();

            console.log("\nTransferred 10 GoldX from team wallet to user1\n");
            let balancesAfter = await getBalances();
            let totalSupplyAfter = await goldX.totalSupply();
        });
    });
});

