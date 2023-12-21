// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "./interfaces/IBalancerVault.sol";
import "./interfaces/IStargateRouter.sol";
import "./interfaces/ILiquidityBootstrappingPool.sol";
import "./interfaces/IStargateLbpHelper.sol";

//OZ
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract StargateLbpHelper is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct StargateData {
        address srcToken;
        address targetToken;
        uint16 dstChainId;
        address peer; // StargateLbpHelper address on destination
        uint256 amount;
        uint256 slippage;
        uint256 srcPoolId;
        uint256 dstPoolId;
    }
    struct ParticipateData {
        address assetIn;
        address assetOut;
        uint256 poolId;
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

    event ReceiveFailed(
        uint16 indexed srcChainId,
        address indexed token,
        uint256 indexed nonce,
        uint256 amountLD,
        bytes payload
    );
    event ReceiveSuccess(
        uint16 indexed srcChainId,
        address indexed token,
        uint256 indexed nonce,
        uint256 amountLD,
        bytes payload
    );

    // ************************ //
    // *** ERRORS FUNCTIONS *** //
    // ************************ //
    error RouterNotValid();
    error NotAuthorized();
    error BalanceTooLow();
    error TokensMismatch();

    constructor(address _router, address _lbpPool, address _vault) {
        if (_router == address(0)) revert RouterNotValid();
        router = IStargateRouter(_router);
        lbpPool = ILiquidityBootstrappingPool(_lbpPool); // address(0) for non-host chains
        lbpVault = IBalancerVault(_vault); // address(0) for non-host chains
    }

    // ************************ //
    // *** PUBLIC FUNCTIONS *** //
    // ************************ //
    /// @notice sends token to another layer using Stargate to participate in the LBP
    /// @param stargateData Stargate operation related data; see `StargateData` struct
    /// @param lbpData LBP related data; see 'ParticipateData' struct
    function participate(
        StargateData calldata stargateData,
        ParticipateData calldata lbpData
    ) external payable nonReentrant {
        IERC20 erc20 = IERC20(stargateData.srcToken);

        // retrieve source token from sender
        erc20.safeTransferFrom(msg.sender, address(this), stargateData.amount);

        // compute min amount to be received on destination
        uint256 amountWithSlippage = stargateData.amount -
            ((stargateData.amount * stargateData.slippage) /
                SLIPPAGE_PRECISION);

        // approve token for Stargate router
        erc20.safeApprove(address(router), stargateData.amount);

        // send over to another layer using the Stargate router
        router.swap{value: msg.value}(
            stargateData.dstChainId,
            stargateData.srcPoolId,
            stargateData.dstPoolId,
            payable(msg.sender), //refund address
            stargateData.amount,
            amountWithSlippage,
            IStargateRouterBase.lzTxObj({
                dstGasForCall: 0,
                dstNativeAmount: 0,
                dstNativeAddr: "0x0"
            }),
            abi.encodePacked(stargateData.peer), // StargateLbpHelper.sol destination address
            abi.encode(lbpData, msg.sender)
        );
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
        // will just ignore the payload in some invalid configuration
        if (payload.length <= 40) return; // 20 + 20 + payload

        try
            IStargateLbpHelper(address(this))._sgReceive(
                token,
                amountLD,
                payload
            )
        {
            emit ReceiveSuccess(srcChainId, token, nonce, amountLD, payload);
        } catch {
            emit ReceiveFailed(srcChainId, token, nonce, amountLD, payload);
            // decode payload
            (, address receiver) = abi.decode(
                payload,
                (ParticipateData, address)
            );
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
        (ParticipateData memory data, address receiver) = abi.decode(
            payload,
            (ParticipateData, address)
        );
        if (token != data.assetIn) revert TokensMismatch();

        // check token's balance
        uint256 tokenBalance = IERC20(token).balanceOf(address(this));
        if (tokenBalance < amountLD) revert BalanceTooLow();

        // create lbp join params
        IBalancerVault.SingleSwap memory singleSwap = IBalancerVault
            .SingleSwap({
                poolId: lbpPool.getPoolId(),
                kind: IBalancerVault.SwapKind.GIVEN_IN, //0
                assetIn: IAsset(data.assetIn),
                assetOut: IAsset(data.assetOut),
                amount: amountLD,
                userData: "0x"
            });

        IBalancerVault.FundManagement memory fundManagement = IBalancerVault
            .FundManagement({
                sender: address(this),
                recipient: payable(receiver),
                fromInternalBalance: false,
                toInternalBalance: false
            });

        // participate in the lbp
        IERC20(data.assetIn).approve(address(lbpVault), 0);
        IERC20(data.assetIn).approve(address(lbpVault), amountLD);
        lbpVault.swap(
            singleSwap,
            fundManagement,
            data.minAmountOut,
            (data.deadline != 0 ? data.deadline : block.timestamp)
        );
    }

    receive() external payable {}

    // *********************** //
    // *** OWNER FUNCTIONS *** //
    // *********************** //
    function retryRevert(
        uint16 srcChainId,
        bytes calldata srcAddress,
        uint256 nonce
    ) external payable onlyOwner {
        router.retryRevert{value: msg.value}(srcChainId, srcAddress, nonce);
    }
}
