// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {IPenrose} from "tapioca-periph/interfaces/bar/IPenrose.sol";

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

interface IBigBangDebtRateHelper {
    struct DebtRateCall {
        bool isMainMarket;
        IPenrose penrose;
        uint256 elastic;
        uint256 debtRateAgainstEthMarket;
        uint256 maxDebtRate;
        uint256 minDebtRate;
    }

    function getDebtRate(DebtRateCall memory data) external view returns (uint256);
}