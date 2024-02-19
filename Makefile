CHARTS ?= $(shell find charts/* -maxdepth 0 -type d)
CHARTS_DESTINATION := $(PWD)/.staging
CHARTS_URL := "https://github.com/pffmachado/helm-charts/releases/download/__version"

.DEFAULT_GOAL := help

.PHONY: list
list: ## List of charts
	@echo $(CHARTS)

.PHONY: clean
clean: ## Cleanup
	@echo "=> Clean"
	@rm -rf $(CHARTS_DESTINATION)

.PHONY: lint
lint: clean ## Run Helm Lint
	@echo "=> Lint"
	@for chart in $(CHARTS); do \
		echo "linting $$chart ..."; \
		helm lint $$chart; \
	done

.PHONY: package
package:  lint ## Generate Package
	@mkdir -p $(CHARTS_DESTINATION)
	@cp index.yaml $(CHARTS_DESTINATION)
	@for chart in $(CHARTS); do \
		echo "=> Index"; \
		CHART_NAME=`basename $$chart`; \
		echo "package $${CHART_NAME}..."; \
		helm package $$chart -d $(CHARTS_DESTINATION); \
		echo "index repo $${CHART_NAME} ..."; \
		helm repo index $(CHARTS_DESTINATION) --merge $(CHARTS_DESTINATION)/index.yaml --url $(CHARTS_URL)__$${CHART_NAME}; \
		CHART_VERSION=`basename $(CHARTS_DESTINATION)/$$CHART_NAME* .tgz`; \
		echo "version $${CHART_VERSION} ..."; \
		sed -i "s/__version__$${CHART_NAME}/$${CHART_VERSION}/g" $(CHARTS_DESTINATION)/index.yaml; \
		rm -f $(CHARTS_DESTINATION)/$$CHART_NAME* .tgz; \
	done
	@cp $(CHARTS_DESTINATION)/index.yaml index.yaml

.PHONY: template
template: ## Template Helm Chart
	@echo "=> Template"
	@mkdir -p $(CHARTS_DESTINATION)
	@for chart in $(CHARTS); do \
		echo "template $$chart ..."; \
		CHART_NAME=`basename $$chart`; \
		helm template $$CHART_NAME $$chart ; \
	done

install: ## Dry-run Install Helm Chart
	@echo "=> Install"
	@mkdir -p $(CHARTS_DESTINATION)
	@for chart in $(CHARTS); do \
		echo "dry-run $$chart ..."; \
		CHART_NAME=`basename $$chart`; \
		helm install --dry-run --debug -n $$CHART_NAME $$CHART_NAME $$chart ; \
	done

key: ## Generate Self-Signed Certificate
	@echo "=> Generate Certifacte"
	@mkdir -p $(CHARTS_DESTINATION)
	openssl req -x509 -newkey rsa:4096 \
		-keyout $(CHARTS_DESTINATION)/my-cert.key \
		-out $(CHARTS_DESTINATION)/my-cert.pem \
		-sha256 -days 3650 -nodes -subj "/C=XX/ST=StateName/L=CityName/O=CompanyName/OU=CompanySectionName/CN=CommonNameOrHostname"

.PHONY: update-deps
update-deps: ## Update dependencies of the charts
	@for chart in $(CHARTS); do \
		helm dependency update $$chart; \
	done

.PHONY: configure-deps-repos
configure-deps: ## Configure dependencies repositories
	helm repo add bitnami https://charts.bitnami.com/bitnami

.PHONY: help
help: ## Displays this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
