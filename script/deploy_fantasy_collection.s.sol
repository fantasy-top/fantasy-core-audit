pragma solidity ^0.8.20;

import "../lib/forge-std/src/Script.sol";
import "../lib/forge-std/src/console.sol";

import "../src/FantasyCards.sol";
import "../src/Exchange.sol";
import "../src/ExecutionDelegate.sol";
import "../src/Minter.sol";
import "../test/tokens/WrappedETH_Ownable.sol";

contract Deploy is Script {
    address wethAddress = 0x4300000000000000000000000000000000000004;
    address blastPointsAddress = 0x2536FE9ab3F511540F2f9e2eC2A805005C3Dd800;
    address blastGasAddress = 0x4300000000000000000000000000000000000002;

    address executionDelegateAddress = 0x3Da2a1D0C88dc1E5567970C305d09249Fc7ae08a;
    address minterAddress = 0x01655f68D8063234e2E8e069608AfCcA90cbbAf1;
    address exchangeAddress = 0xDb922BD2c4B3F44d75Aa91A789296410F0f20b0e;

    address treasuryAddress = 0x8Ab15fE88a00b03724aC91EE4eE1f998064F2e31;
    address governanceAddress = 0x87300D35353D21479e0c96B87D9a7997726f4c16;
    address mintConfigMasterAddress = 0xa65B253C01cBFb156c63371bb732137a3a77bA52;
    address pauserAddress = 0x70aC9FA233435d1b764DF4e6d2F5C94eB0551918;

    ExecutionDelegate executionDelegate = ExecutionDelegate(executionDelegateAddress);
    Minter minter = Minter(minterAddress);
    Exchange exchange = Exchange(exchangeAddress);

    IBlast blastGas = IBlast(blastGasAddress);
    IBlastPoints blastPoints = IBlastPoints(blastPointsAddress);

    FantasyCards fantasyCards;

    address oldFantasyCardsAddress = 0x0908f097497054A753763Fa40e1D2c216F9B3847;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PK");

        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deployer: ", address(deployer));

        vm.startBroadcast(deployerPrivateKey);

        fantasyCards = new FantasyCards();

        minter.whiteListCollection(address(fantasyCards));
        minter.unWhiteListCollection(oldFantasyCardsAddress);

        exchange.whiteListCollection(address(fantasyCards));
        exchange.unWhiteListCollection(oldFantasyCardsAddress);

        fantasyCards.grantRole(fantasyCards.EXECUTION_DELEGATE_ROLE(), address(executionDelegate));

        fantasyCards.beginDefaultAdminTransfer(governanceAddress);

        blastGas.configureGovernorOnBehalf(address(fantasyCards), governanceAddress);
        blastPoints.configurePointsOperatorOnBehalf(address(fantasyCards), governanceAddress);

        vm.stopBroadcast();

        console.log("FantasyCards: ", address(fantasyCards));
    }
}
