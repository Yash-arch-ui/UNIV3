// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title TickMath (Pure Solidity — No Assembly)
/// @notice Converts between ticks and sqrt price (Q96 fixed-point)
///
///   Price at a tick:     P = 1.0001^tick
///   Stored sqrt price:   sqrtPriceX96 = sqrt(P) × 2^96
///
/// Uses binary decomposition with precomputed Q128 magic constants
/// so the result is exact to the last bit across the full tick range.

library TickMath {
    // ──────────────────────────────────────────────────────
    //  Constants
    // ──────────────────────────────────────────────────────

    /// @dev Minimum tick supported (≈ price of 2.94e-39)
    int24 internal constant MIN_TICK = -887272;

    /// @dev Maximum tick supported (≈ price of 3.40e+38)
    int24 internal constant MAX_TICK = 887272;

    /// @dev Minimum sqrtPriceX96: getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;

    /// @dev Maximum sqrtPriceX96: getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    // ──────────────────────────────────────────────────────
    //  tick → sqrtPriceX96
    // ──────────────────────────────────────────────────────

    /// @notice Calculates sqrtPriceX96 = sqrt(1.0001^tick) × 2^96
    /// @dev Uses binary decomposition of |tick| into powers of 2.
    ///
    ///   1.0001^(tick/2) = product of  1.0001^(2^i)  for each set bit i
    ///
    ///   Each factor is a precomputed Q128 constant.
    ///   We multiply them together, then convert Q128 → Q96.
    ///
    /// @param tick  The tick value (int24, range: MIN_TICK to MAX_TICK)
    /// @return sqrtPriceX96  The sqrt price as a Q64.96 fixed-point number
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        // ── Step 1: Validate range ──────────────────────────
        require(tick >= MIN_TICK && tick <= MAX_TICK, "TICK_OOB");

        // Work with |tick| — we handle sign at the end
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));

        // ── Step 2: Start with 1.0 in Q128 ─────────────────
        // The magic constants below represent 1/sqrt(1.0001)^(2^i)
        // in Q128 format.  We start from ratio = 1.0 and multiply
        // in each factor whose bit is set in absTick.
        //
        // Why 1/sqrt(1.0001)?  Because the constants were derived
        // for negative ticks.  For positive ticks we invert at the end.

        // ── Step 3: Multiply in each power-of-two factor ────

        // Bit 0 (2^0 = 1):  factor = 1/sqrt(1.0001^1)
        // If bit 0 is set, start with the factor; otherwise start at 1.0 in Q128.
        uint256 ratio;
        if (absTick & 0x1 != 0) {
            ratio = 0xfffcb933bd6fad37aa2d162d1a594001;
        } else {
            ratio = 0x100000000000000000000000000000000; // 1.0 in Q128 (= 1 << 128)
        }

        // Bit 1 (2^1 = 2):  factor = 1/sqrt(1.0001^2)
        if (absTick & 0x2 != 0) {
            ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        }

        // Bit 2 (2^2 = 4):  factor = 1/sqrt(1.0001^4)
        if (absTick & 0x4 != 0) {
            ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        }

        // Bit 3 (2^3 = 8):  factor = 1/sqrt(1.0001^8)
        if (absTick & 0x8 != 0) {
            ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        }

        // Bit 4 (2^4 = 16):  factor = 1/sqrt(1.0001^16)
        if (absTick & 0x10 != 0) {
            ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        }

        // Bit 5 (2^5 = 32):  factor = 1/sqrt(1.0001^32)
        if (absTick & 0x20 != 0) {
            ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        }

        // Bit 6 (2^6 = 64):  factor = 1/sqrt(1.0001^64)
        if (absTick & 0x40 != 0) {
            ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        }

        // Bit 7 (2^7 = 128):  factor = 1/sqrt(1.0001^128)
        if (absTick & 0x80 != 0) {
            ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        }

        // Bit 8 (2^8 = 256):  factor = 1/sqrt(1.0001^256)
        if (absTick & 0x100 != 0) {
            ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        }

        // Bit 9 (2^9 = 512):  factor = 1/sqrt(1.0001^512)
        if (absTick & 0x200 != 0) {
            ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        }

        // Bit 10 (2^10 = 1024):  factor = 1/sqrt(1.0001^1024)
        if (absTick & 0x400 != 0) {
            ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        }

        // Bit 11 (2^11 = 2048):  factor = 1/sqrt(1.0001^2048)
        if (absTick & 0x800 != 0) {
            ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        }

        // Bit 12 (2^12 = 4096):  factor = 1/sqrt(1.0001^4096)
        if (absTick & 0x1000 != 0) {
            ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        }

        // Bit 13 (2^13 = 8192):  factor = 1/sqrt(1.0001^8192)
        if (absTick & 0x2000 != 0) {
            ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        }

        // Bit 14 (2^14 = 16384):  factor = 1/sqrt(1.0001^16384)
        if (absTick & 0x4000 != 0) {
            ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        }

        // Bit 15 (2^15 = 32768):  factor = 1/sqrt(1.0001^32768)
        if (absTick & 0x8000 != 0) {
            ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        }

        // Bit 16 (2^16 = 65536):  factor = 1/sqrt(1.0001^65536)
        if (absTick & 0x10000 != 0) {
            ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        }

        // Bit 17 (2^17 = 131072):  factor = 1/sqrt(1.0001^131072)
        if (absTick & 0x20000 != 0) {
            ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        }

        // Bit 18 (2^18 = 262144):  factor = 1/sqrt(1.0001^262144)
        if (absTick & 0x40000 != 0) {
            ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        }

        // Bit 19 (2^19 = 524288):  factor = 1/sqrt(1.0001^524288)
        if (absTick & 0x80000 != 0) {
            ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;
        }

        // ── Step 4: Handle positive ticks by inverting ──────
        // The constants above computed 1/sqrt(1.0001^|tick|).
        // For negative ticks, that IS the answer (price < 1).
        // For positive ticks, we need sqrt(1.0001^tick),
        // so we invert: ratio = type(uint256).max / ratio.

        if (tick > 0) {
            ratio = type(uint256).max / ratio;
        }

        // ── Step 5: Convert Q128 → Q96 (shift right by 32) ─
        // Add 1 if there's a remainder (round up to protect pool)

        sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }

    // ──────────────────────────────────────────────────────
    //  sqrtPriceX96 → tick
    // ──────────────────────────────────────────────────────

    /// @notice Calculates the greatest tick where getSqrtRatioAtTick(tick) ≤ sqrtPriceX96
    /// @dev Uses a log-base-2 approach:
    ///
    ///   tick = log_{1.0001}(P) = log_{1.0001}(sqrtP²)
    ///        = 2 × log_{1.0001}(sqrtP)
    ///        = 2 × log2(sqrtP) / log2(1.0001)
    ///
    ///   We compute log2(sqrtPriceX96 / 2^96) in Q64 using
    ///   MSB binary search + repeated squaring for fractional bits,
    ///   then scale by the constant 1 / log2(sqrt(1.0001)).
    ///
    /// @param sqrtPriceX96  The sqrt price as a Q64.96 value
    /// @return tick  The greatest tick whose price ≤ sqrtPriceX96
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        // ── Step 1: Validate range ──────────────────────────
        require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, "SQRT_OOB");

        // ── Step 2: Compute integer part of log2 ───────────
        // Find the most significant bit (MSB) via binary search.

        uint256 ratio = uint256(sqrtPriceX96) << 32; // Q96 → Q128

        uint256 r = ratio;
        uint256 msb = 0;

        // Check if r > 2^128 - 1  (i.e., bit 128+ is set)
        uint256 f;

        f = r > 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF ? 1 : 0;
        f = f << 7; // f = 128 if bit is set, else 0
        msb = msb | f;
        r = r >> f;

        f = r > 0xFFFFFFFFFFFFFFFF ? 1 : 0;
        f = f << 6; // f = 64 if set
        msb = msb | f;
        r = r >> f;

        f = r > 0xFFFFFFFF ? 1 : 0;
        f = f << 5; // f = 32 if set
        msb = msb | f;
        r = r >> f;

        f = r > 0xFFFF ? 1 : 0;
        f = f << 4; // f = 16 if set
        msb = msb | f;
        r = r >> f;

        f = r > 0xFF ? 1 : 0;
        f = f << 3; // f = 8 if set
        msb = msb | f;
        r = r >> f;

        f = r > 0xF ? 1 : 0;
        f = f << 2; // f = 4 if set
        msb = msb | f;
        r = r >> f;

        f = r > 0x3 ? 1 : 0;
        f = f << 1; // f = 2 if set
        msb = msb | f;
        r = r >> f;

        f = r > 0x1 ? 1 : 0;
        msb = msb | f;

        // ── Step 3: Compute fractional part of log2 ────────
        // Normalize ratio so MSB is at bit 127, then
        // square-and-check 14 times to get 14 fractional bits.

        int256 log_2;

        if (msb >= 128) {
            r = ratio >> (msb - 127);
        } else {
            r = ratio << (127 - msb);
        }

        log_2 = (int256(msb) - 128) << 64; // integer part in Q64

        // Each iteration: square r (Q127 × Q127 = Q254, shift right 127 → Q127)
        // If the result has bit 128 set, that fractional bit is 1.
        // 14 iterations → 14 fractional bits of precision.

        // Fractional bit 1 (weight = 2^63 in Q64)
        r = (r * r) >> 127;
        f = r >> 128;
        log_2 = log_2 | int256(f << 63);
        r = r >> f;

        // Fractional bit 2 (weight = 2^62)
        r = (r * r) >> 127;
        f = r >> 128;
        log_2 = log_2 | int256(f << 62);
        r = r >> f;

        // Fractional bit 3 (weight = 2^61)
        r = (r * r) >> 127;
        f = r >> 128;
        log_2 = log_2 | int256(f << 61);
        r = r >> f;

        // Fractional bit 4 (weight = 2^60)
        r = (r * r) >> 127;
        f = r >> 128;
        log_2 = log_2 | int256(f << 60);
        r = r >> f;

        // Fractional bit 5 (weight = 2^59)
        r = (r * r) >> 127;
        f = r >> 128;
        log_2 = log_2 | int256(f << 59);
        r = r >> f;

        // Fractional bit 6 (weight = 2^58)
        r = (r * r) >> 127;
        f = r >> 128;
        log_2 = log_2 | int256(f << 58);
        r = r >> f;

        // Fractional bit 7 (weight = 2^57)
        r = (r * r) >> 127;
        f = r >> 128;
        log_2 = log_2 | int256(f << 57);
        r = r >> f;

        // Fractional bit 8 (weight = 2^56)
        r = (r * r) >> 127;
        f = r >> 128;
        log_2 = log_2 | int256(f << 56);
        r = r >> f;

        // Fractional bit 9 (weight = 2^55)
        r = (r * r) >> 127;
        f = r >> 128;
        log_2 = log_2 | int256(f << 55);
        r = r >> f;

        // Fractional bit 10 (weight = 2^54)
        r = (r * r) >> 127;
        f = r >> 128;
        log_2 = log_2 | int256(f << 54);
        r = r >> f;

        // Fractional bit 11 (weight = 2^53)
        r = (r * r) >> 127;
        f = r >> 128;
        log_2 = log_2 | int256(f << 53);
        r = r >> f;

        // Fractional bit 12 (weight = 2^52)
        r = (r * r) >> 127;
        f = r >> 128;
        log_2 = log_2 | int256(f << 52);
        r = r >> f;

        // Fractional bit 13 (weight = 2^51)
        r = (r * r) >> 127;
        f = r >> 128;
        log_2 = log_2 | int256(f << 51);
        r = r >> f;

        // Fractional bit 14 (weight = 2^50)
        r = (r * r) >> 127;
        f = r >> 128;
        log_2 = log_2 | int256(f << 50);
        // No need to shift r further — last iteration

        // ── Step 4: Convert log2 → tick ─────────────────────
        //
        //   tick = log2(sqrtP) × 2 / log2(1.0001)
        //        = log2(sqrtP) / log2(sqrt(1.0001))
        //
        //   The magic constant below = 1 / log2(sqrt(1.0001)) in Q64
        //   = 255738958999603826347141

        int256 log_sqrt10001 = log_2 * 255738958999603826347141;

        // ── Step 5: Round down to the greatest valid tick ────
        // We compute a lower and upper bound tick, then pick
        // the largest tick whose sqrtPrice ≤ the input.

        int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
        int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

        // If both bounds agree, that's our tick.
        // Otherwise, check whether tickHi's price is ≤ input.
        tick = tickLow == tickHi ? tickLow : (getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow);
    }
}
