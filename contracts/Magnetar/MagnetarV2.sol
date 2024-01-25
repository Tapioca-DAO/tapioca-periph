// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// Tapioca
import {
    ITapiocaOptionBrokerCrossChain,
    ITapiocaOptionBroker
} from "tapioca-periph/interfaces/tap-token/ITapiocaOptionBroker.sol";
import {ITapiocaOFT, ITapiocaOFTBase} from "tapioca-periph/interfaces/tap-token/ITapiocaOFT.sol";
import {IMagnetarHelper} from "tapioca-periph/interfaces/periph/IMagnetarHelper.sol";
import {IPermitAction} from "tapioca-periph/interfaces/common/IPermitAction.sol";
import {ICommonData} from "tapioca-periph/interfaces/common/ICommonData.sol";
import {IYieldBox} from "tapioca-periph/interfaces/yieldBox/IYieldBox.sol";
import {IPermitAll} from "tapioca-periph/interfaces/common/IPermitAll.sol";
import {MagnetarMarketModule1} from "./modules/MagnetarMarketModule1.sol";
import {MagnetarMarketModule2} from "./modules/MagnetarMarketModule2.sol";
import {ISendFrom} from "tapioca-periph/interfaces/common/ISendFrom.sol";
import {ICluster} from "tapioca-periph/interfaces/periph/ICluster.sol";
import {IPermit} from "tapioca-periph/interfaces/common/IPermit.sol";
import {IMarket} from "tapioca-periph/interfaces/bar/IMarket.sol";
import {IUSDOBase} from "tapioca-periph/interfaces/bar/IUSDO.sol";
import {MagnetarV2Storage} from "./MagnetarV2Storage.sol";

