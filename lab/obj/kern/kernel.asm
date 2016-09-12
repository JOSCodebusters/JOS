
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
f010004b:	68 e0 18 10 f0       	push   $0xf01018e0
f0100050:	e8 09 09 00 00       	call   f010095e <cprintf>
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
f0100076:	e8 fc 06 00 00       	call   f0100777 <mon_backtrace>
f010007b:	83 c4 10             	add    $0x10,%esp
	cprintf("leaving test_backtrace %d\n", x);
f010007e:	83 ec 08             	sub    $0x8,%esp
f0100081:	53                   	push   %ebx
f0100082:	68 fc 18 10 f0       	push   $0xf01018fc
f0100087:	e8 d2 08 00 00       	call   f010095e <cprintf>
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
f01000ac:	e8 91 13 00 00       	call   f0101442 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b1:	e8 8f 04 00 00       	call   f0100545 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000b6:	83 c4 08             	add    $0x8,%esp
f01000b9:	68 ac 1a 00 00       	push   $0x1aac
f01000be:	68 17 19 10 f0       	push   $0xf0101917
f01000c3:	e8 96 08 00 00       	call   f010095e <cprintf>

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
f01000dc:	e8 10 07 00 00       	call   f01007f1 <monitor>
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
f010010b:	68 32 19 10 f0       	push   $0xf0101932
f0100110:	e8 49 08 00 00       	call   f010095e <cprintf>
	vcprintf(fmt, ap);
f0100115:	83 c4 08             	add    $0x8,%esp
f0100118:	53                   	push   %ebx
f0100119:	56                   	push   %esi
f010011a:	e8 19 08 00 00       	call   f0100938 <vcprintf>
	cprintf("\n");
f010011f:	c7 04 24 6e 19 10 f0 	movl   $0xf010196e,(%esp)
f0100126:	e8 33 08 00 00       	call   f010095e <cprintf>
	va_end(ap);
f010012b:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010012e:	83 ec 0c             	sub    $0xc,%esp
f0100131:	6a 00                	push   $0x0
f0100133:	e8 b9 06 00 00       	call   f01007f1 <monitor>
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
f010014d:	68 4a 19 10 f0       	push   $0xf010194a
f0100152:	e8 07 08 00 00       	call   f010095e <cprintf>
	vcprintf(fmt, ap);
f0100157:	83 c4 08             	add    $0x8,%esp
f010015a:	53                   	push   %ebx
f010015b:	ff 75 10             	pushl  0x10(%ebp)
f010015e:	e8 d5 07 00 00       	call   f0100938 <vcprintf>
	cprintf("\n");
f0100163:	c7 04 24 6e 19 10 f0 	movl   $0xf010196e,(%esp)
f010016a:	e8 ef 07 00 00       	call   f010095e <cprintf>
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
f0100221:	0f b6 82 c0 1a 10 f0 	movzbl -0xfefe540(%edx),%eax
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
f010025d:	0f b6 82 c0 1a 10 f0 	movzbl -0xfefe540(%edx),%eax
f0100264:	0b 05 00 23 11 f0    	or     0xf0112300,%eax
f010026a:	0f b6 8a c0 19 10 f0 	movzbl -0xfefe640(%edx),%ecx
f0100271:	31 c8                	xor    %ecx,%eax
f0100273:	a3 00 23 11 f0       	mov    %eax,0xf0112300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100278:	89 c1                	mov    %eax,%ecx
f010027a:	83 e1 03             	and    $0x3,%ecx
f010027d:	8b 0c 8d a0 19 10 f0 	mov    -0xfefe660(,%ecx,4),%ecx
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
f01002bb:	68 64 19 10 f0       	push   $0xf0101964
f01002c0:	e8 99 06 00 00       	call   f010095e <cprintf>
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
f0100469:	e8 21 10 00 00       	call   f010148f <memmove>
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
f0100638:	68 70 19 10 f0       	push   $0xf0101970
f010063d:	e8 1c 03 00 00       	call   f010095e <cprintf>
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
f010067e:	68 c0 1b 10 f0       	push   $0xf0101bc0
f0100683:	68 de 1b 10 f0       	push   $0xf0101bde
f0100688:	68 e3 1b 10 f0       	push   $0xf0101be3
f010068d:	e8 cc 02 00 00       	call   f010095e <cprintf>
f0100692:	83 c4 0c             	add    $0xc,%esp
f0100695:	68 7c 1c 10 f0       	push   $0xf0101c7c
f010069a:	68 ec 1b 10 f0       	push   $0xf0101bec
f010069f:	68 e3 1b 10 f0       	push   $0xf0101be3
f01006a4:	e8 b5 02 00 00       	call   f010095e <cprintf>
f01006a9:	83 c4 0c             	add    $0xc,%esp
f01006ac:	68 a4 1c 10 f0       	push   $0xf0101ca4
f01006b1:	68 f5 1b 10 f0       	push   $0xf0101bf5
f01006b6:	68 e3 1b 10 f0       	push   $0xf0101be3
f01006bb:	e8 9e 02 00 00       	call   f010095e <cprintf>
	return 0;
}
f01006c0:	b8 00 00 00 00       	mov    $0x0,%eax
f01006c5:	c9                   	leave  
f01006c6:	c3                   	ret    

f01006c7 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006c7:	55                   	push   %ebp
f01006c8:	89 e5                	mov    %esp,%ebp
f01006ca:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006cd:	68 ff 1b 10 f0       	push   $0xf0101bff
f01006d2:	e8 87 02 00 00       	call   f010095e <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006d7:	83 c4 08             	add    $0x8,%esp
f01006da:	68 0c 00 10 00       	push   $0x10000c
f01006df:	68 c4 1c 10 f0       	push   $0xf0101cc4
f01006e4:	e8 75 02 00 00       	call   f010095e <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006e9:	83 c4 0c             	add    $0xc,%esp
f01006ec:	68 0c 00 10 00       	push   $0x10000c
f01006f1:	68 0c 00 10 f0       	push   $0xf010000c
f01006f6:	68 ec 1c 10 f0       	push   $0xf0101cec
f01006fb:	e8 5e 02 00 00       	call   f010095e <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100700:	83 c4 0c             	add    $0xc,%esp
f0100703:	68 d1 18 10 00       	push   $0x1018d1
f0100708:	68 d1 18 10 f0       	push   $0xf01018d1
f010070d:	68 10 1d 10 f0       	push   $0xf0101d10
f0100712:	e8 47 02 00 00       	call   f010095e <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100717:	83 c4 0c             	add    $0xc,%esp
f010071a:	68 00 23 11 00       	push   $0x112300
f010071f:	68 00 23 11 f0       	push   $0xf0112300
f0100724:	68 34 1d 10 f0       	push   $0xf0101d34
f0100729:	e8 30 02 00 00       	call   f010095e <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010072e:	83 c4 0c             	add    $0xc,%esp
f0100731:	68 44 29 11 00       	push   $0x112944
f0100736:	68 44 29 11 f0       	push   $0xf0112944
f010073b:	68 58 1d 10 f0       	push   $0xf0101d58
f0100740:	e8 19 02 00 00       	call   f010095e <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100745:	b8 43 2d 11 f0       	mov    $0xf0112d43,%eax
f010074a:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f010074f:	83 c4 08             	add    $0x8,%esp
f0100752:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f0100757:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010075d:	85 c0                	test   %eax,%eax
f010075f:	0f 48 c2             	cmovs  %edx,%eax
f0100762:	c1 f8 0a             	sar    $0xa,%eax
f0100765:	50                   	push   %eax
f0100766:	68 7c 1d 10 f0       	push   $0xf0101d7c
f010076b:	e8 ee 01 00 00       	call   f010095e <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100770:	b8 00 00 00 00       	mov    $0x0,%eax
f0100775:	c9                   	leave  
f0100776:	c3                   	ret    

f0100777 <mon_backtrace>:


int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100777:	55                   	push   %ebp
f0100778:	89 e5                	mov    %esp,%ebp
f010077a:	56                   	push   %esi
f010077b:	53                   	push   %ebx
f010077c:	83 ec 2c             	sub    $0x2c,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f010077f:	89 eb                	mov    %ebp,%ebx
	struct Eipdebuginfo info;
	uint32_t* test_ebp = (uint32_t*) read_ebp();
	cprintf("Stack backtrace:\n");
f0100781:	68 18 1c 10 f0       	push   $0xf0101c18
f0100786:	e8 d3 01 00 00       	call   f010095e <cprintf>
	while (test_ebp)
f010078b:	83 c4 10             	add    $0x10,%esp
	 {
		cprintf("  ebp %08x eip %08x args %08x %08x %08x %08x %08x",test_ebp, test_ebp[1],test_ebp[2],test_ebp[3],test_ebp[4],test_ebp[5], test_ebp[6]);
		debuginfo_eip(test_ebp[1],&info);
f010078e:	8d 75 e0             	lea    -0x20(%ebp),%esi
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	struct Eipdebuginfo info;
	uint32_t* test_ebp = (uint32_t*) read_ebp();
	cprintf("Stack backtrace:\n");
	while (test_ebp)
f0100791:	eb 4e                	jmp    f01007e1 <mon_backtrace+0x6a>
	 {
		cprintf("  ebp %08x eip %08x args %08x %08x %08x %08x %08x",test_ebp, test_ebp[1],test_ebp[2],test_ebp[3],test_ebp[4],test_ebp[5], test_ebp[6]);
f0100793:	ff 73 18             	pushl  0x18(%ebx)
f0100796:	ff 73 14             	pushl  0x14(%ebx)
f0100799:	ff 73 10             	pushl  0x10(%ebx)
f010079c:	ff 73 0c             	pushl  0xc(%ebx)
f010079f:	ff 73 08             	pushl  0x8(%ebx)
f01007a2:	ff 73 04             	pushl  0x4(%ebx)
f01007a5:	53                   	push   %ebx
f01007a6:	68 a8 1d 10 f0       	push   $0xf0101da8
f01007ab:	e8 ae 01 00 00       	call   f010095e <cprintf>
		debuginfo_eip(test_ebp[1],&info);
f01007b0:	83 c4 18             	add    $0x18,%esp
f01007b3:	56                   	push   %esi
f01007b4:	ff 73 04             	pushl  0x4(%ebx)
f01007b7:	e8 ac 02 00 00       	call   f0100a68 <debuginfo_eip>
		cprintf("\t    %s:%d: %.*s+%d\n",info.eip_file,info.eip_line,info.eip_fn_namelen,info.eip_fn_name,test_ebp[1] - info.eip_fn_addr);
f01007bc:	83 c4 08             	add    $0x8,%esp
f01007bf:	8b 43 04             	mov    0x4(%ebx),%eax
f01007c2:	2b 45 f0             	sub    -0x10(%ebp),%eax
f01007c5:	50                   	push   %eax
f01007c6:	ff 75 e8             	pushl  -0x18(%ebp)
f01007c9:	ff 75 ec             	pushl  -0x14(%ebp)
f01007cc:	ff 75 e4             	pushl  -0x1c(%ebp)
f01007cf:	ff 75 e0             	pushl  -0x20(%ebp)
f01007d2:	68 2a 1c 10 f0       	push   $0xf0101c2a
f01007d7:	e8 82 01 00 00       	call   f010095e <cprintf>
		test_ebp = (uint32_t*) *test_ebp;
f01007dc:	8b 1b                	mov    (%ebx),%ebx
f01007de:	83 c4 20             	add    $0x20,%esp
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	struct Eipdebuginfo info;
	uint32_t* test_ebp = (uint32_t*) read_ebp();
	cprintf("Stack backtrace:\n");
	while (test_ebp)
f01007e1:	85 db                	test   %ebx,%ebx
f01007e3:	75 ae                	jne    f0100793 <mon_backtrace+0x1c>
		debuginfo_eip(test_ebp[1],&info);
		cprintf("\t    %s:%d: %.*s+%d\n",info.eip_file,info.eip_line,info.eip_fn_namelen,info.eip_fn_name,test_ebp[1] - info.eip_fn_addr);
		test_ebp = (uint32_t*) *test_ebp;
	}
return 0;
}
f01007e5:	b8 00 00 00 00       	mov    $0x0,%eax
f01007ea:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01007ed:	5b                   	pop    %ebx
f01007ee:	5e                   	pop    %esi
f01007ef:	5d                   	pop    %ebp
f01007f0:	c3                   	ret    

