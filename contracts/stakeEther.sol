// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract EthStakingApp { // 0x4b24274196b47B61fff3c40a72824077CD028350
    address owner;
    uint totalStakedEther;

    mapping (address => uint) userStakeAmount;
    mapping (address => uint) userStakeReward;
    mapping (address => uint) userStakeDuration;
    mapping (address => uint) stakeEndTime;

    error AddressZeroDetected();
    error CantStakeZeroAmount();
    error StakeTimeElapsed();
    error StakeStillOngoing();
    error StakeDurationBelowMin();
    
    event StakeSuccessful(uint amount);
    event WithdrawalSuccessful();

    constructor() payable {
        owner = msg.sender;
    }

    receive() external payable { }

    // function to stake ether
    function stake(uint _days_to_stake) external payable {
        // check that the person doesnt have an ongoing stake
        if (stakeEndTime[msg.sender] > block.timestamp) {
            revert StakeStillOngoing();
        }
        // check that stake is not called by zero address
        if (msg.sender == address(0)) {
            revert AddressZeroDetected();
        }
        // check that amount is not 0
        if (msg.value <= 0) {
            revert CantStakeZeroAmount();
        }
        // check that duration is not lower than a week
        if (_days_to_stake < 7) {
            revert StakeDurationBelowMin();
        }

        userStakeAmount[msg.sender] += msg.value;
        totalStakedEther += msg.value;
        uint durationInSec = _days_to_stake * 1 days;
        stakeEndTime[msg.sender] = block.timestamp + durationInSec;

        uint reward = calcReward(msg.value, durationInSec);
        userStakeReward[msg.sender] = reward;

        emit StakeSuccessful(msg.value);
    }
    
    // function to calculate staking rewards
    function calcReward(uint _stakeAmt, uint _duration) private pure returns (uint) {
        // for each ether a user stakes, I want the users to get a reward of 0.02% of the ether they staked per second. 
        // So for example, 
        // if they stake 10 ether for 10sec, they will get 0.2 extra i.e (0.02 / 100) * 10sec * 10ethers staked.
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
        // require(userStakeAmount[msg.sender] > 0, "You have not staked any amount");
        if (userStakeAmount[msg.sender] <= 0) {
            revert CantStakeZeroAmount();
        }
        // check that stake duration has ended
        // require(stakeEndTime[msg.sender] < block.timestamp, "stake still ongoing");
        if (stakeEndTime[msg.sender] > block.timestamp) {
            revert StakeStillOngoing();
        }
        // send staked amount plus reward to user
        uint sendAmount = userStakeAmount[msg.sender] + userStakeReward[msg.sender];
        // check that contract has enough balance to pay staked amount plus reward
        require(address(this).balance >= sendAmount, "vault empty ke?");
       
        (bool ok, ) = msg.sender.call{value: sendAmount}("");
        require(ok, "call failed");
        totalStakedEther -= userStakeAmount[msg.sender];
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
        _amount = totalStakedEther;
    }

    // function to get time left for staking to end
    function getTimeLeftToEnd(address _user) external view returns (uint timeLeft) {
        if (stakeEndTime[_user] < block.timestamp) {
            revert StakeTimeElapsed();
        }
        timeLeft = stakeEndTime[_user] - block.timestamp;
    }
}