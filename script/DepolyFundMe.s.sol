// SPDX-License-Identifier: NOT-DEFINED-LEARNING

pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {FundMe} from "src/FundMe.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployFundMe is Script {
    /// @notice Deploying the FundMe contract based on the chain ID
    function deployFundMe() public returns (FundMe, HelperConfig) {
        HelperConfig _helperconfig = new HelperConfig();
        address _priceFeed = _helperconfig
            .getConfigByChainId(block.chainid)
            .priceFeed;

        vm.startBroadcast();
        FundMe _fundMe = new FundMe(_priceFeed);
        vm.stopBroadcast();

        return (_fundMe, _helperconfig);
    }

    /// @notice Run the deployment
    function run() external returns (FundMe, HelperConfig) {
        return deployFundMe();
    }
}
