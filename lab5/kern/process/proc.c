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
#include <unistd.h>
#include <cow.h>

/* ------------- process/thread mechanism design&implementation -------------
(an simplified Linux process/thread mechanism )
introduction:
  ucore implements a simple process/thread mechanism. process contains the independent memory sapce, at least one threads
for execution, the kernel data(for management), processor state (for context switch), files(in lab6), etc. ucore needs to
manage all these details efficiently. In ucore, a thread is just a special kind of process(share process's memory).
------------------------------
process state       :     meaning               -- reason
    PROC_UNINIT     :   uninitialized           -- alloc_proc
    PROC_SLEEPING   :   sleeping                -- try_free_pages, do_wait, do_sleep
    PROC_RUNNABLE   :   runnable(maybe running) -- proc_init, wakeup_proc, 
    PROC_ZOMBIE     :   almost dead             -- do_exit

-----------------------------
process state changing:
                                            
  alloc_proc                                 RUNNING
      +                                   +--<----<--+
      +                                   + proc_run +
      V                                   +-->---->--+ 
PROC_UNINIT -- proc_init/wakeup_proc --> PROC_RUNNABLE -- try_free_pages/do_wait/do_sleep --> PROC_SLEEPING --
                                           A      +                                                           +
                                           |      +--- do_exit --> PROC_ZOMBIE                                +
                                           +                                                                  + 
                                           -----------------------wakeup_proc----------------------------------
-----------------------------
process relations
parent:           proc->parent  (proc is children)
children:         proc->cptr    (proc is parent)
older sibling:    proc->optr    (proc is younger sibling)
younger sibling:  proc->yptr    (proc is older sibling)
-----------------------------
related syscall for process:
SYS_exit        : process exit,                           -->do_exit
SYS_fork        : create child process, dup mm            -->do_fork-->wakeup_proc
SYS_wait        : wait process                            -->do_wait
SYS_exec        : after fork, process execute a program   -->load a program and refresh the mm
SYS_clone       : create child thread                     -->do_fork-->wakeup_proc
SYS_yield       : process flag itself need resecheduling, -- proc->need_sched=1, then scheduler will rescheule this process
SYS_sleep       : process sleep                           -->do_sleep 
SYS_kill        : kill process                            -->do_kill-->proc->flags |= PF_EXITING
                                                                 -->wakeup_proc-->do_wait-->do_exit   
SYS_getpid      : get the process's pid

*/

// the process set's list
list_entry_t proc_list;

#define HASH_SHIFT          10
#define HASH_LIST_SIZE      (1 << HASH_SHIFT)
#define pid_hashfn(x)       (hash32(x, HASH_SHIFT))

// has list for process set based on pid
static list_entry_t hash_list[HASH_LIST_SIZE];

// idle proc
struct proc_struct *idleproc = NULL;
// init proc
struct proc_struct *initproc = NULL;
// current proc
struct proc_struct *current = NULL;

static int nr_process = 0;

void kernel_thread_entry(void);
void forkrets(struct trapframe *tf);
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void) {
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct)); // 分配一个proc_struct结构体的内存
    if (proc != NULL) {
    //LAB4:EXERCISE1 你的代码
    /*
     * 下面的字段需要在 proc_struct 中初始化
     *       enum proc_state state;                      // 进程状态
     *       int pid;                                    // 进程ID
     *       int runs;                                   // 进程运行次数
     *       uintptr_t kstack;                           // 进程内核栈
     *       volatile bool need_resched;                 // 布尔值：是否需要重新调度以释放CPU？
     *       struct proc_struct *parent;                 // 父进程
     *       struct mm_struct *mm;                       // 进程的内存管理字段
     *       struct context context;                     // 切换到这里运行进程
     *       struct trapframe *tf;                       // 当前中断的陷阱帧
     *       uintptr_t cr3;                              // CR3寄存器：页目录表(PDT)的基地址
     *       uint32_t flags;                             // 进程标志
     *       char name[PROC_NAME_LEN + 1];               // 进程名称
     */

     //LAB5 你的代码 : (更新 LAB4 步骤)
     /*
     * 下面的字段（在LAB5中添加）需要在 proc_struct 中初始化  
     *       uint32_t wait_state;                        // 等待状态
     *       struct proc_struct *cptr, *yptr, *optr;     // 进程之间的关系
     */
        proc->state = PROC_UNINIT; // 初始化进程状态为未初始化
        proc->pid = -1; // 初始化进程ID为-1
        proc->runs = 0; // 初始化进程运行次数为0
        proc->kstack = 0; // 初始化内核栈指针为0
        proc->need_resched = 0; // 初始化是否需要重新调度标志为0
        proc->parent = NULL; // 初始化父进程指针为NULL
        proc->mm = NULL; // 初始化内存管理结构体指针为NULL
        memset(&(proc->context), 0, sizeof(struct context)); // 将上下文结构体清零
        proc->tf = NULL; // 初始化trapframe指针为NULL
        proc->cr3 = boot_cr3; // 初始化CR3寄存器为boot_cr3
        proc->flags = 0; // 初始化进程标志为0
        memset(proc->name, 0, PROC_NAME_LEN); // 将进程名清零
        proc->wait_state = 0; // 初始化等待状态为0
        proc->cptr = NULL; // 初始化子进程指针为NULL
        proc->optr = NULL; // 初始化老兄弟进程指针为NULL
        proc->yptr = NULL; // 初始化年轻兄弟进程指针为NULL
    }
    return proc; // 返回分配并初始化的proc_struct结构体指针
}

// set_proc_name - set the name of proc
char *
set_proc_name(struct proc_struct *proc, const char *name) {
    memset(proc->name, 0, sizeof(proc->name)); // 将proc->name的内存清零
    return memcpy(proc->name, name, PROC_NAME_LEN); // 将name复制到proc->name中，长度为PROC_NAME_LEN
}

// get_proc_name - get the name of proc
char *
// 获取进程名称 - 获取进程的名称
get_proc_name(struct proc_struct *proc) {
    static char name[PROC_NAME_LEN + 1]; // 定义一个静态字符数组，用于存储进程名称
    memset(name, 0, sizeof(name)); // 将字符数组的内存清零
    return memcpy(name, proc->name, PROC_NAME_LEN); // 将进程名称复制到字符数组中，并返回字符数组的指针
}

// set_links - set the relation links of process
static void
set_links(struct proc_struct *proc) {
    list_add(&proc_list, &(proc->list_link)); // 将进程插入到进程链表中
    proc->yptr = NULL; // 初始化年轻兄弟进程指针为NULL
    if ((proc->optr = proc->parent->cptr) != NULL) { // 如果父进程的子进程不为空，则将当前进程的老兄弟指针指向父进程的子进程
        proc->optr->yptr = proc; // 将父进程的子进程的年轻兄弟指针指向当前进程
    }
    proc->parent->cptr = proc; // 将父进程的子进程指针指向当前进程
    nr_process ++; // 进程数量加1
}

// remove_links - clean the relation links of process
static void
remove_links(struct proc_struct *proc) {
    list_del(&(proc->list_link)); // 从进程链表中删除当前进程
    if (proc->optr != NULL) { // 如果当前进程有老兄弟进程
        proc->optr->yptr = proc->yptr; // 将老兄弟进程的年轻兄弟指针指向当前进程的年轻兄弟
    }
    if (proc->yptr != NULL) { // 如果当前进程有年轻兄弟进程
        proc->yptr->optr = proc->optr; // 将年轻兄弟进程的老兄弟指针指向当前进程的老兄弟
    }
    else { // 如果当前进程没有年轻兄弟进程
       proc->parent->cptr = proc->optr; // 将父进程的子进程指针指向当前进程的老兄弟
    }
    nr_process --; // 进程数量减1
}

// get_pid - alloc a unique pid for process
static int
get_pid(void) {
    static_assert(MAX_PID > MAX_PROCESS); // 确保最大PID大于最大进程数
    struct proc_struct *proc; // 定义一个进程结构体指针
    list_entry_t *list = &proc_list, *le; // 定义两个链表指针，分别指向进程链表和链表元素
    static int next_safe = MAX_PID, last_pid = MAX_PID; // 定义两个静态变量，分别表示下一个安全的PID和最后一个分配的PID
    if (++ last_pid >= MAX_PID) { // 如果最后一个分配的PID加1后大于等于最大PID
        last_pid = 1; // 将最后一个分配的PID重置为1
        goto inside; // 跳转到inside标签
    }
    if (last_pid >= next_safe) { // 如果最后一个分配的PID大于等于下一个安全的PID
    inside: // inside标签
        next_safe = MAX_PID; // 将下一个安全的PID重置为最大PID
    repeat: // repeat标签
        le = list; // 将链表元素指针重置为链表指针
        while ((le = list_next(le)) != list) { // 遍历链表中的每个元素
            proc = le2proc(le, list_link); // 获取链表元素对应的进程结构体指针
            if (proc->pid == last_pid) { // 如果进程的PID等于最后一个分配的PID
                if (++ last_pid >= next_safe) { // 如果最后一个分配的PID加1后大于等于下一个安全的PID
                    if (last_pid >= MAX_PID) { // 如果最后一个分配的PID大于等于最大PID
                        last_pid = 1; // 将最后一个分配的PID重置为1
                    }
                    next_safe = MAX_PID; // 将下一个安全的PID重置为最大PID
                    goto repeat; // 跳转到repeat标签
                }
            }
            else if (proc->pid > last_pid && next_safe > proc->pid) { // 如果进程的PID大于最后一个分配的PID且下一个安全的PID大于进程的PID
                next_safe = proc->pid; // 将下一个安全的PID设置为进程的PID
            }
        }
    }
    return last_pid; // 返回最后一个分配的PID
}

// proc_run - 使进程 "proc" 在 CPU 上运行
// 注意: 在调用 switch_to 之前，应加载 "proc" 的新 PDT 的基地址
void
proc_run(struct proc_struct *proc) {
    if (proc != current) { // 如果目标进程不是当前进程
        // LAB4:EXERCISE3 你的代码
        /*
        * 一些有用的宏、函数和定义，你可以在下面的实现中使用它们。
        * 宏或函数:
        *   local_intr_save():        禁用中断
        *   local_intr_restore():     启用中断
        *   lcr3():                   修改 CR3 寄存器的值
        *   switch_to():              在两个进程之间进行上下文切换
        */
        bool intr_flag; // 定义一个布尔变量用于保存中断状态
        struct proc_struct *prev = current, *next = proc; // 定义两个进程结构体指针，分别指向当前进程和目标进程
        local_intr_save(intr_flag); // 禁用中断并保存当前中断状态
        {
            current = proc; // 将当前进程设置为目标进程
            lcr3(next->cr3); // 加载目标进程的 CR3 寄存器值
            switch_to(&(prev->context), &(next->context)); // 在两个进程之间进行上下文切换
        }
        local_intr_restore(intr_flag); // 恢复之前的中断状态

    }
}

// forkret -- 新线程/进程的第一个内核入口点
// 注意: forkret 的地址在 copy_thread 函数中设置
// 在 switch_to 之后，当前进程将在这里执行。
static void
forkret(void) {
    forkrets(current->tf); // 调用 forkrets 函数，传入当前进程的 trapframe
}

// hash_proc - 将进程添加到进程哈希列表中
static void
hash_proc(struct proc_struct *proc) {
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link)); // 将进程添加到哈希列表中
}

// unhash_proc - 从进程哈希列表中删除进程
static void
unhash_proc(struct proc_struct *proc) {
    list_del(&(proc->hash_link)); // 从哈希链表中删除当前进程的哈希链接
}

// find_proc - 根据pid从进程哈希列表中查找进程
struct proc_struct *
find_proc(int pid) {
    if (0 < pid && pid < MAX_PID) { // 如果pid在有效范围内
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list; // 获取哈希链表的起始位置
        while ((le = list_next(le)) != list) { // 遍历哈希链表
            struct proc_struct *proc = le2proc(le, hash_link); // 获取链表元素对应的进程结构体指针
            if (proc->pid == pid) { // 如果找到匹配的pid
                return proc; // 返回找到的进程结构体指针
            }
        }
    }
    return NULL; // 如果没有找到匹配的pid，返回NULL
}

