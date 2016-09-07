
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
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
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
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 56 00 00 00       	call   f0100094 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 0c             	sub    $0xc,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	53                   	push   %ebx
f010004b:	68 c0 18 10 f0       	push   $0xf01018c0
f0100050:	e8 e0 08 00 00       	call   f0100935 <cprintf>
	if (x > 0)
f0100055:	83 c4 10             	add    $0x10,%esp
f0100058:	85 db                	test   %ebx,%ebx
f010005a:	7e 11                	jle    f010006d <test_backtrace+0x2d>
		test_backtrace(x-1);
f010005c:	83 ec 0c             	sub    $0xc,%esp
f010005f:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100062:	50                   	push   %eax
f0100063:	e8 d8 ff ff ff       	call   f0100040 <test_backtrace>
f0100068:	83 c4 10             	add    $0x10,%esp
f010006b:	eb 11                	jmp    f010007e <test_backtrace+0x3e>
	else
		mon_backtrace(0, 0, 0);
f010006d:	83 ec 04             	sub    $0x4,%esp
f0100070:	6a 00                	push   $0x0
f0100072:	6a 00                	push   $0x0
f0100074:	6a 00                	push   $0x0
f0100076:	e8 e5 06 00 00       	call   f0100760 <mon_backtrace>
f010007b:	83 c4 10             	add    $0x10,%esp
	cprintf("leaving test_backtrace %d\n", x);
f010007e:	83 ec 08             	sub    $0x8,%esp
f0100081:	53                   	push   %ebx
f0100082:	68 dc 18 10 f0       	push   $0xf01018dc
f0100087:	e8 a9 08 00 00       	call   f0100935 <cprintf>
}
f010008c:	83 c4 10             	add    $0x10,%esp
f010008f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100092:	c9                   	leave  
f0100093:	c3                   	ret    

f0100094 <i386_init>:

void
i386_init(void)
{
f0100094:	55                   	push   %ebp
f0100095:	89 e5                	mov    %esp,%ebp
f0100097:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f010009a:	b8 44 29 11 f0       	mov    $0xf0112944,%eax
f010009f:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000a4:	50                   	push   %eax
f01000a5:	6a 00                	push   $0x0
f01000a7:	68 00 23 11 f0       	push   $0xf0112300
f01000ac:	e8 6d 13 00 00       	call   f010141e <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b1:	e8 8f 04 00 00       	call   f0100545 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000b6:	83 c4 08             	add    $0x8,%esp
f01000b9:	68 ac 1a 00 00       	push   $0x1aac
f01000be:	68 f7 18 10 f0       	push   $0xf01018f7
f01000c3:	e8 6d 08 00 00       	call   f0100935 <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000c8:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000cf:	e8 6c ff ff ff       	call   f0100040 <test_backtrace>
f01000d4:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000d7:	83 ec 0c             	sub    $0xc,%esp
f01000da:	6a 00                	push   $0x0
f01000dc:	e8 d4 06 00 00       	call   f01007b5 <monitor>
f01000e1:	83 c4 10             	add    $0x10,%esp
f01000e4:	eb f1                	jmp    f01000d7 <i386_init+0x43>

f01000e6 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000e6:	55                   	push   %ebp
f01000e7:	89 e5                	mov    %esp,%ebp
f01000e9:	56                   	push   %esi
f01000ea:	53                   	push   %ebx
f01000eb:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000ee:	83 3d 40 29 11 f0 00 	cmpl   $0x0,0xf0112940
f01000f5:	75 37                	jne    f010012e <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000f7:	89 35 40 29 11 f0    	mov    %esi,0xf0112940

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000fd:	fa                   	cli    
f01000fe:	fc                   	cld    

	va_start(ap, fmt);
f01000ff:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100102:	83 ec 04             	sub    $0x4,%esp
f0100105:	ff 75 0c             	pushl  0xc(%ebp)
f0100108:	ff 75 08             	pushl  0x8(%ebp)
f010010b:	68 12 19 10 f0       	push   $0xf0101912
f0100110:	e8 20 08 00 00       	call   f0100935 <cprintf>
	vcprintf(fmt, ap);
f0100115:	83 c4 08             	add    $0x8,%esp
f0100118:	53                   	push   %ebx
f0100119:	56                   	push   %esi
f010011a:	e8 f0 07 00 00       	call   f010090f <vcprintf>
	cprintf("\n");
f010011f:	c7 04 24 4e 19 10 f0 	movl   $0xf010194e,(%esp)
f0100126:	e8 0a 08 00 00       	call   f0100935 <cprintf>
	va_end(ap);
f010012b:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010012e:	83 ec 0c             	sub    $0xc,%esp
f0100131:	6a 00                	push   $0x0
f0100133:	e8 7d 06 00 00       	call   f01007b5 <monitor>
f0100138:	83 c4 10             	add    $0x10,%esp
f010013b:	eb f1                	jmp    f010012e <_panic+0x48>

f010013d <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010013d:	55                   	push   %ebp
f010013e:	89 e5                	mov    %esp,%ebp
f0100140:	53                   	push   %ebx
f0100141:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100144:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100147:	ff 75 0c             	pushl  0xc(%ebp)
f010014a:	ff 75 08             	pushl  0x8(%ebp)
f010014d:	68 2a 19 10 f0       	push   $0xf010192a
f0100152:	e8 de 07 00 00       	call   f0100935 <cprintf>
	vcprintf(fmt, ap);
f0100157:	83 c4 08             	add    $0x8,%esp
f010015a:	53                   	push   %ebx
f010015b:	ff 75 10             	pushl  0x10(%ebp)
f010015e:	e8 ac 07 00 00       	call   f010090f <vcprintf>
	cprintf("\n");
f0100163:	c7 04 24 4e 19 10 f0 	movl   $0xf010194e,(%esp)
f010016a:	e8 c6 07 00 00       	call   f0100935 <cprintf>
	va_end(ap);
}
f010016f:	83 c4 10             	add    $0x10,%esp
f0100172:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100175:	c9                   	leave  
f0100176:	c3                   	ret    

f0100177 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100177:	55                   	push   %ebp
f0100178:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010017a:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010017f:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100180:	a8 01                	test   $0x1,%al
f0100182:	74 0b                	je     f010018f <serial_proc_data+0x18>
f0100184:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100189:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010018a:	0f b6 c0             	movzbl %al,%eax
f010018d:	eb 05                	jmp    f0100194 <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f010018f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100194:	5d                   	pop    %ebp
f0100195:	c3                   	ret    

f0100196 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100196:	55                   	push   %ebp
f0100197:	89 e5                	mov    %esp,%ebp
f0100199:	53                   	push   %ebx
f010019a:	83 ec 04             	sub    $0x4,%esp
f010019d:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f010019f:	eb 2b                	jmp    f01001cc <cons_intr+0x36>
		if (c == 0)
f01001a1:	85 c0                	test   %eax,%eax
f01001a3:	74 27                	je     f01001cc <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f01001a5:	8b 0d 24 25 11 f0    	mov    0xf0112524,%ecx
f01001ab:	8d 51 01             	lea    0x1(%ecx),%edx
f01001ae:	89 15 24 25 11 f0    	mov    %edx,0xf0112524
f01001b4:	88 81 20 23 11 f0    	mov    %al,-0xfeedce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f01001ba:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01001c0:	75 0a                	jne    f01001cc <cons_intr+0x36>
			cons.wpos = 0;
f01001c2:	c7 05 24 25 11 f0 00 	movl   $0x0,0xf0112524
f01001c9:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001cc:	ff d3                	call   *%ebx
f01001ce:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001d1:	75 ce                	jne    f01001a1 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001d3:	83 c4 04             	add    $0x4,%esp
f01001d6:	5b                   	pop    %ebx
f01001d7:	5d                   	pop    %ebp
f01001d8:	c3                   	ret    

f01001d9 <kbd_proc_data>:
f01001d9:	ba 64 00 00 00       	mov    $0x64,%edx
f01001de:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01001df:	a8 01                	test   $0x1,%al
f01001e1:	0f 84 f0 00 00 00    	je     f01002d7 <kbd_proc_data+0xfe>
f01001e7:	ba 60 00 00 00       	mov    $0x60,%edx
f01001ec:	ec                   	in     (%dx),%al
f01001ed:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001ef:	3c e0                	cmp    $0xe0,%al
f01001f1:	75 0d                	jne    f0100200 <kbd_proc_data+0x27>
		// E0 escape character
		shift |= E0ESC;
f01001f3:	83 0d 00 23 11 f0 40 	orl    $0x40,0xf0112300
		return 0;
f01001fa:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01001ff:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100200:	55                   	push   %ebp
f0100201:	89 e5                	mov    %esp,%ebp
f0100203:	53                   	push   %ebx
f0100204:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f0100207:	84 c0                	test   %al,%al
f0100209:	79 36                	jns    f0100241 <kbd_proc_data+0x68>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f010020b:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f0100211:	89 cb                	mov    %ecx,%ebx
f0100213:	83 e3 40             	and    $0x40,%ebx
f0100216:	83 e0 7f             	and    $0x7f,%eax
f0100219:	85 db                	test   %ebx,%ebx
f010021b:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f010021e:	0f b6 d2             	movzbl %dl,%edx
f0100221:	0f b6 82 a0 1a 10 f0 	movzbl -0xfefe560(%edx),%eax
f0100228:	83 c8 40             	or     $0x40,%eax
f010022b:	0f b6 c0             	movzbl %al,%eax
f010022e:	f7 d0                	not    %eax
f0100230:	21 c8                	and    %ecx,%eax
f0100232:	a3 00 23 11 f0       	mov    %eax,0xf0112300
		return 0;
f0100237:	b8 00 00 00 00       	mov    $0x0,%eax
f010023c:	e9 9e 00 00 00       	jmp    f01002df <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f0100241:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f0100247:	f6 c1 40             	test   $0x40,%cl
f010024a:	74 0e                	je     f010025a <kbd_proc_data+0x81>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f010024c:	83 c8 80             	or     $0xffffff80,%eax
f010024f:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100251:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100254:	89 0d 00 23 11 f0    	mov    %ecx,0xf0112300
	}

	shift |= shiftcode[data];
f010025a:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f010025d:	0f b6 82 a0 1a 10 f0 	movzbl -0xfefe560(%edx),%eax
f0100264:	0b 05 00 23 11 f0    	or     0xf0112300,%eax
f010026a:	0f b6 8a a0 19 10 f0 	movzbl -0xfefe660(%edx),%ecx
f0100271:	31 c8                	xor    %ecx,%eax
f0100273:	a3 00 23 11 f0       	mov    %eax,0xf0112300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100278:	89 c1                	mov    %eax,%ecx
f010027a:	83 e1 03             	and    $0x3,%ecx
f010027d:	8b 0c 8d 80 19 10 f0 	mov    -0xfefe680(,%ecx,4),%ecx
f0100284:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100288:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f010028b:	a8 08                	test   $0x8,%al
f010028d:	74 1b                	je     f01002aa <kbd_proc_data+0xd1>
		if ('a' <= c && c <= 'z')
f010028f:	89 da                	mov    %ebx,%edx
f0100291:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100294:	83 f9 19             	cmp    $0x19,%ecx
f0100297:	77 05                	ja     f010029e <kbd_proc_data+0xc5>
			c += 'A' - 'a';
f0100299:	83 eb 20             	sub    $0x20,%ebx
f010029c:	eb 0c                	jmp    f01002aa <kbd_proc_data+0xd1>
		else if ('A' <= c && c <= 'Z')
f010029e:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002a1:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01002a4:	83 fa 19             	cmp    $0x19,%edx
f01002a7:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002aa:	f7 d0                	not    %eax
f01002ac:	a8 06                	test   $0x6,%al
f01002ae:	75 2d                	jne    f01002dd <kbd_proc_data+0x104>
f01002b0:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01002b6:	75 25                	jne    f01002dd <kbd_proc_data+0x104>
		cprintf("Rebooting!\n");
f01002b8:	83 ec 0c             	sub    $0xc,%esp
f01002bb:	68 44 19 10 f0       	push   $0xf0101944
f01002c0:	e8 70 06 00 00       	call   f0100935 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002c5:	ba 92 00 00 00       	mov    $0x92,%edx
f01002ca:	b8 03 00 00 00       	mov    $0x3,%eax
f01002cf:	ee                   	out    %al,(%dx)
f01002d0:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002d3:	89 d8                	mov    %ebx,%eax
f01002d5:	eb 08                	jmp    f01002df <kbd_proc_data+0x106>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01002d7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002dc:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002dd:	89 d8                	mov    %ebx,%eax
}
f01002df:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01002e2:	c9                   	leave  
f01002e3:	c3                   	ret    

f01002e4 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002e4:	55                   	push   %ebp
f01002e5:	89 e5                	mov    %esp,%ebp
f01002e7:	57                   	push   %edi
f01002e8:	56                   	push   %esi
f01002e9:	53                   	push   %ebx
f01002ea:	83 ec 1c             	sub    $0x1c,%esp
f01002ed:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002ef:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002f4:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002f9:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002fe:	eb 09                	jmp    f0100309 <cons_putc+0x25>
f0100300:	89 ca                	mov    %ecx,%edx
f0100302:	ec                   	in     (%dx),%al
f0100303:	ec                   	in     (%dx),%al
f0100304:	ec                   	in     (%dx),%al
f0100305:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f0100306:	83 c3 01             	add    $0x1,%ebx
f0100309:	89 f2                	mov    %esi,%edx
f010030b:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f010030c:	a8 20                	test   $0x20,%al
f010030e:	75 08                	jne    f0100318 <cons_putc+0x34>
f0100310:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100316:	7e e8                	jle    f0100300 <cons_putc+0x1c>
f0100318:	89 f8                	mov    %edi,%eax
f010031a:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010031d:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100322:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100323:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100328:	be 79 03 00 00       	mov    $0x379,%esi
f010032d:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100332:	eb 09                	jmp    f010033d <cons_putc+0x59>
f0100334:	89 ca                	mov    %ecx,%edx
f0100336:	ec                   	in     (%dx),%al
f0100337:	ec                   	in     (%dx),%al
f0100338:	ec                   	in     (%dx),%al
f0100339:	ec                   	in     (%dx),%al
f010033a:	83 c3 01             	add    $0x1,%ebx
f010033d:	89 f2                	mov    %esi,%edx
f010033f:	ec                   	in     (%dx),%al
f0100340:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100346:	7f 04                	jg     f010034c <cons_putc+0x68>
f0100348:	84 c0                	test   %al,%al
f010034a:	79 e8                	jns    f0100334 <cons_putc+0x50>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010034c:	ba 78 03 00 00       	mov    $0x378,%edx
f0100351:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100355:	ee                   	out    %al,(%dx)
f0100356:	ba 7a 03 00 00       	mov    $0x37a,%edx
f010035b:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100360:	ee                   	out    %al,(%dx)
f0100361:	b8 08 00 00 00       	mov    $0x8,%eax
f0100366:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100367:	89 fa                	mov    %edi,%edx
f0100369:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f010036f:	89 f8                	mov    %edi,%eax
f0100371:	80 cc 07             	or     $0x7,%ah
f0100374:	85 d2                	test   %edx,%edx
f0100376:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100379:	89 f8                	mov    %edi,%eax
f010037b:	0f b6 c0             	movzbl %al,%eax
f010037e:	83 f8 09             	cmp    $0x9,%eax
f0100381:	74 74                	je     f01003f7 <cons_putc+0x113>
f0100383:	83 f8 09             	cmp    $0x9,%eax
f0100386:	7f 0a                	jg     f0100392 <cons_putc+0xae>
f0100388:	83 f8 08             	cmp    $0x8,%eax
f010038b:	74 14                	je     f01003a1 <cons_putc+0xbd>
f010038d:	e9 99 00 00 00       	jmp    f010042b <cons_putc+0x147>
f0100392:	83 f8 0a             	cmp    $0xa,%eax
f0100395:	74 3a                	je     f01003d1 <cons_putc+0xed>
f0100397:	83 f8 0d             	cmp    $0xd,%eax
f010039a:	74 3d                	je     f01003d9 <cons_putc+0xf5>
f010039c:	e9 8a 00 00 00       	jmp    f010042b <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f01003a1:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003a8:	66 85 c0             	test   %ax,%ax
f01003ab:	0f 84 e6 00 00 00    	je     f0100497 <cons_putc+0x1b3>
			crt_pos--;
f01003b1:	83 e8 01             	sub    $0x1,%eax
f01003b4:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003ba:	0f b7 c0             	movzwl %ax,%eax
f01003bd:	66 81 e7 00 ff       	and    $0xff00,%di
f01003c2:	83 cf 20             	or     $0x20,%edi
f01003c5:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f01003cb:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003cf:	eb 78                	jmp    f0100449 <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003d1:	66 83 05 28 25 11 f0 	addw   $0x50,0xf0112528
f01003d8:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003d9:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003e0:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003e6:	c1 e8 16             	shr    $0x16,%eax
f01003e9:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003ec:	c1 e0 04             	shl    $0x4,%eax
f01003ef:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
f01003f5:	eb 52                	jmp    f0100449 <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f01003f7:	b8 20 00 00 00       	mov    $0x20,%eax
f01003fc:	e8 e3 fe ff ff       	call   f01002e4 <cons_putc>
		cons_putc(' ');
f0100401:	b8 20 00 00 00       	mov    $0x20,%eax
f0100406:	e8 d9 fe ff ff       	call   f01002e4 <cons_putc>
		cons_putc(' ');
f010040b:	b8 20 00 00 00       	mov    $0x20,%eax
f0100410:	e8 cf fe ff ff       	call   f01002e4 <cons_putc>
		cons_putc(' ');
f0100415:	b8 20 00 00 00       	mov    $0x20,%eax
f010041a:	e8 c5 fe ff ff       	call   f01002e4 <cons_putc>
		cons_putc(' ');
f010041f:	b8 20 00 00 00       	mov    $0x20,%eax
f0100424:	e8 bb fe ff ff       	call   f01002e4 <cons_putc>
f0100429:	eb 1e                	jmp    f0100449 <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f010042b:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f0100432:	8d 50 01             	lea    0x1(%eax),%edx
f0100435:	66 89 15 28 25 11 f0 	mov    %dx,0xf0112528
f010043c:	0f b7 c0             	movzwl %ax,%eax
f010043f:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f0100445:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100449:	66 81 3d 28 25 11 f0 	cmpw   $0x7cf,0xf0112528
f0100450:	cf 07 
f0100452:	76 43                	jbe    f0100497 <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100454:	a1 2c 25 11 f0       	mov    0xf011252c,%eax
f0100459:	83 ec 04             	sub    $0x4,%esp
f010045c:	68 00 0f 00 00       	push   $0xf00
f0100461:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100467:	52                   	push   %edx
f0100468:	50                   	push   %eax
f0100469:	e8 fd 0f 00 00       	call   f010146b <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010046e:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f0100474:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f010047a:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100480:	83 c4 10             	add    $0x10,%esp
f0100483:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100488:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010048b:	39 d0                	cmp    %edx,%eax
f010048d:	75 f4                	jne    f0100483 <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f010048f:	66 83 2d 28 25 11 f0 	subw   $0x50,0xf0112528
f0100496:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100497:	8b 0d 30 25 11 f0    	mov    0xf0112530,%ecx
f010049d:	b8 0e 00 00 00       	mov    $0xe,%eax
f01004a2:	89 ca                	mov    %ecx,%edx
f01004a4:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01004a5:	0f b7 1d 28 25 11 f0 	movzwl 0xf0112528,%ebx
f01004ac:	8d 71 01             	lea    0x1(%ecx),%esi
f01004af:	89 d8                	mov    %ebx,%eax
f01004b1:	66 c1 e8 08          	shr    $0x8,%ax
f01004b5:	89 f2                	mov    %esi,%edx
f01004b7:	ee                   	out    %al,(%dx)
f01004b8:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004bd:	89 ca                	mov    %ecx,%edx
f01004bf:	ee                   	out    %al,(%dx)
f01004c0:	89 d8                	mov    %ebx,%eax
f01004c2:	89 f2                	mov    %esi,%edx
f01004c4:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004c5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01004c8:	5b                   	pop    %ebx
f01004c9:	5e                   	pop    %esi
f01004ca:	5f                   	pop    %edi
f01004cb:	5d                   	pop    %ebp
f01004cc:	c3                   	ret    

f01004cd <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004cd:	80 3d 34 25 11 f0 00 	cmpb   $0x0,0xf0112534
f01004d4:	74 11                	je     f01004e7 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004d6:	55                   	push   %ebp
f01004d7:	89 e5                	mov    %esp,%ebp
f01004d9:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004dc:	b8 77 01 10 f0       	mov    $0xf0100177,%eax
f01004e1:	e8 b0 fc ff ff       	call   f0100196 <cons_intr>
}
f01004e6:	c9                   	leave  
f01004e7:	f3 c3                	repz ret 

f01004e9 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004e9:	55                   	push   %ebp
f01004ea:	89 e5                	mov    %esp,%ebp
f01004ec:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004ef:	b8 d9 01 10 f0       	mov    $0xf01001d9,%eax
f01004f4:	e8 9d fc ff ff       	call   f0100196 <cons_intr>
}
f01004f9:	c9                   	leave  
f01004fa:	c3                   	ret    

f01004fb <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004fb:	55                   	push   %ebp
f01004fc:	89 e5                	mov    %esp,%ebp
f01004fe:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f0100501:	e8 c7 ff ff ff       	call   f01004cd <serial_intr>
	kbd_intr();
f0100506:	e8 de ff ff ff       	call   f01004e9 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f010050b:	a1 20 25 11 f0       	mov    0xf0112520,%eax
f0100510:	3b 05 24 25 11 f0    	cmp    0xf0112524,%eax
f0100516:	74 26                	je     f010053e <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100518:	8d 50 01             	lea    0x1(%eax),%edx
f010051b:	89 15 20 25 11 f0    	mov    %edx,0xf0112520
f0100521:	0f b6 88 20 23 11 f0 	movzbl -0xfeedce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100528:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f010052a:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100530:	75 11                	jne    f0100543 <cons_getc+0x48>
			cons.rpos = 0;
f0100532:	c7 05 20 25 11 f0 00 	movl   $0x0,0xf0112520
f0100539:	00 00 00 
f010053c:	eb 05                	jmp    f0100543 <cons_getc+0x48>
		return c;
	}
	return 0;
f010053e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100543:	c9                   	leave  
f0100544:	c3                   	ret    

f0100545 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f0100545:	55                   	push   %ebp
f0100546:	89 e5                	mov    %esp,%ebp
f0100548:	57                   	push   %edi
f0100549:	56                   	push   %esi
f010054a:	53                   	push   %ebx
f010054b:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f010054e:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100555:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010055c:	5a a5 
	if (*cp != 0xA55A) {
f010055e:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100565:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100569:	74 11                	je     f010057c <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f010056b:	c7 05 30 25 11 f0 b4 	movl   $0x3b4,0xf0112530
f0100572:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100575:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f010057a:	eb 16                	jmp    f0100592 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010057c:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100583:	c7 05 30 25 11 f0 d4 	movl   $0x3d4,0xf0112530
f010058a:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f010058d:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100592:	8b 3d 30 25 11 f0    	mov    0xf0112530,%edi
f0100598:	b8 0e 00 00 00       	mov    $0xe,%eax
f010059d:	89 fa                	mov    %edi,%edx
f010059f:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005a0:	8d 5f 01             	lea    0x1(%edi),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005a3:	89 da                	mov    %ebx,%edx
f01005a5:	ec                   	in     (%dx),%al
f01005a6:	0f b6 c8             	movzbl %al,%ecx
f01005a9:	c1 e1 08             	shl    $0x8,%ecx
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005ac:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005b1:	89 fa                	mov    %edi,%edx
f01005b3:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005b4:	89 da                	mov    %ebx,%edx
f01005b6:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005b7:	89 35 2c 25 11 f0    	mov    %esi,0xf011252c
	crt_pos = pos;
f01005bd:	0f b6 c0             	movzbl %al,%eax
f01005c0:	09 c8                	or     %ecx,%eax
f01005c2:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005c8:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005cd:	b8 00 00 00 00       	mov    $0x0,%eax
f01005d2:	89 f2                	mov    %esi,%edx
f01005d4:	ee                   	out    %al,(%dx)
f01005d5:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005da:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005df:	ee                   	out    %al,(%dx)
f01005e0:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005e5:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005ea:	89 da                	mov    %ebx,%edx
f01005ec:	ee                   	out    %al,(%dx)
f01005ed:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005f2:	b8 00 00 00 00       	mov    $0x0,%eax
f01005f7:	ee                   	out    %al,(%dx)
f01005f8:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005fd:	b8 03 00 00 00       	mov    $0x3,%eax
f0100602:	ee                   	out    %al,(%dx)
f0100603:	ba fc 03 00 00       	mov    $0x3fc,%edx
f0100608:	b8 00 00 00 00       	mov    $0x0,%eax
f010060d:	ee                   	out    %al,(%dx)
f010060e:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100613:	b8 01 00 00 00       	mov    $0x1,%eax
f0100618:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100619:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010061e:	ec                   	in     (%dx),%al
f010061f:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100621:	3c ff                	cmp    $0xff,%al
f0100623:	0f 95 05 34 25 11 f0 	setne  0xf0112534
f010062a:	89 f2                	mov    %esi,%edx
f010062c:	ec                   	in     (%dx),%al
f010062d:	89 da                	mov    %ebx,%edx
f010062f:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100630:	80 f9 ff             	cmp    $0xff,%cl
f0100633:	75 10                	jne    f0100645 <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f0100635:	83 ec 0c             	sub    $0xc,%esp
f0100638:	68 50 19 10 f0       	push   $0xf0101950
f010063d:	e8 f3 02 00 00       	call   f0100935 <cprintf>
f0100642:	83 c4 10             	add    $0x10,%esp
}
f0100645:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100648:	5b                   	pop    %ebx
f0100649:	5e                   	pop    %esi
f010064a:	5f                   	pop    %edi
f010064b:	5d                   	pop    %ebp
f010064c:	c3                   	ret    

f010064d <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010064d:	55                   	push   %ebp
f010064e:	89 e5                	mov    %esp,%ebp
f0100650:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100653:	8b 45 08             	mov    0x8(%ebp),%eax
f0100656:	e8 89 fc ff ff       	call   f01002e4 <cons_putc>
}
f010065b:	c9                   	leave  
f010065c:	c3                   	ret    

f010065d <getchar>:

