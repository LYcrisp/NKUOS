#include <defs.h> // 包含定义头文件
#include <stdio.h> // 包含标准输入输出头文件
#include <string.h> // 包含字符串操作头文件
#include <console.h> // 包含控制台头文件
#include <kdebug.h> // 包含内核调试头文件
#include <picirq.h> // 包含可编程中断控制器头文件
#include <trap.h> // 包含陷阱处理头文件
#include <clock.h> // 包含时钟头文件
#include <intr.h> // 包含中断头文件
#include <pmm.h> // 包含物理内存管理头文件
#include <vmm.h> // 包含虚拟内存管理头文件
#include <ide.h> // 包含IDE设备头文件
#include <swap.h> // 包含交换头文件
#include <proc.h> // 包含进程头文件
#include <kmonitor.h> // 包含内核监视器头文件

int kern_init(void) __attribute__((noreturn)); // 声明内核初始化函数，noreturn属性表示该函数不会返回
void grade_backtrace(void); // 声明grade_backtrace函数

int
kern_init(void) { // 内核初始化函数
    extern char edata[], end[]; // 声明外部变量edata和end，表示数据段的起始和结束地址
    memset(edata, 0, end - edata); // 将数据段清零

    cons_init(); // 初始化控制台

    const char *message = "(THU.CST) os is loading ..."; // 定义加载信息字符串
    cprintf("%s\n\n", message); // 打印加载信息

    print_kerninfo(); // 打印内核信息

    // grade_backtrace(); // 调用grade_backtrace函数（已注释）

    pmm_init(); // 初始化物理内存管理

    pic_init(); // 初始化可编程中断控制器
    idt_init(); // 初始化中断描述符表

    vmm_init(); // 初始化虚拟内存管理
    proc_init(); // 初始化进程表
    
    ide_init(); // 初始化IDE设备
    swap_init(); // 初始化交换

    clock_init(); // 初始化时钟中断
    intr_enable(); // 启用IRQ中断

    cpu_idle(); // 运行空闲进程
}

void __attribute__((noinline))
grade_backtrace2(int arg0, int arg1, int arg2, int arg3) { // 定义grade_backtrace2函数，noinline属性表示该函数不会被内联
    mon_backtrace(0, NULL, NULL); // 调用mon_backtrace函数，打印当前的函数调用栈
}

void __attribute__((noinline))
grade_backtrace1(int arg0, int arg1) { // 定义grade_backtrace1函数，noinline属性表示该函数不会被内联
    grade_backtrace2(arg0, (int)&arg0, arg1, (int)&arg1); // 调用grade_backtrace2函数，传递参数
}

void __attribute__((noinline))
grade_backtrace0(int arg0, int arg1, int arg2) { // 定义grade_backtrace0函数，noinline属性表示该函数不会被内联
    grade_backtrace1(arg0, arg2); // 调用grade_backtrace1函数，传递参数
}

void
grade_backtrace(void) { // 定义grade_backtrace函数
    grade_backtrace0(0, (int)kern_init, 0xffff0000); // 调用grade_backtrace0函数，传递参数
}

static void
lab1_print_cur_status(void) { // 定义lab1_print_cur_status函数
    static int round = 0; // 定义静态变量round，初始化为0
    round ++; // 递增round变量
}
