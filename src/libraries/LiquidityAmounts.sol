//SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;
import "./FixedPoint96.sol";
import "./FullMath.sol";

library LiquidityAmounts {
    function getLiquidityForAmount0(uint160 sqrtPriceA, uint160 sqrtPriceB, uint256 amount0)
        internal
        pure
        returns (uint128 liquidity)
    {
        // how much liquidity L is generated when a u ser deposits a specific amount of token0(amount0) into a specific price range defined by two square root prices(sqrtPriceA ) and sqrtPrice(B)
        if (sqrtPriceA > sqrtPriceB) {
            (sqrtPriceA, sqrtPriceB) = (sqrtPriceB, sqrtPriceA);
        }
        require(sqrtPriceA != sqrtPriceB, "IDENTICAL_PRICES");
        uint256 intermediate = FullMath.mulDiv(uint256(sqrtPriceA), uint256(sqrtPriceB), FixedPoint96.Q96);
        liquidity = uint128(FullMath.mulDiv(amount0, intermediate, uint256(sqrtPriceB - sqrtPriceA)));
        /*
            L = delta (X)(root Pa * root Pb)/ (root Pb - root Pa);
        */
    }

    function getLiquidityForAmount1(uint160 sqrtPriceA, uint160 sqrtPriceB, uint256 amount1)
        internal
        pure
        returns (uint128 liquidity)
    {
        if (sqrtPriceA > sqrtPriceB) {
            (sqrtPriceA, sqrtPriceB) = (sqrtPriceB, sqrtPriceA);
        }

        liquidity = uint128(FullMath.mulDiv(amount1, FixedPoint96.Q96, uint256(sqrtPriceB) - uint256(sqrtPriceA)));
        // L= delta y *(root pb - root Pa)
    }

    function getAmount0ForLiquidity(uint160 sqrtPriceA, uint160 sqrtPriceB, uint128 liquidity)
        internal
        pure
        returns (uint256 amount0)
    {
        /*
        , this one calculates how much token0 (amount0) is required to create a
         target amount of liquidity between two
        specific price bounds (sqrtPriceA and sqrtPriceB).
        */
        if (sqrtPriceA > sqrtPriceB) {
            (sqrtPriceA, sqrtPriceB) = (sqrtPriceB, sqrtPriceA);
        }

        require(sqrtPriceA != sqrtPriceB, "IDENTICAL_PRICES");

        uint256 intermediate = FullMath.mulDiv(uint256(sqrtPriceA), uint256(sqrtPriceB), FixedPoint96.Q96);

        amount0 = FullMath.mulDiv(uint256(liquidity), uint256(sqrtPriceB) - uint256(sqrtPriceA), intermediate);
    }

    function getAmount1ForLiquidity(uint160 sqrtPriceA, uint160 sqrtPriceB, uint128 liquidity)
        internal
        pure
        returns (uint256 amount1)
    {
        if (sqrtPriceA > sqrtPriceB) {
            (sqrtPriceA, sqrtPriceB) = (sqrtPriceB, sqrtPriceA);
        }

        require(sqrtPriceA != sqrtPriceB, "IDENTICAL_PRICES");

        amount1 = FullMath.mulDiv(uint256(liquidity), uint256(sqrtPriceB) - uint256(sqrtPriceA), FixedPoint96.Q96);
    }
}
