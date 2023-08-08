
ifeq ($(OS),Windows_NT)
	DEL = del /s /q $(subst /,\,$(1))
	MKDIR = md $(subst /,\,$(1))
	COPY = copy $(subst /,\,$(1)) $(subst /,\,$(2))
	LZG =
else
	UNAME_S := $(shell uname -s)

	DEL = $(RM) -rf $(1)
	MKDIR = mkdir -p $(1)
	COPY = cp $(1) $(2)

	ifeq ($(UNAME_S),Darwin)
		LZG = tools/macos/lzg
	else
		LFG =
	endif
endif


C_SOURCES = src/main.c src/f256.c
C_INCLUDES = src/*.h
C_OBJS := $(patsubst %.c, bin/%.o, $(C_SOURCES))

DOCS := docs/superbasic_intro.txt docs/superbasic_programs.txt docs/superbasic_assembler.txt docs/microkernel.txt
DOCS_BIN := $(patsubst docs/%.txt, bin/%.bin, $(DOCS))

ASM_SOURCES = src/f256_crt0.s src/f256_lzg.s src/header.s src/documents.s
ASM_INCLUDES = src/*.inc
ASM_OBJS := $(patsubst %.s, bin/%.o, $(ASM_SOURCES))


.PHONY: all clean upload dump

all: bin bin/help.bin

os:
	echo $(UNAME_S)

bin:
	$(call MKDIR, bin/src)

bin/src/documents.o: $(DOCS_BIN)

bin/%.bin: docs/%.txt
	$(LZG) -9 $< $@

bin/src/%.o: src/%.c
	cc65 --cpu 65C02 --standard cc65 -Osir -Cl -t none -Isrc -Igfx -o $(@:.o=.s) $<
	ca65 --cpu 65C02 -o $@ -l $(@:.o=.lst) -t none -Isrc bin/$(<:.c=.s)

bin/src/%.o: src/%.s
	ca65 --cpu 65C02 -t none -o $@ -Isrc -l $(@:.o=.lst) $<

bin/help.bin: $(ASM_OBJS) $(C_OBJS)
	ld65 -C src/f256.cfg -o $@ $(ASM_OBJS) $(C_OBJS) none.lib -m $(basename $@).map -Ln $(basename $@).lbl

clean:
	$(call DEL, bin/*.*)
	$(call DEL, bin/src/*.*)

upload: bin/help.bin
	python3 $(FOENIXMGR)/FoenixMgr/fnxmgr.py --target f256k --binary bin/help.bin --address 2000

dump:
	python $(FOENIXMGR)/FoenixMgr/fnxmgr.py --target f256k --dump 2000 --count 1024