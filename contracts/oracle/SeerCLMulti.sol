// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.22;

// External
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Tapioca
import {OracleChainlinkMulti, OracleChainlinkMultiConstructorData} from "./OracleChainlinkMulti.sol";
import {ITapiocaOracle} from "tapioca-periph/interfaces/periph/ITapiocaOracle.sol";

contract SeerCLMulti is ITapiocaOracle, OracleChainlinkMulti, ReentrancyGuard {
    string public _name;
    string public _symbol;
    uint8 public immutable override decimals;

    /// @notice Constructor for the oracle using a single Chainlink pool
    /// @param __name Name of the oracle
    /// @param __symbol Symbol of the oracle
    /// @param _decimals Number of decimals of the oracle
    /// @param _oracleChainlinkConstructorData._poolChainlink Chainlink pool address
    /// @param _oracleChainlinkConstructorData._isChainlinkMultiplied Whether we should multiply or divide by the Chainlink rate the
    /// in-currency amount to get the out-currency amount
    /// @param _oracleChainlinkConstructorData._description Description of the assets concerned by the oracle
    /// @param _oracleChainlinkConstructorData._sequencerUptimeFeed Address of the sequencer uptime feed, 0x0 if not used
    /// @param _oracleChainlinkConstructorData._admin Address of the admin of the oracle
    constructor(
        string memory __name,
        string memory __symbol,
        uint8 _decimals,
        OracleChainlinkMultiConstructorData memory _oracleChainlinkConstructorData
    ) OracleChainlinkMulti(_oracleChainlinkConstructorData) {
        _name = __name;
        _symbol = __symbol;
        decimals = _decimals;

        _grantRole(SEQUENCER_ROLE, _oracleChainlinkConstructorData._admin);
    }

    /// @notice Get the latest exchange rate.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function get(bytes calldata) external virtual nonReentrant returns (bool success, uint256 rate) {
        // Checking whether the sequencer is up
        _sequencerBeatCheck();

        (, rate) = _readAll(inBase);
        success = true;
    }

    /// @notice Check the last exchange rate without any state changes.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function peek(bytes calldata) external view virtual returns (bool success, uint256 rate) {
        (, rate) = _readAll(inBase);
        success = true;
    }

    /// @notice Check the current spot exchange rate without any state changes.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return rate The rate of the requested asset / pair / pool.
    function peekSpot(bytes calldata) external view virtual returns (uint256 rate) {
        (, rate) = _readAll(inBase);
        return rate;
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
