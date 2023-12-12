// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library SafeApprove {
    function safeApprove(address token, address to, uint256 value) internal {
        require(token.code.length > 0, "SafeApprove: no contract");

        bool success;
        bytes memory data;
        (success, data) = token.call(abi.encodeCall(IERC20.approve, (to, 0)));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "SafeApprove: approve failed"
        );

        (success, data) = token.call(
            abi.encodeCall(IERC20.approve, (to, value))
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "SafeApprove: approve failed"
        );
    }
}
