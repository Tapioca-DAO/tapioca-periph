# ITapiocaOFT









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

### getLzChainId

```solidity
function getLzChainId() external view returns (uint16)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint16 | undefined |

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

### isNative

```solidity
function isNative() external view returns (bool)
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

### retrieveFromYB

```solidity
function retrieveFromYB(address _from, uint256 amount, uint256 assetId, uint16 lzDstChainId, address zroPaymentAddress, bytes airdropAdapterParam, bool strategyWithdrawal) external payable
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
| strategyWithdrawal | bool | undefined |

### sendToYB

```solidity
function sendToYB(address _from, address _to, uint256 amount, uint256 assetId, uint16 lzDstChainId, ITapiocaOFT.SendOptions options) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _from | address | undefined |
| _to | address | undefined |
| amount | uint256 | undefined |
| assetId | uint256 | undefined |
| lzDstChainId | uint16 | undefined |
| options | ITapiocaOFT.SendOptions | undefined |

### sendToYBAndBorrow

```solidity
function sendToYBAndBorrow(address _from, address _to, uint16 lzDstChainId, bytes airdropAdapterParams, ITapiocaOFT.IBorrowParams borrowParams, ITapiocaOFT.IWithdrawParams withdrawParams, ITapiocaOFT.SendOptions options, ITapiocaOFT.IApproval[] approvals) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _from | address | undefined |
| _to | address | undefined |
| lzDstChainId | uint16 | undefined |
| airdropAdapterParams | bytes | undefined |
| borrowParams | ITapiocaOFT.IBorrowParams | undefined |
| withdrawParams | ITapiocaOFT.IWithdrawParams | undefined |
| options | ITapiocaOFT.SendOptions | undefined |
| approvals | ITapiocaOFT.IApproval[] | undefined |

### totalFees

```solidity
function totalFees() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### unwrap

```solidity
function unwrap(address _toAddress, uint256 _amount) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _toAddress | address | undefined |
| _amount | uint256 | undefined |

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




