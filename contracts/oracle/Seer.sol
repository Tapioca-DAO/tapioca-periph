// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import "./OracleMulti.sol";
import "../interfaces/IOracle.sol" as ITOracle;

contract Seer is ITOracle.IOracle, OracleMulti {
    string public _name;
    string public _symbol;
    uint8 public immutable override decimals;

    /// @notice Constructor for the oracle using a mix of ChainLink and Uniswap
    /// @param __name Name of the oracle
    /// @param __symbol Symbol of the oracle
    /// @param _decimals Number of decimals of the oracle
    /// @param addressInAndOutUni Array of contract addresses used the Uniswap pool
    /// @param _circuitUniswap Array of Uniswap pool addresses to use
    /// @param _circuitUniIsMultiplied Array of booleans indicating whether we should multiply or divide by the Uniswap rate the
    /// in-currency amount to get the out-currency amount
    /// @param _twapPeriod Time weighted average window for all Uniswap pools, in seconds
    /// @param observationLength Number of observations that each pool should have stored
    /// @param _uniFinalCurrency Whether we need to use the last ChainLink oracle to convert to another
    /// currency / asset (Forex for instance)
    /// @param _circuitChainlink ChainLink pool addresses put in order
    /// @param _circuitChainIsMultiplied Whether we should multiply or divide by this rate
    /// @param _stalePeriod Time in seconds after which the oracle is considered stale
    /// @param guardians List of governor or guardian addresses
    /// @param _description Description of the assets concerned by the oracle
    /// @param _sequencerUptimeFeed Address of the sequencer uptime feed, 0x0 if not used
    /// @param _admin Address of the admin of the oracle
    constructor(
        string memory __name,
        string memory __symbol,
        uint8 _decimals,
        address[] memory addressInAndOutUni,
        IUniswapV3Pool[] memory _circuitUniswap,
        uint8[] memory _circuitUniIsMultiplied,
        uint32 _twapPeriod,
        uint16 observationLength,
        uint8 _uniFinalCurrency,
        address[] memory _circuitChainlink,
        uint8[] memory _circuitChainIsMultiplied,
        uint32 _stalePeriod,
        address[] memory guardians,
        bytes32 _description,
        address _sequencerUptimeFeed,
        address _admin
    )
        OracleMulti(
            addressInAndOutUni,
            _circuitUniswap,
            _circuitUniIsMultiplied,
            _twapPeriod,
            observationLength,
            _uniFinalCurrency,
            _circuitChainlink,
            _circuitChainIsMultiplied,
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
    }

    /// @notice Get the latest exchange rate.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function get(bytes calldata data) external virtual nonReentrant returns (bool success, uint256 rate) {
        // Checking whether the sequencer is up
        _sequencerBeatCheck();

        (uint256 low, uint256 high) = _readAll(inBase);

        if (data.length > 0) {
            ITOracle.ISeerQuery memory query = abi.decode(data, (ITOracle.ISeerQuery));
            if (query.useHigh) return (true, high);
        }

        return (true, low);
    }

    /// @notice Check the last exchange rate without any state changes.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function peek(bytes calldata data) external view virtual returns (bool success, uint256 rate) {
        (uint256 low, uint256 high) = _readAll(inBase);

        if (data.length > 0) {
            ITOracle.ISeerQuery memory query = abi.decode(data, (ITOracle.ISeerQuery));
            if (query.useHigh) return (true, high);
        }

        return (true, low);
    }

    /// @notice Check the current spot exchange rate without any state changes.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return rate The rate of the requested asset / pair / pool.
    function peekSpot(bytes calldata data) external view virtual returns (uint256 rate) {
        (uint256 low, uint256 high) = _readAll(inBase);

        if (data.length > 0) {
            ITOracle.ISeerQuery memory query = abi.decode(data, (ITOracle.ISeerQuery));
            if (query.useHigh) return high;
        }

        return low;
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
