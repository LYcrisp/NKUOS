/*
文件定义了一个名为 pushregs 的结构体，该结构体用于保存寄存器的状态。
这个结构体在处理陷阱（trap）或中断时非常有用，因为它可以保存当前的寄存器状态，以便在处理完陷阱或中断后恢复。
*/


#ifndef __KERN_TRAP_TRAP_H__  // 防止重复包含头文件的宏定义
#define __KERN_TRAP_TRAP_H__  // 防止重复包含头文件的宏定义

#include <defs.h>  // 包含通用的定义头文件

// 定义保存寄存器状态的结构体
struct pushregs {
    uintptr_t zero;  // 硬连线为零的寄存器
    uintptr_t ra;    // 返回地址寄存器
    uintptr_t sp;    // 栈指针寄存器
    uintptr_t gp;    // 全局指针寄存器
    uintptr_t tp;    // 线程指针寄存器
    uintptr_t t0;    // 临时寄存器
    uintptr_t t1;    // 临时寄存器
    uintptr_t t2;    // 临时寄存器
    uintptr_t s0;    // 保存的寄存器/帧指针
    uintptr_t s1;    // 保存的寄存器
    uintptr_t a0;    // 函数参数/返回值寄存器
    uintptr_t a1;    // 函数参数/返回值寄存器
    uintptr_t a2;    // 函数参数寄存器
    uintptr_t a3;    // 函数参数寄存器
    uintptr_t a4;    // 函数参数寄存器
    uintptr_t a5;    // 函数参数寄存器
    uintptr_t a6;    // 函数参数寄存器
    uintptr_t a7;    // 函数参数寄存器
    uintptr_t s2;    // 保存的寄存器
    uintptr_t s3;    // 保存的寄存器
    uintptr_t s4;    // 保存的寄存器
    uintptr_t s5;    // 保存的寄存器
    uintptr_t s6;    // 保存的寄存器
    uintptr_t s7;    // 保存的寄存器
    uintptr_t s8;    // 保存的寄存器
    uintptr_t s9;    // 保存的寄存器
    uintptr_t s10;   // 保存的寄存器
    uintptr_t s11;   // 保存的寄存器
    uintptr_t t3;    // 临时寄存器
    uintptr_t t4;    // 临时寄存器
    uintptr_t t5;    // 临时寄存器
    uintptr_t t6;    // 临时寄存器
};

// 定义陷阱帧结构体，用于保存陷阱发生时的CPU状态
struct trapframe {
    struct pushregs gpr;  // 通用寄存器的状态
    uintptr_t status;     // CPU状态寄存器
    uintptr_t epc;        // 异常程序计数器
    uintptr_t badvaddr;   // 错误地址寄存器
    uintptr_t cause;      // 异常原因寄存器
};

// 声明陷阱处理函数
void trap(struct trapframe *tf);  // 处理陷阱的函数
void idt_init(void);  // 初始化中断描述符表的函数
void print_trapframe(struct trapframe *tf);  // 打印陷阱帧信息的函数
void print_regs(struct pushregs* gpr);  // 打印寄存器信息的函数
bool trap_in_kernel(struct trapframe *tf);  // 判断陷阱是否发生在内核模式下的函数

#endif /* !__KERN_TRAP_TRAP_H__ */  // 结束防止重复包含头文件的宏定义