// kernel_thread - 使用 "fn" 函数创建一个内核线程
// 注意: 临时trapframe tf的内容将被复制到
//       proc->tf 在 do_fork-->copy_thread 函数中
int
kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags) {
    struct trapframe tf; // 定义一个trapframe结构体
    memset(&tf, 0, sizeof(struct trapframe)); // 将trapframe结构体清零
    tf.gpr.s0 = (uintptr_t)fn; // 将函数指针fn的地址赋值给trapframe的s0寄存器
    tf.gpr.s1 = (uintptr_t)arg; // 将参数arg的地址赋值给trapframe的s1寄存器
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE; // 设置trapframe的status寄存器
    tf.epc = (uintptr_t)kernel_thread_entry; // 将kernel_thread_entry的地址赋值给trapframe的epc寄存器
    return do_fork(clone_flags | CLONE_VM, 0, &tf); // 调用do_fork函数创建子进程，并返回子进程的pid
}

// setup_kstack - 分配大小为KSTACKPAGE的页作为进程内核栈
static int
setup_kstack(struct proc_struct *proc) {
    struct Page *page = alloc_pages(KSTACKPAGE); // 分配KSTACKPAGE大小的页
    if (page != NULL) { // 如果分配成功
        proc->kstack = (uintptr_t)page2kva(page); // 将页的虚拟地址赋值给进程的kstack字段
        return 0; // 返回0表示成功
    }
    return -E_NO_MEM; // 返回-E_NO_MEM表示内存不足
}

// put_kstack - 释放进程内核栈的内存空间
static void
put_kstack(struct proc_struct *proc) {
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE); // 释放进程内核栈的页
}

// setup_pgdir - 分配一页作为页目录表
static int
setup_pgdir(struct mm_struct *mm) {
    struct Page *page; // 定义一个页结构体指针
    if ((page = alloc_page()) == NULL) { // 分配一页内存，如果失败返回-E_NO_MEM
        return -E_NO_MEM; // 返回内存不足错误码
    }
    pde_t *pgdir = page2kva(page); // 获取页的虚拟地址
    memcpy(pgdir, boot_pgdir, PGSIZE); // 将boot_pgdir复制到新分配的页中

    mm->pgdir = pgdir; // 将新分配的页地址赋值给mm结构体的pgdir字段
    return 0; // 返回0表示成功
}

// put_pgdir - 释放页目录表的内存空间
static void
put_pgdir(struct mm_struct *mm) {
    free_page(kva2page(mm->pgdir)); // 释放页目录表的页
}

// copy_mm - 根据clone_flags，进程"proc"复制或共享进程"current"的mm
//         - 如果clone_flags & CLONE_VM，则"共享"；否则"复制"
static int
copy_mm(uint32_t clone_flags, struct proc_struct *proc) {
    struct mm_struct *mm, *oldmm = current->mm; // 定义两个内存管理结构体指针，分别指向当前进程的mm和新进程的mm

    /* current是一个内核线程 */
    if (oldmm == NULL) { // 如果当前进程的mm为空
        return 0; // 返回0表示成功
    }
    if (clone_flags & CLONE_VM) { // 如果clone_flags包含CLONE_VM标志
        mm = oldmm; // 将新进程的mm设置为当前进程的mm
        goto good_mm; // 跳转到good_mm标签
    }
    int ret = -E_NO_MEM; // 定义一个返回值变量，初始值为内存不足错误码
    if ((mm = mm_create()) == NULL) { // 创建一个新的内存管理结构体，如果失败则跳转到bad_mm标签
        goto bad_mm; // 跳转到bad_mm标签
    }
    if (setup_pgdir(mm) != 0) { // 设置页目录表，如果失败则跳转到bad_pgdir_cleanup_mm标签
        goto bad_pgdir_cleanup_mm; // 跳转到bad_pgdir_cleanup_mm标签
    }
    lock_mm(oldmm); // 锁定当前进程的mm
    {
        ret = dup_mmap(mm, oldmm); // 复制当前进程的内存映射到新进程的mm
    }
    unlock_mm(oldmm); // 解锁当前进程的mm

    if (ret != 0) { // 如果复制内存映射失败
        goto bad_dup_cleanup_mmap; // 跳转到bad_dup_cleanup_mmap标签
    }

good_mm:
    mm_count_inc(mm); // 增加新进程的mm的引用计数
    proc->mm = mm; // 将新进程的mm设置为新创建的mm
    proc->cr3 = PADDR(mm->pgdir); // 将新进程的cr3设置为新创建的页目录表的物理地址
    return 0; // 返回0表示成功
bad_dup_cleanup_mmap:
    exit_mmap(mm); // 退出内存映射
    put_pgdir(mm); // 释放页目录表
bad_pgdir_cleanup_mm:
    mm_destroy(mm); // 销毁内存管理结构体
bad_mm:
    return ret; // 返回错误码
}

// copy_thread - 在进程的内核栈顶设置trapframe
//             - 设置进程的内核入口点和栈
static void
copy_thread(struct proc_struct *proc, uintptr_t esp, struct trapframe *tf) {
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1; // 将新进程的trapframe设置为内核栈顶
    *(proc->tf) = *tf; // 复制当前进程的trapframe到新进程的trapframe

    // 将a0设置为0，以便子进程知道它刚刚被fork
    proc->tf->gpr.a0 = 0; // 将新进程的trapframe的a0寄存器设置为0
    // proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf - 4 : esp; // 设置新进程的栈指针

    proc->context.ra = (uintptr_t)forkret; // 设置新进程的返回地址为forkret函数
    proc->context.sp = (uintptr_t)(proc->tf); // 设置新进程的栈指针为trapframe的地址
}

/* do_fork -     为一个新的子进程创建父进程
 * @clone_flags: 用于指导如何克隆子进程
 * @stack:       父进程的用户栈指针。如果 stack==0，表示 fork 一个内核线程。
 * @tf:          trapframe 信息，将被复制到子进程的 proc->tf
 */
