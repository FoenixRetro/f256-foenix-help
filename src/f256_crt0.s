    ;
    ; Start-up code for cc65 (Foenix F256 Jr)
    ;
    .export _exit, _event, _args
    .export __STARTUP__ : absolute = 1      ; Mark as start-up
    .exportzp _index0, _index1, _ptr0

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

    .PC02

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
    jsr init

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



    .segment "ZEROPAGE" : zeropage
_event:     .res    7
_index0:    .res    1
_index1:    .res    2
_ptr0:      .res    2

    .segment "KERNEL_ARGS" : zeropage
_args:  .res    16

    .segment "INIT"
spsave: .res    1

    .segment "END"       ; Defined for heap computation


    .segment "ONCE"


init:
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

    rts

    .data

__old_irq:
    .res    2
__heaporg:
    .word   HEAP
__heapptr:
    .word   HEAP
__heapend:
    .word   __HIMEM__
__heapfirst:
    .word   0
__heaplast:
    .word   0