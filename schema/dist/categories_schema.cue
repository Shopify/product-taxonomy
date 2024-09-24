// This file defines and enforces the shape of the data for dist/categories.json and dist/taxonomy.json
// Data validations are handled by the application test-suite

#attribute_gid_regex: "^gid://shopify/TaxonomyAttribute/\\d+$"
#category_gid_regex: "^gid://shopify/TaxonomyCategory/[a-zA-Z]{2}(-\\d+)*$"

_category_reference: {
	id!:   string & =~#category_gid_regex
	name!: string
}

#version_regex: "^\\d{4}-\\d{2}(-(unstable|beta\\d+))?$"
version!: string & =~#version_regex
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
