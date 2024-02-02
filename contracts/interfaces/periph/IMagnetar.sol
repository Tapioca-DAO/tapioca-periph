// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// Tapioca
import {ITapiocaOptionLiquidityProvision} from
    "tapioca-periph/interfaces/tap-token/ITapiocaOptionLiquidityProvision.sol";
import {
    ICommonData,
    IWithdrawParams,
    IDepositData,
    ICommonExternalContracts
} from "tapioca-periph/interfaces/common/ICommonData.sol";
import {ITapiocaOptionBroker} from "tapioca-periph/interfaces/tap-token/ITapiocaOptionBroker.sol";
import {IMagnetarHelper} from "tapioca-periph/interfaces/periph/IMagnetarHelper.sol";
import {IUSDOBase} from "tapioca-periph/interfaces/bar/IUSDO.sol";

interface IMagnetar {
    struct Call {
        uint8 id;
        address target;
        uint256 value;
        bool allowFailure;
        bytes call;
    }

    struct DepositRepayAndRemoveCollateralFromMarketData {
        address market;
        address user;
        uint256 depositAmount;
        uint256 repayAmount;
        uint256 collateralAmount;
        bool extractFromSender;
        IWithdrawParams withdrawCollateralParams;
        uint256 valueAmount;
    }

    struct ExitPositionAndRemoveCollateralData {
        address user;
        ICommonExternalContracts externalData;
        IUSDOBase.IRemoveAndRepay removeAndRepayData;
        uint256 valueAmount;
    }

    struct DepositAddCollateralAndBorrowFromMarketData {
        address market;
        address user;
        uint256 collateralAmount;
        uint256 borrowAmount;
        bool extractFromSender;
        bool deposit;
        IWithdrawParams withdrawParams;
        uint256 valueAmount;
    }

    struct MintFromBBAndLendOnSGLData {
        address user;
        uint256 lendAmount;
        IUSDOBase.IMintData mintData;
        IDepositData depositData;
        ITapiocaOptionLiquidityProvision.IOptionsLockData lockData;
        ITapiocaOptionBroker.IOptionsParticipateData participateData;
        ICommonExternalContracts externalContracts;
    }

    struct YieldBoxDepositData {
        address yieldbox;
        uint256 assetId;
        address from;
        address to;
        uint256 amount;
        uint256 share;
    }

    struct WithdrawToChainData {
        address yieldBox;
        address from;
        uint256 assetId;
        uint16 dstChainId;
        bytes32 receiver;
        uint256 amount;
        bytes adapterParams;
        address refundAddress;
        uint256 gas;
        bool unwrap;
        address zroPaymentAddress;
    }

    function MAGNETAR_ACTION_MARKET() external view returns (uint8);

    function MAGNETAR_ACTION_MARKET_MODULE() external view returns (uint8);

    function MAGNETAR_ACTION_PERMIT() external view returns (uint8);

    function MAGNETAR_ACTION_TAP_TOKEN() external view returns (uint8);

    function MAGNETAR_ACTION_TOFT() external view returns (uint8);

    function MAGNETAR_ACTION_YIELDBOX_MODULE() external view returns (uint8);

    function burst(Call[] memory calls) external payable;

    function cluster() external view returns (address);

    function helper() external view returns (address);

    function depositRepayAndRemoveCollateralFromMarket(DepositRepayAndRemoveCollateralFromMarketData memory _data)
        external
        payable;

    function exitPositionAndRemoveCollateral(ExitPositionAndRemoveCollateralData memory _data) external payable;

    function depositAddCollateralAndBorrowFromMarket(DepositAddCollateralAndBorrowFromMarketData memory _data)
        external
        payable;

    function mintFromBBAndLendOnSGL(MintFromBBAndLendOnSGLData memory _data) external payable;

    function withdrawToChain(WithdrawToChainData memory _data) external payable;
    function depositAsset(YieldBoxDepositData memory _data) external;

    receive() external payable;
}
