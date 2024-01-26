// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SafeApprove} from "tapioca-periph/libraries/SafeApprove.sol";

// Tapioca
import {IUniswapV2Factory} from "tapioca-periph/interfaces/external/uniswap/IUniswapV2Factory.sol";
import {IUniswapV2Router02} from "tapioca-periph/interfaces/external/uniswap/IUniswapV2Router02.sol";
import {IYieldBox} from "tapioca-periph/interfaces/yieldbox/IYieldBox.sol";
import {BaseSwapper} from "./BaseSwapper.sol";

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

contract UniswapV2Swapper is BaseSwapper {
    using SafeERC20 for IERC20;
    using SafeApprove for address;

    /// *** VARS ***
    /// ***  ***
    IUniswapV2Router02 public immutable swapRouter;
    IUniswapV2Factory public immutable factory;
    IYieldBox public immutable yieldBox;

    /// *** ERRORS ***
    error InvalidSwap();

    constructor(address _router, address _factory, IYieldBox _yieldBox, address _owner)
        validAddress(_router)
        validAddress(_factory)
        validAddress(address(_yieldBox))
    {
        swapRouter = IUniswapV2Router02(_router);
        factory = IUniswapV2Factory(_factory);
        yieldBox = _yieldBox;
        transferOwnership(_owner);
    }

    /// *** VIEW METHODS ***
    /// ***  ***
    /// @notice returns default bytes swap data
    function getDefaultDexOptions() public view override returns (bytes memory) {
        return abi.encode(block.timestamp + 1 hours);
    }

    /// @notice Computes amount out for amount in
    /// @param swapData operation data
    function getOutputAmount(SwapData calldata swapData, bytes calldata)
        external
        view
        override
        returns (uint256 amountOut)
    {
        (address tokenIn, address tokenOut) = _getTokens(swapData.tokensData, yieldBox);
        address[] memory path = _createPath(tokenIn, tokenOut);
        (uint256 amountIn,) =
            _getAmounts(swapData.amountData, swapData.tokensData.tokenInId, swapData.tokensData.tokenOutId, yieldBox);

        uint256[] memory amounts = swapRouter.getAmountsOut(amountIn, path);
        amountOut = amounts[1];
    }

    /// @notice Comutes amount in for amount out
    function getInputAmount(SwapData calldata swapData, bytes calldata)
        external
        view
        override
        returns (uint256 amountIn)
    {
        (address tokenIn, address tokenOut) = _getTokens(swapData.tokensData, yieldBox);
        address[] memory path = _createPath(tokenIn, tokenOut);
        (, uint256 amountOut) =
            _getAmounts(swapData.amountData, swapData.tokensData.tokenInId, swapData.tokensData.tokenOutId, yieldBox);

        uint256[] memory amounts = swapRouter.getAmountsIn(amountOut, path);
        amountIn = amounts[0];
    }

    struct _SwapMemoryData {
        address tokenIn;
        address tokenOut;
        address[] path;
        uint256 amountIn;
    }

    /// @notice swaps amount in
    /// @param swapData operation data
    /// @param amountOutMin min amount out to receive
    /// @param to receiver address
    /// @param data AMM data
    function swap(SwapData calldata swapData, uint256 amountOutMin, address to, bytes memory data)
        external
        payable
        override
        nonReentrant
        returns (uint256 amountOut, uint256 shareOut)
    {
        _SwapMemoryData memory _swapMemoryData;
        // Get tokens' addresses
        (_swapMemoryData.tokenIn, _swapMemoryData.tokenOut) = _getTokens(swapData.tokensData, yieldBox);

        // Get tokens' amounts
        (_swapMemoryData.amountIn,) =
            _getAmounts(swapData.amountData, swapData.tokensData.tokenInId, swapData.tokensData.tokenOutId, yieldBox);

        // Retrieve tokens from sender or from YieldBox
        _swapMemoryData.amountIn = _extractTokens(
            swapData.yieldBoxData,
            yieldBox,
            _swapMemoryData.tokenIn,
            swapData.tokensData.tokenInId,
            _swapMemoryData.amountIn,
            swapData.amountData.shareIn
        );

        // Perform the swap operation
        if (data.length == 0) {
            data = getDefaultDexOptions();
        }
        {
            uint256 deadline = abi.decode(data, (uint256));
            // Create swap path for UniswapV2Router02 operations
            _swapMemoryData.path = _createPath(_swapMemoryData.tokenIn, _swapMemoryData.tokenOut);
            uint256[] memory amounts = _swap(
                _swapMemoryData.amountIn,
                amountOutMin,
                _swapMemoryData.tokenIn,
                _swapMemoryData.tokenOut,
                swapData.yieldBoxData.depositToYb ? address(this) : to,
                deadline
            );

            // Compute outputs
            amountOut = amounts[1];
        }

        if (swapData.yieldBoxData.depositToYb) {
            if (_swapMemoryData.path[_swapMemoryData.path.length - 1] != address(0)) {
                _swapMemoryData.path[_swapMemoryData.path.length - 1].safeApprove(address(yieldBox), amountOut);
                (, shareOut) = yieldBox.depositAsset(swapData.tokensData.tokenOutId, address(this), to, amountOut, 0);
            } else {
                (, shareOut) = yieldBox.depositETHAsset{value: amountOut}(swapData.tokensData.tokenOutId, to, amountOut);
            }
        }
    }

    function _swap(
        uint256 amountIn,
        uint256 amountOutMin,
        address tokenIn,
        address tokenOut,
        address receiver,
        uint256 deadline
    ) private returns (uint256[] memory amounts) {
        // Create swap path for UniswapV2Router02 operations
        address _tokenIn = tokenIn != address(0) ? tokenIn : swapRouter.WETH();
        address _tokenOut = tokenOut != address(0) ? tokenOut : swapRouter.WETH();
        address[] memory path = _createPath(_tokenIn, _tokenOut);

        if (tokenIn != address(0) && tokenOut != address(0)) {
            tokenIn.safeApprove(address(swapRouter), amountIn);
            amounts = swapRouter.swapExactTokensForTokens(amountIn, amountOutMin, path, receiver, deadline);
        } else if (tokenIn == address(0) && tokenOut != address(0)) {
            amounts = swapRouter.swapExactETHForTokens{value: amountIn}(amountOutMin, path, receiver, deadline);
        } else if (tokenIn != address(0) && tokenOut == address(0)) {
            tokenIn.safeApprove(address(swapRouter), amountIn);
            amounts = swapRouter.swapExactTokensForETH(amountIn, amountOutMin, path, receiver, deadline);
        } else {
            revert InvalidSwap();
        }
    }

    receive() external payable {}
}
