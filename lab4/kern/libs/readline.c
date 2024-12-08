#include <stdio.h> // 包含标准输入输出头文件

#define BUFSIZE 1024 // 定义缓冲区大小为1024
static char buf[BUFSIZE]; // 定义静态字符数组buf，大小为BUFSIZE

/* *
 * readline - 从标准输入获取一行
 * @prompt:     要写入标准输出的字符串
 *
 * readline()函数将首先将输入字符串@prompt写入标准输出。
 * 如果@prompt为NULL或空字符串，则不发出提示。
 *
 * 该函数将继续读取字符并将其保存到缓冲区'buf'中，直到遇到'\n'或'\r'。
 *
 * 注意，如果读取的字符串长度超过缓冲区大小，字符串的末尾将被丢弃。
 *
 * readline()函数返回读取的行的文本。如果发生一些错误，则返回NULL。
 * 返回值是一个全局变量，因此在使用之前应复制它。
 * */
char *
readline(const char *prompt) {
    if (prompt != NULL) { // 如果提示字符串不为空
        cprintf("%s", prompt); // 将提示字符串写入标准输出
    }
    int i = 0, c; // 定义变量i和c，i用于索引缓冲区，c用于存储读取的字符
    while (1) { // 无限循环
        c = getchar(); // 从标准输入读取一个字符
        if (c < 0) { // 如果读取错误
            return NULL; // 返回NULL
        }
        else if (c >= ' ' && i < BUFSIZE - 1) { // 如果读取的字符是可打印字符且缓冲区未满
            cputchar(c); // 将字符写入标准输出
            buf[i ++] = c; // 将字符保存到缓冲区，并递增索引
        }
        else if (c == '\b' && i > 0) { // 如果读取的字符是退格符且缓冲区不为空
            cputchar(c); // 将退格符写入标准输出
            i --; // 递减索引
        }
        else if (c == '\n' || c == '\r') { // 如果读取的字符是换行符或回车符
            cputchar(c); // 将换行符或回车符写入标准输出
            buf[i] = '\0'; // 在缓冲区末尾添加字符串结束符
            return buf; // 返回缓冲区
        }
    }
}
