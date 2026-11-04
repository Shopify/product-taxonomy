// categories/*.yml is key-less, so we rely on `cue vet -d`

#schema: [...{
	id!:   string
	name!: string
	children!: [...string]
	attributes!: [...string]
	// Either an explicit list of return reason friendly IDs, or the literal "inherit" to copy them from the closest
	// ancestor that defines its own.
	return_reasons!: [...string] | "inherit"
}]
