# OracleUniSolo



> OracleUniSolo

Updated version of the OracleMulti contract that only uses Uniswap



## Methods

### BASE

```solidity
function BASE() external view returns (uint256)
```

Base used for computation




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### DEFAULT_ADMIN_ROLE

```solidity
function DEFAULT_ADMIN_ROLE() external view returns (bytes32)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### GRACE_PERIOD_TIME

```solidity
function GRACE_PERIOD_TIME() external view returns (uint32)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint32 | undefined |

### GUARDIAN_ROLE_UNISWAP

```solidity
function GUARDIAN_ROLE_UNISWAP() external view returns (bytes32)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### SEQUENCER_ROLE

```solidity
function SEQUENCER_ROLE() external view returns (bytes32)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### SEQUENCER_UPTIME_FEED

```solidity
function SEQUENCER_UPTIME_FEED() external view returns (contract AggregatorV3Interface)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract AggregatorV3Interface | undefined |

### acceptDefaultAdminTransfer

```solidity
function acceptDefaultAdminTransfer() external nonpayable
```



*Completes a {defaultAdmin} transfer previously started with {beginDefaultAdminTransfer}. After calling the function: - `DEFAULT_ADMIN_ROLE` should be granted to the caller. - `DEFAULT_ADMIN_ROLE` should be revoked from the previous holder. - {pendingDefaultAdmin} should be reset to zero values. Requirements: - Only can be called by the {pendingDefaultAdmin}&#39;s `newAdmin`. - The {pendingDefaultAdmin}&#39;s `acceptSchedule` should&#39;ve passed.*


### beginDefaultAdminTransfer

```solidity
function beginDefaultAdminTransfer(address newAdmin) external nonpayable
```



*Starts a {defaultAdmin} transfer by setting a {pendingDefaultAdmin} scheduled for acceptance after the current timestamp plus a {defaultAdminDelay}. Requirements: - Only can be called by the current {defaultAdmin}. Emits a DefaultAdminRoleChangeStarted event.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newAdmin | address | undefined |

### cancelDefaultAdminTransfer

```solidity
function cancelDefaultAdminTransfer() external nonpayable
```



*Cancels a {defaultAdmin} transfer previously started with {beginDefaultAdminTransfer}. A {pendingDefaultAdmin} not yet accepted can also be cancelled with this function. Requirements: - Only can be called by the current {defaultAdmin}. May emit a DefaultAdminTransferCanceled event.*


### changeDefaultAdminDelay

```solidity
function changeDefaultAdminDelay(uint48 newDelay) external nonpayable
```



*Initiates a {defaultAdminDelay} update by setting a {pendingDefaultAdminDelay} scheduled for getting into effect after the current timestamp plus a {defaultAdminDelay}. This function guarantees that any call to {beginDefaultAdminTransfer} done between the timestamp this method is called and the {pendingDefaultAdminDelay} effect schedule will use the current {defaultAdminDelay} set before calling. The {pendingDefaultAdminDelay}&#39;s effect schedule is defined in a way that waiting until the schedule and then calling {beginDefaultAdminTransfer} with the new delay will take at least the same as another {defaultAdmin} complete transfer (including acceptance). The schedule is designed for two scenarios: - When the delay is changed for a larger one the schedule is `block.timestamp + newDelay` capped by {defaultAdminDelayIncreaseWait}. - When the delay is changed for a shorter one, the schedule is `block.timestamp + (current delay - new delay)`. A {pendingDefaultAdminDelay} that never got into effect will be canceled in favor of a new scheduled change. Requirements: - Only can be called by the current {defaultAdmin}. Emits a DefaultAdminDelayChangeScheduled event and may emit a DefaultAdminDelayChangeCanceled event.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newDelay | uint48 | undefined |

### changeGracePeriod

```solidity
function changeGracePeriod(uint32 _gracePeriod) external nonpayable
```

Changes the grace period for the sequencer update



#### Parameters

| Name | Type | Description |
|---|---|---|
| _gracePeriod | uint32 | New stale period (in seconds) |

### changeTwapPeriod

```solidity
function changeTwapPeriod(uint32 _twapPeriod) external nonpayable
```

Changes the TWAP period



#### Parameters

| Name | Type | Description |
|---|---|---|
| _twapPeriod | uint32 | New window to compute the TWAP |

### circuitUniIsMultiplied

```solidity
function circuitUniIsMultiplied(uint256) external view returns (uint8)
```

Whether the rate obtained with each pool should be multiplied or divided to the current amount



#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint8 | undefined |

### circuitUniswap

```solidity
function circuitUniswap(uint256) external view returns (contract IUniswapV3Pool)
```

Uniswap pools, the order of the pools to arrive to the final price should be respected



#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract IUniswapV3Pool | undefined |

### defaultAdmin

```solidity
function defaultAdmin() external view returns (address)
```



*Returns the address of the current `DEFAULT_ADMIN_ROLE` holder.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### defaultAdminDelay

```solidity
function defaultAdminDelay() external view returns (uint48)
```



*Returns the delay required to schedule the acceptance of a {defaultAdmin} transfer started. This delay will be added to the current timestamp when calling {beginDefaultAdminTransfer} to set the acceptance schedule. NOTE: If a delay change has been scheduled, it will take effect as soon as the schedule passes, making this function returns the new delay. See {changeDefaultAdminDelay}.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint48 | undefined |

### defaultAdminDelayIncreaseWait

```solidity
function defaultAdminDelayIncreaseWait() external view returns (uint48)
```



*Maximum time in seconds for an increase to {defaultAdminDelay} (that is scheduled using {changeDefaultAdminDelay}) to take effect. Default to 5 days. When the {defaultAdminDelay} is scheduled to be increased, it goes into effect after the new delay has passed with the purpose of giving enough time for reverting any accidental change (i.e. using milliseconds instead of seconds) that may lock the contract. However, to avoid excessive schedules, the wait is capped by this function and it can be overrode for a custom {defaultAdminDelay} increase scheduling. IMPORTANT: Make sure to add a reasonable amount of time while overriding this value, otherwise, there&#39;s a risk of setting a high new delay that goes into effect almost immediately without the possibility of human intervention in the case of an input error (eg. set milliseconds instead of seconds).*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint48 | undefined |

### description

```solidity
function description() external view returns (bytes32)
```

Description of the assets concerned by the oracle and the price outputted




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### getRoleAdmin

```solidity
function getRoleAdmin(bytes32 role) external view returns (bytes32)
```



*Returns the admin role that controls `role`. See {grantRole} and {revokeRole}. To change a role&#39;s admin, use {_setRoleAdmin}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### grantRole

```solidity
function grantRole(bytes32 role, address account) external nonpayable
```



*See {AccessControl-grantRole}. Reverts for `DEFAULT_ADMIN_ROLE`.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | undefined |
| account | address | undefined |

### hasRole

```solidity
function hasRole(bytes32 role, address account) external view returns (bool)
```



*Returns `true` if `account` has been granted `role`.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | undefined |
| account | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### inBase

```solidity
function inBase() external view returns (uint256)
```

Unit of the in-currency




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### increaseTWAPStore

```solidity
function increaseTWAPStore(uint16 newLengthStored) external nonpayable
```

Increases the number of observations for each Uniswap pools

*newLengthStored should be larger than all previous pools observations length*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newLengthStored | uint16 | Size asked for |

### outBase

```solidity
function outBase() external view returns (uint256)
```

Unit out Uniswap currency




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### owner

```solidity
function owner() external view returns (address)
```



*See {IERC5313-owner}.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### pendingDefaultAdmin

```solidity
function pendingDefaultAdmin() external view returns (address newAdmin, uint48 schedule)
```



*Returns a tuple of a `newAdmin` and an accept schedule. After the `schedule` passes, the `newAdmin` will be able to accept the {defaultAdmin} role by calling {acceptDefaultAdminTransfer}, completing the role transfer. A zero value only in `acceptSchedule` indicates no pending admin transfer. NOTE: A zero address `newAdmin` means that {defaultAdmin} is being renounced.*


#### Returns

| Name | Type | Description |
|---|---|---|
| newAdmin | address | undefined |
| schedule | uint48 | undefined |

### pendingDefaultAdminDelay

```solidity
function pendingDefaultAdminDelay() external view returns (uint48 newDelay, uint48 schedule)
```



*Returns a tuple of `newDelay` and an effect schedule. After the `schedule` passes, the `newDelay` will get into effect immediately for every new {defaultAdmin} transfer started with {beginDefaultAdminTransfer}. A zero value only in `effectSchedule` indicates no pending delay change. NOTE: A zero value only for `newDelay` means that the next {defaultAdminDelay} will be zero after the effect schedule.*


#### Returns

| Name | Type | Description |
|---|---|---|
| newDelay | uint48 | undefined |
| schedule | uint48 | undefined |

### read

```solidity
function read() external view returns (uint256)
```

Reads the Uniswap rate using the circuit given

*By default even if there is a Chainlink rate, this function returns the Uniswap rateThe amount returned is expressed with base `BASE` (and not the base of the out-currency)*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | The current rate between the in-currency and out-currency |

### readAll

```solidity
function readAll() external view returns (uint256, uint256)
```

Read rates from the circuit of both Uniswap and Chainlink if there are both circuits else returns twice the same price

*The rate returned is expressed with base `BASE` (and not the base of the out-currency)*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | Return all available rates (Chainlink and Uniswap) with the lowest rate returned first. |
| _1 | uint256 | undefined |

### readLower

```solidity
function readLower() external view returns (uint256 rate)
```

Reads rates from the circuit of both Uniswap and Chainlink if there are both circuits and returns either the highest of both rates or the lowest

*If there is only one rate computed in an oracle contract, then the only rate is returned regardless of the value of the `lower` parameterThe rate returned is expressed with base `BASE` (and not the base of the out-currency)*


#### Returns

| Name | Type | Description |
|---|---|---|
| rate | uint256 | The lower rate between Chainlink and Uniswap |

### readQuote

```solidity
function readQuote(uint256 quoteAmount) external view returns (uint256)
```

Converts an in-currency quote amount to out-currency using the Uniswap rate

*Like in the `read` function, this function returns the Uniswap quoteThe amount returned is expressed with base `BASE` (and not the base of the out-currency)*

#### Parameters

| Name | Type | Description |
|---|---|---|
| quoteAmount | uint256 | Amount (in the input collateral) to be converted in out-currency |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | Quote amount in out-currency from the base amount in in-currency |

### readQuoteLower

```solidity
function readQuoteLower(uint256 quoteAmount) external view returns (uint256)
```

Returns the lowest quote amount between Uniswap and Chainlink circuits (if possible). If the oracle contract only involves a single feed, then this returns the value of this feed

*The rate returned is expressed with base `BASE` (and not the base of the out-currency)*

#### Parameters

| Name | Type | Description |
|---|---|---|
| quoteAmount | uint256 | Amount (in the input collateral) to be converted |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | The lowest quote amount from the quote amount in in-currency |

### readUpper

```solidity
function readUpper() external view returns (uint256 rate)
```

Reads rates from the circuit of both Uniswap and Chainlink if there are both circuits and returns either the highest of both rates or the lowest

*If there is only one rate computed in an oracle contract, then the only rate is returned regardless of the value of the `lower` parameterThe rate returned is expressed with base `BASE` (and not the base of the out-currency)*


#### Returns

| Name | Type | Description |
|---|---|---|
| rate | uint256 | The upper rate between Chainlink and Uniswap |

### renounceRole

```solidity
function renounceRole(bytes32 role, address account) external nonpayable
```



*See {AccessControl-renounceRole}. For the `DEFAULT_ADMIN_ROLE`, it only allows renouncing in two steps by first calling {beginDefaultAdminTransfer} to the `address(0)`, so it&#39;s required that the {pendingDefaultAdmin} schedule has also passed when calling this function. After its execution, it will not be possible to call `onlyRole(DEFAULT_ADMIN_ROLE)` functions. NOTE: Renouncing `DEFAULT_ADMIN_ROLE` will leave the contract without a {defaultAdmin}, thereby disabling any functionality that is only available for it, and the possibility of reassigning a non-administrated role.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | undefined |
| account | address | undefined |

### revokeRole

```solidity
function revokeRole(bytes32 role, address account) external nonpayable
```



*See {AccessControl-revokeRole}. Reverts for `DEFAULT_ADMIN_ROLE`.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | undefined |
| account | address | undefined |

### rollbackDefaultAdminDelay

```solidity
function rollbackDefaultAdminDelay() external nonpayable
```



*Cancels a scheduled {defaultAdminDelay} change. Requirements: - Only can be called by the current {defaultAdmin}. May emit a DefaultAdminDelayChangeCanceled event.*


### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) external view returns (bool)
```



