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
ATTRIBUTES_DATA = $(shell find data/attributes)

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
STATIC_VERSION_FILE = $(GENERATED_DIST_PATH)/VERSION
STATIC_LICENSE_FILE = $(GENERATED_DIST_PATH)/LICENSE
STATIC_CHANGELOG_FILE = $(GENERATED_DIST_PATH)/CHANGELOG.md

# DATA files to run application
LOCAL_DB = tmp/local.sqlite3

# CUE imports needed for schema validation
ATTRIBUTES_DATA_CUE = schema/attributes_data.cue
CATEGORIES_DATA_CUE = schema/categories_data.cue

###############################################################################
# COMMANDS

#
# BUILD commands and children
default: build
.PHONY: default

build: $(DIST_GENERATED_SENTINEL) \
	$(STATIC_VERSION_FILE) \
	$(STATIC_LICENSE_FILE) \
	$(STATIC_CHANGELOG_FILE) \
	$(DOCS_GENERATED_SENTINEL) \
	$(CATEGORIES_DATA_CUE) \
	$(ATTRIBUTES_DATA_CUE)
.PHONY: build

$(DOCS_GENERATED_SENTINEL): $(LOCAL_DB) $(CATEGORIES_DATA) $(ATTRIBUTES_DATA)
	@$(GENERATE) "Building Docs" "$(GENERATED_DOCS_PATH)/*"
	$(V)./bin/generate_docs $(VARG)
	$(V)touch $@

$(DIST_GENERATED_SENTINEL): $(LOCAL_DB) $(CATEGORIES_DATA) $(ATTRIBUTES_DATA)
	@$(GENERATE) "Building Dist" "$(GENERATED_DIST_PATH)/*.[json|txt]"
	$(V)bin/generate_dist $(VARG)
	$(V)touch $@

$(STATIC_VERSION_FILE):
	@$(GENERATE) "Copying Version File" $(STATIC_VERSION_FILE)
	$(V)cp -f VERSION $(STATIC_VERSION_FILE)

$(STATIC_LICENSE_FILE):
	@$(GENERATE) "Copying License File" $(STATIC_LICENSE_FILE)
	$(V)cp -f LICENSE $(STATIC_LICENSE_FILE)

$(STATIC_CHANGELOG_FILE):
	@$(GENERATE) "Copying Changelog File" $(STATIC_CHANGELOG_FILE)
	$(V)cp -f CHANGELOG.md $(STATIC_CHANGELOG_FILE)

#
# CLEAN
clean:
	@$(NUKE) "Cleaning dev db" $(LOCAL_DB)
	$(V)rm -f $(LOCAL_DB)
	@$(NUKE) "Cleaning Generated Docs" $(GENERATED_DOCS_PATH)
	$(V)rm -f $(DOCS_GENERATED_SENTINEL)
	$(V)rm -rf $(GENERATED_DOCS_PATH)
	@$(NUKE) "Cleaning attribute data cuefiles" $(ATTRIBUTES_DATA_CUE)
	$(V)rm -f $(ATTRIBUTES_DATA_CUE)
	@$(NUKE) "Cleaning category data cuefiles" $(CATEGORIES_DATA_CUE)
	$(V)rm -f $(CATEGORIES_DATA_CUE)
	@$(NUKE) "Cleaning Generated Dist Files" $(GENERATED_DIST_PATH)
	$(V)rm -f $(DIST_GENERATED_SENTINEL)
	$(V)rm -f $(STATIC_VERSION_FILE)
	$(V)rm -f $(STATIC_LICENSE_FILE)
	$(V)rm -f $(STATIC_CHANGELOG_FILE)
	$(V)rm -rf $(GENERATED_DIST_PATH)/*.json
	$(V)rm -rf $(GENERATED_DIST_PATH)/*.txt
.PHONY: clean

#
# DOCS SERVER
server: $(DOCS_GENERATED_SENTINEL)
	@$(RUN_CMD) "Running Server"
	$(V)bundle exec jekyll serve --source docs --destination _site $(VARG)
.PHONY: server

#
# DATABASE SETUP
seed: $(LOCAL_DB)
.PHONY: seed

$(LOCAL_DB):
	@$(GENERATE) "Seeding Database" $(LOCAL_DB)
	$(V)bin/seed $(VARG)

#
# TESTS
test: unit_tests integration_tests vet_schema
.PHONY: test

unit_tests:
	@$(RUN_CMD) "Running Unit Tests"
	$(V)bin/rake test $(filter-out $@,$(MAKECMDGOALS))
.PHONY: unit_tests

integration_tests:
	@$(RUN_CMD) "Running Integration Tests"
	$(V)bin/rake test_integration $(filter-out $@,$(MAKECMDGOALS))
.PHONY: integration_tests

vet_schema: $(CATEGORIES_DATA_CUE) $(ATTRIBUTES_DATA_CUE)
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
