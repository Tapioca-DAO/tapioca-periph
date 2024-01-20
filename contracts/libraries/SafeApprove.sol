// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

interface IToken {
    function approve(address spender, uint256 amount) external returns (bool);
}

library SafeApprove {
    function safeApprove(address token, address to, uint256 value) internal {
        require(token.code.length > 0, "SafeApprove: no contract");

        bool success;
        bytes memory data;
        (success, data) = token.call(abi.encodeCall(IToken.approve, (to, 0)));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "SafeApprove: approve failed"
        );

        if (value > 0) {
            (success, data) = token.call(
                abi.encodeCall(IToken.approve, (to, value))
            );
            require(
                success && (data.length == 0 || abi.decode(data, (bool))),
                "SafeApprove: approve failed"
            );
        }
    }
}
