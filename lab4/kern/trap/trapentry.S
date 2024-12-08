//用于处理 RISC-V 架构下的陷阱（trap）和中断。它定义了保存和恢复寄存器状态的宏，并实现了陷阱处理的入口和返回逻辑。

#include <riscv.h>  // 包含 RISC-V 的头文件

    .macro SAVE_ALL  // 定义宏 SAVE_ALL
    .align 2  // 对齐到 2 字节

    csrw sscratch, sp  // 将当前栈指针保存到 sscratch 寄存器

    addi sp, sp, -36 * REGBYTES  // 为保存寄存器腾出空间，调整栈指针
    # save gprs  // 保存通用寄存器
    STORE  x1,1*REGBYTES(sp)  // 保存 x1 寄存器
    STORE  x3,3*REGBYTES(sp)  // 保存 x3 寄存器
    STORE  x4,4*REGBYTES(sp)  // 保存 x4 寄存器
    STORE  x5,5*REGBYTES(sp)  // 保存 x5 寄存器
    STORE  x6,6*REGBYTES(sp)  // 保存 x6 寄存器
    STORE  x7,7*REGBYTES(sp)  // 保存 x7 寄存器
    STORE  x8,8*REGBYTES(sp)  // 保存 x8 寄存器
    STORE  x9,9*REGBYTES(sp)  // 保存 x9 寄存器
    STORE  x10,10*REGBYTES(sp)  // 保存 x10 寄存器
    STORE  x11,11*REGBYTES(sp)  // 保存 x11 寄存器
    STORE  x12,12*REGBYTES(sp)  // 保存 x12 寄存器
    STORE  x13,13*REGBYTES(sp)  // 保存 x13 寄存器
    STORE  x14,14*REGBYTES(sp)  // 保存 x14 寄存器
    STORE  x15,15*REGBYTES(sp)  // 保存 x15 寄存器
    STORE  x16,16*REGBYTES(sp)  // 保存 x16 寄存器
    STORE  x17,17*REGBYTES(sp)  // 保存 x17 寄存器
    STORE  x18,18*REGBYTES(sp)  // 保存 x18 寄存器
    STORE  x19,19*REGBYTES(sp)  // 保存 x19 寄存器
    STORE  x20,20*REGBYTES(sp)  // 保存 x20 寄存器
    STORE  x21,21*REGBYTES(sp)  // 保存 x21 寄存器
    STORE  x22,22*REGBYTES(sp)  // 保存 x22 寄存器
    STORE  x23,23*REGBYTES(sp)  // 保存 x23 寄存器
    STORE  x24,24*REGBYTES(sp)  // 保存 x24 寄存器
    STORE  x25,25*REGBYTES(sp)  // 保存 x25 寄存器
    STORE  x26,26*REGBYTES(sp)  // 保存 x26 寄存器
    STORE  x27,27*REGBYTES(sp)  // 保存 x27 寄存器
    STORE  x28,28*REGBYTES(sp)  // 保存 x28 寄存器
    STORE  x29,29*REGBYTES(sp)  // 保存 x29 寄存器
    STORE  x30,30*REGBYTES(sp)  // 保存 x30 寄存器
    STORE  x31,31*REGBYTES(sp)  // 保存 x31 寄存器

    # get sr, epc, badvaddr, cause  // 获取状态寄存器、异常程序计数器、错误地址和异常原因
    csrr s0, sscratch  // 从 sscratch 寄存器读取 s0
    csrr s1, sstatus  // 从 sstatus 寄存器读取 s1
    csrr s2, sepc  // 从 sepc 寄存器读取 s2
    csrr s3, 0x143  // 从 0x143 寄存器读取 s3
    csrr s4, scause  // 从 scause 寄存器读取 s4

    STORE s0, 2*REGBYTES(sp)  // 保存 s0 寄存器
    STORE s1, 32*REGBYTES(sp)  // 保存 s1 寄存器
    STORE s2, 33*REGBYTES(sp)  // 保存 s2 寄存器
    STORE s3, 34*REGBYTES(sp)  // 保存 s3 寄存器
    STORE s4, 35*REGBYTES(sp)  // 保存 s4 寄存器
    .endm  // 结束宏定义

    .macro RESTORE_ALL  // 定义宏 RESTORE_ALL

    LOAD s1, 32*REGBYTES(sp)  // 恢复 s1 寄存器
    LOAD s2, 33*REGBYTES(sp)  // 恢复 s2 寄存器

    csrw sstatus, s1  // 将 s1 写入 sstatus 寄存器
    csrw sepc, s2  // 将 s2 写入 sepc 寄存器

    // restore x registers  // 恢复 x 寄存器
    LOAD  x1,1*REGBYTES(sp)  // 恢复 x1 寄存器
    LOAD  x3,3*REGBYTES(sp)  // 恢复 x3 寄存器
    LOAD  x4,4*REGBYTES(sp)  // 恢复 x4 寄存器
    LOAD  x5,5*REGBYTES(sp)  // 恢复 x5 寄存器
    LOAD  x6,6*REGBYTES(sp)  // 恢复 x6 寄存器
    LOAD  x7,7*REGBYTES(sp)  // 恢复 x7 寄存器
    LOAD  x8,8*REGBYTES(sp)  // 恢复 x8 寄存器
    LOAD  x9,9*REGBYTES(sp)  // 恢复 x9 寄存器
    LOAD  x10,10*REGBYTES(sp)  // 恢复 x10 寄存器
    LOAD  x11,11*REGBYTES(sp)  // 恢复 x11 寄存器
    LOAD  x12,12*REGBYTES(sp)  // 恢复 x12 寄存器
    LOAD  x13,13*REGBYTES(sp)  // 恢复 x13 寄存器
    LOAD  x14,14*REGBYTES(sp)  // 恢复 x14 寄存器
    LOAD  x15,15*REGBYTES(sp)  // 恢复 x15 寄存器
    LOAD  x16,16*REGBYTES(sp)  // 恢复 x16 寄存器
    LOAD  x17,17*REGBYTES(sp)  // 恢复 x17 寄存器
    LOAD  x18,18*REGBYTES(sp)  // 恢复 x18 寄存器
    LOAD  x19,19*REGBYTES(sp)  // 恢复 x19 寄存器
    LOAD  x20,20*REGBYTES(sp)  // 恢复 x20 寄存器
    LOAD  x21,21*REGBYTES(sp)  // 恢复 x21 寄存器
    LOAD  x22,22*REGBYTES(sp)  // 恢复 x22 寄存器
    LOAD  x23,23*REGBYTES(sp)  // 恢复 x23 寄存器
    LOAD  x24,24*REGBYTES(sp)  // 恢复 x24 寄存器
    LOAD  x25,25*REGBYTES(sp)  // 恢复 x25 寄存器
    LOAD  x26,26*REGBYTES(sp)  // 恢复 x26 寄存器
    LOAD  x27,27*REGBYTES(sp)  // 恢复 x27 寄存器
    LOAD  x28,28*REGBYTES(sp)  // 恢复 x28 寄存器
    LOAD  x29,29*REGBYTES(sp)  // 恢复 x29 寄存器
    LOAD  x30,30*REGBYTES(sp)  // 恢复 x30 寄存器
    LOAD  x31,31*REGBYTES(sp)  // 恢复 x31 寄存器
    # restore sp last  // 最后恢复栈指针
    LOAD  x2,2*REGBYTES(sp)  // 恢复 x2 寄存器
    .endm  // 结束宏定义

    .globl __alltraps  // 声明全局符号 __alltraps
__alltraps:  // 定义 __alltraps 标签
    SAVE_ALL  // 调用 SAVE_ALL 宏

    move  a0, sp  // 将栈指针移动到 a0
    jal trap  // 跳转并链接到 trap 函数
    # sp should be the same as before "jal trap"  // sp 应该和 "jal trap" 之前一样
    # 因为调用 trap 函数时，栈指针（SP）用于保存当前的寄存器状态和其他上下文信息。

    .globl __trapret  // 声明全局符号 __trapret
__trapret:  // 定义 __trapret 标签
    RESTORE_ALL  // 调用 RESTORE_ALL 宏
    # go back from supervisor call  // 从超级调用返回
    sret  // 执行 sret 指令返回，在proc.c中设置了epc为kernel_thread_entry，kernel_thread_entry在entry.s中

    .globl forkrets  // 声明全局符号 forkrets
forkrets:  // 定义 forkrets 标签
    # set stack to this new process's trapframe  // 将栈设置为这个新进程的 trapframe
    move sp, a0  // 将 a0 移动到栈指针，中断帧放在了sp，这样在__trapret中就可以直接从中断帧里面恢复所有的寄存器
    j __trapret  // 跳转到 __trapret
