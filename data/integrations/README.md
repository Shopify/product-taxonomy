# Integrations
Integrations maintain the rules for how the Shopify Product Taxonomy interacts with other taxonomy systems in the world of commerce.

## Supported Integrations
- Google (2021-09-21)
- Shopify (from 2022-02 onwards)

## How this works
### Overview

Integrations live in the `data/integrations` directory and are further grouped by integration handle and version.

```
data/integrations/
├── integrations.yml  # lists integrations and their versions for taxonomy mappings in distribution
├── <integration 1>  # name/handle of the commerce system (e.g. google/amazon)
│   ├── <version> # e.g. v1.0.1 or 2024-07
│   │   ├── mappings
│   │   │   ├── from_shopify.yml
│   │   │   └── to_shopify.yml
│   │   └── full_names.yml
│   └── <another version>
│       └── ...
└── <integration 2> #...
```

Generated distribution files for mappings can be found in `dist/{locale}/integrations`.

```
dist/{locale}/integrations/
├── all_mappings.json  # contains all taxonomy mappings for all available integrations
├── <integration 1>  # e.g. google, shopify
│   ├── <source_taxonomy_version>_to_<target_taxonomy_version>.json # e.g. shopify_2024-07_to_google_2021-09-21.json
│   └── <source_taxonomy_version>_to_<target_taxonomy_version>.txt
└── <integration 2>
```

### Mappings
The primary concern of integrations are mappings. Mappings are a set of rules that help us convert to and from the Shopify taxonomy and the taxonomy of that integration.

#### Examples of mapping rules

```yaml
# Mapping rule from Shopify taxonomy to Google taxonomy
input:
  product_category_id: aa # Apparel & Accessories (Shopify)
output:
  product_category_id:
  - '166' # Apparel & Accessories (Google)

# Mapping rule from Shopify legacy taxonomy to Shopify latest taxonomy
input:
  product_category_id: 126
output:
  product_category_id:
  - aa
```

<details>
<summary>Output as JSON</summary>

For the example above, `dist/en/integrations/all_mappings.json` would contain the following generated JSON output

```json
{
  "version": "0.18.0",
  "mappings": [
    {
      "input_taxonomy": "shopify/2024-07",
      "output_taxonomy": "google/2021-09-21",
      "rules": [
        //...
        {
          "input": {
            "category": {
              "id": "gid://shopify/TaxonomyCategory/aa",
              "full_name": "Apparel & Accessories"
            }
          },
          "output": {
            "category": [
              {
                "id": "166",
                "full_name": "Apparel & Accessories"
              }
            ]
          }
        },
        //...
      ]
    },
    {
      "input_taxonomy": "shopify/2022-02",
      "output_taxonomy": "shopify/2024-07",
      "rules": [
        //...
        {
          "input": {
            "category": {
              "id": "126",
              "full_name": "Apparel & Accessories"
            }
          },
          "output": {
            "category": [
              {
                "id": "gid://shopify/TaxonomyCategory/aa",
                "full_name": "Apparel & Accessories"
              }
            ]
          }
        },
        //...
      ]
    }
  ]
}
```
</details>

#### Unmapped Product Categories
In cases where certain product categories from the source do not align with any available categories in the target taxonomy, these should be clearly listed in the `unmapped_product_category_ids` field. This field is optional and can be included in mapping files such as `from_shopify.yml` or `to_shopify.yml`. It should be positioned at the same hierarchical level as the `rules` field.


#### Examples of unmapped product category ids
```yaml

# Mapping rules from Shopify taxonomy to Google taxonomy
rules:
  - input:
    product_category_id: aa # Apparel & Accessories (Shopify)
  - output:
    product_category_id:
      - '166' # Apparel & Accessories (Google)
  ...

# product category ids without a corresponding match in Google taxonomy.
unmapped_product_category_ids:
  - ae-2-2-4-1-5 # Shotguns (Shopify)
  - ae-2-2-4-1-3 # Replica Guns (Shopify)
  ...
```


As `unmapped_product_category_ids` is designed to explicitly exclude certain mappings from the CI validator checks, `unmapped_product_category_ids` is not included in the distribution mapping files (e.g., `dist/en/integrations/all_mappings.json`)
<details>
<summary>Output as JSON</summary>

For the example above, `dist/en/integrations/all_mappings.json` would contain the following generated JSON output

```json
{
  "version": "0.18.0",
  "mappings": [
    {
      "input_taxonomy": "shopify/2024-07",
      "output_taxonomy": "google/2021-09-21",
      "rules": [
        //...
        {
          "input": {
            "category": {
              "id": "gid://shopify/TaxonomyCategory/aa",
              "full_name": "Apparel & Accessories"
            }
          },
          "output": {
            "category": [
              {
                "id": "166",
                "full_name": "Apparel & Accessories"
              }
            ]
          }
        },
        //...
      ]
    },
  ]
}
```
</details>

