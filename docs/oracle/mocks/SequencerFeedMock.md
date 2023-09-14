# SequencerFeedMock









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

### roundData

```solidity
function roundData(uint80) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint80 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| roundId | uint80 | undefined |
| answer | int256 | undefined |
| startedAt | uint256 | undefined |
| updatedAt | uint256 | undefined |
| answeredInRound | uint80 | undefined |

### setLatestRoundData

```solidity
function setLatestRoundData(RoundData _latestRoundData) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _latestRoundData | RoundData | undefined |

### setRoundData

```solidity
function setRoundData(uint80 _roundId, RoundData _roundData) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _roundId | uint80 | undefined |
| _roundData | RoundData | undefined |

### version

```solidity
function version() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |




