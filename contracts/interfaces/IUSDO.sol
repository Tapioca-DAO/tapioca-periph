// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "./IMarket.sol";
import "./ISingularity.sol";
import "./ITapiocaOptionsBroker.sol";
import "./ITapiocaOptionLiquidityProvision.sol";

interface IUSDOBase {
    //common data
    struct IWithdrawParams {
        bool withdraw;
        uint256 withdrawLzFeeAmount;
        bool withdrawOnOtherChain;
        uint16 withdrawLzChainId;
        bytes withdrawAdapterParams;
    }

    struct IApproval {
        bool permitAll;
        bool allowFailure;
        address target;
        bool permitBorrow;
        address owner;
        address spender;
        uint256 value;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct ISendOptions {
        uint256 extraGasLimit;
        address zroPaymentAddress;
    }

    // remove and repay
    struct IRemoveAndRepayExternalContracts {
        address magnetar;
        address singularity;
        address bigBang;
    }
    struct IRemoveAndRepay {
        bool removeAssetFromSGL;
        uint256 removeShare; //slightly greater than repayAmount to cover the interest
        bool repayAssetOnBB;
        uint256 repayAmount; // on BB
        bool removeCollateralFromBB;
        uint256 collateralShare; // from BB
        ITapiocaOptionsBroker.IOptionsExitData exitData;
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
        uint256 removeCollateralShare;
        ITapiocaOptionLiquidityProvision.IOptionsLockData lockData;
        ITapiocaOptionsBroker.IOptionsParticipateData participateData;
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
    struct ILeverageExternalContractsData {
        address swapper;
        address magnetar;
        address tOft;
        address srcMarket;
    }

    function mint(address _to, uint256 _amount) external;

    function burn(address _from, uint256 _amount) external;

    function sendAndLendOrRepay(
        address _from,
        address _to,
        uint16 lzDstChainId,
        address zroPaymentAddress,
        ILendOrRepayParams calldata lendParams,
        IApproval[] calldata approvals,
        IWithdrawParams calldata withdrawParams, //collateral remove data
        bytes calldata adapterParams
    ) external payable;

    function sendForLeverage(
        uint256 amount,
        address leverageFor,
        ILeverageLZData calldata lzData,
        ILeverageSwapData calldata swapData,
        ILeverageExternalContractsData calldata externalData
    ) external payable;

    function initMultiHopBuy(
        address from,
        uint256 collateralAmount,
        uint256 borrowAmount,
        IUSDOBase.ILeverageSwapData calldata swapData,
        IUSDOBase.ILeverageLZData calldata lzData,
        IUSDOBase.ILeverageExternalContractsData calldata externalData,
        bytes calldata airdropAdapterParams,
        IUSDOBase.IApproval[] memory approvals
    ) external payable;
}

interface IUSDO is IUSDOBase, IERC20Metadata {}
