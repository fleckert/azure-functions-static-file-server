-include .env

SUBSCRIPTION_ID      ?= 00000000-0000-0000-0000-000000000000
RG_NAME              ?= sttcflsrvr
NAME                 ?= sttcflsrvr

ROOT_DIR             := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
SCRIPTS_DIR          := $(ROOT_DIR)scripts
PATH_CSPROJ          := $(ROOT_DIR)StaticFilesHandler/StaticFilesHandler.csproj
PATH_OUTPUT          := $(ROOT_DIR)dist
PATH_APP_BUILD       := $(SCRIPTS_DIR)/appBuild.sh
PATH_APP_BUILD_LOCAL := $(SCRIPTS_DIR)/appBuildLocal.sh
PATH_APP_CHECK       := $(SCRIPTS_DIR)/appCheck.sh
PATH_APP_DEPLOY      := $(SCRIPTS_DIR)/appDeploy.sh
PATH_INFRA_SETUP     := $(SCRIPTS_DIR)/infraSetup.sh
PATH_INFRA_TEARDOWN  := $(SCRIPTS_DIR)/infraTearDown.sh
INIT_STAMP           := $(SCRIPTS_DIR)/.init-done

.PHONY: init clean build build-local deploy infra deploy-app check infra-down run

.DEFAULT_GOAL := run

help:
	@echo "Targets:"
	@echo "  help             Show this help"
	@echo "  run              Build and run locally using Azure Functions Core Tools"
	@echo "  deploy           Create infrastructure and deploy app to Azure (requires SUBSCRIPTION_ID)"
	@echo "  deploy-app       Deploy app to Azure (requires SUBSCRIPTION_ID)"
	@echo "  infra-down       Tear down infra (requires SUBSCRIPTION_ID)"
	@echo ""
	@echo "Required variables:"
	@echo "  SUBSCRIPTION_ID  Azure subscription ID (required for deploy and infra-down)"
	@echo ""
	@echo "Optional variables:"
	@echo "  RG_NAME          Resource group name (default: $(RG_NAME))"
	@echo "  NAME             App/base resource name (default: $(NAME))"

guard-%      : ; @test "$($(*))" != "00000000-0000-0000-0000-000000000000" && test "$($(*))" != "" || (echo "ERROR: $* is not set or is still the default value"; exit 1)
$(INIT_STAMP): $(wildcard $(SCRIPTS_DIR)/*.sh) ; @chmod +x $(SCRIPTS_DIR)/*.sh; @touch "$(INIT_STAMP)"

init         : $(INIT_STAMP)
clean        :                            ; rm -rf "$(PATH_OUTPUT)"
build-local  : init clean                 ; "$(PATH_APP_BUILD_LOCAL)" "$(PATH_CSPROJ)" "$(PATH_OUTPUT)"
run          : build-local                ; AzureWebJobsStorage="UseDevelopmentStorage=true" func start --custom
build        : init clean                 ; "$(PATH_APP_BUILD)" "$(PATH_CSPROJ)" "$(PATH_OUTPUT)"
infra        : init guard-SUBSCRIPTION_ID ; "$(PATH_INFRA_SETUP)" "$(SUBSCRIPTION_ID)" "$(RG_NAME)" "$(NAME)"
deploy-app   : init                       ; "$(PATH_APP_DEPLOY)" "$(NAME)"
check        : init                       ; "$(PATH_APP_CHECK)" "https://$(NAME).azurewebsites.net"
infra-down   : init guard-SUBSCRIPTION_ID ; "$(PATH_INFRA_TEARDOWN)" "$(SUBSCRIPTION_ID)" "$(RG_NAME)" "$(NAME)"
deploy       : init guard-SUBSCRIPTION_ID build infra deploy-app check
