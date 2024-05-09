pragma solidity ^0.8.20;

import "../lib/forge-std/src/Script.sol";
import "../lib/forge-std/src/console.sol";

import "../src/FantasyCards.sol";
import "../src/Exchange.sol";
import "../src/ExecutionDelegate.sol";
import "../src/Minter.sol";
import {BlastMock} from "../test/helpers/BlastMock.sol";

contract Deploy is Script {
    FantasyCards fantasyCards = FantasyCards(0x0AAADCf421A3143E5cB2dDB8452c03ae595B0734);
    Exchange exchange;
    ExecutionDelegate executionDelegate = ExecutionDelegate(0xA11Bf3A1b86A977e3beAb2a2E20c67ffDE9DEF7e);

    address weth = 0x4300000000000000000000000000000000000004;

    uint256 protocolFeeBps = 300;
    uint256 wethMinimumPrice = 1000000000000000; // 0.001 eth`

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PK");
        address treasury = vm.envAddress("TREASURY_ADDRESS");
        address governance = vm.envAddress("GOVERNANCE_ADDRESS");
        address deployer = vm.addr(deployerPrivateKey);
        console.log("TREASURY_ADDRESS: ", treasury);
        console.log("GOVERNANCE_ADDRESS: ", governance);
        console.log("DEPLOYER", address(deployer));
        require(treasury != address(0), "Invalid treasury address");
        require(governance != address(0), "Invalid governance address");

        vm.startBroadcast(deployerPrivateKey);

        // --------------------------------------------
        /* EXCHANGE SETUP */
        // --------------------------------------------
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
        // --------------------------------------------
        /*  END OF EXCHANGE SETUP */
        // --------------------------------------------

        // REST OF THE SETUP
        // executionDelegate.approveContract(address(minter));
        // executionDelegate.approveContract(address(exchange)); // TODO: GOVERNANCE

        // fantasyCards.grantRole(fantasyCards.EXECUTION_DELEGATE_ROLE(), address(executionDelegate));

        console.log("SCRIPT FINISHED");

        vm.stopBroadcast();
    }
}
