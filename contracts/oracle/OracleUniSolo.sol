// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.22;

// External
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Tapioca
import {AccessControlDefaultAdminRules} from "./external/AccessControlDefaultAdminRules.sol";
import {ModuleUniswapMulti} from "./modules/ModuleUniswapMulti.sol";
import {SequencerCheck} from "./utils/SequencerCheck.sol";
import {OracleAbstract} from "./OracleAbstract.sol";

struct OracleUniSoloConstructorData {
    address[] addressInAndOutUni;
    IUniswapV3Pool[] _circuitUniswap;
    uint8[] _circuitUniIsMultiplied;
    uint32 _twapPeriod;
    uint16 observationLength;
    address[] guardians;
    bytes32 _description;
    address _sequencerUptimeFeed;
    address _admin;
}

/// @title OracleUniSolo
/// @notice Updated version of the OracleMulti contract that only uses Uniswap
contract OracleUniSolo is OracleAbstract, ModuleUniswapMulti, SequencerCheck, ReentrancyGuard {
    /// @notice Unit out Uniswap currency
    uint256 public immutable outBase;

    /// @notice Constructor for an oracle using both Uniswap to read from
    /// @param _data.addressInAndOutUni List of 2 addresses representing the in-currency address and the out-currency address
    /// @param _data._circuitUniswap Path of the Uniswap pools
    /// @param _data._circuitUniIsMultiplied Whether we should multiply or divide by this rate in the path
    /// @param _data._twapPeriod Time weighted average window for all Uniswap pools
    /// @param _data.observationLength Number of observations that each pool should have stored
    /// @param _data.guardians List of governor or guardian addresses
    /// @param _data._description Description of the assets concerned by the oracle
    /// @param _data._sequencerUptimeFeed Address of the sequencer uptime feed, 0x0 if not used
    /// @param _data._admin Address of the admin of the oracle
    constructor(OracleUniSoloConstructorData memory _data)
        ModuleUniswapMulti(
            _data._circuitUniswap,
            _data._circuitUniIsMultiplied,
            _data._twapPeriod,
            _data.observationLength,
            _data.guardians
        )
        SequencerCheck(_data._sequencerUptimeFeed)
        AccessControlDefaultAdminRules(3 days, _data._admin)
    {
        require(_data.addressInAndOutUni.length == 2, "107");
        // Using the tokens' metadata to get the in and out currencies decimals
        IERC20Metadata inCur = IERC20Metadata(_data.addressInAndOutUni[0]);
        IERC20Metadata outCur = IERC20Metadata(_data.addressInAndOutUni[1]);
        inBase = 10 ** (inCur.decimals());
        outBase = 10 ** (outCur.decimals());

        description = _data._description;
    }

    /// @notice Reads the Uniswap rate using the circuit given
    /// @return The current rate between the in-currency and out-currency
    /// @dev By default even if there is a Chainlink rate, this function returns the Uniswap rate
    /// @dev The amount returned is expressed with base `BASE` (and not the base of the out-currency)
    function read() external view override returns (uint256) {
        return _readUniswapQuote(inBase);
    }

    /// @notice Converts an in-currency quote amount to out-currency using the Uniswap rate
    /// @param quoteAmount Amount (in the input collateral) to be converted in out-currency
    /// @return Quote amount in out-currency from the base amount in in-currency
    /// @dev Like in the `read` function, this function returns the Uniswap quote
    /// @dev The amount returned is expressed with base `BASE` (and not the base of the out-currency)
    function readQuote(uint256 quoteAmount) external view override returns (uint256) {
        return _readUniswapQuote(quoteAmount);
    }

    /// @notice Returns Uniswap and Chainlink values (with the first one being the smallest one)
    /// @param quoteAmount Amount expressed in the in-currency base.
    /// @dev If quoteAmount is `inBase`, rates are returned
    /// @return The first parameter is the lowest value and the second parameter is the highest
    /// @dev The amount returned is expressed with base `BASE` (and not the base of the out-currency)
    function _readAll(uint256 quoteAmount) internal view override returns (uint256, uint256) {
        uint256 quoteAmountUni = _readUniswapQuote(quoteAmount);
        return (quoteAmountUni, quoteAmountUni);
    }

    /// @notice Internal function to convert an in-currency quote amount to out-currency using only the Uniswap rate
    /// @param quoteAmount Amount (in the input collateral) to be converted in out-currency using Uniswap
    /// @return uniAmount Quote amount in out-currency from the base amount in in-currency
    /// @dev The amount returned is expressed with base `BASE` (and not the base of the out-currency)
    function _readUniswapQuote(uint256 quoteAmount) internal view returns (uint256 uniAmount) {
        uniAmount = _quoteUniswap(quoteAmount);
        // The current uni rate is in outBase we want our rate to all be in base
        uniAmount = (uniAmount * BASE) / outBase;
    }

    /// @notice Changes the grace period for the sequencer update
    /// @param _gracePeriod New stale period (in seconds)
    function changeGracePeriod(uint32 _gracePeriod) external override onlyRole(SEQUENCER_ROLE) {
        GRACE_PERIOD_TIME = _gracePeriod;
    }
}
