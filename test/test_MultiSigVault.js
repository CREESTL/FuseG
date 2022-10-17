const { ethers } = require("hardhat");
const { expect } = require("chai");

const parseEther = ethers.utils.parseEther;
const arrToBN = (arr) => {
    return arr.map((el) => parseEther(el.toString()))
}

describe("Multi-signature vault", () => {
    beforeEach( async () => {
        [fuseG, team, marketing, alice, bob, charlie, eva] = await ethers.getSigners();

        let MultiSigVault = await ethers.getContractFactory("MultiSigVault");
        multiSigVault = await MultiSigVault.deploy([alice.address, bob.address, charlie.address]);

        let RewardVault = await ethers.getContractFactory("RewardVault");
        rewardVault = await RewardVault.deploy();

        let GoldX = await ethers.getContractFactory("GOLDX");
        goldX = await GoldX.deploy(team.address, marketing.address, rewardVault.address, multiSigVault.address);

        await rewardVault.initialize(fuseG.address, goldX.address, multiSigVault.address);
        await multiSigVault.initialize(goldX.address, rewardVault.address);
    });

    describe("Base", () => {
        it('Successfully initializes the vault', async() => {
            expect(await multiSigVault.getRewardVault()).to.be.equal(rewardVault.address);
            expect(await multiSigVault.getGoldX()).to.be.equal(goldX.address);
            expect(await multiSigVault.getProposalCount()).to.be.equal(0);
        });
    });

    describe("Proposals", () => {
        it("Signer can submit a proposal", async() => {
            let amount = parseEther("10000");
            await expect(multiSigVault.connect(alice).submitProposal(0, marketing.address, amount))
                .to.emit(multiSigVault, "SubmitProposal")
                .withArgs(alice.address, 0, 0, marketing.address, amount);

            expect(await multiSigVault.getProposalCount()).to.be.equal(1);
            let proposal = await multiSigVault.getProposal(0);

            expect(proposal.amount).to.be.equal(amount);
            expect(proposal.to).to.be.equal(marketing.address);
            expect(proposal.numConfirmations).to.be.equal(0);
            expect(proposal.executed).to.be.equal(false);
        });
        it("Signer can confirm a proposal", async() => {
            let amount = parseEther("10000");
            await multiSigVault.connect(alice).submitProposal(0, marketing.address, amount);
            await expect(multiSigVault.connect(alice).confirmProposal(0))
                .to.emit(multiSigVault, "ConfirmProposal")
                .withArgs(alice.address, 0);
            let {numConfirmations} = await multiSigVault.getProposal(0);
            expect(numConfirmations).to.be.equal(1);
        });
        it("Signer can revoke confirmation", async() => {
            let amount = parseEther("10000");
            await multiSigVault.connect(alice).submitProposal(0, marketing.address, amount);
            await multiSigVault.connect(alice).confirmProposal(0);
            await expect(multiSigVault.connect(alice).revokeConfirmation(0))
                .to.emit(multiSigVault, "RevokeConfirmation")
                .withArgs(alice.address, 0);
            let {numConfirmations} = await multiSigVault.getProposal(0);
            expect(numConfirmations).to.be.equal(0);
        });
        it("Signer can execute a tx proposal if >50% voted for it", async() => {
            let amount = parseEther("10000");
            let balanceBefore = await goldX.balanceOf(marketing.address);

            await multiSigVault.connect(alice).submitProposal(0, marketing.address, amount);
            await multiSigVault.connect(alice).confirmProposal(0);
            await multiSigVault.connect(bob).confirmProposal(0);

            let {numConfirmations} = await multiSigVault.getProposal(0);
            expect(numConfirmations).to.be.equal(2);

            await expect(multiSigVault.connect(alice).executeProposal(0))
                .to.emit(multiSigVault, "ExecuteProposal")
                .withArgs(alice.address, 0);
            let balanceAfter = await goldX.balanceOf(marketing.address);

            let {executed} = await multiSigVault.getProposal(0);
            expect(balanceAfter).to.be.equal(balanceBefore.add(amount));
            expect(executed).to.be.equal(true);
        });
        it("Signer can execute an addSigner proposal if >50% voted for it", async() => {
            let signers = await multiSigVault.getSigners();
            expect(signers).to.not.include(eva.address);

            await multiSigVault.connect(alice).submitProposal(1, eva.address, 0);
            await multiSigVault.connect(alice).confirmProposal(0);
            await multiSigVault.connect(bob).confirmProposal(0);

            let {numConfirmations} = await multiSigVault.getProposal(0);
            expect(numConfirmations).to.be.equal(2);

            await multiSigVault.connect(alice).executeProposal(0);
            signers = await multiSigVault.getSigners();
            expect(signers).to.include(eva.address);
        });
        it("Signer can execute removeSigner proposal if >50% voted for it", async() => {
            let signers = await multiSigVault.getSigners();
            expect(signers).to.include(bob.address);

            await multiSigVault.connect(alice).submitProposal(2, bob.address, 0);
            await multiSigVault.connect(alice).confirmProposal(0);
            await multiSigVault.connect(bob).confirmProposal(0);

            let {numConfirmations} = await multiSigVault.getProposal(0);
            expect(numConfirmations).to.be.equal(2);

            await multiSigVault.connect(alice).executeProposal(0);
            signers = await multiSigVault.getSigners();
            expect(signers).to.not.include(bob.address);
        });
        it("Only signer can submit a proposal", async() => {
            let amount = parseEther("10000");
            await expect(multiSigVault.submitProposal(0, marketing.address, amount))
                .to.be.revertedWith("MV: NOT A SIGNER");
        });
        it("Only signer can confirm a proposal", async() => {
            let amount = parseEther("10000");
            await multiSigVault.connect(alice).submitProposal(0, marketing.address, amount);
            await expect(multiSigVault.confirmProposal(0))
                .to.be.revertedWith("MV: NOT A SIGNER");
        });
        it("Only signer can execute a proposal", async() => {
            let amount = parseEther("10000");
            await multiSigVault.connect(alice).submitProposal(0, marketing.address, amount);
            await multiSigVault.connect(alice).confirmProposal(0);
            await expect(multiSigVault.executeProposal(0))
                .to.be.revertedWith("MV: NOT A SIGNER");
        });
        it("Signer can't confirm same proposal twice", async() => {
            let amount = parseEther("10000");
            await multiSigVault.connect(alice).submitProposal(0, marketing.address, amount);
            await multiSigVault.connect(alice).confirmProposal(0);
            await expect(multiSigVault.connect(alice).confirmProposal(0))
                .to.be.revertedWith("MV: PROPOSAL ALREADY CONFIRMED");
        });
        it("Signer can't confirm proposal if it doesn't exist", async() => {
            let amount = parseEther("10000");
            await multiSigVault.connect(alice).submitProposal(0, marketing.address, amount);
            await expect(multiSigVault.connect(alice).confirmProposal(1))
                .to.be.revertedWith("MV: PROPOSAL DOESN'T EXIST");
        });
        it("Signer can't confirm proposal if it's already executed", async() => {
            let amount = parseEther("10000");
            await multiSigVault.connect(alice).submitProposal(0, marketing.address, amount);

            await multiSigVault.connect(alice).confirmProposal(0);
            await multiSigVault.connect(bob).confirmProposal(0);
            await multiSigVault.connect(alice).executeProposal(0);
            
            await expect(multiSigVault.connect(charlie).confirmProposal(0))
                .to.be.revertedWith("MV: PROPOSAL ALREADY EXECUTED");
        });
        it("Signer can't execute proposal if it doesn't exist", async() => {
            let amount = parseEther("10000");
            await expect(multiSigVault.connect(alice).executeProposal(1))
                .to.be.revertedWith("MV: PROPOSAL DOESN'T EXIST");
        });
        it("Signer can't execute proposal if it's already executed", async() => {
            let amount = parseEther("10000");
            await multiSigVault.connect(alice).submitProposal(0, marketing.address, amount);

            await multiSigVault.connect(alice).confirmProposal(0);
            await multiSigVault.connect(bob).confirmProposal(0);
            await multiSigVault.connect(alice).executeProposal(0);
            
            await expect(multiSigVault.connect(charlie).executeProposal(0))
                .to.be.revertedWith("MV: PROPOSAL ALREADY EXECUTED");
        });
        it("Signer can't revoke confirmation if he hasn't confirmed a proposal", async() => {
            let amount = parseEther("10000");
            await multiSigVault.connect(alice).submitProposal(0, marketing.address, amount);
            await expect(multiSigVault.connect(alice).revokeConfirmation(0))
                .to.be.revertedWith("MV: PROPOSAL NOT CONFIRMED");
        });
        it("Signer can't revoke confirmation if proposal already executed", async() => {
            let amount = parseEther("10000");
            await multiSigVault.connect(alice).submitProposal(0, marketing.address, amount);

            await multiSigVault.connect(alice).confirmProposal(0);
            await multiSigVault.connect(bob).confirmProposal(0);
            await multiSigVault.connect(alice).executeProposal(0);
            
            await expect(multiSigVault.connect(alice).revokeConfirmation(0))
                .to.be.revertedWith("MV: PROPOSAL ALREADY EXECUTED");
        });
    });
    describe("Reward vault operations", () => {
        it('Sets a new round in the reward vault', async() => {
            let phaseSupply = parseEther("100");
            let phaseCount = 5;
            let coeffs = [1.1,1.2,1.3,1.4,1.5];
            coeffs = arrToBN(coeffs);
            await expect(multiSigVault.setNewRound(phaseSupply, phaseCount, coeffs))
                .to.emit(rewardVault, "NewRound")
                .withArgs(phaseSupply.mul(phaseCount), phaseSupply, phaseCount);
        });
    });
});


