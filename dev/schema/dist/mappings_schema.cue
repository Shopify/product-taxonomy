// This file defines and enforces the shape of the data for dist/mappings.json
// Data validations are handled by the application test-suite

#attribute_gid_regex: "^gid://shopify/TaxonomyAttribute/\\d+$"
#value_gid_regex:     "^gid://shopify/TaxonomyValue/\\d+$"

#version_regex: "^\\d{4}-\\d{2}(-(unstable|beta\\d+))?$"
version!: string & =~#version_regex
mappings!: [
	...{
		input_taxonomy!:  string
		output_taxonomy!: string
		rules!: [
			...{
				input!: {
					category!: {
						id: string
						full_name: string
					}
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
