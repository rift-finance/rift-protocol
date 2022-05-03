// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.11;

import "../../lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";
import "../../lib/openzeppelin-contracts-upgradeable/contracts/access/IAccessControlUpgradeable.sol";
import "../../lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol";
import "../../lib/openzeppelin-contracts-upgradeable/contracts/governance/utils/IVotesUpgradeable.sol";

interface IRift is IERC20Upgradeable, IERC20PermitUpgradeable, IAccessControlUpgradeable, IVotesUpgradeable {
    function owner() external;

    function pendingOwner() external;

    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;

    function transferOwnership(address _pendingOwner) external;

    function acceptOwnership() external;
}
