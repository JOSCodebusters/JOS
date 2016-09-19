
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
f0100015:	b8 00 20 11 00       	mov    $0x112000,%eax
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
f0100034:	bc 00 20 11 f0       	mov    $0xf0112000,%esp

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
f0100046:	b8 88 49 11 f0       	mov    $0xf0114988,%eax
f010004b:	2d 00 43 11 f0       	sub    $0xf0114300,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 00 43 11 f0       	push   $0xf0114300
f0100058:	e8 4a 1f 00 00       	call   f0101fa7 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 88 04 00 00       	call   f01004ea <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 40 24 10 f0       	push   $0xf0102440
f010006f:	e8 4f 14 00 00       	call   f01014c3 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 21 0d 00 00       	call   f0100d9a <mem_init>
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
f0100093:	83 3d 60 49 11 f0 00 	cmpl   $0x0,0xf0114960
f010009a:	75 37                	jne    f01000d3 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f010009c:	89 35 60 49 11 f0    	mov    %esi,0xf0114960

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
f01000b0:	68 5b 24 10 f0       	push   $0xf010245b
f01000b5:	e8 09 14 00 00       	call   f01014c3 <cprintf>
	vcprintf(fmt, ap);
f01000ba:	83 c4 08             	add    $0x8,%esp
f01000bd:	53                   	push   %ebx
f01000be:	56                   	push   %esi
f01000bf:	e8 d9 13 00 00       	call   f010149d <vcprintf>
	cprintf("\n");
f01000c4:	c7 04 24 97 24 10 f0 	movl   $0xf0102497,(%esp)
f01000cb:	e8 f3 13 00 00       	call   f01014c3 <cprintf>
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
f01000f2:	68 73 24 10 f0       	push   $0xf0102473
f01000f7:	e8 c7 13 00 00       	call   f01014c3 <cprintf>
	vcprintf(fmt, ap);
f01000fc:	83 c4 08             	add    $0x8,%esp
f01000ff:	53                   	push   %ebx
f0100100:	ff 75 10             	pushl  0x10(%ebp)
f0100103:	e8 95 13 00 00       	call   f010149d <vcprintf>
	cprintf("\n");
f0100108:	c7 04 24 97 24 10 f0 	movl   $0xf0102497,(%esp)
f010010f:	e8 af 13 00 00       	call   f01014c3 <cprintf>
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
f010014a:	8b 0d 24 45 11 f0    	mov    0xf0114524,%ecx
f0100150:	8d 51 01             	lea    0x1(%ecx),%edx
f0100153:	89 15 24 45 11 f0    	mov    %edx,0xf0114524
f0100159:	88 81 20 43 11 f0    	mov    %al,-0xfeebce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f010015f:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100165:	75 0a                	jne    f0100171 <cons_intr+0x36>
			cons.wpos = 0;
f0100167:	c7 05 24 45 11 f0 00 	movl   $0x0,0xf0114524
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
f0100198:	83 0d 00 43 11 f0 40 	orl    $0x40,0xf0114300
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
f01001b0:	8b 0d 00 43 11 f0    	mov    0xf0114300,%ecx
f01001b6:	89 cb                	mov    %ecx,%ebx
f01001b8:	83 e3 40             	and    $0x40,%ebx
f01001bb:	83 e0 7f             	and    $0x7f,%eax
f01001be:	85 db                	test   %ebx,%ebx
f01001c0:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001c3:	0f b6 d2             	movzbl %dl,%edx
f01001c6:	0f b6 82 e0 25 10 f0 	movzbl -0xfefda20(%edx),%eax
f01001cd:	83 c8 40             	or     $0x40,%eax
f01001d0:	0f b6 c0             	movzbl %al,%eax
f01001d3:	f7 d0                	not    %eax
f01001d5:	21 c8                	and    %ecx,%eax
f01001d7:	a3 00 43 11 f0       	mov    %eax,0xf0114300
		return 0;
f01001dc:	b8 00 00 00 00       	mov    $0x0,%eax
f01001e1:	e9 9e 00 00 00       	jmp    f0100284 <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f01001e6:	8b 0d 00 43 11 f0    	mov    0xf0114300,%ecx
f01001ec:	f6 c1 40             	test   $0x40,%cl
f01001ef:	74 0e                	je     f01001ff <kbd_proc_data+0x81>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01001f1:	83 c8 80             	or     $0xffffff80,%eax
f01001f4:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f01001f6:	83 e1 bf             	and    $0xffffffbf,%ecx
f01001f9:	89 0d 00 43 11 f0    	mov    %ecx,0xf0114300
	}

	shift |= shiftcode[data];
f01001ff:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f0100202:	0f b6 82 e0 25 10 f0 	movzbl -0xfefda20(%edx),%eax
f0100209:	0b 05 00 43 11 f0    	or     0xf0114300,%eax
f010020f:	0f b6 8a e0 24 10 f0 	movzbl -0xfefdb20(%edx),%ecx
f0100216:	31 c8                	xor    %ecx,%eax
f0100218:	a3 00 43 11 f0       	mov    %eax,0xf0114300

	c = charcode[shift & (CTL | SHIFT)][data];
f010021d:	89 c1                	mov    %eax,%ecx
f010021f:	83 e1 03             	and    $0x3,%ecx
f0100222:	8b 0c 8d c0 24 10 f0 	mov    -0xfefdb40(,%ecx,4),%ecx
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
f0100260:	68 8d 24 10 f0       	push   $0xf010248d
f0100265:	e8 59 12 00 00       	call   f01014c3 <cprintf>
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
f0100346:	0f b7 05 28 45 11 f0 	movzwl 0xf0114528,%eax
f010034d:	66 85 c0             	test   %ax,%ax
f0100350:	0f 84 e6 00 00 00    	je     f010043c <cons_putc+0x1b3>
			crt_pos--;
f0100356:	83 e8 01             	sub    $0x1,%eax
f0100359:	66 a3 28 45 11 f0    	mov    %ax,0xf0114528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010035f:	0f b7 c0             	movzwl %ax,%eax
f0100362:	66 81 e7 00 ff       	and    $0xff00,%di
f0100367:	83 cf 20             	or     $0x20,%edi
f010036a:	8b 15 2c 45 11 f0    	mov    0xf011452c,%edx
f0100370:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100374:	eb 78                	jmp    f01003ee <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100376:	66 83 05 28 45 11 f0 	addw   $0x50,0xf0114528
f010037d:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010037e:	0f b7 05 28 45 11 f0 	movzwl 0xf0114528,%eax
f0100385:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f010038b:	c1 e8 16             	shr    $0x16,%eax
f010038e:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100391:	c1 e0 04             	shl    $0x4,%eax
f0100394:	66 a3 28 45 11 f0    	mov    %ax,0xf0114528
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
f01003d0:	0f b7 05 28 45 11 f0 	movzwl 0xf0114528,%eax
f01003d7:	8d 50 01             	lea    0x1(%eax),%edx
f01003da:	66 89 15 28 45 11 f0 	mov    %dx,0xf0114528
f01003e1:	0f b7 c0             	movzwl %ax,%eax
f01003e4:	8b 15 2c 45 11 f0    	mov    0xf011452c,%edx
f01003ea:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01003ee:	66 81 3d 28 45 11 f0 	cmpw   $0x7cf,0xf0114528
f01003f5:	cf 07 
f01003f7:	76 43                	jbe    f010043c <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01003f9:	a1 2c 45 11 f0       	mov    0xf011452c,%eax
f01003fe:	83 ec 04             	sub    $0x4,%esp
f0100401:	68 00 0f 00 00       	push   $0xf00
f0100406:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010040c:	52                   	push   %edx
f010040d:	50                   	push   %eax
f010040e:	e8 e1 1b 00 00       	call   f0101ff4 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100413:	8b 15 2c 45 11 f0    	mov    0xf011452c,%edx
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
f0100434:	66 83 2d 28 45 11 f0 	subw   $0x50,0xf0114528
f010043b:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010043c:	8b 0d 30 45 11 f0    	mov    0xf0114530,%ecx
f0100442:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100447:	89 ca                	mov    %ecx,%edx
f0100449:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010044a:	0f b7 1d 28 45 11 f0 	movzwl 0xf0114528,%ebx
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
f0100472:	80 3d 34 45 11 f0 00 	cmpb   $0x0,0xf0114534
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
f01004b0:	a1 20 45 11 f0       	mov    0xf0114520,%eax
f01004b5:	3b 05 24 45 11 f0    	cmp    0xf0114524,%eax
f01004bb:	74 26                	je     f01004e3 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004bd:	8d 50 01             	lea    0x1(%eax),%edx
f01004c0:	89 15 20 45 11 f0    	mov    %edx,0xf0114520
f01004c6:	0f b6 88 20 43 11 f0 	movzbl -0xfeebce0(%eax),%ecx
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
f01004d7:	c7 05 20 45 11 f0 00 	movl   $0x0,0xf0114520
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
f0100510:	c7 05 30 45 11 f0 b4 	movl   $0x3b4,0xf0114530
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
f0100528:	c7 05 30 45 11 f0 d4 	movl   $0x3d4,0xf0114530
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
f0100537:	8b 3d 30 45 11 f0    	mov    0xf0114530,%edi
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
f010055c:	89 35 2c 45 11 f0    	mov    %esi,0xf011452c
	crt_pos = pos;
f0100562:	0f b6 c0             	movzbl %al,%eax
f0100565:	09 c8                	or     %ecx,%eax
f0100567:	66 a3 28 45 11 f0    	mov    %ax,0xf0114528
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
f01005c8:	0f 95 05 34 45 11 f0 	setne  0xf0114534
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
f01005dd:	68 99 24 10 f0       	push   $0xf0102499
f01005e2:	e8 dc 0e 00 00       	call   f01014c3 <cprintf>
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
f0100623:	68 e0 26 10 f0       	push   $0xf01026e0
f0100628:	68 fe 26 10 f0       	push   $0xf01026fe
f010062d:	68 03 27 10 f0       	push   $0xf0102703
f0100632:	e8 8c 0e 00 00       	call   f01014c3 <cprintf>
f0100637:	83 c4 0c             	add    $0xc,%esp
f010063a:	68 9c 27 10 f0       	push   $0xf010279c
f010063f:	68 0c 27 10 f0       	push   $0xf010270c
f0100644:	68 03 27 10 f0       	push   $0xf0102703
f0100649:	e8 75 0e 00 00       	call   f01014c3 <cprintf>
f010064e:	83 c4 0c             	add    $0xc,%esp
f0100651:	68 c4 27 10 f0       	push   $0xf01027c4
f0100656:	68 15 27 10 f0       	push   $0xf0102715
f010065b:	68 03 27 10 f0       	push   $0xf0102703
f0100660:	e8 5e 0e 00 00       	call   f01014c3 <cprintf>
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
f0100672:	68 1f 27 10 f0       	push   $0xf010271f
f0100677:	e8 47 0e 00 00       	call   f01014c3 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f010067c:	83 c4 08             	add    $0x8,%esp
f010067f:	68 0c 00 10 00       	push   $0x10000c
f0100684:	68 e4 27 10 f0       	push   $0xf01027e4
f0100689:	e8 35 0e 00 00       	call   f01014c3 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010068e:	83 c4 0c             	add    $0xc,%esp
f0100691:	68 0c 00 10 00       	push   $0x10000c
f0100696:	68 0c 00 10 f0       	push   $0xf010000c
f010069b:	68 0c 28 10 f0       	push   $0xf010280c
f01006a0:	e8 1e 0e 00 00       	call   f01014c3 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006a5:	83 c4 0c             	add    $0xc,%esp
f01006a8:	68 31 24 10 00       	push   $0x102431
f01006ad:	68 31 24 10 f0       	push   $0xf0102431
f01006b2:	68 30 28 10 f0       	push   $0xf0102830
f01006b7:	e8 07 0e 00 00       	call   f01014c3 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006bc:	83 c4 0c             	add    $0xc,%esp
f01006bf:	68 00 43 11 00       	push   $0x114300
f01006c4:	68 00 43 11 f0       	push   $0xf0114300
f01006c9:	68 54 28 10 f0       	push   $0xf0102854
f01006ce:	e8 f0 0d 00 00       	call   f01014c3 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006d3:	83 c4 0c             	add    $0xc,%esp
f01006d6:	68 88 49 11 00       	push   $0x114988
f01006db:	68 88 49 11 f0       	push   $0xf0114988
f01006e0:	68 78 28 10 f0       	push   $0xf0102878
f01006e5:	e8 d9 0d 00 00       	call   f01014c3 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006ea:	b8 87 4d 11 f0       	mov    $0xf0114d87,%eax
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
f010070b:	68 9c 28 10 f0       	push   $0xf010289c
f0100710:	e8 ae 0d 00 00       	call   f01014c3 <cprintf>
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
f0100726:	68 38 27 10 f0       	push   $0xf0102738
f010072b:	e8 93 0d 00 00       	call   f01014c3 <cprintf>
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
f010074b:	68 c8 28 10 f0       	push   $0xf01028c8
f0100750:	e8 6e 0d 00 00       	call   f01014c3 <cprintf>
		debuginfo_eip(test_ebp[1],&info);
f0100755:	83 c4 18             	add    $0x18,%esp
f0100758:	56                   	push   %esi
f0100759:	ff 73 04             	pushl  0x4(%ebx)
f010075c:	e8 6c 0e 00 00       	call   f01015cd <debuginfo_eip>
		cprintf("\t    %s:%d: %.*s+%d\n",info.eip_file,info.eip_line,info.eip_fn_namelen,info.eip_fn_name,test_ebp[1] - info.eip_fn_addr);
f0100761:	83 c4 08             	add    $0x8,%esp
f0100764:	8b 43 04             	mov    0x4(%ebx),%eax
f0100767:	2b 45 f0             	sub    -0x10(%ebp),%eax
f010076a:	50                   	push   %eax
f010076b:	ff 75 e8             	pushl  -0x18(%ebp)
f010076e:	ff 75 ec             	pushl  -0x14(%ebp)
f0100771:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100774:	ff 75 e0             	pushl  -0x20(%ebp)
f0100777:	68 4a 27 10 f0       	push   $0xf010274a
f010077c:	e8 42 0d 00 00       	call   f01014c3 <cprintf>
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
f010079f:	68 fc 28 10 f0       	push   $0xf01028fc
f01007a4:	e8 1a 0d 00 00       	call   f01014c3 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007a9:	c7 04 24 20 29 10 f0 	movl   $0xf0102920,(%esp)
f01007b0:	e8 0e 0d 00 00       	call   f01014c3 <cprintf>
f01007b5:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f01007b8:	83 ec 0c             	sub    $0xc,%esp
f01007bb:	68 5f 27 10 f0       	push   $0xf010275f
f01007c0:	e8 8b 15 00 00       	call   f0101d50 <readline>
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
f01007f4:	68 63 27 10 f0       	push   $0xf0102763
f01007f9:	e8 6c 17 00 00       	call   f0101f6a <strchr>
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
f0100814:	68 68 27 10 f0       	push   $0xf0102768
f0100819:	e8 a5 0c 00 00       	call   f01014c3 <cprintf>
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
f010083d:	68 63 27 10 f0       	push   $0xf0102763
f0100842:	e8 23 17 00 00       	call   f0101f6a <strchr>
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
f010086b:	ff 34 85 60 29 10 f0 	pushl  -0xfefd6a0(,%eax,4)
f0100872:	ff 75 a8             	pushl  -0x58(%ebp)
f0100875:	e8 92 16 00 00       	call   f0101f0c <strcmp>
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
f010088f:	ff 14 85 68 29 10 f0 	call   *-0xfefd698(,%eax,4)


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
f01008b0:	68 85 27 10 f0       	push   $0xf0102785
f01008b5:	e8 09 0c 00 00       	call   f01014c3 <cprintf>
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
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f01008cd:	83 3d 38 45 11 f0 00 	cmpl   $0x0,0xf0114538
f01008d4:	75 37                	jne    f010090d <boot_alloc+0x43>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f01008d6:	ba 87 59 11 f0       	mov    $0xf0115987,%edx
f01008db:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01008e1:	89 15 38 45 11 f0    	mov    %edx,0xf0114538
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if(n > 0){ 
f01008e7:	85 c0                	test   %eax,%eax
f01008e9:	74 1b                	je     f0100906 <boot_alloc+0x3c>
		result = nextfree;
f01008eb:	8b 15 38 45 11 f0    	mov    0xf0114538,%edx
		nextfree += n;
		nextfree = ROUNDUP((char *)nextfree,PGSIZE);
f01008f1:	8d 84 02 ff 0f 00 00 	lea    0xfff(%edx,%eax,1),%eax
f01008f8:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01008fd:	a3 38 45 11 f0       	mov    %eax,0xf0114538
		
		return result;
f0100902:	89 d0                	mov    %edx,%eax
f0100904:	eb 0d                	jmp    f0100913 <boot_alloc+0x49>
	}
	else if(n == 0)
		return nextfree;
f0100906:	a1 38 45 11 f0       	mov    0xf0114538,%eax
f010090b:	eb 06                	jmp    f0100913 <boot_alloc+0x49>
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if(n > 0){ 
f010090d:	85 c0                	test   %eax,%eax
f010090f:	74 f5                	je     f0100906 <boot_alloc+0x3c>
f0100911:	eb d8                	jmp    f01008eb <boot_alloc+0x21>
	}
	else if(n == 0)
		return nextfree;
	
	return NULL;
}
f0100913:	5d                   	pop    %ebp
f0100914:	c3                   	ret    

f0100915 <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0100915:	89 d1                	mov    %edx,%ecx
f0100917:	c1 e9 16             	shr    $0x16,%ecx
f010091a:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f010091d:	a8 01                	test   $0x1,%al
f010091f:	74 52                	je     f0100973 <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100921:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100926:	89 c1                	mov    %eax,%ecx
f0100928:	c1 e9 0c             	shr    $0xc,%ecx
f010092b:	3b 0d 7c 49 11 f0    	cmp    0xf011497c,%ecx
f0100931:	72 1b                	jb     f010094e <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100933:	55                   	push   %ebp
f0100934:	89 e5                	mov    %esp,%ebp
f0100936:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100939:	50                   	push   %eax
f010093a:	68 84 29 10 f0       	push   $0xf0102984
f010093f:	68 94 02 00 00       	push   $0x294
f0100944:	68 3c 2b 10 f0       	push   $0xf0102b3c
f0100949:	e8 3d f7 ff ff       	call   f010008b <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f010094e:	c1 ea 0c             	shr    $0xc,%edx
f0100951:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100957:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f010095e:	89 c2                	mov    %eax,%edx
f0100960:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100963:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100968:	85 d2                	test   %edx,%edx
f010096a:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f010096f:	0f 44 c2             	cmove  %edx,%eax
f0100972:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100973:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100978:	c3                   	ret    

