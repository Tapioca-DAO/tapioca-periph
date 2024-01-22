// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// Tapioca
import {
    IStargateRouter,
    IStargateBridge,
    IStargateRouterBase
} from "tapioca-periph/interfaces/external/stargate/IStargateRouter.sol";
import {ILiquidityBootstrappingPool} from "tapioca-periph/interfaces/external/balancer/ILiquidityBootstrappingPool.sol";
import {IBalancerVault, IBalancerAsset} from "tapioca-periph/interfaces/external/balancer/IBalancerVault.sol";
import {ILayerZeroEndpoint} from "tapioca-periph/interfaces/external/layerzero/ILayerZeroEndpoint.sol";
import {IStargateLbpHelper} from "tapioca-periph/interfaces/external/stargate/IStargateLbpHelper.sol";

contract StargateLbpHelper is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct StargateData {
        address srcToken;
        address targetToken;
        uint16 dstChainId;
        address peer; // StargateLbpHelper address on destination
        address receiver; // Receiver address on destination
        uint256 amount;
        uint256 slippage;
        uint256 srcPoolId;
        uint256 dstPoolId;
        bool getDust;
        uint256 dstAirdropAmount;
        uint256 dstGasLimit;
    }

    struct ParticipateData {
        address assetIn;
        address assetOut;
        uint256 deadline;
        uint256 minAmountOut;
    }

    /// @notice Stargate router address
    IStargateRouter public immutable router;
    /// @notice LBP pool address
    ILiquidityBootstrappingPool public immutable lbpPool;
    /// @notice LBP vault address
    IBalancerVault public immutable lbpVault;

    uint256 private constant SLIPPAGE_PRECISION = 1e5;

    uint8 internal constant PARTICIPATE_FN = 1;

    event ReceiveFailed(
        uint16 indexed srcChainId, address indexed token, uint256 indexed nonce, uint256 amountLD, bytes payload
    );
    event ReceiveSuccess(
        uint16 indexed srcChainId, address indexed token, uint256 indexed nonce, uint256 amountLD, bytes payload
    );

    // ************************ //
    // *** ERRORS FUNCTIONS *** //
    // ************************ //
    error NoContract();
    error RouterNotValid();
    error NotAuthorized();
    error BalanceTooLow();
    error TokensMismatch();
    error UnsupportedFunctionType();

    constructor(address _router, address _lbpPool, address _vault) {
        if (_router == address(0)) revert RouterNotValid();
        router = IStargateRouter(_router);
        lbpPool = ILiquidityBootstrappingPool(_lbpPool); // address(0) for non-host chains
        lbpVault = IBalancerVault(_vault); // address(0) for non-host chains
    }

    // ********************** //
    // *** VIEW FUNCTIONS *** //
    // ********************** //

    struct QuoteLayerZeroFeeData {
        uint16 dstChainId;
        uint8 functionType;
        bytes toAddress;
        bytes _empty; // TODO check what's that. Not sure for why this is here
        IStargateRouter.lzTxObj lzTxParams;
    }

    function quoteLayerZeroFee(QuoteLayerZeroFeeData calldata _data) external view returns (uint256, uint256) {
        bytes memory payload = "";
        if (_data.functionType == PARTICIPATE_FN) {
            ParticipateData memory participateData =
                ParticipateData({assetIn: address(0), assetOut: address(0), deadline: block.timestamp, minAmountOut: 0});
            payload = abi.encode(participateData, _data.toAddress);
        } else {
            revert UnsupportedFunctionType();
        }

        IStargateBridge bridge = router.bridge();
        ILayerZeroEndpoint endpoint = bridge.layerZeroEndpoint();
        return endpoint.estimateFees(
            _data.dstChainId,
            address(bridge),
            payload,
            false,
            _txParamBuilder(_data.dstChainId, _data.functionType, _data.lzTxParams)
        );
    }

    // ************************ //
    // *** PUBLIC FUNCTIONS *** //
    // ************************ //
    /// @notice sends token to another layer using Stargate to participate in the LBP
    /// @param stargateData Stargate operation related data; see `StargateData` struct
    /// @param lbpData LBP related data; see 'ParticipateData' struct
    function participate(StargateData calldata stargateData, ParticipateData calldata lbpData)
        external
        payable
        nonReentrant
    {
        IERC20 erc20 = IERC20(stargateData.srcToken);

        // retrieve source token from sender
        erc20.safeTransferFrom(msg.sender, address(this), stargateData.amount);

        // compute min amount to be received on destination
        uint256 amountWithSlippage =
            stargateData.amount - ((stargateData.amount * stargateData.slippage) / SLIPPAGE_PRECISION);

        // approve token for Stargate router
        _safeApprove(address(erc20), address(router), stargateData.amount);

        // send over to another layer using the Stargate router
        uint256 balanceBefore = IERC20(stargateData.srcToken).balanceOf(address(this));

        IStargateRouterBase.lzTxObj memory lzTxParams;
        bytes memory to;
        bytes memory payload;
        {
            lzTxParams = IStargateRouterBase.lzTxObj({
                dstGasForCall: stargateData.dstGasLimit,
                dstNativeAmount: stargateData.dstAirdropAmount,
                dstNativeAddr: abi.encodePacked(stargateData.peer)
            });
            to = abi.encodePacked(stargateData.peer); // StargateLbpHelper.sol destination address
            payload = abi.encode(lbpData, stargateData.receiver);
        }

        router.swap{value: msg.value}(
            stargateData.dstChainId,
            stargateData.srcPoolId,
            stargateData.dstPoolId,
            payable(msg.sender), //refund address
            stargateData.amount,
            amountWithSlippage,
            lzTxParams,
            to, // StargateLbpHelper.sol destination address
            payload
        );

        // check dust and send it back to the user
        uint256 balanceAfter = IERC20(stargateData.srcToken).balanceOf(address(this));
        uint256 transferred = balanceBefore - balanceAfter;
        if (transferred < stargateData.amount && stargateData.getDust) {
            IERC20(stargateData.srcToken).transfer(msg.sender, stargateData.amount - transferred);
        }
    }

    /// @notice receive call for Stargate
    function sgReceive(
        uint16 srcChainId, // the remote chainId sending the tokens
        bytes memory, // the remote Bridge address
        uint256 nonce,
        address token, // the token contract on the local chain
        uint256 amountLD, // the qty of local _token contract tokens
        bytes memory payload
    ) external {
        if (msg.sender != address(router)) revert NotAuthorized();

        try IStargateLbpHelper(address(this))._sgReceive(token, amountLD, payload) {
            emit ReceiveSuccess(srcChainId, token, nonce, amountLD, payload);
        } catch {
            emit ReceiveFailed(srcChainId, token, nonce, amountLD, payload);
            // decode payload
            (, address receiver) = abi.decode(payload, (ParticipateData, address));
            IERC20(token).safeTransfer(receiver, amountLD);
        }
    }

    function _sgReceive(
        address token, // the token contract on the local chain
        uint256 amountLD, // the qty of local _token contract tokens
        bytes memory payload
    ) external {
        if (msg.sender != address(this)) revert NotAuthorized();

        // decode payload
        (ParticipateData memory data, address receiver) = abi.decode(payload, (ParticipateData, address));
        if (token != data.assetIn) revert TokensMismatch();

        // check token's balance
        uint256 tokenBalance = IERC20(token).balanceOf(address(this));
        if (tokenBalance < amountLD) revert BalanceTooLow();

        // create lbp join params
        IBalancerVault.SingleSwap memory singleSwap = IBalancerVault.SingleSwap({
            poolId: lbpPool.getPoolId(),
            kind: IBalancerVault.SwapKind.GIVEN_IN, //0
            assetIn: IBalancerAsset(data.assetIn),
            assetOut: IBalancerAsset(data.assetOut),
            amount: amountLD,
            userData: "0x"
        });

        IBalancerVault.FundManagement memory fundManagement = IBalancerVault.FundManagement({
            sender: address(this),
            recipient: payable(receiver),
            fromInternalBalance: false,
            toInternalBalance: false
        });

        // participate in the lbp
        _safeApprove(data.assetIn, address(lbpVault), amountLD);
        lbpVault.swap(
            singleSwap, fundManagement, data.minAmountOut, (data.deadline != 0 ? data.deadline : block.timestamp)
        );
    }

    receive() external payable {}

    // ************************* //
    // *** PRIVATE FUNCTIONS *** //
    // ************************* //
    function _safeApprove(address token, address to, uint256 value) internal {
        if (token.code.length == 0) revert NoContract();
        bool success;
        bytes memory data;
        (success, data) = token.call(abi.encodeCall(IERC20.approve, (to, 0)));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))), "StargateLbpHelper::safeApprove: approve failed"
        );

        (success, data) = token.call(abi.encodeCall(IERC20.approve, (to, value)));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))), "StargateLbpHelper::safeApprove: approve failed"
        );
    }

    function _txParamBuilder(uint16 _chainId, uint8 _type, IStargateRouter.lzTxObj memory _lzTxParams)
        private
        view
        returns (bytes memory)
    {
        bytes memory lzTxParam;
        address dstNativeAddr;
        {
            bytes memory dstNativeAddrBytes = _lzTxParams.dstNativeAddr;
            assembly {
                dstNativeAddr := mload(add(dstNativeAddrBytes, 20))
            }
        }

        uint256 totalGas = router.bridge().gasLookup(_chainId, _type) + _lzTxParams.dstGasForCall;
        if (_lzTxParams.dstNativeAmount > 0 && dstNativeAddr != address(0x0)) {
            lzTxParam = abi.encodePacked(uint16(2), totalGas, _lzTxParams.dstNativeAmount, _lzTxParams.dstNativeAddr);
        } else {
            lzTxParam = abi.encodePacked(uint16(1), totalGas);
        }

        return lzTxParam;
    }
}
