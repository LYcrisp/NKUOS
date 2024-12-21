#include <list.h>
#include <sync.h>
#include <proc.h>
#include <sched.h>
#include <assert.h>

void
wakeup_proc(struct proc_struct *proc) {
    assert(proc->state != PROC_ZOMBIE); // 确保进程状态不是PROC_ZOMBIE
    bool intr_flag;
    local_intr_save(intr_flag); // 保存中断状态并关闭中断
    {
        if (proc->state != PROC_RUNNABLE) { // 如果进程状态不是PROC_RUNNABLE
            proc->state = PROC_RUNNABLE; // 将进程状态设置为PROC_RUNNABLE
            proc->wait_state = 0; // 重置等待状态
        }
        else {
            warn("wakeup runnable process.\n"); // 警告：唤醒了一个已经是可运行状态的进程
        }
    }
    local_intr_restore(intr_flag); // 恢复中断状态
}

void
schedule(void) {
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag); // 保存中断状态并关闭中断
    {
        current->need_resched = 0; // 重置当前进程的need_resched标志
        last = (current == idleproc) ? &proc_list : &(current->list_link); // 如果当前进程是idleproc，则last指向proc_list，否则指向当前进程的list_link
        le = last; // 初始化le为last
        do {
            if ((le = list_next(le)) != &proc_list) { // 遍历进程列表
                next = le2proc(le, list_link); // 获取下一个进程
                if (next->state == PROC_RUNNABLE) { // 如果下一个进程是可运行状态
                    break; // 退出循环
                }
            }
        } while (le != last); // 如果没有找到可运行的进程，则继续循环
        if (next == NULL || next->state != PROC_RUNNABLE) { // 如果没有找到可运行的进程
            next = idleproc; // 将next设置为idleproc
        }
        next->runs ++; // 增加next进程的运行次数
        if (next != current) { // 如果下一个进程不是当前进程
            proc_run(next); // 切换到下一个进程
        }
    }
    local_intr_restore(intr_flag); // 恢复中断状态
}
