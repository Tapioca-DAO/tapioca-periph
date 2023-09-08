// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "../external/AccessControl.sol";

/// @title ChainlinkUtils
/// @author Angle Core Team
/// @notice Utility contract that is used across the different module contracts using Chainlink
contract ChainlinkUtils is AccessControl {
    /// @notice Represent the maximum amount of time (in seconds) between each Chainlink update
    /// before the price feed is considered stale
    uint32 public stalePeriod;

    // sequencer uptime feed
    AggregatorV3Interface public immutable SEQUENCER_UPTIME_FEED; // If not set, assume it's on a L1
    uint256 public GRACE_PERIOD_TIME = 3600; // 1 hour

    // Role for guardians and governors
    bytes32 public constant GUARDIAN_ROLE_CHAINLINK =
        keccak256("GUARDIAN_ROLE");

    constructor(address _sequencerUptimeFeed) {
        SEQUENCER_UPTIME_FEED = AggregatorV3Interface(_sequencerUptimeFeed);
    }

    error InvalidChainlinkRate();
    error SequencerDown();
    error GracePeriodNotOver();

    /// @notice Reads a Chainlink feed using a quote amount and converts the quote amount to
    /// the out-currency
    /// @param quoteAmount The amount for which to compute the price expressed with base decimal
    /// @param feed Chainlink feed to query
    /// @param multiplied Whether the ratio outputted by Chainlink should be multiplied or divided
    /// to the `quoteAmount`
    /// @param decimals Number of decimals of the corresponding Chainlink pair
    /// @param castedRatio Whether a previous rate has already been computed for this feed
    /// This is mostly used in the `_changeUniswapNotFinal` function of the oracles
    /// @return The `quoteAmount` converted in out-currency (computed using the second return value)
    /// @return The value obtained with the Chainlink feed queried casted to uint
    function _readChainlinkFeed(
        uint256 quoteAmount,
        AggregatorV3Interface feed,
        uint8 multiplied,
        uint256 decimals,
        uint256 castedRatio
    ) internal view returns (uint256, uint256) {
        // Checking whether the sequencer is up
        _sequencerBeatCheck();

        if (castedRatio == 0) {
            (
                uint80 roundId,
                int256 ratio,
                ,
                uint256 updatedAt,
                uint80 answeredInRound
            ) = feed.latestRoundData();
            if (
                ratio <= 0 ||
                roundId > answeredInRound ||
                block.timestamp - updatedAt > stalePeriod
            ) revert InvalidChainlinkRate();
            castedRatio = uint256(ratio);
        }
        // Checking whether we should multiply or divide by the ratio computed
        if (multiplied == 1)
            quoteAmount = (quoteAmount * castedRatio) / (10 ** decimals);
        else quoteAmount = (quoteAmount * (10 ** decimals)) / castedRatio;
        return (quoteAmount, castedRatio);
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

    /// @notice Changes the Stale Period
    /// @param _stalePeriod New stale period (in seconds)
    function changeStalePeriod(
        uint32 _stalePeriod
    ) external onlyRole(GUARDIAN_ROLE_CHAINLINK) {
        stalePeriod = _stalePeriod;
    }

    /// @notice Changes the grace period for the sequencer update
    /// @param _gracePeriod New stale period (in seconds)
    function changeGracePeriod(
        uint32 _gracePeriod
    ) external onlyRole(GUARDIAN_ROLE_CHAINLINK) {
        GRACE_PERIOD_TIME = _gracePeriod;
    }
}
