// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./interfaces/IDex.sol";
import "./Pair.sol";
import "./Errors.sol";

contract MinimalDex is IDex {
    address public feeRecipient;
    address public owner;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    constructor(address _owner) {
        owner = _owner;
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair) {
        if (tokenA == tokenB) revert IdenticalTokenAddresses();

        // to make gas efficient and less code
        // swap the token addresses by value.
        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);

        if (token0 == address(0)) revert ZeroAddressNotAllowed();
        if (getPair[token0][token1] != address(0)) revert PairAlreadyExists();

        // deploy new Pair contract using create2
        bytes memory bytecode = type(Pair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        // initialize the deployed pair.
        IPair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);

        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeRecipient(address _feeRecipient) external {
        if (msg.sender != owner) revert OnlyOwnerAllowed();
        feeRecipient = _feeRecipient;
    }

    function setOwner(address _owner) external {
        if (msg.sender != owner) revert OnlyOwnerAllowed();
        owner = _owner;
    }
}
