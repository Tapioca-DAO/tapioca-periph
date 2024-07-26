// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {IMagnetarModuleExtender, MagnetarCall} from "tapioca-periph/interfaces/periph/IMagnetar.sol";

contract MagnetarExtenderMock is IMagnetarModuleExtender {
    function isValidActionId(uint8 actionId) external view returns (bool) {
        // we want this to pass the Magnetar check to call with ID 100, then force revert on `handleAction`
        if (actionId == 100) {
            return true;
        }
        // Action 200 does nothing
        if (actionId == 200) {
            return true;
        }
        return false;
    }

    function handleAction(MagnetarCall calldata call) external payable {
        if (call.id == 100) {
            revert("Invalid action id");
        }
    }
}
