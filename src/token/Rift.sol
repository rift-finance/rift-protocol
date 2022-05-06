// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.11;

import "../../lib/openzeppelin-contracts-upgradeable/contracts/access/AccessControlUpgradeable.sol";
import "../../lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC20VotesUpgradeable.sol";

import "./IRift.sol";

contract Rift is AccessControlUpgradeable, ERC20VotesUpgradeable {
    uint216[400] private __gap; // in case we want to extend the contract in the future
    address public owner;
    address public pendingOwner;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    event OwnershipTransferInitiated(address owner, address pendingOwner);
    event OwnershipTransferred(address oldOwner, address newOwner);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(address _owner) public initializer {
        owner = _owner;
        __ERC20_init("RIFT", "Rift Token");
        __AccessControl_init();
        __ERC20Permit_init("Rift Token");
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "ONLY_OWNER");
        _;
    }

    // ----------- Ownership -----------

    /// @dev Init transfer of ownership of the contract to a new account (`_pendingOwner`).
    /// @param _pendingOwner pending owner of contract
    /// Can only be called by the current owner.
    function transferOwnership(address _pendingOwner) external onlyOwner {
        pendingOwner = _pendingOwner;
        emit OwnershipTransferInitiated(owner, pendingOwner);
    }

    /// @dev Accept transfer of ownership of the contract.
    /// Can only be called by the pendingOwner.
    function acceptOwnership() external {
        require(msg.sender == pendingOwner, "ONLY_PENDING_OWNER");
        address oldOwner = owner;
        owner = pendingOwner;

        // revoke the DEFAULT ADMIN ROLE from prev owner
        _revokeRole(DEFAULT_ADMIN_ROLE, oldOwner);
        _grantRole(DEFAULT_ADMIN_ROLE, owner);

        emit OwnershipTransferred(oldOwner, owner);
    }

    // ----------- Mint / Burn -----------
    // note: users can burn their tokens

    /// @dev Mints tokens to an account.
    /// Can only be called by MINTER_ROLE.
    function mint(address account, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(account, amount);
    }

    /// @dev Destroys `amount` tokens from the caller.
    /// See {ERC20-_burn}.
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}