f0100979 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100979:	55                   	push   %ebp
f010097a:	89 e5                	mov    %esp,%ebp
f010097c:	57                   	push   %edi
f010097d:	56                   	push   %esi
f010097e:	53                   	push   %ebx
f010097f:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100982:	84 c0                	test   %al,%al
f0100984:	0f 85 72 02 00 00    	jne    f0100bfc <check_page_free_list+0x283>
f010098a:	e9 7f 02 00 00       	jmp    f0100c0e <check_page_free_list+0x295>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f010098f:	83 ec 04             	sub    $0x4,%esp
f0100992:	68 a8 29 10 f0       	push   $0xf01029a8
f0100997:	68 de 01 00 00       	push   $0x1de
f010099c:	68 3c 2b 10 f0       	push   $0xf0102b3c
f01009a1:	e8 e5 f6 ff ff       	call   f010008b <_panic>
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f01009a6:	8d 55 d8             	lea    -0x28(%ebp),%edx
f01009a9:	89 55 e0             	mov    %edx,-0x20(%ebp)
f01009ac:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01009af:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f01009b2:	89 c2                	mov    %eax,%edx
f01009b4:	2b 15 84 49 11 f0    	sub    0xf0114984,%edx
f01009ba:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f01009c0:	0f 95 c2             	setne  %dl
f01009c3:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f01009c6:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f01009ca:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f01009cc:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f01009d0:	8b 00                	mov    (%eax),%eax
f01009d2:	85 c0                	test   %eax,%eax
f01009d4:	75 dc                	jne    f01009b2 <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f01009d6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01009d9:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f01009df:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01009e2:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01009e5:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f01009e7:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01009ea:	a3 3c 45 11 f0       	mov    %eax,0xf011453c
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f01009ef:	be 01 00 00 00       	mov    $0x1,%esi
		*tp[0] = pp2;
		page_free_list = pp1;
	}
	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01009f4:	8b 1d 3c 45 11 f0    	mov    0xf011453c,%ebx
f01009fa:	eb 53                	jmp    f0100a4f <check_page_free_list+0xd6>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01009fc:	89 d8                	mov    %ebx,%eax
f01009fe:	2b 05 84 49 11 f0    	sub    0xf0114984,%eax
f0100a04:	c1 f8 03             	sar    $0x3,%eax
f0100a07:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100a0a:	89 c2                	mov    %eax,%edx
f0100a0c:	c1 ea 16             	shr    $0x16,%edx
f0100a0f:	39 f2                	cmp    %esi,%edx
f0100a11:	73 3a                	jae    f0100a4d <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a13:	89 c2                	mov    %eax,%edx
f0100a15:	c1 ea 0c             	shr    $0xc,%edx
f0100a18:	3b 15 7c 49 11 f0    	cmp    0xf011497c,%edx
f0100a1e:	72 12                	jb     f0100a32 <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a20:	50                   	push   %eax
f0100a21:	68 84 29 10 f0       	push   $0xf0102984
f0100a26:	6a 52                	push   $0x52
f0100a28:	68 48 2b 10 f0       	push   $0xf0102b48
f0100a2d:	e8 59 f6 ff ff       	call   f010008b <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100a32:	83 ec 04             	sub    $0x4,%esp
f0100a35:	68 80 00 00 00       	push   $0x80
f0100a3a:	68 97 00 00 00       	push   $0x97
f0100a3f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100a44:	50                   	push   %eax
f0100a45:	e8 5d 15 00 00       	call   f0101fa7 <memset>
f0100a4a:	83 c4 10             	add    $0x10,%esp
		*tp[0] = pp2;
		page_free_list = pp1;
	}
	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a4d:	8b 1b                	mov    (%ebx),%ebx
f0100a4f:	85 db                	test   %ebx,%ebx
f0100a51:	75 a9                	jne    f01009fc <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);
	first_free_page = (char *) boot_alloc(0);
f0100a53:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a58:	e8 6d fe ff ff       	call   f01008ca <boot_alloc>
f0100a5d:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a60:	8b 15 3c 45 11 f0    	mov    0xf011453c,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100a66:	8b 0d 84 49 11 f0    	mov    0xf0114984,%ecx
		assert(pp < pages + npages);
f0100a6c:	a1 7c 49 11 f0       	mov    0xf011497c,%eax
f0100a71:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100a74:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100a77:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100a7a:	be 00 00 00 00       	mov    $0x0,%esi
f0100a7f:	89 5d d0             	mov    %ebx,-0x30(%ebp)
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);
	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a82:	e9 30 01 00 00       	jmp    f0100bb7 <check_page_free_list+0x23e>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100a87:	39 ca                	cmp    %ecx,%edx
f0100a89:	73 19                	jae    f0100aa4 <check_page_free_list+0x12b>
f0100a8b:	68 56 2b 10 f0       	push   $0xf0102b56
f0100a90:	68 62 2b 10 f0       	push   $0xf0102b62
f0100a95:	68 f5 01 00 00       	push   $0x1f5
f0100a9a:	68 3c 2b 10 f0       	push   $0xf0102b3c
f0100a9f:	e8 e7 f5 ff ff       	call   f010008b <_panic>
		assert(pp < pages + npages);
f0100aa4:	39 fa                	cmp    %edi,%edx
f0100aa6:	72 19                	jb     f0100ac1 <check_page_free_list+0x148>
f0100aa8:	68 77 2b 10 f0       	push   $0xf0102b77
f0100aad:	68 62 2b 10 f0       	push   $0xf0102b62
f0100ab2:	68 f6 01 00 00       	push   $0x1f6
f0100ab7:	68 3c 2b 10 f0       	push   $0xf0102b3c
f0100abc:	e8 ca f5 ff ff       	call   f010008b <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100ac1:	89 d0                	mov    %edx,%eax
f0100ac3:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100ac6:	a8 07                	test   $0x7,%al
f0100ac8:	74 19                	je     f0100ae3 <check_page_free_list+0x16a>
f0100aca:	68 cc 29 10 f0       	push   $0xf01029cc
f0100acf:	68 62 2b 10 f0       	push   $0xf0102b62
f0100ad4:	68 f7 01 00 00       	push   $0x1f7
f0100ad9:	68 3c 2b 10 f0       	push   $0xf0102b3c
f0100ade:	e8 a8 f5 ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100ae3:	c1 f8 03             	sar    $0x3,%eax
f0100ae6:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100ae9:	85 c0                	test   %eax,%eax
f0100aeb:	75 19                	jne    f0100b06 <check_page_free_list+0x18d>
f0100aed:	68 8b 2b 10 f0       	push   $0xf0102b8b
f0100af2:	68 62 2b 10 f0       	push   $0xf0102b62
f0100af7:	68 fa 01 00 00       	push   $0x1fa
f0100afc:	68 3c 2b 10 f0       	push   $0xf0102b3c
f0100b01:	e8 85 f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100b06:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100b0b:	75 19                	jne    f0100b26 <check_page_free_list+0x1ad>
f0100b0d:	68 9c 2b 10 f0       	push   $0xf0102b9c
f0100b12:	68 62 2b 10 f0       	push   $0xf0102b62
f0100b17:	68 fb 01 00 00       	push   $0x1fb
f0100b1c:	68 3c 2b 10 f0       	push   $0xf0102b3c
f0100b21:	e8 65 f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100b26:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100b2b:	75 19                	jne    f0100b46 <check_page_free_list+0x1cd>
f0100b2d:	68 00 2a 10 f0       	push   $0xf0102a00
f0100b32:	68 62 2b 10 f0       	push   $0xf0102b62
f0100b37:	68 fc 01 00 00       	push   $0x1fc
f0100b3c:	68 3c 2b 10 f0       	push   $0xf0102b3c
f0100b41:	e8 45 f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100b46:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100b4b:	75 19                	jne    f0100b66 <check_page_free_list+0x1ed>
f0100b4d:	68 b5 2b 10 f0       	push   $0xf0102bb5
f0100b52:	68 62 2b 10 f0       	push   $0xf0102b62
f0100b57:	68 fd 01 00 00       	push   $0x1fd
f0100b5c:	68 3c 2b 10 f0       	push   $0xf0102b3c
f0100b61:	e8 25 f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100b66:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100b6b:	76 3f                	jbe    f0100bac <check_page_free_list+0x233>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b6d:	89 c3                	mov    %eax,%ebx
f0100b6f:	c1 eb 0c             	shr    $0xc,%ebx
f0100b72:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100b75:	77 12                	ja     f0100b89 <check_page_free_list+0x210>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b77:	50                   	push   %eax
f0100b78:	68 84 29 10 f0       	push   $0xf0102984
f0100b7d:	6a 52                	push   $0x52
f0100b7f:	68 48 2b 10 f0       	push   $0xf0102b48
f0100b84:	e8 02 f5 ff ff       	call   f010008b <_panic>
f0100b89:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b8e:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100b91:	76 1e                	jbe    f0100bb1 <check_page_free_list+0x238>
f0100b93:	68 24 2a 10 f0       	push   $0xf0102a24
f0100b98:	68 62 2b 10 f0       	push   $0xf0102b62
f0100b9d:	68 fe 01 00 00       	push   $0x1fe
f0100ba2:	68 3c 2b 10 f0       	push   $0xf0102b3c
f0100ba7:	e8 df f4 ff ff       	call   f010008b <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100bac:	83 c6 01             	add    $0x1,%esi
f0100baf:	eb 04                	jmp    f0100bb5 <check_page_free_list+0x23c>
		else
			++nfree_extmem;
f0100bb1:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);
	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100bb5:	8b 12                	mov    (%edx),%edx
f0100bb7:	85 d2                	test   %edx,%edx
f0100bb9:	0f 85 c8 fe ff ff    	jne    f0100a87 <check_page_free_list+0x10e>
f0100bbf:	8b 5d d0             	mov    -0x30(%ebp),%ebx
		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
		else
			++nfree_extmem;
	}
	assert(nfree_basemem > 0);
f0100bc2:	85 f6                	test   %esi,%esi
f0100bc4:	7f 19                	jg     f0100bdf <check_page_free_list+0x266>
f0100bc6:	68 cf 2b 10 f0       	push   $0xf0102bcf
f0100bcb:	68 62 2b 10 f0       	push   $0xf0102b62
f0100bd0:	68 05 02 00 00       	push   $0x205
f0100bd5:	68 3c 2b 10 f0       	push   $0xf0102b3c
f0100bda:	e8 ac f4 ff ff       	call   f010008b <_panic>
	assert(nfree_extmem > 0);
f0100bdf:	85 db                	test   %ebx,%ebx
f0100be1:	7f 42                	jg     f0100c25 <check_page_free_list+0x2ac>
f0100be3:	68 e1 2b 10 f0       	push   $0xf0102be1
f0100be8:	68 62 2b 10 f0       	push   $0xf0102b62
f0100bed:	68 06 02 00 00       	push   $0x206
f0100bf2:	68 3c 2b 10 f0       	push   $0xf0102b3c
f0100bf7:	e8 8f f4 ff ff       	call   f010008b <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100bfc:	a1 3c 45 11 f0       	mov    0xf011453c,%eax
f0100c01:	85 c0                	test   %eax,%eax
f0100c03:	0f 85 9d fd ff ff    	jne    f01009a6 <check_page_free_list+0x2d>
f0100c09:	e9 81 fd ff ff       	jmp    f010098f <check_page_free_list+0x16>
f0100c0e:	83 3d 3c 45 11 f0 00 	cmpl   $0x0,0xf011453c
f0100c15:	0f 84 74 fd ff ff    	je     f010098f <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c1b:	be 00 04 00 00       	mov    $0x400,%esi
f0100c20:	e9 cf fd ff ff       	jmp    f01009f4 <check_page_free_list+0x7b>
		else
			++nfree_extmem;
	}
	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0100c25:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100c28:	5b                   	pop    %ebx
f0100c29:	5e                   	pop    %esi
f0100c2a:	5f                   	pop    %edi
f0100c2b:	5d                   	pop    %ebp
f0100c2c:	c3                   	ret    

f0100c2d <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100c2d:	55                   	push   %ebp
f0100c2e:	89 e5                	mov    %esp,%ebp
f0100c30:	56                   	push   %esi
f0100c31:	53                   	push   %ebx
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 1;i < npages_basemem; i++) {
f0100c32:	8b 35 40 45 11 f0    	mov    0xf0114540,%esi
f0100c38:	8b 1d 3c 45 11 f0    	mov    0xf011453c,%ebx
f0100c3e:	ba 00 00 00 00       	mov    $0x0,%edx
f0100c43:	b8 01 00 00 00       	mov    $0x1,%eax
f0100c48:	eb 27                	jmp    f0100c71 <page_init+0x44>
		pages[i].pp_ref = 0;
f0100c4a:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f0100c51:	89 d1                	mov    %edx,%ecx
f0100c53:	03 0d 84 49 11 f0    	add    0xf0114984,%ecx
f0100c59:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100c5f:	89 19                	mov    %ebx,(%ecx)
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 1;i < npages_basemem; i++) {
f0100c61:	83 c0 01             	add    $0x1,%eax
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];		
f0100c64:	89 d3                	mov    %edx,%ebx
f0100c66:	03 1d 84 49 11 f0    	add    0xf0114984,%ebx
f0100c6c:	ba 01 00 00 00       	mov    $0x1,%edx
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 1;i < npages_basemem; i++) {
f0100c71:	39 f0                	cmp    %esi,%eax
f0100c73:	72 d5                	jb     f0100c4a <page_init+0x1d>
f0100c75:	84 d2                	test   %dl,%dl
f0100c77:	74 06                	je     f0100c7f <page_init+0x52>
f0100c79:	89 1d 3c 45 11 f0    	mov    %ebx,0xf011453c
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];		
	}
	int free = (int)ROUNDUP(((char *)pages + sizeof(struct PageInfo) * npages) - KERNBASE,PGSIZE)/PGSIZE;
f0100c7f:	a1 84 49 11 f0       	mov    0xf0114984,%eax
f0100c84:	8b 15 7c 49 11 f0    	mov    0xf011497c,%edx
f0100c8a:	8d 84 d0 ff 0f 00 10 	lea    0x10000fff(%eax,%edx,8),%eax
	for (i = free;i < npages; i++) {
f0100c91:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100c96:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0100c9c:	85 c0                	test   %eax,%eax
f0100c9e:	0f 48 c2             	cmovs  %edx,%eax
f0100ca1:	c1 f8 0c             	sar    $0xc,%eax
f0100ca4:	89 c2                	mov    %eax,%edx
f0100ca6:	8b 1d 3c 45 11 f0    	mov    0xf011453c,%ebx
f0100cac:	c1 e0 03             	shl    $0x3,%eax
f0100caf:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100cb4:	eb 23                	jmp    f0100cd9 <page_init+0xac>
		pages[i].pp_ref = 0;
f0100cb6:	89 c1                	mov    %eax,%ecx
f0100cb8:	03 0d 84 49 11 f0    	add    0xf0114984,%ecx
f0100cbe:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100cc4:	89 19                	mov    %ebx,(%ecx)
		page_free_list = &pages[i];		
f0100cc6:	89 c3                	mov    %eax,%ebx
f0100cc8:	03 1d 84 49 11 f0    	add    0xf0114984,%ebx
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];		
	}
	int free = (int)ROUNDUP(((char *)pages + sizeof(struct PageInfo) * npages) - KERNBASE,PGSIZE)/PGSIZE;
	for (i = free;i < npages; i++) {
f0100cce:	83 c2 01             	add    $0x1,%edx
f0100cd1:	83 c0 08             	add    $0x8,%eax
f0100cd4:	b9 01 00 00 00       	mov    $0x1,%ecx
f0100cd9:	3b 15 7c 49 11 f0    	cmp    0xf011497c,%edx
f0100cdf:	72 d5                	jb     f0100cb6 <page_init+0x89>
f0100ce1:	84 c9                	test   %cl,%cl
f0100ce3:	74 06                	je     f0100ceb <page_init+0xbe>
f0100ce5:	89 1d 3c 45 11 f0    	mov    %ebx,0xf011453c
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];		
	}
}
f0100ceb:	5b                   	pop    %ebx
f0100cec:	5e                   	pop    %esi
f0100ced:	5d                   	pop    %ebp
f0100cee:	c3                   	ret    

f0100cef <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{	
f0100cef:	55                   	push   %ebp
f0100cf0:	89 e5                	mov    %esp,%ebp
f0100cf2:	53                   	push   %ebx
f0100cf3:	83 ec 04             	sub    $0x4,%esp
	if(!(page_free_list))
f0100cf6:	8b 1d 3c 45 11 f0    	mov    0xf011453c,%ebx
f0100cfc:	85 db                	test   %ebx,%ebx
f0100cfe:	74 58                	je     f0100d58 <page_alloc+0x69>
		return NULL;
	else{
		struct PageInfo *new_page;
		new_page = page_free_list;
		page_free_list = page_free_list->pp_link;
f0100d00:	8b 03                	mov    (%ebx),%eax
f0100d02:	a3 3c 45 11 f0       	mov    %eax,0xf011453c
		if(alloc_flags & ALLOC_ZERO)
f0100d07:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100d0b:	74 45                	je     f0100d52 <page_alloc+0x63>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100d0d:	89 d8                	mov    %ebx,%eax
f0100d0f:	2b 05 84 49 11 f0    	sub    0xf0114984,%eax
f0100d15:	c1 f8 03             	sar    $0x3,%eax
f0100d18:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100d1b:	89 c2                	mov    %eax,%edx
f0100d1d:	c1 ea 0c             	shr    $0xc,%edx
f0100d20:	3b 15 7c 49 11 f0    	cmp    0xf011497c,%edx
f0100d26:	72 12                	jb     f0100d3a <page_alloc+0x4b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d28:	50                   	push   %eax
f0100d29:	68 84 29 10 f0       	push   $0xf0102984
f0100d2e:	6a 52                	push   $0x52
f0100d30:	68 48 2b 10 f0       	push   $0xf0102b48
f0100d35:	e8 51 f3 ff ff       	call   f010008b <_panic>
			memset(page2kva(new_page),0, PGSIZE);
f0100d3a:	83 ec 04             	sub    $0x4,%esp
f0100d3d:	68 00 10 00 00       	push   $0x1000
f0100d42:	6a 00                	push   $0x0
f0100d44:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100d49:	50                   	push   %eax
f0100d4a:	e8 58 12 00 00       	call   f0101fa7 <memset>
f0100d4f:	83 c4 10             	add    $0x10,%esp
		new_page->pp_link = NULL;
f0100d52:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
		return new_page;
	}
	return 0;
}
f0100d58:	89 d8                	mov    %ebx,%eax
f0100d5a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100d5d:	c9                   	leave  
f0100d5e:	c3                   	ret    

f0100d5f <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100d5f:	55                   	push   %ebp
f0100d60:	89 e5                	mov    %esp,%ebp
f0100d62:	83 ec 08             	sub    $0x8,%esp
f0100d65:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	if((pp->pp_ref != 0) || (pp->pp_link != NULL))
f0100d68:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100d6d:	75 05                	jne    f0100d74 <page_free+0x15>
f0100d6f:	83 38 00             	cmpl   $0x0,(%eax)
f0100d72:	74 17                	je     f0100d8b <page_free+0x2c>
		panic("page_free error");
f0100d74:	83 ec 04             	sub    $0x4,%esp
f0100d77:	68 f2 2b 10 f0       	push   $0xf0102bf2
f0100d7c:	68 3a 01 00 00       	push   $0x13a
f0100d81:	68 3c 2b 10 f0       	push   $0xf0102b3c
f0100d86:	e8 00 f3 ff ff       	call   f010008b <_panic>
	pp->pp_link = page_free_list;
f0100d8b:	8b 15 3c 45 11 f0    	mov    0xf011453c,%edx
f0100d91:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100d93:	a3 3c 45 11 f0       	mov    %eax,0xf011453c
}
f0100d98:	c9                   	leave  
f0100d99:	c3                   	ret    

f0100d9a <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0100d9a:	55                   	push   %ebp
f0100d9b:	89 e5                	mov    %esp,%ebp
f0100d9d:	57                   	push   %edi
f0100d9e:	56                   	push   %esi
f0100d9f:	53                   	push   %ebx
f0100da0:	83 ec 28             	sub    $0x28,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100da3:	6a 15                	push   $0x15
f0100da5:	e8 b2 06 00 00       	call   f010145c <mc146818_read>
f0100daa:	89 c3                	mov    %eax,%ebx
f0100dac:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f0100db3:	e8 a4 06 00 00       	call   f010145c <mc146818_read>
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f0100db8:	c1 e0 08             	shl    $0x8,%eax
f0100dbb:	09 d8                	or     %ebx,%eax
f0100dbd:	c1 e0 0a             	shl    $0xa,%eax
f0100dc0:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0100dc6:	85 c0                	test   %eax,%eax
f0100dc8:	0f 48 c2             	cmovs  %edx,%eax
f0100dcb:	c1 f8 0c             	sar    $0xc,%eax
f0100dce:	a3 40 45 11 f0       	mov    %eax,0xf0114540
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100dd3:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f0100dda:	e8 7d 06 00 00       	call   f010145c <mc146818_read>
f0100ddf:	89 c3                	mov    %eax,%ebx
f0100de1:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f0100de8:	e8 6f 06 00 00       	call   f010145c <mc146818_read>
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f0100ded:	c1 e0 08             	shl    $0x8,%eax
f0100df0:	09 d8                	or     %ebx,%eax
f0100df2:	c1 e0 0a             	shl    $0xa,%eax
f0100df5:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0100dfb:	83 c4 10             	add    $0x10,%esp
f0100dfe:	85 c0                	test   %eax,%eax
f0100e00:	0f 48 c2             	cmovs  %edx,%eax
f0100e03:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f0100e06:	85 c0                	test   %eax,%eax
f0100e08:	74 0e                	je     f0100e18 <mem_init+0x7e>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f0100e0a:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f0100e10:	89 15 7c 49 11 f0    	mov    %edx,0xf011497c
f0100e16:	eb 0c                	jmp    f0100e24 <mem_init+0x8a>
	else
		npages = npages_basemem;
f0100e18:	8b 15 40 45 11 f0    	mov    0xf0114540,%edx
f0100e1e:	89 15 7c 49 11 f0    	mov    %edx,0xf011497c

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100e24:	c1 e0 0c             	shl    $0xc,%eax
f0100e27:	c1 e8 0a             	shr    $0xa,%eax
f0100e2a:	50                   	push   %eax
f0100e2b:	a1 40 45 11 f0       	mov    0xf0114540,%eax
f0100e30:	c1 e0 0c             	shl    $0xc,%eax
f0100e33:	c1 e8 0a             	shr    $0xa,%eax
f0100e36:	50                   	push   %eax
f0100e37:	a1 7c 49 11 f0       	mov    0xf011497c,%eax
f0100e3c:	c1 e0 0c             	shl    $0xc,%eax
f0100e3f:	c1 e8 0a             	shr    $0xa,%eax
f0100e42:	50                   	push   %eax
f0100e43:	68 6c 2a 10 f0       	push   $0xf0102a6c
f0100e48:	e8 76 06 00 00       	call   f01014c3 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);			//the boot_alloc allocates n = 1000 which is 4KB and this is our 										//page directory(i.e. the first level of the two level page 										//tables)   
f0100e4d:	b8 00 10 00 00       	mov    $0x1000,%eax
f0100e52:	e8 73 fa ff ff       	call   f01008ca <boot_alloc>
f0100e57:	a3 80 49 11 f0       	mov    %eax,0xf0114980
	memset(kern_pgdir, 0, PGSIZE);
f0100e5c:	83 c4 0c             	add    $0xc,%esp
f0100e5f:	68 00 10 00 00       	push   $0x1000
f0100e64:	6a 00                	push   $0x0
f0100e66:	50                   	push   %eax
f0100e67:	e8 3b 11 00 00       	call   f0101fa7 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0100e6c:	a1 80 49 11 f0       	mov    0xf0114980,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100e71:	83 c4 10             	add    $0x10,%esp
f0100e74:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100e79:	77 15                	ja     f0100e90 <mem_init+0xf6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100e7b:	50                   	push   %eax
f0100e7c:	68 a8 2a 10 f0       	push   $0xf0102aa8
f0100e81:	68 92 00 00 00       	push   $0x92
f0100e86:	68 3c 2b 10 f0       	push   $0xf0102b3c
f0100e8b:	e8 fb f1 ff ff       	call   f010008b <_panic>
f0100e90:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0100e96:	83 ca 05             	or     $0x5,%edx
f0100e99:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	
	pages = (struct PageInfo *)boot_alloc(sizeof(struct PageInfo) * npages);
f0100e9f:	a1 7c 49 11 f0       	mov    0xf011497c,%eax
f0100ea4:	c1 e0 03             	shl    $0x3,%eax
f0100ea7:	e8 1e fa ff ff       	call   f01008ca <boot_alloc>
f0100eac:	a3 84 49 11 f0       	mov    %eax,0xf0114984
	memset(pages, 0, sizeof(struct PageInfo) * npages);
f0100eb1:	83 ec 04             	sub    $0x4,%esp
f0100eb4:	8b 0d 7c 49 11 f0    	mov    0xf011497c,%ecx
f0100eba:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f0100ec1:	52                   	push   %edx
f0100ec2:	6a 00                	push   $0x0
f0100ec4:	50                   	push   %eax
f0100ec5:	e8 dd 10 00 00       	call   f0101fa7 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0100eca:	e8 5e fd ff ff       	call   f0100c2d <page_init>

	check_page_free_list(1);
f0100ecf:	b8 01 00 00 00       	mov    $0x1,%eax
f0100ed4:	e8 a0 fa ff ff       	call   f0100979 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0100ed9:	83 c4 10             	add    $0x10,%esp
f0100edc:	83 3d 84 49 11 f0 00 	cmpl   $0x0,0xf0114984
f0100ee3:	75 17                	jne    f0100efc <mem_init+0x162>
		panic("'pages' is a null pointer!");
f0100ee5:	83 ec 04             	sub    $0x4,%esp
f0100ee8:	68 02 2c 10 f0       	push   $0xf0102c02
f0100eed:	68 17 02 00 00       	push   $0x217
f0100ef2:	68 3c 2b 10 f0       	push   $0xf0102b3c
f0100ef7:	e8 8f f1 ff ff       	call   f010008b <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0100efc:	a1 3c 45 11 f0       	mov    0xf011453c,%eax
f0100f01:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100f06:	eb 05                	jmp    f0100f0d <mem_init+0x173>
		++nfree;
f0100f08:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0100f0b:	8b 00                	mov    (%eax),%eax
f0100f0d:	85 c0                	test   %eax,%eax
f0100f0f:	75 f7                	jne    f0100f08 <mem_init+0x16e>
		++nfree;
	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0100f11:	83 ec 0c             	sub    $0xc,%esp
f0100f14:	6a 00                	push   $0x0
f0100f16:	e8 d4 fd ff ff       	call   f0100cef <page_alloc>
f0100f1b:	89 c7                	mov    %eax,%edi
f0100f1d:	83 c4 10             	add    $0x10,%esp
f0100f20:	85 c0                	test   %eax,%eax
f0100f22:	75 19                	jne    f0100f3d <mem_init+0x1a3>
f0100f24:	68 1d 2c 10 f0       	push   $0xf0102c1d
f0100f29:	68 62 2b 10 f0       	push   $0xf0102b62
f0100f2e:	68 1e 02 00 00       	push   $0x21e
f0100f33:	68 3c 2b 10 f0       	push   $0xf0102b3c
f0100f38:	e8 4e f1 ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0100f3d:	83 ec 0c             	sub    $0xc,%esp
f0100f40:	6a 00                	push   $0x0
f0100f42:	e8 a8 fd ff ff       	call   f0100cef <page_alloc>
f0100f47:	89 c6                	mov    %eax,%esi
f0100f49:	83 c4 10             	add    $0x10,%esp
f0100f4c:	85 c0                	test   %eax,%eax
f0100f4e:	75 19                	jne    f0100f69 <mem_init+0x1cf>
f0100f50:	68 33 2c 10 f0       	push   $0xf0102c33
f0100f55:	68 62 2b 10 f0       	push   $0xf0102b62
f0100f5a:	68 1f 02 00 00       	push   $0x21f
f0100f5f:	68 3c 2b 10 f0       	push   $0xf0102b3c
f0100f64:	e8 22 f1 ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0100f69:	83 ec 0c             	sub    $0xc,%esp
f0100f6c:	6a 00                	push   $0x0
f0100f6e:	e8 7c fd ff ff       	call   f0100cef <page_alloc>
f0100f73:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100f76:	83 c4 10             	add    $0x10,%esp
f0100f79:	85 c0                	test   %eax,%eax
f0100f7b:	75 19                	jne    f0100f96 <mem_init+0x1fc>
f0100f7d:	68 49 2c 10 f0       	push   $0xf0102c49
f0100f82:	68 62 2b 10 f0       	push   $0xf0102b62
f0100f87:	68 20 02 00 00       	push   $0x220
f0100f8c:	68 3c 2b 10 f0       	push   $0xf0102b3c
f0100f91:	e8 f5 f0 ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0100f96:	39 f7                	cmp    %esi,%edi
f0100f98:	75 19                	jne    f0100fb3 <mem_init+0x219>
f0100f9a:	68 5f 2c 10 f0       	push   $0xf0102c5f
f0100f9f:	68 62 2b 10 f0       	push   $0xf0102b62
f0100fa4:	68 23 02 00 00       	push   $0x223
f0100fa9:	68 3c 2b 10 f0       	push   $0xf0102b3c
f0100fae:	e8 d8 f0 ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0100fb3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100fb6:	39 c7                	cmp    %eax,%edi
f0100fb8:	74 04                	je     f0100fbe <mem_init+0x224>
f0100fba:	39 c6                	cmp    %eax,%esi
f0100fbc:	75 19                	jne    f0100fd7 <mem_init+0x23d>
f0100fbe:	68 cc 2a 10 f0       	push   $0xf0102acc
f0100fc3:	68 62 2b 10 f0       	push   $0xf0102b62
f0100fc8:	68 24 02 00 00       	push   $0x224
f0100fcd:	68 3c 2b 10 f0       	push   $0xf0102b3c
f0100fd2:	e8 b4 f0 ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100fd7:	8b 0d 84 49 11 f0    	mov    0xf0114984,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0100fdd:	8b 15 7c 49 11 f0    	mov    0xf011497c,%edx
f0100fe3:	c1 e2 0c             	shl    $0xc,%edx
f0100fe6:	89 f8                	mov    %edi,%eax
f0100fe8:	29 c8                	sub    %ecx,%eax
f0100fea:	c1 f8 03             	sar    $0x3,%eax
f0100fed:	c1 e0 0c             	shl    $0xc,%eax
f0100ff0:	39 d0                	cmp    %edx,%eax
f0100ff2:	72 19                	jb     f010100d <mem_init+0x273>
f0100ff4:	68 71 2c 10 f0       	push   $0xf0102c71
f0100ff9:	68 62 2b 10 f0       	push   $0xf0102b62
f0100ffe:	68 25 02 00 00       	push   $0x225
f0101003:	68 3c 2b 10 f0       	push   $0xf0102b3c
f0101008:	e8 7e f0 ff ff       	call   f010008b <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f010100d:	89 f0                	mov    %esi,%eax
f010100f:	29 c8                	sub    %ecx,%eax
f0101011:	c1 f8 03             	sar    $0x3,%eax
f0101014:	c1 e0 0c             	shl    $0xc,%eax
f0101017:	39 c2                	cmp    %eax,%edx
f0101019:	77 19                	ja     f0101034 <mem_init+0x29a>
f010101b:	68 8e 2c 10 f0       	push   $0xf0102c8e
f0101020:	68 62 2b 10 f0       	push   $0xf0102b62
f0101025:	68 26 02 00 00       	push   $0x226
f010102a:	68 3c 2b 10 f0       	push   $0xf0102b3c
f010102f:	e8 57 f0 ff ff       	call   f010008b <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f0101034:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101037:	29 c8                	sub    %ecx,%eax
f0101039:	c1 f8 03             	sar    $0x3,%eax
f010103c:	c1 e0 0c             	shl    $0xc,%eax
f010103f:	39 c2                	cmp    %eax,%edx
f0101041:	77 19                	ja     f010105c <mem_init+0x2c2>
f0101043:	68 ab 2c 10 f0       	push   $0xf0102cab
f0101048:	68 62 2b 10 f0       	push   $0xf0102b62
f010104d:	68 27 02 00 00       	push   $0x227
f0101052:	68 3c 2b 10 f0       	push   $0xf0102b3c
f0101057:	e8 2f f0 ff ff       	call   f010008b <_panic>
	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010105c:	a1 3c 45 11 f0       	mov    0xf011453c,%eax
f0101061:	89 45 e0             	mov    %eax,-0x20(%ebp)
	page_free_list = 0;
f0101064:	c7 05 3c 45 11 f0 00 	movl   $0x0,0xf011453c
f010106b:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010106e:	83 ec 0c             	sub    $0xc,%esp
f0101071:	6a 00                	push   $0x0
f0101073:	e8 77 fc ff ff       	call   f0100cef <page_alloc>
f0101078:	83 c4 10             	add    $0x10,%esp
f010107b:	85 c0                	test   %eax,%eax
f010107d:	74 19                	je     f0101098 <mem_init+0x2fe>
f010107f:	68 c8 2c 10 f0       	push   $0xf0102cc8
f0101084:	68 62 2b 10 f0       	push   $0xf0102b62
f0101089:	68 2d 02 00 00       	push   $0x22d
f010108e:	68 3c 2b 10 f0       	push   $0xf0102b3c
f0101093:	e8 f3 ef ff ff       	call   f010008b <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101098:	83 ec 0c             	sub    $0xc,%esp
f010109b:	57                   	push   %edi
f010109c:	e8 be fc ff ff       	call   f0100d5f <page_free>
	page_free(pp1);
f01010a1:	89 34 24             	mov    %esi,(%esp)
f01010a4:	e8 b6 fc ff ff       	call   f0100d5f <page_free>
	page_free(pp2);
f01010a9:	83 c4 04             	add    $0x4,%esp
f01010ac:	ff 75 e4             	pushl  -0x1c(%ebp)
f01010af:	e8 ab fc ff ff       	call   f0100d5f <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01010b4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01010bb:	e8 2f fc ff ff       	call   f0100cef <page_alloc>
f01010c0:	89 c6                	mov    %eax,%esi
f01010c2:	83 c4 10             	add    $0x10,%esp
f01010c5:	85 c0                	test   %eax,%eax
f01010c7:	75 19                	jne    f01010e2 <mem_init+0x348>
f01010c9:	68 1d 2c 10 f0       	push   $0xf0102c1d
f01010ce:	68 62 2b 10 f0       	push   $0xf0102b62
f01010d3:	68 34 02 00 00       	push   $0x234
f01010d8:	68 3c 2b 10 f0       	push   $0xf0102b3c
f01010dd:	e8 a9 ef ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01010e2:	83 ec 0c             	sub    $0xc,%esp
f01010e5:	6a 00                	push   $0x0
f01010e7:	e8 03 fc ff ff       	call   f0100cef <page_alloc>
f01010ec:	89 c7                	mov    %eax,%edi
f01010ee:	83 c4 10             	add    $0x10,%esp
f01010f1:	85 c0                	test   %eax,%eax
f01010f3:	75 19                	jne    f010110e <mem_init+0x374>
f01010f5:	68 33 2c 10 f0       	push   $0xf0102c33
f01010fa:	68 62 2b 10 f0       	push   $0xf0102b62
f01010ff:	68 35 02 00 00       	push   $0x235
f0101104:	68 3c 2b 10 f0       	push   $0xf0102b3c
f0101109:	e8 7d ef ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f010110e:	83 ec 0c             	sub    $0xc,%esp
f0101111:	6a 00                	push   $0x0
f0101113:	e8 d7 fb ff ff       	call   f0100cef <page_alloc>
f0101118:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010111b:	83 c4 10             	add    $0x10,%esp
f010111e:	85 c0                	test   %eax,%eax
f0101120:	75 19                	jne    f010113b <mem_init+0x3a1>
f0101122:	68 49 2c 10 f0       	push   $0xf0102c49
f0101127:	68 62 2b 10 f0       	push   $0xf0102b62
f010112c:	68 36 02 00 00       	push   $0x236
f0101131:	68 3c 2b 10 f0       	push   $0xf0102b3c
f0101136:	e8 50 ef ff ff       	call   f010008b <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010113b:	39 fe                	cmp    %edi,%esi
f010113d:	75 19                	jne    f0101158 <mem_init+0x3be>
f010113f:	68 5f 2c 10 f0       	push   $0xf0102c5f
f0101144:	68 62 2b 10 f0       	push   $0xf0102b62
f0101149:	68 38 02 00 00       	push   $0x238
f010114e:	68 3c 2b 10 f0       	push   $0xf0102b3c
f0101153:	e8 33 ef ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101158:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010115b:	39 c7                	cmp    %eax,%edi
f010115d:	74 04                	je     f0101163 <mem_init+0x3c9>
f010115f:	39 c6                	cmp    %eax,%esi
f0101161:	75 19                	jne    f010117c <mem_init+0x3e2>
f0101163:	68 cc 2a 10 f0       	push   $0xf0102acc
f0101168:	68 62 2b 10 f0       	push   $0xf0102b62
f010116d:	68 39 02 00 00       	push   $0x239
f0101172:	68 3c 2b 10 f0       	push   $0xf0102b3c
f0101177:	e8 0f ef ff ff       	call   f010008b <_panic>
	assert(!page_alloc(0));
