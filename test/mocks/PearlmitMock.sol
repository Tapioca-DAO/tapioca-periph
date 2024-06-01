// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {Pearlmit} from "../../contracts/pearlmit/Pearlmit.sol";
import {IPearlmit} from "tapioca-periph/interfaces/periph/IPearlmit.sol";
import {PearlmitHash} from "../../contracts/pearlmit/PearlmitHash.sol";

contract PearlmitMock is Pearlmit {
    constructor() Pearlmit("Pearlmit", "1", address(this), 0) {}

    function checkPermitBatchApproval_(IPearlmit.PermitBatchTransferFrom calldata batch, bytes32 hashedData) public {
        bytes32 digest = _hashTypedDataV4(PearlmitHash.hashBatchTransferFrom(batch, _masterNonces[batch.owner]));

        if (batch.hashedData != hashedData) {
            revert Pearlmit__BadHashedData();
        }
        _checkBatchPermitData(batch.nonce, batch.sigDeadline, batch.owner, digest, batch.signedPermit);
    }
}
