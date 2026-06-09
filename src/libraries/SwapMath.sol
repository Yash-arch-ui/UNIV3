// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library SwapMath {

    function computeSwapStep(
        uint160 sqrtPriceCurrent,
        uint160 sqrtPriceTarget,
        uint128 liquidity,
        uint256 amountRemaining
    )
        internal
        pure
        returns (
            uint160 sqrtPriceNext,
            uint256 amountIn,
            uint256 amountOut,
            uint256 feeAmount
        )
    {
       sqrtPriceNext=sqrtPriceTarget;
       amountIn= amountRemaining > 100 ? 100 : amountRemaining;
       feeAmount = (amountIn * 3) / 1000;
       amountOut= amountIn - feeAmount;
  

       return (sqrtPriceNext, amountIn, amountOut, feeAmount);
    }
}
/* Currently what is happening in the swap step -> 
User given AmountRemaninig -> Use all of it -> Charge 0.3% fee -> Move directly to target tick 
*/