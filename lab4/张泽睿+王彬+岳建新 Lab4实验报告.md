<h1 align = "center">操作系统实验报告</h1>

<h3 align = "center">实验名称：进程管理    </h3>

<h4 align = "center">组号：46      小组成员：张泽睿  王彬  岳建新</h4>

## 一、实验目的

* 了解内核线程创建/执行的管理过程

* 了解内核线程的切换和基本调度过程

## 二、实验过程

### 1.练习1：分配并初始化一个进程控制块（需要编码）

*alloc_proc 函数（位于 kern/process/proc.c 中）负责分配并返回一个新的 struct proc_struct 结构，用于存储新建 立的内核线程的管理信息。ucore 需要对这个结构进行最基本的初始化，你需要完成这个初始化过程。 【提示】在 alloc_proc 函数的实现中，需要初始化的 proc_struct 结构中的成员变量至少包括：state/pid/runs/kstack/need_resched/parent/mm/context/tf/cr3/ffags/name。* 

* *请在实验报告中简要说明你的设计实现过程。请回答如下问题：*

* *请说明 proc_struct 中 struct context context 和 struct trapframe tf 成员变量含义和 在本实验中的作用是啥？（提示通过看代码和编程调试可以判断出来）*

alloc_proc 函数的主要作用是初始化空闲进程。它通过调用 kmalloc 函数分配一个空的进程控制块（PCB），用于空闲进程。分配成功后，函数会对 PCB 的各个成员进行初始化：将进程状态设置为 PROC_UNINIT，表示进程处于初始状态；将 pid 设为 -1，表示进程尚未分配；将 cr3 指向 uCore 内核页表的基址。其他成员变量初始化时则基本上被置零清空。实现代码如下所示：

alloc_proc函数初始化工作如下：

```c++
	
	// alloc_proc - alloc a proc_struct and init all fields of proc_struct

	static struct proc_struct *
	
	alloc_proc(void) {
	
	    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
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
	    proc->state = PROC_UNINIT;                           // 设置进程状态为未初始化
	    proc->pid = -1;                                      // 设置进程的pid为-1  
	    proc->runs = 0;                                      // 设置进程的运⾏次数为0
	    proc->kstack = 0;                                    // 设置进程的内核栈地址为0，未分配
	    proc->need_resched = 0;                              // 设置进程是否需要重新调度为0
	    proc->parent = NULL;                                 // 设置进程的⽗进程为NULL
	    proc->mm = NULL;                                     // 设置进程的内存管理结构为NULL
	    memset(&(proc->context), 0, sizeof(struct context)); // 清空进程的上下⽂
	    proc->tf = NULL;                                     // 设置进程的 trapframe 为NULL
	    proc->cr3 = boot_cr3;                                // 设置进程的⻚⽬录表基址为 boot_cr3
	    proc->flags = 0;                                     // 设置进程的标志为0
	    memset(proc->name, 0, PROC_NAME_LEN + 1);            // 初始化进程的名字
	
	    }
	    return proc;
	}

```

在操作系统中，proc_struct 数据结构用于存储与进程相关的各种信息，其中 struct context 和 struct trapframe 是两个重要的成员变量：

#### 1. `struct context context`
##### 含义
`context` 结构体用于保存进程的上下文，即进程被中断或切换出 CPU 时所需保存的寄存器状态。它包含了几个关键的寄存器，如：
- **程序计数器（PC）**
- **堆栈指针（SP）**
- 其他通用寄存器等。
操作系统在进程切换时，会将当前运行进程的状态保存在其 context 中，以便稍后恢复该进程的执行状态。

##### 作用
在本实验中，`context` 的作用是在 进程切换 时保存和恢复进程的执行状态。当调度器选择一个新的进程运行时，CPU 的寄存器状态会通过 `context` 被恢复，进而开始执行该进程。`context` 主要在上下文切换函数 `switch_to` 中使用。每当进程切换发生时，系统会从 `context` 中恢复进程的执行状态，使其能够从被中断的地方继续执行。

#### 2. `struct trapframe *tf`
##### 含义
`trapframe` 结构体用于保存当进程进入内核模式时（例如系统调用或硬件中断）需要保存的所有 CPU 状态。它包括中断发生时的寄存器值、程序计数器（PC）、栈指针（SP）等。这允许内核在处理中断时精确了解中断发生时进程的状态，并在中断处理完成后恢复到中断前的状态继续执行。

