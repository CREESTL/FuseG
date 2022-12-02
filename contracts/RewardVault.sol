// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "./interfaces/IRewardVault.sol";
import "./interfaces/IGoldX.sol";

// @title Reward wallet provides FuseG contract with GoldX tokens depending on
//        the current mining phase
contract RewardVault is IRewardVault, Ownable, AccessControl, Initializable {
    // @notice the GoldX contract
    IGOLDX goldX;
    // @notice the MultiSigVaule contract
    address public multiSigVault;
    // @notice the FuseG contract
    address public fuseG;

    // @notice the total GoldX supply of the round consisting of multiple phases
    uint256 public roundSupply;
    // @notice the Goldx supply in a single phase
    uint256 private phaseSupply;
    // @notice the nunber of phases in a round
    uint8 private phaseCount;
    // @notice true means that current round is in progress
    // @notice false means that round has ended
    bool public vaultDepleted = true;
    // @notice the amount of GoldX tokens mined in the round
    uint256 public minedAmount;

    // @notice table of coefficients for each phase in the round
    mapping(uint8 => uint256) public coeffTable;
    // @notice counter of the rounds
    uint256 public currentRound;

    // @notice used to convert from decimals = 1 (FuseG) and decimals = 18 (GoldX)
    uint256 private constant PRECISION = 1e18;
    // @notice this role gives a right to set a new round of mining
    bytes32 public constant SUPPLY_ROLE = keccak256("SUPPLY_ROLE");

    /// @notice initializes fuseG platform addresses
    /// @param _fuseG FuseG token address
    /// @param _goldX GoldX token address
    /// @param _multiSigVault multi-signature vault address
    function initialize(
        address _fuseG,
        address _goldX,
        address _multiSigVault
    ) public onlyOwner initializer {
        require(_fuseG != address(0), "RV: FUSEG ADDRESS CANNOT BE ZERO");
        require(_goldX != address(0), "RV: GOLDX ADDRESS CANNOT BE ZERO");
        require(
            _multiSigVault != address(0),
            "RV: MULTISIGVAULT ADDRESS CANNOT BE ZERO"
        );

        goldX = IGOLDX(_goldX);
        fuseG = _fuseG;
        multiSigVault = _multiSigVault;
        // deployer and multisig vault get the supply role
        _grantRole(SUPPLY_ROLE, msg.sender);
        _grantRole(SUPPLY_ROLE, _multiSigVault);
    }

    /// @notice sets new round
    /// @param _phaseSupply GoldX amount in one phase
    /// @param _phaseCount amount of phases
    /// @param _coeffs FuseG : GoldX coefficient for each phase
    function setNewRound(
        uint256 _phaseSupply,
        uint8 _phaseCount,
        uint256[] memory _coeffs
    ) external onlyRole(SUPPLY_ROLE) {
        // a new round can be set only if the previos round was finished
        require(vaultDepleted, "RV: PREVIOUS ROUND HASN'T FINISHED YET");
        // there should be a coefficient for each phase
        require(_coeffs.length == _phaseCount, "RV: COEFFS NUM != PHASE COUNT");
        // there should be enough funds in the vault to distribute
        require(
            _phaseSupply * _phaseCount <= goldX.balanceOf(address(this)),
            "RV: NOT ENOUGH TOKENS TO START A NEW ROUND"
        );

        roundSupply = _phaseSupply * _phaseCount;
        phaseSupply = _phaseSupply;
        phaseCount = _phaseCount;

        // copy phase coefficients to the table for
        for (uint8 i = 0; i < _coeffs.length; i++) {
            coeffTable[i] = _coeffs[i];
        }
        // a new round is marked as not finished
        vaultDepleted = false;
        minedAmount = 0;
        // total number of rounds increases each new round
        currentRound++;
        emit NewRound(roundSupply, phaseSupply, phaseCount);
    }

    /// @notice called by FuseG token, mines GoldX to FuseG holders
    /// @param sender user who initiated FuseG transaction
    /// @param fuseGAmount amount of FuseG tokens in transaction
    function mineGoldX(address sender, uint256 fuseGAmount) external {
        // check that caller is a FuseG contract
        require(msg.sender == fuseG, "RV: ONLY FUSEG CONTRACT CAN CALL");
        (uint8 phase, uint256 remainingPhaseSupply) = getMiningPhase();
        uint256 amountToMine = calcAmountToMine(
            phase,
            remainingPhaseSupply,
            fuseGAmount
        );
        /// check if tx succeeded
        if (!goldX.transfer(sender, amountToMine)) return;

        minedAmount += amountToMine;
        emit Mine(sender, amountToMine);
        if (minedAmount == roundSupply) {
            vaultDepleted = true;
            emit RewardVaultDepleted();
        }
    }

    /// @notice calculates amount of GoldX to distribute to user based on coeffs and phase
    /// @param phase current phase
    /// @param remainingPhaseSupply the rest of GoldX to be mined in the phase
    /// @param fuseGAmount amount of FuseG tokens in transaction
    /// @return GoldX amount to mine
    function calcAmountToMine(
        uint8 phase,
        uint256 remainingPhaseSupply,
        uint256 fuseGAmount
    ) internal view returns (uint256) {
        // the number of phases till the end of the round
        uint8 remainingPhaseCount = phaseCount - phase;
        uint256 coeff;
        // the amount of GoldX tokens that were not mined in the previous phase
        uint256 notMinedInPreviousPhase;
        uint256 amountToMine;

        // there is not enough FuseG to mine all GoldX for all phases
        // (e.g. there is enough FuseG to mine GoldX for 4.5 phases out of 6 phases)

        for (uint8 i = 0; i < remainingPhaseCount; i++) {
            // get the coefficient of corresponding phase
            coeff = coeffTable[phase + i];
            // calculate the amount of GoldX tokens to mine
            // amount must be of decimals = 18
            amountToMine = (fuseGAmount * coeff) / PRECISION;
            if (amountToMine <= remainingPhaseSupply)
                // amount of Goldx to mine is not enough to start a new phase
                return amountToMine + notMinedInPreviousPhase;
            // amount of GoldX is enough to start a new phase
            // decrease the amount of FuseG tokens by the amount that was used in
            // the previous phase
            fuseGAmount -= (remainingPhaseSupply * PRECISION) / coeff;
            // all amount of GoldX tokens that were not mined in the previous phase
            // increases the total amount of not mined GoldX
            notMinedInPreviousPhase += remainingPhaseSupply;
            // remaining supply is a whole supply of a new phase
            remainingPhaseSupply = phaseSupply;
        }

        // there is enough FuseG to mine total required amount of GoldX for all phases or even more

        // if we already mined more GoldX than we need - do not mine anything
        if (minedAmount >= roundSupply) return 0;
        // else just mint the amount of GoldX required to finish the round and not more
        return roundSupply - minedAmount;
    }

    /// @notice getter for mining phase
    /// @return phase current mining phase
    /// @return remainingPhaseSupply the rest of GoldX to be mined in the phase
    function getMiningPhase()
        public
        view
        returns (uint8 phase, uint256 remainingPhaseSupply)
    {
        phase = uint8(minedAmount / phaseSupply);
        remainingPhaseSupply = phaseSupply - (minedAmount % phaseSupply);
    }

    /// @notice returns GOLDX address
    function getGoldX() public view returns (address) {
        return address(goldX);
    }

    /// @notice multi-signature vault can change owner of the reward vault if enough multisigners have voted
    /// @param newOwner new owner of the token contract
    function changeOwner(address newOwner) external {
        require(
            msg.sender == multiSigVault,
            "GOLDX: ONLY MULTISIGNER VAULT CONTRACT CAN CHANGE THE OWNER"
        );
        address oldOwner = owner();
        _transferOwnership(newOwner);

        // Revokes roles from the old owner and grant them to the new owner
        _revokeRole(DEFAULT_ADMIN_ROLE, oldOwner);
        _revokeRole(SUPPLY_ROLE, oldOwner);
        _grantRole(DEFAULT_ADMIN_ROLE, newOwner);
        _grantRole(SUPPLY_ROLE, newOwner);
    }
}