int
getchar(void)
{
f010065d:	55                   	push   %ebp
f010065e:	89 e5                	mov    %esp,%ebp
f0100660:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100663:	e8 93 fe ff ff       	call   f01004fb <cons_getc>
f0100668:	85 c0                	test   %eax,%eax
f010066a:	74 f7                	je     f0100663 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010066c:	c9                   	leave  
f010066d:	c3                   	ret    

f010066e <iscons>:

int
iscons(int fdnum)
{
f010066e:	55                   	push   %ebp
f010066f:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100671:	b8 01 00 00 00       	mov    $0x1,%eax
f0100676:	5d                   	pop    %ebp
f0100677:	c3                   	ret    

f0100678 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100678:	55                   	push   %ebp
f0100679:	89 e5                	mov    %esp,%ebp
f010067b:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010067e:	68 a0 1b 10 f0       	push   $0xf0101ba0
f0100683:	68 be 1b 10 f0       	push   $0xf0101bbe
f0100688:	68 c3 1b 10 f0       	push   $0xf0101bc3
f010068d:	e8 a3 02 00 00       	call   f0100935 <cprintf>
f0100692:	83 c4 0c             	add    $0xc,%esp
f0100695:	68 3c 1c 10 f0       	push   $0xf0101c3c
f010069a:	68 cc 1b 10 f0       	push   $0xf0101bcc
f010069f:	68 c3 1b 10 f0       	push   $0xf0101bc3
f01006a4:	e8 8c 02 00 00       	call   f0100935 <cprintf>
	return 0;
}
f01006a9:	b8 00 00 00 00       	mov    $0x0,%eax
f01006ae:	c9                   	leave  
f01006af:	c3                   	ret    

f01006b0 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006b0:	55                   	push   %ebp
f01006b1:	89 e5                	mov    %esp,%ebp
f01006b3:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006b6:	68 d5 1b 10 f0       	push   $0xf0101bd5
f01006bb:	e8 75 02 00 00       	call   f0100935 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006c0:	83 c4 08             	add    $0x8,%esp
f01006c3:	68 0c 00 10 00       	push   $0x10000c
f01006c8:	68 64 1c 10 f0       	push   $0xf0101c64
f01006cd:	e8 63 02 00 00       	call   f0100935 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006d2:	83 c4 0c             	add    $0xc,%esp
f01006d5:	68 0c 00 10 00       	push   $0x10000c
f01006da:	68 0c 00 10 f0       	push   $0xf010000c
f01006df:	68 8c 1c 10 f0       	push   $0xf0101c8c
f01006e4:	e8 4c 02 00 00       	call   f0100935 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006e9:	83 c4 0c             	add    $0xc,%esp
f01006ec:	68 a1 18 10 00       	push   $0x1018a1
f01006f1:	68 a1 18 10 f0       	push   $0xf01018a1
f01006f6:	68 b0 1c 10 f0       	push   $0xf0101cb0
f01006fb:	e8 35 02 00 00       	call   f0100935 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100700:	83 c4 0c             	add    $0xc,%esp
f0100703:	68 00 23 11 00       	push   $0x112300
f0100708:	68 00 23 11 f0       	push   $0xf0112300
f010070d:	68 d4 1c 10 f0       	push   $0xf0101cd4
f0100712:	e8 1e 02 00 00       	call   f0100935 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100717:	83 c4 0c             	add    $0xc,%esp
f010071a:	68 44 29 11 00       	push   $0x112944
f010071f:	68 44 29 11 f0       	push   $0xf0112944
f0100724:	68 f8 1c 10 f0       	push   $0xf0101cf8
f0100729:	e8 07 02 00 00       	call   f0100935 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f010072e:	b8 43 2d 11 f0       	mov    $0xf0112d43,%eax
f0100733:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100738:	83 c4 08             	add    $0x8,%esp
f010073b:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f0100740:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100746:	85 c0                	test   %eax,%eax
f0100748:	0f 48 c2             	cmovs  %edx,%eax
f010074b:	c1 f8 0a             	sar    $0xa,%eax
f010074e:	50                   	push   %eax
f010074f:	68 1c 1d 10 f0       	push   $0xf0101d1c
f0100754:	e8 dc 01 00 00       	call   f0100935 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100759:	b8 00 00 00 00       	mov    $0x0,%eax
f010075e:	c9                   	leave  
f010075f:	c3                   	ret    

f0100760 <mon_backtrace>:


int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100760:	55                   	push   %ebp
f0100761:	89 e5                	mov    %esp,%ebp
f0100763:	53                   	push   %ebx
f0100764:	83 ec 10             	sub    $0x10,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f0100767:	89 eb                	mov    %ebp,%ebx
	uint32_t* test_ebp = (uint32_t*) read_ebp();
	cprintf("Stack backtrace:\n");
f0100769:	68 ee 1b 10 f0       	push   $0xf0101bee
f010076e:	e8 c2 01 00 00       	call   f0100935 <cprintf>
	while (test_ebp)
f0100773:	83 c4 10             	add    $0x10,%esp
f0100776:	eb 2f                	jmp    f01007a7 <mon_backtrace+0x47>
	 {
		cprintf("  ebp %08x eip %08x args %08x %08x %08x %08x %08x",test_ebp, test_ebp[1],test_ebp[2],test_ebp[3],test_ebp[4],test_ebp[5], test_ebp[6]);
f0100778:	ff 73 18             	pushl  0x18(%ebx)
f010077b:	ff 73 14             	pushl  0x14(%ebx)
f010077e:	ff 73 10             	pushl  0x10(%ebx)
f0100781:	ff 73 0c             	pushl  0xc(%ebx)
f0100784:	ff 73 08             	pushl  0x8(%ebx)
f0100787:	ff 73 04             	pushl  0x4(%ebx)
f010078a:	53                   	push   %ebx
f010078b:	68 48 1d 10 f0       	push   $0xf0101d48
f0100790:	e8 a0 01 00 00       	call   f0100935 <cprintf>
		test_ebp = (uint32_t*) *test_ebp;
f0100795:	8b 1b                	mov    (%ebx),%ebx
		cprintf("\n");
f0100797:	83 c4 14             	add    $0x14,%esp
f010079a:	68 4e 19 10 f0       	push   $0xf010194e
f010079f:	e8 91 01 00 00       	call   f0100935 <cprintf>
f01007a4:	83 c4 10             	add    $0x10,%esp
int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	uint32_t* test_ebp = (uint32_t*) read_ebp();
	cprintf("Stack backtrace:\n");
	while (test_ebp)
f01007a7:	85 db                	test   %ebx,%ebx
f01007a9:	75 cd                	jne    f0100778 <mon_backtrace+0x18>
		cprintf("  ebp %08x eip %08x args %08x %08x %08x %08x %08x",test_ebp, test_ebp[1],test_ebp[2],test_ebp[3],test_ebp[4],test_ebp[5], test_ebp[6]);
		test_ebp = (uint32_t*) *test_ebp;
		cprintf("\n");
	}
return 0;
}
f01007ab:	b8 00 00 00 00       	mov    $0x0,%eax
f01007b0:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01007b3:	c9                   	leave  
f01007b4:	c3                   	ret    

f01007b5 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007b5:	55                   	push   %ebp
f01007b6:	89 e5                	mov    %esp,%ebp
f01007b8:	57                   	push   %edi
f01007b9:	56                   	push   %esi
f01007ba:	53                   	push   %ebx
f01007bb:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007be:	68 7c 1d 10 f0       	push   $0xf0101d7c
f01007c3:	e8 6d 01 00 00       	call   f0100935 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007c8:	c7 04 24 a0 1d 10 f0 	movl   $0xf0101da0,(%esp)
f01007cf:	e8 61 01 00 00       	call   f0100935 <cprintf>
f01007d4:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f01007d7:	83 ec 0c             	sub    $0xc,%esp
f01007da:	68 00 1c 10 f0       	push   $0xf0101c00
f01007df:	e8 e3 09 00 00       	call   f01011c7 <readline>
f01007e4:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01007e6:	83 c4 10             	add    $0x10,%esp
f01007e9:	85 c0                	test   %eax,%eax
f01007eb:	74 ea                	je     f01007d7 <monitor+0x22>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01007ed:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01007f4:	be 00 00 00 00       	mov    $0x0,%esi
f01007f9:	eb 0a                	jmp    f0100805 <monitor+0x50>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01007fb:	c6 03 00             	movb   $0x0,(%ebx)
f01007fe:	89 f7                	mov    %esi,%edi
f0100800:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100803:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100805:	0f b6 03             	movzbl (%ebx),%eax
f0100808:	84 c0                	test   %al,%al
f010080a:	74 63                	je     f010086f <monitor+0xba>
f010080c:	83 ec 08             	sub    $0x8,%esp
f010080f:	0f be c0             	movsbl %al,%eax
f0100812:	50                   	push   %eax
f0100813:	68 04 1c 10 f0       	push   $0xf0101c04
f0100818:	e8 c4 0b 00 00       	call   f01013e1 <strchr>
f010081d:	83 c4 10             	add    $0x10,%esp
f0100820:	85 c0                	test   %eax,%eax
f0100822:	75 d7                	jne    f01007fb <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f0100824:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100827:	74 46                	je     f010086f <monitor+0xba>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100829:	83 fe 0f             	cmp    $0xf,%esi
f010082c:	75 14                	jne    f0100842 <monitor+0x8d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f010082e:	83 ec 08             	sub    $0x8,%esp
f0100831:	6a 10                	push   $0x10
f0100833:	68 09 1c 10 f0       	push   $0xf0101c09
f0100838:	e8 f8 00 00 00       	call   f0100935 <cprintf>
f010083d:	83 c4 10             	add    $0x10,%esp
f0100840:	eb 95                	jmp    f01007d7 <monitor+0x22>
			return 0;
		}
		argv[argc++] = buf;
f0100842:	8d 7e 01             	lea    0x1(%esi),%edi
f0100845:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100849:	eb 03                	jmp    f010084e <monitor+0x99>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f010084b:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010084e:	0f b6 03             	movzbl (%ebx),%eax
f0100851:	84 c0                	test   %al,%al
f0100853:	74 ae                	je     f0100803 <monitor+0x4e>
f0100855:	83 ec 08             	sub    $0x8,%esp
f0100858:	0f be c0             	movsbl %al,%eax
f010085b:	50                   	push   %eax
f010085c:	68 04 1c 10 f0       	push   $0xf0101c04
f0100861:	e8 7b 0b 00 00       	call   f01013e1 <strchr>
f0100866:	83 c4 10             	add    $0x10,%esp
f0100869:	85 c0                	test   %eax,%eax
f010086b:	74 de                	je     f010084b <monitor+0x96>
f010086d:	eb 94                	jmp    f0100803 <monitor+0x4e>
			buf++;
	}
	argv[argc] = 0;
f010086f:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100876:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100877:	85 f6                	test   %esi,%esi
f0100879:	0f 84 58 ff ff ff    	je     f01007d7 <monitor+0x22>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f010087f:	83 ec 08             	sub    $0x8,%esp
f0100882:	68 be 1b 10 f0       	push   $0xf0101bbe
f0100887:	ff 75 a8             	pushl  -0x58(%ebp)
f010088a:	e8 f4 0a 00 00       	call   f0101383 <strcmp>
f010088f:	83 c4 10             	add    $0x10,%esp
f0100892:	85 c0                	test   %eax,%eax
f0100894:	74 1e                	je     f01008b4 <monitor+0xff>
f0100896:	83 ec 08             	sub    $0x8,%esp
f0100899:	68 cc 1b 10 f0       	push   $0xf0101bcc
f010089e:	ff 75 a8             	pushl  -0x58(%ebp)
f01008a1:	e8 dd 0a 00 00       	call   f0101383 <strcmp>
f01008a6:	83 c4 10             	add    $0x10,%esp
f01008a9:	85 c0                	test   %eax,%eax
f01008ab:	75 2f                	jne    f01008dc <monitor+0x127>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f01008ad:	b8 01 00 00 00       	mov    $0x1,%eax
f01008b2:	eb 05                	jmp    f01008b9 <monitor+0x104>
		if (strcmp(argv[0], commands[i].name) == 0)
f01008b4:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f01008b9:	83 ec 04             	sub    $0x4,%esp
f01008bc:	8d 14 00             	lea    (%eax,%eax,1),%edx
f01008bf:	01 d0                	add    %edx,%eax
f01008c1:	ff 75 08             	pushl  0x8(%ebp)
f01008c4:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f01008c7:	51                   	push   %ecx
f01008c8:	56                   	push   %esi
f01008c9:	ff 14 85 d0 1d 10 f0 	call   *-0xfefe230(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008d0:	83 c4 10             	add    $0x10,%esp
f01008d3:	85 c0                	test   %eax,%eax
f01008d5:	78 1d                	js     f01008f4 <monitor+0x13f>
f01008d7:	e9 fb fe ff ff       	jmp    f01007d7 <monitor+0x22>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008dc:	83 ec 08             	sub    $0x8,%esp
f01008df:	ff 75 a8             	pushl  -0x58(%ebp)
f01008e2:	68 26 1c 10 f0       	push   $0xf0101c26
f01008e7:	e8 49 00 00 00       	call   f0100935 <cprintf>
f01008ec:	83 c4 10             	add    $0x10,%esp
f01008ef:	e9 e3 fe ff ff       	jmp    f01007d7 <monitor+0x22>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01008f4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01008f7:	5b                   	pop    %ebx
f01008f8:	5e                   	pop    %esi
f01008f9:	5f                   	pop    %edi
f01008fa:	5d                   	pop    %ebp
f01008fb:	c3                   	ret    

f01008fc <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01008fc:	55                   	push   %ebp
f01008fd:	89 e5                	mov    %esp,%ebp
f01008ff:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0100902:	ff 75 08             	pushl  0x8(%ebp)
f0100905:	e8 43 fd ff ff       	call   f010064d <cputchar>
	*cnt++;
}
f010090a:	83 c4 10             	add    $0x10,%esp
f010090d:	c9                   	leave  
f010090e:	c3                   	ret    

f010090f <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f010090f:	55                   	push   %ebp
f0100910:	89 e5                	mov    %esp,%ebp
f0100912:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0100915:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f010091c:	ff 75 0c             	pushl  0xc(%ebp)
f010091f:	ff 75 08             	pushl  0x8(%ebp)
f0100922:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100925:	50                   	push   %eax
f0100926:	68 fc 08 10 f0       	push   $0xf01008fc
f010092b:	e8 c9 03 00 00       	call   f0100cf9 <vprintfmt>
	return cnt;
}
f0100930:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100933:	c9                   	leave  
f0100934:	c3                   	ret    

f0100935 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100935:	55                   	push   %ebp
f0100936:	89 e5                	mov    %esp,%ebp
f0100938:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f010093b:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f010093e:	50                   	push   %eax
f010093f:	ff 75 08             	pushl  0x8(%ebp)
f0100942:	e8 c8 ff ff ff       	call   f010090f <vcprintf>
	va_end(ap);

	return cnt;
}
f0100947:	c9                   	leave  
f0100948:	c3                   	ret    

f0100949 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100949:	55                   	push   %ebp
f010094a:	89 e5                	mov    %esp,%ebp
f010094c:	57                   	push   %edi
f010094d:	56                   	push   %esi
f010094e:	53                   	push   %ebx
f010094f:	83 ec 14             	sub    $0x14,%esp
f0100952:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0100955:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100958:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010095b:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f010095e:	8b 1a                	mov    (%edx),%ebx
f0100960:	8b 01                	mov    (%ecx),%eax
f0100962:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100965:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f010096c:	eb 7f                	jmp    f01009ed <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f010096e:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100971:	01 d8                	add    %ebx,%eax
f0100973:	89 c6                	mov    %eax,%esi
f0100975:	c1 ee 1f             	shr    $0x1f,%esi
f0100978:	01 c6                	add    %eax,%esi
f010097a:	d1 fe                	sar    %esi
f010097c:	8d 04 76             	lea    (%esi,%esi,2),%eax
f010097f:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100982:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0100985:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100987:	eb 03                	jmp    f010098c <stab_binsearch+0x43>
			m--;
f0100989:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010098c:	39 c3                	cmp    %eax,%ebx
f010098e:	7f 0d                	jg     f010099d <stab_binsearch+0x54>
f0100990:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0100994:	83 ea 0c             	sub    $0xc,%edx
f0100997:	39 f9                	cmp    %edi,%ecx
f0100999:	75 ee                	jne    f0100989 <stab_binsearch+0x40>
f010099b:	eb 05                	jmp    f01009a2 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f010099d:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f01009a0:	eb 4b                	jmp    f01009ed <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01009a2:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01009a5:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01009a8:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01009ac:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01009af:	76 11                	jbe    f01009c2 <stab_binsearch+0x79>
			*region_left = m;
f01009b1:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01009b4:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01009b6:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01009b9:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01009c0:	eb 2b                	jmp    f01009ed <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01009c2:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01009c5:	73 14                	jae    f01009db <stab_binsearch+0x92>
			*region_right = m - 1;
f01009c7:	83 e8 01             	sub    $0x1,%eax
f01009ca:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01009cd:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01009d0:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01009d2:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01009d9:	eb 12                	jmp    f01009ed <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01009db:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01009de:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f01009e0:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01009e4:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01009e6:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01009ed:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01009f0:	0f 8e 78 ff ff ff    	jle    f010096e <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01009f6:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01009fa:	75 0f                	jne    f0100a0b <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f01009fc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01009ff:	8b 00                	mov    (%eax),%eax
f0100a01:	83 e8 01             	sub    $0x1,%eax
f0100a04:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100a07:	89 06                	mov    %eax,(%esi)
f0100a09:	eb 2c                	jmp    f0100a37 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a0b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a0e:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100a10:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100a13:	8b 0e                	mov    (%esi),%ecx
f0100a15:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100a18:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0100a1b:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a1e:	eb 03                	jmp    f0100a23 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100a20:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a23:	39 c8                	cmp    %ecx,%eax
f0100a25:	7e 0b                	jle    f0100a32 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0100a27:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0100a2b:	83 ea 0c             	sub    $0xc,%edx
f0100a2e:	39 df                	cmp    %ebx,%edi
f0100a30:	75 ee                	jne    f0100a20 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100a32:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100a35:	89 06                	mov    %eax,(%esi)
	}
}
f0100a37:	83 c4 14             	add    $0x14,%esp
f0100a3a:	5b                   	pop    %ebx
f0100a3b:	5e                   	pop    %esi
f0100a3c:	5f                   	pop    %edi
f0100a3d:	5d                   	pop    %ebp
f0100a3e:	c3                   	ret    

