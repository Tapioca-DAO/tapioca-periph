// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {ISingularity} from "tapioca-periph/interfaces/bar/ISingularity.sol";

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

interface IMagnetarHelper {
    function getAmountForBorrowPart(address market, uint256 borrowPart, bool roundUp)
        external
        view
        returns (uint256 amount);

    function getBorrowPartForAmount(address market, uint256 amount, bool roundUp)
        external
        view
        returns (uint256 part);

    function getFractionForAmount(ISingularity singularity, uint256 amount, bool roundUp)
        external
        view
        returns (uint256 fraction);
}
