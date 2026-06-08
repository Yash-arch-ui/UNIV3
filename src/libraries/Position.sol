// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library Position {
    struct PositionInfo {
        int24 tickLower;
        int24 tickUpper;
        uint128 liquidity;
    }
}