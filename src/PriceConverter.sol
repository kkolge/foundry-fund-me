// SPDX-License-Identifier: NOT-DEFINED-LEARNING
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

//This library deals with the external calls to the chainlink network to get the conversion
// details.
library PriceConverter {
    /**
    This function gets the USD price for 1 ETH
     */
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // ETH/USD rate in 18 digit
        return uint256(answer * 10000000000);
    }

    /**
    This function is external function that can be called to get the conversion of the funded amount
    and check it agains the minimum that can be funded.
    */
    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        // the actual ETH/USD conversion rate, after adjusting the extra 0s.
        return ethAmountInUsd;
    }

    /**
    This function gets the version number of the chainlink library 
    that we are using for the price conversion. 
    It's best to keep all interactions with the library here
    */
    function getVersion(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        return priceFeed.version();
    }
}
