package product_taxonomy

#attribute_gid_regex: "^gid://shopify/Taxonomy/Attribute/\\d+$"
#value_gid_regex: "^gid://shopify/Taxonomy/Value/\\d+$"
#category_gid_regex: "^gid://shopify/Taxonomy/Category/[a-zA-Z]{2}(-\\d+)*$"
#mapping_taxonomy_version_regex: "^\\w+/v(\\d+\\.)*\\d+$"

// This file defines and enforces the shape of the data for dist/attributes.json and dist/categories.json
// There are additional validations handled in validations.cue in this directory but use this to understand
// the shape of the data.

// Both the categories.json and attributes.json file are imported into this cue package for the purposes
// of this validation. These keys might all be in one file, or split across multiple, cue doesn't care.

// Present in categories.json / categories_data.cue. If this is specified in multiple files this enforces their equality.
version!: string & =~"^\\d+.\\d+.\\d+$"

// Present in attributes.json / attributes_data.cue
attributes!: [
	...{
		id!:      string & =~#attribute_gid_regex
		name!:    string
		values!: [
			...{
				// TODO: Consider this for categories somehow
				id!:   string & =~#value_gid_regex
				name!: string
			},
		]
	},
]

_category_reference: {
	id!:   string & =~#category_gid_regex
	name!: validations.category_lookup[id]
}

// Present in categories.json / categories_data.cue
verticals!: [...{
	name!:   string
	prefix!: string & =~"^[a-zA-Z]{2}$"
	categories!: [...{
		id!:        string & =~#category_gid_regex
		name!:      validations.category_lookup[id]
		level!:     int & >=0
		full_name!: string
		parent_id:  null | string & =~#category_gid_regex
		attributes!: [...{
			id!: string & =~#attribute_gid_regex
			// The name must match the name of the attribute being referenced
			name!: string & validations.attribute_lookup[id]
		}]
		children!: [..._category_reference]
		ancestors!: [..._category_reference]
	}]
}]

// Present in mappings.json / mappings_data.cue
mappings!: [
	...{
		input_taxonomy!:  string & =~#mapping_taxonomy_version_regex
		output_taxonomy!: string & =~#mapping_taxonomy_version_regex
		rules!: [
			...{
				input!: {
					product_category_id: string & =~#category_gid_regex
					attributes?: [...{
						name:  string & =~#attribute_gid_regex
						value: string & =~#value_gid_regex | null
					}]
				}
				output!: [string]: _
			},
		]
	},
]
