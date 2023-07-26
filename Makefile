include .env
export $(shell sed 's/=.*//' .env)

export PYTHONPATH=$(CURDIR)

define set_user_id
    export USER_ID=$(shell id -u)
	$(eval export USER_ID=$(shell id -u))
endef

.PHONY: help
help: ## Command help
	@egrep -h '\s##\s' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

.PHONY: run-api
run-api:  ## Stop infra
	@poetry run uvicorn main:app --reload --port 9090 --host 0.0.0.0 --reload

.PHONY: ot-auto
ot-auto: ## Auto app instrumentation
	@poetry run opentelemetry-bootstrap -a install

.PHONY: ot-api
ot-api: ## Run the app instrumentation
	@poetry run opentelemetry-instrument --traces_exporter console --metrics_exporter console --logs_exporter console uvicorn main:app --port 9090 --host 0.0.0.0

.PHONY: ot-collector
ot-collector: ## Run the collector
	@docker run -p 4317:4317 -v $(CURDIR)/config/otel-collector-config.yaml:/etc/otel-collector-config.yaml otel/opentelemetry-collector:latest --config=/etc/otel-collector-config.yaml

.PHONY: ot-api-collect
ot-api-collect: ## Run the app instrumentation through the collector
	@poetry run opentelemetry-instrument uvicorn main:app --port 9090 --host 0.0.0.0

.PHONY: ot-collector-datadog
ot-collector-datadog: ## Run the app instrumentation through the datadog collector
	@docker run --rm -p 4317:4317 --env-file .env -v $(CURDIR)/config/otel-collector-datadog-config.yaml:/etc/otel-collector-config.yaml otel/opentelemetry-collector-contrib:latest --config=/etc/otel-collector-config.yaml
