// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

// Tapioca
import {ITapiocaOptionLiquidityProvision} from
    "tapioca-periph/interfaces/tap-token/ITapiocaOptionLiquidityProvision.sol";
import {ICommonData, IWithdrawParams, IDepositData} from "tapioca-periph/interfaces/common/ICommonData.sol";
import {ITapiocaOptionBroker} from "tapioca-periph/interfaces/tap-token/ITapiocaOptionBroker.sol";
import {ICommonOFT} from "tapioca-periph/interfaces/common/ICommonOFT.sol";
import {ISingularity} from "./ISingularity.sol";
import {IMarket} from "./IMarket.sol";

interface IUSDOBase {
    // remove and repay
    struct ILeverageExternalContractsData {
        address swapper;
        address magnetar;
        address tOft;
        address srcMarket;
    }

    struct IRemoveAndRepay {
        bool removeAssetFromSGL;
        uint256 removeAmount; //slightly greater than repayAmount to cover the interest
        bool repayAssetOnBB;
        uint256 repayAmount; // on BB
        bool removeCollateralFromBB;
        uint256 collateralAmount; // from BB
        ITapiocaOptionBroker.IOptionsExitData exitData;
        ITapiocaOptionLiquidityProvision.IOptionsUnlockData unlockData;
        IWithdrawParams assetWithdrawData;
        IWithdrawParams collateralWithdrawData;
    }

    // lend or repay
    struct ILendOrRepayParams {
        bool repay;
        uint256 depositAmount;
        uint256 repayAmount;
        address marketHelper;
        address market;
        bool removeCollateral;
        uint256 removeCollateralAmount;
        ITapiocaOptionLiquidityProvision.IOptionsLockData lockData;
        ITapiocaOptionBroker.IOptionsParticipateData participateData;
    }

    //leverage data
    struct ILeverageLZData {
        uint256 srcExtraGasLimit;
        uint16 lzSrcChainId;
        uint16 lzDstChainId;
        address zroPaymentAddress;
        bytes dstAirdropAdapterParam;
        bytes srcAirdropAdapterParam;
        address refundAddress;
    }

    struct ILeverageSwapData {
        address tokenOut;
        uint256 amountOutMin;
        bytes data;
    }

    struct IMintData {
        bool mint;
        uint256 mintAmount;
        IDepositData collateralDepositData;
    }

    function mint(address _to, uint256 _amount) external;

    function burn(address _from, uint256 _amount) external;

    function setFlashloanHelper(address _helper) external;

    function addFlashloanFee(uint256 _fee) external; //onlyOwner

    function paused() external view returns (bool);
}

interface IUSDO is IUSDOBase, IERC20Metadata {}
