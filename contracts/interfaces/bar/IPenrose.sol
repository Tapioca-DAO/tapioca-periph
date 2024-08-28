// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {IPearlmit} from "../periph/IPearlmit.sol";
import {ICluster} from "../periph/ICluster.sol";

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

interface IPenrose {
    /// @notice swap extra data
    struct SwapData {
        uint256 minAssetAmount;
    }

    /// @notice Used to define the MasterContract's type
    enum ContractType {
        lowRisk,
        mediumRisk,
        highRisk
    }

    /// @notice MasterContract address and type
    struct MasterContract {
        address location;
        ContractType risk;
    }

    function viewTotalDebt() external view returns (uint256);

    function computeTotalDebt() external returns (uint256 totalUsdoDebt);

    function mintOpenInterestDebt(address twTap) external;

    function bigBangMarkets() external view returns (address[] memory markets);

    function bigBangEthMarket() external view returns (address);

    function bigBangEthDebtRate() external view returns (uint256);

    function yieldBox() external view returns (address payable);

    function tapToken() external view returns (address);

    function tapAssetId() external view returns (uint256);

    function usdoToken() external view returns (address);

    function usdoAssetId() external view returns (uint256);

    function feeTo() external view returns (address);

    function mainToken() external view returns (address);

    function mainAssetId() external view returns (uint256);

    function isMarketRegistered(address market) external view returns (bool);

    function cluster() external view returns (ICluster);

    function pearlmit() external view returns (IPearlmit);

    function reAccrueBigBangMarkets() external;
}
