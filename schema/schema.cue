package shopify

// Define a pattern for IDs
#idPattern: =~"^gid://shopify/Taxonomy/(Category|Attribute)/.*$"

// Define the structure for attributes
#attribute: {
	id:   string & #idPattern
	name: string
}

// reference
#category_ref: {
	id:   string & #idPattern
	name: string
}

// Define the structure for categories, including recursive definitions for children
#category: {
	id:        string & #idPattern
	name:      string
	level:     int & >=0
	full_name: string
	parent_id: *null | string & #idPattern
	attributes: [...#attribute]
	children: [...#category_ref] | *[]
	ancestors: [...{id: string & #idPattern, name: string}] | *[]
}

// Define the structure for verticals
#vertical: {
	name:   string
	prefix: string
	categories: [...#category]
}

version: =~"^\\d+.\\d+.\\d+"
verticals: [...#vertical]
