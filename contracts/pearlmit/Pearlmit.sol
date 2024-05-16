// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {
    PermitC, PermitC__SignatureTransferExceededPermitExpired, PackedApproval, ZERO_BYTES32
} from "permitc/PermitC.sol";

// Tapioca
import {PearlmitHash} from "./PearlmitHash.sol";
import {IPearlmit} from "tapioca-periph/interfaces/periph/IPearlmit.sol";

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

/**
 * @title Pearlmit
 * @author Limit Break Inc., Tapioca
 * @notice Pearlmit inherit PermitC and implements a new `permitBatchTransferFrom()` function
 * to allow batch transfer of multiple token types.
 */
contract Pearlmit is PermitC {
    error Pearlmit__BadHashedData();

    constructor(string memory name, string memory version) PermitC(name, version) {}

    /**
     * @notice Permit batch approve of multiple token types.
     * @dev Check the validity of a permit batch transfer.
     *      - Reverts if the permit is invalid.
     *      - Reverts if the permit is expired.
     * @dev Invalidate the nonce after checking it.
     * @dev If past allowances for the token still exist, bypass the permit check.
     * @dev When performing the hash check, it uses the msg.sender as the expected operator,
     * countering the possibility of grief.
     * @dev If past allowances for the token still exist, bypass the permit check.
     *
     * @param batch PermitBatchTransferFrom struct containing all necessary data for batch transfer.
     * batch.approvals - array of SignatureApproval structs.
     *      * batch.approvals.tokenType - type of token (0 = ERC20, 1 = ERC721, 2 = ERC1155).
     *      * batch.approvals.token - address of the token.
     *      * batch.approvals.id - id of the token (0 if ERC20).
     *      * batch.approvals.amount - amount of the token (0 if ERC721).
     *      * batch.approvals.operator - address of the operator to transfer the tokens to.
     *      * batch.approvals.approvalExpiration - expiration of the approval.
     * batch.owner - address of the owner of the tokens.
     * batch.nonce - nonce of the owner.
     * batch.sigDeadline - deadline for the signature.
     * batch.signedPermit - signature of the permit.
     *
     * @param hashedData Hashed data that comes with the permit execution. Will be `msg.sender` -> `srcMsgSender` from an LZ perspective.
     * This is useful in an async scenario
     * where the permit is signed to execute some certain actions. The payload can be hashed and used
     * in `hashedData` to trust that the permit is being used for the intended purpose, from the intended executor.
     * The source needs to be trusted to pass a valid `hashedData`, in the case of Pearlmit usage, this'll be
     * a TapiocaOmnichainReceiver contract.
     *
     */
    function permitBatchApprove(IPearlmit.PermitBatchTransferFrom calldata batch, bytes32 hashedData) external {
        _checkPermitBatchApproval(batch, hashedData);

        uint256 numPermits = batch.approvals.length;
        for (uint256 i = 0; i < numPermits; ++i) {
            IPearlmit.SignatureApproval calldata approval = batch.approvals[i];
            __storeApproval(
                approval.token, approval.id, approval.amount, batch.sigDeadline, batch.owner, approval.operator
            );
        }
    }

    /**
     * @dev Identical of PermitC._storeApproval.
     */
    function __storeApproval(
        address token,
        uint256 id,
        uint200 amount,
        uint48 expiration,
        address owner,
        address operator
    ) internal {
        PackedApproval storage allowed = _getPackedApprovalPtr(owner, token, id, ZERO_BYTES32, operator);
        allowed.expiration = expiration;
        allowed.amount = amount;

        emit Approval({owner: owner, token: token, operator: operator, id: id, amount: amount, expiration: expiration});
    }

    /**
     * @dev Generate the digest and check its validity against the permit.
     * @dev If past allowances for the token still exist, bypass the permit check.
     */
    function _checkPermitBatchApproval(IPearlmit.PermitBatchTransferFrom calldata batch, bytes32 hashedData) internal {
        bytes32 digest = _hashTypedDataV4(PearlmitHash.hashBatchTransferFrom(batch, masterNonce(batch.owner)));

        if (batch.hashedData != hashedData) {
            revert Pearlmit__BadHashedData();
        }
        _checkBatchPermitData(batch.nonce, batch.sigDeadline, batch.owner, digest, batch.signedPermit);
    }

    /**
     * @dev Check the validity of a permit batch transfer.
     *      - Reverts if the permit is invalid.
     *      - Reverts if the permit is expired.
     * @dev Invalidate the nonce after checking it.
     */
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
