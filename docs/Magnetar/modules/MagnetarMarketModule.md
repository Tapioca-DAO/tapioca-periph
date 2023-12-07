# MagnetarMarketModule









## Methods

### cluster

```solidity
function cluster() external view returns (contract ICluster)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract ICluster | undefined |

### depositAddCollateralAndBorrowFromMarket

```solidity
function depositAddCollateralAndBorrowFromMarket(contract IMarket market, address user, uint256 collateralAmount, uint256 borrowAmount, bool extractFromSender, bool deposit, ICommonData.IWithdrawParams withdrawParams, uint256 valueAmount) external payable
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
| valueAmount | uint256 | undefined |

### depositRepayAndRemoveCollateralFromMarket

```solidity
function depositRepayAndRemoveCollateralFromMarket(address market, address user, uint256 depositAmount, uint256 repayAmount, uint256 collateralAmount, bool extractFromSender, ICommonData.IWithdrawParams withdrawCollateralParams, uint256 valueAmount) external payable
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
| valueAmount | uint256 | undefined |

### exitPositionAndRemoveCollateral

```solidity
function exitPositionAndRemoveCollateral(address user, ICommonData.ICommonExternalContracts externalData, IUSDOBase.IRemoveAndRepay removeAndRepayData, uint256 valueAmount, contract ICluster _cluster) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| user | address | undefined |
| externalData | ICommonData.ICommonExternalContracts | undefined |
| removeAndRepayData | IUSDOBase.IRemoveAndRepay | undefined |
| valueAmount | uint256 | undefined |
| _cluster | contract ICluster | undefined |

### mintFromBBAndLendOnSGL

```solidity
function mintFromBBAndLendOnSGL(address user, uint256 lendAmount, IUSDOBase.IMintData mintData, ICommonData.IDepositData depositData, ITapiocaOptionLiquidityProvision.IOptionsLockData lockData, ITapiocaOptionsBroker.IOptionsParticipateData participateData, ICommonData.ICommonExternalContracts externalContracts, contract ICluster _cluster) external payable
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
| _cluster | contract ICluster | undefined |

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



*Leaves the contract without owner. It will not be possible to call `onlyOwner` functions. Can only be called by the current owner. NOTE: Renouncing ownership will leave the contract without an owner, thereby disabling any functionality that is only available to the owner.*


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
function withdrawToChain(contract IYieldBoxBase yieldBox, address from, uint256 assetId, uint16 dstChainId, bytes32 receiver, uint256 amount, bytes adapterParams, address payable refundAddress, uint256 gas, bool unwrap) external payable
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
| adapterParams | bytes | undefined |
| refundAddress | address payable | undefined |
| gas | uint256 | undefined |
| unwrap | bool | undefined |



## Events

### ClusterSet

```solidity
event ClusterSet(contract ICluster indexed oldCluster, contract ICluster indexed newCluster)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| oldCluster `indexed` | contract ICluster | undefined |
| newCluster `indexed` | contract ICluster | undefined |

### OwnershipTransferred

```solidity
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| previousOwner `indexed` | address | undefined |
| newOwner `indexed` | address | undefined |



## Errors

### Failed

```solidity
error Failed()
```






### LockTargetMismatch

```solidity
error LockTargetMismatch()
```






### NotAuthorized

```solidity
error NotAuthorized()
```






### NotValid

```solidity
error NotValid()
```






### tOLPTokenMismatch

```solidity
error tOLPTokenMismatch()
```







