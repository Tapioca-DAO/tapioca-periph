// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {ILayerZeroEndpoint} from "../../../layerzero/v1/interfaces/ILayerZeroEndpoint.sol";

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

// Tapioca


interface IStargatePool {
    function convertRate() external view returns (uint256);
}

interface IStargateFactory {
    function getPool(uint256 _poolId) external view returns (address);
}

interface IStargateBridge {
    function quoteLayerZeroFee(
        uint16 _chainId,
        uint8 _functionType,
        bytes calldata _toAddress,
        bytes calldata _transferAndCallPayload,
        IStargateRouterBase.lzTxObj memory _lzTxParams
    ) external view returns (uint256, uint256);

    function layerZeroEndpoint() external view returns (ILayerZeroEndpoint);

    function gasLookup(uint16, uint8) external view returns (uint256);
}

interface IStargateRouterBase {
    //for Router
    struct lzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    //for StargateComposer
    struct SwapAmount {
        uint256 amountLD; // the amount, in Local Decimals, to be swapped
        uint256 minAmountLD; // the minimum amount accepted out on destination
    }

    function swap(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    ) external payable;
}

interface IStargateRouter is IStargateRouterBase {
    //for StargateComposer
    function swapETHAndCall(
        uint16 _dstChainId, // destination Stargate chainId
        address payable _refundAddress, // refund additional messageFee to this address
        bytes calldata _to, // the receiver of the destination ETH
        SwapAmount memory _swapAmount, // the amount and the minimum swap amount
        lzTxObj memory _lzTxParams, // the LZ tx params
        bytes calldata _payload // the payload to send to the destination
    ) external payable;

    function bridge() external view returns (IStargateBridge); // for StargateRouter contract

    function stargateBridge() external view returns (IStargateBridge); // for StargateComposer contract

    function poolId() external view returns (uint256);

    function stargateRouter() external view returns (address);

    function stargateEthVault() external view returns (address);

    //StargateRouter methods only
    function retryRevert(uint16 _srcChainId, bytes calldata _srcAddress, uint256 _nonce) external payable;

    function instantRedeemLocal(uint16 _srcPoolId, uint256 _amountLP, address _to)
        external
        returns (uint256 amountSD);

    function redeemLocal(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function redeemRemote(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        uint256 _minAmountLD,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function addLiquidity(uint256 _poolId, uint256 _amountLD, address _to) external;

    function createChainPath(uint256 _poolId, uint16 _dstChainId, uint256 _dstPoolId, uint256 _weight) external;

    function activateChainPath(uint256 _poolId, uint16 _dstChainId, uint256 _dstPoolId) external;

    function setWeightForChainPath(uint256 _poolId, uint16 _dstChainId, uint256 _dstPoolId, uint16 _weight) external;

    struct CreditObj {
        uint256 credits;
        uint256 idealBalance;
    }

    function creditChainPath(uint16 _dstChainId, uint256 _dstPoolId, uint256 _srcPoolId, CreditObj memory _c)
        external;
}