int
do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf) {
    int ret = -E_NO_FREE_PROC; // 初始化返回值为没有可用进程错误码
    struct proc_struct *proc; // 定义一个进程结构体指针
    if (nr_process >= MAX_PROCESS) { // 如果当前进程数大于等于最大进程数
        goto fork_out; // 跳转到 fork_out 标签
    }
    ret = -E_NO_MEM; // 初始化返回值为内存不足错误码
    //LAB4:EXERCISE2 你的代码
    /*
     * 一些有用的宏、函数和定义，你可以在下面的实现中使用它们。
     * 宏或函数:
     *   alloc_proc:   创建一个进程结构体并初始化字段 (lab4:exercise1)
     *   setup_kstack: 分配大小为 KSTACKPAGE 的页作为进程内核栈
     *   copy_mm:      根据 clone_flags 复制或共享进程 "current" 的 mm
     *                 如果 clone_flags & CLONE_VM，则 "共享"；否则 "复制"
     *   copy_thread:  在进程的内核栈顶设置 trapframe 并
     *                 设置进程的内核入口点和栈
     *   hash_proc:    将进程添加到进程哈希列表中
     *   get_pid:      分配一个唯一的进程 ID
     *   wakeup_proc:  设置进程状态为 PROC_RUNNABLE
     * 变量:
     *   proc_list:    进程集合的列表
     *   nr_process:   进程集合的数量
     */

    //    1. 调用 alloc_proc 分配一个进程结构体
    //    2. 调用 setup_kstack 为子进程分配一个内核栈
    //    3. 调用 copy_mm 根据 clone_flag 复制或共享 mm
    //    4. 调用 copy_thread 在进程结构体中设置 tf 和 context
    //    5. 将进程结构体插入到哈希列表和进程列表中
    //    6. 调用 wakeup_proc 使新子进程变为 RUNNABLE
    //    7. 使用子进程的 pid 设置返回值

    //LAB5 你的代码 : (更新 LAB4 步骤)
    //提示: 你应该修改你在 lab4 中编写的代码（步骤1和步骤5），而不是添加更多代码。
   /* 一些函数
    *    set_links:  设置进程的关系链接。 另见: remove_links:  清理进程的关系链接
    *    -------------------
    *    更新步骤 1: 将子进程的父进程设置为当前进程，确保当前进程的 wait_state 为 0
    *    更新步骤 5: 将进程结构体插入到哈希列表和进程列表中，设置进程的关系链接
    */
    if((proc = alloc_proc()) == NULL) { // 调用 alloc_proc 分配一个进程结构体，如果失败则跳转到 fork_out 标签
        goto fork_out; // 跳转到 fork_out 标签
    }
    proc->parent = current; // 将子进程的父进程设置为当前进程,添加
    assert(current->wait_state == 0); // 确保当前进程的 wait_state 为 0
    if(setup_kstack(proc) != 0) { // 调用 setup_kstack 为子进程分配一个内核栈，如果失败则跳转到 bad_fork_cleanup_proc 标签
        goto bad_fork_cleanup_proc; // 跳转到 bad_fork_cleanup_proc 标签
    }
    // if(copy_mm(clone_flags, proc) != 0) { // 调用 copy_mm 根据 clone_flags 复制或共享 mm，如果失败则跳转到 bad_fork_cleanup_kstack 标签
    //     goto bad_fork_cleanup_kstack; // 跳转到 bad_fork_cleanup_kstack 标签
    // }
    if(cow_copy_mm(proc) != 0) {
        goto bad_fork_cleanup_kstack;
    }
    copy_thread(proc, stack, tf); // 调用 copy_thread 在进程结构体中设置 tf 和 context
    bool intr_flag; // 定义一个布尔变量用于保存中断状态
    local_intr_save(intr_flag); // 禁用中断并保存当前中断状态
    {
        proc->pid = get_pid(); // 调用 get_pid 分配一个唯一的进程 ID
        hash_proc(proc); // 调用 hash_proc 将进程添加到进程哈希列表中
        set_links(proc); // 调用 set_links 设置进程的关系链接
    }
    local_intr_restore(intr_flag); // 恢复之前的中断状态
    wakeup_proc(proc); // 调用 wakeup_proc 使新子进程变为 RUNNABLE
    ret = proc->pid; // 使用子进程的 pid 设置返回值
 
fork_out:
    return ret; // 返回结果

bad_fork_cleanup_kstack:
    put_kstack(proc); // 调用 put_kstack 释放子进程的内核栈
bad_fork_cleanup_proc:
    kfree(proc); // 调用 kfree 释放子进程的内存
    goto fork_out; // 跳转到 fork_out 标签
}

// do_exit - 由 sys_exit 调用
//   1. 调用 exit_mmap & put_pgdir & mm_destroy 来释放几乎所有的进程内存空间
//   2. 将进程状态设置为 PROC_ZOMBIE，然后调用 wakeup_proc(parent) 请求父进程回收自身。
//   3. 调用调度程序切换到其他进程
int
do_exit(int error_code) {
    if (current == idleproc) { // 如果当前进程是 idleproc，则触发 panic
        panic("idleproc exit.\n");
    }
    if (current == initproc) { // 如果当前进程是 initproc，则触发 panic
        panic("initproc exit.\n");
    }
    struct mm_struct *mm = current->mm; // 获取当前进程的内存管理结构体
    if (mm != NULL) { // 如果内存管理结构体不为空
        lcr3(boot_cr3); // 切换到 boot_cr3
        if (mm_count_dec(mm) == 0) { // 如果内存管理结构体的引用计数为0
            exit_mmap(mm); // 退出内存映射
            put_pgdir(mm); // 释放页目录表
            mm_destroy(mm); // 销毁内存管理结构体
        }
        current->mm = NULL; // 将当前进程的内存管理结构体指针置为空
    }
    current->state = PROC_ZOMBIE; // 将当前进程的状态设置为 PROC_ZOMBIE
    current->exit_code = error_code; // 设置当前进程的退出代码
    bool intr_flag; // 定义一个布尔变量用于保存中断状态
    struct proc_struct *proc; // 定义一个进程结构体指针
    local_intr_save(intr_flag); // 禁用中断并保存当前中断状态
    {
        proc = current->parent; // 获取当前进程的父进程
        if (proc->wait_state == WT_CHILD) { // 如果父进程的等待状态为 WT_CHILD
            wakeup_proc(proc); // 唤醒父进程
        }
        while (current->cptr != NULL) { // 遍历当前进程的所有子进程
            proc = current->cptr; // 获取当前进程的子进程
            current->cptr = proc->optr; // 将当前进程的子进程指针指向下一个兄弟进程
    
            proc->yptr = NULL; // 将子进程的年轻兄弟指针置为空
            if ((proc->optr = initproc->cptr) != NULL) { // 如果 initproc 有子进程
                initproc->cptr->yptr = proc; // 将 initproc 的子进程的年轻兄弟指针指向当前子进程
            }
            proc->parent = initproc; // 将子进程的父进程设置为 initproc
            initproc->cptr = proc; // 将 initproc 的子进程指针指向当前子进程
            if (proc->state == PROC_ZOMBIE) { // 如果子进程的状态为 PROC_ZOMBIE
                if (initproc->wait_state == WT_CHILD) { // 如果 initproc 的等待状态为 WT_CHILD
                    wakeup_proc(initproc); // 唤醒 initproc
                }
            }
        }
    }
    local_intr_restore(intr_flag); // 恢复之前的中断状态
    schedule(); // 调用调度程序切换到其他进程
    panic("do_exit will not return!! %d.\n", current->pid); // 触发 panic，do_exit 不会返回
}

