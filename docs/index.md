# Solidity API

## GOLDX

### _rOwned

```solidity
mapping(address => uint256) _rOwned
```

_NOTE: this contract uses the principals of RFI tokens
           for detailed documentation please see:
           https://reflect-contract-doc.netlify.app/#a-technical-whitepaper-for-reflect-contracts_

### _tOwned

```solidity
mapping(address => uint256) _tOwned
```

### _allowances

```solidity
mapping(address => mapping(address => uint256)) _allowances
```

_allowances of users_

### _isExcluded

```solidity
mapping(address => bool) _isExcluded
```

_addresses that are excluded from token distribution_

### _excluded

```solidity
address[] _excluded
```

### MAX

```solidity
uint256 MAX
```

_the maximum possible amount of token both from t-space and r-space_

### _tTotal

```solidity
uint256 _tTotal
```

_the maximum possible amount of tokens from t-space_

### _rTotal

```solidity
uint256 _rTotal
```

_the maximum possible amount of tokens from r-space_

### _tFeeTotal

```solidity
uint256 _tFeeTotal
```

_the total amount of fees paid for transfers in t-space_

### _name

```solidity
string _name
```

_credentials of the token_

### _symbol

```solidity
string _symbol
```

### _decimals

```solidity
uint8 _decimals
```

### SUPERADMIN_ROLE

```solidity
bytes32 SUPERADMIN_ROLE
```

_this role gives a right for many admin-only functions_

### blacklist

```solidity
mapping(address => bool) blacklist
```

the list of users who can not transfer GoldX tokens

### whitelist

```solidity
mapping(address => bool) whitelist
```

the list of users who do not pay fees for GoldX transfers

### PCT_RATE

```solidity
uint256 PCT_RATE
```

### feeAmount

```solidity
uint256 feeAmount
```

the amount of GoldX tokens paid as fee for each transaction

### feeToHolders

```solidity
uint256 feeToHolders
```

the part of `feeAmount` that should be transferred to GoldX holders

### feeToTreasury

```solidity
uint256 feeToTreasury
```

the part of `feeAmount` that should be transferred to treasury wallet

### feeToReferrals

```solidity
uint256 feeToReferrals
```

the part of `feeAmount` that should be transferred to participants of referral program

### feeToBurn

```solidity
uint256 feeToBurn
```

the part of `feeAmount` that should be burnt

### teamWallet

```solidity
address teamWallet
```

_the address team's wallet_

### marketing

```solidity
address marketing
```

_the address wallet used for marketing_

### treasury

```solidity
address treasury
```

the address of the treasury wallet

### rewardVault

```solidity
address rewardVault
```

the address of the reward vault contract

### multiSigVault

```solidity
address multiSigVault
```

the address of the multisig vault contract

### referrer

```solidity
mapping(address => address) referrer
```

returns referrer's address for a given referral

### snapshot

```solidity
mapping(address => uint256) snapshot
```

_holds "snapshot" of the current state of users account_

### personalReward

```solidity
mapping(address => uint256) personalReward
```

_the rewards of each participant of referral program_

### referrers

```solidity
struct EnumerableSet.AddressSet referrers
```

### referrals

```solidity
struct EnumerableSet.AddressSet referrals
```

### compositeReferralReward

```solidity
uint256 compositeReferralReward
```

_total reward for unique members of referral program_

### _tReferralReward

```solidity
uint256 _tReferralReward
```

_total referral reward collected (in t-space)_

### _rReferralReward

```solidity
uint256 _rReferralReward
```

_total referral reward collected (in r-space)_

### uniqueUsersCount

```solidity
uint256 uniqueUsersCount
```

_total number of unique members of referral program_

### cooldown

```solidity
uint256 cooldown
```

time that should pass for referer to change his referee

### timestamp

```solidity
mapping(address => uint256) timestamp
```

_keeps track of moments when users were added to
     the referral program_

### notInBlacklist

```solidity
modifier notInBlacklist(address account)
```

checks if user is in the blacklist

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | user's address |

### constructor

```solidity
constructor(address _teamWallet, address _marketing, address _treasury, address _rewardVault, address _multiSigVault) public
```

