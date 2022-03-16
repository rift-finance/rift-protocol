// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;

import "../../../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract MasterChefMock is ERC20("SUSHI", "Sushiswap Token") {
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. SUSHI to distribute per block.
        uint256 lastRewardBlock; // Last block number that SUSHI distribution occurs.
        uint256 accSushiPerShare; // Accumulated SUSHI per share, times 1e12. See below.
    }

    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    mapping(uint256 => PoolInfo) public poolInfo;

    function addPool(uint256 _pid, address _token) public {
        require(
            address(poolInfo[_pid].lpToken) == address(0),
            "already registered pid"
        );
        poolInfo[_pid] = PoolInfo({
            lpToken: IERC20(_token),
            allocPoint: 0,
            lastRewardBlock: 0,
            accSushiPerShare: 0
        });
    }

    function deposit(uint256 _pid, uint256 _amount) public {
        IERC20 lpToken = poolInfo[_pid].lpToken;
        lpToken.transferFrom(msg.sender, address(this), _amount);
        userInfo[_pid][msg.sender].amount += _amount;
    }

    function withdraw(uint256 _pid, uint256 _amount) public {
        IERC20 lpToken = poolInfo[_pid].lpToken;
        userInfo[_pid][msg.sender].amount -= _amount;
        mint(msg.sender, _amount);
        lpToken.transfer(msg.sender, _amount);
    }

    function mint(address user, uint256 amount) public {
        _mint(user, amount);
    }
}