/* load_icode - 加载二进制程序（ELF格式）的内容作为当前进程的新内容
 * @binary:  二进制程序内容的内存地址
 * @size:  二进制程序内容的大小
 */
/*
load_icode函数的主要工作就是给用户进程建立一个能够让用户进程正常运行的用户环境。此函数有一百多行，完成了如下重要工作：

调用mm_create函数来申请进程的内存管理数据结构mm所需内存空间，并对mm进行初始化；

调用setup_pgdir来申请一个页目录表所需的一个页大小的内存空间，并把描述ucore内核虚空间映射的内核页表（boot_pgdir所指）的内容拷贝到此新目录表中，最后让mm->pgdir指向此页目录表，这就是进程新的页目录表了，且能够正确映射内核虚空间；

根据应用程序执行码的起始位置来解析此ELF格式的执行程序，并调用mm_map函数根据ELF格式的执行程序说明的各个段（代码段、数据段、BSS段等）的起始位置和大小建立对应的vma结构，并把vma插入到mm结构中，从而表明了用户进程的合法用户态虚拟地址空间；

调用根据执行程序各个段的大小分配物理内存空间，并根据执行程序各个段的起始位置确定虚拟地址，并在页表中建立好物理地址和虚拟地址的映射关系，然后把执行程序各个段的内容拷贝到相应的内核虚拟地址中，至此应用程序执行码和数据已经根据编译时设定地址放置到虚拟内存中了；

需要给用户进程设置用户栈，为此调用mm_mmap函数建立用户栈的vma结构，明确用户栈的位置在用户虚空间的顶端，大小为256个页，即1MB，并分配一定数量的物理内存且建立好栈的虚地址<-->物理地址映射关系；

至此,进程内的内存管理vma和mm数据结构已经建立完成，于是把mm->pgdir赋值到cr3寄存器中，即更新了用户进程的虚拟内存空间，此时的initproc已经被hello的代码和数据覆盖，成为了第一个用户进程，但此时这个用户进程的执行现场还没建立好；

先清空进程的中断帧，再重新设置进程的中断帧，使得在执行中断返回指令“iret”后，能够让CPU转到用户态特权级，并回到用户态内存空间，使用用户态的代码段、数据段和堆栈，且能够跳转到用户进程的第一条指令执行，并确保在用户态能够响应中断；
*/
static int
load_icode(unsigned char *binary, size_t size) {
    if (current->mm != NULL) { // 如果当前进程的内存管理结构体不为空
        panic("load_icode: current->mm must be empty.\n"); // 触发panic，当前进程的内存管理结构体必须为空
    }

    int ret = -E_NO_MEM; // 初始化返回值为内存不足错误码
    struct mm_struct *mm; // 定义一个内存管理结构体指针
    //(1) 为当前进程创建一个新的内存管理结构体
    if ((mm = mm_create()) == NULL) { // 创建一个新的内存管理结构体，如果失败则跳转到bad_mm标签
        goto bad_mm; // 跳转到bad_mm标签
    }
    //(2) 创建一个新的页目录表，并将mm->pgdir设置为页目录表的内核虚拟地址
    if (setup_pgdir(mm) != 0) { // 设置页目录表，如果失败则跳转到bad_pgdir_cleanup_mm标签
        goto bad_pgdir_cleanup_mm; // 跳转到bad_pgdir_cleanup_mm标签
    }
    //(3) 复制TEXT/DATA段，将二进制程序中的BSS部分构建到进程的内存空间中
    struct Page *page; // 定义一个页结构体指针
    //(3.1) 获取二进制程序的文件头（ELF格式）
    struct elfhdr *elf = (struct elfhdr *)binary; // 将二进制程序的内容转换为ELF文件头结构体指针
    //(3.2) 获取二进制程序的程序段头表的入口（ELF格式）
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff); // 获取程序段头表的入口地址
    //(3.3) 这个程序是有效的吗？
    if (elf->e_magic != ELF_MAGIC) { // 如果ELF文件头的魔数不匹配
        ret = -E_INVAL_ELF; // 设置返回值为无效的ELF错误码
        goto bad_elf_cleanup_pgdir; // 跳转到bad_elf_cleanup_pgdir标签
    }

    uint32_t vm_flags, perm; // 定义两个变量用于存储虚拟内存标志和权限
    struct proghdr *ph_end = ph + elf->e_phnum; // 获取程序段头表的结束地址
    for (; ph < ph_end; ph ++) { // 遍历每个程序段头
    //(3.4) 找到每个程序段头
        if (ph->p_type != ELF_PT_LOAD) { // 如果程序段头的类型不是可加载段
            continue ; // 跳过当前程序段头
        }
        if (ph->p_filesz > ph->p_memsz) { // 如果程序段头的文件大小大于内存大小
            ret = -E_INVAL_ELF; // 设置返回值为无效的ELF错误码
            goto bad_cleanup_mmap; // 跳转到bad_cleanup_mmap标签
        }
        if (ph->p_filesz == 0) { // 如果程序段头的文件大小为0
            // continue ;
        }
    //(3.5) 调用mm_map函数设置新的虚拟内存区域（ph->p_va, ph->p_memsz）
        vm_flags = 0, perm = PTE_U | PTE_V; // 初始化虚拟内存标志和权限
        if (ph->p_flags & ELF_PF_X) vm_flags |= VM_EXEC; // 如果程序段头的标志包含可执行标志，则设置虚拟内存标志为可执行
        if (ph->p_flags & ELF_PF_W) vm_flags |= VM_WRITE; // 如果程序段头的标志包含可写标志，则设置虚拟内存标志为可写
        if (ph->p_flags & ELF_PF_R) vm_flags |= VM_READ; // 如果程序段头的标志包含可读标志，则设置虚拟内存标志为可读
        // 修改RISC-V的权限位
        if (vm_flags & VM_READ) perm |= PTE_R; // 如果虚拟内存标志包含可读标志，则设置权限为可读
        if (vm_flags & VM_WRITE) perm |= (PTE_W | PTE_R); // 如果虚拟内存标志包含可写标志，则设置权限为可写和可读
        if (vm_flags & VM_EXEC) perm |= PTE_X; // 如果虚拟内存标志包含可执行标志，则设置权限为可执行
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0) { // 调用mm_map函数设置新的虚拟内存区域，如果失败则跳转到bad_cleanup_mmap标签
            goto bad_cleanup_mmap; // 跳转到bad_cleanup_mmap标签
        }
        unsigned char *from = binary + ph->p_offset; // 获取程序段头的偏移地址
        size_t off, size; // 定义两个变量用于存储偏移量和大小
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE); // 获取程序段头的虚拟地址起始位置和结束位置，并将起始位置向下取整到页边界

        ret = -E_NO_MEM; // 设置返回值为内存不足错误码

     //(3.6) 分配内存，并将每个程序段的内容（from, from+end）复制到进程的内存（la, la+end）中
        end = ph->p_va + ph->p_filesz; // 获取程序段头的文件大小结束位置
     //(3.6.1) 复制二进制程序的TEXT/DATA段
        while (start < end) { // 遍历每个页
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL) { // 分配页，如果失败则跳转到bad_cleanup_mmap标签
                goto bad_cleanup_mmap; // 跳转到bad_cleanup_mmap标签
            }
            off = start - la, size = PGSIZE - off, la += PGSIZE; // 计算偏移量和大小，并更新虚拟地址
            if (end < la) { // 如果结束位置小于虚拟地址
                size -= la - end; // 更新大小
            }
            memcpy(page2kva(page) + off, from, size); // 将二进制程序的内容复制到页中
            start += size, from += size; // 更新起始位置和偏移地址
        }

      //(3.6.2) 构建二进制程序的BSS段
        end = ph->p_va + ph->p_memsz; // 获取程序段头的内存大小结束位置
        if (start < la) { // 如果起始位置小于虚拟地址
            /* ph->p_memsz == ph->p_filesz */
            if (start == end) { // 如果起始位置等于结束位置
                continue ; // 跳过当前程序段头
            }
            off = start + PGSIZE - la, size = PGSIZE - off; // 计算偏移量和大小
            if (end < la) { // 如果结束位置小于虚拟地址
                size -= la - end; // 更新大小
            }
            memset(page2kva(page) + off, 0, size); // 将页中的内容清零
            start += size; // 更新起始位置
            assert((end < la && start == end) || (end >= la && start == la)); // 断言结束位置和起始位置的关系
        }
        while (start < end) { // 遍历每个页
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL) { // 分配页，如果失败则跳转到bad_cleanup_mmap标签
                goto bad_cleanup_mmap; // 跳转到bad_cleanup_mmap标签
            }
            off = start - la, size = PGSIZE - off, la += PGSIZE; // 计算偏移量和大小，并更新虚拟地址
            if (end < la) { // 如果结束位置小于虚拟地址
                size -= la - end; // 更新大小
            }
            memset(page2kva(page) + off, 0, size); // 将页中的内容清零
            start += size; // 更新起始位置
        }
    }
    //(4) 构建用户栈内存
    vm_flags = VM_READ | VM_WRITE | VM_STACK; // 设置虚拟内存标志为可读、可写和栈
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0) { // 调用mm_map函数设置新的虚拟内存区域，如果失败则跳转到bad_cleanup_mmap标签
        goto bad_cleanup_mmap; // 跳转到bad_cleanup_mmap标签
    }
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-PGSIZE , PTE_USER) != NULL); // 断言分配页成功
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-2*PGSIZE , PTE_USER) != NULL); // 断言分配页成功
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-3*PGSIZE , PTE_USER) != NULL); // 断言分配页成功
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-4*PGSIZE , PTE_USER) != NULL); // 断言分配页成功
    
    //(5) 设置当前进程的内存管理结构体、sr3，并设置CR3寄存器为页目录表的物理地址
    mm_count_inc(mm); // 增加内存管理结构体的引用计数
    current->mm = mm; // 将当前进程的内存管理结构体设置为新创建的内存管理结构体
    current->cr3 = PADDR(mm->pgdir); // 将当前进程的CR3寄存器设置为页目录表的物理地址
    lcr3(PADDR(mm->pgdir)); // 加载CR3寄存器

    //(6) 为用户环境设置trapframe
    struct trapframe *tf = current->tf; // 获取当前进程的trapframe
    // 保持sstatus
    uintptr_t sstatus = tf->status; // 获取当前trapframe的status寄存器
    memset(tf, 0, sizeof(struct trapframe)); // 将trapframe清零
    /* LAB5:EXERCISE1 你的代码
     * 应该设置tf->gpr.sp, tf->epc, tf->status
     * 注意：如果我们正确设置trapframe，那么用户级进程可以从内核返回到用户模式。所以
     *          tf->gpr.sp应该是用户栈顶（sp的值）
     *          tf->epc应该是用户程序的入口点（sepc的值）
     *          tf->status应该适合用户程序（sstatus的值）
     *          提示：检查SPP、SPIE在SSTATUS中的含义，通过SSTATUS_SPP、SSTATUS_SPIE（在risv.h中定义）使用它们
     */

    tf->gpr.sp = USTACKTOP; // 设置trapframe的栈指针为用户栈顶
    tf->epc = elf->e_entry; // 设置trapframe的程序计数器为ELF文件头的入口点
    // sstatus &= ~SSTATUS_SPP;
    // sstatus &= SSTATUS_SPIE;
    // tf->status = sstatus;
    tf->status = sstatus & ~(SSTATUS_SPP | SSTATUS_SPIE); // 设置trapframe的status寄存器

    ret = 0; // 设置返回值为0
