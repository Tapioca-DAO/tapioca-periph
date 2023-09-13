# YieldBox

*BoringCrypto, Keno*

> YieldBox

The YieldBox is a vault for tokens. The stored tokens can assigned to strategies. Yield from this will go to the token depositors. Any funds transfered directly onto the YieldBox will be lost, use the deposit function instead.



## Methods

### DOMAIN_SEPARATOR

```solidity
function DOMAIN_SEPARATOR() external view returns (bytes32)
```



*See {IERC20Permit-DOMAIN_SEPARATOR}.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### amountOf

```solidity
function amountOf(address user, uint256 assetId) external view returns (uint256 amount)
```



*Helper function represent the balance in `token` amount for a `user` for an `asset`.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| user | address | The `user` to get the amount for. |
| assetId | uint256 | The id of the asset. |

#### Returns

| Name | Type | Description |
|---|---|---|
| amount | uint256 | undefined |

### assetCount

```solidity
function assetCount() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### assetTotals

```solidity
function assetTotals(uint256 assetId) external view returns (uint256 totalShare, uint256 totalAmount)
```

Helper function to return totals for an asset



#### Parameters

| Name | Type | Description |
|---|---|---|
| assetId | uint256 | The regierestered asset id |

#### Returns

| Name | Type | Description |
|---|---|---|
| totalShare | uint256 | The total amount for asset represented in shares |
| totalAmount | uint256 | The total amount for asset |

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

### batch

```solidity
function batch(bytes[] calls, bool revertOnFail) external payable
```

Allows batched call to self (this contract).



#### Parameters

| Name | Type | Description |
|---|---|---|
| calls | bytes[] | An array of inputs for each call. |
| revertOnFail | bool | If True then reverts after a failed call and stops doing further calls. |

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

### decimals

```solidity
function decimals(uint256 assetId) external view returns (uint8)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| assetId | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint8 | undefined |

### deposit

```solidity
function deposit(enum TokenType tokenType, address contractAddress, contract IStrategy strategy, uint256 tokenId, address from, address to, uint256 amount, uint256 share) external nonpayable returns (uint256 amountOut, uint256 shareOut)
```

Helper function to register &amp; deposit an asset



#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenType | enum TokenType | Registration token type. |
| contractAddress | address | Token address. |
| strategy | contract IStrategy | Asset&#39;s strategy address. |
| tokenId | uint256 | Registration token id. |
| from | address | which user to pull the tokens. |
| to | address | which account to push the tokens. |
| amount | uint256 | amount to deposit. |
| share | uint256 | amount to deposit represented in shares. |

#### Returns

| Name | Type | Description |
|---|---|---|
| amountOut | uint256 | The amount deposited. |
| shareOut | uint256 | The deposited amount repesented in shares. |

### depositAsset

```solidity
function depositAsset(uint256 assetId, address from, address to, uint256 amount, uint256 share) external nonpayable returns (uint256 amountOut, uint256 shareOut)
```

Deposit an amount of `token` represented in either `amount` or `share`.



#### Parameters

| Name | Type | Description |
|---|---|---|
| assetId | uint256 | The id of the asset. |
| from | address | which account to pull the tokens. |
| to | address | which account to push the tokens. |
| amount | uint256 | Token amount in native representation to deposit. |
| share | uint256 | Token amount represented in shares to deposit. Takes precedence over `amount`. |

#### Returns

| Name | Type | Description |
|---|---|---|
| amountOut | uint256 | The amount deposited. |
| shareOut | uint256 | The deposited amount repesented in shares. |

### depositETH

```solidity
function depositETH(contract IStrategy strategy, address to, uint256 amount) external payable returns (uint256 amountOut, uint256 shareOut)
```

Helper function to register &amp; deposit ETH



#### Parameters

| Name | Type | Description |
|---|---|---|
| strategy | contract IStrategy | Asset&#39;s strategy address. |
| to | address | undefined |
| amount | uint256 | amount to deposit. |

#### Returns

