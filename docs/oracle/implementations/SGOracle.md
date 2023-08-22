# SGOracle





Courtesy of https://gist.github.com/0xShaito/f01f04cb26d0f89a0cead15cff3f7047

*Addresses are for Arbitrum*

## Methods

### SG_POOL

```solidity
function SG_POOL() external view returns (contract IStargatePool)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract IStargatePool | undefined |

### UNDERLYING

```solidity
function UNDERLYING() external view returns (contract AggregatorV2V3Interface)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract AggregatorV2V3Interface | undefined |

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

### decimals

```solidity
function decimals() external view returns (uint8)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint8 | undefined |

### get

```solidity
function get(bytes) external nonpayable returns (bool success, uint256 rate)
```

Get the latest exchange rate. For example: (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));



#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| success | bool | if no valid (recent) rate is available, return false else true. |
| rate | uint256 | The rate of the requested asset / pair / pool. |

### name

```solidity
function name(bytes) external view returns (string)
```

Returns a human readable name about this oracle. For example: (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));



#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | (string) A human readable name about this oracle. |

### peek

```solidity
function peek(bytes) external view returns (bool success, uint256 rate)
```

Check the last exchange rate without any state changes. For example: (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));



#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| success | bool | if no valid (recent) rate is available, return false else true. |
| rate | uint256 | The rate of the requested asset / pair / pool. |

### peekSpot

```solidity
function peekSpot(bytes) external view returns (uint256 rate)
```

Check the current spot exchange rate without any state changes. For oracles like TWAP this will be different from peek(). For example: (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));



#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| rate | uint256 | The rate of the requested asset / pair / pool. |

### symbol

```solidity
function symbol(bytes) external view returns (string)
```

Returns a human readable (short) name about this oracle. For example: (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));



#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | (string) A human readable symbol name about this oracle. |




