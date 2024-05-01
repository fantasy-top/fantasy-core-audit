pragma solidity ^0.8.20;

import "../lib/forge-std/src/Script.sol";
import "../lib/forge-std/src/console.sol";

import "../src/FantasyCards.sol";
import "../src/Exchange.sol";
import "../src/ExecutionDelegate.sol";
import "../src/Minter.sol";

import "../src/interfaces/IBlast.sol";
import "../src/interfaces/IBlastPoints.sol";

contract DeploymentSanityCheck is Script {
    address wethAddress = 0x4300000000000000000000000000000000000004;
    address blastPointsAddress = 0x2536FE9ab3F511540F2f9e2eC2A805005C3Dd800;
    address blastGasAddress = 0x4300000000000000000000000000000000000002;

    address fantasyCardsAddress = 0x0AAADCf421A3143E5cB2dDB8452c03ae595B0734;
    address executionDelegateAddress = 0xA11Bf3A1b86A977e3beAb2a2E20c67ffDE9DEF7e;
    address minterAddress = 0x86b58ca576c24F79aD1e5459aee01d40BEA22828;
    address exchangeAddress = 0x56BFb3a51A7A2D4F685e5107CEE05a58A0F1ad61;

    address treasuryAddress = 0x8Ab15fE88a00b03724aC91EE4eE1f998064F2e31;
    address governanceAddress = 0x87300D35353D21479e0c96B87D9a7997726f4c16;
    address mintConfigMasterAddress = 0xa65B253C01cBFb156c63371bb732137a3a77bA52;
    address pauserAddress = 0x70aC9FA233435d1b764DF4e6d2F5C94eB0551918;

    uint256 cardsRequiredForBurnToDraw = 15;
    uint256 cardsRequiredForLevelUp = 5;
    uint256 cardsDrawnPerBurn = 1;
    uint256 minimumPricePerPaymentToken = 1000000000000000; // 0.001 ether
    uint256 protocolFeeBps = 300; // 3%

    FantasyCards fantasyCards = FantasyCards(fantasyCardsAddress);
    ExecutionDelegate executionDelegate = ExecutionDelegate(executionDelegateAddress);
    Minter minter = Minter(minterAddress);
    Exchange exchange = Exchange(exchangeAddress);

    IBlast blastGas = IBlast(blastGasAddress);
    IBlastPoints blastPoints = IBlastPoints(blastPointsAddress);

    function run() public view {
        // --------------------------------------------
        /* Fantasy Cards Sanity Check */
        // --------------------------------------------
        // Check Execution Delegate role
        require(
            fantasyCards.hasRole(fantasyCards.EXECUTION_DELEGATE_ROLE(), executionDelegateAddress),
            "FantasyCards has the wrong ExecutionDelegate"
        );
        // Check Default Admin role
        require(
            fantasyCards.hasRole(fantasyCards.DEFAULT_ADMIN_ROLE(), governanceAddress),
            "FantasyCards has the wrong Default Admin"
        );
        // Check Gas Governor
        require(
            blastGas.governorMap(fantasyCardsAddress) == governanceAddress,
            "FantasyCards has the wrong Gas Governor"
        ); // TODO: update from deployer
        // Check Points Operator
        require(
            blastPoints.operators(fantasyCardsAddress) == governanceAddress,
            "FantasyCards has the wrong Points Operator"
        ); // TODO: update from deployer

        // --------------------------------------------
        /* Execution Delegate Sanity Check */
        // --------------------------------------------
        // Check Default Admin role
        require(
            executionDelegate.hasRole(executionDelegate.DEFAULT_ADMIN_ROLE(), governanceAddress),
            "ExecutionDelegate has the wrong Default Admin"
        );
        // Check Pauser role
        require(
            executionDelegate.hasRole(executionDelegate.PAUSER_ROLE(), pauserAddress),
            "ExecutionDelegate has the wrong Pauser"
        );
        // Check Exchange is whitelisted
        require(executionDelegate.contracts(exchangeAddress), "ExecutionDelegate has not whitelisted the Exchange");
        // Check Minter is whitelisted
        require(executionDelegate.contracts(minterAddress), "ExecutionDelegate has not whitelisted the Exchange");
        // Check Gas Governor
        require(
            blastGas.governorMap(executionDelegateAddress) == governanceAddress,
            "ExecutionDelegate has the wrong Gas Governor"
        ); // TODO: update from deployer
        // Check Points Operator
        require(
            blastPoints.operators(executionDelegateAddress) == governanceAddress,
            "ExecutionDelegate has the wrong Points Operator"
        ); // TODO: update from deployer

        // --------------------------------------------
        /* Minter Sanity Check */
        // --------------------------------------------
        // Check Default Admin role
        require(minter.hasRole(minter.DEFAULT_ADMIN_ROLE(), governanceAddress), "Minter has the wrong Default Admin");
        // Check Treasury
        require(minter.treasury() == treasuryAddress, "Minter has the wrong Treasury");
        // Check Execution Delegate
        require(
            address(minter.executionDelegate()) == executionDelegateAddress,
            "Minter has the wrong ExecutionDelegate"
        );
        // Check Mint Config Master
        require(
            minter.hasRole(minter.MINT_CONFIG_MASTER(), mintConfigMasterAddress),
            "Minter has the wrong Mint Config Master"
        );
        // Check Cards required for burn to Draw
        require(
            minter.cardsRequiredForBurnToDraw() == cardsRequiredForBurnToDraw,
            "Minter has the wrong number of Cards required for burn to draw"
        );
        // Check Cards required for level up
        require(
            minter.cardsRequiredForLevelUp() == cardsRequiredForLevelUp,
            "Minter has the wrong number of Cards required for burn to draw"
        );
        // Check Cards Drawn Per Burn
        require(minter.cardsDrawnPerBurn() == cardsDrawnPerBurn, "Minter has the wrong number of Cards drawn per burn");
        // Check Gas Governor
        require(blastGas.governorMap(minterAddress) == governanceAddress, "Minter has the wrong Gas Governor");
        // Check Points Operator
        require(blastPoints.operators(minterAddress) == governanceAddress, "Minter has the wrong Points Operator");

        // --------------------------------------------
        /* Exchange Sanity Check */
        // --------------------------------------------
        // Check Default Admin role
        require(exchange.owner() == governanceAddress, "Exchange has the wrong Default Admin");
        // Check Treasury
        require(
            exchange.protocolFeeRecipient() == treasuryAddress,
            "Exchange has the wrong Treasury (aka protocolFeeRecipient)"
        );
        // Check Execution Delegate
        require(
            address(exchange.executionDelegate()) == executionDelegateAddress,
            "Exchange has the wrong ExecutionDelegate"
        );
        // Check WETH whitelist
        require(exchange.whitelistedPaymentTokens(wethAddress), "Exchange has not whitelisted WETH");
        // Check WETH minimum price
        require(
            exchange.minimumPricePerPaymentToken(wethAddress) == minimumPricePerPaymentToken,
            "Exchange has the wrong minimum price for WETH"
        );
        // Check Protocol Fee Bps
        require(exchange.protocolFeeBps() == protocolFeeBps, "Exchange has the wrong protocolFeeBps");
        // Check Fantasy Cards is whitelisted
        require(exchange.whitelistedCollections(fantasyCardsAddress), "Exchange has not whitelisted FantasyCards");
        // Check Gas Governor
        require(blastGas.governorMap(exchangeAddress) == governanceAddress, "Exchange has the wrong Gas Governor");
        // Check Points Operator
        require(blastPoints.operators(exchangeAddress) == governanceAddress, "Exchange has the wrong Points Operator");
    }
}