f01007f1 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007f1:	55                   	push   %ebp
f01007f2:	89 e5                	mov    %esp,%ebp
f01007f4:	57                   	push   %edi
f01007f5:	56                   	push   %esi
f01007f6:	53                   	push   %ebx
f01007f7:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007fa:	68 dc 1d 10 f0       	push   $0xf0101ddc
f01007ff:	e8 5a 01 00 00       	call   f010095e <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100804:	c7 04 24 00 1e 10 f0 	movl   $0xf0101e00,(%esp)
f010080b:	e8 4e 01 00 00       	call   f010095e <cprintf>
f0100810:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f0100813:	83 ec 0c             	sub    $0xc,%esp
f0100816:	68 3f 1c 10 f0       	push   $0xf0101c3f
f010081b:	e8 cb 09 00 00       	call   f01011eb <readline>
f0100820:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100822:	83 c4 10             	add    $0x10,%esp
f0100825:	85 c0                	test   %eax,%eax
f0100827:	74 ea                	je     f0100813 <monitor+0x22>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100829:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100830:	be 00 00 00 00       	mov    $0x0,%esi
f0100835:	eb 0a                	jmp    f0100841 <monitor+0x50>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100837:	c6 03 00             	movb   $0x0,(%ebx)
f010083a:	89 f7                	mov    %esi,%edi
f010083c:	8d 5b 01             	lea    0x1(%ebx),%ebx
f010083f:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100841:	0f b6 03             	movzbl (%ebx),%eax
f0100844:	84 c0                	test   %al,%al
f0100846:	74 63                	je     f01008ab <monitor+0xba>
f0100848:	83 ec 08             	sub    $0x8,%esp
f010084b:	0f be c0             	movsbl %al,%eax
f010084e:	50                   	push   %eax
f010084f:	68 43 1c 10 f0       	push   $0xf0101c43
f0100854:	e8 ac 0b 00 00       	call   f0101405 <strchr>
f0100859:	83 c4 10             	add    $0x10,%esp
f010085c:	85 c0                	test   %eax,%eax
f010085e:	75 d7                	jne    f0100837 <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f0100860:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100863:	74 46                	je     f01008ab <monitor+0xba>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100865:	83 fe 0f             	cmp    $0xf,%esi
f0100868:	75 14                	jne    f010087e <monitor+0x8d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f010086a:	83 ec 08             	sub    $0x8,%esp
f010086d:	6a 10                	push   $0x10
f010086f:	68 48 1c 10 f0       	push   $0xf0101c48
f0100874:	e8 e5 00 00 00       	call   f010095e <cprintf>
f0100879:	83 c4 10             	add    $0x10,%esp
f010087c:	eb 95                	jmp    f0100813 <monitor+0x22>
			return 0;
		}
		argv[argc++] = buf;
f010087e:	8d 7e 01             	lea    0x1(%esi),%edi
f0100881:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100885:	eb 03                	jmp    f010088a <monitor+0x99>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100887:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010088a:	0f b6 03             	movzbl (%ebx),%eax
f010088d:	84 c0                	test   %al,%al
f010088f:	74 ae                	je     f010083f <monitor+0x4e>
f0100891:	83 ec 08             	sub    $0x8,%esp
f0100894:	0f be c0             	movsbl %al,%eax
f0100897:	50                   	push   %eax
f0100898:	68 43 1c 10 f0       	push   $0xf0101c43
f010089d:	e8 63 0b 00 00       	call   f0101405 <strchr>
f01008a2:	83 c4 10             	add    $0x10,%esp
f01008a5:	85 c0                	test   %eax,%eax
f01008a7:	74 de                	je     f0100887 <monitor+0x96>
f01008a9:	eb 94                	jmp    f010083f <monitor+0x4e>
			buf++;
	}
	argv[argc] = 0;
f01008ab:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01008b2:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01008b3:	85 f6                	test   %esi,%esi
f01008b5:	0f 84 58 ff ff ff    	je     f0100813 <monitor+0x22>
f01008bb:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01008c0:	83 ec 08             	sub    $0x8,%esp
f01008c3:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01008c6:	ff 34 85 40 1e 10 f0 	pushl  -0xfefe1c0(,%eax,4)
f01008cd:	ff 75 a8             	pushl  -0x58(%ebp)
f01008d0:	e8 d2 0a 00 00       	call   f01013a7 <strcmp>
f01008d5:	83 c4 10             	add    $0x10,%esp
f01008d8:	85 c0                	test   %eax,%eax
f01008da:	75 21                	jne    f01008fd <monitor+0x10c>
			return commands[i].func(argc, argv, tf);
f01008dc:	83 ec 04             	sub    $0x4,%esp
f01008df:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01008e2:	ff 75 08             	pushl  0x8(%ebp)
f01008e5:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01008e8:	52                   	push   %edx
f01008e9:	56                   	push   %esi
f01008ea:	ff 14 85 48 1e 10 f0 	call   *-0xfefe1b8(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008f1:	83 c4 10             	add    $0x10,%esp
f01008f4:	85 c0                	test   %eax,%eax
f01008f6:	78 25                	js     f010091d <monitor+0x12c>
f01008f8:	e9 16 ff ff ff       	jmp    f0100813 <monitor+0x22>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f01008fd:	83 c3 01             	add    $0x1,%ebx
f0100900:	83 fb 03             	cmp    $0x3,%ebx
f0100903:	75 bb                	jne    f01008c0 <monitor+0xcf>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100905:	83 ec 08             	sub    $0x8,%esp
f0100908:	ff 75 a8             	pushl  -0x58(%ebp)
f010090b:	68 65 1c 10 f0       	push   $0xf0101c65
f0100910:	e8 49 00 00 00       	call   f010095e <cprintf>
f0100915:	83 c4 10             	add    $0x10,%esp
f0100918:	e9 f6 fe ff ff       	jmp    f0100813 <monitor+0x22>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f010091d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100920:	5b                   	pop    %ebx
f0100921:	5e                   	pop    %esi
f0100922:	5f                   	pop    %edi
f0100923:	5d                   	pop    %ebp
f0100924:	c3                   	ret    

f0100925 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100925:	55                   	push   %ebp
f0100926:	89 e5                	mov    %esp,%ebp
f0100928:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f010092b:	ff 75 08             	pushl  0x8(%ebp)
f010092e:	e8 1a fd ff ff       	call   f010064d <cputchar>
	*cnt++;
}
f0100933:	83 c4 10             	add    $0x10,%esp
f0100936:	c9                   	leave  
f0100937:	c3                   	ret    

f0100938 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100938:	55                   	push   %ebp
f0100939:	89 e5                	mov    %esp,%ebp
f010093b:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f010093e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100945:	ff 75 0c             	pushl  0xc(%ebp)
f0100948:	ff 75 08             	pushl  0x8(%ebp)
f010094b:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010094e:	50                   	push   %eax
f010094f:	68 25 09 10 f0       	push   $0xf0100925
f0100954:	e8 5d 04 00 00       	call   f0100db6 <vprintfmt>
	return cnt;
}
f0100959:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010095c:	c9                   	leave  
f010095d:	c3                   	ret    

f010095e <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010095e:	55                   	push   %ebp
f010095f:	89 e5                	mov    %esp,%ebp
f0100961:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100964:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100967:	50                   	push   %eax
f0100968:	ff 75 08             	pushl  0x8(%ebp)
f010096b:	e8 c8 ff ff ff       	call   f0100938 <vcprintf>
	va_end(ap);

	return cnt;
}
f0100970:	c9                   	leave  
f0100971:	c3                   	ret    

f0100972 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100972:	55                   	push   %ebp
f0100973:	89 e5                	mov    %esp,%ebp
f0100975:	57                   	push   %edi
f0100976:	56                   	push   %esi
f0100977:	53                   	push   %ebx
f0100978:	83 ec 14             	sub    $0x14,%esp
f010097b:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010097e:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100981:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100984:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100987:	8b 1a                	mov    (%edx),%ebx
f0100989:	8b 01                	mov    (%ecx),%eax
f010098b:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010098e:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0100995:	eb 7f                	jmp    f0100a16 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f0100997:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010099a:	01 d8                	add    %ebx,%eax
f010099c:	89 c6                	mov    %eax,%esi
f010099e:	c1 ee 1f             	shr    $0x1f,%esi
f01009a1:	01 c6                	add    %eax,%esi
f01009a3:	d1 fe                	sar    %esi
f01009a5:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01009a8:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01009ab:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01009ae:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01009b0:	eb 03                	jmp    f01009b5 <stab_binsearch+0x43>
			m--;
f01009b2:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01009b5:	39 c3                	cmp    %eax,%ebx
f01009b7:	7f 0d                	jg     f01009c6 <stab_binsearch+0x54>
f01009b9:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01009bd:	83 ea 0c             	sub    $0xc,%edx
f01009c0:	39 f9                	cmp    %edi,%ecx
f01009c2:	75 ee                	jne    f01009b2 <stab_binsearch+0x40>
f01009c4:	eb 05                	jmp    f01009cb <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01009c6:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f01009c9:	eb 4b                	jmp    f0100a16 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01009cb:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01009ce:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01009d1:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01009d5:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01009d8:	76 11                	jbe    f01009eb <stab_binsearch+0x79>
			*region_left = m;
f01009da:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01009dd:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01009df:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01009e2:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01009e9:	eb 2b                	jmp    f0100a16 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01009eb:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01009ee:	73 14                	jae    f0100a04 <stab_binsearch+0x92>
			*region_right = m - 1;
f01009f0:	83 e8 01             	sub    $0x1,%eax
f01009f3:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01009f6:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01009f9:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01009fb:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100a02:	eb 12                	jmp    f0100a16 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100a04:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100a07:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0100a09:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0100a0d:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a0f:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100a16:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100a19:	0f 8e 78 ff ff ff    	jle    f0100997 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100a1f:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0100a23:	75 0f                	jne    f0100a34 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0100a25:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a28:	8b 00                	mov    (%eax),%eax
f0100a2a:	83 e8 01             	sub    $0x1,%eax
f0100a2d:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100a30:	89 06                	mov    %eax,(%esi)
f0100a32:	eb 2c                	jmp    f0100a60 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a34:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a37:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100a39:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100a3c:	8b 0e                	mov    (%esi),%ecx
f0100a3e:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100a41:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0100a44:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a47:	eb 03                	jmp    f0100a4c <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100a49:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a4c:	39 c8                	cmp    %ecx,%eax
f0100a4e:	7e 0b                	jle    f0100a5b <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0100a50:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0100a54:	83 ea 0c             	sub    $0xc,%edx
f0100a57:	39 df                	cmp    %ebx,%edi
f0100a59:	75 ee                	jne    f0100a49 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100a5b:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100a5e:	89 06                	mov    %eax,(%esi)
	}
}
f0100a60:	83 c4 14             	add    $0x14,%esp
f0100a63:	5b                   	pop    %ebx
f0100a64:	5e                   	pop    %esi
f0100a65:	5f                   	pop    %edi
f0100a66:	5d                   	pop    %ebp
f0100a67:	c3                   	ret    

f0100a68 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100a68:	55                   	push   %ebp
f0100a69:	89 e5                	mov    %esp,%ebp
f0100a6b:	57                   	push   %edi
f0100a6c:	56                   	push   %esi
f0100a6d:	53                   	push   %ebx
f0100a6e:	83 ec 3c             	sub    $0x3c,%esp
f0100a71:	8b 75 08             	mov    0x8(%ebp),%esi
f0100a74:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100a77:	c7 03 64 1e 10 f0    	movl   $0xf0101e64,(%ebx)
	info->eip_line = 0;
