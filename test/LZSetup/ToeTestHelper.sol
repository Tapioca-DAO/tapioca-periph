// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.22;

// Lz
import {TestHelper} from "../LZSetup/TestHelper.sol";

// Tapioca
import {
    ERC20PermitApprovalMsg,
    ERC20PermitStruct,
    ERC721PermitApprovalMsg,
    ERC721PermitStruct
} from "tapioca-periph/interfaces/periph/ITapiocaOmnichainEngine.sol";

import "forge-std/Test.sol";

contract ToeTestHelper is TestHelper {
    /**
     * @dev Helper to build an ERC20PermitApprovalMsg.
     * @param _permit The permit data.
     * @param _digest The typed data digest.
     * @param _token The token contract to receive the permit.
     * @param _pkSigner The private key signer.
     */
    function __getERC20PermitData(ERC20PermitStruct memory _permit, bytes32 _digest, address _token, uint256 _pkSigner)
        internal
        pure
        returns (ERC20PermitApprovalMsg memory permitApproval_)
    {
        (uint8 v_, bytes32 r_, bytes32 s_) = vm.sign(_pkSigner, _digest);

        permitApproval_ = ERC20PermitApprovalMsg({
            token: _token,
            owner: _permit.owner,
            spender: _permit.spender,
            value: _permit.value,
            deadline: _permit.deadline,
            v: v_,
            r: r_,
            s: s_
        });
    }

    /**
     * @dev Helper to build an ERC721PermitApprovalMsg.
     * @param _permit The permit data.
     * @param _digest The typed data digest.
     * @param _token The token contract to receive the permit.
     * @param _pkSigner The private key signer.
     */
    function __getERC721PermitData(
        ERC721PermitStruct memory _permit,
        bytes32 _digest,
        address _token,
        uint256 _pkSigner
    ) internal pure returns (ERC721PermitApprovalMsg memory permitApproval_) {
        (uint8 v_, bytes32 r_, bytes32 s_) = vm.sign(_pkSigner, _digest);

        permitApproval_ = ERC721PermitApprovalMsg({
            token: _token,
            tokenId: _permit.tokenId,
            spender: _permit.spender,
            deadline: _permit.deadline,
            v: v_,
            r: r_,
            s: s_
        });
    }
}
