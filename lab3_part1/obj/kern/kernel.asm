
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
f0100046:	b8 50 7c 17 f0       	mov    $0xf0177c50,%eax
f010004b:	2d 26 6d 17 f0       	sub    $0xf0176d26,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 26 6d 17 f0       	push   $0xf0176d26
f0100058:	e8 39 3c 00 00       	call   f0103c96 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 9d 04 00 00       	call   f01004ff <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 40 41 10 f0       	push   $0xf0104140
f010006f:	e8 7e 2d 00 00       	call   f0102df2 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 61 0f 00 00       	call   f0100fda <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100079:	e8 df 27 00 00       	call   f010285d <env_init>
	trap_init();
f010007e:	e8 e0 2d 00 00       	call   f0102e63 <trap_init>
#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
#else
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
f0100083:	83 c4 08             	add    $0x8,%esp
f0100086:	6a 00                	push   $0x0
f0100088:	68 56 a3 11 f0       	push   $0xf011a356
f010008d:	e8 79 29 00 00       	call   f0102a0b <env_create>
#endif // TEST*

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f0100092:	83 c4 04             	add    $0x4,%esp
f0100095:	ff 35 88 6f 17 f0    	pushl  0xf0176f88
f010009b:	e8 85 2c 00 00       	call   f0102d25 <env_run>

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
f01000a8:	83 3d 40 7c 17 f0 00 	cmpl   $0x0,0xf0177c40
f01000af:	75 37                	jne    f01000e8 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000b1:	89 35 40 7c 17 f0    	mov    %esi,0xf0177c40

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
f01000c5:	68 5b 41 10 f0       	push   $0xf010415b
f01000ca:	e8 23 2d 00 00       	call   f0102df2 <cprintf>
	vcprintf(fmt, ap);
f01000cf:	83 c4 08             	add    $0x8,%esp
f01000d2:	53                   	push   %ebx
f01000d3:	56                   	push   %esi
f01000d4:	e8 f3 2c 00 00       	call   f0102dcc <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 ba 50 10 f0 	movl   $0xf01050ba,(%esp)
f01000e0:	e8 0d 2d 00 00       	call   f0102df2 <cprintf>
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
f0100107:	68 73 41 10 f0       	push   $0xf0104173
f010010c:	e8 e1 2c 00 00       	call   f0102df2 <cprintf>
	vcprintf(fmt, ap);
f0100111:	83 c4 08             	add    $0x8,%esp
f0100114:	53                   	push   %ebx
f0100115:	ff 75 10             	pushl  0x10(%ebp)
f0100118:	e8 af 2c 00 00       	call   f0102dcc <vcprintf>
	cprintf("\n");
f010011d:	c7 04 24 ba 50 10 f0 	movl   $0xf01050ba,(%esp)
f0100124:	e8 c9 2c 00 00       	call   f0102df2 <cprintf>
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
f010015f:	8b 0d 64 6f 17 f0    	mov    0xf0176f64,%ecx
f0100165:	8d 51 01             	lea    0x1(%ecx),%edx
f0100168:	89 15 64 6f 17 f0    	mov    %edx,0xf0176f64
f010016e:	88 81 60 6d 17 f0    	mov    %al,-0xfe892a0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f0100174:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010017a:	75 0a                	jne    f0100186 <cons_intr+0x36>
			cons.wpos = 0;
f010017c:	c7 05 64 6f 17 f0 00 	movl   $0x0,0xf0176f64
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
f01001ad:	83 0d 40 6d 17 f0 40 	orl    $0x40,0xf0176d40
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
f01001c5:	8b 0d 40 6d 17 f0    	mov    0xf0176d40,%ecx
f01001cb:	89 cb                	mov    %ecx,%ebx
f01001cd:	83 e3 40             	and    $0x40,%ebx
f01001d0:	83 e0 7f             	and    $0x7f,%eax
f01001d3:	85 db                	test   %ebx,%ebx
f01001d5:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001d8:	0f b6 d2             	movzbl %dl,%edx
f01001db:	0f b6 82 e0 42 10 f0 	movzbl -0xfefbd20(%edx),%eax
f01001e2:	83 c8 40             	or     $0x40,%eax
f01001e5:	0f b6 c0             	movzbl %al,%eax
f01001e8:	f7 d0                	not    %eax
f01001ea:	21 c8                	and    %ecx,%eax
f01001ec:	a3 40 6d 17 f0       	mov    %eax,0xf0176d40
		return 0;
f01001f1:	b8 00 00 00 00       	mov    $0x0,%eax
f01001f6:	e9 9e 00 00 00       	jmp    f0100299 <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f01001fb:	8b 0d 40 6d 17 f0    	mov    0xf0176d40,%ecx
f0100201:	f6 c1 40             	test   $0x40,%cl
f0100204:	74 0e                	je     f0100214 <kbd_proc_data+0x81>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100206:	83 c8 80             	or     $0xffffff80,%eax
f0100209:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010020b:	83 e1 bf             	and    $0xffffffbf,%ecx
f010020e:	89 0d 40 6d 17 f0    	mov    %ecx,0xf0176d40
	}

	shift |= shiftcode[data];
f0100214:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f0100217:	0f b6 82 e0 42 10 f0 	movzbl -0xfefbd20(%edx),%eax
f010021e:	0b 05 40 6d 17 f0    	or     0xf0176d40,%eax
f0100224:	0f b6 8a e0 41 10 f0 	movzbl -0xfefbe20(%edx),%ecx
f010022b:	31 c8                	xor    %ecx,%eax
f010022d:	a3 40 6d 17 f0       	mov    %eax,0xf0176d40

	c = charcode[shift & (CTL | SHIFT)][data];
f0100232:	89 c1                	mov    %eax,%ecx
f0100234:	83 e1 03             	and    $0x3,%ecx
f0100237:	8b 0c 8d c0 41 10 f0 	mov    -0xfefbe40(,%ecx,4),%ecx
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
f0100275:	68 8d 41 10 f0       	push   $0xf010418d
f010027a:	e8 73 2b 00 00       	call   f0102df2 <cprintf>
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
f010035b:	0f b7 05 68 6f 17 f0 	movzwl 0xf0176f68,%eax
f0100362:	66 85 c0             	test   %ax,%ax
f0100365:	0f 84 e6 00 00 00    	je     f0100451 <cons_putc+0x1b3>
			crt_pos--;
f010036b:	83 e8 01             	sub    $0x1,%eax
f010036e:	66 a3 68 6f 17 f0    	mov    %ax,0xf0176f68
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100374:	0f b7 c0             	movzwl %ax,%eax
f0100377:	66 81 e7 00 ff       	and    $0xff00,%di
f010037c:	83 cf 20             	or     $0x20,%edi
f010037f:	8b 15 6c 6f 17 f0    	mov    0xf0176f6c,%edx
f0100385:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100389:	eb 78                	jmp    f0100403 <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f010038b:	66 83 05 68 6f 17 f0 	addw   $0x50,0xf0176f68
f0100392:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100393:	0f b7 05 68 6f 17 f0 	movzwl 0xf0176f68,%eax
f010039a:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003a0:	c1 e8 16             	shr    $0x16,%eax
f01003a3:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003a6:	c1 e0 04             	shl    $0x4,%eax
f01003a9:	66 a3 68 6f 17 f0    	mov    %ax,0xf0176f68
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
f01003e5:	0f b7 05 68 6f 17 f0 	movzwl 0xf0176f68,%eax
f01003ec:	8d 50 01             	lea    0x1(%eax),%edx
f01003ef:	66 89 15 68 6f 17 f0 	mov    %dx,0xf0176f68
f01003f6:	0f b7 c0             	movzwl %ax,%eax
f01003f9:	8b 15 6c 6f 17 f0    	mov    0xf0176f6c,%edx
f01003ff:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100403:	66 81 3d 68 6f 17 f0 	cmpw   $0x7cf,0xf0176f68
f010040a:	cf 07 
f010040c:	76 43                	jbe    f0100451 <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010040e:	a1 6c 6f 17 f0       	mov    0xf0176f6c,%eax
f0100413:	83 ec 04             	sub    $0x4,%esp
f0100416:	68 00 0f 00 00       	push   $0xf00
f010041b:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100421:	52                   	push   %edx
f0100422:	50                   	push   %eax
f0100423:	e8 bb 38 00 00       	call   f0103ce3 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100428:	8b 15 6c 6f 17 f0    	mov    0xf0176f6c,%edx
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
f0100449:	66 83 2d 68 6f 17 f0 	subw   $0x50,0xf0176f68
f0100450:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100451:	8b 0d 70 6f 17 f0    	mov    0xf0176f70,%ecx
f0100457:	b8 0e 00 00 00       	mov    $0xe,%eax
f010045c:	89 ca                	mov    %ecx,%edx
f010045e:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010045f:	0f b7 1d 68 6f 17 f0 	movzwl 0xf0176f68,%ebx
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
f0100487:	80 3d 74 6f 17 f0 00 	cmpb   $0x0,0xf0176f74
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
f01004c5:	a1 60 6f 17 f0       	mov    0xf0176f60,%eax
f01004ca:	3b 05 64 6f 17 f0    	cmp    0xf0176f64,%eax
f01004d0:	74 26                	je     f01004f8 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004d2:	8d 50 01             	lea    0x1(%eax),%edx
f01004d5:	89 15 60 6f 17 f0    	mov    %edx,0xf0176f60
f01004db:	0f b6 88 60 6d 17 f0 	movzbl -0xfe892a0(%eax),%ecx
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
f01004ec:	c7 05 60 6f 17 f0 00 	movl   $0x0,0xf0176f60
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
f0100525:	c7 05 70 6f 17 f0 b4 	movl   $0x3b4,0xf0176f70
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
f010053d:	c7 05 70 6f 17 f0 d4 	movl   $0x3d4,0xf0176f70
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
f010054c:	8b 3d 70 6f 17 f0    	mov    0xf0176f70,%edi
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
f0100571:	89 35 6c 6f 17 f0    	mov    %esi,0xf0176f6c
	crt_pos = pos;
f0100577:	0f b6 c0             	movzbl %al,%eax
f010057a:	09 c8                	or     %ecx,%eax
f010057c:	66 a3 68 6f 17 f0    	mov    %ax,0xf0176f68
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
f01005dd:	0f 95 05 74 6f 17 f0 	setne  0xf0176f74
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
f01005f2:	68 99 41 10 f0       	push   $0xf0104199
f01005f7:	e8 f6 27 00 00       	call   f0102df2 <cprintf>
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
f0100638:	68 e0 43 10 f0       	push   $0xf01043e0
f010063d:	68 fe 43 10 f0       	push   $0xf01043fe
f0100642:	68 03 44 10 f0       	push   $0xf0104403
f0100647:	e8 a6 27 00 00       	call   f0102df2 <cprintf>
f010064c:	83 c4 0c             	add    $0xc,%esp
f010064f:	68 9c 44 10 f0       	push   $0xf010449c
f0100654:	68 0c 44 10 f0       	push   $0xf010440c
f0100659:	68 03 44 10 f0       	push   $0xf0104403
f010065e:	e8 8f 27 00 00       	call   f0102df2 <cprintf>
f0100663:	83 c4 0c             	add    $0xc,%esp
f0100666:	68 c4 44 10 f0       	push   $0xf01044c4
f010066b:	68 15 44 10 f0       	push   $0xf0104415
f0100670:	68 03 44 10 f0       	push   $0xf0104403
f0100675:	e8 78 27 00 00       	call   f0102df2 <cprintf>
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
f0100687:	68 1f 44 10 f0       	push   $0xf010441f
f010068c:	e8 61 27 00 00       	call   f0102df2 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100691:	83 c4 08             	add    $0x8,%esp
f0100694:	68 0c 00 10 00       	push   $0x10000c
f0100699:	68 e4 44 10 f0       	push   $0xf01044e4
f010069e:	e8 4f 27 00 00       	call   f0102df2 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006a3:	83 c4 0c             	add    $0xc,%esp
f01006a6:	68 0c 00 10 00       	push   $0x10000c
f01006ab:	68 0c 00 10 f0       	push   $0xf010000c
f01006b0:	68 0c 45 10 f0       	push   $0xf010450c
f01006b5:	e8 38 27 00 00       	call   f0102df2 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006ba:	83 c4 0c             	add    $0xc,%esp
f01006bd:	68 21 41 10 00       	push   $0x104121
f01006c2:	68 21 41 10 f0       	push   $0xf0104121
f01006c7:	68 30 45 10 f0       	push   $0xf0104530
f01006cc:	e8 21 27 00 00       	call   f0102df2 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006d1:	83 c4 0c             	add    $0xc,%esp
f01006d4:	68 26 6d 17 00       	push   $0x176d26
f01006d9:	68 26 6d 17 f0       	push   $0xf0176d26
f01006de:	68 54 45 10 f0       	push   $0xf0104554
f01006e3:	e8 0a 27 00 00       	call   f0102df2 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006e8:	83 c4 0c             	add    $0xc,%esp
f01006eb:	68 50 7c 17 00       	push   $0x177c50
f01006f0:	68 50 7c 17 f0       	push   $0xf0177c50
f01006f5:	68 78 45 10 f0       	push   $0xf0104578
f01006fa:	e8 f3 26 00 00       	call   f0102df2 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006ff:	b8 4f 80 17 f0       	mov    $0xf017804f,%eax
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
f0100720:	68 9c 45 10 f0       	push   $0xf010459c
f0100725:	e8 c8 26 00 00       	call   f0102df2 <cprintf>
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
f010073b:	68 38 44 10 f0       	push   $0xf0104438
f0100740:	e8 ad 26 00 00       	call   f0102df2 <cprintf>
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
f0100760:	68 c8 45 10 f0       	push   $0xf01045c8
f0100765:	e8 88 26 00 00       	call   f0102df2 <cprintf>
		debuginfo_eip(test_ebp[1],&info);
f010076a:	83 c4 18             	add    $0x18,%esp
f010076d:	56                   	push   %esi
f010076e:	ff 73 04             	pushl  0x4(%ebx)
f0100771:	e8 30 2b 00 00       	call   f01032a6 <debuginfo_eip>
		cprintf("\t    %s:%d: %.*s+%d\n",info.eip_file,info.eip_line,info.eip_fn_namelen,info.eip_fn_name,test_ebp[1] - info.eip_fn_addr);
f0100776:	83 c4 08             	add    $0x8,%esp
f0100779:	8b 43 04             	mov    0x4(%ebx),%eax
f010077c:	2b 45 f0             	sub    -0x10(%ebp),%eax
f010077f:	50                   	push   %eax
f0100780:	ff 75 e8             	pushl  -0x18(%ebp)
f0100783:	ff 75 ec             	pushl  -0x14(%ebp)
f0100786:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100789:	ff 75 e0             	pushl  -0x20(%ebp)
f010078c:	68 4a 44 10 f0       	push   $0xf010444a
f0100791:	e8 5c 26 00 00       	call   f0102df2 <cprintf>
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
f01007b4:	68 fc 45 10 f0       	push   $0xf01045fc
f01007b9:	e8 34 26 00 00       	call   f0102df2 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007be:	c7 04 24 20 46 10 f0 	movl   $0xf0104620,(%esp)
f01007c5:	e8 28 26 00 00       	call   f0102df2 <cprintf>

	if (tf != NULL)
f01007ca:	83 c4 10             	add    $0x10,%esp
f01007cd:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f01007d1:	74 0e                	je     f01007e1 <monitor+0x36>
		print_trapframe(tf);
f01007d3:	83 ec 0c             	sub    $0xc,%esp
f01007d6:	ff 75 08             	pushl  0x8(%ebp)
f01007d9:	e8 1d 27 00 00       	call   f0102efb <print_trapframe>
f01007de:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f01007e1:	83 ec 0c             	sub    $0xc,%esp
f01007e4:	68 5f 44 10 f0       	push   $0xf010445f
f01007e9:	e8 51 32 00 00       	call   f0103a3f <readline>
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
f010081d:	68 63 44 10 f0       	push   $0xf0104463
f0100822:	e8 32 34 00 00       	call   f0103c59 <strchr>
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
f010083d:	68 68 44 10 f0       	push   $0xf0104468
f0100842:	e8 ab 25 00 00       	call   f0102df2 <cprintf>
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
f0100866:	68 63 44 10 f0       	push   $0xf0104463
f010086b:	e8 e9 33 00 00       	call   f0103c59 <strchr>
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
f0100894:	ff 34 85 60 46 10 f0 	pushl  -0xfefb9a0(,%eax,4)
f010089b:	ff 75 a8             	pushl  -0x58(%ebp)
f010089e:	e8 58 33 00 00       	call   f0103bfb <strcmp>
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
f01008b8:	ff 14 85 68 46 10 f0 	call   *-0xfefb998(,%eax,4)
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
f01008d9:	68 85 44 10 f0       	push   $0xf0104485
f01008de:	e8 0f 25 00 00       	call   f0102df2 <cprintf>
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
f01008f6:	83 3d 78 6f 17 f0 00 	cmpl   $0x0,0xf0176f78
f01008fd:	75 11                	jne    f0100910 <boot_alloc+0x1d>
		extern char end[];
		//cprintf("end=%x\n",end);
		//cprintf("PGSIZE=%x\n",PGSIZE);
		nextfree = ROUNDUP((char *) end, PGSIZE);
f01008ff:	ba 4f 8c 17 f0       	mov    $0xf0178c4f,%edx
f0100904:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010090a:	89 15 78 6f 17 f0    	mov    %edx,0xf0176f78
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	//cprintf("n=%x\n",n);
	//cprintf("Initial=%x\n",nextfree);
	result=nextfree;
f0100910:	8b 0d 78 6f 17 f0    	mov    0xf0176f78,%ecx
	nextfree = ROUNDUP((char *) nextfree+n, PGSIZE);
f0100916:	8d 94 01 ff 0f 00 00 	lea    0xfff(%ecx,%eax,1),%edx
f010091d:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100923:	89 15 78 6f 17 f0    	mov    %edx,0xf0176f78
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
f0100943:	3b 0d 44 7c 17 f0    	cmp    0xf0177c44,%ecx
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
f0100952:	68 84 46 10 f0       	push   $0xf0104684
f0100957:	68 28 03 00 00       	push   $0x328
f010095c:	68 09 4e 10 f0       	push   $0xf0104e09
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
f01009aa:	68 a8 46 10 f0       	push   $0xf01046a8
f01009af:	68 66 02 00 00       	push   $0x266
f01009b4:	68 09 4e 10 f0       	push   $0xf0104e09
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
f01009cc:	2b 15 4c 7c 17 f0    	sub    0xf0177c4c,%edx
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
f0100a02:	a3 7c 6f 17 f0       	mov    %eax,0xf0176f7c
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
f0100a0c:	8b 1d 7c 6f 17 f0    	mov    0xf0176f7c,%ebx
f0100a12:	eb 53                	jmp    f0100a67 <check_page_free_list+0xd6>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a14:	89 d8                	mov    %ebx,%eax
f0100a16:	2b 05 4c 7c 17 f0    	sub    0xf0177c4c,%eax
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
f0100a30:	3b 15 44 7c 17 f0    	cmp    0xf0177c44,%edx
f0100a36:	72 12                	jb     f0100a4a <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a38:	50                   	push   %eax
f0100a39:	68 84 46 10 f0       	push   $0xf0104684
f0100a3e:	6a 56                	push   $0x56
f0100a40:	68 15 4e 10 f0       	push   $0xf0104e15
f0100a45:	e8 56 f6 ff ff       	call   f01000a0 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100a4a:	83 ec 04             	sub    $0x4,%esp
f0100a4d:	68 80 00 00 00       	push   $0x80
f0100a52:	68 97 00 00 00       	push   $0x97
f0100a57:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100a5c:	50                   	push   %eax
f0100a5d:	e8 34 32 00 00       	call   f0103c96 <memset>
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
f0100a78:	8b 15 7c 6f 17 f0    	mov    0xf0176f7c,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100a7e:	8b 0d 4c 7c 17 f0    	mov    0xf0177c4c,%ecx
		assert(pp < pages + npages);
f0100a84:	a1 44 7c 17 f0       	mov    0xf0177c44,%eax
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
f0100aa3:	68 23 4e 10 f0       	push   $0xf0104e23
f0100aa8:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0100aad:	68 80 02 00 00       	push   $0x280
f0100ab2:	68 09 4e 10 f0       	push   $0xf0104e09
f0100ab7:	e8 e4 f5 ff ff       	call   f01000a0 <_panic>
		assert(pp < pages + npages);
f0100abc:	39 fa                	cmp    %edi,%edx
f0100abe:	72 19                	jb     f0100ad9 <check_page_free_list+0x148>
f0100ac0:	68 44 4e 10 f0       	push   $0xf0104e44
f0100ac5:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0100aca:	68 81 02 00 00       	push   $0x281
f0100acf:	68 09 4e 10 f0       	push   $0xf0104e09
f0100ad4:	e8 c7 f5 ff ff       	call   f01000a0 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100ad9:	89 d0                	mov    %edx,%eax
f0100adb:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100ade:	a8 07                	test   $0x7,%al
f0100ae0:	74 19                	je     f0100afb <check_page_free_list+0x16a>
f0100ae2:	68 cc 46 10 f0       	push   $0xf01046cc
f0100ae7:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0100aec:	68 82 02 00 00       	push   $0x282
f0100af1:	68 09 4e 10 f0       	push   $0xf0104e09
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
f0100b05:	68 58 4e 10 f0       	push   $0xf0104e58
f0100b0a:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0100b0f:	68 85 02 00 00       	push   $0x285
f0100b14:	68 09 4e 10 f0       	push   $0xf0104e09
f0100b19:	e8 82 f5 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100b1e:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100b23:	75 19                	jne    f0100b3e <check_page_free_list+0x1ad>
f0100b25:	68 69 4e 10 f0       	push   $0xf0104e69
f0100b2a:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0100b2f:	68 86 02 00 00       	push   $0x286
f0100b34:	68 09 4e 10 f0       	push   $0xf0104e09
f0100b39:	e8 62 f5 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100b3e:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100b43:	75 19                	jne    f0100b5e <check_page_free_list+0x1cd>
f0100b45:	68 00 47 10 f0       	push   $0xf0104700
f0100b4a:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0100b4f:	68 87 02 00 00       	push   $0x287
f0100b54:	68 09 4e 10 f0       	push   $0xf0104e09
f0100b59:	e8 42 f5 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100b5e:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100b63:	75 19                	jne    f0100b7e <check_page_free_list+0x1ed>
f0100b65:	68 82 4e 10 f0       	push   $0xf0104e82
f0100b6a:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0100b6f:	68 88 02 00 00       	push   $0x288
f0100b74:	68 09 4e 10 f0       	push   $0xf0104e09
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
f0100b90:	68 84 46 10 f0       	push   $0xf0104684
f0100b95:	6a 56                	push   $0x56
f0100b97:	68 15 4e 10 f0       	push   $0xf0104e15
f0100b9c:	e8 ff f4 ff ff       	call   f01000a0 <_panic>
f0100ba1:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100ba6:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100ba9:	76 1e                	jbe    f0100bc9 <check_page_free_list+0x238>
f0100bab:	68 24 47 10 f0       	push   $0xf0104724
f0100bb0:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0100bb5:	68 89 02 00 00       	push   $0x289
f0100bba:	68 09 4e 10 f0       	push   $0xf0104e09
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
f0100bde:	68 9c 4e 10 f0       	push   $0xf0104e9c
f0100be3:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0100be8:	68 91 02 00 00       	push   $0x291
f0100bed:	68 09 4e 10 f0       	push   $0xf0104e09
f0100bf2:	e8 a9 f4 ff ff       	call   f01000a0 <_panic>
	assert(nfree_extmem > 0);
f0100bf7:	85 db                	test   %ebx,%ebx
f0100bf9:	7f 42                	jg     f0100c3d <check_page_free_list+0x2ac>
f0100bfb:	68 ae 4e 10 f0       	push   $0xf0104eae
f0100c00:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0100c05:	68 92 02 00 00       	push   $0x292
f0100c0a:	68 09 4e 10 f0       	push   $0xf0104e09
f0100c0f:	e8 8c f4 ff ff       	call   f01000a0 <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100c14:	a1 7c 6f 17 f0       	mov    0xf0176f7c,%eax
f0100c19:	85 c0                	test   %eax,%eax
f0100c1b:	0f 85 9d fd ff ff    	jne    f01009be <check_page_free_list+0x2d>
f0100c21:	e9 81 fd ff ff       	jmp    f01009a7 <check_page_free_list+0x16>
f0100c26:	83 3d 7c 6f 17 f0 00 	cmpl   $0x0,0xf0176f7c
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
f0100c4a:	8b 35 80 6f 17 f0    	mov    0xf0176f80,%esi
f0100c50:	8b 1d 7c 6f 17 f0    	mov    0xf0176f7c,%ebx
f0100c56:	ba 00 00 00 00       	mov    $0x0,%edx
f0100c5b:	b8 01 00 00 00       	mov    $0x1,%eax
f0100c60:	eb 27                	jmp    f0100c89 <page_init+0x44>
		pages[i].pp_ref = 0;
f0100c62:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f0100c69:	89 d1                	mov    %edx,%ecx
f0100c6b:	03 0d 4c 7c 17 f0    	add    0xf0177c4c,%ecx
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
f0100c7e:	03 1d 4c 7c 17 f0    	add    0xf0177c4c,%ebx
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
f0100c91:	89 1d 7c 6f 17 f0    	mov    %ebx,0xf0176f7c
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
	
	keriolim = (int)ROUNDUP(((char*)envs) + (sizeof(struct Env) * NENV) - KERNBASE, PGSIZE)/PGSIZE;
