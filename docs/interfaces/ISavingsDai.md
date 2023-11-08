# ISavingsDai









## Methods

### approve

```solidity
function approve(address spender, uint256 value) external nonpayable returns (bool)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| spender | address | undefined |
| value | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### asset

```solidity
function asset() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### balanceOf

```solidity
function balanceOf(address owner) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| owner | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### convertToAssets

```solidity
function convertToAssets(uint256 shares) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| shares | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### convertToShares

```solidity
function convertToShares(uint256 assets) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| assets | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### dai

```solidity
function dai() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### decreaseAllowance

```solidity
function decreaseAllowance(address spender, uint256 subtractedValue) external nonpayable returns (bool)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| spender | address | undefined |
| subtractedValue | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### deploymentChainId

```solidity
function deploymentChainId() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### deposit

```solidity
function deposit(uint256 assets, address receiver) external nonpayable returns (uint256 shares)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| assets | uint256 | undefined |
| receiver | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| shares | uint256 | undefined |

### increaseAllowance

```solidity
function increaseAllowance(address spender, uint256 addedValue) external nonpayable returns (bool)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| spender | address | undefined |
| addedValue | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### maxDeposit

```solidity
function maxDeposit(address) external pure returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### maxRedeem

```solidity
function maxRedeem(address owner) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| owner | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### maxWithdraw

```solidity
function maxWithdraw(address owner) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| owner | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### permit

```solidity
function permit(address owner, address spender, uint256 value, uint256 deadline, bytes signature) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| owner | address | undefined |
| spender | address | undefined |
| value | uint256 | undefined |
| deadline | uint256 | undefined |
| signature | bytes | undefined |

### permit

```solidity
function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| owner | address | undefined |
| spender | address | undefined |
| value | uint256 | undefined |
| deadline | uint256 | undefined |
| v | uint8 | undefined |
| r | bytes32 | undefined |
| s | bytes32 | undefined |

### previewDeposit

```solidity
function previewDeposit(uint256 assets) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| assets | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### previewRedeem

```solidity
function previewRedeem(uint256 shares) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| shares | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### previewWithdraw

```solidity
function previewWithdraw(uint256 assets) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| assets | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### redeem

```solidity
function redeem(uint256 shares, address receiver, address owner) external nonpayable returns (uint256 assets)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| shares | uint256 | undefined |
| receiver | address | undefined |
| owner | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| assets | uint256 | undefined |

### totalAssets

```solidity
function totalAssets() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### transfer

```solidity
function transfer(address to, uint256 value) external nonpayable returns (bool)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| to | address | undefined |
| value | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### transferFrom

```solidity
function transferFrom(address from, address to, uint256 value) external nonpayable returns (bool)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| from | address | undefined |
| to | address | undefined |
| value | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### withdraw

```solidity
function withdraw(uint256 assets, address receiver, address owner) external nonpayable returns (uint256 shares)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| assets | uint256 | undefined |
| receiver | address | undefined |
| owner | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| shares | uint256 | undefined |




