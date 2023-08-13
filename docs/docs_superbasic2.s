
	.include "docs.inc"

	.segment "HEADER"

	.byte $D0, $AB
	.word copyrights
	.word table_start
	.word table_end

copyrights:
	.asciiz "Copyright (c) 2022 paulscottrobson"

table_start:
	document 	"Graphics", 			"../bin/docs/superbasic_graphics.bin"
	document    "Sprites", 				"../bin/docs/superbasic_sprites.bin"
	document    "Tiles and Tile Maps",	"../bin/docs/superbasic_tiles.bin"
	document    "Sound",				"../bin/docs/superbasic_sound.bin"
table_end:

	.segment "DOCS"