##### 作用
在本实验中，`trapframe` 主要用于 中断处理和系统调用。当一个进程从用户模式切换到内核模式（例如由于系统调用或中断发生）时，用户模式下的寄存器状态会被保存到 `trapframe` 中。内核完成中断处理后，系统会使用 `trapframe` 中保存的寄存器状态来恢复进程的执行，确保进程从正确的位置继续执行。

在设计和实现 alloc_proc 函数时，确保这些成员变量正确初始化至关重要。context 需要被清零，确保进程初始状态没有残留数据，而 trapframe 应初始化为 NULL，因为在进程创建时尚未发生中断或系统调用。若这些变量初始化不正确，可能导致进程在切换时无法正确恢复，或系统在处理中断时产生异常，进而引发系统崩溃。

### 2.练习 2：为新创建的内核线程分配资源（需要编码）

*创建一个内核线程需要分配和设置好很多资源。kernel_thread 函数通过调用 do_fork 函数完成具体内核线程 的创建工作。do_kernel 函数会调用 alloc_proc 函数来分配并初始化一个进程控制块，但 alloc_proc 只是找到 了一小块内存用以记录进程的必要信息，并没有实际分配这些资源。ucore 一般通过 do_fork 实际创建新的内 核线程。do_fork 的作用是，创建当前内核线程的一个副本，它们的执行上下文、代码、数据都一样，但是存 储位置不同。因此，我们实际需要”fork”的东西就是 stack 和 trapframe。在这个过程中，需要给新内核线 程分配资源，并且复制原进程的状态。你需要完成在kern/process/proc.c中的do_fork函数中的处理过程。它的大致执行步骤包括：*

* 调用alloc_proc，首先获得一块用户信息块。
* 为进程分配一个内核栈。
* 复制原进程的内存管理信息到新进程（但内核线程不必做此事）
* 复制原进程上下文到新进程
* 将新进程添加到进程列表
* 唤醒新进程
* 返回新进程号

* *请在实验报告中简要说明你的设计实现过程。*

* *请说明 ucore 是否做到给每个新 fork 的线程一个唯一的 id？请说明你的分析和理由。*

#### do_fork函数设计实现：

```c++

	int
	do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf) {
	    int ret = -E_NO_FREE_PROC;
	    struct proc_struct *proc;
	    if (nr_process >= MAX_PROCESS) {
	        goto fork_out;
	    }
	    ret = -E_NO_MEM;
	    //LAB4:EXERCISE2 YOUR CODE
	    /*
	     * Some Useful MACROs, Functions and DEFINEs, you can use them in below implementation.
	     * MACROs or Functions:
	     *   alloc_proc:   create a proc struct and init fields (lab4:exercise1)
	     *   setup_kstack: alloc pages with size KSTACKPAGE as process kernel stack
	     *   copy_mm:      process "proc" duplicate OR share process "current"'s mm according clone_flags
	     *                 if clone_flags & CLONE_VM, then "share" ; else "duplicate"
	     *   copy_thread:  setup the trapframe on the  process's kernel stack top and
	     *                 setup the kernel entry point and stack of process
	     *   hash_proc:    add proc into proc hash_list
	     *   get_pid:      alloc a unique pid for process
	     *   wakeup_proc:  set proc->state = PROC_RUNNABLE
	     * VARIABLES:
	     *   proc_list:    the process set's list
	     *   nr_process:   the number of process set
	     */
	
	    //    1. call alloc_proc to allocate a proc_struct
	    //    2. call setup_kstack to allocate a kernel stack for child process
	    //    3. call copy_mm to dup OR share mm according clone_flag
	    //    4. call copy_thread to setup tf & context in proc_struct
	    //    5. insert proc_struct into hash_list && proc_list
	    //    6. call wakeup_proc to make the new child process RUNNABLE
	    //    7. set ret vaule using child proc's pid
	    if ((proc = alloc_proc()) == NULL) // 为⼦进程分配 proc_struct 结构
	        goto fork_out;
	    proc->parent = current; // 设置⼦进程的⽗进程为当前进程
	    if (setup_kstack(proc))// 为⼦进程分配内核栈
	        goto bad_fork_cleanup_kstack;
	    if (copy_mm(clone_flags, proc))// 复制⽗进程的内存管理结构
	        goto bad_fork_cleanup_proc;
	    copy_thread(proc, stack, tf);// 复制⽗进程的 trapframe
	    bool intr_flag;
	    local_intr_save(intr_flag); // 禁⽤中断
	    {
	        proc->pid = get_pid();// 为⼦进程分配唯⼀的 pid
	        hash_proc(proc);// 将⼦进程插⼊到 hash_list 中
	        list_add(&proc_list, &(proc->list_link));// 将⼦进程插⼊到 proc_list 中
	    }
	    local_intr_restore(intr_flag); // 开启中断
	    wakeup_proc(proc); // 唤醒⼦进程
	    ret = proc->pid;// 返回⼦进程的 pid
	    
	
	fork_out:
	    return ret;
	
	bad_fork_cleanup_kstack:
	    put_kstack(proc);//清理内核栈
	bad_fork_cleanup_proc:
	    kfree(proc);// 清理 proc_struct 结构
	    goto fork_out;
	}
```

