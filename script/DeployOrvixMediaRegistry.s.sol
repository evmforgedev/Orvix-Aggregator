// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {Script} from "forge-std/Script.sol";
import {OrvixMediaRegistry} from "../src/OrvixMediaRegistry.sol";

contract DeployOrvixMediaRegistry is Script {
    function run() external returns (OrvixMediaRegistry registry) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        registry = new OrvixMediaRegistry();

        vm.stopBroadcast();
    }
}
