// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Tapioca
import {AccessControlDefaultAdminRules} from "../../external/AccessControlDefaultAdminRules.sol";
import {IGmxGlpManager} from "contracts/interfaces/external/gmx/IGmxGlpManager.sol";
import {ITapiocaOracle} from "contracts/interfaces/periph/ITapiocaOracle.sol";
import {SequencerCheck} from "../../utils/SequencerCheck.sol";

contract EthGlpOracle is ITapiocaOracle, SequencerCheck, AccessControlDefaultAdminRules, ReentrancyGuard {
    IOracle public wethUsdOracle;
    IOracle public glpUsdOracle;

    constructor(IOracle _wethUsdOracle, IOracle _glpUsdOracle, address _sequencerUptimeFeed, address _admin)
        SequencerCheck(_sequencerUptimeFeed)
        AccessControlDefaultAdminRules(3 days, _admin)
    {
        wethUsdOracle = _wethUsdOracle;
        glpUsdOracle = _glpUsdOracle;
        _grantRole(SEQUENCER_ROLE, _admin);
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    // Get the latest exchange rate
    /// @inheritdoc IOracle
    function get(bytes calldata) public override nonReentrant returns (bool success, uint256 rate) {
        _sequencerBeatCheck();

        (, uint256 wethUsdPrice) = wethUsdOracle.get("");
        (, uint256 glpUsdPrice) = glpUsdOracle.get("");

        return (true, (wethUsdPrice * 1e30) / glpUsdPrice);
    }

    // Check the last exchange rate without any state changes
    /// @inheritdoc IOracle
    function peek(bytes calldata) public view override returns (bool success, uint256 rate) {
        (, uint256 wethUsdPrice) = wethUsdOracle.peek("");
        (, uint256 glpUsdPrice) = glpUsdOracle.peek("");

        return (true, (wethUsdPrice * 1e30) / glpUsdPrice);
    }

    // Check the current spot exchange rate without any state changes
    /// @inheritdoc IOracle
    function peekSpot(bytes calldata data) external view override returns (uint256 rate) {
        (, rate) = peek(data);
    }

    /// @inheritdoc IOracle
    function name(bytes calldata) public pure override returns (string memory) {
        return "ETH/GLP";
    }

    /// @inheritdoc IOracle
    function symbol(bytes calldata) public pure override returns (string memory) {
        return "ETH/GLP";
    }

    /// @notice Changes the grace period for the sequencer update
    /// @param _gracePeriod New stale period (in seconds)
    function changeGracePeriod(uint32 _gracePeriod) external override onlyRole(SEQUENCER_ROLE) {
        GRACE_PERIOD_TIME = _gracePeriod;
    }
}
