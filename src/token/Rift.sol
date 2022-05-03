// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.11;

import "../../lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "../../lib/openzeppelin-contracts-upgradeable/contracts/access/AccessControlUpgradeable.sol";
import "../../lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "../../lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC20VotesUpgradeable.sol";

contract Rift is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    AccessControlUpgradeable,
    ERC20PermitUpgradeable,
    ERC20VotesUpgradeable
{
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

        // do we want to init MINTER_ROLE and BURNER_ROLE?
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
        // important to grant admin role to pendingOwner here
        _grantRole(DEFAULT_ADMIN_ROLE, pendingOwner);
        emit OwnershipTransferInitiated(owner, pendingOwner);
    }

    function acceptOwnership() external {
        require(msg.sender == pendingOwner, "NOT_PENDING_OWNER");
        address oldOwner = owner;
        owner = pendingOwner;

        // revoke the DEFAULT ADMIN ROLE from prev owner
        _revokeRole(DEFAULT_ADMIN_ROLE, oldOwner);

        emit OwnershipTransferred(oldOwner, owner);
    }

    // ----------- Mint / Burn -----------
    // note: users can burn their tokens

    function mint(address account, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(account, amount);
    }

    function burnFrom(address account, uint256 amount) public override onlyRole(BURNER_ROLE) {
        super.burnFrom(account, amount);
    }

    // ----------- The following functions are overrides required by Solidity. -----------

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
