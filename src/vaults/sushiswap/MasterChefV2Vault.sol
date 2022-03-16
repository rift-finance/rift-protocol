// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;

import "../../../lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../../external/sushiswap/IMasterChefV2.sol";
import "../uniswap/UniswapVault.sol";
import "./SushiswapVaultStorage.sol";

/// @notice Contains the staking logic for MasterChefV2 Vaults
/// @author Recursive Research Inc
contract MasterChefV2Vault is UniswapVault, SushiswapVaultStorage {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function initialize(
        address coreAddress,
        uint256 _epochDuration,
        address _token0,
        address _token1,
        uint256 _token0FloorNum,
        uint256 _token1FloorNum,
        address _sushiswapFactory,
        address _sushiswapRouter,
        address _sushi,
        address _masterChefV2,
        uint256 _pid
    ) public virtual initializer {
        __MasterChefV2Vault_init(
            coreAddress,
            _epochDuration,
            _token0,
            _token1,
            _token0FloorNum,
            _token1FloorNum,
            _sushiswapFactory,
            _sushiswapRouter,
            _sushi,
            _masterChefV2,
            _pid
        );
    }

    function __MasterChefV2Vault_init(
        address coreAddress,
        uint256 _epochDuration,
        address _token0,
        address _token1,
        uint256 _token0FloorNum,
        uint256 _token1FloorNum,
        address _sushiswapFactory,
        address _sushiswapRouter,
        address _sushi,
        address _masterChefV2,
        uint256 _pid
    ) internal onlyInitializing {
        __UniswapVault_init(
            coreAddress,
            _epochDuration,
            _token0,
            _token1,
            _token0FloorNum,
            _token1FloorNum,
            _sushiswapFactory,
            _sushiswapRouter
        );
        __MasterChefV2Vault_init_unchained(_sushi, _masterChefV2, _pid);
    }

    function __MasterChefV2Vault_init_unchained(
        address _sushi,
        address _masterChefV2,
        uint256 _pid
    ) internal onlyInitializing {
        require(_sushi != address(0), "ZERO_ADDRESS");
        require(_masterChefV2 != address(0), "ZERO_ADDRESS");
        require(
            IMasterChefV2(_masterChefV2).lpToken(_pid) == address(pair),
            "INVALID_PID"
        );
        sushi = IERC20Upgradeable(_sushi);
        rewarder = _masterChefV2;
        pid = _pid;
    }

    function _unstakeLiquidity() internal virtual override {
        // withdraw from master chef v2
        uint256 depositBalance = IMasterChefV2(rewarder)
            .userInfo(pid, address(this))
            .amount;
        if (depositBalance > 0) {
            IMasterChefV2(rewarder).withdrawAndHarvest(
                pid,
                depositBalance,
                address(this)
            );
        }

        if (sushi != token0 && sushi != token1) {
            uint256 sushiBalance = sushi.balanceOf(address(this));
            if (sushiBalance > 0) {
                sushi.safeIncreaseAllowance(router, sushiBalance);
                IUniswapV2Router02(router).swapExactTokensForTokens(
                    sushiBalance,
                    0,
                    getPath(address(sushi), address(token0)),
                    address(this),
                    block.timestamp
                );
            }
        }
    }

    function _stakeLiquidity() internal virtual override {
        // take our SLP tokens and deposit them into the MasterChefV2 for rewards
        uint256 lpTokenBalance = IERC20Upgradeable(pair).balanceOf(
            address(this)
        );
        if (lpTokenBalance > 0) {
            IERC20Upgradeable(pair).safeIncreaseAllowance(
                rewarder,
                lpTokenBalance
            );
            IMasterChefV2(rewarder).deposit(pid, lpTokenBalance, address(this));
        }
    }
}
