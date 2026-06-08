// P= (1.0001)^tick
// sqrtPriceX96 = sqrt(P)*2^96

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;
library TickMath{
    uint160 internal contstant Q96=79228162514264337593543950336;
    function getSqrtRatioAtTick(int24 tick) internal pure returns(uint160){
     uint160 step = Q96/10000;
     if(tick>=0){
        return Q96 + uint160(int160(tick))*step;

     }
     return Q96- uint160(int160(-tick))*step;

    }
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns(int24){
       uint160 step=Q96 /10000;
       if(sqrtPriceX96>= Q96){
        return int24(int256(uint256(sqrtPriceX96 - Q96)/step));
             }   
             return -int24(int256(uint256(Q96 - sqrtPriceX96)/step));  
              }
    }
