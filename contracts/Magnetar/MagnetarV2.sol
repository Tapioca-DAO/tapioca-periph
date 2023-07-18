// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

//OZ
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

//TAPIOCA
import "./MagnetarV2Storage.sol";
import "./modules/MagnetarMarketModule.sol";

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

contract MagnetarV2 is Ownable, MagnetarV2Storage {
    using SafeERC20 for IERC20;
    using RebaseLibrary for Rebase;

    // ************ //
    // *** VARS *** //
    // ************ //
    enum Module {
        Market
    }

    /// @notice returns the Market module
    MagnetarMarketModule public marketModule;

    constructor(address _owner, address payable _marketModule) {
        transferOwnership(_owner);
        marketModule = MagnetarMarketModule(_marketModule);
    }

    // ******************** //
    // *** VIEW METHODS *** //
    // ******************** //
    /// @notice returns Singularity markets' information
    /// @param who user to return for
    /// @param markets the list of Singularity markets to query for
    function singularityMarketInfo(
        address who,
        ISingularity[] calldata markets
    ) external view returns (SingularityInfo[] memory) {
        return _singularityMarketInfo(who, markets);
    }

    /// @notice returns BigBang markets' information
    /// @param who user to return for
    /// @param markets the list of BigBang markets to query for
    function bigBangMarketInfo(
        address who,
        IBigBang[] calldata markets
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
    ) external view returns (uint256 amount) {
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
    ) external view returns (uint256 collateralShares) {
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
    ) external view returns (uint256 amount) {
        Rebase memory _totalBorrowed;
        (uint128 totalBorrowElastic, uint128 totalBorrowBase) = market
            .totalBorrow();
        _totalBorrowed = Rebase(totalBorrowElastic, totalBorrowBase);

        return _totalBorrowed.toElastic(borrowPart, false);
    }

    /// @notice Return the equivalent of amount in borrow part.
    /// @param market the Singularity or BigBang address
    /// @param amount The amount to convert.
    /// @return part The equivalent of amount in borrow part.
    function getBorrowPartForAmount(
        IMarket market,
        uint256 amount
    ) external view returns (uint256 part) {
        Rebase memory _totalBorrowed;
        (uint128 totalBorrowElastic, uint128 totalBorrowBase) = market
            .totalBorrow();
        _totalBorrowed = Rebase(totalBorrowElastic, totalBorrowBase);

        return _totalBorrowed.toBase(amount, false);
    }

    /// @notice Compute the amount of `singularity.assetId` from `fraction`
    /// `fraction` can be `singularity.accrueInfo.feeFraction` or `singularity.balanceOf`
    /// @param singularity the singularity address
    /// @param fraction The fraction.
    /// @return amount The amount.
    function getAmountForAssetFraction(
        ISingularity singularity,
        uint256 fraction
    ) external view returns (uint256 amount) {
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

    /// @notice Compute the fraction of `singularity.assetId` from `amount`
    /// `fraction` can be `singularity.accrueInfo.feeFraction` or `singularity.balanceOf`
    /// @param singularity the singularity address
    /// @param amount The amount.
    /// @return fraction The fraction.
    function getFractionForAmount(
        ISingularity singularity,
        uint256 amount
    ) external view returns (uint256 fraction) {
        (uint128 totalAssetShare, uint128 totalAssetBase) = singularity
            .totalAsset();
        (uint128 totalBorrowElastic, ) = singularity.totalBorrow();
        uint256 assetId = singularity.assetId();

        IYieldBoxBase yieldBox = IYieldBoxBase(singularity.yieldBox());

        uint256 share = yieldBox.toShare(assetId, amount, false);
        uint256 allShare = totalAssetShare +
            yieldBox.toShare(assetId, totalBorrowElastic, true);

        fraction = allShare == 0 ? share : (share * totalAssetBase) / allShare;
    }

    // ********************** //
    // *** PUBLIC METHODS *** //
    // ********************** //
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
                    ITapiocaOFT(_action.target).wrapNative{
                        value: _action.value
                    }(data.to);
                } else {
                    ITapiocaOFT(_action.target).wrap(
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
                    data.amount,
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
            } else if (_action.id == YB_WITHDRAW_TO) {
                (
                    address yieldBox,
                    address from,
                    uint256 assetId,
                    uint16 dstChainId,
                    bytes32 receiver,
                    uint256 amount,
                    uint256 share,
                    bytes memory adapterParams,
                    address payable refundAddress
                ) = abi.decode(
                        _action.call[4:],
                        (
                            address,
                            address,
                            uint256,
                            uint16,
                            bytes32,
                            uint256,
                            uint256,
                            bytes,
                            address
                        )
                    );

                _executeModule(
                    Module.Market,
                    abi.encodeWithSelector(
                        MagnetarMarketModule.withdrawToChain.selector,
                        yieldBox,
                        from,
                        assetId,
                        dstChainId,
                        receiver,
                        amount,
                        share,
                        adapterParams,
                        refundAddress,
                        _action.value
                    )
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
                    ITapiocaOFT.IBorrowParams memory borrowParams,
                    ICommonData.IWithdrawParams memory withdrawParams,
                    ICommonData.ISendOptions memory options,
                    ICommonData.IApproval[] memory approvals
                ) = abi.decode(
                        _action.call[4:],
                        (
                            address,
                            address,
                            uint16,
                            bytes,
                            ITapiocaOFT.IBorrowParams,
                            ICommonData.IWithdrawParams,
                            ICommonData.ISendOptions,
                            ICommonData.IApproval[]
                        )
                    );
                _checkSender(from);

                ITapiocaOFT(_action.target).sendToYBAndBorrow{
                    value: _action.value
                }(
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
                    address zroPaymentAddress,
                    IUSDOBase.ILendOrRepayParams memory lendParams,
                    ICommonData.IApproval[] memory approvals,
                    ICommonData.IWithdrawParams memory withdrawParams,
                    bytes memory adapterParams
                ) = abi.decode(
                        _action.call[4:],
                        (
                            address,
                            address,
                            uint16,
                            address,
                            (IUSDOBase.ILendOrRepayParams),
                            (ICommonData.IApproval[]),
                            (ICommonData.IWithdrawParams),
                            bytes
                        )
                    );
                _checkSender(from);

                IUSDOBase(_action.target).sendAndLendOrRepay{
                    value: _action.value
                }(
                    msg.sender,
                    to,
                    dstChainId,
                    zroPaymentAddress,
                    lendParams,
                    approvals,
                    withdrawParams,
                    adapterParams
                );
            } else if (_action.id == TOFT_DEPOSIT_TO_STRATEGY) {
                TOFTSendToStrategyData memory data = abi.decode(
                    _action.call[4:],
                    (TOFTSendToStrategyData)
                );
                _checkSender(data.from);

                ITapiocaOFT(_action.target).sendToStrategy{
                    value: _action.value
                }(
                    msg.sender,
                    data.to,
                    data.amount,
                    data.share,
                    data.assetId,
                    data.lzDstChainId,
                    data.options
                );
            } else if (_action.id == TOFT_RETRIEVE_FROM_STRATEGY) {
                (
                    address from,
                    uint256 amount,
                    uint256 share,
                    uint256 assetId,
                    uint16 lzDstChainId,
                    address zroPaymentAddress,
                    bytes memory airdropAdapterParam
                ) = abi.decode(
                        _action.call[4:],
                        (
                            address,
                            uint256,
                            uint256,
                            uint256,
                            uint16,
                            address,
                            bytes
                        )
                    );

                _checkSender(from);

                ITapiocaOFT(_action.target).retrieveFromStrategy{
                    value: _action.value
                }(
                    msg.sender,
                    amount,
                    share,
                    assetId,
                    lzDstChainId,
                    zroPaymentAddress,
                    airdropAdapterParam
                );
            } else if (_action.id == MARKET_YBDEPOSIT_AND_LEND) {
                HelperLendData memory data = abi.decode(
                    _action.call[4:],
                    (HelperLendData)
                );

                _executeModule(
                    Module.Market,
                    abi.encodeWithSelector(
                        MagnetarMarketModule.mintFromBBAndLendOnSGL.selector,
                        data.user,
                        data.lendAmount,
                        data.mintData,
                        data.depositData,
                        data.lockData,
                        data.participateData,
                        data.externalContracts
                    )
                );
            } else if (_action.id == MARKET_YBDEPOSIT_COLLATERAL_AND_BORROW) {
                (
                    address market,
                    address user,
                    uint256 collateralAmount,
                    uint256 borrowAmount,
                    ,
                    bool deposit,
                    ICommonData.IWithdrawParams memory withdrawParams
                ) = abi.decode(
                        _action.call[4:],
                        (
                            address,
                            address,
                            uint256,
                            uint256,
                            bool,
                            bool,
                            ICommonData.IWithdrawParams
                        )
                    );

                _executeModule(
                    Module.Market,
                    abi.encodeWithSelector(
                        MagnetarMarketModule
                            .depositAddCollateralAndBorrowFromMarket
                            .selector,
                        market,
                        user,
                        collateralAmount,
                        borrowAmount,
                        false,
                        deposit,
                        withdrawParams
                    )
                );
            } else if (_action.id == MARKET_REMOVE_ASSET) {
                (
                    address user,
                    ICommonData.ICommonExternalContracts memory externalData,
                    IUSDOBase.IRemoveAndRepay memory removeAndRepayData
                ) = abi.decode(
                        _action.call[4:],
                        (
                            address,
                            ICommonData.ICommonExternalContracts,
                            IUSDOBase.IRemoveAndRepay
                        )
                    );

                _executeModule(
                    Module.Market,
                    abi.encodeWithSelector(
                        MagnetarMarketModule
                            .exitPositionAndRemoveCollateral
                            .selector,
                        user,
                        externalData,
                        removeAndRepayData
                    )
                );
            } else if (_action.id == MARKET_DEPOSIT_REPAY_REMOVE_COLLATERAL) {
                (
                    address market,
                    address user,
                    uint256 depositAmount,
                    uint256 repayAmount,
                    uint256 collateralAmount,
                    bool extractFromSender,
                    ICommonData.IWithdrawParams memory withdrawCollateralParams
                ) = abi.decode(
                        _action.call[4:],
                        (
                            address,
                            address,
                            uint256,
                            uint256,
                            uint256,
                            bool,
                            ICommonData.IWithdrawParams
                        )
                    );

                _executeModule(
                    Module.Market,
                    abi.encodeWithSelector(
                        MagnetarMarketModule
                            .depositRepayAndRemoveCollateralFromMarket
                            .selector,
                        market,
                        user,
                        depositAmount,
                        repayAmount,
                        collateralAmount,
                        extractFromSender,
                        withdrawCollateralParams
                    )
                );
            } else if (_action.id == MARKET_BUY_COLLATERAL) {
                (
                    address market,
                    address from,
                    uint256 borrowAmount,
                    uint256 supplyAmount,
                    uint256 minAmountOut,
                    address swapper,
                    bytes memory dexData
                ) = abi.decode(
                        _action.call[4:],
                        (
                            address,
                            address,
                            uint256,
                            uint256,
                            uint256,
                            address,
                            bytes
                        )
                    );

                IMarket(market).buyCollateral(
                    from,
                    borrowAmount,
                    supplyAmount,
                    minAmountOut,
                    swapper,
                    dexData
                );
            } else if (_action.id == MARKET_SELL_COLLATERAL) {
                (
                    address market,
                    address from,
                    uint256 share,
                    uint256 minAmountOut,
                    address swapper,
                    bytes memory dexData
                ) = abi.decode(
                        _action.call[4:],
                        (
                            address,
                            address,
                            uint256,
                            uint256,
                            address,
                            bytes
                        )
                    );

                IMarket(market).sellCollateral(
                    from,
                    share,
                    minAmountOut,
                    swapper,
                    dexData
                );
            } else if (_action.id == TAP_EXERCISE_OPTION) {
                HelperExerciseOption memory data = abi.decode(
                    _action.call[4:],
                    (HelperExerciseOption)
                );

                ITapiocaOptionsBrokerCrossChain(_action.target).exerciseOption(
                    data.optionsData,
                    data.lzData,
                    data.tapSendData,
                    data.approvals
                );
            } else if (_action.id == MARKET_MULTIHOP_BUY) {
                HelperMultiHopBuy memory data = abi.decode(
                    _action.call[4:],
                    (HelperMultiHopBuy)
                );

                IUSDOBase(_action.target).initMultiHopBuy(
                    data.from,
                    data.collateralAmount,
                    data.borrowAmount,
                    data.swapData,
                    data.lzData,
                    data.externalData,
                    data.airdropAdapterParams,
                    data.approvals
                );
            } else if (_action.id == MARKET_MULTIHOP_BUY) {
                HelperMultiHopBuy memory data = abi.decode(
                    _action.call[4:],
                    (HelperMultiHopBuy)
                );

                IUSDOBase(_action.target).initMultiHopBuy(
                    data.from,
                    data.collateralAmount,
                    data.borrowAmount,
                    data.swapData,
                    data.lzData,
                    data.externalData,
                    data.airdropAdapterParams,
                    data.approvals
                );
            } else if (_action.id == TOFT_REMOVE_AND_REPAY) {
                HelperTOFTRemoveAndRepayAsset memory data = abi.decode(
                    _action.call[4:],
                    (HelperTOFTRemoveAndRepayAsset)
                );

                IUSDOBase(_action.target).removeAsset(
                    data.from,
                    data.to,
                    data.lzDstChainId,
                    data.zroPaymentAddress,
                    data.adapterParams,
                    data.externalData,
                    data.removeAndRepayData,
                    data.approvals
                );
            } else {
                revert("MagnetarV2: action not valid");
            }
        }

        require(msg.value == valAccumulator, "MagnetarV2: value mismatch");
    }

    /// @notice performs a withdraw operation
    /// @dev it can withdraw on the current chain or it can send it to another one
    ///     - if `dstChainId` is 0 performs a same-chain withdrawal
    ///          - all parameters except `yieldBox`, `from`, `assetId` and `amount` or `share` are ignored
    ///     - if `dstChainId` is NOT 0, the method requires gas for the `sendFrom` operation
    /// @param yieldBox the YieldBox address
    /// @param from user to withdraw from
    /// @param assetId the YieldBox asset id to withdraw
    /// @param dstChainId LZ chain id to withdraw to
    /// @param receiver the receiver on the destination chain
    /// @param amount the amount to withdraw
    /// @param share the share to withdraw
    /// @param adapterParams LZ adapter params
    /// @param refundAddress the LZ refund address which receives the gas not used in the process
    /// @param gas the amount of gas to use for sending the asset to another layer
    function withdrawToChain(
        IYieldBoxBase yieldBox,
        address from,
        uint256 assetId,
        uint16 dstChainId,
        bytes32 receiver,
        uint256 amount,
        uint256 share,
        bytes memory adapterParams,
        address payable refundAddress,
        uint256 gas
    ) external payable {
        _executeModule(
            Module.Market,
            abi.encodeWithSelector(
                MagnetarMarketModule.withdrawToChain.selector,
                yieldBox,
                from,
                assetId,
                dstChainId,
                receiver,
                amount,
                share,
                adapterParams,
                refundAddress,
                gas
            )
        );
    }

    /// @notice helper for deposit to YieldBox, add collateral to a market, borrom from the same market and withdraw
    /// @dev all operations are optional:
    ///         - if `deposit` is false it will skip the deposit to YieldBox step
    ///         - if `withdraw` is false it will skip the withdraw step
    ///         - if `collateralAmount == 0` it will skip the add collateral step
    ///         - if `borrowAmount == 0` it will skip the borrow step
    ///     - the amount deposited to YieldBox is `collateralAmount`
    /// @param market the SGL/BigBang market
    /// @param user the user to perform the action for
    /// @param collateralAmount the collateral amount to add
    /// @param borrowAmount the borrow amount
    /// @param extractFromSender extracts collateral tokens from sender or from the user
    /// @param deposit true/false flag for the deposit to YieldBox step
    /// @param withdrawParams necessary data for the same chain or the cross-chain withdrawal
    function depositAddCollateralAndBorrowFromMarket(
        IMarket market,
        address user,
        uint256 collateralAmount,
        uint256 borrowAmount,
        bool extractFromSender,
        bool deposit,
        ICommonData.IWithdrawParams calldata withdrawParams
    ) external payable {
        _executeModule(
            Module.Market,
            abi.encodeWithSelector(
                MagnetarMarketModule
                    .depositAddCollateralAndBorrowFromMarket
                    .selector,
                market,
                user,
                collateralAmount,
                borrowAmount,
                extractFromSender,
                deposit,
                withdrawParams
            )
        );
    }

    /// @notice helper for deposit asset to YieldBox, repay on a market, remove collateral and withdraw
    /// @dev all steps are optional:
    ///         - if `depositAmount` is 0, the deposit to YieldBox step is skipped
    ///         - if `repayAmount` is 0, the repay step is skipped
    ///         - if `collateralAmount` is 0, the add collateral step is skipped
    /// @param market the SGL/BigBang market
    /// @param user the user to perform the action for
    /// @param depositAmount the amount to deposit to YieldBox
    /// @param repayAmount the amount to repay to the market
    /// @param collateralAmount the amount to withdraw from the market
    /// @param extractFromSender extracts collateral tokens from sender or from the user
    /// @param withdrawCollateralParams withdraw specific params
    function depositRepayAndRemoveCollateralFromMarket(
        address market,
        address user,
        uint256 depositAmount,
        uint256 repayAmount,
        uint256 collateralAmount,
        bool extractFromSender,
        ICommonData.IWithdrawParams calldata withdrawCollateralParams
    ) external payable {
        _executeModule(
            Module.Market,
            abi.encodeWithSelector(
                MagnetarMarketModule
                    .depositRepayAndRemoveCollateralFromMarket
                    .selector,
                market,
                user,
                depositAmount,
                repayAmount,
                collateralAmount,
                extractFromSender,
                withdrawCollateralParams
            )
        );
    }

    /// @notice helper to deposit mint from BB, lend on SGL, lock on tOLP and participate on tOB
    /// @dev all steps are optional:
    ///         - if `mintData.mint` is false, the mint operation on BB is skipped
    ///             - add BB collateral to YB, add collateral on BB and borrow from BB are part of the mint operation
    ///         - if `depositData.deposit` is false, the asset deposit to YB is skipped
    ///         - if `lendAmount == 0` the addAsset operation on SGL is skipped
    ///             - if `mintData.mint` is true, `lendAmount` will be automatically filled with the minted value
    ///         - if `lockData.lock` is false, the tOLP lock operation is skipped
    ///         - if `participateData.participate` is false, the tOB participate operation is skipped
    /// @param user the user to perform the operation for
    /// @param lendAmount the amount to lend on SGL
    /// @param mintData the data needed to mint on BB
    /// @param depositData the data needed for asset deposit on YieldBox
    /// @param lockData the data needed to lock on TapiocaOptionLiquidityProvision
    /// @param participateData the data needed to perform a participate operation on TapiocaOptionsBroker
    /// @param externalContracts the contracts' addresses used in all the operations performed by the helper
    function mintFromBBAndLendOnSGL(
        address user,
        uint256 lendAmount,
        IUSDOBase.IMintData calldata mintData,
        ICommonData.IDepositData calldata depositData,
        ITapiocaOptionLiquidityProvision.IOptionsLockData calldata lockData,
        ITapiocaOptionsBroker.IOptionsParticipateData calldata participateData,
        ICommonData.ICommonExternalContracts calldata externalContracts
    ) external payable {
        _executeModule(
            Module.Market,
            abi.encodeWithSelector(
                MagnetarMarketModule.mintFromBBAndLendOnSGL.selector,
                user,
                lendAmount,
                mintData,
                depositData,
                lockData,
                participateData,
                externalContracts
            )
        );
    }

    /// @notice helper to exit from  tOB, unlock from tOLP, remove from SGL, repay on BB, remove collateral from BB and withdraw
    /// @dev all steps are optional:
    ///         - if `removeAndRepayData.exitData.exit` is false, the exit operation is skipped
    ///         - if `removeAndRepayData.unlockData.unlock` is false, the unlock operation is skipped
    ///         - if `removeAndRepayData.removeAssetFromSGL` is false, the removeAsset operation is skipped
    ///         - if `!removeAndRepayData.assetWithdrawData.withdraw && removeAndRepayData.repayAssetOnBB`, the repay operation is performed
    ///         - if `removeAndRepayData.removeCollateralFromBB` is false, the rmeove collateral is skipped
    ///     - the helper can either stop at the remove asset from SGL step or it can continue until is removes & withdraws collateral from BB
    ///         - removed asset can be withdrawn by providing `removeAndRepayData.assetWithdrawData`
    ///     - BB collateral can be removed by providing `removeAndRepayData.collateralWithdrawData`
    function exitPositionAndRemoveCollateral(
        address user,
        ICommonData.ICommonExternalContracts calldata externalData,
        IUSDOBase.IRemoveAndRepay calldata removeAndRepayData
    ) external payable {
        _executeModule(
            Module.Market,
            abi.encodeWithSelector(
                MagnetarMarketModule.exitPositionAndRemoveCollateral.selector,
                user,
                externalData,
                removeAndRepayData
            )
        );
    }

    // ********************* //
    // *** OWNER METHODS *** //
    // ********************* //
    /// @notice rescues unused ETH from the contract
    /// @param amount the amount to rescue
    /// @param to the recipient
    function rescueEth(uint256 amount, address to) external onlyOwner {
        (bool success, ) = to.call{value: amount}("");
        require(success, "Magnetar: transfer failed.");
    }

    // ********************** //
    // *** PRIVATE METHODS *** //
    // *********************** //
    function _commonInfo(
        address who,
        IMarket market
    ) private view returns (MarketInfo memory) {
        Rebase memory _totalBorrowed;
        MarketInfo memory info;

        info.collateral = market.collateral();
        info.asset = market.asset();
        info.oracle = IOracle(market.oracle());
        info.oracleData = market.oracleData();
        info.totalCollateralShare = market.totalCollateralShare();
        info.userCollateralShare = market.userCollateralShare(who);

        (uint128 totalBorrowElastic, uint128 totalBorrowBase) = market
            .totalBorrow();
        _totalBorrowed = Rebase(totalBorrowElastic, totalBorrowBase);
        info.totalBorrow = _totalBorrowed;
        info.userBorrowPart = market.userBorrowPart(who);

        info.currentExchangeRate = market.exchangeRate();
        (, info.oracleExchangeRate) = IOracle(market.oracle()).peek(
            market.oracleData()
        );
        info.spotExchangeRate = IOracle(market.oracle()).peekSpot(
            market.oracleData()
        );
        info.totalBorrowCap = market.totalBorrowCap();
        info.assetId = market.assetId();
        info.collateralId = market.collateralId();
        info.collateralizationRate = market.collateralizationRate();

        IYieldBoxBase yieldBox = IYieldBoxBase(market.yieldBox());

        (
            info.totalYieldBoxCollateralShare,
            info.totalYieldBoxCollateralAmount
        ) = yieldBox.assetTotals(info.collateralId);
        (info.totalYieldBoxAssetShare, info.totalYieldBoxAssetAmount) = yieldBox
            .assetTotals(info.assetId);

        (
            info.yieldBoxCollateralTokenType,
            info.yieldBoxCollateralContractAddress,
            info.yieldBoxCollateralStrategyAddress,
            info.yieldBoxCollateralTokenId
        ) = yieldBox.assets(info.collateralId);
        (
            info.yieldBoxAssetTokenType,
            info.yieldBoxAssetContractAddress,
            info.yieldBoxAssetStrategyAddress,
            info.yieldBoxAssetTokenId
        ) = yieldBox.assets(info.assetId);

        return info;
    }

    function _singularityMarketInfo(
        address who,
        ISingularity[] memory markets
    ) private view returns (SingularityInfo[] memory) {
        uint256 len = markets.length;
        SingularityInfo[] memory result = new SingularityInfo[](len);

        Rebase memory _totalAsset;
        for (uint256 i = 0; i < len; i++) {
            ISingularity sgl = markets[i];

            result[i].market = _commonInfo(who, IMarket(address(sgl)));

            (uint128 totalAssetElastic, uint128 totalAssetBase) = sgl //
                .totalAsset(); //
            _totalAsset = Rebase(totalAssetElastic, totalAssetBase); //
            result[i].totalAsset = _totalAsset; //
            result[i].userAssetFraction = sgl.balanceOf(who); //

            (
                ISingularity.AccrueInfo memory _accrueInfo,
                uint256 _utilization
            ) = sgl.getInterestDetails();

            result[i].accrueInfo = _accrueInfo;
            result[i].utilization = _utilization;
            result[i].minimumTargetUtilization = sgl.minimumTargetUtilization();
            result[i].maximumTargetUtilization = sgl.maximumTargetUtilization();
            result[i].minimumInterestPerSecond = sgl.minimumInterestPerSecond();
            result[i].maximumInterestPerSecond = sgl.maximumInterestPerSecond();
            result[i].interestElasticity = sgl.interestElasticity();
            result[i].startingInterestPerSecond = sgl
                .startingInterestPerSecond();
        }

        return result;
    }

    function _bigBangMarketInfo(
        address who,
        IBigBang[] memory markets
    ) private view returns (BigBangInfo[] memory) {
        uint256 len = markets.length;
        BigBangInfo[] memory result = new BigBangInfo[](len);

        IBigBang.AccrueInfo memory _accrueInfo;
        for (uint256 i = 0; i < len; i++) {
            IBigBang bigBang = markets[i];
            result[i].market = _commonInfo(who, IMarket(address(bigBang)));

            (uint64 debtRate, uint64 lastAccrued) = bigBang.accrueInfo();
            _accrueInfo = IBigBang.AccrueInfo(debtRate, lastAccrued);
            result[i].accrueInfo = _accrueInfo;
            result[i].minDebtRate = bigBang.minDebtRate();
            result[i].maxDebtRate = bigBang.maxDebtRate();
            result[i].debtRateAgainstEthMarket = bigBang
                .debtRateAgainstEthMarket();
            result[i].currentDebtRate = bigBang.getDebtRate();

            IPenrose penrose = IPenrose(bigBang.penrose());
            result[i].mainBBMarket = penrose.bigBangEthMarket();
            result[i].mainBBDebtRate = penrose.bigBangEthDebtRate();
        }

        return result;
    }

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

        require(target.code.length > 0, "Magnetar: no contract");
        (bool success, bytes memory returnData) = target.call(actionCalldata);
        if (!success && !allowFailure) {
            _getRevertMsg(returnData);
        }
    }

    function _extractModule(Module _module) private view returns (address) {
        address module;
        if (_module == Module.Market) {
            module = address(marketModule);
        }

        if (module == address(0)) {
            revert("MagnetarV2: module not found");
        }

        return module;
    }

    function _executeModule(
        Module _module,
        bytes memory _data
    ) private returns (bytes memory returnData) {
        bool success = true;
        address module = _extractModule(_module);

        (success, returnData) = module.delegatecall(_data);
        if (!success) {
            _getRevertMsg(returnData);
        }
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
