#include <stdio.h>

int main(int argc, char* argv[]) {
    const char* inFileName = 0;
    const char* outFileName = 0;
    FILE* inFile = 0;
    FILE* outFile = 0;

    int ch;

    if (argc != 3) {
        fprintf(stderr, "Usage: %s <input> <output>\n", argv[0]);
        return 1;
    }

    inFileName = argv[1];
    outFileName = argv[2];

    inFile = fopen(inFileName, "r");
    outFile = fopen(outFileName, "w");

    if (!inFile) {
        fprintf(stderr, "Cannot open input file: \"%s\"\n", inFileName);
        return 1;
    }
    if (!outFile) {
        fprintf(stderr, "Cannot open input file: \"%s\"\n", outFileName);
        return 1;
    }

    while ((ch = fgetc(inFile)) != EOF) {
        fprintf(outFile, "%02X", ch);
        if (ch == '\n') {
            fprintf(outFile, "\n");
        }
    }

    return 0;
}
