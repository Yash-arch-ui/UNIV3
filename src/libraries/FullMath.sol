// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library FullMath {

    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    )
        internal
        pure
        returns(uint256)
    {
        return (a * b) / denominator;
    }
}