| Name | Type | Description |
|---|---|---|
| amountOut | uint256 | The amount deposited. |
| shareOut | uint256 | The deposited amount repesented in shares. |

### depositETHAsset

```solidity
function depositETHAsset(uint256 assetId, address to, uint256 amount) external payable returns (uint256 amountOut, uint256 shareOut)
```

Deposit ETH asset



#### Parameters

| Name | Type | Description |
|---|---|---|
| assetId | uint256 | The id of the asset. |
| to | address | which account to push the tokens. |
| amount | uint256 | ETH amount to deposit. |

#### Returns

| Name | Type | Description |
|---|---|---|
| amountOut | uint256 | The amount deposited. |
| shareOut | uint256 | The deposited amount repesented in shares. |

### depositNFTAsset

```solidity
function depositNFTAsset(uint256 assetId, address from, address to) external nonpayable returns (uint256 amountOut, uint256 shareOut)
```

Deposit an NFT asset



#### Parameters

| Name | Type | Description |
|---|---|---|
| assetId | uint256 | The id of the asset. |
| from | address | which account to pull the tokens. |
| to | address | which account to push the tokens. |

#### Returns

| Name | Type | Description |
|---|---|---|
| amountOut | uint256 | The amount deposited. |
| shareOut | uint256 | The deposited amount repesented in shares. |

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

### name

```solidity
function name(uint256 assetId) external view returns (string)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| assetId | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined |

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

### nonces

```solidity
function nonces(address owner) external view returns (uint256)
```



*See {IERC20Permit-nonces}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| owner | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### onERC1155BatchReceived

```solidity
function onERC1155BatchReceived(address, address, uint256[], uint256[], bytes) external pure returns (bytes4)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |
| _1 | address | undefined |
| _2 | uint256[] | undefined |
| _3 | uint256[] | undefined |
| _4 | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes4 | undefined |

### onERC1155Received

