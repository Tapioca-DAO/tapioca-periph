// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

//OZ
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

//TAPIOCA
import "./MagnetarV2Storage.sol";
import "./modules/MagnetarMarketModule.sol";

import "../interfaces/IPenrose.sol";

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

    /// @notice Return the equivalent of amount in borrow part.
    /// @param market the Singularity or BigBang address
    /// @param amount The amount to convert.
    /// @return part The equivalent of amount in borrow part.
    function getBorrowPartForAmount(
        IMarket market,
        uint256 amount
    ) public view returns (uint256 part) {
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

    /// @notice Compute the fraction of `singularity.assetId` from `amount`
    /// `fraction` can be `singularity.accrueInfo.feeFraction` or `singularity.balanceOf`
    /// @param singularity the singularity address
    /// @param amount The amount.
    /// @return fraction The fraction.
    function getFractionForAmount(
        ISingularity singularity,
        uint256 amount
    ) public view returns (uint256 fraction) {
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
                        MagnetarMarketModule.withdrawTo.selector,
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
                    ITapiocaOFT.IWithdrawParams memory withdrawParams,
                    ITapiocaOFT.ISendOptions memory options,
                    ITapiocaOFT.IApproval[] memory approvals
                ) = abi.decode(
                        _action.call[4:],
                        (
                            address,
                            address,
                            uint16,
                            bytes,
                            ITapiocaOFT.IBorrowParams,
                            ITapiocaOFT.IWithdrawParams,
                            ITapiocaOFT.ISendOptions,
                            ITapiocaOFT.IApproval[]
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
                    IUSDOBase.ILendParams memory lendParams,
                    IUSDOBase.IApproval[] memory approvals,
                    IUSDOBase.IWithdrawParams memory withdrawParams,
                    bytes memory adapterParams
                ) = abi.decode(
                        _action.call[4:],
                        (
                            address,
                            address,
                            uint16,
                            address,
                            (IUSDOBase.ILendParams),
                            (IUSDOBase.IApproval[]),
                            (IUSDOBase.IWithdrawParams),
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
                        MagnetarMarketModule.depositAndAddAsset.selector,
                        data.market,
                        data.from,
                        data.amount,
                        data.deposit,
                        false
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

                _executeModule(
                    Module.Market,
                    abi.encodeWithSelector(
                        MagnetarMarketModule
                            .depositAddCollateralAndBorrow
                            .selector,
                        market,
                        user,
                        collateralAmount,
                        borrowAmount,
                        false,
                        deposit,
                        withdraw,
                        withdrawData
                    )
                );
            } else if (_action.id == MARKET_REMOVE_ASSET) {
                HelperRemoveAssetData memory data = abi.decode(
                    _action.call[4:],
                    (HelperRemoveAssetData)
                );

                 ISingularity(data.market).removeAsset(data.user, data.user, data.fraction);
            } else if (_action.id == MARKET_DEPOSIT_REPAY_REMOVE_COLLATERAL) {
                HelperDepositRepayRemoveCollateral memory data = abi.decode(
                    _action.call[4:],
                    (HelperDepositRepayRemoveCollateral)
                );

                _executeModule(
                    Module.Market,
                    abi.encodeWithSelector(
                        MagnetarMarketModule
                            .depositRepayAndRemoveCollateral
                            .selector,
                        data.market,
                        data.user,
                        data.depositAmount,
                        data.repayAmount,
                        data.collateralAmount,
                        data.deposit,
                        data.withdraw,
                        data.extractFromSender
                    )
                );
            } else if (_action.id == MARKET_BUY_COLLATERAL) {
                HelperBuyCollateral memory data = abi.decode(
                    _action.call[4:],
                    (HelperBuyCollateral)
                );

                IMarket(data.market).buyCollateral(data.from, data.borrowAmount, data.supplyAmount, data.minAmountOut, address(data.swapper), data.dexData);
            } else if (_action.id == MARKET_SELL_COLLATERAL) {
                HelperSellCollateral memory data = abi.decode(
                    _action.call[4:],
                    (HelperSellCollateral)
                );

                IMarket(data.market).sellCollateral(data.from, data.share, data.minAmountOut, address(data.swapper), data.dexData);
            } else {
                revert("MagnetarV2: action not valid");
            }
        }

        require(msg.value == valAccumulator, "MagnetarV2: value mismatch");
    }

    function withdrawTo(
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
                MagnetarMarketModule.withdrawTo.selector,
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

    function depositAddCollateralAndBorrow(
        IMarket market,
        address user,
        uint256 collateralAmount,
        uint256 borrowAmount,
        bool extractFromSender,
        bool deposit,
        bool withdraw,
        bytes memory withdrawData
    ) external payable {
        _executeModule(
            Module.Market,
            abi.encodeWithSelector(
                MagnetarMarketModule.depositAddCollateralAndBorrow.selector,
                market,
                user,
                collateralAmount,
                borrowAmount,
                extractFromSender,
                deposit,
                withdraw,
                withdrawData
            )
        );
    }

    function depositAndRepay(
        IMarket market,
        address user,
        uint256 depositAmount,
        uint256 repayAmount,
        bool deposit,
        bool extractFromSender
    ) external payable {
        _executeModule(
            Module.Market,
            abi.encodeWithSelector(
                MagnetarMarketModule.depositAndRepay.selector,
                market,
                user,
                depositAmount,
                repayAmount,
                deposit,
                extractFromSender
            )
        );
    }

    function depositRepayAndRemoveCollateral(
        IMarket market,
        address user,
        uint256 depositAmount,
        uint256 repayAmount,
        uint256 collateralAmount,
        bool deposit,
        bool withdraw,
        bool extractFromSender
    ) external payable {
        _executeModule(
            Module.Market,
            abi.encodeWithSelector(
                MagnetarMarketModule.depositRepayAndRemoveCollateral.selector,
                market,
                user,
                depositAmount,
                repayAmount,
                collateralAmount,
                deposit,
                withdraw,
                extractFromSender
            )
        );
    }

    function mintAndLend(
        ISingularity singularity,
        IMarket bingBang,
        address user,
        uint256 collateralAmount,
        uint256 borrowAmount,
        bool deposit,
        bool extractFromSender
    ) external payable {
        _executeModule(
            Module.Market,
            abi.encodeWithSelector(
                MagnetarMarketModule.mintAndLend.selector,
                singularity,
                bingBang,
                user,
                collateralAmount,
                borrowAmount,
                deposit,
                extractFromSender
            )
        );
    }

    function depositAndAddAsset(
        IMarket singularity,
        address user,
        uint256 amount,
        bool deposit,
        bool extractFromSender
    ) external payable {
        _executeModule(
            Module.Market,
            abi.encodeWithSelector(
                MagnetarMarketModule.depositAndAddAsset.selector,
                singularity,
                user,
                amount,
                deposit,
                extractFromSender
            )
        );
    }

    function removeAssetAndRepay(
        ISingularity singularity,
        IMarket bingBang,
        address user,
        uint256 removeShare, //slightly greater than _repayAmount to cover the interest
        uint256 repayAmount,
        uint256 collateralShare,
        bool withdraw,
        bytes calldata withdrawData
    ) external payable {
        _executeModule(
            Module.Market,
            abi.encodeWithSelector(
                MagnetarMarketModule.removeAssetAndRepay.selector,
                singularity,
                bingBang,
                user,
                removeShare,
                repayAmount,
                collateralShare,
                withdraw,
                withdrawData
            )
        );
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
