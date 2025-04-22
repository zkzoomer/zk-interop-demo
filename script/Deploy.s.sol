// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {HotPotato} from "../src/HotPotato.sol";

contract Deploy is Script {
    HotPotato public hotPotato;

    function run() public {
        bytes32 salt = 0x00000000000000000000000000000000000000000000000000000000feed5eed;
        vm.startBroadcast();
        hotPotato = new HotPotato{salt: salt}();
        vm.stopBroadcast();

        console.log("Deployed HotPotato at: ", address(hotPotato));
    }
}
