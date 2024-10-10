## 2024-10-unstable

#### 📚 Taxonomy Updates
Expanded taxonomy with new categories, attributes and values to enhance coverage and categorization accuracy, informed by user feedback and market insights.

##### Apparel & Accessories

- Adds `Leotards & Unitards`, `Fashion Face Masks` and `Hair Bands`.
- Adds `Clothing Sewing Materials`.

##### Arts & Entertainment

- Adds `Comic Books` with the attributes `Comic tradition` and `Comic edition` in the Collectibles area.
- Adds `Guitar Pedals`.
- Adds the attribute `Mesh type` in the Fabrics area.

##### Baby & Toddler

- Adds `Feeding Essentials` (`Feeding Bowls`, `Plates`, `Spoons` and `Flatware Sets`).

##### Business & Industrial

- Adds `Raw Structural Components` in the Construction area.
- Adds `Heavy Machinery Parts & Accessories`.

##### Electronics

- Adds `Gaming Computers`.
- Adds the attribute `Microphone design` in the Microphones category.

##### Food, Beverages & Tobacco

- Adds the attributes `Grind size` and `Caffeine content` in the Coffee area.
- Adds the attribute `Chocolate type` in the Chocolate category.

##### Hardware

- Adds `Micrometers` and `Micrometer Accessories` with the attribute `Micrometer type`.

##### Health & Beauty

- Adds `Medical Face Masks`.

##### Home & Garden

- Adds `Paintings` with the attributes `Art medium`, `Art movement` and `Artwork authenticity` in the Visual Artwork area.
- Adds `Diffusers` ('Electric', 'Plug-In', 'Ultrasonic') and 'Reed Diffuser Sticks'.
- Adds `Air Fryers` with the attributes `Cooking compartment` and `Air fryer functions`.
- Adds `Food Processors`.
- Adds `Champagne`, `Cocktail` and `Wine Glasses` with the attribute `Drinkware shape` in the Stemware area.
- Adds a `Hydroponics` area, including:
  - `Growing Media` (`Clay Pebbles`, `Coconut Coir`, `Perlite`, `Rockwool` and `Vermiculite`) with the attributes `pH level` and `Plant stage`;
  - `Grow Lights` (`Fluorescent`, `HID` and `LED`);
  - `Hydroponic Systems` (`Aeroponics`, `Aquaponics`, `DWC`, `Drip Systems`, `Ebb & Flow` and `NFT`); and
  - `Nutrients & Supplements` (`Nutrient Solutions`, `pH Adjusters` and `Supplements`).
- Adds `Irrigation Systems`.
- Adds `Head Towels` and `Hand Towels`.

##### Luggage & Bags

- Adds `Hiking Backpacks`, `Military Backpacks`, `Laptop Backpacks` and `Laptop Bags`.

##### Sporting Goods

- Adds `American Football Shoes`, `Basketball Shoes`, `Cricket Shoes`, `Dancing Shoes` (with the attribute `Dance style`), `Field Hockey & Lacrosse Shoes`, `Racquetball & Squash Shoes`, `Rugby Shoes`, `Soccer Shoes`, `Tennis Shoes`, `Cycling Shoes`, `Golf Shoes`, `Badminton Shoes` and `Climbing Shoes`.
- Adds `Camping Hammocks` and `Camping Hammock Accessories`.
- In the Archery area, adds `Arrow Shafts`, `Arrow Rests`, `Bow & Crossbow Cases & Covers`, `Hardware & Parts`, `Scopes & Sights`, `Stabilizers`, `Range Accessories` and `Tools & Equipment` (including `Tool Accessories`, `Tools` and `Bow Presses`), along with the attributes `Archery target type` and `Broadhead design`.
- Adds the attributes `Racket head balance` and `Racket shape` to Racket Sports categories.

##### Miscellaneous

- Expands the `Language version` attribute to include more languages and regional variations.
- Expands the `Size` attribute to include options for babies and toddlers.
- Extends existing attributes to additional categories.
- Includes other value additions.

## 2024-07
- The first stable release of "Shopify's Standard Product Taxonomy". 

## Pre-Stable Changelog

### 0.18.0 (May 17, 2024)
- Importing attribute descriptions
- Importing latest localizations
- Updating country attribute

### 0.17.0 (Apr 26, 2024)

#### Updated Attribute Data format
- The attributes data file has two new root level properties, `base_attributes` and `extended_attributes`
  - The `base_attributes` represent the base level attribute that contain an `id` and `values`.
  - The `extended_attributes` property contain attributes that have extended a `base_attribute`. They do not have an `id` and indicate their parent via the `values_from` property.

#### Updated Attribute Distribution format

- Attributes that extend another attribute have been removed and placed under a `extended_attributes` property.
- Categories that contain an extended attribute have these attributes indicated by an `extended` property.

### 0.16.0 (Apr 15, 2024)

