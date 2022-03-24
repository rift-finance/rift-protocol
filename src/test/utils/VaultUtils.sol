// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import { TransparentUpgradeableProxy } from "../../../lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { IUniswapV2Factory } from "../../../lib/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import { IUniswapV2Router02 } from "../../../lib/v2-periphery/contracts//interfaces/IUniswapV2Router02.sol";

import { UniswapVault } from "../../vaults/uniswap/UniswapVault.sol";
import { MasterChefVault } from "../../vaults/sushiswap/MasterChefVault.sol";
import { MasterChefV2Vault } from "../../vaults/sushiswap/MasterChefV2Vault.sol";

import { TestToken } from "../mocks/TestToken.sol";
import { MasterChefMock } from "../mocks/MasterChefMock.sol";
import { MasterChefV2Mock } from "../mocks/MasterChefV2Mock.sol";

import { CoreFixture } from "./CoreUtils.sol";
import { C } from "./Constants.sol";

contract UniswapFixture is CoreFixture {
    // TODO: Refactor to use deployCode from forge-std
    IUniswapV2Factory public factory = IUniswapV2Factory(C.uniswapFactory);
    IUniswapV2Router02 public router = IUniswapV2Router02(C.uniswapRouter);
}

contract UniswapVaultFixture is UniswapFixture {
    TestToken public token0;
    TestToken public token1;
    UniswapVault public uniswapVaultImpl;
    UniswapVault public uniswapVault;

    function setUp() public virtual override {
        super.setUp();

        token0 = new TestToken("Test Token 0", "TT0");
        token1 = new TestToken("Test Token 1", "TT1");

        factory.createPair(address(token0), address(token1));

        uniswapVaultImpl = new UniswapVault();
        uniswapVault = UniswapVault(
            payable(
                address(
                    new TransparentUpgradeableProxy(
                        address(uniswapVaultImpl),
                        address(proxyAdmin),
                        abi.encodeWithSignature(
                            "initialize(address,uint256,address,address,uint256,uint256,address,address)",
                            address(core),
                            1,
                            address(token0),
                            address(token1),
                            10_000,
                            500,
                            address(factory),
                            address(router)
                        )
                    )
                )
            )
        );
    }
}

contract MasterChefVaultFixture is UniswapFixture {
    TestToken public token0;
    TestToken public token1;
    MasterChefMock public masterChef;
    MasterChefVault public masterChefVaultImpl;
    MasterChefVault public masterChefVault;

    function setUp() public virtual override {
        super.setUp();

        token0 = new TestToken("Test Token 0", "TT0");
        token1 = new TestToken("Test Token 1", "TT1");
        address _pair = factory.createPair(address(token0), address(token1));

        masterChef = new MasterChefMock();
        masterChef.addPool(0, _pair);

        masterChefVaultImpl = new MasterChefVault();
        masterChefVault = MasterChefVault(
            payable(
                address(
                    new TransparentUpgradeableProxy(
                        address(masterChefVaultImpl),
                        address(proxyAdmin),
                        abi.encodeWithSignature(
                            "initialize(address,uint256,address,address,uint256,uint256,address,address,address,address,uint256)",
                            address(core),
                            1,
                            address(token0),
                            address(token1),
                            10_000,
                            500,
                            address(factory),
                            address(router),
                            address(masterChef),
                            address(masterChef),
                            0
                        )
                    )
                )
            )
        );
    }
}

contract MasterChefV2VaultFixture is UniswapFixture {
    TestToken public token0;
    TestToken public token1;
    MasterChefV2Mock public masterChefV2;
    MasterChefV2Vault public masterChefV2VaultImpl;
    MasterChefV2Vault public masterChefV2Vault;

    function setUp() public virtual override {
        super.setUp();

        token0 = new TestToken("Test Token 0", "TT0");
        token1 = new TestToken("Test Token 1", "TT1");
        address _pair = factory.createPair(address(token0), address(token1));

        masterChefV2 = new MasterChefV2Mock();
        masterChefV2.addPool(0, _pair, address(token1));

        masterChefV2VaultImpl = new MasterChefV2Vault();
        masterChefV2Vault = MasterChefV2Vault(
            payable(
                address(
                    new TransparentUpgradeableProxy(
                        address(masterChefV2VaultImpl),
                        address(proxyAdmin),
                        abi.encodeWithSignature(
                            "initialize(address,uint256,address,address,uint256,uint256,address,address,address,address,uint256)",
                            address(core),
                            1,
                            address(token0),
                            address(token1),
                            10_000,
                            500,
                            address(factory),
                            address(router),
                            address(masterChefV2),
                            address(masterChefV2),
                            0
                        )
                    )
                )
            )
        );
    }
}