// Interfaces

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
    // ************ //
    // *** VARS *** //
    // ************ //

    IMagnetarHelper public helper;

    event HelperUpdate(address indexed old, address indexed newHelper);

    // ************** //
    // *** ERRORS *** //
    // ************** //
    error FuncSigNotValid(bytes4 funcSig);
    error EmptyAddress();
    error ValueMismatch(uint256 expected, uint256 received); // Value mismatch in the total value asked and the msg.value in burst
    error ActionNotValid(MagnetarAction action, bytes actionCalldata); // Burst did not find what to execute
    error FailRescueEth();

    constructor(
        address _cluster,
        address _owner,
        address payable _marketModule1,
        address payable _marketModule2,
        address _yieldboxModule
    ) {
        cluster = ICluster(_cluster);
        transferOwnership(_owner);

        modules[Module.Market1] = _marketModule1;
        modules[Module.Market2] = _marketModule2;
        modules[Module.Yieldbox] = _yieldboxModule;
    }

    // ********************** //
    // *** PUBLIC METHODS *** //
    // ********************** //

    /// @notice Batch multiple calls together
    /// @param calls The list of actions to perform
    function burst(Call[] calldata calls) external payable {
        uint256 valAccumulator;

        uint256 length = calls.length;

        for (uint256 i; i < length; i++) {
            Call calldata _action = calls[i];
            if (!_action.allowFailure) {
                require(
                    _action.call.length > 0,
                    string.concat("MagnetarV2: Missing call for action with index", string(abi.encode(i)))
                );
            }

            valAccumulator += _action.value;

            /// @dev Permit on YB, or an SGL/BB market
            if (_action.id == MagnetarAction.Permit) {
                _processPermitOperation(_action.target, _action.call, _action.allowFailure);
                continue; // skip the rest of the loop
            }

            /// @dev Wrap/SendFrom operations on TOFT
            if (_action.id == MagnetarAction.Toft) {
                _processToftAction(_action.target, _action.call, _action.value, _action.allowFailure);
                continue; // skip the rest of the loop
            }

            /// @dev addCollateral/borrow/addAsset/repay
            if (_action.id == MagnetarAction.Market) {
                _processMarketAction(_action.target, _action.call, _action.value, _action.allowFailure);
                continue; // skip the rest of the loop
            }

            /// @dev exerciseOption
            if (_action.id == MagnetarAction.Market) {
                _processTapTokenAction(_action.target, _action.call, _action.value, _action.allowFailure);
                continue; // skip the rest of the loop
            }

            /// @dev We use modules for complex operations in contrary to PERMIT/TOFT actions singular, direct operation to the target.
            /// @dev Modules will not return result data.
            if (_action.id == MagnetarAction.YieldboxModule) {
                _executeModule(Module.Yieldbox, _action.call);
                continue; // skip the rest of the loop
            }

            /// @dev We use modules for complex operations in contrary to PERMIT/TOFT actions singular, direct operation to the target.
            /// @dev Modules will not return result data.
            /// @dev Special use case for MarketModule, the module is split in two contracts, we need to check the funcSig to know which one to call.
            if (_action.id == MagnetarAction.MarketModule) {
                _handleMarketModuleCall(_action.call);
                continue; // skip the rest of the loop
            }
            // If no valid action was found, revert
            revert ActionNotValid(_action.id, _action.call);
        }

        if (msg.value != valAccumulator) revert ValueMismatch(msg.value, valAccumulator);
    }

    // ********************* //
    // *** OWNER METHODS *** //
    // ********************* //

    /// @notice updates the cluster address
    /// @dev can only be called by the owner
    /// @param _cluster the new address
    function setCluster(ICluster _cluster) external onlyOwner {
        if (address(_cluster) == address(0)) revert EmptyAddress();
        emit ClusterSet(cluster, _cluster);
        cluster = _cluster;
    }

    function setHelper(address _helper) external onlyOwner {
        emit HelperUpdate(address(helper), _helper);
        helper = IMagnetarHelper(_helper);
    }

    /// @notice rescues unused ETH from the contract
    /// @param amount the amount to rescue
    /// @param to the recipient
    function rescueEth(uint256 amount, address to) external onlyOwner {
        (bool success,) = to.call{value: amount}("");
        if (!success) revert FailRescueEth();
    }

    // ************************ //
    // *** INTERNAL METHODS *** //
    // ************************ //

    /**
     * @dev Process a permit operation, will only execute if the selector is allowed.
     * @dev !!! WARNING !!! Make sure to check the Owner param and check that function definition didn't change.
     *
     * @param _target The contract address to call.
     * @param _actionCalldata The calldata to send to the target.
     * @param _allowFailure Whether to allow the call to fail.
     */
    function _processPermitOperation(address _target, bytes calldata _actionCalldata, bool _allowFailure) internal {
        /// @dev owner address should always be first param.
        // permitAction(bytes,uint16)
        //      permit(address owner...)
        //      revoke(address owner...)
        // permitAll(address from,..)
        // permit(address from,...)
        // setApprovalForAll(address from,...)
        // setApprovalForAsset(address from,...)
        bytes4 funcSig = bytes4(_actionCalldata[:4]);
        if (
            funcSig == IPermitAction.permitAction.selector || funcSig == IPermitAll.permitAll.selector
                || funcSig == IPermitAll.revokeAll.selector || funcSig == IPermit.permit.selector
                || funcSig == IPermit.revoke.selector || funcSig == IYieldBox.setApprovalForAll.selector
                || funcSig == IYieldBox.setApprovalForAsset.selector
        ) {
            /// @dev Owner param check. See Warning above.
            _checkSender(abi.decode(_actionCalldata[4:36], (address)));
            // No need to send value on permit
            _executeCall(_target, _actionCalldata, 0, _allowFailure);
            return;
        }
        revert ActionNotValid(MagnetarAction.Permit, _actionCalldata);
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
    function _processToftAction(
        address _target,
        bytes calldata _actionCalldata,
        uint256 _actionValue,
        bool _allowFailure
    ) internal {
        /// @dev owner address should always be first param.
        // wrap(address from,...)
        // sendFrom(address from,...)
        // sendToYBAndBorrow(address from,...)
        // sendAndLendOrRepay(address _from,...)
        // removeAsset(address _from,...)
        bytes4 funcSig = bytes4(_actionCalldata[:4]);
        if (
            funcSig == ISendFrom.sendFrom.selector || funcSig == ITapiocaOFTBase.wrap.selector
                || funcSig == ITapiocaOFT.sendToYBAndBorrow.selector || funcSig == IUSDOBase.sendAndLendOrRepay.selector
                || funcSig == IUSDOBase.removeAsset.selector
        ) {
            /// @dev Owner param check. See Warning above.
            _checkSender(abi.decode(_actionCalldata[4:36], (address)));
            _executeCall(_target, _actionCalldata, _actionValue, _allowFailure);
            return;
        }
        revert ActionNotValid(MagnetarAction.Toft, _actionCalldata);
    }

    /**
     * @dev Process a Market operation, will only execute if the selector is allowed.
     * @dev !!! WARNING !!! Make sure to check the Owner param and check that function definition didn't change.
     *
     * @param _target The contract address to call.
     * @param _actionCalldata The calldata to send to the target.
     * @param _actionValue The value to send with the call.
     * @param _allowFailure Whether to allow the call to fail.
     */
    function _processMarketAction(
        address _target,
        bytes calldata _actionCalldata,
        uint256 _actionValue,
        bool _allowFailure
    ) internal {
        /// @dev owner address should always be first param.
        // addCollateral(address from,...)
        // borrow(address from,...)
        // addAsset(address from,...)
        // repay(address _from,...)
        // buyCollateral(address from,...)
        // sellCollateral(address from,...)
        bytes4 funcSig = bytes4(_actionCalldata[:4]);
        if (
            funcSig == IMarket.addCollateral.selector || funcSig == IMarket.borrow.selector
                || funcSig == IMarket.addAsset.selector || funcSig == IMarket.repay.selector
                || funcSig == IMarket.buyCollateral.selector || funcSig == IMarket.sellCollateral.selector
        ) {
            /// @dev Owner param check. See Warning above.
            _checkSender(abi.decode(_actionCalldata[4:36], (address)));
            _executeCall(_target, _actionCalldata, _actionValue, _allowFailure);
            return;
        }
        revert ActionNotValid(MagnetarAction.Market, _actionCalldata);
    }

    /**
     * @dev Data for `ITapiocaOptionBrokerCrossChain.exerciseOption` action.
     */
    struct MagnetarAction__TapTokenExerciseOptionData {
        ITapiocaOptionBrokerCrossChain.IExerciseOptionsData optionsData;
        ITapiocaOptionBrokerCrossChain.IExerciseLZData lzData;
        ITapiocaOptionBrokerCrossChain.IExerciseLZSendTapData tapSendData;
        ICommonData.IApproval[] approvals;
        ICommonData.IApproval[] revokes;
        address airdropAddress;
        uint256 airdropAmount;
        uint256 extraGas;
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

    function _processTapTokenAction(
        address _target,
        bytes calldata _actionCalldata,
        uint256 _actionValue,
        bool _allowFailure
    ) internal {
        /// @dev owner address should always be first param.
        // exerciseOption(...)
        bytes4 funcSig = bytes4(_actionCalldata[:4]);
        if (funcSig == ITapiocaOptionBrokerCrossChain.exerciseOption.selector) {
            _executeCall(_target, _actionCalldata, _actionValue, _allowFailure);
            return;
        }
        revert ActionNotValid(MagnetarAction.TapToken, _actionCalldata);
    }

    /**
     * @dev Special handler for MarketModule call. The module was split into 2 contracts because of the total size of it.
     * @dev This function will check the funcSig and call the right contract.
     */
    function _handleMarketModuleCall(bytes calldata call) internal {
        bytes4 funcSig = bytes4(call[:4]);
        // Check `MagnetarMarketModule1` fallBack handler
        if (
            funcSig == MagnetarMarketModule1.depositAddCollateralAndBorrowFromMarket.selector
                || funcSig == MagnetarMarketModule1.mintFromBBAndLendOnSGL.selector
        ) {
            _executeModule(Module.Market1, call);
            return;
        }
        // Check `MagnetarMarketModule2` fallBack handler
        if (
            funcSig == MagnetarMarketModule2.depositRepayAndRemoveCollateralFromMarket.selector
                || funcSig == MagnetarMarketModule2.exitPositionAndRemoveCollateral.selector
        ) {
            _executeModule(Module.Market2, call);
            return;
        }
    }

    /**
     * @dev Executes a call to an address, optionally reverting on failure. Make sure to sanitize prior to calling.
     */
    function _executeCall(address _target, bytes calldata _actionCalldata, uint256 _actionValue, bool _allowFailure)
        internal
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
