//SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;

interface ICLAMMPool{
    function getFeeGrowthGlobals() 
    external view returns (uint256, uint256);

    function modifyPosition(int24 tickLower, int24 tickUpper, int128 liquidityDelta) external;
    function getFreeGrowthInside(int24 tickLower, itn24 tickUpper) external view returns(uint256 feeInside0, uint256 feeInside1);
}