// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import { IUniswapV2Pair } from "../../lib/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import { UniswapVaultFixture } from "./utils/VaultUtils.sol";

import { C } from "./utils/Constants.sol";
import "forge-std/console.sol";

contract UniswapVaultTest is UniswapVaultFixture {
    uint256 public amount = C.amount;
    address public origLp;
    IUniswapV2Pair pair;

    function setUp() public override {
        super.setUp();

        origLp = vm.addr(19);
        pair = IUniswapV2Pair(uniswapVault.pair());
        vm.startPrank(origLp);

        token0.giveMeTokens(amount);
        token1.giveMeTokens(amount);

        token0.approve(address(router), amount);
        token1.approve(address(router), amount);

        router.addLiquidity(
            address(token0),
            address(token1),
            amount,
            amount,
            0,
            0,
            address(this),
            block.timestamp
        );
        vm.stopPrank();

        token0.giveMeTokens(amount);
        token1.giveMeTokens(amount);
        token0.approve(address(uniswapVault), amount);
        token1.approve(address(uniswapVault), amount);
    }

    function test_initParams() public {
        assertEq(
            address(pair),
            factory.getPair(address(token0), address(token1))
        );
        assertTrue(uniswapVault.isNativeVault() == (address(token0) == C.WETH));
    }

    function test_depositToken0WithValue() public {
        vm.expectRevert("NOT_NATIVE_VAULT");
        uniswapVault.depositToken0{ value: 1 }(0);
    }

    function test_depositToken0() public {
        uniswapVault.depositToken0(amount);
        assertEq(getToken0PendingDeposit(), amount);
    }

    function test_depositToken1() public {
        uniswapVault.depositToken1(amount);
        assertEq(getToken1PendingDeposit(), amount);
    }

    function test_noToken1Deposits() public {
        uniswapVault.depositToken1(amount);
        advance();
    }

    function getToken0PendingDeposit() public returns (uint256 pd) {
        (, pd, ) = uniswapVault.token0Balance(address(this));
    }

    function getToken1PendingDeposit() public returns (uint256 pd) {
        (, pd, ) = uniswapVault.token1Balance(address(this));
    }

    function advance() public {
        (uint256 r0, uint256 r1, ) = pair.getReserves();
        (uint256 reserves0, uint256 reserves1) = pair.token0() ==
            address(uniswapVault.token0())
            ? (r0, r1)
            : (r1, r0);
        vm.prank(strategist);
        uniswapVault.nextEpoch(reserves0, reserves1);
    }

    function test_paused() public {
        vm.startPrank(pauser);

        core.pause();
        assertTrue(uniswapVault.paused());

        core.unpause();
        assertTrue(!uniswapVault.paused());

        uniswapVault.pause();
        assertTrue(uniswapVault.paused());
    }
}
