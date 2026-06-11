// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "./SqrtPriceMath.sol";
import "./FullMath.sol";
library SwapMath {

    function computeSwapStep(
        uint160 sqrtPriceCurrent,
        uint160 sqrtPriceTarget,
        uint128 liquidity,
        uint256 amountRemaining,
        bool zeroForOne
    )
        internal
        pure
        returns (
            uint160 sqrtPriceNext,
            uint256 amountIn,
            uint256 amountOut,
            uint256 feeAmount,
            bool decision
        )
    {  
        require(liquidity >0 , "NO_LIQUIDITY");
       amountIn= amountRemaining > 100 ? 100 : amountRemaining;
       feeAmount = FullMath.mulDiv( amountIn,3,1000);
       uint256 amountInAfterFee= amountIn - feeAmount;
       if(zeroForOne){
        sqrtPriceNext = SqrtPriceMath.getNextSqrtPriceFromAmount0(sqrtPriceCurrent,liquidity,amountInAfterFee);
        amountOut=SqrtPriceMath.getAmount1Delta(sqrtPriceNext, sqrtPriceCurrent, liquidity);

       }
       else{
        sqrtPriceNext= SqrtPriceMath.getNextSqrtPriceFromAmount1(sqrtPriceCurrent,liquidity,amountInAfterFee);
        amountOut=SqrtPriceMath.getAmount1Delta(sqrtPriceNext, sqrtPriceCurrent, liquidity);

       }

        if (zeroForOne && sqrtPriceNext < sqrtPriceTarget) {
            sqrtPriceNext = sqrtPriceTarget;
        }

        if (!zeroForOne && sqrtPriceNext > sqrtPriceTarget) {
            sqrtPriceNext = sqrtPriceTarget;
        }

       
        return (sqrtPriceNext, amountIn, amountOut, feeAmount,zeroForOne);
    }
}
/* Currently what is happening in the swap step -> 
User given AmountRemaninig -> Use all of it -> Charge 0.3% fee -> Move directly to target tick 
*/