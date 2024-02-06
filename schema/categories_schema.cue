package shopify

#AttributeGid: "gid://shopify/Taxonomy/Attribute/\\d+"
#CategoryGid: "gid://shopify/Taxonomy/Category/[a-zA-Z]{2}(-\\d+)*"

// Lookup to ensure all attributes exist
_attribute_lookup: {
	for k in attributes {
		"\(k.id)": k.name
	}
}

// Structure for categories, including recursive definitions for children, attributes, and ancestors
#category_ref: {
	id:   =~"^\(#CategoryGid)$"
	name: string
}

#category: {
	id:        =~"^\(#CategoryGid)$"
	name:      string
	level:     int & >=0
	full_name: string
	parent_id: *null | =~"^\(#CategoryGid)$"
	attributes: [...{
		id:   =~"^\(#AttributeGid)$"
		name: _attribute_lookup[id]
	}]
	children: [...#category_ref]
	ancestors: [...#category_ref]
}

// actual schema for categories data
version: =~"^\\d+.\\d+.\\d+$"
verticals: [...{
	name:   string
	prefix: =~"^[a-zA-Z]{2}$"
	categories: [...#category]
}]
