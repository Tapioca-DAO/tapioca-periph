// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.22;

// Tapioca
import {
    AccessControlledOffchainAggregator,
    AggregatorV3Interface
} from "tapioca-periph/interfaces/external/chainlink/IAggregatorV3Interface.sol";
import {AccessControlDefaultAdminRules} from "../external/AccessControlDefaultAdminRules.sol";

/// @title ChainlinkUtils
/// @author Angle Core Team, modifier by Tapioca
/// @notice Utility contract that is used across the different module contracts using Chainlink
abstract contract ChainlinkUtils is AccessControlDefaultAdminRules {
    /// @notice Represent the maximum amount of time (in seconds) between each Chainlink update
    /// before the price feed is considered stale
    mapping(AggregatorV3Interface => uint32) public stalePeriods;
    uint32 public DEFAULT_STALE_PERIOD = 86400;

    // Role for guardians and governors
    bytes32 public constant GUARDIAN_ROLE_CHAINLINK = keccak256("GUARDIAN_ROLE");

    error InvalidChainlinkRate();
    error StalePeriodNotValid();

    event StalePeriodUpdated(AggregatorV3Interface indexed feed, uint32 indexed val);

    /// @notice Reads a Chainlink feed. Perform a sequence upbeat check if L2 chain
    /// @param feed Chainlink feed to query
    /// @return The value obtained with the Chainlink feed queried
    function _readChainlinkBase(AggregatorV3Interface feed, uint256 castedRatio) internal view returns (uint256) {
        if (castedRatio == 0) {
            uint256 _stalePeriod = stalePeriods[feed];
            if (_stalePeriod == 0) _stalePeriod = DEFAULT_STALE_PERIOD;

            (, int256 ratio,, uint256 updatedAt,) = feed.latestRoundData();

            if (
                ratio <= feed.aggregator().minAnswer() || ratio >= feed.aggregator().maxAnswer()
                    || block.timestamp - updatedAt > _stalePeriod
            ) revert InvalidChainlinkRate();
            castedRatio = uint256(ratio);
        }
        return castedRatio;
    }

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
        castedRatio = _readChainlinkBase(feed, castedRatio);

        // Checking whether we should multiply or divide by the ratio computed
        if (multiplied == 1) {
            quoteAmount = (quoteAmount * castedRatio) / (10 ** decimals);
        } else {
            quoteAmount = (quoteAmount * (10 ** decimals)) / castedRatio;
        }
        return (quoteAmount, castedRatio);
    }

    /// @notice Updates stale period for feed
    /// @param _feed the feed key
    /// @param _stalePeriod the new sale period
    function updateStalePeriod(AggregatorV3Interface _feed, uint32 _stalePeriod)
        external
        onlyRole(GUARDIAN_ROLE_CHAINLINK)
    {
        if (_stalePeriod == 0) revert StalePeriodNotValid();

        stalePeriods[_feed] = _stalePeriod;
        emit StalePeriodUpdated(_feed, _stalePeriod);
    }

    /// @notice Changes the Stale Period
    /// @param _stalePeriod New stale period (in seconds)
    function changeDefaultStalePeriod(uint32 _stalePeriod) external onlyRole(GUARDIAN_ROLE_CHAINLINK) {
        DEFAULT_STALE_PERIOD = _stalePeriod;
    }
}
