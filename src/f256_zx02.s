; De-compressor for ZX02 files
; ----------------------------
;
; Decompress ZX02 data (6502 optimized format), optimized for speed and size
;  138 bytes code, 58.0 cycles/byte in test file.
;
; Compress with:
;    zx02 input.bin output.zx0
;
; (c) 2022 DMSC
; Code under MIT license, see LICENSE file.


              .export _decompress
              .export decompress_start
              .export _decompress_get_end

              .exportzp src_ptr, dest_ptr

              .include "zeropage.inc"

              .segment "ZEROPAGE"

offset:       .res 2
src_ptr:      .res 2
dest_ptr:     .res 2
bitr:         .res 1
pntr:         .res 2


              .code

              .proc _decompress_get_end: near

              lda dest_ptr
              ldx dest_ptr+1
              rts

              .endproc

;--------------------------------------------------
; Decompress ZX0 data (6502 optimized format)


_decompress:

              ; Setup arguments
              sta dest_ptr
              stx dest_ptr+1

              ldy #$01
              lda (sp),y
              sta src_ptr+1
              lda (sp)
              sta src_ptr

              inc sp
              inc sp

decompress_start:
              ldy #$00
              sty offset
              sty offset+1
              lda #$80
              sta bitr
              lda #$00

; Decode literal: Ccopy next N bytes from compressed file
;    Elias(length)  byte[1]  byte[2]  ...  byte[N]
decode_literal:
              jsr   get_elias

cop0:         lda   (src_ptr), y
              inc   src_ptr
              bne   :+
              inc   src_ptr+1
:             sta   (dest_ptr),y
              inc   dest_ptr
              bne   :+
              inc   dest_ptr+1
:             dex
              bne   cop0

              asl   bitr
              bcs   dzx0s_new_offset

; Copy from last offset (repeat N bytes from last offset)
;    Elias(length)
              jsr   get_elias
dzx0s_copy:
              lda   dest_ptr
              sbc   offset  ; C=0 from get_elias
              sta   pntr
              lda   dest_ptr+1
              sbc   offset+1
              sta   pntr+1

cop1:
              lda   (pntr), y
              inc   pntr
              bne   :+
              inc   pntr+1
:             sta   (dest_ptr),y
              inc   dest_ptr
              bne   :+
              inc   dest_ptr+1
:             dex
              bne   cop1

              asl   bitr
              bcc   decode_literal

; Copy from new offset (repeat N bytes from new offset)
;    Elias(MSB(offset))  LSB(offset)  Elias(length-1)
dzx0s_new_offset:
              ; Read elias code for high part of offset
              jsr   get_elias
              beq   exit  ; Read a 0, signals the end
              ; Decrease and divide by 2
              dex
              txa
              lsr
              sta   offset+1

              ; Get low part of offset, a literal 7 bits
              lda   (src_ptr), y
              inc   src_ptr
              bne   :+
              inc   src_ptr+1
:
              ; Divide by 2
              ror
              sta   offset

              ; And get the copy length.
              ; Start elias reading with the bit already in carry:
              ldx   #1
              jsr   elias_skip1

              inx
              bcc   dzx0s_copy

; Read an elias-gamma interlaced code.
; ------------------------------------
get_elias:
              ; Initialize return value to #1
              ldx   #1
              bne   elias_start

elias_get:    ; Read next data bit to result
              asl   bitr
              rol
              tax

elias_start:
              ; Get one bit
              asl   bitr
              bne   elias_skip1

              ; Read new bit from stream
              lda   (src_ptr), y
              inc   src_ptr
              bne   :+
              inc   src_ptr+1
:             ;sec   ; not needed, C=1 guaranteed from last bit
              rol
              sta   bitr

elias_skip1:
              txa
              bcs   elias_get
              ; Got ending bit, stop reading
exit:
              rts

