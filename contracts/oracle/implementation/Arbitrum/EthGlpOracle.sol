// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Tapioca
import {AccessControlDefaultAdminRules} from "../../external/AccessControlDefaultAdminRules.sol";
import {ITapiocaOracle} from "tapioca-periph/interfaces/periph/ITapiocaOracle.sol";

contract EthGlpOracle is ITapiocaOracle, AccessControlDefaultAdminRules, ReentrancyGuard {
    ITapiocaOracle public wethUsdOracle;
    ITapiocaOracle public glpUsdOracle;

    constructor(ITapiocaOracle _wethUsdOracle, ITapiocaOracle _glpUsdOracle, address _admin)
        AccessControlDefaultAdminRules(3 days, _admin)
    {
        wethUsdOracle = _wethUsdOracle;
        glpUsdOracle = _glpUsdOracle;
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    // Get the latest exchange rate
    /// @inheritdoc ITapiocaOracle
    function get(bytes calldata) public override nonReentrant returns (bool success, uint256 rate) {
        (, uint256 wethUsdPrice) = wethUsdOracle.get("");
        (, uint256 glpUsdPrice) = glpUsdOracle.get("");

        return (true, (wethUsdPrice * 1e18) / glpUsdPrice);
    }

    // Check the last exchange rate without any state changes
    /// @inheritdoc ITapiocaOracle
    function peek(bytes calldata) public view override returns (bool success, uint256 rate) {
        (, uint256 wethUsdPrice) = wethUsdOracle.peek("");
        (, uint256 glpUsdPrice) = glpUsdOracle.peek("");

        return (true, (wethUsdPrice * 1e18) / glpUsdPrice);
    }

    // Check the current spot exchange rate without any state changes
    /// @inheritdoc ITapiocaOracle
    function peekSpot(bytes calldata data) external view override returns (uint256 rate) {
        (, rate) = peek(data);
    }

    /// @inheritdoc ITapiocaOracle
    function name(bytes calldata) public pure override returns (string memory) {
        return "ETH/GLP";
    }

    /// @inheritdoc ITapiocaOracle
    function symbol(bytes calldata) public pure override returns (string memory) {
        return "ETH/GLP";
    }
}
