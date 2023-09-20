# OracleChainlinkMultiEfficient

*Angle Core Team*

> OracleChainlinkMultiEfficient

Abstract contract to build oracle contracts looking at Chainlink feeds on top of

*This is contract should be overriden with the correct addresses of the Chainlink feed and the right amount of decimals*

## Methods

### BASE

```solidity
function BASE() external view returns (uint256)
```






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
function GRACE_PERIOD_TIME() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### GUARDIAN_ROLE_CHAINLINK

```solidity
function GUARDIAN_ROLE_CHAINLINK() external view returns (bytes32)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### OUTBASE

```solidity
function OUTBASE() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### SEQUENCER_UPTIME_FEED

```solidity
function SEQUENCER_UPTIME_FEED() external view returns (contract AggregatorV3Interface)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract AggregatorV3Interface | undefined |

### changeGracePeriod

```solidity
function changeGracePeriod(uint32 _gracePeriod) external nonpayable
```

Changes the grace period for the sequencer update



#### Parameters

| Name | Type | Description |
|---|---|---|
| _gracePeriod | uint32 | New stale period (in seconds) |

### changeStalePeriod

```solidity
function changeStalePeriod(uint32 _stalePeriod) external nonpayable
```

Changes the Stale Period



#### Parameters

| Name | Type | Description |
|---|---|---|
| _stalePeriod | uint32 | New stale period (in seconds) |

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



*Grants `role` to `account`. If `account` had not been already granted `role`, emits a {RoleGranted} event. Requirements: - the caller must have ``role``&#39;s admin role.*

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
function inBase() external pure returns (uint256)
```

Returns the base of the inToken

*This function is a necessary function to keep in the interface of oracle contracts interacting with the core module of the protocol*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### read

```solidity
function read() external view returns (uint256 rate)
```

Returns the outToken value of 1 inToken




#### Returns

| Name | Type | Description |
|---|---|---|
| rate | uint256 | undefined |

### readAll

```solidity
function readAll() external view returns (uint256, uint256)
```

Returns twice the value obtained from Chainlink feeds




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |
| _1 | uint256 | undefined |

### readLower

```solidity
function readLower() external view returns (uint256 rate)
```

Returns the value of the inToken obtained from Chainlink feeds




#### Returns

| Name | Type | Description |
|---|---|---|
| rate | uint256 | undefined |

### readQuote

```solidity
function readQuote(uint256 quoteAmount) external view returns (uint256)
```

Converts a quote amount of inToken to an outToken amount using Chainlink rates



#### Parameters

| Name | Type | Description |
|---|---|---|
| quoteAmount | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### readQuoteLower

```solidity
function readQuoteLower(uint256 quoteAmount) external view returns (uint256)
```

Converts a quote amount of inToken to an outToken amount using Chainlink rates



#### Parameters

| Name | Type | Description |
|---|---|---|
| quoteAmount | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### readUpper

```solidity
function readUpper() external view returns (uint256 rate)
```

Returns the value of the inToken obtained from Chainlink feeds




#### Returns

| Name | Type | Description |
|---|---|---|
| rate | uint256 | undefined |

### renounceRole

```solidity
function renounceRole(bytes32 role, address account) external nonpayable
```



*Revokes `role` from the calling account. Roles are often managed via {grantRole} and {revokeRole}: this function&#39;s purpose is to provide a mechanism for accounts to lose their privileges if they are compromised (such as when a trusted device is misplaced). If the calling account had been granted `role`, emits a {RoleRevoked} event. Requirements: - the caller must be `account`.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | undefined |
| account | address | undefined |

### revokeRole

```solidity
function revokeRole(bytes32 role, address account) external nonpayable
```



*Revokes `role` from `account`. If `account` had been granted `role`, emits a {RoleRevoked} event. Requirements: - the caller must have ``role``&#39;s admin role.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | undefined |
| account | address | undefined |

### stalePeriod

```solidity
function stalePeriod() external view returns (uint32)
```

Represent the maximum amount of time (in seconds) between each Chainlink update before the price feed is considered stale




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint32 | undefined |



## Events

### RoleAdminChanged

```solidity
event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole)
```



*Emitted when `newAdminRole` is set as ``role``&#39;s admin role, replacing `previousAdminRole` `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite {RoleAdminChanged} not being emitted signaling this. _Available since v3.1._*

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



*Emitted when `account` is granted `role`. `sender` is the account that originated the contract call, an admin role bearer except when using {_setupRole}.*

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

### GracePeriodNotOver

```solidity
error GracePeriodNotOver()
```






### InvalidChainlinkRate

```solidity
error InvalidChainlinkRate()
```






### InvalidLength

```solidity
error InvalidLength()
```






### SequencerDown

```solidity
error SequencerDown()
```






### ZeroAddress

```solidity
error ZeroAddress()
```







