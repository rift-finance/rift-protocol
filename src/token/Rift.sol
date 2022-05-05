// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.11;

import "../../lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "../../lib/openzeppelin-contracts-upgradeable/contracts/access/AccessControlUpgradeable.sol";
import "../../lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC20VotesUpgradeable.sol";

contract Rift is ERC20BurnableUpgradeable, AccessControlUpgradeable, ERC20VotesUpgradeable {
    address public owner;
    address public pendingOwner;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    event OwnershipTransferInitiated(address owner, address pendingOwner);
    event OwnershipTransferred(address oldOwner, address newOwner);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(address _owner) public initializer {
        owner = _owner;
        __ERC20_init("RIFT", "Rift Token");
        __ERC20Burnable_init();
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

    /// @dev Mint tokens.
    /// Can only be called by MINTER_ROLE.
    function mint(address account, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(account, amount);
    }

    /// @dev Burn tokens from a given account.
    /// Can only be called by BURNER_ROLE and requires allowance from account
    function burnFrom(address account, uint256 amount) public override onlyRole(BURNER_ROLE) {
        super.burnFrom(account, amount);
    }

    // ----------- The following functions are overrides required by Solidity. -----------
    // this ensures we use the ERC20VotesUpgradeable overrides in order to track voting power and checkpoints
    // reason this is required is because we are inheriting from both ERC20BurnableUpgradeable and ERC20VotesUpgradeable
    // which both inherit from ERC20Upgradeable

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20Upgradeable, ERC20VotesUpgradeable) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal override(ERC20Upgradeable, ERC20VotesUpgradeable) {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount) internal override(ERC20Upgradeable, ERC20VotesUpgradeable) {
        super._burn(account, amount);
    }
}
