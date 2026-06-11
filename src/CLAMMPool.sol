// Pool is responsible for current price current tick current liquidity swaps tick crossing fee accounting 
//SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;
import "./libraries/Tick.sol";
import "./libraries/LiquidityMath.sol";
import "./libraries/TickMath.sol";
import "./libraries/SwapMath.sol";
import "./Oracle.sol";
import "./libraries/FullMath.sol";
import "./libraries/TickBitmap.sol";
import "./interfaces/IFlashCallback.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CLAMMPool{
    using TickBitmap for TickBitmap.Bitmap;
    TickBitmap.Bitmap internal bitmap;

    address public token0;
    address public token1;
    address public positionManager;
    uint160 public sqrtPriceX96;
    uint24 public fee;
    int24 public currentTick;
    uint128 public liquidity;
    uint256 public feeGrowthGlobal0;
    uint256 public feeGrowthGlobal1;
    Oracle public oracle ;

    mapping(int24 => Tick.TickInfo) public ticks;
    mapping(int24 => bool) public initializedTicks;

    event PositionUpdated(address indexed owner, int24 tickLower, int24 tickUpper,int128 liquidityDelta);
    

    constructor(address _token0, address _token1, uint160 _sqrtPriceX96, address _positionManager, address _oracle, uint24 _fee) {
        token0 = _token0;
        token1 = _token1;
        sqrtPriceX96 = _sqrtPriceX96;
        currentTick = 0;
        positionManager = _positionManager;
        oracle=Oracle(_oracle);
        fee=_fee;
        currentTick=TickMath.getTickAtSqrtRatio(_sqrtPriceX96);
    
        }    
    modifier onlyPositionManager(){
        require(msg.sender == positionManager,"ONLY BY POS MANAGER");
        _;
    }

    function modifyPosition(int24 tickLower, int24 tickUpper, uint128 liquidityDelta) external onlyPositionManager {
// increase pool liquiidty should not be doneby anyone 
        bool lowerWasZero = ticks[tickLower].liquidityGross == 0;
        bool upperWasZero = ticks[tickUpper].liquidityGross == 0;
         ticks[tickLower].liquidityGross += liquidityDelta;
         ticks[tickLower].liquidityNet += int128(liquidityDelta);
         ticks[tickUpper].liquidityGross += liquidityDelta;
         ticks[tickUpper].liquidityNet -= int128(liquidityDelta);
         if (lowerWasZero) {
          bitmap.flipTick(tickLower);
         }

          if (upperWasZero) {
            bitmap.flipTick(tickUpper);
           }
         if(currentTick >= tickLower && currentTick < tickUpper){
            liquidity += liquidityDelta;
         }
         emit PositionUpdated(msg.sender, tickLower, tickUpper, int128(liquidityDelta));

    }
        
    function crossTick(int24 tick) internal {
        ticks[tick].feeGrowthOutside0 =  feeGrowthGlobal0 - ticks[tick].feeGrowthOutside0;
        ticks[tick].feeGrowthOutside1 = feeGrowthGlobal1 -ticks[tick].feeGrowthOutside1;
        // whenever crosses tick just inclrease the liquidity by liquidityNet of the tick
        int128 liquidityNet= ticks[tick].liquidityNet;
        liquidity = LiquidityMath.addLiquidity(liquidity, liquidityNet);
        currentTick= tick;
    }

    function swap( bool zeroForOne, uint256 amountSpecified) external{
        // find next tick 
        // compute sqrtpricetarget -> what price is at that boundary 
        // swapmath.computeSwapStep
        // update sqrtPriceX96
        // deduct amountIn from amountRemaning 
        /*
        zeroForOne = true  → price moving down → scan ticks downward → tick--
        zeroForOne = false → price moving up   → scan ticks upward   → tick++
        */
        uint256 amountRemaining = amountSpecified;

        while(amountRemaining>0){

            int24 nextTick= getNextTick(zeroForOne);

            uint160 sqrtPriceTarget= TickMath.getSqrtRatioAtTick(nextTick);

            (uint160 sqrtPriceNext,
            uint256 amountIn,
            uint256 amountOut,
            uint256 feeAmount,
            bool decision
           ) = SwapMath.computeSwapStep(
                sqrtPriceX96,
                sqrtPriceTarget, 
                liquidity,
                amountRemaining,
                zeroForOne   );
                            
             address tokenIn;
             address tokenOut;

             if(zeroForOne){
             if(liquidity > 0){
              feeGrowthGlobal0 += feeAmount * 1e18 / liquidity;
               }
             tokenIn=token0;
             tokenOut=token1;
             }else{
                if(liquidity > 0){
              feeGrowthGlobal1 += feeAmount * 1e18 / liquidity;
                }
               tokenIn= token1;
               tokenOut=token0;
             }

            require(amountIn>0 , "ZEROAMOUNTIN Not Possible ");
            require(IERC20(tokenOut).balanceOf(address(this)) >= amountOut, "NOT ENOUGH MONEY IN THE POOL ");
            IERC20(tokenIn).transferFrom(msg.sender, address(this),amountIn+feeAmount);
            sqrtPriceX96= sqrtPriceNext;
            amountRemaining -= (amountIn+feeAmount);

            if(sqrtPriceX96== sqrtPriceTarget){
                crossTick(nextTick);
            }
            IERC20(tokenOut).transfer(msg.sender, amountOut);
            oracle.writeObservation(currentTick);
        }
    }

    function getNextTick( bool zeroForOne) internal view returns(int24){
        if(zeroForOne)
        /*
        zeroForOne = true  → selling token0, buying token1
                   → you're FLOODING the pool with token0
                   → token0 becomes cheaper
                   → PRICE GOES DOWN
                   → tick goes DOWN
        */
        {
            for(int24 tick= currentTick-1; tick >= -10000; tick--){
                {
                    if(bitmap.isInitialized(tick)){
                        return tick;
                    }
                    
                }
            }
        }
        else{
            for(int24 tick = currentTick+1; tick <=10000; tick ++){
               if(bitmap.isInitialized(tick)){
                    return tick;
                }
            }
        }
        revert ("NO_TICK");

    }

    function flash(uint256 amount0, uint256 amount1, address recipient, bytes calldata data)external {
     uint256 reserve0= IERC20(token0).balanceOf(address(this));
     uint256 reserve1= IERC20(token1).balanceOf(address(this)); 
   uint256  fee0 = FullMath.mulDiv(
    amount0,
    fee,
    1e6
    );

uint256 fee1 = FullMath.mulDiv(
    amount1,
    fee,
    1e6
   );

     if(amount0>0) IERC20(token0).transfer(recipient, amount0);
     if(amount1>0) IERC20(token1).transfer(recipient, amount1);

     IFlashCallback(recipient).flashCallback(fee0, fee1, data);

     uint256 balance0After = IERC20(token0).balanceOf(address(this));
     uint256 balance1After = IERC20(token1).balanceOf(address(this));
     require(balance0After >= reserve0 + fee0, "NOT REPAID token0");
     require(balance1After >= reserve1 + fee1, "NOT REPAID token1");
}

    function getFeeGrowthGlobals() external view returns(uint256, uint256){
        return( feeGrowthGlobal0,feeGrowthGlobal1);
    }
