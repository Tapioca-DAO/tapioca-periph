// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./BaseSwapper.sol";

/*

__/\\\\\\\\\\\\\\\_____/\\\\\\\\\_____/\\\\\\\\\\\\\____/\\\\\\\\\\\_______/\\\\\_____________/\\\\\\\\\_____/\\\\\\\\\____        
 _\///////\\\/////____/\\\\\\\\\\\\\__\/\\\/////////\\\_\/////\\\///______/\\\///\\\________/\\\////////____/\\\\\\\\\\\\\__       
  _______\/\\\________/\\\/////////\\\_\/\\\_______\/\\\_____\/\\\_______/\\\/__\///\\\____/\\\/____________/\\\/////////\\\_      
   _______\/\\\_______\/\\\_______\/\\\_\/\\\\\\\\\\\\\/______\/\\\______/\\\______\//\\\__/\\\_____________\/\\\_______\/\\\_     
    _______\/\\\_______\/\\\\\\\\\\\\\\\_\/\\\/////////________\/\\\_____\/\\\_______\/\\\_\/\\\_____________\/\\\\\\\\\\\\\\\_    
     _______\/\\\_______\/\\\/////////\\\_\/\\\_________________\/\\\_____\//\\\______/\\\__\//\\\____________\/\\\/////////\\\_   
      _______\/\\\_______\/\\\_______\/\\\_\/\\\_________________\/\\\______\///\\\__/\\\_____\///\\\__________\/\\\_______\/\\\_  
       _______\/\\\_______\/\\\_______\/\\\_\/\\\______________/\\\\\\\\\\\____\///\\\\\/________\////\\\\\\\\\_\/\\\_______\/\\\_ 
        _______\///________\///________\///__\///______________\///////////_______\/////_____________\/////////__\///________\///__
*/

contract UniswapV2Swapper is ISwapper, BaseSwapper {
    using SafeERC20 for IERC20;

    /// *** VARS ***
    /// ***  ***
    IUniswapV2Router02 public immutable swapRouter;
    IUniswapV2Factory public immutable factory;
    IYieldBox public immutable yieldBox;

    constructor(
        address _router,
        address _factory,
        IYieldBox _yieldBox
    )
        validAddress(_router)
        validAddress(_factory)
        validAddress(address(_yieldBox))
    {
        swapRouter = IUniswapV2Router02(_router);
        factory = IUniswapV2Factory(_factory);
        yieldBox = _yieldBox;
    }

    /// *** VIEW METHODS ***
    /// ***  ***
    function getDefaultSwapData() public view override returns (bytes memory) {
        return abi.encode(block.timestamp + 1 hours);
    }

    function getOutputAmount(
        SwapData calldata swapData,
        bytes calldata
    ) external view override returns (uint256 amountOut) {
        (address tokenIn, address tokenOut) = _getTokens(
            swapData.tokensData,
            yieldBox
        );
        address[] memory path = _createPath(tokenIn, tokenOut);
        (uint256 amountIn, ) = _getAmounts(
            swapData.amountData,
            swapData.tokensData.tokenInId,
            swapData.tokensData.tokenOutId,
            yieldBox
        );

        uint256[] memory amounts = swapRouter.getAmountsOut(amountIn, path);
        amountOut = amounts[1];
    }

    function getInputAmount(
        SwapData calldata swapData,
        bytes calldata
    ) external view override returns (uint256 amountIn) {
        (address tokenIn, address tokenOut) = _getTokens(
            swapData.tokensData,
            yieldBox
        );
        address[] memory path = _createPath(tokenIn, tokenOut);
        (, uint256 amountOut) = _getAmounts(
            swapData.amountData,
            swapData.tokensData.tokenInId,
            swapData.tokensData.tokenOutId,
            yieldBox
        );

        uint256[] memory amounts = swapRouter.getAmountsIn(amountOut, path);
        amountIn = amounts[0];
    }

    /// *** PUBLIC METHODS ***
    /// ***  ***
    function swap(
        SwapData calldata swapData,
        uint256 amountOutMin,
        address to,
        bytes memory data
    )
        external
        override
        nonReentrant
        returns (uint256 amountOut, uint256 shareOut)
    {
        // Get tokens' addresses
        (address tokenIn, address tokenOut) = _getTokens(
            swapData.tokensData,
            yieldBox
        );

        // Create swap path for UniswapV2Router02 operations
        address[] memory path = _createPath(tokenIn, tokenOut);

        // Get tokens' amounts
        (uint256 amountIn, ) = _getAmounts(
            swapData.amountData,
            swapData.tokensData.tokenInId,
            swapData.tokensData.tokenOutId,
            yieldBox
        );

        // Retrieve tokens from sender or from YieldBox
        amountIn = _extractTokens(
            swapData.yieldBoxData,
            yieldBox,
            tokenIn,
            swapData.tokensData.tokenInId,
            amountIn,
            swapData.amountData.shareIn
        );

        // Perform the swap operation
        _safeApprove(tokenIn, address(swapRouter), amountIn);
        if (data.length == 0) {
            data = getDefaultSwapData();
        }
        uint256 deadline = abi.decode(data, (uint256));
        uint256[] memory amounts = swapRouter.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            swapData.yieldBoxData.depositToYb ? address(this) : to,
            deadline
        );

        // Compute outputs
        amountOut = amounts[1];
        if (swapData.yieldBoxData.depositToYb) {
            _safeApprove(path[path.length - 1], address(yieldBox), amountOut);
            (, shareOut) = yieldBox.depositAsset(
                swapData.tokensData.tokenOutId,
                address(this),
                to,
                amountOut,
                0
            );
        }
    }
}
