# YieldBoxPermit





Modification of the OpenZeppelin ERC20Permit contract to support ERC721 tokens. OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/extensions/draft-ERC20Permit.sol).

*Implementation of the ERC-4494 Permit extension allowing approvals to be made via signatures, as defined in https://eips.ethereum.org/EIPS/eip-4494[EIP-4494]. Adds the {permit} method, which can be used to change an account&#39;s ERC721 allowance (see {IERC721-allowance}) by presenting a message signed by the account. By not relying on `{IERC721-approve}`, the token holder account doesn&#39;t need to send a transaction, and thus is not required to hold Ether at all.*

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

### revoke

```solidity
function revoke(address owner, address spender, uint256 assetId, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external nonpayable
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

### revokeAll

```solidity
function revokeAll(address owner, address spender, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external nonpayable
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




