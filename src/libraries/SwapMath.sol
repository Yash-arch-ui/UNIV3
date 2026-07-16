// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./SqrtPriceMath.sol";
import "./FullMath.sol";

library SwapMath {
    uint256 constant FEE_PIPS        = 3_000;
    uint256 constant FEE_DENOMINATOR = 1_000_000;

    // ─────────────────────────────────────────────────────────────────────────
    // PROCESS: INPUT → OUTPUT  (exact-input swap)
    //
    // Convention used throughout this function:
    //   amountIn   = post-fee amount that actually moves into the liquidity pool
    //   feeAmount  = fee charged on top of amountIn
    //   user pays  = amountIn + feeAmount  (≤ amountRemaining)
    //
    // Return values
    //   sqrtPriceNext  – price after this step
    //   amountIn       – net input consumed by the pool (post-fee)
    //   amountOut      – output produced by the pool
    //   feeAmount      – fee collected
    // ─────────────────────────────────────────────────────────────────────────
    function computeSwapStep(
        uint160 sqrtPriceCurrent,
        uint160 sqrtPriceTarget,
        uint128 liquidity,
        uint256 amountRemaining,   // gross input provided by the caller
        bool    zeroForOne
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
        if (zeroForOne) {
            require(sqrtPriceTarget < sqrtPriceCurrent, "INVALID_TARGET");
        } else {
            require(sqrtPriceTarget > sqrtPriceCurrent, "INVALID_TARGET");
        }

        // ── Step 1: how much usable (post-fee) input do we have? ─────────────
        uint256 amountRemainingLessFee = FullMath.mulDiv(
            amountRemaining,
            FEE_DENOMINATOR - FEE_PIPS,
            FEE_DENOMINATOR
        );
        // ── Step 2: how much net input is needed to reach the target price? ──
        uint256 amountInToTarget = zeroForOne
            ? SqrtPriceMath.getAmount0Delta(sqrtPriceTarget, sqrtPriceCurrent, liquidity)
            : SqrtPriceMath.getAmount1Delta(sqrtPriceCurrent, sqrtPriceTarget, liquidity);

        // ── Step 3: decide whether the target price is reached ───────────────
        bool reachTarget = amountRemainingLessFee >= amountInToTarget;

        if (reachTarget) {
            sqrtPriceNext = sqrtPriceTarget;
            amountIn      = amountInToTarget;

            // Fee on a "known-net" amount → gross = net * D / (D - F)  →  fee = net * F / (D - F)
            // Round UP to protect the pool.
            feeAmount = FullMath.mulDivRoundingUp(
                amountIn,
                FEE_PIPS,
                FEE_DENOMINATOR - FEE_PIPS
            );
        } else {
            // Partial step: all usable input is spent, target is NOT reached.
            amountIn = amountRemainingLessFee;

            // Derive the price that amountIn (post-fee) can actually reach.
            sqrtPriceNext = SqrtPriceMath.getNextSqrtPriceFromInput(
                sqrtPriceCurrent,
                liquidity,
                amountIn,
                zeroForOne
            );

            feeAmount = amountRemainingLessFee - amountIn;
        }

        amountOut = zeroForOne
            ? SqrtPriceMath.getAmount1Delta(sqrtPriceNext, sqrtPriceCurrent, liquidity)
            : SqrtPriceMath.getAmount0Delta(sqrtPriceCurrent, sqrtPriceNext, liquidity);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PROCESS: OUTPUT → INPUT  (exact-output swap)
    //
    // Convention used throughout this function:
    //   amountIn   = net input that moves into the pool (post-fee)
    //   feeAmount  = fee charged on top of amountIn
    //   user pays  = amountIn + feeAmount
    //
    // Return values
    //   sqrtPriceNext  – price after this step
    //   amountIn       – net input consumed by the pool (post-fee)
    //   amountOut      – output produced (≤ amountRemaining)
    //   feeAmount      – fee collected (rounds UP to protect the pool)
    // ─────────────────────────────────────────────────────────────────────────
    function computeSwapStepExactOutput(
        uint160 sqrtPriceCurrent,
        uint160 sqrtPriceTarget,
        uint128 liquidity,
        uint256 amountRemaining,   // desired output amount
        bool    zeroForOne
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
        // ── Guard ────────────────────────────────────────────────────────────
        require(liquidity > 0, "NO_LIQUIDITY");

        if (zeroForOne) {
            require(sqrtPriceTarget < sqrtPriceCurrent, "INVALID_TARGET");
        } else {
            require(sqrtPriceTarget > sqrtPriceCurrent, "INVALID_TARGET");
        }
        uint256 maxOut = zeroForOne
            ? SqrtPriceMath.getAmount1Delta(sqrtPriceTarget, sqrtPriceCurrent, liquidity)
            : SqrtPriceMath.getAmount0Delta(sqrtPriceCurrent, sqrtPriceTarget, liquidity);

        // ── Step 2: decide whether the target price is reached ───────────────
        bool reachTarget = amountRemaining >= maxOut;

        if (reachTarget) {
            // Enough output desired to push all the way to the target price.
            sqrtPriceNext = sqrtPriceTarget;
            amountOut     = maxOut;
        } else {
            amountOut = amountRemaining;
            sqrtPriceNext = SqrtPriceMath.getNextSqrtPriceFromInput(
                sqrtPriceCurrent,
                liquidity,
                amountOut,
                zeroForOne
            );
        }
        amountIn = zeroForOne
            ? SqrtPriceMath.getAmount0Delta(sqrtPriceNext, sqrtPriceCurrent, liquidity)
            : SqrtPriceMath.getAmount1Delta(sqrtPriceCurrent, sqrtPriceNext, liquidity);
        feeAmount = FullMath.mulDivRoundingUp(
            amountIn,
            FEE_PIPS,
            FEE_DENOMINATOR - FEE_PIPS
        );
    }
}