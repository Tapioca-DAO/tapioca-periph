# ISingularity









## Methods

### accrueInfo

```solidity
function accrueInfo() external view returns (uint64 interestPerSecond, uint64 lastBlockAccrued, uint128 feesEarnedFraction)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| interestPerSecond | uint64 | undefined |
| lastBlockAccrued | uint64 | undefined |
| feesEarnedFraction | uint128 | undefined |

### addAsset

```solidity
function addAsset(address from, address to, bool skim, uint256 share) external nonpayable returns (uint256 fraction)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| from | address | undefined |
| to | address | undefined |
| skim | bool | undefined |
| share | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| fraction | uint256 | undefined |

### addCollateral

```solidity
function addCollateral(address from, address to, bool skim, uint256 amount, uint256 share) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| from | address | undefined |
| to | address | undefined |
| skim | bool | undefined |
| amount | uint256 | undefined |
| share | uint256 | undefined |

### allowance

```solidity
function allowance(address, address) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |
| _1 | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### approve

```solidity
function approve(address spender, uint256 amount) external nonpayable returns (bool)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| spender | address | undefined |
| amount | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### asset

```solidity
function asset() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### assetId

```solidity
function assetId() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### balanceOf

```solidity
function balanceOf(address) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### borrow

```solidity
function borrow(address from, address to, uint256 amount) external nonpayable returns (uint256 part, uint256 share)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| from | address | undefined |
| to | address | undefined |
| amount | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| part | uint256 | undefined |
| share | uint256 | undefined |

### buyCollateral

```solidity
function buyCollateral(address from, uint256 borrowAmount, uint256 supplyAmount, uint256 minAmountOut, address swapper, bytes dexData) external nonpayable returns (uint256 amountOut)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| from | address | undefined |
| borrowAmount | uint256 | undefined |
| supplyAmount | uint256 | undefined |
| minAmountOut | uint256 | undefined |
| swapper | address | undefined |
| dexData | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| amountOut | uint256 | undefined |

### collateral

```solidity
function collateral() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### collateralId

```solidity
function collateralId() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### collateralizationRate

```solidity
function collateralizationRate() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### computeAllowedLendShare

```solidity
function computeAllowedLendShare(uint256 amount, uint256 tokenId) external view returns (uint256 share)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| amount | uint256 | undefined |
| tokenId | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| share | uint256 | undefined |

### exchangeRate

```solidity
function exchangeRate() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### execute

```solidity
function execute(bytes[] calls, bool revertOnFail) external nonpayable returns (bool[] successes, string[] results)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| calls | bytes[] | undefined |
| revertOnFail | bool | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| successes | bool[] | undefined |
| results | string[] | undefined |

### getInterestDetails

```solidity
function getInterestDetails() external view returns (struct ISingularity.AccrueInfo _accrueInfo, uint256 utilization)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _accrueInfo | ISingularity.AccrueInfo | undefined |
| utilization | uint256 | undefined |

### interestElasticity

```solidity
function interestElasticity() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### liquidationMultiplier

```solidity
function liquidationMultiplier() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### liquidationQueue

```solidity
function liquidationQueue() external view returns (address payable)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address payable | undefined |

### maximumInterestPerSecond

```solidity
function maximumInterestPerSecond() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### maximumTargetUtilization

```solidity
function maximumTargetUtilization() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### minimumInterestPerSecond

```solidity
function minimumInterestPerSecond() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### minimumTargetUtilization

```solidity
function minimumTargetUtilization() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### multiHopBuyCollateral

```solidity
function multiHopBuyCollateral(address from, uint256 collateralAmount, uint256 borrowAmount, bool useAirdroppedFunds, IUSDOBase.ILeverageSwapData swapData, IUSDOBase.ILeverageLZData lzData, IUSDOBase.ILeverageExternalContractsData externalData) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| from | address | undefined |
| collateralAmount | uint256 | undefined |
| borrowAmount | uint256 | undefined |
| useAirdroppedFunds | bool | undefined |
| swapData | IUSDOBase.ILeverageSwapData | undefined |
| lzData | IUSDOBase.ILeverageLZData | undefined |
| externalData | IUSDOBase.ILeverageExternalContractsData | undefined |

### multiHopSellCollateral

```solidity
function multiHopSellCollateral(address from, uint256 share, bool useAirdroppedFunds, IUSDOBase.ILeverageSwapData swapData, IUSDOBase.ILeverageLZData lzData, IUSDOBase.ILeverageExternalContractsData externalData) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| from | address | undefined |
| share | uint256 | undefined |
| useAirdroppedFunds | bool | undefined |
| swapData | IUSDOBase.ILeverageSwapData | undefined |
| lzData | IUSDOBase.ILeverageLZData | undefined |
| externalData | IUSDOBase.ILeverageExternalContractsData | undefined |

### name

```solidity
function name() external view returns (string)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined |

### nonces

```solidity
function nonces(address) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### oracle

```solidity
function oracle() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### oracleData

```solidity
function oracleData() external view returns (bytes)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes | undefined |

### owner

```solidity
function owner() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### penrose

```solidity
function penrose() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### permit

```solidity
function permit(address owner_, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| owner_ | address | undefined |
| spender | address | undefined |
| value | uint256 | undefined |
| deadline | uint256 | undefined |
| v | uint8 | undefined |
| r | bytes32 | undefined |
| s | bytes32 | undefined |

### refreshPenroseFees

```solidity
function refreshPenroseFees() external nonpayable returns (uint256 feeShares)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| feeShares | uint256 | undefined |

### removeAsset

```solidity
function removeAsset(address from, address to, uint256 fraction) external nonpayable returns (uint256 share)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| from | address | undefined |
| to | address | undefined |
| fraction | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| share | uint256 | undefined |

### removeCollateral

```solidity
function removeCollateral(address from, address to, uint256 share) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| from | address | undefined |
| to | address | undefined |
| share | uint256 | undefined |

### repay

```solidity
function repay(address from, address to, bool skim, uint256 part) external nonpayable returns (uint256 amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| from | address | undefined |
| to | address | undefined |
| skim | bool | undefined |
| part | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| amount | uint256 | undefined |

### sellCollateral

```solidity
function sellCollateral(address from, uint256 share, uint256 minAmountOut, address swapper, bytes dexData) external nonpayable returns (uint256 amountOut)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| from | address | undefined |
| share | uint256 | undefined |
| minAmountOut | uint256 | undefined |
| swapper | address | undefined |
| dexData | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| amountOut | uint256 | undefined |

### startingInterestPerSecond

```solidity
function startingInterestPerSecond() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### totalAsset

```solidity
function totalAsset() external view returns (uint128 elastic, uint128 base)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| elastic | uint128 | undefined |
| base | uint128 | undefined |

### totalBorrow

```solidity
function totalBorrow() external view returns (uint128 elastic, uint128 base)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| elastic | uint128 | undefined |
| base | uint128 | undefined |

### totalBorrowCap

```solidity
function totalBorrowCap() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### totalCollateralShare

```solidity
function totalCollateralShare() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### userBorrowPart

```solidity
function userBorrowPart(address) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### userCollateralShare

```solidity
function userCollateralShare(address) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### yieldBox

```solidity
function yieldBox() external view returns (address payable)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address payable | undefined |




