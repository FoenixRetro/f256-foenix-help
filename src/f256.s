    ;
    ; Start-up code for cc65 (Foenix F256 Jr)
    ;
    .export _exit, _event, _args
    .export __STARTUP__ : absolute = 1      ; Mark as start-up
    .exportzp _index0, _index1, _ptr0

    .export _map, _home, _clear, _color, _getc, _newline
    .export _at, _putc, _puts, _puti, _puth8, _puth16

    .import initlib, donelib
    .import zerobss
    .import copydata
    .import _main
    .import __STACKSTART__   ; From f256.cfg
    .import __END_LOAD__, __HIMEM__

    HEAP = (__END_LOAD__ + $1fff) & $E000
    .global __heaporg
    .global __heapptr
    .global __heapend
    .global __heapfirst
    .global __heaplast

    .include "zeropage.inc"


.scope kernel
    next_event  = $ff00

    .scope event
        type = _event+0

        .scope key
            ascii       = _event+5

            PRESSED     = $08
            RELEASED    = $0A
        .endscope
    .endscope
.endscope

.scope mmu
    mem_ctrl    = $00
    io_ctrl     = $01
    lut         = $08
.endscope


    .segment "ZEROPAGE" : zeropage
_event:         .res    8
_index0:        .res    1
_index1:        .res    2
_ptr0:          .res    2
text_ptr:       .res    2


    .segment "KERNEL_ARGS" : zeropage
_args:          .res    16

    .segment "INIT"
spsave:         .res    1

    .segment "BSS"
column:         .res    1
row:            .res    1
text_color:     .res    1

    .segment "DATA"
__heaporg:      .word   HEAP
__heapptr:      .word   HEAP
__heapend:      .word   __HIMEM__
__heapfirst:    .word   0
__heaplast:     .word   0


    .segment "END"       ; Defined for heap computation


    .segment "STARTUP"
Start:
    ; Disable interrupts
    sei

    ; Stash the original stack pointer so we can "return"
    ; to DOS (or whatever) from anywhere.
    tsx
    stx spsave

    ; Run the rest of the init code from the ONCE segment;
    ; the ONCE segment may then be merged into the heap.
    jsr initialize

    cli

    ; Push the command-line arguments, and call main().
    jsr _main


_exit:
    ; Disable the cursor
    stz $1
    stz $D010

    ; Restore the original stack pointer
    ldx spsave
    txs

    ; Run cleanup.
    jsr donelib

    ; Return to the shell
    rts


    .segment "ONCE"


initialize:
    ; Set up the stack.
    lda     #<__STACKSTART__
    ldx     #>__STACKSTART__
    sta     sp
    stx     sp+1            ; Set argument stack ptr

    ; Call the module constructors.
    jsr     initlib

    ; Zero the BSS
    jsr     zerobss

    ; Initialze statically initialized variables.
    jsr     copydata

    ; Initialize the kernel interface.
    lda     #<_event
    sta     _args+0
    stz     _args+1

    ; Initialize display
    stz     $01

    lda     #$01
    sta     $D000                   ; text only display
    ;lda     #$04
    ;sta     $D001                   ; 320x240 @60Hz
    stz     $D001                   ; 320x240 @60Hz
    stz     $D004                   ; no borders
    stz     $D010                   ; no cursor

    ; Setup text color palette
    ldy     #0
@copy_palette:
    lda     text_palette, y
    sta     $D800, y
    sta     $D840, y
    iny
    cpy     #text_palette_len
    bne     @copy_palette

    ; Make sure we are able to edit the active LUT
    lda     mmu::mem_ctrl
    and     #$03
    sta     _index0
    asl
    asl
    asl
    asl
    ora     #$80
    ora     _index0
    sta     mmu::mem_ctrl


    ; Clear screen
    lda     #$10
    sta     text_color
    jsr     _clear

    rts


    .segment "CODE"

;
; Map a specific slot to address $A000
;
    .proc _map: near
    sta     mmu::lut+5
    rts
    .endproc


;
; Move cursor to top left corner
;
    .proc _home: near

    pha
    stz     text_ptr
    lda     #$C0
    sta     text_ptr+1
    stz     column
    stz     row
    pla
    rts

    .endproc


;
; Clear screen
;
    .proc _clear: near

    pha
    phy
    phx
    jsr     _home

    lda     #$02                    ; fill text area with space
    sta     $01
    lda     #' '
    jsr     fill

    inc     $01                     ; fill color area
    lda     text_color
    jsr     fill

    jsr     _home

    plx
    ply
    pla
    rts

    .endproc


fill:
    ldy     #0
@row:
    ldx     #0
@column:
    sta     (text_ptr)
    inc     text_ptr
    bne     @next
    inc     text_ptr+1
@next:
    inx
    cpx     #80
    bne     @column

    iny
    cpy     #60
    bne     @row
    rts


;
; Set text and background color
;
    .proc _color: near

    sta     text_color
    rts

    .endproc



