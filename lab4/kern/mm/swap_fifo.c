#include <defs.h>
#include <riscv.h>
#include <stdio.h>
#include <string.h>
#include <swap.h>
#include <swap_fifo.h>
#include <list.h>

/* [wikipedia]The simplest Page Replacement Algorithm(PRA) is a FIFO algorithm. The first-in, first-out
 * page replacement algorithm is a low-overhead algorithm that requires little book-keeping on
 * the part of the operating system. The idea is obvious from the name - the operating system
 * keeps track of all the pages in memory in a queue, with the most recent arrival at the back,
 * and the earliest arrival in front. When a page needs to be replaced, the page at the front
 * of the queue (the oldest page) is selected. While FIFO is cheap and intuitive, it performs
 * poorly in practical application. Thus, it is rarely used in its unmodified form. This
 * algorithm experiences Belady's anomaly.
 *
 * Details of FIFO PRA
 * (1) Prepare: In order to implement FIFO PRA, we should manage all swappable pages, so we can
 *              link these pages into pra_list_head according the time order. At first you should
 *              be familiar to the struct list in list.h. struct list is a simple doubly linked list
 *              implementation. You should know howto USE: list_init, list_add(list_add_after),
 *              list_add_before, list_del, list_next, list_prev. Another tricky method is to transform
 *              a general list struct to a special struct (such as struct page). You can find some MACRO:
 *              le2page (in memlayout.h), (in future labs: le2vma (in vmm.h), le2proc (in proc.h),etc.
 */

list_entry_t pra_list_head;

/*
 * _fifo_init_mm - 初始化FIFO页面置换算法的内存管理结构
 * @mm: 内存管理结构指针
 * 初始化pra_list_head并让mm->sm_priv指向pra_list_head的地址
 */
static int
_fifo_init_mm(struct mm_struct *mm)
{     
    list_init(&pra_list_head); // 初始化pra_list_head
    mm->sm_priv = &pra_list_head; // 让mm->sm_priv指向pra_list_head的地址
    //cprintf(" mm->sm_priv %x in fifo_init_mm\n",mm->sm_priv);
    return 0;
}

/*
 * _fifo_map_swappable - 将页面映射为可交换的
 * @mm: 内存管理结构指针
 * @addr: 页面地址
 * @page: 页面结构指针
 * @swap_in: 是否是换入操作
 * 根据FIFO页面置换算法，我们应该将最近到达的页面链接到pra_list_head队列的末尾
 */
static int
_fifo_map_swappable(struct mm_struct *mm, uintptr_t addr, struct Page *page, int swap_in)
{
    list_entry_t *head=(list_entry_t*) mm->sm_priv;
    list_entry_t *entry=&(page->pra_page_link);
 
    assert(entry != NULL && head != NULL);
    // 记录页面访问情况
    /*LAB3 EXERCISE 2: YOUR CODE*/ 
    //(1)将最近到达的页面链接到pra_list_head队列的末尾
    list_add_before(head, entry); // 将entry添加到head之前
    return 0;
}

/*
 * _fifo_swap_out_victim - 选择要换出的受害页面
 * @mm: 内存管理结构指针
 * @ptr_page: 指向要换出的页面指针的指针
 * @in_tick: 时钟中断标志
 * 根据FIFO页面置换算法，我们应该取消链接pra_list_head队列前面的最早到达的页面，然后将该页面的地址设置为ptr_page
 */
static int
_fifo_swap_out_victim(struct mm_struct *mm, struct Page ** ptr_page, int in_tick)
{
    list_entry_t *head=(list_entry_t*) mm->sm_priv;
    assert(head != NULL);
    assert(in_tick==0);
    /* 选择受害页面 */
    /*LAB3 EXERCISE 2: YOUR CODE*/ 
    //(1) 取消链接pra_list_head队列前面的最早到达的页面
    //(2) 将该页面的地址设置为ptr_page
    list_entry_t* entry = list_next(head); // 获取head的下一个元素
    list_del(entry); // 删除entry
    *ptr_page = le2page(entry, pra_page_link); // 将entry转换为页面结构并赋值给ptr_page
    return 0;
}

/*
 * _fifo_check_swap - 检查FIFO页面置换算法
 * 检查FIFO页面置换算法是否正确
 */
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

/*
 * _fifo_init - 初始化FIFO页面置换算法
 * 初始化FIFO页面置换算法
 */
static int
_fifo_init(void)
{
    return 0;
}

/*
 * _fifo_set_unswappable - 设置页面为不可交换
 * @mm: 内存管理结构指针
 * @addr: 页面地址
 * 设置页面为不可交换
 */
static int
_fifo_set_unswappable(struct mm_struct *mm, uintptr_t addr)
{
    return 0;
}

/*
 * _fifo_tick_event - 时钟事件处理
 * @mm: 内存管理结构指针
 * 处理时钟事件
 */
static int
_fifo_tick_event(struct mm_struct *mm)
{ 
    return 0; 
}

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
