pragma solidity ^0.8.20;

import "../base/BaseTest.t.sol";

contract TokenUri is BaseTest {
    function setUp() public override {
        super.setUp();

        cheats.startPrank(address(executionDelegate));
        fantasyCards.safeMint(user1);
        cheats.stopPrank();
    }

    function test_tokenUri() public {
        assertEq(fantasyCards.tokenURI(0), "https://fantasy.com/0");
    }
}
