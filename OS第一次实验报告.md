# Lab0.5

## 练习1：使用GDB验证启动流程

>为了熟悉使用qemu和gdb进行调试工作,使用gdb调试QEMU模拟的RISC-V计算机加电开始运行到执行应用程序的第一条指令（即跳转到0x80200000）这个阶段的执行过程，说明RISC-V硬件加电后的几条指令在哪里？完成了哪些功能？要求在报告中简要写出练习过程和回答。
答：

首先使用 make debug 并挂起然后使用 make gdb 指令，开启gdb调试，然后使用命令 x/10i $pc 可以查看即将执行的十条的命令：

<img src="C:\Users\ZhangZeRui\AppData\Roaming\Typora\typora-user-images\image-20240926114944630.png" alt="image-20240926114944630" style="zoom:80%;" />

RISC-V 加电后，指令从复位地址 **0x1000** 开始执行。以下是每条指令的功能及其结果：

1. **指令：`auipc t0, 0x0`**
   - **功能**：这条指令将立即数 0 的符号位扩展成 20 位，并左移 12 位后加到当前程序计数器（PC）上。由于 PC 的初始值为 **0x1000**，执行结果为：
     - `t0 = PC + 0 = 0x1000`
   - **结果**：寄存器 `t0` 的值为 **0x1000**。

2. **指令：`addi a1, t0, 32`**
   - **功能**：这条指令将 `t0` 的值（即 **0x1000**）加上偏移量 32，并将结果存入 `a1` 寄存器。
   - **计算**：
     - `a1 = t0 + 32 = 0x1000 + 0x20 = 0x1020`
   - **结果**：寄存器 `a1` 的值为 **0x1020**。

3. **指令：`csrr a0, mhartid`**
   - **功能**：这条指令从控制状态寄存器（CSR）中读取 `mhartid` 的值，并将其存入 `a0`。该寄存器通常表示硬件线程的 ID。
   - **结果**：寄存器 `a0` 的值为 **0x0000000000000000**，表示当前线程的 ID。

4. **指令：`ld t0, 24(t0)`**
   - **功能**：这条指令从内存地址 `t0 + 24`（即 **0x1018**）读取 64 位值，并加载到 `t0` 中。
   - **计算**：
     - 内存地址 = `t0 + 24 = 0x1000 + 0x18 = 0x1018`
   - **结果**：执行后，寄存器 `t0` 的值变为 **0x80000000**，为后续跳转指令提供目标地址。

5. **指令：`jr t0`**
   - **功能**：根据 `t0` 的值执行跳转指令，目标地址为 **0x80000000**，用于跳转至 OpenSBI 加载地址。这条指令的执行标志着应用程序的启动。

下图是单步调试上述五条指令并进行逐一测试并验证：

<img src="C:\Users\ZhangZeRui\AppData\Roaming\Typora\typora-user-images\image-20240926115316284.png" alt="image-20240926115316284" style="zoom:80%;" />


综上我们可知，RISCV加电后的地址是**0x1000**，这五条指令（复位代码）成功让CPU控制流从复位地址跳转到0x80000000，也就是OpenSBI.bin的加载地址。

为了探寻作为bootloader的 OpenSBI 在0x80000000到0x80200000在做什么，于是在0x80200000处设置断点后continue，make debug命令行界面显示了OpenSBI初始化的输出，而且也显示了在0x80200000会执行应用程序的第一条指令：  `la sp, bootstacktop` 如下图。

<img src="C:\Users\ZhangZeRui\AppData\Roaming\Typora\typora-user-images\image-20240926115738742.png" alt="image-20240926115738742" style="zoom:80%;" />


OpenSBI在这段地址区间开始做一些准备工作，最后让CPU的pc跳转到0x80200000，开始执行应用第一条指令，该指令的作用是将标签 `bootstacktop` 的地址加载到栈指针寄存器 `sp` 中。也就是entry.S文件中的入口标签的第一条指令。


## 本实验中重要知识点

本实验构建了一个基本可执行内核，能够进行格式化输出并进入死循环。通过分析项目的组成，我们理解了从处理器复位地址开始执行的复位代码，启动 bootloader（OpenSBI 固件），该 bootloader 负责加载操作系统内核并跳转至入口点 `kern_entry`，最终到达“真正的入口点” `kern_init`。在 `kern/init/init.c` 中，`kern_init` 函数在完成格式化输出 `cprintf()` 后进入死循环。

分析 `sbi_call()` 的过程使我们认识到，操作系统函数依赖固件提供的 API。以下是输出函数的封装步骤：

