#include <stdio.h>
#include <string.h>

#define MATCH "ASDFGHJKLPQWERTY"

// Our ''stream''
// 256 bytes
static const char str[] = "AAAAAAAAAAAAAAA"
                          "AAAAAAAAAAAAAAA"
                          "AAAAAAAAAAAAAAA"
                          "ASDFGAAHJKLPQWE" // this must not match
                          "RTYAAAAAAAAAAAA"
                          "AAAAAAAAAAAAAAA"
                          "AAAAAAAAAAAAAAA"
                          "AAAAAAAAAAAAAAA"
                          "AAAAAAAAAAAAAAA"
                          "AAAAAAAAAAAAAAA"
                          "AAAAAAAAAAAAAAA"
                          MATCH
                          "AAAAAAAAAAAA"
                          "AAAAAAAAAAAAAAA"
                          "AAAAAAAAAAAAAAA"
                          "AAAAAAAAAAAAAAA"
                          "AAAAAAAAAAAAAAAA";


/**
 * Simulate recvfrom()
 * just return th next chunk that
 * is 'random' in size
 */
static char *feed_chunk(void) {
    static int rnd[] = {
        5, 1, 9, 10, 2, 16, 9, 9, 5, 3, 1, 6, 4, 4,
        15, 11, 9, 10, 2, 16, 9, 9, 5, 3, 3, 1,  4,
        1, 4, 15, 11, 9, 10, 2, 16, 3, 4
    };
    static int pos;
    static int str_pos;
    static char buf[16+1];

    if (pos < sizeof(rnd)/sizeof(int)) {
        memcpy(buf, &str[str_pos], rnd[pos]);
        buf[rnd[pos]] = 0;
        str_pos += rnd[pos++];
    } else
        *buf = '\0';
    return buf;
}

/**
 * Just a not optimized/tested and
 * pretty much hard-coded code
 * that looks for a segmented pattern
 * in a non-continuous stream.
 * Don't take this too seriously - just a lazy example
 */
int main(int argc, char **argv)
{
    char *buf = MATCH;
    int pos = 0;
    char *str = feed_chunk();

    while (*str != '\0') {
        char *tmp = str;
        while (*tmp) {
            if (buf[pos] == *tmp) {
                pos++;
            } else if (pos == strlen(buf)){
                printf("!!! match !!! -> '%s'\n", buf);
                goto leave;
            } else if (*(tmp+1) && *(tmp+1) != buf[pos+1]) {
                pos = 0;
                break;
            }
            tmp++;
        }

        printf("[%ld] %s\n", strlen(str), str);
        str = feed_chunk();
    }
leave:
    return 0;
}

