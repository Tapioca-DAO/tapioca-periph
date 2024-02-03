// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

interface IPearlmit {
    enum TokenType {
        ERC20,
        ERC721,
        ERC1155
    }
    struct SignatureApproval {
        uint8 tokenType;
        address token;
        uint256 id;
        uint200 amount;
        address operator;
        uint48 approvalExpiration;
    }

    struct PermitBatchTransferFrom {
        SignatureApproval[] approvals;
        address owner;
        uint256 nonce;
        uint48 sigDeadline;
        bytes signedPermit;
    }
}
