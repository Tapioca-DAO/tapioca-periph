# ILiquidationQueue









## Methods

### executeBids

```solidity
function executeBids(uint256 collateralAmountToLiquidate, bytes swapData) external nonpayable returns (uint256 amountExecuted, uint256 collateralLiquidated)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| collateralAmountToLiquidate | uint256 | undefined |
| swapData | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| amountExecuted | uint256 | undefined |
| collateralLiquidated | uint256 | undefined |

### getNextAvailBidPool

```solidity
function getNextAvailBidPool() external view returns (uint256 i, bool available, uint256 totalAmount)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| i | uint256 | undefined |
| available | bool | undefined |
| totalAmount | uint256 | undefined |

### init

```solidity
function init(ILiquidationQueue.LiquidationQueueMeta, address singularity) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | ILiquidationQueue.LiquidationQueueMeta | undefined |
| singularity | address | undefined |

### lqAssetId

```solidity
function lqAssetId() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### onlyOnce

```solidity
function onlyOnce() external view returns (bool)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### setBidExecutionSwapper

```solidity
function setBidExecutionSwapper(address swapper) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| swapper | address | undefined |

### setUsdoSwapper

```solidity
function setUsdoSwapper(address swapper) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| swapper | address | undefined |




