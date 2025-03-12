// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/forge-std/src/Script.sol";
import "../lib/forge-std/src/console.sol";

import "../test/tokens/RestrictedToken.sol";
import "../src/Exchange.sol";
import "../src/ExecutionDelegate.sol";
import "../src/Minter.sol";
import "../src/FantasyCards.sol";

contract IntegrateFMON is Script {
    // Minimum price for fMON in the exchange
    uint256 fmonMinimumPrice = 1000000000000000; // 0.001 eth

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PK");
        address deployer = vm.addr(deployerPrivateKey);
        
        // Get contract addresses from environment variables
        // These are required for the integration
        address fmonAddress = vm.envOr("FMON_ADDRESS", address(0));
        address exchangeAddress = vm.envOr("EXCHANGE_ADDRESS", address(0));
        address executionDelegateAddress = vm.envOr("EXECUTION_DELEGATE_ADDRESS", address(0));
        address minterAddress = vm.envOr("MINTER_ADDRESS", address(0));
        address fantasyCardsAddress = vm.envOr("FANTASY_CARDS_ADDRESS", address(0));
        
        require(fmonAddress != address(0), "fMON address not provided");
        
        console.log("DEPLOYER: ", deployer);
        console.log("FMON ADDRESS: ", fmonAddress);
        console.log("EXCHANGE ADDRESS: ", exchangeAddress);
        console.log("EXECUTION DELEGATE ADDRESS: ", executionDelegateAddress);
        console.log("MINTER ADDRESS: ", minterAddress);
        console.log("FANTASY CARDS ADDRESS: ", fantasyCardsAddress);

        vm.startBroadcast(deployerPrivateKey);

        RestrictedToken fmon = RestrictedToken(fmonAddress);
        
        // --------------------------------------------
        /* INTEGRATION WITH EXCHANGE */
        // --------------------------------------------
        if (exchangeAddress != address(0)) {
            Exchange exchange = Exchange(exchangeAddress);
            console.log("Whitelisting fMON in Exchange...");
            exchange.whiteListPaymentToken(fmonAddress, fmonMinimumPrice);
            console.log("fMON whitelisted in Exchange with minimum price: ", fmonMinimumPrice);
        } else {
            console.log("Exchange address not provided. Skipping Exchange integration.");
        }
        
        // --------------------------------------------
        /* INTEGRATION WITH EXECUTION DELEGATE */
        // --------------------------------------------
        if (executionDelegateAddress != address(0)) {
            console.log("Approving ExecutionDelegate to spend fMON...");
            fmon.approve(executionDelegateAddress, type(uint256).max);
            console.log("ExecutionDelegate approved to spend fMON");
        } else {
            console.log("ExecutionDelegate address not provided. Skipping ExecutionDelegate integration.");
        }
        
        // --------------------------------------------
        /* INTEGRATION WITH MINTER (if needed) */
        // --------------------------------------------
        if (minterAddress != address(0)) {
            Minter minter = Minter(minterAddress);
            // Add any minter-specific integration here if needed
            console.log("Minter address provided, but no specific integration needed for fMON");
        } else {
            console.log("Minter address not provided. Skipping Minter integration.");
        }
        
        // --------------------------------------------
        /* INTEGRATION WITH FANTASY CARDS (if needed) */
        // --------------------------------------------
        if (fantasyCardsAddress != address(0)) {
            FantasyCards fantasyCards = FantasyCards(fantasyCardsAddress);
            // Add any FantasyCards-specific integration here if needed
            console.log("FantasyCards address provided, but no specific integration needed for fMON");
        } else {
            console.log("FantasyCards address not provided. Skipping FantasyCards integration.");
        }
        
        console.log("FMON INTEGRATION COMPLETED");
        
        vm.stopBroadcast();
    }
} 