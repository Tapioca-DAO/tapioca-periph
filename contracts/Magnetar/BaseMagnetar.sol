// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// Tapioca
import {IMagnetarModuleExtender} from "tapioca-periph/interfaces/periph/IMagnetar.sol";
import {IMagnetarHelper} from "tapioca-periph/interfaces/periph/IMagnetarHelper.sol";
import {ICluster} from "tapioca-periph/interfaces/periph/ICluster.sol";
import {MagnetarStorage, IPearlmit} from "./MagnetarStorage.sol";

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

/**
 * @title BaseMagnetar
 * @author TapiocaDAO
 * @notice Base contract for Magnetar
 */
contract BaseMagnetar is Ownable, MagnetarStorage {
    IMagnetarModuleExtender public magnetarModuleExtender; // For future implementations

    error Magnetar_FailRescueEth();
    error Magnetar_EmptyAddress();

    event HelperUpdate(address indexed old, address indexed newHelper);
    event ClusterUpdated(ICluster indexed oldCluster, ICluster indexed newCluster);
    event MagnetarModuleExtenderSet(address old, address newMagnetarModuleExtender);

    constructor(ICluster _cluster, IPearlmit _pearlmit, address _toeHelper, address _owner)
        MagnetarStorage(_pearlmit, _toeHelper)
    {
        cluster = _cluster;
        transferOwnership(_owner);
    }

    /// =====================
    /// Owner
    /// =====================
    /**
     * @notice updates the Cluster address.
     * @dev can only be called by the owner.
     * @param _cluster the new address.
     */
    function setCluster(ICluster _cluster) external onlyOwner {
        if (address(_cluster) == address(0)) revert Magnetar_EmptyAddress();
        emit ClusterUpdated(cluster, _cluster);
        cluster = _cluster;
    }

    /**
     * @notice updates the MagnetarHelper address.
     * @dev can only be called by the owner.
     * @param _helper the new address.
     */
    function setHelper(address _helper) external onlyOwner {
        emit HelperUpdate(address(helper), _helper);
        helper = IMagnetarHelper(_helper);
    }

    /**
     * @notice updates the `magnetarModuleExtender` state variable
     */
    function setMagnetarModuleExtender(IMagnetarModuleExtender _magnetarModuleExtender) external onlyOwner {
        emit MagnetarModuleExtenderSet(address(magnetarModuleExtender), address(_magnetarModuleExtender));
        magnetarModuleExtender = _magnetarModuleExtender;
    }

    /**
     * @notice rescues unused ETH from the contract.
     * @param amount the amount to rescue.
     * @param to the recipient.
     */
    function rescueEth(uint256 amount, address to) external onlyOwner {
        (bool success,) = to.call{value: amount}("");
        if (!success) revert Magnetar_FailRescueEth();
    }
}
