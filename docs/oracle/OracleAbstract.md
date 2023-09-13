# OracleAbstract

*Angle Core Team*

> OracleAbstract

Abstract Oracle contract that contains some of the functions that are used across all oracle contracts

*This is the most generic form of oracle contractA rate gives the price of the out-currency with respect to the in-currency in base `BASE`. For instance if the out-currency is ETH worth 1000 USD, then the rate ETH-USD is 10**21*

## Methods

### BASE

```solidity
function BASE() external view returns (uint256)
```

Base used for computation




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### description

```solidity
function description() external view returns (bytes32)
```

Description of the assets concerned by the oracle and the price outputted




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### inBase

```solidity
function inBase() external view returns (uint256)
```

Unit of the in-currency




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### read

```solidity
function read() external view returns (uint256 rate)
```

Reads one of the rates from the circuits given

*By default if the oracle involves a Uniswap price and a Chainlink price this function will return the Uniswap priceThe rate returned is expressed with base `BASE` (and not the base of the out-currency)*


#### Returns

| Name | Type | Description |
|---|---|---|
| rate | uint256 | The current rate between the in-currency and out-currency |

### readAll

```solidity
function readAll() external view returns (uint256, uint256)
```

Read rates from the circuit of both Uniswap and Chainlink if there are both circuits else returns twice the same price

*The rate returned is expressed with base `BASE` (and not the base of the out-currency)*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | Return all available rates (Chainlink and Uniswap) with the lowest rate returned first. |
| _1 | uint256 | undefined |

### readLower

```solidity
function readLower() external view returns (uint256 rate)
```

Reads rates from the circuit of both Uniswap and Chainlink if there are both circuits and returns either the highest of both rates or the lowest

*If there is only one rate computed in an oracle contract, then the only rate is returned regardless of the value of the `lower` parameterThe rate returned is expressed with base `BASE` (and not the base of the out-currency)*


#### Returns

| Name | Type | Description |
|---|---|---|
| rate | uint256 | The lower rate between Chainlink and Uniswap |

### readQuote

```solidity
function readQuote(uint256 quoteAmount) external view returns (uint256)
```

Converts an in-currency quote amount to out-currency using one of the rates available in the oracle contract

*Like in the read function, if the oracle involves a Uniswap and a Chainlink price, this function will use the Uniswap price to compute the out quoteAmountThe rate returned is expressed with base `BASE` (and not the base of the out-currency)*

#### Parameters

| Name | Type | Description |
|---|---|---|
| quoteAmount | uint256 | Amount (in the input collateral) to be converted to be converted in out-currency |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | Quote amount in out-currency from the base amount in in-currency |

### readQuoteLower

```solidity
function readQuoteLower(uint256 quoteAmount) external view returns (uint256)
```

Returns the lowest quote amount between Uniswap and Chainlink circuits (if possible). If the oracle contract only involves a single feed, then this returns the value of this feed

*The rate returned is expressed with base `BASE` (and not the base of the out-currency)*

#### Parameters

| Name | Type | Description |
|---|---|---|
| quoteAmount | uint256 | Amount (in the input collateral) to be converted |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | The lowest quote amount from the quote amount in in-currency |

### readUpper

```solidity
function readUpper() external view returns (uint256 rate)
```

Reads rates from the circuit of both Uniswap and Chainlink if there are both circuits and returns either the highest of both rates or the lowest

*If there is only one rate computed in an oracle contract, then the only rate is returned regardless of the value of the `lower` parameterThe rate returned is expressed with base `BASE` (and not the base of the out-currency)*


#### Returns

| Name | Type | Description |
|---|---|---|
| rate | uint256 | The upper rate between Chainlink and Uniswap |




