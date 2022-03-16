// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.11;

import "../../../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract TestToken is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function giveMeTokens(uint256 amount) public {
        _mint(msg.sender, amount);
    }

    function giveTokensTo(address user, uint256 amount) public {
        _mint(user, amount);
    }
}
