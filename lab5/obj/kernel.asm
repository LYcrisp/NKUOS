
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:

    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200000:	c020b2b7          	lui	t0,0xc020b
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc0200004:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200008:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc020000a:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc020000e:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc0200012:	fff0031b          	addiw	t1,zero,-1
ffffffffc0200016:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200018:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc020001c:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200020:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc0200024:	c020b137          	lui	sp,0xc020b

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200028:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc020002c:	03228293          	addi	t0,t0,50 # ffffffffc0200032 <kern_init>
    jr t0
ffffffffc0200030:	8282                	jr	t0

ffffffffc0200032 <kern_init>:
void grade_backtrace(void);

int
kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc0200032:	000a7517          	auipc	a0,0xa7
ffffffffc0200036:	35650513          	addi	a0,a0,854 # ffffffffc02a7388 <buf>
ffffffffc020003a:	000b3617          	auipc	a2,0xb3
ffffffffc020003e:	8aa60613          	addi	a2,a2,-1878 # ffffffffc02b28e4 <end>
kern_init(void) {
ffffffffc0200042:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200044:	8e09                	sub	a2,a2,a0
ffffffffc0200046:	4581                	li	a1,0
kern_init(void) {
ffffffffc0200048:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020004a:	300060ef          	jal	ra,ffffffffc020634a <memset>
    cons_init();                // init the console
ffffffffc020004e:	580000ef          	jal	ra,ffffffffc02005ce <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc0200052:	00006597          	auipc	a1,0x6
ffffffffc0200056:	72658593          	addi	a1,a1,1830 # ffffffffc0206778 <etext>
ffffffffc020005a:	00006517          	auipc	a0,0x6
ffffffffc020005e:	73e50513          	addi	a0,a0,1854 # ffffffffc0206798 <etext+0x20>
ffffffffc0200062:	06a000ef          	jal	ra,ffffffffc02000cc <cprintf>

    print_kerninfo();
ffffffffc0200066:	24e000ef          	jal	ra,ffffffffc02002b4 <print_kerninfo>

    // grade_backtrace();

    pmm_init();                 // init physical memory management
ffffffffc020006a:	3cb010ef          	jal	ra,ffffffffc0201c34 <pmm_init>

    pic_init();                 // init interrupt controller
ffffffffc020006e:	5d2000ef          	jal	ra,ffffffffc0200640 <pic_init>
    idt_init();                 // init interrupt descriptor table
ffffffffc0200072:	5dc000ef          	jal	ra,ffffffffc020064e <idt_init>

    vmm_init();                 // init virtual memory management
ffffffffc0200076:	33b020ef          	jal	ra,ffffffffc0202bb0 <vmm_init>
    proc_init();                // init process table
ffffffffc020007a:	6b7050ef          	jal	ra,ffffffffc0205f30 <proc_init>
    
    ide_init();                 // init ide devices
ffffffffc020007e:	4a8000ef          	jal	ra,ffffffffc0200526 <ide_init>
    swap_init();                // init swap
ffffffffc0200082:	23e030ef          	jal	ra,ffffffffc02032c0 <swap_init>

    clock_init();               // init clock interrupt
ffffffffc0200086:	4f6000ef          	jal	ra,ffffffffc020057c <clock_init>
    intr_enable();              // enable irq interrupt
ffffffffc020008a:	5b8000ef          	jal	ra,ffffffffc0200642 <intr_enable>
    
    cpu_idle();                 // run idle process
ffffffffc020008e:	03a060ef          	jal	ra,ffffffffc02060c8 <cpu_idle>

ffffffffc0200092 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200092:	1141                	addi	sp,sp,-16
ffffffffc0200094:	e022                	sd	s0,0(sp)
ffffffffc0200096:	e406                	sd	ra,8(sp)
ffffffffc0200098:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc020009a:	536000ef          	jal	ra,ffffffffc02005d0 <cons_putc>
    (*cnt) ++;
ffffffffc020009e:	401c                	lw	a5,0(s0)
}
ffffffffc02000a0:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc02000a2:	2785                	addiw	a5,a5,1
ffffffffc02000a4:	c01c                	sw	a5,0(s0)
}
ffffffffc02000a6:	6402                	ld	s0,0(sp)
ffffffffc02000a8:	0141                	addi	sp,sp,16
ffffffffc02000aa:	8082                	ret

ffffffffc02000ac <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000ac:	1101                	addi	sp,sp,-32
ffffffffc02000ae:	862a                	mv	a2,a0
ffffffffc02000b0:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000b2:	00000517          	auipc	a0,0x0
ffffffffc02000b6:	fe050513          	addi	a0,a0,-32 # ffffffffc0200092 <cputch>
ffffffffc02000ba:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000bc:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000be:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000c0:	320060ef          	jal	ra,ffffffffc02063e0 <vprintfmt>
    return cnt;
}
ffffffffc02000c4:	60e2                	ld	ra,24(sp)
ffffffffc02000c6:	4532                	lw	a0,12(sp)
ffffffffc02000c8:	6105                	addi	sp,sp,32
ffffffffc02000ca:	8082                	ret

ffffffffc02000cc <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02000cc:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000ce:	02810313          	addi	t1,sp,40 # ffffffffc020b028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc02000d2:	8e2a                	mv	t3,a0
ffffffffc02000d4:	f42e                	sd	a1,40(sp)
ffffffffc02000d6:	f832                	sd	a2,48(sp)
ffffffffc02000d8:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000da:	00000517          	auipc	a0,0x0
ffffffffc02000de:	fb850513          	addi	a0,a0,-72 # ffffffffc0200092 <cputch>
ffffffffc02000e2:	004c                	addi	a1,sp,4
ffffffffc02000e4:	869a                	mv	a3,t1
ffffffffc02000e6:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc02000e8:	ec06                	sd	ra,24(sp)
ffffffffc02000ea:	e0ba                	sd	a4,64(sp)
ffffffffc02000ec:	e4be                	sd	a5,72(sp)
ffffffffc02000ee:	e8c2                	sd	a6,80(sp)
ffffffffc02000f0:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02000f2:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02000f4:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000f6:	2ea060ef          	jal	ra,ffffffffc02063e0 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02000fa:	60e2                	ld	ra,24(sp)
ffffffffc02000fc:	4512                	lw	a0,4(sp)
ffffffffc02000fe:	6125                	addi	sp,sp,96
ffffffffc0200100:	8082                	ret

ffffffffc0200102 <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc0200102:	a1f9                	j	ffffffffc02005d0 <cons_putc>

ffffffffc0200104 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc0200104:	1101                	addi	sp,sp,-32
ffffffffc0200106:	e822                	sd	s0,16(sp)
ffffffffc0200108:	ec06                	sd	ra,24(sp)
ffffffffc020010a:	e426                	sd	s1,8(sp)
ffffffffc020010c:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc020010e:	00054503          	lbu	a0,0(a0)
ffffffffc0200112:	c51d                	beqz	a0,ffffffffc0200140 <cputs+0x3c>
ffffffffc0200114:	0405                	addi	s0,s0,1
ffffffffc0200116:	4485                	li	s1,1
ffffffffc0200118:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc020011a:	4b6000ef          	jal	ra,ffffffffc02005d0 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc020011e:	00044503          	lbu	a0,0(s0)
ffffffffc0200122:	008487bb          	addw	a5,s1,s0
ffffffffc0200126:	0405                	addi	s0,s0,1
ffffffffc0200128:	f96d                	bnez	a0,ffffffffc020011a <cputs+0x16>
    (*cnt) ++;
ffffffffc020012a:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc020012e:	4529                	li	a0,10
ffffffffc0200130:	4a0000ef          	jal	ra,ffffffffc02005d0 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc0200134:	60e2                	ld	ra,24(sp)
ffffffffc0200136:	8522                	mv	a0,s0
ffffffffc0200138:	6442                	ld	s0,16(sp)
ffffffffc020013a:	64a2                	ld	s1,8(sp)
ffffffffc020013c:	6105                	addi	sp,sp,32
ffffffffc020013e:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc0200140:	4405                	li	s0,1
ffffffffc0200142:	b7f5                	j	ffffffffc020012e <cputs+0x2a>

ffffffffc0200144 <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc0200144:	1141                	addi	sp,sp,-16
ffffffffc0200146:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc0200148:	4bc000ef          	jal	ra,ffffffffc0200604 <cons_getc>
ffffffffc020014c:	dd75                	beqz	a0,ffffffffc0200148 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc020014e:	60a2                	ld	ra,8(sp)
ffffffffc0200150:	0141                	addi	sp,sp,16
ffffffffc0200152:	8082                	ret

ffffffffc0200154 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0200154:	715d                	addi	sp,sp,-80
ffffffffc0200156:	e486                	sd	ra,72(sp)
ffffffffc0200158:	e0a6                	sd	s1,64(sp)
ffffffffc020015a:	fc4a                	sd	s2,56(sp)
ffffffffc020015c:	f84e                	sd	s3,48(sp)
ffffffffc020015e:	f452                	sd	s4,40(sp)
ffffffffc0200160:	f056                	sd	s5,32(sp)
ffffffffc0200162:	ec5a                	sd	s6,24(sp)
ffffffffc0200164:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc0200166:	c901                	beqz	a0,ffffffffc0200176 <readline+0x22>
ffffffffc0200168:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc020016a:	00006517          	auipc	a0,0x6
ffffffffc020016e:	63650513          	addi	a0,a0,1590 # ffffffffc02067a0 <etext+0x28>
ffffffffc0200172:	f5bff0ef          	jal	ra,ffffffffc02000cc <cprintf>
readline(const char *prompt) {
ffffffffc0200176:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0200178:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc020017a:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc020017c:	4aa9                	li	s5,10
ffffffffc020017e:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc0200180:	000a7b97          	auipc	s7,0xa7
ffffffffc0200184:	208b8b93          	addi	s7,s7,520 # ffffffffc02a7388 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0200188:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc020018c:	fb9ff0ef          	jal	ra,ffffffffc0200144 <getchar>
        if (c < 0) {
ffffffffc0200190:	00054a63          	bltz	a0,ffffffffc02001a4 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0200194:	00a95a63          	bge	s2,a0,ffffffffc02001a8 <readline+0x54>
ffffffffc0200198:	029a5263          	bge	s4,s1,ffffffffc02001bc <readline+0x68>
        c = getchar();
ffffffffc020019c:	fa9ff0ef          	jal	ra,ffffffffc0200144 <getchar>
        if (c < 0) {
ffffffffc02001a0:	fe055ae3          	bgez	a0,ffffffffc0200194 <readline+0x40>
            return NULL;
ffffffffc02001a4:	4501                	li	a0,0
ffffffffc02001a6:	a091                	j	ffffffffc02001ea <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc02001a8:	03351463          	bne	a0,s3,ffffffffc02001d0 <readline+0x7c>
ffffffffc02001ac:	e8a9                	bnez	s1,ffffffffc02001fe <readline+0xaa>
        c = getchar();
ffffffffc02001ae:	f97ff0ef          	jal	ra,ffffffffc0200144 <getchar>
        if (c < 0) {
ffffffffc02001b2:	fe0549e3          	bltz	a0,ffffffffc02001a4 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02001b6:	fea959e3          	bge	s2,a0,ffffffffc02001a8 <readline+0x54>
ffffffffc02001ba:	4481                	li	s1,0
            cputchar(c);
ffffffffc02001bc:	e42a                	sd	a0,8(sp)
ffffffffc02001be:	f45ff0ef          	jal	ra,ffffffffc0200102 <cputchar>
            buf[i ++] = c;
ffffffffc02001c2:	6522                	ld	a0,8(sp)
ffffffffc02001c4:	009b87b3          	add	a5,s7,s1
ffffffffc02001c8:	2485                	addiw	s1,s1,1
ffffffffc02001ca:	00a78023          	sb	a0,0(a5)
ffffffffc02001ce:	bf7d                	j	ffffffffc020018c <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc02001d0:	01550463          	beq	a0,s5,ffffffffc02001d8 <readline+0x84>
ffffffffc02001d4:	fb651ce3          	bne	a0,s6,ffffffffc020018c <readline+0x38>
            cputchar(c);
ffffffffc02001d8:	f2bff0ef          	jal	ra,ffffffffc0200102 <cputchar>
            buf[i] = '\0';
ffffffffc02001dc:	000a7517          	auipc	a0,0xa7
ffffffffc02001e0:	1ac50513          	addi	a0,a0,428 # ffffffffc02a7388 <buf>
ffffffffc02001e4:	94aa                	add	s1,s1,a0
ffffffffc02001e6:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc02001ea:	60a6                	ld	ra,72(sp)
ffffffffc02001ec:	6486                	ld	s1,64(sp)
ffffffffc02001ee:	7962                	ld	s2,56(sp)
ffffffffc02001f0:	79c2                	ld	s3,48(sp)
ffffffffc02001f2:	7a22                	ld	s4,40(sp)
ffffffffc02001f4:	7a82                	ld	s5,32(sp)
ffffffffc02001f6:	6b62                	ld	s6,24(sp)
ffffffffc02001f8:	6bc2                	ld	s7,16(sp)
ffffffffc02001fa:	6161                	addi	sp,sp,80
ffffffffc02001fc:	8082                	ret
            cputchar(c);
ffffffffc02001fe:	4521                	li	a0,8
ffffffffc0200200:	f03ff0ef          	jal	ra,ffffffffc0200102 <cputchar>
            i --;
ffffffffc0200204:	34fd                	addiw	s1,s1,-1
ffffffffc0200206:	b759                	j	ffffffffc020018c <readline+0x38>

ffffffffc0200208 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc0200208:	000b2317          	auipc	t1,0xb2
ffffffffc020020c:	64830313          	addi	t1,t1,1608 # ffffffffc02b2850 <is_panic>
ffffffffc0200210:	00033e03          	ld	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc0200214:	715d                	addi	sp,sp,-80
ffffffffc0200216:	ec06                	sd	ra,24(sp)
ffffffffc0200218:	e822                	sd	s0,16(sp)
ffffffffc020021a:	f436                	sd	a3,40(sp)
ffffffffc020021c:	f83a                	sd	a4,48(sp)
ffffffffc020021e:	fc3e                	sd	a5,56(sp)
ffffffffc0200220:	e0c2                	sd	a6,64(sp)
ffffffffc0200222:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc0200224:	020e1a63          	bnez	t3,ffffffffc0200258 <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc0200228:	4785                	li	a5,1
ffffffffc020022a:	00f33023          	sd	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc020022e:	8432                	mv	s0,a2
ffffffffc0200230:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200232:	862e                	mv	a2,a1
ffffffffc0200234:	85aa                	mv	a1,a0
ffffffffc0200236:	00006517          	auipc	a0,0x6
ffffffffc020023a:	57250513          	addi	a0,a0,1394 # ffffffffc02067a8 <etext+0x30>
    va_start(ap, fmt);
ffffffffc020023e:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200240:	e8dff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200244:	65a2                	ld	a1,8(sp)
ffffffffc0200246:	8522                	mv	a0,s0
ffffffffc0200248:	e65ff0ef          	jal	ra,ffffffffc02000ac <vcprintf>
    cprintf("\n");
ffffffffc020024c:	00007517          	auipc	a0,0x7
ffffffffc0200250:	3e450513          	addi	a0,a0,996 # ffffffffc0207630 <commands+0xc10>
ffffffffc0200254:	e79ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc0200258:	4501                	li	a0,0
ffffffffc020025a:	4581                	li	a1,0
ffffffffc020025c:	4601                	li	a2,0
ffffffffc020025e:	48a1                	li	a7,8
ffffffffc0200260:	00000073          	ecall
    va_end(ap);

panic_dead:
    // No debug monitor here
    sbi_shutdown();
    intr_disable();
ffffffffc0200264:	3e4000ef          	jal	ra,ffffffffc0200648 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc0200268:	4501                	li	a0,0
ffffffffc020026a:	174000ef          	jal	ra,ffffffffc02003de <kmonitor>
    while (1) {
ffffffffc020026e:	bfed                	j	ffffffffc0200268 <__panic+0x60>

ffffffffc0200270 <__warn>:
    }
}

/* __warn - like panic, but don't */
void
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc0200270:	715d                	addi	sp,sp,-80
ffffffffc0200272:	832e                	mv	t1,a1
ffffffffc0200274:	e822                	sd	s0,16(sp)
    va_list ap;
    va_start(ap, fmt);
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc0200276:	85aa                	mv	a1,a0
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc0200278:	8432                	mv	s0,a2
ffffffffc020027a:	fc3e                	sd	a5,56(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc020027c:	861a                	mv	a2,t1
    va_start(ap, fmt);
ffffffffc020027e:	103c                	addi	a5,sp,40
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc0200280:	00006517          	auipc	a0,0x6
ffffffffc0200284:	54850513          	addi	a0,a0,1352 # ffffffffc02067c8 <etext+0x50>
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc0200288:	ec06                	sd	ra,24(sp)
ffffffffc020028a:	f436                	sd	a3,40(sp)
ffffffffc020028c:	f83a                	sd	a4,48(sp)
ffffffffc020028e:	e0c2                	sd	a6,64(sp)
ffffffffc0200290:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0200292:	e43e                	sd	a5,8(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc0200294:	e39ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200298:	65a2                	ld	a1,8(sp)
ffffffffc020029a:	8522                	mv	a0,s0
ffffffffc020029c:	e11ff0ef          	jal	ra,ffffffffc02000ac <vcprintf>
    cprintf("\n");
ffffffffc02002a0:	00007517          	auipc	a0,0x7
ffffffffc02002a4:	39050513          	addi	a0,a0,912 # ffffffffc0207630 <commands+0xc10>
ffffffffc02002a8:	e25ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    va_end(ap);
}
ffffffffc02002ac:	60e2                	ld	ra,24(sp)
ffffffffc02002ae:	6442                	ld	s0,16(sp)
ffffffffc02002b0:	6161                	addi	sp,sp,80
ffffffffc02002b2:	8082                	ret

ffffffffc02002b4 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc02002b4:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc02002b6:	00006517          	auipc	a0,0x6
ffffffffc02002ba:	53250513          	addi	a0,a0,1330 # ffffffffc02067e8 <etext+0x70>
void print_kerninfo(void) {
ffffffffc02002be:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc02002c0:	e0dff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc02002c4:	00000597          	auipc	a1,0x0
ffffffffc02002c8:	d6e58593          	addi	a1,a1,-658 # ffffffffc0200032 <kern_init>
ffffffffc02002cc:	00006517          	auipc	a0,0x6
ffffffffc02002d0:	53c50513          	addi	a0,a0,1340 # ffffffffc0206808 <etext+0x90>
ffffffffc02002d4:	df9ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc02002d8:	00006597          	auipc	a1,0x6
ffffffffc02002dc:	4a058593          	addi	a1,a1,1184 # ffffffffc0206778 <etext>
ffffffffc02002e0:	00006517          	auipc	a0,0x6
ffffffffc02002e4:	54850513          	addi	a0,a0,1352 # ffffffffc0206828 <etext+0xb0>
ffffffffc02002e8:	de5ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc02002ec:	000a7597          	auipc	a1,0xa7
ffffffffc02002f0:	09c58593          	addi	a1,a1,156 # ffffffffc02a7388 <buf>
ffffffffc02002f4:	00006517          	auipc	a0,0x6
ffffffffc02002f8:	55450513          	addi	a0,a0,1364 # ffffffffc0206848 <etext+0xd0>
ffffffffc02002fc:	dd1ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200300:	000b2597          	auipc	a1,0xb2
ffffffffc0200304:	5e458593          	addi	a1,a1,1508 # ffffffffc02b28e4 <end>
ffffffffc0200308:	00006517          	auipc	a0,0x6
ffffffffc020030c:	56050513          	addi	a0,a0,1376 # ffffffffc0206868 <etext+0xf0>
ffffffffc0200310:	dbdff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc0200314:	000b3597          	auipc	a1,0xb3
ffffffffc0200318:	9cf58593          	addi	a1,a1,-1585 # ffffffffc02b2ce3 <end+0x3ff>
ffffffffc020031c:	00000797          	auipc	a5,0x0
ffffffffc0200320:	d1678793          	addi	a5,a5,-746 # ffffffffc0200032 <kern_init>
ffffffffc0200324:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200328:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc020032c:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc020032e:	3ff5f593          	andi	a1,a1,1023
ffffffffc0200332:	95be                	add	a1,a1,a5
ffffffffc0200334:	85a9                	srai	a1,a1,0xa
ffffffffc0200336:	00006517          	auipc	a0,0x6
ffffffffc020033a:	55250513          	addi	a0,a0,1362 # ffffffffc0206888 <etext+0x110>
}
ffffffffc020033e:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200340:	b371                	j	ffffffffc02000cc <cprintf>

ffffffffc0200342 <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc0200342:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc0200344:	00006617          	auipc	a2,0x6
ffffffffc0200348:	57460613          	addi	a2,a2,1396 # ffffffffc02068b8 <etext+0x140>
ffffffffc020034c:	04d00593          	li	a1,77
ffffffffc0200350:	00006517          	auipc	a0,0x6
ffffffffc0200354:	58050513          	addi	a0,a0,1408 # ffffffffc02068d0 <etext+0x158>
void print_stackframe(void) {
ffffffffc0200358:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc020035a:	eafff0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc020035e <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc020035e:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200360:	00006617          	auipc	a2,0x6
ffffffffc0200364:	58860613          	addi	a2,a2,1416 # ffffffffc02068e8 <etext+0x170>
ffffffffc0200368:	00006597          	auipc	a1,0x6
ffffffffc020036c:	5a058593          	addi	a1,a1,1440 # ffffffffc0206908 <etext+0x190>
ffffffffc0200370:	00006517          	auipc	a0,0x6
ffffffffc0200374:	5a050513          	addi	a0,a0,1440 # ffffffffc0206910 <etext+0x198>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200378:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc020037a:	d53ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
ffffffffc020037e:	00006617          	auipc	a2,0x6
ffffffffc0200382:	5a260613          	addi	a2,a2,1442 # ffffffffc0206920 <etext+0x1a8>
ffffffffc0200386:	00006597          	auipc	a1,0x6
ffffffffc020038a:	5c258593          	addi	a1,a1,1474 # ffffffffc0206948 <etext+0x1d0>
ffffffffc020038e:	00006517          	auipc	a0,0x6
ffffffffc0200392:	58250513          	addi	a0,a0,1410 # ffffffffc0206910 <etext+0x198>
ffffffffc0200396:	d37ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
ffffffffc020039a:	00006617          	auipc	a2,0x6
ffffffffc020039e:	5be60613          	addi	a2,a2,1470 # ffffffffc0206958 <etext+0x1e0>
ffffffffc02003a2:	00006597          	auipc	a1,0x6
ffffffffc02003a6:	5d658593          	addi	a1,a1,1494 # ffffffffc0206978 <etext+0x200>
ffffffffc02003aa:	00006517          	auipc	a0,0x6
ffffffffc02003ae:	56650513          	addi	a0,a0,1382 # ffffffffc0206910 <etext+0x198>
ffffffffc02003b2:	d1bff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    }
    return 0;
}
ffffffffc02003b6:	60a2                	ld	ra,8(sp)
ffffffffc02003b8:	4501                	li	a0,0
ffffffffc02003ba:	0141                	addi	sp,sp,16
ffffffffc02003bc:	8082                	ret

ffffffffc02003be <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc02003be:	1141                	addi	sp,sp,-16
ffffffffc02003c0:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc02003c2:	ef3ff0ef          	jal	ra,ffffffffc02002b4 <print_kerninfo>
    return 0;
}
ffffffffc02003c6:	60a2                	ld	ra,8(sp)
ffffffffc02003c8:	4501                	li	a0,0
ffffffffc02003ca:	0141                	addi	sp,sp,16
ffffffffc02003cc:	8082                	ret

ffffffffc02003ce <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc02003ce:	1141                	addi	sp,sp,-16
ffffffffc02003d0:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc02003d2:	f71ff0ef          	jal	ra,ffffffffc0200342 <print_stackframe>
    return 0;
}
ffffffffc02003d6:	60a2                	ld	ra,8(sp)
ffffffffc02003d8:	4501                	li	a0,0
ffffffffc02003da:	0141                	addi	sp,sp,16
ffffffffc02003dc:	8082                	ret

ffffffffc02003de <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc02003de:	7115                	addi	sp,sp,-224
ffffffffc02003e0:	ed5e                	sd	s7,152(sp)
ffffffffc02003e2:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02003e4:	00006517          	auipc	a0,0x6
ffffffffc02003e8:	5a450513          	addi	a0,a0,1444 # ffffffffc0206988 <etext+0x210>
kmonitor(struct trapframe *tf) {
ffffffffc02003ec:	ed86                	sd	ra,216(sp)
ffffffffc02003ee:	e9a2                	sd	s0,208(sp)
ffffffffc02003f0:	e5a6                	sd	s1,200(sp)
ffffffffc02003f2:	e1ca                	sd	s2,192(sp)
ffffffffc02003f4:	fd4e                	sd	s3,184(sp)
ffffffffc02003f6:	f952                	sd	s4,176(sp)
ffffffffc02003f8:	f556                	sd	s5,168(sp)
ffffffffc02003fa:	f15a                	sd	s6,160(sp)
ffffffffc02003fc:	e962                	sd	s8,144(sp)
ffffffffc02003fe:	e566                	sd	s9,136(sp)
ffffffffc0200400:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200402:	ccbff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc0200406:	00006517          	auipc	a0,0x6
ffffffffc020040a:	5aa50513          	addi	a0,a0,1450 # ffffffffc02069b0 <etext+0x238>
ffffffffc020040e:	cbfff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    if (tf != NULL) {
ffffffffc0200412:	000b8563          	beqz	s7,ffffffffc020041c <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc0200416:	855e                	mv	a0,s7
ffffffffc0200418:	41e000ef          	jal	ra,ffffffffc0200836 <print_trapframe>
ffffffffc020041c:	00006c17          	auipc	s8,0x6
ffffffffc0200420:	604c0c13          	addi	s8,s8,1540 # ffffffffc0206a20 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200424:	00006917          	auipc	s2,0x6
ffffffffc0200428:	5b490913          	addi	s2,s2,1460 # ffffffffc02069d8 <etext+0x260>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020042c:	00006497          	auipc	s1,0x6
ffffffffc0200430:	5b448493          	addi	s1,s1,1460 # ffffffffc02069e0 <etext+0x268>
        if (argc == MAXARGS - 1) {
ffffffffc0200434:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200436:	00006b17          	auipc	s6,0x6
ffffffffc020043a:	5b2b0b13          	addi	s6,s6,1458 # ffffffffc02069e8 <etext+0x270>
        argv[argc ++] = buf;
ffffffffc020043e:	00006a17          	auipc	s4,0x6
ffffffffc0200442:	4caa0a13          	addi	s4,s4,1226 # ffffffffc0206908 <etext+0x190>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200446:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200448:	854a                	mv	a0,s2
ffffffffc020044a:	d0bff0ef          	jal	ra,ffffffffc0200154 <readline>
ffffffffc020044e:	842a                	mv	s0,a0
ffffffffc0200450:	dd65                	beqz	a0,ffffffffc0200448 <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200452:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc0200456:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200458:	e1bd                	bnez	a1,ffffffffc02004be <kmonitor+0xe0>
    if (argc == 0) {
ffffffffc020045a:	fe0c87e3          	beqz	s9,ffffffffc0200448 <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020045e:	6582                	ld	a1,0(sp)
ffffffffc0200460:	00006d17          	auipc	s10,0x6
ffffffffc0200464:	5c0d0d13          	addi	s10,s10,1472 # ffffffffc0206a20 <commands>
        argv[argc ++] = buf;
ffffffffc0200468:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020046a:	4401                	li	s0,0
ffffffffc020046c:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020046e:	6a9050ef          	jal	ra,ffffffffc0206316 <strcmp>
ffffffffc0200472:	c919                	beqz	a0,ffffffffc0200488 <kmonitor+0xaa>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200474:	2405                	addiw	s0,s0,1
ffffffffc0200476:	0b540063          	beq	s0,s5,ffffffffc0200516 <kmonitor+0x138>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020047a:	000d3503          	ld	a0,0(s10)
ffffffffc020047e:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200480:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200482:	695050ef          	jal	ra,ffffffffc0206316 <strcmp>
ffffffffc0200486:	f57d                	bnez	a0,ffffffffc0200474 <kmonitor+0x96>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc0200488:	00141793          	slli	a5,s0,0x1
ffffffffc020048c:	97a2                	add	a5,a5,s0
ffffffffc020048e:	078e                	slli	a5,a5,0x3
ffffffffc0200490:	97e2                	add	a5,a5,s8
ffffffffc0200492:	6b9c                	ld	a5,16(a5)
ffffffffc0200494:	865e                	mv	a2,s7
ffffffffc0200496:	002c                	addi	a1,sp,8
ffffffffc0200498:	fffc851b          	addiw	a0,s9,-1
ffffffffc020049c:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc020049e:	fa0555e3          	bgez	a0,ffffffffc0200448 <kmonitor+0x6a>
}
ffffffffc02004a2:	60ee                	ld	ra,216(sp)
ffffffffc02004a4:	644e                	ld	s0,208(sp)
ffffffffc02004a6:	64ae                	ld	s1,200(sp)
ffffffffc02004a8:	690e                	ld	s2,192(sp)
ffffffffc02004aa:	79ea                	ld	s3,184(sp)
ffffffffc02004ac:	7a4a                	ld	s4,176(sp)
ffffffffc02004ae:	7aaa                	ld	s5,168(sp)
ffffffffc02004b0:	7b0a                	ld	s6,160(sp)
ffffffffc02004b2:	6bea                	ld	s7,152(sp)
ffffffffc02004b4:	6c4a                	ld	s8,144(sp)
ffffffffc02004b6:	6caa                	ld	s9,136(sp)
ffffffffc02004b8:	6d0a                	ld	s10,128(sp)
ffffffffc02004ba:	612d                	addi	sp,sp,224
ffffffffc02004bc:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02004be:	8526                	mv	a0,s1
ffffffffc02004c0:	675050ef          	jal	ra,ffffffffc0206334 <strchr>
ffffffffc02004c4:	c901                	beqz	a0,ffffffffc02004d4 <kmonitor+0xf6>
ffffffffc02004c6:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc02004ca:	00040023          	sb	zero,0(s0)
ffffffffc02004ce:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02004d0:	d5c9                	beqz	a1,ffffffffc020045a <kmonitor+0x7c>
ffffffffc02004d2:	b7f5                	j	ffffffffc02004be <kmonitor+0xe0>
        if (*buf == '\0') {
ffffffffc02004d4:	00044783          	lbu	a5,0(s0)
ffffffffc02004d8:	d3c9                	beqz	a5,ffffffffc020045a <kmonitor+0x7c>
        if (argc == MAXARGS - 1) {
ffffffffc02004da:	033c8963          	beq	s9,s3,ffffffffc020050c <kmonitor+0x12e>
        argv[argc ++] = buf;
ffffffffc02004de:	003c9793          	slli	a5,s9,0x3
ffffffffc02004e2:	0118                	addi	a4,sp,128
ffffffffc02004e4:	97ba                	add	a5,a5,a4
ffffffffc02004e6:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02004ea:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc02004ee:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02004f0:	e591                	bnez	a1,ffffffffc02004fc <kmonitor+0x11e>
ffffffffc02004f2:	b7b5                	j	ffffffffc020045e <kmonitor+0x80>
ffffffffc02004f4:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc02004f8:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02004fa:	d1a5                	beqz	a1,ffffffffc020045a <kmonitor+0x7c>
ffffffffc02004fc:	8526                	mv	a0,s1
ffffffffc02004fe:	637050ef          	jal	ra,ffffffffc0206334 <strchr>
ffffffffc0200502:	d96d                	beqz	a0,ffffffffc02004f4 <kmonitor+0x116>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200504:	00044583          	lbu	a1,0(s0)
ffffffffc0200508:	d9a9                	beqz	a1,ffffffffc020045a <kmonitor+0x7c>
ffffffffc020050a:	bf55                	j	ffffffffc02004be <kmonitor+0xe0>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020050c:	45c1                	li	a1,16
ffffffffc020050e:	855a                	mv	a0,s6
ffffffffc0200510:	bbdff0ef          	jal	ra,ffffffffc02000cc <cprintf>
ffffffffc0200514:	b7e9                	j	ffffffffc02004de <kmonitor+0x100>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc0200516:	6582                	ld	a1,0(sp)
ffffffffc0200518:	00006517          	auipc	a0,0x6
ffffffffc020051c:	4f050513          	addi	a0,a0,1264 # ffffffffc0206a08 <etext+0x290>
ffffffffc0200520:	badff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    return 0;
ffffffffc0200524:	b715                	j	ffffffffc0200448 <kmonitor+0x6a>

ffffffffc0200526 <ide_init>:
#include <stdio.h>
#include <string.h>
#include <trap.h>
#include <riscv.h>

void ide_init(void) {}
ffffffffc0200526:	8082                	ret

ffffffffc0200528 <ide_device_valid>:

#define MAX_IDE 2
#define MAX_DISK_NSECS 56
static char ide[MAX_DISK_NSECS * SECTSIZE];

bool ide_device_valid(unsigned short ideno) { return ideno < MAX_IDE; }
ffffffffc0200528:	00253513          	sltiu	a0,a0,2
ffffffffc020052c:	8082                	ret

ffffffffc020052e <ide_device_size>:

size_t ide_device_size(unsigned short ideno) { return MAX_DISK_NSECS; }
ffffffffc020052e:	03800513          	li	a0,56
ffffffffc0200532:	8082                	ret

ffffffffc0200534 <ide_read_secs>:

int ide_read_secs(unsigned short ideno, uint32_t secno, void *dst,
                  size_t nsecs) {
    int iobase = secno * SECTSIZE;
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc0200534:	000a7797          	auipc	a5,0xa7
ffffffffc0200538:	25478793          	addi	a5,a5,596 # ffffffffc02a7788 <ide>
    int iobase = secno * SECTSIZE;
ffffffffc020053c:	0095959b          	slliw	a1,a1,0x9
                  size_t nsecs) {
ffffffffc0200540:	1141                	addi	sp,sp,-16
ffffffffc0200542:	8532                	mv	a0,a2
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc0200544:	95be                	add	a1,a1,a5
ffffffffc0200546:	00969613          	slli	a2,a3,0x9
                  size_t nsecs) {
ffffffffc020054a:	e406                	sd	ra,8(sp)
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc020054c:	611050ef          	jal	ra,ffffffffc020635c <memcpy>
    return 0;
}
ffffffffc0200550:	60a2                	ld	ra,8(sp)
ffffffffc0200552:	4501                	li	a0,0
ffffffffc0200554:	0141                	addi	sp,sp,16
ffffffffc0200556:	8082                	ret

ffffffffc0200558 <ide_write_secs>:

int ide_write_secs(unsigned short ideno, uint32_t secno, const void *src,
                   size_t nsecs) {
    int iobase = secno * SECTSIZE;
ffffffffc0200558:	0095979b          	slliw	a5,a1,0x9
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc020055c:	000a7517          	auipc	a0,0xa7
ffffffffc0200560:	22c50513          	addi	a0,a0,556 # ffffffffc02a7788 <ide>
                   size_t nsecs) {
ffffffffc0200564:	1141                	addi	sp,sp,-16
ffffffffc0200566:	85b2                	mv	a1,a2
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc0200568:	953e                	add	a0,a0,a5
ffffffffc020056a:	00969613          	slli	a2,a3,0x9
                   size_t nsecs) {
ffffffffc020056e:	e406                	sd	ra,8(sp)
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc0200570:	5ed050ef          	jal	ra,ffffffffc020635c <memcpy>
    return 0;
}
ffffffffc0200574:	60a2                	ld	ra,8(sp)
ffffffffc0200576:	4501                	li	a0,0
ffffffffc0200578:	0141                	addi	sp,sp,16
ffffffffc020057a:	8082                	ret

ffffffffc020057c <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc020057c:	67e1                	lui	a5,0x18
ffffffffc020057e:	6a078793          	addi	a5,a5,1696 # 186a0 <_binary_obj___user_exit_out_size+0xd568>
ffffffffc0200582:	000b2717          	auipc	a4,0xb2
ffffffffc0200586:	2cf73f23          	sd	a5,734(a4) # ffffffffc02b2860 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020058a:	c0102573          	rdtime	a0
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc020058e:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200590:	953e                	add	a0,a0,a5
ffffffffc0200592:	4601                	li	a2,0
ffffffffc0200594:	4881                	li	a7,0
ffffffffc0200596:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc020059a:	02000793          	li	a5,32
ffffffffc020059e:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc02005a2:	00006517          	auipc	a0,0x6
ffffffffc02005a6:	4c650513          	addi	a0,a0,1222 # ffffffffc0206a68 <commands+0x48>
    ticks = 0;
ffffffffc02005aa:	000b2797          	auipc	a5,0xb2
ffffffffc02005ae:	2a07b723          	sd	zero,686(a5) # ffffffffc02b2858 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc02005b2:	be29                	j	ffffffffc02000cc <cprintf>

ffffffffc02005b4 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc02005b4:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc02005b8:	000b2797          	auipc	a5,0xb2
ffffffffc02005bc:	2a87b783          	ld	a5,680(a5) # ffffffffc02b2860 <timebase>
ffffffffc02005c0:	953e                	add	a0,a0,a5
ffffffffc02005c2:	4581                	li	a1,0
ffffffffc02005c4:	4601                	li	a2,0
ffffffffc02005c6:	4881                	li	a7,0
ffffffffc02005c8:	00000073          	ecall
ffffffffc02005cc:	8082                	ret

ffffffffc02005ce <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc02005ce:	8082                	ret

ffffffffc02005d0 <cons_putc>:
#include <sched.h>
#include <riscv.h>
#include <assert.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02005d0:	100027f3          	csrr	a5,sstatus
ffffffffc02005d4:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc02005d6:	0ff57513          	zext.b	a0,a0
ffffffffc02005da:	e799                	bnez	a5,ffffffffc02005e8 <cons_putc+0x18>
ffffffffc02005dc:	4581                	li	a1,0
ffffffffc02005de:	4601                	li	a2,0
ffffffffc02005e0:	4885                	li	a7,1
ffffffffc02005e2:	00000073          	ecall
    }
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
ffffffffc02005e6:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc02005e8:	1101                	addi	sp,sp,-32
ffffffffc02005ea:	ec06                	sd	ra,24(sp)
ffffffffc02005ec:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02005ee:	05a000ef          	jal	ra,ffffffffc0200648 <intr_disable>
ffffffffc02005f2:	6522                	ld	a0,8(sp)
ffffffffc02005f4:	4581                	li	a1,0
ffffffffc02005f6:	4601                	li	a2,0
ffffffffc02005f8:	4885                	li	a7,1
ffffffffc02005fa:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc02005fe:	60e2                	ld	ra,24(sp)
ffffffffc0200600:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0200602:	a081                	j	ffffffffc0200642 <intr_enable>

ffffffffc0200604 <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200604:	100027f3          	csrr	a5,sstatus
ffffffffc0200608:	8b89                	andi	a5,a5,2
ffffffffc020060a:	eb89                	bnez	a5,ffffffffc020061c <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc020060c:	4501                	li	a0,0
ffffffffc020060e:	4581                	li	a1,0
ffffffffc0200610:	4601                	li	a2,0
ffffffffc0200612:	4889                	li	a7,2
ffffffffc0200614:	00000073          	ecall
ffffffffc0200618:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc020061a:	8082                	ret
int cons_getc(void) {
ffffffffc020061c:	1101                	addi	sp,sp,-32
ffffffffc020061e:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0200620:	028000ef          	jal	ra,ffffffffc0200648 <intr_disable>
ffffffffc0200624:	4501                	li	a0,0
ffffffffc0200626:	4581                	li	a1,0
ffffffffc0200628:	4601                	li	a2,0
ffffffffc020062a:	4889                	li	a7,2
ffffffffc020062c:	00000073          	ecall
ffffffffc0200630:	2501                	sext.w	a0,a0
ffffffffc0200632:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0200634:	00e000ef          	jal	ra,ffffffffc0200642 <intr_enable>
}
ffffffffc0200638:	60e2                	ld	ra,24(sp)
ffffffffc020063a:	6522                	ld	a0,8(sp)
ffffffffc020063c:	6105                	addi	sp,sp,32
ffffffffc020063e:	8082                	ret

ffffffffc0200640 <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc0200640:	8082                	ret

ffffffffc0200642 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200642:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200646:	8082                	ret

ffffffffc0200648 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200648:	100177f3          	csrrci	a5,sstatus,2
ffffffffc020064c:	8082                	ret

ffffffffc020064e <idt_init>:
void
idt_init(void) {
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc020064e:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc0200652:	00000797          	auipc	a5,0x0
ffffffffc0200656:	65a78793          	addi	a5,a5,1626 # ffffffffc0200cac <__alltraps>
ffffffffc020065a:	10579073          	csrw	stvec,a5
    /* Allow kernel to access user memory */
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc020065e:	000407b7          	lui	a5,0x40
ffffffffc0200662:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc0200666:	8082                	ret

ffffffffc0200668 <print_regs>:
    cprintf("  tval 0x%08x\n", tf->tval);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs* gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200668:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs* gpr) {
ffffffffc020066a:	1141                	addi	sp,sp,-16
ffffffffc020066c:	e022                	sd	s0,0(sp)
ffffffffc020066e:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200670:	00006517          	auipc	a0,0x6
ffffffffc0200674:	41850513          	addi	a0,a0,1048 # ffffffffc0206a88 <commands+0x68>
void print_regs(struct pushregs* gpr) {
ffffffffc0200678:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020067a:	a53ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc020067e:	640c                	ld	a1,8(s0)
ffffffffc0200680:	00006517          	auipc	a0,0x6
ffffffffc0200684:	42050513          	addi	a0,a0,1056 # ffffffffc0206aa0 <commands+0x80>
ffffffffc0200688:	a45ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc020068c:	680c                	ld	a1,16(s0)
ffffffffc020068e:	00006517          	auipc	a0,0x6
ffffffffc0200692:	42a50513          	addi	a0,a0,1066 # ffffffffc0206ab8 <commands+0x98>
ffffffffc0200696:	a37ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc020069a:	6c0c                	ld	a1,24(s0)
ffffffffc020069c:	00006517          	auipc	a0,0x6
ffffffffc02006a0:	43450513          	addi	a0,a0,1076 # ffffffffc0206ad0 <commands+0xb0>
ffffffffc02006a4:	a29ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02006a8:	700c                	ld	a1,32(s0)
ffffffffc02006aa:	00006517          	auipc	a0,0x6
ffffffffc02006ae:	43e50513          	addi	a0,a0,1086 # ffffffffc0206ae8 <commands+0xc8>
ffffffffc02006b2:	a1bff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02006b6:	740c                	ld	a1,40(s0)
ffffffffc02006b8:	00006517          	auipc	a0,0x6
ffffffffc02006bc:	44850513          	addi	a0,a0,1096 # ffffffffc0206b00 <commands+0xe0>
ffffffffc02006c0:	a0dff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02006c4:	780c                	ld	a1,48(s0)
ffffffffc02006c6:	00006517          	auipc	a0,0x6
ffffffffc02006ca:	45250513          	addi	a0,a0,1106 # ffffffffc0206b18 <commands+0xf8>
ffffffffc02006ce:	9ffff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02006d2:	7c0c                	ld	a1,56(s0)
ffffffffc02006d4:	00006517          	auipc	a0,0x6
ffffffffc02006d8:	45c50513          	addi	a0,a0,1116 # ffffffffc0206b30 <commands+0x110>
ffffffffc02006dc:	9f1ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02006e0:	602c                	ld	a1,64(s0)
ffffffffc02006e2:	00006517          	auipc	a0,0x6
ffffffffc02006e6:	46650513          	addi	a0,a0,1126 # ffffffffc0206b48 <commands+0x128>
ffffffffc02006ea:	9e3ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02006ee:	642c                	ld	a1,72(s0)
ffffffffc02006f0:	00006517          	auipc	a0,0x6
ffffffffc02006f4:	47050513          	addi	a0,a0,1136 # ffffffffc0206b60 <commands+0x140>
ffffffffc02006f8:	9d5ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc02006fc:	682c                	ld	a1,80(s0)
ffffffffc02006fe:	00006517          	auipc	a0,0x6
ffffffffc0200702:	47a50513          	addi	a0,a0,1146 # ffffffffc0206b78 <commands+0x158>
ffffffffc0200706:	9c7ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc020070a:	6c2c                	ld	a1,88(s0)
ffffffffc020070c:	00006517          	auipc	a0,0x6
ffffffffc0200710:	48450513          	addi	a0,a0,1156 # ffffffffc0206b90 <commands+0x170>
ffffffffc0200714:	9b9ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200718:	702c                	ld	a1,96(s0)
ffffffffc020071a:	00006517          	auipc	a0,0x6
ffffffffc020071e:	48e50513          	addi	a0,a0,1166 # ffffffffc0206ba8 <commands+0x188>
ffffffffc0200722:	9abff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200726:	742c                	ld	a1,104(s0)
ffffffffc0200728:	00006517          	auipc	a0,0x6
ffffffffc020072c:	49850513          	addi	a0,a0,1176 # ffffffffc0206bc0 <commands+0x1a0>
ffffffffc0200730:	99dff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200734:	782c                	ld	a1,112(s0)
ffffffffc0200736:	00006517          	auipc	a0,0x6
ffffffffc020073a:	4a250513          	addi	a0,a0,1186 # ffffffffc0206bd8 <commands+0x1b8>
ffffffffc020073e:	98fff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200742:	7c2c                	ld	a1,120(s0)
ffffffffc0200744:	00006517          	auipc	a0,0x6
ffffffffc0200748:	4ac50513          	addi	a0,a0,1196 # ffffffffc0206bf0 <commands+0x1d0>
ffffffffc020074c:	981ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200750:	604c                	ld	a1,128(s0)
ffffffffc0200752:	00006517          	auipc	a0,0x6
ffffffffc0200756:	4b650513          	addi	a0,a0,1206 # ffffffffc0206c08 <commands+0x1e8>
ffffffffc020075a:	973ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc020075e:	644c                	ld	a1,136(s0)
ffffffffc0200760:	00006517          	auipc	a0,0x6
ffffffffc0200764:	4c050513          	addi	a0,a0,1216 # ffffffffc0206c20 <commands+0x200>
ffffffffc0200768:	965ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc020076c:	684c                	ld	a1,144(s0)
ffffffffc020076e:	00006517          	auipc	a0,0x6
ffffffffc0200772:	4ca50513          	addi	a0,a0,1226 # ffffffffc0206c38 <commands+0x218>
ffffffffc0200776:	957ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc020077a:	6c4c                	ld	a1,152(s0)
ffffffffc020077c:	00006517          	auipc	a0,0x6
ffffffffc0200780:	4d450513          	addi	a0,a0,1236 # ffffffffc0206c50 <commands+0x230>
ffffffffc0200784:	949ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200788:	704c                	ld	a1,160(s0)
ffffffffc020078a:	00006517          	auipc	a0,0x6
ffffffffc020078e:	4de50513          	addi	a0,a0,1246 # ffffffffc0206c68 <commands+0x248>
ffffffffc0200792:	93bff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200796:	744c                	ld	a1,168(s0)
ffffffffc0200798:	00006517          	auipc	a0,0x6
ffffffffc020079c:	4e850513          	addi	a0,a0,1256 # ffffffffc0206c80 <commands+0x260>
ffffffffc02007a0:	92dff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02007a4:	784c                	ld	a1,176(s0)
ffffffffc02007a6:	00006517          	auipc	a0,0x6
ffffffffc02007aa:	4f250513          	addi	a0,a0,1266 # ffffffffc0206c98 <commands+0x278>
ffffffffc02007ae:	91fff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02007b2:	7c4c                	ld	a1,184(s0)
ffffffffc02007b4:	00006517          	auipc	a0,0x6
ffffffffc02007b8:	4fc50513          	addi	a0,a0,1276 # ffffffffc0206cb0 <commands+0x290>
ffffffffc02007bc:	911ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02007c0:	606c                	ld	a1,192(s0)
ffffffffc02007c2:	00006517          	auipc	a0,0x6
ffffffffc02007c6:	50650513          	addi	a0,a0,1286 # ffffffffc0206cc8 <commands+0x2a8>
ffffffffc02007ca:	903ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02007ce:	646c                	ld	a1,200(s0)
ffffffffc02007d0:	00006517          	auipc	a0,0x6
ffffffffc02007d4:	51050513          	addi	a0,a0,1296 # ffffffffc0206ce0 <commands+0x2c0>
ffffffffc02007d8:	8f5ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02007dc:	686c                	ld	a1,208(s0)
ffffffffc02007de:	00006517          	auipc	a0,0x6
ffffffffc02007e2:	51a50513          	addi	a0,a0,1306 # ffffffffc0206cf8 <commands+0x2d8>
ffffffffc02007e6:	8e7ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02007ea:	6c6c                	ld	a1,216(s0)
ffffffffc02007ec:	00006517          	auipc	a0,0x6
ffffffffc02007f0:	52450513          	addi	a0,a0,1316 # ffffffffc0206d10 <commands+0x2f0>
ffffffffc02007f4:	8d9ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc02007f8:	706c                	ld	a1,224(s0)
ffffffffc02007fa:	00006517          	auipc	a0,0x6
ffffffffc02007fe:	52e50513          	addi	a0,a0,1326 # ffffffffc0206d28 <commands+0x308>
ffffffffc0200802:	8cbff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200806:	746c                	ld	a1,232(s0)
ffffffffc0200808:	00006517          	auipc	a0,0x6
ffffffffc020080c:	53850513          	addi	a0,a0,1336 # ffffffffc0206d40 <commands+0x320>
ffffffffc0200810:	8bdff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200814:	786c                	ld	a1,240(s0)
ffffffffc0200816:	00006517          	auipc	a0,0x6
ffffffffc020081a:	54250513          	addi	a0,a0,1346 # ffffffffc0206d58 <commands+0x338>
ffffffffc020081e:	8afff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200822:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200824:	6402                	ld	s0,0(sp)
ffffffffc0200826:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200828:	00006517          	auipc	a0,0x6
ffffffffc020082c:	54850513          	addi	a0,a0,1352 # ffffffffc0206d70 <commands+0x350>
}
ffffffffc0200830:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200832:	89bff06f          	j	ffffffffc02000cc <cprintf>

ffffffffc0200836 <print_trapframe>:
print_trapframe(struct trapframe *tf) {
ffffffffc0200836:	1141                	addi	sp,sp,-16
ffffffffc0200838:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc020083a:	85aa                	mv	a1,a0
print_trapframe(struct trapframe *tf) {
ffffffffc020083c:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc020083e:	00006517          	auipc	a0,0x6
ffffffffc0200842:	54a50513          	addi	a0,a0,1354 # ffffffffc0206d88 <commands+0x368>
print_trapframe(struct trapframe *tf) {
ffffffffc0200846:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200848:	885ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    print_regs(&tf->gpr);
ffffffffc020084c:	8522                	mv	a0,s0
ffffffffc020084e:	e1bff0ef          	jal	ra,ffffffffc0200668 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200852:	10043583          	ld	a1,256(s0)
ffffffffc0200856:	00006517          	auipc	a0,0x6
ffffffffc020085a:	54a50513          	addi	a0,a0,1354 # ffffffffc0206da0 <commands+0x380>
ffffffffc020085e:	86fff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200862:	10843583          	ld	a1,264(s0)
ffffffffc0200866:	00006517          	auipc	a0,0x6
ffffffffc020086a:	55250513          	addi	a0,a0,1362 # ffffffffc0206db8 <commands+0x398>
ffffffffc020086e:	85fff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  tval 0x%08x\n", tf->tval);
ffffffffc0200872:	11043583          	ld	a1,272(s0)
ffffffffc0200876:	00006517          	auipc	a0,0x6
ffffffffc020087a:	55a50513          	addi	a0,a0,1370 # ffffffffc0206dd0 <commands+0x3b0>
ffffffffc020087e:	84fff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200882:	11843583          	ld	a1,280(s0)
}
ffffffffc0200886:	6402                	ld	s0,0(sp)
ffffffffc0200888:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020088a:	00006517          	auipc	a0,0x6
ffffffffc020088e:	55650513          	addi	a0,a0,1366 # ffffffffc0206de0 <commands+0x3c0>
}
ffffffffc0200892:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200894:	839ff06f          	j	ffffffffc02000cc <cprintf>

ffffffffc0200898 <pgfault_handler>:
            trap_in_kernel(tf) ? 'K' : 'U',
            tf->cause == CAUSE_STORE_PAGE_FAULT ? 'W' : 'R');
}

static int
pgfault_handler(struct trapframe *tf) {
ffffffffc0200898:	1101                	addi	sp,sp,-32
ffffffffc020089a:	e426                	sd	s1,8(sp)
    extern struct mm_struct *check_mm_struct;
    if(check_mm_struct !=NULL) { //used for test check_swap
ffffffffc020089c:	000b2497          	auipc	s1,0xb2
ffffffffc02008a0:	ffc48493          	addi	s1,s1,-4 # ffffffffc02b2898 <check_mm_struct>
ffffffffc02008a4:	609c                	ld	a5,0(s1)
pgfault_handler(struct trapframe *tf) {
ffffffffc02008a6:	e822                	sd	s0,16(sp)
ffffffffc02008a8:	ec06                	sd	ra,24(sp)
ffffffffc02008aa:	842a                	mv	s0,a0
    if(check_mm_struct !=NULL) { //used for test check_swap
ffffffffc02008ac:	cbad                	beqz	a5,ffffffffc020091e <pgfault_handler+0x86>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc02008ae:	10053783          	ld	a5,256(a0)
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc02008b2:	11053583          	ld	a1,272(a0)
ffffffffc02008b6:	04b00613          	li	a2,75
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc02008ba:	1007f793          	andi	a5,a5,256
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc02008be:	c7b1                	beqz	a5,ffffffffc020090a <pgfault_handler+0x72>
ffffffffc02008c0:	11843703          	ld	a4,280(s0)
ffffffffc02008c4:	47bd                	li	a5,15
ffffffffc02008c6:	05700693          	li	a3,87
ffffffffc02008ca:	00f70463          	beq	a4,a5,ffffffffc02008d2 <pgfault_handler+0x3a>
ffffffffc02008ce:	05200693          	li	a3,82
ffffffffc02008d2:	00006517          	auipc	a0,0x6
ffffffffc02008d6:	52650513          	addi	a0,a0,1318 # ffffffffc0206df8 <commands+0x3d8>
ffffffffc02008da:	ff2ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
            print_pgfault(tf);
        }
    struct mm_struct *mm;
    if (check_mm_struct != NULL) {
ffffffffc02008de:	6088                	ld	a0,0(s1)
ffffffffc02008e0:	cd1d                	beqz	a0,ffffffffc020091e <pgfault_handler+0x86>
        assert(current == idleproc);
ffffffffc02008e2:	000b2717          	auipc	a4,0xb2
ffffffffc02008e6:	fe673703          	ld	a4,-26(a4) # ffffffffc02b28c8 <current>
ffffffffc02008ea:	000b2797          	auipc	a5,0xb2
ffffffffc02008ee:	fe67b783          	ld	a5,-26(a5) # ffffffffc02b28d0 <idleproc>
ffffffffc02008f2:	04f71663          	bne	a4,a5,ffffffffc020093e <pgfault_handler+0xa6>
            print_pgfault(tf);
            panic("unhandled page fault.\n");
        }
        mm = current->mm;
    }
    return do_pgfault(mm, tf->cause, tf->tval);
ffffffffc02008f6:	11043603          	ld	a2,272(s0)
ffffffffc02008fa:	11843583          	ld	a1,280(s0)
}
ffffffffc02008fe:	6442                	ld	s0,16(sp)
ffffffffc0200900:	60e2                	ld	ra,24(sp)
ffffffffc0200902:	64a2                	ld	s1,8(sp)
ffffffffc0200904:	6105                	addi	sp,sp,32
    return do_pgfault(mm, tf->cause, tf->tval);
ffffffffc0200906:	7ea0206f          	j	ffffffffc02030f0 <do_pgfault>
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc020090a:	11843703          	ld	a4,280(s0)
ffffffffc020090e:	47bd                	li	a5,15
ffffffffc0200910:	05500613          	li	a2,85
ffffffffc0200914:	05700693          	li	a3,87
ffffffffc0200918:	faf71be3          	bne	a4,a5,ffffffffc02008ce <pgfault_handler+0x36>
ffffffffc020091c:	bf5d                	j	ffffffffc02008d2 <pgfault_handler+0x3a>
        if (current == NULL) {
ffffffffc020091e:	000b2797          	auipc	a5,0xb2
ffffffffc0200922:	faa7b783          	ld	a5,-86(a5) # ffffffffc02b28c8 <current>
ffffffffc0200926:	cf85                	beqz	a5,ffffffffc020095e <pgfault_handler+0xc6>
    return do_pgfault(mm, tf->cause, tf->tval);
ffffffffc0200928:	11043603          	ld	a2,272(s0)
ffffffffc020092c:	11843583          	ld	a1,280(s0)
}
ffffffffc0200930:	6442                	ld	s0,16(sp)
ffffffffc0200932:	60e2                	ld	ra,24(sp)
ffffffffc0200934:	64a2                	ld	s1,8(sp)
        mm = current->mm;
ffffffffc0200936:	7788                	ld	a0,40(a5)
}
ffffffffc0200938:	6105                	addi	sp,sp,32
    return do_pgfault(mm, tf->cause, tf->tval);
ffffffffc020093a:	7b60206f          	j	ffffffffc02030f0 <do_pgfault>
        assert(current == idleproc);
ffffffffc020093e:	00006697          	auipc	a3,0x6
ffffffffc0200942:	4da68693          	addi	a3,a3,1242 # ffffffffc0206e18 <commands+0x3f8>
ffffffffc0200946:	00006617          	auipc	a2,0x6
ffffffffc020094a:	4ea60613          	addi	a2,a2,1258 # ffffffffc0206e30 <commands+0x410>
ffffffffc020094e:	06b00593          	li	a1,107
ffffffffc0200952:	00006517          	auipc	a0,0x6
ffffffffc0200956:	4f650513          	addi	a0,a0,1270 # ffffffffc0206e48 <commands+0x428>
ffffffffc020095a:	8afff0ef          	jal	ra,ffffffffc0200208 <__panic>
            print_trapframe(tf);
ffffffffc020095e:	8522                	mv	a0,s0
ffffffffc0200960:	ed7ff0ef          	jal	ra,ffffffffc0200836 <print_trapframe>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200964:	10043783          	ld	a5,256(s0)
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc0200968:	11043583          	ld	a1,272(s0)
ffffffffc020096c:	04b00613          	li	a2,75
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200970:	1007f793          	andi	a5,a5,256
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc0200974:	e399                	bnez	a5,ffffffffc020097a <pgfault_handler+0xe2>
ffffffffc0200976:	05500613          	li	a2,85
ffffffffc020097a:	11843703          	ld	a4,280(s0)
ffffffffc020097e:	47bd                	li	a5,15
ffffffffc0200980:	02f70663          	beq	a4,a5,ffffffffc02009ac <pgfault_handler+0x114>
ffffffffc0200984:	05200693          	li	a3,82
ffffffffc0200988:	00006517          	auipc	a0,0x6
ffffffffc020098c:	47050513          	addi	a0,a0,1136 # ffffffffc0206df8 <commands+0x3d8>
ffffffffc0200990:	f3cff0ef          	jal	ra,ffffffffc02000cc <cprintf>
            panic("unhandled page fault.\n");
ffffffffc0200994:	00006617          	auipc	a2,0x6
ffffffffc0200998:	4cc60613          	addi	a2,a2,1228 # ffffffffc0206e60 <commands+0x440>
ffffffffc020099c:	07200593          	li	a1,114
ffffffffc02009a0:	00006517          	auipc	a0,0x6
ffffffffc02009a4:	4a850513          	addi	a0,a0,1192 # ffffffffc0206e48 <commands+0x428>
ffffffffc02009a8:	861ff0ef          	jal	ra,ffffffffc0200208 <__panic>
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc02009ac:	05700693          	li	a3,87
ffffffffc02009b0:	bfe1                	j	ffffffffc0200988 <pgfault_handler+0xf0>

ffffffffc02009b2 <interrupt_handler>:

static volatile int in_swap_tick_event = 0;
extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc02009b2:	11853783          	ld	a5,280(a0)
ffffffffc02009b6:	472d                	li	a4,11
ffffffffc02009b8:	0786                	slli	a5,a5,0x1
ffffffffc02009ba:	8385                	srli	a5,a5,0x1
ffffffffc02009bc:	08f76363          	bltu	a4,a5,ffffffffc0200a42 <interrupt_handler+0x90>
ffffffffc02009c0:	00006717          	auipc	a4,0x6
ffffffffc02009c4:	55870713          	addi	a4,a4,1368 # ffffffffc0206f18 <commands+0x4f8>
ffffffffc02009c8:	078a                	slli	a5,a5,0x2
ffffffffc02009ca:	97ba                	add	a5,a5,a4
ffffffffc02009cc:	439c                	lw	a5,0(a5)
ffffffffc02009ce:	97ba                	add	a5,a5,a4
ffffffffc02009d0:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc02009d2:	00006517          	auipc	a0,0x6
ffffffffc02009d6:	50650513          	addi	a0,a0,1286 # ffffffffc0206ed8 <commands+0x4b8>
ffffffffc02009da:	ef2ff06f          	j	ffffffffc02000cc <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc02009de:	00006517          	auipc	a0,0x6
ffffffffc02009e2:	4da50513          	addi	a0,a0,1242 # ffffffffc0206eb8 <commands+0x498>
ffffffffc02009e6:	ee6ff06f          	j	ffffffffc02000cc <cprintf>
            cprintf("User software interrupt\n");
ffffffffc02009ea:	00006517          	auipc	a0,0x6
ffffffffc02009ee:	48e50513          	addi	a0,a0,1166 # ffffffffc0206e78 <commands+0x458>
ffffffffc02009f2:	edaff06f          	j	ffffffffc02000cc <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc02009f6:	00006517          	auipc	a0,0x6
ffffffffc02009fa:	4a250513          	addi	a0,a0,1186 # ffffffffc0206e98 <commands+0x478>
ffffffffc02009fe:	eceff06f          	j	ffffffffc02000cc <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc0200a02:	1141                	addi	sp,sp,-16
ffffffffc0200a04:	e406                	sd	ra,8(sp)
            // "All bits besides SSIP and USIP in the sip register are
            // read-only." -- privileged spec1.9.1, 4.1.4, p59
            // In fact, Call sbi_set_timer will clear STIP, or you can clear it
            // directly.
            // clear_csr(sip, SIP_STIP);
            clock_set_next_event();
ffffffffc0200a06:	bafff0ef          	jal	ra,ffffffffc02005b4 <clock_set_next_event>
            if (++ticks % TICK_NUM == 0 && current) {
ffffffffc0200a0a:	000b2697          	auipc	a3,0xb2
ffffffffc0200a0e:	e4e68693          	addi	a3,a3,-434 # ffffffffc02b2858 <ticks>
ffffffffc0200a12:	629c                	ld	a5,0(a3)
ffffffffc0200a14:	06400713          	li	a4,100
ffffffffc0200a18:	0785                	addi	a5,a5,1
ffffffffc0200a1a:	02e7f733          	remu	a4,a5,a4
ffffffffc0200a1e:	e29c                	sd	a5,0(a3)
ffffffffc0200a20:	eb01                	bnez	a4,ffffffffc0200a30 <interrupt_handler+0x7e>
ffffffffc0200a22:	000b2797          	auipc	a5,0xb2
ffffffffc0200a26:	ea67b783          	ld	a5,-346(a5) # ffffffffc02b28c8 <current>
ffffffffc0200a2a:	c399                	beqz	a5,ffffffffc0200a30 <interrupt_handler+0x7e>
                // print_ticks();
                current->need_resched = 1;
ffffffffc0200a2c:	4705                	li	a4,1
ffffffffc0200a2e:	ef98                	sd	a4,24(a5)
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200a30:	60a2                	ld	ra,8(sp)
ffffffffc0200a32:	0141                	addi	sp,sp,16
ffffffffc0200a34:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc0200a36:	00006517          	auipc	a0,0x6
ffffffffc0200a3a:	4c250513          	addi	a0,a0,1218 # ffffffffc0206ef8 <commands+0x4d8>
ffffffffc0200a3e:	e8eff06f          	j	ffffffffc02000cc <cprintf>
            print_trapframe(tf);
ffffffffc0200a42:	bbd5                	j	ffffffffc0200836 <print_trapframe>

ffffffffc0200a44 <exception_handler>:
void kernel_execve_ret(struct trapframe *tf,uintptr_t kstacktop);
void exception_handler(struct trapframe *tf) {
    int ret;
    switch (tf->cause) {
ffffffffc0200a44:	11853783          	ld	a5,280(a0)
void exception_handler(struct trapframe *tf) {
ffffffffc0200a48:	1101                	addi	sp,sp,-32
ffffffffc0200a4a:	e822                	sd	s0,16(sp)
ffffffffc0200a4c:	ec06                	sd	ra,24(sp)
ffffffffc0200a4e:	e426                	sd	s1,8(sp)
ffffffffc0200a50:	473d                	li	a4,15
ffffffffc0200a52:	842a                	mv	s0,a0
ffffffffc0200a54:	18f76563          	bltu	a4,a5,ffffffffc0200bde <exception_handler+0x19a>
ffffffffc0200a58:	00006717          	auipc	a4,0x6
ffffffffc0200a5c:	68870713          	addi	a4,a4,1672 # ffffffffc02070e0 <commands+0x6c0>
ffffffffc0200a60:	078a                	slli	a5,a5,0x2
ffffffffc0200a62:	97ba                	add	a5,a5,a4
ffffffffc0200a64:	439c                	lw	a5,0(a5)
ffffffffc0200a66:	97ba                	add	a5,a5,a4
ffffffffc0200a68:	8782                	jr	a5
            //cprintf("Environment call from U-mode\n");
            tf->epc += 4; // 增加epc寄存器的值
            syscall(); // 调用系统调用
            break;
        case CAUSE_SUPERVISOR_ECALL: // 监督模式的环境调用
            cprintf("Environment call from S-mode\n"); // 打印来自S模式的环境调用
ffffffffc0200a6a:	00006517          	auipc	a0,0x6
ffffffffc0200a6e:	5ce50513          	addi	a0,a0,1486 # ffffffffc0207038 <commands+0x618>
ffffffffc0200a72:	e5aff0ef          	jal	ra,ffffffffc02000cc <cprintf>
            tf->epc += 4; // 增加epc寄存器的值
ffffffffc0200a76:	10843783          	ld	a5,264(s0)
            break;
        default: // 默认情况
            print_trapframe(tf); // 打印trapframe
            break;
    }
}
ffffffffc0200a7a:	60e2                	ld	ra,24(sp)
ffffffffc0200a7c:	64a2                	ld	s1,8(sp)
            tf->epc += 4; // 增加epc寄存器的值
ffffffffc0200a7e:	0791                	addi	a5,a5,4
ffffffffc0200a80:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200a84:	6442                	ld	s0,16(sp)
ffffffffc0200a86:	6105                	addi	sp,sp,32
            syscall(); // 调用系统调用
ffffffffc0200a88:	7c60506f          	j	ffffffffc020624e <syscall>
            cprintf("Environment call from H-mode\n"); // 打印来自H模式的环境调用
ffffffffc0200a8c:	00006517          	auipc	a0,0x6
ffffffffc0200a90:	5cc50513          	addi	a0,a0,1484 # ffffffffc0207058 <commands+0x638>
}
ffffffffc0200a94:	6442                	ld	s0,16(sp)
ffffffffc0200a96:	60e2                	ld	ra,24(sp)
ffffffffc0200a98:	64a2                	ld	s1,8(sp)
ffffffffc0200a9a:	6105                	addi	sp,sp,32
            cprintf("Instruction access fault\n"); // 打印指令访问错误
ffffffffc0200a9c:	e30ff06f          	j	ffffffffc02000cc <cprintf>
            cprintf("Environment call from M-mode\n"); // 打印来自M模式的环境调用
ffffffffc0200aa0:	00006517          	auipc	a0,0x6
ffffffffc0200aa4:	5d850513          	addi	a0,a0,1496 # ffffffffc0207078 <commands+0x658>
ffffffffc0200aa8:	b7f5                	j	ffffffffc0200a94 <exception_handler+0x50>
            cprintf("Instruction page fault\n"); // 打印指令页错误
ffffffffc0200aaa:	00006517          	auipc	a0,0x6
ffffffffc0200aae:	5ee50513          	addi	a0,a0,1518 # ffffffffc0207098 <commands+0x678>
ffffffffc0200ab2:	b7cd                	j	ffffffffc0200a94 <exception_handler+0x50>
            cprintf("Load page fault\n"); // 打印加载页错误
ffffffffc0200ab4:	00006517          	auipc	a0,0x6
ffffffffc0200ab8:	5fc50513          	addi	a0,a0,1532 # ffffffffc02070b0 <commands+0x690>
ffffffffc0200abc:	e10ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) { // 如果处理页错误失败
ffffffffc0200ac0:	8522                	mv	a0,s0
ffffffffc0200ac2:	dd7ff0ef          	jal	ra,ffffffffc0200898 <pgfault_handler>
ffffffffc0200ac6:	84aa                	mv	s1,a0
ffffffffc0200ac8:	12051d63          	bnez	a0,ffffffffc0200c02 <exception_handler+0x1be>
}
ffffffffc0200acc:	60e2                	ld	ra,24(sp)
ffffffffc0200ace:	6442                	ld	s0,16(sp)
ffffffffc0200ad0:	64a2                	ld	s1,8(sp)
ffffffffc0200ad2:	6105                	addi	sp,sp,32
ffffffffc0200ad4:	8082                	ret
            cprintf("Store/AMO page fault\n"); // 打印存储/AMO页错误
ffffffffc0200ad6:	00006517          	auipc	a0,0x6
ffffffffc0200ada:	5f250513          	addi	a0,a0,1522 # ffffffffc02070c8 <commands+0x6a8>
ffffffffc0200ade:	deeff0ef          	jal	ra,ffffffffc02000cc <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) { // 如果处理页错误失败
ffffffffc0200ae2:	8522                	mv	a0,s0
ffffffffc0200ae4:	db5ff0ef          	jal	ra,ffffffffc0200898 <pgfault_handler>
ffffffffc0200ae8:	84aa                	mv	s1,a0
ffffffffc0200aea:	d16d                	beqz	a0,ffffffffc0200acc <exception_handler+0x88>
                print_trapframe(tf); // 打印trapframe
ffffffffc0200aec:	8522                	mv	a0,s0
ffffffffc0200aee:	d49ff0ef          	jal	ra,ffffffffc0200836 <print_trapframe>
                panic("handle pgfault failed. %e\n", ret); // 打印处理页错误失败信息并panic
ffffffffc0200af2:	86a6                	mv	a3,s1
ffffffffc0200af4:	00006617          	auipc	a2,0x6
ffffffffc0200af8:	4f460613          	addi	a2,a2,1268 # ffffffffc0206fe8 <commands+0x5c8>
ffffffffc0200afc:	0f800593          	li	a1,248
ffffffffc0200b00:	00006517          	auipc	a0,0x6
ffffffffc0200b04:	34850513          	addi	a0,a0,840 # ffffffffc0206e48 <commands+0x428>
ffffffffc0200b08:	f00ff0ef          	jal	ra,ffffffffc0200208 <__panic>
            cprintf("Instruction address misaligned\n"); // 打印未对齐的指令地址
ffffffffc0200b0c:	00006517          	auipc	a0,0x6
ffffffffc0200b10:	43c50513          	addi	a0,a0,1084 # ffffffffc0206f48 <commands+0x528>
ffffffffc0200b14:	b741                	j	ffffffffc0200a94 <exception_handler+0x50>
            cprintf("Instruction access fault\n"); // 打印指令访问错误
ffffffffc0200b16:	00006517          	auipc	a0,0x6
ffffffffc0200b1a:	45250513          	addi	a0,a0,1106 # ffffffffc0206f68 <commands+0x548>
ffffffffc0200b1e:	bf9d                	j	ffffffffc0200a94 <exception_handler+0x50>
            cprintf("Illegal instruction\n"); // 打印非法指令
ffffffffc0200b20:	00006517          	auipc	a0,0x6
ffffffffc0200b24:	46850513          	addi	a0,a0,1128 # ffffffffc0206f88 <commands+0x568>
ffffffffc0200b28:	b7b5                	j	ffffffffc0200a94 <exception_handler+0x50>
            cprintf("Breakpoint\n"); // 打印断点
ffffffffc0200b2a:	00006517          	auipc	a0,0x6
ffffffffc0200b2e:	47650513          	addi	a0,a0,1142 # ffffffffc0206fa0 <commands+0x580>
ffffffffc0200b32:	d9aff0ef          	jal	ra,ffffffffc02000cc <cprintf>
            if(tf->gpr.a7 == 10){ // 如果a7寄存器的值为10
ffffffffc0200b36:	6458                	ld	a4,136(s0)
ffffffffc0200b38:	47a9                	li	a5,10
ffffffffc0200b3a:	f8f719e3          	bne	a4,a5,ffffffffc0200acc <exception_handler+0x88>
                tf->epc += 4; // 增加epc寄存器的值
ffffffffc0200b3e:	10843783          	ld	a5,264(s0)
ffffffffc0200b42:	0791                	addi	a5,a5,4
ffffffffc0200b44:	10f43423          	sd	a5,264(s0)
                syscall(); // 调用系统调用
ffffffffc0200b48:	706050ef          	jal	ra,ffffffffc020624e <syscall>
                kernel_execve_ret(tf,current->kstack+KSTACKSIZE); // 返回到内核执行
ffffffffc0200b4c:	000b2797          	auipc	a5,0xb2
ffffffffc0200b50:	d7c7b783          	ld	a5,-644(a5) # ffffffffc02b28c8 <current>
ffffffffc0200b54:	6b9c                	ld	a5,16(a5)
ffffffffc0200b56:	8522                	mv	a0,s0
}
ffffffffc0200b58:	6442                	ld	s0,16(sp)
ffffffffc0200b5a:	60e2                	ld	ra,24(sp)
ffffffffc0200b5c:	64a2                	ld	s1,8(sp)
                kernel_execve_ret(tf,current->kstack+KSTACKSIZE); // 返回到内核执行
ffffffffc0200b5e:	6589                	lui	a1,0x2
ffffffffc0200b60:	95be                	add	a1,a1,a5
}
ffffffffc0200b62:	6105                	addi	sp,sp,32
                kernel_execve_ret(tf,current->kstack+KSTACKSIZE); // 返回到内核执行
ffffffffc0200b64:	ac19                	j	ffffffffc0200d7a <kernel_execve_ret>
            cprintf("Load address misaligned\n"); // 打印加载地址未对齐
ffffffffc0200b66:	00006517          	auipc	a0,0x6
ffffffffc0200b6a:	44a50513          	addi	a0,a0,1098 # ffffffffc0206fb0 <commands+0x590>
ffffffffc0200b6e:	b71d                	j	ffffffffc0200a94 <exception_handler+0x50>
            cprintf("Load access fault\n"); // 打印加载访问错误
ffffffffc0200b70:	00006517          	auipc	a0,0x6
ffffffffc0200b74:	46050513          	addi	a0,a0,1120 # ffffffffc0206fd0 <commands+0x5b0>
ffffffffc0200b78:	d54ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) { // 如果处理页错误失败
ffffffffc0200b7c:	8522                	mv	a0,s0
ffffffffc0200b7e:	d1bff0ef          	jal	ra,ffffffffc0200898 <pgfault_handler>
ffffffffc0200b82:	84aa                	mv	s1,a0
ffffffffc0200b84:	d521                	beqz	a0,ffffffffc0200acc <exception_handler+0x88>
                print_trapframe(tf); // 打印trapframe
ffffffffc0200b86:	8522                	mv	a0,s0
ffffffffc0200b88:	cafff0ef          	jal	ra,ffffffffc0200836 <print_trapframe>
                panic("handle pgfault failed. %e\n", ret); // 打印处理页错误失败信息并panic
ffffffffc0200b8c:	86a6                	mv	a3,s1
ffffffffc0200b8e:	00006617          	auipc	a2,0x6
ffffffffc0200b92:	45a60613          	addi	a2,a2,1114 # ffffffffc0206fe8 <commands+0x5c8>
ffffffffc0200b96:	0cd00593          	li	a1,205
ffffffffc0200b9a:	00006517          	auipc	a0,0x6
ffffffffc0200b9e:	2ae50513          	addi	a0,a0,686 # ffffffffc0206e48 <commands+0x428>
ffffffffc0200ba2:	e66ff0ef          	jal	ra,ffffffffc0200208 <__panic>
            cprintf("Store/AMO access fault\n"); // 打印存储/AMO访问错误
ffffffffc0200ba6:	00006517          	auipc	a0,0x6
ffffffffc0200baa:	47a50513          	addi	a0,a0,1146 # ffffffffc0207020 <commands+0x600>
ffffffffc0200bae:	d1eff0ef          	jal	ra,ffffffffc02000cc <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) { // 如果处理页错误失败
ffffffffc0200bb2:	8522                	mv	a0,s0
ffffffffc0200bb4:	ce5ff0ef          	jal	ra,ffffffffc0200898 <pgfault_handler>
ffffffffc0200bb8:	84aa                	mv	s1,a0
ffffffffc0200bba:	f00509e3          	beqz	a0,ffffffffc0200acc <exception_handler+0x88>
                print_trapframe(tf); // 打印trapframe
ffffffffc0200bbe:	8522                	mv	a0,s0
ffffffffc0200bc0:	c77ff0ef          	jal	ra,ffffffffc0200836 <print_trapframe>
                panic("handle pgfault failed. %e\n", ret); // 打印处理页错误失败信息并panic
ffffffffc0200bc4:	86a6                	mv	a3,s1
ffffffffc0200bc6:	00006617          	auipc	a2,0x6
ffffffffc0200bca:	42260613          	addi	a2,a2,1058 # ffffffffc0206fe8 <commands+0x5c8>
ffffffffc0200bce:	0d700593          	li	a1,215
ffffffffc0200bd2:	00006517          	auipc	a0,0x6
ffffffffc0200bd6:	27650513          	addi	a0,a0,630 # ffffffffc0206e48 <commands+0x428>
ffffffffc0200bda:	e2eff0ef          	jal	ra,ffffffffc0200208 <__panic>
            print_trapframe(tf); // 打印trapframe
ffffffffc0200bde:	8522                	mv	a0,s0
}
ffffffffc0200be0:	6442                	ld	s0,16(sp)
ffffffffc0200be2:	60e2                	ld	ra,24(sp)
ffffffffc0200be4:	64a2                	ld	s1,8(sp)
ffffffffc0200be6:	6105                	addi	sp,sp,32
            print_trapframe(tf); // 打印trapframe
ffffffffc0200be8:	b1b9                	j	ffffffffc0200836 <print_trapframe>
            panic("AMO address misaligned\n"); // 打印AMO地址未对齐并panic
ffffffffc0200bea:	00006617          	auipc	a2,0x6
ffffffffc0200bee:	41e60613          	addi	a2,a2,1054 # ffffffffc0207008 <commands+0x5e8>
ffffffffc0200bf2:	0d100593          	li	a1,209
ffffffffc0200bf6:	00006517          	auipc	a0,0x6
ffffffffc0200bfa:	25250513          	addi	a0,a0,594 # ffffffffc0206e48 <commands+0x428>
ffffffffc0200bfe:	e0aff0ef          	jal	ra,ffffffffc0200208 <__panic>
                print_trapframe(tf); // 打印trapframe
ffffffffc0200c02:	8522                	mv	a0,s0
ffffffffc0200c04:	c33ff0ef          	jal	ra,ffffffffc0200836 <print_trapframe>
                panic("handle pgfault failed. %e\n", ret); // 打印处理页错误失败信息并panic
ffffffffc0200c08:	86a6                	mv	a3,s1
ffffffffc0200c0a:	00006617          	auipc	a2,0x6
ffffffffc0200c0e:	3de60613          	addi	a2,a2,990 # ffffffffc0206fe8 <commands+0x5c8>
ffffffffc0200c12:	0f100593          	li	a1,241
ffffffffc0200c16:	00006517          	auipc	a0,0x6
ffffffffc0200c1a:	23250513          	addi	a0,a0,562 # ffffffffc0206e48 <commands+0x428>
ffffffffc0200c1e:	deaff0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0200c22 <trap>:
 * trap - 处理或分发异常/中断。如果trap()返回，
 * kern/trap/trapentry.S中的代码将恢复保存在trapframe中的旧CPU状态，
 * 然后使用iret指令从异常中返回。
 * */
void
trap(struct trapframe *tf) {
ffffffffc0200c22:	1101                	addi	sp,sp,-32
ffffffffc0200c24:	e822                	sd	s0,16(sp)
    // 根据发生的trap类型进行分发
    // cputs("some trap");
    if (current == NULL) { // 如果当前没有进程
ffffffffc0200c26:	000b2417          	auipc	s0,0xb2
ffffffffc0200c2a:	ca240413          	addi	s0,s0,-862 # ffffffffc02b28c8 <current>
ffffffffc0200c2e:	6018                	ld	a4,0(s0)
trap(struct trapframe *tf) {
ffffffffc0200c30:	ec06                	sd	ra,24(sp)
ffffffffc0200c32:	e426                	sd	s1,8(sp)
ffffffffc0200c34:	e04a                	sd	s2,0(sp)
    if ((intptr_t)tf->cause < 0) { // 如果tf->cause为负数，表示是中断
ffffffffc0200c36:	11853683          	ld	a3,280(a0)
    if (current == NULL) { // 如果当前没有进程
ffffffffc0200c3a:	cf1d                	beqz	a4,ffffffffc0200c78 <trap+0x56>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200c3c:	10053483          	ld	s1,256(a0)
        trap_dispatch(tf); // 调用trap_dispatch函数处理trap
    } else { // 如果当前有进程
        struct trapframe *otf = current->tf; // 保存当前进程的trapframe
ffffffffc0200c40:	0a073903          	ld	s2,160(a4)
        current->tf = tf; // 将当前trapframe设置为传入的trapframe
ffffffffc0200c44:	f348                	sd	a0,160(a4)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200c46:	1004f493          	andi	s1,s1,256
    if ((intptr_t)tf->cause < 0) { // 如果tf->cause为负数，表示是中断
ffffffffc0200c4a:	0206c463          	bltz	a3,ffffffffc0200c72 <trap+0x50>
        exception_handler(tf); // 调用异常处理函数
ffffffffc0200c4e:	df7ff0ef          	jal	ra,ffffffffc0200a44 <exception_handler>

        bool in_kernel = trap_in_kernel(tf); // 判断trap是否发生在内核中

        trap_dispatch(tf); // 调用trap_dispatch函数处理trap

        current->tf = otf; // 恢复原来的trapframe
ffffffffc0200c52:	601c                	ld	a5,0(s0)
ffffffffc0200c54:	0b27b023          	sd	s2,160(a5)
        if (!in_kernel) { // 如果trap不是发生在内核中
ffffffffc0200c58:	e499                	bnez	s1,ffffffffc0200c66 <trap+0x44>
            if (current->flags & PF_EXITING) { // 如果当前进程正在退出
ffffffffc0200c5a:	0b07a703          	lw	a4,176(a5)
ffffffffc0200c5e:	8b05                	andi	a4,a4,1
ffffffffc0200c60:	e329                	bnez	a4,ffffffffc0200ca2 <trap+0x80>
                do_exit(-E_KILLED); // 调用do_exit函数退出进程
            }
            if (current->need_resched) { // 如果当前进程需要重新调度
ffffffffc0200c62:	6f9c                	ld	a5,24(a5)
ffffffffc0200c64:	eb85                	bnez	a5,ffffffffc0200c94 <trap+0x72>
                schedule(); // 调用schedule函数进行调度
            }
        }
    }
}
ffffffffc0200c66:	60e2                	ld	ra,24(sp)
ffffffffc0200c68:	6442                	ld	s0,16(sp)
ffffffffc0200c6a:	64a2                	ld	s1,8(sp)
ffffffffc0200c6c:	6902                	ld	s2,0(sp)
ffffffffc0200c6e:	6105                	addi	sp,sp,32
ffffffffc0200c70:	8082                	ret
        interrupt_handler(tf); // 调用中断处理函数
ffffffffc0200c72:	d41ff0ef          	jal	ra,ffffffffc02009b2 <interrupt_handler>
ffffffffc0200c76:	bff1                	j	ffffffffc0200c52 <trap+0x30>
    if ((intptr_t)tf->cause < 0) { // 如果tf->cause为负数，表示是中断
ffffffffc0200c78:	0006c863          	bltz	a3,ffffffffc0200c88 <trap+0x66>
}
ffffffffc0200c7c:	6442                	ld	s0,16(sp)
ffffffffc0200c7e:	60e2                	ld	ra,24(sp)
ffffffffc0200c80:	64a2                	ld	s1,8(sp)
ffffffffc0200c82:	6902                	ld	s2,0(sp)
ffffffffc0200c84:	6105                	addi	sp,sp,32
        exception_handler(tf); // 调用异常处理函数
ffffffffc0200c86:	bb7d                	j	ffffffffc0200a44 <exception_handler>
}
ffffffffc0200c88:	6442                	ld	s0,16(sp)
ffffffffc0200c8a:	60e2                	ld	ra,24(sp)
ffffffffc0200c8c:	64a2                	ld	s1,8(sp)
ffffffffc0200c8e:	6902                	ld	s2,0(sp)
ffffffffc0200c90:	6105                	addi	sp,sp,32
        interrupt_handler(tf); // 调用中断处理函数
ffffffffc0200c92:	b305                	j	ffffffffc02009b2 <interrupt_handler>
}
ffffffffc0200c94:	6442                	ld	s0,16(sp)
ffffffffc0200c96:	60e2                	ld	ra,24(sp)
ffffffffc0200c98:	64a2                	ld	s1,8(sp)
ffffffffc0200c9a:	6902                	ld	s2,0(sp)
ffffffffc0200c9c:	6105                	addi	sp,sp,32
                schedule(); // 调用schedule函数进行调度
ffffffffc0200c9e:	4c40506f          	j	ffffffffc0206162 <schedule>
                do_exit(-E_KILLED); // 调用do_exit函数退出进程
ffffffffc0200ca2:	555d                	li	a0,-9
ffffffffc0200ca4:	073040ef          	jal	ra,ffffffffc0205516 <do_exit>
            if (current->need_resched) { // 如果当前进程需要重新调度
ffffffffc0200ca8:	601c                	ld	a5,0(s0)
ffffffffc0200caa:	bf65                	j	ffffffffc0200c62 <trap+0x40>

ffffffffc0200cac <__alltraps>:
    LOAD x2, 2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200cac:	14011173          	csrrw	sp,sscratch,sp
ffffffffc0200cb0:	00011463          	bnez	sp,ffffffffc0200cb8 <__alltraps+0xc>
ffffffffc0200cb4:	14002173          	csrr	sp,sscratch
ffffffffc0200cb8:	712d                	addi	sp,sp,-288
ffffffffc0200cba:	e002                	sd	zero,0(sp)
ffffffffc0200cbc:	e406                	sd	ra,8(sp)
ffffffffc0200cbe:	ec0e                	sd	gp,24(sp)
ffffffffc0200cc0:	f012                	sd	tp,32(sp)
ffffffffc0200cc2:	f416                	sd	t0,40(sp)
ffffffffc0200cc4:	f81a                	sd	t1,48(sp)
ffffffffc0200cc6:	fc1e                	sd	t2,56(sp)
ffffffffc0200cc8:	e0a2                	sd	s0,64(sp)
ffffffffc0200cca:	e4a6                	sd	s1,72(sp)
ffffffffc0200ccc:	e8aa                	sd	a0,80(sp)
ffffffffc0200cce:	ecae                	sd	a1,88(sp)
ffffffffc0200cd0:	f0b2                	sd	a2,96(sp)
ffffffffc0200cd2:	f4b6                	sd	a3,104(sp)
ffffffffc0200cd4:	f8ba                	sd	a4,112(sp)
ffffffffc0200cd6:	fcbe                	sd	a5,120(sp)
ffffffffc0200cd8:	e142                	sd	a6,128(sp)
ffffffffc0200cda:	e546                	sd	a7,136(sp)
ffffffffc0200cdc:	e94a                	sd	s2,144(sp)
ffffffffc0200cde:	ed4e                	sd	s3,152(sp)
ffffffffc0200ce0:	f152                	sd	s4,160(sp)
ffffffffc0200ce2:	f556                	sd	s5,168(sp)
ffffffffc0200ce4:	f95a                	sd	s6,176(sp)
ffffffffc0200ce6:	fd5e                	sd	s7,184(sp)
ffffffffc0200ce8:	e1e2                	sd	s8,192(sp)
ffffffffc0200cea:	e5e6                	sd	s9,200(sp)
ffffffffc0200cec:	e9ea                	sd	s10,208(sp)
ffffffffc0200cee:	edee                	sd	s11,216(sp)
ffffffffc0200cf0:	f1f2                	sd	t3,224(sp)
ffffffffc0200cf2:	f5f6                	sd	t4,232(sp)
ffffffffc0200cf4:	f9fa                	sd	t5,240(sp)
ffffffffc0200cf6:	fdfe                	sd	t6,248(sp)
ffffffffc0200cf8:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200cfc:	100024f3          	csrr	s1,sstatus
ffffffffc0200d00:	14102973          	csrr	s2,sepc
ffffffffc0200d04:	143029f3          	csrr	s3,stval
ffffffffc0200d08:	14202a73          	csrr	s4,scause
ffffffffc0200d0c:	e822                	sd	s0,16(sp)
ffffffffc0200d0e:	e226                	sd	s1,256(sp)
ffffffffc0200d10:	e64a                	sd	s2,264(sp)
ffffffffc0200d12:	ea4e                	sd	s3,272(sp)
ffffffffc0200d14:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200d16:	850a                	mv	a0,sp
    jal trap
ffffffffc0200d18:	f0bff0ef          	jal	ra,ffffffffc0200c22 <trap>

ffffffffc0200d1c <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200d1c:	6492                	ld	s1,256(sp)
ffffffffc0200d1e:	6932                	ld	s2,264(sp)
ffffffffc0200d20:	1004f413          	andi	s0,s1,256
ffffffffc0200d24:	e401                	bnez	s0,ffffffffc0200d2c <__trapret+0x10>
ffffffffc0200d26:	1200                	addi	s0,sp,288
ffffffffc0200d28:	14041073          	csrw	sscratch,s0
ffffffffc0200d2c:	10049073          	csrw	sstatus,s1
ffffffffc0200d30:	14191073          	csrw	sepc,s2
ffffffffc0200d34:	60a2                	ld	ra,8(sp)
ffffffffc0200d36:	61e2                	ld	gp,24(sp)
ffffffffc0200d38:	7202                	ld	tp,32(sp)
ffffffffc0200d3a:	72a2                	ld	t0,40(sp)
ffffffffc0200d3c:	7342                	ld	t1,48(sp)
ffffffffc0200d3e:	73e2                	ld	t2,56(sp)
ffffffffc0200d40:	6406                	ld	s0,64(sp)
ffffffffc0200d42:	64a6                	ld	s1,72(sp)
ffffffffc0200d44:	6546                	ld	a0,80(sp)
ffffffffc0200d46:	65e6                	ld	a1,88(sp)
ffffffffc0200d48:	7606                	ld	a2,96(sp)
ffffffffc0200d4a:	76a6                	ld	a3,104(sp)
ffffffffc0200d4c:	7746                	ld	a4,112(sp)
ffffffffc0200d4e:	77e6                	ld	a5,120(sp)
ffffffffc0200d50:	680a                	ld	a6,128(sp)
ffffffffc0200d52:	68aa                	ld	a7,136(sp)
ffffffffc0200d54:	694a                	ld	s2,144(sp)
ffffffffc0200d56:	69ea                	ld	s3,152(sp)
ffffffffc0200d58:	7a0a                	ld	s4,160(sp)
ffffffffc0200d5a:	7aaa                	ld	s5,168(sp)
ffffffffc0200d5c:	7b4a                	ld	s6,176(sp)
ffffffffc0200d5e:	7bea                	ld	s7,184(sp)
ffffffffc0200d60:	6c0e                	ld	s8,192(sp)
ffffffffc0200d62:	6cae                	ld	s9,200(sp)
ffffffffc0200d64:	6d4e                	ld	s10,208(sp)
ffffffffc0200d66:	6dee                	ld	s11,216(sp)
ffffffffc0200d68:	7e0e                	ld	t3,224(sp)
ffffffffc0200d6a:	7eae                	ld	t4,232(sp)
ffffffffc0200d6c:	7f4e                	ld	t5,240(sp)
ffffffffc0200d6e:	7fee                	ld	t6,248(sp)
ffffffffc0200d70:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200d72:	10200073          	sret

ffffffffc0200d76 <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200d76:	812a                	mv	sp,a0
    j __trapret
ffffffffc0200d78:	b755                	j	ffffffffc0200d1c <__trapret>

ffffffffc0200d7a <kernel_execve_ret>:

    .global kernel_execve_ret
kernel_execve_ret:
    // adjust sp to beneath kstacktop of current process
    addi a1, a1, -36*REGBYTES
ffffffffc0200d7a:	ee058593          	addi	a1,a1,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x7cd8>

    // copy from previous trapframe to new trapframe
    LOAD s1, 35*REGBYTES(a0)
ffffffffc0200d7e:	11853483          	ld	s1,280(a0)
    STORE s1, 35*REGBYTES(a1)
ffffffffc0200d82:	1095bc23          	sd	s1,280(a1)
    LOAD s1, 34*REGBYTES(a0)
ffffffffc0200d86:	11053483          	ld	s1,272(a0)
    STORE s1, 34*REGBYTES(a1)
ffffffffc0200d8a:	1095b823          	sd	s1,272(a1)
    LOAD s1, 33*REGBYTES(a0)
ffffffffc0200d8e:	10853483          	ld	s1,264(a0)
    STORE s1, 33*REGBYTES(a1)
ffffffffc0200d92:	1095b423          	sd	s1,264(a1)
    LOAD s1, 32*REGBYTES(a0)
ffffffffc0200d96:	10053483          	ld	s1,256(a0)
    STORE s1, 32*REGBYTES(a1)
ffffffffc0200d9a:	1095b023          	sd	s1,256(a1)
    LOAD s1, 31*REGBYTES(a0)
ffffffffc0200d9e:	7d64                	ld	s1,248(a0)
    STORE s1, 31*REGBYTES(a1)
ffffffffc0200da0:	fde4                	sd	s1,248(a1)
    LOAD s1, 30*REGBYTES(a0)
ffffffffc0200da2:	7964                	ld	s1,240(a0)
    STORE s1, 30*REGBYTES(a1)
ffffffffc0200da4:	f9e4                	sd	s1,240(a1)
    LOAD s1, 29*REGBYTES(a0)
ffffffffc0200da6:	7564                	ld	s1,232(a0)
    STORE s1, 29*REGBYTES(a1)
ffffffffc0200da8:	f5e4                	sd	s1,232(a1)
    LOAD s1, 28*REGBYTES(a0)
ffffffffc0200daa:	7164                	ld	s1,224(a0)
    STORE s1, 28*REGBYTES(a1)
ffffffffc0200dac:	f1e4                	sd	s1,224(a1)
    LOAD s1, 27*REGBYTES(a0)
ffffffffc0200dae:	6d64                	ld	s1,216(a0)
    STORE s1, 27*REGBYTES(a1)
ffffffffc0200db0:	ede4                	sd	s1,216(a1)
    LOAD s1, 26*REGBYTES(a0)
ffffffffc0200db2:	6964                	ld	s1,208(a0)
    STORE s1, 26*REGBYTES(a1)
ffffffffc0200db4:	e9e4                	sd	s1,208(a1)
    LOAD s1, 25*REGBYTES(a0)
ffffffffc0200db6:	6564                	ld	s1,200(a0)
    STORE s1, 25*REGBYTES(a1)
ffffffffc0200db8:	e5e4                	sd	s1,200(a1)
    LOAD s1, 24*REGBYTES(a0)
ffffffffc0200dba:	6164                	ld	s1,192(a0)
    STORE s1, 24*REGBYTES(a1)
ffffffffc0200dbc:	e1e4                	sd	s1,192(a1)
    LOAD s1, 23*REGBYTES(a0)
ffffffffc0200dbe:	7d44                	ld	s1,184(a0)
    STORE s1, 23*REGBYTES(a1)
ffffffffc0200dc0:	fdc4                	sd	s1,184(a1)
    LOAD s1, 22*REGBYTES(a0)
ffffffffc0200dc2:	7944                	ld	s1,176(a0)
    STORE s1, 22*REGBYTES(a1)
ffffffffc0200dc4:	f9c4                	sd	s1,176(a1)
    LOAD s1, 21*REGBYTES(a0)
ffffffffc0200dc6:	7544                	ld	s1,168(a0)
    STORE s1, 21*REGBYTES(a1)
ffffffffc0200dc8:	f5c4                	sd	s1,168(a1)
    LOAD s1, 20*REGBYTES(a0)
ffffffffc0200dca:	7144                	ld	s1,160(a0)
    STORE s1, 20*REGBYTES(a1)
ffffffffc0200dcc:	f1c4                	sd	s1,160(a1)
    LOAD s1, 19*REGBYTES(a0)
ffffffffc0200dce:	6d44                	ld	s1,152(a0)
    STORE s1, 19*REGBYTES(a1)
ffffffffc0200dd0:	edc4                	sd	s1,152(a1)
    LOAD s1, 18*REGBYTES(a0)
ffffffffc0200dd2:	6944                	ld	s1,144(a0)
    STORE s1, 18*REGBYTES(a1)
ffffffffc0200dd4:	e9c4                	sd	s1,144(a1)
    LOAD s1, 17*REGBYTES(a0)
ffffffffc0200dd6:	6544                	ld	s1,136(a0)
    STORE s1, 17*REGBYTES(a1)
ffffffffc0200dd8:	e5c4                	sd	s1,136(a1)
    LOAD s1, 16*REGBYTES(a0)
ffffffffc0200dda:	6144                	ld	s1,128(a0)
    STORE s1, 16*REGBYTES(a1)
ffffffffc0200ddc:	e1c4                	sd	s1,128(a1)
    LOAD s1, 15*REGBYTES(a0)
ffffffffc0200dde:	7d24                	ld	s1,120(a0)
    STORE s1, 15*REGBYTES(a1)
ffffffffc0200de0:	fda4                	sd	s1,120(a1)
    LOAD s1, 14*REGBYTES(a0)
ffffffffc0200de2:	7924                	ld	s1,112(a0)
    STORE s1, 14*REGBYTES(a1)
ffffffffc0200de4:	f9a4                	sd	s1,112(a1)
    LOAD s1, 13*REGBYTES(a0)
ffffffffc0200de6:	7524                	ld	s1,104(a0)
    STORE s1, 13*REGBYTES(a1)
ffffffffc0200de8:	f5a4                	sd	s1,104(a1)
    LOAD s1, 12*REGBYTES(a0)
ffffffffc0200dea:	7124                	ld	s1,96(a0)
    STORE s1, 12*REGBYTES(a1)
ffffffffc0200dec:	f1a4                	sd	s1,96(a1)
    LOAD s1, 11*REGBYTES(a0)
ffffffffc0200dee:	6d24                	ld	s1,88(a0)
    STORE s1, 11*REGBYTES(a1)
ffffffffc0200df0:	eda4                	sd	s1,88(a1)
    LOAD s1, 10*REGBYTES(a0)
ffffffffc0200df2:	6924                	ld	s1,80(a0)
    STORE s1, 10*REGBYTES(a1)
ffffffffc0200df4:	e9a4                	sd	s1,80(a1)
    LOAD s1, 9*REGBYTES(a0)
ffffffffc0200df6:	6524                	ld	s1,72(a0)
    STORE s1, 9*REGBYTES(a1)
ffffffffc0200df8:	e5a4                	sd	s1,72(a1)
    LOAD s1, 8*REGBYTES(a0)
ffffffffc0200dfa:	6124                	ld	s1,64(a0)
    STORE s1, 8*REGBYTES(a1)
ffffffffc0200dfc:	e1a4                	sd	s1,64(a1)
    LOAD s1, 7*REGBYTES(a0)
ffffffffc0200dfe:	7d04                	ld	s1,56(a0)
    STORE s1, 7*REGBYTES(a1)
ffffffffc0200e00:	fd84                	sd	s1,56(a1)
    LOAD s1, 6*REGBYTES(a0)
ffffffffc0200e02:	7904                	ld	s1,48(a0)
    STORE s1, 6*REGBYTES(a1)
ffffffffc0200e04:	f984                	sd	s1,48(a1)
    LOAD s1, 5*REGBYTES(a0)
ffffffffc0200e06:	7504                	ld	s1,40(a0)
    STORE s1, 5*REGBYTES(a1)
ffffffffc0200e08:	f584                	sd	s1,40(a1)
    LOAD s1, 4*REGBYTES(a0)
ffffffffc0200e0a:	7104                	ld	s1,32(a0)
    STORE s1, 4*REGBYTES(a1)
ffffffffc0200e0c:	f184                	sd	s1,32(a1)
    LOAD s1, 3*REGBYTES(a0)
ffffffffc0200e0e:	6d04                	ld	s1,24(a0)
    STORE s1, 3*REGBYTES(a1)
ffffffffc0200e10:	ed84                	sd	s1,24(a1)
    LOAD s1, 2*REGBYTES(a0)
ffffffffc0200e12:	6904                	ld	s1,16(a0)
    STORE s1, 2*REGBYTES(a1)
ffffffffc0200e14:	e984                	sd	s1,16(a1)
    LOAD s1, 1*REGBYTES(a0)
ffffffffc0200e16:	6504                	ld	s1,8(a0)
    STORE s1, 1*REGBYTES(a1)
ffffffffc0200e18:	e584                	sd	s1,8(a1)
    LOAD s1, 0*REGBYTES(a0)
ffffffffc0200e1a:	6104                	ld	s1,0(a0)
    STORE s1, 0*REGBYTES(a1)
ffffffffc0200e1c:	e184                	sd	s1,0(a1)

    // acutually adjust sp
    move sp, a1
ffffffffc0200e1e:	812e                	mv	sp,a1
ffffffffc0200e20:	bdf5                	j	ffffffffc0200d1c <__trapret>

ffffffffc0200e22 <cow_copy_range>:
        }
    }
    return 0;
}

int cow_copy_range(pde_t *to, pde_t *from, uintptr_t start, uintptr_t end) {
ffffffffc0200e22:	711d                	addi	sp,sp,-96
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0200e24:	00d667b3          	or	a5,a2,a3
int cow_copy_range(pde_t *to, pde_t *from, uintptr_t start, uintptr_t end) {
ffffffffc0200e28:	ec86                	sd	ra,88(sp)
ffffffffc0200e2a:	e8a2                	sd	s0,80(sp)
ffffffffc0200e2c:	e4a6                	sd	s1,72(sp)
ffffffffc0200e2e:	e0ca                	sd	s2,64(sp)
ffffffffc0200e30:	fc4e                	sd	s3,56(sp)
ffffffffc0200e32:	f852                	sd	s4,48(sp)
ffffffffc0200e34:	f456                	sd	s5,40(sp)
ffffffffc0200e36:	f05a                	sd	s6,32(sp)
ffffffffc0200e38:	ec5e                	sd	s7,24(sp)
ffffffffc0200e3a:	e862                	sd	s8,16(sp)
ffffffffc0200e3c:	e466                	sd	s9,8(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0200e3e:	17d2                	slli	a5,a5,0x34
ffffffffc0200e40:	12079663          	bnez	a5,ffffffffc0200f6c <cow_copy_range+0x14a>
    assert(USER_ACCESS(start, end));
ffffffffc0200e44:	002007b7          	lui	a5,0x200
ffffffffc0200e48:	8432                	mv	s0,a2
ffffffffc0200e4a:	10f66163          	bltu	a2,a5,ffffffffc0200f4c <cow_copy_range+0x12a>
ffffffffc0200e4e:	84b6                	mv	s1,a3
ffffffffc0200e50:	0ed67e63          	bgeu	a2,a3,ffffffffc0200f4c <cow_copy_range+0x12a>
ffffffffc0200e54:	4785                	li	a5,1
ffffffffc0200e56:	07fe                	slli	a5,a5,0x1f
ffffffffc0200e58:	0ed7ea63          	bltu	a5,a3,ffffffffc0200f4c <cow_copy_range+0x12a>
ffffffffc0200e5c:	8a2a                	mv	s4,a0
ffffffffc0200e5e:	892e                	mv	s2,a1
            assert(page != NULL);
            int ret = 0;
            ret = page_insert(to, page, start, perm);
            assert(ret == 0);
        }
        start += PGSIZE;
ffffffffc0200e60:	6985                	lui	s3,0x1
    return page2ppn(page) << PGSHIFT;
}

static inline struct Page *
pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0200e62:	000b2b97          	auipc	s7,0xb2
ffffffffc0200e66:	a16b8b93          	addi	s7,s7,-1514 # ffffffffc02b2878 <npage>
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0200e6a:	000b2b17          	auipc	s6,0xb2
ffffffffc0200e6e:	a16b0b13          	addi	s6,s6,-1514 # ffffffffc02b2880 <pages>
ffffffffc0200e72:	00008a97          	auipc	s5,0x8
ffffffffc0200e76:	ffea8a93          	addi	s5,s5,-2 # ffffffffc0208e70 <nbase>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0200e7a:	00200cb7          	lui	s9,0x200
ffffffffc0200e7e:	ffe00c37          	lui	s8,0xffe00
        pte_t *ptep = get_pte(from, start, 0);
ffffffffc0200e82:	4601                	li	a2,0
ffffffffc0200e84:	85a2                	mv	a1,s0
ffffffffc0200e86:	854a                	mv	a0,s2
ffffffffc0200e88:	61c000ef          	jal	ra,ffffffffc02014a4 <get_pte>
        if (ptep == NULL) {
ffffffffc0200e8c:	cd2d                	beqz	a0,ffffffffc0200f06 <cow_copy_range+0xe4>
        if (*ptep & PTE_V) {
ffffffffc0200e8e:	6114                	ld	a3,0(a0)
ffffffffc0200e90:	0016f793          	andi	a5,a3,1
ffffffffc0200e94:	e395                	bnez	a5,ffffffffc0200eb8 <cow_copy_range+0x96>
        start += PGSIZE;
ffffffffc0200e96:	944e                	add	s0,s0,s3
    } while (start != 0 && start < end);
ffffffffc0200e98:	fe9465e3          	bltu	s0,s1,ffffffffc0200e82 <cow_copy_range+0x60>
    return 0;
}
ffffffffc0200e9c:	60e6                	ld	ra,88(sp)
ffffffffc0200e9e:	6446                	ld	s0,80(sp)
ffffffffc0200ea0:	64a6                	ld	s1,72(sp)
ffffffffc0200ea2:	6906                	ld	s2,64(sp)
ffffffffc0200ea4:	79e2                	ld	s3,56(sp)
ffffffffc0200ea6:	7a42                	ld	s4,48(sp)
ffffffffc0200ea8:	7aa2                	ld	s5,40(sp)
ffffffffc0200eaa:	7b02                	ld	s6,32(sp)
ffffffffc0200eac:	6be2                	ld	s7,24(sp)
ffffffffc0200eae:	6c42                	ld	s8,16(sp)
ffffffffc0200eb0:	6ca2                	ld	s9,8(sp)
ffffffffc0200eb2:	4501                	li	a0,0
ffffffffc0200eb4:	6125                	addi	sp,sp,96
ffffffffc0200eb6:	8082                	ret
            *ptep &= ~PTE_W;
ffffffffc0200eb8:	ffb6f793          	andi	a5,a3,-5
ffffffffc0200ebc:	e11c                	sd	a5,0(a0)
    if (PPN(pa) >= npage) {
ffffffffc0200ebe:	000bb703          	ld	a4,0(s7)
static inline struct Page *
pte2page(pte_t pte) {
    if (!(pte & PTE_V)) {
        panic("pte2page called with invalid pte");
    }
    return pa2page(PTE_ADDR(pte));
ffffffffc0200ec2:	078a                	slli	a5,a5,0x2
ffffffffc0200ec4:	83b1                	srli	a5,a5,0xc
            uint32_t perm = (*ptep & PTE_USER & ~PTE_W);
ffffffffc0200ec6:	8aed                	andi	a3,a3,27
    if (PPN(pa) >= npage) {
ffffffffc0200ec8:	06e7f663          	bgeu	a5,a4,ffffffffc0200f34 <cow_copy_range+0x112>
    return &pages[PPN(pa) - nbase];
ffffffffc0200ecc:	000ab703          	ld	a4,0(s5)
ffffffffc0200ed0:	000b3583          	ld	a1,0(s6)
ffffffffc0200ed4:	8f99                	sub	a5,a5,a4
ffffffffc0200ed6:	079a                	slli	a5,a5,0x6
ffffffffc0200ed8:	95be                	add	a1,a1,a5
            assert(page != NULL);
ffffffffc0200eda:	cd8d                	beqz	a1,ffffffffc0200f14 <cow_copy_range+0xf2>
            ret = page_insert(to, page, start, perm);
ffffffffc0200edc:	8622                	mv	a2,s0
ffffffffc0200ede:	8552                	mv	a0,s4
ffffffffc0200ee0:	45f000ef          	jal	ra,ffffffffc0201b3e <page_insert>
            assert(ret == 0);
ffffffffc0200ee4:	d94d                	beqz	a0,ffffffffc0200e96 <cow_copy_range+0x74>
ffffffffc0200ee6:	00006697          	auipc	a3,0x6
ffffffffc0200eea:	2d268693          	addi	a3,a3,722 # ffffffffc02071b8 <commands+0x798>
ffffffffc0200eee:	00006617          	auipc	a2,0x6
ffffffffc0200ef2:	f4260613          	addi	a2,a2,-190 # ffffffffc0206e30 <commands+0x410>
ffffffffc0200ef6:	06b00593          	li	a1,107
ffffffffc0200efa:	00006517          	auipc	a0,0x6
ffffffffc0200efe:	25650513          	addi	a0,a0,598 # ffffffffc0207150 <commands+0x730>
ffffffffc0200f02:	b06ff0ef          	jal	ra,ffffffffc0200208 <__panic>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0200f06:	9466                	add	s0,s0,s9
ffffffffc0200f08:	01847433          	and	s0,s0,s8
    } while (start != 0 && start < end);
ffffffffc0200f0c:	d841                	beqz	s0,ffffffffc0200e9c <cow_copy_range+0x7a>
ffffffffc0200f0e:	f6946ae3          	bltu	s0,s1,ffffffffc0200e82 <cow_copy_range+0x60>
ffffffffc0200f12:	b769                	j	ffffffffc0200e9c <cow_copy_range+0x7a>
            assert(page != NULL);
ffffffffc0200f14:	00006697          	auipc	a3,0x6
ffffffffc0200f18:	29468693          	addi	a3,a3,660 # ffffffffc02071a8 <commands+0x788>
ffffffffc0200f1c:	00006617          	auipc	a2,0x6
ffffffffc0200f20:	f1460613          	addi	a2,a2,-236 # ffffffffc0206e30 <commands+0x410>
ffffffffc0200f24:	06800593          	li	a1,104
ffffffffc0200f28:	00006517          	auipc	a0,0x6
ffffffffc0200f2c:	22850513          	addi	a0,a0,552 # ffffffffc0207150 <commands+0x730>
ffffffffc0200f30:	ad8ff0ef          	jal	ra,ffffffffc0200208 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0200f34:	00006617          	auipc	a2,0x6
ffffffffc0200f38:	24460613          	addi	a2,a2,580 # ffffffffc0207178 <commands+0x758>
ffffffffc0200f3c:	06200593          	li	a1,98
ffffffffc0200f40:	00006517          	auipc	a0,0x6
ffffffffc0200f44:	25850513          	addi	a0,a0,600 # ffffffffc0207198 <commands+0x778>
ffffffffc0200f48:	ac0ff0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc0200f4c:	00006697          	auipc	a3,0x6
ffffffffc0200f50:	21468693          	addi	a3,a3,532 # ffffffffc0207160 <commands+0x740>
ffffffffc0200f54:	00006617          	auipc	a2,0x6
ffffffffc0200f58:	edc60613          	addi	a2,a2,-292 # ffffffffc0206e30 <commands+0x410>
ffffffffc0200f5c:	05d00593          	li	a1,93
ffffffffc0200f60:	00006517          	auipc	a0,0x6
ffffffffc0200f64:	1f050513          	addi	a0,a0,496 # ffffffffc0207150 <commands+0x730>
ffffffffc0200f68:	aa0ff0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0200f6c:	00006697          	auipc	a3,0x6
ffffffffc0200f70:	1b468693          	addi	a3,a3,436 # ffffffffc0207120 <commands+0x700>
ffffffffc0200f74:	00006617          	auipc	a2,0x6
ffffffffc0200f78:	ebc60613          	addi	a2,a2,-324 # ffffffffc0206e30 <commands+0x410>
ffffffffc0200f7c:	05c00593          	li	a1,92
ffffffffc0200f80:	00006517          	auipc	a0,0x6
ffffffffc0200f84:	1d050513          	addi	a0,a0,464 # ffffffffc0207150 <commands+0x730>
ffffffffc0200f88:	a80ff0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0200f8c <cow_copy_mmap>:
cow_copy_mmap(struct mm_struct *to, struct mm_struct *from) {
ffffffffc0200f8c:	1101                	addi	sp,sp,-32
ffffffffc0200f8e:	ec06                	sd	ra,24(sp)
ffffffffc0200f90:	e822                	sd	s0,16(sp)
ffffffffc0200f92:	e426                	sd	s1,8(sp)
ffffffffc0200f94:	e04a                	sd	s2,0(sp)
    assert(to != NULL && from != NULL);
ffffffffc0200f96:	cd31                	beqz	a0,ffffffffc0200ff2 <cow_copy_mmap+0x66>
ffffffffc0200f98:	892a                	mv	s2,a0
ffffffffc0200f9a:	84ae                	mv	s1,a1
    list_entry_t *list = &(from->mmap_list), *le = list;
ffffffffc0200f9c:	842e                	mv	s0,a1
    assert(to != NULL && from != NULL);
ffffffffc0200f9e:	e98d                	bnez	a1,ffffffffc0200fd0 <cow_copy_mmap+0x44>
ffffffffc0200fa0:	a889                	j	ffffffffc0200ff2 <cow_copy_mmap+0x66>
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
ffffffffc0200fa2:	ff043583          	ld	a1,-16(s0)
ffffffffc0200fa6:	ff842603          	lw	a2,-8(s0)
ffffffffc0200faa:	fe843503          	ld	a0,-24(s0)
ffffffffc0200fae:	14d010ef          	jal	ra,ffffffffc02028fa <vma_create>
ffffffffc0200fb2:	85aa                	mv	a1,a0
        if (nvma == NULL) {
ffffffffc0200fb4:	c905                	beqz	a0,ffffffffc0200fe4 <cow_copy_mmap+0x58>
        insert_vma_struct(to, nvma);
ffffffffc0200fb6:	854a                	mv	a0,s2
ffffffffc0200fb8:	1b1010ef          	jal	ra,ffffffffc0202968 <insert_vma_struct>
        if (cow_copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end) != 0) {
ffffffffc0200fbc:	ff043683          	ld	a3,-16(s0)
ffffffffc0200fc0:	fe843603          	ld	a2,-24(s0)
ffffffffc0200fc4:	6c8c                	ld	a1,24(s1)
ffffffffc0200fc6:	01893503          	ld	a0,24(s2)
ffffffffc0200fca:	e59ff0ef          	jal	ra,ffffffffc0200e22 <cow_copy_range>
ffffffffc0200fce:	e919                	bnez	a0,ffffffffc0200fe4 <cow_copy_mmap+0x58>
 * list_prev - get the previous entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_prev(list_entry_t *listelm) {
    return listelm->prev;
ffffffffc0200fd0:	6000                	ld	s0,0(s0)
    while ((le = list_prev(le)) != list) {
ffffffffc0200fd2:	fc8498e3          	bne	s1,s0,ffffffffc0200fa2 <cow_copy_mmap+0x16>
}
ffffffffc0200fd6:	60e2                	ld	ra,24(sp)
ffffffffc0200fd8:	6442                	ld	s0,16(sp)
ffffffffc0200fda:	64a2                	ld	s1,8(sp)
ffffffffc0200fdc:	6902                	ld	s2,0(sp)
    return 0;
ffffffffc0200fde:	4501                	li	a0,0
}
ffffffffc0200fe0:	6105                	addi	sp,sp,32
ffffffffc0200fe2:	8082                	ret
ffffffffc0200fe4:	60e2                	ld	ra,24(sp)
ffffffffc0200fe6:	6442                	ld	s0,16(sp)
ffffffffc0200fe8:	64a2                	ld	s1,8(sp)
ffffffffc0200fea:	6902                	ld	s2,0(sp)
            return -E_NO_MEM;
ffffffffc0200fec:	5571                	li	a0,-4
}
ffffffffc0200fee:	6105                	addi	sp,sp,32
ffffffffc0200ff0:	8082                	ret
    assert(to != NULL && from != NULL);
ffffffffc0200ff2:	00006697          	auipc	a3,0x6
ffffffffc0200ff6:	1d668693          	addi	a3,a3,470 # ffffffffc02071c8 <commands+0x7a8>
ffffffffc0200ffa:	00006617          	auipc	a2,0x6
ffffffffc0200ffe:	e3660613          	addi	a2,a2,-458 # ffffffffc0206e30 <commands+0x410>
ffffffffc0201002:	04a00593          	li	a1,74
ffffffffc0201006:	00006517          	auipc	a0,0x6
ffffffffc020100a:	14a50513          	addi	a0,a0,330 # ffffffffc0207150 <commands+0x730>
ffffffffc020100e:	9faff0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0201012 <cow_copy_mm>:
cow_copy_mm(struct proc_struct *proc) {
ffffffffc0201012:	715d                	addi	sp,sp,-80
    struct mm_struct *mm, *oldmm = current->mm;
ffffffffc0201014:	000b2797          	auipc	a5,0xb2
ffffffffc0201018:	8b47b783          	ld	a5,-1868(a5) # ffffffffc02b28c8 <current>
cow_copy_mm(struct proc_struct *proc) {
ffffffffc020101c:	fc26                	sd	s1,56(sp)
    struct mm_struct *mm, *oldmm = current->mm;
ffffffffc020101e:	7784                	ld	s1,40(a5)
cow_copy_mm(struct proc_struct *proc) {
ffffffffc0201020:	e486                	sd	ra,72(sp)
ffffffffc0201022:	e0a2                	sd	s0,64(sp)
ffffffffc0201024:	f84a                	sd	s2,48(sp)
ffffffffc0201026:	f44e                	sd	s3,40(sp)
ffffffffc0201028:	f052                	sd	s4,32(sp)
ffffffffc020102a:	ec56                	sd	s5,24(sp)
ffffffffc020102c:	e85a                	sd	s6,16(sp)
ffffffffc020102e:	e45e                	sd	s7,8(sp)
ffffffffc0201030:	e062                	sd	s8,0(sp)
    if (oldmm == NULL) {
ffffffffc0201032:	c4f1                	beqz	s1,ffffffffc02010fe <cow_copy_mm+0xec>
ffffffffc0201034:	89aa                	mv	s3,a0
    if ((mm = mm_create()) == NULL) {
ffffffffc0201036:	07d010ef          	jal	ra,ffffffffc02028b2 <mm_create>
ffffffffc020103a:	892a                	mv	s2,a0
ffffffffc020103c:	c169                	beqz	a0,ffffffffc02010fe <cow_copy_mm+0xec>
    if ((page = alloc_page()) == NULL) {
ffffffffc020103e:	4505                	li	a0,1
ffffffffc0201040:	358000ef          	jal	ra,ffffffffc0201398 <alloc_pages>
ffffffffc0201044:	10050a63          	beqz	a0,ffffffffc0201158 <cow_copy_mm+0x146>
    return page - pages + nbase;
ffffffffc0201048:	000b2a17          	auipc	s4,0xb2
ffffffffc020104c:	838a0a13          	addi	s4,s4,-1992 # ffffffffc02b2880 <pages>
ffffffffc0201050:	000a3683          	ld	a3,0(s4)
ffffffffc0201054:	00008a97          	auipc	s5,0x8
ffffffffc0201058:	e1ca8a93          	addi	s5,s5,-484 # ffffffffc0208e70 <nbase>
ffffffffc020105c:	000ab403          	ld	s0,0(s5)
ffffffffc0201060:	40d506b3          	sub	a3,a0,a3
ffffffffc0201064:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0201066:	000b2b17          	auipc	s6,0xb2
ffffffffc020106a:	812b0b13          	addi	s6,s6,-2030 # ffffffffc02b2878 <npage>
    return page - pages + nbase;
ffffffffc020106e:	96a2                	add	a3,a3,s0
    return KADDR(page2pa(page));
ffffffffc0201070:	000b3703          	ld	a4,0(s6)
ffffffffc0201074:	00c69793          	slli	a5,a3,0xc
ffffffffc0201078:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc020107a:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020107c:	0ee7f063          	bgeu	a5,a4,ffffffffc020115c <cow_copy_mm+0x14a>
ffffffffc0201080:	000b2c17          	auipc	s8,0xb2
ffffffffc0201084:	810c0c13          	addi	s8,s8,-2032 # ffffffffc02b2890 <va_pa_offset>
ffffffffc0201088:	000c3403          	ld	s0,0(s8)
    memcpy(pgdir, boot_pgdir, PGSIZE);
ffffffffc020108c:	6605                	lui	a2,0x1
ffffffffc020108e:	000b1597          	auipc	a1,0xb1
ffffffffc0201092:	7e25b583          	ld	a1,2018(a1) # ffffffffc02b2870 <boot_pgdir>
ffffffffc0201096:	9436                	add	s0,s0,a3
ffffffffc0201098:	8522                	mv	a0,s0
ffffffffc020109a:	2c2050ef          	jal	ra,ffffffffc020635c <memcpy>
}

static inline void
lock_mm(struct mm_struct *mm) {
    if (mm != NULL) {
        lock(&(mm->mm_lock));
ffffffffc020109e:	03848b93          	addi	s7,s1,56
    mm->pgdir = pgdir;
ffffffffc02010a2:	00893c23          	sd	s0,24(s2)
 * test_and_set_bit - Atomically set a bit and return its old value
 * @nr:     the bit to set
 * @addr:   the address to count from
 * */
static inline bool test_and_set_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02010a6:	4785                	li	a5,1
ffffffffc02010a8:	40fbb7af          	amoor.d	a5,a5,(s7)
    return !test_and_set_bit(0, lock);
}

static inline void
lock(lock_t *lock) {
    while (!try_lock(lock)) {
ffffffffc02010ac:	8b85                	andi	a5,a5,1
ffffffffc02010ae:	cb81                	beqz	a5,ffffffffc02010be <cow_copy_mm+0xac>
ffffffffc02010b0:	4405                	li	s0,1
        schedule();
ffffffffc02010b2:	0b0050ef          	jal	ra,ffffffffc0206162 <schedule>
ffffffffc02010b6:	408bb7af          	amoor.d	a5,s0,(s7)
    while (!try_lock(lock)) {
ffffffffc02010ba:	8b85                	andi	a5,a5,1
ffffffffc02010bc:	fbfd                	bnez	a5,ffffffffc02010b2 <cow_copy_mm+0xa0>
        ret = cow_copy_mmap(mm, oldmm);
ffffffffc02010be:	85a6                	mv	a1,s1
ffffffffc02010c0:	854a                	mv	a0,s2
ffffffffc02010c2:	ecbff0ef          	jal	ra,ffffffffc0200f8c <cow_copy_mmap>
ffffffffc02010c6:	842a                	mv	s0,a0
 * test_and_clear_bit - Atomically clear a bit and return its old value
 * @nr:     the bit to clear
 * @addr:   the address to count from
 * */
static inline bool test_and_clear_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02010c8:	57f9                	li	a5,-2
ffffffffc02010ca:	03848713          	addi	a4,s1,56
ffffffffc02010ce:	60f737af          	amoand.d	a5,a5,(a4)
ffffffffc02010d2:	8b85                	andi	a5,a5,1
    }
}

static inline void
unlock(lock_t *lock) {
    if (!test_and_clear_bit(0, lock)) {
ffffffffc02010d4:	cfc5                	beqz	a5,ffffffffc020118c <cow_copy_mm+0x17a>
    if (ret != 0) {
ffffffffc02010d6:	e131                	bnez	a0,ffffffffc020111a <cow_copy_mm+0x108>
    mm->mm_count += 1;
ffffffffc02010d8:	03092783          	lw	a5,48(s2)
    proc->cr3 = PADDR(mm->pgdir);
ffffffffc02010dc:	01893683          	ld	a3,24(s2)
ffffffffc02010e0:	c0200737          	lui	a4,0xc0200
ffffffffc02010e4:	2785                	addiw	a5,a5,1
ffffffffc02010e6:	02f92823          	sw	a5,48(s2)
    proc->mm = mm;
ffffffffc02010ea:	0329b423          	sd	s2,40(s3) # 1028 <_binary_obj___user_faultread_out_size-0x8b90>
    proc->cr3 = PADDR(mm->pgdir);
ffffffffc02010ee:	08e6e363          	bltu	a3,a4,ffffffffc0201174 <cow_copy_mm+0x162>
ffffffffc02010f2:	000c3783          	ld	a5,0(s8)
ffffffffc02010f6:	8e9d                	sub	a3,a3,a5
ffffffffc02010f8:	0ad9b423          	sd	a3,168(s3)
    return 0;
ffffffffc02010fc:	a011                	j	ffffffffc0201100 <cow_copy_mm+0xee>
        return 0;
ffffffffc02010fe:	4401                	li	s0,0
}
ffffffffc0201100:	60a6                	ld	ra,72(sp)
ffffffffc0201102:	8522                	mv	a0,s0
ffffffffc0201104:	6406                	ld	s0,64(sp)
ffffffffc0201106:	74e2                	ld	s1,56(sp)
ffffffffc0201108:	7942                	ld	s2,48(sp)
ffffffffc020110a:	79a2                	ld	s3,40(sp)
ffffffffc020110c:	7a02                	ld	s4,32(sp)
ffffffffc020110e:	6ae2                	ld	s5,24(sp)
ffffffffc0201110:	6b42                	ld	s6,16(sp)
ffffffffc0201112:	6ba2                	ld	s7,8(sp)
ffffffffc0201114:	6c02                	ld	s8,0(sp)
ffffffffc0201116:	6161                	addi	sp,sp,80
ffffffffc0201118:	8082                	ret
    exit_mmap(mm);
ffffffffc020111a:	854a                	mv	a0,s2
ffffffffc020111c:	21f010ef          	jal	ra,ffffffffc0202b3a <exit_mmap>
    return pa2page(PADDR(kva));
ffffffffc0201120:	01893683          	ld	a3,24(s2)
ffffffffc0201124:	c02007b7          	lui	a5,0xc0200
ffffffffc0201128:	08f6ea63          	bltu	a3,a5,ffffffffc02011bc <cow_copy_mm+0x1aa>
ffffffffc020112c:	000c3703          	ld	a4,0(s8)
    if (PPN(pa) >= npage) {
ffffffffc0201130:	000b3783          	ld	a5,0(s6)
    return pa2page(PADDR(kva));
ffffffffc0201134:	8e99                	sub	a3,a3,a4
    if (PPN(pa) >= npage) {
ffffffffc0201136:	82b1                	srli	a3,a3,0xc
ffffffffc0201138:	06f6f663          	bgeu	a3,a5,ffffffffc02011a4 <cow_copy_mm+0x192>
    return &pages[PPN(pa) - nbase];
ffffffffc020113c:	000ab783          	ld	a5,0(s5)
ffffffffc0201140:	000a3503          	ld	a0,0(s4)
    free_page(kva2page(mm->pgdir));
ffffffffc0201144:	4585                	li	a1,1
ffffffffc0201146:	8e9d                	sub	a3,a3,a5
ffffffffc0201148:	069a                	slli	a3,a3,0x6
ffffffffc020114a:	9536                	add	a0,a0,a3
ffffffffc020114c:	2de000ef          	jal	ra,ffffffffc020142a <free_pages>
    mm_destroy(mm);
ffffffffc0201150:	854a                	mv	a0,s2
ffffffffc0201152:	0e7010ef          	jal	ra,ffffffffc0202a38 <mm_destroy>
ffffffffc0201156:	b76d                	j	ffffffffc0201100 <cow_copy_mm+0xee>
    int ret = 0;
ffffffffc0201158:	4401                	li	s0,0
ffffffffc020115a:	bfdd                	j	ffffffffc0201150 <cow_copy_mm+0x13e>
    return KADDR(page2pa(page));
ffffffffc020115c:	00006617          	auipc	a2,0x6
ffffffffc0201160:	08c60613          	addi	a2,a2,140 # ffffffffc02071e8 <commands+0x7c8>
ffffffffc0201164:	06900593          	li	a1,105
ffffffffc0201168:	00006517          	auipc	a0,0x6
ffffffffc020116c:	03050513          	addi	a0,a0,48 # ffffffffc0207198 <commands+0x778>
ffffffffc0201170:	898ff0ef          	jal	ra,ffffffffc0200208 <__panic>
    proc->cr3 = PADDR(mm->pgdir);
ffffffffc0201174:	00006617          	auipc	a2,0x6
ffffffffc0201178:	0c460613          	addi	a2,a2,196 # ffffffffc0207238 <commands+0x818>
ffffffffc020117c:	03d00593          	li	a1,61
ffffffffc0201180:	00006517          	auipc	a0,0x6
ffffffffc0201184:	fd050513          	addi	a0,a0,-48 # ffffffffc0207150 <commands+0x730>
ffffffffc0201188:	880ff0ef          	jal	ra,ffffffffc0200208 <__panic>
        panic("Unlock failed.\n");
ffffffffc020118c:	00006617          	auipc	a2,0x6
ffffffffc0201190:	08460613          	addi	a2,a2,132 # ffffffffc0207210 <commands+0x7f0>
ffffffffc0201194:	03100593          	li	a1,49
ffffffffc0201198:	00006517          	auipc	a0,0x6
ffffffffc020119c:	08850513          	addi	a0,a0,136 # ffffffffc0207220 <commands+0x800>
ffffffffc02011a0:	868ff0ef          	jal	ra,ffffffffc0200208 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02011a4:	00006617          	auipc	a2,0x6
ffffffffc02011a8:	fd460613          	addi	a2,a2,-44 # ffffffffc0207178 <commands+0x758>
ffffffffc02011ac:	06200593          	li	a1,98
ffffffffc02011b0:	00006517          	auipc	a0,0x6
ffffffffc02011b4:	fe850513          	addi	a0,a0,-24 # ffffffffc0207198 <commands+0x778>
ffffffffc02011b8:	850ff0ef          	jal	ra,ffffffffc0200208 <__panic>
    return pa2page(PADDR(kva));
ffffffffc02011bc:	00006617          	auipc	a2,0x6
ffffffffc02011c0:	07c60613          	addi	a2,a2,124 # ffffffffc0207238 <commands+0x818>
ffffffffc02011c4:	06e00593          	li	a1,110
ffffffffc02011c8:	00006517          	auipc	a0,0x6
ffffffffc02011cc:	fd050513          	addi	a0,a0,-48 # ffffffffc0207198 <commands+0x778>
ffffffffc02011d0:	838ff0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc02011d4 <cow_pgfault>:

int 
cow_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) {
ffffffffc02011d4:	715d                	addi	sp,sp,-80
    cprintf("COW page fault at 0x%x\n", addr);
ffffffffc02011d6:	85b2                	mv	a1,a2
cow_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) {
ffffffffc02011d8:	f84a                	sd	s2,48(sp)
ffffffffc02011da:	892a                	mv	s2,a0
    cprintf("COW page fault at 0x%x\n", addr);
ffffffffc02011dc:	00006517          	auipc	a0,0x6
ffffffffc02011e0:	08450513          	addi	a0,a0,132 # ffffffffc0207260 <commands+0x840>
cow_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) {
ffffffffc02011e4:	e486                	sd	ra,72(sp)
ffffffffc02011e6:	fc26                	sd	s1,56(sp)
ffffffffc02011e8:	e0a2                	sd	s0,64(sp)
ffffffffc02011ea:	84b2                	mv	s1,a2
ffffffffc02011ec:	f44e                	sd	s3,40(sp)
ffffffffc02011ee:	f052                	sd	s4,32(sp)
ffffffffc02011f0:	ec56                	sd	s5,24(sp)
ffffffffc02011f2:	e85a                	sd	s6,16(sp)
ffffffffc02011f4:	e45e                	sd	s7,8(sp)
ffffffffc02011f6:	e062                	sd	s8,0(sp)
    cprintf("COW page fault at 0x%x\n", addr);
ffffffffc02011f8:	ed5fe0ef          	jal	ra,ffffffffc02000cc <cprintf>
    int ret = 0;
    pte_t *ptep = NULL;
    ptep = get_pte(mm->pgdir, addr, 0);
ffffffffc02011fc:	01893503          	ld	a0,24(s2)
ffffffffc0201200:	4601                	li	a2,0
ffffffffc0201202:	85a6                	mv	a1,s1
ffffffffc0201204:	2a0000ef          	jal	ra,ffffffffc02014a4 <get_pte>
    uint32_t perm = (*ptep & PTE_USER) | PTE_W;
ffffffffc0201208:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc020120a:	0017f713          	andi	a4,a5,1
ffffffffc020120e:	12070d63          	beqz	a4,ffffffffc0201348 <cow_pgfault+0x174>
    if (PPN(pa) >= npage) {
ffffffffc0201212:	000b1b97          	auipc	s7,0xb1
ffffffffc0201216:	666b8b93          	addi	s7,s7,1638 # ffffffffc02b2878 <npage>
ffffffffc020121a:	000bb703          	ld	a4,0(s7)
ffffffffc020121e:	01b7fa13          	andi	s4,a5,27
    return pa2page(PTE_ADDR(pte));
ffffffffc0201222:	078a                	slli	a5,a5,0x2
ffffffffc0201224:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201226:	10e7f563          	bgeu	a5,a4,ffffffffc0201330 <cow_pgfault+0x15c>
    return &pages[PPN(pa) - nbase];
ffffffffc020122a:	000b1c17          	auipc	s8,0xb1
ffffffffc020122e:	656c0c13          	addi	s8,s8,1622 # ffffffffc02b2880 <pages>
ffffffffc0201232:	000c3403          	ld	s0,0(s8)
ffffffffc0201236:	00008b17          	auipc	s6,0x8
ffffffffc020123a:	c3ab3b03          	ld	s6,-966(s6) # ffffffffc0208e70 <nbase>
ffffffffc020123e:	416787b3          	sub	a5,a5,s6
ffffffffc0201242:	079a                	slli	a5,a5,0x6
ffffffffc0201244:	89aa                	mv	s3,a0
    struct Page *page = pte2page(*ptep);
    struct Page *npage = alloc_page();
ffffffffc0201246:	4505                	li	a0,1
ffffffffc0201248:	943e                	add	s0,s0,a5
ffffffffc020124a:	14e000ef          	jal	ra,ffffffffc0201398 <alloc_pages>
ffffffffc020124e:	8aaa                	mv	s5,a0
    assert(page != NULL);
ffffffffc0201250:	c061                	beqz	s0,ffffffffc0201310 <cow_pgfault+0x13c>
    assert(npage != NULL);
ffffffffc0201252:	cd59                	beqz	a0,ffffffffc02012f0 <cow_pgfault+0x11c>
    return page - pages + nbase;
ffffffffc0201254:	000c3703          	ld	a4,0(s8)
    return KADDR(page2pa(page));
ffffffffc0201258:	567d                	li	a2,-1
ffffffffc020125a:	000bb803          	ld	a6,0(s7)
    return page - pages + nbase;
ffffffffc020125e:	40e406b3          	sub	a3,s0,a4
ffffffffc0201262:	8699                	srai	a3,a3,0x6
ffffffffc0201264:	96da                	add	a3,a3,s6
    return KADDR(page2pa(page));
ffffffffc0201266:	8231                	srli	a2,a2,0xc
ffffffffc0201268:	00c6f7b3          	and	a5,a3,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc020126c:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020126e:	0707f563          	bgeu	a5,a6,ffffffffc02012d8 <cow_pgfault+0x104>
    return page - pages + nbase;
ffffffffc0201272:	40e507b3          	sub	a5,a0,a4
ffffffffc0201276:	8799                	srai	a5,a5,0x6
ffffffffc0201278:	97da                	add	a5,a5,s6
    return KADDR(page2pa(page));
ffffffffc020127a:	000b1517          	auipc	a0,0xb1
ffffffffc020127e:	61653503          	ld	a0,1558(a0) # ffffffffc02b2890 <va_pa_offset>
ffffffffc0201282:	8e7d                	and	a2,a2,a5
ffffffffc0201284:	00a685b3          	add	a1,a3,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc0201288:	07b2                	slli	a5,a5,0xc
    return KADDR(page2pa(page));
ffffffffc020128a:	05067663          	bgeu	a2,a6,ffffffffc02012d6 <cow_pgfault+0x102>
    uintptr_t* src = page2kva(page);
    uintptr_t* dst = page2kva(npage);
    memcpy(dst, src, PGSIZE);
ffffffffc020128e:	953e                	add	a0,a0,a5
ffffffffc0201290:	6605                	lui	a2,0x1
ffffffffc0201292:	0ca050ef          	jal	ra,ffffffffc020635c <memcpy>
    uintptr_t start = ROUNDDOWN(addr, PGSIZE);
    *ptep = 0;
    ret = page_insert(mm->pgdir, npage, start, perm);
ffffffffc0201296:	01893503          	ld	a0,24(s2)
ffffffffc020129a:	004a6a13          	ori	s4,s4,4
ffffffffc020129e:	767d                	lui	a2,0xfffff
ffffffffc02012a0:	86d2                	mv	a3,s4
ffffffffc02012a2:	8e65                	and	a2,a2,s1
ffffffffc02012a4:	85d6                	mv	a1,s5
    *ptep = 0;
ffffffffc02012a6:	0009b023          	sd	zero,0(s3)
    ret = page_insert(mm->pgdir, npage, start, perm);
ffffffffc02012aa:	095000ef          	jal	ra,ffffffffc0201b3e <page_insert>
ffffffffc02012ae:	842a                	mv	s0,a0
    ptep = get_pte(mm->pgdir, addr, 0);
ffffffffc02012b0:	01893503          	ld	a0,24(s2)
ffffffffc02012b4:	85a6                	mv	a1,s1
ffffffffc02012b6:	4601                	li	a2,0
ffffffffc02012b8:	1ec000ef          	jal	ra,ffffffffc02014a4 <get_pte>
    return ret;
ffffffffc02012bc:	60a6                	ld	ra,72(sp)
ffffffffc02012be:	8522                	mv	a0,s0
ffffffffc02012c0:	6406                	ld	s0,64(sp)
ffffffffc02012c2:	74e2                	ld	s1,56(sp)
ffffffffc02012c4:	7942                	ld	s2,48(sp)
ffffffffc02012c6:	79a2                	ld	s3,40(sp)
ffffffffc02012c8:	7a02                	ld	s4,32(sp)
ffffffffc02012ca:	6ae2                	ld	s5,24(sp)
ffffffffc02012cc:	6b42                	ld	s6,16(sp)
ffffffffc02012ce:	6ba2                	ld	s7,8(sp)
ffffffffc02012d0:	6c02                	ld	s8,0(sp)
ffffffffc02012d2:	6161                	addi	sp,sp,80
ffffffffc02012d4:	8082                	ret
ffffffffc02012d6:	86be                	mv	a3,a5
ffffffffc02012d8:	00006617          	auipc	a2,0x6
ffffffffc02012dc:	f1060613          	addi	a2,a2,-240 # ffffffffc02071e8 <commands+0x7c8>
ffffffffc02012e0:	06900593          	li	a1,105
ffffffffc02012e4:	00006517          	auipc	a0,0x6
ffffffffc02012e8:	eb450513          	addi	a0,a0,-332 # ffffffffc0207198 <commands+0x778>
ffffffffc02012ec:	f1dfe0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(npage != NULL);
ffffffffc02012f0:	00006697          	auipc	a3,0x6
ffffffffc02012f4:	fb068693          	addi	a3,a3,-80 # ffffffffc02072a0 <commands+0x880>
ffffffffc02012f8:	00006617          	auipc	a2,0x6
ffffffffc02012fc:	b3860613          	addi	a2,a2,-1224 # ffffffffc0206e30 <commands+0x410>
ffffffffc0201300:	07c00593          	li	a1,124
ffffffffc0201304:	00006517          	auipc	a0,0x6
ffffffffc0201308:	e4c50513          	addi	a0,a0,-436 # ffffffffc0207150 <commands+0x730>
ffffffffc020130c:	efdfe0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(page != NULL);
ffffffffc0201310:	00006697          	auipc	a3,0x6
ffffffffc0201314:	e9868693          	addi	a3,a3,-360 # ffffffffc02071a8 <commands+0x788>
ffffffffc0201318:	00006617          	auipc	a2,0x6
ffffffffc020131c:	b1860613          	addi	a2,a2,-1256 # ffffffffc0206e30 <commands+0x410>
ffffffffc0201320:	07b00593          	li	a1,123
ffffffffc0201324:	00006517          	auipc	a0,0x6
ffffffffc0201328:	e2c50513          	addi	a0,a0,-468 # ffffffffc0207150 <commands+0x730>
ffffffffc020132c:	eddfe0ef          	jal	ra,ffffffffc0200208 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0201330:	00006617          	auipc	a2,0x6
ffffffffc0201334:	e4860613          	addi	a2,a2,-440 # ffffffffc0207178 <commands+0x758>
ffffffffc0201338:	06200593          	li	a1,98
ffffffffc020133c:	00006517          	auipc	a0,0x6
ffffffffc0201340:	e5c50513          	addi	a0,a0,-420 # ffffffffc0207198 <commands+0x778>
ffffffffc0201344:	ec5fe0ef          	jal	ra,ffffffffc0200208 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc0201348:	00006617          	auipc	a2,0x6
ffffffffc020134c:	f3060613          	addi	a2,a2,-208 # ffffffffc0207278 <commands+0x858>
ffffffffc0201350:	07400593          	li	a1,116
ffffffffc0201354:	00006517          	auipc	a0,0x6
ffffffffc0201358:	e4450513          	addi	a0,a0,-444 # ffffffffc0207198 <commands+0x778>
ffffffffc020135c:	eadfe0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0201360 <pa2page.part.0>:
pa2page(uintptr_t pa) {
ffffffffc0201360:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201362:	00006617          	auipc	a2,0x6
ffffffffc0201366:	e1660613          	addi	a2,a2,-490 # ffffffffc0207178 <commands+0x758>
ffffffffc020136a:	06200593          	li	a1,98
ffffffffc020136e:	00006517          	auipc	a0,0x6
ffffffffc0201372:	e2a50513          	addi	a0,a0,-470 # ffffffffc0207198 <commands+0x778>
pa2page(uintptr_t pa) {
ffffffffc0201376:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201378:	e91fe0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc020137c <pte2page.part.0>:
pte2page(pte_t pte) {
ffffffffc020137c:	1141                	addi	sp,sp,-16
        panic("pte2page called with invalid pte");
ffffffffc020137e:	00006617          	auipc	a2,0x6
ffffffffc0201382:	efa60613          	addi	a2,a2,-262 # ffffffffc0207278 <commands+0x858>
ffffffffc0201386:	07400593          	li	a1,116
ffffffffc020138a:	00006517          	auipc	a0,0x6
ffffffffc020138e:	e0e50513          	addi	a0,a0,-498 # ffffffffc0207198 <commands+0x778>
pte2page(pte_t pte) {
ffffffffc0201392:	e406                	sd	ra,8(sp)
        panic("pte2page called with invalid pte");
ffffffffc0201394:	e75fe0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0201398 <alloc_pages>:
    pmm_manager->init_memmap(base, n); // 初始化内存映射
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE memory
// 调用pmm->alloc_pages分配连续的n*PAGESIZE内存
struct Page *alloc_pages(size_t n) {
ffffffffc0201398:	7139                	addi	sp,sp,-64
ffffffffc020139a:	f426                	sd	s1,40(sp)
ffffffffc020139c:	f04a                	sd	s2,32(sp)
ffffffffc020139e:	ec4e                	sd	s3,24(sp)
ffffffffc02013a0:	e852                	sd	s4,16(sp)
ffffffffc02013a2:	e456                	sd	s5,8(sp)
ffffffffc02013a4:	e05a                	sd	s6,0(sp)
ffffffffc02013a6:	fc06                	sd	ra,56(sp)
ffffffffc02013a8:	f822                	sd	s0,48(sp)
ffffffffc02013aa:	84aa                	mv	s1,a0
ffffffffc02013ac:	000b1917          	auipc	s2,0xb1
ffffffffc02013b0:	4dc90913          	addi	s2,s2,1244 # ffffffffc02b2888 <pmm_manager>
        {
            page = pmm_manager->alloc_pages(n); // 分配页
        }
        local_intr_restore(intr_flag); // 恢复中断状态

        if (page != NULL || n > 1 || swap_init_ok == 0) break; // 如果分配成功或不需要交换，跳出循环
ffffffffc02013b4:	4a05                	li	s4,1
ffffffffc02013b6:	000b1a97          	auipc	s5,0xb1
ffffffffc02013ba:	502a8a93          	addi	s5,s5,1282 # ffffffffc02b28b8 <swap_init_ok>

        extern struct mm_struct *check_mm_struct;
        // cprintf("page %x, call swap_out in alloc_pages %d\n",page, n);
        swap_out(check_mm_struct, n, 0); // 调用swap_out进行交换
ffffffffc02013be:	0005099b          	sext.w	s3,a0
ffffffffc02013c2:	000b1b17          	auipc	s6,0xb1
ffffffffc02013c6:	4d6b0b13          	addi	s6,s6,1238 # ffffffffc02b2898 <check_mm_struct>
ffffffffc02013ca:	a01d                	j	ffffffffc02013f0 <alloc_pages+0x58>
            page = pmm_manager->alloc_pages(n); // 分配页
ffffffffc02013cc:	00093783          	ld	a5,0(s2)
ffffffffc02013d0:	6f9c                	ld	a5,24(a5)
ffffffffc02013d2:	9782                	jalr	a5
ffffffffc02013d4:	842a                	mv	s0,a0
        swap_out(check_mm_struct, n, 0); // 调用swap_out进行交换
ffffffffc02013d6:	4601                	li	a2,0
ffffffffc02013d8:	85ce                	mv	a1,s3
        if (page != NULL || n > 1 || swap_init_ok == 0) break; // 如果分配成功或不需要交换，跳出循环
ffffffffc02013da:	ec0d                	bnez	s0,ffffffffc0201414 <alloc_pages+0x7c>
ffffffffc02013dc:	029a6c63          	bltu	s4,s1,ffffffffc0201414 <alloc_pages+0x7c>
ffffffffc02013e0:	000aa783          	lw	a5,0(s5)
ffffffffc02013e4:	2781                	sext.w	a5,a5
ffffffffc02013e6:	c79d                	beqz	a5,ffffffffc0201414 <alloc_pages+0x7c>
        swap_out(check_mm_struct, n, 0); // 调用swap_out进行交换
ffffffffc02013e8:	000b3503          	ld	a0,0(s6)
ffffffffc02013ec:	632020ef          	jal	ra,ffffffffc0203a1e <swap_out>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02013f0:	100027f3          	csrr	a5,sstatus
ffffffffc02013f4:	8b89                	andi	a5,a5,2
            page = pmm_manager->alloc_pages(n); // 分配页
ffffffffc02013f6:	8526                	mv	a0,s1
ffffffffc02013f8:	dbf1                	beqz	a5,ffffffffc02013cc <alloc_pages+0x34>
        intr_disable();
ffffffffc02013fa:	a4eff0ef          	jal	ra,ffffffffc0200648 <intr_disable>
ffffffffc02013fe:	00093783          	ld	a5,0(s2)
ffffffffc0201402:	8526                	mv	a0,s1
ffffffffc0201404:	6f9c                	ld	a5,24(a5)
ffffffffc0201406:	9782                	jalr	a5
ffffffffc0201408:	842a                	mv	s0,a0
        intr_enable();
ffffffffc020140a:	a38ff0ef          	jal	ra,ffffffffc0200642 <intr_enable>
        swap_out(check_mm_struct, n, 0); // 调用swap_out进行交换
ffffffffc020140e:	4601                	li	a2,0
ffffffffc0201410:	85ce                	mv	a1,s3
        if (page != NULL || n > 1 || swap_init_ok == 0) break; // 如果分配成功或不需要交换，跳出循环
ffffffffc0201412:	d469                	beqz	s0,ffffffffc02013dc <alloc_pages+0x44>
    }
    // cprintf("n %d,get page %x, No %d in alloc_pages\n",n,page,(page-pages));
    return page; // 返回分配的页
}
ffffffffc0201414:	70e2                	ld	ra,56(sp)
ffffffffc0201416:	8522                	mv	a0,s0
ffffffffc0201418:	7442                	ld	s0,48(sp)
ffffffffc020141a:	74a2                	ld	s1,40(sp)
ffffffffc020141c:	7902                	ld	s2,32(sp)
ffffffffc020141e:	69e2                	ld	s3,24(sp)
ffffffffc0201420:	6a42                	ld	s4,16(sp)
ffffffffc0201422:	6aa2                	ld	s5,8(sp)
ffffffffc0201424:	6b02                	ld	s6,0(sp)
ffffffffc0201426:	6121                	addi	sp,sp,64
ffffffffc0201428:	8082                	ret

ffffffffc020142a <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020142a:	100027f3          	csrr	a5,sstatus
ffffffffc020142e:	8b89                	andi	a5,a5,2
ffffffffc0201430:	e799                	bnez	a5,ffffffffc020143e <free_pages+0x14>
// 调用pmm->free_pages释放连续的n*PAGESIZE内存
void free_pages(struct Page *base, size_t n) {
    bool intr_flag; // 中断标志
    local_intr_save(intr_flag); // 保存中断状态
    {
        pmm_manager->free_pages(base, n); // 释放页
ffffffffc0201432:	000b1797          	auipc	a5,0xb1
ffffffffc0201436:	4567b783          	ld	a5,1110(a5) # ffffffffc02b2888 <pmm_manager>
ffffffffc020143a:	739c                	ld	a5,32(a5)
ffffffffc020143c:	8782                	jr	a5
void free_pages(struct Page *base, size_t n) {
ffffffffc020143e:	1101                	addi	sp,sp,-32
ffffffffc0201440:	ec06                	sd	ra,24(sp)
ffffffffc0201442:	e822                	sd	s0,16(sp)
ffffffffc0201444:	e426                	sd	s1,8(sp)
ffffffffc0201446:	842a                	mv	s0,a0
ffffffffc0201448:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc020144a:	9feff0ef          	jal	ra,ffffffffc0200648 <intr_disable>
        pmm_manager->free_pages(base, n); // 释放页
ffffffffc020144e:	000b1797          	auipc	a5,0xb1
ffffffffc0201452:	43a7b783          	ld	a5,1082(a5) # ffffffffc02b2888 <pmm_manager>
ffffffffc0201456:	739c                	ld	a5,32(a5)
ffffffffc0201458:	85a6                	mv	a1,s1
ffffffffc020145a:	8522                	mv	a0,s0
ffffffffc020145c:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag); // 恢复中断状态
}
ffffffffc020145e:	6442                	ld	s0,16(sp)
ffffffffc0201460:	60e2                	ld	ra,24(sp)
ffffffffc0201462:	64a2                	ld	s1,8(sp)
ffffffffc0201464:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201466:	9dcff06f          	j	ffffffffc0200642 <intr_enable>

ffffffffc020146a <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020146a:	100027f3          	csrr	a5,sstatus
ffffffffc020146e:	8b89                	andi	a5,a5,2
ffffffffc0201470:	e799                	bnez	a5,ffffffffc020147e <nr_free_pages+0x14>
size_t nr_free_pages(void) {
    size_t ret; // 定义返回值变量
    bool intr_flag; // 定义中断标志变量
    local_intr_save(intr_flag); // 保存当前中断状态
    {
        ret = pmm_manager->nr_free_pages(); // 调用pmm_manager的nr_free_pages方法获取空闲页数
ffffffffc0201472:	000b1797          	auipc	a5,0xb1
ffffffffc0201476:	4167b783          	ld	a5,1046(a5) # ffffffffc02b2888 <pmm_manager>
ffffffffc020147a:	779c                	ld	a5,40(a5)
ffffffffc020147c:	8782                	jr	a5
size_t nr_free_pages(void) {
ffffffffc020147e:	1141                	addi	sp,sp,-16
ffffffffc0201480:	e406                	sd	ra,8(sp)
ffffffffc0201482:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0201484:	9c4ff0ef          	jal	ra,ffffffffc0200648 <intr_disable>
        ret = pmm_manager->nr_free_pages(); // 调用pmm_manager的nr_free_pages方法获取空闲页数
ffffffffc0201488:	000b1797          	auipc	a5,0xb1
ffffffffc020148c:	4007b783          	ld	a5,1024(a5) # ffffffffc02b2888 <pmm_manager>
ffffffffc0201490:	779c                	ld	a5,40(a5)
ffffffffc0201492:	9782                	jalr	a5
ffffffffc0201494:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201496:	9acff0ef          	jal	ra,ffffffffc0200642 <intr_enable>
    }
    local_intr_restore(intr_flag); // 恢复之前保存的中断状态
    return ret; // 返回空闲页数
}
ffffffffc020149a:	60a2                	ld	ra,8(sp)
ffffffffc020149c:	8522                	mv	a0,s0
ffffffffc020149e:	6402                	ld	s0,0(sp)
ffffffffc02014a0:	0141                	addi	sp,sp,16
ffffffffc02014a2:	8082                	ret

ffffffffc02014a4 <get_pte>:
//  pgdir:  页目录表的内核虚拟基地址
//  la:     需要映射的线性地址
//  create: 一个逻辑值，决定是否为页表分配一页
// 返回值: 该页表项的内核虚拟地址
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
    pde_t *pdep1 = &pgdir[PDX1(la)]; // 获取一级页目录项的地址
ffffffffc02014a4:	01e5d793          	srli	a5,a1,0x1e
ffffffffc02014a8:	1ff7f793          	andi	a5,a5,511
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc02014ac:	7139                	addi	sp,sp,-64
    pde_t *pdep1 = &pgdir[PDX1(la)]; // 获取一级页目录项的地址
ffffffffc02014ae:	078e                	slli	a5,a5,0x3
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc02014b0:	f426                	sd	s1,40(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)]; // 获取一级页目录项的地址
ffffffffc02014b2:	00f504b3          	add	s1,a0,a5
    if (!(*pdep1 & PTE_V)) { // 如果一级页目录项无效
ffffffffc02014b6:	6094                	ld	a3,0(s1)
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc02014b8:	f04a                	sd	s2,32(sp)
ffffffffc02014ba:	ec4e                	sd	s3,24(sp)
ffffffffc02014bc:	e852                	sd	s4,16(sp)
ffffffffc02014be:	fc06                	sd	ra,56(sp)
ffffffffc02014c0:	f822                	sd	s0,48(sp)
ffffffffc02014c2:	e456                	sd	s5,8(sp)
ffffffffc02014c4:	e05a                	sd	s6,0(sp)
    if (!(*pdep1 & PTE_V)) { // 如果一级页目录项无效
ffffffffc02014c6:	0016f793          	andi	a5,a3,1
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc02014ca:	892e                	mv	s2,a1
ffffffffc02014cc:	89b2                	mv	s3,a2
ffffffffc02014ce:	000b1a17          	auipc	s4,0xb1
ffffffffc02014d2:	3aaa0a13          	addi	s4,s4,938 # ffffffffc02b2878 <npage>
    if (!(*pdep1 & PTE_V)) { // 如果一级页目录项无效
ffffffffc02014d6:	e7b5                	bnez	a5,ffffffffc0201542 <get_pte+0x9e>
        struct Page *page; // 定义一个页指针
        if (!create || (page = alloc_page()) == NULL) { // 如果不需要创建或分配页失败
ffffffffc02014d8:	12060b63          	beqz	a2,ffffffffc020160e <get_pte+0x16a>
ffffffffc02014dc:	4505                	li	a0,1
ffffffffc02014de:	ebbff0ef          	jal	ra,ffffffffc0201398 <alloc_pages>
ffffffffc02014e2:	842a                	mv	s0,a0
ffffffffc02014e4:	12050563          	beqz	a0,ffffffffc020160e <get_pte+0x16a>
    return page - pages + nbase;
ffffffffc02014e8:	000b1b17          	auipc	s6,0xb1
ffffffffc02014ec:	398b0b13          	addi	s6,s6,920 # ffffffffc02b2880 <pages>
ffffffffc02014f0:	000b3503          	ld	a0,0(s6)
ffffffffc02014f4:	00080ab7          	lui	s5,0x80
            return NULL; // 返回NULL
        }
        set_page_ref(page, 1); // 设置页的引用计数为1
        uintptr_t pa = page2pa(page); // 获取页的物理地址
        memset(KADDR(pa), 0, PGSIZE); // 将页的内容清零
ffffffffc02014f8:	000b1a17          	auipc	s4,0xb1
ffffffffc02014fc:	380a0a13          	addi	s4,s4,896 # ffffffffc02b2878 <npage>
ffffffffc0201500:	40a40533          	sub	a0,s0,a0
ffffffffc0201504:	8519                	srai	a0,a0,0x6
ffffffffc0201506:	9556                	add	a0,a0,s5
ffffffffc0201508:	000a3703          	ld	a4,0(s4)
ffffffffc020150c:	00c51793          	slli	a5,a0,0xc
    return page->ref;
}

static inline void
set_page_ref(struct Page *page, int val) {
    page->ref = val;
ffffffffc0201510:	4685                	li	a3,1
ffffffffc0201512:	c014                	sw	a3,0(s0)
ffffffffc0201514:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201516:	0532                	slli	a0,a0,0xc
ffffffffc0201518:	14e7f263          	bgeu	a5,a4,ffffffffc020165c <get_pte+0x1b8>
ffffffffc020151c:	000b1797          	auipc	a5,0xb1
ffffffffc0201520:	3747b783          	ld	a5,884(a5) # ffffffffc02b2890 <va_pa_offset>
ffffffffc0201524:	6605                	lui	a2,0x1
ffffffffc0201526:	4581                	li	a1,0
ffffffffc0201528:	953e                	add	a0,a0,a5
ffffffffc020152a:	621040ef          	jal	ra,ffffffffc020634a <memset>
    return page - pages + nbase;
ffffffffc020152e:	000b3683          	ld	a3,0(s6)
ffffffffc0201532:	40d406b3          	sub	a3,s0,a3
ffffffffc0201536:	8699                	srai	a3,a3,0x6
ffffffffc0201538:	96d6                	add	a3,a3,s5
  asm volatile("sfence.vma");
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type) {
  return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc020153a:	06aa                	slli	a3,a3,0xa
ffffffffc020153c:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V); // 创建一级页目录项
ffffffffc0201540:	e094                	sd	a3,0(s1)
    }

    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)]; // 获取二级页目录项的地址
ffffffffc0201542:	77fd                	lui	a5,0xfffff
ffffffffc0201544:	068a                	slli	a3,a3,0x2
ffffffffc0201546:	000a3703          	ld	a4,0(s4)
ffffffffc020154a:	8efd                	and	a3,a3,a5
ffffffffc020154c:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201550:	0ce7f163          	bgeu	a5,a4,ffffffffc0201612 <get_pte+0x16e>
ffffffffc0201554:	000b1a97          	auipc	s5,0xb1
ffffffffc0201558:	33ca8a93          	addi	s5,s5,828 # ffffffffc02b2890 <va_pa_offset>
ffffffffc020155c:	000ab403          	ld	s0,0(s5)
ffffffffc0201560:	01595793          	srli	a5,s2,0x15
ffffffffc0201564:	1ff7f793          	andi	a5,a5,511
ffffffffc0201568:	96a2                	add	a3,a3,s0
ffffffffc020156a:	00379413          	slli	s0,a5,0x3
ffffffffc020156e:	9436                	add	s0,s0,a3
    if (!(*pdep0 & PTE_V)) { // 如果二级页目录项无效
ffffffffc0201570:	6014                	ld	a3,0(s0)
ffffffffc0201572:	0016f793          	andi	a5,a3,1
ffffffffc0201576:	e3ad                	bnez	a5,ffffffffc02015d8 <get_pte+0x134>
        struct Page *page; // 定义一个页指针
        if (!create || (page = alloc_page()) == NULL) { // 如果不需要创建或分配页失败
ffffffffc0201578:	08098b63          	beqz	s3,ffffffffc020160e <get_pte+0x16a>
ffffffffc020157c:	4505                	li	a0,1
ffffffffc020157e:	e1bff0ef          	jal	ra,ffffffffc0201398 <alloc_pages>
ffffffffc0201582:	84aa                	mv	s1,a0
ffffffffc0201584:	c549                	beqz	a0,ffffffffc020160e <get_pte+0x16a>
    return page - pages + nbase;
ffffffffc0201586:	000b1b17          	auipc	s6,0xb1
ffffffffc020158a:	2fab0b13          	addi	s6,s6,762 # ffffffffc02b2880 <pages>
ffffffffc020158e:	000b3503          	ld	a0,0(s6)
ffffffffc0201592:	000809b7          	lui	s3,0x80
            return NULL; // 返回NULL
        }
        set_page_ref(page, 1); // 设置页的引用计数为1
        uintptr_t pa = page2pa(page); // 获取页的物理地址
        memset(KADDR(pa), 0, PGSIZE); // 将页的内容清零
ffffffffc0201596:	000a3703          	ld	a4,0(s4)
ffffffffc020159a:	40a48533          	sub	a0,s1,a0
ffffffffc020159e:	8519                	srai	a0,a0,0x6
ffffffffc02015a0:	954e                	add	a0,a0,s3
ffffffffc02015a2:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc02015a6:	4685                	li	a3,1
ffffffffc02015a8:	c094                	sw	a3,0(s1)
ffffffffc02015aa:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc02015ac:	0532                	slli	a0,a0,0xc
ffffffffc02015ae:	08e7fa63          	bgeu	a5,a4,ffffffffc0201642 <get_pte+0x19e>
ffffffffc02015b2:	000ab783          	ld	a5,0(s5)
ffffffffc02015b6:	6605                	lui	a2,0x1
ffffffffc02015b8:	4581                	li	a1,0
ffffffffc02015ba:	953e                	add	a0,a0,a5
ffffffffc02015bc:	58f040ef          	jal	ra,ffffffffc020634a <memset>
    return page - pages + nbase;
ffffffffc02015c0:	000b3683          	ld	a3,0(s6)
ffffffffc02015c4:	40d486b3          	sub	a3,s1,a3
ffffffffc02015c8:	8699                	srai	a3,a3,0x6
ffffffffc02015ca:	96ce                	add	a3,a3,s3
  return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc02015cc:	06aa                	slli	a3,a3,0xa
ffffffffc02015ce:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V); // 创建二级页目录项
ffffffffc02015d2:	e014                	sd	a3,0(s0)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)]; // 返回页表项的地址
ffffffffc02015d4:	000a3703          	ld	a4,0(s4)
ffffffffc02015d8:	068a                	slli	a3,a3,0x2
ffffffffc02015da:	757d                	lui	a0,0xfffff
ffffffffc02015dc:	8ee9                	and	a3,a3,a0
ffffffffc02015de:	00c6d793          	srli	a5,a3,0xc
ffffffffc02015e2:	04e7f463          	bgeu	a5,a4,ffffffffc020162a <get_pte+0x186>
ffffffffc02015e6:	000ab503          	ld	a0,0(s5)
ffffffffc02015ea:	00c95913          	srli	s2,s2,0xc
ffffffffc02015ee:	1ff97913          	andi	s2,s2,511
ffffffffc02015f2:	96aa                	add	a3,a3,a0
ffffffffc02015f4:	00391513          	slli	a0,s2,0x3
ffffffffc02015f8:	9536                	add	a0,a0,a3
}
ffffffffc02015fa:	70e2                	ld	ra,56(sp)
ffffffffc02015fc:	7442                	ld	s0,48(sp)
ffffffffc02015fe:	74a2                	ld	s1,40(sp)
ffffffffc0201600:	7902                	ld	s2,32(sp)
ffffffffc0201602:	69e2                	ld	s3,24(sp)
ffffffffc0201604:	6a42                	ld	s4,16(sp)
ffffffffc0201606:	6aa2                	ld	s5,8(sp)
ffffffffc0201608:	6b02                	ld	s6,0(sp)
ffffffffc020160a:	6121                	addi	sp,sp,64
ffffffffc020160c:	8082                	ret
            return NULL; // 返回NULL
ffffffffc020160e:	4501                	li	a0,0
ffffffffc0201610:	b7ed                	j	ffffffffc02015fa <get_pte+0x156>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)]; // 获取二级页目录项的地址
ffffffffc0201612:	00006617          	auipc	a2,0x6
ffffffffc0201616:	bd660613          	addi	a2,a2,-1066 # ffffffffc02071e8 <commands+0x7c8>
ffffffffc020161a:	0de00593          	li	a1,222
ffffffffc020161e:	00006517          	auipc	a0,0x6
ffffffffc0201622:	c9250513          	addi	a0,a0,-878 # ffffffffc02072b0 <commands+0x890>
ffffffffc0201626:	be3fe0ef          	jal	ra,ffffffffc0200208 <__panic>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)]; // 返回页表项的地址
ffffffffc020162a:	00006617          	auipc	a2,0x6
ffffffffc020162e:	bbe60613          	addi	a2,a2,-1090 # ffffffffc02071e8 <commands+0x7c8>
ffffffffc0201632:	0e900593          	li	a1,233
ffffffffc0201636:	00006517          	auipc	a0,0x6
ffffffffc020163a:	c7a50513          	addi	a0,a0,-902 # ffffffffc02072b0 <commands+0x890>
ffffffffc020163e:	bcbfe0ef          	jal	ra,ffffffffc0200208 <__panic>
        memset(KADDR(pa), 0, PGSIZE); // 将页的内容清零
ffffffffc0201642:	86aa                	mv	a3,a0
ffffffffc0201644:	00006617          	auipc	a2,0x6
ffffffffc0201648:	ba460613          	addi	a2,a2,-1116 # ffffffffc02071e8 <commands+0x7c8>
ffffffffc020164c:	0e600593          	li	a1,230
ffffffffc0201650:	00006517          	auipc	a0,0x6
ffffffffc0201654:	c6050513          	addi	a0,a0,-928 # ffffffffc02072b0 <commands+0x890>
ffffffffc0201658:	bb1fe0ef          	jal	ra,ffffffffc0200208 <__panic>
        memset(KADDR(pa), 0, PGSIZE); // 将页的内容清零
ffffffffc020165c:	86aa                	mv	a3,a0
ffffffffc020165e:	00006617          	auipc	a2,0x6
ffffffffc0201662:	b8a60613          	addi	a2,a2,-1142 # ffffffffc02071e8 <commands+0x7c8>
ffffffffc0201666:	0da00593          	li	a1,218
ffffffffc020166a:	00006517          	auipc	a0,0x6
ffffffffc020166e:	c4650513          	addi	a0,a0,-954 # ffffffffc02072b0 <commands+0x890>
ffffffffc0201672:	b97fe0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0201676 <get_page>:

// get_page - 使用页目录表pgdir获取线性地址la对应的Page结构
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
ffffffffc0201676:	1141                	addi	sp,sp,-16
ffffffffc0201678:	e022                	sd	s0,0(sp)
ffffffffc020167a:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0); // 获取页表项
ffffffffc020167c:	4601                	li	a2,0
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
ffffffffc020167e:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0); // 获取页表项
ffffffffc0201680:	e25ff0ef          	jal	ra,ffffffffc02014a4 <get_pte>
    if (ptep_store != NULL) { // 如果ptep_store不为空
ffffffffc0201684:	c011                	beqz	s0,ffffffffc0201688 <get_page+0x12>
        *ptep_store = ptep; // 将页表项地址存储到ptep_store中
ffffffffc0201686:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V) { // 如果页表项有效
ffffffffc0201688:	c511                	beqz	a0,ffffffffc0201694 <get_page+0x1e>
ffffffffc020168a:	611c                	ld	a5,0(a0)
        return pte2page(*ptep); // 返回页表项对应的Page结构
    }
    return NULL; // 返回NULL
ffffffffc020168c:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V) { // 如果页表项有效
ffffffffc020168e:	0017f713          	andi	a4,a5,1
ffffffffc0201692:	e709                	bnez	a4,ffffffffc020169c <get_page+0x26>
}
ffffffffc0201694:	60a2                	ld	ra,8(sp)
ffffffffc0201696:	6402                	ld	s0,0(sp)
ffffffffc0201698:	0141                	addi	sp,sp,16
ffffffffc020169a:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc020169c:	078a                	slli	a5,a5,0x2
ffffffffc020169e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02016a0:	000b1717          	auipc	a4,0xb1
ffffffffc02016a4:	1d873703          	ld	a4,472(a4) # ffffffffc02b2878 <npage>
ffffffffc02016a8:	00e7ff63          	bgeu	a5,a4,ffffffffc02016c6 <get_page+0x50>
ffffffffc02016ac:	60a2                	ld	ra,8(sp)
ffffffffc02016ae:	6402                	ld	s0,0(sp)
    return &pages[PPN(pa) - nbase];
ffffffffc02016b0:	fff80537          	lui	a0,0xfff80
ffffffffc02016b4:	97aa                	add	a5,a5,a0
ffffffffc02016b6:	079a                	slli	a5,a5,0x6
ffffffffc02016b8:	000b1517          	auipc	a0,0xb1
ffffffffc02016bc:	1c853503          	ld	a0,456(a0) # ffffffffc02b2880 <pages>
ffffffffc02016c0:	953e                	add	a0,a0,a5
ffffffffc02016c2:	0141                	addi	sp,sp,16
ffffffffc02016c4:	8082                	ret
ffffffffc02016c6:	c9bff0ef          	jal	ra,ffffffffc0201360 <pa2page.part.0>

ffffffffc02016ca <unmap_range>:
        *ptep = 0;                  //(5) 清除二级页表项
        tlb_invalidate(pgdir, la);  //(6) 刷新TLB
    }
}

void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end) {
ffffffffc02016ca:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0); // 确认起始地址和结束地址是页大小的整数倍
ffffffffc02016cc:	00c5e7b3          	or	a5,a1,a2
void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end) {
ffffffffc02016d0:	f486                	sd	ra,104(sp)
ffffffffc02016d2:	f0a2                	sd	s0,96(sp)
ffffffffc02016d4:	eca6                	sd	s1,88(sp)
ffffffffc02016d6:	e8ca                	sd	s2,80(sp)
ffffffffc02016d8:	e4ce                	sd	s3,72(sp)
ffffffffc02016da:	e0d2                	sd	s4,64(sp)
ffffffffc02016dc:	fc56                	sd	s5,56(sp)
ffffffffc02016de:	f85a                	sd	s6,48(sp)
ffffffffc02016e0:	f45e                	sd	s7,40(sp)
ffffffffc02016e2:	f062                	sd	s8,32(sp)
ffffffffc02016e4:	ec66                	sd	s9,24(sp)
ffffffffc02016e6:	e86a                	sd	s10,16(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0); // 确认起始地址和结束地址是页大小的整数倍
ffffffffc02016e8:	17d2                	slli	a5,a5,0x34
ffffffffc02016ea:	e3ed                	bnez	a5,ffffffffc02017cc <unmap_range+0x102>
    assert(USER_ACCESS(start, end)); // 确认起始地址和结束地址在用户访问范围内
ffffffffc02016ec:	002007b7          	lui	a5,0x200
ffffffffc02016f0:	842e                	mv	s0,a1
ffffffffc02016f2:	0ef5ed63          	bltu	a1,a5,ffffffffc02017ec <unmap_range+0x122>
ffffffffc02016f6:	8932                	mv	s2,a2
ffffffffc02016f8:	0ec5fa63          	bgeu	a1,a2,ffffffffc02017ec <unmap_range+0x122>
ffffffffc02016fc:	4785                	li	a5,1
ffffffffc02016fe:	07fe                	slli	a5,a5,0x1f
ffffffffc0201700:	0ec7e663          	bltu	a5,a2,ffffffffc02017ec <unmap_range+0x122>
ffffffffc0201704:	89aa                	mv	s3,a0
            continue; // 继续下一次循环
        }
        if (*ptep != 0) { // 如果页表项不为空
            page_remove_pte(pgdir, start, ptep); // 移除页表项
        }
        start += PGSIZE; // 增加起始地址，移动到下一页
ffffffffc0201706:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage) {
ffffffffc0201708:	000b1c97          	auipc	s9,0xb1
ffffffffc020170c:	170c8c93          	addi	s9,s9,368 # ffffffffc02b2878 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0201710:	000b1c17          	auipc	s8,0xb1
ffffffffc0201714:	170c0c13          	addi	s8,s8,368 # ffffffffc02b2880 <pages>
ffffffffc0201718:	fff80bb7          	lui	s7,0xfff80
        pmm_manager->free_pages(base, n); // 释放页
ffffffffc020171c:	000b1d17          	auipc	s10,0xb1
ffffffffc0201720:	16cd0d13          	addi	s10,s10,364 # ffffffffc02b2888 <pmm_manager>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE); // 将起始地址向下取整到页表大小的整数倍
ffffffffc0201724:	00200b37          	lui	s6,0x200
ffffffffc0201728:	ffe00ab7          	lui	s5,0xffe00
        pte_t *ptep = get_pte(pgdir, start, 0); // 获取页表项指针
ffffffffc020172c:	4601                	li	a2,0
ffffffffc020172e:	85a2                	mv	a1,s0
ffffffffc0201730:	854e                	mv	a0,s3
ffffffffc0201732:	d73ff0ef          	jal	ra,ffffffffc02014a4 <get_pte>
ffffffffc0201736:	84aa                	mv	s1,a0
        if (ptep == NULL) { // 如果页表项指针为空
ffffffffc0201738:	cd29                	beqz	a0,ffffffffc0201792 <unmap_range+0xc8>
        if (*ptep != 0) { // 如果页表项不为空
ffffffffc020173a:	611c                	ld	a5,0(a0)
ffffffffc020173c:	e395                	bnez	a5,ffffffffc0201760 <unmap_range+0x96>
        start += PGSIZE; // 增加起始地址，移动到下一页
ffffffffc020173e:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end); // 循环直到起始地址为0或大于结束地址
ffffffffc0201740:	ff2466e3          	bltu	s0,s2,ffffffffc020172c <unmap_range+0x62>
}
ffffffffc0201744:	70a6                	ld	ra,104(sp)
ffffffffc0201746:	7406                	ld	s0,96(sp)
ffffffffc0201748:	64e6                	ld	s1,88(sp)
ffffffffc020174a:	6946                	ld	s2,80(sp)
ffffffffc020174c:	69a6                	ld	s3,72(sp)
ffffffffc020174e:	6a06                	ld	s4,64(sp)
ffffffffc0201750:	7ae2                	ld	s5,56(sp)
ffffffffc0201752:	7b42                	ld	s6,48(sp)
ffffffffc0201754:	7ba2                	ld	s7,40(sp)
ffffffffc0201756:	7c02                	ld	s8,32(sp)
ffffffffc0201758:	6ce2                	ld	s9,24(sp)
ffffffffc020175a:	6d42                	ld	s10,16(sp)
ffffffffc020175c:	6165                	addi	sp,sp,112
ffffffffc020175e:	8082                	ret
    if (*ptep & PTE_V) {  //(1) 检查该页表项是否有效
ffffffffc0201760:	0017f713          	andi	a4,a5,1
ffffffffc0201764:	df69                	beqz	a4,ffffffffc020173e <unmap_range+0x74>
    if (PPN(pa) >= npage) {
ffffffffc0201766:	000cb703          	ld	a4,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc020176a:	078a                	slli	a5,a5,0x2
ffffffffc020176c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020176e:	08e7ff63          	bgeu	a5,a4,ffffffffc020180c <unmap_range+0x142>
    return &pages[PPN(pa) - nbase];
ffffffffc0201772:	000c3503          	ld	a0,0(s8)
ffffffffc0201776:	97de                	add	a5,a5,s7
ffffffffc0201778:	079a                	slli	a5,a5,0x6
ffffffffc020177a:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc020177c:	411c                	lw	a5,0(a0)
ffffffffc020177e:	fff7871b          	addiw	a4,a5,-1
ffffffffc0201782:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc0201784:	cf11                	beqz	a4,ffffffffc02017a0 <unmap_range+0xd6>
        *ptep = 0;                  //(5) 清除二级页表项
ffffffffc0201786:	0004b023          	sd	zero,0(s1)
    return 0; // 返回0
}

// 使TLB条目无效，但仅当正在编辑的页表是处理器当前使用的页表时
void tlb_invalidate(pde_t *pgdir, uintptr_t la) {
    asm volatile("sfence.vma %0" : : "r"(la)); // 执行sfence.vma指令使TLB无效
ffffffffc020178a:	12040073          	sfence.vma	s0
        start += PGSIZE; // 增加起始地址，移动到下一页
ffffffffc020178e:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end); // 循环直到起始地址为0或大于结束地址
ffffffffc0201790:	bf45                	j	ffffffffc0201740 <unmap_range+0x76>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE); // 将起始地址向下取整到页表大小的整数倍
ffffffffc0201792:	945a                	add	s0,s0,s6
ffffffffc0201794:	01547433          	and	s0,s0,s5
    } while (start != 0 && start < end); // 循环直到起始地址为0或大于结束地址
ffffffffc0201798:	d455                	beqz	s0,ffffffffc0201744 <unmap_range+0x7a>
ffffffffc020179a:	f92469e3          	bltu	s0,s2,ffffffffc020172c <unmap_range+0x62>
ffffffffc020179e:	b75d                	j	ffffffffc0201744 <unmap_range+0x7a>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02017a0:	100027f3          	csrr	a5,sstatus
ffffffffc02017a4:	8b89                	andi	a5,a5,2
ffffffffc02017a6:	e799                	bnez	a5,ffffffffc02017b4 <unmap_range+0xea>
        pmm_manager->free_pages(base, n); // 释放页
ffffffffc02017a8:	000d3783          	ld	a5,0(s10)
ffffffffc02017ac:	4585                	li	a1,1
ffffffffc02017ae:	739c                	ld	a5,32(a5)
ffffffffc02017b0:	9782                	jalr	a5
    if (flag) {
ffffffffc02017b2:	bfd1                	j	ffffffffc0201786 <unmap_range+0xbc>
ffffffffc02017b4:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02017b6:	e93fe0ef          	jal	ra,ffffffffc0200648 <intr_disable>
ffffffffc02017ba:	000d3783          	ld	a5,0(s10)
ffffffffc02017be:	6522                	ld	a0,8(sp)
ffffffffc02017c0:	4585                	li	a1,1
ffffffffc02017c2:	739c                	ld	a5,32(a5)
ffffffffc02017c4:	9782                	jalr	a5
        intr_enable();
ffffffffc02017c6:	e7dfe0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc02017ca:	bf75                	j	ffffffffc0201786 <unmap_range+0xbc>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0); // 确认起始地址和结束地址是页大小的整数倍
ffffffffc02017cc:	00006697          	auipc	a3,0x6
ffffffffc02017d0:	95468693          	addi	a3,a3,-1708 # ffffffffc0207120 <commands+0x700>
ffffffffc02017d4:	00005617          	auipc	a2,0x5
ffffffffc02017d8:	65c60613          	addi	a2,a2,1628 # ffffffffc0206e30 <commands+0x410>
ffffffffc02017dc:	10a00593          	li	a1,266
ffffffffc02017e0:	00006517          	auipc	a0,0x6
ffffffffc02017e4:	ad050513          	addi	a0,a0,-1328 # ffffffffc02072b0 <commands+0x890>
ffffffffc02017e8:	a21fe0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(USER_ACCESS(start, end)); // 确认起始地址和结束地址在用户访问范围内
ffffffffc02017ec:	00006697          	auipc	a3,0x6
ffffffffc02017f0:	97468693          	addi	a3,a3,-1676 # ffffffffc0207160 <commands+0x740>
ffffffffc02017f4:	00005617          	auipc	a2,0x5
ffffffffc02017f8:	63c60613          	addi	a2,a2,1596 # ffffffffc0206e30 <commands+0x410>
ffffffffc02017fc:	10b00593          	li	a1,267
ffffffffc0201800:	00006517          	auipc	a0,0x6
ffffffffc0201804:	ab050513          	addi	a0,a0,-1360 # ffffffffc02072b0 <commands+0x890>
ffffffffc0201808:	a01fe0ef          	jal	ra,ffffffffc0200208 <__panic>
ffffffffc020180c:	b55ff0ef          	jal	ra,ffffffffc0201360 <pa2page.part.0>

ffffffffc0201810 <exit_range>:
void exit_range(pde_t *pgdir, uintptr_t start, uintptr_t end) {
ffffffffc0201810:	7119                	addi	sp,sp,-128
    assert(start % PGSIZE == 0 && end % PGSIZE == 0); // 确认起始地址和结束地址是页大小的整数倍
ffffffffc0201812:	00c5e7b3          	or	a5,a1,a2
void exit_range(pde_t *pgdir, uintptr_t start, uintptr_t end) {
ffffffffc0201816:	fc86                	sd	ra,120(sp)
ffffffffc0201818:	f8a2                	sd	s0,112(sp)
ffffffffc020181a:	f4a6                	sd	s1,104(sp)
ffffffffc020181c:	f0ca                	sd	s2,96(sp)
ffffffffc020181e:	ecce                	sd	s3,88(sp)
ffffffffc0201820:	e8d2                	sd	s4,80(sp)
ffffffffc0201822:	e4d6                	sd	s5,72(sp)
ffffffffc0201824:	e0da                	sd	s6,64(sp)
ffffffffc0201826:	fc5e                	sd	s7,56(sp)
ffffffffc0201828:	f862                	sd	s8,48(sp)
ffffffffc020182a:	f466                	sd	s9,40(sp)
ffffffffc020182c:	f06a                	sd	s10,32(sp)
ffffffffc020182e:	ec6e                	sd	s11,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0); // 确认起始地址和结束地址是页大小的整数倍
ffffffffc0201830:	17d2                	slli	a5,a5,0x34
ffffffffc0201832:	20079a63          	bnez	a5,ffffffffc0201a46 <exit_range+0x236>
    assert(USER_ACCESS(start, end)); // 确认起始地址和结束地址在用户访问范围内
ffffffffc0201836:	002007b7          	lui	a5,0x200
ffffffffc020183a:	24f5e463          	bltu	a1,a5,ffffffffc0201a82 <exit_range+0x272>
ffffffffc020183e:	8ab2                	mv	s5,a2
ffffffffc0201840:	24c5f163          	bgeu	a1,a2,ffffffffc0201a82 <exit_range+0x272>
ffffffffc0201844:	4785                	li	a5,1
ffffffffc0201846:	07fe                	slli	a5,a5,0x1f
ffffffffc0201848:	22c7ed63          	bltu	a5,a2,ffffffffc0201a82 <exit_range+0x272>
    d1start = ROUNDDOWN(start, PDSIZE); // 将起始地址向下取整到页目录大小的整数倍
ffffffffc020184c:	c00009b7          	lui	s3,0xc0000
ffffffffc0201850:	0135f9b3          	and	s3,a1,s3
    d0start = ROUNDDOWN(start, PTSIZE); // 将起始地址向下取整到页表大小的整数倍
ffffffffc0201854:	ffe00937          	lui	s2,0xffe00
ffffffffc0201858:	400007b7          	lui	a5,0x40000
    return KADDR(page2pa(page));
ffffffffc020185c:	5cfd                	li	s9,-1
ffffffffc020185e:	8c2a                	mv	s8,a0
ffffffffc0201860:	0125f933          	and	s2,a1,s2
ffffffffc0201864:	99be                	add	s3,s3,a5
    if (PPN(pa) >= npage) {
ffffffffc0201866:	000b1d17          	auipc	s10,0xb1
ffffffffc020186a:	012d0d13          	addi	s10,s10,18 # ffffffffc02b2878 <npage>
    return KADDR(page2pa(page));
ffffffffc020186e:	00ccdc93          	srli	s9,s9,0xc
    return &pages[PPN(pa) - nbase];
ffffffffc0201872:	000b1717          	auipc	a4,0xb1
ffffffffc0201876:	00e70713          	addi	a4,a4,14 # ffffffffc02b2880 <pages>
        pmm_manager->free_pages(base, n); // 释放页
ffffffffc020187a:	000b1d97          	auipc	s11,0xb1
ffffffffc020187e:	00ed8d93          	addi	s11,s11,14 # ffffffffc02b2888 <pmm_manager>
        pde1 = pgdir[PDX1(d1start)]; // 获取一级页目录项
ffffffffc0201882:	c0000437          	lui	s0,0xc0000
ffffffffc0201886:	944e                	add	s0,s0,s3
ffffffffc0201888:	8079                	srli	s0,s0,0x1e
ffffffffc020188a:	1ff47413          	andi	s0,s0,511
ffffffffc020188e:	040e                	slli	s0,s0,0x3
ffffffffc0201890:	9462                	add	s0,s0,s8
ffffffffc0201892:	00043a03          	ld	s4,0(s0) # ffffffffc0000000 <_binary_obj___user_exit_out_size+0xffffffffbfff4ec8>
        if (pde1 & PTE_V) { // 如果一级页目录项有效
ffffffffc0201896:	001a7793          	andi	a5,s4,1
ffffffffc020189a:	eb99                	bnez	a5,ffffffffc02018b0 <exit_range+0xa0>
    } while (d1start != 0 && d1start < end); // 循环直到一级页目录的起始地址为0或大于结束地址
ffffffffc020189c:	12098463          	beqz	s3,ffffffffc02019c4 <exit_range+0x1b4>
ffffffffc02018a0:	400007b7          	lui	a5,0x40000
ffffffffc02018a4:	97ce                	add	a5,a5,s3
ffffffffc02018a6:	894e                	mv	s2,s3
ffffffffc02018a8:	1159fe63          	bgeu	s3,s5,ffffffffc02019c4 <exit_range+0x1b4>
ffffffffc02018ac:	89be                	mv	s3,a5
ffffffffc02018ae:	bfd1                	j	ffffffffc0201882 <exit_range+0x72>
    if (PPN(pa) >= npage) {
ffffffffc02018b0:	000d3783          	ld	a5,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc02018b4:	0a0a                	slli	s4,s4,0x2
ffffffffc02018b6:	00ca5a13          	srli	s4,s4,0xc
    if (PPN(pa) >= npage) {
ffffffffc02018ba:	1cfa7263          	bgeu	s4,a5,ffffffffc0201a7e <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc02018be:	fff80637          	lui	a2,0xfff80
ffffffffc02018c2:	9652                	add	a2,a2,s4
    return page - pages + nbase;
ffffffffc02018c4:	000806b7          	lui	a3,0x80
ffffffffc02018c8:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc02018ca:	0196f5b3          	and	a1,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc02018ce:	061a                	slli	a2,a2,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc02018d0:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02018d2:	18f5fa63          	bgeu	a1,a5,ffffffffc0201a66 <exit_range+0x256>
ffffffffc02018d6:	000b1817          	auipc	a6,0xb1
ffffffffc02018da:	fba80813          	addi	a6,a6,-70 # ffffffffc02b2890 <va_pa_offset>
ffffffffc02018de:	00083b03          	ld	s6,0(a6)
            free_pd0 = 1; // 设置释放二级页目录的标志
ffffffffc02018e2:	4b85                	li	s7,1
    return &pages[PPN(pa) - nbase];
ffffffffc02018e4:	fff80e37          	lui	t3,0xfff80
    return KADDR(page2pa(page));
ffffffffc02018e8:	9b36                	add	s6,s6,a3
    return page - pages + nbase;
ffffffffc02018ea:	00080337          	lui	t1,0x80
ffffffffc02018ee:	6885                	lui	a7,0x1
ffffffffc02018f0:	a819                	j	ffffffffc0201906 <exit_range+0xf6>
                    free_pd0 = 0; // 取消释放二级页目录的标志
ffffffffc02018f2:	4b81                	li	s7,0
                d0start += PTSIZE; // 增加二级页目录的起始地址，移动到下一个页表
ffffffffc02018f4:	002007b7          	lui	a5,0x200
ffffffffc02018f8:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end); // 循环直到二级页目录的起始地址为0或大于一级页目录的结束地址或大于结束地址
ffffffffc02018fa:	08090c63          	beqz	s2,ffffffffc0201992 <exit_range+0x182>
ffffffffc02018fe:	09397a63          	bgeu	s2,s3,ffffffffc0201992 <exit_range+0x182>
ffffffffc0201902:	0f597063          	bgeu	s2,s5,ffffffffc02019e2 <exit_range+0x1d2>
                pde0 = pd0[PDX0(d0start)]; // 获取二级页目录项
ffffffffc0201906:	01595493          	srli	s1,s2,0x15
ffffffffc020190a:	1ff4f493          	andi	s1,s1,511
ffffffffc020190e:	048e                	slli	s1,s1,0x3
ffffffffc0201910:	94da                	add	s1,s1,s6
ffffffffc0201912:	609c                	ld	a5,0(s1)
                if (pde0 & PTE_V) { // 如果二级页目录项有效
ffffffffc0201914:	0017f693          	andi	a3,a5,1
ffffffffc0201918:	dee9                	beqz	a3,ffffffffc02018f2 <exit_range+0xe2>
    if (PPN(pa) >= npage) {
ffffffffc020191a:	000d3583          	ld	a1,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc020191e:	078a                	slli	a5,a5,0x2
ffffffffc0201920:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201922:	14b7fe63          	bgeu	a5,a1,ffffffffc0201a7e <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc0201926:	97f2                	add	a5,a5,t3
    return page - pages + nbase;
ffffffffc0201928:	006786b3          	add	a3,a5,t1
    return KADDR(page2pa(page));
ffffffffc020192c:	0196feb3          	and	t4,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc0201930:	00679513          	slli	a0,a5,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc0201934:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0201936:	12bef863          	bgeu	t4,a1,ffffffffc0201a66 <exit_range+0x256>
ffffffffc020193a:	00083783          	ld	a5,0(a6)
ffffffffc020193e:	96be                	add	a3,a3,a5
                    for (int i = 0; i < NPTEENTRY; i++) // 遍历页表项
ffffffffc0201940:	011685b3          	add	a1,a3,a7
                        if (pt[i] & PTE_V) { // 如果页表项有效
ffffffffc0201944:	629c                	ld	a5,0(a3)
ffffffffc0201946:	8b85                	andi	a5,a5,1
ffffffffc0201948:	f7d5                	bnez	a5,ffffffffc02018f4 <exit_range+0xe4>
                    for (int i = 0; i < NPTEENTRY; i++) // 遍历页表项
ffffffffc020194a:	06a1                	addi	a3,a3,8
ffffffffc020194c:	fed59ce3          	bne	a1,a3,ffffffffc0201944 <exit_range+0x134>
    return &pages[PPN(pa) - nbase];
ffffffffc0201950:	631c                	ld	a5,0(a4)
ffffffffc0201952:	953e                	add	a0,a0,a5
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201954:	100027f3          	csrr	a5,sstatus
ffffffffc0201958:	8b89                	andi	a5,a5,2
ffffffffc020195a:	e7d9                	bnez	a5,ffffffffc02019e8 <exit_range+0x1d8>
        pmm_manager->free_pages(base, n); // 释放页
ffffffffc020195c:	000db783          	ld	a5,0(s11)
ffffffffc0201960:	4585                	li	a1,1
ffffffffc0201962:	e032                	sd	a2,0(sp)
ffffffffc0201964:	739c                	ld	a5,32(a5)
ffffffffc0201966:	9782                	jalr	a5
    if (flag) {
ffffffffc0201968:	6602                	ld	a2,0(sp)
ffffffffc020196a:	000b1817          	auipc	a6,0xb1
ffffffffc020196e:	f2680813          	addi	a6,a6,-218 # ffffffffc02b2890 <va_pa_offset>
ffffffffc0201972:	fff80e37          	lui	t3,0xfff80
ffffffffc0201976:	00080337          	lui	t1,0x80
ffffffffc020197a:	6885                	lui	a7,0x1
ffffffffc020197c:	000b1717          	auipc	a4,0xb1
ffffffffc0201980:	f0470713          	addi	a4,a4,-252 # ffffffffc02b2880 <pages>
                        pd0[PDX0(d0start)] = 0; // 清除二级页目录项
ffffffffc0201984:	0004b023          	sd	zero,0(s1)
                d0start += PTSIZE; // 增加二级页目录的起始地址，移动到下一个页表
ffffffffc0201988:	002007b7          	lui	a5,0x200
ffffffffc020198c:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end); // 循环直到二级页目录的起始地址为0或大于一级页目录的结束地址或大于结束地址
ffffffffc020198e:	f60918e3          	bnez	s2,ffffffffc02018fe <exit_range+0xee>
            if (free_pd0) { // 如果可以释放二级页目录
ffffffffc0201992:	f00b85e3          	beqz	s7,ffffffffc020189c <exit_range+0x8c>
    if (PPN(pa) >= npage) {
ffffffffc0201996:	000d3783          	ld	a5,0(s10)
ffffffffc020199a:	0efa7263          	bgeu	s4,a5,ffffffffc0201a7e <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc020199e:	6308                	ld	a0,0(a4)
ffffffffc02019a0:	9532                	add	a0,a0,a2
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02019a2:	100027f3          	csrr	a5,sstatus
ffffffffc02019a6:	8b89                	andi	a5,a5,2
ffffffffc02019a8:	efad                	bnez	a5,ffffffffc0201a22 <exit_range+0x212>
        pmm_manager->free_pages(base, n); // 释放页
ffffffffc02019aa:	000db783          	ld	a5,0(s11)
ffffffffc02019ae:	4585                	li	a1,1
ffffffffc02019b0:	739c                	ld	a5,32(a5)
ffffffffc02019b2:	9782                	jalr	a5
ffffffffc02019b4:	000b1717          	auipc	a4,0xb1
ffffffffc02019b8:	ecc70713          	addi	a4,a4,-308 # ffffffffc02b2880 <pages>
                pgdir[PDX1(d1start)] = 0; // 清除一级页目录项
ffffffffc02019bc:	00043023          	sd	zero,0(s0)
    } while (d1start != 0 && d1start < end); // 循环直到一级页目录的起始地址为0或大于结束地址
ffffffffc02019c0:	ee0990e3          	bnez	s3,ffffffffc02018a0 <exit_range+0x90>
}
ffffffffc02019c4:	70e6                	ld	ra,120(sp)
ffffffffc02019c6:	7446                	ld	s0,112(sp)
ffffffffc02019c8:	74a6                	ld	s1,104(sp)
ffffffffc02019ca:	7906                	ld	s2,96(sp)
ffffffffc02019cc:	69e6                	ld	s3,88(sp)
ffffffffc02019ce:	6a46                	ld	s4,80(sp)
ffffffffc02019d0:	6aa6                	ld	s5,72(sp)
ffffffffc02019d2:	6b06                	ld	s6,64(sp)
ffffffffc02019d4:	7be2                	ld	s7,56(sp)
ffffffffc02019d6:	7c42                	ld	s8,48(sp)
ffffffffc02019d8:	7ca2                	ld	s9,40(sp)
ffffffffc02019da:	7d02                	ld	s10,32(sp)
ffffffffc02019dc:	6de2                	ld	s11,24(sp)
ffffffffc02019de:	6109                	addi	sp,sp,128
ffffffffc02019e0:	8082                	ret
            if (free_pd0) { // 如果可以释放二级页目录
ffffffffc02019e2:	ea0b8fe3          	beqz	s7,ffffffffc02018a0 <exit_range+0x90>
ffffffffc02019e6:	bf45                	j	ffffffffc0201996 <exit_range+0x186>
ffffffffc02019e8:	e032                	sd	a2,0(sp)
        intr_disable();
ffffffffc02019ea:	e42a                	sd	a0,8(sp)
ffffffffc02019ec:	c5dfe0ef          	jal	ra,ffffffffc0200648 <intr_disable>
        pmm_manager->free_pages(base, n); // 释放页
ffffffffc02019f0:	000db783          	ld	a5,0(s11)
ffffffffc02019f4:	6522                	ld	a0,8(sp)
ffffffffc02019f6:	4585                	li	a1,1
ffffffffc02019f8:	739c                	ld	a5,32(a5)
ffffffffc02019fa:	9782                	jalr	a5
        intr_enable();
ffffffffc02019fc:	c47fe0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc0201a00:	6602                	ld	a2,0(sp)
ffffffffc0201a02:	000b1717          	auipc	a4,0xb1
ffffffffc0201a06:	e7e70713          	addi	a4,a4,-386 # ffffffffc02b2880 <pages>
ffffffffc0201a0a:	6885                	lui	a7,0x1
ffffffffc0201a0c:	00080337          	lui	t1,0x80
ffffffffc0201a10:	fff80e37          	lui	t3,0xfff80
ffffffffc0201a14:	000b1817          	auipc	a6,0xb1
ffffffffc0201a18:	e7c80813          	addi	a6,a6,-388 # ffffffffc02b2890 <va_pa_offset>
                        pd0[PDX0(d0start)] = 0; // 清除二级页目录项
ffffffffc0201a1c:	0004b023          	sd	zero,0(s1)
ffffffffc0201a20:	b7a5                	j	ffffffffc0201988 <exit_range+0x178>
ffffffffc0201a22:	e02a                	sd	a0,0(sp)
        intr_disable();
ffffffffc0201a24:	c25fe0ef          	jal	ra,ffffffffc0200648 <intr_disable>
        pmm_manager->free_pages(base, n); // 释放页
ffffffffc0201a28:	000db783          	ld	a5,0(s11)
ffffffffc0201a2c:	6502                	ld	a0,0(sp)
ffffffffc0201a2e:	4585                	li	a1,1
ffffffffc0201a30:	739c                	ld	a5,32(a5)
ffffffffc0201a32:	9782                	jalr	a5
        intr_enable();
ffffffffc0201a34:	c0ffe0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc0201a38:	000b1717          	auipc	a4,0xb1
ffffffffc0201a3c:	e4870713          	addi	a4,a4,-440 # ffffffffc02b2880 <pages>
                pgdir[PDX1(d1start)] = 0; // 清除一级页目录项
ffffffffc0201a40:	00043023          	sd	zero,0(s0)
ffffffffc0201a44:	bfb5                	j	ffffffffc02019c0 <exit_range+0x1b0>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0); // 确认起始地址和结束地址是页大小的整数倍
ffffffffc0201a46:	00005697          	auipc	a3,0x5
ffffffffc0201a4a:	6da68693          	addi	a3,a3,1754 # ffffffffc0207120 <commands+0x700>
ffffffffc0201a4e:	00005617          	auipc	a2,0x5
ffffffffc0201a52:	3e260613          	addi	a2,a2,994 # ffffffffc0206e30 <commands+0x410>
ffffffffc0201a56:	11b00593          	li	a1,283
ffffffffc0201a5a:	00006517          	auipc	a0,0x6
ffffffffc0201a5e:	85650513          	addi	a0,a0,-1962 # ffffffffc02072b0 <commands+0x890>
ffffffffc0201a62:	fa6fe0ef          	jal	ra,ffffffffc0200208 <__panic>
    return KADDR(page2pa(page));
ffffffffc0201a66:	00005617          	auipc	a2,0x5
ffffffffc0201a6a:	78260613          	addi	a2,a2,1922 # ffffffffc02071e8 <commands+0x7c8>
ffffffffc0201a6e:	06900593          	li	a1,105
ffffffffc0201a72:	00005517          	auipc	a0,0x5
ffffffffc0201a76:	72650513          	addi	a0,a0,1830 # ffffffffc0207198 <commands+0x778>
ffffffffc0201a7a:	f8efe0ef          	jal	ra,ffffffffc0200208 <__panic>
ffffffffc0201a7e:	8e3ff0ef          	jal	ra,ffffffffc0201360 <pa2page.part.0>
    assert(USER_ACCESS(start, end)); // 确认起始地址和结束地址在用户访问范围内
ffffffffc0201a82:	00005697          	auipc	a3,0x5
ffffffffc0201a86:	6de68693          	addi	a3,a3,1758 # ffffffffc0207160 <commands+0x740>
ffffffffc0201a8a:	00005617          	auipc	a2,0x5
ffffffffc0201a8e:	3a660613          	addi	a2,a2,934 # ffffffffc0206e30 <commands+0x410>
ffffffffc0201a92:	11c00593          	li	a1,284
ffffffffc0201a96:	00006517          	auipc	a0,0x6
ffffffffc0201a9a:	81a50513          	addi	a0,a0,-2022 # ffffffffc02072b0 <commands+0x890>
ffffffffc0201a9e:	f6afe0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0201aa2 <page_remove>:
void page_remove(pde_t *pgdir, uintptr_t la) {
ffffffffc0201aa2:	7179                	addi	sp,sp,-48
    pte_t *ptep = get_pte(pgdir, la, 0); // 获取页表项
ffffffffc0201aa4:	4601                	li	a2,0
void page_remove(pde_t *pgdir, uintptr_t la) {
ffffffffc0201aa6:	ec26                	sd	s1,24(sp)
ffffffffc0201aa8:	f406                	sd	ra,40(sp)
ffffffffc0201aaa:	f022                	sd	s0,32(sp)
ffffffffc0201aac:	84ae                	mv	s1,a1
    pte_t *ptep = get_pte(pgdir, la, 0); // 获取页表项
ffffffffc0201aae:	9f7ff0ef          	jal	ra,ffffffffc02014a4 <get_pte>
    if (ptep != NULL) { // 如果页表项不为空
ffffffffc0201ab2:	c511                	beqz	a0,ffffffffc0201abe <page_remove+0x1c>
    if (*ptep & PTE_V) {  //(1) 检查该页表项是否有效
ffffffffc0201ab4:	611c                	ld	a5,0(a0)
ffffffffc0201ab6:	842a                	mv	s0,a0
ffffffffc0201ab8:	0017f713          	andi	a4,a5,1
ffffffffc0201abc:	e711                	bnez	a4,ffffffffc0201ac8 <page_remove+0x26>
}
ffffffffc0201abe:	70a2                	ld	ra,40(sp)
ffffffffc0201ac0:	7402                	ld	s0,32(sp)
ffffffffc0201ac2:	64e2                	ld	s1,24(sp)
ffffffffc0201ac4:	6145                	addi	sp,sp,48
ffffffffc0201ac6:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0201ac8:	078a                	slli	a5,a5,0x2
ffffffffc0201aca:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201acc:	000b1717          	auipc	a4,0xb1
ffffffffc0201ad0:	dac73703          	ld	a4,-596(a4) # ffffffffc02b2878 <npage>
ffffffffc0201ad4:	06e7f363          	bgeu	a5,a4,ffffffffc0201b3a <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc0201ad8:	fff80537          	lui	a0,0xfff80
ffffffffc0201adc:	97aa                	add	a5,a5,a0
ffffffffc0201ade:	079a                	slli	a5,a5,0x6
ffffffffc0201ae0:	000b1517          	auipc	a0,0xb1
ffffffffc0201ae4:	da053503          	ld	a0,-608(a0) # ffffffffc02b2880 <pages>
ffffffffc0201ae8:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc0201aea:	411c                	lw	a5,0(a0)
ffffffffc0201aec:	fff7871b          	addiw	a4,a5,-1
ffffffffc0201af0:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc0201af2:	cb11                	beqz	a4,ffffffffc0201b06 <page_remove+0x64>
        *ptep = 0;                  //(5) 清除二级页表项
ffffffffc0201af4:	00043023          	sd	zero,0(s0)
    asm volatile("sfence.vma %0" : : "r"(la)); // 执行sfence.vma指令使TLB无效
ffffffffc0201af8:	12048073          	sfence.vma	s1
}
ffffffffc0201afc:	70a2                	ld	ra,40(sp)
ffffffffc0201afe:	7402                	ld	s0,32(sp)
ffffffffc0201b00:	64e2                	ld	s1,24(sp)
ffffffffc0201b02:	6145                	addi	sp,sp,48
ffffffffc0201b04:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201b06:	100027f3          	csrr	a5,sstatus
ffffffffc0201b0a:	8b89                	andi	a5,a5,2
ffffffffc0201b0c:	eb89                	bnez	a5,ffffffffc0201b1e <page_remove+0x7c>
        pmm_manager->free_pages(base, n); // 释放页
ffffffffc0201b0e:	000b1797          	auipc	a5,0xb1
ffffffffc0201b12:	d7a7b783          	ld	a5,-646(a5) # ffffffffc02b2888 <pmm_manager>
ffffffffc0201b16:	739c                	ld	a5,32(a5)
ffffffffc0201b18:	4585                	li	a1,1
ffffffffc0201b1a:	9782                	jalr	a5
    if (flag) {
ffffffffc0201b1c:	bfe1                	j	ffffffffc0201af4 <page_remove+0x52>
        intr_disable();
ffffffffc0201b1e:	e42a                	sd	a0,8(sp)
ffffffffc0201b20:	b29fe0ef          	jal	ra,ffffffffc0200648 <intr_disable>
ffffffffc0201b24:	000b1797          	auipc	a5,0xb1
ffffffffc0201b28:	d647b783          	ld	a5,-668(a5) # ffffffffc02b2888 <pmm_manager>
ffffffffc0201b2c:	739c                	ld	a5,32(a5)
ffffffffc0201b2e:	6522                	ld	a0,8(sp)
ffffffffc0201b30:	4585                	li	a1,1
ffffffffc0201b32:	9782                	jalr	a5
        intr_enable();
ffffffffc0201b34:	b0ffe0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc0201b38:	bf75                	j	ffffffffc0201af4 <page_remove+0x52>
ffffffffc0201b3a:	827ff0ef          	jal	ra,ffffffffc0201360 <pa2page.part.0>

ffffffffc0201b3e <page_insert>:
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc0201b3e:	7139                	addi	sp,sp,-64
ffffffffc0201b40:	e852                	sd	s4,16(sp)
ffffffffc0201b42:	8a32                	mv	s4,a2
ffffffffc0201b44:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1); // 获取页表项指针，如果不存在则创建
ffffffffc0201b46:	4605                	li	a2,1
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc0201b48:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1); // 获取页表项指针，如果不存在则创建
ffffffffc0201b4a:	85d2                	mv	a1,s4
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc0201b4c:	f426                	sd	s1,40(sp)
ffffffffc0201b4e:	fc06                	sd	ra,56(sp)
ffffffffc0201b50:	f04a                	sd	s2,32(sp)
ffffffffc0201b52:	ec4e                	sd	s3,24(sp)
ffffffffc0201b54:	e456                	sd	s5,8(sp)
ffffffffc0201b56:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1); // 获取页表项指针，如果不存在则创建
ffffffffc0201b58:	94dff0ef          	jal	ra,ffffffffc02014a4 <get_pte>
    if (ptep == NULL) { // 如果页表项指针为空
ffffffffc0201b5c:	c961                	beqz	a0,ffffffffc0201c2c <page_insert+0xee>
    page->ref += 1;
ffffffffc0201b5e:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V) { // 如果页表项有效
ffffffffc0201b60:	611c                	ld	a5,0(a0)
ffffffffc0201b62:	89aa                	mv	s3,a0
ffffffffc0201b64:	0016871b          	addiw	a4,a3,1
ffffffffc0201b68:	c018                	sw	a4,0(s0)
ffffffffc0201b6a:	0017f713          	andi	a4,a5,1
ffffffffc0201b6e:	ef05                	bnez	a4,ffffffffc0201ba6 <page_insert+0x68>
    return page - pages + nbase;
ffffffffc0201b70:	000b1717          	auipc	a4,0xb1
ffffffffc0201b74:	d1073703          	ld	a4,-752(a4) # ffffffffc02b2880 <pages>
ffffffffc0201b78:	8c19                	sub	s0,s0,a4
ffffffffc0201b7a:	000807b7          	lui	a5,0x80
ffffffffc0201b7e:	8419                	srai	s0,s0,0x6
ffffffffc0201b80:	943e                	add	s0,s0,a5
  return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201b82:	042a                	slli	s0,s0,0xa
ffffffffc0201b84:	8cc1                	or	s1,s1,s0
ffffffffc0201b86:	0014e493          	ori	s1,s1,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm); // 创建页表项
ffffffffc0201b8a:	0099b023          	sd	s1,0(s3) # ffffffffc0000000 <_binary_obj___user_exit_out_size+0xffffffffbfff4ec8>
    asm volatile("sfence.vma %0" : : "r"(la)); // 执行sfence.vma指令使TLB无效
ffffffffc0201b8e:	120a0073          	sfence.vma	s4
    return 0; // 返回0
ffffffffc0201b92:	4501                	li	a0,0
}
ffffffffc0201b94:	70e2                	ld	ra,56(sp)
ffffffffc0201b96:	7442                	ld	s0,48(sp)
ffffffffc0201b98:	74a2                	ld	s1,40(sp)
ffffffffc0201b9a:	7902                	ld	s2,32(sp)
ffffffffc0201b9c:	69e2                	ld	s3,24(sp)
ffffffffc0201b9e:	6a42                	ld	s4,16(sp)
ffffffffc0201ba0:	6aa2                	ld	s5,8(sp)
ffffffffc0201ba2:	6121                	addi	sp,sp,64
ffffffffc0201ba4:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0201ba6:	078a                	slli	a5,a5,0x2
ffffffffc0201ba8:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201baa:	000b1717          	auipc	a4,0xb1
ffffffffc0201bae:	cce73703          	ld	a4,-818(a4) # ffffffffc02b2878 <npage>
ffffffffc0201bb2:	06e7ff63          	bgeu	a5,a4,ffffffffc0201c30 <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc0201bb6:	000b1a97          	auipc	s5,0xb1
ffffffffc0201bba:	ccaa8a93          	addi	s5,s5,-822 # ffffffffc02b2880 <pages>
ffffffffc0201bbe:	000ab703          	ld	a4,0(s5)
ffffffffc0201bc2:	fff80937          	lui	s2,0xfff80
ffffffffc0201bc6:	993e                	add	s2,s2,a5
ffffffffc0201bc8:	091a                	slli	s2,s2,0x6
ffffffffc0201bca:	993a                	add	s2,s2,a4
        if (p == page) { // 如果页表项对应的页与当前页相同
ffffffffc0201bcc:	01240c63          	beq	s0,s2,ffffffffc0201be4 <page_insert+0xa6>
    page->ref -= 1;
ffffffffc0201bd0:	00092783          	lw	a5,0(s2) # fffffffffff80000 <end+0x3fccd71c>
ffffffffc0201bd4:	fff7869b          	addiw	a3,a5,-1
ffffffffc0201bd8:	00d92023          	sw	a3,0(s2)
        if (page_ref(page) ==
ffffffffc0201bdc:	c691                	beqz	a3,ffffffffc0201be8 <page_insert+0xaa>
    asm volatile("sfence.vma %0" : : "r"(la)); // 执行sfence.vma指令使TLB无效
ffffffffc0201bde:	120a0073          	sfence.vma	s4
}
ffffffffc0201be2:	bf59                	j	ffffffffc0201b78 <page_insert+0x3a>
ffffffffc0201be4:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc0201be6:	bf49                	j	ffffffffc0201b78 <page_insert+0x3a>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201be8:	100027f3          	csrr	a5,sstatus
ffffffffc0201bec:	8b89                	andi	a5,a5,2
ffffffffc0201bee:	ef91                	bnez	a5,ffffffffc0201c0a <page_insert+0xcc>
        pmm_manager->free_pages(base, n); // 释放页
ffffffffc0201bf0:	000b1797          	auipc	a5,0xb1
ffffffffc0201bf4:	c987b783          	ld	a5,-872(a5) # ffffffffc02b2888 <pmm_manager>
ffffffffc0201bf8:	739c                	ld	a5,32(a5)
ffffffffc0201bfa:	4585                	li	a1,1
ffffffffc0201bfc:	854a                	mv	a0,s2
ffffffffc0201bfe:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc0201c00:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la)); // 执行sfence.vma指令使TLB无效
ffffffffc0201c04:	120a0073          	sfence.vma	s4
ffffffffc0201c08:	bf85                	j	ffffffffc0201b78 <page_insert+0x3a>
        intr_disable();
ffffffffc0201c0a:	a3ffe0ef          	jal	ra,ffffffffc0200648 <intr_disable>
        pmm_manager->free_pages(base, n); // 释放页
ffffffffc0201c0e:	000b1797          	auipc	a5,0xb1
ffffffffc0201c12:	c7a7b783          	ld	a5,-902(a5) # ffffffffc02b2888 <pmm_manager>
ffffffffc0201c16:	739c                	ld	a5,32(a5)
ffffffffc0201c18:	4585                	li	a1,1
ffffffffc0201c1a:	854a                	mv	a0,s2
ffffffffc0201c1c:	9782                	jalr	a5
        intr_enable();
ffffffffc0201c1e:	a25fe0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc0201c22:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la)); // 执行sfence.vma指令使TLB无效
ffffffffc0201c26:	120a0073          	sfence.vma	s4
ffffffffc0201c2a:	b7b9                	j	ffffffffc0201b78 <page_insert+0x3a>
        return -E_NO_MEM; // 返回内存不足错误
ffffffffc0201c2c:	5571                	li	a0,-4
ffffffffc0201c2e:	b79d                	j	ffffffffc0201b94 <page_insert+0x56>
ffffffffc0201c30:	f30ff0ef          	jal	ra,ffffffffc0201360 <pa2page.part.0>

ffffffffc0201c34 <pmm_init>:
    pmm_manager = &default_pmm_manager; // 设置默认的物理内存管理器
ffffffffc0201c34:	00007797          	auipc	a5,0x7
ffffffffc0201c38:	8bc78793          	addi	a5,a5,-1860 # ffffffffc02084f0 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name); // 打印内存管理器的名称
ffffffffc0201c3c:	638c                	ld	a1,0(a5)
void pmm_init(void) {
ffffffffc0201c3e:	711d                	addi	sp,sp,-96
ffffffffc0201c40:	ec5e                	sd	s7,24(sp)
    cprintf("memory management: %s\n", pmm_manager->name); // 打印内存管理器的名称
ffffffffc0201c42:	00005517          	auipc	a0,0x5
ffffffffc0201c46:	67e50513          	addi	a0,a0,1662 # ffffffffc02072c0 <commands+0x8a0>
    pmm_manager = &default_pmm_manager; // 设置默认的物理内存管理器
ffffffffc0201c4a:	000b1b97          	auipc	s7,0xb1
ffffffffc0201c4e:	c3eb8b93          	addi	s7,s7,-962 # ffffffffc02b2888 <pmm_manager>
void pmm_init(void) {
ffffffffc0201c52:	ec86                	sd	ra,88(sp)
ffffffffc0201c54:	e4a6                	sd	s1,72(sp)
ffffffffc0201c56:	fc4e                	sd	s3,56(sp)
ffffffffc0201c58:	f05a                	sd	s6,32(sp)
    pmm_manager = &default_pmm_manager; // 设置默认的物理内存管理器
ffffffffc0201c5a:	00fbb023          	sd	a5,0(s7)
void pmm_init(void) {
ffffffffc0201c5e:	e8a2                	sd	s0,80(sp)
ffffffffc0201c60:	e0ca                	sd	s2,64(sp)
ffffffffc0201c62:	f852                	sd	s4,48(sp)
ffffffffc0201c64:	f456                	sd	s5,40(sp)
ffffffffc0201c66:	e862                	sd	s8,16(sp)
    cprintf("memory management: %s\n", pmm_manager->name); // 打印内存管理器的名称
ffffffffc0201c68:	c64fe0ef          	jal	ra,ffffffffc02000cc <cprintf>
    pmm_manager->init(); // 初始化内存管理器
ffffffffc0201c6c:	000bb783          	ld	a5,0(s7)
    va_pa_offset = KERNBASE - 0x80200000; // 计算虚拟地址和物理地址的偏移量
ffffffffc0201c70:	000b1997          	auipc	s3,0xb1
ffffffffc0201c74:	c2098993          	addi	s3,s3,-992 # ffffffffc02b2890 <va_pa_offset>
    npage = maxpa / PGSIZE; // 计算物理页数
ffffffffc0201c78:	000b1497          	auipc	s1,0xb1
ffffffffc0201c7c:	c0048493          	addi	s1,s1,-1024 # ffffffffc02b2878 <npage>
    pmm_manager->init(); // 初始化内存管理器
ffffffffc0201c80:	679c                	ld	a5,8(a5)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE); // 计算物理页数组的虚拟地址
ffffffffc0201c82:	000b1b17          	auipc	s6,0xb1
ffffffffc0201c86:	bfeb0b13          	addi	s6,s6,-1026 # ffffffffc02b2880 <pages>
    pmm_manager->init(); // 初始化内存管理器
ffffffffc0201c8a:	9782                	jalr	a5
    va_pa_offset = KERNBASE - 0x80200000; // 计算虚拟地址和物理地址的偏移量
ffffffffc0201c8c:	57f5                	li	a5,-3
ffffffffc0201c8e:	07fa                	slli	a5,a5,0x1e
    cprintf("physcial memory map:\n"); // 打印物理内存映射信息
ffffffffc0201c90:	00005517          	auipc	a0,0x5
ffffffffc0201c94:	64850513          	addi	a0,a0,1608 # ffffffffc02072d8 <commands+0x8b8>
    va_pa_offset = KERNBASE - 0x80200000; // 计算虚拟地址和物理地址的偏移量
ffffffffc0201c98:	00f9b023          	sd	a5,0(s3)
    cprintf("physcial memory map:\n"); // 打印物理内存映射信息
ffffffffc0201c9c:	c30fe0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc0201ca0:	46c5                	li	a3,17
ffffffffc0201ca2:	06ee                	slli	a3,a3,0x1b
ffffffffc0201ca4:	40100613          	li	a2,1025
ffffffffc0201ca8:	07e005b7          	lui	a1,0x7e00
ffffffffc0201cac:	16fd                	addi	a3,a3,-1
ffffffffc0201cae:	0656                	slli	a2,a2,0x15
ffffffffc0201cb0:	00005517          	auipc	a0,0x5
ffffffffc0201cb4:	64050513          	addi	a0,a0,1600 # ffffffffc02072f0 <commands+0x8d0>
ffffffffc0201cb8:	c14fe0ef          	jal	ra,ffffffffc02000cc <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE); // 计算物理页数组的虚拟地址
ffffffffc0201cbc:	777d                	lui	a4,0xfffff
ffffffffc0201cbe:	000b2797          	auipc	a5,0xb2
ffffffffc0201cc2:	c2578793          	addi	a5,a5,-987 # ffffffffc02b38e3 <end+0xfff>
ffffffffc0201cc6:	8ff9                	and	a5,a5,a4
    npage = maxpa / PGSIZE; // 计算物理页数
ffffffffc0201cc8:	00088737          	lui	a4,0x88
ffffffffc0201ccc:	e098                	sd	a4,0(s1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE); // 计算物理页数组的虚拟地址
ffffffffc0201cce:	00fb3023          	sd	a5,0(s6)
    for (size_t i = 0; i < npage - nbase; i++) { // 遍历所有物理页
ffffffffc0201cd2:	4701                	li	a4,0
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201cd4:	4585                	li	a1,1
ffffffffc0201cd6:	fff80837          	lui	a6,0xfff80
ffffffffc0201cda:	a019                	j	ffffffffc0201ce0 <pmm_init+0xac>
        SetPageReserved(pages + i); // 将每个物理页标记为保留
ffffffffc0201cdc:	000b3783          	ld	a5,0(s6)
ffffffffc0201ce0:	00671693          	slli	a3,a4,0x6
ffffffffc0201ce4:	97b6                	add	a5,a5,a3
ffffffffc0201ce6:	07a1                	addi	a5,a5,8
ffffffffc0201ce8:	40b7b02f          	amoor.d	zero,a1,(a5)
    for (size_t i = 0; i < npage - nbase; i++) { // 遍历所有物理页
ffffffffc0201cec:	6090                	ld	a2,0(s1)
ffffffffc0201cee:	0705                	addi	a4,a4,1
ffffffffc0201cf0:	010607b3          	add	a5,a2,a6
ffffffffc0201cf4:	fef764e3          	bltu	a4,a5,ffffffffc0201cdc <pmm_init+0xa8>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase)); // 计算空闲内存的起始地址
ffffffffc0201cf8:	000b3503          	ld	a0,0(s6)
ffffffffc0201cfc:	079a                	slli	a5,a5,0x6
ffffffffc0201cfe:	c0200737          	lui	a4,0xc0200
ffffffffc0201d02:	00f506b3          	add	a3,a0,a5
ffffffffc0201d06:	60e6e563          	bltu	a3,a4,ffffffffc0202310 <pmm_init+0x6dc>
ffffffffc0201d0a:	0009b583          	ld	a1,0(s3)
    if (freemem < mem_end) { // 如果空闲内存的起始地址小于物理内存的结束地址
ffffffffc0201d0e:	4745                	li	a4,17
ffffffffc0201d10:	076e                	slli	a4,a4,0x1b
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase)); // 计算空闲内存的起始地址
ffffffffc0201d12:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end) { // 如果空闲内存的起始地址小于物理内存的结束地址
ffffffffc0201d14:	4ae6e563          	bltu	a3,a4,ffffffffc02021be <pmm_init+0x58a>
    cprintf("vapaofset is %llu\n",va_pa_offset); // 打印虚拟地址和物理地址的偏移量
ffffffffc0201d18:	00005517          	auipc	a0,0x5
ffffffffc0201d1c:	60050513          	addi	a0,a0,1536 # ffffffffc0207318 <commands+0x8f8>
ffffffffc0201d20:	bacfe0ef          	jal	ra,ffffffffc02000cc <cprintf>

    return page; // 返回分配的页
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0201d24:	000bb783          	ld	a5,0(s7)
    boot_pgdir = (pte_t*)boot_page_table_sv39; // 设置boot_pgdir为boot_page_table_sv39
ffffffffc0201d28:	000b1917          	auipc	s2,0xb1
ffffffffc0201d2c:	b4890913          	addi	s2,s2,-1208 # ffffffffc02b2870 <boot_pgdir>
    pmm_manager->check();
ffffffffc0201d30:	7b9c                	ld	a5,48(a5)
ffffffffc0201d32:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0201d34:	00005517          	auipc	a0,0x5
ffffffffc0201d38:	5fc50513          	addi	a0,a0,1532 # ffffffffc0207330 <commands+0x910>
ffffffffc0201d3c:	b90fe0ef          	jal	ra,ffffffffc02000cc <cprintf>
    boot_pgdir = (pte_t*)boot_page_table_sv39; // 设置boot_pgdir为boot_page_table_sv39
ffffffffc0201d40:	00009697          	auipc	a3,0x9
ffffffffc0201d44:	2c068693          	addi	a3,a3,704 # ffffffffc020b000 <boot_page_table_sv39>
ffffffffc0201d48:	00d93023          	sd	a3,0(s2)
    boot_cr3 = PADDR(boot_pgdir); // 设置boot_cr3为boot_pgdir的物理地址
ffffffffc0201d4c:	c02007b7          	lui	a5,0xc0200
ffffffffc0201d50:	5cf6ec63          	bltu	a3,a5,ffffffffc0202328 <pmm_init+0x6f4>
ffffffffc0201d54:	0009b783          	ld	a5,0(s3)
ffffffffc0201d58:	8e9d                	sub	a3,a3,a5
ffffffffc0201d5a:	000b1797          	auipc	a5,0xb1
ffffffffc0201d5e:	b0d7b723          	sd	a3,-1266(a5) # ffffffffc02b2868 <boot_cr3>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201d62:	100027f3          	csrr	a5,sstatus
ffffffffc0201d66:	8b89                	andi	a5,a5,2
ffffffffc0201d68:	48079263          	bnez	a5,ffffffffc02021ec <pmm_init+0x5b8>
        ret = pmm_manager->nr_free_pages(); // 调用pmm_manager的nr_free_pages方法获取空闲页数
ffffffffc0201d6c:	000bb783          	ld	a5,0(s7)
ffffffffc0201d70:	779c                	ld	a5,40(a5)
ffffffffc0201d72:	9782                	jalr	a5
ffffffffc0201d74:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store=nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0201d76:	6098                	ld	a4,0(s1)
ffffffffc0201d78:	c80007b7          	lui	a5,0xc8000
ffffffffc0201d7c:	83b1                	srli	a5,a5,0xc
ffffffffc0201d7e:	5ee7e163          	bltu	a5,a4,ffffffffc0202360 <pmm_init+0x72c>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc0201d82:	00093503          	ld	a0,0(s2)
ffffffffc0201d86:	5a050d63          	beqz	a0,ffffffffc0202340 <pmm_init+0x70c>
ffffffffc0201d8a:	03451793          	slli	a5,a0,0x34
ffffffffc0201d8e:	5a079963          	bnez	a5,ffffffffc0202340 <pmm_init+0x70c>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
ffffffffc0201d92:	4601                	li	a2,0
ffffffffc0201d94:	4581                	li	a1,0
ffffffffc0201d96:	8e1ff0ef          	jal	ra,ffffffffc0201676 <get_page>
ffffffffc0201d9a:	62051563          	bnez	a0,ffffffffc02023c4 <pmm_init+0x790>

    struct Page *p1, *p2;
    p1 = alloc_page();
ffffffffc0201d9e:	4505                	li	a0,1
ffffffffc0201da0:	df8ff0ef          	jal	ra,ffffffffc0201398 <alloc_pages>
ffffffffc0201da4:	8a2a                	mv	s4,a0
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc0201da6:	00093503          	ld	a0,0(s2)
ffffffffc0201daa:	4681                	li	a3,0
ffffffffc0201dac:	4601                	li	a2,0
ffffffffc0201dae:	85d2                	mv	a1,s4
ffffffffc0201db0:	d8fff0ef          	jal	ra,ffffffffc0201b3e <page_insert>
ffffffffc0201db4:	5e051863          	bnez	a0,ffffffffc02023a4 <pmm_init+0x770>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
ffffffffc0201db8:	00093503          	ld	a0,0(s2)
ffffffffc0201dbc:	4601                	li	a2,0
ffffffffc0201dbe:	4581                	li	a1,0
ffffffffc0201dc0:	ee4ff0ef          	jal	ra,ffffffffc02014a4 <get_pte>
ffffffffc0201dc4:	5c050063          	beqz	a0,ffffffffc0202384 <pmm_init+0x750>
    assert(pte2page(*ptep) == p1);
ffffffffc0201dc8:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc0201dca:	0017f713          	andi	a4,a5,1
ffffffffc0201dce:	5a070963          	beqz	a4,ffffffffc0202380 <pmm_init+0x74c>
    if (PPN(pa) >= npage) {
ffffffffc0201dd2:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0201dd4:	078a                	slli	a5,a5,0x2
ffffffffc0201dd6:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201dd8:	52e7fa63          	bgeu	a5,a4,ffffffffc020230c <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc0201ddc:	000b3683          	ld	a3,0(s6)
ffffffffc0201de0:	fff80637          	lui	a2,0xfff80
ffffffffc0201de4:	97b2                	add	a5,a5,a2
ffffffffc0201de6:	079a                	slli	a5,a5,0x6
ffffffffc0201de8:	97b6                	add	a5,a5,a3
ffffffffc0201dea:	10fa16e3          	bne	s4,a5,ffffffffc02026f6 <pmm_init+0xac2>
    assert(page_ref(p1) == 1);
ffffffffc0201dee:	000a2683          	lw	a3,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8bb8>
ffffffffc0201df2:	4785                	li	a5,1
ffffffffc0201df4:	12f69de3          	bne	a3,a5,ffffffffc020272e <pmm_init+0xafa>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc0201df8:	00093503          	ld	a0,0(s2)
ffffffffc0201dfc:	77fd                	lui	a5,0xfffff
ffffffffc0201dfe:	6114                	ld	a3,0(a0)
ffffffffc0201e00:	068a                	slli	a3,a3,0x2
ffffffffc0201e02:	8efd                	and	a3,a3,a5
ffffffffc0201e04:	00c6d613          	srli	a2,a3,0xc
ffffffffc0201e08:	10e677e3          	bgeu	a2,a4,ffffffffc0202716 <pmm_init+0xae2>
ffffffffc0201e0c:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0201e10:	96e2                	add	a3,a3,s8
ffffffffc0201e12:	0006ba83          	ld	s5,0(a3)
ffffffffc0201e16:	0a8a                	slli	s5,s5,0x2
ffffffffc0201e18:	00fafab3          	and	s5,s5,a5
ffffffffc0201e1c:	00cad793          	srli	a5,s5,0xc
ffffffffc0201e20:	62e7f263          	bgeu	a5,a4,ffffffffc0202444 <pmm_init+0x810>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0201e24:	4601                	li	a2,0
ffffffffc0201e26:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0201e28:	9ae2                	add	s5,s5,s8
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0201e2a:	e7aff0ef          	jal	ra,ffffffffc02014a4 <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0201e2e:	0aa1                	addi	s5,s5,8
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0201e30:	5f551a63          	bne	a0,s5,ffffffffc0202424 <pmm_init+0x7f0>

    p2 = alloc_page();
ffffffffc0201e34:	4505                	li	a0,1
ffffffffc0201e36:	d62ff0ef          	jal	ra,ffffffffc0201398 <alloc_pages>
ffffffffc0201e3a:	8aaa                	mv	s5,a0
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0201e3c:	00093503          	ld	a0,0(s2)
ffffffffc0201e40:	46d1                	li	a3,20
ffffffffc0201e42:	6605                	lui	a2,0x1
ffffffffc0201e44:	85d6                	mv	a1,s5
ffffffffc0201e46:	cf9ff0ef          	jal	ra,ffffffffc0201b3e <page_insert>
ffffffffc0201e4a:	58051d63          	bnez	a0,ffffffffc02023e4 <pmm_init+0x7b0>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0201e4e:	00093503          	ld	a0,0(s2)
ffffffffc0201e52:	4601                	li	a2,0
ffffffffc0201e54:	6585                	lui	a1,0x1
ffffffffc0201e56:	e4eff0ef          	jal	ra,ffffffffc02014a4 <get_pte>
ffffffffc0201e5a:	0e050ae3          	beqz	a0,ffffffffc020274e <pmm_init+0xb1a>
    assert(*ptep & PTE_U);
ffffffffc0201e5e:	611c                	ld	a5,0(a0)
ffffffffc0201e60:	0107f713          	andi	a4,a5,16
ffffffffc0201e64:	6e070d63          	beqz	a4,ffffffffc020255e <pmm_init+0x92a>
    assert(*ptep & PTE_W);
ffffffffc0201e68:	8b91                	andi	a5,a5,4
ffffffffc0201e6a:	6a078a63          	beqz	a5,ffffffffc020251e <pmm_init+0x8ea>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc0201e6e:	00093503          	ld	a0,0(s2)
ffffffffc0201e72:	611c                	ld	a5,0(a0)
ffffffffc0201e74:	8bc1                	andi	a5,a5,16
ffffffffc0201e76:	68078463          	beqz	a5,ffffffffc02024fe <pmm_init+0x8ca>
    assert(page_ref(p2) == 1);
ffffffffc0201e7a:	000aa703          	lw	a4,0(s5)
ffffffffc0201e7e:	4785                	li	a5,1
ffffffffc0201e80:	58f71263          	bne	a4,a5,ffffffffc0202404 <pmm_init+0x7d0>

    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc0201e84:	4681                	li	a3,0
ffffffffc0201e86:	6605                	lui	a2,0x1
ffffffffc0201e88:	85d2                	mv	a1,s4
ffffffffc0201e8a:	cb5ff0ef          	jal	ra,ffffffffc0201b3e <page_insert>
ffffffffc0201e8e:	62051863          	bnez	a0,ffffffffc02024be <pmm_init+0x88a>
    assert(page_ref(p1) == 2);
ffffffffc0201e92:	000a2703          	lw	a4,0(s4)
ffffffffc0201e96:	4789                	li	a5,2
ffffffffc0201e98:	60f71363          	bne	a4,a5,ffffffffc020249e <pmm_init+0x86a>
    assert(page_ref(p2) == 0);
ffffffffc0201e9c:	000aa783          	lw	a5,0(s5)
ffffffffc0201ea0:	5c079f63          	bnez	a5,ffffffffc020247e <pmm_init+0x84a>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0201ea4:	00093503          	ld	a0,0(s2)
ffffffffc0201ea8:	4601                	li	a2,0
ffffffffc0201eaa:	6585                	lui	a1,0x1
ffffffffc0201eac:	df8ff0ef          	jal	ra,ffffffffc02014a4 <get_pte>
ffffffffc0201eb0:	5a050763          	beqz	a0,ffffffffc020245e <pmm_init+0x82a>
    assert(pte2page(*ptep) == p1);
ffffffffc0201eb4:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc0201eb6:	00177793          	andi	a5,a4,1
ffffffffc0201eba:	4c078363          	beqz	a5,ffffffffc0202380 <pmm_init+0x74c>
    if (PPN(pa) >= npage) {
ffffffffc0201ebe:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0201ec0:	00271793          	slli	a5,a4,0x2
ffffffffc0201ec4:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201ec6:	44d7f363          	bgeu	a5,a3,ffffffffc020230c <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc0201eca:	000b3683          	ld	a3,0(s6)
ffffffffc0201ece:	fff80637          	lui	a2,0xfff80
ffffffffc0201ed2:	97b2                	add	a5,a5,a2
ffffffffc0201ed4:	079a                	slli	a5,a5,0x6
ffffffffc0201ed6:	97b6                	add	a5,a5,a3
ffffffffc0201ed8:	6efa1363          	bne	s4,a5,ffffffffc02025be <pmm_init+0x98a>
    assert((*ptep & PTE_U) == 0);
ffffffffc0201edc:	8b41                	andi	a4,a4,16
ffffffffc0201ede:	6c071063          	bnez	a4,ffffffffc020259e <pmm_init+0x96a>

    page_remove(boot_pgdir, 0x0);
ffffffffc0201ee2:	00093503          	ld	a0,0(s2)
ffffffffc0201ee6:	4581                	li	a1,0
ffffffffc0201ee8:	bbbff0ef          	jal	ra,ffffffffc0201aa2 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0201eec:	000a2703          	lw	a4,0(s4)
ffffffffc0201ef0:	4785                	li	a5,1
ffffffffc0201ef2:	68f71663          	bne	a4,a5,ffffffffc020257e <pmm_init+0x94a>
    assert(page_ref(p2) == 0);
ffffffffc0201ef6:	000aa783          	lw	a5,0(s5)
ffffffffc0201efa:	74079e63          	bnez	a5,ffffffffc0202656 <pmm_init+0xa22>

    page_remove(boot_pgdir, PGSIZE);
ffffffffc0201efe:	00093503          	ld	a0,0(s2)
ffffffffc0201f02:	6585                	lui	a1,0x1
ffffffffc0201f04:	b9fff0ef          	jal	ra,ffffffffc0201aa2 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0201f08:	000a2783          	lw	a5,0(s4)
ffffffffc0201f0c:	72079563          	bnez	a5,ffffffffc0202636 <pmm_init+0xa02>
    assert(page_ref(p2) == 0);
ffffffffc0201f10:	000aa783          	lw	a5,0(s5)
ffffffffc0201f14:	70079163          	bnez	a5,ffffffffc0202616 <pmm_init+0x9e2>

    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
ffffffffc0201f18:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage) {
ffffffffc0201f1c:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201f1e:	000a3683          	ld	a3,0(s4)
ffffffffc0201f22:	068a                	slli	a3,a3,0x2
ffffffffc0201f24:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201f26:	3ee6f363          	bgeu	a3,a4,ffffffffc020230c <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc0201f2a:	fff807b7          	lui	a5,0xfff80
ffffffffc0201f2e:	000b3503          	ld	a0,0(s6)
ffffffffc0201f32:	96be                	add	a3,a3,a5
ffffffffc0201f34:	069a                	slli	a3,a3,0x6
    return page->ref;
ffffffffc0201f36:	00d507b3          	add	a5,a0,a3
ffffffffc0201f3a:	4390                	lw	a2,0(a5)
ffffffffc0201f3c:	4785                	li	a5,1
ffffffffc0201f3e:	6af61c63          	bne	a2,a5,ffffffffc02025f6 <pmm_init+0x9c2>
    return page - pages + nbase;
ffffffffc0201f42:	8699                	srai	a3,a3,0x6
ffffffffc0201f44:	000805b7          	lui	a1,0x80
ffffffffc0201f48:	96ae                	add	a3,a3,a1
    return KADDR(page2pa(page));
ffffffffc0201f4a:	00c69613          	slli	a2,a3,0xc
ffffffffc0201f4e:	8231                	srli	a2,a2,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201f50:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0201f52:	68e67663          	bgeu	a2,a4,ffffffffc02025de <pmm_init+0x9aa>

    pde_t *pd1=boot_pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
    free_page(pde2page(pd0[0]));
ffffffffc0201f56:	0009b603          	ld	a2,0(s3)
ffffffffc0201f5a:	96b2                	add	a3,a3,a2
    return pa2page(PDE_ADDR(pde));
ffffffffc0201f5c:	629c                	ld	a5,0(a3)
ffffffffc0201f5e:	078a                	slli	a5,a5,0x2
ffffffffc0201f60:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201f62:	3ae7f563          	bgeu	a5,a4,ffffffffc020230c <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc0201f66:	8f8d                	sub	a5,a5,a1
ffffffffc0201f68:	079a                	slli	a5,a5,0x6
ffffffffc0201f6a:	953e                	add	a0,a0,a5
ffffffffc0201f6c:	100027f3          	csrr	a5,sstatus
ffffffffc0201f70:	8b89                	andi	a5,a5,2
ffffffffc0201f72:	2c079763          	bnez	a5,ffffffffc0202240 <pmm_init+0x60c>
        pmm_manager->free_pages(base, n); // 释放页
ffffffffc0201f76:	000bb783          	ld	a5,0(s7)
ffffffffc0201f7a:	4585                	li	a1,1
ffffffffc0201f7c:	739c                	ld	a5,32(a5)
ffffffffc0201f7e:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0201f80:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage) {
ffffffffc0201f84:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201f86:	078a                	slli	a5,a5,0x2
ffffffffc0201f88:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201f8a:	38e7f163          	bgeu	a5,a4,ffffffffc020230c <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc0201f8e:	000b3503          	ld	a0,0(s6)
ffffffffc0201f92:	fff80737          	lui	a4,0xfff80
ffffffffc0201f96:	97ba                	add	a5,a5,a4
ffffffffc0201f98:	079a                	slli	a5,a5,0x6
ffffffffc0201f9a:	953e                	add	a0,a0,a5
ffffffffc0201f9c:	100027f3          	csrr	a5,sstatus
ffffffffc0201fa0:	8b89                	andi	a5,a5,2
ffffffffc0201fa2:	28079363          	bnez	a5,ffffffffc0202228 <pmm_init+0x5f4>
ffffffffc0201fa6:	000bb783          	ld	a5,0(s7)
ffffffffc0201faa:	4585                	li	a1,1
ffffffffc0201fac:	739c                	ld	a5,32(a5)
ffffffffc0201fae:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir[0] = 0;
ffffffffc0201fb0:	00093783          	ld	a5,0(s2)
ffffffffc0201fb4:	0007b023          	sd	zero,0(a5) # fffffffffff80000 <end+0x3fccd71c>
  asm volatile("sfence.vma");
ffffffffc0201fb8:	12000073          	sfence.vma
ffffffffc0201fbc:	100027f3          	csrr	a5,sstatus
ffffffffc0201fc0:	8b89                	andi	a5,a5,2
ffffffffc0201fc2:	24079963          	bnez	a5,ffffffffc0202214 <pmm_init+0x5e0>
        ret = pmm_manager->nr_free_pages(); // 调用pmm_manager的nr_free_pages方法获取空闲页数
ffffffffc0201fc6:	000bb783          	ld	a5,0(s7)
ffffffffc0201fca:	779c                	ld	a5,40(a5)
ffffffffc0201fcc:	9782                	jalr	a5
ffffffffc0201fce:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store==nr_free_pages());
ffffffffc0201fd0:	71441363          	bne	s0,s4,ffffffffc02026d6 <pmm_init+0xaa2>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0201fd4:	00005517          	auipc	a0,0x5
ffffffffc0201fd8:	64450513          	addi	a0,a0,1604 # ffffffffc0207618 <commands+0xbf8>
ffffffffc0201fdc:	8f0fe0ef          	jal	ra,ffffffffc02000cc <cprintf>
ffffffffc0201fe0:	100027f3          	csrr	a5,sstatus
ffffffffc0201fe4:	8b89                	andi	a5,a5,2
ffffffffc0201fe6:	20079d63          	bnez	a5,ffffffffc0202200 <pmm_init+0x5cc>
        ret = pmm_manager->nr_free_pages(); // 调用pmm_manager的nr_free_pages方法获取空闲页数
ffffffffc0201fea:	000bb783          	ld	a5,0(s7)
ffffffffc0201fee:	779c                	ld	a5,40(a5)
ffffffffc0201ff0:	9782                	jalr	a5
ffffffffc0201ff2:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store=nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc0201ff4:	6098                	ld	a4,0(s1)
ffffffffc0201ff6:	c0200437          	lui	s0,0xc0200
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0201ffa:	7afd                	lui	s5,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc0201ffc:	00c71793          	slli	a5,a4,0xc
ffffffffc0202000:	6a05                	lui	s4,0x1
ffffffffc0202002:	02f47c63          	bgeu	s0,a5,ffffffffc020203a <pmm_init+0x406>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202006:	00c45793          	srli	a5,s0,0xc
ffffffffc020200a:	00093503          	ld	a0,0(s2)
ffffffffc020200e:	2ee7f263          	bgeu	a5,a4,ffffffffc02022f2 <pmm_init+0x6be>
ffffffffc0202012:	0009b583          	ld	a1,0(s3)
ffffffffc0202016:	4601                	li	a2,0
ffffffffc0202018:	95a2                	add	a1,a1,s0
ffffffffc020201a:	c8aff0ef          	jal	ra,ffffffffc02014a4 <get_pte>
ffffffffc020201e:	2a050a63          	beqz	a0,ffffffffc02022d2 <pmm_init+0x69e>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202022:	611c                	ld	a5,0(a0)
ffffffffc0202024:	078a                	slli	a5,a5,0x2
ffffffffc0202026:	0157f7b3          	and	a5,a5,s5
ffffffffc020202a:	28879463          	bne	a5,s0,ffffffffc02022b2 <pmm_init+0x67e>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc020202e:	6098                	ld	a4,0(s1)
ffffffffc0202030:	9452                	add	s0,s0,s4
ffffffffc0202032:	00c71793          	slli	a5,a4,0xc
ffffffffc0202036:	fcf468e3          	bltu	s0,a5,ffffffffc0202006 <pmm_init+0x3d2>
    }


    assert(boot_pgdir[0] == 0);
ffffffffc020203a:	00093783          	ld	a5,0(s2)
ffffffffc020203e:	639c                	ld	a5,0(a5)
ffffffffc0202040:	66079b63          	bnez	a5,ffffffffc02026b6 <pmm_init+0xa82>

    struct Page *p;
    p = alloc_page();
ffffffffc0202044:	4505                	li	a0,1
ffffffffc0202046:	b52ff0ef          	jal	ra,ffffffffc0201398 <alloc_pages>
ffffffffc020204a:	8aaa                	mv	s5,a0
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc020204c:	00093503          	ld	a0,0(s2)
ffffffffc0202050:	4699                	li	a3,6
ffffffffc0202052:	10000613          	li	a2,256
ffffffffc0202056:	85d6                	mv	a1,s5
ffffffffc0202058:	ae7ff0ef          	jal	ra,ffffffffc0201b3e <page_insert>
ffffffffc020205c:	62051d63          	bnez	a0,ffffffffc0202696 <pmm_init+0xa62>
    assert(page_ref(p) == 1);
ffffffffc0202060:	000aa703          	lw	a4,0(s5) # fffffffffffff000 <end+0x3fd4c71c>
ffffffffc0202064:	4785                	li	a5,1
ffffffffc0202066:	60f71863          	bne	a4,a5,ffffffffc0202676 <pmm_init+0xa42>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc020206a:	00093503          	ld	a0,0(s2)
ffffffffc020206e:	6405                	lui	s0,0x1
ffffffffc0202070:	4699                	li	a3,6
ffffffffc0202072:	10040613          	addi	a2,s0,256 # 1100 <_binary_obj___user_faultread_out_size-0x8ab8>
ffffffffc0202076:	85d6                	mv	a1,s5
ffffffffc0202078:	ac7ff0ef          	jal	ra,ffffffffc0201b3e <page_insert>
ffffffffc020207c:	46051163          	bnez	a0,ffffffffc02024de <pmm_init+0x8aa>
    assert(page_ref(p) == 2);
ffffffffc0202080:	000aa703          	lw	a4,0(s5)
ffffffffc0202084:	4789                	li	a5,2
ffffffffc0202086:	72f71463          	bne	a4,a5,ffffffffc02027ae <pmm_init+0xb7a>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc020208a:	00005597          	auipc	a1,0x5
ffffffffc020208e:	6c658593          	addi	a1,a1,1734 # ffffffffc0207750 <commands+0xd30>
ffffffffc0202092:	10000513          	li	a0,256
ffffffffc0202096:	26e040ef          	jal	ra,ffffffffc0206304 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc020209a:	10040593          	addi	a1,s0,256
ffffffffc020209e:	10000513          	li	a0,256
ffffffffc02020a2:	274040ef          	jal	ra,ffffffffc0206316 <strcmp>
ffffffffc02020a6:	6e051463          	bnez	a0,ffffffffc020278e <pmm_init+0xb5a>
    return page - pages + nbase;
ffffffffc02020aa:	000b3683          	ld	a3,0(s6)
ffffffffc02020ae:	00080737          	lui	a4,0x80
    return KADDR(page2pa(page));
ffffffffc02020b2:	547d                	li	s0,-1
    return page - pages + nbase;
ffffffffc02020b4:	40da86b3          	sub	a3,s5,a3
ffffffffc02020b8:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc02020ba:	609c                	ld	a5,0(s1)
    return page - pages + nbase;
ffffffffc02020bc:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc02020be:	8031                	srli	s0,s0,0xc
ffffffffc02020c0:	0086f733          	and	a4,a3,s0
    return page2ppn(page) << PGSHIFT;
ffffffffc02020c4:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02020c6:	50f77c63          	bgeu	a4,a5,ffffffffc02025de <pmm_init+0x9aa>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc02020ca:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc02020ce:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc02020d2:	96be                	add	a3,a3,a5
ffffffffc02020d4:	10068023          	sb	zero,256(a3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc02020d8:	1f6040ef          	jal	ra,ffffffffc02062ce <strlen>
ffffffffc02020dc:	68051963          	bnez	a0,ffffffffc020276e <pmm_init+0xb3a>

    pde_t *pd1=boot_pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
ffffffffc02020e0:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage) {
ffffffffc02020e4:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02020e6:	000a3683          	ld	a3,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8bb8>
ffffffffc02020ea:	068a                	slli	a3,a3,0x2
ffffffffc02020ec:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage) {
ffffffffc02020ee:	20f6ff63          	bgeu	a3,a5,ffffffffc020230c <pmm_init+0x6d8>
    return KADDR(page2pa(page));
ffffffffc02020f2:	8c75                	and	s0,s0,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc02020f4:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02020f6:	4ef47463          	bgeu	s0,a5,ffffffffc02025de <pmm_init+0x9aa>
ffffffffc02020fa:	0009b403          	ld	s0,0(s3)
ffffffffc02020fe:	9436                	add	s0,s0,a3
ffffffffc0202100:	100027f3          	csrr	a5,sstatus
ffffffffc0202104:	8b89                	andi	a5,a5,2
ffffffffc0202106:	18079b63          	bnez	a5,ffffffffc020229c <pmm_init+0x668>
        pmm_manager->free_pages(base, n); // 释放页
ffffffffc020210a:	000bb783          	ld	a5,0(s7)
ffffffffc020210e:	4585                	li	a1,1
ffffffffc0202110:	8556                	mv	a0,s5
ffffffffc0202112:	739c                	ld	a5,32(a5)
ffffffffc0202114:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202116:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage) {
ffffffffc0202118:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc020211a:	078a                	slli	a5,a5,0x2
ffffffffc020211c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020211e:	1ee7f763          	bgeu	a5,a4,ffffffffc020230c <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc0202122:	000b3503          	ld	a0,0(s6)
ffffffffc0202126:	fff80737          	lui	a4,0xfff80
ffffffffc020212a:	97ba                	add	a5,a5,a4
ffffffffc020212c:	079a                	slli	a5,a5,0x6
ffffffffc020212e:	953e                	add	a0,a0,a5
ffffffffc0202130:	100027f3          	csrr	a5,sstatus
ffffffffc0202134:	8b89                	andi	a5,a5,2
ffffffffc0202136:	14079763          	bnez	a5,ffffffffc0202284 <pmm_init+0x650>
ffffffffc020213a:	000bb783          	ld	a5,0(s7)
ffffffffc020213e:	4585                	li	a1,1
ffffffffc0202140:	739c                	ld	a5,32(a5)
ffffffffc0202142:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202144:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage) {
ffffffffc0202148:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc020214a:	078a                	slli	a5,a5,0x2
ffffffffc020214c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020214e:	1ae7ff63          	bgeu	a5,a4,ffffffffc020230c <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc0202152:	000b3503          	ld	a0,0(s6)
ffffffffc0202156:	fff80737          	lui	a4,0xfff80
ffffffffc020215a:	97ba                	add	a5,a5,a4
ffffffffc020215c:	079a                	slli	a5,a5,0x6
ffffffffc020215e:	953e                	add	a0,a0,a5
ffffffffc0202160:	100027f3          	csrr	a5,sstatus
ffffffffc0202164:	8b89                	andi	a5,a5,2
ffffffffc0202166:	10079363          	bnez	a5,ffffffffc020226c <pmm_init+0x638>
ffffffffc020216a:	000bb783          	ld	a5,0(s7)
ffffffffc020216e:	4585                	li	a1,1
ffffffffc0202170:	739c                	ld	a5,32(a5)
ffffffffc0202172:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir[0] = 0;
ffffffffc0202174:	00093783          	ld	a5,0(s2)
ffffffffc0202178:	0007b023          	sd	zero,0(a5)
  asm volatile("sfence.vma");
ffffffffc020217c:	12000073          	sfence.vma
ffffffffc0202180:	100027f3          	csrr	a5,sstatus
ffffffffc0202184:	8b89                	andi	a5,a5,2
ffffffffc0202186:	0c079963          	bnez	a5,ffffffffc0202258 <pmm_init+0x624>
        ret = pmm_manager->nr_free_pages(); // 调用pmm_manager的nr_free_pages方法获取空闲页数
ffffffffc020218a:	000bb783          	ld	a5,0(s7)
ffffffffc020218e:	779c                	ld	a5,40(a5)
ffffffffc0202190:	9782                	jalr	a5
ffffffffc0202192:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store==nr_free_pages());
ffffffffc0202194:	3a8c1563          	bne	s8,s0,ffffffffc020253e <pmm_init+0x90a>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0202198:	00005517          	auipc	a0,0x5
ffffffffc020219c:	63050513          	addi	a0,a0,1584 # ffffffffc02077c8 <commands+0xda8>
ffffffffc02021a0:	f2dfd0ef          	jal	ra,ffffffffc02000cc <cprintf>
}
ffffffffc02021a4:	6446                	ld	s0,80(sp)
ffffffffc02021a6:	60e6                	ld	ra,88(sp)
ffffffffc02021a8:	64a6                	ld	s1,72(sp)
ffffffffc02021aa:	6906                	ld	s2,64(sp)
ffffffffc02021ac:	79e2                	ld	s3,56(sp)
ffffffffc02021ae:	7a42                	ld	s4,48(sp)
ffffffffc02021b0:	7aa2                	ld	s5,40(sp)
ffffffffc02021b2:	7b02                	ld	s6,32(sp)
ffffffffc02021b4:	6be2                	ld	s7,24(sp)
ffffffffc02021b6:	6c42                	ld	s8,16(sp)
ffffffffc02021b8:	6125                	addi	sp,sp,96
    kmalloc_init(); // 初始化内核内存分配器
ffffffffc02021ba:	4010106f          	j	ffffffffc0203dba <kmalloc_init>
    mem_begin = ROUNDUP(freemem, PGSIZE); // 将空闲内存的起始地址向上取整到页边界
ffffffffc02021be:	6785                	lui	a5,0x1
ffffffffc02021c0:	17fd                	addi	a5,a5,-1
ffffffffc02021c2:	96be                	add	a3,a3,a5
ffffffffc02021c4:	77fd                	lui	a5,0xfffff
ffffffffc02021c6:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage) {
ffffffffc02021c8:	00c7d693          	srli	a3,a5,0xc
ffffffffc02021cc:	14c6f063          	bgeu	a3,a2,ffffffffc020230c <pmm_init+0x6d8>
    pmm_manager->init_memmap(base, n); // 初始化内存映射
ffffffffc02021d0:	000bb603          	ld	a2,0(s7)
    return &pages[PPN(pa) - nbase];
ffffffffc02021d4:	96c2                	add	a3,a3,a6
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE); // 初始化空闲内存的页映射
ffffffffc02021d6:	40f707b3          	sub	a5,a4,a5
    pmm_manager->init_memmap(base, n); // 初始化内存映射
ffffffffc02021da:	6a10                	ld	a2,16(a2)
ffffffffc02021dc:	069a                	slli	a3,a3,0x6
ffffffffc02021de:	00c7d593          	srli	a1,a5,0xc
ffffffffc02021e2:	9536                	add	a0,a0,a3
ffffffffc02021e4:	9602                	jalr	a2
    cprintf("vapaofset is %llu\n",va_pa_offset); // 打印虚拟地址和物理地址的偏移量
ffffffffc02021e6:	0009b583          	ld	a1,0(s3)
}
ffffffffc02021ea:	b63d                	j	ffffffffc0201d18 <pmm_init+0xe4>
        intr_disable();
ffffffffc02021ec:	c5cfe0ef          	jal	ra,ffffffffc0200648 <intr_disable>
        ret = pmm_manager->nr_free_pages(); // 调用pmm_manager的nr_free_pages方法获取空闲页数
ffffffffc02021f0:	000bb783          	ld	a5,0(s7)
ffffffffc02021f4:	779c                	ld	a5,40(a5)
ffffffffc02021f6:	9782                	jalr	a5
ffffffffc02021f8:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02021fa:	c48fe0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc02021fe:	bea5                	j	ffffffffc0201d76 <pmm_init+0x142>
        intr_disable();
ffffffffc0202200:	c48fe0ef          	jal	ra,ffffffffc0200648 <intr_disable>
ffffffffc0202204:	000bb783          	ld	a5,0(s7)
ffffffffc0202208:	779c                	ld	a5,40(a5)
ffffffffc020220a:	9782                	jalr	a5
ffffffffc020220c:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc020220e:	c34fe0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc0202212:	b3cd                	j	ffffffffc0201ff4 <pmm_init+0x3c0>
        intr_disable();
ffffffffc0202214:	c34fe0ef          	jal	ra,ffffffffc0200648 <intr_disable>
ffffffffc0202218:	000bb783          	ld	a5,0(s7)
ffffffffc020221c:	779c                	ld	a5,40(a5)
ffffffffc020221e:	9782                	jalr	a5
ffffffffc0202220:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202222:	c20fe0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc0202226:	b36d                	j	ffffffffc0201fd0 <pmm_init+0x39c>
ffffffffc0202228:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020222a:	c1efe0ef          	jal	ra,ffffffffc0200648 <intr_disable>
        pmm_manager->free_pages(base, n); // 释放页
ffffffffc020222e:	000bb783          	ld	a5,0(s7)
ffffffffc0202232:	6522                	ld	a0,8(sp)
ffffffffc0202234:	4585                	li	a1,1
ffffffffc0202236:	739c                	ld	a5,32(a5)
ffffffffc0202238:	9782                	jalr	a5
        intr_enable();
ffffffffc020223a:	c08fe0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc020223e:	bb8d                	j	ffffffffc0201fb0 <pmm_init+0x37c>
ffffffffc0202240:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202242:	c06fe0ef          	jal	ra,ffffffffc0200648 <intr_disable>
ffffffffc0202246:	000bb783          	ld	a5,0(s7)
ffffffffc020224a:	6522                	ld	a0,8(sp)
ffffffffc020224c:	4585                	li	a1,1
ffffffffc020224e:	739c                	ld	a5,32(a5)
ffffffffc0202250:	9782                	jalr	a5
        intr_enable();
ffffffffc0202252:	bf0fe0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc0202256:	b32d                	j	ffffffffc0201f80 <pmm_init+0x34c>
        intr_disable();
ffffffffc0202258:	bf0fe0ef          	jal	ra,ffffffffc0200648 <intr_disable>
        ret = pmm_manager->nr_free_pages(); // 调用pmm_manager的nr_free_pages方法获取空闲页数
ffffffffc020225c:	000bb783          	ld	a5,0(s7)
ffffffffc0202260:	779c                	ld	a5,40(a5)
ffffffffc0202262:	9782                	jalr	a5
ffffffffc0202264:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202266:	bdcfe0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc020226a:	b72d                	j	ffffffffc0202194 <pmm_init+0x560>
ffffffffc020226c:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020226e:	bdafe0ef          	jal	ra,ffffffffc0200648 <intr_disable>
        pmm_manager->free_pages(base, n); // 释放页
ffffffffc0202272:	000bb783          	ld	a5,0(s7)
ffffffffc0202276:	6522                	ld	a0,8(sp)
ffffffffc0202278:	4585                	li	a1,1
ffffffffc020227a:	739c                	ld	a5,32(a5)
ffffffffc020227c:	9782                	jalr	a5
        intr_enable();
ffffffffc020227e:	bc4fe0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc0202282:	bdcd                	j	ffffffffc0202174 <pmm_init+0x540>
ffffffffc0202284:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202286:	bc2fe0ef          	jal	ra,ffffffffc0200648 <intr_disable>
ffffffffc020228a:	000bb783          	ld	a5,0(s7)
ffffffffc020228e:	6522                	ld	a0,8(sp)
ffffffffc0202290:	4585                	li	a1,1
ffffffffc0202292:	739c                	ld	a5,32(a5)
ffffffffc0202294:	9782                	jalr	a5
        intr_enable();
ffffffffc0202296:	bacfe0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc020229a:	b56d                	j	ffffffffc0202144 <pmm_init+0x510>
        intr_disable();
ffffffffc020229c:	bacfe0ef          	jal	ra,ffffffffc0200648 <intr_disable>
ffffffffc02022a0:	000bb783          	ld	a5,0(s7)
ffffffffc02022a4:	4585                	li	a1,1
ffffffffc02022a6:	8556                	mv	a0,s5
ffffffffc02022a8:	739c                	ld	a5,32(a5)
ffffffffc02022aa:	9782                	jalr	a5
        intr_enable();
ffffffffc02022ac:	b96fe0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc02022b0:	b59d                	j	ffffffffc0202116 <pmm_init+0x4e2>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc02022b2:	00005697          	auipc	a3,0x5
ffffffffc02022b6:	3c668693          	addi	a3,a3,966 # ffffffffc0207678 <commands+0xc58>
ffffffffc02022ba:	00005617          	auipc	a2,0x5
ffffffffc02022be:	b7660613          	addi	a2,a2,-1162 # ffffffffc0206e30 <commands+0x410>
ffffffffc02022c2:	21800593          	li	a1,536
ffffffffc02022c6:	00005517          	auipc	a0,0x5
ffffffffc02022ca:	fea50513          	addi	a0,a0,-22 # ffffffffc02072b0 <commands+0x890>
ffffffffc02022ce:	f3bfd0ef          	jal	ra,ffffffffc0200208 <__panic>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc02022d2:	00005697          	auipc	a3,0x5
ffffffffc02022d6:	36668693          	addi	a3,a3,870 # ffffffffc0207638 <commands+0xc18>
ffffffffc02022da:	00005617          	auipc	a2,0x5
ffffffffc02022de:	b5660613          	addi	a2,a2,-1194 # ffffffffc0206e30 <commands+0x410>
ffffffffc02022e2:	21700593          	li	a1,535
ffffffffc02022e6:	00005517          	auipc	a0,0x5
ffffffffc02022ea:	fca50513          	addi	a0,a0,-54 # ffffffffc02072b0 <commands+0x890>
ffffffffc02022ee:	f1bfd0ef          	jal	ra,ffffffffc0200208 <__panic>
ffffffffc02022f2:	86a2                	mv	a3,s0
ffffffffc02022f4:	00005617          	auipc	a2,0x5
ffffffffc02022f8:	ef460613          	addi	a2,a2,-268 # ffffffffc02071e8 <commands+0x7c8>
ffffffffc02022fc:	21700593          	li	a1,535
ffffffffc0202300:	00005517          	auipc	a0,0x5
ffffffffc0202304:	fb050513          	addi	a0,a0,-80 # ffffffffc02072b0 <commands+0x890>
ffffffffc0202308:	f01fd0ef          	jal	ra,ffffffffc0200208 <__panic>
ffffffffc020230c:	854ff0ef          	jal	ra,ffffffffc0201360 <pa2page.part.0>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase)); // 计算空闲内存的起始地址
ffffffffc0202310:	00005617          	auipc	a2,0x5
ffffffffc0202314:	f2860613          	addi	a2,a2,-216 # ffffffffc0207238 <commands+0x818>
ffffffffc0202318:	08100593          	li	a1,129
ffffffffc020231c:	00005517          	auipc	a0,0x5
ffffffffc0202320:	f9450513          	addi	a0,a0,-108 # ffffffffc02072b0 <commands+0x890>
ffffffffc0202324:	ee5fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    boot_cr3 = PADDR(boot_pgdir); // 设置boot_cr3为boot_pgdir的物理地址
ffffffffc0202328:	00005617          	auipc	a2,0x5
ffffffffc020232c:	f1060613          	addi	a2,a2,-240 # ffffffffc0207238 <commands+0x818>
ffffffffc0202330:	0bd00593          	li	a1,189
ffffffffc0202334:	00005517          	auipc	a0,0x5
ffffffffc0202338:	f7c50513          	addi	a0,a0,-132 # ffffffffc02072b0 <commands+0x890>
ffffffffc020233c:	ecdfd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc0202340:	00005697          	auipc	a3,0x5
ffffffffc0202344:	03068693          	addi	a3,a3,48 # ffffffffc0207370 <commands+0x950>
ffffffffc0202348:	00005617          	auipc	a2,0x5
ffffffffc020234c:	ae860613          	addi	a2,a2,-1304 # ffffffffc0206e30 <commands+0x410>
ffffffffc0202350:	1db00593          	li	a1,475
ffffffffc0202354:	00005517          	auipc	a0,0x5
ffffffffc0202358:	f5c50513          	addi	a0,a0,-164 # ffffffffc02072b0 <commands+0x890>
ffffffffc020235c:	eadfd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202360:	00005697          	auipc	a3,0x5
ffffffffc0202364:	ff068693          	addi	a3,a3,-16 # ffffffffc0207350 <commands+0x930>
ffffffffc0202368:	00005617          	auipc	a2,0x5
ffffffffc020236c:	ac860613          	addi	a2,a2,-1336 # ffffffffc0206e30 <commands+0x410>
ffffffffc0202370:	1da00593          	li	a1,474
ffffffffc0202374:	00005517          	auipc	a0,0x5
ffffffffc0202378:	f3c50513          	addi	a0,a0,-196 # ffffffffc02072b0 <commands+0x890>
ffffffffc020237c:	e8dfd0ef          	jal	ra,ffffffffc0200208 <__panic>
ffffffffc0202380:	ffdfe0ef          	jal	ra,ffffffffc020137c <pte2page.part.0>
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
ffffffffc0202384:	00005697          	auipc	a3,0x5
ffffffffc0202388:	07c68693          	addi	a3,a3,124 # ffffffffc0207400 <commands+0x9e0>
ffffffffc020238c:	00005617          	auipc	a2,0x5
ffffffffc0202390:	aa460613          	addi	a2,a2,-1372 # ffffffffc0206e30 <commands+0x410>
ffffffffc0202394:	1e300593          	li	a1,483
ffffffffc0202398:	00005517          	auipc	a0,0x5
ffffffffc020239c:	f1850513          	addi	a0,a0,-232 # ffffffffc02072b0 <commands+0x890>
ffffffffc02023a0:	e69fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc02023a4:	00005697          	auipc	a3,0x5
ffffffffc02023a8:	02c68693          	addi	a3,a3,44 # ffffffffc02073d0 <commands+0x9b0>
ffffffffc02023ac:	00005617          	auipc	a2,0x5
ffffffffc02023b0:	a8460613          	addi	a2,a2,-1404 # ffffffffc0206e30 <commands+0x410>
ffffffffc02023b4:	1e000593          	li	a1,480
ffffffffc02023b8:	00005517          	auipc	a0,0x5
ffffffffc02023bc:	ef850513          	addi	a0,a0,-264 # ffffffffc02072b0 <commands+0x890>
ffffffffc02023c0:	e49fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
ffffffffc02023c4:	00005697          	auipc	a3,0x5
ffffffffc02023c8:	fe468693          	addi	a3,a3,-28 # ffffffffc02073a8 <commands+0x988>
ffffffffc02023cc:	00005617          	auipc	a2,0x5
ffffffffc02023d0:	a6460613          	addi	a2,a2,-1436 # ffffffffc0206e30 <commands+0x410>
ffffffffc02023d4:	1dc00593          	li	a1,476
ffffffffc02023d8:	00005517          	auipc	a0,0x5
ffffffffc02023dc:	ed850513          	addi	a0,a0,-296 # ffffffffc02072b0 <commands+0x890>
ffffffffc02023e0:	e29fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc02023e4:	00005697          	auipc	a3,0x5
ffffffffc02023e8:	0a468693          	addi	a3,a3,164 # ffffffffc0207488 <commands+0xa68>
ffffffffc02023ec:	00005617          	auipc	a2,0x5
ffffffffc02023f0:	a4460613          	addi	a2,a2,-1468 # ffffffffc0206e30 <commands+0x410>
ffffffffc02023f4:	1ec00593          	li	a1,492
ffffffffc02023f8:	00005517          	auipc	a0,0x5
ffffffffc02023fc:	eb850513          	addi	a0,a0,-328 # ffffffffc02072b0 <commands+0x890>
ffffffffc0202400:	e09fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(page_ref(p2) == 1);
ffffffffc0202404:	00005697          	auipc	a3,0x5
ffffffffc0202408:	12468693          	addi	a3,a3,292 # ffffffffc0207528 <commands+0xb08>
ffffffffc020240c:	00005617          	auipc	a2,0x5
ffffffffc0202410:	a2460613          	addi	a2,a2,-1500 # ffffffffc0206e30 <commands+0x410>
ffffffffc0202414:	1f100593          	li	a1,497
ffffffffc0202418:	00005517          	auipc	a0,0x5
ffffffffc020241c:	e9850513          	addi	a0,a0,-360 # ffffffffc02072b0 <commands+0x890>
ffffffffc0202420:	de9fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0202424:	00005697          	auipc	a3,0x5
ffffffffc0202428:	03c68693          	addi	a3,a3,60 # ffffffffc0207460 <commands+0xa40>
ffffffffc020242c:	00005617          	auipc	a2,0x5
ffffffffc0202430:	a0460613          	addi	a2,a2,-1532 # ffffffffc0206e30 <commands+0x410>
ffffffffc0202434:	1e900593          	li	a1,489
ffffffffc0202438:	00005517          	auipc	a0,0x5
ffffffffc020243c:	e7850513          	addi	a0,a0,-392 # ffffffffc02072b0 <commands+0x890>
ffffffffc0202440:	dc9fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202444:	86d6                	mv	a3,s5
ffffffffc0202446:	00005617          	auipc	a2,0x5
ffffffffc020244a:	da260613          	addi	a2,a2,-606 # ffffffffc02071e8 <commands+0x7c8>
ffffffffc020244e:	1e800593          	li	a1,488
ffffffffc0202452:	00005517          	auipc	a0,0x5
ffffffffc0202456:	e5e50513          	addi	a0,a0,-418 # ffffffffc02072b0 <commands+0x890>
ffffffffc020245a:	daffd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc020245e:	00005697          	auipc	a3,0x5
ffffffffc0202462:	06268693          	addi	a3,a3,98 # ffffffffc02074c0 <commands+0xaa0>
ffffffffc0202466:	00005617          	auipc	a2,0x5
ffffffffc020246a:	9ca60613          	addi	a2,a2,-1590 # ffffffffc0206e30 <commands+0x410>
ffffffffc020246e:	1f600593          	li	a1,502
ffffffffc0202472:	00005517          	auipc	a0,0x5
ffffffffc0202476:	e3e50513          	addi	a0,a0,-450 # ffffffffc02072b0 <commands+0x890>
ffffffffc020247a:	d8ffd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc020247e:	00005697          	auipc	a3,0x5
ffffffffc0202482:	10a68693          	addi	a3,a3,266 # ffffffffc0207588 <commands+0xb68>
ffffffffc0202486:	00005617          	auipc	a2,0x5
ffffffffc020248a:	9aa60613          	addi	a2,a2,-1622 # ffffffffc0206e30 <commands+0x410>
ffffffffc020248e:	1f500593          	li	a1,501
ffffffffc0202492:	00005517          	auipc	a0,0x5
ffffffffc0202496:	e1e50513          	addi	a0,a0,-482 # ffffffffc02072b0 <commands+0x890>
ffffffffc020249a:	d6ffd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(page_ref(p1) == 2);
ffffffffc020249e:	00005697          	auipc	a3,0x5
ffffffffc02024a2:	0d268693          	addi	a3,a3,210 # ffffffffc0207570 <commands+0xb50>
ffffffffc02024a6:	00005617          	auipc	a2,0x5
ffffffffc02024aa:	98a60613          	addi	a2,a2,-1654 # ffffffffc0206e30 <commands+0x410>
ffffffffc02024ae:	1f400593          	li	a1,500
ffffffffc02024b2:	00005517          	auipc	a0,0x5
ffffffffc02024b6:	dfe50513          	addi	a0,a0,-514 # ffffffffc02072b0 <commands+0x890>
ffffffffc02024ba:	d4ffd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc02024be:	00005697          	auipc	a3,0x5
ffffffffc02024c2:	08268693          	addi	a3,a3,130 # ffffffffc0207540 <commands+0xb20>
ffffffffc02024c6:	00005617          	auipc	a2,0x5
ffffffffc02024ca:	96a60613          	addi	a2,a2,-1686 # ffffffffc0206e30 <commands+0x410>
ffffffffc02024ce:	1f300593          	li	a1,499
ffffffffc02024d2:	00005517          	auipc	a0,0x5
ffffffffc02024d6:	dde50513          	addi	a0,a0,-546 # ffffffffc02072b0 <commands+0x890>
ffffffffc02024da:	d2ffd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc02024de:	00005697          	auipc	a3,0x5
ffffffffc02024e2:	21a68693          	addi	a3,a3,538 # ffffffffc02076f8 <commands+0xcd8>
ffffffffc02024e6:	00005617          	auipc	a2,0x5
ffffffffc02024ea:	94a60613          	addi	a2,a2,-1718 # ffffffffc0206e30 <commands+0x410>
ffffffffc02024ee:	22200593          	li	a1,546
ffffffffc02024f2:	00005517          	auipc	a0,0x5
ffffffffc02024f6:	dbe50513          	addi	a0,a0,-578 # ffffffffc02072b0 <commands+0x890>
ffffffffc02024fa:	d0ffd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc02024fe:	00005697          	auipc	a3,0x5
ffffffffc0202502:	01268693          	addi	a3,a3,18 # ffffffffc0207510 <commands+0xaf0>
ffffffffc0202506:	00005617          	auipc	a2,0x5
ffffffffc020250a:	92a60613          	addi	a2,a2,-1750 # ffffffffc0206e30 <commands+0x410>
ffffffffc020250e:	1f000593          	li	a1,496
ffffffffc0202512:	00005517          	auipc	a0,0x5
ffffffffc0202516:	d9e50513          	addi	a0,a0,-610 # ffffffffc02072b0 <commands+0x890>
ffffffffc020251a:	ceffd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(*ptep & PTE_W);
ffffffffc020251e:	00005697          	auipc	a3,0x5
ffffffffc0202522:	fe268693          	addi	a3,a3,-30 # ffffffffc0207500 <commands+0xae0>
ffffffffc0202526:	00005617          	auipc	a2,0x5
ffffffffc020252a:	90a60613          	addi	a2,a2,-1782 # ffffffffc0206e30 <commands+0x410>
ffffffffc020252e:	1ef00593          	li	a1,495
ffffffffc0202532:	00005517          	auipc	a0,0x5
ffffffffc0202536:	d7e50513          	addi	a0,a0,-642 # ffffffffc02072b0 <commands+0x890>
ffffffffc020253a:	ccffd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(nr_free_store==nr_free_pages());
ffffffffc020253e:	00005697          	auipc	a3,0x5
ffffffffc0202542:	0ba68693          	addi	a3,a3,186 # ffffffffc02075f8 <commands+0xbd8>
ffffffffc0202546:	00005617          	auipc	a2,0x5
ffffffffc020254a:	8ea60613          	addi	a2,a2,-1814 # ffffffffc0206e30 <commands+0x410>
ffffffffc020254e:	23300593          	li	a1,563
ffffffffc0202552:	00005517          	auipc	a0,0x5
ffffffffc0202556:	d5e50513          	addi	a0,a0,-674 # ffffffffc02072b0 <commands+0x890>
ffffffffc020255a:	caffd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(*ptep & PTE_U);
ffffffffc020255e:	00005697          	auipc	a3,0x5
ffffffffc0202562:	f9268693          	addi	a3,a3,-110 # ffffffffc02074f0 <commands+0xad0>
ffffffffc0202566:	00005617          	auipc	a2,0x5
ffffffffc020256a:	8ca60613          	addi	a2,a2,-1846 # ffffffffc0206e30 <commands+0x410>
ffffffffc020256e:	1ee00593          	li	a1,494
ffffffffc0202572:	00005517          	auipc	a0,0x5
ffffffffc0202576:	d3e50513          	addi	a0,a0,-706 # ffffffffc02072b0 <commands+0x890>
ffffffffc020257a:	c8ffd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc020257e:	00005697          	auipc	a3,0x5
ffffffffc0202582:	eca68693          	addi	a3,a3,-310 # ffffffffc0207448 <commands+0xa28>
ffffffffc0202586:	00005617          	auipc	a2,0x5
ffffffffc020258a:	8aa60613          	addi	a2,a2,-1878 # ffffffffc0206e30 <commands+0x410>
ffffffffc020258e:	1fb00593          	li	a1,507
ffffffffc0202592:	00005517          	auipc	a0,0x5
ffffffffc0202596:	d1e50513          	addi	a0,a0,-738 # ffffffffc02072b0 <commands+0x890>
ffffffffc020259a:	c6ffd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc020259e:	00005697          	auipc	a3,0x5
ffffffffc02025a2:	00268693          	addi	a3,a3,2 # ffffffffc02075a0 <commands+0xb80>
ffffffffc02025a6:	00005617          	auipc	a2,0x5
ffffffffc02025aa:	88a60613          	addi	a2,a2,-1910 # ffffffffc0206e30 <commands+0x410>
ffffffffc02025ae:	1f800593          	li	a1,504
ffffffffc02025b2:	00005517          	auipc	a0,0x5
ffffffffc02025b6:	cfe50513          	addi	a0,a0,-770 # ffffffffc02072b0 <commands+0x890>
ffffffffc02025ba:	c4ffd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc02025be:	00005697          	auipc	a3,0x5
ffffffffc02025c2:	e7268693          	addi	a3,a3,-398 # ffffffffc0207430 <commands+0xa10>
ffffffffc02025c6:	00005617          	auipc	a2,0x5
ffffffffc02025ca:	86a60613          	addi	a2,a2,-1942 # ffffffffc0206e30 <commands+0x410>
ffffffffc02025ce:	1f700593          	li	a1,503
ffffffffc02025d2:	00005517          	auipc	a0,0x5
ffffffffc02025d6:	cde50513          	addi	a0,a0,-802 # ffffffffc02072b0 <commands+0x890>
ffffffffc02025da:	c2ffd0ef          	jal	ra,ffffffffc0200208 <__panic>
    return KADDR(page2pa(page));
ffffffffc02025de:	00005617          	auipc	a2,0x5
ffffffffc02025e2:	c0a60613          	addi	a2,a2,-1014 # ffffffffc02071e8 <commands+0x7c8>
ffffffffc02025e6:	06900593          	li	a1,105
ffffffffc02025ea:	00005517          	auipc	a0,0x5
ffffffffc02025ee:	bae50513          	addi	a0,a0,-1106 # ffffffffc0207198 <commands+0x778>
ffffffffc02025f2:	c17fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
ffffffffc02025f6:	00005697          	auipc	a3,0x5
ffffffffc02025fa:	fda68693          	addi	a3,a3,-38 # ffffffffc02075d0 <commands+0xbb0>
ffffffffc02025fe:	00005617          	auipc	a2,0x5
ffffffffc0202602:	83260613          	addi	a2,a2,-1998 # ffffffffc0206e30 <commands+0x410>
ffffffffc0202606:	20200593          	li	a1,514
ffffffffc020260a:	00005517          	auipc	a0,0x5
ffffffffc020260e:	ca650513          	addi	a0,a0,-858 # ffffffffc02072b0 <commands+0x890>
ffffffffc0202612:	bf7fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202616:	00005697          	auipc	a3,0x5
ffffffffc020261a:	f7268693          	addi	a3,a3,-142 # ffffffffc0207588 <commands+0xb68>
ffffffffc020261e:	00005617          	auipc	a2,0x5
ffffffffc0202622:	81260613          	addi	a2,a2,-2030 # ffffffffc0206e30 <commands+0x410>
ffffffffc0202626:	20000593          	li	a1,512
ffffffffc020262a:	00005517          	auipc	a0,0x5
ffffffffc020262e:	c8650513          	addi	a0,a0,-890 # ffffffffc02072b0 <commands+0x890>
ffffffffc0202632:	bd7fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(page_ref(p1) == 0);
ffffffffc0202636:	00005697          	auipc	a3,0x5
ffffffffc020263a:	f8268693          	addi	a3,a3,-126 # ffffffffc02075b8 <commands+0xb98>
ffffffffc020263e:	00004617          	auipc	a2,0x4
ffffffffc0202642:	7f260613          	addi	a2,a2,2034 # ffffffffc0206e30 <commands+0x410>
ffffffffc0202646:	1ff00593          	li	a1,511
ffffffffc020264a:	00005517          	auipc	a0,0x5
ffffffffc020264e:	c6650513          	addi	a0,a0,-922 # ffffffffc02072b0 <commands+0x890>
ffffffffc0202652:	bb7fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202656:	00005697          	auipc	a3,0x5
ffffffffc020265a:	f3268693          	addi	a3,a3,-206 # ffffffffc0207588 <commands+0xb68>
ffffffffc020265e:	00004617          	auipc	a2,0x4
ffffffffc0202662:	7d260613          	addi	a2,a2,2002 # ffffffffc0206e30 <commands+0x410>
ffffffffc0202666:	1fc00593          	li	a1,508
ffffffffc020266a:	00005517          	auipc	a0,0x5
ffffffffc020266e:	c4650513          	addi	a0,a0,-954 # ffffffffc02072b0 <commands+0x890>
ffffffffc0202672:	b97fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(page_ref(p) == 1);
ffffffffc0202676:	00005697          	auipc	a3,0x5
ffffffffc020267a:	06a68693          	addi	a3,a3,106 # ffffffffc02076e0 <commands+0xcc0>
ffffffffc020267e:	00004617          	auipc	a2,0x4
ffffffffc0202682:	7b260613          	addi	a2,a2,1970 # ffffffffc0206e30 <commands+0x410>
ffffffffc0202686:	22100593          	li	a1,545
ffffffffc020268a:	00005517          	auipc	a0,0x5
ffffffffc020268e:	c2650513          	addi	a0,a0,-986 # ffffffffc02072b0 <commands+0x890>
ffffffffc0202692:	b77fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202696:	00005697          	auipc	a3,0x5
ffffffffc020269a:	01268693          	addi	a3,a3,18 # ffffffffc02076a8 <commands+0xc88>
ffffffffc020269e:	00004617          	auipc	a2,0x4
ffffffffc02026a2:	79260613          	addi	a2,a2,1938 # ffffffffc0206e30 <commands+0x410>
ffffffffc02026a6:	22000593          	li	a1,544
ffffffffc02026aa:	00005517          	auipc	a0,0x5
ffffffffc02026ae:	c0650513          	addi	a0,a0,-1018 # ffffffffc02072b0 <commands+0x890>
ffffffffc02026b2:	b57fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(boot_pgdir[0] == 0);
ffffffffc02026b6:	00005697          	auipc	a3,0x5
ffffffffc02026ba:	fda68693          	addi	a3,a3,-38 # ffffffffc0207690 <commands+0xc70>
ffffffffc02026be:	00004617          	auipc	a2,0x4
ffffffffc02026c2:	77260613          	addi	a2,a2,1906 # ffffffffc0206e30 <commands+0x410>
ffffffffc02026c6:	21c00593          	li	a1,540
ffffffffc02026ca:	00005517          	auipc	a0,0x5
ffffffffc02026ce:	be650513          	addi	a0,a0,-1050 # ffffffffc02072b0 <commands+0x890>
ffffffffc02026d2:	b37fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(nr_free_store==nr_free_pages());
ffffffffc02026d6:	00005697          	auipc	a3,0x5
ffffffffc02026da:	f2268693          	addi	a3,a3,-222 # ffffffffc02075f8 <commands+0xbd8>
ffffffffc02026de:	00004617          	auipc	a2,0x4
ffffffffc02026e2:	75260613          	addi	a2,a2,1874 # ffffffffc0206e30 <commands+0x410>
ffffffffc02026e6:	20a00593          	li	a1,522
ffffffffc02026ea:	00005517          	auipc	a0,0x5
ffffffffc02026ee:	bc650513          	addi	a0,a0,-1082 # ffffffffc02072b0 <commands+0x890>
ffffffffc02026f2:	b17fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc02026f6:	00005697          	auipc	a3,0x5
ffffffffc02026fa:	d3a68693          	addi	a3,a3,-710 # ffffffffc0207430 <commands+0xa10>
ffffffffc02026fe:	00004617          	auipc	a2,0x4
ffffffffc0202702:	73260613          	addi	a2,a2,1842 # ffffffffc0206e30 <commands+0x410>
ffffffffc0202706:	1e400593          	li	a1,484
ffffffffc020270a:	00005517          	auipc	a0,0x5
ffffffffc020270e:	ba650513          	addi	a0,a0,-1114 # ffffffffc02072b0 <commands+0x890>
ffffffffc0202712:	af7fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc0202716:	00005617          	auipc	a2,0x5
ffffffffc020271a:	ad260613          	addi	a2,a2,-1326 # ffffffffc02071e8 <commands+0x7c8>
ffffffffc020271e:	1e700593          	li	a1,487
ffffffffc0202722:	00005517          	auipc	a0,0x5
ffffffffc0202726:	b8e50513          	addi	a0,a0,-1138 # ffffffffc02072b0 <commands+0x890>
ffffffffc020272a:	adffd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc020272e:	00005697          	auipc	a3,0x5
ffffffffc0202732:	d1a68693          	addi	a3,a3,-742 # ffffffffc0207448 <commands+0xa28>
ffffffffc0202736:	00004617          	auipc	a2,0x4
ffffffffc020273a:	6fa60613          	addi	a2,a2,1786 # ffffffffc0206e30 <commands+0x410>
ffffffffc020273e:	1e500593          	li	a1,485
ffffffffc0202742:	00005517          	auipc	a0,0x5
ffffffffc0202746:	b6e50513          	addi	a0,a0,-1170 # ffffffffc02072b0 <commands+0x890>
ffffffffc020274a:	abffd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc020274e:	00005697          	auipc	a3,0x5
ffffffffc0202752:	d7268693          	addi	a3,a3,-654 # ffffffffc02074c0 <commands+0xaa0>
ffffffffc0202756:	00004617          	auipc	a2,0x4
ffffffffc020275a:	6da60613          	addi	a2,a2,1754 # ffffffffc0206e30 <commands+0x410>
ffffffffc020275e:	1ed00593          	li	a1,493
ffffffffc0202762:	00005517          	auipc	a0,0x5
ffffffffc0202766:	b4e50513          	addi	a0,a0,-1202 # ffffffffc02072b0 <commands+0x890>
ffffffffc020276a:	a9ffd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc020276e:	00005697          	auipc	a3,0x5
ffffffffc0202772:	03268693          	addi	a3,a3,50 # ffffffffc02077a0 <commands+0xd80>
ffffffffc0202776:	00004617          	auipc	a2,0x4
ffffffffc020277a:	6ba60613          	addi	a2,a2,1722 # ffffffffc0206e30 <commands+0x410>
ffffffffc020277e:	22a00593          	li	a1,554
ffffffffc0202782:	00005517          	auipc	a0,0x5
ffffffffc0202786:	b2e50513          	addi	a0,a0,-1234 # ffffffffc02072b0 <commands+0x890>
ffffffffc020278a:	a7ffd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc020278e:	00005697          	auipc	a3,0x5
ffffffffc0202792:	fda68693          	addi	a3,a3,-38 # ffffffffc0207768 <commands+0xd48>
ffffffffc0202796:	00004617          	auipc	a2,0x4
ffffffffc020279a:	69a60613          	addi	a2,a2,1690 # ffffffffc0206e30 <commands+0x410>
ffffffffc020279e:	22700593          	li	a1,551
ffffffffc02027a2:	00005517          	auipc	a0,0x5
ffffffffc02027a6:	b0e50513          	addi	a0,a0,-1266 # ffffffffc02072b0 <commands+0x890>
ffffffffc02027aa:	a5ffd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(page_ref(p) == 2);
ffffffffc02027ae:	00005697          	auipc	a3,0x5
ffffffffc02027b2:	f8a68693          	addi	a3,a3,-118 # ffffffffc0207738 <commands+0xd18>
ffffffffc02027b6:	00004617          	auipc	a2,0x4
ffffffffc02027ba:	67a60613          	addi	a2,a2,1658 # ffffffffc0206e30 <commands+0x410>
ffffffffc02027be:	22300593          	li	a1,547
ffffffffc02027c2:	00005517          	auipc	a0,0x5
ffffffffc02027c6:	aee50513          	addi	a0,a0,-1298 # ffffffffc02072b0 <commands+0x890>
ffffffffc02027ca:	a3ffd0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc02027ce <tlb_invalidate>:
    asm volatile("sfence.vma %0" : : "r"(la)); // 执行sfence.vma指令使TLB无效
ffffffffc02027ce:	12058073          	sfence.vma	a1
}
ffffffffc02027d2:	8082                	ret

ffffffffc02027d4 <pgdir_alloc_page>:
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
ffffffffc02027d4:	7179                	addi	sp,sp,-48
ffffffffc02027d6:	e84a                	sd	s2,16(sp)
ffffffffc02027d8:	892a                	mv	s2,a0
    struct Page *page = alloc_page(); // 分配一个页
ffffffffc02027da:	4505                	li	a0,1
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
ffffffffc02027dc:	f022                	sd	s0,32(sp)
ffffffffc02027de:	ec26                	sd	s1,24(sp)
ffffffffc02027e0:	e44e                	sd	s3,8(sp)
ffffffffc02027e2:	f406                	sd	ra,40(sp)
ffffffffc02027e4:	84ae                	mv	s1,a1
ffffffffc02027e6:	89b2                	mv	s3,a2
    struct Page *page = alloc_page(); // 分配一个页
ffffffffc02027e8:	bb1fe0ef          	jal	ra,ffffffffc0201398 <alloc_pages>
ffffffffc02027ec:	842a                	mv	s0,a0
    if (page != NULL) { // 如果页不为空
ffffffffc02027ee:	cd05                	beqz	a0,ffffffffc0202826 <pgdir_alloc_page+0x52>
        if (page_insert(pgdir, page, la, perm) != 0) { // 插入页表项失败
ffffffffc02027f0:	85aa                	mv	a1,a0
ffffffffc02027f2:	86ce                	mv	a3,s3
ffffffffc02027f4:	8626                	mv	a2,s1
ffffffffc02027f6:	854a                	mv	a0,s2
ffffffffc02027f8:	b46ff0ef          	jal	ra,ffffffffc0201b3e <page_insert>
ffffffffc02027fc:	ed0d                	bnez	a0,ffffffffc0202836 <pgdir_alloc_page+0x62>
        if (swap_init_ok) { // 如果交换初始化成功
ffffffffc02027fe:	000b0797          	auipc	a5,0xb0
ffffffffc0202802:	0ba7a783          	lw	a5,186(a5) # ffffffffc02b28b8 <swap_init_ok>
ffffffffc0202806:	c385                	beqz	a5,ffffffffc0202826 <pgdir_alloc_page+0x52>
            if (check_mm_struct != NULL) { // 如果check_mm_struct不为空
ffffffffc0202808:	000b0517          	auipc	a0,0xb0
ffffffffc020280c:	09053503          	ld	a0,144(a0) # ffffffffc02b2898 <check_mm_struct>
ffffffffc0202810:	c919                	beqz	a0,ffffffffc0202826 <pgdir_alloc_page+0x52>
                swap_map_swappable(check_mm_struct, la, page, 0); // 将页标记为可交换
ffffffffc0202812:	4681                	li	a3,0
ffffffffc0202814:	8622                	mv	a2,s0
ffffffffc0202816:	85a6                	mv	a1,s1
ffffffffc0202818:	1fa010ef          	jal	ra,ffffffffc0203a12 <swap_map_swappable>
                assert(page_ref(page) == 1); // 确认页的引用计数为1
ffffffffc020281c:	4018                	lw	a4,0(s0)
                page->pra_vaddr = la; // 设置页的虚拟地址
ffffffffc020281e:	fc04                	sd	s1,56(s0)
                assert(page_ref(page) == 1); // 确认页的引用计数为1
ffffffffc0202820:	4785                	li	a5,1
ffffffffc0202822:	04f71663          	bne	a4,a5,ffffffffc020286e <pgdir_alloc_page+0x9a>
}
ffffffffc0202826:	70a2                	ld	ra,40(sp)
ffffffffc0202828:	8522                	mv	a0,s0
ffffffffc020282a:	7402                	ld	s0,32(sp)
ffffffffc020282c:	64e2                	ld	s1,24(sp)
ffffffffc020282e:	6942                	ld	s2,16(sp)
ffffffffc0202830:	69a2                	ld	s3,8(sp)
ffffffffc0202832:	6145                	addi	sp,sp,48
ffffffffc0202834:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202836:	100027f3          	csrr	a5,sstatus
ffffffffc020283a:	8b89                	andi	a5,a5,2
ffffffffc020283c:	eb99                	bnez	a5,ffffffffc0202852 <pgdir_alloc_page+0x7e>
        pmm_manager->free_pages(base, n); // 释放页
ffffffffc020283e:	000b0797          	auipc	a5,0xb0
ffffffffc0202842:	04a7b783          	ld	a5,74(a5) # ffffffffc02b2888 <pmm_manager>
ffffffffc0202846:	739c                	ld	a5,32(a5)
ffffffffc0202848:	8522                	mv	a0,s0
ffffffffc020284a:	4585                	li	a1,1
ffffffffc020284c:	9782                	jalr	a5
            return NULL; // 返回NULL
ffffffffc020284e:	4401                	li	s0,0
ffffffffc0202850:	bfd9                	j	ffffffffc0202826 <pgdir_alloc_page+0x52>
        intr_disable();
ffffffffc0202852:	df7fd0ef          	jal	ra,ffffffffc0200648 <intr_disable>
        pmm_manager->free_pages(base, n); // 释放页
ffffffffc0202856:	000b0797          	auipc	a5,0xb0
ffffffffc020285a:	0327b783          	ld	a5,50(a5) # ffffffffc02b2888 <pmm_manager>
ffffffffc020285e:	739c                	ld	a5,32(a5)
ffffffffc0202860:	8522                	mv	a0,s0
ffffffffc0202862:	4585                	li	a1,1
ffffffffc0202864:	9782                	jalr	a5
            return NULL; // 返回NULL
ffffffffc0202866:	4401                	li	s0,0
        intr_enable();
ffffffffc0202868:	ddbfd0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc020286c:	bf6d                	j	ffffffffc0202826 <pgdir_alloc_page+0x52>
                assert(page_ref(page) == 1); // 确认页的引用计数为1
ffffffffc020286e:	00005697          	auipc	a3,0x5
ffffffffc0202872:	f7a68693          	addi	a3,a3,-134 # ffffffffc02077e8 <commands+0xdc8>
ffffffffc0202876:	00004617          	auipc	a2,0x4
ffffffffc020287a:	5ba60613          	addi	a2,a2,1466 # ffffffffc0206e30 <commands+0x410>
ffffffffc020287e:	1bb00593          	li	a1,443
ffffffffc0202882:	00005517          	auipc	a0,0x5
ffffffffc0202886:	a2e50513          	addi	a0,a0,-1490 # ffffffffc02072b0 <commands+0x890>
ffffffffc020288a:	97ffd0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc020288e <check_vma_overlap.part.0>:
}


// check_vma_overlap - 检查vma1是否与vma2重叠
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next) {
ffffffffc020288e:	1141                	addi	sp,sp,-16
        assert(prev->vm_start < prev->vm_end);
        assert(prev->vm_end <= next->vm_start);
        assert(next->vm_start < next->vm_end);
ffffffffc0202890:	00005697          	auipc	a3,0x5
ffffffffc0202894:	f7068693          	addi	a3,a3,-144 # ffffffffc0207800 <commands+0xde0>
ffffffffc0202898:	00004617          	auipc	a2,0x4
ffffffffc020289c:	59860613          	addi	a2,a2,1432 # ffffffffc0206e30 <commands+0x410>
ffffffffc02028a0:	06d00593          	li	a1,109
ffffffffc02028a4:	00005517          	auipc	a0,0x5
ffffffffc02028a8:	f7c50513          	addi	a0,a0,-132 # ffffffffc0207820 <commands+0xe00>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next) {
ffffffffc02028ac:	e406                	sd	ra,8(sp)
        assert(next->vm_start < next->vm_end);
ffffffffc02028ae:	95bfd0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc02028b2 <mm_create>:
mm_create(void) {
ffffffffc02028b2:	1141                	addi	sp,sp,-16
        struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02028b4:	04000513          	li	a0,64
mm_create(void) {
ffffffffc02028b8:	e022                	sd	s0,0(sp)
ffffffffc02028ba:	e406                	sd	ra,8(sp)
        struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02028bc:	522010ef          	jal	ra,ffffffffc0203dde <kmalloc>
ffffffffc02028c0:	842a                	mv	s0,a0
        if (mm != NULL) {
ffffffffc02028c2:	c505                	beqz	a0,ffffffffc02028ea <mm_create+0x38>
    elm->prev = elm->next = elm;
ffffffffc02028c4:	e408                	sd	a0,8(s0)
ffffffffc02028c6:	e008                	sd	a0,0(s0)
                mm->mmap_cache = NULL;
ffffffffc02028c8:	00053823          	sd	zero,16(a0)
                mm->pgdir = NULL;
ffffffffc02028cc:	00053c23          	sd	zero,24(a0)
                mm->map_count = 0;
ffffffffc02028d0:	02052023          	sw	zero,32(a0)
                if (swap_init_ok) swap_init_mm(mm); // 如果swap初始化成功，则初始化mm的swap相关字段
ffffffffc02028d4:	000b0797          	auipc	a5,0xb0
ffffffffc02028d8:	fe47a783          	lw	a5,-28(a5) # ffffffffc02b28b8 <swap_init_ok>
ffffffffc02028dc:	ef81                	bnez	a5,ffffffffc02028f4 <mm_create+0x42>
                else mm->sm_priv = NULL;
ffffffffc02028de:	02053423          	sd	zero,40(a0)
    mm->mm_count = val;
ffffffffc02028e2:	02042823          	sw	zero,48(s0)
    *lock = 0;
ffffffffc02028e6:	02043c23          	sd	zero,56(s0)
}
ffffffffc02028ea:	60a2                	ld	ra,8(sp)
ffffffffc02028ec:	8522                	mv	a0,s0
ffffffffc02028ee:	6402                	ld	s0,0(sp)
ffffffffc02028f0:	0141                	addi	sp,sp,16
ffffffffc02028f2:	8082                	ret
                if (swap_init_ok) swap_init_mm(mm); // 如果swap初始化成功，则初始化mm的swap相关字段
ffffffffc02028f4:	112010ef          	jal	ra,ffffffffc0203a06 <swap_init_mm>
ffffffffc02028f8:	b7ed                	j	ffffffffc02028e2 <mm_create+0x30>

ffffffffc02028fa <vma_create>:
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint32_t vm_flags) {
ffffffffc02028fa:	1101                	addi	sp,sp,-32
ffffffffc02028fc:	e04a                	sd	s2,0(sp)
ffffffffc02028fe:	892a                	mv	s2,a0
        struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202900:	03000513          	li	a0,48
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint32_t vm_flags) {
ffffffffc0202904:	e822                	sd	s0,16(sp)
ffffffffc0202906:	e426                	sd	s1,8(sp)
ffffffffc0202908:	ec06                	sd	ra,24(sp)
ffffffffc020290a:	84ae                	mv	s1,a1
ffffffffc020290c:	8432                	mv	s0,a2
        struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020290e:	4d0010ef          	jal	ra,ffffffffc0203dde <kmalloc>
        if (vma != NULL) {
ffffffffc0202912:	c509                	beqz	a0,ffffffffc020291c <vma_create+0x22>
                vma->vm_start = vm_start;
ffffffffc0202914:	01253423          	sd	s2,8(a0)
                vma->vm_end = vm_end;
ffffffffc0202918:	e904                	sd	s1,16(a0)
                vma->vm_flags = vm_flags;
ffffffffc020291a:	cd00                	sw	s0,24(a0)
}
ffffffffc020291c:	60e2                	ld	ra,24(sp)
ffffffffc020291e:	6442                	ld	s0,16(sp)
ffffffffc0202920:	64a2                	ld	s1,8(sp)
ffffffffc0202922:	6902                	ld	s2,0(sp)
ffffffffc0202924:	6105                	addi	sp,sp,32
ffffffffc0202926:	8082                	ret

ffffffffc0202928 <find_vma>:
find_vma(struct mm_struct *mm, uintptr_t addr) {
ffffffffc0202928:	86aa                	mv	a3,a0
        if (mm != NULL) {
ffffffffc020292a:	c505                	beqz	a0,ffffffffc0202952 <find_vma+0x2a>
                vma = mm->mmap_cache;
ffffffffc020292c:	6908                	ld	a0,16(a0)
                if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) {
ffffffffc020292e:	c501                	beqz	a0,ffffffffc0202936 <find_vma+0xe>
ffffffffc0202930:	651c                	ld	a5,8(a0)
ffffffffc0202932:	02f5f263          	bgeu	a1,a5,ffffffffc0202956 <find_vma+0x2e>
    return listelm->next;
ffffffffc0202936:	669c                	ld	a5,8(a3)
                                while ((le = list_next(le)) != list) {
ffffffffc0202938:	00f68d63          	beq	a3,a5,ffffffffc0202952 <find_vma+0x2a>
                                        if (vma->vm_start<=addr && addr < vma->vm_end) {
ffffffffc020293c:	fe87b703          	ld	a4,-24(a5)
ffffffffc0202940:	00e5e663          	bltu	a1,a4,ffffffffc020294c <find_vma+0x24>
ffffffffc0202944:	ff07b703          	ld	a4,-16(a5)
ffffffffc0202948:	00e5ec63          	bltu	a1,a4,ffffffffc0202960 <find_vma+0x38>
ffffffffc020294c:	679c                	ld	a5,8(a5)
                                while ((le = list_next(le)) != list) {
ffffffffc020294e:	fef697e3          	bne	a3,a5,ffffffffc020293c <find_vma+0x14>
        struct vma_struct *vma = NULL;
ffffffffc0202952:	4501                	li	a0,0
}
ffffffffc0202954:	8082                	ret
                if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) {
ffffffffc0202956:	691c                	ld	a5,16(a0)
ffffffffc0202958:	fcf5ffe3          	bgeu	a1,a5,ffffffffc0202936 <find_vma+0xe>
                        mm->mmap_cache = vma; // 更新mmap_cache
ffffffffc020295c:	ea88                	sd	a0,16(a3)
ffffffffc020295e:	8082                	ret
                                        vma = le2vma(le, list_link);
ffffffffc0202960:	fe078513          	addi	a0,a5,-32
                        mm->mmap_cache = vma; // 更新mmap_cache
ffffffffc0202964:	ea88                	sd	a0,16(a3)
ffffffffc0202966:	8082                	ret

ffffffffc0202968 <insert_vma_struct>:


// insert_vma_struct - 将vma插入到mm的链表中
void
insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma) {
        assert(vma->vm_start < vma->vm_end);
ffffffffc0202968:	6590                	ld	a2,8(a1)
ffffffffc020296a:	0105b803          	ld	a6,16(a1)
insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma) {
ffffffffc020296e:	1141                	addi	sp,sp,-16
ffffffffc0202970:	e406                	sd	ra,8(sp)
ffffffffc0202972:	87aa                	mv	a5,a0
        assert(vma->vm_start < vma->vm_end);
ffffffffc0202974:	01066763          	bltu	a2,a6,ffffffffc0202982 <insert_vma_struct+0x1a>
ffffffffc0202978:	a085                	j	ffffffffc02029d8 <insert_vma_struct+0x70>
        list_entry_t *le_prev = list, *le_next;

                list_entry_t *le = list;
                while ((le = list_next(le)) != list) {
                        struct vma_struct *mmap_prev = le2vma(le, list_link);
                        if (mmap_prev->vm_start > vma->vm_start) {
ffffffffc020297a:	fe87b703          	ld	a4,-24(a5)
ffffffffc020297e:	04e66863          	bltu	a2,a4,ffffffffc02029ce <insert_vma_struct+0x66>
ffffffffc0202982:	86be                	mv	a3,a5
ffffffffc0202984:	679c                	ld	a5,8(a5)
                while ((le = list_next(le)) != list) {
ffffffffc0202986:	fef51ae3          	bne	a0,a5,ffffffffc020297a <insert_vma_struct+0x12>
                }

        le_next = list_next(le_prev);

        /* 检查重叠 */
        if (le_prev != list) {
ffffffffc020298a:	02a68463          	beq	a3,a0,ffffffffc02029b2 <insert_vma_struct+0x4a>
                check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc020298e:	ff06b703          	ld	a4,-16(a3)
        assert(prev->vm_start < prev->vm_end);
ffffffffc0202992:	fe86b883          	ld	a7,-24(a3)
ffffffffc0202996:	08e8f163          	bgeu	a7,a4,ffffffffc0202a18 <insert_vma_struct+0xb0>
        assert(prev->vm_end <= next->vm_start);
ffffffffc020299a:	04e66f63          	bltu	a2,a4,ffffffffc02029f8 <insert_vma_struct+0x90>
        }
        if (le_next != list) {
ffffffffc020299e:	00f50a63          	beq	a0,a5,ffffffffc02029b2 <insert_vma_struct+0x4a>
                        if (mmap_prev->vm_start > vma->vm_start) {
ffffffffc02029a2:	fe87b703          	ld	a4,-24(a5)
        assert(prev->vm_end <= next->vm_start);
ffffffffc02029a6:	05076963          	bltu	a4,a6,ffffffffc02029f8 <insert_vma_struct+0x90>
        assert(next->vm_start < next->vm_end);
ffffffffc02029aa:	ff07b603          	ld	a2,-16(a5)
ffffffffc02029ae:	02c77363          	bgeu	a4,a2,ffffffffc02029d4 <insert_vma_struct+0x6c>
        }

        vma->vm_mm = mm;
        list_add_after(le_prev, &(vma->list_link)); // 将vma插入到链表中

        mm->map_count ++;
ffffffffc02029b2:	5118                	lw	a4,32(a0)
        vma->vm_mm = mm;
ffffffffc02029b4:	e188                	sd	a0,0(a1)
        list_add_after(le_prev, &(vma->list_link)); // 将vma插入到链表中
ffffffffc02029b6:	02058613          	addi	a2,a1,32
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc02029ba:	e390                	sd	a2,0(a5)
ffffffffc02029bc:	e690                	sd	a2,8(a3)
}
ffffffffc02029be:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc02029c0:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc02029c2:	f194                	sd	a3,32(a1)
        mm->map_count ++;
ffffffffc02029c4:	0017079b          	addiw	a5,a4,1
ffffffffc02029c8:	d11c                	sw	a5,32(a0)
}
ffffffffc02029ca:	0141                	addi	sp,sp,16
ffffffffc02029cc:	8082                	ret
        if (le_prev != list) {
ffffffffc02029ce:	fca690e3          	bne	a3,a0,ffffffffc020298e <insert_vma_struct+0x26>
ffffffffc02029d2:	bfd1                	j	ffffffffc02029a6 <insert_vma_struct+0x3e>
ffffffffc02029d4:	ebbff0ef          	jal	ra,ffffffffc020288e <check_vma_overlap.part.0>
        assert(vma->vm_start < vma->vm_end);
ffffffffc02029d8:	00005697          	auipc	a3,0x5
ffffffffc02029dc:	e5868693          	addi	a3,a3,-424 # ffffffffc0207830 <commands+0xe10>
ffffffffc02029e0:	00004617          	auipc	a2,0x4
ffffffffc02029e4:	45060613          	addi	a2,a2,1104 # ffffffffc0206e30 <commands+0x410>
ffffffffc02029e8:	07400593          	li	a1,116
ffffffffc02029ec:	00005517          	auipc	a0,0x5
ffffffffc02029f0:	e3450513          	addi	a0,a0,-460 # ffffffffc0207820 <commands+0xe00>
ffffffffc02029f4:	815fd0ef          	jal	ra,ffffffffc0200208 <__panic>
        assert(prev->vm_end <= next->vm_start);
ffffffffc02029f8:	00005697          	auipc	a3,0x5
ffffffffc02029fc:	e7868693          	addi	a3,a3,-392 # ffffffffc0207870 <commands+0xe50>
ffffffffc0202a00:	00004617          	auipc	a2,0x4
ffffffffc0202a04:	43060613          	addi	a2,a2,1072 # ffffffffc0206e30 <commands+0x410>
ffffffffc0202a08:	06c00593          	li	a1,108
ffffffffc0202a0c:	00005517          	auipc	a0,0x5
ffffffffc0202a10:	e1450513          	addi	a0,a0,-492 # ffffffffc0207820 <commands+0xe00>
ffffffffc0202a14:	ff4fd0ef          	jal	ra,ffffffffc0200208 <__panic>
        assert(prev->vm_start < prev->vm_end);
ffffffffc0202a18:	00005697          	auipc	a3,0x5
ffffffffc0202a1c:	e3868693          	addi	a3,a3,-456 # ffffffffc0207850 <commands+0xe30>
ffffffffc0202a20:	00004617          	auipc	a2,0x4
ffffffffc0202a24:	41060613          	addi	a2,a2,1040 # ffffffffc0206e30 <commands+0x410>
ffffffffc0202a28:	06b00593          	li	a1,107
ffffffffc0202a2c:	00005517          	auipc	a0,0x5
ffffffffc0202a30:	df450513          	addi	a0,a0,-524 # ffffffffc0207820 <commands+0xe00>
ffffffffc0202a34:	fd4fd0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0202a38 <mm_destroy>:

// mm_destroy - 释放mm和mm内部的字段
void
mm_destroy(struct mm_struct *mm) {
        assert(mm_count(mm) == 0);
ffffffffc0202a38:	591c                	lw	a5,48(a0)
mm_destroy(struct mm_struct *mm) {
ffffffffc0202a3a:	1141                	addi	sp,sp,-16
ffffffffc0202a3c:	e406                	sd	ra,8(sp)
ffffffffc0202a3e:	e022                	sd	s0,0(sp)
        assert(mm_count(mm) == 0);
ffffffffc0202a40:	e78d                	bnez	a5,ffffffffc0202a6a <mm_destroy+0x32>
ffffffffc0202a42:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc0202a44:	6508                	ld	a0,8(a0)

        list_entry_t *list = &(mm->mmap_list), *le;
        while ((le = list_next(list)) != list) {
ffffffffc0202a46:	00a40c63          	beq	s0,a0,ffffffffc0202a5e <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc0202a4a:	6118                	ld	a4,0(a0)
ffffffffc0202a4c:	651c                	ld	a5,8(a0)
                list_del(le);
                kfree(le2vma(le, list_link));  // 释放vma        
ffffffffc0202a4e:	1501                	addi	a0,a0,-32
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0202a50:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0202a52:	e398                	sd	a4,0(a5)
ffffffffc0202a54:	43a010ef          	jal	ra,ffffffffc0203e8e <kfree>
    return listelm->next;
ffffffffc0202a58:	6408                	ld	a0,8(s0)
        while ((le = list_next(list)) != list) {
ffffffffc0202a5a:	fea418e3          	bne	s0,a0,ffffffffc0202a4a <mm_destroy+0x12>
        }
        kfree(mm); // 释放mm
ffffffffc0202a5e:	8522                	mv	a0,s0
        mm=NULL;
}
ffffffffc0202a60:	6402                	ld	s0,0(sp)
ffffffffc0202a62:	60a2                	ld	ra,8(sp)
ffffffffc0202a64:	0141                	addi	sp,sp,16
        kfree(mm); // 释放mm
ffffffffc0202a66:	4280106f          	j	ffffffffc0203e8e <kfree>
        assert(mm_count(mm) == 0);
ffffffffc0202a6a:	00005697          	auipc	a3,0x5
ffffffffc0202a6e:	e2668693          	addi	a3,a3,-474 # ffffffffc0207890 <commands+0xe70>
ffffffffc0202a72:	00004617          	auipc	a2,0x4
ffffffffc0202a76:	3be60613          	addi	a2,a2,958 # ffffffffc0206e30 <commands+0x410>
ffffffffc0202a7a:	09400593          	li	a1,148
ffffffffc0202a7e:	00005517          	auipc	a0,0x5
ffffffffc0202a82:	da250513          	addi	a0,a0,-606 # ffffffffc0207820 <commands+0xe00>
ffffffffc0202a86:	f82fd0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0202a8a <mm_map>:

// mm_map - 将地址范围[start, end)映射到mm中
int
mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
             struct vma_struct **vma_store) {
ffffffffc0202a8a:	7139                	addi	sp,sp,-64
ffffffffc0202a8c:	f822                	sd	s0,48(sp)
        uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0202a8e:	6405                	lui	s0,0x1
ffffffffc0202a90:	147d                	addi	s0,s0,-1
ffffffffc0202a92:	77fd                	lui	a5,0xfffff
ffffffffc0202a94:	9622                	add	a2,a2,s0
ffffffffc0202a96:	962e                	add	a2,a2,a1
             struct vma_struct **vma_store) {
ffffffffc0202a98:	f426                	sd	s1,40(sp)
ffffffffc0202a9a:	fc06                	sd	ra,56(sp)
        uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0202a9c:	00f5f4b3          	and	s1,a1,a5
             struct vma_struct **vma_store) {
ffffffffc0202aa0:	f04a                	sd	s2,32(sp)
ffffffffc0202aa2:	ec4e                	sd	s3,24(sp)
ffffffffc0202aa4:	e852                	sd	s4,16(sp)
ffffffffc0202aa6:	e456                	sd	s5,8(sp)
        if (!USER_ACCESS(start, end)) {
ffffffffc0202aa8:	002005b7          	lui	a1,0x200
ffffffffc0202aac:	00f67433          	and	s0,a2,a5
ffffffffc0202ab0:	06b4e363          	bltu	s1,a1,ffffffffc0202b16 <mm_map+0x8c>
ffffffffc0202ab4:	0684f163          	bgeu	s1,s0,ffffffffc0202b16 <mm_map+0x8c>
ffffffffc0202ab8:	4785                	li	a5,1
ffffffffc0202aba:	07fe                	slli	a5,a5,0x1f
ffffffffc0202abc:	0487ed63          	bltu	a5,s0,ffffffffc0202b16 <mm_map+0x8c>
ffffffffc0202ac0:	89aa                	mv	s3,a0
                return -E_INVAL;
        }

        assert(mm != NULL);
ffffffffc0202ac2:	cd21                	beqz	a0,ffffffffc0202b1a <mm_map+0x90>

        int ret = -E_INVAL;

        struct vma_struct *vma;
        if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start) {
ffffffffc0202ac4:	85a6                	mv	a1,s1
ffffffffc0202ac6:	8ab6                	mv	s5,a3
ffffffffc0202ac8:	8a3a                	mv	s4,a4
ffffffffc0202aca:	e5fff0ef          	jal	ra,ffffffffc0202928 <find_vma>
ffffffffc0202ace:	c501                	beqz	a0,ffffffffc0202ad6 <mm_map+0x4c>
ffffffffc0202ad0:	651c                	ld	a5,8(a0)
ffffffffc0202ad2:	0487e263          	bltu	a5,s0,ffffffffc0202b16 <mm_map+0x8c>
        struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202ad6:	03000513          	li	a0,48
ffffffffc0202ada:	304010ef          	jal	ra,ffffffffc0203dde <kmalloc>
ffffffffc0202ade:	892a                	mv	s2,a0
                goto out;
        }
        ret = -E_NO_MEM;
ffffffffc0202ae0:	5571                	li	a0,-4
        if (vma != NULL) {
ffffffffc0202ae2:	02090163          	beqz	s2,ffffffffc0202b04 <mm_map+0x7a>

        if ((vma = vma_create(start, end, vm_flags)) == NULL) {
                goto out;
        }
        insert_vma_struct(mm, vma);
ffffffffc0202ae6:	854e                	mv	a0,s3
                vma->vm_start = vm_start;
ffffffffc0202ae8:	00993423          	sd	s1,8(s2)
                vma->vm_end = vm_end;
ffffffffc0202aec:	00893823          	sd	s0,16(s2)
                vma->vm_flags = vm_flags;
ffffffffc0202af0:	01592c23          	sw	s5,24(s2)
        insert_vma_struct(mm, vma);
ffffffffc0202af4:	85ca                	mv	a1,s2
ffffffffc0202af6:	e73ff0ef          	jal	ra,ffffffffc0202968 <insert_vma_struct>
        if (vma_store != NULL) {
                *vma_store = vma;
        }
        ret = 0;
ffffffffc0202afa:	4501                	li	a0,0
        if (vma_store != NULL) {
ffffffffc0202afc:	000a0463          	beqz	s4,ffffffffc0202b04 <mm_map+0x7a>
                *vma_store = vma;
ffffffffc0202b00:	012a3023          	sd	s2,0(s4)

out:
        return ret;
}
ffffffffc0202b04:	70e2                	ld	ra,56(sp)
ffffffffc0202b06:	7442                	ld	s0,48(sp)
ffffffffc0202b08:	74a2                	ld	s1,40(sp)
ffffffffc0202b0a:	7902                	ld	s2,32(sp)
ffffffffc0202b0c:	69e2                	ld	s3,24(sp)
ffffffffc0202b0e:	6a42                	ld	s4,16(sp)
ffffffffc0202b10:	6aa2                	ld	s5,8(sp)
ffffffffc0202b12:	6121                	addi	sp,sp,64
ffffffffc0202b14:	8082                	ret
                return -E_INVAL;
ffffffffc0202b16:	5575                	li	a0,-3
ffffffffc0202b18:	b7f5                	j	ffffffffc0202b04 <mm_map+0x7a>
        assert(mm != NULL);
ffffffffc0202b1a:	00005697          	auipc	a3,0x5
ffffffffc0202b1e:	d8e68693          	addi	a3,a3,-626 # ffffffffc02078a8 <commands+0xe88>
ffffffffc0202b22:	00004617          	auipc	a2,0x4
ffffffffc0202b26:	30e60613          	addi	a2,a2,782 # ffffffffc0206e30 <commands+0x410>
ffffffffc0202b2a:	0a800593          	li	a1,168
ffffffffc0202b2e:	00005517          	auipc	a0,0x5
ffffffffc0202b32:	cf250513          	addi	a0,a0,-782 # ffffffffc0207820 <commands+0xe00>
ffffffffc0202b36:	ed2fd0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0202b3a <exit_mmap>:
    }
    return 0;
}

void
exit_mmap(struct mm_struct *mm) {
ffffffffc0202b3a:	1101                	addi	sp,sp,-32
ffffffffc0202b3c:	ec06                	sd	ra,24(sp)
ffffffffc0202b3e:	e822                	sd	s0,16(sp)
ffffffffc0202b40:	e426                	sd	s1,8(sp)
ffffffffc0202b42:	e04a                	sd	s2,0(sp)
    assert(mm != NULL && mm_count(mm) == 0); // 确保mm不为空且引用计数为0
ffffffffc0202b44:	c531                	beqz	a0,ffffffffc0202b90 <exit_mmap+0x56>
ffffffffc0202b46:	591c                	lw	a5,48(a0)
ffffffffc0202b48:	84aa                	mv	s1,a0
ffffffffc0202b4a:	e3b9                	bnez	a5,ffffffffc0202b90 <exit_mmap+0x56>
ffffffffc0202b4c:	6500                	ld	s0,8(a0)
    pde_t *pgdir = mm->pgdir; // 获取页目录表指针
ffffffffc0202b4e:	01853903          	ld	s2,24(a0)
    list_entry_t *list = &(mm->mmap_list), *le = list; // 获取mm的mmap_list链表
    while ((le = list_next(le)) != list) { // 遍历链表
ffffffffc0202b52:	02850663          	beq	a0,s0,ffffffffc0202b7e <exit_mmap+0x44>
        struct vma_struct *vma = le2vma(le, list_link); // 获取vma结构体
        unmap_range(pgdir, vma->vm_start, vma->vm_end); // 取消映射vma的地址范围
ffffffffc0202b56:	ff043603          	ld	a2,-16(s0) # ff0 <_binary_obj___user_faultread_out_size-0x8bc8>
ffffffffc0202b5a:	fe843583          	ld	a1,-24(s0)
ffffffffc0202b5e:	854a                	mv	a0,s2
ffffffffc0202b60:	b6bfe0ef          	jal	ra,ffffffffc02016ca <unmap_range>
ffffffffc0202b64:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list) { // 遍历链表
ffffffffc0202b66:	fe8498e3          	bne	s1,s0,ffffffffc0202b56 <exit_mmap+0x1c>
ffffffffc0202b6a:	6400                	ld	s0,8(s0)
    }
    while ((le = list_next(le)) != list) { // 再次遍历链表
ffffffffc0202b6c:	00848c63          	beq	s1,s0,ffffffffc0202b84 <exit_mmap+0x4a>
        struct vma_struct *vma = le2vma(le, list_link); // 获取vma结构体
        exit_range(pgdir, vma->vm_start, vma->vm_end); // 释放vma的地址范围
ffffffffc0202b70:	ff043603          	ld	a2,-16(s0)
ffffffffc0202b74:	fe843583          	ld	a1,-24(s0)
ffffffffc0202b78:	854a                	mv	a0,s2
ffffffffc0202b7a:	c97fe0ef          	jal	ra,ffffffffc0201810 <exit_range>
ffffffffc0202b7e:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list) { // 再次遍历链表
ffffffffc0202b80:	fe8498e3          	bne	s1,s0,ffffffffc0202b70 <exit_mmap+0x36>
    }
}
ffffffffc0202b84:	60e2                	ld	ra,24(sp)
ffffffffc0202b86:	6442                	ld	s0,16(sp)
ffffffffc0202b88:	64a2                	ld	s1,8(sp)
ffffffffc0202b8a:	6902                	ld	s2,0(sp)
ffffffffc0202b8c:	6105                	addi	sp,sp,32
ffffffffc0202b8e:	8082                	ret
    assert(mm != NULL && mm_count(mm) == 0); // 确保mm不为空且引用计数为0
ffffffffc0202b90:	00005697          	auipc	a3,0x5
ffffffffc0202b94:	d2868693          	addi	a3,a3,-728 # ffffffffc02078b8 <commands+0xe98>
ffffffffc0202b98:	00004617          	auipc	a2,0x4
ffffffffc0202b9c:	29860613          	addi	a2,a2,664 # ffffffffc0206e30 <commands+0x410>
ffffffffc0202ba0:	0e500593          	li	a1,229
ffffffffc0202ba4:	00005517          	auipc	a0,0x5
ffffffffc0202ba8:	c7c50513          	addi	a0,a0,-900 # ffffffffc0207820 <commands+0xe00>
ffffffffc0202bac:	e5cfd0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0202bb0 <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void
vmm_init(void) {
ffffffffc0202bb0:	7139                	addi	sp,sp,-64
ffffffffc0202bb2:	f822                	sd	s0,48(sp)
ffffffffc0202bb4:	f426                	sd	s1,40(sp)
ffffffffc0202bb6:	fc06                	sd	ra,56(sp)
ffffffffc0202bb8:	f04a                	sd	s2,32(sp)
ffffffffc0202bba:	ec4e                	sd	s3,24(sp)
ffffffffc0202bbc:	e852                	sd	s4,16(sp)
ffffffffc0202bbe:	e456                	sd	s5,8(sp)

static void
check_vma_struct(void) {
    // size_t nr_free_pages_store = nr_free_pages();

    struct mm_struct *mm = mm_create();
ffffffffc0202bc0:	cf3ff0ef          	jal	ra,ffffffffc02028b2 <mm_create>
    assert(mm != NULL);
ffffffffc0202bc4:	84aa                	mv	s1,a0
ffffffffc0202bc6:	03200413          	li	s0,50
ffffffffc0202bca:	e919                	bnez	a0,ffffffffc0202be0 <vmm_init+0x30>
ffffffffc0202bcc:	a991                	j	ffffffffc0203020 <vmm_init+0x470>
                vma->vm_start = vm_start;
ffffffffc0202bce:	e500                	sd	s0,8(a0)
                vma->vm_end = vm_end;
ffffffffc0202bd0:	e91c                	sd	a5,16(a0)
                vma->vm_flags = vm_flags;
ffffffffc0202bd2:	00052c23          	sw	zero,24(a0)

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i --) {
ffffffffc0202bd6:	146d                	addi	s0,s0,-5
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0202bd8:	8526                	mv	a0,s1
ffffffffc0202bda:	d8fff0ef          	jal	ra,ffffffffc0202968 <insert_vma_struct>
    for (i = step1; i >= 1; i --) {
ffffffffc0202bde:	c80d                	beqz	s0,ffffffffc0202c10 <vmm_init+0x60>
        struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202be0:	03000513          	li	a0,48
ffffffffc0202be4:	1fa010ef          	jal	ra,ffffffffc0203dde <kmalloc>
ffffffffc0202be8:	85aa                	mv	a1,a0
ffffffffc0202bea:	00240793          	addi	a5,s0,2
        if (vma != NULL) {
ffffffffc0202bee:	f165                	bnez	a0,ffffffffc0202bce <vmm_init+0x1e>
        assert(vma != NULL);
ffffffffc0202bf0:	00005697          	auipc	a3,0x5
ffffffffc0202bf4:	f0068693          	addi	a3,a3,-256 # ffffffffc0207af0 <commands+0x10d0>
ffffffffc0202bf8:	00004617          	auipc	a2,0x4
ffffffffc0202bfc:	23860613          	addi	a2,a2,568 # ffffffffc0206e30 <commands+0x410>
ffffffffc0202c00:	12200593          	li	a1,290
ffffffffc0202c04:	00005517          	auipc	a0,0x5
ffffffffc0202c08:	c1c50513          	addi	a0,a0,-996 # ffffffffc0207820 <commands+0xe00>
ffffffffc0202c0c:	dfcfd0ef          	jal	ra,ffffffffc0200208 <__panic>
ffffffffc0202c10:	03700413          	li	s0,55
    }

    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc0202c14:	1f900913          	li	s2,505
ffffffffc0202c18:	a819                	j	ffffffffc0202c2e <vmm_init+0x7e>
                vma->vm_start = vm_start;
ffffffffc0202c1a:	e500                	sd	s0,8(a0)
                vma->vm_end = vm_end;
ffffffffc0202c1c:	e91c                	sd	a5,16(a0)
                vma->vm_flags = vm_flags;
ffffffffc0202c1e:	00052c23          	sw	zero,24(a0)
    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc0202c22:	0415                	addi	s0,s0,5
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0202c24:	8526                	mv	a0,s1
ffffffffc0202c26:	d43ff0ef          	jal	ra,ffffffffc0202968 <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc0202c2a:	03240a63          	beq	s0,s2,ffffffffc0202c5e <vmm_init+0xae>
        struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202c2e:	03000513          	li	a0,48
ffffffffc0202c32:	1ac010ef          	jal	ra,ffffffffc0203dde <kmalloc>
ffffffffc0202c36:	85aa                	mv	a1,a0
ffffffffc0202c38:	00240793          	addi	a5,s0,2
        if (vma != NULL) {
ffffffffc0202c3c:	fd79                	bnez	a0,ffffffffc0202c1a <vmm_init+0x6a>
        assert(vma != NULL);
ffffffffc0202c3e:	00005697          	auipc	a3,0x5
ffffffffc0202c42:	eb268693          	addi	a3,a3,-334 # ffffffffc0207af0 <commands+0x10d0>
ffffffffc0202c46:	00004617          	auipc	a2,0x4
ffffffffc0202c4a:	1ea60613          	addi	a2,a2,490 # ffffffffc0206e30 <commands+0x410>
ffffffffc0202c4e:	12800593          	li	a1,296
ffffffffc0202c52:	00005517          	auipc	a0,0x5
ffffffffc0202c56:	bce50513          	addi	a0,a0,-1074 # ffffffffc0207820 <commands+0xe00>
ffffffffc0202c5a:	daefd0ef          	jal	ra,ffffffffc0200208 <__panic>
ffffffffc0202c5e:	649c                	ld	a5,8(s1)
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i ++) {
        assert(le != &(mm->mmap_list));
ffffffffc0202c60:	471d                	li	a4,7
    for (i = 1; i <= step2; i ++) {
ffffffffc0202c62:	1fb00593          	li	a1,507
        assert(le != &(mm->mmap_list));
ffffffffc0202c66:	2cf48d63          	beq	s1,a5,ffffffffc0202f40 <vmm_init+0x390>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0202c6a:	fe87b683          	ld	a3,-24(a5) # ffffffffffffefe8 <end+0x3fd4c704>
ffffffffc0202c6e:	ffe70613          	addi	a2,a4,-2 # fffffffffff7fffe <end+0x3fccd71a>
ffffffffc0202c72:	24d61763          	bne	a2,a3,ffffffffc0202ec0 <vmm_init+0x310>
ffffffffc0202c76:	ff07b683          	ld	a3,-16(a5)
ffffffffc0202c7a:	24e69363          	bne	a3,a4,ffffffffc0202ec0 <vmm_init+0x310>
    for (i = 1; i <= step2; i ++) {
ffffffffc0202c7e:	0715                	addi	a4,a4,5
ffffffffc0202c80:	679c                	ld	a5,8(a5)
ffffffffc0202c82:	feb712e3          	bne	a4,a1,ffffffffc0202c66 <vmm_init+0xb6>
ffffffffc0202c86:	4a1d                	li	s4,7
ffffffffc0202c88:	4415                	li	s0,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i +=5) {
ffffffffc0202c8a:	1f900a93          	li	s5,505
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0202c8e:	85a2                	mv	a1,s0
ffffffffc0202c90:	8526                	mv	a0,s1
ffffffffc0202c92:	c97ff0ef          	jal	ra,ffffffffc0202928 <find_vma>
ffffffffc0202c96:	892a                	mv	s2,a0
        assert(vma1 != NULL);
ffffffffc0202c98:	30050463          	beqz	a0,ffffffffc0202fa0 <vmm_init+0x3f0>
        struct vma_struct *vma2 = find_vma(mm, i+1);
ffffffffc0202c9c:	00140593          	addi	a1,s0,1
ffffffffc0202ca0:	8526                	mv	a0,s1
ffffffffc0202ca2:	c87ff0ef          	jal	ra,ffffffffc0202928 <find_vma>
ffffffffc0202ca6:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0202ca8:	2c050c63          	beqz	a0,ffffffffc0202f80 <vmm_init+0x3d0>
        struct vma_struct *vma3 = find_vma(mm, i+2);
ffffffffc0202cac:	85d2                	mv	a1,s4
ffffffffc0202cae:	8526                	mv	a0,s1
ffffffffc0202cb0:	c79ff0ef          	jal	ra,ffffffffc0202928 <find_vma>
        assert(vma3 == NULL);
ffffffffc0202cb4:	2a051663          	bnez	a0,ffffffffc0202f60 <vmm_init+0x3b0>
        struct vma_struct *vma4 = find_vma(mm, i+3);
ffffffffc0202cb8:	00340593          	addi	a1,s0,3
ffffffffc0202cbc:	8526                	mv	a0,s1
ffffffffc0202cbe:	c6bff0ef          	jal	ra,ffffffffc0202928 <find_vma>
        assert(vma4 == NULL);
ffffffffc0202cc2:	30051f63          	bnez	a0,ffffffffc0202fe0 <vmm_init+0x430>
        struct vma_struct *vma5 = find_vma(mm, i+4);
ffffffffc0202cc6:	00440593          	addi	a1,s0,4
ffffffffc0202cca:	8526                	mv	a0,s1
ffffffffc0202ccc:	c5dff0ef          	jal	ra,ffffffffc0202928 <find_vma>
        assert(vma5 == NULL);
ffffffffc0202cd0:	2e051863          	bnez	a0,ffffffffc0202fc0 <vmm_init+0x410>

        assert(vma1->vm_start == i  && vma1->vm_end == i  + 2);
ffffffffc0202cd4:	00893783          	ld	a5,8(s2)
ffffffffc0202cd8:	20879463          	bne	a5,s0,ffffffffc0202ee0 <vmm_init+0x330>
ffffffffc0202cdc:	01093783          	ld	a5,16(s2)
ffffffffc0202ce0:	20fa1063          	bne	s4,a5,ffffffffc0202ee0 <vmm_init+0x330>
        assert(vma2->vm_start == i  && vma2->vm_end == i  + 2);
ffffffffc0202ce4:	0089b783          	ld	a5,8(s3)
ffffffffc0202ce8:	20879c63          	bne	a5,s0,ffffffffc0202f00 <vmm_init+0x350>
ffffffffc0202cec:	0109b783          	ld	a5,16(s3)
ffffffffc0202cf0:	20fa1863          	bne	s4,a5,ffffffffc0202f00 <vmm_init+0x350>
    for (i = 5; i <= 5 * step2; i +=5) {
ffffffffc0202cf4:	0415                	addi	s0,s0,5
ffffffffc0202cf6:	0a15                	addi	s4,s4,5
ffffffffc0202cf8:	f9541be3          	bne	s0,s5,ffffffffc0202c8e <vmm_init+0xde>
ffffffffc0202cfc:	4411                	li	s0,4
    }

    for (i =4; i>=0; i--) {
ffffffffc0202cfe:	597d                	li	s2,-1
        struct vma_struct *vma_below_5= find_vma(mm,i);
ffffffffc0202d00:	85a2                	mv	a1,s0
ffffffffc0202d02:	8526                	mv	a0,s1
ffffffffc0202d04:	c25ff0ef          	jal	ra,ffffffffc0202928 <find_vma>
ffffffffc0202d08:	0004059b          	sext.w	a1,s0
        if (vma_below_5 != NULL ) {
ffffffffc0202d0c:	c90d                	beqz	a0,ffffffffc0202d3e <vmm_init+0x18e>
           cprintf("vma_below_5: i %x, start %x, end %x\n",i, vma_below_5->vm_start, vma_below_5->vm_end); 
ffffffffc0202d0e:	6914                	ld	a3,16(a0)
ffffffffc0202d10:	6510                	ld	a2,8(a0)
ffffffffc0202d12:	00005517          	auipc	a0,0x5
ffffffffc0202d16:	cc650513          	addi	a0,a0,-826 # ffffffffc02079d8 <commands+0xfb8>
ffffffffc0202d1a:	bb2fd0ef          	jal	ra,ffffffffc02000cc <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc0202d1e:	00005697          	auipc	a3,0x5
ffffffffc0202d22:	ce268693          	addi	a3,a3,-798 # ffffffffc0207a00 <commands+0xfe0>
ffffffffc0202d26:	00004617          	auipc	a2,0x4
ffffffffc0202d2a:	10a60613          	addi	a2,a2,266 # ffffffffc0206e30 <commands+0x410>
ffffffffc0202d2e:	14a00593          	li	a1,330
ffffffffc0202d32:	00005517          	auipc	a0,0x5
ffffffffc0202d36:	aee50513          	addi	a0,a0,-1298 # ffffffffc0207820 <commands+0xe00>
ffffffffc0202d3a:	ccefd0ef          	jal	ra,ffffffffc0200208 <__panic>
    for (i =4; i>=0; i--) {
ffffffffc0202d3e:	147d                	addi	s0,s0,-1
ffffffffc0202d40:	fd2410e3          	bne	s0,s2,ffffffffc0202d00 <vmm_init+0x150>
    }

    mm_destroy(mm);
ffffffffc0202d44:	8526                	mv	a0,s1
ffffffffc0202d46:	cf3ff0ef          	jal	ra,ffffffffc0202a38 <mm_destroy>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0202d4a:	00005517          	auipc	a0,0x5
ffffffffc0202d4e:	cce50513          	addi	a0,a0,-818 # ffffffffc0207a18 <commands+0xff8>
ffffffffc0202d52:	b7afd0ef          	jal	ra,ffffffffc02000cc <cprintf>
struct mm_struct *check_mm_struct;

// check_pgfault - check correctness of pgfault handler
static void
check_pgfault(void) {
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc0202d56:	f14fe0ef          	jal	ra,ffffffffc020146a <nr_free_pages>
ffffffffc0202d5a:	892a                	mv	s2,a0

    check_mm_struct = mm_create();
ffffffffc0202d5c:	b57ff0ef          	jal	ra,ffffffffc02028b2 <mm_create>
ffffffffc0202d60:	000b0797          	auipc	a5,0xb0
ffffffffc0202d64:	b2a7bc23          	sd	a0,-1224(a5) # ffffffffc02b2898 <check_mm_struct>
ffffffffc0202d68:	842a                	mv	s0,a0
    assert(check_mm_struct != NULL);
ffffffffc0202d6a:	28050b63          	beqz	a0,ffffffffc0203000 <vmm_init+0x450>

    struct mm_struct *mm = check_mm_struct;
    pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0202d6e:	000b0497          	auipc	s1,0xb0
ffffffffc0202d72:	b024b483          	ld	s1,-1278(s1) # ffffffffc02b2870 <boot_pgdir>
    assert(pgdir[0] == 0);
ffffffffc0202d76:	609c                	ld	a5,0(s1)
    pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0202d78:	ed04                	sd	s1,24(a0)
    assert(pgdir[0] == 0);
ffffffffc0202d7a:	2e079f63          	bnez	a5,ffffffffc0203078 <vmm_init+0x4c8>
        struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202d7e:	03000513          	li	a0,48
ffffffffc0202d82:	05c010ef          	jal	ra,ffffffffc0203dde <kmalloc>
ffffffffc0202d86:	89aa                	mv	s3,a0
        if (vma != NULL) {
ffffffffc0202d88:	18050c63          	beqz	a0,ffffffffc0202f20 <vmm_init+0x370>
                vma->vm_end = vm_end;
ffffffffc0202d8c:	002007b7          	lui	a5,0x200
ffffffffc0202d90:	00f9b823          	sd	a5,16(s3)
                vma->vm_flags = vm_flags;
ffffffffc0202d94:	4789                	li	a5,2

    struct vma_struct *vma = vma_create(0, PTSIZE, VM_WRITE);
    assert(vma != NULL);

    insert_vma_struct(mm, vma);
ffffffffc0202d96:	85aa                	mv	a1,a0
                vma->vm_flags = vm_flags;
ffffffffc0202d98:	00f9ac23          	sw	a5,24(s3)
    insert_vma_struct(mm, vma);
ffffffffc0202d9c:	8522                	mv	a0,s0
                vma->vm_start = vm_start;
ffffffffc0202d9e:	0009b423          	sd	zero,8(s3)
    insert_vma_struct(mm, vma);
ffffffffc0202da2:	bc7ff0ef          	jal	ra,ffffffffc0202968 <insert_vma_struct>

    uintptr_t addr = 0x100;
    assert(find_vma(mm, addr) == vma);
ffffffffc0202da6:	10000593          	li	a1,256
ffffffffc0202daa:	8522                	mv	a0,s0
ffffffffc0202dac:	b7dff0ef          	jal	ra,ffffffffc0202928 <find_vma>
ffffffffc0202db0:	10000793          	li	a5,256

    int i, sum = 0;

    for (i = 0; i < 100; i ++) {
ffffffffc0202db4:	16400713          	li	a4,356
    assert(find_vma(mm, addr) == vma);
ffffffffc0202db8:	2ea99063          	bne	s3,a0,ffffffffc0203098 <vmm_init+0x4e8>
        *(char *)(addr + i) = i;
ffffffffc0202dbc:	00f78023          	sb	a5,0(a5) # 200000 <_binary_obj___user_exit_out_size+0x1f4ec8>
    for (i = 0; i < 100; i ++) {
ffffffffc0202dc0:	0785                	addi	a5,a5,1
ffffffffc0202dc2:	fee79de3          	bne	a5,a4,ffffffffc0202dbc <vmm_init+0x20c>
        sum += i;
ffffffffc0202dc6:	6705                	lui	a4,0x1
ffffffffc0202dc8:	10000793          	li	a5,256
ffffffffc0202dcc:	35670713          	addi	a4,a4,854 # 1356 <_binary_obj___user_faultread_out_size-0x8862>
    }
    for (i = 0; i < 100; i ++) {
ffffffffc0202dd0:	16400613          	li	a2,356
        sum -= *(char *)(addr + i);
ffffffffc0202dd4:	0007c683          	lbu	a3,0(a5)
    for (i = 0; i < 100; i ++) {
ffffffffc0202dd8:	0785                	addi	a5,a5,1
        sum -= *(char *)(addr + i);
ffffffffc0202dda:	9f15                	subw	a4,a4,a3
    for (i = 0; i < 100; i ++) {
ffffffffc0202ddc:	fec79ce3          	bne	a5,a2,ffffffffc0202dd4 <vmm_init+0x224>
    }

    assert(sum == 0);
ffffffffc0202de0:	2e071863          	bnez	a4,ffffffffc02030d0 <vmm_init+0x520>
    return pa2page(PDE_ADDR(pde));
ffffffffc0202de4:	609c                	ld	a5,0(s1)
    if (PPN(pa) >= npage) {
ffffffffc0202de6:	000b0a97          	auipc	s5,0xb0
ffffffffc0202dea:	a92a8a93          	addi	s5,s5,-1390 # ffffffffc02b2878 <npage>
ffffffffc0202dee:	000ab603          	ld	a2,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202df2:	078a                	slli	a5,a5,0x2
ffffffffc0202df4:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202df6:	2cc7f163          	bgeu	a5,a2,ffffffffc02030b8 <vmm_init+0x508>
    return &pages[PPN(pa) - nbase];
ffffffffc0202dfa:	00006a17          	auipc	s4,0x6
ffffffffc0202dfe:	076a3a03          	ld	s4,118(s4) # ffffffffc0208e70 <nbase>
ffffffffc0202e02:	414787b3          	sub	a5,a5,s4
ffffffffc0202e06:	079a                	slli	a5,a5,0x6
    return page - pages + nbase;
ffffffffc0202e08:	8799                	srai	a5,a5,0x6
ffffffffc0202e0a:	97d2                	add	a5,a5,s4
    return KADDR(page2pa(page));
ffffffffc0202e0c:	00c79713          	slli	a4,a5,0xc
ffffffffc0202e10:	8331                	srli	a4,a4,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202e12:	00c79693          	slli	a3,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0202e16:	24c77563          	bgeu	a4,a2,ffffffffc0203060 <vmm_init+0x4b0>
ffffffffc0202e1a:	000b0997          	auipc	s3,0xb0
ffffffffc0202e1e:	a769b983          	ld	s3,-1418(s3) # ffffffffc02b2890 <va_pa_offset>

    pde_t *pd1=pgdir,*pd0=page2kva(pde2page(pgdir[0]));
    page_remove(pgdir, ROUNDDOWN(addr, PGSIZE));
ffffffffc0202e22:	4581                	li	a1,0
ffffffffc0202e24:	8526                	mv	a0,s1
ffffffffc0202e26:	99b6                	add	s3,s3,a3
ffffffffc0202e28:	c7bfe0ef          	jal	ra,ffffffffc0201aa2 <page_remove>
    return pa2page(PDE_ADDR(pde));
ffffffffc0202e2c:	0009b783          	ld	a5,0(s3)
    if (PPN(pa) >= npage) {
ffffffffc0202e30:	000ab703          	ld	a4,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202e34:	078a                	slli	a5,a5,0x2
ffffffffc0202e36:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202e38:	28e7f063          	bgeu	a5,a4,ffffffffc02030b8 <vmm_init+0x508>
    return &pages[PPN(pa) - nbase];
ffffffffc0202e3c:	000b0997          	auipc	s3,0xb0
ffffffffc0202e40:	a4498993          	addi	s3,s3,-1468 # ffffffffc02b2880 <pages>
ffffffffc0202e44:	0009b503          	ld	a0,0(s3)
ffffffffc0202e48:	414787b3          	sub	a5,a5,s4
ffffffffc0202e4c:	079a                	slli	a5,a5,0x6
    free_page(pde2page(pd0[0]));
ffffffffc0202e4e:	953e                	add	a0,a0,a5
ffffffffc0202e50:	4585                	li	a1,1
ffffffffc0202e52:	dd8fe0ef          	jal	ra,ffffffffc020142a <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc0202e56:	609c                	ld	a5,0(s1)
    if (PPN(pa) >= npage) {
ffffffffc0202e58:	000ab703          	ld	a4,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202e5c:	078a                	slli	a5,a5,0x2
ffffffffc0202e5e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202e60:	24e7fc63          	bgeu	a5,a4,ffffffffc02030b8 <vmm_init+0x508>
    return &pages[PPN(pa) - nbase];
ffffffffc0202e64:	0009b503          	ld	a0,0(s3)
ffffffffc0202e68:	414787b3          	sub	a5,a5,s4
ffffffffc0202e6c:	079a                	slli	a5,a5,0x6
    free_page(pde2page(pd1[0]));
ffffffffc0202e6e:	4585                	li	a1,1
ffffffffc0202e70:	953e                	add	a0,a0,a5
ffffffffc0202e72:	db8fe0ef          	jal	ra,ffffffffc020142a <free_pages>
    pgdir[0] = 0;
ffffffffc0202e76:	0004b023          	sd	zero,0(s1)
  asm volatile("sfence.vma");
ffffffffc0202e7a:	12000073          	sfence.vma
    flush_tlb();

    mm->pgdir = NULL;
    mm_destroy(mm);
ffffffffc0202e7e:	8522                	mv	a0,s0
    mm->pgdir = NULL;
ffffffffc0202e80:	00043c23          	sd	zero,24(s0)
    mm_destroy(mm);
ffffffffc0202e84:	bb5ff0ef          	jal	ra,ffffffffc0202a38 <mm_destroy>
    check_mm_struct = NULL;
ffffffffc0202e88:	000b0797          	auipc	a5,0xb0
ffffffffc0202e8c:	a007b823          	sd	zero,-1520(a5) # ffffffffc02b2898 <check_mm_struct>

    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0202e90:	ddafe0ef          	jal	ra,ffffffffc020146a <nr_free_pages>
ffffffffc0202e94:	1aa91663          	bne	s2,a0,ffffffffc0203040 <vmm_init+0x490>

    cprintf("check_pgfault() succeeded!\n");
ffffffffc0202e98:	00005517          	auipc	a0,0x5
ffffffffc0202e9c:	c2050513          	addi	a0,a0,-992 # ffffffffc0207ab8 <commands+0x1098>
ffffffffc0202ea0:	a2cfd0ef          	jal	ra,ffffffffc02000cc <cprintf>
}
ffffffffc0202ea4:	7442                	ld	s0,48(sp)
ffffffffc0202ea6:	70e2                	ld	ra,56(sp)
ffffffffc0202ea8:	74a2                	ld	s1,40(sp)
ffffffffc0202eaa:	7902                	ld	s2,32(sp)
ffffffffc0202eac:	69e2                	ld	s3,24(sp)
ffffffffc0202eae:	6a42                	ld	s4,16(sp)
ffffffffc0202eb0:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n"); // 打印检查成功的信息
ffffffffc0202eb2:	00005517          	auipc	a0,0x5
ffffffffc0202eb6:	c2650513          	addi	a0,a0,-986 # ffffffffc0207ad8 <commands+0x10b8>
}
ffffffffc0202eba:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n"); // 打印检查成功的信息
ffffffffc0202ebc:	a10fd06f          	j	ffffffffc02000cc <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0202ec0:	00005697          	auipc	a3,0x5
ffffffffc0202ec4:	a3068693          	addi	a3,a3,-1488 # ffffffffc02078f0 <commands+0xed0>
ffffffffc0202ec8:	00004617          	auipc	a2,0x4
ffffffffc0202ecc:	f6860613          	addi	a2,a2,-152 # ffffffffc0206e30 <commands+0x410>
ffffffffc0202ed0:	13100593          	li	a1,305
ffffffffc0202ed4:	00005517          	auipc	a0,0x5
ffffffffc0202ed8:	94c50513          	addi	a0,a0,-1716 # ffffffffc0207820 <commands+0xe00>
ffffffffc0202edc:	b2cfd0ef          	jal	ra,ffffffffc0200208 <__panic>
        assert(vma1->vm_start == i  && vma1->vm_end == i  + 2);
ffffffffc0202ee0:	00005697          	auipc	a3,0x5
ffffffffc0202ee4:	a9868693          	addi	a3,a3,-1384 # ffffffffc0207978 <commands+0xf58>
ffffffffc0202ee8:	00004617          	auipc	a2,0x4
ffffffffc0202eec:	f4860613          	addi	a2,a2,-184 # ffffffffc0206e30 <commands+0x410>
ffffffffc0202ef0:	14100593          	li	a1,321
ffffffffc0202ef4:	00005517          	auipc	a0,0x5
ffffffffc0202ef8:	92c50513          	addi	a0,a0,-1748 # ffffffffc0207820 <commands+0xe00>
ffffffffc0202efc:	b0cfd0ef          	jal	ra,ffffffffc0200208 <__panic>
        assert(vma2->vm_start == i  && vma2->vm_end == i  + 2);
ffffffffc0202f00:	00005697          	auipc	a3,0x5
ffffffffc0202f04:	aa868693          	addi	a3,a3,-1368 # ffffffffc02079a8 <commands+0xf88>
ffffffffc0202f08:	00004617          	auipc	a2,0x4
ffffffffc0202f0c:	f2860613          	addi	a2,a2,-216 # ffffffffc0206e30 <commands+0x410>
ffffffffc0202f10:	14200593          	li	a1,322
ffffffffc0202f14:	00005517          	auipc	a0,0x5
ffffffffc0202f18:	90c50513          	addi	a0,a0,-1780 # ffffffffc0207820 <commands+0xe00>
ffffffffc0202f1c:	aecfd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(vma != NULL);
ffffffffc0202f20:	00005697          	auipc	a3,0x5
ffffffffc0202f24:	bd068693          	addi	a3,a3,-1072 # ffffffffc0207af0 <commands+0x10d0>
ffffffffc0202f28:	00004617          	auipc	a2,0x4
ffffffffc0202f2c:	f0860613          	addi	a2,a2,-248 # ffffffffc0206e30 <commands+0x410>
ffffffffc0202f30:	16100593          	li	a1,353
ffffffffc0202f34:	00005517          	auipc	a0,0x5
ffffffffc0202f38:	8ec50513          	addi	a0,a0,-1812 # ffffffffc0207820 <commands+0xe00>
ffffffffc0202f3c:	accfd0ef          	jal	ra,ffffffffc0200208 <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0202f40:	00005697          	auipc	a3,0x5
ffffffffc0202f44:	99868693          	addi	a3,a3,-1640 # ffffffffc02078d8 <commands+0xeb8>
ffffffffc0202f48:	00004617          	auipc	a2,0x4
ffffffffc0202f4c:	ee860613          	addi	a2,a2,-280 # ffffffffc0206e30 <commands+0x410>
ffffffffc0202f50:	12f00593          	li	a1,303
ffffffffc0202f54:	00005517          	auipc	a0,0x5
ffffffffc0202f58:	8cc50513          	addi	a0,a0,-1844 # ffffffffc0207820 <commands+0xe00>
ffffffffc0202f5c:	aacfd0ef          	jal	ra,ffffffffc0200208 <__panic>
        assert(vma3 == NULL);
ffffffffc0202f60:	00005697          	auipc	a3,0x5
ffffffffc0202f64:	9e868693          	addi	a3,a3,-1560 # ffffffffc0207948 <commands+0xf28>
ffffffffc0202f68:	00004617          	auipc	a2,0x4
ffffffffc0202f6c:	ec860613          	addi	a2,a2,-312 # ffffffffc0206e30 <commands+0x410>
ffffffffc0202f70:	13b00593          	li	a1,315
ffffffffc0202f74:	00005517          	auipc	a0,0x5
ffffffffc0202f78:	8ac50513          	addi	a0,a0,-1876 # ffffffffc0207820 <commands+0xe00>
ffffffffc0202f7c:	a8cfd0ef          	jal	ra,ffffffffc0200208 <__panic>
        assert(vma2 != NULL);
ffffffffc0202f80:	00005697          	auipc	a3,0x5
ffffffffc0202f84:	9b868693          	addi	a3,a3,-1608 # ffffffffc0207938 <commands+0xf18>
ffffffffc0202f88:	00004617          	auipc	a2,0x4
ffffffffc0202f8c:	ea860613          	addi	a2,a2,-344 # ffffffffc0206e30 <commands+0x410>
ffffffffc0202f90:	13900593          	li	a1,313
ffffffffc0202f94:	00005517          	auipc	a0,0x5
ffffffffc0202f98:	88c50513          	addi	a0,a0,-1908 # ffffffffc0207820 <commands+0xe00>
ffffffffc0202f9c:	a6cfd0ef          	jal	ra,ffffffffc0200208 <__panic>
        assert(vma1 != NULL);
ffffffffc0202fa0:	00005697          	auipc	a3,0x5
ffffffffc0202fa4:	98868693          	addi	a3,a3,-1656 # ffffffffc0207928 <commands+0xf08>
ffffffffc0202fa8:	00004617          	auipc	a2,0x4
ffffffffc0202fac:	e8860613          	addi	a2,a2,-376 # ffffffffc0206e30 <commands+0x410>
ffffffffc0202fb0:	13700593          	li	a1,311
ffffffffc0202fb4:	00005517          	auipc	a0,0x5
ffffffffc0202fb8:	86c50513          	addi	a0,a0,-1940 # ffffffffc0207820 <commands+0xe00>
ffffffffc0202fbc:	a4cfd0ef          	jal	ra,ffffffffc0200208 <__panic>
        assert(vma5 == NULL);
ffffffffc0202fc0:	00005697          	auipc	a3,0x5
ffffffffc0202fc4:	9a868693          	addi	a3,a3,-1624 # ffffffffc0207968 <commands+0xf48>
ffffffffc0202fc8:	00004617          	auipc	a2,0x4
ffffffffc0202fcc:	e6860613          	addi	a2,a2,-408 # ffffffffc0206e30 <commands+0x410>
ffffffffc0202fd0:	13f00593          	li	a1,319
ffffffffc0202fd4:	00005517          	auipc	a0,0x5
ffffffffc0202fd8:	84c50513          	addi	a0,a0,-1972 # ffffffffc0207820 <commands+0xe00>
ffffffffc0202fdc:	a2cfd0ef          	jal	ra,ffffffffc0200208 <__panic>
        assert(vma4 == NULL);
ffffffffc0202fe0:	00005697          	auipc	a3,0x5
ffffffffc0202fe4:	97868693          	addi	a3,a3,-1672 # ffffffffc0207958 <commands+0xf38>
ffffffffc0202fe8:	00004617          	auipc	a2,0x4
ffffffffc0202fec:	e4860613          	addi	a2,a2,-440 # ffffffffc0206e30 <commands+0x410>
ffffffffc0202ff0:	13d00593          	li	a1,317
ffffffffc0202ff4:	00005517          	auipc	a0,0x5
ffffffffc0202ff8:	82c50513          	addi	a0,a0,-2004 # ffffffffc0207820 <commands+0xe00>
ffffffffc0202ffc:	a0cfd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(check_mm_struct != NULL);
ffffffffc0203000:	00005697          	auipc	a3,0x5
ffffffffc0203004:	a3868693          	addi	a3,a3,-1480 # ffffffffc0207a38 <commands+0x1018>
ffffffffc0203008:	00004617          	auipc	a2,0x4
ffffffffc020300c:	e2860613          	addi	a2,a2,-472 # ffffffffc0206e30 <commands+0x410>
ffffffffc0203010:	15a00593          	li	a1,346
ffffffffc0203014:	00005517          	auipc	a0,0x5
ffffffffc0203018:	80c50513          	addi	a0,a0,-2036 # ffffffffc0207820 <commands+0xe00>
ffffffffc020301c:	9ecfd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(mm != NULL);
ffffffffc0203020:	00005697          	auipc	a3,0x5
ffffffffc0203024:	88868693          	addi	a3,a3,-1912 # ffffffffc02078a8 <commands+0xe88>
ffffffffc0203028:	00004617          	auipc	a2,0x4
ffffffffc020302c:	e0860613          	addi	a2,a2,-504 # ffffffffc0206e30 <commands+0x410>
ffffffffc0203030:	11b00593          	li	a1,283
ffffffffc0203034:	00004517          	auipc	a0,0x4
ffffffffc0203038:	7ec50513          	addi	a0,a0,2028 # ffffffffc0207820 <commands+0xe00>
ffffffffc020303c:	9ccfd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0203040:	00005697          	auipc	a3,0x5
ffffffffc0203044:	a5068693          	addi	a3,a3,-1456 # ffffffffc0207a90 <commands+0x1070>
ffffffffc0203048:	00004617          	auipc	a2,0x4
ffffffffc020304c:	de860613          	addi	a2,a2,-536 # ffffffffc0206e30 <commands+0x410>
ffffffffc0203050:	17f00593          	li	a1,383
ffffffffc0203054:	00004517          	auipc	a0,0x4
ffffffffc0203058:	7cc50513          	addi	a0,a0,1996 # ffffffffc0207820 <commands+0xe00>
ffffffffc020305c:	9acfd0ef          	jal	ra,ffffffffc0200208 <__panic>
    return KADDR(page2pa(page));
ffffffffc0203060:	00004617          	auipc	a2,0x4
ffffffffc0203064:	18860613          	addi	a2,a2,392 # ffffffffc02071e8 <commands+0x7c8>
ffffffffc0203068:	06900593          	li	a1,105
ffffffffc020306c:	00004517          	auipc	a0,0x4
ffffffffc0203070:	12c50513          	addi	a0,a0,300 # ffffffffc0207198 <commands+0x778>
ffffffffc0203074:	994fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(pgdir[0] == 0);
ffffffffc0203078:	00005697          	auipc	a3,0x5
ffffffffc020307c:	9d868693          	addi	a3,a3,-1576 # ffffffffc0207a50 <commands+0x1030>
ffffffffc0203080:	00004617          	auipc	a2,0x4
ffffffffc0203084:	db060613          	addi	a2,a2,-592 # ffffffffc0206e30 <commands+0x410>
ffffffffc0203088:	15e00593          	li	a1,350
ffffffffc020308c:	00004517          	auipc	a0,0x4
ffffffffc0203090:	79450513          	addi	a0,a0,1940 # ffffffffc0207820 <commands+0xe00>
ffffffffc0203094:	974fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(find_vma(mm, addr) == vma);
ffffffffc0203098:	00005697          	auipc	a3,0x5
ffffffffc020309c:	9c868693          	addi	a3,a3,-1592 # ffffffffc0207a60 <commands+0x1040>
ffffffffc02030a0:	00004617          	auipc	a2,0x4
ffffffffc02030a4:	d9060613          	addi	a2,a2,-624 # ffffffffc0206e30 <commands+0x410>
ffffffffc02030a8:	16600593          	li	a1,358
ffffffffc02030ac:	00004517          	auipc	a0,0x4
ffffffffc02030b0:	77450513          	addi	a0,a0,1908 # ffffffffc0207820 <commands+0xe00>
ffffffffc02030b4:	954fd0ef          	jal	ra,ffffffffc0200208 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02030b8:	00004617          	auipc	a2,0x4
ffffffffc02030bc:	0c060613          	addi	a2,a2,192 # ffffffffc0207178 <commands+0x758>
ffffffffc02030c0:	06200593          	li	a1,98
ffffffffc02030c4:	00004517          	auipc	a0,0x4
ffffffffc02030c8:	0d450513          	addi	a0,a0,212 # ffffffffc0207198 <commands+0x778>
ffffffffc02030cc:	93cfd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(sum == 0);
ffffffffc02030d0:	00005697          	auipc	a3,0x5
ffffffffc02030d4:	9b068693          	addi	a3,a3,-1616 # ffffffffc0207a80 <commands+0x1060>
ffffffffc02030d8:	00004617          	auipc	a2,0x4
ffffffffc02030dc:	d5860613          	addi	a2,a2,-680 # ffffffffc0206e30 <commands+0x410>
ffffffffc02030e0:	17200593          	li	a1,370
ffffffffc02030e4:	00004517          	auipc	a0,0x4
ffffffffc02030e8:	73c50513          	addi	a0,a0,1852 # ffffffffc0207820 <commands+0xe00>
ffffffffc02030ec:	91cfd0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc02030f0 <do_pgfault>:
 *            was a read (0) or write (1).
 *         -- The U/S flag (bit 2) indicates whether the processor was executing at user mode (1)
 *            or supervisor mode (0) at the time of the exception.
 */
int
do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) {
ffffffffc02030f0:	7139                	addi	sp,sp,-64
ffffffffc02030f2:	f04a                	sd	s2,32(sp)
ffffffffc02030f4:	892e                	mv	s2,a1
    int ret = -E_INVAL; // 初始化返回值为无效错误
    //try to find a vma which include addr
    struct vma_struct *vma = find_vma(mm, addr); // 查找包含addr的vma
ffffffffc02030f6:	85b2                	mv	a1,a2
do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) {
ffffffffc02030f8:	f822                	sd	s0,48(sp)
ffffffffc02030fa:	f426                	sd	s1,40(sp)
ffffffffc02030fc:	fc06                	sd	ra,56(sp)
ffffffffc02030fe:	ec4e                	sd	s3,24(sp)
ffffffffc0203100:	8432                	mv	s0,a2
ffffffffc0203102:	84aa                	mv	s1,a0
    struct vma_struct *vma = find_vma(mm, addr); // 查找包含addr的vma
ffffffffc0203104:	825ff0ef          	jal	ra,ffffffffc0202928 <find_vma>

    pgfault_num++; // 页错误计数器加1
ffffffffc0203108:	000af797          	auipc	a5,0xaf
ffffffffc020310c:	7987a783          	lw	a5,1944(a5) # ffffffffc02b28a0 <pgfault_num>
ffffffffc0203110:	2785                	addiw	a5,a5,1
ffffffffc0203112:	000af717          	auipc	a4,0xaf
ffffffffc0203116:	78f72723          	sw	a5,1934(a4) # ffffffffc02b28a0 <pgfault_num>
    //If the addr is in the range of a mm's vma?
    if (vma == NULL || vma->vm_start > addr) { // 如果找不到vma或者addr不在vma范围内
ffffffffc020311a:	c171                	beqz	a0,ffffffffc02031de <do_pgfault+0xee>
ffffffffc020311c:	651c                	ld	a5,8(a0)
ffffffffc020311e:	0cf46063          	bltu	s0,a5,ffffffffc02031de <do_pgfault+0xee>
     *    (read  an non_existed addr && addr is readable)
     * THEN
     *    continue process
     */
    uint32_t perm = PTE_U; // 初始化页表项权限为用户态
    if (vma->vm_flags & VM_WRITE) { // 如果vma可写
ffffffffc0203122:	4d1c                	lw	a5,24(a0)
    uint32_t perm = PTE_U; // 初始化页表项权限为用户态
ffffffffc0203124:	49c1                	li	s3,16
    if (vma->vm_flags & VM_WRITE) { // 如果vma可写
ffffffffc0203126:	8b89                	andi	a5,a5,2
ffffffffc0203128:	eba9                	bnez	a5,ffffffffc020317a <do_pgfault+0x8a>
        perm |= READ_WRITE; // 增加写权限
    }
    addr = ROUNDDOWN(addr, PGSIZE); // 将addr向下取整到页边界
ffffffffc020312a:	767d                	lui	a2,0xfffff
    ret = -E_NO_MEM; // 初始化返回值为内存不足错误

    pte_t *ptep=NULL; // 页表项指针初始化为空
    
    // 判断页表项权限，如果有效但是不可写，跳转到COW
    if ((ptep = get_pte(mm->pgdir, addr, 0)) != NULL) {
ffffffffc020312c:	6c88                	ld	a0,24(s1)
    addr = ROUNDDOWN(addr, PGSIZE); // 将addr向下取整到页边界
ffffffffc020312e:	8c71                	and	s0,s0,a2
    if ((ptep = get_pte(mm->pgdir, addr, 0)) != NULL) {
ffffffffc0203130:	85a2                	mv	a1,s0
ffffffffc0203132:	4601                	li	a2,0
ffffffffc0203134:	b70fe0ef          	jal	ra,ffffffffc02014a4 <get_pte>
ffffffffc0203138:	c501                	beqz	a0,ffffffffc0203140 <do_pgfault+0x50>
        if((*ptep & PTE_V) & ~(*ptep & PTE_W)) {
ffffffffc020313a:	611c                	ld	a5,0(a0)
ffffffffc020313c:	8b85                	andi	a5,a5,1
ffffffffc020313e:	e7c9                	bnez	a5,ffffffffc02031c8 <do_pgfault+0xd8>
    }


    // try to find a pte, if pte's PT(Page Table) isn't existed, then create a PT.
    // (notice the 3th parameter '1')
    if ((ptep = get_pte(mm->pgdir, addr, 1)) == NULL) { // 尝试获取页表项，如果页表不存在则创建
ffffffffc0203140:	6c88                	ld	a0,24(s1)
ffffffffc0203142:	4605                	li	a2,1
ffffffffc0203144:	85a2                	mv	a1,s0
ffffffffc0203146:	b5efe0ef          	jal	ra,ffffffffc02014a4 <get_pte>
ffffffffc020314a:	c95d                	beqz	a0,ffffffffc0203200 <do_pgfault+0x110>
        cprintf("get_pte in do_pgfault failed\n"); // 打印错误信息
        goto failed; // 跳转到失败处理
    }
    
    if (*ptep == 0) { // if the phy addr isn't exist, then alloc a page & map the phy addr with logical addr
ffffffffc020314c:	610c                	ld	a1,0(a0)
ffffffffc020314e:	cdb1                	beqz	a1,ffffffffc02031aa <do_pgfault+0xba>
        *    swap_in(mm, addr, &page) : 分配一个内存页，然后根据
        *    PTE中的swap条目的addr，找到磁盘页的地址，将磁盘页的内容读入这个内存页
        *    page_insert ： 建立一个Page的phy addr与线性addr la的映射
        *    swap_map_swappable ： 设置页面可交换
        */
        if (swap_init_ok) { // 如果交换初始化成功
ffffffffc0203150:	000af797          	auipc	a5,0xaf
ffffffffc0203154:	7687a783          	lw	a5,1896(a5) # ffffffffc02b28b8 <swap_init_ok>
ffffffffc0203158:	cfc1                	beqz	a5,ffffffffc02031f0 <do_pgfault+0x100>
            //addr AND page, setup the
            //map of phy addr <--->
            //logical addr
            //(3) make the page swappable.
            // cprintf("do_pgfault called!!!\n");
            if((ret = swap_in(mm,addr,&page)) != 0) { // 根据mm和addr，从磁盘加载正确的页面内容到内存
ffffffffc020315a:	0030                	addi	a2,sp,8
ffffffffc020315c:	85a2                	mv	a1,s0
ffffffffc020315e:	8526                	mv	a0,s1
            struct Page *page = NULL; // 初始化页面指针为空
ffffffffc0203160:	e402                	sd	zero,8(sp)
            if((ret = swap_in(mm,addr,&page)) != 0) { // 根据mm和addr，从磁盘加载正确的页面内容到内存
ffffffffc0203162:	1d1000ef          	jal	ra,ffffffffc0203b32 <swap_in>
ffffffffc0203166:	892a                	mv	s2,a0
ffffffffc0203168:	c919                	beqz	a0,ffffffffc020317e <do_pgfault+0x8e>
        }
   }
   ret = 0; // 设置返回值为0，表示成功
failed:
    return ret; // 返回结果
}
ffffffffc020316a:	70e2                	ld	ra,56(sp)
ffffffffc020316c:	7442                	ld	s0,48(sp)
ffffffffc020316e:	74a2                	ld	s1,40(sp)
ffffffffc0203170:	69e2                	ld	s3,24(sp)
ffffffffc0203172:	854a                	mv	a0,s2
ffffffffc0203174:	7902                	ld	s2,32(sp)
ffffffffc0203176:	6121                	addi	sp,sp,64
ffffffffc0203178:	8082                	ret
        perm |= READ_WRITE; // 增加写权限
ffffffffc020317a:	49dd                	li	s3,23
ffffffffc020317c:	b77d                	j	ffffffffc020312a <do_pgfault+0x3a>
            page_insert(mm->pgdir,page,addr,perm); // 建立物理地址和逻辑地址的映射
ffffffffc020317e:	65a2                	ld	a1,8(sp)
ffffffffc0203180:	6c88                	ld	a0,24(s1)
ffffffffc0203182:	86ce                	mv	a3,s3
ffffffffc0203184:	8622                	mv	a2,s0
ffffffffc0203186:	9b9fe0ef          	jal	ra,ffffffffc0201b3e <page_insert>
            swap_map_swappable(mm,addr,page,1); // 设置页面可交换
ffffffffc020318a:	6622                	ld	a2,8(sp)
ffffffffc020318c:	85a2                	mv	a1,s0
ffffffffc020318e:	8526                	mv	a0,s1
ffffffffc0203190:	4685                	li	a3,1
ffffffffc0203192:	081000ef          	jal	ra,ffffffffc0203a12 <swap_map_swappable>
            page->pra_vaddr = addr; // 设置页面的虚拟地址
ffffffffc0203196:	67a2                	ld	a5,8(sp)
}
ffffffffc0203198:	70e2                	ld	ra,56(sp)
ffffffffc020319a:	74a2                	ld	s1,40(sp)
            page->pra_vaddr = addr; // 设置页面的虚拟地址
ffffffffc020319c:	ff80                	sd	s0,56(a5)
}
ffffffffc020319e:	7442                	ld	s0,48(sp)
ffffffffc02031a0:	69e2                	ld	s3,24(sp)
ffffffffc02031a2:	854a                	mv	a0,s2
ffffffffc02031a4:	7902                	ld	s2,32(sp)
ffffffffc02031a6:	6121                	addi	sp,sp,64
ffffffffc02031a8:	8082                	ret
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) { // 如果物理地址不存在，则分配一个页面并映射物理地址和逻辑地址
ffffffffc02031aa:	6c88                	ld	a0,24(s1)
ffffffffc02031ac:	864e                	mv	a2,s3
ffffffffc02031ae:	85a2                	mv	a1,s0
ffffffffc02031b0:	e24ff0ef          	jal	ra,ffffffffc02027d4 <pgdir_alloc_page>
   ret = 0; // 设置返回值为0，表示成功
ffffffffc02031b4:	4901                	li	s2,0
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) { // 如果物理地址不存在，则分配一个页面并映射物理地址和逻辑地址
ffffffffc02031b6:	f955                	bnez	a0,ffffffffc020316a <do_pgfault+0x7a>
            cprintf("pgdir_alloc_page in do_pgfault failed\n"); // 打印错误信息
ffffffffc02031b8:	00005517          	auipc	a0,0x5
ffffffffc02031bc:	99850513          	addi	a0,a0,-1640 # ffffffffc0207b50 <commands+0x1130>
ffffffffc02031c0:	f0dfc0ef          	jal	ra,ffffffffc02000cc <cprintf>
    ret = -E_NO_MEM; // 初始化返回值为内存不足错误
ffffffffc02031c4:	5971                	li	s2,-4
            goto failed; // 跳转到失败处理
ffffffffc02031c6:	b755                	j	ffffffffc020316a <do_pgfault+0x7a>
            return cow_pgfault(mm, error_code, addr);
ffffffffc02031c8:	8622                	mv	a2,s0
}
ffffffffc02031ca:	7442                	ld	s0,48(sp)
ffffffffc02031cc:	70e2                	ld	ra,56(sp)
ffffffffc02031ce:	69e2                	ld	s3,24(sp)
            return cow_pgfault(mm, error_code, addr);
ffffffffc02031d0:	85ca                	mv	a1,s2
ffffffffc02031d2:	8526                	mv	a0,s1
}
ffffffffc02031d4:	7902                	ld	s2,32(sp)
ffffffffc02031d6:	74a2                	ld	s1,40(sp)
ffffffffc02031d8:	6121                	addi	sp,sp,64
            return cow_pgfault(mm, error_code, addr);
ffffffffc02031da:	ffbfd06f          	j	ffffffffc02011d4 <cow_pgfault>
        cprintf("not valid addr %x, and  can not find it in vma\n", addr); // 打印错误信息
ffffffffc02031de:	85a2                	mv	a1,s0
ffffffffc02031e0:	00005517          	auipc	a0,0x5
ffffffffc02031e4:	92050513          	addi	a0,a0,-1760 # ffffffffc0207b00 <commands+0x10e0>
ffffffffc02031e8:	ee5fc0ef          	jal	ra,ffffffffc02000cc <cprintf>
    int ret = -E_INVAL; // 初始化返回值为无效错误
ffffffffc02031ec:	5975                	li	s2,-3
        goto failed; // 跳转到失败处理
ffffffffc02031ee:	bfb5                	j	ffffffffc020316a <do_pgfault+0x7a>
            cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep); // 打印错误信息
ffffffffc02031f0:	00005517          	auipc	a0,0x5
ffffffffc02031f4:	98850513          	addi	a0,a0,-1656 # ffffffffc0207b78 <commands+0x1158>
ffffffffc02031f8:	ed5fc0ef          	jal	ra,ffffffffc02000cc <cprintf>
    ret = -E_NO_MEM; // 初始化返回值为内存不足错误
ffffffffc02031fc:	5971                	li	s2,-4
            goto failed; // 跳转到失败处理
ffffffffc02031fe:	b7b5                	j	ffffffffc020316a <do_pgfault+0x7a>
        cprintf("get_pte in do_pgfault failed\n"); // 打印错误信息
ffffffffc0203200:	00005517          	auipc	a0,0x5
ffffffffc0203204:	93050513          	addi	a0,a0,-1744 # ffffffffc0207b30 <commands+0x1110>
ffffffffc0203208:	ec5fc0ef          	jal	ra,ffffffffc02000cc <cprintf>
    ret = -E_NO_MEM; // 初始化返回值为内存不足错误
ffffffffc020320c:	5971                	li	s2,-4
        goto failed; // 跳转到失败处理
ffffffffc020320e:	bfb1                	j	ffffffffc020316a <do_pgfault+0x7a>

ffffffffc0203210 <user_mem_check>:

bool
user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write) {
ffffffffc0203210:	7179                	addi	sp,sp,-48
ffffffffc0203212:	f022                	sd	s0,32(sp)
ffffffffc0203214:	f406                	sd	ra,40(sp)
ffffffffc0203216:	ec26                	sd	s1,24(sp)
ffffffffc0203218:	e84a                	sd	s2,16(sp)
ffffffffc020321a:	e44e                	sd	s3,8(sp)
ffffffffc020321c:	e052                	sd	s4,0(sp)
ffffffffc020321e:	842e                	mv	s0,a1
    if (mm != NULL) { // 如果mm不为空
ffffffffc0203220:	c135                	beqz	a0,ffffffffc0203284 <user_mem_check+0x74>
        if (!USER_ACCESS(addr, addr + len)) { // 检查地址范围是否在用户空间
ffffffffc0203222:	002007b7          	lui	a5,0x200
ffffffffc0203226:	04f5e663          	bltu	a1,a5,ffffffffc0203272 <user_mem_check+0x62>
ffffffffc020322a:	00c584b3          	add	s1,a1,a2
ffffffffc020322e:	0495f263          	bgeu	a1,s1,ffffffffc0203272 <user_mem_check+0x62>
ffffffffc0203232:	4785                	li	a5,1
ffffffffc0203234:	07fe                	slli	a5,a5,0x1f
ffffffffc0203236:	0297ee63          	bltu	a5,s1,ffffffffc0203272 <user_mem_check+0x62>
ffffffffc020323a:	892a                	mv	s2,a0
ffffffffc020323c:	89b6                	mv	s3,a3
            }
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ))) { // 检查vma的权限，如果写操作但vma不可写，或者读操作但vma不可读
                return 0; // 返回0
            }
            if (write && (vma->vm_flags & VM_STACK)) { // 如果是写操作并且vma是栈
                if (start < vma->vm_start + PGSIZE) { // 检查栈的起始地址和大小
ffffffffc020323e:	6a05                	lui	s4,0x1
ffffffffc0203240:	a821                	j	ffffffffc0203258 <user_mem_check+0x48>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ))) { // 检查vma的权限，如果写操作但vma不可写，或者读操作但vma不可读
ffffffffc0203242:	0027f693          	andi	a3,a5,2
                if (start < vma->vm_start + PGSIZE) { // 检查栈的起始地址和大小
ffffffffc0203246:	9752                	add	a4,a4,s4
            if (write && (vma->vm_flags & VM_STACK)) { // 如果是写操作并且vma是栈
ffffffffc0203248:	8ba1                	andi	a5,a5,8
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ))) { // 检查vma的权限，如果写操作但vma不可写，或者读操作但vma不可读
ffffffffc020324a:	c685                	beqz	a3,ffffffffc0203272 <user_mem_check+0x62>
            if (write && (vma->vm_flags & VM_STACK)) { // 如果是写操作并且vma是栈
ffffffffc020324c:	c399                	beqz	a5,ffffffffc0203252 <user_mem_check+0x42>
                if (start < vma->vm_start + PGSIZE) { // 检查栈的起始地址和大小
ffffffffc020324e:	02e46263          	bltu	s0,a4,ffffffffc0203272 <user_mem_check+0x62>
                    return 0; // 返回0
                }
            }
            start = vma->vm_end; // 更新start为vma的结束地址
ffffffffc0203252:	6900                	ld	s0,16(a0)
        while (start < end) { // 遍历地址范围
ffffffffc0203254:	04947663          	bgeu	s0,s1,ffffffffc02032a0 <user_mem_check+0x90>
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start) { // 查找包含start地址的vma，如果找不到或者start小于vma的起始地址
ffffffffc0203258:	85a2                	mv	a1,s0
ffffffffc020325a:	854a                	mv	a0,s2
ffffffffc020325c:	eccff0ef          	jal	ra,ffffffffc0202928 <find_vma>
ffffffffc0203260:	c909                	beqz	a0,ffffffffc0203272 <user_mem_check+0x62>
ffffffffc0203262:	6518                	ld	a4,8(a0)
ffffffffc0203264:	00e46763          	bltu	s0,a4,ffffffffc0203272 <user_mem_check+0x62>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ))) { // 检查vma的权限，如果写操作但vma不可写，或者读操作但vma不可读
ffffffffc0203268:	4d1c                	lw	a5,24(a0)
ffffffffc020326a:	fc099ce3          	bnez	s3,ffffffffc0203242 <user_mem_check+0x32>
ffffffffc020326e:	8b85                	andi	a5,a5,1
ffffffffc0203270:	f3ed                	bnez	a5,ffffffffc0203252 <user_mem_check+0x42>
            return 0; // 如果不在用户空间，返回0
ffffffffc0203272:	4501                	li	a0,0
        }
        return 1; // 返回1表示成功
    }
    return KERN_ACCESS(addr, addr + len); // 如果mm为空，检查地址范围是否在内核空间
ffffffffc0203274:	70a2                	ld	ra,40(sp)
ffffffffc0203276:	7402                	ld	s0,32(sp)
ffffffffc0203278:	64e2                	ld	s1,24(sp)
ffffffffc020327a:	6942                	ld	s2,16(sp)
ffffffffc020327c:	69a2                	ld	s3,8(sp)
ffffffffc020327e:	6a02                	ld	s4,0(sp)
ffffffffc0203280:	6145                	addi	sp,sp,48
ffffffffc0203282:	8082                	ret
    return KERN_ACCESS(addr, addr + len); // 如果mm为空，检查地址范围是否在内核空间
ffffffffc0203284:	c02007b7          	lui	a5,0xc0200
ffffffffc0203288:	4501                	li	a0,0
ffffffffc020328a:	fef5e5e3          	bltu	a1,a5,ffffffffc0203274 <user_mem_check+0x64>
ffffffffc020328e:	962e                	add	a2,a2,a1
ffffffffc0203290:	fec5f2e3          	bgeu	a1,a2,ffffffffc0203274 <user_mem_check+0x64>
ffffffffc0203294:	c8000537          	lui	a0,0xc8000
ffffffffc0203298:	0505                	addi	a0,a0,1
ffffffffc020329a:	00a63533          	sltu	a0,a2,a0
ffffffffc020329e:	bfd9                	j	ffffffffc0203274 <user_mem_check+0x64>
        return 1; // 返回1表示成功
ffffffffc02032a0:	4505                	li	a0,1
ffffffffc02032a2:	bfc9                	j	ffffffffc0203274 <user_mem_check+0x64>

ffffffffc02032a4 <pa2page.part.0>:
pa2page(uintptr_t pa) {
ffffffffc02032a4:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc02032a6:	00004617          	auipc	a2,0x4
ffffffffc02032aa:	ed260613          	addi	a2,a2,-302 # ffffffffc0207178 <commands+0x758>
ffffffffc02032ae:	06200593          	li	a1,98
ffffffffc02032b2:	00004517          	auipc	a0,0x4
ffffffffc02032b6:	ee650513          	addi	a0,a0,-282 # ffffffffc0207198 <commands+0x778>
pa2page(uintptr_t pa) {
ffffffffc02032ba:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc02032bc:	f4dfc0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc02032c0 <swap_init>:
// 初始化交换管理器
// 参数：无
// 返回值：初始化结果，0表示成功，非0表示失败
int
swap_init(void)
{
ffffffffc02032c0:	7135                	addi	sp,sp,-160
ffffffffc02032c2:	ed06                	sd	ra,152(sp)
ffffffffc02032c4:	e922                	sd	s0,144(sp)
ffffffffc02032c6:	e526                	sd	s1,136(sp)
ffffffffc02032c8:	e14a                	sd	s2,128(sp)
ffffffffc02032ca:	fcce                	sd	s3,120(sp)
ffffffffc02032cc:	f8d2                	sd	s4,112(sp)
ffffffffc02032ce:	f4d6                	sd	s5,104(sp)
ffffffffc02032d0:	f0da                	sd	s6,96(sp)
ffffffffc02032d2:	ecde                	sd	s7,88(sp)
ffffffffc02032d4:	e8e2                	sd	s8,80(sp)
ffffffffc02032d6:	e4e6                	sd	s9,72(sp)
ffffffffc02032d8:	e0ea                	sd	s10,64(sp)
ffffffffc02032da:	fc6e                	sd	s11,56(sp)
     swapfs_init(); // 初始化交换文件系统
ffffffffc02032dc:	347010ef          	jal	ra,ffffffffc0204e22 <swapfs_init>

     // 检查最大交换偏移量是否合法
     if (!(7 <= max_swap_offset &&
ffffffffc02032e0:	000af697          	auipc	a3,0xaf
ffffffffc02032e4:	5c86b683          	ld	a3,1480(a3) # ffffffffc02b28a8 <max_swap_offset>
ffffffffc02032e8:	010007b7          	lui	a5,0x1000
ffffffffc02032ec:	ff968713          	addi	a4,a3,-7
ffffffffc02032f0:	17e1                	addi	a5,a5,-8
ffffffffc02032f2:	42e7e663          	bltu	a5,a4,ffffffffc020371e <swap_init+0x45e>
        max_swap_offset < MAX_SWAP_OFFSET_LIMIT)) {
        panic("bad max_swap_offset %08x.\n", max_swap_offset);
     }
     
     sm = &swap_manager_fifo; // 使用FIFO算法作为交换管理器
ffffffffc02032f6:	000a4797          	auipc	a5,0xa4
ffffffffc02032fa:	04278793          	addi	a5,a5,66 # ffffffffc02a7338 <swap_manager_fifo>
     int r = sm->init(); // 初始化交换管理器
ffffffffc02032fe:	6798                	ld	a4,8(a5)
     sm = &swap_manager_fifo; // 使用FIFO算法作为交换管理器
ffffffffc0203300:	000afb97          	auipc	s7,0xaf
ffffffffc0203304:	5b0b8b93          	addi	s7,s7,1456 # ffffffffc02b28b0 <sm>
ffffffffc0203308:	00fbb023          	sd	a5,0(s7)
     int r = sm->init(); // 初始化交换管理器
ffffffffc020330c:	9702                	jalr	a4
ffffffffc020330e:	892a                	mv	s2,a0
     
     if (r == 0)
ffffffffc0203310:	c10d                	beqz	a0,ffffffffc0203332 <swap_init+0x72>
          cprintf("SWAP: manager = %s\n", sm->name);
          check_swap(); // 检查交换功能
     }

     return r;
}
ffffffffc0203312:	60ea                	ld	ra,152(sp)
ffffffffc0203314:	644a                	ld	s0,144(sp)
ffffffffc0203316:	64aa                	ld	s1,136(sp)
ffffffffc0203318:	79e6                	ld	s3,120(sp)
ffffffffc020331a:	7a46                	ld	s4,112(sp)
ffffffffc020331c:	7aa6                	ld	s5,104(sp)
ffffffffc020331e:	7b06                	ld	s6,96(sp)
ffffffffc0203320:	6be6                	ld	s7,88(sp)
ffffffffc0203322:	6c46                	ld	s8,80(sp)
ffffffffc0203324:	6ca6                	ld	s9,72(sp)
ffffffffc0203326:	6d06                	ld	s10,64(sp)
ffffffffc0203328:	7de2                	ld	s11,56(sp)
ffffffffc020332a:	854a                	mv	a0,s2
ffffffffc020332c:	690a                	ld	s2,128(sp)
ffffffffc020332e:	610d                	addi	sp,sp,160
ffffffffc0203330:	8082                	ret
          cprintf("SWAP: manager = %s\n", sm->name);
ffffffffc0203332:	000bb783          	ld	a5,0(s7)
ffffffffc0203336:	00005517          	auipc	a0,0x5
ffffffffc020333a:	89a50513          	addi	a0,a0,-1894 # ffffffffc0207bd0 <commands+0x11b0>
ffffffffc020333e:	000ab417          	auipc	s0,0xab
ffffffffc0203342:	4ea40413          	addi	s0,s0,1258 # ffffffffc02ae828 <free_area>
ffffffffc0203346:	638c                	ld	a1,0(a5)
          swap_init_ok = 1;
ffffffffc0203348:	4785                	li	a5,1
ffffffffc020334a:	000af717          	auipc	a4,0xaf
ffffffffc020334e:	56f72723          	sw	a5,1390(a4) # ffffffffc02b28b8 <swap_init_ok>
          cprintf("SWAP: manager = %s\n", sm->name);
ffffffffc0203352:	d7bfc0ef          	jal	ra,ffffffffc02000cc <cprintf>
ffffffffc0203356:	641c                	ld	a5,8(s0)
// 检查交换功能
static void
check_swap(void)
{
    // 备份内存环境
     int ret, count = 0, total = 0, i;
ffffffffc0203358:	4d01                	li	s10,0
ffffffffc020335a:	4d81                	li	s11,0
     list_entry_t *le = &free_list;
     while ((le = list_next(le)) != &free_list) {
ffffffffc020335c:	34878163          	beq	a5,s0,ffffffffc020369e <swap_init+0x3de>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0203360:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0203364:	8b09                	andi	a4,a4,2
ffffffffc0203366:	32070e63          	beqz	a4,ffffffffc02036a2 <swap_init+0x3e2>
        count ++, total += p->property;
ffffffffc020336a:	ff87a703          	lw	a4,-8(a5)
ffffffffc020336e:	679c                	ld	a5,8(a5)
ffffffffc0203370:	2d85                	addiw	s11,s11,1
ffffffffc0203372:	01a70d3b          	addw	s10,a4,s10
     while ((le = list_next(le)) != &free_list) {
ffffffffc0203376:	fe8795e3          	bne	a5,s0,ffffffffc0203360 <swap_init+0xa0>
     }
     assert(total == nr_free_pages());
ffffffffc020337a:	84ea                	mv	s1,s10
ffffffffc020337c:	8eefe0ef          	jal	ra,ffffffffc020146a <nr_free_pages>
ffffffffc0203380:	42951763          	bne	a0,s1,ffffffffc02037ae <swap_init+0x4ee>
     cprintf("BEGIN check_swap: count %d, total %d\n",count,total);
ffffffffc0203384:	866a                	mv	a2,s10
ffffffffc0203386:	85ee                	mv	a1,s11
ffffffffc0203388:	00005517          	auipc	a0,0x5
ffffffffc020338c:	89050513          	addi	a0,a0,-1904 # ffffffffc0207c18 <commands+0x11f8>
ffffffffc0203390:	d3dfc0ef          	jal	ra,ffffffffc02000cc <cprintf>
     
     // 设置物理页面环境
     struct mm_struct *mm = mm_create();
ffffffffc0203394:	d1eff0ef          	jal	ra,ffffffffc02028b2 <mm_create>
ffffffffc0203398:	8aaa                	mv	s5,a0
     assert(mm != NULL);
ffffffffc020339a:	46050a63          	beqz	a0,ffffffffc020380e <swap_init+0x54e>

     extern struct mm_struct *check_mm_struct;
     assert(check_mm_struct == NULL);
ffffffffc020339e:	000af797          	auipc	a5,0xaf
ffffffffc02033a2:	4fa78793          	addi	a5,a5,1274 # ffffffffc02b2898 <check_mm_struct>
ffffffffc02033a6:	6398                	ld	a4,0(a5)
ffffffffc02033a8:	3e071363          	bnez	a4,ffffffffc020378e <swap_init+0x4ce>

     check_mm_struct = mm;

     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc02033ac:	000af717          	auipc	a4,0xaf
ffffffffc02033b0:	4c470713          	addi	a4,a4,1220 # ffffffffc02b2870 <boot_pgdir>
ffffffffc02033b4:	00073b03          	ld	s6,0(a4)
     check_mm_struct = mm;
ffffffffc02033b8:	e388                	sd	a0,0(a5)
     assert(pgdir[0] == 0);
ffffffffc02033ba:	000b3783          	ld	a5,0(s6)
     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc02033be:	01653c23          	sd	s6,24(a0)
     assert(pgdir[0] == 0);
ffffffffc02033c2:	42079663          	bnez	a5,ffffffffc02037ee <swap_init+0x52e>

     struct vma_struct *vma = vma_create(BEING_CHECK_VALID_VADDR, CHECK_VALID_VADDR, VM_WRITE | VM_READ);
ffffffffc02033c6:	6599                	lui	a1,0x6
ffffffffc02033c8:	460d                	li	a2,3
ffffffffc02033ca:	6505                	lui	a0,0x1
ffffffffc02033cc:	d2eff0ef          	jal	ra,ffffffffc02028fa <vma_create>
ffffffffc02033d0:	85aa                	mv	a1,a0
     assert(vma != NULL);
ffffffffc02033d2:	52050a63          	beqz	a0,ffffffffc0203906 <swap_init+0x646>

     insert_vma_struct(mm, vma);
ffffffffc02033d6:	8556                	mv	a0,s5
ffffffffc02033d8:	d90ff0ef          	jal	ra,ffffffffc0202968 <insert_vma_struct>

     // 设置临时页表
     cprintf("setup Page Table for vaddr 0X1000, so alloc a page\n");
ffffffffc02033dc:	00005517          	auipc	a0,0x5
ffffffffc02033e0:	87c50513          	addi	a0,a0,-1924 # ffffffffc0207c58 <commands+0x1238>
ffffffffc02033e4:	ce9fc0ef          	jal	ra,ffffffffc02000cc <cprintf>
     pte_t *temp_ptep=NULL;
     temp_ptep = get_pte(mm->pgdir, BEING_CHECK_VALID_VADDR, 1);
ffffffffc02033e8:	018ab503          	ld	a0,24(s5)
ffffffffc02033ec:	4605                	li	a2,1
ffffffffc02033ee:	6585                	lui	a1,0x1
ffffffffc02033f0:	8b4fe0ef          	jal	ra,ffffffffc02014a4 <get_pte>
     assert(temp_ptep!= NULL);
ffffffffc02033f4:	4c050963          	beqz	a0,ffffffffc02038c6 <swap_init+0x606>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc02033f8:	00005517          	auipc	a0,0x5
ffffffffc02033fc:	8b050513          	addi	a0,a0,-1872 # ffffffffc0207ca8 <commands+0x1288>
ffffffffc0203400:	000ab497          	auipc	s1,0xab
ffffffffc0203404:	3a848493          	addi	s1,s1,936 # ffffffffc02ae7a8 <check_rp>
ffffffffc0203408:	cc5fc0ef          	jal	ra,ffffffffc02000cc <cprintf>
     
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc020340c:	000ab997          	auipc	s3,0xab
ffffffffc0203410:	3bc98993          	addi	s3,s3,956 # ffffffffc02ae7c8 <swap_in_seq_no>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc0203414:	8a26                	mv	s4,s1
          check_rp[i] = alloc_page();
ffffffffc0203416:	4505                	li	a0,1
ffffffffc0203418:	f81fd0ef          	jal	ra,ffffffffc0201398 <alloc_pages>
ffffffffc020341c:	00aa3023          	sd	a0,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8bb8>
          assert(check_rp[i] != NULL );
ffffffffc0203420:	2c050f63          	beqz	a0,ffffffffc02036fe <swap_init+0x43e>
ffffffffc0203424:	651c                	ld	a5,8(a0)
          assert(!PageProperty(check_rp[i]));
ffffffffc0203426:	8b89                	andi	a5,a5,2
ffffffffc0203428:	34079363          	bnez	a5,ffffffffc020376e <swap_init+0x4ae>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc020342c:	0a21                	addi	s4,s4,8
ffffffffc020342e:	ff3a14e3          	bne	s4,s3,ffffffffc0203416 <swap_init+0x156>
     }
     list_entry_t free_list_store = free_list;
ffffffffc0203432:	601c                	ld	a5,0(s0)
     list_init(&free_list);
     assert(list_empty(&free_list));
     
     unsigned int nr_free_store = nr_free;
     nr_free = 0;
ffffffffc0203434:	000aba17          	auipc	s4,0xab
ffffffffc0203438:	374a0a13          	addi	s4,s4,884 # ffffffffc02ae7a8 <check_rp>
    elm->prev = elm->next = elm;
ffffffffc020343c:	e000                	sd	s0,0(s0)
     list_entry_t free_list_store = free_list;
ffffffffc020343e:	ec3e                	sd	a5,24(sp)
ffffffffc0203440:	641c                	ld	a5,8(s0)
ffffffffc0203442:	e400                	sd	s0,8(s0)
ffffffffc0203444:	f03e                	sd	a5,32(sp)
     unsigned int nr_free_store = nr_free;
ffffffffc0203446:	481c                	lw	a5,16(s0)
ffffffffc0203448:	f43e                	sd	a5,40(sp)
     nr_free = 0;
ffffffffc020344a:	000ab797          	auipc	a5,0xab
ffffffffc020344e:	3e07a723          	sw	zero,1006(a5) # ffffffffc02ae838 <free_area+0x10>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
        free_pages(check_rp[i],1);
ffffffffc0203452:	000a3503          	ld	a0,0(s4)
ffffffffc0203456:	4585                	li	a1,1
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0203458:	0a21                	addi	s4,s4,8
        free_pages(check_rp[i],1);
ffffffffc020345a:	fd1fd0ef          	jal	ra,ffffffffc020142a <free_pages>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc020345e:	ff3a1ae3          	bne	s4,s3,ffffffffc0203452 <swap_init+0x192>
     }
     assert(nr_free==CHECK_VALID_PHY_PAGE_NUM);
ffffffffc0203462:	01042a03          	lw	s4,16(s0)
ffffffffc0203466:	4791                	li	a5,4
ffffffffc0203468:	42fa1f63          	bne	s4,a5,ffffffffc02038a6 <swap_init+0x5e6>
     
     cprintf("set up init env for check_swap begin!\n");
ffffffffc020346c:	00005517          	auipc	a0,0x5
ffffffffc0203470:	8c450513          	addi	a0,a0,-1852 # ffffffffc0207d30 <commands+0x1310>
ffffffffc0203474:	c59fc0ef          	jal	ra,ffffffffc02000cc <cprintf>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc0203478:	6705                	lui	a4,0x1
     // 设置初始虚拟页面与物理页面的映射关系
     
     pgfault_num=0;
ffffffffc020347a:	000af797          	auipc	a5,0xaf
ffffffffc020347e:	4207a323          	sw	zero,1062(a5) # ffffffffc02b28a0 <pgfault_num>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc0203482:	4629                	li	a2,10
ffffffffc0203484:	00c70023          	sb	a2,0(a4) # 1000 <_binary_obj___user_faultread_out_size-0x8bb8>
     assert(pgfault_num==1);
ffffffffc0203488:	000af697          	auipc	a3,0xaf
ffffffffc020348c:	4186a683          	lw	a3,1048(a3) # ffffffffc02b28a0 <pgfault_num>
ffffffffc0203490:	4585                	li	a1,1
ffffffffc0203492:	000af797          	auipc	a5,0xaf
ffffffffc0203496:	40e78793          	addi	a5,a5,1038 # ffffffffc02b28a0 <pgfault_num>
ffffffffc020349a:	54b69663          	bne	a3,a1,ffffffffc02039e6 <swap_init+0x726>
     *(unsigned char *)0x1010 = 0x0a;
ffffffffc020349e:	00c70823          	sb	a2,16(a4)
     assert(pgfault_num==1);
ffffffffc02034a2:	4398                	lw	a4,0(a5)
ffffffffc02034a4:	2701                	sext.w	a4,a4
ffffffffc02034a6:	3ed71063          	bne	a4,a3,ffffffffc0203886 <swap_init+0x5c6>
     *(unsigned char *)0x2000 = 0x0b;
ffffffffc02034aa:	6689                	lui	a3,0x2
ffffffffc02034ac:	462d                	li	a2,11
ffffffffc02034ae:	00c68023          	sb	a2,0(a3) # 2000 <_binary_obj___user_faultread_out_size-0x7bb8>
     assert(pgfault_num==2);
ffffffffc02034b2:	4398                	lw	a4,0(a5)
ffffffffc02034b4:	4589                	li	a1,2
ffffffffc02034b6:	2701                	sext.w	a4,a4
ffffffffc02034b8:	4ab71763          	bne	a4,a1,ffffffffc0203966 <swap_init+0x6a6>
     *(unsigned char *)0x2010 = 0x0b;
ffffffffc02034bc:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==2);
ffffffffc02034c0:	4394                	lw	a3,0(a5)
ffffffffc02034c2:	2681                	sext.w	a3,a3
ffffffffc02034c4:	4ce69163          	bne	a3,a4,ffffffffc0203986 <swap_init+0x6c6>
     *(unsigned char *)0x3000 = 0x0c;
ffffffffc02034c8:	668d                	lui	a3,0x3
ffffffffc02034ca:	4631                	li	a2,12
ffffffffc02034cc:	00c68023          	sb	a2,0(a3) # 3000 <_binary_obj___user_faultread_out_size-0x6bb8>
     assert(pgfault_num==3);
ffffffffc02034d0:	4398                	lw	a4,0(a5)
ffffffffc02034d2:	458d                	li	a1,3
ffffffffc02034d4:	2701                	sext.w	a4,a4
ffffffffc02034d6:	4cb71863          	bne	a4,a1,ffffffffc02039a6 <swap_init+0x6e6>
     *(unsigned char *)0x3010 = 0x0c;
ffffffffc02034da:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==3);
ffffffffc02034de:	4394                	lw	a3,0(a5)
ffffffffc02034e0:	2681                	sext.w	a3,a3
ffffffffc02034e2:	4ee69263          	bne	a3,a4,ffffffffc02039c6 <swap_init+0x706>
     *(unsigned char *)0x4000 = 0x0d;
ffffffffc02034e6:	6691                	lui	a3,0x4
ffffffffc02034e8:	4635                	li	a2,13
ffffffffc02034ea:	00c68023          	sb	a2,0(a3) # 4000 <_binary_obj___user_faultread_out_size-0x5bb8>
     assert(pgfault_num==4);
ffffffffc02034ee:	4398                	lw	a4,0(a5)
ffffffffc02034f0:	2701                	sext.w	a4,a4
ffffffffc02034f2:	43471a63          	bne	a4,s4,ffffffffc0203926 <swap_init+0x666>
     *(unsigned char *)0x4010 = 0x0d;
ffffffffc02034f6:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==4);
ffffffffc02034fa:	439c                	lw	a5,0(a5)
ffffffffc02034fc:	2781                	sext.w	a5,a5
ffffffffc02034fe:	44e79463          	bne	a5,a4,ffffffffc0203946 <swap_init+0x686>
     
     check_content_set();
     assert( nr_free == 0);         
ffffffffc0203502:	481c                	lw	a5,16(s0)
ffffffffc0203504:	2c079563          	bnez	a5,ffffffffc02037ce <swap_init+0x50e>
ffffffffc0203508:	000ab797          	auipc	a5,0xab
ffffffffc020350c:	2c078793          	addi	a5,a5,704 # ffffffffc02ae7c8 <swap_in_seq_no>
ffffffffc0203510:	000ab717          	auipc	a4,0xab
ffffffffc0203514:	2e070713          	addi	a4,a4,736 # ffffffffc02ae7f0 <swap_out_seq_no>
ffffffffc0203518:	000ab617          	auipc	a2,0xab
ffffffffc020351c:	2d860613          	addi	a2,a2,728 # ffffffffc02ae7f0 <swap_out_seq_no>
     for(i = 0; i<MAX_SEQ_NO ; i++) 
         swap_out_seq_no[i]=swap_in_seq_no[i]=-1;
ffffffffc0203520:	56fd                	li	a3,-1
ffffffffc0203522:	c394                	sw	a3,0(a5)
ffffffffc0203524:	c314                	sw	a3,0(a4)
     for(i = 0; i<MAX_SEQ_NO ; i++) 
ffffffffc0203526:	0791                	addi	a5,a5,4
ffffffffc0203528:	0711                	addi	a4,a4,4
ffffffffc020352a:	fec79ce3          	bne	a5,a2,ffffffffc0203522 <swap_init+0x262>
ffffffffc020352e:	000ab717          	auipc	a4,0xab
ffffffffc0203532:	25a70713          	addi	a4,a4,602 # ffffffffc02ae788 <check_ptep>
ffffffffc0203536:	000ab697          	auipc	a3,0xab
ffffffffc020353a:	27268693          	addi	a3,a3,626 # ffffffffc02ae7a8 <check_rp>
ffffffffc020353e:	6585                	lui	a1,0x1
    if (PPN(pa) >= npage) {
ffffffffc0203540:	000afc17          	auipc	s8,0xaf
ffffffffc0203544:	338c0c13          	addi	s8,s8,824 # ffffffffc02b2878 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0203548:	000afc97          	auipc	s9,0xaf
ffffffffc020354c:	338c8c93          	addi	s9,s9,824 # ffffffffc02b2880 <pages>
     
     for (i= 0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
         check_ptep[i]=0;
ffffffffc0203550:	00073023          	sd	zero,0(a4)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0203554:	4601                	li	a2,0
ffffffffc0203556:	855a                	mv	a0,s6
ffffffffc0203558:	e836                	sd	a3,16(sp)
ffffffffc020355a:	e42e                	sd	a1,8(sp)
         check_ptep[i]=0;
ffffffffc020355c:	e03a                	sd	a4,0(sp)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc020355e:	f47fd0ef          	jal	ra,ffffffffc02014a4 <get_pte>
ffffffffc0203562:	6702                	ld	a4,0(sp)
         assert(check_ptep[i] != NULL);
ffffffffc0203564:	65a2                	ld	a1,8(sp)
ffffffffc0203566:	66c2                	ld	a3,16(sp)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0203568:	e308                	sd	a0,0(a4)
         assert(check_ptep[i] != NULL);
ffffffffc020356a:	1c050663          	beqz	a0,ffffffffc0203736 <swap_init+0x476>
         assert(pte2page(*check_ptep[i]) == check_rp[i]);
ffffffffc020356e:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc0203570:	0017f613          	andi	a2,a5,1
ffffffffc0203574:	1e060163          	beqz	a2,ffffffffc0203756 <swap_init+0x496>
    if (PPN(pa) >= npage) {
ffffffffc0203578:	000c3603          	ld	a2,0(s8)
    return pa2page(PTE_ADDR(pte));
ffffffffc020357c:	078a                	slli	a5,a5,0x2
ffffffffc020357e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203580:	14c7f363          	bgeu	a5,a2,ffffffffc02036c6 <swap_init+0x406>
    return &pages[PPN(pa) - nbase];
ffffffffc0203584:	00006617          	auipc	a2,0x6
ffffffffc0203588:	8ec60613          	addi	a2,a2,-1812 # ffffffffc0208e70 <nbase>
ffffffffc020358c:	00063a03          	ld	s4,0(a2)
ffffffffc0203590:	000cb603          	ld	a2,0(s9)
ffffffffc0203594:	6288                	ld	a0,0(a3)
ffffffffc0203596:	414787b3          	sub	a5,a5,s4
ffffffffc020359a:	079a                	slli	a5,a5,0x6
ffffffffc020359c:	97b2                	add	a5,a5,a2
ffffffffc020359e:	14f51063          	bne	a0,a5,ffffffffc02036de <swap_init+0x41e>
     for (i= 0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc02035a2:	6785                	lui	a5,0x1
ffffffffc02035a4:	95be                	add	a1,a1,a5
ffffffffc02035a6:	6795                	lui	a5,0x5
ffffffffc02035a8:	0721                	addi	a4,a4,8
ffffffffc02035aa:	06a1                	addi	a3,a3,8
ffffffffc02035ac:	faf592e3          	bne	a1,a5,ffffffffc0203550 <swap_init+0x290>
         assert((*check_ptep[i] & PTE_V));          
     }
     cprintf("set up init env for check_swap over!\n");
ffffffffc02035b0:	00005517          	auipc	a0,0x5
ffffffffc02035b4:	83850513          	addi	a0,a0,-1992 # ffffffffc0207de8 <commands+0x13c8>
ffffffffc02035b8:	b15fc0ef          	jal	ra,ffffffffc02000cc <cprintf>
    int ret = sm->check_swap();
ffffffffc02035bc:	000bb783          	ld	a5,0(s7)
ffffffffc02035c0:	7f9c                	ld	a5,56(a5)
ffffffffc02035c2:	9782                	jalr	a5
     // 访问虚拟页面以测试页面替换算法
     ret=check_content_access();
     assert(ret==0);
ffffffffc02035c4:	32051163          	bnez	a0,ffffffffc02038e6 <swap_init+0x626>

     nr_free = nr_free_store;
ffffffffc02035c8:	77a2                	ld	a5,40(sp)
ffffffffc02035ca:	c81c                	sw	a5,16(s0)
     free_list = free_list_store;
ffffffffc02035cc:	67e2                	ld	a5,24(sp)
ffffffffc02035ce:	e01c                	sd	a5,0(s0)
ffffffffc02035d0:	7782                	ld	a5,32(sp)
ffffffffc02035d2:	e41c                	sd	a5,8(s0)

     // 恢复内核内存环境
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
         free_pages(check_rp[i],1);
ffffffffc02035d4:	6088                	ld	a0,0(s1)
ffffffffc02035d6:	4585                	li	a1,1
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc02035d8:	04a1                	addi	s1,s1,8
         free_pages(check_rp[i],1);
ffffffffc02035da:	e51fd0ef          	jal	ra,ffffffffc020142a <free_pages>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc02035de:	ff349be3          	bne	s1,s3,ffffffffc02035d4 <swap_init+0x314>
     } 

     mm->pgdir = NULL;
ffffffffc02035e2:	000abc23          	sd	zero,24(s5)
     mm_destroy(mm);
ffffffffc02035e6:	8556                	mv	a0,s5
ffffffffc02035e8:	c50ff0ef          	jal	ra,ffffffffc0202a38 <mm_destroy>
     check_mm_struct = NULL;

     pde_t *pd1=pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
ffffffffc02035ec:	000af797          	auipc	a5,0xaf
ffffffffc02035f0:	28478793          	addi	a5,a5,644 # ffffffffc02b2870 <boot_pgdir>
ffffffffc02035f4:	639c                	ld	a5,0(a5)
    if (PPN(pa) >= npage) {
ffffffffc02035f6:	000c3703          	ld	a4,0(s8)
     check_mm_struct = NULL;
ffffffffc02035fa:	000af697          	auipc	a3,0xaf
ffffffffc02035fe:	2806bf23          	sd	zero,670(a3) # ffffffffc02b2898 <check_mm_struct>
    return pa2page(PDE_ADDR(pde));
ffffffffc0203602:	639c                	ld	a5,0(a5)
ffffffffc0203604:	078a                	slli	a5,a5,0x2
ffffffffc0203606:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203608:	0ae7fd63          	bgeu	a5,a4,ffffffffc02036c2 <swap_init+0x402>
    return &pages[PPN(pa) - nbase];
ffffffffc020360c:	414786b3          	sub	a3,a5,s4
ffffffffc0203610:	069a                	slli	a3,a3,0x6
    return page - pages + nbase;
ffffffffc0203612:	8699                	srai	a3,a3,0x6
ffffffffc0203614:	96d2                	add	a3,a3,s4
    return KADDR(page2pa(page));
ffffffffc0203616:	00c69793          	slli	a5,a3,0xc
ffffffffc020361a:	83b1                	srli	a5,a5,0xc
    return &pages[PPN(pa) - nbase];
ffffffffc020361c:	000cb503          	ld	a0,0(s9)
    return page2ppn(page) << PGSHIFT;
ffffffffc0203620:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0203622:	22e7f663          	bgeu	a5,a4,ffffffffc020384e <swap_init+0x58e>
     free_page(pde2page(pd0[0]));
ffffffffc0203626:	000af797          	auipc	a5,0xaf
ffffffffc020362a:	26a7b783          	ld	a5,618(a5) # ffffffffc02b2890 <va_pa_offset>
ffffffffc020362e:	96be                	add	a3,a3,a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0203630:	629c                	ld	a5,0(a3)
ffffffffc0203632:	078a                	slli	a5,a5,0x2
ffffffffc0203634:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203636:	08e7f663          	bgeu	a5,a4,ffffffffc02036c2 <swap_init+0x402>
    return &pages[PPN(pa) - nbase];
ffffffffc020363a:	414787b3          	sub	a5,a5,s4
ffffffffc020363e:	079a                	slli	a5,a5,0x6
ffffffffc0203640:	953e                	add	a0,a0,a5
ffffffffc0203642:	4585                	li	a1,1
ffffffffc0203644:	de7fd0ef          	jal	ra,ffffffffc020142a <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc0203648:	000b3783          	ld	a5,0(s6)
    if (PPN(pa) >= npage) {
ffffffffc020364c:	000c3703          	ld	a4,0(s8)
    return pa2page(PDE_ADDR(pde));
ffffffffc0203650:	078a                	slli	a5,a5,0x2
ffffffffc0203652:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203654:	06e7f763          	bgeu	a5,a4,ffffffffc02036c2 <swap_init+0x402>
    return &pages[PPN(pa) - nbase];
ffffffffc0203658:	000cb503          	ld	a0,0(s9)
ffffffffc020365c:	414787b3          	sub	a5,a5,s4
ffffffffc0203660:	079a                	slli	a5,a5,0x6
     free_page(pde2page(pd1[0]));
ffffffffc0203662:	4585                	li	a1,1
ffffffffc0203664:	953e                	add	a0,a0,a5
ffffffffc0203666:	dc5fd0ef          	jal	ra,ffffffffc020142a <free_pages>
     pgdir[0] = 0;
ffffffffc020366a:	000b3023          	sd	zero,0(s6)
  asm volatile("sfence.vma");
ffffffffc020366e:	12000073          	sfence.vma
    return listelm->next;
ffffffffc0203672:	641c                	ld	a5,8(s0)
     flush_tlb();

     le = &free_list;
     while ((le = list_next(le)) != &free_list) {
ffffffffc0203674:	00878a63          	beq	a5,s0,ffffffffc0203688 <swap_init+0x3c8>
         struct Page *p = le2page(le, page_link);
         count --, total -= p->property;
ffffffffc0203678:	ff87a703          	lw	a4,-8(a5)
ffffffffc020367c:	679c                	ld	a5,8(a5)
ffffffffc020367e:	3dfd                	addiw	s11,s11,-1
ffffffffc0203680:	40ed0d3b          	subw	s10,s10,a4
     while ((le = list_next(le)) != &free_list) {
ffffffffc0203684:	fe879ae3          	bne	a5,s0,ffffffffc0203678 <swap_init+0x3b8>
     }
     assert(count==0);
ffffffffc0203688:	1c0d9f63          	bnez	s11,ffffffffc0203866 <swap_init+0x5a6>
     assert(total==0);
ffffffffc020368c:	1a0d1163          	bnez	s10,ffffffffc020382e <swap_init+0x56e>

     cprintf("check_swap() succeeded!\n");
ffffffffc0203690:	00004517          	auipc	a0,0x4
ffffffffc0203694:	7a850513          	addi	a0,a0,1960 # ffffffffc0207e38 <commands+0x1418>
ffffffffc0203698:	a35fc0ef          	jal	ra,ffffffffc02000cc <cprintf>
}
ffffffffc020369c:	b99d                	j	ffffffffc0203312 <swap_init+0x52>
     while ((le = list_next(le)) != &free_list) {
ffffffffc020369e:	4481                	li	s1,0
ffffffffc02036a0:	b9f1                	j	ffffffffc020337c <swap_init+0xbc>
        assert(PageProperty(p));
ffffffffc02036a2:	00004697          	auipc	a3,0x4
ffffffffc02036a6:	54668693          	addi	a3,a3,1350 # ffffffffc0207be8 <commands+0x11c8>
ffffffffc02036aa:	00003617          	auipc	a2,0x3
ffffffffc02036ae:	78660613          	addi	a2,a2,1926 # ffffffffc0206e30 <commands+0x410>
ffffffffc02036b2:	0cb00593          	li	a1,203
ffffffffc02036b6:	00004517          	auipc	a0,0x4
ffffffffc02036ba:	50a50513          	addi	a0,a0,1290 # ffffffffc0207bc0 <commands+0x11a0>
ffffffffc02036be:	b4bfc0ef          	jal	ra,ffffffffc0200208 <__panic>
ffffffffc02036c2:	be3ff0ef          	jal	ra,ffffffffc02032a4 <pa2page.part.0>
        panic("pa2page called with invalid pa");
ffffffffc02036c6:	00004617          	auipc	a2,0x4
ffffffffc02036ca:	ab260613          	addi	a2,a2,-1358 # ffffffffc0207178 <commands+0x758>
ffffffffc02036ce:	06200593          	li	a1,98
ffffffffc02036d2:	00004517          	auipc	a0,0x4
ffffffffc02036d6:	ac650513          	addi	a0,a0,-1338 # ffffffffc0207198 <commands+0x778>
ffffffffc02036da:	b2ffc0ef          	jal	ra,ffffffffc0200208 <__panic>
         assert(pte2page(*check_ptep[i]) == check_rp[i]);
ffffffffc02036de:	00004697          	auipc	a3,0x4
ffffffffc02036e2:	6e268693          	addi	a3,a3,1762 # ffffffffc0207dc0 <commands+0x13a0>
ffffffffc02036e6:	00003617          	auipc	a2,0x3
ffffffffc02036ea:	74a60613          	addi	a2,a2,1866 # ffffffffc0206e30 <commands+0x410>
ffffffffc02036ee:	10700593          	li	a1,263
ffffffffc02036f2:	00004517          	auipc	a0,0x4
ffffffffc02036f6:	4ce50513          	addi	a0,a0,1230 # ffffffffc0207bc0 <commands+0x11a0>
ffffffffc02036fa:	b0ffc0ef          	jal	ra,ffffffffc0200208 <__panic>
          assert(check_rp[i] != NULL );
ffffffffc02036fe:	00004697          	auipc	a3,0x4
ffffffffc0203702:	5d268693          	addi	a3,a3,1490 # ffffffffc0207cd0 <commands+0x12b0>
ffffffffc0203706:	00003617          	auipc	a2,0x3
ffffffffc020370a:	72a60613          	addi	a2,a2,1834 # ffffffffc0206e30 <commands+0x410>
ffffffffc020370e:	0eb00593          	li	a1,235
ffffffffc0203712:	00004517          	auipc	a0,0x4
ffffffffc0203716:	4ae50513          	addi	a0,a0,1198 # ffffffffc0207bc0 <commands+0x11a0>
ffffffffc020371a:	aeffc0ef          	jal	ra,ffffffffc0200208 <__panic>
        panic("bad max_swap_offset %08x.\n", max_swap_offset);
ffffffffc020371e:	00004617          	auipc	a2,0x4
ffffffffc0203722:	48260613          	addi	a2,a2,1154 # ffffffffc0207ba0 <commands+0x1180>
ffffffffc0203726:	02b00593          	li	a1,43
ffffffffc020372a:	00004517          	auipc	a0,0x4
ffffffffc020372e:	49650513          	addi	a0,a0,1174 # ffffffffc0207bc0 <commands+0x11a0>
ffffffffc0203732:	ad7fc0ef          	jal	ra,ffffffffc0200208 <__panic>
         assert(check_ptep[i] != NULL);
ffffffffc0203736:	00004697          	auipc	a3,0x4
ffffffffc020373a:	67268693          	addi	a3,a3,1650 # ffffffffc0207da8 <commands+0x1388>
ffffffffc020373e:	00003617          	auipc	a2,0x3
ffffffffc0203742:	6f260613          	addi	a2,a2,1778 # ffffffffc0206e30 <commands+0x410>
ffffffffc0203746:	10600593          	li	a1,262
ffffffffc020374a:	00004517          	auipc	a0,0x4
ffffffffc020374e:	47650513          	addi	a0,a0,1142 # ffffffffc0207bc0 <commands+0x11a0>
ffffffffc0203752:	ab7fc0ef          	jal	ra,ffffffffc0200208 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc0203756:	00004617          	auipc	a2,0x4
ffffffffc020375a:	b2260613          	addi	a2,a2,-1246 # ffffffffc0207278 <commands+0x858>
ffffffffc020375e:	07400593          	li	a1,116
ffffffffc0203762:	00004517          	auipc	a0,0x4
ffffffffc0203766:	a3650513          	addi	a0,a0,-1482 # ffffffffc0207198 <commands+0x778>
ffffffffc020376a:	a9ffc0ef          	jal	ra,ffffffffc0200208 <__panic>
          assert(!PageProperty(check_rp[i]));
ffffffffc020376e:	00004697          	auipc	a3,0x4
ffffffffc0203772:	57a68693          	addi	a3,a3,1402 # ffffffffc0207ce8 <commands+0x12c8>
ffffffffc0203776:	00003617          	auipc	a2,0x3
ffffffffc020377a:	6ba60613          	addi	a2,a2,1722 # ffffffffc0206e30 <commands+0x410>
ffffffffc020377e:	0ec00593          	li	a1,236
ffffffffc0203782:	00004517          	auipc	a0,0x4
ffffffffc0203786:	43e50513          	addi	a0,a0,1086 # ffffffffc0207bc0 <commands+0x11a0>
ffffffffc020378a:	a7ffc0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(check_mm_struct == NULL);
ffffffffc020378e:	00004697          	auipc	a3,0x4
ffffffffc0203792:	4b268693          	addi	a3,a3,1202 # ffffffffc0207c40 <commands+0x1220>
ffffffffc0203796:	00003617          	auipc	a2,0x3
ffffffffc020379a:	69a60613          	addi	a2,a2,1690 # ffffffffc0206e30 <commands+0x410>
ffffffffc020379e:	0d600593          	li	a1,214
ffffffffc02037a2:	00004517          	auipc	a0,0x4
ffffffffc02037a6:	41e50513          	addi	a0,a0,1054 # ffffffffc0207bc0 <commands+0x11a0>
ffffffffc02037aa:	a5ffc0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(total == nr_free_pages());
ffffffffc02037ae:	00004697          	auipc	a3,0x4
ffffffffc02037b2:	44a68693          	addi	a3,a3,1098 # ffffffffc0207bf8 <commands+0x11d8>
ffffffffc02037b6:	00003617          	auipc	a2,0x3
ffffffffc02037ba:	67a60613          	addi	a2,a2,1658 # ffffffffc0206e30 <commands+0x410>
ffffffffc02037be:	0ce00593          	li	a1,206
ffffffffc02037c2:	00004517          	auipc	a0,0x4
ffffffffc02037c6:	3fe50513          	addi	a0,a0,1022 # ffffffffc0207bc0 <commands+0x11a0>
ffffffffc02037ca:	a3ffc0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert( nr_free == 0);         
ffffffffc02037ce:	00004697          	auipc	a3,0x4
ffffffffc02037d2:	5ca68693          	addi	a3,a3,1482 # ffffffffc0207d98 <commands+0x1378>
ffffffffc02037d6:	00003617          	auipc	a2,0x3
ffffffffc02037da:	65a60613          	addi	a2,a2,1626 # ffffffffc0206e30 <commands+0x410>
ffffffffc02037de:	0ff00593          	li	a1,255
ffffffffc02037e2:	00004517          	auipc	a0,0x4
ffffffffc02037e6:	3de50513          	addi	a0,a0,990 # ffffffffc0207bc0 <commands+0x11a0>
ffffffffc02037ea:	a1ffc0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(pgdir[0] == 0);
ffffffffc02037ee:	00004697          	auipc	a3,0x4
ffffffffc02037f2:	26268693          	addi	a3,a3,610 # ffffffffc0207a50 <commands+0x1030>
ffffffffc02037f6:	00003617          	auipc	a2,0x3
ffffffffc02037fa:	63a60613          	addi	a2,a2,1594 # ffffffffc0206e30 <commands+0x410>
ffffffffc02037fe:	0db00593          	li	a1,219
ffffffffc0203802:	00004517          	auipc	a0,0x4
ffffffffc0203806:	3be50513          	addi	a0,a0,958 # ffffffffc0207bc0 <commands+0x11a0>
ffffffffc020380a:	9fffc0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(mm != NULL);
ffffffffc020380e:	00004697          	auipc	a3,0x4
ffffffffc0203812:	09a68693          	addi	a3,a3,154 # ffffffffc02078a8 <commands+0xe88>
ffffffffc0203816:	00003617          	auipc	a2,0x3
ffffffffc020381a:	61a60613          	addi	a2,a2,1562 # ffffffffc0206e30 <commands+0x410>
ffffffffc020381e:	0d300593          	li	a1,211
ffffffffc0203822:	00004517          	auipc	a0,0x4
ffffffffc0203826:	39e50513          	addi	a0,a0,926 # ffffffffc0207bc0 <commands+0x11a0>
ffffffffc020382a:	9dffc0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(total==0);
ffffffffc020382e:	00004697          	auipc	a3,0x4
ffffffffc0203832:	5fa68693          	addi	a3,a3,1530 # ffffffffc0207e28 <commands+0x1408>
ffffffffc0203836:	00003617          	auipc	a2,0x3
ffffffffc020383a:	5fa60613          	addi	a2,a2,1530 # ffffffffc0206e30 <commands+0x410>
ffffffffc020383e:	12700593          	li	a1,295
ffffffffc0203842:	00004517          	auipc	a0,0x4
ffffffffc0203846:	37e50513          	addi	a0,a0,894 # ffffffffc0207bc0 <commands+0x11a0>
ffffffffc020384a:	9bffc0ef          	jal	ra,ffffffffc0200208 <__panic>
    return KADDR(page2pa(page));
ffffffffc020384e:	00004617          	auipc	a2,0x4
ffffffffc0203852:	99a60613          	addi	a2,a2,-1638 # ffffffffc02071e8 <commands+0x7c8>
ffffffffc0203856:	06900593          	li	a1,105
ffffffffc020385a:	00004517          	auipc	a0,0x4
ffffffffc020385e:	93e50513          	addi	a0,a0,-1730 # ffffffffc0207198 <commands+0x778>
ffffffffc0203862:	9a7fc0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(count==0);
ffffffffc0203866:	00004697          	auipc	a3,0x4
ffffffffc020386a:	5b268693          	addi	a3,a3,1458 # ffffffffc0207e18 <commands+0x13f8>
ffffffffc020386e:	00003617          	auipc	a2,0x3
ffffffffc0203872:	5c260613          	addi	a2,a2,1474 # ffffffffc0206e30 <commands+0x410>
ffffffffc0203876:	12600593          	li	a1,294
ffffffffc020387a:	00004517          	auipc	a0,0x4
ffffffffc020387e:	34650513          	addi	a0,a0,838 # ffffffffc0207bc0 <commands+0x11a0>
ffffffffc0203882:	987fc0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(pgfault_num==1);
ffffffffc0203886:	00004697          	auipc	a3,0x4
ffffffffc020388a:	4d268693          	addi	a3,a3,1234 # ffffffffc0207d58 <commands+0x1338>
ffffffffc020388e:	00003617          	auipc	a2,0x3
ffffffffc0203892:	5a260613          	addi	a2,a2,1442 # ffffffffc0206e30 <commands+0x410>
ffffffffc0203896:	0a200593          	li	a1,162
ffffffffc020389a:	00004517          	auipc	a0,0x4
ffffffffc020389e:	32650513          	addi	a0,a0,806 # ffffffffc0207bc0 <commands+0x11a0>
ffffffffc02038a2:	967fc0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(nr_free==CHECK_VALID_PHY_PAGE_NUM);
ffffffffc02038a6:	00004697          	auipc	a3,0x4
ffffffffc02038aa:	46268693          	addi	a3,a3,1122 # ffffffffc0207d08 <commands+0x12e8>
ffffffffc02038ae:	00003617          	auipc	a2,0x3
ffffffffc02038b2:	58260613          	addi	a2,a2,1410 # ffffffffc0206e30 <commands+0x410>
ffffffffc02038b6:	0f700593          	li	a1,247
ffffffffc02038ba:	00004517          	auipc	a0,0x4
ffffffffc02038be:	30650513          	addi	a0,a0,774 # ffffffffc0207bc0 <commands+0x11a0>
ffffffffc02038c2:	947fc0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(temp_ptep!= NULL);
ffffffffc02038c6:	00004697          	auipc	a3,0x4
ffffffffc02038ca:	3ca68693          	addi	a3,a3,970 # ffffffffc0207c90 <commands+0x1270>
ffffffffc02038ce:	00003617          	auipc	a2,0x3
ffffffffc02038d2:	56260613          	addi	a2,a2,1378 # ffffffffc0206e30 <commands+0x410>
ffffffffc02038d6:	0e600593          	li	a1,230
ffffffffc02038da:	00004517          	auipc	a0,0x4
ffffffffc02038de:	2e650513          	addi	a0,a0,742 # ffffffffc0207bc0 <commands+0x11a0>
ffffffffc02038e2:	927fc0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(ret==0);
ffffffffc02038e6:	00004697          	auipc	a3,0x4
ffffffffc02038ea:	52a68693          	addi	a3,a3,1322 # ffffffffc0207e10 <commands+0x13f0>
ffffffffc02038ee:	00003617          	auipc	a2,0x3
ffffffffc02038f2:	54260613          	addi	a2,a2,1346 # ffffffffc0206e30 <commands+0x410>
ffffffffc02038f6:	10d00593          	li	a1,269
ffffffffc02038fa:	00004517          	auipc	a0,0x4
ffffffffc02038fe:	2c650513          	addi	a0,a0,710 # ffffffffc0207bc0 <commands+0x11a0>
ffffffffc0203902:	907fc0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(vma != NULL);
ffffffffc0203906:	00004697          	auipc	a3,0x4
ffffffffc020390a:	1ea68693          	addi	a3,a3,490 # ffffffffc0207af0 <commands+0x10d0>
ffffffffc020390e:	00003617          	auipc	a2,0x3
ffffffffc0203912:	52260613          	addi	a2,a2,1314 # ffffffffc0206e30 <commands+0x410>
ffffffffc0203916:	0de00593          	li	a1,222
ffffffffc020391a:	00004517          	auipc	a0,0x4
ffffffffc020391e:	2a650513          	addi	a0,a0,678 # ffffffffc0207bc0 <commands+0x11a0>
ffffffffc0203922:	8e7fc0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(pgfault_num==4);
ffffffffc0203926:	00004697          	auipc	a3,0x4
ffffffffc020392a:	46268693          	addi	a3,a3,1122 # ffffffffc0207d88 <commands+0x1368>
ffffffffc020392e:	00003617          	auipc	a2,0x3
ffffffffc0203932:	50260613          	addi	a2,a2,1282 # ffffffffc0206e30 <commands+0x410>
ffffffffc0203936:	0ac00593          	li	a1,172
ffffffffc020393a:	00004517          	auipc	a0,0x4
ffffffffc020393e:	28650513          	addi	a0,a0,646 # ffffffffc0207bc0 <commands+0x11a0>
ffffffffc0203942:	8c7fc0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(pgfault_num==4);
ffffffffc0203946:	00004697          	auipc	a3,0x4
ffffffffc020394a:	44268693          	addi	a3,a3,1090 # ffffffffc0207d88 <commands+0x1368>
ffffffffc020394e:	00003617          	auipc	a2,0x3
ffffffffc0203952:	4e260613          	addi	a2,a2,1250 # ffffffffc0206e30 <commands+0x410>
ffffffffc0203956:	0ae00593          	li	a1,174
ffffffffc020395a:	00004517          	auipc	a0,0x4
ffffffffc020395e:	26650513          	addi	a0,a0,614 # ffffffffc0207bc0 <commands+0x11a0>
ffffffffc0203962:	8a7fc0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(pgfault_num==2);
ffffffffc0203966:	00004697          	auipc	a3,0x4
ffffffffc020396a:	40268693          	addi	a3,a3,1026 # ffffffffc0207d68 <commands+0x1348>
ffffffffc020396e:	00003617          	auipc	a2,0x3
ffffffffc0203972:	4c260613          	addi	a2,a2,1218 # ffffffffc0206e30 <commands+0x410>
ffffffffc0203976:	0a400593          	li	a1,164
ffffffffc020397a:	00004517          	auipc	a0,0x4
ffffffffc020397e:	24650513          	addi	a0,a0,582 # ffffffffc0207bc0 <commands+0x11a0>
ffffffffc0203982:	887fc0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(pgfault_num==2);
ffffffffc0203986:	00004697          	auipc	a3,0x4
ffffffffc020398a:	3e268693          	addi	a3,a3,994 # ffffffffc0207d68 <commands+0x1348>
ffffffffc020398e:	00003617          	auipc	a2,0x3
ffffffffc0203992:	4a260613          	addi	a2,a2,1186 # ffffffffc0206e30 <commands+0x410>
ffffffffc0203996:	0a600593          	li	a1,166
ffffffffc020399a:	00004517          	auipc	a0,0x4
ffffffffc020399e:	22650513          	addi	a0,a0,550 # ffffffffc0207bc0 <commands+0x11a0>
ffffffffc02039a2:	867fc0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(pgfault_num==3);
ffffffffc02039a6:	00004697          	auipc	a3,0x4
ffffffffc02039aa:	3d268693          	addi	a3,a3,978 # ffffffffc0207d78 <commands+0x1358>
ffffffffc02039ae:	00003617          	auipc	a2,0x3
ffffffffc02039b2:	48260613          	addi	a2,a2,1154 # ffffffffc0206e30 <commands+0x410>
ffffffffc02039b6:	0a800593          	li	a1,168
ffffffffc02039ba:	00004517          	auipc	a0,0x4
ffffffffc02039be:	20650513          	addi	a0,a0,518 # ffffffffc0207bc0 <commands+0x11a0>
ffffffffc02039c2:	847fc0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(pgfault_num==3);
ffffffffc02039c6:	00004697          	auipc	a3,0x4
ffffffffc02039ca:	3b268693          	addi	a3,a3,946 # ffffffffc0207d78 <commands+0x1358>
ffffffffc02039ce:	00003617          	auipc	a2,0x3
ffffffffc02039d2:	46260613          	addi	a2,a2,1122 # ffffffffc0206e30 <commands+0x410>
ffffffffc02039d6:	0aa00593          	li	a1,170
ffffffffc02039da:	00004517          	auipc	a0,0x4
ffffffffc02039de:	1e650513          	addi	a0,a0,486 # ffffffffc0207bc0 <commands+0x11a0>
ffffffffc02039e2:	827fc0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(pgfault_num==1);
ffffffffc02039e6:	00004697          	auipc	a3,0x4
ffffffffc02039ea:	37268693          	addi	a3,a3,882 # ffffffffc0207d58 <commands+0x1338>
ffffffffc02039ee:	00003617          	auipc	a2,0x3
ffffffffc02039f2:	44260613          	addi	a2,a2,1090 # ffffffffc0206e30 <commands+0x410>
ffffffffc02039f6:	0a000593          	li	a1,160
ffffffffc02039fa:	00004517          	auipc	a0,0x4
ffffffffc02039fe:	1c650513          	addi	a0,a0,454 # ffffffffc0207bc0 <commands+0x11a0>
ffffffffc0203a02:	807fc0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0203a06 <swap_init_mm>:
     return sm->init_mm(mm);
ffffffffc0203a06:	000af797          	auipc	a5,0xaf
ffffffffc0203a0a:	eaa7b783          	ld	a5,-342(a5) # ffffffffc02b28b0 <sm>
ffffffffc0203a0e:	6b9c                	ld	a5,16(a5)
ffffffffc0203a10:	8782                	jr	a5

ffffffffc0203a12 <swap_map_swappable>:
     return sm->map_swappable(mm, addr, page, swap_in);
ffffffffc0203a12:	000af797          	auipc	a5,0xaf
ffffffffc0203a16:	e9e7b783          	ld	a5,-354(a5) # ffffffffc02b28b0 <sm>
ffffffffc0203a1a:	739c                	ld	a5,32(a5)
ffffffffc0203a1c:	8782                	jr	a5

ffffffffc0203a1e <swap_out>:
{
ffffffffc0203a1e:	711d                	addi	sp,sp,-96
ffffffffc0203a20:	ec86                	sd	ra,88(sp)
ffffffffc0203a22:	e8a2                	sd	s0,80(sp)
ffffffffc0203a24:	e4a6                	sd	s1,72(sp)
ffffffffc0203a26:	e0ca                	sd	s2,64(sp)
ffffffffc0203a28:	fc4e                	sd	s3,56(sp)
ffffffffc0203a2a:	f852                	sd	s4,48(sp)
ffffffffc0203a2c:	f456                	sd	s5,40(sp)
ffffffffc0203a2e:	f05a                	sd	s6,32(sp)
ffffffffc0203a30:	ec5e                	sd	s7,24(sp)
ffffffffc0203a32:	e862                	sd	s8,16(sp)
     for (i = 0; i != n; ++ i)
ffffffffc0203a34:	cde9                	beqz	a1,ffffffffc0203b0e <swap_out+0xf0>
ffffffffc0203a36:	8a2e                	mv	s4,a1
ffffffffc0203a38:	892a                	mv	s2,a0
ffffffffc0203a3a:	8ab2                	mv	s5,a2
ffffffffc0203a3c:	4401                	li	s0,0
ffffffffc0203a3e:	000af997          	auipc	s3,0xaf
ffffffffc0203a42:	e7298993          	addi	s3,s3,-398 # ffffffffc02b28b0 <sm>
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0203a46:	00004b17          	auipc	s6,0x4
ffffffffc0203a4a:	472b0b13          	addi	s6,s6,1138 # ffffffffc0207eb8 <commands+0x1498>
                    cprintf("SWAP: failed to save\n");
ffffffffc0203a4e:	00004b97          	auipc	s7,0x4
ffffffffc0203a52:	452b8b93          	addi	s7,s7,1106 # ffffffffc0207ea0 <commands+0x1480>
ffffffffc0203a56:	a825                	j	ffffffffc0203a8e <swap_out+0x70>
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0203a58:	67a2                	ld	a5,8(sp)
ffffffffc0203a5a:	8626                	mv	a2,s1
ffffffffc0203a5c:	85a2                	mv	a1,s0
ffffffffc0203a5e:	7f94                	ld	a3,56(a5)
ffffffffc0203a60:	855a                	mv	a0,s6
     for (i = 0; i != n; ++ i)
ffffffffc0203a62:	2405                	addiw	s0,s0,1
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0203a64:	82b1                	srli	a3,a3,0xc
ffffffffc0203a66:	0685                	addi	a3,a3,1
ffffffffc0203a68:	e64fc0ef          	jal	ra,ffffffffc02000cc <cprintf>
                    *ptep = (page->pra_vaddr/PGSIZE+1)<<8;
ffffffffc0203a6c:	6522                	ld	a0,8(sp)
                    free_page(page); // 释放页面
ffffffffc0203a6e:	4585                	li	a1,1
                    *ptep = (page->pra_vaddr/PGSIZE+1)<<8;
ffffffffc0203a70:	7d1c                	ld	a5,56(a0)
ffffffffc0203a72:	83b1                	srli	a5,a5,0xc
ffffffffc0203a74:	0785                	addi	a5,a5,1
ffffffffc0203a76:	07a2                	slli	a5,a5,0x8
ffffffffc0203a78:	00fc3023          	sd	a5,0(s8)
                    free_page(page); // 释放页面
ffffffffc0203a7c:	9affd0ef          	jal	ra,ffffffffc020142a <free_pages>
          tlb_invalidate(mm->pgdir, v); // 刷新TLB
ffffffffc0203a80:	01893503          	ld	a0,24(s2)
ffffffffc0203a84:	85a6                	mv	a1,s1
ffffffffc0203a86:	d49fe0ef          	jal	ra,ffffffffc02027ce <tlb_invalidate>
     for (i = 0; i != n; ++ i)
ffffffffc0203a8a:	048a0d63          	beq	s4,s0,ffffffffc0203ae4 <swap_out+0xc6>
          int r = sm->swap_out_victim(mm, &page, in_tick); // 选择换出页面
ffffffffc0203a8e:	0009b783          	ld	a5,0(s3)
ffffffffc0203a92:	8656                	mv	a2,s5
ffffffffc0203a94:	002c                	addi	a1,sp,8
ffffffffc0203a96:	7b9c                	ld	a5,48(a5)
ffffffffc0203a98:	854a                	mv	a0,s2
ffffffffc0203a9a:	9782                	jalr	a5
          if (r != 0) {
ffffffffc0203a9c:	e12d                	bnez	a0,ffffffffc0203afe <swap_out+0xe0>
          v=page->pra_vaddr; 
ffffffffc0203a9e:	67a2                	ld	a5,8(sp)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc0203aa0:	01893503          	ld	a0,24(s2)
ffffffffc0203aa4:	4601                	li	a2,0
          v=page->pra_vaddr; 
ffffffffc0203aa6:	7f84                	ld	s1,56(a5)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc0203aa8:	85a6                	mv	a1,s1
ffffffffc0203aaa:	9fbfd0ef          	jal	ra,ffffffffc02014a4 <get_pte>
          assert((*ptep & PTE_V) != 0);
ffffffffc0203aae:	611c                	ld	a5,0(a0)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc0203ab0:	8c2a                	mv	s8,a0
          assert((*ptep & PTE_V) != 0);
ffffffffc0203ab2:	8b85                	andi	a5,a5,1
ffffffffc0203ab4:	cfb9                	beqz	a5,ffffffffc0203b12 <swap_out+0xf4>
          if (swapfs_write( (page->pra_vaddr/PGSIZE+1)<<8, page) != 0) { // 将页面写入交换文件
ffffffffc0203ab6:	65a2                	ld	a1,8(sp)
ffffffffc0203ab8:	7d9c                	ld	a5,56(a1)
ffffffffc0203aba:	83b1                	srli	a5,a5,0xc
ffffffffc0203abc:	0785                	addi	a5,a5,1
ffffffffc0203abe:	00879513          	slli	a0,a5,0x8
ffffffffc0203ac2:	426010ef          	jal	ra,ffffffffc0204ee8 <swapfs_write>
ffffffffc0203ac6:	d949                	beqz	a0,ffffffffc0203a58 <swap_out+0x3a>
                    cprintf("SWAP: failed to save\n");
ffffffffc0203ac8:	855e                	mv	a0,s7
ffffffffc0203aca:	e02fc0ef          	jal	ra,ffffffffc02000cc <cprintf>
                    sm->map_swappable(mm, v, page, 0);
ffffffffc0203ace:	0009b783          	ld	a5,0(s3)
ffffffffc0203ad2:	6622                	ld	a2,8(sp)
ffffffffc0203ad4:	4681                	li	a3,0
ffffffffc0203ad6:	739c                	ld	a5,32(a5)
ffffffffc0203ad8:	85a6                	mv	a1,s1
ffffffffc0203ada:	854a                	mv	a0,s2
     for (i = 0; i != n; ++ i)
ffffffffc0203adc:	2405                	addiw	s0,s0,1
                    sm->map_swappable(mm, v, page, 0);
ffffffffc0203ade:	9782                	jalr	a5
     for (i = 0; i != n; ++ i)
ffffffffc0203ae0:	fa8a17e3          	bne	s4,s0,ffffffffc0203a8e <swap_out+0x70>
}
ffffffffc0203ae4:	60e6                	ld	ra,88(sp)
ffffffffc0203ae6:	8522                	mv	a0,s0
ffffffffc0203ae8:	6446                	ld	s0,80(sp)
ffffffffc0203aea:	64a6                	ld	s1,72(sp)
ffffffffc0203aec:	6906                	ld	s2,64(sp)
ffffffffc0203aee:	79e2                	ld	s3,56(sp)
ffffffffc0203af0:	7a42                	ld	s4,48(sp)
ffffffffc0203af2:	7aa2                	ld	s5,40(sp)
ffffffffc0203af4:	7b02                	ld	s6,32(sp)
ffffffffc0203af6:	6be2                	ld	s7,24(sp)
ffffffffc0203af8:	6c42                	ld	s8,16(sp)
ffffffffc0203afa:	6125                	addi	sp,sp,96
ffffffffc0203afc:	8082                	ret
                    cprintf("i %d, swap_out: call swap_out_victim failed\n",i);
ffffffffc0203afe:	85a2                	mv	a1,s0
ffffffffc0203b00:	00004517          	auipc	a0,0x4
ffffffffc0203b04:	35850513          	addi	a0,a0,856 # ffffffffc0207e58 <commands+0x1438>
ffffffffc0203b08:	dc4fc0ef          	jal	ra,ffffffffc02000cc <cprintf>
                  break;
ffffffffc0203b0c:	bfe1                	j	ffffffffc0203ae4 <swap_out+0xc6>
     for (i = 0; i != n; ++ i)
ffffffffc0203b0e:	4401                	li	s0,0
ffffffffc0203b10:	bfd1                	j	ffffffffc0203ae4 <swap_out+0xc6>
          assert((*ptep & PTE_V) != 0);
ffffffffc0203b12:	00004697          	auipc	a3,0x4
ffffffffc0203b16:	37668693          	addi	a3,a3,886 # ffffffffc0207e88 <commands+0x1468>
ffffffffc0203b1a:	00003617          	auipc	a2,0x3
ffffffffc0203b1e:	31660613          	addi	a2,a2,790 # ffffffffc0206e30 <commands+0x410>
ffffffffc0203b22:	07400593          	li	a1,116
ffffffffc0203b26:	00004517          	auipc	a0,0x4
ffffffffc0203b2a:	09a50513          	addi	a0,a0,154 # ffffffffc0207bc0 <commands+0x11a0>
ffffffffc0203b2e:	edafc0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0203b32 <swap_in>:
{
ffffffffc0203b32:	7179                	addi	sp,sp,-48
ffffffffc0203b34:	e84a                	sd	s2,16(sp)
ffffffffc0203b36:	892a                	mv	s2,a0
     struct Page *result = alloc_page();
ffffffffc0203b38:	4505                	li	a0,1
{
ffffffffc0203b3a:	ec26                	sd	s1,24(sp)
ffffffffc0203b3c:	e44e                	sd	s3,8(sp)
ffffffffc0203b3e:	f406                	sd	ra,40(sp)
ffffffffc0203b40:	f022                	sd	s0,32(sp)
ffffffffc0203b42:	84ae                	mv	s1,a1
ffffffffc0203b44:	89b2                	mv	s3,a2
     struct Page *result = alloc_page();
ffffffffc0203b46:	853fd0ef          	jal	ra,ffffffffc0201398 <alloc_pages>
     assert(result!=NULL);
ffffffffc0203b4a:	c129                	beqz	a0,ffffffffc0203b8c <swap_in+0x5a>
     pte_t *ptep = get_pte(mm->pgdir, addr, 0);
ffffffffc0203b4c:	842a                	mv	s0,a0
ffffffffc0203b4e:	01893503          	ld	a0,24(s2)
ffffffffc0203b52:	4601                	li	a2,0
ffffffffc0203b54:	85a6                	mv	a1,s1
ffffffffc0203b56:	94ffd0ef          	jal	ra,ffffffffc02014a4 <get_pte>
ffffffffc0203b5a:	892a                	mv	s2,a0
     if ((r = swapfs_read((*ptep), result)) != 0) // 从交换文件读取页面
ffffffffc0203b5c:	6108                	ld	a0,0(a0)
ffffffffc0203b5e:	85a2                	mv	a1,s0
ffffffffc0203b60:	2fa010ef          	jal	ra,ffffffffc0204e5a <swapfs_read>
     cprintf("swap_in: load disk swap entry %d with swap_page in vadr 0x%x\n", (*ptep)>>8, addr);
ffffffffc0203b64:	00093583          	ld	a1,0(s2)
ffffffffc0203b68:	8626                	mv	a2,s1
ffffffffc0203b6a:	00004517          	auipc	a0,0x4
ffffffffc0203b6e:	39e50513          	addi	a0,a0,926 # ffffffffc0207f08 <commands+0x14e8>
ffffffffc0203b72:	81a1                	srli	a1,a1,0x8
ffffffffc0203b74:	d58fc0ef          	jal	ra,ffffffffc02000cc <cprintf>
}
ffffffffc0203b78:	70a2                	ld	ra,40(sp)
     *ptr_result=result;
ffffffffc0203b7a:	0089b023          	sd	s0,0(s3)
}
ffffffffc0203b7e:	7402                	ld	s0,32(sp)
ffffffffc0203b80:	64e2                	ld	s1,24(sp)
ffffffffc0203b82:	6942                	ld	s2,16(sp)
ffffffffc0203b84:	69a2                	ld	s3,8(sp)
ffffffffc0203b86:	4501                	li	a0,0
ffffffffc0203b88:	6145                	addi	sp,sp,48
ffffffffc0203b8a:	8082                	ret
     assert(result!=NULL);
ffffffffc0203b8c:	00004697          	auipc	a3,0x4
ffffffffc0203b90:	36c68693          	addi	a3,a3,876 # ffffffffc0207ef8 <commands+0x14d8>
ffffffffc0203b94:	00003617          	auipc	a2,0x3
ffffffffc0203b98:	29c60613          	addi	a2,a2,668 # ffffffffc0206e30 <commands+0x410>
ffffffffc0203b9c:	08d00593          	li	a1,141
ffffffffc0203ba0:	00004517          	auipc	a0,0x4
ffffffffc0203ba4:	02050513          	addi	a0,a0,32 # ffffffffc0207bc0 <commands+0x11a0>
ffffffffc0203ba8:	e60fc0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0203bac <slob_free>:
static void slob_free(void *block, int size) // 定义 slob_free 函数，释放内存块
{
	slob_t *cur, *b = (slob_t *)block; // 定义指针 cur 和 b，将 block 转换为 slob_t 类型
	unsigned long flags; // 定义标志

	if (!block) // 如果 block 为空
ffffffffc0203bac:	c94d                	beqz	a0,ffffffffc0203c5e <slob_free+0xb2>
{
ffffffffc0203bae:	1141                	addi	sp,sp,-16
ffffffffc0203bb0:	e022                	sd	s0,0(sp)
ffffffffc0203bb2:	e406                	sd	ra,8(sp)
ffffffffc0203bb4:	842a                	mv	s0,a0
		return; // 返回

	if (size) // 如果 size 不为 0
ffffffffc0203bb6:	e9c1                	bnez	a1,ffffffffc0203c46 <slob_free+0x9a>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203bb8:	100027f3          	csrr	a5,sstatus
ffffffffc0203bbc:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0203bbe:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203bc0:	ebd9                	bnez	a5,ffffffffc0203c56 <slob_free+0xaa>
		b->units = SLOB_UNITS(size); // 计算并设置 b 的单位数

	/* 查找重新插入点 */
	spin_lock_irqsave(&slob_lock, flags); // 加锁并保存中断状态
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next) // 遍历 slobfree 链表，查找插入点
ffffffffc0203bc2:	000a3617          	auipc	a2,0xa3
ffffffffc0203bc6:	7b660613          	addi	a2,a2,1974 # ffffffffc02a7378 <slobfree>
ffffffffc0203bca:	621c                	ld	a5,0(a2)
		if (cur >= cur->next && (b > cur || b < cur->next)) // 如果 cur 大于等于 cur->next 且 b 大于 cur 或 b 小于 cur->next
ffffffffc0203bcc:	873e                	mv	a4,a5
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next) // 遍历 slobfree 链表，查找插入点
ffffffffc0203bce:	679c                	ld	a5,8(a5)
ffffffffc0203bd0:	02877a63          	bgeu	a4,s0,ffffffffc0203c04 <slob_free+0x58>
ffffffffc0203bd4:	00f46463          	bltu	s0,a5,ffffffffc0203bdc <slob_free+0x30>
		if (cur >= cur->next && (b > cur || b < cur->next)) // 如果 cur 大于等于 cur->next 且 b 大于 cur 或 b 小于 cur->next
ffffffffc0203bd8:	fef76ae3          	bltu	a4,a5,ffffffffc0203bcc <slob_free+0x20>
			break; // 跳出循环

	if (b + b->units == cur->next) { // 如果 b 的末尾与 cur->next 相连
ffffffffc0203bdc:	400c                	lw	a1,0(s0)
ffffffffc0203bde:	00459693          	slli	a3,a1,0x4
ffffffffc0203be2:	96a2                	add	a3,a3,s0
ffffffffc0203be4:	02d78a63          	beq	a5,a3,ffffffffc0203c18 <slob_free+0x6c>
		b->units += cur->next->units; // 合并单位数
		b->next = cur->next->next; // 更新 b 的下一个指针
	} else // 否则
		b->next = cur->next; // 更新 b 的下一个指针

	if (cur + cur->units == b) { // 如果 cur 的末尾与 b 相连
ffffffffc0203be8:	4314                	lw	a3,0(a4)
		b->next = cur->next; // 更新 b 的下一个指针
ffffffffc0203bea:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b) { // 如果 cur 的末尾与 b 相连
ffffffffc0203bec:	00469793          	slli	a5,a3,0x4
ffffffffc0203bf0:	97ba                	add	a5,a5,a4
ffffffffc0203bf2:	02f40e63          	beq	s0,a5,ffffffffc0203c2e <slob_free+0x82>
		cur->units += b->units; // 合并单位数
		cur->next = b->next; // 更新 cur 的下一个指针
	} else // 否则
		cur->next = b; // 更新 cur 的下一个指针
ffffffffc0203bf6:	e700                	sd	s0,8(a4)

	slobfree = cur; // 更新 slobfree
ffffffffc0203bf8:	e218                	sd	a4,0(a2)
    if (flag) {
ffffffffc0203bfa:	e129                	bnez	a0,ffffffffc0203c3c <slob_free+0x90>

	spin_unlock_irqrestore(&slob_lock, flags); // 解锁并恢复中断状态
}
ffffffffc0203bfc:	60a2                	ld	ra,8(sp)
ffffffffc0203bfe:	6402                	ld	s0,0(sp)
ffffffffc0203c00:	0141                	addi	sp,sp,16
ffffffffc0203c02:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next)) // 如果 cur 大于等于 cur->next 且 b 大于 cur 或 b 小于 cur->next
ffffffffc0203c04:	fcf764e3          	bltu	a4,a5,ffffffffc0203bcc <slob_free+0x20>
ffffffffc0203c08:	fcf472e3          	bgeu	s0,a5,ffffffffc0203bcc <slob_free+0x20>
	if (b + b->units == cur->next) { // 如果 b 的末尾与 cur->next 相连
ffffffffc0203c0c:	400c                	lw	a1,0(s0)
ffffffffc0203c0e:	00459693          	slli	a3,a1,0x4
ffffffffc0203c12:	96a2                	add	a3,a3,s0
ffffffffc0203c14:	fcd79ae3          	bne	a5,a3,ffffffffc0203be8 <slob_free+0x3c>
		b->units += cur->next->units; // 合并单位数
ffffffffc0203c18:	4394                	lw	a3,0(a5)
		b->next = cur->next->next; // 更新 b 的下一个指针
ffffffffc0203c1a:	679c                	ld	a5,8(a5)
		b->units += cur->next->units; // 合并单位数
ffffffffc0203c1c:	9db5                	addw	a1,a1,a3
ffffffffc0203c1e:	c00c                	sw	a1,0(s0)
	if (cur + cur->units == b) { // 如果 cur 的末尾与 b 相连
ffffffffc0203c20:	4314                	lw	a3,0(a4)
		b->next = cur->next->next; // 更新 b 的下一个指针
ffffffffc0203c22:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b) { // 如果 cur 的末尾与 b 相连
ffffffffc0203c24:	00469793          	slli	a5,a3,0x4
ffffffffc0203c28:	97ba                	add	a5,a5,a4
ffffffffc0203c2a:	fcf416e3          	bne	s0,a5,ffffffffc0203bf6 <slob_free+0x4a>
		cur->units += b->units; // 合并单位数
ffffffffc0203c2e:	401c                	lw	a5,0(s0)
		cur->next = b->next; // 更新 cur 的下一个指针
ffffffffc0203c30:	640c                	ld	a1,8(s0)
	slobfree = cur; // 更新 slobfree
ffffffffc0203c32:	e218                	sd	a4,0(a2)
		cur->units += b->units; // 合并单位数
ffffffffc0203c34:	9ebd                	addw	a3,a3,a5
ffffffffc0203c36:	c314                	sw	a3,0(a4)
		cur->next = b->next; // 更新 cur 的下一个指针
ffffffffc0203c38:	e70c                	sd	a1,8(a4)
ffffffffc0203c3a:	d169                	beqz	a0,ffffffffc0203bfc <slob_free+0x50>
}
ffffffffc0203c3c:	6402                	ld	s0,0(sp)
ffffffffc0203c3e:	60a2                	ld	ra,8(sp)
ffffffffc0203c40:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc0203c42:	a01fc06f          	j	ffffffffc0200642 <intr_enable>
		b->units = SLOB_UNITS(size); // 计算并设置 b 的单位数
ffffffffc0203c46:	25bd                	addiw	a1,a1,15
ffffffffc0203c48:	8191                	srli	a1,a1,0x4
ffffffffc0203c4a:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203c4c:	100027f3          	csrr	a5,sstatus
ffffffffc0203c50:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0203c52:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203c54:	d7bd                	beqz	a5,ffffffffc0203bc2 <slob_free+0x16>
        intr_disable();
ffffffffc0203c56:	9f3fc0ef          	jal	ra,ffffffffc0200648 <intr_disable>
        return 1;
ffffffffc0203c5a:	4505                	li	a0,1
ffffffffc0203c5c:	b79d                	j	ffffffffc0203bc2 <slob_free+0x16>
ffffffffc0203c5e:	8082                	ret

ffffffffc0203c60 <__slob_get_free_pages.constprop.0>:
  struct Page * page = alloc_pages(1 << order); // 分配页面
ffffffffc0203c60:	4785                	li	a5,1
static void* __slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0203c62:	1141                	addi	sp,sp,-16
  struct Page * page = alloc_pages(1 << order); // 分配页面
ffffffffc0203c64:	00a7953b          	sllw	a0,a5,a0
static void* __slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0203c68:	e406                	sd	ra,8(sp)
  struct Page * page = alloc_pages(1 << order); // 分配页面
ffffffffc0203c6a:	f2efd0ef          	jal	ra,ffffffffc0201398 <alloc_pages>
  if(!page) // 如果页面分配失败
ffffffffc0203c6e:	c91d                	beqz	a0,ffffffffc0203ca4 <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc0203c70:	000af697          	auipc	a3,0xaf
ffffffffc0203c74:	c106b683          	ld	a3,-1008(a3) # ffffffffc02b2880 <pages>
ffffffffc0203c78:	8d15                	sub	a0,a0,a3
ffffffffc0203c7a:	8519                	srai	a0,a0,0x6
ffffffffc0203c7c:	00005697          	auipc	a3,0x5
ffffffffc0203c80:	1f46b683          	ld	a3,500(a3) # ffffffffc0208e70 <nbase>
ffffffffc0203c84:	9536                	add	a0,a0,a3
    return KADDR(page2pa(page));
ffffffffc0203c86:	00c51793          	slli	a5,a0,0xc
ffffffffc0203c8a:	83b1                	srli	a5,a5,0xc
ffffffffc0203c8c:	000af717          	auipc	a4,0xaf
ffffffffc0203c90:	bec73703          	ld	a4,-1044(a4) # ffffffffc02b2878 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc0203c94:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc0203c96:	00e7fa63          	bgeu	a5,a4,ffffffffc0203caa <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc0203c9a:	000af697          	auipc	a3,0xaf
ffffffffc0203c9e:	bf66b683          	ld	a3,-1034(a3) # ffffffffc02b2890 <va_pa_offset>
ffffffffc0203ca2:	9536                	add	a0,a0,a3
}
ffffffffc0203ca4:	60a2                	ld	ra,8(sp)
ffffffffc0203ca6:	0141                	addi	sp,sp,16
ffffffffc0203ca8:	8082                	ret
ffffffffc0203caa:	86aa                	mv	a3,a0
ffffffffc0203cac:	00003617          	auipc	a2,0x3
ffffffffc0203cb0:	53c60613          	addi	a2,a2,1340 # ffffffffc02071e8 <commands+0x7c8>
ffffffffc0203cb4:	06900593          	li	a1,105
ffffffffc0203cb8:	00003517          	auipc	a0,0x3
ffffffffc0203cbc:	4e050513          	addi	a0,a0,1248 # ffffffffc0207198 <commands+0x778>
ffffffffc0203cc0:	d48fc0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0203cc4 <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc0203cc4:	1101                	addi	sp,sp,-32
ffffffffc0203cc6:	ec06                	sd	ra,24(sp)
ffffffffc0203cc8:	e822                	sd	s0,16(sp)
ffffffffc0203cca:	e426                	sd	s1,8(sp)
ffffffffc0203ccc:	e04a                	sd	s2,0(sp)
  assert( (size + SLOB_UNIT) < PAGE_SIZE ); // 断言大小加上 SLOB 单位小于页面大小
ffffffffc0203cce:	01050713          	addi	a4,a0,16
ffffffffc0203cd2:	6785                	lui	a5,0x1
ffffffffc0203cd4:	0cf77363          	bgeu	a4,a5,ffffffffc0203d9a <slob_alloc.constprop.0+0xd6>
	int delta = 0, units = SLOB_UNITS(size); // 计算单位数
ffffffffc0203cd8:	00f50493          	addi	s1,a0,15
ffffffffc0203cdc:	8091                	srli	s1,s1,0x4
ffffffffc0203cde:	2481                	sext.w	s1,s1
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203ce0:	10002673          	csrr	a2,sstatus
ffffffffc0203ce4:	8a09                	andi	a2,a2,2
ffffffffc0203ce6:	e25d                	bnez	a2,ffffffffc0203d8c <slob_alloc.constprop.0+0xc8>
	prev = slobfree; // 初始化 prev
ffffffffc0203ce8:	000a3917          	auipc	s2,0xa3
ffffffffc0203cec:	69090913          	addi	s2,s2,1680 # ffffffffc02a7378 <slobfree>
ffffffffc0203cf0:	00093683          	ld	a3,0(s2)
	for (cur = prev->next; ; prev = cur, cur = cur->next) { // 遍历 slobfree 链表
ffffffffc0203cf4:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta) { /* 是否有足够空间？ */
ffffffffc0203cf6:	4398                	lw	a4,0(a5)
ffffffffc0203cf8:	08975e63          	bge	a4,s1,ffffffffc0203d94 <slob_alloc.constprop.0+0xd0>
		if (cur == slobfree) { // 如果遍历完链表
ffffffffc0203cfc:	00f68b63          	beq	a3,a5,ffffffffc0203d12 <slob_alloc.constprop.0+0x4e>
	for (cur = prev->next; ; prev = cur, cur = cur->next) { // 遍历 slobfree 链表
ffffffffc0203d00:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta) { /* 是否有足够空间？ */
ffffffffc0203d02:	4018                	lw	a4,0(s0)
ffffffffc0203d04:	02975a63          	bge	a4,s1,ffffffffc0203d38 <slob_alloc.constprop.0+0x74>
		if (cur == slobfree) { // 如果遍历完链表
ffffffffc0203d08:	00093683          	ld	a3,0(s2)
ffffffffc0203d0c:	87a2                	mv	a5,s0
ffffffffc0203d0e:	fef699e3          	bne	a3,a5,ffffffffc0203d00 <slob_alloc.constprop.0+0x3c>
    if (flag) {
ffffffffc0203d12:	ee31                	bnez	a2,ffffffffc0203d6e <slob_alloc.constprop.0+0xaa>
			cur = (slob_t *)__slob_get_free_page(gfp); // 获取新的页面
ffffffffc0203d14:	4501                	li	a0,0
ffffffffc0203d16:	f4bff0ef          	jal	ra,ffffffffc0203c60 <__slob_get_free_pages.constprop.0>
ffffffffc0203d1a:	842a                	mv	s0,a0
			if (!cur) // 如果获取失败
ffffffffc0203d1c:	cd05                	beqz	a0,ffffffffc0203d54 <slob_alloc.constprop.0+0x90>
			slob_free(cur, PAGE_SIZE); // 释放页面
ffffffffc0203d1e:	6585                	lui	a1,0x1
ffffffffc0203d20:	e8dff0ef          	jal	ra,ffffffffc0203bac <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203d24:	10002673          	csrr	a2,sstatus
ffffffffc0203d28:	8a09                	andi	a2,a2,2
ffffffffc0203d2a:	ee05                	bnez	a2,ffffffffc0203d62 <slob_alloc.constprop.0+0x9e>
			cur = slobfree; // 更新 cur
ffffffffc0203d2c:	00093783          	ld	a5,0(s2)
	for (cur = prev->next; ; prev = cur, cur = cur->next) { // 遍历 slobfree 链表
ffffffffc0203d30:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta) { /* 是否有足够空间？ */
ffffffffc0203d32:	4018                	lw	a4,0(s0)
ffffffffc0203d34:	fc974ae3          	blt	a4,s1,ffffffffc0203d08 <slob_alloc.constprop.0+0x44>
			if (cur->units == units) /* 是否正好适配？ */
ffffffffc0203d38:	04e48763          	beq	s1,a4,ffffffffc0203d86 <slob_alloc.constprop.0+0xc2>
				prev->next = cur + units; // 更新 prev 的下一个指针
ffffffffc0203d3c:	00449693          	slli	a3,s1,0x4
ffffffffc0203d40:	96a2                	add	a3,a3,s0
ffffffffc0203d42:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next; // 更新新块的下一个指针
ffffffffc0203d44:	640c                	ld	a1,8(s0)
				prev->next->units = cur->units - units; // 更新新块的单位数
ffffffffc0203d46:	9f05                	subw	a4,a4,s1
ffffffffc0203d48:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next; // 更新新块的下一个指针
ffffffffc0203d4a:	e68c                	sd	a1,8(a3)
				cur->units = units; // 更新当前块的单位数
ffffffffc0203d4c:	c004                	sw	s1,0(s0)
			slobfree = prev; // 更新 slobfree
ffffffffc0203d4e:	00f93023          	sd	a5,0(s2)
    if (flag) {
ffffffffc0203d52:	e20d                	bnez	a2,ffffffffc0203d74 <slob_alloc.constprop.0+0xb0>
}
ffffffffc0203d54:	60e2                	ld	ra,24(sp)
ffffffffc0203d56:	8522                	mv	a0,s0
ffffffffc0203d58:	6442                	ld	s0,16(sp)
ffffffffc0203d5a:	64a2                	ld	s1,8(sp)
ffffffffc0203d5c:	6902                	ld	s2,0(sp)
ffffffffc0203d5e:	6105                	addi	sp,sp,32
ffffffffc0203d60:	8082                	ret
        intr_disable();
ffffffffc0203d62:	8e7fc0ef          	jal	ra,ffffffffc0200648 <intr_disable>
			cur = slobfree; // 更新 cur
ffffffffc0203d66:	00093783          	ld	a5,0(s2)
        return 1;
ffffffffc0203d6a:	4605                	li	a2,1
ffffffffc0203d6c:	b7d1                	j	ffffffffc0203d30 <slob_alloc.constprop.0+0x6c>
        intr_enable();
ffffffffc0203d6e:	8d5fc0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc0203d72:	b74d                	j	ffffffffc0203d14 <slob_alloc.constprop.0+0x50>
ffffffffc0203d74:	8cffc0ef          	jal	ra,ffffffffc0200642 <intr_enable>
}
ffffffffc0203d78:	60e2                	ld	ra,24(sp)
ffffffffc0203d7a:	8522                	mv	a0,s0
ffffffffc0203d7c:	6442                	ld	s0,16(sp)
ffffffffc0203d7e:	64a2                	ld	s1,8(sp)
ffffffffc0203d80:	6902                	ld	s2,0(sp)
ffffffffc0203d82:	6105                	addi	sp,sp,32
ffffffffc0203d84:	8082                	ret
				prev->next = cur->next; /* 取消链接 */
ffffffffc0203d86:	6418                	ld	a4,8(s0)
ffffffffc0203d88:	e798                	sd	a4,8(a5)
ffffffffc0203d8a:	b7d1                	j	ffffffffc0203d4e <slob_alloc.constprop.0+0x8a>
        intr_disable();
ffffffffc0203d8c:	8bdfc0ef          	jal	ra,ffffffffc0200648 <intr_disable>
        return 1;
ffffffffc0203d90:	4605                	li	a2,1
ffffffffc0203d92:	bf99                	j	ffffffffc0203ce8 <slob_alloc.constprop.0+0x24>
		if (cur->units >= units + delta) { /* 是否有足够空间？ */
ffffffffc0203d94:	843e                	mv	s0,a5
ffffffffc0203d96:	87b6                	mv	a5,a3
ffffffffc0203d98:	b745                	j	ffffffffc0203d38 <slob_alloc.constprop.0+0x74>
  assert( (size + SLOB_UNIT) < PAGE_SIZE ); // 断言大小加上 SLOB 单位小于页面大小
ffffffffc0203d9a:	00004697          	auipc	a3,0x4
ffffffffc0203d9e:	1ae68693          	addi	a3,a3,430 # ffffffffc0207f48 <commands+0x1528>
ffffffffc0203da2:	00003617          	auipc	a2,0x3
ffffffffc0203da6:	08e60613          	addi	a2,a2,142 # ffffffffc0206e30 <commands+0x410>
ffffffffc0203daa:	05a00593          	li	a1,90
ffffffffc0203dae:	00004517          	auipc	a0,0x4
ffffffffc0203db2:	1ba50513          	addi	a0,a0,442 # ffffffffc0207f68 <commands+0x1548>
ffffffffc0203db6:	c52fc0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0203dba <kmalloc_init>:

void slob_init(void) { // 定义 slob_init 函数，初始化 SLOB 分配器
  cprintf("use SLOB allocator\n"); // 打印使用 SLOB 分配器的信息
}

inline void kmalloc_init(void) { // 定义 kmalloc_init 函数，初始化 kmalloc
ffffffffc0203dba:	1141                	addi	sp,sp,-16
  cprintf("use SLOB allocator\n"); // 打印使用 SLOB 分配器的信息
ffffffffc0203dbc:	00004517          	auipc	a0,0x4
ffffffffc0203dc0:	1c450513          	addi	a0,a0,452 # ffffffffc0207f80 <commands+0x1560>
inline void kmalloc_init(void) { // 定义 kmalloc_init 函数，初始化 kmalloc
ffffffffc0203dc4:	e406                	sd	ra,8(sp)
  cprintf("use SLOB allocator\n"); // 打印使用 SLOB 分配器的信息
ffffffffc0203dc6:	b06fc0ef          	jal	ra,ffffffffc02000cc <cprintf>
	slob_init(); // 调用 slob_init 函数
	cprintf("kmalloc_init() succeeded!\n"); // 打印 kmalloc 初始化成功的信息
}
ffffffffc0203dca:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n"); // 打印 kmalloc 初始化成功的信息
ffffffffc0203dcc:	00004517          	auipc	a0,0x4
ffffffffc0203dd0:	1cc50513          	addi	a0,a0,460 # ffffffffc0207f98 <commands+0x1578>
}
ffffffffc0203dd4:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n"); // 打印 kmalloc 初始化成功的信息
ffffffffc0203dd6:	af6fc06f          	j	ffffffffc02000cc <cprintf>

ffffffffc0203dda <kallocated>:
  return 0; // 返回 0
}

size_t kallocated(void) { // 定义 kallocated 函数，返回已分配的内存大小
   return slob_allocated(); // 调用 slob_allocated 函数并返回结果
}
ffffffffc0203dda:	4501                	li	a0,0
ffffffffc0203ddc:	8082                	ret

ffffffffc0203dde <kmalloc>:
	return 0; // 返回 0
}

void *
kmalloc(size_t size) // 定义 kmalloc 函数，分配内存
{
ffffffffc0203dde:	1101                	addi	sp,sp,-32
ffffffffc0203de0:	e04a                	sd	s2,0(sp)
	if (size < PAGE_SIZE - SLOB_UNIT) { // 如果 size 小于页面大小减去 SLOB 单位大小
ffffffffc0203de2:	6905                	lui	s2,0x1
{
ffffffffc0203de4:	e822                	sd	s0,16(sp)
ffffffffc0203de6:	ec06                	sd	ra,24(sp)
ffffffffc0203de8:	e426                	sd	s1,8(sp)
	if (size < PAGE_SIZE - SLOB_UNIT) { // 如果 size 小于页面大小减去 SLOB 单位大小
ffffffffc0203dea:	fef90793          	addi	a5,s2,-17 # fef <_binary_obj___user_faultread_out_size-0x8bc9>
{
ffffffffc0203dee:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT) { // 如果 size 小于页面大小减去 SLOB 单位大小
ffffffffc0203df0:	04a7f963          	bgeu	a5,a0,ffffffffc0203e42 <kmalloc+0x64>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0); // 调用 slob_alloc 分配 bigblock_t 大小的内存
ffffffffc0203df4:	4561                	li	a0,24
ffffffffc0203df6:	ecfff0ef          	jal	ra,ffffffffc0203cc4 <slob_alloc.constprop.0>
ffffffffc0203dfa:	84aa                	mv	s1,a0
	if (!bb) // 如果分配失败
ffffffffc0203dfc:	c929                	beqz	a0,ffffffffc0203e4e <kmalloc+0x70>
	bb->order = find_order(size); // 调用 find_order 函数查找合适的顺序
ffffffffc0203dfe:	0004079b          	sext.w	a5,s0
	int order = 0; // 初始化顺序为 0
ffffffffc0203e02:	4501                	li	a0,0
	for ( ; size > 4096 ; size >>=1) // 当 size 大于 4096 时，右移一位
ffffffffc0203e04:	00f95763          	bge	s2,a5,ffffffffc0203e12 <kmalloc+0x34>
ffffffffc0203e08:	6705                	lui	a4,0x1
ffffffffc0203e0a:	8785                	srai	a5,a5,0x1
		order++; // 增加顺序
ffffffffc0203e0c:	2505                	addiw	a0,a0,1
	for ( ; size > 4096 ; size >>=1) // 当 size 大于 4096 时，右移一位
ffffffffc0203e0e:	fef74ee3          	blt	a4,a5,ffffffffc0203e0a <kmalloc+0x2c>
	bb->order = find_order(size); // 调用 find_order 函数查找合适的顺序
ffffffffc0203e12:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order); // 调用 __slob_get_free_pages 分配页面
ffffffffc0203e14:	e4dff0ef          	jal	ra,ffffffffc0203c60 <__slob_get_free_pages.constprop.0>
ffffffffc0203e18:	e488                	sd	a0,8(s1)
ffffffffc0203e1a:	842a                	mv	s0,a0
	if (bb->pages) { // 如果页面分配成功
ffffffffc0203e1c:	c525                	beqz	a0,ffffffffc0203e84 <kmalloc+0xa6>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203e1e:	100027f3          	csrr	a5,sstatus
ffffffffc0203e22:	8b89                	andi	a5,a5,2
ffffffffc0203e24:	ef8d                	bnez	a5,ffffffffc0203e5e <kmalloc+0x80>
		bb->next = bigblocks; // 将 bigblocks 赋值给 bb 的 next 指针
ffffffffc0203e26:	000af797          	auipc	a5,0xaf
ffffffffc0203e2a:	a9a78793          	addi	a5,a5,-1382 # ffffffffc02b28c0 <bigblocks>
ffffffffc0203e2e:	6398                	ld	a4,0(a5)
		bigblocks = bb; // 将 bb 赋值给 bigblocks
ffffffffc0203e30:	e384                	sd	s1,0(a5)
		bb->next = bigblocks; // 将 bigblocks 赋值给 bb 的 next 指针
ffffffffc0203e32:	e898                	sd	a4,16(s1)
  return __kmalloc(size, 0); // 调用 __kmalloc 函数分配内存
}
ffffffffc0203e34:	60e2                	ld	ra,24(sp)
ffffffffc0203e36:	8522                	mv	a0,s0
ffffffffc0203e38:	6442                	ld	s0,16(sp)
ffffffffc0203e3a:	64a2                	ld	s1,8(sp)
ffffffffc0203e3c:	6902                	ld	s2,0(sp)
ffffffffc0203e3e:	6105                	addi	sp,sp,32
ffffffffc0203e40:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0); // 调用 slob_alloc 分配内存
ffffffffc0203e42:	0541                	addi	a0,a0,16
ffffffffc0203e44:	e81ff0ef          	jal	ra,ffffffffc0203cc4 <slob_alloc.constprop.0>
		return m ? (void *)(m + 1) : 0; // 如果分配成功，返回 m + 1，否则返回 0
ffffffffc0203e48:	01050413          	addi	s0,a0,16
ffffffffc0203e4c:	f565                	bnez	a0,ffffffffc0203e34 <kmalloc+0x56>
ffffffffc0203e4e:	4401                	li	s0,0
}
ffffffffc0203e50:	60e2                	ld	ra,24(sp)
ffffffffc0203e52:	8522                	mv	a0,s0
ffffffffc0203e54:	6442                	ld	s0,16(sp)
ffffffffc0203e56:	64a2                	ld	s1,8(sp)
ffffffffc0203e58:	6902                	ld	s2,0(sp)
ffffffffc0203e5a:	6105                	addi	sp,sp,32
ffffffffc0203e5c:	8082                	ret
        intr_disable();
ffffffffc0203e5e:	feafc0ef          	jal	ra,ffffffffc0200648 <intr_disable>
		bb->next = bigblocks; // 将 bigblocks 赋值给 bb 的 next 指针
ffffffffc0203e62:	000af797          	auipc	a5,0xaf
ffffffffc0203e66:	a5e78793          	addi	a5,a5,-1442 # ffffffffc02b28c0 <bigblocks>
ffffffffc0203e6a:	6398                	ld	a4,0(a5)
		bigblocks = bb; // 将 bb 赋值给 bigblocks
ffffffffc0203e6c:	e384                	sd	s1,0(a5)
		bb->next = bigblocks; // 将 bigblocks 赋值给 bb 的 next 指针
ffffffffc0203e6e:	e898                	sd	a4,16(s1)
        intr_enable();
ffffffffc0203e70:	fd2fc0ef          	jal	ra,ffffffffc0200642 <intr_enable>
		return bb->pages; // 返回分配的页面
ffffffffc0203e74:	6480                	ld	s0,8(s1)
}
ffffffffc0203e76:	60e2                	ld	ra,24(sp)
ffffffffc0203e78:	64a2                	ld	s1,8(sp)
ffffffffc0203e7a:	8522                	mv	a0,s0
ffffffffc0203e7c:	6442                	ld	s0,16(sp)
ffffffffc0203e7e:	6902                	ld	s2,0(sp)
ffffffffc0203e80:	6105                	addi	sp,sp,32
ffffffffc0203e82:	8082                	ret
	slob_free(bb, sizeof(bigblock_t)); // 调用 slob_free 释放内存
ffffffffc0203e84:	45e1                	li	a1,24
ffffffffc0203e86:	8526                	mv	a0,s1
ffffffffc0203e88:	d25ff0ef          	jal	ra,ffffffffc0203bac <slob_free>
  return __kmalloc(size, 0); // 调用 __kmalloc 函数分配内存
ffffffffc0203e8c:	b765                	j	ffffffffc0203e34 <kmalloc+0x56>

ffffffffc0203e8e <kfree>:
void kfree(void *block) // 定义 kfree 函数，释放内存
{
	bigblock_t *bb, **last = &bigblocks; // 定义 bigblock_t 类型的指针 bb 和 last，将 bigblocks 的地址赋值给 last
	unsigned long flags; // 定义标志

	if (!block) // 如果 block 为空
ffffffffc0203e8e:	c179                	beqz	a0,ffffffffc0203f54 <kfree+0xc6>
{
ffffffffc0203e90:	1101                	addi	sp,sp,-32
ffffffffc0203e92:	e822                	sd	s0,16(sp)
ffffffffc0203e94:	ec06                	sd	ra,24(sp)
ffffffffc0203e96:	e426                	sd	s1,8(sp)
		return; // 返回

	if (!((unsigned long)block & (PAGE_SIZE-1))) { // 如果 block 是页面对齐的
ffffffffc0203e98:	03451793          	slli	a5,a0,0x34
ffffffffc0203e9c:	842a                	mv	s0,a0
ffffffffc0203e9e:	e7c1                	bnez	a5,ffffffffc0203f26 <kfree+0x98>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203ea0:	100027f3          	csrr	a5,sstatus
ffffffffc0203ea4:	8b89                	andi	a5,a5,2
ffffffffc0203ea6:	ebc9                	bnez	a5,ffffffffc0203f38 <kfree+0xaa>
		/* 可能在大块列表中 */
		spin_lock_irqsave(&block_lock, flags); // 加锁并保存中断状态
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) { // 遍历 bigblocks 链表
ffffffffc0203ea8:	000af797          	auipc	a5,0xaf
ffffffffc0203eac:	a187b783          	ld	a5,-1512(a5) # ffffffffc02b28c0 <bigblocks>
    return 0;
ffffffffc0203eb0:	4601                	li	a2,0
ffffffffc0203eb2:	cbb5                	beqz	a5,ffffffffc0203f26 <kfree+0x98>
	bigblock_t *bb, **last = &bigblocks; // 定义 bigblock_t 类型的指针 bb 和 last，将 bigblocks 的地址赋值给 last
ffffffffc0203eb4:	000af697          	auipc	a3,0xaf
ffffffffc0203eb8:	a0c68693          	addi	a3,a3,-1524 # ffffffffc02b28c0 <bigblocks>
ffffffffc0203ebc:	a021                	j	ffffffffc0203ec4 <kfree+0x36>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) { // 遍历 bigblocks 链表
ffffffffc0203ebe:	01048693          	addi	a3,s1,16
ffffffffc0203ec2:	c3ad                	beqz	a5,ffffffffc0203f24 <kfree+0x96>
			if (bb->pages == block) { // 如果找到匹配的页面
ffffffffc0203ec4:	6798                	ld	a4,8(a5)
ffffffffc0203ec6:	84be                	mv	s1,a5
				*last = bb->next; // 更新 last 的 next 指针
ffffffffc0203ec8:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block) { // 如果找到匹配的页面
ffffffffc0203eca:	fe871ae3          	bne	a4,s0,ffffffffc0203ebe <kfree+0x30>
				*last = bb->next; // 更新 last 的 next 指针
ffffffffc0203ece:	e29c                	sd	a5,0(a3)
    if (flag) {
ffffffffc0203ed0:	ee3d                	bnez	a2,ffffffffc0203f4e <kfree+0xc0>
    return pa2page(PADDR(kva));
ffffffffc0203ed2:	c02007b7          	lui	a5,0xc0200
				spin_unlock_irqrestore(&slob_lock, flags); // 解锁并恢复中断状态
				__slob_free_pages((unsigned long)block, bb->order); // 调用 __slob_free_pages 释放页面
ffffffffc0203ed6:	4098                	lw	a4,0(s1)
ffffffffc0203ed8:	08f46b63          	bltu	s0,a5,ffffffffc0203f6e <kfree+0xe0>
ffffffffc0203edc:	000af697          	auipc	a3,0xaf
ffffffffc0203ee0:	9b46b683          	ld	a3,-1612(a3) # ffffffffc02b2890 <va_pa_offset>
ffffffffc0203ee4:	8c15                	sub	s0,s0,a3
    if (PPN(pa) >= npage) {
ffffffffc0203ee6:	8031                	srli	s0,s0,0xc
ffffffffc0203ee8:	000af797          	auipc	a5,0xaf
ffffffffc0203eec:	9907b783          	ld	a5,-1648(a5) # ffffffffc02b2878 <npage>
ffffffffc0203ef0:	06f47363          	bgeu	s0,a5,ffffffffc0203f56 <kfree+0xc8>
    return &pages[PPN(pa) - nbase];
ffffffffc0203ef4:	00005517          	auipc	a0,0x5
ffffffffc0203ef8:	f7c53503          	ld	a0,-132(a0) # ffffffffc0208e70 <nbase>
ffffffffc0203efc:	8c09                	sub	s0,s0,a0
ffffffffc0203efe:	041a                	slli	s0,s0,0x6
  free_pages(kva2page(kva), 1 << order); // 释放页面
ffffffffc0203f00:	000af517          	auipc	a0,0xaf
ffffffffc0203f04:	98053503          	ld	a0,-1664(a0) # ffffffffc02b2880 <pages>
ffffffffc0203f08:	4585                	li	a1,1
ffffffffc0203f0a:	9522                	add	a0,a0,s0
ffffffffc0203f0c:	00e595bb          	sllw	a1,a1,a4
ffffffffc0203f10:	d1afd0ef          	jal	ra,ffffffffc020142a <free_pages>
		spin_unlock_irqrestore(&block_lock, flags); // 解锁并恢复中断状态
	}

	slob_free((slob_t *)block - 1, 0); // 调用 slob_free 释放内存
	return; // 返回
}
ffffffffc0203f14:	6442                	ld	s0,16(sp)
ffffffffc0203f16:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t)); // 调用 slob_free 释放 bigblock_t 大小的内存
ffffffffc0203f18:	8526                	mv	a0,s1
}
ffffffffc0203f1a:	64a2                	ld	s1,8(sp)
				slob_free(bb, sizeof(bigblock_t)); // 调用 slob_free 释放 bigblock_t 大小的内存
ffffffffc0203f1c:	45e1                	li	a1,24
}
ffffffffc0203f1e:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0); // 调用 slob_free 释放内存
ffffffffc0203f20:	c8dff06f          	j	ffffffffc0203bac <slob_free>
ffffffffc0203f24:	e215                	bnez	a2,ffffffffc0203f48 <kfree+0xba>
ffffffffc0203f26:	ff040513          	addi	a0,s0,-16
}
ffffffffc0203f2a:	6442                	ld	s0,16(sp)
ffffffffc0203f2c:	60e2                	ld	ra,24(sp)
ffffffffc0203f2e:	64a2                	ld	s1,8(sp)
	slob_free((slob_t *)block - 1, 0); // 调用 slob_free 释放内存
ffffffffc0203f30:	4581                	li	a1,0
}
ffffffffc0203f32:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0); // 调用 slob_free 释放内存
ffffffffc0203f34:	c79ff06f          	j	ffffffffc0203bac <slob_free>
        intr_disable();
ffffffffc0203f38:	f10fc0ef          	jal	ra,ffffffffc0200648 <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) { // 遍历 bigblocks 链表
ffffffffc0203f3c:	000af797          	auipc	a5,0xaf
ffffffffc0203f40:	9847b783          	ld	a5,-1660(a5) # ffffffffc02b28c0 <bigblocks>
        return 1;
ffffffffc0203f44:	4605                	li	a2,1
ffffffffc0203f46:	f7bd                	bnez	a5,ffffffffc0203eb4 <kfree+0x26>
        intr_enable();
ffffffffc0203f48:	efafc0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc0203f4c:	bfe9                	j	ffffffffc0203f26 <kfree+0x98>
ffffffffc0203f4e:	ef4fc0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc0203f52:	b741                	j	ffffffffc0203ed2 <kfree+0x44>
ffffffffc0203f54:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0203f56:	00003617          	auipc	a2,0x3
ffffffffc0203f5a:	22260613          	addi	a2,a2,546 # ffffffffc0207178 <commands+0x758>
ffffffffc0203f5e:	06200593          	li	a1,98
ffffffffc0203f62:	00003517          	auipc	a0,0x3
ffffffffc0203f66:	23650513          	addi	a0,a0,566 # ffffffffc0207198 <commands+0x778>
ffffffffc0203f6a:	a9efc0ef          	jal	ra,ffffffffc0200208 <__panic>
    return pa2page(PADDR(kva));
ffffffffc0203f6e:	86a2                	mv	a3,s0
ffffffffc0203f70:	00003617          	auipc	a2,0x3
ffffffffc0203f74:	2c860613          	addi	a2,a2,712 # ffffffffc0207238 <commands+0x818>
ffffffffc0203f78:	06e00593          	li	a1,110
ffffffffc0203f7c:	00003517          	auipc	a0,0x3
ffffffffc0203f80:	21c50513          	addi	a0,a0,540 # ffffffffc0207198 <commands+0x778>
ffffffffc0203f84:	a84fc0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0203f88 <_fifo_init_mm>:
    elm->prev = elm->next = elm;
ffffffffc0203f88:	000ab797          	auipc	a5,0xab
ffffffffc0203f8c:	89078793          	addi	a5,a5,-1904 # ffffffffc02ae818 <pra_list_head>
// 初始化FIFO页面置换算法，设置mm->sm_priv指向pra_list_head
static int
_fifo_init_mm(struct mm_struct *mm)
{     
    list_init(&pra_list_head); // 初始化pra_list_head
    mm->sm_priv = &pra_list_head; // 设置mm->sm_priv指向pra_list_head
ffffffffc0203f90:	f51c                	sd	a5,40(a0)
ffffffffc0203f92:	e79c                	sd	a5,8(a5)
ffffffffc0203f94:	e39c                	sd	a5,0(a5)
    //cprintf(" mm->sm_priv %x in fifo_init_mm\n",mm->sm_priv);
    return 0;
}
ffffffffc0203f96:	4501                	li	a0,0
ffffffffc0203f98:	8082                	ret

ffffffffc0203f9a <_fifo_init>:
// 初始化FIFO页面置换算法
static int
_fifo_init(void)
{
    return 0;
}
ffffffffc0203f9a:	4501                	li	a0,0
ffffffffc0203f9c:	8082                	ret

ffffffffc0203f9e <_fifo_set_unswappable>:
// 设置页面为不可交换的
static int
_fifo_set_unswappable(struct mm_struct *mm, uintptr_t addr)
{
    return 0;
}
ffffffffc0203f9e:	4501                	li	a0,0
ffffffffc0203fa0:	8082                	ret

ffffffffc0203fa2 <_fifo_tick_event>:

// 处理时钟事件
static int
_fifo_tick_event(struct mm_struct *mm)
{ return 0; }
ffffffffc0203fa2:	4501                	li	a0,0
ffffffffc0203fa4:	8082                	ret

ffffffffc0203fa6 <_fifo_check_swap>:
_fifo_check_swap(void) {
ffffffffc0203fa6:	711d                	addi	sp,sp,-96
ffffffffc0203fa8:	fc4e                	sd	s3,56(sp)
ffffffffc0203faa:	f852                	sd	s4,48(sp)
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc0203fac:	00004517          	auipc	a0,0x4
ffffffffc0203fb0:	00c50513          	addi	a0,a0,12 # ffffffffc0207fb8 <commands+0x1598>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc0203fb4:	698d                	lui	s3,0x3
ffffffffc0203fb6:	4a31                	li	s4,12
_fifo_check_swap(void) {
ffffffffc0203fb8:	e0ca                	sd	s2,64(sp)
ffffffffc0203fba:	ec86                	sd	ra,88(sp)
ffffffffc0203fbc:	e8a2                	sd	s0,80(sp)
ffffffffc0203fbe:	e4a6                	sd	s1,72(sp)
ffffffffc0203fc0:	f456                	sd	s5,40(sp)
ffffffffc0203fc2:	f05a                	sd	s6,32(sp)
ffffffffc0203fc4:	ec5e                	sd	s7,24(sp)
ffffffffc0203fc6:	e862                	sd	s8,16(sp)
ffffffffc0203fc8:	e466                	sd	s9,8(sp)
ffffffffc0203fca:	e06a                	sd	s10,0(sp)
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc0203fcc:	900fc0ef          	jal	ra,ffffffffc02000cc <cprintf>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc0203fd0:	01498023          	sb	s4,0(s3) # 3000 <_binary_obj___user_faultread_out_size-0x6bb8>
    assert(pgfault_num==4);
ffffffffc0203fd4:	000af917          	auipc	s2,0xaf
ffffffffc0203fd8:	8cc92903          	lw	s2,-1844(s2) # ffffffffc02b28a0 <pgfault_num>
ffffffffc0203fdc:	4791                	li	a5,4
ffffffffc0203fde:	14f91e63          	bne	s2,a5,ffffffffc020413a <_fifo_check_swap+0x194>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0203fe2:	00004517          	auipc	a0,0x4
ffffffffc0203fe6:	01650513          	addi	a0,a0,22 # ffffffffc0207ff8 <commands+0x15d8>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc0203fea:	6a85                	lui	s5,0x1
ffffffffc0203fec:	4b29                	li	s6,10
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0203fee:	8defc0ef          	jal	ra,ffffffffc02000cc <cprintf>
ffffffffc0203ff2:	000af417          	auipc	s0,0xaf
ffffffffc0203ff6:	8ae40413          	addi	s0,s0,-1874 # ffffffffc02b28a0 <pgfault_num>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc0203ffa:	016a8023          	sb	s6,0(s5) # 1000 <_binary_obj___user_faultread_out_size-0x8bb8>
    assert(pgfault_num==4);
ffffffffc0203ffe:	4004                	lw	s1,0(s0)
ffffffffc0204000:	2481                	sext.w	s1,s1
ffffffffc0204002:	2b249c63          	bne	s1,s2,ffffffffc02042ba <_fifo_check_swap+0x314>
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc0204006:	00004517          	auipc	a0,0x4
ffffffffc020400a:	01a50513          	addi	a0,a0,26 # ffffffffc0208020 <commands+0x1600>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc020400e:	6b91                	lui	s7,0x4
ffffffffc0204010:	4c35                	li	s8,13
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc0204012:	8bafc0ef          	jal	ra,ffffffffc02000cc <cprintf>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc0204016:	018b8023          	sb	s8,0(s7) # 4000 <_binary_obj___user_faultread_out_size-0x5bb8>
    assert(pgfault_num==4);
ffffffffc020401a:	00042903          	lw	s2,0(s0)
ffffffffc020401e:	2901                	sext.w	s2,s2
ffffffffc0204020:	26991d63          	bne	s2,s1,ffffffffc020429a <_fifo_check_swap+0x2f4>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc0204024:	00004517          	auipc	a0,0x4
ffffffffc0204028:	02450513          	addi	a0,a0,36 # ffffffffc0208048 <commands+0x1628>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc020402c:	6c89                	lui	s9,0x2
ffffffffc020402e:	4d2d                	li	s10,11
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc0204030:	89cfc0ef          	jal	ra,ffffffffc02000cc <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0204034:	01ac8023          	sb	s10,0(s9) # 2000 <_binary_obj___user_faultread_out_size-0x7bb8>
    assert(pgfault_num==4);
ffffffffc0204038:	401c                	lw	a5,0(s0)
ffffffffc020403a:	2781                	sext.w	a5,a5
ffffffffc020403c:	23279f63          	bne	a5,s2,ffffffffc020427a <_fifo_check_swap+0x2d4>
    cprintf("write Virt Page e in fifo_check_swap\n");
ffffffffc0204040:	00004517          	auipc	a0,0x4
ffffffffc0204044:	03050513          	addi	a0,a0,48 # ffffffffc0208070 <commands+0x1650>
ffffffffc0204048:	884fc0ef          	jal	ra,ffffffffc02000cc <cprintf>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc020404c:	6795                	lui	a5,0x5
ffffffffc020404e:	4739                	li	a4,14
ffffffffc0204050:	00e78023          	sb	a4,0(a5) # 5000 <_binary_obj___user_faultread_out_size-0x4bb8>
    assert(pgfault_num==5);
ffffffffc0204054:	4004                	lw	s1,0(s0)
ffffffffc0204056:	4795                	li	a5,5
ffffffffc0204058:	2481                	sext.w	s1,s1
ffffffffc020405a:	20f49063          	bne	s1,a5,ffffffffc020425a <_fifo_check_swap+0x2b4>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc020405e:	00004517          	auipc	a0,0x4
ffffffffc0204062:	fea50513          	addi	a0,a0,-22 # ffffffffc0208048 <commands+0x1628>
ffffffffc0204066:	866fc0ef          	jal	ra,ffffffffc02000cc <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc020406a:	01ac8023          	sb	s10,0(s9)
    assert(pgfault_num==5);
ffffffffc020406e:	401c                	lw	a5,0(s0)
ffffffffc0204070:	2781                	sext.w	a5,a5
ffffffffc0204072:	1c979463          	bne	a5,s1,ffffffffc020423a <_fifo_check_swap+0x294>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0204076:	00004517          	auipc	a0,0x4
ffffffffc020407a:	f8250513          	addi	a0,a0,-126 # ffffffffc0207ff8 <commands+0x15d8>
ffffffffc020407e:	84efc0ef          	jal	ra,ffffffffc02000cc <cprintf>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc0204082:	016a8023          	sb	s6,0(s5)
    assert(pgfault_num==6);
ffffffffc0204086:	401c                	lw	a5,0(s0)
ffffffffc0204088:	4719                	li	a4,6
ffffffffc020408a:	2781                	sext.w	a5,a5
ffffffffc020408c:	18e79763          	bne	a5,a4,ffffffffc020421a <_fifo_check_swap+0x274>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc0204090:	00004517          	auipc	a0,0x4
ffffffffc0204094:	fb850513          	addi	a0,a0,-72 # ffffffffc0208048 <commands+0x1628>
ffffffffc0204098:	834fc0ef          	jal	ra,ffffffffc02000cc <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc020409c:	01ac8023          	sb	s10,0(s9)
    assert(pgfault_num==7);
ffffffffc02040a0:	401c                	lw	a5,0(s0)
ffffffffc02040a2:	471d                	li	a4,7
ffffffffc02040a4:	2781                	sext.w	a5,a5
ffffffffc02040a6:	14e79a63          	bne	a5,a4,ffffffffc02041fa <_fifo_check_swap+0x254>
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc02040aa:	00004517          	auipc	a0,0x4
ffffffffc02040ae:	f0e50513          	addi	a0,a0,-242 # ffffffffc0207fb8 <commands+0x1598>
ffffffffc02040b2:	81afc0ef          	jal	ra,ffffffffc02000cc <cprintf>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc02040b6:	01498023          	sb	s4,0(s3)
    assert(pgfault_num==8);
ffffffffc02040ba:	401c                	lw	a5,0(s0)
ffffffffc02040bc:	4721                	li	a4,8
ffffffffc02040be:	2781                	sext.w	a5,a5
ffffffffc02040c0:	10e79d63          	bne	a5,a4,ffffffffc02041da <_fifo_check_swap+0x234>
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc02040c4:	00004517          	auipc	a0,0x4
ffffffffc02040c8:	f5c50513          	addi	a0,a0,-164 # ffffffffc0208020 <commands+0x1600>
ffffffffc02040cc:	800fc0ef          	jal	ra,ffffffffc02000cc <cprintf>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc02040d0:	018b8023          	sb	s8,0(s7)
    assert(pgfault_num==9);
ffffffffc02040d4:	401c                	lw	a5,0(s0)
ffffffffc02040d6:	4725                	li	a4,9
ffffffffc02040d8:	2781                	sext.w	a5,a5
ffffffffc02040da:	0ee79063          	bne	a5,a4,ffffffffc02041ba <_fifo_check_swap+0x214>
    cprintf("write Virt Page e in fifo_check_swap\n");
ffffffffc02040de:	00004517          	auipc	a0,0x4
ffffffffc02040e2:	f9250513          	addi	a0,a0,-110 # ffffffffc0208070 <commands+0x1650>
ffffffffc02040e6:	fe7fb0ef          	jal	ra,ffffffffc02000cc <cprintf>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc02040ea:	6795                	lui	a5,0x5
ffffffffc02040ec:	4739                	li	a4,14
ffffffffc02040ee:	00e78023          	sb	a4,0(a5) # 5000 <_binary_obj___user_faultread_out_size-0x4bb8>
    assert(pgfault_num==10);
ffffffffc02040f2:	4004                	lw	s1,0(s0)
ffffffffc02040f4:	47a9                	li	a5,10
ffffffffc02040f6:	2481                	sext.w	s1,s1
ffffffffc02040f8:	0af49163          	bne	s1,a5,ffffffffc020419a <_fifo_check_swap+0x1f4>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc02040fc:	00004517          	auipc	a0,0x4
ffffffffc0204100:	efc50513          	addi	a0,a0,-260 # ffffffffc0207ff8 <commands+0x15d8>
ffffffffc0204104:	fc9fb0ef          	jal	ra,ffffffffc02000cc <cprintf>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc0204108:	6785                	lui	a5,0x1
ffffffffc020410a:	0007c783          	lbu	a5,0(a5) # 1000 <_binary_obj___user_faultread_out_size-0x8bb8>
ffffffffc020410e:	06979663          	bne	a5,s1,ffffffffc020417a <_fifo_check_swap+0x1d4>
    assert(pgfault_num==11);
ffffffffc0204112:	401c                	lw	a5,0(s0)
ffffffffc0204114:	472d                	li	a4,11
ffffffffc0204116:	2781                	sext.w	a5,a5
ffffffffc0204118:	04e79163          	bne	a5,a4,ffffffffc020415a <_fifo_check_swap+0x1b4>
}
ffffffffc020411c:	60e6                	ld	ra,88(sp)
ffffffffc020411e:	6446                	ld	s0,80(sp)
ffffffffc0204120:	64a6                	ld	s1,72(sp)
ffffffffc0204122:	6906                	ld	s2,64(sp)
ffffffffc0204124:	79e2                	ld	s3,56(sp)
ffffffffc0204126:	7a42                	ld	s4,48(sp)
ffffffffc0204128:	7aa2                	ld	s5,40(sp)
ffffffffc020412a:	7b02                	ld	s6,32(sp)
ffffffffc020412c:	6be2                	ld	s7,24(sp)
ffffffffc020412e:	6c42                	ld	s8,16(sp)
ffffffffc0204130:	6ca2                	ld	s9,8(sp)
ffffffffc0204132:	6d02                	ld	s10,0(sp)
ffffffffc0204134:	4501                	li	a0,0
ffffffffc0204136:	6125                	addi	sp,sp,96
ffffffffc0204138:	8082                	ret
    assert(pgfault_num==4);
ffffffffc020413a:	00004697          	auipc	a3,0x4
ffffffffc020413e:	c4e68693          	addi	a3,a3,-946 # ffffffffc0207d88 <commands+0x1368>
ffffffffc0204142:	00003617          	auipc	a2,0x3
ffffffffc0204146:	cee60613          	addi	a2,a2,-786 # ffffffffc0206e30 <commands+0x410>
ffffffffc020414a:	03b00593          	li	a1,59
ffffffffc020414e:	00004517          	auipc	a0,0x4
ffffffffc0204152:	e9250513          	addi	a0,a0,-366 # ffffffffc0207fe0 <commands+0x15c0>
ffffffffc0204156:	8b2fc0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(pgfault_num==11);
ffffffffc020415a:	00004697          	auipc	a3,0x4
ffffffffc020415e:	fc668693          	addi	a3,a3,-58 # ffffffffc0208120 <commands+0x1700>
ffffffffc0204162:	00003617          	auipc	a2,0x3
ffffffffc0204166:	cce60613          	addi	a2,a2,-818 # ffffffffc0206e30 <commands+0x410>
ffffffffc020416a:	05d00593          	li	a1,93
ffffffffc020416e:	00004517          	auipc	a0,0x4
ffffffffc0204172:	e7250513          	addi	a0,a0,-398 # ffffffffc0207fe0 <commands+0x15c0>
ffffffffc0204176:	892fc0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc020417a:	00004697          	auipc	a3,0x4
ffffffffc020417e:	f7e68693          	addi	a3,a3,-130 # ffffffffc02080f8 <commands+0x16d8>
ffffffffc0204182:	00003617          	auipc	a2,0x3
ffffffffc0204186:	cae60613          	addi	a2,a2,-850 # ffffffffc0206e30 <commands+0x410>
ffffffffc020418a:	05b00593          	li	a1,91
ffffffffc020418e:	00004517          	auipc	a0,0x4
ffffffffc0204192:	e5250513          	addi	a0,a0,-430 # ffffffffc0207fe0 <commands+0x15c0>
ffffffffc0204196:	872fc0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(pgfault_num==10);
ffffffffc020419a:	00004697          	auipc	a3,0x4
ffffffffc020419e:	f4e68693          	addi	a3,a3,-178 # ffffffffc02080e8 <commands+0x16c8>
ffffffffc02041a2:	00003617          	auipc	a2,0x3
ffffffffc02041a6:	c8e60613          	addi	a2,a2,-882 # ffffffffc0206e30 <commands+0x410>
ffffffffc02041aa:	05900593          	li	a1,89
ffffffffc02041ae:	00004517          	auipc	a0,0x4
ffffffffc02041b2:	e3250513          	addi	a0,a0,-462 # ffffffffc0207fe0 <commands+0x15c0>
ffffffffc02041b6:	852fc0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(pgfault_num==9);
ffffffffc02041ba:	00004697          	auipc	a3,0x4
ffffffffc02041be:	f1e68693          	addi	a3,a3,-226 # ffffffffc02080d8 <commands+0x16b8>
ffffffffc02041c2:	00003617          	auipc	a2,0x3
ffffffffc02041c6:	c6e60613          	addi	a2,a2,-914 # ffffffffc0206e30 <commands+0x410>
ffffffffc02041ca:	05600593          	li	a1,86
ffffffffc02041ce:	00004517          	auipc	a0,0x4
ffffffffc02041d2:	e1250513          	addi	a0,a0,-494 # ffffffffc0207fe0 <commands+0x15c0>
ffffffffc02041d6:	832fc0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(pgfault_num==8);
ffffffffc02041da:	00004697          	auipc	a3,0x4
ffffffffc02041de:	eee68693          	addi	a3,a3,-274 # ffffffffc02080c8 <commands+0x16a8>
ffffffffc02041e2:	00003617          	auipc	a2,0x3
ffffffffc02041e6:	c4e60613          	addi	a2,a2,-946 # ffffffffc0206e30 <commands+0x410>
ffffffffc02041ea:	05300593          	li	a1,83
ffffffffc02041ee:	00004517          	auipc	a0,0x4
ffffffffc02041f2:	df250513          	addi	a0,a0,-526 # ffffffffc0207fe0 <commands+0x15c0>
ffffffffc02041f6:	812fc0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(pgfault_num==7);
ffffffffc02041fa:	00004697          	auipc	a3,0x4
ffffffffc02041fe:	ebe68693          	addi	a3,a3,-322 # ffffffffc02080b8 <commands+0x1698>
ffffffffc0204202:	00003617          	auipc	a2,0x3
ffffffffc0204206:	c2e60613          	addi	a2,a2,-978 # ffffffffc0206e30 <commands+0x410>
ffffffffc020420a:	05000593          	li	a1,80
ffffffffc020420e:	00004517          	auipc	a0,0x4
ffffffffc0204212:	dd250513          	addi	a0,a0,-558 # ffffffffc0207fe0 <commands+0x15c0>
ffffffffc0204216:	ff3fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(pgfault_num==6);
ffffffffc020421a:	00004697          	auipc	a3,0x4
ffffffffc020421e:	e8e68693          	addi	a3,a3,-370 # ffffffffc02080a8 <commands+0x1688>
ffffffffc0204222:	00003617          	auipc	a2,0x3
ffffffffc0204226:	c0e60613          	addi	a2,a2,-1010 # ffffffffc0206e30 <commands+0x410>
ffffffffc020422a:	04d00593          	li	a1,77
ffffffffc020422e:	00004517          	auipc	a0,0x4
ffffffffc0204232:	db250513          	addi	a0,a0,-590 # ffffffffc0207fe0 <commands+0x15c0>
ffffffffc0204236:	fd3fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(pgfault_num==5);
ffffffffc020423a:	00004697          	auipc	a3,0x4
ffffffffc020423e:	e5e68693          	addi	a3,a3,-418 # ffffffffc0208098 <commands+0x1678>
ffffffffc0204242:	00003617          	auipc	a2,0x3
ffffffffc0204246:	bee60613          	addi	a2,a2,-1042 # ffffffffc0206e30 <commands+0x410>
ffffffffc020424a:	04a00593          	li	a1,74
ffffffffc020424e:	00004517          	auipc	a0,0x4
ffffffffc0204252:	d9250513          	addi	a0,a0,-622 # ffffffffc0207fe0 <commands+0x15c0>
ffffffffc0204256:	fb3fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(pgfault_num==5);
ffffffffc020425a:	00004697          	auipc	a3,0x4
ffffffffc020425e:	e3e68693          	addi	a3,a3,-450 # ffffffffc0208098 <commands+0x1678>
ffffffffc0204262:	00003617          	auipc	a2,0x3
ffffffffc0204266:	bce60613          	addi	a2,a2,-1074 # ffffffffc0206e30 <commands+0x410>
ffffffffc020426a:	04700593          	li	a1,71
ffffffffc020426e:	00004517          	auipc	a0,0x4
ffffffffc0204272:	d7250513          	addi	a0,a0,-654 # ffffffffc0207fe0 <commands+0x15c0>
ffffffffc0204276:	f93fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(pgfault_num==4);
ffffffffc020427a:	00004697          	auipc	a3,0x4
ffffffffc020427e:	b0e68693          	addi	a3,a3,-1266 # ffffffffc0207d88 <commands+0x1368>
ffffffffc0204282:	00003617          	auipc	a2,0x3
ffffffffc0204286:	bae60613          	addi	a2,a2,-1106 # ffffffffc0206e30 <commands+0x410>
ffffffffc020428a:	04400593          	li	a1,68
ffffffffc020428e:	00004517          	auipc	a0,0x4
ffffffffc0204292:	d5250513          	addi	a0,a0,-686 # ffffffffc0207fe0 <commands+0x15c0>
ffffffffc0204296:	f73fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(pgfault_num==4);
ffffffffc020429a:	00004697          	auipc	a3,0x4
ffffffffc020429e:	aee68693          	addi	a3,a3,-1298 # ffffffffc0207d88 <commands+0x1368>
ffffffffc02042a2:	00003617          	auipc	a2,0x3
ffffffffc02042a6:	b8e60613          	addi	a2,a2,-1138 # ffffffffc0206e30 <commands+0x410>
ffffffffc02042aa:	04100593          	li	a1,65
ffffffffc02042ae:	00004517          	auipc	a0,0x4
ffffffffc02042b2:	d3250513          	addi	a0,a0,-718 # ffffffffc0207fe0 <commands+0x15c0>
ffffffffc02042b6:	f53fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(pgfault_num==4);
ffffffffc02042ba:	00004697          	auipc	a3,0x4
ffffffffc02042be:	ace68693          	addi	a3,a3,-1330 # ffffffffc0207d88 <commands+0x1368>
ffffffffc02042c2:	00003617          	auipc	a2,0x3
ffffffffc02042c6:	b6e60613          	addi	a2,a2,-1170 # ffffffffc0206e30 <commands+0x410>
ffffffffc02042ca:	03e00593          	li	a1,62
ffffffffc02042ce:	00004517          	auipc	a0,0x4
ffffffffc02042d2:	d1250513          	addi	a0,a0,-750 # ffffffffc0207fe0 <commands+0x15c0>
ffffffffc02042d6:	f33fb0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc02042da <_fifo_swap_out_victim>:
    list_entry_t *head=(list_entry_t*) mm->sm_priv;
ffffffffc02042da:	751c                	ld	a5,40(a0)
{
ffffffffc02042dc:	1141                	addi	sp,sp,-16
ffffffffc02042de:	e406                	sd	ra,8(sp)
    assert(head != NULL);
ffffffffc02042e0:	cf91                	beqz	a5,ffffffffc02042fc <_fifo_swap_out_victim+0x22>
    assert(in_tick==0);
ffffffffc02042e2:	ee0d                	bnez	a2,ffffffffc020431c <_fifo_swap_out_victim+0x42>
    return listelm->next;
ffffffffc02042e4:	679c                	ld	a5,8(a5)
}
ffffffffc02042e6:	60a2                	ld	ra,8(sp)
ffffffffc02042e8:	4501                	li	a0,0
    __list_del(listelm->prev, listelm->next);
ffffffffc02042ea:	6394                	ld	a3,0(a5)
ffffffffc02042ec:	6798                	ld	a4,8(a5)
    *ptr_page = le2page(entry, pra_page_link); // 设置页面地址
ffffffffc02042ee:	fd878793          	addi	a5,a5,-40
    prev->next = next;
ffffffffc02042f2:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc02042f4:	e314                	sd	a3,0(a4)
ffffffffc02042f6:	e19c                	sd	a5,0(a1)
}
ffffffffc02042f8:	0141                	addi	sp,sp,16
ffffffffc02042fa:	8082                	ret
    assert(head != NULL);
ffffffffc02042fc:	00004697          	auipc	a3,0x4
ffffffffc0204300:	e3468693          	addi	a3,a3,-460 # ffffffffc0208130 <commands+0x1710>
ffffffffc0204304:	00003617          	auipc	a2,0x3
ffffffffc0204308:	b2c60613          	addi	a2,a2,-1236 # ffffffffc0206e30 <commands+0x410>
ffffffffc020430c:	02a00593          	li	a1,42
ffffffffc0204310:	00004517          	auipc	a0,0x4
ffffffffc0204314:	cd050513          	addi	a0,a0,-816 # ffffffffc0207fe0 <commands+0x15c0>
ffffffffc0204318:	ef1fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(in_tick==0);
ffffffffc020431c:	00004697          	auipc	a3,0x4
ffffffffc0204320:	e2468693          	addi	a3,a3,-476 # ffffffffc0208140 <commands+0x1720>
ffffffffc0204324:	00003617          	auipc	a2,0x3
ffffffffc0204328:	b0c60613          	addi	a2,a2,-1268 # ffffffffc0206e30 <commands+0x410>
ffffffffc020432c:	02b00593          	li	a1,43
ffffffffc0204330:	00004517          	auipc	a0,0x4
ffffffffc0204334:	cb050513          	addi	a0,a0,-848 # ffffffffc0207fe0 <commands+0x15c0>
ffffffffc0204338:	ed1fb0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc020433c <_fifo_map_swappable>:
    list_entry_t *head=(list_entry_t*) mm->sm_priv;
ffffffffc020433c:	751c                	ld	a5,40(a0)
    assert(entry != NULL && head != NULL);
ffffffffc020433e:	cb91                	beqz	a5,ffffffffc0204352 <_fifo_map_swappable+0x16>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0204340:	6394                	ld	a3,0(a5)
ffffffffc0204342:	02860713          	addi	a4,a2,40
    prev->next = next->prev = elm;
ffffffffc0204346:	e398                	sd	a4,0(a5)
ffffffffc0204348:	e698                	sd	a4,8(a3)
}
ffffffffc020434a:	4501                	li	a0,0
    elm->next = next;
ffffffffc020434c:	fa1c                	sd	a5,48(a2)
    elm->prev = prev;
ffffffffc020434e:	f614                	sd	a3,40(a2)
ffffffffc0204350:	8082                	ret
{
ffffffffc0204352:	1141                	addi	sp,sp,-16
    assert(entry != NULL && head != NULL);
ffffffffc0204354:	00004697          	auipc	a3,0x4
ffffffffc0204358:	dfc68693          	addi	a3,a3,-516 # ffffffffc0208150 <commands+0x1730>
ffffffffc020435c:	00003617          	auipc	a2,0x3
ffffffffc0204360:	ad460613          	addi	a2,a2,-1324 # ffffffffc0206e30 <commands+0x410>
ffffffffc0204364:	45f5                	li	a1,29
ffffffffc0204366:	00004517          	auipc	a0,0x4
ffffffffc020436a:	c7a50513          	addi	a0,a0,-902 # ffffffffc0207fe0 <commands+0x15c0>
{
ffffffffc020436e:	e406                	sd	ra,8(sp)
    assert(entry != NULL && head != NULL);
ffffffffc0204370:	e99fb0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0204374 <default_init>:
    elm->prev = elm->next = elm;
ffffffffc0204374:	000aa797          	auipc	a5,0xaa
ffffffffc0204378:	4b478793          	addi	a5,a5,1204 # ffffffffc02ae828 <free_area>
ffffffffc020437c:	e79c                	sd	a5,8(a5)
ffffffffc020437e:	e39c                	sd	a5,0(a5)

// 初始化 free_list 并将 nr_free 设置为 0
static void
default_init(void) {
     list_init(&free_list);
     nr_free = 0;
ffffffffc0204380:	0007a823          	sw	zero,16(a5)
}
ffffffffc0204384:	8082                	ret

ffffffffc0204386 <default_nr_free_pages>:

// 返回空闲页数
static size_t
default_nr_free_pages(void) {
     return nr_free;
}
ffffffffc0204386:	000aa517          	auipc	a0,0xaa
ffffffffc020438a:	4b256503          	lwu	a0,1202(a0) # ffffffffc02ae838 <free_area+0x10>
ffffffffc020438e:	8082                	ret

ffffffffc0204390 <default_check>:
}

// LAB2: 下面的代码用于检查首次适应分配算法（你的练习 1）
// 注意：你不应该更改 basic_check, default_check 函数！
static void
default_check(void) {
ffffffffc0204390:	715d                	addi	sp,sp,-80
ffffffffc0204392:	e0a2                	sd	s0,64(sp)
    return listelm->next;
ffffffffc0204394:	000aa417          	auipc	s0,0xaa
ffffffffc0204398:	49440413          	addi	s0,s0,1172 # ffffffffc02ae828 <free_area>
ffffffffc020439c:	641c                	ld	a5,8(s0)
ffffffffc020439e:	e486                	sd	ra,72(sp)
ffffffffc02043a0:	fc26                	sd	s1,56(sp)
ffffffffc02043a2:	f84a                	sd	s2,48(sp)
ffffffffc02043a4:	f44e                	sd	s3,40(sp)
ffffffffc02043a6:	f052                	sd	s4,32(sp)
ffffffffc02043a8:	ec56                	sd	s5,24(sp)
ffffffffc02043aa:	e85a                	sd	s6,16(sp)
ffffffffc02043ac:	e45e                	sd	s7,8(sp)
ffffffffc02043ae:	e062                	sd	s8,0(sp)
     int count = 0, total = 0;
     list_entry_t *le = &free_list;
     while ((le = list_next(le)) != &free_list) {
ffffffffc02043b0:	2a878d63          	beq	a5,s0,ffffffffc020466a <default_check+0x2da>
     int count = 0, total = 0;
ffffffffc02043b4:	4481                	li	s1,0
ffffffffc02043b6:	4901                	li	s2,0
ffffffffc02043b8:	ff07b703          	ld	a4,-16(a5)
          struct Page *p = le2page(le, page_link);
          assert(PageProperty(p));
ffffffffc02043bc:	8b09                	andi	a4,a4,2
ffffffffc02043be:	2a070a63          	beqz	a4,ffffffffc0204672 <default_check+0x2e2>
          count ++, total += p->property;
ffffffffc02043c2:	ff87a703          	lw	a4,-8(a5)
ffffffffc02043c6:	679c                	ld	a5,8(a5)
ffffffffc02043c8:	2905                	addiw	s2,s2,1
ffffffffc02043ca:	9cb9                	addw	s1,s1,a4
     while ((le = list_next(le)) != &free_list) {
ffffffffc02043cc:	fe8796e3          	bne	a5,s0,ffffffffc02043b8 <default_check+0x28>
     }
     assert(total == nr_free_pages());
ffffffffc02043d0:	89a6                	mv	s3,s1
ffffffffc02043d2:	898fd0ef          	jal	ra,ffffffffc020146a <nr_free_pages>
ffffffffc02043d6:	6f351e63          	bne	a0,s3,ffffffffc0204ad2 <default_check+0x742>
     assert((p0 = alloc_page()) != NULL);
ffffffffc02043da:	4505                	li	a0,1
ffffffffc02043dc:	fbdfc0ef          	jal	ra,ffffffffc0201398 <alloc_pages>
ffffffffc02043e0:	8aaa                	mv	s5,a0
ffffffffc02043e2:	42050863          	beqz	a0,ffffffffc0204812 <default_check+0x482>
     assert((p1 = alloc_page()) != NULL);
ffffffffc02043e6:	4505                	li	a0,1
ffffffffc02043e8:	fb1fc0ef          	jal	ra,ffffffffc0201398 <alloc_pages>
ffffffffc02043ec:	89aa                	mv	s3,a0
ffffffffc02043ee:	70050263          	beqz	a0,ffffffffc0204af2 <default_check+0x762>
     assert((p2 = alloc_page()) != NULL);
ffffffffc02043f2:	4505                	li	a0,1
ffffffffc02043f4:	fa5fc0ef          	jal	ra,ffffffffc0201398 <alloc_pages>
ffffffffc02043f8:	8a2a                	mv	s4,a0
ffffffffc02043fa:	48050c63          	beqz	a0,ffffffffc0204892 <default_check+0x502>
     assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02043fe:	293a8a63          	beq	s5,s3,ffffffffc0204692 <default_check+0x302>
ffffffffc0204402:	28aa8863          	beq	s5,a0,ffffffffc0204692 <default_check+0x302>
ffffffffc0204406:	28a98663          	beq	s3,a0,ffffffffc0204692 <default_check+0x302>
     assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc020440a:	000aa783          	lw	a5,0(s5)
ffffffffc020440e:	2a079263          	bnez	a5,ffffffffc02046b2 <default_check+0x322>
ffffffffc0204412:	0009a783          	lw	a5,0(s3)
ffffffffc0204416:	28079e63          	bnez	a5,ffffffffc02046b2 <default_check+0x322>
ffffffffc020441a:	411c                	lw	a5,0(a0)
ffffffffc020441c:	28079b63          	bnez	a5,ffffffffc02046b2 <default_check+0x322>
    return page - pages + nbase;
ffffffffc0204420:	000ae797          	auipc	a5,0xae
ffffffffc0204424:	4607b783          	ld	a5,1120(a5) # ffffffffc02b2880 <pages>
ffffffffc0204428:	40fa8733          	sub	a4,s5,a5
ffffffffc020442c:	00005617          	auipc	a2,0x5
ffffffffc0204430:	a4463603          	ld	a2,-1468(a2) # ffffffffc0208e70 <nbase>
ffffffffc0204434:	8719                	srai	a4,a4,0x6
ffffffffc0204436:	9732                	add	a4,a4,a2
     assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0204438:	000ae697          	auipc	a3,0xae
ffffffffc020443c:	4406b683          	ld	a3,1088(a3) # ffffffffc02b2878 <npage>
ffffffffc0204440:	06b2                	slli	a3,a3,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0204442:	0732                	slli	a4,a4,0xc
ffffffffc0204444:	28d77763          	bgeu	a4,a3,ffffffffc02046d2 <default_check+0x342>
    return page - pages + nbase;
ffffffffc0204448:	40f98733          	sub	a4,s3,a5
ffffffffc020444c:	8719                	srai	a4,a4,0x6
ffffffffc020444e:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0204450:	0732                	slli	a4,a4,0xc
     assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0204452:	4cd77063          	bgeu	a4,a3,ffffffffc0204912 <default_check+0x582>
    return page - pages + nbase;
ffffffffc0204456:	40f507b3          	sub	a5,a0,a5
ffffffffc020445a:	8799                	srai	a5,a5,0x6
ffffffffc020445c:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc020445e:	07b2                	slli	a5,a5,0xc
     assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0204460:	30d7f963          	bgeu	a5,a3,ffffffffc0204772 <default_check+0x3e2>
     assert(alloc_page() == NULL);
ffffffffc0204464:	4505                	li	a0,1
     list_entry_t free_list_store = free_list;
ffffffffc0204466:	00043c03          	ld	s8,0(s0)
ffffffffc020446a:	00843b83          	ld	s7,8(s0)
     unsigned int nr_free_store = nr_free;
ffffffffc020446e:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0204472:	e400                	sd	s0,8(s0)
ffffffffc0204474:	e000                	sd	s0,0(s0)
     nr_free = 0;
ffffffffc0204476:	000aa797          	auipc	a5,0xaa
ffffffffc020447a:	3c07a123          	sw	zero,962(a5) # ffffffffc02ae838 <free_area+0x10>
     assert(alloc_page() == NULL);
ffffffffc020447e:	f1bfc0ef          	jal	ra,ffffffffc0201398 <alloc_pages>
ffffffffc0204482:	2c051863          	bnez	a0,ffffffffc0204752 <default_check+0x3c2>
     free_page(p0);
ffffffffc0204486:	4585                	li	a1,1
ffffffffc0204488:	8556                	mv	a0,s5
ffffffffc020448a:	fa1fc0ef          	jal	ra,ffffffffc020142a <free_pages>
     free_page(p1);
ffffffffc020448e:	4585                	li	a1,1
ffffffffc0204490:	854e                	mv	a0,s3
ffffffffc0204492:	f99fc0ef          	jal	ra,ffffffffc020142a <free_pages>
     free_page(p2);
ffffffffc0204496:	4585                	li	a1,1
ffffffffc0204498:	8552                	mv	a0,s4
ffffffffc020449a:	f91fc0ef          	jal	ra,ffffffffc020142a <free_pages>
     assert(nr_free == 3);
ffffffffc020449e:	4818                	lw	a4,16(s0)
ffffffffc02044a0:	478d                	li	a5,3
ffffffffc02044a2:	28f71863          	bne	a4,a5,ffffffffc0204732 <default_check+0x3a2>
     assert((p0 = alloc_page()) != NULL);
ffffffffc02044a6:	4505                	li	a0,1
ffffffffc02044a8:	ef1fc0ef          	jal	ra,ffffffffc0201398 <alloc_pages>
ffffffffc02044ac:	89aa                	mv	s3,a0
ffffffffc02044ae:	26050263          	beqz	a0,ffffffffc0204712 <default_check+0x382>
     assert((p1 = alloc_page()) != NULL);
ffffffffc02044b2:	4505                	li	a0,1
ffffffffc02044b4:	ee5fc0ef          	jal	ra,ffffffffc0201398 <alloc_pages>
ffffffffc02044b8:	8aaa                	mv	s5,a0
ffffffffc02044ba:	3a050c63          	beqz	a0,ffffffffc0204872 <default_check+0x4e2>
     assert((p2 = alloc_page()) != NULL);
ffffffffc02044be:	4505                	li	a0,1
ffffffffc02044c0:	ed9fc0ef          	jal	ra,ffffffffc0201398 <alloc_pages>
ffffffffc02044c4:	8a2a                	mv	s4,a0
ffffffffc02044c6:	38050663          	beqz	a0,ffffffffc0204852 <default_check+0x4c2>
     assert(alloc_page() == NULL);
ffffffffc02044ca:	4505                	li	a0,1
ffffffffc02044cc:	ecdfc0ef          	jal	ra,ffffffffc0201398 <alloc_pages>
ffffffffc02044d0:	36051163          	bnez	a0,ffffffffc0204832 <default_check+0x4a2>
     free_page(p0);
ffffffffc02044d4:	4585                	li	a1,1
ffffffffc02044d6:	854e                	mv	a0,s3
ffffffffc02044d8:	f53fc0ef          	jal	ra,ffffffffc020142a <free_pages>
     assert(!list_empty(&free_list));
ffffffffc02044dc:	641c                	ld	a5,8(s0)
ffffffffc02044de:	20878a63          	beq	a5,s0,ffffffffc02046f2 <default_check+0x362>
     assert((p = alloc_page()) == p0);
ffffffffc02044e2:	4505                	li	a0,1
ffffffffc02044e4:	eb5fc0ef          	jal	ra,ffffffffc0201398 <alloc_pages>
ffffffffc02044e8:	30a99563          	bne	s3,a0,ffffffffc02047f2 <default_check+0x462>
     assert(alloc_page() == NULL);
ffffffffc02044ec:	4505                	li	a0,1
ffffffffc02044ee:	eabfc0ef          	jal	ra,ffffffffc0201398 <alloc_pages>
ffffffffc02044f2:	2e051063          	bnez	a0,ffffffffc02047d2 <default_check+0x442>
     assert(nr_free == 0);
ffffffffc02044f6:	481c                	lw	a5,16(s0)
ffffffffc02044f8:	2a079d63          	bnez	a5,ffffffffc02047b2 <default_check+0x422>
     free_page(p);
ffffffffc02044fc:	854e                	mv	a0,s3
ffffffffc02044fe:	4585                	li	a1,1
     free_list = free_list_store;
ffffffffc0204500:	01843023          	sd	s8,0(s0)
ffffffffc0204504:	01743423          	sd	s7,8(s0)
     nr_free = nr_free_store;
ffffffffc0204508:	01642823          	sw	s6,16(s0)
     free_page(p);
ffffffffc020450c:	f1ffc0ef          	jal	ra,ffffffffc020142a <free_pages>
     free_page(p1);
ffffffffc0204510:	4585                	li	a1,1
ffffffffc0204512:	8556                	mv	a0,s5
ffffffffc0204514:	f17fc0ef          	jal	ra,ffffffffc020142a <free_pages>
     free_page(p2);
ffffffffc0204518:	4585                	li	a1,1
ffffffffc020451a:	8552                	mv	a0,s4
ffffffffc020451c:	f0ffc0ef          	jal	ra,ffffffffc020142a <free_pages>

     basic_check();

     struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0204520:	4515                	li	a0,5
ffffffffc0204522:	e77fc0ef          	jal	ra,ffffffffc0201398 <alloc_pages>
ffffffffc0204526:	89aa                	mv	s3,a0
     assert(p0 != NULL);
ffffffffc0204528:	26050563          	beqz	a0,ffffffffc0204792 <default_check+0x402>
ffffffffc020452c:	651c                	ld	a5,8(a0)
ffffffffc020452e:	8385                	srli	a5,a5,0x1
ffffffffc0204530:	8b85                	andi	a5,a5,1
     assert(!PageProperty(p0));
ffffffffc0204532:	54079063          	bnez	a5,ffffffffc0204a72 <default_check+0x6e2>

     list_entry_t free_list_store = free_list;
     list_init(&free_list);
     assert(list_empty(&free_list));
     assert(alloc_page() == NULL);
ffffffffc0204536:	4505                	li	a0,1
     list_entry_t free_list_store = free_list;
ffffffffc0204538:	00043b03          	ld	s6,0(s0)
ffffffffc020453c:	00843a83          	ld	s5,8(s0)
ffffffffc0204540:	e000                	sd	s0,0(s0)
ffffffffc0204542:	e400                	sd	s0,8(s0)
     assert(alloc_page() == NULL);
ffffffffc0204544:	e55fc0ef          	jal	ra,ffffffffc0201398 <alloc_pages>
ffffffffc0204548:	50051563          	bnez	a0,ffffffffc0204a52 <default_check+0x6c2>

     unsigned int nr_free_store = nr_free;
     nr_free = 0;

     free_pages(p0 + 2, 3);
ffffffffc020454c:	08098a13          	addi	s4,s3,128
ffffffffc0204550:	8552                	mv	a0,s4
ffffffffc0204552:	458d                	li	a1,3
     unsigned int nr_free_store = nr_free;
ffffffffc0204554:	01042b83          	lw	s7,16(s0)
     nr_free = 0;
ffffffffc0204558:	000aa797          	auipc	a5,0xaa
ffffffffc020455c:	2e07a023          	sw	zero,736(a5) # ffffffffc02ae838 <free_area+0x10>
     free_pages(p0 + 2, 3);
ffffffffc0204560:	ecbfc0ef          	jal	ra,ffffffffc020142a <free_pages>
     assert(alloc_pages(4) == NULL);
ffffffffc0204564:	4511                	li	a0,4
ffffffffc0204566:	e33fc0ef          	jal	ra,ffffffffc0201398 <alloc_pages>
ffffffffc020456a:	4c051463          	bnez	a0,ffffffffc0204a32 <default_check+0x6a2>
ffffffffc020456e:	0889b783          	ld	a5,136(s3)
ffffffffc0204572:	8385                	srli	a5,a5,0x1
ffffffffc0204574:	8b85                	andi	a5,a5,1
     assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0204576:	48078e63          	beqz	a5,ffffffffc0204a12 <default_check+0x682>
ffffffffc020457a:	0909a703          	lw	a4,144(s3)
ffffffffc020457e:	478d                	li	a5,3
ffffffffc0204580:	48f71963          	bne	a4,a5,ffffffffc0204a12 <default_check+0x682>
     assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0204584:	450d                	li	a0,3
ffffffffc0204586:	e13fc0ef          	jal	ra,ffffffffc0201398 <alloc_pages>
ffffffffc020458a:	8c2a                	mv	s8,a0
ffffffffc020458c:	46050363          	beqz	a0,ffffffffc02049f2 <default_check+0x662>
     assert(alloc_page() == NULL);
ffffffffc0204590:	4505                	li	a0,1
ffffffffc0204592:	e07fc0ef          	jal	ra,ffffffffc0201398 <alloc_pages>
ffffffffc0204596:	42051e63          	bnez	a0,ffffffffc02049d2 <default_check+0x642>
     assert(p0 + 2 == p1);
ffffffffc020459a:	418a1c63          	bne	s4,s8,ffffffffc02049b2 <default_check+0x622>

     p2 = p0 + 1;
     free_page(p0);
ffffffffc020459e:	4585                	li	a1,1
ffffffffc02045a0:	854e                	mv	a0,s3
ffffffffc02045a2:	e89fc0ef          	jal	ra,ffffffffc020142a <free_pages>
     free_pages(p1, 3);
ffffffffc02045a6:	458d                	li	a1,3
ffffffffc02045a8:	8552                	mv	a0,s4
ffffffffc02045aa:	e81fc0ef          	jal	ra,ffffffffc020142a <free_pages>
ffffffffc02045ae:	0089b783          	ld	a5,8(s3)
     p2 = p0 + 1;
ffffffffc02045b2:	04098c13          	addi	s8,s3,64
ffffffffc02045b6:	8385                	srli	a5,a5,0x1
ffffffffc02045b8:	8b85                	andi	a5,a5,1
     assert(PageProperty(p0) && p0->property == 1);
ffffffffc02045ba:	3c078c63          	beqz	a5,ffffffffc0204992 <default_check+0x602>
ffffffffc02045be:	0109a703          	lw	a4,16(s3)
ffffffffc02045c2:	4785                	li	a5,1
ffffffffc02045c4:	3cf71763          	bne	a4,a5,ffffffffc0204992 <default_check+0x602>
ffffffffc02045c8:	008a3783          	ld	a5,8(s4)
ffffffffc02045cc:	8385                	srli	a5,a5,0x1
ffffffffc02045ce:	8b85                	andi	a5,a5,1
     assert(PageProperty(p1) && p1->property == 3);
ffffffffc02045d0:	3a078163          	beqz	a5,ffffffffc0204972 <default_check+0x5e2>
ffffffffc02045d4:	010a2703          	lw	a4,16(s4)
ffffffffc02045d8:	478d                	li	a5,3
ffffffffc02045da:	38f71c63          	bne	a4,a5,ffffffffc0204972 <default_check+0x5e2>

     assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02045de:	4505                	li	a0,1
ffffffffc02045e0:	db9fc0ef          	jal	ra,ffffffffc0201398 <alloc_pages>
ffffffffc02045e4:	36a99763          	bne	s3,a0,ffffffffc0204952 <default_check+0x5c2>
     free_page(p0);
ffffffffc02045e8:	4585                	li	a1,1
ffffffffc02045ea:	e41fc0ef          	jal	ra,ffffffffc020142a <free_pages>
     assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc02045ee:	4509                	li	a0,2
ffffffffc02045f0:	da9fc0ef          	jal	ra,ffffffffc0201398 <alloc_pages>
ffffffffc02045f4:	32aa1f63          	bne	s4,a0,ffffffffc0204932 <default_check+0x5a2>

     free_pages(p0, 2);
ffffffffc02045f8:	4589                	li	a1,2
ffffffffc02045fa:	e31fc0ef          	jal	ra,ffffffffc020142a <free_pages>
     free_page(p2);
ffffffffc02045fe:	4585                	li	a1,1
ffffffffc0204600:	8562                	mv	a0,s8
ffffffffc0204602:	e29fc0ef          	jal	ra,ffffffffc020142a <free_pages>

     assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0204606:	4515                	li	a0,5
ffffffffc0204608:	d91fc0ef          	jal	ra,ffffffffc0201398 <alloc_pages>
ffffffffc020460c:	89aa                	mv	s3,a0
ffffffffc020460e:	48050263          	beqz	a0,ffffffffc0204a92 <default_check+0x702>
     assert(alloc_page() == NULL);
ffffffffc0204612:	4505                	li	a0,1
ffffffffc0204614:	d85fc0ef          	jal	ra,ffffffffc0201398 <alloc_pages>
ffffffffc0204618:	2c051d63          	bnez	a0,ffffffffc02048f2 <default_check+0x562>

     assert(nr_free == 0);
ffffffffc020461c:	481c                	lw	a5,16(s0)
ffffffffc020461e:	2a079a63          	bnez	a5,ffffffffc02048d2 <default_check+0x542>
     nr_free = nr_free_store;

     free_list = free_list_store;
     free_pages(p0, 5);
ffffffffc0204622:	4595                	li	a1,5
ffffffffc0204624:	854e                	mv	a0,s3
     nr_free = nr_free_store;
ffffffffc0204626:	01742823          	sw	s7,16(s0)
     free_list = free_list_store;
ffffffffc020462a:	01643023          	sd	s6,0(s0)
ffffffffc020462e:	01543423          	sd	s5,8(s0)
     free_pages(p0, 5);
ffffffffc0204632:	df9fc0ef          	jal	ra,ffffffffc020142a <free_pages>
    return listelm->next;
ffffffffc0204636:	641c                	ld	a5,8(s0)

     le = &free_list;
     while ((le = list_next(le)) != &free_list) {
ffffffffc0204638:	00878963          	beq	a5,s0,ffffffffc020464a <default_check+0x2ba>
          struct Page *p = le2page(le, page_link);
          count --, total -= p->property;
ffffffffc020463c:	ff87a703          	lw	a4,-8(a5)
ffffffffc0204640:	679c                	ld	a5,8(a5)
ffffffffc0204642:	397d                	addiw	s2,s2,-1
ffffffffc0204644:	9c99                	subw	s1,s1,a4
     while ((le = list_next(le)) != &free_list) {
ffffffffc0204646:	fe879be3          	bne	a5,s0,ffffffffc020463c <default_check+0x2ac>
     }
     assert(count == 0);
ffffffffc020464a:	26091463          	bnez	s2,ffffffffc02048b2 <default_check+0x522>
     assert(total == 0);
ffffffffc020464e:	46049263          	bnez	s1,ffffffffc0204ab2 <default_check+0x722>
}
ffffffffc0204652:	60a6                	ld	ra,72(sp)
ffffffffc0204654:	6406                	ld	s0,64(sp)
ffffffffc0204656:	74e2                	ld	s1,56(sp)
ffffffffc0204658:	7942                	ld	s2,48(sp)
ffffffffc020465a:	79a2                	ld	s3,40(sp)
ffffffffc020465c:	7a02                	ld	s4,32(sp)
ffffffffc020465e:	6ae2                	ld	s5,24(sp)
ffffffffc0204660:	6b42                	ld	s6,16(sp)
ffffffffc0204662:	6ba2                	ld	s7,8(sp)
ffffffffc0204664:	6c02                	ld	s8,0(sp)
ffffffffc0204666:	6161                	addi	sp,sp,80
ffffffffc0204668:	8082                	ret
     while ((le = list_next(le)) != &free_list) {
ffffffffc020466a:	4981                	li	s3,0
     int count = 0, total = 0;
ffffffffc020466c:	4481                	li	s1,0
ffffffffc020466e:	4901                	li	s2,0
ffffffffc0204670:	b38d                	j	ffffffffc02043d2 <default_check+0x42>
          assert(PageProperty(p));
ffffffffc0204672:	00003697          	auipc	a3,0x3
ffffffffc0204676:	57668693          	addi	a3,a3,1398 # ffffffffc0207be8 <commands+0x11c8>
ffffffffc020467a:	00002617          	auipc	a2,0x2
ffffffffc020467e:	7b660613          	addi	a2,a2,1974 # ffffffffc0206e30 <commands+0x410>
ffffffffc0204682:	0f400593          	li	a1,244
ffffffffc0204686:	00004517          	auipc	a0,0x4
ffffffffc020468a:	b0250513          	addi	a0,a0,-1278 # ffffffffc0208188 <commands+0x1768>
ffffffffc020468e:	b7bfb0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0204692:	00004697          	auipc	a3,0x4
ffffffffc0204696:	b6e68693          	addi	a3,a3,-1170 # ffffffffc0208200 <commands+0x17e0>
ffffffffc020469a:	00002617          	auipc	a2,0x2
ffffffffc020469e:	79660613          	addi	a2,a2,1942 # ffffffffc0206e30 <commands+0x410>
ffffffffc02046a2:	0c100593          	li	a1,193
ffffffffc02046a6:	00004517          	auipc	a0,0x4
ffffffffc02046aa:	ae250513          	addi	a0,a0,-1310 # ffffffffc0208188 <commands+0x1768>
ffffffffc02046ae:	b5bfb0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02046b2:	00004697          	auipc	a3,0x4
ffffffffc02046b6:	b7668693          	addi	a3,a3,-1162 # ffffffffc0208228 <commands+0x1808>
ffffffffc02046ba:	00002617          	auipc	a2,0x2
ffffffffc02046be:	77660613          	addi	a2,a2,1910 # ffffffffc0206e30 <commands+0x410>
ffffffffc02046c2:	0c200593          	li	a1,194
ffffffffc02046c6:	00004517          	auipc	a0,0x4
ffffffffc02046ca:	ac250513          	addi	a0,a0,-1342 # ffffffffc0208188 <commands+0x1768>
ffffffffc02046ce:	b3bfb0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02046d2:	00004697          	auipc	a3,0x4
ffffffffc02046d6:	b9668693          	addi	a3,a3,-1130 # ffffffffc0208268 <commands+0x1848>
ffffffffc02046da:	00002617          	auipc	a2,0x2
ffffffffc02046de:	75660613          	addi	a2,a2,1878 # ffffffffc0206e30 <commands+0x410>
ffffffffc02046e2:	0c400593          	li	a1,196
ffffffffc02046e6:	00004517          	auipc	a0,0x4
ffffffffc02046ea:	aa250513          	addi	a0,a0,-1374 # ffffffffc0208188 <commands+0x1768>
ffffffffc02046ee:	b1bfb0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(!list_empty(&free_list));
ffffffffc02046f2:	00004697          	auipc	a3,0x4
ffffffffc02046f6:	bfe68693          	addi	a3,a3,-1026 # ffffffffc02082f0 <commands+0x18d0>
ffffffffc02046fa:	00002617          	auipc	a2,0x2
ffffffffc02046fe:	73660613          	addi	a2,a2,1846 # ffffffffc0206e30 <commands+0x410>
ffffffffc0204702:	0dd00593          	li	a1,221
ffffffffc0204706:	00004517          	auipc	a0,0x4
ffffffffc020470a:	a8250513          	addi	a0,a0,-1406 # ffffffffc0208188 <commands+0x1768>
ffffffffc020470e:	afbfb0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert((p0 = alloc_page()) != NULL);
ffffffffc0204712:	00004697          	auipc	a3,0x4
ffffffffc0204716:	a8e68693          	addi	a3,a3,-1394 # ffffffffc02081a0 <commands+0x1780>
ffffffffc020471a:	00002617          	auipc	a2,0x2
ffffffffc020471e:	71660613          	addi	a2,a2,1814 # ffffffffc0206e30 <commands+0x410>
ffffffffc0204722:	0d600593          	li	a1,214
ffffffffc0204726:	00004517          	auipc	a0,0x4
ffffffffc020472a:	a6250513          	addi	a0,a0,-1438 # ffffffffc0208188 <commands+0x1768>
ffffffffc020472e:	adbfb0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(nr_free == 3);
ffffffffc0204732:	00004697          	auipc	a3,0x4
ffffffffc0204736:	bae68693          	addi	a3,a3,-1106 # ffffffffc02082e0 <commands+0x18c0>
ffffffffc020473a:	00002617          	auipc	a2,0x2
ffffffffc020473e:	6f660613          	addi	a2,a2,1782 # ffffffffc0206e30 <commands+0x410>
ffffffffc0204742:	0d400593          	li	a1,212
ffffffffc0204746:	00004517          	auipc	a0,0x4
ffffffffc020474a:	a4250513          	addi	a0,a0,-1470 # ffffffffc0208188 <commands+0x1768>
ffffffffc020474e:	abbfb0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(alloc_page() == NULL);
ffffffffc0204752:	00004697          	auipc	a3,0x4
ffffffffc0204756:	b7668693          	addi	a3,a3,-1162 # ffffffffc02082c8 <commands+0x18a8>
ffffffffc020475a:	00002617          	auipc	a2,0x2
ffffffffc020475e:	6d660613          	addi	a2,a2,1750 # ffffffffc0206e30 <commands+0x410>
ffffffffc0204762:	0cf00593          	li	a1,207
ffffffffc0204766:	00004517          	auipc	a0,0x4
ffffffffc020476a:	a2250513          	addi	a0,a0,-1502 # ffffffffc0208188 <commands+0x1768>
ffffffffc020476e:	a9bfb0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0204772:	00004697          	auipc	a3,0x4
ffffffffc0204776:	b3668693          	addi	a3,a3,-1226 # ffffffffc02082a8 <commands+0x1888>
ffffffffc020477a:	00002617          	auipc	a2,0x2
ffffffffc020477e:	6b660613          	addi	a2,a2,1718 # ffffffffc0206e30 <commands+0x410>
ffffffffc0204782:	0c600593          	li	a1,198
ffffffffc0204786:	00004517          	auipc	a0,0x4
ffffffffc020478a:	a0250513          	addi	a0,a0,-1534 # ffffffffc0208188 <commands+0x1768>
ffffffffc020478e:	a7bfb0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(p0 != NULL);
ffffffffc0204792:	00004697          	auipc	a3,0x4
ffffffffc0204796:	b9668693          	addi	a3,a3,-1130 # ffffffffc0208328 <commands+0x1908>
ffffffffc020479a:	00002617          	auipc	a2,0x2
ffffffffc020479e:	69660613          	addi	a2,a2,1686 # ffffffffc0206e30 <commands+0x410>
ffffffffc02047a2:	0fc00593          	li	a1,252
ffffffffc02047a6:	00004517          	auipc	a0,0x4
ffffffffc02047aa:	9e250513          	addi	a0,a0,-1566 # ffffffffc0208188 <commands+0x1768>
ffffffffc02047ae:	a5bfb0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(nr_free == 0);
ffffffffc02047b2:	00003697          	auipc	a3,0x3
ffffffffc02047b6:	5e668693          	addi	a3,a3,1510 # ffffffffc0207d98 <commands+0x1378>
ffffffffc02047ba:	00002617          	auipc	a2,0x2
ffffffffc02047be:	67660613          	addi	a2,a2,1654 # ffffffffc0206e30 <commands+0x410>
ffffffffc02047c2:	0e300593          	li	a1,227
ffffffffc02047c6:	00004517          	auipc	a0,0x4
ffffffffc02047ca:	9c250513          	addi	a0,a0,-1598 # ffffffffc0208188 <commands+0x1768>
ffffffffc02047ce:	a3bfb0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(alloc_page() == NULL);
ffffffffc02047d2:	00004697          	auipc	a3,0x4
ffffffffc02047d6:	af668693          	addi	a3,a3,-1290 # ffffffffc02082c8 <commands+0x18a8>
ffffffffc02047da:	00002617          	auipc	a2,0x2
ffffffffc02047de:	65660613          	addi	a2,a2,1622 # ffffffffc0206e30 <commands+0x410>
ffffffffc02047e2:	0e100593          	li	a1,225
ffffffffc02047e6:	00004517          	auipc	a0,0x4
ffffffffc02047ea:	9a250513          	addi	a0,a0,-1630 # ffffffffc0208188 <commands+0x1768>
ffffffffc02047ee:	a1bfb0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert((p = alloc_page()) == p0);
ffffffffc02047f2:	00004697          	auipc	a3,0x4
ffffffffc02047f6:	b1668693          	addi	a3,a3,-1258 # ffffffffc0208308 <commands+0x18e8>
ffffffffc02047fa:	00002617          	auipc	a2,0x2
ffffffffc02047fe:	63660613          	addi	a2,a2,1590 # ffffffffc0206e30 <commands+0x410>
ffffffffc0204802:	0e000593          	li	a1,224
ffffffffc0204806:	00004517          	auipc	a0,0x4
ffffffffc020480a:	98250513          	addi	a0,a0,-1662 # ffffffffc0208188 <commands+0x1768>
ffffffffc020480e:	9fbfb0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert((p0 = alloc_page()) != NULL);
ffffffffc0204812:	00004697          	auipc	a3,0x4
ffffffffc0204816:	98e68693          	addi	a3,a3,-1650 # ffffffffc02081a0 <commands+0x1780>
ffffffffc020481a:	00002617          	auipc	a2,0x2
ffffffffc020481e:	61660613          	addi	a2,a2,1558 # ffffffffc0206e30 <commands+0x410>
ffffffffc0204822:	0bd00593          	li	a1,189
ffffffffc0204826:	00004517          	auipc	a0,0x4
ffffffffc020482a:	96250513          	addi	a0,a0,-1694 # ffffffffc0208188 <commands+0x1768>
ffffffffc020482e:	9dbfb0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(alloc_page() == NULL);
ffffffffc0204832:	00004697          	auipc	a3,0x4
ffffffffc0204836:	a9668693          	addi	a3,a3,-1386 # ffffffffc02082c8 <commands+0x18a8>
ffffffffc020483a:	00002617          	auipc	a2,0x2
ffffffffc020483e:	5f660613          	addi	a2,a2,1526 # ffffffffc0206e30 <commands+0x410>
ffffffffc0204842:	0da00593          	li	a1,218
ffffffffc0204846:	00004517          	auipc	a0,0x4
ffffffffc020484a:	94250513          	addi	a0,a0,-1726 # ffffffffc0208188 <commands+0x1768>
ffffffffc020484e:	9bbfb0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert((p2 = alloc_page()) != NULL);
ffffffffc0204852:	00004697          	auipc	a3,0x4
ffffffffc0204856:	98e68693          	addi	a3,a3,-1650 # ffffffffc02081e0 <commands+0x17c0>
ffffffffc020485a:	00002617          	auipc	a2,0x2
ffffffffc020485e:	5d660613          	addi	a2,a2,1494 # ffffffffc0206e30 <commands+0x410>
ffffffffc0204862:	0d800593          	li	a1,216
ffffffffc0204866:	00004517          	auipc	a0,0x4
ffffffffc020486a:	92250513          	addi	a0,a0,-1758 # ffffffffc0208188 <commands+0x1768>
ffffffffc020486e:	99bfb0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert((p1 = alloc_page()) != NULL);
ffffffffc0204872:	00004697          	auipc	a3,0x4
ffffffffc0204876:	94e68693          	addi	a3,a3,-1714 # ffffffffc02081c0 <commands+0x17a0>
ffffffffc020487a:	00002617          	auipc	a2,0x2
ffffffffc020487e:	5b660613          	addi	a2,a2,1462 # ffffffffc0206e30 <commands+0x410>
ffffffffc0204882:	0d700593          	li	a1,215
ffffffffc0204886:	00004517          	auipc	a0,0x4
ffffffffc020488a:	90250513          	addi	a0,a0,-1790 # ffffffffc0208188 <commands+0x1768>
ffffffffc020488e:	97bfb0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert((p2 = alloc_page()) != NULL);
ffffffffc0204892:	00004697          	auipc	a3,0x4
ffffffffc0204896:	94e68693          	addi	a3,a3,-1714 # ffffffffc02081e0 <commands+0x17c0>
ffffffffc020489a:	00002617          	auipc	a2,0x2
ffffffffc020489e:	59660613          	addi	a2,a2,1430 # ffffffffc0206e30 <commands+0x410>
ffffffffc02048a2:	0bf00593          	li	a1,191
ffffffffc02048a6:	00004517          	auipc	a0,0x4
ffffffffc02048aa:	8e250513          	addi	a0,a0,-1822 # ffffffffc0208188 <commands+0x1768>
ffffffffc02048ae:	95bfb0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(count == 0);
ffffffffc02048b2:	00004697          	auipc	a3,0x4
ffffffffc02048b6:	bc668693          	addi	a3,a3,-1082 # ffffffffc0208478 <commands+0x1a58>
ffffffffc02048ba:	00002617          	auipc	a2,0x2
ffffffffc02048be:	57660613          	addi	a2,a2,1398 # ffffffffc0206e30 <commands+0x410>
ffffffffc02048c2:	12900593          	li	a1,297
ffffffffc02048c6:	00004517          	auipc	a0,0x4
ffffffffc02048ca:	8c250513          	addi	a0,a0,-1854 # ffffffffc0208188 <commands+0x1768>
ffffffffc02048ce:	93bfb0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(nr_free == 0);
ffffffffc02048d2:	00003697          	auipc	a3,0x3
ffffffffc02048d6:	4c668693          	addi	a3,a3,1222 # ffffffffc0207d98 <commands+0x1378>
ffffffffc02048da:	00002617          	auipc	a2,0x2
ffffffffc02048de:	55660613          	addi	a2,a2,1366 # ffffffffc0206e30 <commands+0x410>
ffffffffc02048e2:	11e00593          	li	a1,286
ffffffffc02048e6:	00004517          	auipc	a0,0x4
ffffffffc02048ea:	8a250513          	addi	a0,a0,-1886 # ffffffffc0208188 <commands+0x1768>
ffffffffc02048ee:	91bfb0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(alloc_page() == NULL);
ffffffffc02048f2:	00004697          	auipc	a3,0x4
ffffffffc02048f6:	9d668693          	addi	a3,a3,-1578 # ffffffffc02082c8 <commands+0x18a8>
ffffffffc02048fa:	00002617          	auipc	a2,0x2
ffffffffc02048fe:	53660613          	addi	a2,a2,1334 # ffffffffc0206e30 <commands+0x410>
ffffffffc0204902:	11c00593          	li	a1,284
ffffffffc0204906:	00004517          	auipc	a0,0x4
ffffffffc020490a:	88250513          	addi	a0,a0,-1918 # ffffffffc0208188 <commands+0x1768>
ffffffffc020490e:	8fbfb0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0204912:	00004697          	auipc	a3,0x4
ffffffffc0204916:	97668693          	addi	a3,a3,-1674 # ffffffffc0208288 <commands+0x1868>
ffffffffc020491a:	00002617          	auipc	a2,0x2
ffffffffc020491e:	51660613          	addi	a2,a2,1302 # ffffffffc0206e30 <commands+0x410>
ffffffffc0204922:	0c500593          	li	a1,197
ffffffffc0204926:	00004517          	auipc	a0,0x4
ffffffffc020492a:	86250513          	addi	a0,a0,-1950 # ffffffffc0208188 <commands+0x1768>
ffffffffc020492e:	8dbfb0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0204932:	00004697          	auipc	a3,0x4
ffffffffc0204936:	b0668693          	addi	a3,a3,-1274 # ffffffffc0208438 <commands+0x1a18>
ffffffffc020493a:	00002617          	auipc	a2,0x2
ffffffffc020493e:	4f660613          	addi	a2,a2,1270 # ffffffffc0206e30 <commands+0x410>
ffffffffc0204942:	11600593          	li	a1,278
ffffffffc0204946:	00004517          	auipc	a0,0x4
ffffffffc020494a:	84250513          	addi	a0,a0,-1982 # ffffffffc0208188 <commands+0x1768>
ffffffffc020494e:	8bbfb0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0204952:	00004697          	auipc	a3,0x4
ffffffffc0204956:	ac668693          	addi	a3,a3,-1338 # ffffffffc0208418 <commands+0x19f8>
ffffffffc020495a:	00002617          	auipc	a2,0x2
ffffffffc020495e:	4d660613          	addi	a2,a2,1238 # ffffffffc0206e30 <commands+0x410>
ffffffffc0204962:	11400593          	li	a1,276
ffffffffc0204966:	00004517          	auipc	a0,0x4
ffffffffc020496a:	82250513          	addi	a0,a0,-2014 # ffffffffc0208188 <commands+0x1768>
ffffffffc020496e:	89bfb0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(PageProperty(p1) && p1->property == 3);
ffffffffc0204972:	00004697          	auipc	a3,0x4
ffffffffc0204976:	a7e68693          	addi	a3,a3,-1410 # ffffffffc02083f0 <commands+0x19d0>
ffffffffc020497a:	00002617          	auipc	a2,0x2
ffffffffc020497e:	4b660613          	addi	a2,a2,1206 # ffffffffc0206e30 <commands+0x410>
ffffffffc0204982:	11200593          	li	a1,274
ffffffffc0204986:	00004517          	auipc	a0,0x4
ffffffffc020498a:	80250513          	addi	a0,a0,-2046 # ffffffffc0208188 <commands+0x1768>
ffffffffc020498e:	87bfb0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(PageProperty(p0) && p0->property == 1);
ffffffffc0204992:	00004697          	auipc	a3,0x4
ffffffffc0204996:	a3668693          	addi	a3,a3,-1482 # ffffffffc02083c8 <commands+0x19a8>
ffffffffc020499a:	00002617          	auipc	a2,0x2
ffffffffc020499e:	49660613          	addi	a2,a2,1174 # ffffffffc0206e30 <commands+0x410>
ffffffffc02049a2:	11100593          	li	a1,273
ffffffffc02049a6:	00003517          	auipc	a0,0x3
ffffffffc02049aa:	7e250513          	addi	a0,a0,2018 # ffffffffc0208188 <commands+0x1768>
ffffffffc02049ae:	85bfb0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(p0 + 2 == p1);
ffffffffc02049b2:	00004697          	auipc	a3,0x4
ffffffffc02049b6:	a0668693          	addi	a3,a3,-1530 # ffffffffc02083b8 <commands+0x1998>
ffffffffc02049ba:	00002617          	auipc	a2,0x2
ffffffffc02049be:	47660613          	addi	a2,a2,1142 # ffffffffc0206e30 <commands+0x410>
ffffffffc02049c2:	10c00593          	li	a1,268
ffffffffc02049c6:	00003517          	auipc	a0,0x3
ffffffffc02049ca:	7c250513          	addi	a0,a0,1986 # ffffffffc0208188 <commands+0x1768>
ffffffffc02049ce:	83bfb0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(alloc_page() == NULL);
ffffffffc02049d2:	00004697          	auipc	a3,0x4
ffffffffc02049d6:	8f668693          	addi	a3,a3,-1802 # ffffffffc02082c8 <commands+0x18a8>
ffffffffc02049da:	00002617          	auipc	a2,0x2
ffffffffc02049de:	45660613          	addi	a2,a2,1110 # ffffffffc0206e30 <commands+0x410>
ffffffffc02049e2:	10b00593          	li	a1,267
ffffffffc02049e6:	00003517          	auipc	a0,0x3
ffffffffc02049ea:	7a250513          	addi	a0,a0,1954 # ffffffffc0208188 <commands+0x1768>
ffffffffc02049ee:	81bfb0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02049f2:	00004697          	auipc	a3,0x4
ffffffffc02049f6:	9a668693          	addi	a3,a3,-1626 # ffffffffc0208398 <commands+0x1978>
ffffffffc02049fa:	00002617          	auipc	a2,0x2
ffffffffc02049fe:	43660613          	addi	a2,a2,1078 # ffffffffc0206e30 <commands+0x410>
ffffffffc0204a02:	10a00593          	li	a1,266
ffffffffc0204a06:	00003517          	auipc	a0,0x3
ffffffffc0204a0a:	78250513          	addi	a0,a0,1922 # ffffffffc0208188 <commands+0x1768>
ffffffffc0204a0e:	ffafb0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0204a12:	00004697          	auipc	a3,0x4
ffffffffc0204a16:	95668693          	addi	a3,a3,-1706 # ffffffffc0208368 <commands+0x1948>
ffffffffc0204a1a:	00002617          	auipc	a2,0x2
ffffffffc0204a1e:	41660613          	addi	a2,a2,1046 # ffffffffc0206e30 <commands+0x410>
ffffffffc0204a22:	10900593          	li	a1,265
ffffffffc0204a26:	00003517          	auipc	a0,0x3
ffffffffc0204a2a:	76250513          	addi	a0,a0,1890 # ffffffffc0208188 <commands+0x1768>
ffffffffc0204a2e:	fdafb0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(alloc_pages(4) == NULL);
ffffffffc0204a32:	00004697          	auipc	a3,0x4
ffffffffc0204a36:	91e68693          	addi	a3,a3,-1762 # ffffffffc0208350 <commands+0x1930>
ffffffffc0204a3a:	00002617          	auipc	a2,0x2
ffffffffc0204a3e:	3f660613          	addi	a2,a2,1014 # ffffffffc0206e30 <commands+0x410>
ffffffffc0204a42:	10800593          	li	a1,264
ffffffffc0204a46:	00003517          	auipc	a0,0x3
ffffffffc0204a4a:	74250513          	addi	a0,a0,1858 # ffffffffc0208188 <commands+0x1768>
ffffffffc0204a4e:	fbafb0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(alloc_page() == NULL);
ffffffffc0204a52:	00004697          	auipc	a3,0x4
ffffffffc0204a56:	87668693          	addi	a3,a3,-1930 # ffffffffc02082c8 <commands+0x18a8>
ffffffffc0204a5a:	00002617          	auipc	a2,0x2
ffffffffc0204a5e:	3d660613          	addi	a2,a2,982 # ffffffffc0206e30 <commands+0x410>
ffffffffc0204a62:	10200593          	li	a1,258
ffffffffc0204a66:	00003517          	auipc	a0,0x3
ffffffffc0204a6a:	72250513          	addi	a0,a0,1826 # ffffffffc0208188 <commands+0x1768>
ffffffffc0204a6e:	f9afb0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(!PageProperty(p0));
ffffffffc0204a72:	00004697          	auipc	a3,0x4
ffffffffc0204a76:	8c668693          	addi	a3,a3,-1850 # ffffffffc0208338 <commands+0x1918>
ffffffffc0204a7a:	00002617          	auipc	a2,0x2
ffffffffc0204a7e:	3b660613          	addi	a2,a2,950 # ffffffffc0206e30 <commands+0x410>
ffffffffc0204a82:	0fd00593          	li	a1,253
ffffffffc0204a86:	00003517          	auipc	a0,0x3
ffffffffc0204a8a:	70250513          	addi	a0,a0,1794 # ffffffffc0208188 <commands+0x1768>
ffffffffc0204a8e:	f7afb0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0204a92:	00004697          	auipc	a3,0x4
ffffffffc0204a96:	9c668693          	addi	a3,a3,-1594 # ffffffffc0208458 <commands+0x1a38>
ffffffffc0204a9a:	00002617          	auipc	a2,0x2
ffffffffc0204a9e:	39660613          	addi	a2,a2,918 # ffffffffc0206e30 <commands+0x410>
ffffffffc0204aa2:	11b00593          	li	a1,283
ffffffffc0204aa6:	00003517          	auipc	a0,0x3
ffffffffc0204aaa:	6e250513          	addi	a0,a0,1762 # ffffffffc0208188 <commands+0x1768>
ffffffffc0204aae:	f5afb0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(total == 0);
ffffffffc0204ab2:	00004697          	auipc	a3,0x4
ffffffffc0204ab6:	9d668693          	addi	a3,a3,-1578 # ffffffffc0208488 <commands+0x1a68>
ffffffffc0204aba:	00002617          	auipc	a2,0x2
ffffffffc0204abe:	37660613          	addi	a2,a2,886 # ffffffffc0206e30 <commands+0x410>
ffffffffc0204ac2:	12a00593          	li	a1,298
ffffffffc0204ac6:	00003517          	auipc	a0,0x3
ffffffffc0204aca:	6c250513          	addi	a0,a0,1730 # ffffffffc0208188 <commands+0x1768>
ffffffffc0204ace:	f3afb0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(total == nr_free_pages());
ffffffffc0204ad2:	00003697          	auipc	a3,0x3
ffffffffc0204ad6:	12668693          	addi	a3,a3,294 # ffffffffc0207bf8 <commands+0x11d8>
ffffffffc0204ada:	00002617          	auipc	a2,0x2
ffffffffc0204ade:	35660613          	addi	a2,a2,854 # ffffffffc0206e30 <commands+0x410>
ffffffffc0204ae2:	0f700593          	li	a1,247
ffffffffc0204ae6:	00003517          	auipc	a0,0x3
ffffffffc0204aea:	6a250513          	addi	a0,a0,1698 # ffffffffc0208188 <commands+0x1768>
ffffffffc0204aee:	f1afb0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert((p1 = alloc_page()) != NULL);
ffffffffc0204af2:	00003697          	auipc	a3,0x3
ffffffffc0204af6:	6ce68693          	addi	a3,a3,1742 # ffffffffc02081c0 <commands+0x17a0>
ffffffffc0204afa:	00002617          	auipc	a2,0x2
ffffffffc0204afe:	33660613          	addi	a2,a2,822 # ffffffffc0206e30 <commands+0x410>
ffffffffc0204b02:	0be00593          	li	a1,190
ffffffffc0204b06:	00003517          	auipc	a0,0x3
ffffffffc0204b0a:	68250513          	addi	a0,a0,1666 # ffffffffc0208188 <commands+0x1768>
ffffffffc0204b0e:	efafb0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0204b12 <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc0204b12:	1141                	addi	sp,sp,-16
ffffffffc0204b14:	e406                	sd	ra,8(sp)
    assert(n > 0); // 确保 n 大于 0
ffffffffc0204b16:	14058463          	beqz	a1,ffffffffc0204c5e <default_free_pages+0x14c>
    for (; p != base + n; p ++) { // 遍历从 base 开始的 n 个页面
ffffffffc0204b1a:	00659693          	slli	a3,a1,0x6
ffffffffc0204b1e:	96aa                	add	a3,a3,a0
ffffffffc0204b20:	87aa                	mv	a5,a0
ffffffffc0204b22:	02d50263          	beq	a0,a3,ffffffffc0204b46 <default_free_pages+0x34>
ffffffffc0204b26:	6798                	ld	a4,8(a5)
ffffffffc0204b28:	8b05                	andi	a4,a4,1
        assert(!PageReserved(p) && !PageProperty(p)); // 确保页面 p 没有被保留且没有属性
ffffffffc0204b2a:	10071a63          	bnez	a4,ffffffffc0204c3e <default_free_pages+0x12c>
ffffffffc0204b2e:	6798                	ld	a4,8(a5)
ffffffffc0204b30:	8b09                	andi	a4,a4,2
ffffffffc0204b32:	10071663          	bnez	a4,ffffffffc0204c3e <default_free_pages+0x12c>
        p->flags = 0; // 将页面 p 的 flags 置为 0
ffffffffc0204b36:	0007b423          	sd	zero,8(a5)
    page->ref = val;
ffffffffc0204b3a:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) { // 遍历从 base 开始的 n 个页面
ffffffffc0204b3e:	04078793          	addi	a5,a5,64
ffffffffc0204b42:	fed792e3          	bne	a5,a3,ffffffffc0204b26 <default_free_pages+0x14>
    base->property = n; // 将 base 页面的 property 设置为 n
ffffffffc0204b46:	2581                	sext.w	a1,a1
ffffffffc0204b48:	c90c                	sw	a1,16(a0)
    SetPageProperty(base); // 设置 base 页面的属性
ffffffffc0204b4a:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0204b4e:	4789                	li	a5,2
ffffffffc0204b50:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n; // 增加空闲页面的数量
ffffffffc0204b54:	000aa697          	auipc	a3,0xaa
ffffffffc0204b58:	cd468693          	addi	a3,a3,-812 # ffffffffc02ae828 <free_area>
ffffffffc0204b5c:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0204b5e:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link)); // 将 base 页面添加到空闲列表中
ffffffffc0204b60:	01850613          	addi	a2,a0,24
    nr_free += n; // 增加空闲页面的数量
ffffffffc0204b64:	9db9                	addw	a1,a1,a4
ffffffffc0204b66:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) { // 如果空闲列表为空
ffffffffc0204b68:	0ad78463          	beq	a5,a3,ffffffffc0204c10 <default_free_pages+0xfe>
             struct Page* page = le2page(le, page_link); // 获取 le 对应的页面
ffffffffc0204b6c:	fe878713          	addi	a4,a5,-24
ffffffffc0204b70:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) { // 如果空闲列表为空
ffffffffc0204b74:	4581                	li	a1,0
             if (base < page) { // 如果 base 页面地址小于当前页面地址
ffffffffc0204b76:	00e56a63          	bltu	a0,a4,ffffffffc0204b8a <default_free_pages+0x78>
    return listelm->next;
ffffffffc0204b7a:	6798                	ld	a4,8(a5)
             } else if (list_next(le) == &free_list) { // 如果已经到达空闲列表的末尾
ffffffffc0204b7c:	04d70c63          	beq	a4,a3,ffffffffc0204bd4 <default_free_pages+0xc2>
    for (; p != base + n; p ++) { // 遍历从 base 开始的 n 个页面
ffffffffc0204b80:	87ba                	mv	a5,a4
             struct Page* page = le2page(le, page_link); // 获取 le 对应的页面
ffffffffc0204b82:	fe878713          	addi	a4,a5,-24
             if (base < page) { // 如果 base 页面地址小于当前页面地址
ffffffffc0204b86:	fee57ae3          	bgeu	a0,a4,ffffffffc0204b7a <default_free_pages+0x68>
ffffffffc0204b8a:	c199                	beqz	a1,ffffffffc0204b90 <default_free_pages+0x7e>
ffffffffc0204b8c:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0204b90:	6398                	ld	a4,0(a5)
    prev->next = next->prev = elm;
ffffffffc0204b92:	e390                	sd	a2,0(a5)
ffffffffc0204b94:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0204b96:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0204b98:	ed18                	sd	a4,24(a0)
    if (le != &free_list) { // 如果前一个节点不是空闲列表头
ffffffffc0204b9a:	00d70d63          	beq	a4,a3,ffffffffc0204bb4 <default_free_pages+0xa2>
        if (p + p->property == base) { // 如果前一个页面的结束地址等于 base 的起始地址
ffffffffc0204b9e:	ff872583          	lw	a1,-8(a4) # ff8 <_binary_obj___user_faultread_out_size-0x8bc0>
        p = le2page(le, page_link); // 获取 le 对应的页面
ffffffffc0204ba2:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base) { // 如果前一个页面的结束地址等于 base 的起始地址
ffffffffc0204ba6:	02059813          	slli	a6,a1,0x20
ffffffffc0204baa:	01a85793          	srli	a5,a6,0x1a
ffffffffc0204bae:	97b2                	add	a5,a5,a2
ffffffffc0204bb0:	02f50c63          	beq	a0,a5,ffffffffc0204be8 <default_free_pages+0xd6>
    return listelm->next;
ffffffffc0204bb4:	711c                	ld	a5,32(a0)
    if (le != &free_list) { // 如果下一个节点不是空闲列表头
ffffffffc0204bb6:	00d78c63          	beq	a5,a3,ffffffffc0204bce <default_free_pages+0xbc>
        if (base + base->property == p) { // 如果 base 的结束地址等于下一个页面的起始地址
ffffffffc0204bba:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link); // 获取 le 对应的页面
ffffffffc0204bbc:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p) { // 如果 base 的结束地址等于下一个页面的起始地址
ffffffffc0204bc0:	02061593          	slli	a1,a2,0x20
ffffffffc0204bc4:	01a5d713          	srli	a4,a1,0x1a
ffffffffc0204bc8:	972a                	add	a4,a4,a0
ffffffffc0204bca:	04e68a63          	beq	a3,a4,ffffffffc0204c1e <default_free_pages+0x10c>
}
ffffffffc0204bce:	60a2                	ld	ra,8(sp)
ffffffffc0204bd0:	0141                	addi	sp,sp,16
ffffffffc0204bd2:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0204bd4:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0204bd6:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0204bd8:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0204bda:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) { // 遍历空闲列表
ffffffffc0204bdc:	02d70763          	beq	a4,a3,ffffffffc0204c0a <default_free_pages+0xf8>
    prev->next = next->prev = elm;
ffffffffc0204be0:	8832                	mv	a6,a2
ffffffffc0204be2:	4585                	li	a1,1
    for (; p != base + n; p ++) { // 遍历从 base 开始的 n 个页面
ffffffffc0204be4:	87ba                	mv	a5,a4
ffffffffc0204be6:	bf71                	j	ffffffffc0204b82 <default_free_pages+0x70>
             p->property += base->property; // 合并两个页面块
ffffffffc0204be8:	491c                	lw	a5,16(a0)
ffffffffc0204bea:	9dbd                	addw	a1,a1,a5
ffffffffc0204bec:	feb72c23          	sw	a1,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0204bf0:	57f5                	li	a5,-3
ffffffffc0204bf2:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0204bf6:	01853803          	ld	a6,24(a0)
ffffffffc0204bfa:	710c                	ld	a1,32(a0)
             base = p; // 更新 base 指针
ffffffffc0204bfc:	8532                	mv	a0,a2
    prev->next = next;
ffffffffc0204bfe:	00b83423          	sd	a1,8(a6) # fffffffffff80008 <end+0x3fccd724>
    return listelm->next;
ffffffffc0204c02:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc0204c04:	0105b023          	sd	a6,0(a1) # 1000 <_binary_obj___user_faultread_out_size-0x8bb8>
ffffffffc0204c08:	b77d                	j	ffffffffc0204bb6 <default_free_pages+0xa4>
ffffffffc0204c0a:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list) { // 遍历空闲列表
ffffffffc0204c0c:	873e                	mv	a4,a5
ffffffffc0204c0e:	bf41                	j	ffffffffc0204b9e <default_free_pages+0x8c>
}
ffffffffc0204c10:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0204c12:	e390                	sd	a2,0(a5)
ffffffffc0204c14:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0204c16:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0204c18:	ed1c                	sd	a5,24(a0)
ffffffffc0204c1a:	0141                	addi	sp,sp,16
ffffffffc0204c1c:	8082                	ret
             base->property += p->property; // 合并两个页面块
ffffffffc0204c1e:	ff87a703          	lw	a4,-8(a5)
ffffffffc0204c22:	ff078693          	addi	a3,a5,-16
ffffffffc0204c26:	9e39                	addw	a2,a2,a4
ffffffffc0204c28:	c910                	sw	a2,16(a0)
ffffffffc0204c2a:	5775                	li	a4,-3
ffffffffc0204c2c:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0204c30:	6398                	ld	a4,0(a5)
ffffffffc0204c32:	679c                	ld	a5,8(a5)
}
ffffffffc0204c34:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0204c36:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0204c38:	e398                	sd	a4,0(a5)
ffffffffc0204c3a:	0141                	addi	sp,sp,16
ffffffffc0204c3c:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p)); // 确保页面 p 没有被保留且没有属性
ffffffffc0204c3e:	00004697          	auipc	a3,0x4
ffffffffc0204c42:	86268693          	addi	a3,a3,-1950 # ffffffffc02084a0 <commands+0x1a80>
ffffffffc0204c46:	00002617          	auipc	a2,0x2
ffffffffc0204c4a:	1ea60613          	addi	a2,a2,490 # ffffffffc0206e30 <commands+0x410>
ffffffffc0204c4e:	08500593          	li	a1,133
ffffffffc0204c52:	00003517          	auipc	a0,0x3
ffffffffc0204c56:	53650513          	addi	a0,a0,1334 # ffffffffc0208188 <commands+0x1768>
ffffffffc0204c5a:	daefb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(n > 0); // 确保 n 大于 0
ffffffffc0204c5e:	00004697          	auipc	a3,0x4
ffffffffc0204c62:	83a68693          	addi	a3,a3,-1990 # ffffffffc0208498 <commands+0x1a78>
ffffffffc0204c66:	00002617          	auipc	a2,0x2
ffffffffc0204c6a:	1ca60613          	addi	a2,a2,458 # ffffffffc0206e30 <commands+0x410>
ffffffffc0204c6e:	08200593          	li	a1,130
ffffffffc0204c72:	00003517          	auipc	a0,0x3
ffffffffc0204c76:	51650513          	addi	a0,a0,1302 # ffffffffc0208188 <commands+0x1768>
ffffffffc0204c7a:	d8efb0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0204c7e <default_alloc_pages>:
    assert(n > 0); // 确保 n 大于 0
ffffffffc0204c7e:	c941                	beqz	a0,ffffffffc0204d0e <default_alloc_pages+0x90>
    if (n > nr_free) { // 如果 n 大于空闲页面的数量
ffffffffc0204c80:	000aa597          	auipc	a1,0xaa
ffffffffc0204c84:	ba858593          	addi	a1,a1,-1112 # ffffffffc02ae828 <free_area>
ffffffffc0204c88:	0105a803          	lw	a6,16(a1)
ffffffffc0204c8c:	872a                	mv	a4,a0
ffffffffc0204c8e:	02081793          	slli	a5,a6,0x20
ffffffffc0204c92:	9381                	srli	a5,a5,0x20
ffffffffc0204c94:	00a7ee63          	bltu	a5,a0,ffffffffc0204cb0 <default_alloc_pages+0x32>
    list_entry_t *le = &free_list; // 初始化指针 le 指向空闲列表
ffffffffc0204c98:	87ae                	mv	a5,a1
ffffffffc0204c9a:	a801                	j	ffffffffc0204caa <default_alloc_pages+0x2c>
        if (p->property >= n) { // 如果页面 p 的属性大于或等于 n
ffffffffc0204c9c:	ff87a683          	lw	a3,-8(a5)
ffffffffc0204ca0:	02069613          	slli	a2,a3,0x20
ffffffffc0204ca4:	9201                	srli	a2,a2,0x20
ffffffffc0204ca6:	00e67763          	bgeu	a2,a4,ffffffffc0204cb4 <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc0204caa:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) { // 遍历空闲列表
ffffffffc0204cac:	feb798e3          	bne	a5,a1,ffffffffc0204c9c <default_alloc_pages+0x1e>
        return NULL; // 返回 NULL
ffffffffc0204cb0:	4501                	li	a0,0
}
ffffffffc0204cb2:	8082                	ret
    return listelm->prev;
ffffffffc0204cb4:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0204cb8:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link); // 获取 le 对应的页面
ffffffffc0204cbc:	fe878513          	addi	a0,a5,-24
             p->property = page->property - n; // 设置剩余页面的属性
ffffffffc0204cc0:	00070e1b          	sext.w	t3,a4
    prev->next = next;
ffffffffc0204cc4:	0068b423          	sd	t1,8(a7) # 1008 <_binary_obj___user_faultread_out_size-0x8bb0>
    next->prev = prev;
ffffffffc0204cc8:	01133023          	sd	a7,0(t1) # 80000 <_binary_obj___user_exit_out_size+0x74ec8>
        if (page->property > n) { // 如果页面的属性大于 n
ffffffffc0204ccc:	02c77863          	bgeu	a4,a2,ffffffffc0204cfc <default_alloc_pages+0x7e>
             struct Page *p = page + n; // 计算剩余页面的起始地址
ffffffffc0204cd0:	071a                	slli	a4,a4,0x6
ffffffffc0204cd2:	972a                	add	a4,a4,a0
             p->property = page->property - n; // 设置剩余页面的属性
ffffffffc0204cd4:	41c686bb          	subw	a3,a3,t3
ffffffffc0204cd8:	cb14                	sw	a3,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0204cda:	00870613          	addi	a2,a4,8
ffffffffc0204cde:	4689                	li	a3,2
ffffffffc0204ce0:	40d6302f          	amoor.d	zero,a3,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc0204ce4:	0088b683          	ld	a3,8(a7)
             list_add(prev, &(p->page_link)); // 将剩余页面添加到空闲列表中
ffffffffc0204ce8:	01870613          	addi	a2,a4,24
        nr_free -= n; // 减少空闲页面的数量
ffffffffc0204cec:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc0204cf0:	e290                	sd	a2,0(a3)
ffffffffc0204cf2:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc0204cf6:	f314                	sd	a3,32(a4)
    elm->prev = prev;
ffffffffc0204cf8:	01173c23          	sd	a7,24(a4)
ffffffffc0204cfc:	41c8083b          	subw	a6,a6,t3
ffffffffc0204d00:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0204d04:	5775                	li	a4,-3
ffffffffc0204d06:	17c1                	addi	a5,a5,-16
ffffffffc0204d08:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc0204d0c:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc0204d0e:	1141                	addi	sp,sp,-16
    assert(n > 0); // 确保 n 大于 0
ffffffffc0204d10:	00003697          	auipc	a3,0x3
ffffffffc0204d14:	78868693          	addi	a3,a3,1928 # ffffffffc0208498 <commands+0x1a78>
ffffffffc0204d18:	00002617          	auipc	a2,0x2
ffffffffc0204d1c:	11860613          	addi	a2,a2,280 # ffffffffc0206e30 <commands+0x410>
ffffffffc0204d20:	06300593          	li	a1,99
ffffffffc0204d24:	00003517          	auipc	a0,0x3
ffffffffc0204d28:	46450513          	addi	a0,a0,1124 # ffffffffc0208188 <commands+0x1768>
default_alloc_pages(size_t n) {
ffffffffc0204d2c:	e406                	sd	ra,8(sp)
    assert(n > 0); // 确保 n 大于 0
ffffffffc0204d2e:	cdafb0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0204d32 <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc0204d32:	1141                	addi	sp,sp,-16
ffffffffc0204d34:	e406                	sd	ra,8(sp)
    assert(n > 0); // 确保 n 大于 0
ffffffffc0204d36:	c5f1                	beqz	a1,ffffffffc0204e02 <default_init_memmap+0xd0>
    for (; p != base + n; p ++) { // 遍历从 base 开始的 n 个页面
ffffffffc0204d38:	00659693          	slli	a3,a1,0x6
ffffffffc0204d3c:	96aa                	add	a3,a3,a0
ffffffffc0204d3e:	87aa                	mv	a5,a0
ffffffffc0204d40:	00d50f63          	beq	a0,a3,ffffffffc0204d5e <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0204d44:	6798                	ld	a4,8(a5)
ffffffffc0204d46:	8b05                	andi	a4,a4,1
        assert(PageReserved(p)); // 确保页面 p 被保留
ffffffffc0204d48:	cf49                	beqz	a4,ffffffffc0204de2 <default_init_memmap+0xb0>
        p->flags = p->property = 0; // 将页面 p 的 flags 和 property 置为 0
ffffffffc0204d4a:	0007a823          	sw	zero,16(a5)
ffffffffc0204d4e:	0007b423          	sd	zero,8(a5)
ffffffffc0204d52:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) { // 遍历从 base 开始的 n 个页面
ffffffffc0204d56:	04078793          	addi	a5,a5,64
ffffffffc0204d5a:	fed795e3          	bne	a5,a3,ffffffffc0204d44 <default_init_memmap+0x12>
    base->property = n; // 将 base 页面的 property 设置为 n
ffffffffc0204d5e:	2581                	sext.w	a1,a1
ffffffffc0204d60:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0204d62:	4789                	li	a5,2
ffffffffc0204d64:	00850713          	addi	a4,a0,8
ffffffffc0204d68:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n; // 增加空闲页面的数量
ffffffffc0204d6c:	000aa697          	auipc	a3,0xaa
ffffffffc0204d70:	abc68693          	addi	a3,a3,-1348 # ffffffffc02ae828 <free_area>
ffffffffc0204d74:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0204d76:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link)); // 将 base 页面添加到空闲列表中
ffffffffc0204d78:	01850613          	addi	a2,a0,24
    nr_free += n; // 增加空闲页面的数量
ffffffffc0204d7c:	9db9                	addw	a1,a1,a4
ffffffffc0204d7e:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) { // 如果空闲列表为空
ffffffffc0204d80:	04d78a63          	beq	a5,a3,ffffffffc0204dd4 <default_init_memmap+0xa2>
             struct Page* page = le2page(le, page_link); // 获取 le 对应的页面
ffffffffc0204d84:	fe878713          	addi	a4,a5,-24
ffffffffc0204d88:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) { // 如果空闲列表为空
ffffffffc0204d8c:	4581                	li	a1,0
             if (base < page) { // 如果 base 页面地址小于当前页面地址
ffffffffc0204d8e:	00e56a63          	bltu	a0,a4,ffffffffc0204da2 <default_init_memmap+0x70>
    return listelm->next;
ffffffffc0204d92:	6798                	ld	a4,8(a5)
             } else if (list_next(le) == &free_list) { // 如果已经到达空闲列表的末尾
ffffffffc0204d94:	02d70263          	beq	a4,a3,ffffffffc0204db8 <default_init_memmap+0x86>
    for (; p != base + n; p ++) { // 遍历从 base 开始的 n 个页面
ffffffffc0204d98:	87ba                	mv	a5,a4
             struct Page* page = le2page(le, page_link); // 获取 le 对应的页面
ffffffffc0204d9a:	fe878713          	addi	a4,a5,-24
             if (base < page) { // 如果 base 页面地址小于当前页面地址
ffffffffc0204d9e:	fee57ae3          	bgeu	a0,a4,ffffffffc0204d92 <default_init_memmap+0x60>
ffffffffc0204da2:	c199                	beqz	a1,ffffffffc0204da8 <default_init_memmap+0x76>
ffffffffc0204da4:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0204da8:	6398                	ld	a4,0(a5)
}
ffffffffc0204daa:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0204dac:	e390                	sd	a2,0(a5)
ffffffffc0204dae:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0204db0:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0204db2:	ed18                	sd	a4,24(a0)
ffffffffc0204db4:	0141                	addi	sp,sp,16
ffffffffc0204db6:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0204db8:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0204dba:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0204dbc:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0204dbe:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) { // 遍历空闲列表
ffffffffc0204dc0:	00d70663          	beq	a4,a3,ffffffffc0204dcc <default_init_memmap+0x9a>
    prev->next = next->prev = elm;
ffffffffc0204dc4:	8832                	mv	a6,a2
ffffffffc0204dc6:	4585                	li	a1,1
    for (; p != base + n; p ++) { // 遍历从 base 开始的 n 个页面
ffffffffc0204dc8:	87ba                	mv	a5,a4
ffffffffc0204dca:	bfc1                	j	ffffffffc0204d9a <default_init_memmap+0x68>
}
ffffffffc0204dcc:	60a2                	ld	ra,8(sp)
ffffffffc0204dce:	e290                	sd	a2,0(a3)
ffffffffc0204dd0:	0141                	addi	sp,sp,16
ffffffffc0204dd2:	8082                	ret
ffffffffc0204dd4:	60a2                	ld	ra,8(sp)
ffffffffc0204dd6:	e390                	sd	a2,0(a5)
ffffffffc0204dd8:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0204dda:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0204ddc:	ed1c                	sd	a5,24(a0)
ffffffffc0204dde:	0141                	addi	sp,sp,16
ffffffffc0204de0:	8082                	ret
        assert(PageReserved(p)); // 确保页面 p 被保留
ffffffffc0204de2:	00003697          	auipc	a3,0x3
ffffffffc0204de6:	6e668693          	addi	a3,a3,1766 # ffffffffc02084c8 <commands+0x1aa8>
ffffffffc0204dea:	00002617          	auipc	a2,0x2
ffffffffc0204dee:	04660613          	addi	a2,a2,70 # ffffffffc0206e30 <commands+0x410>
ffffffffc0204df2:	04900593          	li	a1,73
ffffffffc0204df6:	00003517          	auipc	a0,0x3
ffffffffc0204dfa:	39250513          	addi	a0,a0,914 # ffffffffc0208188 <commands+0x1768>
ffffffffc0204dfe:	c0afb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(n > 0); // 确保 n 大于 0
ffffffffc0204e02:	00003697          	auipc	a3,0x3
ffffffffc0204e06:	69668693          	addi	a3,a3,1686 # ffffffffc0208498 <commands+0x1a78>
ffffffffc0204e0a:	00002617          	auipc	a2,0x2
ffffffffc0204e0e:	02660613          	addi	a2,a2,38 # ffffffffc0206e30 <commands+0x410>
ffffffffc0204e12:	04600593          	li	a1,70
ffffffffc0204e16:	00003517          	auipc	a0,0x3
ffffffffc0204e1a:	37250513          	addi	a0,a0,882 # ffffffffc0208188 <commands+0x1768>
ffffffffc0204e1e:	beafb0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0204e22 <swapfs_init>:
#include <ide.h>
#include <pmm.h>
#include <assert.h>

void
swapfs_init(void) {
ffffffffc0204e22:	1141                	addi	sp,sp,-16
    static_assert((PGSIZE % SECTSIZE) == 0);
    if (!ide_device_valid(SWAP_DEV_NO)) {
ffffffffc0204e24:	4505                	li	a0,1
swapfs_init(void) {
ffffffffc0204e26:	e406                	sd	ra,8(sp)
    if (!ide_device_valid(SWAP_DEV_NO)) {
ffffffffc0204e28:	f00fb0ef          	jal	ra,ffffffffc0200528 <ide_device_valid>
ffffffffc0204e2c:	cd01                	beqz	a0,ffffffffc0204e44 <swapfs_init+0x22>
        panic("swap fs isn't available.\n");
    }
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
ffffffffc0204e2e:	4505                	li	a0,1
ffffffffc0204e30:	efefb0ef          	jal	ra,ffffffffc020052e <ide_device_size>
}
ffffffffc0204e34:	60a2                	ld	ra,8(sp)
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
ffffffffc0204e36:	810d                	srli	a0,a0,0x3
ffffffffc0204e38:	000ae797          	auipc	a5,0xae
ffffffffc0204e3c:	a6a7b823          	sd	a0,-1424(a5) # ffffffffc02b28a8 <max_swap_offset>
}
ffffffffc0204e40:	0141                	addi	sp,sp,16
ffffffffc0204e42:	8082                	ret
        panic("swap fs isn't available.\n");
ffffffffc0204e44:	00003617          	auipc	a2,0x3
ffffffffc0204e48:	6e460613          	addi	a2,a2,1764 # ffffffffc0208528 <default_pmm_manager+0x38>
ffffffffc0204e4c:	45b5                	li	a1,13
ffffffffc0204e4e:	00003517          	auipc	a0,0x3
ffffffffc0204e52:	6fa50513          	addi	a0,a0,1786 # ffffffffc0208548 <default_pmm_manager+0x58>
ffffffffc0204e56:	bb2fb0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0204e5a <swapfs_read>:

int
swapfs_read(swap_entry_t entry, struct Page *page) {
ffffffffc0204e5a:	1141                	addi	sp,sp,-16
ffffffffc0204e5c:	e406                	sd	ra,8(sp)
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204e5e:	00855793          	srli	a5,a0,0x8
ffffffffc0204e62:	cbb1                	beqz	a5,ffffffffc0204eb6 <swapfs_read+0x5c>
ffffffffc0204e64:	000ae717          	auipc	a4,0xae
ffffffffc0204e68:	a4473703          	ld	a4,-1468(a4) # ffffffffc02b28a8 <max_swap_offset>
ffffffffc0204e6c:	04e7f563          	bgeu	a5,a4,ffffffffc0204eb6 <swapfs_read+0x5c>
    return page - pages + nbase;
ffffffffc0204e70:	000ae617          	auipc	a2,0xae
ffffffffc0204e74:	a1063603          	ld	a2,-1520(a2) # ffffffffc02b2880 <pages>
ffffffffc0204e78:	8d91                	sub	a1,a1,a2
ffffffffc0204e7a:	4065d613          	srai	a2,a1,0x6
ffffffffc0204e7e:	00004717          	auipc	a4,0x4
ffffffffc0204e82:	ff273703          	ld	a4,-14(a4) # ffffffffc0208e70 <nbase>
ffffffffc0204e86:	963a                	add	a2,a2,a4
    return KADDR(page2pa(page));
ffffffffc0204e88:	00c61713          	slli	a4,a2,0xc
ffffffffc0204e8c:	8331                	srli	a4,a4,0xc
ffffffffc0204e8e:	000ae697          	auipc	a3,0xae
ffffffffc0204e92:	9ea6b683          	ld	a3,-1558(a3) # ffffffffc02b2878 <npage>
ffffffffc0204e96:	0037959b          	slliw	a1,a5,0x3
    return page2ppn(page) << PGSHIFT;
ffffffffc0204e9a:	0632                	slli	a2,a2,0xc
    return KADDR(page2pa(page));
ffffffffc0204e9c:	02d77963          	bgeu	a4,a3,ffffffffc0204ece <swapfs_read+0x74>
}
ffffffffc0204ea0:	60a2                	ld	ra,8(sp)
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204ea2:	000ae797          	auipc	a5,0xae
ffffffffc0204ea6:	9ee7b783          	ld	a5,-1554(a5) # ffffffffc02b2890 <va_pa_offset>
ffffffffc0204eaa:	46a1                	li	a3,8
ffffffffc0204eac:	963e                	add	a2,a2,a5
ffffffffc0204eae:	4505                	li	a0,1
}
ffffffffc0204eb0:	0141                	addi	sp,sp,16
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204eb2:	e82fb06f          	j	ffffffffc0200534 <ide_read_secs>
ffffffffc0204eb6:	86aa                	mv	a3,a0
ffffffffc0204eb8:	00003617          	auipc	a2,0x3
ffffffffc0204ebc:	6a860613          	addi	a2,a2,1704 # ffffffffc0208560 <default_pmm_manager+0x70>
ffffffffc0204ec0:	45d1                	li	a1,20
ffffffffc0204ec2:	00003517          	auipc	a0,0x3
ffffffffc0204ec6:	68650513          	addi	a0,a0,1670 # ffffffffc0208548 <default_pmm_manager+0x58>
ffffffffc0204eca:	b3efb0ef          	jal	ra,ffffffffc0200208 <__panic>
ffffffffc0204ece:	86b2                	mv	a3,a2
ffffffffc0204ed0:	06900593          	li	a1,105
ffffffffc0204ed4:	00002617          	auipc	a2,0x2
ffffffffc0204ed8:	31460613          	addi	a2,a2,788 # ffffffffc02071e8 <commands+0x7c8>
ffffffffc0204edc:	00002517          	auipc	a0,0x2
ffffffffc0204ee0:	2bc50513          	addi	a0,a0,700 # ffffffffc0207198 <commands+0x778>
ffffffffc0204ee4:	b24fb0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0204ee8 <swapfs_write>:

int
swapfs_write(swap_entry_t entry, struct Page *page) {
ffffffffc0204ee8:	1141                	addi	sp,sp,-16
ffffffffc0204eea:	e406                	sd	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204eec:	00855793          	srli	a5,a0,0x8
ffffffffc0204ef0:	cbb1                	beqz	a5,ffffffffc0204f44 <swapfs_write+0x5c>
ffffffffc0204ef2:	000ae717          	auipc	a4,0xae
ffffffffc0204ef6:	9b673703          	ld	a4,-1610(a4) # ffffffffc02b28a8 <max_swap_offset>
ffffffffc0204efa:	04e7f563          	bgeu	a5,a4,ffffffffc0204f44 <swapfs_write+0x5c>
    return page - pages + nbase;
ffffffffc0204efe:	000ae617          	auipc	a2,0xae
ffffffffc0204f02:	98263603          	ld	a2,-1662(a2) # ffffffffc02b2880 <pages>
ffffffffc0204f06:	8d91                	sub	a1,a1,a2
ffffffffc0204f08:	4065d613          	srai	a2,a1,0x6
ffffffffc0204f0c:	00004717          	auipc	a4,0x4
ffffffffc0204f10:	f6473703          	ld	a4,-156(a4) # ffffffffc0208e70 <nbase>
ffffffffc0204f14:	963a                	add	a2,a2,a4
    return KADDR(page2pa(page));
ffffffffc0204f16:	00c61713          	slli	a4,a2,0xc
ffffffffc0204f1a:	8331                	srli	a4,a4,0xc
ffffffffc0204f1c:	000ae697          	auipc	a3,0xae
ffffffffc0204f20:	95c6b683          	ld	a3,-1700(a3) # ffffffffc02b2878 <npage>
ffffffffc0204f24:	0037959b          	slliw	a1,a5,0x3
    return page2ppn(page) << PGSHIFT;
ffffffffc0204f28:	0632                	slli	a2,a2,0xc
    return KADDR(page2pa(page));
ffffffffc0204f2a:	02d77963          	bgeu	a4,a3,ffffffffc0204f5c <swapfs_write+0x74>
}
ffffffffc0204f2e:	60a2                	ld	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204f30:	000ae797          	auipc	a5,0xae
ffffffffc0204f34:	9607b783          	ld	a5,-1696(a5) # ffffffffc02b2890 <va_pa_offset>
ffffffffc0204f38:	46a1                	li	a3,8
ffffffffc0204f3a:	963e                	add	a2,a2,a5
ffffffffc0204f3c:	4505                	li	a0,1
}
ffffffffc0204f3e:	0141                	addi	sp,sp,16
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204f40:	e18fb06f          	j	ffffffffc0200558 <ide_write_secs>
ffffffffc0204f44:	86aa                	mv	a3,a0
ffffffffc0204f46:	00003617          	auipc	a2,0x3
ffffffffc0204f4a:	61a60613          	addi	a2,a2,1562 # ffffffffc0208560 <default_pmm_manager+0x70>
ffffffffc0204f4e:	45e5                	li	a1,25
ffffffffc0204f50:	00003517          	auipc	a0,0x3
ffffffffc0204f54:	5f850513          	addi	a0,a0,1528 # ffffffffc0208548 <default_pmm_manager+0x58>
ffffffffc0204f58:	ab0fb0ef          	jal	ra,ffffffffc0200208 <__panic>
ffffffffc0204f5c:	86b2                	mv	a3,a2
ffffffffc0204f5e:	06900593          	li	a1,105
ffffffffc0204f62:	00002617          	auipc	a2,0x2
ffffffffc0204f66:	28660613          	addi	a2,a2,646 # ffffffffc02071e8 <commands+0x7c8>
ffffffffc0204f6a:	00002517          	auipc	a0,0x2
ffffffffc0204f6e:	22e50513          	addi	a0,a0,558 # ffffffffc0207198 <commands+0x778>
ffffffffc0204f72:	a96fb0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0204f76 <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc0204f76:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc0204f7a:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc0204f7e:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc0204f80:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc0204f82:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc0204f86:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc0204f8a:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc0204f8e:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc0204f92:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc0204f96:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc0204f9a:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc0204f9e:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc0204fa2:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc0204fa6:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc0204faa:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc0204fae:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc0204fb2:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc0204fb4:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc0204fb6:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc0204fba:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc0204fbe:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc0204fc2:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc0204fc6:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc0204fca:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc0204fce:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc0204fd2:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc0204fd6:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc0204fda:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc0204fde:	8082                	ret

ffffffffc0204fe0 <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0204fe0:	8526                	mv	a0,s1
	jalr s0
ffffffffc0204fe2:	9402                	jalr	s0

	jal do_exit
ffffffffc0204fe4:	532000ef          	jal	ra,ffffffffc0205516 <do_exit>

ffffffffc0204fe8 <alloc_proc>:
void forkrets(struct trapframe *tf);
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void) {
ffffffffc0204fe8:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct)); // 分配一个proc_struct结构体的内存
ffffffffc0204fea:	10800513          	li	a0,264
alloc_proc(void) {
ffffffffc0204fee:	e022                	sd	s0,0(sp)
ffffffffc0204ff0:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct)); // 分配一个proc_struct结构体的内存
ffffffffc0204ff2:	dedfe0ef          	jal	ra,ffffffffc0203dde <kmalloc>
ffffffffc0204ff6:	842a                	mv	s0,a0
    if (proc != NULL) {
ffffffffc0204ff8:	cd21                	beqz	a0,ffffffffc0205050 <alloc_proc+0x68>
     /*
     * 下面的字段（在LAB5中添加）需要在 proc_struct 中初始化  
     *       uint32_t wait_state;                        // 等待状态
     *       struct proc_struct *cptr, *yptr, *optr;     // 进程之间的关系
     */
        proc->state = PROC_UNINIT; // 初始化进程状态为未初始化
ffffffffc0204ffa:	57fd                	li	a5,-1
ffffffffc0204ffc:	1782                	slli	a5,a5,0x20
ffffffffc0204ffe:	e11c                	sd	a5,0(a0)
        proc->runs = 0; // 初始化进程运行次数为0
        proc->kstack = 0; // 初始化内核栈指针为0
        proc->need_resched = 0; // 初始化是否需要重新调度标志为0
        proc->parent = NULL; // 初始化父进程指针为NULL
        proc->mm = NULL; // 初始化内存管理结构体指针为NULL
        memset(&(proc->context), 0, sizeof(struct context)); // 将上下文结构体清零
ffffffffc0205000:	07000613          	li	a2,112
ffffffffc0205004:	4581                	li	a1,0
        proc->runs = 0; // 初始化进程运行次数为0
ffffffffc0205006:	00052423          	sw	zero,8(a0)
        proc->kstack = 0; // 初始化内核栈指针为0
ffffffffc020500a:	00053823          	sd	zero,16(a0)
        proc->need_resched = 0; // 初始化是否需要重新调度标志为0
ffffffffc020500e:	00053c23          	sd	zero,24(a0)
        proc->parent = NULL; // 初始化父进程指针为NULL
ffffffffc0205012:	02053023          	sd	zero,32(a0)
        proc->mm = NULL; // 初始化内存管理结构体指针为NULL
ffffffffc0205016:	02053423          	sd	zero,40(a0)
        memset(&(proc->context), 0, sizeof(struct context)); // 将上下文结构体清零
ffffffffc020501a:	03050513          	addi	a0,a0,48
ffffffffc020501e:	32c010ef          	jal	ra,ffffffffc020634a <memset>
        proc->tf = NULL; // 初始化trapframe指针为NULL
        proc->cr3 = boot_cr3; // 初始化CR3寄存器为boot_cr3
ffffffffc0205022:	000ae797          	auipc	a5,0xae
ffffffffc0205026:	8467b783          	ld	a5,-1978(a5) # ffffffffc02b2868 <boot_cr3>
        proc->tf = NULL; // 初始化trapframe指针为NULL
ffffffffc020502a:	0a043023          	sd	zero,160(s0)
        proc->cr3 = boot_cr3; // 初始化CR3寄存器为boot_cr3
ffffffffc020502e:	f45c                	sd	a5,168(s0)
        proc->flags = 0; // 初始化进程标志为0
ffffffffc0205030:	0a042823          	sw	zero,176(s0)
        memset(proc->name, 0, PROC_NAME_LEN); // 将进程名清零
ffffffffc0205034:	463d                	li	a2,15
ffffffffc0205036:	4581                	li	a1,0
ffffffffc0205038:	0b440513          	addi	a0,s0,180
ffffffffc020503c:	30e010ef          	jal	ra,ffffffffc020634a <memset>
        proc->wait_state = 0; // 初始化等待状态为0
ffffffffc0205040:	0e042623          	sw	zero,236(s0)
        proc->cptr = NULL; // 初始化子进程指针为NULL
ffffffffc0205044:	0e043823          	sd	zero,240(s0)
        proc->optr = NULL; // 初始化老兄弟进程指针为NULL
ffffffffc0205048:	10043023          	sd	zero,256(s0)
        proc->yptr = NULL; // 初始化年轻兄弟进程指针为NULL
ffffffffc020504c:	0e043c23          	sd	zero,248(s0)
    }
    return proc; // 返回分配并初始化的proc_struct结构体指针
}
ffffffffc0205050:	60a2                	ld	ra,8(sp)
ffffffffc0205052:	8522                	mv	a0,s0
ffffffffc0205054:	6402                	ld	s0,0(sp)
ffffffffc0205056:	0141                	addi	sp,sp,16
ffffffffc0205058:	8082                	ret

ffffffffc020505a <forkret>:
// forkret -- 新线程/进程的第一个内核入口点
// 注意: forkret 的地址在 copy_thread 函数中设置
// 在 switch_to 之后，当前进程将在这里执行。
static void
forkret(void) {
    forkrets(current->tf); // 调用 forkrets 函数，传入当前进程的 trapframe
ffffffffc020505a:	000ae797          	auipc	a5,0xae
ffffffffc020505e:	86e7b783          	ld	a5,-1938(a5) # ffffffffc02b28c8 <current>
ffffffffc0205062:	73c8                	ld	a0,160(a5)
ffffffffc0205064:	d13fb06f          	j	ffffffffc0200d76 <forkrets>

ffffffffc0205068 <user_main>:
static int
user_main(void *arg) {
#ifdef TEST
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE); // 如果定义了 TEST 宏，则执行 TEST 程序
#else
    KERNEL_EXECVE(exit); // 否则执行 exit 程序
ffffffffc0205068:	000ae797          	auipc	a5,0xae
ffffffffc020506c:	8607b783          	ld	a5,-1952(a5) # ffffffffc02b28c8 <current>
ffffffffc0205070:	43cc                	lw	a1,4(a5)
user_main(void *arg) {
ffffffffc0205072:	7139                	addi	sp,sp,-64
    KERNEL_EXECVE(exit); // 否则执行 exit 程序
ffffffffc0205074:	00003617          	auipc	a2,0x3
ffffffffc0205078:	50c60613          	addi	a2,a2,1292 # ffffffffc0208580 <default_pmm_manager+0x90>
ffffffffc020507c:	00003517          	auipc	a0,0x3
ffffffffc0205080:	50c50513          	addi	a0,a0,1292 # ffffffffc0208588 <default_pmm_manager+0x98>
user_main(void *arg) {
ffffffffc0205084:	fc06                	sd	ra,56(sp)
    KERNEL_EXECVE(exit); // 否则执行 exit 程序
ffffffffc0205086:	846fb0ef          	jal	ra,ffffffffc02000cc <cprintf>
ffffffffc020508a:	3fe06797          	auipc	a5,0x3fe06
ffffffffc020508e:	0ae78793          	addi	a5,a5,174 # b138 <_binary_obj___user_exit_out_size>
ffffffffc0205092:	e43e                	sd	a5,8(sp)
ffffffffc0205094:	00003517          	auipc	a0,0x3
ffffffffc0205098:	4ec50513          	addi	a0,a0,1260 # ffffffffc0208580 <default_pmm_manager+0x90>
ffffffffc020509c:	0003a797          	auipc	a5,0x3a
ffffffffc02050a0:	6ec78793          	addi	a5,a5,1772 # ffffffffc023f788 <_binary_obj___user_exit_out_start>
ffffffffc02050a4:	f03e                	sd	a5,32(sp)
ffffffffc02050a6:	f42a                	sd	a0,40(sp)
    int64_t ret=0, len = strlen(name); // 定义返回值变量和名称长度变量，并初始化
ffffffffc02050a8:	e802                	sd	zero,16(sp)
ffffffffc02050aa:	224010ef          	jal	ra,ffffffffc02062ce <strlen>
ffffffffc02050ae:	ec2a                	sd	a0,24(sp)
    asm volatile( // 内联汇编代码块
ffffffffc02050b0:	4511                	li	a0,4
ffffffffc02050b2:	55a2                	lw	a1,40(sp)
ffffffffc02050b4:	4662                	lw	a2,24(sp)
ffffffffc02050b6:	5682                	lw	a3,32(sp)
ffffffffc02050b8:	4722                	lw	a4,8(sp)
ffffffffc02050ba:	48a9                	li	a7,10
ffffffffc02050bc:	9002                	ebreak
ffffffffc02050be:	c82a                	sw	a0,16(sp)
    cprintf("ret = %d\n", ret); // 打印返回值
ffffffffc02050c0:	65c2                	ld	a1,16(sp)
ffffffffc02050c2:	00003517          	auipc	a0,0x3
ffffffffc02050c6:	4ee50513          	addi	a0,a0,1262 # ffffffffc02085b0 <default_pmm_manager+0xc0>
ffffffffc02050ca:	802fb0ef          	jal	ra,ffffffffc02000cc <cprintf>
#endif
    panic("user_main execve failed.\n"); // 如果 execve 失败，则触发 panic
ffffffffc02050ce:	00003617          	auipc	a2,0x3
ffffffffc02050d2:	4f260613          	addi	a2,a2,1266 # ffffffffc02085c0 <default_pmm_manager+0xd0>
ffffffffc02050d6:	36b00593          	li	a1,875
ffffffffc02050da:	00003517          	auipc	a0,0x3
ffffffffc02050de:	50650513          	addi	a0,a0,1286 # ffffffffc02085e0 <default_pmm_manager+0xf0>
ffffffffc02050e2:	926fb0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc02050e6 <put_pgdir>:
    return pa2page(PADDR(kva));
ffffffffc02050e6:	6d14                	ld	a3,24(a0)
put_pgdir(struct mm_struct *mm) {
ffffffffc02050e8:	1141                	addi	sp,sp,-16
ffffffffc02050ea:	e406                	sd	ra,8(sp)
ffffffffc02050ec:	c02007b7          	lui	a5,0xc0200
ffffffffc02050f0:	02f6ee63          	bltu	a3,a5,ffffffffc020512c <put_pgdir+0x46>
ffffffffc02050f4:	000ad517          	auipc	a0,0xad
ffffffffc02050f8:	79c53503          	ld	a0,1948(a0) # ffffffffc02b2890 <va_pa_offset>
ffffffffc02050fc:	8e89                	sub	a3,a3,a0
    if (PPN(pa) >= npage) {
ffffffffc02050fe:	82b1                	srli	a3,a3,0xc
ffffffffc0205100:	000ad797          	auipc	a5,0xad
ffffffffc0205104:	7787b783          	ld	a5,1912(a5) # ffffffffc02b2878 <npage>
ffffffffc0205108:	02f6fe63          	bgeu	a3,a5,ffffffffc0205144 <put_pgdir+0x5e>
    return &pages[PPN(pa) - nbase];
ffffffffc020510c:	00004517          	auipc	a0,0x4
ffffffffc0205110:	d6453503          	ld	a0,-668(a0) # ffffffffc0208e70 <nbase>
}
ffffffffc0205114:	60a2                	ld	ra,8(sp)
ffffffffc0205116:	8e89                	sub	a3,a3,a0
ffffffffc0205118:	069a                	slli	a3,a3,0x6
    free_page(kva2page(mm->pgdir)); // 释放页目录表的页
ffffffffc020511a:	000ad517          	auipc	a0,0xad
ffffffffc020511e:	76653503          	ld	a0,1894(a0) # ffffffffc02b2880 <pages>
ffffffffc0205122:	4585                	li	a1,1
ffffffffc0205124:	9536                	add	a0,a0,a3
}
ffffffffc0205126:	0141                	addi	sp,sp,16
    free_page(kva2page(mm->pgdir)); // 释放页目录表的页
ffffffffc0205128:	b02fc06f          	j	ffffffffc020142a <free_pages>
    return pa2page(PADDR(kva));
ffffffffc020512c:	00002617          	auipc	a2,0x2
ffffffffc0205130:	10c60613          	addi	a2,a2,268 # ffffffffc0207238 <commands+0x818>
ffffffffc0205134:	06e00593          	li	a1,110
ffffffffc0205138:	00002517          	auipc	a0,0x2
ffffffffc020513c:	06050513          	addi	a0,a0,96 # ffffffffc0207198 <commands+0x778>
ffffffffc0205140:	8c8fb0ef          	jal	ra,ffffffffc0200208 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0205144:	00002617          	auipc	a2,0x2
ffffffffc0205148:	03460613          	addi	a2,a2,52 # ffffffffc0207178 <commands+0x758>
ffffffffc020514c:	06200593          	li	a1,98
ffffffffc0205150:	00002517          	auipc	a0,0x2
ffffffffc0205154:	04850513          	addi	a0,a0,72 # ffffffffc0207198 <commands+0x778>
ffffffffc0205158:	8b0fb0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc020515c <proc_run>:
proc_run(struct proc_struct *proc) {
ffffffffc020515c:	7179                	addi	sp,sp,-48
ffffffffc020515e:	ec4a                	sd	s2,24(sp)
    if (proc != current) { // 如果目标进程不是当前进程
ffffffffc0205160:	000ad917          	auipc	s2,0xad
ffffffffc0205164:	76890913          	addi	s2,s2,1896 # ffffffffc02b28c8 <current>
proc_run(struct proc_struct *proc) {
ffffffffc0205168:	f026                	sd	s1,32(sp)
    if (proc != current) { // 如果目标进程不是当前进程
ffffffffc020516a:	00093483          	ld	s1,0(s2)
proc_run(struct proc_struct *proc) {
ffffffffc020516e:	f406                	sd	ra,40(sp)
ffffffffc0205170:	e84e                	sd	s3,16(sp)
    if (proc != current) { // 如果目标进程不是当前进程
ffffffffc0205172:	02a48863          	beq	s1,a0,ffffffffc02051a2 <proc_run+0x46>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205176:	100027f3          	csrr	a5,sstatus
ffffffffc020517a:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020517c:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020517e:	ef9d                	bnez	a5,ffffffffc02051bc <proc_run+0x60>

#define barrier() __asm__ __volatile__ ("fence" ::: "memory")

static inline void
lcr3(unsigned long cr3) {
    write_csr(satp, 0x8000000000000000 | (cr3 >> RISCV_PGSHIFT));
ffffffffc0205180:	755c                	ld	a5,168(a0)
ffffffffc0205182:	577d                	li	a4,-1
ffffffffc0205184:	177e                	slli	a4,a4,0x3f
ffffffffc0205186:	83b1                	srli	a5,a5,0xc
            current = proc; // 将当前进程设置为目标进程
ffffffffc0205188:	00a93023          	sd	a0,0(s2)
ffffffffc020518c:	8fd9                	or	a5,a5,a4
ffffffffc020518e:	18079073          	csrw	satp,a5
            switch_to(&(prev->context), &(next->context)); // 在两个进程之间进行上下文切换
ffffffffc0205192:	03050593          	addi	a1,a0,48
ffffffffc0205196:	03048513          	addi	a0,s1,48
ffffffffc020519a:	dddff0ef          	jal	ra,ffffffffc0204f76 <switch_to>
    if (flag) {
ffffffffc020519e:	00099863          	bnez	s3,ffffffffc02051ae <proc_run+0x52>
}
ffffffffc02051a2:	70a2                	ld	ra,40(sp)
ffffffffc02051a4:	7482                	ld	s1,32(sp)
ffffffffc02051a6:	6962                	ld	s2,24(sp)
ffffffffc02051a8:	69c2                	ld	s3,16(sp)
ffffffffc02051aa:	6145                	addi	sp,sp,48
ffffffffc02051ac:	8082                	ret
ffffffffc02051ae:	70a2                	ld	ra,40(sp)
ffffffffc02051b0:	7482                	ld	s1,32(sp)
ffffffffc02051b2:	6962                	ld	s2,24(sp)
ffffffffc02051b4:	69c2                	ld	s3,16(sp)
ffffffffc02051b6:	6145                	addi	sp,sp,48
        intr_enable();
ffffffffc02051b8:	c8afb06f          	j	ffffffffc0200642 <intr_enable>
ffffffffc02051bc:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02051be:	c8afb0ef          	jal	ra,ffffffffc0200648 <intr_disable>
        return 1;
ffffffffc02051c2:	6522                	ld	a0,8(sp)
ffffffffc02051c4:	4985                	li	s3,1
ffffffffc02051c6:	bf6d                	j	ffffffffc0205180 <proc_run+0x24>

ffffffffc02051c8 <do_fork>:
do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf) {
ffffffffc02051c8:	715d                	addi	sp,sp,-80
ffffffffc02051ca:	f84a                	sd	s2,48(sp)
    if (nr_process >= MAX_PROCESS) { // 如果当前进程数大于等于最大进程数
ffffffffc02051cc:	000ad917          	auipc	s2,0xad
ffffffffc02051d0:	71490913          	addi	s2,s2,1812 # ffffffffc02b28e0 <nr_process>
ffffffffc02051d4:	00092703          	lw	a4,0(s2)
do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf) {
ffffffffc02051d8:	e486                	sd	ra,72(sp)
ffffffffc02051da:	e0a2                	sd	s0,64(sp)
ffffffffc02051dc:	fc26                	sd	s1,56(sp)
ffffffffc02051de:	f44e                	sd	s3,40(sp)
ffffffffc02051e0:	f052                	sd	s4,32(sp)
ffffffffc02051e2:	ec56                	sd	s5,24(sp)
ffffffffc02051e4:	e85a                	sd	s6,16(sp)
ffffffffc02051e6:	e45e                	sd	s7,8(sp)
    if (nr_process >= MAX_PROCESS) { // 如果当前进程数大于等于最大进程数
ffffffffc02051e8:	6785                	lui	a5,0x1
ffffffffc02051ea:	26f75563          	bge	a4,a5,ffffffffc0205454 <do_fork+0x28c>
ffffffffc02051ee:	89ae                	mv	s3,a1
ffffffffc02051f0:	8432                	mv	s0,a2
    if((proc = alloc_proc()) == NULL) { // 调用 alloc_proc 分配一个进程结构体，如果失败则跳转到 fork_out 标签
ffffffffc02051f2:	df7ff0ef          	jal	ra,ffffffffc0204fe8 <alloc_proc>
ffffffffc02051f6:	84aa                	mv	s1,a0
ffffffffc02051f8:	24050c63          	beqz	a0,ffffffffc0205450 <do_fork+0x288>
    proc->parent = current; // 将子进程的父进程设置为当前进程,添加
ffffffffc02051fc:	000ad797          	auipc	a5,0xad
ffffffffc0205200:	6cc7b783          	ld	a5,1740(a5) # ffffffffc02b28c8 <current>
    assert(current->wait_state == 0); // 确保当前进程的 wait_state 为 0
ffffffffc0205204:	0ec7a703          	lw	a4,236(a5)
    proc->parent = current; // 将子进程的父进程设置为当前进程,添加
ffffffffc0205208:	f11c                	sd	a5,32(a0)
    assert(current->wait_state == 0); // 确保当前进程的 wait_state 为 0
ffffffffc020520a:	24071a63          	bnez	a4,ffffffffc020545e <do_fork+0x296>
    struct Page *page = alloc_pages(KSTACKPAGE); // 分配KSTACKPAGE大小的页
ffffffffc020520e:	4509                	li	a0,2
ffffffffc0205210:	988fc0ef          	jal	ra,ffffffffc0201398 <alloc_pages>
    if (page != NULL) { // 如果分配成功
ffffffffc0205214:	22050b63          	beqz	a0,ffffffffc020544a <do_fork+0x282>
    return page - pages + nbase;
ffffffffc0205218:	000adb17          	auipc	s6,0xad
ffffffffc020521c:	668b0b13          	addi	s6,s6,1640 # ffffffffc02b2880 <pages>
ffffffffc0205220:	000b3683          	ld	a3,0(s6)
ffffffffc0205224:	00004a17          	auipc	s4,0x4
ffffffffc0205228:	c4ca3a03          	ld	s4,-948(s4) # ffffffffc0208e70 <nbase>
    return KADDR(page2pa(page));
ffffffffc020522c:	000adb97          	auipc	s7,0xad
ffffffffc0205230:	64cb8b93          	addi	s7,s7,1612 # ffffffffc02b2878 <npage>
    return page - pages + nbase;
ffffffffc0205234:	40d506b3          	sub	a3,a0,a3
ffffffffc0205238:	8699                	srai	a3,a3,0x6
ffffffffc020523a:	96d2                	add	a3,a3,s4
    return KADDR(page2pa(page));
ffffffffc020523c:	000bb703          	ld	a4,0(s7)
ffffffffc0205240:	00c69793          	slli	a5,a3,0xc
ffffffffc0205244:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0205246:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0205248:	22e7fb63          	bgeu	a5,a4,ffffffffc020547e <do_fork+0x2b6>
ffffffffc020524c:	000ada97          	auipc	s5,0xad
ffffffffc0205250:	644a8a93          	addi	s5,s5,1604 # ffffffffc02b2890 <va_pa_offset>
ffffffffc0205254:	000ab783          	ld	a5,0(s5)
    if(cow_copy_mm(proc) != 0) {
ffffffffc0205258:	8526                	mv	a0,s1
ffffffffc020525a:	96be                	add	a3,a3,a5
        proc->kstack = (uintptr_t)page2kva(page); // 将页的虚拟地址赋值给进程的kstack字段
ffffffffc020525c:	e894                	sd	a3,16(s1)
    if(cow_copy_mm(proc) != 0) {
ffffffffc020525e:	db5fb0ef          	jal	ra,ffffffffc0201012 <cow_copy_mm>
ffffffffc0205262:	1a051d63          	bnez	a0,ffffffffc020541c <do_fork+0x254>
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1; // 将新进程的trapframe设置为内核栈顶
ffffffffc0205266:	0104b303          	ld	t1,16(s1)
ffffffffc020526a:	6709                	lui	a4,0x2
ffffffffc020526c:	ee070713          	addi	a4,a4,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x7cd8>
ffffffffc0205270:	971a                	add	a4,a4,t1
    *(proc->tf) = *tf; // 复制当前进程的trapframe到新进程的trapframe
ffffffffc0205272:	8622                	mv	a2,s0
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1; // 将新进程的trapframe设置为内核栈顶
ffffffffc0205274:	f0d8                	sd	a4,160(s1)
    *(proc->tf) = *tf; // 复制当前进程的trapframe到新进程的trapframe
ffffffffc0205276:	87ba                	mv	a5,a4
ffffffffc0205278:	12040893          	addi	a7,s0,288
ffffffffc020527c:	00063803          	ld	a6,0(a2)
ffffffffc0205280:	6608                	ld	a0,8(a2)
ffffffffc0205282:	6a0c                	ld	a1,16(a2)
ffffffffc0205284:	6e14                	ld	a3,24(a2)
ffffffffc0205286:	0107b023          	sd	a6,0(a5)
ffffffffc020528a:	e788                	sd	a0,8(a5)
ffffffffc020528c:	eb8c                	sd	a1,16(a5)
ffffffffc020528e:	ef94                	sd	a3,24(a5)
ffffffffc0205290:	02060613          	addi	a2,a2,32
ffffffffc0205294:	02078793          	addi	a5,a5,32
ffffffffc0205298:	ff1612e3          	bne	a2,a7,ffffffffc020527c <do_fork+0xb4>
    proc->tf->gpr.a0 = 0; // 将新进程的trapframe的a0寄存器设置为0
ffffffffc020529c:	04073823          	sd	zero,80(a4)
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf - 4 : esp; // 设置新进程的栈指针
ffffffffc02052a0:	12098b63          	beqz	s3,ffffffffc02053d6 <do_fork+0x20e>
ffffffffc02052a4:	01373823          	sd	s3,16(a4)
    proc->context.ra = (uintptr_t)forkret; // 设置新进程的返回地址为forkret函数
ffffffffc02052a8:	00000797          	auipc	a5,0x0
ffffffffc02052ac:	db278793          	addi	a5,a5,-590 # ffffffffc020505a <forkret>
ffffffffc02052b0:	f89c                	sd	a5,48(s1)
    proc->context.sp = (uintptr_t)(proc->tf); // 设置新进程的栈指针为trapframe的地址
ffffffffc02052b2:	fc98                	sd	a4,56(s1)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02052b4:	100027f3          	csrr	a5,sstatus
ffffffffc02052b8:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02052ba:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02052bc:	12079f63          	bnez	a5,ffffffffc02053fa <do_fork+0x232>
    if (++ last_pid >= MAX_PID) { // 如果最后一个分配的PID加1后大于等于最大PID
ffffffffc02052c0:	000a2817          	auipc	a6,0xa2
ffffffffc02052c4:	0c080813          	addi	a6,a6,192 # ffffffffc02a7380 <last_pid.1>
ffffffffc02052c8:	00082783          	lw	a5,0(a6)
ffffffffc02052cc:	6709                	lui	a4,0x2
ffffffffc02052ce:	0017851b          	addiw	a0,a5,1
ffffffffc02052d2:	00a82023          	sw	a0,0(a6)
ffffffffc02052d6:	08e55963          	bge	a0,a4,ffffffffc0205368 <do_fork+0x1a0>
    if (last_pid >= next_safe) { // 如果最后一个分配的PID大于等于下一个安全的PID
ffffffffc02052da:	000a2317          	auipc	t1,0xa2
ffffffffc02052de:	0aa30313          	addi	t1,t1,170 # ffffffffc02a7384 <next_safe.0>
ffffffffc02052e2:	00032783          	lw	a5,0(t1)
ffffffffc02052e6:	000ad417          	auipc	s0,0xad
ffffffffc02052ea:	55a40413          	addi	s0,s0,1370 # ffffffffc02b2840 <proc_list>
ffffffffc02052ee:	08f55563          	bge	a0,a5,ffffffffc0205378 <do_fork+0x1b0>
        proc->pid = get_pid(); // 调用 get_pid 分配一个唯一的进程 ID
ffffffffc02052f2:	c0c8                	sw	a0,4(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link)); // 将进程添加到哈希列表中
ffffffffc02052f4:	45a9                	li	a1,10
ffffffffc02052f6:	2501                	sext.w	a0,a0
ffffffffc02052f8:	46a010ef          	jal	ra,ffffffffc0206762 <hash32>
ffffffffc02052fc:	02051793          	slli	a5,a0,0x20
ffffffffc0205300:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0205304:	000a9797          	auipc	a5,0xa9
ffffffffc0205308:	53c78793          	addi	a5,a5,1340 # ffffffffc02ae840 <hash_list>
ffffffffc020530c:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc020530e:	650c                	ld	a1,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL) { // 如果父进程的子进程不为空，则将当前进程的老兄弟指针指向父进程的子进程
ffffffffc0205310:	7094                	ld	a3,32(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link)); // 将进程添加到哈希列表中
ffffffffc0205312:	0d848793          	addi	a5,s1,216
    prev->next = next->prev = elm;
ffffffffc0205316:	e19c                	sd	a5,0(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc0205318:	6410                	ld	a2,8(s0)
    prev->next = next->prev = elm;
ffffffffc020531a:	e51c                	sd	a5,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL) { // 如果父进程的子进程不为空，则将当前进程的老兄弟指针指向父进程的子进程
ffffffffc020531c:	7af8                	ld	a4,240(a3)
    list_add(&proc_list, &(proc->list_link)); // 将进程插入到进程链表中
ffffffffc020531e:	0c848793          	addi	a5,s1,200
    elm->next = next;
ffffffffc0205322:	f0ec                	sd	a1,224(s1)
    elm->prev = prev;
ffffffffc0205324:	ece8                	sd	a0,216(s1)
    prev->next = next->prev = elm;
ffffffffc0205326:	e21c                	sd	a5,0(a2)
ffffffffc0205328:	e41c                	sd	a5,8(s0)
    elm->next = next;
ffffffffc020532a:	e8f0                	sd	a2,208(s1)
    elm->prev = prev;
ffffffffc020532c:	e4e0                	sd	s0,200(s1)
    proc->yptr = NULL; // 初始化年轻兄弟进程指针为NULL
ffffffffc020532e:	0e04bc23          	sd	zero,248(s1)
    if ((proc->optr = proc->parent->cptr) != NULL) { // 如果父进程的子进程不为空，则将当前进程的老兄弟指针指向父进程的子进程
ffffffffc0205332:	10e4b023          	sd	a4,256(s1)
ffffffffc0205336:	c311                	beqz	a4,ffffffffc020533a <do_fork+0x172>
        proc->optr->yptr = proc; // 将父进程的子进程的年轻兄弟指针指向当前进程
ffffffffc0205338:	ff64                	sd	s1,248(a4)
    nr_process ++; // 进程数量加1
ffffffffc020533a:	00092783          	lw	a5,0(s2)
    proc->parent->cptr = proc; // 将父进程的子进程指针指向当前进程
ffffffffc020533e:	fae4                	sd	s1,240(a3)
    nr_process ++; // 进程数量加1
ffffffffc0205340:	2785                	addiw	a5,a5,1
ffffffffc0205342:	00f92023          	sw	a5,0(s2)
    if (flag) {
ffffffffc0205346:	0a099e63          	bnez	s3,ffffffffc0205402 <do_fork+0x23a>
    wakeup_proc(proc); // 调用 wakeup_proc 使新子进程变为 RUNNABLE
ffffffffc020534a:	8526                	mv	a0,s1
ffffffffc020534c:	597000ef          	jal	ra,ffffffffc02060e2 <wakeup_proc>
    ret = proc->pid; // 使用子进程的 pid 设置返回值
ffffffffc0205350:	40c8                	lw	a0,4(s1)
}
ffffffffc0205352:	60a6                	ld	ra,72(sp)
ffffffffc0205354:	6406                	ld	s0,64(sp)
ffffffffc0205356:	74e2                	ld	s1,56(sp)
ffffffffc0205358:	7942                	ld	s2,48(sp)
ffffffffc020535a:	79a2                	ld	s3,40(sp)
ffffffffc020535c:	7a02                	ld	s4,32(sp)
ffffffffc020535e:	6ae2                	ld	s5,24(sp)
ffffffffc0205360:	6b42                	ld	s6,16(sp)
ffffffffc0205362:	6ba2                	ld	s7,8(sp)
ffffffffc0205364:	6161                	addi	sp,sp,80
ffffffffc0205366:	8082                	ret
        last_pid = 1; // 将最后一个分配的PID重置为1
ffffffffc0205368:	4785                	li	a5,1
ffffffffc020536a:	00f82023          	sw	a5,0(a6)
        goto inside; // 跳转到inside标签
ffffffffc020536e:	4505                	li	a0,1
ffffffffc0205370:	000a2317          	auipc	t1,0xa2
ffffffffc0205374:	01430313          	addi	t1,t1,20 # ffffffffc02a7384 <next_safe.0>
    return listelm->next;
ffffffffc0205378:	000ad417          	auipc	s0,0xad
ffffffffc020537c:	4c840413          	addi	s0,s0,1224 # ffffffffc02b2840 <proc_list>
ffffffffc0205380:	00843e03          	ld	t3,8(s0)
        next_safe = MAX_PID; // 将下一个安全的PID重置为最大PID
ffffffffc0205384:	6789                	lui	a5,0x2
ffffffffc0205386:	00f32023          	sw	a5,0(t1)
ffffffffc020538a:	86aa                	mv	a3,a0
ffffffffc020538c:	4581                	li	a1,0
        while ((le = list_next(le)) != list) { // 遍历链表中的每个元素
ffffffffc020538e:	6e89                	lui	t4,0x2
ffffffffc0205390:	088e0163          	beq	t3,s0,ffffffffc0205412 <do_fork+0x24a>
ffffffffc0205394:	88ae                	mv	a7,a1
ffffffffc0205396:	87f2                	mv	a5,t3
ffffffffc0205398:	6609                	lui	a2,0x2
ffffffffc020539a:	a811                	j	ffffffffc02053ae <do_fork+0x1e6>
            else if (proc->pid > last_pid && next_safe > proc->pid) { // 如果进程的PID大于最后一个分配的PID且下一个安全的PID大于进程的PID
ffffffffc020539c:	00e6d663          	bge	a3,a4,ffffffffc02053a8 <do_fork+0x1e0>
ffffffffc02053a0:	00c75463          	bge	a4,a2,ffffffffc02053a8 <do_fork+0x1e0>
ffffffffc02053a4:	863a                	mv	a2,a4
ffffffffc02053a6:	4885                	li	a7,1
ffffffffc02053a8:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list) { // 遍历链表中的每个元素
ffffffffc02053aa:	00878d63          	beq	a5,s0,ffffffffc02053c4 <do_fork+0x1fc>
            if (proc->pid == last_pid) { // 如果进程的PID等于最后一个分配的PID
ffffffffc02053ae:	f3c7a703          	lw	a4,-196(a5) # 1f3c <_binary_obj___user_faultread_out_size-0x7c7c>
ffffffffc02053b2:	fed715e3          	bne	a4,a3,ffffffffc020539c <do_fork+0x1d4>
                if (++ last_pid >= next_safe) { // 如果最后一个分配的PID加1后大于等于下一个安全的PID
ffffffffc02053b6:	2685                	addiw	a3,a3,1
ffffffffc02053b8:	04c6d863          	bge	a3,a2,ffffffffc0205408 <do_fork+0x240>
ffffffffc02053bc:	679c                	ld	a5,8(a5)
ffffffffc02053be:	4585                	li	a1,1
        while ((le = list_next(le)) != list) { // 遍历链表中的每个元素
ffffffffc02053c0:	fe8797e3          	bne	a5,s0,ffffffffc02053ae <do_fork+0x1e6>
ffffffffc02053c4:	c581                	beqz	a1,ffffffffc02053cc <do_fork+0x204>
ffffffffc02053c6:	00d82023          	sw	a3,0(a6)
ffffffffc02053ca:	8536                	mv	a0,a3
ffffffffc02053cc:	f20883e3          	beqz	a7,ffffffffc02052f2 <do_fork+0x12a>
ffffffffc02053d0:	00c32023          	sw	a2,0(t1)
ffffffffc02053d4:	bf39                	j	ffffffffc02052f2 <do_fork+0x12a>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf - 4 : esp; // 设置新进程的栈指针
ffffffffc02053d6:	6989                	lui	s3,0x2
ffffffffc02053d8:	edc98993          	addi	s3,s3,-292 # 1edc <_binary_obj___user_faultread_out_size-0x7cdc>
ffffffffc02053dc:	999a                	add	s3,s3,t1
ffffffffc02053de:	01373823          	sd	s3,16(a4) # 2010 <_binary_obj___user_faultread_out_size-0x7ba8>
    proc->context.ra = (uintptr_t)forkret; // 设置新进程的返回地址为forkret函数
ffffffffc02053e2:	00000797          	auipc	a5,0x0
ffffffffc02053e6:	c7878793          	addi	a5,a5,-904 # ffffffffc020505a <forkret>
ffffffffc02053ea:	f89c                	sd	a5,48(s1)
    proc->context.sp = (uintptr_t)(proc->tf); // 设置新进程的栈指针为trapframe的地址
ffffffffc02053ec:	fc98                	sd	a4,56(s1)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02053ee:	100027f3          	csrr	a5,sstatus
ffffffffc02053f2:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02053f4:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02053f6:	ec0785e3          	beqz	a5,ffffffffc02052c0 <do_fork+0xf8>
        intr_disable();
ffffffffc02053fa:	a4efb0ef          	jal	ra,ffffffffc0200648 <intr_disable>
        return 1;
ffffffffc02053fe:	4985                	li	s3,1
ffffffffc0205400:	b5c1                	j	ffffffffc02052c0 <do_fork+0xf8>
        intr_enable();
ffffffffc0205402:	a40fb0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc0205406:	b791                	j	ffffffffc020534a <do_fork+0x182>
                    if (last_pid >= MAX_PID) { // 如果最后一个分配的PID大于等于最大PID
ffffffffc0205408:	01d6c363          	blt	a3,t4,ffffffffc020540e <do_fork+0x246>
                        last_pid = 1; // 将最后一个分配的PID重置为1
ffffffffc020540c:	4685                	li	a3,1
                    goto repeat; // 跳转到repeat标签
ffffffffc020540e:	4585                	li	a1,1
ffffffffc0205410:	b741                	j	ffffffffc0205390 <do_fork+0x1c8>
ffffffffc0205412:	c1b9                	beqz	a1,ffffffffc0205458 <do_fork+0x290>
ffffffffc0205414:	00d82023          	sw	a3,0(a6)
    return last_pid; // 返回最后一个分配的PID
ffffffffc0205418:	8536                	mv	a0,a3
ffffffffc020541a:	bde1                	j	ffffffffc02052f2 <do_fork+0x12a>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE); // 释放进程内核栈的页
ffffffffc020541c:	6894                	ld	a3,16(s1)
    return pa2page(PADDR(kva));
ffffffffc020541e:	c02007b7          	lui	a5,0xc0200
ffffffffc0205422:	08f6e663          	bltu	a3,a5,ffffffffc02054ae <do_fork+0x2e6>
ffffffffc0205426:	000ab783          	ld	a5,0(s5)
    if (PPN(pa) >= npage) {
ffffffffc020542a:	000bb703          	ld	a4,0(s7)
    return pa2page(PADDR(kva));
ffffffffc020542e:	40f687b3          	sub	a5,a3,a5
    if (PPN(pa) >= npage) {
ffffffffc0205432:	83b1                	srli	a5,a5,0xc
ffffffffc0205434:	06e7f163          	bgeu	a5,a4,ffffffffc0205496 <do_fork+0x2ce>
    return &pages[PPN(pa) - nbase];
ffffffffc0205438:	000b3503          	ld	a0,0(s6)
ffffffffc020543c:	414787b3          	sub	a5,a5,s4
ffffffffc0205440:	079a                	slli	a5,a5,0x6
ffffffffc0205442:	4589                	li	a1,2
ffffffffc0205444:	953e                	add	a0,a0,a5
ffffffffc0205446:	fe5fb0ef          	jal	ra,ffffffffc020142a <free_pages>
    kfree(proc); // 调用 kfree 释放子进程的内存
ffffffffc020544a:	8526                	mv	a0,s1
ffffffffc020544c:	a43fe0ef          	jal	ra,ffffffffc0203e8e <kfree>
    ret = -E_NO_MEM; // 初始化返回值为内存不足错误码
ffffffffc0205450:	5571                	li	a0,-4
    return ret; // 返回结果
ffffffffc0205452:	b701                	j	ffffffffc0205352 <do_fork+0x18a>
    int ret = -E_NO_FREE_PROC; // 初始化返回值为没有可用进程错误码
ffffffffc0205454:	556d                	li	a0,-5
ffffffffc0205456:	bdf5                	j	ffffffffc0205352 <do_fork+0x18a>
    return last_pid; // 返回最后一个分配的PID
ffffffffc0205458:	00082503          	lw	a0,0(a6)
ffffffffc020545c:	bd59                	j	ffffffffc02052f2 <do_fork+0x12a>
    assert(current->wait_state == 0); // 确保当前进程的 wait_state 为 0
ffffffffc020545e:	00003697          	auipc	a3,0x3
ffffffffc0205462:	19a68693          	addi	a3,a3,410 # ffffffffc02085f8 <default_pmm_manager+0x108>
ffffffffc0205466:	00002617          	auipc	a2,0x2
ffffffffc020546a:	9ca60613          	addi	a2,a2,-1590 # ffffffffc0206e30 <commands+0x410>
ffffffffc020546e:	1b600593          	li	a1,438
ffffffffc0205472:	00003517          	auipc	a0,0x3
ffffffffc0205476:	16e50513          	addi	a0,a0,366 # ffffffffc02085e0 <default_pmm_manager+0xf0>
ffffffffc020547a:	d8ffa0ef          	jal	ra,ffffffffc0200208 <__panic>
    return KADDR(page2pa(page));
ffffffffc020547e:	00002617          	auipc	a2,0x2
ffffffffc0205482:	d6a60613          	addi	a2,a2,-662 # ffffffffc02071e8 <commands+0x7c8>
ffffffffc0205486:	06900593          	li	a1,105
ffffffffc020548a:	00002517          	auipc	a0,0x2
ffffffffc020548e:	d0e50513          	addi	a0,a0,-754 # ffffffffc0207198 <commands+0x778>
ffffffffc0205492:	d77fa0ef          	jal	ra,ffffffffc0200208 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0205496:	00002617          	auipc	a2,0x2
ffffffffc020549a:	ce260613          	addi	a2,a2,-798 # ffffffffc0207178 <commands+0x758>
ffffffffc020549e:	06200593          	li	a1,98
ffffffffc02054a2:	00002517          	auipc	a0,0x2
ffffffffc02054a6:	cf650513          	addi	a0,a0,-778 # ffffffffc0207198 <commands+0x778>
ffffffffc02054aa:	d5ffa0ef          	jal	ra,ffffffffc0200208 <__panic>
    return pa2page(PADDR(kva));
ffffffffc02054ae:	00002617          	auipc	a2,0x2
ffffffffc02054b2:	d8a60613          	addi	a2,a2,-630 # ffffffffc0207238 <commands+0x818>
ffffffffc02054b6:	06e00593          	li	a1,110
ffffffffc02054ba:	00002517          	auipc	a0,0x2
ffffffffc02054be:	cde50513          	addi	a0,a0,-802 # ffffffffc0207198 <commands+0x778>
ffffffffc02054c2:	d47fa0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc02054c6 <kernel_thread>:
kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags) {
ffffffffc02054c6:	7129                	addi	sp,sp,-320
ffffffffc02054c8:	fa22                	sd	s0,304(sp)
ffffffffc02054ca:	f626                	sd	s1,296(sp)
ffffffffc02054cc:	f24a                	sd	s2,288(sp)
ffffffffc02054ce:	84ae                	mv	s1,a1
ffffffffc02054d0:	892a                	mv	s2,a0
ffffffffc02054d2:	8432                	mv	s0,a2
    memset(&tf, 0, sizeof(struct trapframe)); // 将trapframe结构体清零
ffffffffc02054d4:	4581                	li	a1,0
ffffffffc02054d6:	12000613          	li	a2,288
ffffffffc02054da:	850a                	mv	a0,sp
kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags) {
ffffffffc02054dc:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe)); // 将trapframe结构体清零
ffffffffc02054de:	66d000ef          	jal	ra,ffffffffc020634a <memset>
    tf.gpr.s0 = (uintptr_t)fn; // 将函数指针fn的地址赋值给trapframe的s0寄存器
ffffffffc02054e2:	e0ca                	sd	s2,64(sp)
    tf.gpr.s1 = (uintptr_t)arg; // 将参数arg的地址赋值给trapframe的s1寄存器
ffffffffc02054e4:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE; // 设置trapframe的status寄存器
ffffffffc02054e6:	100027f3          	csrr	a5,sstatus
ffffffffc02054ea:	edd7f793          	andi	a5,a5,-291
ffffffffc02054ee:	1207e793          	ori	a5,a5,288
ffffffffc02054f2:	e23e                	sd	a5,256(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf); // 调用do_fork函数创建子进程，并返回子进程的pid
ffffffffc02054f4:	860a                	mv	a2,sp
ffffffffc02054f6:	10046513          	ori	a0,s0,256
    tf.epc = (uintptr_t)kernel_thread_entry; // 将kernel_thread_entry的地址赋值给trapframe的epc寄存器
ffffffffc02054fa:	00000797          	auipc	a5,0x0
ffffffffc02054fe:	ae678793          	addi	a5,a5,-1306 # ffffffffc0204fe0 <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf); // 调用do_fork函数创建子进程，并返回子进程的pid
ffffffffc0205502:	4581                	li	a1,0
    tf.epc = (uintptr_t)kernel_thread_entry; // 将kernel_thread_entry的地址赋值给trapframe的epc寄存器
ffffffffc0205504:	e63e                	sd	a5,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf); // 调用do_fork函数创建子进程，并返回子进程的pid
ffffffffc0205506:	cc3ff0ef          	jal	ra,ffffffffc02051c8 <do_fork>
}
ffffffffc020550a:	70f2                	ld	ra,312(sp)
ffffffffc020550c:	7452                	ld	s0,304(sp)
ffffffffc020550e:	74b2                	ld	s1,296(sp)
ffffffffc0205510:	7912                	ld	s2,288(sp)
ffffffffc0205512:	6131                	addi	sp,sp,320
ffffffffc0205514:	8082                	ret

ffffffffc0205516 <do_exit>:
do_exit(int error_code) {
ffffffffc0205516:	7179                	addi	sp,sp,-48
ffffffffc0205518:	f022                	sd	s0,32(sp)
    if (current == idleproc) { // 如果当前进程是 idleproc，则触发 panic
ffffffffc020551a:	000ad417          	auipc	s0,0xad
ffffffffc020551e:	3ae40413          	addi	s0,s0,942 # ffffffffc02b28c8 <current>
ffffffffc0205522:	601c                	ld	a5,0(s0)
do_exit(int error_code) {
ffffffffc0205524:	f406                	sd	ra,40(sp)
ffffffffc0205526:	ec26                	sd	s1,24(sp)
ffffffffc0205528:	e84a                	sd	s2,16(sp)
ffffffffc020552a:	e44e                	sd	s3,8(sp)
ffffffffc020552c:	e052                	sd	s4,0(sp)
    if (current == idleproc) { // 如果当前进程是 idleproc，则触发 panic
ffffffffc020552e:	000ad717          	auipc	a4,0xad
ffffffffc0205532:	3a273703          	ld	a4,930(a4) # ffffffffc02b28d0 <idleproc>
ffffffffc0205536:	0ce78c63          	beq	a5,a4,ffffffffc020560e <do_exit+0xf8>
    if (current == initproc) { // 如果当前进程是 initproc，则触发 panic
ffffffffc020553a:	000ad497          	auipc	s1,0xad
ffffffffc020553e:	39e48493          	addi	s1,s1,926 # ffffffffc02b28d8 <initproc>
ffffffffc0205542:	6098                	ld	a4,0(s1)
ffffffffc0205544:	0ee78b63          	beq	a5,a4,ffffffffc020563a <do_exit+0x124>
    struct mm_struct *mm = current->mm; // 获取当前进程的内存管理结构体
ffffffffc0205548:	0287b983          	ld	s3,40(a5)
ffffffffc020554c:	892a                	mv	s2,a0
    if (mm != NULL) { // 如果内存管理结构体不为空
ffffffffc020554e:	02098663          	beqz	s3,ffffffffc020557a <do_exit+0x64>
ffffffffc0205552:	000ad797          	auipc	a5,0xad
ffffffffc0205556:	3167b783          	ld	a5,790(a5) # ffffffffc02b2868 <boot_cr3>
ffffffffc020555a:	577d                	li	a4,-1
ffffffffc020555c:	177e                	slli	a4,a4,0x3f
ffffffffc020555e:	83b1                	srli	a5,a5,0xc
ffffffffc0205560:	8fd9                	or	a5,a5,a4
ffffffffc0205562:	18079073          	csrw	satp,a5
    mm->mm_count -= 1;
ffffffffc0205566:	0309a783          	lw	a5,48(s3)
ffffffffc020556a:	fff7871b          	addiw	a4,a5,-1
ffffffffc020556e:	02e9a823          	sw	a4,48(s3)
        if (mm_count_dec(mm) == 0) { // 如果内存管理结构体的引用计数为0
ffffffffc0205572:	cb55                	beqz	a4,ffffffffc0205626 <do_exit+0x110>
        current->mm = NULL; // 将当前进程的内存管理结构体指针置为空
ffffffffc0205574:	601c                	ld	a5,0(s0)
ffffffffc0205576:	0207b423          	sd	zero,40(a5)
    current->state = PROC_ZOMBIE; // 将当前进程的状态设置为 PROC_ZOMBIE
ffffffffc020557a:	601c                	ld	a5,0(s0)
ffffffffc020557c:	470d                	li	a4,3
ffffffffc020557e:	c398                	sw	a4,0(a5)
    current->exit_code = error_code; // 设置当前进程的退出代码
ffffffffc0205580:	0f27a423          	sw	s2,232(a5)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205584:	100027f3          	csrr	a5,sstatus
ffffffffc0205588:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020558a:	4a01                	li	s4,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020558c:	e3f9                	bnez	a5,ffffffffc0205652 <do_exit+0x13c>
        proc = current->parent; // 获取当前进程的父进程
ffffffffc020558e:	6018                	ld	a4,0(s0)
        if (proc->wait_state == WT_CHILD) { // 如果父进程的等待状态为 WT_CHILD
ffffffffc0205590:	800007b7          	lui	a5,0x80000
ffffffffc0205594:	0785                	addi	a5,a5,1
        proc = current->parent; // 获取当前进程的父进程
ffffffffc0205596:	7308                	ld	a0,32(a4)
        if (proc->wait_state == WT_CHILD) { // 如果父进程的等待状态为 WT_CHILD
ffffffffc0205598:	0ec52703          	lw	a4,236(a0)
ffffffffc020559c:	0af70f63          	beq	a4,a5,ffffffffc020565a <do_exit+0x144>
        while (current->cptr != NULL) { // 遍历当前进程的所有子进程
ffffffffc02055a0:	6018                	ld	a4,0(s0)
ffffffffc02055a2:	7b7c                	ld	a5,240(a4)
ffffffffc02055a4:	c3a1                	beqz	a5,ffffffffc02055e4 <do_exit+0xce>
                if (initproc->wait_state == WT_CHILD) { // 如果 initproc 的等待状态为 WT_CHILD
ffffffffc02055a6:	800009b7          	lui	s3,0x80000
            if (proc->state == PROC_ZOMBIE) { // 如果子进程的状态为 PROC_ZOMBIE
ffffffffc02055aa:	490d                	li	s2,3
                if (initproc->wait_state == WT_CHILD) { // 如果 initproc 的等待状态为 WT_CHILD
ffffffffc02055ac:	0985                	addi	s3,s3,1
ffffffffc02055ae:	a021                	j	ffffffffc02055b6 <do_exit+0xa0>
        while (current->cptr != NULL) { // 遍历当前进程的所有子进程
ffffffffc02055b0:	6018                	ld	a4,0(s0)
ffffffffc02055b2:	7b7c                	ld	a5,240(a4)
ffffffffc02055b4:	cb85                	beqz	a5,ffffffffc02055e4 <do_exit+0xce>
            current->cptr = proc->optr; // 将当前进程的子进程指针指向下一个兄弟进程
ffffffffc02055b6:	1007b683          	ld	a3,256(a5) # ffffffff80000100 <_binary_obj___user_exit_out_size+0xffffffff7fff4fc8>
            if ((proc->optr = initproc->cptr) != NULL) { // 如果 initproc 有子进程
ffffffffc02055ba:	6088                	ld	a0,0(s1)
            current->cptr = proc->optr; // 将当前进程的子进程指针指向下一个兄弟进程
ffffffffc02055bc:	fb74                	sd	a3,240(a4)
            if ((proc->optr = initproc->cptr) != NULL) { // 如果 initproc 有子进程
ffffffffc02055be:	7978                	ld	a4,240(a0)
            proc->yptr = NULL; // 将子进程的年轻兄弟指针置为空
ffffffffc02055c0:	0e07bc23          	sd	zero,248(a5)
            if ((proc->optr = initproc->cptr) != NULL) { // 如果 initproc 有子进程
ffffffffc02055c4:	10e7b023          	sd	a4,256(a5)
ffffffffc02055c8:	c311                	beqz	a4,ffffffffc02055cc <do_exit+0xb6>
                initproc->cptr->yptr = proc; // 将 initproc 的子进程的年轻兄弟指针指向当前子进程
ffffffffc02055ca:	ff7c                	sd	a5,248(a4)
            if (proc->state == PROC_ZOMBIE) { // 如果子进程的状态为 PROC_ZOMBIE
ffffffffc02055cc:	4398                	lw	a4,0(a5)
            proc->parent = initproc; // 将子进程的父进程设置为 initproc
ffffffffc02055ce:	f388                	sd	a0,32(a5)
            initproc->cptr = proc; // 将 initproc 的子进程指针指向当前子进程
ffffffffc02055d0:	f97c                	sd	a5,240(a0)
            if (proc->state == PROC_ZOMBIE) { // 如果子进程的状态为 PROC_ZOMBIE
ffffffffc02055d2:	fd271fe3          	bne	a4,s2,ffffffffc02055b0 <do_exit+0x9a>
                if (initproc->wait_state == WT_CHILD) { // 如果 initproc 的等待状态为 WT_CHILD
ffffffffc02055d6:	0ec52783          	lw	a5,236(a0)
ffffffffc02055da:	fd379be3          	bne	a5,s3,ffffffffc02055b0 <do_exit+0x9a>
                    wakeup_proc(initproc); // 唤醒 initproc
ffffffffc02055de:	305000ef          	jal	ra,ffffffffc02060e2 <wakeup_proc>
ffffffffc02055e2:	b7f9                	j	ffffffffc02055b0 <do_exit+0x9a>
    if (flag) {
ffffffffc02055e4:	020a1263          	bnez	s4,ffffffffc0205608 <do_exit+0xf2>
    schedule(); // 调用调度程序切换到其他进程
ffffffffc02055e8:	37b000ef          	jal	ra,ffffffffc0206162 <schedule>
    panic("do_exit will not return!! %d.\n", current->pid); // 触发 panic，do_exit 不会返回
ffffffffc02055ec:	601c                	ld	a5,0(s0)
ffffffffc02055ee:	00003617          	auipc	a2,0x3
ffffffffc02055f2:	04a60613          	addi	a2,a2,74 # ffffffffc0208638 <default_pmm_manager+0x148>
ffffffffc02055f6:	20900593          	li	a1,521
ffffffffc02055fa:	43d4                	lw	a3,4(a5)
ffffffffc02055fc:	00003517          	auipc	a0,0x3
ffffffffc0205600:	fe450513          	addi	a0,a0,-28 # ffffffffc02085e0 <default_pmm_manager+0xf0>
ffffffffc0205604:	c05fa0ef          	jal	ra,ffffffffc0200208 <__panic>
        intr_enable();
ffffffffc0205608:	83afb0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc020560c:	bff1                	j	ffffffffc02055e8 <do_exit+0xd2>
        panic("idleproc exit.\n");
ffffffffc020560e:	00003617          	auipc	a2,0x3
ffffffffc0205612:	00a60613          	addi	a2,a2,10 # ffffffffc0208618 <default_pmm_manager+0x128>
ffffffffc0205616:	1dd00593          	li	a1,477
ffffffffc020561a:	00003517          	auipc	a0,0x3
ffffffffc020561e:	fc650513          	addi	a0,a0,-58 # ffffffffc02085e0 <default_pmm_manager+0xf0>
ffffffffc0205622:	be7fa0ef          	jal	ra,ffffffffc0200208 <__panic>
            exit_mmap(mm); // 退出内存映射
ffffffffc0205626:	854e                	mv	a0,s3
ffffffffc0205628:	d12fd0ef          	jal	ra,ffffffffc0202b3a <exit_mmap>
            put_pgdir(mm); // 释放页目录表
ffffffffc020562c:	854e                	mv	a0,s3
ffffffffc020562e:	ab9ff0ef          	jal	ra,ffffffffc02050e6 <put_pgdir>
            mm_destroy(mm); // 销毁内存管理结构体
ffffffffc0205632:	854e                	mv	a0,s3
ffffffffc0205634:	c04fd0ef          	jal	ra,ffffffffc0202a38 <mm_destroy>
ffffffffc0205638:	bf35                	j	ffffffffc0205574 <do_exit+0x5e>
        panic("initproc exit.\n");
ffffffffc020563a:	00003617          	auipc	a2,0x3
ffffffffc020563e:	fee60613          	addi	a2,a2,-18 # ffffffffc0208628 <default_pmm_manager+0x138>
ffffffffc0205642:	1e000593          	li	a1,480
ffffffffc0205646:	00003517          	auipc	a0,0x3
ffffffffc020564a:	f9a50513          	addi	a0,a0,-102 # ffffffffc02085e0 <default_pmm_manager+0xf0>
ffffffffc020564e:	bbbfa0ef          	jal	ra,ffffffffc0200208 <__panic>
        intr_disable();
ffffffffc0205652:	ff7fa0ef          	jal	ra,ffffffffc0200648 <intr_disable>
        return 1;
ffffffffc0205656:	4a05                	li	s4,1
ffffffffc0205658:	bf1d                	j	ffffffffc020558e <do_exit+0x78>
            wakeup_proc(proc); // 唤醒父进程
ffffffffc020565a:	289000ef          	jal	ra,ffffffffc02060e2 <wakeup_proc>
ffffffffc020565e:	b789                	j	ffffffffc02055a0 <do_exit+0x8a>

ffffffffc0205660 <do_wait.part.0>:
do_wait(int pid, int *code_store) {
ffffffffc0205660:	715d                	addi	sp,sp,-80
ffffffffc0205662:	f84a                	sd	s2,48(sp)
ffffffffc0205664:	f44e                	sd	s3,40(sp)
        current->wait_state = WT_CHILD; // 将当前进程的等待状态设置为WT_CHILD
ffffffffc0205666:	80000937          	lui	s2,0x80000
    if (0 < pid && pid < MAX_PID) { // 如果pid在有效范围内
ffffffffc020566a:	6989                	lui	s3,0x2
do_wait(int pid, int *code_store) {
ffffffffc020566c:	fc26                	sd	s1,56(sp)
ffffffffc020566e:	f052                	sd	s4,32(sp)
ffffffffc0205670:	ec56                	sd	s5,24(sp)
ffffffffc0205672:	e85a                	sd	s6,16(sp)
ffffffffc0205674:	e45e                	sd	s7,8(sp)
ffffffffc0205676:	e486                	sd	ra,72(sp)
ffffffffc0205678:	e0a2                	sd	s0,64(sp)
ffffffffc020567a:	84aa                	mv	s1,a0
ffffffffc020567c:	8a2e                	mv	s4,a1
        proc = current->cptr; // 获取当前进程的子进程
ffffffffc020567e:	000adb97          	auipc	s7,0xad
ffffffffc0205682:	24ab8b93          	addi	s7,s7,586 # ffffffffc02b28c8 <current>
    if (0 < pid && pid < MAX_PID) { // 如果pid在有效范围内
ffffffffc0205686:	00050b1b          	sext.w	s6,a0
ffffffffc020568a:	fff50a9b          	addiw	s5,a0,-1
ffffffffc020568e:	19f9                	addi	s3,s3,-2
        current->wait_state = WT_CHILD; // 将当前进程的等待状态设置为WT_CHILD
ffffffffc0205690:	0905                	addi	s2,s2,1
    if (pid != 0) { // 如果pid不为0
ffffffffc0205692:	ccbd                	beqz	s1,ffffffffc0205710 <do_wait.part.0+0xb0>
    if (0 < pid && pid < MAX_PID) { // 如果pid在有效范围内
ffffffffc0205694:	0359e863          	bltu	s3,s5,ffffffffc02056c4 <do_wait.part.0+0x64>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list; // 获取哈希链表的起始位置
ffffffffc0205698:	45a9                	li	a1,10
ffffffffc020569a:	855a                	mv	a0,s6
ffffffffc020569c:	0c6010ef          	jal	ra,ffffffffc0206762 <hash32>
ffffffffc02056a0:	02051793          	slli	a5,a0,0x20
ffffffffc02056a4:	01c7d513          	srli	a0,a5,0x1c
ffffffffc02056a8:	000a9797          	auipc	a5,0xa9
ffffffffc02056ac:	19878793          	addi	a5,a5,408 # ffffffffc02ae840 <hash_list>
ffffffffc02056b0:	953e                	add	a0,a0,a5
ffffffffc02056b2:	842a                	mv	s0,a0
        while ((le = list_next(le)) != list) { // 遍历哈希链表
ffffffffc02056b4:	a029                	j	ffffffffc02056be <do_wait.part.0+0x5e>
            if (proc->pid == pid) { // 如果找到匹配的pid
ffffffffc02056b6:	f2c42783          	lw	a5,-212(s0)
ffffffffc02056ba:	02978163          	beq	a5,s1,ffffffffc02056dc <do_wait.part.0+0x7c>
ffffffffc02056be:	6400                	ld	s0,8(s0)
        while ((le = list_next(le)) != list) { // 遍历哈希链表
ffffffffc02056c0:	fe851be3          	bne	a0,s0,ffffffffc02056b6 <do_wait.part.0+0x56>
    return -E_BAD_PROC; // 返回-E_BAD_PROC错误码
ffffffffc02056c4:	5579                	li	a0,-2
}
ffffffffc02056c6:	60a6                	ld	ra,72(sp)
ffffffffc02056c8:	6406                	ld	s0,64(sp)
ffffffffc02056ca:	74e2                	ld	s1,56(sp)
ffffffffc02056cc:	7942                	ld	s2,48(sp)
ffffffffc02056ce:	79a2                	ld	s3,40(sp)
ffffffffc02056d0:	7a02                	ld	s4,32(sp)
ffffffffc02056d2:	6ae2                	ld	s5,24(sp)
ffffffffc02056d4:	6b42                	ld	s6,16(sp)
ffffffffc02056d6:	6ba2                	ld	s7,8(sp)
ffffffffc02056d8:	6161                	addi	sp,sp,80
ffffffffc02056da:	8082                	ret
        if (proc != NULL && proc->parent == current) { // 如果找到的进程不为空且其父进程是当前进程
ffffffffc02056dc:	000bb683          	ld	a3,0(s7)
ffffffffc02056e0:	f4843783          	ld	a5,-184(s0)
ffffffffc02056e4:	fed790e3          	bne	a5,a3,ffffffffc02056c4 <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE) { // 如果进程状态为PROC_ZOMBIE
ffffffffc02056e8:	f2842703          	lw	a4,-216(s0)
ffffffffc02056ec:	478d                	li	a5,3
ffffffffc02056ee:	0ef70b63          	beq	a4,a5,ffffffffc02057e4 <do_wait.part.0+0x184>
        current->state = PROC_SLEEPING; // 将当前进程状态设置为PROC_SLEEPING
ffffffffc02056f2:	4785                	li	a5,1
ffffffffc02056f4:	c29c                	sw	a5,0(a3)
        current->wait_state = WT_CHILD; // 将当前进程的等待状态设置为WT_CHILD
ffffffffc02056f6:	0f26a623          	sw	s2,236(a3)
        schedule(); // 调用调度程序进行调度
ffffffffc02056fa:	269000ef          	jal	ra,ffffffffc0206162 <schedule>
        if (current->flags & PF_EXITING) { // 如果当前进程的标志包含PF_EXITING
ffffffffc02056fe:	000bb783          	ld	a5,0(s7)
ffffffffc0205702:	0b07a783          	lw	a5,176(a5)
ffffffffc0205706:	8b85                	andi	a5,a5,1
ffffffffc0205708:	d7c9                	beqz	a5,ffffffffc0205692 <do_wait.part.0+0x32>
            do_exit(-E_KILLED); // 调用do_exit函数退出当前进程
ffffffffc020570a:	555d                	li	a0,-9
ffffffffc020570c:	e0bff0ef          	jal	ra,ffffffffc0205516 <do_exit>
        proc = current->cptr; // 获取当前进程的子进程
ffffffffc0205710:	000bb683          	ld	a3,0(s7)
ffffffffc0205714:	7ae0                	ld	s0,240(a3)
        for (; proc != NULL; proc = proc->optr) { // 遍历所有子进程
ffffffffc0205716:	d45d                	beqz	s0,ffffffffc02056c4 <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE) { // 如果进程状态为PROC_ZOMBIE
ffffffffc0205718:	470d                	li	a4,3
ffffffffc020571a:	a021                	j	ffffffffc0205722 <do_wait.part.0+0xc2>
        for (; proc != NULL; proc = proc->optr) { // 遍历所有子进程
ffffffffc020571c:	10043403          	ld	s0,256(s0)
ffffffffc0205720:	d869                	beqz	s0,ffffffffc02056f2 <do_wait.part.0+0x92>
            if (proc->state == PROC_ZOMBIE) { // 如果进程状态为PROC_ZOMBIE
ffffffffc0205722:	401c                	lw	a5,0(s0)
ffffffffc0205724:	fee79ce3          	bne	a5,a4,ffffffffc020571c <do_wait.part.0+0xbc>
    if (proc == idleproc || proc == initproc) { // 如果进程是idleproc或initproc
ffffffffc0205728:	000ad797          	auipc	a5,0xad
ffffffffc020572c:	1a87b783          	ld	a5,424(a5) # ffffffffc02b28d0 <idleproc>
ffffffffc0205730:	0c878963          	beq	a5,s0,ffffffffc0205802 <do_wait.part.0+0x1a2>
ffffffffc0205734:	000ad797          	auipc	a5,0xad
ffffffffc0205738:	1a47b783          	ld	a5,420(a5) # ffffffffc02b28d8 <initproc>
ffffffffc020573c:	0cf40363          	beq	s0,a5,ffffffffc0205802 <do_wait.part.0+0x1a2>
    if (code_store != NULL) { // 如果code_store不为空
ffffffffc0205740:	000a0663          	beqz	s4,ffffffffc020574c <do_wait.part.0+0xec>
        *code_store = proc->exit_code; // 将进程的退出代码存储到code_store中
ffffffffc0205744:	0e842783          	lw	a5,232(s0)
ffffffffc0205748:	00fa2023          	sw	a5,0(s4)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020574c:	100027f3          	csrr	a5,sstatus
ffffffffc0205750:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0205752:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205754:	e7c1                	bnez	a5,ffffffffc02057dc <do_wait.part.0+0x17c>
    __list_del(listelm->prev, listelm->next);
ffffffffc0205756:	6c70                	ld	a2,216(s0)
ffffffffc0205758:	7074                	ld	a3,224(s0)
    if (proc->optr != NULL) { // 如果当前进程有老兄弟进程
ffffffffc020575a:	10043703          	ld	a4,256(s0)
        proc->optr->yptr = proc->yptr; // 将老兄弟进程的年轻兄弟指针指向当前进程的年轻兄弟
ffffffffc020575e:	7c7c                	ld	a5,248(s0)
    prev->next = next;
ffffffffc0205760:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc0205762:	e290                	sd	a2,0(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0205764:	6470                	ld	a2,200(s0)
ffffffffc0205766:	6874                	ld	a3,208(s0)
    prev->next = next;
ffffffffc0205768:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc020576a:	e290                	sd	a2,0(a3)
    if (proc->optr != NULL) { // 如果当前进程有老兄弟进程
ffffffffc020576c:	c319                	beqz	a4,ffffffffc0205772 <do_wait.part.0+0x112>
        proc->optr->yptr = proc->yptr; // 将老兄弟进程的年轻兄弟指针指向当前进程的年轻兄弟
ffffffffc020576e:	ff7c                	sd	a5,248(a4)
    if (proc->yptr != NULL) { // 如果当前进程有年轻兄弟进程
ffffffffc0205770:	7c7c                	ld	a5,248(s0)
ffffffffc0205772:	c3b5                	beqz	a5,ffffffffc02057d6 <do_wait.part.0+0x176>
        proc->yptr->optr = proc->optr; // 将年轻兄弟进程的老兄弟指针指向当前进程的老兄弟
ffffffffc0205774:	10e7b023          	sd	a4,256(a5)
    nr_process --; // 进程数量减1
ffffffffc0205778:	000ad717          	auipc	a4,0xad
ffffffffc020577c:	16870713          	addi	a4,a4,360 # ffffffffc02b28e0 <nr_process>
ffffffffc0205780:	431c                	lw	a5,0(a4)
ffffffffc0205782:	37fd                	addiw	a5,a5,-1
ffffffffc0205784:	c31c                	sw	a5,0(a4)
    if (flag) {
ffffffffc0205786:	e5a9                	bnez	a1,ffffffffc02057d0 <do_wait.part.0+0x170>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE); // 释放进程内核栈的页
ffffffffc0205788:	6814                	ld	a3,16(s0)
ffffffffc020578a:	c02007b7          	lui	a5,0xc0200
ffffffffc020578e:	04f6ee63          	bltu	a3,a5,ffffffffc02057ea <do_wait.part.0+0x18a>
ffffffffc0205792:	000ad797          	auipc	a5,0xad
ffffffffc0205796:	0fe7b783          	ld	a5,254(a5) # ffffffffc02b2890 <va_pa_offset>
ffffffffc020579a:	8e9d                	sub	a3,a3,a5
    if (PPN(pa) >= npage) {
ffffffffc020579c:	82b1                	srli	a3,a3,0xc
ffffffffc020579e:	000ad797          	auipc	a5,0xad
ffffffffc02057a2:	0da7b783          	ld	a5,218(a5) # ffffffffc02b2878 <npage>
ffffffffc02057a6:	06f6fa63          	bgeu	a3,a5,ffffffffc020581a <do_wait.part.0+0x1ba>
    return &pages[PPN(pa) - nbase];
ffffffffc02057aa:	00003517          	auipc	a0,0x3
ffffffffc02057ae:	6c653503          	ld	a0,1734(a0) # ffffffffc0208e70 <nbase>
ffffffffc02057b2:	8e89                	sub	a3,a3,a0
ffffffffc02057b4:	069a                	slli	a3,a3,0x6
ffffffffc02057b6:	000ad517          	auipc	a0,0xad
ffffffffc02057ba:	0ca53503          	ld	a0,202(a0) # ffffffffc02b2880 <pages>
ffffffffc02057be:	9536                	add	a0,a0,a3
ffffffffc02057c0:	4589                	li	a1,2
ffffffffc02057c2:	c69fb0ef          	jal	ra,ffffffffc020142a <free_pages>
    kfree(proc); // 释放进程的内存
ffffffffc02057c6:	8522                	mv	a0,s0
ffffffffc02057c8:	ec6fe0ef          	jal	ra,ffffffffc0203e8e <kfree>
    return 0; // 返回0表示成功
ffffffffc02057cc:	4501                	li	a0,0
ffffffffc02057ce:	bde5                	j	ffffffffc02056c6 <do_wait.part.0+0x66>
        intr_enable();
ffffffffc02057d0:	e73fa0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc02057d4:	bf55                	j	ffffffffc0205788 <do_wait.part.0+0x128>
       proc->parent->cptr = proc->optr; // 将父进程的子进程指针指向当前进程的老兄弟
ffffffffc02057d6:	701c                	ld	a5,32(s0)
ffffffffc02057d8:	fbf8                	sd	a4,240(a5)
ffffffffc02057da:	bf79                	j	ffffffffc0205778 <do_wait.part.0+0x118>
        intr_disable();
ffffffffc02057dc:	e6dfa0ef          	jal	ra,ffffffffc0200648 <intr_disable>
        return 1;
ffffffffc02057e0:	4585                	li	a1,1
ffffffffc02057e2:	bf95                	j	ffffffffc0205756 <do_wait.part.0+0xf6>
            struct proc_struct *proc = le2proc(le, hash_link); // 获取链表元素对应的进程结构体指针
ffffffffc02057e4:	f2840413          	addi	s0,s0,-216
ffffffffc02057e8:	b781                	j	ffffffffc0205728 <do_wait.part.0+0xc8>
    return pa2page(PADDR(kva));
ffffffffc02057ea:	00002617          	auipc	a2,0x2
ffffffffc02057ee:	a4e60613          	addi	a2,a2,-1458 # ffffffffc0207238 <commands+0x818>
ffffffffc02057f2:	06e00593          	li	a1,110
ffffffffc02057f6:	00002517          	auipc	a0,0x2
ffffffffc02057fa:	9a250513          	addi	a0,a0,-1630 # ffffffffc0207198 <commands+0x778>
ffffffffc02057fe:	a0bfa0ef          	jal	ra,ffffffffc0200208 <__panic>
        panic("wait idleproc or initproc.\n"); // 触发panic，不能等待idleproc或initproc
ffffffffc0205802:	00003617          	auipc	a2,0x3
ffffffffc0205806:	e5660613          	addi	a2,a2,-426 # ffffffffc0208658 <default_pmm_manager+0x168>
ffffffffc020580a:	31900593          	li	a1,793
ffffffffc020580e:	00003517          	auipc	a0,0x3
ffffffffc0205812:	dd250513          	addi	a0,a0,-558 # ffffffffc02085e0 <default_pmm_manager+0xf0>
ffffffffc0205816:	9f3fa0ef          	jal	ra,ffffffffc0200208 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc020581a:	00002617          	auipc	a2,0x2
ffffffffc020581e:	95e60613          	addi	a2,a2,-1698 # ffffffffc0207178 <commands+0x758>
ffffffffc0205822:	06200593          	li	a1,98
ffffffffc0205826:	00002517          	auipc	a0,0x2
ffffffffc020582a:	97250513          	addi	a0,a0,-1678 # ffffffffc0207198 <commands+0x778>
ffffffffc020582e:	9dbfa0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0205832 <init_main>:
}

// init_main - 第二个内核线程，用于创建 user_main 内核线程
static int
init_main(void *arg) {
ffffffffc0205832:	1141                	addi	sp,sp,-16
ffffffffc0205834:	e406                	sd	ra,8(sp)
    size_t nr_free_pages_store = nr_free_pages(); // 获取当前空闲页的数量
ffffffffc0205836:	c35fb0ef          	jal	ra,ffffffffc020146a <nr_free_pages>
    size_t kernel_allocated_store = kallocated(); // 获取当前内核分配的内存数量
ffffffffc020583a:	da0fe0ef          	jal	ra,ffffffffc0203dda <kallocated>

    int pid = kernel_thread(user_main, NULL, 0); // 创建 user_main 内核线程
ffffffffc020583e:	4601                	li	a2,0
ffffffffc0205840:	4581                	li	a1,0
ffffffffc0205842:	00000517          	auipc	a0,0x0
ffffffffc0205846:	82650513          	addi	a0,a0,-2010 # ffffffffc0205068 <user_main>
ffffffffc020584a:	c7dff0ef          	jal	ra,ffffffffc02054c6 <kernel_thread>
    if (pid <= 0) { // 如果创建失败
ffffffffc020584e:	00a04563          	bgtz	a0,ffffffffc0205858 <init_main+0x26>
ffffffffc0205852:	a071                	j	ffffffffc02058de <init_main+0xac>
        panic("create user_main failed.\n"); // 触发 panic，创建 user_main 失败
    }

    while (do_wait(0, NULL) == 0) { // 等待所有子进程退出
        schedule(); // 调用调度程序进行调度
ffffffffc0205854:	10f000ef          	jal	ra,ffffffffc0206162 <schedule>
    if (code_store != NULL) { // 如果code_store不为空
ffffffffc0205858:	4581                	li	a1,0
ffffffffc020585a:	4501                	li	a0,0
ffffffffc020585c:	e05ff0ef          	jal	ra,ffffffffc0205660 <do_wait.part.0>
    while (do_wait(0, NULL) == 0) { // 等待所有子进程退出
ffffffffc0205860:	d975                	beqz	a0,ffffffffc0205854 <init_main+0x22>
    }

    cprintf("all user-mode processes have quit.\n"); // 打印所有用户模式进程已退出
ffffffffc0205862:	00003517          	auipc	a0,0x3
ffffffffc0205866:	e3650513          	addi	a0,a0,-458 # ffffffffc0208698 <default_pmm_manager+0x1a8>
ffffffffc020586a:	863fa0ef          	jal	ra,ffffffffc02000cc <cprintf>
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL); // 确保 initproc 没有子进程
ffffffffc020586e:	000ad797          	auipc	a5,0xad
ffffffffc0205872:	06a7b783          	ld	a5,106(a5) # ffffffffc02b28d8 <initproc>
ffffffffc0205876:	7bf8                	ld	a4,240(a5)
ffffffffc0205878:	e339                	bnez	a4,ffffffffc02058be <init_main+0x8c>
ffffffffc020587a:	7ff8                	ld	a4,248(a5)
ffffffffc020587c:	e329                	bnez	a4,ffffffffc02058be <init_main+0x8c>
ffffffffc020587e:	1007b703          	ld	a4,256(a5)
ffffffffc0205882:	ef15                	bnez	a4,ffffffffc02058be <init_main+0x8c>
    assert(nr_process == 2); // 确保进程数量为 2
ffffffffc0205884:	000ad697          	auipc	a3,0xad
ffffffffc0205888:	05c6a683          	lw	a3,92(a3) # ffffffffc02b28e0 <nr_process>
ffffffffc020588c:	4709                	li	a4,2
ffffffffc020588e:	0ae69463          	bne	a3,a4,ffffffffc0205936 <init_main+0x104>
    return listelm->next;
ffffffffc0205892:	000ad697          	auipc	a3,0xad
ffffffffc0205896:	fae68693          	addi	a3,a3,-82 # ffffffffc02b2840 <proc_list>
    assert(list_next(&proc_list) == &(initproc->list_link)); // 确保进程列表中只有 initproc
ffffffffc020589a:	6698                	ld	a4,8(a3)
ffffffffc020589c:	0c878793          	addi	a5,a5,200
ffffffffc02058a0:	06f71b63          	bne	a4,a5,ffffffffc0205916 <init_main+0xe4>
    assert(list_prev(&proc_list) == &(initproc->list_link)); // 确保进程列表中只有 initproc
ffffffffc02058a4:	629c                	ld	a5,0(a3)
ffffffffc02058a6:	04f71863          	bne	a4,a5,ffffffffc02058f6 <init_main+0xc4>

    cprintf("init check memory pass.\n"); // 打印内存检查通过
ffffffffc02058aa:	00003517          	auipc	a0,0x3
ffffffffc02058ae:	ed650513          	addi	a0,a0,-298 # ffffffffc0208780 <default_pmm_manager+0x290>
ffffffffc02058b2:	81bfa0ef          	jal	ra,ffffffffc02000cc <cprintf>
    return 0; // 返回 0 表示成功
}
ffffffffc02058b6:	60a2                	ld	ra,8(sp)
ffffffffc02058b8:	4501                	li	a0,0
ffffffffc02058ba:	0141                	addi	sp,sp,16
ffffffffc02058bc:	8082                	ret
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL); // 确保 initproc 没有子进程
ffffffffc02058be:	00003697          	auipc	a3,0x3
ffffffffc02058c2:	e0268693          	addi	a3,a3,-510 # ffffffffc02086c0 <default_pmm_manager+0x1d0>
ffffffffc02058c6:	00001617          	auipc	a2,0x1
ffffffffc02058ca:	56a60613          	addi	a2,a2,1386 # ffffffffc0206e30 <commands+0x410>
ffffffffc02058ce:	37e00593          	li	a1,894
ffffffffc02058d2:	00003517          	auipc	a0,0x3
ffffffffc02058d6:	d0e50513          	addi	a0,a0,-754 # ffffffffc02085e0 <default_pmm_manager+0xf0>
ffffffffc02058da:	92ffa0ef          	jal	ra,ffffffffc0200208 <__panic>
        panic("create user_main failed.\n"); // 触发 panic，创建 user_main 失败
ffffffffc02058de:	00003617          	auipc	a2,0x3
ffffffffc02058e2:	d9a60613          	addi	a2,a2,-614 # ffffffffc0208678 <default_pmm_manager+0x188>
ffffffffc02058e6:	37600593          	li	a1,886
ffffffffc02058ea:	00003517          	auipc	a0,0x3
ffffffffc02058ee:	cf650513          	addi	a0,a0,-778 # ffffffffc02085e0 <default_pmm_manager+0xf0>
ffffffffc02058f2:	917fa0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(list_prev(&proc_list) == &(initproc->list_link)); // 确保进程列表中只有 initproc
ffffffffc02058f6:	00003697          	auipc	a3,0x3
ffffffffc02058fa:	e5a68693          	addi	a3,a3,-422 # ffffffffc0208750 <default_pmm_manager+0x260>
ffffffffc02058fe:	00001617          	auipc	a2,0x1
ffffffffc0205902:	53260613          	addi	a2,a2,1330 # ffffffffc0206e30 <commands+0x410>
ffffffffc0205906:	38100593          	li	a1,897
ffffffffc020590a:	00003517          	auipc	a0,0x3
ffffffffc020590e:	cd650513          	addi	a0,a0,-810 # ffffffffc02085e0 <default_pmm_manager+0xf0>
ffffffffc0205912:	8f7fa0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(list_next(&proc_list) == &(initproc->list_link)); // 确保进程列表中只有 initproc
ffffffffc0205916:	00003697          	auipc	a3,0x3
ffffffffc020591a:	e0a68693          	addi	a3,a3,-502 # ffffffffc0208720 <default_pmm_manager+0x230>
ffffffffc020591e:	00001617          	auipc	a2,0x1
ffffffffc0205922:	51260613          	addi	a2,a2,1298 # ffffffffc0206e30 <commands+0x410>
ffffffffc0205926:	38000593          	li	a1,896
ffffffffc020592a:	00003517          	auipc	a0,0x3
ffffffffc020592e:	cb650513          	addi	a0,a0,-842 # ffffffffc02085e0 <default_pmm_manager+0xf0>
ffffffffc0205932:	8d7fa0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(nr_process == 2); // 确保进程数量为 2
ffffffffc0205936:	00003697          	auipc	a3,0x3
ffffffffc020593a:	dda68693          	addi	a3,a3,-550 # ffffffffc0208710 <default_pmm_manager+0x220>
ffffffffc020593e:	00001617          	auipc	a2,0x1
ffffffffc0205942:	4f260613          	addi	a2,a2,1266 # ffffffffc0206e30 <commands+0x410>
ffffffffc0205946:	37f00593          	li	a1,895
ffffffffc020594a:	00003517          	auipc	a0,0x3
ffffffffc020594e:	c9650513          	addi	a0,a0,-874 # ffffffffc02085e0 <default_pmm_manager+0xf0>
ffffffffc0205952:	8b7fa0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0205956 <do_execve>:
do_execve(const char *name, size_t len, unsigned char *binary, size_t size) {
ffffffffc0205956:	7171                	addi	sp,sp,-176
ffffffffc0205958:	e4ee                	sd	s11,72(sp)
    struct mm_struct *mm = current->mm; // 获取当前进程的内存管理结构体
ffffffffc020595a:	000add97          	auipc	s11,0xad
ffffffffc020595e:	f6ed8d93          	addi	s11,s11,-146 # ffffffffc02b28c8 <current>
ffffffffc0205962:	000db783          	ld	a5,0(s11)
do_execve(const char *name, size_t len, unsigned char *binary, size_t size) {
ffffffffc0205966:	e54e                	sd	s3,136(sp)
ffffffffc0205968:	ed26                	sd	s1,152(sp)
    struct mm_struct *mm = current->mm; // 获取当前进程的内存管理结构体
ffffffffc020596a:	0287b983          	ld	s3,40(a5)
do_execve(const char *name, size_t len, unsigned char *binary, size_t size) {
ffffffffc020596e:	e94a                	sd	s2,144(sp)
ffffffffc0205970:	f4de                	sd	s7,104(sp)
ffffffffc0205972:	892a                	mv	s2,a0
ffffffffc0205974:	8bb2                	mv	s7,a2
ffffffffc0205976:	84ae                	mv	s1,a1
    if (!user_mem_check(mm, (uintptr_t)name, len, 0)) { // 检查用户内存是否合法
ffffffffc0205978:	862e                	mv	a2,a1
ffffffffc020597a:	4681                	li	a3,0
ffffffffc020597c:	85aa                	mv	a1,a0
ffffffffc020597e:	854e                	mv	a0,s3
do_execve(const char *name, size_t len, unsigned char *binary, size_t size) {
ffffffffc0205980:	f506                	sd	ra,168(sp)
ffffffffc0205982:	f122                	sd	s0,160(sp)
ffffffffc0205984:	e152                	sd	s4,128(sp)
ffffffffc0205986:	fcd6                	sd	s5,120(sp)
ffffffffc0205988:	f8da                	sd	s6,112(sp)
ffffffffc020598a:	f0e2                	sd	s8,96(sp)
ffffffffc020598c:	ece6                	sd	s9,88(sp)
ffffffffc020598e:	e8ea                	sd	s10,80(sp)
ffffffffc0205990:	f05e                	sd	s7,32(sp)
    if (!user_mem_check(mm, (uintptr_t)name, len, 0)) { // 检查用户内存是否合法
ffffffffc0205992:	87ffd0ef          	jal	ra,ffffffffc0203210 <user_mem_check>
ffffffffc0205996:	40050863          	beqz	a0,ffffffffc0205da6 <do_execve+0x450>
    memset(local_name, 0, sizeof(local_name)); // 将字符数组清零
ffffffffc020599a:	4641                	li	a2,16
ffffffffc020599c:	4581                	li	a1,0
ffffffffc020599e:	1808                	addi	a0,sp,48
ffffffffc02059a0:	1ab000ef          	jal	ra,ffffffffc020634a <memset>
    memcpy(local_name, name, len); // 将名称复制到字符数组中
ffffffffc02059a4:	47bd                	li	a5,15
ffffffffc02059a6:	8626                	mv	a2,s1
ffffffffc02059a8:	1e97e063          	bltu	a5,s1,ffffffffc0205b88 <do_execve+0x232>
ffffffffc02059ac:	85ca                	mv	a1,s2
ffffffffc02059ae:	1808                	addi	a0,sp,48
ffffffffc02059b0:	1ad000ef          	jal	ra,ffffffffc020635c <memcpy>
    if (mm != NULL) { // 如果内存管理结构体不为空
ffffffffc02059b4:	1e098163          	beqz	s3,ffffffffc0205b96 <do_execve+0x240>
        cputs("mm != NULL"); // 打印调试信息
ffffffffc02059b8:	00002517          	auipc	a0,0x2
ffffffffc02059bc:	ef050513          	addi	a0,a0,-272 # ffffffffc02078a8 <commands+0xe88>
ffffffffc02059c0:	f44fa0ef          	jal	ra,ffffffffc0200104 <cputs>
ffffffffc02059c4:	000ad797          	auipc	a5,0xad
ffffffffc02059c8:	ea47b783          	ld	a5,-348(a5) # ffffffffc02b2868 <boot_cr3>
ffffffffc02059cc:	577d                	li	a4,-1
ffffffffc02059ce:	177e                	slli	a4,a4,0x3f
ffffffffc02059d0:	83b1                	srli	a5,a5,0xc
ffffffffc02059d2:	8fd9                	or	a5,a5,a4
ffffffffc02059d4:	18079073          	csrw	satp,a5
ffffffffc02059d8:	0309a783          	lw	a5,48(s3) # 2030 <_binary_obj___user_faultread_out_size-0x7b88>
ffffffffc02059dc:	fff7871b          	addiw	a4,a5,-1
ffffffffc02059e0:	02e9a823          	sw	a4,48(s3)
        if (mm_count_dec(mm) == 0) { // 如果内存管理结构体的引用计数为 0
ffffffffc02059e4:	2c070263          	beqz	a4,ffffffffc0205ca8 <do_execve+0x352>
        current->mm = NULL; // 将当前进程的内存管理结构体指针置为空
ffffffffc02059e8:	000db783          	ld	a5,0(s11)
ffffffffc02059ec:	0207b423          	sd	zero,40(a5)
    if ((mm = mm_create()) == NULL) { // 创建一个新的内存管理结构体，如果失败则跳转到bad_mm标签
ffffffffc02059f0:	ec3fc0ef          	jal	ra,ffffffffc02028b2 <mm_create>
ffffffffc02059f4:	84aa                	mv	s1,a0
ffffffffc02059f6:	1c050b63          	beqz	a0,ffffffffc0205bcc <do_execve+0x276>
    if ((page = alloc_page()) == NULL) { // 分配一页内存，如果失败返回-E_NO_MEM
ffffffffc02059fa:	4505                	li	a0,1
ffffffffc02059fc:	99dfb0ef          	jal	ra,ffffffffc0201398 <alloc_pages>
ffffffffc0205a00:	3a050763          	beqz	a0,ffffffffc0205dae <do_execve+0x458>
    return page - pages + nbase;
ffffffffc0205a04:	000adc97          	auipc	s9,0xad
ffffffffc0205a08:	e7cc8c93          	addi	s9,s9,-388 # ffffffffc02b2880 <pages>
ffffffffc0205a0c:	000cb683          	ld	a3,0(s9)
    return KADDR(page2pa(page));
ffffffffc0205a10:	000adc17          	auipc	s8,0xad
ffffffffc0205a14:	e68c0c13          	addi	s8,s8,-408 # ffffffffc02b2878 <npage>
    return page - pages + nbase;
ffffffffc0205a18:	00003717          	auipc	a4,0x3
ffffffffc0205a1c:	45873703          	ld	a4,1112(a4) # ffffffffc0208e70 <nbase>
ffffffffc0205a20:	40d506b3          	sub	a3,a0,a3
ffffffffc0205a24:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0205a26:	5afd                	li	s5,-1
ffffffffc0205a28:	000c3783          	ld	a5,0(s8)
    return page - pages + nbase;
ffffffffc0205a2c:	96ba                	add	a3,a3,a4
ffffffffc0205a2e:	e83a                	sd	a4,16(sp)
    return KADDR(page2pa(page));
ffffffffc0205a30:	00cad713          	srli	a4,s5,0xc
ffffffffc0205a34:	ec3a                	sd	a4,24(sp)
ffffffffc0205a36:	8f75                	and	a4,a4,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0205a38:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0205a3a:	36f77e63          	bgeu	a4,a5,ffffffffc0205db6 <do_execve+0x460>
ffffffffc0205a3e:	000adb17          	auipc	s6,0xad
ffffffffc0205a42:	e52b0b13          	addi	s6,s6,-430 # ffffffffc02b2890 <va_pa_offset>
ffffffffc0205a46:	000b3903          	ld	s2,0(s6)
    memcpy(pgdir, boot_pgdir, PGSIZE); // 将boot_pgdir复制到新分配的页中
ffffffffc0205a4a:	6605                	lui	a2,0x1
ffffffffc0205a4c:	000ad597          	auipc	a1,0xad
ffffffffc0205a50:	e245b583          	ld	a1,-476(a1) # ffffffffc02b2870 <boot_pgdir>
ffffffffc0205a54:	9936                	add	s2,s2,a3
ffffffffc0205a56:	854a                	mv	a0,s2
ffffffffc0205a58:	105000ef          	jal	ra,ffffffffc020635c <memcpy>
    if (elf->e_magic != ELF_MAGIC) { // 如果ELF文件头的魔数不匹配
ffffffffc0205a5c:	7782                	ld	a5,32(sp)
ffffffffc0205a5e:	4398                	lw	a4,0(a5)
ffffffffc0205a60:	464c47b7          	lui	a5,0x464c4
    mm->pgdir = pgdir; // 将新分配的页地址赋值给mm结构体的pgdir字段
ffffffffc0205a64:	0124bc23          	sd	s2,24(s1)
    if (elf->e_magic != ELF_MAGIC) { // 如果ELF文件头的魔数不匹配
ffffffffc0205a68:	57f78793          	addi	a5,a5,1407 # 464c457f <_binary_obj___user_exit_out_size+0x464b9447>
ffffffffc0205a6c:	14f71663          	bne	a4,a5,ffffffffc0205bb8 <do_execve+0x262>
    struct proghdr *ph_end = ph + elf->e_phnum; // 获取程序段头表的结束地址
ffffffffc0205a70:	7682                	ld	a3,32(sp)
ffffffffc0205a72:	0386d703          	lhu	a4,56(a3)
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff); // 获取程序段头表的入口地址
ffffffffc0205a76:	0206b983          	ld	s3,32(a3)
    struct proghdr *ph_end = ph + elf->e_phnum; // 获取程序段头表的结束地址
ffffffffc0205a7a:	00371793          	slli	a5,a4,0x3
ffffffffc0205a7e:	8f99                	sub	a5,a5,a4
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff); // 获取程序段头表的入口地址
ffffffffc0205a80:	99b6                	add	s3,s3,a3
    struct proghdr *ph_end = ph + elf->e_phnum; // 获取程序段头表的结束地址
ffffffffc0205a82:	078e                	slli	a5,a5,0x3
ffffffffc0205a84:	97ce                	add	a5,a5,s3
ffffffffc0205a86:	f43e                	sd	a5,40(sp)
    for (; ph < ph_end; ph ++) { // 遍历每个程序段头
ffffffffc0205a88:	00f9fc63          	bgeu	s3,a5,ffffffffc0205aa0 <do_execve+0x14a>
        if (ph->p_type != ELF_PT_LOAD) { // 如果程序段头的类型不是可加载段
ffffffffc0205a8c:	0009a783          	lw	a5,0(s3)
ffffffffc0205a90:	4705                	li	a4,1
ffffffffc0205a92:	12e78f63          	beq	a5,a4,ffffffffc0205bd0 <do_execve+0x27a>
    for (; ph < ph_end; ph ++) { // 遍历每个程序段头
ffffffffc0205a96:	77a2                	ld	a5,40(sp)
ffffffffc0205a98:	03898993          	addi	s3,s3,56
ffffffffc0205a9c:	fef9e8e3          	bltu	s3,a5,ffffffffc0205a8c <do_execve+0x136>
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0) { // 调用mm_map函数设置新的虚拟内存区域，如果失败则跳转到bad_cleanup_mmap标签
ffffffffc0205aa0:	4701                	li	a4,0
ffffffffc0205aa2:	46ad                	li	a3,11
ffffffffc0205aa4:	00100637          	lui	a2,0x100
ffffffffc0205aa8:	7ff005b7          	lui	a1,0x7ff00
ffffffffc0205aac:	8526                	mv	a0,s1
ffffffffc0205aae:	fddfc0ef          	jal	ra,ffffffffc0202a8a <mm_map>
ffffffffc0205ab2:	8a2a                	mv	s4,a0
ffffffffc0205ab4:	1e051063          	bnez	a0,ffffffffc0205c94 <do_execve+0x33e>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-PGSIZE , PTE_USER) != NULL); // 断言分配页成功
ffffffffc0205ab8:	6c88                	ld	a0,24(s1)
ffffffffc0205aba:	467d                	li	a2,31
ffffffffc0205abc:	7ffff5b7          	lui	a1,0x7ffff
ffffffffc0205ac0:	d15fc0ef          	jal	ra,ffffffffc02027d4 <pgdir_alloc_page>
ffffffffc0205ac4:	38050163          	beqz	a0,ffffffffc0205e46 <do_execve+0x4f0>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-2*PGSIZE , PTE_USER) != NULL); // 断言分配页成功
ffffffffc0205ac8:	6c88                	ld	a0,24(s1)
ffffffffc0205aca:	467d                	li	a2,31
ffffffffc0205acc:	7fffe5b7          	lui	a1,0x7fffe
ffffffffc0205ad0:	d05fc0ef          	jal	ra,ffffffffc02027d4 <pgdir_alloc_page>
ffffffffc0205ad4:	34050963          	beqz	a0,ffffffffc0205e26 <do_execve+0x4d0>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-3*PGSIZE , PTE_USER) != NULL); // 断言分配页成功
ffffffffc0205ad8:	6c88                	ld	a0,24(s1)
ffffffffc0205ada:	467d                	li	a2,31
ffffffffc0205adc:	7fffd5b7          	lui	a1,0x7fffd
ffffffffc0205ae0:	cf5fc0ef          	jal	ra,ffffffffc02027d4 <pgdir_alloc_page>
ffffffffc0205ae4:	32050163          	beqz	a0,ffffffffc0205e06 <do_execve+0x4b0>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-4*PGSIZE , PTE_USER) != NULL); // 断言分配页成功
ffffffffc0205ae8:	6c88                	ld	a0,24(s1)
ffffffffc0205aea:	467d                	li	a2,31
ffffffffc0205aec:	7fffc5b7          	lui	a1,0x7fffc
ffffffffc0205af0:	ce5fc0ef          	jal	ra,ffffffffc02027d4 <pgdir_alloc_page>
ffffffffc0205af4:	2e050963          	beqz	a0,ffffffffc0205de6 <do_execve+0x490>
    mm->mm_count += 1;
ffffffffc0205af8:	589c                	lw	a5,48(s1)
    current->mm = mm; // 将当前进程的内存管理结构体设置为新创建的内存管理结构体
ffffffffc0205afa:	000db603          	ld	a2,0(s11)
    current->cr3 = PADDR(mm->pgdir); // 将当前进程的CR3寄存器设置为页目录表的物理地址
ffffffffc0205afe:	6c94                	ld	a3,24(s1)
ffffffffc0205b00:	2785                	addiw	a5,a5,1
ffffffffc0205b02:	d89c                	sw	a5,48(s1)
    current->mm = mm; // 将当前进程的内存管理结构体设置为新创建的内存管理结构体
ffffffffc0205b04:	f604                	sd	s1,40(a2)
    current->cr3 = PADDR(mm->pgdir); // 将当前进程的CR3寄存器设置为页目录表的物理地址
ffffffffc0205b06:	c02007b7          	lui	a5,0xc0200
ffffffffc0205b0a:	2cf6e263          	bltu	a3,a5,ffffffffc0205dce <do_execve+0x478>
ffffffffc0205b0e:	000b3783          	ld	a5,0(s6)
ffffffffc0205b12:	577d                	li	a4,-1
ffffffffc0205b14:	177e                	slli	a4,a4,0x3f
ffffffffc0205b16:	8e9d                	sub	a3,a3,a5
ffffffffc0205b18:	00c6d793          	srli	a5,a3,0xc
ffffffffc0205b1c:	f654                	sd	a3,168(a2)
ffffffffc0205b1e:	8fd9                	or	a5,a5,a4
ffffffffc0205b20:	18079073          	csrw	satp,a5
    struct trapframe *tf = current->tf; // 获取当前进程的trapframe
ffffffffc0205b24:	7240                	ld	s0,160(a2)
    memset(tf, 0, sizeof(struct trapframe)); // 将trapframe清零
ffffffffc0205b26:	4581                	li	a1,0
ffffffffc0205b28:	12000613          	li	a2,288
ffffffffc0205b2c:	8522                	mv	a0,s0
    uintptr_t sstatus = tf->status; // 获取当前trapframe的status寄存器
ffffffffc0205b2e:	10043903          	ld	s2,256(s0)
    memset(tf, 0, sizeof(struct trapframe)); // 将trapframe清零
ffffffffc0205b32:	019000ef          	jal	ra,ffffffffc020634a <memset>
    tf->epc = elf->e_entry; // 设置trapframe的程序计数器为ELF文件头的入口点
ffffffffc0205b36:	7782                	ld	a5,32(sp)
    memset(proc->name, 0, sizeof(proc->name)); // 将proc->name的内存清零
ffffffffc0205b38:	000db483          	ld	s1,0(s11)
    tf->status = sstatus & ~(SSTATUS_SPP | SSTATUS_SPIE); // 设置trapframe的status寄存器
ffffffffc0205b3c:	edf97913          	andi	s2,s2,-289
    tf->epc = elf->e_entry; // 设置trapframe的程序计数器为ELF文件头的入口点
ffffffffc0205b40:	6f98                	ld	a4,24(a5)
    tf->gpr.sp = USTACKTOP; // 设置trapframe的栈指针为用户栈顶
ffffffffc0205b42:	4785                	li	a5,1
    memset(proc->name, 0, sizeof(proc->name)); // 将proc->name的内存清零
ffffffffc0205b44:	0b448493          	addi	s1,s1,180
    tf->gpr.sp = USTACKTOP; // 设置trapframe的栈指针为用户栈顶
ffffffffc0205b48:	07fe                	slli	a5,a5,0x1f
    memset(proc->name, 0, sizeof(proc->name)); // 将proc->name的内存清零
ffffffffc0205b4a:	4641                	li	a2,16
ffffffffc0205b4c:	4581                	li	a1,0
    tf->gpr.sp = USTACKTOP; // 设置trapframe的栈指针为用户栈顶
ffffffffc0205b4e:	e81c                	sd	a5,16(s0)
    tf->epc = elf->e_entry; // 设置trapframe的程序计数器为ELF文件头的入口点
ffffffffc0205b50:	10e43423          	sd	a4,264(s0)
    tf->status = sstatus & ~(SSTATUS_SPP | SSTATUS_SPIE); // 设置trapframe的status寄存器
ffffffffc0205b54:	11243023          	sd	s2,256(s0)
    memset(proc->name, 0, sizeof(proc->name)); // 将proc->name的内存清零
ffffffffc0205b58:	8526                	mv	a0,s1
ffffffffc0205b5a:	7f0000ef          	jal	ra,ffffffffc020634a <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN); // 将name复制到proc->name中，长度为PROC_NAME_LEN
ffffffffc0205b5e:	463d                	li	a2,15
ffffffffc0205b60:	180c                	addi	a1,sp,48
ffffffffc0205b62:	8526                	mv	a0,s1
ffffffffc0205b64:	7f8000ef          	jal	ra,ffffffffc020635c <memcpy>
}
ffffffffc0205b68:	70aa                	ld	ra,168(sp)
ffffffffc0205b6a:	740a                	ld	s0,160(sp)
ffffffffc0205b6c:	64ea                	ld	s1,152(sp)
ffffffffc0205b6e:	694a                	ld	s2,144(sp)
ffffffffc0205b70:	69aa                	ld	s3,136(sp)
ffffffffc0205b72:	7ae6                	ld	s5,120(sp)
ffffffffc0205b74:	7b46                	ld	s6,112(sp)
ffffffffc0205b76:	7ba6                	ld	s7,104(sp)
ffffffffc0205b78:	7c06                	ld	s8,96(sp)
ffffffffc0205b7a:	6ce6                	ld	s9,88(sp)
ffffffffc0205b7c:	6d46                	ld	s10,80(sp)
ffffffffc0205b7e:	6da6                	ld	s11,72(sp)
ffffffffc0205b80:	8552                	mv	a0,s4
ffffffffc0205b82:	6a0a                	ld	s4,128(sp)
ffffffffc0205b84:	614d                	addi	sp,sp,176
ffffffffc0205b86:	8082                	ret
    memcpy(local_name, name, len); // 将名称复制到字符数组中
ffffffffc0205b88:	463d                	li	a2,15
ffffffffc0205b8a:	85ca                	mv	a1,s2
ffffffffc0205b8c:	1808                	addi	a0,sp,48
ffffffffc0205b8e:	7ce000ef          	jal	ra,ffffffffc020635c <memcpy>
    if (mm != NULL) { // 如果内存管理结构体不为空
ffffffffc0205b92:	e20993e3          	bnez	s3,ffffffffc02059b8 <do_execve+0x62>
    if (current->mm != NULL) { // 如果当前进程的内存管理结构体不为空
ffffffffc0205b96:	000db783          	ld	a5,0(s11)
ffffffffc0205b9a:	779c                	ld	a5,40(a5)
ffffffffc0205b9c:	e4078ae3          	beqz	a5,ffffffffc02059f0 <do_execve+0x9a>
        panic("load_icode: current->mm must be empty.\n"); // 触发panic，当前进程的内存管理结构体必须为空
ffffffffc0205ba0:	00003617          	auipc	a2,0x3
ffffffffc0205ba4:	c0060613          	addi	a2,a2,-1024 # ffffffffc02087a0 <default_pmm_manager+0x2b0>
ffffffffc0205ba8:	22400593          	li	a1,548
ffffffffc0205bac:	00003517          	auipc	a0,0x3
ffffffffc0205bb0:	a3450513          	addi	a0,a0,-1484 # ffffffffc02085e0 <default_pmm_manager+0xf0>
ffffffffc0205bb4:	e54fa0ef          	jal	ra,ffffffffc0200208 <__panic>
    put_pgdir(mm); // 释放页目录表
ffffffffc0205bb8:	8526                	mv	a0,s1
ffffffffc0205bba:	d2cff0ef          	jal	ra,ffffffffc02050e6 <put_pgdir>
    mm_destroy(mm); // 销毁内存管理结构体
ffffffffc0205bbe:	8526                	mv	a0,s1
ffffffffc0205bc0:	e79fc0ef          	jal	ra,ffffffffc0202a38 <mm_destroy>
        ret = -E_INVAL_ELF; // 设置返回值为无效的ELF错误码
ffffffffc0205bc4:	5a61                	li	s4,-8
    do_exit(ret); // 调用 do_exit 退出当前进程
ffffffffc0205bc6:	8552                	mv	a0,s4
ffffffffc0205bc8:	94fff0ef          	jal	ra,ffffffffc0205516 <do_exit>
    int ret = -E_NO_MEM; // 初始化返回值为内存不足错误码
ffffffffc0205bcc:	5a71                	li	s4,-4
ffffffffc0205bce:	bfe5                	j	ffffffffc0205bc6 <do_execve+0x270>
        if (ph->p_filesz > ph->p_memsz) { // 如果程序段头的文件大小大于内存大小
ffffffffc0205bd0:	0289b603          	ld	a2,40(s3)
ffffffffc0205bd4:	0209b783          	ld	a5,32(s3)
ffffffffc0205bd8:	1cf66d63          	bltu	a2,a5,ffffffffc0205db2 <do_execve+0x45c>
        if (ph->p_flags & ELF_PF_X) vm_flags |= VM_EXEC; // 如果程序段头的标志包含可执行标志，则设置虚拟内存标志为可执行
ffffffffc0205bdc:	0049a783          	lw	a5,4(s3)
ffffffffc0205be0:	0017f693          	andi	a3,a5,1
ffffffffc0205be4:	c291                	beqz	a3,ffffffffc0205be8 <do_execve+0x292>
ffffffffc0205be6:	4691                	li	a3,4
        if (ph->p_flags & ELF_PF_W) vm_flags |= VM_WRITE; // 如果程序段头的标志包含可写标志，则设置虚拟内存标志为可写
ffffffffc0205be8:	0027f713          	andi	a4,a5,2
        if (ph->p_flags & ELF_PF_R) vm_flags |= VM_READ; // 如果程序段头的标志包含可读标志，则设置虚拟内存标志为可读
ffffffffc0205bec:	8b91                	andi	a5,a5,4
        if (ph->p_flags & ELF_PF_W) vm_flags |= VM_WRITE; // 如果程序段头的标志包含可写标志，则设置虚拟内存标志为可写
ffffffffc0205bee:	e779                	bnez	a4,ffffffffc0205cbc <do_execve+0x366>
        vm_flags = 0, perm = PTE_U | PTE_V; // 初始化虚拟内存标志和权限
ffffffffc0205bf0:	4d45                	li	s10,17
        if (ph->p_flags & ELF_PF_R) vm_flags |= VM_READ; // 如果程序段头的标志包含可读标志，则设置虚拟内存标志为可读
ffffffffc0205bf2:	c781                	beqz	a5,ffffffffc0205bfa <do_execve+0x2a4>
ffffffffc0205bf4:	0016e693          	ori	a3,a3,1
        if (vm_flags & VM_READ) perm |= PTE_R; // 如果虚拟内存标志包含可读标志，则设置权限为可读
ffffffffc0205bf8:	4d4d                	li	s10,19
        if (vm_flags & VM_WRITE) perm |= (PTE_W | PTE_R); // 如果虚拟内存标志包含可写标志，则设置权限为可写和可读
ffffffffc0205bfa:	0026f793          	andi	a5,a3,2
ffffffffc0205bfe:	e3f1                	bnez	a5,ffffffffc0205cc2 <do_execve+0x36c>
        if (vm_flags & VM_EXEC) perm |= PTE_X; // 如果虚拟内存标志包含可执行标志，则设置权限为可执行
ffffffffc0205c00:	0046f793          	andi	a5,a3,4
ffffffffc0205c04:	c399                	beqz	a5,ffffffffc0205c0a <do_execve+0x2b4>
ffffffffc0205c06:	008d6d13          	ori	s10,s10,8
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0) { // 调用mm_map函数设置新的虚拟内存区域，如果失败则跳转到bad_cleanup_mmap标签
ffffffffc0205c0a:	0109b583          	ld	a1,16(s3)
ffffffffc0205c0e:	4701                	li	a4,0
ffffffffc0205c10:	8526                	mv	a0,s1
ffffffffc0205c12:	e79fc0ef          	jal	ra,ffffffffc0202a8a <mm_map>
ffffffffc0205c16:	8a2a                	mv	s4,a0
ffffffffc0205c18:	ed35                	bnez	a0,ffffffffc0205c94 <do_execve+0x33e>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE); // 获取程序段头的虚拟地址起始位置和结束位置，并将起始位置向下取整到页边界
ffffffffc0205c1a:	0109bb83          	ld	s7,16(s3)
ffffffffc0205c1e:	77fd                	lui	a5,0xfffff
        end = ph->p_va + ph->p_filesz; // 获取程序段头的文件大小结束位置
ffffffffc0205c20:	0209ba03          	ld	s4,32(s3)
        unsigned char *from = binary + ph->p_offset; // 获取程序段头的偏移地址
ffffffffc0205c24:	0089b903          	ld	s2,8(s3)
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE); // 获取程序段头的虚拟地址起始位置和结束位置，并将起始位置向下取整到页边界
ffffffffc0205c28:	00fbfab3          	and	s5,s7,a5
        unsigned char *from = binary + ph->p_offset; // 获取程序段头的偏移地址
ffffffffc0205c2c:	7782                	ld	a5,32(sp)
        end = ph->p_va + ph->p_filesz; // 获取程序段头的文件大小结束位置
ffffffffc0205c2e:	9a5e                	add	s4,s4,s7
        unsigned char *from = binary + ph->p_offset; // 获取程序段头的偏移地址
ffffffffc0205c30:	993e                	add	s2,s2,a5
        while (start < end) { // 遍历每个页
ffffffffc0205c32:	054be963          	bltu	s7,s4,ffffffffc0205c84 <do_execve+0x32e>
ffffffffc0205c36:	aa95                	j	ffffffffc0205daa <do_execve+0x454>
            off = start - la, size = PGSIZE - off, la += PGSIZE; // 计算偏移量和大小，并更新虚拟地址
ffffffffc0205c38:	6785                	lui	a5,0x1
ffffffffc0205c3a:	415b8533          	sub	a0,s7,s5
ffffffffc0205c3e:	9abe                	add	s5,s5,a5
ffffffffc0205c40:	417a8633          	sub	a2,s5,s7
            if (end < la) { // 如果结束位置小于虚拟地址
ffffffffc0205c44:	015a7463          	bgeu	s4,s5,ffffffffc0205c4c <do_execve+0x2f6>
                size -= la - end; // 更新大小
ffffffffc0205c48:	417a0633          	sub	a2,s4,s7
    return page - pages + nbase;
ffffffffc0205c4c:	000cb683          	ld	a3,0(s9)
ffffffffc0205c50:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0205c52:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc0205c56:	40d406b3          	sub	a3,s0,a3
ffffffffc0205c5a:	8699                	srai	a3,a3,0x6
ffffffffc0205c5c:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0205c5e:	67e2                	ld	a5,24(sp)
ffffffffc0205c60:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0205c64:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0205c66:	14b87863          	bgeu	a6,a1,ffffffffc0205db6 <do_execve+0x460>
ffffffffc0205c6a:	000b3803          	ld	a6,0(s6)
            memcpy(page2kva(page) + off, from, size); // 将二进制程序的内容复制到页中
ffffffffc0205c6e:	85ca                	mv	a1,s2
            start += size, from += size; // 更新起始位置和偏移地址
ffffffffc0205c70:	9bb2                	add	s7,s7,a2
ffffffffc0205c72:	96c2                	add	a3,a3,a6
            memcpy(page2kva(page) + off, from, size); // 将二进制程序的内容复制到页中
ffffffffc0205c74:	9536                	add	a0,a0,a3
            start += size, from += size; // 更新起始位置和偏移地址
ffffffffc0205c76:	e432                	sd	a2,8(sp)
            memcpy(page2kva(page) + off, from, size); // 将二进制程序的内容复制到页中
ffffffffc0205c78:	6e4000ef          	jal	ra,ffffffffc020635c <memcpy>
            start += size, from += size; // 更新起始位置和偏移地址
ffffffffc0205c7c:	6622                	ld	a2,8(sp)
ffffffffc0205c7e:	9932                	add	s2,s2,a2
        while (start < end) { // 遍历每个页
ffffffffc0205c80:	054bf363          	bgeu	s7,s4,ffffffffc0205cc6 <do_execve+0x370>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL) { // 分配页，如果失败则跳转到bad_cleanup_mmap标签
ffffffffc0205c84:	6c88                	ld	a0,24(s1)
ffffffffc0205c86:	866a                	mv	a2,s10
ffffffffc0205c88:	85d6                	mv	a1,s5
ffffffffc0205c8a:	b4bfc0ef          	jal	ra,ffffffffc02027d4 <pgdir_alloc_page>
ffffffffc0205c8e:	842a                	mv	s0,a0
ffffffffc0205c90:	f545                	bnez	a0,ffffffffc0205c38 <do_execve+0x2e2>
        ret = -E_NO_MEM; // 设置返回值为内存不足错误码
ffffffffc0205c92:	5a71                	li	s4,-4
    exit_mmap(mm); // 退出内存映射
ffffffffc0205c94:	8526                	mv	a0,s1
ffffffffc0205c96:	ea5fc0ef          	jal	ra,ffffffffc0202b3a <exit_mmap>
    put_pgdir(mm); // 释放页目录表
ffffffffc0205c9a:	8526                	mv	a0,s1
ffffffffc0205c9c:	c4aff0ef          	jal	ra,ffffffffc02050e6 <put_pgdir>
    mm_destroy(mm); // 销毁内存管理结构体
ffffffffc0205ca0:	8526                	mv	a0,s1
ffffffffc0205ca2:	d97fc0ef          	jal	ra,ffffffffc0202a38 <mm_destroy>
    return ret; // 返回结果
ffffffffc0205ca6:	b705                	j	ffffffffc0205bc6 <do_execve+0x270>
            exit_mmap(mm); // 退出内存映射
ffffffffc0205ca8:	854e                	mv	a0,s3
ffffffffc0205caa:	e91fc0ef          	jal	ra,ffffffffc0202b3a <exit_mmap>
            put_pgdir(mm); // 释放页目录表
ffffffffc0205cae:	854e                	mv	a0,s3
ffffffffc0205cb0:	c36ff0ef          	jal	ra,ffffffffc02050e6 <put_pgdir>
            mm_destroy(mm); // 销毁内存管理结构体
ffffffffc0205cb4:	854e                	mv	a0,s3
ffffffffc0205cb6:	d83fc0ef          	jal	ra,ffffffffc0202a38 <mm_destroy>
ffffffffc0205cba:	b33d                	j	ffffffffc02059e8 <do_execve+0x92>
        if (ph->p_flags & ELF_PF_W) vm_flags |= VM_WRITE; // 如果程序段头的标志包含可写标志，则设置虚拟内存标志为可写
ffffffffc0205cbc:	0026e693          	ori	a3,a3,2
        if (ph->p_flags & ELF_PF_R) vm_flags |= VM_READ; // 如果程序段头的标志包含可读标志，则设置虚拟内存标志为可读
ffffffffc0205cc0:	fb95                	bnez	a5,ffffffffc0205bf4 <do_execve+0x29e>
        if (vm_flags & VM_WRITE) perm |= (PTE_W | PTE_R); // 如果虚拟内存标志包含可写标志，则设置权限为可写和可读
ffffffffc0205cc2:	4d5d                	li	s10,23
ffffffffc0205cc4:	bf35                	j	ffffffffc0205c00 <do_execve+0x2aa>
        end = ph->p_va + ph->p_memsz; // 获取程序段头的内存大小结束位置
ffffffffc0205cc6:	0109b683          	ld	a3,16(s3)
ffffffffc0205cca:	0289b903          	ld	s2,40(s3)
ffffffffc0205cce:	9936                	add	s2,s2,a3
        if (start < la) { // 如果起始位置小于虚拟地址
ffffffffc0205cd0:	075bfd63          	bgeu	s7,s5,ffffffffc0205d4a <do_execve+0x3f4>
            if (start == end) { // 如果起始位置等于结束位置
ffffffffc0205cd4:	dd7901e3          	beq	s2,s7,ffffffffc0205a96 <do_execve+0x140>
            off = start + PGSIZE - la, size = PGSIZE - off; // 计算偏移量和大小
ffffffffc0205cd8:	6785                	lui	a5,0x1
ffffffffc0205cda:	00fb8533          	add	a0,s7,a5
ffffffffc0205cde:	41550533          	sub	a0,a0,s5
                size -= la - end; // 更新大小
ffffffffc0205ce2:	41790a33          	sub	s4,s2,s7
            if (end < la) { // 如果结束位置小于虚拟地址
ffffffffc0205ce6:	0b597d63          	bgeu	s2,s5,ffffffffc0205da0 <do_execve+0x44a>
    return page - pages + nbase;
ffffffffc0205cea:	000cb683          	ld	a3,0(s9)
ffffffffc0205cee:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0205cf0:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc0205cf4:	40d406b3          	sub	a3,s0,a3
ffffffffc0205cf8:	8699                	srai	a3,a3,0x6
ffffffffc0205cfa:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0205cfc:	67e2                	ld	a5,24(sp)
ffffffffc0205cfe:	00f6f5b3          	and	a1,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0205d02:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0205d04:	0ac5f963          	bgeu	a1,a2,ffffffffc0205db6 <do_execve+0x460>
ffffffffc0205d08:	000b3803          	ld	a6,0(s6)
            memset(page2kva(page) + off, 0, size); // 将页中的内容清零
ffffffffc0205d0c:	8652                	mv	a2,s4
ffffffffc0205d0e:	4581                	li	a1,0
ffffffffc0205d10:	96c2                	add	a3,a3,a6
ffffffffc0205d12:	9536                	add	a0,a0,a3
ffffffffc0205d14:	636000ef          	jal	ra,ffffffffc020634a <memset>
            start += size; // 更新起始位置
ffffffffc0205d18:	017a0733          	add	a4,s4,s7
            assert((end < la && start == end) || (end >= la && start == la)); // 断言结束位置和起始位置的关系
ffffffffc0205d1c:	03597463          	bgeu	s2,s5,ffffffffc0205d44 <do_execve+0x3ee>
ffffffffc0205d20:	d6e90be3          	beq	s2,a4,ffffffffc0205a96 <do_execve+0x140>
ffffffffc0205d24:	00003697          	auipc	a3,0x3
ffffffffc0205d28:	aa468693          	addi	a3,a3,-1372 # ffffffffc02087c8 <default_pmm_manager+0x2d8>
ffffffffc0205d2c:	00001617          	auipc	a2,0x1
ffffffffc0205d30:	10460613          	addi	a2,a2,260 # ffffffffc0206e30 <commands+0x410>
ffffffffc0205d34:	27900593          	li	a1,633
ffffffffc0205d38:	00003517          	auipc	a0,0x3
ffffffffc0205d3c:	8a850513          	addi	a0,a0,-1880 # ffffffffc02085e0 <default_pmm_manager+0xf0>
ffffffffc0205d40:	cc8fa0ef          	jal	ra,ffffffffc0200208 <__panic>
ffffffffc0205d44:	ff5710e3          	bne	a4,s5,ffffffffc0205d24 <do_execve+0x3ce>
ffffffffc0205d48:	8bd6                	mv	s7,s5
        while (start < end) { // 遍历每个页
ffffffffc0205d4a:	d52bf6e3          	bgeu	s7,s2,ffffffffc0205a96 <do_execve+0x140>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL) { // 分配页，如果失败则跳转到bad_cleanup_mmap标签
ffffffffc0205d4e:	6c88                	ld	a0,24(s1)
ffffffffc0205d50:	866a                	mv	a2,s10
ffffffffc0205d52:	85d6                	mv	a1,s5
ffffffffc0205d54:	a81fc0ef          	jal	ra,ffffffffc02027d4 <pgdir_alloc_page>
ffffffffc0205d58:	842a                	mv	s0,a0
ffffffffc0205d5a:	dd05                	beqz	a0,ffffffffc0205c92 <do_execve+0x33c>
            off = start - la, size = PGSIZE - off, la += PGSIZE; // 计算偏移量和大小，并更新虚拟地址
ffffffffc0205d5c:	6785                	lui	a5,0x1
ffffffffc0205d5e:	415b8533          	sub	a0,s7,s5
ffffffffc0205d62:	9abe                	add	s5,s5,a5
ffffffffc0205d64:	417a8633          	sub	a2,s5,s7
            if (end < la) { // 如果结束位置小于虚拟地址
ffffffffc0205d68:	01597463          	bgeu	s2,s5,ffffffffc0205d70 <do_execve+0x41a>
                size -= la - end; // 更新大小
ffffffffc0205d6c:	41790633          	sub	a2,s2,s7
    return page - pages + nbase;
ffffffffc0205d70:	000cb683          	ld	a3,0(s9)
ffffffffc0205d74:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0205d76:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc0205d7a:	40d406b3          	sub	a3,s0,a3
ffffffffc0205d7e:	8699                	srai	a3,a3,0x6
ffffffffc0205d80:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0205d82:	67e2                	ld	a5,24(sp)
ffffffffc0205d84:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0205d88:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0205d8a:	02b87663          	bgeu	a6,a1,ffffffffc0205db6 <do_execve+0x460>
ffffffffc0205d8e:	000b3803          	ld	a6,0(s6)
            memset(page2kva(page) + off, 0, size); // 将页中的内容清零
ffffffffc0205d92:	4581                	li	a1,0
            start += size; // 更新起始位置
ffffffffc0205d94:	9bb2                	add	s7,s7,a2
ffffffffc0205d96:	96c2                	add	a3,a3,a6
            memset(page2kva(page) + off, 0, size); // 将页中的内容清零
ffffffffc0205d98:	9536                	add	a0,a0,a3
ffffffffc0205d9a:	5b0000ef          	jal	ra,ffffffffc020634a <memset>
ffffffffc0205d9e:	b775                	j	ffffffffc0205d4a <do_execve+0x3f4>
            off = start + PGSIZE - la, size = PGSIZE - off; // 计算偏移量和大小
ffffffffc0205da0:	417a8a33          	sub	s4,s5,s7
ffffffffc0205da4:	b799                	j	ffffffffc0205cea <do_execve+0x394>
        return -E_INVAL; // 如果不合法，返回 -E_INVAL 错误码
ffffffffc0205da6:	5a75                	li	s4,-3
ffffffffc0205da8:	b3c1                	j	ffffffffc0205b68 <do_execve+0x212>
        while (start < end) { // 遍历每个页
ffffffffc0205daa:	86de                	mv	a3,s7
ffffffffc0205dac:	bf39                	j	ffffffffc0205cca <do_execve+0x374>
    int ret = -E_NO_MEM; // 初始化返回值为内存不足错误码
ffffffffc0205dae:	5a71                	li	s4,-4
ffffffffc0205db0:	bdc5                	j	ffffffffc0205ca0 <do_execve+0x34a>
            ret = -E_INVAL_ELF; // 设置返回值为无效的ELF错误码
ffffffffc0205db2:	5a61                	li	s4,-8
ffffffffc0205db4:	b5c5                	j	ffffffffc0205c94 <do_execve+0x33e>
ffffffffc0205db6:	00001617          	auipc	a2,0x1
ffffffffc0205dba:	43260613          	addi	a2,a2,1074 # ffffffffc02071e8 <commands+0x7c8>
ffffffffc0205dbe:	06900593          	li	a1,105
ffffffffc0205dc2:	00001517          	auipc	a0,0x1
ffffffffc0205dc6:	3d650513          	addi	a0,a0,982 # ffffffffc0207198 <commands+0x778>
ffffffffc0205dca:	c3efa0ef          	jal	ra,ffffffffc0200208 <__panic>
    current->cr3 = PADDR(mm->pgdir); // 将当前进程的CR3寄存器设置为页目录表的物理地址
ffffffffc0205dce:	00001617          	auipc	a2,0x1
ffffffffc0205dd2:	46a60613          	addi	a2,a2,1130 # ffffffffc0207238 <commands+0x818>
ffffffffc0205dd6:	29400593          	li	a1,660
ffffffffc0205dda:	00003517          	auipc	a0,0x3
ffffffffc0205dde:	80650513          	addi	a0,a0,-2042 # ffffffffc02085e0 <default_pmm_manager+0xf0>
ffffffffc0205de2:	c26fa0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-4*PGSIZE , PTE_USER) != NULL); // 断言分配页成功
ffffffffc0205de6:	00003697          	auipc	a3,0x3
ffffffffc0205dea:	afa68693          	addi	a3,a3,-1286 # ffffffffc02088e0 <default_pmm_manager+0x3f0>
ffffffffc0205dee:	00001617          	auipc	a2,0x1
ffffffffc0205df2:	04260613          	addi	a2,a2,66 # ffffffffc0206e30 <commands+0x410>
ffffffffc0205df6:	28f00593          	li	a1,655
ffffffffc0205dfa:	00002517          	auipc	a0,0x2
ffffffffc0205dfe:	7e650513          	addi	a0,a0,2022 # ffffffffc02085e0 <default_pmm_manager+0xf0>
ffffffffc0205e02:	c06fa0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-3*PGSIZE , PTE_USER) != NULL); // 断言分配页成功
ffffffffc0205e06:	00003697          	auipc	a3,0x3
ffffffffc0205e0a:	a9268693          	addi	a3,a3,-1390 # ffffffffc0208898 <default_pmm_manager+0x3a8>
ffffffffc0205e0e:	00001617          	auipc	a2,0x1
ffffffffc0205e12:	02260613          	addi	a2,a2,34 # ffffffffc0206e30 <commands+0x410>
ffffffffc0205e16:	28e00593          	li	a1,654
ffffffffc0205e1a:	00002517          	auipc	a0,0x2
ffffffffc0205e1e:	7c650513          	addi	a0,a0,1990 # ffffffffc02085e0 <default_pmm_manager+0xf0>
ffffffffc0205e22:	be6fa0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-2*PGSIZE , PTE_USER) != NULL); // 断言分配页成功
ffffffffc0205e26:	00003697          	auipc	a3,0x3
ffffffffc0205e2a:	a2a68693          	addi	a3,a3,-1494 # ffffffffc0208850 <default_pmm_manager+0x360>
ffffffffc0205e2e:	00001617          	auipc	a2,0x1
ffffffffc0205e32:	00260613          	addi	a2,a2,2 # ffffffffc0206e30 <commands+0x410>
ffffffffc0205e36:	28d00593          	li	a1,653
ffffffffc0205e3a:	00002517          	auipc	a0,0x2
ffffffffc0205e3e:	7a650513          	addi	a0,a0,1958 # ffffffffc02085e0 <default_pmm_manager+0xf0>
ffffffffc0205e42:	bc6fa0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-PGSIZE , PTE_USER) != NULL); // 断言分配页成功
ffffffffc0205e46:	00003697          	auipc	a3,0x3
ffffffffc0205e4a:	9c268693          	addi	a3,a3,-1598 # ffffffffc0208808 <default_pmm_manager+0x318>
ffffffffc0205e4e:	00001617          	auipc	a2,0x1
ffffffffc0205e52:	fe260613          	addi	a2,a2,-30 # ffffffffc0206e30 <commands+0x410>
ffffffffc0205e56:	28c00593          	li	a1,652
ffffffffc0205e5a:	00002517          	auipc	a0,0x2
ffffffffc0205e5e:	78650513          	addi	a0,a0,1926 # ffffffffc02085e0 <default_pmm_manager+0xf0>
ffffffffc0205e62:	ba6fa0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0205e66 <do_yield>:
    current->need_resched = 1; // 设置当前进程需要重新调度标志为1
ffffffffc0205e66:	000ad797          	auipc	a5,0xad
ffffffffc0205e6a:	a627b783          	ld	a5,-1438(a5) # ffffffffc02b28c8 <current>
ffffffffc0205e6e:	4705                	li	a4,1
ffffffffc0205e70:	ef98                	sd	a4,24(a5)
}
ffffffffc0205e72:	4501                	li	a0,0
ffffffffc0205e74:	8082                	ret

ffffffffc0205e76 <do_wait>:
do_wait(int pid, int *code_store) {
ffffffffc0205e76:	1101                	addi	sp,sp,-32
ffffffffc0205e78:	e822                	sd	s0,16(sp)
ffffffffc0205e7a:	e426                	sd	s1,8(sp)
ffffffffc0205e7c:	ec06                	sd	ra,24(sp)
ffffffffc0205e7e:	842e                	mv	s0,a1
ffffffffc0205e80:	84aa                	mv	s1,a0
    if (code_store != NULL) { // 如果code_store不为空
ffffffffc0205e82:	c999                	beqz	a1,ffffffffc0205e98 <do_wait+0x22>
    struct mm_struct *mm = current->mm; // 获取当前进程的内存管理结构体
ffffffffc0205e84:	000ad797          	auipc	a5,0xad
ffffffffc0205e88:	a447b783          	ld	a5,-1468(a5) # ffffffffc02b28c8 <current>
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1)) { // 检查用户内存是否合法
ffffffffc0205e8c:	7788                	ld	a0,40(a5)
ffffffffc0205e8e:	4685                	li	a3,1
ffffffffc0205e90:	4611                	li	a2,4
ffffffffc0205e92:	b7efd0ef          	jal	ra,ffffffffc0203210 <user_mem_check>
ffffffffc0205e96:	c909                	beqz	a0,ffffffffc0205ea8 <do_wait+0x32>
ffffffffc0205e98:	85a2                	mv	a1,s0
}
ffffffffc0205e9a:	6442                	ld	s0,16(sp)
ffffffffc0205e9c:	60e2                	ld	ra,24(sp)
ffffffffc0205e9e:	8526                	mv	a0,s1
ffffffffc0205ea0:	64a2                	ld	s1,8(sp)
ffffffffc0205ea2:	6105                	addi	sp,sp,32
ffffffffc0205ea4:	fbcff06f          	j	ffffffffc0205660 <do_wait.part.0>
ffffffffc0205ea8:	60e2                	ld	ra,24(sp)
ffffffffc0205eaa:	6442                	ld	s0,16(sp)
ffffffffc0205eac:	64a2                	ld	s1,8(sp)
ffffffffc0205eae:	5575                	li	a0,-3
ffffffffc0205eb0:	6105                	addi	sp,sp,32
ffffffffc0205eb2:	8082                	ret

ffffffffc0205eb4 <do_kill>:
do_kill(int pid) {
ffffffffc0205eb4:	1141                	addi	sp,sp,-16
    if (0 < pid && pid < MAX_PID) { // 如果pid在有效范围内
ffffffffc0205eb6:	6789                	lui	a5,0x2
do_kill(int pid) {
ffffffffc0205eb8:	e406                	sd	ra,8(sp)
ffffffffc0205eba:	e022                	sd	s0,0(sp)
    if (0 < pid && pid < MAX_PID) { // 如果pid在有效范围内
ffffffffc0205ebc:	fff5071b          	addiw	a4,a0,-1
ffffffffc0205ec0:	17f9                	addi	a5,a5,-2
ffffffffc0205ec2:	02e7e963          	bltu	a5,a4,ffffffffc0205ef4 <do_kill+0x40>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list; // 获取哈希链表的起始位置
ffffffffc0205ec6:	842a                	mv	s0,a0
ffffffffc0205ec8:	45a9                	li	a1,10
ffffffffc0205eca:	2501                	sext.w	a0,a0
ffffffffc0205ecc:	097000ef          	jal	ra,ffffffffc0206762 <hash32>
ffffffffc0205ed0:	02051793          	slli	a5,a0,0x20
ffffffffc0205ed4:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0205ed8:	000a9797          	auipc	a5,0xa9
ffffffffc0205edc:	96878793          	addi	a5,a5,-1688 # ffffffffc02ae840 <hash_list>
ffffffffc0205ee0:	953e                	add	a0,a0,a5
ffffffffc0205ee2:	87aa                	mv	a5,a0
        while ((le = list_next(le)) != list) { // 遍历哈希链表
ffffffffc0205ee4:	a029                	j	ffffffffc0205eee <do_kill+0x3a>
            if (proc->pid == pid) { // 如果找到匹配的pid
ffffffffc0205ee6:	f2c7a703          	lw	a4,-212(a5)
ffffffffc0205eea:	00870b63          	beq	a4,s0,ffffffffc0205f00 <do_kill+0x4c>
ffffffffc0205eee:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list) { // 遍历哈希链表
ffffffffc0205ef0:	fef51be3          	bne	a0,a5,ffffffffc0205ee6 <do_kill+0x32>
    return -E_INVAL; // 返回 -E_INVAL 表示无效的 pid
ffffffffc0205ef4:	5475                	li	s0,-3
}
ffffffffc0205ef6:	60a2                	ld	ra,8(sp)
ffffffffc0205ef8:	8522                	mv	a0,s0
ffffffffc0205efa:	6402                	ld	s0,0(sp)
ffffffffc0205efc:	0141                	addi	sp,sp,16
ffffffffc0205efe:	8082                	ret
        if (!(proc->flags & PF_EXITING)) { // 如果进程的标志不包含 PF_EXITING
ffffffffc0205f00:	fd87a703          	lw	a4,-40(a5)
ffffffffc0205f04:	00177693          	andi	a3,a4,1
ffffffffc0205f08:	e295                	bnez	a3,ffffffffc0205f2c <do_kill+0x78>
            if (proc->wait_state & WT_INTERRUPTED) { // 如果进程的等待状态包含 WT_INTERRUPTED
ffffffffc0205f0a:	4bd4                	lw	a3,20(a5)
            proc->flags |= PF_EXITING; // 设置进程的标志为 PF_EXITING
ffffffffc0205f0c:	00176713          	ori	a4,a4,1
ffffffffc0205f10:	fce7ac23          	sw	a4,-40(a5)
            return 0; // 返回 0 表示成功
ffffffffc0205f14:	4401                	li	s0,0
            if (proc->wait_state & WT_INTERRUPTED) { // 如果进程的等待状态包含 WT_INTERRUPTED
ffffffffc0205f16:	fe06d0e3          	bgez	a3,ffffffffc0205ef6 <do_kill+0x42>
                wakeup_proc(proc); // 唤醒进程
ffffffffc0205f1a:	f2878513          	addi	a0,a5,-216
ffffffffc0205f1e:	1c4000ef          	jal	ra,ffffffffc02060e2 <wakeup_proc>
}
ffffffffc0205f22:	60a2                	ld	ra,8(sp)
ffffffffc0205f24:	8522                	mv	a0,s0
ffffffffc0205f26:	6402                	ld	s0,0(sp)
ffffffffc0205f28:	0141                	addi	sp,sp,16
ffffffffc0205f2a:	8082                	ret
        return -E_KILLED; // 返回 -E_KILLED 表示进程已经被杀死
ffffffffc0205f2c:	545d                	li	s0,-9
ffffffffc0205f2e:	b7e1                	j	ffffffffc0205ef6 <do_kill+0x42>

ffffffffc0205f30 <proc_init>:

// proc_init - 通过自身设置第一个内核线程 idleproc "idle"
//           - 创建第二个内核线程 init_main
void
proc_init(void) {
ffffffffc0205f30:	1101                	addi	sp,sp,-32
ffffffffc0205f32:	e426                	sd	s1,8(sp)
    elm->prev = elm->next = elm;
ffffffffc0205f34:	000ad797          	auipc	a5,0xad
ffffffffc0205f38:	90c78793          	addi	a5,a5,-1780 # ffffffffc02b2840 <proc_list>
ffffffffc0205f3c:	ec06                	sd	ra,24(sp)
ffffffffc0205f3e:	e822                	sd	s0,16(sp)
ffffffffc0205f40:	e04a                	sd	s2,0(sp)
ffffffffc0205f42:	000a9497          	auipc	s1,0xa9
ffffffffc0205f46:	8fe48493          	addi	s1,s1,-1794 # ffffffffc02ae840 <hash_list>
ffffffffc0205f4a:	e79c                	sd	a5,8(a5)
ffffffffc0205f4c:	e39c                	sd	a5,0(a5)
    int i; // 定义一个整型变量 i

    list_init(&proc_list); // 初始化进程列表
    for (i = 0; i < HASH_LIST_SIZE; i ++) { // 遍历哈希列表大小
ffffffffc0205f4e:	000ad717          	auipc	a4,0xad
ffffffffc0205f52:	8f270713          	addi	a4,a4,-1806 # ffffffffc02b2840 <proc_list>
ffffffffc0205f56:	87a6                	mv	a5,s1
ffffffffc0205f58:	e79c                	sd	a5,8(a5)
ffffffffc0205f5a:	e39c                	sd	a5,0(a5)
ffffffffc0205f5c:	07c1                	addi	a5,a5,16
ffffffffc0205f5e:	fef71de3          	bne	a4,a5,ffffffffc0205f58 <proc_init+0x28>
        list_init(hash_list + i); // 初始化每个哈希列表
    }

    if ((idleproc = alloc_proc()) == NULL) { // 分配 idleproc，如果失败则触发 panic
ffffffffc0205f62:	886ff0ef          	jal	ra,ffffffffc0204fe8 <alloc_proc>
ffffffffc0205f66:	000ad917          	auipc	s2,0xad
ffffffffc0205f6a:	96a90913          	addi	s2,s2,-1686 # ffffffffc02b28d0 <idleproc>
ffffffffc0205f6e:	00a93023          	sd	a0,0(s2)
ffffffffc0205f72:	0e050f63          	beqz	a0,ffffffffc0206070 <proc_init+0x140>
        panic("cannot alloc idleproc.\n"); // 触发 panic，无法分配 idleproc
    }

    idleproc->pid = 0; // 设置 idleproc 的 pid 为 0
    idleproc->state = PROC_RUNNABLE; // 设置 idleproc 的状态为可运行
ffffffffc0205f76:	4789                	li	a5,2
ffffffffc0205f78:	e11c                	sd	a5,0(a0)
    idleproc->kstack = (uintptr_t)bootstack; // 设置 idleproc 的内核栈为 bootstack
ffffffffc0205f7a:	00003797          	auipc	a5,0x3
ffffffffc0205f7e:	08678793          	addi	a5,a5,134 # ffffffffc0209000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name)); // 将proc->name的内存清零
ffffffffc0205f82:	0b450413          	addi	s0,a0,180
    idleproc->kstack = (uintptr_t)bootstack; // 设置 idleproc 的内核栈为 bootstack
ffffffffc0205f86:	e91c                	sd	a5,16(a0)
    idleproc->need_resched = 1; // 设置 idleproc 需要重新调度
ffffffffc0205f88:	4785                	li	a5,1
ffffffffc0205f8a:	ed1c                	sd	a5,24(a0)
    memset(proc->name, 0, sizeof(proc->name)); // 将proc->name的内存清零
ffffffffc0205f8c:	4641                	li	a2,16
ffffffffc0205f8e:	4581                	li	a1,0
ffffffffc0205f90:	8522                	mv	a0,s0
ffffffffc0205f92:	3b8000ef          	jal	ra,ffffffffc020634a <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN); // 将name复制到proc->name中，长度为PROC_NAME_LEN
ffffffffc0205f96:	463d                	li	a2,15
ffffffffc0205f98:	00003597          	auipc	a1,0x3
ffffffffc0205f9c:	9a858593          	addi	a1,a1,-1624 # ffffffffc0208940 <default_pmm_manager+0x450>
ffffffffc0205fa0:	8522                	mv	a0,s0
ffffffffc0205fa2:	3ba000ef          	jal	ra,ffffffffc020635c <memcpy>
    set_proc_name(idleproc, "idle"); // 设置 idleproc 的名称为 "idle"
    nr_process ++; // 进程数量加 1
ffffffffc0205fa6:	000ad717          	auipc	a4,0xad
ffffffffc0205faa:	93a70713          	addi	a4,a4,-1734 # ffffffffc02b28e0 <nr_process>
ffffffffc0205fae:	431c                	lw	a5,0(a4)

    current = idleproc; // 将当前进程设置为 idleproc
ffffffffc0205fb0:	00093683          	ld	a3,0(s2)

    int pid = kernel_thread(init_main, NULL, 0); // 创建 init_main 内核线程
ffffffffc0205fb4:	4601                	li	a2,0
    nr_process ++; // 进程数量加 1
ffffffffc0205fb6:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, NULL, 0); // 创建 init_main 内核线程
ffffffffc0205fb8:	4581                	li	a1,0
ffffffffc0205fba:	00000517          	auipc	a0,0x0
ffffffffc0205fbe:	87850513          	addi	a0,a0,-1928 # ffffffffc0205832 <init_main>
    nr_process ++; // 进程数量加 1
ffffffffc0205fc2:	c31c                	sw	a5,0(a4)
    current = idleproc; // 将当前进程设置为 idleproc
ffffffffc0205fc4:	000ad797          	auipc	a5,0xad
ffffffffc0205fc8:	90d7b223          	sd	a3,-1788(a5) # ffffffffc02b28c8 <current>
    int pid = kernel_thread(init_main, NULL, 0); // 创建 init_main 内核线程
ffffffffc0205fcc:	cfaff0ef          	jal	ra,ffffffffc02054c6 <kernel_thread>
ffffffffc0205fd0:	842a                	mv	s0,a0
    if (pid <= 0) { // 如果创建失败
ffffffffc0205fd2:	08a05363          	blez	a0,ffffffffc0206058 <proc_init+0x128>
    if (0 < pid && pid < MAX_PID) { // 如果pid在有效范围内
ffffffffc0205fd6:	6789                	lui	a5,0x2
ffffffffc0205fd8:	fff5071b          	addiw	a4,a0,-1
ffffffffc0205fdc:	17f9                	addi	a5,a5,-2
ffffffffc0205fde:	2501                	sext.w	a0,a0
ffffffffc0205fe0:	02e7e363          	bltu	a5,a4,ffffffffc0206006 <proc_init+0xd6>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list; // 获取哈希链表的起始位置
ffffffffc0205fe4:	45a9                	li	a1,10
ffffffffc0205fe6:	77c000ef          	jal	ra,ffffffffc0206762 <hash32>
ffffffffc0205fea:	02051793          	slli	a5,a0,0x20
ffffffffc0205fee:	01c7d693          	srli	a3,a5,0x1c
ffffffffc0205ff2:	96a6                	add	a3,a3,s1
ffffffffc0205ff4:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list) { // 遍历哈希链表
ffffffffc0205ff6:	a029                	j	ffffffffc0206000 <proc_init+0xd0>
            if (proc->pid == pid) { // 如果找到匹配的pid
ffffffffc0205ff8:	f2c7a703          	lw	a4,-212(a5) # 1f2c <_binary_obj___user_faultread_out_size-0x7c8c>
ffffffffc0205ffc:	04870b63          	beq	a4,s0,ffffffffc0206052 <proc_init+0x122>
    return listelm->next;
ffffffffc0206000:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list) { // 遍历哈希链表
ffffffffc0206002:	fef69be3          	bne	a3,a5,ffffffffc0205ff8 <proc_init+0xc8>
    return NULL; // 如果没有找到匹配的pid，返回NULL
ffffffffc0206006:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name)); // 将proc->name的内存清零
ffffffffc0206008:	0b478493          	addi	s1,a5,180
ffffffffc020600c:	4641                	li	a2,16
ffffffffc020600e:	4581                	li	a1,0
        panic("create init_main failed.\n"); // 触发 panic，创建 init_main 失败
    }

    initproc = find_proc(pid); // 查找 initproc
ffffffffc0206010:	000ad417          	auipc	s0,0xad
ffffffffc0206014:	8c840413          	addi	s0,s0,-1848 # ffffffffc02b28d8 <initproc>
    memset(proc->name, 0, sizeof(proc->name)); // 将proc->name的内存清零
ffffffffc0206018:	8526                	mv	a0,s1
    initproc = find_proc(pid); // 查找 initproc
ffffffffc020601a:	e01c                	sd	a5,0(s0)
    memset(proc->name, 0, sizeof(proc->name)); // 将proc->name的内存清零
ffffffffc020601c:	32e000ef          	jal	ra,ffffffffc020634a <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN); // 将name复制到proc->name中，长度为PROC_NAME_LEN
ffffffffc0206020:	463d                	li	a2,15
ffffffffc0206022:	00003597          	auipc	a1,0x3
ffffffffc0206026:	94658593          	addi	a1,a1,-1722 # ffffffffc0208968 <default_pmm_manager+0x478>
ffffffffc020602a:	8526                	mv	a0,s1
ffffffffc020602c:	330000ef          	jal	ra,ffffffffc020635c <memcpy>
    set_proc_name(initproc, "init"); // 设置 initproc 的名称为 "init"

    assert(idleproc != NULL && idleproc->pid == 0); // 确保 idleproc 不为空且 pid 为 0
ffffffffc0206030:	00093783          	ld	a5,0(s2)
ffffffffc0206034:	cbb5                	beqz	a5,ffffffffc02060a8 <proc_init+0x178>
ffffffffc0206036:	43dc                	lw	a5,4(a5)
ffffffffc0206038:	eba5                	bnez	a5,ffffffffc02060a8 <proc_init+0x178>
    assert(initproc != NULL && initproc->pid == 1); // 确保 initproc 不为空且 pid 为 1
ffffffffc020603a:	601c                	ld	a5,0(s0)
ffffffffc020603c:	c7b1                	beqz	a5,ffffffffc0206088 <proc_init+0x158>
ffffffffc020603e:	43d8                	lw	a4,4(a5)
ffffffffc0206040:	4785                	li	a5,1
ffffffffc0206042:	04f71363          	bne	a4,a5,ffffffffc0206088 <proc_init+0x158>
}
ffffffffc0206046:	60e2                	ld	ra,24(sp)
ffffffffc0206048:	6442                	ld	s0,16(sp)
ffffffffc020604a:	64a2                	ld	s1,8(sp)
ffffffffc020604c:	6902                	ld	s2,0(sp)
ffffffffc020604e:	6105                	addi	sp,sp,32
ffffffffc0206050:	8082                	ret
            struct proc_struct *proc = le2proc(le, hash_link); // 获取链表元素对应的进程结构体指针
ffffffffc0206052:	f2878793          	addi	a5,a5,-216
ffffffffc0206056:	bf4d                	j	ffffffffc0206008 <proc_init+0xd8>
        panic("create init_main failed.\n"); // 触发 panic，创建 init_main 失败
ffffffffc0206058:	00003617          	auipc	a2,0x3
ffffffffc020605c:	8f060613          	addi	a2,a2,-1808 # ffffffffc0208948 <default_pmm_manager+0x458>
ffffffffc0206060:	3a100593          	li	a1,929
ffffffffc0206064:	00002517          	auipc	a0,0x2
ffffffffc0206068:	57c50513          	addi	a0,a0,1404 # ffffffffc02085e0 <default_pmm_manager+0xf0>
ffffffffc020606c:	99cfa0ef          	jal	ra,ffffffffc0200208 <__panic>
        panic("cannot alloc idleproc.\n"); // 触发 panic，无法分配 idleproc
ffffffffc0206070:	00003617          	auipc	a2,0x3
ffffffffc0206074:	8b860613          	addi	a2,a2,-1864 # ffffffffc0208928 <default_pmm_manager+0x438>
ffffffffc0206078:	39300593          	li	a1,915
ffffffffc020607c:	00002517          	auipc	a0,0x2
ffffffffc0206080:	56450513          	addi	a0,a0,1380 # ffffffffc02085e0 <default_pmm_manager+0xf0>
ffffffffc0206084:	984fa0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(initproc != NULL && initproc->pid == 1); // 确保 initproc 不为空且 pid 为 1
ffffffffc0206088:	00003697          	auipc	a3,0x3
ffffffffc020608c:	91068693          	addi	a3,a3,-1776 # ffffffffc0208998 <default_pmm_manager+0x4a8>
ffffffffc0206090:	00001617          	auipc	a2,0x1
ffffffffc0206094:	da060613          	addi	a2,a2,-608 # ffffffffc0206e30 <commands+0x410>
ffffffffc0206098:	3a800593          	li	a1,936
ffffffffc020609c:	00002517          	auipc	a0,0x2
ffffffffc02060a0:	54450513          	addi	a0,a0,1348 # ffffffffc02085e0 <default_pmm_manager+0xf0>
ffffffffc02060a4:	964fa0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(idleproc != NULL && idleproc->pid == 0); // 确保 idleproc 不为空且 pid 为 0
ffffffffc02060a8:	00003697          	auipc	a3,0x3
ffffffffc02060ac:	8c868693          	addi	a3,a3,-1848 # ffffffffc0208970 <default_pmm_manager+0x480>
ffffffffc02060b0:	00001617          	auipc	a2,0x1
ffffffffc02060b4:	d8060613          	addi	a2,a2,-640 # ffffffffc0206e30 <commands+0x410>
ffffffffc02060b8:	3a700593          	li	a1,935
ffffffffc02060bc:	00002517          	auipc	a0,0x2
ffffffffc02060c0:	52450513          	addi	a0,a0,1316 # ffffffffc02085e0 <default_pmm_manager+0xf0>
ffffffffc02060c4:	944fa0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc02060c8 <cpu_idle>:

// cpu_idle - 在 kern_init 的末尾，第一个内核线程 idleproc 将执行以下工作
void
cpu_idle(void) {
ffffffffc02060c8:	1141                	addi	sp,sp,-16
ffffffffc02060ca:	e022                	sd	s0,0(sp)
ffffffffc02060cc:	e406                	sd	ra,8(sp)
ffffffffc02060ce:	000ac417          	auipc	s0,0xac
ffffffffc02060d2:	7fa40413          	addi	s0,s0,2042 # ffffffffc02b28c8 <current>
    while (1) { // 无限循环
        if (current->need_resched) { // 如果当前进程需要重新调度
ffffffffc02060d6:	6018                	ld	a4,0(s0)
ffffffffc02060d8:	6f1c                	ld	a5,24(a4)
ffffffffc02060da:	dffd                	beqz	a5,ffffffffc02060d8 <cpu_idle+0x10>
            schedule(); // 调用调度程序进行调度
ffffffffc02060dc:	086000ef          	jal	ra,ffffffffc0206162 <schedule>
ffffffffc02060e0:	bfdd                	j	ffffffffc02060d6 <cpu_idle+0xe>

ffffffffc02060e2 <wakeup_proc>:
#include <sched.h>
#include <assert.h>

void
wakeup_proc(struct proc_struct *proc) {
    assert(proc->state != PROC_ZOMBIE); // 确保进程状态不是PROC_ZOMBIE
ffffffffc02060e2:	4118                	lw	a4,0(a0)
wakeup_proc(struct proc_struct *proc) {
ffffffffc02060e4:	1101                	addi	sp,sp,-32
ffffffffc02060e6:	ec06                	sd	ra,24(sp)
ffffffffc02060e8:	e822                	sd	s0,16(sp)
ffffffffc02060ea:	e426                	sd	s1,8(sp)
    assert(proc->state != PROC_ZOMBIE); // 确保进程状态不是PROC_ZOMBIE
ffffffffc02060ec:	478d                	li	a5,3
ffffffffc02060ee:	04f70b63          	beq	a4,a5,ffffffffc0206144 <wakeup_proc+0x62>
ffffffffc02060f2:	842a                	mv	s0,a0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02060f4:	100027f3          	csrr	a5,sstatus
ffffffffc02060f8:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02060fa:	4481                	li	s1,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02060fc:	ef9d                	bnez	a5,ffffffffc020613a <wakeup_proc+0x58>
    bool intr_flag;
    local_intr_save(intr_flag); // 保存中断状态并关闭中断
    {
        if (proc->state != PROC_RUNNABLE) { // 如果进程状态不是PROC_RUNNABLE
ffffffffc02060fe:	4789                	li	a5,2
ffffffffc0206100:	02f70163          	beq	a4,a5,ffffffffc0206122 <wakeup_proc+0x40>
            proc->state = PROC_RUNNABLE; // 将进程状态设置为PROC_RUNNABLE
ffffffffc0206104:	c01c                	sw	a5,0(s0)
            proc->wait_state = 0; // 重置等待状态
ffffffffc0206106:	0e042623          	sw	zero,236(s0)
    if (flag) {
ffffffffc020610a:	e491                	bnez	s1,ffffffffc0206116 <wakeup_proc+0x34>
        else {
            warn("wakeup runnable process.\n"); // 警告：唤醒了一个已经是可运行状态的进程
        }
    }
    local_intr_restore(intr_flag); // 恢复中断状态
}
ffffffffc020610c:	60e2                	ld	ra,24(sp)
ffffffffc020610e:	6442                	ld	s0,16(sp)
ffffffffc0206110:	64a2                	ld	s1,8(sp)
ffffffffc0206112:	6105                	addi	sp,sp,32
ffffffffc0206114:	8082                	ret
ffffffffc0206116:	6442                	ld	s0,16(sp)
ffffffffc0206118:	60e2                	ld	ra,24(sp)
ffffffffc020611a:	64a2                	ld	s1,8(sp)
ffffffffc020611c:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc020611e:	d24fa06f          	j	ffffffffc0200642 <intr_enable>
            warn("wakeup runnable process.\n"); // 警告：唤醒了一个已经是可运行状态的进程
ffffffffc0206122:	00003617          	auipc	a2,0x3
ffffffffc0206126:	8d660613          	addi	a2,a2,-1834 # ffffffffc02089f8 <default_pmm_manager+0x508>
ffffffffc020612a:	45c9                	li	a1,18
ffffffffc020612c:	00003517          	auipc	a0,0x3
ffffffffc0206130:	8b450513          	addi	a0,a0,-1868 # ffffffffc02089e0 <default_pmm_manager+0x4f0>
ffffffffc0206134:	93cfa0ef          	jal	ra,ffffffffc0200270 <__warn>
ffffffffc0206138:	bfc9                	j	ffffffffc020610a <wakeup_proc+0x28>
        intr_disable();
ffffffffc020613a:	d0efa0ef          	jal	ra,ffffffffc0200648 <intr_disable>
        if (proc->state != PROC_RUNNABLE) { // 如果进程状态不是PROC_RUNNABLE
ffffffffc020613e:	4018                	lw	a4,0(s0)
        return 1;
ffffffffc0206140:	4485                	li	s1,1
ffffffffc0206142:	bf75                	j	ffffffffc02060fe <wakeup_proc+0x1c>
    assert(proc->state != PROC_ZOMBIE); // 确保进程状态不是PROC_ZOMBIE
ffffffffc0206144:	00003697          	auipc	a3,0x3
ffffffffc0206148:	87c68693          	addi	a3,a3,-1924 # ffffffffc02089c0 <default_pmm_manager+0x4d0>
ffffffffc020614c:	00001617          	auipc	a2,0x1
ffffffffc0206150:	ce460613          	addi	a2,a2,-796 # ffffffffc0206e30 <commands+0x410>
ffffffffc0206154:	45a5                	li	a1,9
ffffffffc0206156:	00003517          	auipc	a0,0x3
ffffffffc020615a:	88a50513          	addi	a0,a0,-1910 # ffffffffc02089e0 <default_pmm_manager+0x4f0>
ffffffffc020615e:	8aafa0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0206162 <schedule>:

void
schedule(void) {
ffffffffc0206162:	1141                	addi	sp,sp,-16
ffffffffc0206164:	e406                	sd	ra,8(sp)
ffffffffc0206166:	e022                	sd	s0,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0206168:	100027f3          	csrr	a5,sstatus
ffffffffc020616c:	8b89                	andi	a5,a5,2
ffffffffc020616e:	4401                	li	s0,0
ffffffffc0206170:	efbd                	bnez	a5,ffffffffc02061ee <schedule+0x8c>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag); // 保存中断状态并关闭中断
    {
        current->need_resched = 0; // 重置当前进程的need_resched标志
ffffffffc0206172:	000ac897          	auipc	a7,0xac
ffffffffc0206176:	7568b883          	ld	a7,1878(a7) # ffffffffc02b28c8 <current>
ffffffffc020617a:	0008bc23          	sd	zero,24(a7)
        last = (current == idleproc) ? &proc_list : &(current->list_link); // 如果当前进程是idleproc，则last指向proc_list，否则指向当前进程的list_link
ffffffffc020617e:	000ac517          	auipc	a0,0xac
ffffffffc0206182:	75253503          	ld	a0,1874(a0) # ffffffffc02b28d0 <idleproc>
ffffffffc0206186:	04a88e63          	beq	a7,a0,ffffffffc02061e2 <schedule+0x80>
ffffffffc020618a:	0c888693          	addi	a3,a7,200
ffffffffc020618e:	000ac617          	auipc	a2,0xac
ffffffffc0206192:	6b260613          	addi	a2,a2,1714 # ffffffffc02b2840 <proc_list>
        le = last; // 初始化le为last
ffffffffc0206196:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc0206198:	4581                	li	a1,0
        do {
            if ((le = list_next(le)) != &proc_list) { // 遍历进程列表
                next = le2proc(le, list_link); // 获取下一个进程
                if (next->state == PROC_RUNNABLE) { // 如果下一个进程是可运行状态
ffffffffc020619a:	4809                	li	a6,2
ffffffffc020619c:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list) { // 遍历进程列表
ffffffffc020619e:	00c78863          	beq	a5,a2,ffffffffc02061ae <schedule+0x4c>
                if (next->state == PROC_RUNNABLE) { // 如果下一个进程是可运行状态
ffffffffc02061a2:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link); // 获取下一个进程
ffffffffc02061a6:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE) { // 如果下一个进程是可运行状态
ffffffffc02061aa:	03070163          	beq	a4,a6,ffffffffc02061cc <schedule+0x6a>
                    break; // 退出循环
                }
            }
        } while (le != last); // 如果没有找到可运行的进程，则继续循环
ffffffffc02061ae:	fef697e3          	bne	a3,a5,ffffffffc020619c <schedule+0x3a>
        if (next == NULL || next->state != PROC_RUNNABLE) { // 如果没有找到可运行的进程
ffffffffc02061b2:	ed89                	bnez	a1,ffffffffc02061cc <schedule+0x6a>
            next = idleproc; // 将next设置为idleproc
        }
        next->runs ++; // 增加next进程的运行次数
ffffffffc02061b4:	451c                	lw	a5,8(a0)
ffffffffc02061b6:	2785                	addiw	a5,a5,1
ffffffffc02061b8:	c51c                	sw	a5,8(a0)
        if (next != current) { // 如果下一个进程不是当前进程
ffffffffc02061ba:	00a88463          	beq	a7,a0,ffffffffc02061c2 <schedule+0x60>
            proc_run(next); // 切换到下一个进程
ffffffffc02061be:	f9ffe0ef          	jal	ra,ffffffffc020515c <proc_run>
    if (flag) {
ffffffffc02061c2:	e819                	bnez	s0,ffffffffc02061d8 <schedule+0x76>
        }
    }
    local_intr_restore(intr_flag); // 恢复中断状态
}
ffffffffc02061c4:	60a2                	ld	ra,8(sp)
ffffffffc02061c6:	6402                	ld	s0,0(sp)
ffffffffc02061c8:	0141                	addi	sp,sp,16
ffffffffc02061ca:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE) { // 如果没有找到可运行的进程
ffffffffc02061cc:	4198                	lw	a4,0(a1)
ffffffffc02061ce:	4789                	li	a5,2
ffffffffc02061d0:	fef712e3          	bne	a4,a5,ffffffffc02061b4 <schedule+0x52>
ffffffffc02061d4:	852e                	mv	a0,a1
ffffffffc02061d6:	bff9                	j	ffffffffc02061b4 <schedule+0x52>
}
ffffffffc02061d8:	6402                	ld	s0,0(sp)
ffffffffc02061da:	60a2                	ld	ra,8(sp)
ffffffffc02061dc:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc02061de:	c64fa06f          	j	ffffffffc0200642 <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link); // 如果当前进程是idleproc，则last指向proc_list，否则指向当前进程的list_link
ffffffffc02061e2:	000ac617          	auipc	a2,0xac
ffffffffc02061e6:	65e60613          	addi	a2,a2,1630 # ffffffffc02b2840 <proc_list>
ffffffffc02061ea:	86b2                	mv	a3,a2
ffffffffc02061ec:	b76d                	j	ffffffffc0206196 <schedule+0x34>
        intr_disable();
ffffffffc02061ee:	c5afa0ef          	jal	ra,ffffffffc0200648 <intr_disable>
        return 1;
ffffffffc02061f2:	4405                	li	s0,1
ffffffffc02061f4:	bfbd                	j	ffffffffc0206172 <schedule+0x10>

ffffffffc02061f6 <sys_getpid>:
    return do_kill(pid);
}

static int
sys_getpid(uint64_t arg[]) {
    return current->pid;
ffffffffc02061f6:	000ac797          	auipc	a5,0xac
ffffffffc02061fa:	6d27b783          	ld	a5,1746(a5) # ffffffffc02b28c8 <current>
}
ffffffffc02061fe:	43c8                	lw	a0,4(a5)
ffffffffc0206200:	8082                	ret

ffffffffc0206202 <sys_pgdir>:

static int
sys_pgdir(uint64_t arg[]) {
    //print_pgdir();
    return 0;
}
ffffffffc0206202:	4501                	li	a0,0
ffffffffc0206204:	8082                	ret

ffffffffc0206206 <sys_putc>:
    cputchar(c);
ffffffffc0206206:	4108                	lw	a0,0(a0)
sys_putc(uint64_t arg[]) {
ffffffffc0206208:	1141                	addi	sp,sp,-16
ffffffffc020620a:	e406                	sd	ra,8(sp)
    cputchar(c);
ffffffffc020620c:	ef7f90ef          	jal	ra,ffffffffc0200102 <cputchar>
}
ffffffffc0206210:	60a2                	ld	ra,8(sp)
ffffffffc0206212:	4501                	li	a0,0
ffffffffc0206214:	0141                	addi	sp,sp,16
ffffffffc0206216:	8082                	ret

ffffffffc0206218 <sys_kill>:
    return do_kill(pid);
ffffffffc0206218:	4108                	lw	a0,0(a0)
ffffffffc020621a:	c9bff06f          	j	ffffffffc0205eb4 <do_kill>

ffffffffc020621e <sys_yield>:
    return do_yield();
ffffffffc020621e:	c49ff06f          	j	ffffffffc0205e66 <do_yield>

ffffffffc0206222 <sys_exec>:
    return do_execve(name, len, binary, size);
ffffffffc0206222:	6d14                	ld	a3,24(a0)
ffffffffc0206224:	6910                	ld	a2,16(a0)
ffffffffc0206226:	650c                	ld	a1,8(a0)
ffffffffc0206228:	6108                	ld	a0,0(a0)
ffffffffc020622a:	f2cff06f          	j	ffffffffc0205956 <do_execve>

ffffffffc020622e <sys_wait>:
    return do_wait(pid, store);
ffffffffc020622e:	650c                	ld	a1,8(a0)
ffffffffc0206230:	4108                	lw	a0,0(a0)
ffffffffc0206232:	c45ff06f          	j	ffffffffc0205e76 <do_wait>

ffffffffc0206236 <sys_fork>:
    struct trapframe *tf = current->tf;
ffffffffc0206236:	000ac797          	auipc	a5,0xac
ffffffffc020623a:	6927b783          	ld	a5,1682(a5) # ffffffffc02b28c8 <current>
ffffffffc020623e:	73d0                	ld	a2,160(a5)
    return do_fork(0, stack, tf);
ffffffffc0206240:	4501                	li	a0,0
ffffffffc0206242:	6a0c                	ld	a1,16(a2)
ffffffffc0206244:	f85fe06f          	j	ffffffffc02051c8 <do_fork>

ffffffffc0206248 <sys_exit>:
    return do_exit(error_code);
ffffffffc0206248:	4108                	lw	a0,0(a0)
ffffffffc020624a:	accff06f          	j	ffffffffc0205516 <do_exit>

ffffffffc020624e <syscall>:
};

#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void
syscall(void) {
ffffffffc020624e:	715d                	addi	sp,sp,-80
ffffffffc0206250:	fc26                	sd	s1,56(sp)
    struct trapframe *tf = current->tf;
ffffffffc0206252:	000ac497          	auipc	s1,0xac
ffffffffc0206256:	67648493          	addi	s1,s1,1654 # ffffffffc02b28c8 <current>
ffffffffc020625a:	6098                	ld	a4,0(s1)
syscall(void) {
ffffffffc020625c:	e0a2                	sd	s0,64(sp)
ffffffffc020625e:	f84a                	sd	s2,48(sp)
    struct trapframe *tf = current->tf;
ffffffffc0206260:	7340                	ld	s0,160(a4)
syscall(void) {
ffffffffc0206262:	e486                	sd	ra,72(sp)
    uint64_t arg[5];
    int num = tf->gpr.a0;
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc0206264:	47fd                	li	a5,31
    int num = tf->gpr.a0;
ffffffffc0206266:	05042903          	lw	s2,80(s0)
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc020626a:	0327ee63          	bltu	a5,s2,ffffffffc02062a6 <syscall+0x58>
        if (syscalls[num] != NULL) {
ffffffffc020626e:	00391713          	slli	a4,s2,0x3
ffffffffc0206272:	00002797          	auipc	a5,0x2
ffffffffc0206276:	7ee78793          	addi	a5,a5,2030 # ffffffffc0208a60 <syscalls>
ffffffffc020627a:	97ba                	add	a5,a5,a4
ffffffffc020627c:	639c                	ld	a5,0(a5)
ffffffffc020627e:	c785                	beqz	a5,ffffffffc02062a6 <syscall+0x58>
            arg[0] = tf->gpr.a1;
ffffffffc0206280:	6c28                	ld	a0,88(s0)
            arg[1] = tf->gpr.a2;
ffffffffc0206282:	702c                	ld	a1,96(s0)
            arg[2] = tf->gpr.a3;
ffffffffc0206284:	7430                	ld	a2,104(s0)
            arg[3] = tf->gpr.a4;
ffffffffc0206286:	7834                	ld	a3,112(s0)
            arg[4] = tf->gpr.a5;
ffffffffc0206288:	7c38                	ld	a4,120(s0)
            arg[0] = tf->gpr.a1;
ffffffffc020628a:	e42a                	sd	a0,8(sp)
            arg[1] = tf->gpr.a2;
ffffffffc020628c:	e82e                	sd	a1,16(sp)
            arg[2] = tf->gpr.a3;
ffffffffc020628e:	ec32                	sd	a2,24(sp)
            arg[3] = tf->gpr.a4;
ffffffffc0206290:	f036                	sd	a3,32(sp)
            arg[4] = tf->gpr.a5;
ffffffffc0206292:	f43a                	sd	a4,40(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc0206294:	0028                	addi	a0,sp,8
ffffffffc0206296:	9782                	jalr	a5
        }
    }
    print_trapframe(tf);
    panic("undefined syscall %d, pid = %d, name = %s.\n",
            num, current->pid, current->name);
}
ffffffffc0206298:	60a6                	ld	ra,72(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc020629a:	e828                	sd	a0,80(s0)
}
ffffffffc020629c:	6406                	ld	s0,64(sp)
ffffffffc020629e:	74e2                	ld	s1,56(sp)
ffffffffc02062a0:	7942                	ld	s2,48(sp)
ffffffffc02062a2:	6161                	addi	sp,sp,80
ffffffffc02062a4:	8082                	ret
    print_trapframe(tf);
ffffffffc02062a6:	8522                	mv	a0,s0
ffffffffc02062a8:	d8efa0ef          	jal	ra,ffffffffc0200836 <print_trapframe>
    panic("undefined syscall %d, pid = %d, name = %s.\n",
ffffffffc02062ac:	609c                	ld	a5,0(s1)
ffffffffc02062ae:	86ca                	mv	a3,s2
ffffffffc02062b0:	00002617          	auipc	a2,0x2
ffffffffc02062b4:	76860613          	addi	a2,a2,1896 # ffffffffc0208a18 <default_pmm_manager+0x528>
ffffffffc02062b8:	43d8                	lw	a4,4(a5)
ffffffffc02062ba:	06200593          	li	a1,98
ffffffffc02062be:	0b478793          	addi	a5,a5,180
ffffffffc02062c2:	00002517          	auipc	a0,0x2
ffffffffc02062c6:	78650513          	addi	a0,a0,1926 # ffffffffc0208a48 <default_pmm_manager+0x558>
ffffffffc02062ca:	f3ff90ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc02062ce <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc02062ce:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc02062d2:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc02062d4:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc02062d6:	cb81                	beqz	a5,ffffffffc02062e6 <strlen+0x18>
        cnt ++;
ffffffffc02062d8:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc02062da:	00a707b3          	add	a5,a4,a0
ffffffffc02062de:	0007c783          	lbu	a5,0(a5)
ffffffffc02062e2:	fbfd                	bnez	a5,ffffffffc02062d8 <strlen+0xa>
ffffffffc02062e4:	8082                	ret
    }
    return cnt;
}
ffffffffc02062e6:	8082                	ret

ffffffffc02062e8 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc02062e8:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc02062ea:	e589                	bnez	a1,ffffffffc02062f4 <strnlen+0xc>
ffffffffc02062ec:	a811                	j	ffffffffc0206300 <strnlen+0x18>
        cnt ++;
ffffffffc02062ee:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc02062f0:	00f58863          	beq	a1,a5,ffffffffc0206300 <strnlen+0x18>
ffffffffc02062f4:	00f50733          	add	a4,a0,a5
ffffffffc02062f8:	00074703          	lbu	a4,0(a4)
ffffffffc02062fc:	fb6d                	bnez	a4,ffffffffc02062ee <strnlen+0x6>
ffffffffc02062fe:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0206300:	852e                	mv	a0,a1
ffffffffc0206302:	8082                	ret

ffffffffc0206304 <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc0206304:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc0206306:	0005c703          	lbu	a4,0(a1)
ffffffffc020630a:	0785                	addi	a5,a5,1
ffffffffc020630c:	0585                	addi	a1,a1,1
ffffffffc020630e:	fee78fa3          	sb	a4,-1(a5)
ffffffffc0206312:	fb75                	bnez	a4,ffffffffc0206306 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc0206314:	8082                	ret

ffffffffc0206316 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0206316:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020631a:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020631e:	cb89                	beqz	a5,ffffffffc0206330 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0206320:	0505                	addi	a0,a0,1
ffffffffc0206322:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0206324:	fee789e3          	beq	a5,a4,ffffffffc0206316 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0206328:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc020632c:	9d19                	subw	a0,a0,a4
ffffffffc020632e:	8082                	ret
ffffffffc0206330:	4501                	li	a0,0
ffffffffc0206332:	bfed                	j	ffffffffc020632c <strcmp+0x16>

ffffffffc0206334 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0206334:	00054783          	lbu	a5,0(a0)
ffffffffc0206338:	c799                	beqz	a5,ffffffffc0206346 <strchr+0x12>
        if (*s == c) {
ffffffffc020633a:	00f58763          	beq	a1,a5,ffffffffc0206348 <strchr+0x14>
    while (*s != '\0') {
ffffffffc020633e:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0206342:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0206344:	fbfd                	bnez	a5,ffffffffc020633a <strchr+0x6>
    }
    return NULL;
ffffffffc0206346:	4501                	li	a0,0
}
ffffffffc0206348:	8082                	ret

ffffffffc020634a <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc020634a:	ca01                	beqz	a2,ffffffffc020635a <memset+0x10>
ffffffffc020634c:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc020634e:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0206350:	0785                	addi	a5,a5,1
ffffffffc0206352:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0206356:	fec79de3          	bne	a5,a2,ffffffffc0206350 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc020635a:	8082                	ret

ffffffffc020635c <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc020635c:	ca19                	beqz	a2,ffffffffc0206372 <memcpy+0x16>
ffffffffc020635e:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0206360:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0206362:	0005c703          	lbu	a4,0(a1)
ffffffffc0206366:	0585                	addi	a1,a1,1
ffffffffc0206368:	0785                	addi	a5,a5,1
ffffffffc020636a:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc020636e:	fec59ae3          	bne	a1,a2,ffffffffc0206362 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc0206372:	8082                	ret

ffffffffc0206374 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0206374:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0206378:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc020637a:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020637e:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0206380:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0206384:	f022                	sd	s0,32(sp)
ffffffffc0206386:	ec26                	sd	s1,24(sp)
ffffffffc0206388:	e84a                	sd	s2,16(sp)
ffffffffc020638a:	f406                	sd	ra,40(sp)
ffffffffc020638c:	e44e                	sd	s3,8(sp)
ffffffffc020638e:	84aa                	mv	s1,a0
ffffffffc0206390:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0206392:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0206396:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0206398:	03067e63          	bgeu	a2,a6,ffffffffc02063d4 <printnum+0x60>
ffffffffc020639c:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc020639e:	00805763          	blez	s0,ffffffffc02063ac <printnum+0x38>
ffffffffc02063a2:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc02063a4:	85ca                	mv	a1,s2
ffffffffc02063a6:	854e                	mv	a0,s3
ffffffffc02063a8:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc02063aa:	fc65                	bnez	s0,ffffffffc02063a2 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02063ac:	1a02                	slli	s4,s4,0x20
ffffffffc02063ae:	00002797          	auipc	a5,0x2
ffffffffc02063b2:	7b278793          	addi	a5,a5,1970 # ffffffffc0208b60 <syscalls+0x100>
ffffffffc02063b6:	020a5a13          	srli	s4,s4,0x20
ffffffffc02063ba:	9a3e                	add	s4,s4,a5
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
ffffffffc02063bc:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02063be:	000a4503          	lbu	a0,0(s4)
}
ffffffffc02063c2:	70a2                	ld	ra,40(sp)
ffffffffc02063c4:	69a2                	ld	s3,8(sp)
ffffffffc02063c6:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02063c8:	85ca                	mv	a1,s2
ffffffffc02063ca:	87a6                	mv	a5,s1
}
ffffffffc02063cc:	6942                	ld	s2,16(sp)
ffffffffc02063ce:	64e2                	ld	s1,24(sp)
ffffffffc02063d0:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02063d2:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc02063d4:	03065633          	divu	a2,a2,a6
ffffffffc02063d8:	8722                	mv	a4,s0
ffffffffc02063da:	f9bff0ef          	jal	ra,ffffffffc0206374 <printnum>
ffffffffc02063de:	b7f9                	j	ffffffffc02063ac <printnum+0x38>

ffffffffc02063e0 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc02063e0:	7119                	addi	sp,sp,-128
ffffffffc02063e2:	f4a6                	sd	s1,104(sp)
ffffffffc02063e4:	f0ca                	sd	s2,96(sp)
ffffffffc02063e6:	ecce                	sd	s3,88(sp)
ffffffffc02063e8:	e8d2                	sd	s4,80(sp)
ffffffffc02063ea:	e4d6                	sd	s5,72(sp)
ffffffffc02063ec:	e0da                	sd	s6,64(sp)
ffffffffc02063ee:	fc5e                	sd	s7,56(sp)
ffffffffc02063f0:	f06a                	sd	s10,32(sp)
ffffffffc02063f2:	fc86                	sd	ra,120(sp)
ffffffffc02063f4:	f8a2                	sd	s0,112(sp)
ffffffffc02063f6:	f862                	sd	s8,48(sp)
ffffffffc02063f8:	f466                	sd	s9,40(sp)
ffffffffc02063fa:	ec6e                	sd	s11,24(sp)
ffffffffc02063fc:	892a                	mv	s2,a0
ffffffffc02063fe:	84ae                	mv	s1,a1
ffffffffc0206400:	8d32                	mv	s10,a2
ffffffffc0206402:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0206404:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0206408:	5b7d                	li	s6,-1
ffffffffc020640a:	00002a97          	auipc	s5,0x2
ffffffffc020640e:	782a8a93          	addi	s5,s5,1922 # ffffffffc0208b8c <syscalls+0x12c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0206412:	00003b97          	auipc	s7,0x3
ffffffffc0206416:	996b8b93          	addi	s7,s7,-1642 # ffffffffc0208da8 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020641a:	000d4503          	lbu	a0,0(s10)
ffffffffc020641e:	001d0413          	addi	s0,s10,1
ffffffffc0206422:	01350a63          	beq	a0,s3,ffffffffc0206436 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0206426:	c121                	beqz	a0,ffffffffc0206466 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0206428:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020642a:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc020642c:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020642e:	fff44503          	lbu	a0,-1(s0)
ffffffffc0206432:	ff351ae3          	bne	a0,s3,ffffffffc0206426 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0206436:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc020643a:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc020643e:	4c81                	li	s9,0
ffffffffc0206440:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0206442:	5c7d                	li	s8,-1
ffffffffc0206444:	5dfd                	li	s11,-1
ffffffffc0206446:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc020644a:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020644c:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0206450:	0ff5f593          	zext.b	a1,a1
ffffffffc0206454:	00140d13          	addi	s10,s0,1
ffffffffc0206458:	04b56263          	bltu	a0,a1,ffffffffc020649c <vprintfmt+0xbc>
ffffffffc020645c:	058a                	slli	a1,a1,0x2
ffffffffc020645e:	95d6                	add	a1,a1,s5
ffffffffc0206460:	4194                	lw	a3,0(a1)
ffffffffc0206462:	96d6                	add	a3,a3,s5
ffffffffc0206464:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0206466:	70e6                	ld	ra,120(sp)
ffffffffc0206468:	7446                	ld	s0,112(sp)
ffffffffc020646a:	74a6                	ld	s1,104(sp)
ffffffffc020646c:	7906                	ld	s2,96(sp)
ffffffffc020646e:	69e6                	ld	s3,88(sp)
ffffffffc0206470:	6a46                	ld	s4,80(sp)
ffffffffc0206472:	6aa6                	ld	s5,72(sp)
ffffffffc0206474:	6b06                	ld	s6,64(sp)
ffffffffc0206476:	7be2                	ld	s7,56(sp)
ffffffffc0206478:	7c42                	ld	s8,48(sp)
ffffffffc020647a:	7ca2                	ld	s9,40(sp)
ffffffffc020647c:	7d02                	ld	s10,32(sp)
ffffffffc020647e:	6de2                	ld	s11,24(sp)
ffffffffc0206480:	6109                	addi	sp,sp,128
ffffffffc0206482:	8082                	ret
            padc = '0';
ffffffffc0206484:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0206486:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020648a:	846a                	mv	s0,s10
ffffffffc020648c:	00140d13          	addi	s10,s0,1
ffffffffc0206490:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0206494:	0ff5f593          	zext.b	a1,a1
ffffffffc0206498:	fcb572e3          	bgeu	a0,a1,ffffffffc020645c <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc020649c:	85a6                	mv	a1,s1
ffffffffc020649e:	02500513          	li	a0,37
ffffffffc02064a2:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc02064a4:	fff44783          	lbu	a5,-1(s0)
ffffffffc02064a8:	8d22                	mv	s10,s0
ffffffffc02064aa:	f73788e3          	beq	a5,s3,ffffffffc020641a <vprintfmt+0x3a>
ffffffffc02064ae:	ffed4783          	lbu	a5,-2(s10)
ffffffffc02064b2:	1d7d                	addi	s10,s10,-1
ffffffffc02064b4:	ff379de3          	bne	a5,s3,ffffffffc02064ae <vprintfmt+0xce>
ffffffffc02064b8:	b78d                	j	ffffffffc020641a <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc02064ba:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc02064be:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02064c2:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc02064c4:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc02064c8:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc02064cc:	02d86463          	bltu	a6,a3,ffffffffc02064f4 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc02064d0:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc02064d4:	002c169b          	slliw	a3,s8,0x2
ffffffffc02064d8:	0186873b          	addw	a4,a3,s8
ffffffffc02064dc:	0017171b          	slliw	a4,a4,0x1
ffffffffc02064e0:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc02064e2:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc02064e6:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc02064e8:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc02064ec:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc02064f0:	fed870e3          	bgeu	a6,a3,ffffffffc02064d0 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc02064f4:	f40ddce3          	bgez	s11,ffffffffc020644c <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc02064f8:	8de2                	mv	s11,s8
ffffffffc02064fa:	5c7d                	li	s8,-1
ffffffffc02064fc:	bf81                	j	ffffffffc020644c <vprintfmt+0x6c>
            if (width < 0)
ffffffffc02064fe:	fffdc693          	not	a3,s11
ffffffffc0206502:	96fd                	srai	a3,a3,0x3f
ffffffffc0206504:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0206508:	00144603          	lbu	a2,1(s0)
ffffffffc020650c:	2d81                	sext.w	s11,s11
ffffffffc020650e:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0206510:	bf35                	j	ffffffffc020644c <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0206512:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0206516:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc020651a:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020651c:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc020651e:	bfd9                	j	ffffffffc02064f4 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0206520:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0206522:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0206526:	01174463          	blt	a4,a7,ffffffffc020652e <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc020652a:	1a088e63          	beqz	a7,ffffffffc02066e6 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc020652e:	000a3603          	ld	a2,0(s4)
ffffffffc0206532:	46c1                	li	a3,16
ffffffffc0206534:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0206536:	2781                	sext.w	a5,a5
ffffffffc0206538:	876e                	mv	a4,s11
ffffffffc020653a:	85a6                	mv	a1,s1
ffffffffc020653c:	854a                	mv	a0,s2
ffffffffc020653e:	e37ff0ef          	jal	ra,ffffffffc0206374 <printnum>
            break;
ffffffffc0206542:	bde1                	j	ffffffffc020641a <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0206544:	000a2503          	lw	a0,0(s4)
ffffffffc0206548:	85a6                	mv	a1,s1
ffffffffc020654a:	0a21                	addi	s4,s4,8
ffffffffc020654c:	9902                	jalr	s2
            break;
ffffffffc020654e:	b5f1                	j	ffffffffc020641a <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0206550:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0206552:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0206556:	01174463          	blt	a4,a7,ffffffffc020655e <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc020655a:	18088163          	beqz	a7,ffffffffc02066dc <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc020655e:	000a3603          	ld	a2,0(s4)
ffffffffc0206562:	46a9                	li	a3,10
ffffffffc0206564:	8a2e                	mv	s4,a1
ffffffffc0206566:	bfc1                	j	ffffffffc0206536 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0206568:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc020656c:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020656e:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0206570:	bdf1                	j	ffffffffc020644c <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0206572:	85a6                	mv	a1,s1
ffffffffc0206574:	02500513          	li	a0,37
ffffffffc0206578:	9902                	jalr	s2
            break;
ffffffffc020657a:	b545                	j	ffffffffc020641a <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020657c:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0206580:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0206582:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0206584:	b5e1                	j	ffffffffc020644c <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0206586:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0206588:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020658c:	01174463          	blt	a4,a7,ffffffffc0206594 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0206590:	14088163          	beqz	a7,ffffffffc02066d2 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0206594:	000a3603          	ld	a2,0(s4)
ffffffffc0206598:	46a1                	li	a3,8
ffffffffc020659a:	8a2e                	mv	s4,a1
ffffffffc020659c:	bf69                	j	ffffffffc0206536 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc020659e:	03000513          	li	a0,48
ffffffffc02065a2:	85a6                	mv	a1,s1
ffffffffc02065a4:	e03e                	sd	a5,0(sp)
ffffffffc02065a6:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc02065a8:	85a6                	mv	a1,s1
ffffffffc02065aa:	07800513          	li	a0,120
ffffffffc02065ae:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02065b0:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc02065b2:	6782                	ld	a5,0(sp)
ffffffffc02065b4:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02065b6:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc02065ba:	bfb5                	j	ffffffffc0206536 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02065bc:	000a3403          	ld	s0,0(s4)
ffffffffc02065c0:	008a0713          	addi	a4,s4,8
ffffffffc02065c4:	e03a                	sd	a4,0(sp)
ffffffffc02065c6:	14040263          	beqz	s0,ffffffffc020670a <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc02065ca:	0fb05763          	blez	s11,ffffffffc02066b8 <vprintfmt+0x2d8>
ffffffffc02065ce:	02d00693          	li	a3,45
ffffffffc02065d2:	0cd79163          	bne	a5,a3,ffffffffc0206694 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02065d6:	00044783          	lbu	a5,0(s0)
ffffffffc02065da:	0007851b          	sext.w	a0,a5
ffffffffc02065de:	cf85                	beqz	a5,ffffffffc0206616 <vprintfmt+0x236>
ffffffffc02065e0:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02065e4:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02065e8:	000c4563          	bltz	s8,ffffffffc02065f2 <vprintfmt+0x212>
ffffffffc02065ec:	3c7d                	addiw	s8,s8,-1
ffffffffc02065ee:	036c0263          	beq	s8,s6,ffffffffc0206612 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc02065f2:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02065f4:	0e0c8e63          	beqz	s9,ffffffffc02066f0 <vprintfmt+0x310>
ffffffffc02065f8:	3781                	addiw	a5,a5,-32
ffffffffc02065fa:	0ef47b63          	bgeu	s0,a5,ffffffffc02066f0 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc02065fe:	03f00513          	li	a0,63
ffffffffc0206602:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0206604:	000a4783          	lbu	a5,0(s4)
ffffffffc0206608:	3dfd                	addiw	s11,s11,-1
ffffffffc020660a:	0a05                	addi	s4,s4,1
ffffffffc020660c:	0007851b          	sext.w	a0,a5
ffffffffc0206610:	ffe1                	bnez	a5,ffffffffc02065e8 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0206612:	01b05963          	blez	s11,ffffffffc0206624 <vprintfmt+0x244>
ffffffffc0206616:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0206618:	85a6                	mv	a1,s1
ffffffffc020661a:	02000513          	li	a0,32
ffffffffc020661e:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0206620:	fe0d9be3          	bnez	s11,ffffffffc0206616 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0206624:	6a02                	ld	s4,0(sp)
ffffffffc0206626:	bbd5                	j	ffffffffc020641a <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0206628:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020662a:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc020662e:	01174463          	blt	a4,a7,ffffffffc0206636 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0206632:	08088d63          	beqz	a7,ffffffffc02066cc <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0206636:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc020663a:	0a044d63          	bltz	s0,ffffffffc02066f4 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc020663e:	8622                	mv	a2,s0
ffffffffc0206640:	8a66                	mv	s4,s9
ffffffffc0206642:	46a9                	li	a3,10
ffffffffc0206644:	bdcd                	j	ffffffffc0206536 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0206646:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020664a:	4761                	li	a4,24
            err = va_arg(ap, int);
ffffffffc020664c:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc020664e:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0206652:	8fb5                	xor	a5,a5,a3
ffffffffc0206654:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0206658:	02d74163          	blt	a4,a3,ffffffffc020667a <vprintfmt+0x29a>
ffffffffc020665c:	00369793          	slli	a5,a3,0x3
ffffffffc0206660:	97de                	add	a5,a5,s7
ffffffffc0206662:	639c                	ld	a5,0(a5)
ffffffffc0206664:	cb99                	beqz	a5,ffffffffc020667a <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0206666:	86be                	mv	a3,a5
ffffffffc0206668:	00000617          	auipc	a2,0x0
ffffffffc020666c:	13860613          	addi	a2,a2,312 # ffffffffc02067a0 <etext+0x28>
ffffffffc0206670:	85a6                	mv	a1,s1
ffffffffc0206672:	854a                	mv	a0,s2
ffffffffc0206674:	0ce000ef          	jal	ra,ffffffffc0206742 <printfmt>
ffffffffc0206678:	b34d                	j	ffffffffc020641a <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc020667a:	00002617          	auipc	a2,0x2
ffffffffc020667e:	50660613          	addi	a2,a2,1286 # ffffffffc0208b80 <syscalls+0x120>
ffffffffc0206682:	85a6                	mv	a1,s1
ffffffffc0206684:	854a                	mv	a0,s2
ffffffffc0206686:	0bc000ef          	jal	ra,ffffffffc0206742 <printfmt>
ffffffffc020668a:	bb41                	j	ffffffffc020641a <vprintfmt+0x3a>
                p = "(null)";
ffffffffc020668c:	00002417          	auipc	s0,0x2
ffffffffc0206690:	4ec40413          	addi	s0,s0,1260 # ffffffffc0208b78 <syscalls+0x118>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0206694:	85e2                	mv	a1,s8
ffffffffc0206696:	8522                	mv	a0,s0
ffffffffc0206698:	e43e                	sd	a5,8(sp)
ffffffffc020669a:	c4fff0ef          	jal	ra,ffffffffc02062e8 <strnlen>
ffffffffc020669e:	40ad8dbb          	subw	s11,s11,a0
ffffffffc02066a2:	01b05b63          	blez	s11,ffffffffc02066b8 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc02066a6:	67a2                	ld	a5,8(sp)
ffffffffc02066a8:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02066ac:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc02066ae:	85a6                	mv	a1,s1
ffffffffc02066b0:	8552                	mv	a0,s4
ffffffffc02066b2:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02066b4:	fe0d9ce3          	bnez	s11,ffffffffc02066ac <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02066b8:	00044783          	lbu	a5,0(s0)
ffffffffc02066bc:	00140a13          	addi	s4,s0,1
ffffffffc02066c0:	0007851b          	sext.w	a0,a5
ffffffffc02066c4:	d3a5                	beqz	a5,ffffffffc0206624 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02066c6:	05e00413          	li	s0,94
ffffffffc02066ca:	bf39                	j	ffffffffc02065e8 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc02066cc:	000a2403          	lw	s0,0(s4)
ffffffffc02066d0:	b7ad                	j	ffffffffc020663a <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc02066d2:	000a6603          	lwu	a2,0(s4)
ffffffffc02066d6:	46a1                	li	a3,8
ffffffffc02066d8:	8a2e                	mv	s4,a1
ffffffffc02066da:	bdb1                	j	ffffffffc0206536 <vprintfmt+0x156>
ffffffffc02066dc:	000a6603          	lwu	a2,0(s4)
ffffffffc02066e0:	46a9                	li	a3,10
ffffffffc02066e2:	8a2e                	mv	s4,a1
ffffffffc02066e4:	bd89                	j	ffffffffc0206536 <vprintfmt+0x156>
ffffffffc02066e6:	000a6603          	lwu	a2,0(s4)
ffffffffc02066ea:	46c1                	li	a3,16
ffffffffc02066ec:	8a2e                	mv	s4,a1
ffffffffc02066ee:	b5a1                	j	ffffffffc0206536 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc02066f0:	9902                	jalr	s2
ffffffffc02066f2:	bf09                	j	ffffffffc0206604 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc02066f4:	85a6                	mv	a1,s1
ffffffffc02066f6:	02d00513          	li	a0,45
ffffffffc02066fa:	e03e                	sd	a5,0(sp)
ffffffffc02066fc:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc02066fe:	6782                	ld	a5,0(sp)
ffffffffc0206700:	8a66                	mv	s4,s9
ffffffffc0206702:	40800633          	neg	a2,s0
ffffffffc0206706:	46a9                	li	a3,10
ffffffffc0206708:	b53d                	j	ffffffffc0206536 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc020670a:	03b05163          	blez	s11,ffffffffc020672c <vprintfmt+0x34c>
ffffffffc020670e:	02d00693          	li	a3,45
ffffffffc0206712:	f6d79de3          	bne	a5,a3,ffffffffc020668c <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0206716:	00002417          	auipc	s0,0x2
ffffffffc020671a:	46240413          	addi	s0,s0,1122 # ffffffffc0208b78 <syscalls+0x118>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020671e:	02800793          	li	a5,40
ffffffffc0206722:	02800513          	li	a0,40
ffffffffc0206726:	00140a13          	addi	s4,s0,1
ffffffffc020672a:	bd6d                	j	ffffffffc02065e4 <vprintfmt+0x204>
ffffffffc020672c:	00002a17          	auipc	s4,0x2
ffffffffc0206730:	44da0a13          	addi	s4,s4,1101 # ffffffffc0208b79 <syscalls+0x119>
ffffffffc0206734:	02800513          	li	a0,40
ffffffffc0206738:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020673c:	05e00413          	li	s0,94
ffffffffc0206740:	b565                	j	ffffffffc02065e8 <vprintfmt+0x208>

ffffffffc0206742 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0206742:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0206744:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0206748:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc020674a:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020674c:	ec06                	sd	ra,24(sp)
ffffffffc020674e:	f83a                	sd	a4,48(sp)
ffffffffc0206750:	fc3e                	sd	a5,56(sp)
ffffffffc0206752:	e0c2                	sd	a6,64(sp)
ffffffffc0206754:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0206756:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0206758:	c89ff0ef          	jal	ra,ffffffffc02063e0 <vprintfmt>
}
ffffffffc020675c:	60e2                	ld	ra,24(sp)
ffffffffc020675e:	6161                	addi	sp,sp,80
ffffffffc0206760:	8082                	ret

ffffffffc0206762 <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc0206762:	9e3707b7          	lui	a5,0x9e370
ffffffffc0206766:	2785                	addiw	a5,a5,1
ffffffffc0206768:	02a7853b          	mulw	a0,a5,a0
    return (hash >> (32 - bits));
ffffffffc020676c:	02000793          	li	a5,32
ffffffffc0206770:	9f8d                	subw	a5,a5,a1
}
ffffffffc0206772:	00f5553b          	srlw	a0,a0,a5
ffffffffc0206776:	8082                	ret
