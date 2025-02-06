<p align="center"><img src="./docs/assets/img/header.png" /></p>

<!-- omit in toc -->
<h1 align="center">Shopify's Standard Product Taxonomy <a href="./VERSION"><img src="https://img.shields.io/badge/Version-2024--10-blue.svg" alt="Version"></a></h1>

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

Ready to dive in? [Explore our taxonomy interactively](https://shopify.github.io/product-taxonomy/releases/latest/?categoryId=sg-4-17-2-17) to visualize and discover what's published across the many categories, attributes, and values.

## 🧭 Getting started

This repository is the home of Shopify's Standard Product Taxonomy. It houses the source-of-truth data, the distribution files for implementation, and the source code that makes this all sing.

You can think of this repository serving 3 primary users:

1. **Integrators**: Those who integrate the taxonomy into other systems. You want **stable distribution files**.
2. **Taxonomists**: Those who want to evolve the taxonomy itself. Submit a change request or work directly with the **source-of-truth data files** themselves.
3. **Developers**: Those who want to evolve _how this ETL pipeline_ works, or add richer tooling for other users. You work with the **application files**.

### 🧩 1. Integrators: How to integrate with the taxonomy

Dive straight into [`dist`](./dist/) to find the files you need and integrate this taxonomy into your system.

We offer `txt` and `json` formats to make it easy to integrate with your systems. If you have a specific format you'd like to see, please open an issue and let us know!

#### 🗺️ Mapping to other taxonomies

To make it easier to integrate with the taxonomy, we have also included a set of data called _mappings_. These are rules that can be used to convert between categories and attributes in the Shopify taxonomy to categories and attributes of another taxonomy. For more on mappings see documentaton in the [integrations](./data/integrations/README.md) directory.

### 🧑🏼‍🏫 2. Taxonomists: How to make changes to the taxonomy

Submit a [taxonomy tree change request](https://github.com/Shopify/product-taxonomy/issues/new?template=1-taxonomy-tree-requests.yml) to give us insight and evolve the taxonomy. This is the simplest way to effect change.

Alternatively, you may submit PRs directly yourself against the source-of-truth files in [`data/`](./data).

If you make changes to any files in [`data/`](./data), you'll need to update the distribution files by running:

```
cd dev
bundle install
bin/product_taxonomy dist
```

#### 🌐 Localization to other languages

Our taxonomy supports translations to various languages in the [`localizations`](https://github.com/Shopify/product-taxonomy/tree/main/data/localizations) directory. To report a translation issue (non-English text), submit a [localization fix request](https://github.com/Shopify/product-taxonomy/issues/new?template=2-localization-fix-requests.yml).

### 👩🏼‍💻 3. Developers: How to evolve the system

Everything else is how we manage the taxonomy and generate distributions. This is where the magic happens.

In the `dev/` subfolder is a simple ETL app composed of a few core models. Jekyll is used to serve the documentation locally and on GitHub pages.

#### 🛠️ Setup and dependencies

- Install `ruby`, version matching `dev/.ruby-version`
- Install [`cue`](https://github.com/cue-lang/cue?tab=readme-ov-file#download-and-install), version 0.7.x or higher
- Run `cd dev && bundle install`

#### ⛰️ Common tasks

Here are the commands you'll use most often:

```sh
cd dev

# Download dependencies
bundle install

# Commands to manage the taxonomy
bin/product-taxonomy dist     # build the dist files
bin/product-taxonomy docs     # build the documentation files
bin/product-taxonomy release  # generate a release

# Development tasks (via Rake)
bundle exec rake test              # run all tests
bundle exec rake test:unit         # run unit tests only
bundle exec rake test:integration  # run integration tests only
bundle exec rake benchmark         # run benchmarks

# Docs
bundle exec rake docs:serve        # start Jekyll server for doc microsite

# Schema validation tasks
bundle exec rake schema:vet        # validate all schemas (data and dist)
bundle exec rake schema:vet_data   # validate data schemas only
bundle exec rake schema:vet_dist   # validate distribution schemas only
```

#### 📂 Navigating this repository

```
├── data
│   ├── attributes.yml   # source-of-truth for attributes
│   ├── categories       # source-of-truth for categories
│   ├── integrations     # integrations and mappings between taxonomies
│   ├── localizations    # localizations for categories, attributes, and values
│   └── values.yml       # source-of-truth for values
├── dev                  # ETL app for managing the taxonomy
├── dist                 # generated distribution files
└── docs                 # documentation microsite served with Jekyll
```

## 🧑‍💻 Contributing

We welcome contributions! Before we can merge any changes you submit via PR, you'll need to sign the Shopify CLA (a friendly robot will help when you open your first PR 🤖).

## 📅 Releases

You can always find the current published version in [`VERSION`](./VERSION). The changelog is available in [`CHANGELOG.md`](./CHANGELOG.md).

Versions are determined by [CalVer](https://calver.org/), in sync with [Shopify's API release schedule](https://shopify.dev/docs/api/usage/versioning#release-schedule).

That means a stable release every 3 months **at most**, at the beginning of the quarter. Version names are date-based to be meaningful and semantically unambiguous (for example, `2024-07`).

Formal releases are published as Github releases and available on the [interactive docs site](https://shopify.github.io/product-taxonomy/).

## 📜 License

Shopify's Product Taxonomy is released under the [MIT License](./LICENSE). So go ahead, explore, play, and build something awesome!
