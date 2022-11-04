# *FUSE GOLD CONTRACTS*
[GoldX.sol](#goldxsol)

- [ERC20 Functions](#erc20-functions)
- [Fees](#fees)
- [Admin Functions](#admin-functions)
- [Referral Program Functions](#referral-program-functions)

[MultiSigvault.sol](#multisigvaultsol)\
[RewardVault.sol](#rewardvaultsol)\
[IGoldX.sol](#igoldxsol)\
[IMultiSigVault.sol](#imultisigvaultsol)\
[IRewardVault.sol](#irewardvaultsol)
# GoldX.sol
## ERC20 Functions
### marketing

```solidity
address marketing
```
Marketing wallet address

### treasury

```solidity
address treasury
```
Treasury wallet address

### rewardVault

```solidity
address rewardVault
```

Reward vault Address

### multiSigVault

```solidity
address multiSigVault
```
Multi-signature vault address

### constructor

```solidity
constructor(address _teamWallet, address _marketing, address _treasury, address _rewardVault, address _multiSigVault) public
```

In the constructor we set FuseG platform addresses, and premint 2.2B GoldX tokens:

- 5,000,000 GoldX to the Team Wallet
- 5,000,000 GoldX to the Marketing Wallet
- 101,110,100 GoldX to the Reward Vault
- 2,088,889,900 to the Multi-signature Vault

Reward Vault and Multi-signature Vault are put in the whitelist so they don't pay transaction fees and are excluded from rewards (part of the transaction fee that is distributed to token holders).
Msg.sender becomes an owner of the token and also is granted superadmin rights.

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

Returns name of the token

### symbol

```solidity
function symbol() public view returns (string)
```

Returns symbol of the token

### decimals

```solidity
function decimals() public view returns (uint8)
```

Returns decimals amount of the token - 18

### totalSupply

```solidity
function totalSupply() public view returns (uint256)
```

Returns totalSupply amount of the token

### balanceOf

```solidity
function balanceOf(address account) public view returns (uint256)
```

Returns user's balance

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | user's address |

### transfer

```solidity
function transfer(address recipient, uint256 amount) public returns (bool)
```

Transfers tokens to a given address

> Cannot transfer to a zero address

> Cannot transfer from a zero address

> Amount must be > 0

> Transaction cannot be initiated if the sender is in the blacklist

> Cannot be called if the contract is paused

If the sender is in the whitelist he doesn't pay transaction fees, otherwise transaction fees are deducted from {amount} and distributed accordingly to the fee distribution plan.

 For example
 
 - fee amount - 10%
 - holders share - 7%
 - treasury share - 1%
 - burn share - 1%
 - referral program share - 1%
 
 Alice sends Bob 100 GoldX tokens, 10 GoldX deducted as a transaction fee, of this fee 7 GoldX are shared between all holders of GoldX who haven't been excluded from the reflection, 1 GoldX goes to treasury, 1Goldx is burned and 1 GoldX are equally shared between referral program participants. Bob receives 90 GoldX.
 If Alice is the referral of Charlie who is referrer in this case, they split 1 GoldX between themselves.

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

Returns the amount of tokens that spender allowed to spend on behalf of the owner

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| owner | address | owner of the tokens |
| spender | address | spender's address |

### approve

```solidity
function approve(address spender, uint256 amount) public returns (bool)
```
> Cannot be called if the contract is paused
> 
Allows spender to spend tokens on behalf of the transaction sender via transferFrom

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
> Cannot transfer to a zero address

> Cannot transfer from a zero address

> Amount must be > 0

> Transaction cannot be initiated if the sender is in the blacklist

> Cannot be called if the contract is paused

> The caller must have allowance for {sender}'s tokens of at least {amount}

Transfers tokens to a given address on behalf of the owner. See transfer function.

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

> Cannot be called if the contract is paused

Increase amount of tokens to spend on behalf of an owner

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
> Cannot be called if the contract is paused

Decrease amount of tokens to spend on behalf of an owner

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

Checks if user is excluded from fees reflection (toHolders %)

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | user's address |

### reflect

```solidity
function reflect(uint256 tAmount) public
```
> Cannot be called if the contract is paused
> 
Reflects/distributes tAmount between non-excluded holders. GoldX is based on RFI token which distributes a share of transaction fees through so called reflections, each holder gains his share based on the amount of GoldX tokens on his balance. The more tokens you have, the bigger share you receive.
Please consult this document https://reflect-contract-doc.netlify.app/ on the basics of reflections and operations with r-space and t-space. 

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tAmount | uint256 | amount of tokens to distribute |

### reflectionFromToken

```solidity
function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns (uint256)
```

Transforms token amount from t-space to r-space

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tAmount | uint256 | amount of tokens in r-space |
| deductTransferFee | bool | true if fee should be deducted |

### tokenFromReflection

```solidity
function tokenFromReflection(uint256 rAmount) public view returns (uint256)
```

Transforms token amount from r-space to t-space

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| rAmount | uint256 | token amount in r-space |

## Fees
### feeAmount

```solidity
uint256 feeAmount
```

Transaction fee (%)

### setFees

```solidity
function setFees(uint256 _feeAmount) public
```
> Cannot be called if the contract is paused

> Only owner can call 

> must be 0 >= {_feeAmount} <= 15  

Set transaction fees amount, {_feeAmount} value is in %

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _feeAmount | uint256 | transaction fee amount %|

### setFeeDistribution

```solidity
function setFeeDistribution(uint256 _toHolders, uint256 _toTreasury, uint256 _toBurn, uint256 _toReferrals) public
```
> Cannot be called if the contract is paused

> Only owner can call 

> {_toHolders} + {_toTreasury} + {_toBurn} + {_toReferrals} must be equal 100%

Set fee distribution. Determines what percentage of transaction fee shared by holders, treasury, burned and goes to referrals. Example setFeeDistribution(70,10,10,10).

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _toHolders | uint256 | fee share to token holders %|
| _toTreasury | uint256 | fee share to treasury %|
| _toBurn | uint256 | fee share to burn %|
| _toReferrals | uint256 | fee share to referrals %|

### totalFees

```solidity
function totalFees() public view returns (uint256)
```

Returns total amount of fees paid by users.

## Admin Functions

### SUPERADMIN_ROLE

```solidity
bytes32 SUPERADMIN_ROLE
```

Encoded SUPERADMIN_ROLE string, use it with the access control functions (e.g. grantRole, revokeRole, hasRole)

### blacklist

```solidity
mapping(address => bool) blacklist
```

Blacklist mapping, returns {true} if user's address is in the blacklist, {false} otherwise.

### whitelist

```solidity
mapping(address => bool) whitelist
```
### notInBlacklist

```solidity
modifier notInBlacklist(address account)
```

Checks if user is in the blacklist

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | user's address |

Whitelist mapping, returns {true} if user's address is in the blacklist, {false} otherwise.

### hasRole

```solidity
function hasRole(bytes32 role, address account) public
```

Returns true if {account} has the admin role. Example hasRole(SUPERADMIN_ROLE, admin1.address).

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| role | bytes32 | encoded string with the role name |
| account | address | referrer's address |

### grantRole

```solidity
function grantRole(bytes32 role, address account) public
```
> Only owner  can call 

Grant role to a user. Example grantRole(SUPERADMIN_ROLE, admin1.address).

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| role | bytes32 | encoded string with the role name |
| account | address | referrer's address |

### revokeRole

```solidity
function revokeRole(bytes32 role, address account) public
```
> Only owner  can call 

Revoke role from a user. Example revokeRole(SUPERADMIN_ROLE, admin1.address).

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| role | bytes32 | encoded string with the role name |
| account | address | referrer's address |

### addToWhitelist

```solidity
function addToWhitelist(address account) public
```
> Cannot be called if the contract is paused

> Only owner or superadmin can call 

Add user to the whitelist. Users in the whitelist don't pay transaction fees.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | user's address |

### addToBlacklist

```solidity
function addToBlacklist(address account) public
```
> Cannot be called if the contract is paused

> Only owner or superadmin can call 
> 
Add user to the blacklist. Users in the blacklist are not allowed to make transactions with  GoldX.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | user's address |

### removeFromWhitelist

```solidity
function removeFromWhitelist(address account) public
```
> Cannot be called if the contract is paused

> Only owner or superadmin can call 

Remove user from the whitelist

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | user's address |

### removeFromBlacklist

```solidity
function removeFromBlacklist(address account) public
```
> Cannot be called if the contract is paused

> Only owner or superadmin can call 

Remove user from the blacklist

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | user's address |

### pause

```solidity
function pause() public
```
> Only owner or superadmin can call 

Pause the contract. All operations with GoldX are not allowed.

### unpause

```solidity
function unpause() public
```
> Only owner or superadmin can call 

Unpause the contract.

### excludeAccount

```solidity
function excludeAccount(address account) public
```
> Cannot be called if the contract is paused

> Only owner can call 

Remove user from the fees (toHolders %) distribution.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | user's address |

### includeAccount

```solidity
function includeAccount(address account) public
```
> Cannot be called if the contract is paused

> Only owner can call 

Add user to the fees (toHolders %) distribution

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | user's address |

### changeOwner

```solidity
function changeOwner(address newOwner) external
```
> Cannot be called if the contract is paused

> Only multi-signature vault can call
 
Multi-signature vault can change owner of the token if enough multisigners have voted for this proposal.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| newOwner | address | new owner of the token contract |
## Referral Program Functions 

### referrer

```solidity
mapping(address => address) referrer
```

Mapping that returns referrer's address for a given referral's address

### addReferrer

```solidity
function addReferrer(address account) public
```
> Cannot be called if the contract is paused

> Only owner or superadmin can call 

Add a referrer. This account can be binded to a referral to receive referrals share of the transaction fee. Can receive referral program share.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | referrer's address |

### addReferrers

```solidity
function addReferrers(address[] accounts) public
```
> Cannot be called if the contract is paused

> Only owner or superadmin can call 

Add multiple referrers

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| accounts | address[] | array of referrers |

### setReferrer

```solidity
function setReferrer(address _referrer) public
```
> Cannot be called if the contract is paused

User can call this fuction to become a referral and bind his address to the referrer of his choice. Whenever he makes a transaction he splits a referral share of the fee with his referrer. Can receive referral share.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _referrer | address | referrer's address |

### getMyReferrer

```solidity
function getMyReferrer() public view returns (address)
```

Returns referrer's addres of the msg.sender

### getReferrersList

```solidity
function getReferrersList() public view returns (address[])
```

Returns list of referrers

### getReferralsList

```solidity
function getReferralsList() public view returns (address[])
```

Returns list of referrals



# MultiSigVault.sol


### isConfirmed

```solidity
mapping(uint256 => mapping(address => bool)) isConfirmed
```
Proposal confirmation mapping (proposalId -> multisigner -> bool)

### onlySigner

```solidity
modifier onlySigner()
```

Modifier that allows only multi-signer to call this function

### proposalExists

```solidity
modifier proposalExists(uint256 _proposalIndex)
```

Checks if proposal exists inside the proposals array

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _proposalIndex | uint256 | proposal index inside proposals array |

### notExecuted

```solidity
modifier notExecuted(uint256 _proposalIndex)
```

Checks if proposal has been already executed

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _proposalIndex | uint256 | proposal index inside proposals array |

### notConfirmed

```solidity
modifier notConfirmed(uint256 _proposalIndex)
```

Checks if proposal has been already confirmed by the user

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _proposalIndex | uint256 | proposal index inside proposals array |

### constructor

```solidity
constructor(address[] _signers) public
```

Inside the constructor we assign initial multisigners. Must provide at least one address, can be owner address.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _signers | address[] | array of signer addresses |

### initialize

```solidity
function initialize(address _goldX, address _rewardVault) public
```

Initializes fuseG platform addresses.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _goldX | address | GoldX token address |
| _rewardVault | address | reward vault address |

### setNewRound

```solidity
function setNewRound(uint256 _phaseSupply, uint8 _phaseCount, uint256[] _coeffs) public
```
> Only owner can call 

> Can be called if previous round has ended, vault distributed all the GoldX tokens

> {_coeffs.length} must be equal to {_phaseCount}

> Reward vault's balance should be at least {_phaseSupply} x {_phaseCount} 

Sets new round. Loads a reward distribution table in the reward vault contract. 
For example: 

- _phaseSupply - 9,952,381 * 10 ** goldX.decimals()
- _phaseCount - 20
- _coeffs - [coeff1, coeff2. coeff3...], each coefficient should be multiplied by 10 ** goldX.decimals()

There would be 20 phases with 9,952,381 supply each, phases have their own mining coefficients that are applied to FuseG amount during transactions with FuseG token.

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

> Only owner can call 

Owner can manually add a multisigner.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _newSigner | address | new multi-signer address |

### submitProposal

```solidity
function submitProposal(enum IMultiSigVault.Proposals _proposalType, address _to, uint256 _amount) public
```
> Only multisigner can call 

Submits a proposal. There are 4 types of proposals

- 0 - transfer {_amount} of GoldX tokens to {_to} address
- 1 - add new multsigner with {_to} address
- 2 - remove multisigner with {_to} address
- 3 - change owner of GoldX token to {_to} address
In every type of proposal besides type 0 argument {_amount} can be set to it's default value 0.

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

> Only multisigner can call

> Can't confirm same proposal twice

> Can't confirm executed proposal
  
Confirms the proposal

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _proposalIndex | uint256 | index of the proposal inside proposals array |

### executeProposal

```solidity
function executeProposal(uint256 _proposalIndex) public
```

> Only multisigner can call

> Can't execute same proposal twice

> Can't execute already executed proposal

Executes the proposal. To execute a proposal it must be confirmed by at least 50% of all multisigners.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _proposalIndex | uint256 | index of the proposal inside proposals array |

### revokeConfirmation

```solidity
function revokeConfirmation(uint256 _proposalIndex) public
```
> Only multisigner can call

> Can't revoke executed proposal

> User can't revoke confirmation if he hasn't confirmed the proposal

Cancels confirmation of the proposal

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _proposalIndex | uint256 | index of the proposal inside proposals array |

### getSigners

```solidity
function getSigners() public view returns (address[])
```

Returns the list of multisigners

### getProposalCount

```solidity
function getProposalCount() public view returns (uint256)
```

Returns amount of all proposals

### getProposal

```solidity
function getProposal(uint256 _proposalIndex) public view returns (enum IMultiSigVault.Proposals proposalType, address to, uint256 amount, bool executed, uint256 numConfirmations)
```

Returns info on specific proposal

- proposalType
- subject
- amount
- isExecuted
- number of confirmations

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _proposalIndex | uint256 | index of the proposal inside proposals array |

### getRewardVault

```solidity
function getRewardVault() public view returns (address)
```

Returns reward vault address

### getGoldX

```solidity
function getGoldX() public view returns (address)
```

Returns GOLDX address

# RewardVault.sol


### multiSigVault

```solidity
address multiSigVault
```
Multi-signature vault address

### fuseG

```solidity
address fuseG
```

FuseG token address
### roundSupply

```solidity
uint256 roundSupply
```

Current round GoldX supply.


### vaultDepleted

```solidity
bool vaultDepleted
```

True - if vault has mined all of the GoldX tokens for a current round. New round is needed.
False - if current round is in progress.

### minedAmount

```solidity
uint256 minedAmount
```

Amount of GoldX tokens mined by the users.

### coeffTable

```solidity
mapping(uint8 => uint256) coeffTable
```

Returns mining coefficient for a give phase (0, 1, 2...)
### currentRound

```solidity
uint256 currentRound
```
Returns current round number.


### SUPPLY_ROLE

```solidity
bytes32 SUPPLY_ROLE
```
Encoded SUPPLY_ROLE string, use it with the access control functions (e.g. grantRole, revokeRole, hasRole). Role allows to call setNewRound function of the Reward vault.

### initialize

```solidity
function initialize(address _fuseG, address _goldX, address _multiSigVault) public
```

Initializes fuseG platform addresses. Grants msg.sender and multi-signer vault SUPPLY_ROLE.

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
> Only owner or address with a SUPPLY_ROLE can call

> Can be called if previous round has ended, vault distributed all the GoldX tokens

> {_coeffs.length} must be equal to {_phaseCount}

> Reward vault's balance should be at least {_phaseSupply} x {_phaseCount} 
> 
Sets new round. Loads a reward distribution table in the reward vault contract. 
For example: 

- _phaseSupply - 9,952,381 * 10 ** goldX.decimals()
- _phaseCount - 20
- _coeffs - [coeff1, coeff2. coeff3...], each coefficient should be multiplied by 10 ** goldX.decimals()

There would be 20 phases with 9,952,381 supply each, phases have their own mining coefficients that are applied to FuseG amount during transactions with FuseG token.

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
> Only FuseG token can call

Called by FuseG token, mines GoldX to FuseG holders. During transactions with FuseG tokens sender receives/mines a small amount of GoldX tokens based on the current phase in the reward vault. For example if Alice sends X amount of FuseG to Bob, she then receives X*coeff amount of GoldX from the vault, where coeff is the current phase's coefficient.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sender | address | user who initiated FuseG transaction |
| fuseGAmount | uint256 | amount of FuseG tokens in transaction |


### getMiningPhase

```solidity
function getMiningPhase() public view returns (uint8 phase, uint256 remainingPhaseSupply)
```

Returns current mining phase based on the GoldX amount mined from the vault, also returns remaining GoldX amount for the current phase.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| phase | uint8 | current mining phase |
| remainingPhaseSupply | uint256 | current phase GoldX amount |

### getGoldX

```solidity
function getGoldX() public view returns (address)
```

Returns GOLDX address

# IGoldX.sol



# IMultiSigVault.sol

### Proposals

```solidity
enum Proposals {
  Transaction,
  AddSigner,
  RemoveSigner,
  ChangeOwner
}
```
Proposal types enum
0 - transfer
1 - add multisigner
2 - remove multisigner
3 - change GoldX owner

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
Proposal structure 

## Events
### SubmitProposal

```solidity
event SubmitProposal(address signer, enum IMultiSigVault.Proposals proposalType, uint256 proposalIndex, address to, uint256 amount)
```

Emitted when new proposal has been created

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

Emitted when a multisigner has confirmed a proposal

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| signer | address | signer who confirmed the proposal |
| proposalIndex | uint256 | index of the proposal inside proposals array |

### RevokeConfirmation

```solidity
event RevokeConfirmation(address signer, uint256 proposalIndex)
```

Emitted when confirmation has been cancelled by a signer

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| signer | address | signer who cancelled his confirmation |
| proposalIndex | uint256 | index of the proposal inside proposals array |

### ExecuteProposal

```solidity
event ExecuteProposal(address signer, uint256 proposalIndex)
```

Emitted after proposal has been executed by the majority of votes

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| signer | address | signer who executed the proposal |
| proposalIndex | uint256 | index of the proposal inside proposals array |

# IRewardVault.sol

## Events
### NewRound

```solidity
event NewRound(uint256 roundSupply, uint256 phaseSupply, uint8 phaseCount)
```

Emitted when new round has been started

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

Emitted when GoldX is mined via FuseG transfer

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| miner | address | GoldX receiver |
| goldXAmount | uint256 | GoldX amount |

### RewardVaultDepleted

```solidity
event RewardVaultDepleted()
```

Indicates that reward vault is out of GoldX, all phases are finished



