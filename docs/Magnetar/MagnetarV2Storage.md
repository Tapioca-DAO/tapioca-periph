# MagnetarV2Storage









## Methods

### cluster

```solidity
function cluster() external view returns (contract ICluster)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract ICluster | undefined |

### onERC721Received

```solidity
function onERC721Received(address, address, uint256, bytes) external nonpayable returns (bytes4)
```

IERC721Receiver implementation



#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |
| _1 | address | undefined |
| _2 | uint256 | undefined |
| _3 | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes4 | undefined |



## Events

### ClusterSet

```solidity
event ClusterSet(contract ICluster indexed oldCluster, contract ICluster indexed newCluster)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| oldCluster `indexed` | contract ICluster | undefined |
| newCluster `indexed` | contract ICluster | undefined |



## Errors

### NotAuthorized

```solidity
error NotAuthorized()
```







