// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/forge-std/src/Script.sol";
import "../lib/forge-std/src/console.sol";

import "../test/tokens/RestrictedToken.sol";

contract DeployFMON is Script {
    RestrictedToken fmon;
    
    // Amount to mint to the deployer initially
    uint256 amountFaucet = 100000000000000000000000000000000000;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PK");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("DEPLOYER: ", deployer);

        vm.startBroadcast(deployerPrivateKey);

        // --------------------------------------------
        /* FMON TOKEN SETUP */
        // --------------------------------------------
        // Deploy the fMON token
        fmon = new RestrictedToken();
        console.log("FMON TOKEN: ", address(fmon));
        
        // Mint initial tokens to the deployer
        fmon.getFaucet(amountFaucet);
        console.log("Minted initial tokens to deployer");

        // --------------------------------------------
        /* INTEGRATION WITH EXISTING CONTRACTS */
        // --------------------------------------------
        // NOTE: These addresses will need to be provided later
        // address exchange = address(0); // Replace with actual Exchange address
        // address executionDelegate = address(0); // Replace with actual ExecutionDelegate address
        
        // Example of how to integrate with existing contracts once addresses are provided:
        // uint256 fmonMinimumPrice = 1000000000000000; // 0.001 eth
        // exchange.whiteListPaymentToken(address(fmon), fmonMinimumPrice);
        // fmon.approve(address(executionDelegate), type(uint256).max);
        
        console.log("FMON DEPLOYMENT COMPLETED");
        console.log("NOTE: You will need to run additional commands to whitelist the token in Exchange and approve it for ExecutionDelegate");

        vm.stopBroadcast();
    }
} 