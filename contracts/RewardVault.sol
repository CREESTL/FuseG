// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RewardVault is Ownable {
    IERC20 goldX;

    address public multiSigVault;
    address public fuseG;

    uint256 public initSupply;
    uint256 public precision;
    uint256 private phaseSupply;
    uint8 private phaseCount;

    bool public prevRoundFinished;
    mapping(uint8 => uint256) public coeffTable;

    constructor(address _fuseG, address _goldX, address _multiSigVault) {
        require(_fuseG != address(0), "RV: FUSEG ADDRESS CANNOT BE ZERO");
        require(_goldX != address(0), "RV: GOLDX ADDRESS CANNOT BE ZERO");
        require(_multiSigVault != address(0), "RV: MULTISIGVAULT ADDRESS CANNOT BE ZERO");
        
        goldX = IERC20(_goldX);
        fuseF = _fuseG;
        multiSigVault = _multiSigVault;
    }    

    function setNewRound(uint256 _initSupply, uint256 _phaseSupply, uint8 _phaseCount) public onlyOwner {
        require(!roundActive, "RV: PREVIOUS ROUND HASN'T FINISHED YET");
        initSupply = _initSupply;
        phaseSupply = _phaseSupply;
        phaseCount = _phaseCount;
    }

    function setCoeffs(uint256[] memory coeffs, uint256 precision) public onlyOwner {
        require(coeffs.length == phaseCount, "RV: COEFFS NUM != PHASE COUNT");
        for(uint8 i=0; i<coeffs.length;i++) {
            coeffTable[i] = coeffs[i];
        }
    }
    //TODO make seperate method for calculations
    //TODO add precsision
    //TODO refine formula
    function mineGoldX(address sender, uint256 fuseGAmount) external {
        require(msg.sender == fuseG, "RV: ONLY FUSEG CONTRACT CAN CALL");
        (uint8 phase, uint256 minedAmount) = getMiningPhase(); 
        uint256 remainder = minedAmount % phaseSupply;
        uint256 coeff = coeffTable[phase];
        uint256 goldXAmount = coeff * fuseGAmount;
        if(goldXAmount <= remainder)
            goldX.transfer(sender, goldXAmount);
        else {
            coeff = coeffTable[phase+1];
            goldXAmount = (goldXAmount - remainder) * coef + remainder;
            goldX.transfer(sender, goldXAmount);
        }
    }

    function getMiningPhase() public view returns(uint8 phase, uint256 minedAmount) {
        uint256 reserve = goldX.balanceOf(address(this));
        minedAmount = initSupply - reserve;
        phase = minedAmount / phaseSupply;
        phase += 1;
    }
}
