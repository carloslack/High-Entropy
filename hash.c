#include <stdio.h>
#include <stdlib.h>

#define HASHTSIZ 512

typedef struct innerlist_t
{
    int val;
    struct innerlist_t *next;
}innerlist_t;

typedef struct list_t
{
    int size;
    char *str;
    struct innerlist_t *list;
}list_t;

/*
 * Hash table array
 */
list_t *htable[HASHTSIZ];

/*
 * Bernstein's hash algorithm.
 */
inline int hash(const char *str)
{
    register int h = 0;

    if(!str)
        return -1;

	while(*str) 
        h=33*h + *str++;

    // Make it positive sign
    (h >> 31) & 0x1 ? h = ~h : 0;

	return h % HASHTSIZ;
}

list_t *add_item(char *str, int data)
{
    int key = hash(str);

    innerlist_t *inner = calloc(1, sizeof(innerlist_t));
    if(!inner)
        return NULL;

    inner->val = data;
    inner->next = NULL;

    if(!htable[key])
    {
        htable[key] = calloc(1, sizeof(list_t));
        htable[key]->str = str;
        htable[key]->list = inner;
        htable[key]->size = 1;
    } else
    {
        inner->next = htable[key]->list;
        htable[key]->list = inner;
        htable[key]->size++;
    }

    return htable[key];
}

void list_items(char *str)
{
    int key = hash(str);
    innerlist_t *inner = NULL;

    if(!htable[key])
        return;

    if(htable[key]->size == 1)
    {
        printf("hashstring: %s, value: %d\n", htable[key]->str, htable[key]->list->val);
        return;
    }
        
    for(inner = htable[key]->list; inner != NULL; inner = inner->next)
        printf("hashstring: %s, value: %d\n", htable[key]->str, inner->val);
}

void list_cleanup(void)
{
    int i;
    for(i = 0; i < HASHTSIZ; ++i)
    {   
        if(htable[i])
        {
            innerlist_t *inner;
            for(inner = htable[i]->list; inner != NULL; inner = inner->next)
                free(inner);

            free(htable[i]);
        }
    }
}

int main(int arc, char **argv)
{

    add_item("test1", 2);
    add_item("test1", 3);
    add_item("test1", 100);
    add_item("test2", 60);
    add_item("test3", 99);

    list_items("test1");
    list_items("test2");
    list_items("test3");

    list_cleanup();

    return 0;
}