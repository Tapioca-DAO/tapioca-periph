# IERC3156FlashLender









## Methods

### flashFee

```solidity
function flashFee(address token, uint256 amount) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| token | address | undefined |
| amount | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### flashLoan

```solidity
function flashLoan(contract IERC3156FlashBorrower receiver, address token, uint256 amount, bytes data) external nonpayable returns (bool)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| receiver | contract IERC3156FlashBorrower | undefined |
| token | address | undefined |
| amount | uint256 | undefined |
| data | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### maxFlashLoan

```solidity
function maxFlashLoan(address token) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| token | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |




