// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";

contract legacyFarm {

    struct farmEntity {
        uint value;
        uint depositTime;
        uint plusRewards;
        bool claimedBeforeTotalUnlock;
    }

    modifier onlyOwner() {
        require(msg.sender==owner, "You are not allowed to do that.");
        _;
    }

    // Address variables
    address public owner;
    address public lpAddress;
    address public tokenAddress;

    // Reward variables
    uint public startingTime;
    uint public unlockPerEpoch = 2;
    uint public epochLength = 36000*24*7;
    uint public epochAPR;
    uint public epochAPRdivisor;
    uint public ratio;
    uint[] public multiplicatorCalendar;
    uint public endOfCalendar;

    mapping(address => farmEntity) public farms;

    constructor() {
        owner = msg.sender;
        startingTime = block.timestamp;
    }

    function defLPAddress(address _lpAddress) external onlyOwner {
        lpAddress = _lpAddress;
    }

    function defTokenAddress(address _tokenAddress) external onlyOwner {
        tokenAddress = _tokenAddress;
    }

    function defUnlockPerEoch(uint _unlockPerEpoch) external onlyOwner {
        unlockPerEpoch = _unlockPerEpoch;
    }

    function defEpochAPR(uint _epochAPR, uint _epochAPRdivisor) external onlyOwner {
        epochAPR = _epochAPR;
        epochAPRdivisor = _epochAPRdivisor;
    }

    function defCalendar(uint[] memory _calendar) external onlyOwner {
        multiplicatorCalendar = _calendar;
        endOfCalendar = startingTime+multiplicatorCalendar.length*epochLength;
    }

    function farm(uint _amount) public {
        IERC20 legacy = IERC20(lpAddress);

        require(legacy.allowance(msg.sender, address(this))>=_amount, "Allowance too low.");
        legacy.transferFrom(msg.sender, address(this), _amount);

        farmEntity memory userFarm = farms[msg.sender];
        userFarm.value += _amount;
        userFarm.depositTime = block.timestamp;

    }

    function unlockedPercentage(address _user) public view returns(uint) {

        if (farms[_user].claimedBeforeTotalUnlock) {
            return 0;
        }
        else {
            if (block.timestamp - startingTime < multiplicatorCalendar.length * epochLength) {
                return 5 + unlockPerEpoch*(block.timestamp - startingTime);
            }
            else {
                return 100;
            }
        } 
    }

    function rewardsOf(address _user) public view returns(uint) {

        farmEntity memory userFarm = farms[_user];
        uint rewards = userFarm.plusRewards;
        for (uint i=0; i<multiplicatorCalendar.length; i++) {

            uint epoch = startingTime + (i+1)*epochLength;
            if (epoch < block.timestamp + 1) {
                if (epoch + 1 > userFarm.depositTime) {
                    rewards += multiplicatorCalendar[i]*epochAPR*userFarm.value/epochAPRdivisor;
                }
            }
            else {
                return rewards +  multiplicatorCalendar[i]*(epochLength - (epoch-block.timestamp))/epochLength*epochAPR*userFarm.value/epochAPRdivisor;
            }
        }
        rewards += epochAPR*userFarm.value*(block.timestamp-endOfCalendar)/epochLength;
        return rewards;

    }

    function unlockedRewards(address _user) public view returns(uint) {
        return unlockedPercentage(_user)*rewardsOf(_user)/100;
    }

    function claim() external {
        IERC20(tokenAddress).farmMint(msg.sender, unlockedRewards(msg.sender));
        farmEntity memory userFarm = farms[msg.sender];
        if (block.timestamp<endOfCalendar) {userFarm.claimedBeforeTotalUnlock = true;}
        userFarm.plusRewards = 0;
        userFarm.depositTime = block.timestamp;
    }

    function withdraw(uint _amount) external {
        farmEntity memory userFarm = farms[msg.sender];
        require(userFarm.value>=_amount, "WithdrawalError: asked amount higher than staked value.");
        IERC20(tokenAddress).transfer(msg.sender, _amount);
        userFarm.value -= _amount;

    }
}