f0100c97:	a1 88 6f 17 f0       	mov    0xf0176f88,%eax
f0100c9c:	05 ff 8f 01 10       	add    $0x10018fff,%eax
	//cprintf("keriolim=%d\n",keriolim);
	for (i = keriolim; i < npages; i++) {
f0100ca1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100ca6:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0100cac:	85 c0                	test   %eax,%eax
f0100cae:	0f 48 c2             	cmovs  %edx,%eax
f0100cb1:	c1 f8 0c             	sar    $0xc,%eax
f0100cb4:	89 c2                	mov    %eax,%edx
f0100cb6:	8b 1d 7c 6f 17 f0    	mov    0xf0176f7c,%ebx
f0100cbc:	c1 e0 03             	shl    $0x3,%eax
f0100cbf:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100cc4:	eb 23                	jmp    f0100ce9 <page_init+0xa4>
		pages[i].pp_ref = 0;
f0100cc6:	89 c1                	mov    %eax,%ecx
f0100cc8:	03 0d 4c 7c 17 f0    	add    0xf0177c4c,%ecx
f0100cce:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100cd4:	89 19                	mov    %ebx,(%ecx)
		page_free_list = &pages[i];
f0100cd6:	89 c3                	mov    %eax,%ebx
f0100cd8:	03 1d 4c 7c 17 f0    	add    0xf0177c4c,%ebx
		page_free_list = &pages[i];
	}
	
	keriolim = (int)ROUNDUP(((char*)envs) + (sizeof(struct Env) * NENV) - KERNBASE, PGSIZE)/PGSIZE;
	//cprintf("keriolim=%d\n",keriolim);
	for (i = keriolim; i < npages; i++) {
f0100cde:	83 c2 01             	add    $0x1,%edx
f0100ce1:	83 c0 08             	add    $0x8,%eax
f0100ce4:	b9 01 00 00 00       	mov    $0x1,%ecx
f0100ce9:	3b 15 44 7c 17 f0    	cmp    0xf0177c44,%edx
f0100cef:	72 d5                	jb     f0100cc6 <page_init+0x81>
f0100cf1:	84 c9                	test   %cl,%cl
f0100cf3:	74 06                	je     f0100cfb <page_init+0xb6>
f0100cf5:	89 1d 7c 6f 17 f0    	mov    %ebx,0xf0176f7c
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
f0100d06:	8b 1d 7c 6f 17 f0    	mov    0xf0176f7c,%ebx
f0100d0c:	85 db                	test   %ebx,%ebx
f0100d0e:	74 58                	je     f0100d68 <page_alloc+0x69>
		struct PageInfo *result = page_free_list;
		page_free_list = page_free_list -> pp_link;
f0100d10:	8b 03                	mov    (%ebx),%eax
f0100d12:	a3 7c 6f 17 f0       	mov    %eax,0xf0176f7c
		if(alloc_flags & ALLOC_ZERO)
f0100d17:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100d1b:	74 45                	je     f0100d62 <page_alloc+0x63>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100d1d:	89 d8                	mov    %ebx,%eax
f0100d1f:	2b 05 4c 7c 17 f0    	sub    0xf0177c4c,%eax
f0100d25:	c1 f8 03             	sar    $0x3,%eax
f0100d28:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100d2b:	89 c2                	mov    %eax,%edx
f0100d2d:	c1 ea 0c             	shr    $0xc,%edx
f0100d30:	3b 15 44 7c 17 f0    	cmp    0xf0177c44,%edx
f0100d36:	72 12                	jb     f0100d4a <page_alloc+0x4b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d38:	50                   	push   %eax
f0100d39:	68 84 46 10 f0       	push   $0xf0104684
f0100d3e:	6a 56                	push   $0x56
f0100d40:	68 15 4e 10 f0       	push   $0xf0104e15
f0100d45:	e8 56 f3 ff ff       	call   f01000a0 <_panic>
			memset(page2kva(result), 0 , PGSIZE);
f0100d4a:	83 ec 04             	sub    $0x4,%esp
f0100d4d:	68 00 10 00 00       	push   $0x1000
f0100d52:	6a 00                	push   $0x0
f0100d54:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100d59:	50                   	push   %eax
f0100d5a:	e8 37 2f 00 00       	call   f0103c96 <memset>
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
f0100d75:	8b 15 7c 6f 17 f0    	mov    0xf0176f7c,%edx
f0100d7b:	89 10                	mov    %edx,(%eax)
    	page_free_list = pp;
f0100d7d:	a3 7c 6f 17 f0       	mov    %eax,0xf0176f7c
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
f0100dca:	39 05 44 7c 17 f0    	cmp    %eax,0xf0177c44
f0100dd0:	77 15                	ja     f0100de7 <pgdir_walk+0x42>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100dd2:	52                   	push   %edx
f0100dd3:	68 84 46 10 f0       	push   $0xf0104684
f0100dd8:	68 7f 01 00 00       	push   $0x17f
f0100ddd:	68 09 4e 10 f0       	push   $0xf0104e09
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
f0100e08:	2b 15 4c 7c 17 f0    	sub    0xf0177c4c,%edx
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
f0100e1e:	2b 05 4c 7c 17 f0    	sub    0xf0177c4c,%eax
f0100e24:	c1 f8 03             	sar    $0x3,%eax
f0100e27:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e2a:	89 c2                	mov    %eax,%edx
f0100e2c:	c1 ea 0c             	shr    $0xc,%edx
f0100e2f:	3b 15 44 7c 17 f0    	cmp    0xf0177c44,%edx
f0100e35:	72 12                	jb     f0100e49 <pgdir_walk+0xa4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e37:	50                   	push   %eax
f0100e38:	68 84 46 10 f0       	push   $0xf0104684
f0100e3d:	6a 56                	push   $0x56
f0100e3f:	68 15 4e 10 f0       	push   $0xf0104e15
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
f0100efe:	3b 05 44 7c 17 f0    	cmp    0xf0177c44,%eax
f0100f04:	72 14                	jb     f0100f1a <page_lookup+0x54>
		panic("pa2page called with invalid pa");
f0100f06:	83 ec 04             	sub    $0x4,%esp
f0100f09:	68 6c 47 10 f0       	push   $0xf010476c
f0100f0e:	6a 4f                	push   $0x4f
f0100f10:	68 15 4e 10 f0       	push   $0xf0104e15
f0100f15:	e8 86 f1 ff ff       	call   f01000a0 <_panic>
	return &pages[PGNUM(pa)];
f0100f1a:	8b 15 4c 7c 17 f0    	mov    0xf0177c4c,%edx
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
f0100fb0:	2b 1d 4c 7c 17 f0    	sub    0xf0177c4c,%ebx
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
f0100fe5:	e8 a1 1d 00 00       	call   f0102d8b <mc146818_read>
f0100fea:	89 c3                	mov    %eax,%ebx
f0100fec:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f0100ff3:	e8 93 1d 00 00       	call   f0102d8b <mc146818_read>
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
f010100e:	a3 80 6f 17 f0       	mov    %eax,0xf0176f80
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101013:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f010101a:	e8 6c 1d 00 00       	call   f0102d8b <mc146818_read>
f010101f:	89 c3                	mov    %eax,%ebx
f0101021:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f0101028:	e8 5e 1d 00 00       	call   f0102d8b <mc146818_read>
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
f0101050:	89 15 44 7c 17 f0    	mov    %edx,0xf0177c44
f0101056:	eb 0c                	jmp    f0101064 <mem_init+0x8a>
	else
		npages = npages_basemem;
f0101058:	8b 15 80 6f 17 f0    	mov    0xf0176f80,%edx
f010105e:	89 15 44 7c 17 f0    	mov    %edx,0xf0177c44

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101064:	c1 e0 0c             	shl    $0xc,%eax
f0101067:	c1 e8 0a             	shr    $0xa,%eax
f010106a:	50                   	push   %eax
f010106b:	a1 80 6f 17 f0       	mov    0xf0176f80,%eax
f0101070:	c1 e0 0c             	shl    $0xc,%eax
f0101073:	c1 e8 0a             	shr    $0xa,%eax
f0101076:	50                   	push   %eax
f0101077:	a1 44 7c 17 f0       	mov    0xf0177c44,%eax
f010107c:	c1 e0 0c             	shl    $0xc,%eax
f010107f:	c1 e8 0a             	shr    $0xa,%eax
f0101082:	50                   	push   %eax
f0101083:	68 8c 47 10 f0       	push   $0xf010478c
f0101088:	e8 65 1d 00 00       	call   f0102df2 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f010108d:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101092:	e8 5c f8 ff ff       	call   f01008f3 <boot_alloc>
f0101097:	a3 48 7c 17 f0       	mov    %eax,0xf0177c48
	memset(kern_pgdir, 0, PGSIZE);
f010109c:	83 c4 0c             	add    $0xc,%esp
f010109f:	68 00 10 00 00       	push   $0x1000
f01010a4:	6a 00                	push   $0x0
f01010a6:	50                   	push   %eax
f01010a7:	e8 ea 2b 00 00       	call   f0103c96 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01010ac:	a1 48 7c 17 f0       	mov    0xf0177c48,%eax
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
f01010bc:	68 c8 47 10 f0       	push   $0xf01047c8
f01010c1:	68 93 00 00 00       	push   $0x93
f01010c6:	68 09 4e 10 f0       	push   $0xf0104e09
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
f01010df:	a1 44 7c 17 f0       	mov    0xf0177c44,%eax
f01010e4:	c1 e0 03             	shl    $0x3,%eax
f01010e7:	e8 07 f8 ff ff       	call   f01008f3 <boot_alloc>
f01010ec:	a3 4c 7c 17 f0       	mov    %eax,0xf0177c4c
	memset(pages, 0, npages * sizeof(struct PageInfo));
f01010f1:	83 ec 04             	sub    $0x4,%esp
f01010f4:	8b 3d 44 7c 17 f0    	mov    0xf0177c44,%edi
f01010fa:	8d 14 fd 00 00 00 00 	lea    0x0(,%edi,8),%edx
f0101101:	52                   	push   %edx
f0101102:	6a 00                	push   $0x0
f0101104:	50                   	push   %eax
f0101105:	e8 8c 2b 00 00       	call   f0103c96 <memset>
	envs = (struct Env *) boot_alloc(sizeof(struct Env) * NENV);
f010110a:	b8 00 80 01 00       	mov    $0x18000,%eax
f010110f:	e8 df f7 ff ff       	call   f01008f3 <boot_alloc>
f0101114:	a3 88 6f 17 f0       	mov    %eax,0xf0176f88
	memset(envs, 0, NENV * sizeof(struct Env));
f0101119:	83 c4 0c             	add    $0xc,%esp
f010111c:	68 00 80 01 00       	push   $0x18000
f0101121:	6a 00                	push   $0x0
f0101123:	50                   	push   %eax
f0101124:	e8 6d 2b 00 00       	call   f0103c96 <memset>
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
f010113b:	83 3d 4c 7c 17 f0 00 	cmpl   $0x0,0xf0177c4c
f0101142:	75 17                	jne    f010115b <mem_init+0x181>
		panic("'pages' is a null pointer!");
f0101144:	83 ec 04             	sub    $0x4,%esp
f0101147:	68 bf 4e 10 f0       	push   $0xf0104ebf
f010114c:	68 a3 02 00 00       	push   $0x2a3
f0101151:	68 09 4e 10 f0       	push   $0xf0104e09
f0101156:	e8 45 ef ff ff       	call   f01000a0 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010115b:	a1 7c 6f 17 f0       	mov    0xf0176f7c,%eax
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
f0101183:	68 da 4e 10 f0       	push   $0xf0104eda
f0101188:	68 2f 4e 10 f0       	push   $0xf0104e2f
f010118d:	68 ab 02 00 00       	push   $0x2ab
f0101192:	68 09 4e 10 f0       	push   $0xf0104e09
f0101197:	e8 04 ef ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f010119c:	83 ec 0c             	sub    $0xc,%esp
f010119f:	6a 00                	push   $0x0
f01011a1:	e8 59 fb ff ff       	call   f0100cff <page_alloc>
f01011a6:	89 c6                	mov    %eax,%esi
f01011a8:	83 c4 10             	add    $0x10,%esp
f01011ab:	85 c0                	test   %eax,%eax
f01011ad:	75 19                	jne    f01011c8 <mem_init+0x1ee>
f01011af:	68 f0 4e 10 f0       	push   $0xf0104ef0
f01011b4:	68 2f 4e 10 f0       	push   $0xf0104e2f
f01011b9:	68 ac 02 00 00       	push   $0x2ac
f01011be:	68 09 4e 10 f0       	push   $0xf0104e09
f01011c3:	e8 d8 ee ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f01011c8:	83 ec 0c             	sub    $0xc,%esp
f01011cb:	6a 00                	push   $0x0
f01011cd:	e8 2d fb ff ff       	call   f0100cff <page_alloc>
f01011d2:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01011d5:	83 c4 10             	add    $0x10,%esp
f01011d8:	85 c0                	test   %eax,%eax
f01011da:	75 19                	jne    f01011f5 <mem_init+0x21b>
f01011dc:	68 06 4f 10 f0       	push   $0xf0104f06
f01011e1:	68 2f 4e 10 f0       	push   $0xf0104e2f
f01011e6:	68 ad 02 00 00       	push   $0x2ad
f01011eb:	68 09 4e 10 f0       	push   $0xf0104e09
f01011f0:	e8 ab ee ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01011f5:	39 f7                	cmp    %esi,%edi
f01011f7:	75 19                	jne    f0101212 <mem_init+0x238>
f01011f9:	68 1c 4f 10 f0       	push   $0xf0104f1c
f01011fe:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0101203:	68 b0 02 00 00       	push   $0x2b0
f0101208:	68 09 4e 10 f0       	push   $0xf0104e09
f010120d:	e8 8e ee ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101212:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101215:	39 c6                	cmp    %eax,%esi
f0101217:	74 04                	je     f010121d <mem_init+0x243>
f0101219:	39 c7                	cmp    %eax,%edi
f010121b:	75 19                	jne    f0101236 <mem_init+0x25c>
f010121d:	68 ec 47 10 f0       	push   $0xf01047ec
f0101222:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0101227:	68 b1 02 00 00       	push   $0x2b1
f010122c:	68 09 4e 10 f0       	push   $0xf0104e09
f0101231:	e8 6a ee ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101236:	8b 0d 4c 7c 17 f0    	mov    0xf0177c4c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f010123c:	8b 15 44 7c 17 f0    	mov    0xf0177c44,%edx
f0101242:	c1 e2 0c             	shl    $0xc,%edx
f0101245:	89 f8                	mov    %edi,%eax
f0101247:	29 c8                	sub    %ecx,%eax
f0101249:	c1 f8 03             	sar    $0x3,%eax
f010124c:	c1 e0 0c             	shl    $0xc,%eax
f010124f:	39 d0                	cmp    %edx,%eax
f0101251:	72 19                	jb     f010126c <mem_init+0x292>
f0101253:	68 2e 4f 10 f0       	push   $0xf0104f2e
f0101258:	68 2f 4e 10 f0       	push   $0xf0104e2f
f010125d:	68 b2 02 00 00       	push   $0x2b2
f0101262:	68 09 4e 10 f0       	push   $0xf0104e09
f0101267:	e8 34 ee ff ff       	call   f01000a0 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f010126c:	89 f0                	mov    %esi,%eax
f010126e:	29 c8                	sub    %ecx,%eax
f0101270:	c1 f8 03             	sar    $0x3,%eax
f0101273:	c1 e0 0c             	shl    $0xc,%eax
f0101276:	39 c2                	cmp    %eax,%edx
f0101278:	77 19                	ja     f0101293 <mem_init+0x2b9>
f010127a:	68 4b 4f 10 f0       	push   $0xf0104f4b
f010127f:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0101284:	68 b3 02 00 00       	push   $0x2b3
f0101289:	68 09 4e 10 f0       	push   $0xf0104e09
f010128e:	e8 0d ee ff ff       	call   f01000a0 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f0101293:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101296:	29 c8                	sub    %ecx,%eax
f0101298:	c1 f8 03             	sar    $0x3,%eax
f010129b:	c1 e0 0c             	shl    $0xc,%eax
f010129e:	39 c2                	cmp    %eax,%edx
f01012a0:	77 19                	ja     f01012bb <mem_init+0x2e1>
f01012a2:	68 68 4f 10 f0       	push   $0xf0104f68
f01012a7:	68 2f 4e 10 f0       	push   $0xf0104e2f
f01012ac:	68 b4 02 00 00       	push   $0x2b4
f01012b1:	68 09 4e 10 f0       	push   $0xf0104e09
f01012b6:	e8 e5 ed ff ff       	call   f01000a0 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01012bb:	a1 7c 6f 17 f0       	mov    0xf0176f7c,%eax
f01012c0:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01012c3:	c7 05 7c 6f 17 f0 00 	movl   $0x0,0xf0176f7c
f01012ca:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01012cd:	83 ec 0c             	sub    $0xc,%esp
f01012d0:	6a 00                	push   $0x0
f01012d2:	e8 28 fa ff ff       	call   f0100cff <page_alloc>
f01012d7:	83 c4 10             	add    $0x10,%esp
f01012da:	85 c0                	test   %eax,%eax
f01012dc:	74 19                	je     f01012f7 <mem_init+0x31d>
f01012de:	68 85 4f 10 f0       	push   $0xf0104f85
f01012e3:	68 2f 4e 10 f0       	push   $0xf0104e2f
f01012e8:	68 bb 02 00 00       	push   $0x2bb
f01012ed:	68 09 4e 10 f0       	push   $0xf0104e09
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
f0101328:	68 da 4e 10 f0       	push   $0xf0104eda
f010132d:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0101332:	68 c2 02 00 00       	push   $0x2c2
f0101337:	68 09 4e 10 f0       	push   $0xf0104e09
f010133c:	e8 5f ed ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f0101341:	83 ec 0c             	sub    $0xc,%esp
f0101344:	6a 00                	push   $0x0
f0101346:	e8 b4 f9 ff ff       	call   f0100cff <page_alloc>
f010134b:	89 c7                	mov    %eax,%edi
f010134d:	83 c4 10             	add    $0x10,%esp
f0101350:	85 c0                	test   %eax,%eax
f0101352:	75 19                	jne    f010136d <mem_init+0x393>
f0101354:	68 f0 4e 10 f0       	push   $0xf0104ef0
f0101359:	68 2f 4e 10 f0       	push   $0xf0104e2f
f010135e:	68 c3 02 00 00       	push   $0x2c3
f0101363:	68 09 4e 10 f0       	push   $0xf0104e09
f0101368:	e8 33 ed ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f010136d:	83 ec 0c             	sub    $0xc,%esp
f0101370:	6a 00                	push   $0x0
f0101372:	e8 88 f9 ff ff       	call   f0100cff <page_alloc>
f0101377:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010137a:	83 c4 10             	add    $0x10,%esp
f010137d:	85 c0                	test   %eax,%eax
f010137f:	75 19                	jne    f010139a <mem_init+0x3c0>
f0101381:	68 06 4f 10 f0       	push   $0xf0104f06
f0101386:	68 2f 4e 10 f0       	push   $0xf0104e2f
f010138b:	68 c4 02 00 00       	push   $0x2c4
f0101390:	68 09 4e 10 f0       	push   $0xf0104e09
f0101395:	e8 06 ed ff ff       	call   f01000a0 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010139a:	39 fe                	cmp    %edi,%esi
f010139c:	75 19                	jne    f01013b7 <mem_init+0x3dd>
f010139e:	68 1c 4f 10 f0       	push   $0xf0104f1c
f01013a3:	68 2f 4e 10 f0       	push   $0xf0104e2f
f01013a8:	68 c6 02 00 00       	push   $0x2c6
f01013ad:	68 09 4e 10 f0       	push   $0xf0104e09
f01013b2:	e8 e9 ec ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01013b7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01013ba:	39 c7                	cmp    %eax,%edi
f01013bc:	74 04                	je     f01013c2 <mem_init+0x3e8>
f01013be:	39 c6                	cmp    %eax,%esi
f01013c0:	75 19                	jne    f01013db <mem_init+0x401>
f01013c2:	68 ec 47 10 f0       	push   $0xf01047ec
f01013c7:	68 2f 4e 10 f0       	push   $0xf0104e2f
f01013cc:	68 c7 02 00 00       	push   $0x2c7
f01013d1:	68 09 4e 10 f0       	push   $0xf0104e09
f01013d6:	e8 c5 ec ff ff       	call   f01000a0 <_panic>
	assert(!page_alloc(0));
f01013db:	83 ec 0c             	sub    $0xc,%esp
f01013de:	6a 00                	push   $0x0
f01013e0:	e8 1a f9 ff ff       	call   f0100cff <page_alloc>
f01013e5:	83 c4 10             	add    $0x10,%esp
f01013e8:	85 c0                	test   %eax,%eax
f01013ea:	74 19                	je     f0101405 <mem_init+0x42b>
f01013ec:	68 85 4f 10 f0       	push   $0xf0104f85
f01013f1:	68 2f 4e 10 f0       	push   $0xf0104e2f
f01013f6:	68 c8 02 00 00       	push   $0x2c8
f01013fb:	68 09 4e 10 f0       	push   $0xf0104e09
f0101400:	e8 9b ec ff ff       	call   f01000a0 <_panic>
f0101405:	89 f0                	mov    %esi,%eax
f0101407:	2b 05 4c 7c 17 f0    	sub    0xf0177c4c,%eax
f010140d:	c1 f8 03             	sar    $0x3,%eax
f0101410:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101413:	89 c2                	mov    %eax,%edx
f0101415:	c1 ea 0c             	shr    $0xc,%edx
f0101418:	3b 15 44 7c 17 f0    	cmp    0xf0177c44,%edx
f010141e:	72 12                	jb     f0101432 <mem_init+0x458>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101420:	50                   	push   %eax
f0101421:	68 84 46 10 f0       	push   $0xf0104684
f0101426:	6a 56                	push   $0x56
f0101428:	68 15 4e 10 f0       	push   $0xf0104e15
f010142d:	e8 6e ec ff ff       	call   f01000a0 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101432:	83 ec 04             	sub    $0x4,%esp
f0101435:	68 00 10 00 00       	push   $0x1000
f010143a:	6a 01                	push   $0x1
f010143c:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101441:	50                   	push   %eax
f0101442:	e8 4f 28 00 00       	call   f0103c96 <memset>
	page_free(pp0);
f0101447:	89 34 24             	mov    %esi,(%esp)
f010144a:	e8 20 f9 ff ff       	call   f0100d6f <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f010144f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101456:	e8 a4 f8 ff ff       	call   f0100cff <page_alloc>
f010145b:	83 c4 10             	add    $0x10,%esp
f010145e:	85 c0                	test   %eax,%eax
f0101460:	75 19                	jne    f010147b <mem_init+0x4a1>
f0101462:	68 94 4f 10 f0       	push   $0xf0104f94
f0101467:	68 2f 4e 10 f0       	push   $0xf0104e2f
f010146c:	68 cd 02 00 00       	push   $0x2cd
f0101471:	68 09 4e 10 f0       	push   $0xf0104e09
f0101476:	e8 25 ec ff ff       	call   f01000a0 <_panic>
	assert(pp && pp0 == pp);
f010147b:	39 c6                	cmp    %eax,%esi
f010147d:	74 19                	je     f0101498 <mem_init+0x4be>
f010147f:	68 b2 4f 10 f0       	push   $0xf0104fb2
f0101484:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0101489:	68 ce 02 00 00       	push   $0x2ce
f010148e:	68 09 4e 10 f0       	push   $0xf0104e09
f0101493:	e8 08 ec ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101498:	89 f0                	mov    %esi,%eax
f010149a:	2b 05 4c 7c 17 f0    	sub    0xf0177c4c,%eax
f01014a0:	c1 f8 03             	sar    $0x3,%eax
f01014a3:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01014a6:	89 c2                	mov    %eax,%edx
f01014a8:	c1 ea 0c             	shr    $0xc,%edx
f01014ab:	3b 15 44 7c 17 f0    	cmp    0xf0177c44,%edx
f01014b1:	72 12                	jb     f01014c5 <mem_init+0x4eb>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01014b3:	50                   	push   %eax
f01014b4:	68 84 46 10 f0       	push   $0xf0104684
f01014b9:	6a 56                	push   $0x56
f01014bb:	68 15 4e 10 f0       	push   $0xf0104e15
f01014c0:	e8 db eb ff ff       	call   f01000a0 <_panic>
f01014c5:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f01014cb:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01014d1:	80 38 00             	cmpb   $0x0,(%eax)
f01014d4:	74 19                	je     f01014ef <mem_init+0x515>
f01014d6:	68 c2 4f 10 f0       	push   $0xf0104fc2
f01014db:	68 2f 4e 10 f0       	push   $0xf0104e2f
f01014e0:	68 d1 02 00 00       	push   $0x2d1
f01014e5:	68 09 4e 10 f0       	push   $0xf0104e09
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
f01014f9:	a3 7c 6f 17 f0       	mov    %eax,0xf0176f7c

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
f010151a:	a1 7c 6f 17 f0       	mov    0xf0176f7c,%eax
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
f0101531:	68 cc 4f 10 f0       	push   $0xf0104fcc
f0101536:	68 2f 4e 10 f0       	push   $0xf0104e2f
f010153b:	68 de 02 00 00       	push   $0x2de
f0101540:	68 09 4e 10 f0       	push   $0xf0104e09
f0101545:	e8 56 eb ff ff       	call   f01000a0 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f010154a:	83 ec 0c             	sub    $0xc,%esp
f010154d:	68 0c 48 10 f0       	push   $0xf010480c
f0101552:	e8 9b 18 00 00       	call   f0102df2 <cprintf>
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
f010156d:	68 da 4e 10 f0       	push   $0xf0104eda
f0101572:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0101577:	68 3c 03 00 00       	push   $0x33c
f010157c:	68 09 4e 10 f0       	push   $0xf0104e09
f0101581:	e8 1a eb ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f0101586:	83 ec 0c             	sub    $0xc,%esp
f0101589:	6a 00                	push   $0x0
f010158b:	e8 6f f7 ff ff       	call   f0100cff <page_alloc>
f0101590:	89 c3                	mov    %eax,%ebx
f0101592:	83 c4 10             	add    $0x10,%esp
f0101595:	85 c0                	test   %eax,%eax
f0101597:	75 19                	jne    f01015b2 <mem_init+0x5d8>
f0101599:	68 f0 4e 10 f0       	push   $0xf0104ef0
f010159e:	68 2f 4e 10 f0       	push   $0xf0104e2f
f01015a3:	68 3d 03 00 00       	push   $0x33d
f01015a8:	68 09 4e 10 f0       	push   $0xf0104e09
f01015ad:	e8 ee ea ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f01015b2:	83 ec 0c             	sub    $0xc,%esp
f01015b5:	6a 00                	push   $0x0
f01015b7:	e8 43 f7 ff ff       	call   f0100cff <page_alloc>
f01015bc:	89 c6                	mov    %eax,%esi
f01015be:	83 c4 10             	add    $0x10,%esp
f01015c1:	85 c0                	test   %eax,%eax
f01015c3:	75 19                	jne    f01015de <mem_init+0x604>
f01015c5:	68 06 4f 10 f0       	push   $0xf0104f06
f01015ca:	68 2f 4e 10 f0       	push   $0xf0104e2f
f01015cf:	68 3e 03 00 00       	push   $0x33e
f01015d4:	68 09 4e 10 f0       	push   $0xf0104e09
f01015d9:	e8 c2 ea ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01015de:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01015e1:	75 19                	jne    f01015fc <mem_init+0x622>
f01015e3:	68 1c 4f 10 f0       	push   $0xf0104f1c
f01015e8:	68 2f 4e 10 f0       	push   $0xf0104e2f
f01015ed:	68 41 03 00 00       	push   $0x341
f01015f2:	68 09 4e 10 f0       	push   $0xf0104e09
f01015f7:	e8 a4 ea ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01015fc:	39 c3                	cmp    %eax,%ebx
f01015fe:	74 05                	je     f0101605 <mem_init+0x62b>
f0101600:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101603:	75 19                	jne    f010161e <mem_init+0x644>
f0101605:	68 ec 47 10 f0       	push   $0xf01047ec
f010160a:	68 2f 4e 10 f0       	push   $0xf0104e2f
f010160f:	68 42 03 00 00       	push   $0x342
f0101614:	68 09 4e 10 f0       	push   $0xf0104e09
f0101619:	e8 82 ea ff ff       	call   f01000a0 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010161e:	a1 7c 6f 17 f0       	mov    0xf0176f7c,%eax
f0101623:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101626:	c7 05 7c 6f 17 f0 00 	movl   $0x0,0xf0176f7c
f010162d:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101630:	83 ec 0c             	sub    $0xc,%esp
f0101633:	6a 00                	push   $0x0
f0101635:	e8 c5 f6 ff ff       	call   f0100cff <page_alloc>
f010163a:	83 c4 10             	add    $0x10,%esp
f010163d:	85 c0                	test   %eax,%eax
f010163f:	74 19                	je     f010165a <mem_init+0x680>
f0101641:	68 85 4f 10 f0       	push   $0xf0104f85
f0101646:	68 2f 4e 10 f0       	push   $0xf0104e2f
f010164b:	68 49 03 00 00       	push   $0x349
f0101650:	68 09 4e 10 f0       	push   $0xf0104e09
f0101655:	e8 46 ea ff ff       	call   f01000a0 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f010165a:	83 ec 04             	sub    $0x4,%esp
f010165d:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101660:	50                   	push   %eax
f0101661:	6a 00                	push   $0x0
f0101663:	ff 35 48 7c 17 f0    	pushl  0xf0177c48
f0101669:	e8 58 f8 ff ff       	call   f0100ec6 <page_lookup>
f010166e:	83 c4 10             	add    $0x10,%esp
f0101671:	85 c0                	test   %eax,%eax
f0101673:	74 19                	je     f010168e <mem_init+0x6b4>
f0101675:	68 2c 48 10 f0       	push   $0xf010482c
f010167a:	68 2f 4e 10 f0       	push   $0xf0104e2f
f010167f:	68 4c 03 00 00       	push   $0x34c
f0101684:	68 09 4e 10 f0       	push   $0xf0104e09
f0101689:	e8 12 ea ff ff       	call   f01000a0 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f010168e:	6a 02                	push   $0x2
f0101690:	6a 00                	push   $0x0
f0101692:	53                   	push   %ebx
f0101693:	ff 35 48 7c 17 f0    	pushl  0xf0177c48
f0101699:	e8 d6 f8 ff ff       	call   f0100f74 <page_insert>
f010169e:	83 c4 10             	add    $0x10,%esp
f01016a1:	85 c0                	test   %eax,%eax
f01016a3:	78 19                	js     f01016be <mem_init+0x6e4>
f01016a5:	68 64 48 10 f0       	push   $0xf0104864
f01016aa:	68 2f 4e 10 f0       	push   $0xf0104e2f
f01016af:	68 4f 03 00 00       	push   $0x34f
f01016b4:	68 09 4e 10 f0       	push   $0xf0104e09
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
f01016ce:	ff 35 48 7c 17 f0    	pushl  0xf0177c48
f01016d4:	e8 9b f8 ff ff       	call   f0100f74 <page_insert>
f01016d9:	83 c4 20             	add    $0x20,%esp
f01016dc:	85 c0                	test   %eax,%eax
f01016de:	74 19                	je     f01016f9 <mem_init+0x71f>
f01016e0:	68 94 48 10 f0       	push   $0xf0104894
f01016e5:	68 2f 4e 10 f0       	push   $0xf0104e2f
f01016ea:	68 53 03 00 00       	push   $0x353
f01016ef:	68 09 4e 10 f0       	push   $0xf0104e09
f01016f4:	e8 a7 e9 ff ff       	call   f01000a0 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01016f9:	8b 3d 48 7c 17 f0    	mov    0xf0177c48,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01016ff:	a1 4c 7c 17 f0       	mov    0xf0177c4c,%eax
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
f0101720:	68 c4 48 10 f0       	push   $0xf01048c4
f0101725:	68 2f 4e 10 f0       	push   $0xf0104e2f
f010172a:	68 54 03 00 00       	push   $0x354
f010172f:	68 09 4e 10 f0       	push   $0xf0104e09
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
f0101754:	68 ec 48 10 f0       	push   $0xf01048ec
f0101759:	68 2f 4e 10 f0       	push   $0xf0104e2f
f010175e:	68 55 03 00 00       	push   $0x355
f0101763:	68 09 4e 10 f0       	push   $0xf0104e09
f0101768:	e8 33 e9 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f010176d:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101772:	74 19                	je     f010178d <mem_init+0x7b3>
f0101774:	68 d7 4f 10 f0       	push   $0xf0104fd7
f0101779:	68 2f 4e 10 f0       	push   $0xf0104e2f
f010177e:	68 56 03 00 00       	push   $0x356
f0101783:	68 09 4e 10 f0       	push   $0xf0104e09
f0101788:	e8 13 e9 ff ff       	call   f01000a0 <_panic>
	assert(pp0->pp_ref == 1);
f010178d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101790:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101795:	74 19                	je     f01017b0 <mem_init+0x7d6>
f0101797:	68 e8 4f 10 f0       	push   $0xf0104fe8
f010179c:	68 2f 4e 10 f0       	push   $0xf0104e2f
f01017a1:	68 57 03 00 00       	push   $0x357
f01017a6:	68 09 4e 10 f0       	push   $0xf0104e09
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
f01017c5:	68 1c 49 10 f0       	push   $0xf010491c
f01017ca:	68 2f 4e 10 f0       	push   $0xf0104e2f
f01017cf:	68 5a 03 00 00       	push   $0x35a
f01017d4:	68 09 4e 10 f0       	push   $0xf0104e09
f01017d9:	e8 c2 e8 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01017de:	ba 00 10 00 00       	mov    $0x1000,%edx
f01017e3:	a1 48 7c 17 f0       	mov    0xf0177c48,%eax
f01017e8:	e8 40 f1 ff ff       	call   f010092d <check_va2pa>
f01017ed:	89 f2                	mov    %esi,%edx
f01017ef:	2b 15 4c 7c 17 f0    	sub    0xf0177c4c,%edx
f01017f5:	c1 fa 03             	sar    $0x3,%edx
f01017f8:	c1 e2 0c             	shl    $0xc,%edx
f01017fb:	39 d0                	cmp    %edx,%eax
f01017fd:	74 19                	je     f0101818 <mem_init+0x83e>
f01017ff:	68 58 49 10 f0       	push   $0xf0104958
f0101804:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0101809:	68 5b 03 00 00       	push   $0x35b
f010180e:	68 09 4e 10 f0       	push   $0xf0104e09
f0101813:	e8 88 e8 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0101818:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010181d:	74 19                	je     f0101838 <mem_init+0x85e>
f010181f:	68 f9 4f 10 f0       	push   $0xf0104ff9
f0101824:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0101829:	68 5c 03 00 00       	push   $0x35c
f010182e:	68 09 4e 10 f0       	push   $0xf0104e09
f0101833:	e8 68 e8 ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101838:	83 ec 0c             	sub    $0xc,%esp
f010183b:	6a 00                	push   $0x0
f010183d:	e8 bd f4 ff ff       	call   f0100cff <page_alloc>
f0101842:	83 c4 10             	add    $0x10,%esp
f0101845:	85 c0                	test   %eax,%eax
f0101847:	74 19                	je     f0101862 <mem_init+0x888>
f0101849:	68 85 4f 10 f0       	push   $0xf0104f85
f010184e:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0101853:	68 5f 03 00 00       	push   $0x35f
f0101858:	68 09 4e 10 f0       	push   $0xf0104e09
f010185d:	e8 3e e8 ff ff       	call   f01000a0 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101862:	6a 02                	push   $0x2
f0101864:	68 00 10 00 00       	push   $0x1000
f0101869:	56                   	push   %esi
f010186a:	ff 35 48 7c 17 f0    	pushl  0xf0177c48
f0101870:	e8 ff f6 ff ff       	call   f0100f74 <page_insert>
f0101875:	83 c4 10             	add    $0x10,%esp
f0101878:	85 c0                	test   %eax,%eax
f010187a:	74 19                	je     f0101895 <mem_init+0x8bb>
f010187c:	68 1c 49 10 f0       	push   $0xf010491c
f0101881:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0101886:	68 62 03 00 00       	push   $0x362
f010188b:	68 09 4e 10 f0       	push   $0xf0104e09
f0101890:	e8 0b e8 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101895:	ba 00 10 00 00       	mov    $0x1000,%edx
f010189a:	a1 48 7c 17 f0       	mov    0xf0177c48,%eax
f010189f:	e8 89 f0 ff ff       	call   f010092d <check_va2pa>
f01018a4:	89 f2                	mov    %esi,%edx
f01018a6:	2b 15 4c 7c 17 f0    	sub    0xf0177c4c,%edx
f01018ac:	c1 fa 03             	sar    $0x3,%edx
f01018af:	c1 e2 0c             	shl    $0xc,%edx
f01018b2:	39 d0                	cmp    %edx,%eax
f01018b4:	74 19                	je     f01018cf <mem_init+0x8f5>
f01018b6:	68 58 49 10 f0       	push   $0xf0104958
f01018bb:	68 2f 4e 10 f0       	push   $0xf0104e2f
f01018c0:	68 63 03 00 00       	push   $0x363
f01018c5:	68 09 4e 10 f0       	push   $0xf0104e09
f01018ca:	e8 d1 e7 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f01018cf:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01018d4:	74 19                	je     f01018ef <mem_init+0x915>
f01018d6:	68 f9 4f 10 f0       	push   $0xf0104ff9
f01018db:	68 2f 4e 10 f0       	push   $0xf0104e2f
f01018e0:	68 64 03 00 00       	push   $0x364
f01018e5:	68 09 4e 10 f0       	push   $0xf0104e09
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
f0101900:	68 85 4f 10 f0       	push   $0xf0104f85
f0101905:	68 2f 4e 10 f0       	push   $0xf0104e2f
f010190a:	68 68 03 00 00       	push   $0x368
f010190f:	68 09 4e 10 f0       	push   $0xf0104e09
f0101914:	e8 87 e7 ff ff       	call   f01000a0 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101919:	8b 15 48 7c 17 f0    	mov    0xf0177c48,%edx
f010191f:	8b 02                	mov    (%edx),%eax
f0101921:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101926:	89 c1                	mov    %eax,%ecx
f0101928:	c1 e9 0c             	shr    $0xc,%ecx
f010192b:	3b 0d 44 7c 17 f0    	cmp    0xf0177c44,%ecx
f0101931:	72 15                	jb     f0101948 <mem_init+0x96e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101933:	50                   	push   %eax
f0101934:	68 84 46 10 f0       	push   $0xf0104684
f0101939:	68 6b 03 00 00       	push   $0x36b
f010193e:	68 09 4e 10 f0       	push   $0xf0104e09
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
f010196d:	68 88 49 10 f0       	push   $0xf0104988
f0101972:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0101977:	68 6c 03 00 00       	push   $0x36c
f010197c:	68 09 4e 10 f0       	push   $0xf0104e09
f0101981:	e8 1a e7 ff ff       	call   f01000a0 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101986:	6a 06                	push   $0x6
f0101988:	68 00 10 00 00       	push   $0x1000
f010198d:	56                   	push   %esi
f010198e:	ff 35 48 7c 17 f0    	pushl  0xf0177c48
f0101994:	e8 db f5 ff ff       	call   f0100f74 <page_insert>
f0101999:	83 c4 10             	add    $0x10,%esp
f010199c:	85 c0                	test   %eax,%eax
f010199e:	74 19                	je     f01019b9 <mem_init+0x9df>
f01019a0:	68 c8 49 10 f0       	push   $0xf01049c8
f01019a5:	68 2f 4e 10 f0       	push   $0xf0104e2f
f01019aa:	68 6f 03 00 00       	push   $0x36f
f01019af:	68 09 4e 10 f0       	push   $0xf0104e09
f01019b4:	e8 e7 e6 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01019b9:	8b 3d 48 7c 17 f0    	mov    0xf0177c48,%edi
f01019bf:	ba 00 10 00 00       	mov    $0x1000,%edx
f01019c4:	89 f8                	mov    %edi,%eax
f01019c6:	e8 62 ef ff ff       	call   f010092d <check_va2pa>
f01019cb:	89 f2                	mov    %esi,%edx
f01019cd:	2b 15 4c 7c 17 f0    	sub    0xf0177c4c,%edx
f01019d3:	c1 fa 03             	sar    $0x3,%edx
f01019d6:	c1 e2 0c             	shl    $0xc,%edx
f01019d9:	39 d0                	cmp    %edx,%eax
f01019db:	74 19                	je     f01019f6 <mem_init+0xa1c>
f01019dd:	68 58 49 10 f0       	push   $0xf0104958
f01019e2:	68 2f 4e 10 f0       	push   $0xf0104e2f
f01019e7:	68 70 03 00 00       	push   $0x370
f01019ec:	68 09 4e 10 f0       	push   $0xf0104e09
f01019f1:	e8 aa e6 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f01019f6:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01019fb:	74 19                	je     f0101a16 <mem_init+0xa3c>
f01019fd:	68 f9 4f 10 f0       	push   $0xf0104ff9
f0101a02:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0101a07:	68 71 03 00 00       	push   $0x371
f0101a0c:	68 09 4e 10 f0       	push   $0xf0104e09
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
f0101a2e:	68 08 4a 10 f0       	push   $0xf0104a08
f0101a33:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0101a38:	68 72 03 00 00       	push   $0x372
f0101a3d:	68 09 4e 10 f0       	push   $0xf0104e09
f0101a42:	e8 59 e6 ff ff       	call   f01000a0 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101a47:	a1 48 7c 17 f0       	mov    0xf0177c48,%eax
f0101a4c:	f6 00 04             	testb  $0x4,(%eax)
f0101a4f:	75 19                	jne    f0101a6a <mem_init+0xa90>
f0101a51:	68 0a 50 10 f0       	push   $0xf010500a
f0101a56:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0101a5b:	68 73 03 00 00       	push   $0x373
f0101a60:	68 09 4e 10 f0       	push   $0xf0104e09
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
f0101a7f:	68 1c 49 10 f0       	push   $0xf010491c
f0101a84:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0101a89:	68 76 03 00 00       	push   $0x376
f0101a8e:	68 09 4e 10 f0       	push   $0xf0104e09
f0101a93:	e8 08 e6 ff ff       	call   f01000a0 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101a98:	83 ec 04             	sub    $0x4,%esp
f0101a9b:	6a 00                	push   $0x0
f0101a9d:	68 00 10 00 00       	push   $0x1000
f0101aa2:	ff 35 48 7c 17 f0    	pushl  0xf0177c48
f0101aa8:	e8 f8 f2 ff ff       	call   f0100da5 <pgdir_walk>
f0101aad:	83 c4 10             	add    $0x10,%esp
f0101ab0:	f6 00 02             	testb  $0x2,(%eax)
f0101ab3:	75 19                	jne    f0101ace <mem_init+0xaf4>
f0101ab5:	68 3c 4a 10 f0       	push   $0xf0104a3c
f0101aba:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0101abf:	68 77 03 00 00       	push   $0x377
f0101ac4:	68 09 4e 10 f0       	push   $0xf0104e09
f0101ac9:	e8 d2 e5 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101ace:	83 ec 04             	sub    $0x4,%esp
f0101ad1:	6a 00                	push   $0x0
f0101ad3:	68 00 10 00 00       	push   $0x1000
f0101ad8:	ff 35 48 7c 17 f0    	pushl  0xf0177c48
f0101ade:	e8 c2 f2 ff ff       	call   f0100da5 <pgdir_walk>
f0101ae3:	83 c4 10             	add    $0x10,%esp
f0101ae6:	f6 00 04             	testb  $0x4,(%eax)
f0101ae9:	74 19                	je     f0101b04 <mem_init+0xb2a>
f0101aeb:	68 70 4a 10 f0       	push   $0xf0104a70
f0101af0:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0101af5:	68 78 03 00 00       	push   $0x378
f0101afa:	68 09 4e 10 f0       	push   $0xf0104e09
f0101aff:	e8 9c e5 ff ff       	call   f01000a0 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101b04:	6a 02                	push   $0x2
f0101b06:	68 00 00 40 00       	push   $0x400000
f0101b0b:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101b0e:	ff 35 48 7c 17 f0    	pushl  0xf0177c48
f0101b14:	e8 5b f4 ff ff       	call   f0100f74 <page_insert>
f0101b19:	83 c4 10             	add    $0x10,%esp
f0101b1c:	85 c0                	test   %eax,%eax
f0101b1e:	78 19                	js     f0101b39 <mem_init+0xb5f>
f0101b20:	68 a8 4a 10 f0       	push   $0xf0104aa8
f0101b25:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0101b2a:	68 7b 03 00 00       	push   $0x37b
f0101b2f:	68 09 4e 10 f0       	push   $0xf0104e09
f0101b34:	e8 67 e5 ff ff       	call   f01000a0 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101b39:	6a 02                	push   $0x2
f0101b3b:	68 00 10 00 00       	push   $0x1000
f0101b40:	53                   	push   %ebx
f0101b41:	ff 35 48 7c 17 f0    	pushl  0xf0177c48
f0101b47:	e8 28 f4 ff ff       	call   f0100f74 <page_insert>
f0101b4c:	83 c4 10             	add    $0x10,%esp
f0101b4f:	85 c0                	test   %eax,%eax
f0101b51:	74 19                	je     f0101b6c <mem_init+0xb92>
f0101b53:	68 e0 4a 10 f0       	push   $0xf0104ae0
f0101b58:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0101b5d:	68 7e 03 00 00       	push   $0x37e
f0101b62:	68 09 4e 10 f0       	push   $0xf0104e09
f0101b67:	e8 34 e5 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101b6c:	83 ec 04             	sub    $0x4,%esp
f0101b6f:	6a 00                	push   $0x0
f0101b71:	68 00 10 00 00       	push   $0x1000
f0101b76:	ff 35 48 7c 17 f0    	pushl  0xf0177c48
f0101b7c:	e8 24 f2 ff ff       	call   f0100da5 <pgdir_walk>
f0101b81:	83 c4 10             	add    $0x10,%esp
f0101b84:	f6 00 04             	testb  $0x4,(%eax)
f0101b87:	74 19                	je     f0101ba2 <mem_init+0xbc8>
f0101b89:	68 70 4a 10 f0       	push   $0xf0104a70
f0101b8e:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0101b93:	68 7f 03 00 00       	push   $0x37f
f0101b98:	68 09 4e 10 f0       	push   $0xf0104e09
f0101b9d:	e8 fe e4 ff ff       	call   f01000a0 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101ba2:	8b 3d 48 7c 17 f0    	mov    0xf0177c48,%edi
f0101ba8:	ba 00 00 00 00       	mov    $0x0,%edx
f0101bad:	89 f8                	mov    %edi,%eax
f0101baf:	e8 79 ed ff ff       	call   f010092d <check_va2pa>
f0101bb4:	89 c1                	mov    %eax,%ecx
f0101bb6:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101bb9:	89 d8                	mov    %ebx,%eax
f0101bbb:	2b 05 4c 7c 17 f0    	sub    0xf0177c4c,%eax
f0101bc1:	c1 f8 03             	sar    $0x3,%eax
f0101bc4:	c1 e0 0c             	shl    $0xc,%eax
f0101bc7:	39 c1                	cmp    %eax,%ecx
f0101bc9:	74 19                	je     f0101be4 <mem_init+0xc0a>
f0101bcb:	68 1c 4b 10 f0       	push   $0xf0104b1c
f0101bd0:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0101bd5:	68 82 03 00 00       	push   $0x382
f0101bda:	68 09 4e 10 f0       	push   $0xf0104e09
f0101bdf:	e8 bc e4 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101be4:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101be9:	89 f8                	mov    %edi,%eax
f0101beb:	e8 3d ed ff ff       	call   f010092d <check_va2pa>
f0101bf0:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101bf3:	74 19                	je     f0101c0e <mem_init+0xc34>
f0101bf5:	68 48 4b 10 f0       	push   $0xf0104b48
f0101bfa:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0101bff:	68 83 03 00 00       	push   $0x383
f0101c04:	68 09 4e 10 f0       	push   $0xf0104e09
f0101c09:	e8 92 e4 ff ff       	call   f01000a0 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101c0e:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101c13:	74 19                	je     f0101c2e <mem_init+0xc54>
f0101c15:	68 20 50 10 f0       	push   $0xf0105020
f0101c1a:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0101c1f:	68 85 03 00 00       	push   $0x385
f0101c24:	68 09 4e 10 f0       	push   $0xf0104e09
f0101c29:	e8 72 e4 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101c2e:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101c33:	74 19                	je     f0101c4e <mem_init+0xc74>
f0101c35:	68 31 50 10 f0       	push   $0xf0105031
f0101c3a:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0101c3f:	68 86 03 00 00       	push   $0x386
f0101c44:	68 09 4e 10 f0       	push   $0xf0104e09
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
f0101c63:	68 78 4b 10 f0       	push   $0xf0104b78
f0101c68:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0101c6d:	68 89 03 00 00       	push   $0x389
f0101c72:	68 09 4e 10 f0       	push   $0xf0104e09
f0101c77:	e8 24 e4 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101c7c:	83 ec 08             	sub    $0x8,%esp
f0101c7f:	6a 00                	push   $0x0
f0101c81:	ff 35 48 7c 17 f0    	pushl  0xf0177c48
f0101c87:	e8 a5 f2 ff ff       	call   f0100f31 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101c8c:	8b 3d 48 7c 17 f0    	mov    0xf0177c48,%edi
f0101c92:	ba 00 00 00 00       	mov    $0x0,%edx
f0101c97:	89 f8                	mov    %edi,%eax
f0101c99:	e8 8f ec ff ff       	call   f010092d <check_va2pa>
f0101c9e:	83 c4 10             	add    $0x10,%esp
f0101ca1:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101ca4:	74 19                	je     f0101cbf <mem_init+0xce5>
f0101ca6:	68 9c 4b 10 f0       	push   $0xf0104b9c
f0101cab:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0101cb0:	68 8d 03 00 00       	push   $0x38d
f0101cb5:	68 09 4e 10 f0       	push   $0xf0104e09
f0101cba:	e8 e1 e3 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101cbf:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101cc4:	89 f8                	mov    %edi,%eax
f0101cc6:	e8 62 ec ff ff       	call   f010092d <check_va2pa>
f0101ccb:	89 da                	mov    %ebx,%edx
f0101ccd:	2b 15 4c 7c 17 f0    	sub    0xf0177c4c,%edx
f0101cd3:	c1 fa 03             	sar    $0x3,%edx
f0101cd6:	c1 e2 0c             	shl    $0xc,%edx
f0101cd9:	39 d0                	cmp    %edx,%eax
f0101cdb:	74 19                	je     f0101cf6 <mem_init+0xd1c>
f0101cdd:	68 48 4b 10 f0       	push   $0xf0104b48
f0101ce2:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0101ce7:	68 8e 03 00 00       	push   $0x38e
f0101cec:	68 09 4e 10 f0       	push   $0xf0104e09
f0101cf1:	e8 aa e3 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f0101cf6:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101cfb:	74 19                	je     f0101d16 <mem_init+0xd3c>
f0101cfd:	68 d7 4f 10 f0       	push   $0xf0104fd7
f0101d02:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0101d07:	68 8f 03 00 00       	push   $0x38f
f0101d0c:	68 09 4e 10 f0       	push   $0xf0104e09
f0101d11:	e8 8a e3 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101d16:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101d1b:	74 19                	je     f0101d36 <mem_init+0xd5c>
f0101d1d:	68 31 50 10 f0       	push   $0xf0105031
f0101d22:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0101d27:	68 90 03 00 00       	push   $0x390
f0101d2c:	68 09 4e 10 f0       	push   $0xf0104e09
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
f0101d4b:	68 c0 4b 10 f0       	push   $0xf0104bc0
f0101d50:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0101d55:	68 93 03 00 00       	push   $0x393
f0101d5a:	68 09 4e 10 f0       	push   $0xf0104e09
f0101d5f:	e8 3c e3 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref);
f0101d64:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101d69:	75 19                	jne    f0101d84 <mem_init+0xdaa>
f0101d6b:	68 42 50 10 f0       	push   $0xf0105042
f0101d70:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0101d75:	68 94 03 00 00       	push   $0x394
f0101d7a:	68 09 4e 10 f0       	push   $0xf0104e09
f0101d7f:	e8 1c e3 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_link == NULL);
f0101d84:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101d87:	74 19                	je     f0101da2 <mem_init+0xdc8>
f0101d89:	68 4e 50 10 f0       	push   $0xf010504e
f0101d8e:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0101d93:	68 95 03 00 00       	push   $0x395
f0101d98:	68 09 4e 10 f0       	push   $0xf0104e09
f0101d9d:	e8 fe e2 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101da2:	83 ec 08             	sub    $0x8,%esp
f0101da5:	68 00 10 00 00       	push   $0x1000
f0101daa:	ff 35 48 7c 17 f0    	pushl  0xf0177c48
f0101db0:	e8 7c f1 ff ff       	call   f0100f31 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101db5:	8b 3d 48 7c 17 f0    	mov    0xf0177c48,%edi
f0101dbb:	ba 00 00 00 00       	mov    $0x0,%edx
f0101dc0:	89 f8                	mov    %edi,%eax
f0101dc2:	e8 66 eb ff ff       	call   f010092d <check_va2pa>
f0101dc7:	83 c4 10             	add    $0x10,%esp
f0101dca:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101dcd:	74 19                	je     f0101de8 <mem_init+0xe0e>
f0101dcf:	68 9c 4b 10 f0       	push   $0xf0104b9c
f0101dd4:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0101dd9:	68 99 03 00 00       	push   $0x399
f0101dde:	68 09 4e 10 f0       	push   $0xf0104e09
f0101de3:	e8 b8 e2 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101de8:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ded:	89 f8                	mov    %edi,%eax
f0101def:	e8 39 eb ff ff       	call   f010092d <check_va2pa>
f0101df4:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101df7:	74 19                	je     f0101e12 <mem_init+0xe38>
f0101df9:	68 f8 4b 10 f0       	push   $0xf0104bf8
f0101dfe:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0101e03:	68 9a 03 00 00       	push   $0x39a
f0101e08:	68 09 4e 10 f0       	push   $0xf0104e09
f0101e0d:	e8 8e e2 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f0101e12:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101e17:	74 19                	je     f0101e32 <mem_init+0xe58>
f0101e19:	68 63 50 10 f0       	push   $0xf0105063
f0101e1e:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0101e23:	68 9b 03 00 00       	push   $0x39b
f0101e28:	68 09 4e 10 f0       	push   $0xf0104e09
f0101e2d:	e8 6e e2 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101e32:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101e37:	74 19                	je     f0101e52 <mem_init+0xe78>
f0101e39:	68 31 50 10 f0       	push   $0xf0105031
f0101e3e:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0101e43:	68 9c 03 00 00       	push   $0x39c
f0101e48:	68 09 4e 10 f0       	push   $0xf0104e09
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
f0101e67:	68 20 4c 10 f0       	push   $0xf0104c20
f0101e6c:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0101e71:	68 9f 03 00 00       	push   $0x39f
f0101e76:	68 09 4e 10 f0       	push   $0xf0104e09
f0101e7b:	e8 20 e2 ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101e80:	83 ec 0c             	sub    $0xc,%esp
f0101e83:	6a 00                	push   $0x0
f0101e85:	e8 75 ee ff ff       	call   f0100cff <page_alloc>
f0101e8a:	83 c4 10             	add    $0x10,%esp
f0101e8d:	85 c0                	test   %eax,%eax
f0101e8f:	74 19                	je     f0101eaa <mem_init+0xed0>
f0101e91:	68 85 4f 10 f0       	push   $0xf0104f85
f0101e96:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0101e9b:	68 a2 03 00 00       	push   $0x3a2
f0101ea0:	68 09 4e 10 f0       	push   $0xf0104e09
f0101ea5:	e8 f6 e1 ff ff       	call   f01000a0 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101eaa:	8b 0d 48 7c 17 f0    	mov    0xf0177c48,%ecx
f0101eb0:	8b 11                	mov    (%ecx),%edx
f0101eb2:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101eb8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ebb:	2b 05 4c 7c 17 f0    	sub    0xf0177c4c,%eax
f0101ec1:	c1 f8 03             	sar    $0x3,%eax
f0101ec4:	c1 e0 0c             	shl    $0xc,%eax
f0101ec7:	39 c2                	cmp    %eax,%edx
f0101ec9:	74 19                	je     f0101ee4 <mem_init+0xf0a>
f0101ecb:	68 c4 48 10 f0       	push   $0xf01048c4
f0101ed0:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0101ed5:	68 a5 03 00 00       	push   $0x3a5
f0101eda:	68 09 4e 10 f0       	push   $0xf0104e09
f0101edf:	e8 bc e1 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f0101ee4:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101eea:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101eed:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101ef2:	74 19                	je     f0101f0d <mem_init+0xf33>
f0101ef4:	68 e8 4f 10 f0       	push   $0xf0104fe8
f0101ef9:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0101efe:	68 a7 03 00 00       	push   $0x3a7
f0101f03:	68 09 4e 10 f0       	push   $0xf0104e09
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
f0101f29:	ff 35 48 7c 17 f0    	pushl  0xf0177c48
f0101f2f:	e8 71 ee ff ff       	call   f0100da5 <pgdir_walk>
f0101f34:	89 c7                	mov    %eax,%edi
f0101f36:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101f39:	a1 48 7c 17 f0       	mov    0xf0177c48,%eax
f0101f3e:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101f41:	8b 40 04             	mov    0x4(%eax),%eax
f0101f44:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101f49:	8b 0d 44 7c 17 f0    	mov    0xf0177c44,%ecx
f0101f4f:	89 c2                	mov    %eax,%edx
f0101f51:	c1 ea 0c             	shr    $0xc,%edx
f0101f54:	83 c4 10             	add    $0x10,%esp
f0101f57:	39 ca                	cmp    %ecx,%edx
f0101f59:	72 15                	jb     f0101f70 <mem_init+0xf96>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101f5b:	50                   	push   %eax
f0101f5c:	68 84 46 10 f0       	push   $0xf0104684
f0101f61:	68 ae 03 00 00       	push   $0x3ae
f0101f66:	68 09 4e 10 f0       	push   $0xf0104e09
f0101f6b:	e8 30 e1 ff ff       	call   f01000a0 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0101f70:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0101f75:	39 c7                	cmp    %eax,%edi
f0101f77:	74 19                	je     f0101f92 <mem_init+0xfb8>
f0101f79:	68 74 50 10 f0       	push   $0xf0105074
f0101f7e:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0101f83:	68 af 03 00 00       	push   $0x3af
f0101f88:	68 09 4e 10 f0       	push   $0xf0104e09
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
f0101fa5:	2b 05 4c 7c 17 f0    	sub    0xf0177c4c,%eax
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
f0101fbb:	68 84 46 10 f0       	push   $0xf0104684
f0101fc0:	6a 56                	push   $0x56
f0101fc2:	68 15 4e 10 f0       	push   $0xf0104e15
f0101fc7:	e8 d4 e0 ff ff       	call   f01000a0 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0101fcc:	83 ec 04             	sub    $0x4,%esp
f0101fcf:	68 00 10 00 00       	push   $0x1000
f0101fd4:	68 ff 00 00 00       	push   $0xff
f0101fd9:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101fde:	50                   	push   %eax
f0101fdf:	e8 b2 1c 00 00       	call   f0103c96 <memset>
	page_free(pp0);
