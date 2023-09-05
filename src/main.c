
#include "f256.h"

#include <string.h>

#define DOC_LINK_COUNT 	25
#define REF_COLUMN		29

typedef struct {
    const char* name;
    uint8_t 	index;
    uint16_t 	description;
} keyword_t;

typedef struct {
	keyword_t* keywords;
	uint16_t   len;
	uint8_t    sector;
} keyword_set_t;

typedef struct {
	char* title;
	uint8_t* source;
} doc_t;

typedef struct {
	uint16_t magic;
	char* copyrights;
	doc_t* start_doc;
	doc_t* end_doc;
} document_pack_t;


typedef struct {
	uint8_t index;
	uint8_t segment;
} doc_link_t;


doc_link_t all_doc_links[DOC_LINK_COUNT];
uint8_t document_count;

uint8_t* document_text = (uint8_t*)0x6000;
uint8_t* document_page_start[256];
uint8_t document_page;
uint8_t document_page_count;
uint8_t current_link_index;

const char* current_keyword_title;
keyword_t* current_keywords;
uint16_t current_keyword_len;
uint8_t* current_keyword_slots;
uint8_t current_loaded_slot;


uint8_t superbasic_keyword_slots[2];
keyword_t superbasic_keywords[] = {
	#include "superbasic_keywords_1.h"
	#include "superbasic_keywords_2.h"
};


document_pack_t* current_pack = (document_pack_t*)TEMP_ADDR;


void title(const char* name) {
	uint16_t len = strlen(name);

	home();
	color(0x01);
	putc(' ');
	putc(' ');
	puts(name);

	for (index1 = len + 2; index1 < TEXT_WIDTH; ++index1) {
		putc(' ');
	}

	color(0x10);
}

void draw_document_footer(void) {
	uint16_t len = strlen(current_pack->copyrights);
	at(0, TEXT_HEIGHT - 1);
	color(0x01);

	putc(' ');
	putc(' ');
	puts(current_pack->copyrights);

	for (index1 = len + 2; index1 < TEXT_WIDTH; ++index1) {
		putc(' ');
	}

	at(TEXT_WIDTH - 10, TEXT_HEIGHT - 1);
	puti(document_page + 1);
	putc('/');
	puti(document_page_count);

	color(0x10);
}

void draw_document_page(void) {
	uint8_t* end = document_page_start[document_page + 1];

	clear();
	title(current_pack->start_doc[all_doc_links[current_link_index].index].title);
	color(0x10);
	at(0, 1);
	ptr0 = document_page_start[document_page];

	while (ptr0 != end) {
		if (ptr0[0] == '\n') {
			newline();
		} else if (ptr0[0] == '\r') {
			// Do nothing
		} else {
			putc(ptr0[0]);
		}
		++ptr0;
	}

	draw_document_footer();
}

void document(void) {
	uint16_t line;
	uint8_t* end = NULL;

	map(all_doc_links[current_link_index].segment);
	decompress(current_pack->start_doc[all_doc_links[current_link_index].index].source, document_text);
	end = decompress_get_end();
	document_page = 0;

	// Locate all the different pages
	document_page_start[0] = document_text;
	ptr0 = document_text + 1;
	index0 = 1;
	line = 1;

	while (ptr0 != end && index0 < 254) {
		if (ptr0[0] == '\n') {
			++line;
			if (line == (TEXT_HEIGHT - 3)) {
				document_page_start[index0] = ptr0;
				line = 0;
				++index0;
			}
		}
		++ptr0;
	}

	document_page_count = index0;
	document_page_start[index0] = end;

	draw_document_page();

	while (true) {
		char ch = getc();

		if (ch == KEY_BACKSPACE || ch == KEY_ESCAPE) {
			return;
		} else if (ch == KEY_DOWN) {	// down
			if (document_page < document_page_count - 1) {
				++document_page;
				draw_document_page();
			}
		} else if (ch == KEY_UP) {	// up
			if (document_page > 0) {
				--document_page;
				draw_document_page();
			}
		}
	}
}

void reference(uint16_t ref_index) {
	color(0x10);
	clear();
	title(current_keywords[ref_index].name);
	at(0, 2);

	if (current_loaded_slot != current_keyword_slots[current_keywords[ref_index].index]) {
		current_loaded_slot = current_keyword_slots[current_keywords[ref_index].index];
		map(current_loaded_slot);
		decompress(TEMP_ADDR + 4, document_text);
	}

	ptr0 = document_text + current_keywords[ref_index].description;
	while (ptr0[0] != 0) {
		if (ptr0[0] == '\n') {
			newline();
		} else if (ptr0[0] == '\r') {
			// Do nothing
		} else {
			putc(ptr0[0]);
		}
		++ptr0;
	}

	while (true) {
		char ch = getc();

		if (ch == KEY_BACKSPACE || ch == KEY_ESCAPE) {
			return;
		}
	}
}

