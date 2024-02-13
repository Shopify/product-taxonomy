## Hacking on product-taxonomy

### Dependencies
For Shopify Employees: Run `dev up` to install ruby and the dependencies.

For everyone else: You'll need the ruby version indicated within the `.ruby-version` file, and make.
Run `bundle install` to install the dependencies

You will also need cue installed to be able to run the schema validation commands, you can find the steps to do this [here](https://github.com/cue-lang/cue?tab=readme-ov-file#download-and-install).
At the time of writing, cue version 0.7.x or higher has been tested.

If you're editing cue, either use an editor plugin to run `cue fmt` on save, or do so manually to avoid whitespace issues

### Building Dist/Docs

When you update the data folder, run `make` to rebuild the dist and documentation files.
This will also import the dist files as cue for the schema validation

### Tests

Run `make test` to validate the cue schema, as well as run the ruby tests


