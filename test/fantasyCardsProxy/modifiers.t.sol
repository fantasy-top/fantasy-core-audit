pragma solidity ^0.8.20;

import "../base/BaseTest.t.sol";

contract proxyModifiers is BaseTest {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    function setUp() public override {
        super.setUp();
    }

    function test_nonApprovedOperatorOnApprove() public {
        cheats.startPrank(address(user1));
        cheats.expectRevert("Integrator is not approved");
        fantasyCardsProxy.approve(user2, 0);
        cheats.stopPrank();
    }

    function test_nonApprovedOperatorOnTransferFrom() public {
        cheats.startPrank(address(user1));
        cheats.expectRevert("Integrator is not approved");
        fantasyCardsProxy.transferFrom(user1, user2, 0);
        cheats.stopPrank();
    }

    function test_nonApprovedOperatorOnSafeTransferFrom() public {
        cheats.startPrank(address(user1));
        cheats.expectRevert("Integrator is not approved");
        fantasyCardsProxy.safeTransferFrom(user1, user2, 0);
        cheats.stopPrank();
    }

    function test_nonApprovedOperatorOnSafeTransferFromWithData() public {
        cheats.startPrank(address(user1));
        cheats.expectRevert("Integrator is not approved");
        fantasyCardsProxy.safeTransferFrom(user1, user2, 0, "");
        cheats.stopPrank();
    }

    function test_pause() public {
        fantasyCardsProxy.grantRole(PAUSER_ROLE, address(this));
        fantasyCardsProxy.approveIntegrator(user1);

        cheats.startPrank(address(executionDelegate));
        fantasyCards.safeMint(user1);
        cheats.stopPrank();

        fantasyCardsProxy.pause();
        cheats.startPrank(address(user1));
        cheats.expectRevert(bytes4(keccak256("EnforcedPause()")));
        fantasyCardsProxy.approve(user2, 0);
        cheats.stopPrank();
    }
}
