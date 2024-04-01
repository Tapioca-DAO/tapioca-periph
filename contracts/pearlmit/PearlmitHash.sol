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
    // keccak256("SignatureApproval(uint8 tokenType,address token,uint256 id,uint200 amount,address operator)")
    bytes32 public constant _PERMIT_SIGNATURE_APPROVAL_TYPEHASH =
        0x9907ae0a8b239bb7feef50f64ab23ff79fe790ab79bf66ed21a188dbd846e268;

    // keccak256("PermitBatchTransferFrom(SignatureApproval[] approvals,uint256 nonce,uint48 sigDeadline,uint256 masterNonce)SignatureApproval(address token,uint256 id,uint200 amount,address operator)")
    bytes32 public constant _PERMIT_BATCH_TRANSFER_FROM_TYPEHASH =
        0xb59bf51f2ad95e38709b3bd22127b478138fe26ed8a454e461fd11e1423b53a6;

    /**
     * @dev Hashes the permit batch transfer from.
     */
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