f010117c:	83 ec 0c             	sub    $0xc,%esp
f010117f:	6a 00                	push   $0x0
f0101181:	e8 69 fb ff ff       	call   f0100cef <page_alloc>
f0101186:	83 c4 10             	add    $0x10,%esp
f0101189:	85 c0                	test   %eax,%eax
f010118b:	74 19                	je     f01011a6 <mem_init+0x40c>
f010118d:	68 c8 2c 10 f0       	push   $0xf0102cc8
f0101192:	68 62 2b 10 f0       	push   $0xf0102b62
f0101197:	68 3a 02 00 00       	push   $0x23a
f010119c:	68 3c 2b 10 f0       	push   $0xf0102b3c
f01011a1:	e8 e5 ee ff ff       	call   f010008b <_panic>
f01011a6:	89 f0                	mov    %esi,%eax
f01011a8:	2b 05 84 49 11 f0    	sub    0xf0114984,%eax
f01011ae:	c1 f8 03             	sar    $0x3,%eax
f01011b1:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01011b4:	89 c2                	mov    %eax,%edx
f01011b6:	c1 ea 0c             	shr    $0xc,%edx
f01011b9:	3b 15 7c 49 11 f0    	cmp    0xf011497c,%edx
f01011bf:	72 12                	jb     f01011d3 <mem_init+0x439>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01011c1:	50                   	push   %eax
f01011c2:	68 84 29 10 f0       	push   $0xf0102984
f01011c7:	6a 52                	push   $0x52
f01011c9:	68 48 2b 10 f0       	push   $0xf0102b48
f01011ce:	e8 b8 ee ff ff       	call   f010008b <_panic>
	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f01011d3:	83 ec 04             	sub    $0x4,%esp
f01011d6:	68 00 10 00 00       	push   $0x1000
f01011db:	6a 01                	push   $0x1
f01011dd:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01011e2:	50                   	push   %eax
f01011e3:	e8 bf 0d 00 00       	call   f0101fa7 <memset>
	page_free(pp0);
f01011e8:	89 34 24             	mov    %esi,(%esp)
f01011eb:	e8 6f fb ff ff       	call   f0100d5f <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01011f0:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01011f7:	e8 f3 fa ff ff       	call   f0100cef <page_alloc>
f01011fc:	83 c4 10             	add    $0x10,%esp
f01011ff:	85 c0                	test   %eax,%eax
f0101201:	75 19                	jne    f010121c <mem_init+0x482>
f0101203:	68 d7 2c 10 f0       	push   $0xf0102cd7
f0101208:	68 62 2b 10 f0       	push   $0xf0102b62
f010120d:	68 3e 02 00 00       	push   $0x23e
f0101212:	68 3c 2b 10 f0       	push   $0xf0102b3c
f0101217:	e8 6f ee ff ff       	call   f010008b <_panic>
	assert(pp && pp0 == pp);
f010121c:	39 c6                	cmp    %eax,%esi
f010121e:	74 19                	je     f0101239 <mem_init+0x49f>
f0101220:	68 f5 2c 10 f0       	push   $0xf0102cf5
f0101225:	68 62 2b 10 f0       	push   $0xf0102b62
f010122a:	68 3f 02 00 00       	push   $0x23f
f010122f:	68 3c 2b 10 f0       	push   $0xf0102b3c
f0101234:	e8 52 ee ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101239:	89 f0                	mov    %esi,%eax
f010123b:	2b 05 84 49 11 f0    	sub    0xf0114984,%eax
f0101241:	c1 f8 03             	sar    $0x3,%eax
f0101244:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101247:	89 c2                	mov    %eax,%edx
f0101249:	c1 ea 0c             	shr    $0xc,%edx
f010124c:	3b 15 7c 49 11 f0    	cmp    0xf011497c,%edx
f0101252:	72 12                	jb     f0101266 <mem_init+0x4cc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101254:	50                   	push   %eax
f0101255:	68 84 29 10 f0       	push   $0xf0102984
f010125a:	6a 52                	push   $0x52
f010125c:	68 48 2b 10 f0       	push   $0xf0102b48
f0101261:	e8 25 ee ff ff       	call   f010008b <_panic>
f0101266:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f010126c:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101272:	80 38 00             	cmpb   $0x0,(%eax)
f0101275:	74 19                	je     f0101290 <mem_init+0x4f6>
f0101277:	68 05 2d 10 f0       	push   $0xf0102d05
f010127c:	68 62 2b 10 f0       	push   $0xf0102b62
f0101281:	68 42 02 00 00       	push   $0x242
f0101286:	68 3c 2b 10 f0       	push   $0xf0102b3c
f010128b:	e8 fb ed ff ff       	call   f010008b <_panic>
f0101290:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101293:	39 d0                	cmp    %edx,%eax
f0101295:	75 db                	jne    f0101272 <mem_init+0x4d8>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101297:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010129a:	a3 3c 45 11 f0       	mov    %eax,0xf011453c

	// free the pages we took
	page_free(pp0);
f010129f:	83 ec 0c             	sub    $0xc,%esp
f01012a2:	56                   	push   %esi
f01012a3:	e8 b7 fa ff ff       	call   f0100d5f <page_free>
	page_free(pp1);
f01012a8:	89 3c 24             	mov    %edi,(%esp)
f01012ab:	e8 af fa ff ff       	call   f0100d5f <page_free>
	page_free(pp2);
f01012b0:	83 c4 04             	add    $0x4,%esp
f01012b3:	ff 75 e4             	pushl  -0x1c(%ebp)
f01012b6:	e8 a4 fa ff ff       	call   f0100d5f <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01012bb:	a1 3c 45 11 f0       	mov    0xf011453c,%eax
f01012c0:	83 c4 10             	add    $0x10,%esp
f01012c3:	eb 05                	jmp    f01012ca <mem_init+0x530>
		--nfree;
f01012c5:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01012c8:	8b 00                	mov    (%eax),%eax
f01012ca:	85 c0                	test   %eax,%eax
f01012cc:	75 f7                	jne    f01012c5 <mem_init+0x52b>
		--nfree;
	assert(nfree == 0);
f01012ce:	85 db                	test   %ebx,%ebx
f01012d0:	74 19                	je     f01012eb <mem_init+0x551>
f01012d2:	68 0f 2d 10 f0       	push   $0xf0102d0f
f01012d7:	68 62 2b 10 f0       	push   $0xf0102b62
f01012dc:	68 4f 02 00 00       	push   $0x24f
f01012e1:	68 3c 2b 10 f0       	push   $0xf0102b3c
f01012e6:	e8 a0 ed ff ff       	call   f010008b <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01012eb:	83 ec 0c             	sub    $0xc,%esp
f01012ee:	68 ec 2a 10 f0       	push   $0xf0102aec
f01012f3:	e8 cb 01 00 00       	call   f01014c3 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01012f8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01012ff:	e8 eb f9 ff ff       	call   f0100cef <page_alloc>
f0101304:	89 c3                	mov    %eax,%ebx
f0101306:	83 c4 10             	add    $0x10,%esp
f0101309:	85 c0                	test   %eax,%eax
f010130b:	75 19                	jne    f0101326 <mem_init+0x58c>
f010130d:	68 1d 2c 10 f0       	push   $0xf0102c1d
f0101312:	68 62 2b 10 f0       	push   $0xf0102b62
f0101317:	68 a8 02 00 00       	push   $0x2a8
f010131c:	68 3c 2b 10 f0       	push   $0xf0102b3c
f0101321:	e8 65 ed ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0101326:	83 ec 0c             	sub    $0xc,%esp
f0101329:	6a 00                	push   $0x0
f010132b:	e8 bf f9 ff ff       	call   f0100cef <page_alloc>
f0101330:	89 c6                	mov    %eax,%esi
f0101332:	83 c4 10             	add    $0x10,%esp
f0101335:	85 c0                	test   %eax,%eax
f0101337:	75 19                	jne    f0101352 <mem_init+0x5b8>
f0101339:	68 33 2c 10 f0       	push   $0xf0102c33
f010133e:	68 62 2b 10 f0       	push   $0xf0102b62
f0101343:	68 a9 02 00 00       	push   $0x2a9
f0101348:	68 3c 2b 10 f0       	push   $0xf0102b3c
f010134d:	e8 39 ed ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101352:	83 ec 0c             	sub    $0xc,%esp
f0101355:	6a 00                	push   $0x0
f0101357:	e8 93 f9 ff ff       	call   f0100cef <page_alloc>
f010135c:	83 c4 10             	add    $0x10,%esp
f010135f:	85 c0                	test   %eax,%eax
f0101361:	75 19                	jne    f010137c <mem_init+0x5e2>
f0101363:	68 49 2c 10 f0       	push   $0xf0102c49
f0101368:	68 62 2b 10 f0       	push   $0xf0102b62
f010136d:	68 aa 02 00 00       	push   $0x2aa
f0101372:	68 3c 2b 10 f0       	push   $0xf0102b3c
f0101377:	e8 0f ed ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010137c:	39 f3                	cmp    %esi,%ebx
f010137e:	75 19                	jne    f0101399 <mem_init+0x5ff>
f0101380:	68 5f 2c 10 f0       	push   $0xf0102c5f
f0101385:	68 62 2b 10 f0       	push   $0xf0102b62
f010138a:	68 ad 02 00 00       	push   $0x2ad
f010138f:	68 3c 2b 10 f0       	push   $0xf0102b3c
f0101394:	e8 f2 ec ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101399:	39 c6                	cmp    %eax,%esi
f010139b:	74 04                	je     f01013a1 <mem_init+0x607>
f010139d:	39 c3                	cmp    %eax,%ebx
f010139f:	75 19                	jne    f01013ba <mem_init+0x620>
f01013a1:	68 cc 2a 10 f0       	push   $0xf0102acc
f01013a6:	68 62 2b 10 f0       	push   $0xf0102b62
f01013ab:	68 ae 02 00 00       	push   $0x2ae
f01013b0:	68 3c 2b 10 f0       	push   $0xf0102b3c
f01013b5:	e8 d1 ec ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
	page_free_list = 0;
f01013ba:	c7 05 3c 45 11 f0 00 	movl   $0x0,0xf011453c
f01013c1:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01013c4:	83 ec 0c             	sub    $0xc,%esp
f01013c7:	6a 00                	push   $0x0
f01013c9:	e8 21 f9 ff ff       	call   f0100cef <page_alloc>
f01013ce:	83 c4 10             	add    $0x10,%esp
f01013d1:	85 c0                	test   %eax,%eax
f01013d3:	74 19                	je     f01013ee <mem_init+0x654>
f01013d5:	68 c8 2c 10 f0       	push   $0xf0102cc8
f01013da:	68 62 2b 10 f0       	push   $0xf0102b62
f01013df:	68 b5 02 00 00       	push   $0x2b5
f01013e4:	68 3c 2b 10 f0       	push   $0xf0102b3c
f01013e9:	e8 9d ec ff ff       	call   f010008b <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01013ee:	68 0c 2b 10 f0       	push   $0xf0102b0c
f01013f3:	68 62 2b 10 f0       	push   $0xf0102b62
f01013f8:	68 bb 02 00 00       	push   $0x2bb
f01013fd:	68 3c 2b 10 f0       	push   $0xf0102b3c
f0101402:	e8 84 ec ff ff       	call   f010008b <_panic>

f0101407 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0101407:	55                   	push   %ebp
f0101408:	89 e5                	mov    %esp,%ebp
f010140a:	83 ec 08             	sub    $0x8,%esp
f010140d:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0101410:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0101414:	83 e8 01             	sub    $0x1,%eax
f0101417:	66 89 42 04          	mov    %ax,0x4(%edx)
f010141b:	66 85 c0             	test   %ax,%ax
f010141e:	75 0c                	jne    f010142c <page_decref+0x25>
		page_free(pp);
f0101420:	83 ec 0c             	sub    $0xc,%esp
f0101423:	52                   	push   %edx
f0101424:	e8 36 f9 ff ff       	call   f0100d5f <page_free>
f0101429:	83 c4 10             	add    $0x10,%esp
}
f010142c:	c9                   	leave  
f010142d:	c3                   	ret    

f010142e <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f010142e:	55                   	push   %ebp
f010142f:	89 e5                	mov    %esp,%ebp
	/*struct PageInfo *allocated;
	allocated = page_alloc(create);
	if(all)*/
	return NULL;
}
f0101431:	b8 00 00 00 00       	mov    $0x0,%eax
f0101436:	5d                   	pop    %ebp
f0101437:	c3                   	ret    

f0101438 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0101438:	55                   	push   %ebp
f0101439:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return 0;
}
f010143b:	b8 00 00 00 00       	mov    $0x0,%eax
f0101440:	5d                   	pop    %ebp
f0101441:	c3                   	ret    

f0101442 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0101442:	55                   	push   %ebp
f0101443:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f0101445:	b8 00 00 00 00       	mov    $0x0,%eax
f010144a:	5d                   	pop    %ebp
f010144b:	c3                   	ret    

f010144c <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f010144c:	55                   	push   %ebp
f010144d:	89 e5                	mov    %esp,%ebp
	// Fill this function in
}
f010144f:	5d                   	pop    %ebp
f0101450:	c3                   	ret    

f0101451 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0101451:	55                   	push   %ebp
f0101452:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101454:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101457:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f010145a:	5d                   	pop    %ebp
f010145b:	c3                   	ret    

f010145c <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f010145c:	55                   	push   %ebp
f010145d:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010145f:	ba 70 00 00 00       	mov    $0x70,%edx
f0101464:	8b 45 08             	mov    0x8(%ebp),%eax
f0101467:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0101468:	ba 71 00 00 00       	mov    $0x71,%edx
f010146d:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f010146e:	0f b6 c0             	movzbl %al,%eax
}
f0101471:	5d                   	pop    %ebp
f0101472:	c3                   	ret    

f0101473 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0101473:	55                   	push   %ebp
f0101474:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0101476:	ba 70 00 00 00       	mov    $0x70,%edx
f010147b:	8b 45 08             	mov    0x8(%ebp),%eax
f010147e:	ee                   	out    %al,(%dx)
f010147f:	ba 71 00 00 00       	mov    $0x71,%edx
f0101484:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101487:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0101488:	5d                   	pop    %ebp
f0101489:	c3                   	ret    

f010148a <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f010148a:	55                   	push   %ebp
f010148b:	89 e5                	mov    %esp,%ebp
f010148d:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0101490:	ff 75 08             	pushl  0x8(%ebp)
f0101493:	e8 5a f1 ff ff       	call   f01005f2 <cputchar>
	*cnt++;
}
f0101498:	83 c4 10             	add    $0x10,%esp
f010149b:	c9                   	leave  
f010149c:	c3                   	ret    

f010149d <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f010149d:	55                   	push   %ebp
f010149e:	89 e5                	mov    %esp,%ebp
f01014a0:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f01014a3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01014aa:	ff 75 0c             	pushl  0xc(%ebp)
f01014ad:	ff 75 08             	pushl  0x8(%ebp)
f01014b0:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01014b3:	50                   	push   %eax
f01014b4:	68 8a 14 10 f0       	push   $0xf010148a
f01014b9:	e8 5d 04 00 00       	call   f010191b <vprintfmt>
	return cnt;
}
f01014be:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01014c1:	c9                   	leave  
f01014c2:	c3                   	ret    

f01014c3 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01014c3:	55                   	push   %ebp
f01014c4:	89 e5                	mov    %esp,%ebp
f01014c6:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01014c9:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01014cc:	50                   	push   %eax
f01014cd:	ff 75 08             	pushl  0x8(%ebp)
f01014d0:	e8 c8 ff ff ff       	call   f010149d <vcprintf>
	va_end(ap);

	return cnt;
}
f01014d5:	c9                   	leave  
f01014d6:	c3                   	ret    

f01014d7 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01014d7:	55                   	push   %ebp
f01014d8:	89 e5                	mov    %esp,%ebp
f01014da:	57                   	push   %edi
f01014db:	56                   	push   %esi
f01014dc:	53                   	push   %ebx
f01014dd:	83 ec 14             	sub    $0x14,%esp
f01014e0:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01014e3:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01014e6:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01014e9:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01014ec:	8b 1a                	mov    (%edx),%ebx
f01014ee:	8b 01                	mov    (%ecx),%eax
f01014f0:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01014f3:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01014fa:	eb 7f                	jmp    f010157b <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f01014fc:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01014ff:	01 d8                	add    %ebx,%eax
f0101501:	89 c6                	mov    %eax,%esi
f0101503:	c1 ee 1f             	shr    $0x1f,%esi
f0101506:	01 c6                	add    %eax,%esi
f0101508:	d1 fe                	sar    %esi
f010150a:	8d 04 76             	lea    (%esi,%esi,2),%eax
f010150d:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0101510:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0101513:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0101515:	eb 03                	jmp    f010151a <stab_binsearch+0x43>
			m--;
f0101517:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010151a:	39 c3                	cmp    %eax,%ebx
f010151c:	7f 0d                	jg     f010152b <stab_binsearch+0x54>
f010151e:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0101522:	83 ea 0c             	sub    $0xc,%edx
f0101525:	39 f9                	cmp    %edi,%ecx
f0101527:	75 ee                	jne    f0101517 <stab_binsearch+0x40>
f0101529:	eb 05                	jmp    f0101530 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f010152b:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f010152e:	eb 4b                	jmp    f010157b <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0101530:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0101533:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0101536:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f010153a:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010153d:	76 11                	jbe    f0101550 <stab_binsearch+0x79>
			*region_left = m;
f010153f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0101542:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0101544:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0101547:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010154e:	eb 2b                	jmp    f010157b <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0101550:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0101553:	73 14                	jae    f0101569 <stab_binsearch+0x92>
			*region_right = m - 1;
f0101555:	83 e8 01             	sub    $0x1,%eax
f0101558:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010155b:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010155e:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0101560:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0101567:	eb 12                	jmp    f010157b <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0101569:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010156c:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f010156e:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0101572:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0101574:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f010157b:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f010157e:	0f 8e 78 ff ff ff    	jle    f01014fc <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0101584:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0101588:	75 0f                	jne    f0101599 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f010158a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010158d:	8b 00                	mov    (%eax),%eax
f010158f:	83 e8 01             	sub    $0x1,%eax
f0101592:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0101595:	89 06                	mov    %eax,(%esi)
f0101597:	eb 2c                	jmp    f01015c5 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0101599:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010159c:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f010159e:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01015a1:	8b 0e                	mov    (%esi),%ecx
f01015a3:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01015a6:	8b 75 ec             	mov    -0x14(%ebp),%esi
f01015a9:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01015ac:	eb 03                	jmp    f01015b1 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f01015ae:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01015b1:	39 c8                	cmp    %ecx,%eax
f01015b3:	7e 0b                	jle    f01015c0 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f01015b5:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f01015b9:	83 ea 0c             	sub    $0xc,%edx
f01015bc:	39 df                	cmp    %ebx,%edi
f01015be:	75 ee                	jne    f01015ae <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f01015c0:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01015c3:	89 06                	mov    %eax,(%esi)
	}
}
f01015c5:	83 c4 14             	add    $0x14,%esp
f01015c8:	5b                   	pop    %ebx
f01015c9:	5e                   	pop    %esi
f01015ca:	5f                   	pop    %edi
f01015cb:	5d                   	pop    %ebp
f01015cc:	c3                   	ret    

f01015cd <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01015cd:	55                   	push   %ebp
f01015ce:	89 e5                	mov    %esp,%ebp
f01015d0:	57                   	push   %edi
f01015d1:	56                   	push   %esi
f01015d2:	53                   	push   %ebx
f01015d3:	83 ec 3c             	sub    $0x3c,%esp
f01015d6:	8b 75 08             	mov    0x8(%ebp),%esi
f01015d9:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01015dc:	c7 03 1a 2d 10 f0    	movl   $0xf0102d1a,(%ebx)
	info->eip_line = 0;