do_fork 函数的作用是在父进程的基础上创建一个新的子进程。子进程将继承父进程的部分状态信息，比如内存管理结构（mm_struct）、CPU 寄存器状态等。本质上是通过复制或共享父进程的资源来生成一个新的进程。

* 具体实现首先其通过调用 `alloc_proc` 函数为子进程分配并初始化一个新的 `proc_struct` 结构体。`proc_struct` 是新的进程控制块。并将该子进程的 `parent` 成员设置为当前正在运行的父进程，`current` 是当前运行进程的指针。

* 随后我们调用 `setup_kstack` 函数为子进程分配内核栈。并且根据 `clone_flags` 的设置，调用 `copy_mm` 函数来决定子进程是与父进程共享内存空间（CLONE_VM 标志）还是复制一份父进程的内存管理结构。

* 接下来调用 `copy_thread` 函数来复制父进程的 `trapframe`（保存的寄存器状态）到子进程，并初始化子进程的上下文（即 CPU 寄存器信息）。

* 最后我们调用 `get_pid` 为子进程分配一个唯一的 PID。调用 `hash_proc` 将子进程插入进程哈希表中，以便在未来能够快速找到该进程。将子进程插入到进程链表 `proc_list` 中，维护系统中所有进程的链表结构。这步是通过禁用中断实现的，防止在操作过程中进程状态发生变化。随即调用 `wakeup_proc` 函数将子进程的状态设为 `PROC_RUNNABLE`，使它可以被调度器选中执行。

#### ucore给每个新fork的线程一个唯一的id：

分配 id 的函数 `get_pid` 如下：

```c++
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
```

ucore 确实可以确保每个新 fork 的进程都能获得唯一的 PID，其通过递增和冲突检查机制有效避免 PID 重复，保持系统的稳定性和可靠性。

* get_pid 函数通过递增 last_pid 来为进程分配 PID。当 last_pid 达到 MAX_PID 上限时，它会从 1 重新开始分配。这样，PID 在 1 到 MAX_PID-1 范围内循环，避免了 PID 超过系统限制的问题。并且在每次分配新的 last_pid 后，get_pid 会遍历所有已存在的进程，通过 proc_list 检查当前 PID 是否已被占用。如果当前 PID 已被占用，last_pid 会继续增加，并再次进行检查，直到找到一个未被占用的 PID。
* 该函数还使用 next_safe 跟踪一个合适的 PID 范围，帮助优化 PID 查找过程。如果 last_pid 大于或等于 next_safe，则会重新遍历所有进程，确保找到唯一的 PID。
* 该函数的这种循环检查和递增机制还确保了每次分配的 PID 都是唯一的，不会与其他进程冲突。此外，PID 分配从不超过 MAX_PID，从而避免了 PID 重复和溢出的风险。
* 通过 get_pid  函数的逻辑，它遍历当前所有进程，以确保新分配的PID不与任何现有进程的PID冲突。在 PID（ next_safe  ）是指在 get_pid  函数中，"安全的 get_pid  函数中⽤来追踪可以安全分配⽽不会与现有进程的PID冲突 的PID值，也就是说维护了⼀个性质：当前分配了 last_pid  这⼀PID后，下⼀次 last_pid+1  到 next_safe-1  的PID都是可以分配的。这个机制主要⽤于优化搜索性能，避免每次分配PID时都需要 遍历整个进程列表来检查PID是否已被占⽤。
* last_pid  ：记录最后⼀次成功分配的PID。get_pid 从 last_pid +1 开始寻找下⼀个可⽤的PID。
* next_safe  ：记录下⼀个没有被任何活动进程使⽤的PID。当 last_pid 大于 next_safe 时，需要重新扫描活动进程列表来更新 next_safe  的值。

