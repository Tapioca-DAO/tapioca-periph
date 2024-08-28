// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;
// External

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Tapioca
import {AccessControlDefaultAdminRules} from "../../external/AccessControlDefaultAdminRules.sol";
import {IGmxGlpManager} from "tapioca-periph/interfaces/external/gmx/IGmxGlpManager.sol";
import {ITapiocaOracle} from "tapioca-periph/interfaces/periph/ITapiocaOracle.sol";
import {SequencerCheck} from "../../utils/SequencerCheck.sol";

contract GLPOracle is ITapiocaOracle, SequencerCheck, AccessControlDefaultAdminRules, ReentrancyGuard {
    IGmxGlpManager private immutable glpManager;

    constructor(IGmxGlpManager glpManager_, address _sequencerUptimeFeed, address _admin)
        SequencerCheck(_sequencerUptimeFeed)
        AccessControlDefaultAdminRules(3 days, _admin)
    {
        glpManager = glpManager_;

        _grantRole(SEQUENCER_ROLE, _admin);
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function _get() internal view returns (uint256) {
        return glpManager.getPrice(true) / 1e12; // GLP is 30 decimals, we need 18
    }

    // Get the latest exchange rate
    /// @inheritdoc ITapiocaOracle
    function get(bytes calldata) public override nonReentrant returns (bool success, uint256 rate) {
        _sequencerBeatCheck();
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
        return "GLP/USD";
    }

    /// @inheritdoc ITapiocaOracle
    function symbol(bytes calldata) public pure override returns (string memory) {
        return "GLP/USD";
    }

    /// @notice Changes the grace period for the sequencer update
    /// @param _gracePeriod New stale period (in seconds)
    function changeGracePeriod(uint32 _gracePeriod) external override onlyRole(SEQUENCER_ROLE) {
        GRACE_PERIOD_TIME = _gracePeriod;
    }
}
