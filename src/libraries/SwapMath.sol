// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "./SqrtPriceMath.sol";
import "./FullMath.sol";
library SwapMath {
     uint256  constant FEE_PIPS = 3000;
    uint256  constant FEE_DENOMINATOR = 1_000_000;
    // PROCESS : INPUT TO OUTPUT
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
        uint256 amountInToTarget = SqrtPriceMath.getAmount1Delta(sqrtPriceCurrent, sqrtPriceTarget, liquidity );
        bool reachTarget;
       if(zeroForOne){
        reachTarget = amountRemaining >= amountInToTarget;
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
        reachTarget = amountRemaining >= amountInToTarget;

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
      
      // PROCESS: OUTPUT -> INPUT (exact output swap)
function computeSwapStepExactOutput(
    uint160 sqrtPriceCurrent,
    uint160 sqrtPriceTarget,
    uint128 liquidity,
    uint256 amountRemaining, // amount of OUTPUT token the user wants
    bool zeroForOne
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
    require(liquidity > 0, "NO_LIQUIDITY");
    uint256 maxOut = zeroForOne
        ? SqrtPriceMath.getAmount1Delta(sqrtPriceTarget, sqrtPriceCurrent, liquidity)
        : SqrtPriceMath.getAmount0Delta(sqrtPriceCurrent, sqrtPriceTarget, liquidity);

    bool reachTarget = amountRemaining >= maxOut;

    if (reachTarget) {
        // target reached — output capped at maxOut
        sqrtPriceNext = sqrtPriceTarget;
        amountOut = maxOut;
    } else {
        // target not reached — solve price for the exact amountRemaining output
        amountOut = amountRemaining;
        sqrtPriceNext = zeroForOne
            ? SqrtPriceMath.getNextSqrtPriceFromAmount1(sqrtPriceCurrent, liquidity, amountOut, false)
            : SqrtPriceMath.getNextSqrtPriceFromAmount0(sqrtPriceCurrent, liquidity, amountOut, false);
    }

    amountIn = zeroForOne
        ? SqrtPriceMath.getAmount0Delta(sqrtPriceNext, sqrtPriceCurrent, liquidity)
        : SqrtPriceMath.getAmount1Delta(sqrtPriceCurrent, sqrtPriceNext, liquidity);

    feeAmount = FullMath.mulDiv(amountIn, FEE_PIPS, FEE_DENOMINATOR - FEE_PIPS);
}

    }