f0100a7d:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100a84:	c7 43 08 64 1e 10 f0 	movl   $0xf0101e64,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100a8b:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100a92:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100a95:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100a9c:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100aa2:	76 11                	jbe    f0100ab5 <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100aa4:	b8 40 73 10 f0       	mov    $0xf0107340,%eax
f0100aa9:	3d 1d 5a 10 f0       	cmp    $0xf0105a1d,%eax
f0100aae:	77 19                	ja     f0100ac9 <debuginfo_eip+0x61>
f0100ab0:	e9 b5 01 00 00       	jmp    f0100c6a <debuginfo_eip+0x202>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100ab5:	83 ec 04             	sub    $0x4,%esp
f0100ab8:	68 6e 1e 10 f0       	push   $0xf0101e6e
f0100abd:	6a 7f                	push   $0x7f
f0100abf:	68 7b 1e 10 f0       	push   $0xf0101e7b
f0100ac4:	e8 1d f6 ff ff       	call   f01000e6 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100ac9:	80 3d 3f 73 10 f0 00 	cmpb   $0x0,0xf010733f
f0100ad0:	0f 85 9b 01 00 00    	jne    f0100c71 <debuginfo_eip+0x209>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100ad6:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100add:	b8 1c 5a 10 f0       	mov    $0xf0105a1c,%eax
f0100ae2:	2d b0 20 10 f0       	sub    $0xf01020b0,%eax
f0100ae7:	c1 f8 02             	sar    $0x2,%eax
f0100aea:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100af0:	83 e8 01             	sub    $0x1,%eax
f0100af3:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100af6:	83 ec 08             	sub    $0x8,%esp
f0100af9:	56                   	push   %esi
f0100afa:	6a 64                	push   $0x64
f0100afc:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100aff:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100b02:	b8 b0 20 10 f0       	mov    $0xf01020b0,%eax
f0100b07:	e8 66 fe ff ff       	call   f0100972 <stab_binsearch>
	if (lfile == 0)
f0100b0c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b0f:	83 c4 10             	add    $0x10,%esp
f0100b12:	85 c0                	test   %eax,%eax
f0100b14:	0f 84 5e 01 00 00    	je     f0100c78 <debuginfo_eip+0x210>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100b1a:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100b1d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b20:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100b23:	83 ec 08             	sub    $0x8,%esp
f0100b26:	56                   	push   %esi
f0100b27:	6a 24                	push   $0x24
f0100b29:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100b2c:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100b2f:	b8 b0 20 10 f0       	mov    $0xf01020b0,%eax
f0100b34:	e8 39 fe ff ff       	call   f0100972 <stab_binsearch>

	if (lfun <= rfun) {
f0100b39:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100b3c:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100b3f:	83 c4 10             	add    $0x10,%esp
f0100b42:	39 d0                	cmp    %edx,%eax
f0100b44:	7f 40                	jg     f0100b86 <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100b46:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0100b49:	c1 e1 02             	shl    $0x2,%ecx
f0100b4c:	8d b9 b0 20 10 f0    	lea    -0xfefdf50(%ecx),%edi
f0100b52:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0100b55:	8b b9 b0 20 10 f0    	mov    -0xfefdf50(%ecx),%edi
f0100b5b:	b9 40 73 10 f0       	mov    $0xf0107340,%ecx
f0100b60:	81 e9 1d 5a 10 f0    	sub    $0xf0105a1d,%ecx
f0100b66:	39 cf                	cmp    %ecx,%edi
f0100b68:	73 09                	jae    f0100b73 <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100b6a:	81 c7 1d 5a 10 f0    	add    $0xf0105a1d,%edi
f0100b70:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100b73:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100b76:	8b 4f 08             	mov    0x8(%edi),%ecx
f0100b79:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100b7c:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100b7e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100b81:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0100b84:	eb 0f                	jmp    f0100b95 <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100b86:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100b89:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b8c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100b8f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b92:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100b95:	83 ec 08             	sub    $0x8,%esp
f0100b98:	6a 3a                	push   $0x3a
f0100b9a:	ff 73 08             	pushl  0x8(%ebx)
f0100b9d:	e8 84 08 00 00       	call   f0101426 <strfind>
f0100ba2:	2b 43 08             	sub    0x8(%ebx),%eax
f0100ba5:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0100ba8:	83 c4 08             	add    $0x8,%esp
f0100bab:	56                   	push   %esi
f0100bac:	6a 44                	push   $0x44
f0100bae:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100bb1:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100bb4:	b8 b0 20 10 f0       	mov    $0xf01020b0,%eax
f0100bb9:	e8 b4 fd ff ff       	call   f0100972 <stab_binsearch>
	//cprintf("%d	%d",lline,rline);
	if(lline <= rline)
f0100bbe:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100bc1:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0100bc4:	83 c4 10             	add    $0x10,%esp
f0100bc7:	39 d0                	cmp    %edx,%eax
f0100bc9:	0f 8f b0 00 00 00    	jg     f0100c7f <debuginfo_eip+0x217>
		info->eip_line = stabs[rline].n_desc;
f0100bcf:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0100bd2:	0f b7 14 95 b6 20 10 	movzwl -0xfefdf4a(,%edx,4),%edx
f0100bd9:	f0 
f0100bda:	89 53 04             	mov    %edx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100bdd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100be0:	89 c2                	mov    %eax,%edx
f0100be2:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0100be5:	8d 04 85 b0 20 10 f0 	lea    -0xfefdf50(,%eax,4),%eax
f0100bec:	eb 06                	jmp    f0100bf4 <debuginfo_eip+0x18c>
f0100bee:	83 ea 01             	sub    $0x1,%edx
f0100bf1:	83 e8 0c             	sub    $0xc,%eax
f0100bf4:	39 d7                	cmp    %edx,%edi
f0100bf6:	7f 34                	jg     f0100c2c <debuginfo_eip+0x1c4>
	       && stabs[lline].n_type != N_SOL
f0100bf8:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0100bfc:	80 f9 84             	cmp    $0x84,%cl
f0100bff:	74 0b                	je     f0100c0c <debuginfo_eip+0x1a4>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100c01:	80 f9 64             	cmp    $0x64,%cl
f0100c04:	75 e8                	jne    f0100bee <debuginfo_eip+0x186>
f0100c06:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0100c0a:	74 e2                	je     f0100bee <debuginfo_eip+0x186>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100c0c:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0100c0f:	8b 14 85 b0 20 10 f0 	mov    -0xfefdf50(,%eax,4),%edx
f0100c16:	b8 40 73 10 f0       	mov    $0xf0107340,%eax
f0100c1b:	2d 1d 5a 10 f0       	sub    $0xf0105a1d,%eax
f0100c20:	39 c2                	cmp    %eax,%edx
f0100c22:	73 08                	jae    f0100c2c <debuginfo_eip+0x1c4>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100c24:	81 c2 1d 5a 10 f0    	add    $0xf0105a1d,%edx
f0100c2a:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c2c:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100c2f:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c32:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c37:	39 f2                	cmp    %esi,%edx
f0100c39:	7d 50                	jge    f0100c8b <debuginfo_eip+0x223>
		for (lline = lfun + 1;
f0100c3b:	83 c2 01             	add    $0x1,%edx
f0100c3e:	89 d0                	mov    %edx,%eax
f0100c40:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0100c43:	8d 14 95 b0 20 10 f0 	lea    -0xfefdf50(,%edx,4),%edx
f0100c4a:	eb 04                	jmp    f0100c50 <debuginfo_eip+0x1e8>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100c4c:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100c50:	39 c6                	cmp    %eax,%esi
f0100c52:	7e 32                	jle    f0100c86 <debuginfo_eip+0x21e>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100c54:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0100c58:	83 c0 01             	add    $0x1,%eax
f0100c5b:	83 c2 0c             	add    $0xc,%edx
f0100c5e:	80 f9 a0             	cmp    $0xa0,%cl
f0100c61:	74 e9                	je     f0100c4c <debuginfo_eip+0x1e4>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c63:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c68:	eb 21                	jmp    f0100c8b <debuginfo_eip+0x223>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100c6a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c6f:	eb 1a                	jmp    f0100c8b <debuginfo_eip+0x223>
f0100c71:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c76:	eb 13                	jmp    f0100c8b <debuginfo_eip+0x223>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100c78:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c7d:	eb 0c                	jmp    f0100c8b <debuginfo_eip+0x223>
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
	//cprintf("%d	%d",lline,rline);
	if(lline <= rline)
		info->eip_line = stabs[rline].n_desc;
	else
		return -1;
f0100c7f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c84:	eb 05                	jmp    f0100c8b <debuginfo_eip+0x223>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c86:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100c8b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100c8e:	5b                   	pop    %ebx
f0100c8f:	5e                   	pop    %esi
f0100c90:	5f                   	pop    %edi
f0100c91:	5d                   	pop    %ebp
f0100c92:	c3                   	ret    

f0100c93 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100c93:	55                   	push   %ebp
f0100c94:	89 e5                	mov    %esp,%ebp
f0100c96:	57                   	push   %edi
f0100c97:	56                   	push   %esi
f0100c98:	53                   	push   %ebx
f0100c99:	83 ec 1c             	sub    $0x1c,%esp
f0100c9c:	89 c7                	mov    %eax,%edi
f0100c9e:	89 d6                	mov    %edx,%esi
f0100ca0:	8b 45 08             	mov    0x8(%ebp),%eax
f0100ca3:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100ca6:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100ca9:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100cac:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0100caf:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100cb4:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100cb7:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0100cba:	39 d3                	cmp    %edx,%ebx
f0100cbc:	72 05                	jb     f0100cc3 <printnum+0x30>
f0100cbe:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100cc1:	77 45                	ja     f0100d08 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100cc3:	83 ec 0c             	sub    $0xc,%esp
f0100cc6:	ff 75 18             	pushl  0x18(%ebp)
f0100cc9:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ccc:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0100ccf:	53                   	push   %ebx
f0100cd0:	ff 75 10             	pushl  0x10(%ebp)
f0100cd3:	83 ec 08             	sub    $0x8,%esp
f0100cd6:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100cd9:	ff 75 e0             	pushl  -0x20(%ebp)
f0100cdc:	ff 75 dc             	pushl  -0x24(%ebp)
f0100cdf:	ff 75 d8             	pushl  -0x28(%ebp)
f0100ce2:	e8 69 09 00 00       	call   f0101650 <__udivdi3>
f0100ce7:	83 c4 18             	add    $0x18,%esp
f0100cea:	52                   	push   %edx
f0100ceb:	50                   	push   %eax
f0100cec:	89 f2                	mov    %esi,%edx
f0100cee:	89 f8                	mov    %edi,%eax
f0100cf0:	e8 9e ff ff ff       	call   f0100c93 <printnum>
f0100cf5:	83 c4 20             	add    $0x20,%esp
f0100cf8:	eb 18                	jmp    f0100d12 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100cfa:	83 ec 08             	sub    $0x8,%esp
f0100cfd:	56                   	push   %esi
f0100cfe:	ff 75 18             	pushl  0x18(%ebp)
f0100d01:	ff d7                	call   *%edi
f0100d03:	83 c4 10             	add    $0x10,%esp
f0100d06:	eb 03                	jmp    f0100d0b <printnum+0x78>
f0100d08:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100d0b:	83 eb 01             	sub    $0x1,%ebx
f0100d0e:	85 db                	test   %ebx,%ebx
f0100d10:	7f e8                	jg     f0100cfa <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100d12:	83 ec 08             	sub    $0x8,%esp
f0100d15:	56                   	push   %esi
f0100d16:	83 ec 04             	sub    $0x4,%esp
f0100d19:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100d1c:	ff 75 e0             	pushl  -0x20(%ebp)
f0100d1f:	ff 75 dc             	pushl  -0x24(%ebp)
f0100d22:	ff 75 d8             	pushl  -0x28(%ebp)
f0100d25:	e8 56 0a 00 00       	call   f0101780 <__umoddi3>
f0100d2a:	83 c4 14             	add    $0x14,%esp
f0100d2d:	0f be 80 89 1e 10 f0 	movsbl -0xfefe177(%eax),%eax
f0100d34:	50                   	push   %eax
f0100d35:	ff d7                	call   *%edi
}
f0100d37:	83 c4 10             	add    $0x10,%esp
f0100d3a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100d3d:	5b                   	pop    %ebx
f0100d3e:	5e                   	pop    %esi
f0100d3f:	5f                   	pop    %edi
f0100d40:	5d                   	pop    %ebp
f0100d41:	c3                   	ret    

f0100d42 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100d42:	55                   	push   %ebp
f0100d43:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100d45:	83 fa 01             	cmp    $0x1,%edx
f0100d48:	7e 0e                	jle    f0100d58 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100d4a:	8b 10                	mov    (%eax),%edx
f0100d4c:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100d4f:	89 08                	mov    %ecx,(%eax)
f0100d51:	8b 02                	mov    (%edx),%eax
f0100d53:	8b 52 04             	mov    0x4(%edx),%edx
f0100d56:	eb 22                	jmp    f0100d7a <getuint+0x38>
	else if (lflag)
f0100d58:	85 d2                	test   %edx,%edx
f0100d5a:	74 10                	je     f0100d6c <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100d5c:	8b 10                	mov    (%eax),%edx
f0100d5e:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100d61:	89 08                	mov    %ecx,(%eax)
f0100d63:	8b 02                	mov    (%edx),%eax
f0100d65:	ba 00 00 00 00       	mov    $0x0,%edx
f0100d6a:	eb 0e                	jmp    f0100d7a <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100d6c:	8b 10                	mov    (%eax),%edx
f0100d6e:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100d71:	89 08                	mov    %ecx,(%eax)
f0100d73:	8b 02                	mov    (%edx),%eax
f0100d75:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100d7a:	5d                   	pop    %ebp
f0100d7b:	c3                   	ret    

f0100d7c <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100d7c:	55                   	push   %ebp
f0100d7d:	89 e5                	mov    %esp,%ebp
f0100d7f:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100d82:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100d86:	8b 10                	mov    (%eax),%edx
f0100d88:	3b 50 04             	cmp    0x4(%eax),%edx
f0100d8b:	73 0a                	jae    f0100d97 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100d8d:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100d90:	89 08                	mov    %ecx,(%eax)
f0100d92:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d95:	88 02                	mov    %al,(%edx)
}
f0100d97:	5d                   	pop    %ebp
f0100d98:	c3                   	ret    

