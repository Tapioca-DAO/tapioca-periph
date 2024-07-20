// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {
    MessagingReceipt, OFTReceipt, SendParam
} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";
import {ERC20Permit, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

// Tapioca
import {BaseTapiocaOmnichainEngine} from "tap-utils/tapiocaOmnichainEngine/BaseTapiocaOmnichainEngine.sol";
import {TapiocaOmnichainSender} from "tap-utils/tapiocaOmnichainEngine/TapiocaOmnichainSender.sol";
import {ERC20PermitStruct} from "tap-utils/interfaces/periph/ITapiocaOmnichainEngine.sol";
import {LZSendParam} from "tap-utils/interfaces/periph/ITapiocaOmnichainEngine.sol";
import {IPearlmit} from "tap-utils/interfaces/periph/IPearlmit.sol";
import {ICluster} from "tap-utils/interfaces/periph/ICluster.sol";
import {ModuleManager} from "tap-utils/utils/ModuleManager.sol";

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

contract ToeTokenMock is BaseTapiocaOmnichainEngine, ModuleManager, ERC20Permit {
    enum Module {
        ToeTokenSender,
        ToeTokenReceiver
    }

    constructor(
        address _endpoint,
        address _owner,
        address _extExec,
        address _senderModule,
        address _receiverModule,
        IPearlmit _pearlmit,
        ICluster _cluster
    )
        BaseTapiocaOmnichainEngine("ToeTokenMock", "TOEM", _endpoint, _owner, _extExec, _pearlmit, _cluster)
        ERC20Permit("TOEM")
    {
        _setModule(uint8(Module.ToeTokenSender), _senderModule);
        _setModule(uint8(Module.ToeTokenReceiver), _receiverModule);
    }

    function sendPacket(LZSendParam calldata _lzSendParam, bytes calldata _composeMsg)
        public
        payable
        returns (MessagingReceipt memory msgReceipt, OFTReceipt memory oftReceipt)
    {
        (msgReceipt, oftReceipt) = abi.decode(
            _executeModule(
                uint8(Module.ToeTokenSender),
                abi.encodeCall(TapiocaOmnichainSender.sendPacket, (_lzSendParam, _composeMsg)),
                false
            ),
            (MessagingReceipt, OFTReceipt)
        );
    }

    function sendPacketFrom(address _from, LZSendParam calldata _lzSendParam, bytes calldata _composeMsg)
        public
        payable
        returns (MessagingReceipt memory msgReceipt, OFTReceipt memory oftReceipt)
    {
        (msgReceipt, oftReceipt) = abi.decode(
            _executeModule(
                uint8(Module.ToeTokenSender),
                abi.encodeCall(TapiocaOmnichainSender.sendPacketFrom, (_from, _lzSendParam, _composeMsg)),
                false
            ),
            (MessagingReceipt, OFTReceipt)
        );
    }

    function getTypedDataHash(ERC20PermitStruct calldata _permitData) public view returns (bytes32) {
        bytes32 permitTypeHash_ =
            keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

        bytes32 structHash_ = keccak256(
            abi.encode(
                permitTypeHash_,
                _permitData.owner,
                _permitData.spender,
                _permitData.value,
                _permitData.nonce,
                _permitData.deadline
            )
        );
        return _hashTypedDataV4(structHash_);
    }
}