out:
    return ret; // 返回结果
bad_cleanup_mmap:
    exit_mmap(mm); // 退出内存映射
bad_elf_cleanup_pgdir:
    put_pgdir(mm); // 释放页目录表
bad_pgdir_cleanup_mm:
    mm_destroy(mm); // 销毁内存管理结构体
bad_mm:
    goto out; // 跳转到out标签
}

// do_execve - 调用 exit_mmap(mm) 和 put_pgdir(mm) 来回收当前进程的内存空间
//           - 调用 load_icode 来根据二进制程序设置新的内存空间
int
do_execve(const char *name, size_t len, unsigned char *binary, size_t size) {
    struct mm_struct *mm = current->mm; // 获取当前进程的内存管理结构体
    if (!user_mem_check(mm, (uintptr_t)name, len, 0)) { // 检查用户内存是否合法
        return -E_INVAL; // 如果不合法，返回 -E_INVAL 错误码
    }
    if (len > PROC_NAME_LEN) { // 如果名称长度大于最大进程名称长度
        len = PROC_NAME_LEN; // 将名称长度设置为最大进程名称长度
    }

    char local_name[PROC_NAME_LEN + 1]; // 定义一个局部字符数组，用于存储进程名称
    memset(local_name, 0, sizeof(local_name)); // 将字符数组清零
    memcpy(local_name, name, len); // 将名称复制到字符数组中

    if (mm != NULL) { // 如果内存管理结构体不为空
        cputs("mm != NULL"); // 打印调试信息
        lcr3(boot_cr3); // 切换到 boot_cr3
        if (mm_count_dec(mm) == 0) { // 如果内存管理结构体的引用计数为 0
            exit_mmap(mm); // 退出内存映射
            put_pgdir(mm); // 释放页目录表
            mm_destroy(mm); // 销毁内存管理结构体
        }
        current->mm = NULL; // 将当前进程的内存管理结构体指针置为空
    }
    int ret; // 定义一个返回值变量
    if ((ret = load_icode(binary, size)) != 0) { // 调用 load_icode 加载二进制程序，如果失败则跳转到 execve_exit 标签
        goto execve_exit; // 跳转到 execve_exit 标签
    }
    set_proc_name(current, local_name); // 设置当前进程的名称
    return 0; // 返回 0 表示成功

execve_exit:
    do_exit(ret); // 调用 do_exit 退出当前进程
    panic("already exit: %e.\n", ret); // 触发 panic，已经退出
}

