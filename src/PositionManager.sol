// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./libraries/Position.sol";
import "./libraries/Tick.sol";
import "./interfaces/ICLAMMPOOL.sol";
import "./libraries/FullMath.sol";
import "./libraries/TickMath.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
contract PositionManager is ERC721{
    using Position for Position.PositionInfo;
    address public pool;
    address public token0;
    address public token1;

    mapping(uint256 => Position.PositionInfo) public positions;// mapping each id to position struct 
    uint256 public nextTokenId;
    event PositionUpdated(
        address indexed owner,
        int24 tickLower,
        int24 tickUpper,
        int128 liquidityDelta
    );

    constructor(address _pool) ERC721(
        "CLAMM Position, "CLP"
    ){
        pool=_pool;
    }
  /*  function getKey(
        address owner,
        int24 tickLower,
        int24 tickUpper
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(owner, tickLower, tickUpper));
    }*/

    function mint(
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0Desired,
        uint256 amount1Desired
    ) external {
        require(tickLower < tickUpper, "INVALID_RANGE");

        require(liquidity > 0, "ZERO_LIQUIDITY");
      
         Position.PositionInfo storage position = positions[tokenId];
        uint256 sqrtPriceX96= ICLAMMPool(pool).sqrtPriceX96();
        uint160 sqrtPriceA = TickMath.getSqrtRatioAtTick(tickLower);

        uint160 sqrtPriceB = TickMath.getSqrtRatioAtTick(tickUpper);
        uint128 liquidity;
        // CURRENT PRICE BELOW RANGE 

        if (sqrtPriceX96 <= sqrtPriceA){
            liquidity =LiquidityAmounts.getLiquidityForAmount0(sqrtPriceA, sqrtPriceB, amount0Desired);
        }
        // CURRENT PRICE ABOVE RANGE 
        else if (sqrtPriceX96 >= sqrtPriceB){
            liquidity= LiquidityAmounts.getLiquidityForAmount1(sqrtPriceA, sqrtPriceB, amount1Desired);

        }
        // CURRENT PRICE INSIDE RANGE 
        else 
        {
            uint128 liquidity0= LiquidityAmounts.getLiquidityForAmount0(sqrtPriceX96, sqrtPriceB, amount0Desired);
            uint128 liquidity1= LiquidityAmounts.getLiquidityForAmount1(sqrtPriceA, sqrtPrieX96, amount1Desired);
            liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
        }
        IERC20(token0).transferFrom(msg.sender, address(this), amount0Desired);
        IERC20(token1).transferFrom(msg.sender, address(this), amount1Desired);
            
        tokenId = ++nextTokenId;
        _safeMint(msg.sender, tokenId);
        
        position.tickLower = tickLower;
        position.tickUpper = tickUpper;
        position.liquidity += liquidity;         

        (uint256 feeGrowth0, uint256 feeGrowth1) = ICLAMMPool(pool).getFeeGrowthGlobals();
        (uint256 feeInside0, uint256 feeInside1) = ICLAMMPool(pool).getFeeGrowthInside(tickLower, tickUpper);

        position.feeGrowthInside0Last = feeInside0;
        position.feeGrowthInside0Last= feeInside1;
        ICLAMMPool(pool).modifyPosition(tickLower,tickUpper,liquidity);

        emit PositionUpdated(
            msg.sender,
            tickLower,
            tickUpper,
            int128(liquidity)
        );
    }

    function increaseLiquidity(
        uint256 tokenId,
        uint128 liquidity
    ) external {
        updateFees(position);
        require(ownerOf(tokenId) == msg.sender, "NOT_OWNER");
        require(liquidity > 0, "ZERO_LIQUIDITY");

         Position.PositionInfo storage position = positions[tokenId];
         require(position.liquidity > 0, "POSITION_NOT_FOUND");
          position.liquidity += liquidity;

           ICLAMMPool(pool).modifyPosition(position.tickLower,tickUpper,liquidity);
        emit PositionUpdated(
            msg.sender,
            tickLower,
            tickUpper,
            int128(liquidity)
        );
    }
    function decreaseLiquidity(
        uint256 tokenId,
        uint128 liquidity
    ) external {
        updateFees(position);
        require(ownerOf(tokenId) == msg.sender, "NOT_OWNER");
        require(liquidity > 0, "ZERO_LIQUIDITY");
        Position.PositionInfo storage position = positions[tokenId];

        require(position.liquidity >= liquidity, "INSUFFICIENT_LIQUIDITY");
        updateFees(position);
        position.liquidity -= liquidity;
        ICLAMMPool(pool).modifyPosition(position.tickLower,position.tickUpper,-int128(liquidity));

        emit PositionUpdated(
            msg.sender,
            tickLower,
            tickUpper,
            -int128(liquidity)
        );
    }
    function collect(
      uint256 tokenId
    ) external returns (uint256 amount0, uint256 amount1) {
        updateFees(position);
        require(ownerOf(tokenId) == msg.sender, "NOT_OWNER");
        Position.PositionInfo storage p = positions[tokenId];
        updateFees(p);
        amount0 = p.tokensOwed0 ;
        amount1 = p.tokensOwed1;
        p.tokensOwed0 = 0;
        p.tokensOwed1 = 0;
         if (amount0 > 0 || amount1 > 0) {
            ICLAMMPool(pool).collect(msg.sender, amount0, amount1);
        }
    }

    function getPosition(
        address owner,
        int24 tickLower,
        int24 tickUpper
    ) external view returns (Position.PositionInfo memory) {
        return positions[getKey(owner, tickLower, tickUpper)];
    }

    function updateFees(Position.PositionInfo storage position) internal {

      (uint256 feeGrowthGlobal0, uint256 feeGrowthGlobal1) =ICLAMMPool(pool).getFeeGrowthGlobals();
    
     uint256 fees0 = FullMath.mulDiv(feeGrowthGlobal0 - position.feeGrowthInside0Last,
      position.liquidity,1e18);

     uint256 fees1 = FullMath.mulDiv(feeGrowthGlobal1 - position.feeGrowthInside1Last,
     position.liquidity, 1e18);
     uint256 growth0= feeInside0 - position.feeGrowthInside0Last;
     uint256 growth1= feeInside1 - position.feeGrowthInside1Last;
     position.tokensOwed0 += growth0* position.liquidity;

     position.tokensOwed1 += growth1* position.liquidity;

     position.feeGrowthInside0Last =feeInside0;
      position.feeGrowthInside1Last =   feeInside1;
      (uint256 feeInside0, uint256 feeInside1)= ICLAMMPool(pool).getFeeGrowthInside(position.tickLower, position.tickUpper);
}
}
// See PositionManager.sol for creating positions, modifiying positions, nft ownership, tracking users liquidity ranges
