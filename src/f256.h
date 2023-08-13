
#ifndef F256_H
#define F256_H

#include <stdint.h>
#include <stdbool.h>

#define FE_SCREEN_WIDTH			320
#define FE_SCREEN_HEIGHT		240

#define FE_PAGE_REGISTERS		0
#define FE_PAGE_FONT			1
#define FE_PAGE_TEXT			2
#define FE_PAGE_COLOR			3

#define FE_MMU_MEM_CTRL 		((uint8_t*)0x0000)
#define FE_MMU_IO_CTRL 			((uint8_t*)0x0001)
#define FE_MMU_LUT				((uint8_t*)0x0008)

#define FE_FOREGROUND_LUT		((uint8_t*)0xD800)
#define FE_BACKGROUND_LUT		((uint8_t*)0xD840)
#define FE_TEXT_MATRIX			((uint8_t*)0xC000)
#define FE_TEXT_MATRIX_SIZE		(80*60)

#define FE_VKY_MASTER_CTRL_0	((uint8_t*)0xD000)
#define FE_VKY_MASTER_CTRL_1	((uint8_t*)0xD001)
#define FE_VKY_LAYER_CTRL_0		((uint8_t*)0xD002)
#define FE_VKY_LAYER_CTRL_1		((uint8_t*)0xD002)
#define FE_VKY_BORDER_CTRL		((uint8_t*)0xD004)
#define FE_VKY_BORDER_BLUE		((uint8_t*)0xD005)
#define FE_VKY_BORDER_GREEN		((uint8_t*)0xD006)
#define FE_VKY_BORDER_RED		((uint8_t*)0xD007)
#define FE_VKY_BORDER_SIZE_X	((uint8_t*)0xD008)
#define FE_VKY_BORDER_SIZE_Y	((uint8_t*)0xD009)
#define FE_VKY_BACKGROUND_COLOR	((uint8_t*)0xD00D)		// three consecutive bytes R, G, B
#define FE_VKY_CURSOR_CTRL		((uint8_t*)0xD010)

#define FE_TEMP_BANK			(5)						// address 0xA000 - 0xBFFF can be used to swap out memory
#define FE_DEFAULT_SECTOR		(5)
#define FE_TEMP_ADDR			((uint8_t*)0xA000)
#define FE_TEMP_SIZE			(0x2000)

#define FE_FLASH_SECTOR_START	0x40
#define FE_FLASH_SECTOR_END		0x78

#define FE_ADDR_BANK(addr)			(((addr) >> 13) & 0xFF)
#define FE_BANK2ADDR(bank)			(((uint32_t)bank) << 13)
#define FE_ADDR_LOW(addr)			((addr) & 0xFF)
#define FE_ADDR_MID(addr)			(((addr) >> 8) & 0xFF)
#define FE_ADDR_HIGH(addr)			(((addr) >> 16) & 0xFF)
#define FE_SET_ADDR(target, addr)	(target)->addr_low = FE_ADDR_LOW(addr);  \
									(target)->addr_mid = FE_ADDR_MID(addr);  \
									(target)->addr_high = FE_ADDR_HIGH(addr)


typedef struct {
	uint8_t r;
	uint8_t g;
	uint8_t b;
} fe_color_t;


void fe_init(void);

void fe_map(uint8_t sector);
void fe_unmap(void);

void fe_setup_text_palette(fe_color_t* palette, uint8_t count);

void clear(void);
void color(uint8_t c);
void at(uint8_t x, uint8_t y);

void putc(char ch);
void puts(const char* str);
void puth8(uint8_t value);
void puth16(uint16_t value);
void puth32(uint32_t value);
void putnl(void);

char getc(void);

// Decompress a ZX02 compressed binary stream
void __fastcall__ fe_decompress(uint8_t* source, uint8_t* dest);

// This will return a pointer to the end of the decompressed stream.
// I know, this is ugly...
uint8_t* __fastcall__ fe_decompress_get_end(void);


// Global zero-page variables we can use
extern uint8_t index0;
extern uint16_t index1;
extern uint8_t* ptr0;

#pragma zpsym ("index0");
#pragma zpsym ("index1");
#pragma zpsym ("ptr0");


#endif
