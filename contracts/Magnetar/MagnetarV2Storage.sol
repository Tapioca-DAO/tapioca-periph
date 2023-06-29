// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

//Boring
import "@boringcrypto/boring-solidity/contracts/libraries/BoringRebase.sol";

//TAPIOCA
import "../interfaces/IOracle.sol";
import "../interfaces/ISingularity.sol";
import "../interfaces/IBigBang.sol";
import "../interfaces/ITapiocaOFT.sol";
import "../interfaces/ISwapper.sol";
import "../interfaces/ITapiocaOptionsBroker.sol";
import "../interfaces/ITapiocaOptionLiquidityProvision.sol";
import "../interfaces/IPenrose.sol";
import "../interfaces/ITapiocaOptionsBroker.sol";

import {IUSDOBase} from "../interfaces/IUSDO.sol";

//YIELDBOX
import "tapioca-sdk/dist/contracts/YieldBox/contracts/enums/YieldBoxTokenType.sol";

contract MagnetarV2Storage {
    // ************ //
    // *** VARS *** //
    // ************ //
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    struct MarketInfo {
        address collateral;
        uint256 collateralId;
        address asset;
        uint256 assetId;
        IOracle oracle;
        bytes oracleData;
        uint256 totalCollateralShare;
        uint256 userCollateralShare;
        Rebase totalBorrow;
        uint256 userBorrowPart;
        uint256 currentExchangeRate;
        uint256 spotExchangeRate;
        uint256 oracleExchangeRate;
        uint256 totalBorrowCap;
        uint256 totalYieldBoxCollateralShare;
        uint256 totalYieldBoxCollateralAmount;
        uint256 totalYieldBoxAssetShare;
        uint256 totalYieldBoxAssetAmount;
        TokenType yieldBoxCollateralTokenType;
        address yieldBoxCollateralContractAddress;
        address yieldBoxCollateralStrategyAddress;
        uint256 yieldBoxCollateralTokenId;
        TokenType yieldBoxAssetTokenType;
        address yieldBoxAssetContractAddress;
        address yieldBoxAssetStrategyAddress;
        uint256 yieldBoxAssetTokenId;
    }
    struct SingularityInfo {
        MarketInfo market;
        Rebase totalAsset;
        uint256 userAssetFraction;
        ISingularity.AccrueInfo accrueInfo;
        uint256 utilization;
    }
    struct BigBangInfo {
        MarketInfo market;
        IBigBang.AccrueInfo accrueInfo;
        uint256 minDebtRate;
        uint256 maxDebtRate;
        uint256 debtRateAgainstEthMarket;
        address mainBBMarket;
        uint256 mainBBDebtRate;
        uint256 currentDebtRate;
    }

    // --- ACTIONS DATA ----
    struct Call {
        uint16 id;
        address target;
        uint256 value;
        bool allowFailure;
        bytes call;
    }

    struct Result {
        bool success;
        bytes returnData;
    }

    struct PermitData {
        address owner;
        address spender;
        uint256 value;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct PermitAllData {
        address owner;
        address spender;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct WrapData {
        address from;
        address to;
        uint256 amount;
    }

    struct WrapNativeData {
        address to;
    }

    struct TOFTSendAndBorrowData {
        address from;
        address to;
        uint16 lzDstChainId;
        bytes airdropAdapterParams;
        ITapiocaOFT.IBorrowParams borrowParams;
        ICommonData.IWithdrawParams withdrawParams;
        ICommonData.ISendOptions options;
        ICommonData.IApproval[] approvals;
    }

    struct TOFTSendAndLendData {
        address from;
        address to;
        uint16 lzDstChainId;
        IUSDOBase.ILendOrRepayParams lendParams;
        ICommonData.ISendOptions options;
        ICommonData.IApproval[] approvals;
    }

    struct TOFTSendToStrategyData {
        address from;
        address to;
        uint256 amount;
        uint256 share;
        uint256 assetId;
        uint16 lzDstChainId;
        ICommonData.ISendOptions options;
    }

    struct TOFTRetrieveFromStrategyData {
        address from;
        uint256 amount;
        uint256 share;
        uint256 assetId;
        uint16 lzDstChainId;
        address zroPaymentAddress;
        bytes airdropAdapterParam;
    }

    struct YieldBoxDepositData {
        uint256 assetId;
        address from;
        address to;
        uint256 amount;
        uint256 share;
    }

    struct SGLAddCollateralData {
        address from;
        address to;
        bool skim;
        uint256 amount;
        uint256 share;
    }

    struct SGLBorrowData {
        address from;
        address to;
        uint256 amount;
    }

    struct SGLLendData {
        address from;
        address to;
        bool skim;
        uint256 share;
    }

    struct SGLRepayData {
        address from;
        address to;
        bool skim;
        uint256 part;
    }

    struct HelperRemoveAssetData {
        address market;
        address user;
        uint256 fraction;
    }

    struct HelperLendData {
        address market;
        address from;
        uint256 amount;
        bool deposit;
        bool extractFromSender;
        ITapiocaOptionLiquidityProvision.IOptionsLockData lockData;
        ITapiocaOptionsBroker.IOptionsParticipateData participateData;
    }

    struct HelperBorrowData {
        address market;
        address user;
        uint256 collateralAmount;
        uint256 borrowAmount;
        bool extractFromSender;
        bool deposit;
        bool withdraw;
        bytes withdrawData;
    }

    struct HelperDepositRepayRemoveCollateral {
        address market;
        address user;
        uint256 depositAmount;
        uint256 repayAmount;
        uint256 collateralAmount;
        bool extractFromSender;
        ICommonData.IWithdrawParams withdrawCollateralParams;
    }

    struct HelperBuyCollateral {
        address market;
        address from;
        uint256 borrowAmount;
        uint256 supplyAmount;
        uint256 minAmountOut;
        ISwapper swapper;
        bytes dexData;
    }

    struct HelperSellCollateral {
        address market;
        address from;
        uint256 share;
        uint256 minAmountOut;
        ISwapper swapper;
        bytes dexData;
    }

    struct HelperExerciseOption {
        ITapiocaOptionsBrokerCrossChain.IExerciseOptionsData optionsData;
        ITapiocaOptionsBrokerCrossChain.IExerciseLZData lzData;
        ITapiocaOptionsBrokerCrossChain.IExerciseLZSendTapData tapSendData;
        ICommonData.IApproval[] approvals;
    }

    struct HelperMultiHopBuy {
        address from;
        uint256 collateralAmount;
        uint256 borrowAmount;
        IUSDOBase.ILeverageSwapData swapData;
        IUSDOBase.ILeverageLZData lzData;
        IUSDOBase.ILeverageExternalContractsData externalData;
        bytes airdropAdapterParams;
        ICommonData.IApproval[] approvals;
    }

    struct HelperMultiHopSell {
        address from;
        uint256 share;
        IUSDOBase.ILeverageSwapData swapData;
        IUSDOBase.ILeverageLZData lzData;
        IUSDOBase.ILeverageExternalContractsData externalData;
        bytes airdropAdapterParams;
        ICommonData.IApproval[] approvals;
    }

    struct HelperMarketRemoveAndRepayAsset {
        address user;
        IUSDOBase.IRemoveAndRepayExternalContracts externalData;
        IUSDOBase.IRemoveAndRepay removeAndRepayData;
    }

    struct HelperTOFTRemoveAndRepayAsset {
        address from;
        address to;
        uint16 lzDstChainId;
        address zroPaymentAddress;
        bytes adapterParams;
        IUSDOBase.IRemoveAndRepayExternalContracts externalData;
        IUSDOBase.IRemoveAndRepay removeAndRepayData;
        ICommonData.IApproval[] approvals;
    }

    // --- ACTIONS IDS ----
    uint16 internal constant PERMIT_ALL = 1;
    uint16 internal constant PERMIT = 2;

    uint16 internal constant YB_DEPOSIT_ASSET = 100;
    uint16 internal constant YB_WITHDRAW_TO = 102;

    uint16 internal constant MARKET_ADD_COLLATERAL = 200;
    uint16 internal constant MARKET_BORROW = 201;
    uint16 internal constant MARKET_LEND = 203;
    uint16 internal constant MARKET_REPAY = 204;
    uint16 internal constant MARKET_YBDEPOSIT_AND_LEND = 205;
    uint16 internal constant MARKET_YBDEPOSIT_COLLATERAL_AND_BORROW = 206;
    uint16 internal constant MARKET_REMOVE_ASSET = 207;
    uint16 internal constant MARKET_DEPOSIT_REPAY_REMOVE_COLLATERAL = 208;
    uint16 internal constant MARKET_BUY_COLLATERAL = 209;
    uint16 internal constant MARKET_SELL_COLLATERAL = 210;
    uint16 internal constant MARKET_MULTIHOP_BUY = 211;
    uint16 internal constant MARKET_MULTIHOP_SELL = 212;

    uint16 internal constant TOFT_WRAP = 300;
    uint16 internal constant TOFT_SEND_FROM = 301;
    uint16 internal constant TOFT_SEND_APPROVAL = 302;
    uint16 internal constant TOFT_SEND_AND_BORROW = 303;
    uint16 internal constant TOFT_SEND_AND_LEND = 304;
    uint16 internal constant TOFT_DEPOSIT_TO_STRATEGY = 305;
    uint16 internal constant TOFT_RETRIEVE_FROM_STRATEGY = 306;
    uint16 internal constant TOFT_REMOVE_AND_REPAY = 307;

    uint16 internal constant TAP_EXERCISE_OPTION = 400;

    // ************** //
    // *** EVENTS *** //
    // ************** //
    event ApprovalForAll(address owner, address operator, bool approved);

    // ************************ //
    // *** INTERNAL METHODS *** //
    // ************************ //
    function _checkSender(address _from) internal view {
        require(_from == msg.sender, "MagnetarV2: operator not approved");
    }

    receive() external payable virtual {}
}
