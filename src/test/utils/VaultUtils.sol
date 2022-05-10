// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.11;

import { IERC20 } from "../../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { IUniswapV2Factory } from "../../../lib/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import { IUniswapV2Router02 } from "../../../lib/v2-periphery/contracts//interfaces/IUniswapV2Router02.sol";
import { IUniswapV2Pair } from "../../../lib/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

import { UniswapVault } from "../../vaults/uniswap/UniswapVault.sol";

import { CoreFixture } from "./CoreUtils.sol";
import { C } from "./Constants.sol";

contract UniswapV2Fixture is CoreFixture {
    // TODO: Refactor to use deployCode from forge-std
    IUniswapV2Factory public factory = IUniswapV2Factory(C.uniswapFactory);
    IUniswapV2Router02 public router = IUniswapV2Router02(C.uniswapRouter);
}

abstract contract BasicVaultTest is UniswapV2Fixture {
    uint256 public amount = C.amount;
    address public trader = vm.addr(19);

    IERC20 public token0;
    IERC20 public token1;
    IUniswapV2Pair public pair;

    // a simple uniswap vault regardless of vault type, since it includes
    // all necessary callable functions for any vault. Any specific functions
    // or state variable tests should be tested in the inherited contract
    UniswapVault public vault;

    function setUp() public override {
        super.setUp();
        createTokensAndDexPair();
        vault = UniswapVault(payable(deployVault()));
    }

    /////////////////////////// VIRTUAL FUNCTIONS ///////////////////////////////

    // can choose weth as base or some arbitrary token
    function createTokensAndDexPair() internal virtual {}

    // deploys the vault with chosen parameters
    function deployVault() internal virtual returns (address) {}

    // allows tests to acquire tokens for various purposes, different if it's a simple erc20 or WETH
    function getToken0(address _user, uint256 _amount) internal virtual;

    function getToken1(address _user, uint256 _amount) internal virtual;

    ///////////////////////////// BASIC TESTS ////////////////////////////////////
    /// These tests should pass regardless of vault type and parameters chosen ///
    function test_initParams() public {
        assertEq(address(pair), factory.getPair(address(token0), address(token1)));
        assertTrue(vault.isNativeVault() == (address(token0) == C.WETH));
    }

    function test_depositZeroAmountRevert() public {
        vm.expectRevert("ZERO_AMOUNT");
        vault.depositToken0(0);
    }

    function test_depositNonNativeToken0WithValueRevert() public {
        if (!vault.isNativeVault()) {
            vm.expectRevert("NOT_NATIVE_VAULT");
            vault.depositToken0{ value: 1 }(0);
        }
    }

    function test_depositToken0() public {
        depositToken0();
        assertEq(getToken0UserPendingDeposit(), amount);
        assertEq(getToken0DepositRequests(), amount);
    }

    function test_depositToken1() public {
        depositToken1();
        assertEq(getToken1UserPendingDeposit(), amount);
        assertEq(getToken1DepositRequests(), amount);
    }

    function test_depositTwiceInOneEpoch() public {
        depositToken0();
        depositToken0();

        assertEq(getToken0UserPendingDeposit(), amount * 2);
        assertEq(getToken0DepositRequests(), amount * 2);
    }

    function test_depositAcrossMultipleEpochs() public {
        depositToken0();
        assertEq(getToken0UserPendingDeposit(), amount);
        assertEq(getToken0DepositRequests(), amount);

        advance();

        depositToken0();
        assertEq(getToken0UserPendingDeposit(), amount);
        assertEq(getToken0UserDeposited(), amount);
        assertEq(getToken0DepositRequests(), amount);
    }

    function test_withdrawZeroAmountRevert() public {
        vm.expectRevert("ZERO_AMOUNT");
        vault.withdrawToken0(0);
    }

    function test_withdrawTooMuch() public {
        depositToken0();
        advance();

        uint256 token0BalanceDay0 = vault.token0BalanceDay0(address(this));

        vm.expectRevert("INSUFFICIENT_BALANCE");
        vault.withdrawToken0(token0BalanceDay0 + 1);
    }

    function test_simpleWithdraw() public {
        depositToken0();
        advance();

        withdrawToken0();
        assertEq(getToken0UserWithdrawRequests(), amount);
        assertEq(getToken0UserClaimable(), 0);

        advance();
        assertEq(getToken0UserWithdrawRequests(), 0);
        assertEq(getToken0UserClaimable(), amount);
    }

    function test_withdrawTwiceInOneEpoch() public {
        depositToken0();
        advance();

        uint256 token0BalanceDay0 = vault.token0BalanceDay0(address(this));
        vault.withdrawToken0(token0BalanceDay0 / 2);
        vault.withdrawToken0(token0BalanceDay0 - token0BalanceDay0 / 2);

        advance();
        assertEq(getToken0UserClaimable(), amount);
    }

    function test_withdrawAcrossMultipleEpochs() public {
        depositToken0();
        advance();

        uint256 token0BalanceDay0 = vault.token0BalanceDay0(address(this));
        vault.withdrawToken0(token0BalanceDay0 / 2);

        advance();
        vault.withdrawToken0(token0BalanceDay0 - token0BalanceDay0 / 2);

        advance();
        assertEq(getToken0UserClaimable(), amount);
    }

    function test_claimZeroAmountRevert() public {
        vm.expectRevert("NO_CLAIM");
        claimToken0();
    }

    function test_claimTwiceInOneEpochRevert() public {
        depositToken0();
        advance();

        withdrawToken0();
        advance();

        claimToken0();

        vm.expectRevert("NO_CLAIM");
        claimToken0();
    }

    function test_simpleClaim() public {
        depositToken0();
        advance();

        withdrawToken0();
        advance();

        assertEq(getToken0UserClaimable(), amount);
        uint256 token0BalanceBefore = token0Balance(address(this));

        claimToken0();
        assertEq(getToken0UserClaimable(), 0);
        uint256 token0BalanceAfter = token0Balance(address(this));
        assertEq(token0BalanceAfter - token0BalanceBefore, amount);
    }

    function test_advanceWithNoToken0Deposits() public {
        depositToken1();
        advance();

        assertEq(getToken1UserDeposited(), amount);
        assertEq(getToken1UserPendingDeposit(), 0);
        assertEq(getToken1UserClaimable(), 0);

        assertEq(getToken1Reserves(), amount);
        assertEq(getToken1Active(), 0);
    }

    function test_advanceWithNoToken1Deposits() public {
        depositToken0();
        advance();

        assertEq(getToken0UserDeposited(), amount);
        assertEq(getToken0UserPendingDeposit(), 0);
        assertEq(getToken0UserClaimable(), 0);

        assertEq(getToken0Reserves(), amount);
        assertEq(getToken0Active(), 0);
    }

    function test_nextEpochWithBadReservesRevert() public {
        (uint256 reserves0, uint256 reserves1) = getPairReserves();

        vm.startPrank(strategist);
        vm.expectRevert("UNEXPECTED_POOL_BALANCES");
        vault.nextEpoch(0, reserves1);

        vm.expectRevert("UNEXPECTED_POOL_BALANCES");
        vault.nextEpoch(reserves0 * 2, reserves1);

        vm.expectRevert("UNEXPECTED_POOL_BALANCES");
        vault.nextEpoch(reserves0, 0);

        vm.expectRevert("UNEXPECTED_POOL_BALANCES");
        vault.nextEpoch(reserves0, reserves1 * 2);
    }

    function test_dontDepositLessThanMIN_LPt0() public {
        depositToken0();
        depositToken1();

        advance();

        assertGt(getToken0Active(), 0);
        assertGt(getToken1Active(), 0);

        uint256 token0BalanceDay0 = vault.token0BalanceDay0(address(this));
        vault.withdrawToken0(token0BalanceDay0 - 100);

        advance();

        assertEq(getToken0Active(), 0);
        assertEq(getToken1Active(), 0);
    }

    function test_dontDepositLessThanMIN_LPt1() public {
        depositToken0();
        depositToken1();

        advance();

        assertGt(getToken0Active(), 0);
        assertGt(getToken1Active(), 0);

        uint256 token1BalanceDay0 = vault.token1BalanceDay0(address(this));
        vault.withdrawToken1(token1BalanceDay0 - 100);

        advance();

        assertEq(getToken0Active(), 0);
        assertEq(getToken1Active(), 0);
    }

    function test_canRescueTokens() public {
        depositToken0();
        depositToken1();

        vm.prank(pauser);
        vault.pause();

        vm.prank(guardian);
        vault.rescueTokens(toArray(address(token0), address(token1)), toArray(0, 0));

        assertEq(token0.balanceOf(guardian), amount);
        assertEq(token1.balanceOf(guardian), amount);
    }

    function test_paused() public {
        vm.startPrank(pauser);

        core.pause();
        assertTrue(vault.paused());

        core.unpause();
        assertTrue(!vault.paused());

        vault.pause();
        assertTrue(vault.paused());
        vm.stopPrank();
    }

    /////////////////////////// Utility Functions ////////////////////////////////
    function getToken0UserDeposited() internal view returns (uint256 deposited) {
        (deposited, , ) = vault.token0Balance(address(this));
    }

    function getToken1UserDeposited() internal view returns (uint256 deposited) {
        (deposited, , ) = vault.token1Balance(address(this));
    }

    function getToken0UserPendingDeposit() internal view returns (uint256 pd) {
        (, pd, ) = vault.token0Balance(address(this));
    }

    function getToken1UserPendingDeposit() internal view returns (uint256 pd) {
        (, pd, ) = vault.token1Balance(address(this));
    }

    function getToken0UserClaimable() internal view returns (uint256 claimable) {
        (, , claimable) = vault.token0Balance(address(this));
    }

    function getToken1UserClaimable() internal view returns (uint256 claimable) {
        (, , claimable) = vault.token1Balance(address(this));
    }

    function getToken0UserWithdrawRequests() internal view returns (uint256 wr) {
        wr = vault.token0WithdrawRequests(address(this));
    }

    function getToken1UserWithdrawRequests() internal view returns (uint256 wr) {
        wr = vault.token1WithdrawRequests(address(this));
    }

    function getToken0Reserves() internal view returns (uint256 reserves) {
        (reserves, , , , ) = vault.token0Data();
    }

    function getToken1Reserves() internal view returns (uint256 reserves) {
        (reserves, , , , ) = vault.token1Data();
    }

    function getToken0Active() internal view returns (uint256 active) {
        (, active, , , ) = vault.token0Data();
    }

    function getToken1Active() internal view returns (uint256 active) {
        (, active, , , ) = vault.token1Data();
    }

    function getToken0DepositRequests() internal view returns (uint256 depositRequests) {
        (, , depositRequests, , ) = vault.token0Data();
    }

    function getToken1DepositRequests() internal view returns (uint256 depositRequests) {
        (, , depositRequests, , ) = vault.token1Data();
    }

    function getToken0WithdrawRequests() internal view returns (uint256 withdrawRequests) {
        (, , , withdrawRequests, ) = vault.token0Data();
    }

    function getToken1WithdrawRequests() internal view returns (uint256 withdrawRequests) {
        (, , , withdrawRequests, ) = vault.token1Data();
    }

    function getToken0Claimable() internal view returns (uint256 claimable) {
        (, , , , claimable) = vault.token0Data();
    }

    function getToken1Claimable() internal view returns (uint256 claimable) {
        (, , , , claimable) = vault.token1Data();
    }

    function depositToken0() internal {
        getToken0(address(this), amount);
        if (vault.isNativeVault()) {
            weth.withdraw(amount);
            vault.depositToken0{ value: amount }(0);
        } else {
            token0.approve(address(vault), amount);
            vault.depositToken0(amount);
        }
    }

    function depositToken1() internal {
        getToken1(address(this), amount);
        token1.approve(address(vault), amount);
        vault.depositToken1(amount);
    }

    function claimToken0() internal {
        vault.claimToken0();
    }

    function claimToken1() internal {
        vault.claimToken1();
    }

    function withdrawToken0() internal {
        uint256 token0BalanceDay0 = vault.token0BalanceDay0(address(this));
        vault.withdrawToken0(token0BalanceDay0);
    }

    function withdrawToken1() internal {
        uint256 token1BalanceDay0 = vault.token1BalanceDay0(address(this));
        vault.withdrawToken1(token1BalanceDay0);
    }

    function advance() internal {
        (uint256 reserves0, uint256 reserves1) = getPairReserves();

        vm.prank(strategist);
        vault.nextEpoch(reserves0, reserves1);
    }

    function token0Balance(address _user) internal view virtual returns (uint256 balance) {
        balance = token0.balanceOf(_user);
    }

    function token1Balance(address _user) internal view virtual returns (uint256 balance) {
        balance = token1.balanceOf(_user);
    }

    function getPairReserves() internal view returns (uint256 reserves0, uint256 reserves1) {
        (uint256 r0, uint256 r1, ) = pair.getReserves();
        (reserves0, reserves1) = pair.token0() == address(vault.token0()) ? (r0, r1) : (r1, r0);
    }

    function adjustPoolRatio(uint256 targetRatio) internal {
        // targetRatio: multiplied by 1e27 to manage fractions
        // approximates pool ratio, not exactly
        (uint256 reserves0, uint256 reserves1) = getPairReserves();
        uint256 targetToken1 = sqrt((reserves0 * reserves1 * C.RAY) / targetRatio);
        uint256 targetToken0 = (targetRatio * targetToken1) / C.RAY;

        if (targetToken0 > reserves0) {
            uint256 amountIn = targetToken0 - reserves0;
            getToken0(trader, amountIn);
            vm.startPrank(trader);
            token0.approve(address(router), amountIn);
            router.swapExactTokensForTokens(
                amountIn,
                0,
                toArray(address(token0), address(token1)),
                trader,
                block.timestamp
            );
            vm.stopPrank();
        } else {
            uint256 amountIn = targetToken1 - reserves1;
            getToken1(trader, amountIn);
            vm.startPrank(trader);
            token1.approve(address(router), amountIn);
            router.swapExactTokensForTokens(
                amountIn,
                0,
                toArray(address(token1), address(token0)),
                trader,
                block.timestamp
            );
            vm.stopPrank();
        }
    }

    function simulateFees(uint256 token0Amount, uint256 token1Amount) internal {
        getToken0(address(pair), token0Amount);
        getToken1(address(pair), token1Amount);
        pair.sync();
    }
}