f0100a3f <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100a3f:	55                   	push   %ebp
f0100a40:	89 e5                	mov    %esp,%ebp
f0100a42:	57                   	push   %edi
f0100a43:	56                   	push   %esi
f0100a44:	53                   	push   %ebx
f0100a45:	83 ec 1c             	sub    $0x1c,%esp
f0100a48:	8b 7d 08             	mov    0x8(%ebp),%edi
f0100a4b:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100a4e:	c7 06 e0 1d 10 f0    	movl   $0xf0101de0,(%esi)
	info->eip_line = 0;
f0100a54:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0100a5b:	c7 46 08 e0 1d 10 f0 	movl   $0xf0101de0,0x8(%esi)
	info->eip_fn_namelen = 9;
f0100a62:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f0100a69:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0100a6c:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100a73:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0100a79:	76 11                	jbe    f0100a8c <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100a7b:	b8 56 72 10 f0       	mov    $0xf0107256,%eax
f0100a80:	3d 79 59 10 f0       	cmp    $0xf0105979,%eax
f0100a85:	77 19                	ja     f0100aa0 <debuginfo_eip+0x61>
f0100a87:	e9 62 01 00 00       	jmp    f0100bee <debuginfo_eip+0x1af>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100a8c:	83 ec 04             	sub    $0x4,%esp
f0100a8f:	68 ea 1d 10 f0       	push   $0xf0101dea
f0100a94:	6a 7f                	push   $0x7f
f0100a96:	68 f7 1d 10 f0       	push   $0xf0101df7
f0100a9b:	e8 46 f6 ff ff       	call   f01000e6 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100aa0:	80 3d 55 72 10 f0 00 	cmpb   $0x0,0xf0107255
f0100aa7:	0f 85 48 01 00 00    	jne    f0100bf5 <debuginfo_eip+0x1b6>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100aad:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100ab4:	b8 78 59 10 f0       	mov    $0xf0105978,%eax
f0100ab9:	2d 30 20 10 f0       	sub    $0xf0102030,%eax
f0100abe:	c1 f8 02             	sar    $0x2,%eax
f0100ac1:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100ac7:	83 e8 01             	sub    $0x1,%eax
f0100aca:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100acd:	83 ec 08             	sub    $0x8,%esp
f0100ad0:	57                   	push   %edi
f0100ad1:	6a 64                	push   $0x64
f0100ad3:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100ad6:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100ad9:	b8 30 20 10 f0       	mov    $0xf0102030,%eax
f0100ade:	e8 66 fe ff ff       	call   f0100949 <stab_binsearch>
	if (lfile == 0)
