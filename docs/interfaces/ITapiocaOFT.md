# ITapiocaOFT







*used for generic TOFTs*

## Methods

### approve

```solidity
function approve(address _spender, uint256 _amount) external nonpayable returns (bool)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _spender | address | undefined |
| _amount | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### balanceOf

```solidity
function balanceOf(address _holder) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _holder | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### erc20

```solidity
function erc20() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### extractUnderlying

```solidity
function extractUnderlying(uint256 _amount) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _amount | uint256 | undefined |

### harvestFees

```solidity
function harvestFees() external nonpayable
```






### hostChainID

```solidity
function hostChainID() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### isHostChain

```solidity
function isHostChain() external view returns (bool)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### isTrustedRemote

```solidity
function isTrustedRemote(uint16 lzChainId, bytes path) external view returns (bool)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| lzChainId | uint16 | undefined |
| path | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### lzEndpoint

```solidity
function lzEndpoint() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### removeCollateral

```solidity
function removeCollateral(address from, address to, uint16 lzDstChainId, address zroPaymentAddress, ICommonData.IWithdrawParams withdrawParams, ITapiocaOFT.IRemoveParams removeParams, ICommonData.IApproval[] approvals, ICommonData.IApproval[] revokes, bytes adapterParams) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| from | address | undefined |
| to | address | undefined |
| lzDstChainId | uint16 | undefined |
| zroPaymentAddress | address | undefined |
| withdrawParams | ICommonData.IWithdrawParams | undefined |
| removeParams | ITapiocaOFT.IRemoveParams | undefined |
| approvals | ICommonData.IApproval[] | undefined |
| revokes | ICommonData.IApproval[] | undefined |
| adapterParams | bytes | undefined |

### retrieveFromStrategy

```solidity
function retrieveFromStrategy(address _from, uint256 amount, uint256 assetId, uint16 lzDstChainId, address zroPaymentAddress, bytes airdropAdapterParam) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _from | address | undefined |
| amount | uint256 | undefined |
| assetId | uint256 | undefined |
| lzDstChainId | uint16 | undefined |
| zroPaymentAddress | address | undefined |
| airdropAdapterParam | bytes | undefined |

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

### sendFrom

```solidity
function sendFrom(address from, uint16 dstChainId, bytes32 toAddress, uint256 amount, ICommonOFT.LzCallParams callParams) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| from | address | undefined |
| dstChainId | uint16 | undefined |
| toAddress | bytes32 | undefined |
| amount | uint256 | undefined |
| callParams | ICommonOFT.LzCallParams | undefined |

### sendToStrategy

```solidity
function sendToStrategy(address _from, address _to, uint256 amount, uint256 assetId, uint16 lzDstChainId, ICommonData.ISendOptions options) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _from | address | undefined |
| _to | address | undefined |
| amount | uint256 | undefined |
| assetId | uint256 | undefined |
| lzDstChainId | uint16 | undefined |
| options | ICommonData.ISendOptions | undefined |

### sendToYBAndBorrow

```solidity
function sendToYBAndBorrow(address _from, address _to, uint16 lzDstChainId, bytes airdropAdapterParams, ITapiocaOFT.IBorrowParams borrowParams, ICommonData.IWithdrawParams withdrawParams, ICommonData.ISendOptions options, ICommonData.IApproval[] approvals, ICommonData.IApproval[] revokes) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _from | address | undefined |
| _to | address | undefined |
| lzDstChainId | uint16 | undefined |
| airdropAdapterParams | bytes | undefined |
| borrowParams | ITapiocaOFT.IBorrowParams | undefined |
| withdrawParams | ICommonData.IWithdrawParams | undefined |
| options | ICommonData.ISendOptions | undefined |
| approvals | ICommonData.IApproval[] | undefined |
| revokes | ICommonData.IApproval[] | undefined |

### totalFees

```solidity
function totalFees() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

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

### triggerSendFromWithParams

```solidity
function triggerSendFromWithParams(address from, uint16 lzDstChainId, bytes32 to, uint256 amount, ICommonOFT.LzCallParams callParams, bool unwrap, ICommonData.IApproval[] approvals, ICommonData.IApproval[] revokes) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| from | address | undefined |
| lzDstChainId | uint16 | undefined |
| to | bytes32 | undefined |
| amount | uint256 | undefined |
| callParams | ICommonOFT.LzCallParams | undefined |
| unwrap | bool | undefined |
| approvals | ICommonData.IApproval[] | undefined |
| revokes | ICommonData.IApproval[] | undefined |

### unwrap

```solidity
function unwrap(address _toAddress, uint256 _amount) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _toAddress | address | undefined |
| _amount | uint256 | undefined |

### useCustomAdapterParams

```solidity
function useCustomAdapterParams() external view returns (bool)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### wrap

```solidity
function wrap(address fromAddress, address toAddress, uint256 amount) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| fromAddress | address | undefined |
| toAddress | address | undefined |
| amount | uint256 | undefined |

### wrappedAmount

```solidity
function wrappedAmount(uint256 _amount) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _amount | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |




