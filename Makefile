# Determine this makefile's path.
# Be sure to place this BEFORE `include` directives, if any.
# THIS_FILE := $(lastword $(MAKEFILE_LIST))
THIS_FILE := $(abspath $(lastword $(MAKEFILE_LIST)))
CURRENT_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

include vars.mk

#################################
# Bazel targets
#################################

.PHONY: build
build: ## build all targets
	@bazel build //...

.PHONY: test
test: ## test all targets
	@bazel test //...

.PHONY: buildifier
buildifier: ## format Bazel WORKSPACE and BUILD.bazel files
	@bazel run :buildifier

#################################
# Metadata service targets
#################################

.PHONY: readline-gen-deps
readline-gen-deps: ## regenerate dependencies file (services/metadata/backend/deps.bzl)
	@bazel run //readline:gazelle -- update-repos -from_file=readline/go.mod -to_macro=deps.bzl%go_dependencies

.PHONY: readline-docker-build
readline-docker-build: ## publish linux/amd64 platform image locally
	@bazel run --platforms=@io_bazel_rules_go//go/toolchain:linux_amd64 //readline/cmd:image -- --norun

.PHONY: readline-docker-run
readline-docker-run: ## run Docker image locally
	@bazel run --platforms=@io_bazel_rules_go//go/toolchain:linux_amd64 //readline/cmd:image

.PHONY: readline-run
readline-run: build ## start the metadata service
	@bazel run --platforms=@io_bazel_rules_go//go/toolchain:linux_amd64 //readline/cmd

.PHONY: readline-test
readline-test: ## run all metadata-service tests
	@bazel test //readline/...

#################################
# Vagrant
#################################

.PHONY: vagrant-up
vagrant-up: ## spin up vagrant box
	vagrant up
	@echo "use 'vagrant ssh' to connect"

.PHONY: vagrant-halt
vagrant-halt: ## shutdown vagrant box
	vagrant up
	@echo "use 'vagrant ssh' to connect"

.PHONY: vagrant-destroy
vagrant-destroy: ## destroy vagrant box
	vagrant destroy

#################################
# Other targets
#################################

.PHONY: help
help: ## this help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST) | sort

.DEFAULT_GOAL := help
