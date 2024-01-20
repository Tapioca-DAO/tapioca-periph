// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

/// @notice Used for performing swap operations when bidding on LiquidationQueue
interface IBidder {
    /// @notice returns the unique name
    function name() external view returns (string memory);

    /// @notice returns the amount of collateral
    /// @param singularity Market to query for
    /// @param tokenInId Token in YieldBox asset id
    /// @param amountIn Token in amount
    /// @param data extra data used for retrieving the ouput
    function getOutputAmount(
        address singularity,
        uint256 tokenInId,
        uint256 amountIn,
        bytes calldata data
    ) external view returns (uint256);

    /// @notice swap USDO to collateral
    /// @param singularity Market to swap for
    /// @param tokenInId Token in asset id
    /// @param amountIn Token in amount
    /// @param data extra data used for the swap operation
    function swap(
        address singularity,
        uint256 tokenInId,
        uint256 amountIn,
        bytes calldata data
    ) external returns (uint256);

    /// @notice returns token tokenIn amount based on tokenOut amount
    /// @param singularity Market to query for
    /// @param tokenInId Token in asset id
    /// @param amountOut Token out amount
    /// @param data extra data used for retrieving the ouput
    function getInputAmount(
        address singularity,
        uint256 tokenInId,
        uint256 amountOut,
        bytes calldata data
    ) external view returns (uint256);
}
