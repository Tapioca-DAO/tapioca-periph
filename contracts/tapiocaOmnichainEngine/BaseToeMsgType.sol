// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

abstract contract BaseToeMsgType {
    // LZ
    uint16 public constant MSG_SEND = 1;

    // Tapioca
    uint16 internal constant MSG_APPROVALS = 500; // Use for ERC20Permit approvals
    uint16 internal constant MSG_NFT_APPROVALS = 501; // Use for ERC721Permit approvals
    uint16 internal constant MSG_PEARLMIT_APPROVAL = 502; // Use for Pearlmit approvals
    uint16 internal constant MSG_REMOTE_TRANSFER = 700; // Use for transferring tokens from the contract from another chain
}
