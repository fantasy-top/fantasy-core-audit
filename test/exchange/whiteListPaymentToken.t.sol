pragma solidity ^0.8.20;

import "../base/BaseTest.t.sol";

contract WhiteListPaymentToken is BaseTest {
    function setUp() public override {
        super.setUp();
    }

    function test_successful_WhiteListPaymentToken() public {
        uint256 wethMinimumPrice = 12;
        exchange.whiteListPaymentToken(address(weth), wethMinimumPrice);

        assertEq(exchange.whitelistedPaymentTokens(address(weth)), true);
        assertEq(exchange.minimumPricePerPaymentToken(address(weth)), wethMinimumPrice);
    }

    function test_unsuccessful_WhiteListPaymentToken_caller_not_owner() public {
        cheats.startPrank(user1);
        cheats.expectRevert(); // REVIEW: proper error message
        exchange.whiteListPaymentToken(address(weth), 0);
        cheats.stopPrank();
    }
}
