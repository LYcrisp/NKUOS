#include <defs.h>
#include <riscv.h>
#include <stdio.h>
#include <string.h>
#include <swap.h>
#include <swap_fifo.h>
#include <list.h>

/* FIFO (First-In, First-Out) 页面替换算法
 * 简介：FIFO页面替换算法是一种简单的页面替换算法，操作系统通过一个队列跟踪所有在内存中的页面，
 *      最近到达的页面排在队列后面，最早到达的页面在队列前面。需要替换页面时，从队列头部
 *      移除最早到达的页面。
 * 详细过程：
 *  (1) 在FIFO算法中，操作系统将所有可交换页面按到达的顺序加入到pra_list_head队列。
 *  (2) 新页面到达时，添加到队列末尾；替换页面时，移除队列头部的页面。
 */

extern list_entry_t pra_list_head;  // 定义FIFO页面链表头，用于保存可交换页面的顺序

/*
 * _fifo_init_mm - 初始化pra_list_head，并将mm->sm_priv指向pra_list_head的地址，
 *                 使得通过mm_struct结构可以访问FIFO页面替换算法的链表。
 */
static int
_fifo_init_mm(struct mm_struct *mm) {     
     list_init(&pra_list_head);          // 初始化pra_list_head链表
     mm->sm_priv = &pra_list_head;       // 将pra_list_head的地址赋给mm->sm_priv
     return 0;
}

/*
 * _fifo_map_swappable - 将新到达的页面放到pra_list_head队列的末尾。
 * 参数：
 *   mm: 内存管理结构指针，用于访问页面队列
 *   addr: 逻辑地址
 *   page: 需要标记为可交换的页面
 *   swap_in: 标志页面是被换入的标志
 */
static int
_fifo_map_swappable(struct mm_struct *mm, uintptr_t addr, struct Page *page, int swap_in) {
    list_entry_t *head = (list_entry_t*) mm->sm_priv;  // 获取FIFO链表头
    list_entry_t *entry = &(page->pra_page_link);      // 页面中的链表节点，用于插入到FIFO链表中

    assert(entry != NULL && head != NULL);             // 检查entry和head是否有效
    // 将新页面添加到链表头
    list_add(head, entry);
    return 0;
}

/*
 * _fifo_swap_out_victim - 从pra_list_head队列的头部移除最早到达的页面，即“受害者页面”，并设置ptr_page的地址。
 * 参数：
 *   mm: 内存管理结构
 *   ptr_page: 指向被换出页面的指针
 *   in_tick: 时间计数，FIFO算法中未使用此参数
 */
static int
_fifo_swap_out_victim(struct mm_struct *mm, struct Page **ptr_page, int in_tick) {
    list_entry_t *head = (list_entry_t*) mm->sm_priv;  // 获取FIFO链表头
    assert(head != NULL);
    assert(in_tick == 0);

    // 获取链表头前的元素，FIFO中是最早到达的页面
    list_entry_t *entry = list_prev(head);
    if (entry != head) {                               // 确保队列中有页面
        list_del(entry);                               // 从队列中删除页面
        *ptr_page = le2page(entry, pra_page_link);     // 将删除页面的地址赋给ptr_page
    } else {
        *ptr_page = NULL;                              // 如果队列为空，将ptr_page设置为NULL
    }
    return 0;
}

/*
 * _fifo_check_swap - 用于测试FIFO页面替换算法的函数。
 *                   检查不同虚拟页在FIFO页面替换下的换入换出是否符合预期。
 */
static int
_fifo_check_swap(void) {
    cprintf("write Virt Page c in fifo_check_swap\n");
    *(unsigned char *)0x3000 = 0x0c;
    assert(pgfault_num == 4);

    cprintf("write Virt Page a in fifo_check_swap\n");
    *(unsigned char *)0x1000 = 0x0a;
    assert(pgfault_num == 4);

    cprintf("write Virt Page d in fifo_check_swap\n");
    *(unsigned char *)0x4000 = 0x0d;
    assert(pgfault_num == 4);

    cprintf("write Virt Page b in fifo_check_swap\n");
    *(unsigned char *)0x2000 = 0x0b;
    assert(pgfault_num == 4);

    cprintf("write Virt Page e in fifo_check_swap\n");
    *(unsigned char *)0x5000 = 0x0e;
    assert(pgfault_num == 5);

    cprintf("write Virt Page b in fifo_check_swap\n");
    *(unsigned char *)0x2000 = 0x0b;
    assert(pgfault_num == 5);

    cprintf("write Virt Page a in fifo_check_swap\n");
    *(unsigned char *)0x1000 = 0x0a;
    assert(pgfault_num == 6);

    cprintf("write Virt Page b in fifo_check_swap\n");
    *(unsigned char *)0x2000 = 0x0b;
    assert(pgfault_num == 7);

    cprintf("write Virt Page c in fifo_check_swap\n");
    *(unsigned char *)0x3000 = 0x0c;
    assert(pgfault_num == 8);

    cprintf("write Virt Page d in fifo_check_swap\n");
    *(unsigned char *)0x4000 = 0x0d;
    assert(pgfault_num == 9);

    cprintf("write Virt Page e in fifo_check_swap\n");
    *(unsigned char *)0x5000 = 0x0e;
    assert(pgfault_num == 10);

    cprintf("write Virt Page a in fifo_check_swap\n");
    assert(*(unsigned char *)0x1000 == 0x0a);
    *(unsigned char *)0x1000 = 0x0a;
    assert(pgfault_num == 11);

    return 0;
}

/*
 * _fifo_init - 初始化FIFO页面替换管理器。
 */
static int
_fifo_init(void) {
    return 0;
}

/*
 * _fifo_set_unswappable - 设置指定页面不可交换，FIFO未实现此功能。
 */
static int
_fifo_set_unswappable(struct mm_struct *mm, uintptr_t addr) {
    return 0;
}

/*
 * _fifo_tick_event - 时间片事件，FIFO未实现此功能。
 */
static int
_fifo_tick_event(struct mm_struct *mm) { 
    return 0; 
}

// 定义FIFO页面替换算法的结构体，用于管理页面的替换策略
struct swap_manager swap_manager_fifo = {
     .name            = "fifo swap manager",        // 算法名称
     .init            = &_fifo_init,                // 初始化函数
     .init_mm         = &_fifo_init_mm,             // 初始化内存管理结构的函数
     .tick_event      = &_fifo_tick_event,          // 时间事件函数
     .map_swappable   = &_fifo_map_swappable,       // 标记页面为可交换的函数
     .set_unswappable = &_fifo_set_unswappable,     // 设置页面不可交换的函数
     .swap_out_victim = &_fifo_swap_out_victim,     // 选择页面替换“受害者”的函数
     .check_swap      = &_fifo_check_swap,          // 检查FIFO替换是否正常的函数
};
