# ILayerZeroEndpoint









## Methods

### estimateFees

```solidity
function estimateFees(uint16 _dstChainId, address _userApplication, bytes _payload, bool _payInZRO, bytes _adapterParam) external view returns (uint256 nativeFee, uint256 zroFee)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _dstChainId | uint16 | undefined |
| _userApplication | address | undefined |
| _payload | bytes | undefined |
| _payInZRO | bool | undefined |
| _adapterParam | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| nativeFee | uint256 | undefined |
| zroFee | uint256 | undefined |

### forceResumeReceive

```solidity
function forceResumeReceive(uint16 _srcChainId, bytes _srcAddress) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _srcChainId | uint16 | undefined |
| _srcAddress | bytes | undefined |

### getChainId

```solidity
function getChainId() external view returns (uint16)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint16 | undefined |

### getConfig

```solidity
function getConfig(uint16 _version, uint16 _chainId, address _userApplication, uint256 _configType) external view returns (bytes)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _version | uint16 | undefined |
| _chainId | uint16 | undefined |
| _userApplication | address | undefined |
| _configType | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes | undefined |

### getInboundNonce

```solidity
function getInboundNonce(uint16 _srcChainId, bytes _srcAddress) external view returns (uint64)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _srcChainId | uint16 | undefined |
| _srcAddress | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint64 | undefined |

### getOutboundNonce

```solidity
function getOutboundNonce(uint16 _dstChainId, address _srcAddress) external view returns (uint64)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _dstChainId | uint16 | undefined |
| _srcAddress | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint64 | undefined |

### getReceiveLibraryAddress

```solidity
function getReceiveLibraryAddress(address _userApplication) external view returns (address)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _userApplication | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### getReceiveVersion

```solidity
function getReceiveVersion(address _userApplication) external view returns (uint16)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _userApplication | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint16 | undefined |

### getSendLibraryAddress

```solidity
function getSendLibraryAddress(address _userApplication) external view returns (address)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _userApplication | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### getSendVersion

```solidity
function getSendVersion(address _userApplication) external view returns (uint16)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _userApplication | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint16 | undefined |

### hasStoredPayload

```solidity
function hasStoredPayload(uint16 _srcChainId, bytes _srcAddress) external view returns (bool)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _srcChainId | uint16 | undefined |
| _srcAddress | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### isReceivingPayload

```solidity
function isReceivingPayload() external view returns (bool)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### isSendingPayload

```solidity
function isSendingPayload() external view returns (bool)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### receivePayload

```solidity
function receivePayload(uint16 _srcChainId, bytes _srcAddress, address _dstAddress, uint64 _nonce, uint256 _gasLimit, bytes _payload) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _srcChainId | uint16 | undefined |
| _srcAddress | bytes | undefined |
| _dstAddress | address | undefined |
| _nonce | uint64 | undefined |
| _gasLimit | uint256 | undefined |
| _payload | bytes | undefined |

### retryPayload

```solidity
function retryPayload(uint16 _srcChainId, bytes _srcAddress, bytes _payload) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _srcChainId | uint16 | undefined |
| _srcAddress | bytes | undefined |
| _payload | bytes | undefined |

### send

```solidity
function send(uint16 _dstChainId, bytes _destination, bytes _payload, address payable _refundAddress, address _zroPaymentAddress, bytes _adapterParams) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _dstChainId | uint16 | undefined |
| _destination | bytes | undefined |
| _payload | bytes | undefined |
| _refundAddress | address payable | undefined |
| _zroPaymentAddress | address | undefined |
| _adapterParams | bytes | undefined |

### setConfig

```solidity
function setConfig(uint16 _version, uint16 _chainId, uint256 _configType, bytes _config) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _version | uint16 | undefined |
| _chainId | uint16 | undefined |
| _configType | uint256 | undefined |
| _config | bytes | undefined |

### setReceiveVersion

```solidity
function setReceiveVersion(uint16 _version) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _version | uint16 | undefined |

### setSendVersion

```solidity
function setSendVersion(uint16 _version) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _version | uint16 | undefined |




