# IGmxGlpManager









## Methods

### BASIS_POINTS_DIVISOR

```solidity
function BASIS_POINTS_DIVISOR() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### GLP_PRECISION

```solidity
function GLP_PRECISION() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### MAX_COOLDOWN_DURATION

```solidity
function MAX_COOLDOWN_DURATION() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### PRICE_PRECISION

```solidity
function PRICE_PRECISION() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### USDG_DECIMALS

```solidity
function USDG_DECIMALS() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### addLiquidity

```solidity
function addLiquidity(address _token, uint256 _amount, uint256 _minUsdg, uint256 _minGlp) external nonpayable returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _token | address | undefined |
| _amount | uint256 | undefined |
| _minUsdg | uint256 | undefined |
| _minGlp | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### addLiquidityForAccount

```solidity
function addLiquidityForAccount(address _fundingAccount, address _account, address _token, uint256 _amount, uint256 _minUsdg, uint256 _minGlp) external nonpayable returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _fundingAccount | address | undefined |
| _account | address | undefined |
| _token | address | undefined |
| _amount | uint256 | undefined |
| _minUsdg | uint256 | undefined |
| _minGlp | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### aumAddition

```solidity
function aumAddition() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### aumDeduction

```solidity
function aumDeduction() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### cooldownDuration

```solidity
function cooldownDuration() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### getAum

```solidity
function getAum(bool maximise) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| maximise | bool | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### getAumInUsdg

```solidity
function getAumInUsdg(bool maximise) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| maximise | bool | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### getAums

```solidity
function getAums() external view returns (uint256[])
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256[] | undefined |

### getGlobalShortAveragePrice

```solidity
function getGlobalShortAveragePrice(address _token) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _token | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### getGlobalShortDelta

```solidity
function getGlobalShortDelta(address _token, uint256 _price, uint256 _size) external view returns (uint256, bool)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _token | address | undefined |
| _price | uint256 | undefined |
| _size | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |
| _1 | bool | undefined |

### getPrice

```solidity
function getPrice(bool _maximise) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _maximise | bool | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### glp

```solidity
function glp() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### gov

```solidity
function gov() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### inPrivateMode

```solidity
function inPrivateMode() external view returns (bool)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### isHandler

```solidity
function isHandler(address) external view returns (bool)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### lastAddedAt

```solidity
function lastAddedAt(address) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### removeLiquidity

```solidity
function removeLiquidity(address _tokenOut, uint256 _glpAmount, uint256 _minOut, address _receiver) external nonpayable returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _tokenOut | address | undefined |
| _glpAmount | uint256 | undefined |
| _minOut | uint256 | undefined |
| _receiver | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### removeLiquidityForAccount

```solidity
function removeLiquidityForAccount(address _account, address _tokenOut, uint256 _glpAmount, uint256 _minOut, address _receiver) external nonpayable returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _account | address | undefined |
| _tokenOut | address | undefined |
| _glpAmount | uint256 | undefined |
| _minOut | uint256 | undefined |
| _receiver | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### setAumAdjustment

```solidity
function setAumAdjustment(uint256 _aumAddition, uint256 _aumDeduction) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _aumAddition | uint256 | undefined |
| _aumDeduction | uint256 | undefined |

### setCooldownDuration

```solidity
function setCooldownDuration(uint256 _cooldownDuration) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _cooldownDuration | uint256 | undefined |

### setGov

```solidity
function setGov(address _gov) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _gov | address | undefined |

### setHandler

```solidity
function setHandler(address _handler, bool _isActive) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _handler | address | undefined |
| _isActive | bool | undefined |

### setInPrivateMode

```solidity
function setInPrivateMode(bool _inPrivateMode) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _inPrivateMode | bool | undefined |

### setShortsTracker

```solidity
function setShortsTracker(address _shortsTracker) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _shortsTracker | address | undefined |

### setShortsTrackerAveragePriceWeight

```solidity
function setShortsTrackerAveragePriceWeight(uint256 _shortsTrackerAveragePriceWeight) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _shortsTrackerAveragePriceWeight | uint256 | undefined |

### shortsTracker

```solidity
function shortsTracker() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### shortsTrackerAveragePriceWeight

```solidity
function shortsTrackerAveragePriceWeight() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### usdg

```solidity
function usdg() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### vault

```solidity
function vault() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |



## Events

### AddLiquidity

```solidity
event AddLiquidity(address account, address token, uint256 amount, uint256 aumInUsdg, uint256 glpSupply, uint256 usdgAmount, uint256 mintAmount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| account  | address | undefined |
| token  | address | undefined |
| amount  | uint256 | undefined |
| aumInUsdg  | uint256 | undefined |
| glpSupply  | uint256 | undefined |
| usdgAmount  | uint256 | undefined |
| mintAmount  | uint256 | undefined |

### RemoveLiquidity

```solidity
event RemoveLiquidity(address account, address token, uint256 glpAmount, uint256 aumInUsdg, uint256 glpSupply, uint256 usdgAmount, uint256 amountOut)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| account  | address | undefined |
| token  | address | undefined |
| glpAmount  | uint256 | undefined |
| aumInUsdg  | uint256 | undefined |
| glpSupply  | uint256 | undefined |
| usdgAmount  | uint256 | undefined |
| amountOut  | uint256 | undefined |



