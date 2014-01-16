/**
 * syscalltable.c
 *
 * A friend of mine asked few questions about 
 * (quite deprecated) syscall hooking tecnikz 
 * and went into a question asking why some sys_call_table
 * entry ptr finders algorithms out there return a pointer to pointer (**), C doubts.
 *
 * I didn't look in detail, yet, at sys call table kernel impl so I 
 * started assuming (keep not looking closer because tonight I am feeling lazy) 
 * that it is made out of some pointer to some structure (or array) holding function pointers
 * to syscall functions implementations so as an attempting (dunno yet if I really helped 
 * him or made things worse lol)
 * to 'emulate' the Linux Kernel syscall handlers I wrote the code below.
 *
 * love this kind of silly exercises!
 *
 * - hash
 *
 */

#include <stdio.h>
#include <stdlib.h>

/**
 * some dummy syscalls index. 
 * x86's WORD is 16 bits :/
 */
#define __NR_exit 0
#define __NR_fork __NR_exit + 16
#define __NR_read __NR_fork + 16


/**
 * Dummy syscall functions
 */
void sys_exit(void)
{
    printf("%s\n", __FUNCTION__);
}
void sys_fork(void)
{
    printf("%s\n", __FUNCTION__);
}
void sys_read(void)
{
    printf("%s\n", __FUNCTION__);
}

/**
 * The sys_call_table entry point
 */
typedef void (*sys_call_table)(void);

// The fptr array
static sys_call_table sys[] = {sys_exit, sys_fork, sys_read, NULL};

/**
 * Dummy 'rootkit' sys_call_table finder
 */
sys_call_table **getptr(void)
{
    // return base ptr
    sys_call_table **data = (sys_call_table**)sys;
    return &data[0];
}

int main(int argc, char **argv)
{
    sys_call_table **data = getptr();
    void (*ptr)(void) = (void(*)(void))*data;

    // index 0
    (ptr + __NR_exit)();

    // index 1
    (ptr + __NR_fork)(); 

    // index 2
    (ptr + __NR_read)(); 

    return 0;
}