- **libs/sbi.c**: `uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0...)` 用于输出单个字符 `arg0`，随后通过 `sbi_console_putchar(unsigned char ch)` 进行类型转换。
- **kern/driver/console.c**: `cons_putc(int c)` 封装，并将 `int` 转换为 `unsigned char`。
- **kern/libs/stdio.c**: `cputchar(int c)` 封装上一层，`cputch(int c, int *cnt)` 引入输出计数器，`cputs(const char *strs)` 调用有计数功能的 `cputch()` 来输出字符串。
- 最终，通过一系列封装形成 `cprintf()` 函数。

本实验还学习了 `makefile`，该自动化编译工具通过描述依赖关系和定义编译规则，确定多文件项目的编译顺序，并根据文件修改日期判断是否需要重新编译，从而显著节省编译时间和资源。

**内核栈** 是操作系统内核在运行过程中使用的一块内存区域。它主要用于存储函数调用时的局部变量、函数参数和返回地址等信息。内核栈遵循先进后出的原则，使得后进入的函数在返回时能够正确恢复调用状态。

在操作系统启动时，bootloader 负责初始化内核栈，并将控制权交给内核。当内核开始运行后，内核栈为各种操作提供了存储空间，例如：

- **处理中断**：当系统发生中断时，内核需要保存当前执行上下文，以便在处理完中断后能够恢复。
- **任务调度**：内核在切换任务时，需保存当前任务的状态，并加载下一个任务的上下文。
- **系统调用**：当用户程序请求内核服务时，内核需要使用内核栈保存用户程序的状态。

# Lab1

## 练习1：理解内核启动中的程序入口操作

>阅读 kern/init/entry.S内容代码，结合操作系统内核启动流程，说明指令 la sp, bootstacktop 完成了什么操作，目的是什么？ tail kern_init 完成了什么操作，目的是什么？
答： 

`la sp, bootstacktop` 指令用于初始化内核栈指针 `sp`，将其设置为 `bootstacktop` 标签所代表的地址，从而完成内核栈的初始化。

`tail kern_init` 指令则用于跳转到 `kern_init` 函数，启动内核初始化流程。`kern_init` 是内核的主要入口，负责执行初始化操作。`tail` 是一种特殊的调用方式，调用后不会返回到调用者，直接控制流转至 `kern_init` 开始执行初始化，且调用者的栈帧不会被保留，从而节省空间。

因此，这两条关键指令分别完成了内核栈和控制流的初始化，为内核后续的编程流程做好了准备，启动操作系统内核。

## 练习2：完善中断处理 （需要编程）

>请编程完善trap.c中的中断处理函数trap，在对时钟中断进行处理的部分填写kern/trap/trap.c函数中处理时钟中断的部分，使操作系统每遇到100次时钟中断后，调用print_ticks子程序，向屏幕上打印一行文字”100 ticks”，在打印完10行后调用sbi.h中的shut_down()函数关机。
>>要求完成问题1提出的相关函数实现，提交改进后的源代码包（可以编译执行），并在实验报告中简要说明实现过程和定时器中断中断处理的流程。实现要求的部分代码后，运行整个系统，大约每1秒会输出一次”100 ticks”，输出10行。
答：实现代码如下：

```c++
void interrupt_handler(struct trapframe *tf)
{
    intptr_t cause = (tf->cause << 1) >> 1;
    switch (cause)
    {
    case IRQ_U_SOFT:
        cprintf("User software interrupt\n");
        break;
    case IRQ_S_SOFT:
        cprintf("Supervisor software interrupt\n");
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
        break;
    case IRQ_U_TIMER:
        cprintf("User software interrupt\n");
        break;
    case IRQ_S_TIMER:
        // "All bits besides SSIP and USIP in the sip register are
        // read-only." -- privileged spec1.9.1, 4.1.4, p59
        // In fact, Call sbi_set_timer will clear STIP, or you can clear it
        // directly.
        // cprintf("Supervisor timer interrupt\n");
        /* LAB1 EXERCISE2   YOUR CODE :  */
        /*(1)设置下次时钟中断- clock_set_next_event()
         *(2)计数器（ticks）加一
         *(3)当计数器加到100的时候，我们会输出一个`100ticks`表示我们触发了100次时
         * 钟中断，同时打印次数（num）加一
         * (4)判断打印次数，当打印次数为10时，调用<sbi.h>中的关机函数关机
         */
        clock_set_next_event(); // 发生这次时钟中断的时候，我们要设置下一次
                                // 时钟中断
        if (ticks++ % TICK_NUM == 0)
        {
            // 打印一次
            print_ticks();
            num++;
        }
        if (num == 10)
        {
            // 关机
            sbi_shutdown();
        }
        break;

        // ...其他中断处理
    }
}
```
实现过程：
1. 声明静态变量ticks计数时钟中断次数。
2. 在trap.c的函数中，检查是否为时钟中断（定位到对应的case语句）。
3. 每100次中断调用print_ticks输出信息。
4. 输出10行后,调用sbi关闭系统。
定时器中断流程：

