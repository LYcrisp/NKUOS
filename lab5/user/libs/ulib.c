#include <defs.h> // 包含头文件defs.h
#include <syscall.h> // 包含头文件syscall.h
#include <stdio.h> // 包含头文件stdio.h
#include <ulib.h> // 包含头文件ulib.h

void
exit(int error_code) { // 定义exit函数，参数为错误代码
    sys_exit(error_code); // 调用系统调用sys_exit，传入错误代码
    cprintf("BUG: exit failed.\n"); // 打印错误信息，表示exit失败
    while (1); // 无限循环，防止函数返回
}

int
fork(void) { // 定义fork函数，无参数
    return sys_fork(); // 调用系统调用sys_fork，并返回其结果
}

int
wait(void) { // 定义wait函数，无参数
    return sys_wait(0, NULL); // 调用系统调用sys_wait，传入0和NULL作为参数，并返回其结果
}

int
waitpid(int pid, int *store) { // 定义waitpid函数，参数为进程ID和存储指针
    return sys_wait(pid, store); // 调用系统调用sys_wait，传入进程ID和存储指针，并返回其结果
}

void
yield(void) { // 定义yield函数，无参数
    sys_yield(); // 调用系统调用sys_yield
}

int
kill(int pid) { // 定义kill函数，参数为进程ID
    return sys_kill(pid); // 调用系统调用sys_kill，传入进程ID，并返回其结果
}

int
getpid(void) { // 定义getpid函数，无参数
    return sys_getpid(); // 调用系统调用sys_getpid，并返回其结果
}

//print_pgdir - 打印页目录表和页表
void
print_pgdir(void) { // 定义print_pgdir函数，无参数
    sys_pgdir(); // 调用系统调用sys_pgdir
}