*See {IERC165-supportsInterface}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| interfaceId | bytes4 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### twapPeriod

```solidity
function twapPeriod() external view returns (uint32)
```

Time weigthed average window that should be used for each Uniswap rate It is mainly going to be 5 minutes in the protocol




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint32 | undefined |



## Events

### DefaultAdminDelayChangeCanceled

```solidity
event DefaultAdminDelayChangeCanceled()
```



*Emitted when a {pendingDefaultAdminDelay} is reset if its schedule didn&#39;t pass.*


### DefaultAdminDelayChangeScheduled

```solidity
event DefaultAdminDelayChangeScheduled(uint48 newDelay, uint48 effectSchedule)
```



*Emitted when a {defaultAdminDelay} change is started, setting `newDelay` as the next delay to be applied between default admin transfer after `effectSchedule` has passed.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newDelay  | uint48 | undefined |
| effectSchedule  | uint48 | undefined |

### DefaultAdminTransferCanceled

```solidity
event DefaultAdminTransferCanceled()
```



*Emitted when a {pendingDefaultAdmin} is reset if it was never accepted, regardless of its schedule.*


### DefaultAdminTransferScheduled

```solidity
event DefaultAdminTransferScheduled(address indexed newAdmin, uint48 acceptSchedule)
```



*Emitted when a {defaultAdmin} transfer is started, setting `newAdmin` as the next address to become the {defaultAdmin} by calling {acceptDefaultAdminTransfer} only after `acceptSchedule` passes.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newAdmin `indexed` | address | undefined |
| acceptSchedule  | uint48 | undefined |

