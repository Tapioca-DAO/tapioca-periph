# MagnetarV2









## Methods

### bigBangMarketInfo

```solidity
function bigBangMarketInfo(address who, contract IBigBang[] markets) external view returns (struct MagnetarV2Storage.BigBangInfo[])
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
| _0 | MagnetarV2Storage.BigBangInfo[] | undefined |

### burst

```solidity
function burst(MagnetarV2Storage.Call[] calls) external payable returns (struct MagnetarV2Storage.Result[] returnData)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| calls | MagnetarV2Storage.Call[] | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| returnData | MagnetarV2Storage.Result[] | undefined |

### depositAddCollateralAndBorrowFromMarket

```solidity
function depositAddCollateralAndBorrowFromMarket(contract IMarket market, address user, uint256 collateralAmount, uint256 borrowAmount, bool extractFromSender, bool deposit, ICommonData.IWithdrawParams withdrawParams) external payable
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
| withdrawParams | ICommonData.IWithdrawParams | undefined |

### depositRepayAndRemoveCollateralFromMarket

```solidity
function depositRepayAndRemoveCollateralFromMarket(address market, address user, uint256 depositAmount, uint256 repayAmount, uint256 collateralAmount, bool extractFromSender, ICommonData.IWithdrawParams withdrawCollateralParams) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| market | address | undefined |
| user | address | undefined |
| depositAmount | uint256 | undefined |
| repayAmount | uint256 | undefined |
| collateralAmount | uint256 | undefined |
| extractFromSender | bool | undefined |
| withdrawCollateralParams | ICommonData.IWithdrawParams | undefined |

### exitPositionAndRemoveCollateral

```solidity
function exitPositionAndRemoveCollateral(address user, ICommonData.ICommonExternalContracts externalData, IUSDOBase.IRemoveAndRepay removeAndRepayData) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| user | address | undefined |
| externalData | ICommonData.ICommonExternalContracts | undefined |
| removeAndRepayData | IUSDOBase.IRemoveAndRepay | undefined |

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

### isApprovedForAll

```solidity
function isApprovedForAll(address, address) external view returns (bool)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |
| _1 | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### marketModule

```solidity
function marketModule() external view returns (contract MagnetarMarketModule)
```

returns the Market module




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract MagnetarMarketModule | undefined |

### mintFromBBAndLendOnSGL

```solidity
function mintFromBBAndLendOnSGL(address user, uint256 lendAmount, IUSDOBase.IMintData mintData, ICommonData.IDepositData depositData, ITapiocaOptionLiquidityProvision.IOptionsLockData lockData, ITapiocaOptionsBroker.IOptionsParticipateData participateData, ICommonData.ICommonExternalContracts externalContracts) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| user | address | undefined |
| lendAmount | uint256 | undefined |
| mintData | IUSDOBase.IMintData | undefined |
| depositData | ICommonData.IDepositData | undefined |
| lockData | ITapiocaOptionLiquidityProvision.IOptionsLockData | undefined |
| participateData | ITapiocaOptionsBroker.IOptionsParticipateData | undefined |
| externalContracts | ICommonData.ICommonExternalContracts | undefined |

### onERC721Received

```solidity
function onERC721Received(address, address, uint256, bytes) external nonpayable returns (bytes4)
```

IERC721Receiver implementation



#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |
| _1 | address | undefined |
| _2 | uint256 | undefined |
| _3 | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes4 | undefined |

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


### rescueEth

```solidity
function rescueEth(uint256 amount, address to) external nonpayable
```

rescues unused ETH from the contract



#### Parameters

| Name | Type | Description |
|---|---|---|
| amount | uint256 | the amount to rescue |
| to | address | the recipient |

### singularityMarketInfo

```solidity
function singularityMarketInfo(address who, contract ISingularity[] markets) external view returns (struct MagnetarV2Storage.SingularityInfo[])
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
| _0 | MagnetarV2Storage.SingularityInfo[] | undefined |

### transferOwnership

```solidity
function transferOwnership(address newOwner) external nonpayable
```



*Transfers ownership of the contract to a new account (`newOwner`). Can only be called by the current owner.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newOwner | address | undefined |

### withdrawToChain

```solidity
function withdrawToChain(contract IYieldBoxBase yieldBox, address from, uint256 assetId, uint16 dstChainId, bytes32 receiver, uint256 amount, uint256 share, bytes adapterParams, address payable refundAddress, uint256 gas) external payable
```

performs a withdraw operation

*it can withdraw on the current chain or it can send it to another one     - if `dstChainId` is 0 performs a same-chain withdrawal          - all parameters except `yieldBox`, `from`, `assetId` and `amount` or `share` are ignored     - if `dstChainId` is NOT 0, the method requires gas for the `sendFrom` operation*

#### Parameters

| Name | Type | Description |
|---|---|---|
| yieldBox | contract IYieldBoxBase | the YieldBox address |
| from | address | user to withdraw from |
| assetId | uint256 | the YieldBox asset id to withdraw |
| dstChainId | uint16 | LZ chain id to withdraw to |
| receiver | bytes32 | the receiver on the destination chain |
| amount | uint256 | the amount to withdraw |
| share | uint256 | the share to withdraw |
| adapterParams | bytes | LZ adapter params |
| refundAddress | address payable | the LZ refund address which receives the gas not used in the process |
| gas | uint256 | the amount of gas to use for sending the asset to another layer |



## Events

### ApprovalForAll

```solidity
event ApprovalForAll(address indexed owner, address indexed operator, bool approved)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| owner `indexed` | address | undefined |
| operator `indexed` | address | undefined |
| approved  | bool | undefined |

### OwnershipTransferred

```solidity
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| previousOwner `indexed` | address | undefined |
| newOwner `indexed` | address | undefined |



