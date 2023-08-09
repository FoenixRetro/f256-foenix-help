
 doc:	.macro 	document name,binfile,srcfile
 		.local title
 		.local bin
 		.local source
 		.local source_end

 		.segment "HEADER"
 		.word title
 		.word bin
 		.word (source_end-source)

 		.segment "DOCS"
 title:
 		.asciiz name
 bin:
 		.incbin binfile

 		.segment "SOURCE"
source:
		.incbin srcfile
source_end:
 	.endmacro



	.segment "HEADER"

	.byte $d0, $ab
	.word table_start
	.word table_end

table_start:
	document 	"Introduction", "../bin/superbasic_intro.bin", "docs/superbasic_intro.txt"
	document 	"Writing Programs", "../bin/superbasic_programs.bin", "docs/superbasic_programs.txt"
	document 	"Identifiers, Variables and typing", "../bin/superbasic_variables.bin", "docs/superbasic_variables.txt"
	document 	"Graphics", "../bin/superbasic_graphics.bin", "docs/superbasic_graphics.txt"
	document	"Assembler", "../bin/superbasic_assembler.bin", "docs/superbasic_assembler.txt"
table_end:

	.segment "DOCS"
	.segment "SOURCE"

