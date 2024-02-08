pragma solidity ^0.8.20;

import "../base/BaseTest.t.sol";

contract SetMinimumPricePerPaymentToken is BaseTest {
    function setUp() public override {
        super.setUp();
    }

    function test_successful_setMininmumPricePerPaymentToken() public {
        uint256 minimumPrice = 12;
        exchange.setMinimumPricePerPaymentToken(address(weth), minimumPrice);

        assertEq(exchange.minimumPricePerPaymentToken(address(weth)), minimumPrice);
    }

        function test_unsuccessful_setMininmumPricePerPaymentToken_not_owner() public {
        uint256 minimumPrice = 12;
        cheats.startPrank(user1);
        cheats.expectRevert();
        exchange.setMinimumPricePerPaymentToken(address(weth), minimumPrice);
        cheats.stopPrank();
    }
}