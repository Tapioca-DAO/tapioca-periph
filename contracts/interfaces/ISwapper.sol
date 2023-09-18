// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface ISwapper {
    struct SwapTokensData {
        address tokenIn;
        uint256 tokenInId;
        address tokenOut;
        uint256 tokenOutId;
    }

    struct SwapAmountData {
        uint256 amountIn;
        uint256 shareIn;
        uint256 amountOut;
        uint256 shareOut;
    }

    struct YieldBoxData {
        bool withdrawFromYb;
        bool depositToYb;
    }

    struct SwapData {
        SwapTokensData tokensData;
        SwapAmountData amountData;
        YieldBoxData yieldBoxData;
    }

    //Add more overloads if needed
    function buildSwapData(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 shareIn,
        bool withdrawFromYb,
        bool depositToYb
    ) external view returns (SwapData memory);

    function buildSwapData(
        uint256 tokenInId,
        uint256 tokenOutId,
        uint256 amountIn,
        uint256 shareIn,
        bool withdrawFromYb,
        bool depositToYb
    ) external view returns (SwapData memory);

    function getDefaultDexOptions() external view returns (bytes memory);

    function getOutputAmount(
        SwapData calldata swapData,
        bytes calldata dexOptions
    ) external view returns (uint256 amountOut);

    function getInputAmount(
        SwapData calldata swapData,
        bytes calldata dexOptions
    ) external view returns (uint256 amountIn);

    function swap(
        SwapData calldata swapData,
        uint256 amountOutMin,
        address to,
        bytes calldata dexOptions
    ) external payable returns (uint256 amountOut, uint256 shareOut);
}

interface ICurveSwapper is ISwapper {
    function curvePool() external view returns (address);
}
