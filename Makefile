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

# Generated files
GENERATED_DOCS_SENTINEL  := $(TMP_PATH)/.docs_generated_sentinel
GENERATED_DOCS           := $(DOCS_PATH)/_data/unstable

GENERATED_DIST_SENTINEL  := $(TMP_PATH)/.dist_generated_sentinel
TAXONOMY_JSON            := $(DIST_PATH)/en/taxonomy.json
CATEGORIES_JSON          := $(DIST_PATH)/en/categories.json
ATTRIBUTES_JSON          := $(DIST_PATH)/en/attributes.json
MAPPINGS_JSON            := $(DIST_PATH)/en/integrations/all_mappings.json

DB_DEV                   := $(DB_PATH)/development.sqlite3

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
build: $(GENERATED_DIST_SENTINEL) $(GENERATED_DOCS_SENTINEL)
.PHONY: build

$(GENERATED_DIST_SENTINEL): $(DB_DEV)
	@$(LOG_BUILD) "Building Distribution" "$(DIST_PATH)/*.[json|txt]"
	$(V) bin/generate_dist --locales $(LOCALES) $(VERBOSE_ARG)
	$(V) touch $@

$(GENERATED_DOCS_SENTINEL): $(GENERATED_DIST_SENTINEL)
	@$(LOG_BUILD) "Building Docs" "$(GENERATED_DOCS)/*"
	$(V) bin/generate_docs $(VERBOSE_ARG)
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
	@$(LOG_CLEAN) "Cleaning sentinels" "$(GENERATED_DIST_SENTINEL) $(GENERATED_DOCS_SENTINEL)"
	$(V) rm -f $(GENERATED_DIST_SENTINEL) $(GENERATED_DOCS_SENTINEL)
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

# Help target
help:
	@echo "Makefile targets:"
	@echo "  default:        Build the project"
	@echo "  build:          Build distribution and documentation"
	@echo "  release:        Prepare a release"
	@echo "  clean:          Clean all generated files"
	@echo "  run_docs:       Run the documentation server"
	@echo "  console:        Run the application console"
	@echo "  seed:           Seed the database"
	@echo "  test:           Run all tests"
	@echo "  vet_schema:     Validate schemas"
.PHONY: help
