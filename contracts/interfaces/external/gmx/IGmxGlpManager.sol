// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

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

interface IGmxGlpManager {
    event AddLiquidity(
        address indexed account,
        address indexed token,
        uint256 indexed amount,
        uint256 aumInUsdg,
        uint256 glpSupply,
        uint256 usdgAmount,
        uint256 mintAmount
    );
    event RemoveLiquidity(
        address indexed account,
        address indexed token,
        uint256 indexed glpAmount,
        uint256 aumInUsdg,
        uint256 glpSupply,
        uint256 usdgAmount,
        uint256 amountOut
    );

    function BASIS_POINTS_DIVISOR() external view returns (uint256);

    function GLP_PRECISION() external view returns (uint256);

    function MAX_COOLDOWN_DURATION() external view returns (uint256);

    function PRICE_PRECISION() external view returns (uint256);

    function USDG_DECIMALS() external view returns (uint256);

    function addLiquidity(address _token, uint256 _amount, uint256 _minUsdg, uint256 _minGlp)
        external
        returns (uint256);

    function addLiquidityForAccount(
        address _fundingAccount,
        address _account,
        address _token,
        uint256 _amount,
        uint256 _minUsdg,
        uint256 _minGlp
    ) external returns (uint256);

    function aumAddition() external view returns (uint256);

    function aumDeduction() external view returns (uint256);

    function cooldownDuration() external view returns (uint256);

    function getAum(bool maximise) external view returns (uint256);

    function getAumInUsdg(bool maximise) external view returns (uint256);

    function getAums() external view returns (uint256[] memory);

    function getGlobalShortAveragePrice(address _token) external view returns (uint256);

    function getGlobalShortDelta(address _token, uint256 _price, uint256 _size) external view returns (uint256, bool);

    function getPrice(bool _maximise) external view returns (uint256);

    function glp() external view returns (address);

    function gov() external view returns (address);

    function inPrivateMode() external view returns (bool);

    function isHandler(address) external view returns (bool);

    function lastAddedAt(address) external view returns (uint256);

    function removeLiquidity(address _tokenOut, uint256 _glpAmount, uint256 _minOut, address _receiver)
        external
        returns (uint256);

    function removeLiquidityForAccount(
        address _account,
        address _tokenOut,
        uint256 _glpAmount,
        uint256 _minOut,
        address _receiver
    ) external returns (uint256);

    function setAumAdjustment(uint256 _aumAddition, uint256 _aumDeduction) external;

    function setCooldownDuration(uint256 _cooldownDuration) external;

    function setGov(address _gov) external;

    function setHandler(address _handler, bool _isActive) external;

    function setInPrivateMode(bool _inPrivateMode) external;

    function setShortsTracker(address _shortsTracker) external;

    function setShortsTrackerAveragePriceWeight(uint256 _shortsTrackerAveragePriceWeight) external;

    function shortsTracker() external view returns (address);

    function shortsTrackerAveragePriceWeight() external view returns (uint256);

    function usdg() external view returns (address);

    function vault() external view returns (address);
}