f0101fe4:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101fe7:	89 3c 24             	mov    %edi,(%esp)
f0101fea:	e8 80 ed ff ff       	call   f0100d6f <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0101fef:	83 c4 0c             	add    $0xc,%esp
f0101ff2:	6a 01                	push   $0x1
f0101ff4:	6a 00                	push   $0x0
f0101ff6:	ff 35 48 7c 17 f0    	pushl  0xf0177c48
f0101ffc:	e8 a4 ed ff ff       	call   f0100da5 <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102001:	89 fa                	mov    %edi,%edx
f0102003:	2b 15 4c 7c 17 f0    	sub    0xf0177c4c,%edx
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
f0102017:	3b 05 44 7c 17 f0    	cmp    0xf0177c44,%eax
f010201d:	72 12                	jb     f0102031 <mem_init+0x1057>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010201f:	52                   	push   %edx
f0102020:	68 84 46 10 f0       	push   $0xf0104684
f0102025:	6a 56                	push   $0x56
f0102027:	68 15 4e 10 f0       	push   $0xf0104e15
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
f0102045:	68 8c 50 10 f0       	push   $0xf010508c
f010204a:	68 2f 4e 10 f0       	push   $0xf0104e2f
f010204f:	68 b9 03 00 00       	push   $0x3b9
f0102054:	68 09 4e 10 f0       	push   $0xf0104e09
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
f0102065:	a1 48 7c 17 f0       	mov    0xf0177c48,%eax
f010206a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102070:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102073:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102079:	8b 7d d0             	mov    -0x30(%ebp),%edi
f010207c:	89 3d 7c 6f 17 f0    	mov    %edi,0xf0176f7c

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
f010209b:	c7 04 24 a3 50 10 f0 	movl   $0xf01050a3,(%esp)
f01020a2:	e8 4b 0d 00 00       	call   f0102df2 <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), PTE_U);
f01020a7:	a1 4c 7c 17 f0       	mov    0xf0177c4c,%eax
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
f01020b7:	68 c8 47 10 f0       	push   $0xf01047c8
f01020bc:	68 bb 00 00 00       	push   $0xbb
f01020c1:	68 09 4e 10 f0       	push   $0xf0104e09
f01020c6:	e8 d5 df ff ff       	call   f01000a0 <_panic>
f01020cb:	83 ec 08             	sub    $0x8,%esp
f01020ce:	6a 04                	push   $0x4
f01020d0:	05 00 00 00 10       	add    $0x10000000,%eax
f01020d5:	50                   	push   %eax
f01020d6:	b9 00 00 40 00       	mov    $0x400000,%ecx
f01020db:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01020e0:	a1 48 7c 17 f0       	mov    0xf0177c48,%eax
f01020e5:	e8 86 ed ff ff       	call   f0100e70 <boot_map_region>
	boot_map_region(kern_pgdir,UENVS, PTSIZE, PADDR(envs), PTE_U);
f01020ea:	a1 88 6f 17 f0       	mov    0xf0176f88,%eax
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
f01020fa:	68 c8 47 10 f0       	push   $0xf01047c8
f01020ff:	68 bc 00 00 00       	push   $0xbc
f0102104:	68 09 4e 10 f0       	push   $0xf0104e09
f0102109:	e8 92 df ff ff       	call   f01000a0 <_panic>
f010210e:	83 ec 08             	sub    $0x8,%esp
f0102111:	6a 04                	push   $0x4
f0102113:	05 00 00 00 10       	add    $0x10000000,%eax
f0102118:	50                   	push   %eax
f0102119:	b9 00 00 40 00       	mov    $0x400000,%ecx
f010211e:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102123:	a1 48 7c 17 f0       	mov    0xf0177c48,%eax
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
f010213d:	68 c8 47 10 f0       	push   $0xf01047c8
f0102142:	68 d1 00 00 00       	push   $0xd1
f0102147:	68 09 4e 10 f0       	push   $0xf0104e09
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
f0102165:	a1 48 7c 17 f0       	mov    0xf0177c48,%eax
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
f0102180:	a1 48 7c 17 f0       	mov    0xf0177c48,%eax
f0102185:	e8 e6 ec ff ff       	call   f0100e70 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f010218a:	8b 1d 48 7c 17 f0    	mov    0xf0177c48,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102190:	a1 44 7c 17 f0       	mov    0xf0177c44,%eax
f0102195:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102198:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f010219f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01021a4:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01021a7:	8b 3d 4c 7c 17 f0    	mov    0xf0177c4c,%edi
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
f01021d1:	68 c8 47 10 f0       	push   $0xf01047c8
f01021d6:	68 f6 02 00 00       	push   $0x2f6
f01021db:	68 09 4e 10 f0       	push   $0xf0104e09
f01021e0:	e8 bb de ff ff       	call   f01000a0 <_panic>
f01021e5:	8d 94 37 00 00 00 10 	lea    0x10000000(%edi,%esi,1),%edx
f01021ec:	39 d0                	cmp    %edx,%eax
f01021ee:	74 19                	je     f0102209 <mem_init+0x122f>
f01021f0:	68 44 4c 10 f0       	push   $0xf0104c44
f01021f5:	68 2f 4e 10 f0       	push   $0xf0104e2f
f01021fa:	68 f6 02 00 00       	push   $0x2f6
f01021ff:	68 09 4e 10 f0       	push   $0xf0104e09
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
f0102214:	8b 3d 88 6f 17 f0    	mov    0xf0176f88,%edi
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
f0102235:	68 c8 47 10 f0       	push   $0xf01047c8
f010223a:	68 fb 02 00 00       	push   $0x2fb
f010223f:	68 09 4e 10 f0       	push   $0xf0104e09
f0102244:	e8 57 de ff ff       	call   f01000a0 <_panic>
f0102249:	8d 94 37 00 00 40 21 	lea    0x21400000(%edi,%esi,1),%edx
f0102250:	39 c2                	cmp    %eax,%edx
f0102252:	74 19                	je     f010226d <mem_init+0x1293>
f0102254:	68 78 4c 10 f0       	push   $0xf0104c78
f0102259:	68 2f 4e 10 f0       	push   $0xf0104e2f
f010225e:	68 fb 02 00 00       	push   $0x2fb
f0102263:	68 09 4e 10 f0       	push   $0xf0104e09
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
f0102299:	68 ac 4c 10 f0       	push   $0xf0104cac
f010229e:	68 2f 4e 10 f0       	push   $0xf0104e2f
f01022a3:	68 ff 02 00 00       	push   $0x2ff
f01022a8:	68 09 4e 10 f0       	push   $0xf0104e09
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
f01022d4:	68 d4 4c 10 f0       	push   $0xf0104cd4
f01022d9:	68 2f 4e 10 f0       	push   $0xf0104e2f
f01022de:	68 03 03 00 00       	push   $0x303
f01022e3:	68 09 4e 10 f0       	push   $0xf0104e09
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
f010230c:	68 1c 4d 10 f0       	push   $0xf0104d1c
f0102311:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0102316:	68 04 03 00 00       	push   $0x304
f010231b:	68 09 4e 10 f0       	push   $0xf0104e09
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
f0102344:	68 bc 50 10 f0       	push   $0xf01050bc
f0102349:	68 2f 4e 10 f0       	push   $0xf0104e2f
f010234e:	68 0d 03 00 00       	push   $0x30d
f0102353:	68 09 4e 10 f0       	push   $0xf0104e09
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
f0102371:	68 bc 50 10 f0       	push   $0xf01050bc
f0102376:	68 2f 4e 10 f0       	push   $0xf0104e2f
f010237b:	68 11 03 00 00       	push   $0x311
f0102380:	68 09 4e 10 f0       	push   $0xf0104e09
f0102385:	e8 16 dd ff ff       	call   f01000a0 <_panic>
				assert(pgdir[i] & PTE_W);
f010238a:	f6 c2 02             	test   $0x2,%dl
f010238d:	75 38                	jne    f01023c7 <mem_init+0x13ed>
f010238f:	68 cd 50 10 f0       	push   $0xf01050cd
f0102394:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0102399:	68 12 03 00 00       	push   $0x312
f010239e:	68 09 4e 10 f0       	push   $0xf0104e09
f01023a3:	e8 f8 dc ff ff       	call   f01000a0 <_panic>
			} else
				assert(pgdir[i] == 0);
f01023a8:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f01023ac:	74 19                	je     f01023c7 <mem_init+0x13ed>
f01023ae:	68 de 50 10 f0       	push   $0xf01050de
f01023b3:	68 2f 4e 10 f0       	push   $0xf0104e2f
f01023b8:	68 14 03 00 00       	push   $0x314
f01023bd:	68 09 4e 10 f0       	push   $0xf0104e09
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
f01023d8:	68 4c 4d 10 f0       	push   $0xf0104d4c
f01023dd:	e8 10 0a 00 00       	call   f0102df2 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f01023e2:	a1 48 7c 17 f0       	mov    0xf0177c48,%eax
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
f01023f2:	68 c8 47 10 f0       	push   $0xf01047c8
f01023f7:	68 e8 00 00 00       	push   $0xe8
f01023fc:	68 09 4e 10 f0       	push   $0xf0104e09
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
f0102439:	68 da 4e 10 f0       	push   $0xf0104eda
f010243e:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0102443:	68 d4 03 00 00       	push   $0x3d4
f0102448:	68 09 4e 10 f0       	push   $0xf0104e09
f010244d:	e8 4e dc ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f0102452:	83 ec 0c             	sub    $0xc,%esp
f0102455:	6a 00                	push   $0x0
f0102457:	e8 a3 e8 ff ff       	call   f0100cff <page_alloc>
f010245c:	89 c7                	mov    %eax,%edi
f010245e:	83 c4 10             	add    $0x10,%esp
f0102461:	85 c0                	test   %eax,%eax
f0102463:	75 19                	jne    f010247e <mem_init+0x14a4>
f0102465:	68 f0 4e 10 f0       	push   $0xf0104ef0
f010246a:	68 2f 4e 10 f0       	push   $0xf0104e2f
f010246f:	68 d5 03 00 00       	push   $0x3d5
f0102474:	68 09 4e 10 f0       	push   $0xf0104e09
f0102479:	e8 22 dc ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f010247e:	83 ec 0c             	sub    $0xc,%esp
f0102481:	6a 00                	push   $0x0
f0102483:	e8 77 e8 ff ff       	call   f0100cff <page_alloc>
f0102488:	89 c6                	mov    %eax,%esi
f010248a:	83 c4 10             	add    $0x10,%esp
f010248d:	85 c0                	test   %eax,%eax
f010248f:	75 19                	jne    f01024aa <mem_init+0x14d0>
f0102491:	68 06 4f 10 f0       	push   $0xf0104f06
f0102496:	68 2f 4e 10 f0       	push   $0xf0104e2f
f010249b:	68 d6 03 00 00       	push   $0x3d6
f01024a0:	68 09 4e 10 f0       	push   $0xf0104e09
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
f01024b5:	2b 05 4c 7c 17 f0    	sub    0xf0177c4c,%eax
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
f01024c9:	3b 15 44 7c 17 f0    	cmp    0xf0177c44,%edx
f01024cf:	72 12                	jb     f01024e3 <mem_init+0x1509>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01024d1:	50                   	push   %eax
f01024d2:	68 84 46 10 f0       	push   $0xf0104684
f01024d7:	6a 56                	push   $0x56
f01024d9:	68 15 4e 10 f0       	push   $0xf0104e15
f01024de:	e8 bd db ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f01024e3:	83 ec 04             	sub    $0x4,%esp
f01024e6:	68 00 10 00 00       	push   $0x1000
f01024eb:	6a 01                	push   $0x1
f01024ed:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01024f2:	50                   	push   %eax
f01024f3:	e8 9e 17 00 00       	call   f0103c96 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01024f8:	89 f0                	mov    %esi,%eax
f01024fa:	2b 05 4c 7c 17 f0    	sub    0xf0177c4c,%eax
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
f010250e:	3b 15 44 7c 17 f0    	cmp    0xf0177c44,%edx
f0102514:	72 12                	jb     f0102528 <mem_init+0x154e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102516:	50                   	push   %eax
f0102517:	68 84 46 10 f0       	push   $0xf0104684
f010251c:	6a 56                	push   $0x56
f010251e:	68 15 4e 10 f0       	push   $0xf0104e15
f0102523:	e8 78 db ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102528:	83 ec 04             	sub    $0x4,%esp
f010252b:	68 00 10 00 00       	push   $0x1000
f0102530:	6a 02                	push   $0x2
f0102532:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102537:	50                   	push   %eax
f0102538:	e8 59 17 00 00       	call   f0103c96 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f010253d:	6a 02                	push   $0x2
f010253f:	68 00 10 00 00       	push   $0x1000
f0102544:	57                   	push   %edi
f0102545:	ff 35 48 7c 17 f0    	pushl  0xf0177c48
f010254b:	e8 24 ea ff ff       	call   f0100f74 <page_insert>
	assert(pp1->pp_ref == 1);
f0102550:	83 c4 20             	add    $0x20,%esp
f0102553:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102558:	74 19                	je     f0102573 <mem_init+0x1599>
f010255a:	68 d7 4f 10 f0       	push   $0xf0104fd7
f010255f:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0102564:	68 db 03 00 00       	push   $0x3db
f0102569:	68 09 4e 10 f0       	push   $0xf0104e09
f010256e:	e8 2d db ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102573:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f010257a:	01 01 01 
f010257d:	74 19                	je     f0102598 <mem_init+0x15be>
f010257f:	68 6c 4d 10 f0       	push   $0xf0104d6c
f0102584:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0102589:	68 dc 03 00 00       	push   $0x3dc
f010258e:	68 09 4e 10 f0       	push   $0xf0104e09
f0102593:	e8 08 db ff ff       	call   f01000a0 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102598:	6a 02                	push   $0x2
f010259a:	68 00 10 00 00       	push   $0x1000
f010259f:	56                   	push   %esi
f01025a0:	ff 35 48 7c 17 f0    	pushl  0xf0177c48
f01025a6:	e8 c9 e9 ff ff       	call   f0100f74 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f01025ab:	83 c4 10             	add    $0x10,%esp
f01025ae:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f01025b5:	02 02 02 
f01025b8:	74 19                	je     f01025d3 <mem_init+0x15f9>
f01025ba:	68 90 4d 10 f0       	push   $0xf0104d90
f01025bf:	68 2f 4e 10 f0       	push   $0xf0104e2f
f01025c4:	68 de 03 00 00       	push   $0x3de
f01025c9:	68 09 4e 10 f0       	push   $0xf0104e09
f01025ce:	e8 cd da ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f01025d3:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01025d8:	74 19                	je     f01025f3 <mem_init+0x1619>
f01025da:	68 f9 4f 10 f0       	push   $0xf0104ff9
f01025df:	68 2f 4e 10 f0       	push   $0xf0104e2f
f01025e4:	68 df 03 00 00       	push   $0x3df
f01025e9:	68 09 4e 10 f0       	push   $0xf0104e09
f01025ee:	e8 ad da ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f01025f3:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f01025f8:	74 19                	je     f0102613 <mem_init+0x1639>
f01025fa:	68 63 50 10 f0       	push   $0xf0105063
f01025ff:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0102604:	68 e0 03 00 00       	push   $0x3e0
f0102609:	68 09 4e 10 f0       	push   $0xf0104e09
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
f010261f:	2b 05 4c 7c 17 f0    	sub    0xf0177c4c,%eax
f0102625:	c1 f8 03             	sar    $0x3,%eax
f0102628:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010262b:	89 c2                	mov    %eax,%edx
f010262d:	c1 ea 0c             	shr    $0xc,%edx
f0102630:	3b 15 44 7c 17 f0    	cmp    0xf0177c44,%edx
f0102636:	72 12                	jb     f010264a <mem_init+0x1670>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102638:	50                   	push   %eax
f0102639:	68 84 46 10 f0       	push   $0xf0104684
f010263e:	6a 56                	push   $0x56
f0102640:	68 15 4e 10 f0       	push   $0xf0104e15
f0102645:	e8 56 da ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f010264a:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102651:	03 03 03 
f0102654:	74 19                	je     f010266f <mem_init+0x1695>
f0102656:	68 b4 4d 10 f0       	push   $0xf0104db4
f010265b:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0102660:	68 e2 03 00 00       	push   $0x3e2
f0102665:	68 09 4e 10 f0       	push   $0xf0104e09
f010266a:	e8 31 da ff ff       	call   f01000a0 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f010266f:	83 ec 08             	sub    $0x8,%esp
f0102672:	68 00 10 00 00       	push   $0x1000
f0102677:	ff 35 48 7c 17 f0    	pushl  0xf0177c48
f010267d:	e8 af e8 ff ff       	call   f0100f31 <page_remove>
	assert(pp2->pp_ref == 0);
f0102682:	83 c4 10             	add    $0x10,%esp
f0102685:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010268a:	74 19                	je     f01026a5 <mem_init+0x16cb>
f010268c:	68 31 50 10 f0       	push   $0xf0105031
f0102691:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0102696:	68 e4 03 00 00       	push   $0x3e4
f010269b:	68 09 4e 10 f0       	push   $0xf0104e09
f01026a0:	e8 fb d9 ff ff       	call   f01000a0 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01026a5:	8b 0d 48 7c 17 f0    	mov    0xf0177c48,%ecx
f01026ab:	8b 11                	mov    (%ecx),%edx
f01026ad:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01026b3:	89 d8                	mov    %ebx,%eax
f01026b5:	2b 05 4c 7c 17 f0    	sub    0xf0177c4c,%eax
f01026bb:	c1 f8 03             	sar    $0x3,%eax
f01026be:	c1 e0 0c             	shl    $0xc,%eax
f01026c1:	39 c2                	cmp    %eax,%edx
f01026c3:	74 19                	je     f01026de <mem_init+0x1704>
f01026c5:	68 c4 48 10 f0       	push   $0xf01048c4
f01026ca:	68 2f 4e 10 f0       	push   $0xf0104e2f
f01026cf:	68 e7 03 00 00       	push   $0x3e7
f01026d4:	68 09 4e 10 f0       	push   $0xf0104e09
f01026d9:	e8 c2 d9 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f01026de:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f01026e4:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01026e9:	74 19                	je     f0102704 <mem_init+0x172a>
f01026eb:	68 e8 4f 10 f0       	push   $0xf0104fe8
f01026f0:	68 2f 4e 10 f0       	push   $0xf0104e2f
f01026f5:	68 e9 03 00 00       	push   $0x3e9
f01026fa:	68 09 4e 10 f0       	push   $0xf0104e09
f01026ff:	e8 9c d9 ff ff       	call   f01000a0 <_panic>
	pp0->pp_ref = 0;
f0102704:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f010270a:	83 ec 0c             	sub    $0xc,%esp
f010270d:	53                   	push   %ebx
f010270e:	e8 5c e6 ff ff       	call   f0100d6f <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102713:	c7 04 24 e0 4d 10 f0 	movl   $0xf0104de0,(%esp)
f010271a:	e8 d3 06 00 00       	call   f0102df2 <cprintf>
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
	// LAB 3: Your code here.

	return 0;
}
f0102738:	b8 00 00 00 00       	mov    $0x0,%eax
f010273d:	5d                   	pop    %ebp
f010273e:	c3                   	ret    

f010273f <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f010273f:	55                   	push   %ebp
f0102740:	89 e5                	mov    %esp,%ebp
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
		cprintf("[%08x] user_mem_check assertion failure for "
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
	}
}
f0102742:	5d                   	pop    %ebp
f0102743:	c3                   	ret    

f0102744 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0102744:	55                   	push   %ebp
f0102745:	89 e5                	mov    %esp,%ebp
f0102747:	57                   	push   %edi
f0102748:	56                   	push   %esi
f0102749:	53                   	push   %ebx
f010274a:	83 ec 0c             	sub    $0xc,%esp
f010274d:	89 c7                	mov    %eax,%edi
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	
	void *start = ROUNDDOWN(va,PGSIZE);
f010274f:	89 d3                	mov    %edx,%ebx
f0102751:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	void *end = ROUNDUP(va + len, PGSIZE);
f0102757:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f010275e:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	
	for(; start < end; start = start + PGSIZE)
f0102764:	eb 3d                	jmp    f01027a3 <region_alloc+0x5f>
	{
		struct PageInfo *p = page_alloc(!ALLOC_ZERO);
f0102766:	83 ec 0c             	sub    $0xc,%esp
f0102769:	6a 00                	push   $0x0
f010276b:	e8 8f e5 ff ff       	call   f0100cff <page_alloc>
		if(!p)
f0102770:	83 c4 10             	add    $0x10,%esp
f0102773:	85 c0                	test   %eax,%eax
f0102775:	75 17                	jne    f010278e <region_alloc+0x4a>
			panic("Allocation attempt failed");
f0102777:	83 ec 04             	sub    $0x4,%esp
f010277a:	68 ec 50 10 f0       	push   $0xf01050ec
f010277f:	68 21 01 00 00       	push   $0x121
f0102784:	68 06 51 10 f0       	push   $0xf0105106
f0102789:	e8 12 d9 ff ff       	call   f01000a0 <_panic>
		page_insert(e->env_pgdir, p, start, PTE_W|PTE_U);		
f010278e:	6a 06                	push   $0x6
f0102790:	53                   	push   %ebx
f0102791:	50                   	push   %eax
f0102792:	ff 77 5c             	pushl  0x5c(%edi)
f0102795:	e8 da e7 ff ff       	call   f0100f74 <page_insert>
	//   (Watch out for corner-cases!)
	
	void *start = ROUNDDOWN(va,PGSIZE);
	void *end = ROUNDUP(va + len, PGSIZE);
	
	for(; start < end; start = start + PGSIZE)
f010279a:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01027a0:	83 c4 10             	add    $0x10,%esp
f01027a3:	39 f3                	cmp    %esi,%ebx
f01027a5:	72 bf                	jb     f0102766 <region_alloc+0x22>
		struct PageInfo *p = page_alloc(!ALLOC_ZERO);
		if(!p)
			panic("Allocation attempt failed");
		page_insert(e->env_pgdir, p, start, PTE_W|PTE_U);		
	}
}
f01027a7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01027aa:	5b                   	pop    %ebx
f01027ab:	5e                   	pop    %esi
f01027ac:	5f                   	pop    %edi
f01027ad:	5d                   	pop    %ebp
f01027ae:	c3                   	ret    

f01027af <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f01027af:	55                   	push   %ebp
f01027b0:	89 e5                	mov    %esp,%ebp
f01027b2:	8b 55 08             	mov    0x8(%ebp),%edx
f01027b5:	8b 4d 10             	mov    0x10(%ebp),%ecx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f01027b8:	85 d2                	test   %edx,%edx
f01027ba:	75 11                	jne    f01027cd <envid2env+0x1e>
		*env_store = curenv;
f01027bc:	a1 84 6f 17 f0       	mov    0xf0176f84,%eax
f01027c1:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01027c4:	89 01                	mov    %eax,(%ecx)
		return 0;
f01027c6:	b8 00 00 00 00       	mov    $0x0,%eax
f01027cb:	eb 5e                	jmp    f010282b <envid2env+0x7c>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f01027cd:	89 d0                	mov    %edx,%eax
f01027cf:	25 ff 03 00 00       	and    $0x3ff,%eax
f01027d4:	8d 04 40             	lea    (%eax,%eax,2),%eax
f01027d7:	c1 e0 05             	shl    $0x5,%eax
f01027da:	03 05 88 6f 17 f0    	add    0xf0176f88,%eax
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f01027e0:	83 78 54 00          	cmpl   $0x0,0x54(%eax)
f01027e4:	74 05                	je     f01027eb <envid2env+0x3c>
f01027e6:	3b 50 48             	cmp    0x48(%eax),%edx
f01027e9:	74 10                	je     f01027fb <envid2env+0x4c>
		*env_store = 0;
f01027eb:	8b 45 0c             	mov    0xc(%ebp),%eax
f01027ee:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f01027f4:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01027f9:	eb 30                	jmp    f010282b <envid2env+0x7c>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f01027fb:	84 c9                	test   %cl,%cl
f01027fd:	74 22                	je     f0102821 <envid2env+0x72>
f01027ff:	8b 15 84 6f 17 f0    	mov    0xf0176f84,%edx
f0102805:	39 d0                	cmp    %edx,%eax
f0102807:	74 18                	je     f0102821 <envid2env+0x72>
f0102809:	8b 4a 48             	mov    0x48(%edx),%ecx
f010280c:	39 48 4c             	cmp    %ecx,0x4c(%eax)
f010280f:	74 10                	je     f0102821 <envid2env+0x72>
		*env_store = 0;
f0102811:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102814:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f010281a:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f010281f:	eb 0a                	jmp    f010282b <envid2env+0x7c>
	}

	*env_store = e;
f0102821:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102824:	89 01                	mov    %eax,(%ecx)
	return 0;
f0102826:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010282b:	5d                   	pop    %ebp
f010282c:	c3                   	ret    

f010282d <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f010282d:	55                   	push   %ebp
f010282e:	89 e5                	mov    %esp,%ebp
}

static __inline void
lgdt(void *p)
{
	__asm __volatile("lgdt (%0)" : : "r" (p));
f0102830:	b8 00 a3 11 f0       	mov    $0xf011a300,%eax
f0102835:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f0102838:	b8 23 00 00 00       	mov    $0x23,%eax
f010283d:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f010283f:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f0102841:	b8 10 00 00 00       	mov    $0x10,%eax
f0102846:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f0102848:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f010284a:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));
f010284c:	ea 53 28 10 f0 08 00 	ljmp   $0x8,$0xf0102853
}

