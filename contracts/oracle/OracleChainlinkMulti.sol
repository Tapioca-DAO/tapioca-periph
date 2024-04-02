// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.22;

// Tapioca
import {AccessControlDefaultAdminRules} from "./external/AccessControlDefaultAdminRules.sol";
import {ModuleChainlinkMulti} from "./modules/ModuleChainlinkMulti.sol";
import {SequencerCheck} from "./utils/SequencerCheck.sol";
import {OracleAbstract} from "./OracleAbstract.sol";

struct OracleChainlinkMultiConstructorData {
    address[] _circuitChainlink;
    uint8[] _circuitChainIsMultiplied;
    uint256 _inBase;
    uint32 stalePeriod;
    address[] guardians;
    bytes32 _description;
    address _sequencerUptimeFeed;
    address _admin;
}

/// @title OracleChainlinkMulti
/// @author Angle Core Team, modified by Tapioca
/// @notice Oracle contract, one contract is deployed per collateral/stablecoin pair
/// @dev This contract concerns an oracle that uses Chainlink with multiple pools to read from
/// @dev It inherits the `ModuleChainlinkMulti` contract and like all oracle contracts, this contract
/// is an instance of `OracleAstract` that contains some base functions
contract OracleChainlinkMulti is OracleAbstract, ModuleChainlinkMulti, SequencerCheck {
    /**
     * @notice Constructor for an oracle using Chainlink with multiple pools to read from
     * @param _data._circuitChainlink ChainLink pool addresses put in order
     * @param _data._circuitChainIsMultiplied Whether we should multiply or divide by this rate
     * @param _data._inBase Number of units of the in-currency
     * @param _data._stalePeriod Time in seconds after which the oracle is considered stale
     * @param _data.guardians List of governor or guardian addresses
     * @param _data._description Description of the assets concerned by the oracle
     * @param _data._sequencerUptimeFeed Address of the sequencer uptime feed, 0x0 if not used
     * @param _data._admin Address of the admin of the oracle
     */
    constructor(OracleChainlinkMultiConstructorData memory _data)
        ModuleChainlinkMulti(_data._circuitChainlink, _data._circuitChainIsMultiplied, _data.stalePeriod, _data.guardians)
        AccessControlDefaultAdminRules(3 days, _data._admin)
        SequencerCheck(_data._sequencerUptimeFeed)
    {
        inBase = _data._inBase;
        description = _data._description;
    }

    /// @notice Reads the rate from the Chainlink circuit
    /// @return rate The current rate between the in-currency and out-currency
    function read() external view override returns (uint256 rate) {
        (rate,) = _quoteChainlink(BASE);
    }

    /// @notice Converts an in-currency quote amount to out-currency using Chainlink's circuit
    /// @param quoteAmount Amount (in the input collateral) to be converted in out-currency
    /// @return Quote amount in out-currency from the base amount in in-currency
    /// @dev The amount returned is expressed with base `BASE` (and not the base of the out-currency)
    function readQuote(uint256 quoteAmount) external view override returns (uint256) {
        return _readQuote(quoteAmount);
    }

    /// @notice Returns Chainlink quote values twice
    /// @param quoteAmount Amount expressed in the in-currency base.
    /// @dev If quoteAmount is `inBase`, rates are returned
    /// @return The two return values are similar
    /// @dev The amount returned is expressed with base `BASE` (and not the base of the out-currency)
    function _readAll(uint256 quoteAmount) internal view override returns (uint256, uint256) {
        uint256 quote = _readQuote(quoteAmount);
        return (quote, quote);
    }

    /// @notice Internal function to convert an in-currency quote amount to out-currency using Chainlink's circuit
    /// @param quoteAmount Amount (in the input collateral) to be converted to be converted in out-currency
    /// @dev The amount returned is expressed with base `BASE` (and not the base of the out-currency)
    function _readQuote(uint256 quoteAmount) internal view returns (uint256) {
        quoteAmount = (quoteAmount * BASE) / inBase;
        (quoteAmount,) = _quoteChainlink(quoteAmount);
        // We return only rates with base as decimals
        return quoteAmount;
    }
}
