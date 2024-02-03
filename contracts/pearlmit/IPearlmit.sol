// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

interface IPearlmit {
    enum TokenType {
        ERC20, // 0
        ERC721, // 1
        ERC1155 // 2

    }

    struct SignatureApproval {
        uint8 tokenType; // 0 = ERC20, 1 = ERC721, 2 = ERC1155.
        address token; // Address of the token.
        uint256 id; // ID of the token (0 if ERC20).
        uint200 amount; // Amount of the token (0 if ERC721).
        address operator; // Address of the operator to transfer the tokens to.
    }

    struct PermitBatchTransferFrom {
        SignatureApproval[] approvals; // Array of SignatureApproval structs.
        address owner; // Address of the owner of the tokens.
        uint256 nonce; // Nonce of the owner.
        uint48 sigDeadline; // Deadline for the signature.
        bytes signedPermit; // Signature of the permit.
    }
}
