# MagnetarHelper









## Methods

### bigBangMarketInfo

```solidity
function bigBangMarketInfo(address who, contract IBigBang[] markets) external view returns (struct MagnetarHelper.BigBangInfo[])
```

returns BigBang markets&#39; information



#### Parameters

| Name | Type | Description |
|---|---|---|
| who | address | user to return for |
| markets | contract IBigBang[] | the list of BigBang markets to query for |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | MagnetarHelper.BigBangInfo[] | undefined |

### getAmountForAssetFraction

```solidity
function getAmountForAssetFraction(contract ISingularity singularity, uint256 fraction) external view returns (uint256 amount)
```

Compute the amount of `singularity.assetId` from `fraction` `fraction` can be `singularity.accrueInfo.feeFraction` or `singularity.balanceOf`



#### Parameters

| Name | Type | Description |
|---|---|---|
| singularity | contract ISingularity | the singularity address |
| fraction | uint256 | The fraction. |

#### Returns

| Name | Type | Description |
|---|---|---|
| amount | uint256 | The amount. |

### getAmountForBorrowPart

```solidity
function getAmountForBorrowPart(contract IMarket market, uint256 borrowPart) external view returns (uint256 amount)
```

Return the equivalent of borrow part in asset amount.



#### Parameters

| Name | Type | Description |
|---|---|---|
| market | contract IMarket | the Singularity or BigBang address |
| borrowPart | uint256 | The amount of borrow part to convert. |

#### Returns

| Name | Type | Description |
|---|---|---|
| amount | uint256 | The equivalent of borrow part in asset amount. |

### getBorrowPartForAmount

```solidity
function getBorrowPartForAmount(contract IMarket market, uint256 amount) external view returns (uint256 part)
```

Return the equivalent of amount in borrow part.



#### Parameters

| Name | Type | Description |
|---|---|---|
| market | contract IMarket | the Singularity or BigBang address |
| amount | uint256 | The amount to convert. |

#### Returns

| Name | Type | Description |
|---|---|---|
| part | uint256 | The equivalent of amount in borrow part. |

### getCollateralAmountForShare

```solidity
function getCollateralAmountForShare(contract IMarket market, uint256 share) external view returns (uint256 amount)
```

Calculate the collateral amount off the shares.



#### Parameters

| Name | Type | Description |
|---|---|---|
| market | contract IMarket | the Singularity or BigBang address |
| share | uint256 | The shares. |

#### Returns

| Name | Type | Description |
|---|---|---|
| amount | uint256 | The amount. |

### getCollateralSharesForBorrowPart

```solidity
function getCollateralSharesForBorrowPart(contract IMarket market, uint256 borrowPart, uint256 collateralizationRatePrecision, uint256 exchangeRatePrecision) external view returns (uint256 collateralShares)
```

Calculate the collateral shares that are needed for `borrowPart`, taking the current exchange rate into account.



#### Parameters

| Name | Type | Description |
|---|---|---|
| market | contract IMarket | the Singularity or BigBang address |
| borrowPart | uint256 | The borrow part. |
| collateralizationRatePrecision | uint256 | undefined |
| exchangeRatePrecision | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| collateralShares | uint256 | The collateral shares. |

### getFractionForAmount

```solidity
function getFractionForAmount(contract ISingularity singularity, uint256 amount) external view returns (uint256 fraction)
```

Compute the fraction of `singularity.assetId` from `amount` `fraction` can be `singularity.accrueInfo.feeFraction` or `singularity.balanceOf`



#### Parameters

| Name | Type | Description |
|---|---|---|
| singularity | contract ISingularity | the singularity address |
| amount | uint256 | The amount. |

#### Returns

| Name | Type | Description |
|---|---|---|
| fraction | uint256 | The fraction. |

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


### singularityMarketInfo

```solidity
function singularityMarketInfo(address who, contract ISingularity[] markets) external view returns (struct MagnetarHelper.SingularityInfo[])
```

returns Singularity markets&#39; information



#### Parameters

| Name | Type | Description |
|---|---|---|
| who | address | user to return for |
| markets | contract ISingularity[] | the list of Singularity markets to query for |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | MagnetarHelper.SingularityInfo[] | undefined |

### transferOwnership

```solidity
function transferOwnership(address newOwner) external nonpayable
```



*Transfers ownership of the contract to a new account (`newOwner`). Can only be called by the current owner.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newOwner | address | undefined |



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



