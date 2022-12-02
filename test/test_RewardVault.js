const { ethers } = require("hardhat");
const { expect } = require("chai");

const parseEther = ethers.utils.parseEther;
const SUPPLIER_ROLE =
  "0xbc1f3f7c406085be62d227092f4fd5af86922a19f3a87e6199f14015341eb9d9";
const arrToBN = (arr) => {
  return arr.map((el) => parseEther(el.toString()));
};

describe("Reward vault", () => {
  beforeEach(async () => {
    [fuseG, team, marketing, treasury, multiSigVault, alice, bob] =
      await ethers.getSigners();

    let RewardVault = await ethers.getContractFactory("RewardVault");
    rewardVault = await RewardVault.deploy();

    let GoldX = await ethers.getContractFactory("GOLDX");
    goldX = await GoldX.deploy(
      team.address,
      marketing.address,
      treasury.address,
      rewardVault.address,
      multiSigVault.address
    );

    await rewardVault.initialize(
      fuseG.address,
      goldX.address,
      multiSigVault.address
    );
  });

  describe("Vault management", () => {
    it("Successfully initializes the vault", async () => {
      expect(await rewardVault.multiSigVault()).to.be.equal(
        multiSigVault.address
      );
      expect(await rewardVault.fuseG()).to.be.equal(fuseG.address);
    });
    it("Can initialize a new round", async () => {
      let phaseSupply = parseEther("100");
      let phaseCount = 5;
      let coeffs = [1.1, 1.2, 1.3, 1.4, 1.5];
      expect(await rewardVault.vaultDepleted()).to.be.equal(true);
      coeffs = arrToBN(coeffs);
      await expect(rewardVault.setNewRound(phaseSupply, phaseCount, coeffs))
        .to.emit(rewardVault, "NewRound")
        .withArgs(phaseSupply.mul(phaseCount), phaseSupply, phaseCount);
      expect(await rewardVault.roundSupply()).to.be.equal(
        phaseSupply.mul(phaseCount)
      );
      for (let i = 0; i < coeffs.length; i++) {
        expect(await rewardVault.coeffTable(i)).to.be.equal(coeffs[i]);
      }
      expect(await rewardVault.vaultDepleted()).to.be.equal(false);
    });
    it("Only owner OR multi-sig vault can start a new round", async () => {
      let phaseSupply = parseEther("100");
      let phaseCount = 5;
      let coeffs = [1.1, 1.2, 1.3, 1.4, 1.5];
      coeffs = arrToBN(coeffs);
      await expect(
        rewardVault.connect(alice).setNewRound(phaseSupply, phaseCount, coeffs)
      ).to.be.revertedWith(
        `AccessControl: account ${alice.address.toLowerCase()} is missing role ${SUPPLIER_ROLE}`
      );
    });
    it("Can't start a new round if not enough GoldX tokens on vault balance", async () => {
      let phaseSupply = parseEther("100000000");
      let phaseCount = 5;
      let coeffs = [1.1, 1.2, 1.3, 1.4, 1.5];
      coeffs = arrToBN(coeffs);
      await expect(
        rewardVault.setNewRound(phaseSupply, phaseCount, coeffs)
      ).to.be.revertedWith("RV: NOT ENOUGH TOKENS TO START A NEW ROUND");
    });
    it("Can't start a new round if coefficients amount is not equal to number of phases", async () => {
      let phaseSupply = parseEther("100");
      let phaseCount = 10;
      let coeffs = [1.1, 1.2, 1.3, 1.4, 1.5];
      coeffs = arrToBN(coeffs);
      await expect(
        rewardVault.setNewRound(phaseSupply, phaseCount, coeffs)
      ).to.be.revertedWith("RV: COEFFS NUM != PHASE COUNT");
    });
    it("Can't start a new round if previous round supply hasn't been distributed", async () => {
      let phaseSupply = parseEther("100");
      let phaseCount = 5;
      let coeffs = [1.1, 1.2, 1.3, 1.4, 1.5];
      coeffs = arrToBN(coeffs);
      await rewardVault.setNewRound(phaseSupply, phaseCount, coeffs);
      await expect(
        rewardVault.setNewRound(phaseSupply, phaseCount, coeffs)
      ).to.be.revertedWith("RV: PREVIOUS ROUND HASN'T FINISHED YET");
    });
  });

  describe("GoldX mining", () => {
    it("Simple case - phase supply > GoldX amount", async () => {
      let fuseGAmount = parseEther("10");
      let phaseSupply = parseEther("100");
      let phaseCount = 5;
      let coeffs = [1, 1, 1, 1, 1];
      coeffs = arrToBN(coeffs);

      await rewardVault.setNewRound(phaseSupply, phaseCount, coeffs);
      let balanceBefore = await goldX.balanceOf(alice.address);
      await rewardVault.mineGoldX(alice.address, fuseGAmount);
      let balanceAfter = await goldX.balanceOf(alice.address);
      let minedAmount = await rewardVault.minedAmount();

      expect(balanceAfter).to.be.equal(fuseGAmount);
      expect(minedAmount).to.be.equal(fuseGAmount);
    });
    it("Simple case - phase supply < GoldX amount", async () => {
      let fuseGAmount = parseEther("101");
      let phaseSupply = parseEther("100");
      let phaseCount = 5;
      let coeffs = [1, 1, 1, 1, 1];
      coeffs = arrToBN(coeffs);

      await rewardVault.setNewRound(phaseSupply, phaseCount, coeffs);
      let balanceBefore = await goldX.balanceOf(alice.address);
      await rewardVault.mineGoldX(alice.address, fuseGAmount);
      let balanceAfter = await goldX.balanceOf(alice.address);
      let [phaseAfter, phaseAmountAfter] = await rewardVault.getMiningPhase();
      let minedAmount = await rewardVault.minedAmount();

      let expectedPhaseAmount = phaseSupply.sub(fuseGAmount.sub(phaseSupply));
      expect(balanceAfter).to.be.equal(fuseGAmount);
      expect(phaseAfter).to.be.equal(1);
      expect(phaseAmountAfter).to.be.equal(expectedPhaseAmount);
      expect(minedAmount).to.be.equal(fuseGAmount);
    });
    it("Depletion case - no phase overlap", async () => {
      let amounts = [25, 12.5, 6.25, 5, 3.125];
      let phaseSupply = parseEther("100");
      let phaseCount = 5;
      let coeffs = [1, 2, 4, 5, 8];

      coeffsBN = arrToBN(coeffs);
      amountsBN = arrToBN(amounts);

      await rewardVault.setNewRound(phaseSupply, phaseCount, coeffsBN);
      let expectedMinedAmount = 0;
      let expectedPhase = 0;
      let expectedPhaseAmount = 100;
      for (let i = 0; i < amounts.length; i++) {
        for (let j = 0; j < 4; j++) {
          let balanceBefore = await goldX.balanceOf(alice.address);
          await rewardVault.mineGoldX(alice.address, amountsBN[i]);
          let balanceAfter = await goldX.balanceOf(alice.address);
          let [phase, phaseAmount] = await rewardVault.getMiningPhase();
          let minedAmount = await rewardVault.minedAmount();
          console.log(
            "User sent: ",
            amountsBN[i] / 1e18,
            "FuseG",
            " | User balance: ",
            balanceAfter / 1e18,
            "GoldX",
            " | Phase: ",
            phase,
            " | Phase amount: ",
            phaseAmount / 1e18,
            "GoldX",
            " | Mined amount: ",
            minedAmount / 1e18,
            "GoldX",
            " | Vault depleted: ",
            await rewardVault.vaultDepleted()
          );
          //GoldX sent = X * k, X - FuseG amount, k - phase coeff
          let profit = balanceAfter.sub(balanceBefore) / 1e18;
          expect(profit).to.be.equal(amounts[i] * coeffs[i]);

          expectedMinedAmount += amounts[i] * coeffs[i];
          expectedPhaseAmount -= amounts[i] * coeffs[i];
          //Out of tokens for the current phase? Start new phase
          if (expectedPhaseAmount == 0) {
            expectedPhase++;
            expectedPhaseAmount = 100;
          }
          expect(phase).to.be.equal(expectedPhase);
          expect(minedAmount / 1e18).to.be.equal(expectedMinedAmount);
          expect(phaseAmount / 1e18).to.be.equal(expectedPhaseAmount);
        }
      }
    });
    it("Depletion case - phase overlap", async () => {
      let amounts = [30, 8, 6, 5, 2];
      let phaseSupply = parseEther("100");
      let phaseCount = 5;
      let coeffs = [1, 2, 4, 5, 8];

      coeffsBN = arrToBN(coeffs);
      amountsBN = arrToBN(amounts);

      await rewardVault.setNewRound(phaseSupply, phaseCount, coeffsBN);
      let expectedMinedAmount = 0;
      let expectedPhase = 0;
      let expectedPhaseAmount = 100;
      for (let i = 0; i < amounts.length; i++) {
        for (let j = 0; j < 4; j++) {
          let balanceBefore = await goldX.balanceOf(alice.address);
          await rewardVault.mineGoldX(alice.address, amountsBN[i]);
          let balanceAfter = await goldX.balanceOf(alice.address);
          let [phase, phaseAmount] = await rewardVault.getMiningPhase();
          let minedAmount = await rewardVault.minedAmount();
          console.log(
            "User sent: ",
            amountsBN[i] / 1e18,
            "FuseG",
            " | User balance: ",
            balanceAfter / 1e18,
            "GoldX",
            " | Phase: ",
            phase,
            " | Phase amount: ",
            phaseAmount / 1e18,
            "GoldX",
            " | Mined amount: ",
            minedAmount / 1e18,
            "GoldX",
            " | Vault depleted: ",
            await rewardVault.vaultDepleted()
          );
          //GoldX sent = X * k, X - FuseG amount, k - phase coeff
          //if Y < X, Y - phase supply left
          //send Y + (X - Y/k1) * k2
          let profit = balanceAfter.sub(balanceBefore) / 1e18;

          let X = amounts[i] * coeffs[i];
          let Y = expectedPhaseAmount;
          let expectedProfit = 0;

          //Phase supply has enough tokens
          if (Y > X) {
            expectedProfit = amounts[i] * coeffs[i];
            expectedPhaseAmount -= amounts[i] * coeffs[i];
          }
          //Out of tokens for the current phase? Start new phase
          if (Y == 0) {
            expectedProfit = amounts[i] * coeffs[i];
            expectedPhase++;
            expectedPhaseAmount = 100;
          }
          //Not enough tokens at current phase, send the remainder, start new phase
          if (Y != 0 && Y < X) {
            expectedProfit = Y + (amounts[i] - Y / coeffs[i]) * coeffs[i + 1];
            expectedPhase++;
            expectedPhaseAmount =
              100 - (amounts[i] - Y / coeffs[i]) * coeffs[i + 1];
          }

          expectedMinedAmount += expectedProfit;
          expect(profit).to.be.equal(expectedProfit);
          expect(phase).to.be.equal(expectedPhase);
          expect(minedAmount / 1e18).to.be.equal(expectedMinedAmount);
          expect(phaseAmount / 1e18).to.be.equal(expectedPhaseAmount);
        }
      }
    });
    it("Depletion case - if not enough tokens in the last phase, send all that is left", async () => {
      let fuseGAmount = parseEther("150");
      let phaseSupply = parseEther("100");
      let phaseCount = 2;
      let coeffs = [1, 1];
      coeffs = arrToBN(coeffs);

      await rewardVault.setNewRound(phaseSupply, phaseCount, coeffs);
      await rewardVault.mineGoldX(alice.address, fuseGAmount);
      await rewardVault.mineGoldX(alice.address, fuseGAmount);
      balance = await goldX.balanceOf(alice.address);
      expect(balance).to.be.equal(phaseSupply.mul(phaseCount));
    });
    it("Emits event when GoldX is mined", async () => {
      let fuseGAmount = parseEther("10");
      let phaseSupply = parseEther("100");
      let phaseCount = 5;
      let coeffs = [1, 1, 1, 1, 1];
      coeffs = arrToBN(coeffs);

      await rewardVault.setNewRound(phaseSupply, phaseCount, coeffs);
      await expect(rewardVault.mineGoldX(alice.address, fuseGAmount))
        .to.emit(rewardVault, "Mine")
        .withArgs(alice.address, fuseGAmount);
    });
    it("Emits event when Vault is depleted", async () => {
      let fuseGAmount = parseEther("101");
      let phaseSupply = parseEther("100");
      let phaseCount = 2;
      let coeffs = [1, 1];
      coeffs = arrToBN(coeffs);

      await rewardVault.setNewRound(phaseSupply, phaseCount, coeffs);
      await rewardVault.mineGoldX(alice.address, fuseGAmount);
      await expect(rewardVault.mineGoldX(alice.address, fuseGAmount)).to.emit(
        rewardVault,
        "RewardVaultDepleted"
      );
    });
  });
});
