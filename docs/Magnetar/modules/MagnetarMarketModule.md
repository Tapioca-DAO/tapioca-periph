# MagnetarMarketModule









## Methods

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
function exitPositionAndRemoveCollateral(address user, ICommonData.ICommonExternalContracts externalData, IUSDOBase.IRemoveAndRepay removeAndRepayData, uint256 valueAmount) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| user | address | undefined |
| externalData | ICommonData.ICommonExternalContracts | undefined |
| removeAndRepayData | IUSDOBase.IRemoveAndRepay | undefined |
| valueAmount | uint256 | undefined |

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

### withdrawToChain

```solidity
function withdrawToChain(contract IYieldBoxBase yieldBox, address from, uint256 assetId, uint16 dstChainId, bytes32 receiver, uint256 amount, bytes adapterParams, address payable refundAddress, uint256 gas) external payable
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