f0100ae3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ae6:	83 c4 10             	add    $0x10,%esp
f0100ae9:	85 c0                	test   %eax,%eax
f0100aeb:	0f 84 0b 01 00 00    	je     f0100bfc <debuginfo_eip+0x1bd>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100af1:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100af4:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100af7:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100afa:	83 ec 08             	sub    $0x8,%esp
f0100afd:	57                   	push   %edi
f0100afe:	6a 24                	push   $0x24
f0100b00:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100b03:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100b06:	b8 30 20 10 f0       	mov    $0xf0102030,%eax
f0100b0b:	e8 39 fe ff ff       	call   f0100949 <stab_binsearch>

	if (lfun <= rfun) {
f0100b10:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100b13:	83 c4 10             	add    $0x10,%esp
f0100b16:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f0100b19:	7f 31                	jg     f0100b4c <debuginfo_eip+0x10d>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100b1b:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100b1e:	c1 e0 02             	shl    $0x2,%eax
f0100b21:	8d 90 30 20 10 f0    	lea    -0xfefdfd0(%eax),%edx
f0100b27:	8b 88 30 20 10 f0    	mov    -0xfefdfd0(%eax),%ecx
f0100b2d:	b8 56 72 10 f0       	mov    $0xf0107256,%eax
f0100b32:	2d 79 59 10 f0       	sub    $0xf0105979,%eax
f0100b37:	39 c1                	cmp    %eax,%ecx
f0100b39:	73 09                	jae    f0100b44 <debuginfo_eip+0x105>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100b3b:	81 c1 79 59 10 f0    	add    $0xf0105979,%ecx
f0100b41:	89 4e 08             	mov    %ecx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100b44:	8b 42 08             	mov    0x8(%edx),%eax
f0100b47:	89 46 10             	mov    %eax,0x10(%esi)
f0100b4a:	eb 06                	jmp    f0100b52 <debuginfo_eip+0x113>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100b4c:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0100b4f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100b52:	83 ec 08             	sub    $0x8,%esp
f0100b55:	6a 3a                	push   $0x3a
f0100b57:	ff 76 08             	pushl  0x8(%esi)
f0100b5a:	e8 a3 08 00 00       	call   f0101402 <strfind>
f0100b5f:	2b 46 08             	sub    0x8(%esi),%eax
f0100b62:	89 46 0c             	mov    %eax,0xc(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100b65:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100b68:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100b6b:	8d 04 85 30 20 10 f0 	lea    -0xfefdfd0(,%eax,4),%eax
f0100b72:	83 c4 10             	add    $0x10,%esp
f0100b75:	eb 06                	jmp    f0100b7d <debuginfo_eip+0x13e>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100b77:	83 eb 01             	sub    $0x1,%ebx
f0100b7a:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100b7d:	39 fb                	cmp    %edi,%ebx
f0100b7f:	7c 34                	jl     f0100bb5 <debuginfo_eip+0x176>
	       && stabs[lline].n_type != N_SOL
f0100b81:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f0100b85:	80 fa 84             	cmp    $0x84,%dl
f0100b88:	74 0b                	je     f0100b95 <debuginfo_eip+0x156>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100b8a:	80 fa 64             	cmp    $0x64,%dl
f0100b8d:	75 e8                	jne    f0100b77 <debuginfo_eip+0x138>
f0100b8f:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0100b93:	74 e2                	je     f0100b77 <debuginfo_eip+0x138>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100b95:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100b98:	8b 14 85 30 20 10 f0 	mov    -0xfefdfd0(,%eax,4),%edx
f0100b9f:	b8 56 72 10 f0       	mov    $0xf0107256,%eax
f0100ba4:	2d 79 59 10 f0       	sub    $0xf0105979,%eax
f0100ba9:	39 c2                	cmp    %eax,%edx
f0100bab:	73 08                	jae    f0100bb5 <debuginfo_eip+0x176>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100bad:	81 c2 79 59 10 f0    	add    $0xf0105979,%edx
f0100bb3:	89 16                	mov    %edx,(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100bb5:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100bb8:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100bbb:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100bc0:	39 cb                	cmp    %ecx,%ebx
f0100bc2:	7d 44                	jge    f0100c08 <debuginfo_eip+0x1c9>
		for (lline = lfun + 1;
f0100bc4:	8d 53 01             	lea    0x1(%ebx),%edx
f0100bc7:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100bca:	8d 04 85 30 20 10 f0 	lea    -0xfefdfd0(,%eax,4),%eax
f0100bd1:	eb 07                	jmp    f0100bda <debuginfo_eip+0x19b>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100bd3:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0100bd7:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100bda:	39 ca                	cmp    %ecx,%edx
f0100bdc:	74 25                	je     f0100c03 <debuginfo_eip+0x1c4>
f0100bde:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100be1:	80 78 04 a0          	cmpb   $0xa0,0x4(%eax)
f0100be5:	74 ec                	je     f0100bd3 <debuginfo_eip+0x194>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100be7:	b8 00 00 00 00       	mov    $0x0,%eax
f0100bec:	eb 1a                	jmp    f0100c08 <debuginfo_eip+0x1c9>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100bee:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100bf3:	eb 13                	jmp    f0100c08 <debuginfo_eip+0x1c9>
f0100bf5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100bfa:	eb 0c                	jmp    f0100c08 <debuginfo_eip+0x1c9>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100bfc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c01:	eb 05                	jmp    f0100c08 <debuginfo_eip+0x1c9>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c03:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100c08:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100c0b:	5b                   	pop    %ebx
f0100c0c:	5e                   	pop    %esi
f0100c0d:	5f                   	pop    %edi
f0100c0e:	5d                   	pop    %ebp
f0100c0f:	c3                   	ret    

f0100c10 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100c10:	55                   	push   %ebp
f0100c11:	89 e5                	mov    %esp,%ebp
f0100c13:	57                   	push   %edi
f0100c14:	56                   	push   %esi
f0100c15:	53                   	push   %ebx
f0100c16:	83 ec 1c             	sub    $0x1c,%esp
f0100c19:	89 c7                	mov    %eax,%edi
f0100c1b:	89 d6                	mov    %edx,%esi
f0100c1d:	8b 45 08             	mov    0x8(%ebp),%eax
f0100c20:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100c23:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100c26:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100c29:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0100c2c:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100c31:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100c34:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0100c37:	39 d3                	cmp    %edx,%ebx
f0100c39:	72 05                	jb     f0100c40 <printnum+0x30>
f0100c3b:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100c3e:	77 45                	ja     f0100c85 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100c40:	83 ec 0c             	sub    $0xc,%esp
f0100c43:	ff 75 18             	pushl  0x18(%ebp)
f0100c46:	8b 45 14             	mov    0x14(%ebp),%eax
f0100c49:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0100c4c:	53                   	push   %ebx
f0100c4d:	ff 75 10             	pushl  0x10(%ebp)
f0100c50:	83 ec 08             	sub    $0x8,%esp
f0100c53:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100c56:	ff 75 e0             	pushl  -0x20(%ebp)
f0100c59:	ff 75 dc             	pushl  -0x24(%ebp)
f0100c5c:	ff 75 d8             	pushl  -0x28(%ebp)
f0100c5f:	e8 bc 09 00 00       	call   f0101620 <__udivdi3>
f0100c64:	83 c4 18             	add    $0x18,%esp
f0100c67:	52                   	push   %edx
f0100c68:	50                   	push   %eax
f0100c69:	89 f2                	mov    %esi,%edx
f0100c6b:	89 f8                	mov    %edi,%eax
f0100c6d:	e8 9e ff ff ff       	call   f0100c10 <printnum>
f0100c72:	83 c4 20             	add    $0x20,%esp
f0100c75:	eb 18                	jmp    f0100c8f <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100c77:	83 ec 08             	sub    $0x8,%esp
f0100c7a:	56                   	push   %esi
f0100c7b:	ff 75 18             	pushl  0x18(%ebp)
f0100c7e:	ff d7                	call   *%edi
f0100c80:	83 c4 10             	add    $0x10,%esp
f0100c83:	eb 03                	jmp    f0100c88 <printnum+0x78>
f0100c85:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100c88:	83 eb 01             	sub    $0x1,%ebx
f0100c8b:	85 db                	test   %ebx,%ebx
f0100c8d:	7f e8                	jg     f0100c77 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100c8f:	83 ec 08             	sub    $0x8,%esp
f0100c92:	56                   	push   %esi
f0100c93:	83 ec 04             	sub    $0x4,%esp
f0100c96:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100c99:	ff 75 e0             	pushl  -0x20(%ebp)
f0100c9c:	ff 75 dc             	pushl  -0x24(%ebp)
f0100c9f:	ff 75 d8             	pushl  -0x28(%ebp)
f0100ca2:	e8 a9 0a 00 00       	call   f0101750 <__umoddi3>
f0100ca7:	83 c4 14             	add    $0x14,%esp
f0100caa:	0f be 80 05 1e 10 f0 	movsbl -0xfefe1fb(%eax),%eax
f0100cb1:	50                   	push   %eax
f0100cb2:	ff d7                	call   *%edi
}
f0100cb4:	83 c4 10             	add    $0x10,%esp
f0100cb7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100cba:	5b                   	pop    %ebx
f0100cbb:	5e                   	pop    %esi
f0100cbc:	5f                   	pop    %edi
f0100cbd:	5d                   	pop    %ebp
f0100cbe:	c3                   	ret    

f0100cbf <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100cbf:	55                   	push   %ebp
f0100cc0:	89 e5                	mov    %esp,%ebp
f0100cc2:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100cc5:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100cc9:	8b 10                	mov    (%eax),%edx
f0100ccb:	3b 50 04             	cmp    0x4(%eax),%edx
f0100cce:	73 0a                	jae    f0100cda <sprintputch+0x1b>
		*b->buf++ = ch;
f0100cd0:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100cd3:	89 08                	mov    %ecx,(%eax)
f0100cd5:	8b 45 08             	mov    0x8(%ebp),%eax
f0100cd8:	88 02                	mov    %al,(%edx)
}
f0100cda:	5d                   	pop    %ebp
f0100cdb:	c3                   	ret    

f0100cdc <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100cdc:	55                   	push   %ebp
f0100cdd:	89 e5                	mov    %esp,%ebp
f0100cdf:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100ce2:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100ce5:	50                   	push   %eax
f0100ce6:	ff 75 10             	pushl  0x10(%ebp)
f0100ce9:	ff 75 0c             	pushl  0xc(%ebp)
f0100cec:	ff 75 08             	pushl  0x8(%ebp)
f0100cef:	e8 05 00 00 00       	call   f0100cf9 <vprintfmt>
	va_end(ap);
}
f0100cf4:	83 c4 10             	add    $0x10,%esp
f0100cf7:	c9                   	leave  
f0100cf8:	c3                   	ret    

f0100cf9 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100cf9:	55                   	push   %ebp
f0100cfa:	89 e5                	mov    %esp,%ebp
f0100cfc:	57                   	push   %edi
f0100cfd:	56                   	push   %esi
f0100cfe:	53                   	push   %ebx
f0100cff:	83 ec 2c             	sub    $0x2c,%esp
f0100d02:	8b 75 08             	mov    0x8(%ebp),%esi
f0100d05:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100d08:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100d0b:	eb 12                	jmp    f0100d1f <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100d0d:	85 c0                	test   %eax,%eax
f0100d0f:	0f 84 42 04 00 00    	je     f0101157 <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
f0100d15:	83 ec 08             	sub    $0x8,%esp
f0100d18:	53                   	push   %ebx
f0100d19:	50                   	push   %eax
f0100d1a:	ff d6                	call   *%esi
f0100d1c:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100d1f:	83 c7 01             	add    $0x1,%edi
f0100d22:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0100d26:	83 f8 25             	cmp    $0x25,%eax
f0100d29:	75 e2                	jne    f0100d0d <vprintfmt+0x14>
f0100d2b:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0100d2f:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100d36:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100d3d:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0100d44:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100d49:	eb 07                	jmp    f0100d52 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100d4b:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100d4e:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100d52:	8d 47 01             	lea    0x1(%edi),%eax
f0100d55:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100d58:	0f b6 07             	movzbl (%edi),%eax
f0100d5b:	0f b6 d0             	movzbl %al,%edx
f0100d5e:	83 e8 23             	sub    $0x23,%eax
f0100d61:	3c 55                	cmp    $0x55,%al
f0100d63:	0f 87 d3 03 00 00    	ja     f010113c <vprintfmt+0x443>
f0100d69:	0f b6 c0             	movzbl %al,%eax
f0100d6c:	ff 24 85 a0 1e 10 f0 	jmp    *-0xfefe160(,%eax,4)
f0100d73:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100d76:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0100d7a:	eb d6                	jmp    f0100d52 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100d7c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100d7f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d84:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100d87:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100d8a:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0100d8e:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0100d91:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0100d94:	83 f9 09             	cmp    $0x9,%ecx
f0100d97:	77 3f                	ja     f0100dd8 <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100d99:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0100d9c:	eb e9                	jmp    f0100d87 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100d9e:	8b 45 14             	mov    0x14(%ebp),%eax
f0100da1:	8b 00                	mov    (%eax),%eax
f0100da3:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100da6:	8b 45 14             	mov    0x14(%ebp),%eax
f0100da9:	8d 40 04             	lea    0x4(%eax),%eax
f0100dac:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100daf:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100db2:	eb 2a                	jmp    f0100dde <vprintfmt+0xe5>
f0100db4:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100db7:	85 c0                	test   %eax,%eax
f0100db9:	ba 00 00 00 00       	mov    $0x0,%edx
f0100dbe:	0f 49 d0             	cmovns %eax,%edx
f0100dc1:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100dc4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100dc7:	eb 89                	jmp    f0100d52 <vprintfmt+0x59>
f0100dc9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100dcc:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0100dd3:	e9 7a ff ff ff       	jmp    f0100d52 <vprintfmt+0x59>
f0100dd8:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100ddb:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0100dde:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100de2:	0f 89 6a ff ff ff    	jns    f0100d52 <vprintfmt+0x59>
				width = precision, precision = -1;
f0100de8:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100deb:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100dee:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100df5:	e9 58 ff ff ff       	jmp    f0100d52 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100dfa:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100dfd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100e00:	e9 4d ff ff ff       	jmp    f0100d52 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100e05:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e08:	8d 78 04             	lea    0x4(%eax),%edi
f0100e0b:	83 ec 08             	sub    $0x8,%esp
f0100e0e:	53                   	push   %ebx
f0100e0f:	ff 30                	pushl  (%eax)
f0100e11:	ff d6                	call   *%esi
			break;
f0100e13:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100e16:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e19:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0100e1c:	e9 fe fe ff ff       	jmp    f0100d1f <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100e21:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e24:	8d 78 04             	lea    0x4(%eax),%edi
f0100e27:	8b 00                	mov    (%eax),%eax
f0100e29:	99                   	cltd   
f0100e2a:	31 d0                	xor    %edx,%eax
f0100e2c:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100e2e:	83 f8 07             	cmp    $0x7,%eax
f0100e31:	7f 0b                	jg     f0100e3e <vprintfmt+0x145>
f0100e33:	8b 14 85 00 20 10 f0 	mov    -0xfefe000(,%eax,4),%edx
f0100e3a:	85 d2                	test   %edx,%edx
f0100e3c:	75 1b                	jne    f0100e59 <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
f0100e3e:	50                   	push   %eax
f0100e3f:	68 1d 1e 10 f0       	push   $0xf0101e1d
f0100e44:	53                   	push   %ebx
f0100e45:	56                   	push   %esi
f0100e46:	e8 91 fe ff ff       	call   f0100cdc <printfmt>
f0100e4b:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100e4e:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e51:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0100e54:	e9 c6 fe ff ff       	jmp    f0100d1f <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0100e59:	52                   	push   %edx
f0100e5a:	68 26 1e 10 f0       	push   $0xf0101e26
f0100e5f:	53                   	push   %ebx
f0100e60:	56                   	push   %esi
f0100e61:	e8 76 fe ff ff       	call   f0100cdc <printfmt>
f0100e66:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100e69:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e6c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100e6f:	e9 ab fe ff ff       	jmp    f0100d1f <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100e74:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e77:	83 c0 04             	add    $0x4,%eax
f0100e7a:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0100e7d:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e80:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0100e82:	85 ff                	test   %edi,%edi
f0100e84:	b8 16 1e 10 f0       	mov    $0xf0101e16,%eax
f0100e89:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0100e8c:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100e90:	0f 8e 94 00 00 00    	jle    f0100f2a <vprintfmt+0x231>
f0100e96:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0100e9a:	0f 84 98 00 00 00    	je     f0100f38 <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
f0100ea0:	83 ec 08             	sub    $0x8,%esp
f0100ea3:	ff 75 d0             	pushl  -0x30(%ebp)
f0100ea6:	57                   	push   %edi
f0100ea7:	e8 0c 04 00 00       	call   f01012b8 <strnlen>
f0100eac:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100eaf:	29 c1                	sub    %eax,%ecx
f0100eb1:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f0100eb4:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0100eb7:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0100ebb:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100ebe:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0100ec1:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100ec3:	eb 0f                	jmp    f0100ed4 <vprintfmt+0x1db>
					putch(padc, putdat);
f0100ec5:	83 ec 08             	sub    $0x8,%esp
f0100ec8:	53                   	push   %ebx
f0100ec9:	ff 75 e0             	pushl  -0x20(%ebp)
f0100ecc:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100ece:	83 ef 01             	sub    $0x1,%edi
f0100ed1:	83 c4 10             	add    $0x10,%esp
f0100ed4:	85 ff                	test   %edi,%edi
f0100ed6:	7f ed                	jg     f0100ec5 <vprintfmt+0x1cc>
f0100ed8:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0100edb:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0100ede:	85 c9                	test   %ecx,%ecx
f0100ee0:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ee5:	0f 49 c1             	cmovns %ecx,%eax
f0100ee8:	29 c1                	sub    %eax,%ecx
f0100eea:	89 75 08             	mov    %esi,0x8(%ebp)
f0100eed:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100ef0:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100ef3:	89 cb                	mov    %ecx,%ebx
f0100ef5:	eb 4d                	jmp    f0100f44 <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0100ef7:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0100efb:	74 1b                	je     f0100f18 <vprintfmt+0x21f>
f0100efd:	0f be c0             	movsbl %al,%eax
f0100f00:	83 e8 20             	sub    $0x20,%eax
f0100f03:	83 f8 5e             	cmp    $0x5e,%eax
f0100f06:	76 10                	jbe    f0100f18 <vprintfmt+0x21f>
					putch('?', putdat);
f0100f08:	83 ec 08             	sub    $0x8,%esp
f0100f0b:	ff 75 0c             	pushl  0xc(%ebp)
f0100f0e:	6a 3f                	push   $0x3f
f0100f10:	ff 55 08             	call   *0x8(%ebp)
f0100f13:	83 c4 10             	add    $0x10,%esp
f0100f16:	eb 0d                	jmp    f0100f25 <vprintfmt+0x22c>
				else
					putch(ch, putdat);
f0100f18:	83 ec 08             	sub    $0x8,%esp
f0100f1b:	ff 75 0c             	pushl  0xc(%ebp)
f0100f1e:	52                   	push   %edx
f0100f1f:	ff 55 08             	call   *0x8(%ebp)
f0100f22:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100f25:	83 eb 01             	sub    $0x1,%ebx
f0100f28:	eb 1a                	jmp    f0100f44 <vprintfmt+0x24b>
f0100f2a:	89 75 08             	mov    %esi,0x8(%ebp)
f0100f2d:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100f30:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100f33:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100f36:	eb 0c                	jmp    f0100f44 <vprintfmt+0x24b>
f0100f38:	89 75 08             	mov    %esi,0x8(%ebp)
f0100f3b:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100f3e:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100f41:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100f44:	83 c7 01             	add    $0x1,%edi
f0100f47:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0100f4b:	0f be d0             	movsbl %al,%edx
f0100f4e:	85 d2                	test   %edx,%edx
f0100f50:	74 23                	je     f0100f75 <vprintfmt+0x27c>
f0100f52:	85 f6                	test   %esi,%esi
f0100f54:	78 a1                	js     f0100ef7 <vprintfmt+0x1fe>
f0100f56:	83 ee 01             	sub    $0x1,%esi
f0100f59:	79 9c                	jns    f0100ef7 <vprintfmt+0x1fe>
f0100f5b:	89 df                	mov    %ebx,%edi
f0100f5d:	8b 75 08             	mov    0x8(%ebp),%esi
f0100f60:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100f63:	eb 18                	jmp    f0100f7d <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0100f65:	83 ec 08             	sub    $0x8,%esp
f0100f68:	53                   	push   %ebx
f0100f69:	6a 20                	push   $0x20
f0100f6b:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0100f6d:	83 ef 01             	sub    $0x1,%edi
f0100f70:	83 c4 10             	add    $0x10,%esp
f0100f73:	eb 08                	jmp    f0100f7d <vprintfmt+0x284>
f0100f75:	89 df                	mov    %ebx,%edi
f0100f77:	8b 75 08             	mov    0x8(%ebp),%esi
f0100f7a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100f7d:	85 ff                	test   %edi,%edi
f0100f7f:	7f e4                	jg     f0100f65 <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100f81:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0100f84:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f87:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100f8a:	e9 90 fd ff ff       	jmp    f0100d1f <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0100f8f:	83 f9 01             	cmp    $0x1,%ecx
f0100f92:	7e 19                	jle    f0100fad <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
f0100f94:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f97:	8b 50 04             	mov    0x4(%eax),%edx
f0100f9a:	8b 00                	mov    (%eax),%eax
f0100f9c:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100f9f:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0100fa2:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fa5:	8d 40 08             	lea    0x8(%eax),%eax
f0100fa8:	89 45 14             	mov    %eax,0x14(%ebp)
f0100fab:	eb 38                	jmp    f0100fe5 <vprintfmt+0x2ec>
	else if (lflag)
f0100fad:	85 c9                	test   %ecx,%ecx
f0100faf:	74 1b                	je     f0100fcc <vprintfmt+0x2d3>
		return va_arg(*ap, long);
f0100fb1:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fb4:	8b 00                	mov    (%eax),%eax
f0100fb6:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100fb9:	89 c1                	mov    %eax,%ecx
f0100fbb:	c1 f9 1f             	sar    $0x1f,%ecx
f0100fbe:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100fc1:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fc4:	8d 40 04             	lea    0x4(%eax),%eax
f0100fc7:	89 45 14             	mov    %eax,0x14(%ebp)
f0100fca:	eb 19                	jmp    f0100fe5 <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
f0100fcc:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fcf:	8b 00                	mov    (%eax),%eax
f0100fd1:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100fd4:	89 c1                	mov    %eax,%ecx
f0100fd6:	c1 f9 1f             	sar    $0x1f,%ecx
f0100fd9:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100fdc:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fdf:	8d 40 04             	lea    0x4(%eax),%eax
f0100fe2:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0100fe5:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100fe8:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0100feb:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0100ff0:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0100ff4:	0f 89 0e 01 00 00    	jns    f0101108 <vprintfmt+0x40f>
				putch('-', putdat);
f0100ffa:	83 ec 08             	sub    $0x8,%esp
f0100ffd:	53                   	push   %ebx
f0100ffe:	6a 2d                	push   $0x2d
f0101000:	ff d6                	call   *%esi
				num = -(long long) num;
f0101002:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101005:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0101008:	f7 da                	neg    %edx
f010100a:	83 d1 00             	adc    $0x0,%ecx
f010100d:	f7 d9                	neg    %ecx
f010100f:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0101012:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101017:	e9 ec 00 00 00       	jmp    f0101108 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f010101c:	83 f9 01             	cmp    $0x1,%ecx
f010101f:	7e 18                	jle    f0101039 <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
f0101021:	8b 45 14             	mov    0x14(%ebp),%eax
f0101024:	8b 10                	mov    (%eax),%edx
f0101026:	8b 48 04             	mov    0x4(%eax),%ecx
f0101029:	8d 40 08             	lea    0x8(%eax),%eax
f010102c:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f010102f:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101034:	e9 cf 00 00 00       	jmp    f0101108 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0101039:	85 c9                	test   %ecx,%ecx
f010103b:	74 1a                	je     f0101057 <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
f010103d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101040:	8b 10                	mov    (%eax),%edx
f0101042:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101047:	8d 40 04             	lea    0x4(%eax),%eax
f010104a:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f010104d:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101052:	e9 b1 00 00 00       	jmp    f0101108 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0101057:	8b 45 14             	mov    0x14(%ebp),%eax
f010105a:	8b 10                	mov    (%eax),%edx
f010105c:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101061:	8d 40 04             	lea    0x4(%eax),%eax
f0101064:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0101067:	b8 0a 00 00 00       	mov    $0xa,%eax
f010106c:	e9 97 00 00 00       	jmp    f0101108 <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f0101071:	83 ec 08             	sub    $0x8,%esp
f0101074:	53                   	push   %ebx
f0101075:	6a 58                	push   $0x58
f0101077:	ff d6                	call   *%esi
			putch('X', putdat);
f0101079:	83 c4 08             	add    $0x8,%esp
f010107c:	53                   	push   %ebx
f010107d:	6a 58                	push   $0x58
f010107f:	ff d6                	call   *%esi
			putch('X', putdat);
f0101081:	83 c4 08             	add    $0x8,%esp
f0101084:	53                   	push   %ebx
f0101085:	6a 58                	push   $0x58
f0101087:	ff d6                	call   *%esi
			break;
f0101089:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010108c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
f010108f:	e9 8b fc ff ff       	jmp    f0100d1f <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
f0101094:	83 ec 08             	sub    $0x8,%esp
f0101097:	53                   	push   %ebx
f0101098:	6a 30                	push   $0x30
f010109a:	ff d6                	call   *%esi
			putch('x', putdat);
f010109c:	83 c4 08             	add    $0x8,%esp
f010109f:	53                   	push   %ebx
f01010a0:	6a 78                	push   $0x78
f01010a2:	ff d6                	call   *%esi
			num = (unsigned long long)
f01010a4:	8b 45 14             	mov    0x14(%ebp),%eax
f01010a7:	8b 10                	mov    (%eax),%edx
f01010a9:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f01010ae:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01010b1:	8d 40 04             	lea    0x4(%eax),%eax
f01010b4:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01010b7:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f01010bc:	eb 4a                	jmp    f0101108 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01010be:	83 f9 01             	cmp    $0x1,%ecx
f01010c1:	7e 15                	jle    f01010d8 <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
f01010c3:	8b 45 14             	mov    0x14(%ebp),%eax
f01010c6:	8b 10                	mov    (%eax),%edx
f01010c8:	8b 48 04             	mov    0x4(%eax),%ecx
f01010cb:	8d 40 08             	lea    0x8(%eax),%eax
f01010ce:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f01010d1:	b8 10 00 00 00       	mov    $0x10,%eax
f01010d6:	eb 30                	jmp    f0101108 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f01010d8:	85 c9                	test   %ecx,%ecx
f01010da:	74 17                	je     f01010f3 <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
f01010dc:	8b 45 14             	mov    0x14(%ebp),%eax
f01010df:	8b 10                	mov    (%eax),%edx
f01010e1:	b9 00 00 00 00       	mov    $0x0,%ecx
f01010e6:	8d 40 04             	lea    0x4(%eax),%eax
f01010e9:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f01010ec:	b8 10 00 00 00       	mov    $0x10,%eax
f01010f1:	eb 15                	jmp    f0101108 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f01010f3:	8b 45 14             	mov    0x14(%ebp),%eax
f01010f6:	8b 10                	mov    (%eax),%edx
f01010f8:	b9 00 00 00 00       	mov    $0x0,%ecx
f01010fd:	8d 40 04             	lea    0x4(%eax),%eax
f0101100:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0101103:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101108:	83 ec 0c             	sub    $0xc,%esp
f010110b:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f010110f:	57                   	push   %edi
f0101110:	ff 75 e0             	pushl  -0x20(%ebp)
f0101113:	50                   	push   %eax
f0101114:	51                   	push   %ecx
f0101115:	52                   	push   %edx
f0101116:	89 da                	mov    %ebx,%edx
f0101118:	89 f0                	mov    %esi,%eax
f010111a:	e8 f1 fa ff ff       	call   f0100c10 <printnum>
			break;
f010111f:	83 c4 20             	add    $0x20,%esp
f0101122:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101125:	e9 f5 fb ff ff       	jmp    f0100d1f <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f010112a:	83 ec 08             	sub    $0x8,%esp
f010112d:	53                   	push   %ebx
f010112e:	52                   	push   %edx
f010112f:	ff d6                	call   *%esi
			break;
f0101131:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101134:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0101137:	e9 e3 fb ff ff       	jmp    f0100d1f <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f010113c:	83 ec 08             	sub    $0x8,%esp
f010113f:	53                   	push   %ebx
f0101140:	6a 25                	push   $0x25
f0101142:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101144:	83 c4 10             	add    $0x10,%esp
f0101147:	eb 03                	jmp    f010114c <vprintfmt+0x453>
f0101149:	83 ef 01             	sub    $0x1,%edi
f010114c:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0101150:	75 f7                	jne    f0101149 <vprintfmt+0x450>
f0101152:	e9 c8 fb ff ff       	jmp    f0100d1f <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0101157:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010115a:	5b                   	pop    %ebx
f010115b:	5e                   	pop    %esi
f010115c:	5f                   	pop    %edi
f010115d:	5d                   	pop    %ebp
f010115e:	c3                   	ret    

f010115f <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f010115f:	55                   	push   %ebp
f0101160:	89 e5                	mov    %esp,%ebp
f0101162:	83 ec 18             	sub    $0x18,%esp
f0101165:	8b 45 08             	mov    0x8(%ebp),%eax
f0101168:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010116b:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010116e:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101172:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101175:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010117c:	85 c0                	test   %eax,%eax
f010117e:	74 26                	je     f01011a6 <vsnprintf+0x47>
f0101180:	85 d2                	test   %edx,%edx
f0101182:	7e 22                	jle    f01011a6 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101184:	ff 75 14             	pushl  0x14(%ebp)
f0101187:	ff 75 10             	pushl  0x10(%ebp)
f010118a:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010118d:	50                   	push   %eax
f010118e:	68 bf 0c 10 f0       	push   $0xf0100cbf
f0101193:	e8 61 fb ff ff       	call   f0100cf9 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101198:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010119b:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010119e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01011a1:	83 c4 10             	add    $0x10,%esp
f01011a4:	eb 05                	jmp    f01011ab <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01011a6:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01011ab:	c9                   	leave  
f01011ac:	c3                   	ret    

f01011ad <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01011ad:	55                   	push   %ebp
f01011ae:	89 e5                	mov    %esp,%ebp
f01011b0:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01011b3:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01011b6:	50                   	push   %eax
f01011b7:	ff 75 10             	pushl  0x10(%ebp)
f01011ba:	ff 75 0c             	pushl  0xc(%ebp)
f01011bd:	ff 75 08             	pushl  0x8(%ebp)
f01011c0:	e8 9a ff ff ff       	call   f010115f <vsnprintf>
	va_end(ap);

	return rc;
}
f01011c5:	c9                   	leave  
f01011c6:	c3                   	ret    

