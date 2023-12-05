// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

//OZ
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

//TAPIOCA
import "./MagnetarV2Storage.sol";
import "./modules/MagnetarMarketModule.sol";

import "../interfaces/IMagnetarHelper.sol";

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

    IMagnetarHelper public helper;

    event HelperUpdate(address indexed old, address indexed newHelper);

    // ************** //
    // *** ERRORS *** //
    // ************** //
    error NotValid();
    error ValueMismatch();
    error Failed();
    error ActionNotValid();
    error ModuleNotFound();
    error UnknownReason();

    constructor(
        address _cluster,
        address _owner,
        address payable _marketModule
    ) {
        cluster = ICluster(_cluster);
        transferOwnership(_owner);
        marketModule = MagnetarMarketModule(_marketModule);
    }

    // *********************** //
    // *** OWNER METHODS **** //
    // ********************** //
    /// @notice updates the cluster address
    /// @dev can only be called by the owner
    /// @param _cluster the new address
    function setCluster(ICluster _cluster) external {
        if (address(_cluster) == address(0)) revert NotValid();
        emit ClusterSet(cluster, _cluster);
        cluster = _cluster;
    }

    function setHelper(address _helper) external onlyOwner {
        emit HelperUpdate(address(helper), _helper);
        helper = IMagnetarHelper(_helper);
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

        for (uint256 i; i < length; i++) {
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

            valAccumulator += _action.value;

            if (_action.id == PERMIT_YB_ALL) {
                _permit(
                    _action.target,
                    _action.call,
                    true,
                    _action.allowFailure,
                    true
                );
            } else if (_action.id == PERMIT) {
                _permit(
                    _action.target,
                    _action.call,
                    false,
                    _action.allowFailure,
                    true
                );
            } else if (_action.id == PERMIT_MARKET) {
                _permit(
                    _action.target,
                    _action.call,
                    false,
                    _action.allowFailure,
                    false
                );
            } else if (_action.id == REVOKE_YB_ALL) {
                address spender = abi.decode(_action.call[4:], (address));
                if (spender != msg.sender) revert NotAuthorized();
                IYieldBoxBase(_action.target).setApprovalForAll(spender, false);
            } else if (_action.id == REVOKE_YB_ASSET) {
                (address spender, uint256 asset) = abi.decode(
                    _action.call[4:],
                    (address, uint256)
                );
                if (spender != msg.sender) revert NotAuthorized();
                IYieldBoxBase(_action.target).setApprovalForAsset(
                    spender,
                    asset,
                    false
                );
            } else if (_action.id == TOFT_WRAP) {
                WrapData memory data = abi.decode(_action.call[4:], (WrapData));
                _checkSender(data.from);
                ITapiocaOFT(_action.target).wrap{value: _action.value}(
                    msg.sender,
                    data.to,
                    data.amount
                );
            } else if (_action.id == TOFT_SEND_FROM) {
                (
                    address from,
                    uint16 dstChainId,
                    bytes32 to,
                    uint256 amount,
                    ICommonOFT.LzCallParams memory lzCallParams
                ) = abi.decode(
                        _action.call[4:],
                        (
                            address,
                            uint16,
                            bytes32,
                            uint256,
                            (ICommonOFT.LzCallParams)
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
                    bytes memory adapterParams,
                    address payable refundAddress,
                    bool unwrap
                ) = abi.decode(
                        _action.call[4:],
                        (
                            address,
                            address,
                            uint256,
                            uint16,
                            bytes32,
                            uint256,
                            bytes,
                            address,
                            bool
                        )
                    );

                _checkSender(from);

                _executeModule(
                    Module.Market,
                    abi.encodeCall(
                        MagnetarMarketModule.withdrawToChain,
                        (
                            IYieldBoxBase(yieldBox),
                            from,
                            assetId,
                            dstChainId,
                            receiver,
                            amount,
                            adapterParams,
                            refundAddress,
                            _action.value,
                            unwrap
                        )
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
                    ICommonData.IApproval[] memory approvals,
                    ICommonData.IApproval[] memory revokes
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
                            ICommonData.IApproval[],
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
                    approvals,
                    revokes
                );
            } else if (_action.id == TOFT_SEND_AND_LEND) {
                (
                    address from,
                    address to,
                    uint16 dstChainId,
                    address zroPaymentAddress,
                    IUSDOBase.ILendOrRepayParams memory lendParams,
                    ICommonData.IApproval[] memory approvals,
                    ICommonData.IApproval[] memory revokes,
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
                    revokes,
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
                    data.assetId,
                    data.lzDstChainId,
                    data.options
                );
            } else if (_action.id == TOFT_RETRIEVE_FROM_STRATEGY) {
                (
                    address from,
                    uint256 amount,
                    uint256 assetId,
                    uint16 lzDstChainId,
                    address zroPaymentAddress,
                    bytes memory airdropAdapterParam
                ) = abi.decode(
                        _action.call[4:],
                        (address, uint256, uint256, uint16, address, bytes)
                    );
                _checkSender(from);

                ITapiocaOFT(_action.target).retrieveFromStrategy{
                    value: _action.value
                }(
                    msg.sender,
                    amount,
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
                _checkSender(data.user);

                _executeModule(
                    Module.Market,
                    abi.encodeCall(
                        MagnetarMarketModule.mintFromBBAndLendOnSGL,
                        (
                            data.user,
                            data.lendAmount,
                            data.mintData,
                            data.depositData,
                            data.lockData,
                            data.participateData,
                            data.externalContracts,
                            cluster
                        )
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
                _checkSender(user);

                _executeModule(
                    Module.Market,
                    abi.encodeCall(
                        MagnetarMarketModule
                            .depositAddCollateralAndBorrowFromMarket,
                        (
                            IMarket(market),
                            user,
                            collateralAmount,
                            borrowAmount,
                            false,
                            deposit,
                            withdrawParams,
                            _action.value
                        )
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
                _checkSender(user);

                _executeModule(
                    Module.Market,
                    abi.encodeCall(
                        MagnetarMarketModule.exitPositionAndRemoveCollateral,
                        (
                            user,
                            externalData,
                            removeAndRepayData,
                            _action.value,
                            cluster
                        )
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
                _checkSender(user);

                _executeModule(
                    Module.Market,
                    abi.encodeCall(
                        MagnetarMarketModule
                            .depositRepayAndRemoveCollateralFromMarket,
                        (
                            market,
                            user,
                            depositAmount,
                            repayAmount,
                            collateralAmount,
                            extractFromSender,
                            withdrawCollateralParams,
                            _action.value
                        )
                    )
                );
            } else if (_action.id == MARKET_BUY_COLLATERAL) {
                (
                    address from,
                    uint256 borrowAmount,
                    uint256 supplyAmount,
                    uint256 minAmountOut,
                    address swapper,
                    bytes memory dexData
                ) = abi.decode(
                        _action.call[4:],
                        (address, uint256, uint256, uint256, address, bytes)
                    );
                _checkSender(from);

                IMarket(_action.target).buyCollateral(
                    from,
                    borrowAmount,
                    supplyAmount,
                    minAmountOut,
                    swapper,
                    dexData
                );
            } else if (_action.id == MARKET_SELL_COLLATERAL) {
                (
                    address from,
                    uint256 share,
                    uint256 minAmountOut,
                    address swapper,
                    bytes memory dexData
                ) = abi.decode(
                        _action.call[4:],
                        (address, uint256, uint256, address, bytes)
                    );
                _checkSender(from);

                IMarket(_action.target).sellCollateral(
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

                ITapiocaOptionsBrokerCrossChain(_action.target).exerciseOption{
                    value: _action.value
                }(
                    data.optionsData,
                    data.lzData,
                    data.tapSendData,
                    data.approvals,
                    data.revokes
                );
            } else if (_action.id == TOFT_REMOVE_AND_REPAY) {
                HelperTOFTRemoveAndRepayAsset memory data = abi.decode(
                    _action.call[4:],
                    (HelperTOFTRemoveAndRepayAsset)
                );

                _checkSender(data.from);
                IUSDOBase(_action.target).removeAsset(
                    data.from,
                    data.to,
                    data.lzDstChainId,
                    data.zroPaymentAddress,
                    data.adapterParams,
                    data.externalData,
                    data.removeAndRepayData,
                    data.approvals,
                    data.revokes
                );
            } else {
                revert ActionNotValid();
            }
        }

        if (msg.value != valAccumulator) revert ValueMismatch();
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
    /// @param adapterParams LZ adapter params
    /// @param refundAddress the LZ refund address which receives the gas not used in the process
    /// @param gas the amount of gas to use for sending the asset to another layer
    /// @param unwrap if withdrawn asset is a TOFT, it can be unwrapped on destination
    function withdrawToChain(
        IYieldBoxBase yieldBox,
        address from,
        uint256 assetId,
        uint16 dstChainId,
        bytes32 receiver,
        uint256 amount,
        bytes memory adapterParams,
        address payable refundAddress,
        uint256 gas,
        bool unwrap
    ) external payable {
        _checkSender(from);
        _executeModule(
            Module.Market,
            abi.encodeCall(
                MagnetarMarketModule.withdrawToChain,
                (
                    yieldBox,
                    from,
                    assetId,
                    dstChainId,
                    receiver,
                    amount,
                    adapterParams,
                    refundAddress,
                    gas,
                    unwrap
                )
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
        _checkSender(user);
        _executeModule(
            Module.Market,
            abi.encodeCall(
                MagnetarMarketModule.depositAddCollateralAndBorrowFromMarket,
                (
                    market,
                    user,
                    collateralAmount,
                    borrowAmount,
                    extractFromSender,
                    deposit,
                    withdrawParams,
                    msg.value
                )
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
        _checkSender(user);
        _executeModule(
            Module.Market,
            abi.encodeCall(
                MagnetarMarketModule.depositRepayAndRemoveCollateralFromMarket,
                (
                    market,
                    user,
                    depositAmount,
                    repayAmount,
                    collateralAmount,
                    extractFromSender,
                    withdrawCollateralParams,
                    msg.value
                )
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
        _checkSender(user);
        _executeModule(
            Module.Market,
            abi.encodeCall(
                MagnetarMarketModule.mintFromBBAndLendOnSGL,
                (
                    user,
                    lendAmount,
                    mintData,
                    depositData,
                    lockData,
                    participateData,
                    externalContracts,
                    cluster
                )
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
        _checkSender(user);
        _executeModule(
            Module.Market,
            abi.encodeCall(
                MagnetarMarketModule.exitPositionAndRemoveCollateral,
                (user, externalData, removeAndRepayData, msg.value, cluster)
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
        if (!success) revert Failed();
    }

    // ********************** //
    // *** PRIVATE METHODS *** //
    // *********************** //
    function _permit(
        address target,
        bytes calldata actionCalldata,
        bool permitAll,
        bool allowFailure,
        bool executeOnYb
    ) private {
        if (target.code.length == 0) revert NotValid();

        bytes memory data = actionCalldata;
        bytes4 funcSig;
        assembly {
            funcSig := mload(add(data, 0x20))
        }

        if (executeOnYb) {
            _permitOnYb(
                target,
                actionCalldata,
                permitAll,
                allowFailure,
                funcSig
            );
        } else {
            _permitOnMarket(target, actionCalldata, allowFailure, funcSig);
        }
    }

    function _permitOnMarket(
        address target,
        bytes calldata actionCalldata,
        bool allowFailure,
        bytes4 funcSig
    ) private {
        bytes4 allowedTokenSig = bytes4(
            keccak256("permitAction(bytes,uint16)")
        );
        if (funcSig != allowedTokenSig) revert NotValid();

        (bytes memory data, ) = abi.decode(actionCalldata[4:], (bytes, uint16));
        (, address owner, , , , , , ) = abi.decode(
            data,
            (bool, address, address, uint256, uint256, uint8, bytes32, bytes32)
        );
        _checkSender(owner);

        (bool success, bytes memory returnData) = target.call(actionCalldata);
        if (!success && !allowFailure) {
            _getRevertMsg(returnData);
        }
    }

    function _permitOnYb(
        address target,
        bytes calldata actionCalldata,
        bool permitAll,
        bool allowFailure,
        bytes4 funcSig
    ) private {
        bytes4 allowedTokenSig = permitAll
            ? bytes4(
                keccak256(
                    "permitAll(address,address,uint256,uint8,bytes32,bytes32)"
                )
            )
            : bytes4(
                keccak256(
                    "permit(address,address,uint256,uint256,uint8,bytes32,bytes32)"
                )
            );

        if (funcSig != allowedTokenSig) revert NotValid();

        if (permitAll) {
            (address owner, , , , , ) = abi.decode(
                actionCalldata[4:],
                (address, address, uint256, uint8, bytes32, bytes32)
            );
            _checkSender(owner);
        } else {
            (address owner, , , , , , ) = abi.decode(
                actionCalldata[4:],
                (address, address, uint256, uint256, uint8, bytes32, bytes32)
            );
            _checkSender(owner);
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
            revert ModuleNotFound();
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
        if (_returnData.length < 68) revert UnknownReason();

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        revert(abi.decode(_returnData, (string))); // All that remains is the revert string
    }
}
