# ISendFrom









## Methods

### triggerSendFrom

```solidity
function triggerSendFrom(address from, uint16 dstChainId, bytes32 toAddress, uint256 amount, ICommonOFT.LzCallParams callParams) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| from | address | undefined |
| dstChainId | uint16 | undefined |
| toAddress | bytes32 | undefined |
| amount | uint256 | undefined |
| callParams | ICommonOFT.LzCallParams | undefined |

### triggerSendFromWithParams

```solidity
function triggerSendFromWithParams(address from, uint16 lzDstChainId, bytes32 to, uint256 amount, ICommonOFT.LzCallParams callParams, bool unwrap, ICommonData.IApproval[] approvals) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| from | address | undefined |
| lzDstChainId | uint16 | undefined |
| to | bytes32 | undefined |
| amount | uint256 | undefined |
| callParams | ICommonOFT.LzCallParams | undefined |
| unwrap | bool | undefined |
| approvals | ICommonData.IApproval[] | undefined |

### useCustomAdapterParams

```solidity
function useCustomAdapterParams() external view returns (bool)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |




