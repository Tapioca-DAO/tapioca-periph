// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {OFTMsgCodec} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/libs/OFTMsgCodec.sol";
import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Tapioca
import {ITapiocaOptionLiquidityProvision} from
    "tapioca-periph/interfaces/tap-token/ITapiocaOptionLiquidityProvision.sol";
import {MagnetarAction, MagnetarModule, MagnetarCall} from "tapioca-periph/interfaces/periph/IMagnetar.sol";
import {ITapiocaOmnichainEngine, LZSendParam} from "tapioca-periph/interfaces/periph/ITapiocaOmnichainEngine.sol";
import {ITapiocaOptionBroker} from "tapioca-periph/interfaces/tap-token/ITapiocaOptionBroker.sol";
import {IMagnetarModuleExtender} from "tapioca-periph/interfaces/periph/IMagnetar.sol";
import {RevertMsgDecoder} from "tapioca-periph/libraries/RevertMsgDecoder.sol";
import {ISingularity} from "tapioca-periph/interfaces/bar/ISingularity.sol";
import {IYieldBox} from "tapioca-periph/interfaces/yieldbox/IYieldBox.sol";
import {IPermitAll} from "tapioca-periph/interfaces/common/IPermitAll.sol";
import {IMagnetar} from "tapioca-periph/interfaces/periph/IMagnetar.sol";
import {ICluster} from "tapioca-periph/interfaces/periph/ICluster.sol";
import {IPearlmit} from "tapioca-periph/pearlmit/PearlmitHandler.sol";
import {ITwTap} from "tapioca-periph/interfaces/tap-token/ITwTap.sol";
import {IPermit} from "tapioca-periph/interfaces/common/IPermit.sol";
import {SafeApprove} from "tapioca-periph/libraries/SafeApprove.sol";
import {IMarket} from "tapioca-periph/interfaces/bar/IMarket.sol";
import {Module} from "tapioca-periph/interfaces/bar/IMarket.sol";
import {ITOFT} from "tapioca-periph/interfaces/oft/ITOFT.sol";
import {BaseMagnetar} from "./BaseMagnetar.sol";
/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

/**
 * @title Magnetar
 * @author TapiocaDAO
 * @notice Magnetar helper contract
 */
