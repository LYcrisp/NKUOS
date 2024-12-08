#include <riscv.h>  # 包含 RISC-V 的头文件

.text  # 表示接下来的代码段是程序代码
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to  # 声明 switch_to 函数为全局函数，可以被其他文件引用
switch_to:  # switch_to 函数的入口a0和a1是传参数的寄存器
    # save from's registers，a0 寄存器保存了指向 from 进程结构体的指针
    STORE ra, 0*REGBYTES(a0)  # 保存 from 进程的返回地址寄存器
    STORE sp, 1*REGBYTES(a0)  # 保存 from 进程的堆栈指针寄存器
    STORE s0, 2*REGBYTES(a0)  # 保存 from 进程的保存寄存器 s0
    STORE s1, 3*REGBYTES(a0)  # 保存 from 进程的保存寄存器 s1
    STORE s2, 4*REGBYTES(a0)  # 保存 from 进程的保存寄存器 s2
    STORE s3, 5*REGBYTES(a0)  # 保存 from 进程的保存寄存器 s3
    STORE s4, 6*REGBYTES(a0)  # 保存 from 进程的保存寄存器 s4
    STORE s5, 7*REGBYTES(a0)  # 保存 from 进程的保存寄存器 s5
    STORE s6, 8*REGBYTES(a0)  # 保存 from 进程的保存寄存器 s6
    STORE s7, 9*REGBYTES(a0)  # 保存 from 进程的保存寄存器 s7
    STORE s8, 10*REGBYTES(a0)  # 保存 from 进程的保存寄存器 s8
    STORE s9, 11*REGBYTES(a0)  # 保存 from 进程的保存寄存器 s9
    STORE s10, 12*REGBYTES(a0)  # 保存 from 进程的保存寄存器 s10
    STORE s11, 13*REGBYTES(a0)  # 保存 from 进程的保存寄存器 s11

    # restore to's registers,a1传to的指针
    LOAD ra, 0*REGBYTES(a1)  # 恢复 to 进程的返回地址寄存器
    LOAD sp, 1*REGBYTES(a1)  # 恢复 to 进程的堆栈指针寄存器
    LOAD s0, 2*REGBYTES(a1)  # 恢复 to 进程的保存寄存器 s0
    LOAD s1, 3*REGBYTES(a1)  # 恢复 to 进程的保存寄存器 s1
    LOAD s2, 4*REGBYTES(a1)  # 恢复 to 进程的保存寄存器 s2
    LOAD s3, 5*REGBYTES(a1)  # 恢复 to 进程的保存寄存器 s3
    LOAD s4, 6*REGBYTES(a1)  # 恢复 to 进程的保存寄存器 s4
    LOAD s5, 7*REGBYTES(a1)  # 恢复 to 进程的保存寄存器 s5
    LOAD s6, 8*REGBYTES(a1)  # 恢复 to 进程的保存寄存器 s6
    LOAD s7, 9*REGBYTES(a1)  # 恢复 to 进程的保存寄存器 s7
    LOAD s8, 10*REGBYTES(a1)  # 恢复 to 进程的保存寄存器 s8
    LOAD s9, 11*REGBYTES(a1)  # 恢复 to 进程的保存寄存器 s9
    LOAD s10, 12*REGBYTES(a1)  # 恢复 to 进程的保存寄存器 s10
    LOAD s11, 13*REGBYTES(a1)  # 恢复 to 进程的保存寄存器 s11

    ret  # 返回，完成进程切换，跳转到 trap/trap.S中的forkret，ra寄存器的设置位置是proc->context.ra = (uintptr_t)forkret;在文件proc.c中
