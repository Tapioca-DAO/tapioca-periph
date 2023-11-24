// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.18;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoterV2.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./libraries/OracleLibrary.sol";
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

interface ISwapRouterReader {
    function WETH9() external view returns (address);
}

interface IWETH9 {
    function deposit() external payable;

    function withdraw(uint wad) external;
}

/// @title UniswapV3 swapper contract
contract UniswapV3Swapper is BaseSwapper {
    using SafeERC20 for IERC20;

    // ************ //
    // *** VARS *** //
    // ************ //
    IYieldBox private immutable yieldBox;
    ISwapRouter public immutable swapRouter;
    IUniswapV3Factory public immutable factory;

    uint24 public poolFee = 3000;
    uint32 public twapDuration = 60;

    // ************** //
    // *** EVENTS *** //
    // ************** //
    event PoolFee(uint256 indexed _old, uint256 indexed _new);

    // ************** //
    // *** ERRORS *** //
    // ************** //
    error UnwrapFailed();

    constructor(
        IYieldBox _yieldBox,
        ISwapRouter _swapRouter,
        IUniswapV3Factory _factory,
        address _owner
    )
        validAddress(address(_yieldBox))
        validAddress(address(_swapRouter))
        validAddress(address(_factory))
    {
        yieldBox = _yieldBox;
        swapRouter = _swapRouter;
        factory = _factory;
        transferOwnership(_owner);
    }

    /// *** OWNER METHODS ***
    /// ***  ***
    function setPoolFee(uint24 _newFee) external onlyOwner {
        emit PoolFee(poolFee, _newFee);
        poolFee = _newFee;
    }

    /// *** VIEW METHODS ***
    /// ***  ***
    /// @notice returns default bytes swap data
    function getDefaultDexOptions()
        public
        view
        override
        returns (bytes memory)
    {
        return abi.encode(block.timestamp + 1 hours);
    }

    /// @notice Computes amount out for amount in
    /// @param swapData operation data
    function getOutputAmount(
        SwapData calldata swapData,
        bytes calldata
    ) external view override returns (uint256 amountOut) {
        (address tokenIn, address tokenOut) = _getTokens(
            swapData.tokensData,
            yieldBox
        );

        (uint256 amountIn, ) = _getAmounts(
            swapData.amountData,
            swapData.tokensData.tokenInId,
            swapData.tokensData.tokenOutId,
            yieldBox
        );

        address pool = factory.getPool(tokenIn, tokenOut, poolFee);
        (int24 tick, ) = OracleLibrary.consult(pool, twapDuration);

        amountOut = OracleLibrary.getQuoteAtTick(
            tick,
            uint128(amountIn),
            tokenIn,
            tokenOut
        );
    }

    /// @notice Comutes amount in for amount out
    function getInputAmount(
        SwapData calldata swapData,
        bytes calldata
    ) external view override returns (uint256 amountIn) {
        (address tokenIn, address tokenOut) = _getTokens(
            swapData.tokensData,
            yieldBox
        );

        (, uint256 amountOut) = _getAmounts(
            swapData.amountData,
            swapData.tokensData.tokenInId,
            swapData.tokensData.tokenOutId,
            yieldBox
        );

        address pool = factory.getPool(tokenIn, tokenOut, poolFee);

        (int24 tick, ) = OracleLibrary.consult(pool, twapDuration);
        amountIn = OracleLibrary.getQuoteAtTick(
            tick,
            uint128(amountOut),
            tokenOut,
            tokenIn
        );
    }

    /// *** PUBLIC METHODS ***
    /// ***  ***
    /// @notice swaps amount in
    /// @param swapData operation data
    /// @param amountOutMin min amount out to receive
    /// @param to receiver address
    /// @param data AMM data
    function swap(
        SwapData calldata swapData,
        uint256 amountOutMin,
        address to,
        bytes memory data
    ) external payable override returns (uint256 amountOut, uint256 shareOut) {
        // Get tokens' addresses
        (address tokenIn, address tokenOut) = _getTokens(
            swapData.tokensData,
            yieldBox
        );

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

        if (tokenIn != address(0)) {
            TransferHelper.safeApprove(tokenIn, address(swapRouter), amountIn);
        }

        // Perform the swap operation
        if (data.length == 0) {
            data = getDefaultDexOptions();
        }
        uint256 deadline = abi.decode(data, (uint256));

        address _tokenIn = tokenIn != address(0)
            ? tokenIn
            : ISwapRouterReader(address(swapRouter)).WETH9();
        address _tokenOut = tokenOut != address(0)
            ? tokenOut
            : ISwapRouterReader(address(swapRouter)).WETH9();
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: _tokenIn,
                tokenOut: _tokenOut,
                fee: poolFee,
                recipient: address(this),
                deadline: deadline,
                amountIn: amountIn,
                amountOutMinimum: amountOutMin,
                sqrtPriceLimitX96: 0
            });

        // Compute outputs
        if (tokenIn == address(0)) {
            if (msg.value != amountIn) revert NotValid();
        }
        amountOut = _swap(
            tokenOut,
            params,
            swapData.yieldBoxData.depositToYb,
            to
        );
        if (swapData.yieldBoxData.depositToYb) {
            if (tokenOut != address(0)) {
                _safeApprove(tokenOut, address(yieldBox), amountOut);
            }
            (, shareOut) = yieldBox.depositAsset(
                swapData.tokensData.tokenOutId,
                address(this),
                to,
                amountOut,
                0
            );
        }
    }

    function _swap(
        address tokenOut,
        ISwapRouter.ExactInputSingleParams memory params,
        bool depositToYb,
        address to
    ) private returns (uint256 amountOut) {
        address weth = ISwapRouterReader(address(swapRouter)).WETH9();
        amountOut = swapRouter.exactInputSingle{value: msg.value}(params);
        if (params.tokenOut == weth && tokenOut == address(0)) {
            IWETH9(weth).withdraw(amountOut);
            if (address(this).balance < amountOut) revert UnwrapFailed();

            if (!depositToYb) {
                (bool sent, ) = to.call{value: amountOut}("");
                if (!sent) revert Failed();
            }
        } else {
            if (!depositToYb) {
                IERC20(params.tokenOut).safeTransfer(to, amountOut);
            }
        }
    }

    receive() external payable {}
}
