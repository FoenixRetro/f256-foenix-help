
#include "f256.h"

#include <string.h>

typedef struct {
	char* title;
	uint8_t* source;
} doc_t;

extern doc_t* documents;

uint8_t* document_text = (uint8_t*)0x8000;
uint8_t* document_page_start[256];
uint8_t document_page;
uint8_t document_page_count;
uint8_t current_document;


void title(const char* name) {
	uint16_t len = strlen(name);

	at(0, 0);
	color(0x01);
	puts("  ");
	puts(name);

	for (index1 = len + 2; index1 < 80; ++index1) {
		putc(' ');
	}
}

void draw_document_page(void) {
	uint8_t* end = document_page_start[document_page + 1];
	ptr1 = document_page_start[document_page];

	clear();
	title(documents[current_document].title);
	color(0x01);
	at(60, 0);
	puth16(document_page + 1);
	putc('/');
	puth16(document_page_count);
	color(0x10);
	at(0, 1);

	while (ptr1 != end) {
		if (ptr1[0] == '\n')
			putnl();
		else
			putc(ptr1[0]);

		++ptr1;
	}
}

void show_document(void) {
	uint16_t line;
	uint8_t* end = fe_decode_lzg(documents[current_document].source, document_text);
	document_page = 0;

	// Locate all the different pages
	document_page_start[0] = document_text;
	ptr0 = document_text + 1;
	index0 = 1;
	line = 1;

	while (ptr0 != end && index0 < 254) {
		if (ptr0[0] == '\n') {
			++line;
			if (line == 58) {
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


static void draw_menu(void) {
	doc_t* it = documents;
	clear();
	title("Foenix Documentation");
	at(0, 2);
	color(0x10);

	index0 = 0;
	while (it->title != NULL && index0 < 26) {
		puts("  ");
		putc(index0 + 'A');
		puts(")   ");
		puts(it->title);

		putnl();
		++it;
		++index0;
	}

	putnl();
	putnl();
	puts("  Esc) Quit");
}

void show_menu(void) {
	draw_menu();

	while (true) {
		char ch = getc();

		if (ch == 0x08) {
			return;
		}

		current_document = 0xFF;

		if ((ch >= 'a' && ch < ('a' + index0))) {
			current_document = ch - 'a';
		}

		if (current_document != 0xFF) {
			show_document();
			draw_menu();
		}
	}
}


void main(void) {
	fe_init();
	show_menu();
}