f01015e2:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f01015e9:	c7 43 08 1a 2d 10 f0 	movl   $0xf0102d1a,0x8(%ebx)
	info->eip_fn_namelen = 9;
f01015f0:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f01015f7:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f01015fa:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0101601:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0101607:	76 11                	jbe    f010161a <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0101609:	b8 47 97 10 f0       	mov    $0xf0109747,%eax
f010160e:	3d 29 7a 10 f0       	cmp    $0xf0107a29,%eax
f0101613:	77 19                	ja     f010162e <debuginfo_eip+0x61>
f0101615:	e9 b5 01 00 00       	jmp    f01017cf <debuginfo_eip+0x202>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f010161a:	83 ec 04             	sub    $0x4,%esp
f010161d:	68 24 2d 10 f0       	push   $0xf0102d24
f0101622:	6a 7f                	push   $0x7f
f0101624:	68 31 2d 10 f0       	push   $0xf0102d31
f0101629:	e8 5d ea ff ff       	call   f010008b <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010162e:	80 3d 46 97 10 f0 00 	cmpb   $0x0,0xf0109746
f0101635:	0f 85 9b 01 00 00    	jne    f01017d6 <debuginfo_eip+0x209>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f010163b:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0101642:	b8 28 7a 10 f0       	mov    $0xf0107a28,%eax
f0101647:	2d 70 2f 10 f0       	sub    $0xf0102f70,%eax
f010164c:	c1 f8 02             	sar    $0x2,%eax
f010164f:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0101655:	83 e8 01             	sub    $0x1,%eax
f0101658:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f010165b:	83 ec 08             	sub    $0x8,%esp
f010165e:	56                   	push   %esi
f010165f:	6a 64                	push   $0x64
f0101661:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0101664:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0101667:	b8 70 2f 10 f0       	mov    $0xf0102f70,%eax
f010166c:	e8 66 fe ff ff       	call   f01014d7 <stab_binsearch>
	if (lfile == 0)
f0101671:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101674:	83 c4 10             	add    $0x10,%esp
f0101677:	85 c0                	test   %eax,%eax
f0101679:	0f 84 5e 01 00 00    	je     f01017dd <debuginfo_eip+0x210>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f010167f:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0101682:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101685:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0101688:	83 ec 08             	sub    $0x8,%esp
f010168b:	56                   	push   %esi
f010168c:	6a 24                	push   $0x24
f010168e:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0101691:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0101694:	b8 70 2f 10 f0       	mov    $0xf0102f70,%eax
f0101699:	e8 39 fe ff ff       	call   f01014d7 <stab_binsearch>

	if (lfun <= rfun) {
f010169e:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01016a1:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01016a4:	83 c4 10             	add    $0x10,%esp
f01016a7:	39 d0                	cmp    %edx,%eax
f01016a9:	7f 40                	jg     f01016eb <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01016ab:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f01016ae:	c1 e1 02             	shl    $0x2,%ecx
f01016b1:	8d b9 70 2f 10 f0    	lea    -0xfefd090(%ecx),%edi
f01016b7:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f01016ba:	8b b9 70 2f 10 f0    	mov    -0xfefd090(%ecx),%edi
f01016c0:	b9 47 97 10 f0       	mov    $0xf0109747,%ecx
f01016c5:	81 e9 29 7a 10 f0    	sub    $0xf0107a29,%ecx
f01016cb:	39 cf                	cmp    %ecx,%edi
f01016cd:	73 09                	jae    f01016d8 <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f01016cf:	81 c7 29 7a 10 f0    	add    $0xf0107a29,%edi
f01016d5:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f01016d8:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f01016db:	8b 4f 08             	mov    0x8(%edi),%ecx
f01016de:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f01016e1:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f01016e3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f01016e6:	89 55 d0             	mov    %edx,-0x30(%ebp)
f01016e9:	eb 0f                	jmp    f01016fa <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f01016eb:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f01016ee:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01016f1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f01016f4:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01016f7:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f01016fa:	83 ec 08             	sub    $0x8,%esp
f01016fd:	6a 3a                	push   $0x3a
f01016ff:	ff 73 08             	pushl  0x8(%ebx)
f0101702:	e8 84 08 00 00       	call   f0101f8b <strfind>
f0101707:	2b 43 08             	sub    0x8(%ebx),%eax
f010170a:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f010170d:	83 c4 08             	add    $0x8,%esp
f0101710:	56                   	push   %esi
f0101711:	6a 44                	push   $0x44
f0101713:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0101716:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0101719:	b8 70 2f 10 f0       	mov    $0xf0102f70,%eax
f010171e:	e8 b4 fd ff ff       	call   f01014d7 <stab_binsearch>
	if(lline <= rline)
f0101723:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101726:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0101729:	83 c4 10             	add    $0x10,%esp
f010172c:	39 d0                	cmp    %edx,%eax
f010172e:	0f 8f b0 00 00 00    	jg     f01017e4 <debuginfo_eip+0x217>
		info->eip_line = stabs[rline].n_desc;
f0101734:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0101737:	0f b7 14 95 76 2f 10 	movzwl -0xfefd08a(,%edx,4),%edx
f010173e:	f0 
f010173f:	89 53 04             	mov    %edx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0101742:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101745:	89 c2                	mov    %eax,%edx
f0101747:	8d 04 40             	lea    (%eax,%eax,2),%eax
f010174a:	8d 04 85 70 2f 10 f0 	lea    -0xfefd090(,%eax,4),%eax
f0101751:	eb 06                	jmp    f0101759 <debuginfo_eip+0x18c>
f0101753:	83 ea 01             	sub    $0x1,%edx
f0101756:	83 e8 0c             	sub    $0xc,%eax
f0101759:	39 d7                	cmp    %edx,%edi
f010175b:	7f 34                	jg     f0101791 <debuginfo_eip+0x1c4>
	       && stabs[lline].n_type != N_SOL
f010175d:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0101761:	80 f9 84             	cmp    $0x84,%cl
f0101764:	74 0b                	je     f0101771 <debuginfo_eip+0x1a4>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0101766:	80 f9 64             	cmp    $0x64,%cl
f0101769:	75 e8                	jne    f0101753 <debuginfo_eip+0x186>
f010176b:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f010176f:	74 e2                	je     f0101753 <debuginfo_eip+0x186>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0101771:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0101774:	8b 14 85 70 2f 10 f0 	mov    -0xfefd090(,%eax,4),%edx
f010177b:	b8 47 97 10 f0       	mov    $0xf0109747,%eax
f0101780:	2d 29 7a 10 f0       	sub    $0xf0107a29,%eax
f0101785:	39 c2                	cmp    %eax,%edx
f0101787:	73 08                	jae    f0101791 <debuginfo_eip+0x1c4>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0101789:	81 c2 29 7a 10 f0    	add    $0xf0107a29,%edx
f010178f:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0101791:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101794:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0101797:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f010179c:	39 f2                	cmp    %esi,%edx
f010179e:	7d 50                	jge    f01017f0 <debuginfo_eip+0x223>
		for (lline = lfun + 1;
f01017a0:	83 c2 01             	add    $0x1,%edx
f01017a3:	89 d0                	mov    %edx,%eax
f01017a5:	8d 14 52             	lea    (%edx,%edx,2),%edx
f01017a8:	8d 14 95 70 2f 10 f0 	lea    -0xfefd090(,%edx,4),%edx
f01017af:	eb 04                	jmp    f01017b5 <debuginfo_eip+0x1e8>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f01017b1:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f01017b5:	39 c6                	cmp    %eax,%esi
f01017b7:	7e 32                	jle    f01017eb <debuginfo_eip+0x21e>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01017b9:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01017bd:	83 c0 01             	add    $0x1,%eax
f01017c0:	83 c2 0c             	add    $0xc,%edx
f01017c3:	80 f9 a0             	cmp    $0xa0,%cl
f01017c6:	74 e9                	je     f01017b1 <debuginfo_eip+0x1e4>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01017c8:	b8 00 00 00 00       	mov    $0x0,%eax
f01017cd:	eb 21                	jmp    f01017f0 <debuginfo_eip+0x223>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f01017cf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01017d4:	eb 1a                	jmp    f01017f0 <debuginfo_eip+0x223>
f01017d6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01017db:	eb 13                	jmp    f01017f0 <debuginfo_eip+0x223>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f01017dd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01017e2:	eb 0c                	jmp    f01017f0 <debuginfo_eip+0x223>
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
	if(lline <= rline)
		info->eip_line = stabs[rline].n_desc;
	else
		return -1;
f01017e4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01017e9:	eb 05                	jmp    f01017f0 <debuginfo_eip+0x223>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01017eb:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01017f0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01017f3:	5b                   	pop    %ebx
f01017f4:	5e                   	pop    %esi
f01017f5:	5f                   	pop    %edi
f01017f6:	5d                   	pop    %ebp
f01017f7:	c3                   	ret    

f01017f8 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01017f8:	55                   	push   %ebp
f01017f9:	89 e5                	mov    %esp,%ebp
f01017fb:	57                   	push   %edi
f01017fc:	56                   	push   %esi
f01017fd:	53                   	push   %ebx
f01017fe:	83 ec 1c             	sub    $0x1c,%esp
f0101801:	89 c7                	mov    %eax,%edi
f0101803:	89 d6                	mov    %edx,%esi
f0101805:	8b 45 08             	mov    0x8(%ebp),%eax
f0101808:	8b 55 0c             	mov    0xc(%ebp),%edx
f010180b:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010180e:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0101811:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0101814:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101819:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010181c:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f010181f:	39 d3                	cmp    %edx,%ebx
f0101821:	72 05                	jb     f0101828 <printnum+0x30>
f0101823:	39 45 10             	cmp    %eax,0x10(%ebp)
f0101826:	77 45                	ja     f010186d <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0101828:	83 ec 0c             	sub    $0xc,%esp
f010182b:	ff 75 18             	pushl  0x18(%ebp)
f010182e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101831:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0101834:	53                   	push   %ebx
f0101835:	ff 75 10             	pushl  0x10(%ebp)
f0101838:	83 ec 08             	sub    $0x8,%esp
f010183b:	ff 75 e4             	pushl  -0x1c(%ebp)
f010183e:	ff 75 e0             	pushl  -0x20(%ebp)
f0101841:	ff 75 dc             	pushl  -0x24(%ebp)
f0101844:	ff 75 d8             	pushl  -0x28(%ebp)
f0101847:	e8 64 09 00 00       	call   f01021b0 <__udivdi3>
f010184c:	83 c4 18             	add    $0x18,%esp
f010184f:	52                   	push   %edx
f0101850:	50                   	push   %eax
f0101851:	89 f2                	mov    %esi,%edx
f0101853:	89 f8                	mov    %edi,%eax
f0101855:	e8 9e ff ff ff       	call   f01017f8 <printnum>
f010185a:	83 c4 20             	add    $0x20,%esp
f010185d:	eb 18                	jmp    f0101877 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f010185f:	83 ec 08             	sub    $0x8,%esp
f0101862:	56                   	push   %esi
f0101863:	ff 75 18             	pushl  0x18(%ebp)
f0101866:	ff d7                	call   *%edi
f0101868:	83 c4 10             	add    $0x10,%esp
f010186b:	eb 03                	jmp    f0101870 <printnum+0x78>
f010186d:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0101870:	83 eb 01             	sub    $0x1,%ebx
f0101873:	85 db                	test   %ebx,%ebx
f0101875:	7f e8                	jg     f010185f <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0101877:	83 ec 08             	sub    $0x8,%esp
f010187a:	56                   	push   %esi
f010187b:	83 ec 04             	sub    $0x4,%esp
f010187e:	ff 75 e4             	pushl  -0x1c(%ebp)
f0101881:	ff 75 e0             	pushl  -0x20(%ebp)
f0101884:	ff 75 dc             	pushl  -0x24(%ebp)
f0101887:	ff 75 d8             	pushl  -0x28(%ebp)
f010188a:	e8 51 0a 00 00       	call   f01022e0 <__umoddi3>
f010188f:	83 c4 14             	add    $0x14,%esp
f0101892:	0f be 80 3f 2d 10 f0 	movsbl -0xfefd2c1(%eax),%eax
f0101899:	50                   	push   %eax
f010189a:	ff d7                	call   *%edi
}
f010189c:	83 c4 10             	add    $0x10,%esp
f010189f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01018a2:	5b                   	pop    %ebx
f01018a3:	5e                   	pop    %esi
f01018a4:	5f                   	pop    %edi
f01018a5:	5d                   	pop    %ebp
f01018a6:	c3                   	ret    

f01018a7 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f01018a7:	55                   	push   %ebp
f01018a8:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f01018aa:	83 fa 01             	cmp    $0x1,%edx
f01018ad:	7e 0e                	jle    f01018bd <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f01018af:	8b 10                	mov    (%eax),%edx
f01018b1:	8d 4a 08             	lea    0x8(%edx),%ecx
f01018b4:	89 08                	mov    %ecx,(%eax)
f01018b6:	8b 02                	mov    (%edx),%eax
f01018b8:	8b 52 04             	mov    0x4(%edx),%edx
f01018bb:	eb 22                	jmp    f01018df <getuint+0x38>
	else if (lflag)
f01018bd:	85 d2                	test   %edx,%edx
f01018bf:	74 10                	je     f01018d1 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f01018c1:	8b 10                	mov    (%eax),%edx
f01018c3:	8d 4a 04             	lea    0x4(%edx),%ecx
f01018c6:	89 08                	mov    %ecx,(%eax)
f01018c8:	8b 02                	mov    (%edx),%eax
f01018ca:	ba 00 00 00 00       	mov    $0x0,%edx
f01018cf:	eb 0e                	jmp    f01018df <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f01018d1:	8b 10                	mov    (%eax),%edx
f01018d3:	8d 4a 04             	lea    0x4(%edx),%ecx
f01018d6:	89 08                	mov    %ecx,(%eax)
f01018d8:	8b 02                	mov    (%edx),%eax
f01018da:	ba 00 00 00 00       	mov    $0x0,%edx
}
f01018df:	5d                   	pop    %ebp
f01018e0:	c3                   	ret    

f01018e1 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01018e1:	55                   	push   %ebp
f01018e2:	89 e5                	mov    %esp,%ebp
f01018e4:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f01018e7:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f01018eb:	8b 10                	mov    (%eax),%edx
f01018ed:	3b 50 04             	cmp    0x4(%eax),%edx
f01018f0:	73 0a                	jae    f01018fc <sprintputch+0x1b>
		*b->buf++ = ch;
f01018f2:	8d 4a 01             	lea    0x1(%edx),%ecx
f01018f5:	89 08                	mov    %ecx,(%eax)
f01018f7:	8b 45 08             	mov    0x8(%ebp),%eax
f01018fa:	88 02                	mov    %al,(%edx)
}
f01018fc:	5d                   	pop    %ebp
f01018fd:	c3                   	ret    

f01018fe <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f01018fe:	55                   	push   %ebp
f01018ff:	89 e5                	mov    %esp,%ebp
f0101901:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0101904:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0101907:	50                   	push   %eax
f0101908:	ff 75 10             	pushl  0x10(%ebp)
f010190b:	ff 75 0c             	pushl  0xc(%ebp)
f010190e:	ff 75 08             	pushl  0x8(%ebp)
f0101911:	e8 05 00 00 00       	call   f010191b <vprintfmt>
	va_end(ap);
}
f0101916:	83 c4 10             	add    $0x10,%esp
f0101919:	c9                   	leave  
f010191a:	c3                   	ret    

f010191b <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f010191b:	55                   	push   %ebp
f010191c:	89 e5                	mov    %esp,%ebp
f010191e:	57                   	push   %edi
f010191f:	56                   	push   %esi
f0101920:	53                   	push   %ebx
f0101921:	83 ec 2c             	sub    $0x2c,%esp
f0101924:	8b 75 08             	mov    0x8(%ebp),%esi
f0101927:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010192a:	8b 7d 10             	mov    0x10(%ebp),%edi
f010192d:	eb 12                	jmp    f0101941 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f010192f:	85 c0                	test   %eax,%eax
f0101931:	0f 84 a9 03 00 00    	je     f0101ce0 <vprintfmt+0x3c5>
				return;
			putch(ch, putdat);
f0101937:	83 ec 08             	sub    $0x8,%esp
f010193a:	53                   	push   %ebx
f010193b:	50                   	push   %eax
f010193c:	ff d6                	call   *%esi
f010193e:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0101941:	83 c7 01             	add    $0x1,%edi
f0101944:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0101948:	83 f8 25             	cmp    $0x25,%eax
f010194b:	75 e2                	jne    f010192f <vprintfmt+0x14>
f010194d:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0101951:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0101958:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f010195f:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0101966:	ba 00 00 00 00       	mov    $0x0,%edx
f010196b:	eb 07                	jmp    f0101974 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010196d:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0101970:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101974:	8d 47 01             	lea    0x1(%edi),%eax
f0101977:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010197a:	0f b6 07             	movzbl (%edi),%eax
f010197d:	0f b6 c8             	movzbl %al,%ecx
f0101980:	83 e8 23             	sub    $0x23,%eax
f0101983:	3c 55                	cmp    $0x55,%al
f0101985:	0f 87 3a 03 00 00    	ja     f0101cc5 <vprintfmt+0x3aa>
f010198b:	0f b6 c0             	movzbl %al,%eax
f010198e:	ff 24 85 e0 2d 10 f0 	jmp    *-0xfefd220(,%eax,4)
f0101995:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0101998:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f010199c:	eb d6                	jmp    f0101974 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010199e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01019a1:	b8 00 00 00 00       	mov    $0x0,%eax
f01019a6:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f01019a9:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01019ac:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f01019b0:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f01019b3:	8d 51 d0             	lea    -0x30(%ecx),%edx
f01019b6:	83 fa 09             	cmp    $0x9,%edx
f01019b9:	77 39                	ja     f01019f4 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f01019bb:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f01019be:	eb e9                	jmp    f01019a9 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f01019c0:	8b 45 14             	mov    0x14(%ebp),%eax
f01019c3:	8d 48 04             	lea    0x4(%eax),%ecx
f01019c6:	89 4d 14             	mov    %ecx,0x14(%ebp)
f01019c9:	8b 00                	mov    (%eax),%eax
f01019cb:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01019ce:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f01019d1:	eb 27                	jmp    f01019fa <vprintfmt+0xdf>
f01019d3:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01019d6:	85 c0                	test   %eax,%eax
f01019d8:	b9 00 00 00 00       	mov    $0x0,%ecx
f01019dd:	0f 49 c8             	cmovns %eax,%ecx
f01019e0:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01019e3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01019e6:	eb 8c                	jmp    f0101974 <vprintfmt+0x59>
f01019e8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f01019eb:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f01019f2:	eb 80                	jmp    f0101974 <vprintfmt+0x59>
f01019f4:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01019f7:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f01019fa:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01019fe:	0f 89 70 ff ff ff    	jns    f0101974 <vprintfmt+0x59>
				width = precision, precision = -1;
