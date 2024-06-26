// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import "forge-std/Test.sol";

// External
import {ITapiocaOracle} from "tapioca-periph/interfaces/periph/ITapiocaOracle.sol";
import {UsdoMarketOracle} from "tapioca-periph/oracle/UsdoMarketOracle.sol";

// Tests
import {OracleMock} from "../mocks/OracleMock.sol";

contract UsdoMarketOracleTest is Test {
    ITapiocaOracle public assetOracle;
    UsdoMarketOracle public usdoAssetOracle;

    uint256 constant ETH_PRICE = 2000 * 1e18;
    uint256 constant USDO_PRICE = 5 * 1e14; // If ETH/USD is 2000, USDO/ETH is the inverse, 1/2000, 0.0005

    function setUp() public {
        assetOracle = ITapiocaOracle(new OracleMock("ETH/USD", "ETH/USD", 2000 * 1e18)); // 2000 USD
        usdoAssetOracle = new UsdoMarketOracle(assetOracle, address(this));
    }

    function testSetup() public {
        assertEq(address(usdoAssetOracle.marketAssetOracle()), address(assetOracle));
        assertEq(assetOracle.decimals(), 18);

        (, uint256 getRate) = assetOracle.get("");
        assertEq(getRate, ETH_PRICE);
        (, uint256 peekRate) = assetOracle.peek("");
        assertEq(peekRate, ETH_PRICE);

        assertEq(assetOracle.peekSpot(""), ETH_PRICE);
        assertEq(assetOracle.name(""), "ETH/USD");
        assertEq(assetOracle.symbol(""), "ETH/USD");
    }

    function testDecimals() public {
        assertEq(usdoAssetOracle.decimals(), 18);
    }

    function testGet() public {
        (bool success, uint256 rate) = usdoAssetOracle.get("0x");
        assertTrue(success);
        assertEq(rate, USDO_PRICE);
    }

    function testPeek() public {
        (bool success, uint256 rate) = usdoAssetOracle.peek("0x");
        assertTrue(success);
        assertEq(rate, USDO_PRICE);
    }

    function testPeekSpot() public {
        assertEq(usdoAssetOracle.peekSpot("0x"), USDO_PRICE);
    }

    function testName() public {
        assertEq(usdoAssetOracle.name("0x"), "Inverse ETH/USD");
    }

    function testSymbol() public {
        assertEq(usdoAssetOracle.symbol("0x"), "Inv ETH/USD");
    }
}
