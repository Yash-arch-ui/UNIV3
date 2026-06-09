//SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;

interface ICLAMMPool{
    function getFeeGrowthGlobals() 
    external view returns (uint256, uint256);

}