// do_yield - 请求调度程序重新调度
int
do_yield(void) {
    current->need_resched = 1; // 设置当前进程需要重新调度标志为1
    return 0; // 返回0表示成功
}

// do_wait - 等待一个或任何子进程进入PROC_ZOMBIE状态，并释放内核栈的内存空间
//         - 子进程的proc结构体。
// 注意：只有在do_wait函数之后，子进程的所有资源才会被释放。
/*只有一个usermain是他子进程，而且这个
子进程的状态也不是僵尸进程，所以会将当前进程状态设置为sleeping
等待状态设为WT_CHILD，并调
用schedule函数进行调度*/
int
do_wait(int pid, int *code_store) {
    struct mm_struct *mm = current->mm; // 获取当前进程的内存管理结构体
    if (code_store != NULL) { // 如果code_store不为空
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1)) { // 检查用户内存是否合法
            return -E_INVAL; // 如果不合法，返回-E_INVAL错误码
        }
    }

    struct proc_struct *proc; // 定义一个进程结构体指针
    bool intr_flag, haskid; // 定义两个布尔变量用于保存中断状态和是否有子进程
repeat:
    haskid = 0; // 初始化是否有子进程标志为0
    if (pid != 0) { // 如果pid不为0
        proc = find_proc(pid); // 根据pid查找进程
        if (proc != NULL && proc->parent == current) { // 如果找到的进程不为空且其父进程是当前进程
            haskid = 1; // 设置是否有子进程标志为1
            if (proc->state == PROC_ZOMBIE) { // 如果进程状态为PROC_ZOMBIE
                goto found; // 跳转到found标签
            }
        }
    }
    else { // 如果pid为0
        proc = current->cptr; // 获取当前进程的子进程
        for (; proc != NULL; proc = proc->optr) { // 遍历所有子进程
            haskid = 1; // 设置是否有子进程标志为1
            if (proc->state == PROC_ZOMBIE) { // 如果进程状态为PROC_ZOMBIE
                goto found; // 跳转到found标签
            }
        }
    }
    if (haskid) { // 如果有子进程
        current->state = PROC_SLEEPING; // 将当前进程状态设置为PROC_SLEEPING
        current->wait_state = WT_CHILD; // 将当前进程的等待状态设置为WT_CHILD
        schedule(); // 调用调度程序进行调度
        if (current->flags & PF_EXITING) { // 如果当前进程的标志包含PF_EXITING
            do_exit(-E_KILLED); // 调用do_exit函数退出当前进程
        }
        goto repeat; // 跳转到repeat标签
    }
    return -E_BAD_PROC; // 返回-E_BAD_PROC错误码

found:
    if (proc == idleproc || proc == initproc) { // 如果进程是idleproc或initproc
        panic("wait idleproc or initproc.\n"); // 触发panic，不能等待idleproc或initproc
    }
    if (code_store != NULL) { // 如果code_store不为空
        *code_store = proc->exit_code; // 将进程的退出代码存储到code_store中
    }
    local_intr_save(intr_flag); // 禁用中断并保存当前中断状态
    {
        unhash_proc(proc); // 从进程哈希列表中删除进程
        remove_links(proc); // 清理进程的关系链接
    }
    local_intr_restore(intr_flag); // 恢复之前的中断状态
    put_kstack(proc); // 释放进程的内核栈
    kfree(proc); // 释放进程的内存
    return 0; // 返回0表示成功
}

// do_kill - 通过设置进程的标志为 PF_EXITING 来杀死具有 pid 的进程
int
do_kill(int pid) {
    struct proc_struct *proc; // 定义一个进程结构体指针
    if ((proc = find_proc(pid)) != NULL) { // 如果找到具有 pid 的进程
        if (!(proc->flags & PF_EXITING)) { // 如果进程的标志不包含 PF_EXITING
            proc->flags |= PF_EXITING; // 设置进程的标志为 PF_EXITING
            if (proc->wait_state & WT_INTERRUPTED) { // 如果进程的等待状态包含 WT_INTERRUPTED
                wakeup_proc(proc); // 唤醒进程
            }
            return 0; // 返回 0 表示成功
        }
        return -E_KILLED; // 返回 -E_KILLED 表示进程已经被杀死
    }
    return -E_INVAL; // 返回 -E_INVAL 表示无效的 pid
}

