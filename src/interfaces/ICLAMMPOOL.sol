//SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;

interface ICLAMMPool{
    function getFeeGrowthGlobals() external view returns (uint256, uint256);

    function modifyPosition(int24 tickLower, int24 tickUpper, int128 liquidityDelta) external;
    function getFeeGrowthInside(int24 tickLower, int24 tickUpper) external view returns(uint256 feeInside0, uint256 feeInside1);
    function swap(bool zeroForOne, uint256 amountSpecified) external;
    function sqrtPriceX96() external view returns(uint160);
    function liquidity() external view returns(uint128);
    function collect() external view returns(uint256, uint256);
    function currentTick() external view returns(int24);
    function getCurrentState() external view returns(uint160, int24, uint128);

}