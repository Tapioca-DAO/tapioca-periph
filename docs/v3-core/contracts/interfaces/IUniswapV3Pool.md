# IUniswapV3Pool



> The interface for a Uniswap V3 Pool

A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform to the ERC20 specification

*The pool interface is broken up into many smaller pieces*

## Methods

### burn

```solidity
function burn(int24 tickLower, int24 tickUpper, uint128 amount) external nonpayable returns (uint256 amount0, uint256 amount1)
```

Burn liquidity from the sender and account tokens owed for the liquidity to the position

*Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0Fees must be collected separately via a call to #collect*

#### Parameters

| Name | Type | Description |
|---|---|---|
| tickLower | int24 | The lower tick of the position for which to burn liquidity |
| tickUpper | int24 | The upper tick of the position for which to burn liquidity |
| amount | uint128 | How much liquidity to burn |

#### Returns

| Name | Type | Description |
|---|---|---|
| amount0 | uint256 | The amount of token0 sent to the recipient |
| amount1 | uint256 | The amount of token1 sent to the recipient |

### collect

```solidity
function collect(address recipient, int24 tickLower, int24 tickUpper, uint128 amount0Requested, uint128 amount1Requested) external nonpayable returns (uint128 amount0, uint128 amount1)
```

Collects tokens owed to a position

*Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity. Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| recipient | address | The address which should receive the fees collected |
| tickLower | int24 | The lower tick of the position for which to collect fees |
| tickUpper | int24 | The upper tick of the position for which to collect fees |
| amount0Requested | uint128 | How much token0 should be withdrawn from the fees owed |
| amount1Requested | uint128 | How much token1 should be withdrawn from the fees owed |

#### Returns

| Name | Type | Description |
|---|---|---|
| amount0 | uint128 | The amount of fees collected in token0 |
| amount1 | uint128 | The amount of fees collected in token1 |

### collectProtocol

```solidity
function collectProtocol(address recipient, uint128 amount0Requested, uint128 amount1Requested) external nonpayable returns (uint128 amount0, uint128 amount1)
```

Collect the protocol fee accrued to the pool



#### Parameters

| Name | Type | Description |
|---|---|---|
| recipient | address | The address to which collected protocol fees should be sent |
| amount0Requested | uint128 | The maximum amount of token0 to send, can be 0 to collect fees in only token1 |
| amount1Requested | uint128 | The maximum amount of token1 to send, can be 0 to collect fees in only token0 |

#### Returns

| Name | Type | Description |
|---|---|---|
| amount0 | uint128 | The protocol fee collected in token0 |
| amount1 | uint128 | The protocol fee collected in token1 |

### factory

```solidity
function factory() external view returns (address)
```

The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | The contract address |

### fee

```solidity
function fee() external view returns (uint24)
```

The pool&#39;s fee in hundredths of a bip, i.e. 1e-6




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint24 | The fee |

### feeGrowthGlobal0X128

```solidity
function feeGrowthGlobal0X128() external view returns (uint256)
```

The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool

*This value can overflow the uint256*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### feeGrowthGlobal1X128

```solidity
function feeGrowthGlobal1X128() external view returns (uint256)
```

The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool

*This value can overflow the uint256*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### flash

```solidity
function flash(address recipient, uint256 amount0, uint256 amount1, bytes data) external nonpayable
```

Receive token0 and/or token1 and pay it back, plus a fee, in the callback

*The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallbackCan be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling with 0 amount{0,1} and sending the donation amount(s) from the callback*

#### Parameters

| Name | Type | Description |
|---|---|---|
| recipient | address | The address which will receive the token0 and token1 amounts |
| amount0 | uint256 | The amount of token0 to send |
| amount1 | uint256 | The amount of token1 to send |
| data | bytes | Any data to be passed through to the callback |

### increaseObservationCardinalityNext

```solidity
function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external nonpayable
```

Increase the maximum number of price and liquidity observations that this pool will store

*This method is no-op if the pool already has an observationCardinalityNext greater than or equal to the input observationCardinalityNext.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| observationCardinalityNext | uint16 | The desired minimum number of observations for the pool to store |

### initialize

```solidity
function initialize(uint160 sqrtPriceX96) external nonpayable
```

Sets the initial price for the pool

*Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value*

#### Parameters

| Name | Type | Description |
|---|---|---|
| sqrtPriceX96 | uint160 | the initial sqrt price of the pool as a Q64.96 |

### liquidity

```solidity
function liquidity() external view returns (uint128)
```

The currently in range liquidity available to the pool

*This value has no relationship to the total liquidity across all ticks*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint128 | undefined |

### maxLiquidityPerTick

```solidity
function maxLiquidityPerTick() external view returns (uint128)
```

The maximum amount of position liquidity that can use any tick in the range

*This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint128 | The max amount of liquidity per tick |