function getFeeGrowthInside(int24 tickLower,int24 tickUpper)external view returns (
    uint256 feeInside0,uint256 feeInside1)
{
    uint256 feeBelow0;
    uint256 feeBelow1;

    uint256 feeAbove0;
    uint256 feeAbove1;

    if(currentTick >= tickLower){
        feeBelow0 = ticks[tickLower].feeGrowthOutside0;
        feeBelow1 = ticks[tickLower].feeGrowthOutside1;
    } else {
        feeBelow0 =
            feeGrowthGlobal0 -ticks[tickLower].feeGrowthOutside0;

        feeBelow1 =
            feeGrowthGlobal1 -ticks[tickLower].feeGrowthOutside1;
    }

    if(currentTick < tickUpper){
        feeAbove0 = ticks[tickUpper].feeGrowthOutside0;
        feeAbove1 = ticks[tickUpper].feeGrowthOutside1;
    } else {
        feeAbove0 =
            feeGrowthGlobal0 -
            ticks[tickUpper].feeGrowthOutside0;

        feeAbove1 =
            feeGrowthGlobal1 -
            ticks[tickUpper].feeGrowthOutside1;
    }

    feeInside0 =
        feeGrowthGlobal0 -
        feeBelow0 -
        feeAbove0;

    feeInside1 =
        feeGrowthGlobal1 -
        feeBelow1 -
        feeAbove1;
}
}
