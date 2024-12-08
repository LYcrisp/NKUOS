
#include <proc.h>
#include <kmalloc.h>
#include <string.h>
#include <sync.h>
#include <pmm.h>
#include <error.h>
#include <sched.h>
#include <elf.h>
#include <vmm.h>
#include <trap.h>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

/* ------------- 进程/线程机制设计与实现 -------------
(一个简化的 Linux 进程/线程机制)
简介：
  uCore 实现了一个简单的进程/线程机制。进程包含独立的内存空间、至少一个用于执行的线程、内核数据（用于管理）、处理器状态（用于上下文切换）、文件（在第六章实验中引入）等。uCore 需要高效管理这些细节。在 uCore 中，线程是一种特殊的进程（共享进程的内存）。
------------------------------
进程状态        :     含义                      -- 相关函数
    PROC_UNINIT     :   未初始化                -- alloc_proc
    PROC_SLEEPING   :   睡眠状态                -- try_free_pages, do_wait, do_sleep
    PROC_RUNNABLE   :   可运行（可能正在运行）    -- proc_init, wakeup_proc
    PROC_ZOMBIE     :   几乎已结束               -- do_exit

------------------------------
进程状态变化：
                                                
  alloc_proc                                 RUNNING
      +                                   +--<----<--+
      +                                   + proc_run +
      V                                   +-->---->--+ 
PROC_UNINIT -- proc_init/wakeup_proc --> PROC_RUNNABLE -- try_free_pages/do_wait/do_sleep --> PROC_SLEEPING --
                                           A      +                                                           +
                                           |      +--- do_exit --> PROC_ZOMBIE                                +
                                           +                                                                  + 
                                           -----------------------wakeup_proc----------------------------------
------------------------------
进程关系：
父进程:           proc->parent  （proc 是子进程）
子进程:           proc->cptr    （proc 是父进程）
较老的兄弟进程:    proc->optr    （proc 是较年轻的兄弟进程）
较年轻的兄弟进程:  proc->yptr    （proc 是较老的兄弟进程）
------------------------------
与进程相关的系统调用：
SYS_exit        : 进程退出                             -->do_exit
SYS_fork        : 创建子进程，复制内存管理结构          -->do_fork-->wakeup_proc
SYS_wait        : 等待进程                             -->do_wait
SYS_exec        : fork 后，进程执行程序                -->加载程序并刷新内存管理结构
SYS_clone       : 创建子线程                           -->do_fork-->wakeup_proc
SYS_yield       : 进程主动标记自己需要重新调度         -->proc->need_sched=1，然后调度器会重新调度该进程
SYS_sleep       : 进程休眠                             -->do_sleep 
SYS_kill        : 终止进程                             -->do_kill-->proc->flags |= PF_EXITING
                                                     -->wakeup_proc-->do_wait-->do_exit   
SYS_getpid      : 获取进程的 PID
*/


// the process set's list
list_entry_t proc_list; // 所有进程控制块的双向线性列表，proc_struct中的成员变量list_link将链接入这个链表中。

#define HASH_SHIFT          10 //哈希表大小计算中用于移位的位数。
#define HASH_LIST_SIZE      (1 << HASH_SHIFT) //哈希表中将有 1024 个桶（buckets）用于存储数据2^10 = 1024
#define pid_hashfn(x)       (hash32(x, HASH_SHIFT)) //哈希函数，用于计算pid的哈希值

// has list for process set based on pid
static list_entry_t hash_list[HASH_LIST_SIZE]; // 基于pid的进程集合的哈希列表，proc_struct中的成员变量hash_link将基于pid链接入这个哈希表中。

// idle proc
struct proc_struct *idleproc = NULL; // 空闲进程
// init proc
struct proc_struct *initproc = NULL; // 初始化进程
// current proc
struct proc_struct *current = NULL; // 当前进程

static int nr_process = 0; // 进程数量

void kernel_thread_entry(void); // 内核线程入口
void forkrets(struct trapframe *tf); // fork返回
void switch_to(struct context *from, struct context *to); // 上下文切换,在switch.S中实现

/*
 * alloc_proc - 分配并初始化一个新的进程控制块(proc_struct)。
 * 返回新分配的proc_struct指针，如果分配失败则返回NULL。
 */
