// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IPair {
    event Mint(address indexed sender, uint amount0, uint amount1, uint liquidity);
    event Burn(address indexed sender, uint amount0, uint amount1, uint liquidity);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amountOut
    );

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function addLiquidity(uint amount0In, uint amount1In) external returns (uint liquidity);
    function removeLiquidity(uint liquidity) external returns (uint amount0Out, uint amount1Out);
    function swap(uint amount0In, uint amount1In) external returns (uint amountOut);

    function initialize(address, address) external;
}