f0100d99 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100d99:	55                   	push   %ebp
f0100d9a:	89 e5                	mov    %esp,%ebp
f0100d9c:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100d9f:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100da2:	50                   	push   %eax
f0100da3:	ff 75 10             	pushl  0x10(%ebp)
f0100da6:	ff 75 0c             	pushl  0xc(%ebp)
f0100da9:	ff 75 08             	pushl  0x8(%ebp)
f0100dac:	e8 05 00 00 00       	call   f0100db6 <vprintfmt>
	va_end(ap);
}
f0100db1:	83 c4 10             	add    $0x10,%esp
f0100db4:	c9                   	leave  
f0100db5:	c3                   	ret    

f0100db6 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100db6:	55                   	push   %ebp
f0100db7:	89 e5                	mov    %esp,%ebp
f0100db9:	57                   	push   %edi
f0100dba:	56                   	push   %esi
f0100dbb:	53                   	push   %ebx
f0100dbc:	83 ec 2c             	sub    $0x2c,%esp
f0100dbf:	8b 75 08             	mov    0x8(%ebp),%esi
f0100dc2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100dc5:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100dc8:	eb 12                	jmp    f0100ddc <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100dca:	85 c0                	test   %eax,%eax
f0100dcc:	0f 84 a9 03 00 00    	je     f010117b <vprintfmt+0x3c5>
				return;
			putch(ch, putdat);
f0100dd2:	83 ec 08             	sub    $0x8,%esp
f0100dd5:	53                   	push   %ebx
f0100dd6:	50                   	push   %eax
f0100dd7:	ff d6                	call   *%esi
f0100dd9:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100ddc:	83 c7 01             	add    $0x1,%edi
f0100ddf:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0100de3:	83 f8 25             	cmp    $0x25,%eax
f0100de6:	75 e2                	jne    f0100dca <vprintfmt+0x14>
f0100de8:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0100dec:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100df3:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100dfa:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0100e01:	ba 00 00 00 00       	mov    $0x0,%edx
f0100e06:	eb 07                	jmp    f0100e0f <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e08:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100e0b:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e0f:	8d 47 01             	lea    0x1(%edi),%eax
f0100e12:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100e15:	0f b6 07             	movzbl (%edi),%eax
f0100e18:	0f b6 c8             	movzbl %al,%ecx
f0100e1b:	83 e8 23             	sub    $0x23,%eax
f0100e1e:	3c 55                	cmp    $0x55,%al
f0100e20:	0f 87 3a 03 00 00    	ja     f0101160 <vprintfmt+0x3aa>
f0100e26:	0f b6 c0             	movzbl %al,%eax
f0100e29:	ff 24 85 20 1f 10 f0 	jmp    *-0xfefe0e0(,%eax,4)
f0100e30:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100e33:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0100e37:	eb d6                	jmp    f0100e0f <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e39:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100e3c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e41:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100e44:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100e47:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0100e4b:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0100e4e:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0100e51:	83 fa 09             	cmp    $0x9,%edx
f0100e54:	77 39                	ja     f0100e8f <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100e56:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0100e59:	eb e9                	jmp    f0100e44 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100e5b:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e5e:	8d 48 04             	lea    0x4(%eax),%ecx
f0100e61:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0100e64:	8b 00                	mov    (%eax),%eax
f0100e66:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e69:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100e6c:	eb 27                	jmp    f0100e95 <vprintfmt+0xdf>
f0100e6e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100e71:	85 c0                	test   %eax,%eax
f0100e73:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100e78:	0f 49 c8             	cmovns %eax,%ecx
f0100e7b:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e7e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100e81:	eb 8c                	jmp    f0100e0f <vprintfmt+0x59>
f0100e83:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100e86:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0100e8d:	eb 80                	jmp    f0100e0f <vprintfmt+0x59>
f0100e8f:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100e92:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0100e95:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100e99:	0f 89 70 ff ff ff    	jns    f0100e0f <vprintfmt+0x59>
				width = precision, precision = -1;
f0100e9f:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100ea2:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100ea5:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100eac:	e9 5e ff ff ff       	jmp    f0100e0f <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100eb1:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100eb4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100eb7:	e9 53 ff ff ff       	jmp    f0100e0f <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100ebc:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ebf:	8d 50 04             	lea    0x4(%eax),%edx
f0100ec2:	89 55 14             	mov    %edx,0x14(%ebp)
f0100ec5:	83 ec 08             	sub    $0x8,%esp
f0100ec8:	53                   	push   %ebx
f0100ec9:	ff 30                	pushl  (%eax)
f0100ecb:	ff d6                	call   *%esi
			break;
f0100ecd:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ed0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0100ed3:	e9 04 ff ff ff       	jmp    f0100ddc <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100ed8:	8b 45 14             	mov    0x14(%ebp),%eax
f0100edb:	8d 50 04             	lea    0x4(%eax),%edx
f0100ede:	89 55 14             	mov    %edx,0x14(%ebp)
f0100ee1:	8b 00                	mov    (%eax),%eax
f0100ee3:	99                   	cltd   
f0100ee4:	31 d0                	xor    %edx,%eax
f0100ee6:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100ee8:	83 f8 07             	cmp    $0x7,%eax
f0100eeb:	7f 0b                	jg     f0100ef8 <vprintfmt+0x142>
f0100eed:	8b 14 85 80 20 10 f0 	mov    -0xfefdf80(,%eax,4),%edx
f0100ef4:	85 d2                	test   %edx,%edx
f0100ef6:	75 18                	jne    f0100f10 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0100ef8:	50                   	push   %eax
f0100ef9:	68 a1 1e 10 f0       	push   $0xf0101ea1
f0100efe:	53                   	push   %ebx
f0100eff:	56                   	push   %esi
f0100f00:	e8 94 fe ff ff       	call   f0100d99 <printfmt>
f0100f05:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f08:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0100f0b:	e9 cc fe ff ff       	jmp    f0100ddc <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0100f10:	52                   	push   %edx
f0100f11:	68 aa 1e 10 f0       	push   $0xf0101eaa
f0100f16:	53                   	push   %ebx
f0100f17:	56                   	push   %esi
f0100f18:	e8 7c fe ff ff       	call   f0100d99 <printfmt>
f0100f1d:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f20:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100f23:	e9 b4 fe ff ff       	jmp    f0100ddc <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100f28:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f2b:	8d 50 04             	lea    0x4(%eax),%edx
f0100f2e:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f31:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0100f33:	85 ff                	test   %edi,%edi
f0100f35:	b8 9a 1e 10 f0       	mov    $0xf0101e9a,%eax
f0100f3a:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0100f3d:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100f41:	0f 8e 94 00 00 00    	jle    f0100fdb <vprintfmt+0x225>
f0100f47:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0100f4b:	0f 84 98 00 00 00    	je     f0100fe9 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f51:	83 ec 08             	sub    $0x8,%esp
f0100f54:	ff 75 d0             	pushl  -0x30(%ebp)
f0100f57:	57                   	push   %edi
f0100f58:	e8 7f 03 00 00       	call   f01012dc <strnlen>
f0100f5d:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100f60:	29 c1                	sub    %eax,%ecx
f0100f62:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0100f65:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0100f68:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0100f6c:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100f6f:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0100f72:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f74:	eb 0f                	jmp    f0100f85 <vprintfmt+0x1cf>
					putch(padc, putdat);
f0100f76:	83 ec 08             	sub    $0x8,%esp
f0100f79:	53                   	push   %ebx
f0100f7a:	ff 75 e0             	pushl  -0x20(%ebp)
f0100f7d:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f7f:	83 ef 01             	sub    $0x1,%edi
f0100f82:	83 c4 10             	add    $0x10,%esp
f0100f85:	85 ff                	test   %edi,%edi
f0100f87:	7f ed                	jg     f0100f76 <vprintfmt+0x1c0>
f0100f89:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0100f8c:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0100f8f:	85 c9                	test   %ecx,%ecx
f0100f91:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f96:	0f 49 c1             	cmovns %ecx,%eax
f0100f99:	29 c1                	sub    %eax,%ecx
f0100f9b:	89 75 08             	mov    %esi,0x8(%ebp)
f0100f9e:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100fa1:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100fa4:	89 cb                	mov    %ecx,%ebx
f0100fa6:	eb 4d                	jmp    f0100ff5 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0100fa8:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0100fac:	74 1b                	je     f0100fc9 <vprintfmt+0x213>
f0100fae:	0f be c0             	movsbl %al,%eax
f0100fb1:	83 e8 20             	sub    $0x20,%eax
f0100fb4:	83 f8 5e             	cmp    $0x5e,%eax
f0100fb7:	76 10                	jbe    f0100fc9 <vprintfmt+0x213>
					putch('?', putdat);
f0100fb9:	83 ec 08             	sub    $0x8,%esp
f0100fbc:	ff 75 0c             	pushl  0xc(%ebp)
f0100fbf:	6a 3f                	push   $0x3f
f0100fc1:	ff 55 08             	call   *0x8(%ebp)
f0100fc4:	83 c4 10             	add    $0x10,%esp
f0100fc7:	eb 0d                	jmp    f0100fd6 <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0100fc9:	83 ec 08             	sub    $0x8,%esp
f0100fcc:	ff 75 0c             	pushl  0xc(%ebp)
f0100fcf:	52                   	push   %edx
f0100fd0:	ff 55 08             	call   *0x8(%ebp)
f0100fd3:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100fd6:	83 eb 01             	sub    $0x1,%ebx
f0100fd9:	eb 1a                	jmp    f0100ff5 <vprintfmt+0x23f>
f0100fdb:	89 75 08             	mov    %esi,0x8(%ebp)
f0100fde:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100fe1:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100fe4:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100fe7:	eb 0c                	jmp    f0100ff5 <vprintfmt+0x23f>
f0100fe9:	89 75 08             	mov    %esi,0x8(%ebp)
f0100fec:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100fef:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100ff2:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100ff5:	83 c7 01             	add    $0x1,%edi
f0100ff8:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0100ffc:	0f be d0             	movsbl %al,%edx
f0100fff:	85 d2                	test   %edx,%edx
f0101001:	74 23                	je     f0101026 <vprintfmt+0x270>
f0101003:	85 f6                	test   %esi,%esi
f0101005:	78 a1                	js     f0100fa8 <vprintfmt+0x1f2>
f0101007:	83 ee 01             	sub    $0x1,%esi
f010100a:	79 9c                	jns    f0100fa8 <vprintfmt+0x1f2>
f010100c:	89 df                	mov    %ebx,%edi
f010100e:	8b 75 08             	mov    0x8(%ebp),%esi
f0101011:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101014:	eb 18                	jmp    f010102e <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0101016:	83 ec 08             	sub    $0x8,%esp
f0101019:	53                   	push   %ebx
f010101a:	6a 20                	push   $0x20
f010101c:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f010101e:	83 ef 01             	sub    $0x1,%edi
f0101021:	83 c4 10             	add    $0x10,%esp
f0101024:	eb 08                	jmp    f010102e <vprintfmt+0x278>
f0101026:	89 df                	mov    %ebx,%edi
f0101028:	8b 75 08             	mov    0x8(%ebp),%esi
f010102b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010102e:	85 ff                	test   %edi,%edi
f0101030:	7f e4                	jg     f0101016 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101032:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101035:	e9 a2 fd ff ff       	jmp    f0100ddc <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f010103a:	83 fa 01             	cmp    $0x1,%edx
f010103d:	7e 16                	jle    f0101055 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f010103f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101042:	8d 50 08             	lea    0x8(%eax),%edx
f0101045:	89 55 14             	mov    %edx,0x14(%ebp)
f0101048:	8b 50 04             	mov    0x4(%eax),%edx
f010104b:	8b 00                	mov    (%eax),%eax
f010104d:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101050:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101053:	eb 32                	jmp    f0101087 <vprintfmt+0x2d1>
	else if (lflag)
