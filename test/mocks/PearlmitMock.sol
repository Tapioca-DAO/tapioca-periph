// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {Pearlmit} from "../../contracts/pearlmit/Pearlmit.sol";
import {IPearlmit} from "tapioca-periph/interfaces/periph/IPearlmit.sol";
import {PearlmitHash} from "../../contracts/pearlmit/PearlmitHash.sol";
/**
 * @title PearlmitMock
 * @dev A mock contract for testing internal Pearlmit functions.
 */

contract PearlmitMock is Pearlmit {
    constructor() Pearlmit("Pearlmit", "1", address(this), 0) {}

    error PermitC__SignatureTransferExceededPermitExpired();

    function checkPermitBatchApproval_(IPearlmit.PermitBatchTransferFrom calldata batch, bytes32 hashedData) public {
        _checkPermitBatchApproval(batch, hashedData);
    }

    function checkBatchPermitData_(
        uint256 nonce,
        uint256 expiration,
        address _owner,
        bytes32 digest,
        bytes calldata signedPermit
    ) public {
        _checkBatchPermitData(nonce, expiration, _owner, digest, signedPermit);
    }

    function clearAllowance_(address _owner, uint256 tokenType, address token, address operator, uint256 id) public {
        _clearAllowance(_owner, tokenType, token, operator, id);
    }
}
