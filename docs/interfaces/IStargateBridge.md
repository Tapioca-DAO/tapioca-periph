# IStargateBridge









## Methods

### gasLookup

```solidity
function gasLookup(uint16, uint8) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint16 | undefined |
| _1 | uint8 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### layerZeroEndpoint

```solidity
function layerZeroEndpoint() external view returns (contract ILayerZeroEndpoint)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract ILayerZeroEndpoint | undefined |

### quoteLayerZeroFee

```solidity
function quoteLayerZeroFee(uint16 _chainId, uint8 _functionType, bytes _toAddress, bytes _transferAndCallPayload, IStargateRouterBase.lzTxObj _lzTxParams) external view returns (uint256, uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _chainId | uint16 | undefined |
| _functionType | uint8 | undefined |
| _toAddress | bytes | undefined |
| _transferAndCallPayload | bytes | undefined |
| _lzTxParams | IStargateRouterBase.lzTxObj | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |
| _1 | uint256 | undefined |




