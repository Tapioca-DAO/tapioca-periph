// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Tapioca
import {AccessControlDefaultAdminRules} from "./external/AccessControlDefaultAdminRules.sol";
import {ITapiocaOracle} from "tapioca-periph/interfaces/periph/ITapiocaOracle.sol";

/**
 * @notice Helps inverse the value of a `ITapiocaOracle` contract.
 * This is used because Tapioca BB/SGL expect a USD/Asset exchange rate. Why usually we have Asset/USD.
 */
contract UsdoMarketOracle is ITapiocaOracle, AccessControlDefaultAdminRules, ReentrancyGuard {
    ITapiocaOracle public immutable marketAssetOracle;

    constructor(ITapiocaOracle _oracle, address _admin) AccessControlDefaultAdminRules(3 days, _admin) {
        marketAssetOracle = _oracle;

        if (_oracle.decimals() != 18) {
            revert("UsdoMarketOracle: Oracle must have 18 decimals");
        }
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    // Get the latest exchange rate
    /// @inheritdoc ITapiocaOracle
    function get(bytes calldata) public override nonReentrant returns (bool success, uint256 rate) {
        (, uint256 marketAssetPrice) = marketAssetOracle.get("");
        return (true, inverseValue(marketAssetPrice));
    }

    // Check the last exchange rate without any state changes
    /// @inheritdoc ITapiocaOracle
    function peek(bytes calldata) public view override returns (bool success, uint256 rate) {
        (, uint256 marketAssetPrice) = marketAssetOracle.peek("");
        return (true, inverseValue(marketAssetPrice));
    }

    // Check the current spot exchange rate without any state changes
    /// @inheritdoc ITapiocaOracle
    function peekSpot(bytes calldata data) external view override returns (uint256 rate) {
        (, rate) = peek(data);
    }

    /// @inheritdoc ITapiocaOracle
    function name(bytes calldata) public view override returns (string memory) {
        return string.concat("Inverse ", marketAssetOracle.name(""));
    }

    /// @inheritdoc ITapiocaOracle
    function symbol(bytes calldata) public view override returns (string memory) {
        return string.concat("Inv", marketAssetOracle.symbol(""));
    }

    /**
     * @notice Inverse the value of a given value. The value should be in 1e18 format.
     */
    function inverseValue(uint256 value) internal pure returns (uint256) {
        return 1e36 / value;
    }
}
