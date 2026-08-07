// This file defines and enforces the shape of the data for dist/categories.json and dist/taxonomy.json
// Data validations are handled by the application test-suite

#attribute_gid_regex: "^gid://shopify/TaxonomyAttribute/\\d+$"
#category_gid_regex:  "^gid://shopify/TaxonomyCategory/[a-zA-Z]{2}(-\\d+)*$"

_category_reference: {
	id!:   string & =~#category_gid_regex
	name!: string
}

#attribute_reference_common: {
	id!:          string & =~#attribute_gid_regex
	name!:        string
	handle!:      string
	description?: string
	extended!:    bool
	...
}

#closed_list_attribute_reference: #attribute_reference_common & {
	type!:             "closed_list"
	values?:           _|_
	measurement_type?: _|_
	supported_units?:  _|_
}

#measurement_attribute_reference: #attribute_reference_common & {
	type!:             "measurement"
	values?:           _|_
	measurement_type?: _|_
	supported_units?:  _|_
}

#attribute_reference: #closed_list_attribute_reference | #measurement_attribute_reference

#version_regex: "^\\d{4}-\\d{2}(-(unstable|beta\\d+))?$"
version!:       string & =~#version_regex
verticals!: [...{
	name!:   string
	prefix!: string & =~"^[a-zA-Z]{2}$"
	categories!: [...{
		id!:        string & =~#category_gid_regex
		name!:      string
		level!:     int & >=0
		full_name!: string
		parent_id:  null | string & =~#category_gid_regex
		attributes!: [...#attribute_reference]
		children!: [..._category_reference]
		ancestors!: [..._category_reference]
	}]
}]
