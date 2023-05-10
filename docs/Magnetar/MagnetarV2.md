# MagnetarV2









## Methods

### bigBangMarketInfo

```solidity
function bigBangMarketInfo(address who, contract IBigBang[] markets) external view returns (struct MagnetarV2Operations.BigBangInfo[])
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
| _0 | MagnetarV2Operations.BigBangInfo[] | undefined |

### burst

```solidity
function burst(MagnetarV2ActionsData.Call[] calls) external payable returns (struct MagnetarV2ActionsData.Result[] returnData)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| calls | MagnetarV2ActionsData.Call[] | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| returnData | MagnetarV2ActionsData.Result[] | undefined |

### depositAddCollateralAndBorrow

```solidity
function depositAddCollateralAndBorrow(contract IMarket market, address user, uint256 collateralAmount, uint256 borrowAmount, bool extractFromSender, bool deposit, bool withdraw, bytes withdrawData) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| market | contract IMarket | undefined |
| user | address | undefined |
| collateralAmount | uint256 | undefined |
| borrowAmount | uint256 | undefined |
| extractFromSender | bool | undefined |
| deposit | bool | undefined |
| withdraw | bool | undefined |
| withdrawData | bytes | undefined |

### depositAndAddAsset

```solidity
function depositAndAddAsset(contract IMarket singularity, address _user, uint256 _amount, bool deposit_, bool extractFromSender) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| singularity | contract IMarket | undefined |
| _user | address | undefined |
| _amount | uint256 | undefined |
| deposit_ | bool | undefined |
| extractFromSender | bool | undefined |

### depositAndRepay

```solidity
function depositAndRepay(contract IMarket market, address user, uint256 depositAmount, uint256 repayAmount, bool deposit, bool extractFromSender) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| market | contract IMarket | undefined |
| user | address | undefined |
| depositAmount | uint256 | undefined |
| repayAmount | uint256 | undefined |
| deposit | bool | undefined |
| extractFromSender | bool | undefined |

### depositRepayAndRemoveCollateral

```solidity
function depositRepayAndRemoveCollateral(contract IMarket market, address user, uint256 depositAmount, uint256 repayAmount, uint256 collateralAmount, bool deposit, bool withdraw, bool extractFromSender) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| market | contract IMarket | undefined |
| user | address | undefined |
| depositAmount | uint256 | undefined |
| repayAmount | uint256 | undefined |
| collateralAmount | uint256 | undefined |
| deposit | bool | undefined |
| withdraw | bool | undefined |
| extractFromSender | bool | undefined |

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
function getCollateralSharesForBorrowPart(contract IMarket market, uint256 borrowPart, uint256 liquidationMultiplierPrecision, uint256 exchangeRatePrecision) external view returns (uint256 collateralShares)
```

Calculate the collateral shares that are needed for `borrowPart`, taking the current exchange rate into account.



#### Parameters

| Name | Type | Description |
|---|---|---|
| market | contract IMarket | the Singularity or BigBang address |
| borrowPart | uint256 | The borrow part. |
| liquidationMultiplierPrecision | uint256 | undefined |
| exchangeRatePrecision | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| collateralShares | uint256 | The collateral shares. |

### mintAndLend

```solidity
function mintAndLend(contract ISingularity singularity, contract IMarket bingBang, address user, uint256 collateralAmount, uint256 borrowAmount, bool deposit, bool extractFromSender) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| singularity | contract ISingularity | undefined |
| bingBang | contract IMarket | undefined |
| user | address | undefined |
| collateralAmount | uint256 | undefined |
| borrowAmount | uint256 | undefined |
| deposit | bool | undefined |
| extractFromSender | bool | undefined |

### owner

```solidity
function owner() external view returns (address)
```



*Returns the address of the current owner.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### removeAssetAndRepay

```solidity
function removeAssetAndRepay(contract ISingularity singularity, contract IMarket bingBang, address user, uint256 removeShare, uint256 repayAmount, uint256 collateralShare, bool withdraw, bytes withdrawData) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| singularity | contract ISingularity | undefined |
| bingBang | contract IMarket | undefined |
| user | address | undefined |
| removeShare | uint256 | undefined |
| repayAmount | uint256 | undefined |
| collateralShare | uint256 | undefined |
| withdraw | bool | undefined |
| withdrawData | bytes | undefined |

### renounceOwnership

```solidity
function renounceOwnership() external nonpayable
```



*Leaves the contract without owner. It will not be possible to call `onlyOwner` functions anymore. Can only be called by the current owner. NOTE: Renouncing ownership will leave the contract without an owner, thereby removing any functionality that is only available to the owner.*


### singularityMarketInfo

```solidity
function singularityMarketInfo(address who, contract ISingularity[] markets) external view returns (struct MagnetarV2Operations.SingularityInfo[])
```

*** VIEW METHODS *** ***  ***returns Singularity markets&#39; information



#### Parameters

| Name | Type | Description |
|---|---|---|
| who | address | user to return for |
| markets | contract ISingularity[] | the list of Singularity markets to query for |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | MagnetarV2Operations.SingularityInfo[] | undefined |

### transferOwnership

```solidity
function transferOwnership(address newOwner) external nonpayable
```



*Transfers ownership of the contract to a new account (`newOwner`). Can only be called by the current owner.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newOwner | address | undefined |

### withdrawTo

```solidity
function withdrawTo(contract IYieldBoxBase yieldBox, address from, uint256 assetId, uint16 dstChainId, bytes32 receiver, uint256 amount, uint256 share, bytes adapterParams, address payable refundAddress, uint256 gas) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| yieldBox | contract IYieldBoxBase | undefined |
| from | address | undefined |
| assetId | uint256 | undefined |
| dstChainId | uint16 | undefined |
| receiver | bytes32 | undefined |
| amount | uint256 | undefined |
| share | uint256 | undefined |
| adapterParams | bytes | undefined |
| refundAddress | address payable | undefined |
| gas | uint256 | undefined |



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



