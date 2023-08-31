
#include <stdio.h>
#include <stdbool.h>
#include <stdint.h>
#include <string.h>

enum {
	MODE_NONE,
	MODE_DESC,
	MODE_EXAMPLE,
};

void print_escaped(FILE* file, char* str) {
	while (*str) {
		if (*str == '\\') {
			fputs("\\\\", file);
		} else if (*str == '"') {
			fputs("\\\"", file);
		} else {
			fputc(*str, file);
		}
		str++;
	}
}

int main(int argc, char* argv[]) {
	FILE* input = fopen("docs/superbasic_reference.txt", "r");
	if (input == NULL) {
		fprintf(stderr, "Could not load docs/superbasic_reference.txt\n");
		goto done;
	}

	FILE* cout = fopen("src/reference.h", "w");
	if (cout == NULL) {
		fprintf(stderr, "Could not open src/reference.h for writing\n");
		goto done;
	}

	FILE* doc = fopen("docs/superbasic_reference_processed.txt", "w");
	if (doc == NULL) {
		fprintf(stderr, "Could not open docs/superbasic_reference_processed.txt for writing\n");
		goto done;
	}

	// Output header in cout
	fprintf(cout, "\n#ifndef REFERENCE_H\n");
	fprintf(cout, "#define REFERENCE_H\n\n");
	fprintf(cout, "typedef struct {\n");
	fprintf(cout, "    const char* name;\n");
	fprintf(cout, "    uint16_t desciption;\n");
	fprintf(cout, "    uint16_t example;\n");
	fprintf(cout, "} keyword_t;\n\n");
	fprintf(cout, "keyword_t keywords[] = {\n");

	bool first_desc = true;
	bool first_example = true;

	while (!feof(input)) {
		char line[1024];
		fgets(line, 1024, input);

		int len = strlen(line);
		if (len == 1) {
			continue;
		}

		if (strncmp(line, "KEYWORD: ", 9) == 0) {
			if (line[len - 1] == '\n')
				line[len - 1] = 0;
			printf("keyword: %s\n", line + 9);

			if (first_example && !first_desc) {
				// Missing example for this entry
				fprintf(cout, ", 0xFFFF},\n");
			} else if (!first_desc || !first_example) {
				fprintf(cout, "},\n");
			}

			fputs("    {\"", cout);
			print_escaped(cout, line + 9);
			fputs("\"", cout);

			first_desc = true;
			first_example = true;
		} else if (strncmp(line, "    ", 4) == 0 && len > 4) {
			// Example
			if (first_example) {
				int pos = ftell(doc);
				fprintf(cout, ", %d", pos);
			}

			fprintf(doc, "%s", line);
			first_example = false;
		} else {
			// Description
			if (first_desc) {
				int pos = ftell(doc);

				fprintf(cout, ", %d", pos);
				printf("Desciption at %d\n", pos);
			}

			fprintf(doc, "%s", line);
			first_desc = false;
		}
	}

	fprintf(cout, "}\n};\n\n");
	fprintf(cout, "#endif\n");

done:
	fclose(input);
	fclose(cout);
	return 0;
}