#### **以下是对next_safe作用的分析**：

next_safe 是一个辅助变量，用于优化进程 ID (PID) 的分配过程，帮助快速确定当前可以安全分配的 PID 范围的上限。

##### 主要作用
在 get_pid 函数中，next_safe 的作用是指示从当前的 last_pid 到 next_safe 范围内可以尝试分配的 PID，避免在这个范围内重复遍历进程列表进行检查，从而提高效率。

##### 具体功能

- 限制检查范围：

  当 last_pid 增加时，如果已经检查过某个范围的 PID（即 last_pid 到 next_safe 之间的 PID），可以跳过对这些 PID 的重复检查。
  只有在 last_pid 超过了 next_safe 时，才需要重新遍历整个进程列表，找出新的 next_safe 值。

- 加速分配过程：

  如果当前的 PID 被占用（与现有进程的 pid 冲突），而且 next_safe 没有被更新，则会跳过无效的检查范围直接跳转到新的 repeat，从而避免不必要的遍历操作。


- 动态更新：

  在遍历进程列表时，如果发现某个进程的 pid 大于当前的 last_pid，并且小于当前的 next_safe，会将 next_safe 更新为这个进程的 pid。这表示在下次分配时，可以尝试分配从 last_pid 到 next_safe 范围内的 PID。


### 3.练习3：编写 proc_run 函数（需要编码）

proc_run 用于将指定的进程切换到 CPU 上运行。它的大致执行步骤包括：

* 检查要切换的进程是否与当前正在运行的进程相同，如果相同则不需要切换。

* 禁用中断。你可以使用/kern/sync/sync.h中定义好的宏local_intr_save(x)和local_intr_restore(x)来实现关、开中断。

* 切换当前进程为要运行的进程。

* 切换页表，以便使用新进程的地址空间。/libs/riscv.h中提供了lcr3(unsigned int cr3)函数，可实现修改CR3寄存器值的功能。

* 实现上下文切换。/kern/process中已经预先编写好了switch.S，其中定义了switch_to()函数。可实现两个进程的context切换。

* 允许中断。

请回答如下问题：

* *在本实验的执行过程中，创建且运行了几个内核线程？*

#### proc_run函数实现如下：

```c++
void
proc_run(struct proc_struct *proc) {
    if (proc != current) {
        // LAB4:EXERCISE3 YOUR CODE
        /*
        * Some Useful MACROs, Functions and DEFINEs, you can use them in below implementation.
        * MACROs or Functions:
        *   local_intr_save():        Disable interrupts
        *   local_intr_restore():     Enable Interrupts
        *   lcr3():                   Modify the value of CR3 register
        *   switch_to():              Context switching between two processes
        */
        // 定义⽤于保存中断状态的变量
        bool intr_flag;
        // 记录当前进程和即将运⾏的进程
        struct proc_struct *prev = current, *next = proc;
        // 禁⽤中断 
        local_intr_save(intr_flag);
        {
            // 将当前进程更新为proc
            current = proc;
            lcr3(next->cr3);// 加载新进程的⻚⽬录表到CR3寄存器并切换地址空间
            switch_to(&(prev->context), &(next->context));// 切换到新的进程
        }
        // 开启中断
        local_intr_restore(intr_flag);
    }
}
```

proc_run 函数用于将当前进程切换到指定的进程 proc。它首先禁用中断以确保操作的原子性，然后通过更新 current 指针指向新的进程，加载该进程的页目录表（CR3寄存器），并调用 switch_to 进行上下文切换，从当前进程切换到目标进程。最后，恢复中断以允许其他中断操作。这确保了在进程间切换时，系统的中断和内存管理不会受到干扰。

