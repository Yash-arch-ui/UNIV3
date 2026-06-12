// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library TickBitmap {

    struct Bitmap {

        mapping(int16 => uint256) words;
    }

    function position( int24 tick)  internal pure returns ( int16 wordPos, uint8 bitPos)
    {
        wordPos = int16(tick >> 8);
        bitPos = uint8(uint24(tick & 255));
    }

    function flipTick( Bitmap storage self, int24 tick )  internal
    {
        (int16 wordPos, uint8 bitPos) =
            position(tick);

        self.words[wordPos] ^=
            (uint256(1) << bitPos);
    }

    function isInitialized( Bitmap storage self,int24 tick
    )internal view returns (bool)
    {
        (int16 wordPos, uint8 bitPos) = position(tick);

        return
            (
                self.words[wordPos]  &  (uint256(1) << bitPos)
            ) != 0;
    }

    function nextInitializedTick( Bitmap storage self, int24 tick, bool lte )  internal  view  returns ( int24 next, bool initialized )
    {
        (int16 wordPos, uint8 bitPos) =position(tick);

        uint256 word =  self.words[wordPos];

        if (lte) {

            for (
                uint256 i = bitPos + 1; i < 256; i++) {
                if (
                    word &
                    (uint256(1) << i)
                    != 0
                ) {
                    return (
                        (int24(wordPos) << 8) + int24(uint24(i)),true  );
                }
            }

        } else {

            for (
                uint256 i = bitPos;  i > 0;  i--
            ) {
                if (
                    word &(uint256(1) << (i - 1))!= 0
                ) {
                    return ((int24(wordPos) << 8) + int24(uint24(i - 1)), true
                    );
                }
            }
        }

        return (tick, false);
    }
}