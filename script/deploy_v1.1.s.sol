pragma solidity ^0.8.20;

import "../lib/forge-std/src/Script.sol";
import "../lib/forge-std/src/console.sol";

import "../src/FantasyCards.sol";
import "../src/Exchange.sol";
import "../src/ExecutionDelegate.sol";
import "../src/Minter.sol";
import "../test/tokens/WrappedMON_Ownable.sol";
import {BlastMock} from "../test/helpers/BlastMock.sol";

contract Deploy is Script {
    FantasyCards fantasyCards;
    Exchange exchange;
    ExecutionDelegate executionDelegate;
    Minter minter;

    uint256 protocolFeeBps = 300;
    uint256 wethMinimumPrice = 1000000000000000; // 0.001 eth
    uint256 cardsRequiredForLevelUp = 5;
    uint256 cardsRequiredForBurnToDraw = 2;
    uint256 cardsDrawnPerBurn = 1;

    bytes32 public constant MINT_CONFIG_MASTER = keccak256("MINT_CONFIG_MASTER");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PK");
        address deployer = vm.addr(deployerPrivateKey);
        address treasury = address(0x8Ab15fE88a00b03724aC91EE4eE1f998064F2e31);
        address governance = address(0x87300D35353D21479e0c96B87D9a7997726f4c16);
        address pauser1 = address(0x5d81AE293cBebdCD0fe57F62068bB763E56581AC);
        address weth = address(0x4200000000000000000000000000000000000006);
        address minter1 = address(0xa65B253C01cBFb156c63371bb732137a3a77bA52);
        
        console.log("TREASURY_ADDRESS: ", treasury);
        console.log("GOVERNANCE_ADDRESS: ", governance);
        console.log("DEPLOYER", address(deployer));

        require(treasury != address(0), "Invalid treasury address");
        require(governance != address(0), "Invalid governance address");

        vm.startBroadcast(deployerPrivateKey);

        fantasyCards = new FantasyCards();
        console.log("FANTASY CARDS: ", address(fantasyCards));

        // // --------------------------------------------
        // /* EXECUTION DELEGATE SETUP */
        // // --------------------------------------------
        // Deploys the contract
        executionDelegate = new ExecutionDelegate();
        console.log("EXECUTION DELEGATE: ", address(executionDelegate));
        // Sets the PAUSER_ROLE to the deployer
        executionDelegate.grantRole(PAUSER_ROLE, pauser1);
        // Initiates the transfer of ownership to governance multisig
        // TODO: accept the admin transfer via the governance multisig
        executionDelegate.beginDefaultAdminTransfer(governance);
        // // --------------------------------------------
        // /* END OF EXECUTION DELEGATE SETUP */
        // // --------------------------------------------

        fantasyCards.grantRole(fantasyCards.EXECUTION_DELEGATE_ROLE(), address(executionDelegate));

        // // --------------------------------------------
        // /* MINTER SETUP */
        // // --------------------------------------------
        // // Deploys the new minter contract
        minter = new Minter(
            treasury,
            address(executionDelegate),
            cardsRequiredForLevelUp,
            cardsRequiredForBurnToDraw,
            cardsDrawnPerBurn
        );
        console.log("MINTER: ", address(minter));
        // Whitelists the fantasy card collection
        minter.whiteListCollection(address(fantasyCards));
        // Grants the MINT_CONFIG_MASTER role to the deployer
        minter.grantRole(MINT_CONFIG_MASTER, deployer);
        minter.grantRole(MINT_CONFIG_MASTER, minter1);
        // Initiates the transfer of ownership to governance multisig
        // TODO: accept the ownership via the governance multisig
        minter.beginDefaultAdminTransfer(governance);
        // // --------------------------------------------
        // /* END OF MINTER SETUP */
        // // --------------------------------------------

        // // --------------------------------------------
        // /* EXCHANGE SETUP */
        // // --------------------------------------------
        // Deploys the contract
        exchange = new Exchange(treasury, protocolFeeBps, address(executionDelegate));
        console.log("EXCHANGE: ", address(exchange));
        // Whitelists the fantasy card collection
        exchange.whiteListCollection(address(fantasyCards));
        // Whitelists the wrapped ETH token and sets the minimum price
        exchange.whiteListPaymentToken(weth, wethMinimumPrice);
        // Initiates the transfer of ownership to governance multisig
        // TODO: accept the ownership transfer via the governance multisig
        exchange.transferOwnership(governance);
        // // --------------------------------------------
        // /*  END OF EXCHANGE SETUP */
        // // --------------------------------------------

        // // REST OF THE SETUP
        executionDelegate.approveContract(address(minter));
        executionDelegate.approveContract(address(exchange));

        console.log("SCRIPT FINISHED");

        vm.stopBroadcast();
    }
}