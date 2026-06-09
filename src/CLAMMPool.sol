// Pool is responsible for current price current tick current liquidity swaps tick crossing fee accounting 
//SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;
import "./libraries/Tick.sol";
contract CLAMMPool{
    address public token0;
    address public token1;
    address public _positionManager;

    uint160 public sqrtPriceX96;
    int24 public currentTick;
    uint128 public liquidity;

    mapping(int24 => Tick.TickInfo) public ticks;

    event PositionUpdated(address indexed owner, int24 tickLower, int24 tickUpper,int128 liquidityDelta);

    constructor(address _token0, address _token1, uint160 _sqrtPriceX96, address positionManager) {
        token0 = _token0;
        token1 = _token1;
        sqrtPriceX96 = _sqrtPriceX96;
        currentTick = 0;
        positionManager = _positionManager;
    }
    modifier onlyPositionManager(){
        require(msg.sender == positionManager,"ONLY BY POS MANAGER");
        _;
    }

    function modifyPosition(int24 tickLower, int24 tickUpper, uint128 liquidityDelta) external onlyPositionManager {
// increase pool liquiidty should not be doneby anyone 
         ticks[tickLower].liquidityGross += liquidityDelta;
         ticks[tickLower].liquidityNet += int128(liquidityDelta);
         ticks[tickUpper].liquidityGross += liquidityDelta;
         ticks[tickUpper].liquidityNet -= int128(liquidityDelta);
         if(currentTick >= tickLower && currentTick < tickUpper){
            liquidity += liquidityDelta;
         }
         emit PositionUpdated(msg.sender, tickLower, tickUpper, int128(liquidityDelta));

    }

    function crossTick(int24 tick) public {
        // whenever crosses tick just inclrease the liquidity by liquidityNet of the tick
        int128 liquidityNet= ticks[tick].liquidityNet;
        liquidity = LiquidityMath.addLiquidity(liquidity, liquidityNet);
        currentTick= tick;
    }

    function swap( bool zeroForOne, uint256 amountSpecified) external{
        uint256 amountRemaining = amountSpecified;
        while(amountRemaining>0){
            int24 nextTick= getNextTick(zeroForOne);
            uint160 sqrtPriceTarget= TickMath.getSqrtRatioAtTick(nextTick);
            (uint160 sqrtPriceNext,
            uint256 amountIn,
            uint256 amountOut,
            uint256 feeAmount) = SwapMath.computeSwapStep(
                sqrtPriceX96,
                sqrtPriceTarget, 
                liquidity,
                amountRemaining
            );
            sqrtPriceX96= sqrtPriceNext;
            amountRemaining -= amountIn;

            if(sqrtPriceX96== sqrtPriceTarget){
                crossTick(nextTick);
                currentTick= nextTick;
            }
            break; // For simplicity, we break after one step. In a complete implementation, we would loop until the entire amount is swapped.
        }
    }

    function getNextTick( bool zeroForOne) internal view returns(int24){
        if(zeroForOne)
        return currentTick-100;

        return currentTick+100;
    }
}
