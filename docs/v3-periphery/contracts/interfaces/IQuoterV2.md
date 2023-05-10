# IQuoterV2



> QuoterV2 Interface

Supports quoting the calculated amounts from exact input or exact output swaps.For each pool also tells you the number of initialized ticks crossed and the sqrt price of the pool after the swap.

*These functions are not marked view because they rely on calling non-view functions and reverting to compute the result. They are also not gas efficient and should not be called on-chain.*

## Methods

### quoteExactInput

```solidity
function quoteExactInput(bytes path, uint256 amountIn) external nonpayable returns (uint256 amountOut, uint160[] sqrtPriceX96AfterList, uint32[] initializedTicksCrossedList, uint256 gasEstimate)
```

Returns the amount out received for a given exact input swap without executing the swap



#### Parameters

| Name | Type | Description |
|---|---|---|
| path | bytes | The path of the swap, i.e. each token pair and the pool fee |
| amountIn | uint256 | The amount of the first token to swap |

#### Returns

| Name | Type | Description |
|---|---|---|
| amountOut | uint256 | The amount of the last token that would be received |
| sqrtPriceX96AfterList | uint160[] | List of the sqrt price after the swap for each pool in the path |
| initializedTicksCrossedList | uint32[] | List of the initialized ticks that the swap crossed for each pool in the path |
| gasEstimate | uint256 | The estimate of the gas that the swap consumes |

### quoteExactInputSingle

```solidity
function quoteExactInputSingle(IQuoterV2.QuoteExactInputSingleParams params) external nonpayable returns (uint256 amountOut, uint160 sqrtPriceX96After, uint32 initializedTicksCrossed, uint256 gasEstimate)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| params | IQuoterV2.QuoteExactInputSingleParams | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| amountOut | uint256 | undefined |
| sqrtPriceX96After | uint160 | undefined |
| initializedTicksCrossed | uint32 | undefined |
| gasEstimate | uint256 | undefined |

### quoteExactOutput

```solidity
function quoteExactOutput(bytes path, uint256 amountOut) external nonpayable returns (uint256 amountIn, uint160[] sqrtPriceX96AfterList, uint32[] initializedTicksCrossedList, uint256 gasEstimate)
```

Returns the amount in required for a given exact output swap without executing the swap



#### Parameters

| Name | Type | Description |
|---|---|---|
| path | bytes | The path of the swap, i.e. each token pair and the pool fee. Path must be provided in reverse order |
| amountOut | uint256 | The amount of the last token to receive |

#### Returns

| Name | Type | Description |
|---|---|---|
| amountIn | uint256 | The amount of first token required to be paid |
| sqrtPriceX96AfterList | uint160[] | List of the sqrt price after the swap for each pool in the path |
| initializedTicksCrossedList | uint32[] | List of the initialized ticks that the swap crossed for each pool in the path |
| gasEstimate | uint256 | The estimate of the gas that the swap consumes |

### quoteExactOutputSingle

```solidity
function quoteExactOutputSingle(IQuoterV2.QuoteExactOutputSingleParams params) external nonpayable returns (uint256 amountIn, uint160 sqrtPriceX96After, uint32 initializedTicksCrossed, uint256 gasEstimate)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| params | IQuoterV2.QuoteExactOutputSingleParams | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| amountIn | uint256 | undefined |
| sqrtPriceX96After | uint160 | undefined |
| initializedTicksCrossed | uint32 | undefined |
| gasEstimate | uint256 | undefined |




