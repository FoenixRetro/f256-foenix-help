
#include "f256.h"

#include <string.h>

#define DOC_LINK_COUNT 	26

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

uint8_t* document_text = (uint8_t*)0x7000;
uint8_t* document_page_start[256];
uint8_t document_page;
uint8_t document_page_count;
uint8_t current_link_index;

document_pack_t* current_pack = (document_pack_t*)FE_TEMP_ADDR;


void title(const char* name) {
	uint16_t len = strlen(name);

	at(0, 0);
	color(0x01);
	putc(' ');
	putc(' ');
	puts(name);

	for (index1 = len + 2; index1 < 80; ++index1) {
		putc(' ');
	}
}

void draw_document_footer(void) {
	uint16_t len = strlen(current_pack->copyrights);
	at(0, 59);
	color(0x01);

	putc(' ');
	putc(' ');
	puts(current_pack->copyrights);

	for (index1 = len + 2; index1 < 80; ++index1) {
		putc(' ');
	}

	at(71, 59);
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
		if (ptr0[0] == '\n')
			putnl();
		else
			putc(ptr0[0]);
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
			if (line == 56) {
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

		if (ch == 0x08) {
			return;
		} else if (ch == 0x0E) {	// down
			if (document_page < document_page_count - 1) {
				++document_page;
				draw_document_page();
			}
		} else if (ch == 0x10) {	// up
			if (document_page > 0) {
				--document_page;
				draw_document_page();
			}
		}
	}
}


void draw_menu(void) {
	clear();
	title("Foenix Documentation");
	at(0, 2);
	color(0x10);

	document_count = 0;
	for (index0 = FE_FLASH_SECTOR_START; index0 < FE_FLASH_SECTOR_END && document_count < DOC_LINK_COUNT; ++index0) {
		map(index0);

		if (current_pack->magic == 0xABD0) {
			doc_t* it = current_pack->start_doc;

			while (it != current_pack->end_doc && document_count < DOC_LINK_COUNT) {
				all_doc_links[document_count].segment = index0;
				all_doc_links[document_count].index = it - current_pack->start_doc;

				puts("  ");
				putc(document_count + 'A');
				puts(")   ");
				puts(it->title);
				putnl();

				++document_count;
				++it;
			}
		}
	}

	putnl();
	putnl();
	puts("  Esc) Quit");
}

void menu(void) {
	draw_menu();

	while (true) {
		char ch = getc();

		if (ch == 0x08) {
			return;
		}

		current_link_index = 0xFF;

		if ((ch >= 'a' && ch < ('a' + document_count))) {
			current_link_index = ch - 'a';
		}

		if (current_link_index != 0xFF) {
			document();
			draw_menu();
		}
	}
}


void main(void) {
	initialize();
	menu();
}