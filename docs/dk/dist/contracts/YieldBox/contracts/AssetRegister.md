# AssetRegister









## Methods

### assetCount

```solidity
function assetCount() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### assets

```solidity
function assets(uint256) external view returns (enum TokenType tokenType, address contractAddress, contract IStrategy strategy, uint256 tokenId)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| tokenType | enum TokenType | undefined |
| contractAddress | address | undefined |
| strategy | contract IStrategy | undefined |
| tokenId | uint256 | undefined |

### balanceOf

```solidity
function balanceOf(address, uint256) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |
| _1 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### balanceOfBatch

```solidity
function balanceOfBatch(address[] owners, uint256[] ids) external view returns (uint256[] balances)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| owners | address[] | undefined |
| ids | uint256[] | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| balances | uint256[] | undefined |

### ids

```solidity
function ids(enum TokenType, address, contract IStrategy, uint256) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | enum TokenType | undefined |
| _1 | address | undefined |
| _2 | contract IStrategy | undefined |
| _3 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### isApprovedForAll

```solidity
function isApprovedForAll(address, address) external view returns (bool)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |
| _1 | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### isApprovedForAsset

```solidity
function isApprovedForAsset(address, address, uint256) external view returns (bool)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |
| _1 | address | undefined |
| _2 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### registerAsset

```solidity
function registerAsset(enum TokenType tokenType, address contractAddress, contract IStrategy strategy, uint256 tokenId) external nonpayable returns (uint256 assetId)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenType | enum TokenType | undefined |
| contractAddress | address | undefined |
| strategy | contract IStrategy | undefined |
| tokenId | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| assetId | uint256 | undefined |

### safeBatchTransferFrom

```solidity
function safeBatchTransferFrom(address from, address to, uint256[] ids, uint256[] values, bytes data) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| from | address | undefined |
| to | address | undefined |
| ids | uint256[] | undefined |
| values | uint256[] | undefined |
| data | bytes | undefined |

### safeTransferFrom

```solidity
function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes data) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| from | address | undefined |
| to | address | undefined |
| id | uint256 | undefined |
| value | uint256 | undefined |
| data | bytes | undefined |

### setApprovalForAll

```solidity
function setApprovalForAll(address operator, bool approved) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| operator | address | undefined |
| approved | bool | undefined |

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

### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceID) external pure returns (bool)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| interfaceID | bytes4 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### totalSupply

```solidity
function totalSupply(uint256) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### uri

```solidity
function uri(uint256) external view returns (string)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined |



## Events

### ApprovalForAll

```solidity
event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _owner `indexed` | address | undefined |
| _operator `indexed` | address | undefined |
| _approved  | bool | undefined |

### ApprovalForAsset

```solidity
event ApprovalForAsset(address indexed sender, address indexed operator, uint256 assetId, bool approved)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| sender `indexed` | address | undefined |
| operator `indexed` | address | undefined |
| assetId  | uint256 | undefined |
| approved  | bool | undefined |

### AssetRegistered

```solidity
event AssetRegistered(enum TokenType indexed tokenType, address indexed contractAddress, contract IStrategy strategy, uint256 indexed tokenId, uint256 assetId)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenType `indexed` | enum TokenType | undefined |
| contractAddress `indexed` | address | undefined |
| strategy  | contract IStrategy | undefined |
| tokenId `indexed` | uint256 | undefined |
| assetId  | uint256 | undefined |

### TransferBatch

```solidity
event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _operator `indexed` | address | undefined |
| _from `indexed` | address | undefined |
| _to `indexed` | address | undefined |
| _ids  | uint256[] | undefined |
| _values  | uint256[] | undefined |

### TransferSingle

```solidity
event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _operator `indexed` | address | undefined |
| _from `indexed` | address | undefined |
| _to `indexed` | address | undefined |
| _id  | uint256 | undefined |
| _value  | uint256 | undefined |

### URI

```solidity
event URI(string _value, uint256 indexed _id)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _value  | string | undefined |
| _id `indexed` | uint256 | undefined |



