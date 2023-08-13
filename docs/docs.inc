
 doc:	.macro 	document name,binfile,srcfile
 		.local title
 		.local bin

 		.segment "HEADER"
 		.word title
 		.word bin

 		.segment "DOCS"
 title:
 		.asciiz name
 bin:
 		.incbin binfile

		.segment "HEADER"
 	.endmacro
