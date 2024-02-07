pragma solidity ^0.8.20;

import "../base/BaseTest.t.sol";

contract MintFantasyCard is BaseTest {
    function setUp() public override {
        super.setUp();
    }

    function test_successful_mint_with_minter() public {
        cheats.startPrank(address(minter));
        executionDelegate.mintFantasyCard(address(fantasyCards), user1);
        cheats.stopPrank();

        assertEq(fantasyCards.ownerOf(0), user1);
        assertEq(fantasyCards.tokenCounter(), 1);
    }

    function test_unsuccesful_mint_with_unauthorised_address() public {
        cheats.startPrank(user2);
        cheats.expectRevert("Contract is not approved to make transfers");
        executionDelegate.mintFantasyCard(address(fantasyCards), user1);
        cheats.stopPrank();
    }
}
