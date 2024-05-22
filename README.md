<p align="center"><img src="./docs/assets/img/header.png" /></p>

<!-- omit in toc -->
<h1 align="center">Shopify's Standard Product Taxonomy <img src="https://img.shields.io/badge/preview-orange.svg" alt="Preview"> <a href="./VERSION"><img src="https://img.shields.io/badge/version-vUNRELEASED-orange.svg" alt="Version"></a></h1>

**🌍 Global Standard**: Our open-source, standardized product taxonomy establishes a universal language for product classification. Comprehensive and already empowering merchants on Shopify.

**👩🏼‍💻 Integration Friendly**: With a stable structure and diverse formats our taxonomy is designed for effortless integration into any system.

**🚀 Industry Benchmark**: Spanning 25+ essential verticals, our taxonomy encompasses categories, attributes, and values, all thoughtfully integrated within Shopify and numerous marketplaces.

<p align="right"><em>Learn more on <a href="https://help.shopify.com/manual/products/details/product-category">help.shopify.com</a></em></p>

<!-- omit in toc -->
## 🗂️ Table of Contents

- [🕹️ Interactive explorer](#️-interactive-explorer)
- [📚 Taxonomy overview](#-taxonomy-overview)
- [🧭 Getting started](#-getting-started)
  - [🧩 How to integrate with the taxonomy](#-how-to-integrate-with-the-taxonomy)
  - [🧑🏼‍🏫 How to make changes to the taxonomy](#-how-to-make-changes-to-the-taxonomy)
  - [👩🏼‍💻 How to evolve the system](#-how-to-evolve-the-system)
- [🤿 Diving in](#-diving-in)
- [🛠️ Setup and dependencies](#️-setup-and-dependencies)
- [📂 How this is all organized](#-how-this-is-all-organized)
- [🧑‍💻 Contributing](#-contributing)
- [📅 Releases](#-releases)
- [📜 License](#-license)

## 🕹️ Interactive explorer

Ready to dive in? [Explore our taxonomy interactively](https://shopify.github.io/product-taxonomy/releases/unstable/?categoryId=gid%3A%2F%2Fshopify%2FTaxonomyCategory%2Fsg-4-17-2-17) to visualize and discover what's published across the many categories, attributes, and values.

## 📚 Taxonomy overview

Our taxonomy is an open-source comprehensive, global standard for product classification. It's a universal language that empowers merchants to categorize their products. Spanning 25+ essential verticals, our taxonomy encompasses categories, attributes, and values, all thoughtfully integrated within Shopify and numerous marketplaces.

## 🧭 Getting started

This repository is the home of Shopify's Standard Product Taxonomy. It houses the source-of-truth data, the distribution files for implementation, and the source code that makes this all sing.

We've structured it to be as user-friendly as possible, whether you're looking to integrate the taxonomy into your system, suggest changes, or delve into how it's developed and maintained.

### 🧩 How to integrate with the taxonomy

Dive straight into [`dist`](./dist/) to find the files you need and integrate this taxonomy into your system.

We're working on a variety of formats to make it easy to integrate with your systems. Today we have `txt` and `json` formats, and we're working on more. If you have a specific format you'd like to see, please open an issue and let us know!

### 🧑🏼‍🏫 How to make changes to the taxonomy

> **🔵 Note**: While we are in preview we are not actively seeking PRs.

Everything comes from the source-of-truth files in [`data/`](./data). This is where you should submit PRs to change the taxonomy itself.

### 👩🏼‍💻 How to evolve the system

Everything else is how we manage the taxonomy and generate distributions. This is where the magic happens.

## 🤿 Diving in

This is a simple ruby app with a few models and serializers. The bulk of the work is parsing `data/` into a tree of `app/models/category.rb` to serialize reliably to `dist/`. The app is set up to be rails-like including using `ActiveRecord`.

Everything ultimately runs through `make` (`dev` simply proxies). Here are the commands you'll use most often:

```sh
make [build] # build the dist and documentation files
make clean   # remove sentinels and all generated files
make seed    # parse data/ into local db
make console # irb with dependencies loaded
make test    # run ruby tests and cue schema verification
make server  # http://localhost:4000 interactive view of dist/
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
1. Add a new serializer to `app/serializers/dist/`
2. Extend `bin/generate_dist` to use your new serializer and write files

For your explorations, here's a map of the land:

```
├── Makefile             # key dev and build commands
├── Rakefile             # manages ruby tests
├── app/
│   └── models/          # most models are simple data objects
│       ├── category.rb  # node-based tree impl for categories
│       └── ...
├── bin/
│   ├── generate_dist    # primary entrypoint for generating dist/
│   └── generate_docs    # primary entrypoint for generating docs/
├── config/              # setup for the app, including DB config
├── db/
│   ├── schema.rb        # defines tables for models
│   └── seed.rb          # seeds the db from data/
├── dist/                # generated distribution files
├── data/
│   ├── integrations/    # integrations and mappings between taxonomies
│   └── localizations/   # localizations for categories, attributes, and values
│   ├── categories/      # source-of-truth for categories
│   ├── attributes.yml   # source-of-truth for attributes
│   └── values.yml       # source-of-truth for values
└── test/
```

## 🧑‍💻 Contributing

We welcome contributions! Before we can merge any changes you submit, you'll need to sign the Shopify CLA (a friendly robot will help when you open your first PR 🤖).

## 📅 Releases

You can always find the current published version in [`VERSION`](./VERSION). The changelog is available in [`CHANGELOG.md`](./CHANGELOG.md).

While this is `UNSTABLE`, we're using SemVer, but when this goes stable it will transition to [CalVer](https://calver.org/), in sync with [Shopify's API release schedule](https://shopify.dev/docs/api/usage/versioning#release-schedule).

That means a stable release every 3 months **at most**, at the beginning of the quarter. Version names are date-based to be meaningful and semantically unambiguous (for example, `2024-07`).

Formal releases are published as Github releases and available on the [interactive docs site](https://shopify.github.io/product-taxonomy/).

## 📜 License

Shopify's Product Taxonomy is released under the [MIT License](./LICENSE). So go ahead, explore, play, and build something awesome!
