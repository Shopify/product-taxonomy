// This file defines and enforces the shape of the data for dist/attributes.json and dist/taxonomy.json
// Data validations are handled by the application test-suite

#attribute_gid_regex: "^gid://shopify/TaxonomyAttribute/\\d+$"
#value_gid_regex:     "^gid://shopify/TaxonomyValue/\\d+$"


#version_regex: "^\\d{4}-\\d{2}(-(unstable|beta\\d+))?$"
version!: string & =~#version_regex

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
