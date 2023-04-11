// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";
import "tapioca-sdk/dist/contracts/YieldBox/contracts/YieldBox.sol";

import "../interfaces/ISwapper.sol";
import "./interfaces/ICurvePool.sol";

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

/// @title Curve pool swapper
contract CurveSwapper is ISwapper {
    using BoringERC20 for IERC20;

    // ************ //
    // *** VARS *** //
    // ************ //
    ICurvePool public curvePool;

    YieldBox private immutable yieldBox;

    /// @notice creates a new CurveSwapper contract
    /// @param _curvePool CurvePool address
    /// @param _yieldBox YieldBox address
    constructor(ICurvePool _curvePool, YieldBox _yieldBox) {
        curvePool = _curvePool;
        yieldBox = _yieldBox;
    }

    // ********************** //
    // *** VIEW FUNCTIONS *** //
    // ********************** //
    /// @notice returns the possible output amount for input share
    /// @param tokenInId YieldBox asset id
    /// @param shareIn Shares to get the amount for
    /// @param dexData Custom DEX data for query execution
    function getOutputAmount(
        uint256 tokenInId,
        uint256 shareIn,
        bytes calldata dexData
    ) external view override returns (uint256 amountOut) {
        uint256[] memory tokenIndexes = abi.decode(dexData, (uint256[]));
        uint256 amountIn = yieldBox.toAmount(tokenInId, shareIn, false);
        amountOut = curvePool.get_dy(
            int128(int256(tokenIndexes[0])),
            int128(int256(tokenIndexes[1])),
            amountIn
        );
    }

    function getInputAmount(
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (uint256) {
        revert("Not implemented");
    }

    // ************************ //
    // *** PUBLIC FUNCTIONS *** //
    // ************************ //
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
    function swap(
        uint256 tokenInId,
        uint256 tokenOutId,
        uint256 shareIn,
        address to,
        uint256 amountOutMin,
        bytes calldata dexData
    ) external override returns (uint256 amountOut, uint256 shareOut) {
        uint256[] memory tokenIndexes = abi.decode(dexData, (uint256[]));

        (uint256 amountIn, ) = yieldBox.withdraw(
            tokenInId,
            address(this),
            address(this),
            0,
            shareIn
        );

        amountOut = _swapTokensForTokens(
            int128(int256(tokenIndexes[0])),
            int128(int256(tokenIndexes[1])),
            amountIn,
            amountOutMin
        );

        (, address tokenOutAddress, , ) = yieldBox.assets(tokenOutId);
        IERC20(tokenOutAddress).approve(address(yieldBox), amountOut);
        (, shareOut) = yieldBox.depositAsset(
            tokenOutId,
            address(this),
            to,
            amountOut,
            0
        );
    }

    // ************************* //
    // *** PRIVATE FUNCTIONS *** //
    // ************************* //
    function _swapTokensForTokens(
        int128 i,
        int128 j,
        uint256 amountIn,
        uint256 amountOutMin
    ) private returns (uint256) {
        address tokenOut = curvePool.coins(uint256(uint128(j)));

        uint256 outputAmount = curvePool.get_dy(i, j, amountIn);
        require(outputAmount >= amountOutMin, "insufficient-amount-out");

        uint256 balanceBefore = IERC20(tokenOut).balanceOf(address(this));
        curvePool.exchange(i, j, amountIn, amountOutMin);
        uint256 balanceAfter = IERC20(tokenOut).balanceOf(address(this));
        require(balanceAfter > balanceBefore, "swap failed");

        return balanceAfter - balanceBefore;
    }
}
