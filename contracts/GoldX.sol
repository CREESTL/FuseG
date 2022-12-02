// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/IGoldX.sol";

/// @title The GoldX token smart contract.
///        This is the native token of the GoldX platform
contract GOLDX is Context, IGOLDX, Ownable, AccessControl, Pausable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @dev NOTE: this contract uses the principals of RFI tokens
    ///            for detailed documentation please see:
    ///            https://reflect-contract-doc.netlify.app/#a-technical-whitepaper-for-reflect-contracts
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;

    /// @dev allowances of users
    mapping(address => mapping(address => uint256)) private _allowances;

    /// @dev addresses that are excluded from token distribution
    mapping(address => bool) private _isExcluded;
    address[] private _excluded;

    /// @dev the maximum possible amount of token both from t-space and r-space
    uint256 private constant MAX = ~uint256(0);
    /// @dev the maximum possible amount of tokens from t-space
    uint256 private _tTotal = 2_200_000_000 * 1e18;
    /// @dev the maximum possible amount of tokens from r-space
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    /// @dev the total amount of fees paid for transfers in t-space
    uint256 private _tFeeTotal;

    /// @dev credentials of the token
    string private _name = "GOLDX";
    string private _symbol = "GLDX";
    uint8 private _decimals = 18;

    /// @dev this role gives a right for many admin-only functions
    bytes32 public constant SUPERADMIN_ROLE = keccak256("SUPERADMIN_ROLE");

    /// @notice the list of users who can not transfer GoldX tokens
    mapping(address => bool) public blacklist;
    /// @notice the list of users who do not pay fees for GoldX transfers
    mapping(address => bool) public whitelist;

    uint256 private constant PCT_RATE = 100;
    /// @notice the amount of GoldX tokens paid as fee for each transaction
    uint256 public feeAmount;
    /// @notice the part of `feeAmount` that should be transferred to GoldX holders
    uint256 private feeToHolders;
    /// @notice the part of `feeAmount` that should be transferred to treasury wallet
    uint256 private feeToTreasury;
    /// @notice the part of `feeAmount` that should be transferred to participants of referral program
    uint256 private feeToReferrals;
    /// @notice the part of `feeAmount` that should be burnt
    uint256 private feeToBurn;

    /// @dev the address team's wallet
    address private teamWallet;
    /// @dev the address wallet used for marketing
    address private marketing;
    /// @notice the address of the treasury wallet
    address public treasury;
    /// @notice the address of the reward vault contract
    address public rewardVault;
    /// @notice the address of the multisig vault contract
    address public multiSigVault;

    /// @notice returns referrer's address for a given referral
    mapping(address => address) public referrer;
    /// @dev holds "snapshot" of the current state of users account
    mapping(address => uint256) private snapshot;
    /// @dev the rewards of each participant of referral program
    mapping(address => uint256) private personalReward;
    EnumerableSet.AddressSet referrers;
    EnumerableSet.AddressSet referrals;
    /// @dev total reward for unique members of referral program
    uint256 private compositeReferralReward;
    /// @dev total referral reward collected (in t-space)
    uint256 private _tReferralReward;
    /// @dev total referral reward collected (in r-space)
    uint256 private _rReferralReward;
    /// @dev total number of unique members of referral program
    uint256 private uniqueUsersCount;
    /// @notice time that should pass for referer to change his referee 
    uint256 public cooldown;
    /// @dev keeps track of moments when users were added to
    ///      the referral program
    mapping(address => uint256) private timestamp;

    /// @notice checks if user is in the blacklist
    /// @param account user's address
    modifier notInBlacklist(address account) {
        require(!blacklist[account], "GOLDX: USER IS BLACKLISTED");
        _;
    }

    /// @notice constructor with FuseG platform addresses
    /// @param _teamWallet team wallet address
    /// @param _marketing marketing wallet address
    /// @param _treasury treasury address
    /// @param _rewardVault reward vault address
    /// @param _multiSigVault multi-signature vault address
    constructor(
        address _teamWallet,
        address _marketing,
        address _treasury,
        address _rewardVault,
        address _multiSigVault
    ) {
        require(
            _teamWallet != address(0),
            "GOLDX: TEAMWALLET ADDRESS CANNOT BE ZERO"
        );
        require(
            _marketing != address(0),
            "GOLDX: MARKETING ADDRESS CANNOT BE ZERO"
        );
        require(
            _treasury != address(0),
            "GOLDX: TREASURY ADDRESS CANNOT BE ZERO"
        );
        require(
            _rewardVault != address(0),
            "GOLDX: REWARDVAULT ADDRESS CANNOT BE ZERO"
        );
        require(
            _multiSigVault != address(0),
            "GOLDX: MULTISIGVAULT ADDRESS CANNOT BE ZERO"
        );

        teamWallet = _teamWallet;
        marketing = _marketing;
        treasury = _treasury;
        rewardVault = _rewardVault;
        multiSigVault = _multiSigVault;

        // calculate the rate (for RFI tokens)
        uint256 rate = _rTotal.div(_tTotal);

        // tokens are spread between different accounts
        _rOwned[_teamWallet] = uint256(5_000_000 * 1e18).mul(rate);
        _rOwned[_marketing] = uint256(5_000_000 * 1e18).mul(rate);
        _rOwned[_rewardVault] = uint256(101_110_100 * 1e18).mul(rate);
        _rOwned[_multiSigVault] = uint256(2_088_889_900 * 1e18).mul(rate);

        emit Transfer(address(0), _teamWallet, 5_000_000 * 1e18);
        emit Transfer(address(0), _marketing, 5_000_000 * 1e18);
        emit Transfer(address(0), _rewardVault, 101_110_100 * 1e18);
        emit Transfer(address(0), _multiSigVault, 2_088_889_900 * 1e18);

        // exclude rewards vauld and multisig vault from transactions fees distribution
        excludeAccount(_rewardVault);
        excludeAccount(_multiSigVault);
        whitelist[_rewardVault] = true;
        whitelist[_multiSigVault] = true;

        // deployer gets all possible roles
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SUPERADMIN_ROLE, msg.sender);

        // set default fees to 10%
        // 10% of GoldX from each transaction will be distributed among GoldX holders (RFI)
        setFees(10);
        // set fee distribution: 7% - to holders, 1% - to treasury, 1% - to burn, 1% - to referral program
        setFeeDistribution(70, 10, 10, 10);
        // default referral cooldown is 90 days
        cooldown = 90 days;
    }

    /// @notice returns the name of the token
    /// @return the name of the token
    function name() public view returns (string memory) {
        return _name;
    }

    /// @notice returns the symbol of the token
    /// @return the symbol of the token
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /// @notice returns the decimals amount of the token
    /// @return the decimals amount of the token
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /// @notice returns the totalSupply amount of the token
    /// @return the total supply of the token
    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    /// @notice returns the balance of the user
    /// @param account user's address
    /// @dev this is where user's balance is calculated using the amount of token 
    ///      from r-space. The less tokens in r-space there are, the higher the 
    ///      user's balance is. Main feature of RFI.
    /// @dev balance is in t-space
    /// @return the balance of the user
    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        // If user is a part of referral program, his balance consists of
        // his tokens from r-space and rewards for referral program
        if (referrers.contains(account) || referrals.contains(account)) {
            uint256 totalReward = getCompositeReferralReward() -
                snapshot[account];
            return
                tokenFromReflection(_rOwned[account]) +
                totalReward +
                personalReward[account];
        }
        // If user is not a part of referral program, his balance is 
        // calculated only based on the current amount of r-space 
        // tokens on his balance
        return tokenFromReflection(_rOwned[account]);
    }

    /// @notice transfers tokens to a given address
    /// @param recipient recipient's address
    /// @param amount amount of tokens to send
    /// @return boolean value indicating whether the operation succeeded.
    function transfer(
        address recipient,
        uint256 amount
    ) public override whenNotPaused returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /// @notice returns the amount of tokens that spender is allowed to spend on behalf of owner
    /// @param owner owner of the tokens
    /// @param spender spender's address
    /// @return the amount of tokens that spender is allowed to spend of behalf of owner
    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /// @notice allows spender to spend tokens on behalf of the transaction sender via transferFrom
    /// @param spender spender's address
    /// @param amount amount of tokens that spender is allowed to spent
    /// @return boolean value indicating whether the operation succeeded.
    function approve(
        address spender,
        uint256 amount
    ) public override whenNotPaused returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /// @notice transfers tokens to a given address on behalf of the owner
    /// @param sender sender's address
    /// @param recipient recipient's address
    /// @param amount amount of tokens
    /// @return boolean value indicating whether the operation succeeded.
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override whenNotPaused returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    /// @notice increases amount of tokens to spend on behalf of an owner
    /// @param spender sender's address
    /// @param addedValue amount of tokens
    /// @return boolean value indicating whether the operation succeeded.
    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual whenNotPaused returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    /// @notice decreases amount of tokens to spend on behalf of an owner
    /// @param spender sender's address
    /// @param subtractedValue amount of tokens
    /// @return boolean value indicating whether the operation succeeded.
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual whenNotPaused returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    /// @notice checks if user is excluded from fees distribution 
    /// @param account user's address
    /// @return boolean value indicating wether account is excluded from fees distribution
    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    /// @notice sets transaction fees amount
    /// @param _feeAmount transaction fee amount
    function setFees(uint256 _feeAmount) public whenNotPaused onlyOwner {
        require(_feeAmount <= 15, "GOLDX: 0% >= TRANSACTION FEE <= 15%");
        feeAmount = _feeAmount;
        emit SetFees(_feeAmount);
    }

    /// @notice sets fee distribution
    /// @param _toHolders fee share to token holders
    /// @param _toTreasury fee share to treasury
    /// @param _toBurn fee share to burn
    /// @param _toReferrals fee share to referrals
    function setFeeDistribution(
        uint256 _toHolders,
        uint256 _toTreasury,
        uint256 _toBurn,
        uint256 _toReferrals
    ) public whenNotPaused onlyOwner {
        require(feeAmount != 0, "GOLDX: TRANSACTION FEE IS ZERO");
        uint256 sum = _toHolders + _toTreasury + _toBurn + _toReferrals;
        require(sum == 100, "GOLDX: WRONG DISTRIBUTION, SUM MUST EQUAL 100%");
        feeToHolders = _toHolders;
        feeToTreasury = _toTreasury;
        feeToBurn = _toBurn;
        feeToReferrals = _toReferrals;
    }

    /// @notice returns fee distribution
    /// @return feeToHolders holders share
    /// @return feeToTreasury treasury share
    /// @return feeToBurn burn wallet share
    /// @return feeToReferrals referrals share
    function getFeeDistribution()
        public
        view
        returns (uint256, uint256, uint256, uint256)
    {
        return (feeToHolders, feeToTreasury, feeToBurn, feeToReferrals);
    }

    /// @notice returns amount of collected fees
    /// @return the amount of collected fees
    /// @dev the amount of collected fees is in t-space
    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    /// @notice reflects/distributes tAmount between non-excluded holders
    /// @param tAmount amount of tokens to distribute
    function reflect(uint256 tAmount) public whenNotPaused {
        address sender = _msgSender();
        require(
            !_isExcluded[sender],
            "Excluded addresses cannot call this function"
        );
        // convert the amount from t-space to r-space
        (uint256 rAmount, , , , ) = _getValues(tAmount);
        // decrease user's balance in r-space
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        // decrease the total amount of tokens in r-space
        _rTotal = _rTotal.sub(rAmount);
        // increase the total fee in t-space 
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    /// @notice transforms token amount from t-space to r-space
    /// @param tAmount amount of tokens in r-space
    /// @param deductTransferFee true if fee should be deducted
    /// @return the amount of r-space tokens equal to t-space amount
    function reflectionFromToken(
        uint256 tAmount,
        bool deductTransferFee
    ) public view returns (uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount, , , , ) = _getValues(tAmount);
            return rAmount;
        } else {
            (, uint256 rTransferAmount, , , ) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    /// @notice transforms token amount from r-space to t-space
    /// @param rAmount token amount in r-space
    /// @return the amount of t-space tokens equal to r-space amount
    function tokenFromReflection(
        uint256 rAmount
    ) public view returns (uint256) {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    /// @dev sets the new allowance for the spender
    /// @param owner the owner of tokens
    /// @param spender the one spending owner's tokens
    /// @param amount the amount of tokens spender is allowed to spend
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /// @dev transfers t-space tokens from one user to another
    /// @param sender the user owning tokens
    /// @param recipient the user receiving tokens of the owner
    /// @param amount the amount of t-space tokens to transfer from sender to recipient
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private notInBlacklist(sender) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        // if sender is a member of the referral program he gets extra rewards
        if (referrers.contains(sender) || referrals.contains(sender)) {
            uint256 tReward = getCompositeReferralReward() - snapshot[sender];
            uint256 rReward = tReward.add(personalReward[sender]).mul(
                _getRate()
            );
            _rOwned[sender] = _rOwned[sender].add(rReward);
            snapshot[sender] = snapshot[sender].add(tReward);
            // senders personal reward for the referral program gets reset
            personalReward[sender] = 0;
        }

        // make different types of transfers if sender or recipient are excluded from
        // fees distribution
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
    }

    /// @dev transfers tokens from the sender who is not excluded from fees distribution
    ///      to the recipient who is not excluded from the distribution
    /// @param sender the owner of the tokens
    /// @param recipient the user who receives sender's tokens
    /// @param tAmount the amount of t-space tokens to be transferred
    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _reflectAndProcessFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    /// @dev transfers tokens from the sender who is not excluded from fees distribution
    ///      to the recipient who is excluded from the distribution
    /// @param sender the owner of the tokens
    /// @param recipient the user who receives sender's tokens
    /// @param tAmount the amount of t-space tokens to be transferred
    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _reflectAndProcessFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    /// @dev transfers tokens from the sender who is excluded from fees distribution
    ///      to the recipient who is not excluded 
    /// @param sender the owner of the tokens
    /// @param recipient the user who receives sender's tokens
    /// @param tAmount the amount of t-space tokens to be transferred
    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _reflectAndProcessFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    /// @dev transfers tokens from the sender who is excluded from fees distribution
    ///      to the recipient who is excluded from the distribution as well
    /// @param sender the owner of the tokens
    /// @param recipient the user who receives sender's tokens
    /// @param tAmount the amount of t-space tokens to be transferred
    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _reflectAndProcessFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }


    /// @dev distributes fees among of destinations
    /// @param rFee the amount of r-space tokens paid as fees
    /// @param tFee the amount of t-space tokens paid as fees
    function _reflectAndProcessFee(uint256 rFee, uint256 tFee) private {
        // get the fee distribution among all destinations
        (
            uint256 rToHolders,
            uint256 rToTreasury,
            uint256 rToBurn,
            uint256 rToReferrals
        ) = _getFeeDistribution(rFee);
        // convert amounts from r-space into t-space
        uint256 tToBurn = tokenFromReflection(rToBurn);
        uint256 tToHolders = tokenFromReflection(rToHolders);
        uint256 tToTreasury = tokenFromReflection(rToTreasury);
        uint256 tToReferrals = tokenFromReflection(rToReferrals);
        // if user has a referrer, split rewards between them
        if (referrer[msg.sender] != address(0)) {
            // each gets half of the reward if t-space tokens
            personalReward[msg.sender] = personalReward[msg.sender].add(
                tToReferrals.div(2)
            );
            personalReward[referrer[msg.sender]] = personalReward[
                referrer[msg.sender]
            ].add(tToReferrals.div(2));
            // count total referral program rewards in both spaces
            _rReferralReward = _rReferralReward.add(rToReferrals);
            _tReferralReward = _tReferralReward.add(tToReferrals);
        // else all referrals and referrers ahare equal amount of toReferrals value
        } else {
            compositeReferralReward = compositeReferralReward.add(tToReferrals);
            // count total referral program rewards in both spaces
            _rReferralReward = _rReferralReward.add(rToReferrals);
            _tReferralReward = _tReferralReward.add(tToReferrals);
        }

        // add t- and r-space tokens amount to the treasury balance
        _rOwned[treasury] = _rOwned[treasury].add(rToTreasury);
        _tOwned[treasury] = _tOwned[treasury].add(tToTreasury);

        // decrease the total amount of r-space tokens by the amount that
        // is distributed among GoldX holders and the amount that is burnt
        _rTotal = _rTotal.sub(rToHolders).sub(rToBurn);
        _tTotal = _tTotal.sub(tToBurn);

        // add the amount of t-space tokens paid as fees to the total amout of fees
        _tFeeTotal = _tFeeTotal.add(tFee);

        emit Distribute(msg.sender, tToHolders);
        emit Transfer(msg.sender, address(0), tToBurn);
        emit Transfer(msg.sender, treasury, tToTreasury);
    }

    /// @dev returns r- and t-space amount of tokens necessary for future calculations
    /// @param tAmount the amount of t-space tokens that are supposed to be transferred
    /// @return rAmount the amount of r-space tokens that are supposed to be transferred
    /// @return rTransferAmount the amount of r-space tokens that would be transferred
    /// @return rFee the amount of r-space tokens that would be paid and distributed as fees 
    /// @return tTransferAmount the amount of t-space tokens that are supposed to be transferred 
    /// @return tFee the amount of t-space tokens that would be transferred 
    function _getValues(
        uint256 tAmount
    ) private view returns (uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee) = _getTValues(tAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            currentRate
        );
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee);
    }

    /// @dev returns the amount of t-space tokens to transfer and 
    ///      t-space tokens transfer fee
    /// @param tAmount the amount of t-space token to transfer
    /// @return tTransferAmount amount of t-space tokens to transfer
    /// @return tFee t-space tokens transfer fee
    function _getTValues(
        uint256 tAmount
    ) private view returns (uint256, uint256) {
        uint256 tFee = 0;
        // calculcate the fee for a non-whitelisted user
        if (!whitelist[msg.sender]) tFee = tAmount.mul(feeAmount).div(PCT_RATE);
        // calcalate the actual transfer amount with fee
        uint256 tTransferAmount = tAmount.sub(tFee);
        return (tTransferAmount, tFee);
    }

    /// @dev returns the amount of r-space tokens that are supposed to be transferred,
    ///      the amount of r-space tokens that would be transferred with fee and the fee itself
    /// @param tAmount the amount of t-space tokens to transfer
    /// @param tFee the transfer fee of t-space tokens
    /// @param currentRate current rate
    /// @return rAmount the amount of r-space tokens that are supposed to be transferred
    /// @return rTransferAmount the amount of r-space tokens that would be transferred with fee 
    /// @return rFee the r-space token transfer fee
    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 currentRate
    ) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee);
        return (rAmount, rTransferAmount, rFee);
    }

    /// @dev returns fee distribution of r-space tokens
    /// @param rFee the amount of r-space tokens to be paid
    ///        as fee for each transaction
    /// @return rToHolders amount of r-space tokens to be distributed among GoldX holders
    /// @return rToTreasury amount of r-space tokens to be transferred to the treasury wallet
    /// @return rToBurn amount of r-space tokens to be burnt
    /// @return rToReferrals amount of r-space tokens to be distributed among referral 
    ///         program members
    function _getFeeDistribution(
        uint256 rFee
    ) private view returns (uint256, uint256, uint256, uint256) {
        uint256 rToHolders = rFee.mul(feeToHolders).div(PCT_RATE);
        uint256 rToTreasury = rFee.mul(feeToTreasury).div(PCT_RATE);
        uint256 rToBurn = rFee.mul(feeToBurn).div(PCT_RATE);
        uint256 rToReferrals = rFee.mul(feeToReferrals).div(PCT_RATE);
        return (rToHolders, rToTreasury, rToBurn, rToReferrals);
    }

    /// @dev returns the current rate (RFI)
    /// @return the current rate of t-space and r-space tokens
    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    /// @dev returns the current supply of r- and t-space tokens
    /// @return rSupply the current supply of r-space tokens
    /// @return tSupply the current supply of t-space tokens
    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _rOwned[_excluded[i]] > rSupply ||
                _tOwned[_excluded[i]] > tSupply
            ) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        rSupply = rSupply.sub(_rReferralReward);
        tSupply = tSupply.sub(_tReferralReward);
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    /// @notice add user to the whitelist
    /// @param account user's address
    function addToWhitelist(
        address account
    ) public whenNotPaused onlyRole(SUPERADMIN_ROLE) {
        whitelist[account] = true;
        emit AddToWhitelist(account);
    }

    /// @notice add user to the blacklist
    /// @param account user's address
    function addToBlacklist(
        address account
    ) public whenNotPaused onlyRole(SUPERADMIN_ROLE) {
        blacklist[account] = true;
        emit AddToBlacklist(account);
    }

    /// @notice remove user from the whitelist
    /// @param account user's address
    function removeFromWhitelist(
        address account
    ) public whenNotPaused onlyRole(SUPERADMIN_ROLE) {
        whitelist[account] = false;
        emit RemoveFromWhitelist(account);
    }

    /// @notice remove user from the blacklist
    /// @param account user's address
    function removeFromBlacklist(
        address account
    ) public whenNotPaused onlyRole(SUPERADMIN_ROLE) {
        blacklist[account] = false;
        emit RemoveFromBlacklist(account);
    }

    /// @notice pause the contract
    function pause() public onlyRole(SUPERADMIN_ROLE) {
        _pause();
    }

    /// @notice unpause the contract
    function unpause() public onlyRole(SUPERADMIN_ROLE) {
        _unpause();
    }

    /// @notice removes user from fees distribution
    /// @param account user's address
    function excludeAccount(address account) public whenNotPaused onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    /// @notice adds user to fees distribution
    /// @param account user's address
    function includeAccount(address account) public whenNotPaused onlyOwner {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                // delete user from excluded preserving array's length
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    /// @notice multi-signature vault can change owner of the token if enough multisigners have voted
    /// @param newOwner new owner of the token contract
    function changeOwner(address newOwner) external whenNotPaused {
        require(
            msg.sender == multiSigVault,
            "GOLDX: ONLY MULTISIGNER VAULT CONTRACT CAN CHANGE THE OWNER"
        );
        address oldOwner = owner();
        _transferOwnership(newOwner);

        _revokeRole(DEFAULT_ADMIN_ROLE, oldOwner);
        _revokeRole(SUPERADMIN_ROLE, oldOwner);
        _grantRole(DEFAULT_ADMIN_ROLE, newOwner);
        _grantRole(SUPERADMIN_ROLE, newOwner);
    }

    /// @notice add a referrer
    /// @param account referrer's address
    function addReferrer(
        address account
    ) public whenNotPaused onlyRole(SUPERADMIN_ROLE) {
        require(!referrers.contains(account), "GOLDX: REFERRER ALREADY EXISTS");
        snapshot[account] = getCompositeReferralReward();
        compositeReferralReward = compositeReferralReward.add(
            getCompositeReferralReward()
        );
        referrers.add(account);
        if (!referrals.contains(account)) uniqueUsersCount++;
    }

    /// @notice add multiple referrers
    /// @param accounts array of referrers
    function addReferrers(
        address[] memory accounts
    ) public whenNotPaused onlyRole(SUPERADMIN_ROLE) {
        for (uint256 i = 0; i < accounts.length; i++) {
            addReferrer(accounts[i]);
        }
    }

    /// @notice binds referrers to a referral address
    /// @param _referrer referrer's address
    function setReferrer(address _referrer) public whenNotPaused {
        require(
            referrers.contains(_referrer),
            "GOLDX: REFERRER DOES NOT EXIST"
        );
        require(
            block.timestamp > timestamp[msg.sender] + cooldown,
            "GOLDX: COOLDOWN IN PROGRESS"
        );

        referrer[msg.sender] = _referrer;
        timestamp[msg.sender] = block.timestamp;
        if (!referrals.contains(msg.sender)) {
            snapshot[msg.sender] = getCompositeReferralReward();
            compositeReferralReward = compositeReferralReward.add(
                getCompositeReferralReward()
            );
            referrals.add(msg.sender);
        }
        if (!referrers.contains(msg.sender)) uniqueUsersCount++;
    }

    /// @notice sets a cooldown after which a referral can change his referrer again
    /// @param _cooldown cooldown in seconds
    function setReferralCooldown(
        uint256 _cooldown
    ) public whenNotPaused onlyOwner {
        cooldown = _cooldown;
    }

    /// @notice returns referrer's addres of the msg.sender
    /// @return the address of the referrer of the caller
    function getMyReferrer() public view returns (address) {
        return referrer[msg.sender];
    }

    /// @notice returns list of referrers
    /// @return the list of referrers
    function getReferrersList() public view returns (address[] memory) {
        return referrers.values();
    }

    /// @notice returns list of referrals
    /// @return the list of referrals
    function getReferralsList() public view returns (address[] memory) {
        return referrals.values();
    }

    /// @notice returns amount of GoldX distributed to referral program
    /// @return the total amount of t-space tokens distributed 
    ///         during the referral program
    function getReferralReward() public view returns (uint256) {
        return _tReferralReward;
    }

    /// @dev returns the composite referral reward per a single user
    /// @return the composite referral rewards per a single user
    function getCompositeReferralReward() private view returns (uint256) {
        uint256 referralProgrammAccounts = uniqueUsersCount;
        if (referralProgrammAccounts == 0) return 0;
        return compositeReferralReward / referralProgrammAccounts;
    }
}
