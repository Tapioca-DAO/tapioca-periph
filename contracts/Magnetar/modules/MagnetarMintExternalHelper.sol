// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// Tapioca
import {
    DepositAndSendForLockingData,
    LockAndParticipateData
} from "tapioca-periph/interfaces/periph/IMagnetar.sol";
import {TapiocaOmnichainEngineCodec} from "tapioca-periph/tapiocaOmnichainEngine/TapiocaOmnichainEngineCodec.sol";


contract MagnetarMintExternalHelper {

    function mintBBLendXChainSGLEncoder(bytes memory composeMsg, uint256 amountToSet) public returns (bytes memory) {
        (uint16 msgType_,, uint16 msgIndex_, bytes memory tapComposeMsg_, bytes memory nextMsg_) =
                TapiocaOmnichainEngineCodec.decodeToeComposeMsg(composeMsg);

        DepositAndSendForLockingData memory lendData = abi.decode(tapComposeMsg_, (DepositAndSendForLockingData));
        lendData.lendAmount = amountToSet;

        return 
            TapiocaOmnichainEngineCodec.encodeToeComposeMsg(abi.encode(lendData), msgType_, msgIndex_, nextMsg_);
    }

    function depositYBLendSGLLockXchainTOLPEncoder(bytes memory composeMsg, uint256 amountToSet) public returns (bytes memory) {
         // decode `composeMsg` and re-encode it with updated params
        (uint16 msgType_,, uint16 msgIndex_, bytes memory tapComposeMsg_, bytes memory nextMsg_) =
            TapiocaOmnichainEngineCodec.decodeToeComposeMsg(
                composeMsg
            );

        LockAndParticipateData memory lockData = abi.decode(tapComposeMsg_, (LockAndParticipateData));
        lockData.fraction = amountToSet;

        return
            TapiocaOmnichainEngineCodec.encodeToeComposeMsg(abi.encode(lockData), msgType_, msgIndex_, nextMsg_);
    }
}