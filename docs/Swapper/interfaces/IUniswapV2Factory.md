# IUniswapV2Factory









## Methods

### allPairs

```solidity
function allPairs(uint256) external view returns (address pair)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| pair | address | undefined |

### allPairsLength

```solidity
function allPairsLength() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### createPair

```solidity
function createPair(address tokenA, address tokenB) external nonpayable returns (address pair)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenA | address | undefined |
| tokenB | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| pair | address | undefined |

### feeTo

```solidity
function feeTo() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### feeToSetter

```solidity
function feeToSetter() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### getPair

```solidity
function getPair(address tokenA, address tokenB) external view returns (address pair)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenA | address | undefined |
| tokenB | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| pair | address | undefined |

### setFeeTo

```solidity
function setFeeTo(address) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### setFeeToSetter

```solidity
function setFeeToSetter(address) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |



## Events

### PairCreated

```solidity
event PairCreated(address indexed token0, address indexed token1, address pair, uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| token0 `indexed` | address | undefined |
| token1 `indexed` | address | undefined |
| pair  | address | undefined |
| _3  | uint256 | undefined |



