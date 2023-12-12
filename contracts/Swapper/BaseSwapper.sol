// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "tapioca-sdk/dist/contracts/YieldBox/contracts/interfaces/IYieldBox.sol";

import "../interfaces/ISwapper.sol";

import "../libraries/SafeApprove.sol";

abstract contract BaseSwapper is Ownable, ReentrancyGuard, ISwapper {
    using SafeERC20 for IERC20;
    using SafeApprove for address;

    /// *** ERRORS ***
    /// ***  ***
    error AddressNotValid();
    error Failed();
    error NotValid();
    error AmountZero();
    error NoContract();

    modifier validAddress(address _addr) {
        if (_addr == address(0)) revert AddressNotValid();
        _;
    }

    /// *** VIEW METHODS ***
    /// ***  ***
    function buildSwapData(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 shareIn,
        bool withdrawFromYb,
        bool depositToYb
    ) external pure override returns (SwapData memory) {
        return
            _buildSwapData(
                tokenIn,
                tokenOut,
                0,
                0,
                amountIn,
                shareIn,
                withdrawFromYb,
                depositToYb
            );
    }

    function buildSwapData(
        uint256 tokenInId,
        uint256 tokenOutId,
        uint256 amountIn,
        uint256 shareIn,
        bool withdrawFromYb,
        bool depositToYb
    ) external pure override returns (SwapData memory) {
        return
            _buildSwapData(
                address(0),
                address(0),
                tokenInId,
                tokenOutId,
                amountIn,
                shareIn,
                withdrawFromYb,
                depositToYb
            );
    }

    /// *** INTERNAL METHODS ***
    /// ***  ***
    function _buildSwapData(
        address tokenIn,
        address tokenOut,
        uint256 tokenInId,
        uint256 tokenOutId,
        uint256 amountIn,
        uint256 shareIn,
        bool withdrawFromYb,
        bool depositToYb
    ) internal pure returns (ISwapper.SwapData memory swapData) {
        ISwapper.SwapAmountData memory swapAmountData;
        swapAmountData.amountIn = amountIn;
        swapAmountData.shareIn = shareIn;

        ISwapper.SwapTokensData memory swapTokenData;
        swapTokenData.tokenIn = tokenIn;
        swapTokenData.tokenOut = tokenOut;
        swapTokenData.tokenInId = tokenInId;
        swapTokenData.tokenOutId = tokenOutId;

        ISwapper.YieldBoxData memory swapYBData;
        swapYBData.withdrawFromYb = withdrawFromYb;
        swapYBData.depositToYb = depositToYb;

        swapData.tokensData = swapTokenData;
        swapData.amountData = swapAmountData;
        swapData.yieldBoxData = swapYBData;
    }

    function _getTokens(
        ISwapper.SwapTokensData calldata tokens,
        IYieldBox _yieldBox
    ) internal view returns (address tokenIn, address tokenOut) {
        if (tokens.tokenIn != address(0) || tokens.tokenOut != address(0)) {
            tokenIn = tokens.tokenIn;
            tokenOut = tokens.tokenOut;
        } else {
            (, tokenIn, , ) = _yieldBox.assets(tokens.tokenInId);
            (, tokenOut, , ) = _yieldBox.assets(tokens.tokenOutId);
        }
    }

    function _getAmounts(
        ISwapper.SwapAmountData calldata amounts,
        uint256 tokenInId,
        uint256 tokenOutId,
        IYieldBox _yieldBox
    ) internal view returns (uint256 amountIn, uint256 amountOut) {
        if (amounts.amountIn > 0 || amounts.amountOut > 0) {
            amountIn = amounts.amountIn;
            amountOut = amounts.amountOut;
        } else {
            if (tokenInId > 0) {
                amountIn = amounts.amountIn == 0
                    ? _yieldBox.toAmount(tokenInId, amounts.shareIn, false)
                    : amounts.amountIn;
            }
            if (tokenOutId > 0) {
                amountOut = amounts.amountOut == 0
                    ? _yieldBox.toAmount(tokenOutId, amounts.shareOut, false)
                    : amounts.amountOut;
            }
        }
    }

    function _extractTokens(
        ISwapper.YieldBoxData calldata ybData,
        IYieldBox _yieldBox,
        address token,
        uint256 tokenId,
        uint256 amount,
        uint256 share
    ) internal returns (uint256) {
        if (ybData.withdrawFromYb) {
            (amount, share) = _yieldBox.withdraw(
                tokenId,
                address(this),
                address(this),
                amount,
                share
            );
            return amount;
        }

        if (amount == 0) revert AmountZero();

        if (token != address(0)) {
            uint256 balanceBefore = IERC20(token).balanceOf(address(this));
            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
            uint256 balanceAfter = IERC20(token).balanceOf(address(this));
            if (balanceAfter <= balanceBefore) revert Failed();
            return balanceAfter - balanceBefore;
        } else {
            if (msg.value != amount) revert NotValid();
            return amount;
        }
    }

    function _createPath(
        address tokenIn,
        address tokenOut
    ) internal pure returns (address[] memory path) {
        path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
    }
}
