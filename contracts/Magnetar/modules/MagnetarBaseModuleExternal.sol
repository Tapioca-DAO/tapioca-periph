// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {MagnetarWithdrawData} from "tapioca-periph/interfaces/periph/IMagnetar.sol";
import {IYieldBox} from "tapioca-periph/interfaces/yieldbox/IYieldBox.sol";
import {MagnetarBaseModule} from "./MagnetarBaseModule.sol";

contract MagnetarBaseModuleExternal is MagnetarBaseModule {
    constructor() MagnetarBaseModule() {}

    function withdrawToChain(MagnetarWithdrawData memory data) external {
        _withdrawToChain(data);
    }

    function setApprovalForYieldBox(address _target, IYieldBox _yieldBox) external {
        _setApprovalForYieldBox(_target, _yieldBox);
    }

    function revertYieldBoxApproval(address _target, IYieldBox _yieldBox) external {
        _revertYieldBoxApproval(_target, _yieldBox);
    }

    function extractTokens(address _from, address _token, uint256 _amount) external returns (uint256) {
        return _extractTokens(_from, _token, _amount);
    }
}
