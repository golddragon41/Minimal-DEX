// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Script, console } from "forge-std/Script.sol";
import { MinimalDex } from "../../contracts/MinimalDex.sol";

contract MinimalDexScript is Script {
    function setUp() public { }

    function run() public {
        address signer = vm.getWallets()[0];

        vm.startBroadcast();
        
        new MinimalDex(signer);

        vm.stopBroadcast();
    }
}
