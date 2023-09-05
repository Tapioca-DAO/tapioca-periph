# Cluster









## Methods

### isEditor

```solidity
function isEditor(address editor) external view returns (bool status)
```

returns true if an address is marked as an Editor

*editors can update contracts&#39; whitelist status*

#### Parameters

| Name | Type | Description |
|---|---|---|
| editor | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| status | bool | undefined |

### isWhitelisted

```solidity
function isWhitelisted(uint16 _lzChainId, address _addr) external view returns (bool)
```

returns the whitelist status of a contract



#### Parameters

| Name | Type | Description |
|---|---|---|
| _lzChainId | uint16 | LayerZero chain id |
| _addr | address | the contract&#39;s address |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### lzChainId

```solidity
function lzChainId() external view returns (uint16)
```

returns the current LayerZero chain id




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint16 | undefined |

### owner

```solidity
function owner() external view returns (address)
```



*Returns the address of the current owner.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### renounceOwnership

```solidity
function renounceOwnership() external nonpayable
```



*Leaves the contract without owner. It will not be possible to call `onlyOwner` functions anymore. Can only be called by the current owner. NOTE: Renouncing ownership will leave the contract without an owner, thereby removing any functionality that is only available to the owner.*


### transferOwnership

```solidity
function transferOwnership(address newOwner) external nonpayable
```



*Transfers ownership of the contract to a new account (`newOwner`). Can only be called by the current owner.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newOwner | address | undefined |

### updateContract

```solidity
function updateContract(uint16 _lzChainId, address _addr, bool _status) external nonpayable
```

updates the whitelist status of a contract

*can only be called by Editors or the Owner*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _lzChainId | uint16 | LayerZero chain id |
| _addr | address | the contract&#39;s address |
| _status | bool | the new whitelist status |

### updateEditor

```solidity
function updateEditor(address _editor, bool _status) external nonpayable
```

updates the editor status



#### Parameters

| Name | Type | Description |
|---|---|---|
| _editor | address | the editor&#39;s address |
| _status | bool | the new editor&#39;s status |

### updateLzChain

```solidity
function updateLzChain(uint16 _lzChainId) external nonpayable
```

updates LayerZero chain id



#### Parameters

| Name | Type | Description |
|---|---|---|
| _lzChainId | uint16 | the new LayerZero chain id |



## Events

### ContractUpdated

```solidity
event ContractUpdated(address indexed _contract, uint16 indexed _lzChainId, bool _oldStatus, bool _newStatus)
```

event emitted when a contract status is updated



#### Parameters

| Name | Type | Description |
|---|---|---|
| _contract `indexed` | address | undefined |
| _lzChainId `indexed` | uint16 | undefined |
| _oldStatus  | bool | undefined |
| _newStatus  | bool | undefined |

### EditorUpdated

```solidity
event EditorUpdated(address indexed _editor, bool _oldStatus, bool _newStatus)
```

event emitted when an editor status is updated



#### Parameters

| Name | Type | Description |
|---|---|---|
| _editor `indexed` | address | undefined |
| _oldStatus  | bool | undefined |
| _newStatus  | bool | undefined |

### LzChainUpdate

```solidity
event LzChainUpdate(uint256 _oldChain, uint256 _newChain)
```

event emitted when LZ chain id is updated



#### Parameters

| Name | Type | Description |
|---|---|---|
| _oldChain  | uint256 | undefined |
| _newChain  | uint256 | undefined |

### OwnershipTransferred

```solidity
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| previousOwner `indexed` | address | undefined |
| newOwner `indexed` | address | undefined |



