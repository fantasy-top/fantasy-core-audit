// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/forge-std/src/Script.sol";
import "../lib/forge-std/src/console.sol";

import "../test/tokens/RestrictedToken.sol";
import "../src/Exchange.sol";
import "../src/ExecutionDelegate.sol";

contract DeployFMONWithIntegration is Script {
    RestrictedToken fmon;
    
    // Amount to mint to the deployer initially
    uint256 amountFaucet = 1000000000000000000000000000000000;
    // Minimum price for fMON in the exchange
    uint256 fmonMinimumPrice = 100000000000000; // 0.0001 eth

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PK");
        address deployer = vm.addr(deployerPrivateKey);
        
        // Get existing contract addresses from environment variables
        // If not provided, these will be address(0) and integration steps will be skipped
        address exchangeAddress = vm.envOr("EXCHANGE_ADDRESS", address(0));
        address executionDelegateAddress = vm.envOr("EXECUTION_DELEGATE_ADDRESS", address(0));
        
        console.log("DEPLOYER: ", deployer);
        console.log("EXCHANGE ADDRESS: ", exchangeAddress);
        console.log("EXECUTION DELEGATE ADDRESS: ", executionDelegateAddress);

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
        // Only perform integration if addresses are provided
        if (exchangeAddress != address(0)) {
            Exchange exchange = Exchange(exchangeAddress);
            console.log("Whitelisting fMON in Exchange...");
            exchange.whiteListPaymentToken(address(fmon), fmonMinimumPrice);
            console.log("fMON whitelisted in Exchange with minimum price: ", fmonMinimumPrice);
        } else {
            console.log("Exchange address not provided. Skipping Exchange integration.");
        }
        
        if (executionDelegateAddress != address(0)) {
            ExecutionDelegate executionDelegate = ExecutionDelegate(executionDelegateAddress);
            console.log("Approving ExecutionDelegate to spend fMON...");
            fmon.approve(executionDelegateAddress, type(uint256).max);
            console.log("ExecutionDelegate approved to spend fMON");
            
            // Add the ExecutionDelegate as an approved sender
            console.log("Adding ExecutionDelegate as an approved sender...");
            fmon.approveSender(executionDelegateAddress);
            console.log("ExecutionDelegate added as an approved sender");
        } else {
            console.log("ExecutionDelegate address not provided. Skipping ExecutionDelegate integration.");
        }
        
        console.log("FMON DEPLOYMENT COMPLETED");
        
        vm.stopBroadcast();
    }
} 