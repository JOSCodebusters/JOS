/* See COPYRIGHT for copyright information. */

#include <inc/mmu.h>
#include <inc/memlayout.h>
#include <inc/trap.h>

#include <kern/picirq.h>


###################################################################
# exceptions/interrupts
###################################################################

/* TRAPHANDLER defines a globally-visible function for handling a trap.
 * It pushes a trap number onto the stack, then jumps to _alltraps.
 * Use TRAPHANDLER for traps where the CPU automatically pushes an error code.
 *
 * You shouldn't call a TRAPHANDLER function from C, but you may
 * need to _declare_ one in C (for instance, to get a function pointer
 * during IDT setup).  You can declare the function with
 *   void NAME();
 * where NAME is the argument passed to TRAPHANDLER.
 */
#define TRAPHANDLER(name, num)						\
	.globl name;		/* define global symbol for 'name' */	\
	.type name, @function;	/* symbol type is function */		\
	.align 2;		/* align function definition */		\
	name:			/* function starts here */		\
	pushl $(num);							\
	jmp _alltraps

/* Use TRAPHANDLER_NOEC for traps where the CPU doesn't push an error code.
 * It pushes a 0 in place of the error code, so the trap frame has the same
 * format in either case.
 */
#define TRAPHANDLER_NOEC(name, num)					\
	.globl name;							\
	.type name, @function;						\
	.align 2;							\
	name:								\
	pushl $0;							\
	pushl $(num);							\
	jmp _alltraps

.text

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
 
 /*	Table 9-7 summarizes the error information that is available with each exception.
	Table 9-7. Error-Code Summary

	Description                       Interrupt     Error Code
	Number

	Divide error                       0            No
	Debug exceptions                   1            No
	Breakpoint                         3            No
	Overflow                           4            No
	Bounds check                       5            No
	Invalid opcode                     6            No
	Coprocessor not available          7            No
	System error                       8            Yes (always 0)
	Coprocessor Segment Overrun        9            No
	Invalid TSS                       10            Yes
	Segment not present               11            Yes
	Stack exception                   12            Yes
	General protection fault          13            Yes
	Page fault                        14            Yes
	Coprocessor error                 16            No
	Two-byte SW interrupt             0-255         No
 */

	TRAPHANDLER_NOEC(th0, 0)
    TRAPHANDLER_NOEC(th1, 1)
    TRAPHANDLER_NOEC(th3, 3)
    TRAPHANDLER_NOEC(th4, 4)
    TRAPHANDLER_NOEC(th5, 5)
    TRAPHANDLER_NOEC(th6, 6)
    TRAPHANDLER_NOEC(th7, 7)
    TRAPHANDLER(th8, 8)
    TRAPHANDLER_NOEC(th9, 9)
    TRAPHANDLER(th10, 10)
    TRAPHANDLER(th11, 11)
    TRAPHANDLER(th12, 12)
    TRAPHANDLER(th13, 13)
    TRAPHANDLER(th14, 14)
    TRAPHANDLER_NOEC(th16, 16)
    
    TRAPHANDLER_NOEC(th48, 48)
    
    TRAPHANDLER_NOEC(th32, 32)
    TRAPHANDLER_NOEC(th33, 33)
    TRAPHANDLER_NOEC(th34, 34)
    TRAPHANDLER_NOEC(th35, 35)
    TRAPHANDLER_NOEC(th36, 36)
    TRAPHANDLER_NOEC(th37, 37)
    TRAPHANDLER_NOEC(th38, 38)
    TRAPHANDLER_NOEC(th39, 39)
    TRAPHANDLER_NOEC(th40, 40)
    TRAPHANDLER_NOEC(th41, 41)
    TRAPHANDLER_NOEC(th42, 42)
    TRAPHANDLER_NOEC(th43, 43)
    TRAPHANDLER_NOEC(th44, 44)
    TRAPHANDLER_NOEC(th45, 45)
    TRAPHANDLER_NOEC(th46, 46)
    TRAPHANDLER_NOEC(th47, 47)

/*
 * Lab 3: Your code here for _alltraps
 */

_alltraps:
   	pushl %ds
    pushl %es
    pushal
    pushl $GD_KD
    popl %ds
    pushl $GD_KD
    popl %es
    pushl %esp
    call trap
		
		