### RoleAdminChanged

```solidity
event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole)
```



*Emitted when `newAdminRole` is set as ``role``&#39;s admin role, replacing `previousAdminRole` `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite {RoleAdminChanged} not being emitted signaling this.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role `indexed` | bytes32 | undefined |
| previousAdminRole `indexed` | bytes32 | undefined |
| newAdminRole `indexed` | bytes32 | undefined |

### RoleGranted

```solidity
event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender)
```



*Emitted when `account` is granted `role`. `sender` is the account that originated the contract call, an admin role bearer except when using {AccessControl-_setupRole}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role `indexed` | bytes32 | undefined |
| account `indexed` | address | undefined |
| sender `indexed` | address | undefined |

### RoleRevoked

```solidity
event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender)
```



*Emitted when `account` is revoked `role`. `sender` is the account that originated the contract call:   - if using `revokeRole`, it is the admin role bearer   - if using `renounceRole`, it is the role bearer (i.e. `account`)*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role `indexed` | bytes32 | undefined |
| account `indexed` | address | undefined |
| sender `indexed` | address | undefined |



## Errors

### AccessControlBadConfirmation

```solidity
error AccessControlBadConfirmation()
```



*The caller of a function is not the expected one. NOTE: Don&#39;t confuse with {AccessControlUnauthorizedAccount}.*


