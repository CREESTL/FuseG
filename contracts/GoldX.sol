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

import "hardhat/console.sol";

contract GOLDX is Context, IGOLDX, Ownable, AccessControl, Pausable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 2_200_000_000 * 1e18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = 'GOLDX';
    string private _symbol = 'GLDX';
    uint8 private _decimals = 18;

    /// ADMIN ROLES
    bytes32 public constant SUPERADMIN_ROLE = keccak256("SUPERADMIN_ROLE");

    /// BLACKLIST & WHITELIST
    mapping (address => bool) public blacklist;
    mapping (address => bool) public whitelist;

    /// FEES
    uint256 private constant PCT_RATE = 100;
    uint256 public feeAmount;
    uint256 private feeToHolders; 
    uint256 private feeToTreasury;
    uint256 private feeToReferrals;
    uint256 private feeToBurn;

    /// FUSE GOLD ADDRESSES
    address private teamWallet;
    address private marketing;
    address public treasury;
    address public rewardVault;
    address public multiSigVault;

    /// REFERRAL PROGRAM
    // referral => referrer
    mapping (address => address) public referrer;
    mapping (address => uint256) private snapshot;
    mapping (address => uint256) private personalReward;
    EnumerableSet.AddressSet referrers;
    EnumerableSet.AddressSet referrals;
    uint256 private totalReferralReward;
    uint256 private _rReferralReward;
    // referral rewards collected
    uint256 public _tReferralReward;
    uint256 private uniqueUsersCount;



    modifier notInBlacklist(address account) {
        require(!blacklist[account], "GOLDX: USER IS BLACKLISTED");
        _;
    }

    constructor (
        address _teamWallet,
        address _marketing,
        address _treasury,
        address _rewardVault,
        address _multiSigVault
    ) {
        require(_teamWallet != address(0), "GOLDX: TEAMWALLET ADDRESS CANNOT BE ZERO");
        require(_marketing != address(0), "GOLDX: MARKETING ADDRESS CANNOT BE ZERO");
        require(_treasury != address(0), "GOLDX: TREASURY ADDRESS CANNOT BE ZERO");
        require(_rewardVault != address(0), "GOLDX: REWARDVAULT ADDRESS CANNOT BE ZERO");
        require(_multiSigVault != address(0), "GOLDX: MULTISIGVAULT ADDRESS CANNOT BE ZERO");

        teamWallet = _teamWallet;
        marketing = _marketing;
        treasury = _treasury;
        rewardVault = _rewardVault;
        multiSigVault = _multiSigVault;
        
        uint256 rate = _rTotal.div(_tTotal);

        _rOwned[_teamWallet] = uint256(5_000_000 * 1e18).mul(rate);
        _rOwned[_marketing] = uint256(5_000_000 * 1e18).mul(rate);
        _rOwned[_rewardVault] = uint256(101_110_100 * 1e18).mul(rate);
        _rOwned[_multiSigVault] = uint256(2_088_889_900 * 1e18).mul(rate);

        emit Transfer(address(0), _teamWallet, 5_000_000);
        emit Transfer(address(0), _marketing, 5_000_000);
        emit Transfer(address(0), _rewardVault, 101_110_100);
        emit Transfer(address(0), _multiSigVault, 2_088_889_900);

        excludeAccount(_rewardVault);
        excludeAccount(_multiSigVault);
        whitelist[_rewardVault] = true;
        whitelist[_multiSigVault] = true;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SUPERADMIN_ROLE, msg.sender);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) 
            return _tOwned[account];
        if (referrers.contains(account) || referrals.contains(account)) {
            uint256 totalReward = getReferralReward() - snapshot[account];
            return tokenFromReflection(_rOwned[account]) + totalReward + personalReward[account];
        }
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override whenNotPaused returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override whenNotPaused returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override whenNotPaused returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual whenNotPaused returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual whenNotPaused returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function setFees(uint256 _feeAmount) public whenNotPaused onlyOwner{
        require(_feeAmount >= 0 && _feeAmount <= 15, "GOLDX: 0% >= TRANSACTION FEE <= 15%");
        feeAmount = _feeAmount;
    }

    function setFeeDistribution(uint256 _toHolders, uint256 _toTreasury, uint256 _toBurn, uint256 _toReferrals) public whenNotPaused onlyOwner{
        require(feeAmount !=0, "GOLDX: TRANSACTION FEE IS ZERO");
        uint256 sum = _toHolders + _toTreasury + _toBurn + _toReferrals;
        require(sum.div(10) == feeAmount, "GOLDX: WRONG DISTRIBUTION, SUM MUST EQUAL FEE");
        feeToHolders = _toHolders;
        feeToTreasury = _toTreasury;
        feeToBurn = _toBurn;
        feeToReferrals = _toReferrals;
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function reflect(uint256 tAmount) public whenNotPaused {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private notInBlacklist(sender) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        if (referrers.contains(sender) || referrals.contains(sender)) {
            uint256 tReward = getReferralReward() - snapshot[sender];
            uint256 rReward = tReward.add(personalReward[sender]).mul(_getRate());
            _rOwned[sender] = _rOwned[sender].add(rReward);
            snapshot[sender] = snapshot[sender].add(tReward);
            personalReward[sender] = 0;
        }

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

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);       
        _reflectAndProcessFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _reflectAndProcessFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _reflectAndProcessFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _reflectAndProcessFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectAndProcessFee(uint256 rFee, uint256 tFee) private {
    /// TODO MAKE BURN AND MINT FUNCTIONS
        (uint256 rToHolders, uint256 rToTreasury, uint256 rToBurn, uint256 rToReferrals) = _getFeeDistribution(rFee);
        uint256 tToBurn = tokenFromReflection(rToBurn);
        uint256 tToTreasury = tokenFromReflection(rToTreasury);
        uint256 tToReferrals = tokenFromReflection(rToReferrals);
        // If user has a referrer, split toReferrals value between them
        if(referrer[msg.sender] != address(0)) {
            personalReward[msg.sender] = personalReward[msg.sender].add(tToReferrals.div(2));
            personalReward[referrer[msg.sender]] = personalReward[referrer[msg.sender]].add(tToReferrals.div(2));
        // else all referrals and referrers ahare equal amount of toReferrals value
        } else {
            totalReferralReward = totalReferralReward.add(tToReferrals);
            _rReferralReward = _rReferralReward.add(rToReferrals);
            _tReferralReward = _tReferralReward.add(tToReferrals);
        }

        _rOwned[treasury] = _rOwned[treasury].add(rToTreasury);
        _tOwned[treasury] = _tOwned[treasury].add(tToTreasury);

        _rTotal = _rTotal.sub(rToHolders).sub(rToBurn);
        _tTotal = _tTotal.sub(tToBurn);
        _tFeeTotal = _tFeeTotal.add(tFee);
        emit Transfer(msg.sender, address(0), tToBurn);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee) = _getTValues(tAmount);
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256) {
        uint256 tFee;
        // Whitelisted users don't pay fees
        if(!whitelist[msg.sender])
            tFee = tAmount.mul(feeAmount).div(PCT_RATE);

        uint256 tTransferAmount = tAmount.sub(tFee);
        return (tTransferAmount, tFee);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getFeeDistribution(uint256 rFee) private view returns (uint256, uint256, uint256, uint256) {
        uint256 rToHolders = rFee.mul(feeToHolders).div(PCT_RATE);
        uint256 rToTreasury = rFee.mul(feeToTreasury).div(PCT_RATE);
        uint256 rToBurn = rFee.mul(feeToBurn).div(PCT_RATE);
        uint256 rToReferrals = rFee.mul(feeToReferrals).div(PCT_RATE);
        return (rToHolders, rToTreasury, rToBurn, rToReferrals);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        rSupply = rSupply.sub(_rReferralReward);
        tSupply = tSupply.sub(_tReferralReward);
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    
    /// ADMIN FUNCTIONS
    function addToWhitelist(address account) public whenNotPaused onlyRole(SUPERADMIN_ROLE){
        whitelist[account] = true;
    }

    function addToBlacklist(address account) public whenNotPaused onlyRole(SUPERADMIN_ROLE){
        blacklist[account] = true;
    }

    function removeFromWhitelist(address account) public whenNotPaused onlyRole(SUPERADMIN_ROLE){
        whitelist[account] = false;
    }

    function removeFromBlacklist(address account) public whenNotPaused onlyRole(SUPERADMIN_ROLE){
        blacklist[account] = false;
    }

    function pause() public onlyRole(SUPERADMIN_ROLE){
        _pause();
    }

    function unpause() public onlyRole(SUPERADMIN_ROLE){
        _unpause();
    }

    function excludeAccount(address account) public whenNotPaused onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeAccount(address account) public whenNotPaused onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function changeOwner(address newOwner) external whenNotPaused {
        require(msg.sender == multiSigVault, "GOLDX: ONLY MULTISIGNER VAULT CONTRACT CAN CHANGE THE OWNER");
        address oldOwner = owner();
        _transferOwnership(newOwner);

        _revokeRole(DEFAULT_ADMIN_ROLE, oldOwner);
        _revokeRole(SUPERADMIN_ROLE, oldOwner);
        _grantRole(DEFAULT_ADMIN_ROLE, newOwner);
        _grantRole(SUPERADMIN_ROLE, newOwner);
    }

    /// REFERRAL PROGRAMM FUNCTIONS
    function addReferrer(address account) public whenNotPaused onlyRole(SUPERADMIN_ROLE) {
        require(!referrers.contains(account), "GOLDX: REFERRER ALREADY EXISTS");
        snapshot[account] = getReferralReward();
        totalReferralReward = totalReferralReward.add(getReferralReward());
        referrers.add(account);
        uniqueUsersCount ++;
    }

    function addReferrers(address[] memory accounts) public whenNotPaused onlyRole(SUPERADMIN_ROLE) {
        for(uint256 i = 0; i < accounts.length; i++) {
            addReferrer(accounts[i]);
        }
    }

    function setReferrer(address _referrer) public whenNotPaused {
        require(referrers.contains(_referrer), "GOLDX: REFERRER DOES NOT EXIST");
        referrer[msg.sender] = _referrer;
        if(!referrals.contains(msg.sender)) {
            snapshot[msg.sender] = getReferralReward();
            totalReferralReward = totalReferralReward.add(getReferralReward());
            referrals.add(msg.sender);
        }
        if(msg.sender != _referrer)
            uniqueUsersCount ++;
    }

    function getMyReferrer() public view returns(address) {
        return referrer[msg.sender];
    }

    function getReferrersList() public view returns(address[] memory) {
        return referrers.values();
    }

    function getReferralsList() public view returns(address[] memory) {
        return referrals.values();
    }

    function getReferralReward() private view returns(uint256) {
        uint256 referralProgrammAccounts = uniqueUsersCount;
        if (referralProgrammAccounts == 0)
            return 0;
        return totalReferralReward / referralProgrammAccounts;
    }
}
