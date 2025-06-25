// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/forge-std/src/Script.sol";
import "../lib/forge-std/src/console.sol";

import "../test/tokens/RestrictedToken.sol";

contract DeployFWETH is Script {
    RestrictedToken fweth;
    
    // Amount to mint to the deployer initially
    uint256 amountFaucet = 100000000000000000000000000000000000;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PK");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("DEPLOYER: ", deployer);

        vm.startBroadcast(deployerPrivateKey);

        // --------------------------------------------
        /* fweth TOKEN SETUP */
        // --------------------------------------------
        // Deploy the fweth token
        fweth = new RestrictedToken();
        console.log("FWETH TOKEN: ", address(fweth));
        
        // Mint initial tokens to the deployer
        fweth.getFaucet(amountFaucet);
        console.log("Minted initial tokens to deployer");

        // --------------------------------------------
        /* INTEGRATION WITH EXISTING CONTRACTS */
        // --------------------------------------------
        // NOTE: These addresses will need to be provided later
        // address exchange = address(0); // Replace with actual Exchange address
        // address executionDelegate = address(0); // Replace with actual ExecutionDelegate address
        
        // Example of how to integrate with existing contracts once addresses are provided:
        // uint256 fwethMinimumPrice = 1000000000000000; // 0.001 eth
        // exchange.whiteListPaymentToken(address(fweth), fwethMinimumPrice);
        // fweth.approve(address(executionDelegate), type(uint256).max);
        
        console.log("FWETH DEPLOYMENT COMPLETED");
        console.log("NOTE: You will need to run additional commands to whitelist the token in Exchange and approve it for ExecutionDelegate");

        vm.stopBroadcast();
    }
} 