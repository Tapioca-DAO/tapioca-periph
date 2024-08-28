// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.22;

// External
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

// Tapioca
import {OracleUniSolo, OracleUniSoloConstructorData} from "./OracleUniSolo.sol";
import {ITapiocaOracle} from "tapioca-periph/interfaces/periph/ITapiocaOracle.sol";

contract SeerUniSolo is ITapiocaOracle, OracleUniSolo {
    string public _name;
    string public _symbol;
    uint8 public immutable override decimals;

    /// @notice Constructor for an oracle using both Uniswap to read from
    /// @param __name Name of the oracle
    /// @param __symbol Symbol of the oracle
    /// @param _decimals Number of decimals of the oracle
    /// @param _oracleUniSoloConstructorData.addressInAndOutUni List of 2 addresses representing the in-currency address and the out-currency address
    /// @param _oracleUniSoloConstructorData._circuitUniswap Path of the Uniswap pools
    /// @param _oracleUniSoloConstructorData._circuitUniIsMultiplied Whether we should multiply or divide by this rate in the path
    /// @param _oracleUniSoloConstructorData._twapPeriod Time weighted average window for all Uniswap pools
    /// @param _oracleUniSoloConstructorData.observationLength Number of observations that each pool should have stored
    /// @param _oracleUniSoloConstructorData.guardians List of governor or guardian addresses
    /// @param _oracleUniSoloConstructorData._description Description of the assets concerned by the oracle
    /// @param _oracleUniSoloConstructorData._sequencerUptimeFeed Address of the sequencer uptime feed, 0x0 if not used
    /// @param _oracleUniSoloConstructorData._admin Address of the admin of the oracle
    constructor(
        string memory __name,
        string memory __symbol,
        uint8 _decimals,
        OracleUniSoloConstructorData memory _oracleUniSoloConstructorData
    ) OracleUniSolo(_oracleUniSoloConstructorData) {
        _name = __name;
        _symbol = __symbol;
        decimals = _decimals;

        _grantRole(SEQUENCER_ROLE, _oracleUniSoloConstructorData._admin);
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
