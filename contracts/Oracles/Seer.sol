// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

import "./Math.sol";
import "../interfaces/IAggregatorV3Interface.sol";
import "../interfaces/IOracle.sol";

contract Seer is IOracle {
    AggregatorV3Interface internal immutable CHAINLINK_AGGREGATOR;
    IUniswapV3Pool internal immutable UNI_POOL;

    string public _name;
    string public _symbol;

    constructor(
        string memory __name,
        string memory __symbol,
        address chainlinkAggregator,
        address uniPool
    ) {
        CHAINLINK_AGGREGATOR = AggregatorV3Interface(chainlinkAggregator);
        UNI_POOL = IUniswapV3Pool(uniPool);
        _name = __name;
        _symbol = __symbol;
    }

    function _getUniPrice() public view returns (uint256) {
        (uint160 sqrtPriceX96, , , , , , ) = UNI_POOL.slot0();

        // sqrtPriceX96 is a Q64.96 fixed point number, so you need to decode it
        uint256 numerator1 = uint256(sqrtPriceX96) * uint256(sqrtPriceX96);
        uint256 numerator2 = 10 ** 18;
        return Math.mulDiv(numerator1, numerator2, 1 << 192);
    }

    function getPrice() public view returns (int) {
        (, int price, , , ) = CHAINLINK_AGGREGATOR.latestRoundData();
        return price;
    }

    function getUniPrice() public view returns (int) {
        return int(_getUniPrice());
    }

    /// @notice Get the latest exchange rate.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function get(
        bytes calldata data
    ) external virtual returns (bool success, uint256 rate) {
        return (true, uint256(getPrice()));
    }

    /// @notice Check the last exchange rate without any state changes.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function peek(
        bytes calldata data
    ) external view virtual returns (bool success, uint256 rate) {
        return (true, uint256(getPrice()));
    }

    /// @notice Check the current spot exchange rate without any state changes. For oracles like TWAP this will be different from peek().
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return rate The rate of the requested asset / pair / pool.
    function peekSpot(
        bytes calldata data
    ) external view virtual returns (uint256 rate) {
        return uint256(getPrice());
    }

    /// @notice Returns a human readable (short) name about this oracle.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return (string) A human readable symbol name about this oracle.
    function symbol(bytes calldata data) external view returns (string memory) {
        return _symbol;
    }

    /// @notice Returns a human readable name about this oracle.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return (string) A human readable name about this oracle.
    function name(bytes calldata data) external view returns (string memory) {
        return _name;
    }
}
