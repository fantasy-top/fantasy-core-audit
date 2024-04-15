pragma solidity ^0.8.20;

import "../lib/forge-std/src/Script.sol";
import "../lib/forge-std/src/console.sol";

import "../src/FantasyCards.sol";
import "../src/Exchange.sol";
import "../src/ExecutionDelegate.sol";
import "../src/Minter.sol";

contract Deploy is Script {
    FantasyCards fantasyCards;
    Exchange exchange;
    ExecutionDelegate executionDelegate;
    Minter minter;

    address weth = 0x4300000000000000000000000000000000000004;

    uint256 protocolFeeBps = 300;
    uint256 wethMinimumPrice = 10000000000000000; // 0.01 eth
    uint256 cardsRequiredForLevelUp = 5;
    uint256 cardsRequiredForBurnToDraw = 15;
    uint256 cardsDrawnPerBurn = 1;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PK");

        address treasury = vm.envAddress("TREASURY_ADDRESS");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deployer: ", address(deployer));
        console.log("Treasury: ", address(treasury));

        vm.startBroadcast(deployerPrivateKey);

        fantasyCards = new FantasyCards();
        executionDelegate = new ExecutionDelegate();
        minter = new Minter(
            treasury,
            address(executionDelegate),
            cardsRequiredForLevelUp,
            cardsRequiredForBurnToDraw,
            cardsDrawnPerBurn
        );

        exchange = new Exchange(treasury, protocolFeeBps, address(executionDelegate));
        exchange.whiteListCollection(address(fantasyCards));
        exchange.whiteListPaymentToken(weth, wethMinimumPrice);

        executionDelegate.approveContract(address(minter));
        executionDelegate.approveContract(address(exchange));

        fantasyCards.grantRole(fantasyCards.EXECUTION_DELEGATE_ROLE(), address(executionDelegate));

        vm.stopBroadcast();

        console.log("FantasyCards: ", address(fantasyCards));
        console.log("Exchange: ", address(exchange));
        console.log("ExecutionDelegate: ", address(executionDelegate));
        console.log("Minter: ", address(minter));
        console.log("WrappedETH: ", address(weth));
    }
}
