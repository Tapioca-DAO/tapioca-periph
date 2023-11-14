# IUSDO









## Methods

### addFlashloanFee

```solidity
function addFlashloanFee(uint256 _fee) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _fee | uint256 | undefined |

### allowance

```solidity
function allowance(address owner, address spender) external view returns (uint256)
```



*Returns the remaining number of tokens that `spender` will be allowed to spend on behalf of `owner` through {transferFrom}. This is zero by default. This value changes when {approve} or {transferFrom} are called.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| owner | address | undefined |
| spender | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### approve

```solidity
function approve(address spender, uint256 amount) external nonpayable returns (bool)
```



*Sets `amount` as the allowance of `spender` over the caller&#39;s tokens. Returns a boolean value indicating whether the operation succeeded. IMPORTANT: Beware that changing an allowance with this method brings the risk that someone may use both the old and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729 Emits an {Approval} event.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| spender | address | undefined |
| amount | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### balanceOf

```solidity
function balanceOf(address account) external view returns (uint256)
```



*Returns the amount of tokens owned by `account`.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### burn

```solidity
function burn(address _from, uint256 _amount) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _from | address | undefined |
| _amount | uint256 | undefined |

### decimals

```solidity
function decimals() external view returns (uint8)
```



*Returns the decimals places of the token.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint8 | undefined |

### mint

```solidity
function mint(address _to, uint256 _amount) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _to | address | undefined |
| _amount | uint256 | undefined |

### name

```solidity
function name() external view returns (string)
```



*Returns the name of the token.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined |

### paused

```solidity
function paused() external view returns (bool)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### removeAsset

```solidity
function removeAsset(address from, address to, uint16 lzDstChainId, address zroPaymentAddress, bytes adapterParams, ICommonData.ICommonExternalContracts externalData, IUSDOBase.IRemoveAndRepay removeAndRepayData, ICommonData.IApproval[] approvals, ICommonData.IApproval[] revokes) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| from | address | undefined |
| to | address | undefined |
| lzDstChainId | uint16 | undefined |
| zroPaymentAddress | address | undefined |
| adapterParams | bytes | undefined |
| externalData | ICommonData.ICommonExternalContracts | undefined |
| removeAndRepayData | IUSDOBase.IRemoveAndRepay | undefined |
| approvals | ICommonData.IApproval[] | undefined |
| revokes | ICommonData.IApproval[] | undefined |

### sendAndLendOrRepay

```solidity
function sendAndLendOrRepay(address _from, address _to, uint16 lzDstChainId, address zroPaymentAddress, IUSDOBase.ILendOrRepayParams lendParams, ICommonData.IApproval[] approvals, ICommonData.IApproval[] revokes, ICommonData.IWithdrawParams withdrawParams, bytes adapterParams) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _from | address | undefined |
| _to | address | undefined |
| lzDstChainId | uint16 | undefined |
| zroPaymentAddress | address | undefined |
| lendParams | IUSDOBase.ILendOrRepayParams | undefined |
| approvals | ICommonData.IApproval[] | undefined |
| revokes | ICommonData.IApproval[] | undefined |
| withdrawParams | ICommonData.IWithdrawParams | undefined |
| adapterParams | bytes | undefined |

### sendForLeverage

```solidity
function sendForLeverage(uint256 amount, address leverageFor, IUSDOBase.ILeverageLZData lzData, IUSDOBase.ILeverageSwapData swapData, IUSDOBase.ILeverageExternalContractsData externalData) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| amount | uint256 | undefined |
| leverageFor | address | undefined |
| lzData | IUSDOBase.ILeverageLZData | undefined |
| swapData | IUSDOBase.ILeverageSwapData | undefined |
| externalData | IUSDOBase.ILeverageExternalContractsData | undefined |

### setFlashloanHelper

```solidity
function setFlashloanHelper(address _helper) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _helper | address | undefined |

### symbol

```solidity
function symbol() external view returns (string)
```



*Returns the symbol of the token.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined |

### totalSupply

```solidity
function totalSupply() external view returns (uint256)
```



*Returns the amount of tokens in existence.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### transfer

```solidity
function transfer(address to, uint256 amount) external nonpayable returns (bool)
```



*Moves `amount` tokens from the caller&#39;s account to `to`. Returns a boolean value indicating whether the operation succeeded. Emits a {Transfer} event.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| to | address | undefined |
| amount | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### transferFrom

```solidity
function transferFrom(address from, address to, uint256 amount) external nonpayable returns (bool)
```



*Moves `amount` tokens from `from` to `to` using the allowance mechanism. `amount` is then deducted from the caller&#39;s allowance. Returns a boolean value indicating whether the operation succeeded. Emits a {Transfer} event.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| from | address | undefined |
| to | address | undefined |
| amount | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### triggerApproveOrRevoke

```solidity
function triggerApproveOrRevoke(uint16 lzDstChainId, ICommonOFT.LzCallParams lzCallParams, ICommonData.IApproval[] approvals) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| lzDstChainId | uint16 | undefined |
| lzCallParams | ICommonOFT.LzCallParams | undefined |
| approvals | ICommonData.IApproval[] | undefined |

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



## Events

### Approval

```solidity
event Approval(address indexed owner, address indexed spender, uint256 value)
```



*Emitted when the allowance of a `spender` for an `owner` is set by a call to {approve}. `value` is the new allowance.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| owner `indexed` | address | undefined |
| spender `indexed` | address | undefined |
| value  | uint256 | undefined |

### Transfer

```solidity
event Transfer(address indexed from, address indexed to, uint256 value)
```



*Emitted when `value` tokens are moved from one account (`from`) to another (`to`). Note that `value` may be zero.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| from `indexed` | address | undefined |
| to `indexed` | address | undefined |
| value  | uint256 | undefined |



