// SPDX-License-Identifier: MIT

// 5:11:00

pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

// imported to deal with integer overflows; not needed in newer versions of solidity
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";

// When a contract is created, you can pass in a "value" in remix,
// but this isn't a fund() call, so when you try to look up your address
// in addressToAmountFunded, nothing is there. Once the contract is on chain and
// THEN you call fund(), then your address will be added to addressToAmountFunded

contract FundMe {
    using SafeMathChainlink for uint256;

    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;
    AggregatorV3Interface public priceFeed;

    // need a PAYABLE constructor function to accept funds
    constructor(address _priceFeed) public payable {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    function fund() public payable {
        uint256 minimumUSD = 0.00000000000001 * (10**18);
        require(getConversionRate(msg.value) >= minimumUSD, "Moar ETH plz");
        addressToAmountFunded[msg.sender] = msg.value;
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // pricefeed returns value of eth by 10^8
        // 1 wei = 10^18 eth so, if we want to keep it in wei, multiply by 10^10
        return uint256(answer * (10**10));
    }

    // 1 ETH = 10^18 wei
    // to keep everything in wei, making all numbers 18 decimal places
    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / (10**18);
        return ethAmountInUsd;
    }

    function getEntranceFee() public view returns (uint256) {
        // minimumUSD
        uint256 minimumUSD = 50 * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        return (minimumUSD * precision) / price;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // this = contract you're currently in
    // whoever calls a function is the "sender"
    function withdraw() public payable onlyOwner {
        msg.sender.transfer(address(this).balance);
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
    }
}
