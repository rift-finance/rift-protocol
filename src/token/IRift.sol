// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.11;

import "../../lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";
import "../../lib/openzeppelin-contracts-upgradeable/contracts/access/IAccessControlUpgradeable.sol";
import "../../lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol";
import "../../lib/openzeppelin-contracts-upgradeable/contracts/governance/utils/IVotesUpgradeable.sol";

import "../../lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

interface IRift is
    IAccessControlUpgradeable,
    IERC20Upgradeable,
    IERC20PermitUpgradeable,
    IVotesUpgradeable,
    IERC20MetadataUpgradeable
{
    // roles
    function MINTER_ROLE() external view returns (bytes32);

    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);

    function BURNER_ROLE() external view returns (bytes32);

    // ownership

    function owner() external view returns (address);

    function pendingOwner() external view returns (address);

    function transferOwnership(address _pendingOwner) external;

    function acceptOwnership() external;

    // mint / burn

    function burn(uint256 amount) external;

    function mint(address account, uint256 amount) external;

    // erc20 extensions

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
}
