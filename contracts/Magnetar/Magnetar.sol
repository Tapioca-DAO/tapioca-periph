// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Tapioca
import {ITapiocaOptionBroker} from "tapioca-periph/interfaces/tap-token/ITapiocaOptionBroker.sol";
import {ITapiocaOptionLiquidityProvision} from
    "tapioca-periph/interfaces/tap-token/ITapiocaOptionLiquidityProvision.sol";
import {MagnetarAction, MagnetarModule, MagnetarCall} from "tapioca-periph/interfaces/periph/IMagnetar.sol";
import {IMagnetarModuleExtender} from "tapioca-periph/interfaces/periph/IMagnetar.sol";
import {ISingularity} from "tapioca-periph/interfaces/bar/ISingularity.sol";
import {IYieldBox} from "tapioca-periph/interfaces/yieldbox/IYieldBox.sol";
import {IPermitAll} from "tapioca-periph/interfaces/common/IPermitAll.sol";
import {ICluster} from "tapioca-periph/interfaces/periph/ICluster.sol";
import {IPearlmit} from "tapioca-periph/pearlmit/PearlmitHandler.sol";
import {IPermit} from "tapioca-periph/interfaces/common/IPermit.sol";
import {IMarket} from "tapioca-periph/interfaces/bar/IMarket.sol";
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
contract Magnetar is BaseMagnetar {
    using SafeERC20 for IERC20;

    error Magnetar_ValueMismatch(uint256 expected, uint256 received); // Value mismatch in the total value asked and the msg.value in burst
    error Magnetar_ActionNotValid(MagnetarAction action, bytes actionCalldata); // Burst did not find what to execute

    constructor(
        ICluster _cluster,
        address _owner,
        address payable _assetModule,
        address payable _assetXChainModule,
        address payable _collateralModule,
        address payable _mintModule,
        address payable _mintXChainModule,
        address payable _optionModule,
        address payable _yieldBoxModule,
        IPearlmit _pearlmit
    ) BaseMagnetar(_cluster, _pearlmit, _owner) {
        modules[MagnetarModule.AssetModule] = _assetModule;
        modules[MagnetarModule.AssetXChainModule] = _assetXChainModule;
        modules[MagnetarModule.CollateralModule] = _collateralModule;
        modules[MagnetarModule.MintModule] = _mintModule;
        modules[MagnetarModule.MintXChainModule] = _mintXChainModule;
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
        uint256 valAccumulator;

        uint256 length = calls.length;

        for (uint256 i; i < length; i++) {
            MagnetarCall calldata _action = calls[i];
            if (!_action.allowFailure) {
                require(
                    _action.call.length > 0,
                    string.concat("Magnetar: Missing call for action with index", string(abi.encode(i)))
                );
            }
            valAccumulator += _action.value;

            /// @dev Permit on YB, or an SGL/BB market
            if (_action.id == MagnetarAction.Permit) {
                _processPermitOperation(_action.target, _action.call, _action.allowFailure);
                continue; // skip the rest of the loop
            }

            /// @dev Wrap/unwrap singular operations
            if (_action.id == MagnetarAction.Wrap) {
                _processWrapOperation(_action.target, _action.call, _action.value, _action.allowFailure);
                continue; // skip the rest of the loop
            }

            /// @dev Market singular operations
            if (_action.id == MagnetarAction.Market) {
                _processMarketOperation(_action.target, _action.call, _action.value, _action.allowFailure);
                continue; // skip the rest of the loop
            }

            /// @dev Tap singular operations
            if (_action.id == MagnetarAction.TapToken) {
                _processTapTokenOperation(_action.target, _action.call, _action.value, _action.allowFailure);
                continue; // skip the rest of the loop
            }

            /// @dev Modules will not return result data.
            if (_action.id == MagnetarAction.AssetModule) {
                _executeModule(MagnetarModule.AssetModule, _action.call);
                continue; // skip the rest of the loop
            }

            /// @dev Modules will not return result data.
            if (_action.id == MagnetarAction.AssetXChainModule) {
                _executeModule(MagnetarModule.AssetXChainModule, _action.call);
                continue; // skip the rest of the loop
            }

            /// @dev Modules will not return result data.
            if (_action.id == MagnetarAction.CollateralModule) {
                _executeModule(MagnetarModule.CollateralModule, _action.call);
                continue; // skip the rest of the loop
            }

            /// @dev Modules will not return result data.
            if (_action.id == MagnetarAction.MintModule) {
                _executeModule(MagnetarModule.MintModule, _action.call);
                continue; // skip the rest of the loop
            }

            /// @dev Modules will not return result data.
            if (_action.id == MagnetarAction.MintXChainModule) {
                _executeModule(MagnetarModule.MintXChainModule, _action.call);
                continue; // skip the rest of the loop
            }

            /// @dev Modules will not return result data.
            if (_action.id == MagnetarAction.OptionModule) {
                _executeModule(MagnetarModule.OptionModule, _action.call);
                continue; // skip the rest of the loop
            }

            /// @dev Modules will not return result data.
            if (_action.id == MagnetarAction.YieldBoxModule) {
                _executeModule(MagnetarModule.YieldBoxModule, _action.call);
                continue; // skip the rest of the loop
            }

            if (_action.id == MagnetarAction.OFT) {
                _processOFTOperation(_action.target, _action.call, _action.value, _action.allowFailure);
                continue; // skip the rest of the loop
            }

            // If no valid action was found, use the Magnetar module extender. Only if the action is valid.
            if (
                address(magnetarModuleExtender) != address(0)
                    && magnetarModuleExtender.isValidActionId(uint8(_action.id))
            ) {
                bytes memory callData = abi.encodeWithSelector(IMagnetarModuleExtender.handleAction.selector, _action);
                (bool success, bytes memory returnData) = address(magnetarModuleExtender).delegatecall(callData);
                if (!success) {
                    _getRevertMsg(returnData);
                }
            } else {
                // If no valid action was found, revert
                revert Magnetar_ActionNotValid(_action.id, _action.call);
            }
        }

        if (msg.value != valAccumulator) revert Magnetar_ValueMismatch(msg.value, valAccumulator);

        // @dev Magnetar shouldn't hold eth so this is safe
        // @dev if allowFailure is `true` and action fails, ETH might be left here
        if(address(this).balance>0){
            msg.sender.call{value:address(this).balance}(""); 
        }
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
     * @param _allowFailure Whether to allow the call to fail.
     */
    function _processPermitOperation(address _target, bytes calldata _actionCalldata, bool _allowFailure) private {
        if (!cluster.isWhitelisted(0, _target)) revert Magnetar_NotAuthorized(_target, _target);

        /// @dev owner address should always be first param.
        // permit(address owner...)
        // revoke(address owner...)
        // permitAll(address from,..)
        // revokeAll(address from,..)
        // permit(address from,...)
        // setApprovalForAll(address from,...)
        // setApprovalForAsset(address from,...)
        bytes4 funcSig = bytes4(_actionCalldata[:4]);
        if (
            funcSig == IPermitAll.permitAll.selector || funcSig == IPermitAll.revokeAll.selector
                || funcSig == IPermit.permit.selector || funcSig == IPermit.revoke.selector
                || funcSig == IYieldBox.setApprovalForAll.selector || funcSig == IYieldBox.setApprovalForAsset.selector
                || funcSig == IERC20.approve.selector || funcSig == IERC721.approve.selector
        ) {
            /// @dev Owner param check. See Warning above.
            _checkSender(abi.decode(_actionCalldata[4:36], (address)));
            // No need to send value on permit
            _executeCall(_target, _actionCalldata, 0, _allowFailure);
            return;
        }
        revert Magnetar_ActionNotValid(MagnetarAction.Permit, _actionCalldata);
    }

    /**
     * @dev Process a TOFT operation, will only execute if the selector is allowed.
     * @dev !!! WARNING !!! Make sure to check the Owner param and check that function definition didn't change.
     *
     * @param _target The contract address to call.
     * @param _actionCalldata The calldata to send to the target.
     * @param _actionValue The value to send with the call.
     * @param _allowFailure Whether to allow the call to fail.
     */
    // TODO: rename to `_processToftOperation` and add sendFrom operation
    function _processWrapOperation(
        address _target,
        bytes calldata _actionCalldata,
        uint256 _actionValue,
        bool _allowFailure
    ) private {
        if (!cluster.isWhitelisted(0, _target)) revert Magnetar_NotAuthorized(_target, _target);

        /// @dev owner address should always be first param.
        // wrap(address from,...)
        // unwrap(address from,...)
        bytes4 funcSig = bytes4(_actionCalldata[:4]);

        if (funcSig == ITOFT.wrap.selector) {
            /// @dev Owner param check. See Warning above.
            _checkSender(abi.decode(_actionCalldata[4:36], (address)));
        }

        if (funcSig == ITOFT.unwrap.selector) {
            (, uint256 _amount) = abi.decode(_actionCalldata[4:36], (address, uint256));
            // IERC20(_target).safeTransferFrom(msg.sender, address(this), _amount);
            {
                bool isErr = pearlmit.transferFromERC20(msg.sender, address(this), _target, _amount);
                if (isErr) revert Failed();
            }
        }

        if (funcSig == ITOFT.wrap.selector || funcSig == ITOFT.unwrap.selector) {
            _executeCall(_target, _actionCalldata, _actionValue, _allowFailure);
            return;
        }
        revert Magnetar_ActionNotValid(MagnetarAction.Wrap, _actionCalldata);
    }

    /**
     * @dev Process a market operation, will only execute if the selector is allowed.
     * @dev !!! WARNING !!! Make sure to check the Owner param and check that function definition didn't change.
     *
     * @param _target The contract address to call.
     * @param _actionCalldata The calldata to send to the target.
     * @param _actionValue The value to send with the call.
     * @param _allowFailure Whether to allow the call to fail.
     */
    function _processMarketOperation(
        address _target,
        bytes calldata _actionCalldata,
        uint256 _actionValue,
        bool _allowFailure
    ) private {
        if (!cluster.isWhitelisted(0, _target)) revert Magnetar_NotAuthorized(_target, _target);

        /// @dev owner address should always be first param.
        bytes4 funcSig = bytes4(_actionCalldata[:4]);
        if (funcSig == ISingularity.addAsset.selector || funcSig == ISingularity.removeAsset.selector) {
            /// @dev Owner param check. See Warning above.
            _checkSender(abi.decode(_actionCalldata[4:36], (address)));
        }
        if (
            funcSig == IMarket.execute.selector || funcSig == ISingularity.addAsset.selector
                || funcSig == ISingularity.removeAsset.selector
        ) {
            _executeCall(_target, _actionCalldata, _actionValue, _allowFailure);
            return;
        }
        revert Magnetar_ActionNotValid(MagnetarAction.Market, _actionCalldata);
    }

    /**
     * @dev Process a TapToken operation, will only execute if the selector is allowed.
     * @dev Different from the others. No need to check for sender.
     *
     * @param _target The contract address to call.
     * @param _actionCalldata The calldata to send to the target.
     * @param _actionValue The value to send with the call.
     * @param _allowFailure Whether to allow the call to fail.
     */
    function _processTapTokenOperation(
        address _target,
        bytes calldata _actionCalldata,
        uint256 _actionValue,
        bool _allowFailure
    ) private {
        if (!cluster.isWhitelisted(0, _target)) revert Magnetar_NotAuthorized(_target, _target);

        bytes4 funcSig = bytes4(_actionCalldata[:4]);
        if (
            funcSig == ITapiocaOptionBroker.exerciseOption.selector
                || funcSig == ITapiocaOptionBroker.participate.selector
                || funcSig == ITapiocaOptionBroker.exitPosition.selector
                || funcSig == ITapiocaOptionLiquidityProvision.lock.selector
                || funcSig == ITapiocaOptionLiquidityProvision.unlock.selector
        ) {
            _executeCall(_target, _actionCalldata, _actionValue, _allowFailure);
            return;
        }
        revert Magnetar_ActionNotValid(MagnetarAction.TapToken, _actionCalldata);
    }

    /**
     * @dev Process an OFT operation, will only execute if the selector is allowed.
     * @dev Different from the others. No need to check for sender. MsgType is sanitized by the OFT
     *
     * @param _target The contract address to call.
     * @param _actionCalldata The calldata to send to the target.
     * @param _actionValue The value to send with the call.
     * @param _allowFailure Whether to allow the call to fail.
     */
    function _processOFTOperation(
        address _target,
        bytes calldata _actionCalldata,
        uint256 _actionValue,
        bool _allowFailure
    ) private {
        if (!cluster.isWhitelisted(0, _target)) revert Magnetar_NotAuthorized(_target, _target);
        _executeCall(_target, _actionCalldata, _actionValue, _allowFailure);
    }

    /**
     * @dev Executes a call to an address, optionally reverting on failure. Make sure to sanitize prior to calling.
     */
    function _executeCall(address _target, bytes calldata _actionCalldata, uint256 _actionValue, bool _allowFailure)
        private
    {
        bool success;
        bytes memory returnData;

        if (_actionValue > 0) {
            (success, returnData) = _target.call{value: _actionValue}(_actionCalldata);
        } else {
            (success, returnData) = _target.call(_actionCalldata);
        }

        if (!success && !_allowFailure) {
            _getRevertMsg(returnData);
        }
    }
}
