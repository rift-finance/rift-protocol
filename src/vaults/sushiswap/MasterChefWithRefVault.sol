// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;

import "../../../lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { IMasterChefWithRef } from "../../external/sushiswap/IMasterChef.sol";
import "./MasterChefVault.sol";

/// @notice Contains the staking logic for MasterChefWithRef Vaults
/// @author Recursive Research Inc
contract MasterChefWithRefVault is MasterChefVault {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @dev the only difference here is the additional `_ref` argument in the deposit function
    function _stakeLiquidity() internal virtual override {
        // take our SLP tokens and deposit them into the MasterChef for SUSHI rewards
        uint256 lpTokenBalance = IERC20Upgradeable(pair).balanceOf(
            address(this)
        );
        if (lpTokenBalance > 0) {
            IERC20Upgradeable(pair).safeIncreaseAllowance(
                rewarder,
                lpTokenBalance
            );
            IMasterChefWithRef(rewarder).deposit(
                pid,
                lpTokenBalance,
                address(0)
            );
        }
    }
}
