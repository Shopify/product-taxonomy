## 0.13.0 (Apr 5, 2024)

Add 2 more verticals.

### 📚 Taxonomy

- Adds `Gift Cards` vertical
- Adds `Product Add-Ons` vertical

## 0.12.0 (Apr 3, 2024)

- Shift attribute and attribute value friendly_ids to be consistent.
- Text distribution for values includes primary property.

## 0.11.0 (Apr 2, 2024)

Making GIDs spec-compliant.

### 👩🏼‍💻 Structure

- Category GID from `gid://shopify/Taxonomy/Category/*` → `gid://shopify/TaxonomyCategory/*`
- Attribute GID from `gid://shopify/Taxonomy/Attribute/*` → `gid://shopify/TaxonomyAttribute/*`
- Attribute Value GID from `gid://shopify/Taxonomy/Value/*` → `gid://shopify/TaxonomyValue/*`

## 0.10.0 (Mar 14, 2024)

### 📚 Taxonomy Attribute Updates

- Product attributes in the taxonomy have been refined, splitting the general 'material' attribute into more specific categories such as 'fabric', 'cocktail decoration material', 'safety equipment material' etc.

## 0.9.0 (Mar 4, 2024)

Changed GID structure for Attribute Values and added more txt distributions.

### 👩🏼‍💻 Structure

- Attribute GID from `gid://shopify/Taxonomy/Attribute/123/12` → `gid://shopify/Taxonomy/Value/12`
- Added both `dist/attributes.txt` and `dist/attributes_values.txt`

### 💅🏼 Enhancement

- DB is now in a file instead of in-memory to save unnecessary seeding

## 0.8.0 (Mar 1, 2024)

Adds 3 more verticals.

### 📚 Taxonomy
- Adds `Mature` vertical
- Adds `Religious & Ceremonial` vertical
- Adds `Services` vertical

## 0.7.0 (Feb 29, 2024)

Adds 2 more verticals.

### 📚 Taxonomy
- Adds `Toys & Games` vertical
- Adds `Vehicles & Parts` vertical

## 0.6.0 (Feb 23, 2024)

Adds 2 more verticals.

### 📚 Taxonomy
- Adds `Business & Industrial` vertical
- Adds `Software` vertical

## 0.5.0 (Feb 23, 2024)

Adds 6 more verticals.

### 📚 Taxonomy
- Adds `Animals & Pet Supplies` vertical
- Adds `Arts & Entertainment` vertical
- Adds `Baby's & Toddlers` vertical
- Adds `Cameras & Optics` vertical
- Adds `Media` vertical
- Adds `Office Supplies` vertical

## 0.4.0 (Feb 23, 2024)

Adds 2 more verticals.

### 📚 Taxonomy

- Adds `Hardware` vertical
- Adds `Luggage & Bags` vertical

## 0.3.0 (Feb 21, 2024)

Adds electronics and simplifies existing verticals.

### 📚 Taxonomy

- Adds `Electronics` vertical
- Simplifies `Food, Beverages, & Tobacco` vertical
- Simplifies `Health & Beauty` vertical
- Simplifies `Sporting Goods` vertical

## 0.2.0 (Feb 14, 2024)

Adds the next vertical.

### 📚 Taxonomy

- Adds `Health & Beauty` vertical
- Adds `Uncategorized` category

## 0.1.0 (Feb 6, 2024)

Structure CHANGED for `dist/attributes.json`. Adds schema validation.

### 📚 Taxonomy

- Attribute distribution JSON is now normative, with top-level `attributes` and `version` keys

### 💅🏼 Enhancement

- `cue` added to validate `dist/` while providing a clear spec of the distribution files

## 0.0.3 (Feb 2, 2024)

Adds the next vertical.

### 📚 Taxonomy

- Adds `Furniture` vertical

## 0.0.2 (Feb 2, 2024)

Sort output and improve the developer experience.

### 📚 Taxonomy

- Category distribution files are now sorted by name
- Attribute distribution files are now sorted by name

### 💅🏼 Enhancement

- Add an additional output, `taxonomy.json` that gives you all the data in one file

## 0.0.1 (Jan 31, 2024)

Initial public release.

### 📚 Taxonomy

Adds verticals:
- `Apparel & Accessories`
- `Food, Beverages, & Tobacco`
- `Home & Garden`
- `Sporting Goods`
