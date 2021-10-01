.DEFAULT_GOAL := all
.PHONY: all usage

COMPOSE_BINARY ?= $(shell command -v docker-compose 2>/dev/null)
DOCKER_BINARY ?= $(shell command -v docker 2>/dev/null)
GIT_BINARY ?= $(shell command -v git 2>/dev/null)

usage: ## Displays this message
	@grep -E '^[A-Za-z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m%s\n", $$1, $$2}'

.PHONY: deps
deps: ## Ensures required dependencies are met
ifeq ($(COMPOSE_BINARY),)
	$(error "Specify the path to docker-compose using COMPOSE_BINARY to continue")
endif
ifeq ($(DOCKER_BINARY),)
	$(error "Specify the path to docker using DOCKER_BINARY to continue")
endif
ifeq ($(GIT_BINARY),)
	$(error "Specify the path to git using GIT_BINARY to continue")
endif

.PHONY: version
version: deps ## Identifies the version of this codebase
	@$(GIT_BINARY) rev-parse HEAD

.PHONY: check
check: ## TBD
	$(info "Not implemented")

.PHONY: TAGS
TAGS: ## TBD
	$(info "Not implemented")

.PHONY: dist
dist: ## Builds the image locally
	@$(COMPOSE_BINARY) build $(BUILD_ARGS) easydns-dynamic

.PHONY: installdirs
installdirs: ## TBD
	$(info "Not implemented")

.PHONY: install
install: dist ## Build the image locally

.PHONY: install-strip
install-strip: ## TBD
	$(info "Not implemented")

.PHONY: installcheck
installcheck: ## TBD
	$(info "Not implemented")

.PHONY: uninstall
uninstall: clean ## Removes locally built images

.PHONY: info
info: ## TBD
	$(info "Not implemented")

.PHONY: clean
clean: ## Cleans up the local environment
	@$(DOCKER_BINARY) container prune -f --filter 'label=project=easydns-dynamic'
	@$(DOCKER_BINARY) image prune -f --all --filter 'label=project=easydns-dynamic'

.PHONY: distclean
distclean: ## Cleans up most .gitignore files and directories
	@$(GIT_BINARY) clean -fXd

.PHONY: mostlyclean
mostlyclean: ## Cleans up all .gitignore files and directories
	@$(GIT_BINARY) clean -fXdf

.PHONY: maintainer-clean
maintainer-clean: ## Cleans up all untracked files and directories
	@$(GIT_BINARY) clean -fxdf

.PHONY: exec-interactive
exec-interactive: ## Runs the container interactively
	@$(COMPOSE_BINARY) run $(RUN_ARGS) --entrypoint /bin/sh easydns-dynamic

.PHONY: exec
exec: ## Runs the application in a container
	@$(COMPOSE_BINARY) up $(RUN_ARGS) easydns-dynamic

.PHONY: release
release: dist ## Releases the image to the Docker registry
	$(eval APP_VERSION ?= $(shell $(GIT_BINARY) rev-parse HEAD))
	@APP_VERSION=$(APP_VERSION) $(MAKE) dist
	@APP_VERSION=$(APP_VERSION) $(COMPOSE_BINARY) push $(BUILD_ARGS) easydns-dynamic
	@$(COMPOSE_BINARY) push $(BUILD_ARGS) easydns-dynamic
