# CurveStableToUsdoBidder



> Swaps Stable to USDO through Curve



*Performs a swap operation between stable and USDO through 3CRV+USDO pool*

## Methods

### claimOwnership

```solidity
function claimOwnership() external nonpayable
```

Needs to be called by `pendingOwner` to claim ownership.




### curveSwapper

```solidity
function curveSwapper() external view returns (contract ICurveSwapper)
```

3Crv+USDO swapper




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract ICurveSwapper | undefined |

### getInputAmount

```solidity
function getInputAmount(contract ISingularity singularity, uint256 tokenInId, uint256 amountOut, bytes) external view returns (uint256)
```

returns token tokenIn amount based on tokenOut amount



#### Parameters

| Name | Type | Description |
|---|---|---|
| singularity | contract ISingularity | Singularity market address |
| tokenInId | uint256 | Token in YielxBox id |
| amountOut | uint256 | Token out amount |
| _3 | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | input amount |

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
| _0 | uint256 | output amount |

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

### setCurveSwapper

```solidity
function setCurveSwapper(contract ICurveSwapper _swapper) external nonpayable
```

sets the Curve swapper

*used for USDO to WETH swap*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _swapper | contract ICurveSwapper | The curve pool swapper address |

### swap

```solidity
function swap(contract ISingularity singularity, uint256 tokenInId, uint256 amountIn, bytes data) external nonpayable returns (uint256)
```

swaps stable to collateral



#### Parameters

| Name | Type | Description |
|---|---|---|
| singularity | contract ISingularity | Singularity market address |
| tokenInId | uint256 | Stablecoin asset id |
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



## Events

### CurveSwapperUpdated

```solidity
event CurveSwapperUpdated(address indexed _old, address indexed _new)
```

event emitted when the ISwapper property is updated



#### Parameters

| Name | Type | Description |
|---|---|---|
| _old `indexed` | address | undefined |
| _new `indexed` | address | undefined |

### OwnershipTransferred

```solidity
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| previousOwner `indexed` | address | undefined |
| newOwner `indexed` | address | undefined |



