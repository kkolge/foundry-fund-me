// SPDX-License-Identifier: NOT-DEFINED-LEARNING
pragma solidity ^0.8.18;

//Using chainlink to get the external conversion data using the call
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";
// import {DeployFundMe} from "script/DepolyFundMe.s.sol";
// import {Test, console} from "forge-std/Test.sol";

//Custom Errors
error FundMe__NotOwner();

/**
 * @title FundMe
 * @author Ketan Kolge
 * @dev This contract is used to fund the contract with a minimum amount of USD, withdraw the funds
 * @notice For testing and learning purposes only
 */
contract FundMe {
    //Type declarations
    using PriceConverter for uint256;

    //State variables
    uint256 public constant MINIMUM_USD = 5 * 10 ** 18;
    address private immutable i_owner;
    address[] private s_funders;
    mapping(address => uint256) private s_addressToAmountFunded;
    AggregatorV3Interface private immutable s_priceFeed;

    //Modifiers
    modifier onlyOwner() {
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        _;
    }

    //Constructor
    constructor(address _priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(_priceFeed);
    }

    /// @notice This function is used to fund the contract with minimum amount price check
    function fund() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "You need to spend more ETH!"
        );
        // updating the funded value against the funder
        s_addressToAmountFunded[msg.sender] += msg.value;
        // updating the list of funders
        s_funders.push(msg.sender);
    }

    /// @notice This function is used to withdraw the funds from the contract
    function withdraw() public onlyOwner {
        address[] memory _funders = s_funders; //reading only 1 time from the storage

        for (
            uint8 funderIndex = 0;
            funderIndex < _funders.length;
            funderIndex++
        ) {
            address _funder = _funders[funderIndex];
            s_addressToAmountFunded[_funder] = 0;
        }
        s_funders = new address[](0);

        // transfer the funds to the owner
        (bool callSuccess, ) = i_owner.call{value: address(this).balance}("");
        require(callSuccess, "Failed to withdraw the funds");
    }

    /// @notice These are default functions in case we get a call without any function
    //Fallback functions
    fallback() external payable {
        fund();
    }

    //Receive function
    receive() external payable {
        fund();
    }

    //Getter functions for view and pure functions

    /// @notice This function is used to get the amount funded against the address
    function getAddressToAmountFunded(
        address _fundingAddress
    ) external view returns (uint256) {
        return s_addressToAmountFunded[_fundingAddress];
    }

    /// @notice This function is used to get the funder address against the index
    function getFunder(uint256 _index) external view returns (address) {
        return s_funders[_index];
    }

    /// @notice This function is used to get the list of funders
    function getFunders() external view returns (address[] memory) {
        return s_funders;
    }

    /// @notice This function is used to get the price feed address
    function getPriceFeed() external view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }

    /// @notice This function is used to get the version of the priceFeed
    function getVersion() public view returns (uint256) {
        return PriceConverter.getVersion(s_priceFeed);
    }

    /// @notice This function is used to get the owner of the contract
    function getOwner() external view returns (address) {
        return i_owner;
    }
}
