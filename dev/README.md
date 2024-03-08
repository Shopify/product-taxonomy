# Hacking on product-taxonomy

This is a simple ruby app with a few models and serializers. The bulk of the work is parsing `data/` into a tree of `app/models/category.rb` to serialize reliably to `/dist/`. The app is setup to be rails-like, but  is not a rails app, though is using `ActiveRecord`.

## Diving in 🤿

Everything ultimately runs through `make` (`dev` simply proxies). Here are the commands you'll use most often:

```sh
make        # build the dist and documentation files
make clean  # remove sentinels and all generated files
make seed   # parse /data into local db
make test   # run ruby tests and cue schema verification
make server # http://localhost:4000 interactive view of /dist/
```

## Setup and dependencies 🛠️

For Shopify employees or folks with [`minidev`](https://github.com/burke/minidev):
- Run `dev up`

For everyone else you'll need to:
- Install `ruby`, version matching `.ruby-version`
- Install [`cue`](https://github.com/cue-lang/cue?tab=readme-ov-file#download-and-install), version 0.7.x or higher
- Install `make`
- Run `bundle install`

When you edit any cue files, ensure you're running `cue fmt`. This will format the cue files to the standard format.

## How this is all organized 📂

Most folks won't touch most of this, but we see you 👩🏼‍💻.

If you want to add a new serialization target, three simple steps:
1. Add a new serializer to `app/serializers`
2. Add the file load to `application.rb`
3. Extend `bin/generate_dist` to use your new serializer and write files

For your own explorations, here's a map of the land:

```
dev/
├── application.rb  # handles file loading "app-wide"
├── Makefile        # primary source of useful commands
├── Rakefile        # only used for testing
├── app/
│   ├── models/         # most models are simple data objects
│   │   ├── category.rb     # node-based tree impl for categories
│   │   └── ...
│   └── serializers/    # serializers are per-format, not per-model
│       ├── json.rb
│       └── text.rb
├── bin/
│   ├── generate_dist   # file IO for /data → /dist
│   └── generate_docs   # file IO for /dist → /docs
├── db/
│   ├── schema.rb       # defines in-memory tables for models
│   └── seed.rb         # seed the db by parsing data shaped from /data
└── test/
```