#### 本实验的执行过程中，创建且运行了几个内核线程:

在本实验中，创建且运行了2两个内核线程：

- idleproc：第一个内核进程，完成内核中各个子系统的初始化，它的作⽤是在没有其他线程可运⾏时占据CPU，在此之后调度，执行其他进程。
- initproc：用于完成实验的功能而调度的内核进程。这个线程开始执⾏ init_main 函数，也就是打印消息。


### 4.扩展练习 Challenge：

*说明语句 local_intr_save(intr_flag);....local_intr_restore(intr_flag); 是如何实现开关中断的？*


```c++
// __intr_save - 保存当前中断状态并禁用中断
static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) { // 如果当前中断使能
        intr_disable(); // 禁用中断
        return 1; // 返回1表示中断之前是使能的
    }
    return 0; // 返回0表示中断之前是禁用的
}

// __intr_restore - 恢复之前保存的中断状态
static inline void __intr_restore(bool flag) {
    if (flag) { // 如果flag为1
        intr_enable(); // 使能中断
    }
}

// local_intr_save - 宏定义，用于保存当前中断状态并禁用中断
#define local_intr_save(x) \
    do {                   \
        x = __intr_save(); \
    } while (0)

// local_intr_restore - 宏定义，用于恢复之前保存的中断状态
#define local_intr_restore(x) __intr_restore(x);
```

##### intr_save 和 local_intr_save：

* intr_save： 通过读取 CSR 控制和状态寄存器中的 sstatus 值，检查其中的 SIE 位（中断使能位）。如果 SIE 为 1，表示当前允许中断，则调用 intr.h中的intr_disable() 禁用中断。如果 SIE 为 0，表示中断已经被禁用，则直接返回，不做任何操作。
* local_intr_save： 该宏使用 do-while 循环确保调用 __intr_save() 后，将中断状态正确保存到 x 变量中。无论中断是否已禁用，都会正确赋值给 x。


##### intr_restore 和 local_intr_restore：

* intr_restore： 根据传入的 flag 标志位，判断是否重新启用中断。通过调用 intr_enable() 恢复中断。
* local_intr_restore： 该宏无需返回任何值，只需根据保存的 flag 恢复中断状态。

两者结合，local_intr_save(intr_flag); ... local_intr_restore(intr_flag) 实现了在进程切换前禁用中断，切换后恢复中断的功能，从而确保进程切换的原子性，避免中断打断进程切换的操作。

**注意！！原子操作的实现如下：**

通过内联汇编 (`asm`) 的方式执行 CSR 指令，分别实现**设置**和**清除**寄存器中的特定位。以下是其如何实现原子操作的详细说明：

```assembly
#define set_csr(reg, bit) ({ unsigned long __tmp; \
  asm volatile ("csrrs %0, " #reg ", %1" : "=r"(__tmp) : "rK"(bit)); \
  __tmp; })

#define clear_csr(reg, bit) ({ unsigned long __tmp; \
  asm volatile ("csrrc %0, " #reg ", %1" : "=r"(__tmp) : "rK"(bit)); \
  __tmp; })
```

#### 1. **指令解析**

##### `csrrs` 和 `csrrc` 指令

- **`csrrs rd, rs1, csr`**（Atomic Read and Set）
  从 CSR 中读取值到目标寄存器 `rd`，同时使用 `rs1` 中的位掩码对 CSR 的值进行**位设置**。
- **`csrrc rd, rs1, csr`**（Atomic Read and Clear）
  从 CSR 中读取值到目标寄存器 `rd`，同时使用 `rs1` 中的位掩码对 CSR 的值进行**位清除**。

这两个指令的关键在于它们同时完成**读取**和**修改**操作，而这一过程在硬件层面是原子的。

------

#### 2. **代码解释**

##### 宏定义 `set_csr`

```
c复制代码#define set_csr(reg, bit) ({ unsigned long __tmp; \
  asm volatile ("csrrs %0, " #reg ", %1" : "=r"(__tmp) : "rK"(bit)); \
  __tmp; })
```

