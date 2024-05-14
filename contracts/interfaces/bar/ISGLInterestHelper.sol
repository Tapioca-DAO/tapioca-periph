// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

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
