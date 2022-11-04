// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMultiSigVault {

    /// @notice proposal types 0-tx, 1-add signer, 2-remove signer, 3-change GoldX owner
    enum Proposals {
        Transaction,
        AddSigner,
        RemoveSigner,
        ChangeOwner
    }

    /// @notice structure, contains proposal options
    /// @param proposalType see Proposals enum 
    /// @param to subject of the proposal 
    /// @param amount GoldX amount to send if tx type proposal
    /// @param executed  is proposal executed
    /// @param numConfirmations current amount of votes for this proposal
    struct Proposal {
        Proposals proposalType;
        address to;
        uint256 amount;
        bool executed;
        uint256 numConfirmations;
    }

    /// @notice event indicating that new proposal was created
    /// @param signer proposal initiator
    /// @param proposalType see Proposals enum
    /// @param proposalIndex index of the proposal inside proposals array
    /// @param to subject of the proposal 
    /// @param amount GoldX amount to send if tx type proposal
    event SubmitProposal(
        address indexed signer,
        Proposals indexed proposalType,
        uint256 indexed proposalIndex,
        address to,
        uint256 amount
    );
    /// @notice event indicating confirmation of the proposal by a signer
    /// @param signer signer who confirmed the proposal
    /// @param proposalIndex index of the proposal inside proposals array
    event ConfirmProposal(address indexed signer, uint256 indexed proposalIndex);
    /// @notice event indicating that confirmation was cancelled by a signer
    /// @param signer signer who cancelled his confirmation
    /// @param proposalIndex index of the proposal inside proposals array
    event RevokeConfirmation(address indexed signer, uint256 indexed proposalIndex);
    /// @notice event indicating that proposal was executed by majority of votes
    /// @param signer signer who executed the proposal
    /// @param proposalIndex index of the proposal inside proposals array
    event ExecuteProposal(address indexed signer, uint256 indexed proposalIndex);
}


