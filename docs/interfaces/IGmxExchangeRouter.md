# IGmxExchangeRouter









## Methods

### createDeposit

```solidity
function createDeposit(IGmxExchangeRouter.CreateDepositParams params) external payable returns (bytes32)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| params | IGmxExchangeRouter.CreateDepositParams | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### createWithdrawal

```solidity
function createWithdrawal(IGmxExchangeRouter.CreateWithdrawalParams params) external payable returns (bytes32)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| params | IGmxExchangeRouter.CreateWithdrawalParams | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### multicall

```solidity
function multicall(bytes[] data) external payable returns (bytes[] results)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| data | bytes[] | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| results | bytes[] | undefined |

### sendTokens

```solidity
function sendTokens(address token, address receiver, uint256 amount) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| token | address | undefined |
| receiver | address | undefined |
| amount | uint256 | undefined |

### sendWnt

```solidity
function sendWnt(address receiver, uint256 amount) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| receiver | address | undefined |
| amount | uint256 | undefined |




