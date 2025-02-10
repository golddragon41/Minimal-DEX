// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Test, console2 } from "forge-std/Test.sol"; // Importing the Foundry Test library
import "../../contracts/MinimalDex.sol";   // Import the MinimalDex contract
import "../../contracts/ERC20.sol";        // Import the ERC20 token contract

contract MinimalDexTest is Test {
    MinimalDex minimalDex;
    ERC20 token0;
    ERC20 token1;
    address token0Address;
    address token1Address;
    address owner;
    address addr1;
    address addr2;

    // Deploy the contracts before running the tests
    function setUp() public {
        // Set up the owner and other test accounts
        owner = vm.addr(1);
        addr1 = vm.addr(2);
        addr2 = vm.addr(3);

        // Deploy ERC20 tokens
        token0 = new ERC20();
        token1 = new ERC20();

        token0Address = address(token0);
        token1Address = address(token1);

        // Deploy MinimalDex contract
        minimalDex = new MinimalDex(owner);

        // Mint tokens for addr1 and addr2
        vm.startPrank(addr1);
        token0.mint(10000 * 10**18);
        token1.mint(10000 * 10**18);
        vm.stopPrank();

        vm.startPrank(addr2);
        token0.mint(10000 * 10**18);
        token1.mint(10000 * 10**18);
        vm.stopPrank();
    }

    // Testing the Factory functionality
    function testFactory() public {
        // Check if the contract is deployed with the correct owner
        assertEq(minimalDex.owner(), owner);

        // Create a pair and test the event
        vm.expectEmit(false, false, false, false);
        emit IDex.PairCreated(token0Address, token1Address, address(0), 1);
        minimalDex.createPair(token0Address, token1Address);
        // Check if the pair was created successfully
        address pairAddress = minimalDex.getPair(token0Address, token1Address);
        assertNotEq(pairAddress, address(0));

        // Try creating a pair with identical tokens and expect failure
        vm.expectRevert(IdenticalTokenAddresses.selector);
        minimalDex.createPair(token0Address, token0Address);

        // Try creating a duplicate pair and expect failure
        vm.expectRevert(PairAlreadyExists.selector);
        minimalDex.createPair(token0Address, token1Address);
    }

    // Testing the functionality of the Pair contract
    function testFunctionality() public {
        // Create pair
        minimalDex.createPair(token0Address, token1Address);

        // Add liquidity to the pair
        address pairAddress = minimalDex.getPair(token0Address, token1Address);
        Pair pair = Pair(pairAddress);

        vm.startPrank(addr1);
        token0.approve(pairAddress, 100 * 10**18);
        token1.approve(pairAddress, 100 * 10**18);
        vm.expectEmit(true, false, false, false);
        emit IPair.Mint(addr1, 0, 0, 0); // Replace 100 with actual expected liquidity minted
        pair.addLiquidity(10 * 10**18, 10 * 10**18);
        vm.stopPrank();

        // Test for empty liquidity addition (should fail)
        vm.startPrank(addr1);
        vm.expectRevert(InsufficientInputAmount.selector);
        pair.addLiquidity(0, 0);
        vm.stopPrank();

        // Test removing liquidity
        uint liquidity = pair.balanceOf(addr1);
        vm.startPrank(addr1);
        pair.approve(pairAddress, liquidity);
        vm.expectEmit(true, false, false, false);
        emit IPair.Burn(addr1, 0, 0, liquidity); // Adjust the expected amounts
        pair.removeLiquidity(liquidity);
        vm.stopPrank();

        // Try removing liquidity with insufficient balance and expect failure
        vm.startPrank(addr1);
        vm.expectRevert(InsufficientLiquidity.selector);
        pair.removeLiquidity(100 * 10**18);
        vm.stopPrank();

        // Test a swap (valid input)
        vm.startPrank(addr2);
        token0.approve(pairAddress, 10 * 10**18);
        token1.approve(pairAddress, 10 * 10**18);
        vm.expectEmit(true, false, false, false);
        emit IPair.Swap(addr2, 0, 0, 100); // Adjust the expected swap output
        pair.swap(10 * 10**18, 0);
        vm.stopPrank();

        // Test swap with invalid input and expect failure
        vm.startPrank(addr2);
        vm.expectRevert(InvalidInputAmount.selector);
        pair.swap(10 * 10**18, 10 * 10**18);
        vm.stopPrank();

        // Test swap with insufficient input and expect failure
        vm.startPrank(addr2);
        vm.expectRevert(InsufficientInputAmount.selector);
        pair.swap(0, 0);
        vm.stopPrank();
    }
}