```solidity
function onERC1155Received(address, address, uint256, uint256, bytes) external pure returns (bytes4)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |
| _1 | address | undefined |
| _2 | uint256 | undefined |
| _3 | uint256 | undefined |
| _4 | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes4 | undefined |

### onERC721Received

```solidity
function onERC721Received(address, address, uint256, bytes) external pure returns (bytes4)
```





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

### permit

```solidity
function permit(address owner, address spender, uint256 assetId, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| owner | address | undefined |
| spender | address | undefined |
| assetId | uint256 | undefined |
| deadline | uint256 | undefined |
| v | uint8 | undefined |
| r | bytes32 | undefined |
| s | bytes32 | undefined |

### permitAll

```solidity
function permitAll(address owner, address spender, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| owner | address | undefined |
| spender | address | undefined |
| deadline | uint256 | undefined |
| v | uint8 | undefined |
| r | bytes32 | undefined |
| s | bytes32 | undefined |

### permitToken

```solidity
function permitToken(contract IERC20 token, address from, address to, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external nonpayable
```

Call wrapper that performs `ERC20.permit` on `token`. Lookup `IERC20.permit`.



#### Parameters

| Name | Type | Description |
|---|---|---|
| token | contract IERC20 | undefined |
| from | address | undefined |
| to | address | undefined |
| amount | uint256 | undefined |
| deadline | uint256 | undefined |
| v | uint8 | undefined |
| r | bytes32 | undefined |
| s | bytes32 | undefined |

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

Update approval status for an operator



#### Parameters

| Name | Type | Description |
|---|---|---|
| operator | address | The address approved to perform actions on your behalf |
| approved | bool | True/False |

### setApprovalForAsset

```solidity
function setApprovalForAsset(address operator, uint256 assetId, bool approved) external nonpayable
```

Update approval status for an operator and for a specific asset



#### Parameters

| Name | Type | Description |
|---|---|---|
| operator | address | The address approved to perform actions on your behalf |
| assetId | uint256 | The asset id  to update approval status for |
| approved | bool | True/False |

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

### symbol

```solidity
function symbol(uint256 assetId) external view returns (string)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| assetId | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined |

### toAmount

```solidity
function toAmount(uint256 assetId, uint256 share, bool roundUp) external view returns (uint256 amount)
```



*Helper function represent shares back into the `token` amount.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| assetId | uint256 | The id of the asset. |
| share | uint256 | The amount of shares. |
| roundUp | bool | If the result should be rounded up. |

#### Returns

| Name | Type | Description |
|---|---|---|
| amount | uint256 | The share amount back into native representation. |

### toShare

```solidity
function toShare(uint256 assetId, uint256 amount, bool roundUp) external view returns (uint256 share)
```



*Helper function to represent an `amount` of `token` in shares.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| assetId | uint256 | The id of the asset. |
| amount | uint256 | The `token` amount. |
| roundUp | bool | If the result `share` should be rounded up. |

#### Returns

| Name | Type | Description |
|---|---|---|
| share | uint256 | The token amount represented in shares. |

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

### transfer

```solidity
function transfer(address from, address to, uint256 assetId, uint256 share) external nonpayable
```

Transfer shares from a user account to another one.



#### Parameters

| Name | Type | Description |
|---|---|---|
| from | address | which user to pull the tokens. |
| to | address | which user to push the tokens. |
| assetId | uint256 | The id of the asset. |
| share | uint256 | The amount of `token` in shares. |

### transferMultiple

```solidity
function transferMultiple(address from, address[] tos, uint256 assetId, uint256[] shares) external nonpayable
```

Transfer shares from a user account to multiple other ones.



#### Parameters

| Name | Type | Description |
|---|---|---|
| from | address | which user to pull the tokens. |
| tos | address[] | The receivers of the tokens. |
| assetId | uint256 | The id of the asset. |
| shares | uint256[] | The amount of `token` in shares for each receiver in `tos`. |

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
function uri(uint256 assetId) external view returns (string)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| assetId | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined |

### uriBuilder

```solidity
function uriBuilder() external view returns (contract YieldBoxURIBuilder)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract YieldBoxURIBuilder | undefined |

### withdraw

```solidity
function withdraw(uint256 assetId, address from, address to, uint256 amount, uint256 share) external nonpayable returns (uint256 amountOut, uint256 shareOut)
```

Withdraws an amount of `token` from a user account.



#### Parameters

| Name | Type | Description |
|---|---|---|
| assetId | uint256 | The id of the asset. |
| from | address | which user to pull the tokens. |
| to | address | which user to push the tokens. |
| amount | uint256 | of tokens. Either one of `amount` or `share` needs to be supplied. |
| share | uint256 | Like above, but `share` takes precedence over `amount`. |

#### Returns

| Name | Type | Description |
|---|---|---|
| amountOut | uint256 | undefined |
| shareOut | uint256 | undefined |

### wrappedNative

```solidity
function wrappedNative() external view returns (contract IWrappedNative)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract IWrappedNative | undefined |



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

### Deposited

```solidity
event Deposited(address indexed sender, address indexed from, address indexed to, uint256 assetId, uint256 amountIn, uint256 shareIn, uint256 amountOut, uint256 shareOut, bool isNFT)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| sender `indexed` | address | undefined |
| from `indexed` | address | undefined |
| to `indexed` | address | undefined |
| assetId  | uint256 | undefined |
| amountIn  | uint256 | undefined |
| shareIn  | uint256 | undefined |
| amountOut  | uint256 | undefined |
| shareOut  | uint256 | undefined |
| isNFT  | bool | undefined |

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

### Withdraw

```solidity
event Withdraw(address indexed sender, address indexed from, address indexed to, uint256 assetId, uint256 amountIn, uint256 shareIn, uint256 amountOut, uint256 shareOut)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| sender `indexed` | address | undefined |
| from `indexed` | address | undefined |
| to `indexed` | address | undefined |
| assetId  | uint256 | undefined |
| amountIn  | uint256 | undefined |
| shareIn  | uint256 | undefined |
| amountOut  | uint256 | undefined |
| shareOut  | uint256 | undefined |