void draw_keyword(uint16_t index, bool highlight) {
	uint8_t x = (index / REF_COLUMN) * 20;
	uint8_t y = 1 + (index % REF_COLUMN);

	color(highlight ? 0x01 : 0x10);
	at(x, y);
	puts(current_keywords[index].name);
}

uint16_t keyword_select(uint16_t current, uint16_t next) {
	draw_keyword(current, false);
	draw_keyword(next, true);
	return next;
}


void draw_references(void) {
	color(0x10);
	clear();
	title(current_keyword_title);

	for (index1 = 0; index1 < current_keyword_len; ++index1) {
		draw_keyword(index1, false);
	}
}

void references(void) {
	current_loaded_slot = 0xFF;

	draw_references();

	index1 = 0;
	draw_keyword(index1, true);

	while (true) {
		char ch = getc();

		if (ch == KEY_BACKSPACE || ch == KEY_ESCAPE) {
			return;
		}

		if (ch >= 'a' && ch <= 'z') {
			if (current_keywords[index1].name[0] == ch) {
				if (index1 + 1 < current_keyword_len && current_keywords[index1 + 1].name[0] == ch) {
					index1 = keyword_select(index1, index1 + 1);
				}
			} else {
				uint16_t index;
				for (index = 0; index < current_keyword_len; ++index) {
					if (current_keywords[index].name[0] == ch) {
						index1 = keyword_select(index1, index);
						break;
					}
				}
			}
		} else if (ch == KEY_LEFT && index1 >= REF_COLUMN) {
			index1 = keyword_select(index1, index1 - REF_COLUMN);
		} else if (ch == KEY_RIGHT && index1 < current_keyword_len - REF_COLUMN) {
			index1 = keyword_select(index1, index1 + REF_COLUMN);
		} else if (ch == KEY_UP && index1 > 0) {
			index1 = keyword_select(index1, index1 - 1);
		} else if (ch == KEY_DOWN && index1 < current_keyword_len - 1) {
			index1 = keyword_select(index1, index1 + 1);
		} else if (ch == KEY_RETURN) {
			uint16_t last_index = index1;
			reference(index1);
			draw_references();

			index1 = last_index;
			draw_keyword(index1, true);
		}
	}
}


void draw_menu(void) {
	color(0x10);
	clear();
	title("Foenix Documentation");
	at(0, 2);
	color(0x10);

	document_count = 0;
	for (index0 = FLASH_SECTOR_START; index0 < FLASH_SECTOR_END && document_count < DOC_LINK_COUNT; ++index0) {
		map(index0);

		if (current_pack->magic == 0xABD0) {
			// Ordinary document
			doc_t* it = current_pack->start_doc;

			while (it != current_pack->end_doc && document_count < DOC_LINK_COUNT) {
				all_doc_links[document_count].segment = index0;
				all_doc_links[document_count].index = it - current_pack->start_doc;

				puts("  ");
				putc(document_count + 'A');
				puts(")   ");
				puts(it->title);
				newline();

				++document_count;
				++it;
			}
		} else if (current_pack->magic == 0xABD1) {
			// SuberBASIC Reference document
			uint16_t index = TEMP_ADDR[2] | (TEMP_ADDR[3] << 8);
			if (index < (sizeof(superbasic_keyword_slots) / sizeof(superbasic_keyword_slots[0]))) {
				superbasic_keyword_slots[index] = index0;
			}
		}
	}

	newline();
	puts("  X)   SuperBASIC Reference");
	newline();
	newline();

	if (get_machine_id() == MACHINE_F256_JR) {
		puts("  Esc) Quit");
	} else {
		puts("    \x16) Quit");
	}
}

void menu(void) {
	draw_menu();

	while (true) {
		char ch = getc();

		if (ch == KEY_BACKSPACE || ch == KEY_ESCAPE) {
			return;
		}

		current_link_index = 0xFF;

		if ((ch >= 'a' && ch < ('a' + document_count))) {
			current_link_index = ch - 'a';
			document();
			draw_menu();
		} else if (ch == 'x') {
			current_keyword_title = "SuperBASIC Reference";
			current_keywords = superbasic_keywords;
			current_keyword_len = sizeof(superbasic_keywords) / sizeof(keyword_t);
			current_keyword_slots = superbasic_keyword_slots;

			references();
			draw_menu();
		}
	}
}


void main(void) {
	menu();
}