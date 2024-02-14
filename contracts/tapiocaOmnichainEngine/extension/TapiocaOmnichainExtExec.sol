// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";

import {
    ERC20PermitApprovalMsg,
    ERC721PermitApprovalMsg
} from "tapioca-periph/interfaces/periph/ITapiocaOmnichainEngine.sol";
import {ERC721Permit} from "tapioca-periph/utils/ERC721Permit.sol"; // TODO audit
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
 * @title TapiocaOmnichainExtExec
 * @author TapiocaDAO
 * @notice Used to execute external calls from a TapiocaOmnichainEngine contract. So to not use TapiocaOmnichainEngine in the call context.
 */
contract TapiocaOmnichainExtExec {
    /**
     * @notice Executes an ERC20 permit approval.
     * @param _approvals The ERC20 permit approval messages.
     */
    function erc20PermitApproval(ERC20PermitApprovalMsg[] calldata _approvals) public {
        uint256 approvalsLength = _approvals.length;
        for (uint256 i = 0; i < approvalsLength;) {
            IERC20Permit(_approvals[i].token).permit(
                _approvals[i].owner,
                _approvals[i].spender,
                _approvals[i].value,
                _approvals[i].deadline,
                _approvals[i].v,
                _approvals[i].r,
                _approvals[i].s
            );
            unchecked {
                ++i;
            }
        }
    }
    /**
     * @notice Executes an ERC721 permit approval.
     * @param _approvals The ERC721 permit approval messages.
     */

    function erc721PermitApproval(ERC721PermitApprovalMsg[] calldata _approvals) public {
        uint256 approvalsLength = _approvals.length;
        for (uint256 i = 0; i < approvalsLength;) {
            ERC721Permit(_approvals[i].token).permit(
                _approvals[i].spender,
                _approvals[i].tokenId,
                _approvals[i].deadline,
                _approvals[i].v,
                _approvals[i].r,
                _approvals[i].s
            );
            unchecked {
                ++i;
            }
        }
    }

    function pearlmitApproval(address pearlmit, IPearlmit.PermitBatchTransferFrom calldata _data) public {
        IPearlmit(pearlmit).permitBatchApprove(_data);
    }
}
