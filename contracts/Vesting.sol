// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

contract Vesting {
    IERC20 public immutable token;
    IUniswapV2Pair public immutable pool;
    uint256 public totalBalance;
    uint256 public allocatedBalance;
    address public owner;
    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public unlockOf;
    uint256 blacklistCount;
    mapping(uint256 => address) public blacklisted;


    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(address _token, address _pool) {
        token = IERC20(_token);
        pool = IUniswapV2Pair(_pool);
        owner = msg.sender;
    }

    function calculateCircSupply() public view returns (uint256) {
        uint256 decirculated;

        for (uint i = 0; i < blacklistCount; i++) {
            decirculated += token.balanceOf(blacklisted[i]);
        }

        return token.totalSupply() - decirculated;
    }

    function calculateMC() public view returns (uint256) {
        address token0 = pool.token0();

        (uint112 reserve0, uint112 reserve1, ) = pool.getReserves();

        if (token0 == address(token)) {
            return reserve1 * calculateCircSupply() / reserve0;
        } else {
            return reserve0 * calculateCircSupply() / reserve1;
        }
    }

    function fund(uint256 _amount) external {
        require(_amount > 0, "amount = 0!");
        require(token.allowance(msg.sender, address(this)) >= _amount, "Insufficient allowance!");
        token.transferFrom(msg.sender, address(this), _amount);
        totalBalance += _amount;
    }

    function allocate(address _user, uint256 _amount, uint256 _unlockMC) external onlyOwner {
        require(balanceOf[_user] == 0, "_user is currently vesting!");
        require(allocatedBalance + _amount <= totalBalance, "Insufficient available balance!");
        unlockOf[_user] = _unlockMC;
        balanceOf[_user] = _amount;
        allocatedBalance += _amount;
    }

    function blacklist(address _user) external onlyOwner {
        blacklistCount += 1;
        blacklisted[blacklistCount] = _user;
    }

    function claim() public {
        require(calculateMC() >= unlockOf[msg.sender], "MC too low!");
        totalBalance -= balanceOf[msg.sender];
        allocatedBalance -= balanceOf[msg.sender];
        unlockOf[msg.sender] = 0;
        uint256 balance = balanceOf[msg.sender];
        balanceOf[msg.sender] = 0;
        token.transfer(msg.sender, balance);
    }

}