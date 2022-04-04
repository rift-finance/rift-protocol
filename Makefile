.PHONY:	help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
	awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: test
test: build ## run tests
	forge test --match-contract RiftTokenTest
	forge test --match-contract CoreTest
	forge test --match-contract UniswapVaultTest
	forge test --match-contract MasterChefVaultTest
	forge test --match-contract MasterChefV2VaultTest
	forge test --match-contract NativeVaultTest

.PHONY: build
build: ## clean and build contracts
	forge clean && forge build