### AccessControlEnforcedDefaultAdminDelay

```solidity
error AccessControlEnforcedDefaultAdminDelay(uint48 schedule)
```



*The delay for transferring the default admin delay is enforced and the operation must wait until `schedule`. NOTE: `schedule` can be 0 indicating there&#39;s no transfer scheduled.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| schedule | uint48 | undefined |

### AccessControlEnforcedDefaultAdminRules

```solidity
error AccessControlEnforcedDefaultAdminRules()
```



*At least one of the following rules was violated: - The `DEFAULT_ADMIN_ROLE` must only be managed by itself. - The `DEFAULT_ADMIN_ROLE` must only be held by one account at the time. - Any `DEFAULT_ADMIN_ROLE` transfer must be in two delayed steps.*


### AccessControlInvalidDefaultAdmin

```solidity
error AccessControlInvalidDefaultAdmin(address defaultAdmin)
```



*The new default admin is not a valid default admin.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| defaultAdmin | address | undefined |

### AccessControlUnauthorizedAccount

```solidity
error AccessControlUnauthorizedAccount(address account, bytes32 neededRole)
```



*The `account` is missing a role.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | undefined |
| neededRole | bytes32 | undefined |

### GracePeriodNotOver

```solidity
error GracePeriodNotOver()
```






### SequencerDown

```solidity
error SequencerDown()
```






