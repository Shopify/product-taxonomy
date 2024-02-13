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

# Inputs
CATEGORIES_DATA = $(shell find ../data/categories)
ATTRIBUTES_DATA = $(shell find ../data/attributes)

CATEGORIES_JSON = ../dist/categories.json
ATTRIBUTES_JSON = ../dist/attributes.json

# Targets

# Note, this is only because bin/generate_docs generates multiple files
# and would probably generate more in the future. Make isn't great at targeting
# arbitrary numbers of outputs, so we'll use a sentinel instead.
DOCS_GENERATED_SENTINEL = tmp/.docs_generated_sentinel
GENERATED_DOCS_PATH = ../docs/_data

# CUE imports needed for schema validation
ATTRIBUTES_DATA_CUE = ../schema/attributes_data.cue
CATEGORIES_DATA_CUE = ../schema/categories_data.cue

default: $(DOCS_GENERATED_SENTINEL) \
	$(CATEGORIES_DATA_CUE) \
	$(ATTRIBUTES_DATA_CUE)
.PHONY: default

clean:
	@$(NUKE) "Cleaning Generated Docs" $(GENERATED_DOCS_PATH)
	$(V)rm -f $(DOCS_GENERATED_SENTINEL)
	$(V)rm -rf $(GENERATED_DOCS_PATH)
	@$(NUKE) "Cleaning attribute data cuefiles" $(ATTRIBUTES_DATA_CUE)
	$(V)rm -f $(ATTRIBUTES_DATA_CUE)
	@$(NUKE) "Cleaning category data cuefiles" $(CATEGORIES_DATA_CUE)
	$(V)rm -f $(CATEGORIES_DATA_CUE)
.PHONY: clean

test:
	bin/rake test $@
.PHONY: test

$(DOCS_GENERATED_SENTINEL): $(CATEGORIES_DATA) $(ATTRIBUTES_DATA)
	@$(GENERATE) "Building Docs" "../docs/_data/*.yml"
	$(V)./bin/generate_docs
	$(V)touch $@

# TODO: These two targets can be done together
$(CATEGORIES_DATA_CUE): $(CATEGORIES_JSON)
	@$(GENERATE) "Importing $(CATEGORIES_JSON)" $(CATEGORIES_DATA_CUE)
	$(V)cue import $(CATEGORIES_JSON) -p product_taxonomy -f -o $(CATEGORIES_DATA_CUE)

$(ATTRIBUTES_DATA_CUE): $(ATTRIBUTES_JSON)
	@$(GENERATE) "Importing $(ATTRIBUTES_JSON)" $(ATTRIBUTES_DATA_CUE)
	$(V)cue import $(ATTRIBUTES_JSON) -p product_taxonomy -f -o $(ATTRIBUTES_DATA_CUE)
