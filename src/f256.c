
#include "f256.h"
#include "microkernel.h"

#include <string.h>

// The event struct is allocated in crt0.
extern struct event_t event;
#pragma zpsym ("event")

// The kernel block is allocated and initialized with &event in crt0.
extern struct call_args args;
#pragma zpsym ("args")


static uint8_t *_text_ptr;
static uint8_t _column;
static uint8_t _row;
static uint8_t _text_color;

static bool _key_pressed[256];


void fe_init(void) {
	uint8_t current, active;
	_text_ptr = FE_TEXT_MATRIX;
	_column = 0;
	_row = 0;
	_text_color = 0x10;

	*FE_MMU_IO_CTRL = FE_PAGE_REGISTERS;
	*FE_VKY_MASTER_CTRL_0 = 0x01;		// text only
	*FE_VKY_MASTER_CTRL_1 = 0;			// 320x240 @60Hz resolution
	*FE_VKY_BORDER_CTRL = 0;			// no borders
	*FE_VKY_CURSOR_CTRL = 0;			// cursor off

	// Set text colors
	*FE_MMU_IO_CTRL = FE_PAGE_COLOR;
	memset(FE_TEXT_MATRIX, 0x10, FE_TEXT_MATRIX_SIZE);

	// A simple text color palette (black, white)
	*FE_MMU_IO_CTRL = FE_PAGE_REGISTERS;
	FE_FOREGROUND_LUT[0] = 0;
	FE_FOREGROUND_LUT[1] = 0;
	FE_FOREGROUND_LUT[2] = 0;
	FE_FOREGROUND_LUT[4] = 255;
	FE_FOREGROUND_LUT[5] = 255;
	FE_FOREGROUND_LUT[6] = 255;

	FE_BACKGROUND_LUT[0] = 0;
	FE_BACKGROUND_LUT[1] = 0;
	FE_BACKGROUND_LUT[2] = 0;
	FE_BACKGROUND_LUT[4] = 255;
	FE_BACKGROUND_LUT[5] = 255;
	FE_BACKGROUND_LUT[6] = 255;

	// Make sure we are able to edit the active LUT
	current = *FE_MMU_MEM_CTRL;
	active = current & 0x03;
	*FE_MMU_MEM_CTRL = 0x80 | (active << 4) | active;

	memset(_key_pressed, 0, sizeof(_key_pressed));
}

void fe_setup_text_palette(fe_color_t* palette, uint8_t count) {
	*FE_MMU_IO_CTRL = FE_PAGE_REGISTERS;

	ptr0 = FE_FOREGROUND_LUT;
	for (index0 = 0; index0 < count; ++index0) {
		ptr0[0] = palette[index0].b;
		ptr0[1] = palette[index0].g;
		ptr0[2] = palette[index0].r;
		ptr0 += 4;
	}

	ptr0 = FE_BACKGROUND_LUT;
	for (index0 = 0; index0 < count; ++index0) {
		ptr0[0] = palette[index0].b;
		ptr0[1] = palette[index0].g;
		ptr0[2] = palette[index0].r;
		ptr0 += 4;
	}
}

void fe_map(uint8_t bank) {
	FE_MMU_LUT[FE_TEMP_BANK] = bank;
}

void fe_unmap(void) {
	FE_MMU_LUT[FE_TEMP_BANK] = FE_DEFAULT_BANK;
}

static void display_scroll(void) {
	int saved0 = index0;
	int saved1 = index1;
	int saved2 = (int)ptr0;

    ptr0 = FE_TEXT_MATRIX;

	*FE_MMU_IO_CTRL = FE_PAGE_TEXT;
    for (index1 = 0; index1 < 80*59; ++index1) {
        ptr0[index1] = ptr0[index1+80];
    }

    ptr0 += index1;
    for (index0 = 0; index0 < 80; index0++) {
        *ptr0++ = ' ';
    }

   	ptr0 = FE_TEXT_MATRIX;
	*FE_MMU_IO_CTRL = FE_PAGE_COLOR;
    for (index1 = 0; index1 < 80*59; ++index1) {
        ptr0[index1] = ptr0[index1+80];
    }

    ptr0 += index1;
    for (index0 = 0; index0 < 80; index0++) {
        *ptr0++ = _text_color;
    }

    index0 = saved0;
    index1 = saved1;
    ptr0 = (uint8_t*)saved2;
}

void clear(void) {
	*FE_MMU_IO_CTRL = FE_PAGE_TEXT;
	memset(FE_TEXT_MATRIX, ' ', FE_TEXT_MATRIX_SIZE);

	*FE_MMU_IO_CTRL = FE_PAGE_COLOR;
	memset(FE_TEXT_MATRIX, _text_color, FE_TEXT_MATRIX_SIZE);

	_column = 0;
	_row = 0;
	_text_ptr = FE_TEXT_MATRIX;
}

void color(uint8_t c) {
	_text_color = c;
}

void putc(char ch) {
	*FE_MMU_IO_CTRL = FE_PAGE_TEXT;
	_text_ptr[_column] = ch;

	*FE_MMU_IO_CTRL = FE_PAGE_COLOR;
	_text_ptr[_column] = _text_color;

	_column++;
	if (_column == 80) {
		_column = 0;
		_text_ptr += 80;
		_row++;
	}

	if (_row == 60) {
		_row = 59;
		_text_ptr -= 80;
		display_scroll();
	}
}

void puts(const char* str) {
	while (*str) {
		putc(*str);
		++str;
	}
}

void puth8(uint8_t value) {
	static char nibble[] = { '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F' };
	putc(nibble[value >> 4]);
	putc(nibble[value & 0x0F]);
}

void puth16(uint16_t value) {
	puth8(value >> 8);
	puth8(value);
}

void puth32(uint32_t value) {
	puth16(value >> 16);
	puth16(value);
}


void putnl(void) {
	_column = 0;
	_text_ptr += 80;
	_row++;

	if (_row == 60) {
		_row = 59;
		_text_ptr -= 80;
		display_scroll();
	}
}

void at(uint8_t x, uint8_t y) {
	_column = x;
	_row = y;
	_text_ptr = FE_TEXT_MATRIX + y * 80;
}



char getc(void) {
	while (true) {
		CALL(NextEvent);

        if (event.type == EVENT(key.PRESSED)) {
        	if (!_key_pressed[event.key.ascii]) {
        		_key_pressed[event.key.ascii] = true;
        		return event.key.ascii;
        	}
        } else if (event.type == EVENT(key.RELEASED)) {
        	_key_pressed[event.key.ascii] = false;
        }
	}
	return 0;
}
