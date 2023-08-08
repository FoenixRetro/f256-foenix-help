

	.export _documents

	.code



_documents:
	.word 	documents_array

documents_array:
	.word	superbasic_intro_title
	.word 	superbasic_intro
	.word 	superbasic_programs_title
	.word	superbasic_programs
	.word 	superbasic_assembler_title
	.word	superbasic_assembler
	.word 	microkernel_ref_title
	.word 	microkernel_ref
	.word 	0
	.word	0


superbasic_intro_title:
	.asciiz	"SuperBASIC Introduction"
superbasic_intro:
	.incbin "../bin/superbasic_intro.bin"

superbasic_programs_title:
	.asciiz "Writing Programs in SuperBASIC"
superbasic_programs:
	.incbin "../bin/superbasic_programs.bin"

superbasic_assembler_title:
	.asciiz "Assembly in SuperBASIC"
superbasic_assembler:
	.incbin "../bin/superbasic_assembler.bin"

microkernel_ref_title:
	.asciiz "TinyCore MicroKernel"
microkernel_ref:
	.incbin "../bin/microkernel.bin"

