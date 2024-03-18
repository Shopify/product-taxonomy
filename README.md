<p align="center"><img src="./docs/assets/img/header.png" /></p>

<!-- omit in toc -->
<h1 align="center">Shopify's Standard Product Taxonomy <img src="https://img.shields.io/badge/preview-orange.svg" alt="Preview"> <a href="./VERSION"><img src="https://img.shields.io/badge/version-v0.10.0-blue.svg" alt="Version"></a></h1>

**🌍 Global Standard**: Our open-source, standardized product taxonomy establishes a universal language for product classification. Comprehensive and already empowering merchants on Shopify.

**👩🏼‍💻 Integration Friendly**: With a stable structure and diverse formats our taxonomy is designed for effortless integration into any system.

**🚀 Industry Benchmark**: Spanning 22 essential verticals, our taxonomy encompasses categories, attributes, and values, all thoughtfully integrated within Shopify and numerous marketplaces.

<p align="right"><em>Learn more on <a href="https://help.shopify.com/manual/products/details/product-category">help.shopify.com</a></em></p>

<!-- omit in toc -->
## 🗂️ Table of Contents

- [tl;dr;](#tldr)
- [🤿 Diving in](#-diving-in)
- [🛠️ Setup and dependencies](#️-setup-and-dependencies)
- [📂 How this is all organized](#-how-this-is-all-organized)
- [📅 Releases](#-releases)
- [📜 License](#-license)


## tl;dr;

This is a simple ruby app with a few models and serializers. The bulk of the work is parsing `data/` into a tree of `app/models/category.rb` to serialize reliably to `/dist/`. The app is setup to be rails-like, but  is not a rails app, though is using `ActiveRecord`.

## 🤿 Diving in

Everything ultimately runs through `make` (`dev` simply proxies). Here are the commands you'll use most often:

```sh
make        # build the dist and documentation files
make clean  # remove sentinels and all generated files
make seed   # parse /data into local db
make test   # run ruby tests and cue schema verification
make server # http://localhost:4000 interactive view of /dist/
```

## 🛠️ Setup and dependencies

For Shopify employees or folks with [`minidev`](https://github.com/burke/minidev):
- Run `dev up`

For everyone else you'll need to:
- Install `ruby`, version matching `.ruby-version`
- Install [`cue`](https://github.com/cue-lang/cue?tab=readme-ov-file#download-and-install), version 0.7.x or higher
- Install `make`
- Run `bundle install`

When you edit any cue files, ensure you're running `cue fmt`. This will format the cue files to the standard format.

## 📂 How this is all organized

Most folks won't touch most of this, but we see you 👩🏼‍💻.

If you want to add a new serialization target, three simple steps:
1. Add a new serializer to `app/serializers`
2. Add the file load to `application.rb`
3. Extend `bin/generate_dist` to use your new serializer and write files

For your own explorations, here's a map of the land:

```
./
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

## 📅 Releases

You can always find the current version in [`VERSION`](./VERSION).

We follow time-based releases consistent with [Shopify's API release schedule](https://shopify.dev/docs/api/usage/versioning#release-schedule) _at most_. That means a release every 3 months at the beginning of the quarter. Version names are date-based to be meaningful and semantically unambiguous (for example, `2024-01`).

## 📜 License

Shopify's Product Taxonomy is released under the [MIT License](./LICENSE). So go ahead, explore, play, and build something awesome!
