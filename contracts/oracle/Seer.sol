// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./OracleMulti.sol";
import "../interfaces/IOracle.sol" as ITOracle;

contract Seer is ITOracle.IOracle, OracleMulti {
    string public _name;
    string public _symbol;
    uint8 public immutable override decimals;

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
        address _sequencerUptimeFeed
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
            _sequencerUptimeFeed
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
    function get(
        bytes calldata
    ) external virtual returns (bool success, uint256 rate) {
        (, uint256 high) = _readAll(inBase);
        return (true, high);
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

    /// @notice Check the current spot exchange rate without any state changes. For oracles like TWAP this will be different from peek().
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
