// categories/*.yml is key-less, so we rely on `cue vet -d`

#schema: [...{
	id!:   string
	name!: string
	children!: [...string]
	attributes!: [...string]
	return_reasons!: [...string]
}]
