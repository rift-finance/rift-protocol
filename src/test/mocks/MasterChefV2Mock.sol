// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;

import "../../../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "./TestToken.sol";

contract MasterChefV2Mock is ERC20("SUSHI", "Sushiswap Token") {
    struct UserInfo {
        uint256 amount;
        int256 rewardDebt;
    }

    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    mapping(uint256 => address) public lpToken;
    mapping(uint256 => TestToken) public rewardToken;
    mapping(uint256 => mapping(address => uint256)) accumulatedRewards;

    function addPool(
        uint256 _pid,
        address _token,
        address _rewardToken
    ) public {
        require(lpToken[_pid] == address(0), "already registered pid");
        lpToken[_pid] = _token;
        rewardToken[_pid] = TestToken(_rewardToken);
    }

    function giveRewards(
        uint256 _pid,
        address user,
        uint256 amount
    ) public {
        accumulatedRewards[_pid][user] += amount;
    }

    function deposit(
        uint256 _pid,
        uint256 _amount,
        address _to
    ) public {
        IERC20 _lpToken = IERC20(lpToken[_pid]);
        _lpToken.transferFrom(msg.sender, address(this), _amount);
        userInfo[_pid][_to].amount += _amount;
    }

    function withdrawAndHarvest(
        uint256 _pid,
        uint256 _amount,
        address _to
    ) public {
        IERC20 _lpToken = IERC20(lpToken[_pid]);
        userInfo[_pid][msg.sender].amount -= _amount;
        mint(msg.sender, _amount);
        rewardToken[_pid].giveTokensTo(
            msg.sender,
            accumulatedRewards[_pid][msg.sender]
        );
        _lpToken.transfer(_to, _amount);
    }

    function mint(address user, uint256 amount) public {
        _mint(user, amount);
    }
}
