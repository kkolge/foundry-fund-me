// SPDX-License-Identifier: NOT-DEFINED-LEARNING
pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.t.sol";

abstract contract CodeContants {
    //Adding all constants that will be used in the contract
    uint8 constant DECIMALS = 8;
    int constant INITIAL_PRICE = 2000e8;

    //Chain ID for testing and deploying on different networks
    uint256 public constant LOCAL_CHAIN_ID = 31337; // Anvil chain
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111; //Sipolia testnet
}

contract HelperConfig is CodeContants, Script {
    //Custom Errors
    //This is used when the chain ID is not supported
    error HelperConfig__ChainIdNotSupported();

    //Data scructure to store the network configuration
    struct NetworkConfig {
        address priceFeed;
    }

    //State variables
    NetworkConfig public localNetworkConfig;
    mapping(uint256 => NetworkConfig) public networkConfigs;

    //Active network configuration in the constructor
    constructor() {
        //networkConfigs[LOCAL_CHAIN_ID] = localNetworkConfig;
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSipoliaEthConfig();
    }

    //Functions in the contract

    function getConfigByChainId(
        uint256 _chainId
    ) public returns (NetworkConfig memory) {
        if (networkConfigs[_chainId].priceFeed != address(0)) {
            return networkConfigs[_chainId];
        } else if (_chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilEthConfig();
        } else {
            revert HelperConfig__ChainIdNotSupported();
        }
    }

    function getSipoliaEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory sipoliaEthConfig = NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
        return sipoliaEthConfig;
    }

    //Local configuration for testing purposes
    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (localNetworkConfig.priceFeed != address(0)) {
            return localNetworkConfig;
        }

        console.log(unicode"⚠️ You have deployed a mock contract!");
        console.log("Make sure this was intentional");

        //Creating a mock aggregator contract
        vm.startBroadcast();
        MockV3Aggregator mockV3Aggregator = new MockV3Aggregator(
            DECIMALS,
            INITIAL_PRICE
        );
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({
            priceFeed: address(mockV3Aggregator)
        });
        return localNetworkConfig;
    }
}