f0101055:	85 d2                	test   %edx,%edx
f0101057:	74 18                	je     f0101071 <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f0101059:	8b 45 14             	mov    0x14(%ebp),%eax
f010105c:	8d 50 04             	lea    0x4(%eax),%edx
f010105f:	89 55 14             	mov    %edx,0x14(%ebp)
f0101062:	8b 00                	mov    (%eax),%eax
f0101064:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101067:	89 c1                	mov    %eax,%ecx
f0101069:	c1 f9 1f             	sar    $0x1f,%ecx
f010106c:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f010106f:	eb 16                	jmp    f0101087 <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f0101071:	8b 45 14             	mov    0x14(%ebp),%eax
f0101074:	8d 50 04             	lea    0x4(%eax),%edx
f0101077:	89 55 14             	mov    %edx,0x14(%ebp)
f010107a:	8b 00                	mov    (%eax),%eax
f010107c:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010107f:	89 c1                	mov    %eax,%ecx
f0101081:	c1 f9 1f             	sar    $0x1f,%ecx
f0101084:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0101087:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010108a:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f010108d:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0101092:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0101096:	0f 89 90 00 00 00    	jns    f010112c <vprintfmt+0x376>
				putch('-', putdat);
f010109c:	83 ec 08             	sub    $0x8,%esp
f010109f:	53                   	push   %ebx
f01010a0:	6a 2d                	push   $0x2d
f01010a2:	ff d6                	call   *%esi
				num = -(long long) num;
f01010a4:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01010a7:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01010aa:	f7 d8                	neg    %eax
f01010ac:	83 d2 00             	adc    $0x0,%edx
f01010af:	f7 da                	neg    %edx
f01010b1:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f01010b4:	b9 0a 00 00 00       	mov    $0xa,%ecx
f01010b9:	eb 71                	jmp    f010112c <vprintfmt+0x376>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01010bb:	8d 45 14             	lea    0x14(%ebp),%eax
f01010be:	e8 7f fc ff ff       	call   f0100d42 <getuint>
			base = 10;
f01010c3:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f01010c8:	eb 62                	jmp    f010112c <vprintfmt+0x376>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f01010ca:	8d 45 14             	lea    0x14(%ebp),%eax
f01010cd:	e8 70 fc ff ff       	call   f0100d42 <getuint>
			base = 8;
			printnum(putch, putdat, num, base, width, padc);
f01010d2:	83 ec 0c             	sub    $0xc,%esp
f01010d5:	0f be 4d d4          	movsbl -0x2c(%ebp),%ecx
f01010d9:	51                   	push   %ecx
f01010da:	ff 75 e0             	pushl  -0x20(%ebp)
f01010dd:	6a 08                	push   $0x8
f01010df:	52                   	push   %edx
f01010e0:	50                   	push   %eax
f01010e1:	89 da                	mov    %ebx,%edx
f01010e3:	89 f0                	mov    %esi,%eax
f01010e5:	e8 a9 fb ff ff       	call   f0100c93 <printnum>
			break;
f01010ea:	83 c4 20             	add    $0x20,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01010ed:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
			base = 8;
			printnum(putch, putdat, num, base, width, padc);
			break;
f01010f0:	e9 e7 fc ff ff       	jmp    f0100ddc <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
f01010f5:	83 ec 08             	sub    $0x8,%esp
f01010f8:	53                   	push   %ebx
f01010f9:	6a 30                	push   $0x30
f01010fb:	ff d6                	call   *%esi
			putch('x', putdat);
f01010fd:	83 c4 08             	add    $0x8,%esp
f0101100:	53                   	push   %ebx
f0101101:	6a 78                	push   $0x78
f0101103:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0101105:	8b 45 14             	mov    0x14(%ebp),%eax
f0101108:	8d 50 04             	lea    0x4(%eax),%edx
f010110b:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f010110e:	8b 00                	mov    (%eax),%eax
f0101110:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0101115:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0101118:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f010111d:	eb 0d                	jmp    f010112c <vprintfmt+0x376>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f010111f:	8d 45 14             	lea    0x14(%ebp),%eax
f0101122:	e8 1b fc ff ff       	call   f0100d42 <getuint>
			base = 16;
f0101127:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f010112c:	83 ec 0c             	sub    $0xc,%esp
f010112f:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0101133:	57                   	push   %edi
f0101134:	ff 75 e0             	pushl  -0x20(%ebp)
f0101137:	51                   	push   %ecx
f0101138:	52                   	push   %edx
f0101139:	50                   	push   %eax
f010113a:	89 da                	mov    %ebx,%edx
f010113c:	89 f0                	mov    %esi,%eax
f010113e:	e8 50 fb ff ff       	call   f0100c93 <printnum>
			break;
f0101143:	83 c4 20             	add    $0x20,%esp
f0101146:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101149:	e9 8e fc ff ff       	jmp    f0100ddc <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f010114e:	83 ec 08             	sub    $0x8,%esp
f0101151:	53                   	push   %ebx
f0101152:	51                   	push   %ecx
f0101153:	ff d6                	call   *%esi
			break;
f0101155:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101158:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f010115b:	e9 7c fc ff ff       	jmp    f0100ddc <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0101160:	83 ec 08             	sub    $0x8,%esp
f0101163:	53                   	push   %ebx
f0101164:	6a 25                	push   $0x25
f0101166:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101168:	83 c4 10             	add    $0x10,%esp
f010116b:	eb 03                	jmp    f0101170 <vprintfmt+0x3ba>
f010116d:	83 ef 01             	sub    $0x1,%edi
f0101170:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0101174:	75 f7                	jne    f010116d <vprintfmt+0x3b7>
f0101176:	e9 61 fc ff ff       	jmp    f0100ddc <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f010117b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010117e:	5b                   	pop    %ebx
f010117f:	5e                   	pop    %esi
f0101180:	5f                   	pop    %edi
f0101181:	5d                   	pop    %ebp
f0101182:	c3                   	ret    

f0101183 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101183:	55                   	push   %ebp
f0101184:	89 e5                	mov    %esp,%ebp
f0101186:	83 ec 18             	sub    $0x18,%esp
f0101189:	8b 45 08             	mov    0x8(%ebp),%eax
f010118c:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010118f:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101192:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101196:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101199:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01011a0:	85 c0                	test   %eax,%eax
f01011a2:	74 26                	je     f01011ca <vsnprintf+0x47>
f01011a4:	85 d2                	test   %edx,%edx
f01011a6:	7e 22                	jle    f01011ca <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01011a8:	ff 75 14             	pushl  0x14(%ebp)
f01011ab:	ff 75 10             	pushl  0x10(%ebp)
f01011ae:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01011b1:	50                   	push   %eax
f01011b2:	68 7c 0d 10 f0       	push   $0xf0100d7c
f01011b7:	e8 fa fb ff ff       	call   f0100db6 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01011bc:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01011bf:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01011c2:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01011c5:	83 c4 10             	add    $0x10,%esp
f01011c8:	eb 05                	jmp    f01011cf <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01011ca:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01011cf:	c9                   	leave  
f01011d0:	c3                   	ret    

f01011d1 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01011d1:	55                   	push   %ebp
f01011d2:	89 e5                	mov    %esp,%ebp
f01011d4:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01011d7:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01011da:	50                   	push   %eax
f01011db:	ff 75 10             	pushl  0x10(%ebp)
f01011de:	ff 75 0c             	pushl  0xc(%ebp)
f01011e1:	ff 75 08             	pushl  0x8(%ebp)
f01011e4:	e8 9a ff ff ff       	call   f0101183 <vsnprintf>
	va_end(ap);

	return rc;
}
f01011e9:	c9                   	leave  
f01011ea:	c3                   	ret    

f01011eb <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01011eb:	55                   	push   %ebp
f01011ec:	89 e5                	mov    %esp,%ebp
f01011ee:	57                   	push   %edi
f01011ef:	56                   	push   %esi
f01011f0:	53                   	push   %ebx
f01011f1:	83 ec 0c             	sub    $0xc,%esp
f01011f4:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01011f7:	85 c0                	test   %eax,%eax
f01011f9:	74 11                	je     f010120c <readline+0x21>
		cprintf("%s", prompt);
f01011fb:	83 ec 08             	sub    $0x8,%esp
f01011fe:	50                   	push   %eax
f01011ff:	68 aa 1e 10 f0       	push   $0xf0101eaa
f0101204:	e8 55 f7 ff ff       	call   f010095e <cprintf>
f0101209:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f010120c:	83 ec 0c             	sub    $0xc,%esp
f010120f:	6a 00                	push   $0x0
f0101211:	e8 58 f4 ff ff       	call   f010066e <iscons>
f0101216:	89 c7                	mov    %eax,%edi
f0101218:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010121b:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101220:	e8 38 f4 ff ff       	call   f010065d <getchar>
f0101225:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0101227:	85 c0                	test   %eax,%eax
f0101229:	79 18                	jns    f0101243 <readline+0x58>
			cprintf("read error: %e\n", c);
f010122b:	83 ec 08             	sub    $0x8,%esp
f010122e:	50                   	push   %eax
f010122f:	68 a0 20 10 f0       	push   $0xf01020a0
f0101234:	e8 25 f7 ff ff       	call   f010095e <cprintf>
			return NULL;
f0101239:	83 c4 10             	add    $0x10,%esp
f010123c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101241:	eb 79                	jmp    f01012bc <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101243:	83 f8 08             	cmp    $0x8,%eax
f0101246:	0f 94 c2             	sete   %dl
f0101249:	83 f8 7f             	cmp    $0x7f,%eax
f010124c:	0f 94 c0             	sete   %al
f010124f:	08 c2                	or     %al,%dl
f0101251:	74 1a                	je     f010126d <readline+0x82>
f0101253:	85 f6                	test   %esi,%esi
f0101255:	7e 16                	jle    f010126d <readline+0x82>
			if (echoing)
f0101257:	85 ff                	test   %edi,%edi
f0101259:	74 0d                	je     f0101268 <readline+0x7d>
				cputchar('\b');
f010125b:	83 ec 0c             	sub    $0xc,%esp
f010125e:	6a 08                	push   $0x8
f0101260:	e8 e8 f3 ff ff       	call   f010064d <cputchar>
f0101265:	83 c4 10             	add    $0x10,%esp
			i--;
f0101268:	83 ee 01             	sub    $0x1,%esi
f010126b:	eb b3                	jmp    f0101220 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f010126d:	83 fb 1f             	cmp    $0x1f,%ebx
f0101270:	7e 23                	jle    f0101295 <readline+0xaa>
f0101272:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0101278:	7f 1b                	jg     f0101295 <readline+0xaa>
			if (echoing)
f010127a:	85 ff                	test   %edi,%edi
f010127c:	74 0c                	je     f010128a <readline+0x9f>
				cputchar(c);
f010127e:	83 ec 0c             	sub    $0xc,%esp
f0101281:	53                   	push   %ebx
f0101282:	e8 c6 f3 ff ff       	call   f010064d <cputchar>
f0101287:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f010128a:	88 9e 40 25 11 f0    	mov    %bl,-0xfeedac0(%esi)
f0101290:	8d 76 01             	lea    0x1(%esi),%esi
f0101293:	eb 8b                	jmp    f0101220 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0101295:	83 fb 0a             	cmp    $0xa,%ebx
f0101298:	74 05                	je     f010129f <readline+0xb4>
f010129a:	83 fb 0d             	cmp    $0xd,%ebx
f010129d:	75 81                	jne    f0101220 <readline+0x35>
			if (echoing)
