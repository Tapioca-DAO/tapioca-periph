# BaseBoringBatchable









## Methods

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