// kernel_execve - 由 user_main 内核线程调用的 SYS_exec 系统调用，用于执行用户程序
static int
kernel_execve(const char *name, unsigned char *binary, size_t size) {
    int64_t ret=0, len = strlen(name); // 定义返回值变量和名称长度变量，并初始化
 //   ret = do_execve(name, len, binary, size);
    asm volatile( // 内联汇编代码块
        "li a0, %1\n" // 将 SYS_exec 的值加载到 a0 寄存器
        "lw a1, %2\n" // 将 name 的值加载到 a1 寄存器
        "lw a2, %3\n" // 将 len 的值加载到 a2 寄存器
        "lw a3, %4\n" // 将 binary 的值加载到 a3 寄存器
        "lw a4, %5\n" // 将 size 的值加载到 a4 寄存器
        "li a7, 10\n" // 将系统调用号 10 加载到 a7 寄存器
        "ebreak\n" // 触发断点异常，执行系统调用,转到`__alltraps`处理
        "sw a0, %0\n" // 将系统调用的返回值存储到 ret 变量
        : "=m"(ret) // 输出操作数
        : "i"(SYS_exec), "m"(name), "m"(len), "m"(binary), "m"(size) // 输入操作数
        : "memory"); // 告诉编译器内存已被修改
    cprintf("ret = %d\n", ret); // 打印返回值
    return ret; // 返回结果
}

#define __KERNEL_EXECVE(name, binary, size) ({                          \
            cprintf("kernel_execve: pid = %d, name = \"%s\".\n",        \
                    current->pid, name);                                \
            kernel_execve(name, binary, (size_t)(size));                \
        }) // 定义一个宏，用于执行内核中的 execve 函数，打印当前进程的 pid 和名称，并调用 kernel_execve 函数

#define KERNEL_EXECVE(x) ({                                             \
            extern unsigned char _binary_obj___user_##x##_out_start[],  \
                _binary_obj___user_##x##_out_size[];                    \
            __KERNEL_EXECVE(#x, _binary_obj___user_##x##_out_start,     \
                            _binary_obj___user_##x##_out_size);         \
        }) // 定义一个宏，用于执行内核中的 execve 函数，传入用户程序的二进制起始地址和大小

#define __KERNEL_EXECVE2(x, xstart, xsize) ({                           \
            extern unsigned char xstart[], xsize[];                     \
            __KERNEL_EXECVE(#x, xstart, (size_t)xsize);                 \
        }) // 定义一个宏，用于执行内核中的 execve 函数，传入用户程序的二进制起始地址和大小

#define KERNEL_EXECVE2(x, xstart, xsize)        __KERNEL_EXECVE2(x, xstart, xsize) // 定义一个宏，用于执行内核中的 execve 函数，传入用户程序的二进制起始地址和大小

// user_main - 内核线程，用于执行用户程序
static int
user_main(void *arg) {
#ifdef TEST
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE); // 如果定义了 TEST 宏，则执行 TEST 程序
#else
    KERNEL_EXECVE(exit); // 否则执行 exit 程序
#endif
    panic("user_main execve failed.\n"); // 如果 execve 失败，则触发 panic
}

// init_main - 第二个内核线程，用于创建 user_main 内核线程
static int
init_main(void *arg) {
    size_t nr_free_pages_store = nr_free_pages(); // 获取当前空闲页的数量
    size_t kernel_allocated_store = kallocated(); // 获取当前内核分配的内存数量

    int pid = kernel_thread(user_main, NULL, 0); // 创建 user_main 内核线程
    if (pid <= 0) { // 如果创建失败
        panic("create user_main failed.\n"); // 触发 panic，创建 user_main 失败
    }

    while (do_wait(0, NULL) == 0) { // 等待所有子进程退出
        schedule(); // 调用调度程序进行调度
    }

    cprintf("all user-mode processes have quit.\n"); // 打印所有用户模式进程已退出
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL); // 确保 initproc 没有子进程
    assert(nr_process == 2); // 确保进程数量为 2
    assert(list_next(&proc_list) == &(initproc->list_link)); // 确保进程列表中只有 initproc
    assert(list_prev(&proc_list) == &(initproc->list_link)); // 确保进程列表中只有 initproc

    cprintf("init check memory pass.\n"); // 打印内存检查通过
    return 0; // 返回 0 表示成功
}

// proc_init - 通过自身设置第一个内核线程 idleproc "idle"
//           - 创建第二个内核线程 init_main
void
proc_init(void) {
    int i; // 定义一个整型变量 i

    list_init(&proc_list); // 初始化进程列表
    for (i = 0; i < HASH_LIST_SIZE; i ++) { // 遍历哈希列表大小
        list_init(hash_list + i); // 初始化每个哈希列表
    }

    if ((idleproc = alloc_proc()) == NULL) { // 分配 idleproc，如果失败则触发 panic
        panic("cannot alloc idleproc.\n"); // 触发 panic，无法分配 idleproc
    }

    idleproc->pid = 0; // 设置 idleproc 的 pid 为 0
    idleproc->state = PROC_RUNNABLE; // 设置 idleproc 的状态为可运行
    idleproc->kstack = (uintptr_t)bootstack; // 设置 idleproc 的内核栈为 bootstack
    idleproc->need_resched = 1; // 设置 idleproc 需要重新调度
    set_proc_name(idleproc, "idle"); // 设置 idleproc 的名称为 "idle"
    nr_process ++; // 进程数量加 1

    current = idleproc; // 将当前进程设置为 idleproc

    int pid = kernel_thread(init_main, NULL, 0); // 创建 init_main 内核线程
    if (pid <= 0) { // 如果创建失败
        panic("create init_main failed.\n"); // 触发 panic，创建 init_main 失败
    }

    initproc = find_proc(pid); // 查找 initproc
    set_proc_name(initproc, "init"); // 设置 initproc 的名称为 "init"

    assert(idleproc != NULL && idleproc->pid == 0); // 确保 idleproc 不为空且 pid 为 0
    assert(initproc != NULL && initproc->pid == 1); // 确保 initproc 不为空且 pid 为 1
}

// cpu_idle - 在 kern_init 的末尾，第一个内核线程 idleproc 将执行以下工作
void
cpu_idle(void) {
    while (1) { // 无限循环
        if (current->need_resched) { // 如果当前进程需要重新调度
            schedule(); // 调用调度程序进行调度
        }
    }
}