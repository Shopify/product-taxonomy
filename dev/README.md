## Hacking on product-taxonomy

### Dependencies

For Shopify employees or folks with [`minidev`](https://github.com/burke/minidev):
- Run `dev up`

For everyone else you'll need to:
- Install `ruby`, version matching `.ruby-version`
- Install [`cue`](https://github.com/cue-lang/cue?tab=readme-ov-file#download-and-install), version 0.7.x or higher
- Install `make`
- Run `bundle install`

When you edit any cue files, ensure you're running `cue fmt`. This will format the cue files to the standard format.

### Running locally

Run `make serve` to start a local server to view the taxonomy.

### Building Dist/Docs

When you update the data folder, run `make` to rebuild the dist and documentation files.

This will also import the dist files as cue for the schema validation.

### Tests

Run `make test` to validate the cue schema, as well as run the ruby tests.
