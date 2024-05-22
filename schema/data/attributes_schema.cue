base_attributes!: [
	...{
		id!:          int
		name!:        string
		friendly_id!: string
		handle!:      string
		values!: [_, ...string] // at least one; all strings
	},
]

extended_attributes!: [
	...{
		name!:        string
		friendly_id!: string
		handle!:      string
		values_from!: string
	},
]
