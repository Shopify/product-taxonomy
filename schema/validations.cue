package product_taxonomy

import ("list")

// This file is responsible for verifying the referential integrity of the product taxonomy
// For the shape of the taxonomy, see schema.cue. Like the schema, this runs validations on data
// when it's actually present, allowing for conditional validation of slices of data as required.

// There are a few validations that will be used in the schema to enforce referential integrity
// the rest are used only for validation of data.

// validations.attribute_lookup and validations.attribute_value_lookup can be used to ensure
// that the denormalized names being used in the schema do in fact match their references.

// print the result of a specific validation with `cue eval -e validations.attribute_names` for example.
// cue eval -c will throw the error in the case of a disjunction.

validations: {}

// We start with validating attributes, and their values for uniqueness and for lookup tables used in the schema.
// Then we'll flat map the categories to ensure we get the same guarentees there.

// We can only perform these validations if we have the data present.
// The schema will throw errors if this data is missing, so no need to pile on additional errors.
if (len(attributes) > 0) {

	// Check for uniqueness of attribute names, ids are handled via validations.attribute_lookup
	validations: attribute_names: [for x in attributes {x.name}]
	validations: attribute_names_unique: true & list.UniqueItems(validations.attribute_names)

	validations: attribute_value_integrity: [string]: {names_unique: bool, ids_unique: bool}
	for k in attributes {
		// Note: This handles Name <> ID uniqueness, since you cannot override values in cue
		validations: attribute_lookup: {
			"\(k.id)": k.name
		}

		// Ensure attribute value names and ids are unique per attribute
		validations: attribute_value_integrity: {
			"\(k.id)": {
				names_unique: true & list.UniqueItems([for v in k.values {v.name}])
				ids_unique: true & list.UniqueItems([for v in k.values {v.id}])
			}
		}

		// Note: This handles Name <> ID uniqueness, since you cannot override values in cue
		for v in k.values {
			validations: attribute_value_lookup: {
				"\(v.id)": v.name
			}
		}
	}
}

// Same as above, no need to pile on a bunch of errors if the schema is ensuring data is present here
if (len(verticals) >= 0 && len(attributes) >= 0) {
	for vertical in verticals {
		validations: {
			vertical_names: [for x in verticals {x.name}]
			vertical_prefixes: [for x in verticals {x.prefix}]
			vertical_uniqueness: {
				names:    true & list.UniqueItems(vertical_names)
				prefixes: true & list.UniqueItems(vertical_prefixes)
			}
		}
		for category in vertical.categories {
			// Note: This handles Name <> ID uniqueness, since you cannot override values in cue
			validations: category_lookup: {
				"\(category.id)": category.name
			}
		}
	}
}