constructor with FuseG platform addresses

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _teamWallet | address | team wallet address |
| _marketing | address | marketing wallet address |
| _treasury | address | treasury address |
| _rewardVault | address | reward vault address |
| _multiSigVault | address | multi-signature vault address |

### name

```solidity
function name() public view returns (string)
```

returns the name of the token

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | string | the name of the token |

### symbol

```solidity
function symbol() public view returns (string)
```

returns the symbol of the token

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | string | the symbol of the token |

### decimals

```solidity
function decimals() public view returns (uint8)
```

returns the decimals amount of the token

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint8 | the decimals amount of the token |

### totalSupply

```solidity
function totalSupply() public view returns (uint256)
```

returns the totalSupply amount of the token

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | the total supply of the token |

### balanceOf

```solidity
function balanceOf(address account) public view returns (uint256)
```

returns the balance of the user

_this is where user's balance is calculated using the amount of token 
     from r-space. The less tokens in r-space there are, the higher the 
     user's balance is. Main feature of RFI.
balance is in t-space_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | user's address |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | the balance of the user |

### transfer

```solidity
function transfer(address recipient, uint256 amount) public returns (bool)
```

transfers tokens to a given address

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| recipient | address | recipient's address |
| amount | uint256 | amount of tokens to send |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | boolean value indicating whether the operation succeeded. |

### allowance

```solidity
function allowance(address owner, address spender) public view returns (uint256)
```

returns the amount of tokens that spender is allowed to spend on behalf of owner

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| owner | address | owner of the tokens |
| spender | address | spender's address |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | the amount of tokens that spender is allowed to spend of behalf of owner |

### approve

```solidity
function approve(address spender, uint256 amount) public returns (bool)
```

allows spender to spend tokens on behalf of the transaction sender via transferFrom

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| spender | address | spender's address |
| amount | uint256 | amount of tokens that spender is allowed to spent |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | boolean value indicating whether the operation succeeded. |

### transferFrom

```solidity
function transferFrom(address sender, address recipient, uint256 amount) public returns (bool)
```

transfers tokens to a given address on behalf of the owner

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sender | address | sender's address |
| recipient | address | recipient's address |
| amount | uint256 | amount of tokens |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | boolean value indicating whether the operation succeeded. |

### increaseAllowance

```solidity
function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool)
```

increases amount of tokens to spend on behalf of an owner

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| spender | address | sender's address |
| addedValue | uint256 | amount of tokens |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | boolean value indicating whether the operation succeeded. |

### decreaseAllowance

```solidity
function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool)
```

decreases amount of tokens to spend on behalf of an owner

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| spender | address | sender's address |
| subtractedValue | uint256 | amount of tokens |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | boolean value indicating whether the operation succeeded. |

### isExcluded

```solidity
function isExcluded(address account) public view returns (bool)
```

checks if user is excluded from fees distribution

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | user's address |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | boolean value indicating wether account is excluded from fees distribution |

### setFees

```solidity
function setFees(uint256 _feeAmount) public
```

sets transaction fees amount

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _feeAmount | uint256 | transaction fee amount |

### setFeeDistribution

```solidity
function setFeeDistribution(uint256 _toHolders, uint256 _toTreasury, uint256 _toBurn, uint256 _toReferrals) public
```

sets fee distribution

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _toHolders | uint256 | fee share to token holders |
| _toTreasury | uint256 | fee share to treasury |
| _toBurn | uint256 | fee share to burn |
| _toReferrals | uint256 | fee share to referrals |

### getFeeDistribution

```solidity
function getFeeDistribution() public view returns (uint256, uint256, uint256, uint256)
```

returns fee distribution

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | feeToHolders holders share |
| [1] | uint256 | feeToTreasury treasury share |
| [2] | uint256 | feeToBurn burn wallet share |
| [3] | uint256 | feeToReferrals referrals share |

### totalFees

```solidity
function totalFees() public view returns (uint256)
```

returns amount of collected fees

_the amount of collected fees is in t-space_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | the amount of collected fees |

### reflect

```solidity
function reflect(uint256 tAmount) public
```

