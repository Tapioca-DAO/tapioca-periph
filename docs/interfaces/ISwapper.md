# ISwapper









## Methods

### getInputAmount

```solidity
function getInputAmount(uint256 tokenOutId, uint256 shareOut, bytes dexData) external view returns (uint256 amountIn)
```

returns necessary input amount for a fixed output amount

*dexData examples:     - for UniV2, it should contain address[] swapPath*

#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenOutId | uint256 | YieldBox asset id |
| shareOut | uint256 | Shares out to compute the amount for |
| dexData | bytes | Custom DEX data for query execution |

#### Returns

| Name | Type | Description |
|---|---|---|
| amountIn | uint256 | undefined |

### getOutputAmount

```solidity
function getOutputAmount(uint256 tokenInId, uint256 shareIn, bytes dexData) external view returns (uint256 amountOut)
```

returns the possible output amount for input share

*dexData examples:     - for UniV2, it should contain address[] swapPath     - for Curve, it should contain uint256[] tokenIndexes*

#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenInId | uint256 | YieldBox asset id |
| shareIn | uint256 | Shares to get the amount for |
| dexData | bytes | Custom DEX data for query execution |

#### Returns

| Name | Type | Description |
|---|---|---|
| amountOut | uint256 | undefined |

### swap

```solidity
function swap(uint256 tokenInId, uint256 tokenOutId, uint256 shareIn, address to, uint256 amountOutMin, bytes dexData) external nonpayable returns (uint256 amountOut, uint256 shareOut)
```

swaps token in with token out

*returns both amount and sharesdexData examples:     - for UniV2, it should contain address[] swapPath     - for Curve, it should contain uint256[] tokenIndexes*

#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenInId | uint256 | YieldBox asset id |
| tokenOutId | uint256 | YieldBox asset id |
| shareIn | uint256 | Shares to be swapped |
| to | address | Receiver address |
| amountOutMin | uint256 | Minimum amount to be received |
| dexData | bytes | Custom DEX data for query execution |

#### Returns

| Name | Type | Description |
|---|---|---|
| amountOut | uint256 | undefined |
| shareOut | uint256 | undefined |




