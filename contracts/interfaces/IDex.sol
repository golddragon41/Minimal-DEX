// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IDex {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint len
    );

    function feeRecipient() external view returns (address);
    function owner() external view returns (address);

    function setFeeRecipient(address) external;
    function setOwner(address) external;

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}
