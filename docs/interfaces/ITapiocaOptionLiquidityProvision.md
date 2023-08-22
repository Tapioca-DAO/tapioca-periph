# ITapiocaOptionLiquidityProvision









## Methods

### activeSingularities

```solidity
function activeSingularities(address singularity) external view returns (uint256 sglAssetId, uint256 totalDeposited, uint256 poolWeight)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| singularity | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| sglAssetId | uint256 | undefined |
| totalDeposited | uint256 | undefined |
| poolWeight | uint256 | undefined |

### lock

```solidity
function lock(address to, address singularity, uint128 lockDuration, uint128 amount) external nonpayable returns (uint256 tokenId)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| to | address | undefined |
| singularity | address | undefined |
| lockDuration | uint128 | undefined |
| amount | uint128 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| tokenId | uint256 | undefined |

### unlock

```solidity
function unlock(uint256 tokenId, address singularity, address to) external nonpayable returns (uint256 sharesOut)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenId | uint256 | undefined |
| singularity | address | undefined |
| to | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| sharesOut | uint256 | undefined |

### yieldBox

```solidity
function yieldBox() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |




