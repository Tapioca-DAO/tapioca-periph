// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {IOracle} from "../../../interfaces/IOracle.sol";
import {IGmxGlpManager} from "../../../interfaces/IGmxGlpManager.sol";
import {SequencerCheck} from "../../utils/SequencerCheck.sol";
import {AccessControl} from "../../external/AccessControl.sol";

contract GLPOracle is IOracle, SequencerCheck, AccessControl {
    IGmxGlpManager private immutable glpManager;

    /// @notice Reentrancy check
    bool private entered;
    modifier nonReentrant() {
        require(!entered, "Oracle: reentrancy");
        entered = true;
        _;
        entered = false;
    }

    constructor(
        IGmxGlpManager glpManager_,
        address _sequencerUptimeFeed,
        address _admin
    ) SequencerCheck(_sequencerUptimeFeed) {
        glpManager = glpManager_;

        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(SEQUENCER_ROLE, _admin);
    }

    function decimals() external pure returns (uint8) {
        return 30;
    }

    function _get() internal view returns (uint256) {
        return glpManager.getPrice(false);
    }

    // Get the latest exchange rate
    /// @inheritdoc IOracle
    function get(
        bytes calldata
    ) public override nonReentrant returns (bool success, uint256 rate) {
        _sequencerBeatCheck();
        return (true, _get());
    }

    // Check the last exchange rate without any state changes
    /// @inheritdoc IOracle
    function peek(
        bytes calldata
    ) public view override returns (bool success, uint256 rate) {
        return (true, _get());
    }

    // Check the current spot exchange rate without any state changes
    /// @inheritdoc IOracle
    function peekSpot(
        bytes calldata data
    ) external view override returns (uint256 rate) {
        (, rate) = peek(data);
    }

    /// @inheritdoc IOracle
    function name(bytes calldata) public pure override returns (string memory) {
        return "GLP/USD";
    }

    /// @inheritdoc IOracle
    function symbol(
        bytes calldata
    ) public pure override returns (string memory) {
        return "GLP/USD";
    }

    /// @notice Changes the grace period for the sequencer update
    /// @param _gracePeriod New stale period (in seconds)
    function changeGracePeriod(
        uint32 _gracePeriod
    ) external override onlyRole(SEQUENCER_ROLE) {
        GRACE_PERIOD_TIME = _gracePeriod;
    }
}
