// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.6;

import "ds-test/test.sol";
import "../auth/authorities/RolesAuthority.sol";

contract RequiresAuth is Auth {
    bool public flag1;
    bool public flag2;

    function updateFlag1() external auth {
        flag1 = true;
    }

    function updateFlag2() external auth {
        flag2 = true;
    }
}

contract RolesAuthorityTest is DSTest {
    address self = address(this);

    RolesAuthority roles;
    address requiresAuth;

    function setUp() public {
        roles = new RolesAuthority();
        requiresAuth = address(new RequiresAuth());
    }

    function testBasics() public {
        uint8 rootRole = 0;
        uint8 adminRole = 1;
        uint8 modRole = 2;
        uint8 userRole = 3;

        roles.setUserRole(self, rootRole, true);
        roles.setUserRole(self, adminRole, true);

        assertEq32(
            bytes32(hex"0000000000000000000000000000000000000000000000000000000000000003"),
            roles.getUserRoles(self)
        );

        roles.setRoleCapability(adminRole, requiresAuth, bytes4(keccak256("updateFlag1()")), true);

        assertTrue(roles.canCall(self, requiresAuth, bytes4(keccak256("updateFlag1()"))));
        RequiresAuth(requiresAuth).updateFlag1();
        assertTrue(RequiresAuth(requiresAuth).flag1());

        roles.setRoleCapability(adminRole, requiresAuth, bytes4(keccak256("updateFlag1()")), false);
        assertTrue(!roles.canCall(self, requiresAuth, bytes4(keccak256("updateFlag1()"))));

        assertTrue(roles.doesUserHaveRole(self, rootRole));
        assertTrue(roles.doesUserHaveRole(self, adminRole));
        assertTrue(!roles.doesUserHaveRole(self, modRole));
        assertTrue(!roles.doesUserHaveRole(self, userRole));
    }

    function testRoot() public {
        assertTrue(!roles.isUserRoot(self));
        assertTrue(!roles.canCall(self, requiresAuth, bytes4(keccak256("updateFlag1()"))));

        roles.setRootUser(self, true);
        assertTrue(roles.isUserRoot(self));
        assertTrue(roles.canCall(self, requiresAuth, bytes4(keccak256("updateFlag1()"))));

        roles.setRootUser(self, false);
        assertTrue(!roles.isUserRoot(self));
        assertTrue(!roles.canCall(self, requiresAuth, bytes4(keccak256("updateFlag1()"))));
    }

    function testPublicCapabilities() public {
        assertTrue(!roles.isCapabilityPublic(requiresAuth, bytes4(keccak256("updateFlag1()"))));
        assertTrue(!roles.canCall(self, requiresAuth, bytes4(keccak256("updateFlag1()"))));

        roles.setPublicCapability(requiresAuth, bytes4(keccak256("updateFlag1()")), true);
        assertTrue(roles.isCapabilityPublic(requiresAuth, bytes4(keccak256("updateFlag1()"))));
        assertTrue(roles.canCall(self, requiresAuth, bytes4(keccak256("updateFlag1()"))));

        roles.setPublicCapability(requiresAuth, bytes4(keccak256("updateFlag1()")), false);
        assertTrue(!roles.isCapabilityPublic(requiresAuth, bytes4(keccak256("updateFlag1()"))));
        assertTrue(!roles.canCall(self, requiresAuth, bytes4(keccak256("updateFlag1()"))));
    }
}
