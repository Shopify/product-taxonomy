# Shopify's Standardized Product Taxonomy

Shopify's standardized and public product taxonomy used across our systems. Standardizes product categories, attributes, and attribute values.

## Organization

Organized into a few key folders, which are important to understand how to consume and contribute:

- `src` is likely to change regularly and is NOT a stable shape to integrate against. See nested `README` files.
- `dist` is the stable output. Split by owners and output formats.
- `bin` helper methods to generate `dist`.

## Releases

Managed with releases on Github and generally follows [semver](https://semver.org/). Current version always found in [`VERSION`](./VERSION).

## License

Shopify's Product Taxonomy is released under the [MIT License](./LICENSE).
