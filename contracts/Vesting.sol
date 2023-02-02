// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IERC20.sol";

contract Vesting {
    IERC20 public immutable token;
    address public immutable pool;
    uint256 public totalBalance;
    uint256 public allocatedBalance;
    address public owner;
    mapping(address => uint256) public balanceOf;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(address _token, address _pool) {
        token = IERC20(_token);
        pool = _pool;
        owner = msg.sender;
    }

    function fund(uint256 _amount) external {
        require(_amount > 0, "amount = 0!");
        require(token.allowance(msg.sender, address(this)) >= _amount, "Insufficient allowance!");
        token.transferFrom(msg.sender, address(this), _amount);
        totalBalance += _amount;
    }

    function allocate(address _user, uint256 _amount) external onlyOwner {
        require(allocatedBalance + _amount <= totalBalance, "Insufficient available balance!");
        balanceOf[_user] = _amount;
        allocatedBalance += _amount;
    }

    function claim() public {

    }

}