- **功能**：将寄存器 `reg` 的值读取到变量 `__tmp`，同时设置 `reg` 中由 `bit` 掩码指定的位。

- 内联汇编解读

  ：

  - `"csrrs %0, " #reg ", %1"`：执行 `csrrs` 指令，读取 `reg` 寄存器的值到 `%0`（即 `__tmp`），并根据掩码 `bit` 设置寄存器中的对应位。
  - `: "=r"(__tmp)`：表示输出到 `__tmp` 的寄存器约束。
  - `: "rK"(bit)`：表示输入的 `bit`，可以是一个立即数（`K`）或寄存器值（`r`）。

- **结果**：返回寄存器 `reg` 原始的值，同时更新寄存器的特定位。

------

##### 宏定义 `clear_csr`

```
c复制代码#define clear_csr(reg, bit) ({ unsigned long __tmp; \
  asm volatile ("csrrc %0, " #reg ", %1" : "=r"(__tmp) : "rK"(bit)); \
  __tmp; })
```

- **功能**：将寄存器 `reg` 的值读取到变量 `__tmp`，同时清除 `reg` 中由 `bit` 掩码指定的位。

- 内联汇编解读

  ：

  - `"csrrc %0, " #reg ", %1"`：执行 `csrrc` 指令，读取 `reg` 寄存器的值到 `%0`（即 `__tmp`），并根据掩码 `bit` 清除寄存器中的对应位。
  - 其余约束与 `set_csr` 类似。

------

#### 3. **原子操作的实现原理**

`csrrs` 和 `csrrc` 指令的关键特性是**硬件原子性**：

1. **单指令完成读写操作**：RISC-V 硬件确保 `csrrs` 和 `csrrc` 在一个时钟周期内完成对 CSR 的读取和修改，而不会被中断打断。
2. **无中断干扰**：在指令执行期间，硬件保证 CSR 的访问不会受到其他内核或中断的干扰，避免竞态条件。

因此，这些指令天然实现了对寄存器的原子操作，确保在多线程或中断环境下操作 CSR 的一致性和正确性。



## 知识点

### 进程切换

进程切换是操作系统在多任务环境中实现 CPU 时间共享的重要机制。当一个进程的执行被暂停，另一个进程被调度执行时，操作系统需要保存当前进程的状态并恢复另一个进程的状态，这一过程称为**进程切换**。其主要步骤如下：

1. **保存当前进程状态**
   将当前进程的运行状态（包括寄存器、程序计数器、堆栈指针等）保存到进程控制块（PCB）中，以便后续能够恢复执行。
2. **选择下一个运行进程**
   根据调度算法（如先来先服务、短作业优先或时间片轮转）从就绪队列中选出下一个需要运行的进程。
3. **切换内核堆栈**
   将当前的内核堆栈切换到新进程的内核堆栈，以确保新进程能够正确访问自己的堆栈。
4. **恢复新进程状态**
   从新进程的 PCB 中加载其状态，包括寄存器、程序计数器等，准备开始执行。
5. **切换上下文**
   操作系统完成上下文切换后，CPU 开始执行新进程。

#### 进程切换的特点

- **上下文开销**
  进程切换会消耗 CPU 时间，用于保存和恢复进程状态，因此频繁的切换会影响系统性能。
- **内存管理影响**
  当进程切换涉及到地址空间的改变时，可能需要更新内存页表。
- **硬件支持**
  现代 CPU 提供硬件机制（如中断和寄存器保存）以加速上下文切换。

进程切换是多任务操作系统的核心功能，合理的调度算法和优化的切换机制可以提高系统的整体性能和资源利用率。



### 进程调度

进程调度是操作系统管理 CPU 资源的关键机制，用于决定在多任务环境下，哪个进程可以占用 CPU 运行。调度的目标是提高系统的效率和资源利用率，同时确保任务公平性和响应速度。进程调度主要分为以下三种类型：

#### 1. **长作业调度（Long-term Scheduling）**

- **功能**：决定哪些进程可以被载入内存进入就绪队列，从而控制系统的工作负载。
- **频率**：长作业调度的执行频率较低，因为它主要在作业进入系统时发生。
- **目标**：保持系统资源的平衡，避免因进程过多而导致内存溢出或因进程过少而导致 CPU 空闲。

