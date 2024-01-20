// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {ChainlinkUtils, AggregatorV3Interface, AccessControlDefaultAdminRules} from "../../utils/ChainlinkUtils.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {SequencerCheck} from "../../utils/SequencerCheck.sol";
import "../../../interfaces/IOracle.sol" as ITOracle;

interface IStargatePool {
    function deltaCredit() external view returns (uint256);

    function totalLiquidity() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint256);

    function localDecimals() external view returns (uint256);

    function token() external view returns (address);
}

contract SGOracle is ITOracle.IOracle, ChainlinkUtils, SequencerCheck, ReentrancyGuard {
    string public _name;
    string public _symbol;

    IStargatePool public immutable SG_POOL;
    AggregatorV3Interface public immutable UNDERLYING;

    constructor(
        string memory __name,
        string memory __symbol,
        IStargatePool pool,
        AggregatorV3Interface _underlying,
        address _sequencerUptimeFeed,
        address _admin
    ) SequencerCheck(_sequencerUptimeFeed) AccessControlDefaultAdminRules(3 days, _admin) {
        _name = __name;
        _symbol = __symbol;
        SG_POOL = pool;
        UNDERLYING = _underlying;
    }

    function decimals() external view returns (uint8) {
        return UNDERLYING.decimals();
    }

    /// @notice Calculated the price of 1 LP token
    /// @return _maxPrice the current value
    /// @dev This function comes from the implementation in vyper that is on the bottom
    function _get() internal view returns (uint256 _maxPrice) {
        require(SG_POOL.totalSupply() > 0, "SGOracle: supply 0");

        uint256 underlyingPrice = _readChainlinkBase(UNDERLYING, 0);
        uint256 lpPrice = (SG_POOL.totalLiquidity() * uint256(underlyingPrice)) / SG_POOL.totalSupply();

        return lpPrice;
    }

    /// @notice Get the latest exchange rate.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function get(bytes calldata) external virtual nonReentrant returns (bool success, uint256 rate) {
        _sequencerBeatCheck();
        return (true, _get());
    }

    /// @notice Check the last exchange rate without any state changes.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function peek(bytes calldata) external view virtual returns (bool success, uint256 rate) {
        return (true, _get());
    }

    /// @notice Check the current spot exchange rate without any state changes. For oracles like TWAP this will be different from peek().
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return rate The rate of the requested asset / pair / pool.
    function peekSpot(bytes calldata) external view virtual returns (uint256 rate) {
        return _get();
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
