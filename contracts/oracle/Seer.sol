// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

// Tapioca
import {ITapiocaOracle, ISeerQuery} from "tapioca-periph/interfaces/periph/ITapiocaOracle.sol";
import {OracleMulti, OracleMultiConstructorData} from "./OracleMulti.sol";

contract Seer is ITapiocaOracle, OracleMulti {
    string public _name;
    string public _symbol;
    uint8 public immutable override decimals;

    /**
     * @notice Constructor for the oracle using a mix of ChainLink and Uniswap
     * @param __name Name of the oracle
     * @param __symbol Symbol of the oracle
     * @param _decimals Number of decimals of the oracle
     * @param _oracleMultiConstructorData.addressInAndOutUni Array of contract addresses used the Uniswap pool
     * @param _oracleMultiConstructorData._circuitUniswap Array of Uniswap pool addresses to use
     * @param _oracleMultiConstructorData._circuitUniIsMultiplied Array of booleans indicating whether we should multiply or divide by the Uniswap rate the
     * in-currency amount to get the out-currency amount
     * @param _oracleMultiConstructorData._twapPeriod Time weighted average window for all Uniswap pools, in seconds
     * @param _oracleMultiConstructorData.observationLength Number of observations that each pool should have stored
     * @param _oracleMultiConstructorData._uniFinalCurrency Whether we need to use the last ChainLink oracle to convert to another
     * currency / asset (Forex for instance)
     * @param _oracleMultiConstructorData._circuitChainlink ChainLink pool addresses put in order
     * @param _oracleMultiConstructorData._circuitChainIsMultiplied Whether we should multiply or divide by this rate
     * @param _oracleMultiConstructorData._stalePeriod Time in seconds after which the oracle is considered stale
     * @param _oracleMultiConstructorData.guardians List of governor or guardian addresses
     * @param _oracleMultiConstructorData._description Description of the assets concerned by the oracle
     * @param _oracleMultiConstructorData._sequencerUptimeFeed Address of the sequencer uptime feed, 0x0 if not used
     * @param _oracleMultiConstructorData._admin Address of the admin of the oracle
     */
    constructor(
        string memory __name,
        string memory __symbol,
        uint8 _decimals,
        OracleMultiConstructorData memory _oracleMultiConstructorData
    ) OracleMulti(_oracleMultiConstructorData) {
        _name = __name;
        _symbol = __symbol;
        decimals = _decimals;
    }

    /// @notice Get the latest exchange rate.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function get(bytes calldata data) external virtual nonReentrant returns (bool success, uint256 rate) {
        // Checking whether the sequencer is up
        _sequencerBeatCheck();

        (uint256 uniswap, uint256 chainlink) = _readAll(inBase);
        if (uniFinalCurrency > 0) {
            return (true, uniswap);
        }

        if (data.length > 0) {
            ISeerQuery memory query = abi.decode(data, (ISeerQuery));
            if (query.useHigh) {
                return (true, uniswap > chainlink ? uniswap : chainlink);
            }
        }

        return (true, uniswap < chainlink ? uniswap : chainlink);
    }

    /// @notice Check the last exchange rate without any state changes.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function peek(bytes calldata data) external view virtual returns (bool success, uint256 rate) {
        (uint256 uniswap, uint256 chainlink) = _readAll(inBase);
        if (uniFinalCurrency > 0) {
            return (true, uniswap);
        }

        if (data.length > 0) {
            ISeerQuery memory query = abi.decode(data, (ISeerQuery));
            if (query.useHigh) {
                return (true, uniswap > chainlink ? uniswap : chainlink);
            }
        }

        return (true, uniswap < chainlink ? uniswap : chainlink);
    }

    /// @notice Check the current spot exchange rate without any state changes.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return rate The rate of the requested asset / pair / pool.
    function peekSpot(bytes calldata data) external view virtual returns (uint256 rate) {
        (uint256 uniswap, uint256 chainlink) = _readAll(inBase);
        if (uniFinalCurrency > 0) {
            return  uniswap;
        }

        if (data.length > 0) {
            ISeerQuery memory query = abi.decode(data, (ISeerQuery));
            if (query.useHigh) {
                return uniswap > chainlink ? uniswap : chainlink;
            }
        }

        return uniswap < chainlink ? uniswap : chainlink;
    }

    /// @notice Returns a human readable (short) name about this oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return (string) A human readable symbol name about this oracle.
    function symbol(bytes calldata) external view returns (string memory) {
        return _symbol;
    }

    /// @notice Returns a human readable name about this oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return (string) A human readable name about this oracle.
    function name(bytes calldata) external view returns (string memory) {
        return _name;
    }
}
