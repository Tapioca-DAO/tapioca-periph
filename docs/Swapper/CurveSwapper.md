# CurveSwapper



> Curve pool swapper





## Methods

### curvePool

```solidity
function curvePool() external view returns (contract ICurvePool)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract ICurvePool | undefined |

### getInputAmount

```solidity
function getInputAmount(uint256, uint256, bytes) external pure returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |
| _1 | uint256 | undefined |
| _2 | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### getOutputAmount

```solidity
function getOutputAmount(uint256 tokenInId, uint256 shareIn, bytes dexData) external view returns (uint256 amountOut)
```

returns the possible output amount for input share



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



