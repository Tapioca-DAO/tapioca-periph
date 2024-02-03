// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {PermitC, PermitC__SignatureTransferExceededPermitExpired} from "permitc/PermitC.sol";

// Tapioca
import {PearlmitHash} from "./PearlmitHash.sol";
import {IPearlmit} from "./IPearlmit.sol";

contract Pearlmit is PermitC {
    constructor(string memory name, string memory version) PermitC(name, version) {}

    function permitBatchTransferFrom(IPearlmit.PermitBatchTransferFrom calldata batch) external {
        _checkPermitBatchApproval(batch);

        uint256 numPermits = batch.approvals.length;
        for (uint256 i = 0; i < numPermits; ++i) {
            IPearlmit.SignatureApproval calldata approval = batch.approvals[i];
            if (approval.tokenType == uint8(IPearlmit.TokenType.ERC20)) {
                _transferFromERC20(approval.token, batch.owner, approval.operator, 0, approval.amount);
            } else if (approval.tokenType == uint8(IPearlmit.TokenType.ERC721)) {
                _transferFromERC721(batch.owner, approval.operator, approval.token, approval.id);
            } else if (approval.tokenType == uint8(IPearlmit.TokenType.ERC1155)) {
                _transferFromERC1155(approval.token, batch.owner, approval.operator, approval.id, approval.amount);
            }
        }
    }

    function _checkPermitBatchApproval(IPearlmit.PermitBatchTransferFrom calldata batch) internal {
        bytes32 digest = _hashTypedDataV4(
            PearlmitHash.hashBatchTransferFrom(
                batch.approvals, batch.nonce, batch.sigDeadline, masterNonce(batch.owner)
            )
        );

        _checkBatchPermitData(batch.nonce, batch.sigDeadline, batch.owner, digest, batch.signedPermit);
    }

    function _checkBatchPermitData(
        uint256 nonce,
        uint256 expiration,
        address owner,
        bytes32 digest,
        bytes calldata signedPermit
    ) internal {
        if (block.timestamp > expiration) {
            revert PermitC__SignatureTransferExceededPermitExpired();
        }

        _verifyPermitSignature(digest, signedPermit, owner);
        _checkAndInvalidateNonce(owner, nonce);
    }
}
