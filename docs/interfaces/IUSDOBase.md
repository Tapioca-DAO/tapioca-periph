# IUSDOBase









## Methods

### addFlashloanFee

```solidity
function addFlashloanFee(uint256 _fee) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _fee | uint256 | undefined |

### burn

```solidity
function burn(address _from, uint256 _amount) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _from | address | undefined |
| _amount | uint256 | undefined |

### mint

```solidity
function mint(address _to, uint256 _amount) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _to | address | undefined |
| _amount | uint256 | undefined |

### paused

```solidity
function paused() external view returns (bool)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### removeAsset

```solidity
function removeAsset(address from, address to, uint16 lzDstChainId, address zroPaymentAddress, bytes adapterParams, ICommonData.ICommonExternalContracts externalData, IUSDOBase.IRemoveAndRepay removeAndRepayData, ICommonData.IApproval[] approvals, ICommonData.IApproval[] revokes) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| from | address | undefined |
| to | address | undefined |
| lzDstChainId | uint16 | undefined |
| zroPaymentAddress | address | undefined |
| adapterParams | bytes | undefined |
| externalData | ICommonData.ICommonExternalContracts | undefined |
| removeAndRepayData | IUSDOBase.IRemoveAndRepay | undefined |
| approvals | ICommonData.IApproval[] | undefined |
| revokes | ICommonData.IApproval[] | undefined |

### sendAndLendOrRepay

```solidity
function sendAndLendOrRepay(address _from, address _to, uint16 lzDstChainId, address zroPaymentAddress, IUSDOBase.ILendOrRepayParams lendParams, ICommonData.IApproval[] approvals, ICommonData.IApproval[] revokes, ICommonData.IWithdrawParams withdrawParams, bytes adapterParams) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _from | address | undefined |
| _to | address | undefined |
| lzDstChainId | uint16 | undefined |
| zroPaymentAddress | address | undefined |
| lendParams | IUSDOBase.ILendOrRepayParams | undefined |
| approvals | ICommonData.IApproval[] | undefined |
| revokes | ICommonData.IApproval[] | undefined |
| withdrawParams | ICommonData.IWithdrawParams | undefined |
| adapterParams | bytes | undefined |

### sendForLeverage

```solidity
function sendForLeverage(uint256 amount, address leverageFor, IUSDOBase.ILeverageLZData lzData, IUSDOBase.ILeverageSwapData swapData, IUSDOBase.ILeverageExternalContractsData externalData) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| amount | uint256 | undefined |
| leverageFor | address | undefined |
| lzData | IUSDOBase.ILeverageLZData | undefined |
| swapData | IUSDOBase.ILeverageSwapData | undefined |
| externalData | IUSDOBase.ILeverageExternalContractsData | undefined |

### setFlashloanHelper

```solidity
function setFlashloanHelper(address _helper) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _helper | address | undefined |

### triggerApproveOrRevoke

```solidity
function triggerApproveOrRevoke(uint16 lzDstChainId, ICommonOFT.LzCallParams lzCallParams, ICommonData.IApproval[] approvals) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| lzDstChainId | uint16 | undefined |
| lzCallParams | ICommonOFT.LzCallParams | undefined |
| approvals | ICommonData.IApproval[] | undefined |

### triggerSendFrom

```solidity
function triggerSendFrom(address from, uint16 dstChainId, bytes32 toAddress, uint256 amount, ICommonOFT.LzCallParams callParams) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| from | address | undefined |
| dstChainId | uint16 | undefined |
| toAddress | bytes32 | undefined |
| amount | uint256 | undefined |
| callParams | ICommonOFT.LzCallParams | undefined |




