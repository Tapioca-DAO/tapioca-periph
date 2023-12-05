# StargateLbpHelper









## Methods

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

### lbpPool

```solidity
function lbpPool() external view returns (contract ILiquidityBootstrappingPool)
```

LBP pool address




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract ILiquidityBootstrappingPool | undefined |

### lbpVault

```solidity
function lbpVault() external view returns (contract IBalancerVault)
```

LBP vault address




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract IBalancerVault | undefined |

### owner

```solidity
function owner() external view returns (address)
```



*Returns the address of the current owner.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### participate

```solidity
function participate(StargateLbpHelper.StargateData stargateData, StargateLbpHelper.ParticipateData lbpData) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| stargateData | StargateLbpHelper.StargateData | undefined |
| lbpData | StargateLbpHelper.ParticipateData | undefined |

### quoteLayerZeroFee

```solidity
function quoteLayerZeroFee(uint16 _dstChainId, uint8 _functionType, bytes _toAddress, bytes, IStargateRouterBase.lzTxObj _lzTxParams) external view returns (uint256, uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _dstChainId | uint16 | undefined |
| _functionType | uint8 | undefined |
| _toAddress | bytes | undefined |
| _3 | bytes | undefined |
| _lzTxParams | IStargateRouterBase.lzTxObj | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |
| _1 | uint256 | undefined |

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

### renounceOwnership

```solidity
function renounceOwnership() external nonpayable
```



*Leaves the contract without owner. It will not be possible to call `onlyOwner` functions anymore. Can only be called by the current owner. NOTE: Renouncing ownership will leave the contract without an owner, thereby removing any functionality that is only available to the owner.*


### retryRevert

```solidity
function retryRevert(uint16 srcChainId, bytes srcAddress, uint256 nonce) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| srcChainId | uint16 | undefined |
| srcAddress | bytes | undefined |
| nonce | uint256 | undefined |

### router

```solidity
function router() external view returns (contract IStargateRouter)
```

Stargate router address




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract IStargateRouter | undefined |

### sgReceive

```solidity
function sgReceive(uint16, bytes, uint256, address token, uint256 amountLD, bytes payload) external nonpayable
```

receive call for Stargate



#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint16 | undefined |
| _1 | bytes | undefined |
| _2 | uint256 | undefined |
| token | address | undefined |
| amountLD | uint256 | undefined |
| payload | bytes | undefined |

### transferOwnership

```solidity
function transferOwnership(address newOwner) external nonpayable
```



*Transfers ownership of the contract to a new account (`newOwner`). Can only be called by the current owner.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newOwner | address | undefined |



## Events

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

### BalanceTooLow

```solidity
error BalanceTooLow()
```






### NotAuthorized

```solidity
error NotAuthorized()
```






### RouterNotValid

```solidity
error RouterNotValid()
```






### TokensMismatch

```solidity
error TokensMismatch()
```






### UnsupportedFunctionType

```solidity
error UnsupportedFunctionType()
```







