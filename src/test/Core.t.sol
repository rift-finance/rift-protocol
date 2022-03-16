// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import { CoreFixture } from "./utils/CoreUtils.sol";
import { C } from "./utils/Constants.sol";

contract CoreTest is CoreFixture {
    address public user;

    function setUp() public override {
        super.setUp();
        user = vm.addr(777);
    }

    function test_initParams() public {
        assertEq(core.protocolFee(), 0);
        assertEq(core.feeTo(), feeTo);
        assertEq(core.wrappedNative(), address(weth));
        assertTrue(core.hasRole(C.GOVERN_ROLE, governor));
        assertTrue(core.hasRole(C.GUARDIAN_ROLE, guardian));
        assertTrue(core.hasRole(C.PAUSE_ROLE, pauser));
        assertTrue(core.hasRole(C.STRATEGIST_ROLE, strategist));
    }

    function test_registerVaults() public {
        address vault = vm.addr(10);
        assertTrue(!core.isRegistered(vault));

        vm.prank(governor);
        core.registerVaults(toArray(vault));
        assertTrue(core.isRegistered(vault));

        address[] memory registeredVaults = core.getRegisteredVaults();
        assertEq(registeredVaults[0], vault);
    }

    function testFail_registerVaultFromNonGovernor() public {
        address vault = vm.addr(10);

        vm.prank(user);
        core.registerVaults(toArray(vault));
    }

    function test_removeVaults() public {
        address vault = vm.addr(11);

        vm.startPrank(governor);

        core.registerVaults(toArray(vault));
        assertTrue(core.isRegistered(vault));

        core.removeVaults(toArray(vault));
        assertTrue(!core.isRegistered(vault));
    }

    function testFail_removeVaultFromNonGovernor() public {
        address vault = vm.addr(10);

        vm.prank(user);
        core.removeVaults(toArray(vault));
    }

    function test_setProtocolFee() public {
        uint256 newProtocolFee = 200;

        vm.prank(governor);

        core.setProtocolFee(newProtocolFee);
        assertEq(core.protocolFee(), newProtocolFee);
    }

    function test_setBadProtocolFee() public {
        uint256 badProtocolFee = 10_001;

        vm.prank(governor);

        vm.expectRevert("INVALID_PROTOCOL_FEE");
        core.setProtocolFee(badProtocolFee);
    }

    function testFail_setProtocolFeeFromNonGovernor() public {
        uint256 newProtocolFee = 10;

        vm.prank(user);
        core.setProtocolFee(newProtocolFee);
    }

    function test_setFeeTo() public {
        address newFeeTo = vm.addr(12);

        vm.prank(governor);

        core.setFeeTo(newFeeTo);
        assertEq(core.feeTo(), newFeeTo);
    }

    function test_setBadFeeTo() public {
        address badFeeTo = address(0);

        vm.prank(governor);

        vm.expectRevert("ZERO_ADDRESS");
        core.setFeeTo(badFeeTo);
    }

    function testFail_setFeeToFromNonGovernor() public {
        address badFeeTo = address(0);

        vm.prank(governor);
        core.setFeeTo(badFeeTo);
    }

    function test_pause() public {
        vm.startPrank(pauser);

        assertTrue(!core.paused());
        core.pause();
        assertTrue(core.paused());

        vm.expectRevert("PAUSED");
        core.pause();
    }

    function test_unpause() public {
        vm.startPrank(pauser);

        vm.expectRevert("NOT_PAUSED");
        core.unpause();

        core.pause();
        assertTrue(core.paused());

        core.unpause();
        assertTrue(!core.paused());
    }

    function testFail_pauseFromNonPauser() public {
        vm.prank(user);
        core.pause();
    }

    function test_createRole() public {
        bytes32 testRole = keccak256("TEST_ROLE");
        bytes32 testRoleAdmin = keccak256("TEST_ADMIN");

        vm.prank(governor);

        core.createRole(testRole, testRoleAdmin);
        assertEq(core.getRoleAdmin(testRole), testRoleAdmin);
    }

    function testFail_createRoleFromNonGovernor() public {
        bytes32 testRole = keccak256("TEST_ROLE");
        bytes32 testRoleAdmin = keccak256("TEST_ADMIN");

        vm.prank(user);
        core.createRole(testRole, testRoleAdmin);
    }

    function test_revokeLastGovernor() public {
        vm.prank(governor);

        vm.expectRevert("LAST_GOVERNOR");
        core.revokeRole(C.GOVERN_ROLE, governor);
    }

    function test_whitelistAll() public {
        address user2 = vm.addr(222);

        vm.prank(governor);
        core.whitelistAll(toArray(user, user2));

        assertTrue(core.hasRole(C.WHITELISTED_ROLE, user));
        assertTrue(core.hasRole(C.WHITELISTED_ROLE, user2));
    }

    function test_disableWhitelist() public {
        vm.startPrank(governor);

        core.disableWhitelist();
        assertTrue(core.whitelistDisabled());

        core.enableWhitelist();
        assertTrue(!core.whitelistDisabled());
    }

    function testFail_disableWhitelistFromNonGovernor() public {
        vm.startPrank(user);

        core.disableWhitelist();
    }

    function toArray(address item) internal pure returns (address[] memory) {
        address[] memory array = new address[](1);
        array[0] = item;
        return array;
    }

    function toArray(address item0, address item1)
        internal
        pure
        returns (address[] memory)
    {
        address[] memory array = new address[](2);
        array[0] = item0;
        array[1] = item1;
        return array;
    }
}
