.DEFAULT_GOAL := help

.PHONY: help analyze test generate-database database-schema \
	test-database-web test-integration test-integration-startup-failure \
	check-env check-config docs check-format check-generated check-clean \
	check check-ci run-local run-dev run-prod

FLUTTER ?= flutter
DART ?= dart
DEVICE ?=
DEVICE_OPTION := $(if $(strip $(DEVICE)),-d "$(DEVICE)",)

LOCAL_ENV_FILE ?= env/local.env
DEV_ENV_FILE ?= env/dev.env
TEST_ENV_FILE ?= env/test.env
PROD_ENV_FILE ?= env/prod.env

DATABASE_GENERATED_PATHS := \
	packages/libraries/app_database/lib/src/application_database.g.dart \
	packages/libraries/app_database/lib/src/application_database.steps.dart \
	packages/libraries/app_database/lib/src/schema \
	packages/libraries/app_database/test/migrations/drift/application_database/generated

help:
	@echo "Template quality and database commands"
	@echo "  make check              Analyze, test, validate config, and validate docs"
	@echo "  make check-ci           Reproduce the clean-checkout CI quality gate"
	@echo "  make generate-database  Regenerate application database sources"
	@echo "  make database-schema    Refresh schema snapshot and verifier code"
	@echo "  make test-database-web  Verify real Chrome persistence across modules"
	@echo "  make test-integration DEVICE=<device>  Verify real successful startup"
	@echo "  make test-integration-startup-failure DEVICE=<device>  Verify safe fallback"
	@echo "  make check-env ENV_FILE=<path>  Validate the exact profile used by a build"
	@echo "  make run-local          Run with env/local.env"
	@echo "  make run-dev            Run with env/dev.env"
	@echo "  make run-prod           Run with env/prod.env"

analyze:
	$(FLUTTER) analyze --fatal-warnings --fatal-infos

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

test-integration:
	$(FLUTTER) test integration_test/startup_success_test.dart \
		$(DEVICE_OPTION) --dart-define-from-file=$(TEST_ENV_FILE)

test-integration-startup-failure:
	$(FLUTTER) test integration_test/startup_failure_test.dart \
		$(DEVICE_OPTION) \
		--dart-define=APP_ENVIRONMENT=invalid \
		--dart-define=APP_URL_STRATEGY=hash \
		--dart-define=APP_STORAGE_NAMESPACE=test

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

check-format:
	$(DART) format --output=none --set-exit-if-changed .

check-generated:
	$(MAKE) generate-database
	$(MAKE) database-schema
	@generated_status="$$(git status --porcelain=v1 --untracked-files=all -- \
		$(DATABASE_GENERATED_PATHS))"; \
	if [ -n "$$generated_status" ]; then \
		printf '%s\n' "$$generated_status"; \
		git diff -- $(DATABASE_GENERATED_PATHS); \
		exit 1; \
	fi

check-clean:
	@tree_status="$$(git status --porcelain=v1 --untracked-files=all)"; \
	if [ -n "$$tree_status" ]; then \
		printf '%s\n' "$$tree_status"; \
		git diff --; \
		exit 1; \
	fi

check: analyze test check-config docs

check-ci:
	$(MAKE) check-clean
	$(FLUTTER) pub get --enforce-lockfile
	$(MAKE) check-clean
	$(MAKE) check-format
	$(MAKE) check-generated
	$(MAKE) check
	$(MAKE) check-clean

run-local:
	$(DART) tool/quality/validate_dart_defines.dart $(LOCAL_ENV_FILE)
	$(FLUTTER) run $(DEVICE_OPTION) --dart-define-from-file=$(LOCAL_ENV_FILE)

run-dev:
	$(DART) tool/quality/validate_dart_defines.dart $(DEV_ENV_FILE)
	$(FLUTTER) run $(DEVICE_OPTION) --dart-define-from-file=$(DEV_ENV_FILE)

run-prod:
	$(DART) tool/quality/validate_dart_defines.dart $(PROD_ENV_FILE)
	$(FLUTTER) run $(DEVICE_OPTION) --dart-define-from-file=$(PROD_ENV_FILE)
