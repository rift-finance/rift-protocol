// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import { TransparentUpgradeableProxy } from "../../lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { ProxyAdmin } from "../../lib/openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
import { RiftTest } from "./utils/CoreUtils.sol";
import { Rift } from "../token/Rift.sol";

contract RiftTokenTest is RiftTest {
  address public owner = vm.addr(1);

  ProxyAdmin public proxyAdmin;
  Rift public riftImpl;
  Rift public rift;

  function setUp() public {
    proxyAdmin = new ProxyAdmin();
    riftImpl = new Rift();
    rift = Rift(
      address(
        new TransparentUpgradeableProxy(
          address(riftImpl), 
          address(proxyAdmin), 
          abi.encodeWithSignature("initialize(address)", 
                                  owner
      ))));
  }

  function test_initialParams() public {
    assertEq(owner, rift.owner());
  }

  function testCannotAddMinterWithoutPermission() public {
    vm.expectRevert("ONLY_OWNER");
    rift.addMinter(address(this));
  }

  function testCannotAddBurnerWithoutPermission() public {
    vm.expectRevert("ONLY_OWNER");
    rift.addBurner(address(this));
  }

  function testCannotRevokeMinterWithoutPermission() public {
    vm.prank(owner);
    rift.addMinter(address(this));

    vm.expectRevert("ONLY_OWNER");
    rift.addMinter(address(this));
  }

  function testCannotRevokeBurnerWithoutPermission() public {
    vm.prank(owner);
    rift.addMinter(address(this));

    vm.expectRevert("ONLY_OWNER");
    rift.addBurner(address(this));
  }

  function test_ownerCanAddMinter() public {
    vm.prank(owner);
    rift.addMinter(address(this));

    assertTrue(rift.isMinter(address(this)));
  }

  function test_ownerCanAddBurner() public {
    vm.prank(owner);
    rift.addBurner(address(this));

    assertTrue(rift.isBurner(address(this)));
  }

  function test_ownerCanRevokeMinter() public {
    vm.prank(owner);
    rift.addMinter(address(this));

    vm.prank(owner);
    rift.revokeMinter(address(this));
    assertTrue(!rift.isMinter(address(this)));
  }

  function test_ownerCanRevokeBurner() public {
    vm.prank(owner);
    rift.addBurner(address(this));

    vm.prank(owner);
    rift.revokeBurner(address(this));
    assertTrue(!rift.isBurner(address(this)));
  }

  function test_cannotAddAlreadyMinter() public {
    vm.startPrank(owner);
    rift.addMinter(address(this));

    vm.expectRevert("ALREADY_MINTER");
    rift.addMinter(address(this));
    vm.stopPrank();
  }

  function test_cannotAddAlreadyBurner() public {
    vm.startPrank(owner);
    rift.addBurner(address(this));

    vm.expectRevert("ALREADY_BURNER");
    rift.addBurner(address(this));
    vm.stopPrank();
  }

  function test_cannotRevokeNonMinter() public {
    vm.prank(owner);
    vm.expectRevert("NOT_MINTER");
    rift.revokeMinter(address(this));
  }

  function test_cannotRevokeNonBurner() public {
    vm.prank(owner);
    vm.expectRevert("NOT_BURNER");
    rift.revokeBurner(address(this));
  }

  function test_cannotMintWithoutPermissions() public {
    vm.expectRevert("ONLY_MINTER");
    rift.mint(address(this), 100);
  }

  function test_cannotBurnWithoutPermissions() public {
    vm.expectRevert("ONLY_BURNER");
    rift.burnFrom(address(this), 100);
  }

  function test_canMintAsMinter() public {
    vm.prank(owner);
    rift.addMinter(address(this));

    rift.mint(address(this), 100);
    assertEq(rift.balanceOf(address(this)), 100);
  }

  function test_canBurnAsBurner() public {
    vm.prank(owner);
    rift.addMinter(address(this));
    rift.mint(address(this), 100);
    rift.increaseAllowance(address(this), 100);

    vm.prank(owner);
    rift.addBurner(address(this));
    rift.burnFrom(address(this), 100);

    assertEq(rift.balanceOf(address(this)), 0);
  }
}
