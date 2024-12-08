/*处理陷阱（trap）和中断。它包含了初始化中断描述符表（IDT）、处理页错误、中断和异常的函数。
*/
#include <assert.h> // 包含断言库
#include <clock.h> // 包含时钟库
#include <console.h> // 包含控制台库
#include <defs.h> // 包含定义库
#include <kdebug.h> // 包含内核调试库
#include <memlayout.h> // 包含内存布局库
#include <mmu.h> // 包含内存管理单元库
#include <riscv.h> // 包含RISC-V架构相关库
#include <stdio.h> // 包含标准输入输出库
#include <swap.h> // 包含交换库
#include <trap.h> // 包含陷阱处理库
#include <vmm.h> // 包含虚拟内存管理库

#define TICK_NUM 100 // 定义时钟滴答数

static void print_ticks() { // 打印时钟滴答数
    cprintf("%d ticks\n", TICK_NUM); // 打印滴答数
#ifdef DEBUG_GRADE // 如果定义了DEBUG_GRADE
    cprintf("End of Test.\n"); // 打印测试结束
    panic("EOT: kernel seems ok."); // 触发内核恐慌，表示测试结束
#endif
}

/* idt_init - initialize IDT to each of the entry points in kern/trap/vectors.S
 * 初始化中断描述符表（IDT），指向kern/trap/vectors.S中的各个入口点
 */
void idt_init(void) {
    extern void __alltraps(void); // 声明外部函数__alltraps
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel
     * 将sscratch寄存器设置为0，表示当前在内核中执行
     */
    write_csr(sscratch, 0); // 写入sscratch寄存器
    /* Set the exception vector address
     * 设置异常向量地址
     */
    write_csr(stvec, &__alltraps); // 写入stvec寄存器
    /* Allow kernel to access user memory
     * 允许内核访问用户内存
     */
    set_csr(sstatus, SSTATUS_SUM); // 设置sstatus寄存器
}

/* trap_in_kernel - test if trap happened in kernel
 * 测试陷阱是否发生在内核中
 */
bool trap_in_kernel(struct trapframe *tf) {
    return (tf->status & SSTATUS_SPP) != 0; // 检查状态寄存器中的SPP位
}

void print_trapframe(struct trapframe *tf) { // 打印陷阱帧
    cprintf("trapframe at %p\n", tf); // 打印陷阱帧地址
    print_regs(&tf->gpr); // 打印通用寄存器
    cprintf("  status   0x%08x\n", tf->status); // 打印状态寄存器
    cprintf("  epc      0x%08x\n", tf->epc); // 打印异常程序计数器
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr); // 打印错误地址
    cprintf("  cause    0x%08x\n", tf->cause); // 打印异常原因
}

void print_regs(struct pushregs *gpr) { // 打印通用寄存器
    cprintf("  zero     0x%08x\n", gpr->zero); // 打印zero寄存器
    cprintf("  ra       0x%08x\n", gpr->ra); // 打印返回地址寄存器
    cprintf("  sp       0x%08x\n", gpr->sp); // 打印栈指针寄存器
    cprintf("  gp       0x%08x\n", gpr->gp); // 打印全局指针寄存器
    cprintf("  tp       0x%08x\n", gpr->tp); // 打印线程指针寄存器
    cprintf("  t0       0x%08x\n", gpr->t0); // 打印临时寄存器t0
    cprintf("  t1       0x%08x\n", gpr->t1); // 打印临时寄存器t1
    cprintf("  t2       0x%08x\n", gpr->t2); // 打印临时寄存器t2
    cprintf("  s0       0x%08x\n", gpr->s0); // 打印保存寄存器s0
    cprintf("  s1       0x%08x\n", gpr->s1); // 打印保存寄存器s1
    cprintf("  a0       0x%08x\n", gpr->a0); // 打印函数参数寄存器a0
    cprintf("  a1       0x%08x\n", gpr->a1); // 打印函数参数寄存器a1
    cprintf("  a2       0x%08x\n", gpr->a2); // 打印函数参数寄存器a2
    cprintf("  a3       0x%08x\n", gpr->a3); // 打印函数参数寄存器a3
    cprintf("  a4       0x%08x\n", gpr->a4); // 打印函数参数寄存器a4
    cprintf("  a5       0x%08x\n", gpr->a5); // 打印函数参数寄存器a5
    cprintf("  a6       0x%08x\n", gpr->a6); // 打印函数参数寄存器a6
    cprintf("  a7       0x%08x\n", gpr->a7); // 打印函数参数寄存器a7
    cprintf("  s2       0x%08x\n", gpr->s2); // 打印保存寄存器s2
    cprintf("  s3       0x%08x\n", gpr->s3); // 打印保存寄存器s3
    cprintf("  s4       0x%08x\n", gpr->s4); // 打印保存寄存器s4
    cprintf("  s5       0x%08x\n", gpr->s5); // 打印保存寄存器s5
    cprintf("  s6       0x%08x\n", gpr->s6); // 打印保存寄存器s6
    cprintf("  s7       0x%08x\n", gpr->s7); // 打印保存寄存器s7
    cprintf("  s8       0x%08x\n", gpr->s8); // 打印保存寄存器s8
    cprintf("  s9       0x%08x\n", gpr->s9); // 打印保存寄存器s9
    cprintf("  s10      0x%08x\n", gpr->s10); // 打印保存寄存器s10
    cprintf("  s11      0x%08x\n", gpr->s11); // 打印保存寄存器s11
    cprintf("  t3       0x%08x\n", gpr->t3); // 打印临时寄存器t3
    cprintf("  t4       0x%08x\n", gpr->t4); // 打印临时寄存器t4
    cprintf("  t5       0x%08x\n", gpr->t5); // 打印临时寄存器t5
    cprintf("  t6       0x%08x\n", gpr->t6); // 打印临时寄存器t6
}

