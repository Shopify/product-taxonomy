<p align="center"><img src="./img/header.png" /></p>

<!-- omit in toc -->
<h1 align="center">Shopify's Standard Product Taxonomy <img src="https://img.shields.io/badge/preview-orange.svg" alt="Preview"> <a href="./VERSION"><img src="https://img.shields.io/badge/version-v0.10.0-blue.svg" alt="Version"></a></h1>

**🌍 Global Standard**: Our open-source, standardized product taxonomy establishes a universal language for product classification. Comprehensive and already empowering merchants on Shopify.

**👩🏼‍💻 Integration Friendly**: With a stable structure and diverse formats our taxonomy is designed for effortless integration into any system.

**🚀 Industry Benchmark**: Spanning 22 essential verticals, our taxonomy encompasses categories, attributes, and values, all thoughtfully integrated within Shopify and numerous marketplaces.

<p align="right"><em>Learn more on <a href="https://help.shopify.com/manual/products/details/product-category">help.shopify.com</a></em></p>

<!-- omit in toc -->
## 🗂️ Table of Contents

- [🕹️ Interactive explorer](#️-interactive-explorer)
- [📚 Taxonomy overview](#-taxonomy-overview)
- [🧭 Getting started](#-getting-started)
  - [🧩 How to integrate with the taxonomy: `releases` @ `/` (you're here!)](#-how-to-integrate-with-the-taxonomy-releases---youre-here)
  - [🧑🏼‍🏫 How to make changes to the taxonomy: `main` @ `data/`](#-how-to-make-changes-to-the-taxonomy-main--data)
  - [👩🏼‍💻 How to evolve the system: `main` @ `/`](#-how-to-evolve-the-system-main--)
- [📅 Releases](#-releases)
- [📜 License](#-license)

## 🕹️ Interactive explorer

Ready to dive in? [Explore our taxonomy interactively](https://shopify.github.io/product-taxonomy/?categoryId=gid%3A%2F%2Fshopify%2FTaxonomy%2FCategory%2Fsg-4-17-2-17) to visualize and discover what's published across the many categories, attributes, and values.

## 📚 Taxonomy overview

Our taxonomy is an open-source comprehensive, global standard for product classification. It's a universal language that empowers merchants to categorize their products. Spanning 22 essential verticals, our taxonomy encompasses categories, attributes, and values, all thoughtfully integrated within Shopify and numerous marketplaces.

What's next? ⏭️ More attributes and values as we work to make this truly comprehensive.

## 🧭 Getting started

This repository is the home of Shopify's Standard Product Taxonomy. It houses the source-of-truth data, the distribution files for implementation, and the source code that makes this all sing.

We've structured it to be as user-friendly as possible, whether you're looking to integrate the taxonomy into your own system, suggest changes, or delve into how it's developed and maintained.

### 🧩 How to integrate with the taxonomy: [`releases` @ `/`](./) (you're here!)

Dive straight into `releases` to find the files you need and integrate this taxonomy into your system.

We're working on a variety of formats to make it easy to integrate with your systems. Today we have `txt` and `json` formats, and we're working on more. If you have a specific format you'd like to see, please open an issue and let us know!

### 🧑🏼‍🏫 How to make changes to the taxonomy: [`main` @ `data/`](https://github.com/Shopify/product-taxonomy/tree/main/data)

> **🔵 Note**: While we are in preview we are not actively seeking PRs.

Everything comes from the source-of-truth in `data/`. This is where you can submit PRs to change the taxonomy itself.

### 👩🏼‍💻 How to evolve the system: [`main` @ `/`](https://github.com/Shopify/product-taxonomy/tree/main)

You can see how how the taxonomy is generated and maintained. This is where the magic happens.

For more information, see the [dev README](https://github.com/Shopify/product-taxonomy/blob/main/README.md)

## 📅 Releases

You can always find the current published version in [`VERSION`](./VERSION). The changelog is available in [`CHANGELOG.md`](./CHANGELOG.md).

We follow time-based releases consistent with [Shopify's API release schedule](https://shopify.dev/docs/api/usage/versioning#release-schedule) _at most_. That means a release every 3 months at the beginning of the quarter. Version names are date-based to be meaningful and semantically unambiguous (for example, `2024-01`).

## 📜 License

Shopify's Product Taxonomy is released under the [MIT License](./LICENSE). So go ahead, explore, play, and build something awesome!
