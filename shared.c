/*
 * shared.c
 *
 * _Old_ POC (the final version would be much more complex and interesting) 
 * code for an embedded device TV implementing 
 * a custom memory allocator for two 'clients', to each one
 * is given a memory endpoint segmentation, one starting from 
 * left to right and the other one starting from right to left
 * until they reach each other then we cannot allocate more slots.
 *
 * - hash
 *
 *
 */
#include <stdio.h>
#include <string.h>
#include <string.h>
#include <stdlib.h>

#define SIZE 64 

typedef struct __memory_t
{
    char* bottomPtr;
    char data[SIZE];
    int topPos;
    int bottomPos;
} memory_t;

static inline memory_t* getMem()
{
    static int lock = 0;
    static memory_t mem;

    if(!lock)
    {
        lock = 1;
        memset(&mem, 0, sizeof(memory_t));
    }

    return &mem;
}

void printBuf(char* func)
{
    memory_t* mem = (memory_t*)getMem();
    int i;

    printf("%s: ", func);
    for(i=0; i<SIZE; ++i)
    {
        if(mem->data[i] == 0) 
            printf("_");
        else
            printf("%c", mem->data[i]);
    }

    puts("");
}

void allocTop(int size, char* buff)
{
    memory_t* mem = (memory_t*)getMem();

    if(size >= SIZE || size < 0) 
    {
        printf("%d:%s error\n", __LINE__, __FUNCTION__);
        return;
    }

    if( (mem->bottomPos + size) > SIZE)
    {
        printf("%d:%s error\n", __LINE__, __FUNCTION__);
        return;
    }

    memset(mem->data, 0, mem->topPos);
    memcpy(mem->data, buff, size); 
    mem->topPos = size;

    printBuf((char*)__FUNCTION__);
}

void allocBot(int size, char* buff)
{
    memory_t* mem = (memory_t*)getMem();
    
    if(size >= SIZE || size < 0) 
    {
        printf("%d:%s error\n", __LINE__, __FUNCTION__);
        return;
    }

    if( (mem->topPos + size || size <= 0) > SIZE)
    {
        printf("%d:%s error\n", __LINE__, __FUNCTION__);
        return;
    }

    memset(mem->bottomPtr, 0, mem->bottomPos);
    memcpy(mem->data + (SIZE - size), buff, size);
    mem->bottomPos = size;
    mem->bottomPtr = mem->data + (SIZE - size);
    
    printBuf((char*)__FUNCTION__);
}

int main(int argc, char** argv)
{
    allocBot(strlen("test"), "test");
    allocTop(strlen("nuts"), "nuts");
    allocTop(strlen("sync"), "sync");
    allocBot(strlen("x"), "x");
    allocTop(strlen("W"), "W");
    allocBot(strlen("Y"), "Y");
    allocBot(strlen("W"), "W");
    allocBot(strlen("KK"), "KK");
    allocBot(strlen("x y w z"), "x y w z");
    allocBot(strlen("Z"), "Z");
    allocBot(strlen("TT"), "TT");
    allocBot(strlen("O"), "O");
    allocTop(strlen("gta"), "gta");
    allocTop(strlen("W"), "W");
    allocTop(strlen("nsf"), "nsf");
    allocBot(strlen("T"), "T");
    allocBot(strlen("H"), "H");
    allocTop(strlen("R"), "R");
    allocBot(strlen("BAAC"), "BAAC");
    allocBot(0, NULL);
    allocBot(strlen("Bptoooooooooooooooo"), "Bptoooooooooooooooo");
    allocTop(strlen("T"), "T");
    allocBot(strlen("Bptooooooooooooooo"), "Bptooooooooooooooo");
    allocTop(0, NULL);
    allocBot(strlen("BptooooooooooooooFF"), "BptooooooooooooooFF");
    allocBot(strlen("xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"), "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx");
    allocTop(strlen("yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy"), "yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy");
    allocBot(0, NULL);

    return 0;
}