f0101a04:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101a07:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101a0a:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0101a11:	e9 5e ff ff ff       	jmp    f0101974 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0101a16:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101a19:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0101a1c:	e9 53 ff ff ff       	jmp    f0101974 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0101a21:	8b 45 14             	mov    0x14(%ebp),%eax
f0101a24:	8d 50 04             	lea    0x4(%eax),%edx
f0101a27:	89 55 14             	mov    %edx,0x14(%ebp)
f0101a2a:	83 ec 08             	sub    $0x8,%esp
f0101a2d:	53                   	push   %ebx
f0101a2e:	ff 30                	pushl  (%eax)
f0101a30:	ff d6                	call   *%esi
			break;
f0101a32:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101a35:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0101a38:	e9 04 ff ff ff       	jmp    f0101941 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0101a3d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101a40:	8d 50 04             	lea    0x4(%eax),%edx
f0101a43:	89 55 14             	mov    %edx,0x14(%ebp)
f0101a46:	8b 00                	mov    (%eax),%eax
f0101a48:	99                   	cltd   
f0101a49:	31 d0                	xor    %edx,%eax
f0101a4b:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0101a4d:	83 f8 07             	cmp    $0x7,%eax
f0101a50:	7f 0b                	jg     f0101a5d <vprintfmt+0x142>
f0101a52:	8b 14 85 40 2f 10 f0 	mov    -0xfefd0c0(,%eax,4),%edx
f0101a59:	85 d2                	test   %edx,%edx
f0101a5b:	75 18                	jne    f0101a75 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0101a5d:	50                   	push   %eax
f0101a5e:	68 57 2d 10 f0       	push   $0xf0102d57
f0101a63:	53                   	push   %ebx
f0101a64:	56                   	push   %esi
f0101a65:	e8 94 fe ff ff       	call   f01018fe <printfmt>
f0101a6a:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101a6d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0101a70:	e9 cc fe ff ff       	jmp    f0101941 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0101a75:	52                   	push   %edx
f0101a76:	68 74 2b 10 f0       	push   $0xf0102b74
f0101a7b:	53                   	push   %ebx
f0101a7c:	56                   	push   %esi
f0101a7d:	e8 7c fe ff ff       	call   f01018fe <printfmt>
f0101a82:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101a85:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101a88:	e9 b4 fe ff ff       	jmp    f0101941 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0101a8d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101a90:	8d 50 04             	lea    0x4(%eax),%edx
f0101a93:	89 55 14             	mov    %edx,0x14(%ebp)
f0101a96:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0101a98:	85 ff                	test   %edi,%edi
f0101a9a:	b8 50 2d 10 f0       	mov    $0xf0102d50,%eax
f0101a9f:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0101aa2:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0101aa6:	0f 8e 94 00 00 00    	jle    f0101b40 <vprintfmt+0x225>
f0101aac:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0101ab0:	0f 84 98 00 00 00    	je     f0101b4e <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0101ab6:	83 ec 08             	sub    $0x8,%esp
f0101ab9:	ff 75 d0             	pushl  -0x30(%ebp)
f0101abc:	57                   	push   %edi
f0101abd:	e8 7f 03 00 00       	call   f0101e41 <strnlen>
f0101ac2:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0101ac5:	29 c1                	sub    %eax,%ecx
f0101ac7:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0101aca:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0101acd:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0101ad1:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101ad4:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0101ad7:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101ad9:	eb 0f                	jmp    f0101aea <vprintfmt+0x1cf>
					putch(padc, putdat);
f0101adb:	83 ec 08             	sub    $0x8,%esp
f0101ade:	53                   	push   %ebx
f0101adf:	ff 75 e0             	pushl  -0x20(%ebp)
f0101ae2:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101ae4:	83 ef 01             	sub    $0x1,%edi
f0101ae7:	83 c4 10             	add    $0x10,%esp
f0101aea:	85 ff                	test   %edi,%edi
f0101aec:	7f ed                	jg     f0101adb <vprintfmt+0x1c0>
f0101aee:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101af1:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0101af4:	85 c9                	test   %ecx,%ecx
f0101af6:	b8 00 00 00 00       	mov    $0x0,%eax
f0101afb:	0f 49 c1             	cmovns %ecx,%eax
f0101afe:	29 c1                	sub    %eax,%ecx
f0101b00:	89 75 08             	mov    %esi,0x8(%ebp)
f0101b03:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101b06:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101b09:	89 cb                	mov    %ecx,%ebx
f0101b0b:	eb 4d                	jmp    f0101b5a <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0101b0d:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0101b11:	74 1b                	je     f0101b2e <vprintfmt+0x213>
f0101b13:	0f be c0             	movsbl %al,%eax
f0101b16:	83 e8 20             	sub    $0x20,%eax
f0101b19:	83 f8 5e             	cmp    $0x5e,%eax
f0101b1c:	76 10                	jbe    f0101b2e <vprintfmt+0x213>
					putch('?', putdat);
f0101b1e:	83 ec 08             	sub    $0x8,%esp
f0101b21:	ff 75 0c             	pushl  0xc(%ebp)
f0101b24:	6a 3f                	push   $0x3f
f0101b26:	ff 55 08             	call   *0x8(%ebp)
f0101b29:	83 c4 10             	add    $0x10,%esp
f0101b2c:	eb 0d                	jmp    f0101b3b <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0101b2e:	83 ec 08             	sub    $0x8,%esp
f0101b31:	ff 75 0c             	pushl  0xc(%ebp)
f0101b34:	52                   	push   %edx
f0101b35:	ff 55 08             	call   *0x8(%ebp)
f0101b38:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101b3b:	83 eb 01             	sub    $0x1,%ebx
f0101b3e:	eb 1a                	jmp    f0101b5a <vprintfmt+0x23f>
f0101b40:	89 75 08             	mov    %esi,0x8(%ebp)
f0101b43:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101b46:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101b49:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0101b4c:	eb 0c                	jmp    f0101b5a <vprintfmt+0x23f>
f0101b4e:	89 75 08             	mov    %esi,0x8(%ebp)
f0101b51:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101b54:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101b57:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0101b5a:	83 c7 01             	add    $0x1,%edi
f0101b5d:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0101b61:	0f be d0             	movsbl %al,%edx
f0101b64:	85 d2                	test   %edx,%edx
f0101b66:	74 23                	je     f0101b8b <vprintfmt+0x270>
f0101b68:	85 f6                	test   %esi,%esi
f0101b6a:	78 a1                	js     f0101b0d <vprintfmt+0x1f2>
f0101b6c:	83 ee 01             	sub    $0x1,%esi
f0101b6f:	79 9c                	jns    f0101b0d <vprintfmt+0x1f2>
f0101b71:	89 df                	mov    %ebx,%edi
f0101b73:	8b 75 08             	mov    0x8(%ebp),%esi
f0101b76:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101b79:	eb 18                	jmp    f0101b93 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0101b7b:	83 ec 08             	sub    $0x8,%esp
f0101b7e:	53                   	push   %ebx
f0101b7f:	6a 20                	push   $0x20
f0101b81:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101b83:	83 ef 01             	sub    $0x1,%edi
f0101b86:	83 c4 10             	add    $0x10,%esp
f0101b89:	eb 08                	jmp    f0101b93 <vprintfmt+0x278>
f0101b8b:	89 df                	mov    %ebx,%edi
f0101b8d:	8b 75 08             	mov    0x8(%ebp),%esi
f0101b90:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101b93:	85 ff                	test   %edi,%edi
f0101b95:	7f e4                	jg     f0101b7b <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101b97:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101b9a:	e9 a2 fd ff ff       	jmp    f0101941 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101b9f:	83 fa 01             	cmp    $0x1,%edx
f0101ba2:	7e 16                	jle    f0101bba <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0101ba4:	8b 45 14             	mov    0x14(%ebp),%eax
f0101ba7:	8d 50 08             	lea    0x8(%eax),%edx
f0101baa:	89 55 14             	mov    %edx,0x14(%ebp)
f0101bad:	8b 50 04             	mov    0x4(%eax),%edx
f0101bb0:	8b 00                	mov    (%eax),%eax
f0101bb2:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101bb5:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101bb8:	eb 32                	jmp    f0101bec <vprintfmt+0x2d1>
	else if (lflag)
f0101bba:	85 d2                	test   %edx,%edx
f0101bbc:	74 18                	je     f0101bd6 <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f0101bbe:	8b 45 14             	mov    0x14(%ebp),%eax
f0101bc1:	8d 50 04             	lea    0x4(%eax),%edx
f0101bc4:	89 55 14             	mov    %edx,0x14(%ebp)
f0101bc7:	8b 00                	mov    (%eax),%eax
f0101bc9:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101bcc:	89 c1                	mov    %eax,%ecx
f0101bce:	c1 f9 1f             	sar    $0x1f,%ecx
f0101bd1:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0101bd4:	eb 16                	jmp    f0101bec <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f0101bd6:	8b 45 14             	mov    0x14(%ebp),%eax
f0101bd9:	8d 50 04             	lea    0x4(%eax),%edx
f0101bdc:	89 55 14             	mov    %edx,0x14(%ebp)
f0101bdf:	8b 00                	mov    (%eax),%eax
f0101be1:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101be4:	89 c1                	mov    %eax,%ecx
f0101be6:	c1 f9 1f             	sar    $0x1f,%ecx
f0101be9:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0101bec:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101bef:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0101bf2:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0101bf7:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0101bfb:	0f 89 90 00 00 00    	jns    f0101c91 <vprintfmt+0x376>
				putch('-', putdat);
f0101c01:	83 ec 08             	sub    $0x8,%esp
f0101c04:	53                   	push   %ebx
f0101c05:	6a 2d                	push   $0x2d
f0101c07:	ff d6                	call   *%esi
				num = -(long long) num;
f0101c09:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101c0c:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101c0f:	f7 d8                	neg    %eax
f0101c11:	83 d2 00             	adc    $0x0,%edx
f0101c14:	f7 da                	neg    %edx
f0101c16:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0101c19:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0101c1e:	eb 71                	jmp    f0101c91 <vprintfmt+0x376>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0101c20:	8d 45 14             	lea    0x14(%ebp),%eax
f0101c23:	e8 7f fc ff ff       	call   f01018a7 <getuint>
			base = 10;
f0101c28:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0101c2d:	eb 62                	jmp    f0101c91 <vprintfmt+0x376>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f0101c2f:	8d 45 14             	lea    0x14(%ebp),%eax
f0101c32:	e8 70 fc ff ff       	call   f01018a7 <getuint>
			base = 8;
			printnum(putch, putdat, num, base, width, padc);
f0101c37:	83 ec 0c             	sub    $0xc,%esp
f0101c3a:	0f be 4d d4          	movsbl -0x2c(%ebp),%ecx
f0101c3e:	51                   	push   %ecx
f0101c3f:	ff 75 e0             	pushl  -0x20(%ebp)
f0101c42:	6a 08                	push   $0x8
f0101c44:	52                   	push   %edx
f0101c45:	50                   	push   %eax
f0101c46:	89 da                	mov    %ebx,%edx
f0101c48:	89 f0                	mov    %esi,%eax
f0101c4a:	e8 a9 fb ff ff       	call   f01017f8 <printnum>
			break;
f0101c4f:	83 c4 20             	add    $0x20,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101c52:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
			base = 8;
			printnum(putch, putdat, num, base, width, padc);
			break;
f0101c55:	e9 e7 fc ff ff       	jmp    f0101941 <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
f0101c5a:	83 ec 08             	sub    $0x8,%esp
f0101c5d:	53                   	push   %ebx
f0101c5e:	6a 30                	push   $0x30
f0101c60:	ff d6                	call   *%esi
			putch('x', putdat);
f0101c62:	83 c4 08             	add    $0x8,%esp
f0101c65:	53                   	push   %ebx
f0101c66:	6a 78                	push   $0x78
f0101c68:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0101c6a:	8b 45 14             	mov    0x14(%ebp),%eax
f0101c6d:	8d 50 04             	lea    0x4(%eax),%edx
f0101c70:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0101c73:	8b 00                	mov    (%eax),%eax
f0101c75:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0101c7a:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0101c7d:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0101c82:	eb 0d                	jmp    f0101c91 <vprintfmt+0x376>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0101c84:	8d 45 14             	lea    0x14(%ebp),%eax
f0101c87:	e8 1b fc ff ff       	call   f01018a7 <getuint>
			base = 16;
f0101c8c:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101c91:	83 ec 0c             	sub    $0xc,%esp
f0101c94:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0101c98:	57                   	push   %edi
f0101c99:	ff 75 e0             	pushl  -0x20(%ebp)
f0101c9c:	51                   	push   %ecx
f0101c9d:	52                   	push   %edx
f0101c9e:	50                   	push   %eax
f0101c9f:	89 da                	mov    %ebx,%edx
f0101ca1:	89 f0                	mov    %esi,%eax
f0101ca3:	e8 50 fb ff ff       	call   f01017f8 <printnum>
			break;
f0101ca8:	83 c4 20             	add    $0x20,%esp
f0101cab:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101cae:	e9 8e fc ff ff       	jmp    f0101941 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0101cb3:	83 ec 08             	sub    $0x8,%esp
f0101cb6:	53                   	push   %ebx
f0101cb7:	51                   	push   %ecx
f0101cb8:	ff d6                	call   *%esi
			break;
f0101cba:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101cbd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0101cc0:	e9 7c fc ff ff       	jmp    f0101941 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0101cc5:	83 ec 08             	sub    $0x8,%esp
f0101cc8:	53                   	push   %ebx
f0101cc9:	6a 25                	push   $0x25
f0101ccb:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101ccd:	83 c4 10             	add    $0x10,%esp
f0101cd0:	eb 03                	jmp    f0101cd5 <vprintfmt+0x3ba>
f0101cd2:	83 ef 01             	sub    $0x1,%edi
f0101cd5:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0101cd9:	75 f7                	jne    f0101cd2 <vprintfmt+0x3b7>
f0101cdb:	e9 61 fc ff ff       	jmp    f0101941 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0101ce0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101ce3:	5b                   	pop    %ebx
f0101ce4:	5e                   	pop    %esi
f0101ce5:	5f                   	pop    %edi
f0101ce6:	5d                   	pop    %ebp
f0101ce7:	c3                   	ret    

f0101ce8 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101ce8:	55                   	push   %ebp
f0101ce9:	89 e5                	mov    %esp,%ebp
f0101ceb:	83 ec 18             	sub    $0x18,%esp
f0101cee:	8b 45 08             	mov    0x8(%ebp),%eax
f0101cf1:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101cf4:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101cf7:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101cfb:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101cfe:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101d05:	85 c0                	test   %eax,%eax
f0101d07:	74 26                	je     f0101d2f <vsnprintf+0x47>
f0101d09:	85 d2                	test   %edx,%edx
f0101d0b:	7e 22                	jle    f0101d2f <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101d0d:	ff 75 14             	pushl  0x14(%ebp)
f0101d10:	ff 75 10             	pushl  0x10(%ebp)
f0101d13:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101d16:	50                   	push   %eax
f0101d17:	68 e1 18 10 f0       	push   $0xf01018e1
f0101d1c:	e8 fa fb ff ff       	call   f010191b <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101d21:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101d24:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101d27:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101d2a:	83 c4 10             	add    $0x10,%esp
f0101d2d:	eb 05                	jmp    f0101d34 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0101d2f:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0101d34:	c9                   	leave  
f0101d35:	c3                   	ret    

f0101d36 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0101d36:	55                   	push   %ebp
f0101d37:	89 e5                	mov    %esp,%ebp
f0101d39:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101d3c:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101d3f:	50                   	push   %eax
f0101d40:	ff 75 10             	pushl  0x10(%ebp)
f0101d43:	ff 75 0c             	pushl  0xc(%ebp)
f0101d46:	ff 75 08             	pushl  0x8(%ebp)
f0101d49:	e8 9a ff ff ff       	call   f0101ce8 <vsnprintf>
	va_end(ap);

	return rc;
}
f0101d4e:	c9                   	leave  
f0101d4f:	c3                   	ret    

f0101d50 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101d50:	55                   	push   %ebp
f0101d51:	89 e5                	mov    %esp,%ebp
f0101d53:	57                   	push   %edi
f0101d54:	56                   	push   %esi
f0101d55:	53                   	push   %ebx
f0101d56:	83 ec 0c             	sub    $0xc,%esp
f0101d59:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0101d5c:	85 c0                	test   %eax,%eax
f0101d5e:	74 11                	je     f0101d71 <readline+0x21>
		cprintf("%s", prompt);
f0101d60:	83 ec 08             	sub    $0x8,%esp
f0101d63:	50                   	push   %eax
f0101d64:	68 74 2b 10 f0       	push   $0xf0102b74
f0101d69:	e8 55 f7 ff ff       	call   f01014c3 <cprintf>
f0101d6e:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0101d71:	83 ec 0c             	sub    $0xc,%esp
f0101d74:	6a 00                	push   $0x0
f0101d76:	e8 98 e8 ff ff       	call   f0100613 <iscons>
f0101d7b:	89 c7                	mov    %eax,%edi
f0101d7d:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0101d80:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101d85:	e8 78 e8 ff ff       	call   f0100602 <getchar>
f0101d8a:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0101d8c:	85 c0                	test   %eax,%eax
f0101d8e:	79 18                	jns    f0101da8 <readline+0x58>
			cprintf("read error: %e\n", c);
f0101d90:	83 ec 08             	sub    $0x8,%esp
f0101d93:	50                   	push   %eax
f0101d94:	68 60 2f 10 f0       	push   $0xf0102f60
f0101d99:	e8 25 f7 ff ff       	call   f01014c3 <cprintf>
			return NULL;
f0101d9e:	83 c4 10             	add    $0x10,%esp
f0101da1:	b8 00 00 00 00       	mov    $0x0,%eax
f0101da6:	eb 79                	jmp    f0101e21 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101da8:	83 f8 08             	cmp    $0x8,%eax
f0101dab:	0f 94 c2             	sete   %dl
f0101dae:	83 f8 7f             	cmp    $0x7f,%eax
f0101db1:	0f 94 c0             	sete   %al
f0101db4:	08 c2                	or     %al,%dl
f0101db6:	74 1a                	je     f0101dd2 <readline+0x82>
f0101db8:	85 f6                	test   %esi,%esi
f0101dba:	7e 16                	jle    f0101dd2 <readline+0x82>
			if (echoing)
f0101dbc:	85 ff                	test   %edi,%edi
f0101dbe:	74 0d                	je     f0101dcd <readline+0x7d>
				cputchar('\b');
f0101dc0:	83 ec 0c             	sub    $0xc,%esp
f0101dc3:	6a 08                	push   $0x8
f0101dc5:	e8 28 e8 ff ff       	call   f01005f2 <cputchar>
f0101dca:	83 c4 10             	add    $0x10,%esp
			i--;
f0101dcd:	83 ee 01             	sub    $0x1,%esi
f0101dd0:	eb b3                	jmp    f0101d85 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101dd2:	83 fb 1f             	cmp    $0x1f,%ebx
f0101dd5:	7e 23                	jle    f0101dfa <readline+0xaa>
f0101dd7:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0101ddd:	7f 1b                	jg     f0101dfa <readline+0xaa>
			if (echoing)
f0101ddf:	85 ff                	test   %edi,%edi
f0101de1:	74 0c                	je     f0101def <readline+0x9f>
				cputchar(c);
f0101de3:	83 ec 0c             	sub    $0xc,%esp
f0101de6:	53                   	push   %ebx
f0101de7:	e8 06 e8 ff ff       	call   f01005f2 <cputchar>
f0101dec:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0101def:	88 9e 60 45 11 f0    	mov    %bl,-0xfeebaa0(%esi)
f0101df5:	8d 76 01             	lea    0x1(%esi),%esi
f0101df8:	eb 8b                	jmp    f0101d85 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0101dfa:	83 fb 0a             	cmp    $0xa,%ebx
f0101dfd:	74 05                	je     f0101e04 <readline+0xb4>
f0101dff:	83 fb 0d             	cmp    $0xd,%ebx
f0101e02:	75 81                	jne    f0101d85 <readline+0x35>
			if (echoing)
f0101e04:	85 ff                	test   %edi,%edi
f0101e06:	74 0d                	je     f0101e15 <readline+0xc5>
				cputchar('\n');
f0101e08:	83 ec 0c             	sub    $0xc,%esp
f0101e0b:	6a 0a                	push   $0xa
f0101e0d:	e8 e0 e7 ff ff       	call   f01005f2 <cputchar>
f0101e12:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0101e15:	c6 86 60 45 11 f0 00 	movb   $0x0,-0xfeebaa0(%esi)
			return buf;
f0101e1c:	b8 60 45 11 f0       	mov    $0xf0114560,%eax
		}
	}
}
f0101e21:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101e24:	5b                   	pop    %ebx
f0101e25:	5e                   	pop    %esi
f0101e26:	5f                   	pop    %edi
f0101e27:	5d                   	pop    %ebp
f0101e28:	c3                   	ret    

f0101e29 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101e29:	55                   	push   %ebp
f0101e2a:	89 e5                	mov    %esp,%ebp
f0101e2c:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101e2f:	b8 00 00 00 00       	mov    $0x0,%eax
f0101e34:	eb 03                	jmp    f0101e39 <strlen+0x10>
		n++;
f0101e36:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101e39:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101e3d:	75 f7                	jne    f0101e36 <strlen+0xd>
		n++;
	return n;
}
f0101e3f:	5d                   	pop    %ebp
f0101e40:	c3                   	ret    

f0101e41 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101e41:	55                   	push   %ebp
f0101e42:	89 e5                	mov    %esp,%ebp
f0101e44:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101e47:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101e4a:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e4f:	eb 03                	jmp    f0101e54 <strnlen+0x13>
		n++;
f0101e51:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101e54:	39 c2                	cmp    %eax,%edx
f0101e56:	74 08                	je     f0101e60 <strnlen+0x1f>
f0101e58:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0101e5c:	75 f3                	jne    f0101e51 <strnlen+0x10>
f0101e5e:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0101e60:	5d                   	pop    %ebp
f0101e61:	c3                   	ret    

f0101e62 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101e62:	55                   	push   %ebp
f0101e63:	89 e5                	mov    %esp,%ebp
f0101e65:	53                   	push   %ebx
f0101e66:	8b 45 08             	mov    0x8(%ebp),%eax
f0101e69:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101e6c:	89 c2                	mov    %eax,%edx
f0101e6e:	83 c2 01             	add    $0x1,%edx
f0101e71:	83 c1 01             	add    $0x1,%ecx
f0101e74:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0101e78:	88 5a ff             	mov    %bl,-0x1(%edx)
f0101e7b:	84 db                	test   %bl,%bl
f0101e7d:	75 ef                	jne    f0101e6e <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101e7f:	5b                   	pop    %ebx
f0101e80:	5d                   	pop    %ebp
f0101e81:	c3                   	ret    

f0101e82 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101e82:	55                   	push   %ebp
f0101e83:	89 e5                	mov    %esp,%ebp
f0101e85:	53                   	push   %ebx
f0101e86:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101e89:	53                   	push   %ebx
f0101e8a:	e8 9a ff ff ff       	call   f0101e29 <strlen>
f0101e8f:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0101e92:	ff 75 0c             	pushl  0xc(%ebp)
f0101e95:	01 d8                	add    %ebx,%eax
f0101e97:	50                   	push   %eax
f0101e98:	e8 c5 ff ff ff       	call   f0101e62 <strcpy>
	return dst;
}
f0101e9d:	89 d8                	mov    %ebx,%eax
f0101e9f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101ea2:	c9                   	leave  
f0101ea3:	c3                   	ret    

f0101ea4 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101ea4:	55                   	push   %ebp
f0101ea5:	89 e5                	mov    %esp,%ebp
f0101ea7:	56                   	push   %esi
f0101ea8:	53                   	push   %ebx
f0101ea9:	8b 75 08             	mov    0x8(%ebp),%esi
f0101eac:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101eaf:	89 f3                	mov    %esi,%ebx
f0101eb1:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101eb4:	89 f2                	mov    %esi,%edx
f0101eb6:	eb 0f                	jmp    f0101ec7 <strncpy+0x23>
		*dst++ = *src;
f0101eb8:	83 c2 01             	add    $0x1,%edx
f0101ebb:	0f b6 01             	movzbl (%ecx),%eax
f0101ebe:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101ec1:	80 39 01             	cmpb   $0x1,(%ecx)
f0101ec4:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101ec7:	39 da                	cmp    %ebx,%edx
f0101ec9:	75 ed                	jne    f0101eb8 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101ecb:	89 f0                	mov    %esi,%eax
f0101ecd:	5b                   	pop    %ebx
f0101ece:	5e                   	pop    %esi
f0101ecf:	5d                   	pop    %ebp
f0101ed0:	c3                   	ret    

f0101ed1 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101ed1:	55                   	push   %ebp
f0101ed2:	89 e5                	mov    %esp,%ebp
f0101ed4:	56                   	push   %esi
f0101ed5:	53                   	push   %ebx
f0101ed6:	8b 75 08             	mov    0x8(%ebp),%esi
f0101ed9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101edc:	8b 55 10             	mov    0x10(%ebp),%edx
f0101edf:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101ee1:	85 d2                	test   %edx,%edx
f0101ee3:	74 21                	je     f0101f06 <strlcpy+0x35>
f0101ee5:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0101ee9:	89 f2                	mov    %esi,%edx
f0101eeb:	eb 09                	jmp    f0101ef6 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101eed:	83 c2 01             	add    $0x1,%edx
f0101ef0:	83 c1 01             	add    $0x1,%ecx
f0101ef3:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101ef6:	39 c2                	cmp    %eax,%edx
f0101ef8:	74 09                	je     f0101f03 <strlcpy+0x32>
f0101efa:	0f b6 19             	movzbl (%ecx),%ebx
f0101efd:	84 db                	test   %bl,%bl
f0101eff:	75 ec                	jne    f0101eed <strlcpy+0x1c>
f0101f01:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0101f03:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0101f06:	29 f0                	sub    %esi,%eax
}
f0101f08:	5b                   	pop    %ebx
f0101f09:	5e                   	pop    %esi
f0101f0a:	5d                   	pop    %ebp
f0101f0b:	c3                   	ret    

f0101f0c <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101f0c:	55                   	push   %ebp
f0101f0d:	89 e5                	mov    %esp,%ebp
f0101f0f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101f12:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101f15:	eb 06                	jmp    f0101f1d <strcmp+0x11>
		p++, q++;
f0101f17:	83 c1 01             	add    $0x1,%ecx
f0101f1a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0101f1d:	0f b6 01             	movzbl (%ecx),%eax
f0101f20:	84 c0                	test   %al,%al
f0101f22:	74 04                	je     f0101f28 <strcmp+0x1c>
f0101f24:	3a 02                	cmp    (%edx),%al
f0101f26:	74 ef                	je     f0101f17 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101f28:	0f b6 c0             	movzbl %al,%eax
f0101f2b:	0f b6 12             	movzbl (%edx),%edx
f0101f2e:	29 d0                	sub    %edx,%eax
}
f0101f30:	5d                   	pop    %ebp
f0101f31:	c3                   	ret    

f0101f32 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101f32:	55                   	push   %ebp
f0101f33:	89 e5                	mov    %esp,%ebp
f0101f35:	53                   	push   %ebx
f0101f36:	8b 45 08             	mov    0x8(%ebp),%eax
f0101f39:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101f3c:	89 c3                	mov    %eax,%ebx
f0101f3e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0101f41:	eb 06                	jmp    f0101f49 <strncmp+0x17>
		n--, p++, q++;
f0101f43:	83 c0 01             	add    $0x1,%eax
f0101f46:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101f49:	39 d8                	cmp    %ebx,%eax
f0101f4b:	74 15                	je     f0101f62 <strncmp+0x30>
f0101f4d:	0f b6 08             	movzbl (%eax),%ecx
f0101f50:	84 c9                	test   %cl,%cl
f0101f52:	74 04                	je     f0101f58 <strncmp+0x26>
f0101f54:	3a 0a                	cmp    (%edx),%cl
f0101f56:	74 eb                	je     f0101f43 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101f58:	0f b6 00             	movzbl (%eax),%eax
f0101f5b:	0f b6 12             	movzbl (%edx),%edx
f0101f5e:	29 d0                	sub    %edx,%eax
f0101f60:	eb 05                	jmp    f0101f67 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101f62:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0101f67:	5b                   	pop    %ebx
f0101f68:	5d                   	pop    %ebp
f0101f69:	c3                   	ret    

f0101f6a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101f6a:	55                   	push   %ebp
f0101f6b:	89 e5                	mov    %esp,%ebp
f0101f6d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101f70:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101f74:	eb 07                	jmp    f0101f7d <strchr+0x13>
		if (*s == c)
f0101f76:	38 ca                	cmp    %cl,%dl
f0101f78:	74 0f                	je     f0101f89 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0101f7a:	83 c0 01             	add    $0x1,%eax
f0101f7d:	0f b6 10             	movzbl (%eax),%edx
f0101f80:	84 d2                	test   %dl,%dl
f0101f82:	75 f2                	jne    f0101f76 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0101f84:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101f89:	5d                   	pop    %ebp
f0101f8a:	c3                   	ret    

f0101f8b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101f8b:	55                   	push   %ebp
f0101f8c:	89 e5                	mov    %esp,%ebp
f0101f8e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101f91:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101f95:	eb 03                	jmp    f0101f9a <strfind+0xf>
f0101f97:	83 c0 01             	add    $0x1,%eax
f0101f9a:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0101f9d:	38 ca                	cmp    %cl,%dl
f0101f9f:	74 04                	je     f0101fa5 <strfind+0x1a>
f0101fa1:	84 d2                	test   %dl,%dl
f0101fa3:	75 f2                	jne    f0101f97 <strfind+0xc>
			break;
	return (char *) s;
}
f0101fa5:	5d                   	pop    %ebp
f0101fa6:	c3                   	ret    

f0101fa7 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101fa7:	55                   	push   %ebp
f0101fa8:	89 e5                	mov    %esp,%ebp
f0101faa:	57                   	push   %edi
f0101fab:	56                   	push   %esi
f0101fac:	53                   	push   %ebx
f0101fad:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101fb0:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101fb3:	85 c9                	test   %ecx,%ecx
f0101fb5:	74 36                	je     f0101fed <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101fb7:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101fbd:	75 28                	jne    f0101fe7 <memset+0x40>
f0101fbf:	f6 c1 03             	test   $0x3,%cl
f0101fc2:	75 23                	jne    f0101fe7 <memset+0x40>
		c &= 0xFF;
f0101fc4:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101fc8:	89 d3                	mov    %edx,%ebx
f0101fca:	c1 e3 08             	shl    $0x8,%ebx
f0101fcd:	89 d6                	mov    %edx,%esi
f0101fcf:	c1 e6 18             	shl    $0x18,%esi
f0101fd2:	89 d0                	mov    %edx,%eax
f0101fd4:	c1 e0 10             	shl    $0x10,%eax
f0101fd7:	09 f0                	or     %esi,%eax
f0101fd9:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0101fdb:	89 d8                	mov    %ebx,%eax
f0101fdd:	09 d0                	or     %edx,%eax
f0101fdf:	c1 e9 02             	shr    $0x2,%ecx
f0101fe2:	fc                   	cld    
f0101fe3:	f3 ab                	rep stos %eax,%es:(%edi)
f0101fe5:	eb 06                	jmp    f0101fed <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0101fe7:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101fea:	fc                   	cld    
f0101feb:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0101fed:	89 f8                	mov    %edi,%eax
f0101fef:	5b                   	pop    %ebx
f0101ff0:	5e                   	pop    %esi
f0101ff1:	5f                   	pop    %edi
f0101ff2:	5d                   	pop    %ebp
f0101ff3:	c3                   	ret    

f0101ff4 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101ff4:	55                   	push   %ebp
f0101ff5:	89 e5                	mov    %esp,%ebp
f0101ff7:	57                   	push   %edi
f0101ff8:	56                   	push   %esi
f0101ff9:	8b 45 08             	mov    0x8(%ebp),%eax
f0101ffc:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101fff:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0102002:	39 c6                	cmp    %eax,%esi
f0102004:	73 35                	jae    f010203b <memmove+0x47>
f0102006:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0102009:	39 d0                	cmp    %edx,%eax
f010200b:	73 2e                	jae    f010203b <memmove+0x47>
		s += n;
		d += n;
f010200d:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0102010:	89 d6                	mov    %edx,%esi
f0102012:	09 fe                	or     %edi,%esi
f0102014:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010201a:	75 13                	jne    f010202f <memmove+0x3b>
f010201c:	f6 c1 03             	test   $0x3,%cl
f010201f:	75 0e                	jne    f010202f <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0102021:	83 ef 04             	sub    $0x4,%edi
f0102024:	8d 72 fc             	lea    -0x4(%edx),%esi
f0102027:	c1 e9 02             	shr    $0x2,%ecx
f010202a:	fd                   	std    
f010202b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010202d:	eb 09                	jmp    f0102038 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f010202f:	83 ef 01             	sub    $0x1,%edi
f0102032:	8d 72 ff             	lea    -0x1(%edx),%esi
f0102035:	fd                   	std    
f0102036:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0102038:	fc                   	cld    
f0102039:	eb 1d                	jmp    f0102058 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010203b:	89 f2                	mov    %esi,%edx
f010203d:	09 c2                	or     %eax,%edx
f010203f:	f6 c2 03             	test   $0x3,%dl
f0102042:	75 0f                	jne    f0102053 <memmove+0x5f>
f0102044:	f6 c1 03             	test   $0x3,%cl
f0102047:	75 0a                	jne    f0102053 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0102049:	c1 e9 02             	shr    $0x2,%ecx
f010204c:	89 c7                	mov    %eax,%edi
f010204e:	fc                   	cld    
f010204f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0102051:	eb 05                	jmp    f0102058 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0102053:	89 c7                	mov    %eax,%edi
f0102055:	fc                   	cld    
f0102056:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0102058:	5e                   	pop    %esi
f0102059:	5f                   	pop    %edi
f010205a:	5d                   	pop    %ebp
f010205b:	c3                   	ret    

f010205c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010205c:	55                   	push   %ebp
f010205d:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f010205f:	ff 75 10             	pushl  0x10(%ebp)
f0102062:	ff 75 0c             	pushl  0xc(%ebp)
f0102065:	ff 75 08             	pushl  0x8(%ebp)
f0102068:	e8 87 ff ff ff       	call   f0101ff4 <memmove>
}
f010206d:	c9                   	leave  
f010206e:	c3                   	ret    

f010206f <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010206f:	55                   	push   %ebp
f0102070:	89 e5                	mov    %esp,%ebp
f0102072:	56                   	push   %esi
f0102073:	53                   	push   %ebx
f0102074:	8b 45 08             	mov    0x8(%ebp),%eax
f0102077:	8b 55 0c             	mov    0xc(%ebp),%edx
f010207a:	89 c6                	mov    %eax,%esi
f010207c:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010207f:	eb 1a                	jmp    f010209b <memcmp+0x2c>
		if (*s1 != *s2)
f0102081:	0f b6 08             	movzbl (%eax),%ecx
f0102084:	0f b6 1a             	movzbl (%edx),%ebx
f0102087:	38 d9                	cmp    %bl,%cl
f0102089:	74 0a                	je     f0102095 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f010208b:	0f b6 c1             	movzbl %cl,%eax
f010208e:	0f b6 db             	movzbl %bl,%ebx
f0102091:	29 d8                	sub    %ebx,%eax
f0102093:	eb 0f                	jmp    f01020a4 <memcmp+0x35>
		s1++, s2++;
f0102095:	83 c0 01             	add    $0x1,%eax
f0102098:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010209b:	39 f0                	cmp    %esi,%eax
f010209d:	75 e2                	jne    f0102081 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010209f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01020a4:	5b                   	pop    %ebx
f01020a5:	5e                   	pop    %esi
f01020a6:	5d                   	pop    %ebp
f01020a7:	c3                   	ret    

f01020a8 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01020a8:	55                   	push   %ebp
f01020a9:	89 e5                	mov    %esp,%ebp
f01020ab:	53                   	push   %ebx
f01020ac:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f01020af:	89 c1                	mov    %eax,%ecx
f01020b1:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f01020b4:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01020b8:	eb 0a                	jmp    f01020c4 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f01020ba:	0f b6 10             	movzbl (%eax),%edx
f01020bd:	39 da                	cmp    %ebx,%edx
f01020bf:	74 07                	je     f01020c8 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01020c1:	83 c0 01             	add    $0x1,%eax
f01020c4:	39 c8                	cmp    %ecx,%eax
f01020c6:	72 f2                	jb     f01020ba <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01020c8:	5b                   	pop    %ebx
f01020c9:	5d                   	pop    %ebp
f01020ca:	c3                   	ret    

f01020cb <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01020cb:	55                   	push   %ebp
f01020cc:	89 e5                	mov    %esp,%ebp
f01020ce:	57                   	push   %edi
f01020cf:	56                   	push   %esi
f01020d0:	53                   	push   %ebx
f01020d1:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01020d4:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01020d7:	eb 03                	jmp    f01020dc <strtol+0x11>
		s++;
f01020d9:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01020dc:	0f b6 01             	movzbl (%ecx),%eax
f01020df:	3c 20                	cmp    $0x20,%al
f01020e1:	74 f6                	je     f01020d9 <strtol+0xe>
f01020e3:	3c 09                	cmp    $0x9,%al
f01020e5:	74 f2                	je     f01020d9 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01020e7:	3c 2b                	cmp    $0x2b,%al
f01020e9:	75 0a                	jne    f01020f5 <strtol+0x2a>
		s++;
f01020eb:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01020ee:	bf 00 00 00 00       	mov    $0x0,%edi
f01020f3:	eb 11                	jmp    f0102106 <strtol+0x3b>
f01020f5:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01020fa:	3c 2d                	cmp    $0x2d,%al
f01020fc:	75 08                	jne    f0102106 <strtol+0x3b>
		s++, neg = 1;
