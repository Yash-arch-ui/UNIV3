//SPDX-License-identifier:MIT
pragma solidity ^0.8.19;
interface IPositionManager{
    function mint(address owner, int24 tickUpper, int24 tickLower, uint128 liquidity) external; 
}