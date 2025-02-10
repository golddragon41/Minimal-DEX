// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

error IdenticalTokenAddresses();
error ZeroAddressNotAllowed();
error PairAlreadyExists();
error OnlyOwnerAllowed();

error OnlyFactoryAllowed();
error TransferFailed();
error InsufficientLiquidityMinted();
error InsufficientLiquidityBurned();
error InsufficientInputAmount();
error InvalidInputAmount();
error InsufficientOutputAmount();
error InsufficientLiquidity();
error InvalidTraderAddress();
error InvalidSwapTokenAddress();
error PairRateCorrupted();
error BalanceOverflow();
error ReentrancyCallNotAllowed();