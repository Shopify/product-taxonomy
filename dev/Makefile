.DEFAULT_GOAL := default

###############################################################################
# FORMATTING HELPERS
# Used throughout the makefile for pretty printing and toggling verbose output

ifeq ($(VERBOSE),1)
	V=
	VPIPE=
else
	V=@
	VPIPE= >/dev/null
endif

FMT      = printf "\e[%sm>> %-21s\e[0;1m →\e[1;32m %s\e[0m\n"
GENERATE = $(FMT) "1;34" # bold blue
NUKE     = $(FMT) "1;31" # bold red
ADVISORY = printf "\e[%sm!! %-21s\e[0;1m\n" "1;31" # bold red text with a !! prefix
RUN_CMD  = printf "\e[%sm>> %-21s\e[0;1m\n" "1;34" # bold blue text with a >> prefix

# Inputs
CATEGORIES_DATA = $(shell find ../data/categories)
ATTRIBUTES_DATA = $(shell find ../data/attributes)

# Targets

# Note, this is only because bin/generate_docs generates multiple files
# and would probably generate more in the future. Make isn't great at targeting
# arbitrary numbers of outputs, so we'll use a sentinel instead.
# also required for generating dist files
DOCS_GENERATED_SENTINEL = tmp/.docs_generated_sentinel
GENERATED_DOCS_PATH = ../docs/_data
DIST_GENERATED_SENTINEL = tmp/.dist_generated_sentinel
GENERATED_DIST_PATH = ../dist

# CUE imports needed for schema validation
ATTRIBUTES_DATA_CUE = ../schema/attributes_data.cue
CATEGORIES_DATA_CUE = ../schema/categories_data.cue

# DATA files to run application
LOCAL_DB = ../tmp/local.sqlite3

# JSON files generated
CATEGORIES_JSON = ../dist/categories.json
ATTRIBUTES_JSON = ../dist/attributes.json

default: $(CATEGORIES_DATA_CUE) \
	$(ATTRIBUTES_DATA_CUE) \
	$(DOCS_GENERATED_SENTINEL)
.PHONY: default

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
	$(V)rm -rf $(GENERATED_DIST_PATH)/*.json
	$(V)rm -rf $(GENERATED_DIST_PATH)/*.txt
.PHONY: clean

server:
	@$(RUN_CMD) "Running Server"
	$(V)bundle exec jekyll serve --source ../docs --destination ../_site
.PHONY: server

seed:
	@$(GENERATE) "Seeding Database" $(LOCAL_DB)
	$(V)bin/seed
.PHONY: seed

test: vet_schema unit_tests integration_tests
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
	$(V)cd ../schema && cue vet
	$(V)echo "Done!"
.PHONY: vet_schema

$(DOCS_GENERATED_SENTINEL): $(CATEGORIES_DATA) $(ATTRIBUTES_DATA)
	@$(GENERATE) "Building Docs" "../docs/_data/*.yml"
	$(V)./bin/generate_docs
	$(V)touch $@

# This generates both dist/categories.json and dist/attributes.json
$(DIST_GENERATED_SENTINEL): $(LOCAL_DB) $(CATEGORIES_DATA) $(ATTRIBUTES_DATA)
	@$(GENERATE) "Building Dist" "../dist/*.json"
	$(V)bin/generate_dist
	$(V)touch $@

$(LOCAL_DB): seed
ifeq ($(shell test -e $(LOCAL_DB) && echo -n yes),yes)
	seed
endif

# TODO: These two targets can be done together
$(CATEGORIES_DATA_CUE): $(DIST_GENERATED_SENTINEL)
	@$(GENERATE) "Importing $(CATEGORIES_JSON)" $(CATEGORIES_DATA_CUE)
	$(V)cue import $(CATEGORIES_JSON) -p product_taxonomy -f -o $(CATEGORIES_DATA_CUE)

$(ATTRIBUTES_DATA_CUE): $(DIST_GENERATED_SENTINEL)
	@$(GENERATE) "Importing $(ATTRIBUTES_JSON)" $(ATTRIBUTES_DATA_CUE)
	$(V)cue import $(ATTRIBUTES_JSON) -p product_taxonomy -f -o $(ATTRIBUTES_DATA_CUE)
