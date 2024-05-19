// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// LZ
import {BytesLib} from "solidity-bytes-utils/contracts/BytesLib.sol";

// Tapioca
import {YieldBoxDepositData, MagnetarWithdrawData} from "tapioca-periph/interfaces/periph/IMagnetar.sol";
import {IYieldBox} from "tapioca-periph/interfaces/yieldbox/IYieldBox.sol";
import {IPearlmit} from "tapioca-periph/pearlmit/PearlmitHandler.sol";
import {MagnetarBaseModule} from "./MagnetarBaseModule.sol";

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

/**
 * @title MagnetarYieldBoxModule
 * @author TapiocaDAO
 * @notice Magnetar YieldBox related operations
 */
contract MagnetarYieldBoxModule is MagnetarBaseModule {
    /// @dev Parse a burst call
    constructor(IPearlmit pearlmit) MagnetarBaseModule(pearlmit) {}

    fallback() external payable {
        bytes4 funcSig = bytes4(BytesLib.slice(msg.data, 0, 4));
        bytes memory callWithoutSelector = BytesLib.slice(msg.data, 4, msg.data.length - 4);

        if (funcSig == this.depositAsset.selector) {
            depositAsset(abi.decode(callWithoutSelector, (YieldBoxDepositData)));
        }
        if (funcSig == this.withdrawHere.selector) {
            withdrawHere(abi.decode(callWithoutSelector, (MagnetarWithdrawData)));
        }
    }

    /// =====================
    /// Public
    /// =====================
    /**
     * @notice Deposit asset to YieldBox.
     * @param data The data without the func sig
     */
    function depositAsset(YieldBoxDepositData memory data) public {
        validateDepositAsset(data);

        IYieldBox(data.yieldBox).depositAsset(data.assetId, data.from, data.to, data.amount, data.share);
    }

    /**
     * @notice performs a withdraw operation
     * @dev it can withdraw on the current chain or it can send it to another one
     *     - if `dstChainId` is 0 performs a same-chain withdrawal
     *          - all parameters except `yieldBox`, `assetId` and `amount` or `share` are ignored
     *     - if `dstChainId` is NOT 0, the method requires gas for the `send` operation
     *
     * @param data.yieldBox the YieldBox address
     * @param data.assetId the YieldBox asset id to withdraw
     * @param data.receiver the assets receiver
     * @param data.amount the amount to withdraw
     * @param data.unwrap if withdrawn asset is a TOFT, it can be unwrapped
     * @param data.withdraw has to be true
     */
    function withdrawHere(MagnetarWithdrawData memory data) public payable {
        validateWithdraw(data);
        _withdrawHere(data);
    }

    /// =====================
    /// Private
    /// =====================
    function validateDepositAsset(YieldBoxDepositData memory data) private view {
        _checkSender(data.from);
        _checkWhitelisted(data.yieldBox);
    }

    function validateWithdraw(MagnetarWithdrawData memory data) private view {
        _checkWhitelisted(data.yieldBox);

        if (data.amount == 0) revert Magnetar_ActionParamsMismatch();
        if (!data.withdraw) revert Magnetar_ActionParamsMismatch();
    }
}
