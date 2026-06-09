// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library Position {
    struct PositionInfo {
        int24 tickLower;
        int24 tickUpper;
        uint128 liquidity;
        uint256 feeGrowthInside0Last;
        uint256 feeGrowthInside1Last;


        uint256 tokensOwed0;
        uint256 tokensOwed1;
    }
}