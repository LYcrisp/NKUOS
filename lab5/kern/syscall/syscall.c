#include <unistd.h>
#include <proc.h>
#include <syscall.h>
#include <trap.h>
#include <stdio.h>
#include <pmm.h>
#include <assert.h>

static int
sys_exit(uint64_t arg[]) {
    int error_code = (int)arg[0];
    return do_exit(error_code);
}

static int
sys_fork(uint64_t arg[]) {
    struct trapframe *tf = current->tf;
    uintptr_t stack = tf->gpr.sp;
    return do_fork(0, stack, tf);
}

static int
sys_wait(uint64_t arg[]) {
    int pid = (int)arg[0];
    int *store = (int *)arg[1];
    return do_wait(pid, store);
}

static int
sys_exec(uint64_t arg[]) {
    const char *name = (const char *)arg[0];
    size_t len = (size_t)arg[1];
    unsigned char *binary = (unsigned char *)arg[2];
    size_t size = (size_t)arg[3];
    return do_execve(name, len, binary, size);
}

static int
sys_yield(uint64_t arg[]) {
    return do_yield();
}

static int
sys_kill(uint64_t arg[]) {
    int pid = (int)arg[0];
    return do_kill(pid);
}

static int
sys_getpid(uint64_t arg[]) {
    return current->pid;
}

static int
sys_putc(uint64_t arg[]) {
    int c = (int)arg[0];
    cputchar(c);
    return 0;
}

static int
sys_pgdir(uint64_t arg[]) {
    //print_pgdir();
    return 0;
}

static int (*syscalls[])(uint64_t arg[]) = {
    [SYS_exit]              sys_exit,
    [SYS_fork]              sys_fork,
    [SYS_wait]              sys_wait,
    [SYS_exec]              sys_exec, //执行这个
    [SYS_yield]             sys_yield,
    [SYS_kill]              sys_kill,
    [SYS_getpid]            sys_getpid,
    [SYS_putc]              sys_putc,
    [SYS_pgdir]             sys_pgdir,
};

#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void
syscall(void) {
    struct trapframe *tf = current->tf;
    uint64_t arg[5];
    int num = tf->gpr.a0;
    if (num >= 0 && num < NUM_SYSCALLS) {
        if (syscalls[num] != NULL) {
            arg[0] = tf->gpr.a1;
            arg[1] = tf->gpr.a2;
            arg[2] = tf->gpr.a3;
            arg[3] = tf->gpr.a4;
            arg[4] = tf->gpr.a5;
            tf->gpr.a0 = syscalls[num](arg);
            return ;
        }
    }
    print_trapframe(tf);
    panic("undefined syscall %d, pid = %d, name = %s.\n",
            num, current->pid, current->name);
}
/*
void
syscall(void) { // 系统调用处理函数
    struct trapframe *tf = current->tf; // 获取当前进程的trapframe
    uint64_t arg[5]; // 用于存储系统调用参数的数组
    int num = tf->gpr.a0; // 获取系统调用号
    if (num >= 0 && num < NUM_SYSCALLS) { // 检查系统调用号是否有效
        if (syscalls[num] != NULL) { // 检查系统调用是否已实现
            arg[0] = tf->gpr.a1; // 获取第一个参数
            arg[1] = tf->gpr.a2; // 获取第二个参数
            arg[2] = tf->gpr.a3; // 获取第三个参数
            arg[3] = tf->gpr.a4; // 获取第四个参数
            arg[4] = tf->gpr.a5; // 获取第五个参数
            tf->gpr.a0 = syscalls[num](arg); // 调用相应的系统调用函数，并将返回值存储在a0寄存器中
            return ; // 返回
        }
    }
    print_trapframe(tf); // 打印trapframe信息
    panic("undefined syscall %d, pid = %d, name = %s.\n", // 抛出未定义的系统调用异常
            num, current->pid, current->name);
}
*/
