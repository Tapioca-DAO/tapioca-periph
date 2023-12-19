// SPDX-License-Identifier: GPL-3.0

// contracts/oracle/OracleChainlinkSingle.sol
pragma solidity 0.8.19;

import "./OracleChainlinkSingle.sol";
import "../interfaces/IOracle.sol" as ITOracle;

contract SeerCLSolo is ITOracle.IOracle, OracleChainlinkSingle {
    string public _name;
    string public _symbol;
    uint8 public immutable override decimals;

    /// @notice Constructor for the oracle using a single Chainlink pool
    /// @param __name Name of the oracle
    /// @param __symbol Symbol of the oracle
    /// @param _decimals Number of decimals of the oracle
    /// @param _poolChainlink Chainlink pool address
    /// @param _isChainlinkMultiplied Whether we should multiply or divide by the Chainlink rate the
    /// in-currency amount to get the out-currency amount
    /// @param _description Description of the assets concerned by the oracle
    /// @param _sequencerUptimeFeed Address of the sequencer uptime feed, 0x0 if not used
    /// @param _admin Address of the admin of the oracle
    constructor(
        string memory __name,
        string memory __symbol,
        uint8 _decimals,
        address _poolChainlink,
        uint8 _isChainlinkMultiplied,
        uint32 _stalePeriod,
        address[] memory guardians,
        bytes32 _description,
        address _sequencerUptimeFeed,
        address _admin
    )
        OracleChainlinkSingle(
            _poolChainlink,
            _isChainlinkMultiplied,
            _decimals,
            _stalePeriod,
            guardians,
            _description,
            _sequencerUptimeFeed,
            _admin
        )
    {
        _name = __name;
        _symbol = __symbol;
        decimals = _decimals;

        _grantRole(SEQUENCER_ROLE, _admin);
    }

    /// @notice Get the latest exchange rate.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function get(
        bytes calldata
    ) external virtual nonReentrant returns (bool success, uint256 rate) {
        // Checking whether the sequencer is up
        _sequencerBeatCheck();

        (rate, ) = _quoteChainlink(inBase);
        return (true, rate);
    }

    /// @notice Check the last exchange rate without any state changes.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function peek(
        bytes calldata
    ) external view virtual returns (bool success, uint256 rate) {
        (, uint256 high) = _readAll(inBase);
        return (true, high);
    }

    /// @notice Check the current spot exchange rate without any state changes.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return rate The rate of the requested asset / pair / pool.
    function peekSpot(
        bytes calldata
    ) external view virtual returns (uint256 rate) {
        (, uint256 high) = _readAll(inBase);
        return high;
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
