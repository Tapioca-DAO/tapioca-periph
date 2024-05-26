// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// Tapioca
import {IPearlmit} from "tapioca-periph/interfaces/periph/IPearlmit.sol";

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

library PearlmitHash {
    // Batch transfer
    bytes32 public constant _PERMIT_SIGNATURE_APPROVAL_TYPEHASH =
        keccak256("SignatureApproval(uint256 tokenType,address token,uint256 id,uint200 amount,address operator)");

    // Only `signedPermit` is not present, otherwise should be 1:1 with `IPearlmit.PermitBatchTransferFrom`
    bytes32 public constant _PERMIT_BATCH_TRANSFER_FROM_TYPEHASH = keccak256(
        "PermitBatchTransferFrom(SignatureApproval[] approvals,address owner,uint256 nonce,uint48 sigDeadline,uint256 masterNonce,address executor,bytes32 hashedData)SignatureApproval(uint256 tokenType,address token,uint256 id,uint200 amount,address operator)"
    );

    /**
     * @dev Hashes the permit batch transfer from.
     */
    function hashBatchTransferFrom(IPearlmit.PermitBatchTransferFrom calldata batch, uint256 masterNonce)
        internal
        view
        returns (bytes32)
    {
        IPearlmit.SignatureApproval[] memory approvals = batch.approvals;
        uint256 numPermits = approvals.length;
        bytes32[] memory permitHashes = new bytes32[](numPermits);
        for (uint256 i = 0; i < numPermits; ++i) {
            permitHashes[i] = _hashPermitSignatureApproval(approvals[i]);
        }

        return keccak256(
            abi.encode(
                _PERMIT_BATCH_TRANSFER_FROM_TYPEHASH,
                keccak256(abi.encodePacked(permitHashes)),
                batch.nonce,
                batch.sigDeadline,
                masterNonce,
                msg.sender, // executor
                batch.hashedData
            )
        );
    }

    /**
     * @dev Hashes the permit signature approval.
     */
    function _hashPermitSignatureApproval(IPearlmit.SignatureApproval memory approval)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encode(
                _PERMIT_SIGNATURE_APPROVAL_TYPEHASH,
                approval.tokenType,
                approval.token,
                approval.id,
                approval.amount,
                approval.operator
            )
        );
    }
}
