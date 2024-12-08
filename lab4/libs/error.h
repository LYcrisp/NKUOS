#ifndef __LIBS_ERROR_H__
#define __LIBS_ERROR_H__

/* 内核错误代码 -- 请与 lib/printfmt.c 中的列表保持同步 */
#define E_UNSPECIFIED       1   // 未指定或未知问题
#define E_BAD_PROC          2   // 进程不存在或其他问题
#define E_INVAL             3   // 无效参数
#define E_NO_MEM            4   // 请求因内存不足而失败
#define E_NO_FREE_PROC      5   // 尝试创建新进程超出限制
#define E_FAULT             6   // 内存错误

/* 最大允许值 */
#define MAXERROR            6

#endif /* !__LIBS_ERROR_H__ */
