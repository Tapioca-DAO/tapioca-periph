# AggregatorV2V3Interface









## Methods

### decimals

```solidity
function decimals() external view returns (uint8)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint8 | undefined |

### description

```solidity
function description() external view returns (string)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined |

### getAnswer

```solidity
function getAnswer(uint256 roundId) external view returns (int256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| roundId | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | int256 | undefined |

### getRoundData

```solidity
function getRoundData(uint80 _roundId) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _roundId | uint80 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| roundId | uint80 | undefined |
| answer | int256 | undefined |
| startedAt | uint256 | undefined |
| updatedAt | uint256 | undefined |
| answeredInRound | uint80 | undefined |

### getTimestamp

```solidity
function getTimestamp(uint256 roundId) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| roundId | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### latestAnswer

```solidity
function latestAnswer() external view returns (int256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | int256 | undefined |

### latestRound

```solidity
function latestRound() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### latestRoundData

```solidity
function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| roundId | uint80 | undefined |
| answer | int256 | undefined |
| startedAt | uint256 | undefined |
| updatedAt | uint256 | undefined |
| answeredInRound | uint80 | undefined |

### latestTimestamp

```solidity
function latestTimestamp() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### version

```solidity
function version() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |



## Events

### AnswerUpdated

```solidity
event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| current `indexed` | int256 | undefined |
| roundId `indexed` | uint256 | undefined |
| updatedAt  | uint256 | undefined |

### NewRound

```solidity
event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| roundId `indexed` | uint256 | undefined |
| startedBy `indexed` | address | undefined |
| startedAt  | uint256 | undefined |



