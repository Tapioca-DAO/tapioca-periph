// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// Tapioca
import {IMagnetarModuleExtender} from "tapioca-periph/interfaces/periph/IMagnetar.sol";
import {IMagnetarHelper} from "tapioca-periph/interfaces/periph/IMagnetarHelper.sol";
import {ICluster} from "tapioca-periph/interfaces/periph/ICluster.sol";
import {MagnetarStorage} from "./MagnetarStorage.sol";

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

/**
 * @title BaseMagnetar
 * @author TapiocaDAO
 * @notice Base contract for Magnetar
 */
contract BaseMagnetar is Ownable, MagnetarStorage {
    IMagnetarHelper public helper;
    IMagnetarModuleExtender public magnetarModuleExtender; // For future implementations

    error Magnetar_FailRescueEth();
    error Magnetar_EmptyAddress();

    event HelperUpdate(address indexed old, address indexed newHelper);
    event ClusterUpdated(ICluster indexed oldCluster, ICluster indexed newCluster);
    event MagnetarModuleExtenderSet(address old, address newMagnetarModuleExtender);

    constructor(ICluster _cluster, address _owner) {
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
