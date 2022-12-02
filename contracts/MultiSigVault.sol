// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/IRewardVault.sol";
import "./interfaces/IMultiSigVault.sol";
import "./interfaces/IGoldX.sol";

pragma solidity ^0.8.0;

// @title Multi-signature vault. Owners of the vault vote on proposals
contract MultiSigVault is IMultiSigVault, Ownable, Initializable {
    using EnumerableSet for EnumerableSet.AddressSet;

    // @notice the GoldX contract
    IGOLDX goldX;
    // @notice the RewardVault contract
    IRewardVault rewardVault;
    // @notice list of signers whos signatures are required to execute the proposal
    EnumerableSet.AddressSet signers;

    // @dev mapping from proposal index to signer to bool
    // @dev idicates wether a signer has confirmed a proposal
    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    // @notice list of all proposals
    Proposal[] public proposals;

    /// @notice allows only multi-signers to call the function
    modifier onlySigner() {
        require(signers.contains(msg.sender), "MV: NOT A SIGNER");
        _;
    }

    /// @notice checks if proposal exists inside proposals array
    /// @param _proposalIndex proposal index inside proposals array
    modifier proposalExists(uint256 _proposalIndex) {
        require(
            _proposalIndex < proposals.length,
            "MV: PROPOSAL DOESN'T EXIST"
        );
        _;
    }

    /// @notice checks if proposal has been executed
    /// @param _proposalIndex proposal index inside proposals array
    modifier notExecuted(uint256 _proposalIndex) {
        require(
            !proposals[_proposalIndex].executed,
            "MV: PROPOSAL ALREADY EXECUTED"
        );
        _;
    }

    /// @notice checks if proposal has been confirmed
    /// @param _proposalIndex proposal index inside proposals array
    modifier notConfirmed(uint256 _proposalIndex) {
        require(
            !isConfirmed[_proposalIndex][msg.sender],
            "MV: PROPOSAL ALREADY CONFIRMED"
        );
        _;
    }

    /// @notice constructor with initial signers
    /// @param _signers array of signer addresses
    constructor(address[] memory _signers) {
        require(_signers.length > 0, "MV: ADD AT LEAST ONE SIGNER");
        // each signer is checked and added to the list
        for (uint256 i = 0; i < _signers.length; i++) {
            require(_signers[i] != address(0), "MV: INVALID SIGNER");
            require(!signers.contains(_signers[i]), "MV: SIGNER NOT UNIQUE");
            signers.add(_signers[i]);
        }
    }

    /// @notice initializes fuseG platform addresses
    /// @param _goldX GoldX token address
    /// @param _rewardVault reward vault address
    function initialize(
        address _goldX,
        address _rewardVault
    ) public onlyOwner initializer {
        require(_goldX != address(0), "RV: GOLDX ADDRESS CANNOT BE ZERO");
        require(
            _rewardVault != address(0),
            "RV: REWARDVAULT ADDRESS CANNOT BE ZERO"
        );

        goldX = IGOLDX(_goldX);
        rewardVault = IRewardVault(_rewardVault);
    }

    /// @notice Sets new round
    /// @param _phaseSupply GoldX amount in one phase
    /// @param _phaseCount amount of phases
    /// @param _coeffs FuseG : GoldX coefficient for each phase
    function setNewRound(
        uint256 _phaseSupply,
        uint8 _phaseCount,
        uint256[] memory _coeffs
    ) public onlyOwner {
        rewardVault.setNewRound(_phaseSupply, _phaseCount, _coeffs);
    }

    /// @notice allows the owner to manually add a multi-signer
    /// @param _newSigner new multi-signer address
    function addMultiSigner(address _newSigner) public onlyOwner {
        require(!signers.contains(_newSigner), "MV: SIGNER NOT UNIQUE");
        signers.add(_newSigner);
    }

    /// @notice allows the owner to manually remove a multi-signer
    /// @param _signer address of the multi-signer to remove
    function removeMultiSigner(address _signer) public onlyOwner {
        require(signers.contains(_signer), "MV: SIGNER DOESN'T EXIST");
        signers.remove(_signer);
    }

    /// @notice submits the proposal
    /// @param _proposalType see Proposals enum
    /// @param _to subject of the proposal
    /// @param _amount GoldX amount to send if tx type proposal
    function submitProposal(
        Proposals _proposalType,
        address _to,
        uint256 _amount
    ) public onlySigner {
        uint256 proposalIndex = proposals.length;

        proposals.push(
            Proposal({
                proposalType: _proposalType,
                to: _to,
                amount: _amount,
                executed: false,
                numConfirmations: 0
            })
        );

        emit SubmitProposal(
            msg.sender,
            _proposalType,
            proposalIndex,
            _to,
            _amount
        );
    }

    /// @notice allows a multi-signer to confirm a proposal
    /// @param _proposalIndex index of the proposal inside proposals array
    function confirmProposal(
        uint256 _proposalIndex
    )
        public
        onlySigner
        proposalExists(_proposalIndex)
        notExecuted(_proposalIndex)
        notConfirmed(_proposalIndex)
    {
        Proposal storage proposal = proposals[_proposalIndex];
        // count proposal confirmations
        proposal.numConfirmations += 1;
        // mark that thos proposal was confirmed
        isConfirmed[_proposalIndex][msg.sender] = true;

        emit ConfirmProposal(msg.sender, _proposalIndex);
    }

    /// @notice executes the proposal if it has enough votes
    /// @param _proposalIndex index of the proposal inside proposals array
    function executeProposal(
        uint256 _proposalIndex
    )
        public
        onlySigner
        proposalExists(_proposalIndex)
        notExecuted(_proposalIndex)
    {
        Proposal storage proposal = proposals[_proposalIndex];
        // (e.g. 4002 / 2 = 2001)
        uint256 halfOfAllSigners = signers.length() / 2;
        // round up to the closest integer
        // (e.g.2001 + 2001 mod 2 = 2002)
        uint256 numToConfirm = halfOfAllSigners + (halfOfAllSigners % 2);

        // half of all signers have to sign the proposal to execute it
        require(
            proposal.numConfirmations >= numToConfirm,
            "MV: NOT ENOUGH CONFIRMATIONS"
        );

        // mark the proposal as executed right away
        proposal.executed = true;
        // transfer GoldX if the proposal was about transaction
        if (proposal.proposalType == Proposals.Transaction)
            require(
                goldX.transfer(proposal.to, proposal.amount),
                "MV: GOLDX TRANSFER FAILED"
            );
        // add a signer if the proposal was about adding a signer
        if (proposal.proposalType == Proposals.AddSigner)
            signers.add(proposal.to);
        // remove a signer if the proposal was about removing a signer
        if (proposal.proposalType == Proposals.RemoveSigner)
            signers.remove(proposal.to);
        // change the owner of all contracts if the proposal was about changing owner
        if (proposal.proposalType == Proposals.ChangeOwner) {
            _changeOwner(proposal.to);
            rewardVault.changeOwner(proposal.to);
            goldX.changeOwner(proposal.to);
        }
        emit ExecuteProposal(msg.sender, _proposalIndex);
    }

    /// @notice revokes one singer's confirmation of the proposal
    /// @param _proposalIndex index of the proposal inside proposals array
    function revokeConfirmation(
        uint256 _proposalIndex
    )
        public
        onlySigner
        proposalExists(_proposalIndex)
        notExecuted(_proposalIndex)
    {
        Proposal storage proposal = proposals[_proposalIndex];

        // the proposal must be confirmed to remove confirmation
        require(
            isConfirmed[_proposalIndex][msg.sender],
            "MV: PROPOSAL NOT CONFIRMED"
        );

        // decrease the number of confirmations and mark the proposal as not confirmed
        proposal.numConfirmations -= 1;
        isConfirmed[_proposalIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _proposalIndex);
    }

    /// @notice returns the list of all signers
    function getSigners() public view returns (address[] memory) {
        return signers.values();
    }

    /// @notice returns amount of all proposals
    function getProposalCount() public view returns (uint) {
        return proposals.length;
    }

    /// @notice returns info on specific proposal
    /// @param _proposalIndex index of the proposal inside proposals array
    function getProposal(
        uint256 _proposalIndex
    )
        public
        view
        returns (
            Proposals proposalType,
            address to,
            uint256 amount,
            bool executed,
            uint256 numConfirmations
        )
    {
        Proposal storage proposal = proposals[_proposalIndex];

        return (
            proposal.proposalType,
            proposal.to,
            proposal.amount,
            proposal.executed,
            proposal.numConfirmations
        );
    }

    /// @notice returns reward vault address
    function getRewardVault() public view returns (address) {
        return address(rewardVault);
    }

    /// @notice returns GOLDX address
    function getGoldX() public view returns (address) {
        return address(goldX);
    }

    /// @notice changes this contract's owner
    /// @param newOwner new owner of the token contract
    function _changeOwner(address newOwner) private {
        _transferOwnership(newOwner);
    }
}
