// SPDX-License-Identifier: NOT-DEFINED-LEARNING
pragma solidity ^0.8.18;

import {DeployFundMe} from "../../script/DepolyFundMe.s.sol";
import {FundMe} from "../../src/FundMe.sol";
import {HelperConfig, CodeContants} from "../../script/HelperConfig.s.sol";

import {MockV3Aggregator} from "../mocks/MockV3Aggregator.t.sol";

import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";

contract FundMeTest is CodeContants, StdCheats, Test {
    FundMe public fundMe;
    HelperConfig public helperConfig;

    // All constants that will be used in the contract for testing purpose
    uint256 public constant SEND_VALUE = 0.2 ether;
    uint256 public constant STARTING_USER_BALANCE = 3 ether;
    uint256 public constant GAS_PRICE = 1;

    //This test user will be used for for testing purposes
    address TEST_USER = address(0x1234);

    // Modifiers
    modifier funding() {
        vm.prank(TEST_USER);
        fundMe.fund{value: SEND_VALUE}();
        assert(address(fundMe).balance > 0);
        _;
    }

    function setUp() external {
        //Deploying the contract
        DeployFundMe _deployer = new DeployFundMe();
        (fundMe, helperConfig) = _deployer.deployFundMe();

        //Seeding the account with some funds for transactions
        vm.deal(TEST_USER, STARTING_USER_BALANCE);
    }

    /// @notice Test if the price feed is set up correctly
    function test_PriceFeedSetupCorrectly() public {
        address _retrievedPriceFeed = address(fundMe.getPriceFeed());
        address _expectedPriceFeed = helperConfig
            .getConfigByChainId(block.chainid)
            .priceFeed;
        assertEq(_retrievedPriceFeed, _expectedPriceFeed);
        console.log("Price Feed address: ", _retrievedPriceFeed);
    }

    function test_MinimumDollarAmount() public view {
        console.log("Minimum USD: ", fundMe.MINIMUM_USD());
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function test_FundFailsWithoutMinimumETH() public {
        vm.expectRevert();
        fundMe.fund();
    }

    function test_fundValidValue() public funding {
        assertEq(address(fundMe).balance, SEND_VALUE);
    }

    function test_FundUpdatesFundedDataStructure() public funding {
        uint256 _amountFunded = fundMe.getAddressToAmountFunded(TEST_USER);
        assertEq(_amountFunded, SEND_VALUE);
    }

    function test_AddFunderToArrayOfFunders() public funding {
        address[] memory _funders = fundMe.getFunders();
        assertEq(_funders.length, 1);
        assertEq(_funders[0], TEST_USER);
    }

    function test_OnlyOwnerCanWithdraw() public funding {
        console.log("Balance before withdraw: ", address(fundMe).balance);
        vm.expectRevert();
        fundMe.withdraw();
    }

    function test_WithdrawSingleOwner() public funding {
        uint256 _startingFundMeBalance = address(fundMe).balance;
        uint256 _startingOwnerBalance = fundMe.getOwner().balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        uint256 _endingFundMeBalance = address(fundMe).balance;
        uint256 _endingOwnerBalance = fundMe.getOwner().balance;

        assertEq(_endingFundMeBalance, 0);
        assertEq(
            _startingFundMeBalance + _startingOwnerBalance,
            _endingOwnerBalance
        );
    }

    function testWithdrawFromMultipleFunders() public funding {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 2;
        for (
            uint160 i = startingFunderIndex;
            i < numberOfFunders + startingFunderIndex;
            i++
        ) {
            hoax(address(i), STARTING_USER_BALANCE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
        assert(
            (numberOfFunders + 1) * SEND_VALUE ==
                fundMe.getOwner().balance - startingOwnerBalance
        );
    }

    function test_libraryVersion() public view {
        uint256 version = fundMe.getVersion();
        console.log("Version: ", version);
        assertEq(version, 4);
    }

    function test_GetFunder() public funding {
        address funder = fundMe.getFunder(0);
        assertEq(funder, TEST_USER);
    }
}
