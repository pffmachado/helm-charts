CHARTS ?= $(shell find charts/* -maxdepth 0 -type d)
CHARTS_DESTINATION := $(PWD)/.staging
CHARTS_URL := "https://github.com/pffmachado/helm-charts/releases/download/__version__"

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
package: lint ## Package charts
	@echo "=> Package"
	@mkdir -p $(CHARTS_DESTINATION)
	@for chart in $(CHARTS); do \
		echo "packaging $$chart ..."; \
		helm package $$chart -d $(CHARTS_DESTINATION); \
	done

.PHONY: index
index:  package ## Generate Index
	@echo "=> Index"
	@cp index.yaml $(CHARTS_DESTINATION)
	@for chart in $(CHARTS); do \
		echo "index repo ..."; \
		helm repo index $(CHARTS_DESTINATION) --merge index.yaml --url $(CHARTS_URL); \
		CHART_NAME=`basename $$chart`; \
		CHART_NAME=`basename $(CHARTS_DESTINATION)/$$CHART_NAME* .tgz`; \
		sed -i "s/__version__/$${CHART_NAME}/g" $(CHARTS_DESTINATION)/index.yaml ;\
	done
	@cp $(CHARTS_DESTINATION)/index.yaml index.yaml
.PHONY: index

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
		helm install --dry-run --debug $$CHART_NAME $$chart ; \
	done


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
