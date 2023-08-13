
	.include "docs.inc"

	.segment "HEADER"

	.byte $D0, $AB
	.word copyrights
	.word table_start
	.word table_end

copyrights:
	.asciiz "Copyright (c) 2022 paulscottrobson"

table_start:
	document 	"Reference (Symbols)", 	"../bin/docs/superbasic_ref_symbols.bin"
	document    "Reference (A - F)", 	"../bin/docs/superbasic_ref_a_f.bin"
	document    "Reference (G - L)", 	"../bin/docs/superbasic_ref_g_l.bin"
table_end:

	.segment "DOCS"