reflects/distributes tAmount between non-excluded holders

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tAmount | uint256 | amount of tokens to distribute |

### reflectionFromToken

```solidity
function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns (uint256)
```

transforms token amount from t-space to r-space

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tAmount | uint256 | amount of tokens in r-space |
| deductTransferFee | bool | true if fee should be deducted |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | the amount of r-space tokens equal to t-space amount |

### tokenFromReflection

```solidity
function tokenFromReflection(uint256 rAmount) public view returns (uint256)
```

transforms token amount from r-space to t-space

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| rAmount | uint256 | token amount in r-space |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | the amount of t-space tokens equal to r-space amount |

### _approve

```solidity
function _approve(address owner, address spender, uint256 amount) private
```

_sets the new allowance for the spender_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| owner | address | the owner of tokens |
| spender | address | the one spending owner's tokens |
| amount | uint256 | the amount of tokens spender is allowed to spend |

### _transfer

```solidity
function _transfer(address sender, address recipient, uint256 amount) private
```

_transfers t-space tokens from one user to another_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sender | address | the user owning tokens |
| recipient | address | the user receiving tokens of the owner |
| amount | uint256 | the amount of t-space tokens to transfer from sender to recipient |

### _transferStandard

```solidity
function _transferStandard(address sender, address recipient, uint256 tAmount) private
```

_transfers tokens from the sender who is not excluded from fees distribution
     to the recipient who is not excluded from the distribution_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sender | address | the owner of the tokens |
| recipient | address | the user who receives sender's tokens |
| tAmount | uint256 | the amount of t-space tokens to be transferred |

### _transferToExcluded

```solidity
function _transferToExcluded(address sender, address recipient, uint256 tAmount) private
```

_transfers tokens from the sender who is not excluded from fees distribution
     to the recipient who is excluded from the distribution_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sender | address | the owner of the tokens |
| recipient | address | the user who receives sender's tokens |
| tAmount | uint256 | the amount of t-space tokens to be transferred |

### _transferFromExcluded

```solidity
function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private
```

_transfers tokens from the sender who is excluded from fees distribution
     to the recipient who is not excluded_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sender | address | the owner of the tokens |
| recipient | address | the user who receives sender's tokens |
| tAmount | uint256 | the amount of t-space tokens to be transferred |

### _transferBothExcluded

```solidity
function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private
```

_transfers tokens from the sender who is excluded from fees distribution
     to the recipient who is excluded from the distribution as well_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sender | address | the owner of the tokens |
| recipient | address | the user who receives sender's tokens |
| tAmount | uint256 | the amount of t-space tokens to be transferred |

### _reflectAndProcessFee

```solidity
function _reflectAndProcessFee(uint256 rFee, uint256 tFee) private
```

_distributes fees among of destinations_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| rFee | uint256 | the amount of r-space tokens paid as fees |
| tFee | uint256 | the amount of t-space tokens paid as fees |

### _getValues

```solidity
function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256)
```

_returns r- and t-space amount of tokens necessary for future calculations_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tAmount | uint256 | the amount of t-space tokens that are supposed to be transferred |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | rAmount the amount of r-space tokens that are supposed to be transferred |
| [1] | uint256 | rTransferAmount the amount of r-space tokens that would be transferred |
| [2] | uint256 | rFee the amount of r-space tokens that would be paid and distributed as fees |
| [3] | uint256 | tTransferAmount the amount of t-space tokens that are supposed to be transferred |
| [4] | uint256 | tFee the amount of t-space tokens that would be transferred |

### _getTValues

```solidity
function _getTValues(uint256 tAmount) private view returns (uint256, uint256)
```

_returns the amount of t-space tokens to transfer and 
     t-space tokens transfer fee_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tAmount | uint256 | the amount of t-space token to transfer |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | tTransferAmount amount of t-space tokens to transfer |
| [1] | uint256 | tFee t-space tokens transfer fee |

### _getRValues

```solidity
function _getRValues(uint256 tAmount, uint256 tFee, uint256 currentRate) private pure returns (uint256, uint256, uint256)
```

