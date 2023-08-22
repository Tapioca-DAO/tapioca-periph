# IStargateRouter









## Methods

### activateChainPath

```solidity
function activateChainPath(uint256 _poolId, uint16 _dstChainId, uint256 _dstPoolId) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolId | uint256 | undefined |
| _dstChainId | uint16 | undefined |
| _dstPoolId | uint256 | undefined |

### addLiquidity

```solidity
function addLiquidity(uint256 _poolId, uint256 _amountLD, address _to) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolId | uint256 | undefined |
| _amountLD | uint256 | undefined |
| _to | address | undefined |

### bridge

```solidity
function bridge() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### createChainPath

```solidity
function createChainPath(uint256 _poolId, uint16 _dstChainId, uint256 _dstPoolId, uint256 _weight) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolId | uint256 | undefined |
| _dstChainId | uint16 | undefined |
| _dstPoolId | uint256 | undefined |
| _weight | uint256 | undefined |

### creditChainPath

```solidity
function creditChainPath(uint16 _dstChainId, uint256 _dstPoolId, uint256 _srcPoolId, IStargateRouter.CreditObj _c) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _dstChainId | uint16 | undefined |
| _dstPoolId | uint256 | undefined |
| _srcPoolId | uint256 | undefined |
| _c | IStargateRouter.CreditObj | undefined |

### instantRedeemLocal

```solidity
function instantRedeemLocal(uint16 _srcPoolId, uint256 _amountLP, address _to) external nonpayable returns (uint256 amountSD)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _srcPoolId | uint16 | undefined |
| _amountLP | uint256 | undefined |
| _to | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| amountSD | uint256 | undefined |

### poolId

```solidity
function poolId() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### redeemLocal

```solidity
function redeemLocal(uint16 _dstChainId, uint256 _srcPoolId, uint256 _dstPoolId, address payable _refundAddress, uint256 _amountLP, bytes _to, IStargateRouterBase.lzTxObj _lzTxParams) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _dstChainId | uint16 | undefined |
| _srcPoolId | uint256 | undefined |
| _dstPoolId | uint256 | undefined |
| _refundAddress | address payable | undefined |
| _amountLP | uint256 | undefined |
| _to | bytes | undefined |
| _lzTxParams | IStargateRouterBase.lzTxObj | undefined |

### redeemRemote

```solidity
function redeemRemote(uint16 _dstChainId, uint256 _srcPoolId, uint256 _dstPoolId, address payable _refundAddress, uint256 _amountLP, uint256 _minAmountLD, bytes _to, IStargateRouterBase.lzTxObj _lzTxParams) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _dstChainId | uint16 | undefined |
| _srcPoolId | uint256 | undefined |
| _dstPoolId | uint256 | undefined |
| _refundAddress | address payable | undefined |
| _amountLP | uint256 | undefined |
| _minAmountLD | uint256 | undefined |
| _to | bytes | undefined |
| _lzTxParams | IStargateRouterBase.lzTxObj | undefined |

### retryRevert

```solidity
function retryRevert(uint16 _srcChainId, bytes _srcAddress, uint256 _nonce) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _srcChainId | uint16 | undefined |
| _srcAddress | bytes | undefined |
| _nonce | uint256 | undefined |

### setWeightForChainPath

```solidity
function setWeightForChainPath(uint256 _poolId, uint16 _dstChainId, uint256 _dstPoolId, uint16 _weight) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolId | uint256 | undefined |
| _dstChainId | uint16 | undefined |
| _dstPoolId | uint256 | undefined |
| _weight | uint16 | undefined |

### stargateEthVault

```solidity
function stargateEthVault() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### stargateRouter

```solidity
function stargateRouter() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### swap

```solidity
function swap(uint16 _dstChainId, uint256 _srcPoolId, uint256 _dstPoolId, address payable _refundAddress, uint256 _amountLD, uint256 _minAmountLD, IStargateRouterBase.lzTxObj _lzTxParams, bytes _to, bytes _payload) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _dstChainId | uint16 | undefined |
| _srcPoolId | uint256 | undefined |
| _dstPoolId | uint256 | undefined |
| _refundAddress | address payable | undefined |
| _amountLD | uint256 | undefined |
| _minAmountLD | uint256 | undefined |
| _lzTxParams | IStargateRouterBase.lzTxObj | undefined |
| _to | bytes | undefined |
| _payload | bytes | undefined |

### swapETH

```solidity
function swapETH(uint16 _dstChainId, address payable, bytes _toAddress, uint256 _amountLD, uint256 _minAmountLD) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _dstChainId | uint16 | undefined |
| _1 | address payable | undefined |
| _toAddress | bytes | undefined |
| _amountLD | uint256 | undefined |
| _minAmountLD | uint256 | undefined |




