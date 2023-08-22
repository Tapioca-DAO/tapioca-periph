# IOracle

*Angle Core Team*

> IOracle

Interface for Angle&#39;s oracle contracts reading oracle rates from both UniswapV3 and Chainlink from just UniswapV3 or from just Chainlink



## Methods

### inBase

```solidity
function inBase() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### read

```solidity
function read() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### readAll

```solidity
function readAll() external view returns (uint256 lowerRate, uint256 upperRate)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| lowerRate | uint256 | undefined |
| upperRate | uint256 | undefined |

### readLower

```solidity
function readLower() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### readQuote

```solidity
function readQuote(uint256 baseAmount) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| baseAmount | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### readQuoteLower

```solidity
function readQuoteLower(uint256 baseAmount) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| baseAmount | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### readUpper

```solidity
function readUpper() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |




