/**
 * rammstring.c
 *
 * Search for a word/letter sequence
 * in a non-continuous 'stream' of bytes.
 *
 * $ gcc match.c -o match
 *
 *  Ex:
 *      ./match a
 *      ./match kein
 *      ./match trägtMuss
 *      ./match ' '
 *
 * - hash
 */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>
#include <assert.h>

/* 'Rammstring' */
 static const char was_ich_liebe[] =
    "Ich kann auf Glück verzichten"
    "Weil es Unglück in sich trägt"
    "Muss ich es vernichten"
    "Was ich liebe, will ich richten"
    "Dass ich froh bin, darf nicht sein"
    "Nein (nein, nein)"
    "Ich liebe nicht, dass ich was liebe"
    "Ich mag es nicht, wenn ich was mag"
    "Ich freu' mich nicht, wenn ich mich freue"
    "Weiß ich doch, ich werde es bereuen"
    "Dass ich froh bin, darf nicht sein"
    "Wer mich liebt, geht dabei ein"
    "Was ich liebe"
    "Das wird verderben"
    "Was ich liebe"
    "Das muss auch sterben, muss sterben"
    "So halte ich mich schadlos"
    "Lieben darf ich nicht"
    "Dann brauch' ich nicht zu leiden (nein)"
    "Und kein Herz zerbricht"
    "Dass ich froh bin, darf nicht sein"
    "Nein (nein, nein)"
    "Was ich liebe"
    "Das wird verderben"
    "Was ich liebe"
    "Das muss auch sterben, muss sterben"
    "Auf Glück und Freude"
    "Folgen Qualen"
    "Für alles Schöne"
    "Muss man zahlen, ja"
    "Was ich liebe"
    "Das wird verderben"
    "Was ich liebe"
    "Das muss auch sterben, muss sterben"
    "Was ich liebe";

/**
 * Pretend this is recv()
 * It returns the number of bytes
 * written in given buffer, which is
 * null-terminated.
 * 'trust' chunk can hold the bytes
 */
static int my_recv(char *chunk, size_t *remaining) {
    static int pos;
    int written = 0;

    if (*remaining <= 0)
        *chunk = 0;
    else {
        written = (rand() % *remaining - 1 + 1 /* min 1 char */) + 1;
        memcpy(chunk, &was_ich_liebe[pos], written);
        chunk[written] = '\0';
        pos += written;
        *remaining -= written;
    }
    return written;
}

static int find_sequence(char *input, char *chunk, size_t len) {
    int rval = 0;

    for (int i = 0; i < len; ++i) {
        static int count;
        if (chunk[i] == input[count]) {
            /* have we found a full sequence? */
            if (count+1 == strlen(input)) {
                count = 0;
                rval++;
            } else
                /* looks promising.. */
                count++;
        } else
            count = 0;
    }
    return rval;
}

int main(int argc, char **argv) {
    if (argc < 2) {
        fprintf(stdout, "%s\n", was_ich_liebe);
        exit(0);
    }

    size_t remaining = strlen(was_ich_liebe);
    int total = 0, found = 0;
    char *input = argv[1];
    char buf[remaining+1];

    /* setup the seed */
    srand(time(NULL));

    while (remaining > 0) {
        int written = my_recv(buf, &remaining);
        if (written) {
            fprintf(stdout, "\t{len %d} %s\n", written, buf);
            total += written;
            found += find_sequence(input, buf, written);
        }
    }

    fprintf(stdout, "\nFound %d entries for '%s'\n", found, input);

    return 0;
}