### mint

```solidity
function mint(address recipient, int24 tickLower, int24 tickUpper, uint128 amount, bytes data) external nonpayable returns (uint256 amount0, uint256 amount1)
```

Adds liquidity for the given recipient/tickLower/tickUpper position

*The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends on tickLower, tickUpper, the amount of liquidity, and the current price.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| recipient | address | The address for which the liquidity will be created |
| tickLower | int24 | The lower tick of the position in which to add liquidity |
| tickUpper | int24 | The upper tick of the position in which to add liquidity |
| amount | uint128 | The amount of liquidity to mint |
| data | bytes | Any data that should be passed through to the callback |

#### Returns

| Name | Type | Description |
|---|---|---|
| amount0 | uint256 | The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback |
| amount1 | uint256 | The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback |

### observations

```solidity
function observations(uint256 index) external view returns (uint32 blockTimestamp, int56 tickCumulative, uint160 secondsPerLiquidityCumulativeX128, bool initialized)
```

Returns data about a specific observation index

*You most likely want to use #observe() instead of this method to get an observation as of some amount of time ago, rather than at a specific index in the array.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| index | uint256 | The element of the observations array to fetch |

#### Returns

| Name | Type | Description |
|---|---|---|
| blockTimestamp | uint32 | The timestamp of the observation, Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp, Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp, Returns initialized whether the observation has been initialized and the values are safe to use |
| tickCumulative | int56 | undefined |
| secondsPerLiquidityCumulativeX128 | uint160 | undefined |
| initialized | bool | undefined |

### observe

```solidity
function observe(uint32[] secondsAgos) external view returns (int56[] tickCumulatives, uint160[] secondsPerLiquidityCumulativeX128s)
```

Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp

*To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick, you must call it with secondsAgos = [3600, 0].The time weighted average tick represents the geometric time weighted average price of the pool, in log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| secondsAgos | uint32[] | From how long ago each cumulative tick and liquidity value should be returned |

#### Returns

| Name | Type | Description |
|---|---|---|
| tickCumulatives | int56[] | Cumulative tick values as of each `secondsAgos` from the current block timestamp |
| secondsPerLiquidityCumulativeX128s | uint160[] | Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block timestamp |

### positions

```solidity
function positions(bytes32 key) external view returns (uint128 _liquidity, uint256 feeGrowthInside0LastX128, uint256 feeGrowthInside1LastX128, uint128 tokensOwed0, uint128 tokensOwed1)
```

Returns the information about a position by the position&#39;s key



#### Parameters

| Name | Type | Description |
|---|---|---|
| key | bytes32 | The position&#39;s key is a hash of a preimage composed by the owner, tickLower and tickUpper |

#### Returns

| Name | Type | Description |
|---|---|---|
| _liquidity | uint128 | The amount of liquidity in the position, Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke, Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke, Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke, Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke |
| feeGrowthInside0LastX128 | uint256 | undefined |
| feeGrowthInside1LastX128 | uint256 | undefined |
| tokensOwed0 | uint128 | undefined |
| tokensOwed1 | uint128 | undefined |

### protocolFees

```solidity
function protocolFees() external view returns (uint128 token0, uint128 token1)
```

The amounts of token0 and token1 that are owed to the protocol

*Protocol fees will never exceed uint128 max in either token*


#### Returns

| Name | Type | Description |
|---|---|---|
| token0 | uint128 | undefined |
| token1 | uint128 | undefined |

### setFeeProtocol

```solidity
function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external nonpayable
```

Set the denominator of the protocol&#39;s % share of the fees



#### Parameters

| Name | Type | Description |
|---|---|---|
| feeProtocol0 | uint8 | new protocol fee for token0 of the pool |
| feeProtocol1 | uint8 | new protocol fee for token1 of the pool |

### slot0

```solidity
function slot0() external view returns (uint160 sqrtPriceX96, int24 tick, uint16 observationIndex, uint16 observationCardinality, uint16 observationCardinalityNext, uint8 feeProtocol, bool unlocked)
```

The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas when accessed externally.




#### Returns

| Name | Type | Description |
|---|---|---|
| sqrtPriceX96 | uint160 | The current price of the pool as a sqrt(token1/token0) Q64.96 value tick The current tick of the pool, i.e. according to the last tick transition that was run. This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick boundary. observationIndex The index of the last oracle observation that was written, observationCardinality The current maximum number of observations stored in the pool, observationCardinalityNext The next maximum number of observations, to be updated when the observation. feeProtocol The protocol fee for both tokens of the pool. Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0 is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee. unlocked Whether the pool is currently locked to reentrancy |
| tick | int24 | undefined |
| observationIndex | uint16 | undefined |
| observationCardinality | uint16 | undefined |
| observationCardinalityNext | uint16 | undefined |
| feeProtocol | uint8 | undefined |
| unlocked | bool | undefined |

