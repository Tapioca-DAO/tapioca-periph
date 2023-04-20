# IYieldBoxBase









## Methods

### assets

```solidity
function assets(uint256 assetId) external view returns (enum TokenType tokenType, address contractAddress, address strategy, uint256 tokenId)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| assetId | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| tokenType | enum TokenType | undefined |
| contractAddress | address | undefined |
| strategy | address | undefined |
| tokenId | uint256 | undefined |

### depositAsset

```solidity
function depositAsset(uint256 assetId, address from, address to, uint256 amount, uint256 share) external nonpayable returns (uint256 amountOut, uint256 shareOut)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| assetId | uint256 | undefined |
| from | address | undefined |
| to | address | undefined |
| amount | uint256 | undefined |
| share | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| amountOut | uint256 | undefined |
| shareOut | uint256 | undefined |

### isApprovedForAll

```solidity
function isApprovedForAll(address user, address spender) external view returns (bool)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| user | address | undefined |
| spender | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### setApprovalForAll

```solidity
function setApprovalForAll(address spender, bool status) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| spender | address | undefined |
| status | bool | undefined |

### toAmount

```solidity
function toAmount(uint256 assetId, uint256 share, bool roundUp) external view returns (uint256 amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| assetId | uint256 | undefined |
| share | uint256 | undefined |
| roundUp | bool | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| amount | uint256 | undefined |

### toShare

```solidity
function toShare(uint256 assetId, uint256 amount, bool roundUp) external view returns (uint256 share)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| assetId | uint256 | undefined |
| amount | uint256 | undefined |
| roundUp | bool | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| share | uint256 | undefined |

### transfer

```solidity
function transfer(address from, address to, uint256 assetId, uint256 share) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| from | address | undefined |
| to | address | undefined |
| assetId | uint256 | undefined |
| share | uint256 | undefined |

### withdraw

```solidity
function withdraw(uint256 assetId, address from, address to, uint256 amount, uint256 share) external nonpayable returns (uint256 amountOut, uint256 shareOut)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| assetId | uint256 | undefined |
| from | address | undefined |
| to | address | undefined |
| amount | uint256 | undefined |
| share | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| amountOut | uint256 | undefined |
| shareOut | uint256 | undefined |




