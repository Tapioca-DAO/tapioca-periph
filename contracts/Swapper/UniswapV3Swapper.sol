// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.18;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoterV2.sol";

import "tapioca-sdk/dist/contracts/YieldBox/contracts/interfaces/IYieldBox.sol";

import "../interfaces/ISwapper.sol";
import "./libraries/OracleLibrary.sol";

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

/// @title UniswapV3 swapper contract
contract UniswapV3Swapper is ISwapper {
    // ************ //
    // *** VARS *** //
    // ************ //
    IYieldBox private immutable yieldBox;
    ISwapRouter public immutable swapRouter;
    IUniswapV3Factory public immutable factory;
    address public owner;

    uint24 public poolFee = 3000;

    // ************** //
    // *** EVENTS *** //
    // ************** //
    event PoolFee(uint256 _old, uint256 _new);

    /// @notice creates a new UniswapV3Swapper contract
    constructor(
        IYieldBox _yieldBox,
        ISwapRouter _swapRouter,
        IUniswapV3Factory _factory
    ) {
        yieldBox = _yieldBox;
        swapRouter = _swapRouter;
        factory = _factory;
        owner = msg.sender;
    }

    /// @notice sets a new pool fee
    /// @param _newFee the new value
    function setPoolFee(uint24 _newFee) external {
        require(msg.sender == owner, "UniswapV3Swapper: not authorized");
        emit PoolFee(poolFee, _newFee);
        poolFee = _newFee;
    }

    /// @notice returns the possible output amount for input share
    /// @param tokenInId YieldBox asset id
    /// @param shareIn Shares to get the amount for
    /// @param dexData Custom DEX data for query execution
    /// @dev dexData examples:
    ///     - for UniV2, it should contain address[] swapPath
    ///     - for Curve, it should contain uint256[] tokenIndexes
    ///     - for UniV3, it should contain uint256 tokenOutId
    function getOutputAmount(
        uint256 tokenInId,
        uint256 shareIn,
        bytes calldata dexData
    ) external view override returns (uint256 amountOut) {
        uint256 tokenOutId = abi.decode(dexData, (uint256));

        (, address tokenIn, , ) = yieldBox.assets(tokenInId);
        (, address tokenOut, , ) = yieldBox.assets(tokenOutId);

        uint256 amountIn = yieldBox.toAmount(tokenInId, shareIn, false);

        address pool = factory.getPool(tokenIn, tokenOut, poolFee);
        (int24 tick, ) = OracleLibrary.consult(pool, 60);

        amountOut = OracleLibrary.getQuoteAtTick(
            tick,
            uint128(amountIn),
            tokenIn,
            tokenOut
        );
    }

    /// @notice returns necessary input amount for a fixed output amount
    /// @param tokenOutId YieldBox asset id
    /// @param shareOut Shares out to compute the amount for
    /// @param dexData Custom DEX data for query execution
    /// @dev dexData examples:
    ///     - for UniV2, it should contain address[] swapPath
    ///     - for UniV3, it should contain uint256 tokenInId
    function getInputAmount(
        uint256 tokenOutId,
        uint256 shareOut,
        bytes calldata dexData
    ) external view override returns (uint256 amountIn) {
        uint256 tokenInId = abi.decode(dexData, (uint256));

        (, address tokenIn, , ) = yieldBox.assets(tokenInId);
        (, address tokenOut, , ) = yieldBox.assets(tokenOutId);

        uint256 amountOut = yieldBox.toAmount(tokenOutId, shareOut, false);

        address pool = factory.getPool(tokenIn, tokenOut, poolFee);

        (int24 tick, ) = OracleLibrary.consult(pool, 60);
        amountIn = OracleLibrary.getQuoteAtTick(
            tick,
            uint128(amountOut),
            tokenOut,
            tokenIn
        );
    }

    /// @notice swaps token in with token out
    /// @dev returns both amount and shares
    /// @param tokenInId YieldBox asset id
    /// @param tokenOutId YieldBox asset id
    /// @param shareIn Shares to be swapped
    /// @param to Receiver address
    /// @param amountOutMin Minimum amount to be received
    /// @param dexData Custom DEX data for query execution
    /// @dev dexData examples:
    ///     - for UniV2, it should contain address[] swapPath
    ///     - for Curve, it should contain uint256[] tokenIndexes
    ///     - for UniV3, it should contain uint256 deadline
    function swap(
        uint256 tokenInId,
        uint256 tokenOutId,
        uint256 shareIn,
        address to,
        uint256 amountOutMin,
        bytes calldata dexData
    ) external override returns (uint256 amountOut, uint256 shareOut) {
        (, address tokenIn, , ) = yieldBox.assets(tokenInId);
        (, address tokenOut, , ) = yieldBox.assets(tokenOutId);

        (uint256 amountIn, ) = yieldBox.withdraw(
            tokenInId,
            address(this),
            address(this),
            0,
            shareIn
        );

        TransferHelper.safeApprove(tokenIn, address(swapRouter), amountIn);

        uint256 deadline = abi.decode(dexData, (uint256));
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: poolFee,
                recipient: address(this),
                deadline: deadline,
                amountIn: amountIn,
                amountOutMinimum: amountOutMin,
                sqrtPriceLimitX96: 0
            });

        amountOut = swapRouter.exactInputSingle(params);

        IERC20(tokenOut).approve(address(yieldBox), amountOut);
        (, shareOut) = yieldBox.depositAsset(
            tokenOutId,
            address(this),
            to,
            amountOut,
            0
        );
    }
}