### snapshotCumulativesInside

```solidity
function snapshotCumulativesInside(int24 tickLower, int24 tickUpper) external view returns (int56 tickCumulativeInside, uint160 secondsPerLiquidityInsideX128, uint32 secondsInside)
```

Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range

*Snapshots must only be compared to other snapshots, taken over a period for which a position existed. I.e., snapshots cannot be compared if a position is not held for the entire period between when the first snapshot is taken and the second snapshot is taken.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| tickLower | int24 | The lower tick of the range |
| tickUpper | int24 | The upper tick of the range |

#### Returns

| Name | Type | Description |
|---|---|---|
| tickCumulativeInside | int56 | The snapshot of the tick accumulator for the range |
| secondsPerLiquidityInsideX128 | uint160 | The snapshot of seconds per liquidity for the range |
| secondsInside | uint32 | The snapshot of seconds per liquidity for the range |

### swap

```solidity
function swap(address recipient, bool zeroForOne, int256 amountSpecified, uint160 sqrtPriceLimitX96, bytes data) external nonpayable returns (int256 amount0, int256 amount1)
```

Swap token0 for token1, or token1 for token0

*The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback*

#### Parameters

| Name | Type | Description |
|---|---|---|
| recipient | address | The address to receive the output of the swap |
| zeroForOne | bool | The direction of the swap, true for token0 to token1, false for token1 to token0 |
| amountSpecified | int256 | The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative) |
| sqrtPriceLimitX96 | uint160 | The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this value after the swap. If one for zero, the price cannot be greater than this value after the swap |
| data | bytes | Any data to be passed through to the callback |

#### Returns

| Name | Type | Description |
|---|---|---|
| amount0 | int256 | The delta of the balance of token0 of the pool, exact when negative, minimum when positive |
| amount1 | int256 | The delta of the balance of token1 of the pool, exact when negative, minimum when positive |

### tickBitmap

```solidity
function tickBitmap(int16 wordPosition) external view returns (uint256)
```

Returns 256 packed tick initialized boolean values. See TickBitmap for more information



#### Parameters

| Name | Type | Description |
|---|---|---|
| wordPosition | int16 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### tickSpacing

```solidity
function tickSpacing() external view returns (int24)
```

The pool tick spacing

*Ticks can only be used at multiples of this value, minimum of 1 and always positive e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ... This value is an int24 to avoid casting even though it is always positive.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | int24 | The tick spacing |

### ticks

```solidity
function ticks(int24 tick) external view returns (uint128 liquidityGross, int128 liquidityNet, uint256 feeGrowthOutside0X128, uint256 feeGrowthOutside1X128, int56 tickCumulativeOutside, uint160 secondsPerLiquidityOutsideX128, uint32 secondsOutside, bool initialized)
```

Look up information about a specific tick in the pool



#### Parameters

| Name | Type | Description |
|---|---|---|
| tick | int24 | The tick to look up |

#### Returns

| Name | Type | Description |
|---|---|---|
| liquidityGross | uint128 | the total amount of position liquidity that uses the pool either as tick lower or tick upper, liquidityNet how much liquidity changes when the pool price crosses the tick, feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0, feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1, tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick, secondsOutside the seconds spent on the other side of the tick from the current tick, initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false. Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0. In addition, these values are only relative and must be used only in comparison to previous snapshots for a specific position. |
| liquidityNet | int128 | undefined |
| feeGrowthOutside0X128 | uint256 | undefined |
| feeGrowthOutside1X128 | uint256 | undefined |
| tickCumulativeOutside | int56 | undefined |
| secondsPerLiquidityOutsideX128 | uint160 | undefined |
| secondsOutside | uint32 | undefined |
| initialized | bool | undefined |

### token0

```solidity
function token0() external view returns (address)
```

The first of the two tokens of the pool, sorted by address




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | The token contract address |

### token1

```solidity
function token1() external view returns (address)
```

The second of the two tokens of the pool, sorted by address




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | The token contract address |



## Events

### Burn

```solidity
event Burn(address indexed owner, int24 indexed tickLower, int24 indexed tickUpper, uint128 amount, uint256 amount0, uint256 amount1)
```

Emitted when a position&#39;s liquidity is removed

*Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect*

#### Parameters

| Name | Type | Description |
|---|---|---|
| owner `indexed` | address | The owner of the position for which liquidity is removed |
| tickLower `indexed` | int24 | The lower tick of the position |
| tickUpper `indexed` | int24 | The upper tick of the position |
| amount  | uint128 | The amount of liquidity to remove |
| amount0  | uint256 | The amount of token0 withdrawn |
| amount1  | uint256 | The amount of token1 withdrawn |

### Collect

