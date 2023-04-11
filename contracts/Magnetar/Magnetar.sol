// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./MagnetarData.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

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

contract Magnetar is Ownable, MagnetarData {
    constructor(address _owner) {
        transferOwnership(_owner);
    }

    // ************************ //
    // *** PUBLIC FUNCTIONS *** //
    // ************************ //
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
                        "Magnetar: Missing call for action with index",
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
            } else if (_action.id == SGL_ADD_COLLATERAL) {
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
            } else if (_action.id == SGL_BORROW) {
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
            } else if (_action.id == SGL_WITHDRAW_TO) {
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
            } else if (_action.id == SGL_LEND) {
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
            } else if (_action.id == SGL_REPAY) {
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
            } else if (_action.id == TOFT_SEND_YB) {
                USDOSendToYBData memory data = abi.decode(
                    _action.call[4:],
                    (USDOSendToYBData)
                );
                _checkSender(data.from);

                ITOFT(_action.target).sendToYB{value: _action.value}(
                    msg.sender,
                    data.to,
                    data.amount,
                    data.assetId,
                    data.lzDstChainId,
                    data.options
                );
            } else if (_action.id == TOFT_RETRIEVE_YB) {
                (
                    address from,
                    uint256 amount,
                    uint256 assetId,
                    uint16 lzDstChainId,
                    address zroPaymentAddress,
                    bytes memory airdropAdapterParam,
                    bool strategyWithdrawal
                ) = abi.decode(
                        _action.call[4:],
                        (
                            address,
                            uint256,
                            uint256,
                            uint16,
                            address,
                            bytes,
                            bool
                        )
                    );
                _checkSender(from);

                ITOFT(_action.target).retrieveFromYB{value: _action.value}(
                    msg.sender,
                    amount,
                    assetId,
                    lzDstChainId,
                    zroPaymentAddress,
                    airdropAdapterParam,
                    strategyWithdrawal
                );
            } else if (_action.id == HELPER_LEND) {
                HelperLendData memory data = abi.decode(
                    _action.call[4:],
                    (HelperLendData)
                );
                _checkSender(data.from);

                IMarketHelper(_action.target).depositAndAddAsset(
                    data.market,
                    data.from,
                    data.amount,
                    data.deposit,
                    false
                );
            } else if (_action.id == HELPER_BORROW) {
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

                IMarketHelper(_action.target).depositAddCollateralAndBorrow{
                    value: _action.value
                }(
                    market,
                    user,
                    collateralAmount,
                    borrowAmount,
                    false,
                    deposit,
                    withdraw,
                    withdrawData
                );
            } else {
                revert("Magnetar: action not valid");
            }
        }

        require(msg.value == valAccumulator, "Magnetar: value mismatch");
    }

    // ************************* //
    // *** PRIVATE FUNCTIONS *** //
    // ************************* //
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
        require(msg.sender == sent, "Magnetar: unauthorized");
    }

    function _getRevertMsg(bytes memory _returnData) private pure {
        // If the _res length is less than 68, then
        // the transaction failed with custom error or silently (without a revert message)
        if (_returnData.length < 68) revert("Reason unknown");

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        revert(abi.decode(_returnData, (string))); // All that remains is the revert string
    }
}