_returns the amount of r-space tokens that are supposed to be transferred,
     the amount of r-space tokens that would be transferred with fee and the fee itself_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tAmount | uint256 | the amount of t-space tokens to transfer |
| tFee | uint256 | the transfer fee of t-space tokens |
| currentRate | uint256 | current rate |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | rAmount the amount of r-space tokens that are supposed to be transferred |
| [1] | uint256 | rTransferAmount the amount of r-space tokens that would be transferred with fee |
| [2] | uint256 | rFee the r-space token transfer fee |

### _getFeeDistribution

```solidity
function _getFeeDistribution(uint256 rFee) private view returns (uint256, uint256, uint256, uint256)
```

_returns fee distribution of r-space tokens_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| rFee | uint256 | the amount of r-space tokens to be paid        as fee for each transaction |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | rToHolders amount of r-space tokens to be distributed among GoldX holders |
| [1] | uint256 | rToTreasury amount of r-space tokens to be transferred to the treasury wallet |
| [2] | uint256 | rToBurn amount of r-space tokens to be burnt |
| [3] | uint256 | rToReferrals amount of r-space tokens to be distributed among referral          program members |

### _getRate

```solidity
function _getRate() private view returns (uint256)
```

_returns the current rate (RFI)_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | the current rate of t-space and r-space tokens |

### _getCurrentSupply

```solidity
function _getCurrentSupply() private view returns (uint256, uint256)
```

_returns the current supply of r- and t-space tokens_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | rSupply the current supply of r-space tokens |
| [1] | uint256 | tSupply the current supply of t-space tokens |

### addToWhitelist

```solidity
function addToWhitelist(address account) public
```

add user to the whitelist

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | user's address |

### addToBlacklist

```solidity
function addToBlacklist(address account) public
```

add user to the blacklist

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | user's address |

### removeFromWhitelist

```solidity
function removeFromWhitelist(address account) public
```

remove user from the whitelist

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | user's address |

### removeFromBlacklist

```solidity
function removeFromBlacklist(address account) public
```

remove user from the blacklist

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | user's address |

### pause

```solidity
function pause() public
```

pause the contract

### unpause

```solidity
function unpause() public
```

unpause the contract

### excludeAccount

```solidity
function excludeAccount(address account) public
```

removes user from fees distribution

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | user's address |

### includeAccount

```solidity
function includeAccount(address account) public
```

adds user to fees distribution

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | user's address |

### changeOwner

```solidity
function changeOwner(address newOwner) external
```

multi-signature vault can change owner of the token if enough multisigners have voted

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| newOwner | address | new owner of the token contract |

### addReferrer

```solidity
function addReferrer(address account) public
```

add a referrer

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | referrer's address |

### addReferrers

```solidity
function addReferrers(address[] accounts) public
```

add multiple referrers

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| accounts | address[] | array of referrers |

### setReferrer

```solidity
function setReferrer(address _referrer) public
```

binds referrers to a referral address

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _referrer | address | referrer's address |

### setReferralCooldown

```solidity
function setReferralCooldown(uint256 _cooldown) public
```

sets a cooldown after which a referral can change his referrer again

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _cooldown | uint256 | cooldown in seconds |

### getMyReferrer

```solidity
function getMyReferrer() public view returns (address)
```

returns referrer's addres of the msg.sender

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | the address of the referrer of the caller |

### getReferrersList

```solidity
function getReferrersList() public view returns (address[])
```

returns list of referrers

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address[] | the list of referrers |

### getReferralsList

```solidity
function getReferralsList() public view returns (address[])
```

returns list of referrals

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address[] | the list of referrals |

### getReferralReward

```solidity
function getReferralReward() public view returns (uint256)
```

returns amount of GoldX distributed to referral program

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | the total amount of t-space tokens distributed          during the referral program |

### getCompositeReferralReward

```solidity
function getCompositeReferralReward() private view returns (uint256)
```

_returns the composite referral reward per a single user_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | the composite referral rewards per a single user |

## MultiSigVault

### goldX

```solidity
contract IGOLDX goldX
```

### rewardVault

```solidity
contract IRewardVault rewardVault
```

### signers