static __inline void
lldt(uint16_t sel)
{
	__asm __volatile("lldt %0" : : "r" (sel));
f0102853:	b8 00 00 00 00       	mov    $0x0,%eax
f0102858:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f010285b:	5d                   	pop    %ebp
f010285c:	c3                   	ret    

f010285d <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f010285d:	55                   	push   %ebp
f010285e:	89 e5                	mov    %esp,%ebp
f0102860:	56                   	push   %esi
f0102861:	53                   	push   %ebx
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	for (i = NENV - 1; i >= 0; --i) {
		envs[i].env_status=ENV_FREE;
f0102862:	8b 35 88 6f 17 f0    	mov    0xf0176f88,%esi
f0102868:	8b 15 8c 6f 17 f0    	mov    0xf0176f8c,%edx
f010286e:	8d 86 a0 7f 01 00    	lea    0x17fa0(%esi),%eax
f0102874:	8d 5e a0             	lea    -0x60(%esi),%ebx
f0102877:	89 c1                	mov    %eax,%ecx
f0102879:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
		envs[i].env_id = 0;
f0102880:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_link = env_free_list;
f0102887:	89 50 44             	mov    %edx,0x44(%eax)
f010288a:	83 e8 60             	sub    $0x60,%eax
		env_free_list = &envs[i];
f010288d:	89 ca                	mov    %ecx,%edx
env_init(void)
{
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	for (i = NENV - 1; i >= 0; --i) {
f010288f:	39 d8                	cmp    %ebx,%eax
f0102891:	75 e4                	jne    f0102877 <env_init+0x1a>
f0102893:	89 35 8c 6f 17 f0    	mov    %esi,0xf0176f8c
		envs[i].env_link = env_free_list;
		env_free_list = &envs[i];
	}
	
	// Per-CPU part of the initialization
	env_init_percpu();
f0102899:	e8 8f ff ff ff       	call   f010282d <env_init_percpu>
}
f010289e:	5b                   	pop    %ebx
f010289f:	5e                   	pop    %esi
f01028a0:	5d                   	pop    %ebp
f01028a1:	c3                   	ret    

f01028a2 <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f01028a2:	55                   	push   %ebp
f01028a3:	89 e5                	mov    %esp,%ebp
f01028a5:	53                   	push   %ebx
f01028a6:	83 ec 04             	sub    $0x4,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f01028a9:	8b 1d 8c 6f 17 f0    	mov    0xf0176f8c,%ebx
f01028af:	85 db                	test   %ebx,%ebx
f01028b1:	0f 84 43 01 00 00    	je     f01029fa <env_alloc+0x158>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f01028b7:	83 ec 0c             	sub    $0xc,%esp
f01028ba:	6a 01                	push   $0x1
f01028bc:	e8 3e e4 ff ff       	call   f0100cff <page_alloc>
f01028c1:	83 c4 10             	add    $0x10,%esp
f01028c4:	85 c0                	test   %eax,%eax
f01028c6:	0f 84 35 01 00 00    	je     f0102a01 <env_alloc+0x15f>
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.

	p->pp_ref++;
f01028cc:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01028d1:	2b 05 4c 7c 17 f0    	sub    0xf0177c4c,%eax
f01028d7:	c1 f8 03             	sar    $0x3,%eax
f01028da:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01028dd:	89 c2                	mov    %eax,%edx
f01028df:	c1 ea 0c             	shr    $0xc,%edx
f01028e2:	3b 15 44 7c 17 f0    	cmp    0xf0177c44,%edx
f01028e8:	72 12                	jb     f01028fc <env_alloc+0x5a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01028ea:	50                   	push   %eax
f01028eb:	68 84 46 10 f0       	push   $0xf0104684
f01028f0:	6a 56                	push   $0x56
f01028f2:	68 15 4e 10 f0       	push   $0xf0104e15
f01028f7:	e8 a4 d7 ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f01028fc:	2d 00 00 00 10       	sub    $0x10000000,%eax
	e->env_pgdir = (pde_t *) page2kva(p);
f0102901:	89 43 5c             	mov    %eax,0x5c(%ebx)
	memcpy(e->env_pgdir, kern_pgdir, PGSIZE);
f0102904:	83 ec 04             	sub    $0x4,%esp
f0102907:	68 00 10 00 00       	push   $0x1000
f010290c:	ff 35 48 7c 17 f0    	pushl  0xf0177c48
f0102912:	50                   	push   %eax
f0102913:	e8 33 14 00 00       	call   f0103d4b <memcpy>

	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0102918:	8b 43 5c             	mov    0x5c(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010291b:	83 c4 10             	add    $0x10,%esp
f010291e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102923:	77 15                	ja     f010293a <env_alloc+0x98>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102925:	50                   	push   %eax
f0102926:	68 c8 47 10 f0       	push   $0xf01047c8
f010292b:	68 c4 00 00 00       	push   $0xc4
f0102930:	68 06 51 10 f0       	push   $0xf0105106
f0102935:	e8 66 d7 ff ff       	call   f01000a0 <_panic>
f010293a:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0102940:	83 ca 05             	or     $0x5,%edx
f0102943:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f0102949:	8b 43 48             	mov    0x48(%ebx),%eax
f010294c:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f0102951:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0102956:	ba 00 10 00 00       	mov    $0x1000,%edx
f010295b:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f010295e:	89 da                	mov    %ebx,%edx
f0102960:	2b 15 88 6f 17 f0    	sub    0xf0176f88,%edx
f0102966:	c1 fa 05             	sar    $0x5,%edx
f0102969:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f010296f:	09 d0                	or     %edx,%eax
f0102971:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0102974:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102977:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f010297a:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0102981:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f0102988:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f010298f:	83 ec 04             	sub    $0x4,%esp
f0102992:	6a 44                	push   $0x44
f0102994:	6a 00                	push   $0x0
f0102996:	53                   	push   %ebx
f0102997:	e8 fa 12 00 00       	call   f0103c96 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f010299c:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f01029a2:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f01029a8:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f01029ae:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f01029b5:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	env_free_list = e->env_link;
f01029bb:	8b 43 44             	mov    0x44(%ebx),%eax
f01029be:	a3 8c 6f 17 f0       	mov    %eax,0xf0176f8c
	*newenv_store = e;
f01029c3:	8b 45 08             	mov    0x8(%ebp),%eax
f01029c6:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f01029c8:	8b 53 48             	mov    0x48(%ebx),%edx
f01029cb:	a1 84 6f 17 f0       	mov    0xf0176f84,%eax
f01029d0:	83 c4 10             	add    $0x10,%esp
f01029d3:	85 c0                	test   %eax,%eax
f01029d5:	74 05                	je     f01029dc <env_alloc+0x13a>
f01029d7:	8b 40 48             	mov    0x48(%eax),%eax
f01029da:	eb 05                	jmp    f01029e1 <env_alloc+0x13f>
f01029dc:	b8 00 00 00 00       	mov    $0x0,%eax
f01029e1:	83 ec 04             	sub    $0x4,%esp
f01029e4:	52                   	push   %edx
f01029e5:	50                   	push   %eax
f01029e6:	68 11 51 10 f0       	push   $0xf0105111
f01029eb:	e8 02 04 00 00       	call   f0102df2 <cprintf>
	return 0;
f01029f0:	83 c4 10             	add    $0x10,%esp
f01029f3:	b8 00 00 00 00       	mov    $0x0,%eax
f01029f8:	eb 0c                	jmp    f0102a06 <env_alloc+0x164>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f01029fa:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f01029ff:	eb 05                	jmp    f0102a06 <env_alloc+0x164>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0102a01:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0102a06:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102a09:	c9                   	leave  
f0102a0a:	c3                   	ret    

f0102a0b <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0102a0b:	55                   	push   %ebp
f0102a0c:	89 e5                	mov    %esp,%ebp
f0102a0e:	57                   	push   %edi
f0102a0f:	56                   	push   %esi
f0102a10:	53                   	push   %ebx
f0102a11:	83 ec 34             	sub    $0x34,%esp
f0102a14:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	
	struct Env *e;
	env_alloc(&e, 0);
f0102a17:	6a 00                	push   $0x0
f0102a19:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0102a1c:	50                   	push   %eax
f0102a1d:	e8 80 fe ff ff       	call   f01028a2 <env_alloc>
	load_icode(e, binary);
f0102a22:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102a25:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	struct Elf *ELFHDR = (struct Elf *) binary;
	struct Proghdr *ph, *eph;
	
	
	// is this a valid ELF?
	if (ELFHDR->e_magic != ELF_MAGIC)
f0102a28:	83 c4 10             	add    $0x10,%esp
f0102a2b:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f0102a31:	74 17                	je     f0102a4a <env_create+0x3f>
		panic("Not a valid ELF Header");
f0102a33:	83 ec 04             	sub    $0x4,%esp
f0102a36:	68 26 51 10 f0       	push   $0xf0105126
f0102a3b:	68 63 01 00 00       	push   $0x163
f0102a40:	68 06 51 10 f0       	push   $0xf0105106
f0102a45:	e8 56 d6 ff ff       	call   f01000a0 <_panic>
		
	ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);
f0102a4a:	89 fb                	mov    %edi,%ebx
f0102a4c:	03 5f 1c             	add    0x1c(%edi),%ebx
	eph = ph + ELFHDR->e_phnum;
f0102a4f:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f0102a53:	c1 e6 05             	shl    $0x5,%esi
f0102a56:	01 de                	add    %ebx,%esi
	
	lcr3(PADDR(e->env_pgdir));
f0102a58:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102a5b:	8b 40 5c             	mov    0x5c(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102a5e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102a63:	77 15                	ja     f0102a7a <env_create+0x6f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102a65:	50                   	push   %eax
f0102a66:	68 c8 47 10 f0       	push   $0xf01047c8
f0102a6b:	68 68 01 00 00       	push   $0x168
f0102a70:	68 06 51 10 f0       	push   $0xf0105106
f0102a75:	e8 26 d6 ff ff       	call   f01000a0 <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102a7a:	05 00 00 00 10       	add    $0x10000000,%eax
f0102a7f:	0f 22 d8             	mov    %eax,%cr3
f0102a82:	eb 46                	jmp    f0102aca <env_create+0xbf>
	
	for (; ph < eph; ph++)
	{
		if(ph->p_type == ELF_PROG_LOAD)
f0102a84:	83 3b 01             	cmpl   $0x1,(%ebx)
f0102a87:	75 3e                	jne    f0102ac7 <env_create+0xbc>
		{
			region_alloc(e, (void *)ph->p_va, ph->p_memsz);
f0102a89:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0102a8c:	8b 53 08             	mov    0x8(%ebx),%edx
f0102a8f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102a92:	e8 ad fc ff ff       	call   f0102744 <region_alloc>
			memcpy((void*)ph->p_va, (void*)binary + ph->p_offset, ph->p_filesz);
f0102a97:	83 ec 04             	sub    $0x4,%esp
f0102a9a:	ff 73 10             	pushl  0x10(%ebx)
f0102a9d:	89 f8                	mov    %edi,%eax
f0102a9f:	03 43 04             	add    0x4(%ebx),%eax
f0102aa2:	50                   	push   %eax
f0102aa3:	ff 73 08             	pushl  0x8(%ebx)
f0102aa6:	e8 a0 12 00 00       	call   f0103d4b <memcpy>
			memset((void *)(binary + ph->p_offset + ph->p_filesz), 0, (uint32_t)ph->p_memsz - ph->p_filesz);
f0102aab:	8b 43 10             	mov    0x10(%ebx),%eax
f0102aae:	83 c4 0c             	add    $0xc,%esp
f0102ab1:	8b 53 14             	mov    0x14(%ebx),%edx
f0102ab4:	29 c2                	sub    %eax,%edx
f0102ab6:	52                   	push   %edx
f0102ab7:	6a 00                	push   $0x0
f0102ab9:	03 43 04             	add    0x4(%ebx),%eax
f0102abc:	01 f8                	add    %edi,%eax
f0102abe:	50                   	push   %eax
f0102abf:	e8 d2 11 00 00       	call   f0103c96 <memset>
f0102ac4:	83 c4 10             	add    $0x10,%esp
	ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);
	eph = ph + ELFHDR->e_phnum;
	
	lcr3(PADDR(e->env_pgdir));
	
	for (; ph < eph; ph++)
f0102ac7:	83 c3 20             	add    $0x20,%ebx
f0102aca:	39 de                	cmp    %ebx,%esi
f0102acc:	77 b6                	ja     f0102a84 <env_create+0x79>
			memset((void *)(binary + ph->p_offset + ph->p_filesz), 0, (uint32_t)ph->p_memsz - ph->p_filesz);
			
		}
	}

	lcr3(PADDR(kern_pgdir));
f0102ace:	a1 48 7c 17 f0       	mov    0xf0177c48,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102ad3:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102ad8:	77 15                	ja     f0102aef <env_create+0xe4>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102ada:	50                   	push   %eax
f0102adb:	68 c8 47 10 f0       	push   $0xf01047c8
f0102ae0:	68 75 01 00 00       	push   $0x175
f0102ae5:	68 06 51 10 f0       	push   $0xf0105106
f0102aea:	e8 b1 d5 ff ff       	call   f01000a0 <_panic>
f0102aef:	05 00 00 00 10       	add    $0x10000000,%eax
f0102af4:	0f 22 d8             	mov    %eax,%cr3
	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.
	region_alloc(e, (void *)USTACKTOP - PGSIZE, PGSIZE);
f0102af7:	b9 00 10 00 00       	mov    $0x1000,%ecx
f0102afc:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f0102b01:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0102b04:	89 f0                	mov    %esi,%eax
f0102b06:	e8 39 fc ff ff       	call   f0102744 <region_alloc>
	// LAB 3: Your code here.
	e->env_tf.tf_eip = ELFHDR->e_entry;
f0102b0b:	8b 47 18             	mov    0x18(%edi),%eax
f0102b0e:	89 46 30             	mov    %eax,0x30(%esi)
	// LAB 3: Your code here.
	
	struct Env *e;
	env_alloc(&e, 0);
	load_icode(e, binary);
}
f0102b11:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102b14:	5b                   	pop    %ebx
f0102b15:	5e                   	pop    %esi
f0102b16:	5f                   	pop    %edi
f0102b17:	5d                   	pop    %ebp
f0102b18:	c3                   	ret    

f0102b19 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0102b19:	55                   	push   %ebp
f0102b1a:	89 e5                	mov    %esp,%ebp
f0102b1c:	57                   	push   %edi
f0102b1d:	56                   	push   %esi
f0102b1e:	53                   	push   %ebx
f0102b1f:	83 ec 1c             	sub    $0x1c,%esp
f0102b22:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0102b25:	8b 15 84 6f 17 f0    	mov    0xf0176f84,%edx
f0102b2b:	39 fa                	cmp    %edi,%edx
f0102b2d:	75 29                	jne    f0102b58 <env_free+0x3f>
		lcr3(PADDR(kern_pgdir));
f0102b2f:	a1 48 7c 17 f0       	mov    0xf0177c48,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102b34:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102b39:	77 15                	ja     f0102b50 <env_free+0x37>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102b3b:	50                   	push   %eax
f0102b3c:	68 c8 47 10 f0       	push   $0xf01047c8
f0102b41:	68 9c 01 00 00       	push   $0x19c
f0102b46:	68 06 51 10 f0       	push   $0xf0105106
f0102b4b:	e8 50 d5 ff ff       	call   f01000a0 <_panic>
f0102b50:	05 00 00 00 10       	add    $0x10000000,%eax
f0102b55:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102b58:	8b 4f 48             	mov    0x48(%edi),%ecx
f0102b5b:	85 d2                	test   %edx,%edx
f0102b5d:	74 05                	je     f0102b64 <env_free+0x4b>
f0102b5f:	8b 42 48             	mov    0x48(%edx),%eax
f0102b62:	eb 05                	jmp    f0102b69 <env_free+0x50>
f0102b64:	b8 00 00 00 00       	mov    $0x0,%eax
f0102b69:	83 ec 04             	sub    $0x4,%esp
f0102b6c:	51                   	push   %ecx
f0102b6d:	50                   	push   %eax
f0102b6e:	68 3d 51 10 f0       	push   $0xf010513d
f0102b73:	e8 7a 02 00 00       	call   f0102df2 <cprintf>
f0102b78:	83 c4 10             	add    $0x10,%esp

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102b7b:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0102b82:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0102b85:	89 d0                	mov    %edx,%eax
f0102b87:	c1 e0 02             	shl    $0x2,%eax
f0102b8a:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0102b8d:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102b90:	8b 34 90             	mov    (%eax,%edx,4),%esi
f0102b93:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0102b99:	0f 84 a8 00 00 00    	je     f0102c47 <env_free+0x12e>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0102b9f:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102ba5:	89 f0                	mov    %esi,%eax
f0102ba7:	c1 e8 0c             	shr    $0xc,%eax
f0102baa:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102bad:	39 05 44 7c 17 f0    	cmp    %eax,0xf0177c44
f0102bb3:	77 15                	ja     f0102bca <env_free+0xb1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102bb5:	56                   	push   %esi
f0102bb6:	68 84 46 10 f0       	push   $0xf0104684
f0102bbb:	68 ab 01 00 00       	push   $0x1ab
f0102bc0:	68 06 51 10 f0       	push   $0xf0105106
f0102bc5:	e8 d6 d4 ff ff       	call   f01000a0 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102bca:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102bcd:	c1 e0 16             	shl    $0x16,%eax
f0102bd0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102bd3:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0102bd8:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0102bdf:	01 
f0102be0:	74 17                	je     f0102bf9 <env_free+0xe0>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102be2:	83 ec 08             	sub    $0x8,%esp
f0102be5:	89 d8                	mov    %ebx,%eax
f0102be7:	c1 e0 0c             	shl    $0xc,%eax
f0102bea:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0102bed:	50                   	push   %eax
f0102bee:	ff 77 5c             	pushl  0x5c(%edi)
f0102bf1:	e8 3b e3 ff ff       	call   f0100f31 <page_remove>
f0102bf6:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102bf9:	83 c3 01             	add    $0x1,%ebx
f0102bfc:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0102c02:	75 d4                	jne    f0102bd8 <env_free+0xbf>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0102c04:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102c07:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102c0a:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102c11:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102c14:	3b 05 44 7c 17 f0    	cmp    0xf0177c44,%eax
f0102c1a:	72 14                	jb     f0102c30 <env_free+0x117>
		panic("pa2page called with invalid pa");
f0102c1c:	83 ec 04             	sub    $0x4,%esp
f0102c1f:	68 6c 47 10 f0       	push   $0xf010476c
f0102c24:	6a 4f                	push   $0x4f
f0102c26:	68 15 4e 10 f0       	push   $0xf0104e15
f0102c2b:	e8 70 d4 ff ff       	call   f01000a0 <_panic>
		page_decref(pa2page(pa));
f0102c30:	83 ec 0c             	sub    $0xc,%esp
f0102c33:	a1 4c 7c 17 f0       	mov    0xf0177c4c,%eax
f0102c38:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102c3b:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f0102c3e:	50                   	push   %eax
f0102c3f:	e8 40 e1 ff ff       	call   f0100d84 <page_decref>
f0102c44:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102c47:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0102c4b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102c4e:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0102c53:	0f 85 29 ff ff ff    	jne    f0102b82 <env_free+0x69>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0102c59:	8b 47 5c             	mov    0x5c(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102c5c:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102c61:	77 15                	ja     f0102c78 <env_free+0x15f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102c63:	50                   	push   %eax
f0102c64:	68 c8 47 10 f0       	push   $0xf01047c8
f0102c69:	68 b9 01 00 00       	push   $0x1b9
f0102c6e:	68 06 51 10 f0       	push   $0xf0105106
f0102c73:	e8 28 d4 ff ff       	call   f01000a0 <_panic>
	e->env_pgdir = 0;
f0102c78:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102c7f:	05 00 00 00 10       	add    $0x10000000,%eax
f0102c84:	c1 e8 0c             	shr    $0xc,%eax
f0102c87:	3b 05 44 7c 17 f0    	cmp    0xf0177c44,%eax
f0102c8d:	72 14                	jb     f0102ca3 <env_free+0x18a>
		panic("pa2page called with invalid pa");
f0102c8f:	83 ec 04             	sub    $0x4,%esp
f0102c92:	68 6c 47 10 f0       	push   $0xf010476c
f0102c97:	6a 4f                	push   $0x4f
f0102c99:	68 15 4e 10 f0       	push   $0xf0104e15
f0102c9e:	e8 fd d3 ff ff       	call   f01000a0 <_panic>
	page_decref(pa2page(pa));
f0102ca3:	83 ec 0c             	sub    $0xc,%esp
f0102ca6:	8b 15 4c 7c 17 f0    	mov    0xf0177c4c,%edx
f0102cac:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0102caf:	50                   	push   %eax
f0102cb0:	e8 cf e0 ff ff       	call   f0100d84 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0102cb5:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0102cbc:	a1 8c 6f 17 f0       	mov    0xf0176f8c,%eax
f0102cc1:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0102cc4:	89 3d 8c 6f 17 f0    	mov    %edi,0xf0176f8c
}
f0102cca:	83 c4 10             	add    $0x10,%esp
f0102ccd:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102cd0:	5b                   	pop    %ebx
f0102cd1:	5e                   	pop    %esi
f0102cd2:	5f                   	pop    %edi
f0102cd3:	5d                   	pop    %ebp
f0102cd4:	c3                   	ret    

f0102cd5 <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f0102cd5:	55                   	push   %ebp
f0102cd6:	89 e5                	mov    %esp,%ebp
f0102cd8:	83 ec 14             	sub    $0x14,%esp
	env_free(e);
f0102cdb:	ff 75 08             	pushl  0x8(%ebp)
f0102cde:	e8 36 fe ff ff       	call   f0102b19 <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f0102ce3:	c7 04 24 60 51 10 f0 	movl   $0xf0105160,(%esp)
f0102cea:	e8 03 01 00 00       	call   f0102df2 <cprintf>
f0102cef:	83 c4 10             	add    $0x10,%esp
	while (1)
		monitor(NULL);
f0102cf2:	83 ec 0c             	sub    $0xc,%esp
f0102cf5:	6a 00                	push   $0x0
f0102cf7:	e8 af da ff ff       	call   f01007ab <monitor>
f0102cfc:	83 c4 10             	add    $0x10,%esp
f0102cff:	eb f1                	jmp    f0102cf2 <env_destroy+0x1d>

f0102d01 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0102d01:	55                   	push   %ebp
f0102d02:	89 e5                	mov    %esp,%ebp
f0102d04:	83 ec 0c             	sub    $0xc,%esp
	__asm __volatile("movl %0,%%esp\n"
f0102d07:	8b 65 08             	mov    0x8(%ebp),%esp
f0102d0a:	61                   	popa   
f0102d0b:	07                   	pop    %es
f0102d0c:	1f                   	pop    %ds
f0102d0d:	83 c4 08             	add    $0x8,%esp
f0102d10:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0102d11:	68 53 51 10 f0       	push   $0xf0105153
f0102d16:	68 e1 01 00 00       	push   $0x1e1
f0102d1b:	68 06 51 10 f0       	push   $0xf0105106
f0102d20:	e8 7b d3 ff ff       	call   f01000a0 <_panic>

f0102d25 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0102d25:	55                   	push   %ebp
f0102d26:	89 e5                	mov    %esp,%ebp
f0102d28:	83 ec 08             	sub    $0x8,%esp
f0102d2b:	8b 45 08             	mov    0x8(%ebp),%eax
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.
	//cprintf("curenv: %x, e: %x\n", curenv, e);
	if ((curenv !=NULL) && (curenv->env_status == ENV_RUNNING))
f0102d2e:	8b 15 84 6f 17 f0    	mov    0xf0176f84,%edx
f0102d34:	85 d2                	test   %edx,%edx
f0102d36:	74 0d                	je     f0102d45 <env_run+0x20>
f0102d38:	83 7a 54 03          	cmpl   $0x3,0x54(%edx)
f0102d3c:	75 07                	jne    f0102d45 <env_run+0x20>
		curenv->env_status = ENV_RUNNABLE;
f0102d3e:	c7 42 54 02 00 00 00 	movl   $0x2,0x54(%edx)
	if(curenv != e)
f0102d45:	39 c2                	cmp    %eax,%edx
f0102d47:	74 39                	je     f0102d82 <env_run+0x5d>
	{
		curenv = e;
f0102d49:	a3 84 6f 17 f0       	mov    %eax,0xf0176f84
		e->env_status = ENV_RUNNING;
f0102d4e:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
		e->env_runs++;
f0102d55:	83 40 58 01          	addl   $0x1,0x58(%eax)
		lcr3(PADDR(e->env_pgdir));
f0102d59:	8b 50 5c             	mov    0x5c(%eax),%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102d5c:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0102d62:	77 15                	ja     f0102d79 <env_run+0x54>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102d64:	52                   	push   %edx
f0102d65:	68 c8 47 10 f0       	push   $0xf01047c8
f0102d6a:	68 07 02 00 00       	push   $0x207
f0102d6f:	68 06 51 10 f0       	push   $0xf0105106
f0102d74:	e8 27 d3 ff ff       	call   f01000a0 <_panic>
f0102d79:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f0102d7f:	0f 22 da             	mov    %edx,%cr3
		
	}
	
	env_pop_tf(&e->env_tf);
f0102d82:	83 ec 0c             	sub    $0xc,%esp
f0102d85:	50                   	push   %eax
f0102d86:	e8 76 ff ff ff       	call   f0102d01 <env_pop_tf>

f0102d8b <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102d8b:	55                   	push   %ebp
f0102d8c:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102d8e:	ba 70 00 00 00       	mov    $0x70,%edx
f0102d93:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d96:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102d97:	ba 71 00 00 00       	mov    $0x71,%edx
f0102d9c:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102d9d:	0f b6 c0             	movzbl %al,%eax
}
f0102da0:	5d                   	pop    %ebp
f0102da1:	c3                   	ret    

f0102da2 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102da2:	55                   	push   %ebp
f0102da3:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102da5:	ba 70 00 00 00       	mov    $0x70,%edx
f0102daa:	8b 45 08             	mov    0x8(%ebp),%eax
f0102dad:	ee                   	out    %al,(%dx)
f0102dae:	ba 71 00 00 00       	mov    $0x71,%edx
f0102db3:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102db6:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102db7:	5d                   	pop    %ebp
f0102db8:	c3                   	ret    

f0102db9 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102db9:	55                   	push   %ebp
f0102dba:	89 e5                	mov    %esp,%ebp
f0102dbc:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0102dbf:	ff 75 08             	pushl  0x8(%ebp)
f0102dc2:	e8 40 d8 ff ff       	call   f0100607 <cputchar>
	*cnt++;
}
f0102dc7:	83 c4 10             	add    $0x10,%esp
f0102dca:	c9                   	leave  
f0102dcb:	c3                   	ret    

f0102dcc <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102dcc:	55                   	push   %ebp
f0102dcd:	89 e5                	mov    %esp,%ebp
f0102dcf:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0102dd2:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102dd9:	ff 75 0c             	pushl  0xc(%ebp)
f0102ddc:	ff 75 08             	pushl  0x8(%ebp)
f0102ddf:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102de2:	50                   	push   %eax
f0102de3:	68 b9 2d 10 f0       	push   $0xf0102db9
f0102de8:	e8 1d 08 00 00       	call   f010360a <vprintfmt>
	return cnt;
}
f0102ded:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102df0:	c9                   	leave  
f0102df1:	c3                   	ret    

f0102df2 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102df2:	55                   	push   %ebp
f0102df3:	89 e5                	mov    %esp,%ebp
f0102df5:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102df8:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102dfb:	50                   	push   %eax
f0102dfc:	ff 75 08             	pushl  0x8(%ebp)
f0102dff:	e8 c8 ff ff ff       	call   f0102dcc <vcprintf>
	va_end(ap);

	return cnt;
}
f0102e04:	c9                   	leave  
f0102e05:	c3                   	ret    

f0102e06 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0102e06:	55                   	push   %ebp
f0102e07:	89 e5                	mov    %esp,%ebp
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f0102e09:	b8 c0 77 17 f0       	mov    $0xf01777c0,%eax
f0102e0e:	c7 05 c4 77 17 f0 00 	movl   $0xf0000000,0xf01777c4
f0102e15:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f0102e18:	66 c7 05 c8 77 17 f0 	movw   $0x10,0xf01777c8
f0102e1f:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f0102e21:	66 c7 05 48 a3 11 f0 	movw   $0x67,0xf011a348
f0102e28:	67 00 
f0102e2a:	66 a3 4a a3 11 f0    	mov    %ax,0xf011a34a
f0102e30:	89 c2                	mov    %eax,%edx
f0102e32:	c1 ea 10             	shr    $0x10,%edx
f0102e35:	88 15 4c a3 11 f0    	mov    %dl,0xf011a34c
f0102e3b:	c6 05 4e a3 11 f0 40 	movb   $0x40,0xf011a34e
f0102e42:	c1 e8 18             	shr    $0x18,%eax
f0102e45:	a2 4f a3 11 f0       	mov    %al,0xf011a34f
					sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f0102e4a:	c6 05 4d a3 11 f0 89 	movb   $0x89,0xf011a34d
}

static __inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
f0102e51:	b8 28 00 00 00       	mov    $0x28,%eax
f0102e56:	0f 00 d8             	ltr    %ax
}

static __inline void
lidt(void *p)
{
	__asm __volatile("lidt (%0)" : : "r" (p));
f0102e59:	b8 50 a3 11 f0       	mov    $0xf011a350,%eax
f0102e5e:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f0102e61:	5d                   	pop    %ebp
f0102e62:	c3                   	ret    

f0102e63 <trap_init>:
}


void
trap_init(void)
{
f0102e63:	55                   	push   %ebp
f0102e64:	89 e5                	mov    %esp,%ebp
	extern struct Segdesc gdt[];

	// LAB 3: Your code here.

	// Per-CPU setup 
	trap_init_percpu();
f0102e66:	e8 9b ff ff ff       	call   f0102e06 <trap_init_percpu>
}
f0102e6b:	5d                   	pop    %ebp
f0102e6c:	c3                   	ret    

f0102e6d <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0102e6d:	55                   	push   %ebp
f0102e6e:	89 e5                	mov    %esp,%ebp
f0102e70:	53                   	push   %ebx
f0102e71:	83 ec 0c             	sub    $0xc,%esp
f0102e74:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0102e77:	ff 33                	pushl  (%ebx)
f0102e79:	68 96 51 10 f0       	push   $0xf0105196
f0102e7e:	e8 6f ff ff ff       	call   f0102df2 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0102e83:	83 c4 08             	add    $0x8,%esp
f0102e86:	ff 73 04             	pushl  0x4(%ebx)
f0102e89:	68 a5 51 10 f0       	push   $0xf01051a5
f0102e8e:	e8 5f ff ff ff       	call   f0102df2 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0102e93:	83 c4 08             	add    $0x8,%esp
f0102e96:	ff 73 08             	pushl  0x8(%ebx)
f0102e99:	68 b4 51 10 f0       	push   $0xf01051b4
f0102e9e:	e8 4f ff ff ff       	call   f0102df2 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0102ea3:	83 c4 08             	add    $0x8,%esp
f0102ea6:	ff 73 0c             	pushl  0xc(%ebx)
f0102ea9:	68 c3 51 10 f0       	push   $0xf01051c3
f0102eae:	e8 3f ff ff ff       	call   f0102df2 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0102eb3:	83 c4 08             	add    $0x8,%esp
f0102eb6:	ff 73 10             	pushl  0x10(%ebx)
f0102eb9:	68 d2 51 10 f0       	push   $0xf01051d2
f0102ebe:	e8 2f ff ff ff       	call   f0102df2 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0102ec3:	83 c4 08             	add    $0x8,%esp
f0102ec6:	ff 73 14             	pushl  0x14(%ebx)
f0102ec9:	68 e1 51 10 f0       	push   $0xf01051e1
f0102ece:	e8 1f ff ff ff       	call   f0102df2 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0102ed3:	83 c4 08             	add    $0x8,%esp
f0102ed6:	ff 73 18             	pushl  0x18(%ebx)
f0102ed9:	68 f0 51 10 f0       	push   $0xf01051f0
f0102ede:	e8 0f ff ff ff       	call   f0102df2 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0102ee3:	83 c4 08             	add    $0x8,%esp
f0102ee6:	ff 73 1c             	pushl  0x1c(%ebx)
f0102ee9:	68 ff 51 10 f0       	push   $0xf01051ff
f0102eee:	e8 ff fe ff ff       	call   f0102df2 <cprintf>
}
f0102ef3:	83 c4 10             	add    $0x10,%esp
f0102ef6:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102ef9:	c9                   	leave  
f0102efa:	c3                   	ret    

f0102efb <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f0102efb:	55                   	push   %ebp
f0102efc:	89 e5                	mov    %esp,%ebp
f0102efe:	56                   	push   %esi
f0102eff:	53                   	push   %ebx
f0102f00:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p\n", tf);
f0102f03:	83 ec 08             	sub    $0x8,%esp
f0102f06:	53                   	push   %ebx
f0102f07:	68 35 53 10 f0       	push   $0xf0105335
f0102f0c:	e8 e1 fe ff ff       	call   f0102df2 <cprintf>
	print_regs(&tf->tf_regs);
f0102f11:	89 1c 24             	mov    %ebx,(%esp)
f0102f14:	e8 54 ff ff ff       	call   f0102e6d <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0102f19:	83 c4 08             	add    $0x8,%esp
f0102f1c:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0102f20:	50                   	push   %eax
f0102f21:	68 50 52 10 f0       	push   $0xf0105250
f0102f26:	e8 c7 fe ff ff       	call   f0102df2 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0102f2b:	83 c4 08             	add    $0x8,%esp
f0102f2e:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0102f32:	50                   	push   %eax
f0102f33:	68 63 52 10 f0       	push   $0xf0105263
f0102f38:	e8 b5 fe ff ff       	call   f0102df2 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0102f3d:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
f0102f40:	83 c4 10             	add    $0x10,%esp
f0102f43:	83 f8 13             	cmp    $0x13,%eax
f0102f46:	77 09                	ja     f0102f51 <print_trapframe+0x56>
		return excnames[trapno];
f0102f48:	8b 14 85 00 55 10 f0 	mov    -0xfefab00(,%eax,4),%edx
f0102f4f:	eb 10                	jmp    f0102f61 <print_trapframe+0x66>
	if (trapno == T_SYSCALL)
		return "System call";
	return "(unknown trap)";
f0102f51:	83 f8 30             	cmp    $0x30,%eax
f0102f54:	b9 1a 52 10 f0       	mov    $0xf010521a,%ecx
f0102f59:	ba 0e 52 10 f0       	mov    $0xf010520e,%edx
f0102f5e:	0f 45 d1             	cmovne %ecx,%edx
{
	cprintf("TRAP frame at %p\n", tf);
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0102f61:	83 ec 04             	sub    $0x4,%esp
f0102f64:	52                   	push   %edx
f0102f65:	50                   	push   %eax
f0102f66:	68 76 52 10 f0       	push   $0xf0105276
f0102f6b:	e8 82 fe ff ff       	call   f0102df2 <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0102f70:	83 c4 10             	add    $0x10,%esp
f0102f73:	3b 1d a0 77 17 f0    	cmp    0xf01777a0,%ebx
f0102f79:	75 1a                	jne    f0102f95 <print_trapframe+0x9a>
f0102f7b:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0102f7f:	75 14                	jne    f0102f95 <print_trapframe+0x9a>

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f0102f81:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0102f84:	83 ec 08             	sub    $0x8,%esp
f0102f87:	50                   	push   %eax
f0102f88:	68 88 52 10 f0       	push   $0xf0105288
f0102f8d:	e8 60 fe ff ff       	call   f0102df2 <cprintf>
f0102f92:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f0102f95:	83 ec 08             	sub    $0x8,%esp
f0102f98:	ff 73 2c             	pushl  0x2c(%ebx)
f0102f9b:	68 97 52 10 f0       	push   $0xf0105297
f0102fa0:	e8 4d fe ff ff       	call   f0102df2 <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0102fa5:	83 c4 10             	add    $0x10,%esp
f0102fa8:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0102fac:	75 49                	jne    f0102ff7 <print_trapframe+0xfc>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0102fae:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0102fb1:	89 c2                	mov    %eax,%edx
f0102fb3:	83 e2 01             	and    $0x1,%edx
f0102fb6:	ba 34 52 10 f0       	mov    $0xf0105234,%edx
f0102fbb:	b9 29 52 10 f0       	mov    $0xf0105229,%ecx
f0102fc0:	0f 44 ca             	cmove  %edx,%ecx
f0102fc3:	89 c2                	mov    %eax,%edx
f0102fc5:	83 e2 02             	and    $0x2,%edx
f0102fc8:	ba 46 52 10 f0       	mov    $0xf0105246,%edx
f0102fcd:	be 40 52 10 f0       	mov    $0xf0105240,%esi
f0102fd2:	0f 45 d6             	cmovne %esi,%edx
f0102fd5:	83 e0 04             	and    $0x4,%eax
f0102fd8:	be 60 53 10 f0       	mov    $0xf0105360,%esi
f0102fdd:	b8 4b 52 10 f0       	mov    $0xf010524b,%eax
f0102fe2:	0f 44 c6             	cmove  %esi,%eax
f0102fe5:	51                   	push   %ecx
f0102fe6:	52                   	push   %edx
f0102fe7:	50                   	push   %eax
f0102fe8:	68 a5 52 10 f0       	push   $0xf01052a5
f0102fed:	e8 00 fe ff ff       	call   f0102df2 <cprintf>
f0102ff2:	83 c4 10             	add    $0x10,%esp
f0102ff5:	eb 10                	jmp    f0103007 <print_trapframe+0x10c>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0102ff7:	83 ec 0c             	sub    $0xc,%esp
f0102ffa:	68 ba 50 10 f0       	push   $0xf01050ba
f0102fff:	e8 ee fd ff ff       	call   f0102df2 <cprintf>
f0103004:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103007:	83 ec 08             	sub    $0x8,%esp
f010300a:	ff 73 30             	pushl  0x30(%ebx)
f010300d:	68 b4 52 10 f0       	push   $0xf01052b4
f0103012:	e8 db fd ff ff       	call   f0102df2 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103017:	83 c4 08             	add    $0x8,%esp
f010301a:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f010301e:	50                   	push   %eax
f010301f:	68 c3 52 10 f0       	push   $0xf01052c3
f0103024:	e8 c9 fd ff ff       	call   f0102df2 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103029:	83 c4 08             	add    $0x8,%esp
f010302c:	ff 73 38             	pushl  0x38(%ebx)
f010302f:	68 d6 52 10 f0       	push   $0xf01052d6
f0103034:	e8 b9 fd ff ff       	call   f0102df2 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0103039:	83 c4 10             	add    $0x10,%esp
f010303c:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103040:	74 25                	je     f0103067 <print_trapframe+0x16c>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0103042:	83 ec 08             	sub    $0x8,%esp
f0103045:	ff 73 3c             	pushl  0x3c(%ebx)
f0103048:	68 e5 52 10 f0       	push   $0xf01052e5
f010304d:	e8 a0 fd ff ff       	call   f0102df2 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0103052:	83 c4 08             	add    $0x8,%esp
f0103055:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0103059:	50                   	push   %eax
f010305a:	68 f4 52 10 f0       	push   $0xf01052f4
f010305f:	e8 8e fd ff ff       	call   f0102df2 <cprintf>
f0103064:	83 c4 10             	add    $0x10,%esp
	}
}
f0103067:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010306a:	5b                   	pop    %ebx
f010306b:	5e                   	pop    %esi
f010306c:	5d                   	pop    %ebp
f010306d:	c3                   	ret    

f010306e <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f010306e:	55                   	push   %ebp
f010306f:	89 e5                	mov    %esp,%ebp
f0103071:	57                   	push   %edi
f0103072:	56                   	push   %esi
f0103073:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0103076:	fc                   	cld    

static __inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	__asm __volatile("pushfl; popl %0" : "=r" (eflags));
f0103077:	9c                   	pushf  
f0103078:	58                   	pop    %eax

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0103079:	f6 c4 02             	test   $0x2,%ah
f010307c:	74 19                	je     f0103097 <trap+0x29>
f010307e:	68 07 53 10 f0       	push   $0xf0105307
f0103083:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0103088:	68 a7 00 00 00       	push   $0xa7
f010308d:	68 20 53 10 f0       	push   $0xf0105320
f0103092:	e8 09 d0 ff ff       	call   f01000a0 <_panic>

	cprintf("Incoming TRAP frame at %p\n", tf);
f0103097:	83 ec 08             	sub    $0x8,%esp
f010309a:	56                   	push   %esi
f010309b:	68 2c 53 10 f0       	push   $0xf010532c
f01030a0:	e8 4d fd ff ff       	call   f0102df2 <cprintf>

	if ((tf->tf_cs & 3) == 3) {
f01030a5:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f01030a9:	83 e0 03             	and    $0x3,%eax
f01030ac:	83 c4 10             	add    $0x10,%esp
f01030af:	66 83 f8 03          	cmp    $0x3,%ax
f01030b3:	75 31                	jne    f01030e6 <trap+0x78>
		// Trapped from user mode.
		assert(curenv);
f01030b5:	a1 84 6f 17 f0       	mov    0xf0176f84,%eax
f01030ba:	85 c0                	test   %eax,%eax
f01030bc:	75 19                	jne    f01030d7 <trap+0x69>
f01030be:	68 47 53 10 f0       	push   $0xf0105347
f01030c3:	68 2f 4e 10 f0       	push   $0xf0104e2f
f01030c8:	68 ad 00 00 00       	push   $0xad
f01030cd:	68 20 53 10 f0       	push   $0xf0105320
f01030d2:	e8 c9 cf ff ff       	call   f01000a0 <_panic>

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f01030d7:	b9 11 00 00 00       	mov    $0x11,%ecx
f01030dc:	89 c7                	mov    %eax,%edi
f01030de:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f01030e0:	8b 35 84 6f 17 f0    	mov    0xf0176f84,%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f01030e6:	89 35 a0 77 17 f0    	mov    %esi,0xf01777a0
{
	// Handle processor exceptions.
	// LAB 3: Your code here.

	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f01030ec:	83 ec 0c             	sub    $0xc,%esp
f01030ef:	56                   	push   %esi
f01030f0:	e8 06 fe ff ff       	call   f0102efb <print_trapframe>
	if (tf->tf_cs == GD_KT)
f01030f5:	83 c4 10             	add    $0x10,%esp
f01030f8:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f01030fd:	75 17                	jne    f0103116 <trap+0xa8>
		panic("unhandled trap in kernel");
f01030ff:	83 ec 04             	sub    $0x4,%esp
f0103102:	68 4e 53 10 f0       	push   $0xf010534e
f0103107:	68 96 00 00 00       	push   $0x96
f010310c:	68 20 53 10 f0       	push   $0xf0105320
f0103111:	e8 8a cf ff ff       	call   f01000a0 <_panic>
	else {
		env_destroy(curenv);
f0103116:	83 ec 0c             	sub    $0xc,%esp
f0103119:	ff 35 84 6f 17 f0    	pushl  0xf0176f84
f010311f:	e8 b1 fb ff ff       	call   f0102cd5 <env_destroy>

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
f0103124:	a1 84 6f 17 f0       	mov    0xf0176f84,%eax
f0103129:	83 c4 10             	add    $0x10,%esp
f010312c:	85 c0                	test   %eax,%eax
f010312e:	74 06                	je     f0103136 <trap+0xc8>
f0103130:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103134:	74 19                	je     f010314f <trap+0xe1>
f0103136:	68 ac 54 10 f0       	push   $0xf01054ac
f010313b:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0103140:	68 bf 00 00 00       	push   $0xbf
f0103145:	68 20 53 10 f0       	push   $0xf0105320
f010314a:	e8 51 cf ff ff       	call   f01000a0 <_panic>
	env_run(curenv);
f010314f:	83 ec 0c             	sub    $0xc,%esp
f0103152:	50                   	push   %eax
f0103153:	e8 cd fb ff ff       	call   f0102d25 <env_run>

f0103158 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103158:	55                   	push   %ebp
f0103159:	89 e5                	mov    %esp,%ebp
f010315b:	53                   	push   %ebx
f010315c:	83 ec 04             	sub    $0x4,%esp
f010315f:	8b 5d 08             	mov    0x8(%ebp),%ebx

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f0103162:	0f 20 d0             	mov    %cr2,%eax

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103165:	ff 73 30             	pushl  0x30(%ebx)
f0103168:	50                   	push   %eax
f0103169:	a1 84 6f 17 f0       	mov    0xf0176f84,%eax
f010316e:	ff 70 48             	pushl  0x48(%eax)
f0103171:	68 d8 54 10 f0       	push   $0xf01054d8
f0103176:	e8 77 fc ff ff       	call   f0102df2 <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f010317b:	89 1c 24             	mov    %ebx,(%esp)
f010317e:	e8 78 fd ff ff       	call   f0102efb <print_trapframe>
	env_destroy(curenv);
f0103183:	83 c4 04             	add    $0x4,%esp
f0103186:	ff 35 84 6f 17 f0    	pushl  0xf0176f84
f010318c:	e8 44 fb ff ff       	call   f0102cd5 <env_destroy>
}
f0103191:	83 c4 10             	add    $0x10,%esp
f0103194:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103197:	c9                   	leave  
f0103198:	c3                   	ret    

f0103199 <syscall>:
f0103199:	55                   	push   %ebp
f010319a:	89 e5                	mov    %esp,%ebp
f010319c:	83 ec 0c             	sub    $0xc,%esp
f010319f:	68 50 55 10 f0       	push   $0xf0105550
f01031a4:	6a 49                	push   $0x49
f01031a6:	68 68 55 10 f0       	push   $0xf0105568
f01031ab:	e8 f0 ce ff ff       	call   f01000a0 <_panic>

f01031b0 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01031b0:	55                   	push   %ebp
f01031b1:	89 e5                	mov    %esp,%ebp
f01031b3:	57                   	push   %edi
f01031b4:	56                   	push   %esi
f01031b5:	53                   	push   %ebx
f01031b6:	83 ec 14             	sub    $0x14,%esp
f01031b9:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01031bc:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01031bf:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01031c2:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01031c5:	8b 1a                	mov    (%edx),%ebx
f01031c7:	8b 01                	mov    (%ecx),%eax
f01031c9:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01031cc:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01031d3:	eb 7f                	jmp    f0103254 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f01031d5:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01031d8:	01 d8                	add    %ebx,%eax
f01031da:	89 c6                	mov    %eax,%esi
f01031dc:	c1 ee 1f             	shr    $0x1f,%esi
f01031df:	01 c6                	add    %eax,%esi
f01031e1:	d1 fe                	sar    %esi
f01031e3:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01031e6:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01031e9:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01031ec:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01031ee:	eb 03                	jmp    f01031f3 <stab_binsearch+0x43>
			m--;
f01031f0:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01031f3:	39 c3                	cmp    %eax,%ebx
f01031f5:	7f 0d                	jg     f0103204 <stab_binsearch+0x54>
f01031f7:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01031fb:	83 ea 0c             	sub    $0xc,%edx
f01031fe:	39 f9                	cmp    %edi,%ecx
f0103200:	75 ee                	jne    f01031f0 <stab_binsearch+0x40>
f0103202:	eb 05                	jmp    f0103209 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0103204:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0103207:	eb 4b                	jmp    f0103254 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0103209:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010320c:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010320f:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0103213:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0103216:	76 11                	jbe    f0103229 <stab_binsearch+0x79>
			*region_left = m;
f0103218:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010321b:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f010321d:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103220:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103227:	eb 2b                	jmp    f0103254 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0103229:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010322c:	73 14                	jae    f0103242 <stab_binsearch+0x92>
			*region_right = m - 1;
f010322e:	83 e8 01             	sub    $0x1,%eax
f0103231:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103234:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0103237:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103239:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103240:	eb 12                	jmp    f0103254 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0103242:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103245:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0103247:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f010324b:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010324d:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0103254:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0103257:	0f 8e 78 ff ff ff    	jle    f01031d5 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f010325d:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0103261:	75 0f                	jne    f0103272 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0103263:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103266:	8b 00                	mov    (%eax),%eax
f0103268:	83 e8 01             	sub    $0x1,%eax
f010326b:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010326e:	89 06                	mov    %eax,(%esi)
f0103270:	eb 2c                	jmp    f010329e <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103272:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103275:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0103277:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010327a:	8b 0e                	mov    (%esi),%ecx
f010327c:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010327f:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0103282:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103285:	eb 03                	jmp    f010328a <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0103287:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010328a:	39 c8                	cmp    %ecx,%eax
f010328c:	7e 0b                	jle    f0103299 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f010328e:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0103292:	83 ea 0c             	sub    $0xc,%edx
f0103295:	39 df                	cmp    %ebx,%edi
f0103297:	75 ee                	jne    f0103287 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0103299:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010329c:	89 06                	mov    %eax,(%esi)
	}
}
f010329e:	83 c4 14             	add    $0x14,%esp
f01032a1:	5b                   	pop    %ebx
f01032a2:	5e                   	pop    %esi
f01032a3:	5f                   	pop    %edi
f01032a4:	5d                   	pop    %ebp
f01032a5:	c3                   	ret    

f01032a6 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01032a6:	55                   	push   %ebp
f01032a7:	89 e5                	mov    %esp,%ebp
f01032a9:	57                   	push   %edi
f01032aa:	56                   	push   %esi
f01032ab:	53                   	push   %ebx
f01032ac:	83 ec 3c             	sub    $0x3c,%esp
f01032af:	8b 75 08             	mov    0x8(%ebp),%esi
f01032b2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01032b5:	c7 03 77 55 10 f0    	movl   $0xf0105577,(%ebx)
	info->eip_line = 0;
f01032bb:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f01032c2:	c7 43 08 77 55 10 f0 	movl   $0xf0105577,0x8(%ebx)
	info->eip_fn_namelen = 9;
f01032c9:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f01032d0:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f01032d3:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01032da:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f01032e0:	77 21                	ja     f0103303 <debuginfo_eip+0x5d>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.

		stabs = usd->stabs;
f01032e2:	a1 00 00 20 00       	mov    0x200000,%eax
f01032e7:	89 45 bc             	mov    %eax,-0x44(%ebp)
		stab_end = usd->stab_end;
f01032ea:	a1 04 00 20 00       	mov    0x200004,%eax
		stabstr = usd->stabstr;
f01032ef:	8b 3d 08 00 20 00    	mov    0x200008,%edi
f01032f5:	89 7d b8             	mov    %edi,-0x48(%ebp)
		stabstr_end = usd->stabstr_end;
f01032f8:	8b 3d 0c 00 20 00    	mov    0x20000c,%edi
f01032fe:	89 7d c0             	mov    %edi,-0x40(%ebp)
f0103301:	eb 1a                	jmp    f010331d <debuginfo_eip+0x77>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0103303:	c7 45 c0 99 f3 10 f0 	movl   $0xf010f399,-0x40(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f010330a:	c7 45 b8 bd c9 10 f0 	movl   $0xf010c9bd,-0x48(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f0103311:	b8 bc c9 10 f0       	mov    $0xf010c9bc,%eax
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f0103316:	c7 45 bc b0 57 10 f0 	movl   $0xf01057b0,-0x44(%ebp)
		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010331d:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0103320:	39 7d b8             	cmp    %edi,-0x48(%ebp)
f0103323:	0f 83 95 01 00 00    	jae    f01034be <debuginfo_eip+0x218>
f0103329:	80 7f ff 00          	cmpb   $0x0,-0x1(%edi)
f010332d:	0f 85 92 01 00 00    	jne    f01034c5 <debuginfo_eip+0x21f>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0103333:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f010333a:	8b 7d bc             	mov    -0x44(%ebp),%edi
f010333d:	29 f8                	sub    %edi,%eax
f010333f:	c1 f8 02             	sar    $0x2,%eax
f0103342:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0103348:	83 e8 01             	sub    $0x1,%eax
f010334b:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f010334e:	56                   	push   %esi
f010334f:	6a 64                	push   $0x64
f0103351:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0103354:	89 c1                	mov    %eax,%ecx
f0103356:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0103359:	89 f8                	mov    %edi,%eax
f010335b:	e8 50 fe ff ff       	call   f01031b0 <stab_binsearch>
	if (lfile == 0)
f0103360:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103363:	83 c4 08             	add    $0x8,%esp
f0103366:	85 c0                	test   %eax,%eax
f0103368:	0f 84 5e 01 00 00    	je     f01034cc <debuginfo_eip+0x226>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f010336e:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0103371:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103374:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0103377:	56                   	push   %esi
f0103378:	6a 24                	push   $0x24
f010337a:	8d 45 d8             	lea    -0x28(%ebp),%eax
f010337d:	89 c1                	mov    %eax,%ecx
f010337f:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0103382:	89 f8                	mov    %edi,%eax
f0103384:	e8 27 fe ff ff       	call   f01031b0 <stab_binsearch>

	if (lfun <= rfun) {
f0103389:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010338c:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010338f:	89 55 c4             	mov    %edx,-0x3c(%ebp)
f0103392:	83 c4 08             	add    $0x8,%esp
f0103395:	39 d0                	cmp    %edx,%eax
f0103397:	7f 2b                	jg     f01033c4 <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0103399:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010339c:	8d 0c 97             	lea    (%edi,%edx,4),%ecx
f010339f:	8b 11                	mov    (%ecx),%edx
f01033a1:	8b 7d c0             	mov    -0x40(%ebp),%edi
f01033a4:	2b 7d b8             	sub    -0x48(%ebp),%edi
f01033a7:	39 fa                	cmp    %edi,%edx
f01033a9:	73 06                	jae    f01033b1 <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f01033ab:	03 55 b8             	add    -0x48(%ebp),%edx
f01033ae:	89 53 08             	mov    %edx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f01033b1:	8b 51 08             	mov    0x8(%ecx),%edx
f01033b4:	89 53 10             	mov    %edx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f01033b7:	29 d6                	sub    %edx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f01033b9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f01033bc:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f01033bf:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01033c2:	eb 0f                	jmp    f01033d3 <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f01033c4:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f01033c7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01033ca:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f01033cd:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01033d0:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f01033d3:	83 ec 08             	sub    $0x8,%esp
f01033d6:	6a 3a                	push   $0x3a
f01033d8:	ff 73 08             	pushl  0x8(%ebx)
f01033db:	e8 9a 08 00 00       	call   f0103c7a <strfind>
f01033e0:	2b 43 08             	sub    0x8(%ebx),%eax
f01033e3:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f01033e6:	83 c4 08             	add    $0x8,%esp
f01033e9:	56                   	push   %esi
f01033ea:	6a 44                	push   $0x44
f01033ec:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f01033ef:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f01033f2:	8b 75 bc             	mov    -0x44(%ebp),%esi
f01033f5:	89 f0                	mov    %esi,%eax
f01033f7:	e8 b4 fd ff ff       	call   f01031b0 <stab_binsearch>
	//cprintf("%d	%d",lline,rline);
	if(lline <= rline)
f01033fc:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01033ff:	83 c4 10             	add    $0x10,%esp
f0103402:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0103405:	0f 8f c8 00 00 00    	jg     f01034d3 <debuginfo_eip+0x22d>
		info->eip_line = stabs[lline].n_desc;
f010340b:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010340e:	8d 14 96             	lea    (%esi,%edx,4),%edx
f0103411:	0f b7 4a 06          	movzwl 0x6(%edx),%ecx
f0103415:	89 4b 04             	mov    %ecx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103418:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010341b:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f010341f:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103422:	eb 0a                	jmp    f010342e <debuginfo_eip+0x188>
f0103424:	83 e8 01             	sub    $0x1,%eax
f0103427:	83 ea 0c             	sub    $0xc,%edx
f010342a:	c6 45 c4 01          	movb   $0x1,-0x3c(%ebp)
f010342e:	39 c7                	cmp    %eax,%edi
f0103430:	7e 05                	jle    f0103437 <debuginfo_eip+0x191>
f0103432:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103435:	eb 47                	jmp    f010347e <debuginfo_eip+0x1d8>
	       && stabs[lline].n_type != N_SOL
f0103437:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f010343b:	80 f9 84             	cmp    $0x84,%cl
f010343e:	75 0e                	jne    f010344e <debuginfo_eip+0x1a8>
f0103440:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103443:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0103447:	74 1c                	je     f0103465 <debuginfo_eip+0x1bf>
f0103449:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010344c:	eb 17                	jmp    f0103465 <debuginfo_eip+0x1bf>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f010344e:	80 f9 64             	cmp    $0x64,%cl
f0103451:	75 d1                	jne    f0103424 <debuginfo_eip+0x17e>
f0103453:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0103457:	74 cb                	je     f0103424 <debuginfo_eip+0x17e>
f0103459:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010345c:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0103460:	74 03                	je     f0103465 <debuginfo_eip+0x1bf>
f0103462:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103465:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0103468:	8b 7d bc             	mov    -0x44(%ebp),%edi
f010346b:	8b 14 87             	mov    (%edi,%eax,4),%edx
f010346e:	8b 45 c0             	mov    -0x40(%ebp),%eax
f0103471:	8b 75 b8             	mov    -0x48(%ebp),%esi
f0103474:	29 f0                	sub    %esi,%eax
f0103476:	39 c2                	cmp    %eax,%edx
f0103478:	73 04                	jae    f010347e <debuginfo_eip+0x1d8>
		info->eip_file = stabstr + stabs[lline].n_strx;
f010347a:	01 f2                	add    %esi,%edx
f010347c:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f010347e:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103481:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103484:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103489:	39 f2                	cmp    %esi,%edx
f010348b:	7d 52                	jge    f01034df <debuginfo_eip+0x239>
		for (lline = lfun + 1;
f010348d:	83 c2 01             	add    $0x1,%edx
f0103490:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0103493:	89 d0                	mov    %edx,%eax
f0103495:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0103498:	8b 7d bc             	mov    -0x44(%ebp),%edi
f010349b:	8d 14 97             	lea    (%edi,%edx,4),%edx
f010349e:	eb 04                	jmp    f01034a4 <debuginfo_eip+0x1fe>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f01034a0:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f01034a4:	39 c6                	cmp    %eax,%esi
f01034a6:	7e 32                	jle    f01034da <debuginfo_eip+0x234>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01034a8:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01034ac:	83 c0 01             	add    $0x1,%eax
f01034af:	83 c2 0c             	add    $0xc,%edx
f01034b2:	80 f9 a0             	cmp    $0xa0,%cl
f01034b5:	74 e9                	je     f01034a0 <debuginfo_eip+0x1fa>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01034b7:	b8 00 00 00 00       	mov    $0x0,%eax
f01034bc:	eb 21                	jmp    f01034df <debuginfo_eip+0x239>
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f01034be:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01034c3:	eb 1a                	jmp    f01034df <debuginfo_eip+0x239>
f01034c5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01034ca:	eb 13                	jmp    f01034df <debuginfo_eip+0x239>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f01034cc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01034d1:	eb 0c                	jmp    f01034df <debuginfo_eip+0x239>
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
	//cprintf("%d	%d",lline,rline);
	if(lline <= rline)
		info->eip_line = stabs[lline].n_desc;
	else
		return -1;
f01034d3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01034d8:	eb 05                	jmp    f01034df <debuginfo_eip+0x239>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01034da:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01034df:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01034e2:	5b                   	pop    %ebx
f01034e3:	5e                   	pop    %esi
f01034e4:	5f                   	pop    %edi
f01034e5:	5d                   	pop    %ebp
f01034e6:	c3                   	ret    

f01034e7 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01034e7:	55                   	push   %ebp
f01034e8:	89 e5                	mov    %esp,%ebp
f01034ea:	57                   	push   %edi
f01034eb:	56                   	push   %esi
f01034ec:	53                   	push   %ebx
f01034ed:	83 ec 1c             	sub    $0x1c,%esp
f01034f0:	89 c7                	mov    %eax,%edi
f01034f2:	89 d6                	mov    %edx,%esi
f01034f4:	8b 45 08             	mov    0x8(%ebp),%eax
f01034f7:	8b 55 0c             	mov    0xc(%ebp),%edx
f01034fa:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01034fd:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103500:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0103503:	bb 00 00 00 00       	mov    $0x0,%ebx
f0103508:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010350b:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f010350e:	39 d3                	cmp    %edx,%ebx
f0103510:	72 05                	jb     f0103517 <printnum+0x30>
f0103512:	39 45 10             	cmp    %eax,0x10(%ebp)
f0103515:	77 45                	ja     f010355c <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0103517:	83 ec 0c             	sub    $0xc,%esp
f010351a:	ff 75 18             	pushl  0x18(%ebp)
f010351d:	8b 45 14             	mov    0x14(%ebp),%eax
f0103520:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0103523:	53                   	push   %ebx
f0103524:	ff 75 10             	pushl  0x10(%ebp)
f0103527:	83 ec 08             	sub    $0x8,%esp
f010352a:	ff 75 e4             	pushl  -0x1c(%ebp)
f010352d:	ff 75 e0             	pushl  -0x20(%ebp)
f0103530:	ff 75 dc             	pushl  -0x24(%ebp)
f0103533:	ff 75 d8             	pushl  -0x28(%ebp)
f0103536:	e8 65 09 00 00       	call   f0103ea0 <__udivdi3>
f010353b:	83 c4 18             	add    $0x18,%esp
f010353e:	52                   	push   %edx
f010353f:	50                   	push   %eax
f0103540:	89 f2                	mov    %esi,%edx
f0103542:	89 f8                	mov    %edi,%eax
f0103544:	e8 9e ff ff ff       	call   f01034e7 <printnum>
f0103549:	83 c4 20             	add    $0x20,%esp
f010354c:	eb 18                	jmp    f0103566 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f010354e:	83 ec 08             	sub    $0x8,%esp
f0103551:	56                   	push   %esi
f0103552:	ff 75 18             	pushl  0x18(%ebp)
f0103555:	ff d7                	call   *%edi
f0103557:	83 c4 10             	add    $0x10,%esp
f010355a:	eb 03                	jmp    f010355f <printnum+0x78>
f010355c:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f010355f:	83 eb 01             	sub    $0x1,%ebx
f0103562:	85 db                	test   %ebx,%ebx
f0103564:	7f e8                	jg     f010354e <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103566:	83 ec 08             	sub    $0x8,%esp
f0103569:	56                   	push   %esi
f010356a:	83 ec 04             	sub    $0x4,%esp
f010356d:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103570:	ff 75 e0             	pushl  -0x20(%ebp)
f0103573:	ff 75 dc             	pushl  -0x24(%ebp)
f0103576:	ff 75 d8             	pushl  -0x28(%ebp)
f0103579:	e8 52 0a 00 00       	call   f0103fd0 <__umoddi3>
f010357e:	83 c4 14             	add    $0x14,%esp
f0103581:	0f be 80 81 55 10 f0 	movsbl -0xfefaa7f(%eax),%eax
f0103588:	50                   	push   %eax
f0103589:	ff d7                	call   *%edi
}
f010358b:	83 c4 10             	add    $0x10,%esp
f010358e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103591:	5b                   	pop    %ebx
f0103592:	5e                   	pop    %esi
f0103593:	5f                   	pop    %edi
f0103594:	5d                   	pop    %ebp
f0103595:	c3                   	ret    

f0103596 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0103596:	55                   	push   %ebp
f0103597:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0103599:	83 fa 01             	cmp    $0x1,%edx
f010359c:	7e 0e                	jle    f01035ac <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f010359e:	8b 10                	mov    (%eax),%edx
f01035a0:	8d 4a 08             	lea    0x8(%edx),%ecx
f01035a3:	89 08                	mov    %ecx,(%eax)
f01035a5:	8b 02                	mov    (%edx),%eax
f01035a7:	8b 52 04             	mov    0x4(%edx),%edx
f01035aa:	eb 22                	jmp    f01035ce <getuint+0x38>
	else if (lflag)
f01035ac:	85 d2                	test   %edx,%edx
f01035ae:	74 10                	je     f01035c0 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f01035b0:	8b 10                	mov    (%eax),%edx
f01035b2:	8d 4a 04             	lea    0x4(%edx),%ecx
f01035b5:	89 08                	mov    %ecx,(%eax)
f01035b7:	8b 02                	mov    (%edx),%eax
f01035b9:	ba 00 00 00 00       	mov    $0x0,%edx
f01035be:	eb 0e                	jmp    f01035ce <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f01035c0:	8b 10                	mov    (%eax),%edx
f01035c2:	8d 4a 04             	lea    0x4(%edx),%ecx
f01035c5:	89 08                	mov    %ecx,(%eax)
f01035c7:	8b 02                	mov    (%edx),%eax
f01035c9:	ba 00 00 00 00       	mov    $0x0,%edx
}
f01035ce:	5d                   	pop    %ebp
f01035cf:	c3                   	ret    

f01035d0 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01035d0:	55                   	push   %ebp
f01035d1:	89 e5                	mov    %esp,%ebp
f01035d3:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f01035d6:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f01035da:	8b 10                	mov    (%eax),%edx
f01035dc:	3b 50 04             	cmp    0x4(%eax),%edx
f01035df:	73 0a                	jae    f01035eb <sprintputch+0x1b>
		*b->buf++ = ch;
f01035e1:	8d 4a 01             	lea    0x1(%edx),%ecx
f01035e4:	89 08                	mov    %ecx,(%eax)
f01035e6:	8b 45 08             	mov    0x8(%ebp),%eax
f01035e9:	88 02                	mov    %al,(%edx)
}
f01035eb:	5d                   	pop    %ebp
f01035ec:	c3                   	ret    

f01035ed <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f01035ed:	55                   	push   %ebp
f01035ee:	89 e5                	mov    %esp,%ebp
f01035f0:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01035f3:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f01035f6:	50                   	push   %eax
f01035f7:	ff 75 10             	pushl  0x10(%ebp)
f01035fa:	ff 75 0c             	pushl  0xc(%ebp)
f01035fd:	ff 75 08             	pushl  0x8(%ebp)
f0103600:	e8 05 00 00 00       	call   f010360a <vprintfmt>
	va_end(ap);
}
f0103605:	83 c4 10             	add    $0x10,%esp
f0103608:	c9                   	leave  
f0103609:	c3                   	ret    

f010360a <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f010360a:	55                   	push   %ebp
f010360b:	89 e5                	mov    %esp,%ebp
f010360d:	57                   	push   %edi
f010360e:	56                   	push   %esi
f010360f:	53                   	push   %ebx
f0103610:	83 ec 2c             	sub    $0x2c,%esp
f0103613:	8b 75 08             	mov    0x8(%ebp),%esi
f0103616:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103619:	8b 7d 10             	mov    0x10(%ebp),%edi
f010361c:	eb 12                	jmp    f0103630 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f010361e:	85 c0                	test   %eax,%eax
f0103620:	0f 84 a9 03 00 00    	je     f01039cf <vprintfmt+0x3c5>
				return;
			putch(ch, putdat);
f0103626:	83 ec 08             	sub    $0x8,%esp
f0103629:	53                   	push   %ebx
f010362a:	50                   	push   %eax
f010362b:	ff d6                	call   *%esi
f010362d:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103630:	83 c7 01             	add    $0x1,%edi
f0103633:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103637:	83 f8 25             	cmp    $0x25,%eax
f010363a:	75 e2                	jne    f010361e <vprintfmt+0x14>
f010363c:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0103640:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0103647:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f010364e:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0103655:	ba 00 00 00 00       	mov    $0x0,%edx
f010365a:	eb 07                	jmp    f0103663 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010365c:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f010365f:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103663:	8d 47 01             	lea    0x1(%edi),%eax
f0103666:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103669:	0f b6 07             	movzbl (%edi),%eax
f010366c:	0f b6 c8             	movzbl %al,%ecx
f010366f:	83 e8 23             	sub    $0x23,%eax
f0103672:	3c 55                	cmp    $0x55,%al
f0103674:	0f 87 3a 03 00 00    	ja     f01039b4 <vprintfmt+0x3aa>
f010367a:	0f b6 c0             	movzbl %al,%eax
f010367d:	ff 24 85 20 56 10 f0 	jmp    *-0xfefa9e0(,%eax,4)
f0103684:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0103687:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f010368b:	eb d6                	jmp    f0103663 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010368d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103690:	b8 00 00 00 00       	mov    $0x0,%eax
f0103695:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0103698:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010369b:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f010369f:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f01036a2:	8d 51 d0             	lea    -0x30(%ecx),%edx
f01036a5:	83 fa 09             	cmp    $0x9,%edx
f01036a8:	77 39                	ja     f01036e3 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f01036aa:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f01036ad:	eb e9                	jmp    f0103698 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f01036af:	8b 45 14             	mov    0x14(%ebp),%eax
f01036b2:	8d 48 04             	lea    0x4(%eax),%ecx
f01036b5:	89 4d 14             	mov    %ecx,0x14(%ebp)
f01036b8:	8b 00                	mov    (%eax),%eax
f01036ba:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01036bd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f01036c0:	eb 27                	jmp    f01036e9 <vprintfmt+0xdf>
f01036c2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01036c5:	85 c0                	test   %eax,%eax
f01036c7:	b9 00 00 00 00       	mov    $0x0,%ecx
f01036cc:	0f 49 c8             	cmovns %eax,%ecx
f01036cf:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01036d2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01036d5:	eb 8c                	jmp    f0103663 <vprintfmt+0x59>
f01036d7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f01036da:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f01036e1:	eb 80                	jmp    f0103663 <vprintfmt+0x59>
f01036e3:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01036e6:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f01036e9:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01036ed:	0f 89 70 ff ff ff    	jns    f0103663 <vprintfmt+0x59>
				width = precision, precision = -1;
f01036f3:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01036f6:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01036f9:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103700:	e9 5e ff ff ff       	jmp    f0103663 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0103705:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103708:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f010370b:	e9 53 ff ff ff       	jmp    f0103663 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0103710:	8b 45 14             	mov    0x14(%ebp),%eax
f0103713:	8d 50 04             	lea    0x4(%eax),%edx
f0103716:	89 55 14             	mov    %edx,0x14(%ebp)
f0103719:	83 ec 08             	sub    $0x8,%esp
f010371c:	53                   	push   %ebx
f010371d:	ff 30                	pushl  (%eax)
f010371f:	ff d6                	call   *%esi
			break;
f0103721:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103724:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0103727:	e9 04 ff ff ff       	jmp    f0103630 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f010372c:	8b 45 14             	mov    0x14(%ebp),%eax
f010372f:	8d 50 04             	lea    0x4(%eax),%edx
f0103732:	89 55 14             	mov    %edx,0x14(%ebp)
f0103735:	8b 00                	mov    (%eax),%eax
f0103737:	99                   	cltd   
f0103738:	31 d0                	xor    %edx,%eax
f010373a:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010373c:	83 f8 07             	cmp    $0x7,%eax
f010373f:	7f 0b                	jg     f010374c <vprintfmt+0x142>
f0103741:	8b 14 85 80 57 10 f0 	mov    -0xfefa880(,%eax,4),%edx
f0103748:	85 d2                	test   %edx,%edx
f010374a:	75 18                	jne    f0103764 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f010374c:	50                   	push   %eax
f010374d:	68 99 55 10 f0       	push   $0xf0105599
f0103752:	53                   	push   %ebx
f0103753:	56                   	push   %esi
f0103754:	e8 94 fe ff ff       	call   f01035ed <printfmt>
f0103759:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010375c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f010375f:	e9 cc fe ff ff       	jmp    f0103630 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0103764:	52                   	push   %edx
f0103765:	68 41 4e 10 f0       	push   $0xf0104e41
f010376a:	53                   	push   %ebx
f010376b:	56                   	push   %esi
f010376c:	e8 7c fe ff ff       	call   f01035ed <printfmt>
f0103771:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103774:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103777:	e9 b4 fe ff ff       	jmp    f0103630 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f010377c:	8b 45 14             	mov    0x14(%ebp),%eax
f010377f:	8d 50 04             	lea    0x4(%eax),%edx
f0103782:	89 55 14             	mov    %edx,0x14(%ebp)
f0103785:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0103787:	85 ff                	test   %edi,%edi
f0103789:	b8 92 55 10 f0       	mov    $0xf0105592,%eax
f010378e:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0103791:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103795:	0f 8e 94 00 00 00    	jle    f010382f <vprintfmt+0x225>
f010379b:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f010379f:	0f 84 98 00 00 00    	je     f010383d <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f01037a5:	83 ec 08             	sub    $0x8,%esp
f01037a8:	ff 75 d0             	pushl  -0x30(%ebp)
f01037ab:	57                   	push   %edi
f01037ac:	e8 7f 03 00 00       	call   f0103b30 <strnlen>
f01037b1:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f01037b4:	29 c1                	sub    %eax,%ecx
f01037b6:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f01037b9:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f01037bc:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f01037c0:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01037c3:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01037c6:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01037c8:	eb 0f                	jmp    f01037d9 <vprintfmt+0x1cf>
					putch(padc, putdat);
f01037ca:	83 ec 08             	sub    $0x8,%esp
f01037cd:	53                   	push   %ebx
f01037ce:	ff 75 e0             	pushl  -0x20(%ebp)
f01037d1:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01037d3:	83 ef 01             	sub    $0x1,%edi
f01037d6:	83 c4 10             	add    $0x10,%esp
f01037d9:	85 ff                	test   %edi,%edi
f01037db:	7f ed                	jg     f01037ca <vprintfmt+0x1c0>
f01037dd:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01037e0:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f01037e3:	85 c9                	test   %ecx,%ecx
f01037e5:	b8 00 00 00 00       	mov    $0x0,%eax
f01037ea:	0f 49 c1             	cmovns %ecx,%eax
f01037ed:	29 c1                	sub    %eax,%ecx
f01037ef:	89 75 08             	mov    %esi,0x8(%ebp)
f01037f2:	8b 75 d0             	mov    -0x30(%ebp),%esi
f01037f5:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01037f8:	89 cb                	mov    %ecx,%ebx
f01037fa:	eb 4d                	jmp    f0103849 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f01037fc:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0103800:	74 1b                	je     f010381d <vprintfmt+0x213>
f0103802:	0f be c0             	movsbl %al,%eax
f0103805:	83 e8 20             	sub    $0x20,%eax
f0103808:	83 f8 5e             	cmp    $0x5e,%eax
f010380b:	76 10                	jbe    f010381d <vprintfmt+0x213>
					putch('?', putdat);
f010380d:	83 ec 08             	sub    $0x8,%esp
f0103810:	ff 75 0c             	pushl  0xc(%ebp)
f0103813:	6a 3f                	push   $0x3f
f0103815:	ff 55 08             	call   *0x8(%ebp)
f0103818:	83 c4 10             	add    $0x10,%esp
f010381b:	eb 0d                	jmp    f010382a <vprintfmt+0x220>
				else
					putch(ch, putdat);
f010381d:	83 ec 08             	sub    $0x8,%esp
f0103820:	ff 75 0c             	pushl  0xc(%ebp)
f0103823:	52                   	push   %edx
f0103824:	ff 55 08             	call   *0x8(%ebp)
f0103827:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010382a:	83 eb 01             	sub    $0x1,%ebx
f010382d:	eb 1a                	jmp    f0103849 <vprintfmt+0x23f>
f010382f:	89 75 08             	mov    %esi,0x8(%ebp)
f0103832:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103835:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103838:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f010383b:	eb 0c                	jmp    f0103849 <vprintfmt+0x23f>
f010383d:	89 75 08             	mov    %esi,0x8(%ebp)
f0103840:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103843:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103846:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103849:	83 c7 01             	add    $0x1,%edi
f010384c:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103850:	0f be d0             	movsbl %al,%edx
f0103853:	85 d2                	test   %edx,%edx
f0103855:	74 23                	je     f010387a <vprintfmt+0x270>
f0103857:	85 f6                	test   %esi,%esi
f0103859:	78 a1                	js     f01037fc <vprintfmt+0x1f2>
f010385b:	83 ee 01             	sub    $0x1,%esi
f010385e:	79 9c                	jns    f01037fc <vprintfmt+0x1f2>
f0103860:	89 df                	mov    %ebx,%edi
f0103862:	8b 75 08             	mov    0x8(%ebp),%esi
f0103865:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103868:	eb 18                	jmp    f0103882 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f010386a:	83 ec 08             	sub    $0x8,%esp
f010386d:	53                   	push   %ebx
f010386e:	6a 20                	push   $0x20
f0103870:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103872:	83 ef 01             	sub    $0x1,%edi
f0103875:	83 c4 10             	add    $0x10,%esp
f0103878:	eb 08                	jmp    f0103882 <vprintfmt+0x278>
f010387a:	89 df                	mov    %ebx,%edi
f010387c:	8b 75 08             	mov    0x8(%ebp),%esi
f010387f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103882:	85 ff                	test   %edi,%edi
f0103884:	7f e4                	jg     f010386a <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103886:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103889:	e9 a2 fd ff ff       	jmp    f0103630 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f010388e:	83 fa 01             	cmp    $0x1,%edx
f0103891:	7e 16                	jle    f01038a9 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0103893:	8b 45 14             	mov    0x14(%ebp),%eax
f0103896:	8d 50 08             	lea    0x8(%eax),%edx
f0103899:	89 55 14             	mov    %edx,0x14(%ebp)
f010389c:	8b 50 04             	mov    0x4(%eax),%edx
f010389f:	8b 00                	mov    (%eax),%eax
f01038a1:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01038a4:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01038a7:	eb 32                	jmp    f01038db <vprintfmt+0x2d1>
	else if (lflag)
f01038a9:	85 d2                	test   %edx,%edx
f01038ab:	74 18                	je     f01038c5 <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f01038ad:	8b 45 14             	mov    0x14(%ebp),%eax
f01038b0:	8d 50 04             	lea    0x4(%eax),%edx
f01038b3:	89 55 14             	mov    %edx,0x14(%ebp)
f01038b6:	8b 00                	mov    (%eax),%eax
f01038b8:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01038bb:	89 c1                	mov    %eax,%ecx
f01038bd:	c1 f9 1f             	sar    $0x1f,%ecx
f01038c0:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01038c3:	eb 16                	jmp    f01038db <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f01038c5:	8b 45 14             	mov    0x14(%ebp),%eax
f01038c8:	8d 50 04             	lea    0x4(%eax),%edx
f01038cb:	89 55 14             	mov    %edx,0x14(%ebp)
f01038ce:	8b 00                	mov    (%eax),%eax
f01038d0:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01038d3:	89 c1                	mov    %eax,%ecx
f01038d5:	c1 f9 1f             	sar    $0x1f,%ecx
f01038d8:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f01038db:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01038de:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01038e1:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01038e6:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01038ea:	0f 89 90 00 00 00    	jns    f0103980 <vprintfmt+0x376>
				putch('-', putdat);
f01038f0:	83 ec 08             	sub    $0x8,%esp
f01038f3:	53                   	push   %ebx
f01038f4:	6a 2d                	push   $0x2d
f01038f6:	ff d6                	call   *%esi
				num = -(long long) num;
f01038f8:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01038fb:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01038fe:	f7 d8                	neg    %eax
f0103900:	83 d2 00             	adc    $0x0,%edx
f0103903:	f7 da                	neg    %edx
f0103905:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0103908:	b9 0a 00 00 00       	mov    $0xa,%ecx
f010390d:	eb 71                	jmp    f0103980 <vprintfmt+0x376>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f010390f:	8d 45 14             	lea    0x14(%ebp),%eax
f0103912:	e8 7f fc ff ff       	call   f0103596 <getuint>
			base = 10;
f0103917:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f010391c:	eb 62                	jmp    f0103980 <vprintfmt+0x376>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f010391e:	8d 45 14             	lea    0x14(%ebp),%eax
f0103921:	e8 70 fc ff ff       	call   f0103596 <getuint>
			base = 8;
			printnum(putch, putdat, num, base, width, padc);
f0103926:	83 ec 0c             	sub    $0xc,%esp
f0103929:	0f be 4d d4          	movsbl -0x2c(%ebp),%ecx
f010392d:	51                   	push   %ecx
f010392e:	ff 75 e0             	pushl  -0x20(%ebp)
f0103931:	6a 08                	push   $0x8
f0103933:	52                   	push   %edx
f0103934:	50                   	push   %eax
f0103935:	89 da                	mov    %ebx,%edx
f0103937:	89 f0                	mov    %esi,%eax
f0103939:	e8 a9 fb ff ff       	call   f01034e7 <printnum>
			break;
f010393e:	83 c4 20             	add    $0x20,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103941:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
			base = 8;
			printnum(putch, putdat, num, base, width, padc);
			break;
f0103944:	e9 e7 fc ff ff       	jmp    f0103630 <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
f0103949:	83 ec 08             	sub    $0x8,%esp
f010394c:	53                   	push   %ebx
f010394d:	6a 30                	push   $0x30
f010394f:	ff d6                	call   *%esi
			putch('x', putdat);
f0103951:	83 c4 08             	add    $0x8,%esp
f0103954:	53                   	push   %ebx
f0103955:	6a 78                	push   $0x78
f0103957:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0103959:	8b 45 14             	mov    0x14(%ebp),%eax
f010395c:	8d 50 04             	lea    0x4(%eax),%edx
f010395f:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0103962:	8b 00                	mov    (%eax),%eax
f0103964:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0103969:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010396c:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0103971:	eb 0d                	jmp    f0103980 <vprintfmt+0x376>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0103973:	8d 45 14             	lea    0x14(%ebp),%eax
f0103976:	e8 1b fc ff ff       	call   f0103596 <getuint>
			base = 16;
f010397b:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0103980:	83 ec 0c             	sub    $0xc,%esp
f0103983:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0103987:	57                   	push   %edi
f0103988:	ff 75 e0             	pushl  -0x20(%ebp)
f010398b:	51                   	push   %ecx
f010398c:	52                   	push   %edx
f010398d:	50                   	push   %eax
f010398e:	89 da                	mov    %ebx,%edx
f0103990:	89 f0                	mov    %esi,%eax
f0103992:	e8 50 fb ff ff       	call   f01034e7 <printnum>
			break;
f0103997:	83 c4 20             	add    $0x20,%esp
f010399a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010399d:	e9 8e fc ff ff       	jmp    f0103630 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01039a2:	83 ec 08             	sub    $0x8,%esp
f01039a5:	53                   	push   %ebx
f01039a6:	51                   	push   %ecx
f01039a7:	ff d6                	call   *%esi
			break;
f01039a9:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01039ac:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f01039af:	e9 7c fc ff ff       	jmp    f0103630 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01039b4:	83 ec 08             	sub    $0x8,%esp
f01039b7:	53                   	push   %ebx
f01039b8:	6a 25                	push   $0x25
f01039ba:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01039bc:	83 c4 10             	add    $0x10,%esp
f01039bf:	eb 03                	jmp    f01039c4 <vprintfmt+0x3ba>
f01039c1:	83 ef 01             	sub    $0x1,%edi
f01039c4:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f01039c8:	75 f7                	jne    f01039c1 <vprintfmt+0x3b7>
f01039ca:	e9 61 fc ff ff       	jmp    f0103630 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f01039cf:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01039d2:	5b                   	pop    %ebx
f01039d3:	5e                   	pop    %esi
f01039d4:	5f                   	pop    %edi
f01039d5:	5d                   	pop    %ebp
f01039d6:	c3                   	ret    

f01039d7 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01039d7:	55                   	push   %ebp
f01039d8:	89 e5                	mov    %esp,%ebp
f01039da:	83 ec 18             	sub    $0x18,%esp
f01039dd:	8b 45 08             	mov    0x8(%ebp),%eax
f01039e0:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01039e3:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01039e6:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01039ea:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01039ed:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01039f4:	85 c0                	test   %eax,%eax
f01039f6:	74 26                	je     f0103a1e <vsnprintf+0x47>
f01039f8:	85 d2                	test   %edx,%edx
f01039fa:	7e 22                	jle    f0103a1e <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01039fc:	ff 75 14             	pushl  0x14(%ebp)
f01039ff:	ff 75 10             	pushl  0x10(%ebp)
f0103a02:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0103a05:	50                   	push   %eax
f0103a06:	68 d0 35 10 f0       	push   $0xf01035d0
f0103a0b:	e8 fa fb ff ff       	call   f010360a <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0103a10:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103a13:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0103a16:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103a19:	83 c4 10             	add    $0x10,%esp
f0103a1c:	eb 05                	jmp    f0103a23 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0103a1e:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0103a23:	c9                   	leave  
f0103a24:	c3                   	ret    

f0103a25 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0103a25:	55                   	push   %ebp
f0103a26:	89 e5                	mov    %esp,%ebp
f0103a28:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0103a2b:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0103a2e:	50                   	push   %eax
f0103a2f:	ff 75 10             	pushl  0x10(%ebp)
f0103a32:	ff 75 0c             	pushl  0xc(%ebp)
f0103a35:	ff 75 08             	pushl  0x8(%ebp)
f0103a38:	e8 9a ff ff ff       	call   f01039d7 <vsnprintf>
	va_end(ap);

	return rc;
}
f0103a3d:	c9                   	leave  
f0103a3e:	c3                   	ret    

f0103a3f <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103a3f:	55                   	push   %ebp
f0103a40:	89 e5                	mov    %esp,%ebp
f0103a42:	57                   	push   %edi
f0103a43:	56                   	push   %esi
f0103a44:	53                   	push   %ebx
f0103a45:	83 ec 0c             	sub    $0xc,%esp
f0103a48:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0103a4b:	85 c0                	test   %eax,%eax
f0103a4d:	74 11                	je     f0103a60 <readline+0x21>
		cprintf("%s", prompt);
f0103a4f:	83 ec 08             	sub    $0x8,%esp
f0103a52:	50                   	push   %eax
f0103a53:	68 41 4e 10 f0       	push   $0xf0104e41
f0103a58:	e8 95 f3 ff ff       	call   f0102df2 <cprintf>
f0103a5d:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0103a60:	83 ec 0c             	sub    $0xc,%esp
f0103a63:	6a 00                	push   $0x0
f0103a65:	e8 be cb ff ff       	call   f0100628 <iscons>
f0103a6a:	89 c7                	mov    %eax,%edi
f0103a6c:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0103a6f:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0103a74:	e8 9e cb ff ff       	call   f0100617 <getchar>
f0103a79:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0103a7b:	85 c0                	test   %eax,%eax
f0103a7d:	79 18                	jns    f0103a97 <readline+0x58>
			cprintf("read error: %e\n", c);
f0103a7f:	83 ec 08             	sub    $0x8,%esp
f0103a82:	50                   	push   %eax
f0103a83:	68 a0 57 10 f0       	push   $0xf01057a0
f0103a88:	e8 65 f3 ff ff       	call   f0102df2 <cprintf>
			return NULL;
f0103a8d:	83 c4 10             	add    $0x10,%esp
f0103a90:	b8 00 00 00 00       	mov    $0x0,%eax
f0103a95:	eb 79                	jmp    f0103b10 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103a97:	83 f8 08             	cmp    $0x8,%eax
f0103a9a:	0f 94 c2             	sete   %dl
f0103a9d:	83 f8 7f             	cmp    $0x7f,%eax
f0103aa0:	0f 94 c0             	sete   %al
f0103aa3:	08 c2                	or     %al,%dl
f0103aa5:	74 1a                	je     f0103ac1 <readline+0x82>
f0103aa7:	85 f6                	test   %esi,%esi
f0103aa9:	7e 16                	jle    f0103ac1 <readline+0x82>
			if (echoing)
f0103aab:	85 ff                	test   %edi,%edi
f0103aad:	74 0d                	je     f0103abc <readline+0x7d>
				cputchar('\b');
f0103aaf:	83 ec 0c             	sub    $0xc,%esp
f0103ab2:	6a 08                	push   $0x8
f0103ab4:	e8 4e cb ff ff       	call   f0100607 <cputchar>
f0103ab9:	83 c4 10             	add    $0x10,%esp
			i--;
f0103abc:	83 ee 01             	sub    $0x1,%esi
f0103abf:	eb b3                	jmp    f0103a74 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103ac1:	83 fb 1f             	cmp    $0x1f,%ebx
f0103ac4:	7e 23                	jle    f0103ae9 <readline+0xaa>
f0103ac6:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0103acc:	7f 1b                	jg     f0103ae9 <readline+0xaa>
			if (echoing)
f0103ace:	85 ff                	test   %edi,%edi
f0103ad0:	74 0c                	je     f0103ade <readline+0x9f>
				cputchar(c);
f0103ad2:	83 ec 0c             	sub    $0xc,%esp
f0103ad5:	53                   	push   %ebx
f0103ad6:	e8 2c cb ff ff       	call   f0100607 <cputchar>
f0103adb:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0103ade:	88 9e 40 78 17 f0    	mov    %bl,-0xfe887c0(%esi)
f0103ae4:	8d 76 01             	lea    0x1(%esi),%esi
f0103ae7:	eb 8b                	jmp    f0103a74 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0103ae9:	83 fb 0a             	cmp    $0xa,%ebx
f0103aec:	74 05                	je     f0103af3 <readline+0xb4>
f0103aee:	83 fb 0d             	cmp    $0xd,%ebx
f0103af1:	75 81                	jne    f0103a74 <readline+0x35>
			if (echoing)
f0103af3:	85 ff                	test   %edi,%edi
f0103af5:	74 0d                	je     f0103b04 <readline+0xc5>
				cputchar('\n');
f0103af7:	83 ec 0c             	sub    $0xc,%esp
f0103afa:	6a 0a                	push   $0xa
f0103afc:	e8 06 cb ff ff       	call   f0100607 <cputchar>
f0103b01:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0103b04:	c6 86 40 78 17 f0 00 	movb   $0x0,-0xfe887c0(%esi)
			return buf;
f0103b0b:	b8 40 78 17 f0       	mov    $0xf0177840,%eax
		}
	}
}
f0103b10:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103b13:	5b                   	pop    %ebx
f0103b14:	5e                   	pop    %esi
f0103b15:	5f                   	pop    %edi
f0103b16:	5d                   	pop    %ebp
f0103b17:	c3                   	ret    

f0103b18 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103b18:	55                   	push   %ebp
f0103b19:	89 e5                	mov    %esp,%ebp
f0103b1b:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103b1e:	b8 00 00 00 00       	mov    $0x0,%eax
f0103b23:	eb 03                	jmp    f0103b28 <strlen+0x10>
		n++;
f0103b25:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0103b28:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103b2c:	75 f7                	jne    f0103b25 <strlen+0xd>
		n++;
	return n;
}
f0103b2e:	5d                   	pop    %ebp
f0103b2f:	c3                   	ret    

f0103b30 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103b30:	55                   	push   %ebp
f0103b31:	89 e5                	mov    %esp,%ebp
f0103b33:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103b36:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103b39:	ba 00 00 00 00       	mov    $0x0,%edx
f0103b3e:	eb 03                	jmp    f0103b43 <strnlen+0x13>
		n++;
f0103b40:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103b43:	39 c2                	cmp    %eax,%edx
f0103b45:	74 08                	je     f0103b4f <strnlen+0x1f>
f0103b47:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0103b4b:	75 f3                	jne    f0103b40 <strnlen+0x10>
f0103b4d:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0103b4f:	5d                   	pop    %ebp
f0103b50:	c3                   	ret    

f0103b51 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103b51:	55                   	push   %ebp
f0103b52:	89 e5                	mov    %esp,%ebp
f0103b54:	53                   	push   %ebx
f0103b55:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b58:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103b5b:	89 c2                	mov    %eax,%edx
f0103b5d:	83 c2 01             	add    $0x1,%edx
f0103b60:	83 c1 01             	add    $0x1,%ecx
f0103b63:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0103b67:	88 5a ff             	mov    %bl,-0x1(%edx)
f0103b6a:	84 db                	test   %bl,%bl
f0103b6c:	75 ef                	jne    f0103b5d <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0103b6e:	5b                   	pop    %ebx
f0103b6f:	5d                   	pop    %ebp
f0103b70:	c3                   	ret    

f0103b71 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0103b71:	55                   	push   %ebp
f0103b72:	89 e5                	mov    %esp,%ebp
f0103b74:	53                   	push   %ebx
f0103b75:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103b78:	53                   	push   %ebx
f0103b79:	e8 9a ff ff ff       	call   f0103b18 <strlen>
f0103b7e:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0103b81:	ff 75 0c             	pushl  0xc(%ebp)
f0103b84:	01 d8                	add    %ebx,%eax
f0103b86:	50                   	push   %eax
f0103b87:	e8 c5 ff ff ff       	call   f0103b51 <strcpy>
	return dst;
}
f0103b8c:	89 d8                	mov    %ebx,%eax
f0103b8e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103b91:	c9                   	leave  
f0103b92:	c3                   	ret    

f0103b93 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103b93:	55                   	push   %ebp
f0103b94:	89 e5                	mov    %esp,%ebp
f0103b96:	56                   	push   %esi
f0103b97:	53                   	push   %ebx
f0103b98:	8b 75 08             	mov    0x8(%ebp),%esi
f0103b9b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103b9e:	89 f3                	mov    %esi,%ebx
f0103ba0:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103ba3:	89 f2                	mov    %esi,%edx
f0103ba5:	eb 0f                	jmp    f0103bb6 <strncpy+0x23>
		*dst++ = *src;
f0103ba7:	83 c2 01             	add    $0x1,%edx
f0103baa:	0f b6 01             	movzbl (%ecx),%eax
f0103bad:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0103bb0:	80 39 01             	cmpb   $0x1,(%ecx)
f0103bb3:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103bb6:	39 da                	cmp    %ebx,%edx
f0103bb8:	75 ed                	jne    f0103ba7 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0103bba:	89 f0                	mov    %esi,%eax
f0103bbc:	5b                   	pop    %ebx
f0103bbd:	5e                   	pop    %esi
f0103bbe:	5d                   	pop    %ebp
f0103bbf:	c3                   	ret    

f0103bc0 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0103bc0:	55                   	push   %ebp
f0103bc1:	89 e5                	mov    %esp,%ebp
f0103bc3:	56                   	push   %esi
f0103bc4:	53                   	push   %ebx
f0103bc5:	8b 75 08             	mov    0x8(%ebp),%esi
f0103bc8:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103bcb:	8b 55 10             	mov    0x10(%ebp),%edx
f0103bce:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103bd0:	85 d2                	test   %edx,%edx
f0103bd2:	74 21                	je     f0103bf5 <strlcpy+0x35>
f0103bd4:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0103bd8:	89 f2                	mov    %esi,%edx
f0103bda:	eb 09                	jmp    f0103be5 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103bdc:	83 c2 01             	add    $0x1,%edx
f0103bdf:	83 c1 01             	add    $0x1,%ecx
f0103be2:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0103be5:	39 c2                	cmp    %eax,%edx
f0103be7:	74 09                	je     f0103bf2 <strlcpy+0x32>
f0103be9:	0f b6 19             	movzbl (%ecx),%ebx
f0103bec:	84 db                	test   %bl,%bl
f0103bee:	75 ec                	jne    f0103bdc <strlcpy+0x1c>
f0103bf0:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0103bf2:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0103bf5:	29 f0                	sub    %esi,%eax
}
f0103bf7:	5b                   	pop    %ebx
f0103bf8:	5e                   	pop    %esi
f0103bf9:	5d                   	pop    %ebp
f0103bfa:	c3                   	ret    

f0103bfb <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103bfb:	55                   	push   %ebp
f0103bfc:	89 e5                	mov    %esp,%ebp
f0103bfe:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103c01:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103c04:	eb 06                	jmp    f0103c0c <strcmp+0x11>
		p++, q++;
f0103c06:	83 c1 01             	add    $0x1,%ecx
f0103c09:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0103c0c:	0f b6 01             	movzbl (%ecx),%eax
f0103c0f:	84 c0                	test   %al,%al
f0103c11:	74 04                	je     f0103c17 <strcmp+0x1c>
f0103c13:	3a 02                	cmp    (%edx),%al
f0103c15:	74 ef                	je     f0103c06 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103c17:	0f b6 c0             	movzbl %al,%eax
f0103c1a:	0f b6 12             	movzbl (%edx),%edx
f0103c1d:	29 d0                	sub    %edx,%eax
}
f0103c1f:	5d                   	pop    %ebp
f0103c20:	c3                   	ret    

f0103c21 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103c21:	55                   	push   %ebp
f0103c22:	89 e5                	mov    %esp,%ebp
f0103c24:	53                   	push   %ebx
f0103c25:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c28:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103c2b:	89 c3                	mov    %eax,%ebx
f0103c2d:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0103c30:	eb 06                	jmp    f0103c38 <strncmp+0x17>
		n--, p++, q++;
f0103c32:	83 c0 01             	add    $0x1,%eax
f0103c35:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0103c38:	39 d8                	cmp    %ebx,%eax
f0103c3a:	74 15                	je     f0103c51 <strncmp+0x30>
f0103c3c:	0f b6 08             	movzbl (%eax),%ecx
f0103c3f:	84 c9                	test   %cl,%cl
f0103c41:	74 04                	je     f0103c47 <strncmp+0x26>
f0103c43:	3a 0a                	cmp    (%edx),%cl
f0103c45:	74 eb                	je     f0103c32 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103c47:	0f b6 00             	movzbl (%eax),%eax
f0103c4a:	0f b6 12             	movzbl (%edx),%edx
f0103c4d:	29 d0                	sub    %edx,%eax
f0103c4f:	eb 05                	jmp    f0103c56 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0103c51:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0103c56:	5b                   	pop    %ebx
f0103c57:	5d                   	pop    %ebp
f0103c58:	c3                   	ret    

f0103c59 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103c59:	55                   	push   %ebp
f0103c5a:	89 e5                	mov    %esp,%ebp
f0103c5c:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c5f:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103c63:	eb 07                	jmp    f0103c6c <strchr+0x13>
		if (*s == c)
f0103c65:	38 ca                	cmp    %cl,%dl
f0103c67:	74 0f                	je     f0103c78 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0103c69:	83 c0 01             	add    $0x1,%eax
f0103c6c:	0f b6 10             	movzbl (%eax),%edx
f0103c6f:	84 d2                	test   %dl,%dl
f0103c71:	75 f2                	jne    f0103c65 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0103c73:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103c78:	5d                   	pop    %ebp
f0103c79:	c3                   	ret    

f0103c7a <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103c7a:	55                   	push   %ebp
f0103c7b:	89 e5                	mov    %esp,%ebp
f0103c7d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c80:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103c84:	eb 03                	jmp    f0103c89 <strfind+0xf>
f0103c86:	83 c0 01             	add    $0x1,%eax
f0103c89:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0103c8c:	38 ca                	cmp    %cl,%dl
f0103c8e:	74 04                	je     f0103c94 <strfind+0x1a>
f0103c90:	84 d2                	test   %dl,%dl
f0103c92:	75 f2                	jne    f0103c86 <strfind+0xc>
			break;
	return (char *) s;
}
f0103c94:	5d                   	pop    %ebp
f0103c95:	c3                   	ret    

f0103c96 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103c96:	55                   	push   %ebp
f0103c97:	89 e5                	mov    %esp,%ebp
f0103c99:	57                   	push   %edi
f0103c9a:	56                   	push   %esi
f0103c9b:	53                   	push   %ebx
f0103c9c:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103c9f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0103ca2:	85 c9                	test   %ecx,%ecx
f0103ca4:	74 36                	je     f0103cdc <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103ca6:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103cac:	75 28                	jne    f0103cd6 <memset+0x40>
f0103cae:	f6 c1 03             	test   $0x3,%cl
f0103cb1:	75 23                	jne    f0103cd6 <memset+0x40>
		c &= 0xFF;
f0103cb3:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103cb7:	89 d3                	mov    %edx,%ebx
f0103cb9:	c1 e3 08             	shl    $0x8,%ebx
f0103cbc:	89 d6                	mov    %edx,%esi
f0103cbe:	c1 e6 18             	shl    $0x18,%esi
f0103cc1:	89 d0                	mov    %edx,%eax
f0103cc3:	c1 e0 10             	shl    $0x10,%eax
f0103cc6:	09 f0                	or     %esi,%eax
f0103cc8:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0103cca:	89 d8                	mov    %ebx,%eax
f0103ccc:	09 d0                	or     %edx,%eax
f0103cce:	c1 e9 02             	shr    $0x2,%ecx
f0103cd1:	fc                   	cld    
f0103cd2:	f3 ab                	rep stos %eax,%es:(%edi)
f0103cd4:	eb 06                	jmp    f0103cdc <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103cd6:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103cd9:	fc                   	cld    
f0103cda:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103cdc:	89 f8                	mov    %edi,%eax
f0103cde:	5b                   	pop    %ebx
f0103cdf:	5e                   	pop    %esi
f0103ce0:	5f                   	pop    %edi
f0103ce1:	5d                   	pop    %ebp
f0103ce2:	c3                   	ret    

f0103ce3 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103ce3:	55                   	push   %ebp
f0103ce4:	89 e5                	mov    %esp,%ebp
f0103ce6:	57                   	push   %edi
f0103ce7:	56                   	push   %esi
f0103ce8:	8b 45 08             	mov    0x8(%ebp),%eax
f0103ceb:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103cee:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103cf1:	39 c6                	cmp    %eax,%esi
f0103cf3:	73 35                	jae    f0103d2a <memmove+0x47>
f0103cf5:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103cf8:	39 d0                	cmp    %edx,%eax
f0103cfa:	73 2e                	jae    f0103d2a <memmove+0x47>
		s += n;
		d += n;
f0103cfc:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103cff:	89 d6                	mov    %edx,%esi
f0103d01:	09 fe                	or     %edi,%esi
f0103d03:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103d09:	75 13                	jne    f0103d1e <memmove+0x3b>
f0103d0b:	f6 c1 03             	test   $0x3,%cl
f0103d0e:	75 0e                	jne    f0103d1e <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0103d10:	83 ef 04             	sub    $0x4,%edi
f0103d13:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103d16:	c1 e9 02             	shr    $0x2,%ecx
f0103d19:	fd                   	std    
f0103d1a:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103d1c:	eb 09                	jmp    f0103d27 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0103d1e:	83 ef 01             	sub    $0x1,%edi
f0103d21:	8d 72 ff             	lea    -0x1(%edx),%esi
f0103d24:	fd                   	std    
f0103d25:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103d27:	fc                   	cld    
f0103d28:	eb 1d                	jmp    f0103d47 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103d2a:	89 f2                	mov    %esi,%edx
f0103d2c:	09 c2                	or     %eax,%edx
f0103d2e:	f6 c2 03             	test   $0x3,%dl
f0103d31:	75 0f                	jne    f0103d42 <memmove+0x5f>
f0103d33:	f6 c1 03             	test   $0x3,%cl
f0103d36:	75 0a                	jne    f0103d42 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0103d38:	c1 e9 02             	shr    $0x2,%ecx
f0103d3b:	89 c7                	mov    %eax,%edi
f0103d3d:	fc                   	cld    
f0103d3e:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103d40:	eb 05                	jmp    f0103d47 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0103d42:	89 c7                	mov    %eax,%edi
f0103d44:	fc                   	cld    
f0103d45:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103d47:	5e                   	pop    %esi
f0103d48:	5f                   	pop    %edi
f0103d49:	5d                   	pop    %ebp
f0103d4a:	c3                   	ret    

f0103d4b <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0103d4b:	55                   	push   %ebp
f0103d4c:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0103d4e:	ff 75 10             	pushl  0x10(%ebp)
f0103d51:	ff 75 0c             	pushl  0xc(%ebp)
f0103d54:	ff 75 08             	pushl  0x8(%ebp)
f0103d57:	e8 87 ff ff ff       	call   f0103ce3 <memmove>
}
f0103d5c:	c9                   	leave  
f0103d5d:	c3                   	ret    

f0103d5e <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103d5e:	55                   	push   %ebp
f0103d5f:	89 e5                	mov    %esp,%ebp
f0103d61:	56                   	push   %esi
f0103d62:	53                   	push   %ebx
f0103d63:	8b 45 08             	mov    0x8(%ebp),%eax
f0103d66:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103d69:	89 c6                	mov    %eax,%esi
f0103d6b:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103d6e:	eb 1a                	jmp    f0103d8a <memcmp+0x2c>
		if (*s1 != *s2)
f0103d70:	0f b6 08             	movzbl (%eax),%ecx
f0103d73:	0f b6 1a             	movzbl (%edx),%ebx
f0103d76:	38 d9                	cmp    %bl,%cl
f0103d78:	74 0a                	je     f0103d84 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0103d7a:	0f b6 c1             	movzbl %cl,%eax
f0103d7d:	0f b6 db             	movzbl %bl,%ebx
f0103d80:	29 d8                	sub    %ebx,%eax
f0103d82:	eb 0f                	jmp    f0103d93 <memcmp+0x35>
		s1++, s2++;
f0103d84:	83 c0 01             	add    $0x1,%eax
f0103d87:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103d8a:	39 f0                	cmp    %esi,%eax
f0103d8c:	75 e2                	jne    f0103d70 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0103d8e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103d93:	5b                   	pop    %ebx
f0103d94:	5e                   	pop    %esi
f0103d95:	5d                   	pop    %ebp
f0103d96:	c3                   	ret    

f0103d97 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103d97:	55                   	push   %ebp
f0103d98:	89 e5                	mov    %esp,%ebp
f0103d9a:	53                   	push   %ebx
f0103d9b:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0103d9e:	89 c1                	mov    %eax,%ecx
f0103da0:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0103da3:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103da7:	eb 0a                	jmp    f0103db3 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103da9:	0f b6 10             	movzbl (%eax),%edx
f0103dac:	39 da                	cmp    %ebx,%edx
f0103dae:	74 07                	je     f0103db7 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103db0:	83 c0 01             	add    $0x1,%eax
f0103db3:	39 c8                	cmp    %ecx,%eax
f0103db5:	72 f2                	jb     f0103da9 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0103db7:	5b                   	pop    %ebx
f0103db8:	5d                   	pop    %ebp
f0103db9:	c3                   	ret    

f0103dba <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103dba:	55                   	push   %ebp
f0103dbb:	89 e5                	mov    %esp,%ebp
f0103dbd:	57                   	push   %edi
f0103dbe:	56                   	push   %esi
f0103dbf:	53                   	push   %ebx
f0103dc0:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103dc3:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103dc6:	eb 03                	jmp    f0103dcb <strtol+0x11>
		s++;
f0103dc8:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103dcb:	0f b6 01             	movzbl (%ecx),%eax
f0103dce:	3c 20                	cmp    $0x20,%al
f0103dd0:	74 f6                	je     f0103dc8 <strtol+0xe>
f0103dd2:	3c 09                	cmp    $0x9,%al
f0103dd4:	74 f2                	je     f0103dc8 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0103dd6:	3c 2b                	cmp    $0x2b,%al
f0103dd8:	75 0a                	jne    f0103de4 <strtol+0x2a>
		s++;
f0103dda:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0103ddd:	bf 00 00 00 00       	mov    $0x0,%edi
f0103de2:	eb 11                	jmp    f0103df5 <strtol+0x3b>
f0103de4:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0103de9:	3c 2d                	cmp    $0x2d,%al
f0103deb:	75 08                	jne    f0103df5 <strtol+0x3b>
		s++, neg = 1;
f0103ded:	83 c1 01             	add    $0x1,%ecx
f0103df0:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103df5:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0103dfb:	75 15                	jne    f0103e12 <strtol+0x58>
f0103dfd:	80 39 30             	cmpb   $0x30,(%ecx)
f0103e00:	75 10                	jne    f0103e12 <strtol+0x58>
f0103e02:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0103e06:	75 7c                	jne    f0103e84 <strtol+0xca>
		s += 2, base = 16;
f0103e08:	83 c1 02             	add    $0x2,%ecx
f0103e0b:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103e10:	eb 16                	jmp    f0103e28 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0103e12:	85 db                	test   %ebx,%ebx
f0103e14:	75 12                	jne    f0103e28 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103e16:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103e1b:	80 39 30             	cmpb   $0x30,(%ecx)
f0103e1e:	75 08                	jne    f0103e28 <strtol+0x6e>
		s++, base = 8;
f0103e20:	83 c1 01             	add    $0x1,%ecx
f0103e23:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0103e28:	b8 00 00 00 00       	mov    $0x0,%eax
f0103e2d:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0103e30:	0f b6 11             	movzbl (%ecx),%edx
f0103e33:	8d 72 d0             	lea    -0x30(%edx),%esi
f0103e36:	89 f3                	mov    %esi,%ebx
f0103e38:	80 fb 09             	cmp    $0x9,%bl
f0103e3b:	77 08                	ja     f0103e45 <strtol+0x8b>
			dig = *s - '0';
f0103e3d:	0f be d2             	movsbl %dl,%edx
f0103e40:	83 ea 30             	sub    $0x30,%edx
f0103e43:	eb 22                	jmp    f0103e67 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0103e45:	8d 72 9f             	lea    -0x61(%edx),%esi
f0103e48:	89 f3                	mov    %esi,%ebx
f0103e4a:	80 fb 19             	cmp    $0x19,%bl
f0103e4d:	77 08                	ja     f0103e57 <strtol+0x9d>
			dig = *s - 'a' + 10;
f0103e4f:	0f be d2             	movsbl %dl,%edx
f0103e52:	83 ea 57             	sub    $0x57,%edx
f0103e55:	eb 10                	jmp    f0103e67 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0103e57:	8d 72 bf             	lea    -0x41(%edx),%esi
f0103e5a:	89 f3                	mov    %esi,%ebx
f0103e5c:	80 fb 19             	cmp    $0x19,%bl
f0103e5f:	77 16                	ja     f0103e77 <strtol+0xbd>
			dig = *s - 'A' + 10;
f0103e61:	0f be d2             	movsbl %dl,%edx
f0103e64:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0103e67:	3b 55 10             	cmp    0x10(%ebp),%edx
f0103e6a:	7d 0b                	jge    f0103e77 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0103e6c:	83 c1 01             	add    $0x1,%ecx
f0103e6f:	0f af 45 10          	imul   0x10(%ebp),%eax
f0103e73:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0103e75:	eb b9                	jmp    f0103e30 <strtol+0x76>

	if (endptr)
f0103e77:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103e7b:	74 0d                	je     f0103e8a <strtol+0xd0>
		*endptr = (char *) s;
f0103e7d:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103e80:	89 0e                	mov    %ecx,(%esi)
f0103e82:	eb 06                	jmp    f0103e8a <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103e84:	85 db                	test   %ebx,%ebx
f0103e86:	74 98                	je     f0103e20 <strtol+0x66>
f0103e88:	eb 9e                	jmp    f0103e28 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0103e8a:	89 c2                	mov    %eax,%edx
f0103e8c:	f7 da                	neg    %edx
f0103e8e:	85 ff                	test   %edi,%edi
f0103e90:	0f 45 c2             	cmovne %edx,%eax
}
f0103e93:	5b                   	pop    %ebx
f0103e94:	5e                   	pop    %esi
f0103e95:	5f                   	pop    %edi
f0103e96:	5d                   	pop    %ebp
f0103e97:	c3                   	ret    
f0103e98:	66 90                	xchg   %ax,%ax
f0103e9a:	66 90                	xchg   %ax,%ax
f0103e9c:	66 90                	xchg   %ax,%ax
f0103e9e:	66 90                	xchg   %ax,%ax

f0103ea0 <__udivdi3>:
f0103ea0:	55                   	push   %ebp
f0103ea1:	57                   	push   %edi
f0103ea2:	56                   	push   %esi
f0103ea3:	53                   	push   %ebx
f0103ea4:	83 ec 1c             	sub    $0x1c,%esp
f0103ea7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f0103eab:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f0103eaf:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0103eb3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103eb7:	85 f6                	test   %esi,%esi
f0103eb9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103ebd:	89 ca                	mov    %ecx,%edx
f0103ebf:	89 f8                	mov    %edi,%eax
f0103ec1:	75 3d                	jne    f0103f00 <__udivdi3+0x60>
f0103ec3:	39 cf                	cmp    %ecx,%edi
f0103ec5:	0f 87 c5 00 00 00    	ja     f0103f90 <__udivdi3+0xf0>
f0103ecb:	85 ff                	test   %edi,%edi
f0103ecd:	89 fd                	mov    %edi,%ebp
f0103ecf:	75 0b                	jne    f0103edc <__udivdi3+0x3c>
f0103ed1:	b8 01 00 00 00       	mov    $0x1,%eax
f0103ed6:	31 d2                	xor    %edx,%edx
f0103ed8:	f7 f7                	div    %edi
f0103eda:	89 c5                	mov    %eax,%ebp
f0103edc:	89 c8                	mov    %ecx,%eax
f0103ede:	31 d2                	xor    %edx,%edx
f0103ee0:	f7 f5                	div    %ebp
f0103ee2:	89 c1                	mov    %eax,%ecx
f0103ee4:	89 d8                	mov    %ebx,%eax
f0103ee6:	89 cf                	mov    %ecx,%edi
f0103ee8:	f7 f5                	div    %ebp
f0103eea:	89 c3                	mov    %eax,%ebx
f0103eec:	89 d8                	mov    %ebx,%eax
f0103eee:	89 fa                	mov    %edi,%edx
f0103ef0:	83 c4 1c             	add    $0x1c,%esp
f0103ef3:	5b                   	pop    %ebx
f0103ef4:	5e                   	pop    %esi
f0103ef5:	5f                   	pop    %edi
f0103ef6:	5d                   	pop    %ebp
f0103ef7:	c3                   	ret    
f0103ef8:	90                   	nop
f0103ef9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103f00:	39 ce                	cmp    %ecx,%esi
f0103f02:	77 74                	ja     f0103f78 <__udivdi3+0xd8>
f0103f04:	0f bd fe             	bsr    %esi,%edi
f0103f07:	83 f7 1f             	xor    $0x1f,%edi
f0103f0a:	0f 84 98 00 00 00    	je     f0103fa8 <__udivdi3+0x108>
f0103f10:	bb 20 00 00 00       	mov    $0x20,%ebx
f0103f15:	89 f9                	mov    %edi,%ecx
f0103f17:	89 c5                	mov    %eax,%ebp
f0103f19:	29 fb                	sub    %edi,%ebx
f0103f1b:	d3 e6                	shl    %cl,%esi
f0103f1d:	89 d9                	mov    %ebx,%ecx
f0103f1f:	d3 ed                	shr    %cl,%ebp
f0103f21:	89 f9                	mov    %edi,%ecx
f0103f23:	d3 e0                	shl    %cl,%eax
f0103f25:	09 ee                	or     %ebp,%esi
f0103f27:	89 d9                	mov    %ebx,%ecx
f0103f29:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103f2d:	89 d5                	mov    %edx,%ebp
f0103f2f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103f33:	d3 ed                	shr    %cl,%ebp
f0103f35:	89 f9                	mov    %edi,%ecx
f0103f37:	d3 e2                	shl    %cl,%edx
f0103f39:	89 d9                	mov    %ebx,%ecx
f0103f3b:	d3 e8                	shr    %cl,%eax
f0103f3d:	09 c2                	or     %eax,%edx
f0103f3f:	89 d0                	mov    %edx,%eax
f0103f41:	89 ea                	mov    %ebp,%edx
f0103f43:	f7 f6                	div    %esi
f0103f45:	89 d5                	mov    %edx,%ebp
f0103f47:	89 c3                	mov    %eax,%ebx
f0103f49:	f7 64 24 0c          	mull   0xc(%esp)
f0103f4d:	39 d5                	cmp    %edx,%ebp
f0103f4f:	72 10                	jb     f0103f61 <__udivdi3+0xc1>
f0103f51:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103f55:	89 f9                	mov    %edi,%ecx
f0103f57:	d3 e6                	shl    %cl,%esi
f0103f59:	39 c6                	cmp    %eax,%esi
f0103f5b:	73 07                	jae    f0103f64 <__udivdi3+0xc4>
f0103f5d:	39 d5                	cmp    %edx,%ebp
f0103f5f:	75 03                	jne    f0103f64 <__udivdi3+0xc4>
f0103f61:	83 eb 01             	sub    $0x1,%ebx
f0103f64:	31 ff                	xor    %edi,%edi
f0103f66:	89 d8                	mov    %ebx,%eax
f0103f68:	89 fa                	mov    %edi,%edx
f0103f6a:	83 c4 1c             	add    $0x1c,%esp
f0103f6d:	5b                   	pop    %ebx
f0103f6e:	5e                   	pop    %esi
f0103f6f:	5f                   	pop    %edi
f0103f70:	5d                   	pop    %ebp
f0103f71:	c3                   	ret    
f0103f72:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103f78:	31 ff                	xor    %edi,%edi
f0103f7a:	31 db                	xor    %ebx,%ebx
f0103f7c:	89 d8                	mov    %ebx,%eax
f0103f7e:	89 fa                	mov    %edi,%edx
f0103f80:	83 c4 1c             	add    $0x1c,%esp
f0103f83:	5b                   	pop    %ebx
f0103f84:	5e                   	pop    %esi
f0103f85:	5f                   	pop    %edi
f0103f86:	5d                   	pop    %ebp
f0103f87:	c3                   	ret    
f0103f88:	90                   	nop
f0103f89:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103f90:	89 d8                	mov    %ebx,%eax
f0103f92:	f7 f7                	div    %edi
f0103f94:	31 ff                	xor    %edi,%edi
f0103f96:	89 c3                	mov    %eax,%ebx
f0103f98:	89 d8                	mov    %ebx,%eax
f0103f9a:	89 fa                	mov    %edi,%edx
f0103f9c:	83 c4 1c             	add    $0x1c,%esp
f0103f9f:	5b                   	pop    %ebx
f0103fa0:	5e                   	pop    %esi
f0103fa1:	5f                   	pop    %edi
f0103fa2:	5d                   	pop    %ebp
f0103fa3:	c3                   	ret    
f0103fa4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103fa8:	39 ce                	cmp    %ecx,%esi
f0103faa:	72 0c                	jb     f0103fb8 <__udivdi3+0x118>
f0103fac:	31 db                	xor    %ebx,%ebx
f0103fae:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0103fb2:	0f 87 34 ff ff ff    	ja     f0103eec <__udivdi3+0x4c>
f0103fb8:	bb 01 00 00 00       	mov    $0x1,%ebx
f0103fbd:	e9 2a ff ff ff       	jmp    f0103eec <__udivdi3+0x4c>
f0103fc2:	66 90                	xchg   %ax,%ax
f0103fc4:	66 90                	xchg   %ax,%ax
f0103fc6:	66 90                	xchg   %ax,%ax
f0103fc8:	66 90                	xchg   %ax,%ax
f0103fca:	66 90                	xchg   %ax,%ax
f0103fcc:	66 90                	xchg   %ax,%ax
f0103fce:	66 90                	xchg   %ax,%ax

f0103fd0 <__umoddi3>:
f0103fd0:	55                   	push   %ebp
f0103fd1:	57                   	push   %edi
f0103fd2:	56                   	push   %esi
f0103fd3:	53                   	push   %ebx
f0103fd4:	83 ec 1c             	sub    $0x1c,%esp
f0103fd7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f0103fdb:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f0103fdf:	8b 74 24 34          	mov    0x34(%esp),%esi
f0103fe3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103fe7:	85 d2                	test   %edx,%edx
f0103fe9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0103fed:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103ff1:	89 f3                	mov    %esi,%ebx
f0103ff3:	89 3c 24             	mov    %edi,(%esp)
f0103ff6:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103ffa:	75 1c                	jne    f0104018 <__umoddi3+0x48>
f0103ffc:	39 f7                	cmp    %esi,%edi
f0103ffe:	76 50                	jbe    f0104050 <__umoddi3+0x80>
f0104000:	89 c8                	mov    %ecx,%eax
f0104002:	89 f2                	mov    %esi,%edx
f0104004:	f7 f7                	div    %edi
f0104006:	89 d0                	mov    %edx,%eax
f0104008:	31 d2                	xor    %edx,%edx
f010400a:	83 c4 1c             	add    $0x1c,%esp
f010400d:	5b                   	pop    %ebx
f010400e:	5e                   	pop    %esi
f010400f:	5f                   	pop    %edi
f0104010:	5d                   	pop    %ebp
f0104011:	c3                   	ret    
f0104012:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104018:	39 f2                	cmp    %esi,%edx
f010401a:	89 d0                	mov    %edx,%eax
f010401c:	77 52                	ja     f0104070 <__umoddi3+0xa0>
f010401e:	0f bd ea             	bsr    %edx,%ebp
f0104021:	83 f5 1f             	xor    $0x1f,%ebp
f0104024:	75 5a                	jne    f0104080 <__umoddi3+0xb0>
f0104026:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010402a:	0f 82 e0 00 00 00    	jb     f0104110 <__umoddi3+0x140>
f0104030:	39 0c 24             	cmp    %ecx,(%esp)
f0104033:	0f 86 d7 00 00 00    	jbe    f0104110 <__umoddi3+0x140>
f0104039:	8b 44 24 08          	mov    0x8(%esp),%eax
f010403d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0104041:	83 c4 1c             	add    $0x1c,%esp
f0104044:	5b                   	pop    %ebx
f0104045:	5e                   	pop    %esi
f0104046:	5f                   	pop    %edi
f0104047:	5d                   	pop    %ebp
f0104048:	c3                   	ret    
f0104049:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104050:	85 ff                	test   %edi,%edi
f0104052:	89 fd                	mov    %edi,%ebp
f0104054:	75 0b                	jne    f0104061 <__umoddi3+0x91>
f0104056:	b8 01 00 00 00       	mov    $0x1,%eax
f010405b:	31 d2                	xor    %edx,%edx
f010405d:	f7 f7                	div    %edi
f010405f:	89 c5                	mov    %eax,%ebp
f0104061:	89 f0                	mov    %esi,%eax
f0104063:	31 d2                	xor    %edx,%edx
f0104065:	f7 f5                	div    %ebp
f0104067:	89 c8                	mov    %ecx,%eax
f0104069:	f7 f5                	div    %ebp
f010406b:	89 d0                	mov    %edx,%eax
f010406d:	eb 99                	jmp    f0104008 <__umoddi3+0x38>
f010406f:	90                   	nop
f0104070:	89 c8                	mov    %ecx,%eax
f0104072:	89 f2                	mov    %esi,%edx
f0104074:	83 c4 1c             	add    $0x1c,%esp
f0104077:	5b                   	pop    %ebx
f0104078:	5e                   	pop    %esi
f0104079:	5f                   	pop    %edi
f010407a:	5d                   	pop    %ebp
f010407b:	c3                   	ret    
f010407c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104080:	8b 34 24             	mov    (%esp),%esi
f0104083:	bf 20 00 00 00       	mov    $0x20,%edi
f0104088:	89 e9                	mov    %ebp,%ecx
f010408a:	29 ef                	sub    %ebp,%edi
f010408c:	d3 e0                	shl    %cl,%eax
f010408e:	89 f9                	mov    %edi,%ecx
f0104090:	89 f2                	mov    %esi,%edx
f0104092:	d3 ea                	shr    %cl,%edx
f0104094:	89 e9                	mov    %ebp,%ecx
f0104096:	09 c2                	or     %eax,%edx
f0104098:	89 d8                	mov    %ebx,%eax
f010409a:	89 14 24             	mov    %edx,(%esp)
f010409d:	89 f2                	mov    %esi,%edx
f010409f:	d3 e2                	shl    %cl,%edx
f01040a1:	89 f9                	mov    %edi,%ecx
f01040a3:	89 54 24 04          	mov    %edx,0x4(%esp)
f01040a7:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01040ab:	d3 e8                	shr    %cl,%eax
f01040ad:	89 e9                	mov    %ebp,%ecx
f01040af:	89 c6                	mov    %eax,%esi
f01040b1:	d3 e3                	shl    %cl,%ebx
f01040b3:	89 f9                	mov    %edi,%ecx
f01040b5:	89 d0                	mov    %edx,%eax
f01040b7:	d3 e8                	shr    %cl,%eax
f01040b9:	89 e9                	mov    %ebp,%ecx
f01040bb:	09 d8                	or     %ebx,%eax
f01040bd:	89 d3                	mov    %edx,%ebx
f01040bf:	89 f2                	mov    %esi,%edx
f01040c1:	f7 34 24             	divl   (%esp)
f01040c4:	89 d6                	mov    %edx,%esi
f01040c6:	d3 e3                	shl    %cl,%ebx
f01040c8:	f7 64 24 04          	mull   0x4(%esp)
f01040cc:	39 d6                	cmp    %edx,%esi
f01040ce:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01040d2:	89 d1                	mov    %edx,%ecx
f01040d4:	89 c3                	mov    %eax,%ebx
f01040d6:	72 08                	jb     f01040e0 <__umoddi3+0x110>
f01040d8:	75 11                	jne    f01040eb <__umoddi3+0x11b>
f01040da:	39 44 24 08          	cmp    %eax,0x8(%esp)
f01040de:	73 0b                	jae    f01040eb <__umoddi3+0x11b>
f01040e0:	2b 44 24 04          	sub    0x4(%esp),%eax
f01040e4:	1b 14 24             	sbb    (%esp),%edx
f01040e7:	89 d1                	mov    %edx,%ecx
f01040e9:	89 c3                	mov    %eax,%ebx
f01040eb:	8b 54 24 08          	mov    0x8(%esp),%edx
f01040ef:	29 da                	sub    %ebx,%edx
f01040f1:	19 ce                	sbb    %ecx,%esi
f01040f3:	89 f9                	mov    %edi,%ecx
f01040f5:	89 f0                	mov    %esi,%eax
f01040f7:	d3 e0                	shl    %cl,%eax
f01040f9:	89 e9                	mov    %ebp,%ecx
f01040fb:	d3 ea                	shr    %cl,%edx
f01040fd:	89 e9                	mov    %ebp,%ecx
f01040ff:	d3 ee                	shr    %cl,%esi
f0104101:	09 d0                	or     %edx,%eax
f0104103:	89 f2                	mov    %esi,%edx
f0104105:	83 c4 1c             	add    $0x1c,%esp
f0104108:	5b                   	pop    %ebx
f0104109:	5e                   	pop    %esi
f010410a:	5f                   	pop    %edi
f010410b:	5d                   	pop    %ebp
f010410c:	c3                   	ret    
f010410d:	8d 76 00             	lea    0x0(%esi),%esi
f0104110:	29 f9                	sub    %edi,%ecx
f0104112:	19 d6                	sbb    %edx,%esi
f0104114:	89 74 24 04          	mov    %esi,0x4(%esp)
f0104118:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010411c:	e9 18 ff ff ff       	jmp    f0104039 <__umoddi3+0x69>
