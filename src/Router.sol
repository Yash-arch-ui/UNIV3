//SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;
import "./interfaces/ICLAMMFactory.sol";
import "./interfaces/ICLAMMPOOL.sol";
import "./interfaces/IPositionManager.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Router{
    address public factory ;
    address public positionManager;

constructor(address _factory, address _positionManager ){
    factory = _factory;
    positionManager = _positionManager;
}

function swapExactTokensForTokens(address tokenIn, address tokenOut, uint256 amountIn, bool zeroForOne) external{
    IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
    address pool = ICLAMMFactory(factory).getPool(tokenIn,tokenOut);
    require(pool != address(0), "POOL_NOT_FOUND");
    IERC20(tokenIn).approve(pool, amountIn);// approving pool to use 
    ICLAMMPool(pool).swap(zeroForOne, amountIn);
}

function mintPosition(int24 tickLower, int24 tickUpper, uint128 liquidity) external {
    IPositionManager(positionManager).mint(msg.sender,tickLower. tickUpper, liquidity);
}

function increaseLiquidity(uint256 tokenId, uint128 liquidity) external {
    IPositionManager(positionManager).increaseLiquidity(msg.sender,tokenId, liquidity);
    
}
function decreaseLiquidity(uint256 tokenId, uint128 liquidity) external {
    IPositionManager(positionManager).decreaseLiquidity(msg.sender,tokenId, liquidity);
}
function collect (uint256 tokenId) external {
    IPositionManager(positionManager).collect(msg.sender, tokenId);
}
}

// POOL - FACTORY 
// LP POS - PositionManager 