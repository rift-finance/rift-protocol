// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.11;

import "../../lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";

contract Rift is ERC20BurnableUpgradeable {
  address public owner;
  address public pendingOwner;
  mapping(address => bool) public isBurner;
  mapping(address => bool) public isMinter;

  function initialize(address _owner) public initializer {
      owner = _owner;
      __ERC20_init("RIFT", "Rift Token");
  }

  modifier onlyOwner() {
      require(msg.sender == owner, "ONLY_OWNER");
      _;
  }

  modifier onlyMinter() {
      require(isMinter[msg.sender], "ONLY_MINTER");
      _;
  }

  modifier onlyBurner() {
      require(isBurner[msg.sender], "ONLY_BURNER");
      _;
  }

  function addMinter(address _newMinter) public onlyOwner {
    require(!isMinter[_newMinter], "ALREADY_MINTER");
    isMinter[_newMinter] = true;
  }
   
  function addBurner(address _newBurner) public onlyOwner {
    require(!isBurner[_newBurner], "ALREADY_BURNER");
    isBurner[_newBurner] = true;
  }
   
  function revokeMinter(address _oldMinter) public onlyOwner {
    require(isMinter[_oldMinter], "NOT_MINTER");
    isMinter[_oldMinter] = false;
  }

  function revokeBurner(address _oldBurner) public onlyOwner {
    require(isBurner[_oldBurner], "NOT_BURNER");
    isBurner[_oldBurner] = false;
  }

  function mint(address account, uint256 amount) public onlyMinter {
    _mint(account, amount);
  }

  function burnFrom(address account, uint256 amount) public override onlyBurner {
    super.burnFrom(account, amount);
  }
}
