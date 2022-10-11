// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "./interfaces/IRewardVault.sol";
import "hardhat/console.sol";
contract RewardVault is IRewardVault, Ownable, AccessControl, Initializable{
    IERC20 goldX;

    address public multiSigVault;
    address public fuseG;

    uint256 public roundSupply;
    uint256 private phaseSupply;
    uint8 private phaseCount;

    bool public vaultDepleted = true;
    uint256 public minedAmount;

    mapping(uint8 => uint256) public coeffTable;
    uint256 public currentRound;

    uint256 private constant PRECISION = 1e18;
    bytes32 public constant SUPPLY_ROLE = keccak256("SUPPLY_ROLE");

    /// @notice Initializes fuseG platform addresses
    /// @param _fuseG FuseG token address
    /// @param _goldX GoldX token address
    /// @param _multiSigVault multi-signature vault address
    function initialize(address _fuseG, address _goldX, address _multiSigVault)
        public
        onlyOwner
        initializer
    {
        require(_fuseG != address(0), "RV: FUSEG ADDRESS CANNOT BE ZERO");
        require(_goldX != address(0), "RV: GOLDX ADDRESS CANNOT BE ZERO");
        require(_multiSigVault != address(0), "RV: MULTISIGVAULT ADDRESS CANNOT BE ZERO");
        
        goldX = IERC20(_goldX);
        fuseG = _fuseG;
        multiSigVault = _multiSigVault;
        _grantRole(SUPPLY_ROLE, msg.sender);
        _grantRole(SUPPLY_ROLE, _multiSigVault);

    }    

    /// @notice Sets new round
    /// @param _phaseSupply GoldX amount in one phase
    /// @param _phaseCount amount of phases
    /// @param _coeffs FuseG : GoldX coefficient for each phase
    function setNewRound(uint256 _phaseSupply, uint8 _phaseCount, uint256[] memory _coeffs) public onlyRole(SUPPLY_ROLE) {
        require(vaultDepleted, "RV: PREVIOUS ROUND HASN'T FINISHED YET");
        require(_coeffs.length == _phaseCount, "RV: COEFFS NUM != PHASE COUNT");
        require(
            _phaseSupply * _phaseCount <= goldX.balanceOf(address(this)),
            "RV: NOT ENOUGH TOKENS TO START A NEW ROUND"
        );

        roundSupply = _phaseSupply * _phaseCount;
        phaseSupply = _phaseSupply;
        phaseCount = _phaseCount;

        for(uint8 i=0; i<_coeffs.length;i++) {
            coeffTable[i] = _coeffs[i];
        }
        vaultDepleted = false;
        minedAmount = 0;
        currentRound ++;
        emit NewRound(roundSupply, phaseSupply, phaseCount); 
    }

    /// @notice Called by FuseG token, mines GoldX to FuseG holders
    /// @param sender user who initiated FuseG transaction
    /// @param fuseGAmount amount of FuseG tokens in transaction
    function mineGoldX(address sender, uint256 fuseGAmount) external {
        require(msg.sender == fuseG, "RV: ONLY FUSEG CONTRACT CAN CALL");
        (uint8 phase, uint256 remainingPhaseSupply) = getMiningPhase(); 
        uint256 amountToMine = calcAmountToMine(phase, remainingPhaseSupply, fuseGAmount);
        goldX.transfer(sender, amountToMine);
        minedAmount += amountToMine;
        emit Mine(sender, amountToMine);
        if(minedAmount == roundSupply){
            vaultDepleted = true;
            emit RewardVaultDepleted();
        }
    }

    /// @notice Calculates amount of GoldX to distribute to user based on coeffs and phase
    /// @param phase current phase
    /// @param remainingPhaseSupply current phase GoldX amount 
    /// @param fuseGAmount amount of FuseG tokens in transaction
    /// @return GoldX amount to mine
    function calcAmountToMine(uint8 phase, uint256 remainingPhaseSupply, uint256 fuseGAmount) internal view returns(uint256) {
        uint8 remainingPhaseCount = phaseCount - phase;
        uint256 coeff;
        uint256 acc;
        uint256 amountToMine;
        uint256 supply = remainingPhaseSupply;
        for(uint8 i=0; i<remainingPhaseCount; i++) {
            coeff = coeffTable[phase + i];
            amountToMine = fuseGAmount * coeff / PRECISION;
            if(amountToMine <= supply)
                return amountToMine + acc;
            fuseGAmount -= supply * PRECISION / coeff;
            acc += supply;
            supply = phaseSupply;
        }
        if(minedAmount >= roundSupply)
            return 0;
        return roundSupply - minedAmount;
    }

    /// @notice Getter for mining phase
    /// @return phase current mining phase
    /// @return remainingPhaseSupply current phase GoldX amount 
    function getMiningPhase() public view returns(uint8 phase, uint256 remainingPhaseSupply) {
        phase = uint8(minedAmount / phaseSupply);
        remainingPhaseSupply = phaseSupply - (minedAmount % phaseSupply);
    }
}