#### Taxonomy Mappings

- Add mapping data from shopify/2022-02 to new shopify categories

### 0.15.0 (Apr 12, 2024)

#### Taxonomy Attribute Updates

- Product attributes in the taxonomy have been further refined, adding new 'Features'-based attributes
- Nested data within `data/` directory files are now sorted alphabetically
  - data/categories/*.yml: `category.attributes` array
  - data/attributes.yml: `attribute.values` array

### 0.14.0 (Apr 9, 2024)

- Add `parent_id` field to attributes.json dist output

### 0.13.0 (Apr 5, 2024)

Add 2 more verticals.

#### 📚 Taxonomy

- Adds `Gift Cards` vertical
- Adds `Product Add-Ons` vertical

### 0.12.0 (Apr 3, 2024)

- Shift attribute and attribute value friendly_ids to be consistent.
- Text distribution for values includes primary property.

### 0.11.0 (Apr 2, 2024)

Making GIDs spec-compliant.

#### 👩🏼‍💻 Structure

- Category GID from `gid://shopify/Taxonomy/Category/*` → `gid://shopify/TaxonomyCategory/*`
- Attribute GID from `gid://shopify/Taxonomy/Attribute/*` → `gid://shopify/TaxonomyAttribute/*`
- Attribute Value GID from `gid://shopify/Taxonomy/Value/*` → `gid://shopify/TaxonomyValue/*`

### 0.10.0 (Mar 14, 2024)

#### 📚 Taxonomy Attribute Updates

- Product attributes in the taxonomy have been refined, splitting the general 'material' attribute into more specific categories such as 'fabric', 'cocktail decoration material', 'safety equipment material' etc.

### 0.9.0 (Mar 4, 2024)

Changed GID structure for Attribute Values and added more txt distributions.

#### 👩🏼‍💻 Structure

- Attribute GID from `gid://shopify/Taxonomy/Attribute/123/12` → `gid://shopify/Taxonomy/Value/12`
- Added both `dist/attributes.txt` and `dist/attributes_values.txt`

#### 💅🏼 Enhancement

- DB is now in a file instead of in-memory to save unnecessary seeding

### 0.8.0 (Mar 1, 2024)

Adds 3 more verticals.

#### 📚 Taxonomy
- Adds `Mature` vertical
- Adds `Religious & Ceremonial` vertical
- Adds `Services` vertical

### 0.7.0 (Feb 29, 2024)

Adds 2 more verticals.

#### 📚 Taxonomy
- Adds `Toys & Games` vertical
- Adds `Vehicles & Parts` vertical

### 0.6.0 (Feb 23, 2024)

Adds 2 more verticals.

#### 📚 Taxonomy
- Adds `Business & Industrial` vertical
- Adds `Software` vertical

### 0.5.0 (Feb 23, 2024)

Adds 6 more verticals.

#### 📚 Taxonomy
- Adds `Animals & Pet Supplies` vertical
- Adds `Arts & Entertainment` vertical
- Adds `Baby's & Toddlers` vertical
- Adds `Cameras & Optics` vertical
- Adds `Media` vertical
- Adds `Office Supplies` vertical

### 0.4.0 (Feb 23, 2024)

Adds 2 more verticals.

#### 📚 Taxonomy

- Adds `Hardware` vertical
- Adds `Luggage & Bags` vertical

### 0.3.0 (Feb 21, 2024)

Adds electronics and simplifies existing verticals.

#### 📚 Taxonomy

- Adds `Electronics` vertical
- Simplifies `Food, Beverages, & Tobacco` vertical
- Simplifies `Health & Beauty` vertical
- Simplifies `Sporting Goods` vertical

### 0.2.0 (Feb 14, 2024)

Adds the next vertical.

#### 📚 Taxonomy

- Adds `Health & Beauty` vertical
- Adds `Uncategorized` category

### 0.1.0 (Feb 6, 2024)

Structure CHANGED for `dist/attributes.json`. Adds schema validation.

#### 📚 Taxonomy

- Attribute distribution JSON is now normative, with top-level `attributes` and `version` keys

#### 💅🏼 Enhancement

- `cue` added to validate `dist/` while providing a clear spec of the distribution files

### 0.0.3 (Feb 2, 2024)

Adds the next vertical.

#### 📚 Taxonomy

- Adds `Furniture` vertical

### 0.0.2 (Feb 2, 2024)

Sort output and improve the developer experience.

#### 📚 Taxonomy

- Category distribution files are now sorted by name
- Attribute distribution files are now sorted by name

#### 💅🏼 Enhancement

- Add an additional output, `taxonomy.json` that gives you all the data in one file

### 0.0.1 (Jan 31, 2024)

Initial public release.

#### 📚 Taxonomy

Adds verticals:
- `Apparel & Accessories`
- `Food, Beverages, & Tobacco`
- `Home & Garden`
- `Sporting Goods`
