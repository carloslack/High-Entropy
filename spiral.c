/*
 * huebr
 */
#include <stdio.h>
#include <stdbool.h>

int arg(int x, const char *name)
{
    printf("%s: %d %s\n", __func__, x, name);
    return 0;
}

int p1( int (*ptr)(int, const char*), const char *data, bool execute)
{
    ptr(0, "from function1");
    printf("%s: %p %p %d\n", __func__, ptr, data, execute);
    return 0;
}

int p2( int (*ptr)(int, const char*), const char *data, bool execute)
{
    ptr(0, "from function2");
    printf("%s: %p %p %d\n", __func__, ptr, data, execute);
    return 0;
}

int main(int argc, char **argv)
{
    const char *troll = "troll";
    int (*access)(int, const char*) = arg;
    int (*const x)(int (*)(int, const char*), const char*, bool) = (int (*const)(int(*)(int, const char*),const char*, bool))p1;

    x(access, troll, false); 

    /*
     * X eh um const pointer para uma funcao que recebe um function pointer que recebe um int e
     * um const char* que retorna um int mais um const char* e um booleando que retorna int.
     */

    /* compila? */
    x = (int *const(*)(int(*)(int, const char*),const char*, bool))p2;

    return 0;
}