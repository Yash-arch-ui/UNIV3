// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "./SqrtPriceMath.sol";
import "./FullMath.sol";
library SwapMath {
    uint256 amountInToTarget;
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
       feeAmount = FullMath.mulDiv( amountIn,3,1000);
       uint256 amountInAfterFee= amountIn - feeAmount;
       if(zeroForOne){
        amountInToTarget=SqrtPriceMath.getAmount0Delta(sqrtPriceTarget, sqrtPriceCurrent, liquidity);\
        bool reachTarget = amountRemaining >= amountInToTarget;
        if(reachTarget)
        {
            sqrtPriceNext=sqrtPriceTarget;
        }
        else {
            amountIn= amountRemaining;
            sqrtPriceNext = SqrtPriceMath.getNextSqrtPriceFromInput(sqrtPriceCurrent, liquidity,amountIn, zeroForOne);
        }
        amountOut=SqrtPriceMath.getAmount1Delta(sqrtPriceNext, sqrtPriceCurrent, liquidity);
        sqrtPriceNext = SqrtPriceMath.getNextSqrtPriceFromAmount0(sqrtPriceCurrent,liquidity,amountInAfterFee);
        amountOut=SqrtPriceMath.getAmount1Delta(sqrtPriceNext, sqrtPriceCurrent, liquidity);

       }
       else{
        amountInToTarget = SqrtPriceMath.getAmount1Delta(sqrtPriceCurrent, sqrtPriceTarget, liquidity );
        bool reachTarget = amountRemaining >= amountInToTarget;

        if(reachTarget)
        {
            sqrtPriceNext=sqrtPriceTarget;
        }
        else {
            amountIn= amountRemaining;
            sqrtPriceNext = SqrtPriceMath.getNextSqrtPriceFromInput(sqrtPriceCurrent, liquidity,amountIn, zeroForOne);
        }
        amountOut=SqrtPriceMath.getAmount0Delta(sqrtPriceNext, sqrtPriceCurrent, liquidity);
       }


       
        return (sqrtPriceNext, amountIn, amountOut, feeAmount,zeroForOne);
    }
}
/* Currently what is happening in the swap step -> 
User given AmountRemaninig -> Use all of it -> Charge 0.3% fee -> Move directly to target tick 
*/