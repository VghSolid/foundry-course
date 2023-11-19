-include .env

deploy-anvil:
	forge script script/DeployFundMe.s.sol:DeployFundMe --rpc-url $(ANVIL_RPC_URL) --private-key $(ANVIL_PRIVATE_KEY) --broadcast -vvvv