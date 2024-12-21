#include <defs.h> // 包含头文件defs.h
#include <stdio.h> // 包含头文件stdio.h
#include <syscall.h> // 包含头文件syscall.h

/* *
 * cputch - 将单个字符@c写入到标准输出，并且会增加@cnt指向的计数器的值。
 * */
static void
cputch(int c, int *cnt) { // 定义静态函数cputch，参数为字符c和计数器指针cnt
    sys_putc(c); // 调用系统调用sys_putc将字符c输出
    (*cnt) ++; // 计数器加1
}

/* *
 * vcprintf - 格式化字符串并将其写入到标准输出
 *
 * 返回值是将会写入到标准输出的字符数量。
 *
 * 如果你已经在处理va_list，请调用此函数。
 * 否则你可能更想调用cprintf()。
 * */
int
vcprintf(const char *fmt, va_list ap) { // 定义函数vcprintf，参数为格式字符串fmt和可变参数列表ap
    int cnt = 0; // 初始化计数器cnt为0
    vprintfmt((void*)cputch, &cnt, fmt, ap); // 调用vprintfmt函数，传入cputch函数指针、计数器、格式字符串和可变参数列表
    return cnt; // 返回计数器的值
}

/* *
 * cprintf - 格式化字符串并将其写入到标准输出
 *
 * 返回值是将会写入到标准输出的字符数量。
 * */
int
cprintf(const char *fmt, ...) { // 定义函数cprintf，参数为格式字符串fmt和可变参数
    va_list ap; // 定义va_list类型的变量ap

    va_start(ap, fmt); // 初始化ap，使其指向可变参数的第一个参数
    int cnt = vcprintf(fmt, ap); // 调用vcprintf函数，传入格式字符串fmt和可变参数列表ap，并将返回值赋给cnt
    va_end(ap); // 结束可变参数的处理

    return cnt; // 返回计数器的值
}

/* *
 * cputs- 将@str指向的字符串写入到标准输出并附加一个换行符。
 * */
int
cputs(const char *str) { // 定义函数cputs，参数为字符串指针str
    int cnt = 0; // 初始化计数器cnt为0
    char c; // 定义字符变量c
    while ((c = *str ++) != '\0') { // 遍历字符串，直到遇到字符串结束符'\0'
        cputch(c, &cnt); // 调用cputch函数，将字符c输出，并增加计数器
    }
    cputch('\n', &cnt); // 输出换行符，并增加计数器
    return cnt; // 返回计数器的值
}
