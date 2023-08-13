

	.export _documents

	.code



_documents:
	.word 	documents_array

documents_array:
	.word	superbasic_intro_title
	.word 	superbasic_intro
	.word 	0
	.word 	superbasic_programs_title
	.word	superbasic_programs
	.word 	0
	.word 	superbasic_graphics_title
	.word 	superbasic_graphics
	.word 	0
	.word 	superbasic_assembler_title
	.word	superbasic_assembler
	.word 	0
	.word 	0
	.word	0
	.word	0


superbasic_intro_title:
	.asciiz	"Introduction"
superbasic_intro:
	.incbin "../bin/superbasic_intro.bin"

superbasic_programs_title:
	.asciiz "Writing Programs"
superbasic_programs:
	.incbin "../bin/superbasic_programs.bin"

superbasic_assembler_title:
	.asciiz "Assembly"
superbasic_assembler:
	.incbin "../bin/superbasic_assembler.bin"

superbasic_graphics_title:
	.asciiz "Graphics"
superbasic_graphics:
	.incbin "../bin/superbasic_graphics.bin"

