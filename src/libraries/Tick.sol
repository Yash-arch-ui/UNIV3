// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library Tick {
    struct TickInfo {
        uint128 liquidityGross;
        int128 liquidityNet;

        uint256 feeGrowthOutside0;
        uint256 feeGrowthOutside1;
    }
}