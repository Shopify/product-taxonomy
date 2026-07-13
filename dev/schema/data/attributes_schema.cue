#reference_regex: "^.+__.+$"

#base_attribute_common: {
	id!:          int
	name!:        string
	description?: string
	friendly_id!: string
	handle!:      string
	sorting?:     string
	...
}

#closed_list_attribute: #base_attribute_common & {
	type!: "closed_list"
	values!: [string & =~#reference_regex, ...string & =~#reference_regex]
	measurement_type?: _|_
	supported_units?:  _|_
}

#measurement_attribute: #base_attribute_common & {
	type!:             "measurement"
	measurement_type!: string
	supported_units!: [string, ...string]
	values?: _|_
}

base_attributes!: [...(#closed_list_attribute | #measurement_attribute)]

extended_attributes!: [
	...{
		name!:        string
		description?: string
		friendly_id!: string
		handle!:      string
		values_from!: string
	},
]