;
; Move text cursor to specified row and column
;
    .proc _at: near

    tay
    sta     row
    lda     (sp)
    sta     column
    inc     sp                          ; pop x argument from stack

    lda     row_start_low, y
    sta     text_ptr
    lda     row_start_high, y
    sta     text_ptr+1

    rts

    .endproc


;
; Print character in A
;
    .proc _putc: near
    pha
    phy
    jsr     output_char
    ply
    pla
    rts

    .endproc


output_char:
    ldy     #$02
    sty     mmu::io_ctrl
    ldy     column
    sta     (text_ptr),y

    inc     mmu::io_ctrl
    lda     text_color
    sta     (text_ptr),y

    iny
    cpy     #80
    beq     _newline
    sty     column
    rts


;
; Move cursor to the next line
;
    .proc _newline: near

    stz     column
    inc     row
    lda     row
    cmp     #60
    beq     @at_bottom

    ldy     row
    lda     row_start_low, y
    sta     text_ptr
    lda     row_start_high, y
    sta     text_ptr+1

    rts

@at_bottom:
    lda     #59
    sta     row
    rts

    .endproc


;
; Print the null terminated string in A/X
;
    .proc _puts: near

    ; Save _ptr0 so we don't break any user code
    ldy     _ptr0
    phy
    ldy     _ptr0+1
    phy

    sta     _ptr0
    stx     _ptr0+1

    ldy     #0
    clc
@loop:
    lda     (_ptr0),y
    beq     @done
    jsr     _putc
    iny
    bne     @loop
@done:

    ; Restore _ptr0 value
    pla
    sta     _ptr0+1
    pla
    sta     _ptr0

    rts

    .endproc



    .proc _puth8: near
    pha
    lsr
    lsr
    lsr
    lsr
    jsr     @put_nibble
    pla

@put_nibble:
    and     #$0f
    cmp     #10
    bcc     @output_digit
    adc     #6                          ; convert a : to A
@output_digit:
    adc     #'0'
    jsr     _putc
    rts
    .endproc


    .proc _puth16: near
    pha
    txa
    jsr     _puth8
    pla
    jmp     _puth8
    .endproc


;
; Print number in A/X
;
; Taken from the page: https://beebwiki.mdfs.net/Number_output_in_6502_machine_code
;
    .proc _puti: near
    rts
    ; Save _index1 value
    ldy     _index1
    phy
    ldy     _index1+1
    phy

    ; Store value to print in _index1
    sta     _index1
    stx     _index1+1

    ldy     #8
@lp1:
    ldx     #$ff
    sec
@lp2:
    lda     _index1
    sbc     @tens,y
    sta     _index1

    lda     _index1+1
    sbc     @tens+1,y
    sta     _index1+1

    inx
    bcs     @lp2                        ; loop until <0

@done:
    ; Store _index1 value
    pla
    sta     _index1+1
    pla
    sta     _index1

    rts

@tens:
    .word   1
    .word   10
    .word   100
    .word   1000
    .word   10000
    .endproc


;
; Wait for keypress, and return ascii code in A
;
    .proc _getc: near

    ldx     #$00

    jsr     kernel::next_event
    bcs     _getc

    lda     kernel::event::type
    cmp     #kernel::event::key::PRESSED
    bne     _getc

    lda     kernel::event::key::ascii
    beq     _getc

    rts

    .endproc

text_palette:
    ; Color b    g    r    a
    .byte   $79, $51, $00, $00
    .byte   $f9, $f0, $e0, $00
    ;.byte   $52, $40, $31, $00
    ;.byte   $d8, $d0, $c9, $00
    .byte   $ff, $ff, $ff, $00
text_palette_len    = *-text_palette

row_start_low:
    .byte $00, $50, $a0, $f0, $40, $90, $e0, $30, $80, $d0, $20, $70, $c0, $10, $60, $b0, $00, $50, $a0, $f0
    .byte $40, $90, $e0, $30, $80, $d0, $20, $70, $c0, $10, $60, $b0, $00, $50, $a0, $f0, $40, $90, $e0, $30
    .byte $80, $d0, $20, $70, $c0, $10, $60, $b0, $00, $50, $a0, $f0, $40, $90, $e0, $30, $80, $d0, $20, $70
row_start_high:
    .byte $c0, $c0, $c0, $c0, $c1, $c1, $c1, $c2, $c2, $c2, $c3, $c3, $c3, $c4, $c4, $c4, $c5, $c5, $c5, $c5
    .byte $c6, $c6, $c6, $c7, $c7, $c7, $c8, $c8, $c8, $c9, $c9, $c9, $ca, $ca, $ca, $ca, $cb, $cb, $cb, $cc
    .byte $cc, $cc, $cd, $cd, $cd, $ce, $ce, $ce, $cf, $cf, $cf, $cf, $d0, $d0, $d0, $d1, $d1, $d1, $d2, $d2

