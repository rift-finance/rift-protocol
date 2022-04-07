// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.11;

import { IERC20 } from "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { TransparentUpgradeableProxy } from "../../lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { IUniswapV2Pair } from "../../lib/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

import { UniswapVault } from "../vaults/uniswap/UniswapVault.sol";

import { BasicVaultTest } from "./utils/VaultUtils.sol";
import { TestToken } from "./mocks/TestToken.sol";
import { C } from "./utils/Constants.sol";

contract NativeVaultTest is BasicVaultTest {
    UniswapVault public uniswapVaultImpl;

    /////////////////// DEFINE VIRTUAL FUNCTIONS ///////////////////////////
    function createTokensAndDexPair() internal override {
        token0 = IERC20(address(weth));
        token1 = IERC20(address(new TestToken("Test Token 1", "TT1")));
        pair = IUniswapV2Pair(factory.createPair(address(token0), address(token1)));

        getToken0(trader, amount);
        getToken1(trader, amount);

        vm.startPrank(trader);

        token0.approve(address(router), amount);
        token1.approve(address(router), amount);
        router.addLiquidity(address(token0), address(token1), amount, amount, 0, 0, trader, block.timestamp);

        vm.stopPrank();
    }

    function deployVault() internal override returns (address vault) {
        uniswapVaultImpl = new UniswapVault();
        vault = address(
            new TransparentUpgradeableProxy(
                address(uniswapVaultImpl),
                address(proxyAdmin),
                abi.encodeWithSignature(
                    "initialize(address,uint256,address,address,uint256,uint256,address,address)",
                    address(core),
                    0,
                    address(token0),
                    address(token1),
                    10_000,
                    500,
                    address(factory),
                    address(router)
                )
            )
        );
    }

    function getToken0(address user, uint256 amount) internal override {
        vm.deal(user, amount);
        vm.prank(user);
        weth.deposit{ value: amount }();
    }

    function getToken1(address user, uint256 amount) internal override {
        TestToken(address(token1)).giveTokensTo(user, amount);
    }

    // override because it's not an erc20
    function token0Balance(address _user) internal view override returns (uint256 balance) {
        balance = _user.balance;
    }

    // to receive eth
    receive() external payable {}

    /////////////////// TESTS SPECIFIC TO THIS DEPLOYMENT ///////////////////////
    // don't need many here, we're just testing that standard deposits, withdraws, and claims
    // (i.e. what's tested by BasicVaultTest) can work with a native vault

    function test_collectProtocolFeeAfterProfit() public {
        vm.prank(governor);
        core.setProtocolFee(1000);

        depositToken0();
        depositToken1();
        advance();

        simulateFees(amount, amount);
        withdrawToken0();
        withdrawToken1();

        advance();

        (uint256 token0Fees, uint256 token1Fees) = vault.feesAccrued();
        assertTrue(token0Fees > 0);
        assertEq(token1Fees, 0);

        vault.collectFees();
        assertEq(token0.balanceOf(feeTo), token0Fees);
        assertEq(token1.balanceOf(feeTo), token1Fees);
    }
}
