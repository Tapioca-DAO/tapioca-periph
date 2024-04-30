// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {IMarket} from "./IMarket.sol";

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

interface IBigBang is IMarket {
    struct AccrueInfo {
        uint64 debtRate;
        uint64 lastAccrued;
    }

    function accrueInfo() external view returns (uint64 debtRate, uint64 lastAccrued);

    function minDebtRate() external view returns (uint256);

    function maxDebtRate() external view returns (uint256);

    function debtRateAgainstEthMarket() external view returns (uint256);

    function penrose() external view returns (address);

    function getDebtRate() external view returns (uint256);

    function getTotalDebt() external view returns (uint256);


    function computeOpenInterestMintable() external returns (uint256);

    function viewOpenInterest() external view returns (uint256);
}
