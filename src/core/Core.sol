// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;

import "../../lib/openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import "./CorePermissions.sol";
import "./CoreStorage.sol";
import "./ICore.sol";

/// @notice Core maintains global parameters, instances of protocol
/// contracts, and access control across the Rift protocol
/// @author Recursive Research Inc
contract Core is ICore, CorePermissions, CoreStorage {
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 public constant override MAX_FEE = 10000;

    // ----------- Upgradeable Constructor Pattern -----------

    /// initialize logic contract
    /// This tag here tells OZ to not throw an error on this constructor
    /// Recommended here:
    /// https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#initializing_the_implementation_contract
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @notice Sets up the core with the initial access roles, and sets
    /// the initial protocol fee and feeTo
    /// @param _protocolFee initial protocol fee (out of `MAX_FEE`)
    /// @param _feeTo the fee destination address
    /// @param _wrappedNative the address of the wrapped native token of the chain
    /// @param governor intitial governor
    /// @param guardian initial guardian
    /// @param pauser initial pauser
    /// @param strategist initial strategist
    function initialize(
        uint256 _protocolFee,
        address _feeTo,
        address _wrappedNative,
        address governor,
        address guardian,
        address pauser,
        address strategist
    ) public virtual initializer {
        __Core_init(_protocolFee, _feeTo, _wrappedNative, governor, guardian, pauser, strategist);
    }

    function __Core_init(
        uint256 _protocolFee,
        address _feeTo,
        address _wrappedNative,
        address governor,
        address guardian,
        address pauser,
        address strategist
    ) internal onlyInitializing {
        __CorePermissions_init(governor, guardian, pauser, strategist);
        __Core_init_unchained(_protocolFee, _feeTo, _wrappedNative);
    }

    function __Core_init_unchained(
        uint256 _protocolFee,
        address _feeTo,
        address _wrappedNative
    ) internal onlyInitializing {
        require(_protocolFee <= MAX_FEE, "INVALID_PROTOCOL_FEE");
        require(_feeTo != address(0), "ZERO_ADDRESS");
        require(_wrappedNative != address(0), "ZERO_ADDRESS");

        protocolFee = _protocolFee;
        feeTo = _feeTo;
        wrappedNative = _wrappedNative;
    }

    // ----------- Main Core Utility --------------

    /// @notice Registers new vault contracts with Core
    /// @param vaults list of addresses of the new vault contracts
    function registerVaults(address[] memory vaults) external override onlyRole(GOVERN_ROLE) whenNotPaused {
        for (uint256 i = 0; i < vaults.length; i++) {
            require(vaults[i] != address(0), "ZERO_ADDRESS");
            // Next line returns false if the vault is already registered
            if (registeredVaults.add(vaults[i])) {
                emit VaultRegistered(vaults[i], msg.sender);
            }
        }
    }

    /// @notice Removes vault contracts from Core
    /// @param vaults list of addresses of the vaults to be removed
    function removeVaults(address[] memory vaults) external override onlyRole(GOVERN_ROLE) whenNotPaused {
        for (uint256 i = 0; i < vaults.length; i++) {
            // Next line returns false if the vault is already registered
            if (registeredVaults.remove(vaults[i])) {
                emit VaultRemoved(vaults[i], msg.sender);
            }
        }
    }

    /// @notice Sets the new protocol fee
    /// @param _protocolFee new protocol fee (out of `MAX_FEE`)
    function setProtocolFee(uint256 _protocolFee) external override onlyRole(GOVERN_ROLE) whenNotPaused {
        require(_protocolFee <= MAX_FEE, "INVALID_PROTOCOL_FEE");
        protocolFee = _protocolFee;
        emit ProtocolFeeUpdated(_protocolFee);
    }

    /// @notice Sets the new fee destination
    /// @param _feeTo new fee destination
    function setFeeTo(address _feeTo) external override onlyRole(GOVERN_ROLE) whenNotPaused {
        require(_feeTo != address(0), "ZERO_ADDRESS");
        feeTo = _feeTo;
        emit FeeToUpdated(_feeTo);
    }

    // ----------- Getters for Registered Core References -----------

    /// @notice Returns a list of registered vault addresses
    function getRegisteredVaults() external view override returns (address[] memory) {
        return registeredVaults.values();
    }

    /// @notice Checks to see if a given address is registered with Core as a vault
    /// @param vault address to check
    function isRegistered(address vault) external view override returns (bool) {
        return registeredVaults.contains(vault);
    }

    // ----------- Protocol Pausing -----------

    modifier whenNotPaused() {
        require(!paused, "PAUSED");
        _;
    }

    modifier whenPaused() {
        require(paused, "NOT_PAUSED");
        _;
    }

    /// @notice Pauses the Rift protocol, including all RiftInstance contracts
    /// that point to this instance of the Core
    function pause() external override onlyRole(PAUSE_ROLE) whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    /// @notice Unpauses the Rift protocol, including all RiftInstance contracts
    /// that point to this instance of the Core
    function unpause() external override onlyRole(PAUSE_ROLE) whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }
}