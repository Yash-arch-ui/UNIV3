// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./FullMath.sol";
import "./FixedPoint96.sol";
    uint256  constant Q96 = 0x1000000000000000000000000; 

library SqrtPriceMath {

    function getAmount0Delta( uint160 sqrtA, uint160 sqrtB, uint128 liquidity ) internal pure returns (uint256) {

        if (sqrtA > sqrtB) {
            (sqrtA, sqrtB) = (sqrtB, sqrtA);
        }

        uint256 numerator = FullMath.mulDiv(
            uint256(liquidity),
            FixedPoint96.Q96,
            1
        );

        return FullMath.mulDiv( numerator, uint256(sqrtB - sqrtA), uint256(sqrtB) * uint256(sqrtA) );
    }

    function getAmount1Delta( uint160 sqrtA, uint160 sqrtB, uint128 liquidity
    ) internal pure returns (uint256) {
                                                                 
        if (sqrtA > sqrtB) {
            (sqrtA, sqrtB) = (sqrtB, sqrtA);
        }
                      
        return FullMath.mulDiv(
            uint256(liquidity),
            uint256(sqrtB - sqrtA),
            FixedPoint96.Q96
        );
    }
                                            
    function getNextSqrtPriceFromAmount0( uint160 sqrtPrice, uint128 liquidity, uint256 amountIn
    ) internal pure returns (uint160) {

        uint256 product = FullMath.mulDiv(
            amountIn,
            sqrtPrice,
            FixedPoint96.Q96
        );

        return uint160(
            FullMath.mulDiv(
                liquidity,
                sqrtPrice,
                uint256(liquidity) + product
            )
        );
    }

    function getNextSqrtPriceFromAmount1(uint160 sqrtPrice,uint128 liquidity,uint256 amountIn
    ) internal pure returns (uint160) {

        return uint160(
            uint256(sqrtPrice) +
            FullMath.mulDiv(
                amountIn,
                FixedPoint96.Q96,
                liquidity
            )
        );
    }

    function getNextSqrtPriceFromInput(uint160 sqrtPriceCurrent, uint128 liquidity, uint256 amountIn, bool zeroForOne) internal pure returns(uint128)
    {
        if(zeroForOne){
             return uint128(getNextSqrtPriceFromAmount0(
            sqrtPriceCurrent,
            liquidity,
            amountIn
        ));

        }
        else {
        return uint128(getNextSqrtPriceFromAmount1(sqrtPriceCurrent, liquidity, amountIn));
        }
    }
     function getNextSqrtPriceFromOutput(
        uint160 sqrtPriceCurrent,
        uint128 liquidity,
        uint256 amount,
        bool zeroForOne
    ) internal pure returns (uint160 sqrtPriceNext) {

        require(sqrtPriceCurrent > 0, "ZERO_PRICE");
        require(liquidity > 0,        "ZERO_LIQUIDITY");

        if (zeroForOne) {
            // ─────────────────────────────────────────────────────
            // OUTPUT = token1   →   pool loses token1   →   price DOWN
            //
            //   sqrtP_new = sqrtP_current - (amount1 × 2^96) / L
            //
            // Round the quotient UP so sqrtP_new is slightly LOWER
            // → amountIn (token0) required is higher → pool protected
            // ─────────────────────────────────────────────────────

            uint256 quotient = FullMath.mulDivRoundingUp(
                amount,
                Q96,
                uint256(liquidity)
            );

            require(
                uint256(sqrtPriceCurrent) > quotient,
                "PRICE_UNDERFLOW" // amount1 too large for current price
            );

            sqrtPriceNext = uint160(uint256(sqrtPriceCurrent) - quotient);

        } else {
            // ─────────────────────────────────────────────────────
            // OUTPUT = token0   →   pool loses token0   →   price UP
            //
            //              L × 2^96 × sqrtP_current
            //   sqrtP_new = ─────────────────────────────────────
            //               L × 2^96  −  amount0 × sqrtP_current
            //
            // Round UP so sqrtP_new is slightly HIGHER
            // → amountIn (token1) required is higher → pool protected
            // ─────────────────────────────────────────────────────
            uint256 numerator1 = uint256(liquidity) << 96;

            // amount0 × sqrtP fits in uint256 in practice
            // because amount0 ≤ L/sqrtP, so amount0 × sqrtP ≤ L
            uint256 product = amount * uint256(sqrtPriceCurrent);
            require(
                product / uint256(sqrtPriceCurrent) == amount &&
                numerator1 > product,
                "PRICE_OVERFLOW"
            );

            uint256 denominator = numerator1 - product;

            // numerator = numerator1 × sqrtPriceCurrent (512-bit, handled by FullMath)
            sqrtPriceNext = uint160(
                FullMath.mulDivRoundingUp(
                    numerator1,
                    uint256(sqrtPriceCurrent),
                    denominator
                )
            );
        }
    }
}