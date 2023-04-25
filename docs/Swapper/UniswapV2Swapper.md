# UniswapV2Swapper









## Methods

### buildSwapData

```solidity
function buildSwapData(address tokenIn, address tokenOut, uint256 amountIn, uint256 shareIn, bool withdrawFromYb, bool depositToYb) external pure returns (struct ISwapper.SwapData)
```

*** VIEW METHODS *** ***  ***



#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenIn | address | undefined |
| tokenOut | address | undefined |
| amountIn | uint256 | undefined |
| shareIn | uint256 | undefined |
| withdrawFromYb | bool | undefined |
| depositToYb | bool | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | ISwapper.SwapData | undefined |

### buildSwapData

```solidity
function buildSwapData(uint256 tokenInId, uint256 tokenOutId, uint256 amountIn, uint256 shareIn, bool withdrawFromYb, bool depositToYb) external pure returns (struct ISwapper.SwapData)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenInId | uint256 | undefined |
| tokenOutId | uint256 | undefined |
| amountIn | uint256 | undefined |
| shareIn | uint256 | undefined |
| withdrawFromYb | bool | undefined |
| depositToYb | bool | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | ISwapper.SwapData | undefined |

### factory

```solidity
function factory() external view returns (contract IUniswapV2Factory)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract IUniswapV2Factory | undefined |

### getDefaultDexOptions

```solidity
function getDefaultDexOptions() external view returns (bytes)
```

*** VIEW METHODS *** ***  ***returns default bytes swap data




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes | undefined |

### getInputAmount

```solidity
function getInputAmount(ISwapper.SwapData swapData, bytes) external view returns (uint256 amountIn)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| swapData | ISwapper.SwapData | undefined |
| _1 | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| amountIn | uint256 | undefined |

### getOutputAmount

```solidity
function getOutputAmount(ISwapper.SwapData swapData, bytes) external view returns (uint256 amountOut)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| swapData | ISwapper.SwapData | undefined |
| _1 | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| amountOut | uint256 | undefined |

### owner

```solidity
function owner() external view returns (address)
```



*Returns the address of the current owner.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### renounceOwnership

```solidity
function renounceOwnership() external nonpayable
```



*Leaves the contract without owner. It will not be possible to call `onlyOwner` functions anymore. Can only be called by the current owner. NOTE: Renouncing ownership will leave the contract without an owner, thereby removing any functionality that is only available to the owner.*


### swap

```solidity
function swap(ISwapper.SwapData swapData, uint256 amountOutMin, address to, bytes data) external nonpayable returns (uint256 amountOut, uint256 shareOut)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| swapData | ISwapper.SwapData | undefined |
| amountOutMin | uint256 | undefined |
| to | address | undefined |
| data | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| amountOut | uint256 | undefined |
| shareOut | uint256 | undefined |

### swapRouter

```solidity
function swapRouter() external view returns (contract IUniswapV2Router02)
```

*** VARS *** ***  ***




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract IUniswapV2Router02 | undefined |

### transferOwnership

```solidity
function transferOwnership(address newOwner) external nonpayable
```



*Transfers ownership of the contract to a new account (`newOwner`). Can only be called by the current owner.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newOwner | address | undefined |

### yieldBox

```solidity
function yieldBox() external view returns (contract IYieldBox)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract IYieldBox | undefined |



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



## Errors

### AddressNotValid

```solidity
error AddressNotValid()
```

*** ERRORS *** ***  ***