- 通过计时器触发时钟中断，控制流跳转到中断向量表的 `__alltraps`，保存上下文后进入 `trap` 函数。
  
- 在 `trap` 函数中，调用 `trap_dispatch`，利用 `cause` 寄存器判断中断类型，进入 `interrupt_handler`。

- 在 `interrupt_handler` 中，首先调用 `clock_set_next_event` 来设置下一次时钟中断，接着根据 `cause` 寄存器确认中断来源，如果是时钟中断，则增加 `ticks` 计数。

- 当 `ticks` 达到100（即 `ticks % 100 == 0`）时，输出信息；同时，当 `num` 计数器累积到10次时，调用关机函数。

- 如果没有触发关机，程序将返回到 `__alltraps`，恢复上下文，并等待下一次时钟中断的到来。

  经验证发现可以正确满足实验要求，实验结果如下：

  <img src="C:\Users\ZhangZeRui\AppData\Roaming\Typora\typora-user-images\image-20240926155257531.png" alt="image-20240926155257531" style="zoom:80%;" />


## 扩展练习 Challenge1：描述与理解中断流程

>回答：描述ucore中处理中断异常的流程（从异常的产生开始），其中mov a0，sp的目的是什么？SAVE_ALL中寄寄存器保存在栈中的位置是什么确定的？对于任何中断，__alltraps 中都需要保存所有寄存器吗？请说明理由。
答：ucore处理中断和异常的流程是:（由于从异常的产生开始，这里不讨论中断向量表的初始化）

ucore 中处理中断和异常的流程如下（从异常产生开始）：

1. 以时钟中断为例，计时器通过 `sbi_call` 调用 `ecall`（在 `kern/init/init.c` 的 `kern_init` 函数中调用 `clock_init`，然后设置下次中断时间并将计时器 `ticks` 初始化为 0）。异常的产生方式类似于此。此时，在 S 状态产生中断，控制权转移至 M 模式的异常处理程序，由 RISC-V 的异常委托机制将中断和同步异常转交给 S 模式处理。

2. 异常触发后，设置 PC 跳转至中断向量表中对应地址。在实验中，采用 Direct 模式，直接跳转到 `stvec` 指向的地址，此时设置 `epc` 寄存器为产生异常的指令位置。

3. 实现上下文保存：将关键寄存器（包括指令寄存器 `ra` 等）存储到中断帧的栈中，这个实现位置在 `trap.h` 中定义的寄存器结构体和 `trapentry.S` 中的 `SAVE_ALL` 宏。

4. 在 `__alltraps` 中，通过 `mov a0, sp` 将中断帧的栈地址传递给 `trap` 函数，这样中断处理程序能够获取中断上下文并判断中断类型，交给相应的处理函数。

5. 最后，`trap` 函数返回时，通过 `RESTORE_ALL` 恢复上下文，然后在 `__alltraps` 中使用 `sret` 跳回原内核程序执行。

`mov a0, sp` 的目的是将中断帧的栈地址传递给 `trap` 函数，以便中断处理程序能够访问中断上下文。


中断帧内寄存器保存的位置是**当前sp所指向的栈顶**。由于使用了addi sp, sp, -36 * REGBYTES开辟栈空间，其中REGBYTES是每个寄存器所栈的字节数，进行减法运算是因为栈是向低地址增长的。然后逐个STORE xi, i*REGBYTES(sp)，相当于把这些寄存器保存在了栈顶位置处。

**__alltraps 中不一定需要保存所有寄存器。**原因如下：我们知道，保存上下文的目的是为了后续中断处理程序的进行，因此要保存的寄存器取决于中断处理程序的具体需求和设计。我们认为并非所有中断都需要保存所有的寄存器。一方面，对于某些中断，其处理程序可能只会用到几个寄存器，我们只需要将这些寄存器保存下来即可，若所有中断都保存所有寄存器，那会使得系统的性能和效率大大降低；另一方面，有很多寄存器的值实际上是不会受中断影响而改变的，对于这部分寄存器我们完全可以不用保存，减少程序的空间和时间开销。

## 扩增练习 Challenge2：理解上下文切换机制

>回答：在trapentry.S中汇编代码 csrw sscratch, sp；csrrw s0, sscratch, x0实现了什么操作，目的是什么？save all里面保存了stval scause这些csr，而在restore all里面却不还原它们？那这样store的意义何在呢？
答：trapentry.S中的汇编指令csrw sscratch, sp; csrrw s0, sscratch, x0实现的操作是:

*  `csrw sscratch, sp`: 把原先上文的栈顶指针sp赋值给sscratch特权寄存器。
*  `csrrw s0, sscratch, x0`: 将原 sp 值（sscratch 特权寄存器中的值）存入 s0 中，用于后续存入内存实现上文的保存。将sscratch的值设置为0（相当于是复原了，标识中断前程序处于S态）。
目的是:

