/*
Factory
  │
  ├── deploy(token0, token1, fee) → CLAMMPool #1  (ETH/USDC)
  ├── deploy(token0, token1, fee) → CLAMMPool #2  (ETH/DAI)
  └── deploy(token0, token1, fee) → CLAMMPool #3  (USDC/DAI)3
*/

//SPDX-License-Identifier:MIT 
pragma solidity ^0.8.19;
import "./Oracle.sol";
import "./PositionManager.sol";
import "./CLAMMPool.sol";
contract CLAMMFactory {

mapping(address => mapping(address => mapping(uint24 => address))) public getPool;
address[] public allPools;

// this allows to return the pool address -> getPool[token0][token1]

event PoolCreated(address indexed token0, address indexed token1, address pool , uint24 fee);
address public positionManager;
address public oracle;

constructor( address _positionManager, address _oracle ){
    positionManager= _positionManager;
    oracle=_oracle;
}

function createPool( address tokenA, address tokenB,uint24 fee, uint160 sqrtPriceX96) external returns (address pool){
    require(tokenA != tokenB,"SAME TOKENS");
    require(
    tokenA != address(0) &&
    tokenB != address(0),
    "ZERO_ADDRESS"
);
    (address token0,address token1)= (tokenA < tokenB)?(tokenA, tokenB): (tokenB, tokenA);
        require(getPool[token0][token1][fee] == address(0), "POOL EXISTS ");

    pool = address(new CLAMMPool
    (token0,token1,sqrtPriceX96,positionManager,oracle,fee)
    );
    getPool[token0][token1][fee]= pool;
    getPool[token1][token0][fee]=pool;
    allPools.push(pool);
    emit PoolCreated(token0, token1, pool, fee);
    returns pool;
}

function allPoolsLength() external view returns(uint256){
    return allPools.length;
}
}