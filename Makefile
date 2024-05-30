.DEFAULT_GOAL := default

###############################################################################
# FORMATTING HELPERS
# Used throughout the makefile for pretty printing and toggling verbose output

ifeq ($(VERBOSE),1)
	V=
	VPIPE=
	VERBOSE_ARG=--verbose
else
	V=@
	VPIPE= >/dev/null
	VERBOSE_ARG=
endif

FMT      = printf "\e[%sm>> %-21s\e[0;1m →\e[1;32m %s\e[0m\n"
GENERATE = $(FMT) "1;34" # bold blue
NUKE     = $(FMT) "1;31" # bold red
ADVISORY = printf "\e[%sm!! %-21s\e[0;1m\n" "1;31" # bold red text with a !! prefix
RUN_CMD  = printf "\e[%sm>> %-21s\e[0;1m\n" "1;34" # bold blue text with a >> prefix

###############################################################################
# TARGETS
# Many commands generate many files (that'll expand), and Make isn't great at
# targeting arbitrary numbers of outputs, so we'll use sentinels.

# DATA
CATEGORIES_DATA_PATH = data/categories/*.yml
ATTRIBUTES_DATA_PATH = data/attributes.yml
VALUES_DATA_PATH = data/values.yml
MAPPINGS_DATA_PATH = data/integrations/*/*/mappings

# DOCS
GENERATED_DOCS_PATH = docs/_data/unstable
DOCS_GENERATED_SENTINEL = tmp/.docs_generated_sentinel

# DIST
DIST_PATH = dist
DIST_GENERATED_SENTINEL = tmp/.dist_generated_sentinel
TAXONOMY_JSON = $(DIST_PATH)/en/taxonomy.json
CATEGORIES_JSON = $(DIST_PATH)/en/categories.json
ATTRIBUTES_JSON = $(DIST_PATH)/en/attributes.json
MAPPINGS_JSON = $(DIST_PATH)/en/mappings.json

# APP files to run application
DEV_DB = storage/development.sqlite3
TEST_DB = storage/test.sqlite3

###############################################################################
# INPUTS

LOCALES ?= en
CATEGORIES_DATA = $(shell find $(CATEGORIES_DATA_PATH))
ATTRIBUTES_DATA = $(shell find $(ATTRIBUTES_DATA_PATH))
VALUES_DATA     = $(shell find $(VALUES_DATA_PATH))
MAPPINGS_DATA   = $(shell find $(MAPPINGS_DATA_PATH))

###############################################################################
# COMMANDS

#
# BUILD commands and children
default: build
.PHONY: default

build: $(DIST_GENERATED_SENTINEL) \
	$(DOCS_GENERATED_SENTINEL)
.PHONY: build

$(DOCS_GENERATED_SENTINEL): $(DEV_DB) $(CATEGORIES_DATA) $(ATTRIBUTES_DATA) $(VALUES_DATA)
	@$(GENERATE) "Building Docs" "$(GENERATED_DOCS_PATH)/*"
	$(V)./bin/generate_docs $(VERBOSE_ARG)
	$(V)touch $@

$(DIST_GENERATED_SENTINEL): $(DEV_DB) $(CATEGORIES_DATA) $(ATTRIBUTES_DATA) $(VALUES_DATA) $(MAPPINGS_DATA)
	@$(GENERATE) "Building Distribution" "$(DIST_PATH)/*.[json|txt]"
	$(V)bin/generate_dist --locales $(LOCALES) $(VERBOSE_ARG)
	$(V)touch $@

#
# RELEASE
release: $(DIST_GENERATED_SENTINEL)
	@$(RUN_CMD) "Preparing release"
	$(V)bin/generate_release $(VERBOSE_ARG)
.PHONY: release

#
# CLEAN
clean:
	@$(NUKE) "Cleaning sentinels" "$(DIST_GENERATED_SENTINEL) $(DOCS_GENERATED_SENTINEL)"
	$(V)rm -f $(DIST_GENERATED_SENTINEL) $(DOCS_GENERATED_SENTINEL)
	@$(NUKE) "Cleaning local dbs" "$(DEV_DB) $(TEST_DB)"
	$(V)rm -f $(DEV_DB)* $(TEST_DB)*
	@$(NUKE) "Cleaning unstable docs" $(GENERATED_DOCS_PATH)
	$(V)rm -rf $(GENERATED_DOCS_PATH)
.PHONY: clean

#
# COMMANDS
run_docs: $(DOCS_GENERATED_SENTINEL)
	@$(RUN_CMD) "Running docs server"
	$(V)bundle exec jekyll serve --source docs --destination _site $(VERBOSE_ARG)
.PHONY: run_docs

console:
	@$(RUN_CMD) "Running console with dependencies"
	$(V)bin/rails console
.PHONY: console

#
# DATABASE SETUP
seed: vet_schema_data
	@$(GENERATE) "Seeding Database" $(DEV_DB)
	$(V)bin/rails db:drop
	$(V)bin/rails db:schema:load
	$(V)bin/seed $(VERBOSE_ARG)
.PHONY: seed

$(DEV_DB):
	if [ ! -f $@ ]; then make seed; fi

#
# TESTS
test: test_unit test_integration vet_schema
.PHONY: test

test_unit:
	@$(RUN_CMD) "Running Unit Tests"
	$(V)bin/rails unit $(filter-out $@,$(MAKECMDGOALS))
.PHONY: test_unit

test_integration:
	@$(RUN_CMD) "Running Integration Tests"
	$(V)bin/rails integration $(filter-out $@,$(MAKECMDGOALS))
.PHONY: test_integration

vet_schema: vet_schema_data vet_schema_dist
.PHONY: .vet_schema

vet_schema_data:
	@$(RUN_CMD) "Validating $(ATTRIBUTES_DATA_PATH) schema"
	$(V)cue vet schema/data/attributes_schema.cue $(ATTRIBUTES_DATA_PATH)
	@$(RUN_CMD) "Validating $(CATEGORIES_DATA_PATH) schema"
	$(V)cue vet schema/data/categories_schema.cue -d '#schema' $(CATEGORIES_DATA_PATH)
	@$(RUN_CMD) "Validating $(VALUES_DATA_PATH) schema"
	$(V)cue vet schema/data/values_schema.cue -d '#schema' $(VALUES_DATA_PATH)
.PHONY: vet_schema_data

vet_schema_dist:
	@$(RUN_CMD) "Validating $(ATTRIBUTES_JSON) schema"
	$(V)cue vet schema/dist/attributes_schema.cue $(ATTRIBUTES_JSON)
	@$(RUN_CMD) "Validating $(CATEGORIES_JSON) schema"
	$(V)cue vet schema/dist/categories_schema.cue $(CATEGORIES_JSON)
	@$(RUN_CMD) "Validating $(TAXONOMY_JSON) schema"
	$(V)cue vet schema/dist/attributes_schema.cue $(TAXONOMY_JSON)
	$(V)cue vet schema/dist/categories_schema.cue $(TAXONOMY_JSON)
	@$(RUN_CMD) "Validating $(MAPPINGS_JSON) schema"
	$(V)cue vet schema/dist/mappings_schema.cue $(MAPPINGS_JSON)
.PHONY: vet_schema_dist
