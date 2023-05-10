# ISwapper









## Methods

### buildSwapData

```solidity
function buildSwapData(address tokenIn, address tokenOut, uint256 amountIn, uint256 shareIn, bool withdrawFromYb, bool depositToYb) external view returns (struct ISwapper.SwapData)
```





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
function buildSwapData(uint256 tokenInId, uint256 tokenOutId, uint256 amountIn, uint256 shareIn, bool withdrawFromYb, bool depositToYb) external view returns (struct ISwapper.SwapData)
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

### getDefaultDexOptions

```solidity
function getDefaultDexOptions() external view returns (bytes)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes | undefined |

### getInputAmount

```solidity
function getInputAmount(ISwapper.SwapData swapData, bytes dexOptions) external view returns (uint256 amountIn)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| swapData | ISwapper.SwapData | undefined |
| dexOptions | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| amountIn | uint256 | undefined |

### getOutputAmount

```solidity
function getOutputAmount(ISwapper.SwapData swapData, bytes dexOptions) external view returns (uint256 amountOut)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| swapData | ISwapper.SwapData | undefined |
| dexOptions | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| amountOut | uint256 | undefined |

### swap

```solidity
function swap(ISwapper.SwapData swapData, uint256 amountOutMin, address to, bytes dexOptions) external nonpayable returns (uint256 amountOut, uint256 shareOut)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| swapData | ISwapper.SwapData | undefined |
| amountOutMin | uint256 | undefined |
| to | address | undefined |
| dexOptions | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| amountOut | uint256 | undefined |
| shareOut | uint256 | undefined |




