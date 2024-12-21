#include <stdio.h>
#include <ulib.h>

int magic = -0x10384;

int
main(void) {
    int pid, code;
    cprintf("I am the parent. Forking the child...\n");
    if ((pid = fork()) == 0) {
        /*fork() 用于创建一个新的子进程，子进程是父进程的副本，拥有相同的代码和数据空间。
        fork() 返回两次：一次在父进程中，返回子进程的 PID；一次在子进程中，返回 0。
        copy_thread 把 a0 寄存器设置为 0，所以子进程返回 0。
        */
        cprintf("I am the child.\n");
        // uintptr_t* p = 0x800588;
        // cprintf("*p = 0x%x\n", *p);
        // *p = 0x222;
        // cprintf("*p = 0x%x\n", *p);
        yield(); 
        /*sys_yield() 是一个用于进程主动让出 CPU 的系统调用接口*/
        yield();
        yield();
        yield();
        yield();
        yield();
        yield();
        exit(magic);
    }
    else {
        cprintf("I am parent, fork a child pid %d\n",pid);
    }
    assert(pid > 0);
    cprintf("I am the parent, waiting now..\n");

    assert(waitpid(pid, &code) == 0 && code == magic);
    assert(waitpid(pid, &code) != 0 && wait() != 0);
    cprintf("waitpid %d ok.\n", pid);

    cprintf("exit pass.\n");
    return 0;
}

