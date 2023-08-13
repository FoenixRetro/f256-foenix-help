
	.include "docs.inc"

	.segment "HEADER"

	.byte $D0, $AB
	.word copyrights
	.word table_start
	.word table_end

copyrights:
	.asciiz "Copyright (c) 2022 paulscottrobson"

table_start:
	document    "Reference (M - R)", 	"../bin/docs/superbasic_ref_m_r.bin"
	document    "Reference (S - Z)", 	"../bin/docs/superbasic_ref_s_z.bin"
table_end:

	.segment "DOCS"

