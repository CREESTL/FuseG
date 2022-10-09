// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRewardVault {
    
    /// @notice event indicating set of the new round
    /// @param roundSupply GoldX amount in one round
    /// @param phaseSupply GoldX amount in one phase
    /// @param phaseCount amount of phases
    event NewRound(uint256 roundSupply, uint256 phaseSupply, uint8 phaseCount);
    /// @notice indicates GoldX mining via FuseG transfer
    /// @param miner GoldX receiver
    /// @param goldXAmount GoldX amount
    event Mine(address miner, uint256 goldXAmount);
    /// @notice indicates that reward vault is out of GoldX, all phases are finished
    event RewardVaultDepleted();

    function mineGoldX(address sender, uint256 fuseGAmount) external;
}

