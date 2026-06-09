// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./libraries/Position.sol";
import "./libraries/Tick.sol";
import "./interfaces/ICLAMMPOOL.sol";

contract PositionManager {
    using Position for Position.PositionInfo;
    address public pool ;
    mapping(bytes32 => Position.PositionInfo) public positions;
    mapping(int24 => Tick.TickInfo) public ticks;
    event PositionUpdated(address indexed owner,int24 tickLower,int24 tickUpper,int128 liquidityDelta);

    constructor (address _pool){
        pool=_pool;
    }
     
    function getKey(address owner,int24 tickLower,int24 tickUpper) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(owner, tickLower, tickUpper));
    }

    function mint(int24 tickLower,int24 tickUpper,uint128 liquidity) external {
        require(tickLower < tickUpper, "INVALID_RANGE");
        require(liquidity > 0, "ZERO_LIQUIDITY");
        bytes32 key = getKey(msg.sender, tickLower, tickUpper);
        Position.PositionInfo storage position = positions[key];
        position.tickLower = tickLower;
        position.tickUpper = tickUpper;
        position.liquidity += liquidity;

        ticks[tickLower].liquidityGross += liquidity;
        ticks[tickLower].liquidityNet += int128(liquidity);

        ticks[tickUpper].liquidityGross += liquidity;
        ticks[tickUpper].liquidityNet -= int128(liquidity);

        emit PositionUpdated( msg.sender, tickLower,tickUpper,int128(liquidity));
    }

    function increaseLiquidity( int24 tickLower,int24 tickUpper,uint128 liquidity ) external {
        require(liquidity > 0, "ZERO_LIQUIDITY");

        bytes32 key = getKey(msg.sender, tickLower, tickUpper);
        (uint256 feeGrowth0, 
        uint256 feeGrowth1) = ICLAMMPool(pool).getFeeGrowthGlobals();
        Position.PositionInfo storage position = positions[key];
        require(position.liquidity > 0, "POSITION_NOT_FOUND");
        uint256 fees0= feeGrowth0- (position.feeGrowthInside0Last)* position.liquidity;
        uint256 fees1= feeGrowth1- (position.feeGrowthInside1Last)*position.liquidity;
         position.feeGrowthInside0Last =feeGrowth0;
         position.feeGrowthInside1Last = feeGrowth1;
        position.liquidity += liquidity;

        ticks[tickLower].liquidityGross += liquidity;
        ticks[tickLower].liquidityNet += int128(liquidity);

        ticks[tickUpper].liquidityGross += liquidity;
        ticks[tickUpper].liquidityNet -= int128(liquidity);
        position.tokensOwed0 += fees0;
        position.tokensOwed1 += fees1;
       

        emit PositionUpdated(msg.sender,tickLower,tickUpper,int128(liquidity));
    }

    function decreaseLiquidity(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    ) external {
        require(liquidity > 0, "ZERO_LIQUIDITY");
        bytes32 key = getKey(msg.sender, tickLower, tickUpper);
          (uint256 feeGrowth0, 
        uint256 feeGrowth1) = ICLAMMPool(pool).getFeeGrowthGlobals();
        Position.PositionInfo storage position = positions[key];
        require(position.liquidity >= liquidity, "INSUFFICIENT_LIQUIDITY");
          uint256 fees0= feeGrowth0- (position.feeGrowthInside0Last)* position.liquidity;
          uint256 fees1= feeGrowth1- (position.feeGrowthInside1Last)*position.liquidity;
         position.feeGrowthInside0Last =feeGrowth0;
         position.feeGrowthInside1Last = feeGrowth1;
        position.liquidity -= liquidity;
        ticks[tickLower].liquidityGross -= liquidity;
        ticks[tickLower].liquidityNet -= int128(liquidity);

        ticks[tickUpper].liquidityGross -= liquidity;
        ticks[tickUpper].liquidityNet += int128(liquidity);

        emit PositionUpdated(
            msg.sender,tickLower,tickUpper,-int128(liquidity)
        );
    }
    function collect (int24 tickLower, int24 tickUpper) external returns(uint256 amount0, uint256 amount1){
        bytes32 key = getKey ( msg.sender, tickLower, tickUpper);
        Position.PositionInfo storage p = positions[key];
        amount0= p.tokensOwed0=0;
        amount1= p.tokensOwed1=0;
        p.tokensOwed0 = 0;
        p.tokensOwed1 = 0;
    }

    function getPosition(
        address owner,
        int24 tickLower,
        int24 tickUpper
    ) external view returns (Position.PositionInfo memory) {
        return positions[getKey(owner, tickLower, tickUpper)];
    }
}
// See PositionManager.sol for creating positions, modifiying positions, nft ownership, tracking users liquidity ranges 