f01020fe:	83 c1 01             	add    $0x1,%ecx
f0102101:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0102106:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f010210c:	75 15                	jne    f0102123 <strtol+0x58>
f010210e:	80 39 30             	cmpb   $0x30,(%ecx)
f0102111:	75 10                	jne    f0102123 <strtol+0x58>
f0102113:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0102117:	75 7c                	jne    f0102195 <strtol+0xca>
		s += 2, base = 16;
f0102119:	83 c1 02             	add    $0x2,%ecx
f010211c:	bb 10 00 00 00       	mov    $0x10,%ebx
f0102121:	eb 16                	jmp    f0102139 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0102123:	85 db                	test   %ebx,%ebx
f0102125:	75 12                	jne    f0102139 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0102127:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010212c:	80 39 30             	cmpb   $0x30,(%ecx)
f010212f:	75 08                	jne    f0102139 <strtol+0x6e>
		s++, base = 8;
f0102131:	83 c1 01             	add    $0x1,%ecx
f0102134:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0102139:	b8 00 00 00 00       	mov    $0x0,%eax
f010213e:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0102141:	0f b6 11             	movzbl (%ecx),%edx
f0102144:	8d 72 d0             	lea    -0x30(%edx),%esi
f0102147:	89 f3                	mov    %esi,%ebx
f0102149:	80 fb 09             	cmp    $0x9,%bl
f010214c:	77 08                	ja     f0102156 <strtol+0x8b>
			dig = *s - '0';
f010214e:	0f be d2             	movsbl %dl,%edx
f0102151:	83 ea 30             	sub    $0x30,%edx
f0102154:	eb 22                	jmp    f0102178 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0102156:	8d 72 9f             	lea    -0x61(%edx),%esi
f0102159:	89 f3                	mov    %esi,%ebx
f010215b:	80 fb 19             	cmp    $0x19,%bl
f010215e:	77 08                	ja     f0102168 <strtol+0x9d>
			dig = *s - 'a' + 10;
f0102160:	0f be d2             	movsbl %dl,%edx
f0102163:	83 ea 57             	sub    $0x57,%edx
f0102166:	eb 10                	jmp    f0102178 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0102168:	8d 72 bf             	lea    -0x41(%edx),%esi
f010216b:	89 f3                	mov    %esi,%ebx
f010216d:	80 fb 19             	cmp    $0x19,%bl
f0102170:	77 16                	ja     f0102188 <strtol+0xbd>
			dig = *s - 'A' + 10;
f0102172:	0f be d2             	movsbl %dl,%edx
f0102175:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0102178:	3b 55 10             	cmp    0x10(%ebp),%edx
f010217b:	7d 0b                	jge    f0102188 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f010217d:	83 c1 01             	add    $0x1,%ecx
f0102180:	0f af 45 10          	imul   0x10(%ebp),%eax
f0102184:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0102186:	eb b9                	jmp    f0102141 <strtol+0x76>

	if (endptr)
f0102188:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010218c:	74 0d                	je     f010219b <strtol+0xd0>
		*endptr = (char *) s;
f010218e:	8b 75 0c             	mov    0xc(%ebp),%esi
f0102191:	89 0e                	mov    %ecx,(%esi)
f0102193:	eb 06                	jmp    f010219b <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0102195:	85 db                	test   %ebx,%ebx
f0102197:	74 98                	je     f0102131 <strtol+0x66>
f0102199:	eb 9e                	jmp    f0102139 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f010219b:	89 c2                	mov    %eax,%edx
f010219d:	f7 da                	neg    %edx
f010219f:	85 ff                	test   %edi,%edi
f01021a1:	0f 45 c2             	cmovne %edx,%eax
}
f01021a4:	5b                   	pop    %ebx
f01021a5:	5e                   	pop    %esi
f01021a6:	5f                   	pop    %edi
f01021a7:	5d                   	pop    %ebp
f01021a8:	c3                   	ret    
f01021a9:	66 90                	xchg   %ax,%ax
f01021ab:	66 90                	xchg   %ax,%ax
f01021ad:	66 90                	xchg   %ax,%ax
f01021af:	90                   	nop

f01021b0 <__udivdi3>:
f01021b0:	55                   	push   %ebp
f01021b1:	57                   	push   %edi
f01021b2:	56                   	push   %esi
f01021b3:	53                   	push   %ebx
f01021b4:	83 ec 1c             	sub    $0x1c,%esp
f01021b7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f01021bb:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f01021bf:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f01021c3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01021c7:	85 f6                	test   %esi,%esi
f01021c9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01021cd:	89 ca                	mov    %ecx,%edx
f01021cf:	89 f8                	mov    %edi,%eax
f01021d1:	75 3d                	jne    f0102210 <__udivdi3+0x60>
f01021d3:	39 cf                	cmp    %ecx,%edi
f01021d5:	0f 87 c5 00 00 00    	ja     f01022a0 <__udivdi3+0xf0>
f01021db:	85 ff                	test   %edi,%edi
f01021dd:	89 fd                	mov    %edi,%ebp
f01021df:	75 0b                	jne    f01021ec <__udivdi3+0x3c>
f01021e1:	b8 01 00 00 00       	mov    $0x1,%eax
f01021e6:	31 d2                	xor    %edx,%edx
f01021e8:	f7 f7                	div    %edi
f01021ea:	89 c5                	mov    %eax,%ebp
f01021ec:	89 c8                	mov    %ecx,%eax
f01021ee:	31 d2                	xor    %edx,%edx
f01021f0:	f7 f5                	div    %ebp
f01021f2:	89 c1                	mov    %eax,%ecx
f01021f4:	89 d8                	mov    %ebx,%eax
f01021f6:	89 cf                	mov    %ecx,%edi
f01021f8:	f7 f5                	div    %ebp
f01021fa:	89 c3                	mov    %eax,%ebx
f01021fc:	89 d8                	mov    %ebx,%eax
f01021fe:	89 fa                	mov    %edi,%edx
f0102200:	83 c4 1c             	add    $0x1c,%esp
f0102203:	5b                   	pop    %ebx
f0102204:	5e                   	pop    %esi
f0102205:	5f                   	pop    %edi
f0102206:	5d                   	pop    %ebp
f0102207:	c3                   	ret    
f0102208:	90                   	nop
f0102209:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0102210:	39 ce                	cmp    %ecx,%esi
f0102212:	77 74                	ja     f0102288 <__udivdi3+0xd8>
f0102214:	0f bd fe             	bsr    %esi,%edi
f0102217:	83 f7 1f             	xor    $0x1f,%edi
f010221a:	0f 84 98 00 00 00    	je     f01022b8 <__udivdi3+0x108>
f0102220:	bb 20 00 00 00       	mov    $0x20,%ebx
f0102225:	89 f9                	mov    %edi,%ecx
f0102227:	89 c5                	mov    %eax,%ebp
f0102229:	29 fb                	sub    %edi,%ebx
f010222b:	d3 e6                	shl    %cl,%esi
f010222d:	89 d9                	mov    %ebx,%ecx
f010222f:	d3 ed                	shr    %cl,%ebp
f0102231:	89 f9                	mov    %edi,%ecx
f0102233:	d3 e0                	shl    %cl,%eax
f0102235:	09 ee                	or     %ebp,%esi
f0102237:	89 d9                	mov    %ebx,%ecx
f0102239:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010223d:	89 d5                	mov    %edx,%ebp
f010223f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0102243:	d3 ed                	shr    %cl,%ebp
f0102245:	89 f9                	mov    %edi,%ecx
f0102247:	d3 e2                	shl    %cl,%edx
f0102249:	89 d9                	mov    %ebx,%ecx
f010224b:	d3 e8                	shr    %cl,%eax
f010224d:	09 c2                	or     %eax,%edx
f010224f:	89 d0                	mov    %edx,%eax
f0102251:	89 ea                	mov    %ebp,%edx
f0102253:	f7 f6                	div    %esi
f0102255:	89 d5                	mov    %edx,%ebp
f0102257:	89 c3                	mov    %eax,%ebx
f0102259:	f7 64 24 0c          	mull   0xc(%esp)
f010225d:	39 d5                	cmp    %edx,%ebp
f010225f:	72 10                	jb     f0102271 <__udivdi3+0xc1>
f0102261:	8b 74 24 08          	mov    0x8(%esp),%esi
f0102265:	89 f9                	mov    %edi,%ecx
f0102267:	d3 e6                	shl    %cl,%esi
f0102269:	39 c6                	cmp    %eax,%esi
f010226b:	73 07                	jae    f0102274 <__udivdi3+0xc4>
f010226d:	39 d5                	cmp    %edx,%ebp
f010226f:	75 03                	jne    f0102274 <__udivdi3+0xc4>
f0102271:	83 eb 01             	sub    $0x1,%ebx
f0102274:	31 ff                	xor    %edi,%edi
f0102276:	89 d8                	mov    %ebx,%eax
f0102278:	89 fa                	mov    %edi,%edx
f010227a:	83 c4 1c             	add    $0x1c,%esp
f010227d:	5b                   	pop    %ebx
f010227e:	5e                   	pop    %esi
f010227f:	5f                   	pop    %edi
f0102280:	5d                   	pop    %ebp
f0102281:	c3                   	ret    
f0102282:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0102288:	31 ff                	xor    %edi,%edi
f010228a:	31 db                	xor    %ebx,%ebx
f010228c:	89 d8                	mov    %ebx,%eax
f010228e:	89 fa                	mov    %edi,%edx
f0102290:	83 c4 1c             	add    $0x1c,%esp
f0102293:	5b                   	pop    %ebx
f0102294:	5e                   	pop    %esi
f0102295:	5f                   	pop    %edi
f0102296:	5d                   	pop    %ebp
f0102297:	c3                   	ret    
f0102298:	90                   	nop
f0102299:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01022a0:	89 d8                	mov    %ebx,%eax
f01022a2:	f7 f7                	div    %edi
f01022a4:	31 ff                	xor    %edi,%edi
f01022a6:	89 c3                	mov    %eax,%ebx
f01022a8:	89 d8                	mov    %ebx,%eax
f01022aa:	89 fa                	mov    %edi,%edx
f01022ac:	83 c4 1c             	add    $0x1c,%esp
f01022af:	5b                   	pop    %ebx
f01022b0:	5e                   	pop    %esi
f01022b1:	5f                   	pop    %edi
f01022b2:	5d                   	pop    %ebp
f01022b3:	c3                   	ret    
f01022b4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01022b8:	39 ce                	cmp    %ecx,%esi
f01022ba:	72 0c                	jb     f01022c8 <__udivdi3+0x118>
f01022bc:	31 db                	xor    %ebx,%ebx
f01022be:	3b 44 24 08          	cmp    0x8(%esp),%eax
f01022c2:	0f 87 34 ff ff ff    	ja     f01021fc <__udivdi3+0x4c>
f01022c8:	bb 01 00 00 00       	mov    $0x1,%ebx
f01022cd:	e9 2a ff ff ff       	jmp    f01021fc <__udivdi3+0x4c>
f01022d2:	66 90                	xchg   %ax,%ax
f01022d4:	66 90                	xchg   %ax,%ax
f01022d6:	66 90                	xchg   %ax,%ax
f01022d8:	66 90                	xchg   %ax,%ax
f01022da:	66 90                	xchg   %ax,%ax
f01022dc:	66 90                	xchg   %ax,%ax
f01022de:	66 90                	xchg   %ax,%ax

f01022e0 <__umoddi3>:
f01022e0:	55                   	push   %ebp
f01022e1:	57                   	push   %edi
f01022e2:	56                   	push   %esi
f01022e3:	53                   	push   %ebx
f01022e4:	83 ec 1c             	sub    $0x1c,%esp
f01022e7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01022eb:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f01022ef:	8b 74 24 34          	mov    0x34(%esp),%esi
f01022f3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01022f7:	85 d2                	test   %edx,%edx
f01022f9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01022fd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0102301:	89 f3                	mov    %esi,%ebx
f0102303:	89 3c 24             	mov    %edi,(%esp)
f0102306:	89 74 24 04          	mov    %esi,0x4(%esp)
f010230a:	75 1c                	jne    f0102328 <__umoddi3+0x48>
f010230c:	39 f7                	cmp    %esi,%edi
f010230e:	76 50                	jbe    f0102360 <__umoddi3+0x80>
f0102310:	89 c8                	mov    %ecx,%eax
f0102312:	89 f2                	mov    %esi,%edx
f0102314:	f7 f7                	div    %edi
f0102316:	89 d0                	mov    %edx,%eax
f0102318:	31 d2                	xor    %edx,%edx
f010231a:	83 c4 1c             	add    $0x1c,%esp
f010231d:	5b                   	pop    %ebx
f010231e:	5e                   	pop    %esi
f010231f:	5f                   	pop    %edi
f0102320:	5d                   	pop    %ebp
f0102321:	c3                   	ret    
f0102322:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0102328:	39 f2                	cmp    %esi,%edx
f010232a:	89 d0                	mov    %edx,%eax
f010232c:	77 52                	ja     f0102380 <__umoddi3+0xa0>
f010232e:	0f bd ea             	bsr    %edx,%ebp
f0102331:	83 f5 1f             	xor    $0x1f,%ebp
f0102334:	75 5a                	jne    f0102390 <__umoddi3+0xb0>
f0102336:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010233a:	0f 82 e0 00 00 00    	jb     f0102420 <__umoddi3+0x140>
f0102340:	39 0c 24             	cmp    %ecx,(%esp)
f0102343:	0f 86 d7 00 00 00    	jbe    f0102420 <__umoddi3+0x140>
f0102349:	8b 44 24 08          	mov    0x8(%esp),%eax
f010234d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0102351:	83 c4 1c             	add    $0x1c,%esp
f0102354:	5b                   	pop    %ebx
f0102355:	5e                   	pop    %esi
f0102356:	5f                   	pop    %edi
f0102357:	5d                   	pop    %ebp
f0102358:	c3                   	ret    
f0102359:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0102360:	85 ff                	test   %edi,%edi
f0102362:	89 fd                	mov    %edi,%ebp
f0102364:	75 0b                	jne    f0102371 <__umoddi3+0x91>
f0102366:	b8 01 00 00 00       	mov    $0x1,%eax
f010236b:	31 d2                	xor    %edx,%edx
f010236d:	f7 f7                	div    %edi
f010236f:	89 c5                	mov    %eax,%ebp
f0102371:	89 f0                	mov    %esi,%eax
f0102373:	31 d2                	xor    %edx,%edx
f0102375:	f7 f5                	div    %ebp
f0102377:	89 c8                	mov    %ecx,%eax
f0102379:	f7 f5                	div    %ebp
f010237b:	89 d0                	mov    %edx,%eax
f010237d:	eb 99                	jmp    f0102318 <__umoddi3+0x38>
f010237f:	90                   	nop
f0102380:	89 c8                	mov    %ecx,%eax
f0102382:	89 f2                	mov    %esi,%edx
f0102384:	83 c4 1c             	add    $0x1c,%esp
f0102387:	5b                   	pop    %ebx
f0102388:	5e                   	pop    %esi
f0102389:	5f                   	pop    %edi
f010238a:	5d                   	pop    %ebp
f010238b:	c3                   	ret    
f010238c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0102390:	8b 34 24             	mov    (%esp),%esi
f0102393:	bf 20 00 00 00       	mov    $0x20,%edi
f0102398:	89 e9                	mov    %ebp,%ecx
f010239a:	29 ef                	sub    %ebp,%edi
f010239c:	d3 e0                	shl    %cl,%eax
f010239e:	89 f9                	mov    %edi,%ecx
f01023a0:	89 f2                	mov    %esi,%edx
f01023a2:	d3 ea                	shr    %cl,%edx
f01023a4:	89 e9                	mov    %ebp,%ecx
f01023a6:	09 c2                	or     %eax,%edx
f01023a8:	89 d8                	mov    %ebx,%eax
f01023aa:	89 14 24             	mov    %edx,(%esp)
f01023ad:	89 f2                	mov    %esi,%edx
f01023af:	d3 e2                	shl    %cl,%edx
f01023b1:	89 f9                	mov    %edi,%ecx
f01023b3:	89 54 24 04          	mov    %edx,0x4(%esp)
f01023b7:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01023bb:	d3 e8                	shr    %cl,%eax
f01023bd:	89 e9                	mov    %ebp,%ecx
f01023bf:	89 c6                	mov    %eax,%esi
f01023c1:	d3 e3                	shl    %cl,%ebx
f01023c3:	89 f9                	mov    %edi,%ecx
f01023c5:	89 d0                	mov    %edx,%eax
f01023c7:	d3 e8                	shr    %cl,%eax
f01023c9:	89 e9                	mov    %ebp,%ecx
f01023cb:	09 d8                	or     %ebx,%eax
f01023cd:	89 d3                	mov    %edx,%ebx
f01023cf:	89 f2                	mov    %esi,%edx
f01023d1:	f7 34 24             	divl   (%esp)
f01023d4:	89 d6                	mov    %edx,%esi
f01023d6:	d3 e3                	shl    %cl,%ebx
f01023d8:	f7 64 24 04          	mull   0x4(%esp)
f01023dc:	39 d6                	cmp    %edx,%esi
f01023de:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01023e2:	89 d1                	mov    %edx,%ecx
f01023e4:	89 c3                	mov    %eax,%ebx
f01023e6:	72 08                	jb     f01023f0 <__umoddi3+0x110>
f01023e8:	75 11                	jne    f01023fb <__umoddi3+0x11b>
f01023ea:	39 44 24 08          	cmp    %eax,0x8(%esp)
f01023ee:	73 0b                	jae    f01023fb <__umoddi3+0x11b>
f01023f0:	2b 44 24 04          	sub    0x4(%esp),%eax
f01023f4:	1b 14 24             	sbb    (%esp),%edx
f01023f7:	89 d1                	mov    %edx,%ecx
f01023f9:	89 c3                	mov    %eax,%ebx
f01023fb:	8b 54 24 08          	mov    0x8(%esp),%edx
f01023ff:	29 da                	sub    %ebx,%edx
f0102401:	19 ce                	sbb    %ecx,%esi
f0102403:	89 f9                	mov    %edi,%ecx
f0102405:	89 f0                	mov    %esi,%eax
f0102407:	d3 e0                	shl    %cl,%eax
f0102409:	89 e9                	mov    %ebp,%ecx
f010240b:	d3 ea                	shr    %cl,%edx
f010240d:	89 e9                	mov    %ebp,%ecx
f010240f:	d3 ee                	shr    %cl,%esi
f0102411:	09 d0                	or     %edx,%eax
f0102413:	89 f2                	mov    %esi,%edx
f0102415:	83 c4 1c             	add    $0x1c,%esp
f0102418:	5b                   	pop    %ebx
f0102419:	5e                   	pop    %esi
f010241a:	5f                   	pop    %edi
f010241b:	5d                   	pop    %ebp
f010241c:	c3                   	ret    
f010241d:	8d 76 00             	lea    0x0(%esi),%esi
f0102420:	29 f9                	sub    %edi,%ecx
f0102422:	19 d6                	sbb    %edx,%esi
f0102424:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102428:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010242c:	e9 18 ff ff ff       	jmp    f0102349 <__umoddi3+0x69>
