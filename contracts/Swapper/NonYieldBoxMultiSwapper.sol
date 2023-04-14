// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";

import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./libraries/UniswapV2Library.sol";

contract NonYieldBoxMultiSwapper {
    using BoringERC20 for IERC20;

    // ************ //
    // *** VARS *** //
    // ************ //
    address private immutable factory;
    bytes32 private immutable pairCodeHash;

    /// @notice creates a new MultiSwapper contract
    /// @param _factory UniswapV2Factory address
    /// @param _pairCodeHash UniswapV2 pair code hash
    constructor(address _factory, bytes32 _pairCodeHash) {
        factory = _factory;
        pairCodeHash = _pairCodeHash;
    }

    // ********************** //
    // *** VIEW FUNCTIONS *** //
    // ********************** //
    function getOutputAmount(
        address[] calldata path,
        uint256 amountIn
    ) external view returns (uint256 amountOut) {
        uint256[] memory amounts = UniswapV2Library.getAmountsOut(
            factory,
            amountIn,
            path,
            pairCodeHash
        );
        amountOut = amounts[amounts.length - 1];
    }

    function getInputAmount(
        address[] calldata path,
        uint256 amountOut
    ) external view returns (uint256 amountIn) {
        uint256[] memory amounts = UniswapV2Library.getAmountsIn(
            factory,
            amountOut,
            path,
            pairCodeHash
        );
        amountIn = amounts[0];
    }

    // ************************ //
    // *** PUBLIC FUNCTIONS *** //
    // ************************ //
    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountMinOut,
        address to,
        address[] calldata path,
        uint256 amountIn
    ) external returns (uint256 amountOut) {
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);

        amountOut = _swapExactTokensForTokens(
            amountIn,
            amountMinOut,
            path,
            address(this)
        );

        IERC20(tokenOut).safeTransfer(to, amountOut);
    }

    // ************************* //
    // *** PRIVATE FUNCTIONS *** //
    // ************************* //
    // Swaps an exact amount of tokens for another token through the path passed as an argument
    // Returns the amount of the final token
    function _swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address to
    ) internal returns (uint256 amountOut) {
        uint256[] memory amounts = UniswapV2Library.getAmountsOut(
            factory,
            amountIn,
            path,
            pairCodeHash
        );
        amountOut = amounts[amounts.length - 1];
        require(amountOut >= amountOutMin, "insufficient-amount-out");
        // Required for the next step
        IERC20(path[0]).safeTransfer(
            UniswapV2Library.pairFor(factory, path[0], path[1], pairCodeHash),
            amountIn
        );
        _swap(amounts, path, to);
    }

    // requires the initial amount to have already been sent to the first pair
    function _swap(
        uint256[] memory amounts,
        address[] memory path,
        address _to
    ) internal virtual {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = UniswapV2Library.sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOut)
                : (amountOut, uint256(0));
            address to = i < path.length - 2
                ? UniswapV2Library.pairFor(
                    factory,
                    output,
                    path[i + 2],
                    pairCodeHash
                )
                : _to;

            IUniswapV2Pair(
                UniswapV2Library.pairFor(factory, input, output, pairCodeHash)
            ).swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }
}