f010129f:	85 ff                	test   %edi,%edi
f01012a1:	74 0d                	je     f01012b0 <readline+0xc5>
				cputchar('\n');
f01012a3:	83 ec 0c             	sub    $0xc,%esp
f01012a6:	6a 0a                	push   $0xa
f01012a8:	e8 a0 f3 ff ff       	call   f010064d <cputchar>
f01012ad:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f01012b0:	c6 86 40 25 11 f0 00 	movb   $0x0,-0xfeedac0(%esi)
			return buf;
f01012b7:	b8 40 25 11 f0       	mov    $0xf0112540,%eax
		}
	}
}
f01012bc:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01012bf:	5b                   	pop    %ebx
f01012c0:	5e                   	pop    %esi
f01012c1:	5f                   	pop    %edi
f01012c2:	5d                   	pop    %ebp
f01012c3:	c3                   	ret    

f01012c4 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01012c4:	55                   	push   %ebp
f01012c5:	89 e5                	mov    %esp,%ebp
f01012c7:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01012ca:	b8 00 00 00 00       	mov    $0x0,%eax
f01012cf:	eb 03                	jmp    f01012d4 <strlen+0x10>
		n++;
f01012d1:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01012d4:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01012d8:	75 f7                	jne    f01012d1 <strlen+0xd>
		n++;
	return n;
}
f01012da:	5d                   	pop    %ebp
f01012db:	c3                   	ret    

f01012dc <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01012dc:	55                   	push   %ebp
f01012dd:	89 e5                	mov    %esp,%ebp
f01012df:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01012e2:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01012e5:	ba 00 00 00 00       	mov    $0x0,%edx
f01012ea:	eb 03                	jmp    f01012ef <strnlen+0x13>
		n++;
f01012ec:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01012ef:	39 c2                	cmp    %eax,%edx
f01012f1:	74 08                	je     f01012fb <strnlen+0x1f>
f01012f3:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f01012f7:	75 f3                	jne    f01012ec <strnlen+0x10>
f01012f9:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f01012fb:	5d                   	pop    %ebp
f01012fc:	c3                   	ret    

f01012fd <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01012fd:	55                   	push   %ebp
f01012fe:	89 e5                	mov    %esp,%ebp
f0101300:	53                   	push   %ebx
f0101301:	8b 45 08             	mov    0x8(%ebp),%eax
f0101304:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101307:	89 c2                	mov    %eax,%edx
f0101309:	83 c2 01             	add    $0x1,%edx
f010130c:	83 c1 01             	add    $0x1,%ecx
f010130f:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0101313:	88 5a ff             	mov    %bl,-0x1(%edx)
f0101316:	84 db                	test   %bl,%bl
f0101318:	75 ef                	jne    f0101309 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f010131a:	5b                   	pop    %ebx
f010131b:	5d                   	pop    %ebp
f010131c:	c3                   	ret    

f010131d <strcat>:

char *
strcat(char *dst, const char *src)
{
f010131d:	55                   	push   %ebp
f010131e:	89 e5                	mov    %esp,%ebp
f0101320:	53                   	push   %ebx
f0101321:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101324:	53                   	push   %ebx
f0101325:	e8 9a ff ff ff       	call   f01012c4 <strlen>
f010132a:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f010132d:	ff 75 0c             	pushl  0xc(%ebp)
f0101330:	01 d8                	add    %ebx,%eax
f0101332:	50                   	push   %eax
f0101333:	e8 c5 ff ff ff       	call   f01012fd <strcpy>
	return dst;
}
f0101338:	89 d8                	mov    %ebx,%eax
f010133a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010133d:	c9                   	leave  
f010133e:	c3                   	ret    

f010133f <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010133f:	55                   	push   %ebp
f0101340:	89 e5                	mov    %esp,%ebp
f0101342:	56                   	push   %esi
f0101343:	53                   	push   %ebx
f0101344:	8b 75 08             	mov    0x8(%ebp),%esi
f0101347:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010134a:	89 f3                	mov    %esi,%ebx
f010134c:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010134f:	89 f2                	mov    %esi,%edx
f0101351:	eb 0f                	jmp    f0101362 <strncpy+0x23>
		*dst++ = *src;
f0101353:	83 c2 01             	add    $0x1,%edx
f0101356:	0f b6 01             	movzbl (%ecx),%eax
f0101359:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010135c:	80 39 01             	cmpb   $0x1,(%ecx)
f010135f:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101362:	39 da                	cmp    %ebx,%edx
f0101364:	75 ed                	jne    f0101353 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101366:	89 f0                	mov    %esi,%eax
f0101368:	5b                   	pop    %ebx
f0101369:	5e                   	pop    %esi
f010136a:	5d                   	pop    %ebp
f010136b:	c3                   	ret    

f010136c <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010136c:	55                   	push   %ebp
f010136d:	89 e5                	mov    %esp,%ebp
f010136f:	56                   	push   %esi
f0101370:	53                   	push   %ebx
f0101371:	8b 75 08             	mov    0x8(%ebp),%esi
f0101374:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101377:	8b 55 10             	mov    0x10(%ebp),%edx
f010137a:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f010137c:	85 d2                	test   %edx,%edx
f010137e:	74 21                	je     f01013a1 <strlcpy+0x35>
f0101380:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0101384:	89 f2                	mov    %esi,%edx
f0101386:	eb 09                	jmp    f0101391 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101388:	83 c2 01             	add    $0x1,%edx
f010138b:	83 c1 01             	add    $0x1,%ecx
f010138e:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101391:	39 c2                	cmp    %eax,%edx
f0101393:	74 09                	je     f010139e <strlcpy+0x32>
f0101395:	0f b6 19             	movzbl (%ecx),%ebx
f0101398:	84 db                	test   %bl,%bl
f010139a:	75 ec                	jne    f0101388 <strlcpy+0x1c>
f010139c:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f010139e:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01013a1:	29 f0                	sub    %esi,%eax
}
f01013a3:	5b                   	pop    %ebx
f01013a4:	5e                   	pop    %esi
f01013a5:	5d                   	pop    %ebp
f01013a6:	c3                   	ret    

f01013a7 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01013a7:	55                   	push   %ebp
f01013a8:	89 e5                	mov    %esp,%ebp
f01013aa:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01013ad:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01013b0:	eb 06                	jmp    f01013b8 <strcmp+0x11>
		p++, q++;
f01013b2:	83 c1 01             	add    $0x1,%ecx
f01013b5:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01013b8:	0f b6 01             	movzbl (%ecx),%eax
f01013bb:	84 c0                	test   %al,%al
f01013bd:	74 04                	je     f01013c3 <strcmp+0x1c>
f01013bf:	3a 02                	cmp    (%edx),%al
f01013c1:	74 ef                	je     f01013b2 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01013c3:	0f b6 c0             	movzbl %al,%eax
f01013c6:	0f b6 12             	movzbl (%edx),%edx
f01013c9:	29 d0                	sub    %edx,%eax
}
f01013cb:	5d                   	pop    %ebp
f01013cc:	c3                   	ret    

f01013cd <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01013cd:	55                   	push   %ebp
f01013ce:	89 e5                	mov    %esp,%ebp
f01013d0:	53                   	push   %ebx
f01013d1:	8b 45 08             	mov    0x8(%ebp),%eax
f01013d4:	8b 55 0c             	mov    0xc(%ebp),%edx
f01013d7:	89 c3                	mov    %eax,%ebx
f01013d9:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01013dc:	eb 06                	jmp    f01013e4 <strncmp+0x17>
		n--, p++, q++;
f01013de:	83 c0 01             	add    $0x1,%eax
f01013e1:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01013e4:	39 d8                	cmp    %ebx,%eax
f01013e6:	74 15                	je     f01013fd <strncmp+0x30>
f01013e8:	0f b6 08             	movzbl (%eax),%ecx
f01013eb:	84 c9                	test   %cl,%cl
f01013ed:	74 04                	je     f01013f3 <strncmp+0x26>
f01013ef:	3a 0a                	cmp    (%edx),%cl
f01013f1:	74 eb                	je     f01013de <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01013f3:	0f b6 00             	movzbl (%eax),%eax
f01013f6:	0f b6 12             	movzbl (%edx),%edx
f01013f9:	29 d0                	sub    %edx,%eax
f01013fb:	eb 05                	jmp    f0101402 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01013fd:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0101402:	5b                   	pop    %ebx
f0101403:	5d                   	pop    %ebp
f0101404:	c3                   	ret    

f0101405 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101405:	55                   	push   %ebp
f0101406:	89 e5                	mov    %esp,%ebp
f0101408:	8b 45 08             	mov    0x8(%ebp),%eax
f010140b:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010140f:	eb 07                	jmp    f0101418 <strchr+0x13>
		if (*s == c)
f0101411:	38 ca                	cmp    %cl,%dl
f0101413:	74 0f                	je     f0101424 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0101415:	83 c0 01             	add    $0x1,%eax
f0101418:	0f b6 10             	movzbl (%eax),%edx
f010141b:	84 d2                	test   %dl,%dl
f010141d:	75 f2                	jne    f0101411 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f010141f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101424:	5d                   	pop    %ebp
f0101425:	c3                   	ret    

f0101426 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101426:	55                   	push   %ebp
f0101427:	89 e5                	mov    %esp,%ebp
f0101429:	8b 45 08             	mov    0x8(%ebp),%eax
f010142c:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101430:	eb 03                	jmp    f0101435 <strfind+0xf>
f0101432:	83 c0 01             	add    $0x1,%eax
f0101435:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0101438:	38 ca                	cmp    %cl,%dl
f010143a:	74 04                	je     f0101440 <strfind+0x1a>
f010143c:	84 d2                	test   %dl,%dl
f010143e:	75 f2                	jne    f0101432 <strfind+0xc>
			break;
	return (char *) s;
}
f0101440:	5d                   	pop    %ebp
f0101441:	c3                   	ret    

f0101442 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101442:	55                   	push   %ebp
f0101443:	89 e5                	mov    %esp,%ebp
f0101445:	57                   	push   %edi
f0101446:	56                   	push   %esi
f0101447:	53                   	push   %ebx
f0101448:	8b 7d 08             	mov    0x8(%ebp),%edi
f010144b:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010144e:	85 c9                	test   %ecx,%ecx
f0101450:	74 36                	je     f0101488 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101452:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101458:	75 28                	jne    f0101482 <memset+0x40>
f010145a:	f6 c1 03             	test   $0x3,%cl
f010145d:	75 23                	jne    f0101482 <memset+0x40>
		c &= 0xFF;
f010145f:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101463:	89 d3                	mov    %edx,%ebx
f0101465:	c1 e3 08             	shl    $0x8,%ebx
f0101468:	89 d6                	mov    %edx,%esi
f010146a:	c1 e6 18             	shl    $0x18,%esi
f010146d:	89 d0                	mov    %edx,%eax
f010146f:	c1 e0 10             	shl    $0x10,%eax
f0101472:	09 f0                	or     %esi,%eax
f0101474:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0101476:	89 d8                	mov    %ebx,%eax
f0101478:	09 d0                	or     %edx,%eax
f010147a:	c1 e9 02             	shr    $0x2,%ecx
f010147d:	fc                   	cld    
f010147e:	f3 ab                	rep stos %eax,%es:(%edi)
f0101480:	eb 06                	jmp    f0101488 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0101482:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101485:	fc                   	cld    
f0101486:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0101488:	89 f8                	mov    %edi,%eax
f010148a:	5b                   	pop    %ebx
f010148b:	5e                   	pop    %esi
f010148c:	5f                   	pop    %edi
f010148d:	5d                   	pop    %ebp
f010148e:	c3                   	ret    

f010148f <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010148f:	55                   	push   %ebp
f0101490:	89 e5                	mov    %esp,%ebp
f0101492:	57                   	push   %edi
f0101493:	56                   	push   %esi
f0101494:	8b 45 08             	mov    0x8(%ebp),%eax
f0101497:	8b 75 0c             	mov    0xc(%ebp),%esi
f010149a:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f010149d:	39 c6                	cmp    %eax,%esi
f010149f:	73 35                	jae    f01014d6 <memmove+0x47>
f01014a1:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01014a4:	39 d0                	cmp    %edx,%eax
f01014a6:	73 2e                	jae    f01014d6 <memmove+0x47>
		s += n;
		d += n;
