// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "hardhat/console.sol";

contract RewardToken {
    function mint(uint256 amount, address receiver) external {}
    function decimals() external view returns (uint8){}
}

contract StakingContract {
    uint8 public APR = 10;
    struct Stake {
        uint256 balance;
        uint256 reward;
        uint256 checkpoint;
    }
    RewardToken public rewardToken;
    mapping(address => Stake) public stakes;
    AggregatorV3Interface internal priceFeed;

    event Staking(
        address from,
        uint256 value
    );

    event Withdrawing(
        address to,
        uint256 value
    );

    event Rewarding(
        address to,
        RewardToken rewardToken,
        uint256 value
    );

    constructor(address _rewardToken, address _priceFeed) {
        rewardToken = RewardToken(_rewardToken);
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    function stake() payable public {
        require(stakes[msg.sender].balance + msg.value >= 0.31536 gwei, "minimal stake is 0,31536 gwei");

        if(stakes[msg.sender].balance > 0) {
            stakes[msg.sender].reward += calculateReward();
        }

        stakes[msg.sender].balance += msg.value;
        stakes[msg.sender].checkpoint = block.timestamp;
        emit Staking(msg.sender, msg.value);
    }

    function calculateReward() public view returns(uint) {
        console.log("timestamp: %s, checkpoint: %s", block.timestamp, stakes[msg.sender].checkpoint);
        uint256 period = (block.timestamp - stakes[msg.sender].checkpoint);
        console.log("period: %s seconds", period);
        (,int price,,,) = priceFeed.latestRoundData();
        // int price = 3000 * (10 ** 8);
        console.log("price: %s USD", uint256(price));
        uint8 priceFeedDecimals = priceFeed.decimals();
        // uint8 priceFeedDecimals = 8;
        uint8 rewardTokenDecimals = rewardToken.decimals();
        uint8 stakeCurrencyDecimals = 18;
        assert(price > 0);

        uint256 rewardPerSecond = stakes[msg.sender].balance / 100 * APR / 365 days;
        console.log("reward wei: %s per second", rewardPerSecond);
        uint256 reward = rewardPerSecond * period;
        console.log("reward wei: %s", reward);
        uint256 rewardInRewardToken = reward * uint256(price);
        console.log("rewardTokenDecimals %s", rewardTokenDecimals);
        console.log("stakeCurrencyDecimals %s", stakeCurrencyDecimals);
        console.log("priceFeedDecimals %s", priceFeedDecimals);
        uint256 decimals = stakeCurrencyDecimals + priceFeedDecimals - rewardTokenDecimals;
        console.log("decimals %s", decimals);
        console.log("reward USDC: %s USDC", rewardInRewardToken / (10 ** decimals));

        return rewardInRewardToken / (10 ** decimals);
    }

    function withdraw() public {
        require(stakes[msg.sender].balance > 0, "stake not found");
        stakes[msg.sender].reward += calculateReward();

        uint256 balance = stakes[msg.sender].balance;
        stakes[msg.sender].balance = 0;
        (bool successStakeWithdraw, ) = msg.sender.call{value: balance}("");
        require(successStakeWithdraw, "withdrawing stake failed");
        emit Withdrawing(msg.sender, balance);

        uint256 reward = stakes[msg.sender].reward;
        stakes[msg.sender].reward = 0;
        rewardToken.mint(reward, msg.sender);
        emit Rewarding(msg.sender, rewardToken, reward);
    }
}
