# IMagnetar









## Methods

### depositAddCollateralAndBorrow

```solidity
function depositAddCollateralAndBorrow(address market, address user, uint256 collateralAmount, uint256 borrowAmount, bool extractFromSender, bool deposit, bool withdraw, bytes withdrawData) external payable
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
| withdraw | bool | undefined |
| withdrawData | bytes | undefined |

### depositAndAddAsset

```solidity
function depositAndAddAsset(address singularity, address _user, uint256 _amount, bool deposit_, bool extractFromSender) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| singularity | address | undefined |
| _user | address | undefined |
| _amount | uint256 | undefined |
| deposit_ | bool | undefined |
| extractFromSender | bool | undefined |

### depositAndRepay

```solidity
function depositAndRepay(address market, address user, uint256 depositAmount, uint256 repayAmount, bool deposit, bool extractFromSender) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| market | address | undefined |
| user | address | undefined |
| depositAmount | uint256 | undefined |
| repayAmount | uint256 | undefined |
| deposit | bool | undefined |
| extractFromSender | bool | undefined |

### depositRepayAndRemoveCollateral

```solidity
function depositRepayAndRemoveCollateral(address market, address user, uint256 depositAmount, uint256 repayAmount, uint256 collateralAmount, bool deposit, bool withdraw, bool extractFromSender) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| market | address | undefined |
| user | address | undefined |
| depositAmount | uint256 | undefined |
| repayAmount | uint256 | undefined |
| collateralAmount | uint256 | undefined |
| deposit | bool | undefined |
| withdraw | bool | undefined |
| extractFromSender | bool | undefined |

### mintAndLend

```solidity
function mintAndLend(address singularity, address bingBang, address user, uint256 collateralAmount, uint256 borrowAmount, bool deposit, bool extractFromSender) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| singularity | address | undefined |
| bingBang | address | undefined |
| user | address | undefined |
| collateralAmount | uint256 | undefined |
| borrowAmount | uint256 | undefined |
| deposit | bool | undefined |
| extractFromSender | bool | undefined |

### removeAssetAndRepay

```solidity
function removeAssetAndRepay(address singularity, address bingBang, address user, uint256 removeShare, uint256 repayAmount, uint256 collateralShare, bool withdraw, bytes withdrawData) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| singularity | address | undefined |
| bingBang | address | undefined |
| user | address | undefined |
| removeShare | uint256 | undefined |
| repayAmount | uint256 | undefined |
| collateralShare | uint256 | undefined |
| withdraw | bool | undefined |
| withdrawData | bytes | undefined |

### withdrawTo

```solidity
function withdrawTo(address yieldBox, address from, uint256 assetId, uint16 dstChainId, bytes32 receiver, uint256 amount, uint256 share, bytes adapterParams, address payable refundAddress, uint256 gas) external payable
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
| share | uint256 | undefined |
| adapterParams | bytes | undefined |
| refundAddress | address payable | undefined |
| gas | uint256 | undefined |




