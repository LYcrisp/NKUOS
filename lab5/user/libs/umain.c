#include <ulib.h>

int main(void);

void
umain(void) {
    int ret = main();
    exit(ret);
}

/*
实现了umain函数，这是所有应用程序执行的第一个C函数，它将调用应用程序的main函数，
并在main函数结束后调用exit函数，而exit函数最终将调用sys_exit系统调用，让操作系统回收进程资源。
*/