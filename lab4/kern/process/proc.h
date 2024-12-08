#ifndef __KERN_PROCESS_PROC_H__
#define __KERN_PROCESS_PROC_H__

#include <defs.h>
#include <list.h>
#include <trap.h>
#include <memlayout.h>


// process's state in his life cycle
enum proc_state {
    // PROC_UNINIT = 0,  // 未初始化
    // PROC_SLEEPING,    // 睡眠状态
    // PROC_RUNNABLE,    // 可运行状态（可能正在运行）
    // PROC_ZOMBIE,      // 僵尸状态，几乎死亡，等待父进程回收其资源

    // 这四个状态分别是：
    // 1. PROC_UNINIT：进程未初始化状态，表示进程还没有被完全创建或初始化。
    // 2. PROC_SLEEPING：进程处于睡眠状态，表示进程正在等待某个事件（如I/O操作完成）而暂时停止运行。
    // 3. PROC_RUNNABLE：进程处于可运行状态，表示进程已经准备好运行，可能正在运行或等待CPU调度。
    // 4. PROC_ZOMBIE：进程处于僵尸状态，表示进程已经终止，但其父进程尚未回收其资源。
    PROC_UNINIT = 0,  // uninitialized
    PROC_SLEEPING,    // sleeping
    PROC_RUNNABLE,    // runnable(maybe running)
    PROC_ZOMBIE,      // almost dead, and wait parent proc to reclaim his resource
};

struct context {
    uintptr_t ra;
    uintptr_t sp;
    uintptr_t s0;
    uintptr_t s1;
    uintptr_t s2;
    uintptr_t s3;
    uintptr_t s4;
    uintptr_t s5;
    uintptr_t s6;
    uintptr_t s7;
    uintptr_t s8;
    uintptr_t s9;
    uintptr_t s10;
    uintptr_t s11;
};

#define PROC_NAME_LEN               15
#define MAX_PROCESS                 4096
#define MAX_PID                     (MAX_PROCESS * 2)

extern list_entry_t proc_list;

struct proc_struct {
    enum proc_state state;                      // 进程状态
    int pid;                                    // Process ID
    int runs;                                   // the running times of Proces
    uintptr_t kstack;                           // 进程的内核栈地址
    volatile bool need_resched;                 // 是否需要重新调度
    struct proc_struct *parent;                 // the parent process
    struct mm_struct *mm;                       // 进程的内存管理字段
    struct context context;                     // context中保存了进程执行的上下文，也就是几个关键的寄存器的值
    struct trapframe *tf;                       // 进程的中断帧。当进程从用户空间跳进内核空间的时候，进程的执行状态被保存在了中断帧中
    uintptr_t cr3;                              // 页表所在的基址
    uint32_t flags;                             // 进程标志
    char name[PROC_NAME_LEN + 1];               // Process name
    list_entry_t list_link;                     // Process link list 
    list_entry_t hash_link;                     // Process hash list
};

#define le2proc(le, member)         \
    to_struct((le), struct proc_struct, member)

extern struct proc_struct *idleproc, *initproc, *current;

void proc_init(void);
void proc_run(struct proc_struct *proc);
int kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags);

char *set_proc_name(struct proc_struct *proc, const char *name);
char *get_proc_name(struct proc_struct *proc);
void cpu_idle(void) __attribute__((noreturn));

struct proc_struct *find_proc(int pid);
int do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf);
int do_exit(int error_code);

#endif /* !__KERN_PROCESS_PROC_H__ */

