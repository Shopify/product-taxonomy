<p align="center"><img src="./docs/assets/img/header.png" /></p>

<!-- omit in toc -->
<h1 align="center">Shopify's Standard Product Taxonomy <a href="./VERSION"><img src="https://img.shields.io/badge/Version-2024--07-blue.svg" alt="Version"></a></h1>

**🌍 Global Standard**: Our open-source, standardized product taxonomy establishes a universal language for product classification. Comprehensive and already empowering merchants on Shopify.

**👩🏼‍💻 Integration Friendly**: With a stable structure and diverse formats our taxonomy is designed for effortless integration into any system.

**🚀 Industry Benchmark**: Spanning 25+ essential verticals, our taxonomy encompasses categories, attributes, and values, all thoughtfully integrated within Shopify and numerous marketplaces.

<p align="right"><em>Learn more on <a href="https://help.shopify.com/manual/products/details/product-category">help.shopify.com</a></em></p>

<!-- omit in toc -->
## 🗂️ Table of Contents

- [📚 The Taxonomy](#-the-taxonomy)
  - [🕹️ Interactive explorer](#️-interactive-explorer)
- [🧭 Getting started](#-getting-started)
  - [🧩 1. Integrators: How to integrate with the taxonomy](#-1-integrators-how-to-integrate-with-the-taxonomy)
    - [🗺️ Mapping to other taxonomies](#️-mapping-to-other-taxonomies)
  - [🧑🏼‍🏫 2. Taxonomists: How to make changes to the taxonomy](#-2-taxonomists-how-to-make-changes-to-the-taxonomy)
  - [👩🏼‍💻 3. Developers: How to evolve the system](#-3-developers-how-to-evolve-the-system)
    - [🛠️ Setup and dependencies](#️-setup-and-dependencies)
    - [⛰️ Common tasks](#️-common-tasks)
    - [📂 Navigating this repository](#-navigating-this-repository)
- [🧑‍💻 Contributing](#-contributing)
- [📅 Releases](#-releases)
- [📜 License](#-license)

## 📚 The Taxonomy

Our taxonomy is an open-source comprehensive, global standard for product classification. It's a universal language that empowers merchants to categorize their products. Spanning 25+ essential verticals, our taxonomy encompasses categories, attributes, and values, all thoughtfully integrated within Shopify and numerous marketplaces.

### 🕹️ Interactive explorer

Ready to dive in? [Explore our taxonomy interactively](https://shopify.github.io/product-taxonomy/releases/2024-07/?categoryId=sg-4-17-2-17) to visualize and discover what's published across the many categories, attributes, and values.

## 🧭 Getting started

This repository is the home of Shopify's Standard Product Taxonomy. It houses the source-of-truth data, the distribution files for implementation, and the source code that makes this all sing.

You can think of this repository serving 3 primary users:

1. **Integrators**: Those who integrate the taxonomy into other systems. You want **stable distribution files**.
2. **Taxonomists**: Those who want to evolve the taxonomy itself. You want to work with the **source-of-truth data files**.
3. **Developers**: Those who want to evolve _how this ETL pipeline_ works, or add richer tooling for other users. You work with the **application files**.

### 🧩 1. Integrators: How to integrate with the taxonomy

Dive straight into [`dist`](./dist/) to find the files you need and integrate this taxonomy into your system.

We offer `txt` and `json` formats to make it easy to integrate with your systems. If you have a specific format you'd like to see, please open an issue and let us know!

#### 🗺️ Mapping to other taxonomies

To make it easier to integrate with the taxonomy, we have also included a set of data called _mappings_. These are rules that can be used to convert between categories and attributes in the Shopify taxonomy to categories and attributes of another taxonomy. For more on mappings see documentaton in the [integrations](./data/integrations/README.md) directory.

### 🧑🏼‍🏫 2. Taxonomists: How to make changes to the taxonomy

Everything comes from the source-of-truth files in [`data/`](./data).

You may submit PRs against these files to change the taxonomy itself.

If you make changes to any files in [`data/`](./data), you'll need to update the distribution files. There are two ways:
1. Make a PR comment of `/generate_dist` to have CI commit the changes for you 🤖
2. Run `make` locally and commit the changes yourself

### 👩🏼‍💻 3. Developers: How to evolve the system

Everything else is how we manage the taxonomy and generate distributions. This is where the magic happens.

This is a simple ETL app composed of a few core models. The app is built on Rails and Jekyll:
- Rails is used to generate distribution files from `data/` and ensure the correctness of results.
- Jekyll is used to serve the documentation locally and on GitHub pages.

#### 🛠️ Setup and dependencies

For Shopify employees or folks with [`minidev`](https://github.com/burke/minidev):
- Run `dev up`

For everyone else you'll need to:
- Install `ruby`, version matching `.ruby-version`
- Install [`cue`](https://github.com/cue-lang/cue?tab=readme-ov-file#download-and-install), version 0.7.x or higher
- Install `make`
- Run `bundle install`

#### ⛰️ Common tasks

Here are the commands you'll use most often:

```sh
make [build]  # build the dist and documentation files
make clean    # remove sentinels and generated files
make seed     # parse data/ into local db
make console  # irb with dependencies loaded
make test     # run ruby tests and cue schema verification
make run_docs # http://localhost:4000 interactive view of dist/
```

If you want to add a new distribution format, you'll need to do 3 things:
1. Add new serialization methods to relevant models (e.g., `Category#as_json`, `Category#as_pkl`)
2. Extend `bin/generate_dist` to write files in the new format
3. Extend the `Makefile` to add the new file format to the clean target

#### 📂 Navigating this repository

This is a rails app after all, so we'll give a map of the _novel_ pieces of our system:

```
├── Makefile             # key dev and build commands
├── app/                 # rails standard
├── bin/
│   ├── generate_dist    # primary entrypoint for generating dist/
│   └── generate_docs    # primary entrypoint for generating docs/
├── db/
│   ├── schema.rb        # because this is a local-only app, we don't use migrations
│   └── seed.rb          # a custom seed script to load data/ into the local db
├── dist/                # generated distribution files
├── data/
│   ├── integrations/    # integrations and mappings between taxonomies
│   └── localizations/   # localizations for categories, attributes, and values
│   ├── categories/      # source-of-truth for categories
│   ├── attributes.yml   # source-of-truth for attributes
│   └── values.yml       # source-of-truth for values
└── test/                # rails standard
```

## 🧑‍💻 Contributing

We welcome contributions! Before we can merge any changes you submit, you'll need to sign the Shopify CLA (a friendly robot will help when you open your first PR 🤖).

## 📅 Releases

You can always find the current published version in [`VERSION`](./VERSION). The changelog is available in [`CHANGELOG.md`](./CHANGELOG.md).

Versions are determined by [CalVer](https://calver.org/), in sync with [Shopify's API release schedule](https://shopify.dev/docs/api/usage/versioning#release-schedule).

That means a stable release every 3 months **at most**, at the beginning of the quarter. Version names are date-based to be meaningful and semantically unambiguous (for example, `2024-07`).

Formal releases are published as Github releases and available on the [interactive docs site](https://shopify.github.io/product-taxonomy/).

## 📜 License

Shopify's Product Taxonomy is released under the [MIT License](./LICENSE). So go ahead, explore, play, and build something awesome!
