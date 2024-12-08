/*文件在这个项目中主要负责进程调度和进程状态管理
 */

#include <list.h> // 包含链表操作的头文件
#include <sync.h> // 包含同步操作的头文件
#include <proc.h> // 包含进程操作的头文件
#include <sched.h> // 包含调度操作的头文件
#include <assert.h> // 包含断言操作的头文件

void
wakeup_proc(struct proc_struct *proc) { // 唤醒进程函数
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE); // 确保进程状态不是僵尸态或可运行态
    proc->state = PROC_RUNNABLE; // 将进程状态设置为可运行态
}

void
schedule(void) { // 调度函数
    bool intr_flag; // 定义中断标志
    list_entry_t *le, *last; // 定义链表指针
    struct proc_struct *next = NULL; // 定义下一个要运行的进程
    local_intr_save(intr_flag); // 保存当前中断状态并禁用中断
    {
        current->need_resched = 0; // 清除当前进程的需要调度标志
        last = (current == idleproc) ? &proc_list : &(current->list_link); // 获取当前进程的链表位置
        le = last; // 初始化链表指针
        do {
            if ((le = list_next(le)) != &proc_list) { // 遍历进程链表
                next = le2proc(le, list_link); // 获取下一个进程
                if (next->state == PROC_RUNNABLE) { // 如果进程状态为可运行态
                    break; // 退出循环
                }
            }
        } while (le != last); // 如果遍历完一圈则退出循环
        if (next == NULL || next->state != PROC_RUNNABLE) { // 如果没有找到可运行的进程
            next = idleproc; // 设置为空闲进程
        }
        next->runs ++; // 增加进程的运行次数
        if (next != current) { // 如果下一个进程不是当前进程
            proc_run(next); // 切换到下一个进程
        }
    }
    local_intr_restore(intr_flag); // 恢复之前保存的中断状态
}
