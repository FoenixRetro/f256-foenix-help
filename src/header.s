        .segment    "HEADER"
        .import     __STARTUP_LOAD__, __END_LOAD__

        EXEC  = __STARTUP_LOAD__
        SLOT  = __STARTUP_LOAD__ >> 13
        COUNT = __END_LOAD__ >> 13   ; Assumes code starts at $2000.

        .byte   $f2,$56     ; signature
        .byte   <(COUNT+EXTRA_FLASH_BLOCKS) ; block count
        .byte   <SLOT       ; start slot
        .word   EXEC        ; exec addr
        .byte   1           ; header version
        .byte   0           ; reserved
        .byte   0           ; reserved
        .byte   0           ; reserved
        .asciiz "help"      ; name
        .asciiz ""          ; arguments
        .asciiz "SuperBASIC help viewer." ; description

