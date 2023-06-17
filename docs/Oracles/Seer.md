# Seer









## Methods

### _getUniPrice

```solidity
function _getUniPrice() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### _name

```solidity
function _name() external view returns (string)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined |

### _symbol

```solidity
function _symbol() external view returns (string)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined |

### get

```solidity
function get(bytes data) external nonpayable returns (bool success, uint256 rate)
```

Get the latest exchange rate.



#### Parameters

| Name | Type | Description |
|---|---|---|
| data | bytes | Usually abi encoded, implementation specific data that contains information and arguments to &amp; about the oracle. For example: (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256)); |

#### Returns

| Name | Type | Description |
|---|---|---|
| success | bool | if no valid (recent) rate is available, return false else true. |
| rate | uint256 | The rate of the requested asset / pair / pool. |

### getPrice

```solidity
function getPrice() external view returns (int256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | int256 | undefined |

### name

```solidity
function name(bytes data) external view returns (string)
```

Returns a human readable name about this oracle.



#### Parameters

| Name | Type | Description |
|---|---|---|
| data | bytes | Usually abi encoded, implementation specific data that contains information and arguments to &amp; about the oracle. For example: (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256)); |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | (string) A human readable name about this oracle. |

### peek

```solidity
function peek(bytes data) external view returns (bool success, uint256 rate)
```

Check the last exchange rate without any state changes.



#### Parameters

| Name | Type | Description |
|---|---|---|
| data | bytes | Usually abi encoded, implementation specific data that contains information and arguments to &amp; about the oracle. For example: (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256)); |

#### Returns

| Name | Type | Description |
|---|---|---|
| success | bool | if no valid (recent) rate is available, return false else true. |
| rate | uint256 | The rate of the requested asset / pair / pool. |

### peekSpot

```solidity
function peekSpot(bytes data) external view returns (uint256 rate)
```

Check the current spot exchange rate without any state changes. For oracles like TWAP this will be different from peek().



#### Parameters

| Name | Type | Description |
|---|---|---|
| data | bytes | Usually abi encoded, implementation specific data that contains information and arguments to &amp; about the oracle. For example: (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256)); |

#### Returns

| Name | Type | Description |
|---|---|---|
| rate | uint256 | The rate of the requested asset / pair / pool. |

### symbol

```solidity
function symbol(bytes data) external view returns (string)
```

Returns a human readable (short) name about this oracle.



#### Parameters

| Name | Type | Description |
|---|---|---|
| data | bytes | Usually abi encoded, implementation specific data that contains information and arguments to &amp; about the oracle. For example: (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256)); |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | (string) A human readable symbol name about this oracle. |




