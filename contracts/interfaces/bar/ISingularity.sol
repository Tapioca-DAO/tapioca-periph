// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {ILeverageLZData, ILeverageExternalContractsData, ILeverageSwapData} from "../oft/IUsdo.sol";
import {IMarket} from "./IMarket.sol";

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

interface ISingularity is IMarket {
    struct AccrueInfo {
        uint64 interestPerSecond;
        uint64 lastAccrued;
        uint128 feesEarnedFraction;
    }

    function accrueInfo()
        external
        view
        returns (uint64 interestPerSecond, uint64 lastBlockAccrued, uint128 feesEarnedFraction);

    function totalAsset() external view returns (uint128 elastic, uint128 base);

    function removeAsset(address from, address to, uint256 fraction) external returns (uint256 share);

    function name() external view returns (string memory);

    function nonces(address) external view returns (uint256);

    function permit(address owner_, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external;

    function allowance(address, address) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address) external view returns (uint256);

    function liquidationQueue() external view returns (address payable);

    function computeAllowedLendShare(uint256 amount, uint256 tokenId) external view returns (uint256 share);

    function getInterestDetails() external view returns (AccrueInfo memory _accrueInfo, uint256 utilization);

    function minimumTargetUtilization() external view returns (uint256);

    function maximumTargetUtilization() external view returns (uint256);

    function minimumInterestPerSecond() external view returns (uint256);

    function maximumInterestPerSecond() external view returns (uint256);

    function interestElasticity() external view returns (uint256);

    function startingInterestPerSecond() external view returns (uint256);
}
