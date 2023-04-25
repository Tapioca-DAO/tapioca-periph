// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "tapioca-sdk/dist/contracts/YieldBox/contracts/interfaces/IYieldBox.sol";

import "../interfaces/ISwapper.sol";

abstract contract BaseSwapper is Ownable, ReentrancyGuard, ISwapper {
    using SafeERC20 for IERC20;

    /// *** ERRORS ***
    /// ***  ***
    error AddressNotValid();

    modifier validAddress(address _addr) {
        if (_addr == address(0)) revert AddressNotValid();
        _;
    }

    /// *** VIEW METHODS ***
    /// ***  ***
    function buildSwapData(
        address tokenIn,
        uint256 amountIn,
        uint256 shareIn,
        bool withdrawFromYb,
        bool depositToYb
    ) external pure override returns (SwapData memory) {
        return
            _buildSwapData(
                tokenIn,
                0,
                amountIn,
                shareIn,
                withdrawFromYb,
                depositToYb
            );
    }

    function buildSwapData(
        uint256 tokenInId,
        uint256 amountIn,
        uint256 shareIn,
        bool withdrawFromYb,
        bool depositToYb
    ) external pure override returns (SwapData memory) {
        return
            _buildSwapData(
                address(0),
                tokenInId,
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
        uint256 tokenInId,
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
        swapTokenData.tokenInId = tokenInId;

        ISwapper.YieldBoxData memory swapYBData;
        swapYBData.withdrawFromYb = withdrawFromYb;
        swapYBData.depositToYb = depositToYb;

        swapData.tokensData = swapTokenData;
        swapData.amountData = swapAmountData;
        swapData.yieldBoxData = swapYBData;
    }

    function _safeApprove(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "BaseSwapper::safeApprove: approve failed"
        );
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
                amountIn = _yieldBox.toAmount(
                    tokenInId,
                    amounts.shareIn,
                    false
                );
            }
            if (tokenOutId > 0) {
                amountOut = _yieldBox.toAmount(
                    tokenOutId,
                    amounts.shareOut,
                    false
                );
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
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        return amount;
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
