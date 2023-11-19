// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {PriceConverter} from "./PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

error FundMe__Notowner(); //naming errors: contract's name + __ + the error

//The functions here only work on sepolia testnet(not RemixNM or ...)
contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MIN_USD = 5e18; //constant reduces gas cost
    address[] private s_funders;

    mapping(address => uint256) private s_amountFunded;
    address private immutable i_owner; //immutable reduces gas cost
    AggregatorV3Interface private s_pricefeed;

    constructor(address pricefeed) {
        i_owner = msg.sender;
        s_pricefeed = AggregatorV3Interface(pricefeed);
    }

    modifier onlyowner() {
        //require(msg.sender== i_owner,"caller must be admin");
        if (msg.sender != i_owner) {
            revert FundMe__Notowner(); //this is new and can reduce gas
        }
        _;
    }

    function fundMe() public payable {
        require(
            msg.value.getConversion(s_pricefeed) >= MIN_USD,
            "didn't send enough ETH"
        ); //New
        s_funders.push(msg.sender);
        s_amountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyowner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "transfer failed");

        uint256 arrayLength = s_funders.length;
        for (uint256 i = 0; i < arrayLength; i++) {
            s_amountFunded[s_funders[i]] = 0;
        }
        s_funders = new address[](0); //this line resets the array length to zero.(NEW)
    }

    receive() external payable {
        fundMe();
    }

    fallback() external payable {
        fundMe();
    }

    //----------------------------Getters-----------------------

    function getAmountFundedByAddress(
        address fundingAddress
    ) external view returns (uint256) {
        return s_amountFunded[fundingAddress];
    }

    function getFunderAddress(uint256 index) external view returns (address) {
        return s_funders[index];
    }

    function getversion() public view returns (uint256) {
        return s_pricefeed.version();
    }

    //some testing functions

    function getEthPrice() external view returns (uint256) {
        (, int256 ethPrice, , , ) = s_pricefeed.latestRoundData();
        return uint256(ethPrice);
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }
}
