//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract FundMe {
    mapping(address => uint256) public fundersToAmount;
    uint256 constant MINIMUM_VALUE = 10 * 10**18; //USD

    uint256 constant TARGET = 50 * 10**18;
    AggregatorV3Interface internal dataFeed;

    address owner;
    uint256 deploymentTimestamp;
    uint256 lockTime;

    constructor(uint256 _lockTime) {
        dataFeed = AggregatorV3Interface(
            0x694AA1769357215DE4FAC081bf1f309aDC325306
        );
        owner = msg.sender;
        deploymentTimestamp = block.timestamp;
        lockTime = _lockTime;
    }

    function fund() external payable{
        require(convertEthToUsd(msg.value) >= MINIMUM_VALUE, "Send more ETH");
        require(block.timestamp < deploymentTimestamp + lockTime, "window is closed");
        fundersToAmount[msg.sender] = msg.value;
    }

    function getChainlinkDataFeedLatestAnswer() public view returns (int256) {
        // prettier-ignore
        (
            /* uint80 roundID */,
            int answer,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = dataFeed.latestRoundData();
        return answer;
    }

    function convertEthToUsd(uint256 ethAmount)
        internal
        view
        returns (uint256)
    {
        uint256 ethPrice = uint256(getChainlinkDataFeedLatestAnswer());
        return (ethAmount * ethPrice) / (10**8);
    }

    function transferOwnership(address newOwner) public {
        require(
            msg.sender == owner,
            "the fundction is only can be called by owner"
        );
        owner = newOwner;
    }

    function getFund() external windowsclose onlyOwner {
        require(
            convertEthToUsd(address(this).balance) >= TARGET,
            "TARGET is not reached"
        );
        bool success;
        (success, ) = payable(msg.sender).call{value: address(this).balance}(
            ""
        );
        require(success, "transfer is failed");
        fundersToAmount[msg.sender] = 0;
    }

    function refund() external windowsclose{
        require(
            convertEthToUsd(address(this).balance) < TARGET,
            "TARGET is reached"
        );
        require(fundersToAmount[msg.sender] != 0, "there is no fund for you");

        bool success;
        (success, ) = payable(msg.sender).call{
            value: fundersToAmount[msg.sender]
        }("");
        require(success, "transfer is failed");
        fundersToAmount[msg.sender] = 0;
    }

    modifier windowsclose() {
        require(
            block.timestamp >= deploymentTimestamp + lockTime,
            "window is not closed"
        );
        _;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "the fundction is only can be called by owner"
        );
        _;
    }
}
