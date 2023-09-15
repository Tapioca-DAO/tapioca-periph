# IMagnetar









## Methods

### depositAddCollateralAndBorrowFromMarket

```solidity
function depositAddCollateralAndBorrowFromMarket(address market, address user, uint256 collateralAmount, uint256 borrowAmount, bool extractFromSender, bool deposit, ICommonData.IWithdrawParams withdrawParams) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| market | address | undefined |
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

### helper

```solidity
function helper() external view returns (contract IMagnetarHelper)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract IMagnetarHelper | undefined |

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
function withdrawToChain(address yieldBox, address from, uint256 assetId, uint16 dstChainId, bytes32 receiver, uint256 amount, bytes adapterParams, address payable refundAddress, uint256 gas) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| yieldBox | address | undefined |
| from | address | undefined |
| assetId | uint256 | undefined |
| dstChainId | uint16 | undefined |
| receiver | bytes32 | undefined |
| amount | uint256 | undefined |
| adapterParams | bytes | undefined |
| refundAddress | address payable | undefined |
| gas | uint256 | undefined |




