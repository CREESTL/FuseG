// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

pragma solidity ^0.8.0;

contract MultiSigWallet is Ownable, Initializable {
    event SubmitTransaction(
        address indexed signer,
        uint256 indexed txIndex,
        address indexed to,
        uint256 amount
    );
    event ConfirmTransaction(address indexed signer, uint256 indexed txIndex);
    event RevokeConfirmation(address indexed signer, uint256 indexed txIndex);
    event ExecuteTransaction(address indexed signer, uint256 indexed txIndex);

    IERC20 goldX;
    address public rewardVault;
    address[] public signers;
    mapping(address => bool) public isSigner;

    struct Transaction {
        address to;
        uint256 amount;
        bool executed;
        uint256 numConfirmations;
    }

    // mapping from tx index => signer => bool
    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    Transaction[] public transactions;

    modifier onlySigner() {
        require(isSigner[msg.sender], "MV: NOT THE SIGNER");
        _;
    }

    modifier txExists(uint256 _txIndex) {
        require(_txIndex < transactions.length, "MV: TX DOESN'T EXIST");
        _;
    }

    modifier notExecuted(uint256 _txIndex) {
        require(!transactions[_txIndex].executed, "MV: TX ALREADY EXECUTED");
        _;
    }

    modifier notConfirmed(uint256 _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "MV: TX ALREADY CONFIRMED");
        _;
    }

    constructor(address[] memory _signers) {
        require(_signers.length > 0, "MV: SIGNERS REQUIRED");

        for (uint256 i = 0; i < _signers.length; i++) {
            address signer = _signers[i];

            require(signer != address(0), "MV: INVALID SIGNER");
            require(!isSigner[signer], "MV: SIGNER NOT UNIQUE");

            isSigner[signer] = true;
            signers.push(signer);
        }
    }
    /// @notice Initializes fuseG platform addresses
    /// @param _goldX GoldX token address
    /// @param _rewardVault reward vault address
    function initialize(address _goldX, address _rewardVault)
        public
        onlyOwner
        initializer
    {
        require(_goldX != address(0), "RV: GOLDX ADDRESS CANNOT BE ZERO");
        require(_rewardVault != address(0), "RV: REWARDVAULT ADDRESS CANNOT BE ZERO");
        
        goldX = IERC20(_goldX);
        rewardVault = _rewardVault;
    }    

    function submitTransaction(
        address _to,
        uint256 _amount
    ) public onlySigner {
        uint256 txIndex = transactions.length;

        transactions.push(
            Transaction({
                to: _to,
                amount: _amount,
                executed: false,
                numConfirmations: 0
            })
        );

        emit SubmitTransaction(msg.sender, txIndex, _to, _amount);
    }

    function confirmTransaction(uint256 _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    function executeTransaction(uint256 _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(
            transaction.numConfirmations >= signers.length / 2,
            "MV: NOT ENOUGH CONFIRMATIONS"
        );

        transaction.executed = true;
        goldX.transfer(transaction.to, transaction.amount);

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function revokeConfirmation(uint256 _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(isConfirmed[_txIndex][msg.sender], "MV: TX NOT CONFIRMED");

        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    function getSigners() public view returns (address[] memory) {
        return signers;
    }

    function getTransactionCount() public view returns (uint) {
        return transactions.length;
    }

    function getTransaction(uint256 _txIndex)
        public
        view
        returns (
            address to,
            uint256 amount,
            bool executed,
            uint256 numConfirmations
        )
    {
        Transaction storage transaction = transactions[_txIndex];

        return (
            transaction.to,
            transaction.amount,
            transaction.executed,
            transaction.numConfirmations
        );
    }
}
