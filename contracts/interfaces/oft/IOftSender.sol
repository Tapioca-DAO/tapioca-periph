// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// LZ
import {MessagingReceipt, OFTReceipt} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";

// Tapioca
import {LZSendParam} from "tapioca-periph/interfaces/periph/ITapiocaOmnichainEngine.sol";

interface IOftSender {
    function sendPacket(LZSendParam calldata _lzSendParam, bytes calldata _composeMsg)
        external
        payable
        returns (MessagingReceipt memory msgReceipt, OFTReceipt memory oftReceipt);
}
