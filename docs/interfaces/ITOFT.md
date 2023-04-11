# ITOFT









## Methods

### retrieveFromYB

```solidity
function retrieveFromYB(address from, uint256 amount, uint256 assetId, uint16 lzDstChainId, address zroPaymentAddress, bytes airdropAdapterParam, bool strategyWithdrawal) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| from | address | undefined |
| amount | uint256 | undefined |
| assetId | uint256 | undefined |
| lzDstChainId | uint16 | undefined |
| zroPaymentAddress | address | undefined |
| airdropAdapterParam | bytes | undefined |
| strategyWithdrawal | bool | undefined |

### sendFrom

```solidity
function sendFrom(address _from, uint16 _dstChainId, bytes32 _toAddress, uint256 _amount, ISendFrom.LzCallParams _callParams) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _from | address | undefined |
| _dstChainId | uint16 | undefined |
| _toAddress | bytes32 | undefined |
| _amount | uint256 | undefined |
| _callParams | ISendFrom.LzCallParams | undefined |

### sendToYB

```solidity
function sendToYB(address from, address to, uint256 amount, uint256 assetId, uint16 lzDstChainId, ITOFT.IUSDOSendOptions options) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| from | address | undefined |
| to | address | undefined |
| amount | uint256 | undefined |
| assetId | uint256 | undefined |
| lzDstChainId | uint16 | undefined |
| options | ITOFT.IUSDOSendOptions | undefined |

### sendToYBAndBorrow

```solidity
function sendToYBAndBorrow(address _from, address _to, uint16 lzDstChainId, bytes airdropAdapterParams, ITOFT.IBorrowParams borrowParams, ITOFT.IWithdrawParams withdrawParams, ITOFT.ITOFTSendOptions options, ITOFT.ITOFTApproval[] approvals) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _from | address | undefined |
| _to | address | undefined |
| lzDstChainId | uint16 | undefined |
| airdropAdapterParams | bytes | undefined |
| borrowParams | ITOFT.IBorrowParams | undefined |
| withdrawParams | ITOFT.IWithdrawParams | undefined |
| options | ITOFT.ITOFTSendOptions | undefined |
| approvals | ITOFT.ITOFTApproval[] | undefined |

### sendToYBAndLend

```solidity
function sendToYBAndLend(address _from, address _to, uint16 lzDstChainId, ITOFT.ILendParams lendParams, ITOFT.IUSDOSendOptions options, ITOFT.IUSDOApproval[] approvals) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _from | address | undefined |
| _to | address | undefined |
| lzDstChainId | uint16 | undefined |
| lendParams | ITOFT.ILendParams | undefined |
| options | ITOFT.IUSDOSendOptions | undefined |
| approvals | ITOFT.IUSDOApproval[] | undefined |

### wrap

```solidity
function wrap(address fromAddress, address toAddress, uint256 amount) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| fromAddress | address | undefined |
| toAddress | address | undefined |
| amount | uint256 | undefined |

### wrapNative

```solidity
function wrapNative(address _toAddress) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _toAddress | address | undefined |




