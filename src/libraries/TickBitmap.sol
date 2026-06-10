//SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;
library TickBitmap {

    struct Bitmap{
        mapping(int16 => uint256 ) words;
    }
    function positions(int24 tick) internal pure returns(int16 wordPos, uint8 bitPos){
        wordPos= int16(tick>>8);
        bitPos=uint8(uint24(tick %256));
    }
    function flipTick(Bitmap storage self,int24 tick)
    internal
{
    (int16 wordPos, uint8 bitPos)
        = positions(tick);

    self.words[wordPos] ^= (
        uint256(1) << bitPos
    );
}
function isInitialized(
    Bitmap storage self,
    int24 tick
)
    internal
    view
    returns(bool)
{
    (int16 wordPos, uint8 bitPos)
        = positions(tick);

    return (
        self.words[wordPos]
        &
        (uint256(1) << bitPos)
    ) != 0;
}
}