static struct proc_struct *
alloc_proc(void) {
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct)); // 分配一个proc_struct结构
    if (proc != NULL) {
    //LAB4:EXERCISE1 YOUR CODE
    /*
     * below fields in proc_struct need to be initialized
     *       enum proc_state state;                      // Process state
     *       int pid;                                    // Process ID
     *       int runs;                                   // the running times of Proces
     *       uintptr_t kstack;                           // Process kernel stack
     *       volatile bool need_resched;                 // bool value: need to be rescheduled to release CPU?
     *       struct proc_struct *parent;                 // the parent process
     *       struct mm_struct *mm;                       // Process's memory management field
     *       struct context context;                     // Switch here to run process
     *       struct trapframe *tf;                       // Trap frame for current interrupt
     *       uintptr_t cr3;                              // CR3 register: the base addr of Page Directroy Table(PDT)
     *       uint32_t flags;                             // Process flag
     *       char name[PROC_NAME_LEN + 1];               // Process name
     */

    //【提示】在alloc_proc函数的实现中，需要初始化的proc_struct结构中的成员变量至少包括：
    //state/pid/runs/kstack/need_resched/parent/mm/context/tf/cr3/flags/name。

        proc->state = PROC_UNINIT;                           // 设置进程状态为未初始化
        proc->pid = -1;                                      // 设置进程ID为-1（还未分配）
        proc->cr3 = boot_cr3;                                // 设置CR3寄存器的值（页目录基址）
        proc->runs = 0;                                      // 设置进程运行次数为0
        proc->kstack = 0;                                    // 设置内核栈地址为0（还未分配）
        proc->need_resched = 0;                              // 设置不需要重新调度
        proc->parent = NULL;                                 // 设置父进程为空
        proc->mm = NULL;                                     // 设置内存管理字段为空
        memset(&(proc->context), 0, sizeof(struct context)); // 初始化上下文信息为0
        proc->tf = NULL;                                     // 设置trapframe为空
        proc->flags = 0;                                     // 设置进程标志为0
        memset(proc->name, 0, PROC_NAME_LEN);                // 初始化进程名为0
    }
    return proc; // 返回分配的proc_struct结构
}

/*
 * set_proc_name - 设置进程proc的名称为name。
 * @proc: 指向进程控制块(proc_struct)的指针。
 * @name: 要设置的进程名称字符串。
 * 返回值为设置后的进程名称字符串的指针。
 */
// set_proc_name - set the name of proc
char *
set_proc_name(struct proc_struct *proc, const char *name) {
    memset(proc->name, 0, sizeof(proc->name)); // 清空进程名
    return memcpy(proc->name, name, PROC_NAME_LEN); // 复制新的进程名
}

/*
 * get_proc_name - 获取进程proc的名称。
 * @proc: 指向进程控制块(proc_struct)的指针。
 * 返回值为进程名称字符串的指针。
 */
// get_proc_name - get the name of proc
char *
get_proc_name(struct proc_struct *proc) {
    static char name[PROC_NAME_LEN + 1]; // 静态字符数组用于存储进程名
    memset(name, 0, sizeof(name)); // 清空字符数组
    return memcpy(name, proc->name, PROC_NAME_LEN); // 复制进程名到字符数组
}

/*
 * get_pid - 为新进程分配一个唯一的进程ID(pid)。
 * 返回值为分配的pid。
 */
// get_pid - alloc a unique pid for process
static int
get_pid(void) {
    static_assert(MAX_PID > MAX_PROCESS); // 确保最大PID大于最大进程数
    struct proc_struct *proc; // 定义进程结构指针
    list_entry_t *list = &proc_list, *le; // 定义列表指针
    static int next_safe = MAX_PID, last_pid = MAX_PID; // 定义静态变量用于PID分配
    if (++ last_pid >= MAX_PID) { // 如果last_pid超过最大PID
        last_pid = 1; // 重置last_pid为1
        goto inside; // 跳转到inside标签
    }
    if (last_pid >= next_safe) { // 如果last_pid超过next_safe
    inside:
        next_safe = MAX_PID; // 重置next_safe为最大PID
    repeat:
        le = list; // 初始化列表指针
        while ((le = list_next(le)) != list) { // 遍历进程列表
            proc = le2proc(le, list_link); // 获取进程结构
            if (proc->pid == last_pid) { // 如果进程PID等于last_pid
                if (++ last_pid >= next_safe) { // 增加last_pid并检查是否超过next_safe
                    if (last_pid >= MAX_PID) { // 如果last_pid超过最大PID
                        last_pid = 1; // 重置last_pid为1
                    }
                    next_safe = MAX_PID; // 重置next_safe为最大PID
                    goto repeat; // 重新遍历进程列表
                }
            }
            else if (proc->pid > last_pid && next_safe > proc->pid) { // 如果进程PID大于last_pid且next_safe大于进程PID
                next_safe = proc->pid; // 更新next_safe为进程PID
            }
        }
    }
    return last_pid; // 返回分配的PID
}

