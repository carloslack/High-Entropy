#
# Example code reading/printing 
# each given command line argument.
#
########################

#   Sets current argument index into
#   given register
.macro NARG reg
    popl %eax
    movl %eax, \reg
    decl \reg
    pushl \reg; .endm

#   Gets current argument, argv[x]
.macro GETARG reg; movl 8(%esp), \reg; .endm

#   Overwrites current argument by the
#   next one. (shift)
.macro SETARG reg
    popl \reg
    addl $4, %esp
    pushl \reg; .endm

.data
nl: .byte 0xa

.text
.type print,@function
print: # sys_write
    pushl %ebp
    movl %esp, %ebp
    movl 8(%esp), %edx
    movl 12(%esp), %ecx
    movl $1, %ebx
    movl $4, %eax
    int $0x80
    leave
    ret

.globl _start
_start:
loop:
    xorl %edi, %edi
    NARG %ebx
    cmpl $0, %ebx
    je quit
    GETARG %ecx

    # Gets effective address and
    # load it into %esi, needed by lodsb
    leal (%ecx), %esi
strlen:
    # Read a byte at a time from %esi
    lodsb
    
    # if NULL then print
    cmp $0, %al
    je display

    incl %edi
    jmp strlen
display:
    pushl %ecx
    pushl %edi
    call print
    addl $8, %esp


    # puts new line
    pushl $nl
    pushl $1
    call print
    addl $8, %esp

    # move to next argument
    SETARG %ecx
    jmp loop

quit:
    # %ebx is already set
    movb $1, %al
    int $0x80
