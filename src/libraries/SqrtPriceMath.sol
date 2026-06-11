// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./FullMath.sol";
import "./FixedPoint96.sol";

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
             return getNextSqrtPriceFromAmount0(
            sqrtPriceCurrent,
            liquidity,
            amountIn
        );

        }
        return getNextSqrtPriceFromAmount1(sqrtPriceCurrent, liquidity, amountIn);
    }
}