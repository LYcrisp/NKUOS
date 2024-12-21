#include <defs.h> // 包含定义头文件
#include <stdarg.h> // 包含变长参数头文件
#include <stdio.h> // 包含标准输入输出头文件
#include <ulib.h> // 包含用户库头文件
#include <error.h> // 包含错误头文件

void
__panic(const char *file, int line, const char *fmt, ...) { // 定义__panic函数，接受文件名、行号和格式化字符串作为参数
    // 打印'消息'
    va_list ap; // 定义变长参数列表
    va_start(ap, fmt); // 初始化变长参数列表
    cprintf("user panic at %s:%d:\n    ", file, line); // 打印文件名和行号
    vcprintf(fmt, ap); // 打印格式化字符串
    cprintf("\n"); // 打印换行符
    va_end(ap); // 结束变长参数列表
    exit(-E_PANIC); // 退出程序并返回错误码
}

void
__warn(const char *file, int line, const char *fmt, ...) { // 定义__warn函数，接受文件名、行号和格式化字符串作为参数
    va_list ap; // 定义变长参数列表
    va_start(ap, fmt); // 初始化变长参数列表
    cprintf("user warning at %s:%d:\n    ", file, line); // 打印文件名和行号
    vcprintf(fmt, ap); // 打印格式化字符串
    cprintf("\n"); // 打印换行符
    va_end(ap); // 结束变长参数列表
}