f01011c7 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01011c7:	55                   	push   %ebp
f01011c8:	89 e5                	mov    %esp,%ebp
f01011ca:	57                   	push   %edi
f01011cb:	56                   	push   %esi
f01011cc:	53                   	push   %ebx
f01011cd:	83 ec 0c             	sub    $0xc,%esp
f01011d0:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01011d3:	85 c0                	test   %eax,%eax
f01011d5:	74 11                	je     f01011e8 <readline+0x21>
		cprintf("%s", prompt);
f01011d7:	83 ec 08             	sub    $0x8,%esp
f01011da:	50                   	push   %eax
f01011db:	68 26 1e 10 f0       	push   $0xf0101e26
f01011e0:	e8 50 f7 ff ff       	call   f0100935 <cprintf>
f01011e5:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f01011e8:	83 ec 0c             	sub    $0xc,%esp
f01011eb:	6a 00                	push   $0x0
f01011ed:	e8 7c f4 ff ff       	call   f010066e <iscons>
f01011f2:	89 c7                	mov    %eax,%edi
f01011f4:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01011f7:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01011fc:	e8 5c f4 ff ff       	call   f010065d <getchar>
f0101201:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0101203:	85 c0                	test   %eax,%eax
f0101205:	79 18                	jns    f010121f <readline+0x58>
			cprintf("read error: %e\n", c);
f0101207:	83 ec 08             	sub    $0x8,%esp
f010120a:	50                   	push   %eax
f010120b:	68 20 20 10 f0       	push   $0xf0102020
f0101210:	e8 20 f7 ff ff       	call   f0100935 <cprintf>
			return NULL;
f0101215:	83 c4 10             	add    $0x10,%esp
f0101218:	b8 00 00 00 00       	mov    $0x0,%eax
f010121d:	eb 79                	jmp    f0101298 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f010121f:	83 f8 08             	cmp    $0x8,%eax
f0101222:	0f 94 c2             	sete   %dl
f0101225:	83 f8 7f             	cmp    $0x7f,%eax
f0101228:	0f 94 c0             	sete   %al
f010122b:	08 c2                	or     %al,%dl
f010122d:	74 1a                	je     f0101249 <readline+0x82>
f010122f:	85 f6                	test   %esi,%esi
f0101231:	7e 16                	jle    f0101249 <readline+0x82>
			if (echoing)
f0101233:	85 ff                	test   %edi,%edi
f0101235:	74 0d                	je     f0101244 <readline+0x7d>
				cputchar('\b');
f0101237:	83 ec 0c             	sub    $0xc,%esp
f010123a:	6a 08                	push   $0x8
f010123c:	e8 0c f4 ff ff       	call   f010064d <cputchar>
f0101241:	83 c4 10             	add    $0x10,%esp
			i--;
f0101244:	83 ee 01             	sub    $0x1,%esi
f0101247:	eb b3                	jmp    f01011fc <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101249:	83 fb 1f             	cmp    $0x1f,%ebx
f010124c:	7e 23                	jle    f0101271 <readline+0xaa>
f010124e:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0101254:	7f 1b                	jg     f0101271 <readline+0xaa>
			if (echoing)
f0101256:	85 ff                	test   %edi,%edi
f0101258:	74 0c                	je     f0101266 <readline+0x9f>
				cputchar(c);
f010125a:	83 ec 0c             	sub    $0xc,%esp
f010125d:	53                   	push   %ebx
f010125e:	e8 ea f3 ff ff       	call   f010064d <cputchar>
f0101263:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0101266:	88 9e 40 25 11 f0    	mov    %bl,-0xfeedac0(%esi)
f010126c:	8d 76 01             	lea    0x1(%esi),%esi
f010126f:	eb 8b                	jmp    f01011fc <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0101271:	83 fb 0a             	cmp    $0xa,%ebx
f0101274:	74 05                	je     f010127b <readline+0xb4>
f0101276:	83 fb 0d             	cmp    $0xd,%ebx
f0101279:	75 81                	jne    f01011fc <readline+0x35>
			if (echoing)
f010127b:	85 ff                	test   %edi,%edi
f010127d:	74 0d                	je     f010128c <readline+0xc5>
				cputchar('\n');
f010127f:	83 ec 0c             	sub    $0xc,%esp
f0101282:	6a 0a                	push   $0xa
f0101284:	e8 c4 f3 ff ff       	call   f010064d <cputchar>
f0101289:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f010128c:	c6 86 40 25 11 f0 00 	movb   $0x0,-0xfeedac0(%esi)
			return buf;
f0101293:	b8 40 25 11 f0       	mov    $0xf0112540,%eax
		}
	}
}
f0101298:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010129b:	5b                   	pop    %ebx
f010129c:	5e                   	pop    %esi
f010129d:	5f                   	pop    %edi
f010129e:	5d                   	pop    %ebp
f010129f:	c3                   	ret    

f01012a0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01012a0:	55                   	push   %ebp
f01012a1:	89 e5                	mov    %esp,%ebp
f01012a3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01012a6:	b8 00 00 00 00       	mov    $0x0,%eax
f01012ab:	eb 03                	jmp    f01012b0 <strlen+0x10>
		n++;
f01012ad:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01012b0:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01012b4:	75 f7                	jne    f01012ad <strlen+0xd>
		n++;
	return n;
}
f01012b6:	5d                   	pop    %ebp
f01012b7:	c3                   	ret    

f01012b8 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01012b8:	55                   	push   %ebp
f01012b9:	89 e5                	mov    %esp,%ebp
f01012bb:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01012be:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01012c1:	ba 00 00 00 00       	mov    $0x0,%edx
f01012c6:	eb 03                	jmp    f01012cb <strnlen+0x13>
		n++;
f01012c8:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01012cb:	39 c2                	cmp    %eax,%edx
f01012cd:	74 08                	je     f01012d7 <strnlen+0x1f>
f01012cf:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f01012d3:	75 f3                	jne    f01012c8 <strnlen+0x10>
f01012d5:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f01012d7:	5d                   	pop    %ebp
f01012d8:	c3                   	ret    

f01012d9 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01012d9:	55                   	push   %ebp
f01012da:	89 e5                	mov    %esp,%ebp
f01012dc:	53                   	push   %ebx
f01012dd:	8b 45 08             	mov    0x8(%ebp),%eax
f01012e0:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01012e3:	89 c2                	mov    %eax,%edx
f01012e5:	83 c2 01             	add    $0x1,%edx
f01012e8:	83 c1 01             	add    $0x1,%ecx
f01012eb:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01012ef:	88 5a ff             	mov    %bl,-0x1(%edx)
f01012f2:	84 db                	test   %bl,%bl
f01012f4:	75 ef                	jne    f01012e5 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01012f6:	5b                   	pop    %ebx
f01012f7:	5d                   	pop    %ebp
f01012f8:	c3                   	ret    

f01012f9 <strcat>:

char *
strcat(char *dst, const char *src)
{
f01012f9:	55                   	push   %ebp
f01012fa:	89 e5                	mov    %esp,%ebp
f01012fc:	53                   	push   %ebx
f01012fd:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101300:	53                   	push   %ebx
f0101301:	e8 9a ff ff ff       	call   f01012a0 <strlen>
f0101306:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0101309:	ff 75 0c             	pushl  0xc(%ebp)
f010130c:	01 d8                	add    %ebx,%eax
f010130e:	50                   	push   %eax
f010130f:	e8 c5 ff ff ff       	call   f01012d9 <strcpy>
	return dst;
}
f0101314:	89 d8                	mov    %ebx,%eax
f0101316:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101319:	c9                   	leave  
f010131a:	c3                   	ret    

f010131b <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010131b:	55                   	push   %ebp
f010131c:	89 e5                	mov    %esp,%ebp
f010131e:	56                   	push   %esi
f010131f:	53                   	push   %ebx
f0101320:	8b 75 08             	mov    0x8(%ebp),%esi
f0101323:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101326:	89 f3                	mov    %esi,%ebx
f0101328:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010132b:	89 f2                	mov    %esi,%edx
f010132d:	eb 0f                	jmp    f010133e <strncpy+0x23>
		*dst++ = *src;
f010132f:	83 c2 01             	add    $0x1,%edx
f0101332:	0f b6 01             	movzbl (%ecx),%eax
f0101335:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101338:	80 39 01             	cmpb   $0x1,(%ecx)
f010133b:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010133e:	39 da                	cmp    %ebx,%edx
f0101340:	75 ed                	jne    f010132f <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101342:	89 f0                	mov    %esi,%eax
f0101344:	5b                   	pop    %ebx
f0101345:	5e                   	pop    %esi
f0101346:	5d                   	pop    %ebp
f0101347:	c3                   	ret    

f0101348 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101348:	55                   	push   %ebp
f0101349:	89 e5                	mov    %esp,%ebp
f010134b:	56                   	push   %esi
f010134c:	53                   	push   %ebx
f010134d:	8b 75 08             	mov    0x8(%ebp),%esi
f0101350:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101353:	8b 55 10             	mov    0x10(%ebp),%edx
f0101356:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101358:	85 d2                	test   %edx,%edx
f010135a:	74 21                	je     f010137d <strlcpy+0x35>
f010135c:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0101360:	89 f2                	mov    %esi,%edx
f0101362:	eb 09                	jmp    f010136d <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101364:	83 c2 01             	add    $0x1,%edx
f0101367:	83 c1 01             	add    $0x1,%ecx
f010136a:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f010136d:	39 c2                	cmp    %eax,%edx
f010136f:	74 09                	je     f010137a <strlcpy+0x32>
f0101371:	0f b6 19             	movzbl (%ecx),%ebx
f0101374:	84 db                	test   %bl,%bl
f0101376:	75 ec                	jne    f0101364 <strlcpy+0x1c>
f0101378:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f010137a:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f010137d:	29 f0                	sub    %esi,%eax
}
f010137f:	5b                   	pop    %ebx
f0101380:	5e                   	pop    %esi
f0101381:	5d                   	pop    %ebp
f0101382:	c3                   	ret    

f0101383 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101383:	55                   	push   %ebp
f0101384:	89 e5                	mov    %esp,%ebp
f0101386:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101389:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f010138c:	eb 06                	jmp    f0101394 <strcmp+0x11>
		p++, q++;
f010138e:	83 c1 01             	add    $0x1,%ecx
f0101391:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0101394:	0f b6 01             	movzbl (%ecx),%eax
f0101397:	84 c0                	test   %al,%al
f0101399:	74 04                	je     f010139f <strcmp+0x1c>
f010139b:	3a 02                	cmp    (%edx),%al
f010139d:	74 ef                	je     f010138e <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f010139f:	0f b6 c0             	movzbl %al,%eax
f01013a2:	0f b6 12             	movzbl (%edx),%edx
f01013a5:	29 d0                	sub    %edx,%eax
}
f01013a7:	5d                   	pop    %ebp
f01013a8:	c3                   	ret    