contract Magnetar is BaseMagnetar, ERC1155Holder {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;
    using SafeApprove for address;

    error Magnetar_ValueMismatch(uint256 expected, uint256 received); // Value mismatch in the total value asked and the msg.value in burst
    error Magnetar_ActionNotValid(uint8 action, bytes actionCalldata); // Burst did not find what to execute
    error Magnetar_PearlmitTransferFailed(); // Transfer failed in pearlmit
    error Magnetar_MarketOperationNotAllowed();

    constructor(
        ICluster _cluster,
        address _owner,
        address payable _collateralModule,
        address payable _mintModule,
        address payable _optionModule,
        address payable _yieldBoxModule,
        IPearlmit _pearlmit,
        address _toeHelper
    ) BaseMagnetar(_cluster, _pearlmit, _toeHelper, _owner) {
        modules[MagnetarModule.CollateralModule] = _collateralModule;
        modules[MagnetarModule.MintModule] = _mintModule;
        modules[MagnetarModule.OptionModule] = _optionModule;
        modules[MagnetarModule.YieldBoxModule] = _yieldBoxModule;
    }

    /// =====================
    /// Public
    /// =====================
    /**
     * @notice Batch multiple calls together
     * @param calls The list of actions to perform
     */
    function burst(MagnetarCall[] calldata calls) external payable {
        // @dev: make sure the current magnetar is whitelisted
        _checkWhitelisted(address(this));

        uint256 valAccumulator;

        uint256 length = calls.length;

        for (uint256 i; i < length; i++) {
            MagnetarCall calldata _action = calls[i];

            valAccumulator += _action.value;

            /// @dev Permit on YB, or an SGL/BB market
            if (_action.id == uint8(MagnetarAction.Permit)) {
                _processPermitOperation(_action.target, _action.call);
                continue; // skip the rest of the loop
            }

            if (_action.id == uint8(MagnetarAction.OFT)) {
                _processOFTOperation(_action.target, _action.call, _action.value);
                continue; // skip the rest of the loop
            }

            if (_action.id == uint8(MagnetarAction.TapLock)) {
                _processTapLockOperation(_action.target, _action.call, _action.value);
                continue; // skip the rest of the loop
            }

            if (_action.id == uint8(MagnetarAction.TapUnlock)) {
                _processTapUnlockOperation(_action.target, _action.call, _action.value);
                continue; // skip the rest of the loop
            }

            /// @dev Market singular operations
            if (_action.id == uint8(MagnetarAction.Market)) {
                _processMarketOperation(_action.target, _action.call, _action.value);
                continue; // skip the rest of the loop
            }

            if (_action.id == uint8(MagnetarAction.ExerciseOption)) {
                _processExerciseOption(_action.target, _action.call, _action.value);
                continue;
            }

            /// @dev Modules will not return result data.
            if (_action.id == uint8(MagnetarAction.CollateralModule)) {
                _executeModule(MagnetarModule.CollateralModule, _action.call);
                continue; // skip the rest of the loop
            }

            /// @dev Modules will not return result data.
            if (_action.id == uint8(MagnetarAction.MintModule)) {
                _executeModule(MagnetarModule.MintModule, _action.call);
                continue; // skip the rest of the loop
            }

            /// @dev Modules will not return result data.
            if (_action.id == uint8(MagnetarAction.OptionModule)) {
                _executeModule(MagnetarModule.OptionModule, _action.call);
                continue; // skip the rest of the loop
            }

            /// @dev Modules will not return result data.
            if (_action.id == uint8(MagnetarAction.YieldBoxModule)) {
                _executeModule(MagnetarModule.YieldBoxModule, _action.call);
                continue; // skip the rest of the loop
            }

            // If no valid action was found, use the Magnetar module extender. Only if the action is valid.
            if (address(magnetarModuleExtender) != address(0) && magnetarModuleExtender.isValidActionId(_action.id)) {
                bytes memory callData = abi.encodeWithSelector(IMagnetarModuleExtender.handleAction.selector, _action);
                (bool success, bytes memory returnData) = address(magnetarModuleExtender).delegatecall(callData);
                if (!success) {
                    revert(RevertMsgDecoder._getRevertMsg(returnData));
                }
            } else {
                // If no valid action was found, revert
                revert Magnetar_ActionNotValid(_action.id, _action.call);
            }
        }

        if (msg.value != valAccumulator) revert Magnetar_ValueMismatch(msg.value, valAccumulator);
    }

    /// =====================
    /// Private
    /// =====================
    /**
     * @dev Process a permit operation, will only execute if the selector is allowed.
     * @dev !!! WARNING !!! Make sure to check the Owner param and check that function definition didn't change.
     *
     * @param _target The contract address to call.
     * @param _actionCalldata The calldata to send to the target.
     */
    function _processPermitOperation(address _target, bytes calldata _actionCalldata) private {
        /**
         * @dev Executes the following:
         *      permit(address owner...)
         *      revoke(address owner...)
         *      permitAll(address from,..)
         *      revokeAll(address from,..)
         */
        bool selectorValidated = _validatePermitOperation(_target, _actionCalldata);
        /// @dev no need to check the owner for the rest; it's using `msg.sender`
        if (selectorValidated) {
            // No need to send value on permit
            _executeCall(_target, _actionCalldata, 0);
            return;
        }
        revert Magnetar_ActionNotValid(uint8(MagnetarAction.Permit), _actionCalldata);
    }

    function _validatePermitOperation(address _target, bytes calldata _actionCalldata)
        private
        view
        returns (bool selectorValidated)
    {
        selectorValidated = false;

        _checkWhitelisted(_target);

        bytes4 funcSig = bytes4(_actionCalldata[:4]);
        if (
            funcSig == IPermitAll.permitAll.selector || funcSig == IPermitAll.revokeAll.selector
                || funcSig == IPermit.permit.selector || funcSig == IPermit.revoke.selector
        ) {
            selectorValidated = true;
            /// @dev Owner param check. See Warning above.
            _checkSender(abi.decode(_actionCalldata[4:36], (address)));
        }

        // IPearlmit.permitBatchApprove(IPearlmit.PermitBatchTransferFrom calldata batch)
        if (funcSig == IPearlmit.permitBatchApprove.selector) {
            selectorValidated = true;
            IPearlmit.PermitBatchTransferFrom memory batch =
                abi.decode(_actionCalldata[4:], (IPearlmit.PermitBatchTransferFrom));

            /// @dev Owner param check. See Warning above.
            _checkSender(batch.owner);
        }
    }
    /**
     * @dev Process a TOFT operation, will only execute if the selector is allowed.
     * @dev !!! WARNING !!! Make sure to check the Owner param and check that function definition didn't change.
     *
     * @param _target The contract address to call.
     * @param _actionCalldata The calldata to send to the target.
     * @param _actionValue The value to send with the call.
     */

    function _processOFTOperation(address _target, bytes calldata _actionCalldata, uint256 _actionValue) private {
        /**
         * @dev Executes the following:
         *      wrap(address from,...)
         *      unwrap(address from,...)
         *      sendPacketFrom(...)
         */
        bool selectorValidated = _validateOFTOperation(_target, _actionCalldata);
        if (selectorValidated) {
            bytes4 funcSig = bytes4(_actionCalldata[:4]);
            if (funcSig == ITOFT.unwrap.selector) {
                (, uint256 _amount) = abi.decode(_actionCalldata[4:36], (address, uint256));
                bool isErr = pearlmit.transferFromERC20(msg.sender, address(this), _target, _amount); //unwrap happens on `msg.sender`
                if (isErr) revert Magnetar_PearlmitTransferFailed();
            }
            if (funcSig == ITapiocaOmnichainEngine.sendPacketFrom.selector) {
                (, LZSendParam memory lzSendParam_,) = abi.decode(_actionCalldata[4:], (address, LZSendParam, bytes));
                uint256 amount_ = lzSendParam_.sendParam.amountLD;
                bool isErr = pearlmit.transferFromERC20(msg.sender, address(this), _target, amount_); //sendPacketFrom happens on msg.sender
                if (isErr) revert Magnetar_PearlmitTransferFailed();
            }

            _executeCall(_target, _actionCalldata, _actionValue);
            return;
        }

        revert Magnetar_ActionNotValid(uint8(MagnetarAction.OFT), _actionCalldata);
    }

    function _validateOFTOperation(address _target, bytes calldata _actionCalldata)
        private
        view
        returns (bool selectorValidated)
    {
        selectorValidated = false;

        _checkWhitelisted(_target);

        bytes4 funcSig = bytes4(_actionCalldata[:4]);
        if (funcSig == ITOFT.wrap.selector) {
            selectorValidated = true;
            /// @dev Owner param check. See Warning above.
            _checkSender(abi.decode(_actionCalldata[4:36], (address)));
        }

        if (funcSig == ITOFT.unwrap.selector) {
            selectorValidated = true;
        }

        if (funcSig == ITapiocaOmnichainEngine.sendPacketFrom.selector) {
            selectorValidated = true;
            (address from_, LZSendParam memory lzSendParam_,) =
                abi.decode(_actionCalldata[4:], (address, LZSendParam, bytes));
            address owner_ = OFTMsgCodec.bytes32ToAddress(lzSendParam_.sendParam.to);
            _checkSender(owner_);
            _checkSender(from_);
        }
    }

    /**
     * @dev Process a market operation, will only execute if the selector is allowed.
     * @dev !!! WARNING !!! Make sure to check the Owner param and check that function definition didn't change.
     *
     * @param _target The contract address to call.
     * @param _actionCalldata The calldata to send to the target.
     * @param _actionValue The value to send with the call.
     */
    function _processMarketOperation(address _target, bytes calldata _actionCalldata, uint256 _actionValue) private {
        /**
         * @dev Executes the following:
         *      addCollateral(address from, address to, bool skim, uint256 amount, uint256 share)
         *      removeCollateral(address from, address to, uint256 share)
         *      borrow(address from, address to, uint256 amount)
         *      repay(address from, address to, bool skim, uint256 part)
         *      buyCollateral(address from, uint256 borrowAmount, uint256 supplyAmount, bytes calldata data)
         *      sellCollateral(address from, uint256 share, bytes calldata data)
         *      addAsset(address from, address to, bool skim, uint256 share)
         *      removeAsset(address from, address to, uint256 fraction)
         */

        /// @dev owner address should always be first param.
        bool selectorValidated = _validateMarketOperation(_target, _actionCalldata);

        if (selectorValidated) {
            _executeCall(_target, _actionCalldata, _actionValue);
            return;
        }
        revert Magnetar_ActionNotValid(uint8(MagnetarAction.Market), _actionCalldata);
    }

    function _validateMarketOperation(address _target, bytes calldata _actionCalldata)
        private
        view
        returns (bool selectorValidated)
    {
        selectorValidated = false;

        _checkWhitelisted(_target);

        bytes4 funcSig = bytes4(_actionCalldata[:4]);
        // function addCollateral(address from, address to, bool skim, uint256 amount, uint256 share)
        // function removeCollateral(address from, address to, uint256 share)
        // function borrow(address from, address to, uint256 amount)
        // function repay(address from, address to, bool skim, uint256 part)
        // function buyCollateral(address from, uint256 borrowAmount, uint256 supplyAmount, bytes calldata data)
        // function sellCollateral(address from, uint256 share, bytes calldata data)
        if (funcSig == IMarket.execute.selector) {
            selectorValidated = true;
            (Module[] memory modules, bytes[] memory calls,) =
                abi.decode(_actionCalldata[4:], (Module[], bytes[], bool));
            // sanitize modules
            uint256 modulesLength;
            for (uint256 i; i < modulesLength; i++) {
                if (modules[i] == Module.Liquidation) revert Magnetar_MarketOperationNotAllowed();
            }

            // sanitize call
            uint256 callsLength = calls.length;
            for (uint256 i; i < callsLength; i++) {
                bytes memory _call = calls[i];

                address _from;
                assembly {
                    let dataPointer := add(_call, 0x24)
                    _from := mload(dataPointer)
                }
                _checkSender(_from);
            }
        }

        // function addAsset(address from, address to, bool skim, uint256 share)
        // function removeAsset(address from, address to, uint256 fraction)
        if (funcSig == ISingularity.addAsset.selector || funcSig == ISingularity.removeAsset.selector) {
            selectorValidated = true;
            /// @dev Owner param check. See Warning above.
            _checkSender(abi.decode(_actionCalldata[4:36], (address)));
        }
    }

    /**
     * @dev Process a TOB/TOLP/TWTAP lock operation, will only execute if the selector is allowed.
     * @dev !!! WARNING !!! Make sure to check the Owner param and check that function definition didn't change.
     *
     * @param _target The contract address to call.
     * @param _actionCalldata The calldata to send to the target.
     * @param _actionValue The value to send with the call.
     */
    function _processTapLockOperation(address _target, bytes calldata _actionCalldata, uint256 _actionValue) private {
        /**
         * @dev Executes the following:
         *      lock(....)
         *      participate(....)
         *      lock(....)
         */
        bool selectorValidated = _validateTapLockOperation(_target, _actionCalldata);

        if (selectorValidated) {
            bytes4 funcSig = bytes4(_actionCalldata[:4]);

            // Token is sent to the owner after execute
            if (funcSig == ITapiocaOptionLiquidityProvision.lock.selector) {
                (address from, address sgl,, uint128 amount) =
                    abi.decode(_actionCalldata[4:], (address, address, uint128, uint128));
                (uint256 assetId,,) = ITapiocaOptionLiquidityProvision(_target).activeSingularities(sgl);
                address yieldBox = ITapiocaOptionLiquidityProvision(_target).yieldBox();

                {
                    bool isErr = pearlmit.transferFromERC1155(from, address(this), yieldBox, assetId, amount);
                    if (isErr) {
                        revert Magnetar_PearlmitTransferFailed();
                    }
                }

                pearlmit.approve(1155, yieldBox, assetId, _target, amount, block.timestamp.toUint48());
                IYieldBox(yieldBox).setApprovalForAll(address(pearlmit), true);
                _executeCall(_target, _actionCalldata, _actionValue);
                IYieldBox(yieldBox).setApprovalForAll(address(pearlmit), false);

                return;
            }

            // Token is sent to msg.sender after execute, need to send back
            if (funcSig == ITapiocaOptionBroker.participate.selector) {
                (uint256 tokenId) = abi.decode(_actionCalldata[4:], (uint256));
                address tOLP = ITapiocaOptionBroker(_target).tOLP();

                {
                    // function is executed for `msg.sender`
                    bool isErr = pearlmit.transferFromERC721(msg.sender, address(this), tOLP, tokenId);
                    if (isErr) {
                        revert Magnetar_PearlmitTransferFailed();
                    }
                }

                pearlmit.approve(721, tOLP, tokenId, _target, 1, block.timestamp.toUint48());
                ITapiocaOptionLiquidityProvision(tOLP).setApprovalForAll(address(pearlmit), true);
                (bytes memory tokenIdData) = _executeCall(_target, _actionCalldata, _actionValue);
                ITapiocaOptionLiquidityProvision(tOLP).setApprovalForAll(address(pearlmit), false);

                address oTAP = ITapiocaOptionBroker(_target).oTAP();
                ITapiocaOptionLiquidityProvision(oTAP).safeTransferFrom(
                    address(this), msg.sender, abi.decode(tokenIdData, (uint256))
                );

                return;
            }

            // Token is sent to the owner after execute
            if (funcSig == ITwTap.participate.selector) {
                (address from, uint256 amount,) = abi.decode(_actionCalldata[4:], (address, uint256, uint256));
                address tapOFT = ITwTap(_target).tapOFT();

                {
                    bool isErr = pearlmit.transferFromERC20(from, address(this), address(tapOFT), amount);
                    if (isErr) {
                        revert Magnetar_PearlmitTransferFailed();
                    }
                }

                pearlmit.approve(20, tapOFT, 0, _target, amount.toUint200(), block.timestamp.toUint48());

                tapOFT.safeApprove(address(pearlmit), type(uint256).max);
                _executeCall(_target, _actionCalldata, _actionValue);
                tapOFT.safeApprove(address(pearlmit), 0);
                return;
            }
        }

        revert Magnetar_ActionNotValid(uint8(MagnetarAction.Market), _actionCalldata);
    }

    function _validateTapLockOperation(address _target, bytes calldata _actionCalldata)
        private
        view
        returns (bool selectorValidated)
    {
        selectorValidated = false;

        _checkWhitelisted(_target);

        bytes4 funcSig = bytes4(_actionCalldata[:4]);
        if (funcSig == ITapiocaOptionLiquidityProvision.lock.selector || funcSig == ITwTap.participate.selector) {
            /// @dev Owner param check. See Warning above.
            _checkSender(abi.decode(_actionCalldata[4:36], (address)));
            selectorValidated = true;
        }
        if (funcSig == ITapiocaOptionBroker.participate.selector) selectorValidated = true;
    }

    /**
     * @dev Process a TOB/TOLP/TWTAP unlock operation, will only execute if the selector is allowed.
     *
     * @param _target The contract address to call.
     * @param _actionCalldata The calldata to send to the target.
     * @param _actionValue The value to send with the call.
     */
    function _processTapUnlockOperation(address _target, bytes calldata _actionCalldata, uint256 _actionValue)
        private
    {
        /**
         * @dev Executes the following:
         *      twTap.exitPosition(....)
         *      tOB.exitPosition(....)
         *      tOLP.unlock(....)
         */
        bool selectorValidated = _validateTapUnlockOperation(_target, _actionCalldata);

        /// @dev No need to check owner as anyone can unlock twTap/tOB/tOLP positions by design.
        /// Owner of the token receives the unlocked tokens.
        if (selectorValidated) {
            _executeCall(_target, _actionCalldata, _actionValue);
            return;
        }
        revert Magnetar_ActionNotValid(uint8(MagnetarAction.Market), _actionCalldata);
    }

    function _validateTapUnlockOperation(address _target, bytes calldata _actionCalldata)
        private
        view
        returns (bool selectorValidated)
    {
        _checkWhitelisted(_target);

        bytes4 funcSig = bytes4(_actionCalldata[:4]);
        selectorValidated = funcSig == ITwTap.exitPosition.selector
            || funcSig == ITapiocaOptionBroker.exitPosition.selector
            || funcSig == ITapiocaOptionLiquidityProvision.unlock.selector;
    }

    /**
     * @dev Process a TOB exerciseOption operation, will only execute if the selector is allowed.
     *
     * @param _target The contract address to call.
     * @param _actionCalldata The calldata to send to the target.
     * @param _actionValue The value to send with the call.
     */
    function _processExerciseOption(address _target, bytes calldata _actionCalldata, uint256 _actionValue) private {
        /**
         * @dev Executes the following:
         *      tOB.exerciseOption(....)
         */
        {
            bool selectorValidated = _validateExerciseOption(_target, _actionCalldata);
            if (!selectorValidated) {
                revert Magnetar_ActionNotValid(uint8(MagnetarAction.Market), _actionCalldata);
            }
        }

        /// @dev No need to check owner as anyone can unlock twTap/tOB/tOLP positions by design.
        /// Owner of the token receives the unlocked tokens.
        (uint256 _oTAPTokenID, address _paymentToken, uint256 _tapAmount) =
            abi.decode(_actionCalldata[4:], (uint256, address, uint256));

        // compute `paymentToken` amount
        (uint256 eligibleTapAmount,, uint256 _eligibleTapAmount) =
            ITapiocaOptionBroker(_target).getOTCDealDetails(_oTAPTokenID, _paymentToken, _tapAmount);
        address tapToken = ITapiocaOptionBroker(_target).tapOFT();

        // transfer `paymentToken` here
        {
            // executed for `msg.sender`
            bool isErr = pearlmit.transferFromERC20(msg.sender, address(this), _paymentToken, eligibleTapAmount);
            if (isErr) {
                revert Magnetar_PearlmitTransferFailed();
            }
        }

        uint256 tapAmountBefore = IERC20(tapToken).balanceOf(address(this));

        // execute
        pearlmit.approve(20, _paymentToken, 0, _target, eligibleTapAmount.toUint200(), block.timestamp.toUint48());
        _paymentToken.safeApprove(address(pearlmit), eligibleTapAmount);
        _executeCall(_target, _actionCalldata, _actionValue);
        _paymentToken.safeApprove(address(pearlmit), 0);

        // Clear Pearlmit ERC721 allowance post execution
        {
            address oTap = ITapiocaOptionBroker(_target).oTAP();
            address oTapOwner = IERC721(oTap).ownerOf(_oTAPTokenID);
            pearlmit.clearAllowance(oTapOwner, 721, oTap, _oTAPTokenID);
        }

        uint256 tapAmountAfter = IERC20(tapToken).balanceOf(address(this));

        // @dev we can also use `_eligibleTapAmount` here, but just in case
        IERC20(tapToken).safeTransfer(msg.sender, tapAmountAfter - tapAmountBefore);
    }

    function _validateExerciseOption(address _target, bytes calldata _actionCalldata)
        private
        view
        returns (bool selectorValidated)
    {
        _checkWhitelisted(_target);
        bytes4 funcSig = bytes4(_actionCalldata[:4]);
        selectorValidated = funcSig == ITapiocaOptionBroker.exerciseOption.selector;
    }

    /**
     * @dev Executes a call to an address, optionally reverting on failure. Make sure to sanitize prior to calling.
     */
    function _executeCall(address _target, bytes calldata _actionCalldata, uint256 _actionValue)
        private
        returns (bytes memory returnData)
    {
        bool success;
        (success, returnData) = _target.call{value: _actionValue}(_actionCalldata);

        if (!success) {
            revert(RevertMsgDecoder._getRevertMsg(returnData));
        }
    }
}
