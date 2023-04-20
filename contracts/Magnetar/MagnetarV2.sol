// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./MagnetarV2Actions.sol";
import "./MagnetarV2ActionsData.sol";
import "./MagnetarV2Operations.sol";

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

contract MagnetarV2 is
    Ownable,
    ReentrancyGuard,
    MagnetarV2Actions,
    MagnetarV2ActionsData,
    MagnetarV2Operations
{
    using SafeERC20 for IERC20;
    using RebaseLibrary for Rebase;

    constructor(address _owner) {
        transferOwnership(_owner);
    }

    receive() external payable override {}

    /// *** VIEW METHODS ***
    /// ***  ***

    /// @notice returns Singularity markets' information
    /// @param who user to return for
    /// @param markets the list of Singularity markets to query for
    function singularityMarketInfo(
        address who,
        ISingularity[] memory markets
    ) external view returns (SingularityInfo[] memory) {
        return _singularityMarketInfo(who, markets);
    }

    /// @notice returns BigBang markets' information
    /// @param who user to return for
    /// @param markets the list of BigBang markets to query for
    function bigBangMarketInfo(
        address who,
        IBigBang[] memory markets
    ) external view returns (BigBangInfo[] memory) {
        return _bigBangMarketInfo(who, markets);
    }

    /// @notice Calculate the collateral amount off the shares.
    /// @param market the Singularity or BigBang address
    /// @param share The shares.
    /// @return amount The amount.
    function getCollateralAmountForShare(
        IMarket market,
        uint256 share
    ) public view returns (uint256 amount) {
        IYieldBoxBase yieldBox = IYieldBoxBase(market.yieldBox());
        return yieldBox.toAmount(market.collateralId(), share, false);
    }

    /// @notice Calculate the collateral shares that are needed for `borrowPart`,
    /// taking the current exchange rate into account.
    /// @param market the Singularity or BigBang address
    /// @param borrowPart The borrow part.
    /// @return collateralShares The collateral shares.
    function getCollateralSharesForBorrowPart(
        IMarket market,
        uint256 borrowPart,
        uint256 liquidationMultiplierPrecision,
        uint256 exchangeRatePrecision
    ) public view returns (uint256 collateralShares) {
        Rebase memory _totalBorrowed;
        (uint128 totalBorrowElastic, uint128 totalBorrowBase) = market
            .totalBorrow();
        _totalBorrowed = Rebase(totalBorrowElastic, totalBorrowBase);

        IYieldBoxBase yieldBox = IYieldBoxBase(market.yieldBox());
        uint256 borrowAmount = _totalBorrowed.toElastic(borrowPart, false);
        return
            yieldBox.toShare(
                market.collateralId(),
                (borrowAmount *
                    market.liquidationMultiplier() *
                    market.exchangeRate()) /
                    (liquidationMultiplierPrecision * exchangeRatePrecision),
                false
            );
    }

    /// @notice Return the equivalent of borrow part in asset amount.
    /// @param market the Singularity or BigBang address
    /// @param borrowPart The amount of borrow part to convert.
    /// @return amount The equivalent of borrow part in asset amount.
    function getAmountForBorrowPart(
        IMarket market,
        uint256 borrowPart
    ) public view returns (uint256 amount) {
        Rebase memory _totalBorrowed;
        (uint128 totalBorrowElastic, uint128 totalBorrowBase) = market
            .totalBorrow();
        _totalBorrowed = Rebase(totalBorrowElastic, totalBorrowBase);

        return _totalBorrowed.toElastic(borrowPart, false);
    }

    /// @notice Compute the amount of `singularity.assetId` from `fraction`
    /// `fraction` can be `singularity.accrueInfo.feeFraction` or `singularity.balanceOf`
    /// @param singularity the singularity address
    /// @param fraction The fraction.
    /// @return amount The amount.
    function getAmountForAssetFraction(
        ISingularity singularity,
        uint256 fraction
    ) public view returns (uint256 amount) {
        (uint128 totalAssetElastic, uint128 totalAssetBase) = singularity
            .totalAsset();

        IYieldBoxBase yieldBox = IYieldBoxBase(singularity.yieldBox());
        return
            yieldBox.toAmount(
                singularity.assetId(),
                (fraction * totalAssetElastic) / totalAssetBase,
                false
            );
    }

    /// *** PUBLIC METHODS ***
    /// ***  ***
    /// @notice Batch multiple calls together
    /// @param calls The list of actions to perform
    function burst(
        Call[] calldata calls
    ) external payable returns (Result[] memory returnData) {
        uint256 valAccumulator;

        uint256 length = calls.length;
        returnData = new Result[](length);

        for (uint256 i = 0; i < length; i++) {
            Call calldata _action = calls[i];
            if (!_action.allowFailure) {
                require(
                    _action.call.length > 0,
                    string.concat(
                        "MagnetarV2: Missing call for action with index",
                        string(abi.encode(i))
                    )
                );
            }

            unchecked {
                valAccumulator += _action.value;
            }

            if (_action.id == PERMIT_ALL) {
                _permit(
                    _action.target,
                    _action.call,
                    true,
                    _action.allowFailure
                );
            } else if (_action.id == PERMIT) {
                _permit(
                    _action.target,
                    _action.call,
                    false,
                    _action.allowFailure
                );
            } else if (_action.id == TOFT_WRAP) {
                WrapData memory data = abi.decode(_action.call[4:], (WrapData));
                _checkSender(data.from);
                if (_action.value > 0) {
                    unchecked {
                        valAccumulator += _action.value;
                    }
                    ITOFT(_action.target).wrapNative{value: _action.value}(
                        data.to
                    );
                } else {
                    ITOFT(_action.target).wrap(
                        msg.sender,
                        data.to,
                        data.amount
                    );
                }
            } else if (_action.id == TOFT_SEND_FROM) {
                (
                    address from,
                    uint16 dstChainId,
                    bytes32 to,
                    uint256 amount,
                    ISendFrom.LzCallParams memory lzCallParams
                ) = abi.decode(
                        _action.call[4:],
                        (
                            address,
                            uint16,
                            bytes32,
                            uint256,
                            (ISendFrom.LzCallParams)
                        )
                    );
                _checkSender(from);

                ISendFrom(_action.target).sendFrom{value: _action.value}(
                    msg.sender,
                    dstChainId,
                    to,
                    amount,
                    lzCallParams
                );
            } else if (_action.id == YB_DEPOSIT_ASSET) {
                YieldBoxDepositData memory data = abi.decode(
                    _action.call[4:],
                    (YieldBoxDepositData)
                );
                _checkSender(data.from);

                (uint256 amountOut, uint256 shareOut) = IYieldBoxBase(
                    _action.target
                ).depositAsset(
                        data.assetId,
                        msg.sender,
                        data.to,
                        data.amount,
                        data.share
                    );
                returnData[i] = Result({
                    success: true,
                    returnData: abi.encode(amountOut, shareOut)
                });
            } else if (_action.id == MARKET_ADD_COLLATERAL) {
                SGLAddCollateralData memory data = abi.decode(
                    _action.call[4:],
                    (SGLAddCollateralData)
                );
                _checkSender(data.from);

                IMarket(_action.target).addCollateral(
                    msg.sender,
                    data.to,
                    data.skim,
                    data.share
                );
            } else if (_action.id == MARKET_BORROW) {
                SGLBorrowData memory data = abi.decode(
                    _action.call[4:],
                    (SGLBorrowData)
                );
                _checkSender(data.from);

                (uint256 part, uint256 share) = IMarket(_action.target).borrow(
                    msg.sender,
                    data.to,
                    data.amount
                );
                returnData[i] = Result({
                    success: true,
                    returnData: abi.encode(part, share)
                });
            } else if (_action.id == MARKET_WITHDRAW_TO) {
                (
                    address from,
                    uint16 dstChainId,
                    bytes32 receiver,
                    uint256 amount,
                    bytes memory adapterParams,
                    address payable refundAddress
                ) = abi.decode(
                        _action.call[4:],
                        (address, uint16, bytes32, uint256, bytes, address)
                    );
                _checkSender(from);

                IMarket(_action.target).withdrawTo{value: _action.value}(
                    msg.sender,
                    dstChainId,
                    receiver,
                    amount,
                    adapterParams,
                    refundAddress
                );
            } else if (_action.id == MARKET_LEND) {
                SGLLendData memory data = abi.decode(
                    _action.call[4:],
                    (SGLLendData)
                );
                _checkSender(data.from);

                uint256 fraction = IMarket(_action.target).addAsset(
                    msg.sender,
                    data.to,
                    data.skim,
                    data.share
                );
                returnData[i] = Result({
                    success: true,
                    returnData: abi.encode(fraction)
                });
            } else if (_action.id == MARKET_REPAY) {
                SGLRepayData memory data = abi.decode(
                    _action.call[4:],
                    (SGLRepayData)
                );
                _checkSender(data.from);

                uint256 amount = IMarket(_action.target).repay(
                    msg.sender,
                    data.to,
                    data.skim,
                    data.part
                );
                returnData[i] = Result({
                    success: true,
                    returnData: abi.encode(amount)
                });
            } else if (_action.id == TOFT_SEND_AND_BORROW) {
                (
                    address from,
                    address to,
                    uint16 lzDstChainId,
                    bytes memory airdropAdapterParams,
                    ITOFT.IBorrowParams memory borrowParams,
                    ITOFT.IWithdrawParams memory withdrawParams,
                    ITOFT.ITOFTSendOptions memory options,
                    ITOFT.ITOFTApproval[] memory approvals
                ) = abi.decode(
                        _action.call[4:],
                        (
                            address,
                            address,
                            uint16,
                            bytes,
                            ITOFT.IBorrowParams,
                            ITOFT.IWithdrawParams,
                            ITOFT.ITOFTSendOptions,
                            ITOFT.ITOFTApproval[]
                        )
                    );
                _checkSender(from);

                ITOFT(_action.target).sendToYBAndBorrow{value: _action.value}(
                    msg.sender,
                    to,
                    lzDstChainId,
                    airdropAdapterParams,
                    borrowParams,
                    withdrawParams,
                    options,
                    approvals
                );
            } else if (_action.id == TOFT_SEND_AND_LEND) {
                (
                    address from,
                    address to,
                    uint16 dstChainId,
                    ITOFT.ILendParams memory lendParams,
                    ITOFT.IUSDOSendOptions memory options,
                    ITOFT.IUSDOApproval[] memory approvals
                ) = abi.decode(
                        _action.call[4:],
                        (
                            address,
                            address,
                            uint16,
                            (ITOFT.ILendParams),
                            (ITOFT.IUSDOSendOptions),
                            (ITOFT.IUSDOApproval[])
                        )
                    );
                _checkSender(from);

                ITOFT(_action.target).sendToYBAndLend{value: _action.value}(
                    msg.sender,
                    to,
                    dstChainId,
                    lendParams,
                    options,
                    approvals
                );
            } else if (_action.id == MARKET_YBDEPOSIT_AND_LEND) {
                HelperLendData memory data = abi.decode(
                    _action.call[4:],
                    (HelperLendData)
                );
                _checkSender(data.from);

                _depositAndAddAsset(
                    IMarket(data.market),
                    data.from,
                    data.amount,
                    data.deposit,
                    false
                );
            } else if (_action.id == MARKET_YBDEPOSIT_COLLATERAL_AND_BORROW) {
                (
                    address market,
                    address user,
                    uint256 collateralAmount,
                    uint256 borrowAmount,
                    ,
                    bool deposit,
                    bool withdraw,
                    bytes memory withdrawData
                ) = abi.decode(
                        _action.call[4:],
                        (
                            address,
                            address,
                            uint256,
                            uint256,
                            bool,
                            bool,
                            bool,
                            bytes
                        )
                    );
                _checkSender(user);

                _depositAddCollateralAndBorrow(
                    IMarket(market),
                    user,
                    collateralAmount,
                    borrowAmount,
                    false,
                    deposit,
                    withdraw,
                    withdrawData
                );
            } else {
                revert("MagnetarV2: action not valid");
            }
        }

        require(msg.value == valAccumulator, "MagnetarV2: value mismatch");
    }

    /// *** PRIVATE METHODS ***
    /// ***  ***
    function _permit(
        address target,
        bytes calldata actionCalldata,
        bool permitAll,
        bool allowFailure
    ) private {
        if (permitAll) {
            PermitAllData memory permitData = abi.decode(
                actionCalldata[4:],
                (PermitAllData)
            );
            _checkSender(permitData.owner);
        } else {
            PermitData memory permitData = abi.decode(
                actionCalldata[4:],
                (PermitData)
            );
            _checkSender(permitData.owner);
        }

        (bool success, bytes memory returnData) = target.call(actionCalldata);
        if (!success && !allowFailure) {
            _getRevertMsg(returnData);
        }
    }

    function _checkSender(address sent) private view {
        require(msg.sender == sent, "MagnetarV2: Unauthorized");
    }

    function _getRevertMsg(bytes memory _returnData) private pure {
        // If the _res length is less than 68, then
        // the transaction failed with custom error or silently (without a revert message)
        if (_returnData.length < 68) revert("MagnetarV2: Reason unknown");

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        revert(abi.decode(_returnData, (string))); // All that remains is the revert string
    }
}
