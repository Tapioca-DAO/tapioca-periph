# PausableMapUpgradeable

*Angle Core Team after a fork from OpenZeppelin&#39;s similar Pausable Contracts*

> PausableMap

Contract module which allows children to implement an emergency stop mechanism that can be triggered by an authorized account.It generalizes Pausable from OpenZeppelin by allowing to specify a bytes32 that should be stopped

*This module is used through inheritanceIn Angle&#39;s protocol, this contract is mainly used in `StableMasterFront` to prevent SLPs and new stable holders from coming inThe modifiers `whenNotPaused` and `whenPaused` from the original OpenZeppelin contracts were removed to save some space and because they are not used in the `StableMaster` contract where this contract is imported*

## Methods

### paused

```solidity
function paused(bytes32) external view returns (bool)
```



*Mapping between a name and a boolean representing the paused state*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |



## Events

### Paused

```solidity
event Paused(bytes32 indexed name)
```



*Emitted when the pause is triggered for `name`*

#### Parameters

| Name | Type | Description |
|---|---|---|
| name `indexed` | bytes32 | undefined |

### Unpaused

```solidity
event Unpaused(bytes32 indexed name)
```



*Emitted when the pause is lifted for `name`*

#### Parameters

| Name | Type | Description |
|---|---|---|
| name `indexed` | bytes32 | undefined |



