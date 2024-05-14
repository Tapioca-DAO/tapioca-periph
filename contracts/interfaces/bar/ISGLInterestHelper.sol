// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {RebaseLibrary, Rebase} from "@boringcrypto/boring-solidity/contracts/libraries/BoringRebase.sol";

// Tapioca
import {IYieldBox} from "tapioca-periph/interfaces/yieldbox/IYieldBox.sol";
import {ISingularity, IMarket} from "tapioca-periph/interfaces/bar/ISingularity.sol";

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

interface ISGLInterestHelper {
    struct InterestRateCall {
        IYieldBox yieldBox;
        ISingularity.AccrueInfo accrueInfo;
        uint256 assetId;
        Rebase totalAsset;
        Rebase totalBorrow;
        uint256 protocolFee;
        uint256 interestElasticity;
        uint256 minimumTargetUtilization;
        uint256 maximumTargetUtilization;
        uint64 minimumInterestPerSecond;
        uint64 maximumInterestPerSecond;
        uint64 startingInterestPerSecond;
    }

    function getInterestRate(InterestRateCall memory data)
        external
        view
        returns (
            ISingularity.AccrueInfo memory _accrueInfo,
            Rebase memory _totalBorrow,
            Rebase memory _totalAsset,
            uint256 extraAmount,
            uint256 feeFraction,
            uint256 utilization
        );
}
