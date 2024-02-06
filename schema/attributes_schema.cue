package shopify

#AttributeGid: "gid://shopify/Taxonomy/Attribute/\\d+"

// Structure for attributes, including recursive definitions for values
#attribute: {
	id:   =~"^\(#AttributeGid)$"
	name: string
	values: [...{
		id:   =~"^\(#AttributeGid)/\\d+$"
		name: string
	}]
}

// actual schema for attributes data
version: =~"^\\d+.\\d+.\\d+$"
attributes: [...#attribute]
