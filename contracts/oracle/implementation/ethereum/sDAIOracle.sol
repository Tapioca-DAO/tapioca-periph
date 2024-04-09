// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;
// External

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Tapioca
import {AggregatorInterface} from "tapioca-periph/interfaces/external/chainlink/AggregatorInterface.sol";
import {ITapiocaOracle} from "tapioca-periph/interfaces/periph/ITapiocaOracle.sol";

contract SDaiOracle is ITapiocaOracle, ReentrancyGuard {
    AggregatorInterface private immutable sDaiOracle;

    constructor(AggregatorInterface _sDaiOracle, address _admin) {
        sDaiOracle = _sDaiOracle;
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function _get() internal view returns (uint256) {
        return uint256(sDaiOracle.latestAnswer()) * 1e10; // Chainlink returns 8 decimals, we need 18
    }

    // Get the latest exchange rate
    /// @inheritdoc ITapiocaOracle
    function get(bytes calldata) public override nonReentrant returns (bool success, uint256 rate) {
        return (true, _get());
    }

    // Check the last exchange rate without any state changes
    /// @inheritdoc ITapiocaOracle
    function peek(bytes calldata) public view override returns (bool success, uint256 rate) {
        return (true, _get());
    }

    // Check the current spot exchange rate without any state changes
    /// @inheritdoc ITapiocaOracle
    function peekSpot(bytes calldata data) external view override returns (uint256 rate) {
        (, rate) = peek(data);
    }

    /// @inheritdoc ITapiocaOracle
    function name(bytes calldata) public pure override returns (string memory) {
        return "sDAI/USD";
    }

    /// @inheritdoc ITapiocaOracle
    function symbol(bytes calldata) public pure override returns (string memory) {
        return "sDAI/USD";
    }
}
