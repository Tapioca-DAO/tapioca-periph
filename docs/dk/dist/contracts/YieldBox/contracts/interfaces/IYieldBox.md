# IYieldBox









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

### batchTransfer

```solidity
function batchTransfer(address from, address to, uint256[] assetIds_, uint256[] shares_) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| from | address | undefined |
| to | address | undefined |
| assetIds_ | uint256[] | undefined |
| shares_ | uint256[] | undefined |

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

### nativeTokens

```solidity
function nativeTokens(uint256 assetId) external view returns (string name, string symbol, uint8 decimals)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| assetId | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| name | string | undefined |
| symbol | string | undefined |
| decimals | uint8 | undefined |

### owner

```solidity
function owner(uint256 assetId) external view returns (address owner)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| assetId | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| owner | address | undefined |

### setApprovalForAsset

```solidity
function setApprovalForAsset(address operator, uint256 assetId, bool approved) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| operator | address | undefined |
| assetId | uint256 | undefined |
| approved | bool | undefined |

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

### totalSupply

```solidity
function totalSupply(uint256 assetId) external view returns (uint256 totalSupply)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| assetId | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| totalSupply | uint256 | undefined |

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

### transferMultiple

```solidity
function transferMultiple(address from, address[] tos, uint256 assetId, uint256[] shares) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| from | address | undefined |
| tos | address[] | undefined |
| assetId | uint256 | undefined |
| shares | uint256[] | undefined |

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

### wrappedNative

```solidity
function wrappedNative() external view returns (address wrappedNative)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| wrappedNative | address | undefined |




