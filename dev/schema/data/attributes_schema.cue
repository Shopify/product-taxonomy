#reference_regex: "^.+__.+$"

base_attributes!: [
	...{
		id!:               int
		name!:             string
		description?:      string
		friendly_id!:      string
		handle!:           string
		type!:             "closed_list" | "measurement"
		sorting?:          string
		values?:           [_, ...string & =~#reference_regex]
		measurement_type?: string
		supported_units?:  [_, ...string]
	},
]

extended_attributes!: [
	...{
		name!:        string
		description?: string
		friendly_id!: string
		handle!:      string
		values_from!: string
	},
]