f01013a9 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01013a9:	55                   	push   %ebp
f01013aa:	89 e5                	mov    %esp,%ebp
f01013ac:	53                   	push   %ebx
f01013ad:	8b 45 08             	mov    0x8(%ebp),%eax
f01013b0:	8b 55 0c             	mov    0xc(%ebp),%edx
f01013b3:	89 c3                	mov    %eax,%ebx
f01013b5:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01013b8:	eb 06                	jmp    f01013c0 <strncmp+0x17>
		n--, p++, q++;
f01013ba:	83 c0 01             	add    $0x1,%eax
f01013bd:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01013c0:	39 d8                	cmp    %ebx,%eax
f01013c2:	74 15                	je     f01013d9 <strncmp+0x30>
f01013c4:	0f b6 08             	movzbl (%eax),%ecx
f01013c7:	84 c9                	test   %cl,%cl
f01013c9:	74 04                	je     f01013cf <strncmp+0x26>
f01013cb:	3a 0a                	cmp    (%edx),%cl
f01013cd:	74 eb                	je     f01013ba <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01013cf:	0f b6 00             	movzbl (%eax),%eax
f01013d2:	0f b6 12             	movzbl (%edx),%edx
f01013d5:	29 d0                	sub    %edx,%eax
f01013d7:	eb 05                	jmp    f01013de <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01013d9:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01013de:	5b                   	pop    %ebx
f01013df:	5d                   	pop    %ebp
f01013e0:	c3                   	ret    

f01013e1 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01013e1:	55                   	push   %ebp
f01013e2:	89 e5                	mov    %esp,%ebp
f01013e4:	8b 45 08             	mov    0x8(%ebp),%eax
f01013e7:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01013eb:	eb 07                	jmp    f01013f4 <strchr+0x13>
		if (*s == c)
f01013ed:	38 ca                	cmp    %cl,%dl
f01013ef:	74 0f                	je     f0101400 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01013f1:	83 c0 01             	add    $0x1,%eax
f01013f4:	0f b6 10             	movzbl (%eax),%edx
f01013f7:	84 d2                	test   %dl,%dl
f01013f9:	75 f2                	jne    f01013ed <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f01013fb:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101400:	5d                   	pop    %ebp
f0101401:	c3                   	ret    

f0101402 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101402:	55                   	push   %ebp
f0101403:	89 e5                	mov    %esp,%ebp
f0101405:	8b 45 08             	mov    0x8(%ebp),%eax
f0101408:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010140c:	eb 03                	jmp    f0101411 <strfind+0xf>
f010140e:	83 c0 01             	add    $0x1,%eax
f0101411:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0101414:	38 ca                	cmp    %cl,%dl
f0101416:	74 04                	je     f010141c <strfind+0x1a>
f0101418:	84 d2                	test   %dl,%dl
f010141a:	75 f2                	jne    f010140e <strfind+0xc>
			break;
	return (char *) s;
}
f010141c:	5d                   	pop    %ebp
f010141d:	c3                   	ret    

f010141e <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f010141e:	55                   	push   %ebp
f010141f:	89 e5                	mov    %esp,%ebp
f0101421:	57                   	push   %edi
f0101422:	56                   	push   %esi
f0101423:	53                   	push   %ebx
f0101424:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101427:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010142a:	85 c9                	test   %ecx,%ecx
f010142c:	74 36                	je     f0101464 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010142e:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101434:	75 28                	jne    f010145e <memset+0x40>
f0101436:	f6 c1 03             	test   $0x3,%cl
f0101439:	75 23                	jne    f010145e <memset+0x40>
		c &= 0xFF;
f010143b:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010143f:	89 d3                	mov    %edx,%ebx
f0101441:	c1 e3 08             	shl    $0x8,%ebx
f0101444:	89 d6                	mov    %edx,%esi
f0101446:	c1 e6 18             	shl    $0x18,%esi
f0101449:	89 d0                	mov    %edx,%eax
f010144b:	c1 e0 10             	shl    $0x10,%eax
f010144e:	09 f0                	or     %esi,%eax
f0101450:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0101452:	89 d8                	mov    %ebx,%eax
f0101454:	09 d0                	or     %edx,%eax
f0101456:	c1 e9 02             	shr    $0x2,%ecx
f0101459:	fc                   	cld    
f010145a:	f3 ab                	rep stos %eax,%es:(%edi)
f010145c:	eb 06                	jmp    f0101464 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010145e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101461:	fc                   	cld    
f0101462:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0101464:	89 f8                	mov    %edi,%eax
f0101466:	5b                   	pop    %ebx
f0101467:	5e                   	pop    %esi
f0101468:	5f                   	pop    %edi
f0101469:	5d                   	pop    %ebp
f010146a:	c3                   	ret    

f010146b <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010146b:	55                   	push   %ebp
f010146c:	89 e5                	mov    %esp,%ebp
f010146e:	57                   	push   %edi
f010146f:	56                   	push   %esi
f0101470:	8b 45 08             	mov    0x8(%ebp),%eax
f0101473:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101476:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101479:	39 c6                	cmp    %eax,%esi
f010147b:	73 35                	jae    f01014b2 <memmove+0x47>
f010147d:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0101480:	39 d0                	cmp    %edx,%eax
f0101482:	73 2e                	jae    f01014b2 <memmove+0x47>
		s += n;
		d += n;
f0101484:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101487:	89 d6                	mov    %edx,%esi
f0101489:	09 fe                	or     %edi,%esi
f010148b:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0101491:	75 13                	jne    f01014a6 <memmove+0x3b>
f0101493:	f6 c1 03             	test   $0x3,%cl
f0101496:	75 0e                	jne    f01014a6 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0101498:	83 ef 04             	sub    $0x4,%edi
f010149b:	8d 72 fc             	lea    -0x4(%edx),%esi
f010149e:	c1 e9 02             	shr    $0x2,%ecx
f01014a1:	fd                   	std    
f01014a2:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01014a4:	eb 09                	jmp    f01014af <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01014a6:	83 ef 01             	sub    $0x1,%edi
f01014a9:	8d 72 ff             	lea    -0x1(%edx),%esi
f01014ac:	fd                   	std    
f01014ad:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01014af:	fc                   	cld    
f01014b0:	eb 1d                	jmp    f01014cf <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01014b2:	89 f2                	mov    %esi,%edx
f01014b4:	09 c2                	or     %eax,%edx
f01014b6:	f6 c2 03             	test   $0x3,%dl
f01014b9:	75 0f                	jne    f01014ca <memmove+0x5f>
f01014bb:	f6 c1 03             	test   $0x3,%cl
f01014be:	75 0a                	jne    f01014ca <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f01014c0:	c1 e9 02             	shr    $0x2,%ecx
f01014c3:	89 c7                	mov    %eax,%edi
f01014c5:	fc                   	cld    
f01014c6:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01014c8:	eb 05                	jmp    f01014cf <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01014ca:	89 c7                	mov    %eax,%edi
f01014cc:	fc                   	cld    
f01014cd:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01014cf:	5e                   	pop    %esi
f01014d0:	5f                   	pop    %edi
f01014d1:	5d                   	pop    %ebp
f01014d2:	c3                   	ret    

f01014d3 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01014d3:	55                   	push   %ebp
f01014d4:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01014d6:	ff 75 10             	pushl  0x10(%ebp)
f01014d9:	ff 75 0c             	pushl  0xc(%ebp)
f01014dc:	ff 75 08             	pushl  0x8(%ebp)
f01014df:	e8 87 ff ff ff       	call   f010146b <memmove>
}
f01014e4:	c9                   	leave  
f01014e5:	c3                   	ret    

f01014e6 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01014e6:	55                   	push   %ebp
f01014e7:	89 e5                	mov    %esp,%ebp
f01014e9:	56                   	push   %esi
f01014ea:	53                   	push   %ebx
f01014eb:	8b 45 08             	mov    0x8(%ebp),%eax
f01014ee:	8b 55 0c             	mov    0xc(%ebp),%edx
f01014f1:	89 c6                	mov    %eax,%esi
f01014f3:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01014f6:	eb 1a                	jmp    f0101512 <memcmp+0x2c>
		if (*s1 != *s2)
f01014f8:	0f b6 08             	movzbl (%eax),%ecx
f01014fb:	0f b6 1a             	movzbl (%edx),%ebx
f01014fe:	38 d9                	cmp    %bl,%cl
f0101500:	74 0a                	je     f010150c <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0101502:	0f b6 c1             	movzbl %cl,%eax
f0101505:	0f b6 db             	movzbl %bl,%ebx
f0101508:	29 d8                	sub    %ebx,%eax
f010150a:	eb 0f                	jmp    f010151b <memcmp+0x35>
		s1++, s2++;
f010150c:	83 c0 01             	add    $0x1,%eax
f010150f:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101512:	39 f0                	cmp    %esi,%eax
f0101514:	75 e2                	jne    f01014f8 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0101516:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010151b:	5b                   	pop    %ebx
f010151c:	5e                   	pop    %esi
f010151d:	5d                   	pop    %ebp
f010151e:	c3                   	ret    

f010151f <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010151f:	55                   	push   %ebp
f0101520:	89 e5                	mov    %esp,%ebp
f0101522:	53                   	push   %ebx
f0101523:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0101526:	89 c1                	mov    %eax,%ecx
f0101528:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f010152b:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010152f:	eb 0a                	jmp    f010153b <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101531:	0f b6 10             	movzbl (%eax),%edx
f0101534:	39 da                	cmp    %ebx,%edx
f0101536:	74 07                	je     f010153f <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0101538:	83 c0 01             	add    $0x1,%eax
f010153b:	39 c8                	cmp    %ecx,%eax
f010153d:	72 f2                	jb     f0101531 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f010153f:	5b                   	pop    %ebx
f0101540:	5d                   	pop    %ebp
f0101541:	c3                   	ret    

f0101542 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101542:	55                   	push   %ebp
f0101543:	89 e5                	mov    %esp,%ebp
f0101545:	57                   	push   %edi
f0101546:	56                   	push   %esi
f0101547:	53                   	push   %ebx
f0101548:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010154b:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010154e:	eb 03                	jmp    f0101553 <strtol+0x11>
		s++;
f0101550:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101553:	0f b6 01             	movzbl (%ecx),%eax
f0101556:	3c 20                	cmp    $0x20,%al
f0101558:	74 f6                	je     f0101550 <strtol+0xe>
f010155a:	3c 09                	cmp    $0x9,%al
f010155c:	74 f2                	je     f0101550 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f010155e:	3c 2b                	cmp    $0x2b,%al
f0101560:	75 0a                	jne    f010156c <strtol+0x2a>
		s++;
f0101562:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0101565:	bf 00 00 00 00       	mov    $0x0,%edi
f010156a:	eb 11                	jmp    f010157d <strtol+0x3b>
f010156c:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0101571:	3c 2d                	cmp    $0x2d,%al
f0101573:	75 08                	jne    f010157d <strtol+0x3b>
		s++, neg = 1;
f0101575:	83 c1 01             	add    $0x1,%ecx
f0101578:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010157d:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0101583:	75 15                	jne    f010159a <strtol+0x58>
f0101585:	80 39 30             	cmpb   $0x30,(%ecx)
f0101588:	75 10                	jne    f010159a <strtol+0x58>
f010158a:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f010158e:	75 7c                	jne    f010160c <strtol+0xca>
		s += 2, base = 16;
f0101590:	83 c1 02             	add    $0x2,%ecx
f0101593:	bb 10 00 00 00       	mov    $0x10,%ebx
f0101598:	eb 16                	jmp    f01015b0 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f010159a:	85 db                	test   %ebx,%ebx
f010159c:	75 12                	jne    f01015b0 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010159e:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01015a3:	80 39 30             	cmpb   $0x30,(%ecx)
f01015a6:	75 08                	jne    f01015b0 <strtol+0x6e>
		s++, base = 8;
f01015a8:	83 c1 01             	add    $0x1,%ecx
f01015ab:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f01015b0:	b8 00 00 00 00       	mov    $0x0,%eax
f01015b5:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01015b8:	0f b6 11             	movzbl (%ecx),%edx
f01015bb:	8d 72 d0             	lea    -0x30(%edx),%esi
f01015be:	89 f3                	mov    %esi,%ebx
f01015c0:	80 fb 09             	cmp    $0x9,%bl
f01015c3:	77 08                	ja     f01015cd <strtol+0x8b>
			dig = *s - '0';
f01015c5:	0f be d2             	movsbl %dl,%edx
f01015c8:	83 ea 30             	sub    $0x30,%edx
f01015cb:	eb 22                	jmp    f01015ef <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f01015cd:	8d 72 9f             	lea    -0x61(%edx),%esi
f01015d0:	89 f3                	mov    %esi,%ebx
f01015d2:	80 fb 19             	cmp    $0x19,%bl
f01015d5:	77 08                	ja     f01015df <strtol+0x9d>
			dig = *s - 'a' + 10;
f01015d7:	0f be d2             	movsbl %dl,%edx
f01015da:	83 ea 57             	sub    $0x57,%edx
f01015dd:	eb 10                	jmp    f01015ef <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f01015df:	8d 72 bf             	lea    -0x41(%edx),%esi
f01015e2:	89 f3                	mov    %esi,%ebx
f01015e4:	80 fb 19             	cmp    $0x19,%bl
f01015e7:	77 16                	ja     f01015ff <strtol+0xbd>
			dig = *s - 'A' + 10;
f01015e9:	0f be d2             	movsbl %dl,%edx
f01015ec:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f01015ef:	3b 55 10             	cmp    0x10(%ebp),%edx
f01015f2:	7d 0b                	jge    f01015ff <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f01015f4:	83 c1 01             	add    $0x1,%ecx
f01015f7:	0f af 45 10          	imul   0x10(%ebp),%eax
f01015fb:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f01015fd:	eb b9                	jmp    f01015b8 <strtol+0x76>

	if (endptr)
f01015ff:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101603:	74 0d                	je     f0101612 <strtol+0xd0>
		*endptr = (char *) s;
f0101605:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101608:	89 0e                	mov    %ecx,(%esi)
f010160a:	eb 06                	jmp    f0101612 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010160c:	85 db                	test   %ebx,%ebx
f010160e:	74 98                	je     f01015a8 <strtol+0x66>
f0101610:	eb 9e                	jmp    f01015b0 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0101612:	89 c2                	mov    %eax,%edx
f0101614:	f7 da                	neg    %edx
f0101616:	85 ff                	test   %edi,%edi
f0101618:	0f 45 c2             	cmovne %edx,%eax
}
f010161b:	5b                   	pop    %ebx
f010161c:	5e                   	pop    %esi
f010161d:	5f                   	pop    %edi
f010161e:	5d                   	pop    %ebp
f010161f:	c3                   	ret    

