// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import { DSTest } from "ds-test/test.sol";
import { Vm } from "forge-std/Vm.sol";

import { ProxyAdmin } from "../../../lib/openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
import { TransparentUpgradeableProxy } from "../../../lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import { Core } from "../../core/Core.sol";
import { WETH9 } from "../mocks/WETH9.sol";
import { C } from "./Constants.sol";

contract RiftTest is DSTest {
    Vm public constant vm = Vm(HEVM_ADDRESS);

    function toArray(address item) internal pure returns (address[] memory array) {
        array = new address[](1);
        array[0] = item;
        return array;
    }

    function toArray(address item0, address item1) internal pure returns (address[] memory array) {
        array = new address[](2);
        array[0] = item0;
        array[1] = item1;
        return array;
    }

    function toArray(uint256 item0, uint256 item1) internal pure returns (uint256[] memory array) {
        array = new uint256[](2);
        array[0] = item0;
        array[1] = item1;
        return array;
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0 (default value)
    }
}

contract WethFixture is RiftTest {
    // TODO: Refactor to use deployCode from forge-std
    WETH9 public weth = WETH9(C.WETH);
}

contract CoreFixture is WethFixture {
    address public governor;
    address public guardian;
    address public pauser;
    address public strategist;
    address public feeTo;

    ProxyAdmin public proxyAdmin;
    Core public coreImpl;
    Core public core;

    function setUp() public virtual {
        governor = vm.addr(1);
        guardian = vm.addr(2);
        pauser = vm.addr(3);
        strategist = vm.addr(4);
        feeTo = vm.addr(5);

        vm.label(governor, "Governor");
        vm.label(guardian, "Guardian");
        vm.label(pauser, "Pauser");
        vm.label(strategist, "Strategist");
        vm.label(feeTo, "feeTo");

        proxyAdmin = new ProxyAdmin();
        coreImpl = new Core();

        core = Core(
            address(
                new TransparentUpgradeableProxy(
                    address(coreImpl),
                    address(proxyAdmin),
                    abi.encodeWithSignature(
                        "initialize(uint256,address,address,address,address,address,address)",
                        0,
                        feeTo,
                        address(weth),
                        governor,
                        guardian,
                        pauser,
                        strategist
                    )
                )
            )
        );
    }
}
