/*
 * Carlos Carvalho <carloslack@gmail.com>
 *
 * compile:
 * $ gcc complement.c -o complement -Wall
 * test:
 * $ a=0 ; while [ $a -le 127 ] ; do ./complement $a; a=$(expr $a + 1) ; done
 *
 */
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

static int32_t complement(int32_t n)
{
   int32_t mask = n;
   int32_t ret = (n ? ~n : 1);
   int8_t i;

   if(!n)
     return ret;

   for(i = 31; i >= 0; --i)
     {
        if(!(mask >> i) & 0x1)
         continue;

        while(i >= 0)
             mask |= 1 << i--;

        ret = (~n & mask);
        break;
     }

   return ret;
}

int main(int argc, char **argv)
{
   int32_t n;
   int32_t val;

   if(argc < 2)
     {
        fprintf(stderr, "Use: %s <number>\n", argv[0]);
        exit(0);
     }

   ;
   n = complement((val = atoi(argv[1])));

   printf("%d complement is: %d\n", val, n);

   return 0;
}