#### 2. **中期调度（Medium-term Scheduling）**

- **功能**：通过挂起和恢复某些进程来调节系统内的运行进程数量。
- **实现**：操作系统会将某些进程从内存中移到外存（如硬盘）以释放内存，当资源充足时再将其恢复到就绪状态。
- **作用**：在系统资源紧张时维持系统稳定性。

#### 3. **短作业调度（Short-term Scheduling）**

- **功能**：决定哪个就绪状态的进程可以获得 CPU 运行的时间。
- **频率**：频繁执行，通常在每次时间片结束、中断或系统调用后进行。
- **目标**：提高 CPU 利用率和系统响应速度。

#### 调度算法分类

操作系统根据具体需求和性能目标设计了多种调度算法，常见算法包括：

1. **先来先服务（FCFS, First Come First Serve）**
   按到达时间顺序分配 CPU，简单但可能导致长作业延迟。
2. **短作业优先（SJF, Shortest Job First）**
   优先执行运行时间最短的进程，能最小化平均等待时间，但需要预知作业时间。
3. **优先级调度（Priority Scheduling）**
   按进程优先级分配 CPU，可能导致低优先级进程长期等待（饥饿问题）。
4. **时间片轮转（Round Robin, RR）**
   每个进程分配固定时间片，轮流运行，适合多用户系统，响应时间较好。
5. **多级队列调度（Multilevel Queue Scheduling）**
   按进程类型划分多个队列，不同队列使用不同调度算法，适合复杂系统。
6. **多级反馈队列调度（Multilevel Feedback Queue Scheduling）**
   在多级队列基础上增加动态调整机制，进程可以在队列间移动，提高调度灵活性。

#### 调度的性能指标

1. **CPU 利用率**：保持 CPU 尽可能忙碌。
2. **吞吐量**：单位时间内完成的进程数量。
3. **周转时间**：进程从提交到完成的总时间。
4. **等待时间**：进程在就绪队列中等待的总时间。
5. **响应时间**：进程开始运行到首次响应的时间。

通过优化调度算法，操作系统能够在不同的应用场景下实现高效的资源分配和良好的用户体验。



### 进程与线程的关系

进程和线程是操作系统中多任务管理的重要概念，它们既相互独立又紧密关联。理解它们的关系有助于更好地设计并发和并行程序。以下从定义、区别和联系等方面进行说明：

#### 1. **进程的定义**

进程是操作系统资源分配的基本单位，是程序的一次执行实例。每个进程拥有独立的内存空间（包括代码段、数据段、堆和栈）以及系统资源（如文件句柄和设备）。

#### 2. **线程的定义**

线程是进程中的执行单元，是 CPU 调度的基本单位。一个线程运行在所属进程的内存空间中，共享进程的资源（如全局变量、打开的文件等），但有独立的栈和寄存器。

#### 3. **进程与线程的区别**

| **方面**     | **进程**                                   | **线程**                                             |
| ------------ | ------------------------------------------ | ---------------------------------------------------- |
| **资源分配** | 是资源分配的基本单位，每个进程独占资源     | 是 CPU 调度的基本单位，资源共享效率高                |
| **内存空间** | 进程间独立，互不影响                       | 同一进程内线程共享内存空间                           |
| **切换开销** | 进程切换开销大（需要切换内存地址等）       | 线程切换开销小（共享内存，切换少量寄存器）           |
| **通信方式** | 进程间通信需要使用 IPC（如管道、消息队列） | 线程间通信可以直接通过共享内存                       |
| **独立性**   | 进程之间完全独立，崩溃互不影响             | 同一进程内线程共享资源，线程崩溃可能导致整个进程崩溃 |

#### 4. **进程与线程的联系**

1. **线程是进程的一部分**
   一个进程至少包含一个线程（主线程），多线程可以并行执行任务，提高效率。线程依赖进程存在，进程终止会导致其所有线程退出。
2. **共享资源**
   同一进程中的线程共享代码段、数据段和打开的文件等资源，从而降低资源消耗，提高通信效率。
3. **相辅相成**
   进程提供隔离性，保证不同程序之间的独立性和稳定性；线程提供并发能力，提高程序的执行效率。

