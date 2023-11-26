// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract SequencerCheck {
    // sequencer uptime feed
    AggregatorV3Interface public immutable SEQUENCER_UPTIME_FEED; // If not set, assume it's on a L1
    uint256 public GRACE_PERIOD_TIME = 3600; // 1 hour

    bytes32 public constant SEQUENCER_ROLE = keccak256("SEQUENCER_ROLE");

    error SequencerDown();
    error GracePeriodNotOver();

    constructor(address _sequencerUptimeFeed) {
        SEQUENCER_UPTIME_FEED = AggregatorV3Interface(_sequencerUptimeFeed);
    }

    function _sequencerBeatCheck() internal view {
        // Do not check if the sequencer uptime feed is not set
        // Assume it's on a L1 if it's not set
        if (address(SEQUENCER_UPTIME_FEED) == address(0)) {
            return;
        }

        (, int256 answer, uint256 startedAt, , ) = SEQUENCER_UPTIME_FEED
            .latestRoundData();

        // Answer == 0: Sequencer is up
        // Answer == 1: Sequencer is down
        bool isSequencerUp = answer == 0;
        if (!isSequencerUp) {
            revert SequencerDown();
        }

        // Make sure the grace period has passed after the
        // sequencer is back up.
        uint256 timeSinceUp = block.timestamp - startedAt;
        if (timeSinceUp <= GRACE_PERIOD_TIME) {
            revert GracePeriodNotOver();
        }
    }

    /// @notice Changes the grace period for the sequencer update
    /// @param _gracePeriod New stale period (in seconds)
    function changeGracePeriod(uint32 _gracePeriod) external virtual {}
}
