# FixedPointMathLib

*Solady (https://github.com/vectorized/solady/blob/main/src/utils/FixedPointMathLib.sol)Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)*



Arithmetic library with operations for fixed-point numbers.





## Errors

### DivFailed

```solidity
error DivFailed()
```



*The division failed, as the denominator is zero.*


### DivWadFailed

```solidity
error DivWadFailed()
```



*The operation failed, either due to a multiplication overflow, or a division by a zero.*


### ExpOverflow

```solidity
error ExpOverflow()
```



*The operation failed, as the output exceeds the maximum value of uint256.*


### FactorialOverflow

```solidity
error FactorialOverflow()
```



*The operation failed, as the output exceeds the maximum value of uint256.*


### FullMulDivFailed

```solidity
error FullMulDivFailed()
```



*The full precision multiply-divide operation failed, either due to the result being larger than 256 bits, or a division by a zero.*


### LnWadUndefined

```solidity
error LnWadUndefined()
```



*The output is undefined, as the input is less-than-or-equal to zero.*


### Log2Undefined

```solidity
error Log2Undefined()
```



*The output is undefined, as the input is zero.*


### MulDivFailed

```solidity
error MulDivFailed()
```



*The multiply-divide operation failed, either due to a multiplication overflow, or a division by a zero.*


### MulWadFailed

```solidity
error MulWadFailed()
```



*The operation failed, due to an multiplication overflow.*