```solidity
struct EnumerableSet.AddressSet signers
```

### isConfirmed

```solidity
mapping(uint256 => mapping(address => bool)) isConfirmed
```

### proposals

```solidity
struct IMultiSigVault.Proposal[] proposals
```

### onlySigner

```solidity
modifier onlySigner()
```

allows only multi-signers to call the function

### proposalExists

```solidity
modifier proposalExists(uint256 _proposalIndex)
```

checks if proposal exists inside proposals array

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _proposalIndex | uint256 | proposal index inside proposals array |

### notExecuted

```solidity
modifier notExecuted(uint256 _proposalIndex)
```

checks if proposal has been executed

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _proposalIndex | uint256 | proposal index inside proposals array |

### notConfirmed

```solidity
modifier notConfirmed(uint256 _proposalIndex)
```

checks if proposal has been confirmed

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _proposalIndex | uint256 | proposal index inside proposals array |

### constructor

```solidity
constructor(address[] _signers) public
```

constructor with initial signers

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _signers | address[] | array of signer addresses |

### initialize

```solidity
function initialize(address _goldX, address _rewardVault) public
```

initializes fuseG platform addresses

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _goldX | address | GoldX token address |
| _rewardVault | address | reward vault address |

### setNewRound

```solidity
function setNewRound(uint256 _phaseSupply, uint8 _phaseCount, uint256[] _coeffs) public
```

Sets new round

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _phaseSupply | uint256 | GoldX amount in one phase |
| _phaseCount | uint8 | amount of phases |
| _coeffs | uint256[] | FuseG : GoldX coefficient for each phase |

### addMultiSigner

```solidity
function addMultiSigner(address _newSigner) public
```

allows the owner to manually add a multi-signer

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _newSigner | address | new multi-signer address |

### removeMultiSigner

```solidity
function removeMultiSigner(address _signer) public
```

allows the owner to manually remove a multi-signer

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _signer | address | address of the multi-signer to remove |

### submitProposal

```solidity
function submitProposal(enum IMultiSigVault.Proposals _proposalType, address _to, uint256 _amount) public
```

submits the proposal

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _proposalType | enum IMultiSigVault.Proposals | see Proposals enum |
| _to | address | subject of the proposal |
| _amount | uint256 | GoldX amount to send if tx type proposal |

### confirmProposal

```solidity
function confirmProposal(uint256 _proposalIndex) public
```

allows a multi-signer to confirm a proposal

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _proposalIndex | uint256 | index of the proposal inside proposals array |

### executeProposal

```solidity
function executeProposal(uint256 _proposalIndex) public
```

executes the proposal if it has enough votes

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _proposalIndex | uint256 | index of the proposal inside proposals array |

### revokeConfirmation

```solidity
function revokeConfirmation(uint256 _proposalIndex) public
```

revokes one singer's confirmation of the proposal

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _proposalIndex | uint256 | index of the proposal inside proposals array |

### getSigners

```solidity
function getSigners() public view returns (address[])
```

returns the list of all signers

### getProposalCount

```solidity
function getProposalCount() public view returns (uint256)
```

returns amount of all proposals

### getProposal

```solidity
function getProposal(uint256 _proposalIndex) public view returns (enum IMultiSigVault.Proposals proposalType, address to, uint256 amount, bool executed, uint256 numConfirmations)
```

returns info on specific proposal

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _proposalIndex | uint256 | index of the proposal inside proposals array |

### getRewardVault

```solidity
function getRewardVault() public view returns (address)
```

returns reward vault address

### getGoldX

```solidity
function getGoldX() public view returns (address)
```

returns GOLDX address

### _changeOwner

```solidity
function _changeOwner(address newOwner) private
```

changes this contract's owner

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| newOwner | address | new owner of the token contract |

## RewardVault

### goldX

```solidity
contract IGOLDX goldX
```

### multiSigVault

```solidity
address multiSigVault
```

### fuseG

```solidity
address fuseG
```

### roundSupply

```solidity
uint256 roundSupply
```

### phaseSupply

```solidity
uint256 phaseSupply
```

### phaseCount

```solidity
uint8 phaseCount
```

