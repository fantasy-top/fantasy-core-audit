pragma solidity ^0.8.20;

import "../base/BaseTest.t.sol";

contract UnWhiteListPaymentToken is BaseTest {
    function setUp() public override {
        super.setUp();
    }

    function test_successful_unWhiteListPaymentToken() public {
        exchange.whiteListPaymentToken(address(weth), 0);

        exchange.unWhiteListPaymentToken(address(weth));
        assertEq(exchange.whitelistedPaymentTokens(address(weth)), false);
    }

    function test_unsuccessful_unWhiteListPaymentToken_caller_not_owner() public {
        cheats.startPrank(user1);
        cheats.expectRevert(); // REVIEW: proper error message
        exchange.unWhiteListPaymentToken(address(weth));
        cheats.stopPrank();
    }
}
