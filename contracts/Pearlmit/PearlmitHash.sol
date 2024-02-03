// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// Tapioca
import {IPearlmit} from "./IPearlmit.sol";

library PearlmitHash {
    string public constant _PERMIT_SIGNATURE_APPROVAL_TYPEHASH =
        "SignatureApproval(uint8 tokenType,address token,uint256 id,uint200 amount,address operator,uint48 approvalExpiration)";
    string public constant _PERMIT_BATCH_TRANSFER_FROM_TYPEHASH =
        "PermitBatchTransferFrom(SignatureApproval[] approvals,uint256 nonce,uint48 sigDeadline,uint256 masterNonce)SignatureApproval(address token,uint256 id,uint200 amount,address operator,uint48 approvalExpiration)";

    function hashBatchTransferFrom(
        IPearlmit.SignatureApproval[] memory approvals,
        uint256 nonce,
        uint48 sigDeadline,
        uint256 masterNonce
    ) internal pure returns (bytes32) {
        uint256 numPermits = approvals.length;
        bytes32[] memory permitHashes = new bytes32[](numPermits);
        for (uint256 i = 0; i < numPermits; ++i) {
            permitHashes[i] = _hashPermitSignatureApproval(approvals[i]);
        }

        return keccak256(
            abi.encode(
                _PERMIT_BATCH_TRANSFER_FROM_TYPEHASH,
                keccak256(abi.encodePacked(permitHashes)),
                nonce,
                sigDeadline,
                masterNonce
            )
        );
    }

    function _hashPermitSignatureApproval(IPearlmit.SignatureApproval memory approval)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encode(
                _PERMIT_SIGNATURE_APPROVAL_TYPEHASH,
                approval.token,
                approval.tokenType,
                approval.id,
                approval.amount,
                approval.operator,
                approval.approvalExpiration
            )
        );
    }
}
