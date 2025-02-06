// values.yml is key-less, so we rely on `cue vet -d`

#reference_regex: "^.+__.+$"

#schema: [...{
	id!:          int
	name!:        string
	friendly_id!: string & =~#reference_regex
	handle!:      string & =~#reference_regex
}]
