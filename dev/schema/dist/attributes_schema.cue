// This file defines and enforces the shape of the data for dist/attributes.json and dist/taxonomy.json
// Data validations are handled by the application test-suite

#attribute_gid_regex: "^gid://shopify/TaxonomyAttribute/\\d+$"
#value_gid_regex:     "^gid://shopify/TaxonomyValue/\\d+$"

#version_regex: "^\\d{4}-\\d{2}(-(unstable|beta\\d+))?$"
version!:       string & =~#version_regex

#attribute_common: {
	id!:          string & =~#attribute_gid_regex
	name!:        string
	handle!:      string
	description?: string
	extended_attributes!: [
		...{
			name!:   string
			handle!: string
		},
	]
	...
}

#value_reference: {
	id!:     string & =~#value_gid_regex
	name!:   string
	handle!: string
}

#closed_list_attribute: #attribute_common & {
	type!: "closed_list"
	values!: [#value_reference, ...#value_reference]
	measurement_type?: _|_
	supported_units?:  _|_
}

#measurement_attribute: #attribute_common & {
	type!:             "measurement"
	measurement_type!: string
	supported_units!: [string, ...string]
	values?: _|_
}

attributes!: [...(#closed_list_attribute | #measurement_attribute)]
