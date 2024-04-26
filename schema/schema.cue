package product_taxonomy

#attribute_gid_regex: "^gid://shopify/TaxonomyAttribute/\\d+$"
#value_gid_regex:     "^gid://shopify/TaxonomyValue/\\d+$"

#category_gid_regex: "^gid://shopify/TaxonomyCategory/[a-zA-Z]{2}(-\\d+)*$"

// This file defines and enforces the shape of the data for dist/attributes.json and dist/categories.json
// Data validations are handled by the application test-suite

// Present in categories.json / attributes.json / taxonomy.json. If this is specified in multiple files this enforces their equality.
version!: string & =~"^\\d+.\\d+.\\d+$"

// Present in attributes.json / taxonomy.json
attributes!: [
	...{
		id!:     string & =~#attribute_gid_regex
		name!:   string
		handle!: string
		extended_attributes!: [
			...{
				name!:   string
				handle!: string
			},
		]
		values!: [
			...{
				id!:     string & =~#value_gid_regex
				name!:   string
				handle!: string
			},
		]
	},
]

_category_reference: {
	id!:   string & =~#category_gid_regex
	name!: string
}

// Present in categories.json / taxonomy.json
verticals!: [...{
	name!:   string
	prefix!: string & =~"^[a-zA-Z]{2}$"
	categories!: [...{
		id!:        string & =~#category_gid_regex
		name!:      string
		level!:     int & >=0
		full_name!: string
		parent_id:  null | string & =~#category_gid_regex
		attributes!: [...{
			id!:       string & =~#attribute_gid_regex
			name!:     string
			handle!:   string
			extended!: bool
		}]
		children!: [..._category_reference]
		ancestors!: [..._category_reference]
	}]
}]

// Present in mappings.json / mappings_data.cue
mappings!: [
	...{
		input_taxonomy!:  string
		output_taxonomy!: string
		rules!: [
			...{
				input!: {
					product_category_id: string
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
