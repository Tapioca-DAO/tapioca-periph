// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Tapioca
import {AccessControlDefaultAdminRules} from "../../external/AccessControlDefaultAdminRules.sol";
import {ITapiocaOracle, ISeerQuery} from "tapioca-periph/interfaces/periph/ITapiocaOracle.sol";
import {SequencerCheck} from "../../utils/SequencerCheck.sol";

contract DualETHOracle is ITapiocaOracle, SequencerCheck, AccessControlDefaultAdminRules, ReentrancyGuard {
    ITapiocaOracle public seerClEthOracle;
    ITapiocaOracle public seerUniEthOracle;

    constructor(
        ITapiocaOracle _seerClEthOracle,
        ITapiocaOracle _seerUniEthOracle,
        address _sequencerUptimeFeed,
        address _admin
    ) SequencerCheck(_sequencerUptimeFeed) AccessControlDefaultAdminRules(3 days, _admin) {
        seerClEthOracle = _seerClEthOracle;
        seerUniEthOracle = _seerUniEthOracle;
        _grantRole(SEQUENCER_ROLE, _admin);
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    // Get the latest exchange rate
    /// @inheritdoc ITapiocaOracle
    function get(bytes calldata data) public override nonReentrant returns (bool success, uint256 rate) {
        _sequencerBeatCheck();

        (, uint256 clPrice) = seerClEthOracle.get("");
        (, uint256 uniPrice) = seerUniEthOracle.get("");
        (uint256 high, uint256 low) = clPrice > uniPrice ? (clPrice, uniPrice) : (uniPrice, clPrice);

        if (data.length > 0) {
            ISeerQuery memory query = abi.decode(data, (ISeerQuery));
            if (query.useHigh) {
                return (true, high);
            }
        }

        return (true, low);
    }

    function _peek(bytes calldata data) internal view returns (bool, uint256) {
        (, uint256 clPrice) = seerClEthOracle.peek("");
        (, uint256 uniPrice) = seerUniEthOracle.peek("");
        (uint256 high, uint256 low) = clPrice > uniPrice ? (clPrice, uniPrice) : (uniPrice, clPrice);

        if (data.length > 0) {
            ISeerQuery memory query = abi.decode(data, (ISeerQuery));
            if (query.useHigh) {
                return (true, high);
            }
        }

        return (true, low);
    }

    // Check the last exchange rate without any state changes
    /// @inheritdoc ITapiocaOracle
    function peek(bytes calldata data) public view override returns (bool success, uint256 rate) {
        return _peek(data);
    }

    // Check the current spot exchange rate without any state changes
    /// @inheritdoc ITapiocaOracle
    function peekSpot(bytes calldata data) external view override returns (uint256 rate) {
        (, rate) = _peek(data);
    }

    /// @inheritdoc ITapiocaOracle
    function name(bytes calldata) public pure override returns (string memory) {
        return "DUAL ETH/USD";
    }

    /// @inheritdoc ITapiocaOracle
    function symbol(bytes calldata) public pure override returns (string memory) {
        return "ETH/USD";
    }

    /// @notice Changes the grace period for the sequencer update
    /// @param _gracePeriod New stale period (in seconds)
    function changeGracePeriod(uint32 _gracePeriod) external override onlyRole(SEQUENCER_ROLE) {
        GRACE_PERIOD_TIME = _gracePeriod;
    }
}
