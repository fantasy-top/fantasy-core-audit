pragma solidity ^0.8.20;

import "../lib/forge-std/src/Script.sol";
import "../lib/forge-std/src/console.sol";

import "../src/FantasyCards.sol";
import "../src/Exchange.sol";
import "../src/ExecutionDelegate.sol";
import "../src/Minter.sol";
import "../test/tokens/WrappedETH_Ownable.sol";

contract DeployMinter is Script {
    FantasyCards fantasyCards;
    Exchange exchange;
    ExecutionDelegate executionDelegate;
    Minter minter;
    WrappedETH weth;

    uint256 protocolFeeBps = 300;
    uint256 wethMinimumPrice = 0;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PK");
        console.log("Deployer Private Key: ", deployerPrivateKey);

        address treasury = 0x6b88C7D530969F747A4dA218CF8Ef26505d45AE6;
        address executionDelegate = 0x1caaa0Cce5d809BCa4f5C23896d94d07a1C0B07A;
        console.log("Treasury Address: ", address(treasury));
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        minter = new Minter(treasury, executionDelegate, 5, 15, 1);

        vm.stopBroadcast();

        console.log("Minter: ", address(minter));
    }
}