f01014a8:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01014ab:	89 d6                	mov    %edx,%esi
f01014ad:	09 fe                	or     %edi,%esi
f01014af:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01014b5:	75 13                	jne    f01014ca <memmove+0x3b>
f01014b7:	f6 c1 03             	test   $0x3,%cl
f01014ba:	75 0e                	jne    f01014ca <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f01014bc:	83 ef 04             	sub    $0x4,%edi
f01014bf:	8d 72 fc             	lea    -0x4(%edx),%esi
f01014c2:	c1 e9 02             	shr    $0x2,%ecx
f01014c5:	fd                   	std    
f01014c6:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01014c8:	eb 09                	jmp    f01014d3 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01014ca:	83 ef 01             	sub    $0x1,%edi
f01014cd:	8d 72 ff             	lea    -0x1(%edx),%esi
f01014d0:	fd                   	std    
f01014d1:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01014d3:	fc                   	cld    
f01014d4:	eb 1d                	jmp    f01014f3 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01014d6:	89 f2                	mov    %esi,%edx
f01014d8:	09 c2                	or     %eax,%edx
f01014da:	f6 c2 03             	test   $0x3,%dl
f01014dd:	75 0f                	jne    f01014ee <memmove+0x5f>
f01014df:	f6 c1 03             	test   $0x3,%cl
f01014e2:	75 0a                	jne    f01014ee <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f01014e4:	c1 e9 02             	shr    $0x2,%ecx
f01014e7:	89 c7                	mov    %eax,%edi
f01014e9:	fc                   	cld    
f01014ea:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01014ec:	eb 05                	jmp    f01014f3 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01014ee:	89 c7                	mov    %eax,%edi
f01014f0:	fc                   	cld    
f01014f1:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01014f3:	5e                   	pop    %esi
f01014f4:	5f                   	pop    %edi
f01014f5:	5d                   	pop    %ebp
f01014f6:	c3                   	ret    

f01014f7 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01014f7:	55                   	push   %ebp
f01014f8:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01014fa:	ff 75 10             	pushl  0x10(%ebp)
f01014fd:	ff 75 0c             	pushl  0xc(%ebp)
f0101500:	ff 75 08             	pushl  0x8(%ebp)
f0101503:	e8 87 ff ff ff       	call   f010148f <memmove>
}
f0101508:	c9                   	leave  
f0101509:	c3                   	ret    

f010150a <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010150a:	55                   	push   %ebp
f010150b:	89 e5                	mov    %esp,%ebp
f010150d:	56                   	push   %esi
f010150e:	53                   	push   %ebx
f010150f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101512:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101515:	89 c6                	mov    %eax,%esi
f0101517:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010151a:	eb 1a                	jmp    f0101536 <memcmp+0x2c>
		if (*s1 != *s2)
f010151c:	0f b6 08             	movzbl (%eax),%ecx
f010151f:	0f b6 1a             	movzbl (%edx),%ebx
f0101522:	38 d9                	cmp    %bl,%cl
f0101524:	74 0a                	je     f0101530 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0101526:	0f b6 c1             	movzbl %cl,%eax
f0101529:	0f b6 db             	movzbl %bl,%ebx
f010152c:	29 d8                	sub    %ebx,%eax
f010152e:	eb 0f                	jmp    f010153f <memcmp+0x35>
		s1++, s2++;
f0101530:	83 c0 01             	add    $0x1,%eax
f0101533:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101536:	39 f0                	cmp    %esi,%eax
f0101538:	75 e2                	jne    f010151c <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010153a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010153f:	5b                   	pop    %ebx
f0101540:	5e                   	pop    %esi
f0101541:	5d                   	pop    %ebp
f0101542:	c3                   	ret    

f0101543 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101543:	55                   	push   %ebp
f0101544:	89 e5                	mov    %esp,%ebp
f0101546:	53                   	push   %ebx
f0101547:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f010154a:	89 c1                	mov    %eax,%ecx
f010154c:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f010154f:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0101553:	eb 0a                	jmp    f010155f <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101555:	0f b6 10             	movzbl (%eax),%edx
f0101558:	39 da                	cmp    %ebx,%edx
f010155a:	74 07                	je     f0101563 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010155c:	83 c0 01             	add    $0x1,%eax
f010155f:	39 c8                	cmp    %ecx,%eax
f0101561:	72 f2                	jb     f0101555 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0101563:	5b                   	pop    %ebx
f0101564:	5d                   	pop    %ebp
f0101565:	c3                   	ret    

f0101566 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101566:	55                   	push   %ebp
f0101567:	89 e5                	mov    %esp,%ebp
f0101569:	57                   	push   %edi
f010156a:	56                   	push   %esi
f010156b:	53                   	push   %ebx
f010156c:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010156f:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101572:	eb 03                	jmp    f0101577 <strtol+0x11>
		s++;
f0101574:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101577:	0f b6 01             	movzbl (%ecx),%eax
f010157a:	3c 20                	cmp    $0x20,%al
f010157c:	74 f6                	je     f0101574 <strtol+0xe>
f010157e:	3c 09                	cmp    $0x9,%al
f0101580:	74 f2                	je     f0101574 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0101582:	3c 2b                	cmp    $0x2b,%al
f0101584:	75 0a                	jne    f0101590 <strtol+0x2a>
		s++;
f0101586:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0101589:	bf 00 00 00 00       	mov    $0x0,%edi
f010158e:	eb 11                	jmp    f01015a1 <strtol+0x3b>
f0101590:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0101595:	3c 2d                	cmp    $0x2d,%al
f0101597:	75 08                	jne    f01015a1 <strtol+0x3b>
		s++, neg = 1;
f0101599:	83 c1 01             	add    $0x1,%ecx
f010159c:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01015a1:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01015a7:	75 15                	jne    f01015be <strtol+0x58>
f01015a9:	80 39 30             	cmpb   $0x30,(%ecx)
f01015ac:	75 10                	jne    f01015be <strtol+0x58>
f01015ae:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01015b2:	75 7c                	jne    f0101630 <strtol+0xca>
		s += 2, base = 16;
f01015b4:	83 c1 02             	add    $0x2,%ecx
f01015b7:	bb 10 00 00 00       	mov    $0x10,%ebx
f01015bc:	eb 16                	jmp    f01015d4 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f01015be:	85 db                	test   %ebx,%ebx
f01015c0:	75 12                	jne    f01015d4 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01015c2:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01015c7:	80 39 30             	cmpb   $0x30,(%ecx)
f01015ca:	75 08                	jne    f01015d4 <strtol+0x6e>
		s++, base = 8;
f01015cc:	83 c1 01             	add    $0x1,%ecx
f01015cf:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f01015d4:	b8 00 00 00 00       	mov    $0x0,%eax
f01015d9:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01015dc:	0f b6 11             	movzbl (%ecx),%edx
f01015df:	8d 72 d0             	lea    -0x30(%edx),%esi
f01015e2:	89 f3                	mov    %esi,%ebx
f01015e4:	80 fb 09             	cmp    $0x9,%bl
f01015e7:	77 08                	ja     f01015f1 <strtol+0x8b>
			dig = *s - '0';
f01015e9:	0f be d2             	movsbl %dl,%edx
f01015ec:	83 ea 30             	sub    $0x30,%edx
f01015ef:	eb 22                	jmp    f0101613 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f01015f1:	8d 72 9f             	lea    -0x61(%edx),%esi
f01015f4:	89 f3                	mov    %esi,%ebx
f01015f6:	80 fb 19             	cmp    $0x19,%bl
f01015f9:	77 08                	ja     f0101603 <strtol+0x9d>
			dig = *s - 'a' + 10;
f01015fb:	0f be d2             	movsbl %dl,%edx
f01015fe:	83 ea 57             	sub    $0x57,%edx
f0101601:	eb 10                	jmp    f0101613 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0101603:	8d 72 bf             	lea    -0x41(%edx),%esi
f0101606:	89 f3                	mov    %esi,%ebx
f0101608:	80 fb 19             	cmp    $0x19,%bl
f010160b:	77 16                	ja     f0101623 <strtol+0xbd>
			dig = *s - 'A' + 10;
f010160d:	0f be d2             	movsbl %dl,%edx
f0101610:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0101613:	3b 55 10             	cmp    0x10(%ebp),%edx
f0101616:	7d 0b                	jge    f0101623 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0101618:	83 c1 01             	add    $0x1,%ecx
f010161b:	0f af 45 10          	imul   0x10(%ebp),%eax
f010161f:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0101621:	eb b9                	jmp    f01015dc <strtol+0x76>

	if (endptr)
f0101623:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101627:	74 0d                	je     f0101636 <strtol+0xd0>
		*endptr = (char *) s;
f0101629:	8b 75 0c             	mov    0xc(%ebp),%esi
f010162c:	89 0e                	mov    %ecx,(%esi)
f010162e:	eb 06                	jmp    f0101636 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101630:	85 db                	test   %ebx,%ebx
f0101632:	74 98                	je     f01015cc <strtol+0x66>
f0101634:	eb 9e                	jmp    f01015d4 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0101636:	89 c2                	mov    %eax,%edx
f0101638:	f7 da                	neg    %edx
f010163a:	85 ff                	test   %edi,%edi
f010163c:	0f 45 c2             	cmovne %edx,%eax
}
f010163f:	5b                   	pop    %ebx
f0101640:	5e                   	pop    %esi
f0101641:	5f                   	pop    %edi
f0101642:	5d                   	pop    %ebp
f0101643:	c3                   	ret    
f0101644:	66 90                	xchg   %ax,%ax
f0101646:	66 90                	xchg   %ax,%ax
f0101648:	66 90                	xchg   %ax,%ax
f010164a:	66 90                	xchg   %ax,%ax
f010164c:	66 90                	xchg   %ax,%ax
f010164e:	66 90                	xchg   %ax,%ax

