# Shopify's Standard Product Taxonomy in _Early Access Preview_

Shopify's public product taxonomy serves as an open-source, standardized, and global classification of products sold on Shopify. Composed of product categories, attributes, and attribute values, the taxonomy is leveraged across Shopify and is integrated with numerous marketplaces. To learn more, and to request early access on your Shopify store, refer to our [help docs](https://help.shopify.com/manual/products/details/product-category).

## Currently Supported Verticals
Three taxonomy verticals are currently available for preview:
* Apparel & Accessories
* Home & Garden
* Sporting Goods

As new verticals are made available in the coming weeks, they will be added to this repository.

## Organization
This github repository includes both the source code for defining the taxonomy, as well as distribution files for consuming the taxonomy. We welcome public input to evolve and adjust this taxonomy. All requested changes will be reviewed regularily and when appropriate, approved for the next version update. 

#### Overview:
**Distribution files**: Used to consume the taxonomy. These are packaged as simple txt for easy parsing and review. More file formats will be made available in the coming weeks. 

**Source files**: Used to manage source code. These are stored in yaml format. When proposing adjustments to Shopify product taxonomy, submit changes using these files. 

```
# Distribution files - Use this folder for integration.
dist/
  txt/
    categories.txt
    categories/
      aa_apparel_accessories.txt
      ...

# helper methods to generate dist
bin/

# Source (of truth) files - Use these files to submit PRs for changes to the taxonomy.
src/
  categories/
    aa_apparel_accessories.yml
    ...

```

## Releases

Releases will be managed on Github and will generally follow [semver](https://semver.org/). The current version can always be found in [`VERSION`](./VERSION).

## License

Shopify's Product Taxonomy is released under the [MIT License](./LICENSE).
