.DEFAULT_GOAL := default

###############################################################################
# FORMATTING HELPERS
# Used throughout the makefile for pretty printing and toggling verbose output

ifeq ($(VERBOSE),1)
	V=
	VPIPE=
	VARG=--verbose
else
	V=@
	VPIPE= >/dev/null
	VARG=
endif

FMT      = printf "\e[%sm>> %-21s\e[0;1m →\e[1;32m %s\e[0m\n"
GENERATE = $(FMT) "1;34" # bold blue
NUKE     = $(FMT) "1;31" # bold red
ADVISORY = printf "\e[%sm!! %-21s\e[0;1m\n" "1;31" # bold red text with a !! prefix
RUN_CMD  = printf "\e[%sm>> %-21s\e[0;1m\n" "1;34" # bold blue text with a >> prefix


###############################################################################
# INPUTS

CATEGORIES_DATA = $(shell find data/categories)
ATTRIBUTES_DATA = $(shell find data/attributes.yml)
VALUES_DATA     = $(shell find data/values.yml)
MAPPINGS_DATA   = $(shell find data/integrations/*/*/mappings)

###############################################################################
# TARGETS
# Many commands generate many files (that'll expand), and Make isn't great at
# targeting arbitrary numbers of outputs, so we'll use sentinels.

# DOCS
GENERATED_DOCS_PATH = docs/_data/unstable
DOCS_GENERATED_SENTINEL = tmp/.docs_generated_sentinel

# DIST
GENERATED_DIST_PATH = dist
DIST_GENERATED_SENTINEL = tmp/.dist_generated_sentinel
CATEGORIES_JSON = $(GENERATED_DIST_PATH)/categories.json
ATTRIBUTES_JSON = $(GENERATED_DIST_PATH)/attributes.json
MAPPINGS_JSON = $(GENERATED_DIST_PATH)/mappings.json

# DATA files to run application
DEV_DB = storage/development.sqlite3
TEST_DB = storage/test.sqlite3

# CUE imports needed for schema validation
ATTRIBUTES_DATA_CUE = schema/attributes_data.cue
CATEGORIES_DATA_CUE = schema/categories_data.cue
MAPPINGS_DATA_CUE = schema/mappings_data.cue

###############################################################################
# COMMANDS

#
# BUILD commands and children
default: build
.PHONY: default

build: $(DIST_GENERATED_SENTINEL) \
	$(DOCS_GENERATED_SENTINEL) \
	$(CATEGORIES_DATA_CUE) \
	$(ATTRIBUTES_DATA_CUE) \
	$(MAPPINGS_DATA_CUE)
.PHONY: build

$(DOCS_GENERATED_SENTINEL): $(DEV_DB) $(CATEGORIES_DATA) $(ATTRIBUTES_DATA) $(VALUES_DATA)
	@$(GENERATE) "Building Docs" "$(GENERATED_DOCS_PATH)/*"
	$(V)./bin/generate_docs $(VARG)
	$(V)touch $@

$(DIST_GENERATED_SENTINEL): $(DEV_DB) $(CATEGORIES_DATA) $(ATTRIBUTES_DATA) $(VALUES_DATA) $(MAPPINGS_DATA)
	@$(GENERATE) "Building Distribution" "$(GENERATED_DIST_PATH)/*.[json|txt]"
	$(V)bin/generate_dist $(VARG)
	$(V)touch $@

#
# RELEASE
release: build
	@$(RUN_CMD) "Preparing release"
	$(V)bin/generate_release $(VARG)
.PHONY: release

#
# CLEAN
clean:
	@$(NUKE) "Cleaning dev db" $(DEV_DB)
	$(V)rm -f $(DEV_DB)*
	@$(NUKE) "Cleaning test db" $(TEST_DB)
	$(V)rm -f $(TEST_DB)*
	@$(NUKE) "Cleaning generated docs" $(GENERATED_DOCS_PATH)
	$(V)rm -f $(DOCS_GENERATED_SENTINEL)
	$(V)rm -rf $(GENERATED_DOCS_PATH)
	@$(NUKE) "Cleaning attribute data cuefile" $(ATTRIBUTES_DATA_CUE)
	$(V)rm -f $(ATTRIBUTES_DATA_CUE)
	@$(NUKE) "Cleaning category data cuefile" $(CATEGORIES_DATA_CUE)
	$(V)rm -f $(CATEGORIES_DATA_CUE)
	@$(NUKE) "Cleaning mapping data cuefile" $(MAPPINGS_DATA_CUE)
	$(V)rm -f $(MAPPINGS_DATA_CUE)
	@$(NUKE) "Cleaning generated distribution files" $(GENERATED_DIST_PATH)
	$(V)rm -f $(DIST_GENERATED_SENTINEL)
	$(V)rm -rf $(GENERATED_DIST_PATH)/*.json
	$(V)rm -rf $(GENERATED_DIST_PATH)/*.txt
.PHONY: clean

#
# COMMANDS
server: $(DOCS_GENERATED_SENTINEL)
	@$(RUN_CMD) "Running server"
	$(V)bundle exec jekyll serve --source docs --destination _site $(VARG)
.PHONY: server

console:
	@$(RUN_CMD) "Running console with dependencies"
	$(V)bin/console
.PHONY: console

#
# DATABASE SETUP
seed:
	@$(GENERATE) "Seeding Database" $(DEV_DB)
	$(V)rake db:drop
	$(V)rake db:schema_load
	$(V)bin/seed $(VARG)
.PHONY: seed

$(DEV_DB): seed

#
# TESTS
test: vet_schema
	@$(RUN_CMD) "Running All Tests"
	$(V)bin/rake test $(filter-out $@,$(MAKECMDGOALS))
.PHONY: test

unit_tests:
	@$(RUN_CMD) "Running Unit Tests"
	$(V)bin/rake unit $(filter-out $@,$(MAKECMDGOALS))
.PHONY: unit_tests

integration_tests:
	@$(RUN_CMD) "Running Integration Tests"
	$(V)bin/rake integration $(filter-out $@,$(MAKECMDGOALS))
.PHONY: integration_tests

vet_schema: $(CATEGORIES_DATA_CUE) $(ATTRIBUTES_DATA_CUE) $(MAPPINGS_DATA_CUE)
	@$(RUN_CMD) "Validating Schema"
	$(V)cd schema && cue vet
	$(V)echo "Done!"
.PHONY: vet_schema

# TODO: These two targets can be done together
$(CATEGORIES_DATA_CUE): $(DIST_GENERATED_SENTINEL)
	@$(GENERATE) "Importing $(CATEGORIES_JSON)" $(CATEGORIES_DATA_CUE)
	$(V)cue import $(CATEGORIES_JSON) -p product_taxonomy -f -o $(CATEGORIES_DATA_CUE)

$(ATTRIBUTES_DATA_CUE): $(DIST_GENERATED_SENTINEL)
	@$(GENERATE) "Importing $(ATTRIBUTES_JSON)" $(ATTRIBUTES_DATA_CUE)
	$(V)cue import $(ATTRIBUTES_JSON) -p product_taxonomy -f -o $(ATTRIBUTES_DATA_CUE)

$(MAPPINGS_DATA_CUE): $(DIST_GENERATED_SENTINEL)
	@$(GENERATE) "Importing $(MAPPINGS_JSON)" $(MAPPINGS_DATA_CUE)
	$(V)cue import $(MAPPINGS_JSON) -p product_taxonomy -f -o $(MAPPINGS_DATA_CUE)
