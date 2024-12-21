.text                   // 定义接下来的代码段为文本段
.globl _start           // 声明 _start 为全局符号，链接器可以识别
_start:                 // 定义 _start 标签，程序入口点
    # 调用用户程序函数
    call umain          // 调用 umain 函数
1:  j 1b                // 无限循环，跳转到标签 1
