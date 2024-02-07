pragma solidity ^0.8.20;

import "../base/BaseTest.t.sol";

contract SetTreasury is BaseTest {
    function setUp() public override {
        super.setUp();
    }

    function test_successful_setTreasury() public {
        assertEq(minter.treasury(), treasury);

        // Act
        minter.setTreasury(user1);

        // Assert
        assertEq(minter.treasury(), user1);
    }

    function test_unsuccessful_setTreasury_address_zero() public {
        cheats.expectRevert("Treasury address cannot be 0x0"); // REVIEW: proper error message?
        minter.setTreasury(address(0));
    }

    function test_unauthorized_setTreasury() public {
        cheats.startPrank(user1);
        cheats.expectRevert(); // REVIEW: proper error message?
        minter.setTreasury(user1);
        cheats.stopPrank();
    }
}
