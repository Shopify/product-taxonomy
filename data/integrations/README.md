# Integrations
Integrations maintain the rules for how the Shopify Product Taxonomy interacts with other taxonomy systems in the world of commerce.

## Supported Integrations
- Google (2021-09-21)

## How this works
### Overview

Integrations live in the `data/integrations` directory and are further grouped by integration handle and version.

```
data/integrations/
├── integrations.yml  # index
├── <integration 1>  # name/handle of the commerce system (e.g. google/amazon)
│   ├── <version> # e.g. v1.0.1 or 2024-04
│   │   └── mappings
│   │       ├── from_shopify.yml
│   │       └── to_shopify.yml
│   └── <another version>
│       └── ...
└── <integration 2> #...
```

### Mappings
The primary concern of integrations are mappings. Mappings are a set of rules that help us convert to and from the Shopify taxonomy and the taxonomy of that integration.

Each mapping is generated from a set of mapping rules that are defined as inputs and outputs. Inputs and outputs are sparse-products which means they are shaped like the products of the taxonomies being mapped. Attributes in a input/output can be one of the following:

| Type of Entry | Matching logic |
|---------------|----------------|
| single value |match for this specific single value |
| list | match for any value that is in the list of values |
| present | match for any any valid value for this attribute |
| nil | matches when the value is not present (or is a null-type) |

#### Examples of mapping rules

```yaml
# Simple mapping rule (e.g. Shopify -> Google)
input:
    product_category_id: aa # Apparel & Accessories (Shopify)
output:
    product_category_id: 166 # Apparel & Accessories (Google)


# More complex mapping rules (e.g. Shopify -> Amazon)
input:
    product_category_id: aa-6-9
    attributes:
        - name: target_gender
          value: target_gender__female
output:
    amazon_category:
        - 3888171
        - 9539904011
input:
    product_category_id: aa-6-9
output:
    product_type:
        - Jewelry/FineRing
        - Jewelry/Ring

```

#### Generating mappings from rules
Mappings are generated from the rules as a part of the build/distribution step:
- Combinations for all input variations are generated for all product categories and their attributes that appear in the inputs found in the set of rules
  - As an optimization, combinations including attributes that do not occur in any rules are omitted
- Builder then passes each generated input through the set of rules, reducing the output of each matching rule into a final output
  - To combine outputs, we do a union of all attributes
  - When an attributes is present in both outputs being combined an intersection is done

Putting this all together, let us look at how mappings could be compiled for the `Apparel & Accessories > Jewelry > Rings` category in Shopify taxonomy to relevant Amazon categories (using attribute/attribute value names and handles for easier reading):

```yaml
# Rule 1 - Adult Rings
input:
    product_category_id: aa-6-9 # Shopify: Apparel & Accessories > Jewelry > Rings
    attributes:
        - name: age_group
          value: age_group__adults
output:
    amazon_category: # list of all valid categories for adult rings
        - 3888171 # Men > Jewelry > Rings
        - 9539904011 # Men > Jewelry > Wedding Rings
        - 9539894011 # Women > Jewelry > Women's Wedding & Engagement Rings
        - 9539902011 # Women's Anniversary Rings
        - 9539895011 # Women's Bridal Rings
        - 9539896011 # Women's Engagement Rings
        #...
```

```yaml
# Rule 2 - Men's Rings
input:
    product_category_id: aa-6-9 # Shopify: Apparel & Accessories > Jewelry > Rings
    attributes:
        - name: target_gender
          value: target_gender__male
output:
    amazon_category: # list of all valid categories for male rings
        - 3888171 # Men > Jewelry > Rings
        - 9539904011 # Men > Jewelry > Wedding Rings
        - 3880891 # Boys > Jewelry > Rings
```

```yaml
# Rule 3 - Women's Rings
input
    product_category_id: aa-6-9 # Shopify: Apparel & Accessories > Jewelry > Rings
    attributes:
        - name: target_gender
          value: target_gender__female
output
    amazon_category: # list of all valid categories for female rings
        - 9539894011 # Women > Jewelry > Women's Wedding & Engagement Rings
        - 9539902011 # Women's Anniversary Rings
        - 9539895011 # Women's Bridal Rings
        - 9539896011 # Women's Engagement Rings
        - 3881961 # Girls > Jewelry > Rings
```

---

**Final Mapping (JSON)**

```json
[
    {
        "input": {
            "product_category_id": "aa-6-9",
            "attributes": [
                {
                    "name": "target_gender",
                    "value": "target_gender__male"
                },
                {
                    "name": "age_group",
                    "value": "age_group__adults"
                }
            ]
        },
        "output": {
            "amazon_category": [3888171, 9539904011]
        }
    }, // Matches rules 1 and 2
    {
        "input": {
            "product_category_id": "aa-6-9",
            "attributes": [
                {
                    "name": "target_gender",
                    "value": "target_gender__female"
                },
                {
                    "name": "age_group",
                    "value": "age_group__adults"
                }
            ]
        },
        "output": {
            "amazon_category": [9539894011, 9539902011, 9539895011, 9539896011]
        }
    } // Matches rules 1 and 3
]

```
