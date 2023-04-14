# NativeTokenFactory

*BoringCrypto (@Boring_Crypto)*

> NativeTokenFactory

The NativeTokenFactory is a token factory to create ERC1155 tokens. This is used by YieldBox to create native tokens in YieldBox. These have many benefits: - low and predictable gas usage - simplified approval - no hidden features, all these tokens behave the same



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

### batchBurn

```solidity
function batchBurn(uint256 tokenId, address[] froms, uint256[] amounts) external nonpayable
```

Burns tokens. This is only useful to be used by an operator.



#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenId | uint256 | The token to be burned. |
| froms | address[] | The accounts to burn tokens from. |
| amounts | uint256[] | The amounts of tokens to burn. |

### batchMint

```solidity
function batchMint(uint256 tokenId, address[] tos, uint256[] amounts) external nonpayable
```

The `owner` can mint tokens. If a fixed supply is needed, the `owner` should mint the totalSupply and renounce ownership.

*If the tos array is longer than the amounts array there will be an out of bounds error. If the amounts array is longer, the extra amounts are simply ignored.For security reasons, operators are not allowed to mint. Only the actual owner can do this. Of course the owner can be a contract.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenId | uint256 | The token to be minted. |
| tos | address[] | The accounts to transfer the minted tokens to. |
| amounts | uint256[] | The amounts of tokens to mint. |

### burn

```solidity
function burn(uint256 tokenId, address from, uint256 amount) external nonpayable
```

Burns tokens. Only the holder of tokens can burn them or an approved operator.



#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenId | uint256 | The token to be burned. |
| from | address | undefined |
| amount | uint256 | The amount of tokens to burn. |

### claimOwnership

```solidity
function claimOwnership(uint256 tokenId) external nonpayable
```

Needs to be called by `pendingOwner` to claim ownership.



#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenId | uint256 | The `tokenId` of the token that ownership is claimed for. |

### createToken

```solidity
function createToken(string name, string symbol, uint8 decimals, string uri) external nonpayable returns (uint32 tokenId)
```

Create a new native token. This will be an ERC1155 token. If later it&#39;s needed as an ERC20 token it can be wrapped into an ERC20 token. Native support for ERC1155 tokens is growing though.



#### Parameters

| Name | Type | Description |
|---|---|---|
| name | string | The name of the token. |
| symbol | string | The symbol of the token. |
| decimals | uint8 | The number of decimals of the token (this is just for display purposes). Should be set to 18 in normal cases. |
| uri | string | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| tokenId | uint32 | undefined |

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

### mint

```solidity
function mint(uint256 tokenId, address to, uint256 amount) external nonpayable
```

The `owner` can mint tokens. If a fixed supply is needed, the `owner` should mint the totalSupply and renounce ownership.

*For security reasons, operators are not allowed to mint. Only the actual owner can do this. Of course the owner can be a contract.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenId | uint256 | The token to be minted. |
| to | address | The account to transfer the minted tokens to. |
| amount | uint256 | The amount of tokens to mint. |

### nativeTokens

```solidity
function nativeTokens(uint256) external view returns (string name, string symbol, uint8 decimals, string uri)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| name | string | undefined |
| symbol | string | undefined |
| decimals | uint8 | undefined |
| uri | string | undefined |

### owner

```solidity
function owner(uint256) external view returns (address)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### pendingOwner

```solidity
function pendingOwner(uint256) external view returns (address)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

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

### transferOwnership

```solidity
function transferOwnership(uint256 tokenId, address newOwner, bool direct, bool renounce) external nonpayable
```

Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner. Can only be invoked by the current `owner`.



#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenId | uint256 | The `tokenId` of the token that ownership whose ownership will be transferred/renounced. |
| newOwner | address | Address of the new owner. |
| direct | bool | True if `newOwner` should be set immediately. False if `newOwner` needs to use `claimOwnership`. |
| renounce | bool | Allows the `newOwner` to be `address(0)` if `direct` and `renounce` is True. Has no effect otherwise. |

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

### OwnershipTransferred

```solidity
event OwnershipTransferred(uint256 indexed tokenId, address indexed previousOwner, address indexed newOwner)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenId `indexed` | uint256 | undefined |
| previousOwner `indexed` | address | undefined |
| newOwner `indexed` | address | undefined |

### TokenCreated

```solidity
event TokenCreated(address indexed creator, string name, string symbol, uint8 decimals, uint256 tokenId)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| creator `indexed` | address | undefined |
| name  | string | undefined |
| symbol  | string | undefined |
| decimals  | uint8 | undefined |
| tokenId  | uint256 | undefined |

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



