.DEFAULT_GOAL := default

###############################################################################
# VARIABLES
###############################################################################

# Paths
DATA_PATH    := data
DIST_PATH    := dist
DOCS_PATH    := docs
DB_PATH      := storage
SCHEMA_PATH  := schema
TMP_PATH     := tmp

# Data files
CATEGORIES_DATA  := $(DATA_PATH)/categories/*.yml
ATTRIBUTES_DATA  := $(DATA_PATH)/attributes.yml
VALUES_DATA      := $(DATA_PATH)/values.yml

LOCALIZATION_SOURCES := $(shell find ${DATA_PATH} -maxdepth 2 -type f \( -path "${DATA_PATH}/*" -o -path "${DATA_PATH}/categories/*" \))

# Generated files
GENERATED_DOCS_SENTINEL  := $(TMP_PATH)/.docs_generated_sentinel
GENERATED_DOCS           := $(DOCS_PATH)/_data/unstable

GENERATED_DIST_SENTINEL  := $(TMP_PATH)/.dist_generated_sentinel
GENERATED_LOCALIZATION_SENTINEL := $(TMP_PATH)/.localization_updated_sentinel

TAXONOMY_JSON            := $(DIST_PATH)/en/taxonomy.json
CATEGORIES_JSON          := $(DIST_PATH)/en/categories.json
ATTRIBUTES_JSON          := $(DIST_PATH)/en/attributes.json
MAPPINGS_JSON            := $(DIST_PATH)/en/integrations/all_mappings.json

DB_DEV                   := $(DB_PATH)/development.sqlite3

# Taxonomy mapping generation tooling
QDRANT_PORT := 6333
QDRANT_CONTAINER_NAME := qdrant_taxonomy_mappings

# Input variables
LOCALES ?= en
VERBOSE ?= 0

# Formatting helpers
ifeq ($(VERBOSE),1)
	V           :=
	VPIPE       :=
	VERBOSE_ARG := --verbose
else
	V           := @
	VPIPE       := > /dev/null
	VERBOSE_ARG :=
endif

FMT           := printf "\e[%sm>> %-21s\e[0;1m →\e[1;32m %s\e[0m\n"
LOG_BUILD     := $(FMT) "1;34"  # bold blue
LOG_CLEAN     := $(FMT) "1;31"  # bold red
LOG_ADVISORY  := printf "\e[%sm!! %-21s\e[0;1m\n" "1;31" # bold red text with a !! prefix
LOG_CMD       := printf "\e[%sm>> %-21s\e[0;1m\n" "1;34" # bold blue text with a >> prefix

###############################################################################
# TARGETS
###############################################################################

# Default target
default: build
.PHONY: default

# Build targets
build: $(GENERATED_DIST_SENTINEL) $(GENERATED_DOCS_SENTINEL) ${GENERATED_LOCALIZATION_SENTINEL}
.PHONY: build

$(GENERATED_DIST_SENTINEL): $(DB_DEV)
	@$(LOG_BUILD) "Building Distribution" "$(DIST_PATH)/*.[json|txt]"
	$(V) bin/generate_dist --locales $(LOCALES) $(VERBOSE_ARG)
	$(V) touch $@

$(GENERATED_DOCS_SENTINEL): $(GENERATED_DIST_SENTINEL)
	@$(LOG_BUILD) "Building Docs" "$(GENERATED_DOCS)/*"
	$(V) bin/generate_docs $(VERBOSE_ARG)
	$(V) touch $@

$(GENERATED_LOCALIZATION_SENTINEL): $(LOCALIZATION_SOURCES)
	@$(LOG_BUILD) "Syncing English Localizations"
	$(V) bin/sync_en_localizations $(VERBOSE_ARG)
	$(V) touch $@

# Release target
release: $(GENERATED_DIST_SENTINEL)
	@$(LOG_CMD) "Preparing release"
	$(V) bin/generate_release $(VERBOSE_ARG)
.PHONY: release

# Clean targets
clean: clean_sentinels clean_dbs clean_docs
.PHONY: clean

clean_sentinels:
	@$(LOG_CLEAN) "Cleaning sentinels" "$(GENERATED_DIST_SENTINEL) $(GENERATED_DOCS_SENTINEL) $(GENERATED_LOCALIZATION_SENTINEL)"
	$(V) rm -f $(GENERATED_DIST_SENTINEL) $(GENERATED_DOCS_SENTINEL) $(GENERATED_LOCALIZATION_SENTINEL)
.PHONY: clean_sentinels

clean_dbs:
	@$(LOG_CLEAN) "Cleaning local dbs" $(DB_DEV)
	$(V) bin/rails db:drop $(VERBOSE_ARG)
.PHONY: clean_dbs

clean_docs:
	@$(LOG_CLEAN) "Cleaning unstable docs" $(GENERATED_DOCS)
	$(V) rm -rf $(GENERATED_DOCS)
.PHONY: clean_docs

# Command targets
run_docs: $(GENERATED_DOCS_SENTINEL)
	@$(LOG_CMD) "Running docs server"
	$(V) bundle exec jekyll serve --source $(DOCS_PATH) --destination _site $(VERBOSE_ARG)
.PHONY: run_docs

console:
	@$(LOG_CMD) "Running console with dependencies"
	$(V) bin/rails console
.PHONY: console

# Database setup
seed: vet_schema_data
	@$(LOG_BUILD) "Seeding Database" $(DB_DEV)
	$(V) bin/rails db:drop $(VERBOSE_ARG)
	$(V) bin/rails db:schema:load $(VERBOSE_ARG)
	$(V) bin/seed $(VERBOSE_ARG)
.PHONY: seed

$(DB_DEV):
	if [ ! -f $@ ]; then $(MAKE) seed; fi

# Test targets
test: test_unit test_integration vet_schema
.PHONY: test

test_unit:
	@$(LOG_CMD) "Running Unit Tests"
	$(V) bin/rails unit $(filter-out $@,$(MAKECMDGOALS))
.PHONY: test_unit

test_integration:
	@$(LOG_CMD) "Running Integration Tests"
	$(V) bin/rails integration $(filter-out $@,$(MAKECMDGOALS))
.PHONY: test_integration

# Schema validation targets
vet_schema: vet_schema_data vet_schema_dist
.PHONY: vet_schema

vet_schema_data:
	@$(LOG_CMD) "Validating $(ATTRIBUTES_DATA) schema"
	$(V) cue vet $(SCHEMA_PATH)/data/attributes_schema.cue $(ATTRIBUTES_DATA)
	@$(LOG_CMD) "Validating $(CATEGORIES_DATA) schema"
	$(V) cue vet $(SCHEMA_PATH)/data/categories_schema.cue -d '#schema' $(CATEGORIES_DATA)
	@$(LOG_CMD) "Validating $(VALUES_DATA) schema"
	$(V) cue vet $(SCHEMA_PATH)/data/values_schema.cue -d '#schema' $(VALUES_DATA)
.PHONY: vet_schema_data

vet_schema_dist:
	@$(LOG_CMD) "Validating $(ATTRIBUTES_JSON) schema"
	$(V) cue vet $(SCHEMA_PATH)/dist/attributes_schema.cue $(ATTRIBUTES_JSON)
	@$(LOG_CMD) "Validating $(CATEGORIES_JSON) schema"
	$(V) cue vet $(SCHEMA_PATH)/dist/categories_schema.cue $(CATEGORIES_JSON)
	@$(LOG_CMD) "Validating $(TAXONOMY_JSON) schema"
	$(V) cue vet $(SCHEMA_PATH)/dist/attributes_schema.cue $(TAXONOMY_JSON)
	$(V) cue vet $(SCHEMA_PATH)/dist/categories_schema.cue $(TAXONOMY_JSON)
	@$(LOG_CMD) "Validating $(MAPPINGS_JSON) schema"
	$(V) cue vet $(SCHEMA_PATH)/dist/mappings_schema.cue $(MAPPINGS_JSON)
.PHONY: vet_schema_dist

generate_mappings:
	@$(LOG_CMD) "Starting Qdrant server"
	@podman run -d --name $(QDRANT_CONTAINER_NAME) -p $(QDRANT_PORT):$(QDRANT_PORT) qdrant/qdrant > /dev/null 2>&1 || true
	@$(LOG_CMD) "Generating missing taxonomy mappings"
	@$(V) bin/generate_missing_mappings $(VERBOSE_ARG)
	@$(LOG_CMD) "Stopping Qdrant server"
	@podman stop $(QDRANT_CONTAINER_NAME) > /dev/null 2>&1 || true
	@podman rm $(QDRANT_CONTAINER_NAME) > /dev/null 2>&1 || true
.PHONY: generate_mappings

# Update the help target to include the new command
help:
	@echo "Makefile targets:"
	@echo "  default:           Build the project"
	@echo "  build:             Build distribution and documentation"
	@echo "  release:           Prepare a release"
	@echo "  clean:             Clean all generated files"
	@echo "  run_docs:          Run the documentation server"
	@echo "  console:           Run the application console"
	@echo "  seed:              Seed the database"
	@echo "  test:              Run all tests"
	@echo "  vet_schema:        Validate schemas"
	@echo "  generate_mappings: Generate missing taxonomy mappings"
.PHONY: help
