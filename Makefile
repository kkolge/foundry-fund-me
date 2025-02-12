-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil

DEFAULT_ANVIL_KEY := 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d

all: clean remove install update build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install :; `install smartcontractkit/chainlink-brownie-contracts@1.1.1 --no-commit

# Update Dependencies
update:; forge update

build:; forge build

test :; forge test

snapshot :; forge snapshot

format :; forge fmt

anvil :; anvil --host 172.24.194.134 -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1 
#--host 172.24.194.134

NETWORK_ARGS := --rpc-url http://172.24.194.134:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast

deploy:
	@forge script $(NETWORK_ARGS) script/DeployFundMe.s.sol:DeployFundMe 


ifeq ($(findstring --network sepolia,$(ARGS)),--network sepolia)
	NETWORK_ARGS := --rpc-url $(SEPOLIA_RPC_URL) --account $(ACCOUNT) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
endif

deploy-sepolia:
	@forge script script/DeployFundMe.s.sol:DeployFundMe $(NETWORK_ARGS)
