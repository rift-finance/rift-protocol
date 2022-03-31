test: build
	forge test --match-contract CoreTest
	forge test --match-contract UniswapVaultTest
	forge test --match-contract MasterChefVaultTest
	forge test --match-contract MasterChefV2VaultTest
	forge test --match-contract NativeVaultTest

build:
	forge clean && forge build
