
ifeq ($(OS),Windows_NT)
	DEL = del /s /q $(subst /,\,$(1))
	MKDIR = md $(subst /,\,$(1))
	COPY = copy $(subst /,\,$(1)) $(subst /,\,$(2))
	ZX02 = bin\zx02.exe
	REFS = bin\refs.exe
	PYTHON = python.exe
else
	DEL = $(RM) -rf $(1)
	MKDIR = mkdir -p $(1)
	COPY = cp $(1) $(2)
	ZX02 = bin/zx02
	REFS = bin/refs
	PYTHON = python3
endif


C_SOURCES = src/main.c
C_OBJS := $(patsubst %.c, bin/%.o, $(C_SOURCES))

ASM_SOURCES = src/f256.s src/f256_zx02.s src/header.s
ASM_OBJS := $(patsubst %.s, bin/%.o, $(ASM_SOURCES))

DOC_PACKS = $(patsubst %.s, bin/%.bin, $(wildcard docs/*.s))


.PHONY: all clean upload dump release

all: bin bin/help.bin $(DOC_PACKS) $(REFS)

bin:
	$(call MKDIR, bin/src)
	$(call MKDIR, bin/docs)

bin/src/%.o: src/%.c
	cc65 --cpu 65C02 --standard cc65 -Osir -Cl -t none -Isrc -Igfx -o $(@:.o=.s) $<
	ca65 --cpu 65C02 -o $@ -l $(@:.o=.lst) -t none -Isrc bin/$(<:.c=.s)

bin/src/%.o: src/%.s
	ca65 --cpu 65C02 -t none -o $@ -Isrc -l $(@:.o=.lst) $<

bin/help.bin: $(ASM_OBJS) $(C_OBJS)
	ld65 -C src/f256.cfg -o $@ $(ASM_OBJS) $(C_OBJS) none.lib -m $(basename $@).map -Ln $(basename $@).lbl

bin/docs/%.bin: docs/%.txt $(ZX02)
	$(ZX02) -f $< $@

bin/docs/%.bin: docs/%.s
	ca65 --cpu 65C02 -t none -o $(basename $@).o -Isrc -l $(basename $@).lst $<
	ld65 -C docs/docs.cfg -o $@ $(basename $@).o -m $(basename $@).map -Ln $(basename $@).lbl

resources/font_compressed.bin: resources/font.bin $(ZX02)
	$(ZX02) -f $< $@

$(ZX02): src/tools/zx02/zx02.c src/tools/zx02/compress.c src/tools/zx02/memory.c src/tools/zx02/optimize.c
	gcc -O2 -o $@ $^

$(REFS): src/tools/refs/refs.c
	gcc -O2 -o $@ $^

docs/superbasic_reference_1_packed.txt: docs/superbasic_reference_1.txt $(REFS)
	$(REFS) $< $@ src/superbasic_keywords_1.h 0

docs/superbasic_reference_2_packed.txt: docs/superbasic_reference_2.txt $(REFS)
	$(REFS) $< $@ src/superbasic_keywords_2.h 1


src/main.c: docs/superbasic_reference_1_packed.txt docs/superbasic_reference_2_packed.txt src/superbasic_keywords_1.h src/superbasic_keywords_2.h
bin/src/f256.o: resources/font_compressed.bin

bin/docs/docs_superbasic1.bin: bin/docs/superbasic_intro.bin bin/docs/superbasic_programs.bin bin/docs/superbasic_assembler.bin bin/docs/superbasic_variables.bin bin/docs/superbasic_procedures.bin
bin/docs/docs_superbasic2.bin: bin/docs/superbasic_graphics.bin bin/docs/superbasic_sprites.bin bin/docs/superbasic_tiles.bin bin/docs/superbasic_sound.bin
bin/docs/docs_superbasic_ref_1.bin: bin/docs/superbasic_reference_1_packed.bin
bin/docs/docs_superbasic_ref_2.bin: bin/docs/superbasic_reference_2_packed.bin

clean:
	$(call DEL, bin/*.*)
	$(call DEL, bin/src/*.*)
	$(call DEL, bin/docs/*.*)
	$(call DEL, docs/superbasic_reference_1_packed.txt)
	$(call DEL, docs/superbasic_reference_2_packed.txt)
	$(call DEL, src/superbasic_keywords_1.h)
	$(call DEL, src/superbasic_keywords_2.h)

upload: bin/help.bin
	$(PYTHON) $(FOENIXMGR)/FoenixMgr/fnxmgr.py --target f256k --binary bin/help.bin --address 2000

flash_app: bin/help.bin
	$(PYTHON) $(FOENIXMGR)/FoenixMgr/fnxmgr.py --target f256k --flash-sector=10 --flash bin/help.bin

flash_docs: $(DOC_PACKS)
	$(PYTHON) $(FOENIXMGR)/FoenixMgr/fnxmgr.py --target f256k --flash-sector=11 --flash bin/docs/docs_superbasic1.bin
	$(PYTHON) $(FOENIXMGR)/FoenixMgr/fnxmgr.py --target f256k --flash-sector=12 --flash bin/docs/docs_superbasic2.bin
	$(PYTHON) $(FOENIXMGR)/FoenixMgr/fnxmgr.py --target f256k --flash-sector=13 --flash bin/docs/docs_superbasic_ref_1.bin
	$(PYTHON) $(FOENIXMGR)/FoenixMgr/fnxmgr.py --target f256k --flash-sector=14 --flash bin/docs/docs_superbasic_ref_2.bin

release: bin/help.bin $(DOC_PACKS)
	$(call DEL, release/*.bin)
	$(call COPY, bin/*.bin release)
	$(call COPY, bin/docs/docs_*.bin release)