static inline void print_pgfault(struct trapframe *tf) { // 打印页错误信息
    cprintf("page falut at 0x%08x: %c/%c\n", tf->badvaddr, // 打印页错误地址
            trap_in_kernel(tf) ? 'K' : 'U', // 判断错误发生在内核还是用户模式
            tf->cause == CAUSE_STORE_PAGE_FAULT ? 'W' : 'R'); // 判断是写错误还是读错误
}

static int pgfault_handler(struct trapframe *tf) { // 页错误处理函数
    extern struct mm_struct *check_mm_struct; // 声明外部变量check_mm_struct
    print_pgfault(tf); // 打印页错误信息
    if (check_mm_struct != NULL) { // 如果check_mm_struct不为空
        return do_pgfault(check_mm_struct, tf->cause, tf->badvaddr); // 处理页错误
    }
    panic("unhandled page fault.\n"); // 触发内核恐慌，表示未处理的页错误
}

static volatile int in_swap_tick_event = 0; // 定义一个静态易失性变量，表示是否在交换滴答事件中
extern struct mm_struct *check_mm_struct; // 声明外部变量check_mm_struct

void interrupt_handler(struct trapframe *tf) { // 中断处理函数
    intptr_t cause = (tf->cause << 1) >> 1; // 获取中断原因
    switch (cause) { // 根据中断原因进行处理
        case IRQ_U_SOFT: // 用户软件中断
            cprintf("User software interrupt\n"); // 打印用户软件中断信息
            break;
        case IRQ_S_SOFT: // 监督者软件中断
            cprintf("Supervisor software interrupt\n"); // 打印监督者软件中断信息
            break;
        case IRQ_H_SOFT: // 管理者软件中断
            cprintf("Hypervisor software interrupt\n"); // 打印管理者软件中断信息
            break;
        case IRQ_M_SOFT: // 机器软件中断
            cprintf("Machine software interrupt\n"); // 打印机器软件中断信息
            break;
        case IRQ_U_TIMER: // 用户定时器中断
            cprintf("User software interrupt\n"); // 打印用户定时器中断信息
            break;
        case IRQ_S_TIMER: // 监督者定时器中断
            // "All bits besides SSIP and USIP in the sip register are
            // read-only." -- privileged spec1.9.1, 4.1.4, p59
            // In fact, Call sbi_set_timer will clear STIP, or you can clear it
            // directly.
            // clear_csr(sip, SIP_STIP);
            clock_set_next_event(); // 设置下一个时钟事件
            if (++ticks % TICK_NUM == 0) { // 如果滴答数达到TICK_NUM
                print_ticks(); // 打印滴答数
            }
            break;
        case IRQ_H_TIMER: // 管理者定时器中断
            cprintf("Hypervisor software interrupt\n"); // 打印管理者定时器中断信息
            break;
        case IRQ_M_TIMER: // 机器定时器中断
            cprintf("Machine software interrupt\n"); // 打印机器定时器中断信息
            break;
        case IRQ_U_EXT: // 用户外部中断
            cprintf("User software interrupt\n"); // 打印用户外部中断信息
            break;
        case IRQ_S_EXT: // 监督者外部中断
            cprintf("Supervisor external interrupt\n"); // 打印监督者外部中断信息
            break;
        case IRQ_H_EXT: // 管理者外部中断
            cprintf("Hypervisor software interrupt\n"); // 打印管理者外部中断信息
            break;
        case IRQ_M_EXT: // 机器外部中断
            cprintf("Machine software interrupt\n"); // 打印机器外部中断信息
            break;
        default: // 其他中断
            print_trapframe(tf); // 打印陷阱帧
            break;
    }
}