```solidity
event Collect(address indexed owner, address recipient, int24 indexed tickLower, int24 indexed tickUpper, uint128 amount0, uint128 amount1)
```

Emitted when fees are collected by the owner of a position

*Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees*

#### Parameters

| Name | Type | Description |
|---|---|---|
| owner `indexed` | address | The owner of the position for which fees are collected |
| recipient  | address | undefined |
| tickLower `indexed` | int24 | The lower tick of the position |
| tickUpper `indexed` | int24 | The upper tick of the position |
| amount0  | uint128 | The amount of token0 fees collected |
| amount1  | uint128 | The amount of token1 fees collected |

### CollectProtocol

```solidity
event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1)
```

Emitted when the collected protocol fees are withdrawn by the factory owner



#### Parameters

| Name | Type | Description |
|---|---|---|
| sender `indexed` | address | The address that collects the protocol fees |
| recipient `indexed` | address | The address that receives the collected protocol fees |
| amount0  | uint128 | The amount of token1 protocol fees that is withdrawn |
| amount1  | uint128 | undefined |

### Flash

```solidity
event Flash(address indexed sender, address indexed recipient, uint256 amount0, uint256 amount1, uint256 paid0, uint256 paid1)
```

Emitted by the pool for any flashes of token0/token1



#### Parameters

| Name | Type | Description |
|---|---|---|
| sender `indexed` | address | The address that initiated the swap call, and that received the callback |
| recipient `indexed` | address | The address that received the tokens from flash |
| amount0  | uint256 | The amount of token0 that was flashed |
| amount1  | uint256 | The amount of token1 that was flashed |
| paid0  | uint256 | The amount of token0 paid for the flash, which can exceed the amount0 plus the fee |
| paid1  | uint256 | The amount of token1 paid for the flash, which can exceed the amount1 plus the fee |

### IncreaseObservationCardinalityNext

```solidity
event IncreaseObservationCardinalityNext(uint16 observationCardinalityNextOld, uint16 observationCardinalityNextNew)
```

Emitted by the pool for increases to the number of observations that can be stored

*observationCardinalityNext is not the observation cardinality until an observation is written at the index just before a mint/swap/burn.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| observationCardinalityNextOld  | uint16 | The previous value of the next observation cardinality |
| observationCardinalityNextNew  | uint16 | The updated value of the next observation cardinality |

### Initialize

```solidity
event Initialize(uint160 sqrtPriceX96, int24 tick)
```

Emitted exactly once by a pool when #initialize is first called on the pool

*Mint/Burn/Swap cannot be emitted by the pool before Initialize*

#### Parameters

| Name | Type | Description |
|---|---|---|
| sqrtPriceX96  | uint160 | The initial sqrt price of the pool, as a Q64.96 |
| tick  | int24 | The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool |

### Mint

```solidity
event Mint(address sender, address indexed owner, int24 indexed tickLower, int24 indexed tickUpper, uint128 amount, uint256 amount0, uint256 amount1)
```

Emitted when liquidity is minted for a given position



#### Parameters

| Name | Type | Description |
|---|---|---|
| sender  | address | The address that minted the liquidity |
| owner `indexed` | address | The owner of the position and recipient of any minted liquidity |
| tickLower `indexed` | int24 | The lower tick of the position |
| tickUpper `indexed` | int24 | The upper tick of the position |
| amount  | uint128 | The amount of liquidity minted to the position range |
| amount0  | uint256 | How much token0 was required for the minted liquidity |
| amount1  | uint256 | How much token1 was required for the minted liquidity |

### SetFeeProtocol

```solidity
event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New)
```

Emitted when the protocol fee is changed by the pool



#### Parameters

| Name | Type | Description |
|---|---|---|
| feeProtocol0Old  | uint8 | The previous value of the token0 protocol fee |
| feeProtocol1Old  | uint8 | The previous value of the token1 protocol fee |
| feeProtocol0New  | uint8 | The updated value of the token0 protocol fee |
| feeProtocol1New  | uint8 | The updated value of the token1 protocol fee |

### Swap

```solidity
event Swap(address indexed sender, address indexed recipient, int256 amount0, int256 amount1, uint160 sqrtPriceX96, uint128 liquidity, int24 tick)
```

Emitted by the pool for any swaps between token0 and token1



#### Parameters

| Name | Type | Description |
|---|---|---|
| sender `indexed` | address | The address that initiated the swap call, and that received the callback |
| recipient `indexed` | address | The address that received the output of the swap |
| amount0  | int256 | The delta of the token0 balance of the pool |
| amount1  | int256 | The delta of the token1 balance of the pool |
| sqrtPriceX96  | uint160 | The sqrt(price) of the pool after the swap, as a Q64.96 |
| liquidity  | uint128 | The liquidity of the pool after the swap |
| tick  | int24 | The log base 1.0001 of price of the pool after the swap |