// proc_run - make process "proc" running on cpu
// NOTE: before call switch_to, should load  base addr of "proc"'s new PDT
/*
 * proc_run - 使进程proc在CPU上运行。
 * @proc: 要运行的进程控制块(proc_struct)的指针。
 * 如果proc不是当前进程，则进行上下文切换，并切换到proc对应的地址空间。
 */
void
proc_run(struct proc_struct *proc) {
    if (proc != current) { // 如果proc不是当前进程
        // LAB4:EXERCISE3 YOUR CODE
        /*
            * 一些有用的宏、函数和定义，你可以在下面的实现中使用它们。
            * 宏或函数：
            *   local_intr_save():        禁用中断
            *   local_intr_restore():     启用中断
            *   lcr3():                   修改CR3寄存器的值
            *   switch_to():              在两个进程之间进行上下文切换
            */
        // 定义用于保存中断状态的变量
        bool intr_flag;
        // 记录当前进程和即将运行的进程
        struct proc_struct *prev = current, *next = proc;

        // 禁用中断以保护上下文切换过程
        local_intr_save(intr_flag);
        {
            // 将当前进程更新为proc
            current = proc;
            // 加载新进程的页目录表到CR3寄存器并切换地址空间
            lcr3(next->cr3);
            // 执行上下文切换，切换到新进程
            switch_to(&(prev->context), &(next->context));
        }
        // 恢复之前的中断状态
        local_intr_restore(intr_flag);
    }
}

// forkret -- the first kernel entry point of a new thread/process
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
/*
 * forkret - 新进程的第一个内核入口点。
 * 当新进程第一次在内核态运行时，将执行此函数。
 */
static void
forkret(void) {
    forkrets(current->tf); // 执行forkrets函数
}

/*
 * hash_proc - 将进程proc添加到进程哈希链表中。
 * @proc: 要添加的进程控制块(proc_struct)的指针。
 */
// hash_proc - add proc into proc hash_list
static void
hash_proc(struct proc_struct *proc) {
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link)); // 将进程添加到哈希列表中
}

/*
 * find_proc - 根据进程ID(pid)在进程哈希表中查找进程。
 * @pid: 要查找的进程ID。
 * 返回找到的进程控制块(proc_struct)的指针，如果未找到则返回NULL。
 */
// find_proc - find proc frome proc hash_list according to pid
struct proc_struct *
find_proc(int pid) {
    if (0 < pid && pid < MAX_PID) { // 如果PID在有效范围内
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list; // 获取哈希列表
        while ((le = list_next(le)) != list) { // 遍历哈希列表
            struct proc_struct *proc = le2proc(le, hash_link); // 获取进程结构
            if (proc->pid == pid) { // 如果进程PID匹配
                return proc; // 返回进程结构
            }
        }
    }
    return NULL; // 未找到匹配的进程，返回NULL
}

// kernel_thread - create a kernel thread using "fn" function
// NOTE: the contents of temp trapframe tf will be copied to 
//       proc->tf in do_fork-->copy_thread function
/*
 * kernel_thread - 使用函数fn创建一个内核线程。
 * @fn: 函数指针，指向线程将要执行的函数。
 * @arg: 传递给函数fn的参数。
 * @clone_flags: 指定新线程的克隆选项。
 * 返回值为新创建线程的进程ID(pid)。
 */
int kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags) {
    // 对trameframe，也就是我们程序的一些上下文进行一些初始化
    struct trapframe tf;
    memset(&tf, 0, sizeof(struct trapframe));

    // 设置内核线程的参数和函数指针
    tf.gpr.s0 = (uintptr_t)fn; // s0 寄存器保存函数指针
    tf.gpr.s1 = (uintptr_t)arg; // s1 寄存器保存函数参数

    // 设置 trapframe 中的 status 寄存器（SSTATUS）
    // SSTATUS_SPP：Supervisor Previous Privilege（设置为 supervisor 模式，因为这是一个内核线程）
    // SSTATUS_SPIE：Supervisor Previous Interrupt Enable（设置为启用中断，因为这是一个内核线程）
    // SSTATUS_SIE：Supervisor Interrupt Enable（设置为禁用中断，因为我们不希望该线程被中断）
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
    /*
    sstatus 寄存器是 RISC-V 中特权级寄存器之一，
    它用于保存当前进程的状态，包括控制中断和管理 CPU 的运行模式。它包含了多个标志位，用于控制特定的系统行为。 */

    // 将入口点（epc）设置为 kernel_thread_entry 函数，作用实际上是将pc指针指向它(*trapentry.S会用到)
    tf.epc = (uintptr_t)kernel_thread_entry;    // epc用于存储发生异常或中断时的程序计数器（PC）值

    // 使用 do_fork 创建一个新进程（内核线程），这样才真正用设置的tf创建新进程。
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
}

// setup_kstack - alloc pages with size KSTACKPAGE as process kernel stack

/*
 * setup_kstack - 为进程proc分配内核栈。
 * @proc: 指向进程控制块(proc_struct)的指针。
 * 返回0表示成功，否则返回错误码。
 */
static int
setup_kstack(struct proc_struct *proc) {
    struct Page *page = alloc_pages(KSTACKPAGE); // 分配内核栈页
    if (page != NULL) {
        proc->kstack = (uintptr_t)page2kva(page); // 设置内核栈地址
        return 0; // 返回0表示成功
    }
    return -E_NO_MEM; // 返回错误码表示内存不足
}

// put_kstack - free the memory space of process kernel stack
/*
 * put_kstack - 释放进程proc的内核栈内存空间。
 * @proc: 指向进程控制块(proc_struct)的指针。
 */
static void
put_kstack(struct proc_struct *proc) {
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE); // 释放内核栈页
}

// copy_mm - process "proc" duplicate OR share process "current"'s mm according clone_flags
//         - if clone_flags & CLONE_VM, then "share" ; else "duplicate"
/*
 * copy_mm - 根据clone_flags，将当前进程的内存空间复制或共享给进程proc。
 * @clone_flags: 克隆选项，如果设置了CLONE_VM，则共享地址空间，否则复制地址空间。
 * @proc: 指向目标进程控制块(proc_struct)的指针。
 * 返回0表示成功，否则返回错误码。
 */
static int
copy_mm(uint32_t clone_flags, struct proc_struct *proc) {
    assert(current->mm == NULL); // 确保当前进程的内存管理结构为空
    /*
    如果当前进程的内存管理结构不为空，说明该进程可能已经分配了一些内存。
    如果不先释放这些内存就进行新的分配，会导致内存泄漏，浪费系统资源。*/
    /* do nothing in this project */
    return 0; // 返回0表示成功
}

// copy_thread - setup the trapframe on the  process's kernel stack top and
//             - setup the kernel entry point and stack of process

/*
 * copy_thread - 设置进程proc的初始线程状态。
 * @proc: 指向进程控制块(proc_struct)的指针。
 * @esp: 用户栈指针，如果为0，则使用proc的trapframe地址作为栈指针。
 * @tf: 指向当前进程的trapframe，用于初始化proc的trapframe。
 */
