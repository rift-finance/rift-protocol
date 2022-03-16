// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.11;

import "./ICorePermissions.sol";

/// @notice Interface for Core
/// @author Recursive Research Inc
interface ICore is ICorePermissions {
    // ----------- Events ---------------------

    /// @dev Emitted when the protocol fee (`protocolFee`) is changed
    event ProtocolFeeUpdated(uint256 indexed protocolFee);

    /// @dev Emitted when the protocol fee destination (`feeTo`) is changed
    event FeeToUpdated(address indexed feeTo);

    /// @dev Emitted when the pause is triggered by `account`.
    event Paused(address indexed account);

    /// @dev Emitted when the pause is lifted by `account`.
    event Unpaused(address indexed account);

    // @dev Emitted when a vault with address `vault` is added by `admin`
    event VaultRegistered(address indexed vault, address indexed admin);

    // @dev Emitted when a vault with address `vault` is removed by `admin`
    event VaultRemoved(address indexed vault, address indexed admin);

    // ----------- Default Getters --------------

    function MAX_FEE() external view returns (uint256);

    function feeTo() external view returns (address);

    function protocolFee() external view returns (uint256);

    function wrappedNative() external view returns (address);

    // ----------- Main Core Utility --------------

    function registerVaults(address[] memory vaults) external;

    function removeVaults(address[] memory vaults) external;

    function setProtocolFee(uint256 _protocolFee) external;

    function setFeeTo(address _feeTo) external;

    // ----------- Getters for Registered Vaults -----------

    function getRegisteredVaults() external view returns (address[] memory);

    function isRegistered(address vault) external view returns (bool);

    // ----------- Protocol Pausing -----------

    function pause() external;

    function unpause() external;

    function paused() external view returns (bool);
}
