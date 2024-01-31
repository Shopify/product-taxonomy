# Shopify's Standard Product Taxonomy ([v0.0.1](./VERSION))

Shopify's public product taxonomy serves as an open-source, standardized, and global classification of products sold on Shopify. Composed of product categories, attributes, and attribute values, the taxonomy is leveraged across Shopify and is integrated with numerous marketplaces. To learn more, visit our [help docs](https://help.shopify.com/manual/products/details/product-type); to request early access, fill out the form [here](http://shopify.com/editions/winter2024#new-taxonomy).


[Browse Shopify's product taxonomy](https://refactored-broccoli-1wvy2wl.pages.github.io/)

## Supported Verticals

| Vertical | Status |
|----------|----------|
| Apparel & Accessories | ✅ | 
| Food, Beverages, & Tobacco | ✅ |
| Home & Garden | ✅ |
| Sporting Goods | ✅ |
| Furniture | Coming soon [next] | 
| Health & Beauty | Coming soon [next] |
| Animals & Pet supplies | Coming soon |
| Electronics | Coming soon |
| Media | Coming soon |
| Arts & Entertainmen | Coming soon |
| Vehicles & parts | Coming soon |
| Toys & games | Coming soon |
| Luggage & bags | Coming soon |
| Software | Coming soon |
| Cameras & optics | Coming soon |
| Hardware | Coming soon |
| Baby & toddler | Coming soon |
| Business & industrial | Coming soon |
| Office supplies | Coming soon |
| Services | Coming soon |

As new verticals are made available in the coming weeks, they will be added to this repository.

## Organization

This github repository includes both the source code for defining the taxonomy, as well as distribution files for consuming the taxonomy. We welcome public input to evolve and adjust this taxonomy. Requested changes will be reviewed and considered for subsequent version updates.

### Distribution files

Used to consume the taxonomy. These are packaged in multiple formats for easy parsing and review.

Current formats:
- `txt`
- `json`

Coming soon:
- `jsonl`
- `parquet`

### Source & Data files

Used to manage and update the taxonomy itself, along with necessary files to generate published formats reliably. When proposing adjustments to Shopify's product taxonomy, submit changes to these files.


```
# Helper commands for generation
bin/

# Source-code for generation itself
src/

# Source-of-truth for the taxonomy
# Use these files to submit PRs for changes to the taxonomy
data/
  categories/
    aa_apparel_accessories.yml
    ...
```

## Releases

Releases will be managed on Github and will generally follow [semver](https://semver.org/). The current version can always be found in [`VERSION`](./VERSION).

## License

Shopify's Product Taxonomy is released under the [MIT License](./LICENSE).