### vaultDepleted

```solidity
bool vaultDepleted
```

### minedAmount

```solidity
uint256 minedAmount
```

### coeffTable

```solidity
mapping(uint8 => uint256) coeffTable
```

### currentRound

```solidity
uint256 currentRound
```

### PRECISION

```solidity
uint256 PRECISION
```

### SUPPLY_ROLE

```solidity
bytes32 SUPPLY_ROLE
```

### initialize

```solidity
function initialize(address _fuseG, address _goldX, address _multiSigVault) public
```

initializes fuseG platform addresses

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _fuseG | address | FuseG token address |
| _goldX | address | GoldX token address |
| _multiSigVault | address | multi-signature vault address |

### setNewRound

```solidity
function setNewRound(uint256 _phaseSupply, uint8 _phaseCount, uint256[] _coeffs) external
```

sets new round

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _phaseSupply | uint256 | GoldX amount in one phase |
| _phaseCount | uint8 | amount of phases |
| _coeffs | uint256[] | FuseG : GoldX coefficient for each phase |

### mineGoldX

```solidity
function mineGoldX(address sender, uint256 fuseGAmount) external
```

called by FuseG token, mines GoldX to FuseG holders

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sender | address | user who initiated FuseG transaction |
| fuseGAmount | uint256 | amount of FuseG tokens in transaction |

### calcAmountToMine

```solidity
function calcAmountToMine(uint8 phase, uint256 remainingPhaseSupply, uint256 fuseGAmount) internal view returns (uint256)
```

calculates amount of GoldX to distribute to user based on coeffs and phase

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| phase | uint8 | current phase |
| remainingPhaseSupply | uint256 | the rest of GoldX to be mined in the phase |
| fuseGAmount | uint256 | amount of FuseG tokens in transaction |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | GoldX amount to mine |

### getMiningPhase

```solidity
function getMiningPhase() public view returns (uint8 phase, uint256 remainingPhaseSupply)
```

getter for mining phase

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| phase | uint8 | current mining phase |
| remainingPhaseSupply | uint256 | the rest of GoldX to be mined in the phase |

### getGoldX

```solidity
function getGoldX() public view returns (address)
```

returns GOLDX address

### changeOwner

```solidity
function changeOwner(address newOwner) external
```

multi-signature vault can change owner of the reward vault if enough multisigners have voted

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| newOwner | address | new owner of the token contract |

## IGOLDX

_Interface of the ERC20 standard as defined in the EIP._

### Transfer

```solidity
event Transfer(address from, address to, uint256 value)
```

_Emitted when `value` tokens are moved from one account (`from`) to
another (`to`).

Note that `value` may be zero._

### Distribute

```solidity
event Distribute(address from, uint256 amount)
```

_Emitted when `amount` tokens are destributed as fees to GoldX holders_

### Approval

```solidity
event Approval(address owner, address spender, uint256 value)
```

_Emitted when the allowance of a `spender` for an `owner` is set by
a call to {approve}. `value` is the new allowance._

### SetFees

```solidity
event SetFees(uint256 newFeeAmount)
```

_Emitted when owner calls {setFees} function with 'newFeeAmount' value_

### AddToWhitelist

```solidity
event AddToWhitelist(address account)
```

_Emitted when owner or superadmin adds a new user to the whitelist_

### RemoveFromWhitelist

```solidity
event RemoveFromWhitelist(address account)
```

_Emitted when owner or superadmin removes a user from the whitelist_

### AddToBlacklist

```solidity
event AddToBlacklist(address account)
```

_Emitted when owner or superadmin adds a new user to the blacklist_

### RemoveFromBlacklist

```solidity
event RemoveFromBlacklist(address account)
```

_Emitted when owner or superadmin removes a user from the blacklist_

### totalSupply

```solidity
function totalSupply() external view returns (uint256)
```

_Returns the amount of tokens in existence._

### balanceOf

```solidity
function balanceOf(address account) external view returns (uint256)
```

_Returns the amount of tokens owned by `account`._

### transfer

```solidity
function transfer(address to, uint256 amount) external returns (bool)
```

