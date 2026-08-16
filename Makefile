.DEFAULT_GOAL := help

.PHONY: help analyze test generate-database database-schema \
	test-database-web check-env check-config docs check run-local run-dev \
	run-prod

FLUTTER ?= flutter
DART ?= dart
DEVICE ?=
DEVICE_OPTION := $(if $(strip $(DEVICE)),-d "$(DEVICE)",)

LOCAL_ENV_FILE ?= env/local.env
DEV_ENV_FILE ?= env/dev.env
TEST_ENV_FILE ?= env/test.env
PROD_ENV_FILE ?= env/prod.env

help:
	@echo "Template quality and database commands"
	@echo "  make check              Analyze, test, validate config, and validate docs"
	@echo "  make generate-database  Regenerate application database sources"
	@echo "  make database-schema    Refresh schema snapshot and verifier code"
	@echo "  make test-database-web  Verify real Chrome persistence across modules"
	@echo "  make check-env ENV_FILE=<path>  Validate the exact profile used by a build"
	@echo "  make run-local          Run with env/local.env"
	@echo "  make run-dev            Run with env/dev.env"
	@echo "  make run-prod           Run with env/prod.env"

analyze:
	$(FLUTTER) analyze

test:
	$(FLUTTER) test
	cd packages/libraries/app_database && $(DART) test
	cd packages/bounded_contexts/catalog && $(DART) test
	cd packages/bounded_contexts/ordering && $(DART) test

generate-database:
	cd packages/libraries/app_database && $(DART) run build_runner build

database-schema:
	cd packages/libraries/app_database && $(DART) run drift_dev make-migrations

test-database-web:
	$(FLUTTER) drive \
		--driver=test_driver/integration_test.dart \
		--target=integration_test/app_database_web_persistence_test.dart \
		-d web-server --browser-name=chrome

check-config:
	$(DART) tool/quality/validate_dart_defines.dart $(LOCAL_ENV_FILE)
	$(DART) tool/quality/validate_dart_defines.dart $(DEV_ENV_FILE)
	$(DART) tool/quality/validate_dart_defines.dart $(TEST_ENV_FILE)
	$(DART) tool/quality/validate_dart_defines.dart $(PROD_ENV_FILE)

check-env:
	$(DART) tool/quality/validate_dart_defines.dart $(ENV_FILE)

docs:
	$(DART) doc --dry-run
	$(DART) doc --dry-run packages/libraries/app_database
	$(DART) doc --dry-run packages/bounded_contexts/catalog
	$(DART) doc --dry-run packages/bounded_contexts/ordering

check: analyze test check-config docs

run-local:
	$(DART) tool/quality/validate_dart_defines.dart $(LOCAL_ENV_FILE)
	$(FLUTTER) run $(DEVICE_OPTION) --dart-define-from-file=$(LOCAL_ENV_FILE)

run-dev:
	$(DART) tool/quality/validate_dart_defines.dart $(DEV_ENV_FILE)
	$(FLUTTER) run $(DEVICE_OPTION) --dart-define-from-file=$(DEV_ENV_FILE)

run-prod:
	$(DART) tool/quality/validate_dart_defines.dart $(PROD_ENV_FILE)
	$(FLUTTER) run $(DEVICE_OPTION) --dart-define-from-file=$(PROD_ENV_FILE)
