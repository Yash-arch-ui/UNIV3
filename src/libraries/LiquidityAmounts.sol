//SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;
import "./FixedPoint96.sol";
import "./FullMath.sol";

library LiquidityAmounts {
    function getLiquiditywrtAmount0(
        uint160 sqrtPriceA,
        uint160 sqrtPriceB,
        uint256 amount0
    ) internal pure returns (uint128 liquidity) {
        if (sqrtPriceA > sqrtPriceB) {
            (sqrtPriceA, sqrtPriceB) = (sqrtPriceB, sqrtPriceA);
        }
         require(sqrtPriceA != sqrtPriceB, "IDENTICAL_PRICES");
       uint256 intermediate = FullMath.mulDiv(uint256(sqrtPriceA), uint256(sqrtPriceB),FixedPoint96.Q96);
       liquidity= uint128(
        FullMath.mulDiv(amount0,intermediate, uint256(sqrtPriceB - sqrtPriceA))
       );
    }

    function getLiquidityForAmount1(
        uint160 sqrtPriceA,
        uint160 sqrtPriceB,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtPriceA > sqrtPriceB) {
            (sqrtPriceA, sqrtPriceB) = (sqrtPriceB, sqrtPriceA);
        }

         liquidity = uint128(
            FullMath.mulDiv(amount1,FixedPoint96.Q96,uint256(sqrtPriceB) - uint256(sqrtPriceA)
            ));
    }

        function getAmount0ForLiquidity(
        uint160 sqrtPriceA,
        uint160 sqrtPriceB,
        uint128 liquidity
    ) internal pure returns (uint256 amount0) {

        if (sqrtPriceA > sqrtPriceB) {
            (sqrtPriceA, sqrtPriceB) = (sqrtPriceB, sqrtPriceA);
        }

        require(sqrtPriceA != sqrtPriceB, "IDENTICAL_PRICES");

        uint256 intermediate = FullMath.mulDiv(  uint256(sqrtPriceA),  uint256(sqrtPriceB), FixedPoint96.Q96 );

        amount0 = FullMath.mulDiv( uint256(liquidity), uint256(sqrtPriceB) - uint256(sqrtPriceA), intermediate
        );
    }

    function getAmount1ForLiquidity(
        uint160 sqrtPriceA,
        uint160 sqrtPriceB,
        uint128 liquidity
    ) internal pure returns (uint256 amount1) {

        if (sqrtPriceA > sqrtPriceB) {
            (sqrtPriceA, sqrtPriceB) = (sqrtPriceB, sqrtPriceA);
        }

        require(sqrtPriceA != sqrtPriceB, "IDENTICAL_PRICES");

        amount1 = FullMath.mulDiv(uint256(liquidity),uint256(sqrtPriceB) - uint256(sqrtPriceA), FixedPoint96.Q96);
    }
}
