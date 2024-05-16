// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

// Tapioca
import {TapiocaOmnichainEngineHelper} from
    "tapioca-periph/tapiocaOmnichainEngine/extension/TapiocaOmnichainEngineHelper.sol";
import {MagnetarModule} from "tapioca-periph/interfaces/periph/IMagnetar.sol";
import {PearlmitHandler, IPearlmit} from "tapioca-periph/pearlmit/PearlmitHandler.sol";
import {IMagnetarHelper} from "tapioca-periph/interfaces/periph/IMagnetarHelper.sol";
import {RevertMsgDecoder} from "tapioca-periph/libraries/RevertMsgDecoder.sol";
import {ICluster} from "tapioca-periph/interfaces/periph/ICluster.sol";

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

/**
 * @title MagnetarStorage
 * @author TapiocaDAO
 * @notice Storage contract for Magnetar & modules
 */
contract MagnetarStorage is IERC721Receiver, PearlmitHandler {
    ICluster internal cluster;
    IMagnetarHelper public helper;
    TapiocaOmnichainEngineHelper public toeHelper;

    mapping(MagnetarModule moduleId => address moduleAddress) internal modules;

    // Helpers for external usage. Not used in the contract.
    uint8 public constant MAGNETAR_ACTION_PERMIT = 0;
    uint8 public constant MAGNETAR_ACTION_MARKET = 2;
    uint8 public constant MAGNETAR_ACTION_TAP_LOCK = 3;
    uint8 public constant MAGNETAR_ACTION_TAP_UNLOCK = 4;
    uint8 public constant MAGNETAR_ACTION_OFT = 5;
    uint8 public constant MAGNETAR_ACTION_COLLATERAL_MODULE = 6;
    uint8 public constant MAGNETAR_ACTION_MINT_MODULE = 7;
    uint8 public constant MAGNETAR_ACTION_OPTION_MODULE = 8;
    uint8 public constant MAGNETAR_ACTION_YIELDBOX_MODULE = 9;

    error Magnetar_NotAuthorized(address caller, address expectedCaller); // msg.send is neither the owner nor whitelisted by Cluster
    error Magnetar_ModuleNotFound(MagnetarModule module); // Module not found
    error Magnetar_UnknownReason(); // Revert reason not recognized
    error Magnetar_TargetNotWhitelisted(address addy); // cluster.isWhitelisted(lzChainId, _addr) => false

    constructor(IPearlmit _pearlmit, address _toeHelper) PearlmitHandler(_pearlmit) {
        toeHelper = TapiocaOmnichainEngineHelper(_toeHelper);
    }

    receive() external payable virtual {}

    /// =====================
    /// Public
    /// =====================

    /**
     * @dev Receiver for `MagnetarMintModule._participateOnTOLP()`
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /// =====================
    /// Private
    /// =====================
    function _executeModule(MagnetarModule _module, bytes memory _data) internal returns (bytes memory returnData) {
        bool success = true;
        address module = modules[_module];
        if (module == address(0)) revert Magnetar_ModuleNotFound(_module);

        (success, returnData) = module.delegatecall(_data);
        if (!success) {
            revert(RevertMsgDecoder._getRevertMsg(returnData));
        }
    }

    /**
     * @dev Check if the sender is authorized to call the contract.
     * sender is authorized if:
     *      - is the owner
     *      - is whitelisted by the cluster
     */
    function _checkSender(address _from) internal view {
        if (_from != msg.sender && !cluster.isWhitelisted(0, msg.sender)) {
            revert Magnetar_NotAuthorized(msg.sender, _from);
        }
    }

    function _checkWhitelisted(address addy) internal view {
        if (addy != address(0)) {
            if (!cluster.isWhitelisted(0, addy)) {
                revert Magnetar_TargetNotWhitelisted(addy);
            }
        }
    }
}
