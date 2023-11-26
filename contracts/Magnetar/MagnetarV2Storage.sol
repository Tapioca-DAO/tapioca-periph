// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

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

//OZ
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract MagnetarV2Storage is IERC721Receiver {
    // ************ //
    // *** VARS *** //
    // ************ //
    ICluster public cluster;

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
        ICommonData.IApproval[] revokes;
    }

    struct TOFTSendAndLendData {
        address from;
        address to;
        uint16 lzDstChainId;
        IUSDOBase.ILendOrRepayParams lendParams;
        ICommonData.ISendOptions options;
        ICommonData.IApproval[] approvals;
        ICommonData.IApproval[] revokes;
    }

    struct TOFTSendToStrategyData {
        address from;
        address to;
        uint256 amount;
        uint256 assetId;
        uint16 lzDstChainId;
        ICommonData.ISendOptions options;
    }

    struct TOFTRetrieveFromStrategyData {
        address from;
        uint256 amount;
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
        address user;
        uint256 lendAmount;
        IUSDOBase.IMintData mintData;
        ICommonData.IDepositData depositData;
        ITapiocaOptionLiquidityProvision.IOptionsLockData lockData;
        ITapiocaOptionsBroker.IOptionsParticipateData participateData;
        ICommonData.ICommonExternalContracts externalContracts;
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

    struct HelperExerciseOption {
        ITapiocaOptionsBrokerCrossChain.IExerciseOptionsData optionsData;
        ITapiocaOptionsBrokerCrossChain.IExerciseLZData lzData;
        ITapiocaOptionsBrokerCrossChain.IExerciseLZSendTapData tapSendData;
        ICommonData.IApproval[] approvals;
        ICommonData.IApproval[] revokes;
    }

    struct HelperTOFTRemoveAndRepayAsset {
        address from;
        address to;
        uint16 lzDstChainId;
        address zroPaymentAddress;
        bytes adapterParams;
        ICommonData.ICommonExternalContracts externalData;
        IUSDOBase.IRemoveAndRepay removeAndRepayData;
        ICommonData.IApproval[] approvals;
        ICommonData.IApproval[] revokes;
    }

    // --- ACTIONS IDS ----
    uint16 internal constant PERMIT_YB_ALL = 1; // executed on YieldBox
    uint16 internal constant PERMIT = 2; // ERC20 permit sig type
    uint16 internal constant PERMIT_MARKET = 3; // SGL/BB permit sig type
    uint16 internal constant REVOKE_YB_ALL = 4; // executed on YieldBox
    uint16 internal constant REVOKE_YB_ASSET = 5; // executed on YieldBox

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
    event ClusterSet(ICluster indexed oldCluster, ICluster indexed newCluster);

    // ************** //
    // *** ERRORS *** //
    // ************** //
    error NotAuthorized();

    // ********************** //
    // *** PUBLIC METHODS *** //
    // ********************** //
    /// @notice IERC721Receiver implementation
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    // ************************ //
    // *** INTERNAL METHODS *** //
    // ************************ //
    function _checkSender(address _from) internal view {
        if (_from != msg.sender && !cluster.isWhitelisted(0, msg.sender))
            revert NotAuthorized();
    }

    receive() external payable virtual {}
}
