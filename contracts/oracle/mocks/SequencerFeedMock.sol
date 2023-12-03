// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

struct RoundData {
    uint80 roundId;
    int256 answer;
    uint256 startedAt;
    uint256 updatedAt;
    uint80 answeredInRound;
}

contract SequencerFeedMock is AggregatorV3Interface {
    uint8 public constant override decimals = 18;
    string public constant override description = "Sequencer Feed Mock";
    uint256 public constant override version = 3;

    // roundId => RoundData
    mapping(uint80 => RoundData) public roundData;
    RoundData public latestRoundData;

    function setRoundData(uint80 _roundId, RoundData memory _roundData) public {
        roundData[_roundId] = _roundData;
    }

    function setLatestRoundData(RoundData memory _latestRoundData) public {
        latestRoundData = _latestRoundData;
    }

    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (
            roundData[_roundId].roundId,
            roundData[_roundId].answer,
            roundData[_roundId].startedAt,
            roundData[_roundId].updatedAt,
            roundData[_roundId].answeredInRound
        );
    }
}
