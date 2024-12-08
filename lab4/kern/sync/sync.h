/*
处理中断的保存和恢复操作*/

#ifndef __KERN_SYNC_SYNC_H__ // 防止重复包含头文件的宏定义
#define __KERN_SYNC_SYNC_H__

#include <defs.h> // 包含一些基本的宏定义和类型定义
#include <intr.h> // 包含中断处理相关的函数和宏定义
#include <riscv.h> // 包含RISC-V架构相关的函数和宏定义

// __intr_save - 保存当前中断状态并禁用中断
static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) { // 如果当前中断使能
        intr_disable(); // 禁用中断
        return 1; // 返回1表示中断之前是使能的
    }
    return 0; // 返回0表示中断之前是禁用的
}

// __intr_restore - 恢复之前保存的中断状态
static inline void __intr_restore(bool flag) {
    if (flag) { // 如果flag为1
        intr_enable(); // 使能中断
    }
}

// local_intr_save - 宏定义，用于保存当前中断状态并禁用中断
#define local_intr_save(x) \
    do {                   \
        x = __intr_save(); \
    } while (0)

// local_intr_restore - 宏定义，用于恢复之前保存的中断状态
#define local_intr_restore(x) __intr_restore(x);

#endif /* !__KERN_SYNC_SYNC_H__ */ // 结束防止重复包含头文件的宏定义
