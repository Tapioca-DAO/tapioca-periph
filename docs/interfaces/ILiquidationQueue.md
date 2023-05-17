# ILiquidationQueue









## Methods

### activateBid

```solidity
function activateBid(address user, uint256 pool) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| user | address | undefined |
| pool | uint256 | undefined |

### bid

```solidity
function bid(address user, uint256 pool, uint256 amount) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| user | address | undefined |
| pool | uint256 | undefined |
| amount | uint256 | undefined |

### bidWithStable

```solidity
function bidWithStable(address user, uint256 pool, uint256 stableAssetId, uint256 amountIn, bytes data) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| user | address | undefined |
| pool | uint256 | undefined |
| stableAssetId | uint256 | undefined |
| amountIn | uint256 | undefined |
| data | bytes | undefined |

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

### getBidPoolUserInfo

```solidity
function getBidPoolUserInfo(uint256 pool, address user) external view returns (struct ILiquidationQueue.Bidder)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| pool | uint256 | undefined |
| user | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | ILiquidationQueue.Bidder | undefined |

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

### getOrderBookPoolEntries

```solidity
function getOrderBookPoolEntries(uint256 pool) external view returns (struct ILiquidationQueue.OrderBookPoolEntry[] x)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| pool | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| x | ILiquidationQueue.OrderBookPoolEntry[] | undefined |

### getOrderBookSize

```solidity
function getOrderBookSize(uint256 pool) external view returns (uint256 size)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| pool | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| size | uint256 | undefined |

### init

```solidity
function init(ILiquidationQueue.LiquidationQueueMeta, address singularity) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | ILiquidationQueue.LiquidationQueueMeta | undefined |
| singularity | address | undefined |

### liquidatedAssetId

```solidity
function liquidatedAssetId() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### lqAssetId

```solidity
function lqAssetId() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### market

```solidity
function market() external view returns (string)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined |

### marketAssetId

```solidity
function marketAssetId() external view returns (uint256)
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

### redeem

```solidity
function redeem(address to) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| to | address | undefined |

### removeBid

```solidity
function removeBid(address user, uint256 pool) external nonpayable returns (uint256 amountRemoved)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| user | address | undefined |
| pool | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| amountRemoved | uint256 | undefined |

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

### userBidIndexLength

```solidity
function userBidIndexLength(address user, uint256 pool) external view returns (uint256 len)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| user | address | undefined |
| pool | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| len | uint256 | undefined |