_Moves `amount` tokens from the caller's account to `to`.

Returns a boolean value indicating whether the operation succeeded.

Emits a {Transfer} event._

### allowance

```solidity
function allowance(address owner, address spender) external view returns (uint256)
```

_Returns the remaining number of tokens that `spender` will be
allowed to spend on behalf of `owner` through {transferFrom}. This is
zero by default.

This value changes when {approve} or {transferFrom} are called._

### approve

```solidity
function approve(address spender, uint256 amount) external returns (bool)
```

_Sets `amount` as the allowance of `spender` over the caller's tokens.

Returns a boolean value indicating whether the operation succeeded.

IMPORTANT: Beware that changing an allowance with this method brings the risk
that someone may use both the old and the new allowance by unfortunate
transaction ordering. One possible solution to mitigate this race
condition is to first reduce the spender's allowance to 0 and set the
desired value afterwards:
https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729

Emits an {Approval} event._

### transferFrom

```solidity
function transferFrom(address from, address to, uint256 amount) external returns (bool)
```

_Moves `amount` tokens from `from` to `to` using the
allowance mechanism. `amount` is then deducted from the caller's
allowance.

Returns a boolean value indicating whether the operation succeeded.

Emits a {Transfer} event._

### changeOwner

```solidity
function changeOwner(address newOwner) external
```

_Changes token's owner, can be only called by multi-signer vault contract

Emits a {OwnershipTransferred} event._

## IMultiSigVault

### Proposals

```solidity
enum Proposals {
  Transaction,
  AddSigner,
  RemoveSigner,
  ChangeOwner
}
```

### Proposal

```solidity
struct Proposal {
  enum IMultiSigVault.Proposals proposalType;
  address to;
  uint256 amount;
  bool executed;
  uint256 numConfirmations;
}
```

### SubmitProposal

```solidity
event SubmitProposal(address signer, enum IMultiSigVault.Proposals proposalType, uint256 proposalIndex, address to, uint256 amount)
```

event indicating that new proposal was created

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| signer | address | proposal initiator |
| proposalType | enum IMultiSigVault.Proposals | see Proposals enum |
| proposalIndex | uint256 | index of the proposal inside proposals array |
| to | address | subject of the proposal |
| amount | uint256 | GoldX amount to send if tx type proposal |

### ConfirmProposal

```solidity
event ConfirmProposal(address signer, uint256 proposalIndex)
```

event indicating confirmation of the proposal by a signer

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| signer | address | signer who confirmed the proposal |
| proposalIndex | uint256 | index of the proposal inside proposals array |

### RevokeConfirmation

```solidity
event RevokeConfirmation(address signer, uint256 proposalIndex)
```

event indicating that confirmation was cancelled by a signer

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| signer | address | signer who cancelled his confirmation |
| proposalIndex | uint256 | index of the proposal inside proposals array |

### ExecuteProposal

```solidity
event ExecuteProposal(address signer, uint256 proposalIndex)
```

event indicating that proposal was executed by majority of votes

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| signer | address | signer who executed the proposal |
| proposalIndex | uint256 | index of the proposal inside proposals array |

## IRewardVault

### NewRound

```solidity
event NewRound(uint256 roundSupply, uint256 phaseSupply, uint8 phaseCount)
```

event indicating set of the new round

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| roundSupply | uint256 | GoldX amount in one round |
| phaseSupply | uint256 | GoldX amount in one phase |
| phaseCount | uint8 | amount of phases |

### Mine

```solidity
event Mine(address miner, uint256 goldXAmount)
```

indicates GoldX mining via FuseG transfer

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| miner | address | GoldX receiver |
| goldXAmount | uint256 | GoldX amount |

### RewardVaultDepleted

```solidity
event RewardVaultDepleted()
```

indicates that reward vault is out of GoldX, all phases are finished

### mineGoldX

```solidity
function mineGoldX(address sender, uint256 fuseGAmount) external
```

### setNewRound

```solidity
function setNewRound(uint256 _phaseSupply, uint8 _phaseCount, uint256[] _coeffs) external
```

### changeOwner

```solidity
function changeOwner(address newOwner) external
```