void exception_handler(struct trapframe *tf) { // 异常处理函数
    int ret; // 定义返回值
    switch (tf->cause) { // 根据异常原因进行处理
        case CAUSE_MISALIGNED_FETCH: // 指令地址未对齐
            cprintf("Instruction address misaligned\n"); // 打印指令地址未对齐信息
            break;
        case CAUSE_FETCH_ACCESS: // 指令访问错误
            cprintf("Instruction access fault\n"); // 打印指令访问错误信息
            break;
        case CAUSE_ILLEGAL_INSTRUCTION: // 非法指令
            cprintf("Illegal instruction\n"); // 打印非法指令信息
            break;
        case CAUSE_BREAKPOINT: // 断点
            cprintf("Breakpoint\n"); // 打印断点信息
            break;
        case CAUSE_MISALIGNED_LOAD: // 加载地址未对齐
            cprintf("Load address misaligned\n"); // 打印加载地址未对齐信息
            break;
        case CAUSE_LOAD_ACCESS: // 加载访问错误
            cprintf("Load access fault\n"); // 打印加载访问错误信息
            if ((ret = pgfault_handler(tf)) != 0) { // 如果页错误处理失败
                print_trapframe(tf); // 打印陷阱帧
                panic("handle pgfault failed. %e\n", ret); // 触发内核恐慌，表示页错误处理失败
            }
            break;
        case CAUSE_MISALIGNED_STORE: // 存储地址未对齐
            cprintf("AMO address misaligned\n"); // 打印存储地址未对齐信息
            break;
        case CAUSE_STORE_ACCESS: // 存储访问错误
            cprintf("Store/AMO access fault\n"); // 打印存储访问错误信息
            if ((ret = pgfault_handler(tf)) != 0) { // 如果页错误处理失败
                print_trapframe(tf); // 打印陷阱帧
                panic("handle pgfault failed. %e\n", ret); // 触发内核恐慌，表示页错误处理失败
            }
            break;
        case CAUSE_USER_ECALL: // 用户模式环境调用
            cprintf("Environment call from U-mode\n"); // 打印用户模式环境调用信息
            break;
        case CAUSE_SUPERVISOR_ECALL: // 监督者模式环境调用
            cprintf("Environment call from S-mode\n"); // 打印监督者模式环境调用信息
            break;
        case CAUSE_HYPERVISOR_ECALL: // 管理者模式环境调用
            cprintf("Environment call from H-mode\n"); // 打印管理者模式环境调用信息
            break;
        case CAUSE_MACHINE_ECALL: // 机器模式环境调用
            cprintf("Environment call from M-mode\n"); // 打印机器模式环境调用信息
            break;
        case CAUSE_FETCH_PAGE_FAULT: // 指令页错误
            cprintf("Instruction page fault\n"); // 打印指令页错误信息
            break;
        case CAUSE_LOAD_PAGE_FAULT: // 加载页错误
            cprintf("Load page fault\n"); // 打印加载页错误信息
            if ((ret = pgfault_handler(tf)) != 0) { // 如果页错误处理失败
                print_trapframe(tf); // 打印陷阱帧
                panic("handle pgfault failed. %e\n", ret); // 触发内核恐慌，表示页错误处理失败
            }
            break;
        case CAUSE_STORE_PAGE_FAULT: // 存储页错误
            cprintf("Store/AMO page fault\n"); // 打印存储页错误信息
            if ((ret = pgfault_handler(tf)) != 0) { // 如果页错误处理失败
                print_trapframe(tf); // 打印陷阱帧
                panic("handle pgfault failed. %e\n", ret); // 触发内核恐慌，表示页错误处理失败
            }
            break;
        default: // 其他异常
            print_trapframe(tf); // 打印陷阱帧
            break;
    }
}

/* *
 * trap - handles or dispatches an exception/interrupt. if and when trap()
 * returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * 处理或分派异常/中断。当trap()返回时，kern/trap/trapentry.S中的代码会恢复保存在trapframe中的旧CPU状态，然后使用iret指令从异常中返回。
 * */
void trap(struct trapframe *tf) {
    // dispatch based on what type of trap occurred
    // 根据发生的陷阱类型进行分派
    if ((intptr_t)tf->cause < 0) {
        // interrupts
        // 中断
        interrupt_handler(tf); // 调用中断处理函数
    } else {
        // exceptions
        // 异常
        exception_handler(tf); // 调用异常处理函数
    }
}
