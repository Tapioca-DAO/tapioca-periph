// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// LZ
import {OFTMsgCodec} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/libs/OFTMsgCodec.sol";
import {BytesLib} from "solidity-bytes-utils/contracts/BytesLib.sol";

// External
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// Tapioca
import {
    PrepareLzCallData,
    PrepareLzCallReturn,
    ComposeMsgData
} from "tapioca-periph/tapiocaOmnichainEngine/extension/TapiocaOmnichainEngineHelper.sol";
import {TapiocaOmnichainEngineHelper} from
    "tapioca-periph/tapiocaOmnichainEngine/extension/TapiocaOmnichainEngineHelper.sol";
import {ITapiocaOmnichainEngine, LZSendParam} from "tapioca-periph/interfaces/periph/ITapiocaOmnichainEngine.sol";
import {YieldBoxDepositData, MagnetarWithdrawData} from "tapioca-periph/interfaces/periph/IMagnetar.sol";
import {IYieldBox} from "tapioca-periph/interfaces/yieldbox/IYieldBox.sol";
import {IOftSender} from "tapioca-periph/interfaces/oft/IOftSender.sol";
import {MagnetarBaseModule} from "./MagnetarBaseModule.sol";
/*

__/\\\\\\\\\\\\\\\_____/\\\\\\\\\_____/\\\\\\\\\\\\\____/\\\\\\\\\\\_______/\\\\\_____________/\\\\\\\\\_____/\\\\\\\\\____        
 _\///////\\\/////____/\\\\\\\\\\\\\__\/\\\/////////\\\_\/////\\\///______/\\\///\\\________/\\\////////____/\\\\\\\\\\\\\__       
  _______\/\\\________/\\\/////////\\\_\/\\\_______\/\\\_____\/\\\_______/\\\/__\///\\\____/\\\/____________/\\\/////////\\\_      
   _______\/\\\_______\/\\\_______\/\\\_\/\\\\\\\\\\\\\/______\/\\\______/\\\______\//\\\__/\\\_____________\/\\\_______\/\\\_     
    _______\/\\\_______\/\\\\\\\\\\\\\\\_\/\\\/////////________\/\\\_____\/\\\_______\/\\\_\/\\\_____________\/\\\\\\\\\\\\\\\_    
     _______\/\\\_______\/\\\/////////\\\_\/\\\_________________\/\\\_____\//\\\______/\\\__\//\\\____________\/\\\/////////\\\_   
      _______\/\\\_______\/\\\_______\/\\\_\/\\\_________________\/\\\______\///\\\__/\\\_____\///\\\__________\/\\\_______\/\\\_  
       _______\/\\\_______\/\\\_______\/\\\_\/\\\______________/\\\\\\\\\\\____\///\\\\\/________\////\\\\\\\\\_\/\\\_______\/\\\_ 
        _______\///________\///________\///__\///______________\///////////_______\/////_____________\/////////__\///________\///__

*/

/**
 * @title MagnetarYieldBoxModule
 * @author TapiocaDAO
 * @notice Magnetar YieldBox related operations
 */
contract MagnetarYieldBoxModule is MagnetarBaseModule {
    /// @dev Parse a burst call
    fallback() external payable {
        bytes4 funcSig = bytes4(BytesLib.slice(msg.data, 0, 4));
        bytes memory callWithoutSelector = BytesLib.slice(msg.data, 4, msg.data.length - 4);

        if (funcSig == this.depositAsset.selector) {
            depositAsset(abi.decode(callWithoutSelector, (YieldBoxDepositData)));
        }
        if (funcSig == this.withdrawToChain.selector) {
            withdrawToChain(abi.decode(callWithoutSelector, (MagnetarWithdrawData)));
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
        _checkSender(data.from);
        if (!cluster.isWhitelisted(0, data.yieldbox)) {
            // 0 means current chain
            revert Magnetar_TargetNotWhitelisted(data.yieldbox);
        }
        IYieldBox(data.yieldbox).depositAsset(data.assetId, data.from, data.to, data.amount, data.share);
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
     * @param data.unwrap if withdrawn asset is a TOFT, it can be unwrapped on destination
     * @param data.receiver the receiver on the destination chain
     * @param data.receiver the receiver on the destination chain
     * @param data.lzSendParams LZv2 send params
     * @param data.composeGas compose message gas amount
     * @param data.composeMsg LZv2 compose message
     */
    function withdrawToChain(MagnetarWithdrawData memory data) public payable {
        _withdrawToChain(data);
    }
}
