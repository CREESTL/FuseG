// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRewardVault {
    
    event NewRound(uint256 roundSupply, uint256 phaseSupply, uint8 phaseCount);
    event Mine(address miner, uint256 goldXAmount);
    event RewardVaultDepleted();

    function mineGoldX(address sender, uint256 fuseGAmount) external;
}

