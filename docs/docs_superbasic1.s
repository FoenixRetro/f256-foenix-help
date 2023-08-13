
	.include "docs.inc"

	.segment "HEADER"

	.byte $D0, $AB
	.word copyrights
	.word table_start
	.word table_end

copyrights:
	.asciiz "Copyright (c) 2022 paulscottrobson"

table_start:
	document 	"Introduction", 				"../bin/docs/superbasic_intro.bin"
	document 	"Writing Programs", 			"../bin/docs/superbasic_programs.bin"
	document 	"Identifiers and Variables", 	"../bin/docs/superbasic_variables.bin"
	document    "Structured Programming",		"../bin/docs/superbasic_procedures.bin"
	document	"Assembler", 					"../bin/docs/superbasic_assembler.bin"
table_end:

	.segment "DOCS"

