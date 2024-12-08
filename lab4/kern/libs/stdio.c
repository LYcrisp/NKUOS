#include <defs.h> // 包含定义头文件
#include <stdio.h> // 包含标准输入输出头文件
#include <console.h> // 包含控制台头文件

/* HIGH level console I/O // 高级控制台输入输出 */

/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * cputch - 将单个字符 @c 写入标准输出，并增加 @cnt 指向的计数器的值。
 * */
static void
cputch(int c, int *cnt) { // 将字符c写入控制台，并增加计数器cnt
    cons_putc(c); // 调用控制台输出函数
    (*cnt) ++; // 计数器加1
}

/* *
 * vcprintf - format a string and writes it to stdout
 * vcprintf - 格式化字符串并将其写入标准输出
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * 返回值是将写入标准输出的字符数。
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * 如果你已经在处理va_list，请调用此函数。否则你可能需要cprintf()。
 * */
int
vcprintf(const char *fmt, va_list ap) { // 格式化字符串并写入标准输出
    int cnt = 0; // 初始化计数器
    vprintfmt((void*)cputch, &cnt, fmt, ap); // 调用vprintfmt函数进行格式化输出
    return cnt; // 返回计数器值
}

/* *
 * cprintf - formats a string and writes it to stdout
 * cprintf - 格式化字符串并将其写入标准输出
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * 返回值是将写入标准输出的字符数。
 * */
int
cprintf(const char *fmt, ...) { // 格式化字符串并写入标准输出
    va_list ap; // 定义va_list变量
    int cnt; // 定义计数器变量
    va_start(ap, fmt); // 初始化va_list变量
    cnt = vcprintf(fmt, ap); // 调用vcprintf函数进行格式化输出
    va_end(ap); // 结束va_list变量的使用
    return cnt; // 返回计数器值
}

/* cputchar - writes a single character to stdout // cputchar - 将单个字符写入标准输出 */
void
cputchar(int c) { // 将字符c写入控制台
    cons_putc(c); // 调用控制台输出函数
}

/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * cputs- 将 @str 指向的字符串写入标准输出，并附加一个换行符。
 * */
int
cputs(const char *str) { // 将字符串str写入标准输出，并附加换行符
    int cnt = 0; // 初始化计数器
    char c; // 定义字符变量
    while ((c = *str ++) != '\0') { // 遍历字符串
        cputch(c, &cnt); // 调用cputch函数输出字符并增加计数器
    }
    cputch('\n', &cnt); // 输出换行符并增加计数器
    return cnt; // 返回计数器值
}

/* getchar - reads a single non-zero character from stdin // getchar - 从标准输入读取单个非零字符 */
int
getchar(void) { // 从标准输入读取单个字符
    int c; // 定义字符变量
    while ((c = cons_getc()) == 0) // 循环读取字符，直到读取到非零字符
        /* do nothing */; // 什么也不做
    return c; // 返回读取到的字符
}
