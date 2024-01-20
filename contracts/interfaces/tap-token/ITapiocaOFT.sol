// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// Tapioca
import {ICommonData} from "contracts/interfaces/common/ICommonData.sol";
import {ICommonOFT} from "contracts/interfaces/common/ICommonOFT.sol";
import {ISendFrom} from "contracts/interfaces/common/ISendFrom.sol";
import {IUSDOBase} from "contracts/interfaces/bar/IUSDO.sol";

interface ITapiocaOFTBase {
    function hostChainID() external view returns (uint256);

    function wrap(address fromAddress, address toAddress, uint256 amount) external payable returns (uint256 minted);

    function unwrap(address _toAddress, uint256 _amount) external;

    function erc20() external view returns (address);

    function lzEndpoint() external view returns (address);

    function vault() external view returns (address);
}

/// @dev used for generic TOFTs
interface ITapiocaOFT is ISendFrom, ITapiocaOFTBase {
    struct IRemoveParams {
        uint256 amount;
        address marketHelper;
        address market;
    }

    struct IBorrowParams {
        uint256 amount;
        uint256 borrowAmount;
        address marketHelper;
        address market;
    }

    function totalFees() external view returns (uint256);

    function erc20() external view returns (address);

    function wrappedAmount(uint256 _amount) external view returns (uint256);

    function isHostChain() external view returns (bool);

    function balanceOf(address _holder) external view returns (uint256);

    function isTrustedRemote(uint16 lzChainId, bytes calldata path) external view returns (bool);

    function approve(address _spender, uint256 _amount) external returns (bool);

    function extractUnderlying(uint256 _amount) external;

    function harvestFees() external;

    /// OFT specific methods
    function sendToYBAndBorrow(
        address _from,
        address _to,
        uint16 lzDstChainId,
        bytes calldata airdropAdapterParams,
        IBorrowParams calldata borrowParams,
        ICommonData.IWithdrawParams calldata withdrawParams,
        ICommonData.ISendOptions calldata options,
        ICommonData.IApproval[] calldata approvals,
        ICommonData.IApproval[] calldata revokes
    ) external payable;

    function sendForLeverage(
        uint256 amount,
        address leverageFor,
        IUSDOBase.ILeverageLZData calldata lzData,
        IUSDOBase.ILeverageSwapData calldata swapData,
        IUSDOBase.ILeverageExternalContractsData calldata externalData
    ) external payable;

    function removeCollateral(
        address from,
        address to,
        uint16 lzDstChainId,
        address zroPaymentAddress,
        ICommonData.IWithdrawParams calldata withdrawParams,
        ITapiocaOFT.IRemoveParams calldata removeParams,
        ICommonData.IApproval[] calldata approvals,
        ICommonData.IApproval[] calldata revokes,
        bytes calldata adapterParams
    ) external payable;

    function triggerSendFrom(
        address from,
        uint16 dstChainId,
        bytes32 to,
        uint256 amount,
        ICommonOFT.LzCallParams calldata callParams
    ) external payable;

    function sendFromWithParams(
        address from,
        uint16 lzDstChainId,
        bytes32 to,
        uint256 amount,
        ICommonOFT.LzCallParams calldata callParams,
        bool unwrap,
        ICommonData.IApproval[] calldata approvals,
        ICommonData.IApproval[] calldata revokes
    ) external payable;

    function triggerApproveOrRevoke(
        uint16 lzDstChainId,
        ICommonOFT.LzCallParams calldata lzCallParams,
        ICommonData.IApproval[] calldata approvals
    ) external payable;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}