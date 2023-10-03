# LiquidationQueue

*@0xRektora, TapiocaDAO*

> LiquidationQueue





## Methods

### activateBid

```solidity
function activateBid(address user, uint256 pool) external nonpayable
```

Activate a bid by putting it in the order book.

*Create an entry in `orderBook` and remove it from `bidPools`.Spam vector attack is mitigated the min amount req., 10min CD + activation fees.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| user | address | The user to activate the bid for. |
| pool | uint256 | The target pool. |

### balancesDue

```solidity
function balancesDue(address) external view returns (uint256)
```

Due balance of users

*user =&gt; amountDue.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### bid

```solidity
function bid(address user, uint256 pool, uint256 amount) external nonpayable
```

Add a bid to a bid pool.

*Create an entry in `bidPools`.      Clean the userBidIndex here instead of the `executeBids()` function to save on gas.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| user | address | The bidder. |
| pool | uint256 | To which pool the bid should go. |
| amount | uint256 | The amount in asset to bid. |

### bidPools

```solidity
function bidPools(uint256) external view returns (uint256 totalAmount)
```

Bid pools

*x% premium =&gt; bid pool      0 ... 30 range      poolId =&gt; totalAmount      poolId =&gt; userAddress =&gt; userBidInfo.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| totalAmount | uint256 | undefined |

### bidWithStable

```solidity
function bidWithStable(address user, uint256 pool, uint256 stableAssetId, uint256 amountIn, bytes data) external nonpayable
```

Add a bid to a bid pool using stablecoins.

*Works the same way as `bid` but performs a swap from the stablecoin to USDO      - if stableAssetId == usdoAssetId, no swap is performed*

#### Parameters

| Name | Type | Description |
|---|---|---|
| user | address | The bidder |
| pool | uint256 | To which pool the bid should go |
| stableAssetId | uint256 | Stablecoin YieldBox asset id |
| amountIn | uint256 | Stablecoin amount |
| data | bytes | Extra data for swap operations |

### executeBids

```solidity
function executeBids(uint256 collateralAmountToLiquidate, bytes swapData) external nonpayable returns (uint256 totalAmountExecuted, uint256 totalCollateralLiquidated)
```

Execute the liquidation call by executing the bids placed in the pools in ASC order.

*Should only be called from Singularity.      Singularity should send the `collateralAmountToLiquidate` to this contract before calling this function. Tx will fail if it can&#39;t transfer allowed Penrose asset from Singularity.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| collateralAmountToLiquidate | uint256 | The amount of collateral to liquidate. |
| swapData | bytes | Swap data necessary for swapping USDO to market asset; necessary only if bidder added USDO |

#### Returns

| Name | Type | Description |
|---|---|---|
| totalAmountExecuted | uint256 | The amount of asset that was executed. |
| totalCollateralLiquidated | uint256 | The amount of collateral that was liquidated. |

### getBidPoolUserInfo

```solidity
function getBidPoolUserInfo(uint256 pool, address user) external view returns (struct ILiquidationQueue.Bidder)
```

returns user data for an existing bid pool



#### Parameters

| Name | Type | Description |
|---|---|---|
| pool | uint256 | the pool identifier |
| user | address | the user identifier |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | ILiquidationQueue.Bidder | bidder information |

### getNextAvailBidPool

```solidity
function getNextAvailBidPool() external view returns (uint256 i, bool available, uint256 totalAmount)
```

Get the next not empty bid pool in ASC order.




#### Returns

| Name | Type | Description |
|---|---|---|
| i | uint256 | The bid pool id. |
| available | bool | True if there is at least 1 bid available across all the order books. |
| totalAmount | uint256 | Total available liquidated asset amount. |

### getOrderBookPoolEntries

```solidity
function getOrderBookPoolEntries(uint256 pool) external view returns (struct ILiquidationQueue.OrderBookPoolEntry[] x)
```

returns an array of &#39;OrderBookPoolEntry&#39; for a pool



#### Parameters

| Name | Type | Description |
|---|---|---|
| pool | uint256 | the pool id return x order book pool entries details |

#### Returns

| Name | Type | Description |
|---|---|---|
| x | ILiquidationQueue.OrderBookPoolEntry[] | undefined |

### getOrderBookSize

```solidity
function getOrderBookSize(uint256 pool) external view returns (uint256 size)
```

returns order book size



#### Parameters

| Name | Type | Description |
|---|---|---|
| pool | uint256 | the pool id |

#### Returns

| Name | Type | Description |
|---|---|---|
| size | uint256 | order book size |

### init