static void
copy_thread(struct proc_struct *proc, uintptr_t esp, struct trapframe *tf) {
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE - sizeof(struct trapframe)); // 设置trapframe地址
    *(proc->tf) = *tf; // 复制trapframe内容

    // 将a0寄存器设置为0，以便子进程知道它刚刚被fork
    proc->tf->gpr.a0 = 0; // 设置a0寄存器为0，表示子进程刚刚被fork,说明这个进程是一个子进程
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp; // 设置栈指针

    proc->context.ra = (uintptr_t)forkret; // 设置返回地址为forkret函数
    proc->context.sp = (uintptr_t)(proc->tf); // 设置上下文栈指针,把trapframe放在上下文的栈顶
}
/* do_fork -     parent process for a new child process
 * @clone_flags: used to guide how to clone the child process
 * @stack:       the parent's user stack pointer. if stack==0, It means to fork a kernel thread.
 * @tf:          the trapframe info, which will be copied to child process's proc->tf
 */
 /*
 * do_fork - 创建一个新的子进程。
 * @clone_flags: 克隆选项，指定如何克隆子进程。
 * @stack: 父进程的用户栈指针，如果stack==0，表示创建一个内核线程。
 * @tf: 指向trapframe信息，将被复制到子进程的proc->tf。
 * 返回子进程的进程ID(pid)，如果失败则返回错误码。
 */
int
do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf) {
    int ret = -E_NO_FREE_PROC; // 初始化返回值为没有空闲进程错误码
    struct proc_struct *proc; // 定义进程结构指针
    if (nr_process >= MAX_PROCESS) { // 如果当前进程数量超过最大进程数
        goto fork_out; // 跳转到fork_out标签
    }
    ret = -E_NO_MEM; // 初始化返回值为内存不足错误码
    //LAB4:EXERCISE2 YOUR CODE
        /*
         * 一些有用的宏、函数和定义，你可以在下面的实现中使用它们。
         * 宏或函数：
         *   alloc_proc:   创建一个proc结构并初始化字段 (lab4:exercise1)
         *   setup_kstack: 分配大小为KSTACKPAGE的页作为进程内核栈
         *   copy_mm:      根据clone_flags，复制或共享当前进程的内存空间给进程"proc"
         *                 如果clone_flags & CLONE_VM，则共享；否则复制
         *   copy_thread:  在进程的内核栈顶设置trapframe，并设置进程的内核入口点和栈
         *   hash_proc:    将进程添加到进程哈希链表中
         *   get_pid:      为进程分配一个唯一的pid
         *   wakeup_proc:  设置proc->state = PROC_RUNNABLE
         * 变量：
         *   proc_list:    进程集合的列表
         *   nr_process:   进程集合的数量
         */

    // 1. 调用alloc_proc来分配一个proc_struct
    if ((proc = alloc_proc()) == NULL) // 如果分配失败
        goto fork_out; // 跳转到fork_out标签
    // 2. 调用setup_kstack为子进程分配内核栈
    proc->parent = current; // 设置子进程的父进程为当前进程
    if (setup_kstack(proc)) // 如果分配内核栈失败
        goto bad_fork_cleanup_kstack; // 跳转到bad_fork_cleanup_kstack标签
    // 3. 调用copy_mm根据clone_flag来复制或共享内存
    if (copy_mm(clone_flags, proc)) // 如果复制或共享内存失败
        goto bad_fork_cleanup_proc; // 跳转到bad_fork_cleanup_proc标签
    // 4. 调用copy_thread来设置子进程的tf和context
    copy_thread(proc, stack, tf); // 设置子进程的trapframe和上下文
    // 5. 将新进程添加到进程列表和哈希表中
    bool intr_flag; // 定义中断标志变量
    local_intr_save(intr_flag); // 禁用中断
    {
        proc->pid = get_pid();                    // 为子进程分配一个唯一的进程ID
        hash_proc(proc);                          // 将新进程添加到哈希表中
        list_add(&proc_list, &(proc->list_link)); // 将新进程添加到进程列表中
    }
    local_intr_restore(intr_flag); // 恢复中断
    // 6. 调用wakeup_proc使新的子进程变为可运行状态
    wakeup_proc(proc); // 唤醒子进程
    // 7. 使用子进程的pid作为返回值
    ret = proc->pid; // 设置返回值为子进程的PID

fork_out:
    return ret; // 返回结果

bad_fork_cleanup_kstack:
    put_kstack(proc); // 释放子进程的内核栈
bad_fork_cleanup_proc:
    kfree(proc); // 释放子进程的proc_struct
    goto fork_out; // 跳转到fork_out标签
}

// do_exit - called by sys_exit
//   1. call exit_mmap & put_pgdir & mm_destroy to free the almost all memory space of process
//   2. set process' state as PROC_ZOMBIE, then call wakeup_proc(parent) to ask parent reclaim itself.
//   3. call scheduler to switch to other process

