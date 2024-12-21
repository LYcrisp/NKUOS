#include <defs.h>
#include <riscv.h>
#include <stdio.h>
#include <string.h>
#include <swap.h>
#include <swap_fifo.h>
#include <list.h>

// 初始化FIFO页面置换算法
list_entry_t pra_list_head;

// 初始化FIFO页面置换算法，设置mm->sm_priv指向pra_list_head
static int
_fifo_init_mm(struct mm_struct *mm)
{     
    list_init(&pra_list_head); // 初始化pra_list_head
    mm->sm_priv = &pra_list_head; // 设置mm->sm_priv指向pra_list_head
    //cprintf(" mm->sm_priv %x in fifo_init_mm\n",mm->sm_priv);
    return 0;
}

// 将页面映射为可交换的，根据FIFO算法，将最新到达的页面链接到pra_list_head队列的末尾
static int
_fifo_map_swappable(struct mm_struct *mm, uintptr_t addr, struct Page *page, int swap_in)
{
    list_entry_t *head=(list_entry_t*) mm->sm_priv;
    list_entry_t *entry=&(page->pra_page_link);
 
    assert(entry != NULL && head != NULL);
    // 记录页面访问情况
    /*LAB3 EXERCISE 2: YOUR CODE*/ 
    //(1)将最新到达的页面链接到pra_list_head队列的末尾
    list_add_before(head, entry); // 将entry添加到head之前
    return 0;
}

// 根据FIFO算法，选择要交换出去的受害页面，取消链接pra_list_head队列最前面的页面，并将该页面的地址设置为ptr_page
static int
_fifo_swap_out_victim(struct mm_struct *mm, struct Page ** ptr_page, int in_tick)
{
    list_entry_t *head=(list_entry_t*) mm->sm_priv;
    assert(head != NULL);
    assert(in_tick==0);
    /* 选择受害页面 */
    /*LAB3 EXERCISE 2: YOUR CODE*/ 
    //(1) 取消链接pra_list_head队列最前面的页面
    //(2) 将该页面的地址设置为ptr_page
    list_entry_t* entry = list_next(head); // 获取队列最前面的页面
    list_del(entry); // 取消链接
    *ptr_page = le2page(entry, pra_page_link); // 设置页面地址
    return 0;
}

// 检查FIFO页面置换算法的正确性
static int
_fifo_check_swap(void) {
    cprintf("write Virt Page c in fifo_check_swap\n");
    *(unsigned char *)0x3000 = 0x0c;
    assert(pgfault_num==4);
    cprintf("write Virt Page a in fifo_check_swap\n");
    *(unsigned char *)0x1000 = 0x0a;
    assert(pgfault_num==4);
    cprintf("write Virt Page d in fifo_check_swap\n");
    *(unsigned char *)0x4000 = 0x0d;
    assert(pgfault_num==4);
    cprintf("write Virt Page b in fifo_check_swap\n");
    *(unsigned char *)0x2000 = 0x0b;
    assert(pgfault_num==4);
    cprintf("write Virt Page e in fifo_check_swap\n");
    *(unsigned char *)0x5000 = 0x0e;
    assert(pgfault_num==5);
    cprintf("write Virt Page b in fifo_check_swap\n");
    *(unsigned char *)0x2000 = 0x0b;
    assert(pgfault_num==5);
    cprintf("write Virt Page a in fifo_check_swap\n");
    *(unsigned char *)0x1000 = 0x0a;
    assert(pgfault_num==6);
    cprintf("write Virt Page b in fifo_check_swap\n");
    *(unsigned char *)0x2000 = 0x0b;
    assert(pgfault_num==7);
    cprintf("write Virt Page c in fifo_check_swap\n");
    *(unsigned char *)0x3000 = 0x0c;
    assert(pgfault_num==8);
    cprintf("write Virt Page d in fifo_check_swap\n");
    *(unsigned char *)0x4000 = 0x0d;
    assert(pgfault_num==9);
    cprintf("write Virt Page e in fifo_check_swap\n");
    *(unsigned char *)0x5000 = 0x0e;
    assert(pgfault_num==10);
    cprintf("write Virt Page a in fifo_check_swap\n");
    assert(*(unsigned char *)0x1000 == 0x0a);
    *(unsigned char *)0x1000 = 0x0a;
    assert(pgfault_num==11);
    return 0;
}

// 初始化FIFO页面置换算法
static int
_fifo_init(void)
{
    return 0;
}

// 设置页面为不可交换的
static int
_fifo_set_unswappable(struct mm_struct *mm, uintptr_t addr)
{
    return 0;
}

// 处理时钟事件
static int
_fifo_tick_event(struct mm_struct *mm)
{ return 0; }

// FIFO页面置换算法管理器
struct swap_manager swap_manager_fifo =
{
    .name            = "fifo swap manager",
    .init            = &_fifo_init,
    .init_mm         = &_fifo_init_mm,
    .tick_event      = &_fifo_tick_event,
    .map_swappable   = &_fifo_map_swappable,
    .set_unswappable = &_fifo_set_unswappable,
    .swap_out_victim = &_fifo_swap_out_victim,
    .check_swap      = &_fifo_check_swap,
};
