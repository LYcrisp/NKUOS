
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:

    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200000:	c020a2b7          	lui	t0,0xc020a
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
ffffffffc0200024:	c020a137          	lui	sp,0xc020a

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200028:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc020002c:	03228293          	addi	t0,t0,50 # ffffffffc0200032 <kern_init>
    jr t0
ffffffffc0200030:	8282                	jr	t0

ffffffffc0200032 <kern_init>:
void grade_backtrace(void); // 声明grade_backtrace函数

int
kern_init(void) { // 内核初始化函数
    extern char edata[], end[]; // 声明外部变量edata和end，表示数据段的起始和结束地址
    memset(edata, 0, end - edata); // 将数据段清零
ffffffffc0200032:	0000b517          	auipc	a0,0xb
ffffffffc0200036:	02e50513          	addi	a0,a0,46 # ffffffffc020b060 <buf>
ffffffffc020003a:	00016617          	auipc	a2,0x16
ffffffffc020003e:	59260613          	addi	a2,a2,1426 # ffffffffc02165cc <end>
kern_init(void) { // 内核初始化函数
ffffffffc0200042:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata); // 将数据段清零
ffffffffc0200044:	8e09                	sub	a2,a2,a0
ffffffffc0200046:	4581                	li	a1,0
kern_init(void) { // 内核初始化函数
ffffffffc0200048:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata); // 将数据段清零
ffffffffc020004a:	287040ef          	jal	ra,ffffffffc0204ad0 <memset>

    cons_init(); // 初始化控制台
ffffffffc020004e:	4fc000ef          	jal	ra,ffffffffc020054a <cons_init>

    const char *message = "(THU.CST) os is loading ..."; // 定义加载信息字符串
    cprintf("%s\n\n", message); // 打印加载信息
ffffffffc0200052:	00005597          	auipc	a1,0x5
ffffffffc0200056:	ed658593          	addi	a1,a1,-298 # ffffffffc0204f28 <etext+0x6>
ffffffffc020005a:	00005517          	auipc	a0,0x5
ffffffffc020005e:	eee50513          	addi	a0,a0,-274 # ffffffffc0204f48 <etext+0x26>
ffffffffc0200062:	06a000ef          	jal	ra,ffffffffc02000cc <cprintf>

    print_kerninfo(); // 打印内核信息
ffffffffc0200066:	1be000ef          	jal	ra,ffffffffc0200224 <print_kerninfo>

    // grade_backtrace(); // 调用grade_backtrace函数（已注释）

    pmm_init(); // 初始化物理内存管理
ffffffffc020006a:	004010ef          	jal	ra,ffffffffc020106e <pmm_init>

    pic_init(); // 初始化可编程中断控制器
ffffffffc020006e:	54e000ef          	jal	ra,ffffffffc02005bc <pic_init>
    idt_init(); // 初始化中断描述符表
ffffffffc0200072:	5c8000ef          	jal	ra,ffffffffc020063a <idt_init>

    vmm_init(); // 初始化虚拟内存管理
ffffffffc0200076:	629010ef          	jal	ra,ffffffffc0201e9e <vmm_init>
    proc_init(); // 初始化进程表
ffffffffc020007a:	6aa040ef          	jal	ra,ffffffffc0204724 <proc_init>
    
    ide_init(); // 初始化IDE设备
ffffffffc020007e:	424000ef          	jal	ra,ffffffffc02004a2 <ide_init>
    swap_init(); // 初始化交换
ffffffffc0200082:	4ec020ef          	jal	ra,ffffffffc020256e <swap_init>

    clock_init(); // 初始化时钟中断
ffffffffc0200086:	472000ef          	jal	ra,ffffffffc02004f8 <clock_init>
    intr_enable(); // 启用IRQ中断
ffffffffc020008a:	534000ef          	jal	ra,ffffffffc02005be <intr_enable>

    cpu_idle(); // 运行空闲进程
ffffffffc020008e:	0e5040ef          	jal	ra,ffffffffc0204972 <cpu_idle>

ffffffffc0200092 <cputch>:
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * cputch - 将单个字符 @c 写入标准输出，并增加 @cnt 指向的计数器的值。
 * */
static void
cputch(int c, int *cnt) { // 将字符c写入控制台，并增加计数器cnt
ffffffffc0200092:	1141                	addi	sp,sp,-16
ffffffffc0200094:	e022                	sd	s0,0(sp)
ffffffffc0200096:	e406                	sd	ra,8(sp)
ffffffffc0200098:	842e                	mv	s0,a1
    cons_putc(c); // 调用控制台输出函数
ffffffffc020009a:	4b2000ef          	jal	ra,ffffffffc020054c <cons_putc>
    (*cnt) ++; // 计数器加1
ffffffffc020009e:	401c                	lw	a5,0(s0)
}
ffffffffc02000a0:	60a2                	ld	ra,8(sp)
    (*cnt) ++; // 计数器加1
ffffffffc02000a2:	2785                	addiw	a5,a5,1
ffffffffc02000a4:	c01c                	sw	a5,0(s0)
}
ffffffffc02000a6:	6402                	ld	s0,0(sp)
ffffffffc02000a8:	0141                	addi	sp,sp,16
ffffffffc02000aa:	8082                	ret

ffffffffc02000ac <vcprintf>:
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * 如果你已经在处理va_list，请调用此函数。否则你可能需要cprintf()。
 * */
int
vcprintf(const char *fmt, va_list ap) { // 格式化字符串并写入标准输出
ffffffffc02000ac:	1101                	addi	sp,sp,-32
ffffffffc02000ae:	862a                	mv	a2,a0
ffffffffc02000b0:	86ae                	mv	a3,a1
    int cnt = 0; // 初始化计数器
    vprintfmt((void*)cputch, &cnt, fmt, ap); // 调用vprintfmt函数进行格式化输出
ffffffffc02000b2:	00000517          	auipc	a0,0x0
ffffffffc02000b6:	fe050513          	addi	a0,a0,-32 # ffffffffc0200092 <cputch>
ffffffffc02000ba:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) { // 格式化字符串并写入标准输出
ffffffffc02000bc:	ec06                	sd	ra,24(sp)
    int cnt = 0; // 初始化计数器
ffffffffc02000be:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap); // 调用vprintfmt函数进行格式化输出
ffffffffc02000c0:	2cb040ef          	jal	ra,ffffffffc0204b8a <vprintfmt>
    return cnt; // 返回计数器值
}
ffffffffc02000c4:	60e2                	ld	ra,24(sp)
ffffffffc02000c6:	4532                	lw	a0,12(sp)
ffffffffc02000c8:	6105                	addi	sp,sp,32
ffffffffc02000ca:	8082                	ret

ffffffffc02000cc <cprintf>:
 * The return value is the number of characters which would be
 * written to stdout.
 * 返回值是将写入标准输出的字符数。
 * */
int
cprintf(const char *fmt, ...) { // 格式化字符串并写入标准输出
ffffffffc02000cc:	711d                	addi	sp,sp,-96
    va_list ap; // 定义va_list变量
    int cnt; // 定义计数器变量
    va_start(ap, fmt); // 初始化va_list变量
ffffffffc02000ce:	02810313          	addi	t1,sp,40 # ffffffffc020a028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) { // 格式化字符串并写入标准输出
ffffffffc02000d2:	8e2a                	mv	t3,a0
ffffffffc02000d4:	f42e                	sd	a1,40(sp)
ffffffffc02000d6:	f832                	sd	a2,48(sp)
ffffffffc02000d8:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap); // 调用vprintfmt函数进行格式化输出
ffffffffc02000da:	00000517          	auipc	a0,0x0
ffffffffc02000de:	fb850513          	addi	a0,a0,-72 # ffffffffc0200092 <cputch>
ffffffffc02000e2:	004c                	addi	a1,sp,4
ffffffffc02000e4:	869a                	mv	a3,t1
ffffffffc02000e6:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) { // 格式化字符串并写入标准输出
ffffffffc02000e8:	ec06                	sd	ra,24(sp)
ffffffffc02000ea:	e0ba                	sd	a4,64(sp)
ffffffffc02000ec:	e4be                	sd	a5,72(sp)
ffffffffc02000ee:	e8c2                	sd	a6,80(sp)
ffffffffc02000f0:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt); // 初始化va_list变量
ffffffffc02000f2:	e41a                	sd	t1,8(sp)
    int cnt = 0; // 初始化计数器
ffffffffc02000f4:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap); // 调用vprintfmt函数进行格式化输出
ffffffffc02000f6:	295040ef          	jal	ra,ffffffffc0204b8a <vprintfmt>
    cnt = vcprintf(fmt, ap); // 调用vcprintf函数进行格式化输出
    va_end(ap); // 结束va_list变量的使用
    return cnt; // 返回计数器值
}
ffffffffc02000fa:	60e2                	ld	ra,24(sp)
ffffffffc02000fc:	4512                	lw	a0,4(sp)
ffffffffc02000fe:	6125                	addi	sp,sp,96
ffffffffc0200100:	8082                	ret

ffffffffc0200102 <cputchar>:

/* cputchar - writes a single character to stdout // cputchar - 将单个字符写入标准输出 */
void
cputchar(int c) { // 将字符c写入控制台
    cons_putc(c); // 调用控制台输出函数
ffffffffc0200102:	a1a9                	j	ffffffffc020054c <cons_putc>

ffffffffc0200104 <getchar>:
    return cnt; // 返回计数器值
}

/* getchar - reads a single non-zero character from stdin // getchar - 从标准输入读取单个非零字符 */
int
getchar(void) { // 从标准输入读取单个字符
ffffffffc0200104:	1141                	addi	sp,sp,-16
ffffffffc0200106:	e406                	sd	ra,8(sp)
    int c; // 定义字符变量
    while ((c = cons_getc()) == 0) // 循环读取字符，直到读取到非零字符
ffffffffc0200108:	478000ef          	jal	ra,ffffffffc0200580 <cons_getc>
ffffffffc020010c:	dd75                	beqz	a0,ffffffffc0200108 <getchar+0x4>
        /* do nothing */; // 什么也不做
    return c; // 返回读取到的字符
}
ffffffffc020010e:	60a2                	ld	ra,8(sp)
ffffffffc0200110:	0141                	addi	sp,sp,16
ffffffffc0200112:	8082                	ret

ffffffffc0200114 <readline>:
 *
 * readline()函数返回读取的行的文本。如果发生一些错误，则返回NULL。
 * 返回值是一个全局变量，因此在使用之前应复制它。
 * */
char *
readline(const char *prompt) {
ffffffffc0200114:	715d                	addi	sp,sp,-80
ffffffffc0200116:	e486                	sd	ra,72(sp)
ffffffffc0200118:	e0a6                	sd	s1,64(sp)
ffffffffc020011a:	fc4a                	sd	s2,56(sp)
ffffffffc020011c:	f84e                	sd	s3,48(sp)
ffffffffc020011e:	f452                	sd	s4,40(sp)
ffffffffc0200120:	f056                	sd	s5,32(sp)
ffffffffc0200122:	ec5a                	sd	s6,24(sp)
ffffffffc0200124:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) { // 如果提示字符串不为空
ffffffffc0200126:	c901                	beqz	a0,ffffffffc0200136 <readline+0x22>
ffffffffc0200128:	85aa                	mv	a1,a0
        cprintf("%s", prompt); // 将提示字符串写入标准输出
ffffffffc020012a:	00005517          	auipc	a0,0x5
ffffffffc020012e:	e2650513          	addi	a0,a0,-474 # ffffffffc0204f50 <etext+0x2e>
ffffffffc0200132:	f9bff0ef          	jal	ra,ffffffffc02000cc <cprintf>
readline(const char *prompt) {
ffffffffc0200136:	4481                	li	s1,0
    while (1) { // 无限循环
        c = getchar(); // 从标准输入读取一个字符
        if (c < 0) { // 如果读取错误
            return NULL; // 返回NULL
        }
        else if (c >= ' ' && i < BUFSIZE - 1) { // 如果读取的字符是可打印字符且缓冲区未满
ffffffffc0200138:	497d                	li	s2,31
            cputchar(c); // 将字符写入标准输出
            buf[i ++] = c; // 将字符保存到缓冲区，并递增索引
        }
        else if (c == '\b' && i > 0) { // 如果读取的字符是退格符且缓冲区不为空
ffffffffc020013a:	49a1                	li	s3,8
            cputchar(c); // 将退格符写入标准输出
            i --; // 递减索引
        }
        else if (c == '\n' || c == '\r') { // 如果读取的字符是换行符或回车符
ffffffffc020013c:	4aa9                	li	s5,10
ffffffffc020013e:	4b35                	li	s6,13
            buf[i ++] = c; // 将字符保存到缓冲区，并递增索引
ffffffffc0200140:	0000bb97          	auipc	s7,0xb
ffffffffc0200144:	f20b8b93          	addi	s7,s7,-224 # ffffffffc020b060 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) { // 如果读取的字符是可打印字符且缓冲区未满
ffffffffc0200148:	3fe00a13          	li	s4,1022
        c = getchar(); // 从标准输入读取一个字符
ffffffffc020014c:	fb9ff0ef          	jal	ra,ffffffffc0200104 <getchar>
        if (c < 0) { // 如果读取错误
ffffffffc0200150:	00054a63          	bltz	a0,ffffffffc0200164 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) { // 如果读取的字符是可打印字符且缓冲区未满
ffffffffc0200154:	00a95a63          	bge	s2,a0,ffffffffc0200168 <readline+0x54>
ffffffffc0200158:	029a5263          	bge	s4,s1,ffffffffc020017c <readline+0x68>
        c = getchar(); // 从标准输入读取一个字符
ffffffffc020015c:	fa9ff0ef          	jal	ra,ffffffffc0200104 <getchar>
        if (c < 0) { // 如果读取错误
ffffffffc0200160:	fe055ae3          	bgez	a0,ffffffffc0200154 <readline+0x40>
            return NULL; // 返回NULL
ffffffffc0200164:	4501                	li	a0,0
ffffffffc0200166:	a091                	j	ffffffffc02001aa <readline+0x96>
        else if (c == '\b' && i > 0) { // 如果读取的字符是退格符且缓冲区不为空
ffffffffc0200168:	03351463          	bne	a0,s3,ffffffffc0200190 <readline+0x7c>
ffffffffc020016c:	e8a9                	bnez	s1,ffffffffc02001be <readline+0xaa>
        c = getchar(); // 从标准输入读取一个字符
ffffffffc020016e:	f97ff0ef          	jal	ra,ffffffffc0200104 <getchar>
        if (c < 0) { // 如果读取错误
ffffffffc0200172:	fe0549e3          	bltz	a0,ffffffffc0200164 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) { // 如果读取的字符是可打印字符且缓冲区未满
ffffffffc0200176:	fea959e3          	bge	s2,a0,ffffffffc0200168 <readline+0x54>
ffffffffc020017a:	4481                	li	s1,0
            cputchar(c); // 将字符写入标准输出
ffffffffc020017c:	e42a                	sd	a0,8(sp)
ffffffffc020017e:	f85ff0ef          	jal	ra,ffffffffc0200102 <cputchar>
            buf[i ++] = c; // 将字符保存到缓冲区，并递增索引
ffffffffc0200182:	6522                	ld	a0,8(sp)
ffffffffc0200184:	009b87b3          	add	a5,s7,s1
ffffffffc0200188:	2485                	addiw	s1,s1,1
ffffffffc020018a:	00a78023          	sb	a0,0(a5)
ffffffffc020018e:	bf7d                	j	ffffffffc020014c <readline+0x38>
        else if (c == '\n' || c == '\r') { // 如果读取的字符是换行符或回车符
ffffffffc0200190:	01550463          	beq	a0,s5,ffffffffc0200198 <readline+0x84>
ffffffffc0200194:	fb651ce3          	bne	a0,s6,ffffffffc020014c <readline+0x38>
            cputchar(c); // 将换行符或回车符写入标准输出
ffffffffc0200198:	f6bff0ef          	jal	ra,ffffffffc0200102 <cputchar>
            buf[i] = '\0'; // 在缓冲区末尾添加字符串结束符
ffffffffc020019c:	0000b517          	auipc	a0,0xb
ffffffffc02001a0:	ec450513          	addi	a0,a0,-316 # ffffffffc020b060 <buf>
ffffffffc02001a4:	94aa                	add	s1,s1,a0
ffffffffc02001a6:	00048023          	sb	zero,0(s1)
            return buf; // 返回缓冲区
        }
    }
}
ffffffffc02001aa:	60a6                	ld	ra,72(sp)
ffffffffc02001ac:	6486                	ld	s1,64(sp)
ffffffffc02001ae:	7962                	ld	s2,56(sp)
ffffffffc02001b0:	79c2                	ld	s3,48(sp)
ffffffffc02001b2:	7a22                	ld	s4,40(sp)
ffffffffc02001b4:	7a82                	ld	s5,32(sp)
ffffffffc02001b6:	6b62                	ld	s6,24(sp)
ffffffffc02001b8:	6bc2                	ld	s7,16(sp)
ffffffffc02001ba:	6161                	addi	sp,sp,80
ffffffffc02001bc:	8082                	ret
            cputchar(c); // 将退格符写入标准输出
ffffffffc02001be:	4521                	li	a0,8
ffffffffc02001c0:	f43ff0ef          	jal	ra,ffffffffc0200102 <cputchar>
            i --; // 递减索引
ffffffffc02001c4:	34fd                	addiw	s1,s1,-1
ffffffffc02001c6:	b759                	j	ffffffffc020014c <readline+0x38>

ffffffffc02001c8 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02001c8:	00016317          	auipc	t1,0x16
ffffffffc02001cc:	37030313          	addi	t1,t1,880 # ffffffffc0216538 <is_panic>
ffffffffc02001d0:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02001d4:	715d                	addi	sp,sp,-80
ffffffffc02001d6:	ec06                	sd	ra,24(sp)
ffffffffc02001d8:	e822                	sd	s0,16(sp)
ffffffffc02001da:	f436                	sd	a3,40(sp)
ffffffffc02001dc:	f83a                	sd	a4,48(sp)
ffffffffc02001de:	fc3e                	sd	a5,56(sp)
ffffffffc02001e0:	e0c2                	sd	a6,64(sp)
ffffffffc02001e2:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02001e4:	020e1a63          	bnez	t3,ffffffffc0200218 <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02001e8:	4785                	li	a5,1
ffffffffc02001ea:	00f32023          	sw	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc02001ee:	8432                	mv	s0,a2
ffffffffc02001f0:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001f2:	862e                	mv	a2,a1
ffffffffc02001f4:	85aa                	mv	a1,a0
ffffffffc02001f6:	00005517          	auipc	a0,0x5
ffffffffc02001fa:	d6250513          	addi	a0,a0,-670 # ffffffffc0204f58 <etext+0x36>
    va_start(ap, fmt);
ffffffffc02001fe:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200200:	ecdff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200204:	65a2                	ld	a1,8(sp)
ffffffffc0200206:	8522                	mv	a0,s0
ffffffffc0200208:	ea5ff0ef          	jal	ra,ffffffffc02000ac <vcprintf>
    cprintf("\n");
ffffffffc020020c:	00006517          	auipc	a0,0x6
ffffffffc0200210:	aec50513          	addi	a0,a0,-1300 # ffffffffc0205cf8 <commands+0xb48>
ffffffffc0200214:	eb9ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc0200218:	3ac000ef          	jal	ra,ffffffffc02005c4 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc020021c:	4501                	li	a0,0
ffffffffc020021e:	130000ef          	jal	ra,ffffffffc020034e <kmonitor>
    while (1) {
ffffffffc0200222:	bfed                	j	ffffffffc020021c <__panic+0x54>

ffffffffc0200224 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc0200224:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc0200226:	00005517          	auipc	a0,0x5
ffffffffc020022a:	d5250513          	addi	a0,a0,-686 # ffffffffc0204f78 <etext+0x56>
void print_kerninfo(void) {
ffffffffc020022e:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200230:	e9dff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc0200234:	00000597          	auipc	a1,0x0
ffffffffc0200238:	dfe58593          	addi	a1,a1,-514 # ffffffffc0200032 <kern_init>
ffffffffc020023c:	00005517          	auipc	a0,0x5
ffffffffc0200240:	d5c50513          	addi	a0,a0,-676 # ffffffffc0204f98 <etext+0x76>
ffffffffc0200244:	e89ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc0200248:	00005597          	auipc	a1,0x5
ffffffffc020024c:	cda58593          	addi	a1,a1,-806 # ffffffffc0204f22 <etext>
ffffffffc0200250:	00005517          	auipc	a0,0x5
ffffffffc0200254:	d6850513          	addi	a0,a0,-664 # ffffffffc0204fb8 <etext+0x96>
ffffffffc0200258:	e75ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc020025c:	0000b597          	auipc	a1,0xb
ffffffffc0200260:	e0458593          	addi	a1,a1,-508 # ffffffffc020b060 <buf>
ffffffffc0200264:	00005517          	auipc	a0,0x5
ffffffffc0200268:	d7450513          	addi	a0,a0,-652 # ffffffffc0204fd8 <etext+0xb6>
ffffffffc020026c:	e61ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200270:	00016597          	auipc	a1,0x16
ffffffffc0200274:	35c58593          	addi	a1,a1,860 # ffffffffc02165cc <end>
ffffffffc0200278:	00005517          	auipc	a0,0x5
ffffffffc020027c:	d8050513          	addi	a0,a0,-640 # ffffffffc0204ff8 <etext+0xd6>
ffffffffc0200280:	e4dff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc0200284:	00016597          	auipc	a1,0x16
ffffffffc0200288:	74758593          	addi	a1,a1,1863 # ffffffffc02169cb <end+0x3ff>
ffffffffc020028c:	00000797          	auipc	a5,0x0
ffffffffc0200290:	da678793          	addi	a5,a5,-602 # ffffffffc0200032 <kern_init>
ffffffffc0200294:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200298:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc020029c:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc020029e:	3ff5f593          	andi	a1,a1,1023
ffffffffc02002a2:	95be                	add	a1,a1,a5
ffffffffc02002a4:	85a9                	srai	a1,a1,0xa
ffffffffc02002a6:	00005517          	auipc	a0,0x5
ffffffffc02002aa:	d7250513          	addi	a0,a0,-654 # ffffffffc0205018 <etext+0xf6>
}
ffffffffc02002ae:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02002b0:	bd31                	j	ffffffffc02000cc <cprintf>

ffffffffc02002b2 <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc02002b2:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc02002b4:	00005617          	auipc	a2,0x5
ffffffffc02002b8:	d9460613          	addi	a2,a2,-620 # ffffffffc0205048 <etext+0x126>
ffffffffc02002bc:	04d00593          	li	a1,77
ffffffffc02002c0:	00005517          	auipc	a0,0x5
ffffffffc02002c4:	da050513          	addi	a0,a0,-608 # ffffffffc0205060 <etext+0x13e>
void print_stackframe(void) {
ffffffffc02002c8:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02002ca:	effff0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc02002ce <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002ce:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002d0:	00005617          	auipc	a2,0x5
ffffffffc02002d4:	da860613          	addi	a2,a2,-600 # ffffffffc0205078 <etext+0x156>
ffffffffc02002d8:	00005597          	auipc	a1,0x5
ffffffffc02002dc:	dc058593          	addi	a1,a1,-576 # ffffffffc0205098 <etext+0x176>
ffffffffc02002e0:	00005517          	auipc	a0,0x5
ffffffffc02002e4:	dc050513          	addi	a0,a0,-576 # ffffffffc02050a0 <etext+0x17e>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002e8:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002ea:	de3ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
ffffffffc02002ee:	00005617          	auipc	a2,0x5
ffffffffc02002f2:	dc260613          	addi	a2,a2,-574 # ffffffffc02050b0 <etext+0x18e>
ffffffffc02002f6:	00005597          	auipc	a1,0x5
ffffffffc02002fa:	de258593          	addi	a1,a1,-542 # ffffffffc02050d8 <etext+0x1b6>
ffffffffc02002fe:	00005517          	auipc	a0,0x5
ffffffffc0200302:	da250513          	addi	a0,a0,-606 # ffffffffc02050a0 <etext+0x17e>
ffffffffc0200306:	dc7ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
ffffffffc020030a:	00005617          	auipc	a2,0x5
ffffffffc020030e:	dde60613          	addi	a2,a2,-546 # ffffffffc02050e8 <etext+0x1c6>
ffffffffc0200312:	00005597          	auipc	a1,0x5
ffffffffc0200316:	df658593          	addi	a1,a1,-522 # ffffffffc0205108 <etext+0x1e6>
ffffffffc020031a:	00005517          	auipc	a0,0x5
ffffffffc020031e:	d8650513          	addi	a0,a0,-634 # ffffffffc02050a0 <etext+0x17e>
ffffffffc0200322:	dabff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    }
    return 0;
}
ffffffffc0200326:	60a2                	ld	ra,8(sp)
ffffffffc0200328:	4501                	li	a0,0
ffffffffc020032a:	0141                	addi	sp,sp,16
ffffffffc020032c:	8082                	ret

ffffffffc020032e <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc020032e:	1141                	addi	sp,sp,-16
ffffffffc0200330:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc0200332:	ef3ff0ef          	jal	ra,ffffffffc0200224 <print_kerninfo>
    return 0;
}
ffffffffc0200336:	60a2                	ld	ra,8(sp)
ffffffffc0200338:	4501                	li	a0,0
ffffffffc020033a:	0141                	addi	sp,sp,16
ffffffffc020033c:	8082                	ret

ffffffffc020033e <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc020033e:	1141                	addi	sp,sp,-16
ffffffffc0200340:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc0200342:	f71ff0ef          	jal	ra,ffffffffc02002b2 <print_stackframe>
    return 0;
}
ffffffffc0200346:	60a2                	ld	ra,8(sp)
ffffffffc0200348:	4501                	li	a0,0
ffffffffc020034a:	0141                	addi	sp,sp,16
ffffffffc020034c:	8082                	ret

ffffffffc020034e <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc020034e:	7115                	addi	sp,sp,-224
ffffffffc0200350:	ed5e                	sd	s7,152(sp)
ffffffffc0200352:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200354:	00005517          	auipc	a0,0x5
ffffffffc0200358:	dc450513          	addi	a0,a0,-572 # ffffffffc0205118 <etext+0x1f6>
kmonitor(struct trapframe *tf) {
ffffffffc020035c:	ed86                	sd	ra,216(sp)
ffffffffc020035e:	e9a2                	sd	s0,208(sp)
ffffffffc0200360:	e5a6                	sd	s1,200(sp)
ffffffffc0200362:	e1ca                	sd	s2,192(sp)
ffffffffc0200364:	fd4e                	sd	s3,184(sp)
ffffffffc0200366:	f952                	sd	s4,176(sp)
ffffffffc0200368:	f556                	sd	s5,168(sp)
ffffffffc020036a:	f15a                	sd	s6,160(sp)
ffffffffc020036c:	e962                	sd	s8,144(sp)
ffffffffc020036e:	e566                	sd	s9,136(sp)
ffffffffc0200370:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200372:	d5bff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc0200376:	00005517          	auipc	a0,0x5
ffffffffc020037a:	dca50513          	addi	a0,a0,-566 # ffffffffc0205140 <etext+0x21e>
ffffffffc020037e:	d4fff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    if (tf != NULL) {
ffffffffc0200382:	000b8563          	beqz	s7,ffffffffc020038c <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc0200386:	855e                	mv	a0,s7
ffffffffc0200388:	49a000ef          	jal	ra,ffffffffc0200822 <print_trapframe>
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc020038c:	4501                	li	a0,0
ffffffffc020038e:	4581                	li	a1,0
ffffffffc0200390:	4601                	li	a2,0
ffffffffc0200392:	48a1                	li	a7,8
ffffffffc0200394:	00000073          	ecall
ffffffffc0200398:	00005c17          	auipc	s8,0x5
ffffffffc020039c:	e18c0c13          	addi	s8,s8,-488 # ffffffffc02051b0 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02003a0:	00005917          	auipc	s2,0x5
ffffffffc02003a4:	dc890913          	addi	s2,s2,-568 # ffffffffc0205168 <etext+0x246>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003a8:	00005497          	auipc	s1,0x5
ffffffffc02003ac:	dc848493          	addi	s1,s1,-568 # ffffffffc0205170 <etext+0x24e>
        if (argc == MAXARGS - 1) {
ffffffffc02003b0:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02003b2:	00005b17          	auipc	s6,0x5
ffffffffc02003b6:	dc6b0b13          	addi	s6,s6,-570 # ffffffffc0205178 <etext+0x256>
        argv[argc ++] = buf;
ffffffffc02003ba:	00005a17          	auipc	s4,0x5
ffffffffc02003be:	cdea0a13          	addi	s4,s4,-802 # ffffffffc0205098 <etext+0x176>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003c2:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02003c4:	854a                	mv	a0,s2
ffffffffc02003c6:	d4fff0ef          	jal	ra,ffffffffc0200114 <readline>
ffffffffc02003ca:	842a                	mv	s0,a0
ffffffffc02003cc:	dd65                	beqz	a0,ffffffffc02003c4 <kmonitor+0x76>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003ce:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02003d2:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003d4:	e1bd                	bnez	a1,ffffffffc020043a <kmonitor+0xec>
    if (argc == 0) {
ffffffffc02003d6:	fe0c87e3          	beqz	s9,ffffffffc02003c4 <kmonitor+0x76>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003da:	6582                	ld	a1,0(sp)
ffffffffc02003dc:	00005d17          	auipc	s10,0x5
ffffffffc02003e0:	dd4d0d13          	addi	s10,s10,-556 # ffffffffc02051b0 <commands>
        argv[argc ++] = buf;
ffffffffc02003e4:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003e6:	4401                	li	s0,0
ffffffffc02003e8:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003ea:	6b2040ef          	jal	ra,ffffffffc0204a9c <strcmp>
ffffffffc02003ee:	c919                	beqz	a0,ffffffffc0200404 <kmonitor+0xb6>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003f0:	2405                	addiw	s0,s0,1
ffffffffc02003f2:	0b540063          	beq	s0,s5,ffffffffc0200492 <kmonitor+0x144>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003f6:	000d3503          	ld	a0,0(s10)
ffffffffc02003fa:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003fc:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003fe:	69e040ef          	jal	ra,ffffffffc0204a9c <strcmp>
ffffffffc0200402:	f57d                	bnez	a0,ffffffffc02003f0 <kmonitor+0xa2>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc0200404:	00141793          	slli	a5,s0,0x1
ffffffffc0200408:	97a2                	add	a5,a5,s0
ffffffffc020040a:	078e                	slli	a5,a5,0x3
ffffffffc020040c:	97e2                	add	a5,a5,s8
ffffffffc020040e:	6b9c                	ld	a5,16(a5)
ffffffffc0200410:	865e                	mv	a2,s7
ffffffffc0200412:	002c                	addi	a1,sp,8
ffffffffc0200414:	fffc851b          	addiw	a0,s9,-1
ffffffffc0200418:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc020041a:	fa0555e3          	bgez	a0,ffffffffc02003c4 <kmonitor+0x76>
}
ffffffffc020041e:	60ee                	ld	ra,216(sp)
ffffffffc0200420:	644e                	ld	s0,208(sp)
ffffffffc0200422:	64ae                	ld	s1,200(sp)
ffffffffc0200424:	690e                	ld	s2,192(sp)
ffffffffc0200426:	79ea                	ld	s3,184(sp)
ffffffffc0200428:	7a4a                	ld	s4,176(sp)
ffffffffc020042a:	7aaa                	ld	s5,168(sp)
ffffffffc020042c:	7b0a                	ld	s6,160(sp)
ffffffffc020042e:	6bea                	ld	s7,152(sp)
ffffffffc0200430:	6c4a                	ld	s8,144(sp)
ffffffffc0200432:	6caa                	ld	s9,136(sp)
ffffffffc0200434:	6d0a                	ld	s10,128(sp)
ffffffffc0200436:	612d                	addi	sp,sp,224
ffffffffc0200438:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020043a:	8526                	mv	a0,s1
ffffffffc020043c:	67e040ef          	jal	ra,ffffffffc0204aba <strchr>
ffffffffc0200440:	c901                	beqz	a0,ffffffffc0200450 <kmonitor+0x102>
ffffffffc0200442:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc0200446:	00040023          	sb	zero,0(s0)
ffffffffc020044a:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020044c:	d5c9                	beqz	a1,ffffffffc02003d6 <kmonitor+0x88>
ffffffffc020044e:	b7f5                	j	ffffffffc020043a <kmonitor+0xec>
        if (*buf == '\0') {
ffffffffc0200450:	00044783          	lbu	a5,0(s0)
ffffffffc0200454:	d3c9                	beqz	a5,ffffffffc02003d6 <kmonitor+0x88>
        if (argc == MAXARGS - 1) {
ffffffffc0200456:	033c8963          	beq	s9,s3,ffffffffc0200488 <kmonitor+0x13a>
        argv[argc ++] = buf;
ffffffffc020045a:	003c9793          	slli	a5,s9,0x3
ffffffffc020045e:	0118                	addi	a4,sp,128
ffffffffc0200460:	97ba                	add	a5,a5,a4
ffffffffc0200462:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200466:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc020046a:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020046c:	e591                	bnez	a1,ffffffffc0200478 <kmonitor+0x12a>
ffffffffc020046e:	b7b5                	j	ffffffffc02003da <kmonitor+0x8c>
ffffffffc0200470:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc0200474:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200476:	d1a5                	beqz	a1,ffffffffc02003d6 <kmonitor+0x88>
ffffffffc0200478:	8526                	mv	a0,s1
ffffffffc020047a:	640040ef          	jal	ra,ffffffffc0204aba <strchr>
ffffffffc020047e:	d96d                	beqz	a0,ffffffffc0200470 <kmonitor+0x122>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200480:	00044583          	lbu	a1,0(s0)
ffffffffc0200484:	d9a9                	beqz	a1,ffffffffc02003d6 <kmonitor+0x88>
ffffffffc0200486:	bf55                	j	ffffffffc020043a <kmonitor+0xec>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200488:	45c1                	li	a1,16
ffffffffc020048a:	855a                	mv	a0,s6
ffffffffc020048c:	c41ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
ffffffffc0200490:	b7e9                	j	ffffffffc020045a <kmonitor+0x10c>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc0200492:	6582                	ld	a1,0(sp)
ffffffffc0200494:	00005517          	auipc	a0,0x5
ffffffffc0200498:	d0450513          	addi	a0,a0,-764 # ffffffffc0205198 <etext+0x276>
ffffffffc020049c:	c31ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    return 0;
ffffffffc02004a0:	b715                	j	ffffffffc02003c4 <kmonitor+0x76>

ffffffffc02004a2 <ide_init>:
#include <stdio.h>
#include <string.h>
#include <trap.h>
#include <riscv.h>

void ide_init(void) {}
ffffffffc02004a2:	8082                	ret

ffffffffc02004a4 <ide_device_valid>:

#define MAX_IDE 2
#define MAX_DISK_NSECS 56
static char ide[MAX_DISK_NSECS * SECTSIZE];

bool ide_device_valid(unsigned short ideno) { return ideno < MAX_IDE; }
ffffffffc02004a4:	00253513          	sltiu	a0,a0,2
ffffffffc02004a8:	8082                	ret

ffffffffc02004aa <ide_device_size>:

size_t ide_device_size(unsigned short ideno) { return MAX_DISK_NSECS; }
ffffffffc02004aa:	03800513          	li	a0,56
ffffffffc02004ae:	8082                	ret

ffffffffc02004b0 <ide_read_secs>:

int ide_read_secs(unsigned short ideno, uint32_t secno, void *dst,
                  size_t nsecs) {
    int iobase = secno * SECTSIZE;
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc02004b0:	0000b797          	auipc	a5,0xb
ffffffffc02004b4:	fb078793          	addi	a5,a5,-80 # ffffffffc020b460 <ide>
    int iobase = secno * SECTSIZE;
ffffffffc02004b8:	0095959b          	slliw	a1,a1,0x9
                  size_t nsecs) {
ffffffffc02004bc:	1141                	addi	sp,sp,-16
ffffffffc02004be:	8532                	mv	a0,a2
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc02004c0:	95be                	add	a1,a1,a5
ffffffffc02004c2:	00969613          	slli	a2,a3,0x9
                  size_t nsecs) {
ffffffffc02004c6:	e406                	sd	ra,8(sp)
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc02004c8:	61a040ef          	jal	ra,ffffffffc0204ae2 <memcpy>
    return 0;
}
ffffffffc02004cc:	60a2                	ld	ra,8(sp)
ffffffffc02004ce:	4501                	li	a0,0
ffffffffc02004d0:	0141                	addi	sp,sp,16
ffffffffc02004d2:	8082                	ret

ffffffffc02004d4 <ide_write_secs>:

int ide_write_secs(unsigned short ideno, uint32_t secno, const void *src,
                   size_t nsecs) {
    int iobase = secno * SECTSIZE;
ffffffffc02004d4:	0095979b          	slliw	a5,a1,0x9
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc02004d8:	0000b517          	auipc	a0,0xb
ffffffffc02004dc:	f8850513          	addi	a0,a0,-120 # ffffffffc020b460 <ide>
                   size_t nsecs) {
ffffffffc02004e0:	1141                	addi	sp,sp,-16
ffffffffc02004e2:	85b2                	mv	a1,a2
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc02004e4:	953e                	add	a0,a0,a5
ffffffffc02004e6:	00969613          	slli	a2,a3,0x9
                   size_t nsecs) {
ffffffffc02004ea:	e406                	sd	ra,8(sp)
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc02004ec:	5f6040ef          	jal	ra,ffffffffc0204ae2 <memcpy>
    return 0;
}
ffffffffc02004f0:	60a2                	ld	ra,8(sp)
ffffffffc02004f2:	4501                	li	a0,0
ffffffffc02004f4:	0141                	addi	sp,sp,16
ffffffffc02004f6:	8082                	ret

ffffffffc02004f8 <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc02004f8:	67e1                	lui	a5,0x18
ffffffffc02004fa:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc02004fe:	00016717          	auipc	a4,0x16
ffffffffc0200502:	04f73523          	sd	a5,74(a4) # ffffffffc0216548 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200506:	c0102573          	rdtime	a0
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc020050a:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020050c:	953e                	add	a0,a0,a5
ffffffffc020050e:	4601                	li	a2,0
ffffffffc0200510:	4881                	li	a7,0
ffffffffc0200512:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc0200516:	02000793          	li	a5,32
ffffffffc020051a:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc020051e:	00005517          	auipc	a0,0x5
ffffffffc0200522:	cda50513          	addi	a0,a0,-806 # ffffffffc02051f8 <commands+0x48>
    ticks = 0;
ffffffffc0200526:	00016797          	auipc	a5,0x16
ffffffffc020052a:	0007bd23          	sd	zero,26(a5) # ffffffffc0216540 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020052e:	be79                	j	ffffffffc02000cc <cprintf>

ffffffffc0200530 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200530:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200534:	00016797          	auipc	a5,0x16
ffffffffc0200538:	0147b783          	ld	a5,20(a5) # ffffffffc0216548 <timebase>
ffffffffc020053c:	953e                	add	a0,a0,a5
ffffffffc020053e:	4581                	li	a1,0
ffffffffc0200540:	4601                	li	a2,0
ffffffffc0200542:	4881                	li	a7,0
ffffffffc0200544:	00000073          	ecall
ffffffffc0200548:	8082                	ret

ffffffffc020054a <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc020054a:	8082                	ret

ffffffffc020054c <cons_putc>:
#include <intr.h> // 包含中断处理相关的函数和宏定义
#include <riscv.h> // 包含RISC-V架构相关的函数和宏定义

// __intr_save - 保存当前中断状态并禁用中断
static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) { // 如果当前中断使能
ffffffffc020054c:	100027f3          	csrr	a5,sstatus
ffffffffc0200550:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc0200552:	0ff57513          	zext.b	a0,a0
ffffffffc0200556:	e799                	bnez	a5,ffffffffc0200564 <cons_putc+0x18>
ffffffffc0200558:	4581                	li	a1,0
ffffffffc020055a:	4601                	li	a2,0
ffffffffc020055c:	4885                	li	a7,1
ffffffffc020055e:	00000073          	ecall
    return 0; // 返回0表示中断之前是禁用的
}

// __intr_restore - 恢复之前保存的中断状态
static inline void __intr_restore(bool flag) {
    if (flag) { // 如果flag为1
ffffffffc0200562:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc0200564:	1101                	addi	sp,sp,-32
ffffffffc0200566:	ec06                	sd	ra,24(sp)
ffffffffc0200568:	e42a                	sd	a0,8(sp)
        intr_disable(); // 禁用中断
ffffffffc020056a:	05a000ef          	jal	ra,ffffffffc02005c4 <intr_disable>
ffffffffc020056e:	6522                	ld	a0,8(sp)
ffffffffc0200570:	4581                	li	a1,0
ffffffffc0200572:	4601                	li	a2,0
ffffffffc0200574:	4885                	li	a7,1
ffffffffc0200576:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc020057a:	60e2                	ld	ra,24(sp)
ffffffffc020057c:	6105                	addi	sp,sp,32
        intr_enable(); // 使能中断
ffffffffc020057e:	a081                	j	ffffffffc02005be <intr_enable>

ffffffffc0200580 <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE) { // 如果当前中断使能
ffffffffc0200580:	100027f3          	csrr	a5,sstatus
ffffffffc0200584:	8b89                	andi	a5,a5,2
ffffffffc0200586:	eb89                	bnez	a5,ffffffffc0200598 <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc0200588:	4501                	li	a0,0
ffffffffc020058a:	4581                	li	a1,0
ffffffffc020058c:	4601                	li	a2,0
ffffffffc020058e:	4889                	li	a7,2
ffffffffc0200590:	00000073          	ecall
ffffffffc0200594:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc0200596:	8082                	ret
int cons_getc(void) {
ffffffffc0200598:	1101                	addi	sp,sp,-32
ffffffffc020059a:	ec06                	sd	ra,24(sp)
        intr_disable(); // 禁用中断
ffffffffc020059c:	028000ef          	jal	ra,ffffffffc02005c4 <intr_disable>
ffffffffc02005a0:	4501                	li	a0,0
ffffffffc02005a2:	4581                	li	a1,0
ffffffffc02005a4:	4601                	li	a2,0
ffffffffc02005a6:	4889                	li	a7,2
ffffffffc02005a8:	00000073          	ecall
ffffffffc02005ac:	2501                	sext.w	a0,a0
ffffffffc02005ae:	e42a                	sd	a0,8(sp)
        intr_enable(); // 使能中断
ffffffffc02005b0:	00e000ef          	jal	ra,ffffffffc02005be <intr_enable>
}
ffffffffc02005b4:	60e2                	ld	ra,24(sp)
ffffffffc02005b6:	6522                	ld	a0,8(sp)
ffffffffc02005b8:	6105                	addi	sp,sp,32
ffffffffc02005ba:	8082                	ret

ffffffffc02005bc <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc02005bc:	8082                	ret

ffffffffc02005be <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc02005be:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc02005c2:	8082                	ret

ffffffffc02005c4 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc02005c4:	100177f3          	csrrci	a5,sstatus,2
ffffffffc02005c8:	8082                	ret

ffffffffc02005ca <pgfault_handler>:

/* trap_in_kernel - test if trap happened in kernel
 * 测试陷阱是否发生在内核中
 */
bool trap_in_kernel(struct trapframe *tf) {
    return (tf->status & SSTATUS_SPP) != 0; // 检查状态寄存器中的SPP位
ffffffffc02005ca:	10053783          	ld	a5,256(a0)
    cprintf("page falut at 0x%08x: %c/%c\n", tf->badvaddr, // 打印页错误地址
            trap_in_kernel(tf) ? 'K' : 'U', // 判断错误发生在内核还是用户模式
            tf->cause == CAUSE_STORE_PAGE_FAULT ? 'W' : 'R'); // 判断是写错误还是读错误
}

static int pgfault_handler(struct trapframe *tf) { // 页错误处理函数
ffffffffc02005ce:	1141                	addi	sp,sp,-16
ffffffffc02005d0:	e022                	sd	s0,0(sp)
ffffffffc02005d2:	e406                	sd	ra,8(sp)
    return (tf->status & SSTATUS_SPP) != 0; // 检查状态寄存器中的SPP位
ffffffffc02005d4:	1007f793          	andi	a5,a5,256
    cprintf("page falut at 0x%08x: %c/%c\n", tf->badvaddr, // 打印页错误地址
ffffffffc02005d8:	11053583          	ld	a1,272(a0)
static int pgfault_handler(struct trapframe *tf) { // 页错误处理函数
ffffffffc02005dc:	842a                	mv	s0,a0
    cprintf("page falut at 0x%08x: %c/%c\n", tf->badvaddr, // 打印页错误地址
ffffffffc02005de:	05500613          	li	a2,85
ffffffffc02005e2:	c399                	beqz	a5,ffffffffc02005e8 <pgfault_handler+0x1e>
ffffffffc02005e4:	04b00613          	li	a2,75
ffffffffc02005e8:	11843703          	ld	a4,280(s0)
ffffffffc02005ec:	47bd                	li	a5,15
ffffffffc02005ee:	05700693          	li	a3,87
ffffffffc02005f2:	00f70463          	beq	a4,a5,ffffffffc02005fa <pgfault_handler+0x30>
ffffffffc02005f6:	05200693          	li	a3,82
ffffffffc02005fa:	00005517          	auipc	a0,0x5
ffffffffc02005fe:	c1e50513          	addi	a0,a0,-994 # ffffffffc0205218 <commands+0x68>
ffffffffc0200602:	acbff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    extern struct mm_struct *check_mm_struct; // 声明外部变量check_mm_struct
    print_pgfault(tf); // 打印页错误信息
    if (check_mm_struct != NULL) { // 如果check_mm_struct不为空
ffffffffc0200606:	00016517          	auipc	a0,0x16
ffffffffc020060a:	f7a53503          	ld	a0,-134(a0) # ffffffffc0216580 <check_mm_struct>
ffffffffc020060e:	c911                	beqz	a0,ffffffffc0200622 <pgfault_handler+0x58>
        return do_pgfault(check_mm_struct, tf->cause, tf->badvaddr); // 处理页错误
ffffffffc0200610:	11043603          	ld	a2,272(s0)
ffffffffc0200614:	11842583          	lw	a1,280(s0)
    }
    panic("unhandled page fault.\n"); // 触发内核恐慌，表示未处理的页错误
}
ffffffffc0200618:	6402                	ld	s0,0(sp)
ffffffffc020061a:	60a2                	ld	ra,8(sp)
ffffffffc020061c:	0141                	addi	sp,sp,16
        return do_pgfault(check_mm_struct, tf->cause, tf->badvaddr); // 处理页错误
ffffffffc020061e:	6550106f          	j	ffffffffc0202472 <do_pgfault>
    panic("unhandled page fault.\n"); // 触发内核恐慌，表示未处理的页错误
ffffffffc0200622:	00005617          	auipc	a2,0x5
ffffffffc0200626:	c1660613          	addi	a2,a2,-1002 # ffffffffc0205238 <commands+0x88>
ffffffffc020062a:	06d00593          	li	a1,109
ffffffffc020062e:	00005517          	auipc	a0,0x5
ffffffffc0200632:	c2250513          	addi	a0,a0,-990 # ffffffffc0205250 <commands+0xa0>
ffffffffc0200636:	b93ff0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc020063a <idt_init>:
    write_csr(sscratch, 0); // 写入sscratch寄存器
ffffffffc020063a:	14005073          	csrwi	sscratch,0
    write_csr(stvec, &__alltraps); // 写入stvec寄存器
ffffffffc020063e:	00000797          	auipc	a5,0x0
ffffffffc0200642:	47a78793          	addi	a5,a5,1146 # ffffffffc0200ab8 <__alltraps>
ffffffffc0200646:	10579073          	csrw	stvec,a5
    set_csr(sstatus, SSTATUS_SUM); // 设置sstatus寄存器
ffffffffc020064a:	000407b7          	lui	a5,0x40
ffffffffc020064e:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc0200652:	8082                	ret

ffffffffc0200654 <print_regs>:
    cprintf("  zero     0x%08x\n", gpr->zero); // 打印zero寄存器
ffffffffc0200654:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) { // 打印通用寄存器
ffffffffc0200656:	1141                	addi	sp,sp,-16
ffffffffc0200658:	e022                	sd	s0,0(sp)
ffffffffc020065a:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero); // 打印zero寄存器
ffffffffc020065c:	00005517          	auipc	a0,0x5
ffffffffc0200660:	c0c50513          	addi	a0,a0,-1012 # ffffffffc0205268 <commands+0xb8>
void print_regs(struct pushregs *gpr) { // 打印通用寄存器
ffffffffc0200664:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero); // 打印zero寄存器
ffffffffc0200666:	a67ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra); // 打印返回地址寄存器
ffffffffc020066a:	640c                	ld	a1,8(s0)
ffffffffc020066c:	00005517          	auipc	a0,0x5
ffffffffc0200670:	c1450513          	addi	a0,a0,-1004 # ffffffffc0205280 <commands+0xd0>
ffffffffc0200674:	a59ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp); // 打印栈指针寄存器
ffffffffc0200678:	680c                	ld	a1,16(s0)
ffffffffc020067a:	00005517          	auipc	a0,0x5
ffffffffc020067e:	c1e50513          	addi	a0,a0,-994 # ffffffffc0205298 <commands+0xe8>
ffffffffc0200682:	a4bff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp); // 打印全局指针寄存器
ffffffffc0200686:	6c0c                	ld	a1,24(s0)
ffffffffc0200688:	00005517          	auipc	a0,0x5
ffffffffc020068c:	c2850513          	addi	a0,a0,-984 # ffffffffc02052b0 <commands+0x100>
ffffffffc0200690:	a3dff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp); // 打印线程指针寄存器
ffffffffc0200694:	700c                	ld	a1,32(s0)
ffffffffc0200696:	00005517          	auipc	a0,0x5
ffffffffc020069a:	c3250513          	addi	a0,a0,-974 # ffffffffc02052c8 <commands+0x118>
ffffffffc020069e:	a2fff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0); // 打印临时寄存器t0
ffffffffc02006a2:	740c                	ld	a1,40(s0)
ffffffffc02006a4:	00005517          	auipc	a0,0x5
ffffffffc02006a8:	c3c50513          	addi	a0,a0,-964 # ffffffffc02052e0 <commands+0x130>
ffffffffc02006ac:	a21ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1); // 打印临时寄存器t1
ffffffffc02006b0:	780c                	ld	a1,48(s0)
ffffffffc02006b2:	00005517          	auipc	a0,0x5
ffffffffc02006b6:	c4650513          	addi	a0,a0,-954 # ffffffffc02052f8 <commands+0x148>
ffffffffc02006ba:	a13ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2); // 打印临时寄存器t2
ffffffffc02006be:	7c0c                	ld	a1,56(s0)
ffffffffc02006c0:	00005517          	auipc	a0,0x5
ffffffffc02006c4:	c5050513          	addi	a0,a0,-944 # ffffffffc0205310 <commands+0x160>
ffffffffc02006c8:	a05ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0); // 打印保存寄存器s0
ffffffffc02006cc:	602c                	ld	a1,64(s0)
ffffffffc02006ce:	00005517          	auipc	a0,0x5
ffffffffc02006d2:	c5a50513          	addi	a0,a0,-934 # ffffffffc0205328 <commands+0x178>
ffffffffc02006d6:	9f7ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1); // 打印保存寄存器s1
ffffffffc02006da:	642c                	ld	a1,72(s0)
ffffffffc02006dc:	00005517          	auipc	a0,0x5
ffffffffc02006e0:	c6450513          	addi	a0,a0,-924 # ffffffffc0205340 <commands+0x190>
ffffffffc02006e4:	9e9ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0); // 打印函数参数寄存器a0
ffffffffc02006e8:	682c                	ld	a1,80(s0)
ffffffffc02006ea:	00005517          	auipc	a0,0x5
ffffffffc02006ee:	c6e50513          	addi	a0,a0,-914 # ffffffffc0205358 <commands+0x1a8>
ffffffffc02006f2:	9dbff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1); // 打印函数参数寄存器a1
ffffffffc02006f6:	6c2c                	ld	a1,88(s0)
ffffffffc02006f8:	00005517          	auipc	a0,0x5
ffffffffc02006fc:	c7850513          	addi	a0,a0,-904 # ffffffffc0205370 <commands+0x1c0>
ffffffffc0200700:	9cdff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2); // 打印函数参数寄存器a2
ffffffffc0200704:	702c                	ld	a1,96(s0)
ffffffffc0200706:	00005517          	auipc	a0,0x5
ffffffffc020070a:	c8250513          	addi	a0,a0,-894 # ffffffffc0205388 <commands+0x1d8>
ffffffffc020070e:	9bfff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3); // 打印函数参数寄存器a3
ffffffffc0200712:	742c                	ld	a1,104(s0)
ffffffffc0200714:	00005517          	auipc	a0,0x5
ffffffffc0200718:	c8c50513          	addi	a0,a0,-884 # ffffffffc02053a0 <commands+0x1f0>
ffffffffc020071c:	9b1ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4); // 打印函数参数寄存器a4
ffffffffc0200720:	782c                	ld	a1,112(s0)
ffffffffc0200722:	00005517          	auipc	a0,0x5
ffffffffc0200726:	c9650513          	addi	a0,a0,-874 # ffffffffc02053b8 <commands+0x208>
ffffffffc020072a:	9a3ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5); // 打印函数参数寄存器a5
ffffffffc020072e:	7c2c                	ld	a1,120(s0)
ffffffffc0200730:	00005517          	auipc	a0,0x5
ffffffffc0200734:	ca050513          	addi	a0,a0,-864 # ffffffffc02053d0 <commands+0x220>
ffffffffc0200738:	995ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6); // 打印函数参数寄存器a6
ffffffffc020073c:	604c                	ld	a1,128(s0)
ffffffffc020073e:	00005517          	auipc	a0,0x5
ffffffffc0200742:	caa50513          	addi	a0,a0,-854 # ffffffffc02053e8 <commands+0x238>
ffffffffc0200746:	987ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7); // 打印函数参数寄存器a7
ffffffffc020074a:	644c                	ld	a1,136(s0)
ffffffffc020074c:	00005517          	auipc	a0,0x5
ffffffffc0200750:	cb450513          	addi	a0,a0,-844 # ffffffffc0205400 <commands+0x250>
ffffffffc0200754:	979ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2); // 打印保存寄存器s2
ffffffffc0200758:	684c                	ld	a1,144(s0)
ffffffffc020075a:	00005517          	auipc	a0,0x5
ffffffffc020075e:	cbe50513          	addi	a0,a0,-834 # ffffffffc0205418 <commands+0x268>
ffffffffc0200762:	96bff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3); // 打印保存寄存器s3
ffffffffc0200766:	6c4c                	ld	a1,152(s0)
ffffffffc0200768:	00005517          	auipc	a0,0x5
ffffffffc020076c:	cc850513          	addi	a0,a0,-824 # ffffffffc0205430 <commands+0x280>
ffffffffc0200770:	95dff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4); // 打印保存寄存器s4
ffffffffc0200774:	704c                	ld	a1,160(s0)
ffffffffc0200776:	00005517          	auipc	a0,0x5
ffffffffc020077a:	cd250513          	addi	a0,a0,-814 # ffffffffc0205448 <commands+0x298>
ffffffffc020077e:	94fff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5); // 打印保存寄存器s5
ffffffffc0200782:	744c                	ld	a1,168(s0)
ffffffffc0200784:	00005517          	auipc	a0,0x5
ffffffffc0200788:	cdc50513          	addi	a0,a0,-804 # ffffffffc0205460 <commands+0x2b0>
ffffffffc020078c:	941ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6); // 打印保存寄存器s6
ffffffffc0200790:	784c                	ld	a1,176(s0)
ffffffffc0200792:	00005517          	auipc	a0,0x5
ffffffffc0200796:	ce650513          	addi	a0,a0,-794 # ffffffffc0205478 <commands+0x2c8>
ffffffffc020079a:	933ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7); // 打印保存寄存器s7
ffffffffc020079e:	7c4c                	ld	a1,184(s0)
ffffffffc02007a0:	00005517          	auipc	a0,0x5
ffffffffc02007a4:	cf050513          	addi	a0,a0,-784 # ffffffffc0205490 <commands+0x2e0>
ffffffffc02007a8:	925ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8); // 打印保存寄存器s8
ffffffffc02007ac:	606c                	ld	a1,192(s0)
ffffffffc02007ae:	00005517          	auipc	a0,0x5
ffffffffc02007b2:	cfa50513          	addi	a0,a0,-774 # ffffffffc02054a8 <commands+0x2f8>
ffffffffc02007b6:	917ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9); // 打印保存寄存器s9
ffffffffc02007ba:	646c                	ld	a1,200(s0)
ffffffffc02007bc:	00005517          	auipc	a0,0x5
ffffffffc02007c0:	d0450513          	addi	a0,a0,-764 # ffffffffc02054c0 <commands+0x310>
ffffffffc02007c4:	909ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10); // 打印保存寄存器s10
ffffffffc02007c8:	686c                	ld	a1,208(s0)
ffffffffc02007ca:	00005517          	auipc	a0,0x5
ffffffffc02007ce:	d0e50513          	addi	a0,a0,-754 # ffffffffc02054d8 <commands+0x328>
ffffffffc02007d2:	8fbff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11); // 打印保存寄存器s11
ffffffffc02007d6:	6c6c                	ld	a1,216(s0)
ffffffffc02007d8:	00005517          	auipc	a0,0x5
ffffffffc02007dc:	d1850513          	addi	a0,a0,-744 # ffffffffc02054f0 <commands+0x340>
ffffffffc02007e0:	8edff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3); // 打印临时寄存器t3
ffffffffc02007e4:	706c                	ld	a1,224(s0)
ffffffffc02007e6:	00005517          	auipc	a0,0x5
ffffffffc02007ea:	d2250513          	addi	a0,a0,-734 # ffffffffc0205508 <commands+0x358>
ffffffffc02007ee:	8dfff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4); // 打印临时寄存器t4
ffffffffc02007f2:	746c                	ld	a1,232(s0)
ffffffffc02007f4:	00005517          	auipc	a0,0x5
ffffffffc02007f8:	d2c50513          	addi	a0,a0,-724 # ffffffffc0205520 <commands+0x370>
ffffffffc02007fc:	8d1ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5); // 打印临时寄存器t5
ffffffffc0200800:	786c                	ld	a1,240(s0)
ffffffffc0200802:	00005517          	auipc	a0,0x5
ffffffffc0200806:	d3650513          	addi	a0,a0,-714 # ffffffffc0205538 <commands+0x388>
ffffffffc020080a:	8c3ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6); // 打印临时寄存器t6
ffffffffc020080e:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200810:	6402                	ld	s0,0(sp)
ffffffffc0200812:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6); // 打印临时寄存器t6
ffffffffc0200814:	00005517          	auipc	a0,0x5
ffffffffc0200818:	d3c50513          	addi	a0,a0,-708 # ffffffffc0205550 <commands+0x3a0>
}
ffffffffc020081c:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6); // 打印临时寄存器t6
ffffffffc020081e:	8afff06f          	j	ffffffffc02000cc <cprintf>

ffffffffc0200822 <print_trapframe>:
void print_trapframe(struct trapframe *tf) { // 打印陷阱帧
ffffffffc0200822:	1141                	addi	sp,sp,-16
ffffffffc0200824:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf); // 打印陷阱帧地址
ffffffffc0200826:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) { // 打印陷阱帧
ffffffffc0200828:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf); // 打印陷阱帧地址
ffffffffc020082a:	00005517          	auipc	a0,0x5
ffffffffc020082e:	d3e50513          	addi	a0,a0,-706 # ffffffffc0205568 <commands+0x3b8>
void print_trapframe(struct trapframe *tf) { // 打印陷阱帧
ffffffffc0200832:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf); // 打印陷阱帧地址
ffffffffc0200834:	899ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    print_regs(&tf->gpr); // 打印通用寄存器
ffffffffc0200838:	8522                	mv	a0,s0
ffffffffc020083a:	e1bff0ef          	jal	ra,ffffffffc0200654 <print_regs>
    cprintf("  status   0x%08x\n", tf->status); // 打印状态寄存器
ffffffffc020083e:	10043583          	ld	a1,256(s0)
ffffffffc0200842:	00005517          	auipc	a0,0x5
ffffffffc0200846:	d3e50513          	addi	a0,a0,-706 # ffffffffc0205580 <commands+0x3d0>
ffffffffc020084a:	883ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc); // 打印异常程序计数器
ffffffffc020084e:	10843583          	ld	a1,264(s0)
ffffffffc0200852:	00005517          	auipc	a0,0x5
ffffffffc0200856:	d4650513          	addi	a0,a0,-698 # ffffffffc0205598 <commands+0x3e8>
ffffffffc020085a:	873ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr); // 打印错误地址
ffffffffc020085e:	11043583          	ld	a1,272(s0)
ffffffffc0200862:	00005517          	auipc	a0,0x5
ffffffffc0200866:	d4e50513          	addi	a0,a0,-690 # ffffffffc02055b0 <commands+0x400>
ffffffffc020086a:	863ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause); // 打印异常原因
ffffffffc020086e:	11843583          	ld	a1,280(s0)
}
ffffffffc0200872:	6402                	ld	s0,0(sp)
ffffffffc0200874:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause); // 打印异常原因
ffffffffc0200876:	00005517          	auipc	a0,0x5
ffffffffc020087a:	d5250513          	addi	a0,a0,-686 # ffffffffc02055c8 <commands+0x418>
}
ffffffffc020087e:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause); // 打印异常原因
ffffffffc0200880:	84dff06f          	j	ffffffffc02000cc <cprintf>

ffffffffc0200884 <interrupt_handler>:

static volatile int in_swap_tick_event = 0; // 定义一个静态易失性变量，表示是否在交换滴答事件中
extern struct mm_struct *check_mm_struct; // 声明外部变量check_mm_struct

void interrupt_handler(struct trapframe *tf) { // 中断处理函数
    intptr_t cause = (tf->cause << 1) >> 1; // 获取中断原因
ffffffffc0200884:	11853783          	ld	a5,280(a0)
ffffffffc0200888:	472d                	li	a4,11
ffffffffc020088a:	0786                	slli	a5,a5,0x1
ffffffffc020088c:	8385                	srli	a5,a5,0x1
ffffffffc020088e:	06f76c63          	bltu	a4,a5,ffffffffc0200906 <interrupt_handler+0x82>
ffffffffc0200892:	00005717          	auipc	a4,0x5
ffffffffc0200896:	dfe70713          	addi	a4,a4,-514 # ffffffffc0205690 <commands+0x4e0>
ffffffffc020089a:	078a                	slli	a5,a5,0x2
ffffffffc020089c:	97ba                	add	a5,a5,a4
ffffffffc020089e:	439c                	lw	a5,0(a5)
ffffffffc02008a0:	97ba                	add	a5,a5,a4
ffffffffc02008a2:	8782                	jr	a5
            break;
        case IRQ_H_SOFT: // 管理者软件中断
            cprintf("Hypervisor software interrupt\n"); // 打印管理者软件中断信息
            break;
        case IRQ_M_SOFT: // 机器软件中断
            cprintf("Machine software interrupt\n"); // 打印机器软件中断信息
ffffffffc02008a4:	00005517          	auipc	a0,0x5
ffffffffc02008a8:	d9c50513          	addi	a0,a0,-612 # ffffffffc0205640 <commands+0x490>
ffffffffc02008ac:	821ff06f          	j	ffffffffc02000cc <cprintf>
            cprintf("Hypervisor software interrupt\n"); // 打印管理者软件中断信息
ffffffffc02008b0:	00005517          	auipc	a0,0x5
ffffffffc02008b4:	d7050513          	addi	a0,a0,-656 # ffffffffc0205620 <commands+0x470>
ffffffffc02008b8:	815ff06f          	j	ffffffffc02000cc <cprintf>
            cprintf("User software interrupt\n"); // 打印用户软件中断信息
ffffffffc02008bc:	00005517          	auipc	a0,0x5
ffffffffc02008c0:	d2450513          	addi	a0,a0,-732 # ffffffffc02055e0 <commands+0x430>
ffffffffc02008c4:	809ff06f          	j	ffffffffc02000cc <cprintf>
            cprintf("Supervisor software interrupt\n"); // 打印监督者软件中断信息
ffffffffc02008c8:	00005517          	auipc	a0,0x5
ffffffffc02008cc:	d3850513          	addi	a0,a0,-712 # ffffffffc0205600 <commands+0x450>
ffffffffc02008d0:	ffcff06f          	j	ffffffffc02000cc <cprintf>
void interrupt_handler(struct trapframe *tf) { // 中断处理函数
ffffffffc02008d4:	1141                	addi	sp,sp,-16
ffffffffc02008d6:	e406                	sd	ra,8(sp)
            // "All bits besides SSIP and USIP in the sip register are
            // read-only." -- privileged spec1.9.1, 4.1.4, p59
            // In fact, Call sbi_set_timer will clear STIP, or you can clear it
            // directly.
            // clear_csr(sip, SIP_STIP);
            clock_set_next_event(); // 设置下一个时钟事件
ffffffffc02008d8:	c59ff0ef          	jal	ra,ffffffffc0200530 <clock_set_next_event>
            if (++ticks % TICK_NUM == 0) { // 如果滴答数达到TICK_NUM
ffffffffc02008dc:	00016697          	auipc	a3,0x16
ffffffffc02008e0:	c6468693          	addi	a3,a3,-924 # ffffffffc0216540 <ticks>
ffffffffc02008e4:	629c                	ld	a5,0(a3)
ffffffffc02008e6:	06400713          	li	a4,100
ffffffffc02008ea:	0785                	addi	a5,a5,1
ffffffffc02008ec:	02e7f733          	remu	a4,a5,a4
ffffffffc02008f0:	e29c                	sd	a5,0(a3)
ffffffffc02008f2:	cb19                	beqz	a4,ffffffffc0200908 <interrupt_handler+0x84>
            break;
        default: // 其他中断
            print_trapframe(tf); // 打印陷阱帧
            break;
    }
}
ffffffffc02008f4:	60a2                	ld	ra,8(sp)
ffffffffc02008f6:	0141                	addi	sp,sp,16
ffffffffc02008f8:	8082                	ret
            cprintf("Supervisor external interrupt\n"); // 打印监督者外部中断信息
ffffffffc02008fa:	00005517          	auipc	a0,0x5
ffffffffc02008fe:	d7650513          	addi	a0,a0,-650 # ffffffffc0205670 <commands+0x4c0>
ffffffffc0200902:	fcaff06f          	j	ffffffffc02000cc <cprintf>
            print_trapframe(tf); // 打印陷阱帧
ffffffffc0200906:	bf31                	j	ffffffffc0200822 <print_trapframe>
}
ffffffffc0200908:	60a2                	ld	ra,8(sp)
    cprintf("%d ticks\n", TICK_NUM); // 打印滴答数
ffffffffc020090a:	06400593          	li	a1,100
ffffffffc020090e:	00005517          	auipc	a0,0x5
ffffffffc0200912:	d5250513          	addi	a0,a0,-686 # ffffffffc0205660 <commands+0x4b0>
}
ffffffffc0200916:	0141                	addi	sp,sp,16
    cprintf("%d ticks\n", TICK_NUM); // 打印滴答数
ffffffffc0200918:	fb4ff06f          	j	ffffffffc02000cc <cprintf>

ffffffffc020091c <exception_handler>:

void exception_handler(struct trapframe *tf) { // 异常处理函数
    int ret; // 定义返回值
    switch (tf->cause) { // 根据异常原因进行处理
ffffffffc020091c:	11853783          	ld	a5,280(a0)
void exception_handler(struct trapframe *tf) { // 异常处理函数
ffffffffc0200920:	1101                	addi	sp,sp,-32
ffffffffc0200922:	e822                	sd	s0,16(sp)
ffffffffc0200924:	ec06                	sd	ra,24(sp)
ffffffffc0200926:	e426                	sd	s1,8(sp)
ffffffffc0200928:	473d                	li	a4,15
ffffffffc020092a:	842a                	mv	s0,a0
ffffffffc020092c:	14f76a63          	bltu	a4,a5,ffffffffc0200a80 <exception_handler+0x164>
ffffffffc0200930:	00005717          	auipc	a4,0x5
ffffffffc0200934:	f4870713          	addi	a4,a4,-184 # ffffffffc0205878 <commands+0x6c8>
ffffffffc0200938:	078a                	slli	a5,a5,0x2
ffffffffc020093a:	97ba                	add	a5,a5,a4
ffffffffc020093c:	439c                	lw	a5,0(a5)
ffffffffc020093e:	97ba                	add	a5,a5,a4
ffffffffc0200940:	8782                	jr	a5
                print_trapframe(tf); // 打印陷阱帧
                panic("handle pgfault failed. %e\n", ret); // 触发内核恐慌，表示页错误处理失败
            }
            break;
        case CAUSE_STORE_PAGE_FAULT: // 存储页错误
            cprintf("Store/AMO page fault\n"); // 打印存储页错误信息
ffffffffc0200942:	00005517          	auipc	a0,0x5
ffffffffc0200946:	f1e50513          	addi	a0,a0,-226 # ffffffffc0205860 <commands+0x6b0>
ffffffffc020094a:	f82ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) { // 如果页错误处理失败
ffffffffc020094e:	8522                	mv	a0,s0
ffffffffc0200950:	c7bff0ef          	jal	ra,ffffffffc02005ca <pgfault_handler>
ffffffffc0200954:	84aa                	mv	s1,a0
ffffffffc0200956:	12051b63          	bnez	a0,ffffffffc0200a8c <exception_handler+0x170>
            break;
        default: // 其他异常
            print_trapframe(tf); // 打印陷阱帧
            break;
    }
}
ffffffffc020095a:	60e2                	ld	ra,24(sp)
ffffffffc020095c:	6442                	ld	s0,16(sp)
ffffffffc020095e:	64a2                	ld	s1,8(sp)
ffffffffc0200960:	6105                	addi	sp,sp,32
ffffffffc0200962:	8082                	ret
            cprintf("Instruction address misaligned\n"); // 打印指令地址未对齐信息
ffffffffc0200964:	00005517          	auipc	a0,0x5
ffffffffc0200968:	d5c50513          	addi	a0,a0,-676 # ffffffffc02056c0 <commands+0x510>
}
ffffffffc020096c:	6442                	ld	s0,16(sp)
ffffffffc020096e:	60e2                	ld	ra,24(sp)
ffffffffc0200970:	64a2                	ld	s1,8(sp)
ffffffffc0200972:	6105                	addi	sp,sp,32
            cprintf("Instruction access fault\n"); // 打印指令访问错误信息
ffffffffc0200974:	f58ff06f          	j	ffffffffc02000cc <cprintf>
ffffffffc0200978:	00005517          	auipc	a0,0x5
ffffffffc020097c:	d6850513          	addi	a0,a0,-664 # ffffffffc02056e0 <commands+0x530>
ffffffffc0200980:	b7f5                	j	ffffffffc020096c <exception_handler+0x50>
            cprintf("Illegal instruction\n"); // 打印非法指令信息
ffffffffc0200982:	00005517          	auipc	a0,0x5
ffffffffc0200986:	d7e50513          	addi	a0,a0,-642 # ffffffffc0205700 <commands+0x550>
ffffffffc020098a:	b7cd                	j	ffffffffc020096c <exception_handler+0x50>
            cprintf("Breakpoint\n"); // 打印断点信息
ffffffffc020098c:	00005517          	auipc	a0,0x5
ffffffffc0200990:	d8c50513          	addi	a0,a0,-628 # ffffffffc0205718 <commands+0x568>
ffffffffc0200994:	bfe1                	j	ffffffffc020096c <exception_handler+0x50>
            cprintf("Load address misaligned\n"); // 打印加载地址未对齐信息
ffffffffc0200996:	00005517          	auipc	a0,0x5
ffffffffc020099a:	d9250513          	addi	a0,a0,-622 # ffffffffc0205728 <commands+0x578>
ffffffffc020099e:	b7f9                	j	ffffffffc020096c <exception_handler+0x50>
            cprintf("Load access fault\n"); // 打印加载访问错误信息
ffffffffc02009a0:	00005517          	auipc	a0,0x5
ffffffffc02009a4:	da850513          	addi	a0,a0,-600 # ffffffffc0205748 <commands+0x598>
ffffffffc02009a8:	f24ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) { // 如果页错误处理失败
ffffffffc02009ac:	8522                	mv	a0,s0
ffffffffc02009ae:	c1dff0ef          	jal	ra,ffffffffc02005ca <pgfault_handler>
ffffffffc02009b2:	84aa                	mv	s1,a0
ffffffffc02009b4:	d15d                	beqz	a0,ffffffffc020095a <exception_handler+0x3e>
                print_trapframe(tf); // 打印陷阱帧
ffffffffc02009b6:	8522                	mv	a0,s0
ffffffffc02009b8:	e6bff0ef          	jal	ra,ffffffffc0200822 <print_trapframe>
                panic("handle pgfault failed. %e\n", ret); // 触发内核恐慌，表示页错误处理失败
ffffffffc02009bc:	86a6                	mv	a3,s1
ffffffffc02009be:	00005617          	auipc	a2,0x5
ffffffffc02009c2:	da260613          	addi	a2,a2,-606 # ffffffffc0205760 <commands+0x5b0>
ffffffffc02009c6:	0be00593          	li	a1,190
ffffffffc02009ca:	00005517          	auipc	a0,0x5
ffffffffc02009ce:	88650513          	addi	a0,a0,-1914 # ffffffffc0205250 <commands+0xa0>
ffffffffc02009d2:	ff6ff0ef          	jal	ra,ffffffffc02001c8 <__panic>
            cprintf("AMO address misaligned\n"); // 打印存储地址未对齐信息
ffffffffc02009d6:	00005517          	auipc	a0,0x5
ffffffffc02009da:	daa50513          	addi	a0,a0,-598 # ffffffffc0205780 <commands+0x5d0>
ffffffffc02009de:	b779                	j	ffffffffc020096c <exception_handler+0x50>
            cprintf("Store/AMO access fault\n"); // 打印存储访问错误信息
ffffffffc02009e0:	00005517          	auipc	a0,0x5
ffffffffc02009e4:	db850513          	addi	a0,a0,-584 # ffffffffc0205798 <commands+0x5e8>
ffffffffc02009e8:	ee4ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) { // 如果页错误处理失败
ffffffffc02009ec:	8522                	mv	a0,s0
ffffffffc02009ee:	bddff0ef          	jal	ra,ffffffffc02005ca <pgfault_handler>
ffffffffc02009f2:	84aa                	mv	s1,a0
ffffffffc02009f4:	d13d                	beqz	a0,ffffffffc020095a <exception_handler+0x3e>
                print_trapframe(tf); // 打印陷阱帧
ffffffffc02009f6:	8522                	mv	a0,s0
ffffffffc02009f8:	e2bff0ef          	jal	ra,ffffffffc0200822 <print_trapframe>
                panic("handle pgfault failed. %e\n", ret); // 触发内核恐慌，表示页错误处理失败
ffffffffc02009fc:	86a6                	mv	a3,s1
ffffffffc02009fe:	00005617          	auipc	a2,0x5
ffffffffc0200a02:	d6260613          	addi	a2,a2,-670 # ffffffffc0205760 <commands+0x5b0>
ffffffffc0200a06:	0c800593          	li	a1,200
ffffffffc0200a0a:	00005517          	auipc	a0,0x5
ffffffffc0200a0e:	84650513          	addi	a0,a0,-1978 # ffffffffc0205250 <commands+0xa0>
ffffffffc0200a12:	fb6ff0ef          	jal	ra,ffffffffc02001c8 <__panic>
            cprintf("Environment call from U-mode\n"); // 打印用户模式环境调用信息
ffffffffc0200a16:	00005517          	auipc	a0,0x5
ffffffffc0200a1a:	d9a50513          	addi	a0,a0,-614 # ffffffffc02057b0 <commands+0x600>
ffffffffc0200a1e:	b7b9                	j	ffffffffc020096c <exception_handler+0x50>
            cprintf("Environment call from S-mode\n"); // 打印监督者模式环境调用信息
ffffffffc0200a20:	00005517          	auipc	a0,0x5
ffffffffc0200a24:	db050513          	addi	a0,a0,-592 # ffffffffc02057d0 <commands+0x620>
ffffffffc0200a28:	b791                	j	ffffffffc020096c <exception_handler+0x50>
            cprintf("Environment call from H-mode\n"); // 打印管理者模式环境调用信息
ffffffffc0200a2a:	00005517          	auipc	a0,0x5
ffffffffc0200a2e:	dc650513          	addi	a0,a0,-570 # ffffffffc02057f0 <commands+0x640>
ffffffffc0200a32:	bf2d                	j	ffffffffc020096c <exception_handler+0x50>
            cprintf("Environment call from M-mode\n"); // 打印机器模式环境调用信息
ffffffffc0200a34:	00005517          	auipc	a0,0x5
ffffffffc0200a38:	ddc50513          	addi	a0,a0,-548 # ffffffffc0205810 <commands+0x660>
ffffffffc0200a3c:	bf05                	j	ffffffffc020096c <exception_handler+0x50>
            cprintf("Instruction page fault\n"); // 打印指令页错误信息
ffffffffc0200a3e:	00005517          	auipc	a0,0x5
ffffffffc0200a42:	df250513          	addi	a0,a0,-526 # ffffffffc0205830 <commands+0x680>
ffffffffc0200a46:	b71d                	j	ffffffffc020096c <exception_handler+0x50>
            cprintf("Load page fault\n"); // 打印加载页错误信息
ffffffffc0200a48:	00005517          	auipc	a0,0x5
ffffffffc0200a4c:	e0050513          	addi	a0,a0,-512 # ffffffffc0205848 <commands+0x698>
ffffffffc0200a50:	e7cff0ef          	jal	ra,ffffffffc02000cc <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) { // 如果页错误处理失败
ffffffffc0200a54:	8522                	mv	a0,s0
ffffffffc0200a56:	b75ff0ef          	jal	ra,ffffffffc02005ca <pgfault_handler>
ffffffffc0200a5a:	84aa                	mv	s1,a0
ffffffffc0200a5c:	ee050fe3          	beqz	a0,ffffffffc020095a <exception_handler+0x3e>
                print_trapframe(tf); // 打印陷阱帧
ffffffffc0200a60:	8522                	mv	a0,s0
ffffffffc0200a62:	dc1ff0ef          	jal	ra,ffffffffc0200822 <print_trapframe>
                panic("handle pgfault failed. %e\n", ret); // 触发内核恐慌，表示页错误处理失败
ffffffffc0200a66:	86a6                	mv	a3,s1
ffffffffc0200a68:	00005617          	auipc	a2,0x5
ffffffffc0200a6c:	cf860613          	addi	a2,a2,-776 # ffffffffc0205760 <commands+0x5b0>
ffffffffc0200a70:	0de00593          	li	a1,222
ffffffffc0200a74:	00004517          	auipc	a0,0x4
ffffffffc0200a78:	7dc50513          	addi	a0,a0,2012 # ffffffffc0205250 <commands+0xa0>
ffffffffc0200a7c:	f4cff0ef          	jal	ra,ffffffffc02001c8 <__panic>
            print_trapframe(tf); // 打印陷阱帧
ffffffffc0200a80:	8522                	mv	a0,s0
}
ffffffffc0200a82:	6442                	ld	s0,16(sp)
ffffffffc0200a84:	60e2                	ld	ra,24(sp)
ffffffffc0200a86:	64a2                	ld	s1,8(sp)
ffffffffc0200a88:	6105                	addi	sp,sp,32
            print_trapframe(tf); // 打印陷阱帧
ffffffffc0200a8a:	bb61                	j	ffffffffc0200822 <print_trapframe>
                print_trapframe(tf); // 打印陷阱帧
ffffffffc0200a8c:	8522                	mv	a0,s0
ffffffffc0200a8e:	d95ff0ef          	jal	ra,ffffffffc0200822 <print_trapframe>
                panic("handle pgfault failed. %e\n", ret); // 触发内核恐慌，表示页错误处理失败
ffffffffc0200a92:	86a6                	mv	a3,s1
ffffffffc0200a94:	00005617          	auipc	a2,0x5
ffffffffc0200a98:	ccc60613          	addi	a2,a2,-820 # ffffffffc0205760 <commands+0x5b0>
ffffffffc0200a9c:	0e500593          	li	a1,229
ffffffffc0200aa0:	00004517          	auipc	a0,0x4
ffffffffc0200aa4:	7b050513          	addi	a0,a0,1968 # ffffffffc0205250 <commands+0xa0>
ffffffffc0200aa8:	f20ff0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc0200aac <trap>:
 * 处理或分派异常/中断。当trap()返回时，kern/trap/trapentry.S中的代码会恢复保存在trapframe中的旧CPU状态，然后使用iret指令从异常中返回。
 * */
void trap(struct trapframe *tf) {
    // dispatch based on what type of trap occurred
    // 根据发生的陷阱类型进行分派
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200aac:	11853783          	ld	a5,280(a0)
ffffffffc0200ab0:	0007c363          	bltz	a5,ffffffffc0200ab6 <trap+0xa>
        // 中断
        interrupt_handler(tf); // 调用中断处理函数
    } else {
        // exceptions
        // 异常
        exception_handler(tf); // 调用异常处理函数
ffffffffc0200ab4:	b5a5                	j	ffffffffc020091c <exception_handler>
        interrupt_handler(tf); // 调用中断处理函数
ffffffffc0200ab6:	b3f9                	j	ffffffffc0200884 <interrupt_handler>

ffffffffc0200ab8 <__alltraps>:
    LOAD  x2,2*REGBYTES(sp)  // 恢复 x2 寄存器
    .endm  // 结束宏定义

    .globl __alltraps  // 声明全局符号 __alltraps
__alltraps:  // 定义 __alltraps 标签
    SAVE_ALL  // 调用 SAVE_ALL 宏
ffffffffc0200ab8:	14011073          	csrw	sscratch,sp
ffffffffc0200abc:	712d                	addi	sp,sp,-288
ffffffffc0200abe:	e406                	sd	ra,8(sp)
ffffffffc0200ac0:	ec0e                	sd	gp,24(sp)
ffffffffc0200ac2:	f012                	sd	tp,32(sp)
ffffffffc0200ac4:	f416                	sd	t0,40(sp)
ffffffffc0200ac6:	f81a                	sd	t1,48(sp)
ffffffffc0200ac8:	fc1e                	sd	t2,56(sp)
ffffffffc0200aca:	e0a2                	sd	s0,64(sp)
ffffffffc0200acc:	e4a6                	sd	s1,72(sp)
ffffffffc0200ace:	e8aa                	sd	a0,80(sp)
ffffffffc0200ad0:	ecae                	sd	a1,88(sp)
ffffffffc0200ad2:	f0b2                	sd	a2,96(sp)
ffffffffc0200ad4:	f4b6                	sd	a3,104(sp)
ffffffffc0200ad6:	f8ba                	sd	a4,112(sp)
ffffffffc0200ad8:	fcbe                	sd	a5,120(sp)
ffffffffc0200ada:	e142                	sd	a6,128(sp)
ffffffffc0200adc:	e546                	sd	a7,136(sp)
ffffffffc0200ade:	e94a                	sd	s2,144(sp)
ffffffffc0200ae0:	ed4e                	sd	s3,152(sp)
ffffffffc0200ae2:	f152                	sd	s4,160(sp)
ffffffffc0200ae4:	f556                	sd	s5,168(sp)
ffffffffc0200ae6:	f95a                	sd	s6,176(sp)
ffffffffc0200ae8:	fd5e                	sd	s7,184(sp)
ffffffffc0200aea:	e1e2                	sd	s8,192(sp)
ffffffffc0200aec:	e5e6                	sd	s9,200(sp)
ffffffffc0200aee:	e9ea                	sd	s10,208(sp)
ffffffffc0200af0:	edee                	sd	s11,216(sp)
ffffffffc0200af2:	f1f2                	sd	t3,224(sp)
ffffffffc0200af4:	f5f6                	sd	t4,232(sp)
ffffffffc0200af6:	f9fa                	sd	t5,240(sp)
ffffffffc0200af8:	fdfe                	sd	t6,248(sp)
ffffffffc0200afa:	14002473          	csrr	s0,sscratch
ffffffffc0200afe:	100024f3          	csrr	s1,sstatus
ffffffffc0200b02:	14102973          	csrr	s2,sepc
ffffffffc0200b06:	143029f3          	csrr	s3,stval
ffffffffc0200b0a:	14202a73          	csrr	s4,scause
ffffffffc0200b0e:	e822                	sd	s0,16(sp)
ffffffffc0200b10:	e226                	sd	s1,256(sp)
ffffffffc0200b12:	e64a                	sd	s2,264(sp)
ffffffffc0200b14:	ea4e                	sd	s3,272(sp)
ffffffffc0200b16:	ee52                	sd	s4,280(sp)

    move  a0, sp  // 将栈指针移动到 a0
ffffffffc0200b18:	850a                	mv	a0,sp
    jal trap  // 跳转并链接到 trap 函数
ffffffffc0200b1a:	f93ff0ef          	jal	ra,ffffffffc0200aac <trap>

ffffffffc0200b1e <__trapret>:
    # sp should be the same as before "jal trap"  // sp 应该和 "jal trap" 之前一样
    # 因为调用 trap 函数时，栈指针（SP）用于保存当前的寄存器状态和其他上下文信息。

    .globl __trapret  // 声明全局符号 __trapret
__trapret:  // 定义 __trapret 标签
    RESTORE_ALL  // 调用 RESTORE_ALL 宏
ffffffffc0200b1e:	6492                	ld	s1,256(sp)
ffffffffc0200b20:	6932                	ld	s2,264(sp)
ffffffffc0200b22:	10049073          	csrw	sstatus,s1
ffffffffc0200b26:	14191073          	csrw	sepc,s2
ffffffffc0200b2a:	60a2                	ld	ra,8(sp)
ffffffffc0200b2c:	61e2                	ld	gp,24(sp)
ffffffffc0200b2e:	7202                	ld	tp,32(sp)
ffffffffc0200b30:	72a2                	ld	t0,40(sp)
ffffffffc0200b32:	7342                	ld	t1,48(sp)
ffffffffc0200b34:	73e2                	ld	t2,56(sp)
ffffffffc0200b36:	6406                	ld	s0,64(sp)
ffffffffc0200b38:	64a6                	ld	s1,72(sp)
ffffffffc0200b3a:	6546                	ld	a0,80(sp)
ffffffffc0200b3c:	65e6                	ld	a1,88(sp)
ffffffffc0200b3e:	7606                	ld	a2,96(sp)
ffffffffc0200b40:	76a6                	ld	a3,104(sp)
ffffffffc0200b42:	7746                	ld	a4,112(sp)
ffffffffc0200b44:	77e6                	ld	a5,120(sp)
ffffffffc0200b46:	680a                	ld	a6,128(sp)
ffffffffc0200b48:	68aa                	ld	a7,136(sp)
ffffffffc0200b4a:	694a                	ld	s2,144(sp)
ffffffffc0200b4c:	69ea                	ld	s3,152(sp)
ffffffffc0200b4e:	7a0a                	ld	s4,160(sp)
ffffffffc0200b50:	7aaa                	ld	s5,168(sp)
ffffffffc0200b52:	7b4a                	ld	s6,176(sp)
ffffffffc0200b54:	7bea                	ld	s7,184(sp)
ffffffffc0200b56:	6c0e                	ld	s8,192(sp)
ffffffffc0200b58:	6cae                	ld	s9,200(sp)
ffffffffc0200b5a:	6d4e                	ld	s10,208(sp)
ffffffffc0200b5c:	6dee                	ld	s11,216(sp)
ffffffffc0200b5e:	7e0e                	ld	t3,224(sp)
ffffffffc0200b60:	7eae                	ld	t4,232(sp)
ffffffffc0200b62:	7f4e                	ld	t5,240(sp)
ffffffffc0200b64:	7fee                	ld	t6,248(sp)
ffffffffc0200b66:	6142                	ld	sp,16(sp)
    # go back from supervisor call  // 从超级调用返回
    sret  // 执行 sret 指令返回，在proc.c中设置了epc为kernel_thread_entry，kernel_thread_entry在entry.s中
ffffffffc0200b68:	10200073          	sret

ffffffffc0200b6c <forkrets>:

    .globl forkrets  // 声明全局符号 forkrets
forkrets:  // 定义 forkrets 标签
    # set stack to this new process's trapframe  // 将栈设置为这个新进程的 trapframe
    move sp, a0  // 将 a0 移动到栈指针，中断帧放在了sp，这样在__trapret中就可以直接从中断帧里面恢复所有的寄存器
ffffffffc0200b6c:	812a                	mv	sp,a0
    j __trapret  // 跳转到 __trapret
ffffffffc0200b6e:	bf45                	j	ffffffffc0200b1e <__trapret>
	...

ffffffffc0200b72 <pa2page.part.0>:
page2pa(struct Page *page) { // 将 Page 转换为物理地址
    return page2ppn(page) << PGSHIFT;
}

static inline struct Page *
pa2page(uintptr_t pa) { // 将物理地址转换为 Page
ffffffffc0200b72:	1141                	addi	sp,sp,-16
    if (PPN(pa) >= npage) {
        panic("pa2page called with invalid pa");
ffffffffc0200b74:	00005617          	auipc	a2,0x5
ffffffffc0200b78:	d4460613          	addi	a2,a2,-700 # ffffffffc02058b8 <commands+0x708>
ffffffffc0200b7c:	06000593          	li	a1,96
ffffffffc0200b80:	00005517          	auipc	a0,0x5
ffffffffc0200b84:	d5850513          	addi	a0,a0,-680 # ffffffffc02058d8 <commands+0x728>
pa2page(uintptr_t pa) { // 将物理地址转换为 Page
ffffffffc0200b88:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0200b8a:	e3eff0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc0200b8e <pte2page.part.0>:
kva2page(void *kva) { // 将内核虚拟地址转换为 Page
    return pa2page(PADDR(kva));
}

static inline struct Page *
pte2page(pte_t pte) { // 将页表项转换为 Page
ffffffffc0200b8e:	1141                	addi	sp,sp,-16
    if (!(pte & PTE_V)) {
        panic("pte2page called with invalid pte");
ffffffffc0200b90:	00005617          	auipc	a2,0x5
ffffffffc0200b94:	d5860613          	addi	a2,a2,-680 # ffffffffc02058e8 <commands+0x738>
ffffffffc0200b98:	07200593          	li	a1,114
ffffffffc0200b9c:	00005517          	auipc	a0,0x5
ffffffffc0200ba0:	d3c50513          	addi	a0,a0,-708 # ffffffffc02058d8 <commands+0x728>
pte2page(pte_t pte) { // 将页表项转换为 Page
ffffffffc0200ba4:	e406                	sd	ra,8(sp)
        panic("pte2page called with invalid pte");
ffffffffc0200ba6:	e22ff0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc0200baa <alloc_pages>:
static void init_memmap(struct Page *base, size_t n) {
    pmm_manager->init_memmap(base, n);
}

// 分配连续的n个物理页
struct Page *alloc_pages(size_t n) {
ffffffffc0200baa:	7139                	addi	sp,sp,-64
ffffffffc0200bac:	f426                	sd	s1,40(sp)
ffffffffc0200bae:	f04a                	sd	s2,32(sp)
ffffffffc0200bb0:	ec4e                	sd	s3,24(sp)
ffffffffc0200bb2:	e852                	sd	s4,16(sp)
ffffffffc0200bb4:	e456                	sd	s5,8(sp)
ffffffffc0200bb6:	e05a                	sd	s6,0(sp)
ffffffffc0200bb8:	fc06                	sd	ra,56(sp)
ffffffffc0200bba:	f822                	sd	s0,48(sp)
ffffffffc0200bbc:	84aa                	mv	s1,a0
ffffffffc0200bbe:	00016917          	auipc	s2,0x16
ffffffffc0200bc2:	9b290913          	addi	s2,s2,-1614 # ffffffffc0216570 <pmm_manager>
        {
            page = pmm_manager->alloc_pages(n); // 分配页
        }
        local_intr_restore(intr_flag); // 恢复中断

        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc0200bc6:	4a05                	li	s4,1
ffffffffc0200bc8:	00016a97          	auipc	s5,0x16
ffffffffc0200bcc:	9d8a8a93          	addi	s5,s5,-1576 # ffffffffc02165a0 <swap_init_ok>

        extern struct mm_struct *check_mm_struct;
        // cprintf("page %x, call swap_out in alloc_pages %d\n",page, n);
        swap_out(check_mm_struct, n, 0); // 交换出去
ffffffffc0200bd0:	0005099b          	sext.w	s3,a0
ffffffffc0200bd4:	00016b17          	auipc	s6,0x16
ffffffffc0200bd8:	9acb0b13          	addi	s6,s6,-1620 # ffffffffc0216580 <check_mm_struct>
ffffffffc0200bdc:	a01d                	j	ffffffffc0200c02 <alloc_pages+0x58>
            page = pmm_manager->alloc_pages(n); // 分配页
ffffffffc0200bde:	00093783          	ld	a5,0(s2)
ffffffffc0200be2:	6f9c                	ld	a5,24(a5)
ffffffffc0200be4:	9782                	jalr	a5
ffffffffc0200be6:	842a                	mv	s0,a0
        swap_out(check_mm_struct, n, 0); // 交换出去
ffffffffc0200be8:	4601                	li	a2,0
ffffffffc0200bea:	85ce                	mv	a1,s3
        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc0200bec:	ec0d                	bnez	s0,ffffffffc0200c26 <alloc_pages+0x7c>
ffffffffc0200bee:	029a6c63          	bltu	s4,s1,ffffffffc0200c26 <alloc_pages+0x7c>
ffffffffc0200bf2:	000aa783          	lw	a5,0(s5)
ffffffffc0200bf6:	2781                	sext.w	a5,a5
ffffffffc0200bf8:	c79d                	beqz	a5,ffffffffc0200c26 <alloc_pages+0x7c>
        swap_out(check_mm_struct, n, 0); // 交换出去
ffffffffc0200bfa:	000b3503          	ld	a0,0(s6)
ffffffffc0200bfe:	0c2020ef          	jal	ra,ffffffffc0202cc0 <swap_out>
    if (read_csr(sstatus) & SSTATUS_SIE) { // 如果当前中断使能
ffffffffc0200c02:	100027f3          	csrr	a5,sstatus
ffffffffc0200c06:	8b89                	andi	a5,a5,2
            page = pmm_manager->alloc_pages(n); // 分配页
ffffffffc0200c08:	8526                	mv	a0,s1
ffffffffc0200c0a:	dbf1                	beqz	a5,ffffffffc0200bde <alloc_pages+0x34>
        intr_disable(); // 禁用中断
ffffffffc0200c0c:	9b9ff0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
ffffffffc0200c10:	00093783          	ld	a5,0(s2)
ffffffffc0200c14:	8526                	mv	a0,s1
ffffffffc0200c16:	6f9c                	ld	a5,24(a5)
ffffffffc0200c18:	9782                	jalr	a5
ffffffffc0200c1a:	842a                	mv	s0,a0
        intr_enable(); // 使能中断
ffffffffc0200c1c:	9a3ff0ef          	jal	ra,ffffffffc02005be <intr_enable>
        swap_out(check_mm_struct, n, 0); // 交换出去
ffffffffc0200c20:	4601                	li	a2,0
ffffffffc0200c22:	85ce                	mv	a1,s3
        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc0200c24:	d469                	beqz	s0,ffffffffc0200bee <alloc_pages+0x44>
    }
    // cprintf("n %d,get page %x, No %d in alloc_pages\n",n,page,(page-pages));
    return page;
}
ffffffffc0200c26:	70e2                	ld	ra,56(sp)
ffffffffc0200c28:	8522                	mv	a0,s0
ffffffffc0200c2a:	7442                	ld	s0,48(sp)
ffffffffc0200c2c:	74a2                	ld	s1,40(sp)
ffffffffc0200c2e:	7902                	ld	s2,32(sp)
ffffffffc0200c30:	69e2                	ld	s3,24(sp)
ffffffffc0200c32:	6a42                	ld	s4,16(sp)
ffffffffc0200c34:	6aa2                	ld	s5,8(sp)
ffffffffc0200c36:	6b02                	ld	s6,0(sp)
ffffffffc0200c38:	6121                	addi	sp,sp,64
ffffffffc0200c3a:	8082                	ret

ffffffffc0200c3c <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) { // 如果当前中断使能
ffffffffc0200c3c:	100027f3          	csrr	a5,sstatus
ffffffffc0200c40:	8b89                	andi	a5,a5,2
ffffffffc0200c42:	e799                	bnez	a5,ffffffffc0200c50 <free_pages+0x14>
// 释放连续的n个物理页
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0200c44:	00016797          	auipc	a5,0x16
ffffffffc0200c48:	92c7b783          	ld	a5,-1748(a5) # ffffffffc0216570 <pmm_manager>
ffffffffc0200c4c:	739c                	ld	a5,32(a5)
ffffffffc0200c4e:	8782                	jr	a5
void free_pages(struct Page *base, size_t n) {
ffffffffc0200c50:	1101                	addi	sp,sp,-32
ffffffffc0200c52:	ec06                	sd	ra,24(sp)
ffffffffc0200c54:	e822                	sd	s0,16(sp)
ffffffffc0200c56:	e426                	sd	s1,8(sp)
ffffffffc0200c58:	842a                	mv	s0,a0
ffffffffc0200c5a:	84ae                	mv	s1,a1
        intr_disable(); // 禁用中断
ffffffffc0200c5c:	969ff0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0200c60:	00016797          	auipc	a5,0x16
ffffffffc0200c64:	9107b783          	ld	a5,-1776(a5) # ffffffffc0216570 <pmm_manager>
ffffffffc0200c68:	739c                	ld	a5,32(a5)
ffffffffc0200c6a:	85a6                	mv	a1,s1
ffffffffc0200c6c:	8522                	mv	a0,s0
ffffffffc0200c6e:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0200c70:	6442                	ld	s0,16(sp)
ffffffffc0200c72:	60e2                	ld	ra,24(sp)
ffffffffc0200c74:	64a2                	ld	s1,8(sp)
ffffffffc0200c76:	6105                	addi	sp,sp,32
        intr_enable(); // 使能中断
ffffffffc0200c78:	947ff06f          	j	ffffffffc02005be <intr_enable>

ffffffffc0200c7c <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) { // 如果当前中断使能
ffffffffc0200c7c:	100027f3          	csrr	a5,sstatus
ffffffffc0200c80:	8b89                	andi	a5,a5,2
ffffffffc0200c82:	e799                	bnez	a5,ffffffffc0200c90 <nr_free_pages+0x14>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0200c84:	00016797          	auipc	a5,0x16
ffffffffc0200c88:	8ec7b783          	ld	a5,-1812(a5) # ffffffffc0216570 <pmm_manager>
ffffffffc0200c8c:	779c                	ld	a5,40(a5)
ffffffffc0200c8e:	8782                	jr	a5
size_t nr_free_pages(void) {
ffffffffc0200c90:	1141                	addi	sp,sp,-16
ffffffffc0200c92:	e406                	sd	ra,8(sp)
ffffffffc0200c94:	e022                	sd	s0,0(sp)
        intr_disable(); // 禁用中断
ffffffffc0200c96:	92fff0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0200c9a:	00016797          	auipc	a5,0x16
ffffffffc0200c9e:	8d67b783          	ld	a5,-1834(a5) # ffffffffc0216570 <pmm_manager>
ffffffffc0200ca2:	779c                	ld	a5,40(a5)
ffffffffc0200ca4:	9782                	jalr	a5
ffffffffc0200ca6:	842a                	mv	s0,a0
        intr_enable(); // 使能中断
ffffffffc0200ca8:	917ff0ef          	jal	ra,ffffffffc02005be <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0200cac:	60a2                	ld	ra,8(sp)
ffffffffc0200cae:	8522                	mv	a0,s0
ffffffffc0200cb0:	6402                	ld	s0,0(sp)
ffffffffc0200cb2:	0141                	addi	sp,sp,16
ffffffffc0200cb4:	8082                	ret

ffffffffc0200cb6 <get_pte>:
    kmalloc_init();
}

// 获取线性地址la对应的PTE的内核虚拟地址，如果不存在则根据create决定是否创建
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0200cb6:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0200cba:	1ff7f793          	andi	a5,a5,511
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0200cbe:	7139                	addi	sp,sp,-64
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0200cc0:	078e                	slli	a5,a5,0x3
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0200cc2:	f426                	sd	s1,40(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0200cc4:	00f504b3          	add	s1,a0,a5
    if (!(*pdep1 & PTE_V)) {
ffffffffc0200cc8:	6094                	ld	a3,0(s1)
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0200cca:	f04a                	sd	s2,32(sp)
ffffffffc0200ccc:	ec4e                	sd	s3,24(sp)
ffffffffc0200cce:	e852                	sd	s4,16(sp)
ffffffffc0200cd0:	fc06                	sd	ra,56(sp)
ffffffffc0200cd2:	f822                	sd	s0,48(sp)
ffffffffc0200cd4:	e456                	sd	s5,8(sp)
ffffffffc0200cd6:	e05a                	sd	s6,0(sp)
    if (!(*pdep1 & PTE_V)) {
ffffffffc0200cd8:	0016f793          	andi	a5,a3,1
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0200cdc:	892e                	mv	s2,a1
ffffffffc0200cde:	89b2                	mv	s3,a2
ffffffffc0200ce0:	00016a17          	auipc	s4,0x16
ffffffffc0200ce4:	880a0a13          	addi	s4,s4,-1920 # ffffffffc0216560 <npage>
    if (!(*pdep1 & PTE_V)) {
ffffffffc0200ce8:	e7b5                	bnez	a5,ffffffffc0200d54 <get_pte+0x9e>
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
ffffffffc0200cea:	12060b63          	beqz	a2,ffffffffc0200e20 <get_pte+0x16a>
ffffffffc0200cee:	4505                	li	a0,1
ffffffffc0200cf0:	ebbff0ef          	jal	ra,ffffffffc0200baa <alloc_pages>
ffffffffc0200cf4:	842a                	mv	s0,a0
ffffffffc0200cf6:	12050563          	beqz	a0,ffffffffc0200e20 <get_pte+0x16a>
    return page - pages + nbase;
ffffffffc0200cfa:	00016b17          	auipc	s6,0x16
ffffffffc0200cfe:	86eb0b13          	addi	s6,s6,-1938 # ffffffffc0216568 <pages>
ffffffffc0200d02:	000b3503          	ld	a0,0(s6)
ffffffffc0200d06:	00080ab7          	lui	s5,0x80
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE); // 清空新页
ffffffffc0200d0a:	00016a17          	auipc	s4,0x16
ffffffffc0200d0e:	856a0a13          	addi	s4,s4,-1962 # ffffffffc0216560 <npage>
ffffffffc0200d12:	40a40533          	sub	a0,s0,a0
ffffffffc0200d16:	8519                	srai	a0,a0,0x6
ffffffffc0200d18:	9556                	add	a0,a0,s5
ffffffffc0200d1a:	000a3703          	ld	a4,0(s4)
ffffffffc0200d1e:	00c51793          	slli	a5,a0,0xc
    return page->ref;
}

static inline void
set_page_ref(struct Page *page, int val) { // 设置 Page 的引用计数
    page->ref = val;
ffffffffc0200d22:	4685                	li	a3,1
ffffffffc0200d24:	c014                	sw	a3,0(s0)
ffffffffc0200d26:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0200d28:	0532                	slli	a0,a0,0xc
ffffffffc0200d2a:	14e7f263          	bgeu	a5,a4,ffffffffc0200e6e <get_pte+0x1b8>
ffffffffc0200d2e:	00016797          	auipc	a5,0x16
ffffffffc0200d32:	84a7b783          	ld	a5,-1974(a5) # ffffffffc0216578 <va_pa_offset>
ffffffffc0200d36:	6605                	lui	a2,0x1
ffffffffc0200d38:	4581                	li	a1,0
ffffffffc0200d3a:	953e                	add	a0,a0,a5
ffffffffc0200d3c:	595030ef          	jal	ra,ffffffffc0204ad0 <memset>
    return page - pages + nbase;
ffffffffc0200d40:	000b3683          	ld	a3,0(s6)
ffffffffc0200d44:	40d406b3          	sub	a3,s0,a3
ffffffffc0200d48:	8699                	srai	a3,a3,0x6
ffffffffc0200d4a:	96d6                	add	a3,a3,s5
  asm volatile("sfence.vma");
}

// 构造页表项
static inline pte_t pte_create(uintptr_t ppn, int type) {
  return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0200d4c:	06aa                	slli	a3,a3,0xa
ffffffffc0200d4e:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V); // 创建PDE
ffffffffc0200d52:	e094                	sd	a3,0(s1)
    }
    pde_t *pdep0 = &((pte_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0200d54:	77fd                	lui	a5,0xfffff
ffffffffc0200d56:	068a                	slli	a3,a3,0x2
ffffffffc0200d58:	000a3703          	ld	a4,0(s4)
ffffffffc0200d5c:	8efd                	and	a3,a3,a5
ffffffffc0200d5e:	00c6d793          	srli	a5,a3,0xc
ffffffffc0200d62:	0ce7f163          	bgeu	a5,a4,ffffffffc0200e24 <get_pte+0x16e>
ffffffffc0200d66:	00016a97          	auipc	s5,0x16
ffffffffc0200d6a:	812a8a93          	addi	s5,s5,-2030 # ffffffffc0216578 <va_pa_offset>
ffffffffc0200d6e:	000ab403          	ld	s0,0(s5)
ffffffffc0200d72:	01595793          	srli	a5,s2,0x15
ffffffffc0200d76:	1ff7f793          	andi	a5,a5,511
ffffffffc0200d7a:	96a2                	add	a3,a3,s0
ffffffffc0200d7c:	00379413          	slli	s0,a5,0x3
ffffffffc0200d80:	9436                	add	s0,s0,a3
    if (!(*pdep0 & PTE_V)) {
ffffffffc0200d82:	6014                	ld	a3,0(s0)
ffffffffc0200d84:	0016f793          	andi	a5,a3,1
ffffffffc0200d88:	e3ad                	bnez	a5,ffffffffc0200dea <get_pte+0x134>
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
ffffffffc0200d8a:	08098b63          	beqz	s3,ffffffffc0200e20 <get_pte+0x16a>
ffffffffc0200d8e:	4505                	li	a0,1
ffffffffc0200d90:	e1bff0ef          	jal	ra,ffffffffc0200baa <alloc_pages>
ffffffffc0200d94:	84aa                	mv	s1,a0
ffffffffc0200d96:	c549                	beqz	a0,ffffffffc0200e20 <get_pte+0x16a>
    return page - pages + nbase;
ffffffffc0200d98:	00015b17          	auipc	s6,0x15
ffffffffc0200d9c:	7d0b0b13          	addi	s6,s6,2000 # ffffffffc0216568 <pages>
ffffffffc0200da0:	000b3503          	ld	a0,0(s6)
ffffffffc0200da4:	000809b7          	lui	s3,0x80
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE); // 清空新页
ffffffffc0200da8:	000a3703          	ld	a4,0(s4)
ffffffffc0200dac:	40a48533          	sub	a0,s1,a0
ffffffffc0200db0:	8519                	srai	a0,a0,0x6
ffffffffc0200db2:	954e                	add	a0,a0,s3
ffffffffc0200db4:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0200db8:	4685                	li	a3,1
ffffffffc0200dba:	c094                	sw	a3,0(s1)
ffffffffc0200dbc:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0200dbe:	0532                	slli	a0,a0,0xc
ffffffffc0200dc0:	08e7fa63          	bgeu	a5,a4,ffffffffc0200e54 <get_pte+0x19e>
ffffffffc0200dc4:	000ab783          	ld	a5,0(s5)
ffffffffc0200dc8:	6605                	lui	a2,0x1
ffffffffc0200dca:	4581                	li	a1,0
ffffffffc0200dcc:	953e                	add	a0,a0,a5
ffffffffc0200dce:	503030ef          	jal	ra,ffffffffc0204ad0 <memset>
    return page - pages + nbase;
ffffffffc0200dd2:	000b3683          	ld	a3,0(s6)
ffffffffc0200dd6:	40d486b3          	sub	a3,s1,a3
ffffffffc0200dda:	8699                	srai	a3,a3,0x6
ffffffffc0200ddc:	96ce                	add	a3,a3,s3
  return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0200dde:	06aa                	slli	a3,a3,0xa
ffffffffc0200de0:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V); // 创建PDE
ffffffffc0200de4:	e014                	sd	a3,0(s0)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)]; // 返回PTE地址
ffffffffc0200de6:	000a3703          	ld	a4,0(s4)
ffffffffc0200dea:	068a                	slli	a3,a3,0x2
ffffffffc0200dec:	757d                	lui	a0,0xfffff
ffffffffc0200dee:	8ee9                	and	a3,a3,a0
ffffffffc0200df0:	00c6d793          	srli	a5,a3,0xc
ffffffffc0200df4:	04e7f463          	bgeu	a5,a4,ffffffffc0200e3c <get_pte+0x186>
ffffffffc0200df8:	000ab503          	ld	a0,0(s5)
ffffffffc0200dfc:	00c95913          	srli	s2,s2,0xc
ffffffffc0200e00:	1ff97913          	andi	s2,s2,511
ffffffffc0200e04:	96aa                	add	a3,a3,a0
ffffffffc0200e06:	00391513          	slli	a0,s2,0x3
ffffffffc0200e0a:	9536                	add	a0,a0,a3
}
ffffffffc0200e0c:	70e2                	ld	ra,56(sp)
ffffffffc0200e0e:	7442                	ld	s0,48(sp)
ffffffffc0200e10:	74a2                	ld	s1,40(sp)
ffffffffc0200e12:	7902                	ld	s2,32(sp)
ffffffffc0200e14:	69e2                	ld	s3,24(sp)
ffffffffc0200e16:	6a42                	ld	s4,16(sp)
ffffffffc0200e18:	6aa2                	ld	s5,8(sp)
ffffffffc0200e1a:	6b02                	ld	s6,0(sp)
ffffffffc0200e1c:	6121                	addi	sp,sp,64
ffffffffc0200e1e:	8082                	ret
            return NULL;
ffffffffc0200e20:	4501                	li	a0,0
ffffffffc0200e22:	b7ed                	j	ffffffffc0200e0c <get_pte+0x156>
    pde_t *pdep0 = &((pte_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0200e24:	00005617          	auipc	a2,0x5
ffffffffc0200e28:	aec60613          	addi	a2,a2,-1300 # ffffffffc0205910 <commands+0x760>
ffffffffc0200e2c:	0ca00593          	li	a1,202
ffffffffc0200e30:	00005517          	auipc	a0,0x5
ffffffffc0200e34:	b0850513          	addi	a0,a0,-1272 # ffffffffc0205938 <commands+0x788>
ffffffffc0200e38:	b90ff0ef          	jal	ra,ffffffffc02001c8 <__panic>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)]; // 返回PTE地址
ffffffffc0200e3c:	00005617          	auipc	a2,0x5
ffffffffc0200e40:	ad460613          	addi	a2,a2,-1324 # ffffffffc0205910 <commands+0x760>
ffffffffc0200e44:	0d500593          	li	a1,213
ffffffffc0200e48:	00005517          	auipc	a0,0x5
ffffffffc0200e4c:	af050513          	addi	a0,a0,-1296 # ffffffffc0205938 <commands+0x788>
ffffffffc0200e50:	b78ff0ef          	jal	ra,ffffffffc02001c8 <__panic>
        memset(KADDR(pa), 0, PGSIZE); // 清空新页
ffffffffc0200e54:	86aa                	mv	a3,a0
ffffffffc0200e56:	00005617          	auipc	a2,0x5
ffffffffc0200e5a:	aba60613          	addi	a2,a2,-1350 # ffffffffc0205910 <commands+0x760>
ffffffffc0200e5e:	0d200593          	li	a1,210
ffffffffc0200e62:	00005517          	auipc	a0,0x5
ffffffffc0200e66:	ad650513          	addi	a0,a0,-1322 # ffffffffc0205938 <commands+0x788>
ffffffffc0200e6a:	b5eff0ef          	jal	ra,ffffffffc02001c8 <__panic>
        memset(KADDR(pa), 0, PGSIZE); // 清空新页
ffffffffc0200e6e:	86aa                	mv	a3,a0
ffffffffc0200e70:	00005617          	auipc	a2,0x5
ffffffffc0200e74:	aa060613          	addi	a2,a2,-1376 # ffffffffc0205910 <commands+0x760>
ffffffffc0200e78:	0c700593          	li	a1,199
ffffffffc0200e7c:	00005517          	auipc	a0,0x5
ffffffffc0200e80:	abc50513          	addi	a0,a0,-1348 # ffffffffc0205938 <commands+0x788>
ffffffffc0200e84:	b44ff0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc0200e88 <get_page>:

// 获取线性地址la对应的Page结构
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
ffffffffc0200e88:	1141                	addi	sp,sp,-16
ffffffffc0200e8a:	e022                	sd	s0,0(sp)
ffffffffc0200e8c:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0200e8e:	4601                	li	a2,0
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
ffffffffc0200e90:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0200e92:	e25ff0ef          	jal	ra,ffffffffc0200cb6 <get_pte>
    if (ptep_store != NULL) {
ffffffffc0200e96:	c011                	beqz	s0,ffffffffc0200e9a <get_page+0x12>
        *ptep_store = ptep;
ffffffffc0200e98:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V) {
ffffffffc0200e9a:	c511                	beqz	a0,ffffffffc0200ea6 <get_page+0x1e>
ffffffffc0200e9c:	611c                	ld	a5,0(a0)
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc0200e9e:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V) {
ffffffffc0200ea0:	0017f713          	andi	a4,a5,1
ffffffffc0200ea4:	e709                	bnez	a4,ffffffffc0200eae <get_page+0x26>
}
ffffffffc0200ea6:	60a2                	ld	ra,8(sp)
ffffffffc0200ea8:	6402                	ld	s0,0(sp)
ffffffffc0200eaa:	0141                	addi	sp,sp,16
ffffffffc0200eac:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0200eae:	078a                	slli	a5,a5,0x2
ffffffffc0200eb0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0200eb2:	00015717          	auipc	a4,0x15
ffffffffc0200eb6:	6ae73703          	ld	a4,1710(a4) # ffffffffc0216560 <npage>
ffffffffc0200eba:	00e7ff63          	bgeu	a5,a4,ffffffffc0200ed8 <get_page+0x50>
ffffffffc0200ebe:	60a2                	ld	ra,8(sp)
ffffffffc0200ec0:	6402                	ld	s0,0(sp)
    return &pages[PPN(pa) - nbase];
ffffffffc0200ec2:	fff80537          	lui	a0,0xfff80
ffffffffc0200ec6:	97aa                	add	a5,a5,a0
ffffffffc0200ec8:	079a                	slli	a5,a5,0x6
ffffffffc0200eca:	00015517          	auipc	a0,0x15
ffffffffc0200ece:	69e53503          	ld	a0,1694(a0) # ffffffffc0216568 <pages>
ffffffffc0200ed2:	953e                	add	a0,a0,a5
ffffffffc0200ed4:	0141                	addi	sp,sp,16
ffffffffc0200ed6:	8082                	ret
ffffffffc0200ed8:	c9bff0ef          	jal	ra,ffffffffc0200b72 <pa2page.part.0>

ffffffffc0200edc <page_remove>:
        tlb_invalidate(pgdir, la);  // 刷新TLB
    }
}

// 移除线性地址la对应的页映射
void page_remove(pde_t *pgdir, uintptr_t la) {
ffffffffc0200edc:	7179                	addi	sp,sp,-48
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0200ede:	4601                	li	a2,0
void page_remove(pde_t *pgdir, uintptr_t la) {
ffffffffc0200ee0:	ec26                	sd	s1,24(sp)
ffffffffc0200ee2:	f406                	sd	ra,40(sp)
ffffffffc0200ee4:	f022                	sd	s0,32(sp)
ffffffffc0200ee6:	84ae                	mv	s1,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0200ee8:	dcfff0ef          	jal	ra,ffffffffc0200cb6 <get_pte>
    if (ptep != NULL) {
ffffffffc0200eec:	c511                	beqz	a0,ffffffffc0200ef8 <page_remove+0x1c>
    if (*ptep & PTE_V) {  // 检查PTE是否有效
ffffffffc0200eee:	611c                	ld	a5,0(a0)
ffffffffc0200ef0:	842a                	mv	s0,a0
ffffffffc0200ef2:	0017f713          	andi	a4,a5,1
ffffffffc0200ef6:	e711                	bnez	a4,ffffffffc0200f02 <page_remove+0x26>
        page_remove_pte(pgdir, la, ptep);
    }
}
ffffffffc0200ef8:	70a2                	ld	ra,40(sp)
ffffffffc0200efa:	7402                	ld	s0,32(sp)
ffffffffc0200efc:	64e2                	ld	s1,24(sp)
ffffffffc0200efe:	6145                	addi	sp,sp,48
ffffffffc0200f00:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0200f02:	078a                	slli	a5,a5,0x2
ffffffffc0200f04:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0200f06:	00015717          	auipc	a4,0x15
ffffffffc0200f0a:	65a73703          	ld	a4,1626(a4) # ffffffffc0216560 <npage>
ffffffffc0200f0e:	06e7f363          	bgeu	a5,a4,ffffffffc0200f74 <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc0200f12:	fff80537          	lui	a0,0xfff80
ffffffffc0200f16:	97aa                	add	a5,a5,a0
ffffffffc0200f18:	079a                	slli	a5,a5,0x6
ffffffffc0200f1a:	00015517          	auipc	a0,0x15
ffffffffc0200f1e:	64e53503          	ld	a0,1614(a0) # ffffffffc0216568 <pages>
ffffffffc0200f22:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc0200f24:	411c                	lw	a5,0(a0)
ffffffffc0200f26:	fff7871b          	addiw	a4,a5,-1
ffffffffc0200f2a:	c118                	sw	a4,0(a0)
        if (page_ref(page) == 0) {  // 如果引用计数为0，释放页面
ffffffffc0200f2c:	cb11                	beqz	a4,ffffffffc0200f40 <page_remove+0x64>
        *ptep = 0;                  // 清除PTE
ffffffffc0200f2e:	00043023          	sd	zero,0(s0)

// 刷新TLB中的某个条目
void tlb_invalidate(pde_t *pgdir, uintptr_t la) {
    // flush_tlb();
    // The flush_tlb flush the entire TLB, is there any better way?
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0200f32:	12048073          	sfence.vma	s1
}
ffffffffc0200f36:	70a2                	ld	ra,40(sp)
ffffffffc0200f38:	7402                	ld	s0,32(sp)
ffffffffc0200f3a:	64e2                	ld	s1,24(sp)
ffffffffc0200f3c:	6145                	addi	sp,sp,48
ffffffffc0200f3e:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE) { // 如果当前中断使能
ffffffffc0200f40:	100027f3          	csrr	a5,sstatus
ffffffffc0200f44:	8b89                	andi	a5,a5,2
ffffffffc0200f46:	eb89                	bnez	a5,ffffffffc0200f58 <page_remove+0x7c>
        pmm_manager->free_pages(base, n);
ffffffffc0200f48:	00015797          	auipc	a5,0x15
ffffffffc0200f4c:	6287b783          	ld	a5,1576(a5) # ffffffffc0216570 <pmm_manager>
ffffffffc0200f50:	739c                	ld	a5,32(a5)
ffffffffc0200f52:	4585                	li	a1,1
ffffffffc0200f54:	9782                	jalr	a5
    if (flag) { // 如果flag为1
ffffffffc0200f56:	bfe1                	j	ffffffffc0200f2e <page_remove+0x52>
        intr_disable(); // 禁用中断
ffffffffc0200f58:	e42a                	sd	a0,8(sp)
ffffffffc0200f5a:	e6aff0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
ffffffffc0200f5e:	00015797          	auipc	a5,0x15
ffffffffc0200f62:	6127b783          	ld	a5,1554(a5) # ffffffffc0216570 <pmm_manager>
ffffffffc0200f66:	739c                	ld	a5,32(a5)
ffffffffc0200f68:	6522                	ld	a0,8(sp)
ffffffffc0200f6a:	4585                	li	a1,1
ffffffffc0200f6c:	9782                	jalr	a5
        intr_enable(); // 使能中断
ffffffffc0200f6e:	e50ff0ef          	jal	ra,ffffffffc02005be <intr_enable>
ffffffffc0200f72:	bf75                	j	ffffffffc0200f2e <page_remove+0x52>
ffffffffc0200f74:	bffff0ef          	jal	ra,ffffffffc0200b72 <pa2page.part.0>

ffffffffc0200f78 <page_insert>:
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc0200f78:	7139                	addi	sp,sp,-64
ffffffffc0200f7a:	e852                	sd	s4,16(sp)
ffffffffc0200f7c:	8a32                	mv	s4,a2
ffffffffc0200f7e:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0200f80:	4605                	li	a2,1
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc0200f82:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0200f84:	85d2                	mv	a1,s4
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc0200f86:	f426                	sd	s1,40(sp)
ffffffffc0200f88:	fc06                	sd	ra,56(sp)
ffffffffc0200f8a:	f04a                	sd	s2,32(sp)
ffffffffc0200f8c:	ec4e                	sd	s3,24(sp)
ffffffffc0200f8e:	e456                	sd	s5,8(sp)
ffffffffc0200f90:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0200f92:	d25ff0ef          	jal	ra,ffffffffc0200cb6 <get_pte>
    if (ptep == NULL) {
ffffffffc0200f96:	c961                	beqz	a0,ffffffffc0201066 <page_insert+0xee>
    page->ref += 1;
ffffffffc0200f98:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V) {
ffffffffc0200f9a:	611c                	ld	a5,0(a0)
ffffffffc0200f9c:	89aa                	mv	s3,a0
ffffffffc0200f9e:	0016871b          	addiw	a4,a3,1
ffffffffc0200fa2:	c018                	sw	a4,0(s0)
ffffffffc0200fa4:	0017f713          	andi	a4,a5,1
ffffffffc0200fa8:	ef05                	bnez	a4,ffffffffc0200fe0 <page_insert+0x68>
    return page - pages + nbase;
ffffffffc0200faa:	00015717          	auipc	a4,0x15
ffffffffc0200fae:	5be73703          	ld	a4,1470(a4) # ffffffffc0216568 <pages>
ffffffffc0200fb2:	8c19                	sub	s0,s0,a4
ffffffffc0200fb4:	000807b7          	lui	a5,0x80
ffffffffc0200fb8:	8419                	srai	s0,s0,0x6
ffffffffc0200fba:	943e                	add	s0,s0,a5
  return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0200fbc:	042a                	slli	s0,s0,0xa
ffffffffc0200fbe:	8cc1                	or	s1,s1,s0
ffffffffc0200fc0:	0014e493          	ori	s1,s1,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm); // 设置新的PTE
ffffffffc0200fc4:	0099b023          	sd	s1,0(s3) # 80000 <kern_entry-0xffffffffc0180000>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0200fc8:	120a0073          	sfence.vma	s4
    return 0;
ffffffffc0200fcc:	4501                	li	a0,0
}
ffffffffc0200fce:	70e2                	ld	ra,56(sp)
ffffffffc0200fd0:	7442                	ld	s0,48(sp)
ffffffffc0200fd2:	74a2                	ld	s1,40(sp)
ffffffffc0200fd4:	7902                	ld	s2,32(sp)
ffffffffc0200fd6:	69e2                	ld	s3,24(sp)
ffffffffc0200fd8:	6a42                	ld	s4,16(sp)
ffffffffc0200fda:	6aa2                	ld	s5,8(sp)
ffffffffc0200fdc:	6121                	addi	sp,sp,64
ffffffffc0200fde:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0200fe0:	078a                	slli	a5,a5,0x2
ffffffffc0200fe2:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0200fe4:	00015717          	auipc	a4,0x15
ffffffffc0200fe8:	57c73703          	ld	a4,1404(a4) # ffffffffc0216560 <npage>
ffffffffc0200fec:	06e7ff63          	bgeu	a5,a4,ffffffffc020106a <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc0200ff0:	00015a97          	auipc	s5,0x15
ffffffffc0200ff4:	578a8a93          	addi	s5,s5,1400 # ffffffffc0216568 <pages>
ffffffffc0200ff8:	000ab703          	ld	a4,0(s5)
ffffffffc0200ffc:	fff80937          	lui	s2,0xfff80
ffffffffc0201000:	993e                	add	s2,s2,a5
ffffffffc0201002:	091a                	slli	s2,s2,0x6
ffffffffc0201004:	993a                	add	s2,s2,a4
        if (p == page) {
ffffffffc0201006:	01240c63          	beq	s0,s2,ffffffffc020101e <page_insert+0xa6>
    page->ref -= 1;
ffffffffc020100a:	00092783          	lw	a5,0(s2) # fffffffffff80000 <end+0x3fd69a34>
ffffffffc020100e:	fff7869b          	addiw	a3,a5,-1
ffffffffc0201012:	00d92023          	sw	a3,0(s2)
        if (page_ref(page) == 0) {  // 如果引用计数为0，释放页面
ffffffffc0201016:	c691                	beqz	a3,ffffffffc0201022 <page_insert+0xaa>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0201018:	120a0073          	sfence.vma	s4
}
ffffffffc020101c:	bf59                	j	ffffffffc0200fb2 <page_insert+0x3a>
ffffffffc020101e:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc0201020:	bf49                	j	ffffffffc0200fb2 <page_insert+0x3a>
    if (read_csr(sstatus) & SSTATUS_SIE) { // 如果当前中断使能
ffffffffc0201022:	100027f3          	csrr	a5,sstatus
ffffffffc0201026:	8b89                	andi	a5,a5,2
ffffffffc0201028:	ef91                	bnez	a5,ffffffffc0201044 <page_insert+0xcc>
        pmm_manager->free_pages(base, n);
ffffffffc020102a:	00015797          	auipc	a5,0x15
ffffffffc020102e:	5467b783          	ld	a5,1350(a5) # ffffffffc0216570 <pmm_manager>
ffffffffc0201032:	739c                	ld	a5,32(a5)
ffffffffc0201034:	4585                	li	a1,1
ffffffffc0201036:	854a                	mv	a0,s2
ffffffffc0201038:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc020103a:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020103e:	120a0073          	sfence.vma	s4
ffffffffc0201042:	bf85                	j	ffffffffc0200fb2 <page_insert+0x3a>
        intr_disable(); // 禁用中断
ffffffffc0201044:	d80ff0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201048:	00015797          	auipc	a5,0x15
ffffffffc020104c:	5287b783          	ld	a5,1320(a5) # ffffffffc0216570 <pmm_manager>
ffffffffc0201050:	739c                	ld	a5,32(a5)
ffffffffc0201052:	4585                	li	a1,1
ffffffffc0201054:	854a                	mv	a0,s2
ffffffffc0201056:	9782                	jalr	a5
        intr_enable(); // 使能中断
ffffffffc0201058:	d66ff0ef          	jal	ra,ffffffffc02005be <intr_enable>
ffffffffc020105c:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0201060:	120a0073          	sfence.vma	s4
ffffffffc0201064:	b7b9                	j	ffffffffc0200fb2 <page_insert+0x3a>
        return -E_NO_MEM;
ffffffffc0201066:	5571                	li	a0,-4
ffffffffc0201068:	b79d                	j	ffffffffc0200fce <page_insert+0x56>
ffffffffc020106a:	b09ff0ef          	jal	ra,ffffffffc0200b72 <pa2page.part.0>

ffffffffc020106e <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc020106e:	00006797          	auipc	a5,0x6
ffffffffc0201072:	b1278793          	addi	a5,a5,-1262 # ffffffffc0206b80 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201076:	638c                	ld	a1,0(a5)
void pmm_init(void) {
ffffffffc0201078:	711d                	addi	sp,sp,-96
ffffffffc020107a:	ec5e                	sd	s7,24(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020107c:	00005517          	auipc	a0,0x5
ffffffffc0201080:	8cc50513          	addi	a0,a0,-1844 # ffffffffc0205948 <commands+0x798>
    pmm_manager = &default_pmm_manager;
ffffffffc0201084:	00015b97          	auipc	s7,0x15
ffffffffc0201088:	4ecb8b93          	addi	s7,s7,1260 # ffffffffc0216570 <pmm_manager>
void pmm_init(void) {
ffffffffc020108c:	ec86                	sd	ra,88(sp)
ffffffffc020108e:	e4a6                	sd	s1,72(sp)
ffffffffc0201090:	fc4e                	sd	s3,56(sp)
ffffffffc0201092:	f05a                	sd	s6,32(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0201094:	00fbb023          	sd	a5,0(s7)
void pmm_init(void) {
ffffffffc0201098:	e8a2                	sd	s0,80(sp)
ffffffffc020109a:	e0ca                	sd	s2,64(sp)
ffffffffc020109c:	f852                	sd	s4,48(sp)
ffffffffc020109e:	f456                	sd	s5,40(sp)
ffffffffc02010a0:	e862                	sd	s8,16(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02010a2:	82aff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    pmm_manager->init();
ffffffffc02010a6:	000bb783          	ld	a5,0(s7)
    va_pa_offset = KERNBASE - 0x80200000; // 计算虚拟地址和物理地址的偏移
ffffffffc02010aa:	00015997          	auipc	s3,0x15
ffffffffc02010ae:	4ce98993          	addi	s3,s3,1230 # ffffffffc0216578 <va_pa_offset>
    npage = maxpa / PGSIZE;
ffffffffc02010b2:	00015497          	auipc	s1,0x15
ffffffffc02010b6:	4ae48493          	addi	s1,s1,1198 # ffffffffc0216560 <npage>
    pmm_manager->init();
ffffffffc02010ba:	679c                	ld	a5,8(a5)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02010bc:	00015b17          	auipc	s6,0x15
ffffffffc02010c0:	4acb0b13          	addi	s6,s6,1196 # ffffffffc0216568 <pages>
    pmm_manager->init();
ffffffffc02010c4:	9782                	jalr	a5
    va_pa_offset = KERNBASE - 0x80200000; // 计算虚拟地址和物理地址的偏移
ffffffffc02010c6:	57f5                	li	a5,-3
ffffffffc02010c8:	07fa                	slli	a5,a5,0x1e
    cprintf("physcial memory map:\n");
ffffffffc02010ca:	00005517          	auipc	a0,0x5
ffffffffc02010ce:	89650513          	addi	a0,a0,-1898 # ffffffffc0205960 <commands+0x7b0>
    va_pa_offset = KERNBASE - 0x80200000; // 计算虚拟地址和物理地址的偏移
ffffffffc02010d2:	00f9b023          	sd	a5,0(s3)
    cprintf("physcial memory map:\n");
ffffffffc02010d6:	ff7fe0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc02010da:	46c5                	li	a3,17
ffffffffc02010dc:	06ee                	slli	a3,a3,0x1b
ffffffffc02010de:	40100613          	li	a2,1025
ffffffffc02010e2:	07e005b7          	lui	a1,0x7e00
ffffffffc02010e6:	16fd                	addi	a3,a3,-1
ffffffffc02010e8:	0656                	slli	a2,a2,0x15
ffffffffc02010ea:	00005517          	auipc	a0,0x5
ffffffffc02010ee:	88e50513          	addi	a0,a0,-1906 # ffffffffc0205978 <commands+0x7c8>
ffffffffc02010f2:	fdbfe0ef          	jal	ra,ffffffffc02000cc <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02010f6:	777d                	lui	a4,0xfffff
ffffffffc02010f8:	00016797          	auipc	a5,0x16
ffffffffc02010fc:	4d378793          	addi	a5,a5,1235 # ffffffffc02175cb <end+0xfff>
ffffffffc0201100:	8ff9                	and	a5,a5,a4
    npage = maxpa / PGSIZE;
ffffffffc0201102:	00088737          	lui	a4,0x88
ffffffffc0201106:	e098                	sd	a4,0(s1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201108:	00fb3023          	sd	a5,0(s6)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020110c:	4701                	li	a4,0
 *
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void set_bit(int nr, volatile void *addr) {
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020110e:	4585                	li	a1,1
ffffffffc0201110:	fff80837          	lui	a6,0xfff80
ffffffffc0201114:	a019                	j	ffffffffc020111a <pmm_init+0xac>
        SetPageReserved(pages + i);
ffffffffc0201116:	000b3783          	ld	a5,0(s6)
ffffffffc020111a:	00671693          	slli	a3,a4,0x6
ffffffffc020111e:	97b6                	add	a5,a5,a3
ffffffffc0201120:	07a1                	addi	a5,a5,8
ffffffffc0201122:	40b7b02f          	amoor.d	zero,a1,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201126:	6090                	ld	a2,0(s1)
ffffffffc0201128:	0705                	addi	a4,a4,1
ffffffffc020112a:	010607b3          	add	a5,a2,a6
ffffffffc020112e:	fef764e3          	bltu	a4,a5,ffffffffc0201116 <pmm_init+0xa8>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201132:	000b3503          	ld	a0,0(s6)
ffffffffc0201136:	079a                	slli	a5,a5,0x6
ffffffffc0201138:	c0200737          	lui	a4,0xc0200
ffffffffc020113c:	00f506b3          	add	a3,a0,a5
ffffffffc0201140:	60e6e563          	bltu	a3,a4,ffffffffc020174a <pmm_init+0x6dc>
ffffffffc0201144:	0009b583          	ld	a1,0(s3)
    if (freemem < mem_end) {
ffffffffc0201148:	4745                	li	a4,17
ffffffffc020114a:	076e                	slli	a4,a4,0x1b
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020114c:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end) {
ffffffffc020114e:	4ae6e563          	bltu	a3,a4,ffffffffc02015f8 <pmm_init+0x58a>
    cprintf("vapaofset is %llu\n",va_pa_offset);
ffffffffc0201152:	00005517          	auipc	a0,0x5
ffffffffc0201156:	87650513          	addi	a0,a0,-1930 # ffffffffc02059c8 <commands+0x818>
ffffffffc020115a:	f73fe0ef          	jal	ra,ffffffffc02000cc <cprintf>
    return page;
}

// 检查alloc_page和free_page函数的正确性
static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc020115e:	000bb783          	ld	a5,0(s7)
    boot_pgdir = (pte_t*)boot_page_table_sv39;
ffffffffc0201162:	00015917          	auipc	s2,0x15
ffffffffc0201166:	3f690913          	addi	s2,s2,1014 # ffffffffc0216558 <boot_pgdir>
    pmm_manager->check();
ffffffffc020116a:	7b9c                	ld	a5,48(a5)
ffffffffc020116c:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc020116e:	00005517          	auipc	a0,0x5
ffffffffc0201172:	87250513          	addi	a0,a0,-1934 # ffffffffc02059e0 <commands+0x830>
ffffffffc0201176:	f57fe0ef          	jal	ra,ffffffffc02000cc <cprintf>
    boot_pgdir = (pte_t*)boot_page_table_sv39;
ffffffffc020117a:	00009697          	auipc	a3,0x9
ffffffffc020117e:	e8668693          	addi	a3,a3,-378 # ffffffffc020a000 <boot_page_table_sv39>
ffffffffc0201182:	00d93023          	sd	a3,0(s2)
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc0201186:	c02007b7          	lui	a5,0xc0200
ffffffffc020118a:	5cf6ec63          	bltu	a3,a5,ffffffffc0201762 <pmm_init+0x6f4>
ffffffffc020118e:	0009b783          	ld	a5,0(s3)
ffffffffc0201192:	8e9d                	sub	a3,a3,a5
ffffffffc0201194:	00015797          	auipc	a5,0x15
ffffffffc0201198:	3ad7be23          	sd	a3,956(a5) # ffffffffc0216550 <boot_cr3>
    if (read_csr(sstatus) & SSTATUS_SIE) { // 如果当前中断使能
ffffffffc020119c:	100027f3          	csrr	a5,sstatus
ffffffffc02011a0:	8b89                	andi	a5,a5,2
ffffffffc02011a2:	48079263          	bnez	a5,ffffffffc0201626 <pmm_init+0x5b8>
        ret = pmm_manager->nr_free_pages();
ffffffffc02011a6:	000bb783          	ld	a5,0(s7)
ffffffffc02011aa:	779c                	ld	a5,40(a5)
ffffffffc02011ac:	9782                	jalr	a5
ffffffffc02011ae:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store=nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc02011b0:	6098                	ld	a4,0(s1)
ffffffffc02011b2:	c80007b7          	lui	a5,0xc8000
ffffffffc02011b6:	83b1                	srli	a5,a5,0xc
ffffffffc02011b8:	5ee7e163          	bltu	a5,a4,ffffffffc020179a <pmm_init+0x72c>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc02011bc:	00093503          	ld	a0,0(s2)
ffffffffc02011c0:	5a050d63          	beqz	a0,ffffffffc020177a <pmm_init+0x70c>
ffffffffc02011c4:	03451793          	slli	a5,a0,0x34
ffffffffc02011c8:	5a079963          	bnez	a5,ffffffffc020177a <pmm_init+0x70c>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
ffffffffc02011cc:	4601                	li	a2,0
ffffffffc02011ce:	4581                	li	a1,0
ffffffffc02011d0:	cb9ff0ef          	jal	ra,ffffffffc0200e88 <get_page>
ffffffffc02011d4:	62051563          	bnez	a0,ffffffffc02017fe <pmm_init+0x790>

    struct Page *p1, *p2;
    p1 = alloc_page();
ffffffffc02011d8:	4505                	li	a0,1
ffffffffc02011da:	9d1ff0ef          	jal	ra,ffffffffc0200baa <alloc_pages>
ffffffffc02011de:	8a2a                	mv	s4,a0
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc02011e0:	00093503          	ld	a0,0(s2)
ffffffffc02011e4:	4681                	li	a3,0
ffffffffc02011e6:	4601                	li	a2,0
ffffffffc02011e8:	85d2                	mv	a1,s4
ffffffffc02011ea:	d8fff0ef          	jal	ra,ffffffffc0200f78 <page_insert>
ffffffffc02011ee:	5e051863          	bnez	a0,ffffffffc02017de <pmm_init+0x770>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
ffffffffc02011f2:	00093503          	ld	a0,0(s2)
ffffffffc02011f6:	4601                	li	a2,0
ffffffffc02011f8:	4581                	li	a1,0
ffffffffc02011fa:	abdff0ef          	jal	ra,ffffffffc0200cb6 <get_pte>
ffffffffc02011fe:	5c050063          	beqz	a0,ffffffffc02017be <pmm_init+0x750>
    assert(pte2page(*ptep) == p1);
ffffffffc0201202:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc0201204:	0017f713          	andi	a4,a5,1
ffffffffc0201208:	5a070963          	beqz	a4,ffffffffc02017ba <pmm_init+0x74c>
    if (PPN(pa) >= npage) {
ffffffffc020120c:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc020120e:	078a                	slli	a5,a5,0x2
ffffffffc0201210:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201212:	52e7fa63          	bgeu	a5,a4,ffffffffc0201746 <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc0201216:	000b3683          	ld	a3,0(s6)
ffffffffc020121a:	fff80637          	lui	a2,0xfff80
ffffffffc020121e:	97b2                	add	a5,a5,a2
ffffffffc0201220:	079a                	slli	a5,a5,0x6
ffffffffc0201222:	97b6                	add	a5,a5,a3
ffffffffc0201224:	10fa16e3          	bne	s4,a5,ffffffffc0201b30 <pmm_init+0xac2>
    assert(page_ref(p1) == 1);
ffffffffc0201228:	000a2683          	lw	a3,0(s4)
ffffffffc020122c:	4785                	li	a5,1
ffffffffc020122e:	12f69de3          	bne	a3,a5,ffffffffc0201b68 <pmm_init+0xafa>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc0201232:	00093503          	ld	a0,0(s2)
ffffffffc0201236:	77fd                	lui	a5,0xfffff
ffffffffc0201238:	6114                	ld	a3,0(a0)
ffffffffc020123a:	068a                	slli	a3,a3,0x2
ffffffffc020123c:	8efd                	and	a3,a3,a5
ffffffffc020123e:	00c6d613          	srli	a2,a3,0xc
ffffffffc0201242:	10e677e3          	bgeu	a2,a4,ffffffffc0201b50 <pmm_init+0xae2>
ffffffffc0201246:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020124a:	96e2                	add	a3,a3,s8
ffffffffc020124c:	0006ba83          	ld	s5,0(a3)
ffffffffc0201250:	0a8a                	slli	s5,s5,0x2
ffffffffc0201252:	00fafab3          	and	s5,s5,a5
ffffffffc0201256:	00cad793          	srli	a5,s5,0xc
ffffffffc020125a:	62e7f263          	bgeu	a5,a4,ffffffffc020187e <pmm_init+0x810>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc020125e:	4601                	li	a2,0
ffffffffc0201260:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0201262:	9ae2                	add	s5,s5,s8
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0201264:	a53ff0ef          	jal	ra,ffffffffc0200cb6 <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0201268:	0aa1                	addi	s5,s5,8
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc020126a:	5f551a63          	bne	a0,s5,ffffffffc020185e <pmm_init+0x7f0>

    p2 = alloc_page();
ffffffffc020126e:	4505                	li	a0,1
ffffffffc0201270:	93bff0ef          	jal	ra,ffffffffc0200baa <alloc_pages>
ffffffffc0201274:	8aaa                	mv	s5,a0
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0201276:	00093503          	ld	a0,0(s2)
ffffffffc020127a:	46d1                	li	a3,20
ffffffffc020127c:	6605                	lui	a2,0x1
ffffffffc020127e:	85d6                	mv	a1,s5
ffffffffc0201280:	cf9ff0ef          	jal	ra,ffffffffc0200f78 <page_insert>
ffffffffc0201284:	58051d63          	bnez	a0,ffffffffc020181e <pmm_init+0x7b0>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0201288:	00093503          	ld	a0,0(s2)
ffffffffc020128c:	4601                	li	a2,0
ffffffffc020128e:	6585                	lui	a1,0x1
ffffffffc0201290:	a27ff0ef          	jal	ra,ffffffffc0200cb6 <get_pte>
ffffffffc0201294:	0e050ae3          	beqz	a0,ffffffffc0201b88 <pmm_init+0xb1a>
    assert(*ptep & PTE_U);
ffffffffc0201298:	611c                	ld	a5,0(a0)
ffffffffc020129a:	0107f713          	andi	a4,a5,16
ffffffffc020129e:	6e070d63          	beqz	a4,ffffffffc0201998 <pmm_init+0x92a>
    assert(*ptep & PTE_W);
ffffffffc02012a2:	8b91                	andi	a5,a5,4
ffffffffc02012a4:	6a078a63          	beqz	a5,ffffffffc0201958 <pmm_init+0x8ea>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc02012a8:	00093503          	ld	a0,0(s2)
ffffffffc02012ac:	611c                	ld	a5,0(a0)
ffffffffc02012ae:	8bc1                	andi	a5,a5,16
ffffffffc02012b0:	68078463          	beqz	a5,ffffffffc0201938 <pmm_init+0x8ca>
    assert(page_ref(p2) == 1);
ffffffffc02012b4:	000aa703          	lw	a4,0(s5)
ffffffffc02012b8:	4785                	li	a5,1
ffffffffc02012ba:	58f71263          	bne	a4,a5,ffffffffc020183e <pmm_init+0x7d0>

    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc02012be:	4681                	li	a3,0
ffffffffc02012c0:	6605                	lui	a2,0x1
ffffffffc02012c2:	85d2                	mv	a1,s4
ffffffffc02012c4:	cb5ff0ef          	jal	ra,ffffffffc0200f78 <page_insert>
ffffffffc02012c8:	62051863          	bnez	a0,ffffffffc02018f8 <pmm_init+0x88a>
    assert(page_ref(p1) == 2);
ffffffffc02012cc:	000a2703          	lw	a4,0(s4)
ffffffffc02012d0:	4789                	li	a5,2
ffffffffc02012d2:	60f71363          	bne	a4,a5,ffffffffc02018d8 <pmm_init+0x86a>
    assert(page_ref(p2) == 0);
ffffffffc02012d6:	000aa783          	lw	a5,0(s5)
ffffffffc02012da:	5c079f63          	bnez	a5,ffffffffc02018b8 <pmm_init+0x84a>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc02012de:	00093503          	ld	a0,0(s2)
ffffffffc02012e2:	4601                	li	a2,0
ffffffffc02012e4:	6585                	lui	a1,0x1
ffffffffc02012e6:	9d1ff0ef          	jal	ra,ffffffffc0200cb6 <get_pte>
ffffffffc02012ea:	5a050763          	beqz	a0,ffffffffc0201898 <pmm_init+0x82a>
    assert(pte2page(*ptep) == p1);
ffffffffc02012ee:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc02012f0:	00177793          	andi	a5,a4,1
ffffffffc02012f4:	4c078363          	beqz	a5,ffffffffc02017ba <pmm_init+0x74c>
    if (PPN(pa) >= npage) {
ffffffffc02012f8:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc02012fa:	00271793          	slli	a5,a4,0x2
ffffffffc02012fe:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201300:	44d7f363          	bgeu	a5,a3,ffffffffc0201746 <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc0201304:	000b3683          	ld	a3,0(s6)
ffffffffc0201308:	fff80637          	lui	a2,0xfff80
ffffffffc020130c:	97b2                	add	a5,a5,a2
ffffffffc020130e:	079a                	slli	a5,a5,0x6
ffffffffc0201310:	97b6                	add	a5,a5,a3
ffffffffc0201312:	6efa1363          	bne	s4,a5,ffffffffc02019f8 <pmm_init+0x98a>
    assert((*ptep & PTE_U) == 0);
ffffffffc0201316:	8b41                	andi	a4,a4,16
ffffffffc0201318:	6c071063          	bnez	a4,ffffffffc02019d8 <pmm_init+0x96a>

    page_remove(boot_pgdir, 0x0);
ffffffffc020131c:	00093503          	ld	a0,0(s2)
ffffffffc0201320:	4581                	li	a1,0
ffffffffc0201322:	bbbff0ef          	jal	ra,ffffffffc0200edc <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0201326:	000a2703          	lw	a4,0(s4)
ffffffffc020132a:	4785                	li	a5,1
ffffffffc020132c:	68f71663          	bne	a4,a5,ffffffffc02019b8 <pmm_init+0x94a>
    assert(page_ref(p2) == 0);
ffffffffc0201330:	000aa783          	lw	a5,0(s5)
ffffffffc0201334:	74079e63          	bnez	a5,ffffffffc0201a90 <pmm_init+0xa22>

    page_remove(boot_pgdir, PGSIZE);
ffffffffc0201338:	00093503          	ld	a0,0(s2)
ffffffffc020133c:	6585                	lui	a1,0x1
ffffffffc020133e:	b9fff0ef          	jal	ra,ffffffffc0200edc <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0201342:	000a2783          	lw	a5,0(s4)
ffffffffc0201346:	72079563          	bnez	a5,ffffffffc0201a70 <pmm_init+0xa02>
    assert(page_ref(p2) == 0);
ffffffffc020134a:	000aa783          	lw	a5,0(s5)
ffffffffc020134e:	70079163          	bnez	a5,ffffffffc0201a50 <pmm_init+0x9e2>

    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
ffffffffc0201352:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage) {
ffffffffc0201356:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201358:	000a3683          	ld	a3,0(s4)
ffffffffc020135c:	068a                	slli	a3,a3,0x2
ffffffffc020135e:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201360:	3ee6f363          	bgeu	a3,a4,ffffffffc0201746 <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc0201364:	fff807b7          	lui	a5,0xfff80
ffffffffc0201368:	000b3503          	ld	a0,0(s6)
ffffffffc020136c:	96be                	add	a3,a3,a5
ffffffffc020136e:	069a                	slli	a3,a3,0x6
    return page->ref;
ffffffffc0201370:	00d507b3          	add	a5,a0,a3
ffffffffc0201374:	4390                	lw	a2,0(a5)
ffffffffc0201376:	4785                	li	a5,1
ffffffffc0201378:	6af61c63          	bne	a2,a5,ffffffffc0201a30 <pmm_init+0x9c2>
    return page - pages + nbase;
ffffffffc020137c:	8699                	srai	a3,a3,0x6
ffffffffc020137e:	000805b7          	lui	a1,0x80
ffffffffc0201382:	96ae                	add	a3,a3,a1
    return KADDR(page2pa(page));
ffffffffc0201384:	00c69613          	slli	a2,a3,0xc
ffffffffc0201388:	8231                	srli	a2,a2,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc020138a:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020138c:	68e67663          	bgeu	a2,a4,ffffffffc0201a18 <pmm_init+0x9aa>

    pde_t *pd1=boot_pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
    free_page(pde2page(pd0[0]));
ffffffffc0201390:	0009b603          	ld	a2,0(s3)
ffffffffc0201394:	96b2                	add	a3,a3,a2
    return pa2page(PDE_ADDR(pde));
ffffffffc0201396:	629c                	ld	a5,0(a3)
ffffffffc0201398:	078a                	slli	a5,a5,0x2
ffffffffc020139a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020139c:	3ae7f563          	bgeu	a5,a4,ffffffffc0201746 <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc02013a0:	8f8d                	sub	a5,a5,a1
ffffffffc02013a2:	079a                	slli	a5,a5,0x6
ffffffffc02013a4:	953e                	add	a0,a0,a5
ffffffffc02013a6:	100027f3          	csrr	a5,sstatus
ffffffffc02013aa:	8b89                	andi	a5,a5,2
ffffffffc02013ac:	2c079763          	bnez	a5,ffffffffc020167a <pmm_init+0x60c>
        pmm_manager->free_pages(base, n);
ffffffffc02013b0:	000bb783          	ld	a5,0(s7)
ffffffffc02013b4:	4585                	li	a1,1
ffffffffc02013b6:	739c                	ld	a5,32(a5)
ffffffffc02013b8:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc02013ba:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage) {
ffffffffc02013be:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02013c0:	078a                	slli	a5,a5,0x2
ffffffffc02013c2:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02013c4:	38e7f163          	bgeu	a5,a4,ffffffffc0201746 <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc02013c8:	000b3503          	ld	a0,0(s6)
ffffffffc02013cc:	fff80737          	lui	a4,0xfff80
ffffffffc02013d0:	97ba                	add	a5,a5,a4
ffffffffc02013d2:	079a                	slli	a5,a5,0x6
ffffffffc02013d4:	953e                	add	a0,a0,a5
ffffffffc02013d6:	100027f3          	csrr	a5,sstatus
ffffffffc02013da:	8b89                	andi	a5,a5,2
ffffffffc02013dc:	28079363          	bnez	a5,ffffffffc0201662 <pmm_init+0x5f4>
ffffffffc02013e0:	000bb783          	ld	a5,0(s7)
ffffffffc02013e4:	4585                	li	a1,1
ffffffffc02013e6:	739c                	ld	a5,32(a5)
ffffffffc02013e8:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir[0] = 0;
ffffffffc02013ea:	00093783          	ld	a5,0(s2)
ffffffffc02013ee:	0007b023          	sd	zero,0(a5) # fffffffffff80000 <end+0x3fd69a34>
  asm volatile("sfence.vma");
ffffffffc02013f2:	12000073          	sfence.vma
ffffffffc02013f6:	100027f3          	csrr	a5,sstatus
ffffffffc02013fa:	8b89                	andi	a5,a5,2
ffffffffc02013fc:	24079963          	bnez	a5,ffffffffc020164e <pmm_init+0x5e0>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201400:	000bb783          	ld	a5,0(s7)
ffffffffc0201404:	779c                	ld	a5,40(a5)
ffffffffc0201406:	9782                	jalr	a5
ffffffffc0201408:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store==nr_free_pages());
ffffffffc020140a:	71441363          	bne	s0,s4,ffffffffc0201b10 <pmm_init+0xaa2>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc020140e:	00005517          	auipc	a0,0x5
ffffffffc0201412:	8d250513          	addi	a0,a0,-1838 # ffffffffc0205ce0 <commands+0xb30>
ffffffffc0201416:	cb7fe0ef          	jal	ra,ffffffffc02000cc <cprintf>
ffffffffc020141a:	100027f3          	csrr	a5,sstatus
ffffffffc020141e:	8b89                	andi	a5,a5,2
ffffffffc0201420:	20079d63          	bnez	a5,ffffffffc020163a <pmm_init+0x5cc>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201424:	000bb783          	ld	a5,0(s7)
ffffffffc0201428:	779c                	ld	a5,40(a5)
ffffffffc020142a:	9782                	jalr	a5
ffffffffc020142c:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store=nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc020142e:	6098                	ld	a4,0(s1)
ffffffffc0201430:	c0200437          	lui	s0,0xc0200
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0201434:	7afd                	lui	s5,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc0201436:	00c71793          	slli	a5,a4,0xc
ffffffffc020143a:	6a05                	lui	s4,0x1
ffffffffc020143c:	02f47c63          	bgeu	s0,a5,ffffffffc0201474 <pmm_init+0x406>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0201440:	00c45793          	srli	a5,s0,0xc
ffffffffc0201444:	00093503          	ld	a0,0(s2)
ffffffffc0201448:	2ee7f263          	bgeu	a5,a4,ffffffffc020172c <pmm_init+0x6be>
ffffffffc020144c:	0009b583          	ld	a1,0(s3)
ffffffffc0201450:	4601                	li	a2,0
ffffffffc0201452:	95a2                	add	a1,a1,s0
ffffffffc0201454:	863ff0ef          	jal	ra,ffffffffc0200cb6 <get_pte>
ffffffffc0201458:	2a050a63          	beqz	a0,ffffffffc020170c <pmm_init+0x69e>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc020145c:	611c                	ld	a5,0(a0)
ffffffffc020145e:	078a                	slli	a5,a5,0x2
ffffffffc0201460:	0157f7b3          	and	a5,a5,s5
ffffffffc0201464:	28879463          	bne	a5,s0,ffffffffc02016ec <pmm_init+0x67e>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc0201468:	6098                	ld	a4,0(s1)
ffffffffc020146a:	9452                	add	s0,s0,s4
ffffffffc020146c:	00c71793          	slli	a5,a4,0xc
ffffffffc0201470:	fcf468e3          	bltu	s0,a5,ffffffffc0201440 <pmm_init+0x3d2>
    }

    assert(boot_pgdir[0] == 0);
ffffffffc0201474:	00093783          	ld	a5,0(s2)
ffffffffc0201478:	639c                	ld	a5,0(a5)
ffffffffc020147a:	66079b63          	bnez	a5,ffffffffc0201af0 <pmm_init+0xa82>

    struct Page *p;
    p = alloc_page();
ffffffffc020147e:	4505                	li	a0,1
ffffffffc0201480:	f2aff0ef          	jal	ra,ffffffffc0200baa <alloc_pages>
ffffffffc0201484:	8aaa                	mv	s5,a0
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0201486:	00093503          	ld	a0,0(s2)
ffffffffc020148a:	4699                	li	a3,6
ffffffffc020148c:	10000613          	li	a2,256
ffffffffc0201490:	85d6                	mv	a1,s5
ffffffffc0201492:	ae7ff0ef          	jal	ra,ffffffffc0200f78 <page_insert>
ffffffffc0201496:	62051d63          	bnez	a0,ffffffffc0201ad0 <pmm_init+0xa62>
    assert(page_ref(p) == 1);
ffffffffc020149a:	000aa703          	lw	a4,0(s5) # fffffffffffff000 <end+0x3fde8a34>
ffffffffc020149e:	4785                	li	a5,1
ffffffffc02014a0:	60f71863          	bne	a4,a5,ffffffffc0201ab0 <pmm_init+0xa42>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc02014a4:	00093503          	ld	a0,0(s2)
ffffffffc02014a8:	6405                	lui	s0,0x1
ffffffffc02014aa:	4699                	li	a3,6
ffffffffc02014ac:	10040613          	addi	a2,s0,256 # 1100 <kern_entry-0xffffffffc01fef00>
ffffffffc02014b0:	85d6                	mv	a1,s5
ffffffffc02014b2:	ac7ff0ef          	jal	ra,ffffffffc0200f78 <page_insert>
ffffffffc02014b6:	46051163          	bnez	a0,ffffffffc0201918 <pmm_init+0x8aa>
    assert(page_ref(p) == 2);
ffffffffc02014ba:	000aa703          	lw	a4,0(s5)
ffffffffc02014be:	4789                	li	a5,2
ffffffffc02014c0:	72f71463          	bne	a4,a5,ffffffffc0201be8 <pmm_init+0xb7a>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc02014c4:	00005597          	auipc	a1,0x5
ffffffffc02014c8:	95458593          	addi	a1,a1,-1708 # ffffffffc0205e18 <commands+0xc68>
ffffffffc02014cc:	10000513          	li	a0,256
ffffffffc02014d0:	5ba030ef          	jal	ra,ffffffffc0204a8a <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc02014d4:	10040593          	addi	a1,s0,256
ffffffffc02014d8:	10000513          	li	a0,256
ffffffffc02014dc:	5c0030ef          	jal	ra,ffffffffc0204a9c <strcmp>
ffffffffc02014e0:	6e051463          	bnez	a0,ffffffffc0201bc8 <pmm_init+0xb5a>
    return page - pages + nbase;
ffffffffc02014e4:	000b3683          	ld	a3,0(s6)
ffffffffc02014e8:	00080737          	lui	a4,0x80
    return KADDR(page2pa(page));
ffffffffc02014ec:	547d                	li	s0,-1
    return page - pages + nbase;
ffffffffc02014ee:	40da86b3          	sub	a3,s5,a3
ffffffffc02014f2:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc02014f4:	609c                	ld	a5,0(s1)
    return page - pages + nbase;
ffffffffc02014f6:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc02014f8:	8031                	srli	s0,s0,0xc
ffffffffc02014fa:	0086f733          	and	a4,a3,s0
    return page2ppn(page) << PGSHIFT;
ffffffffc02014fe:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0201500:	50f77c63          	bgeu	a4,a5,ffffffffc0201a18 <pmm_init+0x9aa>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0201504:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0201508:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc020150c:	96be                	add	a3,a3,a5
ffffffffc020150e:	10068023          	sb	zero,256(a3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0201512:	542030ef          	jal	ra,ffffffffc0204a54 <strlen>
ffffffffc0201516:	68051963          	bnez	a0,ffffffffc0201ba8 <pmm_init+0xb3a>

    pde_t *pd1=boot_pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
ffffffffc020151a:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage) {
ffffffffc020151e:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201520:	000a3683          	ld	a3,0(s4) # 1000 <kern_entry-0xffffffffc01ff000>
ffffffffc0201524:	068a                	slli	a3,a3,0x2
ffffffffc0201526:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201528:	20f6ff63          	bgeu	a3,a5,ffffffffc0201746 <pmm_init+0x6d8>
    return KADDR(page2pa(page));
ffffffffc020152c:	8c75                	and	s0,s0,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc020152e:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0201530:	4ef47463          	bgeu	s0,a5,ffffffffc0201a18 <pmm_init+0x9aa>
ffffffffc0201534:	0009b403          	ld	s0,0(s3)
ffffffffc0201538:	9436                	add	s0,s0,a3
ffffffffc020153a:	100027f3          	csrr	a5,sstatus
ffffffffc020153e:	8b89                	andi	a5,a5,2
ffffffffc0201540:	18079b63          	bnez	a5,ffffffffc02016d6 <pmm_init+0x668>
        pmm_manager->free_pages(base, n);
ffffffffc0201544:	000bb783          	ld	a5,0(s7)
ffffffffc0201548:	4585                	li	a1,1
ffffffffc020154a:	8556                	mv	a0,s5
ffffffffc020154c:	739c                	ld	a5,32(a5)
ffffffffc020154e:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0201550:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage) {
ffffffffc0201552:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201554:	078a                	slli	a5,a5,0x2
ffffffffc0201556:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201558:	1ee7f763          	bgeu	a5,a4,ffffffffc0201746 <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc020155c:	000b3503          	ld	a0,0(s6)
ffffffffc0201560:	fff80737          	lui	a4,0xfff80
ffffffffc0201564:	97ba                	add	a5,a5,a4
ffffffffc0201566:	079a                	slli	a5,a5,0x6
ffffffffc0201568:	953e                	add	a0,a0,a5
ffffffffc020156a:	100027f3          	csrr	a5,sstatus
ffffffffc020156e:	8b89                	andi	a5,a5,2
ffffffffc0201570:	14079763          	bnez	a5,ffffffffc02016be <pmm_init+0x650>
ffffffffc0201574:	000bb783          	ld	a5,0(s7)
ffffffffc0201578:	4585                	li	a1,1
ffffffffc020157a:	739c                	ld	a5,32(a5)
ffffffffc020157c:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc020157e:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage) {
ffffffffc0201582:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201584:	078a                	slli	a5,a5,0x2
ffffffffc0201586:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201588:	1ae7ff63          	bgeu	a5,a4,ffffffffc0201746 <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc020158c:	000b3503          	ld	a0,0(s6)
ffffffffc0201590:	fff80737          	lui	a4,0xfff80
ffffffffc0201594:	97ba                	add	a5,a5,a4
ffffffffc0201596:	079a                	slli	a5,a5,0x6
ffffffffc0201598:	953e                	add	a0,a0,a5
ffffffffc020159a:	100027f3          	csrr	a5,sstatus
ffffffffc020159e:	8b89                	andi	a5,a5,2
ffffffffc02015a0:	10079363          	bnez	a5,ffffffffc02016a6 <pmm_init+0x638>
ffffffffc02015a4:	000bb783          	ld	a5,0(s7)
ffffffffc02015a8:	4585                	li	a1,1
ffffffffc02015aa:	739c                	ld	a5,32(a5)
ffffffffc02015ac:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir[0] = 0;
ffffffffc02015ae:	00093783          	ld	a5,0(s2)
ffffffffc02015b2:	0007b023          	sd	zero,0(a5)
  asm volatile("sfence.vma");
ffffffffc02015b6:	12000073          	sfence.vma
ffffffffc02015ba:	100027f3          	csrr	a5,sstatus
ffffffffc02015be:	8b89                	andi	a5,a5,2
ffffffffc02015c0:	0c079963          	bnez	a5,ffffffffc0201692 <pmm_init+0x624>
        ret = pmm_manager->nr_free_pages();
ffffffffc02015c4:	000bb783          	ld	a5,0(s7)
ffffffffc02015c8:	779c                	ld	a5,40(a5)
ffffffffc02015ca:	9782                	jalr	a5
ffffffffc02015cc:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store==nr_free_pages());
ffffffffc02015ce:	3a8c1563          	bne	s8,s0,ffffffffc0201978 <pmm_init+0x90a>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc02015d2:	00005517          	auipc	a0,0x5
ffffffffc02015d6:	8be50513          	addi	a0,a0,-1858 # ffffffffc0205e90 <commands+0xce0>
ffffffffc02015da:	af3fe0ef          	jal	ra,ffffffffc02000cc <cprintf>
}
ffffffffc02015de:	6446                	ld	s0,80(sp)
ffffffffc02015e0:	60e6                	ld	ra,88(sp)
ffffffffc02015e2:	64a6                	ld	s1,72(sp)
ffffffffc02015e4:	6906                	ld	s2,64(sp)
ffffffffc02015e6:	79e2                	ld	s3,56(sp)
ffffffffc02015e8:	7a42                	ld	s4,48(sp)
ffffffffc02015ea:	7aa2                	ld	s5,40(sp)
ffffffffc02015ec:	7b02                	ld	s6,32(sp)
ffffffffc02015ee:	6be2                	ld	s7,24(sp)
ffffffffc02015f0:	6c42                	ld	s8,16(sp)
ffffffffc02015f2:	6125                	addi	sp,sp,96
    kmalloc_init();
ffffffffc02015f4:	2690106f          	j	ffffffffc020305c <kmalloc_init>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc02015f8:	6785                	lui	a5,0x1
ffffffffc02015fa:	17fd                	addi	a5,a5,-1
ffffffffc02015fc:	96be                	add	a3,a3,a5
ffffffffc02015fe:	77fd                	lui	a5,0xfffff
ffffffffc0201600:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage) {
ffffffffc0201602:	00c7d693          	srli	a3,a5,0xc
ffffffffc0201606:	14c6f063          	bgeu	a3,a2,ffffffffc0201746 <pmm_init+0x6d8>
    pmm_manager->init_memmap(base, n);
ffffffffc020160a:	000bb603          	ld	a2,0(s7)
    return &pages[PPN(pa) - nbase];
ffffffffc020160e:	96c2                	add	a3,a3,a6
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0201610:	40f707b3          	sub	a5,a4,a5
    pmm_manager->init_memmap(base, n);
ffffffffc0201614:	6a10                	ld	a2,16(a2)
ffffffffc0201616:	069a                	slli	a3,a3,0x6
ffffffffc0201618:	00c7d593          	srli	a1,a5,0xc
ffffffffc020161c:	9536                	add	a0,a0,a3
ffffffffc020161e:	9602                	jalr	a2
    cprintf("vapaofset is %llu\n",va_pa_offset);
ffffffffc0201620:	0009b583          	ld	a1,0(s3)
}
ffffffffc0201624:	b63d                	j	ffffffffc0201152 <pmm_init+0xe4>
        intr_disable(); // 禁用中断
ffffffffc0201626:	f9ffe0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc020162a:	000bb783          	ld	a5,0(s7)
ffffffffc020162e:	779c                	ld	a5,40(a5)
ffffffffc0201630:	9782                	jalr	a5
ffffffffc0201632:	842a                	mv	s0,a0
        intr_enable(); // 使能中断
ffffffffc0201634:	f8bfe0ef          	jal	ra,ffffffffc02005be <intr_enable>
ffffffffc0201638:	bea5                	j	ffffffffc02011b0 <pmm_init+0x142>
        intr_disable(); // 禁用中断
ffffffffc020163a:	f8bfe0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
ffffffffc020163e:	000bb783          	ld	a5,0(s7)
ffffffffc0201642:	779c                	ld	a5,40(a5)
ffffffffc0201644:	9782                	jalr	a5
ffffffffc0201646:	8c2a                	mv	s8,a0
        intr_enable(); // 使能中断
ffffffffc0201648:	f77fe0ef          	jal	ra,ffffffffc02005be <intr_enable>
ffffffffc020164c:	b3cd                	j	ffffffffc020142e <pmm_init+0x3c0>
        intr_disable(); // 禁用中断
ffffffffc020164e:	f77fe0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
ffffffffc0201652:	000bb783          	ld	a5,0(s7)
ffffffffc0201656:	779c                	ld	a5,40(a5)
ffffffffc0201658:	9782                	jalr	a5
ffffffffc020165a:	8a2a                	mv	s4,a0
        intr_enable(); // 使能中断
ffffffffc020165c:	f63fe0ef          	jal	ra,ffffffffc02005be <intr_enable>
ffffffffc0201660:	b36d                	j	ffffffffc020140a <pmm_init+0x39c>
ffffffffc0201662:	e42a                	sd	a0,8(sp)
        intr_disable(); // 禁用中断
ffffffffc0201664:	f61fe0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201668:	000bb783          	ld	a5,0(s7)
ffffffffc020166c:	6522                	ld	a0,8(sp)
ffffffffc020166e:	4585                	li	a1,1
ffffffffc0201670:	739c                	ld	a5,32(a5)
ffffffffc0201672:	9782                	jalr	a5
        intr_enable(); // 使能中断
ffffffffc0201674:	f4bfe0ef          	jal	ra,ffffffffc02005be <intr_enable>
ffffffffc0201678:	bb8d                	j	ffffffffc02013ea <pmm_init+0x37c>
ffffffffc020167a:	e42a                	sd	a0,8(sp)
        intr_disable(); // 禁用中断
ffffffffc020167c:	f49fe0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
ffffffffc0201680:	000bb783          	ld	a5,0(s7)
ffffffffc0201684:	6522                	ld	a0,8(sp)
ffffffffc0201686:	4585                	li	a1,1
ffffffffc0201688:	739c                	ld	a5,32(a5)
ffffffffc020168a:	9782                	jalr	a5
        intr_enable(); // 使能中断
ffffffffc020168c:	f33fe0ef          	jal	ra,ffffffffc02005be <intr_enable>
ffffffffc0201690:	b32d                	j	ffffffffc02013ba <pmm_init+0x34c>
        intr_disable(); // 禁用中断
ffffffffc0201692:	f33fe0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201696:	000bb783          	ld	a5,0(s7)
ffffffffc020169a:	779c                	ld	a5,40(a5)
ffffffffc020169c:	9782                	jalr	a5
ffffffffc020169e:	842a                	mv	s0,a0
        intr_enable(); // 使能中断
ffffffffc02016a0:	f1ffe0ef          	jal	ra,ffffffffc02005be <intr_enable>
ffffffffc02016a4:	b72d                	j	ffffffffc02015ce <pmm_init+0x560>
ffffffffc02016a6:	e42a                	sd	a0,8(sp)
        intr_disable(); // 禁用中断
ffffffffc02016a8:	f1dfe0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02016ac:	000bb783          	ld	a5,0(s7)
ffffffffc02016b0:	6522                	ld	a0,8(sp)
ffffffffc02016b2:	4585                	li	a1,1
ffffffffc02016b4:	739c                	ld	a5,32(a5)
ffffffffc02016b6:	9782                	jalr	a5
        intr_enable(); // 使能中断
ffffffffc02016b8:	f07fe0ef          	jal	ra,ffffffffc02005be <intr_enable>
ffffffffc02016bc:	bdcd                	j	ffffffffc02015ae <pmm_init+0x540>
ffffffffc02016be:	e42a                	sd	a0,8(sp)
        intr_disable(); // 禁用中断
ffffffffc02016c0:	f05fe0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
ffffffffc02016c4:	000bb783          	ld	a5,0(s7)
ffffffffc02016c8:	6522                	ld	a0,8(sp)
ffffffffc02016ca:	4585                	li	a1,1
ffffffffc02016cc:	739c                	ld	a5,32(a5)
ffffffffc02016ce:	9782                	jalr	a5
        intr_enable(); // 使能中断
ffffffffc02016d0:	eeffe0ef          	jal	ra,ffffffffc02005be <intr_enable>
ffffffffc02016d4:	b56d                	j	ffffffffc020157e <pmm_init+0x510>
        intr_disable(); // 禁用中断
ffffffffc02016d6:	eeffe0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
ffffffffc02016da:	000bb783          	ld	a5,0(s7)
ffffffffc02016de:	4585                	li	a1,1
ffffffffc02016e0:	8556                	mv	a0,s5
ffffffffc02016e2:	739c                	ld	a5,32(a5)
ffffffffc02016e4:	9782                	jalr	a5
        intr_enable(); // 使能中断
ffffffffc02016e6:	ed9fe0ef          	jal	ra,ffffffffc02005be <intr_enable>
ffffffffc02016ea:	b59d                	j	ffffffffc0201550 <pmm_init+0x4e2>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc02016ec:	00004697          	auipc	a3,0x4
ffffffffc02016f0:	65468693          	addi	a3,a3,1620 # ffffffffc0205d40 <commands+0xb90>
ffffffffc02016f4:	00004617          	auipc	a2,0x4
ffffffffc02016f8:	32c60613          	addi	a2,a2,812 # ffffffffc0205a20 <commands+0x870>
ffffffffc02016fc:	17800593          	li	a1,376
ffffffffc0201700:	00004517          	auipc	a0,0x4
ffffffffc0201704:	23850513          	addi	a0,a0,568 # ffffffffc0205938 <commands+0x788>
ffffffffc0201708:	ac1fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc020170c:	00004697          	auipc	a3,0x4
ffffffffc0201710:	5f468693          	addi	a3,a3,1524 # ffffffffc0205d00 <commands+0xb50>
ffffffffc0201714:	00004617          	auipc	a2,0x4
ffffffffc0201718:	30c60613          	addi	a2,a2,780 # ffffffffc0205a20 <commands+0x870>
ffffffffc020171c:	17700593          	li	a1,375
ffffffffc0201720:	00004517          	auipc	a0,0x4
ffffffffc0201724:	21850513          	addi	a0,a0,536 # ffffffffc0205938 <commands+0x788>
ffffffffc0201728:	aa1fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
ffffffffc020172c:	86a2                	mv	a3,s0
ffffffffc020172e:	00004617          	auipc	a2,0x4
ffffffffc0201732:	1e260613          	addi	a2,a2,482 # ffffffffc0205910 <commands+0x760>
ffffffffc0201736:	17700593          	li	a1,375
ffffffffc020173a:	00004517          	auipc	a0,0x4
ffffffffc020173e:	1fe50513          	addi	a0,a0,510 # ffffffffc0205938 <commands+0x788>
ffffffffc0201742:	a87fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
ffffffffc0201746:	c2cff0ef          	jal	ra,ffffffffc0200b72 <pa2page.part.0>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020174a:	00004617          	auipc	a2,0x4
ffffffffc020174e:	25660613          	addi	a2,a2,598 # ffffffffc02059a0 <commands+0x7f0>
ffffffffc0201752:	07d00593          	li	a1,125
ffffffffc0201756:	00004517          	auipc	a0,0x4
ffffffffc020175a:	1e250513          	addi	a0,a0,482 # ffffffffc0205938 <commands+0x788>
ffffffffc020175e:	a6bfe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc0201762:	00004617          	auipc	a2,0x4
ffffffffc0201766:	23e60613          	addi	a2,a2,574 # ffffffffc02059a0 <commands+0x7f0>
ffffffffc020176a:	0b100593          	li	a1,177
ffffffffc020176e:	00004517          	auipc	a0,0x4
ffffffffc0201772:	1ca50513          	addi	a0,a0,458 # ffffffffc0205938 <commands+0x788>
ffffffffc0201776:	a53fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc020177a:	00004697          	auipc	a3,0x4
ffffffffc020177e:	2be68693          	addi	a3,a3,702 # ffffffffc0205a38 <commands+0x888>
ffffffffc0201782:	00004617          	auipc	a2,0x4
ffffffffc0201786:	29e60613          	addi	a2,a2,670 # ffffffffc0205a20 <commands+0x870>
ffffffffc020178a:	13a00593          	li	a1,314
ffffffffc020178e:	00004517          	auipc	a0,0x4
ffffffffc0201792:	1aa50513          	addi	a0,a0,426 # ffffffffc0205938 <commands+0x788>
ffffffffc0201796:	a33fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc020179a:	00004697          	auipc	a3,0x4
ffffffffc020179e:	26668693          	addi	a3,a3,614 # ffffffffc0205a00 <commands+0x850>
ffffffffc02017a2:	00004617          	auipc	a2,0x4
ffffffffc02017a6:	27e60613          	addi	a2,a2,638 # ffffffffc0205a20 <commands+0x870>
ffffffffc02017aa:	13900593          	li	a1,313
ffffffffc02017ae:	00004517          	auipc	a0,0x4
ffffffffc02017b2:	18a50513          	addi	a0,a0,394 # ffffffffc0205938 <commands+0x788>
ffffffffc02017b6:	a13fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
ffffffffc02017ba:	bd4ff0ef          	jal	ra,ffffffffc0200b8e <pte2page.part.0>
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
ffffffffc02017be:	00004697          	auipc	a3,0x4
ffffffffc02017c2:	30a68693          	addi	a3,a3,778 # ffffffffc0205ac8 <commands+0x918>
ffffffffc02017c6:	00004617          	auipc	a2,0x4
ffffffffc02017ca:	25a60613          	addi	a2,a2,602 # ffffffffc0205a20 <commands+0x870>
ffffffffc02017ce:	14200593          	li	a1,322
ffffffffc02017d2:	00004517          	auipc	a0,0x4
ffffffffc02017d6:	16650513          	addi	a0,a0,358 # ffffffffc0205938 <commands+0x788>
ffffffffc02017da:	9effe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc02017de:	00004697          	auipc	a3,0x4
ffffffffc02017e2:	2ba68693          	addi	a3,a3,698 # ffffffffc0205a98 <commands+0x8e8>
ffffffffc02017e6:	00004617          	auipc	a2,0x4
ffffffffc02017ea:	23a60613          	addi	a2,a2,570 # ffffffffc0205a20 <commands+0x870>
ffffffffc02017ee:	13f00593          	li	a1,319
ffffffffc02017f2:	00004517          	auipc	a0,0x4
ffffffffc02017f6:	14650513          	addi	a0,a0,326 # ffffffffc0205938 <commands+0x788>
ffffffffc02017fa:	9cffe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
ffffffffc02017fe:	00004697          	auipc	a3,0x4
ffffffffc0201802:	27268693          	addi	a3,a3,626 # ffffffffc0205a70 <commands+0x8c0>
ffffffffc0201806:	00004617          	auipc	a2,0x4
ffffffffc020180a:	21a60613          	addi	a2,a2,538 # ffffffffc0205a20 <commands+0x870>
ffffffffc020180e:	13b00593          	li	a1,315
ffffffffc0201812:	00004517          	auipc	a0,0x4
ffffffffc0201816:	12650513          	addi	a0,a0,294 # ffffffffc0205938 <commands+0x788>
ffffffffc020181a:	9affe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc020181e:	00004697          	auipc	a3,0x4
ffffffffc0201822:	33268693          	addi	a3,a3,818 # ffffffffc0205b50 <commands+0x9a0>
ffffffffc0201826:	00004617          	auipc	a2,0x4
ffffffffc020182a:	1fa60613          	addi	a2,a2,506 # ffffffffc0205a20 <commands+0x870>
ffffffffc020182e:	14b00593          	li	a1,331
ffffffffc0201832:	00004517          	auipc	a0,0x4
ffffffffc0201836:	10650513          	addi	a0,a0,262 # ffffffffc0205938 <commands+0x788>
ffffffffc020183a:	98ffe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(page_ref(p2) == 1);
ffffffffc020183e:	00004697          	auipc	a3,0x4
ffffffffc0201842:	3b268693          	addi	a3,a3,946 # ffffffffc0205bf0 <commands+0xa40>
ffffffffc0201846:	00004617          	auipc	a2,0x4
ffffffffc020184a:	1da60613          	addi	a2,a2,474 # ffffffffc0205a20 <commands+0x870>
ffffffffc020184e:	15000593          	li	a1,336
ffffffffc0201852:	00004517          	auipc	a0,0x4
ffffffffc0201856:	0e650513          	addi	a0,a0,230 # ffffffffc0205938 <commands+0x788>
ffffffffc020185a:	96ffe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc020185e:	00004697          	auipc	a3,0x4
ffffffffc0201862:	2ca68693          	addi	a3,a3,714 # ffffffffc0205b28 <commands+0x978>
ffffffffc0201866:	00004617          	auipc	a2,0x4
ffffffffc020186a:	1ba60613          	addi	a2,a2,442 # ffffffffc0205a20 <commands+0x870>
ffffffffc020186e:	14800593          	li	a1,328
ffffffffc0201872:	00004517          	auipc	a0,0x4
ffffffffc0201876:	0c650513          	addi	a0,a0,198 # ffffffffc0205938 <commands+0x788>
ffffffffc020187a:	94ffe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020187e:	86d6                	mv	a3,s5
ffffffffc0201880:	00004617          	auipc	a2,0x4
ffffffffc0201884:	09060613          	addi	a2,a2,144 # ffffffffc0205910 <commands+0x760>
ffffffffc0201888:	14700593          	li	a1,327
ffffffffc020188c:	00004517          	auipc	a0,0x4
ffffffffc0201890:	0ac50513          	addi	a0,a0,172 # ffffffffc0205938 <commands+0x788>
ffffffffc0201894:	935fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0201898:	00004697          	auipc	a3,0x4
ffffffffc020189c:	2f068693          	addi	a3,a3,752 # ffffffffc0205b88 <commands+0x9d8>
ffffffffc02018a0:	00004617          	auipc	a2,0x4
ffffffffc02018a4:	18060613          	addi	a2,a2,384 # ffffffffc0205a20 <commands+0x870>
ffffffffc02018a8:	15500593          	li	a1,341
ffffffffc02018ac:	00004517          	auipc	a0,0x4
ffffffffc02018b0:	08c50513          	addi	a0,a0,140 # ffffffffc0205938 <commands+0x788>
ffffffffc02018b4:	915fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc02018b8:	00004697          	auipc	a3,0x4
ffffffffc02018bc:	39868693          	addi	a3,a3,920 # ffffffffc0205c50 <commands+0xaa0>
ffffffffc02018c0:	00004617          	auipc	a2,0x4
ffffffffc02018c4:	16060613          	addi	a2,a2,352 # ffffffffc0205a20 <commands+0x870>
ffffffffc02018c8:	15400593          	li	a1,340
ffffffffc02018cc:	00004517          	auipc	a0,0x4
ffffffffc02018d0:	06c50513          	addi	a0,a0,108 # ffffffffc0205938 <commands+0x788>
ffffffffc02018d4:	8f5fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(page_ref(p1) == 2);
ffffffffc02018d8:	00004697          	auipc	a3,0x4
ffffffffc02018dc:	36068693          	addi	a3,a3,864 # ffffffffc0205c38 <commands+0xa88>
ffffffffc02018e0:	00004617          	auipc	a2,0x4
ffffffffc02018e4:	14060613          	addi	a2,a2,320 # ffffffffc0205a20 <commands+0x870>
ffffffffc02018e8:	15300593          	li	a1,339
ffffffffc02018ec:	00004517          	auipc	a0,0x4
ffffffffc02018f0:	04c50513          	addi	a0,a0,76 # ffffffffc0205938 <commands+0x788>
ffffffffc02018f4:	8d5fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc02018f8:	00004697          	auipc	a3,0x4
ffffffffc02018fc:	31068693          	addi	a3,a3,784 # ffffffffc0205c08 <commands+0xa58>
ffffffffc0201900:	00004617          	auipc	a2,0x4
ffffffffc0201904:	12060613          	addi	a2,a2,288 # ffffffffc0205a20 <commands+0x870>
ffffffffc0201908:	15200593          	li	a1,338
ffffffffc020190c:	00004517          	auipc	a0,0x4
ffffffffc0201910:	02c50513          	addi	a0,a0,44 # ffffffffc0205938 <commands+0x788>
ffffffffc0201914:	8b5fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0201918:	00004697          	auipc	a3,0x4
ffffffffc020191c:	4a868693          	addi	a3,a3,1192 # ffffffffc0205dc0 <commands+0xc10>
ffffffffc0201920:	00004617          	auipc	a2,0x4
ffffffffc0201924:	10060613          	addi	a2,a2,256 # ffffffffc0205a20 <commands+0x870>
ffffffffc0201928:	18100593          	li	a1,385
ffffffffc020192c:	00004517          	auipc	a0,0x4
ffffffffc0201930:	00c50513          	addi	a0,a0,12 # ffffffffc0205938 <commands+0x788>
ffffffffc0201934:	895fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc0201938:	00004697          	auipc	a3,0x4
ffffffffc020193c:	2a068693          	addi	a3,a3,672 # ffffffffc0205bd8 <commands+0xa28>
ffffffffc0201940:	00004617          	auipc	a2,0x4
ffffffffc0201944:	0e060613          	addi	a2,a2,224 # ffffffffc0205a20 <commands+0x870>
ffffffffc0201948:	14f00593          	li	a1,335
ffffffffc020194c:	00004517          	auipc	a0,0x4
ffffffffc0201950:	fec50513          	addi	a0,a0,-20 # ffffffffc0205938 <commands+0x788>
ffffffffc0201954:	875fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(*ptep & PTE_W);
ffffffffc0201958:	00004697          	auipc	a3,0x4
ffffffffc020195c:	27068693          	addi	a3,a3,624 # ffffffffc0205bc8 <commands+0xa18>
ffffffffc0201960:	00004617          	auipc	a2,0x4
ffffffffc0201964:	0c060613          	addi	a2,a2,192 # ffffffffc0205a20 <commands+0x870>
ffffffffc0201968:	14e00593          	li	a1,334
ffffffffc020196c:	00004517          	auipc	a0,0x4
ffffffffc0201970:	fcc50513          	addi	a0,a0,-52 # ffffffffc0205938 <commands+0x788>
ffffffffc0201974:	855fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(nr_free_store==nr_free_pages());
ffffffffc0201978:	00004697          	auipc	a3,0x4
ffffffffc020197c:	34868693          	addi	a3,a3,840 # ffffffffc0205cc0 <commands+0xb10>
ffffffffc0201980:	00004617          	auipc	a2,0x4
ffffffffc0201984:	0a060613          	addi	a2,a2,160 # ffffffffc0205a20 <commands+0x870>
ffffffffc0201988:	19200593          	li	a1,402
ffffffffc020198c:	00004517          	auipc	a0,0x4
ffffffffc0201990:	fac50513          	addi	a0,a0,-84 # ffffffffc0205938 <commands+0x788>
ffffffffc0201994:	835fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(*ptep & PTE_U);
ffffffffc0201998:	00004697          	auipc	a3,0x4
ffffffffc020199c:	22068693          	addi	a3,a3,544 # ffffffffc0205bb8 <commands+0xa08>
ffffffffc02019a0:	00004617          	auipc	a2,0x4
ffffffffc02019a4:	08060613          	addi	a2,a2,128 # ffffffffc0205a20 <commands+0x870>
ffffffffc02019a8:	14d00593          	li	a1,333
ffffffffc02019ac:	00004517          	auipc	a0,0x4
ffffffffc02019b0:	f8c50513          	addi	a0,a0,-116 # ffffffffc0205938 <commands+0x788>
ffffffffc02019b4:	815fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc02019b8:	00004697          	auipc	a3,0x4
ffffffffc02019bc:	15868693          	addi	a3,a3,344 # ffffffffc0205b10 <commands+0x960>
ffffffffc02019c0:	00004617          	auipc	a2,0x4
ffffffffc02019c4:	06060613          	addi	a2,a2,96 # ffffffffc0205a20 <commands+0x870>
ffffffffc02019c8:	15a00593          	li	a1,346
ffffffffc02019cc:	00004517          	auipc	a0,0x4
ffffffffc02019d0:	f6c50513          	addi	a0,a0,-148 # ffffffffc0205938 <commands+0x788>
ffffffffc02019d4:	ff4fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc02019d8:	00004697          	auipc	a3,0x4
ffffffffc02019dc:	29068693          	addi	a3,a3,656 # ffffffffc0205c68 <commands+0xab8>
ffffffffc02019e0:	00004617          	auipc	a2,0x4
ffffffffc02019e4:	04060613          	addi	a2,a2,64 # ffffffffc0205a20 <commands+0x870>
ffffffffc02019e8:	15700593          	li	a1,343
ffffffffc02019ec:	00004517          	auipc	a0,0x4
ffffffffc02019f0:	f4c50513          	addi	a0,a0,-180 # ffffffffc0205938 <commands+0x788>
ffffffffc02019f4:	fd4fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc02019f8:	00004697          	auipc	a3,0x4
ffffffffc02019fc:	10068693          	addi	a3,a3,256 # ffffffffc0205af8 <commands+0x948>
ffffffffc0201a00:	00004617          	auipc	a2,0x4
ffffffffc0201a04:	02060613          	addi	a2,a2,32 # ffffffffc0205a20 <commands+0x870>
ffffffffc0201a08:	15600593          	li	a1,342
ffffffffc0201a0c:	00004517          	auipc	a0,0x4
ffffffffc0201a10:	f2c50513          	addi	a0,a0,-212 # ffffffffc0205938 <commands+0x788>
ffffffffc0201a14:	fb4fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    return KADDR(page2pa(page));
ffffffffc0201a18:	00004617          	auipc	a2,0x4
ffffffffc0201a1c:	ef860613          	addi	a2,a2,-264 # ffffffffc0205910 <commands+0x760>
ffffffffc0201a20:	06700593          	li	a1,103
ffffffffc0201a24:	00004517          	auipc	a0,0x4
ffffffffc0201a28:	eb450513          	addi	a0,a0,-332 # ffffffffc02058d8 <commands+0x728>
ffffffffc0201a2c:	f9cfe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
ffffffffc0201a30:	00004697          	auipc	a3,0x4
ffffffffc0201a34:	26868693          	addi	a3,a3,616 # ffffffffc0205c98 <commands+0xae8>
ffffffffc0201a38:	00004617          	auipc	a2,0x4
ffffffffc0201a3c:	fe860613          	addi	a2,a2,-24 # ffffffffc0205a20 <commands+0x870>
ffffffffc0201a40:	16100593          	li	a1,353
ffffffffc0201a44:	00004517          	auipc	a0,0x4
ffffffffc0201a48:	ef450513          	addi	a0,a0,-268 # ffffffffc0205938 <commands+0x788>
ffffffffc0201a4c:	f7cfe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0201a50:	00004697          	auipc	a3,0x4
ffffffffc0201a54:	20068693          	addi	a3,a3,512 # ffffffffc0205c50 <commands+0xaa0>
ffffffffc0201a58:	00004617          	auipc	a2,0x4
ffffffffc0201a5c:	fc860613          	addi	a2,a2,-56 # ffffffffc0205a20 <commands+0x870>
ffffffffc0201a60:	15f00593          	li	a1,351
ffffffffc0201a64:	00004517          	auipc	a0,0x4
ffffffffc0201a68:	ed450513          	addi	a0,a0,-300 # ffffffffc0205938 <commands+0x788>
ffffffffc0201a6c:	f5cfe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(page_ref(p1) == 0);
ffffffffc0201a70:	00004697          	auipc	a3,0x4
ffffffffc0201a74:	21068693          	addi	a3,a3,528 # ffffffffc0205c80 <commands+0xad0>
ffffffffc0201a78:	00004617          	auipc	a2,0x4
ffffffffc0201a7c:	fa860613          	addi	a2,a2,-88 # ffffffffc0205a20 <commands+0x870>
ffffffffc0201a80:	15e00593          	li	a1,350
ffffffffc0201a84:	00004517          	auipc	a0,0x4
ffffffffc0201a88:	eb450513          	addi	a0,a0,-332 # ffffffffc0205938 <commands+0x788>
ffffffffc0201a8c:	f3cfe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0201a90:	00004697          	auipc	a3,0x4
ffffffffc0201a94:	1c068693          	addi	a3,a3,448 # ffffffffc0205c50 <commands+0xaa0>
ffffffffc0201a98:	00004617          	auipc	a2,0x4
ffffffffc0201a9c:	f8860613          	addi	a2,a2,-120 # ffffffffc0205a20 <commands+0x870>
ffffffffc0201aa0:	15b00593          	li	a1,347
ffffffffc0201aa4:	00004517          	auipc	a0,0x4
ffffffffc0201aa8:	e9450513          	addi	a0,a0,-364 # ffffffffc0205938 <commands+0x788>
ffffffffc0201aac:	f1cfe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(page_ref(p) == 1);
ffffffffc0201ab0:	00004697          	auipc	a3,0x4
ffffffffc0201ab4:	2f868693          	addi	a3,a3,760 # ffffffffc0205da8 <commands+0xbf8>
ffffffffc0201ab8:	00004617          	auipc	a2,0x4
ffffffffc0201abc:	f6860613          	addi	a2,a2,-152 # ffffffffc0205a20 <commands+0x870>
ffffffffc0201ac0:	18000593          	li	a1,384
ffffffffc0201ac4:	00004517          	auipc	a0,0x4
ffffffffc0201ac8:	e7450513          	addi	a0,a0,-396 # ffffffffc0205938 <commands+0x788>
ffffffffc0201acc:	efcfe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0201ad0:	00004697          	auipc	a3,0x4
ffffffffc0201ad4:	2a068693          	addi	a3,a3,672 # ffffffffc0205d70 <commands+0xbc0>
ffffffffc0201ad8:	00004617          	auipc	a2,0x4
ffffffffc0201adc:	f4860613          	addi	a2,a2,-184 # ffffffffc0205a20 <commands+0x870>
ffffffffc0201ae0:	17f00593          	li	a1,383
ffffffffc0201ae4:	00004517          	auipc	a0,0x4
ffffffffc0201ae8:	e5450513          	addi	a0,a0,-428 # ffffffffc0205938 <commands+0x788>
ffffffffc0201aec:	edcfe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(boot_pgdir[0] == 0);
ffffffffc0201af0:	00004697          	auipc	a3,0x4
ffffffffc0201af4:	26868693          	addi	a3,a3,616 # ffffffffc0205d58 <commands+0xba8>
ffffffffc0201af8:	00004617          	auipc	a2,0x4
ffffffffc0201afc:	f2860613          	addi	a2,a2,-216 # ffffffffc0205a20 <commands+0x870>
ffffffffc0201b00:	17b00593          	li	a1,379
ffffffffc0201b04:	00004517          	auipc	a0,0x4
ffffffffc0201b08:	e3450513          	addi	a0,a0,-460 # ffffffffc0205938 <commands+0x788>
ffffffffc0201b0c:	ebcfe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(nr_free_store==nr_free_pages());
ffffffffc0201b10:	00004697          	auipc	a3,0x4
ffffffffc0201b14:	1b068693          	addi	a3,a3,432 # ffffffffc0205cc0 <commands+0xb10>
ffffffffc0201b18:	00004617          	auipc	a2,0x4
ffffffffc0201b1c:	f0860613          	addi	a2,a2,-248 # ffffffffc0205a20 <commands+0x870>
ffffffffc0201b20:	16900593          	li	a1,361
ffffffffc0201b24:	00004517          	auipc	a0,0x4
ffffffffc0201b28:	e1450513          	addi	a0,a0,-492 # ffffffffc0205938 <commands+0x788>
ffffffffc0201b2c:	e9cfe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0201b30:	00004697          	auipc	a3,0x4
ffffffffc0201b34:	fc868693          	addi	a3,a3,-56 # ffffffffc0205af8 <commands+0x948>
ffffffffc0201b38:	00004617          	auipc	a2,0x4
ffffffffc0201b3c:	ee860613          	addi	a2,a2,-280 # ffffffffc0205a20 <commands+0x870>
ffffffffc0201b40:	14300593          	li	a1,323
ffffffffc0201b44:	00004517          	auipc	a0,0x4
ffffffffc0201b48:	df450513          	addi	a0,a0,-524 # ffffffffc0205938 <commands+0x788>
ffffffffc0201b4c:	e7cfe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc0201b50:	00004617          	auipc	a2,0x4
ffffffffc0201b54:	dc060613          	addi	a2,a2,-576 # ffffffffc0205910 <commands+0x760>
ffffffffc0201b58:	14600593          	li	a1,326
ffffffffc0201b5c:	00004517          	auipc	a0,0x4
ffffffffc0201b60:	ddc50513          	addi	a0,a0,-548 # ffffffffc0205938 <commands+0x788>
ffffffffc0201b64:	e64fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0201b68:	00004697          	auipc	a3,0x4
ffffffffc0201b6c:	fa868693          	addi	a3,a3,-88 # ffffffffc0205b10 <commands+0x960>
ffffffffc0201b70:	00004617          	auipc	a2,0x4
ffffffffc0201b74:	eb060613          	addi	a2,a2,-336 # ffffffffc0205a20 <commands+0x870>
ffffffffc0201b78:	14400593          	li	a1,324
ffffffffc0201b7c:	00004517          	auipc	a0,0x4
ffffffffc0201b80:	dbc50513          	addi	a0,a0,-580 # ffffffffc0205938 <commands+0x788>
ffffffffc0201b84:	e44fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0201b88:	00004697          	auipc	a3,0x4
ffffffffc0201b8c:	00068693          	mv	a3,a3
ffffffffc0201b90:	00004617          	auipc	a2,0x4
ffffffffc0201b94:	e9060613          	addi	a2,a2,-368 # ffffffffc0205a20 <commands+0x870>
ffffffffc0201b98:	14c00593          	li	a1,332
ffffffffc0201b9c:	00004517          	auipc	a0,0x4
ffffffffc0201ba0:	d9c50513          	addi	a0,a0,-612 # ffffffffc0205938 <commands+0x788>
ffffffffc0201ba4:	e24fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0201ba8:	00004697          	auipc	a3,0x4
ffffffffc0201bac:	2c068693          	addi	a3,a3,704 # ffffffffc0205e68 <commands+0xcb8>
ffffffffc0201bb0:	00004617          	auipc	a2,0x4
ffffffffc0201bb4:	e7060613          	addi	a2,a2,-400 # ffffffffc0205a20 <commands+0x870>
ffffffffc0201bb8:	18900593          	li	a1,393
ffffffffc0201bbc:	00004517          	auipc	a0,0x4
ffffffffc0201bc0:	d7c50513          	addi	a0,a0,-644 # ffffffffc0205938 <commands+0x788>
ffffffffc0201bc4:	e04fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0201bc8:	00004697          	auipc	a3,0x4
ffffffffc0201bcc:	26868693          	addi	a3,a3,616 # ffffffffc0205e30 <commands+0xc80>
ffffffffc0201bd0:	00004617          	auipc	a2,0x4
ffffffffc0201bd4:	e5060613          	addi	a2,a2,-432 # ffffffffc0205a20 <commands+0x870>
ffffffffc0201bd8:	18600593          	li	a1,390
ffffffffc0201bdc:	00004517          	auipc	a0,0x4
ffffffffc0201be0:	d5c50513          	addi	a0,a0,-676 # ffffffffc0205938 <commands+0x788>
ffffffffc0201be4:	de4fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(page_ref(p) == 2);
ffffffffc0201be8:	00004697          	auipc	a3,0x4
ffffffffc0201bec:	21868693          	addi	a3,a3,536 # ffffffffc0205e00 <commands+0xc50>
ffffffffc0201bf0:	00004617          	auipc	a2,0x4
ffffffffc0201bf4:	e3060613          	addi	a2,a2,-464 # ffffffffc0205a20 <commands+0x870>
ffffffffc0201bf8:	18200593          	li	a1,386
ffffffffc0201bfc:	00004517          	auipc	a0,0x4
ffffffffc0201c00:	d3c50513          	addi	a0,a0,-708 # ffffffffc0205938 <commands+0x788>
ffffffffc0201c04:	dc4fe0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc0201c08 <tlb_invalidate>:
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0201c08:	12058073          	sfence.vma	a1
}
ffffffffc0201c0c:	8082                	ret

ffffffffc0201c0e <pgdir_alloc_page>:
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
ffffffffc0201c0e:	7179                	addi	sp,sp,-48
ffffffffc0201c10:	e84a                	sd	s2,16(sp)
ffffffffc0201c12:	892a                	mv	s2,a0
    struct Page *page = alloc_page();
ffffffffc0201c14:	4505                	li	a0,1
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
ffffffffc0201c16:	f022                	sd	s0,32(sp)
ffffffffc0201c18:	ec26                	sd	s1,24(sp)
ffffffffc0201c1a:	e44e                	sd	s3,8(sp)
ffffffffc0201c1c:	f406                	sd	ra,40(sp)
ffffffffc0201c1e:	84ae                	mv	s1,a1
ffffffffc0201c20:	89b2                	mv	s3,a2
    struct Page *page = alloc_page();
ffffffffc0201c22:	f89fe0ef          	jal	ra,ffffffffc0200baa <alloc_pages>
ffffffffc0201c26:	842a                	mv	s0,a0
    if (page != NULL) {
ffffffffc0201c28:	cd09                	beqz	a0,ffffffffc0201c42 <pgdir_alloc_page+0x34>
        if (page_insert(pgdir, page, la, perm) != 0) {
ffffffffc0201c2a:	85aa                	mv	a1,a0
ffffffffc0201c2c:	86ce                	mv	a3,s3
ffffffffc0201c2e:	8626                	mv	a2,s1
ffffffffc0201c30:	854a                	mv	a0,s2
ffffffffc0201c32:	b46ff0ef          	jal	ra,ffffffffc0200f78 <page_insert>
ffffffffc0201c36:	ed21                	bnez	a0,ffffffffc0201c8e <pgdir_alloc_page+0x80>
        if (swap_init_ok) {
ffffffffc0201c38:	00015797          	auipc	a5,0x15
ffffffffc0201c3c:	9687a783          	lw	a5,-1688(a5) # ffffffffc02165a0 <swap_init_ok>
ffffffffc0201c40:	eb89                	bnez	a5,ffffffffc0201c52 <pgdir_alloc_page+0x44>
}
ffffffffc0201c42:	70a2                	ld	ra,40(sp)
ffffffffc0201c44:	8522                	mv	a0,s0
ffffffffc0201c46:	7402                	ld	s0,32(sp)
ffffffffc0201c48:	64e2                	ld	s1,24(sp)
ffffffffc0201c4a:	6942                	ld	s2,16(sp)
ffffffffc0201c4c:	69a2                	ld	s3,8(sp)
ffffffffc0201c4e:	6145                	addi	sp,sp,48
ffffffffc0201c50:	8082                	ret
            swap_map_swappable(check_mm_struct, la, page, 0);
ffffffffc0201c52:	4681                	li	a3,0
ffffffffc0201c54:	8622                	mv	a2,s0
ffffffffc0201c56:	85a6                	mv	a1,s1
ffffffffc0201c58:	00015517          	auipc	a0,0x15
ffffffffc0201c5c:	92853503          	ld	a0,-1752(a0) # ffffffffc0216580 <check_mm_struct>
ffffffffc0201c60:	054010ef          	jal	ra,ffffffffc0202cb4 <swap_map_swappable>
            assert(page_ref(page) == 1);
ffffffffc0201c64:	4018                	lw	a4,0(s0)
            page->pra_vaddr = la;
ffffffffc0201c66:	fc04                	sd	s1,56(s0)
            assert(page_ref(page) == 1);
ffffffffc0201c68:	4785                	li	a5,1
ffffffffc0201c6a:	fcf70ce3          	beq	a4,a5,ffffffffc0201c42 <pgdir_alloc_page+0x34>
ffffffffc0201c6e:	00004697          	auipc	a3,0x4
ffffffffc0201c72:	24268693          	addi	a3,a3,578 # ffffffffc0205eb0 <commands+0xd00>
ffffffffc0201c76:	00004617          	auipc	a2,0x4
ffffffffc0201c7a:	daa60613          	addi	a2,a2,-598 # ffffffffc0205a20 <commands+0x870>
ffffffffc0201c7e:	11f00593          	li	a1,287
ffffffffc0201c82:	00004517          	auipc	a0,0x4
ffffffffc0201c86:	cb650513          	addi	a0,a0,-842 # ffffffffc0205938 <commands+0x788>
ffffffffc0201c8a:	d3efe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    if (read_csr(sstatus) & SSTATUS_SIE) { // 如果当前中断使能
ffffffffc0201c8e:	100027f3          	csrr	a5,sstatus
ffffffffc0201c92:	8b89                	andi	a5,a5,2
ffffffffc0201c94:	eb99                	bnez	a5,ffffffffc0201caa <pgdir_alloc_page+0x9c>
        pmm_manager->free_pages(base, n);
ffffffffc0201c96:	00015797          	auipc	a5,0x15
ffffffffc0201c9a:	8da7b783          	ld	a5,-1830(a5) # ffffffffc0216570 <pmm_manager>
ffffffffc0201c9e:	739c                	ld	a5,32(a5)
ffffffffc0201ca0:	8522                	mv	a0,s0
ffffffffc0201ca2:	4585                	li	a1,1
ffffffffc0201ca4:	9782                	jalr	a5
            return NULL;
ffffffffc0201ca6:	4401                	li	s0,0
ffffffffc0201ca8:	bf69                	j	ffffffffc0201c42 <pgdir_alloc_page+0x34>
        intr_disable(); // 禁用中断
ffffffffc0201caa:	91bfe0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201cae:	00015797          	auipc	a5,0x15
ffffffffc0201cb2:	8c27b783          	ld	a5,-1854(a5) # ffffffffc0216570 <pmm_manager>
ffffffffc0201cb6:	739c                	ld	a5,32(a5)
ffffffffc0201cb8:	8522                	mv	a0,s0
ffffffffc0201cba:	4585                	li	a1,1
ffffffffc0201cbc:	9782                	jalr	a5
            return NULL;
ffffffffc0201cbe:	4401                	li	s0,0
        intr_enable(); // 使能中断
ffffffffc0201cc0:	8fffe0ef          	jal	ra,ffffffffc02005be <intr_enable>
ffffffffc0201cc4:	bfbd                	j	ffffffffc0201c42 <pgdir_alloc_page+0x34>

ffffffffc0201cc6 <check_vma_overlap.part.0>:
        return vma;
}

// check_vma_overlap - 检查vma1是否与vma2重叠
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next) {
ffffffffc0201cc6:	1141                	addi	sp,sp,-16
        assert(prev->vm_start < prev->vm_end);
        assert(prev->vm_end <= next->vm_start);
        assert(next->vm_start < next->vm_end);
ffffffffc0201cc8:	00004697          	auipc	a3,0x4
ffffffffc0201ccc:	20068693          	addi	a3,a3,512 # ffffffffc0205ec8 <commands+0xd18>
ffffffffc0201cd0:	00004617          	auipc	a2,0x4
ffffffffc0201cd4:	d5060613          	addi	a2,a2,-688 # ffffffffc0205a20 <commands+0x870>
ffffffffc0201cd8:	07b00593          	li	a1,123
ffffffffc0201cdc:	00004517          	auipc	a0,0x4
ffffffffc0201ce0:	20c50513          	addi	a0,a0,524 # ffffffffc0205ee8 <commands+0xd38>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next) {
ffffffffc0201ce4:	e406                	sd	ra,8(sp)
        assert(next->vm_start < next->vm_end);
ffffffffc0201ce6:	ce2fe0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc0201cea <mm_create>:
mm_create(void) {
ffffffffc0201cea:	1141                	addi	sp,sp,-16
        struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0201cec:	03000513          	li	a0,48
mm_create(void) {
ffffffffc0201cf0:	e022                	sd	s0,0(sp)
ffffffffc0201cf2:	e406                	sd	ra,8(sp)
        struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0201cf4:	388010ef          	jal	ra,ffffffffc020307c <kmalloc>
ffffffffc0201cf8:	842a                	mv	s0,a0
        if (mm != NULL) {
ffffffffc0201cfa:	c105                	beqz	a0,ffffffffc0201d1a <mm_create+0x30>
 * @elm:        new entry to be initialized
 * 新的链表节点
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm; // 将节点的前后指针都指向自己
ffffffffc0201cfc:	e408                	sd	a0,8(s0)
ffffffffc0201cfe:	e008                	sd	a0,0(s0)
                mm->mmap_cache = NULL;
ffffffffc0201d00:	00053823          	sd	zero,16(a0)
                mm->pgdir = NULL;
ffffffffc0201d04:	00053c23          	sd	zero,24(a0)
                mm->map_count = 0;
ffffffffc0201d08:	02052023          	sw	zero,32(a0)
                if (swap_init_ok) swap_init_mm(mm);
ffffffffc0201d0c:	00015797          	auipc	a5,0x15
ffffffffc0201d10:	8947a783          	lw	a5,-1900(a5) # ffffffffc02165a0 <swap_init_ok>
ffffffffc0201d14:	eb81                	bnez	a5,ffffffffc0201d24 <mm_create+0x3a>
                else mm->sm_priv = NULL;
ffffffffc0201d16:	02053423          	sd	zero,40(a0)
}
ffffffffc0201d1a:	60a2                	ld	ra,8(sp)
ffffffffc0201d1c:	8522                	mv	a0,s0
ffffffffc0201d1e:	6402                	ld	s0,0(sp)
ffffffffc0201d20:	0141                	addi	sp,sp,16
ffffffffc0201d22:	8082                	ret
                if (swap_init_ok) swap_init_mm(mm);
ffffffffc0201d24:	785000ef          	jal	ra,ffffffffc0202ca8 <swap_init_mm>
}
ffffffffc0201d28:	60a2                	ld	ra,8(sp)
ffffffffc0201d2a:	8522                	mv	a0,s0
ffffffffc0201d2c:	6402                	ld	s0,0(sp)
ffffffffc0201d2e:	0141                	addi	sp,sp,16
ffffffffc0201d30:	8082                	ret

ffffffffc0201d32 <vma_create>:
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint32_t vm_flags) {
ffffffffc0201d32:	1101                	addi	sp,sp,-32
ffffffffc0201d34:	e04a                	sd	s2,0(sp)
ffffffffc0201d36:	892a                	mv	s2,a0
        struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0201d38:	03000513          	li	a0,48
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint32_t vm_flags) {
ffffffffc0201d3c:	e822                	sd	s0,16(sp)
ffffffffc0201d3e:	e426                	sd	s1,8(sp)
ffffffffc0201d40:	ec06                	sd	ra,24(sp)
ffffffffc0201d42:	84ae                	mv	s1,a1
ffffffffc0201d44:	8432                	mv	s0,a2
        struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0201d46:	336010ef          	jal	ra,ffffffffc020307c <kmalloc>
        if (vma != NULL) {
ffffffffc0201d4a:	c509                	beqz	a0,ffffffffc0201d54 <vma_create+0x22>
                vma->vm_start = vm_start;
ffffffffc0201d4c:	01253423          	sd	s2,8(a0)
                vma->vm_end = vm_end;
ffffffffc0201d50:	e904                	sd	s1,16(a0)
                vma->vm_flags = vm_flags;
ffffffffc0201d52:	cd00                	sw	s0,24(a0)
}
ffffffffc0201d54:	60e2                	ld	ra,24(sp)
ffffffffc0201d56:	6442                	ld	s0,16(sp)
ffffffffc0201d58:	64a2                	ld	s1,8(sp)
ffffffffc0201d5a:	6902                	ld	s2,0(sp)
ffffffffc0201d5c:	6105                	addi	sp,sp,32
ffffffffc0201d5e:	8082                	ret

ffffffffc0201d60 <find_vma>:
find_vma(struct mm_struct *mm, uintptr_t addr) {
ffffffffc0201d60:	86aa                	mv	a3,a0
        if (mm != NULL) {
ffffffffc0201d62:	c505                	beqz	a0,ffffffffc0201d8a <find_vma+0x2a>
                vma = mm->mmap_cache;
ffffffffc0201d64:	6908                	ld	a0,16(a0)
                if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) {
ffffffffc0201d66:	c501                	beqz	a0,ffffffffc0201d6e <find_vma+0xe>
ffffffffc0201d68:	651c                	ld	a5,8(a0)
ffffffffc0201d6a:	02f5f263          	bgeu	a1,a5,ffffffffc0201d8e <find_vma+0x2e>
 * @listelm:    the list head
 * 链表头
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next; // 返回下一个节点
ffffffffc0201d6e:	669c                	ld	a5,8(a3)
                                while ((le = list_next(le)) != list) {
ffffffffc0201d70:	00f68d63          	beq	a3,a5,ffffffffc0201d8a <find_vma+0x2a>
                                        if (vma->vm_start<=addr && addr < vma->vm_end) {
ffffffffc0201d74:	fe87b703          	ld	a4,-24(a5)
ffffffffc0201d78:	00e5e663          	bltu	a1,a4,ffffffffc0201d84 <find_vma+0x24>
ffffffffc0201d7c:	ff07b703          	ld	a4,-16(a5)
ffffffffc0201d80:	00e5ec63          	bltu	a1,a4,ffffffffc0201d98 <find_vma+0x38>
ffffffffc0201d84:	679c                	ld	a5,8(a5)
                                while ((le = list_next(le)) != list) {
ffffffffc0201d86:	fef697e3          	bne	a3,a5,ffffffffc0201d74 <find_vma+0x14>
        struct vma_struct *vma = NULL;
ffffffffc0201d8a:	4501                	li	a0,0
}
ffffffffc0201d8c:	8082                	ret
                if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) {
ffffffffc0201d8e:	691c                	ld	a5,16(a0)
ffffffffc0201d90:	fcf5ffe3          	bgeu	a1,a5,ffffffffc0201d6e <find_vma+0xe>
                        mm->mmap_cache = vma;
ffffffffc0201d94:	ea88                	sd	a0,16(a3)
ffffffffc0201d96:	8082                	ret
                                        vma = le2vma(le, list_link);
ffffffffc0201d98:	fe078513          	addi	a0,a5,-32
                        mm->mmap_cache = vma;
ffffffffc0201d9c:	ea88                	sd	a0,16(a3)
ffffffffc0201d9e:	8082                	ret

ffffffffc0201da0 <insert_vma_struct>:
}

// insert_vma_struct - 在mm的链表中插入vma
void
insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma) {
        assert(vma->vm_start < vma->vm_end);
ffffffffc0201da0:	6590                	ld	a2,8(a1)
ffffffffc0201da2:	0105b803          	ld	a6,16(a1)
insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma) {
ffffffffc0201da6:	1141                	addi	sp,sp,-16
ffffffffc0201da8:	e406                	sd	ra,8(sp)
ffffffffc0201daa:	87aa                	mv	a5,a0
        assert(vma->vm_start < vma->vm_end);
ffffffffc0201dac:	01066763          	bltu	a2,a6,ffffffffc0201dba <insert_vma_struct+0x1a>
ffffffffc0201db0:	a085                	j	ffffffffc0201e10 <insert_vma_struct+0x70>
        list_entry_t *le_prev = list, *le_next;

                list_entry_t *le = list;
                while ((le = list_next(le)) != list) {
                        struct vma_struct *mmap_prev = le2vma(le, list_link);
                        if (mmap_prev->vm_start > vma->vm_start) {
ffffffffc0201db2:	fe87b703          	ld	a4,-24(a5)
ffffffffc0201db6:	04e66863          	bltu	a2,a4,ffffffffc0201e06 <insert_vma_struct+0x66>
ffffffffc0201dba:	86be                	mv	a3,a5
ffffffffc0201dbc:	679c                	ld	a5,8(a5)
                while ((le = list_next(le)) != list) {
ffffffffc0201dbe:	fef51ae3          	bne	a0,a5,ffffffffc0201db2 <insert_vma_struct+0x12>
                }

        le_next = list_next(le_prev);

        /* 检查重叠 */
        if (le_prev != list) {
ffffffffc0201dc2:	02a68463          	beq	a3,a0,ffffffffc0201dea <insert_vma_struct+0x4a>
                check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc0201dc6:	ff06b703          	ld	a4,-16(a3)
        assert(prev->vm_start < prev->vm_end);
ffffffffc0201dca:	fe86b883          	ld	a7,-24(a3)
ffffffffc0201dce:	08e8f163          	bgeu	a7,a4,ffffffffc0201e50 <insert_vma_struct+0xb0>
        assert(prev->vm_end <= next->vm_start);
ffffffffc0201dd2:	04e66f63          	bltu	a2,a4,ffffffffc0201e30 <insert_vma_struct+0x90>
        }
        if (le_next != list) {
ffffffffc0201dd6:	00f50a63          	beq	a0,a5,ffffffffc0201dea <insert_vma_struct+0x4a>
                        if (mmap_prev->vm_start > vma->vm_start) {
ffffffffc0201dda:	fe87b703          	ld	a4,-24(a5)
        assert(prev->vm_end <= next->vm_start);
ffffffffc0201dde:	05076963          	bltu	a4,a6,ffffffffc0201e30 <insert_vma_struct+0x90>
        assert(next->vm_start < next->vm_end);
ffffffffc0201de2:	ff07b603          	ld	a2,-16(a5)
ffffffffc0201de6:	02c77363          	bgeu	a4,a2,ffffffffc0201e0c <insert_vma_struct+0x6c>
        }

        vma->vm_mm = mm;
        list_add_after(le_prev, &(vma->list_link));

        mm->map_count ++;
ffffffffc0201dea:	5118                	lw	a4,32(a0)
        vma->vm_mm = mm;
ffffffffc0201dec:	e188                	sd	a0,0(a1)
        list_add_after(le_prev, &(vma->list_link));
ffffffffc0201dee:	02058613          	addi	a2,a1,32
 * the prev/next entries already!
 * 这仅用于我们已经知道前/后节点的内部链表操作！
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm; // 将前一个节点的下一个指针和后一个节点的前一个指针指向新节点
ffffffffc0201df2:	e390                	sd	a2,0(a5)
ffffffffc0201df4:	e690                	sd	a2,8(a3)
}
ffffffffc0201df6:	60a2                	ld	ra,8(sp)
    elm->next = next; // 将新节点的下一个指针指向后一个节点
ffffffffc0201df8:	f59c                	sd	a5,40(a1)
    elm->prev = prev; // 将新节点的前一个指针指向前一个节点
ffffffffc0201dfa:	f194                	sd	a3,32(a1)
        mm->map_count ++;
ffffffffc0201dfc:	0017079b          	addiw	a5,a4,1
ffffffffc0201e00:	d11c                	sw	a5,32(a0)
}
ffffffffc0201e02:	0141                	addi	sp,sp,16
ffffffffc0201e04:	8082                	ret
        if (le_prev != list) {
ffffffffc0201e06:	fca690e3          	bne	a3,a0,ffffffffc0201dc6 <insert_vma_struct+0x26>
ffffffffc0201e0a:	bfd1                	j	ffffffffc0201dde <insert_vma_struct+0x3e>
ffffffffc0201e0c:	ebbff0ef          	jal	ra,ffffffffc0201cc6 <check_vma_overlap.part.0>
        assert(vma->vm_start < vma->vm_end);
ffffffffc0201e10:	00004697          	auipc	a3,0x4
ffffffffc0201e14:	0e868693          	addi	a3,a3,232 # ffffffffc0205ef8 <commands+0xd48>
ffffffffc0201e18:	00004617          	auipc	a2,0x4
ffffffffc0201e1c:	c0860613          	addi	a2,a2,-1016 # ffffffffc0205a20 <commands+0x870>
ffffffffc0201e20:	08100593          	li	a1,129
ffffffffc0201e24:	00004517          	auipc	a0,0x4
ffffffffc0201e28:	0c450513          	addi	a0,a0,196 # ffffffffc0205ee8 <commands+0xd38>
ffffffffc0201e2c:	b9cfe0ef          	jal	ra,ffffffffc02001c8 <__panic>
        assert(prev->vm_end <= next->vm_start);
ffffffffc0201e30:	00004697          	auipc	a3,0x4
ffffffffc0201e34:	10868693          	addi	a3,a3,264 # ffffffffc0205f38 <commands+0xd88>
ffffffffc0201e38:	00004617          	auipc	a2,0x4
ffffffffc0201e3c:	be860613          	addi	a2,a2,-1048 # ffffffffc0205a20 <commands+0x870>
ffffffffc0201e40:	07a00593          	li	a1,122
ffffffffc0201e44:	00004517          	auipc	a0,0x4
ffffffffc0201e48:	0a450513          	addi	a0,a0,164 # ffffffffc0205ee8 <commands+0xd38>
ffffffffc0201e4c:	b7cfe0ef          	jal	ra,ffffffffc02001c8 <__panic>
        assert(prev->vm_start < prev->vm_end);
ffffffffc0201e50:	00004697          	auipc	a3,0x4
ffffffffc0201e54:	0c868693          	addi	a3,a3,200 # ffffffffc0205f18 <commands+0xd68>
ffffffffc0201e58:	00004617          	auipc	a2,0x4
ffffffffc0201e5c:	bc860613          	addi	a2,a2,-1080 # ffffffffc0205a20 <commands+0x870>
ffffffffc0201e60:	07900593          	li	a1,121
ffffffffc0201e64:	00004517          	auipc	a0,0x4
ffffffffc0201e68:	08450513          	addi	a0,a0,132 # ffffffffc0205ee8 <commands+0xd38>
ffffffffc0201e6c:	b5cfe0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc0201e70 <mm_destroy>:

// mm_destroy - 释放mm和mm的内部字段
void
mm_destroy(struct mm_struct *mm) {
ffffffffc0201e70:	1141                	addi	sp,sp,-16
ffffffffc0201e72:	e022                	sd	s0,0(sp)
ffffffffc0201e74:	842a                	mv	s0,a0
    return listelm->next; // 返回下一个节点
ffffffffc0201e76:	6508                	ld	a0,8(a0)
ffffffffc0201e78:	e406                	sd	ra,8(sp)

        list_entry_t *list = &(mm->mmap_list), *le;
        while ((le = list_next(list)) != list) {
ffffffffc0201e7a:	00a40c63          	beq	s0,a0,ffffffffc0201e92 <mm_destroy+0x22>
    __list_del(listelm->prev, listelm->next); // 调用__list_del函数
ffffffffc0201e7e:	6118                	ld	a4,0(a0)
ffffffffc0201e80:	651c                	ld	a5,8(a0)
                list_del(le);
                kfree(le2vma(le, list_link));  //释放vma        
ffffffffc0201e82:	1501                	addi	a0,a0,-32
 * the prev/next entries already!
 * 这仅用于我们已经知道前/后节点的内部链表操作！
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next; // 将前一个节点的下一个指针指向后一个节点
ffffffffc0201e84:	e71c                	sd	a5,8(a4)
    next->prev = prev; // 将后一个节点的前一个指针指向前一个节点
ffffffffc0201e86:	e398                	sd	a4,0(a5)
ffffffffc0201e88:	2a4010ef          	jal	ra,ffffffffc020312c <kfree>
    return listelm->next; // 返回下一个节点
ffffffffc0201e8c:	6408                	ld	a0,8(s0)
        while ((le = list_next(list)) != list) {
ffffffffc0201e8e:	fea418e3          	bne	s0,a0,ffffffffc0201e7e <mm_destroy+0xe>
        }
        kfree(mm); //释放mm
ffffffffc0201e92:	8522                	mv	a0,s0
        mm=NULL;
}
ffffffffc0201e94:	6402                	ld	s0,0(sp)
ffffffffc0201e96:	60a2                	ld	ra,8(sp)
ffffffffc0201e98:	0141                	addi	sp,sp,16
        kfree(mm); //释放mm
ffffffffc0201e9a:	2920106f          	j	ffffffffc020312c <kfree>

ffffffffc0201e9e <vmm_init>:

// vmm_init - 初始化虚拟内存管理
//          - 现在只调用check_vmm来检查vmm的正确性
void
vmm_init(void) {
ffffffffc0201e9e:	7139                	addi	sp,sp,-64
        struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0201ea0:	03000513          	li	a0,48
vmm_init(void) {
ffffffffc0201ea4:	fc06                	sd	ra,56(sp)
ffffffffc0201ea6:	f822                	sd	s0,48(sp)
ffffffffc0201ea8:	f426                	sd	s1,40(sp)
ffffffffc0201eaa:	f04a                	sd	s2,32(sp)
ffffffffc0201eac:	ec4e                	sd	s3,24(sp)
ffffffffc0201eae:	e852                	sd	s4,16(sp)
ffffffffc0201eb0:	e456                	sd	s5,8(sp)
        struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0201eb2:	1ca010ef          	jal	ra,ffffffffc020307c <kmalloc>
        if (mm != NULL) {
ffffffffc0201eb6:	58050e63          	beqz	a0,ffffffffc0202452 <vmm_init+0x5b4>
    elm->prev = elm->next = elm; // 将节点的前后指针都指向自己
ffffffffc0201eba:	e508                	sd	a0,8(a0)
ffffffffc0201ebc:	e108                	sd	a0,0(a0)
                mm->mmap_cache = NULL;
ffffffffc0201ebe:	00053823          	sd	zero,16(a0)
                mm->pgdir = NULL;
ffffffffc0201ec2:	00053c23          	sd	zero,24(a0)
                mm->map_count = 0;
ffffffffc0201ec6:	02052023          	sw	zero,32(a0)
                if (swap_init_ok) swap_init_mm(mm);
ffffffffc0201eca:	00014797          	auipc	a5,0x14
ffffffffc0201ece:	6d67a783          	lw	a5,1750(a5) # ffffffffc02165a0 <swap_init_ok>
ffffffffc0201ed2:	84aa                	mv	s1,a0
ffffffffc0201ed4:	e7b9                	bnez	a5,ffffffffc0201f22 <vmm_init+0x84>
                else mm->sm_priv = NULL;
ffffffffc0201ed6:	02053423          	sd	zero,40(a0)
vmm_init(void) {
ffffffffc0201eda:	03200413          	li	s0,50
ffffffffc0201ede:	a811                	j	ffffffffc0201ef2 <vmm_init+0x54>
                vma->vm_start = vm_start;
ffffffffc0201ee0:	e500                	sd	s0,8(a0)
                vma->vm_end = vm_end;
ffffffffc0201ee2:	e91c                	sd	a5,16(a0)
                vma->vm_flags = vm_flags;
ffffffffc0201ee4:	00052c23          	sw	zero,24(a0)
        assert(mm != NULL);

        int step1 = 10, step2 = step1 * 10;

        int i;
        for (i = step1; i >= 1; i --) {
ffffffffc0201ee8:	146d                	addi	s0,s0,-5
                struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
                assert(vma != NULL);
                insert_vma_struct(mm, vma);
ffffffffc0201eea:	8526                	mv	a0,s1
ffffffffc0201eec:	eb5ff0ef          	jal	ra,ffffffffc0201da0 <insert_vma_struct>
        for (i = step1; i >= 1; i --) {
ffffffffc0201ef0:	cc05                	beqz	s0,ffffffffc0201f28 <vmm_init+0x8a>
        struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0201ef2:	03000513          	li	a0,48
ffffffffc0201ef6:	186010ef          	jal	ra,ffffffffc020307c <kmalloc>
ffffffffc0201efa:	85aa                	mv	a1,a0
ffffffffc0201efc:	00240793          	addi	a5,s0,2
        if (vma != NULL) {
ffffffffc0201f00:	f165                	bnez	a0,ffffffffc0201ee0 <vmm_init+0x42>
                assert(vma != NULL);
ffffffffc0201f02:	00004697          	auipc	a3,0x4
ffffffffc0201f06:	25668693          	addi	a3,a3,598 # ffffffffc0206158 <commands+0xfa8>
ffffffffc0201f0a:	00004617          	auipc	a2,0x4
ffffffffc0201f0e:	b1660613          	addi	a2,a2,-1258 # ffffffffc0205a20 <commands+0x870>
ffffffffc0201f12:	0c600593          	li	a1,198
ffffffffc0201f16:	00004517          	auipc	a0,0x4
ffffffffc0201f1a:	fd250513          	addi	a0,a0,-46 # ffffffffc0205ee8 <commands+0xd38>
ffffffffc0201f1e:	aaafe0ef          	jal	ra,ffffffffc02001c8 <__panic>
                if (swap_init_ok) swap_init_mm(mm);
ffffffffc0201f22:	587000ef          	jal	ra,ffffffffc0202ca8 <swap_init_mm>
ffffffffc0201f26:	bf55                	j	ffffffffc0201eda <vmm_init+0x3c>
ffffffffc0201f28:	03700413          	li	s0,55
        }

        for (i = step1 + 1; i <= step2; i ++) {
ffffffffc0201f2c:	1f900913          	li	s2,505
ffffffffc0201f30:	a819                	j	ffffffffc0201f46 <vmm_init+0xa8>
                vma->vm_start = vm_start;
ffffffffc0201f32:	e500                	sd	s0,8(a0)
                vma->vm_end = vm_end;
ffffffffc0201f34:	e91c                	sd	a5,16(a0)
                vma->vm_flags = vm_flags;
ffffffffc0201f36:	00052c23          	sw	zero,24(a0)
        for (i = step1 + 1; i <= step2; i ++) {
ffffffffc0201f3a:	0415                	addi	s0,s0,5
                struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
                assert(vma != NULL);
                insert_vma_struct(mm, vma);
ffffffffc0201f3c:	8526                	mv	a0,s1
ffffffffc0201f3e:	e63ff0ef          	jal	ra,ffffffffc0201da0 <insert_vma_struct>
        for (i = step1 + 1; i <= step2; i ++) {
ffffffffc0201f42:	03240a63          	beq	s0,s2,ffffffffc0201f76 <vmm_init+0xd8>
        struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0201f46:	03000513          	li	a0,48
ffffffffc0201f4a:	132010ef          	jal	ra,ffffffffc020307c <kmalloc>
ffffffffc0201f4e:	85aa                	mv	a1,a0
ffffffffc0201f50:	00240793          	addi	a5,s0,2
        if (vma != NULL) {
ffffffffc0201f54:	fd79                	bnez	a0,ffffffffc0201f32 <vmm_init+0x94>
                assert(vma != NULL);
ffffffffc0201f56:	00004697          	auipc	a3,0x4
ffffffffc0201f5a:	20268693          	addi	a3,a3,514 # ffffffffc0206158 <commands+0xfa8>
ffffffffc0201f5e:	00004617          	auipc	a2,0x4
ffffffffc0201f62:	ac260613          	addi	a2,a2,-1342 # ffffffffc0205a20 <commands+0x870>
ffffffffc0201f66:	0cc00593          	li	a1,204
ffffffffc0201f6a:	00004517          	auipc	a0,0x4
ffffffffc0201f6e:	f7e50513          	addi	a0,a0,-130 # ffffffffc0205ee8 <commands+0xd38>
ffffffffc0201f72:	a56fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    return listelm->next; // 返回下一个节点
ffffffffc0201f76:	649c                	ld	a5,8(s1)
ffffffffc0201f78:	471d                	li	a4,7
        }

        list_entry_t *le = list_next(&(mm->mmap_list));

        for (i = 1; i <= step2; i ++) {
ffffffffc0201f7a:	1fb00593          	li	a1,507
                assert(le != &(mm->mmap_list));
ffffffffc0201f7e:	30f48e63          	beq	s1,a5,ffffffffc020229a <vmm_init+0x3fc>
                struct vma_struct *mmap = le2vma(le, list_link);
                assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0201f82:	fe87b683          	ld	a3,-24(a5)
ffffffffc0201f86:	ffe70613          	addi	a2,a4,-2 # fffffffffff7fffe <end+0x3fd69a32>
ffffffffc0201f8a:	2ad61863          	bne	a2,a3,ffffffffc020223a <vmm_init+0x39c>
ffffffffc0201f8e:	ff07b683          	ld	a3,-16(a5)
ffffffffc0201f92:	2ae69463          	bne	a3,a4,ffffffffc020223a <vmm_init+0x39c>
        for (i = 1; i <= step2; i ++) {
ffffffffc0201f96:	0715                	addi	a4,a4,5
ffffffffc0201f98:	679c                	ld	a5,8(a5)
ffffffffc0201f9a:	feb712e3          	bne	a4,a1,ffffffffc0201f7e <vmm_init+0xe0>
ffffffffc0201f9e:	4a1d                	li	s4,7
ffffffffc0201fa0:	4415                	li	s0,5
                le = list_next(le);
        }

        for (i = 5; i <= 5 * step2; i +=5) {
ffffffffc0201fa2:	1f900a93          	li	s5,505
                struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0201fa6:	85a2                	mv	a1,s0
ffffffffc0201fa8:	8526                	mv	a0,s1
ffffffffc0201faa:	db7ff0ef          	jal	ra,ffffffffc0201d60 <find_vma>
ffffffffc0201fae:	892a                	mv	s2,a0
                assert(vma1 != NULL);
ffffffffc0201fb0:	34050563          	beqz	a0,ffffffffc02022fa <vmm_init+0x45c>
                struct vma_struct *vma2 = find_vma(mm, i+1);
ffffffffc0201fb4:	00140593          	addi	a1,s0,1
ffffffffc0201fb8:	8526                	mv	a0,s1
ffffffffc0201fba:	da7ff0ef          	jal	ra,ffffffffc0201d60 <find_vma>
ffffffffc0201fbe:	89aa                	mv	s3,a0
                assert(vma2 != NULL);
ffffffffc0201fc0:	34050d63          	beqz	a0,ffffffffc020231a <vmm_init+0x47c>
                struct vma_struct *vma3 = find_vma(mm, i+2);
ffffffffc0201fc4:	85d2                	mv	a1,s4
ffffffffc0201fc6:	8526                	mv	a0,s1
ffffffffc0201fc8:	d99ff0ef          	jal	ra,ffffffffc0201d60 <find_vma>
                assert(vma3 == NULL);
ffffffffc0201fcc:	36051763          	bnez	a0,ffffffffc020233a <vmm_init+0x49c>
                struct vma_struct *vma4 = find_vma(mm, i+3);
ffffffffc0201fd0:	00340593          	addi	a1,s0,3
ffffffffc0201fd4:	8526                	mv	a0,s1
ffffffffc0201fd6:	d8bff0ef          	jal	ra,ffffffffc0201d60 <find_vma>
                assert(vma4 == NULL);
ffffffffc0201fda:	2e051063          	bnez	a0,ffffffffc02022ba <vmm_init+0x41c>
                struct vma_struct *vma5 = find_vma(mm, i+4);
ffffffffc0201fde:	00440593          	addi	a1,s0,4
ffffffffc0201fe2:	8526                	mv	a0,s1
ffffffffc0201fe4:	d7dff0ef          	jal	ra,ffffffffc0201d60 <find_vma>
                assert(vma5 == NULL);
ffffffffc0201fe8:	2e051963          	bnez	a0,ffffffffc02022da <vmm_init+0x43c>

                assert(vma1->vm_start == i  && vma1->vm_end == i  + 2);
ffffffffc0201fec:	00893783          	ld	a5,8(s2)
ffffffffc0201ff0:	26879563          	bne	a5,s0,ffffffffc020225a <vmm_init+0x3bc>
ffffffffc0201ff4:	01093783          	ld	a5,16(s2)
ffffffffc0201ff8:	27479163          	bne	a5,s4,ffffffffc020225a <vmm_init+0x3bc>
                assert(vma2->vm_start == i  && vma2->vm_end == i  + 2);
ffffffffc0201ffc:	0089b783          	ld	a5,8(s3)
ffffffffc0202000:	26879d63          	bne	a5,s0,ffffffffc020227a <vmm_init+0x3dc>
ffffffffc0202004:	0109b783          	ld	a5,16(s3)
ffffffffc0202008:	27479963          	bne	a5,s4,ffffffffc020227a <vmm_init+0x3dc>
        for (i = 5; i <= 5 * step2; i +=5) {
ffffffffc020200c:	0415                	addi	s0,s0,5
ffffffffc020200e:	0a15                	addi	s4,s4,5
ffffffffc0202010:	f9541be3          	bne	s0,s5,ffffffffc0201fa6 <vmm_init+0x108>
ffffffffc0202014:	4411                	li	s0,4
        }

        for (i =4; i>=0; i--) {
ffffffffc0202016:	597d                	li	s2,-1
                struct vma_struct *vma_below_5= find_vma(mm,i);
ffffffffc0202018:	85a2                	mv	a1,s0
ffffffffc020201a:	8526                	mv	a0,s1
ffffffffc020201c:	d45ff0ef          	jal	ra,ffffffffc0201d60 <find_vma>
ffffffffc0202020:	0004059b          	sext.w	a1,s0
                if (vma_below_5 != NULL ) {
ffffffffc0202024:	c90d                	beqz	a0,ffffffffc0202056 <vmm_init+0x1b8>
                     cprintf("vma_below_5: i %x, start %x, end %x\n",i, vma_below_5->vm_start, vma_below_5->vm_end); 
ffffffffc0202026:	6914                	ld	a3,16(a0)
ffffffffc0202028:	6510                	ld	a2,8(a0)
ffffffffc020202a:	00004517          	auipc	a0,0x4
ffffffffc020202e:	02e50513          	addi	a0,a0,46 # ffffffffc0206058 <commands+0xea8>
ffffffffc0202032:	89afe0ef          	jal	ra,ffffffffc02000cc <cprintf>
                }
                assert(vma_below_5 == NULL);
ffffffffc0202036:	00004697          	auipc	a3,0x4
ffffffffc020203a:	04a68693          	addi	a3,a3,74 # ffffffffc0206080 <commands+0xed0>
ffffffffc020203e:	00004617          	auipc	a2,0x4
ffffffffc0202042:	9e260613          	addi	a2,a2,-1566 # ffffffffc0205a20 <commands+0x870>
ffffffffc0202046:	0ee00593          	li	a1,238
ffffffffc020204a:	00004517          	auipc	a0,0x4
ffffffffc020204e:	e9e50513          	addi	a0,a0,-354 # ffffffffc0205ee8 <commands+0xd38>
ffffffffc0202052:	976fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
        for (i =4; i>=0; i--) {
ffffffffc0202056:	147d                	addi	s0,s0,-1
ffffffffc0202058:	fd2410e3          	bne	s0,s2,ffffffffc0202018 <vmm_init+0x17a>
ffffffffc020205c:	a801                	j	ffffffffc020206c <vmm_init+0x1ce>
    __list_del(listelm->prev, listelm->next); // 调用__list_del函数
ffffffffc020205e:	6118                	ld	a4,0(a0)
ffffffffc0202060:	651c                	ld	a5,8(a0)
                kfree(le2vma(le, list_link));  //释放vma        
ffffffffc0202062:	1501                	addi	a0,a0,-32
    prev->next = next; // 将前一个节点的下一个指针指向后一个节点
ffffffffc0202064:	e71c                	sd	a5,8(a4)
    next->prev = prev; // 将后一个节点的前一个指针指向前一个节点
ffffffffc0202066:	e398                	sd	a4,0(a5)
ffffffffc0202068:	0c4010ef          	jal	ra,ffffffffc020312c <kfree>
    return listelm->next; // 返回下一个节点
ffffffffc020206c:	6488                	ld	a0,8(s1)
        while ((le = list_next(list)) != list) {
ffffffffc020206e:	fea498e3          	bne	s1,a0,ffffffffc020205e <vmm_init+0x1c0>
        kfree(mm); //释放mm
ffffffffc0202072:	8526                	mv	a0,s1
ffffffffc0202074:	0b8010ef          	jal	ra,ffffffffc020312c <kfree>
        }

        mm_destroy(mm);

        cprintf("check_vma_struct() succeeded!\n");
ffffffffc0202078:	00004517          	auipc	a0,0x4
ffffffffc020207c:	02050513          	addi	a0,a0,32 # ffffffffc0206098 <commands+0xee8>
ffffffffc0202080:	84cfe0ef          	jal	ra,ffffffffc02000cc <cprintf>
struct mm_struct *check_mm_struct;

// check_pgfault - 检查页错误处理程序的正确性
static void
check_pgfault(void) {
        size_t nr_free_pages_store = nr_free_pages();
ffffffffc0202084:	bf9fe0ef          	jal	ra,ffffffffc0200c7c <nr_free_pages>
ffffffffc0202088:	84aa                	mv	s1,a0
        struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc020208a:	03000513          	li	a0,48
ffffffffc020208e:	7ef000ef          	jal	ra,ffffffffc020307c <kmalloc>
ffffffffc0202092:	842a                	mv	s0,a0
        if (mm != NULL) {
ffffffffc0202094:	2c050363          	beqz	a0,ffffffffc020235a <vmm_init+0x4bc>
                if (swap_init_ok) swap_init_mm(mm);
ffffffffc0202098:	00014797          	auipc	a5,0x14
ffffffffc020209c:	5087a783          	lw	a5,1288(a5) # ffffffffc02165a0 <swap_init_ok>
    elm->prev = elm->next = elm; // 将节点的前后指针都指向自己
ffffffffc02020a0:	e508                	sd	a0,8(a0)
ffffffffc02020a2:	e108                	sd	a0,0(a0)
                mm->mmap_cache = NULL;
ffffffffc02020a4:	00053823          	sd	zero,16(a0)
                mm->pgdir = NULL;
ffffffffc02020a8:	00053c23          	sd	zero,24(a0)
                mm->map_count = 0;
ffffffffc02020ac:	02052023          	sw	zero,32(a0)
                if (swap_init_ok) swap_init_mm(mm);
ffffffffc02020b0:	18079263          	bnez	a5,ffffffffc0202234 <vmm_init+0x396>
                else mm->sm_priv = NULL;
ffffffffc02020b4:	02053423          	sd	zero,40(a0)

        check_mm_struct = mm_create();
        assert(check_mm_struct != NULL);

        struct mm_struct *mm = check_mm_struct;
        pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc02020b8:	00014917          	auipc	s2,0x14
ffffffffc02020bc:	4a093903          	ld	s2,1184(s2) # ffffffffc0216558 <boot_pgdir>
        assert(pgdir[0] == 0);
ffffffffc02020c0:	00093783          	ld	a5,0(s2)
        check_mm_struct = mm_create();
ffffffffc02020c4:	00014717          	auipc	a4,0x14
ffffffffc02020c8:	4a873e23          	sd	s0,1212(a4) # ffffffffc0216580 <check_mm_struct>
        pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc02020cc:	01243c23          	sd	s2,24(s0)
        assert(pgdir[0] == 0);
ffffffffc02020d0:	36079163          	bnez	a5,ffffffffc0202432 <vmm_init+0x594>
        struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02020d4:	03000513          	li	a0,48
ffffffffc02020d8:	7a5000ef          	jal	ra,ffffffffc020307c <kmalloc>
ffffffffc02020dc:	89aa                	mv	s3,a0
        if (vma != NULL) {
ffffffffc02020de:	2a050263          	beqz	a0,ffffffffc0202382 <vmm_init+0x4e4>
                vma->vm_end = vm_end;
ffffffffc02020e2:	002007b7          	lui	a5,0x200
ffffffffc02020e6:	00f9b823          	sd	a5,16(s3)
                vma->vm_flags = vm_flags;
ffffffffc02020ea:	4789                	li	a5,2

        struct vma_struct *vma = vma_create(0, PTSIZE, VM_WRITE);
        assert(vma != NULL);

        insert_vma_struct(mm, vma);
ffffffffc02020ec:	85aa                	mv	a1,a0
                vma->vm_flags = vm_flags;
ffffffffc02020ee:	00f9ac23          	sw	a5,24(s3)
        insert_vma_struct(mm, vma);
ffffffffc02020f2:	8522                	mv	a0,s0
                vma->vm_start = vm_start;
ffffffffc02020f4:	0009b423          	sd	zero,8(s3)
        insert_vma_struct(mm, vma);
ffffffffc02020f8:	ca9ff0ef          	jal	ra,ffffffffc0201da0 <insert_vma_struct>

        uintptr_t addr = 0x100;
        assert(find_vma(mm, addr) == vma);
ffffffffc02020fc:	10000593          	li	a1,256
ffffffffc0202100:	8522                	mv	a0,s0
ffffffffc0202102:	c5fff0ef          	jal	ra,ffffffffc0201d60 <find_vma>
ffffffffc0202106:	10000793          	li	a5,256

        int i, sum = 0;
        for (i = 0; i < 100; i ++) {
ffffffffc020210a:	16400713          	li	a4,356
        assert(find_vma(mm, addr) == vma);
ffffffffc020210e:	28a99a63          	bne	s3,a0,ffffffffc02023a2 <vmm_init+0x504>
                *(char *)(addr + i) = i;
ffffffffc0202112:	00f78023          	sb	a5,0(a5) # 200000 <kern_entry-0xffffffffc0000000>
        for (i = 0; i < 100; i ++) {
ffffffffc0202116:	0785                	addi	a5,a5,1
ffffffffc0202118:	fee79de3          	bne	a5,a4,ffffffffc0202112 <vmm_init+0x274>
                sum += i;
ffffffffc020211c:	6705                	lui	a4,0x1
ffffffffc020211e:	10000793          	li	a5,256
ffffffffc0202122:	35670713          	addi	a4,a4,854 # 1356 <kern_entry-0xffffffffc01fecaa>
        }
        for (i = 0; i < 100; i ++) {
ffffffffc0202126:	16400613          	li	a2,356
                sum -= *(char *)(addr + i);
ffffffffc020212a:	0007c683          	lbu	a3,0(a5)
        for (i = 0; i < 100; i ++) {
ffffffffc020212e:	0785                	addi	a5,a5,1
                sum -= *(char *)(addr + i);
ffffffffc0202130:	9f15                	subw	a4,a4,a3
        for (i = 0; i < 100; i ++) {
ffffffffc0202132:	fec79ce3          	bne	a5,a2,ffffffffc020212a <vmm_init+0x28c>
        }
        assert(sum == 0);
ffffffffc0202136:	28071663          	bnez	a4,ffffffffc02023c2 <vmm_init+0x524>
    return pa2page(PDE_ADDR(pde));
ffffffffc020213a:	00093783          	ld	a5,0(s2)
    if (PPN(pa) >= npage) {
ffffffffc020213e:	00014a97          	auipc	s5,0x14
ffffffffc0202142:	422a8a93          	addi	s5,s5,1058 # ffffffffc0216560 <npage>
ffffffffc0202146:	000ab603          	ld	a2,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc020214a:	078a                	slli	a5,a5,0x2
ffffffffc020214c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020214e:	28c7fa63          	bgeu	a5,a2,ffffffffc02023e2 <vmm_init+0x544>
    return &pages[PPN(pa) - nbase];
ffffffffc0202152:	00005a17          	auipc	s4,0x5
ffffffffc0202156:	eb6a3a03          	ld	s4,-330(s4) # ffffffffc0207008 <nbase>
ffffffffc020215a:	414787b3          	sub	a5,a5,s4
ffffffffc020215e:	079a                	slli	a5,a5,0x6
    return page - pages + nbase;
ffffffffc0202160:	8799                	srai	a5,a5,0x6
ffffffffc0202162:	97d2                	add	a5,a5,s4
    return KADDR(page2pa(page));
ffffffffc0202164:	00c79713          	slli	a4,a5,0xc
ffffffffc0202168:	8331                	srli	a4,a4,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc020216a:	00c79693          	slli	a3,a5,0xc
    return KADDR(page2pa(page));
ffffffffc020216e:	28c77663          	bgeu	a4,a2,ffffffffc02023fa <vmm_init+0x55c>
ffffffffc0202172:	00014997          	auipc	s3,0x14
ffffffffc0202176:	4069b983          	ld	s3,1030(s3) # ffffffffc0216578 <va_pa_offset>

        pde_t *pd1=pgdir,*pd0=page2kva(pde2page(pgdir[0]));
        page_remove(pgdir, ROUNDDOWN(addr, PGSIZE));
ffffffffc020217a:	4581                	li	a1,0
ffffffffc020217c:	854a                	mv	a0,s2
ffffffffc020217e:	99b6                	add	s3,s3,a3
ffffffffc0202180:	d5dfe0ef          	jal	ra,ffffffffc0200edc <page_remove>
    return pa2page(PDE_ADDR(pde));
ffffffffc0202184:	0009b783          	ld	a5,0(s3)
    if (PPN(pa) >= npage) {
ffffffffc0202188:	000ab703          	ld	a4,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc020218c:	078a                	slli	a5,a5,0x2
ffffffffc020218e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202190:	24e7f963          	bgeu	a5,a4,ffffffffc02023e2 <vmm_init+0x544>
    return &pages[PPN(pa) - nbase];
ffffffffc0202194:	00014997          	auipc	s3,0x14
ffffffffc0202198:	3d498993          	addi	s3,s3,980 # ffffffffc0216568 <pages>
ffffffffc020219c:	0009b503          	ld	a0,0(s3)
ffffffffc02021a0:	414787b3          	sub	a5,a5,s4
ffffffffc02021a4:	079a                	slli	a5,a5,0x6
        free_page(pde2page(pd0[0]));
ffffffffc02021a6:	953e                	add	a0,a0,a5
ffffffffc02021a8:	4585                	li	a1,1
ffffffffc02021aa:	a93fe0ef          	jal	ra,ffffffffc0200c3c <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc02021ae:	00093783          	ld	a5,0(s2)
    if (PPN(pa) >= npage) {
ffffffffc02021b2:	000ab703          	ld	a4,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc02021b6:	078a                	slli	a5,a5,0x2
ffffffffc02021b8:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02021ba:	22e7f463          	bgeu	a5,a4,ffffffffc02023e2 <vmm_init+0x544>
    return &pages[PPN(pa) - nbase];
ffffffffc02021be:	0009b503          	ld	a0,0(s3)
ffffffffc02021c2:	414787b3          	sub	a5,a5,s4
ffffffffc02021c6:	079a                	slli	a5,a5,0x6
        free_page(pde2page(pd1[0]));
ffffffffc02021c8:	4585                	li	a1,1
ffffffffc02021ca:	953e                	add	a0,a0,a5
ffffffffc02021cc:	a71fe0ef          	jal	ra,ffffffffc0200c3c <free_pages>
        pgdir[0] = 0;
ffffffffc02021d0:	00093023          	sd	zero,0(s2)
  asm volatile("sfence.vma");
ffffffffc02021d4:	12000073          	sfence.vma
    return listelm->next; // 返回下一个节点
ffffffffc02021d8:	6408                	ld	a0,8(s0)
        flush_tlb();

        mm->pgdir = NULL;
ffffffffc02021da:	00043c23          	sd	zero,24(s0)
        while ((le = list_next(list)) != list) {
ffffffffc02021de:	00a40c63          	beq	s0,a0,ffffffffc02021f6 <vmm_init+0x358>
    __list_del(listelm->prev, listelm->next); // 调用__list_del函数
ffffffffc02021e2:	6118                	ld	a4,0(a0)
ffffffffc02021e4:	651c                	ld	a5,8(a0)
                kfree(le2vma(le, list_link));  //释放vma        
ffffffffc02021e6:	1501                	addi	a0,a0,-32
    prev->next = next; // 将前一个节点的下一个指针指向后一个节点
ffffffffc02021e8:	e71c                	sd	a5,8(a4)
    next->prev = prev; // 将后一个节点的前一个指针指向前一个节点
ffffffffc02021ea:	e398                	sd	a4,0(a5)
ffffffffc02021ec:	741000ef          	jal	ra,ffffffffc020312c <kfree>
    return listelm->next; // 返回下一个节点
ffffffffc02021f0:	6408                	ld	a0,8(s0)
        while ((le = list_next(list)) != list) {
ffffffffc02021f2:	fea418e3          	bne	s0,a0,ffffffffc02021e2 <vmm_init+0x344>
        kfree(mm); //释放mm
ffffffffc02021f6:	8522                	mv	a0,s0
ffffffffc02021f8:	735000ef          	jal	ra,ffffffffc020312c <kfree>
        mm_destroy(mm);
        check_mm_struct = NULL;
ffffffffc02021fc:	00014797          	auipc	a5,0x14
ffffffffc0202200:	3807b223          	sd	zero,900(a5) # ffffffffc0216580 <check_mm_struct>

        assert(nr_free_pages_store == nr_free_pages());
ffffffffc0202204:	a79fe0ef          	jal	ra,ffffffffc0200c7c <nr_free_pages>
ffffffffc0202208:	20a49563          	bne	s1,a0,ffffffffc0202412 <vmm_init+0x574>

        cprintf("check_pgfault() succeeded!\n");
ffffffffc020220c:	00004517          	auipc	a0,0x4
ffffffffc0202210:	f1450513          	addi	a0,a0,-236 # ffffffffc0206120 <commands+0xf70>
ffffffffc0202214:	eb9fd0ef          	jal	ra,ffffffffc02000cc <cprintf>
}
ffffffffc0202218:	7442                	ld	s0,48(sp)
ffffffffc020221a:	70e2                	ld	ra,56(sp)
ffffffffc020221c:	74a2                	ld	s1,40(sp)
ffffffffc020221e:	7902                	ld	s2,32(sp)
ffffffffc0202220:	69e2                	ld	s3,24(sp)
ffffffffc0202222:	6a42                	ld	s4,16(sp)
ffffffffc0202224:	6aa2                	ld	s5,8(sp)
        cprintf("check_vmm() succeeded.\n");
ffffffffc0202226:	00004517          	auipc	a0,0x4
ffffffffc020222a:	f1a50513          	addi	a0,a0,-230 # ffffffffc0206140 <commands+0xf90>
}
ffffffffc020222e:	6121                	addi	sp,sp,64
        cprintf("check_vmm() succeeded.\n");
ffffffffc0202230:	e9dfd06f          	j	ffffffffc02000cc <cprintf>
                if (swap_init_ok) swap_init_mm(mm);
ffffffffc0202234:	275000ef          	jal	ra,ffffffffc0202ca8 <swap_init_mm>
ffffffffc0202238:	b541                	j	ffffffffc02020b8 <vmm_init+0x21a>
                assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc020223a:	00004697          	auipc	a3,0x4
ffffffffc020223e:	d3668693          	addi	a3,a3,-714 # ffffffffc0205f70 <commands+0xdc0>
ffffffffc0202242:	00003617          	auipc	a2,0x3
ffffffffc0202246:	7de60613          	addi	a2,a2,2014 # ffffffffc0205a20 <commands+0x870>
ffffffffc020224a:	0d500593          	li	a1,213
ffffffffc020224e:	00004517          	auipc	a0,0x4
ffffffffc0202252:	c9a50513          	addi	a0,a0,-870 # ffffffffc0205ee8 <commands+0xd38>
ffffffffc0202256:	f73fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
                assert(vma1->vm_start == i  && vma1->vm_end == i  + 2);
ffffffffc020225a:	00004697          	auipc	a3,0x4
ffffffffc020225e:	d9e68693          	addi	a3,a3,-610 # ffffffffc0205ff8 <commands+0xe48>
ffffffffc0202262:	00003617          	auipc	a2,0x3
ffffffffc0202266:	7be60613          	addi	a2,a2,1982 # ffffffffc0205a20 <commands+0x870>
ffffffffc020226a:	0e500593          	li	a1,229
ffffffffc020226e:	00004517          	auipc	a0,0x4
ffffffffc0202272:	c7a50513          	addi	a0,a0,-902 # ffffffffc0205ee8 <commands+0xd38>
ffffffffc0202276:	f53fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
                assert(vma2->vm_start == i  && vma2->vm_end == i  + 2);
ffffffffc020227a:	00004697          	auipc	a3,0x4
ffffffffc020227e:	dae68693          	addi	a3,a3,-594 # ffffffffc0206028 <commands+0xe78>
ffffffffc0202282:	00003617          	auipc	a2,0x3
ffffffffc0202286:	79e60613          	addi	a2,a2,1950 # ffffffffc0205a20 <commands+0x870>
ffffffffc020228a:	0e600593          	li	a1,230
ffffffffc020228e:	00004517          	auipc	a0,0x4
ffffffffc0202292:	c5a50513          	addi	a0,a0,-934 # ffffffffc0205ee8 <commands+0xd38>
ffffffffc0202296:	f33fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
                assert(le != &(mm->mmap_list));
ffffffffc020229a:	00004697          	auipc	a3,0x4
ffffffffc020229e:	cbe68693          	addi	a3,a3,-834 # ffffffffc0205f58 <commands+0xda8>
ffffffffc02022a2:	00003617          	auipc	a2,0x3
ffffffffc02022a6:	77e60613          	addi	a2,a2,1918 # ffffffffc0205a20 <commands+0x870>
ffffffffc02022aa:	0d300593          	li	a1,211
ffffffffc02022ae:	00004517          	auipc	a0,0x4
ffffffffc02022b2:	c3a50513          	addi	a0,a0,-966 # ffffffffc0205ee8 <commands+0xd38>
ffffffffc02022b6:	f13fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
                assert(vma4 == NULL);
ffffffffc02022ba:	00004697          	auipc	a3,0x4
ffffffffc02022be:	d1e68693          	addi	a3,a3,-738 # ffffffffc0205fd8 <commands+0xe28>
ffffffffc02022c2:	00003617          	auipc	a2,0x3
ffffffffc02022c6:	75e60613          	addi	a2,a2,1886 # ffffffffc0205a20 <commands+0x870>
ffffffffc02022ca:	0e100593          	li	a1,225
ffffffffc02022ce:	00004517          	auipc	a0,0x4
ffffffffc02022d2:	c1a50513          	addi	a0,a0,-998 # ffffffffc0205ee8 <commands+0xd38>
ffffffffc02022d6:	ef3fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
                assert(vma5 == NULL);
ffffffffc02022da:	00004697          	auipc	a3,0x4
ffffffffc02022de:	d0e68693          	addi	a3,a3,-754 # ffffffffc0205fe8 <commands+0xe38>
ffffffffc02022e2:	00003617          	auipc	a2,0x3
ffffffffc02022e6:	73e60613          	addi	a2,a2,1854 # ffffffffc0205a20 <commands+0x870>
ffffffffc02022ea:	0e300593          	li	a1,227
ffffffffc02022ee:	00004517          	auipc	a0,0x4
ffffffffc02022f2:	bfa50513          	addi	a0,a0,-1030 # ffffffffc0205ee8 <commands+0xd38>
ffffffffc02022f6:	ed3fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
                assert(vma1 != NULL);
ffffffffc02022fa:	00004697          	auipc	a3,0x4
ffffffffc02022fe:	cae68693          	addi	a3,a3,-850 # ffffffffc0205fa8 <commands+0xdf8>
ffffffffc0202302:	00003617          	auipc	a2,0x3
ffffffffc0202306:	71e60613          	addi	a2,a2,1822 # ffffffffc0205a20 <commands+0x870>
ffffffffc020230a:	0db00593          	li	a1,219
ffffffffc020230e:	00004517          	auipc	a0,0x4
ffffffffc0202312:	bda50513          	addi	a0,a0,-1062 # ffffffffc0205ee8 <commands+0xd38>
ffffffffc0202316:	eb3fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
                assert(vma2 != NULL);
ffffffffc020231a:	00004697          	auipc	a3,0x4
ffffffffc020231e:	c9e68693          	addi	a3,a3,-866 # ffffffffc0205fb8 <commands+0xe08>
ffffffffc0202322:	00003617          	auipc	a2,0x3
ffffffffc0202326:	6fe60613          	addi	a2,a2,1790 # ffffffffc0205a20 <commands+0x870>
ffffffffc020232a:	0dd00593          	li	a1,221
ffffffffc020232e:	00004517          	auipc	a0,0x4
ffffffffc0202332:	bba50513          	addi	a0,a0,-1094 # ffffffffc0205ee8 <commands+0xd38>
ffffffffc0202336:	e93fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
                assert(vma3 == NULL);
ffffffffc020233a:	00004697          	auipc	a3,0x4
ffffffffc020233e:	c8e68693          	addi	a3,a3,-882 # ffffffffc0205fc8 <commands+0xe18>
ffffffffc0202342:	00003617          	auipc	a2,0x3
ffffffffc0202346:	6de60613          	addi	a2,a2,1758 # ffffffffc0205a20 <commands+0x870>
ffffffffc020234a:	0df00593          	li	a1,223
ffffffffc020234e:	00004517          	auipc	a0,0x4
ffffffffc0202352:	b9a50513          	addi	a0,a0,-1126 # ffffffffc0205ee8 <commands+0xd38>
ffffffffc0202356:	e73fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
        assert(check_mm_struct != NULL);
ffffffffc020235a:	00004697          	auipc	a3,0x4
ffffffffc020235e:	e0e68693          	addi	a3,a3,-498 # ffffffffc0206168 <commands+0xfb8>
ffffffffc0202362:	00003617          	auipc	a2,0x3
ffffffffc0202366:	6be60613          	addi	a2,a2,1726 # ffffffffc0205a20 <commands+0x870>
ffffffffc020236a:	0fe00593          	li	a1,254
ffffffffc020236e:	00004517          	auipc	a0,0x4
ffffffffc0202372:	b7a50513          	addi	a0,a0,-1158 # ffffffffc0205ee8 <commands+0xd38>
        check_mm_struct = mm_create();
ffffffffc0202376:	00014797          	auipc	a5,0x14
ffffffffc020237a:	2007b523          	sd	zero,522(a5) # ffffffffc0216580 <check_mm_struct>
        assert(check_mm_struct != NULL);
ffffffffc020237e:	e4bfd0ef          	jal	ra,ffffffffc02001c8 <__panic>
        assert(vma != NULL);
ffffffffc0202382:	00004697          	auipc	a3,0x4
ffffffffc0202386:	dd668693          	addi	a3,a3,-554 # ffffffffc0206158 <commands+0xfa8>
ffffffffc020238a:	00003617          	auipc	a2,0x3
ffffffffc020238e:	69660613          	addi	a2,a2,1686 # ffffffffc0205a20 <commands+0x870>
ffffffffc0202392:	10500593          	li	a1,261
ffffffffc0202396:	00004517          	auipc	a0,0x4
ffffffffc020239a:	b5250513          	addi	a0,a0,-1198 # ffffffffc0205ee8 <commands+0xd38>
ffffffffc020239e:	e2bfd0ef          	jal	ra,ffffffffc02001c8 <__panic>
        assert(find_vma(mm, addr) == vma);
ffffffffc02023a2:	00004697          	auipc	a3,0x4
ffffffffc02023a6:	d2668693          	addi	a3,a3,-730 # ffffffffc02060c8 <commands+0xf18>
ffffffffc02023aa:	00003617          	auipc	a2,0x3
ffffffffc02023ae:	67660613          	addi	a2,a2,1654 # ffffffffc0205a20 <commands+0x870>
ffffffffc02023b2:	10a00593          	li	a1,266
ffffffffc02023b6:	00004517          	auipc	a0,0x4
ffffffffc02023ba:	b3250513          	addi	a0,a0,-1230 # ffffffffc0205ee8 <commands+0xd38>
ffffffffc02023be:	e0bfd0ef          	jal	ra,ffffffffc02001c8 <__panic>
        assert(sum == 0);
ffffffffc02023c2:	00004697          	auipc	a3,0x4
ffffffffc02023c6:	d2668693          	addi	a3,a3,-730 # ffffffffc02060e8 <commands+0xf38>
ffffffffc02023ca:	00003617          	auipc	a2,0x3
ffffffffc02023ce:	65660613          	addi	a2,a2,1622 # ffffffffc0205a20 <commands+0x870>
ffffffffc02023d2:	11400593          	li	a1,276
ffffffffc02023d6:	00004517          	auipc	a0,0x4
ffffffffc02023da:	b1250513          	addi	a0,a0,-1262 # ffffffffc0205ee8 <commands+0xd38>
ffffffffc02023de:	debfd0ef          	jal	ra,ffffffffc02001c8 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02023e2:	00003617          	auipc	a2,0x3
ffffffffc02023e6:	4d660613          	addi	a2,a2,1238 # ffffffffc02058b8 <commands+0x708>
ffffffffc02023ea:	06000593          	li	a1,96
ffffffffc02023ee:	00003517          	auipc	a0,0x3
ffffffffc02023f2:	4ea50513          	addi	a0,a0,1258 # ffffffffc02058d8 <commands+0x728>
ffffffffc02023f6:	dd3fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    return KADDR(page2pa(page));
ffffffffc02023fa:	00003617          	auipc	a2,0x3
ffffffffc02023fe:	51660613          	addi	a2,a2,1302 # ffffffffc0205910 <commands+0x760>
ffffffffc0202402:	06700593          	li	a1,103
ffffffffc0202406:	00003517          	auipc	a0,0x3
ffffffffc020240a:	4d250513          	addi	a0,a0,1234 # ffffffffc02058d8 <commands+0x728>
ffffffffc020240e:	dbbfd0ef          	jal	ra,ffffffffc02001c8 <__panic>
        assert(nr_free_pages_store == nr_free_pages());
ffffffffc0202412:	00004697          	auipc	a3,0x4
ffffffffc0202416:	ce668693          	addi	a3,a3,-794 # ffffffffc02060f8 <commands+0xf48>
ffffffffc020241a:	00003617          	auipc	a2,0x3
ffffffffc020241e:	60660613          	addi	a2,a2,1542 # ffffffffc0205a20 <commands+0x870>
ffffffffc0202422:	12100593          	li	a1,289
ffffffffc0202426:	00004517          	auipc	a0,0x4
ffffffffc020242a:	ac250513          	addi	a0,a0,-1342 # ffffffffc0205ee8 <commands+0xd38>
ffffffffc020242e:	d9bfd0ef          	jal	ra,ffffffffc02001c8 <__panic>
        assert(pgdir[0] == 0);
ffffffffc0202432:	00004697          	auipc	a3,0x4
ffffffffc0202436:	c8668693          	addi	a3,a3,-890 # ffffffffc02060b8 <commands+0xf08>
ffffffffc020243a:	00003617          	auipc	a2,0x3
ffffffffc020243e:	5e660613          	addi	a2,a2,1510 # ffffffffc0205a20 <commands+0x870>
ffffffffc0202442:	10200593          	li	a1,258
ffffffffc0202446:	00004517          	auipc	a0,0x4
ffffffffc020244a:	aa250513          	addi	a0,a0,-1374 # ffffffffc0205ee8 <commands+0xd38>
ffffffffc020244e:	d7bfd0ef          	jal	ra,ffffffffc02001c8 <__panic>
        assert(mm != NULL);
ffffffffc0202452:	00004697          	auipc	a3,0x4
ffffffffc0202456:	d2e68693          	addi	a3,a3,-722 # ffffffffc0206180 <commands+0xfd0>
ffffffffc020245a:	00003617          	auipc	a2,0x3
ffffffffc020245e:	5c660613          	addi	a2,a2,1478 # ffffffffc0205a20 <commands+0x870>
ffffffffc0202462:	0bf00593          	li	a1,191
ffffffffc0202466:	00004517          	auipc	a0,0x4
ffffffffc020246a:	a8250513          	addi	a0,a0,-1406 # ffffffffc0205ee8 <commands+0xd38>
ffffffffc020246e:	d5bfd0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc0202472 <do_pgfault>:
 *         -- P标志（位0）指示异常是由于不存在的页面（0）还是由于访问权限违规或使用保留位（1）。
 *         -- W/R标志（位1）指示导致异常的内存访问是读取（0）还是写入（1）。
 *         -- U/S标志（位2）指示处理器在发生异常时是处于用户模式（1）还是监督模式（0）。
 */
int
do_pgfault(struct mm_struct *mm, uint32_t error_code, uintptr_t addr) {
ffffffffc0202472:	7179                	addi	sp,sp,-48
        int ret = -E_INVAL;
        // 尝试查找包含addr的vma
        struct vma_struct *vma = find_vma(mm, addr);
ffffffffc0202474:	85b2                	mv	a1,a2
do_pgfault(struct mm_struct *mm, uint32_t error_code, uintptr_t addr) {
ffffffffc0202476:	f022                	sd	s0,32(sp)
ffffffffc0202478:	ec26                	sd	s1,24(sp)
ffffffffc020247a:	f406                	sd	ra,40(sp)
ffffffffc020247c:	e84a                	sd	s2,16(sp)
ffffffffc020247e:	8432                	mv	s0,a2
ffffffffc0202480:	84aa                	mv	s1,a0
        struct vma_struct *vma = find_vma(mm, addr);
ffffffffc0202482:	8dfff0ef          	jal	ra,ffffffffc0201d60 <find_vma>

        pgfault_num++;
ffffffffc0202486:	00014797          	auipc	a5,0x14
ffffffffc020248a:	1027a783          	lw	a5,258(a5) # ffffffffc0216588 <pgfault_num>
ffffffffc020248e:	2785                	addiw	a5,a5,1
ffffffffc0202490:	00014717          	auipc	a4,0x14
ffffffffc0202494:	0ef72c23          	sw	a5,248(a4) # ffffffffc0216588 <pgfault_num>
        // 如果addr在mm的vma范围内？
        if (vma == NULL || vma->vm_start > addr) {
ffffffffc0202498:	c541                	beqz	a0,ffffffffc0202520 <do_pgfault+0xae>
ffffffffc020249a:	651c                	ld	a5,8(a0)
ffffffffc020249c:	08f46263          	bltu	s0,a5,ffffffffc0202520 <do_pgfault+0xae>
         *    （写入不存在的地址且地址可写）或
         *    （读取不存在的地址且地址可读）
         * 则继续处理
         */
        uint32_t perm = PTE_U;
        if (vma->vm_flags & VM_WRITE) {
ffffffffc02024a0:	4d1c                	lw	a5,24(a0)
        uint32_t perm = PTE_U;
ffffffffc02024a2:	4941                	li	s2,16
        if (vma->vm_flags & VM_WRITE) {
ffffffffc02024a4:	8b89                	andi	a5,a5,2
ffffffffc02024a6:	ebb9                	bnez	a5,ffffffffc02024fc <do_pgfault+0x8a>
                perm |= READ_WRITE;
        }
        addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc02024a8:	75fd                	lui	a1,0xfffff

        pte_t *ptep=NULL;
    
        // 尝试查找一个pte，如果pte的PT（页表）不存在，则创建一个PT。
        // （注意第三个参数'1'）
        if ((ptep = get_pte(mm->pgdir, addr, 1)) == NULL) {
ffffffffc02024aa:	6c88                	ld	a0,24(s1)
        addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc02024ac:	8c6d                	and	s0,s0,a1
        if ((ptep = get_pte(mm->pgdir, addr, 1)) == NULL) {
ffffffffc02024ae:	4605                	li	a2,1
ffffffffc02024b0:	85a2                	mv	a1,s0
ffffffffc02024b2:	805fe0ef          	jal	ra,ffffffffc0200cb6 <get_pte>
ffffffffc02024b6:	c551                	beqz	a0,ffffffffc0202542 <do_pgfault+0xd0>
                cprintf("get_pte in do_pgfault failed\n");
                goto failed;
        }
        if (*ptep == 0) { // 如果物理地址不存在，则分配一个页面并将物理地址与逻辑地址映射
ffffffffc02024b8:	610c                	ld	a1,0(a0)
ffffffffc02024ba:	c1b9                	beqz	a1,ffffffffc0202500 <do_pgfault+0x8e>
                *    swap_in(mm, addr, &page) : 分配一个内存页，然后根据
                *    PTE中的swap条目的addr，找到磁盘页的地址，将磁盘页的内容读入这个内存页
                *    page_insert ： 建立一个Page的phy addr与线性addr la的映射
                *    swap_map_swappable ： 设置页面可交换
                */
                if (swap_init_ok) {
ffffffffc02024bc:	00014797          	auipc	a5,0x14
ffffffffc02024c0:	0e47a783          	lw	a5,228(a5) # ffffffffc02165a0 <swap_init_ok>
ffffffffc02024c4:	c7bd                	beqz	a5,ffffffffc0202532 <do_pgfault+0xc0>
                        struct Page *page = NULL;
                        // 根据mm和addr，尝试将正确的磁盘页面内容加载到page管理的内存中
                        swap_in(mm, addr, &page); 
ffffffffc02024c6:	85a2                	mv	a1,s0
ffffffffc02024c8:	0030                	addi	a2,sp,8
ffffffffc02024ca:	8526                	mv	a0,s1
                        struct Page *page = NULL;
ffffffffc02024cc:	e402                	sd	zero,8(sp)
                        swap_in(mm, addr, &page); 
ffffffffc02024ce:	107000ef          	jal	ra,ffffffffc0202dd4 <swap_in>
                        // 根据mm、addr和page，设置物理地址与逻辑地址的映射
                        page_insert(mm->pgdir, page, addr, perm); // 更新页表，插入新的页表项
ffffffffc02024d2:	65a2                	ld	a1,8(sp)
ffffffffc02024d4:	6c88                	ld	a0,24(s1)
ffffffffc02024d6:	86ca                	mv	a3,s2
ffffffffc02024d8:	8622                	mv	a2,s0
ffffffffc02024da:	a9ffe0ef          	jal	ra,ffffffffc0200f78 <page_insert>

                        // 使页面可交换
                        swap_map_swappable(mm, addr, page, 1);
ffffffffc02024de:	6622                	ld	a2,8(sp)
ffffffffc02024e0:	4685                	li	a3,1
ffffffffc02024e2:	85a2                	mv	a1,s0
ffffffffc02024e4:	8526                	mv	a0,s1
ffffffffc02024e6:	7ce000ef          	jal	ra,ffffffffc0202cb4 <swap_map_swappable>

                        page->pra_vaddr = addr;
ffffffffc02024ea:	67a2                	ld	a5,8(sp)
                        cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
                        goto failed;
                }
     }

     ret = 0;
ffffffffc02024ec:	4501                	li	a0,0
                        page->pra_vaddr = addr;
ffffffffc02024ee:	ff80                	sd	s0,56(a5)
failed:
        return ret;
}
ffffffffc02024f0:	70a2                	ld	ra,40(sp)
ffffffffc02024f2:	7402                	ld	s0,32(sp)
ffffffffc02024f4:	64e2                	ld	s1,24(sp)
ffffffffc02024f6:	6942                	ld	s2,16(sp)
ffffffffc02024f8:	6145                	addi	sp,sp,48
ffffffffc02024fa:	8082                	ret
                perm |= READ_WRITE;
ffffffffc02024fc:	495d                	li	s2,23
ffffffffc02024fe:	b76d                	j	ffffffffc02024a8 <do_pgfault+0x36>
                if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {
ffffffffc0202500:	6c88                	ld	a0,24(s1)
ffffffffc0202502:	864a                	mv	a2,s2
ffffffffc0202504:	85a2                	mv	a1,s0
ffffffffc0202506:	f08ff0ef          	jal	ra,ffffffffc0201c0e <pgdir_alloc_page>
ffffffffc020250a:	87aa                	mv	a5,a0
     ret = 0;
ffffffffc020250c:	4501                	li	a0,0
                if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {
ffffffffc020250e:	f3ed                	bnez	a5,ffffffffc02024f0 <do_pgfault+0x7e>
                        cprintf("pgdir_alloc_page in do_pgfault failed\n");
ffffffffc0202510:	00004517          	auipc	a0,0x4
ffffffffc0202514:	cd050513          	addi	a0,a0,-816 # ffffffffc02061e0 <commands+0x1030>
ffffffffc0202518:	bb5fd0ef          	jal	ra,ffffffffc02000cc <cprintf>
        ret = -E_NO_MEM;
ffffffffc020251c:	5571                	li	a0,-4
                        goto failed;
ffffffffc020251e:	bfc9                	j	ffffffffc02024f0 <do_pgfault+0x7e>
                cprintf("not valid addr %x, and  can not find it in vma\n", addr);
ffffffffc0202520:	85a2                	mv	a1,s0
ffffffffc0202522:	00004517          	auipc	a0,0x4
ffffffffc0202526:	c6e50513          	addi	a0,a0,-914 # ffffffffc0206190 <commands+0xfe0>
ffffffffc020252a:	ba3fd0ef          	jal	ra,ffffffffc02000cc <cprintf>
        int ret = -E_INVAL;
ffffffffc020252e:	5575                	li	a0,-3
                goto failed;
ffffffffc0202530:	b7c1                	j	ffffffffc02024f0 <do_pgfault+0x7e>
                        cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
ffffffffc0202532:	00004517          	auipc	a0,0x4
ffffffffc0202536:	cd650513          	addi	a0,a0,-810 # ffffffffc0206208 <commands+0x1058>
ffffffffc020253a:	b93fd0ef          	jal	ra,ffffffffc02000cc <cprintf>
        ret = -E_NO_MEM;
ffffffffc020253e:	5571                	li	a0,-4
                        goto failed;
ffffffffc0202540:	bf45                	j	ffffffffc02024f0 <do_pgfault+0x7e>
                cprintf("get_pte in do_pgfault failed\n");
ffffffffc0202542:	00004517          	auipc	a0,0x4
ffffffffc0202546:	c7e50513          	addi	a0,a0,-898 # ffffffffc02061c0 <commands+0x1010>
ffffffffc020254a:	b83fd0ef          	jal	ra,ffffffffc02000cc <cprintf>
        ret = -E_NO_MEM;
ffffffffc020254e:	5571                	li	a0,-4
                goto failed;
ffffffffc0202550:	b745                	j	ffffffffc02024f0 <do_pgfault+0x7e>

ffffffffc0202552 <pa2page.part.0>:
pa2page(uintptr_t pa) { // 将物理地址转换为 Page
ffffffffc0202552:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0202554:	00003617          	auipc	a2,0x3
ffffffffc0202558:	36460613          	addi	a2,a2,868 # ffffffffc02058b8 <commands+0x708>
ffffffffc020255c:	06000593          	li	a1,96
ffffffffc0202560:	00003517          	auipc	a0,0x3
ffffffffc0202564:	37850513          	addi	a0,a0,888 # ffffffffc02058d8 <commands+0x728>
pa2page(uintptr_t pa) { // 将物理地址转换为 Page
ffffffffc0202568:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc020256a:	c5ffd0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc020256e <swap_init>:

// swap_init - 初始化交换管理器
// 返回值：初始化成功返回0，失败返回非0
int
swap_init(void)
{
ffffffffc020256e:	7135                	addi	sp,sp,-160
ffffffffc0202570:	ed06                	sd	ra,152(sp)
ffffffffc0202572:	e922                	sd	s0,144(sp)
ffffffffc0202574:	e526                	sd	s1,136(sp)
ffffffffc0202576:	e14a                	sd	s2,128(sp)
ffffffffc0202578:	fcce                	sd	s3,120(sp)
ffffffffc020257a:	f8d2                	sd	s4,112(sp)
ffffffffc020257c:	f4d6                	sd	s5,104(sp)
ffffffffc020257e:	f0da                	sd	s6,96(sp)
ffffffffc0202580:	ecde                	sd	s7,88(sp)
ffffffffc0202582:	e8e2                	sd	s8,80(sp)
ffffffffc0202584:	e4e6                	sd	s9,72(sp)
ffffffffc0202586:	e0ea                	sd	s10,64(sp)
ffffffffc0202588:	fc6e                	sd	s11,56(sp)
     swapfs_init(); // 初始化交换文件系统
ffffffffc020258a:	339010ef          	jal	ra,ffffffffc02040c2 <swapfs_init>
     // if (!(1024 <= max_swap_offset && max_swap_offset < MAX_SWAP_OFFSET_LIMIT))
     // {
     //      panic("bad max_swap_offset %08x.\n", max_swap_offset);
     // }
     // Since the IDE is faked, it can only store 7 pages at most to pass the test
     if (!(7 <= max_swap_offset &&
ffffffffc020258e:	00014697          	auipc	a3,0x14
ffffffffc0202592:	0026b683          	ld	a3,2(a3) # ffffffffc0216590 <max_swap_offset>
ffffffffc0202596:	010007b7          	lui	a5,0x1000
ffffffffc020259a:	ff968713          	addi	a4,a3,-7
ffffffffc020259e:	17e1                	addi	a5,a5,-8
ffffffffc02025a0:	42e7e063          	bltu	a5,a4,ffffffffc02029c0 <swap_init+0x452>
        max_swap_offset < MAX_SWAP_OFFSET_LIMIT)) {
        panic("bad max_swap_offset %08x.\n", max_swap_offset);
     }

     sm = &swap_manager_fifo; // 使用FIFO算法作为交换管理器
ffffffffc02025a4:	00009797          	auipc	a5,0x9
ffffffffc02025a8:	a6c78793          	addi	a5,a5,-1428 # ffffffffc020b010 <swap_manager_fifo>
     int r = sm->init(); // 初始化交换管理器
ffffffffc02025ac:	6798                	ld	a4,8(a5)
     sm = &swap_manager_fifo; // 使用FIFO算法作为交换管理器
ffffffffc02025ae:	00014b97          	auipc	s7,0x14
ffffffffc02025b2:	feab8b93          	addi	s7,s7,-22 # ffffffffc0216598 <sm>
ffffffffc02025b6:	00fbb023          	sd	a5,0(s7)
     int r = sm->init(); // 初始化交换管理器
ffffffffc02025ba:	9702                	jalr	a4
ffffffffc02025bc:	892a                	mv	s2,a0
     
     if (r == 0)
ffffffffc02025be:	c10d                	beqz	a0,ffffffffc02025e0 <swap_init+0x72>
          cprintf("SWAP: manager = %s\n", sm->name);
          check_swap(); // 检查交换功能
     }

     return r;
}
ffffffffc02025c0:	60ea                	ld	ra,152(sp)
ffffffffc02025c2:	644a                	ld	s0,144(sp)
ffffffffc02025c4:	64aa                	ld	s1,136(sp)
ffffffffc02025c6:	79e6                	ld	s3,120(sp)
ffffffffc02025c8:	7a46                	ld	s4,112(sp)
ffffffffc02025ca:	7aa6                	ld	s5,104(sp)
ffffffffc02025cc:	7b06                	ld	s6,96(sp)
ffffffffc02025ce:	6be6                	ld	s7,88(sp)
ffffffffc02025d0:	6c46                	ld	s8,80(sp)
ffffffffc02025d2:	6ca6                	ld	s9,72(sp)
ffffffffc02025d4:	6d06                	ld	s10,64(sp)
ffffffffc02025d6:	7de2                	ld	s11,56(sp)
ffffffffc02025d8:	854a                	mv	a0,s2
ffffffffc02025da:	690a                	ld	s2,128(sp)
ffffffffc02025dc:	610d                	addi	sp,sp,160
ffffffffc02025de:	8082                	ret
          cprintf("SWAP: manager = %s\n", sm->name);
ffffffffc02025e0:	000bb783          	ld	a5,0(s7)
ffffffffc02025e4:	00004517          	auipc	a0,0x4
ffffffffc02025e8:	c7c50513          	addi	a0,a0,-900 # ffffffffc0206260 <commands+0x10b0>
ffffffffc02025ec:	00010417          	auipc	s0,0x10
ffffffffc02025f0:	f1440413          	addi	s0,s0,-236 # ffffffffc0212500 <free_area>
ffffffffc02025f4:	638c                	ld	a1,0(a5)
          swap_init_ok = 1;
ffffffffc02025f6:	4785                	li	a5,1
ffffffffc02025f8:	00014717          	auipc	a4,0x14
ffffffffc02025fc:	faf72423          	sw	a5,-88(a4) # ffffffffc02165a0 <swap_init_ok>
          cprintf("SWAP: manager = %s\n", sm->name);
ffffffffc0202600:	acdfd0ef          	jal	ra,ffffffffc02000cc <cprintf>
ffffffffc0202604:	641c                	ld	a5,8(s0)
// check_swap - 检查交换功能
static void
check_swap(void)
{
    //backup mem env
     int ret, count = 0, total = 0, i;
ffffffffc0202606:	4d01                	li	s10,0
ffffffffc0202608:	4d81                	li	s11,0
     list_entry_t *le = &free_list;
     while ((le = list_next(le)) != &free_list) {
ffffffffc020260a:	32878b63          	beq	a5,s0,ffffffffc0202940 <swap_init+0x3d2>
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc020260e:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0202612:	8b09                	andi	a4,a4,2
ffffffffc0202614:	32070863          	beqz	a4,ffffffffc0202944 <swap_init+0x3d6>
        count ++, total += p->property;
ffffffffc0202618:	ff87a703          	lw	a4,-8(a5)
ffffffffc020261c:	679c                	ld	a5,8(a5)
ffffffffc020261e:	2d85                	addiw	s11,s11,1
ffffffffc0202620:	01a70d3b          	addw	s10,a4,s10
     while ((le = list_next(le)) != &free_list) {
ffffffffc0202624:	fe8795e3          	bne	a5,s0,ffffffffc020260e <swap_init+0xa0>
     }
     assert(total == nr_free_pages());
ffffffffc0202628:	84ea                	mv	s1,s10
ffffffffc020262a:	e52fe0ef          	jal	ra,ffffffffc0200c7c <nr_free_pages>
ffffffffc020262e:	42951163          	bne	a0,s1,ffffffffc0202a50 <swap_init+0x4e2>
     cprintf("BEGIN check_swap: count %d, total %d\n",count,total);
ffffffffc0202632:	866a                	mv	a2,s10
ffffffffc0202634:	85ee                	mv	a1,s11
ffffffffc0202636:	00004517          	auipc	a0,0x4
ffffffffc020263a:	c7250513          	addi	a0,a0,-910 # ffffffffc02062a8 <commands+0x10f8>
ffffffffc020263e:	a8ffd0ef          	jal	ra,ffffffffc02000cc <cprintf>
     
     //now we set the phy pages env     
     struct mm_struct *mm = mm_create(); // 创建内存管理结构
ffffffffc0202642:	ea8ff0ef          	jal	ra,ffffffffc0201cea <mm_create>
ffffffffc0202646:	8aaa                	mv	s5,a0
     assert(mm != NULL);
ffffffffc0202648:	46050463          	beqz	a0,ffffffffc0202ab0 <swap_init+0x542>

     extern struct mm_struct *check_mm_struct;
     assert(check_mm_struct == NULL);
ffffffffc020264c:	00014797          	auipc	a5,0x14
ffffffffc0202650:	f3478793          	addi	a5,a5,-204 # ffffffffc0216580 <check_mm_struct>
ffffffffc0202654:	6398                	ld	a4,0(a5)
ffffffffc0202656:	3c071d63          	bnez	a4,ffffffffc0202a30 <swap_init+0x4c2>

     check_mm_struct = mm;

     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc020265a:	00014717          	auipc	a4,0x14
ffffffffc020265e:	efe70713          	addi	a4,a4,-258 # ffffffffc0216558 <boot_pgdir>
ffffffffc0202662:	00073b03          	ld	s6,0(a4)
     check_mm_struct = mm;
ffffffffc0202666:	e388                	sd	a0,0(a5)
     assert(pgdir[0] == 0);
ffffffffc0202668:	000b3783          	ld	a5,0(s6)
     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc020266c:	01653c23          	sd	s6,24(a0)
     assert(pgdir[0] == 0);
ffffffffc0202670:	42079063          	bnez	a5,ffffffffc0202a90 <swap_init+0x522>

     struct vma_struct *vma = vma_create(BEING_CHECK_VALID_VADDR, CHECK_VALID_VADDR, VM_WRITE | VM_READ); // 创建虚拟内存区域
ffffffffc0202674:	6599                	lui	a1,0x6
ffffffffc0202676:	460d                	li	a2,3
ffffffffc0202678:	6505                	lui	a0,0x1
ffffffffc020267a:	eb8ff0ef          	jal	ra,ffffffffc0201d32 <vma_create>
ffffffffc020267e:	85aa                	mv	a1,a0
     assert(vma != NULL);
ffffffffc0202680:	52050463          	beqz	a0,ffffffffc0202ba8 <swap_init+0x63a>

     insert_vma_struct(mm, vma); // 插入虚拟内存区域
ffffffffc0202684:	8556                	mv	a0,s5
ffffffffc0202686:	f1aff0ef          	jal	ra,ffffffffc0201da0 <insert_vma_struct>

     //setup the temp Page Table vaddr 0~4MB
     cprintf("setup Page Table for vaddr 0X1000, so alloc a page\n");
ffffffffc020268a:	00004517          	auipc	a0,0x4
ffffffffc020268e:	c5e50513          	addi	a0,a0,-930 # ffffffffc02062e8 <commands+0x1138>
ffffffffc0202692:	a3bfd0ef          	jal	ra,ffffffffc02000cc <cprintf>
     pte_t *temp_ptep=NULL;
     temp_ptep = get_pte(mm->pgdir, BEING_CHECK_VALID_VADDR, 1); // 获取页表项指针
ffffffffc0202696:	018ab503          	ld	a0,24(s5)
ffffffffc020269a:	4605                	li	a2,1
ffffffffc020269c:	6585                	lui	a1,0x1
ffffffffc020269e:	e18fe0ef          	jal	ra,ffffffffc0200cb6 <get_pte>
     assert(temp_ptep!= NULL);
ffffffffc02026a2:	4c050363          	beqz	a0,ffffffffc0202b68 <swap_init+0x5fa>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc02026a6:	00004517          	auipc	a0,0x4
ffffffffc02026aa:	c9250513          	addi	a0,a0,-878 # ffffffffc0206338 <commands+0x1188>
ffffffffc02026ae:	00010497          	auipc	s1,0x10
ffffffffc02026b2:	dd248493          	addi	s1,s1,-558 # ffffffffc0212480 <check_rp>
ffffffffc02026b6:	a17fd0ef          	jal	ra,ffffffffc02000cc <cprintf>
     
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc02026ba:	00010997          	auipc	s3,0x10
ffffffffc02026be:	de698993          	addi	s3,s3,-538 # ffffffffc02124a0 <swap_in_seq_no>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc02026c2:	8a26                	mv	s4,s1
          check_rp[i] = alloc_page(); // 分配页面
ffffffffc02026c4:	4505                	li	a0,1
ffffffffc02026c6:	ce4fe0ef          	jal	ra,ffffffffc0200baa <alloc_pages>
ffffffffc02026ca:	00aa3023          	sd	a0,0(s4)
          assert(check_rp[i] != NULL );
ffffffffc02026ce:	2c050963          	beqz	a0,ffffffffc02029a0 <swap_init+0x432>
ffffffffc02026d2:	651c                	ld	a5,8(a0)
          assert(!PageProperty(check_rp[i]));
ffffffffc02026d4:	8b89                	andi	a5,a5,2
ffffffffc02026d6:	32079d63          	bnez	a5,ffffffffc0202a10 <swap_init+0x4a2>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc02026da:	0a21                	addi	s4,s4,8
ffffffffc02026dc:	ff3a14e3          	bne	s4,s3,ffffffffc02026c4 <swap_init+0x156>
     }
     list_entry_t free_list_store = free_list;
ffffffffc02026e0:	601c                	ld	a5,0(s0)
     assert(list_empty(&free_list));
     
     //assert(alloc_page() == NULL);
     
     unsigned int nr_free_store = nr_free;
     nr_free = 0;
ffffffffc02026e2:	00010a17          	auipc	s4,0x10
ffffffffc02026e6:	d9ea0a13          	addi	s4,s4,-610 # ffffffffc0212480 <check_rp>
    elm->prev = elm->next = elm; // 将节点的前后指针都指向自己
ffffffffc02026ea:	e000                	sd	s0,0(s0)
     list_entry_t free_list_store = free_list;
ffffffffc02026ec:	ec3e                	sd	a5,24(sp)
ffffffffc02026ee:	641c                	ld	a5,8(s0)
ffffffffc02026f0:	e400                	sd	s0,8(s0)
ffffffffc02026f2:	f03e                	sd	a5,32(sp)
     unsigned int nr_free_store = nr_free;
ffffffffc02026f4:	481c                	lw	a5,16(s0)
ffffffffc02026f6:	f43e                	sd	a5,40(sp)
     nr_free = 0;
ffffffffc02026f8:	00010797          	auipc	a5,0x10
ffffffffc02026fc:	e007ac23          	sw	zero,-488(a5) # ffffffffc0212510 <free_area+0x10>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
        free_pages(check_rp[i],1); // 释放页面
ffffffffc0202700:	000a3503          	ld	a0,0(s4)
ffffffffc0202704:	4585                	li	a1,1
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0202706:	0a21                	addi	s4,s4,8
        free_pages(check_rp[i],1); // 释放页面
ffffffffc0202708:	d34fe0ef          	jal	ra,ffffffffc0200c3c <free_pages>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc020270c:	ff3a1ae3          	bne	s4,s3,ffffffffc0202700 <swap_init+0x192>
     }
     assert(nr_free==CHECK_VALID_PHY_PAGE_NUM);
ffffffffc0202710:	01042a03          	lw	s4,16(s0)
ffffffffc0202714:	4791                	li	a5,4
ffffffffc0202716:	42fa1963          	bne	s4,a5,ffffffffc0202b48 <swap_init+0x5da>
     
     cprintf("set up init env for check_swap begin!\n");
ffffffffc020271a:	00004517          	auipc	a0,0x4
ffffffffc020271e:	ca650513          	addi	a0,a0,-858 # ffffffffc02063c0 <commands+0x1210>
ffffffffc0202722:	9abfd0ef          	jal	ra,ffffffffc02000cc <cprintf>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc0202726:	6705                	lui	a4,0x1
     //setup initial vir_page<->phy_page environment for page relpacement algorithm 

     
     pgfault_num=0;
ffffffffc0202728:	00014797          	auipc	a5,0x14
ffffffffc020272c:	e607a023          	sw	zero,-416(a5) # ffffffffc0216588 <pgfault_num>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc0202730:	4629                	li	a2,10
ffffffffc0202732:	00c70023          	sb	a2,0(a4) # 1000 <kern_entry-0xffffffffc01ff000>
     assert(pgfault_num==1);
ffffffffc0202736:	00014697          	auipc	a3,0x14
ffffffffc020273a:	e526a683          	lw	a3,-430(a3) # ffffffffc0216588 <pgfault_num>
ffffffffc020273e:	4585                	li	a1,1
ffffffffc0202740:	00014797          	auipc	a5,0x14
ffffffffc0202744:	e4878793          	addi	a5,a5,-440 # ffffffffc0216588 <pgfault_num>
ffffffffc0202748:	54b69063          	bne	a3,a1,ffffffffc0202c88 <swap_init+0x71a>
     *(unsigned char *)0x1010 = 0x0a;
ffffffffc020274c:	00c70823          	sb	a2,16(a4)
     assert(pgfault_num==1);
ffffffffc0202750:	4398                	lw	a4,0(a5)
ffffffffc0202752:	2701                	sext.w	a4,a4
ffffffffc0202754:	3cd71a63          	bne	a4,a3,ffffffffc0202b28 <swap_init+0x5ba>
     *(unsigned char *)0x2000 = 0x0b;
ffffffffc0202758:	6689                	lui	a3,0x2
ffffffffc020275a:	462d                	li	a2,11
ffffffffc020275c:	00c68023          	sb	a2,0(a3) # 2000 <kern_entry-0xffffffffc01fe000>
     assert(pgfault_num==2);
ffffffffc0202760:	4398                	lw	a4,0(a5)
ffffffffc0202762:	4589                	li	a1,2
ffffffffc0202764:	2701                	sext.w	a4,a4
ffffffffc0202766:	4ab71163          	bne	a4,a1,ffffffffc0202c08 <swap_init+0x69a>
     *(unsigned char *)0x2010 = 0x0b;
ffffffffc020276a:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==2);
ffffffffc020276e:	4394                	lw	a3,0(a5)
ffffffffc0202770:	2681                	sext.w	a3,a3
ffffffffc0202772:	4ae69b63          	bne	a3,a4,ffffffffc0202c28 <swap_init+0x6ba>
     *(unsigned char *)0x3000 = 0x0c;
ffffffffc0202776:	668d                	lui	a3,0x3
ffffffffc0202778:	4631                	li	a2,12
ffffffffc020277a:	00c68023          	sb	a2,0(a3) # 3000 <kern_entry-0xffffffffc01fd000>
     assert(pgfault_num==3);
ffffffffc020277e:	4398                	lw	a4,0(a5)
ffffffffc0202780:	458d                	li	a1,3
ffffffffc0202782:	2701                	sext.w	a4,a4
ffffffffc0202784:	4cb71263          	bne	a4,a1,ffffffffc0202c48 <swap_init+0x6da>
     *(unsigned char *)0x3010 = 0x0c;
ffffffffc0202788:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==3);
ffffffffc020278c:	4394                	lw	a3,0(a5)
ffffffffc020278e:	2681                	sext.w	a3,a3
ffffffffc0202790:	4ce69c63          	bne	a3,a4,ffffffffc0202c68 <swap_init+0x6fa>
     *(unsigned char *)0x4000 = 0x0d;
ffffffffc0202794:	6691                	lui	a3,0x4
ffffffffc0202796:	4635                	li	a2,13
ffffffffc0202798:	00c68023          	sb	a2,0(a3) # 4000 <kern_entry-0xffffffffc01fc000>
     assert(pgfault_num==4);
ffffffffc020279c:	4398                	lw	a4,0(a5)
ffffffffc020279e:	2701                	sext.w	a4,a4
ffffffffc02027a0:	43471463          	bne	a4,s4,ffffffffc0202bc8 <swap_init+0x65a>
     *(unsigned char *)0x4010 = 0x0d;
ffffffffc02027a4:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==4);
ffffffffc02027a8:	439c                	lw	a5,0(a5)
ffffffffc02027aa:	2781                	sext.w	a5,a5
ffffffffc02027ac:	42e79e63          	bne	a5,a4,ffffffffc0202be8 <swap_init+0x67a>
     
     check_content_set(); // 设置检查内容
     assert( nr_free == 0);         
ffffffffc02027b0:	481c                	lw	a5,16(s0)
ffffffffc02027b2:	2a079f63          	bnez	a5,ffffffffc0202a70 <swap_init+0x502>
ffffffffc02027b6:	00010797          	auipc	a5,0x10
ffffffffc02027ba:	cea78793          	addi	a5,a5,-790 # ffffffffc02124a0 <swap_in_seq_no>
ffffffffc02027be:	00010717          	auipc	a4,0x10
ffffffffc02027c2:	d0a70713          	addi	a4,a4,-758 # ffffffffc02124c8 <swap_out_seq_no>
ffffffffc02027c6:	00010617          	auipc	a2,0x10
ffffffffc02027ca:	d0260613          	addi	a2,a2,-766 # ffffffffc02124c8 <swap_out_seq_no>
     for(i = 0; i<MAX_SEQ_NO ; i++) 
         swap_out_seq_no[i]=swap_in_seq_no[i]=-1;
ffffffffc02027ce:	56fd                	li	a3,-1
ffffffffc02027d0:	c394                	sw	a3,0(a5)
ffffffffc02027d2:	c314                	sw	a3,0(a4)
     for(i = 0; i<MAX_SEQ_NO ; i++) 
ffffffffc02027d4:	0791                	addi	a5,a5,4
ffffffffc02027d6:	0711                	addi	a4,a4,4
ffffffffc02027d8:	fec79ce3          	bne	a5,a2,ffffffffc02027d0 <swap_init+0x262>
ffffffffc02027dc:	00010717          	auipc	a4,0x10
ffffffffc02027e0:	c8470713          	addi	a4,a4,-892 # ffffffffc0212460 <check_ptep>
ffffffffc02027e4:	00010697          	auipc	a3,0x10
ffffffffc02027e8:	c9c68693          	addi	a3,a3,-868 # ffffffffc0212480 <check_rp>
ffffffffc02027ec:	6585                	lui	a1,0x1
    if (PPN(pa) >= npage) {
ffffffffc02027ee:	00014c17          	auipc	s8,0x14
ffffffffc02027f2:	d72c0c13          	addi	s8,s8,-654 # ffffffffc0216560 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc02027f6:	00014c97          	auipc	s9,0x14
ffffffffc02027fa:	d72c8c93          	addi	s9,s9,-654 # ffffffffc0216568 <pages>
     
     for (i= 0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
         check_ptep[i]=0;
ffffffffc02027fe:	00073023          	sd	zero,0(a4)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0); // 获取页表项指针
ffffffffc0202802:	4601                	li	a2,0
ffffffffc0202804:	855a                	mv	a0,s6
ffffffffc0202806:	e836                	sd	a3,16(sp)
ffffffffc0202808:	e42e                	sd	a1,8(sp)
         check_ptep[i]=0;
ffffffffc020280a:	e03a                	sd	a4,0(sp)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0); // 获取页表项指针
ffffffffc020280c:	caafe0ef          	jal	ra,ffffffffc0200cb6 <get_pte>
ffffffffc0202810:	6702                	ld	a4,0(sp)
         //cprintf("i %d, check_ptep addr %x, value %x\n", i, check_ptep[i], *check_ptep[i]);
         assert(check_ptep[i] != NULL);
ffffffffc0202812:	65a2                	ld	a1,8(sp)
ffffffffc0202814:	66c2                	ld	a3,16(sp)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0); // 获取页表项指针
ffffffffc0202816:	e308                	sd	a0,0(a4)
         assert(check_ptep[i] != NULL);
ffffffffc0202818:	1c050063          	beqz	a0,ffffffffc02029d8 <swap_init+0x46a>
         assert(pte2page(*check_ptep[i]) == check_rp[i]);
ffffffffc020281c:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc020281e:	0017f613          	andi	a2,a5,1
ffffffffc0202822:	1c060b63          	beqz	a2,ffffffffc02029f8 <swap_init+0x48a>
    if (PPN(pa) >= npage) {
ffffffffc0202826:	000c3603          	ld	a2,0(s8)
    return pa2page(PTE_ADDR(pte));
ffffffffc020282a:	078a                	slli	a5,a5,0x2
ffffffffc020282c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020282e:	12c7fd63          	bgeu	a5,a2,ffffffffc0202968 <swap_init+0x3fa>
    return &pages[PPN(pa) - nbase];
ffffffffc0202832:	00004617          	auipc	a2,0x4
ffffffffc0202836:	7d660613          	addi	a2,a2,2006 # ffffffffc0207008 <nbase>
ffffffffc020283a:	00063a03          	ld	s4,0(a2)
ffffffffc020283e:	000cb603          	ld	a2,0(s9)
ffffffffc0202842:	6288                	ld	a0,0(a3)
ffffffffc0202844:	414787b3          	sub	a5,a5,s4
ffffffffc0202848:	079a                	slli	a5,a5,0x6
ffffffffc020284a:	97b2                	add	a5,a5,a2
ffffffffc020284c:	12f51a63          	bne	a0,a5,ffffffffc0202980 <swap_init+0x412>
     for (i= 0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0202850:	6785                	lui	a5,0x1
ffffffffc0202852:	95be                	add	a1,a1,a5
ffffffffc0202854:	6795                	lui	a5,0x5
ffffffffc0202856:	0721                	addi	a4,a4,8
ffffffffc0202858:	06a1                	addi	a3,a3,8
ffffffffc020285a:	faf592e3          	bne	a1,a5,ffffffffc02027fe <swap_init+0x290>
         assert((*check_ptep[i] & PTE_V));          
     }
     cprintf("set up init env for check_swap over!\n");
ffffffffc020285e:	00004517          	auipc	a0,0x4
ffffffffc0202862:	c1a50513          	addi	a0,a0,-998 # ffffffffc0206478 <commands+0x12c8>
ffffffffc0202866:	867fd0ef          	jal	ra,ffffffffc02000cc <cprintf>
    int ret = sm->check_swap();
ffffffffc020286a:	000bb783          	ld	a5,0(s7)
ffffffffc020286e:	7f9c                	ld	a5,56(a5)
ffffffffc0202870:	9782                	jalr	a5
     // now access the virt pages to test  page relpacement algorithm 
     ret=check_content_access(); // 检查内容访问
     assert(ret==0);
ffffffffc0202872:	30051b63          	bnez	a0,ffffffffc0202b88 <swap_init+0x61a>

     nr_free = nr_free_store;
ffffffffc0202876:	77a2                	ld	a5,40(sp)
ffffffffc0202878:	c81c                	sw	a5,16(s0)
     free_list = free_list_store;
ffffffffc020287a:	67e2                	ld	a5,24(sp)
ffffffffc020287c:	e01c                	sd	a5,0(s0)
ffffffffc020287e:	7782                	ld	a5,32(sp)
ffffffffc0202880:	e41c                	sd	a5,8(s0)

     //restore kernel mem env
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
         free_pages(check_rp[i],1); // 释放页面
ffffffffc0202882:	6088                	ld	a0,0(s1)
ffffffffc0202884:	4585                	li	a1,1
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0202886:	04a1                	addi	s1,s1,8
         free_pages(check_rp[i],1); // 释放页面
ffffffffc0202888:	bb4fe0ef          	jal	ra,ffffffffc0200c3c <free_pages>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc020288c:	ff349be3          	bne	s1,s3,ffffffffc0202882 <swap_init+0x314>
     } 

     //free_page(pte2page(*temp_ptep));
     
     mm_destroy(mm); // 销毁内存管理结构
ffffffffc0202890:	8556                	mv	a0,s5
ffffffffc0202892:	ddeff0ef          	jal	ra,ffffffffc0201e70 <mm_destroy>

     pde_t *pd1=pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
ffffffffc0202896:	00014797          	auipc	a5,0x14
ffffffffc020289a:	cc278793          	addi	a5,a5,-830 # ffffffffc0216558 <boot_pgdir>
ffffffffc020289e:	639c                	ld	a5,0(a5)
    if (PPN(pa) >= npage) {
ffffffffc02028a0:	000c3703          	ld	a4,0(s8)
    return pa2page(PDE_ADDR(pde));
ffffffffc02028a4:	639c                	ld	a5,0(a5)
ffffffffc02028a6:	078a                	slli	a5,a5,0x2
ffffffffc02028a8:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02028aa:	0ae7fd63          	bgeu	a5,a4,ffffffffc0202964 <swap_init+0x3f6>
    return &pages[PPN(pa) - nbase];
ffffffffc02028ae:	414786b3          	sub	a3,a5,s4
ffffffffc02028b2:	069a                	slli	a3,a3,0x6
    return page - pages + nbase;
ffffffffc02028b4:	8699                	srai	a3,a3,0x6
ffffffffc02028b6:	96d2                	add	a3,a3,s4
    return KADDR(page2pa(page));
ffffffffc02028b8:	00c69793          	slli	a5,a3,0xc
ffffffffc02028bc:	83b1                	srli	a5,a5,0xc
    return &pages[PPN(pa) - nbase];
ffffffffc02028be:	000cb503          	ld	a0,0(s9)
    return page2ppn(page) << PGSHIFT;
ffffffffc02028c2:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02028c4:	22e7f663          	bgeu	a5,a4,ffffffffc0202af0 <swap_init+0x582>
     free_page(pde2page(pd0[0]));
ffffffffc02028c8:	00014797          	auipc	a5,0x14
ffffffffc02028cc:	cb07b783          	ld	a5,-848(a5) # ffffffffc0216578 <va_pa_offset>
ffffffffc02028d0:	96be                	add	a3,a3,a5
    return pa2page(PDE_ADDR(pde));
ffffffffc02028d2:	629c                	ld	a5,0(a3)
ffffffffc02028d4:	078a                	slli	a5,a5,0x2
ffffffffc02028d6:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02028d8:	08e7f663          	bgeu	a5,a4,ffffffffc0202964 <swap_init+0x3f6>
    return &pages[PPN(pa) - nbase];
ffffffffc02028dc:	414787b3          	sub	a5,a5,s4
ffffffffc02028e0:	079a                	slli	a5,a5,0x6
ffffffffc02028e2:	953e                	add	a0,a0,a5
ffffffffc02028e4:	4585                	li	a1,1
ffffffffc02028e6:	b56fe0ef          	jal	ra,ffffffffc0200c3c <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc02028ea:	000b3783          	ld	a5,0(s6)
    if (PPN(pa) >= npage) {
ffffffffc02028ee:	000c3703          	ld	a4,0(s8)
    return pa2page(PDE_ADDR(pde));
ffffffffc02028f2:	078a                	slli	a5,a5,0x2
ffffffffc02028f4:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02028f6:	06e7f763          	bgeu	a5,a4,ffffffffc0202964 <swap_init+0x3f6>
    return &pages[PPN(pa) - nbase];
ffffffffc02028fa:	000cb503          	ld	a0,0(s9)
ffffffffc02028fe:	414787b3          	sub	a5,a5,s4
ffffffffc0202902:	079a                	slli	a5,a5,0x6
     free_page(pde2page(pd1[0]));
ffffffffc0202904:	4585                	li	a1,1
ffffffffc0202906:	953e                	add	a0,a0,a5
ffffffffc0202908:	b34fe0ef          	jal	ra,ffffffffc0200c3c <free_pages>
     pgdir[0] = 0;
ffffffffc020290c:	000b3023          	sd	zero,0(s6)
  asm volatile("sfence.vma");
ffffffffc0202910:	12000073          	sfence.vma
    return listelm->next; // 返回下一个节点
ffffffffc0202914:	641c                	ld	a5,8(s0)
     flush_tlb(); // 刷新TLB

     le = &free_list;
     while ((le = list_next(le)) != &free_list) {
ffffffffc0202916:	00878a63          	beq	a5,s0,ffffffffc020292a <swap_init+0x3bc>
         struct Page *p = le2page(le, page_link);
         count --, total -= p->property;
ffffffffc020291a:	ff87a703          	lw	a4,-8(a5)
ffffffffc020291e:	679c                	ld	a5,8(a5)
ffffffffc0202920:	3dfd                	addiw	s11,s11,-1
ffffffffc0202922:	40ed0d3b          	subw	s10,s10,a4
     while ((le = list_next(le)) != &free_list) {
ffffffffc0202926:	fe879ae3          	bne	a5,s0,ffffffffc020291a <swap_init+0x3ac>
     }
     assert(count==0);
ffffffffc020292a:	1c0d9f63          	bnez	s11,ffffffffc0202b08 <swap_init+0x59a>
     assert(total==0);
ffffffffc020292e:	1a0d1163          	bnez	s10,ffffffffc0202ad0 <swap_init+0x562>

     cprintf("check_swap() succeeded!\n");
ffffffffc0202932:	00004517          	auipc	a0,0x4
ffffffffc0202936:	b9650513          	addi	a0,a0,-1130 # ffffffffc02064c8 <commands+0x1318>
ffffffffc020293a:	f92fd0ef          	jal	ra,ffffffffc02000cc <cprintf>
}
ffffffffc020293e:	b149                	j	ffffffffc02025c0 <swap_init+0x52>
     while ((le = list_next(le)) != &free_list) {
ffffffffc0202940:	4481                	li	s1,0
ffffffffc0202942:	b1e5                	j	ffffffffc020262a <swap_init+0xbc>
        assert(PageProperty(p));
ffffffffc0202944:	00004697          	auipc	a3,0x4
ffffffffc0202948:	93468693          	addi	a3,a3,-1740 # ffffffffc0206278 <commands+0x10c8>
ffffffffc020294c:	00003617          	auipc	a2,0x3
ffffffffc0202950:	0d460613          	addi	a2,a2,212 # ffffffffc0205a20 <commands+0x870>
ffffffffc0202954:	0d300593          	li	a1,211
ffffffffc0202958:	00004517          	auipc	a0,0x4
ffffffffc020295c:	8f850513          	addi	a0,a0,-1800 # ffffffffc0206250 <commands+0x10a0>
ffffffffc0202960:	869fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
ffffffffc0202964:	befff0ef          	jal	ra,ffffffffc0202552 <pa2page.part.0>
        panic("pa2page called with invalid pa");
ffffffffc0202968:	00003617          	auipc	a2,0x3
ffffffffc020296c:	f5060613          	addi	a2,a2,-176 # ffffffffc02058b8 <commands+0x708>
ffffffffc0202970:	06000593          	li	a1,96
ffffffffc0202974:	00003517          	auipc	a0,0x3
ffffffffc0202978:	f6450513          	addi	a0,a0,-156 # ffffffffc02058d8 <commands+0x728>
ffffffffc020297c:	84dfd0ef          	jal	ra,ffffffffc02001c8 <__panic>
         assert(pte2page(*check_ptep[i]) == check_rp[i]);
ffffffffc0202980:	00004697          	auipc	a3,0x4
ffffffffc0202984:	ad068693          	addi	a3,a3,-1328 # ffffffffc0206450 <commands+0x12a0>
ffffffffc0202988:	00003617          	auipc	a2,0x3
ffffffffc020298c:	09860613          	addi	a2,a2,152 # ffffffffc0205a20 <commands+0x870>
ffffffffc0202990:	11300593          	li	a1,275
ffffffffc0202994:	00004517          	auipc	a0,0x4
ffffffffc0202998:	8bc50513          	addi	a0,a0,-1860 # ffffffffc0206250 <commands+0x10a0>
ffffffffc020299c:	82dfd0ef          	jal	ra,ffffffffc02001c8 <__panic>
          assert(check_rp[i] != NULL );
ffffffffc02029a0:	00004697          	auipc	a3,0x4
ffffffffc02029a4:	9c068693          	addi	a3,a3,-1600 # ffffffffc0206360 <commands+0x11b0>
ffffffffc02029a8:	00003617          	auipc	a2,0x3
ffffffffc02029ac:	07860613          	addi	a2,a2,120 # ffffffffc0205a20 <commands+0x870>
ffffffffc02029b0:	0f300593          	li	a1,243
ffffffffc02029b4:	00004517          	auipc	a0,0x4
ffffffffc02029b8:	89c50513          	addi	a0,a0,-1892 # ffffffffc0206250 <commands+0x10a0>
ffffffffc02029bc:	80dfd0ef          	jal	ra,ffffffffc02001c8 <__panic>
        panic("bad max_swap_offset %08x.\n", max_swap_offset);
ffffffffc02029c0:	00004617          	auipc	a2,0x4
ffffffffc02029c4:	87060613          	addi	a2,a2,-1936 # ffffffffc0206230 <commands+0x1080>
ffffffffc02029c8:	02c00593          	li	a1,44
ffffffffc02029cc:	00004517          	auipc	a0,0x4
ffffffffc02029d0:	88450513          	addi	a0,a0,-1916 # ffffffffc0206250 <commands+0x10a0>
ffffffffc02029d4:	ff4fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
         assert(check_ptep[i] != NULL);
ffffffffc02029d8:	00004697          	auipc	a3,0x4
ffffffffc02029dc:	a6068693          	addi	a3,a3,-1440 # ffffffffc0206438 <commands+0x1288>
ffffffffc02029e0:	00003617          	auipc	a2,0x3
ffffffffc02029e4:	04060613          	addi	a2,a2,64 # ffffffffc0205a20 <commands+0x870>
ffffffffc02029e8:	11200593          	li	a1,274
ffffffffc02029ec:	00004517          	auipc	a0,0x4
ffffffffc02029f0:	86450513          	addi	a0,a0,-1948 # ffffffffc0206250 <commands+0x10a0>
ffffffffc02029f4:	fd4fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc02029f8:	00003617          	auipc	a2,0x3
ffffffffc02029fc:	ef060613          	addi	a2,a2,-272 # ffffffffc02058e8 <commands+0x738>
ffffffffc0202a00:	07200593          	li	a1,114
ffffffffc0202a04:	00003517          	auipc	a0,0x3
ffffffffc0202a08:	ed450513          	addi	a0,a0,-300 # ffffffffc02058d8 <commands+0x728>
ffffffffc0202a0c:	fbcfd0ef          	jal	ra,ffffffffc02001c8 <__panic>
          assert(!PageProperty(check_rp[i]));
ffffffffc0202a10:	00004697          	auipc	a3,0x4
ffffffffc0202a14:	96868693          	addi	a3,a3,-1688 # ffffffffc0206378 <commands+0x11c8>
ffffffffc0202a18:	00003617          	auipc	a2,0x3
ffffffffc0202a1c:	00860613          	addi	a2,a2,8 # ffffffffc0205a20 <commands+0x870>
ffffffffc0202a20:	0f400593          	li	a1,244
ffffffffc0202a24:	00004517          	auipc	a0,0x4
ffffffffc0202a28:	82c50513          	addi	a0,a0,-2004 # ffffffffc0206250 <commands+0x10a0>
ffffffffc0202a2c:	f9cfd0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(check_mm_struct == NULL);
ffffffffc0202a30:	00004697          	auipc	a3,0x4
ffffffffc0202a34:	8a068693          	addi	a3,a3,-1888 # ffffffffc02062d0 <commands+0x1120>
ffffffffc0202a38:	00003617          	auipc	a2,0x3
ffffffffc0202a3c:	fe860613          	addi	a2,a2,-24 # ffffffffc0205a20 <commands+0x870>
ffffffffc0202a40:	0de00593          	li	a1,222
ffffffffc0202a44:	00004517          	auipc	a0,0x4
ffffffffc0202a48:	80c50513          	addi	a0,a0,-2036 # ffffffffc0206250 <commands+0x10a0>
ffffffffc0202a4c:	f7cfd0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(total == nr_free_pages());
ffffffffc0202a50:	00004697          	auipc	a3,0x4
ffffffffc0202a54:	83868693          	addi	a3,a3,-1992 # ffffffffc0206288 <commands+0x10d8>
ffffffffc0202a58:	00003617          	auipc	a2,0x3
ffffffffc0202a5c:	fc860613          	addi	a2,a2,-56 # ffffffffc0205a20 <commands+0x870>
ffffffffc0202a60:	0d600593          	li	a1,214
ffffffffc0202a64:	00003517          	auipc	a0,0x3
ffffffffc0202a68:	7ec50513          	addi	a0,a0,2028 # ffffffffc0206250 <commands+0x10a0>
ffffffffc0202a6c:	f5cfd0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert( nr_free == 0);         
ffffffffc0202a70:	00004697          	auipc	a3,0x4
ffffffffc0202a74:	9b868693          	addi	a3,a3,-1608 # ffffffffc0206428 <commands+0x1278>
ffffffffc0202a78:	00003617          	auipc	a2,0x3
ffffffffc0202a7c:	fa860613          	addi	a2,a2,-88 # ffffffffc0205a20 <commands+0x870>
ffffffffc0202a80:	10a00593          	li	a1,266
ffffffffc0202a84:	00003517          	auipc	a0,0x3
ffffffffc0202a88:	7cc50513          	addi	a0,a0,1996 # ffffffffc0206250 <commands+0x10a0>
ffffffffc0202a8c:	f3cfd0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(pgdir[0] == 0);
ffffffffc0202a90:	00003697          	auipc	a3,0x3
ffffffffc0202a94:	62868693          	addi	a3,a3,1576 # ffffffffc02060b8 <commands+0xf08>
ffffffffc0202a98:	00003617          	auipc	a2,0x3
ffffffffc0202a9c:	f8860613          	addi	a2,a2,-120 # ffffffffc0205a20 <commands+0x870>
ffffffffc0202aa0:	0e300593          	li	a1,227
ffffffffc0202aa4:	00003517          	auipc	a0,0x3
ffffffffc0202aa8:	7ac50513          	addi	a0,a0,1964 # ffffffffc0206250 <commands+0x10a0>
ffffffffc0202aac:	f1cfd0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(mm != NULL);
ffffffffc0202ab0:	00003697          	auipc	a3,0x3
ffffffffc0202ab4:	6d068693          	addi	a3,a3,1744 # ffffffffc0206180 <commands+0xfd0>
ffffffffc0202ab8:	00003617          	auipc	a2,0x3
ffffffffc0202abc:	f6860613          	addi	a2,a2,-152 # ffffffffc0205a20 <commands+0x870>
ffffffffc0202ac0:	0db00593          	li	a1,219
ffffffffc0202ac4:	00003517          	auipc	a0,0x3
ffffffffc0202ac8:	78c50513          	addi	a0,a0,1932 # ffffffffc0206250 <commands+0x10a0>
ffffffffc0202acc:	efcfd0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(total==0);
ffffffffc0202ad0:	00004697          	auipc	a3,0x4
ffffffffc0202ad4:	9e868693          	addi	a3,a3,-1560 # ffffffffc02064b8 <commands+0x1308>
ffffffffc0202ad8:	00003617          	auipc	a2,0x3
ffffffffc0202adc:	f4860613          	addi	a2,a2,-184 # ffffffffc0205a20 <commands+0x870>
ffffffffc0202ae0:	13300593          	li	a1,307
ffffffffc0202ae4:	00003517          	auipc	a0,0x3
ffffffffc0202ae8:	76c50513          	addi	a0,a0,1900 # ffffffffc0206250 <commands+0x10a0>
ffffffffc0202aec:	edcfd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    return KADDR(page2pa(page));
ffffffffc0202af0:	00003617          	auipc	a2,0x3
ffffffffc0202af4:	e2060613          	addi	a2,a2,-480 # ffffffffc0205910 <commands+0x760>
ffffffffc0202af8:	06700593          	li	a1,103
ffffffffc0202afc:	00003517          	auipc	a0,0x3
ffffffffc0202b00:	ddc50513          	addi	a0,a0,-548 # ffffffffc02058d8 <commands+0x728>
ffffffffc0202b04:	ec4fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(count==0);
ffffffffc0202b08:	00004697          	auipc	a3,0x4
ffffffffc0202b0c:	9a068693          	addi	a3,a3,-1632 # ffffffffc02064a8 <commands+0x12f8>
ffffffffc0202b10:	00003617          	auipc	a2,0x3
ffffffffc0202b14:	f1060613          	addi	a2,a2,-240 # ffffffffc0205a20 <commands+0x870>
ffffffffc0202b18:	13200593          	li	a1,306
ffffffffc0202b1c:	00003517          	auipc	a0,0x3
ffffffffc0202b20:	73450513          	addi	a0,a0,1844 # ffffffffc0206250 <commands+0x10a0>
ffffffffc0202b24:	ea4fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(pgfault_num==1);
ffffffffc0202b28:	00004697          	auipc	a3,0x4
ffffffffc0202b2c:	8c068693          	addi	a3,a3,-1856 # ffffffffc02063e8 <commands+0x1238>
ffffffffc0202b30:	00003617          	auipc	a2,0x3
ffffffffc0202b34:	ef060613          	addi	a2,a2,-272 # ffffffffc0205a20 <commands+0x870>
ffffffffc0202b38:	0a900593          	li	a1,169
ffffffffc0202b3c:	00003517          	auipc	a0,0x3
ffffffffc0202b40:	71450513          	addi	a0,a0,1812 # ffffffffc0206250 <commands+0x10a0>
ffffffffc0202b44:	e84fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(nr_free==CHECK_VALID_PHY_PAGE_NUM);
ffffffffc0202b48:	00004697          	auipc	a3,0x4
ffffffffc0202b4c:	85068693          	addi	a3,a3,-1968 # ffffffffc0206398 <commands+0x11e8>
ffffffffc0202b50:	00003617          	auipc	a2,0x3
ffffffffc0202b54:	ed060613          	addi	a2,a2,-304 # ffffffffc0205a20 <commands+0x870>
ffffffffc0202b58:	10100593          	li	a1,257
ffffffffc0202b5c:	00003517          	auipc	a0,0x3
ffffffffc0202b60:	6f450513          	addi	a0,a0,1780 # ffffffffc0206250 <commands+0x10a0>
ffffffffc0202b64:	e64fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(temp_ptep!= NULL);
ffffffffc0202b68:	00003697          	auipc	a3,0x3
ffffffffc0202b6c:	7b868693          	addi	a3,a3,1976 # ffffffffc0206320 <commands+0x1170>
ffffffffc0202b70:	00003617          	auipc	a2,0x3
ffffffffc0202b74:	eb060613          	addi	a2,a2,-336 # ffffffffc0205a20 <commands+0x870>
ffffffffc0202b78:	0ee00593          	li	a1,238
ffffffffc0202b7c:	00003517          	auipc	a0,0x3
ffffffffc0202b80:	6d450513          	addi	a0,a0,1748 # ffffffffc0206250 <commands+0x10a0>
ffffffffc0202b84:	e44fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(ret==0);
ffffffffc0202b88:	00004697          	auipc	a3,0x4
ffffffffc0202b8c:	91868693          	addi	a3,a3,-1768 # ffffffffc02064a0 <commands+0x12f0>
ffffffffc0202b90:	00003617          	auipc	a2,0x3
ffffffffc0202b94:	e9060613          	addi	a2,a2,-368 # ffffffffc0205a20 <commands+0x870>
ffffffffc0202b98:	11900593          	li	a1,281
ffffffffc0202b9c:	00003517          	auipc	a0,0x3
ffffffffc0202ba0:	6b450513          	addi	a0,a0,1716 # ffffffffc0206250 <commands+0x10a0>
ffffffffc0202ba4:	e24fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(vma != NULL);
ffffffffc0202ba8:	00003697          	auipc	a3,0x3
ffffffffc0202bac:	5b068693          	addi	a3,a3,1456 # ffffffffc0206158 <commands+0xfa8>
ffffffffc0202bb0:	00003617          	auipc	a2,0x3
ffffffffc0202bb4:	e7060613          	addi	a2,a2,-400 # ffffffffc0205a20 <commands+0x870>
ffffffffc0202bb8:	0e600593          	li	a1,230
ffffffffc0202bbc:	00003517          	auipc	a0,0x3
ffffffffc0202bc0:	69450513          	addi	a0,a0,1684 # ffffffffc0206250 <commands+0x10a0>
ffffffffc0202bc4:	e04fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(pgfault_num==4);
ffffffffc0202bc8:	00004697          	auipc	a3,0x4
ffffffffc0202bcc:	85068693          	addi	a3,a3,-1968 # ffffffffc0206418 <commands+0x1268>
ffffffffc0202bd0:	00003617          	auipc	a2,0x3
ffffffffc0202bd4:	e5060613          	addi	a2,a2,-432 # ffffffffc0205a20 <commands+0x870>
ffffffffc0202bd8:	0b300593          	li	a1,179
ffffffffc0202bdc:	00003517          	auipc	a0,0x3
ffffffffc0202be0:	67450513          	addi	a0,a0,1652 # ffffffffc0206250 <commands+0x10a0>
ffffffffc0202be4:	de4fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(pgfault_num==4);
ffffffffc0202be8:	00004697          	auipc	a3,0x4
ffffffffc0202bec:	83068693          	addi	a3,a3,-2000 # ffffffffc0206418 <commands+0x1268>
ffffffffc0202bf0:	00003617          	auipc	a2,0x3
ffffffffc0202bf4:	e3060613          	addi	a2,a2,-464 # ffffffffc0205a20 <commands+0x870>
ffffffffc0202bf8:	0b500593          	li	a1,181
ffffffffc0202bfc:	00003517          	auipc	a0,0x3
ffffffffc0202c00:	65450513          	addi	a0,a0,1620 # ffffffffc0206250 <commands+0x10a0>
ffffffffc0202c04:	dc4fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(pgfault_num==2);
ffffffffc0202c08:	00003697          	auipc	a3,0x3
ffffffffc0202c0c:	7f068693          	addi	a3,a3,2032 # ffffffffc02063f8 <commands+0x1248>
ffffffffc0202c10:	00003617          	auipc	a2,0x3
ffffffffc0202c14:	e1060613          	addi	a2,a2,-496 # ffffffffc0205a20 <commands+0x870>
ffffffffc0202c18:	0ab00593          	li	a1,171
ffffffffc0202c1c:	00003517          	auipc	a0,0x3
ffffffffc0202c20:	63450513          	addi	a0,a0,1588 # ffffffffc0206250 <commands+0x10a0>
ffffffffc0202c24:	da4fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(pgfault_num==2);
ffffffffc0202c28:	00003697          	auipc	a3,0x3
ffffffffc0202c2c:	7d068693          	addi	a3,a3,2000 # ffffffffc02063f8 <commands+0x1248>
ffffffffc0202c30:	00003617          	auipc	a2,0x3
ffffffffc0202c34:	df060613          	addi	a2,a2,-528 # ffffffffc0205a20 <commands+0x870>
ffffffffc0202c38:	0ad00593          	li	a1,173
ffffffffc0202c3c:	00003517          	auipc	a0,0x3
ffffffffc0202c40:	61450513          	addi	a0,a0,1556 # ffffffffc0206250 <commands+0x10a0>
ffffffffc0202c44:	d84fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(pgfault_num==3);
ffffffffc0202c48:	00003697          	auipc	a3,0x3
ffffffffc0202c4c:	7c068693          	addi	a3,a3,1984 # ffffffffc0206408 <commands+0x1258>
ffffffffc0202c50:	00003617          	auipc	a2,0x3
ffffffffc0202c54:	dd060613          	addi	a2,a2,-560 # ffffffffc0205a20 <commands+0x870>
ffffffffc0202c58:	0af00593          	li	a1,175
ffffffffc0202c5c:	00003517          	auipc	a0,0x3
ffffffffc0202c60:	5f450513          	addi	a0,a0,1524 # ffffffffc0206250 <commands+0x10a0>
ffffffffc0202c64:	d64fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(pgfault_num==3);
ffffffffc0202c68:	00003697          	auipc	a3,0x3
ffffffffc0202c6c:	7a068693          	addi	a3,a3,1952 # ffffffffc0206408 <commands+0x1258>
ffffffffc0202c70:	00003617          	auipc	a2,0x3
ffffffffc0202c74:	db060613          	addi	a2,a2,-592 # ffffffffc0205a20 <commands+0x870>
ffffffffc0202c78:	0b100593          	li	a1,177
ffffffffc0202c7c:	00003517          	auipc	a0,0x3
ffffffffc0202c80:	5d450513          	addi	a0,a0,1492 # ffffffffc0206250 <commands+0x10a0>
ffffffffc0202c84:	d44fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(pgfault_num==1);
ffffffffc0202c88:	00003697          	auipc	a3,0x3
ffffffffc0202c8c:	76068693          	addi	a3,a3,1888 # ffffffffc02063e8 <commands+0x1238>
ffffffffc0202c90:	00003617          	auipc	a2,0x3
ffffffffc0202c94:	d9060613          	addi	a2,a2,-624 # ffffffffc0205a20 <commands+0x870>
ffffffffc0202c98:	0a700593          	li	a1,167
ffffffffc0202c9c:	00003517          	auipc	a0,0x3
ffffffffc0202ca0:	5b450513          	addi	a0,a0,1460 # ffffffffc0206250 <commands+0x10a0>
ffffffffc0202ca4:	d24fd0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc0202ca8 <swap_init_mm>:
     return sm->init_mm(mm);
ffffffffc0202ca8:	00014797          	auipc	a5,0x14
ffffffffc0202cac:	8f07b783          	ld	a5,-1808(a5) # ffffffffc0216598 <sm>
ffffffffc0202cb0:	6b9c                	ld	a5,16(a5)
ffffffffc0202cb2:	8782                	jr	a5

ffffffffc0202cb4 <swap_map_swappable>:
     return sm->map_swappable(mm, addr, page, swap_in);
ffffffffc0202cb4:	00014797          	auipc	a5,0x14
ffffffffc0202cb8:	8e47b783          	ld	a5,-1820(a5) # ffffffffc0216598 <sm>
ffffffffc0202cbc:	739c                	ld	a5,32(a5)
ffffffffc0202cbe:	8782                	jr	a5

ffffffffc0202cc0 <swap_out>:
{
ffffffffc0202cc0:	711d                	addi	sp,sp,-96
ffffffffc0202cc2:	ec86                	sd	ra,88(sp)
ffffffffc0202cc4:	e8a2                	sd	s0,80(sp)
ffffffffc0202cc6:	e4a6                	sd	s1,72(sp)
ffffffffc0202cc8:	e0ca                	sd	s2,64(sp)
ffffffffc0202cca:	fc4e                	sd	s3,56(sp)
ffffffffc0202ccc:	f852                	sd	s4,48(sp)
ffffffffc0202cce:	f456                	sd	s5,40(sp)
ffffffffc0202cd0:	f05a                	sd	s6,32(sp)
ffffffffc0202cd2:	ec5e                	sd	s7,24(sp)
ffffffffc0202cd4:	e862                	sd	s8,16(sp)
     for (i = 0; i != n; ++ i)
ffffffffc0202cd6:	cde9                	beqz	a1,ffffffffc0202db0 <swap_out+0xf0>
ffffffffc0202cd8:	8a2e                	mv	s4,a1
ffffffffc0202cda:	892a                	mv	s2,a0
ffffffffc0202cdc:	8ab2                	mv	s5,a2
ffffffffc0202cde:	4401                	li	s0,0
ffffffffc0202ce0:	00014997          	auipc	s3,0x14
ffffffffc0202ce4:	8b898993          	addi	s3,s3,-1864 # ffffffffc0216598 <sm>
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0202ce8:	00004b17          	auipc	s6,0x4
ffffffffc0202cec:	860b0b13          	addi	s6,s6,-1952 # ffffffffc0206548 <commands+0x1398>
                    cprintf("SWAP: failed to save\n");
ffffffffc0202cf0:	00004b97          	auipc	s7,0x4
ffffffffc0202cf4:	840b8b93          	addi	s7,s7,-1984 # ffffffffc0206530 <commands+0x1380>
ffffffffc0202cf8:	a825                	j	ffffffffc0202d30 <swap_out+0x70>
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0202cfa:	67a2                	ld	a5,8(sp)
ffffffffc0202cfc:	8626                	mv	a2,s1
ffffffffc0202cfe:	85a2                	mv	a1,s0
ffffffffc0202d00:	7f94                	ld	a3,56(a5)
ffffffffc0202d02:	855a                	mv	a0,s6
     for (i = 0; i != n; ++ i)
ffffffffc0202d04:	2405                	addiw	s0,s0,1
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0202d06:	82b1                	srli	a3,a3,0xc
ffffffffc0202d08:	0685                	addi	a3,a3,1
ffffffffc0202d0a:	bc2fd0ef          	jal	ra,ffffffffc02000cc <cprintf>
                    *ptep = (page->pra_vaddr/PGSIZE+1)<<8; // 更新页表项
ffffffffc0202d0e:	6522                	ld	a0,8(sp)
                    free_page(page); // 释放页面
ffffffffc0202d10:	4585                	li	a1,1
                    *ptep = (page->pra_vaddr/PGSIZE+1)<<8; // 更新页表项
ffffffffc0202d12:	7d1c                	ld	a5,56(a0)
ffffffffc0202d14:	83b1                	srli	a5,a5,0xc
ffffffffc0202d16:	0785                	addi	a5,a5,1
ffffffffc0202d18:	07a2                	slli	a5,a5,0x8
ffffffffc0202d1a:	00fc3023          	sd	a5,0(s8)
                    free_page(page); // 释放页面
ffffffffc0202d1e:	f1ffd0ef          	jal	ra,ffffffffc0200c3c <free_pages>
          tlb_invalidate(mm->pgdir, v); // 刷新TLB
ffffffffc0202d22:	01893503          	ld	a0,24(s2)
ffffffffc0202d26:	85a6                	mv	a1,s1
ffffffffc0202d28:	ee1fe0ef          	jal	ra,ffffffffc0201c08 <tlb_invalidate>
     for (i = 0; i != n; ++ i)
ffffffffc0202d2c:	048a0d63          	beq	s4,s0,ffffffffc0202d86 <swap_out+0xc6>
          int r = sm->swap_out_victim(mm, &page, in_tick); // 选择要交换出的页面
ffffffffc0202d30:	0009b783          	ld	a5,0(s3)
ffffffffc0202d34:	8656                	mv	a2,s5
ffffffffc0202d36:	002c                	addi	a1,sp,8
ffffffffc0202d38:	7b9c                	ld	a5,48(a5)
ffffffffc0202d3a:	854a                	mv	a0,s2
ffffffffc0202d3c:	9782                	jalr	a5
          if (r != 0) {
ffffffffc0202d3e:	e12d                	bnez	a0,ffffffffc0202da0 <swap_out+0xe0>
          v=page->pra_vaddr; 
ffffffffc0202d40:	67a2                	ld	a5,8(sp)
          pte_t *ptep = get_pte(mm->pgdir, v, 0); // 获取页表项指针
ffffffffc0202d42:	01893503          	ld	a0,24(s2)
ffffffffc0202d46:	4601                	li	a2,0
          v=page->pra_vaddr; 
ffffffffc0202d48:	7f84                	ld	s1,56(a5)
          pte_t *ptep = get_pte(mm->pgdir, v, 0); // 获取页表项指针
ffffffffc0202d4a:	85a6                	mv	a1,s1
ffffffffc0202d4c:	f6bfd0ef          	jal	ra,ffffffffc0200cb6 <get_pte>
          assert((*ptep & PTE_V) != 0);
ffffffffc0202d50:	611c                	ld	a5,0(a0)
          pte_t *ptep = get_pte(mm->pgdir, v, 0); // 获取页表项指针
ffffffffc0202d52:	8c2a                	mv	s8,a0
          assert((*ptep & PTE_V) != 0);
ffffffffc0202d54:	8b85                	andi	a5,a5,1
ffffffffc0202d56:	cfb9                	beqz	a5,ffffffffc0202db4 <swap_out+0xf4>
          if (swapfs_write( (page->pra_vaddr/PGSIZE+1)<<8, page) != 0) { // 将页面写入交换文件系统
ffffffffc0202d58:	65a2                	ld	a1,8(sp)
ffffffffc0202d5a:	7d9c                	ld	a5,56(a1)
ffffffffc0202d5c:	83b1                	srli	a5,a5,0xc
ffffffffc0202d5e:	0785                	addi	a5,a5,1
ffffffffc0202d60:	00879513          	slli	a0,a5,0x8
ffffffffc0202d64:	424010ef          	jal	ra,ffffffffc0204188 <swapfs_write>
ffffffffc0202d68:	d949                	beqz	a0,ffffffffc0202cfa <swap_out+0x3a>
                    cprintf("SWAP: failed to save\n");
ffffffffc0202d6a:	855e                	mv	a0,s7
ffffffffc0202d6c:	b60fd0ef          	jal	ra,ffffffffc02000cc <cprintf>
                    sm->map_swappable(mm, v, page, 0);
ffffffffc0202d70:	0009b783          	ld	a5,0(s3)
ffffffffc0202d74:	6622                	ld	a2,8(sp)
ffffffffc0202d76:	4681                	li	a3,0
ffffffffc0202d78:	739c                	ld	a5,32(a5)
ffffffffc0202d7a:	85a6                	mv	a1,s1
ffffffffc0202d7c:	854a                	mv	a0,s2
     for (i = 0; i != n; ++ i)
ffffffffc0202d7e:	2405                	addiw	s0,s0,1
                    sm->map_swappable(mm, v, page, 0);
ffffffffc0202d80:	9782                	jalr	a5
     for (i = 0; i != n; ++ i)
ffffffffc0202d82:	fa8a17e3          	bne	s4,s0,ffffffffc0202d30 <swap_out+0x70>
}
ffffffffc0202d86:	60e6                	ld	ra,88(sp)
ffffffffc0202d88:	8522                	mv	a0,s0
ffffffffc0202d8a:	6446                	ld	s0,80(sp)
ffffffffc0202d8c:	64a6                	ld	s1,72(sp)
ffffffffc0202d8e:	6906                	ld	s2,64(sp)
ffffffffc0202d90:	79e2                	ld	s3,56(sp)
ffffffffc0202d92:	7a42                	ld	s4,48(sp)
ffffffffc0202d94:	7aa2                	ld	s5,40(sp)
ffffffffc0202d96:	7b02                	ld	s6,32(sp)
ffffffffc0202d98:	6be2                	ld	s7,24(sp)
ffffffffc0202d9a:	6c42                	ld	s8,16(sp)
ffffffffc0202d9c:	6125                	addi	sp,sp,96
ffffffffc0202d9e:	8082                	ret
                    cprintf("i %d, swap_out: call swap_out_victim failed\n",i);
ffffffffc0202da0:	85a2                	mv	a1,s0
ffffffffc0202da2:	00003517          	auipc	a0,0x3
ffffffffc0202da6:	74650513          	addi	a0,a0,1862 # ffffffffc02064e8 <commands+0x1338>
ffffffffc0202daa:	b22fd0ef          	jal	ra,ffffffffc02000cc <cprintf>
                  break;
ffffffffc0202dae:	bfe1                	j	ffffffffc0202d86 <swap_out+0xc6>
     for (i = 0; i != n; ++ i)
ffffffffc0202db0:	4401                	li	s0,0
ffffffffc0202db2:	bfd1                	j	ffffffffc0202d86 <swap_out+0xc6>
          assert((*ptep & PTE_V) != 0);
ffffffffc0202db4:	00003697          	auipc	a3,0x3
ffffffffc0202db8:	76468693          	addi	a3,a3,1892 # ffffffffc0206518 <commands+0x1368>
ffffffffc0202dbc:	00003617          	auipc	a2,0x3
ffffffffc0202dc0:	c6460613          	addi	a2,a2,-924 # ffffffffc0205a20 <commands+0x870>
ffffffffc0202dc4:	07a00593          	li	a1,122
ffffffffc0202dc8:	00003517          	auipc	a0,0x3
ffffffffc0202dcc:	48850513          	addi	a0,a0,1160 # ffffffffc0206250 <commands+0x10a0>
ffffffffc0202dd0:	bf8fd0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc0202dd4 <swap_in>:
{
ffffffffc0202dd4:	7179                	addi	sp,sp,-48
ffffffffc0202dd6:	e84a                	sd	s2,16(sp)
ffffffffc0202dd8:	892a                	mv	s2,a0
     struct Page *result = alloc_page(); // 分配新页面
ffffffffc0202dda:	4505                	li	a0,1
{
ffffffffc0202ddc:	ec26                	sd	s1,24(sp)
ffffffffc0202dde:	e44e                	sd	s3,8(sp)
ffffffffc0202de0:	f406                	sd	ra,40(sp)
ffffffffc0202de2:	f022                	sd	s0,32(sp)
ffffffffc0202de4:	84ae                	mv	s1,a1
ffffffffc0202de6:	89b2                	mv	s3,a2
     struct Page *result = alloc_page(); // 分配新页面
ffffffffc0202de8:	dc3fd0ef          	jal	ra,ffffffffc0200baa <alloc_pages>
     assert(result!=NULL);
ffffffffc0202dec:	c129                	beqz	a0,ffffffffc0202e2e <swap_in+0x5a>
     pte_t *ptep = get_pte(mm->pgdir, addr, 0); // 获取页表项指针
ffffffffc0202dee:	842a                	mv	s0,a0
ffffffffc0202df0:	01893503          	ld	a0,24(s2)
ffffffffc0202df4:	4601                	li	a2,0
ffffffffc0202df6:	85a6                	mv	a1,s1
ffffffffc0202df8:	ebffd0ef          	jal	ra,ffffffffc0200cb6 <get_pte>
ffffffffc0202dfc:	892a                	mv	s2,a0
     if ((r = swapfs_read((*ptep), result)) != 0) // 从交换文件系统读取页面
ffffffffc0202dfe:	6108                	ld	a0,0(a0)
ffffffffc0202e00:	85a2                	mv	a1,s0
ffffffffc0202e02:	2f8010ef          	jal	ra,ffffffffc02040fa <swapfs_read>
     cprintf("swap_in: load disk swap entry %d with swap_page in vadr 0x%x\n", (*ptep)>>8, addr);
ffffffffc0202e06:	00093583          	ld	a1,0(s2)
ffffffffc0202e0a:	8626                	mv	a2,s1
ffffffffc0202e0c:	00003517          	auipc	a0,0x3
ffffffffc0202e10:	78c50513          	addi	a0,a0,1932 # ffffffffc0206598 <commands+0x13e8>
ffffffffc0202e14:	81a1                	srli	a1,a1,0x8
ffffffffc0202e16:	ab6fd0ef          	jal	ra,ffffffffc02000cc <cprintf>
}
ffffffffc0202e1a:	70a2                	ld	ra,40(sp)
     *ptr_result=result;
ffffffffc0202e1c:	0089b023          	sd	s0,0(s3)
}
ffffffffc0202e20:	7402                	ld	s0,32(sp)
ffffffffc0202e22:	64e2                	ld	s1,24(sp)
ffffffffc0202e24:	6942                	ld	s2,16(sp)
ffffffffc0202e26:	69a2                	ld	s3,8(sp)
ffffffffc0202e28:	4501                	li	a0,0
ffffffffc0202e2a:	6145                	addi	sp,sp,48
ffffffffc0202e2c:	8082                	ret
     assert(result!=NULL);
ffffffffc0202e2e:	00003697          	auipc	a3,0x3
ffffffffc0202e32:	75a68693          	addi	a3,a3,1882 # ffffffffc0206588 <commands+0x13d8>
ffffffffc0202e36:	00003617          	auipc	a2,0x3
ffffffffc0202e3a:	bea60613          	addi	a2,a2,-1046 # ffffffffc0205a20 <commands+0x870>
ffffffffc0202e3e:	09300593          	li	a1,147
ffffffffc0202e42:	00003517          	auipc	a0,0x3
ffffffffc0202e46:	40e50513          	addi	a0,a0,1038 # ffffffffc0206250 <commands+0x10a0>
ffffffffc0202e4a:	b7efd0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc0202e4e <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc0202e4e:	c94d                	beqz	a0,ffffffffc0202f00 <slob_free+0xb2>
{
ffffffffc0202e50:	1141                	addi	sp,sp,-16
ffffffffc0202e52:	e022                	sd	s0,0(sp)
ffffffffc0202e54:	e406                	sd	ra,8(sp)
ffffffffc0202e56:	842a                	mv	s0,a0
		return;

	if (size)
ffffffffc0202e58:	e9c1                	bnez	a1,ffffffffc0202ee8 <slob_free+0x9a>
    if (read_csr(sstatus) & SSTATUS_SIE) { // 如果当前中断使能
ffffffffc0202e5a:	100027f3          	csrr	a5,sstatus
ffffffffc0202e5e:	8b89                	andi	a5,a5,2
    return 0; // 返回0表示中断之前是禁用的
ffffffffc0202e60:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE) { // 如果当前中断使能
ffffffffc0202e62:	ebd9                	bnez	a5,ffffffffc0202ef8 <slob_free+0xaa>
		b->units = SLOB_UNITS(size);

	/* 找到重新插入点 */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0202e64:	00008617          	auipc	a2,0x8
ffffffffc0202e68:	1ec60613          	addi	a2,a2,492 # ffffffffc020b050 <slobfree>
ffffffffc0202e6c:	621c                	ld	a5,0(a2)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0202e6e:	873e                	mv	a4,a5
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0202e70:	679c                	ld	a5,8(a5)
ffffffffc0202e72:	02877a63          	bgeu	a4,s0,ffffffffc0202ea6 <slob_free+0x58>
ffffffffc0202e76:	00f46463          	bltu	s0,a5,ffffffffc0202e7e <slob_free+0x30>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0202e7a:	fef76ae3          	bltu	a4,a5,ffffffffc0202e6e <slob_free+0x20>
			break;

	if (b + b->units == cur->next) {
ffffffffc0202e7e:	400c                	lw	a1,0(s0)
ffffffffc0202e80:	00459693          	slli	a3,a1,0x4
ffffffffc0202e84:	96a2                	add	a3,a3,s0
ffffffffc0202e86:	02d78a63          	beq	a5,a3,ffffffffc0202eba <slob_free+0x6c>
		b->units += cur->next->units;
		b->next = cur->next->next;
	} else
		b->next = cur->next;

	if (cur + cur->units == b) {
ffffffffc0202e8a:	4314                	lw	a3,0(a4)
		b->next = cur->next;
ffffffffc0202e8c:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b) {
ffffffffc0202e8e:	00469793          	slli	a5,a3,0x4
ffffffffc0202e92:	97ba                	add	a5,a5,a4
ffffffffc0202e94:	02f40e63          	beq	s0,a5,ffffffffc0202ed0 <slob_free+0x82>
		cur->units += b->units;
		cur->next = b->next;
	} else
		cur->next = b;
ffffffffc0202e98:	e700                	sd	s0,8(a4)

	slobfree = cur;
ffffffffc0202e9a:	e218                	sd	a4,0(a2)
    if (flag) { // 如果flag为1
ffffffffc0202e9c:	e129                	bnez	a0,ffffffffc0202ede <slob_free+0x90>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc0202e9e:	60a2                	ld	ra,8(sp)
ffffffffc0202ea0:	6402                	ld	s0,0(sp)
ffffffffc0202ea2:	0141                	addi	sp,sp,16
ffffffffc0202ea4:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0202ea6:	fcf764e3          	bltu	a4,a5,ffffffffc0202e6e <slob_free+0x20>
ffffffffc0202eaa:	fcf472e3          	bgeu	s0,a5,ffffffffc0202e6e <slob_free+0x20>
	if (b + b->units == cur->next) {
ffffffffc0202eae:	400c                	lw	a1,0(s0)
ffffffffc0202eb0:	00459693          	slli	a3,a1,0x4
ffffffffc0202eb4:	96a2                	add	a3,a3,s0
ffffffffc0202eb6:	fcd79ae3          	bne	a5,a3,ffffffffc0202e8a <slob_free+0x3c>
		b->units += cur->next->units;
ffffffffc0202eba:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0202ebc:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0202ebe:	9db5                	addw	a1,a1,a3
ffffffffc0202ec0:	c00c                	sw	a1,0(s0)
	if (cur + cur->units == b) {
ffffffffc0202ec2:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc0202ec4:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b) {
ffffffffc0202ec6:	00469793          	slli	a5,a3,0x4
ffffffffc0202eca:	97ba                	add	a5,a5,a4
ffffffffc0202ecc:	fcf416e3          	bne	s0,a5,ffffffffc0202e98 <slob_free+0x4a>
		cur->units += b->units;
ffffffffc0202ed0:	401c                	lw	a5,0(s0)
		cur->next = b->next;
ffffffffc0202ed2:	640c                	ld	a1,8(s0)
	slobfree = cur;
ffffffffc0202ed4:	e218                	sd	a4,0(a2)
		cur->units += b->units;
ffffffffc0202ed6:	9ebd                	addw	a3,a3,a5
ffffffffc0202ed8:	c314                	sw	a3,0(a4)
		cur->next = b->next;
ffffffffc0202eda:	e70c                	sd	a1,8(a4)
ffffffffc0202edc:	d169                	beqz	a0,ffffffffc0202e9e <slob_free+0x50>
}
ffffffffc0202ede:	6402                	ld	s0,0(sp)
ffffffffc0202ee0:	60a2                	ld	ra,8(sp)
ffffffffc0202ee2:	0141                	addi	sp,sp,16
        intr_enable(); // 使能中断
ffffffffc0202ee4:	edafd06f          	j	ffffffffc02005be <intr_enable>
		b->units = SLOB_UNITS(size);
ffffffffc0202ee8:	25bd                	addiw	a1,a1,15
ffffffffc0202eea:	8191                	srli	a1,a1,0x4
ffffffffc0202eec:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE) { // 如果当前中断使能
ffffffffc0202eee:	100027f3          	csrr	a5,sstatus
ffffffffc0202ef2:	8b89                	andi	a5,a5,2
    return 0; // 返回0表示中断之前是禁用的
ffffffffc0202ef4:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE) { // 如果当前中断使能
ffffffffc0202ef6:	d7bd                	beqz	a5,ffffffffc0202e64 <slob_free+0x16>
        intr_disable(); // 禁用中断
ffffffffc0202ef8:	eccfd0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
        return 1; // 返回1表示中断之前是使能的
ffffffffc0202efc:	4505                	li	a0,1
ffffffffc0202efe:	b79d                	j	ffffffffc0202e64 <slob_free+0x16>
ffffffffc0202f00:	8082                	ret

ffffffffc0202f02 <__slob_get_free_pages.constprop.0>:
  struct Page * page = alloc_pages(1 << order);
ffffffffc0202f02:	4785                	li	a5,1
static void* __slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0202f04:	1141                	addi	sp,sp,-16
  struct Page * page = alloc_pages(1 << order);
ffffffffc0202f06:	00a7953b          	sllw	a0,a5,a0
static void* __slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0202f0a:	e406                	sd	ra,8(sp)
  struct Page * page = alloc_pages(1 << order);
ffffffffc0202f0c:	c9ffd0ef          	jal	ra,ffffffffc0200baa <alloc_pages>
  if(!page)
ffffffffc0202f10:	c91d                	beqz	a0,ffffffffc0202f46 <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc0202f12:	00013697          	auipc	a3,0x13
ffffffffc0202f16:	6566b683          	ld	a3,1622(a3) # ffffffffc0216568 <pages>
ffffffffc0202f1a:	8d15                	sub	a0,a0,a3
ffffffffc0202f1c:	8519                	srai	a0,a0,0x6
ffffffffc0202f1e:	00004697          	auipc	a3,0x4
ffffffffc0202f22:	0ea6b683          	ld	a3,234(a3) # ffffffffc0207008 <nbase>
ffffffffc0202f26:	9536                	add	a0,a0,a3
    return KADDR(page2pa(page));
ffffffffc0202f28:	00c51793          	slli	a5,a0,0xc
ffffffffc0202f2c:	83b1                	srli	a5,a5,0xc
ffffffffc0202f2e:	00013717          	auipc	a4,0x13
ffffffffc0202f32:	63273703          	ld	a4,1586(a4) # ffffffffc0216560 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc0202f36:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc0202f38:	00e7fa63          	bgeu	a5,a4,ffffffffc0202f4c <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc0202f3c:	00013697          	auipc	a3,0x13
ffffffffc0202f40:	63c6b683          	ld	a3,1596(a3) # ffffffffc0216578 <va_pa_offset>
ffffffffc0202f44:	9536                	add	a0,a0,a3
}
ffffffffc0202f46:	60a2                	ld	ra,8(sp)
ffffffffc0202f48:	0141                	addi	sp,sp,16
ffffffffc0202f4a:	8082                	ret
ffffffffc0202f4c:	86aa                	mv	a3,a0
ffffffffc0202f4e:	00003617          	auipc	a2,0x3
ffffffffc0202f52:	9c260613          	addi	a2,a2,-1598 # ffffffffc0205910 <commands+0x760>
ffffffffc0202f56:	06700593          	li	a1,103
ffffffffc0202f5a:	00003517          	auipc	a0,0x3
ffffffffc0202f5e:	97e50513          	addi	a0,a0,-1666 # ffffffffc02058d8 <commands+0x728>
ffffffffc0202f62:	a66fd0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc0202f66 <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc0202f66:	1101                	addi	sp,sp,-32
ffffffffc0202f68:	ec06                	sd	ra,24(sp)
ffffffffc0202f6a:	e822                	sd	s0,16(sp)
ffffffffc0202f6c:	e426                	sd	s1,8(sp)
ffffffffc0202f6e:	e04a                	sd	s2,0(sp)
	assert( (size + SLOB_UNIT) < PAGE_SIZE );
ffffffffc0202f70:	01050713          	addi	a4,a0,16
ffffffffc0202f74:	6785                	lui	a5,0x1
ffffffffc0202f76:	0cf77363          	bgeu	a4,a5,ffffffffc020303c <slob_alloc.constprop.0+0xd6>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc0202f7a:	00f50493          	addi	s1,a0,15
ffffffffc0202f7e:	8091                	srli	s1,s1,0x4
ffffffffc0202f80:	2481                	sext.w	s1,s1
    if (read_csr(sstatus) & SSTATUS_SIE) { // 如果当前中断使能
ffffffffc0202f82:	10002673          	csrr	a2,sstatus
ffffffffc0202f86:	8a09                	andi	a2,a2,2
ffffffffc0202f88:	e25d                	bnez	a2,ffffffffc020302e <slob_alloc.constprop.0+0xc8>
	prev = slobfree;
ffffffffc0202f8a:	00008917          	auipc	s2,0x8
ffffffffc0202f8e:	0c690913          	addi	s2,s2,198 # ffffffffc020b050 <slobfree>
ffffffffc0202f92:	00093683          	ld	a3,0(s2)
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
ffffffffc0202f96:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc0202f98:	4398                	lw	a4,0(a5)
ffffffffc0202f9a:	08975e63          	bge	a4,s1,ffffffffc0203036 <slob_alloc.constprop.0+0xd0>
		if (cur == slobfree) {
ffffffffc0202f9e:	00d78b63          	beq	a5,a3,ffffffffc0202fb4 <slob_alloc.constprop.0+0x4e>
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
ffffffffc0202fa2:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc0202fa4:	4018                	lw	a4,0(s0)
ffffffffc0202fa6:	02975a63          	bge	a4,s1,ffffffffc0202fda <slob_alloc.constprop.0+0x74>
		if (cur == slobfree) {
ffffffffc0202faa:	00093683          	ld	a3,0(s2)
ffffffffc0202fae:	87a2                	mv	a5,s0
ffffffffc0202fb0:	fed799e3          	bne	a5,a3,ffffffffc0202fa2 <slob_alloc.constprop.0+0x3c>
    if (flag) { // 如果flag为1
ffffffffc0202fb4:	ee31                	bnez	a2,ffffffffc0203010 <slob_alloc.constprop.0+0xaa>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0202fb6:	4501                	li	a0,0
ffffffffc0202fb8:	f4bff0ef          	jal	ra,ffffffffc0202f02 <__slob_get_free_pages.constprop.0>
ffffffffc0202fbc:	842a                	mv	s0,a0
			if (!cur)
ffffffffc0202fbe:	cd05                	beqz	a0,ffffffffc0202ff6 <slob_alloc.constprop.0+0x90>
			slob_free(cur, PAGE_SIZE);
ffffffffc0202fc0:	6585                	lui	a1,0x1
ffffffffc0202fc2:	e8dff0ef          	jal	ra,ffffffffc0202e4e <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE) { // 如果当前中断使能
ffffffffc0202fc6:	10002673          	csrr	a2,sstatus
ffffffffc0202fca:	8a09                	andi	a2,a2,2
ffffffffc0202fcc:	ee05                	bnez	a2,ffffffffc0203004 <slob_alloc.constprop.0+0x9e>
			cur = slobfree;
ffffffffc0202fce:	00093783          	ld	a5,0(s2)
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
ffffffffc0202fd2:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc0202fd4:	4018                	lw	a4,0(s0)
ffffffffc0202fd6:	fc974ae3          	blt	a4,s1,ffffffffc0202faa <slob_alloc.constprop.0+0x44>
			if (cur->units == units) /* exact fit? */
ffffffffc0202fda:	04e48763          	beq	s1,a4,ffffffffc0203028 <slob_alloc.constprop.0+0xc2>
				prev->next = cur + units;
ffffffffc0202fde:	00449693          	slli	a3,s1,0x4
ffffffffc0202fe2:	96a2                	add	a3,a3,s0
ffffffffc0202fe4:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next;
ffffffffc0202fe6:	640c                	ld	a1,8(s0)
				prev->next->units = cur->units - units;
ffffffffc0202fe8:	9f05                	subw	a4,a4,s1
ffffffffc0202fea:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next;
ffffffffc0202fec:	e68c                	sd	a1,8(a3)
				cur->units = units;
ffffffffc0202fee:	c004                	sw	s1,0(s0)
			slobfree = prev;
ffffffffc0202ff0:	00f93023          	sd	a5,0(s2)
    if (flag) { // 如果flag为1
ffffffffc0202ff4:	e20d                	bnez	a2,ffffffffc0203016 <slob_alloc.constprop.0+0xb0>
}
ffffffffc0202ff6:	60e2                	ld	ra,24(sp)
ffffffffc0202ff8:	8522                	mv	a0,s0
ffffffffc0202ffa:	6442                	ld	s0,16(sp)
ffffffffc0202ffc:	64a2                	ld	s1,8(sp)
ffffffffc0202ffe:	6902                	ld	s2,0(sp)
ffffffffc0203000:	6105                	addi	sp,sp,32
ffffffffc0203002:	8082                	ret
        intr_disable(); // 禁用中断
ffffffffc0203004:	dc0fd0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
			cur = slobfree;
ffffffffc0203008:	00093783          	ld	a5,0(s2)
        return 1; // 返回1表示中断之前是使能的
ffffffffc020300c:	4605                	li	a2,1
ffffffffc020300e:	b7d1                	j	ffffffffc0202fd2 <slob_alloc.constprop.0+0x6c>
        intr_enable(); // 使能中断
ffffffffc0203010:	daefd0ef          	jal	ra,ffffffffc02005be <intr_enable>
ffffffffc0203014:	b74d                	j	ffffffffc0202fb6 <slob_alloc.constprop.0+0x50>
ffffffffc0203016:	da8fd0ef          	jal	ra,ffffffffc02005be <intr_enable>
}
ffffffffc020301a:	60e2                	ld	ra,24(sp)
ffffffffc020301c:	8522                	mv	a0,s0
ffffffffc020301e:	6442                	ld	s0,16(sp)
ffffffffc0203020:	64a2                	ld	s1,8(sp)
ffffffffc0203022:	6902                	ld	s2,0(sp)
ffffffffc0203024:	6105                	addi	sp,sp,32
ffffffffc0203026:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0203028:	6418                	ld	a4,8(s0)
ffffffffc020302a:	e798                	sd	a4,8(a5)
ffffffffc020302c:	b7d1                	j	ffffffffc0202ff0 <slob_alloc.constprop.0+0x8a>
        intr_disable(); // 禁用中断
ffffffffc020302e:	d96fd0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
        return 1; // 返回1表示中断之前是使能的
ffffffffc0203032:	4605                	li	a2,1
ffffffffc0203034:	bf99                	j	ffffffffc0202f8a <slob_alloc.constprop.0+0x24>
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc0203036:	843e                	mv	s0,a5
ffffffffc0203038:	87b6                	mv	a5,a3
ffffffffc020303a:	b745                	j	ffffffffc0202fda <slob_alloc.constprop.0+0x74>
	assert( (size + SLOB_UNIT) < PAGE_SIZE );
ffffffffc020303c:	00003697          	auipc	a3,0x3
ffffffffc0203040:	59c68693          	addi	a3,a3,1436 # ffffffffc02065d8 <commands+0x1428>
ffffffffc0203044:	00003617          	auipc	a2,0x3
ffffffffc0203048:	9dc60613          	addi	a2,a2,-1572 # ffffffffc0205a20 <commands+0x870>
ffffffffc020304c:	07c00593          	li	a1,124
ffffffffc0203050:	00003517          	auipc	a0,0x3
ffffffffc0203054:	5a850513          	addi	a0,a0,1448 # ffffffffc02065f8 <commands+0x1448>
ffffffffc0203058:	970fd0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc020305c <kmalloc_init>:
}

/**
 * kmalloc_init - 初始化kmalloc
 */
inline void kmalloc_init(void) {
ffffffffc020305c:	1141                	addi	sp,sp,-16
  cprintf("use SLOB allocator\n");
ffffffffc020305e:	00003517          	auipc	a0,0x3
ffffffffc0203062:	5b250513          	addi	a0,a0,1458 # ffffffffc0206610 <commands+0x1460>
inline void kmalloc_init(void) {
ffffffffc0203066:	e406                	sd	ra,8(sp)
  cprintf("use SLOB allocator\n");
ffffffffc0203068:	864fd0ef          	jal	ra,ffffffffc02000cc <cprintf>
	slob_init();
	cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc020306c:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc020306e:	00003517          	auipc	a0,0x3
ffffffffc0203072:	5ba50513          	addi	a0,a0,1466 # ffffffffc0206628 <commands+0x1478>
}
ffffffffc0203076:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0203078:	854fd06f          	j	ffffffffc02000cc <cprintf>

ffffffffc020307c <kmalloc>:
 * @size: 要分配的内存块大小
 *
 * 返回分配的内存块指针，如果分配失败则返回NULL
 */
void *kmalloc(size_t size)
{
ffffffffc020307c:	1101                	addi	sp,sp,-32
ffffffffc020307e:	e04a                	sd	s2,0(sp)
	if (size < PAGE_SIZE - SLOB_UNIT) {
ffffffffc0203080:	6905                	lui	s2,0x1
{
ffffffffc0203082:	e822                	sd	s0,16(sp)
ffffffffc0203084:	ec06                	sd	ra,24(sp)
ffffffffc0203086:	e426                	sd	s1,8(sp)
	if (size < PAGE_SIZE - SLOB_UNIT) {
ffffffffc0203088:	fef90793          	addi	a5,s2,-17 # fef <kern_entry-0xffffffffc01ff011>
{
ffffffffc020308c:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT) {
ffffffffc020308e:	04a7f963          	bgeu	a5,a0,ffffffffc02030e0 <kmalloc+0x64>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0203092:	4561                	li	a0,24
ffffffffc0203094:	ed3ff0ef          	jal	ra,ffffffffc0202f66 <slob_alloc.constprop.0>
ffffffffc0203098:	84aa                	mv	s1,a0
	if (!bb)
ffffffffc020309a:	c929                	beqz	a0,ffffffffc02030ec <kmalloc+0x70>
	bb->order = find_order(size);
ffffffffc020309c:	0004079b          	sext.w	a5,s0
	int order = 0;
ffffffffc02030a0:	4501                	li	a0,0
	for ( ; size > 4096 ; size >>=1)
ffffffffc02030a2:	00f95763          	bge	s2,a5,ffffffffc02030b0 <kmalloc+0x34>
ffffffffc02030a6:	6705                	lui	a4,0x1
ffffffffc02030a8:	8785                	srai	a5,a5,0x1
		order++;
ffffffffc02030aa:	2505                	addiw	a0,a0,1
	for ( ; size > 4096 ; size >>=1)
ffffffffc02030ac:	fef74ee3          	blt	a4,a5,ffffffffc02030a8 <kmalloc+0x2c>
	bb->order = find_order(size);
ffffffffc02030b0:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc02030b2:	e51ff0ef          	jal	ra,ffffffffc0202f02 <__slob_get_free_pages.constprop.0>
ffffffffc02030b6:	e488                	sd	a0,8(s1)
ffffffffc02030b8:	842a                	mv	s0,a0
	if (bb->pages) {
ffffffffc02030ba:	c525                	beqz	a0,ffffffffc0203122 <kmalloc+0xa6>
    if (read_csr(sstatus) & SSTATUS_SIE) { // 如果当前中断使能
ffffffffc02030bc:	100027f3          	csrr	a5,sstatus
ffffffffc02030c0:	8b89                	andi	a5,a5,2
ffffffffc02030c2:	ef8d                	bnez	a5,ffffffffc02030fc <kmalloc+0x80>
		bb->next = bigblocks;
ffffffffc02030c4:	00013797          	auipc	a5,0x13
ffffffffc02030c8:	4e478793          	addi	a5,a5,1252 # ffffffffc02165a8 <bigblocks>
ffffffffc02030cc:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc02030ce:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc02030d0:	e898                	sd	a4,16(s1)
  return __kmalloc(size, 0);
}
ffffffffc02030d2:	60e2                	ld	ra,24(sp)
ffffffffc02030d4:	8522                	mv	a0,s0
ffffffffc02030d6:	6442                	ld	s0,16(sp)
ffffffffc02030d8:	64a2                	ld	s1,8(sp)
ffffffffc02030da:	6902                	ld	s2,0(sp)
ffffffffc02030dc:	6105                	addi	sp,sp,32
ffffffffc02030de:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc02030e0:	0541                	addi	a0,a0,16
ffffffffc02030e2:	e85ff0ef          	jal	ra,ffffffffc0202f66 <slob_alloc.constprop.0>
		return m ? (void *)(m + 1) : 0;
ffffffffc02030e6:	01050413          	addi	s0,a0,16
ffffffffc02030ea:	f565                	bnez	a0,ffffffffc02030d2 <kmalloc+0x56>
ffffffffc02030ec:	4401                	li	s0,0
}
ffffffffc02030ee:	60e2                	ld	ra,24(sp)
ffffffffc02030f0:	8522                	mv	a0,s0
ffffffffc02030f2:	6442                	ld	s0,16(sp)
ffffffffc02030f4:	64a2                	ld	s1,8(sp)
ffffffffc02030f6:	6902                	ld	s2,0(sp)
ffffffffc02030f8:	6105                	addi	sp,sp,32
ffffffffc02030fa:	8082                	ret
        intr_disable(); // 禁用中断
ffffffffc02030fc:	cc8fd0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
		bb->next = bigblocks;
ffffffffc0203100:	00013797          	auipc	a5,0x13
ffffffffc0203104:	4a878793          	addi	a5,a5,1192 # ffffffffc02165a8 <bigblocks>
ffffffffc0203108:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc020310a:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc020310c:	e898                	sd	a4,16(s1)
        intr_enable(); // 使能中断
ffffffffc020310e:	cb0fd0ef          	jal	ra,ffffffffc02005be <intr_enable>
		return bb->pages;
ffffffffc0203112:	6480                	ld	s0,8(s1)
}
ffffffffc0203114:	60e2                	ld	ra,24(sp)
ffffffffc0203116:	64a2                	ld	s1,8(sp)
ffffffffc0203118:	8522                	mv	a0,s0
ffffffffc020311a:	6442                	ld	s0,16(sp)
ffffffffc020311c:	6902                	ld	s2,0(sp)
ffffffffc020311e:	6105                	addi	sp,sp,32
ffffffffc0203120:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0203122:	45e1                	li	a1,24
ffffffffc0203124:	8526                	mv	a0,s1
ffffffffc0203126:	d29ff0ef          	jal	ra,ffffffffc0202e4e <slob_free>
  return __kmalloc(size, 0);
ffffffffc020312a:	b765                	j	ffffffffc02030d2 <kmalloc+0x56>

ffffffffc020312c <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc020312c:	c179                	beqz	a0,ffffffffc02031f2 <kfree+0xc6>
{
ffffffffc020312e:	1101                	addi	sp,sp,-32
ffffffffc0203130:	e822                	sd	s0,16(sp)
ffffffffc0203132:	ec06                	sd	ra,24(sp)
ffffffffc0203134:	e426                	sd	s1,8(sp)
		return;

	if (!((unsigned long)block & (PAGE_SIZE-1))) {
ffffffffc0203136:	03451793          	slli	a5,a0,0x34
ffffffffc020313a:	842a                	mv	s0,a0
ffffffffc020313c:	e7c1                	bnez	a5,ffffffffc02031c4 <kfree+0x98>
    if (read_csr(sstatus) & SSTATUS_SIE) { // 如果当前中断使能
ffffffffc020313e:	100027f3          	csrr	a5,sstatus
ffffffffc0203142:	8b89                	andi	a5,a5,2
ffffffffc0203144:	ebc9                	bnez	a5,ffffffffc02031d6 <kfree+0xaa>
		/* 可能在大块列表中 */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc0203146:	00013797          	auipc	a5,0x13
ffffffffc020314a:	4627b783          	ld	a5,1122(a5) # ffffffffc02165a8 <bigblocks>
    return 0; // 返回0表示中断之前是禁用的
ffffffffc020314e:	4601                	li	a2,0
ffffffffc0203150:	cbb5                	beqz	a5,ffffffffc02031c4 <kfree+0x98>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0203152:	00013697          	auipc	a3,0x13
ffffffffc0203156:	45668693          	addi	a3,a3,1110 # ffffffffc02165a8 <bigblocks>
ffffffffc020315a:	a021                	j	ffffffffc0203162 <kfree+0x36>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc020315c:	01048693          	addi	a3,s1,16
ffffffffc0203160:	c3ad                	beqz	a5,ffffffffc02031c2 <kfree+0x96>
			if (bb->pages == block) {
ffffffffc0203162:	6798                	ld	a4,8(a5)
ffffffffc0203164:	84be                	mv	s1,a5
				*last = bb->next;
ffffffffc0203166:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block) {
ffffffffc0203168:	fe871ae3          	bne	a4,s0,ffffffffc020315c <kfree+0x30>
				*last = bb->next;
ffffffffc020316c:	e29c                	sd	a5,0(a3)
    if (flag) { // 如果flag为1
ffffffffc020316e:	ee3d                	bnez	a2,ffffffffc02031ec <kfree+0xc0>
    return pa2page(PADDR(kva));
ffffffffc0203170:	c02007b7          	lui	a5,0xc0200
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
ffffffffc0203174:	4098                	lw	a4,0(s1)
ffffffffc0203176:	08f46b63          	bltu	s0,a5,ffffffffc020320c <kfree+0xe0>
ffffffffc020317a:	00013697          	auipc	a3,0x13
ffffffffc020317e:	3fe6b683          	ld	a3,1022(a3) # ffffffffc0216578 <va_pa_offset>
ffffffffc0203182:	8c15                	sub	s0,s0,a3
    if (PPN(pa) >= npage) {
ffffffffc0203184:	8031                	srli	s0,s0,0xc
ffffffffc0203186:	00013797          	auipc	a5,0x13
ffffffffc020318a:	3da7b783          	ld	a5,986(a5) # ffffffffc0216560 <npage>
ffffffffc020318e:	06f47363          	bgeu	s0,a5,ffffffffc02031f4 <kfree+0xc8>
    return &pages[PPN(pa) - nbase];
ffffffffc0203192:	00004517          	auipc	a0,0x4
ffffffffc0203196:	e7653503          	ld	a0,-394(a0) # ffffffffc0207008 <nbase>
ffffffffc020319a:	8c09                	sub	s0,s0,a0
ffffffffc020319c:	041a                	slli	s0,s0,0x6
  free_pages(kva2page(kva), 1 << order);
ffffffffc020319e:	00013517          	auipc	a0,0x13
ffffffffc02031a2:	3ca53503          	ld	a0,970(a0) # ffffffffc0216568 <pages>
ffffffffc02031a6:	4585                	li	a1,1
ffffffffc02031a8:	9522                	add	a0,a0,s0
ffffffffc02031aa:	00e595bb          	sllw	a1,a1,a4
ffffffffc02031ae:	a8ffd0ef          	jal	ra,ffffffffc0200c3c <free_pages>
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc02031b2:	6442                	ld	s0,16(sp)
ffffffffc02031b4:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc02031b6:	8526                	mv	a0,s1
}
ffffffffc02031b8:	64a2                	ld	s1,8(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc02031ba:	45e1                	li	a1,24
}
ffffffffc02031bc:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc02031be:	c91ff06f          	j	ffffffffc0202e4e <slob_free>
ffffffffc02031c2:	e215                	bnez	a2,ffffffffc02031e6 <kfree+0xba>
ffffffffc02031c4:	ff040513          	addi	a0,s0,-16
}
ffffffffc02031c8:	6442                	ld	s0,16(sp)
ffffffffc02031ca:	60e2                	ld	ra,24(sp)
ffffffffc02031cc:	64a2                	ld	s1,8(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc02031ce:	4581                	li	a1,0
}
ffffffffc02031d0:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc02031d2:	c7dff06f          	j	ffffffffc0202e4e <slob_free>
        intr_disable(); // 禁用中断
ffffffffc02031d6:	beefd0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc02031da:	00013797          	auipc	a5,0x13
ffffffffc02031de:	3ce7b783          	ld	a5,974(a5) # ffffffffc02165a8 <bigblocks>
        return 1; // 返回1表示中断之前是使能的
ffffffffc02031e2:	4605                	li	a2,1
ffffffffc02031e4:	f7bd                	bnez	a5,ffffffffc0203152 <kfree+0x26>
        intr_enable(); // 使能中断
ffffffffc02031e6:	bd8fd0ef          	jal	ra,ffffffffc02005be <intr_enable>
ffffffffc02031ea:	bfe9                	j	ffffffffc02031c4 <kfree+0x98>
ffffffffc02031ec:	bd2fd0ef          	jal	ra,ffffffffc02005be <intr_enable>
ffffffffc02031f0:	b741                	j	ffffffffc0203170 <kfree+0x44>
ffffffffc02031f2:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc02031f4:	00002617          	auipc	a2,0x2
ffffffffc02031f8:	6c460613          	addi	a2,a2,1732 # ffffffffc02058b8 <commands+0x708>
ffffffffc02031fc:	06000593          	li	a1,96
ffffffffc0203200:	00002517          	auipc	a0,0x2
ffffffffc0203204:	6d850513          	addi	a0,a0,1752 # ffffffffc02058d8 <commands+0x728>
ffffffffc0203208:	fc1fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    return pa2page(PADDR(kva));
ffffffffc020320c:	86a2                	mv	a3,s0
ffffffffc020320e:	00002617          	auipc	a2,0x2
ffffffffc0203212:	79260613          	addi	a2,a2,1938 # ffffffffc02059a0 <commands+0x7f0>
ffffffffc0203216:	06c00593          	li	a1,108
ffffffffc020321a:	00002517          	auipc	a0,0x2
ffffffffc020321e:	6be50513          	addi	a0,a0,1726 # ffffffffc02058d8 <commands+0x728>
ffffffffc0203222:	fa7fc0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc0203226 <_fifo_init_mm>:
    elm->prev = elm->next = elm; // 将节点的前后指针都指向自己
ffffffffc0203226:	0000f797          	auipc	a5,0xf
ffffffffc020322a:	2ca78793          	addi	a5,a5,714 # ffffffffc02124f0 <pra_list_head>
 */
static int
_fifo_init_mm(struct mm_struct *mm)
{     
    list_init(&pra_list_head); // 初始化pra_list_head
    mm->sm_priv = &pra_list_head; // 让mm->sm_priv指向pra_list_head的地址
ffffffffc020322e:	f51c                	sd	a5,40(a0)
ffffffffc0203230:	e79c                	sd	a5,8(a5)
ffffffffc0203232:	e39c                	sd	a5,0(a5)
    //cprintf(" mm->sm_priv %x in fifo_init_mm\n",mm->sm_priv);
    return 0;
}
ffffffffc0203234:	4501                	li	a0,0
ffffffffc0203236:	8082                	ret

ffffffffc0203238 <_fifo_init>:
 */
static int
_fifo_init(void)
{
    return 0;
}
ffffffffc0203238:	4501                	li	a0,0
ffffffffc020323a:	8082                	ret

ffffffffc020323c <_fifo_set_unswappable>:
 */
static int
_fifo_set_unswappable(struct mm_struct *mm, uintptr_t addr)
{
    return 0;
}
ffffffffc020323c:	4501                	li	a0,0
ffffffffc020323e:	8082                	ret

ffffffffc0203240 <_fifo_tick_event>:
 */
static int
_fifo_tick_event(struct mm_struct *mm)
{ 
    return 0; 
}
ffffffffc0203240:	4501                	li	a0,0
ffffffffc0203242:	8082                	ret

ffffffffc0203244 <_fifo_check_swap>:
_fifo_check_swap(void) {
ffffffffc0203244:	711d                	addi	sp,sp,-96
ffffffffc0203246:	fc4e                	sd	s3,56(sp)
ffffffffc0203248:	f852                	sd	s4,48(sp)
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc020324a:	00003517          	auipc	a0,0x3
ffffffffc020324e:	3fe50513          	addi	a0,a0,1022 # ffffffffc0206648 <commands+0x1498>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc0203252:	698d                	lui	s3,0x3
ffffffffc0203254:	4a31                	li	s4,12
_fifo_check_swap(void) {
ffffffffc0203256:	e0ca                	sd	s2,64(sp)
ffffffffc0203258:	ec86                	sd	ra,88(sp)
ffffffffc020325a:	e8a2                	sd	s0,80(sp)
ffffffffc020325c:	e4a6                	sd	s1,72(sp)
ffffffffc020325e:	f456                	sd	s5,40(sp)
ffffffffc0203260:	f05a                	sd	s6,32(sp)
ffffffffc0203262:	ec5e                	sd	s7,24(sp)
ffffffffc0203264:	e862                	sd	s8,16(sp)
ffffffffc0203266:	e466                	sd	s9,8(sp)
ffffffffc0203268:	e06a                	sd	s10,0(sp)
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc020326a:	e63fc0ef          	jal	ra,ffffffffc02000cc <cprintf>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc020326e:	01498023          	sb	s4,0(s3) # 3000 <kern_entry-0xffffffffc01fd000>
    assert(pgfault_num==4);
ffffffffc0203272:	00013917          	auipc	s2,0x13
ffffffffc0203276:	31692903          	lw	s2,790(s2) # ffffffffc0216588 <pgfault_num>
ffffffffc020327a:	4791                	li	a5,4
ffffffffc020327c:	14f91e63          	bne	s2,a5,ffffffffc02033d8 <_fifo_check_swap+0x194>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0203280:	00003517          	auipc	a0,0x3
ffffffffc0203284:	40850513          	addi	a0,a0,1032 # ffffffffc0206688 <commands+0x14d8>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc0203288:	6a85                	lui	s5,0x1
ffffffffc020328a:	4b29                	li	s6,10
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc020328c:	e41fc0ef          	jal	ra,ffffffffc02000cc <cprintf>
ffffffffc0203290:	00013417          	auipc	s0,0x13
ffffffffc0203294:	2f840413          	addi	s0,s0,760 # ffffffffc0216588 <pgfault_num>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc0203298:	016a8023          	sb	s6,0(s5) # 1000 <kern_entry-0xffffffffc01ff000>
    assert(pgfault_num==4);
ffffffffc020329c:	4004                	lw	s1,0(s0)
ffffffffc020329e:	2481                	sext.w	s1,s1
ffffffffc02032a0:	2b249c63          	bne	s1,s2,ffffffffc0203558 <_fifo_check_swap+0x314>
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc02032a4:	00003517          	auipc	a0,0x3
ffffffffc02032a8:	40c50513          	addi	a0,a0,1036 # ffffffffc02066b0 <commands+0x1500>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc02032ac:	6b91                	lui	s7,0x4
ffffffffc02032ae:	4c35                	li	s8,13
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc02032b0:	e1dfc0ef          	jal	ra,ffffffffc02000cc <cprintf>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc02032b4:	018b8023          	sb	s8,0(s7) # 4000 <kern_entry-0xffffffffc01fc000>
    assert(pgfault_num==4);
ffffffffc02032b8:	00042903          	lw	s2,0(s0)
ffffffffc02032bc:	2901                	sext.w	s2,s2
ffffffffc02032be:	26991d63          	bne	s2,s1,ffffffffc0203538 <_fifo_check_swap+0x2f4>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc02032c2:	00003517          	auipc	a0,0x3
ffffffffc02032c6:	41650513          	addi	a0,a0,1046 # ffffffffc02066d8 <commands+0x1528>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc02032ca:	6c89                	lui	s9,0x2
ffffffffc02032cc:	4d2d                	li	s10,11
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc02032ce:	dfffc0ef          	jal	ra,ffffffffc02000cc <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc02032d2:	01ac8023          	sb	s10,0(s9) # 2000 <kern_entry-0xffffffffc01fe000>
    assert(pgfault_num==4);
ffffffffc02032d6:	401c                	lw	a5,0(s0)
ffffffffc02032d8:	2781                	sext.w	a5,a5
ffffffffc02032da:	23279f63          	bne	a5,s2,ffffffffc0203518 <_fifo_check_swap+0x2d4>
    cprintf("write Virt Page e in fifo_check_swap\n");
ffffffffc02032de:	00003517          	auipc	a0,0x3
ffffffffc02032e2:	42250513          	addi	a0,a0,1058 # ffffffffc0206700 <commands+0x1550>
ffffffffc02032e6:	de7fc0ef          	jal	ra,ffffffffc02000cc <cprintf>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc02032ea:	6795                	lui	a5,0x5
ffffffffc02032ec:	4739                	li	a4,14
ffffffffc02032ee:	00e78023          	sb	a4,0(a5) # 5000 <kern_entry-0xffffffffc01fb000>
    assert(pgfault_num==5);
ffffffffc02032f2:	4004                	lw	s1,0(s0)
ffffffffc02032f4:	4795                	li	a5,5
ffffffffc02032f6:	2481                	sext.w	s1,s1
ffffffffc02032f8:	20f49063          	bne	s1,a5,ffffffffc02034f8 <_fifo_check_swap+0x2b4>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc02032fc:	00003517          	auipc	a0,0x3
ffffffffc0203300:	3dc50513          	addi	a0,a0,988 # ffffffffc02066d8 <commands+0x1528>
ffffffffc0203304:	dc9fc0ef          	jal	ra,ffffffffc02000cc <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0203308:	01ac8023          	sb	s10,0(s9)
    assert(pgfault_num==5);
ffffffffc020330c:	401c                	lw	a5,0(s0)
ffffffffc020330e:	2781                	sext.w	a5,a5
ffffffffc0203310:	1c979463          	bne	a5,s1,ffffffffc02034d8 <_fifo_check_swap+0x294>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0203314:	00003517          	auipc	a0,0x3
ffffffffc0203318:	37450513          	addi	a0,a0,884 # ffffffffc0206688 <commands+0x14d8>
ffffffffc020331c:	db1fc0ef          	jal	ra,ffffffffc02000cc <cprintf>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc0203320:	016a8023          	sb	s6,0(s5)
    assert(pgfault_num==6);
ffffffffc0203324:	401c                	lw	a5,0(s0)
ffffffffc0203326:	4719                	li	a4,6
ffffffffc0203328:	2781                	sext.w	a5,a5
ffffffffc020332a:	18e79763          	bne	a5,a4,ffffffffc02034b8 <_fifo_check_swap+0x274>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc020332e:	00003517          	auipc	a0,0x3
ffffffffc0203332:	3aa50513          	addi	a0,a0,938 # ffffffffc02066d8 <commands+0x1528>
ffffffffc0203336:	d97fc0ef          	jal	ra,ffffffffc02000cc <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc020333a:	01ac8023          	sb	s10,0(s9)
    assert(pgfault_num==7);
ffffffffc020333e:	401c                	lw	a5,0(s0)
ffffffffc0203340:	471d                	li	a4,7
ffffffffc0203342:	2781                	sext.w	a5,a5
ffffffffc0203344:	14e79a63          	bne	a5,a4,ffffffffc0203498 <_fifo_check_swap+0x254>
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc0203348:	00003517          	auipc	a0,0x3
ffffffffc020334c:	30050513          	addi	a0,a0,768 # ffffffffc0206648 <commands+0x1498>
ffffffffc0203350:	d7dfc0ef          	jal	ra,ffffffffc02000cc <cprintf>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc0203354:	01498023          	sb	s4,0(s3)
    assert(pgfault_num==8);
ffffffffc0203358:	401c                	lw	a5,0(s0)
ffffffffc020335a:	4721                	li	a4,8
ffffffffc020335c:	2781                	sext.w	a5,a5
ffffffffc020335e:	10e79d63          	bne	a5,a4,ffffffffc0203478 <_fifo_check_swap+0x234>
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc0203362:	00003517          	auipc	a0,0x3
ffffffffc0203366:	34e50513          	addi	a0,a0,846 # ffffffffc02066b0 <commands+0x1500>
ffffffffc020336a:	d63fc0ef          	jal	ra,ffffffffc02000cc <cprintf>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc020336e:	018b8023          	sb	s8,0(s7)
    assert(pgfault_num==9);
ffffffffc0203372:	401c                	lw	a5,0(s0)
ffffffffc0203374:	4725                	li	a4,9
ffffffffc0203376:	2781                	sext.w	a5,a5
ffffffffc0203378:	0ee79063          	bne	a5,a4,ffffffffc0203458 <_fifo_check_swap+0x214>
    cprintf("write Virt Page e in fifo_check_swap\n");
ffffffffc020337c:	00003517          	auipc	a0,0x3
ffffffffc0203380:	38450513          	addi	a0,a0,900 # ffffffffc0206700 <commands+0x1550>
ffffffffc0203384:	d49fc0ef          	jal	ra,ffffffffc02000cc <cprintf>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc0203388:	6795                	lui	a5,0x5
ffffffffc020338a:	4739                	li	a4,14
ffffffffc020338c:	00e78023          	sb	a4,0(a5) # 5000 <kern_entry-0xffffffffc01fb000>
    assert(pgfault_num==10);
ffffffffc0203390:	4004                	lw	s1,0(s0)
ffffffffc0203392:	47a9                	li	a5,10
ffffffffc0203394:	2481                	sext.w	s1,s1
ffffffffc0203396:	0af49163          	bne	s1,a5,ffffffffc0203438 <_fifo_check_swap+0x1f4>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc020339a:	00003517          	auipc	a0,0x3
ffffffffc020339e:	2ee50513          	addi	a0,a0,750 # ffffffffc0206688 <commands+0x14d8>
ffffffffc02033a2:	d2bfc0ef          	jal	ra,ffffffffc02000cc <cprintf>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc02033a6:	6785                	lui	a5,0x1
ffffffffc02033a8:	0007c783          	lbu	a5,0(a5) # 1000 <kern_entry-0xffffffffc01ff000>
ffffffffc02033ac:	06979663          	bne	a5,s1,ffffffffc0203418 <_fifo_check_swap+0x1d4>
    assert(pgfault_num==11);
ffffffffc02033b0:	401c                	lw	a5,0(s0)
ffffffffc02033b2:	472d                	li	a4,11
ffffffffc02033b4:	2781                	sext.w	a5,a5
ffffffffc02033b6:	04e79163          	bne	a5,a4,ffffffffc02033f8 <_fifo_check_swap+0x1b4>
}
ffffffffc02033ba:	60e6                	ld	ra,88(sp)
ffffffffc02033bc:	6446                	ld	s0,80(sp)
ffffffffc02033be:	64a6                	ld	s1,72(sp)
ffffffffc02033c0:	6906                	ld	s2,64(sp)
ffffffffc02033c2:	79e2                	ld	s3,56(sp)
ffffffffc02033c4:	7a42                	ld	s4,48(sp)
ffffffffc02033c6:	7aa2                	ld	s5,40(sp)
ffffffffc02033c8:	7b02                	ld	s6,32(sp)
ffffffffc02033ca:	6be2                	ld	s7,24(sp)
ffffffffc02033cc:	6c42                	ld	s8,16(sp)
ffffffffc02033ce:	6ca2                	ld	s9,8(sp)
ffffffffc02033d0:	6d02                	ld	s10,0(sp)
ffffffffc02033d2:	4501                	li	a0,0
ffffffffc02033d4:	6125                	addi	sp,sp,96
ffffffffc02033d6:	8082                	ret
    assert(pgfault_num==4);
ffffffffc02033d8:	00003697          	auipc	a3,0x3
ffffffffc02033dc:	04068693          	addi	a3,a3,64 # ffffffffc0206418 <commands+0x1268>
ffffffffc02033e0:	00002617          	auipc	a2,0x2
ffffffffc02033e4:	64060613          	addi	a2,a2,1600 # ffffffffc0205a20 <commands+0x870>
ffffffffc02033e8:	06100593          	li	a1,97
ffffffffc02033ec:	00003517          	auipc	a0,0x3
ffffffffc02033f0:	28450513          	addi	a0,a0,644 # ffffffffc0206670 <commands+0x14c0>
ffffffffc02033f4:	dd5fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(pgfault_num==11);
ffffffffc02033f8:	00003697          	auipc	a3,0x3
ffffffffc02033fc:	3b868693          	addi	a3,a3,952 # ffffffffc02067b0 <commands+0x1600>
ffffffffc0203400:	00002617          	auipc	a2,0x2
ffffffffc0203404:	62060613          	addi	a2,a2,1568 # ffffffffc0205a20 <commands+0x870>
ffffffffc0203408:	08300593          	li	a1,131
ffffffffc020340c:	00003517          	auipc	a0,0x3
ffffffffc0203410:	26450513          	addi	a0,a0,612 # ffffffffc0206670 <commands+0x14c0>
ffffffffc0203414:	db5fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc0203418:	00003697          	auipc	a3,0x3
ffffffffc020341c:	37068693          	addi	a3,a3,880 # ffffffffc0206788 <commands+0x15d8>
ffffffffc0203420:	00002617          	auipc	a2,0x2
ffffffffc0203424:	60060613          	addi	a2,a2,1536 # ffffffffc0205a20 <commands+0x870>
ffffffffc0203428:	08100593          	li	a1,129
ffffffffc020342c:	00003517          	auipc	a0,0x3
ffffffffc0203430:	24450513          	addi	a0,a0,580 # ffffffffc0206670 <commands+0x14c0>
ffffffffc0203434:	d95fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(pgfault_num==10);
ffffffffc0203438:	00003697          	auipc	a3,0x3
ffffffffc020343c:	34068693          	addi	a3,a3,832 # ffffffffc0206778 <commands+0x15c8>
ffffffffc0203440:	00002617          	auipc	a2,0x2
ffffffffc0203444:	5e060613          	addi	a2,a2,1504 # ffffffffc0205a20 <commands+0x870>
ffffffffc0203448:	07f00593          	li	a1,127
ffffffffc020344c:	00003517          	auipc	a0,0x3
ffffffffc0203450:	22450513          	addi	a0,a0,548 # ffffffffc0206670 <commands+0x14c0>
ffffffffc0203454:	d75fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(pgfault_num==9);
ffffffffc0203458:	00003697          	auipc	a3,0x3
ffffffffc020345c:	31068693          	addi	a3,a3,784 # ffffffffc0206768 <commands+0x15b8>
ffffffffc0203460:	00002617          	auipc	a2,0x2
ffffffffc0203464:	5c060613          	addi	a2,a2,1472 # ffffffffc0205a20 <commands+0x870>
ffffffffc0203468:	07c00593          	li	a1,124
ffffffffc020346c:	00003517          	auipc	a0,0x3
ffffffffc0203470:	20450513          	addi	a0,a0,516 # ffffffffc0206670 <commands+0x14c0>
ffffffffc0203474:	d55fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(pgfault_num==8);
ffffffffc0203478:	00003697          	auipc	a3,0x3
ffffffffc020347c:	2e068693          	addi	a3,a3,736 # ffffffffc0206758 <commands+0x15a8>
ffffffffc0203480:	00002617          	auipc	a2,0x2
ffffffffc0203484:	5a060613          	addi	a2,a2,1440 # ffffffffc0205a20 <commands+0x870>
ffffffffc0203488:	07900593          	li	a1,121
ffffffffc020348c:	00003517          	auipc	a0,0x3
ffffffffc0203490:	1e450513          	addi	a0,a0,484 # ffffffffc0206670 <commands+0x14c0>
ffffffffc0203494:	d35fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(pgfault_num==7);
ffffffffc0203498:	00003697          	auipc	a3,0x3
ffffffffc020349c:	2b068693          	addi	a3,a3,688 # ffffffffc0206748 <commands+0x1598>
ffffffffc02034a0:	00002617          	auipc	a2,0x2
ffffffffc02034a4:	58060613          	addi	a2,a2,1408 # ffffffffc0205a20 <commands+0x870>
ffffffffc02034a8:	07600593          	li	a1,118
ffffffffc02034ac:	00003517          	auipc	a0,0x3
ffffffffc02034b0:	1c450513          	addi	a0,a0,452 # ffffffffc0206670 <commands+0x14c0>
ffffffffc02034b4:	d15fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(pgfault_num==6);
ffffffffc02034b8:	00003697          	auipc	a3,0x3
ffffffffc02034bc:	28068693          	addi	a3,a3,640 # ffffffffc0206738 <commands+0x1588>
ffffffffc02034c0:	00002617          	auipc	a2,0x2
ffffffffc02034c4:	56060613          	addi	a2,a2,1376 # ffffffffc0205a20 <commands+0x870>
ffffffffc02034c8:	07300593          	li	a1,115
ffffffffc02034cc:	00003517          	auipc	a0,0x3
ffffffffc02034d0:	1a450513          	addi	a0,a0,420 # ffffffffc0206670 <commands+0x14c0>
ffffffffc02034d4:	cf5fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(pgfault_num==5);
ffffffffc02034d8:	00003697          	auipc	a3,0x3
ffffffffc02034dc:	25068693          	addi	a3,a3,592 # ffffffffc0206728 <commands+0x1578>
ffffffffc02034e0:	00002617          	auipc	a2,0x2
ffffffffc02034e4:	54060613          	addi	a2,a2,1344 # ffffffffc0205a20 <commands+0x870>
ffffffffc02034e8:	07000593          	li	a1,112
ffffffffc02034ec:	00003517          	auipc	a0,0x3
ffffffffc02034f0:	18450513          	addi	a0,a0,388 # ffffffffc0206670 <commands+0x14c0>
ffffffffc02034f4:	cd5fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(pgfault_num==5);
ffffffffc02034f8:	00003697          	auipc	a3,0x3
ffffffffc02034fc:	23068693          	addi	a3,a3,560 # ffffffffc0206728 <commands+0x1578>
ffffffffc0203500:	00002617          	auipc	a2,0x2
ffffffffc0203504:	52060613          	addi	a2,a2,1312 # ffffffffc0205a20 <commands+0x870>
ffffffffc0203508:	06d00593          	li	a1,109
ffffffffc020350c:	00003517          	auipc	a0,0x3
ffffffffc0203510:	16450513          	addi	a0,a0,356 # ffffffffc0206670 <commands+0x14c0>
ffffffffc0203514:	cb5fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(pgfault_num==4);
ffffffffc0203518:	00003697          	auipc	a3,0x3
ffffffffc020351c:	f0068693          	addi	a3,a3,-256 # ffffffffc0206418 <commands+0x1268>
ffffffffc0203520:	00002617          	auipc	a2,0x2
ffffffffc0203524:	50060613          	addi	a2,a2,1280 # ffffffffc0205a20 <commands+0x870>
ffffffffc0203528:	06a00593          	li	a1,106
ffffffffc020352c:	00003517          	auipc	a0,0x3
ffffffffc0203530:	14450513          	addi	a0,a0,324 # ffffffffc0206670 <commands+0x14c0>
ffffffffc0203534:	c95fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(pgfault_num==4);
ffffffffc0203538:	00003697          	auipc	a3,0x3
ffffffffc020353c:	ee068693          	addi	a3,a3,-288 # ffffffffc0206418 <commands+0x1268>
ffffffffc0203540:	00002617          	auipc	a2,0x2
ffffffffc0203544:	4e060613          	addi	a2,a2,1248 # ffffffffc0205a20 <commands+0x870>
ffffffffc0203548:	06700593          	li	a1,103
ffffffffc020354c:	00003517          	auipc	a0,0x3
ffffffffc0203550:	12450513          	addi	a0,a0,292 # ffffffffc0206670 <commands+0x14c0>
ffffffffc0203554:	c75fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(pgfault_num==4);
ffffffffc0203558:	00003697          	auipc	a3,0x3
ffffffffc020355c:	ec068693          	addi	a3,a3,-320 # ffffffffc0206418 <commands+0x1268>
ffffffffc0203560:	00002617          	auipc	a2,0x2
ffffffffc0203564:	4c060613          	addi	a2,a2,1216 # ffffffffc0205a20 <commands+0x870>
ffffffffc0203568:	06400593          	li	a1,100
ffffffffc020356c:	00003517          	auipc	a0,0x3
ffffffffc0203570:	10450513          	addi	a0,a0,260 # ffffffffc0206670 <commands+0x14c0>
ffffffffc0203574:	c55fc0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc0203578 <_fifo_swap_out_victim>:
    list_entry_t *head=(list_entry_t*) mm->sm_priv;
ffffffffc0203578:	751c                	ld	a5,40(a0)
{
ffffffffc020357a:	1141                	addi	sp,sp,-16
ffffffffc020357c:	e406                	sd	ra,8(sp)
    assert(head != NULL);
ffffffffc020357e:	cf91                	beqz	a5,ffffffffc020359a <_fifo_swap_out_victim+0x22>
    assert(in_tick==0);
ffffffffc0203580:	ee0d                	bnez	a2,ffffffffc02035ba <_fifo_swap_out_victim+0x42>
    return listelm->next; // 返回下一个节点
ffffffffc0203582:	679c                	ld	a5,8(a5)
}
ffffffffc0203584:	60a2                	ld	ra,8(sp)
ffffffffc0203586:	4501                	li	a0,0
    __list_del(listelm->prev, listelm->next); // 调用__list_del函数
ffffffffc0203588:	6394                	ld	a3,0(a5)
ffffffffc020358a:	6798                	ld	a4,8(a5)
    *ptr_page = le2page(entry, pra_page_link); // 将entry转换为页面结构并赋值给ptr_page
ffffffffc020358c:	fd878793          	addi	a5,a5,-40
    prev->next = next; // 将前一个节点的下一个指针指向后一个节点
ffffffffc0203590:	e698                	sd	a4,8(a3)
    next->prev = prev; // 将后一个节点的前一个指针指向前一个节点
ffffffffc0203592:	e314                	sd	a3,0(a4)
ffffffffc0203594:	e19c                	sd	a5,0(a1)
}
ffffffffc0203596:	0141                	addi	sp,sp,16
ffffffffc0203598:	8082                	ret
    assert(head != NULL);
ffffffffc020359a:	00003697          	auipc	a3,0x3
ffffffffc020359e:	22668693          	addi	a3,a3,550 # ffffffffc02067c0 <commands+0x1610>
ffffffffc02035a2:	00002617          	auipc	a2,0x2
ffffffffc02035a6:	47e60613          	addi	a2,a2,1150 # ffffffffc0205a20 <commands+0x870>
ffffffffc02035aa:	04d00593          	li	a1,77
ffffffffc02035ae:	00003517          	auipc	a0,0x3
ffffffffc02035b2:	0c250513          	addi	a0,a0,194 # ffffffffc0206670 <commands+0x14c0>
ffffffffc02035b6:	c13fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(in_tick==0);
ffffffffc02035ba:	00003697          	auipc	a3,0x3
ffffffffc02035be:	21668693          	addi	a3,a3,534 # ffffffffc02067d0 <commands+0x1620>
ffffffffc02035c2:	00002617          	auipc	a2,0x2
ffffffffc02035c6:	45e60613          	addi	a2,a2,1118 # ffffffffc0205a20 <commands+0x870>
ffffffffc02035ca:	04e00593          	li	a1,78
ffffffffc02035ce:	00003517          	auipc	a0,0x3
ffffffffc02035d2:	0a250513          	addi	a0,a0,162 # ffffffffc0206670 <commands+0x14c0>
ffffffffc02035d6:	bf3fc0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc02035da <_fifo_map_swappable>:
    list_entry_t *head=(list_entry_t*) mm->sm_priv;
ffffffffc02035da:	751c                	ld	a5,40(a0)
    assert(entry != NULL && head != NULL);
ffffffffc02035dc:	cb91                	beqz	a5,ffffffffc02035f0 <_fifo_map_swappable+0x16>
    __list_add(elm, listelm->prev, listelm); // 调用__list_add函数
ffffffffc02035de:	6394                	ld	a3,0(a5)
ffffffffc02035e0:	02860713          	addi	a4,a2,40
    prev->next = next->prev = elm; // 将前一个节点的下一个指针和后一个节点的前一个指针指向新节点
ffffffffc02035e4:	e398                	sd	a4,0(a5)
ffffffffc02035e6:	e698                	sd	a4,8(a3)
}
ffffffffc02035e8:	4501                	li	a0,0
    elm->next = next; // 将新节点的下一个指针指向后一个节点
ffffffffc02035ea:	fa1c                	sd	a5,48(a2)
    elm->prev = prev; // 将新节点的前一个指针指向前一个节点
ffffffffc02035ec:	f614                	sd	a3,40(a2)
ffffffffc02035ee:	8082                	ret
{
ffffffffc02035f0:	1141                	addi	sp,sp,-16
    assert(entry != NULL && head != NULL);
ffffffffc02035f2:	00003697          	auipc	a3,0x3
ffffffffc02035f6:	1ee68693          	addi	a3,a3,494 # ffffffffc02067e0 <commands+0x1630>
ffffffffc02035fa:	00002617          	auipc	a2,0x2
ffffffffc02035fe:	42660613          	addi	a2,a2,1062 # ffffffffc0205a20 <commands+0x870>
ffffffffc0203602:	03a00593          	li	a1,58
ffffffffc0203606:	00003517          	auipc	a0,0x3
ffffffffc020360a:	06a50513          	addi	a0,a0,106 # ffffffffc0206670 <commands+0x14c0>
{
ffffffffc020360e:	e406                	sd	ra,8(sp)
    assert(entry != NULL && head != NULL);
ffffffffc0203610:	bb9fc0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc0203614 <default_init>:
    elm->prev = elm->next = elm; // 将节点的前后指针都指向自己
ffffffffc0203614:	0000f797          	auipc	a5,0xf
ffffffffc0203618:	eec78793          	addi	a5,a5,-276 # ffffffffc0212500 <free_area>
ffffffffc020361c:	e79c                	sd	a5,8(a5)
ffffffffc020361e:	e39c                	sd	a5,0(a5)

/* 初始化空闲列表和空闲页数 */
static void
default_init(void) {
     list_init(&free_list); // 初始化空闲列表
     nr_free = 0; // 初始化空闲页数
ffffffffc0203620:	0007a823          	sw	zero,16(a5)
}
ffffffffc0203624:	8082                	ret

ffffffffc0203626 <default_nr_free_pages>:

/* 返回空闲页面数 */
static size_t
default_nr_free_pages(void) {
     return nr_free;
}
ffffffffc0203626:	0000f517          	auipc	a0,0xf
ffffffffc020362a:	eea56503          	lwu	a0,-278(a0) # ffffffffc0212510 <free_area+0x10>
ffffffffc020362e:	8082                	ret

ffffffffc0203630 <default_check>:
}

// LAB2: 以下代码用于检查首次适应分配算法（你的练习 1）
// 注意：你不应该更改 basic_check 和 default_check 函数！
static void
default_check(void) {
ffffffffc0203630:	715d                	addi	sp,sp,-80
ffffffffc0203632:	e0a2                	sd	s0,64(sp)
    return listelm->next; // 返回下一个节点
ffffffffc0203634:	0000f417          	auipc	s0,0xf
ffffffffc0203638:	ecc40413          	addi	s0,s0,-308 # ffffffffc0212500 <free_area>
ffffffffc020363c:	641c                	ld	a5,8(s0)
ffffffffc020363e:	e486                	sd	ra,72(sp)
ffffffffc0203640:	fc26                	sd	s1,56(sp)
ffffffffc0203642:	f84a                	sd	s2,48(sp)
ffffffffc0203644:	f44e                	sd	s3,40(sp)
ffffffffc0203646:	f052                	sd	s4,32(sp)
ffffffffc0203648:	ec56                	sd	s5,24(sp)
ffffffffc020364a:	e85a                	sd	s6,16(sp)
ffffffffc020364c:	e45e                	sd	s7,8(sp)
ffffffffc020364e:	e062                	sd	s8,0(sp)
     int count = 0, total = 0;
     list_entry_t *le = &free_list;
     while ((le = list_next(le)) != &free_list) {
ffffffffc0203650:	2a878d63          	beq	a5,s0,ffffffffc020390a <default_check+0x2da>
     int count = 0, total = 0;
ffffffffc0203654:	4481                	li	s1,0
ffffffffc0203656:	4901                	li	s2,0
ffffffffc0203658:	ff07b703          	ld	a4,-16(a5)
          struct Page *p = le2page(le, page_link);
          assert(PageProperty(p));
ffffffffc020365c:	8b09                	andi	a4,a4,2
ffffffffc020365e:	2a070a63          	beqz	a4,ffffffffc0203912 <default_check+0x2e2>
          count ++, total += p->property;
ffffffffc0203662:	ff87a703          	lw	a4,-8(a5)
ffffffffc0203666:	679c                	ld	a5,8(a5)
ffffffffc0203668:	2905                	addiw	s2,s2,1
ffffffffc020366a:	9cb9                	addw	s1,s1,a4
     while ((le = list_next(le)) != &free_list) {
ffffffffc020366c:	fe8796e3          	bne	a5,s0,ffffffffc0203658 <default_check+0x28>
     }
     assert(total == nr_free_pages());
ffffffffc0203670:	89a6                	mv	s3,s1
ffffffffc0203672:	e0afd0ef          	jal	ra,ffffffffc0200c7c <nr_free_pages>
ffffffffc0203676:	6f351e63          	bne	a0,s3,ffffffffc0203d72 <default_check+0x742>
     assert((p0 = alloc_page()) != NULL);
ffffffffc020367a:	4505                	li	a0,1
ffffffffc020367c:	d2efd0ef          	jal	ra,ffffffffc0200baa <alloc_pages>
ffffffffc0203680:	8aaa                	mv	s5,a0
ffffffffc0203682:	42050863          	beqz	a0,ffffffffc0203ab2 <default_check+0x482>
     assert((p1 = alloc_page()) != NULL);
ffffffffc0203686:	4505                	li	a0,1
ffffffffc0203688:	d22fd0ef          	jal	ra,ffffffffc0200baa <alloc_pages>
ffffffffc020368c:	89aa                	mv	s3,a0
ffffffffc020368e:	70050263          	beqz	a0,ffffffffc0203d92 <default_check+0x762>
     assert((p2 = alloc_page()) != NULL);
ffffffffc0203692:	4505                	li	a0,1
ffffffffc0203694:	d16fd0ef          	jal	ra,ffffffffc0200baa <alloc_pages>
ffffffffc0203698:	8a2a                	mv	s4,a0
ffffffffc020369a:	48050c63          	beqz	a0,ffffffffc0203b32 <default_check+0x502>
     assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc020369e:	293a8a63          	beq	s5,s3,ffffffffc0203932 <default_check+0x302>
ffffffffc02036a2:	28aa8863          	beq	s5,a0,ffffffffc0203932 <default_check+0x302>
ffffffffc02036a6:	28a98663          	beq	s3,a0,ffffffffc0203932 <default_check+0x302>
     assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02036aa:	000aa783          	lw	a5,0(s5)
ffffffffc02036ae:	2a079263          	bnez	a5,ffffffffc0203952 <default_check+0x322>
ffffffffc02036b2:	0009a783          	lw	a5,0(s3)
ffffffffc02036b6:	28079e63          	bnez	a5,ffffffffc0203952 <default_check+0x322>
ffffffffc02036ba:	411c                	lw	a5,0(a0)
ffffffffc02036bc:	28079b63          	bnez	a5,ffffffffc0203952 <default_check+0x322>
    return page - pages + nbase;
ffffffffc02036c0:	00013797          	auipc	a5,0x13
ffffffffc02036c4:	ea87b783          	ld	a5,-344(a5) # ffffffffc0216568 <pages>
ffffffffc02036c8:	40fa8733          	sub	a4,s5,a5
ffffffffc02036cc:	00004617          	auipc	a2,0x4
ffffffffc02036d0:	93c63603          	ld	a2,-1732(a2) # ffffffffc0207008 <nbase>
ffffffffc02036d4:	8719                	srai	a4,a4,0x6
ffffffffc02036d6:	9732                	add	a4,a4,a2
     assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02036d8:	00013697          	auipc	a3,0x13
ffffffffc02036dc:	e886b683          	ld	a3,-376(a3) # ffffffffc0216560 <npage>
ffffffffc02036e0:	06b2                	slli	a3,a3,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc02036e2:	0732                	slli	a4,a4,0xc
ffffffffc02036e4:	28d77763          	bgeu	a4,a3,ffffffffc0203972 <default_check+0x342>
    return page - pages + nbase;
ffffffffc02036e8:	40f98733          	sub	a4,s3,a5
ffffffffc02036ec:	8719                	srai	a4,a4,0x6
ffffffffc02036ee:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02036f0:	0732                	slli	a4,a4,0xc
     assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02036f2:	4cd77063          	bgeu	a4,a3,ffffffffc0203bb2 <default_check+0x582>
    return page - pages + nbase;
ffffffffc02036f6:	40f507b3          	sub	a5,a0,a5
ffffffffc02036fa:	8799                	srai	a5,a5,0x6
ffffffffc02036fc:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02036fe:	07b2                	slli	a5,a5,0xc
     assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0203700:	30d7f963          	bgeu	a5,a3,ffffffffc0203a12 <default_check+0x3e2>
     assert(alloc_page() == NULL);
ffffffffc0203704:	4505                	li	a0,1
     list_entry_t free_list_store = free_list;
ffffffffc0203706:	00043c03          	ld	s8,0(s0)
ffffffffc020370a:	00843b83          	ld	s7,8(s0)
     unsigned int nr_free_store = nr_free;
ffffffffc020370e:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm; // 将节点的前后指针都指向自己
ffffffffc0203712:	e400                	sd	s0,8(s0)
ffffffffc0203714:	e000                	sd	s0,0(s0)
     nr_free = 0;
ffffffffc0203716:	0000f797          	auipc	a5,0xf
ffffffffc020371a:	de07ad23          	sw	zero,-518(a5) # ffffffffc0212510 <free_area+0x10>
     assert(alloc_page() == NULL);
ffffffffc020371e:	c8cfd0ef          	jal	ra,ffffffffc0200baa <alloc_pages>
ffffffffc0203722:	2c051863          	bnez	a0,ffffffffc02039f2 <default_check+0x3c2>
     free_page(p0);
ffffffffc0203726:	4585                	li	a1,1
ffffffffc0203728:	8556                	mv	a0,s5
ffffffffc020372a:	d12fd0ef          	jal	ra,ffffffffc0200c3c <free_pages>
     free_page(p1);
ffffffffc020372e:	4585                	li	a1,1
ffffffffc0203730:	854e                	mv	a0,s3
ffffffffc0203732:	d0afd0ef          	jal	ra,ffffffffc0200c3c <free_pages>
     free_page(p2);
ffffffffc0203736:	4585                	li	a1,1
ffffffffc0203738:	8552                	mv	a0,s4
ffffffffc020373a:	d02fd0ef          	jal	ra,ffffffffc0200c3c <free_pages>
     assert(nr_free == 3);
ffffffffc020373e:	4818                	lw	a4,16(s0)
ffffffffc0203740:	478d                	li	a5,3
ffffffffc0203742:	28f71863          	bne	a4,a5,ffffffffc02039d2 <default_check+0x3a2>
     assert((p0 = alloc_page()) != NULL);
ffffffffc0203746:	4505                	li	a0,1
ffffffffc0203748:	c62fd0ef          	jal	ra,ffffffffc0200baa <alloc_pages>
ffffffffc020374c:	89aa                	mv	s3,a0
ffffffffc020374e:	26050263          	beqz	a0,ffffffffc02039b2 <default_check+0x382>
     assert((p1 = alloc_page()) != NULL);
ffffffffc0203752:	4505                	li	a0,1
ffffffffc0203754:	c56fd0ef          	jal	ra,ffffffffc0200baa <alloc_pages>
ffffffffc0203758:	8aaa                	mv	s5,a0
ffffffffc020375a:	3a050c63          	beqz	a0,ffffffffc0203b12 <default_check+0x4e2>
     assert((p2 = alloc_page()) != NULL);
ffffffffc020375e:	4505                	li	a0,1
ffffffffc0203760:	c4afd0ef          	jal	ra,ffffffffc0200baa <alloc_pages>
ffffffffc0203764:	8a2a                	mv	s4,a0
ffffffffc0203766:	38050663          	beqz	a0,ffffffffc0203af2 <default_check+0x4c2>
     assert(alloc_page() == NULL);
ffffffffc020376a:	4505                	li	a0,1
ffffffffc020376c:	c3efd0ef          	jal	ra,ffffffffc0200baa <alloc_pages>
ffffffffc0203770:	36051163          	bnez	a0,ffffffffc0203ad2 <default_check+0x4a2>
     free_page(p0);
ffffffffc0203774:	4585                	li	a1,1
ffffffffc0203776:	854e                	mv	a0,s3
ffffffffc0203778:	cc4fd0ef          	jal	ra,ffffffffc0200c3c <free_pages>
     assert(!list_empty(&free_list));
ffffffffc020377c:	641c                	ld	a5,8(s0)
ffffffffc020377e:	20878a63          	beq	a5,s0,ffffffffc0203992 <default_check+0x362>
     assert((p = alloc_page()) == p0);
ffffffffc0203782:	4505                	li	a0,1
ffffffffc0203784:	c26fd0ef          	jal	ra,ffffffffc0200baa <alloc_pages>
ffffffffc0203788:	30a99563          	bne	s3,a0,ffffffffc0203a92 <default_check+0x462>
     assert(alloc_page() == NULL);
ffffffffc020378c:	4505                	li	a0,1
ffffffffc020378e:	c1cfd0ef          	jal	ra,ffffffffc0200baa <alloc_pages>
ffffffffc0203792:	2e051063          	bnez	a0,ffffffffc0203a72 <default_check+0x442>
     assert(nr_free == 0);
ffffffffc0203796:	481c                	lw	a5,16(s0)
ffffffffc0203798:	2a079d63          	bnez	a5,ffffffffc0203a52 <default_check+0x422>
     free_page(p);
ffffffffc020379c:	854e                	mv	a0,s3
ffffffffc020379e:	4585                	li	a1,1
     free_list = free_list_store;
ffffffffc02037a0:	01843023          	sd	s8,0(s0)
ffffffffc02037a4:	01743423          	sd	s7,8(s0)
     nr_free = nr_free_store;
ffffffffc02037a8:	01642823          	sw	s6,16(s0)
     free_page(p);
ffffffffc02037ac:	c90fd0ef          	jal	ra,ffffffffc0200c3c <free_pages>
     free_page(p1);
ffffffffc02037b0:	4585                	li	a1,1
ffffffffc02037b2:	8556                	mv	a0,s5
ffffffffc02037b4:	c88fd0ef          	jal	ra,ffffffffc0200c3c <free_pages>
     free_page(p2);
ffffffffc02037b8:	4585                	li	a1,1
ffffffffc02037ba:	8552                	mv	a0,s4
ffffffffc02037bc:	c80fd0ef          	jal	ra,ffffffffc0200c3c <free_pages>

     basic_check();

     struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc02037c0:	4515                	li	a0,5
ffffffffc02037c2:	be8fd0ef          	jal	ra,ffffffffc0200baa <alloc_pages>
ffffffffc02037c6:	89aa                	mv	s3,a0
     assert(p0 != NULL);
ffffffffc02037c8:	26050563          	beqz	a0,ffffffffc0203a32 <default_check+0x402>
ffffffffc02037cc:	651c                	ld	a5,8(a0)
ffffffffc02037ce:	8385                	srli	a5,a5,0x1
     assert(!PageProperty(p0));
ffffffffc02037d0:	8b85                	andi	a5,a5,1
ffffffffc02037d2:	54079063          	bnez	a5,ffffffffc0203d12 <default_check+0x6e2>

     list_entry_t free_list_store = free_list;
     list_init(&free_list);
     assert(list_empty(&free_list));
     assert(alloc_page() == NULL);
ffffffffc02037d6:	4505                	li	a0,1
     list_entry_t free_list_store = free_list;
ffffffffc02037d8:	00043b03          	ld	s6,0(s0)
ffffffffc02037dc:	00843a83          	ld	s5,8(s0)
ffffffffc02037e0:	e000                	sd	s0,0(s0)
ffffffffc02037e2:	e400                	sd	s0,8(s0)
     assert(alloc_page() == NULL);
ffffffffc02037e4:	bc6fd0ef          	jal	ra,ffffffffc0200baa <alloc_pages>
ffffffffc02037e8:	50051563          	bnez	a0,ffffffffc0203cf2 <default_check+0x6c2>

     unsigned int nr_free_store = nr_free;
     nr_free = 0;

     free_pages(p0 + 2, 3);
ffffffffc02037ec:	08098a13          	addi	s4,s3,128
ffffffffc02037f0:	8552                	mv	a0,s4
ffffffffc02037f2:	458d                	li	a1,3
     unsigned int nr_free_store = nr_free;
ffffffffc02037f4:	01042b83          	lw	s7,16(s0)
     nr_free = 0;
ffffffffc02037f8:	0000f797          	auipc	a5,0xf
ffffffffc02037fc:	d007ac23          	sw	zero,-744(a5) # ffffffffc0212510 <free_area+0x10>
     free_pages(p0 + 2, 3);
ffffffffc0203800:	c3cfd0ef          	jal	ra,ffffffffc0200c3c <free_pages>
     assert(alloc_pages(4) == NULL);
ffffffffc0203804:	4511                	li	a0,4
ffffffffc0203806:	ba4fd0ef          	jal	ra,ffffffffc0200baa <alloc_pages>
ffffffffc020380a:	4c051463          	bnez	a0,ffffffffc0203cd2 <default_check+0x6a2>
ffffffffc020380e:	0889b783          	ld	a5,136(s3)
ffffffffc0203812:	8385                	srli	a5,a5,0x1
     assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0203814:	8b85                	andi	a5,a5,1
ffffffffc0203816:	48078e63          	beqz	a5,ffffffffc0203cb2 <default_check+0x682>
ffffffffc020381a:	0909a703          	lw	a4,144(s3)
ffffffffc020381e:	478d                	li	a5,3
ffffffffc0203820:	48f71963          	bne	a4,a5,ffffffffc0203cb2 <default_check+0x682>
     assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0203824:	450d                	li	a0,3
ffffffffc0203826:	b84fd0ef          	jal	ra,ffffffffc0200baa <alloc_pages>
ffffffffc020382a:	8c2a                	mv	s8,a0
ffffffffc020382c:	46050363          	beqz	a0,ffffffffc0203c92 <default_check+0x662>
     assert(alloc_page() == NULL);
ffffffffc0203830:	4505                	li	a0,1
ffffffffc0203832:	b78fd0ef          	jal	ra,ffffffffc0200baa <alloc_pages>
ffffffffc0203836:	42051e63          	bnez	a0,ffffffffc0203c72 <default_check+0x642>
     assert(p0 + 2 == p1);
ffffffffc020383a:	418a1c63          	bne	s4,s8,ffffffffc0203c52 <default_check+0x622>

     p2 = p0 + 1;
     free_page(p0);
ffffffffc020383e:	4585                	li	a1,1
ffffffffc0203840:	854e                	mv	a0,s3
ffffffffc0203842:	bfafd0ef          	jal	ra,ffffffffc0200c3c <free_pages>
     free_pages(p1, 3);
ffffffffc0203846:	458d                	li	a1,3
ffffffffc0203848:	8552                	mv	a0,s4
ffffffffc020384a:	bf2fd0ef          	jal	ra,ffffffffc0200c3c <free_pages>
ffffffffc020384e:	0089b783          	ld	a5,8(s3)
     p2 = p0 + 1;
ffffffffc0203852:	04098c13          	addi	s8,s3,64
ffffffffc0203856:	8385                	srli	a5,a5,0x1
     assert(PageProperty(p0) && p0->property == 1);
ffffffffc0203858:	8b85                	andi	a5,a5,1
ffffffffc020385a:	3c078c63          	beqz	a5,ffffffffc0203c32 <default_check+0x602>
ffffffffc020385e:	0109a703          	lw	a4,16(s3)
ffffffffc0203862:	4785                	li	a5,1
ffffffffc0203864:	3cf71763          	bne	a4,a5,ffffffffc0203c32 <default_check+0x602>
ffffffffc0203868:	008a3783          	ld	a5,8(s4)
ffffffffc020386c:	8385                	srli	a5,a5,0x1
     assert(PageProperty(p1) && p1->property == 3);
ffffffffc020386e:	8b85                	andi	a5,a5,1
ffffffffc0203870:	3a078163          	beqz	a5,ffffffffc0203c12 <default_check+0x5e2>
ffffffffc0203874:	010a2703          	lw	a4,16(s4)
ffffffffc0203878:	478d                	li	a5,3
ffffffffc020387a:	38f71c63          	bne	a4,a5,ffffffffc0203c12 <default_check+0x5e2>

     assert((p0 = alloc_page()) == p2 - 1);
ffffffffc020387e:	4505                	li	a0,1
ffffffffc0203880:	b2afd0ef          	jal	ra,ffffffffc0200baa <alloc_pages>
ffffffffc0203884:	36a99763          	bne	s3,a0,ffffffffc0203bf2 <default_check+0x5c2>
     free_page(p0);
ffffffffc0203888:	4585                	li	a1,1
ffffffffc020388a:	bb2fd0ef          	jal	ra,ffffffffc0200c3c <free_pages>
     assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc020388e:	4509                	li	a0,2
ffffffffc0203890:	b1afd0ef          	jal	ra,ffffffffc0200baa <alloc_pages>
ffffffffc0203894:	32aa1f63          	bne	s4,a0,ffffffffc0203bd2 <default_check+0x5a2>

     free_pages(p0, 2);
ffffffffc0203898:	4589                	li	a1,2
ffffffffc020389a:	ba2fd0ef          	jal	ra,ffffffffc0200c3c <free_pages>
     free_page(p2);
ffffffffc020389e:	4585                	li	a1,1
ffffffffc02038a0:	8562                	mv	a0,s8
ffffffffc02038a2:	b9afd0ef          	jal	ra,ffffffffc0200c3c <free_pages>

     assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02038a6:	4515                	li	a0,5
ffffffffc02038a8:	b02fd0ef          	jal	ra,ffffffffc0200baa <alloc_pages>
ffffffffc02038ac:	89aa                	mv	s3,a0
ffffffffc02038ae:	48050263          	beqz	a0,ffffffffc0203d32 <default_check+0x702>
     assert(alloc_page() == NULL);
ffffffffc02038b2:	4505                	li	a0,1
ffffffffc02038b4:	af6fd0ef          	jal	ra,ffffffffc0200baa <alloc_pages>
ffffffffc02038b8:	2c051d63          	bnez	a0,ffffffffc0203b92 <default_check+0x562>

     assert(nr_free == 0);
ffffffffc02038bc:	481c                	lw	a5,16(s0)
ffffffffc02038be:	2a079a63          	bnez	a5,ffffffffc0203b72 <default_check+0x542>
     nr_free = nr_free_store;

     free_list = free_list_store;
     free_pages(p0, 5);
ffffffffc02038c2:	4595                	li	a1,5
ffffffffc02038c4:	854e                	mv	a0,s3
     nr_free = nr_free_store;
ffffffffc02038c6:	01742823          	sw	s7,16(s0)
     free_list = free_list_store;
ffffffffc02038ca:	01643023          	sd	s6,0(s0)
ffffffffc02038ce:	01543423          	sd	s5,8(s0)
     free_pages(p0, 5);
ffffffffc02038d2:	b6afd0ef          	jal	ra,ffffffffc0200c3c <free_pages>
    return listelm->next; // 返回下一个节点
ffffffffc02038d6:	641c                	ld	a5,8(s0)

     le = &free_list;
     while ((le = list_next(le)) != &free_list) {
ffffffffc02038d8:	00878963          	beq	a5,s0,ffffffffc02038ea <default_check+0x2ba>
          struct Page *p = le2page(le, page_link);
          count --, total -= p->property;
ffffffffc02038dc:	ff87a703          	lw	a4,-8(a5)
ffffffffc02038e0:	679c                	ld	a5,8(a5)
ffffffffc02038e2:	397d                	addiw	s2,s2,-1
ffffffffc02038e4:	9c99                	subw	s1,s1,a4
     while ((le = list_next(le)) != &free_list) {
ffffffffc02038e6:	fe879be3          	bne	a5,s0,ffffffffc02038dc <default_check+0x2ac>
     }
     assert(count == 0);
ffffffffc02038ea:	26091463          	bnez	s2,ffffffffc0203b52 <default_check+0x522>
     assert(total == 0);
ffffffffc02038ee:	46049263          	bnez	s1,ffffffffc0203d52 <default_check+0x722>
}
ffffffffc02038f2:	60a6                	ld	ra,72(sp)
ffffffffc02038f4:	6406                	ld	s0,64(sp)
ffffffffc02038f6:	74e2                	ld	s1,56(sp)
ffffffffc02038f8:	7942                	ld	s2,48(sp)
ffffffffc02038fa:	79a2                	ld	s3,40(sp)
ffffffffc02038fc:	7a02                	ld	s4,32(sp)
ffffffffc02038fe:	6ae2                	ld	s5,24(sp)
ffffffffc0203900:	6b42                	ld	s6,16(sp)
ffffffffc0203902:	6ba2                	ld	s7,8(sp)
ffffffffc0203904:	6c02                	ld	s8,0(sp)
ffffffffc0203906:	6161                	addi	sp,sp,80
ffffffffc0203908:	8082                	ret
     while ((le = list_next(le)) != &free_list) {
ffffffffc020390a:	4981                	li	s3,0
     int count = 0, total = 0;
ffffffffc020390c:	4481                	li	s1,0
ffffffffc020390e:	4901                	li	s2,0
ffffffffc0203910:	b38d                	j	ffffffffc0203672 <default_check+0x42>
          assert(PageProperty(p));
ffffffffc0203912:	00003697          	auipc	a3,0x3
ffffffffc0203916:	96668693          	addi	a3,a3,-1690 # ffffffffc0206278 <commands+0x10c8>
ffffffffc020391a:	00002617          	auipc	a2,0x2
ffffffffc020391e:	10660613          	addi	a2,a2,262 # ffffffffc0205a20 <commands+0x870>
ffffffffc0203922:	0f300593          	li	a1,243
ffffffffc0203926:	00003517          	auipc	a0,0x3
ffffffffc020392a:	ef250513          	addi	a0,a0,-270 # ffffffffc0206818 <commands+0x1668>
ffffffffc020392e:	89bfc0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0203932:	00003697          	auipc	a3,0x3
ffffffffc0203936:	f5e68693          	addi	a3,a3,-162 # ffffffffc0206890 <commands+0x16e0>
ffffffffc020393a:	00002617          	auipc	a2,0x2
ffffffffc020393e:	0e660613          	addi	a2,a2,230 # ffffffffc0205a20 <commands+0x870>
ffffffffc0203942:	0c000593          	li	a1,192
ffffffffc0203946:	00003517          	auipc	a0,0x3
ffffffffc020394a:	ed250513          	addi	a0,a0,-302 # ffffffffc0206818 <commands+0x1668>
ffffffffc020394e:	87bfc0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0203952:	00003697          	auipc	a3,0x3
ffffffffc0203956:	f6668693          	addi	a3,a3,-154 # ffffffffc02068b8 <commands+0x1708>
ffffffffc020395a:	00002617          	auipc	a2,0x2
ffffffffc020395e:	0c660613          	addi	a2,a2,198 # ffffffffc0205a20 <commands+0x870>
ffffffffc0203962:	0c100593          	li	a1,193
ffffffffc0203966:	00003517          	auipc	a0,0x3
ffffffffc020396a:	eb250513          	addi	a0,a0,-334 # ffffffffc0206818 <commands+0x1668>
ffffffffc020396e:	85bfc0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0203972:	00003697          	auipc	a3,0x3
ffffffffc0203976:	f8668693          	addi	a3,a3,-122 # ffffffffc02068f8 <commands+0x1748>
ffffffffc020397a:	00002617          	auipc	a2,0x2
ffffffffc020397e:	0a660613          	addi	a2,a2,166 # ffffffffc0205a20 <commands+0x870>
ffffffffc0203982:	0c300593          	li	a1,195
ffffffffc0203986:	00003517          	auipc	a0,0x3
ffffffffc020398a:	e9250513          	addi	a0,a0,-366 # ffffffffc0206818 <commands+0x1668>
ffffffffc020398e:	83bfc0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(!list_empty(&free_list));
ffffffffc0203992:	00003697          	auipc	a3,0x3
ffffffffc0203996:	fee68693          	addi	a3,a3,-18 # ffffffffc0206980 <commands+0x17d0>
ffffffffc020399a:	00002617          	auipc	a2,0x2
ffffffffc020399e:	08660613          	addi	a2,a2,134 # ffffffffc0205a20 <commands+0x870>
ffffffffc02039a2:	0dc00593          	li	a1,220
ffffffffc02039a6:	00003517          	auipc	a0,0x3
ffffffffc02039aa:	e7250513          	addi	a0,a0,-398 # ffffffffc0206818 <commands+0x1668>
ffffffffc02039ae:	81bfc0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert((p0 = alloc_page()) != NULL);
ffffffffc02039b2:	00003697          	auipc	a3,0x3
ffffffffc02039b6:	e7e68693          	addi	a3,a3,-386 # ffffffffc0206830 <commands+0x1680>
ffffffffc02039ba:	00002617          	auipc	a2,0x2
ffffffffc02039be:	06660613          	addi	a2,a2,102 # ffffffffc0205a20 <commands+0x870>
ffffffffc02039c2:	0d500593          	li	a1,213
ffffffffc02039c6:	00003517          	auipc	a0,0x3
ffffffffc02039ca:	e5250513          	addi	a0,a0,-430 # ffffffffc0206818 <commands+0x1668>
ffffffffc02039ce:	ffafc0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(nr_free == 3);
ffffffffc02039d2:	00003697          	auipc	a3,0x3
ffffffffc02039d6:	f9e68693          	addi	a3,a3,-98 # ffffffffc0206970 <commands+0x17c0>
ffffffffc02039da:	00002617          	auipc	a2,0x2
ffffffffc02039de:	04660613          	addi	a2,a2,70 # ffffffffc0205a20 <commands+0x870>
ffffffffc02039e2:	0d300593          	li	a1,211
ffffffffc02039e6:	00003517          	auipc	a0,0x3
ffffffffc02039ea:	e3250513          	addi	a0,a0,-462 # ffffffffc0206818 <commands+0x1668>
ffffffffc02039ee:	fdafc0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(alloc_page() == NULL);
ffffffffc02039f2:	00003697          	auipc	a3,0x3
ffffffffc02039f6:	f6668693          	addi	a3,a3,-154 # ffffffffc0206958 <commands+0x17a8>
ffffffffc02039fa:	00002617          	auipc	a2,0x2
ffffffffc02039fe:	02660613          	addi	a2,a2,38 # ffffffffc0205a20 <commands+0x870>
ffffffffc0203a02:	0ce00593          	li	a1,206
ffffffffc0203a06:	00003517          	auipc	a0,0x3
ffffffffc0203a0a:	e1250513          	addi	a0,a0,-494 # ffffffffc0206818 <commands+0x1668>
ffffffffc0203a0e:	fbafc0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0203a12:	00003697          	auipc	a3,0x3
ffffffffc0203a16:	f2668693          	addi	a3,a3,-218 # ffffffffc0206938 <commands+0x1788>
ffffffffc0203a1a:	00002617          	auipc	a2,0x2
ffffffffc0203a1e:	00660613          	addi	a2,a2,6 # ffffffffc0205a20 <commands+0x870>
ffffffffc0203a22:	0c500593          	li	a1,197
ffffffffc0203a26:	00003517          	auipc	a0,0x3
ffffffffc0203a2a:	df250513          	addi	a0,a0,-526 # ffffffffc0206818 <commands+0x1668>
ffffffffc0203a2e:	f9afc0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(p0 != NULL);
ffffffffc0203a32:	00003697          	auipc	a3,0x3
ffffffffc0203a36:	f8668693          	addi	a3,a3,-122 # ffffffffc02069b8 <commands+0x1808>
ffffffffc0203a3a:	00002617          	auipc	a2,0x2
ffffffffc0203a3e:	fe660613          	addi	a2,a2,-26 # ffffffffc0205a20 <commands+0x870>
ffffffffc0203a42:	0fb00593          	li	a1,251
ffffffffc0203a46:	00003517          	auipc	a0,0x3
ffffffffc0203a4a:	dd250513          	addi	a0,a0,-558 # ffffffffc0206818 <commands+0x1668>
ffffffffc0203a4e:	f7afc0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(nr_free == 0);
ffffffffc0203a52:	00003697          	auipc	a3,0x3
ffffffffc0203a56:	9d668693          	addi	a3,a3,-1578 # ffffffffc0206428 <commands+0x1278>
ffffffffc0203a5a:	00002617          	auipc	a2,0x2
ffffffffc0203a5e:	fc660613          	addi	a2,a2,-58 # ffffffffc0205a20 <commands+0x870>
ffffffffc0203a62:	0e200593          	li	a1,226
ffffffffc0203a66:	00003517          	auipc	a0,0x3
ffffffffc0203a6a:	db250513          	addi	a0,a0,-590 # ffffffffc0206818 <commands+0x1668>
ffffffffc0203a6e:	f5afc0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(alloc_page() == NULL);
ffffffffc0203a72:	00003697          	auipc	a3,0x3
ffffffffc0203a76:	ee668693          	addi	a3,a3,-282 # ffffffffc0206958 <commands+0x17a8>
ffffffffc0203a7a:	00002617          	auipc	a2,0x2
ffffffffc0203a7e:	fa660613          	addi	a2,a2,-90 # ffffffffc0205a20 <commands+0x870>
ffffffffc0203a82:	0e000593          	li	a1,224
ffffffffc0203a86:	00003517          	auipc	a0,0x3
ffffffffc0203a8a:	d9250513          	addi	a0,a0,-622 # ffffffffc0206818 <commands+0x1668>
ffffffffc0203a8e:	f3afc0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert((p = alloc_page()) == p0);
ffffffffc0203a92:	00003697          	auipc	a3,0x3
ffffffffc0203a96:	f0668693          	addi	a3,a3,-250 # ffffffffc0206998 <commands+0x17e8>
ffffffffc0203a9a:	00002617          	auipc	a2,0x2
ffffffffc0203a9e:	f8660613          	addi	a2,a2,-122 # ffffffffc0205a20 <commands+0x870>
ffffffffc0203aa2:	0df00593          	li	a1,223
ffffffffc0203aa6:	00003517          	auipc	a0,0x3
ffffffffc0203aaa:	d7250513          	addi	a0,a0,-654 # ffffffffc0206818 <commands+0x1668>
ffffffffc0203aae:	f1afc0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert((p0 = alloc_page()) != NULL);
ffffffffc0203ab2:	00003697          	auipc	a3,0x3
ffffffffc0203ab6:	d7e68693          	addi	a3,a3,-642 # ffffffffc0206830 <commands+0x1680>
ffffffffc0203aba:	00002617          	auipc	a2,0x2
ffffffffc0203abe:	f6660613          	addi	a2,a2,-154 # ffffffffc0205a20 <commands+0x870>
ffffffffc0203ac2:	0bc00593          	li	a1,188
ffffffffc0203ac6:	00003517          	auipc	a0,0x3
ffffffffc0203aca:	d5250513          	addi	a0,a0,-686 # ffffffffc0206818 <commands+0x1668>
ffffffffc0203ace:	efafc0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(alloc_page() == NULL);
ffffffffc0203ad2:	00003697          	auipc	a3,0x3
ffffffffc0203ad6:	e8668693          	addi	a3,a3,-378 # ffffffffc0206958 <commands+0x17a8>
ffffffffc0203ada:	00002617          	auipc	a2,0x2
ffffffffc0203ade:	f4660613          	addi	a2,a2,-186 # ffffffffc0205a20 <commands+0x870>
ffffffffc0203ae2:	0d900593          	li	a1,217
ffffffffc0203ae6:	00003517          	auipc	a0,0x3
ffffffffc0203aea:	d3250513          	addi	a0,a0,-718 # ffffffffc0206818 <commands+0x1668>
ffffffffc0203aee:	edafc0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert((p2 = alloc_page()) != NULL);
ffffffffc0203af2:	00003697          	auipc	a3,0x3
ffffffffc0203af6:	d7e68693          	addi	a3,a3,-642 # ffffffffc0206870 <commands+0x16c0>
ffffffffc0203afa:	00002617          	auipc	a2,0x2
ffffffffc0203afe:	f2660613          	addi	a2,a2,-218 # ffffffffc0205a20 <commands+0x870>
ffffffffc0203b02:	0d700593          	li	a1,215
ffffffffc0203b06:	00003517          	auipc	a0,0x3
ffffffffc0203b0a:	d1250513          	addi	a0,a0,-750 # ffffffffc0206818 <commands+0x1668>
ffffffffc0203b0e:	ebafc0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert((p1 = alloc_page()) != NULL);
ffffffffc0203b12:	00003697          	auipc	a3,0x3
ffffffffc0203b16:	d3e68693          	addi	a3,a3,-706 # ffffffffc0206850 <commands+0x16a0>
ffffffffc0203b1a:	00002617          	auipc	a2,0x2
ffffffffc0203b1e:	f0660613          	addi	a2,a2,-250 # ffffffffc0205a20 <commands+0x870>
ffffffffc0203b22:	0d600593          	li	a1,214
ffffffffc0203b26:	00003517          	auipc	a0,0x3
ffffffffc0203b2a:	cf250513          	addi	a0,a0,-782 # ffffffffc0206818 <commands+0x1668>
ffffffffc0203b2e:	e9afc0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert((p2 = alloc_page()) != NULL);
ffffffffc0203b32:	00003697          	auipc	a3,0x3
ffffffffc0203b36:	d3e68693          	addi	a3,a3,-706 # ffffffffc0206870 <commands+0x16c0>
ffffffffc0203b3a:	00002617          	auipc	a2,0x2
ffffffffc0203b3e:	ee660613          	addi	a2,a2,-282 # ffffffffc0205a20 <commands+0x870>
ffffffffc0203b42:	0be00593          	li	a1,190
ffffffffc0203b46:	00003517          	auipc	a0,0x3
ffffffffc0203b4a:	cd250513          	addi	a0,a0,-814 # ffffffffc0206818 <commands+0x1668>
ffffffffc0203b4e:	e7afc0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(count == 0);
ffffffffc0203b52:	00003697          	auipc	a3,0x3
ffffffffc0203b56:	fb668693          	addi	a3,a3,-74 # ffffffffc0206b08 <commands+0x1958>
ffffffffc0203b5a:	00002617          	auipc	a2,0x2
ffffffffc0203b5e:	ec660613          	addi	a2,a2,-314 # ffffffffc0205a20 <commands+0x870>
ffffffffc0203b62:	12800593          	li	a1,296
ffffffffc0203b66:	00003517          	auipc	a0,0x3
ffffffffc0203b6a:	cb250513          	addi	a0,a0,-846 # ffffffffc0206818 <commands+0x1668>
ffffffffc0203b6e:	e5afc0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(nr_free == 0);
ffffffffc0203b72:	00003697          	auipc	a3,0x3
ffffffffc0203b76:	8b668693          	addi	a3,a3,-1866 # ffffffffc0206428 <commands+0x1278>
ffffffffc0203b7a:	00002617          	auipc	a2,0x2
ffffffffc0203b7e:	ea660613          	addi	a2,a2,-346 # ffffffffc0205a20 <commands+0x870>
ffffffffc0203b82:	11d00593          	li	a1,285
ffffffffc0203b86:	00003517          	auipc	a0,0x3
ffffffffc0203b8a:	c9250513          	addi	a0,a0,-878 # ffffffffc0206818 <commands+0x1668>
ffffffffc0203b8e:	e3afc0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(alloc_page() == NULL);
ffffffffc0203b92:	00003697          	auipc	a3,0x3
ffffffffc0203b96:	dc668693          	addi	a3,a3,-570 # ffffffffc0206958 <commands+0x17a8>
ffffffffc0203b9a:	00002617          	auipc	a2,0x2
ffffffffc0203b9e:	e8660613          	addi	a2,a2,-378 # ffffffffc0205a20 <commands+0x870>
ffffffffc0203ba2:	11b00593          	li	a1,283
ffffffffc0203ba6:	00003517          	auipc	a0,0x3
ffffffffc0203baa:	c7250513          	addi	a0,a0,-910 # ffffffffc0206818 <commands+0x1668>
ffffffffc0203bae:	e1afc0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0203bb2:	00003697          	auipc	a3,0x3
ffffffffc0203bb6:	d6668693          	addi	a3,a3,-666 # ffffffffc0206918 <commands+0x1768>
ffffffffc0203bba:	00002617          	auipc	a2,0x2
ffffffffc0203bbe:	e6660613          	addi	a2,a2,-410 # ffffffffc0205a20 <commands+0x870>
ffffffffc0203bc2:	0c400593          	li	a1,196
ffffffffc0203bc6:	00003517          	auipc	a0,0x3
ffffffffc0203bca:	c5250513          	addi	a0,a0,-942 # ffffffffc0206818 <commands+0x1668>
ffffffffc0203bce:	dfafc0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0203bd2:	00003697          	auipc	a3,0x3
ffffffffc0203bd6:	ef668693          	addi	a3,a3,-266 # ffffffffc0206ac8 <commands+0x1918>
ffffffffc0203bda:	00002617          	auipc	a2,0x2
ffffffffc0203bde:	e4660613          	addi	a2,a2,-442 # ffffffffc0205a20 <commands+0x870>
ffffffffc0203be2:	11500593          	li	a1,277
ffffffffc0203be6:	00003517          	auipc	a0,0x3
ffffffffc0203bea:	c3250513          	addi	a0,a0,-974 # ffffffffc0206818 <commands+0x1668>
ffffffffc0203bee:	ddafc0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0203bf2:	00003697          	auipc	a3,0x3
ffffffffc0203bf6:	eb668693          	addi	a3,a3,-330 # ffffffffc0206aa8 <commands+0x18f8>
ffffffffc0203bfa:	00002617          	auipc	a2,0x2
ffffffffc0203bfe:	e2660613          	addi	a2,a2,-474 # ffffffffc0205a20 <commands+0x870>
ffffffffc0203c02:	11300593          	li	a1,275
ffffffffc0203c06:	00003517          	auipc	a0,0x3
ffffffffc0203c0a:	c1250513          	addi	a0,a0,-1006 # ffffffffc0206818 <commands+0x1668>
ffffffffc0203c0e:	dbafc0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(PageProperty(p1) && p1->property == 3);
ffffffffc0203c12:	00003697          	auipc	a3,0x3
ffffffffc0203c16:	e6e68693          	addi	a3,a3,-402 # ffffffffc0206a80 <commands+0x18d0>
ffffffffc0203c1a:	00002617          	auipc	a2,0x2
ffffffffc0203c1e:	e0660613          	addi	a2,a2,-506 # ffffffffc0205a20 <commands+0x870>
ffffffffc0203c22:	11100593          	li	a1,273
ffffffffc0203c26:	00003517          	auipc	a0,0x3
ffffffffc0203c2a:	bf250513          	addi	a0,a0,-1038 # ffffffffc0206818 <commands+0x1668>
ffffffffc0203c2e:	d9afc0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(PageProperty(p0) && p0->property == 1);
ffffffffc0203c32:	00003697          	auipc	a3,0x3
ffffffffc0203c36:	e2668693          	addi	a3,a3,-474 # ffffffffc0206a58 <commands+0x18a8>
ffffffffc0203c3a:	00002617          	auipc	a2,0x2
ffffffffc0203c3e:	de660613          	addi	a2,a2,-538 # ffffffffc0205a20 <commands+0x870>
ffffffffc0203c42:	11000593          	li	a1,272
ffffffffc0203c46:	00003517          	auipc	a0,0x3
ffffffffc0203c4a:	bd250513          	addi	a0,a0,-1070 # ffffffffc0206818 <commands+0x1668>
ffffffffc0203c4e:	d7afc0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(p0 + 2 == p1);
ffffffffc0203c52:	00003697          	auipc	a3,0x3
ffffffffc0203c56:	df668693          	addi	a3,a3,-522 # ffffffffc0206a48 <commands+0x1898>
ffffffffc0203c5a:	00002617          	auipc	a2,0x2
ffffffffc0203c5e:	dc660613          	addi	a2,a2,-570 # ffffffffc0205a20 <commands+0x870>
ffffffffc0203c62:	10b00593          	li	a1,267
ffffffffc0203c66:	00003517          	auipc	a0,0x3
ffffffffc0203c6a:	bb250513          	addi	a0,a0,-1102 # ffffffffc0206818 <commands+0x1668>
ffffffffc0203c6e:	d5afc0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(alloc_page() == NULL);
ffffffffc0203c72:	00003697          	auipc	a3,0x3
ffffffffc0203c76:	ce668693          	addi	a3,a3,-794 # ffffffffc0206958 <commands+0x17a8>
ffffffffc0203c7a:	00002617          	auipc	a2,0x2
ffffffffc0203c7e:	da660613          	addi	a2,a2,-602 # ffffffffc0205a20 <commands+0x870>
ffffffffc0203c82:	10a00593          	li	a1,266
ffffffffc0203c86:	00003517          	auipc	a0,0x3
ffffffffc0203c8a:	b9250513          	addi	a0,a0,-1134 # ffffffffc0206818 <commands+0x1668>
ffffffffc0203c8e:	d3afc0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0203c92:	00003697          	auipc	a3,0x3
ffffffffc0203c96:	d9668693          	addi	a3,a3,-618 # ffffffffc0206a28 <commands+0x1878>
ffffffffc0203c9a:	00002617          	auipc	a2,0x2
ffffffffc0203c9e:	d8660613          	addi	a2,a2,-634 # ffffffffc0205a20 <commands+0x870>
ffffffffc0203ca2:	10900593          	li	a1,265
ffffffffc0203ca6:	00003517          	auipc	a0,0x3
ffffffffc0203caa:	b7250513          	addi	a0,a0,-1166 # ffffffffc0206818 <commands+0x1668>
ffffffffc0203cae:	d1afc0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0203cb2:	00003697          	auipc	a3,0x3
ffffffffc0203cb6:	d4668693          	addi	a3,a3,-698 # ffffffffc02069f8 <commands+0x1848>
ffffffffc0203cba:	00002617          	auipc	a2,0x2
ffffffffc0203cbe:	d6660613          	addi	a2,a2,-666 # ffffffffc0205a20 <commands+0x870>
ffffffffc0203cc2:	10800593          	li	a1,264
ffffffffc0203cc6:	00003517          	auipc	a0,0x3
ffffffffc0203cca:	b5250513          	addi	a0,a0,-1198 # ffffffffc0206818 <commands+0x1668>
ffffffffc0203cce:	cfafc0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(alloc_pages(4) == NULL);
ffffffffc0203cd2:	00003697          	auipc	a3,0x3
ffffffffc0203cd6:	d0e68693          	addi	a3,a3,-754 # ffffffffc02069e0 <commands+0x1830>
ffffffffc0203cda:	00002617          	auipc	a2,0x2
ffffffffc0203cde:	d4660613          	addi	a2,a2,-698 # ffffffffc0205a20 <commands+0x870>
ffffffffc0203ce2:	10700593          	li	a1,263
ffffffffc0203ce6:	00003517          	auipc	a0,0x3
ffffffffc0203cea:	b3250513          	addi	a0,a0,-1230 # ffffffffc0206818 <commands+0x1668>
ffffffffc0203cee:	cdafc0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(alloc_page() == NULL);
ffffffffc0203cf2:	00003697          	auipc	a3,0x3
ffffffffc0203cf6:	c6668693          	addi	a3,a3,-922 # ffffffffc0206958 <commands+0x17a8>
ffffffffc0203cfa:	00002617          	auipc	a2,0x2
ffffffffc0203cfe:	d2660613          	addi	a2,a2,-730 # ffffffffc0205a20 <commands+0x870>
ffffffffc0203d02:	10100593          	li	a1,257
ffffffffc0203d06:	00003517          	auipc	a0,0x3
ffffffffc0203d0a:	b1250513          	addi	a0,a0,-1262 # ffffffffc0206818 <commands+0x1668>
ffffffffc0203d0e:	cbafc0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(!PageProperty(p0));
ffffffffc0203d12:	00003697          	auipc	a3,0x3
ffffffffc0203d16:	cb668693          	addi	a3,a3,-842 # ffffffffc02069c8 <commands+0x1818>
ffffffffc0203d1a:	00002617          	auipc	a2,0x2
ffffffffc0203d1e:	d0660613          	addi	a2,a2,-762 # ffffffffc0205a20 <commands+0x870>
ffffffffc0203d22:	0fc00593          	li	a1,252
ffffffffc0203d26:	00003517          	auipc	a0,0x3
ffffffffc0203d2a:	af250513          	addi	a0,a0,-1294 # ffffffffc0206818 <commands+0x1668>
ffffffffc0203d2e:	c9afc0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0203d32:	00003697          	auipc	a3,0x3
ffffffffc0203d36:	db668693          	addi	a3,a3,-586 # ffffffffc0206ae8 <commands+0x1938>
ffffffffc0203d3a:	00002617          	auipc	a2,0x2
ffffffffc0203d3e:	ce660613          	addi	a2,a2,-794 # ffffffffc0205a20 <commands+0x870>
ffffffffc0203d42:	11a00593          	li	a1,282
ffffffffc0203d46:	00003517          	auipc	a0,0x3
ffffffffc0203d4a:	ad250513          	addi	a0,a0,-1326 # ffffffffc0206818 <commands+0x1668>
ffffffffc0203d4e:	c7afc0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(total == 0);
ffffffffc0203d52:	00003697          	auipc	a3,0x3
ffffffffc0203d56:	dc668693          	addi	a3,a3,-570 # ffffffffc0206b18 <commands+0x1968>
ffffffffc0203d5a:	00002617          	auipc	a2,0x2
ffffffffc0203d5e:	cc660613          	addi	a2,a2,-826 # ffffffffc0205a20 <commands+0x870>
ffffffffc0203d62:	12900593          	li	a1,297
ffffffffc0203d66:	00003517          	auipc	a0,0x3
ffffffffc0203d6a:	ab250513          	addi	a0,a0,-1358 # ffffffffc0206818 <commands+0x1668>
ffffffffc0203d6e:	c5afc0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(total == nr_free_pages());
ffffffffc0203d72:	00002697          	auipc	a3,0x2
ffffffffc0203d76:	51668693          	addi	a3,a3,1302 # ffffffffc0206288 <commands+0x10d8>
ffffffffc0203d7a:	00002617          	auipc	a2,0x2
ffffffffc0203d7e:	ca660613          	addi	a2,a2,-858 # ffffffffc0205a20 <commands+0x870>
ffffffffc0203d82:	0f600593          	li	a1,246
ffffffffc0203d86:	00003517          	auipc	a0,0x3
ffffffffc0203d8a:	a9250513          	addi	a0,a0,-1390 # ffffffffc0206818 <commands+0x1668>
ffffffffc0203d8e:	c3afc0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert((p1 = alloc_page()) != NULL);
ffffffffc0203d92:	00003697          	auipc	a3,0x3
ffffffffc0203d96:	abe68693          	addi	a3,a3,-1346 # ffffffffc0206850 <commands+0x16a0>
ffffffffc0203d9a:	00002617          	auipc	a2,0x2
ffffffffc0203d9e:	c8660613          	addi	a2,a2,-890 # ffffffffc0205a20 <commands+0x870>
ffffffffc0203da2:	0bd00593          	li	a1,189
ffffffffc0203da6:	00003517          	auipc	a0,0x3
ffffffffc0203daa:	a7250513          	addi	a0,a0,-1422 # ffffffffc0206818 <commands+0x1668>
ffffffffc0203dae:	c1afc0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc0203db2 <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc0203db2:	1141                	addi	sp,sp,-16
ffffffffc0203db4:	e406                	sd	ra,8(sp)
     assert(n > 0);
ffffffffc0203db6:	14058463          	beqz	a1,ffffffffc0203efe <default_free_pages+0x14c>
     for (; p != base + n; p ++) {
ffffffffc0203dba:	00659693          	slli	a3,a1,0x6
ffffffffc0203dbe:	96aa                	add	a3,a3,a0
ffffffffc0203dc0:	87aa                	mv	a5,a0
ffffffffc0203dc2:	02d50263          	beq	a0,a3,ffffffffc0203de6 <default_free_pages+0x34>
ffffffffc0203dc6:	6798                	ld	a4,8(a5)
          assert(!PageReserved(p) && !PageProperty(p)); // 确保页面未保留且无属性
ffffffffc0203dc8:	8b05                	andi	a4,a4,1
ffffffffc0203dca:	10071a63          	bnez	a4,ffffffffc0203ede <default_free_pages+0x12c>
ffffffffc0203dce:	6798                	ld	a4,8(a5)
ffffffffc0203dd0:	8b09                	andi	a4,a4,2
ffffffffc0203dd2:	10071663          	bnez	a4,ffffffffc0203ede <default_free_pages+0x12c>
          p->flags = 0; // 清除标志
ffffffffc0203dd6:	0007b423          	sd	zero,8(a5)
    page->ref = val;
ffffffffc0203dda:	0007a023          	sw	zero,0(a5)
     for (; p != base + n; p ++) {
ffffffffc0203dde:	04078793          	addi	a5,a5,64
ffffffffc0203de2:	fed792e3          	bne	a5,a3,ffffffffc0203dc6 <default_free_pages+0x14>
     base->property = n; // 设置块的大小
ffffffffc0203de6:	2581                	sext.w	a1,a1
ffffffffc0203de8:	c90c                	sw	a1,16(a0)
     SetPageProperty(base); // 设置页面属性
ffffffffc0203dea:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0203dee:	4789                	li	a5,2
ffffffffc0203df0:	40f8b02f          	amoor.d	zero,a5,(a7)
     nr_free += n; // 增加空闲页数
ffffffffc0203df4:	0000e697          	auipc	a3,0xe
ffffffffc0203df8:	70c68693          	addi	a3,a3,1804 # ffffffffc0212500 <free_area>
ffffffffc0203dfc:	4a98                	lw	a4,16(a3)
    return list->next == list; // 判断链表的下一个节点是否是自己
ffffffffc0203dfe:	669c                	ld	a5,8(a3)
          list_add(&free_list, &(base->page_link)); // 如果空闲列表为空，添加到空闲列表
ffffffffc0203e00:	01850613          	addi	a2,a0,24
     nr_free += n; // 增加空闲页数
ffffffffc0203e04:	9db9                	addw	a1,a1,a4
ffffffffc0203e06:	ca8c                	sw	a1,16(a3)
     if (list_empty(&free_list)) {
ffffffffc0203e08:	0ad78463          	beq	a5,a3,ffffffffc0203eb0 <default_free_pages+0xfe>
                struct Page* page = le2page(le, page_link);
ffffffffc0203e0c:	fe878713          	addi	a4,a5,-24
ffffffffc0203e10:	0006b803          	ld	a6,0(a3)
     if (list_empty(&free_list)) {
ffffffffc0203e14:	4581                	li	a1,0
                if (base < page) {
ffffffffc0203e16:	00e56a63          	bltu	a0,a4,ffffffffc0203e2a <default_free_pages+0x78>
    return listelm->next; // 返回下一个节点
ffffffffc0203e1a:	6798                	ld	a4,8(a5)
                } else if (list_next(le) == &free_list) {
ffffffffc0203e1c:	04d70c63          	beq	a4,a3,ffffffffc0203e74 <default_free_pages+0xc2>
     for (; p != base + n; p ++) {
ffffffffc0203e20:	87ba                	mv	a5,a4
                struct Page* page = le2page(le, page_link);
ffffffffc0203e22:	fe878713          	addi	a4,a5,-24
                if (base < page) {
ffffffffc0203e26:	fee57ae3          	bgeu	a0,a4,ffffffffc0203e1a <default_free_pages+0x68>
ffffffffc0203e2a:	c199                	beqz	a1,ffffffffc0203e30 <default_free_pages+0x7e>
ffffffffc0203e2c:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm); // 调用__list_add函数
ffffffffc0203e30:	6398                	ld	a4,0(a5)
    prev->next = next->prev = elm; // 将前一个节点的下一个指针和后一个节点的前一个指针指向新节点
ffffffffc0203e32:	e390                	sd	a2,0(a5)
ffffffffc0203e34:	e710                	sd	a2,8(a4)
    elm->next = next; // 将新节点的下一个指针指向后一个节点
ffffffffc0203e36:	f11c                	sd	a5,32(a0)
    elm->prev = prev; // 将新节点的前一个指针指向前一个节点
ffffffffc0203e38:	ed18                	sd	a4,24(a0)
     if (le != &free_list) {
ffffffffc0203e3a:	00d70d63          	beq	a4,a3,ffffffffc0203e54 <default_free_pages+0xa2>
          if (p + p->property == base) {
ffffffffc0203e3e:	ff872583          	lw	a1,-8(a4) # ff8 <kern_entry-0xffffffffc01ff008>
          p = le2page(le, page_link);
ffffffffc0203e42:	fe870613          	addi	a2,a4,-24
          if (p + p->property == base) {
ffffffffc0203e46:	02059813          	slli	a6,a1,0x20
ffffffffc0203e4a:	01a85793          	srli	a5,a6,0x1a
ffffffffc0203e4e:	97b2                	add	a5,a5,a2
ffffffffc0203e50:	02f50c63          	beq	a0,a5,ffffffffc0203e88 <default_free_pages+0xd6>
    return listelm->next; // 返回下一个节点
ffffffffc0203e54:	711c                	ld	a5,32(a0)
     if (le != &free_list) {
ffffffffc0203e56:	00d78c63          	beq	a5,a3,ffffffffc0203e6e <default_free_pages+0xbc>
          if (base + base->property == p) {
ffffffffc0203e5a:	4910                	lw	a2,16(a0)
          p = le2page(le, page_link);
ffffffffc0203e5c:	fe878693          	addi	a3,a5,-24
          if (base + base->property == p) {
ffffffffc0203e60:	02061593          	slli	a1,a2,0x20
ffffffffc0203e64:	01a5d713          	srli	a4,a1,0x1a
ffffffffc0203e68:	972a                	add	a4,a4,a0
ffffffffc0203e6a:	04e68a63          	beq	a3,a4,ffffffffc0203ebe <default_free_pages+0x10c>
}
ffffffffc0203e6e:	60a2                	ld	ra,8(sp)
ffffffffc0203e70:	0141                	addi	sp,sp,16
ffffffffc0203e72:	8082                	ret
    prev->next = next->prev = elm; // 将前一个节点的下一个指针和后一个节点的前一个指针指向新节点
ffffffffc0203e74:	e790                	sd	a2,8(a5)
    elm->next = next; // 将新节点的下一个指针指向后一个节点
ffffffffc0203e76:	f114                	sd	a3,32(a0)
    return listelm->next; // 返回下一个节点
ffffffffc0203e78:	6798                	ld	a4,8(a5)
    elm->prev = prev; // 将新节点的前一个指针指向前一个节点
ffffffffc0203e7a:	ed1c                	sd	a5,24(a0)
          while ((le = list_next(le)) != &free_list) {
ffffffffc0203e7c:	02d70763          	beq	a4,a3,ffffffffc0203eaa <default_free_pages+0xf8>
    prev->next = next->prev = elm; // 将前一个节点的下一个指针和后一个节点的前一个指针指向新节点
ffffffffc0203e80:	8832                	mv	a6,a2
ffffffffc0203e82:	4585                	li	a1,1
     for (; p != base + n; p ++) {
ffffffffc0203e84:	87ba                	mv	a5,a4
ffffffffc0203e86:	bf71                	j	ffffffffc0203e22 <default_free_pages+0x70>
                p->property += base->property; // 合并低地址块
ffffffffc0203e88:	491c                	lw	a5,16(a0)
ffffffffc0203e8a:	9dbd                	addw	a1,a1,a5
ffffffffc0203e8c:	feb72c23          	sw	a1,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0203e90:	57f5                	li	a5,-3
ffffffffc0203e92:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next); // 调用__list_del函数
ffffffffc0203e96:	01853803          	ld	a6,24(a0)
ffffffffc0203e9a:	710c                	ld	a1,32(a0)
                base = p;
ffffffffc0203e9c:	8532                	mv	a0,a2
    prev->next = next; // 将前一个节点的下一个指针指向后一个节点
ffffffffc0203e9e:	00b83423          	sd	a1,8(a6) # fffffffffff80008 <end+0x3fd69a3c>
    return listelm->next; // 返回下一个节点
ffffffffc0203ea2:	671c                	ld	a5,8(a4)
    next->prev = prev; // 将后一个节点的前一个指针指向前一个节点
ffffffffc0203ea4:	0105b023          	sd	a6,0(a1) # 1000 <kern_entry-0xffffffffc01ff000>
ffffffffc0203ea8:	b77d                	j	ffffffffc0203e56 <default_free_pages+0xa4>
ffffffffc0203eaa:	e290                	sd	a2,0(a3)
          while ((le = list_next(le)) != &free_list) {
ffffffffc0203eac:	873e                	mv	a4,a5
ffffffffc0203eae:	bf41                	j	ffffffffc0203e3e <default_free_pages+0x8c>
}
ffffffffc0203eb0:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm; // 将前一个节点的下一个指针和后一个节点的前一个指针指向新节点
ffffffffc0203eb2:	e390                	sd	a2,0(a5)
ffffffffc0203eb4:	e790                	sd	a2,8(a5)
    elm->next = next; // 将新节点的下一个指针指向后一个节点
ffffffffc0203eb6:	f11c                	sd	a5,32(a0)
    elm->prev = prev; // 将新节点的前一个指针指向前一个节点
ffffffffc0203eb8:	ed1c                	sd	a5,24(a0)
ffffffffc0203eba:	0141                	addi	sp,sp,16
ffffffffc0203ebc:	8082                	ret
                base->property += p->property; // 合并高地址块
ffffffffc0203ebe:	ff87a703          	lw	a4,-8(a5)
ffffffffc0203ec2:	ff078693          	addi	a3,a5,-16
ffffffffc0203ec6:	9e39                	addw	a2,a2,a4
ffffffffc0203ec8:	c910                	sw	a2,16(a0)
ffffffffc0203eca:	5775                	li	a4,-3
ffffffffc0203ecc:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next); // 调用__list_del函数
ffffffffc0203ed0:	6398                	ld	a4,0(a5)
ffffffffc0203ed2:	679c                	ld	a5,8(a5)
}
ffffffffc0203ed4:	60a2                	ld	ra,8(sp)
    prev->next = next; // 将前一个节点的下一个指针指向后一个节点
ffffffffc0203ed6:	e71c                	sd	a5,8(a4)
    next->prev = prev; // 将后一个节点的前一个指针指向前一个节点
ffffffffc0203ed8:	e398                	sd	a4,0(a5)
ffffffffc0203eda:	0141                	addi	sp,sp,16
ffffffffc0203edc:	8082                	ret
          assert(!PageReserved(p) && !PageProperty(p)); // 确保页面未保留且无属性
ffffffffc0203ede:	00003697          	auipc	a3,0x3
ffffffffc0203ee2:	c5268693          	addi	a3,a3,-942 # ffffffffc0206b30 <commands+0x1980>
ffffffffc0203ee6:	00002617          	auipc	a2,0x2
ffffffffc0203eea:	b3a60613          	addi	a2,a2,-1222 # ffffffffc0205a20 <commands+0x870>
ffffffffc0203eee:	08400593          	li	a1,132
ffffffffc0203ef2:	00003517          	auipc	a0,0x3
ffffffffc0203ef6:	92650513          	addi	a0,a0,-1754 # ffffffffc0206818 <commands+0x1668>
ffffffffc0203efa:	acefc0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(n > 0);
ffffffffc0203efe:	00003697          	auipc	a3,0x3
ffffffffc0203f02:	c2a68693          	addi	a3,a3,-982 # ffffffffc0206b28 <commands+0x1978>
ffffffffc0203f06:	00002617          	auipc	a2,0x2
ffffffffc0203f0a:	b1a60613          	addi	a2,a2,-1254 # ffffffffc0205a20 <commands+0x870>
ffffffffc0203f0e:	08100593          	li	a1,129
ffffffffc0203f12:	00003517          	auipc	a0,0x3
ffffffffc0203f16:	90650513          	addi	a0,a0,-1786 # ffffffffc0206818 <commands+0x1668>
ffffffffc0203f1a:	aaefc0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc0203f1e <default_alloc_pages>:
     assert(n > 0);
ffffffffc0203f1e:	c941                	beqz	a0,ffffffffc0203fae <default_alloc_pages+0x90>
     if (n > nr_free) {
ffffffffc0203f20:	0000e597          	auipc	a1,0xe
ffffffffc0203f24:	5e058593          	addi	a1,a1,1504 # ffffffffc0212500 <free_area>
ffffffffc0203f28:	0105a803          	lw	a6,16(a1)
ffffffffc0203f2c:	872a                	mv	a4,a0
ffffffffc0203f2e:	02081793          	slli	a5,a6,0x20
ffffffffc0203f32:	9381                	srli	a5,a5,0x20
ffffffffc0203f34:	00a7ee63          	bltu	a5,a0,ffffffffc0203f50 <default_alloc_pages+0x32>
     list_entry_t *le = &free_list;
ffffffffc0203f38:	87ae                	mv	a5,a1
ffffffffc0203f3a:	a801                	j	ffffffffc0203f4a <default_alloc_pages+0x2c>
          if (p->property >= n) {
ffffffffc0203f3c:	ff87a683          	lw	a3,-8(a5)
ffffffffc0203f40:	02069613          	slli	a2,a3,0x20
ffffffffc0203f44:	9201                	srli	a2,a2,0x20
ffffffffc0203f46:	00e67763          	bgeu	a2,a4,ffffffffc0203f54 <default_alloc_pages+0x36>
    return listelm->next; // 返回下一个节点
ffffffffc0203f4a:	679c                	ld	a5,8(a5)
     while ((le = list_next(le)) != &free_list) {
ffffffffc0203f4c:	feb798e3          	bne	a5,a1,ffffffffc0203f3c <default_alloc_pages+0x1e>
          return NULL; // 如果请求的页面数大于空闲页面数，返回NULL
ffffffffc0203f50:	4501                	li	a0,0
}
ffffffffc0203f52:	8082                	ret
    return listelm->prev; // 返回前一个节点
ffffffffc0203f54:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next); // 调用__list_del函数
ffffffffc0203f58:	0087b303          	ld	t1,8(a5)
          struct Page *p = le2page(le, page_link);
ffffffffc0203f5c:	fe878513          	addi	a0,a5,-24
                p->property = page->property - n; // 调整剩余块的大小
ffffffffc0203f60:	00070e1b          	sext.w	t3,a4
    prev->next = next; // 将前一个节点的下一个指针指向后一个节点
ffffffffc0203f64:	0068b423          	sd	t1,8(a7)
    next->prev = prev; // 将后一个节点的前一个指针指向前一个节点
ffffffffc0203f68:	01133023          	sd	a7,0(t1)
          if (page->property > n) {
ffffffffc0203f6c:	02c77863          	bgeu	a4,a2,ffffffffc0203f9c <default_alloc_pages+0x7e>
                struct Page *p = page + n;
ffffffffc0203f70:	071a                	slli	a4,a4,0x6
ffffffffc0203f72:	972a                	add	a4,a4,a0
                p->property = page->property - n; // 调整剩余块的大小
ffffffffc0203f74:	41c686bb          	subw	a3,a3,t3
ffffffffc0203f78:	cb14                	sw	a3,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0203f7a:	00870613          	addi	a2,a4,8
ffffffffc0203f7e:	4689                	li	a3,2
ffffffffc0203f80:	40d6302f          	amoor.d	zero,a3,(a2)
    __list_add(elm, listelm, listelm->next); // 调用__list_add函数
ffffffffc0203f84:	0088b683          	ld	a3,8(a7)
                list_add(prev, &(p->page_link)); // 添加剩余块到空闲列表
ffffffffc0203f88:	01870613          	addi	a2,a4,24
          nr_free -= n; // 减少空闲页数
ffffffffc0203f8c:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm; // 将前一个节点的下一个指针和后一个节点的前一个指针指向新节点
ffffffffc0203f90:	e290                	sd	a2,0(a3)
ffffffffc0203f92:	00c8b423          	sd	a2,8(a7)
    elm->next = next; // 将新节点的下一个指针指向后一个节点
ffffffffc0203f96:	f314                	sd	a3,32(a4)
    elm->prev = prev; // 将新节点的前一个指针指向前一个节点
ffffffffc0203f98:	01173c23          	sd	a7,24(a4)
ffffffffc0203f9c:	41c8083b          	subw	a6,a6,t3
ffffffffc0203fa0:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0203fa4:	5775                	li	a4,-3
ffffffffc0203fa6:	17c1                	addi	a5,a5,-16
ffffffffc0203fa8:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc0203fac:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc0203fae:	1141                	addi	sp,sp,-16
     assert(n > 0);
ffffffffc0203fb0:	00003697          	auipc	a3,0x3
ffffffffc0203fb4:	b7868693          	addi	a3,a3,-1160 # ffffffffc0206b28 <commands+0x1978>
ffffffffc0203fb8:	00002617          	auipc	a2,0x2
ffffffffc0203fbc:	a6860613          	addi	a2,a2,-1432 # ffffffffc0205a20 <commands+0x870>
ffffffffc0203fc0:	06200593          	li	a1,98
ffffffffc0203fc4:	00003517          	auipc	a0,0x3
ffffffffc0203fc8:	85450513          	addi	a0,a0,-1964 # ffffffffc0206818 <commands+0x1668>
default_alloc_pages(size_t n) {
ffffffffc0203fcc:	e406                	sd	ra,8(sp)
     assert(n > 0);
ffffffffc0203fce:	9fafc0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc0203fd2 <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc0203fd2:	1141                	addi	sp,sp,-16
ffffffffc0203fd4:	e406                	sd	ra,8(sp)
     assert(n > 0);
ffffffffc0203fd6:	c5f1                	beqz	a1,ffffffffc02040a2 <default_init_memmap+0xd0>
     for (; p != base + n; p ++) {
ffffffffc0203fd8:	00659693          	slli	a3,a1,0x6
ffffffffc0203fdc:	96aa                	add	a3,a3,a0
ffffffffc0203fde:	87aa                	mv	a5,a0
ffffffffc0203fe0:	00d50f63          	beq	a0,a3,ffffffffc0203ffe <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0203fe4:	6798                	ld	a4,8(a5)
          assert(PageReserved(p)); // 确保页面已保留
ffffffffc0203fe6:	8b05                	andi	a4,a4,1
ffffffffc0203fe8:	cf49                	beqz	a4,ffffffffc0204082 <default_init_memmap+0xb0>
          p->flags = p->property = 0; // 清除标志和属性
ffffffffc0203fea:	0007a823          	sw	zero,16(a5)
ffffffffc0203fee:	0007b423          	sd	zero,8(a5)
ffffffffc0203ff2:	0007a023          	sw	zero,0(a5)
     for (; p != base + n; p ++) {
ffffffffc0203ff6:	04078793          	addi	a5,a5,64
ffffffffc0203ffa:	fed795e3          	bne	a5,a3,ffffffffc0203fe4 <default_init_memmap+0x12>
     base->property = n; // 设置块的大小
ffffffffc0203ffe:	2581                	sext.w	a1,a1
ffffffffc0204000:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0204002:	4789                	li	a5,2
ffffffffc0204004:	00850713          	addi	a4,a0,8
ffffffffc0204008:	40f7302f          	amoor.d	zero,a5,(a4)
     nr_free += n; // 增加空闲页数
ffffffffc020400c:	0000e697          	auipc	a3,0xe
ffffffffc0204010:	4f468693          	addi	a3,a3,1268 # ffffffffc0212500 <free_area>
ffffffffc0204014:	4a98                	lw	a4,16(a3)
    return list->next == list; // 判断链表的下一个节点是否是自己
ffffffffc0204016:	669c                	ld	a5,8(a3)
          list_add(&free_list, &(base->page_link)); // 如果空闲列表为空，添加到空闲列表
ffffffffc0204018:	01850613          	addi	a2,a0,24
     nr_free += n; // 增加空闲页数
ffffffffc020401c:	9db9                	addw	a1,a1,a4
ffffffffc020401e:	ca8c                	sw	a1,16(a3)
     if (list_empty(&free_list)) {
ffffffffc0204020:	04d78a63          	beq	a5,a3,ffffffffc0204074 <default_init_memmap+0xa2>
                struct Page* page = le2page(le, page_link);
ffffffffc0204024:	fe878713          	addi	a4,a5,-24
ffffffffc0204028:	0006b803          	ld	a6,0(a3)
     if (list_empty(&free_list)) {
ffffffffc020402c:	4581                	li	a1,0
                if (base < page) {
ffffffffc020402e:	00e56a63          	bltu	a0,a4,ffffffffc0204042 <default_init_memmap+0x70>
    return listelm->next; // 返回下一个节点
ffffffffc0204032:	6798                	ld	a4,8(a5)
                } else if (list_next(le) == &free_list) {
ffffffffc0204034:	02d70263          	beq	a4,a3,ffffffffc0204058 <default_init_memmap+0x86>
     for (; p != base + n; p ++) {
ffffffffc0204038:	87ba                	mv	a5,a4
                struct Page* page = le2page(le, page_link);
ffffffffc020403a:	fe878713          	addi	a4,a5,-24
                if (base < page) {
ffffffffc020403e:	fee57ae3          	bgeu	a0,a4,ffffffffc0204032 <default_init_memmap+0x60>
ffffffffc0204042:	c199                	beqz	a1,ffffffffc0204048 <default_init_memmap+0x76>
ffffffffc0204044:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm); // 调用__list_add函数
ffffffffc0204048:	6398                	ld	a4,0(a5)
}
ffffffffc020404a:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm; // 将前一个节点的下一个指针和后一个节点的前一个指针指向新节点
ffffffffc020404c:	e390                	sd	a2,0(a5)
ffffffffc020404e:	e710                	sd	a2,8(a4)
    elm->next = next; // 将新节点的下一个指针指向后一个节点
ffffffffc0204050:	f11c                	sd	a5,32(a0)
    elm->prev = prev; // 将新节点的前一个指针指向前一个节点
ffffffffc0204052:	ed18                	sd	a4,24(a0)
ffffffffc0204054:	0141                	addi	sp,sp,16
ffffffffc0204056:	8082                	ret
    prev->next = next->prev = elm; // 将前一个节点的下一个指针和后一个节点的前一个指针指向新节点
ffffffffc0204058:	e790                	sd	a2,8(a5)
    elm->next = next; // 将新节点的下一个指针指向后一个节点
ffffffffc020405a:	f114                	sd	a3,32(a0)
    return listelm->next; // 返回下一个节点
ffffffffc020405c:	6798                	ld	a4,8(a5)
    elm->prev = prev; // 将新节点的前一个指针指向前一个节点
ffffffffc020405e:	ed1c                	sd	a5,24(a0)
          while ((le = list_next(le)) != &free_list) {
ffffffffc0204060:	00d70663          	beq	a4,a3,ffffffffc020406c <default_init_memmap+0x9a>
    prev->next = next->prev = elm; // 将前一个节点的下一个指针和后一个节点的前一个指针指向新节点
ffffffffc0204064:	8832                	mv	a6,a2
ffffffffc0204066:	4585                	li	a1,1
     for (; p != base + n; p ++) {
ffffffffc0204068:	87ba                	mv	a5,a4
ffffffffc020406a:	bfc1                	j	ffffffffc020403a <default_init_memmap+0x68>
}
ffffffffc020406c:	60a2                	ld	ra,8(sp)
ffffffffc020406e:	e290                	sd	a2,0(a3)
ffffffffc0204070:	0141                	addi	sp,sp,16
ffffffffc0204072:	8082                	ret
ffffffffc0204074:	60a2                	ld	ra,8(sp)
ffffffffc0204076:	e390                	sd	a2,0(a5)
ffffffffc0204078:	e790                	sd	a2,8(a5)
    elm->next = next; // 将新节点的下一个指针指向后一个节点
ffffffffc020407a:	f11c                	sd	a5,32(a0)
    elm->prev = prev; // 将新节点的前一个指针指向前一个节点
ffffffffc020407c:	ed1c                	sd	a5,24(a0)
ffffffffc020407e:	0141                	addi	sp,sp,16
ffffffffc0204080:	8082                	ret
          assert(PageReserved(p)); // 确保页面已保留
ffffffffc0204082:	00003697          	auipc	a3,0x3
ffffffffc0204086:	ad668693          	addi	a3,a3,-1322 # ffffffffc0206b58 <commands+0x19a8>
ffffffffc020408a:	00002617          	auipc	a2,0x2
ffffffffc020408e:	99660613          	addi	a2,a2,-1642 # ffffffffc0205a20 <commands+0x870>
ffffffffc0204092:	04800593          	li	a1,72
ffffffffc0204096:	00002517          	auipc	a0,0x2
ffffffffc020409a:	78250513          	addi	a0,a0,1922 # ffffffffc0206818 <commands+0x1668>
ffffffffc020409e:	92afc0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(n > 0);
ffffffffc02040a2:	00003697          	auipc	a3,0x3
ffffffffc02040a6:	a8668693          	addi	a3,a3,-1402 # ffffffffc0206b28 <commands+0x1978>
ffffffffc02040aa:	00002617          	auipc	a2,0x2
ffffffffc02040ae:	97660613          	addi	a2,a2,-1674 # ffffffffc0205a20 <commands+0x870>
ffffffffc02040b2:	04500593          	li	a1,69
ffffffffc02040b6:	00002517          	auipc	a0,0x2
ffffffffc02040ba:	76250513          	addi	a0,a0,1890 # ffffffffc0206818 <commands+0x1668>
ffffffffc02040be:	90afc0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc02040c2 <swapfs_init>:
#include <ide.h> // 包含IDE设备相关头文件
#include <pmm.h> // 包含物理内存管理相关头文件
#include <assert.h> // 包含断言相关头文件

void
swapfs_init(void) { // 初始化交换文件系统
ffffffffc02040c2:	1141                	addi	sp,sp,-16
    static_assert((PGSIZE % SECTSIZE) == 0); // 静态断言，确保页面大小是扇区大小的整数倍
    if (!ide_device_valid(SWAP_DEV_NO)) { // 检查交换设备是否有效
ffffffffc02040c4:	4505                	li	a0,1
swapfs_init(void) { // 初始化交换文件系统
ffffffffc02040c6:	e406                	sd	ra,8(sp)
    if (!ide_device_valid(SWAP_DEV_NO)) { // 检查交换设备是否有效
ffffffffc02040c8:	bdcfc0ef          	jal	ra,ffffffffc02004a4 <ide_device_valid>
ffffffffc02040cc:	cd01                	beqz	a0,ffffffffc02040e4 <swapfs_init+0x22>
        panic("swap fs isn't available.\n"); // 如果无效，则触发内核恐慌
    }
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE); // 计算最大交换偏移量
ffffffffc02040ce:	4505                	li	a0,1
ffffffffc02040d0:	bdafc0ef          	jal	ra,ffffffffc02004aa <ide_device_size>
}
ffffffffc02040d4:	60a2                	ld	ra,8(sp)
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE); // 计算最大交换偏移量
ffffffffc02040d6:	810d                	srli	a0,a0,0x3
ffffffffc02040d8:	00012797          	auipc	a5,0x12
ffffffffc02040dc:	4aa7bc23          	sd	a0,1208(a5) # ffffffffc0216590 <max_swap_offset>
}
ffffffffc02040e0:	0141                	addi	sp,sp,16
ffffffffc02040e2:	8082                	ret
        panic("swap fs isn't available.\n"); // 如果无效，则触发内核恐慌
ffffffffc02040e4:	00003617          	auipc	a2,0x3
ffffffffc02040e8:	ad460613          	addi	a2,a2,-1324 # ffffffffc0206bb8 <default_pmm_manager+0x38>
ffffffffc02040ec:	45b5                	li	a1,13
ffffffffc02040ee:	00003517          	auipc	a0,0x3
ffffffffc02040f2:	aea50513          	addi	a0,a0,-1302 # ffffffffc0206bd8 <default_pmm_manager+0x58>
ffffffffc02040f6:	8d2fc0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc02040fa <swapfs_read>:

int
swapfs_read(swap_entry_t entry, struct Page *page) { // 从交换文件系统读取页面
ffffffffc02040fa:	1141                	addi	sp,sp,-16
ffffffffc02040fc:	e406                	sd	ra,8(sp)
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT); // 调用IDE读取函数读取页面数据
ffffffffc02040fe:	00855793          	srli	a5,a0,0x8
ffffffffc0204102:	cbb1                	beqz	a5,ffffffffc0204156 <swapfs_read+0x5c>
ffffffffc0204104:	00012717          	auipc	a4,0x12
ffffffffc0204108:	48c73703          	ld	a4,1164(a4) # ffffffffc0216590 <max_swap_offset>
ffffffffc020410c:	04e7f563          	bgeu	a5,a4,ffffffffc0204156 <swapfs_read+0x5c>
    return page - pages + nbase;
ffffffffc0204110:	00012617          	auipc	a2,0x12
ffffffffc0204114:	45863603          	ld	a2,1112(a2) # ffffffffc0216568 <pages>
ffffffffc0204118:	8d91                	sub	a1,a1,a2
ffffffffc020411a:	4065d613          	srai	a2,a1,0x6
ffffffffc020411e:	00003717          	auipc	a4,0x3
ffffffffc0204122:	eea73703          	ld	a4,-278(a4) # ffffffffc0207008 <nbase>
ffffffffc0204126:	963a                	add	a2,a2,a4
    return KADDR(page2pa(page));
ffffffffc0204128:	00c61713          	slli	a4,a2,0xc
ffffffffc020412c:	8331                	srli	a4,a4,0xc
ffffffffc020412e:	00012697          	auipc	a3,0x12
ffffffffc0204132:	4326b683          	ld	a3,1074(a3) # ffffffffc0216560 <npage>
ffffffffc0204136:	0037959b          	slliw	a1,a5,0x3
    return page2ppn(page) << PGSHIFT;
ffffffffc020413a:	0632                	slli	a2,a2,0xc
    return KADDR(page2pa(page));
ffffffffc020413c:	02d77963          	bgeu	a4,a3,ffffffffc020416e <swapfs_read+0x74>
}
ffffffffc0204140:	60a2                	ld	ra,8(sp)
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT); // 调用IDE读取函数读取页面数据
ffffffffc0204142:	00012797          	auipc	a5,0x12
ffffffffc0204146:	4367b783          	ld	a5,1078(a5) # ffffffffc0216578 <va_pa_offset>
ffffffffc020414a:	46a1                	li	a3,8
ffffffffc020414c:	963e                	add	a2,a2,a5
ffffffffc020414e:	4505                	li	a0,1
}
ffffffffc0204150:	0141                	addi	sp,sp,16
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT); // 调用IDE读取函数读取页面数据
ffffffffc0204152:	b5efc06f          	j	ffffffffc02004b0 <ide_read_secs>
ffffffffc0204156:	86aa                	mv	a3,a0
ffffffffc0204158:	00003617          	auipc	a2,0x3
ffffffffc020415c:	a9860613          	addi	a2,a2,-1384 # ffffffffc0206bf0 <default_pmm_manager+0x70>
ffffffffc0204160:	45d1                	li	a1,20
ffffffffc0204162:	00003517          	auipc	a0,0x3
ffffffffc0204166:	a7650513          	addi	a0,a0,-1418 # ffffffffc0206bd8 <default_pmm_manager+0x58>
ffffffffc020416a:	85efc0ef          	jal	ra,ffffffffc02001c8 <__panic>
ffffffffc020416e:	86b2                	mv	a3,a2
ffffffffc0204170:	06700593          	li	a1,103
ffffffffc0204174:	00001617          	auipc	a2,0x1
ffffffffc0204178:	79c60613          	addi	a2,a2,1948 # ffffffffc0205910 <commands+0x760>
ffffffffc020417c:	00001517          	auipc	a0,0x1
ffffffffc0204180:	75c50513          	addi	a0,a0,1884 # ffffffffc02058d8 <commands+0x728>
ffffffffc0204184:	844fc0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc0204188 <swapfs_write>:

int
swapfs_write(swap_entry_t entry, struct Page *page) { // 向交换文件系统写入页面
ffffffffc0204188:	1141                	addi	sp,sp,-16
ffffffffc020418a:	e406                	sd	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT); // 调用IDE写入函数写入页面数据
ffffffffc020418c:	00855793          	srli	a5,a0,0x8
ffffffffc0204190:	cbb1                	beqz	a5,ffffffffc02041e4 <swapfs_write+0x5c>
ffffffffc0204192:	00012717          	auipc	a4,0x12
ffffffffc0204196:	3fe73703          	ld	a4,1022(a4) # ffffffffc0216590 <max_swap_offset>
ffffffffc020419a:	04e7f563          	bgeu	a5,a4,ffffffffc02041e4 <swapfs_write+0x5c>
    return page - pages + nbase;
ffffffffc020419e:	00012617          	auipc	a2,0x12
ffffffffc02041a2:	3ca63603          	ld	a2,970(a2) # ffffffffc0216568 <pages>
ffffffffc02041a6:	8d91                	sub	a1,a1,a2
ffffffffc02041a8:	4065d613          	srai	a2,a1,0x6
ffffffffc02041ac:	00003717          	auipc	a4,0x3
ffffffffc02041b0:	e5c73703          	ld	a4,-420(a4) # ffffffffc0207008 <nbase>
ffffffffc02041b4:	963a                	add	a2,a2,a4
    return KADDR(page2pa(page));
ffffffffc02041b6:	00c61713          	slli	a4,a2,0xc
ffffffffc02041ba:	8331                	srli	a4,a4,0xc
ffffffffc02041bc:	00012697          	auipc	a3,0x12
ffffffffc02041c0:	3a46b683          	ld	a3,932(a3) # ffffffffc0216560 <npage>
ffffffffc02041c4:	0037959b          	slliw	a1,a5,0x3
    return page2ppn(page) << PGSHIFT;
ffffffffc02041c8:	0632                	slli	a2,a2,0xc
    return KADDR(page2pa(page));
ffffffffc02041ca:	02d77963          	bgeu	a4,a3,ffffffffc02041fc <swapfs_write+0x74>
}
ffffffffc02041ce:	60a2                	ld	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT); // 调用IDE写入函数写入页面数据
ffffffffc02041d0:	00012797          	auipc	a5,0x12
ffffffffc02041d4:	3a87b783          	ld	a5,936(a5) # ffffffffc0216578 <va_pa_offset>
ffffffffc02041d8:	46a1                	li	a3,8
ffffffffc02041da:	963e                	add	a2,a2,a5
ffffffffc02041dc:	4505                	li	a0,1
}
ffffffffc02041de:	0141                	addi	sp,sp,16
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT); // 调用IDE写入函数写入页面数据
ffffffffc02041e0:	af4fc06f          	j	ffffffffc02004d4 <ide_write_secs>
ffffffffc02041e4:	86aa                	mv	a3,a0
ffffffffc02041e6:	00003617          	auipc	a2,0x3
ffffffffc02041ea:	a0a60613          	addi	a2,a2,-1526 # ffffffffc0206bf0 <default_pmm_manager+0x70>
ffffffffc02041ee:	45e5                	li	a1,25
ffffffffc02041f0:	00003517          	auipc	a0,0x3
ffffffffc02041f4:	9e850513          	addi	a0,a0,-1560 # ffffffffc0206bd8 <default_pmm_manager+0x58>
ffffffffc02041f8:	fd1fb0ef          	jal	ra,ffffffffc02001c8 <__panic>
ffffffffc02041fc:	86b2                	mv	a3,a2
ffffffffc02041fe:	06700593          	li	a1,103
ffffffffc0204202:	00001617          	auipc	a2,0x1
ffffffffc0204206:	70e60613          	addi	a2,a2,1806 # ffffffffc0205910 <commands+0x760>
ffffffffc020420a:	00001517          	auipc	a0,0x1
ffffffffc020420e:	6ce50513          	addi	a0,a0,1742 # ffffffffc02058d8 <commands+0x728>
ffffffffc0204212:	fb7fb0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc0204216 <switch_to>:
.text  # 表示接下来的代码段是程序代码
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to  # 声明 switch_to 函数为全局函数，可以被其他文件引用
switch_to:  # switch_to 函数的入口a0和a1是传参数的寄存器
    # save from's registers，a0 寄存器保存了指向 from 进程结构体的指针
    STORE ra, 0*REGBYTES(a0)  # 保存 from 进程的返回地址寄存器
ffffffffc0204216:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)  # 保存 from 进程的堆栈指针寄存器
ffffffffc020421a:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)  # 保存 from 进程的保存寄存器 s0
ffffffffc020421e:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)  # 保存 from 进程的保存寄存器 s1
ffffffffc0204220:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)  # 保存 from 进程的保存寄存器 s2
ffffffffc0204222:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)  # 保存 from 进程的保存寄存器 s3
ffffffffc0204226:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)  # 保存 from 进程的保存寄存器 s4
ffffffffc020422a:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)  # 保存 from 进程的保存寄存器 s5
ffffffffc020422e:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)  # 保存 from 进程的保存寄存器 s6
ffffffffc0204232:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)  # 保存 from 进程的保存寄存器 s7
ffffffffc0204236:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)  # 保存 from 进程的保存寄存器 s8
ffffffffc020423a:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)  # 保存 from 进程的保存寄存器 s9
ffffffffc020423e:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)  # 保存 from 进程的保存寄存器 s10
ffffffffc0204242:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)  # 保存 from 进程的保存寄存器 s11
ffffffffc0204246:	07b53423          	sd	s11,104(a0)

    # restore to's registers,a1传to的指针
    LOAD ra, 0*REGBYTES(a1)  # 恢复 to 进程的返回地址寄存器
ffffffffc020424a:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)  # 恢复 to 进程的堆栈指针寄存器
ffffffffc020424e:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)  # 恢复 to 进程的保存寄存器 s0
ffffffffc0204252:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)  # 恢复 to 进程的保存寄存器 s1
ffffffffc0204254:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)  # 恢复 to 进程的保存寄存器 s2
ffffffffc0204256:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)  # 恢复 to 进程的保存寄存器 s3
ffffffffc020425a:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)  # 恢复 to 进程的保存寄存器 s4
ffffffffc020425e:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)  # 恢复 to 进程的保存寄存器 s5
ffffffffc0204262:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)  # 恢复 to 进程的保存寄存器 s6
ffffffffc0204266:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)  # 恢复 to 进程的保存寄存器 s7
ffffffffc020426a:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)  # 恢复 to 进程的保存寄存器 s8
ffffffffc020426e:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)  # 恢复 to 进程的保存寄存器 s9
ffffffffc0204272:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)  # 恢复 to 进程的保存寄存器 s10
ffffffffc0204276:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)  # 恢复 to 进程的保存寄存器 s11
ffffffffc020427a:	0685bd83          	ld	s11,104(a1)

    ret  # 返回，完成进程切换，跳转到 trap/trap.S中的forkret，ra寄存器的设置位置是proc->context.ra = (uintptr_t)forkret;在文件proc.c中
ffffffffc020427e:	8082                	ret

ffffffffc0204280 <kernel_thread_entry>:
#kernel_thread_entry 的函数。
#这个函数的作用是作为内核线程的入口点，执行一些初始化操作后，跳转到实际的内核线程函数，并在内核线程函数返回后调用 do_exit 函数结束当前线程。
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1            # 将寄存器s1的值移动到寄存器a0中
ffffffffc0204280:	8526                	mv	a0,s1
	jalr s0                # 跳转到寄存器s0中存储的地址，并将返回地址存储到ra寄存器中
ffffffffc0204282:	9402                	jalr	s0

	jal do_exit            # 调用do_exit函数，结束当前线程
ffffffffc0204284:	484000ef          	jal	ra,ffffffffc0204708 <do_exit>

ffffffffc0204288 <alloc_proc>:
/*
 * alloc_proc - 分配并初始化一个新的进程控制块(proc_struct)。
 * 返回新分配的proc_struct指针，如果分配失败则返回NULL。
 */
static struct proc_struct *
alloc_proc(void) {
ffffffffc0204288:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct)); // 分配一个proc_struct结构
ffffffffc020428a:	0e800513          	li	a0,232
alloc_proc(void) {
ffffffffc020428e:	e022                	sd	s0,0(sp)
ffffffffc0204290:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct)); // 分配一个proc_struct结构
ffffffffc0204292:	debfe0ef          	jal	ra,ffffffffc020307c <kmalloc>
ffffffffc0204296:	842a                	mv	s0,a0
    if (proc != NULL) {
ffffffffc0204298:	c521                	beqz	a0,ffffffffc02042e0 <alloc_proc+0x58>
    //【提示】在alloc_proc函数的实现中，需要初始化的proc_struct结构中的成员变量至少包括：
    //state/pid/runs/kstack/need_resched/parent/mm/context/tf/cr3/flags/name。

        proc->state = PROC_UNINIT;                           // 设置进程状态为未初始化
        proc->pid = -1;                                      // 设置进程ID为-1（还未分配）
        proc->cr3 = boot_cr3;                                // 设置CR3寄存器的值（页目录基址）
ffffffffc020429a:	00012797          	auipc	a5,0x12
ffffffffc020429e:	2b67b783          	ld	a5,694(a5) # ffffffffc0216550 <boot_cr3>
ffffffffc02042a2:	f55c                	sd	a5,168(a0)
        proc->state = PROC_UNINIT;                           // 设置进程状态为未初始化
ffffffffc02042a4:	57fd                	li	a5,-1
ffffffffc02042a6:	1782                	slli	a5,a5,0x20
        proc->runs = 0;                                      // 设置进程运行次数为0
        proc->kstack = 0;                                    // 设置内核栈地址为0（还未分配）
        proc->need_resched = 0;                              // 设置不需要重新调度
        proc->parent = NULL;                                 // 设置父进程为空
        proc->mm = NULL;                                     // 设置内存管理字段为空
        memset(&(proc->context), 0, sizeof(struct context)); // 初始化上下文信息为0
ffffffffc02042a8:	07000613          	li	a2,112
ffffffffc02042ac:	4581                	li	a1,0
        proc->state = PROC_UNINIT;                           // 设置进程状态为未初始化
ffffffffc02042ae:	e11c                	sd	a5,0(a0)
        proc->runs = 0;                                      // 设置进程运行次数为0
ffffffffc02042b0:	00052423          	sw	zero,8(a0)
        proc->kstack = 0;                                    // 设置内核栈地址为0（还未分配）
ffffffffc02042b4:	00053823          	sd	zero,16(a0)
        proc->need_resched = 0;                              // 设置不需要重新调度
ffffffffc02042b8:	00052c23          	sw	zero,24(a0)
        proc->parent = NULL;                                 // 设置父进程为空
ffffffffc02042bc:	02053023          	sd	zero,32(a0)
        proc->mm = NULL;                                     // 设置内存管理字段为空
ffffffffc02042c0:	02053423          	sd	zero,40(a0)
        memset(&(proc->context), 0, sizeof(struct context)); // 初始化上下文信息为0
ffffffffc02042c4:	03050513          	addi	a0,a0,48
ffffffffc02042c8:	009000ef          	jal	ra,ffffffffc0204ad0 <memset>
        proc->tf = NULL;                                     // 设置trapframe为空
        proc->flags = 0;                                     // 设置进程标志为0
        memset(proc->name, 0, PROC_NAME_LEN);                // 初始化进程名为0
ffffffffc02042cc:	463d                	li	a2,15
        proc->tf = NULL;                                     // 设置trapframe为空
ffffffffc02042ce:	0a043023          	sd	zero,160(s0)
        proc->flags = 0;                                     // 设置进程标志为0
ffffffffc02042d2:	0a042823          	sw	zero,176(s0)
        memset(proc->name, 0, PROC_NAME_LEN);                // 初始化进程名为0
ffffffffc02042d6:	4581                	li	a1,0
ffffffffc02042d8:	0b440513          	addi	a0,s0,180
ffffffffc02042dc:	7f4000ef          	jal	ra,ffffffffc0204ad0 <memset>
    }
    return proc; // 返回分配的proc_struct结构
}
ffffffffc02042e0:	60a2                	ld	ra,8(sp)
ffffffffc02042e2:	8522                	mv	a0,s0
ffffffffc02042e4:	6402                	ld	s0,0(sp)
ffffffffc02042e6:	0141                	addi	sp,sp,16
ffffffffc02042e8:	8082                	ret

ffffffffc02042ea <forkret>:
 * forkret - 新进程的第一个内核入口点。
 * 当新进程第一次在内核态运行时，将执行此函数。
 */
static void
forkret(void) {
    forkrets(current->tf); // 执行forkrets函数
ffffffffc02042ea:	00012797          	auipc	a5,0x12
ffffffffc02042ee:	2c67b783          	ld	a5,710(a5) # ffffffffc02165b0 <current>
ffffffffc02042f2:	73c8                	ld	a0,160(a5)
ffffffffc02042f4:	879fc06f          	j	ffffffffc0200b6c <forkrets>

ffffffffc02042f8 <init_main>:
 * init_main - 第二个内核线程，用于创建 user_main 内核线程。
 * @arg: 传递给 init_main 的参数。
 * 返回值为 0 表示成功。
 */
static int
init_main(void *arg) {
ffffffffc02042f8:	7179                	addi	sp,sp,-48
ffffffffc02042fa:	ec26                	sd	s1,24(sp)
    memset(name, 0, sizeof(name)); // 清空字符数组
ffffffffc02042fc:	00012497          	auipc	s1,0x12
ffffffffc0204300:	21c48493          	addi	s1,s1,540 # ffffffffc0216518 <name.2>
init_main(void *arg) {
ffffffffc0204304:	f022                	sd	s0,32(sp)
ffffffffc0204306:	e84a                	sd	s2,16(sp)
ffffffffc0204308:	842a                	mv	s0,a0
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current)); // 打印initproc的PID和名称
ffffffffc020430a:	00012917          	auipc	s2,0x12
ffffffffc020430e:	2a693903          	ld	s2,678(s2) # ffffffffc02165b0 <current>
    memset(name, 0, sizeof(name)); // 清空字符数组
ffffffffc0204312:	4641                	li	a2,16
ffffffffc0204314:	4581                	li	a1,0
ffffffffc0204316:	8526                	mv	a0,s1
init_main(void *arg) {
ffffffffc0204318:	f406                	sd	ra,40(sp)
ffffffffc020431a:	e44e                	sd	s3,8(sp)
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current)); // 打印initproc的PID和名称
ffffffffc020431c:	00492983          	lw	s3,4(s2)
    memset(name, 0, sizeof(name)); // 清空字符数组
ffffffffc0204320:	7b0000ef          	jal	ra,ffffffffc0204ad0 <memset>
    return memcpy(name, proc->name, PROC_NAME_LEN); // 复制进程名到字符数组
ffffffffc0204324:	0b490593          	addi	a1,s2,180
ffffffffc0204328:	463d                	li	a2,15
ffffffffc020432a:	8526                	mv	a0,s1
ffffffffc020432c:	7b6000ef          	jal	ra,ffffffffc0204ae2 <memcpy>
ffffffffc0204330:	862a                	mv	a2,a0
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current)); // 打印initproc的PID和名称
ffffffffc0204332:	85ce                	mv	a1,s3
ffffffffc0204334:	00003517          	auipc	a0,0x3
ffffffffc0204338:	8dc50513          	addi	a0,a0,-1828 # ffffffffc0206c10 <default_pmm_manager+0x90>
ffffffffc020433c:	d91fb0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("To U: \"%s\".\n", (const char *)arg); // 打印传递的参数
ffffffffc0204340:	85a2                	mv	a1,s0
ffffffffc0204342:	00003517          	auipc	a0,0x3
ffffffffc0204346:	8f650513          	addi	a0,a0,-1802 # ffffffffc0206c38 <default_pmm_manager+0xb8>
ffffffffc020434a:	d83fb0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("To U: \"en.., Bye, Bye. :)\"\n"); // 打印退出信息
ffffffffc020434e:	00003517          	auipc	a0,0x3
ffffffffc0204352:	8fa50513          	addi	a0,a0,-1798 # ffffffffc0206c48 <default_pmm_manager+0xc8>
ffffffffc0204356:	d77fb0ef          	jal	ra,ffffffffc02000cc <cprintf>
    return 0; // 返回0表示成功
}
ffffffffc020435a:	70a2                	ld	ra,40(sp)
ffffffffc020435c:	7402                	ld	s0,32(sp)
ffffffffc020435e:	64e2                	ld	s1,24(sp)
ffffffffc0204360:	6942                	ld	s2,16(sp)
ffffffffc0204362:	69a2                	ld	s3,8(sp)
ffffffffc0204364:	4501                	li	a0,0
ffffffffc0204366:	6145                	addi	sp,sp,48
ffffffffc0204368:	8082                	ret

ffffffffc020436a <proc_run>:
proc_run(struct proc_struct *proc) {
ffffffffc020436a:	7179                	addi	sp,sp,-48
ffffffffc020436c:	ec4a                	sd	s2,24(sp)
    if (proc != current) { // 如果proc不是当前进程
ffffffffc020436e:	00012917          	auipc	s2,0x12
ffffffffc0204372:	24290913          	addi	s2,s2,578 # ffffffffc02165b0 <current>
proc_run(struct proc_struct *proc) {
ffffffffc0204376:	f026                	sd	s1,32(sp)
    if (proc != current) { // 如果proc不是当前进程
ffffffffc0204378:	00093483          	ld	s1,0(s2)
proc_run(struct proc_struct *proc) {
ffffffffc020437c:	f406                	sd	ra,40(sp)
ffffffffc020437e:	e84e                	sd	s3,16(sp)
    if (proc != current) { // 如果proc不是当前进程
ffffffffc0204380:	02a48963          	beq	s1,a0,ffffffffc02043b2 <proc_run+0x48>
    if (read_csr(sstatus) & SSTATUS_SIE) { // 如果当前中断使能
ffffffffc0204384:	100027f3          	csrr	a5,sstatus
ffffffffc0204388:	8b89                	andi	a5,a5,2
    return 0; // 返回0表示中断之前是禁用的
ffffffffc020438a:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE) { // 如果当前中断使能
ffffffffc020438c:	e3a1                	bnez	a5,ffffffffc02043cc <proc_run+0x62>
            lcr3(next->cr3);
ffffffffc020438e:	755c                	ld	a5,168(a0)

// 设置页表基地址寄存器
static inline void
lcr3(unsigned int cr3) {
  // 写入CSR寄存器sptbr，设置页表基地址
  write_csr(sptbr, SATP32_MODE | (cr3 >> RISCV_PGSHIFT));
ffffffffc0204390:	80000737          	lui	a4,0x80000
            current = proc;
ffffffffc0204394:	00a93023          	sd	a0,0(s2)
ffffffffc0204398:	00c7d79b          	srliw	a5,a5,0xc
ffffffffc020439c:	8fd9                	or	a5,a5,a4
ffffffffc020439e:	18079073          	csrw	satp,a5
            switch_to(&(prev->context), &(next->context));
ffffffffc02043a2:	03050593          	addi	a1,a0,48
ffffffffc02043a6:	03048513          	addi	a0,s1,48
ffffffffc02043aa:	e6dff0ef          	jal	ra,ffffffffc0204216 <switch_to>
    if (flag) { // 如果flag为1
ffffffffc02043ae:	00099863          	bnez	s3,ffffffffc02043be <proc_run+0x54>
}
ffffffffc02043b2:	70a2                	ld	ra,40(sp)
ffffffffc02043b4:	7482                	ld	s1,32(sp)
ffffffffc02043b6:	6962                	ld	s2,24(sp)
ffffffffc02043b8:	69c2                	ld	s3,16(sp)
ffffffffc02043ba:	6145                	addi	sp,sp,48
ffffffffc02043bc:	8082                	ret
ffffffffc02043be:	70a2                	ld	ra,40(sp)
ffffffffc02043c0:	7482                	ld	s1,32(sp)
ffffffffc02043c2:	6962                	ld	s2,24(sp)
ffffffffc02043c4:	69c2                	ld	s3,16(sp)
ffffffffc02043c6:	6145                	addi	sp,sp,48
        intr_enable(); // 使能中断
ffffffffc02043c8:	9f6fc06f          	j	ffffffffc02005be <intr_enable>
ffffffffc02043cc:	e42a                	sd	a0,8(sp)
        intr_disable(); // 禁用中断
ffffffffc02043ce:	9f6fc0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
        return 1; // 返回1表示中断之前是使能的
ffffffffc02043d2:	6522                	ld	a0,8(sp)
ffffffffc02043d4:	4985                	li	s3,1
ffffffffc02043d6:	bf65                	j	ffffffffc020438e <proc_run+0x24>

ffffffffc02043d8 <do_fork>:
    if (nr_process >= MAX_PROCESS) { // 如果当前进程数量超过最大进程数
ffffffffc02043d8:	00012717          	auipc	a4,0x12
ffffffffc02043dc:	1f072703          	lw	a4,496(a4) # ffffffffc02165c8 <nr_process>
ffffffffc02043e0:	6785                	lui	a5,0x1
ffffffffc02043e2:	26f75063          	bge	a4,a5,ffffffffc0204642 <do_fork+0x26a>
do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf) {
ffffffffc02043e6:	7179                	addi	sp,sp,-48
ffffffffc02043e8:	f022                	sd	s0,32(sp)
ffffffffc02043ea:	ec26                	sd	s1,24(sp)
ffffffffc02043ec:	e84a                	sd	s2,16(sp)
ffffffffc02043ee:	f406                	sd	ra,40(sp)
ffffffffc02043f0:	e44e                	sd	s3,8(sp)
ffffffffc02043f2:	84ae                	mv	s1,a1
ffffffffc02043f4:	8432                	mv	s0,a2
    if ((proc = alloc_proc()) == NULL) // 如果分配失败
ffffffffc02043f6:	e93ff0ef          	jal	ra,ffffffffc0204288 <alloc_proc>
ffffffffc02043fa:	892a                	mv	s2,a0
ffffffffc02043fc:	24050863          	beqz	a0,ffffffffc020464c <do_fork+0x274>
    proc->parent = current; // 设置子进程的父进程为当前进程
ffffffffc0204400:	00012997          	auipc	s3,0x12
ffffffffc0204404:	1b098993          	addi	s3,s3,432 # ffffffffc02165b0 <current>
ffffffffc0204408:	0009b783          	ld	a5,0(s3)
    struct Page *page = alloc_pages(KSTACKPAGE); // 分配内核栈页
ffffffffc020440c:	4509                	li	a0,2
    proc->parent = current; // 设置子进程的父进程为当前进程
ffffffffc020440e:	02f93023          	sd	a5,32(s2)
    struct Page *page = alloc_pages(KSTACKPAGE); // 分配内核栈页
ffffffffc0204412:	f98fc0ef          	jal	ra,ffffffffc0200baa <alloc_pages>
    if (page != NULL) {
ffffffffc0204416:	1e050063          	beqz	a0,ffffffffc02045f6 <do_fork+0x21e>
    return page - pages + nbase;
ffffffffc020441a:	00012697          	auipc	a3,0x12
ffffffffc020441e:	14e6b683          	ld	a3,334(a3) # ffffffffc0216568 <pages>
ffffffffc0204422:	40d506b3          	sub	a3,a0,a3
ffffffffc0204426:	8699                	srai	a3,a3,0x6
ffffffffc0204428:	00003517          	auipc	a0,0x3
ffffffffc020442c:	be053503          	ld	a0,-1056(a0) # ffffffffc0207008 <nbase>
ffffffffc0204430:	96aa                	add	a3,a3,a0
    return KADDR(page2pa(page));
ffffffffc0204432:	00c69793          	slli	a5,a3,0xc
ffffffffc0204436:	83b1                	srli	a5,a5,0xc
ffffffffc0204438:	00012717          	auipc	a4,0x12
ffffffffc020443c:	12873703          	ld	a4,296(a4) # ffffffffc0216560 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc0204440:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204442:	22e7f763          	bgeu	a5,a4,ffffffffc0204670 <do_fork+0x298>
    assert(current->mm == NULL); // 确保当前进程的内存管理结构为空
ffffffffc0204446:	0009b783          	ld	a5,0(s3)
ffffffffc020444a:	00012717          	auipc	a4,0x12
ffffffffc020444e:	12e73703          	ld	a4,302(a4) # ffffffffc0216578 <va_pa_offset>
ffffffffc0204452:	96ba                	add	a3,a3,a4
ffffffffc0204454:	779c                	ld	a5,40(a5)
        proc->kstack = (uintptr_t)page2kva(page); // 设置内核栈地址
ffffffffc0204456:	00d93823          	sd	a3,16(s2)
    assert(current->mm == NULL); // 确保当前进程的内存管理结构为空
ffffffffc020445a:	1e079b63          	bnez	a5,ffffffffc0204650 <do_fork+0x278>
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE - sizeof(struct trapframe)); // 设置trapframe地址
ffffffffc020445e:	6789                	lui	a5,0x2
ffffffffc0204460:	ee078793          	addi	a5,a5,-288 # 1ee0 <kern_entry-0xffffffffc01fe120>
ffffffffc0204464:	96be                	add	a3,a3,a5
    *(proc->tf) = *tf; // 复制trapframe内容
ffffffffc0204466:	8622                	mv	a2,s0
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE - sizeof(struct trapframe)); // 设置trapframe地址
ffffffffc0204468:	0ad93023          	sd	a3,160(s2)
    *(proc->tf) = *tf; // 复制trapframe内容
ffffffffc020446c:	87b6                	mv	a5,a3
ffffffffc020446e:	12040893          	addi	a7,s0,288
ffffffffc0204472:	00063803          	ld	a6,0(a2)
ffffffffc0204476:	6608                	ld	a0,8(a2)
ffffffffc0204478:	6a0c                	ld	a1,16(a2)
ffffffffc020447a:	6e18                	ld	a4,24(a2)
ffffffffc020447c:	0107b023          	sd	a6,0(a5)
ffffffffc0204480:	e788                	sd	a0,8(a5)
ffffffffc0204482:	eb8c                	sd	a1,16(a5)
ffffffffc0204484:	ef98                	sd	a4,24(a5)
ffffffffc0204486:	02060613          	addi	a2,a2,32
ffffffffc020448a:	02078793          	addi	a5,a5,32
ffffffffc020448e:	ff1612e3          	bne	a2,a7,ffffffffc0204472 <do_fork+0x9a>
    proc->tf->gpr.a0 = 0; // 设置a0寄存器为0，表示子进程刚刚被fork,说明这个进程是一个子进程
ffffffffc0204492:	0406b823          	sd	zero,80(a3)
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp; // 设置栈指针
ffffffffc0204496:	10048f63          	beqz	s1,ffffffffc02045b4 <do_fork+0x1dc>
ffffffffc020449a:	ea84                	sd	s1,16(a3)
    proc->context.ra = (uintptr_t)forkret; // 设置返回地址为forkret函数
ffffffffc020449c:	00000797          	auipc	a5,0x0
ffffffffc02044a0:	e4e78793          	addi	a5,a5,-434 # ffffffffc02042ea <forkret>
ffffffffc02044a4:	02f93823          	sd	a5,48(s2)
    proc->context.sp = (uintptr_t)(proc->tf); // 设置上下文栈指针,把trapframe放在上下文的栈顶
ffffffffc02044a8:	02d93c23          	sd	a3,56(s2)
    if (read_csr(sstatus) & SSTATUS_SIE) { // 如果当前中断使能
ffffffffc02044ac:	100027f3          	csrr	a5,sstatus
ffffffffc02044b0:	8b89                	andi	a5,a5,2
    return 0; // 返回0表示中断之前是禁用的
ffffffffc02044b2:	4481                	li	s1,0
    if (read_csr(sstatus) & SSTATUS_SIE) { // 如果当前中断使能
ffffffffc02044b4:	12079063          	bnez	a5,ffffffffc02045d4 <do_fork+0x1fc>
    if (++ last_pid >= MAX_PID) { // 如果last_pid超过最大PID
ffffffffc02044b8:	00007817          	auipc	a6,0x7
ffffffffc02044bc:	ba080813          	addi	a6,a6,-1120 # ffffffffc020b058 <last_pid.1>
ffffffffc02044c0:	00082783          	lw	a5,0(a6)
ffffffffc02044c4:	6709                	lui	a4,0x2
ffffffffc02044c6:	0017851b          	addiw	a0,a5,1
ffffffffc02044ca:	00a82023          	sw	a0,0(a6)
ffffffffc02044ce:	06e55c63          	bge	a0,a4,ffffffffc0204546 <do_fork+0x16e>
    if (last_pid >= next_safe) { // 如果last_pid超过next_safe
ffffffffc02044d2:	00007317          	auipc	t1,0x7
ffffffffc02044d6:	b8a30313          	addi	t1,t1,-1142 # ffffffffc020b05c <next_safe.0>
ffffffffc02044da:	00032783          	lw	a5,0(t1)
ffffffffc02044de:	00012417          	auipc	s0,0x12
ffffffffc02044e2:	04a40413          	addi	s0,s0,74 # ffffffffc0216528 <proc_list>
ffffffffc02044e6:	06f55863          	bge	a0,a5,ffffffffc0204556 <do_fork+0x17e>
        proc->pid = get_pid();                    // 为子进程分配一个唯一的进程ID
ffffffffc02044ea:	00a92223          	sw	a0,4(s2)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link)); // 将进程添加到哈希列表中
ffffffffc02044ee:	45a9                	li	a1,10
ffffffffc02044f0:	2501                	sext.w	a0,a0
ffffffffc02044f2:	21b000ef          	jal	ra,ffffffffc0204f0c <hash32>
ffffffffc02044f6:	02051793          	slli	a5,a0,0x20
ffffffffc02044fa:	01c7d513          	srli	a0,a5,0x1c
ffffffffc02044fe:	0000e797          	auipc	a5,0xe
ffffffffc0204502:	01a78793          	addi	a5,a5,26 # ffffffffc0212518 <hash_list>
ffffffffc0204506:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next); // 调用__list_add函数
ffffffffc0204508:	6514                	ld	a3,8(a0)
ffffffffc020450a:	0d890793          	addi	a5,s2,216
ffffffffc020450e:	6418                	ld	a4,8(s0)
    prev->next = next->prev = elm; // 将前一个节点的下一个指针和后一个节点的前一个指针指向新节点
ffffffffc0204510:	e29c                	sd	a5,0(a3)
ffffffffc0204512:	e51c                	sd	a5,8(a0)
    elm->next = next; // 将新节点的下一个指针指向后一个节点
ffffffffc0204514:	0ed93023          	sd	a3,224(s2)
        list_add(&proc_list, &(proc->list_link)); // 将新进程添加到进程列表中
ffffffffc0204518:	0c890793          	addi	a5,s2,200
    elm->prev = prev; // 将新节点的前一个指针指向前一个节点
ffffffffc020451c:	0ca93c23          	sd	a0,216(s2)
    prev->next = next->prev = elm; // 将前一个节点的下一个指针和后一个节点的前一个指针指向新节点
ffffffffc0204520:	e31c                	sd	a5,0(a4)
ffffffffc0204522:	e41c                	sd	a5,8(s0)
    elm->next = next; // 将新节点的下一个指针指向后一个节点
ffffffffc0204524:	0ce93823          	sd	a4,208(s2)
    elm->prev = prev; // 将新节点的前一个指针指向前一个节点
ffffffffc0204528:	0c893423          	sd	s0,200(s2)
    if (flag) { // 如果flag为1
ffffffffc020452c:	e8c5                	bnez	s1,ffffffffc02045dc <do_fork+0x204>
    wakeup_proc(proc); // 唤醒子进程
ffffffffc020452e:	854a                	mv	a0,s2
ffffffffc0204530:	45e000ef          	jal	ra,ffffffffc020498e <wakeup_proc>
    ret = proc->pid; // 设置返回值为子进程的PID
ffffffffc0204534:	00492503          	lw	a0,4(s2)
}
ffffffffc0204538:	70a2                	ld	ra,40(sp)
ffffffffc020453a:	7402                	ld	s0,32(sp)
ffffffffc020453c:	64e2                	ld	s1,24(sp)
ffffffffc020453e:	6942                	ld	s2,16(sp)
ffffffffc0204540:	69a2                	ld	s3,8(sp)
ffffffffc0204542:	6145                	addi	sp,sp,48
ffffffffc0204544:	8082                	ret
        last_pid = 1; // 重置last_pid为1
ffffffffc0204546:	4785                	li	a5,1
ffffffffc0204548:	00f82023          	sw	a5,0(a6)
        goto inside; // 跳转到inside标签
ffffffffc020454c:	4505                	li	a0,1
ffffffffc020454e:	00007317          	auipc	t1,0x7
ffffffffc0204552:	b0e30313          	addi	t1,t1,-1266 # ffffffffc020b05c <next_safe.0>
    return listelm->next; // 返回下一个节点
ffffffffc0204556:	00012417          	auipc	s0,0x12
ffffffffc020455a:	fd240413          	addi	s0,s0,-46 # ffffffffc0216528 <proc_list>
ffffffffc020455e:	00843e03          	ld	t3,8(s0)
        next_safe = MAX_PID; // 重置next_safe为最大PID
ffffffffc0204562:	6789                	lui	a5,0x2
ffffffffc0204564:	00f32023          	sw	a5,0(t1)
ffffffffc0204568:	86aa                	mv	a3,a0
ffffffffc020456a:	4581                	li	a1,0
        while ((le = list_next(le)) != list) { // 遍历进程列表
ffffffffc020456c:	6e89                	lui	t4,0x2
ffffffffc020456e:	068e0f63          	beq	t3,s0,ffffffffc02045ec <do_fork+0x214>
ffffffffc0204572:	88ae                	mv	a7,a1
ffffffffc0204574:	87f2                	mv	a5,t3
ffffffffc0204576:	6609                	lui	a2,0x2
ffffffffc0204578:	a811                	j	ffffffffc020458c <do_fork+0x1b4>
            else if (proc->pid > last_pid && next_safe > proc->pid) { // 如果进程PID大于last_pid且next_safe大于进程PID
ffffffffc020457a:	00e6d663          	bge	a3,a4,ffffffffc0204586 <do_fork+0x1ae>
ffffffffc020457e:	00c75463          	bge	a4,a2,ffffffffc0204586 <do_fork+0x1ae>
ffffffffc0204582:	863a                	mv	a2,a4
ffffffffc0204584:	4885                	li	a7,1
ffffffffc0204586:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list) { // 遍历进程列表
ffffffffc0204588:	00878d63          	beq	a5,s0,ffffffffc02045a2 <do_fork+0x1ca>
            if (proc->pid == last_pid) { // 如果进程PID等于last_pid
ffffffffc020458c:	f3c7a703          	lw	a4,-196(a5) # 1f3c <kern_entry-0xffffffffc01fe0c4>
ffffffffc0204590:	fed715e3          	bne	a4,a3,ffffffffc020457a <do_fork+0x1a2>
                if (++ last_pid >= next_safe) { // 增加last_pid并检查是否超过next_safe
ffffffffc0204594:	2685                	addiw	a3,a3,1
ffffffffc0204596:	04c6d663          	bge	a3,a2,ffffffffc02045e2 <do_fork+0x20a>
ffffffffc020459a:	679c                	ld	a5,8(a5)
ffffffffc020459c:	4585                	li	a1,1
        while ((le = list_next(le)) != list) { // 遍历进程列表
ffffffffc020459e:	fe8797e3          	bne	a5,s0,ffffffffc020458c <do_fork+0x1b4>
ffffffffc02045a2:	c581                	beqz	a1,ffffffffc02045aa <do_fork+0x1d2>
ffffffffc02045a4:	00d82023          	sw	a3,0(a6)
ffffffffc02045a8:	8536                	mv	a0,a3
ffffffffc02045aa:	f40880e3          	beqz	a7,ffffffffc02044ea <do_fork+0x112>
ffffffffc02045ae:	00c32023          	sw	a2,0(t1)
ffffffffc02045b2:	bf25                	j	ffffffffc02044ea <do_fork+0x112>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp; // 设置栈指针
ffffffffc02045b4:	84b6                	mv	s1,a3
ffffffffc02045b6:	ea84                	sd	s1,16(a3)
    proc->context.ra = (uintptr_t)forkret; // 设置返回地址为forkret函数
ffffffffc02045b8:	00000797          	auipc	a5,0x0
ffffffffc02045bc:	d3278793          	addi	a5,a5,-718 # ffffffffc02042ea <forkret>
ffffffffc02045c0:	02f93823          	sd	a5,48(s2)
    proc->context.sp = (uintptr_t)(proc->tf); // 设置上下文栈指针,把trapframe放在上下文的栈顶
ffffffffc02045c4:	02d93c23          	sd	a3,56(s2)
    if (read_csr(sstatus) & SSTATUS_SIE) { // 如果当前中断使能
ffffffffc02045c8:	100027f3          	csrr	a5,sstatus
ffffffffc02045cc:	8b89                	andi	a5,a5,2
    return 0; // 返回0表示中断之前是禁用的
ffffffffc02045ce:	4481                	li	s1,0
    if (read_csr(sstatus) & SSTATUS_SIE) { // 如果当前中断使能
ffffffffc02045d0:	ee0784e3          	beqz	a5,ffffffffc02044b8 <do_fork+0xe0>
        intr_disable(); // 禁用中断
ffffffffc02045d4:	ff1fb0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
        return 1; // 返回1表示中断之前是使能的
ffffffffc02045d8:	4485                	li	s1,1
ffffffffc02045da:	bdf9                	j	ffffffffc02044b8 <do_fork+0xe0>
        intr_enable(); // 使能中断
ffffffffc02045dc:	fe3fb0ef          	jal	ra,ffffffffc02005be <intr_enable>
ffffffffc02045e0:	b7b9                	j	ffffffffc020452e <do_fork+0x156>
                    if (last_pid >= MAX_PID) { // 如果last_pid超过最大PID
ffffffffc02045e2:	01d6c363          	blt	a3,t4,ffffffffc02045e8 <do_fork+0x210>
                        last_pid = 1; // 重置last_pid为1
ffffffffc02045e6:	4685                	li	a3,1
                    goto repeat; // 重新遍历进程列表
ffffffffc02045e8:	4585                	li	a1,1
ffffffffc02045ea:	b751                	j	ffffffffc020456e <do_fork+0x196>
ffffffffc02045ec:	cda9                	beqz	a1,ffffffffc0204646 <do_fork+0x26e>
ffffffffc02045ee:	00d82023          	sw	a3,0(a6)
    return last_pid; // 返回分配的PID
ffffffffc02045f2:	8536                	mv	a0,a3
ffffffffc02045f4:	bddd                	j	ffffffffc02044ea <do_fork+0x112>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE); // 释放内核栈页
ffffffffc02045f6:	01093683          	ld	a3,16(s2)
    return pa2page(PADDR(kva));
ffffffffc02045fa:	c02007b7          	lui	a5,0xc0200
ffffffffc02045fe:	0af6e163          	bltu	a3,a5,ffffffffc02046a0 <do_fork+0x2c8>
ffffffffc0204602:	00012797          	auipc	a5,0x12
ffffffffc0204606:	f767b783          	ld	a5,-138(a5) # ffffffffc0216578 <va_pa_offset>
ffffffffc020460a:	40f687b3          	sub	a5,a3,a5
    if (PPN(pa) >= npage) {
ffffffffc020460e:	83b1                	srli	a5,a5,0xc
ffffffffc0204610:	00012717          	auipc	a4,0x12
ffffffffc0204614:	f5073703          	ld	a4,-176(a4) # ffffffffc0216560 <npage>
ffffffffc0204618:	06e7f863          	bgeu	a5,a4,ffffffffc0204688 <do_fork+0x2b0>
    return &pages[PPN(pa) - nbase];
ffffffffc020461c:	00003717          	auipc	a4,0x3
ffffffffc0204620:	9ec73703          	ld	a4,-1556(a4) # ffffffffc0207008 <nbase>
ffffffffc0204624:	8f99                	sub	a5,a5,a4
ffffffffc0204626:	079a                	slli	a5,a5,0x6
ffffffffc0204628:	00012517          	auipc	a0,0x12
ffffffffc020462c:	f4053503          	ld	a0,-192(a0) # ffffffffc0216568 <pages>
ffffffffc0204630:	953e                	add	a0,a0,a5
ffffffffc0204632:	4589                	li	a1,2
ffffffffc0204634:	e08fc0ef          	jal	ra,ffffffffc0200c3c <free_pages>
    kfree(proc); // 释放子进程的proc_struct
ffffffffc0204638:	854a                	mv	a0,s2
ffffffffc020463a:	af3fe0ef          	jal	ra,ffffffffc020312c <kfree>
    ret = -E_NO_MEM; // 初始化返回值为内存不足错误码
ffffffffc020463e:	5571                	li	a0,-4
    goto fork_out; // 跳转到fork_out标签
ffffffffc0204640:	bde5                	j	ffffffffc0204538 <do_fork+0x160>
    int ret = -E_NO_FREE_PROC; // 初始化返回值为没有空闲进程错误码
ffffffffc0204642:	556d                	li	a0,-5
}
ffffffffc0204644:	8082                	ret
    return last_pid; // 返回分配的PID
ffffffffc0204646:	00082503          	lw	a0,0(a6)
ffffffffc020464a:	b545                	j	ffffffffc02044ea <do_fork+0x112>
    ret = -E_NO_MEM; // 初始化返回值为内存不足错误码
ffffffffc020464c:	5571                	li	a0,-4
    return ret; // 返回结果
ffffffffc020464e:	b5ed                	j	ffffffffc0204538 <do_fork+0x160>
    assert(current->mm == NULL); // 确保当前进程的内存管理结构为空
ffffffffc0204650:	00002697          	auipc	a3,0x2
ffffffffc0204654:	61868693          	addi	a3,a3,1560 # ffffffffc0206c68 <default_pmm_manager+0xe8>
ffffffffc0204658:	00001617          	auipc	a2,0x1
ffffffffc020465c:	3c860613          	addi	a2,a2,968 # ffffffffc0205a20 <commands+0x870>
ffffffffc0204660:	15900593          	li	a1,345
ffffffffc0204664:	00002517          	auipc	a0,0x2
ffffffffc0204668:	61c50513          	addi	a0,a0,1564 # ffffffffc0206c80 <default_pmm_manager+0x100>
ffffffffc020466c:	b5dfb0ef          	jal	ra,ffffffffc02001c8 <__panic>
    return KADDR(page2pa(page));
ffffffffc0204670:	00001617          	auipc	a2,0x1
ffffffffc0204674:	2a060613          	addi	a2,a2,672 # ffffffffc0205910 <commands+0x760>
ffffffffc0204678:	06700593          	li	a1,103
ffffffffc020467c:	00001517          	auipc	a0,0x1
ffffffffc0204680:	25c50513          	addi	a0,a0,604 # ffffffffc02058d8 <commands+0x728>
ffffffffc0204684:	b45fb0ef          	jal	ra,ffffffffc02001c8 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0204688:	00001617          	auipc	a2,0x1
ffffffffc020468c:	23060613          	addi	a2,a2,560 # ffffffffc02058b8 <commands+0x708>
ffffffffc0204690:	06000593          	li	a1,96
ffffffffc0204694:	00001517          	auipc	a0,0x1
ffffffffc0204698:	24450513          	addi	a0,a0,580 # ffffffffc02058d8 <commands+0x728>
ffffffffc020469c:	b2dfb0ef          	jal	ra,ffffffffc02001c8 <__panic>
    return pa2page(PADDR(kva));
ffffffffc02046a0:	00001617          	auipc	a2,0x1
ffffffffc02046a4:	30060613          	addi	a2,a2,768 # ffffffffc02059a0 <commands+0x7f0>
ffffffffc02046a8:	06c00593          	li	a1,108
ffffffffc02046ac:	00001517          	auipc	a0,0x1
ffffffffc02046b0:	22c50513          	addi	a0,a0,556 # ffffffffc02058d8 <commands+0x728>
ffffffffc02046b4:	b15fb0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc02046b8 <kernel_thread>:
int kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags) {
ffffffffc02046b8:	7129                	addi	sp,sp,-320
ffffffffc02046ba:	fa22                	sd	s0,304(sp)
ffffffffc02046bc:	f626                	sd	s1,296(sp)
ffffffffc02046be:	f24a                	sd	s2,288(sp)
ffffffffc02046c0:	84ae                	mv	s1,a1
ffffffffc02046c2:	892a                	mv	s2,a0
ffffffffc02046c4:	8432                	mv	s0,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc02046c6:	4581                	li	a1,0
ffffffffc02046c8:	12000613          	li	a2,288
ffffffffc02046cc:	850a                	mv	a0,sp
int kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags) {
ffffffffc02046ce:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc02046d0:	400000ef          	jal	ra,ffffffffc0204ad0 <memset>
    tf.gpr.s0 = (uintptr_t)fn; // s0 寄存器保存函数指针
ffffffffc02046d4:	e0ca                	sd	s2,64(sp)
    tf.gpr.s1 = (uintptr_t)arg; // s1 寄存器保存函数参数
ffffffffc02046d6:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc02046d8:	100027f3          	csrr	a5,sstatus
ffffffffc02046dc:	edd7f793          	andi	a5,a5,-291
ffffffffc02046e0:	1207e793          	ori	a5,a5,288
ffffffffc02046e4:	e23e                	sd	a5,256(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02046e6:	860a                	mv	a2,sp
ffffffffc02046e8:	10046513          	ori	a0,s0,256
    tf.epc = (uintptr_t)kernel_thread_entry;    // epc用于存储发生异常或中断时的程序计数器（PC）值
ffffffffc02046ec:	00000797          	auipc	a5,0x0
ffffffffc02046f0:	b9478793          	addi	a5,a5,-1132 # ffffffffc0204280 <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02046f4:	4581                	li	a1,0
    tf.epc = (uintptr_t)kernel_thread_entry;    // epc用于存储发生异常或中断时的程序计数器（PC）值
ffffffffc02046f6:	e63e                	sd	a5,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02046f8:	ce1ff0ef          	jal	ra,ffffffffc02043d8 <do_fork>
}
ffffffffc02046fc:	70f2                	ld	ra,312(sp)
ffffffffc02046fe:	7452                	ld	s0,304(sp)
ffffffffc0204700:	74b2                	ld	s1,296(sp)
ffffffffc0204702:	7912                	ld	s2,288(sp)
ffffffffc0204704:	6131                	addi	sp,sp,320
ffffffffc0204706:	8082                	ret

ffffffffc0204708 <do_exit>:
do_exit(int error_code) {
ffffffffc0204708:	1141                	addi	sp,sp,-16
    panic("process exit!!.\n"); // 调用panic函数，打印进程退出信息
ffffffffc020470a:	00002617          	auipc	a2,0x2
ffffffffc020470e:	58e60613          	addi	a2,a2,1422 # ffffffffc0206c98 <default_pmm_manager+0x118>
ffffffffc0204712:	1cc00593          	li	a1,460
ffffffffc0204716:	00002517          	auipc	a0,0x2
ffffffffc020471a:	56a50513          	addi	a0,a0,1386 # ffffffffc0206c80 <default_pmm_manager+0x100>
do_exit(int error_code) {
ffffffffc020471e:	e406                	sd	ra,8(sp)
    panic("process exit!!.\n"); // 调用panic函数，打印进程退出信息
ffffffffc0204720:	aa9fb0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc0204724 <proc_init>:

/*
 * proc_init - 初始化进程子系统，创建第一个内核线程 idleproc 和第二个内核线程 init_main。
 */
void
proc_init(void) {
ffffffffc0204724:	7179                	addi	sp,sp,-48
ffffffffc0204726:	ec26                	sd	s1,24(sp)
    elm->prev = elm->next = elm; // 将节点的前后指针都指向自己
ffffffffc0204728:	00012797          	auipc	a5,0x12
ffffffffc020472c:	e0078793          	addi	a5,a5,-512 # ffffffffc0216528 <proc_list>
ffffffffc0204730:	f406                	sd	ra,40(sp)
ffffffffc0204732:	f022                	sd	s0,32(sp)
ffffffffc0204734:	e84a                	sd	s2,16(sp)
ffffffffc0204736:	e44e                	sd	s3,8(sp)
ffffffffc0204738:	0000e497          	auipc	s1,0xe
ffffffffc020473c:	de048493          	addi	s1,s1,-544 # ffffffffc0212518 <hash_list>
ffffffffc0204740:	e79c                	sd	a5,8(a5)
ffffffffc0204742:	e39c                	sd	a5,0(a5)
    int i; // 定义循环变量

    list_init(&proc_list); // 初始化进程列表
    for (i = 0; i < HASH_LIST_SIZE; i ++) { // 遍历哈希列表
ffffffffc0204744:	00012717          	auipc	a4,0x12
ffffffffc0204748:	dd470713          	addi	a4,a4,-556 # ffffffffc0216518 <name.2>
ffffffffc020474c:	87a6                	mv	a5,s1
ffffffffc020474e:	e79c                	sd	a5,8(a5)
ffffffffc0204750:	e39c                	sd	a5,0(a5)
ffffffffc0204752:	07c1                	addi	a5,a5,16
ffffffffc0204754:	fef71de3          	bne	a4,a5,ffffffffc020474e <proc_init+0x2a>
        list_init(hash_list + i); // 初始化每个哈希列表
    }

    if ((idleproc = alloc_proc()) == NULL) { // 分配idleproc失败
ffffffffc0204758:	b31ff0ef          	jal	ra,ffffffffc0204288 <alloc_proc>
ffffffffc020475c:	00012917          	auipc	s2,0x12
ffffffffc0204760:	e5c90913          	addi	s2,s2,-420 # ffffffffc02165b8 <idleproc>
ffffffffc0204764:	00a93023          	sd	a0,0(s2)
ffffffffc0204768:	18050d63          	beqz	a0,ffffffffc0204902 <proc_init+0x1de>
        panic("cannot alloc idleproc.\n"); // 调用panic函数，打印错误信息
    }

    // 检查alloc_proc函数是否正确
    int *context_mem = (int*) kmalloc(sizeof(struct context)); // 分配context内存
ffffffffc020476c:	07000513          	li	a0,112
ffffffffc0204770:	90dfe0ef          	jal	ra,ffffffffc020307c <kmalloc>
    memset(context_mem, 0, sizeof(struct context)); // 初始化context内存为0
ffffffffc0204774:	07000613          	li	a2,112
ffffffffc0204778:	4581                	li	a1,0
    int *context_mem = (int*) kmalloc(sizeof(struct context)); // 分配context内存
ffffffffc020477a:	842a                	mv	s0,a0
    memset(context_mem, 0, sizeof(struct context)); // 初始化context内存为0
ffffffffc020477c:	354000ef          	jal	ra,ffffffffc0204ad0 <memset>
    int context_init_flag = memcmp(&(idleproc->context), context_mem, sizeof(struct context)); // 比较context内存
ffffffffc0204780:	00093503          	ld	a0,0(s2)
ffffffffc0204784:	85a2                	mv	a1,s0
ffffffffc0204786:	07000613          	li	a2,112
ffffffffc020478a:	03050513          	addi	a0,a0,48
ffffffffc020478e:	36c000ef          	jal	ra,ffffffffc0204afa <memcmp>
ffffffffc0204792:	89aa                	mv	s3,a0

    int *proc_name_mem = (int*) kmalloc(PROC_NAME_LEN); // 分配proc_name内存
ffffffffc0204794:	453d                	li	a0,15
ffffffffc0204796:	8e7fe0ef          	jal	ra,ffffffffc020307c <kmalloc>
    memset(proc_name_mem, 0, PROC_NAME_LEN); // 初始化proc_name内存为0
ffffffffc020479a:	463d                	li	a2,15
ffffffffc020479c:	4581                	li	a1,0
    int *proc_name_mem = (int*) kmalloc(PROC_NAME_LEN); // 分配proc_name内存
ffffffffc020479e:	842a                	mv	s0,a0
    memset(proc_name_mem, 0, PROC_NAME_LEN); // 初始化proc_name内存为0
ffffffffc02047a0:	330000ef          	jal	ra,ffffffffc0204ad0 <memset>
    int proc_name_flag = memcmp(&(idleproc->name), proc_name_mem, PROC_NAME_LEN); // 比较proc_name内存
ffffffffc02047a4:	00093503          	ld	a0,0(s2)
ffffffffc02047a8:	463d                	li	a2,15
ffffffffc02047aa:	85a2                	mv	a1,s0
ffffffffc02047ac:	0b450513          	addi	a0,a0,180
ffffffffc02047b0:	34a000ef          	jal	ra,ffffffffc0204afa <memcmp>

    if(idleproc->cr3 == boot_cr3 && idleproc->tf == NULL && !context_init_flag
ffffffffc02047b4:	00093783          	ld	a5,0(s2)
ffffffffc02047b8:	00012717          	auipc	a4,0x12
ffffffffc02047bc:	d9873703          	ld	a4,-616(a4) # ffffffffc0216550 <boot_cr3>
ffffffffc02047c0:	77d4                	ld	a3,168(a5)
ffffffffc02047c2:	0ee68463          	beq	a3,a4,ffffffffc02048aa <proc_init+0x186>
        cprintf("alloc_proc() correct!\n"); // 打印alloc_proc正确信息

    }
    
    idleproc->pid = 0; // 设置idleproc的PID为0
    idleproc->state = PROC_RUNNABLE; // 设置idleproc的状态为可运行
ffffffffc02047c6:	4709                	li	a4,2
ffffffffc02047c8:	e398                	sd	a4,0(a5)
    idleproc->kstack = (uintptr_t)bootstack; // 设置idleproc的内核栈地址
ffffffffc02047ca:	00004717          	auipc	a4,0x4
ffffffffc02047ce:	83670713          	addi	a4,a4,-1994 # ffffffffc0208000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name)); // 清空进程名
ffffffffc02047d2:	0b478413          	addi	s0,a5,180
    idleproc->kstack = (uintptr_t)bootstack; // 设置idleproc的内核栈地址
ffffffffc02047d6:	eb98                	sd	a4,16(a5)
    idleproc->need_resched = 1; // 设置idleproc需要重新调度
ffffffffc02047d8:	4705                	li	a4,1
ffffffffc02047da:	cf98                	sw	a4,24(a5)
    memset(proc->name, 0, sizeof(proc->name)); // 清空进程名
ffffffffc02047dc:	4641                	li	a2,16
ffffffffc02047de:	4581                	li	a1,0
ffffffffc02047e0:	8522                	mv	a0,s0
ffffffffc02047e2:	2ee000ef          	jal	ra,ffffffffc0204ad0 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN); // 复制新的进程名
ffffffffc02047e6:	463d                	li	a2,15
ffffffffc02047e8:	00002597          	auipc	a1,0x2
ffffffffc02047ec:	4f858593          	addi	a1,a1,1272 # ffffffffc0206ce0 <default_pmm_manager+0x160>
ffffffffc02047f0:	8522                	mv	a0,s0
ffffffffc02047f2:	2f0000ef          	jal	ra,ffffffffc0204ae2 <memcpy>
    set_proc_name(idleproc, "idle"); // 设置idleproc的名称为idle
    nr_process ++; // 增加进程数量
ffffffffc02047f6:	00012717          	auipc	a4,0x12
ffffffffc02047fa:	dd270713          	addi	a4,a4,-558 # ffffffffc02165c8 <nr_process>
ffffffffc02047fe:	431c                	lw	a5,0(a4)

    current = idleproc; // 设置当前进程为idleproc
ffffffffc0204800:	00093683          	ld	a3,0(s2)

    int pid = kernel_thread(init_main, "Hello world!!", 0); // 创建init_main内核线程
ffffffffc0204804:	4601                	li	a2,0
    nr_process ++; // 增加进程数量
ffffffffc0204806:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, "Hello world!!", 0); // 创建init_main内核线程
ffffffffc0204808:	00002597          	auipc	a1,0x2
ffffffffc020480c:	4e058593          	addi	a1,a1,1248 # ffffffffc0206ce8 <default_pmm_manager+0x168>
ffffffffc0204810:	00000517          	auipc	a0,0x0
ffffffffc0204814:	ae850513          	addi	a0,a0,-1304 # ffffffffc02042f8 <init_main>
    nr_process ++; // 增加进程数量
ffffffffc0204818:	c31c                	sw	a5,0(a4)
    current = idleproc; // 设置当前进程为idleproc
ffffffffc020481a:	00012797          	auipc	a5,0x12
ffffffffc020481e:	d8d7bb23          	sd	a3,-618(a5) # ffffffffc02165b0 <current>
    int pid = kernel_thread(init_main, "Hello world!!", 0); // 创建init_main内核线程
ffffffffc0204822:	e97ff0ef          	jal	ra,ffffffffc02046b8 <kernel_thread>
ffffffffc0204826:	842a                	mv	s0,a0
    if (pid <= 0) { // 创建失败
ffffffffc0204828:	0ea05963          	blez	a0,ffffffffc020491a <proc_init+0x1f6>
    if (0 < pid && pid < MAX_PID) { // 如果PID在有效范围内
ffffffffc020482c:	6789                	lui	a5,0x2
ffffffffc020482e:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204832:	17f9                	addi	a5,a5,-2
ffffffffc0204834:	2501                	sext.w	a0,a0
ffffffffc0204836:	02e7e363          	bltu	a5,a4,ffffffffc020485c <proc_init+0x138>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list; // 获取哈希列表
ffffffffc020483a:	45a9                	li	a1,10
ffffffffc020483c:	6d0000ef          	jal	ra,ffffffffc0204f0c <hash32>
ffffffffc0204840:	02051793          	slli	a5,a0,0x20
ffffffffc0204844:	01c7d693          	srli	a3,a5,0x1c
ffffffffc0204848:	96a6                	add	a3,a3,s1
ffffffffc020484a:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list) { // 遍历哈希列表
ffffffffc020484c:	a029                	j	ffffffffc0204856 <proc_init+0x132>
            if (proc->pid == pid) { // 如果进程PID匹配
ffffffffc020484e:	f2c7a703          	lw	a4,-212(a5) # 1f2c <kern_entry-0xffffffffc01fe0d4>
ffffffffc0204852:	0a870563          	beq	a4,s0,ffffffffc02048fc <proc_init+0x1d8>
    return listelm->next; // 返回下一个节点
ffffffffc0204856:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list) { // 遍历哈希列表
ffffffffc0204858:	fef69be3          	bne	a3,a5,ffffffffc020484e <proc_init+0x12a>
    return NULL; // 未找到匹配的进程，返回NULL
ffffffffc020485c:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name)); // 清空进程名
ffffffffc020485e:	0b478493          	addi	s1,a5,180
ffffffffc0204862:	4641                	li	a2,16
ffffffffc0204864:	4581                	li	a1,0
        panic("create init_main failed.\n"); // 调用panic函数，打印错误信息
    }

    initproc = find_proc(pid); // 查找initproc
ffffffffc0204866:	00012417          	auipc	s0,0x12
ffffffffc020486a:	d5a40413          	addi	s0,s0,-678 # ffffffffc02165c0 <initproc>
    memset(proc->name, 0, sizeof(proc->name)); // 清空进程名
ffffffffc020486e:	8526                	mv	a0,s1
    initproc = find_proc(pid); // 查找initproc
ffffffffc0204870:	e01c                	sd	a5,0(s0)
    memset(proc->name, 0, sizeof(proc->name)); // 清空进程名
ffffffffc0204872:	25e000ef          	jal	ra,ffffffffc0204ad0 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN); // 复制新的进程名
ffffffffc0204876:	463d                	li	a2,15
ffffffffc0204878:	00002597          	auipc	a1,0x2
ffffffffc020487c:	4a058593          	addi	a1,a1,1184 # ffffffffc0206d18 <default_pmm_manager+0x198>
ffffffffc0204880:	8526                	mv	a0,s1
ffffffffc0204882:	260000ef          	jal	ra,ffffffffc0204ae2 <memcpy>
    set_proc_name(initproc, "init"); // 设置initproc的名称为init

    assert(idleproc != NULL && idleproc->pid == 0); // 断言idleproc不为空且PID为0
ffffffffc0204886:	00093783          	ld	a5,0(s2)
ffffffffc020488a:	c7e1                	beqz	a5,ffffffffc0204952 <proc_init+0x22e>
ffffffffc020488c:	43dc                	lw	a5,4(a5)
ffffffffc020488e:	e3f1                	bnez	a5,ffffffffc0204952 <proc_init+0x22e>
    assert(initproc != NULL && initproc->pid == 1); // 断言initproc不为空且PID为1
ffffffffc0204890:	601c                	ld	a5,0(s0)
ffffffffc0204892:	c3c5                	beqz	a5,ffffffffc0204932 <proc_init+0x20e>
ffffffffc0204894:	43d8                	lw	a4,4(a5)
ffffffffc0204896:	4785                	li	a5,1
ffffffffc0204898:	08f71d63          	bne	a4,a5,ffffffffc0204932 <proc_init+0x20e>
}
ffffffffc020489c:	70a2                	ld	ra,40(sp)
ffffffffc020489e:	7402                	ld	s0,32(sp)
ffffffffc02048a0:	64e2                	ld	s1,24(sp)
ffffffffc02048a2:	6942                	ld	s2,16(sp)
ffffffffc02048a4:	69a2                	ld	s3,8(sp)
ffffffffc02048a6:	6145                	addi	sp,sp,48
ffffffffc02048a8:	8082                	ret
    if(idleproc->cr3 == boot_cr3 && idleproc->tf == NULL && !context_init_flag
ffffffffc02048aa:	73d8                	ld	a4,160(a5)
ffffffffc02048ac:	ff09                	bnez	a4,ffffffffc02047c6 <proc_init+0xa2>
ffffffffc02048ae:	f0099ce3          	bnez	s3,ffffffffc02047c6 <proc_init+0xa2>
        && idleproc->state == PROC_UNINIT && idleproc->pid == -1 && idleproc->runs == 0
ffffffffc02048b2:	6394                	ld	a3,0(a5)
ffffffffc02048b4:	577d                	li	a4,-1
ffffffffc02048b6:	1702                	slli	a4,a4,0x20
ffffffffc02048b8:	f0e697e3          	bne	a3,a4,ffffffffc02047c6 <proc_init+0xa2>
ffffffffc02048bc:	4798                	lw	a4,8(a5)
ffffffffc02048be:	f00714e3          	bnez	a4,ffffffffc02047c6 <proc_init+0xa2>
        && idleproc->kstack == 0 && idleproc->need_resched == 0 && idleproc->parent == NULL
ffffffffc02048c2:	6b98                	ld	a4,16(a5)
ffffffffc02048c4:	f00711e3          	bnez	a4,ffffffffc02047c6 <proc_init+0xa2>
ffffffffc02048c8:	4f98                	lw	a4,24(a5)
ffffffffc02048ca:	2701                	sext.w	a4,a4
ffffffffc02048cc:	ee071de3          	bnez	a4,ffffffffc02047c6 <proc_init+0xa2>
ffffffffc02048d0:	7398                	ld	a4,32(a5)
ffffffffc02048d2:	ee071ae3          	bnez	a4,ffffffffc02047c6 <proc_init+0xa2>
        && idleproc->mm == NULL && idleproc->flags == 0 && !proc_name_flag
ffffffffc02048d6:	7798                	ld	a4,40(a5)
ffffffffc02048d8:	ee0717e3          	bnez	a4,ffffffffc02047c6 <proc_init+0xa2>
ffffffffc02048dc:	0b07a703          	lw	a4,176(a5)
ffffffffc02048e0:	8d59                	or	a0,a0,a4
ffffffffc02048e2:	0005071b          	sext.w	a4,a0
ffffffffc02048e6:	ee0710e3          	bnez	a4,ffffffffc02047c6 <proc_init+0xa2>
        cprintf("alloc_proc() correct!\n"); // 打印alloc_proc正确信息
ffffffffc02048ea:	00002517          	auipc	a0,0x2
ffffffffc02048ee:	3de50513          	addi	a0,a0,990 # ffffffffc0206cc8 <default_pmm_manager+0x148>
ffffffffc02048f2:	fdafb0ef          	jal	ra,ffffffffc02000cc <cprintf>
    idleproc->pid = 0; // 设置idleproc的PID为0
ffffffffc02048f6:	00093783          	ld	a5,0(s2)
ffffffffc02048fa:	b5f1                	j	ffffffffc02047c6 <proc_init+0xa2>
            struct proc_struct *proc = le2proc(le, hash_link); // 获取进程结构
ffffffffc02048fc:	f2878793          	addi	a5,a5,-216
ffffffffc0204900:	bfb9                	j	ffffffffc020485e <proc_init+0x13a>
        panic("cannot alloc idleproc.\n"); // 调用panic函数，打印错误信息
ffffffffc0204902:	00002617          	auipc	a2,0x2
ffffffffc0204906:	3ae60613          	addi	a2,a2,942 # ffffffffc0206cb0 <default_pmm_manager+0x130>
ffffffffc020490a:	1ed00593          	li	a1,493
ffffffffc020490e:	00002517          	auipc	a0,0x2
ffffffffc0204912:	37250513          	addi	a0,a0,882 # ffffffffc0206c80 <default_pmm_manager+0x100>
ffffffffc0204916:	8b3fb0ef          	jal	ra,ffffffffc02001c8 <__panic>
        panic("create init_main failed.\n"); // 调用panic函数，打印错误信息
ffffffffc020491a:	00002617          	auipc	a2,0x2
ffffffffc020491e:	3de60613          	addi	a2,a2,990 # ffffffffc0206cf8 <default_pmm_manager+0x178>
ffffffffc0204922:	20d00593          	li	a1,525
ffffffffc0204926:	00002517          	auipc	a0,0x2
ffffffffc020492a:	35a50513          	addi	a0,a0,858 # ffffffffc0206c80 <default_pmm_manager+0x100>
ffffffffc020492e:	89bfb0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(initproc != NULL && initproc->pid == 1); // 断言initproc不为空且PID为1
ffffffffc0204932:	00002697          	auipc	a3,0x2
ffffffffc0204936:	41668693          	addi	a3,a3,1046 # ffffffffc0206d48 <default_pmm_manager+0x1c8>
ffffffffc020493a:	00001617          	auipc	a2,0x1
ffffffffc020493e:	0e660613          	addi	a2,a2,230 # ffffffffc0205a20 <commands+0x870>
ffffffffc0204942:	21400593          	li	a1,532
ffffffffc0204946:	00002517          	auipc	a0,0x2
ffffffffc020494a:	33a50513          	addi	a0,a0,826 # ffffffffc0206c80 <default_pmm_manager+0x100>
ffffffffc020494e:	87bfb0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(idleproc != NULL && idleproc->pid == 0); // 断言idleproc不为空且PID为0
ffffffffc0204952:	00002697          	auipc	a3,0x2
ffffffffc0204956:	3ce68693          	addi	a3,a3,974 # ffffffffc0206d20 <default_pmm_manager+0x1a0>
ffffffffc020495a:	00001617          	auipc	a2,0x1
ffffffffc020495e:	0c660613          	addi	a2,a2,198 # ffffffffc0205a20 <commands+0x870>
ffffffffc0204962:	21300593          	li	a1,531
ffffffffc0204966:	00002517          	auipc	a0,0x2
ffffffffc020496a:	31a50513          	addi	a0,a0,794 # ffffffffc0206c80 <default_pmm_manager+0x100>
ffffffffc020496e:	85bfb0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc0204972 <cpu_idle>:
/*
 * cpu_idle - 在 kern_init 结束时，第一内核线程 idleproc 将执行此函数。
 * 进入空闲循环，等待需要调度的进程。
 */
void
cpu_idle(void) {
ffffffffc0204972:	1141                	addi	sp,sp,-16
ffffffffc0204974:	e022                	sd	s0,0(sp)
ffffffffc0204976:	e406                	sd	ra,8(sp)
ffffffffc0204978:	00012417          	auipc	s0,0x12
ffffffffc020497c:	c3840413          	addi	s0,s0,-968 # ffffffffc02165b0 <current>
    while (1) { // 无限循环
        if (current->need_resched) { // 如果当前进程需要重新调度
ffffffffc0204980:	6018                	ld	a4,0(s0)
ffffffffc0204982:	4f1c                	lw	a5,24(a4)
ffffffffc0204984:	2781                	sext.w	a5,a5
ffffffffc0204986:	dff5                	beqz	a5,ffffffffc0204982 <cpu_idle+0x10>
            schedule(); // 调用调度函数
ffffffffc0204988:	038000ef          	jal	ra,ffffffffc02049c0 <schedule>
ffffffffc020498c:	bfd5                	j	ffffffffc0204980 <cpu_idle+0xe>

ffffffffc020498e <wakeup_proc>:
#include <sched.h> // 包含调度操作的头文件
#include <assert.h> // 包含断言操作的头文件

void
wakeup_proc(struct proc_struct *proc) { // 唤醒进程函数
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE); // 确保进程状态不是僵尸态或可运行态
ffffffffc020498e:	411c                	lw	a5,0(a0)
ffffffffc0204990:	4705                	li	a4,1
ffffffffc0204992:	37f9                	addiw	a5,a5,-2
ffffffffc0204994:	00f77563          	bgeu	a4,a5,ffffffffc020499e <wakeup_proc+0x10>
    proc->state = PROC_RUNNABLE; // 将进程状态设置为可运行态
ffffffffc0204998:	4789                	li	a5,2
ffffffffc020499a:	c11c                	sw	a5,0(a0)
ffffffffc020499c:	8082                	ret
wakeup_proc(struct proc_struct *proc) { // 唤醒进程函数
ffffffffc020499e:	1141                	addi	sp,sp,-16
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE); // 确保进程状态不是僵尸态或可运行态
ffffffffc02049a0:	00002697          	auipc	a3,0x2
ffffffffc02049a4:	3d068693          	addi	a3,a3,976 # ffffffffc0206d70 <default_pmm_manager+0x1f0>
ffffffffc02049a8:	00001617          	auipc	a2,0x1
ffffffffc02049ac:	07860613          	addi	a2,a2,120 # ffffffffc0205a20 <commands+0x870>
ffffffffc02049b0:	45b1                	li	a1,12
ffffffffc02049b2:	00002517          	auipc	a0,0x2
ffffffffc02049b6:	3fe50513          	addi	a0,a0,1022 # ffffffffc0206db0 <default_pmm_manager+0x230>
wakeup_proc(struct proc_struct *proc) { // 唤醒进程函数
ffffffffc02049ba:	e406                	sd	ra,8(sp)
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE); // 确保进程状态不是僵尸态或可运行态
ffffffffc02049bc:	80dfb0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc02049c0 <schedule>:
}

void
schedule(void) { // 调度函数
ffffffffc02049c0:	1141                	addi	sp,sp,-16
ffffffffc02049c2:	e406                	sd	ra,8(sp)
ffffffffc02049c4:	e022                	sd	s0,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE) { // 如果当前中断使能
ffffffffc02049c6:	100027f3          	csrr	a5,sstatus
ffffffffc02049ca:	8b89                	andi	a5,a5,2
ffffffffc02049cc:	4401                	li	s0,0
ffffffffc02049ce:	efbd                	bnez	a5,ffffffffc0204a4c <schedule+0x8c>
    bool intr_flag; // 定义中断标志
    list_entry_t *le, *last; // 定义链表指针
    struct proc_struct *next = NULL; // 定义下一个要运行的进程
    local_intr_save(intr_flag); // 保存当前中断状态并禁用中断
    {
        current->need_resched = 0; // 清除当前进程的需要调度标志
ffffffffc02049d0:	00012897          	auipc	a7,0x12
ffffffffc02049d4:	be08b883          	ld	a7,-1056(a7) # ffffffffc02165b0 <current>
ffffffffc02049d8:	0008ac23          	sw	zero,24(a7)
        last = (current == idleproc) ? &proc_list : &(current->list_link); // 获取当前进程的链表位置
ffffffffc02049dc:	00012517          	auipc	a0,0x12
ffffffffc02049e0:	bdc53503          	ld	a0,-1060(a0) # ffffffffc02165b8 <idleproc>
ffffffffc02049e4:	04a88e63          	beq	a7,a0,ffffffffc0204a40 <schedule+0x80>
ffffffffc02049e8:	0c888693          	addi	a3,a7,200
ffffffffc02049ec:	00012617          	auipc	a2,0x12
ffffffffc02049f0:	b3c60613          	addi	a2,a2,-1220 # ffffffffc0216528 <proc_list>
        le = last; // 初始化链表指针
ffffffffc02049f4:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL; // 定义下一个要运行的进程
ffffffffc02049f6:	4581                	li	a1,0
        do {
            if ((le = list_next(le)) != &proc_list) { // 遍历进程链表
                next = le2proc(le, list_link); // 获取下一个进程
                if (next->state == PROC_RUNNABLE) { // 如果进程状态为可运行态
ffffffffc02049f8:	4809                	li	a6,2
ffffffffc02049fa:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list) { // 遍历进程链表
ffffffffc02049fc:	00c78863          	beq	a5,a2,ffffffffc0204a0c <schedule+0x4c>
                if (next->state == PROC_RUNNABLE) { // 如果进程状态为可运行态
ffffffffc0204a00:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link); // 获取下一个进程
ffffffffc0204a04:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE) { // 如果进程状态为可运行态
ffffffffc0204a08:	03070163          	beq	a4,a6,ffffffffc0204a2a <schedule+0x6a>
                    break; // 退出循环
                }
            }
        } while (le != last); // 如果遍历完一圈则退出循环
ffffffffc0204a0c:	fef697e3          	bne	a3,a5,ffffffffc02049fa <schedule+0x3a>
        if (next == NULL || next->state != PROC_RUNNABLE) { // 如果没有找到可运行的进程
ffffffffc0204a10:	ed89                	bnez	a1,ffffffffc0204a2a <schedule+0x6a>
            next = idleproc; // 设置为空闲进程
        }
        next->runs ++; // 增加进程的运行次数
ffffffffc0204a12:	451c                	lw	a5,8(a0)
ffffffffc0204a14:	2785                	addiw	a5,a5,1
ffffffffc0204a16:	c51c                	sw	a5,8(a0)
        if (next != current) { // 如果下一个进程不是当前进程
ffffffffc0204a18:	00a88463          	beq	a7,a0,ffffffffc0204a20 <schedule+0x60>
            proc_run(next); // 切换到下一个进程
ffffffffc0204a1c:	94fff0ef          	jal	ra,ffffffffc020436a <proc_run>
    if (flag) { // 如果flag为1
ffffffffc0204a20:	e819                	bnez	s0,ffffffffc0204a36 <schedule+0x76>
        }
    }
    local_intr_restore(intr_flag); // 恢复之前保存的中断状态
}
ffffffffc0204a22:	60a2                	ld	ra,8(sp)
ffffffffc0204a24:	6402                	ld	s0,0(sp)
ffffffffc0204a26:	0141                	addi	sp,sp,16
ffffffffc0204a28:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE) { // 如果没有找到可运行的进程
ffffffffc0204a2a:	4198                	lw	a4,0(a1)
ffffffffc0204a2c:	4789                	li	a5,2
ffffffffc0204a2e:	fef712e3          	bne	a4,a5,ffffffffc0204a12 <schedule+0x52>
ffffffffc0204a32:	852e                	mv	a0,a1
ffffffffc0204a34:	bff9                	j	ffffffffc0204a12 <schedule+0x52>
}
ffffffffc0204a36:	6402                	ld	s0,0(sp)
ffffffffc0204a38:	60a2                	ld	ra,8(sp)
ffffffffc0204a3a:	0141                	addi	sp,sp,16
        intr_enable(); // 使能中断
ffffffffc0204a3c:	b83fb06f          	j	ffffffffc02005be <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link); // 获取当前进程的链表位置
ffffffffc0204a40:	00012617          	auipc	a2,0x12
ffffffffc0204a44:	ae860613          	addi	a2,a2,-1304 # ffffffffc0216528 <proc_list>
ffffffffc0204a48:	86b2                	mv	a3,a2
ffffffffc0204a4a:	b76d                	j	ffffffffc02049f4 <schedule+0x34>
        intr_disable(); // 禁用中断
ffffffffc0204a4c:	b79fb0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
        return 1; // 返回1表示中断之前是使能的
ffffffffc0204a50:	4405                	li	s0,1
ffffffffc0204a52:	bfbd                	j	ffffffffc02049d0 <schedule+0x10>

ffffffffc0204a54 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0204a54:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0204a58:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0204a5a:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0204a5c:	cb81                	beqz	a5,ffffffffc0204a6c <strlen+0x18>
        cnt ++;
ffffffffc0204a5e:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0204a60:	00a707b3          	add	a5,a4,a0
ffffffffc0204a64:	0007c783          	lbu	a5,0(a5)
ffffffffc0204a68:	fbfd                	bnez	a5,ffffffffc0204a5e <strlen+0xa>
ffffffffc0204a6a:	8082                	ret
    }
    return cnt;
}
ffffffffc0204a6c:	8082                	ret

ffffffffc0204a6e <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0204a6e:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0204a70:	e589                	bnez	a1,ffffffffc0204a7a <strnlen+0xc>
ffffffffc0204a72:	a811                	j	ffffffffc0204a86 <strnlen+0x18>
        cnt ++;
ffffffffc0204a74:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0204a76:	00f58863          	beq	a1,a5,ffffffffc0204a86 <strnlen+0x18>
ffffffffc0204a7a:	00f50733          	add	a4,a0,a5
ffffffffc0204a7e:	00074703          	lbu	a4,0(a4)
ffffffffc0204a82:	fb6d                	bnez	a4,ffffffffc0204a74 <strnlen+0x6>
ffffffffc0204a84:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0204a86:	852e                	mv	a0,a1
ffffffffc0204a88:	8082                	ret

ffffffffc0204a8a <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc0204a8a:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc0204a8c:	0005c703          	lbu	a4,0(a1)
ffffffffc0204a90:	0785                	addi	a5,a5,1
ffffffffc0204a92:	0585                	addi	a1,a1,1
ffffffffc0204a94:	fee78fa3          	sb	a4,-1(a5)
ffffffffc0204a98:	fb75                	bnez	a4,ffffffffc0204a8c <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc0204a9a:	8082                	ret

ffffffffc0204a9c <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0204a9c:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0204aa0:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0204aa4:	cb89                	beqz	a5,ffffffffc0204ab6 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0204aa6:	0505                	addi	a0,a0,1
ffffffffc0204aa8:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0204aaa:	fee789e3          	beq	a5,a4,ffffffffc0204a9c <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0204aae:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0204ab2:	9d19                	subw	a0,a0,a4
ffffffffc0204ab4:	8082                	ret
ffffffffc0204ab6:	4501                	li	a0,0
ffffffffc0204ab8:	bfed                	j	ffffffffc0204ab2 <strcmp+0x16>

ffffffffc0204aba <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0204aba:	00054783          	lbu	a5,0(a0)
ffffffffc0204abe:	c799                	beqz	a5,ffffffffc0204acc <strchr+0x12>
        if (*s == c) {
ffffffffc0204ac0:	00f58763          	beq	a1,a5,ffffffffc0204ace <strchr+0x14>
    while (*s != '\0') {
ffffffffc0204ac4:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0204ac8:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0204aca:	fbfd                	bnez	a5,ffffffffc0204ac0 <strchr+0x6>
    }
    return NULL;
ffffffffc0204acc:	4501                	li	a0,0
}
ffffffffc0204ace:	8082                	ret

ffffffffc0204ad0 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0204ad0:	ca01                	beqz	a2,ffffffffc0204ae0 <memset+0x10>
ffffffffc0204ad2:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0204ad4:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0204ad6:	0785                	addi	a5,a5,1
ffffffffc0204ad8:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0204adc:	fec79de3          	bne	a5,a2,ffffffffc0204ad6 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0204ae0:	8082                	ret

ffffffffc0204ae2 <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc0204ae2:	ca19                	beqz	a2,ffffffffc0204af8 <memcpy+0x16>
ffffffffc0204ae4:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0204ae6:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0204ae8:	0005c703          	lbu	a4,0(a1)
ffffffffc0204aec:	0585                	addi	a1,a1,1
ffffffffc0204aee:	0785                	addi	a5,a5,1
ffffffffc0204af0:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc0204af4:	fec59ae3          	bne	a1,a2,ffffffffc0204ae8 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc0204af8:	8082                	ret

ffffffffc0204afa <memcmp>:
 * */
int
memcmp(const void *v1, const void *v2, size_t n) {
    const char *s1 = (const char *)v1;
    const char *s2 = (const char *)v2;
    while (n -- > 0) {
ffffffffc0204afa:	c205                	beqz	a2,ffffffffc0204b1a <memcmp+0x20>
ffffffffc0204afc:	962e                	add	a2,a2,a1
ffffffffc0204afe:	a019                	j	ffffffffc0204b04 <memcmp+0xa>
ffffffffc0204b00:	00c58d63          	beq	a1,a2,ffffffffc0204b1a <memcmp+0x20>
        if (*s1 != *s2) {
ffffffffc0204b04:	00054783          	lbu	a5,0(a0)
ffffffffc0204b08:	0005c703          	lbu	a4,0(a1)
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
        }
        s1 ++, s2 ++;
ffffffffc0204b0c:	0505                	addi	a0,a0,1
ffffffffc0204b0e:	0585                	addi	a1,a1,1
        if (*s1 != *s2) {
ffffffffc0204b10:	fee788e3          	beq	a5,a4,ffffffffc0204b00 <memcmp+0x6>
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0204b14:	40e7853b          	subw	a0,a5,a4
ffffffffc0204b18:	8082                	ret
    }
    return 0;
ffffffffc0204b1a:	4501                	li	a0,0
}
ffffffffc0204b1c:	8082                	ret

ffffffffc0204b1e <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0204b1e:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0204b22:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0204b24:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0204b28:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0204b2a:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0204b2e:	f022                	sd	s0,32(sp)
ffffffffc0204b30:	ec26                	sd	s1,24(sp)
ffffffffc0204b32:	e84a                	sd	s2,16(sp)
ffffffffc0204b34:	f406                	sd	ra,40(sp)
ffffffffc0204b36:	e44e                	sd	s3,8(sp)
ffffffffc0204b38:	84aa                	mv	s1,a0
ffffffffc0204b3a:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0204b3c:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0204b40:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0204b42:	03067e63          	bgeu	a2,a6,ffffffffc0204b7e <printnum+0x60>
ffffffffc0204b46:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0204b48:	00805763          	blez	s0,ffffffffc0204b56 <printnum+0x38>
ffffffffc0204b4c:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0204b4e:	85ca                	mv	a1,s2
ffffffffc0204b50:	854e                	mv	a0,s3
ffffffffc0204b52:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0204b54:	fc65                	bnez	s0,ffffffffc0204b4c <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0204b56:	1a02                	slli	s4,s4,0x20
ffffffffc0204b58:	00002797          	auipc	a5,0x2
ffffffffc0204b5c:	27078793          	addi	a5,a5,624 # ffffffffc0206dc8 <default_pmm_manager+0x248>
ffffffffc0204b60:	020a5a13          	srli	s4,s4,0x20
ffffffffc0204b64:	9a3e                	add	s4,s4,a5
}
ffffffffc0204b66:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0204b68:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0204b6c:	70a2                	ld	ra,40(sp)
ffffffffc0204b6e:	69a2                	ld	s3,8(sp)
ffffffffc0204b70:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0204b72:	85ca                	mv	a1,s2
ffffffffc0204b74:	87a6                	mv	a5,s1
}
ffffffffc0204b76:	6942                	ld	s2,16(sp)
ffffffffc0204b78:	64e2                	ld	s1,24(sp)
ffffffffc0204b7a:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0204b7c:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0204b7e:	03065633          	divu	a2,a2,a6
ffffffffc0204b82:	8722                	mv	a4,s0
ffffffffc0204b84:	f9bff0ef          	jal	ra,ffffffffc0204b1e <printnum>
ffffffffc0204b88:	b7f9                	j	ffffffffc0204b56 <printnum+0x38>

ffffffffc0204b8a <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0204b8a:	7119                	addi	sp,sp,-128
ffffffffc0204b8c:	f4a6                	sd	s1,104(sp)
ffffffffc0204b8e:	f0ca                	sd	s2,96(sp)
ffffffffc0204b90:	ecce                	sd	s3,88(sp)
ffffffffc0204b92:	e8d2                	sd	s4,80(sp)
ffffffffc0204b94:	e4d6                	sd	s5,72(sp)
ffffffffc0204b96:	e0da                	sd	s6,64(sp)
ffffffffc0204b98:	fc5e                	sd	s7,56(sp)
ffffffffc0204b9a:	f06a                	sd	s10,32(sp)
ffffffffc0204b9c:	fc86                	sd	ra,120(sp)
ffffffffc0204b9e:	f8a2                	sd	s0,112(sp)
ffffffffc0204ba0:	f862                	sd	s8,48(sp)
ffffffffc0204ba2:	f466                	sd	s9,40(sp)
ffffffffc0204ba4:	ec6e                	sd	s11,24(sp)
ffffffffc0204ba6:	892a                	mv	s2,a0
ffffffffc0204ba8:	84ae                	mv	s1,a1
ffffffffc0204baa:	8d32                	mv	s10,a2
ffffffffc0204bac:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0204bae:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0204bb2:	5b7d                	li	s6,-1
ffffffffc0204bb4:	00002a97          	auipc	s5,0x2
ffffffffc0204bb8:	240a8a93          	addi	s5,s5,576 # ffffffffc0206df4 <default_pmm_manager+0x274>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0204bbc:	00002b97          	auipc	s7,0x2
ffffffffc0204bc0:	414b8b93          	addi	s7,s7,1044 # ffffffffc0206fd0 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0204bc4:	000d4503          	lbu	a0,0(s10)
ffffffffc0204bc8:	001d0413          	addi	s0,s10,1
ffffffffc0204bcc:	01350a63          	beq	a0,s3,ffffffffc0204be0 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0204bd0:	c121                	beqz	a0,ffffffffc0204c10 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0204bd2:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0204bd4:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0204bd6:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0204bd8:	fff44503          	lbu	a0,-1(s0)
ffffffffc0204bdc:	ff351ae3          	bne	a0,s3,ffffffffc0204bd0 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204be0:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0204be4:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0204be8:	4c81                	li	s9,0
ffffffffc0204bea:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0204bec:	5c7d                	li	s8,-1
ffffffffc0204bee:	5dfd                	li	s11,-1
ffffffffc0204bf0:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0204bf4:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204bf6:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0204bfa:	0ff5f593          	zext.b	a1,a1
ffffffffc0204bfe:	00140d13          	addi	s10,s0,1
ffffffffc0204c02:	04b56263          	bltu	a0,a1,ffffffffc0204c46 <vprintfmt+0xbc>
ffffffffc0204c06:	058a                	slli	a1,a1,0x2
ffffffffc0204c08:	95d6                	add	a1,a1,s5
ffffffffc0204c0a:	4194                	lw	a3,0(a1)
ffffffffc0204c0c:	96d6                	add	a3,a3,s5
ffffffffc0204c0e:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0204c10:	70e6                	ld	ra,120(sp)
ffffffffc0204c12:	7446                	ld	s0,112(sp)
ffffffffc0204c14:	74a6                	ld	s1,104(sp)
ffffffffc0204c16:	7906                	ld	s2,96(sp)
ffffffffc0204c18:	69e6                	ld	s3,88(sp)
ffffffffc0204c1a:	6a46                	ld	s4,80(sp)
ffffffffc0204c1c:	6aa6                	ld	s5,72(sp)
ffffffffc0204c1e:	6b06                	ld	s6,64(sp)
ffffffffc0204c20:	7be2                	ld	s7,56(sp)
ffffffffc0204c22:	7c42                	ld	s8,48(sp)
ffffffffc0204c24:	7ca2                	ld	s9,40(sp)
ffffffffc0204c26:	7d02                	ld	s10,32(sp)
ffffffffc0204c28:	6de2                	ld	s11,24(sp)
ffffffffc0204c2a:	6109                	addi	sp,sp,128
ffffffffc0204c2c:	8082                	ret
            padc = '0';
ffffffffc0204c2e:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0204c30:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204c34:	846a                	mv	s0,s10
ffffffffc0204c36:	00140d13          	addi	s10,s0,1
ffffffffc0204c3a:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0204c3e:	0ff5f593          	zext.b	a1,a1
ffffffffc0204c42:	fcb572e3          	bgeu	a0,a1,ffffffffc0204c06 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0204c46:	85a6                	mv	a1,s1
ffffffffc0204c48:	02500513          	li	a0,37
ffffffffc0204c4c:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0204c4e:	fff44783          	lbu	a5,-1(s0)
ffffffffc0204c52:	8d22                	mv	s10,s0
ffffffffc0204c54:	f73788e3          	beq	a5,s3,ffffffffc0204bc4 <vprintfmt+0x3a>
ffffffffc0204c58:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0204c5c:	1d7d                	addi	s10,s10,-1
ffffffffc0204c5e:	ff379de3          	bne	a5,s3,ffffffffc0204c58 <vprintfmt+0xce>
ffffffffc0204c62:	b78d                	j	ffffffffc0204bc4 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0204c64:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0204c68:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204c6c:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0204c6e:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0204c72:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0204c76:	02d86463          	bltu	a6,a3,ffffffffc0204c9e <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0204c7a:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0204c7e:	002c169b          	slliw	a3,s8,0x2
ffffffffc0204c82:	0186873b          	addw	a4,a3,s8
ffffffffc0204c86:	0017171b          	slliw	a4,a4,0x1
ffffffffc0204c8a:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0204c8c:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0204c90:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0204c92:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0204c96:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0204c9a:	fed870e3          	bgeu	a6,a3,ffffffffc0204c7a <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0204c9e:	f40ddce3          	bgez	s11,ffffffffc0204bf6 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0204ca2:	8de2                	mv	s11,s8
ffffffffc0204ca4:	5c7d                	li	s8,-1
ffffffffc0204ca6:	bf81                	j	ffffffffc0204bf6 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0204ca8:	fffdc693          	not	a3,s11
ffffffffc0204cac:	96fd                	srai	a3,a3,0x3f
ffffffffc0204cae:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204cb2:	00144603          	lbu	a2,1(s0)
ffffffffc0204cb6:	2d81                	sext.w	s11,s11
ffffffffc0204cb8:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0204cba:	bf35                	j	ffffffffc0204bf6 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0204cbc:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204cc0:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0204cc4:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204cc6:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0204cc8:	bfd9                	j	ffffffffc0204c9e <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0204cca:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0204ccc:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0204cd0:	01174463          	blt	a4,a7,ffffffffc0204cd8 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0204cd4:	1a088e63          	beqz	a7,ffffffffc0204e90 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0204cd8:	000a3603          	ld	a2,0(s4)
ffffffffc0204cdc:	46c1                	li	a3,16
ffffffffc0204cde:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0204ce0:	2781                	sext.w	a5,a5
ffffffffc0204ce2:	876e                	mv	a4,s11
ffffffffc0204ce4:	85a6                	mv	a1,s1
ffffffffc0204ce6:	854a                	mv	a0,s2
ffffffffc0204ce8:	e37ff0ef          	jal	ra,ffffffffc0204b1e <printnum>
            break;
ffffffffc0204cec:	bde1                	j	ffffffffc0204bc4 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0204cee:	000a2503          	lw	a0,0(s4)
ffffffffc0204cf2:	85a6                	mv	a1,s1
ffffffffc0204cf4:	0a21                	addi	s4,s4,8
ffffffffc0204cf6:	9902                	jalr	s2
            break;
ffffffffc0204cf8:	b5f1                	j	ffffffffc0204bc4 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0204cfa:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0204cfc:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0204d00:	01174463          	blt	a4,a7,ffffffffc0204d08 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0204d04:	18088163          	beqz	a7,ffffffffc0204e86 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0204d08:	000a3603          	ld	a2,0(s4)
ffffffffc0204d0c:	46a9                	li	a3,10
ffffffffc0204d0e:	8a2e                	mv	s4,a1
ffffffffc0204d10:	bfc1                	j	ffffffffc0204ce0 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204d12:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0204d16:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204d18:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0204d1a:	bdf1                	j	ffffffffc0204bf6 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0204d1c:	85a6                	mv	a1,s1
ffffffffc0204d1e:	02500513          	li	a0,37
ffffffffc0204d22:	9902                	jalr	s2
            break;
ffffffffc0204d24:	b545                	j	ffffffffc0204bc4 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204d26:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0204d2a:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204d2c:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0204d2e:	b5e1                	j	ffffffffc0204bf6 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0204d30:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0204d32:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0204d36:	01174463          	blt	a4,a7,ffffffffc0204d3e <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0204d3a:	14088163          	beqz	a7,ffffffffc0204e7c <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0204d3e:	000a3603          	ld	a2,0(s4)
ffffffffc0204d42:	46a1                	li	a3,8
ffffffffc0204d44:	8a2e                	mv	s4,a1
ffffffffc0204d46:	bf69                	j	ffffffffc0204ce0 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0204d48:	03000513          	li	a0,48
ffffffffc0204d4c:	85a6                	mv	a1,s1
ffffffffc0204d4e:	e03e                	sd	a5,0(sp)
ffffffffc0204d50:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0204d52:	85a6                	mv	a1,s1
ffffffffc0204d54:	07800513          	li	a0,120
ffffffffc0204d58:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0204d5a:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0204d5c:	6782                	ld	a5,0(sp)
ffffffffc0204d5e:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0204d60:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0204d64:	bfb5                	j	ffffffffc0204ce0 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0204d66:	000a3403          	ld	s0,0(s4)
ffffffffc0204d6a:	008a0713          	addi	a4,s4,8
ffffffffc0204d6e:	e03a                	sd	a4,0(sp)
ffffffffc0204d70:	14040263          	beqz	s0,ffffffffc0204eb4 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0204d74:	0fb05763          	blez	s11,ffffffffc0204e62 <vprintfmt+0x2d8>
ffffffffc0204d78:	02d00693          	li	a3,45
ffffffffc0204d7c:	0cd79163          	bne	a5,a3,ffffffffc0204e3e <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204d80:	00044783          	lbu	a5,0(s0)
ffffffffc0204d84:	0007851b          	sext.w	a0,a5
ffffffffc0204d88:	cf85                	beqz	a5,ffffffffc0204dc0 <vprintfmt+0x236>
ffffffffc0204d8a:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0204d8e:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204d92:	000c4563          	bltz	s8,ffffffffc0204d9c <vprintfmt+0x212>
ffffffffc0204d96:	3c7d                	addiw	s8,s8,-1
ffffffffc0204d98:	036c0263          	beq	s8,s6,ffffffffc0204dbc <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0204d9c:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0204d9e:	0e0c8e63          	beqz	s9,ffffffffc0204e9a <vprintfmt+0x310>
ffffffffc0204da2:	3781                	addiw	a5,a5,-32
ffffffffc0204da4:	0ef47b63          	bgeu	s0,a5,ffffffffc0204e9a <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0204da8:	03f00513          	li	a0,63
ffffffffc0204dac:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204dae:	000a4783          	lbu	a5,0(s4)
ffffffffc0204db2:	3dfd                	addiw	s11,s11,-1
ffffffffc0204db4:	0a05                	addi	s4,s4,1
ffffffffc0204db6:	0007851b          	sext.w	a0,a5
ffffffffc0204dba:	ffe1                	bnez	a5,ffffffffc0204d92 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0204dbc:	01b05963          	blez	s11,ffffffffc0204dce <vprintfmt+0x244>
ffffffffc0204dc0:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0204dc2:	85a6                	mv	a1,s1
ffffffffc0204dc4:	02000513          	li	a0,32
ffffffffc0204dc8:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0204dca:	fe0d9be3          	bnez	s11,ffffffffc0204dc0 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0204dce:	6a02                	ld	s4,0(sp)
ffffffffc0204dd0:	bbd5                	j	ffffffffc0204bc4 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0204dd2:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0204dd4:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0204dd8:	01174463          	blt	a4,a7,ffffffffc0204de0 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0204ddc:	08088d63          	beqz	a7,ffffffffc0204e76 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0204de0:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0204de4:	0a044d63          	bltz	s0,ffffffffc0204e9e <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0204de8:	8622                	mv	a2,s0
ffffffffc0204dea:	8a66                	mv	s4,s9
ffffffffc0204dec:	46a9                	li	a3,10
ffffffffc0204dee:	bdcd                	j	ffffffffc0204ce0 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0204df0:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0204df4:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0204df6:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0204df8:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0204dfc:	8fb5                	xor	a5,a5,a3
ffffffffc0204dfe:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0204e02:	02d74163          	blt	a4,a3,ffffffffc0204e24 <vprintfmt+0x29a>
ffffffffc0204e06:	00369793          	slli	a5,a3,0x3
ffffffffc0204e0a:	97de                	add	a5,a5,s7
ffffffffc0204e0c:	639c                	ld	a5,0(a5)
ffffffffc0204e0e:	cb99                	beqz	a5,ffffffffc0204e24 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0204e10:	86be                	mv	a3,a5
ffffffffc0204e12:	00000617          	auipc	a2,0x0
ffffffffc0204e16:	13e60613          	addi	a2,a2,318 # ffffffffc0204f50 <etext+0x2e>
ffffffffc0204e1a:	85a6                	mv	a1,s1
ffffffffc0204e1c:	854a                	mv	a0,s2
ffffffffc0204e1e:	0ce000ef          	jal	ra,ffffffffc0204eec <printfmt>
ffffffffc0204e22:	b34d                	j	ffffffffc0204bc4 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0204e24:	00002617          	auipc	a2,0x2
ffffffffc0204e28:	fc460613          	addi	a2,a2,-60 # ffffffffc0206de8 <default_pmm_manager+0x268>
ffffffffc0204e2c:	85a6                	mv	a1,s1
ffffffffc0204e2e:	854a                	mv	a0,s2
ffffffffc0204e30:	0bc000ef          	jal	ra,ffffffffc0204eec <printfmt>
ffffffffc0204e34:	bb41                	j	ffffffffc0204bc4 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0204e36:	00002417          	auipc	s0,0x2
ffffffffc0204e3a:	faa40413          	addi	s0,s0,-86 # ffffffffc0206de0 <default_pmm_manager+0x260>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0204e3e:	85e2                	mv	a1,s8
ffffffffc0204e40:	8522                	mv	a0,s0
ffffffffc0204e42:	e43e                	sd	a5,8(sp)
ffffffffc0204e44:	c2bff0ef          	jal	ra,ffffffffc0204a6e <strnlen>
ffffffffc0204e48:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0204e4c:	01b05b63          	blez	s11,ffffffffc0204e62 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0204e50:	67a2                	ld	a5,8(sp)
ffffffffc0204e52:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0204e56:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0204e58:	85a6                	mv	a1,s1
ffffffffc0204e5a:	8552                	mv	a0,s4
ffffffffc0204e5c:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0204e5e:	fe0d9ce3          	bnez	s11,ffffffffc0204e56 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204e62:	00044783          	lbu	a5,0(s0)
ffffffffc0204e66:	00140a13          	addi	s4,s0,1
ffffffffc0204e6a:	0007851b          	sext.w	a0,a5
ffffffffc0204e6e:	d3a5                	beqz	a5,ffffffffc0204dce <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0204e70:	05e00413          	li	s0,94
ffffffffc0204e74:	bf39                	j	ffffffffc0204d92 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0204e76:	000a2403          	lw	s0,0(s4)
ffffffffc0204e7a:	b7ad                	j	ffffffffc0204de4 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0204e7c:	000a6603          	lwu	a2,0(s4)
ffffffffc0204e80:	46a1                	li	a3,8
ffffffffc0204e82:	8a2e                	mv	s4,a1
ffffffffc0204e84:	bdb1                	j	ffffffffc0204ce0 <vprintfmt+0x156>
ffffffffc0204e86:	000a6603          	lwu	a2,0(s4)
ffffffffc0204e8a:	46a9                	li	a3,10
ffffffffc0204e8c:	8a2e                	mv	s4,a1
ffffffffc0204e8e:	bd89                	j	ffffffffc0204ce0 <vprintfmt+0x156>
ffffffffc0204e90:	000a6603          	lwu	a2,0(s4)
ffffffffc0204e94:	46c1                	li	a3,16
ffffffffc0204e96:	8a2e                	mv	s4,a1
ffffffffc0204e98:	b5a1                	j	ffffffffc0204ce0 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0204e9a:	9902                	jalr	s2
ffffffffc0204e9c:	bf09                	j	ffffffffc0204dae <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0204e9e:	85a6                	mv	a1,s1
ffffffffc0204ea0:	02d00513          	li	a0,45
ffffffffc0204ea4:	e03e                	sd	a5,0(sp)
ffffffffc0204ea6:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0204ea8:	6782                	ld	a5,0(sp)
ffffffffc0204eaa:	8a66                	mv	s4,s9
ffffffffc0204eac:	40800633          	neg	a2,s0
ffffffffc0204eb0:	46a9                	li	a3,10
ffffffffc0204eb2:	b53d                	j	ffffffffc0204ce0 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0204eb4:	03b05163          	blez	s11,ffffffffc0204ed6 <vprintfmt+0x34c>
ffffffffc0204eb8:	02d00693          	li	a3,45
ffffffffc0204ebc:	f6d79de3          	bne	a5,a3,ffffffffc0204e36 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0204ec0:	00002417          	auipc	s0,0x2
ffffffffc0204ec4:	f2040413          	addi	s0,s0,-224 # ffffffffc0206de0 <default_pmm_manager+0x260>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204ec8:	02800793          	li	a5,40
ffffffffc0204ecc:	02800513          	li	a0,40
ffffffffc0204ed0:	00140a13          	addi	s4,s0,1
ffffffffc0204ed4:	bd6d                	j	ffffffffc0204d8e <vprintfmt+0x204>
ffffffffc0204ed6:	00002a17          	auipc	s4,0x2
ffffffffc0204eda:	f0ba0a13          	addi	s4,s4,-245 # ffffffffc0206de1 <default_pmm_manager+0x261>
ffffffffc0204ede:	02800513          	li	a0,40
ffffffffc0204ee2:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0204ee6:	05e00413          	li	s0,94
ffffffffc0204eea:	b565                	j	ffffffffc0204d92 <vprintfmt+0x208>

ffffffffc0204eec <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0204eec:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0204eee:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0204ef2:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0204ef4:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0204ef6:	ec06                	sd	ra,24(sp)
ffffffffc0204ef8:	f83a                	sd	a4,48(sp)
ffffffffc0204efa:	fc3e                	sd	a5,56(sp)
ffffffffc0204efc:	e0c2                	sd	a6,64(sp)
ffffffffc0204efe:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0204f00:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0204f02:	c89ff0ef          	jal	ra,ffffffffc0204b8a <vprintfmt>
}
ffffffffc0204f06:	60e2                	ld	ra,24(sp)
ffffffffc0204f08:	6161                	addi	sp,sp,80
ffffffffc0204f0a:	8082                	ret

ffffffffc0204f0c <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc0204f0c:	9e3707b7          	lui	a5,0x9e370
ffffffffc0204f10:	2785                	addiw	a5,a5,1
ffffffffc0204f12:	02a7853b          	mulw	a0,a5,a0
    return (hash >> (32 - bits));
ffffffffc0204f16:	02000793          	li	a5,32
ffffffffc0204f1a:	9f8d                	subw	a5,a5,a1
}
ffffffffc0204f1c:	00f5553b          	srlw	a0,a0,a5
ffffffffc0204f20:	8082                	ret