```solidity
function init(ILiquidationQueue.LiquidationQueueMeta _liquidationQueueMeta, address _singularity) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _liquidationQueueMeta | ILiquidationQueue.LiquidationQueueMeta | undefined |
| _singularity | address | undefined |

### liquidatedAssetId

```solidity
function liquidatedAssetId() external view returns (uint256)
```

asset that is being liquidated




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### liquidationQueueMeta

```solidity
function liquidationQueueMeta() external view returns (uint256 activationTime, uint256 minBidAmount, address feeCollector, contract IBidder bidExecutionSwapper, contract IBidder usdoSwapper)
```

returns metadata information




#### Returns

| Name | Type | Description |
|---|---|---|
| activationTime | uint256 | undefined |
| minBidAmount | uint256 | undefined |
| feeCollector | address | undefined |
| bidExecutionSwapper | contract IBidder | undefined |
| usdoSwapper | contract IBidder | undefined |

### lqAssetId

```solidity
function lqAssetId() external view returns (uint256)
```

liquidation queue Penrose asset id




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### market

```solidity
function market() external view returns (string)
```

returns targeted market




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | market name |

### marketAssetId

```solidity
function marketAssetId() external view returns (uint256)
```

singularity asset id




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### onlyOnce

```solidity
function onlyOnce() external view returns (bool)
```

initialization status




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### orderBookEntries

```solidity
function orderBookEntries(uint256, uint256) external view returns (address bidder, struct ILiquidationQueue.Bidder bidInfo)
```

The actual order book. Entries are stored only once a bid has been activated

*poolId =&gt; bidIndex =&gt; bidEntry).*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |
| _1 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| bidder | address | undefined |
| bidInfo | ILiquidationQueue.Bidder | undefined |

### orderBookInfos

```solidity
function orderBookInfos(uint256) external view returns (uint32 poolId, uint32 nextBidPull, uint32 nextBidPush)
```

Meta-data about the order book pool

*poolId =&gt; poolInfo.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| poolId | uint32 | undefined |
| nextBidPull | uint32 | undefined |
| nextBidPush | uint32 | undefined |

### penrose

```solidity
function penrose() external view returns (contract IPenrose)
```

Penrose addres




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract IPenrose | undefined |

### redeem

```solidity
function redeem(address to) external nonpayable
```

Redeem a balance.

*`msg.sender` is used as the redeemer.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| to | address | The address to redeem to. |

### removeBid

```solidity
function removeBid(address user, uint256 pool) external nonpayable returns (uint256 amountRemoved)
```

Remove a not yet activated bid from the bid pool.

*Remove `msg.sender` funds.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| user | address | The user to send the funds to. |
| pool | uint256 | The pool to remove the bid from. |

#### Returns

| Name | Type | Description |
|---|---|---|
| amountRemoved | uint256 | The amount of the bid. |

### setBidExecutionSwapper

```solidity
function setBidExecutionSwapper(address _swapper) external nonpayable
```

updates the bid swapper address



#### Parameters

| Name | Type | Description |
|---|---|---|
| _swapper | address | thew new ICollateralSwaper contract address |

### setUsdoSwapper

```solidity
function setUsdoSwapper(address _swapper) external nonpayable
```

updates the bid swapper address



#### Parameters

| Name | Type | Description |
|---|---|---|
| _swapper | address | thew new ICollateralSwaper contract address |

### singularity

```solidity
function singularity() external view returns (contract ISingularity)
```

targeted market




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract ISingularity | undefined |

### userBidIndexLength

```solidity
function userBidIndexLength(address user, uint256 pool) external view returns (uint256 len)
```

returns number of pool bids for user



#### Parameters

| Name | Type | Description |
|---|---|---|
| user | address | the user indentifier |
| pool | uint256 | the pool identifier |

#### Returns

| Name | Type | Description |
|---|---|---|
| len | uint256 | user bids count |

### userBidIndexes

```solidity
function userBidIndexes(address, uint256, uint256) external view returns (uint256)
```

User current bids

*user =&gt; orderBookEntries[poolId][bidIndex]*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |
| _1 | uint256 | undefined |
| _2 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### yieldBox

```solidity
function yieldBox() external view returns (contract YieldBox)
```

YieldBox address




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract YieldBox | undefined |



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
event Redeem(address indexed redeemer, address indexed to, uint256 indexed amount)
```

event emitted when funds are redeemed



#### Parameters

| Name | Type | Description |
|---|---|---|
| redeemer `indexed` | address | undefined |
| to `indexed` | address | undefined |
| amount `indexed` | uint256 | undefined |

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