/*
 * do_exit - 使当前进程退出。
 * @error_code: 退出时的错误码。
 * 释放进程的大部分内存空间，将进程状态设为PROC_ZOMBIE，并唤醒父进程以回收自身。
 * 然后调用调度器切换到其他进程。
 */
int
do_exit(int error_code) {
    panic("process exit!!.\n"); // 调用panic函数，打印进程退出信息
}

// init_main - the second kernel thread used to create user_main kernel threads
/*
 * init_main - 第二个内核线程，用于创建 user_main 内核线程。
 * @arg: 传递给 init_main 的参数。
 * 返回值为 0 表示成功。
 */
static int
init_main(void *arg) {
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current)); // 打印initproc的PID和名称
    cprintf("To U: \"%s\".\n", (const char *)arg); // 打印传递的参数
    cprintf("To U: \"en.., Bye, Bye. :)\"\n"); // 打印退出信息
    return 0; // 返回0表示成功
}

// proc_init - set up the first kernel thread idleproc "idle" by itself and 
//           - create the second kernel thread init_main

/*
 * proc_init - 初始化进程子系统，创建第一个内核线程 idleproc 和第二个内核线程 init_main。
 */
void
proc_init(void) {
    int i; // 定义循环变量

    list_init(&proc_list); // 初始化进程列表
    for (i = 0; i < HASH_LIST_SIZE; i ++) { // 遍历哈希列表
        list_init(hash_list + i); // 初始化每个哈希列表
    }

    if ((idleproc = alloc_proc()) == NULL) { // 分配idleproc失败
        panic("cannot alloc idleproc.\n"); // 调用panic函数，打印错误信息
    }

    // 检查alloc_proc函数是否正确
    int *context_mem = (int*) kmalloc(sizeof(struct context)); // 分配context内存
    memset(context_mem, 0, sizeof(struct context)); // 初始化context内存为0
    int context_init_flag = memcmp(&(idleproc->context), context_mem, sizeof(struct context)); // 比较context内存

    int *proc_name_mem = (int*) kmalloc(PROC_NAME_LEN); // 分配proc_name内存
    memset(proc_name_mem, 0, PROC_NAME_LEN); // 初始化proc_name内存为0
    int proc_name_flag = memcmp(&(idleproc->name), proc_name_mem, PROC_NAME_LEN); // 比较proc_name内存

    if(idleproc->cr3 == boot_cr3 && idleproc->tf == NULL && !context_init_flag
        && idleproc->state == PROC_UNINIT && idleproc->pid == -1 && idleproc->runs == 0
        && idleproc->kstack == 0 && idleproc->need_resched == 0 && idleproc->parent == NULL
        && idleproc->mm == NULL && idleproc->flags == 0 && !proc_name_flag
    ){
        cprintf("alloc_proc() correct!\n"); // 打印alloc_proc正确信息

    }
    
    idleproc->pid = 0; // 设置idleproc的PID为0
    idleproc->state = PROC_RUNNABLE; // 设置idleproc的状态为可运行
    idleproc->kstack = (uintptr_t)bootstack; // 设置idleproc的内核栈地址
    idleproc->need_resched = 1; // 设置idleproc需要重新调度
    set_proc_name(idleproc, "idle"); // 设置idleproc的名称为idle
    nr_process ++; // 增加进程数量

    current = idleproc; // 设置当前进程为idleproc

    int pid = kernel_thread(init_main, "Hello world!!", 0); // 创建init_main内核线程
    if (pid <= 0) { // 创建失败
        panic("create init_main failed.\n"); // 调用panic函数，打印错误信息
    }

    initproc = find_proc(pid); // 查找initproc
    set_proc_name(initproc, "init"); // 设置initproc的名称为init

    assert(idleproc != NULL && idleproc->pid == 0); // 断言idleproc不为空且PID为0
    assert(initproc != NULL && initproc->pid == 1); // 断言initproc不为空且PID为1
}

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
/*
 * cpu_idle - 在 kern_init 结束时，第一内核线程 idleproc 将执行此函数。
 * 进入空闲循环，等待需要调度的进程。
 */
void
cpu_idle(void) {
    while (1) { // 无限循环
        if (current->need_resched) { // 如果当前进程需要重新调度
            schedule(); // 调用调度函数
        }
    }
}
