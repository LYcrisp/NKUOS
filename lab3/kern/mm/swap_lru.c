#include <defs.h>
#include <riscv.h>
#include <stdio.h>
#include <string.h>
#include <swap.h>
#include <swap_lru.h>
#include <list.h>

extern list_entry_t pra_list_head;

static int
_lru_init_mm(struct mm_struct *mm)
{     
    list_init(&pra_list_head);
    mm->sm_priv = &pra_list_head;
    return 0;
}

static int
_lru_map_swappable(struct mm_struct *mm, uintptr_t addr, struct Page *page, int swap_in)
{
    list_entry_t *head=(list_entry_t*) mm->sm_priv;
    list_entry_t *entry=&(page->pra_page_link);
 
    assert(entry != NULL && head != NULL);

    // 将最近访问的页面添加到链表头部
    list_add(head, entry);
    return 0;
}

static int
_lru_swap_out_victim(struct mm_struct *mm, struct Page ** ptr_page, int in_tick)
{
    list_entry_t *head=(list_entry_t*) mm->sm_priv;
    assert(head != NULL);
    assert(in_tick==0);
    
    // 选择最久未使用的页面进行替换
    list_entry_t* entry = list_prev(head);
    if (entry != head) {
        list_del(entry);
        *ptr_page = le2page(entry, pra_page_link);
    } else {
        *ptr_page = NULL;
    }
    return 0;
}

static void
chect_list(uintptr_t addr) {  // 检查当前页是否在链表中，如果在就放在链表头
    list_entry_t *head = &pra_list_head, *le = head;
    
    while ((le = list_prev(le)) != head) {
        struct Page *curr = le2page(le, pra_page_link);
        if (curr->pra_vaddr == addr) {
            list_del(le);         // 删除找到的页
            list_add(head, le);   // 将页移到链表头部
            return;               
        }
    }
}

static void
printlist() {   // 打印链表
    cprintf("--------list-head----------\n");
    list_entry_t *head = &pra_list_head, *le = head;
    while ((le = list_next(le)) != head)
    {
        struct Page* page = le2page(le, pra_page_link);
        cprintf("vaddr: %x\n", page->pra_vaddr);
    }
    cprintf("--------list-end----------\n");
}

static void
write_and_check(uintptr_t addr, unsigned char value) { // 写入一个字节的数据，对虚拟地址的写操作
    cprintf("write Virt Page 0x%x in lru_check_swap\n", addr);
    chect_list(addr);
    *(unsigned char *)addr = value;
}

static int
_lru_check_swap(void) {
    uintptr_t test_addrs[] = {0x3000, 0x1000, 0x4000, 0x2000, 0x5000};//vma里面没有0x6000
    unsigned char values[] = {0x0c, 0x0a, 0x0d, 0x0b, 0x0e};

    for (int i = 0; i < 5; i++) {
        write_and_check(test_addrs[i], values[i]);
        printlist();
    }
    write_and_check(0x1000, 0x0a);
    printlist();

    return 0;
}

static int
_lru_init(void)
{
    return 0;
}

static int
_lru_set_unswappable(struct mm_struct *mm, uintptr_t addr)
{
    return 0;
}

static int
_lru_tick_event(struct mm_struct *mm)
{ return 0; }

struct swap_manager swap_manager_lru =
{
    .name            = "lru swap manager",
    .init            = &_lru_init,
    .init_mm         = &_lru_init_mm,
    .tick_event      = &_lru_tick_event,
    .map_swappable   = &_lru_map_swappable,
    .set_unswappable = &_lru_set_unswappable,
    .swap_out_victim = &_lru_swap_out_victim,
    .check_swap      = &_lru_check_swap,
};