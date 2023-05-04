# IBidder





Used for performing swap operations when bidding on LiquidationQueue



## Methods

### getInputAmount

```solidity
function getInputAmount(address singularity, uint256 tokenInId, uint256 amountOut, bytes data) external view returns (uint256)
```

returns token tokenIn amount based on tokenOut amount



#### Parameters

| Name | Type | Description |
|---|---|---|
| singularity | address | Market to query for |
| tokenInId | uint256 | Token in asset id |
| amountOut | uint256 | Token out amount |
| data | bytes | extra data used for retrieving the ouput |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### getOutputAmount

```solidity
function getOutputAmount(address singularity, uint256 tokenInId, uint256 amountIn, bytes data) external view returns (uint256)
```

returns the amount of collateral



#### Parameters

| Name | Type | Description |
|---|---|---|
| singularity | address | Market to query for |
| tokenInId | uint256 | Token in YieldBox asset id |
| amountIn | uint256 | Token in amount |
| data | bytes | extra data used for retrieving the ouput |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### name

```solidity
function name() external view returns (string)
```

returns the unique name




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined |

### swap

```solidity
function swap(address singularity, uint256 tokenInId, uint256 amountIn, bytes data) external nonpayable returns (uint256)
```

swap USDO to collateral



#### Parameters

| Name | Type | Description |
|---|---|---|
| singularity | address | Market to swap for |
| tokenInId | uint256 | Token in asset id |
| amountIn | uint256 | Token in amount |
| data | bytes | extra data used for the swap operation |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |




