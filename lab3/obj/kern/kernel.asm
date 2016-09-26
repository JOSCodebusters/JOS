
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
f0100015:	b8 00 40 11 00       	mov    $0x114000,%eax
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
f0100034:	bc 00 40 11 f0       	mov    $0xf0114000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


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
f0100046:	b8 70 69 11 f0       	mov    $0xf0116970,%eax
f010004b:	2d 00 63 11 f0       	sub    $0xf0116300,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 00 63 11 f0       	push   $0xf0116300
f0100058:	e8 de 31 00 00       	call   f010323b <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 88 04 00 00       	call   f01004ea <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 e0 36 10 f0       	push   $0xf01036e0
f010006f:	e8 ee 26 00 00       	call   f0102762 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 f0 0f 00 00       	call   f0101069 <mem_init>
f0100079:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010007c:	83 ec 0c             	sub    $0xc,%esp
f010007f:	6a 00                	push   $0x0
f0100081:	e8 10 07 00 00       	call   f0100796 <monitor>
f0100086:	83 c4 10             	add    $0x10,%esp
f0100089:	eb f1                	jmp    f010007c <i386_init+0x3c>

f010008b <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f010008b:	55                   	push   %ebp
f010008c:	89 e5                	mov    %esp,%ebp
f010008e:	56                   	push   %esi
f010008f:	53                   	push   %ebx
f0100090:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100093:	83 3d 60 69 11 f0 00 	cmpl   $0x0,0xf0116960
f010009a:	75 37                	jne    f01000d3 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f010009c:	89 35 60 69 11 f0    	mov    %esi,0xf0116960

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000a2:	fa                   	cli    
f01000a3:	fc                   	cld    

	va_start(ap, fmt);
f01000a4:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000a7:	83 ec 04             	sub    $0x4,%esp
f01000aa:	ff 75 0c             	pushl  0xc(%ebp)
f01000ad:	ff 75 08             	pushl  0x8(%ebp)
f01000b0:	68 fb 36 10 f0       	push   $0xf01036fb
f01000b5:	e8 a8 26 00 00       	call   f0102762 <cprintf>
	vcprintf(fmt, ap);
f01000ba:	83 c4 08             	add    $0x8,%esp
f01000bd:	53                   	push   %ebx
f01000be:	56                   	push   %esi
f01000bf:	e8 78 26 00 00       	call   f010273c <vcprintf>
	cprintf("\n");
f01000c4:	c7 04 24 2f 3f 10 f0 	movl   $0xf0103f2f,(%esp)
f01000cb:	e8 92 26 00 00       	call   f0102762 <cprintf>
	va_end(ap);
f01000d0:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000d3:	83 ec 0c             	sub    $0xc,%esp
f01000d6:	6a 00                	push   $0x0
f01000d8:	e8 b9 06 00 00       	call   f0100796 <monitor>
f01000dd:	83 c4 10             	add    $0x10,%esp
f01000e0:	eb f1                	jmp    f01000d3 <_panic+0x48>

f01000e2 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000e2:	55                   	push   %ebp
f01000e3:	89 e5                	mov    %esp,%ebp
f01000e5:	53                   	push   %ebx
f01000e6:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01000e9:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000ec:	ff 75 0c             	pushl  0xc(%ebp)
f01000ef:	ff 75 08             	pushl  0x8(%ebp)
f01000f2:	68 13 37 10 f0       	push   $0xf0103713
f01000f7:	e8 66 26 00 00       	call   f0102762 <cprintf>
	vcprintf(fmt, ap);
f01000fc:	83 c4 08             	add    $0x8,%esp
f01000ff:	53                   	push   %ebx
f0100100:	ff 75 10             	pushl  0x10(%ebp)
f0100103:	e8 34 26 00 00       	call   f010273c <vcprintf>
	cprintf("\n");
f0100108:	c7 04 24 2f 3f 10 f0 	movl   $0xf0103f2f,(%esp)
f010010f:	e8 4e 26 00 00       	call   f0102762 <cprintf>
	va_end(ap);
}
f0100114:	83 c4 10             	add    $0x10,%esp
f0100117:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010011a:	c9                   	leave  
f010011b:	c3                   	ret    

f010011c <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010011c:	55                   	push   %ebp
f010011d:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010011f:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100124:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100125:	a8 01                	test   $0x1,%al
f0100127:	74 0b                	je     f0100134 <serial_proc_data+0x18>
f0100129:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010012e:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010012f:	0f b6 c0             	movzbl %al,%eax
f0100132:	eb 05                	jmp    f0100139 <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100134:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100139:	5d                   	pop    %ebp
f010013a:	c3                   	ret    

f010013b <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010013b:	55                   	push   %ebp
f010013c:	89 e5                	mov    %esp,%ebp
f010013e:	53                   	push   %ebx
f010013f:	83 ec 04             	sub    $0x4,%esp
f0100142:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100144:	eb 2b                	jmp    f0100171 <cons_intr+0x36>
		if (c == 0)
f0100146:	85 c0                	test   %eax,%eax
f0100148:	74 27                	je     f0100171 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f010014a:	8b 0d 24 65 11 f0    	mov    0xf0116524,%ecx
f0100150:	8d 51 01             	lea    0x1(%ecx),%edx
f0100153:	89 15 24 65 11 f0    	mov    %edx,0xf0116524
f0100159:	88 81 20 63 11 f0    	mov    %al,-0xfee9ce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f010015f:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100165:	75 0a                	jne    f0100171 <cons_intr+0x36>
			cons.wpos = 0;
f0100167:	c7 05 24 65 11 f0 00 	movl   $0x0,0xf0116524
f010016e:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100171:	ff d3                	call   *%ebx
f0100173:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100176:	75 ce                	jne    f0100146 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f0100178:	83 c4 04             	add    $0x4,%esp
f010017b:	5b                   	pop    %ebx
f010017c:	5d                   	pop    %ebp
f010017d:	c3                   	ret    

f010017e <kbd_proc_data>:
f010017e:	ba 64 00 00 00       	mov    $0x64,%edx
f0100183:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f0100184:	a8 01                	test   $0x1,%al
f0100186:	0f 84 f0 00 00 00    	je     f010027c <kbd_proc_data+0xfe>
f010018c:	ba 60 00 00 00       	mov    $0x60,%edx
f0100191:	ec                   	in     (%dx),%al
f0100192:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f0100194:	3c e0                	cmp    $0xe0,%al
f0100196:	75 0d                	jne    f01001a5 <kbd_proc_data+0x27>
		// E0 escape character
		shift |= E0ESC;
f0100198:	83 0d 00 63 11 f0 40 	orl    $0x40,0xf0116300
		return 0;
f010019f:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01001a4:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001a5:	55                   	push   %ebp
f01001a6:	89 e5                	mov    %esp,%ebp
f01001a8:	53                   	push   %ebx
f01001a9:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001ac:	84 c0                	test   %al,%al
f01001ae:	79 36                	jns    f01001e6 <kbd_proc_data+0x68>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001b0:	8b 0d 00 63 11 f0    	mov    0xf0116300,%ecx
f01001b6:	89 cb                	mov    %ecx,%ebx
f01001b8:	83 e3 40             	and    $0x40,%ebx
f01001bb:	83 e0 7f             	and    $0x7f,%eax
f01001be:	85 db                	test   %ebx,%ebx
f01001c0:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001c3:	0f b6 d2             	movzbl %dl,%edx
f01001c6:	0f b6 82 80 38 10 f0 	movzbl -0xfefc780(%edx),%eax
f01001cd:	83 c8 40             	or     $0x40,%eax
f01001d0:	0f b6 c0             	movzbl %al,%eax
f01001d3:	f7 d0                	not    %eax
f01001d5:	21 c8                	and    %ecx,%eax
f01001d7:	a3 00 63 11 f0       	mov    %eax,0xf0116300
		return 0;
f01001dc:	b8 00 00 00 00       	mov    $0x0,%eax
f01001e1:	e9 9e 00 00 00       	jmp    f0100284 <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f01001e6:	8b 0d 00 63 11 f0    	mov    0xf0116300,%ecx
f01001ec:	f6 c1 40             	test   $0x40,%cl
f01001ef:	74 0e                	je     f01001ff <kbd_proc_data+0x81>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01001f1:	83 c8 80             	or     $0xffffff80,%eax
f01001f4:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f01001f6:	83 e1 bf             	and    $0xffffffbf,%ecx
f01001f9:	89 0d 00 63 11 f0    	mov    %ecx,0xf0116300
	}

	shift |= shiftcode[data];
f01001ff:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f0100202:	0f b6 82 80 38 10 f0 	movzbl -0xfefc780(%edx),%eax
f0100209:	0b 05 00 63 11 f0    	or     0xf0116300,%eax
f010020f:	0f b6 8a 80 37 10 f0 	movzbl -0xfefc880(%edx),%ecx
f0100216:	31 c8                	xor    %ecx,%eax
f0100218:	a3 00 63 11 f0       	mov    %eax,0xf0116300

	c = charcode[shift & (CTL | SHIFT)][data];
f010021d:	89 c1                	mov    %eax,%ecx
f010021f:	83 e1 03             	and    $0x3,%ecx
f0100222:	8b 0c 8d 60 37 10 f0 	mov    -0xfefc8a0(,%ecx,4),%ecx
f0100229:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f010022d:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100230:	a8 08                	test   $0x8,%al
f0100232:	74 1b                	je     f010024f <kbd_proc_data+0xd1>
		if ('a' <= c && c <= 'z')
f0100234:	89 da                	mov    %ebx,%edx
f0100236:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100239:	83 f9 19             	cmp    $0x19,%ecx
f010023c:	77 05                	ja     f0100243 <kbd_proc_data+0xc5>
			c += 'A' - 'a';
f010023e:	83 eb 20             	sub    $0x20,%ebx
f0100241:	eb 0c                	jmp    f010024f <kbd_proc_data+0xd1>
		else if ('A' <= c && c <= 'Z')
f0100243:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f0100246:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100249:	83 fa 19             	cmp    $0x19,%edx
f010024c:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010024f:	f7 d0                	not    %eax
f0100251:	a8 06                	test   $0x6,%al
f0100253:	75 2d                	jne    f0100282 <kbd_proc_data+0x104>
f0100255:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f010025b:	75 25                	jne    f0100282 <kbd_proc_data+0x104>
		cprintf("Rebooting!\n");
f010025d:	83 ec 0c             	sub    $0xc,%esp
f0100260:	68 2d 37 10 f0       	push   $0xf010372d
f0100265:	e8 f8 24 00 00       	call   f0102762 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010026a:	ba 92 00 00 00       	mov    $0x92,%edx
f010026f:	b8 03 00 00 00       	mov    $0x3,%eax
f0100274:	ee                   	out    %al,(%dx)
f0100275:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100278:	89 d8                	mov    %ebx,%eax
f010027a:	eb 08                	jmp    f0100284 <kbd_proc_data+0x106>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f010027c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100281:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100282:	89 d8                	mov    %ebx,%eax
}
f0100284:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100287:	c9                   	leave  
f0100288:	c3                   	ret    

f0100289 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100289:	55                   	push   %ebp
f010028a:	89 e5                	mov    %esp,%ebp
f010028c:	57                   	push   %edi
f010028d:	56                   	push   %esi
f010028e:	53                   	push   %ebx
f010028f:	83 ec 1c             	sub    $0x1c,%esp
f0100292:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f0100294:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100299:	be fd 03 00 00       	mov    $0x3fd,%esi
f010029e:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002a3:	eb 09                	jmp    f01002ae <cons_putc+0x25>
f01002a5:	89 ca                	mov    %ecx,%edx
f01002a7:	ec                   	in     (%dx),%al
f01002a8:	ec                   	in     (%dx),%al
f01002a9:	ec                   	in     (%dx),%al
f01002aa:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01002ab:	83 c3 01             	add    $0x1,%ebx
f01002ae:	89 f2                	mov    %esi,%edx
f01002b0:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002b1:	a8 20                	test   $0x20,%al
f01002b3:	75 08                	jne    f01002bd <cons_putc+0x34>
f01002b5:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002bb:	7e e8                	jle    f01002a5 <cons_putc+0x1c>
f01002bd:	89 f8                	mov    %edi,%eax
f01002bf:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002c2:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002c7:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002c8:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002cd:	be 79 03 00 00       	mov    $0x379,%esi
f01002d2:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002d7:	eb 09                	jmp    f01002e2 <cons_putc+0x59>
f01002d9:	89 ca                	mov    %ecx,%edx
f01002db:	ec                   	in     (%dx),%al
f01002dc:	ec                   	in     (%dx),%al
f01002dd:	ec                   	in     (%dx),%al
f01002de:	ec                   	in     (%dx),%al
f01002df:	83 c3 01             	add    $0x1,%ebx
f01002e2:	89 f2                	mov    %esi,%edx
f01002e4:	ec                   	in     (%dx),%al
f01002e5:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002eb:	7f 04                	jg     f01002f1 <cons_putc+0x68>
f01002ed:	84 c0                	test   %al,%al
f01002ef:	79 e8                	jns    f01002d9 <cons_putc+0x50>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002f1:	ba 78 03 00 00       	mov    $0x378,%edx
f01002f6:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f01002fa:	ee                   	out    %al,(%dx)
f01002fb:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100300:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100305:	ee                   	out    %al,(%dx)
f0100306:	b8 08 00 00 00       	mov    $0x8,%eax
f010030b:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010030c:	89 fa                	mov    %edi,%edx
f010030e:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100314:	89 f8                	mov    %edi,%eax
f0100316:	80 cc 07             	or     $0x7,%ah
f0100319:	85 d2                	test   %edx,%edx
f010031b:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f010031e:	89 f8                	mov    %edi,%eax
f0100320:	0f b6 c0             	movzbl %al,%eax
f0100323:	83 f8 09             	cmp    $0x9,%eax
f0100326:	74 74                	je     f010039c <cons_putc+0x113>
f0100328:	83 f8 09             	cmp    $0x9,%eax
f010032b:	7f 0a                	jg     f0100337 <cons_putc+0xae>
f010032d:	83 f8 08             	cmp    $0x8,%eax
f0100330:	74 14                	je     f0100346 <cons_putc+0xbd>
f0100332:	e9 99 00 00 00       	jmp    f01003d0 <cons_putc+0x147>
f0100337:	83 f8 0a             	cmp    $0xa,%eax
f010033a:	74 3a                	je     f0100376 <cons_putc+0xed>
f010033c:	83 f8 0d             	cmp    $0xd,%eax
f010033f:	74 3d                	je     f010037e <cons_putc+0xf5>
f0100341:	e9 8a 00 00 00       	jmp    f01003d0 <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f0100346:	0f b7 05 28 65 11 f0 	movzwl 0xf0116528,%eax
f010034d:	66 85 c0             	test   %ax,%ax
f0100350:	0f 84 e6 00 00 00    	je     f010043c <cons_putc+0x1b3>
			crt_pos--;
f0100356:	83 e8 01             	sub    $0x1,%eax
f0100359:	66 a3 28 65 11 f0    	mov    %ax,0xf0116528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010035f:	0f b7 c0             	movzwl %ax,%eax
f0100362:	66 81 e7 00 ff       	and    $0xff00,%di
f0100367:	83 cf 20             	or     $0x20,%edi
f010036a:	8b 15 2c 65 11 f0    	mov    0xf011652c,%edx
f0100370:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100374:	eb 78                	jmp    f01003ee <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100376:	66 83 05 28 65 11 f0 	addw   $0x50,0xf0116528
f010037d:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010037e:	0f b7 05 28 65 11 f0 	movzwl 0xf0116528,%eax
f0100385:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f010038b:	c1 e8 16             	shr    $0x16,%eax
f010038e:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100391:	c1 e0 04             	shl    $0x4,%eax
f0100394:	66 a3 28 65 11 f0    	mov    %ax,0xf0116528
f010039a:	eb 52                	jmp    f01003ee <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f010039c:	b8 20 00 00 00       	mov    $0x20,%eax
f01003a1:	e8 e3 fe ff ff       	call   f0100289 <cons_putc>
		cons_putc(' ');
f01003a6:	b8 20 00 00 00       	mov    $0x20,%eax
f01003ab:	e8 d9 fe ff ff       	call   f0100289 <cons_putc>
		cons_putc(' ');
f01003b0:	b8 20 00 00 00       	mov    $0x20,%eax
f01003b5:	e8 cf fe ff ff       	call   f0100289 <cons_putc>
		cons_putc(' ');
f01003ba:	b8 20 00 00 00       	mov    $0x20,%eax
f01003bf:	e8 c5 fe ff ff       	call   f0100289 <cons_putc>
		cons_putc(' ');
f01003c4:	b8 20 00 00 00       	mov    $0x20,%eax
f01003c9:	e8 bb fe ff ff       	call   f0100289 <cons_putc>
f01003ce:	eb 1e                	jmp    f01003ee <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01003d0:	0f b7 05 28 65 11 f0 	movzwl 0xf0116528,%eax
f01003d7:	8d 50 01             	lea    0x1(%eax),%edx
f01003da:	66 89 15 28 65 11 f0 	mov    %dx,0xf0116528
f01003e1:	0f b7 c0             	movzwl %ax,%eax
f01003e4:	8b 15 2c 65 11 f0    	mov    0xf011652c,%edx
f01003ea:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01003ee:	66 81 3d 28 65 11 f0 	cmpw   $0x7cf,0xf0116528
f01003f5:	cf 07 
f01003f7:	76 43                	jbe    f010043c <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01003f9:	a1 2c 65 11 f0       	mov    0xf011652c,%eax
f01003fe:	83 ec 04             	sub    $0x4,%esp
f0100401:	68 00 0f 00 00       	push   $0xf00
f0100406:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010040c:	52                   	push   %edx
f010040d:	50                   	push   %eax
f010040e:	e8 75 2e 00 00       	call   f0103288 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100413:	8b 15 2c 65 11 f0    	mov    0xf011652c,%edx
f0100419:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f010041f:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100425:	83 c4 10             	add    $0x10,%esp
f0100428:	66 c7 00 20 07       	movw   $0x720,(%eax)
f010042d:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100430:	39 d0                	cmp    %edx,%eax
f0100432:	75 f4                	jne    f0100428 <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100434:	66 83 2d 28 65 11 f0 	subw   $0x50,0xf0116528
f010043b:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010043c:	8b 0d 30 65 11 f0    	mov    0xf0116530,%ecx
f0100442:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100447:	89 ca                	mov    %ecx,%edx
f0100449:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010044a:	0f b7 1d 28 65 11 f0 	movzwl 0xf0116528,%ebx
f0100451:	8d 71 01             	lea    0x1(%ecx),%esi
f0100454:	89 d8                	mov    %ebx,%eax
f0100456:	66 c1 e8 08          	shr    $0x8,%ax
f010045a:	89 f2                	mov    %esi,%edx
f010045c:	ee                   	out    %al,(%dx)
f010045d:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100462:	89 ca                	mov    %ecx,%edx
f0100464:	ee                   	out    %al,(%dx)
f0100465:	89 d8                	mov    %ebx,%eax
f0100467:	89 f2                	mov    %esi,%edx
f0100469:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f010046a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010046d:	5b                   	pop    %ebx
f010046e:	5e                   	pop    %esi
f010046f:	5f                   	pop    %edi
f0100470:	5d                   	pop    %ebp
f0100471:	c3                   	ret    

f0100472 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100472:	80 3d 34 65 11 f0 00 	cmpb   $0x0,0xf0116534
f0100479:	74 11                	je     f010048c <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f010047b:	55                   	push   %ebp
f010047c:	89 e5                	mov    %esp,%ebp
f010047e:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f0100481:	b8 1c 01 10 f0       	mov    $0xf010011c,%eax
f0100486:	e8 b0 fc ff ff       	call   f010013b <cons_intr>
}
f010048b:	c9                   	leave  
f010048c:	f3 c3                	repz ret 

f010048e <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f010048e:	55                   	push   %ebp
f010048f:	89 e5                	mov    %esp,%ebp
f0100491:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100494:	b8 7e 01 10 f0       	mov    $0xf010017e,%eax
f0100499:	e8 9d fc ff ff       	call   f010013b <cons_intr>
}
f010049e:	c9                   	leave  
f010049f:	c3                   	ret    

f01004a0 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004a0:	55                   	push   %ebp
f01004a1:	89 e5                	mov    %esp,%ebp
f01004a3:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004a6:	e8 c7 ff ff ff       	call   f0100472 <serial_intr>
	kbd_intr();
f01004ab:	e8 de ff ff ff       	call   f010048e <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004b0:	a1 20 65 11 f0       	mov    0xf0116520,%eax
f01004b5:	3b 05 24 65 11 f0    	cmp    0xf0116524,%eax
f01004bb:	74 26                	je     f01004e3 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004bd:	8d 50 01             	lea    0x1(%eax),%edx
f01004c0:	89 15 20 65 11 f0    	mov    %edx,0xf0116520
f01004c6:	0f b6 88 20 63 11 f0 	movzbl -0xfee9ce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f01004cd:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f01004cf:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004d5:	75 11                	jne    f01004e8 <cons_getc+0x48>
			cons.rpos = 0;
f01004d7:	c7 05 20 65 11 f0 00 	movl   $0x0,0xf0116520
f01004de:	00 00 00 
f01004e1:	eb 05                	jmp    f01004e8 <cons_getc+0x48>
		return c;
	}
	return 0;
f01004e3:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01004e8:	c9                   	leave  
f01004e9:	c3                   	ret    

f01004ea <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01004ea:	55                   	push   %ebp
f01004eb:	89 e5                	mov    %esp,%ebp
f01004ed:	57                   	push   %edi
f01004ee:	56                   	push   %esi
f01004ef:	53                   	push   %ebx
f01004f0:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f01004f3:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f01004fa:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100501:	5a a5 
	if (*cp != 0xA55A) {
f0100503:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010050a:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010050e:	74 11                	je     f0100521 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100510:	c7 05 30 65 11 f0 b4 	movl   $0x3b4,0xf0116530
f0100517:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010051a:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f010051f:	eb 16                	jmp    f0100537 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100521:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100528:	c7 05 30 65 11 f0 d4 	movl   $0x3d4,0xf0116530
f010052f:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100532:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100537:	8b 3d 30 65 11 f0    	mov    0xf0116530,%edi
f010053d:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100542:	89 fa                	mov    %edi,%edx
f0100544:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100545:	8d 5f 01             	lea    0x1(%edi),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100548:	89 da                	mov    %ebx,%edx
f010054a:	ec                   	in     (%dx),%al
f010054b:	0f b6 c8             	movzbl %al,%ecx
f010054e:	c1 e1 08             	shl    $0x8,%ecx
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100551:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100556:	89 fa                	mov    %edi,%edx
f0100558:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100559:	89 da                	mov    %ebx,%edx
f010055b:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f010055c:	89 35 2c 65 11 f0    	mov    %esi,0xf011652c
	crt_pos = pos;
f0100562:	0f b6 c0             	movzbl %al,%eax
f0100565:	09 c8                	or     %ecx,%eax
f0100567:	66 a3 28 65 11 f0    	mov    %ax,0xf0116528
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010056d:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100572:	b8 00 00 00 00       	mov    $0x0,%eax
f0100577:	89 f2                	mov    %esi,%edx
f0100579:	ee                   	out    %al,(%dx)
f010057a:	ba fb 03 00 00       	mov    $0x3fb,%edx
f010057f:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100584:	ee                   	out    %al,(%dx)
f0100585:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f010058a:	b8 0c 00 00 00       	mov    $0xc,%eax
f010058f:	89 da                	mov    %ebx,%edx
f0100591:	ee                   	out    %al,(%dx)
f0100592:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100597:	b8 00 00 00 00       	mov    $0x0,%eax
f010059c:	ee                   	out    %al,(%dx)
f010059d:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005a2:	b8 03 00 00 00       	mov    $0x3,%eax
f01005a7:	ee                   	out    %al,(%dx)
f01005a8:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01005ad:	b8 00 00 00 00       	mov    $0x0,%eax
f01005b2:	ee                   	out    %al,(%dx)
f01005b3:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005b8:	b8 01 00 00 00       	mov    $0x1,%eax
f01005bd:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005be:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01005c3:	ec                   	in     (%dx),%al
f01005c4:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005c6:	3c ff                	cmp    $0xff,%al
f01005c8:	0f 95 05 34 65 11 f0 	setne  0xf0116534
f01005cf:	89 f2                	mov    %esi,%edx
f01005d1:	ec                   	in     (%dx),%al
f01005d2:	89 da                	mov    %ebx,%edx
f01005d4:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005d5:	80 f9 ff             	cmp    $0xff,%cl
f01005d8:	75 10                	jne    f01005ea <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f01005da:	83 ec 0c             	sub    $0xc,%esp
f01005dd:	68 39 37 10 f0       	push   $0xf0103739
f01005e2:	e8 7b 21 00 00       	call   f0102762 <cprintf>
f01005e7:	83 c4 10             	add    $0x10,%esp
}
f01005ea:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01005ed:	5b                   	pop    %ebx
f01005ee:	5e                   	pop    %esi
f01005ef:	5f                   	pop    %edi
f01005f0:	5d                   	pop    %ebp
f01005f1:	c3                   	ret    

f01005f2 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01005f2:	55                   	push   %ebp
f01005f3:	89 e5                	mov    %esp,%ebp
f01005f5:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01005f8:	8b 45 08             	mov    0x8(%ebp),%eax
f01005fb:	e8 89 fc ff ff       	call   f0100289 <cons_putc>
}
f0100600:	c9                   	leave  
f0100601:	c3                   	ret    

f0100602 <getchar>:

int
getchar(void)
{
f0100602:	55                   	push   %ebp
f0100603:	89 e5                	mov    %esp,%ebp
f0100605:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100608:	e8 93 fe ff ff       	call   f01004a0 <cons_getc>
f010060d:	85 c0                	test   %eax,%eax
f010060f:	74 f7                	je     f0100608 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100611:	c9                   	leave  
f0100612:	c3                   	ret    

f0100613 <iscons>:

int
iscons(int fdnum)
{
f0100613:	55                   	push   %ebp
f0100614:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100616:	b8 01 00 00 00       	mov    $0x1,%eax
f010061b:	5d                   	pop    %ebp
f010061c:	c3                   	ret    

f010061d <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010061d:	55                   	push   %ebp
f010061e:	89 e5                	mov    %esp,%ebp
f0100620:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100623:	68 80 39 10 f0       	push   $0xf0103980
f0100628:	68 9e 39 10 f0       	push   $0xf010399e
f010062d:	68 a3 39 10 f0       	push   $0xf01039a3
f0100632:	e8 2b 21 00 00       	call   f0102762 <cprintf>
f0100637:	83 c4 0c             	add    $0xc,%esp
f010063a:	68 3c 3a 10 f0       	push   $0xf0103a3c
f010063f:	68 ac 39 10 f0       	push   $0xf01039ac
f0100644:	68 a3 39 10 f0       	push   $0xf01039a3
f0100649:	e8 14 21 00 00       	call   f0102762 <cprintf>
f010064e:	83 c4 0c             	add    $0xc,%esp
f0100651:	68 64 3a 10 f0       	push   $0xf0103a64
f0100656:	68 b5 39 10 f0       	push   $0xf01039b5
f010065b:	68 a3 39 10 f0       	push   $0xf01039a3
f0100660:	e8 fd 20 00 00       	call   f0102762 <cprintf>
	return 0;
}
f0100665:	b8 00 00 00 00       	mov    $0x0,%eax
f010066a:	c9                   	leave  
f010066b:	c3                   	ret    

f010066c <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f010066c:	55                   	push   %ebp
f010066d:	89 e5                	mov    %esp,%ebp
f010066f:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100672:	68 bf 39 10 f0       	push   $0xf01039bf
f0100677:	e8 e6 20 00 00       	call   f0102762 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f010067c:	83 c4 08             	add    $0x8,%esp
f010067f:	68 0c 00 10 00       	push   $0x10000c
f0100684:	68 84 3a 10 f0       	push   $0xf0103a84
f0100689:	e8 d4 20 00 00       	call   f0102762 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010068e:	83 c4 0c             	add    $0xc,%esp
f0100691:	68 0c 00 10 00       	push   $0x10000c
f0100696:	68 0c 00 10 f0       	push   $0xf010000c
f010069b:	68 ac 3a 10 f0       	push   $0xf0103aac
f01006a0:	e8 bd 20 00 00       	call   f0102762 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006a5:	83 c4 0c             	add    $0xc,%esp
f01006a8:	68 c1 36 10 00       	push   $0x1036c1
f01006ad:	68 c1 36 10 f0       	push   $0xf01036c1
f01006b2:	68 d0 3a 10 f0       	push   $0xf0103ad0
f01006b7:	e8 a6 20 00 00       	call   f0102762 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006bc:	83 c4 0c             	add    $0xc,%esp
f01006bf:	68 00 63 11 00       	push   $0x116300
f01006c4:	68 00 63 11 f0       	push   $0xf0116300
f01006c9:	68 f4 3a 10 f0       	push   $0xf0103af4
f01006ce:	e8 8f 20 00 00       	call   f0102762 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006d3:	83 c4 0c             	add    $0xc,%esp
f01006d6:	68 70 69 11 00       	push   $0x116970
f01006db:	68 70 69 11 f0       	push   $0xf0116970
f01006e0:	68 18 3b 10 f0       	push   $0xf0103b18
f01006e5:	e8 78 20 00 00       	call   f0102762 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006ea:	b8 6f 6d 11 f0       	mov    $0xf0116d6f,%eax
f01006ef:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01006f4:	83 c4 08             	add    $0x8,%esp
f01006f7:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f01006fc:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100702:	85 c0                	test   %eax,%eax
f0100704:	0f 48 c2             	cmovs  %edx,%eax
f0100707:	c1 f8 0a             	sar    $0xa,%eax
f010070a:	50                   	push   %eax
f010070b:	68 3c 3b 10 f0       	push   $0xf0103b3c
f0100710:	e8 4d 20 00 00       	call   f0102762 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100715:	b8 00 00 00 00       	mov    $0x0,%eax
f010071a:	c9                   	leave  
f010071b:	c3                   	ret    

f010071c <mon_backtrace>:


int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010071c:	55                   	push   %ebp
f010071d:	89 e5                	mov    %esp,%ebp
f010071f:	56                   	push   %esi
f0100720:	53                   	push   %ebx
f0100721:	83 ec 2c             	sub    $0x2c,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f0100724:	89 eb                	mov    %ebp,%ebx
	struct Eipdebuginfo info;
	uint32_t* test_ebp = (uint32_t*) read_ebp();
	cprintf("Stack backtrace:\n");
f0100726:	68 d8 39 10 f0       	push   $0xf01039d8
f010072b:	e8 32 20 00 00       	call   f0102762 <cprintf>
	while (test_ebp)
f0100730:	83 c4 10             	add    $0x10,%esp
	 {
		cprintf("  ebp %08x eip %08x args %08x %08x %08x %08x %08x",test_ebp, test_ebp[1],test_ebp[2],test_ebp[3],test_ebp[4],test_ebp[5], test_ebp[6]);
		debuginfo_eip(test_ebp[1],&info);
f0100733:	8d 75 e0             	lea    -0x20(%ebp),%esi
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	struct Eipdebuginfo info;
	uint32_t* test_ebp = (uint32_t*) read_ebp();
	cprintf("Stack backtrace:\n");
	while (test_ebp)
f0100736:	eb 4e                	jmp    f0100786 <mon_backtrace+0x6a>
	 {
		cprintf("  ebp %08x eip %08x args %08x %08x %08x %08x %08x",test_ebp, test_ebp[1],test_ebp[2],test_ebp[3],test_ebp[4],test_ebp[5], test_ebp[6]);
f0100738:	ff 73 18             	pushl  0x18(%ebx)
f010073b:	ff 73 14             	pushl  0x14(%ebx)
f010073e:	ff 73 10             	pushl  0x10(%ebx)
f0100741:	ff 73 0c             	pushl  0xc(%ebx)
f0100744:	ff 73 08             	pushl  0x8(%ebx)
f0100747:	ff 73 04             	pushl  0x4(%ebx)
f010074a:	53                   	push   %ebx
f010074b:	68 68 3b 10 f0       	push   $0xf0103b68
f0100750:	e8 0d 20 00 00       	call   f0102762 <cprintf>
		debuginfo_eip(test_ebp[1],&info);
f0100755:	83 c4 18             	add    $0x18,%esp
f0100758:	56                   	push   %esi
f0100759:	ff 73 04             	pushl  0x4(%ebx)
f010075c:	e8 0b 21 00 00       	call   f010286c <debuginfo_eip>
		cprintf("\t    %s:%d: %.*s+%d\n",info.eip_file,info.eip_line,info.eip_fn_namelen,info.eip_fn_name,test_ebp[1] - info.eip_fn_addr);
f0100761:	83 c4 08             	add    $0x8,%esp
f0100764:	8b 43 04             	mov    0x4(%ebx),%eax
f0100767:	2b 45 f0             	sub    -0x10(%ebp),%eax
f010076a:	50                   	push   %eax
f010076b:	ff 75 e8             	pushl  -0x18(%ebp)
f010076e:	ff 75 ec             	pushl  -0x14(%ebp)
f0100771:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100774:	ff 75 e0             	pushl  -0x20(%ebp)
f0100777:	68 ea 39 10 f0       	push   $0xf01039ea
f010077c:	e8 e1 1f 00 00       	call   f0102762 <cprintf>
		test_ebp = (uint32_t*) *test_ebp;
f0100781:	8b 1b                	mov    (%ebx),%ebx
f0100783:	83 c4 20             	add    $0x20,%esp
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	struct Eipdebuginfo info;
	uint32_t* test_ebp = (uint32_t*) read_ebp();
	cprintf("Stack backtrace:\n");
	while (test_ebp)
f0100786:	85 db                	test   %ebx,%ebx
f0100788:	75 ae                	jne    f0100738 <mon_backtrace+0x1c>
		debuginfo_eip(test_ebp[1],&info);
		cprintf("\t    %s:%d: %.*s+%d\n",info.eip_file,info.eip_line,info.eip_fn_namelen,info.eip_fn_name,test_ebp[1] - info.eip_fn_addr);
		test_ebp = (uint32_t*) *test_ebp;
	}
return 0;
}
f010078a:	b8 00 00 00 00       	mov    $0x0,%eax
f010078f:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100792:	5b                   	pop    %ebx
f0100793:	5e                   	pop    %esi
f0100794:	5d                   	pop    %ebp
f0100795:	c3                   	ret    

f0100796 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100796:	55                   	push   %ebp
f0100797:	89 e5                	mov    %esp,%ebp
f0100799:	57                   	push   %edi
f010079a:	56                   	push   %esi
f010079b:	53                   	push   %ebx
f010079c:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010079f:	68 9c 3b 10 f0       	push   $0xf0103b9c
f01007a4:	e8 b9 1f 00 00       	call   f0102762 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007a9:	c7 04 24 c0 3b 10 f0 	movl   $0xf0103bc0,(%esp)
f01007b0:	e8 ad 1f 00 00       	call   f0102762 <cprintf>
f01007b5:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f01007b8:	83 ec 0c             	sub    $0xc,%esp
f01007bb:	68 ff 39 10 f0       	push   $0xf01039ff
f01007c0:	e8 1f 28 00 00       	call   f0102fe4 <readline>
f01007c5:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01007c7:	83 c4 10             	add    $0x10,%esp
f01007ca:	85 c0                	test   %eax,%eax
f01007cc:	74 ea                	je     f01007b8 <monitor+0x22>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01007ce:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01007d5:	be 00 00 00 00       	mov    $0x0,%esi
f01007da:	eb 0a                	jmp    f01007e6 <monitor+0x50>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01007dc:	c6 03 00             	movb   $0x0,(%ebx)
f01007df:	89 f7                	mov    %esi,%edi
f01007e1:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01007e4:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01007e6:	0f b6 03             	movzbl (%ebx),%eax
f01007e9:	84 c0                	test   %al,%al
f01007eb:	74 63                	je     f0100850 <monitor+0xba>
f01007ed:	83 ec 08             	sub    $0x8,%esp
f01007f0:	0f be c0             	movsbl %al,%eax
f01007f3:	50                   	push   %eax
f01007f4:	68 03 3a 10 f0       	push   $0xf0103a03
f01007f9:	e8 00 2a 00 00       	call   f01031fe <strchr>
f01007fe:	83 c4 10             	add    $0x10,%esp
f0100801:	85 c0                	test   %eax,%eax
f0100803:	75 d7                	jne    f01007dc <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f0100805:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100808:	74 46                	je     f0100850 <monitor+0xba>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f010080a:	83 fe 0f             	cmp    $0xf,%esi
f010080d:	75 14                	jne    f0100823 <monitor+0x8d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f010080f:	83 ec 08             	sub    $0x8,%esp
f0100812:	6a 10                	push   $0x10
f0100814:	68 08 3a 10 f0       	push   $0xf0103a08
f0100819:	e8 44 1f 00 00       	call   f0102762 <cprintf>
f010081e:	83 c4 10             	add    $0x10,%esp
f0100821:	eb 95                	jmp    f01007b8 <monitor+0x22>
			return 0;
		}
		argv[argc++] = buf;
f0100823:	8d 7e 01             	lea    0x1(%esi),%edi
f0100826:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f010082a:	eb 03                	jmp    f010082f <monitor+0x99>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f010082c:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010082f:	0f b6 03             	movzbl (%ebx),%eax
f0100832:	84 c0                	test   %al,%al
f0100834:	74 ae                	je     f01007e4 <monitor+0x4e>
f0100836:	83 ec 08             	sub    $0x8,%esp
f0100839:	0f be c0             	movsbl %al,%eax
f010083c:	50                   	push   %eax
f010083d:	68 03 3a 10 f0       	push   $0xf0103a03
f0100842:	e8 b7 29 00 00       	call   f01031fe <strchr>
f0100847:	83 c4 10             	add    $0x10,%esp
f010084a:	85 c0                	test   %eax,%eax
f010084c:	74 de                	je     f010082c <monitor+0x96>
f010084e:	eb 94                	jmp    f01007e4 <monitor+0x4e>
			buf++;
	}
	argv[argc] = 0;
f0100850:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100857:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100858:	85 f6                	test   %esi,%esi
f010085a:	0f 84 58 ff ff ff    	je     f01007b8 <monitor+0x22>
f0100860:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100865:	83 ec 08             	sub    $0x8,%esp
f0100868:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010086b:	ff 34 85 00 3c 10 f0 	pushl  -0xfefc400(,%eax,4)
f0100872:	ff 75 a8             	pushl  -0x58(%ebp)
f0100875:	e8 26 29 00 00       	call   f01031a0 <strcmp>
f010087a:	83 c4 10             	add    $0x10,%esp
f010087d:	85 c0                	test   %eax,%eax
f010087f:	75 21                	jne    f01008a2 <monitor+0x10c>
			return commands[i].func(argc, argv, tf);
f0100881:	83 ec 04             	sub    $0x4,%esp
f0100884:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100887:	ff 75 08             	pushl  0x8(%ebp)
f010088a:	8d 55 a8             	lea    -0x58(%ebp),%edx
f010088d:	52                   	push   %edx
f010088e:	56                   	push   %esi
f010088f:	ff 14 85 08 3c 10 f0 	call   *-0xfefc3f8(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100896:	83 c4 10             	add    $0x10,%esp
f0100899:	85 c0                	test   %eax,%eax
f010089b:	78 25                	js     f01008c2 <monitor+0x12c>
f010089d:	e9 16 ff ff ff       	jmp    f01007b8 <monitor+0x22>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f01008a2:	83 c3 01             	add    $0x1,%ebx
f01008a5:	83 fb 03             	cmp    $0x3,%ebx
f01008a8:	75 bb                	jne    f0100865 <monitor+0xcf>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008aa:	83 ec 08             	sub    $0x8,%esp
f01008ad:	ff 75 a8             	pushl  -0x58(%ebp)
f01008b0:	68 25 3a 10 f0       	push   $0xf0103a25
f01008b5:	e8 a8 1e 00 00       	call   f0102762 <cprintf>
f01008ba:	83 c4 10             	add    $0x10,%esp
f01008bd:	e9 f6 fe ff ff       	jmp    f01007b8 <monitor+0x22>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01008c2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01008c5:	5b                   	pop    %ebx
f01008c6:	5e                   	pop    %esi
f01008c7:	5f                   	pop    %edi
f01008c8:	5d                   	pop    %ebp
f01008c9:	c3                   	ret    

f01008ca <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f01008ca:	55                   	push   %ebp
f01008cb:	89 e5                	mov    %esp,%ebp
f01008cd:	56                   	push   %esi
f01008ce:	53                   	push   %ebx
f01008cf:	89 c6                	mov    %eax,%esi
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f01008d1:	83 3d 38 65 11 f0 00 	cmpl   $0x0,0xf0116538
f01008d8:	75 36                	jne    f0100910 <boot_alloc+0x46>
		extern char end[];
		cprintf("end=%x\n",end);
f01008da:	83 ec 08             	sub    $0x8,%esp
f01008dd:	68 70 69 11 f0       	push   $0xf0116970
f01008e2:	68 24 3c 10 f0       	push   $0xf0103c24
f01008e7:	e8 76 1e 00 00       	call   f0102762 <cprintf>
		cprintf("PGSIZE=%x\n",PGSIZE);
f01008ec:	83 c4 08             	add    $0x8,%esp
f01008ef:	68 00 10 00 00       	push   $0x1000
f01008f4:	68 2c 3c 10 f0       	push   $0xf0103c2c
f01008f9:	e8 64 1e 00 00       	call   f0102762 <cprintf>
		nextfree = ROUNDUP((char *) end, PGSIZE);
f01008fe:	b8 6f 79 11 f0       	mov    $0xf011796f,%eax
f0100903:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100908:	a3 38 65 11 f0       	mov    %eax,0xf0116538
f010090d:	83 c4 10             	add    $0x10,%esp
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	cprintf("n=%x\n",n);
f0100910:	83 ec 08             	sub    $0x8,%esp
f0100913:	56                   	push   %esi
f0100914:	68 37 3c 10 f0       	push   $0xf0103c37
f0100919:	e8 44 1e 00 00       	call   f0102762 <cprintf>
	cprintf("Initial=%x\n",nextfree);
f010091e:	83 c4 08             	add    $0x8,%esp
f0100921:	ff 35 38 65 11 f0    	pushl  0xf0116538
f0100927:	68 3d 3c 10 f0       	push   $0xf0103c3d
f010092c:	e8 31 1e 00 00       	call   f0102762 <cprintf>
	result=nextfree;
f0100931:	8b 1d 38 65 11 f0    	mov    0xf0116538,%ebx
	nextfree = ROUNDUP((char *) nextfree+n, PGSIZE);
f0100937:	8d 84 33 ff 0f 00 00 	lea    0xfff(%ebx,%esi,1),%eax
f010093e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100943:	a3 38 65 11 f0       	mov    %eax,0xf0116538
	cprintf("Final=%x\n",nextfree);
f0100948:	83 c4 08             	add    $0x8,%esp
f010094b:	50                   	push   %eax
f010094c:	68 49 3c 10 f0       	push   $0xf0103c49
f0100951:	e8 0c 1e 00 00       	call   f0102762 <cprintf>

	return result;
}
f0100956:	89 d8                	mov    %ebx,%eax
f0100958:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010095b:	5b                   	pop    %ebx
f010095c:	5e                   	pop    %esi
f010095d:	5d                   	pop    %ebp
f010095e:	c3                   	ret    

f010095f <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f010095f:	89 d1                	mov    %edx,%ecx
f0100961:	c1 e9 16             	shr    $0x16,%ecx
f0100964:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100967:	a8 01                	test   $0x1,%al
f0100969:	74 52                	je     f01009bd <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f010096b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100970:	89 c1                	mov    %eax,%ecx
f0100972:	c1 e9 0c             	shr    $0xc,%ecx
f0100975:	3b 0d 64 69 11 f0    	cmp    0xf0116964,%ecx
f010097b:	72 1b                	jb     f0100998 <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f010097d:	55                   	push   %ebp
f010097e:	89 e5                	mov    %esp,%ebp
f0100980:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100983:	50                   	push   %eax
f0100984:	68 64 3f 10 f0       	push   $0xf0103f64
f0100989:	68 e7 02 00 00       	push   $0x2e7
f010098e:	68 53 3c 10 f0       	push   $0xf0103c53
f0100993:	e8 f3 f6 ff ff       	call   f010008b <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100998:	c1 ea 0c             	shr    $0xc,%edx
f010099b:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f01009a1:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f01009a8:	89 c2                	mov    %eax,%edx
f01009aa:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f01009ad:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01009b2:	85 d2                	test   %edx,%edx
f01009b4:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f01009b9:	0f 44 c2             	cmove  %edx,%eax
f01009bc:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f01009bd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f01009c2:	c3                   	ret    

f01009c3 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f01009c3:	55                   	push   %ebp
f01009c4:	89 e5                	mov    %esp,%ebp
f01009c6:	57                   	push   %edi
f01009c7:	56                   	push   %esi
f01009c8:	53                   	push   %ebx
f01009c9:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f01009cc:	84 c0                	test   %al,%al
f01009ce:	0f 85 72 02 00 00    	jne    f0100c46 <check_page_free_list+0x283>
f01009d4:	e9 7f 02 00 00       	jmp    f0100c58 <check_page_free_list+0x295>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f01009d9:	83 ec 04             	sub    $0x4,%esp
f01009dc:	68 88 3f 10 f0       	push   $0xf0103f88
f01009e1:	68 2a 02 00 00       	push   $0x22a
f01009e6:	68 53 3c 10 f0       	push   $0xf0103c53
f01009eb:	e8 9b f6 ff ff       	call   f010008b <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f01009f0:	8d 55 d8             	lea    -0x28(%ebp),%edx
f01009f3:	89 55 e0             	mov    %edx,-0x20(%ebp)
f01009f6:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01009f9:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f01009fc:	89 c2                	mov    %eax,%edx
f01009fe:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f0100a04:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100a0a:	0f 95 c2             	setne  %dl
f0100a0d:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100a10:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100a14:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100a16:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a1a:	8b 00                	mov    (%eax),%eax
f0100a1c:	85 c0                	test   %eax,%eax
f0100a1e:	75 dc                	jne    f01009fc <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100a20:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a23:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100a29:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a2c:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100a2f:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100a31:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100a34:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a39:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a3e:	8b 1d 3c 65 11 f0    	mov    0xf011653c,%ebx
f0100a44:	eb 53                	jmp    f0100a99 <check_page_free_list+0xd6>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a46:	89 d8                	mov    %ebx,%eax
f0100a48:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0100a4e:	c1 f8 03             	sar    $0x3,%eax
f0100a51:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100a54:	89 c2                	mov    %eax,%edx
f0100a56:	c1 ea 16             	shr    $0x16,%edx
f0100a59:	39 f2                	cmp    %esi,%edx
f0100a5b:	73 3a                	jae    f0100a97 <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a5d:	89 c2                	mov    %eax,%edx
f0100a5f:	c1 ea 0c             	shr    $0xc,%edx
f0100a62:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f0100a68:	72 12                	jb     f0100a7c <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a6a:	50                   	push   %eax
f0100a6b:	68 64 3f 10 f0       	push   $0xf0103f64
f0100a70:	6a 52                	push   $0x52
f0100a72:	68 5f 3c 10 f0       	push   $0xf0103c5f
f0100a77:	e8 0f f6 ff ff       	call   f010008b <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100a7c:	83 ec 04             	sub    $0x4,%esp
f0100a7f:	68 80 00 00 00       	push   $0x80
f0100a84:	68 97 00 00 00       	push   $0x97
f0100a89:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100a8e:	50                   	push   %eax
f0100a8f:	e8 a7 27 00 00       	call   f010323b <memset>
f0100a94:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a97:	8b 1b                	mov    (%ebx),%ebx
f0100a99:	85 db                	test   %ebx,%ebx
f0100a9b:	75 a9                	jne    f0100a46 <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100a9d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100aa2:	e8 23 fe ff ff       	call   f01008ca <boot_alloc>
f0100aa7:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100aaa:	8b 15 3c 65 11 f0    	mov    0xf011653c,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100ab0:	8b 0d 6c 69 11 f0    	mov    0xf011696c,%ecx
		assert(pp < pages + npages);
f0100ab6:	a1 64 69 11 f0       	mov    0xf0116964,%eax
f0100abb:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100abe:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100ac1:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100ac4:	be 00 00 00 00       	mov    $0x0,%esi
f0100ac9:	89 5d d0             	mov    %ebx,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100acc:	e9 30 01 00 00       	jmp    f0100c01 <check_page_free_list+0x23e>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100ad1:	39 ca                	cmp    %ecx,%edx
f0100ad3:	73 19                	jae    f0100aee <check_page_free_list+0x12b>
f0100ad5:	68 6d 3c 10 f0       	push   $0xf0103c6d
f0100ada:	68 79 3c 10 f0       	push   $0xf0103c79
f0100adf:	68 44 02 00 00       	push   $0x244
f0100ae4:	68 53 3c 10 f0       	push   $0xf0103c53
f0100ae9:	e8 9d f5 ff ff       	call   f010008b <_panic>
		assert(pp < pages + npages);
f0100aee:	39 fa                	cmp    %edi,%edx
f0100af0:	72 19                	jb     f0100b0b <check_page_free_list+0x148>
f0100af2:	68 8e 3c 10 f0       	push   $0xf0103c8e
f0100af7:	68 79 3c 10 f0       	push   $0xf0103c79
f0100afc:	68 45 02 00 00       	push   $0x245
f0100b01:	68 53 3c 10 f0       	push   $0xf0103c53
f0100b06:	e8 80 f5 ff ff       	call   f010008b <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b0b:	89 d0                	mov    %edx,%eax
f0100b0d:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100b10:	a8 07                	test   $0x7,%al
f0100b12:	74 19                	je     f0100b2d <check_page_free_list+0x16a>
f0100b14:	68 ac 3f 10 f0       	push   $0xf0103fac
f0100b19:	68 79 3c 10 f0       	push   $0xf0103c79
f0100b1e:	68 46 02 00 00       	push   $0x246
f0100b23:	68 53 3c 10 f0       	push   $0xf0103c53
f0100b28:	e8 5e f5 ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b2d:	c1 f8 03             	sar    $0x3,%eax
f0100b30:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100b33:	85 c0                	test   %eax,%eax
f0100b35:	75 19                	jne    f0100b50 <check_page_free_list+0x18d>
f0100b37:	68 a2 3c 10 f0       	push   $0xf0103ca2
f0100b3c:	68 79 3c 10 f0       	push   $0xf0103c79
f0100b41:	68 49 02 00 00       	push   $0x249
f0100b46:	68 53 3c 10 f0       	push   $0xf0103c53
f0100b4b:	e8 3b f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100b50:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100b55:	75 19                	jne    f0100b70 <check_page_free_list+0x1ad>
f0100b57:	68 b3 3c 10 f0       	push   $0xf0103cb3
f0100b5c:	68 79 3c 10 f0       	push   $0xf0103c79
f0100b61:	68 4a 02 00 00       	push   $0x24a
f0100b66:	68 53 3c 10 f0       	push   $0xf0103c53
f0100b6b:	e8 1b f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100b70:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100b75:	75 19                	jne    f0100b90 <check_page_free_list+0x1cd>
f0100b77:	68 e0 3f 10 f0       	push   $0xf0103fe0
f0100b7c:	68 79 3c 10 f0       	push   $0xf0103c79
f0100b81:	68 4b 02 00 00       	push   $0x24b
f0100b86:	68 53 3c 10 f0       	push   $0xf0103c53
f0100b8b:	e8 fb f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100b90:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100b95:	75 19                	jne    f0100bb0 <check_page_free_list+0x1ed>
f0100b97:	68 cc 3c 10 f0       	push   $0xf0103ccc
f0100b9c:	68 79 3c 10 f0       	push   $0xf0103c79
f0100ba1:	68 4c 02 00 00       	push   $0x24c
f0100ba6:	68 53 3c 10 f0       	push   $0xf0103c53
f0100bab:	e8 db f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100bb0:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100bb5:	76 3f                	jbe    f0100bf6 <check_page_free_list+0x233>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100bb7:	89 c3                	mov    %eax,%ebx
f0100bb9:	c1 eb 0c             	shr    $0xc,%ebx
f0100bbc:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100bbf:	77 12                	ja     f0100bd3 <check_page_free_list+0x210>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100bc1:	50                   	push   %eax
f0100bc2:	68 64 3f 10 f0       	push   $0xf0103f64
f0100bc7:	6a 52                	push   $0x52
f0100bc9:	68 5f 3c 10 f0       	push   $0xf0103c5f
f0100bce:	e8 b8 f4 ff ff       	call   f010008b <_panic>
f0100bd3:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100bd8:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100bdb:	76 1e                	jbe    f0100bfb <check_page_free_list+0x238>
f0100bdd:	68 04 40 10 f0       	push   $0xf0104004
f0100be2:	68 79 3c 10 f0       	push   $0xf0103c79
f0100be7:	68 4d 02 00 00       	push   $0x24d
f0100bec:	68 53 3c 10 f0       	push   $0xf0103c53
f0100bf1:	e8 95 f4 ff ff       	call   f010008b <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100bf6:	83 c6 01             	add    $0x1,%esi
f0100bf9:	eb 04                	jmp    f0100bff <check_page_free_list+0x23c>
		else
			++nfree_extmem;
f0100bfb:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100bff:	8b 12                	mov    (%edx),%edx
f0100c01:	85 d2                	test   %edx,%edx
f0100c03:	0f 85 c8 fe ff ff    	jne    f0100ad1 <check_page_free_list+0x10e>
f0100c09:	8b 5d d0             	mov    -0x30(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100c0c:	85 f6                	test   %esi,%esi
f0100c0e:	7f 19                	jg     f0100c29 <check_page_free_list+0x266>
f0100c10:	68 e6 3c 10 f0       	push   $0xf0103ce6
f0100c15:	68 79 3c 10 f0       	push   $0xf0103c79
f0100c1a:	68 55 02 00 00       	push   $0x255
f0100c1f:	68 53 3c 10 f0       	push   $0xf0103c53
f0100c24:	e8 62 f4 ff ff       	call   f010008b <_panic>
	assert(nfree_extmem > 0);
f0100c29:	85 db                	test   %ebx,%ebx
f0100c2b:	7f 42                	jg     f0100c6f <check_page_free_list+0x2ac>
f0100c2d:	68 f8 3c 10 f0       	push   $0xf0103cf8
f0100c32:	68 79 3c 10 f0       	push   $0xf0103c79
f0100c37:	68 56 02 00 00       	push   $0x256
f0100c3c:	68 53 3c 10 f0       	push   $0xf0103c53
f0100c41:	e8 45 f4 ff ff       	call   f010008b <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100c46:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f0100c4b:	85 c0                	test   %eax,%eax
f0100c4d:	0f 85 9d fd ff ff    	jne    f01009f0 <check_page_free_list+0x2d>
f0100c53:	e9 81 fd ff ff       	jmp    f01009d9 <check_page_free_list+0x16>
f0100c58:	83 3d 3c 65 11 f0 00 	cmpl   $0x0,0xf011653c
f0100c5f:	0f 84 74 fd ff ff    	je     f01009d9 <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c65:	be 00 04 00 00       	mov    $0x400,%esi
f0100c6a:	e9 cf fd ff ff       	jmp    f0100a3e <check_page_free_list+0x7b>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0100c6f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100c72:	5b                   	pop    %ebx
f0100c73:	5e                   	pop    %esi
f0100c74:	5f                   	pop    %edi
f0100c75:	5d                   	pop    %ebp
f0100c76:	c3                   	ret    

f0100c77 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100c77:	55                   	push   %ebp
f0100c78:	89 e5                	mov    %esp,%ebp
f0100c7a:	56                   	push   %esi
f0100c7b:	53                   	push   %ebx
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	int keriolim=0;
	cprintf("npages=%d\n",npages);
f0100c7c:	83 ec 08             	sub    $0x8,%esp
f0100c7f:	ff 35 64 69 11 f0    	pushl  0xf0116964
f0100c85:	68 09 3d 10 f0       	push   $0xf0103d09
f0100c8a:	e8 d3 1a 00 00       	call   f0102762 <cprintf>
	cprintf("npages_basemem=%d\n",npages_basemem);
f0100c8f:	83 c4 08             	add    $0x8,%esp
f0100c92:	ff 35 40 65 11 f0    	pushl  0xf0116540
f0100c98:	68 14 3d 10 f0       	push   $0xf0103d14
f0100c9d:	e8 c0 1a 00 00       	call   f0102762 <cprintf>
	for (i = 1; i < npages_basemem; i++) {
f0100ca2:	8b 35 40 65 11 f0    	mov    0xf0116540,%esi
f0100ca8:	8b 1d 3c 65 11 f0    	mov    0xf011653c,%ebx
f0100cae:	83 c4 10             	add    $0x10,%esp
f0100cb1:	ba 00 00 00 00       	mov    $0x0,%edx
f0100cb6:	b8 01 00 00 00       	mov    $0x1,%eax
f0100cbb:	eb 27                	jmp    f0100ce4 <page_init+0x6d>
		pages[i].pp_ref = 0;
f0100cbd:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f0100cc4:	89 d1                	mov    %edx,%ecx
f0100cc6:	03 0d 6c 69 11 f0    	add    0xf011696c,%ecx
f0100ccc:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100cd2:	89 19                	mov    %ebx,(%ecx)
	// free pages!
	size_t i;
	int keriolim=0;
	cprintf("npages=%d\n",npages);
	cprintf("npages_basemem=%d\n",npages_basemem);
	for (i = 1; i < npages_basemem; i++) {
f0100cd4:	83 c0 01             	add    $0x1,%eax
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
f0100cd7:	89 d3                	mov    %edx,%ebx
f0100cd9:	03 1d 6c 69 11 f0    	add    0xf011696c,%ebx
f0100cdf:	ba 01 00 00 00       	mov    $0x1,%edx
	// free pages!
	size_t i;
	int keriolim=0;
	cprintf("npages=%d\n",npages);
	cprintf("npages_basemem=%d\n",npages_basemem);
	for (i = 1; i < npages_basemem; i++) {
f0100ce4:	39 f0                	cmp    %esi,%eax
f0100ce6:	72 d5                	jb     f0100cbd <page_init+0x46>
f0100ce8:	84 d2                	test   %dl,%dl
f0100cea:	74 06                	je     f0100cf2 <page_init+0x7b>
f0100cec:	89 1d 3c 65 11 f0    	mov    %ebx,0xf011653c
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
	
	keriolim = (int)ROUNDUP(((char *)pages + sizeof(struct PageInfo) * npages) - KERNBASE,PGSIZE)/PGSIZE;
f0100cf2:	a1 6c 69 11 f0       	mov    0xf011696c,%eax
f0100cf7:	8b 15 64 69 11 f0    	mov    0xf0116964,%edx
f0100cfd:	8d 84 d0 ff 0f 00 10 	lea    0x10000fff(%eax,%edx,8),%eax
f0100d04:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100d09:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0100d0f:	85 c0                	test   %eax,%eax
f0100d11:	0f 48 c2             	cmovs  %edx,%eax
f0100d14:	c1 f8 0c             	sar    $0xc,%eax
f0100d17:	89 c3                	mov    %eax,%ebx
	cprintf("keriolim=%d\n",keriolim);
f0100d19:	83 ec 08             	sub    $0x8,%esp
f0100d1c:	50                   	push   %eax
f0100d1d:	68 27 3d 10 f0       	push   $0xf0103d27
f0100d22:	e8 3b 1a 00 00       	call   f0102762 <cprintf>
	for (i = keriolim; i < npages; i++) {
f0100d27:	89 da                	mov    %ebx,%edx
f0100d29:	8b 35 3c 65 11 f0    	mov    0xf011653c,%esi
f0100d2f:	8d 04 dd 00 00 00 00 	lea    0x0(,%ebx,8),%eax
f0100d36:	83 c4 10             	add    $0x10,%esp
f0100d39:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100d3e:	eb 23                	jmp    f0100d63 <page_init+0xec>
		pages[i].pp_ref = 0;
f0100d40:	89 c1                	mov    %eax,%ecx
f0100d42:	03 0d 6c 69 11 f0    	add    0xf011696c,%ecx
f0100d48:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100d4e:	89 31                	mov    %esi,(%ecx)
		page_free_list = &pages[i];
f0100d50:	89 c6                	mov    %eax,%esi
f0100d52:	03 35 6c 69 11 f0    	add    0xf011696c,%esi
		page_free_list = &pages[i];
	}
	
	keriolim = (int)ROUNDUP(((char *)pages + sizeof(struct PageInfo) * npages) - KERNBASE,PGSIZE)/PGSIZE;
	cprintf("keriolim=%d\n",keriolim);
	for (i = keriolim; i < npages; i++) {
f0100d58:	83 c2 01             	add    $0x1,%edx
f0100d5b:	83 c0 08             	add    $0x8,%eax
f0100d5e:	b9 01 00 00 00       	mov    $0x1,%ecx
f0100d63:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f0100d69:	72 d5                	jb     f0100d40 <page_init+0xc9>
f0100d6b:	84 c9                	test   %cl,%cl
f0100d6d:	74 06                	je     f0100d75 <page_init+0xfe>
f0100d6f:	89 35 3c 65 11 f0    	mov    %esi,0xf011653c
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}

}
f0100d75:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100d78:	5b                   	pop    %ebx
f0100d79:	5e                   	pop    %esi
f0100d7a:	5d                   	pop    %ebp
f0100d7b:	c3                   	ret    

f0100d7c <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100d7c:	55                   	push   %ebp
f0100d7d:	89 e5                	mov    %esp,%ebp
f0100d7f:	53                   	push   %ebx
f0100d80:	83 ec 04             	sub    $0x4,%esp
	if(page_free_list != 0){
f0100d83:	8b 1d 3c 65 11 f0    	mov    0xf011653c,%ebx
f0100d89:	85 db                	test   %ebx,%ebx
f0100d8b:	74 58                	je     f0100de5 <page_alloc+0x69>
		struct PageInfo *result = page_free_list;
		page_free_list = page_free_list -> pp_link;
f0100d8d:	8b 03                	mov    (%ebx),%eax
f0100d8f:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
		if(alloc_flags & ALLOC_ZERO)
f0100d94:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100d98:	74 45                	je     f0100ddf <page_alloc+0x63>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100d9a:	89 d8                	mov    %ebx,%eax
f0100d9c:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0100da2:	c1 f8 03             	sar    $0x3,%eax
f0100da5:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100da8:	89 c2                	mov    %eax,%edx
f0100daa:	c1 ea 0c             	shr    $0xc,%edx
f0100dad:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f0100db3:	72 12                	jb     f0100dc7 <page_alloc+0x4b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100db5:	50                   	push   %eax
f0100db6:	68 64 3f 10 f0       	push   $0xf0103f64
f0100dbb:	6a 52                	push   $0x52
f0100dbd:	68 5f 3c 10 f0       	push   $0xf0103c5f
f0100dc2:	e8 c4 f2 ff ff       	call   f010008b <_panic>
			memset(page2kva(result), 0 , PGSIZE);
f0100dc7:	83 ec 04             	sub    $0x4,%esp
f0100dca:	68 00 10 00 00       	push   $0x1000
f0100dcf:	6a 00                	push   $0x0
f0100dd1:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100dd6:	50                   	push   %eax
f0100dd7:	e8 5f 24 00 00       	call   f010323b <memset>
f0100ddc:	83 c4 10             	add    $0x10,%esp
		result->pp_link = NULL;
f0100ddf:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
		return result;
	}
	else
		return NULL;
}
f0100de5:	89 d8                	mov    %ebx,%eax
f0100de7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100dea:	c9                   	leave  
f0100deb:	c3                   	ret    

f0100dec <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100dec:	55                   	push   %ebp
f0100ded:	89 e5                	mov    %esp,%ebp
f0100def:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	
	pp->pp_link = page_free_list;
f0100df2:	8b 15 3c 65 11 f0    	mov    0xf011653c,%edx
f0100df8:	89 10                	mov    %edx,(%eax)
    	page_free_list = pp;
f0100dfa:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
}
f0100dff:	5d                   	pop    %ebp
f0100e00:	c3                   	ret    

f0100e01 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100e01:	55                   	push   %ebp
f0100e02:	89 e5                	mov    %esp,%ebp
f0100e04:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100e07:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100e0b:	83 e8 01             	sub    $0x1,%eax
f0100e0e:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100e12:	66 85 c0             	test   %ax,%ax
f0100e15:	75 09                	jne    f0100e20 <page_decref+0x1f>
		page_free(pp);
f0100e17:	52                   	push   %edx
f0100e18:	e8 cf ff ff ff       	call   f0100dec <page_free>
f0100e1d:	83 c4 04             	add    $0x4,%esp
}
f0100e20:	c9                   	leave  
f0100e21:	c3                   	ret    

f0100e22 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100e22:	55                   	push   %ebp
f0100e23:	89 e5                	mov    %esp,%ebp
f0100e25:	56                   	push   %esi
f0100e26:	53                   	push   %ebx
f0100e27:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	struct PageInfo *outpg;
	pte_t *pgt;
	size_t pdi= PDX(va);
	pde_t pde= pgdir[pdi];
f0100e2a:	89 de                	mov    %ebx,%esi
f0100e2c:	c1 ee 16             	shr    $0x16,%esi
f0100e2f:	c1 e6 02             	shl    $0x2,%esi
f0100e32:	03 75 08             	add    0x8(%ebp),%esi
f0100e35:	8b 16                	mov    (%esi),%edx
	if((pde & PTE_P)!=0)
f0100e37:	f6 c2 01             	test   $0x1,%dl
f0100e3a:	74 30                	je     f0100e6c <pgdir_walk+0x4a>
	{
		pgt=KADDR(PTE_ADDR(pde));
f0100e3c:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e42:	89 d0                	mov    %edx,%eax
f0100e44:	c1 e8 0c             	shr    $0xc,%eax
f0100e47:	39 05 64 69 11 f0    	cmp    %eax,0xf0116964
f0100e4d:	77 15                	ja     f0100e64 <pgdir_walk+0x42>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e4f:	52                   	push   %edx
f0100e50:	68 64 3f 10 f0       	push   $0xf0103f64
f0100e55:	68 70 01 00 00       	push   $0x170
f0100e5a:	68 53 3c 10 f0       	push   $0xf0103c53
f0100e5f:	e8 27 f2 ff ff       	call   f010008b <_panic>
	return (void *)(pa + KERNBASE);
f0100e64:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0100e6a:	eb 60                	jmp    f0100ecc <pgdir_walk+0xaa>
	}
	else
	{
		if(!create)
f0100e6c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100e70:	74 68                	je     f0100eda <pgdir_walk+0xb8>
		{
			return NULL;
		}
		
		outpg=page_alloc(ALLOC_ZERO);
f0100e72:	83 ec 0c             	sub    $0xc,%esp
f0100e75:	6a 01                	push   $0x1
f0100e77:	e8 00 ff ff ff       	call   f0100d7c <page_alloc>
		
		if(!outpg)
f0100e7c:	83 c4 10             	add    $0x10,%esp
f0100e7f:	85 c0                	test   %eax,%eax
f0100e81:	74 5e                	je     f0100ee1 <pgdir_walk+0xbf>
		{
			return NULL;
		
		}
		
		pgdir[pdi]=page2pa(outpg) |PTE_U |PTE_W|PTE_P;
f0100e83:	89 c2                	mov    %eax,%edx
f0100e85:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f0100e8b:	c1 fa 03             	sar    $0x3,%edx
f0100e8e:	c1 e2 0c             	shl    $0xc,%edx
f0100e91:	83 ca 07             	or     $0x7,%edx
f0100e94:	89 16                	mov    %edx,(%esi)
		outpg->pp_ref++;
f0100e96:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100e9b:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0100ea1:	c1 f8 03             	sar    $0x3,%eax
f0100ea4:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ea7:	89 c2                	mov    %eax,%edx
f0100ea9:	c1 ea 0c             	shr    $0xc,%edx
f0100eac:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f0100eb2:	72 12                	jb     f0100ec6 <pgdir_walk+0xa4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100eb4:	50                   	push   %eax
f0100eb5:	68 64 3f 10 f0       	push   $0xf0103f64
f0100eba:	6a 52                	push   $0x52
f0100ebc:	68 5f 3c 10 f0       	push   $0xf0103c5f
f0100ec1:	e8 c5 f1 ff ff       	call   f010008b <_panic>
	return (void *)(pa + KERNBASE);
f0100ec6:	8d 90 00 00 00 f0    	lea    -0x10000000(%eax),%edx
			
	
	}
	size_t pti = PTX(va);
	
	return &pgt[pti];
f0100ecc:	c1 eb 0a             	shr    $0xa,%ebx
f0100ecf:	81 e3 fc 0f 00 00    	and    $0xffc,%ebx
f0100ed5:	8d 04 1a             	lea    (%edx,%ebx,1),%eax
f0100ed8:	eb 0c                	jmp    f0100ee6 <pgdir_walk+0xc4>
	}
	else
	{
		if(!create)
		{
			return NULL;
f0100eda:	b8 00 00 00 00       	mov    $0x0,%eax
f0100edf:	eb 05                	jmp    f0100ee6 <pgdir_walk+0xc4>
		
		outpg=page_alloc(ALLOC_ZERO);
		
		if(!outpg)
		{
			return NULL;
f0100ee1:	b8 00 00 00 00       	mov    $0x0,%eax
	
	}
	size_t pti = PTX(va);
	
	return &pgt[pti];
}
f0100ee6:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100ee9:	5b                   	pop    %ebx
f0100eea:	5e                   	pop    %esi
f0100eeb:	5d                   	pop    %ebp
f0100eec:	c3                   	ret    

f0100eed <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0100eed:	55                   	push   %ebp
f0100eee:	89 e5                	mov    %esp,%ebp
f0100ef0:	57                   	push   %edi
f0100ef1:	56                   	push   %esi
f0100ef2:	53                   	push   %ebx
f0100ef3:	83 ec 24             	sub    $0x24,%esp
f0100ef6:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100ef9:	89 d6                	mov    %edx,%esi
f0100efb:	89 cb                	mov    %ecx,%ebx
	cprintf("%x\n",size);
f0100efd:	51                   	push   %ecx
f0100efe:	68 33 3c 10 f0       	push   $0xf0103c33
f0100f03:	e8 5a 18 00 00       	call   f0102762 <cprintf>
f0100f08:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
f0100f0e:	8d 04 33             	lea    (%ebx,%esi,1),%eax
f0100f11:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	while (size >= PGSIZE) {
f0100f14:	83 c4 10             	add    $0x10,%esp
f0100f17:	89 f3                	mov    %esi,%ebx
f0100f19:	8b 7d 08             	mov    0x8(%ebp),%edi
f0100f1c:	29 f7                	sub    %esi,%edi
		pte_t *pte = pgdir_walk(pgdir, (void *)va, 1);

		*pte = pa | perm | PTE_P;
f0100f1e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100f21:	83 c8 01             	or     $0x1,%eax
f0100f24:	89 45 dc             	mov    %eax,-0x24(%ebp)
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	cprintf("%x\n",size);
	while (size >= PGSIZE) {
f0100f27:	eb 1c                	jmp    f0100f45 <boot_map_region+0x58>
		pte_t *pte = pgdir_walk(pgdir, (void *)va, 1);
f0100f29:	83 ec 04             	sub    $0x4,%esp
f0100f2c:	6a 01                	push   $0x1
f0100f2e:	53                   	push   %ebx
f0100f2f:	ff 75 e0             	pushl  -0x20(%ebp)
f0100f32:	e8 eb fe ff ff       	call   f0100e22 <pgdir_walk>

		*pte = pa | perm | PTE_P;
f0100f37:	0b 75 dc             	or     -0x24(%ebp),%esi
f0100f3a:	89 30                	mov    %esi,(%eax)

		va += PGSIZE;
f0100f3c:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0100f42:	83 c4 10             	add    $0x10,%esp
f0100f45:	8d 34 1f             	lea    (%edi,%ebx,1),%esi
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	cprintf("%x\n",size);
	while (size >= PGSIZE) {
f0100f48:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f0100f4b:	75 dc                	jne    f0100f29 <boot_map_region+0x3c>

		va += PGSIZE;
		pa += PGSIZE;
		size -= PGSIZE;
	}
}
f0100f4d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f50:	5b                   	pop    %ebx
f0100f51:	5e                   	pop    %esi
f0100f52:	5f                   	pop    %edi
f0100f53:	5d                   	pop    %ebp
f0100f54:	c3                   	ret    

f0100f55 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100f55:	55                   	push   %ebp
f0100f56:	89 e5                	mov    %esp,%ebp
f0100f58:	56                   	push   %esi
f0100f59:	53                   	push   %ebx
f0100f5a:	8b 45 08             	mov    0x8(%ebp),%eax
f0100f5d:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100f60:	8b 5d 10             	mov    0x10(%ebp),%ebx
	size_t pdi= PDX(va);
	pde_t pde= pgdir[pdi];
f0100f63:	89 d1                	mov    %edx,%ecx
f0100f65:	c1 e9 16             	shr    $0x16,%ecx
f0100f68:	8b 34 88             	mov    (%eax,%ecx,4),%esi
	pte_t *pte = pgdir_walk(pgdir, va, 0);
f0100f6b:	83 ec 04             	sub    $0x4,%esp
f0100f6e:	6a 00                	push   $0x0
f0100f70:	52                   	push   %edx
f0100f71:	50                   	push   %eax
f0100f72:	e8 ab fe ff ff       	call   f0100e22 <pgdir_walk>
	if((pde & PTE_P)==0)
f0100f77:	83 c4 10             	add    $0x10,%esp
f0100f7a:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0100f80:	74 32                	je     f0100fb4 <page_lookup+0x5f>
	{
		return NULL;
	}
	else if(pte_store)
f0100f82:	85 db                	test   %ebx,%ebx
f0100f84:	74 02                	je     f0100f88 <page_lookup+0x33>
		*pte_store= pte;
f0100f86:	89 03                	mov    %eax,(%ebx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f88:	8b 00                	mov    (%eax),%eax
f0100f8a:	c1 e8 0c             	shr    $0xc,%eax
f0100f8d:	3b 05 64 69 11 f0    	cmp    0xf0116964,%eax
f0100f93:	72 14                	jb     f0100fa9 <page_lookup+0x54>
		panic("pa2page called with invalid pa");
f0100f95:	83 ec 04             	sub    $0x4,%esp
f0100f98:	68 4c 40 10 f0       	push   $0xf010404c
f0100f9d:	6a 4b                	push   $0x4b
f0100f9f:	68 5f 3c 10 f0       	push   $0xf0103c5f
f0100fa4:	e8 e2 f0 ff ff       	call   f010008b <_panic>
	return &pages[PGNUM(pa)];
f0100fa9:	8b 15 6c 69 11 f0    	mov    0xf011696c,%edx
f0100faf:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	
	return pa2page(PTE_ADDR(*pte));
f0100fb2:	eb 05                	jmp    f0100fb9 <page_lookup+0x64>
	size_t pdi= PDX(va);
	pde_t pde= pgdir[pdi];
	pte_t *pte = pgdir_walk(pgdir, va, 0);
	if((pde & PTE_P)==0)
	{
		return NULL;
f0100fb4:	b8 00 00 00 00       	mov    $0x0,%eax
	}
	else if(pte_store)
		*pte_store= pte;
	
	return pa2page(PTE_ADDR(*pte));
}
f0100fb9:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100fbc:	5b                   	pop    %ebx
f0100fbd:	5e                   	pop    %esi
f0100fbe:	5d                   	pop    %ebp
f0100fbf:	c3                   	ret    

f0100fc0 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0100fc0:	55                   	push   %ebp
f0100fc1:	89 e5                	mov    %esp,%ebp
f0100fc3:	53                   	push   %ebx
f0100fc4:	83 ec 18             	sub    $0x18,%esp
f0100fc7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
		
	pte_t *pst;
	struct PageInfo *page=page_lookup(pgdir,va,&pst);
f0100fca:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100fcd:	50                   	push   %eax
f0100fce:	53                   	push   %ebx
f0100fcf:	ff 75 08             	pushl  0x8(%ebp)
f0100fd2:	e8 7e ff ff ff       	call   f0100f55 <page_lookup>
	if(!page || !(*pst & PTE_P))
f0100fd7:	83 c4 10             	add    $0x10,%esp
f0100fda:	85 c0                	test   %eax,%eax
f0100fdc:	74 20                	je     f0100ffe <page_remove+0x3e>
f0100fde:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0100fe1:	f6 02 01             	testb  $0x1,(%edx)
f0100fe4:	74 18                	je     f0100ffe <page_remove+0x3e>
	{
		return;
	}
	
	
	page_decref(page);
f0100fe6:	83 ec 0c             	sub    $0xc,%esp
f0100fe9:	50                   	push   %eax
f0100fea:	e8 12 fe ff ff       	call   f0100e01 <page_decref>
	*pst = 0;
f0100fef:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100ff2:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100ff8:	0f 01 3b             	invlpg (%ebx)
f0100ffb:	83 c4 10             	add    $0x10,%esp
	tlb_invalidate(pgdir,va);
	
	
}
f0100ffe:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101001:	c9                   	leave  
f0101002:	c3                   	ret    

f0101003 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0101003:	55                   	push   %ebp
f0101004:	89 e5                	mov    %esp,%ebp
f0101006:	57                   	push   %edi
f0101007:	56                   	push   %esi
f0101008:	53                   	push   %ebx
f0101009:	83 ec 10             	sub    $0x10,%esp
f010100c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010100f:	8b 7d 10             	mov    0x10(%ebp),%edi
	pte_t *pst;
	pst = pgdir_walk(pgdir, va, 1);
f0101012:	6a 01                	push   $0x1
f0101014:	57                   	push   %edi
f0101015:	ff 75 08             	pushl  0x8(%ebp)
f0101018:	e8 05 fe ff ff       	call   f0100e22 <pgdir_walk>
	if(!pst)
f010101d:	83 c4 10             	add    $0x10,%esp
f0101020:	85 c0                	test   %eax,%eax
f0101022:	74 38                	je     f010105c <page_insert+0x59>
f0101024:	89 c6                	mov    %eax,%esi
		return -E_NO_MEM;
	pp->pp_ref++;
f0101026:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	if(*pst & PTE_P)
f010102b:	f6 00 01             	testb  $0x1,(%eax)
f010102e:	74 0f                	je     f010103f <page_insert+0x3c>
	{
		page_remove(pgdir, va);
f0101030:	83 ec 08             	sub    $0x8,%esp
f0101033:	57                   	push   %edi
f0101034:	ff 75 08             	pushl  0x8(%ebp)
f0101037:	e8 84 ff ff ff       	call   f0100fc0 <page_remove>
f010103c:	83 c4 10             	add    $0x10,%esp
	}
	
	*pst=page2pa(pp) | perm |PTE_P;	
f010103f:	2b 1d 6c 69 11 f0    	sub    0xf011696c,%ebx
f0101045:	c1 fb 03             	sar    $0x3,%ebx
f0101048:	c1 e3 0c             	shl    $0xc,%ebx
f010104b:	8b 45 14             	mov    0x14(%ebp),%eax
f010104e:	83 c8 01             	or     $0x1,%eax
f0101051:	09 c3                	or     %eax,%ebx
f0101053:	89 1e                	mov    %ebx,(%esi)
	return 0;
f0101055:	b8 00 00 00 00       	mov    $0x0,%eax
f010105a:	eb 05                	jmp    f0101061 <page_insert+0x5e>
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
	pte_t *pst;
	pst = pgdir_walk(pgdir, va, 1);
	if(!pst)
		return -E_NO_MEM;
f010105c:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
		page_remove(pgdir, va);
	}
	
	*pst=page2pa(pp) | perm |PTE_P;	
	return 0;
}
f0101061:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101064:	5b                   	pop    %ebx
f0101065:	5e                   	pop    %esi
f0101066:	5f                   	pop    %edi
f0101067:	5d                   	pop    %ebp
f0101068:	c3                   	ret    

f0101069 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0101069:	55                   	push   %ebp
f010106a:	89 e5                	mov    %esp,%ebp
f010106c:	57                   	push   %edi
f010106d:	56                   	push   %esi
f010106e:	53                   	push   %ebx
f010106f:	83 ec 38             	sub    $0x38,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101072:	6a 15                	push   $0x15
f0101074:	e8 82 16 00 00       	call   f01026fb <mc146818_read>
f0101079:	89 c3                	mov    %eax,%ebx
f010107b:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f0101082:	e8 74 16 00 00       	call   f01026fb <mc146818_read>
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f0101087:	c1 e0 08             	shl    $0x8,%eax
f010108a:	09 d8                	or     %ebx,%eax
f010108c:	c1 e0 0a             	shl    $0xa,%eax
f010108f:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101095:	85 c0                	test   %eax,%eax
f0101097:	0f 48 c2             	cmovs  %edx,%eax
f010109a:	c1 f8 0c             	sar    $0xc,%eax
f010109d:	a3 40 65 11 f0       	mov    %eax,0xf0116540
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01010a2:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f01010a9:	e8 4d 16 00 00       	call   f01026fb <mc146818_read>
f01010ae:	89 c3                	mov    %eax,%ebx
f01010b0:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f01010b7:	e8 3f 16 00 00       	call   f01026fb <mc146818_read>
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f01010bc:	c1 e0 08             	shl    $0x8,%eax
f01010bf:	09 d8                	or     %ebx,%eax
f01010c1:	c1 e0 0a             	shl    $0xa,%eax
f01010c4:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01010ca:	83 c4 10             	add    $0x10,%esp
f01010cd:	85 c0                	test   %eax,%eax
f01010cf:	0f 48 c2             	cmovs  %edx,%eax
f01010d2:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f01010d5:	85 c0                	test   %eax,%eax
f01010d7:	74 0e                	je     f01010e7 <mem_init+0x7e>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f01010d9:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f01010df:	89 15 64 69 11 f0    	mov    %edx,0xf0116964
f01010e5:	eb 0c                	jmp    f01010f3 <mem_init+0x8a>
	else
		npages = npages_basemem;
f01010e7:	8b 15 40 65 11 f0    	mov    0xf0116540,%edx
f01010ed:	89 15 64 69 11 f0    	mov    %edx,0xf0116964

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01010f3:	c1 e0 0c             	shl    $0xc,%eax
f01010f6:	c1 e8 0a             	shr    $0xa,%eax
f01010f9:	50                   	push   %eax
f01010fa:	a1 40 65 11 f0       	mov    0xf0116540,%eax
f01010ff:	c1 e0 0c             	shl    $0xc,%eax
f0101102:	c1 e8 0a             	shr    $0xa,%eax
f0101105:	50                   	push   %eax
f0101106:	a1 64 69 11 f0       	mov    0xf0116964,%eax
f010110b:	c1 e0 0c             	shl    $0xc,%eax
f010110e:	c1 e8 0a             	shr    $0xa,%eax
f0101111:	50                   	push   %eax
f0101112:	68 6c 40 10 f0       	push   $0xf010406c
f0101117:	e8 46 16 00 00       	call   f0102762 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f010111c:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101121:	e8 a4 f7 ff ff       	call   f01008ca <boot_alloc>
f0101126:	a3 68 69 11 f0       	mov    %eax,0xf0116968
	memset(kern_pgdir, 0, PGSIZE);
f010112b:	83 c4 0c             	add    $0xc,%esp
f010112e:	68 00 10 00 00       	push   $0x1000
f0101133:	6a 00                	push   $0x0
f0101135:	50                   	push   %eax
f0101136:	e8 00 21 00 00       	call   f010323b <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f010113b:	a1 68 69 11 f0       	mov    0xf0116968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101140:	83 c4 10             	add    $0x10,%esp
f0101143:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101148:	77 15                	ja     f010115f <mem_init+0xf6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010114a:	50                   	push   %eax
f010114b:	68 a8 40 10 f0       	push   $0xf01040a8
f0101150:	68 92 00 00 00       	push   $0x92
f0101155:	68 53 3c 10 f0       	push   $0xf0103c53
f010115a:	e8 2c ef ff ff       	call   f010008b <_panic>
f010115f:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101165:	83 ca 05             	or     $0x5,%edx
f0101168:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages = (struct PageInfo *)boot_alloc(npages * sizeof(struct PageInfo));
f010116e:	a1 64 69 11 f0       	mov    0xf0116964,%eax
f0101173:	c1 e0 03             	shl    $0x3,%eax
f0101176:	e8 4f f7 ff ff       	call   f01008ca <boot_alloc>
f010117b:	a3 6c 69 11 f0       	mov    %eax,0xf011696c
	memset(pages, 0, npages * sizeof(struct PageInfo));
f0101180:	83 ec 04             	sub    $0x4,%esp
f0101183:	8b 0d 64 69 11 f0    	mov    0xf0116964,%ecx
f0101189:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f0101190:	52                   	push   %edx
f0101191:	6a 00                	push   $0x0
f0101193:	50                   	push   %eax
f0101194:	e8 a2 20 00 00       	call   f010323b <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101199:	e8 d9 fa ff ff       	call   f0100c77 <page_init>

	check_page_free_list(1);
f010119e:	b8 01 00 00 00       	mov    $0x1,%eax
f01011a3:	e8 1b f8 ff ff       	call   f01009c3 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f01011a8:	83 c4 10             	add    $0x10,%esp
f01011ab:	83 3d 6c 69 11 f0 00 	cmpl   $0x0,0xf011696c
f01011b2:	75 17                	jne    f01011cb <mem_init+0x162>
		panic("'pages' is a null pointer!");
f01011b4:	83 ec 04             	sub    $0x4,%esp
f01011b7:	68 34 3d 10 f0       	push   $0xf0103d34
f01011bc:	68 67 02 00 00       	push   $0x267
f01011c1:	68 53 3c 10 f0       	push   $0xf0103c53
f01011c6:	e8 c0 ee ff ff       	call   f010008b <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01011cb:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f01011d0:	bb 00 00 00 00       	mov    $0x0,%ebx
f01011d5:	eb 05                	jmp    f01011dc <mem_init+0x173>
		++nfree;
f01011d7:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01011da:	8b 00                	mov    (%eax),%eax
f01011dc:	85 c0                	test   %eax,%eax
f01011de:	75 f7                	jne    f01011d7 <mem_init+0x16e>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01011e0:	83 ec 0c             	sub    $0xc,%esp
f01011e3:	6a 00                	push   $0x0
f01011e5:	e8 92 fb ff ff       	call   f0100d7c <page_alloc>
f01011ea:	89 c7                	mov    %eax,%edi
f01011ec:	83 c4 10             	add    $0x10,%esp
f01011ef:	85 c0                	test   %eax,%eax
f01011f1:	75 19                	jne    f010120c <mem_init+0x1a3>
f01011f3:	68 4f 3d 10 f0       	push   $0xf0103d4f
f01011f8:	68 79 3c 10 f0       	push   $0xf0103c79
f01011fd:	68 6f 02 00 00       	push   $0x26f
f0101202:	68 53 3c 10 f0       	push   $0xf0103c53
f0101207:	e8 7f ee ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f010120c:	83 ec 0c             	sub    $0xc,%esp
f010120f:	6a 00                	push   $0x0
f0101211:	e8 66 fb ff ff       	call   f0100d7c <page_alloc>
f0101216:	89 c6                	mov    %eax,%esi
f0101218:	83 c4 10             	add    $0x10,%esp
f010121b:	85 c0                	test   %eax,%eax
f010121d:	75 19                	jne    f0101238 <mem_init+0x1cf>
f010121f:	68 65 3d 10 f0       	push   $0xf0103d65
f0101224:	68 79 3c 10 f0       	push   $0xf0103c79
f0101229:	68 70 02 00 00       	push   $0x270
f010122e:	68 53 3c 10 f0       	push   $0xf0103c53
f0101233:	e8 53 ee ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101238:	83 ec 0c             	sub    $0xc,%esp
f010123b:	6a 00                	push   $0x0
f010123d:	e8 3a fb ff ff       	call   f0100d7c <page_alloc>
f0101242:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101245:	83 c4 10             	add    $0x10,%esp
f0101248:	85 c0                	test   %eax,%eax
f010124a:	75 19                	jne    f0101265 <mem_init+0x1fc>
f010124c:	68 7b 3d 10 f0       	push   $0xf0103d7b
f0101251:	68 79 3c 10 f0       	push   $0xf0103c79
f0101256:	68 71 02 00 00       	push   $0x271
f010125b:	68 53 3c 10 f0       	push   $0xf0103c53
f0101260:	e8 26 ee ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101265:	39 f7                	cmp    %esi,%edi
f0101267:	75 19                	jne    f0101282 <mem_init+0x219>
f0101269:	68 91 3d 10 f0       	push   $0xf0103d91
f010126e:	68 79 3c 10 f0       	push   $0xf0103c79
f0101273:	68 74 02 00 00       	push   $0x274
f0101278:	68 53 3c 10 f0       	push   $0xf0103c53
f010127d:	e8 09 ee ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101282:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101285:	39 c6                	cmp    %eax,%esi
f0101287:	74 04                	je     f010128d <mem_init+0x224>
f0101289:	39 c7                	cmp    %eax,%edi
f010128b:	75 19                	jne    f01012a6 <mem_init+0x23d>
f010128d:	68 cc 40 10 f0       	push   $0xf01040cc
f0101292:	68 79 3c 10 f0       	push   $0xf0103c79
f0101297:	68 75 02 00 00       	push   $0x275
f010129c:	68 53 3c 10 f0       	push   $0xf0103c53
f01012a1:	e8 e5 ed ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01012a6:	8b 0d 6c 69 11 f0    	mov    0xf011696c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f01012ac:	8b 15 64 69 11 f0    	mov    0xf0116964,%edx
f01012b2:	c1 e2 0c             	shl    $0xc,%edx
f01012b5:	89 f8                	mov    %edi,%eax
f01012b7:	29 c8                	sub    %ecx,%eax
f01012b9:	c1 f8 03             	sar    $0x3,%eax
f01012bc:	c1 e0 0c             	shl    $0xc,%eax
f01012bf:	39 d0                	cmp    %edx,%eax
f01012c1:	72 19                	jb     f01012dc <mem_init+0x273>
f01012c3:	68 a3 3d 10 f0       	push   $0xf0103da3
f01012c8:	68 79 3c 10 f0       	push   $0xf0103c79
f01012cd:	68 76 02 00 00       	push   $0x276
f01012d2:	68 53 3c 10 f0       	push   $0xf0103c53
f01012d7:	e8 af ed ff ff       	call   f010008b <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f01012dc:	89 f0                	mov    %esi,%eax
f01012de:	29 c8                	sub    %ecx,%eax
f01012e0:	c1 f8 03             	sar    $0x3,%eax
f01012e3:	c1 e0 0c             	shl    $0xc,%eax
f01012e6:	39 c2                	cmp    %eax,%edx
f01012e8:	77 19                	ja     f0101303 <mem_init+0x29a>
f01012ea:	68 c0 3d 10 f0       	push   $0xf0103dc0
f01012ef:	68 79 3c 10 f0       	push   $0xf0103c79
f01012f4:	68 77 02 00 00       	push   $0x277
f01012f9:	68 53 3c 10 f0       	push   $0xf0103c53
f01012fe:	e8 88 ed ff ff       	call   f010008b <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f0101303:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101306:	29 c8                	sub    %ecx,%eax
f0101308:	c1 f8 03             	sar    $0x3,%eax
f010130b:	c1 e0 0c             	shl    $0xc,%eax
f010130e:	39 c2                	cmp    %eax,%edx
f0101310:	77 19                	ja     f010132b <mem_init+0x2c2>
f0101312:	68 dd 3d 10 f0       	push   $0xf0103ddd
f0101317:	68 79 3c 10 f0       	push   $0xf0103c79
f010131c:	68 78 02 00 00       	push   $0x278
f0101321:	68 53 3c 10 f0       	push   $0xf0103c53
f0101326:	e8 60 ed ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010132b:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f0101330:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101333:	c7 05 3c 65 11 f0 00 	movl   $0x0,0xf011653c
f010133a:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010133d:	83 ec 0c             	sub    $0xc,%esp
f0101340:	6a 00                	push   $0x0
f0101342:	e8 35 fa ff ff       	call   f0100d7c <page_alloc>
f0101347:	83 c4 10             	add    $0x10,%esp
f010134a:	85 c0                	test   %eax,%eax
f010134c:	74 19                	je     f0101367 <mem_init+0x2fe>
f010134e:	68 fa 3d 10 f0       	push   $0xf0103dfa
f0101353:	68 79 3c 10 f0       	push   $0xf0103c79
f0101358:	68 7f 02 00 00       	push   $0x27f
f010135d:	68 53 3c 10 f0       	push   $0xf0103c53
f0101362:	e8 24 ed ff ff       	call   f010008b <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101367:	83 ec 0c             	sub    $0xc,%esp
f010136a:	57                   	push   %edi
f010136b:	e8 7c fa ff ff       	call   f0100dec <page_free>
	page_free(pp1);
f0101370:	89 34 24             	mov    %esi,(%esp)
f0101373:	e8 74 fa ff ff       	call   f0100dec <page_free>
	page_free(pp2);
f0101378:	83 c4 04             	add    $0x4,%esp
f010137b:	ff 75 d4             	pushl  -0x2c(%ebp)
f010137e:	e8 69 fa ff ff       	call   f0100dec <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101383:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010138a:	e8 ed f9 ff ff       	call   f0100d7c <page_alloc>
f010138f:	89 c6                	mov    %eax,%esi
f0101391:	83 c4 10             	add    $0x10,%esp
f0101394:	85 c0                	test   %eax,%eax
f0101396:	75 19                	jne    f01013b1 <mem_init+0x348>
f0101398:	68 4f 3d 10 f0       	push   $0xf0103d4f
f010139d:	68 79 3c 10 f0       	push   $0xf0103c79
f01013a2:	68 86 02 00 00       	push   $0x286
f01013a7:	68 53 3c 10 f0       	push   $0xf0103c53
f01013ac:	e8 da ec ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01013b1:	83 ec 0c             	sub    $0xc,%esp
f01013b4:	6a 00                	push   $0x0
f01013b6:	e8 c1 f9 ff ff       	call   f0100d7c <page_alloc>
f01013bb:	89 c7                	mov    %eax,%edi
f01013bd:	83 c4 10             	add    $0x10,%esp
f01013c0:	85 c0                	test   %eax,%eax
f01013c2:	75 19                	jne    f01013dd <mem_init+0x374>
f01013c4:	68 65 3d 10 f0       	push   $0xf0103d65
f01013c9:	68 79 3c 10 f0       	push   $0xf0103c79
f01013ce:	68 87 02 00 00       	push   $0x287
f01013d3:	68 53 3c 10 f0       	push   $0xf0103c53
f01013d8:	e8 ae ec ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01013dd:	83 ec 0c             	sub    $0xc,%esp
f01013e0:	6a 00                	push   $0x0
f01013e2:	e8 95 f9 ff ff       	call   f0100d7c <page_alloc>
f01013e7:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01013ea:	83 c4 10             	add    $0x10,%esp
f01013ed:	85 c0                	test   %eax,%eax
f01013ef:	75 19                	jne    f010140a <mem_init+0x3a1>
f01013f1:	68 7b 3d 10 f0       	push   $0xf0103d7b
f01013f6:	68 79 3c 10 f0       	push   $0xf0103c79
f01013fb:	68 88 02 00 00       	push   $0x288
f0101400:	68 53 3c 10 f0       	push   $0xf0103c53
f0101405:	e8 81 ec ff ff       	call   f010008b <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010140a:	39 fe                	cmp    %edi,%esi
f010140c:	75 19                	jne    f0101427 <mem_init+0x3be>
f010140e:	68 91 3d 10 f0       	push   $0xf0103d91
f0101413:	68 79 3c 10 f0       	push   $0xf0103c79
f0101418:	68 8a 02 00 00       	push   $0x28a
f010141d:	68 53 3c 10 f0       	push   $0xf0103c53
f0101422:	e8 64 ec ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101427:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010142a:	39 c7                	cmp    %eax,%edi
f010142c:	74 04                	je     f0101432 <mem_init+0x3c9>
f010142e:	39 c6                	cmp    %eax,%esi
f0101430:	75 19                	jne    f010144b <mem_init+0x3e2>
f0101432:	68 cc 40 10 f0       	push   $0xf01040cc
f0101437:	68 79 3c 10 f0       	push   $0xf0103c79
f010143c:	68 8b 02 00 00       	push   $0x28b
f0101441:	68 53 3c 10 f0       	push   $0xf0103c53
f0101446:	e8 40 ec ff ff       	call   f010008b <_panic>
	assert(!page_alloc(0));
f010144b:	83 ec 0c             	sub    $0xc,%esp
f010144e:	6a 00                	push   $0x0
f0101450:	e8 27 f9 ff ff       	call   f0100d7c <page_alloc>
f0101455:	83 c4 10             	add    $0x10,%esp
f0101458:	85 c0                	test   %eax,%eax
f010145a:	74 19                	je     f0101475 <mem_init+0x40c>
f010145c:	68 fa 3d 10 f0       	push   $0xf0103dfa
f0101461:	68 79 3c 10 f0       	push   $0xf0103c79
f0101466:	68 8c 02 00 00       	push   $0x28c
f010146b:	68 53 3c 10 f0       	push   $0xf0103c53
f0101470:	e8 16 ec ff ff       	call   f010008b <_panic>
f0101475:	89 f0                	mov    %esi,%eax
f0101477:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f010147d:	c1 f8 03             	sar    $0x3,%eax
f0101480:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101483:	89 c2                	mov    %eax,%edx
f0101485:	c1 ea 0c             	shr    $0xc,%edx
f0101488:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f010148e:	72 12                	jb     f01014a2 <mem_init+0x439>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101490:	50                   	push   %eax
f0101491:	68 64 3f 10 f0       	push   $0xf0103f64
f0101496:	6a 52                	push   $0x52
f0101498:	68 5f 3c 10 f0       	push   $0xf0103c5f
f010149d:	e8 e9 eb ff ff       	call   f010008b <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f01014a2:	83 ec 04             	sub    $0x4,%esp
f01014a5:	68 00 10 00 00       	push   $0x1000
f01014aa:	6a 01                	push   $0x1
f01014ac:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01014b1:	50                   	push   %eax
f01014b2:	e8 84 1d 00 00       	call   f010323b <memset>
	page_free(pp0);
f01014b7:	89 34 24             	mov    %esi,(%esp)
f01014ba:	e8 2d f9 ff ff       	call   f0100dec <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01014bf:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01014c6:	e8 b1 f8 ff ff       	call   f0100d7c <page_alloc>
f01014cb:	83 c4 10             	add    $0x10,%esp
f01014ce:	85 c0                	test   %eax,%eax
f01014d0:	75 19                	jne    f01014eb <mem_init+0x482>
f01014d2:	68 09 3e 10 f0       	push   $0xf0103e09
f01014d7:	68 79 3c 10 f0       	push   $0xf0103c79
f01014dc:	68 91 02 00 00       	push   $0x291
f01014e1:	68 53 3c 10 f0       	push   $0xf0103c53
f01014e6:	e8 a0 eb ff ff       	call   f010008b <_panic>
	assert(pp && pp0 == pp);
f01014eb:	39 c6                	cmp    %eax,%esi
f01014ed:	74 19                	je     f0101508 <mem_init+0x49f>
f01014ef:	68 27 3e 10 f0       	push   $0xf0103e27
f01014f4:	68 79 3c 10 f0       	push   $0xf0103c79
f01014f9:	68 92 02 00 00       	push   $0x292
f01014fe:	68 53 3c 10 f0       	push   $0xf0103c53
f0101503:	e8 83 eb ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101508:	89 f0                	mov    %esi,%eax
f010150a:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0101510:	c1 f8 03             	sar    $0x3,%eax
f0101513:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101516:	89 c2                	mov    %eax,%edx
f0101518:	c1 ea 0c             	shr    $0xc,%edx
f010151b:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f0101521:	72 12                	jb     f0101535 <mem_init+0x4cc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101523:	50                   	push   %eax
f0101524:	68 64 3f 10 f0       	push   $0xf0103f64
f0101529:	6a 52                	push   $0x52
f010152b:	68 5f 3c 10 f0       	push   $0xf0103c5f
f0101530:	e8 56 eb ff ff       	call   f010008b <_panic>
f0101535:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f010153b:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101541:	80 38 00             	cmpb   $0x0,(%eax)
f0101544:	74 19                	je     f010155f <mem_init+0x4f6>
f0101546:	68 37 3e 10 f0       	push   $0xf0103e37
f010154b:	68 79 3c 10 f0       	push   $0xf0103c79
f0101550:	68 95 02 00 00       	push   $0x295
f0101555:	68 53 3c 10 f0       	push   $0xf0103c53
f010155a:	e8 2c eb ff ff       	call   f010008b <_panic>
f010155f:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101562:	39 d0                	cmp    %edx,%eax
f0101564:	75 db                	jne    f0101541 <mem_init+0x4d8>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101566:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101569:	a3 3c 65 11 f0       	mov    %eax,0xf011653c

	// free the pages we took
	page_free(pp0);
f010156e:	83 ec 0c             	sub    $0xc,%esp
f0101571:	56                   	push   %esi
f0101572:	e8 75 f8 ff ff       	call   f0100dec <page_free>
	page_free(pp1);
f0101577:	89 3c 24             	mov    %edi,(%esp)
f010157a:	e8 6d f8 ff ff       	call   f0100dec <page_free>
	page_free(pp2);
f010157f:	83 c4 04             	add    $0x4,%esp
f0101582:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101585:	e8 62 f8 ff ff       	call   f0100dec <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010158a:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f010158f:	83 c4 10             	add    $0x10,%esp
f0101592:	eb 05                	jmp    f0101599 <mem_init+0x530>
		--nfree;
f0101594:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101597:	8b 00                	mov    (%eax),%eax
f0101599:	85 c0                	test   %eax,%eax
f010159b:	75 f7                	jne    f0101594 <mem_init+0x52b>
		--nfree;
	assert(nfree == 0);
f010159d:	85 db                	test   %ebx,%ebx
f010159f:	74 19                	je     f01015ba <mem_init+0x551>
f01015a1:	68 41 3e 10 f0       	push   $0xf0103e41
f01015a6:	68 79 3c 10 f0       	push   $0xf0103c79
f01015ab:	68 a2 02 00 00       	push   $0x2a2
f01015b0:	68 53 3c 10 f0       	push   $0xf0103c53
f01015b5:	e8 d1 ea ff ff       	call   f010008b <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01015ba:	83 ec 0c             	sub    $0xc,%esp
f01015bd:	68 ec 40 10 f0       	push   $0xf01040ec
f01015c2:	e8 9b 11 00 00       	call   f0102762 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01015c7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015ce:	e8 a9 f7 ff ff       	call   f0100d7c <page_alloc>
f01015d3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01015d6:	83 c4 10             	add    $0x10,%esp
f01015d9:	85 c0                	test   %eax,%eax
f01015db:	75 19                	jne    f01015f6 <mem_init+0x58d>
f01015dd:	68 4f 3d 10 f0       	push   $0xf0103d4f
f01015e2:	68 79 3c 10 f0       	push   $0xf0103c79
f01015e7:	68 fb 02 00 00       	push   $0x2fb
f01015ec:	68 53 3c 10 f0       	push   $0xf0103c53
f01015f1:	e8 95 ea ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01015f6:	83 ec 0c             	sub    $0xc,%esp
f01015f9:	6a 00                	push   $0x0
f01015fb:	e8 7c f7 ff ff       	call   f0100d7c <page_alloc>
f0101600:	89 c3                	mov    %eax,%ebx
f0101602:	83 c4 10             	add    $0x10,%esp
f0101605:	85 c0                	test   %eax,%eax
f0101607:	75 19                	jne    f0101622 <mem_init+0x5b9>
f0101609:	68 65 3d 10 f0       	push   $0xf0103d65
f010160e:	68 79 3c 10 f0       	push   $0xf0103c79
f0101613:	68 fc 02 00 00       	push   $0x2fc
f0101618:	68 53 3c 10 f0       	push   $0xf0103c53
f010161d:	e8 69 ea ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101622:	83 ec 0c             	sub    $0xc,%esp
f0101625:	6a 00                	push   $0x0
f0101627:	e8 50 f7 ff ff       	call   f0100d7c <page_alloc>
f010162c:	89 c6                	mov    %eax,%esi
f010162e:	83 c4 10             	add    $0x10,%esp
f0101631:	85 c0                	test   %eax,%eax
f0101633:	75 19                	jne    f010164e <mem_init+0x5e5>
f0101635:	68 7b 3d 10 f0       	push   $0xf0103d7b
f010163a:	68 79 3c 10 f0       	push   $0xf0103c79
f010163f:	68 fd 02 00 00       	push   $0x2fd
f0101644:	68 53 3c 10 f0       	push   $0xf0103c53
f0101649:	e8 3d ea ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010164e:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101651:	75 19                	jne    f010166c <mem_init+0x603>
f0101653:	68 91 3d 10 f0       	push   $0xf0103d91
f0101658:	68 79 3c 10 f0       	push   $0xf0103c79
f010165d:	68 00 03 00 00       	push   $0x300
f0101662:	68 53 3c 10 f0       	push   $0xf0103c53
f0101667:	e8 1f ea ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010166c:	39 c3                	cmp    %eax,%ebx
f010166e:	74 05                	je     f0101675 <mem_init+0x60c>
f0101670:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101673:	75 19                	jne    f010168e <mem_init+0x625>
f0101675:	68 cc 40 10 f0       	push   $0xf01040cc
f010167a:	68 79 3c 10 f0       	push   $0xf0103c79
f010167f:	68 01 03 00 00       	push   $0x301
f0101684:	68 53 3c 10 f0       	push   $0xf0103c53
f0101689:	e8 fd e9 ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010168e:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f0101693:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101696:	c7 05 3c 65 11 f0 00 	movl   $0x0,0xf011653c
f010169d:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01016a0:	83 ec 0c             	sub    $0xc,%esp
f01016a3:	6a 00                	push   $0x0
f01016a5:	e8 d2 f6 ff ff       	call   f0100d7c <page_alloc>
f01016aa:	83 c4 10             	add    $0x10,%esp
f01016ad:	85 c0                	test   %eax,%eax
f01016af:	74 19                	je     f01016ca <mem_init+0x661>
f01016b1:	68 fa 3d 10 f0       	push   $0xf0103dfa
f01016b6:	68 79 3c 10 f0       	push   $0xf0103c79
f01016bb:	68 08 03 00 00       	push   $0x308
f01016c0:	68 53 3c 10 f0       	push   $0xf0103c53
f01016c5:	e8 c1 e9 ff ff       	call   f010008b <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01016ca:	83 ec 04             	sub    $0x4,%esp
f01016cd:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01016d0:	50                   	push   %eax
f01016d1:	6a 00                	push   $0x0
f01016d3:	ff 35 68 69 11 f0    	pushl  0xf0116968
f01016d9:	e8 77 f8 ff ff       	call   f0100f55 <page_lookup>
f01016de:	83 c4 10             	add    $0x10,%esp
f01016e1:	85 c0                	test   %eax,%eax
f01016e3:	74 19                	je     f01016fe <mem_init+0x695>
f01016e5:	68 0c 41 10 f0       	push   $0xf010410c
f01016ea:	68 79 3c 10 f0       	push   $0xf0103c79
f01016ef:	68 0b 03 00 00       	push   $0x30b
f01016f4:	68 53 3c 10 f0       	push   $0xf0103c53
f01016f9:	e8 8d e9 ff ff       	call   f010008b <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01016fe:	6a 02                	push   $0x2
f0101700:	6a 00                	push   $0x0
f0101702:	53                   	push   %ebx
f0101703:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101709:	e8 f5 f8 ff ff       	call   f0101003 <page_insert>
f010170e:	83 c4 10             	add    $0x10,%esp
f0101711:	85 c0                	test   %eax,%eax
f0101713:	78 19                	js     f010172e <mem_init+0x6c5>
f0101715:	68 44 41 10 f0       	push   $0xf0104144
f010171a:	68 79 3c 10 f0       	push   $0xf0103c79
f010171f:	68 0e 03 00 00       	push   $0x30e
f0101724:	68 53 3c 10 f0       	push   $0xf0103c53
f0101729:	e8 5d e9 ff ff       	call   f010008b <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f010172e:	83 ec 0c             	sub    $0xc,%esp
f0101731:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101734:	e8 b3 f6 ff ff       	call   f0100dec <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101739:	6a 02                	push   $0x2
f010173b:	6a 00                	push   $0x0
f010173d:	53                   	push   %ebx
f010173e:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101744:	e8 ba f8 ff ff       	call   f0101003 <page_insert>
f0101749:	83 c4 20             	add    $0x20,%esp
f010174c:	85 c0                	test   %eax,%eax
f010174e:	74 19                	je     f0101769 <mem_init+0x700>
f0101750:	68 74 41 10 f0       	push   $0xf0104174
f0101755:	68 79 3c 10 f0       	push   $0xf0103c79
f010175a:	68 12 03 00 00       	push   $0x312
f010175f:	68 53 3c 10 f0       	push   $0xf0103c53
f0101764:	e8 22 e9 ff ff       	call   f010008b <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101769:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010176f:	a1 6c 69 11 f0       	mov    0xf011696c,%eax
f0101774:	89 c1                	mov    %eax,%ecx
f0101776:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101779:	8b 17                	mov    (%edi),%edx
f010177b:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101781:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101784:	29 c8                	sub    %ecx,%eax
f0101786:	c1 f8 03             	sar    $0x3,%eax
f0101789:	c1 e0 0c             	shl    $0xc,%eax
f010178c:	39 c2                	cmp    %eax,%edx
f010178e:	74 19                	je     f01017a9 <mem_init+0x740>
f0101790:	68 a4 41 10 f0       	push   $0xf01041a4
f0101795:	68 79 3c 10 f0       	push   $0xf0103c79
f010179a:	68 13 03 00 00       	push   $0x313
f010179f:	68 53 3c 10 f0       	push   $0xf0103c53
f01017a4:	e8 e2 e8 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01017a9:	ba 00 00 00 00       	mov    $0x0,%edx
f01017ae:	89 f8                	mov    %edi,%eax
f01017b0:	e8 aa f1 ff ff       	call   f010095f <check_va2pa>
f01017b5:	89 da                	mov    %ebx,%edx
f01017b7:	2b 55 cc             	sub    -0x34(%ebp),%edx
f01017ba:	c1 fa 03             	sar    $0x3,%edx
f01017bd:	c1 e2 0c             	shl    $0xc,%edx
f01017c0:	39 d0                	cmp    %edx,%eax
f01017c2:	74 19                	je     f01017dd <mem_init+0x774>
f01017c4:	68 cc 41 10 f0       	push   $0xf01041cc
f01017c9:	68 79 3c 10 f0       	push   $0xf0103c79
f01017ce:	68 14 03 00 00       	push   $0x314
f01017d3:	68 53 3c 10 f0       	push   $0xf0103c53
f01017d8:	e8 ae e8 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f01017dd:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01017e2:	74 19                	je     f01017fd <mem_init+0x794>
f01017e4:	68 4c 3e 10 f0       	push   $0xf0103e4c
f01017e9:	68 79 3c 10 f0       	push   $0xf0103c79
f01017ee:	68 15 03 00 00       	push   $0x315
f01017f3:	68 53 3c 10 f0       	push   $0xf0103c53
f01017f8:	e8 8e e8 ff ff       	call   f010008b <_panic>
	assert(pp0->pp_ref == 1);
f01017fd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101800:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101805:	74 19                	je     f0101820 <mem_init+0x7b7>
f0101807:	68 5d 3e 10 f0       	push   $0xf0103e5d
f010180c:	68 79 3c 10 f0       	push   $0xf0103c79
f0101811:	68 16 03 00 00       	push   $0x316
f0101816:	68 53 3c 10 f0       	push   $0xf0103c53
f010181b:	e8 6b e8 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101820:	6a 02                	push   $0x2
f0101822:	68 00 10 00 00       	push   $0x1000
f0101827:	56                   	push   %esi
f0101828:	57                   	push   %edi
f0101829:	e8 d5 f7 ff ff       	call   f0101003 <page_insert>
f010182e:	83 c4 10             	add    $0x10,%esp
f0101831:	85 c0                	test   %eax,%eax
f0101833:	74 19                	je     f010184e <mem_init+0x7e5>
f0101835:	68 fc 41 10 f0       	push   $0xf01041fc
f010183a:	68 79 3c 10 f0       	push   $0xf0103c79
f010183f:	68 19 03 00 00       	push   $0x319
f0101844:	68 53 3c 10 f0       	push   $0xf0103c53
f0101849:	e8 3d e8 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010184e:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101853:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f0101858:	e8 02 f1 ff ff       	call   f010095f <check_va2pa>
f010185d:	89 f2                	mov    %esi,%edx
f010185f:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f0101865:	c1 fa 03             	sar    $0x3,%edx
f0101868:	c1 e2 0c             	shl    $0xc,%edx
f010186b:	39 d0                	cmp    %edx,%eax
f010186d:	74 19                	je     f0101888 <mem_init+0x81f>
f010186f:	68 38 42 10 f0       	push   $0xf0104238
f0101874:	68 79 3c 10 f0       	push   $0xf0103c79
f0101879:	68 1a 03 00 00       	push   $0x31a
f010187e:	68 53 3c 10 f0       	push   $0xf0103c53
f0101883:	e8 03 e8 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101888:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010188d:	74 19                	je     f01018a8 <mem_init+0x83f>
f010188f:	68 6e 3e 10 f0       	push   $0xf0103e6e
f0101894:	68 79 3c 10 f0       	push   $0xf0103c79
f0101899:	68 1b 03 00 00       	push   $0x31b
f010189e:	68 53 3c 10 f0       	push   $0xf0103c53
f01018a3:	e8 e3 e7 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01018a8:	83 ec 0c             	sub    $0xc,%esp
f01018ab:	6a 00                	push   $0x0
f01018ad:	e8 ca f4 ff ff       	call   f0100d7c <page_alloc>
f01018b2:	83 c4 10             	add    $0x10,%esp
f01018b5:	85 c0                	test   %eax,%eax
f01018b7:	74 19                	je     f01018d2 <mem_init+0x869>
f01018b9:	68 fa 3d 10 f0       	push   $0xf0103dfa
f01018be:	68 79 3c 10 f0       	push   $0xf0103c79
f01018c3:	68 1e 03 00 00       	push   $0x31e
f01018c8:	68 53 3c 10 f0       	push   $0xf0103c53
f01018cd:	e8 b9 e7 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01018d2:	6a 02                	push   $0x2
f01018d4:	68 00 10 00 00       	push   $0x1000
f01018d9:	56                   	push   %esi
f01018da:	ff 35 68 69 11 f0    	pushl  0xf0116968
f01018e0:	e8 1e f7 ff ff       	call   f0101003 <page_insert>
f01018e5:	83 c4 10             	add    $0x10,%esp
f01018e8:	85 c0                	test   %eax,%eax
f01018ea:	74 19                	je     f0101905 <mem_init+0x89c>
f01018ec:	68 fc 41 10 f0       	push   $0xf01041fc
f01018f1:	68 79 3c 10 f0       	push   $0xf0103c79
f01018f6:	68 21 03 00 00       	push   $0x321
f01018fb:	68 53 3c 10 f0       	push   $0xf0103c53
f0101900:	e8 86 e7 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101905:	ba 00 10 00 00       	mov    $0x1000,%edx
f010190a:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f010190f:	e8 4b f0 ff ff       	call   f010095f <check_va2pa>
f0101914:	89 f2                	mov    %esi,%edx
f0101916:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f010191c:	c1 fa 03             	sar    $0x3,%edx
f010191f:	c1 e2 0c             	shl    $0xc,%edx
f0101922:	39 d0                	cmp    %edx,%eax
f0101924:	74 19                	je     f010193f <mem_init+0x8d6>
f0101926:	68 38 42 10 f0       	push   $0xf0104238
f010192b:	68 79 3c 10 f0       	push   $0xf0103c79
f0101930:	68 22 03 00 00       	push   $0x322
f0101935:	68 53 3c 10 f0       	push   $0xf0103c53
f010193a:	e8 4c e7 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f010193f:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101944:	74 19                	je     f010195f <mem_init+0x8f6>
f0101946:	68 6e 3e 10 f0       	push   $0xf0103e6e
f010194b:	68 79 3c 10 f0       	push   $0xf0103c79
f0101950:	68 23 03 00 00       	push   $0x323
f0101955:	68 53 3c 10 f0       	push   $0xf0103c53
f010195a:	e8 2c e7 ff ff       	call   f010008b <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f010195f:	83 ec 0c             	sub    $0xc,%esp
f0101962:	6a 00                	push   $0x0
f0101964:	e8 13 f4 ff ff       	call   f0100d7c <page_alloc>
f0101969:	83 c4 10             	add    $0x10,%esp
f010196c:	85 c0                	test   %eax,%eax
f010196e:	74 19                	je     f0101989 <mem_init+0x920>
f0101970:	68 fa 3d 10 f0       	push   $0xf0103dfa
f0101975:	68 79 3c 10 f0       	push   $0xf0103c79
f010197a:	68 27 03 00 00       	push   $0x327
f010197f:	68 53 3c 10 f0       	push   $0xf0103c53
f0101984:	e8 02 e7 ff ff       	call   f010008b <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101989:	8b 15 68 69 11 f0    	mov    0xf0116968,%edx
f010198f:	8b 02                	mov    (%edx),%eax
f0101991:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101996:	89 c1                	mov    %eax,%ecx
f0101998:	c1 e9 0c             	shr    $0xc,%ecx
f010199b:	3b 0d 64 69 11 f0    	cmp    0xf0116964,%ecx
f01019a1:	72 15                	jb     f01019b8 <mem_init+0x94f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01019a3:	50                   	push   %eax
f01019a4:	68 64 3f 10 f0       	push   $0xf0103f64
f01019a9:	68 2a 03 00 00       	push   $0x32a
f01019ae:	68 53 3c 10 f0       	push   $0xf0103c53
f01019b3:	e8 d3 e6 ff ff       	call   f010008b <_panic>
f01019b8:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01019bd:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f01019c0:	83 ec 04             	sub    $0x4,%esp
f01019c3:	6a 00                	push   $0x0
f01019c5:	68 00 10 00 00       	push   $0x1000
f01019ca:	52                   	push   %edx
f01019cb:	e8 52 f4 ff ff       	call   f0100e22 <pgdir_walk>
f01019d0:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01019d3:	8d 51 04             	lea    0x4(%ecx),%edx
f01019d6:	83 c4 10             	add    $0x10,%esp
f01019d9:	39 d0                	cmp    %edx,%eax
f01019db:	74 19                	je     f01019f6 <mem_init+0x98d>
f01019dd:	68 68 42 10 f0       	push   $0xf0104268
f01019e2:	68 79 3c 10 f0       	push   $0xf0103c79
f01019e7:	68 2b 03 00 00       	push   $0x32b
f01019ec:	68 53 3c 10 f0       	push   $0xf0103c53
f01019f1:	e8 95 e6 ff ff       	call   f010008b <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f01019f6:	6a 06                	push   $0x6
f01019f8:	68 00 10 00 00       	push   $0x1000
f01019fd:	56                   	push   %esi
f01019fe:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101a04:	e8 fa f5 ff ff       	call   f0101003 <page_insert>
f0101a09:	83 c4 10             	add    $0x10,%esp
f0101a0c:	85 c0                	test   %eax,%eax
f0101a0e:	74 19                	je     f0101a29 <mem_init+0x9c0>
f0101a10:	68 a8 42 10 f0       	push   $0xf01042a8
f0101a15:	68 79 3c 10 f0       	push   $0xf0103c79
f0101a1a:	68 2e 03 00 00       	push   $0x32e
f0101a1f:	68 53 3c 10 f0       	push   $0xf0103c53
f0101a24:	e8 62 e6 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101a29:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
f0101a2f:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a34:	89 f8                	mov    %edi,%eax
f0101a36:	e8 24 ef ff ff       	call   f010095f <check_va2pa>
f0101a3b:	89 f2                	mov    %esi,%edx
f0101a3d:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f0101a43:	c1 fa 03             	sar    $0x3,%edx
f0101a46:	c1 e2 0c             	shl    $0xc,%edx
f0101a49:	39 d0                	cmp    %edx,%eax
f0101a4b:	74 19                	je     f0101a66 <mem_init+0x9fd>
f0101a4d:	68 38 42 10 f0       	push   $0xf0104238
f0101a52:	68 79 3c 10 f0       	push   $0xf0103c79
f0101a57:	68 2f 03 00 00       	push   $0x32f
f0101a5c:	68 53 3c 10 f0       	push   $0xf0103c53
f0101a61:	e8 25 e6 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101a66:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101a6b:	74 19                	je     f0101a86 <mem_init+0xa1d>
f0101a6d:	68 6e 3e 10 f0       	push   $0xf0103e6e
f0101a72:	68 79 3c 10 f0       	push   $0xf0103c79
f0101a77:	68 30 03 00 00       	push   $0x330
f0101a7c:	68 53 3c 10 f0       	push   $0xf0103c53
f0101a81:	e8 05 e6 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101a86:	83 ec 04             	sub    $0x4,%esp
f0101a89:	6a 00                	push   $0x0
f0101a8b:	68 00 10 00 00       	push   $0x1000
f0101a90:	57                   	push   %edi
f0101a91:	e8 8c f3 ff ff       	call   f0100e22 <pgdir_walk>
f0101a96:	83 c4 10             	add    $0x10,%esp
f0101a99:	f6 00 04             	testb  $0x4,(%eax)
f0101a9c:	75 19                	jne    f0101ab7 <mem_init+0xa4e>
f0101a9e:	68 e8 42 10 f0       	push   $0xf01042e8
f0101aa3:	68 79 3c 10 f0       	push   $0xf0103c79
f0101aa8:	68 31 03 00 00       	push   $0x331
f0101aad:	68 53 3c 10 f0       	push   $0xf0103c53
f0101ab2:	e8 d4 e5 ff ff       	call   f010008b <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101ab7:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f0101abc:	f6 00 04             	testb  $0x4,(%eax)
f0101abf:	75 19                	jne    f0101ada <mem_init+0xa71>
f0101ac1:	68 7f 3e 10 f0       	push   $0xf0103e7f
f0101ac6:	68 79 3c 10 f0       	push   $0xf0103c79
f0101acb:	68 32 03 00 00       	push   $0x332
f0101ad0:	68 53 3c 10 f0       	push   $0xf0103c53
f0101ad5:	e8 b1 e5 ff ff       	call   f010008b <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101ada:	6a 02                	push   $0x2
f0101adc:	68 00 10 00 00       	push   $0x1000
f0101ae1:	56                   	push   %esi
f0101ae2:	50                   	push   %eax
f0101ae3:	e8 1b f5 ff ff       	call   f0101003 <page_insert>
f0101ae8:	83 c4 10             	add    $0x10,%esp
f0101aeb:	85 c0                	test   %eax,%eax
f0101aed:	74 19                	je     f0101b08 <mem_init+0xa9f>
f0101aef:	68 fc 41 10 f0       	push   $0xf01041fc
f0101af4:	68 79 3c 10 f0       	push   $0xf0103c79
f0101af9:	68 35 03 00 00       	push   $0x335
f0101afe:	68 53 3c 10 f0       	push   $0xf0103c53
f0101b03:	e8 83 e5 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101b08:	83 ec 04             	sub    $0x4,%esp
f0101b0b:	6a 00                	push   $0x0
f0101b0d:	68 00 10 00 00       	push   $0x1000
f0101b12:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101b18:	e8 05 f3 ff ff       	call   f0100e22 <pgdir_walk>
f0101b1d:	83 c4 10             	add    $0x10,%esp
f0101b20:	f6 00 02             	testb  $0x2,(%eax)
f0101b23:	75 19                	jne    f0101b3e <mem_init+0xad5>
f0101b25:	68 1c 43 10 f0       	push   $0xf010431c
f0101b2a:	68 79 3c 10 f0       	push   $0xf0103c79
f0101b2f:	68 36 03 00 00       	push   $0x336
f0101b34:	68 53 3c 10 f0       	push   $0xf0103c53
f0101b39:	e8 4d e5 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101b3e:	83 ec 04             	sub    $0x4,%esp
f0101b41:	6a 00                	push   $0x0
f0101b43:	68 00 10 00 00       	push   $0x1000
f0101b48:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101b4e:	e8 cf f2 ff ff       	call   f0100e22 <pgdir_walk>
f0101b53:	83 c4 10             	add    $0x10,%esp
f0101b56:	f6 00 04             	testb  $0x4,(%eax)
f0101b59:	74 19                	je     f0101b74 <mem_init+0xb0b>
f0101b5b:	68 50 43 10 f0       	push   $0xf0104350
f0101b60:	68 79 3c 10 f0       	push   $0xf0103c79
f0101b65:	68 37 03 00 00       	push   $0x337
f0101b6a:	68 53 3c 10 f0       	push   $0xf0103c53
f0101b6f:	e8 17 e5 ff ff       	call   f010008b <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101b74:	6a 02                	push   $0x2
f0101b76:	68 00 00 40 00       	push   $0x400000
f0101b7b:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101b7e:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101b84:	e8 7a f4 ff ff       	call   f0101003 <page_insert>
f0101b89:	83 c4 10             	add    $0x10,%esp
f0101b8c:	85 c0                	test   %eax,%eax
f0101b8e:	78 19                	js     f0101ba9 <mem_init+0xb40>
f0101b90:	68 88 43 10 f0       	push   $0xf0104388
f0101b95:	68 79 3c 10 f0       	push   $0xf0103c79
f0101b9a:	68 3a 03 00 00       	push   $0x33a
f0101b9f:	68 53 3c 10 f0       	push   $0xf0103c53
f0101ba4:	e8 e2 e4 ff ff       	call   f010008b <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101ba9:	6a 02                	push   $0x2
f0101bab:	68 00 10 00 00       	push   $0x1000
f0101bb0:	53                   	push   %ebx
f0101bb1:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101bb7:	e8 47 f4 ff ff       	call   f0101003 <page_insert>
f0101bbc:	83 c4 10             	add    $0x10,%esp
f0101bbf:	85 c0                	test   %eax,%eax
f0101bc1:	74 19                	je     f0101bdc <mem_init+0xb73>
f0101bc3:	68 c0 43 10 f0       	push   $0xf01043c0
f0101bc8:	68 79 3c 10 f0       	push   $0xf0103c79
f0101bcd:	68 3d 03 00 00       	push   $0x33d
f0101bd2:	68 53 3c 10 f0       	push   $0xf0103c53
f0101bd7:	e8 af e4 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101bdc:	83 ec 04             	sub    $0x4,%esp
f0101bdf:	6a 00                	push   $0x0
f0101be1:	68 00 10 00 00       	push   $0x1000
f0101be6:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101bec:	e8 31 f2 ff ff       	call   f0100e22 <pgdir_walk>
f0101bf1:	83 c4 10             	add    $0x10,%esp
f0101bf4:	f6 00 04             	testb  $0x4,(%eax)
f0101bf7:	74 19                	je     f0101c12 <mem_init+0xba9>
f0101bf9:	68 50 43 10 f0       	push   $0xf0104350
f0101bfe:	68 79 3c 10 f0       	push   $0xf0103c79
f0101c03:	68 3e 03 00 00       	push   $0x33e
f0101c08:	68 53 3c 10 f0       	push   $0xf0103c53
f0101c0d:	e8 79 e4 ff ff       	call   f010008b <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101c12:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
f0101c18:	ba 00 00 00 00       	mov    $0x0,%edx
f0101c1d:	89 f8                	mov    %edi,%eax
f0101c1f:	e8 3b ed ff ff       	call   f010095f <check_va2pa>
f0101c24:	89 c1                	mov    %eax,%ecx
f0101c26:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101c29:	89 d8                	mov    %ebx,%eax
f0101c2b:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0101c31:	c1 f8 03             	sar    $0x3,%eax
f0101c34:	c1 e0 0c             	shl    $0xc,%eax
f0101c37:	39 c1                	cmp    %eax,%ecx
f0101c39:	74 19                	je     f0101c54 <mem_init+0xbeb>
f0101c3b:	68 fc 43 10 f0       	push   $0xf01043fc
f0101c40:	68 79 3c 10 f0       	push   $0xf0103c79
f0101c45:	68 41 03 00 00       	push   $0x341
f0101c4a:	68 53 3c 10 f0       	push   $0xf0103c53
f0101c4f:	e8 37 e4 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101c54:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c59:	89 f8                	mov    %edi,%eax
f0101c5b:	e8 ff ec ff ff       	call   f010095f <check_va2pa>
f0101c60:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101c63:	74 19                	je     f0101c7e <mem_init+0xc15>
f0101c65:	68 28 44 10 f0       	push   $0xf0104428
f0101c6a:	68 79 3c 10 f0       	push   $0xf0103c79
f0101c6f:	68 42 03 00 00       	push   $0x342
f0101c74:	68 53 3c 10 f0       	push   $0xf0103c53
f0101c79:	e8 0d e4 ff ff       	call   f010008b <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101c7e:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101c83:	74 19                	je     f0101c9e <mem_init+0xc35>
f0101c85:	68 95 3e 10 f0       	push   $0xf0103e95
f0101c8a:	68 79 3c 10 f0       	push   $0xf0103c79
f0101c8f:	68 44 03 00 00       	push   $0x344
f0101c94:	68 53 3c 10 f0       	push   $0xf0103c53
f0101c99:	e8 ed e3 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101c9e:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101ca3:	74 19                	je     f0101cbe <mem_init+0xc55>
f0101ca5:	68 a6 3e 10 f0       	push   $0xf0103ea6
f0101caa:	68 79 3c 10 f0       	push   $0xf0103c79
f0101caf:	68 45 03 00 00       	push   $0x345
f0101cb4:	68 53 3c 10 f0       	push   $0xf0103c53
f0101cb9:	e8 cd e3 ff ff       	call   f010008b <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101cbe:	83 ec 0c             	sub    $0xc,%esp
f0101cc1:	6a 00                	push   $0x0
f0101cc3:	e8 b4 f0 ff ff       	call   f0100d7c <page_alloc>
f0101cc8:	83 c4 10             	add    $0x10,%esp
f0101ccb:	85 c0                	test   %eax,%eax
f0101ccd:	74 04                	je     f0101cd3 <mem_init+0xc6a>
f0101ccf:	39 c6                	cmp    %eax,%esi
f0101cd1:	74 19                	je     f0101cec <mem_init+0xc83>
f0101cd3:	68 58 44 10 f0       	push   $0xf0104458
f0101cd8:	68 79 3c 10 f0       	push   $0xf0103c79
f0101cdd:	68 48 03 00 00       	push   $0x348
f0101ce2:	68 53 3c 10 f0       	push   $0xf0103c53
f0101ce7:	e8 9f e3 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101cec:	83 ec 08             	sub    $0x8,%esp
f0101cef:	6a 00                	push   $0x0
f0101cf1:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101cf7:	e8 c4 f2 ff ff       	call   f0100fc0 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101cfc:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
f0101d02:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d07:	89 f8                	mov    %edi,%eax
f0101d09:	e8 51 ec ff ff       	call   f010095f <check_va2pa>
f0101d0e:	83 c4 10             	add    $0x10,%esp
f0101d11:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101d14:	74 19                	je     f0101d2f <mem_init+0xcc6>
f0101d16:	68 7c 44 10 f0       	push   $0xf010447c
f0101d1b:	68 79 3c 10 f0       	push   $0xf0103c79
f0101d20:	68 4c 03 00 00       	push   $0x34c
f0101d25:	68 53 3c 10 f0       	push   $0xf0103c53
f0101d2a:	e8 5c e3 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101d2f:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d34:	89 f8                	mov    %edi,%eax
f0101d36:	e8 24 ec ff ff       	call   f010095f <check_va2pa>
f0101d3b:	89 da                	mov    %ebx,%edx
f0101d3d:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f0101d43:	c1 fa 03             	sar    $0x3,%edx
f0101d46:	c1 e2 0c             	shl    $0xc,%edx
f0101d49:	39 d0                	cmp    %edx,%eax
f0101d4b:	74 19                	je     f0101d66 <mem_init+0xcfd>
f0101d4d:	68 28 44 10 f0       	push   $0xf0104428
f0101d52:	68 79 3c 10 f0       	push   $0xf0103c79
f0101d57:	68 4d 03 00 00       	push   $0x34d
f0101d5c:	68 53 3c 10 f0       	push   $0xf0103c53
f0101d61:	e8 25 e3 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101d66:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101d6b:	74 19                	je     f0101d86 <mem_init+0xd1d>
f0101d6d:	68 4c 3e 10 f0       	push   $0xf0103e4c
f0101d72:	68 79 3c 10 f0       	push   $0xf0103c79
f0101d77:	68 4e 03 00 00       	push   $0x34e
f0101d7c:	68 53 3c 10 f0       	push   $0xf0103c53
f0101d81:	e8 05 e3 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101d86:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101d8b:	74 19                	je     f0101da6 <mem_init+0xd3d>
f0101d8d:	68 a6 3e 10 f0       	push   $0xf0103ea6
f0101d92:	68 79 3c 10 f0       	push   $0xf0103c79
f0101d97:	68 4f 03 00 00       	push   $0x34f
f0101d9c:	68 53 3c 10 f0       	push   $0xf0103c53
f0101da1:	e8 e5 e2 ff ff       	call   f010008b <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101da6:	6a 00                	push   $0x0
f0101da8:	68 00 10 00 00       	push   $0x1000
f0101dad:	53                   	push   %ebx
f0101dae:	57                   	push   %edi
f0101daf:	e8 4f f2 ff ff       	call   f0101003 <page_insert>
f0101db4:	83 c4 10             	add    $0x10,%esp
f0101db7:	85 c0                	test   %eax,%eax
f0101db9:	74 19                	je     f0101dd4 <mem_init+0xd6b>
f0101dbb:	68 a0 44 10 f0       	push   $0xf01044a0
f0101dc0:	68 79 3c 10 f0       	push   $0xf0103c79
f0101dc5:	68 52 03 00 00       	push   $0x352
f0101dca:	68 53 3c 10 f0       	push   $0xf0103c53
f0101dcf:	e8 b7 e2 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref);
f0101dd4:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101dd9:	75 19                	jne    f0101df4 <mem_init+0xd8b>
f0101ddb:	68 b7 3e 10 f0       	push   $0xf0103eb7
f0101de0:	68 79 3c 10 f0       	push   $0xf0103c79
f0101de5:	68 53 03 00 00       	push   $0x353
f0101dea:	68 53 3c 10 f0       	push   $0xf0103c53
f0101def:	e8 97 e2 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_link == NULL);
f0101df4:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101df7:	74 19                	je     f0101e12 <mem_init+0xda9>
f0101df9:	68 c3 3e 10 f0       	push   $0xf0103ec3
f0101dfe:	68 79 3c 10 f0       	push   $0xf0103c79
f0101e03:	68 54 03 00 00       	push   $0x354
f0101e08:	68 53 3c 10 f0       	push   $0xf0103c53
f0101e0d:	e8 79 e2 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101e12:	83 ec 08             	sub    $0x8,%esp
f0101e15:	68 00 10 00 00       	push   $0x1000
f0101e1a:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101e20:	e8 9b f1 ff ff       	call   f0100fc0 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101e25:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
f0101e2b:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e30:	89 f8                	mov    %edi,%eax
f0101e32:	e8 28 eb ff ff       	call   f010095f <check_va2pa>
f0101e37:	83 c4 10             	add    $0x10,%esp
f0101e3a:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e3d:	74 19                	je     f0101e58 <mem_init+0xdef>
f0101e3f:	68 7c 44 10 f0       	push   $0xf010447c
f0101e44:	68 79 3c 10 f0       	push   $0xf0103c79
f0101e49:	68 58 03 00 00       	push   $0x358
f0101e4e:	68 53 3c 10 f0       	push   $0xf0103c53
f0101e53:	e8 33 e2 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101e58:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e5d:	89 f8                	mov    %edi,%eax
f0101e5f:	e8 fb ea ff ff       	call   f010095f <check_va2pa>
f0101e64:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e67:	74 19                	je     f0101e82 <mem_init+0xe19>
f0101e69:	68 d8 44 10 f0       	push   $0xf01044d8
f0101e6e:	68 79 3c 10 f0       	push   $0xf0103c79
f0101e73:	68 59 03 00 00       	push   $0x359
f0101e78:	68 53 3c 10 f0       	push   $0xf0103c53
f0101e7d:	e8 09 e2 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f0101e82:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101e87:	74 19                	je     f0101ea2 <mem_init+0xe39>
f0101e89:	68 d8 3e 10 f0       	push   $0xf0103ed8
f0101e8e:	68 79 3c 10 f0       	push   $0xf0103c79
f0101e93:	68 5a 03 00 00       	push   $0x35a
f0101e98:	68 53 3c 10 f0       	push   $0xf0103c53
f0101e9d:	e8 e9 e1 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101ea2:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101ea7:	74 19                	je     f0101ec2 <mem_init+0xe59>
f0101ea9:	68 a6 3e 10 f0       	push   $0xf0103ea6
f0101eae:	68 79 3c 10 f0       	push   $0xf0103c79
f0101eb3:	68 5b 03 00 00       	push   $0x35b
f0101eb8:	68 53 3c 10 f0       	push   $0xf0103c53
f0101ebd:	e8 c9 e1 ff ff       	call   f010008b <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101ec2:	83 ec 0c             	sub    $0xc,%esp
f0101ec5:	6a 00                	push   $0x0
f0101ec7:	e8 b0 ee ff ff       	call   f0100d7c <page_alloc>
f0101ecc:	83 c4 10             	add    $0x10,%esp
f0101ecf:	39 c3                	cmp    %eax,%ebx
f0101ed1:	75 04                	jne    f0101ed7 <mem_init+0xe6e>
f0101ed3:	85 c0                	test   %eax,%eax
f0101ed5:	75 19                	jne    f0101ef0 <mem_init+0xe87>
f0101ed7:	68 00 45 10 f0       	push   $0xf0104500
f0101edc:	68 79 3c 10 f0       	push   $0xf0103c79
f0101ee1:	68 5e 03 00 00       	push   $0x35e
f0101ee6:	68 53 3c 10 f0       	push   $0xf0103c53
f0101eeb:	e8 9b e1 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101ef0:	83 ec 0c             	sub    $0xc,%esp
f0101ef3:	6a 00                	push   $0x0
f0101ef5:	e8 82 ee ff ff       	call   f0100d7c <page_alloc>
f0101efa:	83 c4 10             	add    $0x10,%esp
f0101efd:	85 c0                	test   %eax,%eax
f0101eff:	74 19                	je     f0101f1a <mem_init+0xeb1>
f0101f01:	68 fa 3d 10 f0       	push   $0xf0103dfa
f0101f06:	68 79 3c 10 f0       	push   $0xf0103c79
f0101f0b:	68 61 03 00 00       	push   $0x361
f0101f10:	68 53 3c 10 f0       	push   $0xf0103c53
f0101f15:	e8 71 e1 ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101f1a:	8b 0d 68 69 11 f0    	mov    0xf0116968,%ecx
f0101f20:	8b 11                	mov    (%ecx),%edx
f0101f22:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101f28:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f2b:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0101f31:	c1 f8 03             	sar    $0x3,%eax
f0101f34:	c1 e0 0c             	shl    $0xc,%eax
f0101f37:	39 c2                	cmp    %eax,%edx
f0101f39:	74 19                	je     f0101f54 <mem_init+0xeeb>
f0101f3b:	68 a4 41 10 f0       	push   $0xf01041a4
f0101f40:	68 79 3c 10 f0       	push   $0xf0103c79
f0101f45:	68 64 03 00 00       	push   $0x364
f0101f4a:	68 53 3c 10 f0       	push   $0xf0103c53
f0101f4f:	e8 37 e1 ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f0101f54:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101f5a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f5d:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101f62:	74 19                	je     f0101f7d <mem_init+0xf14>
f0101f64:	68 5d 3e 10 f0       	push   $0xf0103e5d
f0101f69:	68 79 3c 10 f0       	push   $0xf0103c79
f0101f6e:	68 66 03 00 00       	push   $0x366
f0101f73:	68 53 3c 10 f0       	push   $0xf0103c53
f0101f78:	e8 0e e1 ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f0101f7d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f80:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101f86:	83 ec 0c             	sub    $0xc,%esp
f0101f89:	50                   	push   %eax
f0101f8a:	e8 5d ee ff ff       	call   f0100dec <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101f8f:	83 c4 0c             	add    $0xc,%esp
f0101f92:	6a 01                	push   $0x1
f0101f94:	68 00 10 40 00       	push   $0x401000
f0101f99:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101f9f:	e8 7e ee ff ff       	call   f0100e22 <pgdir_walk>
f0101fa4:	89 c7                	mov    %eax,%edi
f0101fa6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101fa9:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f0101fae:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101fb1:	8b 40 04             	mov    0x4(%eax),%eax
f0101fb4:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101fb9:	8b 0d 64 69 11 f0    	mov    0xf0116964,%ecx
f0101fbf:	89 c2                	mov    %eax,%edx
f0101fc1:	c1 ea 0c             	shr    $0xc,%edx
f0101fc4:	83 c4 10             	add    $0x10,%esp
f0101fc7:	39 ca                	cmp    %ecx,%edx
f0101fc9:	72 15                	jb     f0101fe0 <mem_init+0xf77>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101fcb:	50                   	push   %eax
f0101fcc:	68 64 3f 10 f0       	push   $0xf0103f64
f0101fd1:	68 6d 03 00 00       	push   $0x36d
f0101fd6:	68 53 3c 10 f0       	push   $0xf0103c53
f0101fdb:	e8 ab e0 ff ff       	call   f010008b <_panic>
	assert(ptep == ptep1 + PTX(va));
f0101fe0:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0101fe5:	39 c7                	cmp    %eax,%edi
f0101fe7:	74 19                	je     f0102002 <mem_init+0xf99>
f0101fe9:	68 e9 3e 10 f0       	push   $0xf0103ee9
f0101fee:	68 79 3c 10 f0       	push   $0xf0103c79
f0101ff3:	68 6e 03 00 00       	push   $0x36e
f0101ff8:	68 53 3c 10 f0       	push   $0xf0103c53
f0101ffd:	e8 89 e0 ff ff       	call   f010008b <_panic>
	kern_pgdir[PDX(va)] = 0;
f0102002:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102005:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f010200c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010200f:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102015:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f010201b:	c1 f8 03             	sar    $0x3,%eax
f010201e:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102021:	89 c2                	mov    %eax,%edx
f0102023:	c1 ea 0c             	shr    $0xc,%edx
f0102026:	39 d1                	cmp    %edx,%ecx
f0102028:	77 12                	ja     f010203c <mem_init+0xfd3>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010202a:	50                   	push   %eax
f010202b:	68 64 3f 10 f0       	push   $0xf0103f64
f0102030:	6a 52                	push   $0x52
f0102032:	68 5f 3c 10 f0       	push   $0xf0103c5f
f0102037:	e8 4f e0 ff ff       	call   f010008b <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f010203c:	83 ec 04             	sub    $0x4,%esp
f010203f:	68 00 10 00 00       	push   $0x1000
f0102044:	68 ff 00 00 00       	push   $0xff
f0102049:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010204e:	50                   	push   %eax
f010204f:	e8 e7 11 00 00       	call   f010323b <memset>
	page_free(pp0);
f0102054:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102057:	89 3c 24             	mov    %edi,(%esp)
f010205a:	e8 8d ed ff ff       	call   f0100dec <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f010205f:	83 c4 0c             	add    $0xc,%esp
f0102062:	6a 01                	push   $0x1
f0102064:	6a 00                	push   $0x0
f0102066:	ff 35 68 69 11 f0    	pushl  0xf0116968
f010206c:	e8 b1 ed ff ff       	call   f0100e22 <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102071:	89 fa                	mov    %edi,%edx
f0102073:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f0102079:	c1 fa 03             	sar    $0x3,%edx
f010207c:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010207f:	89 d0                	mov    %edx,%eax
f0102081:	c1 e8 0c             	shr    $0xc,%eax
f0102084:	83 c4 10             	add    $0x10,%esp
f0102087:	3b 05 64 69 11 f0    	cmp    0xf0116964,%eax
f010208d:	72 12                	jb     f01020a1 <mem_init+0x1038>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010208f:	52                   	push   %edx
f0102090:	68 64 3f 10 f0       	push   $0xf0103f64
f0102095:	6a 52                	push   $0x52
f0102097:	68 5f 3c 10 f0       	push   $0xf0103c5f
f010209c:	e8 ea df ff ff       	call   f010008b <_panic>
	return (void *)(pa + KERNBASE);
f01020a1:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f01020a7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01020aa:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01020b0:	f6 00 01             	testb  $0x1,(%eax)
f01020b3:	74 19                	je     f01020ce <mem_init+0x1065>
f01020b5:	68 01 3f 10 f0       	push   $0xf0103f01
f01020ba:	68 79 3c 10 f0       	push   $0xf0103c79
f01020bf:	68 78 03 00 00       	push   $0x378
f01020c4:	68 53 3c 10 f0       	push   $0xf0103c53
f01020c9:	e8 bd df ff ff       	call   f010008b <_panic>
f01020ce:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f01020d1:	39 d0                	cmp    %edx,%eax
f01020d3:	75 db                	jne    f01020b0 <mem_init+0x1047>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f01020d5:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f01020da:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01020e0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01020e3:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f01020e9:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f01020ec:	89 0d 3c 65 11 f0    	mov    %ecx,0xf011653c

	// free the pages we took
	page_free(pp0);
f01020f2:	83 ec 0c             	sub    $0xc,%esp
f01020f5:	50                   	push   %eax
f01020f6:	e8 f1 ec ff ff       	call   f0100dec <page_free>
	page_free(pp1);
f01020fb:	89 1c 24             	mov    %ebx,(%esp)
f01020fe:	e8 e9 ec ff ff       	call   f0100dec <page_free>
	page_free(pp2);
f0102103:	89 34 24             	mov    %esi,(%esp)
f0102106:	e8 e1 ec ff ff       	call   f0100dec <page_free>

	cprintf("check_page() succeeded!\n");
f010210b:	c7 04 24 18 3f 10 f0 	movl   $0xf0103f18,(%esp)
f0102112:	e8 4b 06 00 00       	call   f0102762 <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), PTE_U);
f0102117:	a1 6c 69 11 f0       	mov    0xf011696c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010211c:	83 c4 10             	add    $0x10,%esp
f010211f:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102124:	77 15                	ja     f010213b <mem_init+0x10d2>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102126:	50                   	push   %eax
f0102127:	68 a8 40 10 f0       	push   $0xf01040a8
f010212c:	68 b5 00 00 00       	push   $0xb5
f0102131:	68 53 3c 10 f0       	push   $0xf0103c53
f0102136:	e8 50 df ff ff       	call   f010008b <_panic>
f010213b:	83 ec 08             	sub    $0x8,%esp
f010213e:	6a 04                	push   $0x4
f0102140:	05 00 00 00 10       	add    $0x10000000,%eax
f0102145:	50                   	push   %eax
f0102146:	b9 00 00 40 00       	mov    $0x400000,%ecx
f010214b:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102150:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f0102155:	e8 93 ed ff ff       	call   f0100eed <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010215a:	83 c4 10             	add    $0x10,%esp
f010215d:	b8 00 c0 10 f0       	mov    $0xf010c000,%eax
f0102162:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102167:	77 15                	ja     f010217e <mem_init+0x1115>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102169:	50                   	push   %eax
f010216a:	68 a8 40 10 f0       	push   $0xf01040a8
f010216f:	68 c2 00 00 00       	push   $0xc2
f0102174:	68 53 3c 10 f0       	push   $0xf0103c53
f0102179:	e8 0d df ff ff       	call   f010008b <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f010217e:	83 ec 08             	sub    $0x8,%esp
f0102181:	6a 02                	push   $0x2
f0102183:	68 00 c0 10 00       	push   $0x10c000
f0102188:	b9 00 80 00 00       	mov    $0x8000,%ecx
f010218d:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102192:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f0102197:	e8 51 ed ff ff       	call   f0100eed <boot_map_region>
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	//cprintf("%x\n",KERNBASE);
	boot_map_region(kern_pgdir, KERNBASE, -KERNBASE, 0, PTE_W);
f010219c:	83 c4 08             	add    $0x8,%esp
f010219f:	6a 02                	push   $0x2
f01021a1:	6a 00                	push   $0x0
f01021a3:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f01021a8:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01021ad:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f01021b2:	e8 36 ed ff ff       	call   f0100eed <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f01021b7:	8b 35 68 69 11 f0    	mov    0xf0116968,%esi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01021bd:	a1 64 69 11 f0       	mov    0xf0116964,%eax
f01021c2:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01021c5:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f01021cc:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01021d1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01021d4:	8b 3d 6c 69 11 f0    	mov    0xf011696c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01021da:	89 7d d0             	mov    %edi,-0x30(%ebp)
f01021dd:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01021e0:	bb 00 00 00 00       	mov    $0x0,%ebx
f01021e5:	eb 55                	jmp    f010223c <mem_init+0x11d3>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01021e7:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f01021ed:	89 f0                	mov    %esi,%eax
f01021ef:	e8 6b e7 ff ff       	call   f010095f <check_va2pa>
f01021f4:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f01021fb:	77 15                	ja     f0102212 <mem_init+0x11a9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01021fd:	57                   	push   %edi
f01021fe:	68 a8 40 10 f0       	push   $0xf01040a8
f0102203:	68 ba 02 00 00       	push   $0x2ba
f0102208:	68 53 3c 10 f0       	push   $0xf0103c53
f010220d:	e8 79 de ff ff       	call   f010008b <_panic>
f0102212:	8d 94 1f 00 00 00 10 	lea    0x10000000(%edi,%ebx,1),%edx
f0102219:	39 c2                	cmp    %eax,%edx
f010221b:	74 19                	je     f0102236 <mem_init+0x11cd>
f010221d:	68 24 45 10 f0       	push   $0xf0104524
f0102222:	68 79 3c 10 f0       	push   $0xf0103c79
f0102227:	68 ba 02 00 00       	push   $0x2ba
f010222c:	68 53 3c 10 f0       	push   $0xf0103c53
f0102231:	e8 55 de ff ff       	call   f010008b <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102236:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010223c:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f010223f:	77 a6                	ja     f01021e7 <mem_init+0x117e>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102241:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0102244:	c1 e7 0c             	shl    $0xc,%edi
f0102247:	bb 00 00 00 00       	mov    $0x0,%ebx
f010224c:	eb 30                	jmp    f010227e <mem_init+0x1215>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f010224e:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f0102254:	89 f0                	mov    %esi,%eax
f0102256:	e8 04 e7 ff ff       	call   f010095f <check_va2pa>
f010225b:	39 c3                	cmp    %eax,%ebx
f010225d:	74 19                	je     f0102278 <mem_init+0x120f>
f010225f:	68 58 45 10 f0       	push   $0xf0104558
f0102264:	68 79 3c 10 f0       	push   $0xf0103c79
f0102269:	68 bf 02 00 00       	push   $0x2bf
f010226e:	68 53 3c 10 f0       	push   $0xf0103c53
f0102273:	e8 13 de ff ff       	call   f010008b <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102278:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010227e:	39 fb                	cmp    %edi,%ebx
f0102280:	72 cc                	jb     f010224e <mem_init+0x11e5>
f0102282:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102287:	89 da                	mov    %ebx,%edx
f0102289:	89 f0                	mov    %esi,%eax
f010228b:	e8 cf e6 ff ff       	call   f010095f <check_va2pa>
f0102290:	8d 93 00 40 11 10    	lea    0x10114000(%ebx),%edx
f0102296:	39 c2                	cmp    %eax,%edx
f0102298:	74 19                	je     f01022b3 <mem_init+0x124a>
f010229a:	68 80 45 10 f0       	push   $0xf0104580
f010229f:	68 79 3c 10 f0       	push   $0xf0103c79
f01022a4:	68 c3 02 00 00       	push   $0x2c3
f01022a9:	68 53 3c 10 f0       	push   $0xf0103c53
f01022ae:	e8 d8 dd ff ff       	call   f010008b <_panic>
f01022b3:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01022b9:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f01022bf:	75 c6                	jne    f0102287 <mem_init+0x121e>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01022c1:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f01022c6:	89 f0                	mov    %esi,%eax
f01022c8:	e8 92 e6 ff ff       	call   f010095f <check_va2pa>
f01022cd:	83 f8 ff             	cmp    $0xffffffff,%eax
f01022d0:	74 51                	je     f0102323 <mem_init+0x12ba>
f01022d2:	68 c8 45 10 f0       	push   $0xf01045c8
f01022d7:	68 79 3c 10 f0       	push   $0xf0103c79
f01022dc:	68 c4 02 00 00       	push   $0x2c4
f01022e1:	68 53 3c 10 f0       	push   $0xf0103c53
f01022e6:	e8 a0 dd ff ff       	call   f010008b <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f01022eb:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f01022f0:	72 36                	jb     f0102328 <mem_init+0x12bf>
f01022f2:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f01022f7:	76 07                	jbe    f0102300 <mem_init+0x1297>
f01022f9:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01022fe:	75 28                	jne    f0102328 <mem_init+0x12bf>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f0102300:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f0102304:	0f 85 83 00 00 00    	jne    f010238d <mem_init+0x1324>
f010230a:	68 31 3f 10 f0       	push   $0xf0103f31
f010230f:	68 79 3c 10 f0       	push   $0xf0103c79
f0102314:	68 cc 02 00 00       	push   $0x2cc
f0102319:	68 53 3c 10 f0       	push   $0xf0103c53
f010231e:	e8 68 dd ff ff       	call   f010008b <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102323:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102328:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f010232d:	76 3f                	jbe    f010236e <mem_init+0x1305>
				assert(pgdir[i] & PTE_P);
f010232f:	8b 14 86             	mov    (%esi,%eax,4),%edx
f0102332:	f6 c2 01             	test   $0x1,%dl
f0102335:	75 19                	jne    f0102350 <mem_init+0x12e7>
f0102337:	68 31 3f 10 f0       	push   $0xf0103f31
f010233c:	68 79 3c 10 f0       	push   $0xf0103c79
f0102341:	68 d0 02 00 00       	push   $0x2d0
f0102346:	68 53 3c 10 f0       	push   $0xf0103c53
f010234b:	e8 3b dd ff ff       	call   f010008b <_panic>
				assert(pgdir[i] & PTE_W);
f0102350:	f6 c2 02             	test   $0x2,%dl
f0102353:	75 38                	jne    f010238d <mem_init+0x1324>
f0102355:	68 42 3f 10 f0       	push   $0xf0103f42
f010235a:	68 79 3c 10 f0       	push   $0xf0103c79
f010235f:	68 d1 02 00 00       	push   $0x2d1
f0102364:	68 53 3c 10 f0       	push   $0xf0103c53
f0102369:	e8 1d dd ff ff       	call   f010008b <_panic>
			} else
				assert(pgdir[i] == 0);
f010236e:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f0102372:	74 19                	je     f010238d <mem_init+0x1324>
f0102374:	68 53 3f 10 f0       	push   $0xf0103f53
f0102379:	68 79 3c 10 f0       	push   $0xf0103c79
f010237e:	68 d3 02 00 00       	push   $0x2d3
f0102383:	68 53 3c 10 f0       	push   $0xf0103c53
f0102388:	e8 fe dc ff ff       	call   f010008b <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f010238d:	83 c0 01             	add    $0x1,%eax
f0102390:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0102395:	0f 86 50 ff ff ff    	jbe    f01022eb <mem_init+0x1282>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f010239b:	83 ec 0c             	sub    $0xc,%esp
f010239e:	68 f8 45 10 f0       	push   $0xf01045f8
f01023a3:	e8 ba 03 00 00       	call   f0102762 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f01023a8:	a1 68 69 11 f0       	mov    0xf0116968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01023ad:	83 c4 10             	add    $0x10,%esp
f01023b0:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01023b5:	77 15                	ja     f01023cc <mem_init+0x1363>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01023b7:	50                   	push   %eax
f01023b8:	68 a8 40 10 f0       	push   $0xf01040a8
f01023bd:	68 d9 00 00 00       	push   $0xd9
f01023c2:	68 53 3c 10 f0       	push   $0xf0103c53
f01023c7:	e8 bf dc ff ff       	call   f010008b <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01023cc:	05 00 00 00 10       	add    $0x10000000,%eax
f01023d1:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f01023d4:	b8 00 00 00 00       	mov    $0x0,%eax
f01023d9:	e8 e5 e5 ff ff       	call   f01009c3 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f01023de:	0f 20 c0             	mov    %cr0,%eax
f01023e1:	83 e0 f3             	and    $0xfffffff3,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f01023e4:	0d 23 00 05 80       	or     $0x80050023,%eax
f01023e9:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01023ec:	83 ec 0c             	sub    $0xc,%esp
f01023ef:	6a 00                	push   $0x0
f01023f1:	e8 86 e9 ff ff       	call   f0100d7c <page_alloc>
f01023f6:	89 c3                	mov    %eax,%ebx
f01023f8:	83 c4 10             	add    $0x10,%esp
f01023fb:	85 c0                	test   %eax,%eax
f01023fd:	75 19                	jne    f0102418 <mem_init+0x13af>
f01023ff:	68 4f 3d 10 f0       	push   $0xf0103d4f
f0102404:	68 79 3c 10 f0       	push   $0xf0103c79
f0102409:	68 93 03 00 00       	push   $0x393
f010240e:	68 53 3c 10 f0       	push   $0xf0103c53
f0102413:	e8 73 dc ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0102418:	83 ec 0c             	sub    $0xc,%esp
f010241b:	6a 00                	push   $0x0
f010241d:	e8 5a e9 ff ff       	call   f0100d7c <page_alloc>
f0102422:	89 c7                	mov    %eax,%edi
f0102424:	83 c4 10             	add    $0x10,%esp
f0102427:	85 c0                	test   %eax,%eax
f0102429:	75 19                	jne    f0102444 <mem_init+0x13db>
f010242b:	68 65 3d 10 f0       	push   $0xf0103d65
f0102430:	68 79 3c 10 f0       	push   $0xf0103c79
f0102435:	68 94 03 00 00       	push   $0x394
f010243a:	68 53 3c 10 f0       	push   $0xf0103c53
f010243f:	e8 47 dc ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0102444:	83 ec 0c             	sub    $0xc,%esp
f0102447:	6a 00                	push   $0x0
f0102449:	e8 2e e9 ff ff       	call   f0100d7c <page_alloc>
f010244e:	89 c6                	mov    %eax,%esi
f0102450:	83 c4 10             	add    $0x10,%esp
f0102453:	85 c0                	test   %eax,%eax
f0102455:	75 19                	jne    f0102470 <mem_init+0x1407>
f0102457:	68 7b 3d 10 f0       	push   $0xf0103d7b
f010245c:	68 79 3c 10 f0       	push   $0xf0103c79
f0102461:	68 95 03 00 00       	push   $0x395
f0102466:	68 53 3c 10 f0       	push   $0xf0103c53
f010246b:	e8 1b dc ff ff       	call   f010008b <_panic>
	page_free(pp0);
f0102470:	83 ec 0c             	sub    $0xc,%esp
f0102473:	53                   	push   %ebx
f0102474:	e8 73 e9 ff ff       	call   f0100dec <page_free>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102479:	89 f8                	mov    %edi,%eax
f010247b:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0102481:	c1 f8 03             	sar    $0x3,%eax
f0102484:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102487:	89 c2                	mov    %eax,%edx
f0102489:	c1 ea 0c             	shr    $0xc,%edx
f010248c:	83 c4 10             	add    $0x10,%esp
f010248f:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f0102495:	72 12                	jb     f01024a9 <mem_init+0x1440>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102497:	50                   	push   %eax
f0102498:	68 64 3f 10 f0       	push   $0xf0103f64
f010249d:	6a 52                	push   $0x52
f010249f:	68 5f 3c 10 f0       	push   $0xf0103c5f
f01024a4:	e8 e2 db ff ff       	call   f010008b <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f01024a9:	83 ec 04             	sub    $0x4,%esp
f01024ac:	68 00 10 00 00       	push   $0x1000
f01024b1:	6a 01                	push   $0x1
f01024b3:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01024b8:	50                   	push   %eax
f01024b9:	e8 7d 0d 00 00       	call   f010323b <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01024be:	89 f0                	mov    %esi,%eax
f01024c0:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f01024c6:	c1 f8 03             	sar    $0x3,%eax
f01024c9:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01024cc:	89 c2                	mov    %eax,%edx
f01024ce:	c1 ea 0c             	shr    $0xc,%edx
f01024d1:	83 c4 10             	add    $0x10,%esp
f01024d4:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f01024da:	72 12                	jb     f01024ee <mem_init+0x1485>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01024dc:	50                   	push   %eax
f01024dd:	68 64 3f 10 f0       	push   $0xf0103f64
f01024e2:	6a 52                	push   $0x52
f01024e4:	68 5f 3c 10 f0       	push   $0xf0103c5f
f01024e9:	e8 9d db ff ff       	call   f010008b <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f01024ee:	83 ec 04             	sub    $0x4,%esp
f01024f1:	68 00 10 00 00       	push   $0x1000
f01024f6:	6a 02                	push   $0x2
f01024f8:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01024fd:	50                   	push   %eax
f01024fe:	e8 38 0d 00 00       	call   f010323b <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102503:	6a 02                	push   $0x2
f0102505:	68 00 10 00 00       	push   $0x1000
f010250a:	57                   	push   %edi
f010250b:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0102511:	e8 ed ea ff ff       	call   f0101003 <page_insert>
	assert(pp1->pp_ref == 1);
f0102516:	83 c4 20             	add    $0x20,%esp
f0102519:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f010251e:	74 19                	je     f0102539 <mem_init+0x14d0>
f0102520:	68 4c 3e 10 f0       	push   $0xf0103e4c
f0102525:	68 79 3c 10 f0       	push   $0xf0103c79
f010252a:	68 9a 03 00 00       	push   $0x39a
f010252f:	68 53 3c 10 f0       	push   $0xf0103c53
f0102534:	e8 52 db ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102539:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102540:	01 01 01 
f0102543:	74 19                	je     f010255e <mem_init+0x14f5>
f0102545:	68 18 46 10 f0       	push   $0xf0104618
f010254a:	68 79 3c 10 f0       	push   $0xf0103c79
f010254f:	68 9b 03 00 00       	push   $0x39b
f0102554:	68 53 3c 10 f0       	push   $0xf0103c53
f0102559:	e8 2d db ff ff       	call   f010008b <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f010255e:	6a 02                	push   $0x2
f0102560:	68 00 10 00 00       	push   $0x1000
f0102565:	56                   	push   %esi
f0102566:	ff 35 68 69 11 f0    	pushl  0xf0116968
f010256c:	e8 92 ea ff ff       	call   f0101003 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102571:	83 c4 10             	add    $0x10,%esp
f0102574:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f010257b:	02 02 02 
f010257e:	74 19                	je     f0102599 <mem_init+0x1530>
f0102580:	68 3c 46 10 f0       	push   $0xf010463c
f0102585:	68 79 3c 10 f0       	push   $0xf0103c79
f010258a:	68 9d 03 00 00       	push   $0x39d
f010258f:	68 53 3c 10 f0       	push   $0xf0103c53
f0102594:	e8 f2 da ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0102599:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010259e:	74 19                	je     f01025b9 <mem_init+0x1550>
f01025a0:	68 6e 3e 10 f0       	push   $0xf0103e6e
f01025a5:	68 79 3c 10 f0       	push   $0xf0103c79
f01025aa:	68 9e 03 00 00       	push   $0x39e
f01025af:	68 53 3c 10 f0       	push   $0xf0103c53
f01025b4:	e8 d2 da ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f01025b9:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f01025be:	74 19                	je     f01025d9 <mem_init+0x1570>
f01025c0:	68 d8 3e 10 f0       	push   $0xf0103ed8
f01025c5:	68 79 3c 10 f0       	push   $0xf0103c79
f01025ca:	68 9f 03 00 00       	push   $0x39f
f01025cf:	68 53 3c 10 f0       	push   $0xf0103c53
f01025d4:	e8 b2 da ff ff       	call   f010008b <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f01025d9:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f01025e0:	03 03 03 
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01025e3:	89 f0                	mov    %esi,%eax
f01025e5:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f01025eb:	c1 f8 03             	sar    $0x3,%eax
f01025ee:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01025f1:	89 c2                	mov    %eax,%edx
f01025f3:	c1 ea 0c             	shr    $0xc,%edx
f01025f6:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f01025fc:	72 12                	jb     f0102610 <mem_init+0x15a7>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01025fe:	50                   	push   %eax
f01025ff:	68 64 3f 10 f0       	push   $0xf0103f64
f0102604:	6a 52                	push   $0x52
f0102606:	68 5f 3c 10 f0       	push   $0xf0103c5f
f010260b:	e8 7b da ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102610:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102617:	03 03 03 
f010261a:	74 19                	je     f0102635 <mem_init+0x15cc>
f010261c:	68 60 46 10 f0       	push   $0xf0104660
f0102621:	68 79 3c 10 f0       	push   $0xf0103c79
f0102626:	68 a1 03 00 00       	push   $0x3a1
f010262b:	68 53 3c 10 f0       	push   $0xf0103c53
f0102630:	e8 56 da ff ff       	call   f010008b <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102635:	83 ec 08             	sub    $0x8,%esp
f0102638:	68 00 10 00 00       	push   $0x1000
f010263d:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0102643:	e8 78 e9 ff ff       	call   f0100fc0 <page_remove>
	assert(pp2->pp_ref == 0);
f0102648:	83 c4 10             	add    $0x10,%esp
f010264b:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102650:	74 19                	je     f010266b <mem_init+0x1602>
f0102652:	68 a6 3e 10 f0       	push   $0xf0103ea6
f0102657:	68 79 3c 10 f0       	push   $0xf0103c79
f010265c:	68 a3 03 00 00       	push   $0x3a3
f0102661:	68 53 3c 10 f0       	push   $0xf0103c53
f0102666:	e8 20 da ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010266b:	8b 0d 68 69 11 f0    	mov    0xf0116968,%ecx
f0102671:	8b 11                	mov    (%ecx),%edx
f0102673:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102679:	89 d8                	mov    %ebx,%eax
f010267b:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0102681:	c1 f8 03             	sar    $0x3,%eax
f0102684:	c1 e0 0c             	shl    $0xc,%eax
f0102687:	39 c2                	cmp    %eax,%edx
f0102689:	74 19                	je     f01026a4 <mem_init+0x163b>
f010268b:	68 a4 41 10 f0       	push   $0xf01041a4
f0102690:	68 79 3c 10 f0       	push   $0xf0103c79
f0102695:	68 a6 03 00 00       	push   $0x3a6
f010269a:	68 53 3c 10 f0       	push   $0xf0103c53
f010269f:	e8 e7 d9 ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f01026a4:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f01026aa:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01026af:	74 19                	je     f01026ca <mem_init+0x1661>
f01026b1:	68 5d 3e 10 f0       	push   $0xf0103e5d
f01026b6:	68 79 3c 10 f0       	push   $0xf0103c79
f01026bb:	68 a8 03 00 00       	push   $0x3a8
f01026c0:	68 53 3c 10 f0       	push   $0xf0103c53
f01026c5:	e8 c1 d9 ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f01026ca:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f01026d0:	83 ec 0c             	sub    $0xc,%esp
f01026d3:	53                   	push   %ebx
f01026d4:	e8 13 e7 ff ff       	call   f0100dec <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f01026d9:	c7 04 24 8c 46 10 f0 	movl   $0xf010468c,(%esp)
f01026e0:	e8 7d 00 00 00       	call   f0102762 <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f01026e5:	83 c4 10             	add    $0x10,%esp
f01026e8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01026eb:	5b                   	pop    %ebx
f01026ec:	5e                   	pop    %esi
f01026ed:	5f                   	pop    %edi
f01026ee:	5d                   	pop    %ebp
f01026ef:	c3                   	ret    

f01026f0 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f01026f0:	55                   	push   %ebp
f01026f1:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01026f3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01026f6:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f01026f9:	5d                   	pop    %ebp
f01026fa:	c3                   	ret    

f01026fb <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01026fb:	55                   	push   %ebp
f01026fc:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01026fe:	ba 70 00 00 00       	mov    $0x70,%edx
f0102703:	8b 45 08             	mov    0x8(%ebp),%eax
f0102706:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102707:	ba 71 00 00 00       	mov    $0x71,%edx
f010270c:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f010270d:	0f b6 c0             	movzbl %al,%eax
}
f0102710:	5d                   	pop    %ebp
f0102711:	c3                   	ret    

f0102712 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102712:	55                   	push   %ebp
f0102713:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102715:	ba 70 00 00 00       	mov    $0x70,%edx
f010271a:	8b 45 08             	mov    0x8(%ebp),%eax
f010271d:	ee                   	out    %al,(%dx)
f010271e:	ba 71 00 00 00       	mov    $0x71,%edx
f0102723:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102726:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102727:	5d                   	pop    %ebp
f0102728:	c3                   	ret    

f0102729 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102729:	55                   	push   %ebp
f010272a:	89 e5                	mov    %esp,%ebp
f010272c:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f010272f:	ff 75 08             	pushl  0x8(%ebp)
f0102732:	e8 bb de ff ff       	call   f01005f2 <cputchar>
	*cnt++;
}
f0102737:	83 c4 10             	add    $0x10,%esp
f010273a:	c9                   	leave  
f010273b:	c3                   	ret    

f010273c <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f010273c:	55                   	push   %ebp
f010273d:	89 e5                	mov    %esp,%ebp
f010273f:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0102742:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102749:	ff 75 0c             	pushl  0xc(%ebp)
f010274c:	ff 75 08             	pushl  0x8(%ebp)
f010274f:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102752:	50                   	push   %eax
f0102753:	68 29 27 10 f0       	push   $0xf0102729
f0102758:	e8 52 04 00 00       	call   f0102baf <vprintfmt>
	return cnt;
}
f010275d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102760:	c9                   	leave  
f0102761:	c3                   	ret    

f0102762 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102762:	55                   	push   %ebp
f0102763:	89 e5                	mov    %esp,%ebp
f0102765:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102768:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f010276b:	50                   	push   %eax
f010276c:	ff 75 08             	pushl  0x8(%ebp)
f010276f:	e8 c8 ff ff ff       	call   f010273c <vcprintf>
	va_end(ap);

	return cnt;
}
f0102774:	c9                   	leave  
f0102775:	c3                   	ret    

f0102776 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102776:	55                   	push   %ebp
f0102777:	89 e5                	mov    %esp,%ebp
f0102779:	57                   	push   %edi
f010277a:	56                   	push   %esi
f010277b:	53                   	push   %ebx
f010277c:	83 ec 14             	sub    $0x14,%esp
f010277f:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102782:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0102785:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102788:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f010278b:	8b 1a                	mov    (%edx),%ebx
f010278d:	8b 01                	mov    (%ecx),%eax
f010278f:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102792:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0102799:	eb 7f                	jmp    f010281a <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f010279b:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010279e:	01 d8                	add    %ebx,%eax
f01027a0:	89 c6                	mov    %eax,%esi
f01027a2:	c1 ee 1f             	shr    $0x1f,%esi
f01027a5:	01 c6                	add    %eax,%esi
f01027a7:	d1 fe                	sar    %esi
f01027a9:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01027ac:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01027af:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01027b2:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01027b4:	eb 03                	jmp    f01027b9 <stab_binsearch+0x43>
			m--;
f01027b6:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01027b9:	39 c3                	cmp    %eax,%ebx
f01027bb:	7f 0d                	jg     f01027ca <stab_binsearch+0x54>
f01027bd:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01027c1:	83 ea 0c             	sub    $0xc,%edx
f01027c4:	39 f9                	cmp    %edi,%ecx
f01027c6:	75 ee                	jne    f01027b6 <stab_binsearch+0x40>
f01027c8:	eb 05                	jmp    f01027cf <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01027ca:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f01027cd:	eb 4b                	jmp    f010281a <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01027cf:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01027d2:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01027d5:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01027d9:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01027dc:	76 11                	jbe    f01027ef <stab_binsearch+0x79>
			*region_left = m;
f01027de:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01027e1:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01027e3:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01027e6:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01027ed:	eb 2b                	jmp    f010281a <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01027ef:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01027f2:	73 14                	jae    f0102808 <stab_binsearch+0x92>
			*region_right = m - 1;
f01027f4:	83 e8 01             	sub    $0x1,%eax
f01027f7:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01027fa:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01027fd:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01027ff:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0102806:	eb 12                	jmp    f010281a <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0102808:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010280b:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f010280d:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0102811:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102813:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f010281a:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f010281d:	0f 8e 78 ff ff ff    	jle    f010279b <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0102823:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0102827:	75 0f                	jne    f0102838 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0102829:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010282c:	8b 00                	mov    (%eax),%eax
f010282e:	83 e8 01             	sub    $0x1,%eax
f0102831:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0102834:	89 06                	mov    %eax,(%esi)
f0102836:	eb 2c                	jmp    f0102864 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102838:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010283b:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f010283d:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102840:	8b 0e                	mov    (%esi),%ecx
f0102842:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0102845:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0102848:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010284b:	eb 03                	jmp    f0102850 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f010284d:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102850:	39 c8                	cmp    %ecx,%eax
f0102852:	7e 0b                	jle    f010285f <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0102854:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0102858:	83 ea 0c             	sub    $0xc,%edx
f010285b:	39 df                	cmp    %ebx,%edi
f010285d:	75 ee                	jne    f010284d <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f010285f:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102862:	89 06                	mov    %eax,(%esi)
	}
}
f0102864:	83 c4 14             	add    $0x14,%esp
f0102867:	5b                   	pop    %ebx
f0102868:	5e                   	pop    %esi
f0102869:	5f                   	pop    %edi
f010286a:	5d                   	pop    %ebp
f010286b:	c3                   	ret    

f010286c <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f010286c:	55                   	push   %ebp
f010286d:	89 e5                	mov    %esp,%ebp
f010286f:	57                   	push   %edi
f0102870:	56                   	push   %esi
f0102871:	53                   	push   %ebx
f0102872:	83 ec 3c             	sub    $0x3c,%esp
f0102875:	8b 75 08             	mov    0x8(%ebp),%esi
f0102878:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f010287b:	c7 03 b8 46 10 f0    	movl   $0xf01046b8,(%ebx)
	info->eip_line = 0;
f0102881:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0102888:	c7 43 08 b8 46 10 f0 	movl   $0xf01046b8,0x8(%ebx)
	info->eip_fn_namelen = 9;
f010288f:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0102896:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0102899:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01028a0:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f01028a6:	76 11                	jbe    f01028b9 <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01028a8:	b8 45 bf 10 f0       	mov    $0xf010bf45,%eax
f01028ad:	3d 85 a1 10 f0       	cmp    $0xf010a185,%eax
f01028b2:	77 19                	ja     f01028cd <debuginfo_eip+0x61>
f01028b4:	e9 aa 01 00 00       	jmp    f0102a63 <debuginfo_eip+0x1f7>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f01028b9:	83 ec 04             	sub    $0x4,%esp
f01028bc:	68 c2 46 10 f0       	push   $0xf01046c2
f01028c1:	6a 7f                	push   $0x7f
f01028c3:	68 cf 46 10 f0       	push   $0xf01046cf
f01028c8:	e8 be d7 ff ff       	call   f010008b <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01028cd:	80 3d 44 bf 10 f0 00 	cmpb   $0x0,0xf010bf44
f01028d4:	0f 85 90 01 00 00    	jne    f0102a6a <debuginfo_eip+0x1fe>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01028da:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01028e1:	b8 84 a1 10 f0       	mov    $0xf010a184,%eax
f01028e6:	2d 10 49 10 f0       	sub    $0xf0104910,%eax
f01028eb:	c1 f8 02             	sar    $0x2,%eax
f01028ee:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f01028f4:	83 e8 01             	sub    $0x1,%eax
f01028f7:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01028fa:	83 ec 08             	sub    $0x8,%esp
f01028fd:	56                   	push   %esi
f01028fe:	6a 64                	push   $0x64
f0102900:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0102903:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0102906:	b8 10 49 10 f0       	mov    $0xf0104910,%eax
f010290b:	e8 66 fe ff ff       	call   f0102776 <stab_binsearch>
	if (lfile == 0)
f0102910:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102913:	83 c4 10             	add    $0x10,%esp
f0102916:	85 c0                	test   %eax,%eax
f0102918:	0f 84 53 01 00 00    	je     f0102a71 <debuginfo_eip+0x205>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f010291e:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0102921:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102924:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0102927:	83 ec 08             	sub    $0x8,%esp
f010292a:	56                   	push   %esi
f010292b:	6a 24                	push   $0x24
f010292d:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0102930:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0102933:	b8 10 49 10 f0       	mov    $0xf0104910,%eax
f0102938:	e8 39 fe ff ff       	call   f0102776 <stab_binsearch>

	if (lfun <= rfun) {
f010293d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102940:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102943:	83 c4 10             	add    $0x10,%esp
f0102946:	39 d0                	cmp    %edx,%eax
f0102948:	7f 40                	jg     f010298a <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f010294a:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f010294d:	c1 e1 02             	shl    $0x2,%ecx
f0102950:	8d b9 10 49 10 f0    	lea    -0xfefb6f0(%ecx),%edi
f0102956:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0102959:	8b b9 10 49 10 f0    	mov    -0xfefb6f0(%ecx),%edi
f010295f:	b9 45 bf 10 f0       	mov    $0xf010bf45,%ecx
f0102964:	81 e9 85 a1 10 f0    	sub    $0xf010a185,%ecx
f010296a:	39 cf                	cmp    %ecx,%edi
f010296c:	73 09                	jae    f0102977 <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f010296e:	81 c7 85 a1 10 f0    	add    $0xf010a185,%edi
f0102974:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0102977:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f010297a:	8b 4f 08             	mov    0x8(%edi),%ecx
f010297d:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0102980:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0102982:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0102985:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0102988:	eb 0f                	jmp    f0102999 <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f010298a:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f010298d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102990:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0102993:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102996:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0102999:	83 ec 08             	sub    $0x8,%esp
f010299c:	6a 3a                	push   $0x3a
f010299e:	ff 73 08             	pushl  0x8(%ebx)
f01029a1:	e8 79 08 00 00       	call   f010321f <strfind>
f01029a6:	2b 43 08             	sub    0x8(%ebx),%eax
f01029a9:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f01029ac:	83 c4 08             	add    $0x8,%esp
f01029af:	56                   	push   %esi
f01029b0:	6a 44                	push   $0x44
f01029b2:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f01029b5:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f01029b8:	b8 10 49 10 f0       	mov    $0xf0104910,%eax
f01029bd:	e8 b4 fd ff ff       	call   f0102776 <stab_binsearch>
	//cprintf("%d	%d",lline,rline);
	if(lline <= rline)
f01029c2:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01029c5:	83 c4 10             	add    $0x10,%esp
f01029c8:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f01029cb:	0f 8f a7 00 00 00    	jg     f0102a78 <debuginfo_eip+0x20c>
		info->eip_line = stabs[lline].n_desc;
f01029d1:	8d 04 52             	lea    (%edx,%edx,2),%eax
f01029d4:	8d 04 85 10 49 10 f0 	lea    -0xfefb6f0(,%eax,4),%eax
f01029db:	0f b7 48 06          	movzwl 0x6(%eax),%ecx
f01029df:	89 4b 04             	mov    %ecx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01029e2:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01029e5:	eb 06                	jmp    f01029ed <debuginfo_eip+0x181>
f01029e7:	83 ea 01             	sub    $0x1,%edx
f01029ea:	83 e8 0c             	sub    $0xc,%eax
f01029ed:	39 d6                	cmp    %edx,%esi
f01029ef:	7f 34                	jg     f0102a25 <debuginfo_eip+0x1b9>
	       && stabs[lline].n_type != N_SOL
f01029f1:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f01029f5:	80 f9 84             	cmp    $0x84,%cl
f01029f8:	74 0b                	je     f0102a05 <debuginfo_eip+0x199>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01029fa:	80 f9 64             	cmp    $0x64,%cl
f01029fd:	75 e8                	jne    f01029e7 <debuginfo_eip+0x17b>
f01029ff:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0102a03:	74 e2                	je     f01029e7 <debuginfo_eip+0x17b>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0102a05:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0102a08:	8b 14 85 10 49 10 f0 	mov    -0xfefb6f0(,%eax,4),%edx
f0102a0f:	b8 45 bf 10 f0       	mov    $0xf010bf45,%eax
f0102a14:	2d 85 a1 10 f0       	sub    $0xf010a185,%eax
f0102a19:	39 c2                	cmp    %eax,%edx
f0102a1b:	73 08                	jae    f0102a25 <debuginfo_eip+0x1b9>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0102a1d:	81 c2 85 a1 10 f0    	add    $0xf010a185,%edx
f0102a23:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102a25:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102a28:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102a2b:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102a30:	39 f2                	cmp    %esi,%edx
f0102a32:	7d 50                	jge    f0102a84 <debuginfo_eip+0x218>
		for (lline = lfun + 1;
f0102a34:	83 c2 01             	add    $0x1,%edx
f0102a37:	89 d0                	mov    %edx,%eax
f0102a39:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0102a3c:	8d 14 95 10 49 10 f0 	lea    -0xfefb6f0(,%edx,4),%edx
f0102a43:	eb 04                	jmp    f0102a49 <debuginfo_eip+0x1dd>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0102a45:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0102a49:	39 c6                	cmp    %eax,%esi
f0102a4b:	7e 32                	jle    f0102a7f <debuginfo_eip+0x213>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0102a4d:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0102a51:	83 c0 01             	add    $0x1,%eax
f0102a54:	83 c2 0c             	add    $0xc,%edx
f0102a57:	80 f9 a0             	cmp    $0xa0,%cl
f0102a5a:	74 e9                	je     f0102a45 <debuginfo_eip+0x1d9>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102a5c:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a61:	eb 21                	jmp    f0102a84 <debuginfo_eip+0x218>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0102a63:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a68:	eb 1a                	jmp    f0102a84 <debuginfo_eip+0x218>
f0102a6a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a6f:	eb 13                	jmp    f0102a84 <debuginfo_eip+0x218>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0102a71:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a76:	eb 0c                	jmp    f0102a84 <debuginfo_eip+0x218>
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
	//cprintf("%d	%d",lline,rline);
	if(lline <= rline)
		info->eip_line = stabs[lline].n_desc;
	else
		return -1;
f0102a78:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a7d:	eb 05                	jmp    f0102a84 <debuginfo_eip+0x218>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102a7f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102a84:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102a87:	5b                   	pop    %ebx
f0102a88:	5e                   	pop    %esi
f0102a89:	5f                   	pop    %edi
f0102a8a:	5d                   	pop    %ebp
f0102a8b:	c3                   	ret    

f0102a8c <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0102a8c:	55                   	push   %ebp
f0102a8d:	89 e5                	mov    %esp,%ebp
f0102a8f:	57                   	push   %edi
f0102a90:	56                   	push   %esi
f0102a91:	53                   	push   %ebx
f0102a92:	83 ec 1c             	sub    $0x1c,%esp
f0102a95:	89 c7                	mov    %eax,%edi
f0102a97:	89 d6                	mov    %edx,%esi
f0102a99:	8b 45 08             	mov    0x8(%ebp),%eax
f0102a9c:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102a9f:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102aa2:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0102aa5:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0102aa8:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102aad:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102ab0:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0102ab3:	39 d3                	cmp    %edx,%ebx
f0102ab5:	72 05                	jb     f0102abc <printnum+0x30>
f0102ab7:	39 45 10             	cmp    %eax,0x10(%ebp)
f0102aba:	77 45                	ja     f0102b01 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0102abc:	83 ec 0c             	sub    $0xc,%esp
f0102abf:	ff 75 18             	pushl  0x18(%ebp)
f0102ac2:	8b 45 14             	mov    0x14(%ebp),%eax
f0102ac5:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0102ac8:	53                   	push   %ebx
f0102ac9:	ff 75 10             	pushl  0x10(%ebp)
f0102acc:	83 ec 08             	sub    $0x8,%esp
f0102acf:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102ad2:	ff 75 e0             	pushl  -0x20(%ebp)
f0102ad5:	ff 75 dc             	pushl  -0x24(%ebp)
f0102ad8:	ff 75 d8             	pushl  -0x28(%ebp)
f0102adb:	e8 60 09 00 00       	call   f0103440 <__udivdi3>
f0102ae0:	83 c4 18             	add    $0x18,%esp
f0102ae3:	52                   	push   %edx
f0102ae4:	50                   	push   %eax
f0102ae5:	89 f2                	mov    %esi,%edx
f0102ae7:	89 f8                	mov    %edi,%eax
f0102ae9:	e8 9e ff ff ff       	call   f0102a8c <printnum>
f0102aee:	83 c4 20             	add    $0x20,%esp
f0102af1:	eb 18                	jmp    f0102b0b <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0102af3:	83 ec 08             	sub    $0x8,%esp
f0102af6:	56                   	push   %esi
f0102af7:	ff 75 18             	pushl  0x18(%ebp)
f0102afa:	ff d7                	call   *%edi
f0102afc:	83 c4 10             	add    $0x10,%esp
f0102aff:	eb 03                	jmp    f0102b04 <printnum+0x78>
f0102b01:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0102b04:	83 eb 01             	sub    $0x1,%ebx
f0102b07:	85 db                	test   %ebx,%ebx
f0102b09:	7f e8                	jg     f0102af3 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0102b0b:	83 ec 08             	sub    $0x8,%esp
f0102b0e:	56                   	push   %esi
f0102b0f:	83 ec 04             	sub    $0x4,%esp
f0102b12:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102b15:	ff 75 e0             	pushl  -0x20(%ebp)
f0102b18:	ff 75 dc             	pushl  -0x24(%ebp)
f0102b1b:	ff 75 d8             	pushl  -0x28(%ebp)
f0102b1e:	e8 4d 0a 00 00       	call   f0103570 <__umoddi3>
f0102b23:	83 c4 14             	add    $0x14,%esp
f0102b26:	0f be 80 dd 46 10 f0 	movsbl -0xfefb923(%eax),%eax
f0102b2d:	50                   	push   %eax
f0102b2e:	ff d7                	call   *%edi
}
f0102b30:	83 c4 10             	add    $0x10,%esp
f0102b33:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102b36:	5b                   	pop    %ebx
f0102b37:	5e                   	pop    %esi
f0102b38:	5f                   	pop    %edi
f0102b39:	5d                   	pop    %ebp
f0102b3a:	c3                   	ret    

f0102b3b <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0102b3b:	55                   	push   %ebp
f0102b3c:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0102b3e:	83 fa 01             	cmp    $0x1,%edx
f0102b41:	7e 0e                	jle    f0102b51 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0102b43:	8b 10                	mov    (%eax),%edx
f0102b45:	8d 4a 08             	lea    0x8(%edx),%ecx
f0102b48:	89 08                	mov    %ecx,(%eax)
f0102b4a:	8b 02                	mov    (%edx),%eax
f0102b4c:	8b 52 04             	mov    0x4(%edx),%edx
f0102b4f:	eb 22                	jmp    f0102b73 <getuint+0x38>
	else if (lflag)
f0102b51:	85 d2                	test   %edx,%edx
f0102b53:	74 10                	je     f0102b65 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0102b55:	8b 10                	mov    (%eax),%edx
f0102b57:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102b5a:	89 08                	mov    %ecx,(%eax)
f0102b5c:	8b 02                	mov    (%edx),%eax
f0102b5e:	ba 00 00 00 00       	mov    $0x0,%edx
f0102b63:	eb 0e                	jmp    f0102b73 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0102b65:	8b 10                	mov    (%eax),%edx
f0102b67:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102b6a:	89 08                	mov    %ecx,(%eax)
f0102b6c:	8b 02                	mov    (%edx),%eax
f0102b6e:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0102b73:	5d                   	pop    %ebp
f0102b74:	c3                   	ret    

f0102b75 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0102b75:	55                   	push   %ebp
f0102b76:	89 e5                	mov    %esp,%ebp
f0102b78:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0102b7b:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0102b7f:	8b 10                	mov    (%eax),%edx
f0102b81:	3b 50 04             	cmp    0x4(%eax),%edx
f0102b84:	73 0a                	jae    f0102b90 <sprintputch+0x1b>
		*b->buf++ = ch;
f0102b86:	8d 4a 01             	lea    0x1(%edx),%ecx
f0102b89:	89 08                	mov    %ecx,(%eax)
f0102b8b:	8b 45 08             	mov    0x8(%ebp),%eax
f0102b8e:	88 02                	mov    %al,(%edx)
}
f0102b90:	5d                   	pop    %ebp
f0102b91:	c3                   	ret    

f0102b92 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0102b92:	55                   	push   %ebp
f0102b93:	89 e5                	mov    %esp,%ebp
f0102b95:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0102b98:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0102b9b:	50                   	push   %eax
f0102b9c:	ff 75 10             	pushl  0x10(%ebp)
f0102b9f:	ff 75 0c             	pushl  0xc(%ebp)
f0102ba2:	ff 75 08             	pushl  0x8(%ebp)
f0102ba5:	e8 05 00 00 00       	call   f0102baf <vprintfmt>
	va_end(ap);
}
f0102baa:	83 c4 10             	add    $0x10,%esp
f0102bad:	c9                   	leave  
f0102bae:	c3                   	ret    

f0102baf <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0102baf:	55                   	push   %ebp
f0102bb0:	89 e5                	mov    %esp,%ebp
f0102bb2:	57                   	push   %edi
f0102bb3:	56                   	push   %esi
f0102bb4:	53                   	push   %ebx
f0102bb5:	83 ec 2c             	sub    $0x2c,%esp
f0102bb8:	8b 75 08             	mov    0x8(%ebp),%esi
f0102bbb:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102bbe:	8b 7d 10             	mov    0x10(%ebp),%edi
f0102bc1:	eb 12                	jmp    f0102bd5 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0102bc3:	85 c0                	test   %eax,%eax
f0102bc5:	0f 84 a9 03 00 00    	je     f0102f74 <vprintfmt+0x3c5>
				return;
			putch(ch, putdat);
f0102bcb:	83 ec 08             	sub    $0x8,%esp
f0102bce:	53                   	push   %ebx
f0102bcf:	50                   	push   %eax
f0102bd0:	ff d6                	call   *%esi
f0102bd2:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0102bd5:	83 c7 01             	add    $0x1,%edi
f0102bd8:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102bdc:	83 f8 25             	cmp    $0x25,%eax
f0102bdf:	75 e2                	jne    f0102bc3 <vprintfmt+0x14>
f0102be1:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0102be5:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0102bec:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102bf3:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0102bfa:	ba 00 00 00 00       	mov    $0x0,%edx
f0102bff:	eb 07                	jmp    f0102c08 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c01:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0102c04:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c08:	8d 47 01             	lea    0x1(%edi),%eax
f0102c0b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102c0e:	0f b6 07             	movzbl (%edi),%eax
f0102c11:	0f b6 c8             	movzbl %al,%ecx
f0102c14:	83 e8 23             	sub    $0x23,%eax
f0102c17:	3c 55                	cmp    $0x55,%al
f0102c19:	0f 87 3a 03 00 00    	ja     f0102f59 <vprintfmt+0x3aa>
f0102c1f:	0f b6 c0             	movzbl %al,%eax
f0102c22:	ff 24 85 80 47 10 f0 	jmp    *-0xfefb880(,%eax,4)
f0102c29:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0102c2c:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0102c30:	eb d6                	jmp    f0102c08 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c32:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102c35:	b8 00 00 00 00       	mov    $0x0,%eax
f0102c3a:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0102c3d:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0102c40:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0102c44:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0102c47:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0102c4a:	83 fa 09             	cmp    $0x9,%edx
f0102c4d:	77 39                	ja     f0102c88 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0102c4f:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0102c52:	eb e9                	jmp    f0102c3d <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0102c54:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c57:	8d 48 04             	lea    0x4(%eax),%ecx
f0102c5a:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0102c5d:	8b 00                	mov    (%eax),%eax
f0102c5f:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c62:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0102c65:	eb 27                	jmp    f0102c8e <vprintfmt+0xdf>
f0102c67:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102c6a:	85 c0                	test   %eax,%eax
f0102c6c:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102c71:	0f 49 c8             	cmovns %eax,%ecx
f0102c74:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c77:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102c7a:	eb 8c                	jmp    f0102c08 <vprintfmt+0x59>
f0102c7c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0102c7f:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0102c86:	eb 80                	jmp    f0102c08 <vprintfmt+0x59>
f0102c88:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0102c8b:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0102c8e:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102c92:	0f 89 70 ff ff ff    	jns    f0102c08 <vprintfmt+0x59>
				width = precision, precision = -1;
f0102c98:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102c9b:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102c9e:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102ca5:	e9 5e ff ff ff       	jmp    f0102c08 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0102caa:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102cad:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0102cb0:	e9 53 ff ff ff       	jmp    f0102c08 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102cb5:	8b 45 14             	mov    0x14(%ebp),%eax
f0102cb8:	8d 50 04             	lea    0x4(%eax),%edx
f0102cbb:	89 55 14             	mov    %edx,0x14(%ebp)
f0102cbe:	83 ec 08             	sub    $0x8,%esp
f0102cc1:	53                   	push   %ebx
f0102cc2:	ff 30                	pushl  (%eax)
f0102cc4:	ff d6                	call   *%esi
			break;
f0102cc6:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102cc9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0102ccc:	e9 04 ff ff ff       	jmp    f0102bd5 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102cd1:	8b 45 14             	mov    0x14(%ebp),%eax
f0102cd4:	8d 50 04             	lea    0x4(%eax),%edx
f0102cd7:	89 55 14             	mov    %edx,0x14(%ebp)
f0102cda:	8b 00                	mov    (%eax),%eax
f0102cdc:	99                   	cltd   
f0102cdd:	31 d0                	xor    %edx,%eax
f0102cdf:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0102ce1:	83 f8 07             	cmp    $0x7,%eax
f0102ce4:	7f 0b                	jg     f0102cf1 <vprintfmt+0x142>
f0102ce6:	8b 14 85 e0 48 10 f0 	mov    -0xfefb720(,%eax,4),%edx
f0102ced:	85 d2                	test   %edx,%edx
f0102cef:	75 18                	jne    f0102d09 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0102cf1:	50                   	push   %eax
f0102cf2:	68 f5 46 10 f0       	push   $0xf01046f5
f0102cf7:	53                   	push   %ebx
f0102cf8:	56                   	push   %esi
f0102cf9:	e8 94 fe ff ff       	call   f0102b92 <printfmt>
f0102cfe:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102d01:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0102d04:	e9 cc fe ff ff       	jmp    f0102bd5 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0102d09:	52                   	push   %edx
f0102d0a:	68 8b 3c 10 f0       	push   $0xf0103c8b
f0102d0f:	53                   	push   %ebx
f0102d10:	56                   	push   %esi
f0102d11:	e8 7c fe ff ff       	call   f0102b92 <printfmt>
f0102d16:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102d19:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102d1c:	e9 b4 fe ff ff       	jmp    f0102bd5 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102d21:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d24:	8d 50 04             	lea    0x4(%eax),%edx
f0102d27:	89 55 14             	mov    %edx,0x14(%ebp)
f0102d2a:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0102d2c:	85 ff                	test   %edi,%edi
f0102d2e:	b8 ee 46 10 f0       	mov    $0xf01046ee,%eax
f0102d33:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0102d36:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102d3a:	0f 8e 94 00 00 00    	jle    f0102dd4 <vprintfmt+0x225>
f0102d40:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0102d44:	0f 84 98 00 00 00    	je     f0102de2 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0102d4a:	83 ec 08             	sub    $0x8,%esp
f0102d4d:	ff 75 d0             	pushl  -0x30(%ebp)
f0102d50:	57                   	push   %edi
f0102d51:	e8 7f 03 00 00       	call   f01030d5 <strnlen>
f0102d56:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0102d59:	29 c1                	sub    %eax,%ecx
f0102d5b:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0102d5e:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0102d61:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0102d65:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102d68:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0102d6b:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102d6d:	eb 0f                	jmp    f0102d7e <vprintfmt+0x1cf>
					putch(padc, putdat);
f0102d6f:	83 ec 08             	sub    $0x8,%esp
f0102d72:	53                   	push   %ebx
f0102d73:	ff 75 e0             	pushl  -0x20(%ebp)
f0102d76:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102d78:	83 ef 01             	sub    $0x1,%edi
f0102d7b:	83 c4 10             	add    $0x10,%esp
f0102d7e:	85 ff                	test   %edi,%edi
f0102d80:	7f ed                	jg     f0102d6f <vprintfmt+0x1c0>
f0102d82:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102d85:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0102d88:	85 c9                	test   %ecx,%ecx
f0102d8a:	b8 00 00 00 00       	mov    $0x0,%eax
f0102d8f:	0f 49 c1             	cmovns %ecx,%eax
f0102d92:	29 c1                	sub    %eax,%ecx
f0102d94:	89 75 08             	mov    %esi,0x8(%ebp)
f0102d97:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102d9a:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102d9d:	89 cb                	mov    %ecx,%ebx
f0102d9f:	eb 4d                	jmp    f0102dee <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0102da1:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0102da5:	74 1b                	je     f0102dc2 <vprintfmt+0x213>
f0102da7:	0f be c0             	movsbl %al,%eax
f0102daa:	83 e8 20             	sub    $0x20,%eax
f0102dad:	83 f8 5e             	cmp    $0x5e,%eax
f0102db0:	76 10                	jbe    f0102dc2 <vprintfmt+0x213>
					putch('?', putdat);
f0102db2:	83 ec 08             	sub    $0x8,%esp
f0102db5:	ff 75 0c             	pushl  0xc(%ebp)
f0102db8:	6a 3f                	push   $0x3f
f0102dba:	ff 55 08             	call   *0x8(%ebp)
f0102dbd:	83 c4 10             	add    $0x10,%esp
f0102dc0:	eb 0d                	jmp    f0102dcf <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0102dc2:	83 ec 08             	sub    $0x8,%esp
f0102dc5:	ff 75 0c             	pushl  0xc(%ebp)
f0102dc8:	52                   	push   %edx
f0102dc9:	ff 55 08             	call   *0x8(%ebp)
f0102dcc:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0102dcf:	83 eb 01             	sub    $0x1,%ebx
f0102dd2:	eb 1a                	jmp    f0102dee <vprintfmt+0x23f>
f0102dd4:	89 75 08             	mov    %esi,0x8(%ebp)
f0102dd7:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102dda:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102ddd:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102de0:	eb 0c                	jmp    f0102dee <vprintfmt+0x23f>
f0102de2:	89 75 08             	mov    %esi,0x8(%ebp)
f0102de5:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102de8:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102deb:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102dee:	83 c7 01             	add    $0x1,%edi
f0102df1:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102df5:	0f be d0             	movsbl %al,%edx
f0102df8:	85 d2                	test   %edx,%edx
f0102dfa:	74 23                	je     f0102e1f <vprintfmt+0x270>
f0102dfc:	85 f6                	test   %esi,%esi
f0102dfe:	78 a1                	js     f0102da1 <vprintfmt+0x1f2>
f0102e00:	83 ee 01             	sub    $0x1,%esi
f0102e03:	79 9c                	jns    f0102da1 <vprintfmt+0x1f2>
f0102e05:	89 df                	mov    %ebx,%edi
f0102e07:	8b 75 08             	mov    0x8(%ebp),%esi
f0102e0a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102e0d:	eb 18                	jmp    f0102e27 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0102e0f:	83 ec 08             	sub    $0x8,%esp
f0102e12:	53                   	push   %ebx
f0102e13:	6a 20                	push   $0x20
f0102e15:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0102e17:	83 ef 01             	sub    $0x1,%edi
f0102e1a:	83 c4 10             	add    $0x10,%esp
f0102e1d:	eb 08                	jmp    f0102e27 <vprintfmt+0x278>
f0102e1f:	89 df                	mov    %ebx,%edi
f0102e21:	8b 75 08             	mov    0x8(%ebp),%esi
f0102e24:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102e27:	85 ff                	test   %edi,%edi
f0102e29:	7f e4                	jg     f0102e0f <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102e2b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102e2e:	e9 a2 fd ff ff       	jmp    f0102bd5 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102e33:	83 fa 01             	cmp    $0x1,%edx
f0102e36:	7e 16                	jle    f0102e4e <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0102e38:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e3b:	8d 50 08             	lea    0x8(%eax),%edx
f0102e3e:	89 55 14             	mov    %edx,0x14(%ebp)
f0102e41:	8b 50 04             	mov    0x4(%eax),%edx
f0102e44:	8b 00                	mov    (%eax),%eax
f0102e46:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102e49:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0102e4c:	eb 32                	jmp    f0102e80 <vprintfmt+0x2d1>
	else if (lflag)
f0102e4e:	85 d2                	test   %edx,%edx
f0102e50:	74 18                	je     f0102e6a <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f0102e52:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e55:	8d 50 04             	lea    0x4(%eax),%edx
f0102e58:	89 55 14             	mov    %edx,0x14(%ebp)
f0102e5b:	8b 00                	mov    (%eax),%eax
f0102e5d:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102e60:	89 c1                	mov    %eax,%ecx
f0102e62:	c1 f9 1f             	sar    $0x1f,%ecx
f0102e65:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102e68:	eb 16                	jmp    f0102e80 <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f0102e6a:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e6d:	8d 50 04             	lea    0x4(%eax),%edx
f0102e70:	89 55 14             	mov    %edx,0x14(%ebp)
f0102e73:	8b 00                	mov    (%eax),%eax
f0102e75:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102e78:	89 c1                	mov    %eax,%ecx
f0102e7a:	c1 f9 1f             	sar    $0x1f,%ecx
f0102e7d:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0102e80:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102e83:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0102e86:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0102e8b:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0102e8f:	0f 89 90 00 00 00    	jns    f0102f25 <vprintfmt+0x376>
				putch('-', putdat);
f0102e95:	83 ec 08             	sub    $0x8,%esp
f0102e98:	53                   	push   %ebx
f0102e99:	6a 2d                	push   $0x2d
f0102e9b:	ff d6                	call   *%esi
				num = -(long long) num;
f0102e9d:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102ea0:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102ea3:	f7 d8                	neg    %eax
f0102ea5:	83 d2 00             	adc    $0x0,%edx
f0102ea8:	f7 da                	neg    %edx
f0102eaa:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0102ead:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0102eb2:	eb 71                	jmp    f0102f25 <vprintfmt+0x376>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0102eb4:	8d 45 14             	lea    0x14(%ebp),%eax
f0102eb7:	e8 7f fc ff ff       	call   f0102b3b <getuint>
			base = 10;
f0102ebc:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0102ec1:	eb 62                	jmp    f0102f25 <vprintfmt+0x376>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f0102ec3:	8d 45 14             	lea    0x14(%ebp),%eax
f0102ec6:	e8 70 fc ff ff       	call   f0102b3b <getuint>
			base = 8;
			printnum(putch, putdat, num, base, width, padc);
f0102ecb:	83 ec 0c             	sub    $0xc,%esp
f0102ece:	0f be 4d d4          	movsbl -0x2c(%ebp),%ecx
f0102ed2:	51                   	push   %ecx
f0102ed3:	ff 75 e0             	pushl  -0x20(%ebp)
f0102ed6:	6a 08                	push   $0x8
f0102ed8:	52                   	push   %edx
f0102ed9:	50                   	push   %eax
f0102eda:	89 da                	mov    %ebx,%edx
f0102edc:	89 f0                	mov    %esi,%eax
f0102ede:	e8 a9 fb ff ff       	call   f0102a8c <printnum>
			break;
f0102ee3:	83 c4 20             	add    $0x20,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102ee6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
			base = 8;
			printnum(putch, putdat, num, base, width, padc);
			break;
f0102ee9:	e9 e7 fc ff ff       	jmp    f0102bd5 <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
f0102eee:	83 ec 08             	sub    $0x8,%esp
f0102ef1:	53                   	push   %ebx
f0102ef2:	6a 30                	push   $0x30
f0102ef4:	ff d6                	call   *%esi
			putch('x', putdat);
f0102ef6:	83 c4 08             	add    $0x8,%esp
f0102ef9:	53                   	push   %ebx
f0102efa:	6a 78                	push   $0x78
f0102efc:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0102efe:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f01:	8d 50 04             	lea    0x4(%eax),%edx
f0102f04:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0102f07:	8b 00                	mov    (%eax),%eax
f0102f09:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0102f0e:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0102f11:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0102f16:	eb 0d                	jmp    f0102f25 <vprintfmt+0x376>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0102f18:	8d 45 14             	lea    0x14(%ebp),%eax
f0102f1b:	e8 1b fc ff ff       	call   f0102b3b <getuint>
			base = 16;
f0102f20:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0102f25:	83 ec 0c             	sub    $0xc,%esp
f0102f28:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0102f2c:	57                   	push   %edi
f0102f2d:	ff 75 e0             	pushl  -0x20(%ebp)
f0102f30:	51                   	push   %ecx
f0102f31:	52                   	push   %edx
f0102f32:	50                   	push   %eax
f0102f33:	89 da                	mov    %ebx,%edx
f0102f35:	89 f0                	mov    %esi,%eax
f0102f37:	e8 50 fb ff ff       	call   f0102a8c <printnum>
			break;
f0102f3c:	83 c4 20             	add    $0x20,%esp
f0102f3f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102f42:	e9 8e fc ff ff       	jmp    f0102bd5 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0102f47:	83 ec 08             	sub    $0x8,%esp
f0102f4a:	53                   	push   %ebx
f0102f4b:	51                   	push   %ecx
f0102f4c:	ff d6                	call   *%esi
			break;
f0102f4e:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102f51:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0102f54:	e9 7c fc ff ff       	jmp    f0102bd5 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0102f59:	83 ec 08             	sub    $0x8,%esp
f0102f5c:	53                   	push   %ebx
f0102f5d:	6a 25                	push   $0x25
f0102f5f:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0102f61:	83 c4 10             	add    $0x10,%esp
f0102f64:	eb 03                	jmp    f0102f69 <vprintfmt+0x3ba>
f0102f66:	83 ef 01             	sub    $0x1,%edi
f0102f69:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0102f6d:	75 f7                	jne    f0102f66 <vprintfmt+0x3b7>
f0102f6f:	e9 61 fc ff ff       	jmp    f0102bd5 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0102f74:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102f77:	5b                   	pop    %ebx
f0102f78:	5e                   	pop    %esi
f0102f79:	5f                   	pop    %edi
f0102f7a:	5d                   	pop    %ebp
f0102f7b:	c3                   	ret    

f0102f7c <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0102f7c:	55                   	push   %ebp
f0102f7d:	89 e5                	mov    %esp,%ebp
f0102f7f:	83 ec 18             	sub    $0x18,%esp
f0102f82:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f85:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0102f88:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102f8b:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0102f8f:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0102f92:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0102f99:	85 c0                	test   %eax,%eax
f0102f9b:	74 26                	je     f0102fc3 <vsnprintf+0x47>
f0102f9d:	85 d2                	test   %edx,%edx
f0102f9f:	7e 22                	jle    f0102fc3 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0102fa1:	ff 75 14             	pushl  0x14(%ebp)
f0102fa4:	ff 75 10             	pushl  0x10(%ebp)
f0102fa7:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0102faa:	50                   	push   %eax
f0102fab:	68 75 2b 10 f0       	push   $0xf0102b75
f0102fb0:	e8 fa fb ff ff       	call   f0102baf <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0102fb5:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102fb8:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0102fbb:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102fbe:	83 c4 10             	add    $0x10,%esp
f0102fc1:	eb 05                	jmp    f0102fc8 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0102fc3:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0102fc8:	c9                   	leave  
f0102fc9:	c3                   	ret    

f0102fca <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0102fca:	55                   	push   %ebp
f0102fcb:	89 e5                	mov    %esp,%ebp
f0102fcd:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0102fd0:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0102fd3:	50                   	push   %eax
f0102fd4:	ff 75 10             	pushl  0x10(%ebp)
f0102fd7:	ff 75 0c             	pushl  0xc(%ebp)
f0102fda:	ff 75 08             	pushl  0x8(%ebp)
f0102fdd:	e8 9a ff ff ff       	call   f0102f7c <vsnprintf>
	va_end(ap);

	return rc;
}
f0102fe2:	c9                   	leave  
f0102fe3:	c3                   	ret    

f0102fe4 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0102fe4:	55                   	push   %ebp
f0102fe5:	89 e5                	mov    %esp,%ebp
f0102fe7:	57                   	push   %edi
f0102fe8:	56                   	push   %esi
f0102fe9:	53                   	push   %ebx
f0102fea:	83 ec 0c             	sub    $0xc,%esp
f0102fed:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0102ff0:	85 c0                	test   %eax,%eax
f0102ff2:	74 11                	je     f0103005 <readline+0x21>
		cprintf("%s", prompt);
f0102ff4:	83 ec 08             	sub    $0x8,%esp
f0102ff7:	50                   	push   %eax
f0102ff8:	68 8b 3c 10 f0       	push   $0xf0103c8b
f0102ffd:	e8 60 f7 ff ff       	call   f0102762 <cprintf>
f0103002:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0103005:	83 ec 0c             	sub    $0xc,%esp
f0103008:	6a 00                	push   $0x0
f010300a:	e8 04 d6 ff ff       	call   f0100613 <iscons>
f010300f:	89 c7                	mov    %eax,%edi
f0103011:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0103014:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0103019:	e8 e4 d5 ff ff       	call   f0100602 <getchar>
f010301e:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0103020:	85 c0                	test   %eax,%eax
f0103022:	79 18                	jns    f010303c <readline+0x58>
			cprintf("read error: %e\n", c);
f0103024:	83 ec 08             	sub    $0x8,%esp
f0103027:	50                   	push   %eax
f0103028:	68 00 49 10 f0       	push   $0xf0104900
f010302d:	e8 30 f7 ff ff       	call   f0102762 <cprintf>
			return NULL;
f0103032:	83 c4 10             	add    $0x10,%esp
f0103035:	b8 00 00 00 00       	mov    $0x0,%eax
f010303a:	eb 79                	jmp    f01030b5 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f010303c:	83 f8 08             	cmp    $0x8,%eax
f010303f:	0f 94 c2             	sete   %dl
f0103042:	83 f8 7f             	cmp    $0x7f,%eax
f0103045:	0f 94 c0             	sete   %al
f0103048:	08 c2                	or     %al,%dl
f010304a:	74 1a                	je     f0103066 <readline+0x82>
f010304c:	85 f6                	test   %esi,%esi
f010304e:	7e 16                	jle    f0103066 <readline+0x82>
			if (echoing)
f0103050:	85 ff                	test   %edi,%edi
f0103052:	74 0d                	je     f0103061 <readline+0x7d>
				cputchar('\b');
f0103054:	83 ec 0c             	sub    $0xc,%esp
f0103057:	6a 08                	push   $0x8
f0103059:	e8 94 d5 ff ff       	call   f01005f2 <cputchar>
f010305e:	83 c4 10             	add    $0x10,%esp
			i--;
f0103061:	83 ee 01             	sub    $0x1,%esi
f0103064:	eb b3                	jmp    f0103019 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103066:	83 fb 1f             	cmp    $0x1f,%ebx
f0103069:	7e 23                	jle    f010308e <readline+0xaa>
f010306b:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0103071:	7f 1b                	jg     f010308e <readline+0xaa>
			if (echoing)
f0103073:	85 ff                	test   %edi,%edi
f0103075:	74 0c                	je     f0103083 <readline+0x9f>
				cputchar(c);
f0103077:	83 ec 0c             	sub    $0xc,%esp
f010307a:	53                   	push   %ebx
f010307b:	e8 72 d5 ff ff       	call   f01005f2 <cputchar>
f0103080:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0103083:	88 9e 60 65 11 f0    	mov    %bl,-0xfee9aa0(%esi)
f0103089:	8d 76 01             	lea    0x1(%esi),%esi
f010308c:	eb 8b                	jmp    f0103019 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f010308e:	83 fb 0a             	cmp    $0xa,%ebx
f0103091:	74 05                	je     f0103098 <readline+0xb4>
f0103093:	83 fb 0d             	cmp    $0xd,%ebx
f0103096:	75 81                	jne    f0103019 <readline+0x35>
			if (echoing)
f0103098:	85 ff                	test   %edi,%edi
f010309a:	74 0d                	je     f01030a9 <readline+0xc5>
				cputchar('\n');
f010309c:	83 ec 0c             	sub    $0xc,%esp
f010309f:	6a 0a                	push   $0xa
f01030a1:	e8 4c d5 ff ff       	call   f01005f2 <cputchar>
f01030a6:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f01030a9:	c6 86 60 65 11 f0 00 	movb   $0x0,-0xfee9aa0(%esi)
			return buf;
f01030b0:	b8 60 65 11 f0       	mov    $0xf0116560,%eax
		}
	}
}
f01030b5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01030b8:	5b                   	pop    %ebx
f01030b9:	5e                   	pop    %esi
f01030ba:	5f                   	pop    %edi
f01030bb:	5d                   	pop    %ebp
f01030bc:	c3                   	ret    

f01030bd <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01030bd:	55                   	push   %ebp
f01030be:	89 e5                	mov    %esp,%ebp
f01030c0:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01030c3:	b8 00 00 00 00       	mov    $0x0,%eax
f01030c8:	eb 03                	jmp    f01030cd <strlen+0x10>
		n++;
f01030ca:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01030cd:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01030d1:	75 f7                	jne    f01030ca <strlen+0xd>
		n++;
	return n;
}
f01030d3:	5d                   	pop    %ebp
f01030d4:	c3                   	ret    

f01030d5 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01030d5:	55                   	push   %ebp
f01030d6:	89 e5                	mov    %esp,%ebp
f01030d8:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01030db:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01030de:	ba 00 00 00 00       	mov    $0x0,%edx
f01030e3:	eb 03                	jmp    f01030e8 <strnlen+0x13>
		n++;
f01030e5:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01030e8:	39 c2                	cmp    %eax,%edx
f01030ea:	74 08                	je     f01030f4 <strnlen+0x1f>
f01030ec:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f01030f0:	75 f3                	jne    f01030e5 <strnlen+0x10>
f01030f2:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f01030f4:	5d                   	pop    %ebp
f01030f5:	c3                   	ret    

f01030f6 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01030f6:	55                   	push   %ebp
f01030f7:	89 e5                	mov    %esp,%ebp
f01030f9:	53                   	push   %ebx
f01030fa:	8b 45 08             	mov    0x8(%ebp),%eax
f01030fd:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103100:	89 c2                	mov    %eax,%edx
f0103102:	83 c2 01             	add    $0x1,%edx
f0103105:	83 c1 01             	add    $0x1,%ecx
f0103108:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010310c:	88 5a ff             	mov    %bl,-0x1(%edx)
f010310f:	84 db                	test   %bl,%bl
f0103111:	75 ef                	jne    f0103102 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0103113:	5b                   	pop    %ebx
f0103114:	5d                   	pop    %ebp
f0103115:	c3                   	ret    

f0103116 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0103116:	55                   	push   %ebp
f0103117:	89 e5                	mov    %esp,%ebp
f0103119:	53                   	push   %ebx
f010311a:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f010311d:	53                   	push   %ebx
f010311e:	e8 9a ff ff ff       	call   f01030bd <strlen>
f0103123:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0103126:	ff 75 0c             	pushl  0xc(%ebp)
f0103129:	01 d8                	add    %ebx,%eax
f010312b:	50                   	push   %eax
f010312c:	e8 c5 ff ff ff       	call   f01030f6 <strcpy>
	return dst;
}
f0103131:	89 d8                	mov    %ebx,%eax
f0103133:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103136:	c9                   	leave  
f0103137:	c3                   	ret    

f0103138 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103138:	55                   	push   %ebp
f0103139:	89 e5                	mov    %esp,%ebp
f010313b:	56                   	push   %esi
f010313c:	53                   	push   %ebx
f010313d:	8b 75 08             	mov    0x8(%ebp),%esi
f0103140:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103143:	89 f3                	mov    %esi,%ebx
f0103145:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103148:	89 f2                	mov    %esi,%edx
f010314a:	eb 0f                	jmp    f010315b <strncpy+0x23>
		*dst++ = *src;
f010314c:	83 c2 01             	add    $0x1,%edx
f010314f:	0f b6 01             	movzbl (%ecx),%eax
f0103152:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0103155:	80 39 01             	cmpb   $0x1,(%ecx)
f0103158:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010315b:	39 da                	cmp    %ebx,%edx
f010315d:	75 ed                	jne    f010314c <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f010315f:	89 f0                	mov    %esi,%eax
f0103161:	5b                   	pop    %ebx
f0103162:	5e                   	pop    %esi
f0103163:	5d                   	pop    %ebp
f0103164:	c3                   	ret    

f0103165 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0103165:	55                   	push   %ebp
f0103166:	89 e5                	mov    %esp,%ebp
f0103168:	56                   	push   %esi
f0103169:	53                   	push   %ebx
f010316a:	8b 75 08             	mov    0x8(%ebp),%esi
f010316d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103170:	8b 55 10             	mov    0x10(%ebp),%edx
f0103173:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103175:	85 d2                	test   %edx,%edx
f0103177:	74 21                	je     f010319a <strlcpy+0x35>
f0103179:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f010317d:	89 f2                	mov    %esi,%edx
f010317f:	eb 09                	jmp    f010318a <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103181:	83 c2 01             	add    $0x1,%edx
f0103184:	83 c1 01             	add    $0x1,%ecx
f0103187:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f010318a:	39 c2                	cmp    %eax,%edx
f010318c:	74 09                	je     f0103197 <strlcpy+0x32>
f010318e:	0f b6 19             	movzbl (%ecx),%ebx
f0103191:	84 db                	test   %bl,%bl
f0103193:	75 ec                	jne    f0103181 <strlcpy+0x1c>
f0103195:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0103197:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f010319a:	29 f0                	sub    %esi,%eax
}
f010319c:	5b                   	pop    %ebx
f010319d:	5e                   	pop    %esi
f010319e:	5d                   	pop    %ebp
f010319f:	c3                   	ret    

f01031a0 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01031a0:	55                   	push   %ebp
f01031a1:	89 e5                	mov    %esp,%ebp
f01031a3:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01031a6:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01031a9:	eb 06                	jmp    f01031b1 <strcmp+0x11>
		p++, q++;
f01031ab:	83 c1 01             	add    $0x1,%ecx
f01031ae:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01031b1:	0f b6 01             	movzbl (%ecx),%eax
f01031b4:	84 c0                	test   %al,%al
f01031b6:	74 04                	je     f01031bc <strcmp+0x1c>
f01031b8:	3a 02                	cmp    (%edx),%al
f01031ba:	74 ef                	je     f01031ab <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01031bc:	0f b6 c0             	movzbl %al,%eax
f01031bf:	0f b6 12             	movzbl (%edx),%edx
f01031c2:	29 d0                	sub    %edx,%eax
}
f01031c4:	5d                   	pop    %ebp
f01031c5:	c3                   	ret    

f01031c6 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01031c6:	55                   	push   %ebp
f01031c7:	89 e5                	mov    %esp,%ebp
f01031c9:	53                   	push   %ebx
f01031ca:	8b 45 08             	mov    0x8(%ebp),%eax
f01031cd:	8b 55 0c             	mov    0xc(%ebp),%edx
f01031d0:	89 c3                	mov    %eax,%ebx
f01031d2:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01031d5:	eb 06                	jmp    f01031dd <strncmp+0x17>
		n--, p++, q++;
f01031d7:	83 c0 01             	add    $0x1,%eax
f01031da:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01031dd:	39 d8                	cmp    %ebx,%eax
f01031df:	74 15                	je     f01031f6 <strncmp+0x30>
f01031e1:	0f b6 08             	movzbl (%eax),%ecx
f01031e4:	84 c9                	test   %cl,%cl
f01031e6:	74 04                	je     f01031ec <strncmp+0x26>
f01031e8:	3a 0a                	cmp    (%edx),%cl
f01031ea:	74 eb                	je     f01031d7 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01031ec:	0f b6 00             	movzbl (%eax),%eax
f01031ef:	0f b6 12             	movzbl (%edx),%edx
f01031f2:	29 d0                	sub    %edx,%eax
f01031f4:	eb 05                	jmp    f01031fb <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01031f6:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01031fb:	5b                   	pop    %ebx
f01031fc:	5d                   	pop    %ebp
f01031fd:	c3                   	ret    

f01031fe <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01031fe:	55                   	push   %ebp
f01031ff:	89 e5                	mov    %esp,%ebp
f0103201:	8b 45 08             	mov    0x8(%ebp),%eax
f0103204:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103208:	eb 07                	jmp    f0103211 <strchr+0x13>
		if (*s == c)
f010320a:	38 ca                	cmp    %cl,%dl
f010320c:	74 0f                	je     f010321d <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010320e:	83 c0 01             	add    $0x1,%eax
f0103211:	0f b6 10             	movzbl (%eax),%edx
f0103214:	84 d2                	test   %dl,%dl
f0103216:	75 f2                	jne    f010320a <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0103218:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010321d:	5d                   	pop    %ebp
f010321e:	c3                   	ret    

f010321f <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010321f:	55                   	push   %ebp
f0103220:	89 e5                	mov    %esp,%ebp
f0103222:	8b 45 08             	mov    0x8(%ebp),%eax
f0103225:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103229:	eb 03                	jmp    f010322e <strfind+0xf>
f010322b:	83 c0 01             	add    $0x1,%eax
f010322e:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0103231:	38 ca                	cmp    %cl,%dl
f0103233:	74 04                	je     f0103239 <strfind+0x1a>
f0103235:	84 d2                	test   %dl,%dl
f0103237:	75 f2                	jne    f010322b <strfind+0xc>
			break;
	return (char *) s;
}
f0103239:	5d                   	pop    %ebp
f010323a:	c3                   	ret    

f010323b <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f010323b:	55                   	push   %ebp
f010323c:	89 e5                	mov    %esp,%ebp
f010323e:	57                   	push   %edi
f010323f:	56                   	push   %esi
f0103240:	53                   	push   %ebx
f0103241:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103244:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0103247:	85 c9                	test   %ecx,%ecx
f0103249:	74 36                	je     f0103281 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010324b:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103251:	75 28                	jne    f010327b <memset+0x40>
f0103253:	f6 c1 03             	test   $0x3,%cl
f0103256:	75 23                	jne    f010327b <memset+0x40>
		c &= 0xFF;
f0103258:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010325c:	89 d3                	mov    %edx,%ebx
f010325e:	c1 e3 08             	shl    $0x8,%ebx
f0103261:	89 d6                	mov    %edx,%esi
f0103263:	c1 e6 18             	shl    $0x18,%esi
f0103266:	89 d0                	mov    %edx,%eax
f0103268:	c1 e0 10             	shl    $0x10,%eax
f010326b:	09 f0                	or     %esi,%eax
f010326d:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f010326f:	89 d8                	mov    %ebx,%eax
f0103271:	09 d0                	or     %edx,%eax
f0103273:	c1 e9 02             	shr    $0x2,%ecx
f0103276:	fc                   	cld    
f0103277:	f3 ab                	rep stos %eax,%es:(%edi)
f0103279:	eb 06                	jmp    f0103281 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010327b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010327e:	fc                   	cld    
f010327f:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103281:	89 f8                	mov    %edi,%eax
f0103283:	5b                   	pop    %ebx
f0103284:	5e                   	pop    %esi
f0103285:	5f                   	pop    %edi
f0103286:	5d                   	pop    %ebp
f0103287:	c3                   	ret    

f0103288 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103288:	55                   	push   %ebp
f0103289:	89 e5                	mov    %esp,%ebp
f010328b:	57                   	push   %edi
f010328c:	56                   	push   %esi
f010328d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103290:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103293:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103296:	39 c6                	cmp    %eax,%esi
f0103298:	73 35                	jae    f01032cf <memmove+0x47>
f010329a:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010329d:	39 d0                	cmp    %edx,%eax
f010329f:	73 2e                	jae    f01032cf <memmove+0x47>
		s += n;
		d += n;
f01032a1:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01032a4:	89 d6                	mov    %edx,%esi
f01032a6:	09 fe                	or     %edi,%esi
f01032a8:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01032ae:	75 13                	jne    f01032c3 <memmove+0x3b>
f01032b0:	f6 c1 03             	test   $0x3,%cl
f01032b3:	75 0e                	jne    f01032c3 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f01032b5:	83 ef 04             	sub    $0x4,%edi
f01032b8:	8d 72 fc             	lea    -0x4(%edx),%esi
f01032bb:	c1 e9 02             	shr    $0x2,%ecx
f01032be:	fd                   	std    
f01032bf:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01032c1:	eb 09                	jmp    f01032cc <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01032c3:	83 ef 01             	sub    $0x1,%edi
f01032c6:	8d 72 ff             	lea    -0x1(%edx),%esi
f01032c9:	fd                   	std    
f01032ca:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01032cc:	fc                   	cld    
f01032cd:	eb 1d                	jmp    f01032ec <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01032cf:	89 f2                	mov    %esi,%edx
f01032d1:	09 c2                	or     %eax,%edx
f01032d3:	f6 c2 03             	test   $0x3,%dl
f01032d6:	75 0f                	jne    f01032e7 <memmove+0x5f>
f01032d8:	f6 c1 03             	test   $0x3,%cl
f01032db:	75 0a                	jne    f01032e7 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f01032dd:	c1 e9 02             	shr    $0x2,%ecx
f01032e0:	89 c7                	mov    %eax,%edi
f01032e2:	fc                   	cld    
f01032e3:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01032e5:	eb 05                	jmp    f01032ec <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01032e7:	89 c7                	mov    %eax,%edi
f01032e9:	fc                   	cld    
f01032ea:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01032ec:	5e                   	pop    %esi
f01032ed:	5f                   	pop    %edi
f01032ee:	5d                   	pop    %ebp
f01032ef:	c3                   	ret    

f01032f0 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01032f0:	55                   	push   %ebp
f01032f1:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01032f3:	ff 75 10             	pushl  0x10(%ebp)
f01032f6:	ff 75 0c             	pushl  0xc(%ebp)
f01032f9:	ff 75 08             	pushl  0x8(%ebp)
f01032fc:	e8 87 ff ff ff       	call   f0103288 <memmove>
}
f0103301:	c9                   	leave  
f0103302:	c3                   	ret    

f0103303 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103303:	55                   	push   %ebp
f0103304:	89 e5                	mov    %esp,%ebp
f0103306:	56                   	push   %esi
f0103307:	53                   	push   %ebx
f0103308:	8b 45 08             	mov    0x8(%ebp),%eax
f010330b:	8b 55 0c             	mov    0xc(%ebp),%edx
f010330e:	89 c6                	mov    %eax,%esi
f0103310:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103313:	eb 1a                	jmp    f010332f <memcmp+0x2c>
		if (*s1 != *s2)
f0103315:	0f b6 08             	movzbl (%eax),%ecx
f0103318:	0f b6 1a             	movzbl (%edx),%ebx
f010331b:	38 d9                	cmp    %bl,%cl
f010331d:	74 0a                	je     f0103329 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f010331f:	0f b6 c1             	movzbl %cl,%eax
f0103322:	0f b6 db             	movzbl %bl,%ebx
f0103325:	29 d8                	sub    %ebx,%eax
f0103327:	eb 0f                	jmp    f0103338 <memcmp+0x35>
		s1++, s2++;
f0103329:	83 c0 01             	add    $0x1,%eax
f010332c:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010332f:	39 f0                	cmp    %esi,%eax
f0103331:	75 e2                	jne    f0103315 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0103333:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103338:	5b                   	pop    %ebx
f0103339:	5e                   	pop    %esi
f010333a:	5d                   	pop    %ebp
f010333b:	c3                   	ret    

f010333c <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010333c:	55                   	push   %ebp
f010333d:	89 e5                	mov    %esp,%ebp
f010333f:	53                   	push   %ebx
f0103340:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0103343:	89 c1                	mov    %eax,%ecx
f0103345:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0103348:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010334c:	eb 0a                	jmp    f0103358 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f010334e:	0f b6 10             	movzbl (%eax),%edx
f0103351:	39 da                	cmp    %ebx,%edx
f0103353:	74 07                	je     f010335c <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103355:	83 c0 01             	add    $0x1,%eax
f0103358:	39 c8                	cmp    %ecx,%eax
f010335a:	72 f2                	jb     f010334e <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f010335c:	5b                   	pop    %ebx
f010335d:	5d                   	pop    %ebp
f010335e:	c3                   	ret    

f010335f <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f010335f:	55                   	push   %ebp
f0103360:	89 e5                	mov    %esp,%ebp
f0103362:	57                   	push   %edi
f0103363:	56                   	push   %esi
f0103364:	53                   	push   %ebx
f0103365:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103368:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010336b:	eb 03                	jmp    f0103370 <strtol+0x11>
		s++;
f010336d:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103370:	0f b6 01             	movzbl (%ecx),%eax
f0103373:	3c 20                	cmp    $0x20,%al
f0103375:	74 f6                	je     f010336d <strtol+0xe>
f0103377:	3c 09                	cmp    $0x9,%al
f0103379:	74 f2                	je     f010336d <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f010337b:	3c 2b                	cmp    $0x2b,%al
f010337d:	75 0a                	jne    f0103389 <strtol+0x2a>
		s++;
f010337f:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0103382:	bf 00 00 00 00       	mov    $0x0,%edi
f0103387:	eb 11                	jmp    f010339a <strtol+0x3b>
f0103389:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f010338e:	3c 2d                	cmp    $0x2d,%al
f0103390:	75 08                	jne    f010339a <strtol+0x3b>
		s++, neg = 1;
f0103392:	83 c1 01             	add    $0x1,%ecx
f0103395:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010339a:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01033a0:	75 15                	jne    f01033b7 <strtol+0x58>
f01033a2:	80 39 30             	cmpb   $0x30,(%ecx)
f01033a5:	75 10                	jne    f01033b7 <strtol+0x58>
f01033a7:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01033ab:	75 7c                	jne    f0103429 <strtol+0xca>
		s += 2, base = 16;
f01033ad:	83 c1 02             	add    $0x2,%ecx
f01033b0:	bb 10 00 00 00       	mov    $0x10,%ebx
f01033b5:	eb 16                	jmp    f01033cd <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f01033b7:	85 db                	test   %ebx,%ebx
f01033b9:	75 12                	jne    f01033cd <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01033bb:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01033c0:	80 39 30             	cmpb   $0x30,(%ecx)
f01033c3:	75 08                	jne    f01033cd <strtol+0x6e>
		s++, base = 8;
f01033c5:	83 c1 01             	add    $0x1,%ecx
f01033c8:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f01033cd:	b8 00 00 00 00       	mov    $0x0,%eax
f01033d2:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01033d5:	0f b6 11             	movzbl (%ecx),%edx
f01033d8:	8d 72 d0             	lea    -0x30(%edx),%esi
f01033db:	89 f3                	mov    %esi,%ebx
f01033dd:	80 fb 09             	cmp    $0x9,%bl
f01033e0:	77 08                	ja     f01033ea <strtol+0x8b>
			dig = *s - '0';
f01033e2:	0f be d2             	movsbl %dl,%edx
f01033e5:	83 ea 30             	sub    $0x30,%edx
f01033e8:	eb 22                	jmp    f010340c <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f01033ea:	8d 72 9f             	lea    -0x61(%edx),%esi
f01033ed:	89 f3                	mov    %esi,%ebx
f01033ef:	80 fb 19             	cmp    $0x19,%bl
f01033f2:	77 08                	ja     f01033fc <strtol+0x9d>
			dig = *s - 'a' + 10;
f01033f4:	0f be d2             	movsbl %dl,%edx
f01033f7:	83 ea 57             	sub    $0x57,%edx
f01033fa:	eb 10                	jmp    f010340c <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f01033fc:	8d 72 bf             	lea    -0x41(%edx),%esi
f01033ff:	89 f3                	mov    %esi,%ebx
f0103401:	80 fb 19             	cmp    $0x19,%bl
f0103404:	77 16                	ja     f010341c <strtol+0xbd>
			dig = *s - 'A' + 10;
f0103406:	0f be d2             	movsbl %dl,%edx
f0103409:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f010340c:	3b 55 10             	cmp    0x10(%ebp),%edx
f010340f:	7d 0b                	jge    f010341c <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0103411:	83 c1 01             	add    $0x1,%ecx
f0103414:	0f af 45 10          	imul   0x10(%ebp),%eax
f0103418:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f010341a:	eb b9                	jmp    f01033d5 <strtol+0x76>

	if (endptr)
f010341c:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103420:	74 0d                	je     f010342f <strtol+0xd0>
		*endptr = (char *) s;
f0103422:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103425:	89 0e                	mov    %ecx,(%esi)
f0103427:	eb 06                	jmp    f010342f <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103429:	85 db                	test   %ebx,%ebx
f010342b:	74 98                	je     f01033c5 <strtol+0x66>
f010342d:	eb 9e                	jmp    f01033cd <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f010342f:	89 c2                	mov    %eax,%edx
f0103431:	f7 da                	neg    %edx
f0103433:	85 ff                	test   %edi,%edi
f0103435:	0f 45 c2             	cmovne %edx,%eax
}
f0103438:	5b                   	pop    %ebx
f0103439:	5e                   	pop    %esi
f010343a:	5f                   	pop    %edi
f010343b:	5d                   	pop    %ebp
f010343c:	c3                   	ret    
f010343d:	66 90                	xchg   %ax,%ax
f010343f:	90                   	nop

f0103440 <__udivdi3>:
f0103440:	55                   	push   %ebp
f0103441:	57                   	push   %edi
f0103442:	56                   	push   %esi
f0103443:	53                   	push   %ebx
f0103444:	83 ec 1c             	sub    $0x1c,%esp
f0103447:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010344b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010344f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0103453:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103457:	85 f6                	test   %esi,%esi
f0103459:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010345d:	89 ca                	mov    %ecx,%edx
f010345f:	89 f8                	mov    %edi,%eax
f0103461:	75 3d                	jne    f01034a0 <__udivdi3+0x60>
f0103463:	39 cf                	cmp    %ecx,%edi
f0103465:	0f 87 c5 00 00 00    	ja     f0103530 <__udivdi3+0xf0>
f010346b:	85 ff                	test   %edi,%edi
f010346d:	89 fd                	mov    %edi,%ebp
f010346f:	75 0b                	jne    f010347c <__udivdi3+0x3c>
f0103471:	b8 01 00 00 00       	mov    $0x1,%eax
f0103476:	31 d2                	xor    %edx,%edx
f0103478:	f7 f7                	div    %edi
f010347a:	89 c5                	mov    %eax,%ebp
f010347c:	89 c8                	mov    %ecx,%eax
f010347e:	31 d2                	xor    %edx,%edx
f0103480:	f7 f5                	div    %ebp
f0103482:	89 c1                	mov    %eax,%ecx
f0103484:	89 d8                	mov    %ebx,%eax
f0103486:	89 cf                	mov    %ecx,%edi
f0103488:	f7 f5                	div    %ebp
f010348a:	89 c3                	mov    %eax,%ebx
f010348c:	89 d8                	mov    %ebx,%eax
f010348e:	89 fa                	mov    %edi,%edx
f0103490:	83 c4 1c             	add    $0x1c,%esp
f0103493:	5b                   	pop    %ebx
f0103494:	5e                   	pop    %esi
f0103495:	5f                   	pop    %edi
f0103496:	5d                   	pop    %ebp
f0103497:	c3                   	ret    
f0103498:	90                   	nop
f0103499:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01034a0:	39 ce                	cmp    %ecx,%esi
f01034a2:	77 74                	ja     f0103518 <__udivdi3+0xd8>
f01034a4:	0f bd fe             	bsr    %esi,%edi
f01034a7:	83 f7 1f             	xor    $0x1f,%edi
f01034aa:	0f 84 98 00 00 00    	je     f0103548 <__udivdi3+0x108>
f01034b0:	bb 20 00 00 00       	mov    $0x20,%ebx
f01034b5:	89 f9                	mov    %edi,%ecx
f01034b7:	89 c5                	mov    %eax,%ebp
f01034b9:	29 fb                	sub    %edi,%ebx
f01034bb:	d3 e6                	shl    %cl,%esi
f01034bd:	89 d9                	mov    %ebx,%ecx
f01034bf:	d3 ed                	shr    %cl,%ebp
f01034c1:	89 f9                	mov    %edi,%ecx
f01034c3:	d3 e0                	shl    %cl,%eax
f01034c5:	09 ee                	or     %ebp,%esi
f01034c7:	89 d9                	mov    %ebx,%ecx
f01034c9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01034cd:	89 d5                	mov    %edx,%ebp
f01034cf:	8b 44 24 08          	mov    0x8(%esp),%eax
f01034d3:	d3 ed                	shr    %cl,%ebp
f01034d5:	89 f9                	mov    %edi,%ecx
f01034d7:	d3 e2                	shl    %cl,%edx
f01034d9:	89 d9                	mov    %ebx,%ecx
f01034db:	d3 e8                	shr    %cl,%eax
f01034dd:	09 c2                	or     %eax,%edx
f01034df:	89 d0                	mov    %edx,%eax
f01034e1:	89 ea                	mov    %ebp,%edx
f01034e3:	f7 f6                	div    %esi
f01034e5:	89 d5                	mov    %edx,%ebp
f01034e7:	89 c3                	mov    %eax,%ebx
f01034e9:	f7 64 24 0c          	mull   0xc(%esp)
f01034ed:	39 d5                	cmp    %edx,%ebp
f01034ef:	72 10                	jb     f0103501 <__udivdi3+0xc1>
f01034f1:	8b 74 24 08          	mov    0x8(%esp),%esi
f01034f5:	89 f9                	mov    %edi,%ecx
f01034f7:	d3 e6                	shl    %cl,%esi
f01034f9:	39 c6                	cmp    %eax,%esi
f01034fb:	73 07                	jae    f0103504 <__udivdi3+0xc4>
f01034fd:	39 d5                	cmp    %edx,%ebp
f01034ff:	75 03                	jne    f0103504 <__udivdi3+0xc4>
f0103501:	83 eb 01             	sub    $0x1,%ebx
f0103504:	31 ff                	xor    %edi,%edi
f0103506:	89 d8                	mov    %ebx,%eax
f0103508:	89 fa                	mov    %edi,%edx
f010350a:	83 c4 1c             	add    $0x1c,%esp
f010350d:	5b                   	pop    %ebx
f010350e:	5e                   	pop    %esi
f010350f:	5f                   	pop    %edi
f0103510:	5d                   	pop    %ebp
f0103511:	c3                   	ret    
f0103512:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103518:	31 ff                	xor    %edi,%edi
f010351a:	31 db                	xor    %ebx,%ebx
f010351c:	89 d8                	mov    %ebx,%eax
f010351e:	89 fa                	mov    %edi,%edx
f0103520:	83 c4 1c             	add    $0x1c,%esp
f0103523:	5b                   	pop    %ebx
f0103524:	5e                   	pop    %esi
f0103525:	5f                   	pop    %edi
f0103526:	5d                   	pop    %ebp
f0103527:	c3                   	ret    
f0103528:	90                   	nop
f0103529:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103530:	89 d8                	mov    %ebx,%eax
f0103532:	f7 f7                	div    %edi
f0103534:	31 ff                	xor    %edi,%edi
f0103536:	89 c3                	mov    %eax,%ebx
f0103538:	89 d8                	mov    %ebx,%eax
f010353a:	89 fa                	mov    %edi,%edx
f010353c:	83 c4 1c             	add    $0x1c,%esp
f010353f:	5b                   	pop    %ebx
f0103540:	5e                   	pop    %esi
f0103541:	5f                   	pop    %edi
f0103542:	5d                   	pop    %ebp
f0103543:	c3                   	ret    
f0103544:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103548:	39 ce                	cmp    %ecx,%esi
f010354a:	72 0c                	jb     f0103558 <__udivdi3+0x118>
f010354c:	31 db                	xor    %ebx,%ebx
f010354e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0103552:	0f 87 34 ff ff ff    	ja     f010348c <__udivdi3+0x4c>
f0103558:	bb 01 00 00 00       	mov    $0x1,%ebx
f010355d:	e9 2a ff ff ff       	jmp    f010348c <__udivdi3+0x4c>
f0103562:	66 90                	xchg   %ax,%ax
f0103564:	66 90                	xchg   %ax,%ax
f0103566:	66 90                	xchg   %ax,%ax
f0103568:	66 90                	xchg   %ax,%ax
f010356a:	66 90                	xchg   %ax,%ax
f010356c:	66 90                	xchg   %ax,%ax
f010356e:	66 90                	xchg   %ax,%ax

f0103570 <__umoddi3>:
f0103570:	55                   	push   %ebp
f0103571:	57                   	push   %edi
f0103572:	56                   	push   %esi
f0103573:	53                   	push   %ebx
f0103574:	83 ec 1c             	sub    $0x1c,%esp
f0103577:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010357b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010357f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0103583:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103587:	85 d2                	test   %edx,%edx
f0103589:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010358d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103591:	89 f3                	mov    %esi,%ebx
f0103593:	89 3c 24             	mov    %edi,(%esp)
f0103596:	89 74 24 04          	mov    %esi,0x4(%esp)
f010359a:	75 1c                	jne    f01035b8 <__umoddi3+0x48>
f010359c:	39 f7                	cmp    %esi,%edi
f010359e:	76 50                	jbe    f01035f0 <__umoddi3+0x80>
f01035a0:	89 c8                	mov    %ecx,%eax
f01035a2:	89 f2                	mov    %esi,%edx
f01035a4:	f7 f7                	div    %edi
f01035a6:	89 d0                	mov    %edx,%eax
f01035a8:	31 d2                	xor    %edx,%edx
f01035aa:	83 c4 1c             	add    $0x1c,%esp
f01035ad:	5b                   	pop    %ebx
f01035ae:	5e                   	pop    %esi
f01035af:	5f                   	pop    %edi
f01035b0:	5d                   	pop    %ebp
f01035b1:	c3                   	ret    
f01035b2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01035b8:	39 f2                	cmp    %esi,%edx
f01035ba:	89 d0                	mov    %edx,%eax
f01035bc:	77 52                	ja     f0103610 <__umoddi3+0xa0>
f01035be:	0f bd ea             	bsr    %edx,%ebp
f01035c1:	83 f5 1f             	xor    $0x1f,%ebp
f01035c4:	75 5a                	jne    f0103620 <__umoddi3+0xb0>
f01035c6:	3b 54 24 04          	cmp    0x4(%esp),%edx
f01035ca:	0f 82 e0 00 00 00    	jb     f01036b0 <__umoddi3+0x140>
f01035d0:	39 0c 24             	cmp    %ecx,(%esp)
f01035d3:	0f 86 d7 00 00 00    	jbe    f01036b0 <__umoddi3+0x140>
f01035d9:	8b 44 24 08          	mov    0x8(%esp),%eax
f01035dd:	8b 54 24 04          	mov    0x4(%esp),%edx
f01035e1:	83 c4 1c             	add    $0x1c,%esp
f01035e4:	5b                   	pop    %ebx
f01035e5:	5e                   	pop    %esi
f01035e6:	5f                   	pop    %edi
f01035e7:	5d                   	pop    %ebp
f01035e8:	c3                   	ret    
f01035e9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01035f0:	85 ff                	test   %edi,%edi
f01035f2:	89 fd                	mov    %edi,%ebp
f01035f4:	75 0b                	jne    f0103601 <__umoddi3+0x91>
f01035f6:	b8 01 00 00 00       	mov    $0x1,%eax
f01035fb:	31 d2                	xor    %edx,%edx
f01035fd:	f7 f7                	div    %edi
f01035ff:	89 c5                	mov    %eax,%ebp
f0103601:	89 f0                	mov    %esi,%eax
f0103603:	31 d2                	xor    %edx,%edx
f0103605:	f7 f5                	div    %ebp
f0103607:	89 c8                	mov    %ecx,%eax
f0103609:	f7 f5                	div    %ebp
f010360b:	89 d0                	mov    %edx,%eax
f010360d:	eb 99                	jmp    f01035a8 <__umoddi3+0x38>
f010360f:	90                   	nop
f0103610:	89 c8                	mov    %ecx,%eax
f0103612:	89 f2                	mov    %esi,%edx
f0103614:	83 c4 1c             	add    $0x1c,%esp
f0103617:	5b                   	pop    %ebx
f0103618:	5e                   	pop    %esi
f0103619:	5f                   	pop    %edi
f010361a:	5d                   	pop    %ebp
f010361b:	c3                   	ret    
f010361c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103620:	8b 34 24             	mov    (%esp),%esi
f0103623:	bf 20 00 00 00       	mov    $0x20,%edi
f0103628:	89 e9                	mov    %ebp,%ecx
f010362a:	29 ef                	sub    %ebp,%edi
f010362c:	d3 e0                	shl    %cl,%eax
f010362e:	89 f9                	mov    %edi,%ecx
f0103630:	89 f2                	mov    %esi,%edx
f0103632:	d3 ea                	shr    %cl,%edx
f0103634:	89 e9                	mov    %ebp,%ecx
f0103636:	09 c2                	or     %eax,%edx
f0103638:	89 d8                	mov    %ebx,%eax
f010363a:	89 14 24             	mov    %edx,(%esp)
f010363d:	89 f2                	mov    %esi,%edx
f010363f:	d3 e2                	shl    %cl,%edx
f0103641:	89 f9                	mov    %edi,%ecx
f0103643:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103647:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010364b:	d3 e8                	shr    %cl,%eax
f010364d:	89 e9                	mov    %ebp,%ecx
f010364f:	89 c6                	mov    %eax,%esi
f0103651:	d3 e3                	shl    %cl,%ebx
f0103653:	89 f9                	mov    %edi,%ecx
f0103655:	89 d0                	mov    %edx,%eax
f0103657:	d3 e8                	shr    %cl,%eax
f0103659:	89 e9                	mov    %ebp,%ecx
f010365b:	09 d8                	or     %ebx,%eax
f010365d:	89 d3                	mov    %edx,%ebx
f010365f:	89 f2                	mov    %esi,%edx
f0103661:	f7 34 24             	divl   (%esp)
f0103664:	89 d6                	mov    %edx,%esi
f0103666:	d3 e3                	shl    %cl,%ebx
f0103668:	f7 64 24 04          	mull   0x4(%esp)
f010366c:	39 d6                	cmp    %edx,%esi
f010366e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103672:	89 d1                	mov    %edx,%ecx
f0103674:	89 c3                	mov    %eax,%ebx
f0103676:	72 08                	jb     f0103680 <__umoddi3+0x110>
f0103678:	75 11                	jne    f010368b <__umoddi3+0x11b>
f010367a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010367e:	73 0b                	jae    f010368b <__umoddi3+0x11b>
f0103680:	2b 44 24 04          	sub    0x4(%esp),%eax
f0103684:	1b 14 24             	sbb    (%esp),%edx
f0103687:	89 d1                	mov    %edx,%ecx
f0103689:	89 c3                	mov    %eax,%ebx
f010368b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010368f:	29 da                	sub    %ebx,%edx
f0103691:	19 ce                	sbb    %ecx,%esi
f0103693:	89 f9                	mov    %edi,%ecx
f0103695:	89 f0                	mov    %esi,%eax
f0103697:	d3 e0                	shl    %cl,%eax
f0103699:	89 e9                	mov    %ebp,%ecx
f010369b:	d3 ea                	shr    %cl,%edx
f010369d:	89 e9                	mov    %ebp,%ecx
f010369f:	d3 ee                	shr    %cl,%esi
f01036a1:	09 d0                	or     %edx,%eax
f01036a3:	89 f2                	mov    %esi,%edx
f01036a5:	83 c4 1c             	add    $0x1c,%esp
f01036a8:	5b                   	pop    %ebx
f01036a9:	5e                   	pop    %esi
f01036aa:	5f                   	pop    %edi
f01036ab:	5d                   	pop    %ebp
f01036ac:	c3                   	ret    
f01036ad:	8d 76 00             	lea    0x0(%esi),%esi
f01036b0:	29 f9                	sub    %edi,%ecx
f01036b2:	19 d6                	sbb    %edx,%esi
f01036b4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01036b8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01036bc:	e9 18 ff ff ff       	jmp    f01035d9 <__umoddi3+0x69>