f0101620 <__udivdi3>:
f0101620:	55                   	push   %ebp
f0101621:	57                   	push   %edi
f0101622:	56                   	push   %esi
f0101623:	53                   	push   %ebx
f0101624:	83 ec 1c             	sub    $0x1c,%esp
f0101627:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010162b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010162f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0101633:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101637:	85 f6                	test   %esi,%esi
f0101639:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010163d:	89 ca                	mov    %ecx,%edx
f010163f:	89 f8                	mov    %edi,%eax
f0101641:	75 3d                	jne    f0101680 <__udivdi3+0x60>
f0101643:	39 cf                	cmp    %ecx,%edi
f0101645:	0f 87 c5 00 00 00    	ja     f0101710 <__udivdi3+0xf0>
f010164b:	85 ff                	test   %edi,%edi
f010164d:	89 fd                	mov    %edi,%ebp
f010164f:	75 0b                	jne    f010165c <__udivdi3+0x3c>
f0101651:	b8 01 00 00 00       	mov    $0x1,%eax
f0101656:	31 d2                	xor    %edx,%edx
f0101658:	f7 f7                	div    %edi
f010165a:	89 c5                	mov    %eax,%ebp
f010165c:	89 c8                	mov    %ecx,%eax
f010165e:	31 d2                	xor    %edx,%edx
f0101660:	f7 f5                	div    %ebp
f0101662:	89 c1                	mov    %eax,%ecx
f0101664:	89 d8                	mov    %ebx,%eax
f0101666:	89 cf                	mov    %ecx,%edi
f0101668:	f7 f5                	div    %ebp
f010166a:	89 c3                	mov    %eax,%ebx
f010166c:	89 d8                	mov    %ebx,%eax
f010166e:	89 fa                	mov    %edi,%edx
f0101670:	83 c4 1c             	add    $0x1c,%esp
f0101673:	5b                   	pop    %ebx
f0101674:	5e                   	pop    %esi
f0101675:	5f                   	pop    %edi
f0101676:	5d                   	pop    %ebp
f0101677:	c3                   	ret    
f0101678:	90                   	nop
f0101679:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101680:	39 ce                	cmp    %ecx,%esi
f0101682:	77 74                	ja     f01016f8 <__udivdi3+0xd8>
f0101684:	0f bd fe             	bsr    %esi,%edi
f0101687:	83 f7 1f             	xor    $0x1f,%edi
f010168a:	0f 84 98 00 00 00    	je     f0101728 <__udivdi3+0x108>
f0101690:	bb 20 00 00 00       	mov    $0x20,%ebx
f0101695:	89 f9                	mov    %edi,%ecx
f0101697:	89 c5                	mov    %eax,%ebp
f0101699:	29 fb                	sub    %edi,%ebx
f010169b:	d3 e6                	shl    %cl,%esi
f010169d:	89 d9                	mov    %ebx,%ecx
f010169f:	d3 ed                	shr    %cl,%ebp
f01016a1:	89 f9                	mov    %edi,%ecx
f01016a3:	d3 e0                	shl    %cl,%eax
f01016a5:	09 ee                	or     %ebp,%esi
f01016a7:	89 d9                	mov    %ebx,%ecx
f01016a9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01016ad:	89 d5                	mov    %edx,%ebp
f01016af:	8b 44 24 08          	mov    0x8(%esp),%eax
f01016b3:	d3 ed                	shr    %cl,%ebp
f01016b5:	89 f9                	mov    %edi,%ecx
f01016b7:	d3 e2                	shl    %cl,%edx
f01016b9:	89 d9                	mov    %ebx,%ecx
f01016bb:	d3 e8                	shr    %cl,%eax
f01016bd:	09 c2                	or     %eax,%edx
f01016bf:	89 d0                	mov    %edx,%eax
f01016c1:	89 ea                	mov    %ebp,%edx
f01016c3:	f7 f6                	div    %esi
f01016c5:	89 d5                	mov    %edx,%ebp
f01016c7:	89 c3                	mov    %eax,%ebx
f01016c9:	f7 64 24 0c          	mull   0xc(%esp)
f01016cd:	39 d5                	cmp    %edx,%ebp
f01016cf:	72 10                	jb     f01016e1 <__udivdi3+0xc1>
f01016d1:	8b 74 24 08          	mov    0x8(%esp),%esi
f01016d5:	89 f9                	mov    %edi,%ecx
f01016d7:	d3 e6                	shl    %cl,%esi
f01016d9:	39 c6                	cmp    %eax,%esi
f01016db:	73 07                	jae    f01016e4 <__udivdi3+0xc4>
f01016dd:	39 d5                	cmp    %edx,%ebp
f01016df:	75 03                	jne    f01016e4 <__udivdi3+0xc4>
f01016e1:	83 eb 01             	sub    $0x1,%ebx
f01016e4:	31 ff                	xor    %edi,%edi
f01016e6:	89 d8                	mov    %ebx,%eax
f01016e8:	89 fa                	mov    %edi,%edx
f01016ea:	83 c4 1c             	add    $0x1c,%esp
f01016ed:	5b                   	pop    %ebx
f01016ee:	5e                   	pop    %esi
f01016ef:	5f                   	pop    %edi
f01016f0:	5d                   	pop    %ebp
f01016f1:	c3                   	ret    
f01016f2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01016f8:	31 ff                	xor    %edi,%edi
f01016fa:	31 db                	xor    %ebx,%ebx
f01016fc:	89 d8                	mov    %ebx,%eax
f01016fe:	89 fa                	mov    %edi,%edx
f0101700:	83 c4 1c             	add    $0x1c,%esp
f0101703:	5b                   	pop    %ebx
f0101704:	5e                   	pop    %esi
f0101705:	5f                   	pop    %edi
f0101706:	5d                   	pop    %ebp
f0101707:	c3                   	ret    
f0101708:	90                   	nop
f0101709:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101710:	89 d8                	mov    %ebx,%eax
f0101712:	f7 f7                	div    %edi
f0101714:	31 ff                	xor    %edi,%edi
f0101716:	89 c3                	mov    %eax,%ebx
f0101718:	89 d8                	mov    %ebx,%eax
f010171a:	89 fa                	mov    %edi,%edx
f010171c:	83 c4 1c             	add    $0x1c,%esp
f010171f:	5b                   	pop    %ebx
f0101720:	5e                   	pop    %esi
f0101721:	5f                   	pop    %edi
f0101722:	5d                   	pop    %ebp
f0101723:	c3                   	ret    
f0101724:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101728:	39 ce                	cmp    %ecx,%esi
f010172a:	72 0c                	jb     f0101738 <__udivdi3+0x118>
f010172c:	31 db                	xor    %ebx,%ebx
f010172e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0101732:	0f 87 34 ff ff ff    	ja     f010166c <__udivdi3+0x4c>
f0101738:	bb 01 00 00 00       	mov    $0x1,%ebx
f010173d:	e9 2a ff ff ff       	jmp    f010166c <__udivdi3+0x4c>
f0101742:	66 90                	xchg   %ax,%ax
f0101744:	66 90                	xchg   %ax,%ax
f0101746:	66 90                	xchg   %ax,%ax
f0101748:	66 90                	xchg   %ax,%ax
f010174a:	66 90                	xchg   %ax,%ax
f010174c:	66 90                	xchg   %ax,%ax
f010174e:	66 90                	xchg   %ax,%ax

f0101750 <__umoddi3>:
f0101750:	55                   	push   %ebp
f0101751:	57                   	push   %edi
f0101752:	56                   	push   %esi
f0101753:	53                   	push   %ebx
f0101754:	83 ec 1c             	sub    $0x1c,%esp
f0101757:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010175b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010175f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0101763:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101767:	85 d2                	test   %edx,%edx
f0101769:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010176d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101771:	89 f3                	mov    %esi,%ebx
f0101773:	89 3c 24             	mov    %edi,(%esp)
f0101776:	89 74 24 04          	mov    %esi,0x4(%esp)
f010177a:	75 1c                	jne    f0101798 <__umoddi3+0x48>
f010177c:	39 f7                	cmp    %esi,%edi
f010177e:	76 50                	jbe    f01017d0 <__umoddi3+0x80>
f0101780:	89 c8                	mov    %ecx,%eax
f0101782:	89 f2                	mov    %esi,%edx
f0101784:	f7 f7                	div    %edi
f0101786:	89 d0                	mov    %edx,%eax
f0101788:	31 d2                	xor    %edx,%edx
f010178a:	83 c4 1c             	add    $0x1c,%esp
f010178d:	5b                   	pop    %ebx
f010178e:	5e                   	pop    %esi
f010178f:	5f                   	pop    %edi
f0101790:	5d                   	pop    %ebp
f0101791:	c3                   	ret    
f0101792:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101798:	39 f2                	cmp    %esi,%edx
f010179a:	89 d0                	mov    %edx,%eax
f010179c:	77 52                	ja     f01017f0 <__umoddi3+0xa0>
f010179e:	0f bd ea             	bsr    %edx,%ebp
f01017a1:	83 f5 1f             	xor    $0x1f,%ebp
f01017a4:	75 5a                	jne    f0101800 <__umoddi3+0xb0>
f01017a6:	3b 54 24 04          	cmp    0x4(%esp),%edx
f01017aa:	0f 82 e0 00 00 00    	jb     f0101890 <__umoddi3+0x140>
f01017b0:	39 0c 24             	cmp    %ecx,(%esp)
f01017b3:	0f 86 d7 00 00 00    	jbe    f0101890 <__umoddi3+0x140>
f01017b9:	8b 44 24 08          	mov    0x8(%esp),%eax
f01017bd:	8b 54 24 04          	mov    0x4(%esp),%edx
f01017c1:	83 c4 1c             	add    $0x1c,%esp
f01017c4:	5b                   	pop    %ebx
f01017c5:	5e                   	pop    %esi
f01017c6:	5f                   	pop    %edi
f01017c7:	5d                   	pop    %ebp
f01017c8:	c3                   	ret    
f01017c9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01017d0:	85 ff                	test   %edi,%edi
f01017d2:	89 fd                	mov    %edi,%ebp
f01017d4:	75 0b                	jne    f01017e1 <__umoddi3+0x91>
f01017d6:	b8 01 00 00 00       	mov    $0x1,%eax
f01017db:	31 d2                	xor    %edx,%edx
f01017dd:	f7 f7                	div    %edi
f01017df:	89 c5                	mov    %eax,%ebp
f01017e1:	89 f0                	mov    %esi,%eax
f01017e3:	31 d2                	xor    %edx,%edx
f01017e5:	f7 f5                	div    %ebp
f01017e7:	89 c8                	mov    %ecx,%eax
f01017e9:	f7 f5                	div    %ebp
f01017eb:	89 d0                	mov    %edx,%eax
f01017ed:	eb 99                	jmp    f0101788 <__umoddi3+0x38>
f01017ef:	90                   	nop
f01017f0:	89 c8                	mov    %ecx,%eax
f01017f2:	89 f2                	mov    %esi,%edx
f01017f4:	83 c4 1c             	add    $0x1c,%esp
f01017f7:	5b                   	pop    %ebx
f01017f8:	5e                   	pop    %esi
f01017f9:	5f                   	pop    %edi
f01017fa:	5d                   	pop    %ebp
f01017fb:	c3                   	ret    
f01017fc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101800:	8b 34 24             	mov    (%esp),%esi
f0101803:	bf 20 00 00 00       	mov    $0x20,%edi
f0101808:	89 e9                	mov    %ebp,%ecx
f010180a:	29 ef                	sub    %ebp,%edi
f010180c:	d3 e0                	shl    %cl,%eax
f010180e:	89 f9                	mov    %edi,%ecx
f0101810:	89 f2                	mov    %esi,%edx
f0101812:	d3 ea                	shr    %cl,%edx
f0101814:	89 e9                	mov    %ebp,%ecx
f0101816:	09 c2                	or     %eax,%edx
f0101818:	89 d8                	mov    %ebx,%eax
f010181a:	89 14 24             	mov    %edx,(%esp)
f010181d:	89 f2                	mov    %esi,%edx
f010181f:	d3 e2                	shl    %cl,%edx
f0101821:	89 f9                	mov    %edi,%ecx
f0101823:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101827:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010182b:	d3 e8                	shr    %cl,%eax
f010182d:	89 e9                	mov    %ebp,%ecx
f010182f:	89 c6                	mov    %eax,%esi
f0101831:	d3 e3                	shl    %cl,%ebx
f0101833:	89 f9                	mov    %edi,%ecx
f0101835:	89 d0                	mov    %edx,%eax
f0101837:	d3 e8                	shr    %cl,%eax
f0101839:	89 e9                	mov    %ebp,%ecx
f010183b:	09 d8                	or     %ebx,%eax
f010183d:	89 d3                	mov    %edx,%ebx
f010183f:	89 f2                	mov    %esi,%edx
f0101841:	f7 34 24             	divl   (%esp)
f0101844:	89 d6                	mov    %edx,%esi
f0101846:	d3 e3                	shl    %cl,%ebx
f0101848:	f7 64 24 04          	mull   0x4(%esp)
f010184c:	39 d6                	cmp    %edx,%esi
f010184e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0101852:	89 d1                	mov    %edx,%ecx
f0101854:	89 c3                	mov    %eax,%ebx
f0101856:	72 08                	jb     f0101860 <__umoddi3+0x110>
f0101858:	75 11                	jne    f010186b <__umoddi3+0x11b>
f010185a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010185e:	73 0b                	jae    f010186b <__umoddi3+0x11b>
f0101860:	2b 44 24 04          	sub    0x4(%esp),%eax
f0101864:	1b 14 24             	sbb    (%esp),%edx
f0101867:	89 d1                	mov    %edx,%ecx
f0101869:	89 c3                	mov    %eax,%ebx
f010186b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010186f:	29 da                	sub    %ebx,%edx
f0101871:	19 ce                	sbb    %ecx,%esi
f0101873:	89 f9                	mov    %edi,%ecx
f0101875:	89 f0                	mov    %esi,%eax
f0101877:	d3 e0                	shl    %cl,%eax
f0101879:	89 e9                	mov    %ebp,%ecx
f010187b:	d3 ea                	shr    %cl,%edx
f010187d:	89 e9                	mov    %ebp,%ecx
f010187f:	d3 ee                	shr    %cl,%esi
f0101881:	09 d0                	or     %edx,%eax
f0101883:	89 f2                	mov    %esi,%edx
f0101885:	83 c4 1c             	add    $0x1c,%esp
f0101888:	5b                   	pop    %ebx
f0101889:	5e                   	pop    %esi
f010188a:	5f                   	pop    %edi
f010188b:	5d                   	pop    %ebp
f010188c:	c3                   	ret    
f010188d:	8d 76 00             	lea    0x0(%esi),%esi
f0101890:	29 f9                	sub    %edi,%ecx
f0101892:	19 d6                	sbb    %edx,%esi
f0101894:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101898:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010189c:	e9 18 ff ff ff       	jmp    f01017b9 <__umoddi3+0x69>
