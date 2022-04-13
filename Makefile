.PHONY:	help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
	awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

check-%:
	@ if [[ -z "${${*}}" ]]; then \
        echo "Environment variable $* not set"; \
        exit 1; \
    fi

.PHONY: bootstrap
bootstrap: check-ALCHEMY_API_KEY install ## bootstrap project
	@sed 's/{YOUR_API_KEY}/${ALCHEMY_API_KEY}/g' foundry.toml > foundry.temp
	@mv foundry.temp foundry.toml

.PHONY: install
install: ## install dependencies
	yarn && forge update

.PHONY: clean
clean: ## clean build artifacts
	forge clean

.PHONY: build
build: clean ## build contracts
	forge build

.PHONY: test
test: build ## run tests
	forge test