f0101650 <__udivdi3>:
f0101650:	55                   	push   %ebp
f0101651:	57                   	push   %edi
f0101652:	56                   	push   %esi
f0101653:	53                   	push   %ebx
f0101654:	83 ec 1c             	sub    $0x1c,%esp
f0101657:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010165b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010165f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0101663:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101667:	85 f6                	test   %esi,%esi
f0101669:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010166d:	89 ca                	mov    %ecx,%edx
f010166f:	89 f8                	mov    %edi,%eax
f0101671:	75 3d                	jne    f01016b0 <__udivdi3+0x60>
f0101673:	39 cf                	cmp    %ecx,%edi
f0101675:	0f 87 c5 00 00 00    	ja     f0101740 <__udivdi3+0xf0>
f010167b:	85 ff                	test   %edi,%edi
f010167d:	89 fd                	mov    %edi,%ebp
f010167f:	75 0b                	jne    f010168c <__udivdi3+0x3c>
f0101681:	b8 01 00 00 00       	mov    $0x1,%eax
f0101686:	31 d2                	xor    %edx,%edx
f0101688:	f7 f7                	div    %edi
f010168a:	89 c5                	mov    %eax,%ebp
f010168c:	89 c8                	mov    %ecx,%eax
f010168e:	31 d2                	xor    %edx,%edx
f0101690:	f7 f5                	div    %ebp
f0101692:	89 c1                	mov    %eax,%ecx
f0101694:	89 d8                	mov    %ebx,%eax
f0101696:	89 cf                	mov    %ecx,%edi
f0101698:	f7 f5                	div    %ebp
f010169a:	89 c3                	mov    %eax,%ebx
f010169c:	89 d8                	mov    %ebx,%eax
f010169e:	89 fa                	mov    %edi,%edx
f01016a0:	83 c4 1c             	add    $0x1c,%esp
f01016a3:	5b                   	pop    %ebx
f01016a4:	5e                   	pop    %esi
f01016a5:	5f                   	pop    %edi
f01016a6:	5d                   	pop    %ebp
f01016a7:	c3                   	ret    
f01016a8:	90                   	nop
f01016a9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01016b0:	39 ce                	cmp    %ecx,%esi
f01016b2:	77 74                	ja     f0101728 <__udivdi3+0xd8>
f01016b4:	0f bd fe             	bsr    %esi,%edi
f01016b7:	83 f7 1f             	xor    $0x1f,%edi
f01016ba:	0f 84 98 00 00 00    	je     f0101758 <__udivdi3+0x108>
f01016c0:	bb 20 00 00 00       	mov    $0x20,%ebx
f01016c5:	89 f9                	mov    %edi,%ecx
f01016c7:	89 c5                	mov    %eax,%ebp
f01016c9:	29 fb                	sub    %edi,%ebx
f01016cb:	d3 e6                	shl    %cl,%esi
f01016cd:	89 d9                	mov    %ebx,%ecx
f01016cf:	d3 ed                	shr    %cl,%ebp
f01016d1:	89 f9                	mov    %edi,%ecx
f01016d3:	d3 e0                	shl    %cl,%eax
f01016d5:	09 ee                	or     %ebp,%esi
f01016d7:	89 d9                	mov    %ebx,%ecx
f01016d9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01016dd:	89 d5                	mov    %edx,%ebp
f01016df:	8b 44 24 08          	mov    0x8(%esp),%eax
f01016e3:	d3 ed                	shr    %cl,%ebp
f01016e5:	89 f9                	mov    %edi,%ecx
f01016e7:	d3 e2                	shl    %cl,%edx
f01016e9:	89 d9                	mov    %ebx,%ecx
f01016eb:	d3 e8                	shr    %cl,%eax
f01016ed:	09 c2                	or     %eax,%edx
f01016ef:	89 d0                	mov    %edx,%eax
f01016f1:	89 ea                	mov    %ebp,%edx
f01016f3:	f7 f6                	div    %esi
f01016f5:	89 d5                	mov    %edx,%ebp
f01016f7:	89 c3                	mov    %eax,%ebx
f01016f9:	f7 64 24 0c          	mull   0xc(%esp)
f01016fd:	39 d5                	cmp    %edx,%ebp
f01016ff:	72 10                	jb     f0101711 <__udivdi3+0xc1>
f0101701:	8b 74 24 08          	mov    0x8(%esp),%esi
f0101705:	89 f9                	mov    %edi,%ecx
f0101707:	d3 e6                	shl    %cl,%esi
f0101709:	39 c6                	cmp    %eax,%esi
f010170b:	73 07                	jae    f0101714 <__udivdi3+0xc4>
f010170d:	39 d5                	cmp    %edx,%ebp
f010170f:	75 03                	jne    f0101714 <__udivdi3+0xc4>
f0101711:	83 eb 01             	sub    $0x1,%ebx
f0101714:	31 ff                	xor    %edi,%edi
f0101716:	89 d8                	mov    %ebx,%eax
f0101718:	89 fa                	mov    %edi,%edx
f010171a:	83 c4 1c             	add    $0x1c,%esp
f010171d:	5b                   	pop    %ebx
f010171e:	5e                   	pop    %esi
f010171f:	5f                   	pop    %edi
f0101720:	5d                   	pop    %ebp
f0101721:	c3                   	ret    
f0101722:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101728:	31 ff                	xor    %edi,%edi
f010172a:	31 db                	xor    %ebx,%ebx
f010172c:	89 d8                	mov    %ebx,%eax
f010172e:	89 fa                	mov    %edi,%edx
f0101730:	83 c4 1c             	add    $0x1c,%esp
f0101733:	5b                   	pop    %ebx
f0101734:	5e                   	pop    %esi
f0101735:	5f                   	pop    %edi
f0101736:	5d                   	pop    %ebp
f0101737:	c3                   	ret    
f0101738:	90                   	nop
f0101739:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101740:	89 d8                	mov    %ebx,%eax
f0101742:	f7 f7                	div    %edi
f0101744:	31 ff                	xor    %edi,%edi
f0101746:	89 c3                	mov    %eax,%ebx
f0101748:	89 d8                	mov    %ebx,%eax
f010174a:	89 fa                	mov    %edi,%edx
f010174c:	83 c4 1c             	add    $0x1c,%esp
f010174f:	5b                   	pop    %ebx
f0101750:	5e                   	pop    %esi
f0101751:	5f                   	pop    %edi
f0101752:	5d                   	pop    %ebp
f0101753:	c3                   	ret    
f0101754:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101758:	39 ce                	cmp    %ecx,%esi
f010175a:	72 0c                	jb     f0101768 <__udivdi3+0x118>
f010175c:	31 db                	xor    %ebx,%ebx
f010175e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0101762:	0f 87 34 ff ff ff    	ja     f010169c <__udivdi3+0x4c>
f0101768:	bb 01 00 00 00       	mov    $0x1,%ebx
f010176d:	e9 2a ff ff ff       	jmp    f010169c <__udivdi3+0x4c>
f0101772:	66 90                	xchg   %ax,%ax
f0101774:	66 90                	xchg   %ax,%ax
f0101776:	66 90                	xchg   %ax,%ax
f0101778:	66 90                	xchg   %ax,%ax
f010177a:	66 90                	xchg   %ax,%ax
f010177c:	66 90                	xchg   %ax,%ax
f010177e:	66 90                	xchg   %ax,%ax

f0101780 <__umoddi3>:
f0101780:	55                   	push   %ebp
f0101781:	57                   	push   %edi
f0101782:	56                   	push   %esi
f0101783:	53                   	push   %ebx
f0101784:	83 ec 1c             	sub    $0x1c,%esp
f0101787:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010178b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010178f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0101793:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101797:	85 d2                	test   %edx,%edx
f0101799:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010179d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01017a1:	89 f3                	mov    %esi,%ebx
f01017a3:	89 3c 24             	mov    %edi,(%esp)
f01017a6:	89 74 24 04          	mov    %esi,0x4(%esp)
f01017aa:	75 1c                	jne    f01017c8 <__umoddi3+0x48>
f01017ac:	39 f7                	cmp    %esi,%edi
f01017ae:	76 50                	jbe    f0101800 <__umoddi3+0x80>
f01017b0:	89 c8                	mov    %ecx,%eax
f01017b2:	89 f2                	mov    %esi,%edx
f01017b4:	f7 f7                	div    %edi
f01017b6:	89 d0                	mov    %edx,%eax
f01017b8:	31 d2                	xor    %edx,%edx
f01017ba:	83 c4 1c             	add    $0x1c,%esp
f01017bd:	5b                   	pop    %ebx
f01017be:	5e                   	pop    %esi
f01017bf:	5f                   	pop    %edi
f01017c0:	5d                   	pop    %ebp
f01017c1:	c3                   	ret    
f01017c2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01017c8:	39 f2                	cmp    %esi,%edx
f01017ca:	89 d0                	mov    %edx,%eax
f01017cc:	77 52                	ja     f0101820 <__umoddi3+0xa0>
f01017ce:	0f bd ea             	bsr    %edx,%ebp
f01017d1:	83 f5 1f             	xor    $0x1f,%ebp
f01017d4:	75 5a                	jne    f0101830 <__umoddi3+0xb0>
f01017d6:	3b 54 24 04          	cmp    0x4(%esp),%edx
f01017da:	0f 82 e0 00 00 00    	jb     f01018c0 <__umoddi3+0x140>
f01017e0:	39 0c 24             	cmp    %ecx,(%esp)
f01017e3:	0f 86 d7 00 00 00    	jbe    f01018c0 <__umoddi3+0x140>
f01017e9:	8b 44 24 08          	mov    0x8(%esp),%eax
f01017ed:	8b 54 24 04          	mov    0x4(%esp),%edx
f01017f1:	83 c4 1c             	add    $0x1c,%esp
f01017f4:	5b                   	pop    %ebx
f01017f5:	5e                   	pop    %esi
f01017f6:	5f                   	pop    %edi
f01017f7:	5d                   	pop    %ebp
f01017f8:	c3                   	ret    
f01017f9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101800:	85 ff                	test   %edi,%edi
f0101802:	89 fd                	mov    %edi,%ebp
f0101804:	75 0b                	jne    f0101811 <__umoddi3+0x91>
f0101806:	b8 01 00 00 00       	mov    $0x1,%eax
f010180b:	31 d2                	xor    %edx,%edx
f010180d:	f7 f7                	div    %edi
f010180f:	89 c5                	mov    %eax,%ebp
f0101811:	89 f0                	mov    %esi,%eax
f0101813:	31 d2                	xor    %edx,%edx
f0101815:	f7 f5                	div    %ebp
f0101817:	89 c8                	mov    %ecx,%eax
f0101819:	f7 f5                	div    %ebp
f010181b:	89 d0                	mov    %edx,%eax
f010181d:	eb 99                	jmp    f01017b8 <__umoddi3+0x38>
f010181f:	90                   	nop
f0101820:	89 c8                	mov    %ecx,%eax
f0101822:	89 f2                	mov    %esi,%edx
f0101824:	83 c4 1c             	add    $0x1c,%esp
f0101827:	5b                   	pop    %ebx
f0101828:	5e                   	pop    %esi
f0101829:	5f                   	pop    %edi
f010182a:	5d                   	pop    %ebp
f010182b:	c3                   	ret    
f010182c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101830:	8b 34 24             	mov    (%esp),%esi
f0101833:	bf 20 00 00 00       	mov    $0x20,%edi
f0101838:	89 e9                	mov    %ebp,%ecx
f010183a:	29 ef                	sub    %ebp,%edi
f010183c:	d3 e0                	shl    %cl,%eax
f010183e:	89 f9                	mov    %edi,%ecx
f0101840:	89 f2                	mov    %esi,%edx
f0101842:	d3 ea                	shr    %cl,%edx
f0101844:	89 e9                	mov    %ebp,%ecx
f0101846:	09 c2                	or     %eax,%edx
f0101848:	89 d8                	mov    %ebx,%eax
f010184a:	89 14 24             	mov    %edx,(%esp)
f010184d:	89 f2                	mov    %esi,%edx
f010184f:	d3 e2                	shl    %cl,%edx
f0101851:	89 f9                	mov    %edi,%ecx
f0101853:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101857:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010185b:	d3 e8                	shr    %cl,%eax
f010185d:	89 e9                	mov    %ebp,%ecx
f010185f:	89 c6                	mov    %eax,%esi
f0101861:	d3 e3                	shl    %cl,%ebx
f0101863:	89 f9                	mov    %edi,%ecx
f0101865:	89 d0                	mov    %edx,%eax
f0101867:	d3 e8                	shr    %cl,%eax
f0101869:	89 e9                	mov    %ebp,%ecx
f010186b:	09 d8                	or     %ebx,%eax
f010186d:	89 d3                	mov    %edx,%ebx
f010186f:	89 f2                	mov    %esi,%edx
f0101871:	f7 34 24             	divl   (%esp)
f0101874:	89 d6                	mov    %edx,%esi
f0101876:	d3 e3                	shl    %cl,%ebx
f0101878:	f7 64 24 04          	mull   0x4(%esp)
f010187c:	39 d6                	cmp    %edx,%esi
f010187e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0101882:	89 d1                	mov    %edx,%ecx
f0101884:	89 c3                	mov    %eax,%ebx
f0101886:	72 08                	jb     f0101890 <__umoddi3+0x110>
f0101888:	75 11                	jne    f010189b <__umoddi3+0x11b>
f010188a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010188e:	73 0b                	jae    f010189b <__umoddi3+0x11b>
f0101890:	2b 44 24 04          	sub    0x4(%esp),%eax
f0101894:	1b 14 24             	sbb    (%esp),%edx
f0101897:	89 d1                	mov    %edx,%ecx
f0101899:	89 c3                	mov    %eax,%ebx
f010189b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010189f:	29 da                	sub    %ebx,%edx
f01018a1:	19 ce                	sbb    %ecx,%esi
f01018a3:	89 f9                	mov    %edi,%ecx
f01018a5:	89 f0                	mov    %esi,%eax
f01018a7:	d3 e0                	shl    %cl,%eax
f01018a9:	89 e9                	mov    %ebp,%ecx
f01018ab:	d3 ea                	shr    %cl,%edx
f01018ad:	89 e9                	mov    %ebp,%ecx
f01018af:	d3 ee                	shr    %cl,%esi
f01018b1:	09 d0                	or     %edx,%eax
f01018b3:	89 f2                	mov    %esi,%edx
f01018b5:	83 c4 1c             	add    $0x1c,%esp
f01018b8:	5b                   	pop    %ebx
f01018b9:	5e                   	pop    %esi
f01018ba:	5f                   	pop    %edi
f01018bb:	5d                   	pop    %ebp
f01018bc:	c3                   	ret    
f01018bd:	8d 76 00             	lea    0x0(%esi),%esi
f01018c0:	29 f9                	sub    %edi,%ecx
f01018c2:	19 d6                	sbb    %edx,%esi
f01018c4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01018c8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01018cc:	e9 18 ff ff ff       	jmp    f01017e9 <__umoddi3+0x69>
