// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// LZ
import {
    SendParam,
    MessagingFee,
    OFTReceipt,
    MessagingReceipt
} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/
interface ITapiocaOmnichainReceiveExtender {
    function isMsgTypeValid(uint16 _msgType) external view returns (bool);
    function toeComposeReceiver(uint16 _msgType, address _srcChainSender, bytes memory _toeComposeMsg)
        external
        payable;
}

interface ITapiocaOmnichainEngine {
    /**
     * =======================
     * LZ functions
     * =======================
     */
    function combineOptions(uint32 _eid, uint16 _msgType, bytes calldata _extraOptions)
        external
        view
        returns (bytes memory);

    /**
     * =======================
     * Tapioca added functions
     * =======================
     */
    function sendPacket(LZSendParam calldata _lzSendParam, bytes calldata _composeMsg)
        external
        payable
        returns (MessagingReceipt memory msgReceipt, OFTReceipt memory oftReceipt);

    function sendPacketFrom(address _from, LZSendParam calldata _lzSendParam, bytes calldata _composeMsg)
        external
        payable
        returns (MessagingReceipt memory msgReceipt, OFTReceipt memory oftReceipt);

    function getTypedDataHash(ERC20PermitStruct calldata _permitData) external view returns (bytes32);

    function quoteSendPacket(
        SendParam calldata _sendParam,
        bytes calldata _extraOptions,
        bool _payInLzToken,
        bytes calldata _composeMsg,
        bytes calldata /*_oftCmd*/ // @dev unused in the default implementation.
    ) external view returns (MessagingFee memory msgFee);
}

/// =======================
/// ========= LZ ==========
/// =======================

/**
 * @param sendParam The parameters for the send operation.
 * @param fee The calculated fee for the send() operation.
 *      - nativeFee: The native fee.
 *      - lzTokenFee: The lzToken fee.
 * @param _extraOptions Additional options for the send() operation.
 * @param refundAddress The address to refund the native fee to.
 */
struct LZSendParam {
    SendParam sendParam;
    MessagingFee fee;
    bytes extraOptions;
    address refundAddress;
}

/// ================================
/// ========= BASE COMPOSE =========
/// ================================

/**
 * @dev Used in TapTokenHelper.
 */
struct RemoteTransferMsg {
    address owner;
    LZSendParam lzSendParam;
    bytes composeMsg;
}

/**
 * Structure of an ERC20 permit message.
 */
struct ERC20PermitStruct {
    address owner;
    address spender;
    uint256 value;
    uint256 nonce;
    uint256 deadline;
}

/**
 * @notice Encodes the message for the ercPermitApproval() operation.
 */
struct ERC20PermitApprovalMsg {
    address token;
    address owner;
    address spender;
    uint256 value;
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
}

/**
 * Structure of an ERC721 permit message.
 */
struct ERC721PermitStruct {
    address spender;
    uint256 tokenId;
    uint256 nonce;
    uint256 deadline;
}

/**
 * @notice Encodes the message for the ercPermitApproval() operation.
 */
struct ERC721PermitApprovalMsg {
    address token;
    address spender;
    uint256 tokenId;
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
}

/**
 * @notice Encodes the message for the ybPermitAll() operation.
 */
struct YieldBoxApproveAllMsg {
    address target;
    address owner;
    address spender;
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
    bool permit;
}

/**
 * @notice Encodes the message for the ybPermitAll() operation.
 */
struct YieldBoxApproveAssetMsg {
    address target;
    address owner;
    address spender;
    uint256 assetId;
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
    bool permit;
}

/**
 * @notice Encodes the message for the market.permitAction() or market.permitBorrow() operations.
 */
struct MarketPermitActionMsg {
    address target;
    address owner;
    address spender;
    uint256 value;
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
    bool permitAsset;
}
