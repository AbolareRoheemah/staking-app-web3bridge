// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./ERC20.sol";

contract StakingApp { // 0xddd87726c2164cB158677810fA57746006F9c748
    address owner;
    IERC20 stakingToken;
    IERC20 rewardToken;
    uint totalStakedToken;

    mapping (address => uint) userStakeAmount;
    // mapping (address => uint) rewardPerTokenStaked;
    mapping (address => uint) userStakeReward;
    mapping (address => uint) userStakeDuration;
    mapping (address => uint) stakeEndTime;
 
    error AddressZeroDetected();
    error CantStakeZeroAmount();
    error StakeTimeElapsed();
    error StakeStillOngoing();
    error StakeDurationBelowMin();
    error InsufficientFunds();
    
    event StakeSuccessful(uint amount);
    event WithdrawalSuccessful();

    constructor(address _stakingToken, address _rewardToken) {
        owner = msg.sender;
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
    }
    // function to stake tokens
    function stake(uint _amt, uint _days_to_stake) external {
        // check that the person doesnt have an ongoing stake
        // require(stakeEndTime[msg.sender] < block.timestamp, "You have an ongoing stake");
        if (stakeEndTime[msg.sender] > block.timestamp) {
            revert StakeStillOngoing();
        }
        // check that stake is not called by zero address
        // require(msg.sender != address(0), "zero address call not allowed");
        if (msg.sender == address(0)) {
            revert AddressZeroDetected();
        }
        // check that amount is not 0
        // require(_amt > 0, "cant stake zero amount");
        if (_amt <= 0) {
            revert CantStakeZeroAmount();
        }
        // check that duration is not lower than a week
        // require(_days_to_stake >= 3600, "min stake duration is 1hour");\
        if (_days_to_stake < 7) {
            revert StakeDurationBelowMin();
        }
        // check that the staker has enough token to stake
        // require(stakingToken.balanceOf(msg.sender) >= _amt, "You dont have sufficient amount to stake");
        if (stakingToken.balanceOf(msg.sender) < _amt) {
            revert InsufficientFunds();
        }

        stakingToken.transferFrom(msg.sender, address(this), _amt);
        userStakeAmount[msg.sender] += _amt;
        totalStakedToken += _amt;
        uint durationInSec = _days_to_stake * 1 days;
        stakeEndTime[msg.sender] = block.timestamp + durationInSec;

        uint reward = calcReward(_amt, durationInSec);
        userStakeReward[msg.sender] = reward;

        emit StakeSuccessful(_amt);
    }
    
    // function to calculate staking rewards
    function calcReward(uint _stakeAmt, uint _duration) private pure returns (uint) {
        // for each token a user stakes, I want the users to get a reward of 0.02% of the token they staked per second. 
        // So for example, 
        // if they stake 10 tokens for 10sec, they will get 0.2 extra i.e (0.02 / 100) * 10sec * 10tokens staked.
        uint rwdAmount = (2 * _duration * _stakeAmt) / 10000;
        return rwdAmount;
    }

    // function to get Accrued reward of a user at a particular time
    function getRealtimeUserReward(address _user) external view returns (uint) {
        // get amount user staked
        uint userStake = userStakeAmount[_user];
        // get end time of user stake
        uint userStakeEnd = stakeEndTime[_user];
        // check if stake duration has elapsed
        if (userStakeEnd < block.timestamp) {
            return userStakeReward[_user];
        }
        // if not elapsed, calculate remaining stake reward
        uint remainingReward = calcReward(userStake, userStakeEnd - block.timestamp);
        return userStakeReward[_user] - remainingReward;
    }

    // function to withdraw on end of stake duration
    function withdrawStakePlusReward() external {
        // check that user has a stake
        require(userStakeAmount[msg.sender] > 0, "You have not staked any amount");
        // check that stake duration has ended
        require(stakeEndTime[msg.sender] < block.timestamp, "stake still ongoing");

        // send staked amount plus reward to user
        uint sendAmount = userStakeAmount[msg.sender] + userStakeReward[msg.sender];
        rewardToken.transfer(msg.sender, sendAmount);
        totalStakedToken -= userStakeAmount[msg.sender];
        userStakeAmount[msg.sender] = 0;
        stakeEndTime[msg.sender] = 0;

        
        emit WithdrawalSuccessful();
    }

    // function to get user's staked amount
    function getUserStakedAmount(address _user) external view returns (uint _amount) {
        _amount = userStakeAmount[_user];
    }

    // function to get all staked amount
    function getTotalAmountStaked() external view returns (uint _amount) {
        _amount = totalStakedToken;
    }

    // function to get time left for staking to end
    function getTimeLeftToEnd(address _user) external view returns (uint timeLeft) {
        if (stakeEndTime[_user] < block.timestamp) {
            revert StakeTimeElapsed();
        }
        timeLeft = stakeEndTime[_user] - block.timestamp;
    }
}