// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {AggregatorV2V3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {FixedPointMathLib} from "solady/src/utils/FixedPointMathLib.sol";

import "../../interfaces/IOracle.sol" as ITOracle;

interface ICurvePool {
    function coins(uint256 i) external view returns (address);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external;

    function get_virtual_price() external view returns (uint256);

    function gamma() external view returns (uint256);

    function A() external view returns (uint256);
}

/// @notice Courtesy of https://gist.github.com/0xShaito/f01f04cb26d0f89a0cead15cff3f7047
/// @dev Addresses are for Arbitrum
contract ARBTriCryptoOracle is ITOracle.IOracle {
    string public _name;
    string public _symbol;

    ICurvePool public immutable TRI_CRYPTO;
    AggregatorV2V3Interface public immutable BTC_FEED;
    AggregatorV2V3Interface public immutable ETH_FEED;
    AggregatorV2V3Interface public immutable USDT_FEED;
    AggregatorV2V3Interface public immutable WBTC_FEED;

    uint256 public constant GAMMA0 = 28_000_000_000_000; // 2.8e-5
    uint256 public constant A0 = 2 * 3 ** 3 * 10_000;
    uint256 public constant DISCOUNT0 = 1_087_460_000_000_000; // 0.00108..

    constructor(
        string memory __name,
        string memory __symbol,
        ICurvePool pool,
        AggregatorV2V3Interface btcFeed,
        AggregatorV2V3Interface ethFeed,
        AggregatorV2V3Interface usdtFeed,
        AggregatorV2V3Interface wbtcFeed
    ) {
        _name = __name;
        _symbol = __symbol;
        TRI_CRYPTO = pool;
        BTC_FEED = btcFeed;
        ETH_FEED = ethFeed;
        USDT_FEED = usdtFeed;
        WBTC_FEED = wbtcFeed;
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    /// @notice Get the latest exchange rate.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function get(
        bytes calldata
    ) external virtual returns (bool success, uint256 rate) {
        return (true, _get());
    }

    /// @notice Check the last exchange rate without any state changes.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function peek(
        bytes calldata
    ) external view virtual returns (bool success, uint256 rate) {
        return (true, _get());
    }

    /// @notice Check the current spot exchange rate without any state changes. For oracles like TWAP this will be different from peek().
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return rate The rate of the requested asset / pair / pool.
    function peekSpot(
        bytes calldata
    ) external view virtual returns (uint256 rate) {
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

    /// @notice Calculated the price of 1 LP token
    /// @return _maxPrice the current value
    /// @dev This function comes from the implementation in vyper that is on the bottom
    function _get() internal view returns (uint256 _maxPrice) {
        uint256 _vp = TRI_CRYPTO.get_virtual_price();

        // Get the prices from chainlink and add 10 decimals
        uint256 _btcPrice = _assurePrice(BTC_FEED) * 1e10;
        uint256 _wbtcPrice = _assurePrice(WBTC_FEED) * 1e10;
        uint256 _ethPrice = _assurePrice(ETH_FEED) * 1e10;
        uint256 _usdtPrice = _assurePrice(USDT_FEED) * 1e10;

        uint256 _minWbtcPrice = (_wbtcPrice < 1e18)
            ? (_wbtcPrice * _btcPrice) / 1e18
            : _btcPrice;

        uint256 _basePrices = (_minWbtcPrice * _ethPrice * _usdtPrice);

        _maxPrice = (3 * _vp * FixedPointMathLib.cbrt(_basePrices)) / 1 ether;

        // ((A/A0) * (gamma/gamma0)**2) ** (1/3)
        uint256 _g = (TRI_CRYPTO.gamma() * 1 ether) / GAMMA0;
        uint256 _a = (TRI_CRYPTO.A() * 1 ether) / A0;
        uint256 _discount = Math.max((_g ** 2 / 1 ether) * _a, 1e34); // handle qbrt nonconvergence
        // if discount is small, we take an upper bound
        _discount = (FixedPointMathLib.sqrt(_discount) * DISCOUNT0) / 1 ether;

        _maxPrice -= (_maxPrice * _discount) / 1 ether;
    }

    function _assurePrice(
        AggregatorV2V3Interface feed
    ) private view returns (uint256 _price) {
        (uint80 roundId, int256 answer, , uint256 updatedAt, ) = feed
            .latestRoundData();
        require(answer > 0, "ARBTriCryptoOracle: feed price 0");
        require(updatedAt > 0, "ARBTriCryptoOracle: stale price");
        require(roundId > 0, "ARBTriCryptoOracle: stale round");
        return uint256(answer);
    }
}
