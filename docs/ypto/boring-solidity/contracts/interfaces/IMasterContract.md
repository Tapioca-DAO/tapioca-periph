# IMasterContract









## Methods

### init

```solidity
function init(bytes data) external payable
```

Init function that gets called from `BoringFactory.deploy`. Also kown as the constructor for cloned contracts. Any ETH send to `BoringFactory.deploy` ends up here.



#### Parameters

| Name | Type | Description |
|---|---|---|
| data | bytes | Can be abi encoded arguments or anything else. |




