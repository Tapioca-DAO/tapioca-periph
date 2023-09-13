# UniUsdoToWethBidder



> Swaps USDO to WETH UniswapV2



*Performs 1 swap operation:     - USDO to Weth through UniV2*

## Methods

### claimOwnership

```solidity
function claimOwnership() external nonpayable
```

Needs to be called by `pendingOwner` to claim ownership.




### getInputAmount

```solidity
function getInputAmount(contract ISingularity singularity, uint256 tokenInId, uint256 amountOut, bytes) external view returns (uint256)
```

returns token tokenIn amount based on tokenOut amount



#### Parameters

| Name | Type | Description |
|---|---|---|
| singularity | contract ISingularity | Singularity market address |
| tokenInId | uint256 | Input token YieldBox id |
| amountOut | uint256 | Token out amount |
| _3 | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | amount out |

### getOutputAmount

```solidity
function getOutputAmount(contract ISingularity singularity, uint256 tokenInId, uint256 amountIn, bytes) external view returns (uint256)
```

returns the amount of collateral



#### Parameters

| Name | Type | Description |
|---|---|---|
| singularity | contract ISingularity | Singularity market address |
| tokenInId | uint256 | Token in YielxBox id |
| amountIn | uint256 | Stablecoin amount |
| _3 | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | input amount |

### name

```solidity
function name() external pure returns (string)
```

returns the unique name




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined |

### owner

```solidity
function owner() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### pendingOwner

```solidity
function pendingOwner() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### setUniswapSwapper

```solidity
function setUniswapSwapper(contract ISwapper _swapper) external nonpayable
```

sets the UniV2 swapper

*used for WETH to USDC swap*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _swapper | contract ISwapper | The UniV2 pool swapper address |

### swap

```solidity
function swap(contract ISingularity singularity, uint256 tokenInId, uint256 amountIn, bytes data) external nonpayable returns (uint256)
```

swaps stable to collateral



#### Parameters

| Name | Type | Description |
|---|---|---|
| singularity | contract ISingularity | Singularity market address |
| tokenInId | uint256 | Token in asset Id |
| amountIn | uint256 | Stablecoin amount |
| data | bytes | extra data used for the swap operation |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | obtained amount |

### transferOwnership

```solidity
function transferOwnership(address newOwner, bool direct, bool renounce) external nonpayable
```

Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner. Can only be invoked by the current `owner`.



#### Parameters

| Name | Type | Description |
|---|---|---|
| newOwner | address | Address of the new owner. |
| direct | bool | True if `newOwner` should be set immediately. False if `newOwner` needs to use `claimOwnership`. |
| renounce | bool | Allows the `newOwner` to be `address(0)` if `direct` and `renounce` is True. Has no effect otherwise. |

### univ2Swapper

```solidity
function univ2Swapper() external view returns (contract ISwapper)
```

UniswapV2 swapper




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract ISwapper | undefined |



## Events

### OwnershipTransferred

```solidity
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| previousOwner `indexed` | address | undefined |
| newOwner `indexed` | address | undefined |

### UniV2SwapperUpdated

```solidity
event UniV2SwapperUpdated(address indexed _old, address indexed _new)
```

event emitted when the ISwapper property is updated



#### Parameters

| Name | Type | Description |
|---|---|---|
| _old `indexed` | address | undefined |
| _new `indexed` | address | undefined |



