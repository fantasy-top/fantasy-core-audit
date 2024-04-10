pragma solidity ^0.8.20;

import "../lib/forge-std/src/Script.sol";
import "../lib/forge-std/src/console.sol";

import "../src/FantasyCards.sol";
import "../src/Exchange.sol";
import "../src/ExecutionDelegate.sol";
import "../src/Minter.sol";
import "../test/tokens/WrappedETH.sol";

contract Deploy is Script {
    FantasyCards fantasyCards;
    Exchange exchange;
    ExecutionDelegate executionDelegate;
    Minter minter;
    WrappedETH weth;

    uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    uint256 treasuryPrivateKey = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;
    uint256 user1PrivateKey = 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a;
    uint256 user2PrivateKey = 0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6;

    address deployer = vm.addr(deployerPrivateKey);
    address treasury = vm.addr(treasuryPrivateKey);
    address user1 = vm.addr(user1PrivateKey);
    address user2 = vm.addr(user2PrivateKey);

    uint256 protocolFeeBps = 300;
    uint256 wethMinimumPrice = 0;

    function run() external {
        vm.startBroadcast(deployerPrivateKey);

        fantasyCards = new FantasyCards();
        weth = new WrappedETH();
        executionDelegate = new ExecutionDelegate();
        minter = new Minter(treasury, address(executionDelegate), 5, 15, 1);

        exchange = new Exchange(treasury, protocolFeeBps, address(executionDelegate));
        exchange.whiteListCollection(address(fantasyCards));
        exchange.whiteListPaymentToken(address(weth), wethMinimumPrice);

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
