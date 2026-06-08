//SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;
library LiquidityMath{
    function addLiquidity(uint128 liquidity, int128 liquidityDelta) internal pure returns(uint128)
    {
        if(liquidityDelta>0){
        return liquidity + uint128(liquidityDelta);
        }
        return liquidity - uint128(-liquidityDelta);
    }
}