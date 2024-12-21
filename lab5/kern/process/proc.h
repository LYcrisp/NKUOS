#ifndef __KERN_PROCESS_PROC_H__
#define __KERN_PROCESS_PROC_H__

#include <defs.h>
#include <list.h>
#include <trap.h>
#include <memlayout.h>


// 进程在其生命周期中的状态
enum proc_state {
    PROC_UNINIT = 0,  // 未初始化
    PROC_SLEEPING,    // 睡眠中
    PROC_RUNNABLE,    // 可运行（可能正在运行）
    PROC_ZOMBIE,      // 几乎死亡，等待父进程回收其资源
};

// 上下文结构体
struct context {
    uintptr_t ra;  // 返回地址寄存器
    uintptr_t sp;  // 栈指针寄存器
    uintptr_t s0;  // 保存寄存器0
    uintptr_t s1;  // 保存寄存器1
    uintptr_t s2;  // 保存寄存器2
    uintptr_t s3;  // 保存寄存器3
    uintptr_t s4;  // 保存寄存器4
    uintptr_t s5;  // 保存寄存器5
    uintptr_t s6;  // 保存寄存器6
    uintptr_t s7;  // 保存寄存器7
    uintptr_t s8;  // 保存寄存器8
    uintptr_t s9;  // 保存寄存器9
    uintptr_t s10; // 保存寄存器10
    uintptr_t s11; // 保存寄存器11
};

#define PROC_NAME_LEN               15  // 进程名称长度
#define MAX_PROCESS                 4096  // 最大进程数
#define MAX_PID                     (MAX_PROCESS * 2)  // 最大进程ID

extern list_entry_t proc_list;  // 进程列表

// 进程结构体
struct proc_struct {
    enum proc_state state;                      // 进程状态
    int pid;                                    // 进程ID
    int runs;                                   // 进程运行次数
    uintptr_t kstack;                           // 进程内核栈
    volatile bool need_resched;                 // 是否需要重新调度以释放CPU？
    struct proc_struct *parent;                 // 父进程
    struct mm_struct *mm;                       // 进程的内存管理字段
    struct context context;                     // 切换到此处运行进程
    struct trapframe *tf;                       // 当前中断的陷阱帧
    uintptr_t cr3;                              // CR3寄存器：页目录表基地址
    uint32_t flags;                             // 进程标志
    char name[PROC_NAME_LEN + 1];               // 进程名称
    list_entry_t list_link;                     // 进程链表
    list_entry_t hash_link;                     // 进程哈希链表
    int exit_code;                              // 退出代码（发送给父进程）
    uint32_t wait_state;                        // 等待状态
    struct proc_struct *cptr, *yptr, *optr;     // 进程之间的关系
};

#define PF_EXITING                  0x00000001      // 正在关闭

#define WT_CHILD                    (0x00000001 | WT_INTERRUPTED)  // 子进程等待状态
#define WT_INTERRUPTED               0x80000000                    // 等待状态可被中断

// 获取进程结构体的宏
#define le2proc(le, member)         \
    to_struct((le), struct proc_struct, member)

extern struct proc_struct *idleproc, *initproc, *current;  // 空闲进程、初始化进程、当前进程

void proc_init(void);  // 初始化进程
void proc_run(struct proc_struct *proc);  // 运行进程
int kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags);  // 创建内核线程

char *set_proc_name(struct proc_struct *proc, const char *name);  // 设置进程名称
char *get_proc_name(struct proc_struct *proc);  // 获取进程名称
void cpu_idle(void) __attribute__((noreturn));  // CPU空闲

struct proc_struct *find_proc(int pid);  // 查找进程
int do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf);  // 执行fork
int do_exit(int error_code);  // 执行退出
int do_yield(void);  // 执行让出
int do_execve(const char *name, size_t len, unsigned char *binary, size_t size);  // 执行execve
int do_wait(int pid, int *code_store);  // 执行等待
int do_kill(int pid);  // 执行杀死进程
#endif /* !__KERN_PROCESS_PROC_H__ */
