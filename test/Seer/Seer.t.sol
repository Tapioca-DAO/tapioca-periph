// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import "forge-std/Test.sol";

import {OracleChainlinkSingleConstructorData} from "tapioca-periph/oracle/OracleChainlinkSingle.sol";
import {SequencerFeedMock, RoundData} from "tapioca-periph/mocks/periph/SequencerFeedMock.sol";
import {EthGlpOracle} from "tapioca-periph/oracle/implementation/Arbitrum/EthGlpOracle.sol";
import {IGmxGlpManager} from "tapioca-periph/interfaces/external/gmx/IGmxGlpManager.sol";
import {GLPOracle} from "tapioca-periph/oracle/implementation/Arbitrum/GLPOracle.sol";
import {ITapiocaOracle} from "tapioca-periph/interfaces/periph/ITapiocaOracle.sol";
import {OracleMultiConstructorData} from "tapioca-periph/oracle/OracleMulti.sol";
import {SequencerCheck} from "tapioca-periph/oracle/utils/SequencerCheck.sol";
import {SeerCLSolo} from "tapioca-periph/oracle/SeerCLSolo.sol";
import {Seer} from "tapioca-periph/oracle/Seer.sol";
//External
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

contract SeerTest is Test {
    function test_seer_dai_usdc() public {
        uint256 mainnetBlock = 19_300_000;
        vm.createSelectFork(vm.rpcUrl("mainnet"), mainnetBlock);

        address[] memory addressInAndOutUni = new address[](2);
        addressInAndOutUni[0] = address(0x6B175474E89094C44Da98b954EedeAC495271d0F); //dai
        addressInAndOutUni[1] = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48); //usdc

        IUniswapV3Pool[] memory circuitUniswap = new IUniswapV3Pool[](1);
        circuitUniswap[0] = IUniswapV3Pool(address(0x5777d92f208679DB4b9778590Fa3CAB3aC9e2168));

        uint8[] memory circuitUniIsMultiplied = new uint8[](1);
        circuitUniIsMultiplied[0] = 1;

        address[] memory circuitChainlink = new address[](2);
        circuitChainlink[0] = address(0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9); //dai/usd
        circuitChainlink[1] = address(0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6); //usdc/usd

        uint8[] memory circuitChainIsMultiplied = new uint8[](2);
        circuitChainIsMultiplied[0] = 1;
        circuitChainIsMultiplied[1] = 0;

        address[] memory guardians = new address[](1);
        guardians[0] = address(this);

        Seer seer = new Seer(
            "DAI/USDC",
            "DAI/UDSC",
            18,
            OracleMultiConstructorData({
                addressInAndOutUni: addressInAndOutUni,
                _circuitUniswap: circuitUniswap,
                _circuitUniIsMultiplied: circuitUniIsMultiplied,
                _twapPeriod: 600,
                observationLength: 10,
                _uniFinalCurrency: 0,
                _circuitChainlink: circuitChainlink,
                _circuitChainIsMultiplied: circuitChainIsMultiplied,
                _stalePeriod: 8640000,
                guardians: guardians,
                _description: bytes32(bytes("DAI/USDC")),
                _sequencerUptimeFeed: address(0),
                _admin: address(this)
            })
        );

        {
            (bool success, uint256 rate) = seer.peek("");
            assertTrue(success);
            assertGt(rate, 0);
        }
    }

    function test_seer_eth_usdc() public {
        uint256 mainnetBlock = 19_300_000;
        vm.createSelectFork(vm.rpcUrl("mainnet"), mainnetBlock);

        address[] memory addressInAndOutUni = new address[](2);
        addressInAndOutUni[0] = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); //dai
        addressInAndOutUni[1] = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48); //usdc

        IUniswapV3Pool[] memory circuitUniswap = new IUniswapV3Pool[](1);
        circuitUniswap[0] = IUniswapV3Pool(address(0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640));

        uint8[] memory circuitUniIsMultiplied = new uint8[](1);
        circuitUniIsMultiplied[0] = 0;

        address[] memory circuitChainlink = new address[](2);
        circuitChainlink[0] = address(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419); //ETH/usd
        circuitChainlink[1] = address(0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6); //usdc/usd

        uint8[] memory circuitChainIsMultiplied = new uint8[](2);
        circuitChainIsMultiplied[0] = 1;
        circuitChainIsMultiplied[1] = 0;

        address[] memory guardians = new address[](1);
        guardians[0] = address(this);

        Seer seer = new Seer(
            "ETH/USDC",
            "ETH/UDSC",
            18,
            OracleMultiConstructorData({
                addressInAndOutUni: addressInAndOutUni,
                _circuitUniswap: circuitUniswap,
                _circuitUniIsMultiplied: circuitUniIsMultiplied,
                _twapPeriod: 600,
                observationLength: 10,
                _uniFinalCurrency: 0,
                _circuitChainlink: circuitChainlink,
                _circuitChainIsMultiplied: circuitChainIsMultiplied,
                _stalePeriod: 8640000,
                guardians: guardians,
                _description: bytes32(bytes("ETH/USDC")),
                _sequencerUptimeFeed: address(0),
                _admin: address(this)
            })
        );

        {
            (bool success, uint256 rate) = seer.peek("");
            assertTrue(success);
            assertGt(rate, 0);
        }
    }

    function test_dai_usdc_no_sequencer() public {
        uint256 mainnetBlock = 19_300_000;
        vm.createSelectFork(vm.rpcUrl("mainnet"), mainnetBlock);


        SequencerFeedMock sequencer = new SequencerFeedMock();

        address[] memory addressInAndOutUni = new address[](2);
        addressInAndOutUni[0] = address(0x6B175474E89094C44Da98b954EedeAC495271d0F); //dai
        addressInAndOutUni[1] = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48); //usdc

        IUniswapV3Pool[] memory circuitUniswap = new IUniswapV3Pool[](1);
        circuitUniswap[0] = IUniswapV3Pool(address(0x5777d92f208679DB4b9778590Fa3CAB3aC9e2168));

        uint8[] memory circuitUniIsMultiplied = new uint8[](1);
        circuitUniIsMultiplied[0] = 1;

        address[] memory circuitChainlink = new address[](2);
        circuitChainlink[0] = address(0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9); //dai/usd
        circuitChainlink[1] = address(0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6); //usdc/usd

        uint8[] memory circuitChainIsMultiplied = new uint8[](2);
        circuitChainIsMultiplied[0] = 1;
        circuitChainIsMultiplied[1] = 0;

        address[] memory guardians = new address[](1);
        guardians[0] = address(this);

        Seer seer = new Seer(
            "DAI/USDC",
            "DAI/UDSC",
            18,
            OracleMultiConstructorData({
                addressInAndOutUni: addressInAndOutUni,
                _circuitUniswap: circuitUniswap,
                _circuitUniIsMultiplied: circuitUniIsMultiplied,
                _twapPeriod: 600,
                observationLength: 10,
                _uniFinalCurrency: 0,
                _circuitChainlink: circuitChainlink,
                _circuitChainIsMultiplied: circuitChainIsMultiplied,
                _stalePeriod: 8640000,
                guardians: guardians,
                _description: bytes32(bytes("DAI/USDC")),
                _sequencerUptimeFeed: address(sequencer),
                _admin: address(this)
            })
        );

        sequencer.setLatestRoundData(
            RoundData({answer: 0, roundId: 0, startedAt: block.timestamp, updatedAt: 0, answeredInRound: 0})
        );

        vm.expectRevert(SequencerCheck.GracePeriodNotOver.selector);
        seer.get("");

        uint256 gracePeriodTime = seer.GRACE_PERIOD_TIME();
        skip(gracePeriodTime + 1);

        seer.get("");
    }

    function test_gmx_oracle() public {
        uint256 mainnetBlock = 187_600_000;
        vm.createSelectFork(vm.rpcUrl("arbitrum"), mainnetBlock);

        address[] memory guardians = new address[](1);
        guardians[0] = address(this);
        SeerCLSolo seer = new SeerCLSolo(
            "GMX/USD",
            "GMX/UDS",
            18,
            OracleChainlinkSingleConstructorData(
                address(0xDB98056FecFff59D032aB628337A4887110df3dB),
                1,
                18,
                86400,
                guardians,
                bytes32(bytes("DAI/USDC")),
                address(0xFdB631F5EE196F0ed6FAa767959853A9F217697D),
                address(this)
            )
        );

        {
            (bool success, uint256 rate) = seer.peek("");
            assertTrue(success);
            assertGt(rate, 0);
        }
    }

    function test_eth_seer_solo_oracle() public {
        uint256 mainnetBlock = 187_600_000;
        vm.createSelectFork(vm.rpcUrl("arbitrum"), mainnetBlock);

        address[] memory guardians = new address[](1);
        guardians[0] = address(this);
        SeerCLSolo seer = new SeerCLSolo(
            "ETH/USD",
            "ETH/UDS",
            18,
            OracleChainlinkSingleConstructorData(
                address(0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612),
                1,
                18,
                86400,
                guardians,
                bytes32(bytes("ETH/USDC")),
                address(0),
                address(this)
            )
        );

        {
            (bool success, uint256 rate) = seer.peek("");
            assertTrue(success);
            assertGt(rate, 0);
        }
    }

    function test_eth_glp_seer_solo_oracle() public {
        uint256 mainnetBlock = 187_600_000;
        vm.createSelectFork(vm.rpcUrl("arbitrum"), mainnetBlock);

        address[] memory guardians = new address[](1);
        guardians[0] = address(this);
        SeerCLSolo ethOracle = new SeerCLSolo(
            "ETH/USD",
            "ETH/UDS",
            18,
            OracleChainlinkSingleConstructorData(
                address(0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612),
                1,
                18,
                86400,
                guardians,
                bytes32(bytes("ETH/USDC")),
                address(0),
                address(this)
            )
        );

        GLPOracle glpOracle = new GLPOracle(
            IGmxGlpManager(address(0x3963FfC9dff443c2A94f21b129D429891E32ec18)),
            address(0xFdB631F5EE196F0ed6FAa767959853A9F217697D),
            address(this)
        );

        EthGlpOracle ethGlpOracle = new EthGlpOracle(
            ITapiocaOracle(address(ethOracle)),
            ITapiocaOracle(address(glpOracle)),
            address(0xFdB631F5EE196F0ed6FAa767959853A9F217697D),
            address(this)
        );

        {
            (bool success, uint256 rate) = ethGlpOracle.peek("");
            assertTrue(success);
            assertGt(rate, 0);
        }
    }
}
