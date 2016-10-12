
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 80 11 00       	mov    $0x118000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 80 11 f0       	mov    $0xf0118000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/trap.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 50 cc 17 f0       	mov    $0xf017cc50,%eax
f010004b:	2d 26 bd 17 f0       	sub    $0xf017bd26,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 26 bd 17 f0       	push   $0xf017bd26
f0100058:	e8 45 42 00 00       	call   f01042a2 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 9d 04 00 00       	call   f01004ff <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 40 47 10 f0       	push   $0xf0104740
f010006f:	e8 35 2e 00 00       	call   f0102ea9 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 61 0f 00 00       	call   f0100fda <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100079:	e8 9a 28 00 00       	call   f0102918 <env_init>
	trap_init();
f010007e:	e8 97 2e 00 00       	call   f0102f1a <trap_init>

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f0100083:	83 c4 08             	add    $0x8,%esp
f0100086:	6a 00                	push   $0x0
f0100088:	68 e2 83 13 f0       	push   $0xf01383e2
f010008d:	e8 34 2a 00 00       	call   f0102ac6 <env_create>
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
#endif // TEST*

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f0100092:	83 c4 04             	add    $0x4,%esp
f0100095:	ff 35 8c bf 17 f0    	pushl  0xf017bf8c
f010009b:	e8 40 2d 00 00       	call   f0102de0 <env_run>

f01000a0 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000a0:	55                   	push   %ebp
f01000a1:	89 e5                	mov    %esp,%ebp
f01000a3:	56                   	push   %esi
f01000a4:	53                   	push   %ebx
f01000a5:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000a8:	83 3d 40 cc 17 f0 00 	cmpl   $0x0,0xf017cc40
f01000af:	75 37                	jne    f01000e8 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000b1:	89 35 40 cc 17 f0    	mov    %esi,0xf017cc40

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000b7:	fa                   	cli    
f01000b8:	fc                   	cld    

	va_start(ap, fmt);
f01000b9:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000bc:	83 ec 04             	sub    $0x4,%esp
f01000bf:	ff 75 0c             	pushl  0xc(%ebp)
f01000c2:	ff 75 08             	pushl  0x8(%ebp)
f01000c5:	68 5b 47 10 f0       	push   $0xf010475b
f01000ca:	e8 da 2d 00 00       	call   f0102ea9 <cprintf>
	vcprintf(fmt, ap);
f01000cf:	83 c4 08             	add    $0x8,%esp
f01000d2:	53                   	push   %ebx
f01000d3:	56                   	push   %esi
f01000d4:	e8 aa 2d 00 00       	call   f0102e83 <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 f2 56 10 f0 	movl   $0xf01056f2,(%esp)
f01000e0:	e8 c4 2d 00 00       	call   f0102ea9 <cprintf>
	va_end(ap);
f01000e5:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000e8:	83 ec 0c             	sub    $0xc,%esp
f01000eb:	6a 00                	push   $0x0
f01000ed:	e8 b9 06 00 00       	call   f01007ab <monitor>
f01000f2:	83 c4 10             	add    $0x10,%esp
f01000f5:	eb f1                	jmp    f01000e8 <_panic+0x48>

f01000f7 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000f7:	55                   	push   %ebp
f01000f8:	89 e5                	mov    %esp,%ebp
f01000fa:	53                   	push   %ebx
f01000fb:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01000fe:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100101:	ff 75 0c             	pushl  0xc(%ebp)
f0100104:	ff 75 08             	pushl  0x8(%ebp)
f0100107:	68 73 47 10 f0       	push   $0xf0104773
f010010c:	e8 98 2d 00 00       	call   f0102ea9 <cprintf>
	vcprintf(fmt, ap);
f0100111:	83 c4 08             	add    $0x8,%esp
f0100114:	53                   	push   %ebx
f0100115:	ff 75 10             	pushl  0x10(%ebp)
f0100118:	e8 66 2d 00 00       	call   f0102e83 <vcprintf>
	cprintf("\n");
f010011d:	c7 04 24 f2 56 10 f0 	movl   $0xf01056f2,(%esp)
f0100124:	e8 80 2d 00 00       	call   f0102ea9 <cprintf>
	va_end(ap);
}
f0100129:	83 c4 10             	add    $0x10,%esp
f010012c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010012f:	c9                   	leave  
f0100130:	c3                   	ret    

f0100131 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100131:	55                   	push   %ebp
f0100132:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100134:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100139:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010013a:	a8 01                	test   $0x1,%al
f010013c:	74 0b                	je     f0100149 <serial_proc_data+0x18>
f010013e:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100143:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100144:	0f b6 c0             	movzbl %al,%eax
f0100147:	eb 05                	jmp    f010014e <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100149:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f010014e:	5d                   	pop    %ebp
f010014f:	c3                   	ret    

f0100150 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100150:	55                   	push   %ebp
f0100151:	89 e5                	mov    %esp,%ebp
f0100153:	53                   	push   %ebx
f0100154:	83 ec 04             	sub    $0x4,%esp
f0100157:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100159:	eb 2b                	jmp    f0100186 <cons_intr+0x36>
		if (c == 0)
f010015b:	85 c0                	test   %eax,%eax
f010015d:	74 27                	je     f0100186 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f010015f:	8b 0d 64 bf 17 f0    	mov    0xf017bf64,%ecx
f0100165:	8d 51 01             	lea    0x1(%ecx),%edx
f0100168:	89 15 64 bf 17 f0    	mov    %edx,0xf017bf64
f010016e:	88 81 60 bd 17 f0    	mov    %al,-0xfe842a0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f0100174:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010017a:	75 0a                	jne    f0100186 <cons_intr+0x36>
			cons.wpos = 0;
f010017c:	c7 05 64 bf 17 f0 00 	movl   $0x0,0xf017bf64
f0100183:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100186:	ff d3                	call   *%ebx
f0100188:	83 f8 ff             	cmp    $0xffffffff,%eax
f010018b:	75 ce                	jne    f010015b <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f010018d:	83 c4 04             	add    $0x4,%esp
f0100190:	5b                   	pop    %ebx
f0100191:	5d                   	pop    %ebp
f0100192:	c3                   	ret    

f0100193 <kbd_proc_data>:
f0100193:	ba 64 00 00 00       	mov    $0x64,%edx
f0100198:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f0100199:	a8 01                	test   $0x1,%al
f010019b:	0f 84 f0 00 00 00    	je     f0100291 <kbd_proc_data+0xfe>
f01001a1:	ba 60 00 00 00       	mov    $0x60,%edx
f01001a6:	ec                   	in     (%dx),%al
f01001a7:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001a9:	3c e0                	cmp    $0xe0,%al
f01001ab:	75 0d                	jne    f01001ba <kbd_proc_data+0x27>
		// E0 escape character
		shift |= E0ESC;
f01001ad:	83 0d 40 bd 17 f0 40 	orl    $0x40,0xf017bd40
		return 0;
f01001b4:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01001b9:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001ba:	55                   	push   %ebp
f01001bb:	89 e5                	mov    %esp,%ebp
f01001bd:	53                   	push   %ebx
f01001be:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001c1:	84 c0                	test   %al,%al
f01001c3:	79 36                	jns    f01001fb <kbd_proc_data+0x68>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001c5:	8b 0d 40 bd 17 f0    	mov    0xf017bd40,%ecx
f01001cb:	89 cb                	mov    %ecx,%ebx
f01001cd:	83 e3 40             	and    $0x40,%ebx
f01001d0:	83 e0 7f             	and    $0x7f,%eax
f01001d3:	85 db                	test   %ebx,%ebx
f01001d5:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001d8:	0f b6 d2             	movzbl %dl,%edx
f01001db:	0f b6 82 e0 48 10 f0 	movzbl -0xfefb720(%edx),%eax
f01001e2:	83 c8 40             	or     $0x40,%eax
f01001e5:	0f b6 c0             	movzbl %al,%eax
f01001e8:	f7 d0                	not    %eax
f01001ea:	21 c8                	and    %ecx,%eax
f01001ec:	a3 40 bd 17 f0       	mov    %eax,0xf017bd40
		return 0;
f01001f1:	b8 00 00 00 00       	mov    $0x0,%eax
f01001f6:	e9 9e 00 00 00       	jmp    f0100299 <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f01001fb:	8b 0d 40 bd 17 f0    	mov    0xf017bd40,%ecx
f0100201:	f6 c1 40             	test   $0x40,%cl
f0100204:	74 0e                	je     f0100214 <kbd_proc_data+0x81>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100206:	83 c8 80             	or     $0xffffff80,%eax
f0100209:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010020b:	83 e1 bf             	and    $0xffffffbf,%ecx
f010020e:	89 0d 40 bd 17 f0    	mov    %ecx,0xf017bd40
	}

	shift |= shiftcode[data];
f0100214:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f0100217:	0f b6 82 e0 48 10 f0 	movzbl -0xfefb720(%edx),%eax
f010021e:	0b 05 40 bd 17 f0    	or     0xf017bd40,%eax
f0100224:	0f b6 8a e0 47 10 f0 	movzbl -0xfefb820(%edx),%ecx
f010022b:	31 c8                	xor    %ecx,%eax
f010022d:	a3 40 bd 17 f0       	mov    %eax,0xf017bd40

	c = charcode[shift & (CTL | SHIFT)][data];
f0100232:	89 c1                	mov    %eax,%ecx
f0100234:	83 e1 03             	and    $0x3,%ecx
f0100237:	8b 0c 8d c0 47 10 f0 	mov    -0xfefb840(,%ecx,4),%ecx
f010023e:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100242:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100245:	a8 08                	test   $0x8,%al
f0100247:	74 1b                	je     f0100264 <kbd_proc_data+0xd1>
		if ('a' <= c && c <= 'z')
f0100249:	89 da                	mov    %ebx,%edx
f010024b:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f010024e:	83 f9 19             	cmp    $0x19,%ecx
f0100251:	77 05                	ja     f0100258 <kbd_proc_data+0xc5>
			c += 'A' - 'a';
f0100253:	83 eb 20             	sub    $0x20,%ebx
f0100256:	eb 0c                	jmp    f0100264 <kbd_proc_data+0xd1>
		else if ('A' <= c && c <= 'Z')
f0100258:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f010025b:	8d 4b 20             	lea    0x20(%ebx),%ecx
f010025e:	83 fa 19             	cmp    $0x19,%edx
f0100261:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100264:	f7 d0                	not    %eax
f0100266:	a8 06                	test   $0x6,%al
f0100268:	75 2d                	jne    f0100297 <kbd_proc_data+0x104>
f010026a:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100270:	75 25                	jne    f0100297 <kbd_proc_data+0x104>
		cprintf("Rebooting!\n");
f0100272:	83 ec 0c             	sub    $0xc,%esp
f0100275:	68 8d 47 10 f0       	push   $0xf010478d
f010027a:	e8 2a 2c 00 00       	call   f0102ea9 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010027f:	ba 92 00 00 00       	mov    $0x92,%edx
f0100284:	b8 03 00 00 00       	mov    $0x3,%eax
f0100289:	ee                   	out    %al,(%dx)
f010028a:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f010028d:	89 d8                	mov    %ebx,%eax
f010028f:	eb 08                	jmp    f0100299 <kbd_proc_data+0x106>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f0100291:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100296:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100297:	89 d8                	mov    %ebx,%eax
}
f0100299:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010029c:	c9                   	leave  
f010029d:	c3                   	ret    

f010029e <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f010029e:	55                   	push   %ebp
f010029f:	89 e5                	mov    %esp,%ebp
f01002a1:	57                   	push   %edi
f01002a2:	56                   	push   %esi
f01002a3:	53                   	push   %ebx
f01002a4:	83 ec 1c             	sub    $0x1c,%esp
f01002a7:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002a9:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002ae:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002b3:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002b8:	eb 09                	jmp    f01002c3 <cons_putc+0x25>
f01002ba:	89 ca                	mov    %ecx,%edx
f01002bc:	ec                   	in     (%dx),%al
f01002bd:	ec                   	in     (%dx),%al
f01002be:	ec                   	in     (%dx),%al
f01002bf:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01002c0:	83 c3 01             	add    $0x1,%ebx
f01002c3:	89 f2                	mov    %esi,%edx
f01002c5:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002c6:	a8 20                	test   $0x20,%al
f01002c8:	75 08                	jne    f01002d2 <cons_putc+0x34>
f01002ca:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002d0:	7e e8                	jle    f01002ba <cons_putc+0x1c>
f01002d2:	89 f8                	mov    %edi,%eax
f01002d4:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002d7:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002dc:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002dd:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002e2:	be 79 03 00 00       	mov    $0x379,%esi
f01002e7:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002ec:	eb 09                	jmp    f01002f7 <cons_putc+0x59>
f01002ee:	89 ca                	mov    %ecx,%edx
f01002f0:	ec                   	in     (%dx),%al
f01002f1:	ec                   	in     (%dx),%al
f01002f2:	ec                   	in     (%dx),%al
f01002f3:	ec                   	in     (%dx),%al
f01002f4:	83 c3 01             	add    $0x1,%ebx
f01002f7:	89 f2                	mov    %esi,%edx
f01002f9:	ec                   	in     (%dx),%al
f01002fa:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100300:	7f 04                	jg     f0100306 <cons_putc+0x68>
f0100302:	84 c0                	test   %al,%al
f0100304:	79 e8                	jns    f01002ee <cons_putc+0x50>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100306:	ba 78 03 00 00       	mov    $0x378,%edx
f010030b:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f010030f:	ee                   	out    %al,(%dx)
f0100310:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100315:	b8 0d 00 00 00       	mov    $0xd,%eax
f010031a:	ee                   	out    %al,(%dx)
f010031b:	b8 08 00 00 00       	mov    $0x8,%eax
f0100320:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100321:	89 fa                	mov    %edi,%edx
f0100323:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100329:	89 f8                	mov    %edi,%eax
f010032b:	80 cc 07             	or     $0x7,%ah
f010032e:	85 d2                	test   %edx,%edx
f0100330:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100333:	89 f8                	mov    %edi,%eax
f0100335:	0f b6 c0             	movzbl %al,%eax
f0100338:	83 f8 09             	cmp    $0x9,%eax
f010033b:	74 74                	je     f01003b1 <cons_putc+0x113>
f010033d:	83 f8 09             	cmp    $0x9,%eax
f0100340:	7f 0a                	jg     f010034c <cons_putc+0xae>
f0100342:	83 f8 08             	cmp    $0x8,%eax
f0100345:	74 14                	je     f010035b <cons_putc+0xbd>
f0100347:	e9 99 00 00 00       	jmp    f01003e5 <cons_putc+0x147>
f010034c:	83 f8 0a             	cmp    $0xa,%eax
f010034f:	74 3a                	je     f010038b <cons_putc+0xed>
f0100351:	83 f8 0d             	cmp    $0xd,%eax
f0100354:	74 3d                	je     f0100393 <cons_putc+0xf5>
f0100356:	e9 8a 00 00 00       	jmp    f01003e5 <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f010035b:	0f b7 05 68 bf 17 f0 	movzwl 0xf017bf68,%eax
f0100362:	66 85 c0             	test   %ax,%ax
f0100365:	0f 84 e6 00 00 00    	je     f0100451 <cons_putc+0x1b3>
			crt_pos--;
f010036b:	83 e8 01             	sub    $0x1,%eax
f010036e:	66 a3 68 bf 17 f0    	mov    %ax,0xf017bf68
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100374:	0f b7 c0             	movzwl %ax,%eax
f0100377:	66 81 e7 00 ff       	and    $0xff00,%di
f010037c:	83 cf 20             	or     $0x20,%edi
f010037f:	8b 15 6c bf 17 f0    	mov    0xf017bf6c,%edx
f0100385:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100389:	eb 78                	jmp    f0100403 <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f010038b:	66 83 05 68 bf 17 f0 	addw   $0x50,0xf017bf68
f0100392:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100393:	0f b7 05 68 bf 17 f0 	movzwl 0xf017bf68,%eax
f010039a:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003a0:	c1 e8 16             	shr    $0x16,%eax
f01003a3:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003a6:	c1 e0 04             	shl    $0x4,%eax
f01003a9:	66 a3 68 bf 17 f0    	mov    %ax,0xf017bf68
f01003af:	eb 52                	jmp    f0100403 <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f01003b1:	b8 20 00 00 00       	mov    $0x20,%eax
f01003b6:	e8 e3 fe ff ff       	call   f010029e <cons_putc>
		cons_putc(' ');
f01003bb:	b8 20 00 00 00       	mov    $0x20,%eax
f01003c0:	e8 d9 fe ff ff       	call   f010029e <cons_putc>
		cons_putc(' ');
f01003c5:	b8 20 00 00 00       	mov    $0x20,%eax
f01003ca:	e8 cf fe ff ff       	call   f010029e <cons_putc>
		cons_putc(' ');
f01003cf:	b8 20 00 00 00       	mov    $0x20,%eax
f01003d4:	e8 c5 fe ff ff       	call   f010029e <cons_putc>
		cons_putc(' ');
f01003d9:	b8 20 00 00 00       	mov    $0x20,%eax
f01003de:	e8 bb fe ff ff       	call   f010029e <cons_putc>
f01003e3:	eb 1e                	jmp    f0100403 <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01003e5:	0f b7 05 68 bf 17 f0 	movzwl 0xf017bf68,%eax
f01003ec:	8d 50 01             	lea    0x1(%eax),%edx
f01003ef:	66 89 15 68 bf 17 f0 	mov    %dx,0xf017bf68
f01003f6:	0f b7 c0             	movzwl %ax,%eax
f01003f9:	8b 15 6c bf 17 f0    	mov    0xf017bf6c,%edx
f01003ff:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100403:	66 81 3d 68 bf 17 f0 	cmpw   $0x7cf,0xf017bf68
f010040a:	cf 07 
f010040c:	76 43                	jbe    f0100451 <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010040e:	a1 6c bf 17 f0       	mov    0xf017bf6c,%eax
f0100413:	83 ec 04             	sub    $0x4,%esp
f0100416:	68 00 0f 00 00       	push   $0xf00
f010041b:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100421:	52                   	push   %edx
f0100422:	50                   	push   %eax
f0100423:	e8 c7 3e 00 00       	call   f01042ef <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100428:	8b 15 6c bf 17 f0    	mov    0xf017bf6c,%edx
f010042e:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100434:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f010043a:	83 c4 10             	add    $0x10,%esp
f010043d:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100442:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100445:	39 d0                	cmp    %edx,%eax
f0100447:	75 f4                	jne    f010043d <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100449:	66 83 2d 68 bf 17 f0 	subw   $0x50,0xf017bf68
f0100450:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100451:	8b 0d 70 bf 17 f0    	mov    0xf017bf70,%ecx
f0100457:	b8 0e 00 00 00       	mov    $0xe,%eax
f010045c:	89 ca                	mov    %ecx,%edx
f010045e:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010045f:	0f b7 1d 68 bf 17 f0 	movzwl 0xf017bf68,%ebx
f0100466:	8d 71 01             	lea    0x1(%ecx),%esi
f0100469:	89 d8                	mov    %ebx,%eax
f010046b:	66 c1 e8 08          	shr    $0x8,%ax
f010046f:	89 f2                	mov    %esi,%edx
f0100471:	ee                   	out    %al,(%dx)
f0100472:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100477:	89 ca                	mov    %ecx,%edx
f0100479:	ee                   	out    %al,(%dx)
f010047a:	89 d8                	mov    %ebx,%eax
f010047c:	89 f2                	mov    %esi,%edx
f010047e:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f010047f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100482:	5b                   	pop    %ebx
f0100483:	5e                   	pop    %esi
f0100484:	5f                   	pop    %edi
f0100485:	5d                   	pop    %ebp
f0100486:	c3                   	ret    

f0100487 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100487:	80 3d 74 bf 17 f0 00 	cmpb   $0x0,0xf017bf74
f010048e:	74 11                	je     f01004a1 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100490:	55                   	push   %ebp
f0100491:	89 e5                	mov    %esp,%ebp
f0100493:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f0100496:	b8 31 01 10 f0       	mov    $0xf0100131,%eax
f010049b:	e8 b0 fc ff ff       	call   f0100150 <cons_intr>
}
f01004a0:	c9                   	leave  
f01004a1:	f3 c3                	repz ret 

f01004a3 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004a3:	55                   	push   %ebp
f01004a4:	89 e5                	mov    %esp,%ebp
f01004a6:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004a9:	b8 93 01 10 f0       	mov    $0xf0100193,%eax
f01004ae:	e8 9d fc ff ff       	call   f0100150 <cons_intr>
}
f01004b3:	c9                   	leave  
f01004b4:	c3                   	ret    

f01004b5 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004b5:	55                   	push   %ebp
f01004b6:	89 e5                	mov    %esp,%ebp
f01004b8:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004bb:	e8 c7 ff ff ff       	call   f0100487 <serial_intr>
	kbd_intr();
f01004c0:	e8 de ff ff ff       	call   f01004a3 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004c5:	a1 60 bf 17 f0       	mov    0xf017bf60,%eax
f01004ca:	3b 05 64 bf 17 f0    	cmp    0xf017bf64,%eax
f01004d0:	74 26                	je     f01004f8 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004d2:	8d 50 01             	lea    0x1(%eax),%edx
f01004d5:	89 15 60 bf 17 f0    	mov    %edx,0xf017bf60
f01004db:	0f b6 88 60 bd 17 f0 	movzbl -0xfe842a0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f01004e2:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f01004e4:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004ea:	75 11                	jne    f01004fd <cons_getc+0x48>
			cons.rpos = 0;
f01004ec:	c7 05 60 bf 17 f0 00 	movl   $0x0,0xf017bf60
f01004f3:	00 00 00 
f01004f6:	eb 05                	jmp    f01004fd <cons_getc+0x48>
		return c;
	}
	return 0;
f01004f8:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01004fd:	c9                   	leave  
f01004fe:	c3                   	ret    

f01004ff <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01004ff:	55                   	push   %ebp
f0100500:	89 e5                	mov    %esp,%ebp
f0100502:	57                   	push   %edi
f0100503:	56                   	push   %esi
f0100504:	53                   	push   %ebx
f0100505:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100508:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010050f:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100516:	5a a5 
	if (*cp != 0xA55A) {
f0100518:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010051f:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100523:	74 11                	je     f0100536 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100525:	c7 05 70 bf 17 f0 b4 	movl   $0x3b4,0xf017bf70
f010052c:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010052f:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100534:	eb 16                	jmp    f010054c <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100536:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010053d:	c7 05 70 bf 17 f0 d4 	movl   $0x3d4,0xf017bf70
f0100544:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100547:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f010054c:	8b 3d 70 bf 17 f0    	mov    0xf017bf70,%edi
f0100552:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100557:	89 fa                	mov    %edi,%edx
f0100559:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f010055a:	8d 5f 01             	lea    0x1(%edi),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010055d:	89 da                	mov    %ebx,%edx
f010055f:	ec                   	in     (%dx),%al
f0100560:	0f b6 c8             	movzbl %al,%ecx
f0100563:	c1 e1 08             	shl    $0x8,%ecx
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100566:	b8 0f 00 00 00       	mov    $0xf,%eax
f010056b:	89 fa                	mov    %edi,%edx
f010056d:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010056e:	89 da                	mov    %ebx,%edx
f0100570:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f0100571:	89 35 6c bf 17 f0    	mov    %esi,0xf017bf6c
	crt_pos = pos;
f0100577:	0f b6 c0             	movzbl %al,%eax
f010057a:	09 c8                	or     %ecx,%eax
f010057c:	66 a3 68 bf 17 f0    	mov    %ax,0xf017bf68
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100582:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100587:	b8 00 00 00 00       	mov    $0x0,%eax
f010058c:	89 f2                	mov    %esi,%edx
f010058e:	ee                   	out    %al,(%dx)
f010058f:	ba fb 03 00 00       	mov    $0x3fb,%edx
f0100594:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100599:	ee                   	out    %al,(%dx)
f010059a:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f010059f:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005a4:	89 da                	mov    %ebx,%edx
f01005a6:	ee                   	out    %al,(%dx)
f01005a7:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005ac:	b8 00 00 00 00       	mov    $0x0,%eax
f01005b1:	ee                   	out    %al,(%dx)
f01005b2:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005b7:	b8 03 00 00 00       	mov    $0x3,%eax
f01005bc:	ee                   	out    %al,(%dx)
f01005bd:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01005c2:	b8 00 00 00 00       	mov    $0x0,%eax
f01005c7:	ee                   	out    %al,(%dx)
f01005c8:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005cd:	b8 01 00 00 00       	mov    $0x1,%eax
f01005d2:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005d3:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01005d8:	ec                   	in     (%dx),%al
f01005d9:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005db:	3c ff                	cmp    $0xff,%al
f01005dd:	0f 95 05 74 bf 17 f0 	setne  0xf017bf74
f01005e4:	89 f2                	mov    %esi,%edx
f01005e6:	ec                   	in     (%dx),%al
f01005e7:	89 da                	mov    %ebx,%edx
f01005e9:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005ea:	80 f9 ff             	cmp    $0xff,%cl
f01005ed:	75 10                	jne    f01005ff <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f01005ef:	83 ec 0c             	sub    $0xc,%esp
f01005f2:	68 99 47 10 f0       	push   $0xf0104799
f01005f7:	e8 ad 28 00 00       	call   f0102ea9 <cprintf>
f01005fc:	83 c4 10             	add    $0x10,%esp
}
f01005ff:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100602:	5b                   	pop    %ebx
f0100603:	5e                   	pop    %esi
f0100604:	5f                   	pop    %edi
f0100605:	5d                   	pop    %ebp
f0100606:	c3                   	ret    

f0100607 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100607:	55                   	push   %ebp
f0100608:	89 e5                	mov    %esp,%ebp
f010060a:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010060d:	8b 45 08             	mov    0x8(%ebp),%eax
f0100610:	e8 89 fc ff ff       	call   f010029e <cons_putc>
}
f0100615:	c9                   	leave  
f0100616:	c3                   	ret    

f0100617 <getchar>:

int
getchar(void)
{
f0100617:	55                   	push   %ebp
f0100618:	89 e5                	mov    %esp,%ebp
f010061a:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010061d:	e8 93 fe ff ff       	call   f01004b5 <cons_getc>
f0100622:	85 c0                	test   %eax,%eax
f0100624:	74 f7                	je     f010061d <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100626:	c9                   	leave  
f0100627:	c3                   	ret    

f0100628 <iscons>:

int
iscons(int fdnum)
{
f0100628:	55                   	push   %ebp
f0100629:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f010062b:	b8 01 00 00 00       	mov    $0x1,%eax
f0100630:	5d                   	pop    %ebp
f0100631:	c3                   	ret    

f0100632 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100632:	55                   	push   %ebp
f0100633:	89 e5                	mov    %esp,%ebp
f0100635:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100638:	68 e0 49 10 f0       	push   $0xf01049e0
f010063d:	68 fe 49 10 f0       	push   $0xf01049fe
f0100642:	68 03 4a 10 f0       	push   $0xf0104a03
f0100647:	e8 5d 28 00 00       	call   f0102ea9 <cprintf>
f010064c:	83 c4 0c             	add    $0xc,%esp
f010064f:	68 9c 4a 10 f0       	push   $0xf0104a9c
f0100654:	68 0c 4a 10 f0       	push   $0xf0104a0c
f0100659:	68 03 4a 10 f0       	push   $0xf0104a03
f010065e:	e8 46 28 00 00       	call   f0102ea9 <cprintf>
f0100663:	83 c4 0c             	add    $0xc,%esp
f0100666:	68 c4 4a 10 f0       	push   $0xf0104ac4
f010066b:	68 15 4a 10 f0       	push   $0xf0104a15
f0100670:	68 03 4a 10 f0       	push   $0xf0104a03
f0100675:	e8 2f 28 00 00       	call   f0102ea9 <cprintf>
	return 0;
}
f010067a:	b8 00 00 00 00       	mov    $0x0,%eax
f010067f:	c9                   	leave  
f0100680:	c3                   	ret    

f0100681 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100681:	55                   	push   %ebp
f0100682:	89 e5                	mov    %esp,%ebp
f0100684:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100687:	68 1f 4a 10 f0       	push   $0xf0104a1f
f010068c:	e8 18 28 00 00       	call   f0102ea9 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100691:	83 c4 08             	add    $0x8,%esp
f0100694:	68 0c 00 10 00       	push   $0x10000c
f0100699:	68 e4 4a 10 f0       	push   $0xf0104ae4
f010069e:	e8 06 28 00 00       	call   f0102ea9 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006a3:	83 c4 0c             	add    $0xc,%esp
f01006a6:	68 0c 00 10 00       	push   $0x10000c
f01006ab:	68 0c 00 10 f0       	push   $0xf010000c
f01006b0:	68 0c 4b 10 f0       	push   $0xf0104b0c
f01006b5:	e8 ef 27 00 00       	call   f0102ea9 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006ba:	83 c4 0c             	add    $0xc,%esp
f01006bd:	68 31 47 10 00       	push   $0x104731
f01006c2:	68 31 47 10 f0       	push   $0xf0104731
f01006c7:	68 30 4b 10 f0       	push   $0xf0104b30
f01006cc:	e8 d8 27 00 00       	call   f0102ea9 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006d1:	83 c4 0c             	add    $0xc,%esp
f01006d4:	68 26 bd 17 00       	push   $0x17bd26
f01006d9:	68 26 bd 17 f0       	push   $0xf017bd26
f01006de:	68 54 4b 10 f0       	push   $0xf0104b54
f01006e3:	e8 c1 27 00 00       	call   f0102ea9 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006e8:	83 c4 0c             	add    $0xc,%esp
f01006eb:	68 50 cc 17 00       	push   $0x17cc50
f01006f0:	68 50 cc 17 f0       	push   $0xf017cc50
f01006f5:	68 78 4b 10 f0       	push   $0xf0104b78
f01006fa:	e8 aa 27 00 00       	call   f0102ea9 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006ff:	b8 4f d0 17 f0       	mov    $0xf017d04f,%eax
f0100704:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100709:	83 c4 08             	add    $0x8,%esp
f010070c:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f0100711:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100717:	85 c0                	test   %eax,%eax
f0100719:	0f 48 c2             	cmovs  %edx,%eax
f010071c:	c1 f8 0a             	sar    $0xa,%eax
f010071f:	50                   	push   %eax
f0100720:	68 9c 4b 10 f0       	push   $0xf0104b9c
f0100725:	e8 7f 27 00 00       	call   f0102ea9 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f010072a:	b8 00 00 00 00       	mov    $0x0,%eax
f010072f:	c9                   	leave  
f0100730:	c3                   	ret    

f0100731 <mon_backtrace>:


int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100731:	55                   	push   %ebp
f0100732:	89 e5                	mov    %esp,%ebp
f0100734:	56                   	push   %esi
f0100735:	53                   	push   %ebx
f0100736:	83 ec 2c             	sub    $0x2c,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f0100739:	89 eb                	mov    %ebp,%ebx
	struct Eipdebuginfo info;
	uint32_t* test_ebp = (uint32_t*) read_ebp();
	cprintf("Stack backtrace:\n");
f010073b:	68 38 4a 10 f0       	push   $0xf0104a38
f0100740:	e8 64 27 00 00       	call   f0102ea9 <cprintf>
	while (test_ebp)
f0100745:	83 c4 10             	add    $0x10,%esp
	 {
		cprintf("  ebp %08x eip %08x args %08x %08x %08x %08x %08x",test_ebp, test_ebp[1],test_ebp[2],test_ebp[3],test_ebp[4],test_ebp[5], test_ebp[6]);
		debuginfo_eip(test_ebp[1],&info);
f0100748:	8d 75 e0             	lea    -0x20(%ebp),%esi
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	struct Eipdebuginfo info;
	uint32_t* test_ebp = (uint32_t*) read_ebp();
	cprintf("Stack backtrace:\n");
	while (test_ebp)
f010074b:	eb 4e                	jmp    f010079b <mon_backtrace+0x6a>
	 {
		cprintf("  ebp %08x eip %08x args %08x %08x %08x %08x %08x",test_ebp, test_ebp[1],test_ebp[2],test_ebp[3],test_ebp[4],test_ebp[5], test_ebp[6]);
f010074d:	ff 73 18             	pushl  0x18(%ebx)
f0100750:	ff 73 14             	pushl  0x14(%ebx)
f0100753:	ff 73 10             	pushl  0x10(%ebx)
f0100756:	ff 73 0c             	pushl  0xc(%ebx)
f0100759:	ff 73 08             	pushl  0x8(%ebx)
f010075c:	ff 73 04             	pushl  0x4(%ebx)
f010075f:	53                   	push   %ebx
f0100760:	68 c8 4b 10 f0       	push   $0xf0104bc8
f0100765:	e8 3f 27 00 00       	call   f0102ea9 <cprintf>
		debuginfo_eip(test_ebp[1],&info);
f010076a:	83 c4 18             	add    $0x18,%esp
f010076d:	56                   	push   %esi
f010076e:	ff 73 04             	pushl  0x4(%ebx)
f0100771:	e8 b3 30 00 00       	call   f0103829 <debuginfo_eip>
		cprintf("\t    %s:%d: %.*s+%d\n",info.eip_file,info.eip_line,info.eip_fn_namelen,info.eip_fn_name,test_ebp[1] - info.eip_fn_addr);
f0100776:	83 c4 08             	add    $0x8,%esp
f0100779:	8b 43 04             	mov    0x4(%ebx),%eax
f010077c:	2b 45 f0             	sub    -0x10(%ebp),%eax
f010077f:	50                   	push   %eax
f0100780:	ff 75 e8             	pushl  -0x18(%ebp)
f0100783:	ff 75 ec             	pushl  -0x14(%ebp)
f0100786:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100789:	ff 75 e0             	pushl  -0x20(%ebp)
f010078c:	68 4a 4a 10 f0       	push   $0xf0104a4a
f0100791:	e8 13 27 00 00       	call   f0102ea9 <cprintf>
		test_ebp = (uint32_t*) *test_ebp;
f0100796:	8b 1b                	mov    (%ebx),%ebx
f0100798:	83 c4 20             	add    $0x20,%esp
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	struct Eipdebuginfo info;
	uint32_t* test_ebp = (uint32_t*) read_ebp();
	cprintf("Stack backtrace:\n");
	while (test_ebp)
f010079b:	85 db                	test   %ebx,%ebx
f010079d:	75 ae                	jne    f010074d <mon_backtrace+0x1c>
		debuginfo_eip(test_ebp[1],&info);
		cprintf("\t    %s:%d: %.*s+%d\n",info.eip_file,info.eip_line,info.eip_fn_namelen,info.eip_fn_name,test_ebp[1] - info.eip_fn_addr);
		test_ebp = (uint32_t*) *test_ebp;
	}
return 0;
}
f010079f:	b8 00 00 00 00       	mov    $0x0,%eax
f01007a4:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01007a7:	5b                   	pop    %ebx
f01007a8:	5e                   	pop    %esi
f01007a9:	5d                   	pop    %ebp
f01007aa:	c3                   	ret    

f01007ab <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007ab:	55                   	push   %ebp
f01007ac:	89 e5                	mov    %esp,%ebp
f01007ae:	57                   	push   %edi
f01007af:	56                   	push   %esi
f01007b0:	53                   	push   %ebx
f01007b1:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007b4:	68 fc 4b 10 f0       	push   $0xf0104bfc
f01007b9:	e8 eb 26 00 00       	call   f0102ea9 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007be:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f01007c5:	e8 df 26 00 00       	call   f0102ea9 <cprintf>

	if (tf != NULL)
f01007ca:	83 c4 10             	add    $0x10,%esp
f01007cd:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f01007d1:	74 0e                	je     f01007e1 <monitor+0x36>
		print_trapframe(tf);
f01007d3:	83 ec 0c             	sub    $0xc,%esp
f01007d6:	ff 75 08             	pushl  0x8(%ebp)
f01007d9:	e8 05 2b 00 00       	call   f01032e3 <print_trapframe>
f01007de:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f01007e1:	83 ec 0c             	sub    $0xc,%esp
f01007e4:	68 5f 4a 10 f0       	push   $0xf0104a5f
f01007e9:	e8 5d 38 00 00       	call   f010404b <readline>
f01007ee:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01007f0:	83 c4 10             	add    $0x10,%esp
f01007f3:	85 c0                	test   %eax,%eax
f01007f5:	74 ea                	je     f01007e1 <monitor+0x36>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01007f7:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01007fe:	be 00 00 00 00       	mov    $0x0,%esi
f0100803:	eb 0a                	jmp    f010080f <monitor+0x64>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100805:	c6 03 00             	movb   $0x0,(%ebx)
f0100808:	89 f7                	mov    %esi,%edi
f010080a:	8d 5b 01             	lea    0x1(%ebx),%ebx
f010080d:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f010080f:	0f b6 03             	movzbl (%ebx),%eax
f0100812:	84 c0                	test   %al,%al
f0100814:	74 63                	je     f0100879 <monitor+0xce>
f0100816:	83 ec 08             	sub    $0x8,%esp
f0100819:	0f be c0             	movsbl %al,%eax
f010081c:	50                   	push   %eax
f010081d:	68 63 4a 10 f0       	push   $0xf0104a63
f0100822:	e8 3e 3a 00 00       	call   f0104265 <strchr>
f0100827:	83 c4 10             	add    $0x10,%esp
f010082a:	85 c0                	test   %eax,%eax
f010082c:	75 d7                	jne    f0100805 <monitor+0x5a>
			*buf++ = 0;
		if (*buf == 0)
f010082e:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100831:	74 46                	je     f0100879 <monitor+0xce>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100833:	83 fe 0f             	cmp    $0xf,%esi
f0100836:	75 14                	jne    f010084c <monitor+0xa1>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100838:	83 ec 08             	sub    $0x8,%esp
f010083b:	6a 10                	push   $0x10
f010083d:	68 68 4a 10 f0       	push   $0xf0104a68
f0100842:	e8 62 26 00 00       	call   f0102ea9 <cprintf>
f0100847:	83 c4 10             	add    $0x10,%esp
f010084a:	eb 95                	jmp    f01007e1 <monitor+0x36>
			return 0;
		}
		argv[argc++] = buf;
f010084c:	8d 7e 01             	lea    0x1(%esi),%edi
f010084f:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100853:	eb 03                	jmp    f0100858 <monitor+0xad>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100855:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100858:	0f b6 03             	movzbl (%ebx),%eax
f010085b:	84 c0                	test   %al,%al
f010085d:	74 ae                	je     f010080d <monitor+0x62>
f010085f:	83 ec 08             	sub    $0x8,%esp
f0100862:	0f be c0             	movsbl %al,%eax
f0100865:	50                   	push   %eax
f0100866:	68 63 4a 10 f0       	push   $0xf0104a63
f010086b:	e8 f5 39 00 00       	call   f0104265 <strchr>
f0100870:	83 c4 10             	add    $0x10,%esp
f0100873:	85 c0                	test   %eax,%eax
f0100875:	74 de                	je     f0100855 <monitor+0xaa>
f0100877:	eb 94                	jmp    f010080d <monitor+0x62>
			buf++;
	}
	argv[argc] = 0;
f0100879:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100880:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100881:	85 f6                	test   %esi,%esi
f0100883:	0f 84 58 ff ff ff    	je     f01007e1 <monitor+0x36>
f0100889:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f010088e:	83 ec 08             	sub    $0x8,%esp
f0100891:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100894:	ff 34 85 60 4c 10 f0 	pushl  -0xfefb3a0(,%eax,4)
f010089b:	ff 75 a8             	pushl  -0x58(%ebp)
f010089e:	e8 64 39 00 00       	call   f0104207 <strcmp>
f01008a3:	83 c4 10             	add    $0x10,%esp
f01008a6:	85 c0                	test   %eax,%eax
f01008a8:	75 21                	jne    f01008cb <monitor+0x120>
			return commands[i].func(argc, argv, tf);
f01008aa:	83 ec 04             	sub    $0x4,%esp
f01008ad:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01008b0:	ff 75 08             	pushl  0x8(%ebp)
f01008b3:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01008b6:	52                   	push   %edx
f01008b7:	56                   	push   %esi
f01008b8:	ff 14 85 68 4c 10 f0 	call   *-0xfefb398(,%eax,4)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008bf:	83 c4 10             	add    $0x10,%esp
f01008c2:	85 c0                	test   %eax,%eax
f01008c4:	78 25                	js     f01008eb <monitor+0x140>
f01008c6:	e9 16 ff ff ff       	jmp    f01007e1 <monitor+0x36>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f01008cb:	83 c3 01             	add    $0x1,%ebx
f01008ce:	83 fb 03             	cmp    $0x3,%ebx
f01008d1:	75 bb                	jne    f010088e <monitor+0xe3>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008d3:	83 ec 08             	sub    $0x8,%esp
f01008d6:	ff 75 a8             	pushl  -0x58(%ebp)
f01008d9:	68 85 4a 10 f0       	push   $0xf0104a85
f01008de:	e8 c6 25 00 00       	call   f0102ea9 <cprintf>
f01008e3:	83 c4 10             	add    $0x10,%esp
f01008e6:	e9 f6 fe ff ff       	jmp    f01007e1 <monitor+0x36>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01008eb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01008ee:	5b                   	pop    %ebx
f01008ef:	5e                   	pop    %esi
f01008f0:	5f                   	pop    %edi
f01008f1:	5d                   	pop    %ebp
f01008f2:	c3                   	ret    

f01008f3 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f01008f3:	55                   	push   %ebp
f01008f4:	89 e5                	mov    %esp,%ebp
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f01008f6:	83 3d 78 bf 17 f0 00 	cmpl   $0x0,0xf017bf78
f01008fd:	75 11                	jne    f0100910 <boot_alloc+0x1d>
		extern char end[];
		//cprintf("end=%x\n",end);
		//cprintf("PGSIZE=%x\n",PGSIZE);
		nextfree = ROUNDUP((char *) end, PGSIZE);
f01008ff:	ba 4f dc 17 f0       	mov    $0xf017dc4f,%edx
f0100904:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010090a:	89 15 78 bf 17 f0    	mov    %edx,0xf017bf78
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	//cprintf("n=%x\n",n);
	//cprintf("Initial=%x\n",nextfree);
	result=nextfree;
f0100910:	8b 0d 78 bf 17 f0    	mov    0xf017bf78,%ecx
	nextfree = ROUNDUP((char *) nextfree+n, PGSIZE);
f0100916:	8d 94 01 ff 0f 00 00 	lea    0xfff(%ecx,%eax,1),%edx
f010091d:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100923:	89 15 78 bf 17 f0    	mov    %edx,0xf017bf78
	//cprintf("Final=%x\n",nextfree);

	return result;
}
f0100929:	89 c8                	mov    %ecx,%eax
f010092b:	5d                   	pop    %ebp
f010092c:	c3                   	ret    

f010092d <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f010092d:	89 d1                	mov    %edx,%ecx
f010092f:	c1 e9 16             	shr    $0x16,%ecx
f0100932:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100935:	a8 01                	test   $0x1,%al
f0100937:	74 52                	je     f010098b <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100939:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010093e:	89 c1                	mov    %eax,%ecx
f0100940:	c1 e9 0c             	shr    $0xc,%ecx
f0100943:	3b 0d 44 cc 17 f0    	cmp    0xf017cc44,%ecx
f0100949:	72 1b                	jb     f0100966 <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f010094b:	55                   	push   %ebp
f010094c:	89 e5                	mov    %esp,%ebp
f010094e:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100951:	50                   	push   %eax
f0100952:	68 84 4c 10 f0       	push   $0xf0104c84
f0100957:	68 40 03 00 00       	push   $0x340
f010095c:	68 41 54 10 f0       	push   $0xf0105441
f0100961:	e8 3a f7 ff ff       	call   f01000a0 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100966:	c1 ea 0c             	shr    $0xc,%edx
f0100969:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f010096f:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100976:	89 c2                	mov    %eax,%edx
f0100978:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f010097b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100980:	85 d2                	test   %edx,%edx
f0100982:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100987:	0f 44 c2             	cmove  %edx,%eax
f010098a:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f010098b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100990:	c3                   	ret    

f0100991 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100991:	55                   	push   %ebp
f0100992:	89 e5                	mov    %esp,%ebp
f0100994:	57                   	push   %edi
f0100995:	56                   	push   %esi
f0100996:	53                   	push   %ebx
f0100997:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f010099a:	84 c0                	test   %al,%al
f010099c:	0f 85 72 02 00 00    	jne    f0100c14 <check_page_free_list+0x283>
f01009a2:	e9 7f 02 00 00       	jmp    f0100c26 <check_page_free_list+0x295>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f01009a7:	83 ec 04             	sub    $0x4,%esp
f01009aa:	68 a8 4c 10 f0       	push   $0xf0104ca8
f01009af:	68 7e 02 00 00       	push   $0x27e
f01009b4:	68 41 54 10 f0       	push   $0xf0105441
f01009b9:	e8 e2 f6 ff ff       	call   f01000a0 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f01009be:	8d 55 d8             	lea    -0x28(%ebp),%edx
f01009c1:	89 55 e0             	mov    %edx,-0x20(%ebp)
f01009c4:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01009c7:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f01009ca:	89 c2                	mov    %eax,%edx
f01009cc:	2b 15 4c cc 17 f0    	sub    0xf017cc4c,%edx
f01009d2:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f01009d8:	0f 95 c2             	setne  %dl
f01009db:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f01009de:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f01009e2:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f01009e4:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f01009e8:	8b 00                	mov    (%eax),%eax
f01009ea:	85 c0                	test   %eax,%eax
f01009ec:	75 dc                	jne    f01009ca <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f01009ee:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01009f1:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f01009f7:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01009fa:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01009fd:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f01009ff:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100a02:	a3 80 bf 17 f0       	mov    %eax,0xf017bf80
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a07:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a0c:	8b 1d 80 bf 17 f0    	mov    0xf017bf80,%ebx
f0100a12:	eb 53                	jmp    f0100a67 <check_page_free_list+0xd6>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a14:	89 d8                	mov    %ebx,%eax
f0100a16:	2b 05 4c cc 17 f0    	sub    0xf017cc4c,%eax
f0100a1c:	c1 f8 03             	sar    $0x3,%eax
f0100a1f:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100a22:	89 c2                	mov    %eax,%edx
f0100a24:	c1 ea 16             	shr    $0x16,%edx
f0100a27:	39 f2                	cmp    %esi,%edx
f0100a29:	73 3a                	jae    f0100a65 <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a2b:	89 c2                	mov    %eax,%edx
f0100a2d:	c1 ea 0c             	shr    $0xc,%edx
f0100a30:	3b 15 44 cc 17 f0    	cmp    0xf017cc44,%edx
f0100a36:	72 12                	jb     f0100a4a <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a38:	50                   	push   %eax
f0100a39:	68 84 4c 10 f0       	push   $0xf0104c84
f0100a3e:	6a 56                	push   $0x56
f0100a40:	68 4d 54 10 f0       	push   $0xf010544d
f0100a45:	e8 56 f6 ff ff       	call   f01000a0 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100a4a:	83 ec 04             	sub    $0x4,%esp
f0100a4d:	68 80 00 00 00       	push   $0x80
f0100a52:	68 97 00 00 00       	push   $0x97
f0100a57:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100a5c:	50                   	push   %eax
f0100a5d:	e8 40 38 00 00       	call   f01042a2 <memset>
f0100a62:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a65:	8b 1b                	mov    (%ebx),%ebx
f0100a67:	85 db                	test   %ebx,%ebx
f0100a69:	75 a9                	jne    f0100a14 <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100a6b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a70:	e8 7e fe ff ff       	call   f01008f3 <boot_alloc>
f0100a75:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a78:	8b 15 80 bf 17 f0    	mov    0xf017bf80,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100a7e:	8b 0d 4c cc 17 f0    	mov    0xf017cc4c,%ecx
		assert(pp < pages + npages);
f0100a84:	a1 44 cc 17 f0       	mov    0xf017cc44,%eax
f0100a89:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100a8c:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100a8f:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100a92:	be 00 00 00 00       	mov    $0x0,%esi
f0100a97:	89 5d d0             	mov    %ebx,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a9a:	e9 30 01 00 00       	jmp    f0100bcf <check_page_free_list+0x23e>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100a9f:	39 ca                	cmp    %ecx,%edx
f0100aa1:	73 19                	jae    f0100abc <check_page_free_list+0x12b>
f0100aa3:	68 5b 54 10 f0       	push   $0xf010545b
f0100aa8:	68 67 54 10 f0       	push   $0xf0105467
f0100aad:	68 98 02 00 00       	push   $0x298
f0100ab2:	68 41 54 10 f0       	push   $0xf0105441
f0100ab7:	e8 e4 f5 ff ff       	call   f01000a0 <_panic>
		assert(pp < pages + npages);
f0100abc:	39 fa                	cmp    %edi,%edx
f0100abe:	72 19                	jb     f0100ad9 <check_page_free_list+0x148>
f0100ac0:	68 7c 54 10 f0       	push   $0xf010547c
f0100ac5:	68 67 54 10 f0       	push   $0xf0105467
f0100aca:	68 99 02 00 00       	push   $0x299
f0100acf:	68 41 54 10 f0       	push   $0xf0105441
f0100ad4:	e8 c7 f5 ff ff       	call   f01000a0 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100ad9:	89 d0                	mov    %edx,%eax
f0100adb:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100ade:	a8 07                	test   $0x7,%al
f0100ae0:	74 19                	je     f0100afb <check_page_free_list+0x16a>
f0100ae2:	68 cc 4c 10 f0       	push   $0xf0104ccc
f0100ae7:	68 67 54 10 f0       	push   $0xf0105467
f0100aec:	68 9a 02 00 00       	push   $0x29a
f0100af1:	68 41 54 10 f0       	push   $0xf0105441
f0100af6:	e8 a5 f5 ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100afb:	c1 f8 03             	sar    $0x3,%eax
f0100afe:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100b01:	85 c0                	test   %eax,%eax
f0100b03:	75 19                	jne    f0100b1e <check_page_free_list+0x18d>
f0100b05:	68 90 54 10 f0       	push   $0xf0105490
f0100b0a:	68 67 54 10 f0       	push   $0xf0105467
f0100b0f:	68 9d 02 00 00       	push   $0x29d
f0100b14:	68 41 54 10 f0       	push   $0xf0105441
f0100b19:	e8 82 f5 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100b1e:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100b23:	75 19                	jne    f0100b3e <check_page_free_list+0x1ad>
f0100b25:	68 a1 54 10 f0       	push   $0xf01054a1
f0100b2a:	68 67 54 10 f0       	push   $0xf0105467
f0100b2f:	68 9e 02 00 00       	push   $0x29e
f0100b34:	68 41 54 10 f0       	push   $0xf0105441
f0100b39:	e8 62 f5 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100b3e:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100b43:	75 19                	jne    f0100b5e <check_page_free_list+0x1cd>
f0100b45:	68 00 4d 10 f0       	push   $0xf0104d00
f0100b4a:	68 67 54 10 f0       	push   $0xf0105467
f0100b4f:	68 9f 02 00 00       	push   $0x29f
f0100b54:	68 41 54 10 f0       	push   $0xf0105441
f0100b59:	e8 42 f5 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100b5e:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100b63:	75 19                	jne    f0100b7e <check_page_free_list+0x1ed>
f0100b65:	68 ba 54 10 f0       	push   $0xf01054ba
f0100b6a:	68 67 54 10 f0       	push   $0xf0105467
f0100b6f:	68 a0 02 00 00       	push   $0x2a0
f0100b74:	68 41 54 10 f0       	push   $0xf0105441
f0100b79:	e8 22 f5 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100b7e:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100b83:	76 3f                	jbe    f0100bc4 <check_page_free_list+0x233>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b85:	89 c3                	mov    %eax,%ebx
f0100b87:	c1 eb 0c             	shr    $0xc,%ebx
f0100b8a:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100b8d:	77 12                	ja     f0100ba1 <check_page_free_list+0x210>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b8f:	50                   	push   %eax
f0100b90:	68 84 4c 10 f0       	push   $0xf0104c84
f0100b95:	6a 56                	push   $0x56
f0100b97:	68 4d 54 10 f0       	push   $0xf010544d
f0100b9c:	e8 ff f4 ff ff       	call   f01000a0 <_panic>
f0100ba1:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100ba6:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100ba9:	76 1e                	jbe    f0100bc9 <check_page_free_list+0x238>
f0100bab:	68 24 4d 10 f0       	push   $0xf0104d24
f0100bb0:	68 67 54 10 f0       	push   $0xf0105467
f0100bb5:	68 a1 02 00 00       	push   $0x2a1
f0100bba:	68 41 54 10 f0       	push   $0xf0105441
f0100bbf:	e8 dc f4 ff ff       	call   f01000a0 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100bc4:	83 c6 01             	add    $0x1,%esi
f0100bc7:	eb 04                	jmp    f0100bcd <check_page_free_list+0x23c>
		else
			++nfree_extmem;
f0100bc9:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100bcd:	8b 12                	mov    (%edx),%edx
f0100bcf:	85 d2                	test   %edx,%edx
f0100bd1:	0f 85 c8 fe ff ff    	jne    f0100a9f <check_page_free_list+0x10e>
f0100bd7:	8b 5d d0             	mov    -0x30(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100bda:	85 f6                	test   %esi,%esi
f0100bdc:	7f 19                	jg     f0100bf7 <check_page_free_list+0x266>
f0100bde:	68 d4 54 10 f0       	push   $0xf01054d4
f0100be3:	68 67 54 10 f0       	push   $0xf0105467
f0100be8:	68 a9 02 00 00       	push   $0x2a9
f0100bed:	68 41 54 10 f0       	push   $0xf0105441
f0100bf2:	e8 a9 f4 ff ff       	call   f01000a0 <_panic>
	assert(nfree_extmem > 0);
f0100bf7:	85 db                	test   %ebx,%ebx
f0100bf9:	7f 42                	jg     f0100c3d <check_page_free_list+0x2ac>
f0100bfb:	68 e6 54 10 f0       	push   $0xf01054e6
f0100c00:	68 67 54 10 f0       	push   $0xf0105467
f0100c05:	68 aa 02 00 00       	push   $0x2aa
f0100c0a:	68 41 54 10 f0       	push   $0xf0105441
f0100c0f:	e8 8c f4 ff ff       	call   f01000a0 <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100c14:	a1 80 bf 17 f0       	mov    0xf017bf80,%eax
f0100c19:	85 c0                	test   %eax,%eax
f0100c1b:	0f 85 9d fd ff ff    	jne    f01009be <check_page_free_list+0x2d>
f0100c21:	e9 81 fd ff ff       	jmp    f01009a7 <check_page_free_list+0x16>
f0100c26:	83 3d 80 bf 17 f0 00 	cmpl   $0x0,0xf017bf80
f0100c2d:	0f 84 74 fd ff ff    	je     f01009a7 <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c33:	be 00 04 00 00       	mov    $0x400,%esi
f0100c38:	e9 cf fd ff ff       	jmp    f0100a0c <check_page_free_list+0x7b>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0100c3d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100c40:	5b                   	pop    %ebx
f0100c41:	5e                   	pop    %esi
f0100c42:	5f                   	pop    %edi
f0100c43:	5d                   	pop    %ebp
f0100c44:	c3                   	ret    

f0100c45 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100c45:	55                   	push   %ebp
f0100c46:	89 e5                	mov    %esp,%ebp
f0100c48:	56                   	push   %esi
f0100c49:	53                   	push   %ebx
	// free pages!
	size_t i;
	int keriolim=0;
	//cprintf("npages=%d\n",npages);
	//cprintf("npages_basemem=%d\n",npages_basemem);
	for (i = 1; i < npages_basemem; i++) {
f0100c4a:	8b 35 84 bf 17 f0    	mov    0xf017bf84,%esi
f0100c50:	8b 1d 80 bf 17 f0    	mov    0xf017bf80,%ebx
f0100c56:	ba 00 00 00 00       	mov    $0x0,%edx
f0100c5b:	b8 01 00 00 00       	mov    $0x1,%eax
f0100c60:	eb 27                	jmp    f0100c89 <page_init+0x44>
		pages[i].pp_ref = 0;
f0100c62:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f0100c69:	89 d1                	mov    %edx,%ecx
f0100c6b:	03 0d 4c cc 17 f0    	add    0xf017cc4c,%ecx
f0100c71:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100c77:	89 19                	mov    %ebx,(%ecx)
	// free pages!
	size_t i;
	int keriolim=0;
	//cprintf("npages=%d\n",npages);
	//cprintf("npages_basemem=%d\n",npages_basemem);
	for (i = 1; i < npages_basemem; i++) {
f0100c79:	83 c0 01             	add    $0x1,%eax
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
f0100c7c:	89 d3                	mov    %edx,%ebx
f0100c7e:	03 1d 4c cc 17 f0    	add    0xf017cc4c,%ebx
f0100c84:	ba 01 00 00 00       	mov    $0x1,%edx
	// free pages!
	size_t i;
	int keriolim=0;
	//cprintf("npages=%d\n",npages);
	//cprintf("npages_basemem=%d\n",npages_basemem);
	for (i = 1; i < npages_basemem; i++) {
f0100c89:	39 f0                	cmp    %esi,%eax
f0100c8b:	72 d5                	jb     f0100c62 <page_init+0x1d>
f0100c8d:	84 d2                	test   %dl,%dl
f0100c8f:	74 06                	je     f0100c97 <page_init+0x52>
f0100c91:	89 1d 80 bf 17 f0    	mov    %ebx,0xf017bf80
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
	
	keriolim = (int)ROUNDUP(((char*)envs) + (sizeof(struct Env) * NENV) - KERNBASE, PGSIZE)/PGSIZE;
f0100c97:	a1 8c bf 17 f0       	mov    0xf017bf8c,%eax
f0100c9c:	05 ff 8f 01 10       	add    $0x10018fff,%eax
	//cprintf("keriolim=%d\n",keriolim);
	for (i = keriolim; i < npages; i++) {
f0100ca1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100ca6:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0100cac:	85 c0                	test   %eax,%eax
f0100cae:	0f 48 c2             	cmovs  %edx,%eax
f0100cb1:	c1 f8 0c             	sar    $0xc,%eax
f0100cb4:	89 c2                	mov    %eax,%edx
f0100cb6:	8b 1d 80 bf 17 f0    	mov    0xf017bf80,%ebx
f0100cbc:	c1 e0 03             	shl    $0x3,%eax
f0100cbf:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100cc4:	eb 23                	jmp    f0100ce9 <page_init+0xa4>
		pages[i].pp_ref = 0;
f0100cc6:	89 c1                	mov    %eax,%ecx
f0100cc8:	03 0d 4c cc 17 f0    	add    0xf017cc4c,%ecx
f0100cce:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100cd4:	89 19                	mov    %ebx,(%ecx)
		page_free_list = &pages[i];
f0100cd6:	89 c3                	mov    %eax,%ebx
f0100cd8:	03 1d 4c cc 17 f0    	add    0xf017cc4c,%ebx
		page_free_list = &pages[i];
	}
	
	keriolim = (int)ROUNDUP(((char*)envs) + (sizeof(struct Env) * NENV) - KERNBASE, PGSIZE)/PGSIZE;
	//cprintf("keriolim=%d\n",keriolim);
	for (i = keriolim; i < npages; i++) {
f0100cde:	83 c2 01             	add    $0x1,%edx
f0100ce1:	83 c0 08             	add    $0x8,%eax
f0100ce4:	b9 01 00 00 00       	mov    $0x1,%ecx
f0100ce9:	3b 15 44 cc 17 f0    	cmp    0xf017cc44,%edx
f0100cef:	72 d5                	jb     f0100cc6 <page_init+0x81>
f0100cf1:	84 c9                	test   %cl,%cl
f0100cf3:	74 06                	je     f0100cfb <page_init+0xb6>
f0100cf5:	89 1d 80 bf 17 f0    	mov    %ebx,0xf017bf80
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}

}
f0100cfb:	5b                   	pop    %ebx
f0100cfc:	5e                   	pop    %esi
f0100cfd:	5d                   	pop    %ebp
f0100cfe:	c3                   	ret    

f0100cff <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100cff:	55                   	push   %ebp
f0100d00:	89 e5                	mov    %esp,%ebp
f0100d02:	53                   	push   %ebx
f0100d03:	83 ec 04             	sub    $0x4,%esp
	if(page_free_list != 0){
f0100d06:	8b 1d 80 bf 17 f0    	mov    0xf017bf80,%ebx
f0100d0c:	85 db                	test   %ebx,%ebx
f0100d0e:	74 58                	je     f0100d68 <page_alloc+0x69>
		struct PageInfo *result = page_free_list;
		page_free_list = page_free_list -> pp_link;
f0100d10:	8b 03                	mov    (%ebx),%eax
f0100d12:	a3 80 bf 17 f0       	mov    %eax,0xf017bf80
		if(alloc_flags & ALLOC_ZERO)
f0100d17:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100d1b:	74 45                	je     f0100d62 <page_alloc+0x63>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100d1d:	89 d8                	mov    %ebx,%eax
f0100d1f:	2b 05 4c cc 17 f0    	sub    0xf017cc4c,%eax
f0100d25:	c1 f8 03             	sar    $0x3,%eax
f0100d28:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100d2b:	89 c2                	mov    %eax,%edx
f0100d2d:	c1 ea 0c             	shr    $0xc,%edx
f0100d30:	3b 15 44 cc 17 f0    	cmp    0xf017cc44,%edx
f0100d36:	72 12                	jb     f0100d4a <page_alloc+0x4b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d38:	50                   	push   %eax
f0100d39:	68 84 4c 10 f0       	push   $0xf0104c84
f0100d3e:	6a 56                	push   $0x56
f0100d40:	68 4d 54 10 f0       	push   $0xf010544d
f0100d45:	e8 56 f3 ff ff       	call   f01000a0 <_panic>
			memset(page2kva(result), 0 , PGSIZE);
f0100d4a:	83 ec 04             	sub    $0x4,%esp
f0100d4d:	68 00 10 00 00       	push   $0x1000
f0100d52:	6a 00                	push   $0x0
f0100d54:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100d59:	50                   	push   %eax
f0100d5a:	e8 43 35 00 00       	call   f01042a2 <memset>
f0100d5f:	83 c4 10             	add    $0x10,%esp
		result->pp_link = NULL;
f0100d62:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
		return result;
	}
	else
		return NULL;
}
f0100d68:	89 d8                	mov    %ebx,%eax
f0100d6a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100d6d:	c9                   	leave  
f0100d6e:	c3                   	ret    

f0100d6f <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100d6f:	55                   	push   %ebp
f0100d70:	89 e5                	mov    %esp,%ebp
f0100d72:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	
	pp->pp_link = page_free_list;
f0100d75:	8b 15 80 bf 17 f0    	mov    0xf017bf80,%edx
f0100d7b:	89 10                	mov    %edx,(%eax)
    	page_free_list = pp;
f0100d7d:	a3 80 bf 17 f0       	mov    %eax,0xf017bf80
}
f0100d82:	5d                   	pop    %ebp
f0100d83:	c3                   	ret    

f0100d84 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100d84:	55                   	push   %ebp
f0100d85:	89 e5                	mov    %esp,%ebp
f0100d87:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100d8a:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100d8e:	83 e8 01             	sub    $0x1,%eax
f0100d91:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100d95:	66 85 c0             	test   %ax,%ax
f0100d98:	75 09                	jne    f0100da3 <page_decref+0x1f>
		page_free(pp);
f0100d9a:	52                   	push   %edx
f0100d9b:	e8 cf ff ff ff       	call   f0100d6f <page_free>
f0100da0:	83 c4 04             	add    $0x4,%esp
}
f0100da3:	c9                   	leave  
f0100da4:	c3                   	ret    

f0100da5 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100da5:	55                   	push   %ebp
f0100da6:	89 e5                	mov    %esp,%ebp
f0100da8:	56                   	push   %esi
f0100da9:	53                   	push   %ebx
f0100daa:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	struct PageInfo *outpg;
	pte_t *pgt;
	size_t pdi= PDX(va);
	pde_t pde= pgdir[pdi];
f0100dad:	89 de                	mov    %ebx,%esi
f0100daf:	c1 ee 16             	shr    $0x16,%esi
f0100db2:	c1 e6 02             	shl    $0x2,%esi
f0100db5:	03 75 08             	add    0x8(%ebp),%esi
f0100db8:	8b 16                	mov    (%esi),%edx
	if((pde & PTE_P)!=0)
f0100dba:	f6 c2 01             	test   $0x1,%dl
f0100dbd:	74 30                	je     f0100def <pgdir_walk+0x4a>
	{
		pgt=KADDR(PTE_ADDR(pde));
f0100dbf:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100dc5:	89 d0                	mov    %edx,%eax
f0100dc7:	c1 e8 0c             	shr    $0xc,%eax
f0100dca:	39 05 44 cc 17 f0    	cmp    %eax,0xf017cc44
f0100dd0:	77 15                	ja     f0100de7 <pgdir_walk+0x42>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100dd2:	52                   	push   %edx
f0100dd3:	68 84 4c 10 f0       	push   $0xf0104c84
f0100dd8:	68 7f 01 00 00       	push   $0x17f
f0100ddd:	68 41 54 10 f0       	push   $0xf0105441
f0100de2:	e8 b9 f2 ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f0100de7:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0100ded:	eb 60                	jmp    f0100e4f <pgdir_walk+0xaa>
	}
	else
	{
		if(!create)
f0100def:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100df3:	74 68                	je     f0100e5d <pgdir_walk+0xb8>
		{
			return NULL;
		}
		
		outpg=page_alloc(ALLOC_ZERO);
f0100df5:	83 ec 0c             	sub    $0xc,%esp
f0100df8:	6a 01                	push   $0x1
f0100dfa:	e8 00 ff ff ff       	call   f0100cff <page_alloc>
		
		if(!outpg)
f0100dff:	83 c4 10             	add    $0x10,%esp
f0100e02:	85 c0                	test   %eax,%eax
f0100e04:	74 5e                	je     f0100e64 <pgdir_walk+0xbf>
		{
			return NULL;
		
		}
		
		pgdir[pdi]=page2pa(outpg) |PTE_U |PTE_W|PTE_P;
f0100e06:	89 c2                	mov    %eax,%edx
f0100e08:	2b 15 4c cc 17 f0    	sub    0xf017cc4c,%edx
f0100e0e:	c1 fa 03             	sar    $0x3,%edx
f0100e11:	c1 e2 0c             	shl    $0xc,%edx
f0100e14:	83 ca 07             	or     $0x7,%edx
f0100e17:	89 16                	mov    %edx,(%esi)
		outpg->pp_ref++;
f0100e19:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100e1e:	2b 05 4c cc 17 f0    	sub    0xf017cc4c,%eax
f0100e24:	c1 f8 03             	sar    $0x3,%eax
f0100e27:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e2a:	89 c2                	mov    %eax,%edx
f0100e2c:	c1 ea 0c             	shr    $0xc,%edx
f0100e2f:	3b 15 44 cc 17 f0    	cmp    0xf017cc44,%edx
f0100e35:	72 12                	jb     f0100e49 <pgdir_walk+0xa4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e37:	50                   	push   %eax
f0100e38:	68 84 4c 10 f0       	push   $0xf0104c84
f0100e3d:	6a 56                	push   $0x56
f0100e3f:	68 4d 54 10 f0       	push   $0xf010544d
f0100e44:	e8 57 f2 ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f0100e49:	8d 90 00 00 00 f0    	lea    -0x10000000(%eax),%edx
			
	
	}
	size_t pti = PTX(va);
	
	return &pgt[pti];
f0100e4f:	c1 eb 0a             	shr    $0xa,%ebx
f0100e52:	81 e3 fc 0f 00 00    	and    $0xffc,%ebx
f0100e58:	8d 04 1a             	lea    (%edx,%ebx,1),%eax
f0100e5b:	eb 0c                	jmp    f0100e69 <pgdir_walk+0xc4>
	}
	else
	{
		if(!create)
		{
			return NULL;
f0100e5d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e62:	eb 05                	jmp    f0100e69 <pgdir_walk+0xc4>
		
		outpg=page_alloc(ALLOC_ZERO);
		
		if(!outpg)
		{
			return NULL;
f0100e64:	b8 00 00 00 00       	mov    $0x0,%eax
	
	}
	size_t pti = PTX(va);
	
	return &pgt[pti];
}
f0100e69:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100e6c:	5b                   	pop    %ebx
f0100e6d:	5e                   	pop    %esi
f0100e6e:	5d                   	pop    %ebp
f0100e6f:	c3                   	ret    

f0100e70 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0100e70:	55                   	push   %ebp
f0100e71:	89 e5                	mov    %esp,%ebp
f0100e73:	57                   	push   %edi
f0100e74:	56                   	push   %esi
f0100e75:	53                   	push   %ebx
f0100e76:	83 ec 1c             	sub    $0x1c,%esp
f0100e79:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100e7c:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0100e82:	8d 04 11             	lea    (%ecx,%edx,1),%eax
f0100e85:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	//cprintf("%x\n",size);
	while (size >= PGSIZE) {
f0100e88:	89 d3                	mov    %edx,%ebx
f0100e8a:	8b 7d 08             	mov    0x8(%ebp),%edi
f0100e8d:	29 d7                	sub    %edx,%edi
		pte_t *pte = pgdir_walk(pgdir, (void *)va, 1);

		*pte = pa | perm | PTE_P;
f0100e8f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e92:	83 c8 01             	or     $0x1,%eax
f0100e95:	89 45 dc             	mov    %eax,-0x24(%ebp)
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	//cprintf("%x\n",size);
	while (size >= PGSIZE) {
f0100e98:	eb 1c                	jmp    f0100eb6 <boot_map_region+0x46>
		pte_t *pte = pgdir_walk(pgdir, (void *)va, 1);
f0100e9a:	83 ec 04             	sub    $0x4,%esp
f0100e9d:	6a 01                	push   $0x1
f0100e9f:	53                   	push   %ebx
f0100ea0:	ff 75 e0             	pushl  -0x20(%ebp)
f0100ea3:	e8 fd fe ff ff       	call   f0100da5 <pgdir_walk>

		*pte = pa | perm | PTE_P;
f0100ea8:	0b 75 dc             	or     -0x24(%ebp),%esi
f0100eab:	89 30                	mov    %esi,(%eax)

		va += PGSIZE;
f0100ead:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0100eb3:	83 c4 10             	add    $0x10,%esp
f0100eb6:	8d 34 1f             	lea    (%edi,%ebx,1),%esi
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	//cprintf("%x\n",size);
	while (size >= PGSIZE) {
f0100eb9:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f0100ebc:	75 dc                	jne    f0100e9a <boot_map_region+0x2a>

		va += PGSIZE;
		pa += PGSIZE;
		size -= PGSIZE;
	}
}
f0100ebe:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100ec1:	5b                   	pop    %ebx
f0100ec2:	5e                   	pop    %esi
f0100ec3:	5f                   	pop    %edi
f0100ec4:	5d                   	pop    %ebp
f0100ec5:	c3                   	ret    

f0100ec6 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100ec6:	55                   	push   %ebp
f0100ec7:	89 e5                	mov    %esp,%ebp
f0100ec9:	56                   	push   %esi
f0100eca:	53                   	push   %ebx
f0100ecb:	8b 45 08             	mov    0x8(%ebp),%eax
f0100ece:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100ed1:	8b 5d 10             	mov    0x10(%ebp),%ebx
	size_t pdi= PDX(va);
	pde_t pde= pgdir[pdi];
f0100ed4:	89 d1                	mov    %edx,%ecx
f0100ed6:	c1 e9 16             	shr    $0x16,%ecx
f0100ed9:	8b 34 88             	mov    (%eax,%ecx,4),%esi
	pte_t *pte = pgdir_walk(pgdir, va, 0);
f0100edc:	83 ec 04             	sub    $0x4,%esp
f0100edf:	6a 00                	push   $0x0
f0100ee1:	52                   	push   %edx
f0100ee2:	50                   	push   %eax
f0100ee3:	e8 bd fe ff ff       	call   f0100da5 <pgdir_walk>
	if((pde & PTE_P)==0)
f0100ee8:	83 c4 10             	add    $0x10,%esp
f0100eeb:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0100ef1:	74 32                	je     f0100f25 <page_lookup+0x5f>
	{
		return NULL;
	}
	else if(pte_store)
f0100ef3:	85 db                	test   %ebx,%ebx
f0100ef5:	74 02                	je     f0100ef9 <page_lookup+0x33>
		*pte_store= pte;
f0100ef7:	89 03                	mov    %eax,(%ebx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ef9:	8b 00                	mov    (%eax),%eax
f0100efb:	c1 e8 0c             	shr    $0xc,%eax
f0100efe:	3b 05 44 cc 17 f0    	cmp    0xf017cc44,%eax
f0100f04:	72 14                	jb     f0100f1a <page_lookup+0x54>
		panic("pa2page called with invalid pa");
f0100f06:	83 ec 04             	sub    $0x4,%esp
f0100f09:	68 6c 4d 10 f0       	push   $0xf0104d6c
f0100f0e:	6a 4f                	push   $0x4f
f0100f10:	68 4d 54 10 f0       	push   $0xf010544d
f0100f15:	e8 86 f1 ff ff       	call   f01000a0 <_panic>
	return &pages[PGNUM(pa)];
f0100f1a:	8b 15 4c cc 17 f0    	mov    0xf017cc4c,%edx
f0100f20:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	
	return pa2page(PTE_ADDR(*pte));
f0100f23:	eb 05                	jmp    f0100f2a <page_lookup+0x64>
	size_t pdi= PDX(va);
	pde_t pde= pgdir[pdi];
	pte_t *pte = pgdir_walk(pgdir, va, 0);
	if((pde & PTE_P)==0)
	{
		return NULL;
f0100f25:	b8 00 00 00 00       	mov    $0x0,%eax
	}
	else if(pte_store)
		*pte_store= pte;
	
	return pa2page(PTE_ADDR(*pte));
}
f0100f2a:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100f2d:	5b                   	pop    %ebx
f0100f2e:	5e                   	pop    %esi
f0100f2f:	5d                   	pop    %ebp
f0100f30:	c3                   	ret    

f0100f31 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0100f31:	55                   	push   %ebp
f0100f32:	89 e5                	mov    %esp,%ebp
f0100f34:	53                   	push   %ebx
f0100f35:	83 ec 18             	sub    $0x18,%esp
f0100f38:	8b 5d 0c             	mov    0xc(%ebp),%ebx
		
	pte_t *pst;
	struct PageInfo *page=page_lookup(pgdir,va,&pst);
f0100f3b:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100f3e:	50                   	push   %eax
f0100f3f:	53                   	push   %ebx
f0100f40:	ff 75 08             	pushl  0x8(%ebp)
f0100f43:	e8 7e ff ff ff       	call   f0100ec6 <page_lookup>
	if(!page || !(*pst & PTE_P))
f0100f48:	83 c4 10             	add    $0x10,%esp
f0100f4b:	85 c0                	test   %eax,%eax
f0100f4d:	74 20                	je     f0100f6f <page_remove+0x3e>
f0100f4f:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0100f52:	f6 02 01             	testb  $0x1,(%edx)
f0100f55:	74 18                	je     f0100f6f <page_remove+0x3e>
	{
		return;
	}
	
	
	page_decref(page);
f0100f57:	83 ec 0c             	sub    $0xc,%esp
f0100f5a:	50                   	push   %eax
f0100f5b:	e8 24 fe ff ff       	call   f0100d84 <page_decref>
	*pst = 0;
f0100f60:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100f63:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100f69:	0f 01 3b             	invlpg (%ebx)
f0100f6c:	83 c4 10             	add    $0x10,%esp
	tlb_invalidate(pgdir,va);
	
	
}
f0100f6f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100f72:	c9                   	leave  
f0100f73:	c3                   	ret    

f0100f74 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0100f74:	55                   	push   %ebp
f0100f75:	89 e5                	mov    %esp,%ebp
f0100f77:	57                   	push   %edi
f0100f78:	56                   	push   %esi
f0100f79:	53                   	push   %ebx
f0100f7a:	83 ec 10             	sub    $0x10,%esp
f0100f7d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100f80:	8b 7d 10             	mov    0x10(%ebp),%edi
	pte_t *pst;
	pst = pgdir_walk(pgdir, va, 1);
f0100f83:	6a 01                	push   $0x1
f0100f85:	57                   	push   %edi
f0100f86:	ff 75 08             	pushl  0x8(%ebp)
f0100f89:	e8 17 fe ff ff       	call   f0100da5 <pgdir_walk>
	if(!pst)
f0100f8e:	83 c4 10             	add    $0x10,%esp
f0100f91:	85 c0                	test   %eax,%eax
f0100f93:	74 38                	je     f0100fcd <page_insert+0x59>
f0100f95:	89 c6                	mov    %eax,%esi
		return -E_NO_MEM;
	pp->pp_ref++;
f0100f97:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	if(*pst & PTE_P)
f0100f9c:	f6 00 01             	testb  $0x1,(%eax)
f0100f9f:	74 0f                	je     f0100fb0 <page_insert+0x3c>
	{
		page_remove(pgdir, va);
f0100fa1:	83 ec 08             	sub    $0x8,%esp
f0100fa4:	57                   	push   %edi
f0100fa5:	ff 75 08             	pushl  0x8(%ebp)
f0100fa8:	e8 84 ff ff ff       	call   f0100f31 <page_remove>
f0100fad:	83 c4 10             	add    $0x10,%esp
	}
	
	*pst=page2pa(pp) | perm |PTE_P;	
f0100fb0:	2b 1d 4c cc 17 f0    	sub    0xf017cc4c,%ebx
f0100fb6:	c1 fb 03             	sar    $0x3,%ebx
f0100fb9:	c1 e3 0c             	shl    $0xc,%ebx
f0100fbc:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fbf:	83 c8 01             	or     $0x1,%eax
f0100fc2:	09 c3                	or     %eax,%ebx
f0100fc4:	89 1e                	mov    %ebx,(%esi)
	return 0;
f0100fc6:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fcb:	eb 05                	jmp    f0100fd2 <page_insert+0x5e>
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
	pte_t *pst;
	pst = pgdir_walk(pgdir, va, 1);
	if(!pst)
		return -E_NO_MEM;
f0100fcd:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
		page_remove(pgdir, va);
	}
	
	*pst=page2pa(pp) | perm |PTE_P;	
	return 0;
}
f0100fd2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100fd5:	5b                   	pop    %ebx
f0100fd6:	5e                   	pop    %esi
f0100fd7:	5f                   	pop    %edi
f0100fd8:	5d                   	pop    %ebp
f0100fd9:	c3                   	ret    

f0100fda <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0100fda:	55                   	push   %ebp
f0100fdb:	89 e5                	mov    %esp,%ebp
f0100fdd:	57                   	push   %edi
f0100fde:	56                   	push   %esi
f0100fdf:	53                   	push   %ebx
f0100fe0:	83 ec 38             	sub    $0x38,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100fe3:	6a 15                	push   $0x15
f0100fe5:	e8 58 1e 00 00       	call   f0102e42 <mc146818_read>
f0100fea:	89 c3                	mov    %eax,%ebx
f0100fec:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f0100ff3:	e8 4a 1e 00 00       	call   f0102e42 <mc146818_read>
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f0100ff8:	c1 e0 08             	shl    $0x8,%eax
f0100ffb:	09 d8                	or     %ebx,%eax
f0100ffd:	c1 e0 0a             	shl    $0xa,%eax
f0101000:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101006:	85 c0                	test   %eax,%eax
f0101008:	0f 48 c2             	cmovs  %edx,%eax
f010100b:	c1 f8 0c             	sar    $0xc,%eax
f010100e:	a3 84 bf 17 f0       	mov    %eax,0xf017bf84
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101013:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f010101a:	e8 23 1e 00 00       	call   f0102e42 <mc146818_read>
f010101f:	89 c3                	mov    %eax,%ebx
f0101021:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f0101028:	e8 15 1e 00 00       	call   f0102e42 <mc146818_read>
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f010102d:	c1 e0 08             	shl    $0x8,%eax
f0101030:	09 d8                	or     %ebx,%eax
f0101032:	c1 e0 0a             	shl    $0xa,%eax
f0101035:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f010103b:	83 c4 10             	add    $0x10,%esp
f010103e:	85 c0                	test   %eax,%eax
f0101040:	0f 48 c2             	cmovs  %edx,%eax
f0101043:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f0101046:	85 c0                	test   %eax,%eax
f0101048:	74 0e                	je     f0101058 <mem_init+0x7e>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f010104a:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f0101050:	89 15 44 cc 17 f0    	mov    %edx,0xf017cc44
f0101056:	eb 0c                	jmp    f0101064 <mem_init+0x8a>
	else
		npages = npages_basemem;
f0101058:	8b 15 84 bf 17 f0    	mov    0xf017bf84,%edx
f010105e:	89 15 44 cc 17 f0    	mov    %edx,0xf017cc44

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101064:	c1 e0 0c             	shl    $0xc,%eax
f0101067:	c1 e8 0a             	shr    $0xa,%eax
f010106a:	50                   	push   %eax
f010106b:	a1 84 bf 17 f0       	mov    0xf017bf84,%eax
f0101070:	c1 e0 0c             	shl    $0xc,%eax
f0101073:	c1 e8 0a             	shr    $0xa,%eax
f0101076:	50                   	push   %eax
f0101077:	a1 44 cc 17 f0       	mov    0xf017cc44,%eax
f010107c:	c1 e0 0c             	shl    $0xc,%eax
f010107f:	c1 e8 0a             	shr    $0xa,%eax
f0101082:	50                   	push   %eax
f0101083:	68 8c 4d 10 f0       	push   $0xf0104d8c
f0101088:	e8 1c 1e 00 00       	call   f0102ea9 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f010108d:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101092:	e8 5c f8 ff ff       	call   f01008f3 <boot_alloc>
f0101097:	a3 48 cc 17 f0       	mov    %eax,0xf017cc48
	memset(kern_pgdir, 0, PGSIZE);
f010109c:	83 c4 0c             	add    $0xc,%esp
f010109f:	68 00 10 00 00       	push   $0x1000
f01010a4:	6a 00                	push   $0x0
f01010a6:	50                   	push   %eax
f01010a7:	e8 f6 31 00 00       	call   f01042a2 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01010ac:	a1 48 cc 17 f0       	mov    0xf017cc48,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01010b1:	83 c4 10             	add    $0x10,%esp
f01010b4:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01010b9:	77 15                	ja     f01010d0 <mem_init+0xf6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01010bb:	50                   	push   %eax
f01010bc:	68 c8 4d 10 f0       	push   $0xf0104dc8
f01010c1:	68 93 00 00 00       	push   $0x93
f01010c6:	68 41 54 10 f0       	push   $0xf0105441
f01010cb:	e8 d0 ef ff ff       	call   f01000a0 <_panic>
f01010d0:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01010d6:	83 ca 05             	or     $0x5,%edx
f01010d9:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages = (struct PageInfo *)boot_alloc(npages * sizeof(struct PageInfo));
f01010df:	a1 44 cc 17 f0       	mov    0xf017cc44,%eax
f01010e4:	c1 e0 03             	shl    $0x3,%eax
f01010e7:	e8 07 f8 ff ff       	call   f01008f3 <boot_alloc>
f01010ec:	a3 4c cc 17 f0       	mov    %eax,0xf017cc4c
	memset(pages, 0, npages * sizeof(struct PageInfo));
f01010f1:	83 ec 04             	sub    $0x4,%esp
f01010f4:	8b 3d 44 cc 17 f0    	mov    0xf017cc44,%edi
f01010fa:	8d 14 fd 00 00 00 00 	lea    0x0(,%edi,8),%edx
f0101101:	52                   	push   %edx
f0101102:	6a 00                	push   $0x0
f0101104:	50                   	push   %eax
f0101105:	e8 98 31 00 00       	call   f01042a2 <memset>
	envs = (struct Env *) boot_alloc(sizeof(struct Env) * NENV);
f010110a:	b8 00 80 01 00       	mov    $0x18000,%eax
f010110f:	e8 df f7 ff ff       	call   f01008f3 <boot_alloc>
f0101114:	a3 8c bf 17 f0       	mov    %eax,0xf017bf8c
	memset(envs, 0, NENV * sizeof(struct Env));
f0101119:	83 c4 0c             	add    $0xc,%esp
f010111c:	68 00 80 01 00       	push   $0x18000
f0101121:	6a 00                	push   $0x0
f0101123:	50                   	push   %eax
f0101124:	e8 79 31 00 00       	call   f01042a2 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101129:	e8 17 fb ff ff       	call   f0100c45 <page_init>

	check_page_free_list(1);
f010112e:	b8 01 00 00 00       	mov    $0x1,%eax
f0101133:	e8 59 f8 ff ff       	call   f0100991 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0101138:	83 c4 10             	add    $0x10,%esp
f010113b:	83 3d 4c cc 17 f0 00 	cmpl   $0x0,0xf017cc4c
f0101142:	75 17                	jne    f010115b <mem_init+0x181>
		panic("'pages' is a null pointer!");
f0101144:	83 ec 04             	sub    $0x4,%esp
f0101147:	68 f7 54 10 f0       	push   $0xf01054f7
f010114c:	68 bb 02 00 00       	push   $0x2bb
f0101151:	68 41 54 10 f0       	push   $0xf0105441
f0101156:	e8 45 ef ff ff       	call   f01000a0 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010115b:	a1 80 bf 17 f0       	mov    0xf017bf80,%eax
f0101160:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101165:	eb 05                	jmp    f010116c <mem_init+0x192>
		++nfree;
f0101167:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010116a:	8b 00                	mov    (%eax),%eax
f010116c:	85 c0                	test   %eax,%eax
f010116e:	75 f7                	jne    f0101167 <mem_init+0x18d>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101170:	83 ec 0c             	sub    $0xc,%esp
f0101173:	6a 00                	push   $0x0
f0101175:	e8 85 fb ff ff       	call   f0100cff <page_alloc>
f010117a:	89 c7                	mov    %eax,%edi
f010117c:	83 c4 10             	add    $0x10,%esp
f010117f:	85 c0                	test   %eax,%eax
f0101181:	75 19                	jne    f010119c <mem_init+0x1c2>
f0101183:	68 12 55 10 f0       	push   $0xf0105512
f0101188:	68 67 54 10 f0       	push   $0xf0105467
f010118d:	68 c3 02 00 00       	push   $0x2c3
f0101192:	68 41 54 10 f0       	push   $0xf0105441
f0101197:	e8 04 ef ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f010119c:	83 ec 0c             	sub    $0xc,%esp
f010119f:	6a 00                	push   $0x0
f01011a1:	e8 59 fb ff ff       	call   f0100cff <page_alloc>
f01011a6:	89 c6                	mov    %eax,%esi
f01011a8:	83 c4 10             	add    $0x10,%esp
f01011ab:	85 c0                	test   %eax,%eax
f01011ad:	75 19                	jne    f01011c8 <mem_init+0x1ee>
f01011af:	68 28 55 10 f0       	push   $0xf0105528
f01011b4:	68 67 54 10 f0       	push   $0xf0105467
f01011b9:	68 c4 02 00 00       	push   $0x2c4
f01011be:	68 41 54 10 f0       	push   $0xf0105441
f01011c3:	e8 d8 ee ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f01011c8:	83 ec 0c             	sub    $0xc,%esp
f01011cb:	6a 00                	push   $0x0
f01011cd:	e8 2d fb ff ff       	call   f0100cff <page_alloc>
f01011d2:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01011d5:	83 c4 10             	add    $0x10,%esp
f01011d8:	85 c0                	test   %eax,%eax
f01011da:	75 19                	jne    f01011f5 <mem_init+0x21b>
f01011dc:	68 3e 55 10 f0       	push   $0xf010553e
f01011e1:	68 67 54 10 f0       	push   $0xf0105467
f01011e6:	68 c5 02 00 00       	push   $0x2c5
f01011eb:	68 41 54 10 f0       	push   $0xf0105441
f01011f0:	e8 ab ee ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01011f5:	39 f7                	cmp    %esi,%edi
f01011f7:	75 19                	jne    f0101212 <mem_init+0x238>
f01011f9:	68 54 55 10 f0       	push   $0xf0105554
f01011fe:	68 67 54 10 f0       	push   $0xf0105467
f0101203:	68 c8 02 00 00       	push   $0x2c8
f0101208:	68 41 54 10 f0       	push   $0xf0105441
f010120d:	e8 8e ee ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101212:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101215:	39 c6                	cmp    %eax,%esi
f0101217:	74 04                	je     f010121d <mem_init+0x243>
f0101219:	39 c7                	cmp    %eax,%edi
f010121b:	75 19                	jne    f0101236 <mem_init+0x25c>
f010121d:	68 ec 4d 10 f0       	push   $0xf0104dec
f0101222:	68 67 54 10 f0       	push   $0xf0105467
f0101227:	68 c9 02 00 00       	push   $0x2c9
f010122c:	68 41 54 10 f0       	push   $0xf0105441
f0101231:	e8 6a ee ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101236:	8b 0d 4c cc 17 f0    	mov    0xf017cc4c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f010123c:	8b 15 44 cc 17 f0    	mov    0xf017cc44,%edx
f0101242:	c1 e2 0c             	shl    $0xc,%edx
f0101245:	89 f8                	mov    %edi,%eax
f0101247:	29 c8                	sub    %ecx,%eax
f0101249:	c1 f8 03             	sar    $0x3,%eax
f010124c:	c1 e0 0c             	shl    $0xc,%eax
f010124f:	39 d0                	cmp    %edx,%eax
f0101251:	72 19                	jb     f010126c <mem_init+0x292>
f0101253:	68 66 55 10 f0       	push   $0xf0105566
f0101258:	68 67 54 10 f0       	push   $0xf0105467
f010125d:	68 ca 02 00 00       	push   $0x2ca
f0101262:	68 41 54 10 f0       	push   $0xf0105441
f0101267:	e8 34 ee ff ff       	call   f01000a0 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f010126c:	89 f0                	mov    %esi,%eax
f010126e:	29 c8                	sub    %ecx,%eax
f0101270:	c1 f8 03             	sar    $0x3,%eax
f0101273:	c1 e0 0c             	shl    $0xc,%eax
f0101276:	39 c2                	cmp    %eax,%edx
f0101278:	77 19                	ja     f0101293 <mem_init+0x2b9>
f010127a:	68 83 55 10 f0       	push   $0xf0105583
f010127f:	68 67 54 10 f0       	push   $0xf0105467
f0101284:	68 cb 02 00 00       	push   $0x2cb
f0101289:	68 41 54 10 f0       	push   $0xf0105441
f010128e:	e8 0d ee ff ff       	call   f01000a0 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f0101293:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101296:	29 c8                	sub    %ecx,%eax
f0101298:	c1 f8 03             	sar    $0x3,%eax
f010129b:	c1 e0 0c             	shl    $0xc,%eax
f010129e:	39 c2                	cmp    %eax,%edx
f01012a0:	77 19                	ja     f01012bb <mem_init+0x2e1>
f01012a2:	68 a0 55 10 f0       	push   $0xf01055a0
f01012a7:	68 67 54 10 f0       	push   $0xf0105467
f01012ac:	68 cc 02 00 00       	push   $0x2cc
f01012b1:	68 41 54 10 f0       	push   $0xf0105441
f01012b6:	e8 e5 ed ff ff       	call   f01000a0 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01012bb:	a1 80 bf 17 f0       	mov    0xf017bf80,%eax
f01012c0:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01012c3:	c7 05 80 bf 17 f0 00 	movl   $0x0,0xf017bf80
f01012ca:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01012cd:	83 ec 0c             	sub    $0xc,%esp
f01012d0:	6a 00                	push   $0x0
f01012d2:	e8 28 fa ff ff       	call   f0100cff <page_alloc>
f01012d7:	83 c4 10             	add    $0x10,%esp
f01012da:	85 c0                	test   %eax,%eax
f01012dc:	74 19                	je     f01012f7 <mem_init+0x31d>
f01012de:	68 bd 55 10 f0       	push   $0xf01055bd
f01012e3:	68 67 54 10 f0       	push   $0xf0105467
f01012e8:	68 d3 02 00 00       	push   $0x2d3
f01012ed:	68 41 54 10 f0       	push   $0xf0105441
f01012f2:	e8 a9 ed ff ff       	call   f01000a0 <_panic>

	// free and re-allocate?
	page_free(pp0);
f01012f7:	83 ec 0c             	sub    $0xc,%esp
f01012fa:	57                   	push   %edi
f01012fb:	e8 6f fa ff ff       	call   f0100d6f <page_free>
	page_free(pp1);
f0101300:	89 34 24             	mov    %esi,(%esp)
f0101303:	e8 67 fa ff ff       	call   f0100d6f <page_free>
	page_free(pp2);
f0101308:	83 c4 04             	add    $0x4,%esp
f010130b:	ff 75 d4             	pushl  -0x2c(%ebp)
f010130e:	e8 5c fa ff ff       	call   f0100d6f <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101313:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010131a:	e8 e0 f9 ff ff       	call   f0100cff <page_alloc>
f010131f:	89 c6                	mov    %eax,%esi
f0101321:	83 c4 10             	add    $0x10,%esp
f0101324:	85 c0                	test   %eax,%eax
f0101326:	75 19                	jne    f0101341 <mem_init+0x367>
f0101328:	68 12 55 10 f0       	push   $0xf0105512
f010132d:	68 67 54 10 f0       	push   $0xf0105467
f0101332:	68 da 02 00 00       	push   $0x2da
f0101337:	68 41 54 10 f0       	push   $0xf0105441
f010133c:	e8 5f ed ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f0101341:	83 ec 0c             	sub    $0xc,%esp
f0101344:	6a 00                	push   $0x0
f0101346:	e8 b4 f9 ff ff       	call   f0100cff <page_alloc>
f010134b:	89 c7                	mov    %eax,%edi
f010134d:	83 c4 10             	add    $0x10,%esp
f0101350:	85 c0                	test   %eax,%eax
f0101352:	75 19                	jne    f010136d <mem_init+0x393>
f0101354:	68 28 55 10 f0       	push   $0xf0105528
f0101359:	68 67 54 10 f0       	push   $0xf0105467
f010135e:	68 db 02 00 00       	push   $0x2db
f0101363:	68 41 54 10 f0       	push   $0xf0105441
f0101368:	e8 33 ed ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f010136d:	83 ec 0c             	sub    $0xc,%esp
f0101370:	6a 00                	push   $0x0
f0101372:	e8 88 f9 ff ff       	call   f0100cff <page_alloc>
f0101377:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010137a:	83 c4 10             	add    $0x10,%esp
f010137d:	85 c0                	test   %eax,%eax
f010137f:	75 19                	jne    f010139a <mem_init+0x3c0>
f0101381:	68 3e 55 10 f0       	push   $0xf010553e
f0101386:	68 67 54 10 f0       	push   $0xf0105467
f010138b:	68 dc 02 00 00       	push   $0x2dc
f0101390:	68 41 54 10 f0       	push   $0xf0105441
f0101395:	e8 06 ed ff ff       	call   f01000a0 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010139a:	39 fe                	cmp    %edi,%esi
f010139c:	75 19                	jne    f01013b7 <mem_init+0x3dd>
f010139e:	68 54 55 10 f0       	push   $0xf0105554
f01013a3:	68 67 54 10 f0       	push   $0xf0105467
f01013a8:	68 de 02 00 00       	push   $0x2de
f01013ad:	68 41 54 10 f0       	push   $0xf0105441
f01013b2:	e8 e9 ec ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01013b7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01013ba:	39 c7                	cmp    %eax,%edi
f01013bc:	74 04                	je     f01013c2 <mem_init+0x3e8>
f01013be:	39 c6                	cmp    %eax,%esi
f01013c0:	75 19                	jne    f01013db <mem_init+0x401>
f01013c2:	68 ec 4d 10 f0       	push   $0xf0104dec
f01013c7:	68 67 54 10 f0       	push   $0xf0105467
f01013cc:	68 df 02 00 00       	push   $0x2df
f01013d1:	68 41 54 10 f0       	push   $0xf0105441
f01013d6:	e8 c5 ec ff ff       	call   f01000a0 <_panic>
	assert(!page_alloc(0));
f01013db:	83 ec 0c             	sub    $0xc,%esp
f01013de:	6a 00                	push   $0x0
f01013e0:	e8 1a f9 ff ff       	call   f0100cff <page_alloc>
f01013e5:	83 c4 10             	add    $0x10,%esp
f01013e8:	85 c0                	test   %eax,%eax
f01013ea:	74 19                	je     f0101405 <mem_init+0x42b>
f01013ec:	68 bd 55 10 f0       	push   $0xf01055bd
f01013f1:	68 67 54 10 f0       	push   $0xf0105467
f01013f6:	68 e0 02 00 00       	push   $0x2e0
f01013fb:	68 41 54 10 f0       	push   $0xf0105441
f0101400:	e8 9b ec ff ff       	call   f01000a0 <_panic>
f0101405:	89 f0                	mov    %esi,%eax
f0101407:	2b 05 4c cc 17 f0    	sub    0xf017cc4c,%eax
f010140d:	c1 f8 03             	sar    $0x3,%eax
f0101410:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101413:	89 c2                	mov    %eax,%edx
f0101415:	c1 ea 0c             	shr    $0xc,%edx
f0101418:	3b 15 44 cc 17 f0    	cmp    0xf017cc44,%edx
f010141e:	72 12                	jb     f0101432 <mem_init+0x458>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101420:	50                   	push   %eax
f0101421:	68 84 4c 10 f0       	push   $0xf0104c84
f0101426:	6a 56                	push   $0x56
f0101428:	68 4d 54 10 f0       	push   $0xf010544d
f010142d:	e8 6e ec ff ff       	call   f01000a0 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101432:	83 ec 04             	sub    $0x4,%esp
f0101435:	68 00 10 00 00       	push   $0x1000
f010143a:	6a 01                	push   $0x1
f010143c:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101441:	50                   	push   %eax
f0101442:	e8 5b 2e 00 00       	call   f01042a2 <memset>
	page_free(pp0);
f0101447:	89 34 24             	mov    %esi,(%esp)
f010144a:	e8 20 f9 ff ff       	call   f0100d6f <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f010144f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101456:	e8 a4 f8 ff ff       	call   f0100cff <page_alloc>
f010145b:	83 c4 10             	add    $0x10,%esp
f010145e:	85 c0                	test   %eax,%eax
f0101460:	75 19                	jne    f010147b <mem_init+0x4a1>
f0101462:	68 cc 55 10 f0       	push   $0xf01055cc
f0101467:	68 67 54 10 f0       	push   $0xf0105467
f010146c:	68 e5 02 00 00       	push   $0x2e5
f0101471:	68 41 54 10 f0       	push   $0xf0105441
f0101476:	e8 25 ec ff ff       	call   f01000a0 <_panic>
	assert(pp && pp0 == pp);
f010147b:	39 c6                	cmp    %eax,%esi
f010147d:	74 19                	je     f0101498 <mem_init+0x4be>
f010147f:	68 ea 55 10 f0       	push   $0xf01055ea
f0101484:	68 67 54 10 f0       	push   $0xf0105467
f0101489:	68 e6 02 00 00       	push   $0x2e6
f010148e:	68 41 54 10 f0       	push   $0xf0105441
f0101493:	e8 08 ec ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101498:	89 f0                	mov    %esi,%eax
f010149a:	2b 05 4c cc 17 f0    	sub    0xf017cc4c,%eax
f01014a0:	c1 f8 03             	sar    $0x3,%eax
f01014a3:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01014a6:	89 c2                	mov    %eax,%edx
f01014a8:	c1 ea 0c             	shr    $0xc,%edx
f01014ab:	3b 15 44 cc 17 f0    	cmp    0xf017cc44,%edx
f01014b1:	72 12                	jb     f01014c5 <mem_init+0x4eb>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01014b3:	50                   	push   %eax
f01014b4:	68 84 4c 10 f0       	push   $0xf0104c84
f01014b9:	6a 56                	push   $0x56
f01014bb:	68 4d 54 10 f0       	push   $0xf010544d
f01014c0:	e8 db eb ff ff       	call   f01000a0 <_panic>
f01014c5:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f01014cb:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01014d1:	80 38 00             	cmpb   $0x0,(%eax)
f01014d4:	74 19                	je     f01014ef <mem_init+0x515>
f01014d6:	68 fa 55 10 f0       	push   $0xf01055fa
f01014db:	68 67 54 10 f0       	push   $0xf0105467
f01014e0:	68 e9 02 00 00       	push   $0x2e9
f01014e5:	68 41 54 10 f0       	push   $0xf0105441
f01014ea:	e8 b1 eb ff ff       	call   f01000a0 <_panic>
f01014ef:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f01014f2:	39 d0                	cmp    %edx,%eax
f01014f4:	75 db                	jne    f01014d1 <mem_init+0x4f7>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f01014f6:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01014f9:	a3 80 bf 17 f0       	mov    %eax,0xf017bf80

	// free the pages we took
	page_free(pp0);
f01014fe:	83 ec 0c             	sub    $0xc,%esp
f0101501:	56                   	push   %esi
f0101502:	e8 68 f8 ff ff       	call   f0100d6f <page_free>
	page_free(pp1);
f0101507:	89 3c 24             	mov    %edi,(%esp)
f010150a:	e8 60 f8 ff ff       	call   f0100d6f <page_free>
	page_free(pp2);
f010150f:	83 c4 04             	add    $0x4,%esp
f0101512:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101515:	e8 55 f8 ff ff       	call   f0100d6f <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010151a:	a1 80 bf 17 f0       	mov    0xf017bf80,%eax
f010151f:	83 c4 10             	add    $0x10,%esp
f0101522:	eb 05                	jmp    f0101529 <mem_init+0x54f>
		--nfree;
f0101524:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101527:	8b 00                	mov    (%eax),%eax
f0101529:	85 c0                	test   %eax,%eax
f010152b:	75 f7                	jne    f0101524 <mem_init+0x54a>
		--nfree;
	assert(nfree == 0);
f010152d:	85 db                	test   %ebx,%ebx
f010152f:	74 19                	je     f010154a <mem_init+0x570>
f0101531:	68 04 56 10 f0       	push   $0xf0105604
f0101536:	68 67 54 10 f0       	push   $0xf0105467
f010153b:	68 f6 02 00 00       	push   $0x2f6
f0101540:	68 41 54 10 f0       	push   $0xf0105441
f0101545:	e8 56 eb ff ff       	call   f01000a0 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f010154a:	83 ec 0c             	sub    $0xc,%esp
f010154d:	68 0c 4e 10 f0       	push   $0xf0104e0c
f0101552:	e8 52 19 00 00       	call   f0102ea9 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101557:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010155e:	e8 9c f7 ff ff       	call   f0100cff <page_alloc>
f0101563:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101566:	83 c4 10             	add    $0x10,%esp
f0101569:	85 c0                	test   %eax,%eax
f010156b:	75 19                	jne    f0101586 <mem_init+0x5ac>
f010156d:	68 12 55 10 f0       	push   $0xf0105512
f0101572:	68 67 54 10 f0       	push   $0xf0105467
f0101577:	68 54 03 00 00       	push   $0x354
f010157c:	68 41 54 10 f0       	push   $0xf0105441
f0101581:	e8 1a eb ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f0101586:	83 ec 0c             	sub    $0xc,%esp
f0101589:	6a 00                	push   $0x0
f010158b:	e8 6f f7 ff ff       	call   f0100cff <page_alloc>
f0101590:	89 c3                	mov    %eax,%ebx
f0101592:	83 c4 10             	add    $0x10,%esp
f0101595:	85 c0                	test   %eax,%eax
f0101597:	75 19                	jne    f01015b2 <mem_init+0x5d8>
f0101599:	68 28 55 10 f0       	push   $0xf0105528
f010159e:	68 67 54 10 f0       	push   $0xf0105467
f01015a3:	68 55 03 00 00       	push   $0x355
f01015a8:	68 41 54 10 f0       	push   $0xf0105441
f01015ad:	e8 ee ea ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f01015b2:	83 ec 0c             	sub    $0xc,%esp
f01015b5:	6a 00                	push   $0x0
f01015b7:	e8 43 f7 ff ff       	call   f0100cff <page_alloc>
f01015bc:	89 c6                	mov    %eax,%esi
f01015be:	83 c4 10             	add    $0x10,%esp
f01015c1:	85 c0                	test   %eax,%eax
f01015c3:	75 19                	jne    f01015de <mem_init+0x604>
f01015c5:	68 3e 55 10 f0       	push   $0xf010553e
f01015ca:	68 67 54 10 f0       	push   $0xf0105467
f01015cf:	68 56 03 00 00       	push   $0x356
f01015d4:	68 41 54 10 f0       	push   $0xf0105441
f01015d9:	e8 c2 ea ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01015de:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01015e1:	75 19                	jne    f01015fc <mem_init+0x622>
f01015e3:	68 54 55 10 f0       	push   $0xf0105554
f01015e8:	68 67 54 10 f0       	push   $0xf0105467
f01015ed:	68 59 03 00 00       	push   $0x359
f01015f2:	68 41 54 10 f0       	push   $0xf0105441
f01015f7:	e8 a4 ea ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01015fc:	39 c3                	cmp    %eax,%ebx
f01015fe:	74 05                	je     f0101605 <mem_init+0x62b>
f0101600:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101603:	75 19                	jne    f010161e <mem_init+0x644>
f0101605:	68 ec 4d 10 f0       	push   $0xf0104dec
f010160a:	68 67 54 10 f0       	push   $0xf0105467
f010160f:	68 5a 03 00 00       	push   $0x35a
f0101614:	68 41 54 10 f0       	push   $0xf0105441
f0101619:	e8 82 ea ff ff       	call   f01000a0 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010161e:	a1 80 bf 17 f0       	mov    0xf017bf80,%eax
f0101623:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101626:	c7 05 80 bf 17 f0 00 	movl   $0x0,0xf017bf80
f010162d:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101630:	83 ec 0c             	sub    $0xc,%esp
f0101633:	6a 00                	push   $0x0
f0101635:	e8 c5 f6 ff ff       	call   f0100cff <page_alloc>
f010163a:	83 c4 10             	add    $0x10,%esp
f010163d:	85 c0                	test   %eax,%eax
f010163f:	74 19                	je     f010165a <mem_init+0x680>
f0101641:	68 bd 55 10 f0       	push   $0xf01055bd
f0101646:	68 67 54 10 f0       	push   $0xf0105467
f010164b:	68 61 03 00 00       	push   $0x361
f0101650:	68 41 54 10 f0       	push   $0xf0105441
f0101655:	e8 46 ea ff ff       	call   f01000a0 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f010165a:	83 ec 04             	sub    $0x4,%esp
f010165d:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101660:	50                   	push   %eax
f0101661:	6a 00                	push   $0x0
f0101663:	ff 35 48 cc 17 f0    	pushl  0xf017cc48
f0101669:	e8 58 f8 ff ff       	call   f0100ec6 <page_lookup>
f010166e:	83 c4 10             	add    $0x10,%esp
f0101671:	85 c0                	test   %eax,%eax
f0101673:	74 19                	je     f010168e <mem_init+0x6b4>
f0101675:	68 2c 4e 10 f0       	push   $0xf0104e2c
f010167a:	68 67 54 10 f0       	push   $0xf0105467
f010167f:	68 64 03 00 00       	push   $0x364
f0101684:	68 41 54 10 f0       	push   $0xf0105441
f0101689:	e8 12 ea ff ff       	call   f01000a0 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f010168e:	6a 02                	push   $0x2
f0101690:	6a 00                	push   $0x0
f0101692:	53                   	push   %ebx
f0101693:	ff 35 48 cc 17 f0    	pushl  0xf017cc48
f0101699:	e8 d6 f8 ff ff       	call   f0100f74 <page_insert>
f010169e:	83 c4 10             	add    $0x10,%esp
f01016a1:	85 c0                	test   %eax,%eax
f01016a3:	78 19                	js     f01016be <mem_init+0x6e4>
f01016a5:	68 64 4e 10 f0       	push   $0xf0104e64
f01016aa:	68 67 54 10 f0       	push   $0xf0105467
f01016af:	68 67 03 00 00       	push   $0x367
f01016b4:	68 41 54 10 f0       	push   $0xf0105441
f01016b9:	e8 e2 e9 ff ff       	call   f01000a0 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f01016be:	83 ec 0c             	sub    $0xc,%esp
f01016c1:	ff 75 d4             	pushl  -0x2c(%ebp)
f01016c4:	e8 a6 f6 ff ff       	call   f0100d6f <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01016c9:	6a 02                	push   $0x2
f01016cb:	6a 00                	push   $0x0
f01016cd:	53                   	push   %ebx
f01016ce:	ff 35 48 cc 17 f0    	pushl  0xf017cc48
f01016d4:	e8 9b f8 ff ff       	call   f0100f74 <page_insert>
f01016d9:	83 c4 20             	add    $0x20,%esp
f01016dc:	85 c0                	test   %eax,%eax
f01016de:	74 19                	je     f01016f9 <mem_init+0x71f>
f01016e0:	68 94 4e 10 f0       	push   $0xf0104e94
f01016e5:	68 67 54 10 f0       	push   $0xf0105467
f01016ea:	68 6b 03 00 00       	push   $0x36b
f01016ef:	68 41 54 10 f0       	push   $0xf0105441
f01016f4:	e8 a7 e9 ff ff       	call   f01000a0 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01016f9:	8b 3d 48 cc 17 f0    	mov    0xf017cc48,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01016ff:	a1 4c cc 17 f0       	mov    0xf017cc4c,%eax
f0101704:	89 c1                	mov    %eax,%ecx
f0101706:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101709:	8b 17                	mov    (%edi),%edx
f010170b:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101711:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101714:	29 c8                	sub    %ecx,%eax
f0101716:	c1 f8 03             	sar    $0x3,%eax
f0101719:	c1 e0 0c             	shl    $0xc,%eax
f010171c:	39 c2                	cmp    %eax,%edx
f010171e:	74 19                	je     f0101739 <mem_init+0x75f>
f0101720:	68 c4 4e 10 f0       	push   $0xf0104ec4
f0101725:	68 67 54 10 f0       	push   $0xf0105467
f010172a:	68 6c 03 00 00       	push   $0x36c
f010172f:	68 41 54 10 f0       	push   $0xf0105441
f0101734:	e8 67 e9 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101739:	ba 00 00 00 00       	mov    $0x0,%edx
f010173e:	89 f8                	mov    %edi,%eax
f0101740:	e8 e8 f1 ff ff       	call   f010092d <check_va2pa>
f0101745:	89 da                	mov    %ebx,%edx
f0101747:	2b 55 cc             	sub    -0x34(%ebp),%edx
f010174a:	c1 fa 03             	sar    $0x3,%edx
f010174d:	c1 e2 0c             	shl    $0xc,%edx
f0101750:	39 d0                	cmp    %edx,%eax
f0101752:	74 19                	je     f010176d <mem_init+0x793>
f0101754:	68 ec 4e 10 f0       	push   $0xf0104eec
f0101759:	68 67 54 10 f0       	push   $0xf0105467
f010175e:	68 6d 03 00 00       	push   $0x36d
f0101763:	68 41 54 10 f0       	push   $0xf0105441
f0101768:	e8 33 e9 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f010176d:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101772:	74 19                	je     f010178d <mem_init+0x7b3>
f0101774:	68 0f 56 10 f0       	push   $0xf010560f
f0101779:	68 67 54 10 f0       	push   $0xf0105467
f010177e:	68 6e 03 00 00       	push   $0x36e
f0101783:	68 41 54 10 f0       	push   $0xf0105441
f0101788:	e8 13 e9 ff ff       	call   f01000a0 <_panic>
	assert(pp0->pp_ref == 1);
f010178d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101790:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101795:	74 19                	je     f01017b0 <mem_init+0x7d6>
f0101797:	68 20 56 10 f0       	push   $0xf0105620
f010179c:	68 67 54 10 f0       	push   $0xf0105467
f01017a1:	68 6f 03 00 00       	push   $0x36f
f01017a6:	68 41 54 10 f0       	push   $0xf0105441
f01017ab:	e8 f0 e8 ff ff       	call   f01000a0 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01017b0:	6a 02                	push   $0x2
f01017b2:	68 00 10 00 00       	push   $0x1000
f01017b7:	56                   	push   %esi
f01017b8:	57                   	push   %edi
f01017b9:	e8 b6 f7 ff ff       	call   f0100f74 <page_insert>
f01017be:	83 c4 10             	add    $0x10,%esp
f01017c1:	85 c0                	test   %eax,%eax
f01017c3:	74 19                	je     f01017de <mem_init+0x804>
f01017c5:	68 1c 4f 10 f0       	push   $0xf0104f1c
f01017ca:	68 67 54 10 f0       	push   $0xf0105467
f01017cf:	68 72 03 00 00       	push   $0x372
f01017d4:	68 41 54 10 f0       	push   $0xf0105441
f01017d9:	e8 c2 e8 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01017de:	ba 00 10 00 00       	mov    $0x1000,%edx
f01017e3:	a1 48 cc 17 f0       	mov    0xf017cc48,%eax
f01017e8:	e8 40 f1 ff ff       	call   f010092d <check_va2pa>
f01017ed:	89 f2                	mov    %esi,%edx
f01017ef:	2b 15 4c cc 17 f0    	sub    0xf017cc4c,%edx
f01017f5:	c1 fa 03             	sar    $0x3,%edx
f01017f8:	c1 e2 0c             	shl    $0xc,%edx
f01017fb:	39 d0                	cmp    %edx,%eax
f01017fd:	74 19                	je     f0101818 <mem_init+0x83e>
f01017ff:	68 58 4f 10 f0       	push   $0xf0104f58
f0101804:	68 67 54 10 f0       	push   $0xf0105467
f0101809:	68 73 03 00 00       	push   $0x373
f010180e:	68 41 54 10 f0       	push   $0xf0105441
f0101813:	e8 88 e8 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0101818:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010181d:	74 19                	je     f0101838 <mem_init+0x85e>
f010181f:	68 31 56 10 f0       	push   $0xf0105631
f0101824:	68 67 54 10 f0       	push   $0xf0105467
f0101829:	68 74 03 00 00       	push   $0x374
f010182e:	68 41 54 10 f0       	push   $0xf0105441
f0101833:	e8 68 e8 ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101838:	83 ec 0c             	sub    $0xc,%esp
f010183b:	6a 00                	push   $0x0
f010183d:	e8 bd f4 ff ff       	call   f0100cff <page_alloc>
f0101842:	83 c4 10             	add    $0x10,%esp
f0101845:	85 c0                	test   %eax,%eax
f0101847:	74 19                	je     f0101862 <mem_init+0x888>
f0101849:	68 bd 55 10 f0       	push   $0xf01055bd
f010184e:	68 67 54 10 f0       	push   $0xf0105467
f0101853:	68 77 03 00 00       	push   $0x377
f0101858:	68 41 54 10 f0       	push   $0xf0105441
f010185d:	e8 3e e8 ff ff       	call   f01000a0 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101862:	6a 02                	push   $0x2
f0101864:	68 00 10 00 00       	push   $0x1000
f0101869:	56                   	push   %esi
f010186a:	ff 35 48 cc 17 f0    	pushl  0xf017cc48
f0101870:	e8 ff f6 ff ff       	call   f0100f74 <page_insert>
f0101875:	83 c4 10             	add    $0x10,%esp
f0101878:	85 c0                	test   %eax,%eax
f010187a:	74 19                	je     f0101895 <mem_init+0x8bb>
f010187c:	68 1c 4f 10 f0       	push   $0xf0104f1c
f0101881:	68 67 54 10 f0       	push   $0xf0105467
f0101886:	68 7a 03 00 00       	push   $0x37a
f010188b:	68 41 54 10 f0       	push   $0xf0105441
f0101890:	e8 0b e8 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101895:	ba 00 10 00 00       	mov    $0x1000,%edx
f010189a:	a1 48 cc 17 f0       	mov    0xf017cc48,%eax
f010189f:	e8 89 f0 ff ff       	call   f010092d <check_va2pa>
f01018a4:	89 f2                	mov    %esi,%edx
f01018a6:	2b 15 4c cc 17 f0    	sub    0xf017cc4c,%edx
f01018ac:	c1 fa 03             	sar    $0x3,%edx
f01018af:	c1 e2 0c             	shl    $0xc,%edx
f01018b2:	39 d0                	cmp    %edx,%eax
f01018b4:	74 19                	je     f01018cf <mem_init+0x8f5>
f01018b6:	68 58 4f 10 f0       	push   $0xf0104f58
f01018bb:	68 67 54 10 f0       	push   $0xf0105467
f01018c0:	68 7b 03 00 00       	push   $0x37b
f01018c5:	68 41 54 10 f0       	push   $0xf0105441
f01018ca:	e8 d1 e7 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f01018cf:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01018d4:	74 19                	je     f01018ef <mem_init+0x915>
f01018d6:	68 31 56 10 f0       	push   $0xf0105631
f01018db:	68 67 54 10 f0       	push   $0xf0105467
f01018e0:	68 7c 03 00 00       	push   $0x37c
f01018e5:	68 41 54 10 f0       	push   $0xf0105441
f01018ea:	e8 b1 e7 ff ff       	call   f01000a0 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f01018ef:	83 ec 0c             	sub    $0xc,%esp
f01018f2:	6a 00                	push   $0x0
f01018f4:	e8 06 f4 ff ff       	call   f0100cff <page_alloc>
f01018f9:	83 c4 10             	add    $0x10,%esp
f01018fc:	85 c0                	test   %eax,%eax
f01018fe:	74 19                	je     f0101919 <mem_init+0x93f>
f0101900:	68 bd 55 10 f0       	push   $0xf01055bd
f0101905:	68 67 54 10 f0       	push   $0xf0105467
f010190a:	68 80 03 00 00       	push   $0x380
f010190f:	68 41 54 10 f0       	push   $0xf0105441
f0101914:	e8 87 e7 ff ff       	call   f01000a0 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101919:	8b 15 48 cc 17 f0    	mov    0xf017cc48,%edx
f010191f:	8b 02                	mov    (%edx),%eax
f0101921:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101926:	89 c1                	mov    %eax,%ecx
f0101928:	c1 e9 0c             	shr    $0xc,%ecx
f010192b:	3b 0d 44 cc 17 f0    	cmp    0xf017cc44,%ecx
f0101931:	72 15                	jb     f0101948 <mem_init+0x96e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101933:	50                   	push   %eax
f0101934:	68 84 4c 10 f0       	push   $0xf0104c84
f0101939:	68 83 03 00 00       	push   $0x383
f010193e:	68 41 54 10 f0       	push   $0xf0105441
f0101943:	e8 58 e7 ff ff       	call   f01000a0 <_panic>
f0101948:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010194d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101950:	83 ec 04             	sub    $0x4,%esp
f0101953:	6a 00                	push   $0x0
f0101955:	68 00 10 00 00       	push   $0x1000
f010195a:	52                   	push   %edx
f010195b:	e8 45 f4 ff ff       	call   f0100da5 <pgdir_walk>
f0101960:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101963:	8d 57 04             	lea    0x4(%edi),%edx
f0101966:	83 c4 10             	add    $0x10,%esp
f0101969:	39 d0                	cmp    %edx,%eax
f010196b:	74 19                	je     f0101986 <mem_init+0x9ac>
f010196d:	68 88 4f 10 f0       	push   $0xf0104f88
f0101972:	68 67 54 10 f0       	push   $0xf0105467
f0101977:	68 84 03 00 00       	push   $0x384
f010197c:	68 41 54 10 f0       	push   $0xf0105441
f0101981:	e8 1a e7 ff ff       	call   f01000a0 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101986:	6a 06                	push   $0x6
f0101988:	68 00 10 00 00       	push   $0x1000
f010198d:	56                   	push   %esi
f010198e:	ff 35 48 cc 17 f0    	pushl  0xf017cc48
f0101994:	e8 db f5 ff ff       	call   f0100f74 <page_insert>
f0101999:	83 c4 10             	add    $0x10,%esp
f010199c:	85 c0                	test   %eax,%eax
f010199e:	74 19                	je     f01019b9 <mem_init+0x9df>
f01019a0:	68 c8 4f 10 f0       	push   $0xf0104fc8
f01019a5:	68 67 54 10 f0       	push   $0xf0105467
f01019aa:	68 87 03 00 00       	push   $0x387
f01019af:	68 41 54 10 f0       	push   $0xf0105441
f01019b4:	e8 e7 e6 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01019b9:	8b 3d 48 cc 17 f0    	mov    0xf017cc48,%edi
f01019bf:	ba 00 10 00 00       	mov    $0x1000,%edx
f01019c4:	89 f8                	mov    %edi,%eax
f01019c6:	e8 62 ef ff ff       	call   f010092d <check_va2pa>
f01019cb:	89 f2                	mov    %esi,%edx
f01019cd:	2b 15 4c cc 17 f0    	sub    0xf017cc4c,%edx
f01019d3:	c1 fa 03             	sar    $0x3,%edx
f01019d6:	c1 e2 0c             	shl    $0xc,%edx
f01019d9:	39 d0                	cmp    %edx,%eax
f01019db:	74 19                	je     f01019f6 <mem_init+0xa1c>
f01019dd:	68 58 4f 10 f0       	push   $0xf0104f58
f01019e2:	68 67 54 10 f0       	push   $0xf0105467
f01019e7:	68 88 03 00 00       	push   $0x388
f01019ec:	68 41 54 10 f0       	push   $0xf0105441
f01019f1:	e8 aa e6 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f01019f6:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01019fb:	74 19                	je     f0101a16 <mem_init+0xa3c>
f01019fd:	68 31 56 10 f0       	push   $0xf0105631
f0101a02:	68 67 54 10 f0       	push   $0xf0105467
f0101a07:	68 89 03 00 00       	push   $0x389
f0101a0c:	68 41 54 10 f0       	push   $0xf0105441
f0101a11:	e8 8a e6 ff ff       	call   f01000a0 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101a16:	83 ec 04             	sub    $0x4,%esp
f0101a19:	6a 00                	push   $0x0
f0101a1b:	68 00 10 00 00       	push   $0x1000
f0101a20:	57                   	push   %edi
f0101a21:	e8 7f f3 ff ff       	call   f0100da5 <pgdir_walk>
f0101a26:	83 c4 10             	add    $0x10,%esp
f0101a29:	f6 00 04             	testb  $0x4,(%eax)
f0101a2c:	75 19                	jne    f0101a47 <mem_init+0xa6d>
f0101a2e:	68 08 50 10 f0       	push   $0xf0105008
f0101a33:	68 67 54 10 f0       	push   $0xf0105467
f0101a38:	68 8a 03 00 00       	push   $0x38a
f0101a3d:	68 41 54 10 f0       	push   $0xf0105441
f0101a42:	e8 59 e6 ff ff       	call   f01000a0 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101a47:	a1 48 cc 17 f0       	mov    0xf017cc48,%eax
f0101a4c:	f6 00 04             	testb  $0x4,(%eax)
f0101a4f:	75 19                	jne    f0101a6a <mem_init+0xa90>
f0101a51:	68 42 56 10 f0       	push   $0xf0105642
f0101a56:	68 67 54 10 f0       	push   $0xf0105467
f0101a5b:	68 8b 03 00 00       	push   $0x38b
f0101a60:	68 41 54 10 f0       	push   $0xf0105441
f0101a65:	e8 36 e6 ff ff       	call   f01000a0 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101a6a:	6a 02                	push   $0x2
f0101a6c:	68 00 10 00 00       	push   $0x1000
f0101a71:	56                   	push   %esi
f0101a72:	50                   	push   %eax
f0101a73:	e8 fc f4 ff ff       	call   f0100f74 <page_insert>
f0101a78:	83 c4 10             	add    $0x10,%esp
f0101a7b:	85 c0                	test   %eax,%eax
f0101a7d:	74 19                	je     f0101a98 <mem_init+0xabe>
f0101a7f:	68 1c 4f 10 f0       	push   $0xf0104f1c
f0101a84:	68 67 54 10 f0       	push   $0xf0105467
f0101a89:	68 8e 03 00 00       	push   $0x38e
f0101a8e:	68 41 54 10 f0       	push   $0xf0105441
f0101a93:	e8 08 e6 ff ff       	call   f01000a0 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101a98:	83 ec 04             	sub    $0x4,%esp
f0101a9b:	6a 00                	push   $0x0
f0101a9d:	68 00 10 00 00       	push   $0x1000
f0101aa2:	ff 35 48 cc 17 f0    	pushl  0xf017cc48
f0101aa8:	e8 f8 f2 ff ff       	call   f0100da5 <pgdir_walk>
f0101aad:	83 c4 10             	add    $0x10,%esp
f0101ab0:	f6 00 02             	testb  $0x2,(%eax)
f0101ab3:	75 19                	jne    f0101ace <mem_init+0xaf4>
f0101ab5:	68 3c 50 10 f0       	push   $0xf010503c
f0101aba:	68 67 54 10 f0       	push   $0xf0105467
f0101abf:	68 8f 03 00 00       	push   $0x38f
f0101ac4:	68 41 54 10 f0       	push   $0xf0105441
f0101ac9:	e8 d2 e5 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101ace:	83 ec 04             	sub    $0x4,%esp
f0101ad1:	6a 00                	push   $0x0
f0101ad3:	68 00 10 00 00       	push   $0x1000
f0101ad8:	ff 35 48 cc 17 f0    	pushl  0xf017cc48
f0101ade:	e8 c2 f2 ff ff       	call   f0100da5 <pgdir_walk>
f0101ae3:	83 c4 10             	add    $0x10,%esp
f0101ae6:	f6 00 04             	testb  $0x4,(%eax)
f0101ae9:	74 19                	je     f0101b04 <mem_init+0xb2a>
f0101aeb:	68 70 50 10 f0       	push   $0xf0105070
f0101af0:	68 67 54 10 f0       	push   $0xf0105467
f0101af5:	68 90 03 00 00       	push   $0x390
f0101afa:	68 41 54 10 f0       	push   $0xf0105441
f0101aff:	e8 9c e5 ff ff       	call   f01000a0 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101b04:	6a 02                	push   $0x2
f0101b06:	68 00 00 40 00       	push   $0x400000
f0101b0b:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101b0e:	ff 35 48 cc 17 f0    	pushl  0xf017cc48
f0101b14:	e8 5b f4 ff ff       	call   f0100f74 <page_insert>
f0101b19:	83 c4 10             	add    $0x10,%esp
f0101b1c:	85 c0                	test   %eax,%eax
f0101b1e:	78 19                	js     f0101b39 <mem_init+0xb5f>
f0101b20:	68 a8 50 10 f0       	push   $0xf01050a8
f0101b25:	68 67 54 10 f0       	push   $0xf0105467
f0101b2a:	68 93 03 00 00       	push   $0x393
f0101b2f:	68 41 54 10 f0       	push   $0xf0105441
f0101b34:	e8 67 e5 ff ff       	call   f01000a0 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101b39:	6a 02                	push   $0x2
f0101b3b:	68 00 10 00 00       	push   $0x1000
f0101b40:	53                   	push   %ebx
f0101b41:	ff 35 48 cc 17 f0    	pushl  0xf017cc48
f0101b47:	e8 28 f4 ff ff       	call   f0100f74 <page_insert>
f0101b4c:	83 c4 10             	add    $0x10,%esp
f0101b4f:	85 c0                	test   %eax,%eax
f0101b51:	74 19                	je     f0101b6c <mem_init+0xb92>
f0101b53:	68 e0 50 10 f0       	push   $0xf01050e0
f0101b58:	68 67 54 10 f0       	push   $0xf0105467
f0101b5d:	68 96 03 00 00       	push   $0x396
f0101b62:	68 41 54 10 f0       	push   $0xf0105441
f0101b67:	e8 34 e5 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101b6c:	83 ec 04             	sub    $0x4,%esp
f0101b6f:	6a 00                	push   $0x0
f0101b71:	68 00 10 00 00       	push   $0x1000
f0101b76:	ff 35 48 cc 17 f0    	pushl  0xf017cc48
f0101b7c:	e8 24 f2 ff ff       	call   f0100da5 <pgdir_walk>
f0101b81:	83 c4 10             	add    $0x10,%esp
f0101b84:	f6 00 04             	testb  $0x4,(%eax)
f0101b87:	74 19                	je     f0101ba2 <mem_init+0xbc8>
f0101b89:	68 70 50 10 f0       	push   $0xf0105070
f0101b8e:	68 67 54 10 f0       	push   $0xf0105467
f0101b93:	68 97 03 00 00       	push   $0x397
f0101b98:	68 41 54 10 f0       	push   $0xf0105441
f0101b9d:	e8 fe e4 ff ff       	call   f01000a0 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101ba2:	8b 3d 48 cc 17 f0    	mov    0xf017cc48,%edi
f0101ba8:	ba 00 00 00 00       	mov    $0x0,%edx
f0101bad:	89 f8                	mov    %edi,%eax
f0101baf:	e8 79 ed ff ff       	call   f010092d <check_va2pa>
f0101bb4:	89 c1                	mov    %eax,%ecx
f0101bb6:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101bb9:	89 d8                	mov    %ebx,%eax
f0101bbb:	2b 05 4c cc 17 f0    	sub    0xf017cc4c,%eax
f0101bc1:	c1 f8 03             	sar    $0x3,%eax
f0101bc4:	c1 e0 0c             	shl    $0xc,%eax
f0101bc7:	39 c1                	cmp    %eax,%ecx
f0101bc9:	74 19                	je     f0101be4 <mem_init+0xc0a>
f0101bcb:	68 1c 51 10 f0       	push   $0xf010511c
f0101bd0:	68 67 54 10 f0       	push   $0xf0105467
f0101bd5:	68 9a 03 00 00       	push   $0x39a
f0101bda:	68 41 54 10 f0       	push   $0xf0105441
f0101bdf:	e8 bc e4 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101be4:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101be9:	89 f8                	mov    %edi,%eax
f0101beb:	e8 3d ed ff ff       	call   f010092d <check_va2pa>
f0101bf0:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101bf3:	74 19                	je     f0101c0e <mem_init+0xc34>
f0101bf5:	68 48 51 10 f0       	push   $0xf0105148
f0101bfa:	68 67 54 10 f0       	push   $0xf0105467
f0101bff:	68 9b 03 00 00       	push   $0x39b
f0101c04:	68 41 54 10 f0       	push   $0xf0105441
f0101c09:	e8 92 e4 ff ff       	call   f01000a0 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101c0e:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101c13:	74 19                	je     f0101c2e <mem_init+0xc54>
f0101c15:	68 58 56 10 f0       	push   $0xf0105658
f0101c1a:	68 67 54 10 f0       	push   $0xf0105467
f0101c1f:	68 9d 03 00 00       	push   $0x39d
f0101c24:	68 41 54 10 f0       	push   $0xf0105441
f0101c29:	e8 72 e4 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101c2e:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101c33:	74 19                	je     f0101c4e <mem_init+0xc74>
f0101c35:	68 69 56 10 f0       	push   $0xf0105669
f0101c3a:	68 67 54 10 f0       	push   $0xf0105467
f0101c3f:	68 9e 03 00 00       	push   $0x39e
f0101c44:	68 41 54 10 f0       	push   $0xf0105441
f0101c49:	e8 52 e4 ff ff       	call   f01000a0 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101c4e:	83 ec 0c             	sub    $0xc,%esp
f0101c51:	6a 00                	push   $0x0
f0101c53:	e8 a7 f0 ff ff       	call   f0100cff <page_alloc>
f0101c58:	83 c4 10             	add    $0x10,%esp
f0101c5b:	85 c0                	test   %eax,%eax
f0101c5d:	74 04                	je     f0101c63 <mem_init+0xc89>
f0101c5f:	39 c6                	cmp    %eax,%esi
f0101c61:	74 19                	je     f0101c7c <mem_init+0xca2>
f0101c63:	68 78 51 10 f0       	push   $0xf0105178
f0101c68:	68 67 54 10 f0       	push   $0xf0105467
f0101c6d:	68 a1 03 00 00       	push   $0x3a1
f0101c72:	68 41 54 10 f0       	push   $0xf0105441
f0101c77:	e8 24 e4 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101c7c:	83 ec 08             	sub    $0x8,%esp
f0101c7f:	6a 00                	push   $0x0
f0101c81:	ff 35 48 cc 17 f0    	pushl  0xf017cc48
f0101c87:	e8 a5 f2 ff ff       	call   f0100f31 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101c8c:	8b 3d 48 cc 17 f0    	mov    0xf017cc48,%edi
f0101c92:	ba 00 00 00 00       	mov    $0x0,%edx
f0101c97:	89 f8                	mov    %edi,%eax
f0101c99:	e8 8f ec ff ff       	call   f010092d <check_va2pa>
f0101c9e:	83 c4 10             	add    $0x10,%esp
f0101ca1:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101ca4:	74 19                	je     f0101cbf <mem_init+0xce5>
f0101ca6:	68 9c 51 10 f0       	push   $0xf010519c
f0101cab:	68 67 54 10 f0       	push   $0xf0105467
f0101cb0:	68 a5 03 00 00       	push   $0x3a5
f0101cb5:	68 41 54 10 f0       	push   $0xf0105441
f0101cba:	e8 e1 e3 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101cbf:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101cc4:	89 f8                	mov    %edi,%eax
f0101cc6:	e8 62 ec ff ff       	call   f010092d <check_va2pa>
f0101ccb:	89 da                	mov    %ebx,%edx
f0101ccd:	2b 15 4c cc 17 f0    	sub    0xf017cc4c,%edx
f0101cd3:	c1 fa 03             	sar    $0x3,%edx
f0101cd6:	c1 e2 0c             	shl    $0xc,%edx
f0101cd9:	39 d0                	cmp    %edx,%eax
f0101cdb:	74 19                	je     f0101cf6 <mem_init+0xd1c>
f0101cdd:	68 48 51 10 f0       	push   $0xf0105148
f0101ce2:	68 67 54 10 f0       	push   $0xf0105467
f0101ce7:	68 a6 03 00 00       	push   $0x3a6
f0101cec:	68 41 54 10 f0       	push   $0xf0105441
f0101cf1:	e8 aa e3 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f0101cf6:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101cfb:	74 19                	je     f0101d16 <mem_init+0xd3c>
f0101cfd:	68 0f 56 10 f0       	push   $0xf010560f
f0101d02:	68 67 54 10 f0       	push   $0xf0105467
f0101d07:	68 a7 03 00 00       	push   $0x3a7
f0101d0c:	68 41 54 10 f0       	push   $0xf0105441
f0101d11:	e8 8a e3 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101d16:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101d1b:	74 19                	je     f0101d36 <mem_init+0xd5c>
f0101d1d:	68 69 56 10 f0       	push   $0xf0105669
f0101d22:	68 67 54 10 f0       	push   $0xf0105467
f0101d27:	68 a8 03 00 00       	push   $0x3a8
f0101d2c:	68 41 54 10 f0       	push   $0xf0105441
f0101d31:	e8 6a e3 ff ff       	call   f01000a0 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101d36:	6a 00                	push   $0x0
f0101d38:	68 00 10 00 00       	push   $0x1000
f0101d3d:	53                   	push   %ebx
f0101d3e:	57                   	push   %edi
f0101d3f:	e8 30 f2 ff ff       	call   f0100f74 <page_insert>
f0101d44:	83 c4 10             	add    $0x10,%esp
f0101d47:	85 c0                	test   %eax,%eax
f0101d49:	74 19                	je     f0101d64 <mem_init+0xd8a>
f0101d4b:	68 c0 51 10 f0       	push   $0xf01051c0
f0101d50:	68 67 54 10 f0       	push   $0xf0105467
f0101d55:	68 ab 03 00 00       	push   $0x3ab
f0101d5a:	68 41 54 10 f0       	push   $0xf0105441
f0101d5f:	e8 3c e3 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref);
f0101d64:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101d69:	75 19                	jne    f0101d84 <mem_init+0xdaa>
f0101d6b:	68 7a 56 10 f0       	push   $0xf010567a
f0101d70:	68 67 54 10 f0       	push   $0xf0105467
f0101d75:	68 ac 03 00 00       	push   $0x3ac
f0101d7a:	68 41 54 10 f0       	push   $0xf0105441
f0101d7f:	e8 1c e3 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_link == NULL);
f0101d84:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101d87:	74 19                	je     f0101da2 <mem_init+0xdc8>
f0101d89:	68 86 56 10 f0       	push   $0xf0105686
f0101d8e:	68 67 54 10 f0       	push   $0xf0105467
f0101d93:	68 ad 03 00 00       	push   $0x3ad
f0101d98:	68 41 54 10 f0       	push   $0xf0105441
f0101d9d:	e8 fe e2 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101da2:	83 ec 08             	sub    $0x8,%esp
f0101da5:	68 00 10 00 00       	push   $0x1000
f0101daa:	ff 35 48 cc 17 f0    	pushl  0xf017cc48
f0101db0:	e8 7c f1 ff ff       	call   f0100f31 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101db5:	8b 3d 48 cc 17 f0    	mov    0xf017cc48,%edi
f0101dbb:	ba 00 00 00 00       	mov    $0x0,%edx
f0101dc0:	89 f8                	mov    %edi,%eax
f0101dc2:	e8 66 eb ff ff       	call   f010092d <check_va2pa>
f0101dc7:	83 c4 10             	add    $0x10,%esp
f0101dca:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101dcd:	74 19                	je     f0101de8 <mem_init+0xe0e>
f0101dcf:	68 9c 51 10 f0       	push   $0xf010519c
f0101dd4:	68 67 54 10 f0       	push   $0xf0105467
f0101dd9:	68 b1 03 00 00       	push   $0x3b1
f0101dde:	68 41 54 10 f0       	push   $0xf0105441
f0101de3:	e8 b8 e2 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101de8:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ded:	89 f8                	mov    %edi,%eax
f0101def:	e8 39 eb ff ff       	call   f010092d <check_va2pa>
f0101df4:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101df7:	74 19                	je     f0101e12 <mem_init+0xe38>
f0101df9:	68 f8 51 10 f0       	push   $0xf01051f8
f0101dfe:	68 67 54 10 f0       	push   $0xf0105467
f0101e03:	68 b2 03 00 00       	push   $0x3b2
f0101e08:	68 41 54 10 f0       	push   $0xf0105441
f0101e0d:	e8 8e e2 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f0101e12:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101e17:	74 19                	je     f0101e32 <mem_init+0xe58>
f0101e19:	68 9b 56 10 f0       	push   $0xf010569b
f0101e1e:	68 67 54 10 f0       	push   $0xf0105467
f0101e23:	68 b3 03 00 00       	push   $0x3b3
f0101e28:	68 41 54 10 f0       	push   $0xf0105441
f0101e2d:	e8 6e e2 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101e32:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101e37:	74 19                	je     f0101e52 <mem_init+0xe78>
f0101e39:	68 69 56 10 f0       	push   $0xf0105669
f0101e3e:	68 67 54 10 f0       	push   $0xf0105467
f0101e43:	68 b4 03 00 00       	push   $0x3b4
f0101e48:	68 41 54 10 f0       	push   $0xf0105441
f0101e4d:	e8 4e e2 ff ff       	call   f01000a0 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101e52:	83 ec 0c             	sub    $0xc,%esp
f0101e55:	6a 00                	push   $0x0
f0101e57:	e8 a3 ee ff ff       	call   f0100cff <page_alloc>
f0101e5c:	83 c4 10             	add    $0x10,%esp
f0101e5f:	39 c3                	cmp    %eax,%ebx
f0101e61:	75 04                	jne    f0101e67 <mem_init+0xe8d>
f0101e63:	85 c0                	test   %eax,%eax
f0101e65:	75 19                	jne    f0101e80 <mem_init+0xea6>
f0101e67:	68 20 52 10 f0       	push   $0xf0105220
f0101e6c:	68 67 54 10 f0       	push   $0xf0105467
f0101e71:	68 b7 03 00 00       	push   $0x3b7
f0101e76:	68 41 54 10 f0       	push   $0xf0105441
f0101e7b:	e8 20 e2 ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101e80:	83 ec 0c             	sub    $0xc,%esp
f0101e83:	6a 00                	push   $0x0
f0101e85:	e8 75 ee ff ff       	call   f0100cff <page_alloc>
f0101e8a:	83 c4 10             	add    $0x10,%esp
f0101e8d:	85 c0                	test   %eax,%eax
f0101e8f:	74 19                	je     f0101eaa <mem_init+0xed0>
f0101e91:	68 bd 55 10 f0       	push   $0xf01055bd
f0101e96:	68 67 54 10 f0       	push   $0xf0105467
f0101e9b:	68 ba 03 00 00       	push   $0x3ba
f0101ea0:	68 41 54 10 f0       	push   $0xf0105441
f0101ea5:	e8 f6 e1 ff ff       	call   f01000a0 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101eaa:	8b 0d 48 cc 17 f0    	mov    0xf017cc48,%ecx
f0101eb0:	8b 11                	mov    (%ecx),%edx
f0101eb2:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101eb8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ebb:	2b 05 4c cc 17 f0    	sub    0xf017cc4c,%eax
f0101ec1:	c1 f8 03             	sar    $0x3,%eax
f0101ec4:	c1 e0 0c             	shl    $0xc,%eax
f0101ec7:	39 c2                	cmp    %eax,%edx
f0101ec9:	74 19                	je     f0101ee4 <mem_init+0xf0a>
f0101ecb:	68 c4 4e 10 f0       	push   $0xf0104ec4
f0101ed0:	68 67 54 10 f0       	push   $0xf0105467
f0101ed5:	68 bd 03 00 00       	push   $0x3bd
f0101eda:	68 41 54 10 f0       	push   $0xf0105441
f0101edf:	e8 bc e1 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f0101ee4:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101eea:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101eed:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101ef2:	74 19                	je     f0101f0d <mem_init+0xf33>
f0101ef4:	68 20 56 10 f0       	push   $0xf0105620
f0101ef9:	68 67 54 10 f0       	push   $0xf0105467
f0101efe:	68 bf 03 00 00       	push   $0x3bf
f0101f03:	68 41 54 10 f0       	push   $0xf0105441
f0101f08:	e8 93 e1 ff ff       	call   f01000a0 <_panic>
	pp0->pp_ref = 0;
f0101f0d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f10:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101f16:	83 ec 0c             	sub    $0xc,%esp
f0101f19:	50                   	push   %eax
f0101f1a:	e8 50 ee ff ff       	call   f0100d6f <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101f1f:	83 c4 0c             	add    $0xc,%esp
f0101f22:	6a 01                	push   $0x1
f0101f24:	68 00 10 40 00       	push   $0x401000
f0101f29:	ff 35 48 cc 17 f0    	pushl  0xf017cc48
f0101f2f:	e8 71 ee ff ff       	call   f0100da5 <pgdir_walk>
f0101f34:	89 c7                	mov    %eax,%edi
f0101f36:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101f39:	a1 48 cc 17 f0       	mov    0xf017cc48,%eax
f0101f3e:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101f41:	8b 40 04             	mov    0x4(%eax),%eax
f0101f44:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101f49:	8b 0d 44 cc 17 f0    	mov    0xf017cc44,%ecx
f0101f4f:	89 c2                	mov    %eax,%edx
f0101f51:	c1 ea 0c             	shr    $0xc,%edx
f0101f54:	83 c4 10             	add    $0x10,%esp
f0101f57:	39 ca                	cmp    %ecx,%edx
f0101f59:	72 15                	jb     f0101f70 <mem_init+0xf96>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101f5b:	50                   	push   %eax
f0101f5c:	68 84 4c 10 f0       	push   $0xf0104c84
f0101f61:	68 c6 03 00 00       	push   $0x3c6
f0101f66:	68 41 54 10 f0       	push   $0xf0105441
f0101f6b:	e8 30 e1 ff ff       	call   f01000a0 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0101f70:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0101f75:	39 c7                	cmp    %eax,%edi
f0101f77:	74 19                	je     f0101f92 <mem_init+0xfb8>
f0101f79:	68 ac 56 10 f0       	push   $0xf01056ac
f0101f7e:	68 67 54 10 f0       	push   $0xf0105467
f0101f83:	68 c7 03 00 00       	push   $0x3c7
f0101f88:	68 41 54 10 f0       	push   $0xf0105441
f0101f8d:	e8 0e e1 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[PDX(va)] = 0;
f0101f92:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101f95:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f0101f9c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f9f:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101fa5:	2b 05 4c cc 17 f0    	sub    0xf017cc4c,%eax
f0101fab:	c1 f8 03             	sar    $0x3,%eax
f0101fae:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101fb1:	89 c2                	mov    %eax,%edx
f0101fb3:	c1 ea 0c             	shr    $0xc,%edx
f0101fb6:	39 d1                	cmp    %edx,%ecx
f0101fb8:	77 12                	ja     f0101fcc <mem_init+0xff2>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101fba:	50                   	push   %eax
f0101fbb:	68 84 4c 10 f0       	push   $0xf0104c84
f0101fc0:	6a 56                	push   $0x56
f0101fc2:	68 4d 54 10 f0       	push   $0xf010544d
f0101fc7:	e8 d4 e0 ff ff       	call   f01000a0 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0101fcc:	83 ec 04             	sub    $0x4,%esp
f0101fcf:	68 00 10 00 00       	push   $0x1000
f0101fd4:	68 ff 00 00 00       	push   $0xff
f0101fd9:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101fde:	50                   	push   %eax
f0101fdf:	e8 be 22 00 00       	call   f01042a2 <memset>
	page_free(pp0);
f0101fe4:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101fe7:	89 3c 24             	mov    %edi,(%esp)
f0101fea:	e8 80 ed ff ff       	call   f0100d6f <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0101fef:	83 c4 0c             	add    $0xc,%esp
f0101ff2:	6a 01                	push   $0x1
f0101ff4:	6a 00                	push   $0x0
f0101ff6:	ff 35 48 cc 17 f0    	pushl  0xf017cc48
f0101ffc:	e8 a4 ed ff ff       	call   f0100da5 <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102001:	89 fa                	mov    %edi,%edx
f0102003:	2b 15 4c cc 17 f0    	sub    0xf017cc4c,%edx
f0102009:	c1 fa 03             	sar    $0x3,%edx
f010200c:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010200f:	89 d0                	mov    %edx,%eax
f0102011:	c1 e8 0c             	shr    $0xc,%eax
f0102014:	83 c4 10             	add    $0x10,%esp
f0102017:	3b 05 44 cc 17 f0    	cmp    0xf017cc44,%eax
f010201d:	72 12                	jb     f0102031 <mem_init+0x1057>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010201f:	52                   	push   %edx
f0102020:	68 84 4c 10 f0       	push   $0xf0104c84
f0102025:	6a 56                	push   $0x56
f0102027:	68 4d 54 10 f0       	push   $0xf010544d
f010202c:	e8 6f e0 ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f0102031:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102037:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010203a:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102040:	f6 00 01             	testb  $0x1,(%eax)
f0102043:	74 19                	je     f010205e <mem_init+0x1084>
f0102045:	68 c4 56 10 f0       	push   $0xf01056c4
f010204a:	68 67 54 10 f0       	push   $0xf0105467
f010204f:	68 d1 03 00 00       	push   $0x3d1
f0102054:	68 41 54 10 f0       	push   $0xf0105441
f0102059:	e8 42 e0 ff ff       	call   f01000a0 <_panic>
f010205e:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102061:	39 c2                	cmp    %eax,%edx
f0102063:	75 db                	jne    f0102040 <mem_init+0x1066>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102065:	a1 48 cc 17 f0       	mov    0xf017cc48,%eax
f010206a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102070:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102073:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102079:	8b 7d d0             	mov    -0x30(%ebp),%edi
f010207c:	89 3d 80 bf 17 f0    	mov    %edi,0xf017bf80

	// free the pages we took
	page_free(pp0);
f0102082:	83 ec 0c             	sub    $0xc,%esp
f0102085:	50                   	push   %eax
f0102086:	e8 e4 ec ff ff       	call   f0100d6f <page_free>
	page_free(pp1);
f010208b:	89 1c 24             	mov    %ebx,(%esp)
f010208e:	e8 dc ec ff ff       	call   f0100d6f <page_free>
	page_free(pp2);
f0102093:	89 34 24             	mov    %esi,(%esp)
f0102096:	e8 d4 ec ff ff       	call   f0100d6f <page_free>

	cprintf("check_page() succeeded!\n");
f010209b:	c7 04 24 db 56 10 f0 	movl   $0xf01056db,(%esp)
f01020a2:	e8 02 0e 00 00       	call   f0102ea9 <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), PTE_U);
f01020a7:	a1 4c cc 17 f0       	mov    0xf017cc4c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01020ac:	83 c4 10             	add    $0x10,%esp
f01020af:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01020b4:	77 15                	ja     f01020cb <mem_init+0x10f1>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01020b6:	50                   	push   %eax
f01020b7:	68 c8 4d 10 f0       	push   $0xf0104dc8
f01020bc:	68 bb 00 00 00       	push   $0xbb
f01020c1:	68 41 54 10 f0       	push   $0xf0105441
f01020c6:	e8 d5 df ff ff       	call   f01000a0 <_panic>
f01020cb:	83 ec 08             	sub    $0x8,%esp
f01020ce:	6a 04                	push   $0x4
f01020d0:	05 00 00 00 10       	add    $0x10000000,%eax
f01020d5:	50                   	push   %eax
f01020d6:	b9 00 00 40 00       	mov    $0x400000,%ecx
f01020db:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01020e0:	a1 48 cc 17 f0       	mov    0xf017cc48,%eax
f01020e5:	e8 86 ed ff ff       	call   f0100e70 <boot_map_region>
	boot_map_region(kern_pgdir,UENVS, PTSIZE, PADDR(envs), PTE_U);
f01020ea:	a1 8c bf 17 f0       	mov    0xf017bf8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01020ef:	83 c4 10             	add    $0x10,%esp
f01020f2:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01020f7:	77 15                	ja     f010210e <mem_init+0x1134>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01020f9:	50                   	push   %eax
f01020fa:	68 c8 4d 10 f0       	push   $0xf0104dc8
f01020ff:	68 bc 00 00 00       	push   $0xbc
f0102104:	68 41 54 10 f0       	push   $0xf0105441
f0102109:	e8 92 df ff ff       	call   f01000a0 <_panic>
f010210e:	83 ec 08             	sub    $0x8,%esp
f0102111:	6a 04                	push   $0x4
f0102113:	05 00 00 00 10       	add    $0x10000000,%eax
f0102118:	50                   	push   %eax
f0102119:	b9 00 00 40 00       	mov    $0x400000,%ecx
f010211e:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102123:	a1 48 cc 17 f0       	mov    0xf017cc48,%eax
f0102128:	e8 43 ed ff ff       	call   f0100e70 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010212d:	83 c4 10             	add    $0x10,%esp
f0102130:	b8 00 00 11 f0       	mov    $0xf0110000,%eax
f0102135:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010213a:	77 15                	ja     f0102151 <mem_init+0x1177>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010213c:	50                   	push   %eax
f010213d:	68 c8 4d 10 f0       	push   $0xf0104dc8
f0102142:	68 d1 00 00 00       	push   $0xd1
f0102147:	68 41 54 10 f0       	push   $0xf0105441
f010214c:	e8 4f df ff ff       	call   f01000a0 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f0102151:	83 ec 08             	sub    $0x8,%esp
f0102154:	6a 02                	push   $0x2
f0102156:	68 00 00 11 00       	push   $0x110000
f010215b:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102160:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102165:	a1 48 cc 17 f0       	mov    0xf017cc48,%eax
f010216a:	e8 01 ed ff ff       	call   f0100e70 <boot_map_region>
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	//cprintf("%x\n",KERNBASE);
	boot_map_region(kern_pgdir, KERNBASE, -KERNBASE, 0, PTE_W);
f010216f:	83 c4 08             	add    $0x8,%esp
f0102172:	6a 02                	push   $0x2
f0102174:	6a 00                	push   $0x0
f0102176:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f010217b:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102180:	a1 48 cc 17 f0       	mov    0xf017cc48,%eax
f0102185:	e8 e6 ec ff ff       	call   f0100e70 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f010218a:	8b 1d 48 cc 17 f0    	mov    0xf017cc48,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102190:	a1 44 cc 17 f0       	mov    0xf017cc44,%eax
f0102195:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102198:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f010219f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01021a4:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01021a7:	8b 3d 4c cc 17 f0    	mov    0xf017cc4c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01021ad:	89 7d d0             	mov    %edi,-0x30(%ebp)
f01021b0:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01021b3:	be 00 00 00 00       	mov    $0x0,%esi
f01021b8:	eb 55                	jmp    f010220f <mem_init+0x1235>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01021ba:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
f01021c0:	89 d8                	mov    %ebx,%eax
f01021c2:	e8 66 e7 ff ff       	call   f010092d <check_va2pa>
f01021c7:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f01021ce:	77 15                	ja     f01021e5 <mem_init+0x120b>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01021d0:	57                   	push   %edi
f01021d1:	68 c8 4d 10 f0       	push   $0xf0104dc8
f01021d6:	68 0e 03 00 00       	push   $0x30e
f01021db:	68 41 54 10 f0       	push   $0xf0105441
f01021e0:	e8 bb de ff ff       	call   f01000a0 <_panic>
f01021e5:	8d 94 37 00 00 00 10 	lea    0x10000000(%edi,%esi,1),%edx
f01021ec:	39 d0                	cmp    %edx,%eax
f01021ee:	74 19                	je     f0102209 <mem_init+0x122f>
f01021f0:	68 44 52 10 f0       	push   $0xf0105244
f01021f5:	68 67 54 10 f0       	push   $0xf0105467
f01021fa:	68 0e 03 00 00       	push   $0x30e
f01021ff:	68 41 54 10 f0       	push   $0xf0105441
f0102204:	e8 97 de ff ff       	call   f01000a0 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102209:	81 c6 00 10 00 00    	add    $0x1000,%esi
f010220f:	39 75 d4             	cmp    %esi,-0x2c(%ebp)
f0102212:	77 a6                	ja     f01021ba <mem_init+0x11e0>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102214:	8b 3d 8c bf 17 f0    	mov    0xf017bf8c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010221a:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f010221d:	be 00 00 c0 ee       	mov    $0xeec00000,%esi
f0102222:	89 f2                	mov    %esi,%edx
f0102224:	89 d8                	mov    %ebx,%eax
f0102226:	e8 02 e7 ff ff       	call   f010092d <check_va2pa>
f010222b:	81 7d d4 ff ff ff ef 	cmpl   $0xefffffff,-0x2c(%ebp)
f0102232:	77 15                	ja     f0102249 <mem_init+0x126f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102234:	57                   	push   %edi
f0102235:	68 c8 4d 10 f0       	push   $0xf0104dc8
f010223a:	68 13 03 00 00       	push   $0x313
f010223f:	68 41 54 10 f0       	push   $0xf0105441
f0102244:	e8 57 de ff ff       	call   f01000a0 <_panic>
f0102249:	8d 94 37 00 00 40 21 	lea    0x21400000(%edi,%esi,1),%edx
f0102250:	39 c2                	cmp    %eax,%edx
f0102252:	74 19                	je     f010226d <mem_init+0x1293>
f0102254:	68 78 52 10 f0       	push   $0xf0105278
f0102259:	68 67 54 10 f0       	push   $0xf0105467
f010225e:	68 13 03 00 00       	push   $0x313
f0102263:	68 41 54 10 f0       	push   $0xf0105441
f0102268:	e8 33 de ff ff       	call   f01000a0 <_panic>
f010226d:	81 c6 00 10 00 00    	add    $0x1000,%esi
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102273:	81 fe 00 80 c1 ee    	cmp    $0xeec18000,%esi
f0102279:	75 a7                	jne    f0102222 <mem_init+0x1248>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010227b:	8b 7d cc             	mov    -0x34(%ebp),%edi
f010227e:	c1 e7 0c             	shl    $0xc,%edi
f0102281:	be 00 00 00 00       	mov    $0x0,%esi
f0102286:	eb 30                	jmp    f01022b8 <mem_init+0x12de>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102288:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
f010228e:	89 d8                	mov    %ebx,%eax
f0102290:	e8 98 e6 ff ff       	call   f010092d <check_va2pa>
f0102295:	39 c6                	cmp    %eax,%esi
f0102297:	74 19                	je     f01022b2 <mem_init+0x12d8>
f0102299:	68 ac 52 10 f0       	push   $0xf01052ac
f010229e:	68 67 54 10 f0       	push   $0xf0105467
f01022a3:	68 17 03 00 00       	push   $0x317
f01022a8:	68 41 54 10 f0       	push   $0xf0105441
f01022ad:	e8 ee dd ff ff       	call   f01000a0 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01022b2:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01022b8:	39 fe                	cmp    %edi,%esi
f01022ba:	72 cc                	jb     f0102288 <mem_init+0x12ae>
f01022bc:	be 00 80 ff ef       	mov    $0xefff8000,%esi
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f01022c1:	89 f2                	mov    %esi,%edx
f01022c3:	89 d8                	mov    %ebx,%eax
f01022c5:	e8 63 e6 ff ff       	call   f010092d <check_va2pa>
f01022ca:	8d 96 00 80 11 10    	lea    0x10118000(%esi),%edx
f01022d0:	39 c2                	cmp    %eax,%edx
f01022d2:	74 19                	je     f01022ed <mem_init+0x1313>
f01022d4:	68 d4 52 10 f0       	push   $0xf01052d4
f01022d9:	68 67 54 10 f0       	push   $0xf0105467
f01022de:	68 1b 03 00 00       	push   $0x31b
f01022e3:	68 41 54 10 f0       	push   $0xf0105441
f01022e8:	e8 b3 dd ff ff       	call   f01000a0 <_panic>
f01022ed:	81 c6 00 10 00 00    	add    $0x1000,%esi
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01022f3:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f01022f9:	75 c6                	jne    f01022c1 <mem_init+0x12e7>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01022fb:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102300:	89 d8                	mov    %ebx,%eax
f0102302:	e8 26 e6 ff ff       	call   f010092d <check_va2pa>
f0102307:	83 f8 ff             	cmp    $0xffffffff,%eax
f010230a:	74 51                	je     f010235d <mem_init+0x1383>
f010230c:	68 1c 53 10 f0       	push   $0xf010531c
f0102311:	68 67 54 10 f0       	push   $0xf0105467
f0102316:	68 1c 03 00 00       	push   $0x31c
f010231b:	68 41 54 10 f0       	push   $0xf0105441
f0102320:	e8 7b dd ff ff       	call   f01000a0 <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102325:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f010232a:	72 36                	jb     f0102362 <mem_init+0x1388>
f010232c:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0102331:	76 07                	jbe    f010233a <mem_init+0x1360>
f0102333:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102338:	75 28                	jne    f0102362 <mem_init+0x1388>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
f010233a:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f010233e:	0f 85 83 00 00 00    	jne    f01023c7 <mem_init+0x13ed>
f0102344:	68 f4 56 10 f0       	push   $0xf01056f4
f0102349:	68 67 54 10 f0       	push   $0xf0105467
f010234e:	68 25 03 00 00       	push   $0x325
f0102353:	68 41 54 10 f0       	push   $0xf0105441
f0102358:	e8 43 dd ff ff       	call   f01000a0 <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f010235d:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102362:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102367:	76 3f                	jbe    f01023a8 <mem_init+0x13ce>
				assert(pgdir[i] & PTE_P);
f0102369:	8b 14 83             	mov    (%ebx,%eax,4),%edx
f010236c:	f6 c2 01             	test   $0x1,%dl
f010236f:	75 19                	jne    f010238a <mem_init+0x13b0>
f0102371:	68 f4 56 10 f0       	push   $0xf01056f4
f0102376:	68 67 54 10 f0       	push   $0xf0105467
f010237b:	68 29 03 00 00       	push   $0x329
f0102380:	68 41 54 10 f0       	push   $0xf0105441
f0102385:	e8 16 dd ff ff       	call   f01000a0 <_panic>
				assert(pgdir[i] & PTE_W);
f010238a:	f6 c2 02             	test   $0x2,%dl
f010238d:	75 38                	jne    f01023c7 <mem_init+0x13ed>
f010238f:	68 05 57 10 f0       	push   $0xf0105705
f0102394:	68 67 54 10 f0       	push   $0xf0105467
f0102399:	68 2a 03 00 00       	push   $0x32a
f010239e:	68 41 54 10 f0       	push   $0xf0105441
f01023a3:	e8 f8 dc ff ff       	call   f01000a0 <_panic>
			} else
				assert(pgdir[i] == 0);
f01023a8:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f01023ac:	74 19                	je     f01023c7 <mem_init+0x13ed>
f01023ae:	68 16 57 10 f0       	push   $0xf0105716
f01023b3:	68 67 54 10 f0       	push   $0xf0105467
f01023b8:	68 2c 03 00 00       	push   $0x32c
f01023bd:	68 41 54 10 f0       	push   $0xf0105441
f01023c2:	e8 d9 dc ff ff       	call   f01000a0 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f01023c7:	83 c0 01             	add    $0x1,%eax
f01023ca:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f01023cf:	0f 86 50 ff ff ff    	jbe    f0102325 <mem_init+0x134b>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f01023d5:	83 ec 0c             	sub    $0xc,%esp
f01023d8:	68 4c 53 10 f0       	push   $0xf010534c
f01023dd:	e8 c7 0a 00 00       	call   f0102ea9 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f01023e2:	a1 48 cc 17 f0       	mov    0xf017cc48,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01023e7:	83 c4 10             	add    $0x10,%esp
f01023ea:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01023ef:	77 15                	ja     f0102406 <mem_init+0x142c>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01023f1:	50                   	push   %eax
f01023f2:	68 c8 4d 10 f0       	push   $0xf0104dc8
f01023f7:	68 e8 00 00 00       	push   $0xe8
f01023fc:	68 41 54 10 f0       	push   $0xf0105441
f0102401:	e8 9a dc ff ff       	call   f01000a0 <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102406:	05 00 00 00 10       	add    $0x10000000,%eax
f010240b:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f010240e:	b8 00 00 00 00       	mov    $0x0,%eax
f0102413:	e8 79 e5 ff ff       	call   f0100991 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0102418:	0f 20 c0             	mov    %cr0,%eax
f010241b:	83 e0 f3             	and    $0xfffffff3,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f010241e:	0d 23 00 05 80       	or     $0x80050023,%eax
f0102423:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102426:	83 ec 0c             	sub    $0xc,%esp
f0102429:	6a 00                	push   $0x0
f010242b:	e8 cf e8 ff ff       	call   f0100cff <page_alloc>
f0102430:	89 c3                	mov    %eax,%ebx
f0102432:	83 c4 10             	add    $0x10,%esp
f0102435:	85 c0                	test   %eax,%eax
f0102437:	75 19                	jne    f0102452 <mem_init+0x1478>
f0102439:	68 12 55 10 f0       	push   $0xf0105512
f010243e:	68 67 54 10 f0       	push   $0xf0105467
f0102443:	68 ec 03 00 00       	push   $0x3ec
f0102448:	68 41 54 10 f0       	push   $0xf0105441
f010244d:	e8 4e dc ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f0102452:	83 ec 0c             	sub    $0xc,%esp
f0102455:	6a 00                	push   $0x0
f0102457:	e8 a3 e8 ff ff       	call   f0100cff <page_alloc>
f010245c:	89 c7                	mov    %eax,%edi
f010245e:	83 c4 10             	add    $0x10,%esp
f0102461:	85 c0                	test   %eax,%eax
f0102463:	75 19                	jne    f010247e <mem_init+0x14a4>
f0102465:	68 28 55 10 f0       	push   $0xf0105528
f010246a:	68 67 54 10 f0       	push   $0xf0105467
f010246f:	68 ed 03 00 00       	push   $0x3ed
f0102474:	68 41 54 10 f0       	push   $0xf0105441
f0102479:	e8 22 dc ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f010247e:	83 ec 0c             	sub    $0xc,%esp
f0102481:	6a 00                	push   $0x0
f0102483:	e8 77 e8 ff ff       	call   f0100cff <page_alloc>
f0102488:	89 c6                	mov    %eax,%esi
f010248a:	83 c4 10             	add    $0x10,%esp
f010248d:	85 c0                	test   %eax,%eax
f010248f:	75 19                	jne    f01024aa <mem_init+0x14d0>
f0102491:	68 3e 55 10 f0       	push   $0xf010553e
f0102496:	68 67 54 10 f0       	push   $0xf0105467
f010249b:	68 ee 03 00 00       	push   $0x3ee
f01024a0:	68 41 54 10 f0       	push   $0xf0105441
f01024a5:	e8 f6 db ff ff       	call   f01000a0 <_panic>
	page_free(pp0);
f01024aa:	83 ec 0c             	sub    $0xc,%esp
f01024ad:	53                   	push   %ebx
f01024ae:	e8 bc e8 ff ff       	call   f0100d6f <page_free>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01024b3:	89 f8                	mov    %edi,%eax
f01024b5:	2b 05 4c cc 17 f0    	sub    0xf017cc4c,%eax
f01024bb:	c1 f8 03             	sar    $0x3,%eax
f01024be:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01024c1:	89 c2                	mov    %eax,%edx
f01024c3:	c1 ea 0c             	shr    $0xc,%edx
f01024c6:	83 c4 10             	add    $0x10,%esp
f01024c9:	3b 15 44 cc 17 f0    	cmp    0xf017cc44,%edx
f01024cf:	72 12                	jb     f01024e3 <mem_init+0x1509>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01024d1:	50                   	push   %eax
f01024d2:	68 84 4c 10 f0       	push   $0xf0104c84
f01024d7:	6a 56                	push   $0x56
f01024d9:	68 4d 54 10 f0       	push   $0xf010544d
f01024de:	e8 bd db ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f01024e3:	83 ec 04             	sub    $0x4,%esp
f01024e6:	68 00 10 00 00       	push   $0x1000
f01024eb:	6a 01                	push   $0x1
f01024ed:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01024f2:	50                   	push   %eax
f01024f3:	e8 aa 1d 00 00       	call   f01042a2 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01024f8:	89 f0                	mov    %esi,%eax
f01024fa:	2b 05 4c cc 17 f0    	sub    0xf017cc4c,%eax
f0102500:	c1 f8 03             	sar    $0x3,%eax
f0102503:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102506:	89 c2                	mov    %eax,%edx
f0102508:	c1 ea 0c             	shr    $0xc,%edx
f010250b:	83 c4 10             	add    $0x10,%esp
f010250e:	3b 15 44 cc 17 f0    	cmp    0xf017cc44,%edx
f0102514:	72 12                	jb     f0102528 <mem_init+0x154e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102516:	50                   	push   %eax
f0102517:	68 84 4c 10 f0       	push   $0xf0104c84
f010251c:	6a 56                	push   $0x56
f010251e:	68 4d 54 10 f0       	push   $0xf010544d
f0102523:	e8 78 db ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102528:	83 ec 04             	sub    $0x4,%esp
f010252b:	68 00 10 00 00       	push   $0x1000
f0102530:	6a 02                	push   $0x2
f0102532:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102537:	50                   	push   %eax
f0102538:	e8 65 1d 00 00       	call   f01042a2 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f010253d:	6a 02                	push   $0x2
f010253f:	68 00 10 00 00       	push   $0x1000
f0102544:	57                   	push   %edi
f0102545:	ff 35 48 cc 17 f0    	pushl  0xf017cc48
f010254b:	e8 24 ea ff ff       	call   f0100f74 <page_insert>
	assert(pp1->pp_ref == 1);
f0102550:	83 c4 20             	add    $0x20,%esp
f0102553:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102558:	74 19                	je     f0102573 <mem_init+0x1599>
f010255a:	68 0f 56 10 f0       	push   $0xf010560f
f010255f:	68 67 54 10 f0       	push   $0xf0105467
f0102564:	68 f3 03 00 00       	push   $0x3f3
f0102569:	68 41 54 10 f0       	push   $0xf0105441
f010256e:	e8 2d db ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102573:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f010257a:	01 01 01 
f010257d:	74 19                	je     f0102598 <mem_init+0x15be>
f010257f:	68 6c 53 10 f0       	push   $0xf010536c
f0102584:	68 67 54 10 f0       	push   $0xf0105467
f0102589:	68 f4 03 00 00       	push   $0x3f4
f010258e:	68 41 54 10 f0       	push   $0xf0105441
f0102593:	e8 08 db ff ff       	call   f01000a0 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102598:	6a 02                	push   $0x2
f010259a:	68 00 10 00 00       	push   $0x1000
f010259f:	56                   	push   %esi
f01025a0:	ff 35 48 cc 17 f0    	pushl  0xf017cc48
f01025a6:	e8 c9 e9 ff ff       	call   f0100f74 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f01025ab:	83 c4 10             	add    $0x10,%esp
f01025ae:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f01025b5:	02 02 02 
f01025b8:	74 19                	je     f01025d3 <mem_init+0x15f9>
f01025ba:	68 90 53 10 f0       	push   $0xf0105390
f01025bf:	68 67 54 10 f0       	push   $0xf0105467
f01025c4:	68 f6 03 00 00       	push   $0x3f6
f01025c9:	68 41 54 10 f0       	push   $0xf0105441
f01025ce:	e8 cd da ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f01025d3:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01025d8:	74 19                	je     f01025f3 <mem_init+0x1619>
f01025da:	68 31 56 10 f0       	push   $0xf0105631
f01025df:	68 67 54 10 f0       	push   $0xf0105467
f01025e4:	68 f7 03 00 00       	push   $0x3f7
f01025e9:	68 41 54 10 f0       	push   $0xf0105441
f01025ee:	e8 ad da ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f01025f3:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f01025f8:	74 19                	je     f0102613 <mem_init+0x1639>
f01025fa:	68 9b 56 10 f0       	push   $0xf010569b
f01025ff:	68 67 54 10 f0       	push   $0xf0105467
f0102604:	68 f8 03 00 00       	push   $0x3f8
f0102609:	68 41 54 10 f0       	push   $0xf0105441
f010260e:	e8 8d da ff ff       	call   f01000a0 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102613:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f010261a:	03 03 03 
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010261d:	89 f0                	mov    %esi,%eax
f010261f:	2b 05 4c cc 17 f0    	sub    0xf017cc4c,%eax
f0102625:	c1 f8 03             	sar    $0x3,%eax
f0102628:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010262b:	89 c2                	mov    %eax,%edx
f010262d:	c1 ea 0c             	shr    $0xc,%edx
f0102630:	3b 15 44 cc 17 f0    	cmp    0xf017cc44,%edx
f0102636:	72 12                	jb     f010264a <mem_init+0x1670>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102638:	50                   	push   %eax
f0102639:	68 84 4c 10 f0       	push   $0xf0104c84
f010263e:	6a 56                	push   $0x56
f0102640:	68 4d 54 10 f0       	push   $0xf010544d
f0102645:	e8 56 da ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f010264a:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102651:	03 03 03 
f0102654:	74 19                	je     f010266f <mem_init+0x1695>
f0102656:	68 b4 53 10 f0       	push   $0xf01053b4
f010265b:	68 67 54 10 f0       	push   $0xf0105467
f0102660:	68 fa 03 00 00       	push   $0x3fa
f0102665:	68 41 54 10 f0       	push   $0xf0105441
f010266a:	e8 31 da ff ff       	call   f01000a0 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f010266f:	83 ec 08             	sub    $0x8,%esp
f0102672:	68 00 10 00 00       	push   $0x1000
f0102677:	ff 35 48 cc 17 f0    	pushl  0xf017cc48
f010267d:	e8 af e8 ff ff       	call   f0100f31 <page_remove>
	assert(pp2->pp_ref == 0);
f0102682:	83 c4 10             	add    $0x10,%esp
f0102685:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010268a:	74 19                	je     f01026a5 <mem_init+0x16cb>
f010268c:	68 69 56 10 f0       	push   $0xf0105669
f0102691:	68 67 54 10 f0       	push   $0xf0105467
f0102696:	68 fc 03 00 00       	push   $0x3fc
f010269b:	68 41 54 10 f0       	push   $0xf0105441
f01026a0:	e8 fb d9 ff ff       	call   f01000a0 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01026a5:	8b 0d 48 cc 17 f0    	mov    0xf017cc48,%ecx
f01026ab:	8b 11                	mov    (%ecx),%edx
f01026ad:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01026b3:	89 d8                	mov    %ebx,%eax
f01026b5:	2b 05 4c cc 17 f0    	sub    0xf017cc4c,%eax
f01026bb:	c1 f8 03             	sar    $0x3,%eax
f01026be:	c1 e0 0c             	shl    $0xc,%eax
f01026c1:	39 c2                	cmp    %eax,%edx
f01026c3:	74 19                	je     f01026de <mem_init+0x1704>
f01026c5:	68 c4 4e 10 f0       	push   $0xf0104ec4
f01026ca:	68 67 54 10 f0       	push   $0xf0105467
f01026cf:	68 ff 03 00 00       	push   $0x3ff
f01026d4:	68 41 54 10 f0       	push   $0xf0105441
f01026d9:	e8 c2 d9 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f01026de:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f01026e4:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01026e9:	74 19                	je     f0102704 <mem_init+0x172a>
f01026eb:	68 20 56 10 f0       	push   $0xf0105620
f01026f0:	68 67 54 10 f0       	push   $0xf0105467
f01026f5:	68 01 04 00 00       	push   $0x401
f01026fa:	68 41 54 10 f0       	push   $0xf0105441
f01026ff:	e8 9c d9 ff ff       	call   f01000a0 <_panic>
	pp0->pp_ref = 0;
f0102704:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f010270a:	83 ec 0c             	sub    $0xc,%esp
f010270d:	53                   	push   %ebx
f010270e:	e8 5c e6 ff ff       	call   f0100d6f <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102713:	c7 04 24 e0 53 10 f0 	movl   $0xf01053e0,(%esp)
f010271a:	e8 8a 07 00 00       	call   f0102ea9 <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f010271f:	83 c4 10             	add    $0x10,%esp
f0102722:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102725:	5b                   	pop    %ebx
f0102726:	5e                   	pop    %esi
f0102727:	5f                   	pop    %edi
f0102728:	5d                   	pop    %ebp
f0102729:	c3                   	ret    

f010272a <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f010272a:	55                   	push   %ebp
f010272b:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010272d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102730:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0102733:	5d                   	pop    %ebp
f0102734:	c3                   	ret    

f0102735 <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f0102735:	55                   	push   %ebp
f0102736:	89 e5                	mov    %esp,%ebp
f0102738:	57                   	push   %edi
f0102739:	56                   	push   %esi
f010273a:	53                   	push   %ebx
f010273b:	83 ec 1c             	sub    $0x1c,%esp
f010273e:	8b 7d 08             	mov    0x8(%ebp),%edi
f0102741:	8b 45 0c             	mov    0xc(%ebp),%eax
	// LAB 3: Your code here.
	uintptr_t i;
	pte_t *pte;

	perm=perm | PTE_U | PTE_P;
f0102744:	8b 75 14             	mov    0x14(%ebp),%esi
f0102747:	83 ce 05             	or     $0x5,%esi

	for(i=((uintptr_t)va); i<=((uintptr_t)va+len-1); i=i+PGSIZE) 
f010274a:	89 c3                	mov    %eax,%ebx
f010274c:	8b 55 10             	mov    0x10(%ebp),%edx
f010274f:	8d 44 10 ff          	lea    -0x1(%eax,%edx,1),%eax
f0102753:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102756:	eb 4b                	jmp    f01027a3 <user_mem_check+0x6e>
	{
		if(i >= ULIM) 
f0102758:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f010275e:	76 0d                	jbe    f010276d <user_mem_check+0x38>
		{
			user_mem_check_addr=i;
f0102760:	89 1d 7c bf 17 f0    	mov    %ebx,0xf017bf7c
			return -E_FAULT;
f0102766:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f010276b:	eb 40                	jmp    f01027ad <user_mem_check+0x78>
		}

		pte=pgdir_walk(env->env_pgdir, (void*)i, 0);
f010276d:	83 ec 04             	sub    $0x4,%esp
f0102770:	6a 00                	push   $0x0
f0102772:	53                   	push   %ebx
f0102773:	ff 77 5c             	pushl  0x5c(%edi)
f0102776:	e8 2a e6 ff ff       	call   f0100da5 <pgdir_walk>
					
		if((pte == NULL) || ((*pte & perm) != perm)) 
f010277b:	83 c4 10             	add    $0x10,%esp
f010277e:	85 c0                	test   %eax,%eax
f0102780:	74 08                	je     f010278a <user_mem_check+0x55>
f0102782:	89 f1                	mov    %esi,%ecx
f0102784:	23 08                	and    (%eax),%ecx
f0102786:	39 ce                	cmp    %ecx,%esi
f0102788:	74 0d                	je     f0102797 <user_mem_check+0x62>
		{
			user_mem_check_addr=i;
f010278a:	89 1d 7c bf 17 f0    	mov    %ebx,0xf017bf7c
			return -E_FAULT;
f0102790:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102795:	eb 16                	jmp    f01027ad <user_mem_check+0x78>
		}

		i=ROUNDDOWN(i, PGSIZE);
f0102797:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	uintptr_t i;
	pte_t *pte;

	perm=perm | PTE_U | PTE_P;

	for(i=((uintptr_t)va); i<=((uintptr_t)va+len-1); i=i+PGSIZE) 
f010279d:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01027a3:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f01027a6:	76 b0                	jbe    f0102758 <user_mem_check+0x23>
		}

		i=ROUNDDOWN(i, PGSIZE);
	}
	
	return 0;
f01027a8:	b8 00 00 00 00       	mov    $0x0,%eax

}
f01027ad:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01027b0:	5b                   	pop    %ebx
f01027b1:	5e                   	pop    %esi
f01027b2:	5f                   	pop    %edi
f01027b3:	5d                   	pop    %ebp
f01027b4:	c3                   	ret    

f01027b5 <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f01027b5:	55                   	push   %ebp
f01027b6:	89 e5                	mov    %esp,%ebp
f01027b8:	53                   	push   %ebx
f01027b9:	83 ec 04             	sub    $0x4,%esp
f01027bc:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f01027bf:	8b 45 14             	mov    0x14(%ebp),%eax
f01027c2:	83 c8 04             	or     $0x4,%eax
f01027c5:	50                   	push   %eax
f01027c6:	ff 75 10             	pushl  0x10(%ebp)
f01027c9:	ff 75 0c             	pushl  0xc(%ebp)
f01027cc:	53                   	push   %ebx
f01027cd:	e8 63 ff ff ff       	call   f0102735 <user_mem_check>
f01027d2:	83 c4 10             	add    $0x10,%esp
f01027d5:	85 c0                	test   %eax,%eax
f01027d7:	79 21                	jns    f01027fa <user_mem_assert+0x45>
		cprintf("[%08x] user_mem_check assertion failure for "
f01027d9:	83 ec 04             	sub    $0x4,%esp
f01027dc:	ff 35 7c bf 17 f0    	pushl  0xf017bf7c
f01027e2:	ff 73 48             	pushl  0x48(%ebx)
f01027e5:	68 0c 54 10 f0       	push   $0xf010540c
f01027ea:	e8 ba 06 00 00       	call   f0102ea9 <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f01027ef:	89 1c 24             	mov    %ebx,(%esp)
f01027f2:	e8 99 05 00 00       	call   f0102d90 <env_destroy>
f01027f7:	83 c4 10             	add    $0x10,%esp
	}
}
f01027fa:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01027fd:	c9                   	leave  
f01027fe:	c3                   	ret    

f01027ff <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f01027ff:	55                   	push   %ebp
f0102800:	89 e5                	mov    %esp,%ebp
f0102802:	57                   	push   %edi
f0102803:	56                   	push   %esi
f0102804:	53                   	push   %ebx
f0102805:	83 ec 0c             	sub    $0xc,%esp
f0102808:	89 c7                	mov    %eax,%edi
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	
	void *start = ROUNDDOWN(va,PGSIZE);
f010280a:	89 d3                	mov    %edx,%ebx
f010280c:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	void *end = ROUNDUP(va + len, PGSIZE);
f0102812:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f0102819:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	
	for(; start < end; start = start + PGSIZE)
f010281f:	eb 3d                	jmp    f010285e <region_alloc+0x5f>
	{
		struct PageInfo *p = page_alloc(!ALLOC_ZERO);
f0102821:	83 ec 0c             	sub    $0xc,%esp
f0102824:	6a 00                	push   $0x0
f0102826:	e8 d4 e4 ff ff       	call   f0100cff <page_alloc>
		if(!p)
f010282b:	83 c4 10             	add    $0x10,%esp
f010282e:	85 c0                	test   %eax,%eax
f0102830:	75 17                	jne    f0102849 <region_alloc+0x4a>
			panic("Allocation attempt failed");
f0102832:	83 ec 04             	sub    $0x4,%esp
f0102835:	68 24 57 10 f0       	push   $0xf0105724
f010283a:	68 21 01 00 00       	push   $0x121
f010283f:	68 3e 57 10 f0       	push   $0xf010573e
f0102844:	e8 57 d8 ff ff       	call   f01000a0 <_panic>
		page_insert(e->env_pgdir, p, start, PTE_W|PTE_U);		
f0102849:	6a 06                	push   $0x6
f010284b:	53                   	push   %ebx
f010284c:	50                   	push   %eax
f010284d:	ff 77 5c             	pushl  0x5c(%edi)
f0102850:	e8 1f e7 ff ff       	call   f0100f74 <page_insert>
	//   (Watch out for corner-cases!)
	
	void *start = ROUNDDOWN(va,PGSIZE);
	void *end = ROUNDUP(va + len, PGSIZE);
	
	for(; start < end; start = start + PGSIZE)
f0102855:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010285b:	83 c4 10             	add    $0x10,%esp
f010285e:	39 f3                	cmp    %esi,%ebx
f0102860:	72 bf                	jb     f0102821 <region_alloc+0x22>
		struct PageInfo *p = page_alloc(!ALLOC_ZERO);
		if(!p)
			panic("Allocation attempt failed");
		page_insert(e->env_pgdir, p, start, PTE_W|PTE_U);		
	}
}
f0102862:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102865:	5b                   	pop    %ebx
f0102866:	5e                   	pop    %esi
f0102867:	5f                   	pop    %edi
f0102868:	5d                   	pop    %ebp
f0102869:	c3                   	ret    

f010286a <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f010286a:	55                   	push   %ebp
f010286b:	89 e5                	mov    %esp,%ebp
f010286d:	8b 55 08             	mov    0x8(%ebp),%edx
f0102870:	8b 4d 10             	mov    0x10(%ebp),%ecx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0102873:	85 d2                	test   %edx,%edx
f0102875:	75 11                	jne    f0102888 <envid2env+0x1e>
		*env_store = curenv;
f0102877:	a1 88 bf 17 f0       	mov    0xf017bf88,%eax
f010287c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010287f:	89 01                	mov    %eax,(%ecx)
		return 0;
f0102881:	b8 00 00 00 00       	mov    $0x0,%eax
f0102886:	eb 5e                	jmp    f01028e6 <envid2env+0x7c>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0102888:	89 d0                	mov    %edx,%eax
f010288a:	25 ff 03 00 00       	and    $0x3ff,%eax
f010288f:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0102892:	c1 e0 05             	shl    $0x5,%eax
f0102895:	03 05 8c bf 17 f0    	add    0xf017bf8c,%eax
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f010289b:	83 78 54 00          	cmpl   $0x0,0x54(%eax)
f010289f:	74 05                	je     f01028a6 <envid2env+0x3c>
f01028a1:	3b 50 48             	cmp    0x48(%eax),%edx
f01028a4:	74 10                	je     f01028b6 <envid2env+0x4c>
		*env_store = 0;
f01028a6:	8b 45 0c             	mov    0xc(%ebp),%eax
f01028a9:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f01028af:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01028b4:	eb 30                	jmp    f01028e6 <envid2env+0x7c>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f01028b6:	84 c9                	test   %cl,%cl
f01028b8:	74 22                	je     f01028dc <envid2env+0x72>
f01028ba:	8b 15 88 bf 17 f0    	mov    0xf017bf88,%edx
f01028c0:	39 d0                	cmp    %edx,%eax
f01028c2:	74 18                	je     f01028dc <envid2env+0x72>
f01028c4:	8b 4a 48             	mov    0x48(%edx),%ecx
f01028c7:	39 48 4c             	cmp    %ecx,0x4c(%eax)
f01028ca:	74 10                	je     f01028dc <envid2env+0x72>
		*env_store = 0;
f01028cc:	8b 45 0c             	mov    0xc(%ebp),%eax
f01028cf:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f01028d5:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01028da:	eb 0a                	jmp    f01028e6 <envid2env+0x7c>
	}

	*env_store = e;
f01028dc:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01028df:	89 01                	mov    %eax,(%ecx)
	return 0;
f01028e1:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01028e6:	5d                   	pop    %ebp
f01028e7:	c3                   	ret    

f01028e8 <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f01028e8:	55                   	push   %ebp
f01028e9:	89 e5                	mov    %esp,%ebp
}

static __inline void
lgdt(void *p)
{
	__asm __volatile("lgdt (%0)" : : "r" (p));
f01028eb:	b8 00 a3 11 f0       	mov    $0xf011a300,%eax
f01028f0:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f01028f3:	b8 23 00 00 00       	mov    $0x23,%eax
f01028f8:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f01028fa:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f01028fc:	b8 10 00 00 00       	mov    $0x10,%eax
f0102901:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f0102903:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f0102905:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));
f0102907:	ea 0e 29 10 f0 08 00 	ljmp   $0x8,$0xf010290e
}

static __inline void
lldt(uint16_t sel)
{
	__asm __volatile("lldt %0" : : "r" (sel));
f010290e:	b8 00 00 00 00       	mov    $0x0,%eax
f0102913:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f0102916:	5d                   	pop    %ebp
f0102917:	c3                   	ret    

f0102918 <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f0102918:	55                   	push   %ebp
f0102919:	89 e5                	mov    %esp,%ebp
f010291b:	56                   	push   %esi
f010291c:	53                   	push   %ebx
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	for (i = NENV - 1; i >= 0; --i) {
		envs[i].env_status=ENV_FREE;
f010291d:	8b 35 8c bf 17 f0    	mov    0xf017bf8c,%esi
f0102923:	8b 15 90 bf 17 f0    	mov    0xf017bf90,%edx
f0102929:	8d 86 a0 7f 01 00    	lea    0x17fa0(%esi),%eax
f010292f:	8d 5e a0             	lea    -0x60(%esi),%ebx
f0102932:	89 c1                	mov    %eax,%ecx
f0102934:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
		envs[i].env_id = 0;
f010293b:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_link = env_free_list;
f0102942:	89 50 44             	mov    %edx,0x44(%eax)
f0102945:	83 e8 60             	sub    $0x60,%eax
		env_free_list = &envs[i];
f0102948:	89 ca                	mov    %ecx,%edx
env_init(void)
{
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	for (i = NENV - 1; i >= 0; --i) {
f010294a:	39 d8                	cmp    %ebx,%eax
f010294c:	75 e4                	jne    f0102932 <env_init+0x1a>
f010294e:	89 35 90 bf 17 f0    	mov    %esi,0xf017bf90
		envs[i].env_link = env_free_list;
		env_free_list = &envs[i];
	}
	
	// Per-CPU part of the initialization
	env_init_percpu();
f0102954:	e8 8f ff ff ff       	call   f01028e8 <env_init_percpu>
}
f0102959:	5b                   	pop    %ebx
f010295a:	5e                   	pop    %esi
f010295b:	5d                   	pop    %ebp
f010295c:	c3                   	ret    

f010295d <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f010295d:	55                   	push   %ebp
f010295e:	89 e5                	mov    %esp,%ebp
f0102960:	53                   	push   %ebx
f0102961:	83 ec 04             	sub    $0x4,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f0102964:	8b 1d 90 bf 17 f0    	mov    0xf017bf90,%ebx
f010296a:	85 db                	test   %ebx,%ebx
f010296c:	0f 84 43 01 00 00    	je     f0102ab5 <env_alloc+0x158>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f0102972:	83 ec 0c             	sub    $0xc,%esp
f0102975:	6a 01                	push   $0x1
f0102977:	e8 83 e3 ff ff       	call   f0100cff <page_alloc>
f010297c:	83 c4 10             	add    $0x10,%esp
f010297f:	85 c0                	test   %eax,%eax
f0102981:	0f 84 35 01 00 00    	je     f0102abc <env_alloc+0x15f>
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.

	p->pp_ref++;
f0102987:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010298c:	2b 05 4c cc 17 f0    	sub    0xf017cc4c,%eax
f0102992:	c1 f8 03             	sar    $0x3,%eax
f0102995:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102998:	89 c2                	mov    %eax,%edx
f010299a:	c1 ea 0c             	shr    $0xc,%edx
f010299d:	3b 15 44 cc 17 f0    	cmp    0xf017cc44,%edx
f01029a3:	72 12                	jb     f01029b7 <env_alloc+0x5a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01029a5:	50                   	push   %eax
f01029a6:	68 84 4c 10 f0       	push   $0xf0104c84
f01029ab:	6a 56                	push   $0x56
f01029ad:	68 4d 54 10 f0       	push   $0xf010544d
f01029b2:	e8 e9 d6 ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f01029b7:	2d 00 00 00 10       	sub    $0x10000000,%eax
	e->env_pgdir = (pde_t *) page2kva(p);
f01029bc:	89 43 5c             	mov    %eax,0x5c(%ebx)
	memcpy(e->env_pgdir, kern_pgdir, PGSIZE);
f01029bf:	83 ec 04             	sub    $0x4,%esp
f01029c2:	68 00 10 00 00       	push   $0x1000
f01029c7:	ff 35 48 cc 17 f0    	pushl  0xf017cc48
f01029cd:	50                   	push   %eax
f01029ce:	e8 84 19 00 00       	call   f0104357 <memcpy>

	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f01029d3:	8b 43 5c             	mov    0x5c(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01029d6:	83 c4 10             	add    $0x10,%esp
f01029d9:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01029de:	77 15                	ja     f01029f5 <env_alloc+0x98>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01029e0:	50                   	push   %eax
f01029e1:	68 c8 4d 10 f0       	push   $0xf0104dc8
f01029e6:	68 c4 00 00 00       	push   $0xc4
f01029eb:	68 3e 57 10 f0       	push   $0xf010573e
f01029f0:	e8 ab d6 ff ff       	call   f01000a0 <_panic>
f01029f5:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01029fb:	83 ca 05             	or     $0x5,%edx
f01029fe:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f0102a04:	8b 43 48             	mov    0x48(%ebx),%eax
f0102a07:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f0102a0c:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0102a11:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102a16:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f0102a19:	89 da                	mov    %ebx,%edx
f0102a1b:	2b 15 8c bf 17 f0    	sub    0xf017bf8c,%edx
f0102a21:	c1 fa 05             	sar    $0x5,%edx
f0102a24:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0102a2a:	09 d0                	or     %edx,%eax
f0102a2c:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0102a2f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102a32:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f0102a35:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0102a3c:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f0102a43:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0102a4a:	83 ec 04             	sub    $0x4,%esp
f0102a4d:	6a 44                	push   $0x44
f0102a4f:	6a 00                	push   $0x0
f0102a51:	53                   	push   %ebx
f0102a52:	e8 4b 18 00 00       	call   f01042a2 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f0102a57:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0102a5d:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0102a63:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0102a69:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0102a70:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	env_free_list = e->env_link;
f0102a76:	8b 43 44             	mov    0x44(%ebx),%eax
f0102a79:	a3 90 bf 17 f0       	mov    %eax,0xf017bf90
	*newenv_store = e;
f0102a7e:	8b 45 08             	mov    0x8(%ebp),%eax
f0102a81:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102a83:	8b 53 48             	mov    0x48(%ebx),%edx
f0102a86:	a1 88 bf 17 f0       	mov    0xf017bf88,%eax
f0102a8b:	83 c4 10             	add    $0x10,%esp
f0102a8e:	85 c0                	test   %eax,%eax
f0102a90:	74 05                	je     f0102a97 <env_alloc+0x13a>
f0102a92:	8b 40 48             	mov    0x48(%eax),%eax
f0102a95:	eb 05                	jmp    f0102a9c <env_alloc+0x13f>
f0102a97:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a9c:	83 ec 04             	sub    $0x4,%esp
f0102a9f:	52                   	push   %edx
f0102aa0:	50                   	push   %eax
f0102aa1:	68 49 57 10 f0       	push   $0xf0105749
f0102aa6:	e8 fe 03 00 00       	call   f0102ea9 <cprintf>
	return 0;
f0102aab:	83 c4 10             	add    $0x10,%esp
f0102aae:	b8 00 00 00 00       	mov    $0x0,%eax
f0102ab3:	eb 0c                	jmp    f0102ac1 <env_alloc+0x164>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0102ab5:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0102aba:	eb 05                	jmp    f0102ac1 <env_alloc+0x164>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0102abc:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0102ac1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102ac4:	c9                   	leave  
f0102ac5:	c3                   	ret    

f0102ac6 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0102ac6:	55                   	push   %ebp
f0102ac7:	89 e5                	mov    %esp,%ebp
f0102ac9:	57                   	push   %edi
f0102aca:	56                   	push   %esi
f0102acb:	53                   	push   %ebx
f0102acc:	83 ec 34             	sub    $0x34,%esp
f0102acf:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	
	struct Env *e;
	env_alloc(&e, 0);
f0102ad2:	6a 00                	push   $0x0
f0102ad4:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0102ad7:	50                   	push   %eax
f0102ad8:	e8 80 fe ff ff       	call   f010295d <env_alloc>
	load_icode(e, binary);
f0102add:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102ae0:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	struct Elf *ELFHDR = (struct Elf *) binary;
	struct Proghdr *ph, *eph;
	
	
	// is this a valid ELF?
	if (ELFHDR->e_magic != ELF_MAGIC)
f0102ae3:	83 c4 10             	add    $0x10,%esp
f0102ae6:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f0102aec:	74 17                	je     f0102b05 <env_create+0x3f>
		panic("Not a valid ELF Header");
f0102aee:	83 ec 04             	sub    $0x4,%esp
f0102af1:	68 5e 57 10 f0       	push   $0xf010575e
f0102af6:	68 63 01 00 00       	push   $0x163
f0102afb:	68 3e 57 10 f0       	push   $0xf010573e
f0102b00:	e8 9b d5 ff ff       	call   f01000a0 <_panic>
		
	ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);
f0102b05:	89 fb                	mov    %edi,%ebx
f0102b07:	03 5f 1c             	add    0x1c(%edi),%ebx
	eph = ph + ELFHDR->e_phnum;
f0102b0a:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f0102b0e:	c1 e6 05             	shl    $0x5,%esi
f0102b11:	01 de                	add    %ebx,%esi
	
	lcr3(PADDR(e->env_pgdir));
f0102b13:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102b16:	8b 40 5c             	mov    0x5c(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102b19:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102b1e:	77 15                	ja     f0102b35 <env_create+0x6f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102b20:	50                   	push   %eax
f0102b21:	68 c8 4d 10 f0       	push   $0xf0104dc8
f0102b26:	68 68 01 00 00       	push   $0x168
f0102b2b:	68 3e 57 10 f0       	push   $0xf010573e
f0102b30:	e8 6b d5 ff ff       	call   f01000a0 <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102b35:	05 00 00 00 10       	add    $0x10000000,%eax
f0102b3a:	0f 22 d8             	mov    %eax,%cr3
f0102b3d:	eb 46                	jmp    f0102b85 <env_create+0xbf>
	
	for (; ph < eph; ph++)
	{
		if(ph->p_type == ELF_PROG_LOAD)
f0102b3f:	83 3b 01             	cmpl   $0x1,(%ebx)
f0102b42:	75 3e                	jne    f0102b82 <env_create+0xbc>
		{
			region_alloc(e, (void *)ph->p_va, ph->p_memsz);
f0102b44:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0102b47:	8b 53 08             	mov    0x8(%ebx),%edx
f0102b4a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102b4d:	e8 ad fc ff ff       	call   f01027ff <region_alloc>
			memcpy((void*)ph->p_va, (void*)binary + ph->p_offset, ph->p_filesz);
f0102b52:	83 ec 04             	sub    $0x4,%esp
f0102b55:	ff 73 10             	pushl  0x10(%ebx)
f0102b58:	89 f8                	mov    %edi,%eax
f0102b5a:	03 43 04             	add    0x4(%ebx),%eax
f0102b5d:	50                   	push   %eax
f0102b5e:	ff 73 08             	pushl  0x8(%ebx)
f0102b61:	e8 f1 17 00 00       	call   f0104357 <memcpy>
			memset((void *)(binary + ph->p_offset + ph->p_filesz), 0, (uint32_t)ph->p_memsz - ph->p_filesz);
f0102b66:	8b 43 10             	mov    0x10(%ebx),%eax
f0102b69:	83 c4 0c             	add    $0xc,%esp
f0102b6c:	8b 53 14             	mov    0x14(%ebx),%edx
f0102b6f:	29 c2                	sub    %eax,%edx
f0102b71:	52                   	push   %edx
f0102b72:	6a 00                	push   $0x0
f0102b74:	03 43 04             	add    0x4(%ebx),%eax
f0102b77:	01 f8                	add    %edi,%eax
f0102b79:	50                   	push   %eax
f0102b7a:	e8 23 17 00 00       	call   f01042a2 <memset>
f0102b7f:	83 c4 10             	add    $0x10,%esp
	ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);
	eph = ph + ELFHDR->e_phnum;
	
	lcr3(PADDR(e->env_pgdir));
	
	for (; ph < eph; ph++)
f0102b82:	83 c3 20             	add    $0x20,%ebx
f0102b85:	39 de                	cmp    %ebx,%esi
f0102b87:	77 b6                	ja     f0102b3f <env_create+0x79>
			memset((void *)(binary + ph->p_offset + ph->p_filesz), 0, (uint32_t)ph->p_memsz - ph->p_filesz);
			
		}
	}

	lcr3(PADDR(kern_pgdir));
f0102b89:	a1 48 cc 17 f0       	mov    0xf017cc48,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102b8e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102b93:	77 15                	ja     f0102baa <env_create+0xe4>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102b95:	50                   	push   %eax
f0102b96:	68 c8 4d 10 f0       	push   $0xf0104dc8
f0102b9b:	68 75 01 00 00       	push   $0x175
f0102ba0:	68 3e 57 10 f0       	push   $0xf010573e
f0102ba5:	e8 f6 d4 ff ff       	call   f01000a0 <_panic>
f0102baa:	05 00 00 00 10       	add    $0x10000000,%eax
f0102baf:	0f 22 d8             	mov    %eax,%cr3
	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.
	region_alloc(e, (void *)USTACKTOP - PGSIZE, PGSIZE);
f0102bb2:	b9 00 10 00 00       	mov    $0x1000,%ecx
f0102bb7:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f0102bbc:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0102bbf:	89 f0                	mov    %esi,%eax
f0102bc1:	e8 39 fc ff ff       	call   f01027ff <region_alloc>
	// LAB 3: Your code here.
	e->env_tf.tf_eip = ELFHDR->e_entry;
f0102bc6:	8b 47 18             	mov    0x18(%edi),%eax
f0102bc9:	89 46 30             	mov    %eax,0x30(%esi)
	// LAB 3: Your code here.
	
	struct Env *e;
	env_alloc(&e, 0);
	load_icode(e, binary);
}
f0102bcc:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102bcf:	5b                   	pop    %ebx
f0102bd0:	5e                   	pop    %esi
f0102bd1:	5f                   	pop    %edi
f0102bd2:	5d                   	pop    %ebp
f0102bd3:	c3                   	ret    

f0102bd4 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0102bd4:	55                   	push   %ebp
f0102bd5:	89 e5                	mov    %esp,%ebp
f0102bd7:	57                   	push   %edi
f0102bd8:	56                   	push   %esi
f0102bd9:	53                   	push   %ebx
f0102bda:	83 ec 1c             	sub    $0x1c,%esp
f0102bdd:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0102be0:	8b 15 88 bf 17 f0    	mov    0xf017bf88,%edx
f0102be6:	39 fa                	cmp    %edi,%edx
f0102be8:	75 29                	jne    f0102c13 <env_free+0x3f>
		lcr3(PADDR(kern_pgdir));
f0102bea:	a1 48 cc 17 f0       	mov    0xf017cc48,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102bef:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102bf4:	77 15                	ja     f0102c0b <env_free+0x37>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102bf6:	50                   	push   %eax
f0102bf7:	68 c8 4d 10 f0       	push   $0xf0104dc8
f0102bfc:	68 9c 01 00 00       	push   $0x19c
f0102c01:	68 3e 57 10 f0       	push   $0xf010573e
f0102c06:	e8 95 d4 ff ff       	call   f01000a0 <_panic>
f0102c0b:	05 00 00 00 10       	add    $0x10000000,%eax
f0102c10:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102c13:	8b 4f 48             	mov    0x48(%edi),%ecx
f0102c16:	85 d2                	test   %edx,%edx
f0102c18:	74 05                	je     f0102c1f <env_free+0x4b>
f0102c1a:	8b 42 48             	mov    0x48(%edx),%eax
f0102c1d:	eb 05                	jmp    f0102c24 <env_free+0x50>
f0102c1f:	b8 00 00 00 00       	mov    $0x0,%eax
f0102c24:	83 ec 04             	sub    $0x4,%esp
f0102c27:	51                   	push   %ecx
f0102c28:	50                   	push   %eax
f0102c29:	68 75 57 10 f0       	push   $0xf0105775
f0102c2e:	e8 76 02 00 00       	call   f0102ea9 <cprintf>
f0102c33:	83 c4 10             	add    $0x10,%esp

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102c36:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0102c3d:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0102c40:	89 d0                	mov    %edx,%eax
f0102c42:	c1 e0 02             	shl    $0x2,%eax
f0102c45:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0102c48:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102c4b:	8b 34 90             	mov    (%eax,%edx,4),%esi
f0102c4e:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0102c54:	0f 84 a8 00 00 00    	je     f0102d02 <env_free+0x12e>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0102c5a:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102c60:	89 f0                	mov    %esi,%eax
f0102c62:	c1 e8 0c             	shr    $0xc,%eax
f0102c65:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102c68:	39 05 44 cc 17 f0    	cmp    %eax,0xf017cc44
f0102c6e:	77 15                	ja     f0102c85 <env_free+0xb1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102c70:	56                   	push   %esi
f0102c71:	68 84 4c 10 f0       	push   $0xf0104c84
f0102c76:	68 ab 01 00 00       	push   $0x1ab
f0102c7b:	68 3e 57 10 f0       	push   $0xf010573e
f0102c80:	e8 1b d4 ff ff       	call   f01000a0 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102c85:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102c88:	c1 e0 16             	shl    $0x16,%eax
f0102c8b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102c8e:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0102c93:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0102c9a:	01 
f0102c9b:	74 17                	je     f0102cb4 <env_free+0xe0>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102c9d:	83 ec 08             	sub    $0x8,%esp
f0102ca0:	89 d8                	mov    %ebx,%eax
f0102ca2:	c1 e0 0c             	shl    $0xc,%eax
f0102ca5:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0102ca8:	50                   	push   %eax
f0102ca9:	ff 77 5c             	pushl  0x5c(%edi)
f0102cac:	e8 80 e2 ff ff       	call   f0100f31 <page_remove>
f0102cb1:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102cb4:	83 c3 01             	add    $0x1,%ebx
f0102cb7:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0102cbd:	75 d4                	jne    f0102c93 <env_free+0xbf>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0102cbf:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102cc2:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102cc5:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102ccc:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102ccf:	3b 05 44 cc 17 f0    	cmp    0xf017cc44,%eax
f0102cd5:	72 14                	jb     f0102ceb <env_free+0x117>
		panic("pa2page called with invalid pa");
f0102cd7:	83 ec 04             	sub    $0x4,%esp
f0102cda:	68 6c 4d 10 f0       	push   $0xf0104d6c
f0102cdf:	6a 4f                	push   $0x4f
f0102ce1:	68 4d 54 10 f0       	push   $0xf010544d
f0102ce6:	e8 b5 d3 ff ff       	call   f01000a0 <_panic>
		page_decref(pa2page(pa));
f0102ceb:	83 ec 0c             	sub    $0xc,%esp
f0102cee:	a1 4c cc 17 f0       	mov    0xf017cc4c,%eax
f0102cf3:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102cf6:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f0102cf9:	50                   	push   %eax
f0102cfa:	e8 85 e0 ff ff       	call   f0100d84 <page_decref>
f0102cff:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102d02:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0102d06:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102d09:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0102d0e:	0f 85 29 ff ff ff    	jne    f0102c3d <env_free+0x69>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0102d14:	8b 47 5c             	mov    0x5c(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102d17:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102d1c:	77 15                	ja     f0102d33 <env_free+0x15f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102d1e:	50                   	push   %eax
f0102d1f:	68 c8 4d 10 f0       	push   $0xf0104dc8
f0102d24:	68 b9 01 00 00       	push   $0x1b9
f0102d29:	68 3e 57 10 f0       	push   $0xf010573e
f0102d2e:	e8 6d d3 ff ff       	call   f01000a0 <_panic>
	e->env_pgdir = 0;
f0102d33:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102d3a:	05 00 00 00 10       	add    $0x10000000,%eax
f0102d3f:	c1 e8 0c             	shr    $0xc,%eax
f0102d42:	3b 05 44 cc 17 f0    	cmp    0xf017cc44,%eax
f0102d48:	72 14                	jb     f0102d5e <env_free+0x18a>
		panic("pa2page called with invalid pa");
f0102d4a:	83 ec 04             	sub    $0x4,%esp
f0102d4d:	68 6c 4d 10 f0       	push   $0xf0104d6c
f0102d52:	6a 4f                	push   $0x4f
f0102d54:	68 4d 54 10 f0       	push   $0xf010544d
f0102d59:	e8 42 d3 ff ff       	call   f01000a0 <_panic>
	page_decref(pa2page(pa));
f0102d5e:	83 ec 0c             	sub    $0xc,%esp
f0102d61:	8b 15 4c cc 17 f0    	mov    0xf017cc4c,%edx
f0102d67:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0102d6a:	50                   	push   %eax
f0102d6b:	e8 14 e0 ff ff       	call   f0100d84 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0102d70:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0102d77:	a1 90 bf 17 f0       	mov    0xf017bf90,%eax
f0102d7c:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0102d7f:	89 3d 90 bf 17 f0    	mov    %edi,0xf017bf90
}
f0102d85:	83 c4 10             	add    $0x10,%esp
f0102d88:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102d8b:	5b                   	pop    %ebx
f0102d8c:	5e                   	pop    %esi
f0102d8d:	5f                   	pop    %edi
f0102d8e:	5d                   	pop    %ebp
f0102d8f:	c3                   	ret    

f0102d90 <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f0102d90:	55                   	push   %ebp
f0102d91:	89 e5                	mov    %esp,%ebp
f0102d93:	83 ec 14             	sub    $0x14,%esp
	env_free(e);
f0102d96:	ff 75 08             	pushl  0x8(%ebp)
f0102d99:	e8 36 fe ff ff       	call   f0102bd4 <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f0102d9e:	c7 04 24 98 57 10 f0 	movl   $0xf0105798,(%esp)
f0102da5:	e8 ff 00 00 00       	call   f0102ea9 <cprintf>
f0102daa:	83 c4 10             	add    $0x10,%esp
	while (1)
		monitor(NULL);
f0102dad:	83 ec 0c             	sub    $0xc,%esp
f0102db0:	6a 00                	push   $0x0
f0102db2:	e8 f4 d9 ff ff       	call   f01007ab <monitor>
f0102db7:	83 c4 10             	add    $0x10,%esp
f0102dba:	eb f1                	jmp    f0102dad <env_destroy+0x1d>

f0102dbc <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0102dbc:	55                   	push   %ebp
f0102dbd:	89 e5                	mov    %esp,%ebp
f0102dbf:	83 ec 0c             	sub    $0xc,%esp
	__asm __volatile("movl %0,%%esp\n"
f0102dc2:	8b 65 08             	mov    0x8(%ebp),%esp
f0102dc5:	61                   	popa   
f0102dc6:	07                   	pop    %es
f0102dc7:	1f                   	pop    %ds
f0102dc8:	83 c4 08             	add    $0x8,%esp
f0102dcb:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0102dcc:	68 8b 57 10 f0       	push   $0xf010578b
f0102dd1:	68 e1 01 00 00       	push   $0x1e1
f0102dd6:	68 3e 57 10 f0       	push   $0xf010573e
f0102ddb:	e8 c0 d2 ff ff       	call   f01000a0 <_panic>

f0102de0 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0102de0:	55                   	push   %ebp
f0102de1:	89 e5                	mov    %esp,%ebp
f0102de3:	83 ec 08             	sub    $0x8,%esp
f0102de6:	8b 45 08             	mov    0x8(%ebp),%eax
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.
	//cprintf("curenv: %x, e: %x\n", curenv, e);
	if ((curenv !=NULL) && (curenv->env_status == ENV_RUNNING))
f0102de9:	8b 15 88 bf 17 f0    	mov    0xf017bf88,%edx
f0102def:	85 d2                	test   %edx,%edx
f0102df1:	74 0d                	je     f0102e00 <env_run+0x20>
f0102df3:	83 7a 54 03          	cmpl   $0x3,0x54(%edx)
f0102df7:	75 07                	jne    f0102e00 <env_run+0x20>
		curenv->env_status = ENV_RUNNABLE;
f0102df9:	c7 42 54 02 00 00 00 	movl   $0x2,0x54(%edx)
	curenv = e;
f0102e00:	a3 88 bf 17 f0       	mov    %eax,0xf017bf88
	e->env_status = ENV_RUNNING;
f0102e05:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	e->env_runs++;
f0102e0c:	83 40 58 01          	addl   $0x1,0x58(%eax)
	lcr3(PADDR(e->env_pgdir));
f0102e10:	8b 50 5c             	mov    0x5c(%eax),%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102e13:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0102e19:	77 15                	ja     f0102e30 <env_run+0x50>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102e1b:	52                   	push   %edx
f0102e1c:	68 c8 4d 10 f0       	push   $0xf0104dc8
f0102e21:	68 05 02 00 00       	push   $0x205
f0102e26:	68 3e 57 10 f0       	push   $0xf010573e
f0102e2b:	e8 70 d2 ff ff       	call   f01000a0 <_panic>
f0102e30:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f0102e36:	0f 22 da             	mov    %edx,%cr3
	
	env_pop_tf(&e->env_tf);
f0102e39:	83 ec 0c             	sub    $0xc,%esp
f0102e3c:	50                   	push   %eax
f0102e3d:	e8 7a ff ff ff       	call   f0102dbc <env_pop_tf>

f0102e42 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102e42:	55                   	push   %ebp
f0102e43:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102e45:	ba 70 00 00 00       	mov    $0x70,%edx
f0102e4a:	8b 45 08             	mov    0x8(%ebp),%eax
f0102e4d:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102e4e:	ba 71 00 00 00       	mov    $0x71,%edx
f0102e53:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102e54:	0f b6 c0             	movzbl %al,%eax
}
f0102e57:	5d                   	pop    %ebp
f0102e58:	c3                   	ret    

f0102e59 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102e59:	55                   	push   %ebp
f0102e5a:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102e5c:	ba 70 00 00 00       	mov    $0x70,%edx
f0102e61:	8b 45 08             	mov    0x8(%ebp),%eax
f0102e64:	ee                   	out    %al,(%dx)
f0102e65:	ba 71 00 00 00       	mov    $0x71,%edx
f0102e6a:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102e6d:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102e6e:	5d                   	pop    %ebp
f0102e6f:	c3                   	ret    

f0102e70 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102e70:	55                   	push   %ebp
f0102e71:	89 e5                	mov    %esp,%ebp
f0102e73:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0102e76:	ff 75 08             	pushl  0x8(%ebp)
f0102e79:	e8 89 d7 ff ff       	call   f0100607 <cputchar>
	*cnt++;
}
f0102e7e:	83 c4 10             	add    $0x10,%esp
f0102e81:	c9                   	leave  
f0102e82:	c3                   	ret    

f0102e83 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102e83:	55                   	push   %ebp
f0102e84:	89 e5                	mov    %esp,%ebp
f0102e86:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0102e89:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102e90:	ff 75 0c             	pushl  0xc(%ebp)
f0102e93:	ff 75 08             	pushl  0x8(%ebp)
f0102e96:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102e99:	50                   	push   %eax
f0102e9a:	68 70 2e 10 f0       	push   $0xf0102e70
f0102e9f:	e8 72 0d 00 00       	call   f0103c16 <vprintfmt>
	return cnt;
}
f0102ea4:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102ea7:	c9                   	leave  
f0102ea8:	c3                   	ret    

f0102ea9 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102ea9:	55                   	push   %ebp
f0102eaa:	89 e5                	mov    %esp,%ebp
f0102eac:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102eaf:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102eb2:	50                   	push   %eax
f0102eb3:	ff 75 08             	pushl  0x8(%ebp)
f0102eb6:	e8 c8 ff ff ff       	call   f0102e83 <vcprintf>
	va_end(ap);

	return cnt;
}
f0102ebb:	c9                   	leave  
f0102ebc:	c3                   	ret    

f0102ebd <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0102ebd:	55                   	push   %ebp
f0102ebe:	89 e5                	mov    %esp,%ebp
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f0102ec0:	b8 c0 c7 17 f0       	mov    $0xf017c7c0,%eax
f0102ec5:	c7 05 c4 c7 17 f0 00 	movl   $0xf0000000,0xf017c7c4
f0102ecc:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f0102ecf:	66 c7 05 c8 c7 17 f0 	movw   $0x10,0xf017c7c8
f0102ed6:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f0102ed8:	66 c7 05 48 a3 11 f0 	movw   $0x67,0xf011a348
f0102edf:	67 00 
f0102ee1:	66 a3 4a a3 11 f0    	mov    %ax,0xf011a34a
f0102ee7:	89 c2                	mov    %eax,%edx
f0102ee9:	c1 ea 10             	shr    $0x10,%edx
f0102eec:	88 15 4c a3 11 f0    	mov    %dl,0xf011a34c
f0102ef2:	c6 05 4e a3 11 f0 40 	movb   $0x40,0xf011a34e
f0102ef9:	c1 e8 18             	shr    $0x18,%eax
f0102efc:	a2 4f a3 11 f0       	mov    %al,0xf011a34f
					sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f0102f01:	c6 05 4d a3 11 f0 89 	movb   $0x89,0xf011a34d
}

static __inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
f0102f08:	b8 28 00 00 00       	mov    $0x28,%eax
f0102f0d:	0f 00 d8             	ltr    %ax
}

static __inline void
lidt(void *p)
{
	__asm __volatile("lidt (%0)" : : "r" (p));
f0102f10:	b8 50 a3 11 f0       	mov    $0xf011a350,%eax
f0102f15:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f0102f18:	5d                   	pop    %ebp
f0102f19:	c3                   	ret    

f0102f1a <trap_init>:
}


void
trap_init(void)
{
f0102f1a:	55                   	push   %ebp
f0102f1b:	89 e5                	mov    %esp,%ebp
	void ac();
	void mc();
	void simd();
	void check23();
	
	SETGATE(idt[0], 1, GD_KT, d, 0);
f0102f1d:	b8 ee 35 10 f0       	mov    $0xf01035ee,%eax
f0102f22:	66 a3 a0 bf 17 f0    	mov    %ax,0xf017bfa0
f0102f28:	66 c7 05 a2 bf 17 f0 	movw   $0x8,0xf017bfa2
f0102f2f:	08 00 
f0102f31:	c6 05 a4 bf 17 f0 00 	movb   $0x0,0xf017bfa4
f0102f38:	c6 05 a5 bf 17 f0 8f 	movb   $0x8f,0xf017bfa5
f0102f3f:	c1 e8 10             	shr    $0x10,%eax
f0102f42:	66 a3 a6 bf 17 f0    	mov    %ax,0xf017bfa6
	SETGATE(idt[1], 1, GD_KT, debug, 0);
f0102f48:	b8 f4 35 10 f0       	mov    $0xf01035f4,%eax
f0102f4d:	66 a3 a8 bf 17 f0    	mov    %ax,0xf017bfa8
f0102f53:	66 c7 05 aa bf 17 f0 	movw   $0x8,0xf017bfaa
f0102f5a:	08 00 
f0102f5c:	c6 05 ac bf 17 f0 00 	movb   $0x0,0xf017bfac
f0102f63:	c6 05 ad bf 17 f0 8f 	movb   $0x8f,0xf017bfad
f0102f6a:	c1 e8 10             	shr    $0x10,%eax
f0102f6d:	66 a3 ae bf 17 f0    	mov    %ax,0xf017bfae
	SETGATE(idt[2], 1, GD_KT, nonmsakable, 0);
f0102f73:	b8 fa 35 10 f0       	mov    $0xf01035fa,%eax
f0102f78:	66 a3 b0 bf 17 f0    	mov    %ax,0xf017bfb0
f0102f7e:	66 c7 05 b2 bf 17 f0 	movw   $0x8,0xf017bfb2
f0102f85:	08 00 
f0102f87:	c6 05 b4 bf 17 f0 00 	movb   $0x0,0xf017bfb4
f0102f8e:	c6 05 b5 bf 17 f0 8f 	movb   $0x8f,0xf017bfb5
f0102f95:	c1 e8 10             	shr    $0x10,%eax
f0102f98:	66 a3 b6 bf 17 f0    	mov    %ax,0xf017bfb6
	SETGATE(idt[3], 1, GD_KT, dreakpoint, 3);
f0102f9e:	b8 00 36 10 f0       	mov    $0xf0103600,%eax
f0102fa3:	66 a3 b8 bf 17 f0    	mov    %ax,0xf017bfb8
f0102fa9:	66 c7 05 ba bf 17 f0 	movw   $0x8,0xf017bfba
f0102fb0:	08 00 
f0102fb2:	c6 05 bc bf 17 f0 00 	movb   $0x0,0xf017bfbc
f0102fb9:	c6 05 bd bf 17 f0 ef 	movb   $0xef,0xf017bfbd
f0102fc0:	c1 e8 10             	shr    $0x10,%eax
f0102fc3:	66 a3 be bf 17 f0    	mov    %ax,0xf017bfbe
	SETGATE(idt[4], 1, GD_KT, overflow, 0);
f0102fc9:	b8 06 36 10 f0       	mov    $0xf0103606,%eax
f0102fce:	66 a3 c0 bf 17 f0    	mov    %ax,0xf017bfc0
f0102fd4:	66 c7 05 c2 bf 17 f0 	movw   $0x8,0xf017bfc2
f0102fdb:	08 00 
f0102fdd:	c6 05 c4 bf 17 f0 00 	movb   $0x0,0xf017bfc4
f0102fe4:	c6 05 c5 bf 17 f0 8f 	movb   $0x8f,0xf017bfc5
f0102feb:	c1 e8 10             	shr    $0x10,%eax
f0102fee:	66 a3 c6 bf 17 f0    	mov    %ax,0xf017bfc6
	SETGATE(idt[5], 1, GD_KT, bounds, 0);
f0102ff4:	b8 0c 36 10 f0       	mov    $0xf010360c,%eax
f0102ff9:	66 a3 c8 bf 17 f0    	mov    %ax,0xf017bfc8
f0102fff:	66 c7 05 ca bf 17 f0 	movw   $0x8,0xf017bfca
f0103006:	08 00 
f0103008:	c6 05 cc bf 17 f0 00 	movb   $0x0,0xf017bfcc
f010300f:	c6 05 cd bf 17 f0 8f 	movb   $0x8f,0xf017bfcd
f0103016:	c1 e8 10             	shr    $0x10,%eax
f0103019:	66 a3 ce bf 17 f0    	mov    %ax,0xf017bfce
	SETGATE(idt[6], 1, GD_KT, illegal, 0);
f010301f:	b8 12 36 10 f0       	mov    $0xf0103612,%eax
f0103024:	66 a3 d0 bf 17 f0    	mov    %ax,0xf017bfd0
f010302a:	66 c7 05 d2 bf 17 f0 	movw   $0x8,0xf017bfd2
f0103031:	08 00 
f0103033:	c6 05 d4 bf 17 f0 00 	movb   $0x0,0xf017bfd4
f010303a:	c6 05 d5 bf 17 f0 8f 	movb   $0x8f,0xf017bfd5
f0103041:	c1 e8 10             	shr    $0x10,%eax
f0103044:	66 a3 d6 bf 17 f0    	mov    %ax,0xf017bfd6
	SETGATE(idt[7], 1, GD_KT, device, 0);
f010304a:	b8 18 36 10 f0       	mov    $0xf0103618,%eax
f010304f:	66 a3 d8 bf 17 f0    	mov    %ax,0xf017bfd8
f0103055:	66 c7 05 da bf 17 f0 	movw   $0x8,0xf017bfda
f010305c:	08 00 
f010305e:	c6 05 dc bf 17 f0 00 	movb   $0x0,0xf017bfdc
f0103065:	c6 05 dd bf 17 f0 8f 	movb   $0x8f,0xf017bfdd
f010306c:	c1 e8 10             	shr    $0x10,%eax
f010306f:	66 a3 de bf 17 f0    	mov    %ax,0xf017bfde
	SETGATE(idt[8], 1, GD_KT, doublef, 0);
f0103075:	b8 1e 36 10 f0       	mov    $0xf010361e,%eax
f010307a:	66 a3 e0 bf 17 f0    	mov    %ax,0xf017bfe0
f0103080:	66 c7 05 e2 bf 17 f0 	movw   $0x8,0xf017bfe2
f0103087:	08 00 
f0103089:	c6 05 e4 bf 17 f0 00 	movb   $0x0,0xf017bfe4
f0103090:	c6 05 e5 bf 17 f0 8f 	movb   $0x8f,0xf017bfe5
f0103097:	c1 e8 10             	shr    $0x10,%eax
f010309a:	66 a3 e6 bf 17 f0    	mov    %ax,0xf017bfe6
	SETGATE(idt[10], 1,GD_KT, itss, 0);
f01030a0:	b8 22 36 10 f0       	mov    $0xf0103622,%eax
f01030a5:	66 a3 f0 bf 17 f0    	mov    %ax,0xf017bff0
f01030ab:	66 c7 05 f2 bf 17 f0 	movw   $0x8,0xf017bff2
f01030b2:	08 00 
f01030b4:	c6 05 f4 bf 17 f0 00 	movb   $0x0,0xf017bff4
f01030bb:	c6 05 f5 bf 17 f0 8f 	movb   $0x8f,0xf017bff5
f01030c2:	c1 e8 10             	shr    $0x10,%eax
f01030c5:	66 a3 f6 bf 17 f0    	mov    %ax,0xf017bff6
	SETGATE(idt[11], 1,GD_KT, snp, 0);
f01030cb:	b8 26 36 10 f0       	mov    $0xf0103626,%eax
f01030d0:	66 a3 f8 bf 17 f0    	mov    %ax,0xf017bff8
f01030d6:	66 c7 05 fa bf 17 f0 	movw   $0x8,0xf017bffa
f01030dd:	08 00 
f01030df:	c6 05 fc bf 17 f0 00 	movb   $0x0,0xf017bffc
f01030e6:	c6 05 fd bf 17 f0 8f 	movb   $0x8f,0xf017bffd
f01030ed:	c1 e8 10             	shr    $0x10,%eax
f01030f0:	66 a3 fe bf 17 f0    	mov    %ax,0xf017bffe
	SETGATE(idt[12], 1,GD_KT, se, 0);
f01030f6:	b8 2a 36 10 f0       	mov    $0xf010362a,%eax
f01030fb:	66 a3 00 c0 17 f0    	mov    %ax,0xf017c000
f0103101:	66 c7 05 02 c0 17 f0 	movw   $0x8,0xf017c002
f0103108:	08 00 
f010310a:	c6 05 04 c0 17 f0 00 	movb   $0x0,0xf017c004
f0103111:	c6 05 05 c0 17 f0 8f 	movb   $0x8f,0xf017c005
f0103118:	c1 e8 10             	shr    $0x10,%eax
f010311b:	66 a3 06 c0 17 f0    	mov    %ax,0xf017c006
	SETGATE(idt[13], 1,GD_KT, gpf, 0);
f0103121:	b8 2e 36 10 f0       	mov    $0xf010362e,%eax
f0103126:	66 a3 08 c0 17 f0    	mov    %ax,0xf017c008
f010312c:	66 c7 05 0a c0 17 f0 	movw   $0x8,0xf017c00a
f0103133:	08 00 
f0103135:	c6 05 0c c0 17 f0 00 	movb   $0x0,0xf017c00c
f010313c:	c6 05 0d c0 17 f0 8f 	movb   $0x8f,0xf017c00d
f0103143:	c1 e8 10             	shr    $0x10,%eax
f0103146:	66 a3 0e c0 17 f0    	mov    %ax,0xf017c00e
	SETGATE(idt[14], 1,GD_KT, pf, 0);
f010314c:	b8 32 36 10 f0       	mov    $0xf0103632,%eax
f0103151:	66 a3 10 c0 17 f0    	mov    %ax,0xf017c010
f0103157:	66 c7 05 12 c0 17 f0 	movw   $0x8,0xf017c012
f010315e:	08 00 
f0103160:	c6 05 14 c0 17 f0 00 	movb   $0x0,0xf017c014
f0103167:	c6 05 15 c0 17 f0 8f 	movb   $0x8f,0xf017c015
f010316e:	c1 e8 10             	shr    $0x10,%eax
f0103171:	66 a3 16 c0 17 f0    	mov    %ax,0xf017c016
	SETGATE(idt[16], 1,GD_KT, fpe, 0);
f0103177:	b8 36 36 10 f0       	mov    $0xf0103636,%eax
f010317c:	66 a3 20 c0 17 f0    	mov    %ax,0xf017c020
f0103182:	66 c7 05 22 c0 17 f0 	movw   $0x8,0xf017c022
f0103189:	08 00 
f010318b:	c6 05 24 c0 17 f0 00 	movb   $0x0,0xf017c024
f0103192:	c6 05 25 c0 17 f0 8f 	movb   $0x8f,0xf017c025
f0103199:	c1 e8 10             	shr    $0x10,%eax
f010319c:	66 a3 26 c0 17 f0    	mov    %ax,0xf017c026
	SETGATE(idt[17], 1,GD_KT, ac, 0);
f01031a2:	b8 3c 36 10 f0       	mov    $0xf010363c,%eax
f01031a7:	66 a3 28 c0 17 f0    	mov    %ax,0xf017c028
f01031ad:	66 c7 05 2a c0 17 f0 	movw   $0x8,0xf017c02a
f01031b4:	08 00 
f01031b6:	c6 05 2c c0 17 f0 00 	movb   $0x0,0xf017c02c
f01031bd:	c6 05 2d c0 17 f0 8f 	movb   $0x8f,0xf017c02d
f01031c4:	c1 e8 10             	shr    $0x10,%eax
f01031c7:	66 a3 2e c0 17 f0    	mov    %ax,0xf017c02e
	SETGATE(idt[18], 1,GD_KT, mc, 0);
f01031cd:	b8 40 36 10 f0       	mov    $0xf0103640,%eax
f01031d2:	66 a3 30 c0 17 f0    	mov    %ax,0xf017c030
f01031d8:	66 c7 05 32 c0 17 f0 	movw   $0x8,0xf017c032
f01031df:	08 00 
f01031e1:	c6 05 34 c0 17 f0 00 	movb   $0x0,0xf017c034
f01031e8:	c6 05 35 c0 17 f0 8f 	movb   $0x8f,0xf017c035
f01031ef:	c1 e8 10             	shr    $0x10,%eax
f01031f2:	66 a3 36 c0 17 f0    	mov    %ax,0xf017c036
	SETGATE(idt[19], 1,GD_KT, simd, 0);
f01031f8:	b8 46 36 10 f0       	mov    $0xf0103646,%eax
f01031fd:	66 a3 38 c0 17 f0    	mov    %ax,0xf017c038
f0103203:	66 c7 05 3a c0 17 f0 	movw   $0x8,0xf017c03a
f010320a:	08 00 
f010320c:	c6 05 3c c0 17 f0 00 	movb   $0x0,0xf017c03c
f0103213:	c6 05 3d c0 17 f0 8f 	movb   $0x8f,0xf017c03d
f010321a:	c1 e8 10             	shr    $0x10,%eax
f010321d:	66 a3 3e c0 17 f0    	mov    %ax,0xf017c03e
	SETGATE(idt[48], 0,GD_KT, check23, 3);
f0103223:	b8 4c 36 10 f0       	mov    $0xf010364c,%eax
f0103228:	66 a3 20 c1 17 f0    	mov    %ax,0xf017c120
f010322e:	66 c7 05 22 c1 17 f0 	movw   $0x8,0xf017c122
f0103235:	08 00 
f0103237:	c6 05 24 c1 17 f0 00 	movb   $0x0,0xf017c124
f010323e:	c6 05 25 c1 17 f0 ee 	movb   $0xee,0xf017c125
f0103245:	c1 e8 10             	shr    $0x10,%eax
f0103248:	66 a3 26 c1 17 f0    	mov    %ax,0xf017c126

	

	// Per-CPU setup 
	trap_init_percpu();
f010324e:	e8 6a fc ff ff       	call   f0102ebd <trap_init_percpu>
}
f0103253:	5d                   	pop    %ebp
f0103254:	c3                   	ret    

f0103255 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0103255:	55                   	push   %ebp
f0103256:	89 e5                	mov    %esp,%ebp
f0103258:	53                   	push   %ebx
f0103259:	83 ec 0c             	sub    $0xc,%esp
f010325c:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f010325f:	ff 33                	pushl  (%ebx)
f0103261:	68 ce 57 10 f0       	push   $0xf01057ce
f0103266:	e8 3e fc ff ff       	call   f0102ea9 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f010326b:	83 c4 08             	add    $0x8,%esp
f010326e:	ff 73 04             	pushl  0x4(%ebx)
f0103271:	68 dd 57 10 f0       	push   $0xf01057dd
f0103276:	e8 2e fc ff ff       	call   f0102ea9 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f010327b:	83 c4 08             	add    $0x8,%esp
f010327e:	ff 73 08             	pushl  0x8(%ebx)
f0103281:	68 ec 57 10 f0       	push   $0xf01057ec
f0103286:	e8 1e fc ff ff       	call   f0102ea9 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f010328b:	83 c4 08             	add    $0x8,%esp
f010328e:	ff 73 0c             	pushl  0xc(%ebx)
f0103291:	68 fb 57 10 f0       	push   $0xf01057fb
f0103296:	e8 0e fc ff ff       	call   f0102ea9 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f010329b:	83 c4 08             	add    $0x8,%esp
f010329e:	ff 73 10             	pushl  0x10(%ebx)
f01032a1:	68 0a 58 10 f0       	push   $0xf010580a
f01032a6:	e8 fe fb ff ff       	call   f0102ea9 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f01032ab:	83 c4 08             	add    $0x8,%esp
f01032ae:	ff 73 14             	pushl  0x14(%ebx)
f01032b1:	68 19 58 10 f0       	push   $0xf0105819
f01032b6:	e8 ee fb ff ff       	call   f0102ea9 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f01032bb:	83 c4 08             	add    $0x8,%esp
f01032be:	ff 73 18             	pushl  0x18(%ebx)
f01032c1:	68 28 58 10 f0       	push   $0xf0105828
f01032c6:	e8 de fb ff ff       	call   f0102ea9 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f01032cb:	83 c4 08             	add    $0x8,%esp
f01032ce:	ff 73 1c             	pushl  0x1c(%ebx)
f01032d1:	68 37 58 10 f0       	push   $0xf0105837
f01032d6:	e8 ce fb ff ff       	call   f0102ea9 <cprintf>
}
f01032db:	83 c4 10             	add    $0x10,%esp
f01032de:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01032e1:	c9                   	leave  
f01032e2:	c3                   	ret    

f01032e3 <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f01032e3:	55                   	push   %ebp
f01032e4:	89 e5                	mov    %esp,%ebp
f01032e6:	56                   	push   %esi
f01032e7:	53                   	push   %ebx
f01032e8:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p\n", tf);
f01032eb:	83 ec 08             	sub    $0x8,%esp
f01032ee:	53                   	push   %ebx
f01032ef:	68 6d 59 10 f0       	push   $0xf010596d
f01032f4:	e8 b0 fb ff ff       	call   f0102ea9 <cprintf>
	print_regs(&tf->tf_regs);
f01032f9:	89 1c 24             	mov    %ebx,(%esp)
f01032fc:	e8 54 ff ff ff       	call   f0103255 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103301:	83 c4 08             	add    $0x8,%esp
f0103304:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0103308:	50                   	push   %eax
f0103309:	68 88 58 10 f0       	push   $0xf0105888
f010330e:	e8 96 fb ff ff       	call   f0102ea9 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103313:	83 c4 08             	add    $0x8,%esp
f0103316:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f010331a:	50                   	push   %eax
f010331b:	68 9b 58 10 f0       	push   $0xf010589b
f0103320:	e8 84 fb ff ff       	call   f0102ea9 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103325:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
f0103328:	83 c4 10             	add    $0x10,%esp
f010332b:	83 f8 13             	cmp    $0x13,%eax
f010332e:	77 09                	ja     f0103339 <print_trapframe+0x56>
		return excnames[trapno];
f0103330:	8b 14 85 60 5b 10 f0 	mov    -0xfefa4a0(,%eax,4),%edx
f0103337:	eb 10                	jmp    f0103349 <print_trapframe+0x66>
	if (trapno == T_SYSCALL)
		return "System call";
	return "(unknown trap)";
f0103339:	83 f8 30             	cmp    $0x30,%eax
f010333c:	b9 52 58 10 f0       	mov    $0xf0105852,%ecx
f0103341:	ba 46 58 10 f0       	mov    $0xf0105846,%edx
f0103346:	0f 45 d1             	cmovne %ecx,%edx
{
	cprintf("TRAP frame at %p\n", tf);
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103349:	83 ec 04             	sub    $0x4,%esp
f010334c:	52                   	push   %edx
f010334d:	50                   	push   %eax
f010334e:	68 ae 58 10 f0       	push   $0xf01058ae
f0103353:	e8 51 fb ff ff       	call   f0102ea9 <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103358:	83 c4 10             	add    $0x10,%esp
f010335b:	3b 1d a0 c7 17 f0    	cmp    0xf017c7a0,%ebx
f0103361:	75 1a                	jne    f010337d <print_trapframe+0x9a>
f0103363:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103367:	75 14                	jne    f010337d <print_trapframe+0x9a>

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f0103369:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f010336c:	83 ec 08             	sub    $0x8,%esp
f010336f:	50                   	push   %eax
f0103370:	68 c0 58 10 f0       	push   $0xf01058c0
f0103375:	e8 2f fb ff ff       	call   f0102ea9 <cprintf>
f010337a:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f010337d:	83 ec 08             	sub    $0x8,%esp
f0103380:	ff 73 2c             	pushl  0x2c(%ebx)
f0103383:	68 cf 58 10 f0       	push   $0xf01058cf
f0103388:	e8 1c fb ff ff       	call   f0102ea9 <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f010338d:	83 c4 10             	add    $0x10,%esp
f0103390:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103394:	75 49                	jne    f01033df <print_trapframe+0xfc>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0103396:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0103399:	89 c2                	mov    %eax,%edx
f010339b:	83 e2 01             	and    $0x1,%edx
f010339e:	ba 6c 58 10 f0       	mov    $0xf010586c,%edx
f01033a3:	b9 61 58 10 f0       	mov    $0xf0105861,%ecx
f01033a8:	0f 44 ca             	cmove  %edx,%ecx
f01033ab:	89 c2                	mov    %eax,%edx
f01033ad:	83 e2 02             	and    $0x2,%edx
f01033b0:	ba 7e 58 10 f0       	mov    $0xf010587e,%edx
f01033b5:	be 78 58 10 f0       	mov    $0xf0105878,%esi
f01033ba:	0f 45 d6             	cmovne %esi,%edx
f01033bd:	83 e0 04             	and    $0x4,%eax
f01033c0:	be 98 59 10 f0       	mov    $0xf0105998,%esi
f01033c5:	b8 83 58 10 f0       	mov    $0xf0105883,%eax
f01033ca:	0f 44 c6             	cmove  %esi,%eax
f01033cd:	51                   	push   %ecx
f01033ce:	52                   	push   %edx
f01033cf:	50                   	push   %eax
f01033d0:	68 dd 58 10 f0       	push   $0xf01058dd
f01033d5:	e8 cf fa ff ff       	call   f0102ea9 <cprintf>
f01033da:	83 c4 10             	add    $0x10,%esp
f01033dd:	eb 10                	jmp    f01033ef <print_trapframe+0x10c>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f01033df:	83 ec 0c             	sub    $0xc,%esp
f01033e2:	68 f2 56 10 f0       	push   $0xf01056f2
f01033e7:	e8 bd fa ff ff       	call   f0102ea9 <cprintf>
f01033ec:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f01033ef:	83 ec 08             	sub    $0x8,%esp
f01033f2:	ff 73 30             	pushl  0x30(%ebx)
f01033f5:	68 ec 58 10 f0       	push   $0xf01058ec
f01033fa:	e8 aa fa ff ff       	call   f0102ea9 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f01033ff:	83 c4 08             	add    $0x8,%esp
f0103402:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103406:	50                   	push   %eax
f0103407:	68 fb 58 10 f0       	push   $0xf01058fb
f010340c:	e8 98 fa ff ff       	call   f0102ea9 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103411:	83 c4 08             	add    $0x8,%esp
f0103414:	ff 73 38             	pushl  0x38(%ebx)
f0103417:	68 0e 59 10 f0       	push   $0xf010590e
f010341c:	e8 88 fa ff ff       	call   f0102ea9 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0103421:	83 c4 10             	add    $0x10,%esp
f0103424:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103428:	74 25                	je     f010344f <print_trapframe+0x16c>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f010342a:	83 ec 08             	sub    $0x8,%esp
f010342d:	ff 73 3c             	pushl  0x3c(%ebx)
f0103430:	68 1d 59 10 f0       	push   $0xf010591d
f0103435:	e8 6f fa ff ff       	call   f0102ea9 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f010343a:	83 c4 08             	add    $0x8,%esp
f010343d:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0103441:	50                   	push   %eax
f0103442:	68 2c 59 10 f0       	push   $0xf010592c
f0103447:	e8 5d fa ff ff       	call   f0102ea9 <cprintf>
f010344c:	83 c4 10             	add    $0x10,%esp
	}
}
f010344f:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103452:	5b                   	pop    %ebx
f0103453:	5e                   	pop    %esi
f0103454:	5d                   	pop    %ebp
f0103455:	c3                   	ret    

f0103456 <page_fault_handler>:
}


void	
page_fault_handler(struct Trapframe *tf)
{
f0103456:	55                   	push   %ebp
f0103457:	89 e5                	mov    %esp,%ebp
f0103459:	53                   	push   %ebx
f010345a:	83 ec 04             	sub    $0x4,%esp
f010345d:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103460:	0f 20 d0             	mov    %cr2,%eax
	fault_va = rcr2();

	// Handle kernel-mode page faults.

	// LAB 3: Your code here.
	if((tf->tf_cs&3) == 0)
f0103463:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103467:	75 17                	jne    f0103480 <page_fault_handler+0x2a>
	{
		panic("handle kernel-mode page faults");
f0103469:	83 ec 04             	sub    $0x4,%esp
f010346c:	68 e4 5a 10 f0       	push   $0xf0105ae4
f0103471:	68 0b 01 00 00       	push   $0x10b
f0103476:	68 3f 59 10 f0       	push   $0xf010593f
f010347b:	e8 20 cc ff ff       	call   f01000a0 <_panic>

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103480:	ff 73 30             	pushl  0x30(%ebx)
f0103483:	50                   	push   %eax
f0103484:	a1 88 bf 17 f0       	mov    0xf017bf88,%eax
f0103489:	ff 70 48             	pushl  0x48(%eax)
f010348c:	68 04 5b 10 f0       	push   $0xf0105b04
f0103491:	e8 13 fa ff ff       	call   f0102ea9 <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f0103496:	89 1c 24             	mov    %ebx,(%esp)
f0103499:	e8 45 fe ff ff       	call   f01032e3 <print_trapframe>
	env_destroy(curenv);
f010349e:	83 c4 04             	add    $0x4,%esp
f01034a1:	ff 35 88 bf 17 f0    	pushl  0xf017bf88
f01034a7:	e8 e4 f8 ff ff       	call   f0102d90 <env_destroy>
}
f01034ac:	83 c4 10             	add    $0x10,%esp
f01034af:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01034b2:	c9                   	leave  
f01034b3:	c3                   	ret    

f01034b4 <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f01034b4:	55                   	push   %ebp
f01034b5:	89 e5                	mov    %esp,%ebp
f01034b7:	57                   	push   %edi
f01034b8:	56                   	push   %esi
f01034b9:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f01034bc:	fc                   	cld    

static __inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	__asm __volatile("pushfl; popl %0" : "=r" (eflags));
f01034bd:	9c                   	pushf  
f01034be:	58                   	pop    %eax

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f01034bf:	f6 c4 02             	test   $0x2,%ah
f01034c2:	74 19                	je     f01034dd <trap+0x29>
f01034c4:	68 4b 59 10 f0       	push   $0xf010594b
f01034c9:	68 67 54 10 f0       	push   $0xf0105467
f01034ce:	68 e0 00 00 00       	push   $0xe0
f01034d3:	68 3f 59 10 f0       	push   $0xf010593f
f01034d8:	e8 c3 cb ff ff       	call   f01000a0 <_panic>

	cprintf("Incoming TRAP frame at %p\n", tf);
f01034dd:	83 ec 08             	sub    $0x8,%esp
f01034e0:	56                   	push   %esi
f01034e1:	68 64 59 10 f0       	push   $0xf0105964
f01034e6:	e8 be f9 ff ff       	call   f0102ea9 <cprintf>
	//cprintf("TRAP no at %p\n", tf->tf_trapno);
	if ((tf->tf_cs & 3) == 3) {
f01034eb:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f01034ef:	83 e0 03             	and    $0x3,%eax
f01034f2:	83 c4 10             	add    $0x10,%esp
f01034f5:	66 83 f8 03          	cmp    $0x3,%ax
f01034f9:	75 31                	jne    f010352c <trap+0x78>
		// Trapped from user mode.
		assert(curenv);
f01034fb:	a1 88 bf 17 f0       	mov    0xf017bf88,%eax
f0103500:	85 c0                	test   %eax,%eax
f0103502:	75 19                	jne    f010351d <trap+0x69>
f0103504:	68 7f 59 10 f0       	push   $0xf010597f
f0103509:	68 67 54 10 f0       	push   $0xf0105467
f010350e:	68 e6 00 00 00       	push   $0xe6
f0103513:	68 3f 59 10 f0       	push   $0xf010593f
f0103518:	e8 83 cb ff ff       	call   f01000a0 <_panic>

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f010351d:	b9 11 00 00 00       	mov    $0x11,%ecx
f0103522:	89 c7                	mov    %eax,%edi
f0103524:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103526:	8b 35 88 bf 17 f0    	mov    0xf017bf88,%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f010352c:	89 35 a0 c7 17 f0    	mov    %esi,0xf017c7a0
static void
trap_dispatch(struct Trapframe *tf)
{
	// Handle processor exceptions.
	// LAB 3: Your code here.
	if (tf->tf_trapno == T_PGFLT) 
f0103532:	8b 46 28             	mov    0x28(%esi),%eax
f0103535:	83 f8 0e             	cmp    $0xe,%eax
f0103538:	75 0e                	jne    f0103548 <trap+0x94>
	{
		page_fault_handler(tf);
f010353a:	83 ec 0c             	sub    $0xc,%esp
f010353d:	56                   	push   %esi
f010353e:	e8 13 ff ff ff       	call   f0103456 <page_fault_handler>
f0103543:	83 c4 10             	add    $0x10,%esp
f0103546:	eb 74                	jmp    f01035bc <trap+0x108>
		return;
    	}
    	if (tf->tf_trapno == T_BRKPT) 
f0103548:	83 f8 03             	cmp    $0x3,%eax
f010354b:	75 0e                	jne    f010355b <trap+0xa7>
	{
		monitor(tf);
f010354d:	83 ec 0c             	sub    $0xc,%esp
f0103550:	56                   	push   %esi
f0103551:	e8 55 d2 ff ff       	call   f01007ab <monitor>
f0103556:	83 c4 10             	add    $0x10,%esp
f0103559:	eb 61                	jmp    f01035bc <trap+0x108>
		return;
	}
	if (tf->tf_trapno == T_SYSCALL) 
f010355b:	83 f8 30             	cmp    $0x30,%eax
f010355e:	75 21                	jne    f0103581 <trap+0xcd>
	{
		
		tf->tf_regs.reg_eax=syscall(tf->tf_regs.reg_eax, tf->tf_regs.reg_edx, tf->tf_regs.reg_ecx, tf->tf_regs.reg_ebx, tf->tf_regs.reg_edi, tf->tf_regs.reg_esi);
f0103560:	83 ec 08             	sub    $0x8,%esp
f0103563:	ff 76 04             	pushl  0x4(%esi)
f0103566:	ff 36                	pushl  (%esi)
f0103568:	ff 76 10             	pushl  0x10(%esi)
f010356b:	ff 76 18             	pushl  0x18(%esi)
f010356e:	ff 76 14             	pushl  0x14(%esi)
f0103571:	ff 76 1c             	pushl  0x1c(%esi)
f0103574:	e8 eb 00 00 00       	call   f0103664 <syscall>
f0103579:	89 46 1c             	mov    %eax,0x1c(%esi)
f010357c:	83 c4 20             	add    $0x20,%esp
f010357f:	eb 3b                	jmp    f01035bc <trap+0x108>
		return;
	}
	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f0103581:	83 ec 0c             	sub    $0xc,%esp
f0103584:	56                   	push   %esi
f0103585:	e8 59 fd ff ff       	call   f01032e3 <print_trapframe>
	if (tf->tf_cs == GD_KT)
f010358a:	83 c4 10             	add    $0x10,%esp
f010358d:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0103592:	75 17                	jne    f01035ab <trap+0xf7>
		panic("unhandled trap in kernel");
f0103594:	83 ec 04             	sub    $0x4,%esp
f0103597:	68 86 59 10 f0       	push   $0xf0105986
f010359c:	68 cf 00 00 00       	push   $0xcf
f01035a1:	68 3f 59 10 f0       	push   $0xf010593f
f01035a6:	e8 f5 ca ff ff       	call   f01000a0 <_panic>
	else {
		env_destroy(curenv);
f01035ab:	83 ec 0c             	sub    $0xc,%esp
f01035ae:	ff 35 88 bf 17 f0    	pushl  0xf017bf88
f01035b4:	e8 d7 f7 ff ff       	call   f0102d90 <env_destroy>
f01035b9:	83 c4 10             	add    $0x10,%esp
	// Dispatch based on what type of trap occurred
	
	trap_dispatch(tf);

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
f01035bc:	a1 88 bf 17 f0       	mov    0xf017bf88,%eax
f01035c1:	85 c0                	test   %eax,%eax
f01035c3:	74 06                	je     f01035cb <trap+0x117>
f01035c5:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f01035c9:	74 19                	je     f01035e4 <trap+0x130>
f01035cb:	68 28 5b 10 f0       	push   $0xf0105b28
f01035d0:	68 67 54 10 f0       	push   $0xf0105467
f01035d5:	68 f9 00 00 00       	push   $0xf9
f01035da:	68 3f 59 10 f0       	push   $0xf010593f
f01035df:	e8 bc ca ff ff       	call   f01000a0 <_panic>
	env_run(curenv);
f01035e4:	83 ec 0c             	sub    $0xc,%esp
f01035e7:	50                   	push   %eax
f01035e8:	e8 f3 f7 ff ff       	call   f0102de0 <env_run>
f01035ed:	90                   	nop

f01035ee <d>:

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
 
	TRAPHANDLER_NOEC(d, 0);
f01035ee:	6a 00                	push   $0x0
f01035f0:	6a 00                	push   $0x0
f01035f2:	eb 5e                	jmp    f0103652 <_alltraps>

f01035f4 <debug>:
	TRAPHANDLER_NOEC(debug, 1);
f01035f4:	6a 00                	push   $0x0
f01035f6:	6a 01                	push   $0x1
f01035f8:	eb 58                	jmp    f0103652 <_alltraps>

f01035fa <nonmsakable>:
	TRAPHANDLER_NOEC(nonmsakable, 2);
f01035fa:	6a 00                	push   $0x0
f01035fc:	6a 02                	push   $0x2
f01035fe:	eb 52                	jmp    f0103652 <_alltraps>

f0103600 <dreakpoint>:
	TRAPHANDLER_NOEC(dreakpoint, 3);
f0103600:	6a 00                	push   $0x0
f0103602:	6a 03                	push   $0x3
f0103604:	eb 4c                	jmp    f0103652 <_alltraps>

f0103606 <overflow>:
	TRAPHANDLER_NOEC(overflow, 4);
f0103606:	6a 00                	push   $0x0
f0103608:	6a 04                	push   $0x4
f010360a:	eb 46                	jmp    f0103652 <_alltraps>

f010360c <bounds>:
	TRAPHANDLER_NOEC(bounds, 5);
f010360c:	6a 00                	push   $0x0
f010360e:	6a 05                	push   $0x5
f0103610:	eb 40                	jmp    f0103652 <_alltraps>

f0103612 <illegal>:
	TRAPHANDLER_NOEC(illegal, 6);
f0103612:	6a 00                	push   $0x0
f0103614:	6a 06                	push   $0x6
f0103616:	eb 3a                	jmp    f0103652 <_alltraps>

f0103618 <device>:
	TRAPHANDLER_NOEC(device, 7);
f0103618:	6a 00                	push   $0x0
f010361a:	6a 07                	push   $0x7
f010361c:	eb 34                	jmp    f0103652 <_alltraps>

f010361e <doublef>:
	TRAPHANDLER(doublef, 8);
f010361e:	6a 08                	push   $0x8
f0103620:	eb 30                	jmp    f0103652 <_alltraps>

f0103622 <itss>:
	TRAPHANDLER(itss, 10);
f0103622:	6a 0a                	push   $0xa
f0103624:	eb 2c                	jmp    f0103652 <_alltraps>

f0103626 <snp>:
	TRAPHANDLER(snp, 11);
f0103626:	6a 0b                	push   $0xb
f0103628:	eb 28                	jmp    f0103652 <_alltraps>

f010362a <se>:
	TRAPHANDLER(se, 12);
f010362a:	6a 0c                	push   $0xc
f010362c:	eb 24                	jmp    f0103652 <_alltraps>

f010362e <gpf>:
	TRAPHANDLER(gpf, 13);
f010362e:	6a 0d                	push   $0xd
f0103630:	eb 20                	jmp    f0103652 <_alltraps>

f0103632 <pf>:
	TRAPHANDLER(pf, 14);
f0103632:	6a 0e                	push   $0xe
f0103634:	eb 1c                	jmp    f0103652 <_alltraps>

f0103636 <fpe>:
	TRAPHANDLER_NOEC(fpe, 16);
f0103636:	6a 00                	push   $0x0
f0103638:	6a 10                	push   $0x10
f010363a:	eb 16                	jmp    f0103652 <_alltraps>

f010363c <ac>:
	TRAPHANDLER(ac, 17);
f010363c:	6a 11                	push   $0x11
f010363e:	eb 12                	jmp    f0103652 <_alltraps>

f0103640 <mc>:
	TRAPHANDLER_NOEC(mc, 18);
f0103640:	6a 00                	push   $0x0
f0103642:	6a 12                	push   $0x12
f0103644:	eb 0c                	jmp    f0103652 <_alltraps>

f0103646 <simd>:
	TRAPHANDLER_NOEC(simd, 19);
f0103646:	6a 00                	push   $0x0
f0103648:	6a 13                	push   $0x13
f010364a:	eb 06                	jmp    f0103652 <_alltraps>

f010364c <check23>:
	TRAPHANDLER_NOEC(check23, 48);
f010364c:	6a 00                	push   $0x0
f010364e:	6a 30                	push   $0x30
f0103650:	eb 00                	jmp    f0103652 <_alltraps>

f0103652 <_alltraps>:
/*
 * Lab 3: Your code here for _alltraps
 */
 
_alltraps:
	pushl %ds
f0103652:	1e                   	push   %ds
	pushl %es
f0103653:	06                   	push   %es
	pushal
f0103654:	60                   	pusha  
	movl $GD_KD, %eax
f0103655:	b8 10 00 00 00       	mov    $0x10,%eax
	movw %ax,%ds
f010365a:	8e d8                	mov    %eax,%ds
	movw %ax,%es
f010365c:	8e c0                	mov    %eax,%es
	pushl %esp
f010365e:	54                   	push   %esp
	call trap
f010365f:	e8 50 fe ff ff       	call   f01034b4 <trap>

f0103664 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f0103664:	55                   	push   %ebp
f0103665:	89 e5                	mov    %esp,%ebp
f0103667:	83 ec 18             	sub    $0x18,%esp
f010366a:	8b 45 08             	mov    0x8(%ebp),%eax
	// Return any appropriate return value.
	// LAB 3: Your code here.

	//panic("syscall not implemented");
	int scn;
	switch (syscallno)
f010366d:	83 f8 01             	cmp    $0x1,%eax
f0103670:	74 44                	je     f01036b6 <syscall+0x52>
f0103672:	83 f8 01             	cmp    $0x1,%eax
f0103675:	72 0f                	jb     f0103686 <syscall+0x22>
f0103677:	83 f8 02             	cmp    $0x2,%eax
f010367a:	74 41                	je     f01036bd <syscall+0x59>
f010367c:	83 f8 03             	cmp    $0x3,%eax
f010367f:	74 46                	je     f01036c7 <syscall+0x63>
f0103681:	e9 a6 00 00 00       	jmp    f010372c <syscall+0xc8>
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
	user_mem_assert(curenv, (void *)s, len, PTE_U);
f0103686:	6a 04                	push   $0x4
f0103688:	ff 75 10             	pushl  0x10(%ebp)
f010368b:	ff 75 0c             	pushl  0xc(%ebp)
f010368e:	ff 35 88 bf 17 f0    	pushl  0xf017bf88
f0103694:	e8 1c f1 ff ff       	call   f01027b5 <user_mem_assert>
	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f0103699:	83 c4 0c             	add    $0xc,%esp
f010369c:	ff 75 0c             	pushl  0xc(%ebp)
f010369f:	ff 75 10             	pushl  0x10(%ebp)
f01036a2:	68 b0 5b 10 f0       	push   $0xf0105bb0
f01036a7:	e8 fd f7 ff ff       	call   f0102ea9 <cprintf>
f01036ac:	83 c4 10             	add    $0x10,%esp
	int scn;
	switch (syscallno)
	{
		case SYS_cputs: 
			sys_cputs((char*)a1, a2);
			scn = 0;
f01036af:	b8 00 00 00 00       	mov    $0x0,%eax
f01036b4:	eb 7b                	jmp    f0103731 <syscall+0xcd>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f01036b6:	e8 fa cd ff ff       	call   f01004b5 <cons_getc>
			sys_cputs((char*)a1, a2);
			scn = 0;
			break;
		case SYS_cgetc:
			scn = sys_cgetc();
			break;
f01036bb:	eb 74                	jmp    f0103731 <syscall+0xcd>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f01036bd:	a1 88 bf 17 f0       	mov    0xf017bf88,%eax
f01036c2:	8b 40 48             	mov    0x48(%eax),%eax
		case SYS_cgetc:
			scn = sys_cgetc();
			break;
		case SYS_getenvid:
			scn = sys_getenvid();
			break;
f01036c5:	eb 6a                	jmp    f0103731 <syscall+0xcd>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f01036c7:	83 ec 04             	sub    $0x4,%esp
f01036ca:	6a 01                	push   $0x1
f01036cc:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01036cf:	50                   	push   %eax
f01036d0:	ff 75 0c             	pushl  0xc(%ebp)
f01036d3:	e8 92 f1 ff ff       	call   f010286a <envid2env>
f01036d8:	83 c4 10             	add    $0x10,%esp
f01036db:	85 c0                	test   %eax,%eax
f01036dd:	78 52                	js     f0103731 <syscall+0xcd>
		return r;
	if (e == curenv)
f01036df:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01036e2:	8b 15 88 bf 17 f0    	mov    0xf017bf88,%edx
f01036e8:	39 d0                	cmp    %edx,%eax
f01036ea:	75 15                	jne    f0103701 <syscall+0x9d>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f01036ec:	83 ec 08             	sub    $0x8,%esp
f01036ef:	ff 70 48             	pushl  0x48(%eax)
f01036f2:	68 b5 5b 10 f0       	push   $0xf0105bb5
f01036f7:	e8 ad f7 ff ff       	call   f0102ea9 <cprintf>
f01036fc:	83 c4 10             	add    $0x10,%esp
f01036ff:	eb 16                	jmp    f0103717 <syscall+0xb3>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f0103701:	83 ec 04             	sub    $0x4,%esp
f0103704:	ff 70 48             	pushl  0x48(%eax)
f0103707:	ff 72 48             	pushl  0x48(%edx)
f010370a:	68 d0 5b 10 f0       	push   $0xf0105bd0
f010370f:	e8 95 f7 ff ff       	call   f0102ea9 <cprintf>
f0103714:	83 c4 10             	add    $0x10,%esp
	env_destroy(e);
f0103717:	83 ec 0c             	sub    $0xc,%esp
f010371a:	ff 75 f4             	pushl  -0xc(%ebp)
f010371d:	e8 6e f6 ff ff       	call   f0102d90 <env_destroy>
f0103722:	83 c4 10             	add    $0x10,%esp
	return 0;
f0103725:	b8 00 00 00 00       	mov    $0x0,%eax
f010372a:	eb 05                	jmp    f0103731 <syscall+0xcd>
			break;
		case SYS_env_destroy:
			scn=sys_env_destroy(a1);
			break;
		default:
			return -E_INVAL;
f010372c:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
	}
	return scn;
}
f0103731:	c9                   	leave  
f0103732:	c3                   	ret    

f0103733 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0103733:	55                   	push   %ebp
f0103734:	89 e5                	mov    %esp,%ebp
f0103736:	57                   	push   %edi
f0103737:	56                   	push   %esi
f0103738:	53                   	push   %ebx
f0103739:	83 ec 14             	sub    $0x14,%esp
f010373c:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010373f:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0103742:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0103745:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0103748:	8b 1a                	mov    (%edx),%ebx
f010374a:	8b 01                	mov    (%ecx),%eax
f010374c:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010374f:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0103756:	eb 7f                	jmp    f01037d7 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f0103758:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010375b:	01 d8                	add    %ebx,%eax
f010375d:	89 c6                	mov    %eax,%esi
f010375f:	c1 ee 1f             	shr    $0x1f,%esi
f0103762:	01 c6                	add    %eax,%esi
f0103764:	d1 fe                	sar    %esi
f0103766:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0103769:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010376c:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f010376f:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103771:	eb 03                	jmp    f0103776 <stab_binsearch+0x43>
			m--;
f0103773:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103776:	39 c3                	cmp    %eax,%ebx
f0103778:	7f 0d                	jg     f0103787 <stab_binsearch+0x54>
f010377a:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f010377e:	83 ea 0c             	sub    $0xc,%edx
f0103781:	39 f9                	cmp    %edi,%ecx
f0103783:	75 ee                	jne    f0103773 <stab_binsearch+0x40>
f0103785:	eb 05                	jmp    f010378c <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0103787:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f010378a:	eb 4b                	jmp    f01037d7 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f010378c:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010378f:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0103792:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0103796:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0103799:	76 11                	jbe    f01037ac <stab_binsearch+0x79>
			*region_left = m;
f010379b:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010379e:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01037a0:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01037a3:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01037aa:	eb 2b                	jmp    f01037d7 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01037ac:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01037af:	73 14                	jae    f01037c5 <stab_binsearch+0x92>
			*region_right = m - 1;
f01037b1:	83 e8 01             	sub    $0x1,%eax
f01037b4:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01037b7:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01037ba:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01037bc:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01037c3:	eb 12                	jmp    f01037d7 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01037c5:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01037c8:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f01037ca:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01037ce:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01037d0:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01037d7:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01037da:	0f 8e 78 ff ff ff    	jle    f0103758 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01037e0:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01037e4:	75 0f                	jne    f01037f5 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f01037e6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01037e9:	8b 00                	mov    (%eax),%eax
f01037eb:	83 e8 01             	sub    $0x1,%eax
f01037ee:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01037f1:	89 06                	mov    %eax,(%esi)
f01037f3:	eb 2c                	jmp    f0103821 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01037f5:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01037f8:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f01037fa:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01037fd:	8b 0e                	mov    (%esi),%ecx
f01037ff:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103802:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0103805:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103808:	eb 03                	jmp    f010380d <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f010380a:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010380d:	39 c8                	cmp    %ecx,%eax
f010380f:	7e 0b                	jle    f010381c <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0103811:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0103815:	83 ea 0c             	sub    $0xc,%edx
f0103818:	39 df                	cmp    %ebx,%edi
f010381a:	75 ee                	jne    f010380a <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f010381c:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010381f:	89 06                	mov    %eax,(%esi)
	}
}
f0103821:	83 c4 14             	add    $0x14,%esp
f0103824:	5b                   	pop    %ebx
f0103825:	5e                   	pop    %esi
f0103826:	5f                   	pop    %edi
f0103827:	5d                   	pop    %ebp
f0103828:	c3                   	ret    

f0103829 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0103829:	55                   	push   %ebp
f010382a:	89 e5                	mov    %esp,%ebp
f010382c:	57                   	push   %edi
f010382d:	56                   	push   %esi
f010382e:	53                   	push   %ebx
f010382f:	83 ec 3c             	sub    $0x3c,%esp
f0103832:	8b 75 08             	mov    0x8(%ebp),%esi
f0103835:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0103838:	c7 03 e8 5b 10 f0    	movl   $0xf0105be8,(%ebx)
	info->eip_line = 0;
f010383e:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0103845:	c7 43 08 e8 5b 10 f0 	movl   $0xf0105be8,0x8(%ebx)
	info->eip_fn_namelen = 9;
f010384c:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0103853:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0103856:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f010385d:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0103863:	0f 87 8a 00 00 00    	ja     f01038f3 <debuginfo_eip+0xca>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.

		if(user_mem_check(curenv, usd, sizeof(struct UserStabData), PTE_U) < 0)
f0103869:	6a 04                	push   $0x4
f010386b:	6a 10                	push   $0x10
f010386d:	68 00 00 20 00       	push   $0x200000
f0103872:	ff 35 88 bf 17 f0    	pushl  0xf017bf88
f0103878:	e8 b8 ee ff ff       	call   f0102735 <user_mem_check>
f010387d:	83 c4 10             	add    $0x10,%esp
f0103880:	85 c0                	test   %eax,%eax
f0103882:	0f 88 2d 02 00 00    	js     f0103ab5 <debuginfo_eip+0x28c>
		{
			return -1;
		}
		stabs = usd->stabs;
f0103888:	a1 00 00 20 00       	mov    0x200000,%eax
f010388d:	89 c1                	mov    %eax,%ecx
f010388f:	89 45 c0             	mov    %eax,-0x40(%ebp)
		stab_end = usd->stab_end;
f0103892:	8b 3d 04 00 20 00    	mov    0x200004,%edi
		stabstr = usd->stabstr;
f0103898:	a1 08 00 20 00       	mov    0x200008,%eax
f010389d:	89 45 b8             	mov    %eax,-0x48(%ebp)
		stabstr_end = usd->stabstr_end;
f01038a0:	8b 15 0c 00 20 00    	mov    0x20000c,%edx
f01038a6:	89 55 bc             	mov    %edx,-0x44(%ebp)

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if(user_mem_check(curenv, stabs, stab_end-stabs, PTE_U) < 0)
f01038a9:	6a 04                	push   $0x4
f01038ab:	89 f8                	mov    %edi,%eax
f01038ad:	29 c8                	sub    %ecx,%eax
f01038af:	c1 f8 02             	sar    $0x2,%eax
f01038b2:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f01038b8:	50                   	push   %eax
f01038b9:	51                   	push   %ecx
f01038ba:	ff 35 88 bf 17 f0    	pushl  0xf017bf88
f01038c0:	e8 70 ee ff ff       	call   f0102735 <user_mem_check>
f01038c5:	83 c4 10             	add    $0x10,%esp
f01038c8:	85 c0                	test   %eax,%eax
f01038ca:	0f 88 ec 01 00 00    	js     f0103abc <debuginfo_eip+0x293>
		{
			return -1;
		}
		
		if(user_mem_check(curenv, stabstr, stabstr_end-stabstr, PTE_U) < 0)
f01038d0:	6a 04                	push   $0x4
f01038d2:	8b 55 bc             	mov    -0x44(%ebp),%edx
f01038d5:	8b 4d b8             	mov    -0x48(%ebp),%ecx
f01038d8:	29 ca                	sub    %ecx,%edx
f01038da:	52                   	push   %edx
f01038db:	51                   	push   %ecx
f01038dc:	ff 35 88 bf 17 f0    	pushl  0xf017bf88
f01038e2:	e8 4e ee ff ff       	call   f0102735 <user_mem_check>
f01038e7:	83 c4 10             	add    $0x10,%esp
f01038ea:	85 c0                	test   %eax,%eax
f01038ec:	79 1f                	jns    f010390d <debuginfo_eip+0xe4>
f01038ee:	e9 d0 01 00 00       	jmp    f0103ac3 <debuginfo_eip+0x29a>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f01038f3:	c7 45 bc 62 ff 10 f0 	movl   $0xf010ff62,-0x44(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f01038fa:	c7 45 b8 15 d5 10 f0 	movl   $0xf010d515,-0x48(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f0103901:	bf 14 d5 10 f0       	mov    $0xf010d514,%edi
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f0103906:	c7 45 c0 10 5e 10 f0 	movl   $0xf0105e10,-0x40(%ebp)
			return -1;
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010390d:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0103910:	39 45 b8             	cmp    %eax,-0x48(%ebp)
f0103913:	0f 83 b1 01 00 00    	jae    f0103aca <debuginfo_eip+0x2a1>
f0103919:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f010391d:	0f 85 ae 01 00 00    	jne    f0103ad1 <debuginfo_eip+0x2a8>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0103923:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f010392a:	2b 7d c0             	sub    -0x40(%ebp),%edi
f010392d:	c1 ff 02             	sar    $0x2,%edi
f0103930:	69 c7 ab aa aa aa    	imul   $0xaaaaaaab,%edi,%eax
f0103936:	83 e8 01             	sub    $0x1,%eax
f0103939:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f010393c:	83 ec 08             	sub    $0x8,%esp
f010393f:	56                   	push   %esi
f0103940:	6a 64                	push   $0x64
f0103942:	8d 55 e0             	lea    -0x20(%ebp),%edx
f0103945:	89 d1                	mov    %edx,%ecx
f0103947:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f010394a:	8b 7d c0             	mov    -0x40(%ebp),%edi
f010394d:	89 f8                	mov    %edi,%eax
f010394f:	e8 df fd ff ff       	call   f0103733 <stab_binsearch>
	if (lfile == 0)
f0103954:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103957:	83 c4 10             	add    $0x10,%esp
f010395a:	85 c0                	test   %eax,%eax
f010395c:	0f 84 76 01 00 00    	je     f0103ad8 <debuginfo_eip+0x2af>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0103962:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0103965:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103968:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f010396b:	83 ec 08             	sub    $0x8,%esp
f010396e:	56                   	push   %esi
f010396f:	6a 24                	push   $0x24
f0103971:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0103974:	89 d1                	mov    %edx,%ecx
f0103976:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0103979:	89 f8                	mov    %edi,%eax
f010397b:	e8 b3 fd ff ff       	call   f0103733 <stab_binsearch>

	if (lfun <= rfun) {
f0103980:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103983:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103986:	89 55 c4             	mov    %edx,-0x3c(%ebp)
f0103989:	83 c4 10             	add    $0x10,%esp
f010398c:	39 d0                	cmp    %edx,%eax
f010398e:	7f 2b                	jg     f01039bb <debuginfo_eip+0x192>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0103990:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103993:	8d 0c 97             	lea    (%edi,%edx,4),%ecx
f0103996:	8b 11                	mov    (%ecx),%edx
f0103998:	8b 7d bc             	mov    -0x44(%ebp),%edi
f010399b:	2b 7d b8             	sub    -0x48(%ebp),%edi
f010399e:	39 fa                	cmp    %edi,%edx
f01039a0:	73 06                	jae    f01039a8 <debuginfo_eip+0x17f>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f01039a2:	03 55 b8             	add    -0x48(%ebp),%edx
f01039a5:	89 53 08             	mov    %edx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f01039a8:	8b 51 08             	mov    0x8(%ecx),%edx
f01039ab:	89 53 10             	mov    %edx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f01039ae:	29 d6                	sub    %edx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f01039b0:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f01039b3:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f01039b6:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01039b9:	eb 0f                	jmp    f01039ca <debuginfo_eip+0x1a1>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f01039bb:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f01039be:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01039c1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f01039c4:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01039c7:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f01039ca:	83 ec 08             	sub    $0x8,%esp
f01039cd:	6a 3a                	push   $0x3a
f01039cf:	ff 73 08             	pushl  0x8(%ebx)
f01039d2:	e8 af 08 00 00       	call   f0104286 <strfind>
f01039d7:	2b 43 08             	sub    0x8(%ebx),%eax
f01039da:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f01039dd:	83 c4 08             	add    $0x8,%esp
f01039e0:	56                   	push   %esi
f01039e1:	6a 44                	push   $0x44
f01039e3:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f01039e6:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f01039e9:	8b 7d c0             	mov    -0x40(%ebp),%edi
f01039ec:	89 f8                	mov    %edi,%eax
f01039ee:	e8 40 fd ff ff       	call   f0103733 <stab_binsearch>
	//cprintf("%d	%d",lline,rline);
	if(lline <= rline)
f01039f3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01039f6:	83 c4 10             	add    $0x10,%esp
f01039f9:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f01039fc:	0f 8f dd 00 00 00    	jg     f0103adf <debuginfo_eip+0x2b6>
		info->eip_line = stabs[lline].n_desc;
f0103a02:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103a05:	8d 14 97             	lea    (%edi,%edx,4),%edx
f0103a08:	0f b7 4a 06          	movzwl 0x6(%edx),%ecx
f0103a0c:	89 4b 04             	mov    %ecx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103a0f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103a12:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f0103a16:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103a19:	eb 0a                	jmp    f0103a25 <debuginfo_eip+0x1fc>
f0103a1b:	83 e8 01             	sub    $0x1,%eax
f0103a1e:	83 ea 0c             	sub    $0xc,%edx
f0103a21:	c6 45 c4 01          	movb   $0x1,-0x3c(%ebp)
f0103a25:	39 c7                	cmp    %eax,%edi
f0103a27:	7e 05                	jle    f0103a2e <debuginfo_eip+0x205>
f0103a29:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103a2c:	eb 47                	jmp    f0103a75 <debuginfo_eip+0x24c>
	       && stabs[lline].n_type != N_SOL
f0103a2e:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103a32:	80 f9 84             	cmp    $0x84,%cl
f0103a35:	75 0e                	jne    f0103a45 <debuginfo_eip+0x21c>
f0103a37:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103a3a:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0103a3e:	74 1c                	je     f0103a5c <debuginfo_eip+0x233>
f0103a40:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0103a43:	eb 17                	jmp    f0103a5c <debuginfo_eip+0x233>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0103a45:	80 f9 64             	cmp    $0x64,%cl
f0103a48:	75 d1                	jne    f0103a1b <debuginfo_eip+0x1f2>
f0103a4a:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0103a4e:	74 cb                	je     f0103a1b <debuginfo_eip+0x1f2>
f0103a50:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103a53:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0103a57:	74 03                	je     f0103a5c <debuginfo_eip+0x233>
f0103a59:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103a5c:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0103a5f:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0103a62:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0103a65:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0103a68:	8b 75 b8             	mov    -0x48(%ebp),%esi
f0103a6b:	29 f0                	sub    %esi,%eax
f0103a6d:	39 c2                	cmp    %eax,%edx
f0103a6f:	73 04                	jae    f0103a75 <debuginfo_eip+0x24c>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0103a71:	01 f2                	add    %esi,%edx
f0103a73:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103a75:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103a78:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103a7b:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103a80:	39 f2                	cmp    %esi,%edx
f0103a82:	7d 67                	jge    f0103aeb <debuginfo_eip+0x2c2>
		for (lline = lfun + 1;
f0103a84:	83 c2 01             	add    $0x1,%edx
f0103a87:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0103a8a:	89 d0                	mov    %edx,%eax
f0103a8c:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0103a8f:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0103a92:	8d 14 97             	lea    (%edi,%edx,4),%edx
f0103a95:	eb 04                	jmp    f0103a9b <debuginfo_eip+0x272>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0103a97:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0103a9b:	39 c6                	cmp    %eax,%esi
f0103a9d:	7e 47                	jle    f0103ae6 <debuginfo_eip+0x2bd>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103a9f:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103aa3:	83 c0 01             	add    $0x1,%eax
f0103aa6:	83 c2 0c             	add    $0xc,%edx
f0103aa9:	80 f9 a0             	cmp    $0xa0,%cl
f0103aac:	74 e9                	je     f0103a97 <debuginfo_eip+0x26e>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103aae:	b8 00 00 00 00       	mov    $0x0,%eax
f0103ab3:	eb 36                	jmp    f0103aeb <debuginfo_eip+0x2c2>
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.

		if(user_mem_check(curenv, usd, sizeof(struct UserStabData), PTE_U) < 0)
		{
			return -1;
f0103ab5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103aba:	eb 2f                	jmp    f0103aeb <debuginfo_eip+0x2c2>

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if(user_mem_check(curenv, stabs, stab_end-stabs, PTE_U) < 0)
		{
			return -1;
f0103abc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103ac1:	eb 28                	jmp    f0103aeb <debuginfo_eip+0x2c2>
		}
		
		if(user_mem_check(curenv, stabstr, stabstr_end-stabstr, PTE_U) < 0)
		{
			return -1;
f0103ac3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103ac8:	eb 21                	jmp    f0103aeb <debuginfo_eip+0x2c2>
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0103aca:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103acf:	eb 1a                	jmp    f0103aeb <debuginfo_eip+0x2c2>
f0103ad1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103ad6:	eb 13                	jmp    f0103aeb <debuginfo_eip+0x2c2>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0103ad8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103add:	eb 0c                	jmp    f0103aeb <debuginfo_eip+0x2c2>
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
	//cprintf("%d	%d",lline,rline);
	if(lline <= rline)
		info->eip_line = stabs[lline].n_desc;
	else
		return -1;
f0103adf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103ae4:	eb 05                	jmp    f0103aeb <debuginfo_eip+0x2c2>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103ae6:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103aeb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103aee:	5b                   	pop    %ebx
f0103aef:	5e                   	pop    %esi
f0103af0:	5f                   	pop    %edi
f0103af1:	5d                   	pop    %ebp
f0103af2:	c3                   	ret    

f0103af3 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103af3:	55                   	push   %ebp
f0103af4:	89 e5                	mov    %esp,%ebp
f0103af6:	57                   	push   %edi
f0103af7:	56                   	push   %esi
f0103af8:	53                   	push   %ebx
f0103af9:	83 ec 1c             	sub    $0x1c,%esp
f0103afc:	89 c7                	mov    %eax,%edi
f0103afe:	89 d6                	mov    %edx,%esi
f0103b00:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b03:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103b06:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103b09:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103b0c:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0103b0f:	bb 00 00 00 00       	mov    $0x0,%ebx
f0103b14:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0103b17:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0103b1a:	39 d3                	cmp    %edx,%ebx
f0103b1c:	72 05                	jb     f0103b23 <printnum+0x30>
f0103b1e:	39 45 10             	cmp    %eax,0x10(%ebp)
f0103b21:	77 45                	ja     f0103b68 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0103b23:	83 ec 0c             	sub    $0xc,%esp
f0103b26:	ff 75 18             	pushl  0x18(%ebp)
f0103b29:	8b 45 14             	mov    0x14(%ebp),%eax
f0103b2c:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0103b2f:	53                   	push   %ebx
f0103b30:	ff 75 10             	pushl  0x10(%ebp)
f0103b33:	83 ec 08             	sub    $0x8,%esp
f0103b36:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103b39:	ff 75 e0             	pushl  -0x20(%ebp)
f0103b3c:	ff 75 dc             	pushl  -0x24(%ebp)
f0103b3f:	ff 75 d8             	pushl  -0x28(%ebp)
f0103b42:	e8 69 09 00 00       	call   f01044b0 <__udivdi3>
f0103b47:	83 c4 18             	add    $0x18,%esp
f0103b4a:	52                   	push   %edx
f0103b4b:	50                   	push   %eax
f0103b4c:	89 f2                	mov    %esi,%edx
f0103b4e:	89 f8                	mov    %edi,%eax
f0103b50:	e8 9e ff ff ff       	call   f0103af3 <printnum>
f0103b55:	83 c4 20             	add    $0x20,%esp
f0103b58:	eb 18                	jmp    f0103b72 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0103b5a:	83 ec 08             	sub    $0x8,%esp
f0103b5d:	56                   	push   %esi
f0103b5e:	ff 75 18             	pushl  0x18(%ebp)
f0103b61:	ff d7                	call   *%edi
f0103b63:	83 c4 10             	add    $0x10,%esp
f0103b66:	eb 03                	jmp    f0103b6b <printnum+0x78>
f0103b68:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103b6b:	83 eb 01             	sub    $0x1,%ebx
f0103b6e:	85 db                	test   %ebx,%ebx
f0103b70:	7f e8                	jg     f0103b5a <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103b72:	83 ec 08             	sub    $0x8,%esp
f0103b75:	56                   	push   %esi
f0103b76:	83 ec 04             	sub    $0x4,%esp
f0103b79:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103b7c:	ff 75 e0             	pushl  -0x20(%ebp)
f0103b7f:	ff 75 dc             	pushl  -0x24(%ebp)
f0103b82:	ff 75 d8             	pushl  -0x28(%ebp)
f0103b85:	e8 56 0a 00 00       	call   f01045e0 <__umoddi3>
f0103b8a:	83 c4 14             	add    $0x14,%esp
f0103b8d:	0f be 80 f2 5b 10 f0 	movsbl -0xfefa40e(%eax),%eax
f0103b94:	50                   	push   %eax
f0103b95:	ff d7                	call   *%edi
}
f0103b97:	83 c4 10             	add    $0x10,%esp
f0103b9a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103b9d:	5b                   	pop    %ebx
f0103b9e:	5e                   	pop    %esi
f0103b9f:	5f                   	pop    %edi
f0103ba0:	5d                   	pop    %ebp
f0103ba1:	c3                   	ret    

f0103ba2 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0103ba2:	55                   	push   %ebp
f0103ba3:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0103ba5:	83 fa 01             	cmp    $0x1,%edx
f0103ba8:	7e 0e                	jle    f0103bb8 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0103baa:	8b 10                	mov    (%eax),%edx
f0103bac:	8d 4a 08             	lea    0x8(%edx),%ecx
f0103baf:	89 08                	mov    %ecx,(%eax)
f0103bb1:	8b 02                	mov    (%edx),%eax
f0103bb3:	8b 52 04             	mov    0x4(%edx),%edx
f0103bb6:	eb 22                	jmp    f0103bda <getuint+0x38>
	else if (lflag)
f0103bb8:	85 d2                	test   %edx,%edx
f0103bba:	74 10                	je     f0103bcc <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0103bbc:	8b 10                	mov    (%eax),%edx
f0103bbe:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103bc1:	89 08                	mov    %ecx,(%eax)
f0103bc3:	8b 02                	mov    (%edx),%eax
f0103bc5:	ba 00 00 00 00       	mov    $0x0,%edx
f0103bca:	eb 0e                	jmp    f0103bda <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0103bcc:	8b 10                	mov    (%eax),%edx
f0103bce:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103bd1:	89 08                	mov    %ecx,(%eax)
f0103bd3:	8b 02                	mov    (%edx),%eax
f0103bd5:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0103bda:	5d                   	pop    %ebp
f0103bdb:	c3                   	ret    

f0103bdc <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103bdc:	55                   	push   %ebp
f0103bdd:	89 e5                	mov    %esp,%ebp
f0103bdf:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0103be2:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103be6:	8b 10                	mov    (%eax),%edx
f0103be8:	3b 50 04             	cmp    0x4(%eax),%edx
f0103beb:	73 0a                	jae    f0103bf7 <sprintputch+0x1b>
		*b->buf++ = ch;
f0103bed:	8d 4a 01             	lea    0x1(%edx),%ecx
f0103bf0:	89 08                	mov    %ecx,(%eax)
f0103bf2:	8b 45 08             	mov    0x8(%ebp),%eax
f0103bf5:	88 02                	mov    %al,(%edx)
}
f0103bf7:	5d                   	pop    %ebp
f0103bf8:	c3                   	ret    

f0103bf9 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0103bf9:	55                   	push   %ebp
f0103bfa:	89 e5                	mov    %esp,%ebp
f0103bfc:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0103bff:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0103c02:	50                   	push   %eax
f0103c03:	ff 75 10             	pushl  0x10(%ebp)
f0103c06:	ff 75 0c             	pushl  0xc(%ebp)
f0103c09:	ff 75 08             	pushl  0x8(%ebp)
f0103c0c:	e8 05 00 00 00       	call   f0103c16 <vprintfmt>
	va_end(ap);
}
f0103c11:	83 c4 10             	add    $0x10,%esp
f0103c14:	c9                   	leave  
f0103c15:	c3                   	ret    

f0103c16 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0103c16:	55                   	push   %ebp
f0103c17:	89 e5                	mov    %esp,%ebp
f0103c19:	57                   	push   %edi
f0103c1a:	56                   	push   %esi
f0103c1b:	53                   	push   %ebx
f0103c1c:	83 ec 2c             	sub    $0x2c,%esp
f0103c1f:	8b 75 08             	mov    0x8(%ebp),%esi
f0103c22:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103c25:	8b 7d 10             	mov    0x10(%ebp),%edi
f0103c28:	eb 12                	jmp    f0103c3c <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0103c2a:	85 c0                	test   %eax,%eax
f0103c2c:	0f 84 a9 03 00 00    	je     f0103fdb <vprintfmt+0x3c5>
				return;
			putch(ch, putdat);
f0103c32:	83 ec 08             	sub    $0x8,%esp
f0103c35:	53                   	push   %ebx
f0103c36:	50                   	push   %eax
f0103c37:	ff d6                	call   *%esi
f0103c39:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103c3c:	83 c7 01             	add    $0x1,%edi
f0103c3f:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103c43:	83 f8 25             	cmp    $0x25,%eax
f0103c46:	75 e2                	jne    f0103c2a <vprintfmt+0x14>
f0103c48:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0103c4c:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0103c53:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103c5a:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0103c61:	ba 00 00 00 00       	mov    $0x0,%edx
f0103c66:	eb 07                	jmp    f0103c6f <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103c68:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0103c6b:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103c6f:	8d 47 01             	lea    0x1(%edi),%eax
f0103c72:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103c75:	0f b6 07             	movzbl (%edi),%eax
f0103c78:	0f b6 c8             	movzbl %al,%ecx
f0103c7b:	83 e8 23             	sub    $0x23,%eax
f0103c7e:	3c 55                	cmp    $0x55,%al
f0103c80:	0f 87 3a 03 00 00    	ja     f0103fc0 <vprintfmt+0x3aa>
f0103c86:	0f b6 c0             	movzbl %al,%eax
f0103c89:	ff 24 85 80 5c 10 f0 	jmp    *-0xfefa380(,%eax,4)
f0103c90:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0103c93:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0103c97:	eb d6                	jmp    f0103c6f <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103c99:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103c9c:	b8 00 00 00 00       	mov    $0x0,%eax
f0103ca1:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0103ca4:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0103ca7:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0103cab:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0103cae:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0103cb1:	83 fa 09             	cmp    $0x9,%edx
f0103cb4:	77 39                	ja     f0103cef <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0103cb6:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0103cb9:	eb e9                	jmp    f0103ca4 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0103cbb:	8b 45 14             	mov    0x14(%ebp),%eax
f0103cbe:	8d 48 04             	lea    0x4(%eax),%ecx
f0103cc1:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0103cc4:	8b 00                	mov    (%eax),%eax
f0103cc6:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103cc9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0103ccc:	eb 27                	jmp    f0103cf5 <vprintfmt+0xdf>
f0103cce:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103cd1:	85 c0                	test   %eax,%eax
f0103cd3:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103cd8:	0f 49 c8             	cmovns %eax,%ecx
f0103cdb:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103cde:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103ce1:	eb 8c                	jmp    f0103c6f <vprintfmt+0x59>
f0103ce3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0103ce6:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0103ced:	eb 80                	jmp    f0103c6f <vprintfmt+0x59>
f0103cef:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0103cf2:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0103cf5:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103cf9:	0f 89 70 ff ff ff    	jns    f0103c6f <vprintfmt+0x59>
				width = precision, precision = -1;
f0103cff:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103d02:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103d05:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103d0c:	e9 5e ff ff ff       	jmp    f0103c6f <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0103d11:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103d14:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0103d17:	e9 53 ff ff ff       	jmp    f0103c6f <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0103d1c:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d1f:	8d 50 04             	lea    0x4(%eax),%edx
f0103d22:	89 55 14             	mov    %edx,0x14(%ebp)
f0103d25:	83 ec 08             	sub    $0x8,%esp
f0103d28:	53                   	push   %ebx
f0103d29:	ff 30                	pushl  (%eax)
f0103d2b:	ff d6                	call   *%esi
			break;
f0103d2d:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103d30:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0103d33:	e9 04 ff ff ff       	jmp    f0103c3c <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0103d38:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d3b:	8d 50 04             	lea    0x4(%eax),%edx
f0103d3e:	89 55 14             	mov    %edx,0x14(%ebp)
f0103d41:	8b 00                	mov    (%eax),%eax
f0103d43:	99                   	cltd   
f0103d44:	31 d0                	xor    %edx,%eax
f0103d46:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0103d48:	83 f8 07             	cmp    $0x7,%eax
f0103d4b:	7f 0b                	jg     f0103d58 <vprintfmt+0x142>
f0103d4d:	8b 14 85 e0 5d 10 f0 	mov    -0xfefa220(,%eax,4),%edx
f0103d54:	85 d2                	test   %edx,%edx
f0103d56:	75 18                	jne    f0103d70 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0103d58:	50                   	push   %eax
f0103d59:	68 0a 5c 10 f0       	push   $0xf0105c0a
f0103d5e:	53                   	push   %ebx
f0103d5f:	56                   	push   %esi
f0103d60:	e8 94 fe ff ff       	call   f0103bf9 <printfmt>
f0103d65:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103d68:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0103d6b:	e9 cc fe ff ff       	jmp    f0103c3c <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0103d70:	52                   	push   %edx
f0103d71:	68 79 54 10 f0       	push   $0xf0105479
f0103d76:	53                   	push   %ebx
f0103d77:	56                   	push   %esi
f0103d78:	e8 7c fe ff ff       	call   f0103bf9 <printfmt>
f0103d7d:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103d80:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103d83:	e9 b4 fe ff ff       	jmp    f0103c3c <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0103d88:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d8b:	8d 50 04             	lea    0x4(%eax),%edx
f0103d8e:	89 55 14             	mov    %edx,0x14(%ebp)
f0103d91:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0103d93:	85 ff                	test   %edi,%edi
f0103d95:	b8 03 5c 10 f0       	mov    $0xf0105c03,%eax
f0103d9a:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0103d9d:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103da1:	0f 8e 94 00 00 00    	jle    f0103e3b <vprintfmt+0x225>
f0103da7:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0103dab:	0f 84 98 00 00 00    	je     f0103e49 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0103db1:	83 ec 08             	sub    $0x8,%esp
f0103db4:	ff 75 d0             	pushl  -0x30(%ebp)
f0103db7:	57                   	push   %edi
f0103db8:	e8 7f 03 00 00       	call   f010413c <strnlen>
f0103dbd:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103dc0:	29 c1                	sub    %eax,%ecx
f0103dc2:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0103dc5:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0103dc8:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0103dcc:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103dcf:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103dd2:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103dd4:	eb 0f                	jmp    f0103de5 <vprintfmt+0x1cf>
					putch(padc, putdat);
f0103dd6:	83 ec 08             	sub    $0x8,%esp
f0103dd9:	53                   	push   %ebx
f0103dda:	ff 75 e0             	pushl  -0x20(%ebp)
f0103ddd:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103ddf:	83 ef 01             	sub    $0x1,%edi
f0103de2:	83 c4 10             	add    $0x10,%esp
f0103de5:	85 ff                	test   %edi,%edi
f0103de7:	7f ed                	jg     f0103dd6 <vprintfmt+0x1c0>
f0103de9:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103dec:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0103def:	85 c9                	test   %ecx,%ecx
f0103df1:	b8 00 00 00 00       	mov    $0x0,%eax
f0103df6:	0f 49 c1             	cmovns %ecx,%eax
f0103df9:	29 c1                	sub    %eax,%ecx
f0103dfb:	89 75 08             	mov    %esi,0x8(%ebp)
f0103dfe:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103e01:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103e04:	89 cb                	mov    %ecx,%ebx
f0103e06:	eb 4d                	jmp    f0103e55 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0103e08:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0103e0c:	74 1b                	je     f0103e29 <vprintfmt+0x213>
f0103e0e:	0f be c0             	movsbl %al,%eax
f0103e11:	83 e8 20             	sub    $0x20,%eax
f0103e14:	83 f8 5e             	cmp    $0x5e,%eax
f0103e17:	76 10                	jbe    f0103e29 <vprintfmt+0x213>
					putch('?', putdat);
f0103e19:	83 ec 08             	sub    $0x8,%esp
f0103e1c:	ff 75 0c             	pushl  0xc(%ebp)
f0103e1f:	6a 3f                	push   $0x3f
f0103e21:	ff 55 08             	call   *0x8(%ebp)
f0103e24:	83 c4 10             	add    $0x10,%esp
f0103e27:	eb 0d                	jmp    f0103e36 <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0103e29:	83 ec 08             	sub    $0x8,%esp
f0103e2c:	ff 75 0c             	pushl  0xc(%ebp)
f0103e2f:	52                   	push   %edx
f0103e30:	ff 55 08             	call   *0x8(%ebp)
f0103e33:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103e36:	83 eb 01             	sub    $0x1,%ebx
f0103e39:	eb 1a                	jmp    f0103e55 <vprintfmt+0x23f>
f0103e3b:	89 75 08             	mov    %esi,0x8(%ebp)
f0103e3e:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103e41:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103e44:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103e47:	eb 0c                	jmp    f0103e55 <vprintfmt+0x23f>
f0103e49:	89 75 08             	mov    %esi,0x8(%ebp)
f0103e4c:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103e4f:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103e52:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103e55:	83 c7 01             	add    $0x1,%edi
f0103e58:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103e5c:	0f be d0             	movsbl %al,%edx
f0103e5f:	85 d2                	test   %edx,%edx
f0103e61:	74 23                	je     f0103e86 <vprintfmt+0x270>
f0103e63:	85 f6                	test   %esi,%esi
f0103e65:	78 a1                	js     f0103e08 <vprintfmt+0x1f2>
f0103e67:	83 ee 01             	sub    $0x1,%esi
f0103e6a:	79 9c                	jns    f0103e08 <vprintfmt+0x1f2>
f0103e6c:	89 df                	mov    %ebx,%edi
f0103e6e:	8b 75 08             	mov    0x8(%ebp),%esi
f0103e71:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103e74:	eb 18                	jmp    f0103e8e <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0103e76:	83 ec 08             	sub    $0x8,%esp
f0103e79:	53                   	push   %ebx
f0103e7a:	6a 20                	push   $0x20
f0103e7c:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103e7e:	83 ef 01             	sub    $0x1,%edi
f0103e81:	83 c4 10             	add    $0x10,%esp
f0103e84:	eb 08                	jmp    f0103e8e <vprintfmt+0x278>
f0103e86:	89 df                	mov    %ebx,%edi
f0103e88:	8b 75 08             	mov    0x8(%ebp),%esi
f0103e8b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103e8e:	85 ff                	test   %edi,%edi
f0103e90:	7f e4                	jg     f0103e76 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103e92:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103e95:	e9 a2 fd ff ff       	jmp    f0103c3c <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103e9a:	83 fa 01             	cmp    $0x1,%edx
f0103e9d:	7e 16                	jle    f0103eb5 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0103e9f:	8b 45 14             	mov    0x14(%ebp),%eax
f0103ea2:	8d 50 08             	lea    0x8(%eax),%edx
f0103ea5:	89 55 14             	mov    %edx,0x14(%ebp)
f0103ea8:	8b 50 04             	mov    0x4(%eax),%edx
f0103eab:	8b 00                	mov    (%eax),%eax
f0103ead:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103eb0:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0103eb3:	eb 32                	jmp    f0103ee7 <vprintfmt+0x2d1>
	else if (lflag)
f0103eb5:	85 d2                	test   %edx,%edx
f0103eb7:	74 18                	je     f0103ed1 <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f0103eb9:	8b 45 14             	mov    0x14(%ebp),%eax
f0103ebc:	8d 50 04             	lea    0x4(%eax),%edx
f0103ebf:	89 55 14             	mov    %edx,0x14(%ebp)
f0103ec2:	8b 00                	mov    (%eax),%eax
f0103ec4:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103ec7:	89 c1                	mov    %eax,%ecx
f0103ec9:	c1 f9 1f             	sar    $0x1f,%ecx
f0103ecc:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0103ecf:	eb 16                	jmp    f0103ee7 <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f0103ed1:	8b 45 14             	mov    0x14(%ebp),%eax
f0103ed4:	8d 50 04             	lea    0x4(%eax),%edx
f0103ed7:	89 55 14             	mov    %edx,0x14(%ebp)
f0103eda:	8b 00                	mov    (%eax),%eax
f0103edc:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103edf:	89 c1                	mov    %eax,%ecx
f0103ee1:	c1 f9 1f             	sar    $0x1f,%ecx
f0103ee4:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0103ee7:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103eea:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0103eed:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0103ef2:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103ef6:	0f 89 90 00 00 00    	jns    f0103f8c <vprintfmt+0x376>
				putch('-', putdat);
f0103efc:	83 ec 08             	sub    $0x8,%esp
f0103eff:	53                   	push   %ebx
f0103f00:	6a 2d                	push   $0x2d
f0103f02:	ff d6                	call   *%esi
				num = -(long long) num;
f0103f04:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103f07:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103f0a:	f7 d8                	neg    %eax
f0103f0c:	83 d2 00             	adc    $0x0,%edx
f0103f0f:	f7 da                	neg    %edx
f0103f11:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0103f14:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0103f19:	eb 71                	jmp    f0103f8c <vprintfmt+0x376>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0103f1b:	8d 45 14             	lea    0x14(%ebp),%eax
f0103f1e:	e8 7f fc ff ff       	call   f0103ba2 <getuint>
			base = 10;
f0103f23:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0103f28:	eb 62                	jmp    f0103f8c <vprintfmt+0x376>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f0103f2a:	8d 45 14             	lea    0x14(%ebp),%eax
f0103f2d:	e8 70 fc ff ff       	call   f0103ba2 <getuint>
			base = 8;
			printnum(putch, putdat, num, base, width, padc);
f0103f32:	83 ec 0c             	sub    $0xc,%esp
f0103f35:	0f be 4d d4          	movsbl -0x2c(%ebp),%ecx
f0103f39:	51                   	push   %ecx
f0103f3a:	ff 75 e0             	pushl  -0x20(%ebp)
f0103f3d:	6a 08                	push   $0x8
f0103f3f:	52                   	push   %edx
f0103f40:	50                   	push   %eax
f0103f41:	89 da                	mov    %ebx,%edx
f0103f43:	89 f0                	mov    %esi,%eax
f0103f45:	e8 a9 fb ff ff       	call   f0103af3 <printnum>
			break;
f0103f4a:	83 c4 20             	add    $0x20,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103f4d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
			base = 8;
			printnum(putch, putdat, num, base, width, padc);
			break;
f0103f50:	e9 e7 fc ff ff       	jmp    f0103c3c <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
f0103f55:	83 ec 08             	sub    $0x8,%esp
f0103f58:	53                   	push   %ebx
f0103f59:	6a 30                	push   $0x30
f0103f5b:	ff d6                	call   *%esi
			putch('x', putdat);
f0103f5d:	83 c4 08             	add    $0x8,%esp
f0103f60:	53                   	push   %ebx
f0103f61:	6a 78                	push   $0x78
f0103f63:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0103f65:	8b 45 14             	mov    0x14(%ebp),%eax
f0103f68:	8d 50 04             	lea    0x4(%eax),%edx
f0103f6b:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0103f6e:	8b 00                	mov    (%eax),%eax
f0103f70:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0103f75:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0103f78:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0103f7d:	eb 0d                	jmp    f0103f8c <vprintfmt+0x376>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0103f7f:	8d 45 14             	lea    0x14(%ebp),%eax
f0103f82:	e8 1b fc ff ff       	call   f0103ba2 <getuint>
			base = 16;
f0103f87:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0103f8c:	83 ec 0c             	sub    $0xc,%esp
f0103f8f:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0103f93:	57                   	push   %edi
f0103f94:	ff 75 e0             	pushl  -0x20(%ebp)
f0103f97:	51                   	push   %ecx
f0103f98:	52                   	push   %edx
f0103f99:	50                   	push   %eax
f0103f9a:	89 da                	mov    %ebx,%edx
f0103f9c:	89 f0                	mov    %esi,%eax
f0103f9e:	e8 50 fb ff ff       	call   f0103af3 <printnum>
			break;
f0103fa3:	83 c4 20             	add    $0x20,%esp
f0103fa6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103fa9:	e9 8e fc ff ff       	jmp    f0103c3c <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0103fae:	83 ec 08             	sub    $0x8,%esp
f0103fb1:	53                   	push   %ebx
f0103fb2:	51                   	push   %ecx
f0103fb3:	ff d6                	call   *%esi
			break;
f0103fb5:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103fb8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0103fbb:	e9 7c fc ff ff       	jmp    f0103c3c <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0103fc0:	83 ec 08             	sub    $0x8,%esp
f0103fc3:	53                   	push   %ebx
f0103fc4:	6a 25                	push   $0x25
f0103fc6:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0103fc8:	83 c4 10             	add    $0x10,%esp
f0103fcb:	eb 03                	jmp    f0103fd0 <vprintfmt+0x3ba>
f0103fcd:	83 ef 01             	sub    $0x1,%edi
f0103fd0:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0103fd4:	75 f7                	jne    f0103fcd <vprintfmt+0x3b7>
f0103fd6:	e9 61 fc ff ff       	jmp    f0103c3c <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0103fdb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103fde:	5b                   	pop    %ebx
f0103fdf:	5e                   	pop    %esi
f0103fe0:	5f                   	pop    %edi
f0103fe1:	5d                   	pop    %ebp
f0103fe2:	c3                   	ret    

f0103fe3 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103fe3:	55                   	push   %ebp
f0103fe4:	89 e5                	mov    %esp,%ebp
f0103fe6:	83 ec 18             	sub    $0x18,%esp
f0103fe9:	8b 45 08             	mov    0x8(%ebp),%eax
f0103fec:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0103fef:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103ff2:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103ff6:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0103ff9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0104000:	85 c0                	test   %eax,%eax
f0104002:	74 26                	je     f010402a <vsnprintf+0x47>
f0104004:	85 d2                	test   %edx,%edx
f0104006:	7e 22                	jle    f010402a <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0104008:	ff 75 14             	pushl  0x14(%ebp)
f010400b:	ff 75 10             	pushl  0x10(%ebp)
f010400e:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0104011:	50                   	push   %eax
f0104012:	68 dc 3b 10 f0       	push   $0xf0103bdc
f0104017:	e8 fa fb ff ff       	call   f0103c16 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010401c:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010401f:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0104022:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104025:	83 c4 10             	add    $0x10,%esp
f0104028:	eb 05                	jmp    f010402f <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f010402a:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f010402f:	c9                   	leave  
f0104030:	c3                   	ret    

f0104031 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0104031:	55                   	push   %ebp
f0104032:	89 e5                	mov    %esp,%ebp
f0104034:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0104037:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f010403a:	50                   	push   %eax
f010403b:	ff 75 10             	pushl  0x10(%ebp)
f010403e:	ff 75 0c             	pushl  0xc(%ebp)
f0104041:	ff 75 08             	pushl  0x8(%ebp)
f0104044:	e8 9a ff ff ff       	call   f0103fe3 <vsnprintf>
	va_end(ap);

	return rc;
}
f0104049:	c9                   	leave  
f010404a:	c3                   	ret    

f010404b <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f010404b:	55                   	push   %ebp
f010404c:	89 e5                	mov    %esp,%ebp
f010404e:	57                   	push   %edi
f010404f:	56                   	push   %esi
f0104050:	53                   	push   %ebx
f0104051:	83 ec 0c             	sub    $0xc,%esp
f0104054:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0104057:	85 c0                	test   %eax,%eax
f0104059:	74 11                	je     f010406c <readline+0x21>
		cprintf("%s", prompt);
f010405b:	83 ec 08             	sub    $0x8,%esp
f010405e:	50                   	push   %eax
f010405f:	68 79 54 10 f0       	push   $0xf0105479
f0104064:	e8 40 ee ff ff       	call   f0102ea9 <cprintf>
f0104069:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f010406c:	83 ec 0c             	sub    $0xc,%esp
f010406f:	6a 00                	push   $0x0
f0104071:	e8 b2 c5 ff ff       	call   f0100628 <iscons>
f0104076:	89 c7                	mov    %eax,%edi
f0104078:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010407b:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0104080:	e8 92 c5 ff ff       	call   f0100617 <getchar>
f0104085:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0104087:	85 c0                	test   %eax,%eax
f0104089:	79 18                	jns    f01040a3 <readline+0x58>
			cprintf("read error: %e\n", c);
f010408b:	83 ec 08             	sub    $0x8,%esp
f010408e:	50                   	push   %eax
f010408f:	68 00 5e 10 f0       	push   $0xf0105e00
f0104094:	e8 10 ee ff ff       	call   f0102ea9 <cprintf>
			return NULL;
f0104099:	83 c4 10             	add    $0x10,%esp
f010409c:	b8 00 00 00 00       	mov    $0x0,%eax
f01040a1:	eb 79                	jmp    f010411c <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01040a3:	83 f8 08             	cmp    $0x8,%eax
f01040a6:	0f 94 c2             	sete   %dl
f01040a9:	83 f8 7f             	cmp    $0x7f,%eax
f01040ac:	0f 94 c0             	sete   %al
f01040af:	08 c2                	or     %al,%dl
f01040b1:	74 1a                	je     f01040cd <readline+0x82>
f01040b3:	85 f6                	test   %esi,%esi
f01040b5:	7e 16                	jle    f01040cd <readline+0x82>
			if (echoing)
f01040b7:	85 ff                	test   %edi,%edi
f01040b9:	74 0d                	je     f01040c8 <readline+0x7d>
				cputchar('\b');
f01040bb:	83 ec 0c             	sub    $0xc,%esp
f01040be:	6a 08                	push   $0x8
f01040c0:	e8 42 c5 ff ff       	call   f0100607 <cputchar>
f01040c5:	83 c4 10             	add    $0x10,%esp
			i--;
f01040c8:	83 ee 01             	sub    $0x1,%esi
f01040cb:	eb b3                	jmp    f0104080 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01040cd:	83 fb 1f             	cmp    $0x1f,%ebx
f01040d0:	7e 23                	jle    f01040f5 <readline+0xaa>
f01040d2:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01040d8:	7f 1b                	jg     f01040f5 <readline+0xaa>
			if (echoing)
f01040da:	85 ff                	test   %edi,%edi
f01040dc:	74 0c                	je     f01040ea <readline+0x9f>
				cputchar(c);
f01040de:	83 ec 0c             	sub    $0xc,%esp
f01040e1:	53                   	push   %ebx
f01040e2:	e8 20 c5 ff ff       	call   f0100607 <cputchar>
f01040e7:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f01040ea:	88 9e 40 c8 17 f0    	mov    %bl,-0xfe837c0(%esi)
f01040f0:	8d 76 01             	lea    0x1(%esi),%esi
f01040f3:	eb 8b                	jmp    f0104080 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f01040f5:	83 fb 0a             	cmp    $0xa,%ebx
f01040f8:	74 05                	je     f01040ff <readline+0xb4>
f01040fa:	83 fb 0d             	cmp    $0xd,%ebx
f01040fd:	75 81                	jne    f0104080 <readline+0x35>
			if (echoing)
f01040ff:	85 ff                	test   %edi,%edi
f0104101:	74 0d                	je     f0104110 <readline+0xc5>
				cputchar('\n');
f0104103:	83 ec 0c             	sub    $0xc,%esp
f0104106:	6a 0a                	push   $0xa
f0104108:	e8 fa c4 ff ff       	call   f0100607 <cputchar>
f010410d:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0104110:	c6 86 40 c8 17 f0 00 	movb   $0x0,-0xfe837c0(%esi)
			return buf;
f0104117:	b8 40 c8 17 f0       	mov    $0xf017c840,%eax
		}
	}
}
f010411c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010411f:	5b                   	pop    %ebx
f0104120:	5e                   	pop    %esi
f0104121:	5f                   	pop    %edi
f0104122:	5d                   	pop    %ebp
f0104123:	c3                   	ret    

f0104124 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0104124:	55                   	push   %ebp
f0104125:	89 e5                	mov    %esp,%ebp
f0104127:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f010412a:	b8 00 00 00 00       	mov    $0x0,%eax
f010412f:	eb 03                	jmp    f0104134 <strlen+0x10>
		n++;
f0104131:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0104134:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0104138:	75 f7                	jne    f0104131 <strlen+0xd>
		n++;
	return n;
}
f010413a:	5d                   	pop    %ebp
f010413b:	c3                   	ret    

f010413c <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010413c:	55                   	push   %ebp
f010413d:	89 e5                	mov    %esp,%ebp
f010413f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104142:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104145:	ba 00 00 00 00       	mov    $0x0,%edx
f010414a:	eb 03                	jmp    f010414f <strnlen+0x13>
		n++;
f010414c:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010414f:	39 c2                	cmp    %eax,%edx
f0104151:	74 08                	je     f010415b <strnlen+0x1f>
f0104153:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0104157:	75 f3                	jne    f010414c <strnlen+0x10>
f0104159:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f010415b:	5d                   	pop    %ebp
f010415c:	c3                   	ret    

f010415d <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010415d:	55                   	push   %ebp
f010415e:	89 e5                	mov    %esp,%ebp
f0104160:	53                   	push   %ebx
f0104161:	8b 45 08             	mov    0x8(%ebp),%eax
f0104164:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0104167:	89 c2                	mov    %eax,%edx
f0104169:	83 c2 01             	add    $0x1,%edx
f010416c:	83 c1 01             	add    $0x1,%ecx
f010416f:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0104173:	88 5a ff             	mov    %bl,-0x1(%edx)
f0104176:	84 db                	test   %bl,%bl
f0104178:	75 ef                	jne    f0104169 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f010417a:	5b                   	pop    %ebx
f010417b:	5d                   	pop    %ebp
f010417c:	c3                   	ret    

f010417d <strcat>:

char *
strcat(char *dst, const char *src)
{
f010417d:	55                   	push   %ebp
f010417e:	89 e5                	mov    %esp,%ebp
f0104180:	53                   	push   %ebx
f0104181:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0104184:	53                   	push   %ebx
f0104185:	e8 9a ff ff ff       	call   f0104124 <strlen>
f010418a:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f010418d:	ff 75 0c             	pushl  0xc(%ebp)
f0104190:	01 d8                	add    %ebx,%eax
f0104192:	50                   	push   %eax
f0104193:	e8 c5 ff ff ff       	call   f010415d <strcpy>
	return dst;
}
f0104198:	89 d8                	mov    %ebx,%eax
f010419a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010419d:	c9                   	leave  
f010419e:	c3                   	ret    

f010419f <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010419f:	55                   	push   %ebp
f01041a0:	89 e5                	mov    %esp,%ebp
f01041a2:	56                   	push   %esi
f01041a3:	53                   	push   %ebx
f01041a4:	8b 75 08             	mov    0x8(%ebp),%esi
f01041a7:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01041aa:	89 f3                	mov    %esi,%ebx
f01041ac:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01041af:	89 f2                	mov    %esi,%edx
f01041b1:	eb 0f                	jmp    f01041c2 <strncpy+0x23>
		*dst++ = *src;
f01041b3:	83 c2 01             	add    $0x1,%edx
f01041b6:	0f b6 01             	movzbl (%ecx),%eax
f01041b9:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01041bc:	80 39 01             	cmpb   $0x1,(%ecx)
f01041bf:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01041c2:	39 da                	cmp    %ebx,%edx
f01041c4:	75 ed                	jne    f01041b3 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01041c6:	89 f0                	mov    %esi,%eax
f01041c8:	5b                   	pop    %ebx
f01041c9:	5e                   	pop    %esi
f01041ca:	5d                   	pop    %ebp
f01041cb:	c3                   	ret    

f01041cc <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01041cc:	55                   	push   %ebp
f01041cd:	89 e5                	mov    %esp,%ebp
f01041cf:	56                   	push   %esi
f01041d0:	53                   	push   %ebx
f01041d1:	8b 75 08             	mov    0x8(%ebp),%esi
f01041d4:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01041d7:	8b 55 10             	mov    0x10(%ebp),%edx
f01041da:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01041dc:	85 d2                	test   %edx,%edx
f01041de:	74 21                	je     f0104201 <strlcpy+0x35>
f01041e0:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f01041e4:	89 f2                	mov    %esi,%edx
f01041e6:	eb 09                	jmp    f01041f1 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01041e8:	83 c2 01             	add    $0x1,%edx
f01041eb:	83 c1 01             	add    $0x1,%ecx
f01041ee:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01041f1:	39 c2                	cmp    %eax,%edx
f01041f3:	74 09                	je     f01041fe <strlcpy+0x32>
f01041f5:	0f b6 19             	movzbl (%ecx),%ebx
f01041f8:	84 db                	test   %bl,%bl
f01041fa:	75 ec                	jne    f01041e8 <strlcpy+0x1c>
f01041fc:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f01041fe:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0104201:	29 f0                	sub    %esi,%eax
}
f0104203:	5b                   	pop    %ebx
f0104204:	5e                   	pop    %esi
f0104205:	5d                   	pop    %ebp
f0104206:	c3                   	ret    

f0104207 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0104207:	55                   	push   %ebp
f0104208:	89 e5                	mov    %esp,%ebp
f010420a:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010420d:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0104210:	eb 06                	jmp    f0104218 <strcmp+0x11>
		p++, q++;
f0104212:	83 c1 01             	add    $0x1,%ecx
f0104215:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0104218:	0f b6 01             	movzbl (%ecx),%eax
f010421b:	84 c0                	test   %al,%al
f010421d:	74 04                	je     f0104223 <strcmp+0x1c>
f010421f:	3a 02                	cmp    (%edx),%al
f0104221:	74 ef                	je     f0104212 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0104223:	0f b6 c0             	movzbl %al,%eax
f0104226:	0f b6 12             	movzbl (%edx),%edx
f0104229:	29 d0                	sub    %edx,%eax
}
f010422b:	5d                   	pop    %ebp
f010422c:	c3                   	ret    

f010422d <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f010422d:	55                   	push   %ebp
f010422e:	89 e5                	mov    %esp,%ebp
f0104230:	53                   	push   %ebx
f0104231:	8b 45 08             	mov    0x8(%ebp),%eax
f0104234:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104237:	89 c3                	mov    %eax,%ebx
f0104239:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f010423c:	eb 06                	jmp    f0104244 <strncmp+0x17>
		n--, p++, q++;
f010423e:	83 c0 01             	add    $0x1,%eax
f0104241:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0104244:	39 d8                	cmp    %ebx,%eax
f0104246:	74 15                	je     f010425d <strncmp+0x30>
f0104248:	0f b6 08             	movzbl (%eax),%ecx
f010424b:	84 c9                	test   %cl,%cl
f010424d:	74 04                	je     f0104253 <strncmp+0x26>
f010424f:	3a 0a                	cmp    (%edx),%cl
f0104251:	74 eb                	je     f010423e <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0104253:	0f b6 00             	movzbl (%eax),%eax
f0104256:	0f b6 12             	movzbl (%edx),%edx
f0104259:	29 d0                	sub    %edx,%eax
f010425b:	eb 05                	jmp    f0104262 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f010425d:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0104262:	5b                   	pop    %ebx
f0104263:	5d                   	pop    %ebp
f0104264:	c3                   	ret    

f0104265 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0104265:	55                   	push   %ebp
f0104266:	89 e5                	mov    %esp,%ebp
f0104268:	8b 45 08             	mov    0x8(%ebp),%eax
f010426b:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010426f:	eb 07                	jmp    f0104278 <strchr+0x13>
		if (*s == c)
f0104271:	38 ca                	cmp    %cl,%dl
f0104273:	74 0f                	je     f0104284 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0104275:	83 c0 01             	add    $0x1,%eax
f0104278:	0f b6 10             	movzbl (%eax),%edx
f010427b:	84 d2                	test   %dl,%dl
f010427d:	75 f2                	jne    f0104271 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f010427f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104284:	5d                   	pop    %ebp
f0104285:	c3                   	ret    

f0104286 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0104286:	55                   	push   %ebp
f0104287:	89 e5                	mov    %esp,%ebp
f0104289:	8b 45 08             	mov    0x8(%ebp),%eax
f010428c:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104290:	eb 03                	jmp    f0104295 <strfind+0xf>
f0104292:	83 c0 01             	add    $0x1,%eax
f0104295:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0104298:	38 ca                	cmp    %cl,%dl
f010429a:	74 04                	je     f01042a0 <strfind+0x1a>
f010429c:	84 d2                	test   %dl,%dl
f010429e:	75 f2                	jne    f0104292 <strfind+0xc>
			break;
	return (char *) s;
}
f01042a0:	5d                   	pop    %ebp
f01042a1:	c3                   	ret    

f01042a2 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01042a2:	55                   	push   %ebp
f01042a3:	89 e5                	mov    %esp,%ebp
f01042a5:	57                   	push   %edi
f01042a6:	56                   	push   %esi
f01042a7:	53                   	push   %ebx
f01042a8:	8b 7d 08             	mov    0x8(%ebp),%edi
f01042ab:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01042ae:	85 c9                	test   %ecx,%ecx
f01042b0:	74 36                	je     f01042e8 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01042b2:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01042b8:	75 28                	jne    f01042e2 <memset+0x40>
f01042ba:	f6 c1 03             	test   $0x3,%cl
f01042bd:	75 23                	jne    f01042e2 <memset+0x40>
		c &= 0xFF;
f01042bf:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01042c3:	89 d3                	mov    %edx,%ebx
f01042c5:	c1 e3 08             	shl    $0x8,%ebx
f01042c8:	89 d6                	mov    %edx,%esi
f01042ca:	c1 e6 18             	shl    $0x18,%esi
f01042cd:	89 d0                	mov    %edx,%eax
f01042cf:	c1 e0 10             	shl    $0x10,%eax
f01042d2:	09 f0                	or     %esi,%eax
f01042d4:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f01042d6:	89 d8                	mov    %ebx,%eax
f01042d8:	09 d0                	or     %edx,%eax
f01042da:	c1 e9 02             	shr    $0x2,%ecx
f01042dd:	fc                   	cld    
f01042de:	f3 ab                	rep stos %eax,%es:(%edi)
f01042e0:	eb 06                	jmp    f01042e8 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01042e2:	8b 45 0c             	mov    0xc(%ebp),%eax
f01042e5:	fc                   	cld    
f01042e6:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01042e8:	89 f8                	mov    %edi,%eax
f01042ea:	5b                   	pop    %ebx
f01042eb:	5e                   	pop    %esi
f01042ec:	5f                   	pop    %edi
f01042ed:	5d                   	pop    %ebp
f01042ee:	c3                   	ret    

f01042ef <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01042ef:	55                   	push   %ebp
f01042f0:	89 e5                	mov    %esp,%ebp
f01042f2:	57                   	push   %edi
f01042f3:	56                   	push   %esi
f01042f4:	8b 45 08             	mov    0x8(%ebp),%eax
f01042f7:	8b 75 0c             	mov    0xc(%ebp),%esi
f01042fa:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01042fd:	39 c6                	cmp    %eax,%esi
f01042ff:	73 35                	jae    f0104336 <memmove+0x47>
f0104301:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0104304:	39 d0                	cmp    %edx,%eax
f0104306:	73 2e                	jae    f0104336 <memmove+0x47>
		s += n;
		d += n;
f0104308:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010430b:	89 d6                	mov    %edx,%esi
f010430d:	09 fe                	or     %edi,%esi
f010430f:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0104315:	75 13                	jne    f010432a <memmove+0x3b>
f0104317:	f6 c1 03             	test   $0x3,%cl
f010431a:	75 0e                	jne    f010432a <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f010431c:	83 ef 04             	sub    $0x4,%edi
f010431f:	8d 72 fc             	lea    -0x4(%edx),%esi
f0104322:	c1 e9 02             	shr    $0x2,%ecx
f0104325:	fd                   	std    
f0104326:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104328:	eb 09                	jmp    f0104333 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f010432a:	83 ef 01             	sub    $0x1,%edi
f010432d:	8d 72 ff             	lea    -0x1(%edx),%esi
f0104330:	fd                   	std    
f0104331:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0104333:	fc                   	cld    
f0104334:	eb 1d                	jmp    f0104353 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104336:	89 f2                	mov    %esi,%edx
f0104338:	09 c2                	or     %eax,%edx
f010433a:	f6 c2 03             	test   $0x3,%dl
f010433d:	75 0f                	jne    f010434e <memmove+0x5f>
f010433f:	f6 c1 03             	test   $0x3,%cl
f0104342:	75 0a                	jne    f010434e <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0104344:	c1 e9 02             	shr    $0x2,%ecx
f0104347:	89 c7                	mov    %eax,%edi
f0104349:	fc                   	cld    
f010434a:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010434c:	eb 05                	jmp    f0104353 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f010434e:	89 c7                	mov    %eax,%edi
f0104350:	fc                   	cld    
f0104351:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0104353:	5e                   	pop    %esi
f0104354:	5f                   	pop    %edi
f0104355:	5d                   	pop    %ebp
f0104356:	c3                   	ret    

f0104357 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0104357:	55                   	push   %ebp
f0104358:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f010435a:	ff 75 10             	pushl  0x10(%ebp)
f010435d:	ff 75 0c             	pushl  0xc(%ebp)
f0104360:	ff 75 08             	pushl  0x8(%ebp)
f0104363:	e8 87 ff ff ff       	call   f01042ef <memmove>
}
f0104368:	c9                   	leave  
f0104369:	c3                   	ret    

f010436a <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010436a:	55                   	push   %ebp
f010436b:	89 e5                	mov    %esp,%ebp
f010436d:	56                   	push   %esi
f010436e:	53                   	push   %ebx
f010436f:	8b 45 08             	mov    0x8(%ebp),%eax
f0104372:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104375:	89 c6                	mov    %eax,%esi
f0104377:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010437a:	eb 1a                	jmp    f0104396 <memcmp+0x2c>
		if (*s1 != *s2)
f010437c:	0f b6 08             	movzbl (%eax),%ecx
f010437f:	0f b6 1a             	movzbl (%edx),%ebx
f0104382:	38 d9                	cmp    %bl,%cl
f0104384:	74 0a                	je     f0104390 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0104386:	0f b6 c1             	movzbl %cl,%eax
f0104389:	0f b6 db             	movzbl %bl,%ebx
f010438c:	29 d8                	sub    %ebx,%eax
f010438e:	eb 0f                	jmp    f010439f <memcmp+0x35>
		s1++, s2++;
f0104390:	83 c0 01             	add    $0x1,%eax
f0104393:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104396:	39 f0                	cmp    %esi,%eax
f0104398:	75 e2                	jne    f010437c <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010439a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010439f:	5b                   	pop    %ebx
f01043a0:	5e                   	pop    %esi
f01043a1:	5d                   	pop    %ebp
f01043a2:	c3                   	ret    

f01043a3 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01043a3:	55                   	push   %ebp
f01043a4:	89 e5                	mov    %esp,%ebp
f01043a6:	53                   	push   %ebx
f01043a7:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f01043aa:	89 c1                	mov    %eax,%ecx
f01043ac:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f01043af:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01043b3:	eb 0a                	jmp    f01043bf <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f01043b5:	0f b6 10             	movzbl (%eax),%edx
f01043b8:	39 da                	cmp    %ebx,%edx
f01043ba:	74 07                	je     f01043c3 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01043bc:	83 c0 01             	add    $0x1,%eax
f01043bf:	39 c8                	cmp    %ecx,%eax
f01043c1:	72 f2                	jb     f01043b5 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01043c3:	5b                   	pop    %ebx
f01043c4:	5d                   	pop    %ebp
f01043c5:	c3                   	ret    

f01043c6 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01043c6:	55                   	push   %ebp
f01043c7:	89 e5                	mov    %esp,%ebp
f01043c9:	57                   	push   %edi
f01043ca:	56                   	push   %esi
f01043cb:	53                   	push   %ebx
f01043cc:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01043cf:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01043d2:	eb 03                	jmp    f01043d7 <strtol+0x11>
		s++;
f01043d4:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01043d7:	0f b6 01             	movzbl (%ecx),%eax
f01043da:	3c 20                	cmp    $0x20,%al
f01043dc:	74 f6                	je     f01043d4 <strtol+0xe>
f01043de:	3c 09                	cmp    $0x9,%al
f01043e0:	74 f2                	je     f01043d4 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01043e2:	3c 2b                	cmp    $0x2b,%al
f01043e4:	75 0a                	jne    f01043f0 <strtol+0x2a>
		s++;
f01043e6:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01043e9:	bf 00 00 00 00       	mov    $0x0,%edi
f01043ee:	eb 11                	jmp    f0104401 <strtol+0x3b>
f01043f0:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01043f5:	3c 2d                	cmp    $0x2d,%al
f01043f7:	75 08                	jne    f0104401 <strtol+0x3b>
		s++, neg = 1;
f01043f9:	83 c1 01             	add    $0x1,%ecx
f01043fc:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0104401:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0104407:	75 15                	jne    f010441e <strtol+0x58>
f0104409:	80 39 30             	cmpb   $0x30,(%ecx)
f010440c:	75 10                	jne    f010441e <strtol+0x58>
f010440e:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0104412:	75 7c                	jne    f0104490 <strtol+0xca>
		s += 2, base = 16;
f0104414:	83 c1 02             	add    $0x2,%ecx
f0104417:	bb 10 00 00 00       	mov    $0x10,%ebx
f010441c:	eb 16                	jmp    f0104434 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f010441e:	85 db                	test   %ebx,%ebx
f0104420:	75 12                	jne    f0104434 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0104422:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104427:	80 39 30             	cmpb   $0x30,(%ecx)
f010442a:	75 08                	jne    f0104434 <strtol+0x6e>
		s++, base = 8;
f010442c:	83 c1 01             	add    $0x1,%ecx
f010442f:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0104434:	b8 00 00 00 00       	mov    $0x0,%eax
f0104439:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f010443c:	0f b6 11             	movzbl (%ecx),%edx
f010443f:	8d 72 d0             	lea    -0x30(%edx),%esi
f0104442:	89 f3                	mov    %esi,%ebx
f0104444:	80 fb 09             	cmp    $0x9,%bl
f0104447:	77 08                	ja     f0104451 <strtol+0x8b>
			dig = *s - '0';
f0104449:	0f be d2             	movsbl %dl,%edx
f010444c:	83 ea 30             	sub    $0x30,%edx
f010444f:	eb 22                	jmp    f0104473 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0104451:	8d 72 9f             	lea    -0x61(%edx),%esi
f0104454:	89 f3                	mov    %esi,%ebx
f0104456:	80 fb 19             	cmp    $0x19,%bl
f0104459:	77 08                	ja     f0104463 <strtol+0x9d>
			dig = *s - 'a' + 10;
f010445b:	0f be d2             	movsbl %dl,%edx
f010445e:	83 ea 57             	sub    $0x57,%edx
f0104461:	eb 10                	jmp    f0104473 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0104463:	8d 72 bf             	lea    -0x41(%edx),%esi
f0104466:	89 f3                	mov    %esi,%ebx
f0104468:	80 fb 19             	cmp    $0x19,%bl
f010446b:	77 16                	ja     f0104483 <strtol+0xbd>
			dig = *s - 'A' + 10;
f010446d:	0f be d2             	movsbl %dl,%edx
f0104470:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0104473:	3b 55 10             	cmp    0x10(%ebp),%edx
f0104476:	7d 0b                	jge    f0104483 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0104478:	83 c1 01             	add    $0x1,%ecx
f010447b:	0f af 45 10          	imul   0x10(%ebp),%eax
f010447f:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0104481:	eb b9                	jmp    f010443c <strtol+0x76>

	if (endptr)
f0104483:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0104487:	74 0d                	je     f0104496 <strtol+0xd0>
		*endptr = (char *) s;
f0104489:	8b 75 0c             	mov    0xc(%ebp),%esi
f010448c:	89 0e                	mov    %ecx,(%esi)
f010448e:	eb 06                	jmp    f0104496 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104490:	85 db                	test   %ebx,%ebx
f0104492:	74 98                	je     f010442c <strtol+0x66>
f0104494:	eb 9e                	jmp    f0104434 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0104496:	89 c2                	mov    %eax,%edx
f0104498:	f7 da                	neg    %edx
f010449a:	85 ff                	test   %edi,%edi
f010449c:	0f 45 c2             	cmovne %edx,%eax
}
f010449f:	5b                   	pop    %ebx
f01044a0:	5e                   	pop    %esi
f01044a1:	5f                   	pop    %edi
f01044a2:	5d                   	pop    %ebp
f01044a3:	c3                   	ret    
f01044a4:	66 90                	xchg   %ax,%ax
f01044a6:	66 90                	xchg   %ax,%ax
f01044a8:	66 90                	xchg   %ax,%ax
f01044aa:	66 90                	xchg   %ax,%ax
f01044ac:	66 90                	xchg   %ax,%ax
f01044ae:	66 90                	xchg   %ax,%ax

f01044b0 <__udivdi3>:
f01044b0:	55                   	push   %ebp
f01044b1:	57                   	push   %edi
f01044b2:	56                   	push   %esi
f01044b3:	53                   	push   %ebx
f01044b4:	83 ec 1c             	sub    $0x1c,%esp
f01044b7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f01044bb:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f01044bf:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f01044c3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01044c7:	85 f6                	test   %esi,%esi
f01044c9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01044cd:	89 ca                	mov    %ecx,%edx
f01044cf:	89 f8                	mov    %edi,%eax
f01044d1:	75 3d                	jne    f0104510 <__udivdi3+0x60>
f01044d3:	39 cf                	cmp    %ecx,%edi
f01044d5:	0f 87 c5 00 00 00    	ja     f01045a0 <__udivdi3+0xf0>
f01044db:	85 ff                	test   %edi,%edi
f01044dd:	89 fd                	mov    %edi,%ebp
f01044df:	75 0b                	jne    f01044ec <__udivdi3+0x3c>
f01044e1:	b8 01 00 00 00       	mov    $0x1,%eax
f01044e6:	31 d2                	xor    %edx,%edx
f01044e8:	f7 f7                	div    %edi
f01044ea:	89 c5                	mov    %eax,%ebp
f01044ec:	89 c8                	mov    %ecx,%eax
f01044ee:	31 d2                	xor    %edx,%edx
f01044f0:	f7 f5                	div    %ebp
f01044f2:	89 c1                	mov    %eax,%ecx
f01044f4:	89 d8                	mov    %ebx,%eax
f01044f6:	89 cf                	mov    %ecx,%edi
f01044f8:	f7 f5                	div    %ebp
f01044fa:	89 c3                	mov    %eax,%ebx
f01044fc:	89 d8                	mov    %ebx,%eax
f01044fe:	89 fa                	mov    %edi,%edx
f0104500:	83 c4 1c             	add    $0x1c,%esp
f0104503:	5b                   	pop    %ebx
f0104504:	5e                   	pop    %esi
f0104505:	5f                   	pop    %edi
f0104506:	5d                   	pop    %ebp
f0104507:	c3                   	ret    
f0104508:	90                   	nop
f0104509:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104510:	39 ce                	cmp    %ecx,%esi
f0104512:	77 74                	ja     f0104588 <__udivdi3+0xd8>
f0104514:	0f bd fe             	bsr    %esi,%edi
f0104517:	83 f7 1f             	xor    $0x1f,%edi
f010451a:	0f 84 98 00 00 00    	je     f01045b8 <__udivdi3+0x108>
f0104520:	bb 20 00 00 00       	mov    $0x20,%ebx
f0104525:	89 f9                	mov    %edi,%ecx
f0104527:	89 c5                	mov    %eax,%ebp
f0104529:	29 fb                	sub    %edi,%ebx
f010452b:	d3 e6                	shl    %cl,%esi
f010452d:	89 d9                	mov    %ebx,%ecx
f010452f:	d3 ed                	shr    %cl,%ebp
f0104531:	89 f9                	mov    %edi,%ecx
f0104533:	d3 e0                	shl    %cl,%eax
f0104535:	09 ee                	or     %ebp,%esi
f0104537:	89 d9                	mov    %ebx,%ecx
f0104539:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010453d:	89 d5                	mov    %edx,%ebp
f010453f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0104543:	d3 ed                	shr    %cl,%ebp
f0104545:	89 f9                	mov    %edi,%ecx
f0104547:	d3 e2                	shl    %cl,%edx
f0104549:	89 d9                	mov    %ebx,%ecx
f010454b:	d3 e8                	shr    %cl,%eax
f010454d:	09 c2                	or     %eax,%edx
f010454f:	89 d0                	mov    %edx,%eax
f0104551:	89 ea                	mov    %ebp,%edx
f0104553:	f7 f6                	div    %esi
f0104555:	89 d5                	mov    %edx,%ebp
f0104557:	89 c3                	mov    %eax,%ebx
f0104559:	f7 64 24 0c          	mull   0xc(%esp)
f010455d:	39 d5                	cmp    %edx,%ebp
f010455f:	72 10                	jb     f0104571 <__udivdi3+0xc1>
f0104561:	8b 74 24 08          	mov    0x8(%esp),%esi
f0104565:	89 f9                	mov    %edi,%ecx
f0104567:	d3 e6                	shl    %cl,%esi
f0104569:	39 c6                	cmp    %eax,%esi
f010456b:	73 07                	jae    f0104574 <__udivdi3+0xc4>
f010456d:	39 d5                	cmp    %edx,%ebp
f010456f:	75 03                	jne    f0104574 <__udivdi3+0xc4>
f0104571:	83 eb 01             	sub    $0x1,%ebx
f0104574:	31 ff                	xor    %edi,%edi
f0104576:	89 d8                	mov    %ebx,%eax
f0104578:	89 fa                	mov    %edi,%edx
f010457a:	83 c4 1c             	add    $0x1c,%esp
f010457d:	5b                   	pop    %ebx
f010457e:	5e                   	pop    %esi
f010457f:	5f                   	pop    %edi
f0104580:	5d                   	pop    %ebp
f0104581:	c3                   	ret    
f0104582:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104588:	31 ff                	xor    %edi,%edi
f010458a:	31 db                	xor    %ebx,%ebx
f010458c:	89 d8                	mov    %ebx,%eax
f010458e:	89 fa                	mov    %edi,%edx
f0104590:	83 c4 1c             	add    $0x1c,%esp
f0104593:	5b                   	pop    %ebx
f0104594:	5e                   	pop    %esi
f0104595:	5f                   	pop    %edi
f0104596:	5d                   	pop    %ebp
f0104597:	c3                   	ret    
f0104598:	90                   	nop
f0104599:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01045a0:	89 d8                	mov    %ebx,%eax
f01045a2:	f7 f7                	div    %edi
f01045a4:	31 ff                	xor    %edi,%edi
f01045a6:	89 c3                	mov    %eax,%ebx
f01045a8:	89 d8                	mov    %ebx,%eax
f01045aa:	89 fa                	mov    %edi,%edx
f01045ac:	83 c4 1c             	add    $0x1c,%esp
f01045af:	5b                   	pop    %ebx
f01045b0:	5e                   	pop    %esi
f01045b1:	5f                   	pop    %edi
f01045b2:	5d                   	pop    %ebp
f01045b3:	c3                   	ret    
f01045b4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01045b8:	39 ce                	cmp    %ecx,%esi
f01045ba:	72 0c                	jb     f01045c8 <__udivdi3+0x118>
f01045bc:	31 db                	xor    %ebx,%ebx
f01045be:	3b 44 24 08          	cmp    0x8(%esp),%eax
f01045c2:	0f 87 34 ff ff ff    	ja     f01044fc <__udivdi3+0x4c>
f01045c8:	bb 01 00 00 00       	mov    $0x1,%ebx
f01045cd:	e9 2a ff ff ff       	jmp    f01044fc <__udivdi3+0x4c>
f01045d2:	66 90                	xchg   %ax,%ax
f01045d4:	66 90                	xchg   %ax,%ax
f01045d6:	66 90                	xchg   %ax,%ax
f01045d8:	66 90                	xchg   %ax,%ax
f01045da:	66 90                	xchg   %ax,%ax
f01045dc:	66 90                	xchg   %ax,%ax
f01045de:	66 90                	xchg   %ax,%ax

f01045e0 <__umoddi3>:
f01045e0:	55                   	push   %ebp
f01045e1:	57                   	push   %edi
f01045e2:	56                   	push   %esi
f01045e3:	53                   	push   %ebx
f01045e4:	83 ec 1c             	sub    $0x1c,%esp
f01045e7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01045eb:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f01045ef:	8b 74 24 34          	mov    0x34(%esp),%esi
f01045f3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01045f7:	85 d2                	test   %edx,%edx
f01045f9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01045fd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104601:	89 f3                	mov    %esi,%ebx
f0104603:	89 3c 24             	mov    %edi,(%esp)
f0104606:	89 74 24 04          	mov    %esi,0x4(%esp)
f010460a:	75 1c                	jne    f0104628 <__umoddi3+0x48>
f010460c:	39 f7                	cmp    %esi,%edi
f010460e:	76 50                	jbe    f0104660 <__umoddi3+0x80>
f0104610:	89 c8                	mov    %ecx,%eax
f0104612:	89 f2                	mov    %esi,%edx
f0104614:	f7 f7                	div    %edi
f0104616:	89 d0                	mov    %edx,%eax
f0104618:	31 d2                	xor    %edx,%edx
f010461a:	83 c4 1c             	add    $0x1c,%esp
f010461d:	5b                   	pop    %ebx
f010461e:	5e                   	pop    %esi
f010461f:	5f                   	pop    %edi
f0104620:	5d                   	pop    %ebp
f0104621:	c3                   	ret    
f0104622:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104628:	39 f2                	cmp    %esi,%edx
f010462a:	89 d0                	mov    %edx,%eax
f010462c:	77 52                	ja     f0104680 <__umoddi3+0xa0>
f010462e:	0f bd ea             	bsr    %edx,%ebp
f0104631:	83 f5 1f             	xor    $0x1f,%ebp
f0104634:	75 5a                	jne    f0104690 <__umoddi3+0xb0>
f0104636:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010463a:	0f 82 e0 00 00 00    	jb     f0104720 <__umoddi3+0x140>
f0104640:	39 0c 24             	cmp    %ecx,(%esp)
f0104643:	0f 86 d7 00 00 00    	jbe    f0104720 <__umoddi3+0x140>
f0104649:	8b 44 24 08          	mov    0x8(%esp),%eax
f010464d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0104651:	83 c4 1c             	add    $0x1c,%esp
f0104654:	5b                   	pop    %ebx
f0104655:	5e                   	pop    %esi
f0104656:	5f                   	pop    %edi
f0104657:	5d                   	pop    %ebp
f0104658:	c3                   	ret    
f0104659:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104660:	85 ff                	test   %edi,%edi
f0104662:	89 fd                	mov    %edi,%ebp
f0104664:	75 0b                	jne    f0104671 <__umoddi3+0x91>
f0104666:	b8 01 00 00 00       	mov    $0x1,%eax
f010466b:	31 d2                	xor    %edx,%edx
f010466d:	f7 f7                	div    %edi
f010466f:	89 c5                	mov    %eax,%ebp
f0104671:	89 f0                	mov    %esi,%eax
f0104673:	31 d2                	xor    %edx,%edx
f0104675:	f7 f5                	div    %ebp
f0104677:	89 c8                	mov    %ecx,%eax
f0104679:	f7 f5                	div    %ebp
f010467b:	89 d0                	mov    %edx,%eax
f010467d:	eb 99                	jmp    f0104618 <__umoddi3+0x38>
f010467f:	90                   	nop
f0104680:	89 c8                	mov    %ecx,%eax
f0104682:	89 f2                	mov    %esi,%edx
f0104684:	83 c4 1c             	add    $0x1c,%esp
f0104687:	5b                   	pop    %ebx
f0104688:	5e                   	pop    %esi
f0104689:	5f                   	pop    %edi
f010468a:	5d                   	pop    %ebp
f010468b:	c3                   	ret    
f010468c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104690:	8b 34 24             	mov    (%esp),%esi
f0104693:	bf 20 00 00 00       	mov    $0x20,%edi
f0104698:	89 e9                	mov    %ebp,%ecx
f010469a:	29 ef                	sub    %ebp,%edi
f010469c:	d3 e0                	shl    %cl,%eax
f010469e:	89 f9                	mov    %edi,%ecx
f01046a0:	89 f2                	mov    %esi,%edx
f01046a2:	d3 ea                	shr    %cl,%edx
f01046a4:	89 e9                	mov    %ebp,%ecx
f01046a6:	09 c2                	or     %eax,%edx
f01046a8:	89 d8                	mov    %ebx,%eax
f01046aa:	89 14 24             	mov    %edx,(%esp)
f01046ad:	89 f2                	mov    %esi,%edx
f01046af:	d3 e2                	shl    %cl,%edx
f01046b1:	89 f9                	mov    %edi,%ecx
f01046b3:	89 54 24 04          	mov    %edx,0x4(%esp)
f01046b7:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01046bb:	d3 e8                	shr    %cl,%eax
f01046bd:	89 e9                	mov    %ebp,%ecx
f01046bf:	89 c6                	mov    %eax,%esi
f01046c1:	d3 e3                	shl    %cl,%ebx
f01046c3:	89 f9                	mov    %edi,%ecx
f01046c5:	89 d0                	mov    %edx,%eax
f01046c7:	d3 e8                	shr    %cl,%eax
f01046c9:	89 e9                	mov    %ebp,%ecx
f01046cb:	09 d8                	or     %ebx,%eax
f01046cd:	89 d3                	mov    %edx,%ebx
f01046cf:	89 f2                	mov    %esi,%edx
f01046d1:	f7 34 24             	divl   (%esp)
f01046d4:	89 d6                	mov    %edx,%esi
f01046d6:	d3 e3                	shl    %cl,%ebx
f01046d8:	f7 64 24 04          	mull   0x4(%esp)
f01046dc:	39 d6                	cmp    %edx,%esi
f01046de:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01046e2:	89 d1                	mov    %edx,%ecx
f01046e4:	89 c3                	mov    %eax,%ebx
f01046e6:	72 08                	jb     f01046f0 <__umoddi3+0x110>
f01046e8:	75 11                	jne    f01046fb <__umoddi3+0x11b>
f01046ea:	39 44 24 08          	cmp    %eax,0x8(%esp)
f01046ee:	73 0b                	jae    f01046fb <__umoddi3+0x11b>
f01046f0:	2b 44 24 04          	sub    0x4(%esp),%eax
f01046f4:	1b 14 24             	sbb    (%esp),%edx
f01046f7:	89 d1                	mov    %edx,%ecx
f01046f9:	89 c3                	mov    %eax,%ebx
f01046fb:	8b 54 24 08          	mov    0x8(%esp),%edx
f01046ff:	29 da                	sub    %ebx,%edx
f0104701:	19 ce                	sbb    %ecx,%esi
f0104703:	89 f9                	mov    %edi,%ecx
f0104705:	89 f0                	mov    %esi,%eax
f0104707:	d3 e0                	shl    %cl,%eax
f0104709:	89 e9                	mov    %ebp,%ecx
f010470b:	d3 ea                	shr    %cl,%edx
f010470d:	89 e9                	mov    %ebp,%ecx
f010470f:	d3 ee                	shr    %cl,%esi
f0104711:	09 d0                	or     %edx,%eax
f0104713:	89 f2                	mov    %esi,%edx
f0104715:	83 c4 1c             	add    $0x1c,%esp
f0104718:	5b                   	pop    %ebx
f0104719:	5e                   	pop    %esi
f010471a:	5f                   	pop    %edi
f010471b:	5d                   	pop    %ebp
f010471c:	c3                   	ret    
f010471d:	8d 76 00             	lea    0x0(%esi),%esi
f0104720:	29 f9                	sub    %edi,%ecx
f0104722:	19 d6                	sbb    %edx,%esi
f0104724:	89 74 24 04          	mov    %esi,0x4(%esp)
f0104728:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010472c:	e9 18 ff ff ff       	jmp    f0104649 <__umoddi3+0x69>
