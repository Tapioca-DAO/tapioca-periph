// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "../../SeerUniSolo.sol";

contract TapOracle is SeerUniSolo {
    /// @notice Time in seconds after which get() can be called again (1 hour).
    uint256 public FETCH_TIME = 4 hours;

    /// @notice Last prices of the oracle. get() will return the average.
    uint256[3] public lastPrices = [0, 0, 0];
    /// @notice Last index update of the oracle. goes from 0 to 2.
    uint8 private lastIndex = 0;
    /// @dev Last timestamp of the oracle update.
    uint128 lastCall = 0;

    event FetchTimeUpdated(uint256 newFetchTime);
    event LastPriceUpdated(uint256 newLastPrice, uint8 index);

    /// @notice Constructor for an oracle using both Uniswap to read from
    /// @param __name Name of the oracle
    /// @param __symbol Symbol of the oracle
    /// @param _decimals Number of decimals of the oracle
    /// @param addressInAndOutUni List of 2 addresses representing the in-currency address and the out-currency address
    /// @param _circuitUniswap Path of the Uniswap pools
    /// @param _circuitUniIsMultiplied Whether we should multiply or divide by this rate in the path
    /// @param _twapPeriod Time weighted average window for all Uniswap pools
    /// @param observationLength Number of observations that each pool should have stored
    /// @param guardians List of governor or guardian addresses
    /// @param _description Description of the assets concerned by the oracle
    /// @param _sequencerUptimeFeed Address of the sequencer uptime feed, 0x0 if not used
    constructor(
        string memory __name,
        string memory __symbol,
        uint8 _decimals,
        address[] memory addressInAndOutUni,
        IUniswapV3Pool[] memory _circuitUniswap,
        uint8[] memory _circuitUniIsMultiplied,
        uint32 _twapPeriod,
        uint16 observationLength,
        address[] memory guardians,
        bytes32 _description,
        address _sequencerUptimeFeed,
        address _admin
    )
        SeerUniSolo(
            __name,
            __symbol,
            _decimals,
            addressInAndOutUni,
            _circuitUniswap,
            _circuitUniIsMultiplied,
            _twapPeriod,
            observationLength,
            guardians,
            _description,
            _sequencerUptimeFeed,
            _admin
        )
    {}

    /// @notice Get the latest exchange rate.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function get(
        bytes calldata
    )
        external
        virtual
        override
        nonReentrant
        returns (bool success, uint256 rate)
    {
        (, uint256 price) = _readAll(inBase);

        /// @dev If the last update was more than FETCH_TIME seconds ago, update the last price.
        if (block.timestamp - lastCall > FETCH_TIME) {
            _updateLastPrice(price);
        }

        uint256 average = _computeAverage();
        return (true, average);
    }

    /// @notice Update the last price of the oracle.
    function updateLastPrice() external {
        (, uint256 price) = _readAll(inBase);
        _updateLastPrice(price);
    }

    /// @notice Update the last price of the oracle. Only if the last update was more than FETCH_TIME seconds ago.
    function _updateLastPrice(uint256 _price) internal {
        require(
            block.timestamp - lastCall > FETCH_TIME,
            "TapOracle: too early"
        );
        uint8 _lastIndex = lastIndex;
        lastPrices[_lastIndex] = _price;
        lastIndex = (_lastIndex + 1) % 3;

        lastCall = uint128(block.timestamp);

        emit LastPriceUpdated(_price, _lastIndex);
    }

    /// @notice Check the last exchange rate without any state changes.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function peek(
        bytes calldata
    ) external view virtual override returns (bool success, uint256 rate) {
        return (true, _computeAverage());
    }

    /// @notice Check the current spot exchange rate without any state changes. For oracles like TWAP this will be different from peek().
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return rate The rate of the requested asset / pair / pool.
    function peekSpot(
        bytes calldata
    ) external view virtual override returns (uint256 rate) {
        return _computeAverage();
    }

    /// @notice Update the time in seconds after which get() can be called again.
    /// @param _newFetchTime New time in seconds after which get() can be called again.
    function updateFetchTime(
        uint256 _newFetchTime
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        FETCH_TIME = _newFetchTime;
        emit FetchTimeUpdated(_newFetchTime);
    }

    /// @notice Compute the average of the last 3 prices fetch by the oracle.
    function _computeAverage() internal view returns (uint256) {
        require(lastPrices[2] > 0, "TapOracle: not enough data");
        return (lastPrices[0] + lastPrices[1] + lastPrices[2]) / 3;
    }
}
