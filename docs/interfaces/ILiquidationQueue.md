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



## Events

### ActivateBid

```solidity
event ActivateBid(address indexed caller, address indexed bidder, uint256 indexed pool, uint256 usdoAmount, uint256 liquidatedAssetAmount, uint256 collateralValue, uint256 timestamp)
```

event emitted when a bid is activated



#### Parameters

| Name | Type | Description |
|---|---|---|
| caller `indexed` | address | undefined |
| bidder `indexed` | address | undefined |
| pool `indexed` | uint256 | undefined |
| usdoAmount  | uint256 | undefined |
| liquidatedAssetAmount  | uint256 | undefined |
| collateralValue  | uint256 | undefined |
| timestamp  | uint256 | undefined |

### Bid

```solidity
event Bid(address indexed caller, address indexed bidder, uint256 indexed pool, uint256 usdoAmount, uint256 liquidatedAssetAmount, uint256 timestamp)
```

event emitted when a bid is placed



#### Parameters

| Name | Type | Description |
|---|---|---|
| caller `indexed` | address | undefined |
| bidder `indexed` | address | undefined |
| pool `indexed` | uint256 | undefined |
| usdoAmount  | uint256 | undefined |
| liquidatedAssetAmount  | uint256 | undefined |
| timestamp  | uint256 | undefined |

### BidSwapperUpdated

```solidity
event BidSwapperUpdated(contract IBidder indexed _old, address indexed _new)
```

event emitted when bid swapper is updated



#### Parameters

| Name | Type | Description |
|---|---|---|
| _old `indexed` | contract IBidder | undefined |
| _new `indexed` | address | undefined |

### ExecuteBids

```solidity
event ExecuteBids(address indexed caller, uint256 indexed pool, uint256 usdoAmountExecuted, uint256 liquidatedAssetAmountExecuted, uint256 collateralLiquidated, uint256 timestamp)
```

event emitted when bids are executed



#### Parameters

| Name | Type | Description |
|---|---|---|
| caller `indexed` | address | undefined |
| pool `indexed` | uint256 | undefined |
| usdoAmountExecuted  | uint256 | undefined |
| liquidatedAssetAmountExecuted  | uint256 | undefined |
| collateralLiquidated  | uint256 | undefined |
| timestamp  | uint256 | undefined |

### Redeem

```solidity
event Redeem(address indexed redeemer, address indexed to, uint256 amount)
```

event emitted when funds are redeemed



#### Parameters

| Name | Type | Description |
|---|---|---|
| redeemer `indexed` | address | undefined |
| to `indexed` | address | undefined |
| amount  | uint256 | undefined |

### RemoveBid

```solidity
event RemoveBid(address indexed caller, address indexed bidder, uint256 indexed pool, uint256 usdoAmount, uint256 liquidatedAssetAmount, uint256 collateralValue, uint256 timestamp)
```

event emitted a bid is removed



#### Parameters

| Name | Type | Description |
|---|---|---|
| caller `indexed` | address | undefined |
| bidder `indexed` | address | undefined |
| pool `indexed` | uint256 | undefined |
| usdoAmount  | uint256 | undefined |
| liquidatedAssetAmount  | uint256 | undefined |
| collateralValue  | uint256 | undefined |
| timestamp  | uint256 | undefined |

### UsdoSwapperUpdated

```solidity
event UsdoSwapperUpdated(contract IBidder indexed _old, address indexed _new)
```

event emitted when usdo swapper is updated



#### Parameters

| Name | Type | Description |
|---|---|---|
| _old `indexed` | contract IBidder | undefined |
| _new `indexed` | address | undefined |



