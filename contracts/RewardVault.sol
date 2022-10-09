// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IRewardVault.sol";

contract RewardVault is IRewardVault, Ownable{
    IERC20 goldX;

    address public multiSigVault;
    address public fuseG;

    uint256 public roundSupply;
    uint256 private phaseSupply;
    uint8 private phaseCount;

    bool public vaultDepleted;
    uint256 public minedAmount;

    mapping(uint8 => uint256) public coeffTable;
    uint256 public currentRound;

    uint256 private constant PRECISION = 1e18;

    constructor(address _fuseG, address _goldX, address _multiSigVault) {
        require(_fuseG != address(0), "RV: FUSEG ADDRESS CANNOT BE ZERO");
        require(_goldX != address(0), "RV: GOLDX ADDRESS CANNOT BE ZERO");
        require(_multiSigVault != address(0), "RV: MULTISIGVAULT ADDRESS CANNOT BE ZERO");
        
        goldX = IERC20(_goldX);
        fuseG = _fuseG;
        multiSigVault = _multiSigVault;
    }    

    function setNewRound(uint256 _phaseSupply, uint8 _phaseCount, uint256[] memory _coeffs) public onlyOwner {
        require(vaultDepleted, "RV: PREVIOUS ROUND HASN'T FINISHED YET");
        require(_coeffs.length == phaseCount, "RV: COEFFS NUM != PHASE COUNT");
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

    function mineGoldX(address sender, uint256 fuseGAmount) external {
        require(msg.sender == fuseG, "RV: ONLY FUSEG CONTRACT CAN CALL");
        uint8 phase = getMiningPhase(); 
        uint256 amountToMine = calcAmountToMine(phase, fuseGAmount);
        goldX.transfer(sender, amountToMine);
        minedAmount += amountToMine;
        emit Mine(sender, amountToMine);
        if(minedAmount == roundSupply){
            vaultDepleted = true;
            emit RewardVaultDepleted();
        }
    }

    function calcAmountToMine(uint8 phase, uint256 fuseGAmount) internal view returns(uint256) {
        uint8 remainingPhaseCount = phaseCount - phase;
        uint256 coeff;
        uint256 acc;
        uint256 amountToMine;
        for(uint8 i=0; i<remainingPhaseCount; i++) {
            coeff = coeffTable[phase + i];
            amountToMine = fuseGAmount * coeff / PRECISION;
            if(amountToMine <= phaseSupply)
                return amountToMine + acc;
            fuseGAmount -= phaseSupply * PRECISION / coeff;
            acc += phaseSupply;
        }
        if(minedAmount >= roundSupply)
            return 0;
        return roundSupply - minedAmount;
    }

    function getMiningPhase() public view returns(uint8) {
        uint8 phase = uint8(minedAmount / phaseSupply);
        return phase;
    }
}
