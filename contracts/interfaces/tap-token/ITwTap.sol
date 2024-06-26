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

interface ITwTap {
    struct Participation {
        uint256 averageMagnitude; // average magnitude of the pool at the time of locking.
        bool hasVotingPower;
        bool divergenceForce; // 0 negative, 1 positive
        bool tapReleased; // allow restaking while rewards may still accumulate
        uint56 lockedAt; // timestamp when lock was created. Since it's locked at block.timestamp, it's safe to say 56 bits will suffice
        uint56 expiry; // expiry timestamp. Big enough for over 2 billion years..
        uint88 tapAmount; // amount of TAP locked
        uint24 multiplier; // Votes = multiplier * tapAmount
        uint40 lastInactive; // One week BEFORE the staker gets a share of rewards
        uint40 lastActive; // Last week that the staker shares in rewards
    }

    function tapOFT() external view returns (address);
    function participate(address _participant, uint256 _amount, uint256 _duration) external returns (uint256 tokenId);
    function exitPosition(uint256 _tokenId) external returns (uint256 tapAmount_);
    function rewardTokenIndex(address token) external view returns (uint256);
    function distributeReward(uint256 _rewardTokenId, uint256 _amount) external;
    function getParticipation(uint256 _tokenId) external view returns (Participation memory participant);
}
