# TapiocaDeployer

*https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Create2.sol*







## Methods

### computeAddress

```solidity
function computeAddress(bytes32 salt, bytes32 bytecodeHash) external view returns (address)
```



*Returns the address where a contract will be stored if deployed via {deploy}. Any change in the `bytecodeHash` or `salt` will result in a new destination address.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| salt | bytes32 | undefined |
| bytecodeHash | bytes32 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### computeAddress

```solidity
function computeAddress(bytes32 salt, bytes32 bytecodeHash, address deployer) external pure returns (address addr)
```



*Returns the address where a contract will be stored if deployed via {deploy} from a contract located at `deployer`. If `deployer` is this contract&#39;s address, returns the same value as {computeAddress}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| salt | bytes32 | undefined |
| bytecodeHash | bytes32 | undefined |
| deployer | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| addr | address | undefined |

### deploy

```solidity
function deploy(uint256 amount, bytes32 salt, bytes bytecode) external payable returns (address addr)
```



*Deploys a contract using `CREATE2`. The address where the contract will be deployed can be known in advance via {computeAddress}. The bytecode for a contract can be obtained from Solidity with `type(contractName).creationCode`. Requirements: - `bytecode` must not be empty. - `salt` must have not been used for `bytecode` already. - the factory must have a balance of at least `amount`. - if `amount` is non-zero, `bytecode` must have a `payable` constructor.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| amount | uint256 | undefined |
| salt | bytes32 | undefined |
| bytecode | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| addr | address | undefined |




