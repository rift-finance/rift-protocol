// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.11;

import { TransparentUpgradeableProxy } from "../../lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { ProxyAdmin } from "../../lib/openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
import { RiftTest } from "./utils/CoreUtils.sol";
import { Rift } from "../token/Rift.sol";
// import { IRift } from "../token/IRift.sol";

import { StringsUpgradeable } from "../../lib/openzeppelin-contracts-upgradeable/contracts/utils/StringsUpgradeable.sol";

contract RiftTokenTest is RiftTest {
    address public owner = vm.addr(1);

    ProxyAdmin public proxyAdmin;
    Rift public riftImpl;
    Rift public rift;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    function setUp() public {
        proxyAdmin = new ProxyAdmin();
        riftImpl = new Rift();
        rift = Rift(
            address(
                new TransparentUpgradeableProxy(
                    address(riftImpl),
                    address(proxyAdmin),
                    abi.encodeWithSignature("initialize(address)", owner)
                )
            )
        );
    }

    function test_initialParams() public {
        assertEq(owner, rift.owner());
        assertEq(MINTER_ROLE, rift.MINTER_ROLE());
        assertEq(BURNER_ROLE, rift.BURNER_ROLE());
        assertEq(DEFAULT_ADMIN_ROLE, rift.DEFAULT_ADMIN_ROLE());
        assertTrue(!rift.hasRole(DEFAULT_ADMIN_ROLE, address(this)));
        assertTrue(rift.hasRole(DEFAULT_ADMIN_ROLE, owner));
    }

    function test_ownerCanAddMinter() public {
        vm.prank(owner);
        rift.grantRole(MINTER_ROLE, address(this));

        assertTrue(rift.hasRole(MINTER_ROLE, address(this)));
    }

    function test_ownerCanAddBurner() public {
        vm.prank(owner);
        rift.grantRole(BURNER_ROLE, address(this));

        assertTrue(rift.hasRole(BURNER_ROLE, address(this)));
    }

    function test_ownerCanRevokeMinter() public {
        vm.prank(owner);
        rift.grantRole(MINTER_ROLE, address(this));

        vm.prank(owner);
        rift.revokeRole(MINTER_ROLE, address(this));
        assertTrue(!rift.hasRole(MINTER_ROLE, address(this)));
    }

    function test_ownerCanRevokeBurner() public {
        vm.prank(owner);
        rift.grantRole(BURNER_ROLE, address(this));

        vm.prank(owner);
        rift.revokeRole(BURNER_ROLE, address(this));
        assertTrue(!rift.hasRole(BURNER_ROLE, address(this)));
    }

    function test_cannotRevokeNonMinter() public {
        vm.prank(owner);
        vm.expectRevert("AccessControl: can only renounce roles for self");
        rift.renounceRole(MINTER_ROLE, address(this));
    }

    function test_cannotRevokeNonBurner() public {
        vm.prank(owner);
        vm.expectRevert("AccessControl: can only renounce roles for self");
        rift.renounceRole(BURNER_ROLE, address(this));
    }

    function test_cannotMintWithoutPermissions() public {
        vm.expectRevert(_accessErrorString(MINTER_ROLE, address(this)));
        rift.mint(address(this), 100);
    }

    function test_cannotBurnWithoutPermissions() public {
        vm.expectRevert(_accessErrorString(BURNER_ROLE, address(this)));
        rift.burnFrom(address(this), 100);
    }

    function test_canMintAsMinter() public {
        vm.prank(owner);
        rift.grantRole(MINTER_ROLE, address(this));

        rift.mint(address(this), 100);
        assertEq(rift.balanceOf(address(this)), 100);
    }

    function test_canBurnAsBurner() public {
        vm.prank(owner);
        rift.grantRole(MINTER_ROLE, address(this));
        rift.mint(address(this), 100);
        rift.increaseAllowance(address(this), 100);

        vm.prank(owner);
        rift.grantRole(BURNER_ROLE, address(this));
        rift.burnFrom(address(this), 100);

        assertEq(rift.balanceOf(address(this)), 0);
    }

    // utils
    function _accessErrorString(bytes32 role, address account) internal pure returns (bytes memory) {
        return
            bytes(
                abi.encodePacked(
                    "AccessControl: account ",
                    StringsUpgradeable.toHexString(uint160(account), 20),
                    " is missing role ",
                    StringsUpgradeable.toHexString(uint256(role), 32)
                )
            );
    }
}