1. 通过sscratch临时保存sp,避免在save all期间修改sp值而导致的问题。

2. 将保存下来的sp值释放出来,赋值给s0,作为参数传给 trap 处理例程，使其可以访问中断帧和相关的上下文信息。

  

  在save all中保存stval scause等 csr 寄存器,是为了**记录异常中断的来源信息**,如产生异常的指令地址和原因等。同时，在trap.c文件中有函数print_trapframe和print_regs用于输出寄存器信息，我们保存这些csr寄存器之后可以调用这些函数来获取异常中断有关信息。

在restore all中不还原这些csr值,是因为:

* 这些值只在异常处理期间需要使用,恢复任务上下文时它们不相关。

* 其他可能会覆盖这些csr的值(如下一次中断),所以不必还原。

  

  意义：通过csr暂存和传值实现了sp值的保存和利用,同时记录中断来源信息,这对异常处理和转入trap例程都很重要。即使不还原csr,记录的信息也已使用完毕。

## 扩展练习Challenge3：完善异常中断

>编程完善在触发一条非法指令异常 mret和，在 kern/trap/trap.c的异常处理函数中捕获，并对其进行处理，简单输出异常类型和异常指令触发地址，即“Illegal instruction caught at 0x(地址)”，“ebreak caught at 0x（地址）”与“Exception type:Illegal instruction"，“Exception type: breakpoint”。
答：实现代码如下：

```c++
//In kern/init/init.c
//设置异常中非法指令触发和断点异常的汇编代码：
asm("mret");   // 异常处理
asm("ebreak"); // 中断
//In kern/trap/trap.c
//完善异常处理句柄函数中，非法指令触发和断点异常的处理代码：
void exception_handler(struct trapframe *tf)
{
    switch (tf->cause)//tf 是一个指向 trapframe 结构体的指针，trapframe 用于保存发生中断或异常时的 CPU 状态。
    {
    case CAUSE_ILLEGAL_INSTRUCTION:
        // 非法指令异常处理
        /* LAB1 CHALLENGE3   YOUR CODE :  */
        /*(1)输出指令异常类型（ Illegal instruction）
         *(2)输出异常指令地址
         *(3)更新 tf->epc寄存器
         */
        cprintf("Exception type:Illegal instruction\n");
        cprintf("Illegal instruction caught at %p\n", tf->epc);
        tf->epc += 4;//tf->epc是异常程序计数器，非法指令4字节
        break;
    case CAUSE_BREAKPOINT:
        // 断点异常处理
        /* LAB1 CHALLLENGE3   YOUR CODE :  */
        /*(1)输出指令异常类型（ breakpoint）
         *(2)输出异常指令地址
         *(3)更新 tf->epc寄存器
         */
        cprintf("Exception type: breakpoint\n");
        cprintf("ebreak caught at %p\n", tf->epc);
        tf->epc += 2;//断点指令两字节
        break;
    // ...其他异常处理
    }
}
```
这里需要注意的是，在输出异常后，还需要跳过当前指令，否则会一直执行异常指令（这里的异常不同于缺页异常，在异常处理结束后应当执行下一条指令）。非法指令mret为4个字节，而ebreak断点异常为2个字节，让epc加上这个字节数、跳过异常指令即可。

在非法指令异常处理后，将 tf->epc 值增加 4，因为 mret 指令长 4 字节，从而跳过该指令继续执行。对于断点异常，tf->epc 增加 2，是因为 ebreak 指令长度为 2 字节，以保持指令的 4 字节对齐。

接下来，为了验证异常处理的有效性，在init.c文件kern_init函数中加上内联汇编，从而在make qemu的时候能够输出异常处理程序中的打印信息，证实异常处理成功。如下代码所示：

```c++
int kern_init(void)
{
    extern char edata[], end[];
    memset(edata, 0, end - edata);

    cons_init(); // init the console

    const char *message = "(THU.CST) os is loading ...\n";
    cprintf("%s\n\n", message);

    print_kerninfo();

    // grade_backtrace();

    idt_init(); // init interrupt descriptor table

    // rdtime in mbare mode crashes
    clock_init(); // init clock interrupt

    intr_enable(); // enable irq interrupt

    asm("mret");   // 非法指令
    asm("ebreak"); // 断点异常

    while (1)
        ;
}
```



运行make qemu，可以看到正常输出异常类型和异常指令触发地址：

![image-20240926120944843](C:\Users\ZhangZeRui\AppData\Roaming\Typora\typora-user-images\image-20240926120944843.png)


说明代码正常运行。

## make grade验证

![image-20240926121035314](C:\Users\ZhangZeRui\AppData\Roaming\Typora\typora-user-images\image-20240926121035314.png)

