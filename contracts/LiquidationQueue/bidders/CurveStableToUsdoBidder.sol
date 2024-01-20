// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import "@boringcrypto/boring-solidity/contracts/BoringOwnable.sol";

import "../../interfaces/ISwapper.sol";
import "../../interfaces/IPenrose.sol";
import "../../interfaces/ISingularity.sol";
import "../../interfaces/ILiquidationQueue.sol";
import "../../Swapper/interfaces/ICurvePool.sol";
import "tapioca-sdk/dist/contracts/YieldBox/contracts/interfaces/IYieldBox.sol";

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

/// @title Swaps Stable to USDO through Curve
/// @dev Performs a swap operation between stable and USDO through 3CRV+USDO pool
contract CurveStableToUsdoBidder is BoringOwnable {
    // ************ //
    // *** VARS *** //
    // ************ //
    /// @notice 3Crv+USDO swapper
    ICurveSwapper public curveSwapper;
    /// @notice Curve pool assets number
    uint256 curveAssetsLength;

    // ************** //
    // *** EVENTS *** //
    // ************** //
    /// @notice event emitted when the ISwapper property is updated
    event CurveSwapperUpdated(address indexed _old, address indexed _new);

    /// @notice creates a new CurveStableToUsdoBidder
    /// @param curveSwapper_ CurveSwapper address
    /// @param curvePoolAssetCount_ Curve pool assets number
    constructor(ICurveSwapper curveSwapper_, uint256 curvePoolAssetCount_) {
        curveSwapper = curveSwapper_;
        curveAssetsLength = curvePoolAssetCount_;
    }

    // ********************** //
    // *** VIEW FUNCTIONS *** //
    // ********************** //
    /// @notice returns the unique name
    function name() external pure returns (string memory) {
        return "stable -> USDO (3Crv+USDO)";
    }

    /// @notice returns the amount of collateral
    /// @param singularity Singularity market address
    /// @param tokenInId Token in YielxBox id
    /// @param amountIn Stablecoin amount
    /// @return output amount
    function getOutputAmount(ISingularity singularity, uint256 tokenInId, uint256 amountIn, bytes calldata)
        external
        view
        returns (uint256)
    {
        require(IPenrose(singularity.penrose()).usdoToken() != address(0), "USDO not set");

        uint256 usdoAssetId = IPenrose(singularity.penrose()).usdoAssetId();
        if (tokenInId == usdoAssetId) {
            return amountIn;
        }

        return _getOutput(IYieldBox(singularity.yieldBox()), tokenInId, usdoAssetId, amountIn);
    }

    /// @notice returns token tokenIn amount based on tokenOut amount
    /// @param singularity Singularity market address
    /// @param tokenInId Token in YielxBox id
    /// @param amountOut Token out amount
    /// @return input amount
    function getInputAmount(ISingularity singularity, uint256 tokenInId, uint256 amountOut, bytes calldata)
        external
        view
        returns (uint256)
    {
        require(IPenrose(singularity.penrose()).usdoToken() != address(0), "USDO not set");

        uint256 usdoAssetId = IPenrose(singularity.penrose()).usdoAssetId();
        if (tokenInId == usdoAssetId) {
            return amountOut;
        }

        return _getOutput(IYieldBox(singularity.yieldBox()), usdoAssetId, tokenInId, amountOut);
    }

    // ************************ //
    // *** PUBLIC FUNCTIONS *** //
    // ************************ //

    /// @notice swaps stable to collateral
    /// @param singularity Singularity market address
    /// @param tokenInId Stablecoin asset id
    /// @param amountIn Stablecoin amount
    /// @param data extra data used for the swap operation
    /// @return obtained amount
    function swap(ISingularity singularity, uint256 tokenInId, uint256 amountIn, bytes calldata data)
        external
        returns (uint256)
    {
        IPenrose penrose = IPenrose(singularity.penrose());
        require(penrose.usdoToken() != address(0), "USDO not set");
        require(penrose.isMarketRegistered(address(singularity)), "Market not valid");
        IYieldBox yieldBox = IYieldBox(singularity.yieldBox());
        ILiquidationQueue liquidationQueue = ILiquidationQueue(singularity.liquidationQueue());

        uint256 usdoAssetId = IPenrose(singularity.penrose()).usdoAssetId();
        require(msg.sender == address(liquidationQueue), "only LQ");
        if (tokenInId == usdoAssetId) {
            yieldBox.transfer(
                address(this), address(liquidationQueue), tokenInId, yieldBox.toShare(tokenInId, amountIn, false)
            );
            return amountIn;
        }

        uint256 _usdoMin = 0;
        if (data.length > 0) {
            //should always be sent
            _usdoMin = abi.decode(data, (uint256));
        }
        yieldBox.transfer(address(this), address(curveSwapper), tokenInId, yieldBox.toShare(tokenInId, amountIn, false));
        return _swap(yieldBox, tokenInId, usdoAssetId, amountIn, _usdoMin, address(liquidationQueue));
    }

    // *********************** //
    // *** OWNER FUNCTIONS *** //
    // *********************** //
    /// @notice sets the Curve swapper
    /// @dev used for USDO to WETH swap
    /// @param _swapper The curve pool swapper address
    function setCurveSwapper(ICurveSwapper _swapper) external onlyOwner {
        emit CurveSwapperUpdated(address(curveSwapper), address(_swapper));
        curveSwapper = _swapper;
    }

    // ************************* //
    // *** PRIVATE FUNCTIONS *** //
    // ************************* //
    function _getCurveIndex(address token) private view returns (uint256) {
        ICurvePool pool = ICurvePool(curveSwapper.curvePool());
        int256 index = -1;
        for (uint256 i; i < curveAssetsLength; i++) {
            address tokenAtIndex = pool.coins(i);
            if (tokenAtIndex == token) {
                index = int256(i);
            }
        }
        require(index > -1, "asset not found");
        return uint256(index);
    }

    function _getOutput(IYieldBox yieldBox, uint256 tokenInId, uint256 tokenOutId, uint256 amountIn)
        private
        view
        returns (uint256)
    {
        (, address tokenInAddress,,) = yieldBox.assets(tokenInId);
        (, address tokenOutAddress,,) = yieldBox.assets(tokenOutId);

        uint256 tokenInCurveIndex = _getCurveIndex(tokenInAddress);
        uint256 tokenOutCurveIndex = _getCurveIndex(tokenOutAddress);
        uint256[] memory indexes = new uint256[](2);
        indexes[0] = tokenInCurveIndex;
        indexes[1] = tokenOutCurveIndex;

        uint256 share = yieldBox.toShare(tokenInId, amountIn, false);

        ISwapper.SwapData memory swapData =
            curveSwapper.buildSwapData(tokenInId, tokenOutId, amountIn, share, true, true);
        return curveSwapper.getOutputAmount(swapData, abi.encode(indexes));
    }

    function _swap(
        IYieldBox yieldBox,
        uint256 stableAssetId,
        uint256 usdoAssetId,
        uint256 amountIn,
        uint256 minAmount,
        address to
    ) private returns (uint256) {
        (, address tokenInAddress,,) = yieldBox.assets(stableAssetId);
        (, address tokenOutAddress,,) = yieldBox.assets(usdoAssetId);

        uint256 tokenInCurveIndex = _getCurveIndex(tokenInAddress);
        uint256 tokenOutCurveIndex = _getCurveIndex(tokenOutAddress);

        uint256[] memory indexes = new uint256[](2);
        indexes[0] = tokenInCurveIndex;
        indexes[1] = tokenOutCurveIndex;
        uint256 tokenInShare = yieldBox.toShare(stableAssetId, amountIn, false);

        ISwapper.SwapData memory swapData =
            curveSwapper.buildSwapData(stableAssetId, usdoAssetId, 0, tokenInShare, true, true);
        (uint256 amountOut,) = curveSwapper.swap(swapData, minAmount, to, abi.encode(indexes));

        return amountOut;
    }
}
